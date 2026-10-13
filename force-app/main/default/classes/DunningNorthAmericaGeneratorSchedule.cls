global with sharing class DunningNorthAmericaGeneratorSchedule implements Schedulable {
    global void execute(SchedulableContext ctx) {
        try {
            Database.executeBatch(new DunningProcessingBatch('North America', 'DUNNING-NORTH AMERICA'), 200);
        } catch (Exception e) {
            System.debug('Error in DunningNorthAmericaGeneratorSchedule : ' + e.getMessage());
        }
    }
}