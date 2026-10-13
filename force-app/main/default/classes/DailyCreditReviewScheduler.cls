global class DailyCreditReviewScheduler implements Schedulable {
    global void execute(SchedulableContext sc) {
        // Schedule the DailyClrGeneratorWithLt20kLimitBatch
        DailyClrGeneratorWithLt20kLimitBatch batch1 = new DailyClrGeneratorWithLt20kLimitBatch();
        Database.executeBatch(batch1, 20);
        
        
        //Schedule the DailyClrGeneratorWithGt20kLimitBatch
        // DailyClrGeneratorWithGt20kLimitBatch batch3 = new DailyClrGeneratorWithGt20kLimitBatch();
        // Database.executeBatch(batch3, 20);

        //Schedule the DailyClrGeneratorForManualBatch
        // DailyClrGeneratorForManualBatch batch4 = new DailyClrGeneratorForManualBatch();
        // Database.executeBatch(batch4, 20);
    }
}