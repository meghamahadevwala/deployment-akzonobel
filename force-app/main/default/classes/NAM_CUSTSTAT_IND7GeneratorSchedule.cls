global with sharing class NAM_CUSTSTAT_IND7GeneratorSchedule implements Schedulable,Database.AllowsCallouts{
    global void execute(SchedulableContext ctx) {
        try{
            Id batchId = Database.executeBatch(new celsrm.SRMAutoDunningTreatmentService('NAM_CUSTSTAT_IND7'), 1);
            System.debug('batchId : ' + batchId);
        }catch(Exception e){
            System.debug('Error in NAM_CUSTSTAT_IND7GeneratorSchedule : ' + e.getMessage());
        }
    }
}