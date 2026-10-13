// DunningEMEAGeneratorSchedule.cls
global with sharing class DunningEMEAGeneratorSchedule implements Schedulable {
    global void execute(SchedulableContext ctx) {
        try {
            Database.executeBatch(new DunningProcessingBatch('EMEA', 'DUNNING-EMEA'), 200);
        } catch (Exception e) {
            System.debug('Error in DunningEMEAGeneratorSchedule : ' + e.getMessage());
        }
    }
}