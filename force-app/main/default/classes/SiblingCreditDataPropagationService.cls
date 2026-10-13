/**
 * @description Replaces PropagateBvdIdToSiblingsService. Given "source" Accounts that already
 * carry, in memory, freshly computed BvD_ID_Number__c / Moody_s_Risk_Class__c /
 * Moody_s_Credit_Limit__c (e.g. right after a Moody's callout in GetMoodysDataService or
 * CreditReviewParameters), this service:
 *
 *   1. Recomputes celsrm__Risk_Class__c / celsrm__Check_Rule__c on the SOURCE accounts
 *      themselves (via RiskClassCheckRuleMappingService) — this stays synchronous Apex,
 *      unchanged from before.
 *   2. Finds sibling Credit Segments — other Accounts sharing the same AccountNumber
 *      (Business Partner).
 *   3. Propagates BvD_ID_Number__c / Moody_s_Risk_Class__c / Moody_s_Credit_Limit__c to
 *      siblings. BvD_ID_Number__c specifically is skipped for siblings whose Check Rule
 *      is 'Z08 Risk Class Child' or whose Credit Group is one of the protected values
 *      (mirrors the "BvD ID" validation rule, which only fires on
 *      ISCHANGED(BvD_ID_Number__c)). Moody_s_Risk_Class__c / Moody_s_Credit_Limit__c are
 *      NOT subject to that exclusion — they always propagate; RiskClassCheckRuleMappingService
 *      already decides internally whether a protected sibling's Risk Class / Check Rule
 *      should actually be recomputed.
 *
 * IMPORTANT: this method does NOT recompute celsrm__Risk_Class__c / celsrm__Check_Rule__c
 * on siblings, and does NOT build any SAP/CFin writeback payload. Both of those are handled
 * automatically once the caller does a normal `update` on the returned accounts, because
 * AccountMasterTrigger already:
 *   - fires the "Risk Class and Check Rule 2" record-triggered Flow when a sibling's
 *     Moody_s_Risk_Class__c changes (that Flow calls
 *     RiskClassCheckRuleMappingService.updateAccountRiskClassAndCheckRule, which computes
 *     and saves celsrm__Risk_Class__c / celsrm__Check_Rule__c for that sibling), and
 *   - fires UpdateBvdIdInSourceSystemService.updateBvdIdInSAP unconditionally whenever
 *     BvD_ID_Number__c changes on any 'Credit' account — no skip-flag gating there.
 * Building that logic here again would just duplicate what the trigger already does.
 *
 * This method performs NO DML and NO callouts of its own — the caller commits
 * accountsToUpdate as part of its own transaction.
 *
 * Unlike the old PropagateBvdIdToSiblingsService, this is NOT wired to AccountMasterTrigger,
 * so there's no re-entrancy risk and no skip-flag guard is needed here.
 */
