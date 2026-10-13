@isTest
public class MoodysRecordSetManagerTest {
    @testSetup
    static void setupData() {
        Moody_s_Auth__c auth = new Moody_s_Auth__c(
            Access_Token__c = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c',
            Token_Generation_Time__c = System.now()
        );

        insert new List<Moody_s_Auth__c>{ auth };

        Credit_Configuration__c creditConfig = new Credit_Configuration__c(
            Moody_s_Record_Set_Name__c = 'AAAA'
        );

        insert creditConfig;
    }


    @isTest
    static void addInRecordSetTest() {
        Test.startTest();
        List<String> bvdIds = new List<String>();
        bvdIds.add('12345');

        HttpResponse mockResponse = new HttpResponse(); 
        mockResponse.setBody('{}');
        mockResponse.setStatusCode(200);
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(mockResponse));

        MoodysRecordSetManager.enqueue(bvdIds);
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