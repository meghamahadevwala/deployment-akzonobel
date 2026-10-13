/**
 * Centralizes the Moody's Risk Class -> celsrm__Risk_Class__c / celsrm__Check_Rule__c mapping logic
 * that used to be duplicated in CreditReviewParameters.initiateCreditReview()
 * and GetMoodysDataService.execute().
 *
 * Pure method: no SOQL, no DML, does not mutate the Account. The caller decides what to do
 * with the result (assign it to the SObject, trigger a sync to SAP/Celonis, etc.), since that
 * differs between the two current call sites.
 */
public with sharing class RiskClassCheckRuleMappingService {

    // -- Starts |Ticket #916| Qualitative Score E -> Direct Block --//
    public static final Map<String, String> MORE_RISK_CLASS_MAPPING = new Map<String, String>{
        'AAA' => 'Low', 'AA' => 'Low', 'A' => 'Low',
        'BBB' => 'Medium', 'BB' => 'Medium',
        'B' => 'High', 'CCC' => 'High', 'CC' => 'High', 'C' => 'High', 'D' => 'High'
    };

    public static final Map<String, String> QUALITATIVE_RISK_CLASS_MAPPING = new Map<String, String>{
        'A' => 'Low', 'B' => 'Medium', 'C' => 'High', 'D' => 'High', 'E' => 'Direct Block'
    };
    // -- End |Ticket #916| --//

    private static final Map<String, Map<String, String>> RISK_CLASS_CODE_MAPPING = new Map<String, Map<String, String>>{
        'Low' => new Map<String, String>{ 'code' => '3', 'description' => 'Low Risk' },
        'Medium' => new Map<String, String>{ 'code' => '4', 'description' => 'Medium Risk' },
        'High' => new Map<String, String>{ 'code' => '5', 'description' => 'High Risk' },
        'Full Credit Block' => new Map<String, String>{ 'code' => '6', 'description' => 'Full Credit Block' },
        'Direct Block' => new Map<String, String>{ 'code' => '5', 'description' => 'High Risk' } // same code as High, own Check Rule (Z09)
    };

    private static final Map<String, String> CHECK_RULE_MAPPING = new Map<String, String>{
        'Low' => 'Z03 Risk Class Low',
        'Medium' => 'Z04 Risk Class Medium',
        'High' => 'Z05 Risk Class High',
        'Full Credit Block' => 'Z06 Risk Class Full Credit Block',
        'Direct Block' => 'Z09 Risk Class Direct Block'
    };

    // Child / Intercompany accounts: nothing is touched
    private static final Set<String> EXCLUDED_CHECK_RULES = new Set<String>{
        'Z08 Risk Class Child'
    };

    // Credit Groups whose Check Rule must never be changed by this service (e.g. Key Account).
    // Risk Class is still updated for these accounts.
    // TODO: confirm exact picklist value(s) for Key Account credit group(s).
    private static final Set<String> PROTECTED_CREDIT_GROUPS = new Set<String>{
        '0002 - Key - Key Account'
    };

    public class MappingResult {
        public String riskClass;          // final value to assign (or the current one, unchanged, if not applicable)
        public String checkRule;          // final value to assign (or the current one, unchanged, if not applicable)
        public Boolean riskClassChanged;
        public Boolean checkRuleChanged;
        public Boolean checkRuleProtected; // true if the Check Rule was kept because of the Credit Group
        public Boolean applied;           // false if the account is excluded (Z08) or accountRiskClass is not mapped
    }

    /**
     * @param accountRiskClass    'Low' | 'Medium' | 'High' | 'Full Credit Block' | 'Direct Block'
     * @param currentRiskClass    current value of account.celsrm__Risk_Class__c
     * @param currentCheckRule    current value of account.celsrm__Check_Rule__c
     * @param currentCreditGroup  current value of account.celsrm__Credit_Group__c
     */
    public static MappingResult mapRiskClassAndCheckRule(
        String accountRiskClass,
        String currentRiskClass,
        String currentCheckRule,
        String currentCreditGroup
    ) {
        MappingResult result = new MappingResult();
        result.riskClass = currentRiskClass;
        result.checkRule = currentCheckRule;
        result.riskClassChanged = false;
        result.checkRuleChanged = false;
        result.checkRuleProtected = false;
        result.applied = false;

        if (accountRiskClass == null || !RISK_CLASS_CODE_MAPPING.containsKey(accountRiskClass)) {
            return result;
        }
        if (EXCLUDED_CHECK_RULES.contains(currentCheckRule)) {
            return result;
        }

        Map<String, String> codeInfo = RISK_CLASS_CODE_MAPPING.get(accountRiskClass);
        String newRiskClass = codeInfo.get('code') + ' - ' + codeInfo.get('description');

        result.applied = true;
        result.riskClass = newRiskClass;
        result.riskClassChanged = (newRiskClass != currentRiskClass);

        if (isProtectedCreditGroup(currentCreditGroup)) {
            // Risk Class is updated, Check Rule stays as-is (Key Account credit group)
            result.checkRuleProtected = true;
        } else {
            String newCheckRule = CHECK_RULE_MAPPING.get(accountRiskClass);
            result.checkRule = newCheckRule;
            result.checkRuleChanged = (newCheckRule != currentCheckRule);
        }

        return result;
    }

    public static Boolean isProtectedCreditGroup(String creditGroup) {
        return creditGroup != null && PROTECTED_CREDIT_GROUPS.contains(creditGroup);
    }

    /**
     * Apex-only convenience overload: mutates the given Account's celsrm__Risk_Class__c /
     * celsrm__Check_Rule__c fields directly. No DML here — the caller controls when/how
     * the Account is saved, so this stays bulk-safe for callers that batch their updates
     * (e.g. CreditReviewParameters, GetMoodysDataService).
     *
     * The Account MUST have celsrm__Credit_Group__c queried; otherwise an SObjectException
     * is thrown on purpose, so a Key Account never gets its Check Rule overwritten silently.
     */
    public static MappingResult applyRiskClassAndCheckRule(Account acc, String accountRiskClass) {
        MappingResult mapped = mapRiskClassAndCheckRule(
            accountRiskClass,
            acc.celsrm__Risk_Class__c,
            acc.celsrm__Check_Rule__c,
            acc.celsrm__Credit_Group__c
        );
        acc.celsrm__Risk_Class__c = mapped.riskClass;
        acc.celsrm__Check_Rule__c = mapped.checkRule;
        return mapped;
    }

    // ---------------------------------------------------------------------
    // Invocable wrapper, so a Flow can pass an Account + a Moody's Risk Class
    // and have Apex update and save the Account directly.
    // NOTE: a class can only have ONE @InvocableMethod.
    // ---------------------------------------------------------------------

    public class FlowRequest {
        @InvocableVariable(label='Account' required=true)
        public Account acc;

        @InvocableVariable(label='Account Risk Class' required=true)
        public String accountRiskClass;
    }

    public class FlowResponse {
        @InvocableVariable public Boolean riskClassChanged;
        @InvocableVariable public Boolean checkRuleChanged;
        @InvocableVariable public Boolean checkRuleProtected;
        @InvocableVariable public Boolean applied;
    }

    @InvocableMethod(
        label='Update Account Risk Class And Check Rule'
        description='Given an Account and a Moody\'s Risk Class, updates and saves celsrm__Risk_Class__c and celsrm__Check_Rule__c on the Account, respecting Child/Intercompany exclusion and Key Account credit group Check Rule protection.'
        category='Credit Management'
    )
    public static List<FlowResponse> updateAccountRiskClassAndCheckRule(List<FlowRequest> requests) {
        List<MappingResult> mappedResults = new List<MappingResult>();
        List<Account> accountsToUpdate = new List<Account>();

        for (FlowRequest req : requests) {
            MappingResult mapped = applyRiskClassAndCheckRule(req.acc, req.accountRiskClass);
            mappedResults.add(mapped);
            if (mapped.applied && (mapped.riskClassChanged || mapped.checkRuleChanged)) {
                // Bare Account with only Id + the two written fields: req.acc comes from the
                // Flow's $Record and carries read-only system fields that would make the DML
                // fail with INVALID_FIELD_FOR_INSERT_UPDATE.
                accountsToUpdate.add(new Account(
                    Id = req.acc.Id,
                    celsrm__Risk_Class__c = mapped.riskClass,
                    celsrm__Check_Rule__c = mapped.checkRule
                ));
            }
        }

        if (!accountsToUpdate.isEmpty()) {
            update accountsToUpdate;
        }

        List<FlowResponse> responses = new List<FlowResponse>();
        for (MappingResult mapped : mappedResults) {
            FlowResponse resp = new FlowResponse();
            resp.riskClassChanged = mapped.riskClassChanged;
            resp.checkRuleChanged = mapped.checkRuleChanged;
            resp.checkRuleProtected = mapped.checkRuleProtected;
            resp.applied = mapped.applied;
            responses.add(resp);
        }
        return responses;
    }
}