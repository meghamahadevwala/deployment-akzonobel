/**************************************************************************************************
CLASS
CelonisEventHandler.cls
**************************************************************************************************/
public with sharing class CelonisEventHandler {

    private static final Integer GRACE_PERIOD_HOURS = 24;

    public class P2PMetrics {
        public Integer countedTotal = 0; // promises that count toward the 2-promise limit
        public Integer activeCount = 0;  // 1 if there's a currently open promise, else 0
    }

    public static void validateBeforeInsert(
        List<celsrm__Celonis_Event__c> newList
    ) {

        Set<Id> txIds = new Set<Id>();

        for (celsrm__Celonis_Event__c ev : newList) {
            if (
                ev.Name == 'Promise To Pay' &&
                ev.celsrm__Transaction__c != null
            ) {
                txIds.add(ev.celsrm__Transaction__c);
            }
        }

        if (txIds.isEmpty()) return;

        Map<Id, celsrm__Transaction__c> txMap =
            new Map<Id, celsrm__Transaction__c>([
                SELECT Id,
                       Status_Event__c
                FROM celsrm__Transaction__c
                WHERE Id IN :txIds
            ]);

        Map<Id, P2PMetrics> metricsByTx = calculateMetrics(txIds);

        for (celsrm__Celonis_Event__c ev : newList) {

            if (ev.Name != 'Promise To Pay') continue;

            Id txId = ev.celsrm__Transaction__c;

            P2PMetrics metrics = metricsByTx.containsKey(txId)
                ? metricsByTx.get(txId)
                : new P2PMetrics();

            if (txMap.get(txId).Status_Event__c == '20') {
                ev.addError('Transaction is closed.');
            }

            if (metrics.countedTotal >= 2) {
                ev.addError('Maximum 2 Promise To Pay allowed.');
            }

            if (metrics.activeCount >= 1) {
                ev.addError('Only 1 active Promise To Pay allowed.');
            }
        }
    }

    /**
     * Builds per-transaction P2P metrics from the existing event history.
     *
     * A "Promise To Pay" is excluded from the 2-promise limit when it was
     * reversed within GRACE_PERIOD_HOURS of its own creation. Reversals are
     * matched to whichever promise was open when the reversal was created —
     * safe because the org enforces only one active promise at a time, so
     * there is never ambiguity about which promise a reversal closes.
     */
    private static Map<Id, P2PMetrics> calculateMetrics(Set<Id> txIds) {

        Map<Id, P2PMetrics> result = new Map<Id, P2PMetrics>();

        Map<Id, List<celsrm__Celonis_Event__c>> eventsByTx =
            new Map<Id, List<celsrm__Celonis_Event__c>>();

        for (celsrm__Celonis_Event__c ev : [
            SELECT Id,
                   Name,
                   CreatedDate,
                   celsrm__Transaction__c
            FROM celsrm__Celonis_Event__c
            WHERE celsrm__Transaction__c IN :txIds
            AND Name IN ('Promise To Pay', 'Promise Reversed')
            ORDER BY celsrm__Transaction__c, CreatedDate ASC
        ]) {
            if (!eventsByTx.containsKey(ev.celsrm__Transaction__c)) {
                eventsByTx.put(ev.celsrm__Transaction__c, new List<celsrm__Celonis_Event__c>());
            }
            eventsByTx.get(ev.celsrm__Transaction__c).add(ev);
        }

        for (Id txId : txIds) {

            P2PMetrics metrics = new P2PMetrics();

            List<celsrm__Celonis_Event__c> events =
                eventsByTx.containsKey(txId)
                ? eventsByTx.get(txId)
                : new List<celsrm__Celonis_Event__c>();

            Datetime openPromiseCreatedDate = null;

            for (celsrm__Celonis_Event__c ev : events) {

                if (ev.Name == 'Promise To Pay') {

                    openPromiseCreatedDate = ev.CreatedDate;
                    metrics.countedTotal++;

                } else if (ev.Name == 'Promise Reversed') {

                    if (openPromiseCreatedDate != null) {

                        Long hoursSinceCreation =
                            (ev.CreatedDate.getTime() - openPromiseCreatedDate.getTime())
                            / (1000 * 60 * 60);

                        if (hoursSinceCreation <= GRACE_PERIOD_HOURS) {
                            metrics.countedTotal--;
                        }
                    }

                    openPromiseCreatedDate = null;
                }
            }

            if (openPromiseCreatedDate != null) {
                metrics.activeCount = 1;
            }

            result.put(txId, metrics);
        }

        return result;
    }

    public static void afterChange(
        List<celsrm__Celonis_Event__c> newList,
        Map<Id,celsrm__Celonis_Event__c> oldMap
    ) {
        Set<Id> txIds = new Set<Id>();

        for (celsrm__Celonis_Event__c ev : newList) {
            if (ev.celsrm__Transaction__c != null) {
                txIds.add(ev.celsrm__Transaction__c);
            }
        }

        processTransactions(txIds);
    }

    public static void afterDelete(
        List<celsrm__Celonis_Event__c> oldList
    ) {
        Set<Id> txIds = new Set<Id>();

        for (celsrm__Celonis_Event__c ev : oldList) {
            if (ev.celsrm__Transaction__c != null) {
                txIds.add(ev.celsrm__Transaction__c);
            }
        }

        processTransactions(txIds);
    }

    private static void processTransactions(
        Set<Id> txIds
    ) {
        if (txIds.isEmpty()) return;

        P2PStatusService.recalculate(txIds);

        SyncP2PWithSAPService.syncP2P(
            new List<Id>(txIds),
            'UPDATE'
        );
    }
}