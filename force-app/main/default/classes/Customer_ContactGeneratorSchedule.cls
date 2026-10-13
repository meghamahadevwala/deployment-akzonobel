global with sharing class Customer_ContactGeneratorSchedule implements Schedulable,Database.AllowsCallouts{
    global void execute(SchedulableContext ctx) {
        try{
            Id batchId = Database.executeBatch(new celsrm.SRMTreatmentService('Customer_Contact'), 1);
            System.debug('batchId : ' + batchId);
        }catch(Exception e){
            System.debug('Error in Customer_ContactGeneratorSchedule : ' + e.getMessage());
        }
    }
}