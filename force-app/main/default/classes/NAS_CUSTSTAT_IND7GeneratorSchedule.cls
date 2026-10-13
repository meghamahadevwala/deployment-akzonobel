global with sharing class NAS_CUSTSTAT_IND7GeneratorSchedule implements Schedulable,Database.AllowsCallouts{
    global void execute(SchedulableContext ctx) {
        try{
            Id batchId = Database.executeBatch(new celsrm.SRMAutoDunningTreatmentService('NAS_CUSTSTAT_IND7'), 1);
            System.debug('batchId : ' + batchId);
        }catch(Exception e){
            System.debug('Error in NAS_CUSTSTAT_IND7GeneratorSchedule : ' + e.getMessage());
        }
    }
}