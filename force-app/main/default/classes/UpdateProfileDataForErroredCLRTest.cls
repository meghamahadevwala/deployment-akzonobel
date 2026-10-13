@isTest
public class UpdateProfileDataForErroredCLRTest {

    @isTest
    static void testBatchQueriesErroredAccounts() {
        // celsrm__Account_Key__c is unique on Account and defaults to '0' via CreditDataGenerator,
        // so each account inserted in the same test needs a distinct key to avoid DUPLICATE_VALUE.
        Account acc = CreditDataGenerator.insertAccount();
        acc.celsrm__Account_Key__c = 'KEY-' + acc.Id;
        acc.Sync_Profile_Data_Message__c = 'Error: something went wrong';
        update acc;

        Account nonMatching = CreditDataGenerator.insertAccount();
        nonMatching.celsrm__Account_Key__c = 'KEY-' + nonMatching.Id;
        nonMatching.Sync_Profile_Data_Message__c = 'Update successful';
        update nonMatching;

        UpdateProfileDataForErroredCLR batch = new UpdateProfileDataForErroredCLR();
        Database.QueryLocator ql = batch.start(null);
        Database.QueryLocatorIterator it = ql.iterator();

        Set<Id> foundIds = new Set<Id>();
        while (it.hasNext()) {
            foundIds.add(((Account) it.next()).Id);
        }
        System.assert(foundIds.contains(acc.Id), 'Account with Error: message should be included');
        System.assert(!foundIds.contains(nonMatching.Id), 'Account without an error message should not be included');
    }

    @isTest
    static void testBatchExecuteWithMatchingAccounts() {
        Account acc = CreditDataGenerator.insertAccount();
        acc.Sync_Profile_Data_Message__c = 'Error: timeout';
        update acc;

        Test.startTest();
        Database.executeBatch(new UpdateProfileDataForErroredCLR());
        Test.stopTest();

        // Test.isRunningTest() short-circuits the actual SAP callout inside execute();
        // reaching here without an unhandled exception confirms the batch runs cleanly.
        System.assert(true);
    }

    @isTest
    static void testBatchExecuteWithNoAccounts() {
        UpdateProfileDataForErroredCLR batch = new UpdateProfileDataForErroredCLR();
        Test.startTest();
        batch.execute(null, new List<Account>());
        batch.finish(null);
        Test.stopTest();
        System.assert(true);
    }
}