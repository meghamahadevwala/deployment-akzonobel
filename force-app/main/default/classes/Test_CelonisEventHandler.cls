public with sharing class Test_CelonisEventHandler {

    public void beforeInsert(List<celsrm__Celonis_Event__c> newList){
        validateBeforeInsert(newList);
    }

    public Set<Id> collectTransactionIds(
        List<celsrm__Celonis_Event__c> newList,
        List<celsrm__Celonis_Event__c> oldList,
        Boolean isDelete
    ){
        Set<Id> txIds = new Set<Id>();

        List<celsrm__Celonis_Event__c> source =
            isDelete ? oldList : newList;

        if(source == null) return txIds;

        for(celsrm__Celonis_Event__c ev : source){
            if(ev.celsrm__Transaction__c != null){
                txIds.add(ev.celsrm__Transaction__c);
            }
        }

        return txIds;
    }

    // 🔒 SOLO VALIDACIÓN
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
                SELECT Id, Status_Event__c
                FROM celsrm__Transaction__c
                WHERE Id IN :txIds
            ]);

        Map<Id, Integer> totalP2P = new Map<Id, Integer>();
        Map<Id, Integer> reverseCount = new Map<Id, Integer>();

        for (AggregateResult ar : [
            SELECT celsrm__Transaction__c txId, COUNT(Id) cnt
            FROM celsrm__Celonis_Event__c
            WHERE celsrm__Transaction__c IN :txIds
            AND Name = 'Promise To Pay'
            GROUP BY celsrm__Transaction__c
        ]) {
            totalP2P.put((Id) ar.get('txId'), (Integer) ar.get('cnt'));
        }

        for (AggregateResult ar : [
            SELECT celsrm__Transaction__c txId, COUNT(Id) cnt
            FROM celsrm__Celonis_Event__c
            WHERE celsrm__Transaction__c IN :txIds
            AND Name = 'Promise Reversed'
            GROUP BY celsrm__Transaction__c
        ]) {
            reverseCount.put((Id) ar.get('txId'), (Integer) ar.get('cnt'));
        }

        for (celsrm__Celonis_Event__c ev : newList) {

            if (ev.Name != 'Promise To Pay') continue;

            Id txId = ev.celsrm__Transaction__c;

            Integer total = totalP2P.get(txId) == null ? 0 : totalP2P.get(txId);
            Integer rev = reverseCount.get(txId) == null ? 0 : reverseCount.get(txId);
            Integer active = total - rev;

            if (txMap.get(txId).Status_Event__c == '20') {
                ev.addError('Transaction is closed.');
            }

            if (total >= 2) {
                ev.addError('Maximum 2 Promise To Pay allowed.');
            }

            if (active >= 1) {
                ev.addError('Only 1 active Promise To Pay allowed.');
            }
        }
    }
}