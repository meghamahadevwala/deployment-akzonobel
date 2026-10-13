global class UpdateSegmentDataForErroredCLRScheduler implements Schedulable {
    global void execute(SchedulableContext sc) {
        UpdateSegmentDataForErroredCLR batch = new UpdateSegmentDataForErroredCLR();
        Database.executeBatch(batch, 50);
    }
}