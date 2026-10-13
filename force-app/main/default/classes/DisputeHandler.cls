public class DisputeHandler {

    public void beforeInsert(List<celsrm__Dispute__c> newList){
        CollectionBlockingService.validateDisputeCreation(newList);
    }

    public void afterInsert(List<celsrm__Dispute__c> newList){
        SyncDisputeWithCelonisService.syncDisputes(
            new List<Id>(new Map<Id,celsrm__Dispute__c>(newList).keySet()),
            true
        );
    }

    public void afterUpdate(
        List<celsrm__Dispute__c> newList,
        Map<Id,celsrm__Dispute__c> oldMap
    ){
        Set<Id> changedIds = new Set<Id>();

        for(celsrm__Dispute__c d : newList){

            celsrm__Dispute__c oldRec = oldMap.get(d.Id);

            if(
                d.celsrm__Status__c != oldRec.celsrm__Status__c ||
                d.celsrm__Reason_Code__c != oldRec.celsrm__Reason_Code__c ||
                d.I2C_Dispute_Processor__c != oldRec.I2C_Dispute_Processor__c
            ){
                changedIds.add(d.Id);
            }
        }

        if(!changedIds.isEmpty()){
            SyncDisputeWithCelonisService.syncDisputes(
                new List<Id>(changedIds),
                false
            );
        }
    }
}