global with sharing class EMEA_CUSTSTAT_IND9ExecutorSchedule implements Schedulable,Database.AllowsCallouts{
    global void execute(SchedulableContext ctx) {
        try{
            Id batchId = Database.executeBatch(new celsrm.SRMAutoDunningTreatmentService('EMEA_CUSTSTAT_IND9'), 1);
            System.debug('batchId : ' + batchId);
        }catch(Exception e){
            System.debug('Error in EMEA_CUSTSTAT_IND9ExecutorSchedule : ' + e.getMessage());
        }
    }
}