/**
 * @trigger    TransactionP2PHandlerTrigger
 * @object     celsrm__Transaction__c
 * @events     after update
 *
 * @description
 * Fires when a Promise to Pay (P2P) transaction is updated directly on the
 * Transaction record — specifically when the promised date or promised amount
 * changes. These fields live natively on celsrm__Transaction__c and are edited
 * through the HighRadius UI or other direct DML operations.
 *
 * DECOUPLING NOTE:
 * This trigger handles the "UPDATE" leg of the SAP sync exclusively.
 * The CREATE and DELETE legs are owned by P2PSyncTriggerCE, which listens on
 * celsrm__Celonis_Event__c. Although Celonis Events are the authoritative source
 * for P2P lifecycle signals (creation and reversal), their payload does NOT carry
 * the mutable P2P fields (Promise Date, Promised Amount). Those live only on the
 * Transaction. Therefore, updates to those fields MUST originate from this trigger
 * rather than from the event-based one.
 *
 * GUARD FLAG:
 * SyncP2PWithSAPService.allowExternalUpdate is set to true immediately before
 * calling syncP2P and reset to false right after. This flag prevents UPDATE
 * callouts from being fired by any other code path (e.g. managed package handlers
 * or unrelated triggers that also write to Transaction records), ensuring that
 * SAP is only notified when a deliberate, field-relevant change has occurred.
 *
 * @see SyncP2PWithSAPService
 * @see P2PSyncTriggerCE
 */
trigger TransactionP2PHandlerTrigger on celsrm__Transaction__c (after update) {

    Set<Id> updateIds = new Set<Id>();

    for (celsrm__Transaction__c tx : Trigger.new) {
        celsrm__Transaction__c oldTx = Trigger.oldMap.get(tx.Id);

        Boolean relevantChange =
            tx.Promised_Date_NF__c        != oldTx.Promised_Date_NF__c ||
            tx.celsrm__Promised_Amount__c != oldTx.celsrm__Promised_Amount__c;

        if (relevantChange) updateIds.add(tx.Id);
    }

    if (!updateIds.isEmpty()) {
        SyncP2PWithSAPService.allowExternalUpdate = true;
        SyncP2PWithSAPService.syncP2P(new List<Id>(updateIds), 'UPDATE');
        SyncP2PWithSAPService.allowExternalUpdate = false;
    }
}