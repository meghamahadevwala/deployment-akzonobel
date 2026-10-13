@isTest
private class CreditFieldsMigrationTempTest {

    @testSetup
    static void setupData() {
        List<Account> accounts = new List<Account>();

        for (Integer i = 0; i < 5; i++) {
            accounts.add(new Account(
                Name = 'Test Account ' + i,
                celsrm__Account_Key__c = 'Test Account ' + i,
                celsrm__App_Name__c = 'Credit'
            ));
        }

        insert accounts;
    }

    @isTest
    static void testCreditFieldsMigrationTempBatch() {

        Test.startTest();

        Database.executeBatch(
            new CreditFieldsMigrationTemp(),
            200
        );

        Test.stopTest();
    }
}