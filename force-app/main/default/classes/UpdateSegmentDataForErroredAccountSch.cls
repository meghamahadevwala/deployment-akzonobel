global class UpdateSegmentDataForErroredAccountSch implements Schedulable{
    global void execute(SchedulableContext sc) {
        UpdateSegmentDataForErroredAccount batch = new UpdateSegmentDataForErroredAccount();
        Database.executeBatch(batch, 50);
    }
}