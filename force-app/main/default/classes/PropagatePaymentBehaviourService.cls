public with sharing class PropagatePaymentBehaviourService {

    /**
     * Static recursion guard. Holds the Ids of accounts already processed
     * (as a trigger source, or already updated by this service) in the
     * current transaction, so that the DML this service performs on parent
     * accounts does not cause AccountMasterTrigger to re-invoke this same
     * propagation indefinitely.
     */
    private static Set<Id> processedSourceIds = new Set<Id>();

    /**
     * Entry point to be called from AccountMasterTrigger (after update
     * context), with the set of Account Ids whose celsrm__Payment_Behaviour_Text__c
     * and/or celsrm__Payment_Behaviour_Trend__c changed in this transaction.
     *
     * The parent account ALWAYS reflects the worst behaviour among ALL of
     * its children:
     * - A changed CHILD account triggers a recompute of the worst behaviour
     *   among ALL of that parent's children (not just the one that
     *   changed), using PaymentBehaviourMultiplierService.getMultiplier(...)
     *   as the score (On Time=1.2, Late+Improved=1.1, Late=1.0,
     *   Very Late=0.9, Declined=0.8 - HIGHER is BETTER). The parent's
     *   celsrm__Payment_Behaviour_Text__c / celsrm__Payment_Behaviour_Trend__c is then set to
     *   match whichever child currently has the lowest (worst) score.
     * - A changed PARENT account (edited directly) is checked against its
     *   own children the same way: if the new value the user just saved is
     *   BETTER than the worst child, it is silently snapped back to match
     *   the worst child. No validation error is raised - the save succeeds,
     *   but the improved value does not stick.
     * - Children are NEVER modified by this service, only read.
     * - Moody_s_Credit_Limit__c and Moody_s_Risk_Class__c are NEVER touched.
     *
     * @param changedAccountIds Ids of accounts whose celsrm__Payment_Behaviour_Text__c or
     *        celsrm__Payment_Behaviour_Trend__c changed in this transaction.
     */
    public static void propagateWorstBehaviour(Set<Id> changedAccountIds) {
        if (changedAccountIds == null || changedAccountIds.isEmpty()) {
            return;
        }

        // Recursion guard: drop any Id we've already used as a propagation
        // source (or already updated) in this transaction.
        Set<Id> idsToProcess = new Set<Id>();
        for (Id accId : changedAccountIds) {
            if (!processedSourceIds.contains(accId)) {
                idsToProcess.add(accId);
            }
        }
        if (idsToProcess.isEmpty()) {
            System.debug('LOGTRACE >>> PropagatePaymentBehaviourService: all Ids already processed in this transaction, skipping.');
            return;
        }
        processedSourceIds.addAll(idsToProcess);

        // Load Id + ParentId for every changed account, so we can tell
        // apart "changed child" (has ParentId) from "changed parent/root"
        // (no ParentId) - BOTH cases must trigger a recompute:
        //   - a child got worse/better -> parent must reflect the worst child
        //   - the parent itself was edited to something BETTER than its
        //     worst child -> must be snapped back to the worst child
        Map<Id, Account> changedAccounts = new Map<Id, Account>(
            [SELECT Id, ParentId
             FROM Account
             WHERE Id IN :idsToProcess]
        );

        if (changedAccounts.isEmpty()) {
            System.debug('LOGTRACE >>> PropagatePaymentBehaviourService: no matching accounts found, nothing to propagate.');
            return;
        }

        Set<Id> parentIds = new Set<Id>();
        for (Account a : changedAccounts.values()) {
            if (a.ParentId != null) {
                // Changed account is a child -> its parent needs recompute.
                parentIds.add(a.ParentId);
            } else {
                // Changed account has no ParentId -> it MIGHT be a parent
                // with children of its own; add it as a candidate too. If it
                // turns out to have no children, it's simply skipped below.
                parentIds.add(a.Id);
            }
        }

        if (parentIds.isEmpty()) {
            System.debug('LOGTRACE >>> PropagatePaymentBehaviourService: no candidate parent accounts to recompute.');
            return;
        }

        // Load the parents + ALL of their children (not just the one that
        // changed) - the parent must reflect the worst among ALL children.
        List<Account> parentAndChildren = [
            SELECT Id, ParentId, celsrm__Payment_Behaviour_Text__c, celsrm__Payment_Behaviour_Trend__c
            FROM Account
            WHERE Id IN :parentIds
               OR ParentId IN :parentIds
        ];

        Map<Id, Account> parentsById = new Map<Id, Account>();
        Map<Id, List<Account>> childrenByParent = new Map<Id, List<Account>>();

        for (Account a : parentAndChildren) {
            if (parentIds.contains(a.Id)) {
                parentsById.put(a.Id, a);
            }
            if (a.ParentId != null && parentIds.contains(a.ParentId)) {
                if (!childrenByParent.containsKey(a.ParentId)) {
                    childrenByParent.put(a.ParentId, new List<Account>());
                }
                childrenByParent.get(a.ParentId).add(a);
            }
        }

        List<Account> parentsToUpdate = new List<Account>();

        for (Id parentId : parentIds) {
            Account parent = parentsById.get(parentId);
            List<Account> children = childrenByParent.get(parentId);
            if (parent == null || children == null || children.isEmpty()) {
                continue;
            }

            Account worstChild = null;
            Decimal worstScore = null;
            for (Account child : children) {
                Decimal score = PaymentBehaviourMultiplierService.getMultiplier(
                    child.celsrm__Payment_Behaviour_Text__c,
                    child.celsrm__Payment_Behaviour_Trend__c
                );
                System.debug('LOGTRACE >>> Child ' + child.Id + ' | celsrm__Payment_Behaviour_Text__c=' + child.celsrm__Payment_Behaviour_Text__c
                    + ' | Trend=' + child.celsrm__Payment_Behaviour_Trend__c + ' | score=' + score);

                // Strictly lower score wins as "worst"; ties keep the first
                // one found, so the outcome is stable within a single run.
                if (worstScore == null || score < worstScore) {
                    worstScore = score;
                    worstChild = child;
                }
            }

            if (worstChild == null) {
                continue;
            }

            System.debug('LOGTRACE >>> Worst child for parent ' + parent.Id + ' is ' + worstChild.Id
                + ' (score=' + worstScore + ', celsrm__Payment_Behaviour_Text__c=' + worstChild.celsrm__Payment_Behaviour_Text__c
                + ', Trend=' + worstChild.celsrm__Payment_Behaviour_Trend__c + ')');

            if (parent.celsrm__Payment_Behaviour_Text__c != worstChild.celsrm__Payment_Behaviour_Text__c ||
                parent.celsrm__Payment_Behaviour_Trend__c != worstChild.celsrm__Payment_Behaviour_Trend__c) {
                System.debug('LOGTRACE >>> Updating parent ' + parent.Id + ' from (celsrm__Payment_Behaviour_Text__c=' + parent.celsrm__Payment_Behaviour_Text__c
                    + ', Trend=' + parent.celsrm__Payment_Behaviour_Trend__c + ') to worst child value (celsrm__Payment_Behaviour_Text__c='
                    + worstChild.celsrm__Payment_Behaviour_Text__c + ', Trend=' + worstChild.celsrm__Payment_Behaviour_Trend__c + ')');
                parent.celsrm__Payment_Behaviour_Text__c = worstChild.celsrm__Payment_Behaviour_Text__c;
                parent.celsrm__Payment_Behaviour_Trend__c = worstChild.celsrm__Payment_Behaviour_Trend__c;
                parentsToUpdate.add(parent);
                // Mark the parent as processed so the resulting after-update
                // re-entry (for this forced change) doesn't try to treat it
                // as a fresh, independent source change (it has no
                // ParentId anyway, so it would be skipped regardless - this
                // is just an extra safety net).
                processedSourceIds.add(parent.Id);
            } else {
                System.debug('LOGTRACE >>> Parent ' + parent.Id + ' already matches worst child, no update needed.');
            }
        }

        if (!parentsToUpdate.isEmpty()) {
            System.debug('LOGTRACE >>> PropagatePaymentBehaviourService updating ' + parentsToUpdate.size() + ' parent account(s).');
            update parentsToUpdate;
        }
    }
}