/**************************************************************************************************
MASTER TRIGGER
CelonisEventTrigger.trigger
**************************************************************************************************/
trigger CelonisEventTrigger on celsrm__Celonis_Event__c (

    before insert,
    after insert,
    after update,
    after delete,
    after undelete
) {

    /**************************************************************************************************
    BEFORE INSERT
    **************************************************************************************************/
    if (Trigger.isBefore && Trigger.isInsert) {

        CelonisEventHandler.validateBeforeInsert(
            Trigger.new
        );
    }


    /**************************************************************************************************
    AFTER EVENTS
    **************************************************************************************************/
    if (Trigger.isAfter) {

        Set<Id> txIds = new Set<Id>();


        /**************************************************************************************************
        INSERT
        **************************************************************************************************/
        if (Trigger.isInsert) {

            for (celsrm__Celonis_Event__c ev : Trigger.new) {
                if (ev.celsrm__Transaction__c != null) {
                    txIds.add(ev.celsrm__Transaction__c);
                }
            }

            CelonisEventHandler.afterChange(
                Trigger.new,
                null
            );
        }


        /**************************************************************************************************
        UPDATE
        **************************************************************************************************/
        if (Trigger.isUpdate) {

            for (celsrm__Celonis_Event__c ev : Trigger.new) {
                if (ev.celsrm__Transaction__c != null) {
                    txIds.add(ev.celsrm__Transaction__c);
                }
            }

            CelonisEventHandler.afterChange(
                Trigger.new,
                Trigger.oldMap
            );
        }


        /**************************************************************************************************
        DELETE
        **************************************************************************************************/
        if (Trigger.isDelete) {

            for (celsrm__Celonis_Event__c ev : Trigger.old) {
                if (ev.celsrm__Transaction__c != null) {
                    txIds.add(ev.celsrm__Transaction__c);
                }
            }

            CelonisEventHandler.afterDelete(
                Trigger.old
            );
        }


        /**************************************************************************************************
        UNDELETE
        **************************************************************************************************/
        if (Trigger.isUndelete) {

            for (celsrm__Celonis_Event__c ev : Trigger.new) {
                if (ev.celsrm__Transaction__c != null) {
                    txIds.add(ev.celsrm__Transaction__c);
                }
            }

            CelonisEventHandler.afterChange(
                Trigger.new,
                null
            );
        }


        /**************************************************************************************************
        NEW BLOCKING LOGIC
        **************************************************************************************************/
        if (!txIds.isEmpty()) {

            CollectionBlockingService.recalculate(
                txIds
            );
        }
    }
}