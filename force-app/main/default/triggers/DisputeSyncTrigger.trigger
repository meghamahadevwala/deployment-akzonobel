trigger DisputeSyncTrigger on celsrm__Dispute__c (after insert, after update) {

    if(Trigger.isAfter){

        if(Trigger.isInsert){

            SyncDisputeWithCelonisService.syncDisputes(
                new List<Id>(Trigger.newMap.keySet()),
                true
            );
        }

        if(Trigger.isUpdate){

            Set<Id> changedIds = new Set<Id>();

            for(celsrm__Dispute__c d : Trigger.new){

                celsrm__Dispute__c oldRec = Trigger.oldMap.get(d.Id);

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
}