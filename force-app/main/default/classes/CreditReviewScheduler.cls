global class CreditReviewScheduler implements Schedulable {
    global void execute(SchedulableContext sc) {

        // Schedule the CreditReviewGeneratorWithZeroLimitBatch
        CreditReviewGeneratorWithZeroLimitBatch batch2 = new CreditReviewGeneratorWithZeroLimitBatch();
        Database.executeBatch(batch2, 20);

        // // Schedule the CreditReviewGeneratorWithLt20kLimitBatch
        // CreditReviewGeneratorWithLt20kLimitBatch batch1 = new CreditReviewGeneratorWithLt20kLimitBatch();
        // Database.executeBatch(batch1, 50);
        
        
        // //Schedule the CreditReviewGeneratorWithGt20kLimitBatch
        // CreditReviewGeneratorWithGt20kLimitBatch batch3 = new CreditReviewGeneratorWithGt20kLimitBatch();
        // Database.executeBatch(batch3, 50);

        // CreditReviewGeneratorForManualBatch batch4 = new CreditReviewGeneratorForManualBatch();
        // Database.executeBatch(batch4, 50);
    }
}