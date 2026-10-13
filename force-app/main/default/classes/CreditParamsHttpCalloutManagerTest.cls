@isTest
public class CreditParamsHttpCalloutManagerTest {
	@isTest
    static void MoodysTokenGenerator() {
        Test.startTest();
        
        HttpResponse mockResponse = new HttpResponse(); 
        mockResponse.setBody('{"access_token":"eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c","expires_in":3600,"token_type": "Bearer"}');
        mockResponse.setStatusCode(200);
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(mockResponse));
        Moody_s_Auth__c ma = creditParamsHttpCalloutManager.getMoodysAccessToken();
        Test.stopTest();
    }
    
    // Inner class to generate mock HTTP responses
    private class MockHttpResponseGenerator implements HttpCalloutMock {
        HttpResponse response;

        public MockHttpResponseGenerator(HttpResponse response) {
            this.response = response;
        }

        public HttpResponse respond(HttpRequest req) {
            return response;
        }
    }
}