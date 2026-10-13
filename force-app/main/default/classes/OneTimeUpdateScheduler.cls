global class OneTimeUpdateScheduler implements Schedulable {
    global void execute(SchedulableContext sc) {
        OneTimeUpdateRecordsBatchable batch = new OneTimeUpdateRecordsBatchable();
        Database.executeBatch(batch, 2000); // Batch size can be adjusted
    }
}