global with sharing class NAM_CUSTSTAT_IND9GeneratorSchedule implements Schedulable,Database.AllowsCallouts{
    global void execute(SchedulableContext ctx) {
        try{
            Id batchId = Database.executeBatch(new celsrm.SRMTreatmentService('NAM_CUSTSTAT_IND9'), 1);
            System.debug('batchId : ' + batchId);
        }catch(Exception e){
            System.debug('Error in NAM_CUSTSTAT_IND9GeneratorSchedule : ' + e.getMessage());
        }
    }
}