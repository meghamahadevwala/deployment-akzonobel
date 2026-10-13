/*
global with sharing class DunningSESAGeneratorSchedule implements Schedulable,Database.AllowsCallouts{
    global void execute(SchedulableContext ctx) {
        try{
            Id batchId = Database.executeBatch(new celsrm.SRMTreatmentService('DUNNING-SESA'), 1);
            System.debug('batchId : ' + batchId);
        }catch(Exception e){
            System.debug('Error in DunningSESAGeneratorSchedule : ' + e.getMessage());
        }
    }
}
*/

// DunningSESAGeneratorSchedule.cls
global with sharing class DunningSESAGeneratorSchedule implements Schedulable {
    global void execute(SchedulableContext ctx) {
        try {
            Database.executeBatch(new DunningProcessingBatch('South Asia and Oceania', 'DUNNING-SESA'), 200);
        } catch (Exception e) {
            System.debug('Error in DunningSESAGeneratorSchedule : ' + e.getMessage());
        }
    }
}