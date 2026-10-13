global with sharing class SAM_CUSTSTAT_IND5GeneratorSchedule implements Schedulable,Database.AllowsCallouts{
    global void execute(SchedulableContext ctx) {
        try{
            Id batchId = Database.executeBatch(new celsrm.SRMAutoDunningTreatmentService('SAM_CUSTSTAT_IND5'), 1);
            System.debug('batchId : ' + batchId);
        }catch(Exception e){
            System.debug('Error in SAM_CUSTSTAT_IND5GeneratorSchedule : ' + e.getMessage());
        }
    }
}