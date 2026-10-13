/**
 * @trigger    P2PSyncTriggerCE
 * @object     celsrm__Celonis_Event__c
 * @events     after insert, after delete
 *
 * @description
 * Listens to Celonis Event records to detect P2P lifecycle transitions —
 * promise creation and promise reversal — and triggers the corresponding
 * SAP sync operations (CREATE or DELETE) via SyncP2PWithSAPService.
 *
 * DECOUPLING NOTE:
 * Celonis Events are the system-of-record for when a P2P promise starts or ends.
 * However, the actual P2P data payload (promised date, promised amount, status)
 * is NOT stored on the Celonis Event itself — it is stored on the parent
 * celsrm__Transaction__c record. This trigger therefore collects the Transaction
 * IDs from the events and delegates to SyncP2PWithSAPService, which re-queries
 * the Transaction to build the full SAP payload.
 *
 * This design intentionally keeps both objects loosely coupled:
 *   - celsrm__Celonis_Event__c owns the LIFECYCLE signal (created / deleted).
 *   - celsrm__Transaction__c owns the DATA (amounts, dates, status).
 *   - SyncP2PWithSAPService owns the INTEGRATION logic.
 *
 * EVENT ROUTING:
 *
 *   INSERT  →  ev.Name == 'Promise To Pay'   → CREATE (new promise sent to SAP)
 *   INSERT  →  ev.Name == 'Promise Reversed' → DELETE (reversal detected inline,
 *                                               before the event is physically
 *                                               deleted from the database)
 *   DELETE  →  ev.Name == 'Promise To Pay'   → DELETE (physical removal of the
 *                                               PTP event; ensures SAP is cleared
 *                                               even when no 'Promise Reversed'
 *                                               event was inserted beforehand)
 *
 * NOTE: Both INSERT-based reversal and DELETE-based removal can resolve to a
 * DELETE sync. Having both paths covered prevents gaps when the reversal event
 * is not inserted (e.g. direct record deletion from admin operations).
 *
 * @see SyncP2PWithSAPService
 * @see TransactionP2PHandlerTrigger
 */
trigger P2PSyncTriggerCE on celsrm__Celonis_Event__c (
    after insert,
    after delete
) {
    Set<Id> createIds = new Set<Id>();
    Set<Id> deleteIds = new Set<Id>();

    if (Trigger.isInsert) {
        for (celsrm__Celonis_Event__c ev : Trigger.new) {
            if (ev.celsrm__Transaction__c == null) continue;
            if (ev.Name == 'Promise To Pay')   createIds.add(ev.celsrm__Transaction__c);
            if (ev.Name == 'Promise Reversed') deleteIds.add(ev.celsrm__Transaction__c);
        }
    }

    if (Trigger.isDelete) {
        for (celsrm__Celonis_Event__c ev : Trigger.old) {
            if (ev.celsrm__Transaction__c == null) continue;
            if (ev.Name == 'Promise To Pay') deleteIds.add(ev.celsrm__Transaction__c);
        }
    }

    if (!createIds.isEmpty()) SyncP2PWithSAPService.syncP2P(new List<Id>(createIds), 'CREATE');
    if (!deleteIds.isEmpty()) SyncP2PWithSAPService.syncP2P(new List<Id>(deleteIds), 'DELETE');
}