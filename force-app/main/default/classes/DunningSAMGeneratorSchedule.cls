global with sharing class DunningSAMGeneratorSchedule implements Schedulable {
    global void execute(SchedulableContext ctx) {
        try {
            Database.executeBatch(new DunningProcessingBatch('South America', 'DUNNING-SAM'), 200);
        } catch (Exception e) {
            System.debug('Error in DunningSAMGeneratorSchedule : ' + e.getMessage());
        }
    }
}