global with sharing class SAM_CUSTSTAT_IND2ExecutorSchedule implements Schedulable,Database.AllowsCallouts{
    global void execute(SchedulableContext ctx) {
        try{
            Id batchId = Database.executeBatch(new celsrm.SRMAutoDunningTreatmentService('SAM_CUSTSTAT_IND2'), 1);
            System.debug('batchId : ' + batchId);
        }catch(Exception e){
            System.debug('Error in SAM_CUSTSTAT_IND2ExecutorSchedule : ' + e.getMessage());
        }
    }
}