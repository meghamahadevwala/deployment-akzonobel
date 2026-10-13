global with sharing class SRMTreatmentScheduler implements Schedulable,Database.AllowsCallouts{
    global void execute(SchedulableContext ctx) {
        try{
            Id batchId = Database.executeBatch(new celsrm.SRMTreatmentService(), 4);
            System.debug('batchId : ' + batchId);
        }catch(Exception e){
            System.debug('Error in SRMTreatmentScheduler : ' + e.getMessage());
        }
    }
}