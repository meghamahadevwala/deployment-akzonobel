global with sharing class DunningNorthAmericaExecutorSchedule implements Schedulable,Database.AllowsCallouts{
    global void execute(SchedulableContext ctx) {
        try{
            Id batchId = Database.executeBatch(new celsrm.SRMAutoDunningTreatmentService('DUNNING-NORTH AMERICA'), 1);
            System.debug('batchId : ' + batchId);
        }catch(Exception e){
            System.debug('Error in DunningNorthAmericaExecutorSchedule : ' + e.getMessage());
        }
    }
}