global with sharing class DunningNORTHASIAGeneratorSchedule implements Schedulable {
    global void execute(SchedulableContext ctx) {
        try {
            Database.executeBatch(new DunningProcessingBatch('North Asia', 'DUNNING-NORTH ASIA'), 200);
        } catch (Exception e) {
            System.debug('Error in DunningNORTHASIAGeneratorSchedule  : ' + e.getMessage());
        }
    }
}