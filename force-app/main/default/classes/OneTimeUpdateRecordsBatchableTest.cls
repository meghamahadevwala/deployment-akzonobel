@isTest
private class OneTimeUpdateRecordsBatchableTest {
    
    @isTest static void testBatchExecution() {
        // Create test data
        
        Account acc = DataGenerator.insertAccount();
        
        //celsrm__Transaction__c trans = DataGenerator.insertTransaction(acc);
        
        List<celsrm__Transaction__c> transactions = new List<celsrm__Transaction__c>();

        
        for (Integer i = 0; i < 5; i++) {
            transactions.add(new celsrm__Transaction__c(
                celsrm__Transaction_Key__c = 'CFIN_CustomerAccountCreditItem_00' + i,
                celsrm__Debit_Credit_Indicator__c = 'S',
                celsrm__Create_Date__c = Date.today(),
                celsrm__Close_Date__c = Date.today(),
                celsrm__Amount__c = 0.01,
                celsrm__Balance__c = 0.01,
                celsrm__Account__c = acc.id
            ));
        }

        insert transactions;

        Test.startTest();
        OneTimeUpdateRecordsBatchable batch = new OneTimeUpdateRecordsBatchable();
        Database.executeBatch(batch, 5); // You can adjust batch size
        Test.stopTest();

        // Verify update happened
        for (celsrm__Transaction__c t : [
            SELECT celsrm__Transaction_Key__c FROM celsrm__Transaction__c
        ]) {
            System.assertEquals(true, t.celsrm__Transaction_Key__c.contains('CustomerAccountDebitItem_'));
        }
    }
}