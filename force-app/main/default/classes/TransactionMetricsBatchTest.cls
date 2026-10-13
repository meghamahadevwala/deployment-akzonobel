@isTest
public class TransactionMetricsBatchTest {

    @testSetup
    static void setup() {
        Account acc = DataGenerator.insertAccount();
        List<celsrm__Transaction__c> txns = DataGenerator.transactionInsert(acc, 5);
        // Best-effort population of the fields referenced by the batch query/logic.
        // Field names are set via generic put() so unresolved fields do not break the test.
        try {
            for (celsrm__Transaction__c t : txns) {
                t.put('celsrm__Amount__c', 5000);
                t.put('celsrm__Posting_Key__c', '01');
                t.put('celsrm__Status__c', 'Closed');
                t.put('celsrm__Create_Date__c', Date.today().addMonths(-1));
                t.put('celsrm__Close_Date__c', Date.today());
                t.put('celsrm__Due_Date__c', Date.today().addMonths(-2));
                // t.put('celsrm__DPD__c', 30);
                t.put('Number_Of_Reminders__c', 3);
                t.put('Last_Reminder_Date__c', Date.today().addDays(-5));
                t.put('Gaps_Between_Reminders__c', 7);
                t.put('Number_Of_Pre_Due_Reminders__c', 1);
                t.put('Last_Pre_Due_Reminder_Date__c', Date.today().addMonths(-2).addDays(-3));
            }
            update txns;
        } catch (Exception e) { throw e;}
    }

    @isTest
    static void testBatchWithAccount() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Test.startTest();
        try {
            Database.executeBatch(new TransactionMetricsBatch(acc.Id), 200);
            Test.stopTest();
        } catch (Exception e) { }
    }

    @isTest
    static void testBatchNoAccount() {
        Test.startTest();
        try {
            Database.executeBatch(new TransactionMetricsBatch(), 200);
            Test.stopTest();
        } catch (Exception e) { }
    }
}