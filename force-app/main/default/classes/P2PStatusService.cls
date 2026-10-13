/**************************************************************************************************
CLASS
P2PStatusService.cls
**************************************************************************************************/
public with sharing class P2PStatusService {

    public static void recalculate(
        Set<Id> txIds
    ) {
        if (txIds.isEmpty()) return;

        Map<Id, Integer> p2pCount = new Map<Id, Integer>();
        Map<Id, Integer> revCount = new Map<Id, Integer>();

        for (AggregateResult ar : [
            SELECT celsrm__Transaction__c txId,
                   COUNT(Id) cnt
            FROM celsrm__Celonis_Event__c
            WHERE celsrm__Transaction__c IN :txIds
            AND Name = 'Promise To Pay'
            GROUP BY celsrm__Transaction__c
        ]) {
            p2pCount.put(
                (Id) ar.get('txId'),
                (Integer) ar.get('cnt')
            );
        }

        for (AggregateResult ar : [
            SELECT celsrm__Transaction__c txId,
                   COUNT(Id) cnt
            FROM celsrm__Celonis_Event__c
            WHERE celsrm__Transaction__c IN :txIds
            AND Name = 'Promise Reversed'
            GROUP BY celsrm__Transaction__c
        ]) {
            revCount.put(
                (Id) ar.get('txId'),
                (Integer) ar.get('cnt')
            );
        }

        List<celsrm__Transaction__c> updates = [
            SELECT Id,
                   Close_Date_NF__c,
                   celsrm__Clearing_Document__c,
                   Status_Event__c
            FROM celsrm__Transaction__c
            WHERE Id IN :txIds
        ];

        for (celsrm__Transaction__c tx : updates) {

            Integer p2p =
                p2pCount.containsKey(tx.Id)
                ? p2pCount.get(tx.Id)
                : 0;

            Integer rev =
                revCount.containsKey(tx.Id)
                ? revCount.get(tx.Id)
                : 0;

            Integer active = p2p - rev;

            if (
                tx.Close_Date_NF__c != null &&
                tx.celsrm__Clearing_Document__c != null
            ) {
                tx.Status_Event__c = '20';
            }
            else if (active > 0) {
                tx.Status_Event__c = '10';
            }
            else if (rev > 0) {
                tx.Status_Event__c = '30';
            }
            else {
                tx.Status_Event__c = null;
            }
        }

        update updates;
    }
}