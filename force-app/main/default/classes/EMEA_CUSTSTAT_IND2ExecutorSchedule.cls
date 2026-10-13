global with sharing class EMEA_CUSTSTAT_IND2ExecutorSchedule implements Schedulable,Database.AllowsCallouts{
    global void execute(SchedulableContext ctx) {
        try{
            Id batchId = Database.executeBatch(new cSRMAutoDunningTreatmentService('EMEA_CUSTSTAT_IND2'), 1);
            System.debug('batchId : ' + batchId);
        }catch(Exception e){
            System.debug('Error in EMEA_CUSTSTAT_IND2ExecutorSchedule : ' + e.getMessage());
        }
    }
}