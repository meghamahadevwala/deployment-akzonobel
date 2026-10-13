global with sharing class DunningEMEAExecutorSchedule implements Schedulable,Database.AllowsCallouts{
    global void execute(SchedulableContext ctx) {
        try{
            Id batchId = Database.executeBatch(new celsrm.SRMAutoDunningTreatmentService('DUNNING-EMEA'), 1);
            System.debug('batchId : ' + batchId);
        }catch(Exception e){
            System.debug('Error in DunningEMEAExecutorSchedule : ' + e.getMessage());
        }
    }
}