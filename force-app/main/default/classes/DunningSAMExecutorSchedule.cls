global with sharing class DunningSAMExecutorSchedule implements Schedulable,Database.AllowsCallouts{
    global void execute(SchedulableContext ctx) {
        try{
            Id batchId = Database.executeBatch(new celsrm.SRMAutoDunningTreatmentService('DUNNING-SAM'), 1);
            System.debug('batchId : ' + batchId);
        }catch(Exception e){
            System.debug('Error in DunningSAMExecutorSchedule : ' + e.getMessage());
        }
    }
}