public without sharing class SiblingCreditDataPropagationService {

    // Mirrors the BvD ID validation rule — applies ONLY to BvD_ID_Number__c
    // propagation (see isProtectedFromPropagation below). Does not gate
    // Moody_s_Risk_Class__c / Moody_s_Credit_Limit__c propagation.
    private static final Set<String> PROTECTED_CHECK_RULES = new Set<String>{
        'Z08 Risk Class Child'
    };

    private static final Set<String> PROTECTED_CREDIT_GROUPS = new Set<String>{
        '0001 - New customer / No score',
        '0007 - IC - Intercompany',
        '0008 - INAC - Inactive Customer',
        '0009 - RPDL - RPDL',
        '0010 - AGY - Agency/Lawyer',
        '0011 - ATR - Atradius',
        '0012 - WRT - Write Off',
        '0013 - BKR - Bankruptcy',
        '0014 - PCC - Pre-pay/Credit Card'
    };

    public class PropagationResult {
        // Every account (source + eligible siblings) that needs saving. Source accounts
        // already carry the recomputed Risk Class / Check Rule; siblings only carry the
        // propagated Moody's fields — their Risk Class / Check Rule is computed later,
        // reactively, by the "Risk Class and Check Rule 2" Flow once this update saves.
        public List<Account> accountsToUpdate = new List<Account>();

        // Subset of the SOURCE accounts whose celsrm__Risk_Class__c or
        // celsrm__Check_Rule__c actually changed — for callers that sync profile data
        // to CFin/SAP only on change (mirrors the old accToUpdateProfileData list in
        // GetMoodysDataService). Siblings are intentionally NOT included here: their
        // own change (once the Flow updates them) goes through AccountMasterTrigger's
        // own detection, not through this list.
        public List<Account> changedForProfileSync = new List<Account>();

        // Per-source-account MappingResult (riskClassChanged / checkRuleChanged kept
        // separate, not just OR'd together), keyed by Account Id — for callers whose
        // downstream sync logic needs to know exactly which field changed, not just
        // "something changed" (e.g. CreditReviewParameters' sysadmin-specific condition).
        public Map<Id, RiskClassCheckRuleMappingService.MappingResult> sourceMappingResults =
            new Map<Id, RiskClassCheckRuleMappingService.MappingResult>();
    }

    /**
     * @description For callers whose source accounts have NOT been recomputed yet.
     * Recomputes Risk Class / Check Rule on the source accounts themselves, then
     * propagates to eligible siblings. Use this when the caller has no other reason
     * to compute the source account's Risk Class / Check Rule itself (e.g.
     * CreditReviewParameters, which handles a single account with no ordering
     * constraints downstream).
     */
    public static PropagationResult propagate(List<Account> sourceAccounts) {
        PropagationResult result = new PropagationResult();
        if (sourceAccounts == null || sourceAccounts.isEmpty()) {
            return result;
        }

        for (Account src : sourceAccounts) {
            RiskClassCheckRuleMappingService.MappingResult mapped =
                RiskClassCheckRuleMappingService.applyRiskClassAndCheckRule(src, src.Moody_s_Risk_Class__c);
            result.sourceMappingResults.put(src.Id, mapped);
            if (mapped.applied && (mapped.riskClassChanged || mapped.checkRuleChanged)) {
                result.changedForProfileSync.add(src);
            }
        }

        result.accountsToUpdate.addAll(propagateToSiblingsOnly(sourceAccounts));
        result.accountsToUpdate.addAll(sourceAccounts);
        return result;
    }

    /**
     * @description For callers that already recomputed Risk Class / Check Rule on their
     * source accounts themselves — e.g. GetMoodysDataService, which needs that recompute
     * to happen inline (before it builds the related celsrm__Credit_Review__c record in
     * the same loop iteration, which reads celsrm__Risk_Class__c off the account).
     * ONLY finds and propagates to eligible siblings; does not touch the source accounts
     * at all. Returns the siblings that need saving — the caller is expected to include
     * both these and its own (already-updated) source accounts in one `update`.
     */
    public static List<Account> propagateToSiblingsOnly(List<Account> sourceAccounts) {
        List<Account> siblingsToUpdate = new List<Account>();
        if (sourceAccounts == null || sourceAccounts.isEmpty()) {
            return siblingsToUpdate;
        }

        // Find sibling Credit Segments (same AccountNumber, excluding the sources themselves)
        Set<String> bpNumbers = new Set<String>();
        Set<Id> sourceIds = new Set<Id>();
        Map<String, Account> sourceByBp = new Map<String, Account>(); // last source per BP wins if duplicated
        for (Account src : sourceAccounts) {
            if (String.isBlank(src.AccountNumber)) continue;
            bpNumbers.add(src.AccountNumber);
            sourceIds.add(src.Id);
            sourceByBp.put(src.AccountNumber, src);
        }
        if (bpNumbers.isEmpty()) {
            return siblingsToUpdate;
        }

        List<Account> siblings = [
            SELECT Id, AccountNumber, BvD_ID_Number__c, Moody_s_Risk_Class__c, Moody_s_Credit_Limit__c,
                   celsrm__Check_Rule__c, celsrm__Credit_Group__c
            FROM Account
            WHERE AccountNumber IN :bpNumbers
              AND celsrm__App_Name__c = 'Credit'
              AND Id NOT IN :sourceIds
        ];

        // Propagate onto eligible siblings (no Risk Class/Check Rule recompute here —
        // the Flow reacts to the Moody_s_Risk_Class__c change once this saves)
        for (Account sibling : siblings) {
            Account src = sourceByBp.get(sibling.AccountNumber);
            if (src == null) continue;

            // BvD_ID_Number__c specifically mirrors the "BvD ID" validation rule
            // (AND(ISCHANGED(BvD_ID_Number__c), <protected Check Rule/Credit Group>,
            // $Profile.Name <> 'System Administrator')): propagating it to a protected
            // sibling as a non-sysadmin user would fail that VR, so it's skipped there
            // regardless of running user (kept conservative/consistent either way).
            // Moody_s_Risk_Class__c / Moody_s_Credit_Limit__c are NOT covered by that VR
            // at all, so they always propagate — RiskClassCheckRuleMappingService already
            // decides internally (via its own exclusion list) whether a protected sibling's
            // celsrm__Risk_Class__c/celsrm__Check_Rule__c should be recomputed once the
            // Flow reacts to this change.
            Boolean protectedFromBvdChange = isProtectedFromPropagation(sibling);

            Boolean bvdChanged = !protectedFromBvdChange && sibling.BvD_ID_Number__c != src.BvD_ID_Number__c;
            Boolean moodysDataChanged =
                bvdChanged ||
                sibling.Moody_s_Risk_Class__c != src.Moody_s_Risk_Class__c ||
                sibling.Moody_s_Credit_Limit__c != src.Moody_s_Credit_Limit__c;

            if (!moodysDataChanged) continue; // nothing to propagate — avoids a no-op update/Flow trigger

            if (bvdChanged) {
                sibling.BvD_ID_Number__c = src.BvD_ID_Number__c;
            }
            sibling.Moody_s_Risk_Class__c = src.Moody_s_Risk_Class__c;
            sibling.Moody_s_Credit_Limit__c = src.Moody_s_Credit_Limit__c;

            siblingsToUpdate.add(sibling);
        }

        return siblingsToUpdate;
    }

    /**
     * @description Mirrors the "BvD ID" validation rule specifically (it only fires on
     * ISCHANGED(BvD_ID_Number__c)): an account is protected from BvD ID propagation if
     * its Check Rule is 'Z08 Risk Class Child' or its Credit Group is one of the
     * restricted values. Does NOT apply to Moody_s_Risk_Class__c / Moody_s_Credit_Limit__c —
     * the VR doesn't cover those fields.
     */
    private static Boolean isProtectedFromPropagation(Account acc) {
        if (PROTECTED_CHECK_RULES.contains(acc.celsrm__Check_Rule__c)) {
            return true;
        }
        if (PROTECTED_CREDIT_GROUPS.contains(acc.celsrm__Credit_Group__c)) {
            return true;
        }
        return false;
    }
}