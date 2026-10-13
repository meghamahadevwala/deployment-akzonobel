global with sharing class MoodysCreditLimitScheduler implements Schedulable{
    global void execute(SchedulableContext sc) {
        // Schedule the UpdateMoodysCreditLimitBatchClass
        UpdateMoodysCreditLimitBatchClass batch1 = new UpdateMoodysCreditLimitBatchClass();
        Database.executeBatch(batch1, 50);
    }
}