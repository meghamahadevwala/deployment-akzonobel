global with sharing class NAM_CUSTSTAT_IND6ExecutorSchedule implements Schedulable,Database.AllowsCallouts{
    global void execute(SchedulableContext ctx) {
        try{
            Id batchId = Database.executeBatch(new celsrm.SRMAutoDunningTreatmentService('NAM_CUSTSTAT_IND6'), 1);
            System.debug('batchId : ' + batchId);
        }catch(Exception e){
            System.debug('Error in NAM_CUSTSTAT_IND6ExecutorSchedule : ' + e.getMessage());
        }
    }
}