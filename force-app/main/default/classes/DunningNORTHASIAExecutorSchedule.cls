global with sharing class DunningNORTHASIAExecutorSchedule implements Schedulable,Database.AllowsCallouts{
    global void execute(SchedulableContext ctx) {
        try{
            Id batchId = Database.executeBatch(new celsrm.SRMAutoDunningTreatmentService('DUNNING-NORTH ASIA'), 1);
            System.debug('batchId : ' + batchId);
        }catch(Exception e){
            System.debug('Error in DunningNORTHASIAExecutorSchedule : ' + e.getMessage());
        }
    }
}