/**
 * @description When BvD_ID_Number__c changes on an Account (Credit Segment),
 *              propagates that change to all sibling Credit Segments sharing
 *              the same AccountNumber (Business Partner), and fires
 *              UpdateBvdIdInSourceSystemService for each sibling so CFin
 *              receives its own writeback per CS.
 *              Siblings whose Check Rule / Credit Group match the protected
 *              values (mirrors the "BvD ID" validation rule) are skipped —
 *              their BvD ID is never overwritten by propagation.
 */
public without sharing class PropagateBvdIdToSiblingsService {
    /** Prevents re-entry when the sibling update re-fires AccountMasterTrigger. */
    public static Boolean skipBvdPropagation = false;

    /** Check Rule values that block BvD ID changes (mirrors the VR). */
    private static final Set<String> PROTECTED_CHECK_RULES = new Set<String>{
        'Z08 Risk Class Child'
    };

    /** Credit Group values that block BvD ID changes (mirrors the VR). */
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

    public static void propagateToSiblings(List<Account> changedAccounts) {
        if (skipBvdPropagation) return;

        // 1. Build a map of AccountNumber → new BvD ID from the changed accounts
        Set<String>     bpNumbers   = new Set<String>();
        Set<Id>         changedIds  = new Set<Id>();
        Map<String, String> newBvdByBp = new Map<String, String>();
        for (Account acc : changedAccounts) {
            if (String.isBlank(acc.AccountNumber)) continue;
            bpNumbers.add(acc.AccountNumber);
            changedIds.add(acc.Id);
            newBvdByBp.put(acc.AccountNumber, acc.BvD_ID_Number__c);
        }
        if (bpNumbers.isEmpty()) return;

        // 2. Query siblings — need current BvD ID, Check Rule and Credit Group
        List<Account> siblings = [
            SELECT Id, AccountNumber, BvD_ID_Number__c,
                   celsrm__Credit_Control_Area__c,
                   celsrm__Check_Rule__c,
                   celsrm__Credit_Group__c
            FROM Account
            WHERE AccountNumber IN :bpNumbers
              AND celsrm__App_Name__c   =  'Credit'
              AND Id           NOT IN :changedIds
        ];
        if (siblings.isEmpty()) return;

        // 3. Build update lists
        List<Account>            toUpdate   = new List<Account>();
        List<Map<String,String>> bvdUpdates = new List<Map<String,String>>();
        for (Account sibling : siblings) {
            // Skip siblings protected by Check Rule / Credit Group
            if (isProtectedFromBvdChange(sibling)) continue;

            String newBvdId = newBvdByBp.get(sibling.AccountNumber);
            // Skip if already in sync
            if (sibling.BvD_ID_Number__c == newBvdId) continue;

            // For CFin: old = what the sibling currently has, new = what we're setting
            Map<String,String> bvdMap = new Map<String,String>();
            bvdMap.put('accountId',         sibling.Id);
            bvdMap.put('accountNumber',     sibling.AccountNumber);
            bvdMap.put('creditControlArea', sibling.celsrm__Credit_Control_Area__c);
            bvdMap.put('oldBvdId',          sibling.BvD_ID_Number__c);
            bvdMap.put('newBvdId',          newBvdId);
            bvdUpdates.add(bvdMap);

            toUpdate.add(new Account(
                Id                = sibling.Id,
                BvD_ID_Number__c  = newBvdId
            ));
        }
        if (toUpdate.isEmpty()) return;

        // 4. Update siblings in SF — guard to avoid recursive propagation
        skipBvdPropagation = true;
        try {
            update toUpdate;
        } finally {
            skipBvdPropagation = false;
        }

        // 5. Fire CFin writeback for each sibling independently
        if (!bvdUpdates.isEmpty() && !Test.isRunningTest()) {
            UpdateBvdIdInSourceSystemService.updateBvdIdInSAP(bvdUpdates);
        }
    }

    /**
     * @description Mirrors the "BvD ID" validation rule: a sibling is
     *              protected from BvD ID propagation if its Check Rule is
     *              'Z08 Risk Class Child' or its Credit Group is one of the
     *              restricted values.
     */
    private static Boolean isProtectedFromBvdChange(Account acc) {
        if (PROTECTED_CHECK_RULES.contains(acc.celsrm__Check_Rule__c)) {
            return true;
        }
        if (PROTECTED_CREDIT_GROUPS.contains(acc.celsrm__Credit_Group__c)) {
            return true;
        }
        return false;
    }
}