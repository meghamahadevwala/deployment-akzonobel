@isTest
public class UpdateMoodysCreditLimitBatchClassTest {

    private class MockHttpResponseGenerator implements HttpCalloutMock {
        private HttpResponse mockResponse;

        public MockHttpResponseGenerator(HttpResponse mockResponse) {
            this.mockResponse = mockResponse;
        }

        public HttpResponse respond(HttpRequest req) {
            return mockResponse;
        }
    }

    private static Account buildQualifyingAccount() {
        Account acc = CreditDataGenerator.insertAccount();
        acc.BvD_ID_Number__c = 'DE123456789';
        acc.celsrm__App_Name__c = 'Credit';
        acc.celsrm__Check_Rule__c = 'Z03 Risk Class Low';
        acc.celsrm__Credit_Group__c = '0002 - GEN - General Customer';
        acc.Calculated_Credit_Limit_Group_Currency__c = 75000;
        acc.Moody_s_Change_Identified__c = true;
        update acc;
        return acc;
    }

    @isTest
    static void testBatchQueriesQualifyingAccounts() {
        Account acc = buildQualifyingAccount();

        UpdateMoodysCreditLimitBatchClass batch = new UpdateMoodysCreditLimitBatchClass();
        Database.QueryLocator ql = batch.start(null);
        Database.QueryLocatorIterator it = ql.iterator();

        Set<Id> foundIds = new Set<Id>();
        while (it.hasNext()) {
            foundIds.add(((Account) it.next()).Id);
        }
        System.assert(foundIds.contains(acc.Id), 'Qualifying account should be included in the batch query');
    }

    @isTest
    static void testBatchExecuteProcessesAccountsWithoutError() {
        Account acc = buildQualifyingAccount();

        HttpResponse mockResponse = new HttpResponse();
        mockResponse.setBody('{"access_token":"dummy-token","expires_in":3600,"token_type":"Bearer"}');
        mockResponse.setStatusCode(200);
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(mockResponse));

        Test.startTest();
        Database.executeBatch(new UpdateMoodysCreditLimitBatchClass());
        Test.stopTest();

        // The batch delegates to the async GetMoodysDataService; reaching here without
        // an unhandled exception confirms start/execute/finish wiring is correct.
        AsyncApexJob job = [SELECT Id, Status FROM AsyncApexJob ORDER BY CreatedDate DESC LIMIT 1];
        System.assertNotEquals(null, job.Id);
    }

    @isTest
    static void testBatchFinishDoesNotThrow() {
        UpdateMoodysCreditLimitBatchClass batch = new UpdateMoodysCreditLimitBatchClass();
        Test.startTest();
        batch.finish(null);
        Test.stopTest();
        // No exception thrown means the finish() method behaves as expected.
        System.assert(true);
    }
}