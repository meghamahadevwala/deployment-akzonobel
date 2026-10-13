public with sharing class PropagateProfileDataToAccounts implements Database.Batchable<SObject>, Database.Stateful {
    public static Boolean skipAccountAutomation = false;

    // Accounts with this Check Rule are skipped by the conventional sibling propagation
    // and only receive the Credit Group from their parent account, in a later, separate DML
    @TestVisible private static final String CHILD_CHECK_RULE = 'Z08 Risk Class Child';

    private enum Phase { SIBLINGS, CHILDREN }

    private Phase currentPhase;
    private Map<Id, String> creditGroupBySiblingId;
    private Set<Id> parentIds;

    public PropagateProfileDataToAccounts(List<Id> accountIds) {
        this.currentPhase = Phase.SIBLINGS;
        this.creditGroupBySiblingId = new Map<Id, String>();
        this.parentIds = new Set<Id>();

        if (accountIds != null && !accountIds.isEmpty()) {
            this.creditGroupBySiblingId = resolveSiblingCreditGroups(new Set<Id>(accountIds), this.parentIds);
        }
    }

    // Second phase: runs after sibling updates have been committed, so each parent's
    // Risk Class/Check Rule has already been recomputed when the child's Flow reads it
    private PropagateProfileDataToAccounts(Set<Id> parentIds) {
        this.currentPhase = Phase.CHILDREN;
        this.creditGroupBySiblingId = new Map<Id, String>();
        this.parentIds = parentIds;
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        if (currentPhase == Phase.CHILDREN) {
            Set<Id> parents = parentIds;
            String childCheckRule = CHILD_CHECK_RULE;

            return Database.getQueryLocator([
                SELECT Id, ParentId, celsrm__Credit_Group__c, Parent.celsrm__Credit_Group__c
                FROM Account
                WHERE ParentId IN :parents
                AND Id NOT IN :parents
                AND (celsrm__App_Name__c = 'Credit' OR celsrm__App_Name__c = 'credit')
                AND celsrm__Check_Rule__c = :childCheckRule
            ]);
        }

        Set<Id> siblingIds = creditGroupBySiblingId.keySet();

        return Database.getQueryLocator([
            SELECT Id, celsrm__Credit_Group__c
            FROM Account
            WHERE Id IN :siblingIds
        ]);
    }

    public void execute(Database.BatchableContext bc, List<Account> scope) {
        List<Account> toUpdate = (currentPhase == Phase.CHILDREN)
            ? buildChildUpdates(scope)
            : buildSiblingUpdates(scope, creditGroupBySiblingId);

        if (toUpdate.isEmpty()) return;

        PropagateProfileDataToAccounts.skipAccountAutomation = true;
        try {
            updateWithRetry(toUpdate);
        } finally {
            PropagateProfileDataToAccounts.skipAccountAutomation = false;
        }
    }

    public void finish(Database.BatchableContext bc) {
        System.debug('PropagateProfileDataToAccounts batch finished. Phase: ' + currentPhase);

        if (currentPhase == Phase.SIBLINGS && !parentIds.isEmpty()) {
            Database.executeBatch(new PropagateProfileDataToAccounts(parentIds));
        }
    }

    /**
     * @description Synchronous counterpart to the batch flow above, for AccountMasterTrigger's
     * direct manual-edit path (a user editing Credit Group on a single Account). Volumes there
     * are small — one save, at most a handful of Credit Segments sharing the same AccountNumber —
     * unlike GetMoodysDataService's bulk Moody's refresh, which can touch many accounts at once
     * and stays on the async Database.executeBatch(...) path above.
     *
     * Running this in the SAME transaction as the user's save (instead of a separate, later batch
     * job) removes the timing window where the batch's own transaction lands after something else
     * has already touched the source Account again — that gap was producing a symptom where the
     * source Account appeared to recompute "out of nowhere" with a different value sometime after
     * the save, once the async batch finally ran.
     *
     * Siblings and children are updated in two separate DML statements: children must be saved
     * after their parent's Risk Class/Check Rule has been recomputed, because the child's Flow
     * copies the parent's Risk Class at save time.
     */
    public static void propagateSync(List<Id> accountIds) {
        if (accountIds == null || accountIds.isEmpty()) {
            return;
        }

        Set<Id> parentIds = new Set<Id>();
        Map<Id, String> creditGroupBySiblingId = resolveSiblingCreditGroups(new Set<Id>(accountIds), parentIds);

        // Step 1: conventional sibling propagation (children excluded)
        if (!creditGroupBySiblingId.isEmpty()) {
            Set<Id> siblingIds = creditGroupBySiblingId.keySet();
            List<Account> siblings = [
                SELECT Id, celsrm__Credit_Group__c
                FROM Account
                WHERE Id IN :siblingIds
            ];
            updateWithGuard(buildSiblingUpdates(siblings, creditGroupBySiblingId));
        }

        // Step 2: children, in a separate DML so their parent is already recomputed
        if (!parentIds.isEmpty()) {
            String childCheckRule = CHILD_CHECK_RULE;
            List<Account> children = [
                SELECT Id, ParentId, celsrm__Credit_Group__c, Parent.celsrm__Credit_Group__c
                FROM Account
                WHERE ParentId IN :parentIds
                AND Id NOT IN :parentIds
                AND (celsrm__App_Name__c = 'Credit' OR celsrm__App_Name__c = 'credit')
                AND celsrm__Check_Rule__c = :childCheckRule
            ];
            updateWithGuard(buildChildUpdates(children));
        }
    }

    /**
     * @description Resolves conventional sibling targets: accounts sharing a source's AccountNumber,
     * excluding child accounts (Check Rule 'Z08 Risk Class Child'). Fills parentIdsOut with every
     * account involved in the propagation (sources + siblings), whose children are handled later.
     */
    @TestVisible
    private static Map<Id, String> resolveSiblingCreditGroups(Set<Id> sourceIds, Set<Id> parentIdsOut) {
        Map<Id, String> creditGroupBySiblingId = new Map<Id, String>();
        Map<String, String> creditGroupByAccountNumber = new Map<String, String>();

        parentIdsOut.addAll(sourceIds);

        for (Account acc : [
            SELECT Id, AccountNumber, celsrm__Credit_Group__c
            FROM Account
            WHERE Id IN :sourceIds
        ]) {
            if (acc.AccountNumber == null) continue;
            if (!creditGroupByAccountNumber.containsKey(acc.AccountNumber)) {
                creditGroupByAccountNumber.put(acc.AccountNumber, acc.celsrm__Credit_Group__c);
            }
        }

        if (creditGroupByAccountNumber.isEmpty()) {
            return creditGroupBySiblingId;
        }

        Set<String> accountNumbers = creditGroupByAccountNumber.keySet();
        String childCheckRule = CHILD_CHECK_RULE;

        for (Account sibling : [
            SELECT Id, AccountNumber
            FROM Account
            WHERE AccountNumber IN :accountNumbers
            AND Id NOT IN :sourceIds
            AND (celsrm__App_Name__c = 'Credit' OR celsrm__App_Name__c = 'credit')
            AND celsrm__Check_Rule__c != :childCheckRule
        ]) {
            creditGroupBySiblingId.put(sibling.Id, creditGroupByAccountNumber.get(sibling.AccountNumber));
            parentIdsOut.add(sibling.Id);
        }

        return creditGroupBySiblingId;
    }

    private static List<Account> buildSiblingUpdates(List<Account> siblings, Map<Id, String> creditGroupBySiblingId) {
        List<Account> toUpdate = new List<Account>();

        for (Account acc : siblings) {
            if (!creditGroupBySiblingId.containsKey(acc.Id)) continue;

            String newCreditGroup = creditGroupBySiblingId.get(acc.Id);

            // Skip records that already have the same Credit Group
            if (acc.celsrm__Credit_Group__c == newCreditGroup) continue;

            toUpdate.add(new Account(Id = acc.Id, celsrm__Credit_Group__c = newCreditGroup));
        }
        return toUpdate;
    }

    // Children take their parent's Credit Group as currently stored, i.e. after step 1 committed
    private static List<Account> buildChildUpdates(List<Account> children) {
        List<Account> toUpdate = new List<Account>();

        for (Account child : children) {
            if (child.Parent == null) continue;

            String newCreditGroup = child.Parent.celsrm__Credit_Group__c;

            // Skip records that already have the same Credit Group
            if (child.celsrm__Credit_Group__c == newCreditGroup) continue;

            toUpdate.add(new Account(Id = child.Id, celsrm__Credit_Group__c = newCreditGroup));
        }
        return toUpdate;
    }

    // Recursion guard: the update fires AccountMasterTrigger again for every target, and the flag
    // stops it from re-entering the profile-sync / CG-propagation blocks. Record-triggered Flows
    // ("Risk Class and Check Rule 1/2") still run, which is how each target's Risk Class/Check Rule
    // gets recomputed.
    private static void updateWithGuard(List<Account> toUpdate) {
        if (toUpdate.isEmpty()) {
            return;
        }

        Boolean previousSkipAccountAutomation = skipAccountAutomation;
        skipAccountAutomation = true;
        try {
            Database.SaveResult[] results = Database.update(toUpdate, false);
            for (Integer i = 0; i < results.size(); i++) {
                if (!results[i].isSuccess()) {
                    for (Database.Error err : results[i].getErrors()) {
                        System.debug('PropagateProfileDataToAccounts.propagateSync failed for ' + toUpdate[i].Id + ': ' + err.getMessage());
                    }
                }
            }
        } finally {
            skipAccountAutomation = previousSkipAccountAutomation;
        }
    }

    private static void updateWithRetry(List<Account> toUpdate) {
        List<Account> retryList = toUpdate;
        Integer maxRetries = 3;

        for (Integer attempt = 1; attempt <= maxRetries && !retryList.isEmpty(); attempt++) {
            System.debug('Attempt: ' + attempt + ' | Records: ' + retryList.size());
            Database.SaveResult[] results = Database.update(retryList, false);
            List<Account> failedAgain = new List<Account>();

            for (Integer i = 0; i < results.size(); i++) {
                if (results[i].isSuccess()) continue;

                Boolean retryable = false;
                for (Database.Error err : results[i].getErrors()) {
                    if (err.getStatusCode() == StatusCode.UNABLE_TO_LOCK_ROW) {
                        retryable = true;
                    } else {
                        System.debug('Permanent Failure: ' + retryList[i].Id);
                        System.debug('Error: ' + err.getMessage());
                    }
                }
                if (retryable) {
                    failedAgain.add(retryList[i]);
                }
            }
            retryList = failedAgain;
        }

        // Final failures after all retries
        for (Account acc : retryList) {
            System.debug('Failed after ' + maxRetries + ' attempts: ' + acc.Id);
        }
    }
}