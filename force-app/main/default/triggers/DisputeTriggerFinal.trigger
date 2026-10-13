/**************************************************************************************************
TRIGGER
DisputeTrigger.trigger
**************************************************************************************************/
trigger DisputeTriggerFinal on celsrm__Dispute__c (
    after insert,
    after update,
    after delete,
    after undelete
) {

    Set<Id> txIds = new Set<Id>();


    // NEW VALUES
    if(
        Trigger.isInsert ||
        Trigger.isUpdate ||
        Trigger.isUndelete
    ){

        for(celsrm__Dispute__c d : Trigger.new){

            if(d.celsrm__Transaction__c != null){
                txIds.add(d.celsrm__Transaction__c);
            }
        }
    }


    // OLD VALUES
    if(
        Trigger.isDelete ||
        Trigger.isUpdate
    ){

        for(celsrm__Dispute__c d : Trigger.old){

            if(d.celsrm__Transaction__c != null){
                txIds.add(d.celsrm__Transaction__c);
            }
        }
    }


    if(!txIds.isEmpty()){

        // UPDATE OPEN DISPUTE COUNT
        DisputeCounterService.updateCounts(
            txIds
        );

        // RECALCULATE DUNNING BLOCK
        CollectionBlockingService.recalculate(
            txIds
        );
    }
}