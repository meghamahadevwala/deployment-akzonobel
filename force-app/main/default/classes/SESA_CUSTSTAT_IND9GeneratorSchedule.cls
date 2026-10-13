global with sharing class SESA_CUSTSTAT_IND9GeneratorSchedule implements Schedulable,Database.AllowsCallouts{
    global void execute(SchedulableContext ctx) {
        try{
            Id batchId = Database.executeBatch(new celsrm.SRMAutoDunningTreatmentService('SESA_CUSTSTAT_IND9'), 1);
            System.debug('batchId : ' + batchId);
        }catch(Exception e){
            System.debug('Error in SESA_CUSTSTAT_IND9GeneratorSchedule : ' + e.getMessage());
        }
    }
}