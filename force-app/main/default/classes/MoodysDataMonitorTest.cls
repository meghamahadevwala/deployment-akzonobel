@isTest
public class MoodysDataMonitorTest {
    @testSetup
    static void setupData() {
        Credit_Configuration__c config = new Credit_Configuration__c(
            Moody_s_Record_Set_Name__c = 'TestRecordSet'
        );
        insert config;

        Moody_s_Auth__c moodysAuth = new Moody_s_Auth__c(
            Access_Token__c = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c',
            Token_Generation_Time__c = System.now()
        );
        insert moodysAuth;
        
        Account acc1 = new Account(Name = 'Test Account 1', celsrm__Account_Key__c = '1111', AccountNumber = '1111', BvD_ID_Number__c = 'BVD123');
        Account acc2 = new Account(Name = 'Test Account 2', celsrm__Account_Key__c = '2222', AccountNumber = '2222', BvD_ID_Number__c = 'BVD124');
        insert new List<Account>{acc1, acc2};
    }

    @isTest
    static void monitorRecordSetTest() {
        Test.startTest();

        HttpResponse mockResponse = new HttpResponse();
        mockResponse.setBody('{"SearchSummary": {"TotalRecordsFound": 2, "RecordsReturned": 2}, "Data": [{"BVDID": "BVD123"}, {"BVDID": "BVD124"}]}');
        mockResponse.setStatusCode(200);
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(mockResponse));

        AsyncOptions asyncOptions = new AsyncOptions();
        asyncOptions.MaximumQueueableStackDepth = 100;
        System.enqueueJob(new MoodysDataMonitor(0), asyncOptions);
        Test.stopTest();
    }

    public class MockHttpResponseGenerator implements HttpCalloutMock {
        private HttpResponse mockResponse;
        
        public MockHttpResponseGenerator(HttpResponse mockResponse) {
            this.mockResponse = mockResponse;
        }

        public HttpResponse respond(HttpRequest req) {
            return mockResponse;
        }
    }
}