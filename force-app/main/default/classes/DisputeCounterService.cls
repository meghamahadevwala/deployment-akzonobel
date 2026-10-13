public without sharing class DisputeCounterService {

    public static void updateCounts(
        Set<Id> txIds
    ){

        Map<Id,Integer> counts = new Map<Id,Integer>();


        for(AggregateResult ar : [

            SELECT celsrm__Transaction__c txId,
                   COUNT(Id) cnt
            FROM celsrm__Dispute__c
            WHERE celsrm__Transaction__c IN :txIds
            AND celsrm__Status__c NOT IN ('60 Closed','80 Voided')
            GROUP BY celsrm__Transaction__c
        ]){

            counts.put(
                (Id) ar.get('txId'),
                (Integer) ar.get('cnt')
            );
        }


        List<celsrm__Transaction__c> updates =
            new List<celsrm__Transaction__c>();


        for(Id txId : txIds){

            Integer total =
                counts.containsKey(txId)
                ? counts.get(txId)
                : 0;

            updates.add(
                new celsrm__Transaction__c(
                    Id = txId,
                    Open_Disputes_Count__c = total
                )
            );
        }


        if(!updates.isEmpty()){
            update updates;
        }
    }
}