@isTest
public class GoogleAuthTokenGeneratorTest {
    
    private class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            // Create a mock HTTP response
            HTTPResponse res = new HTTPResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"access_token": "mockAccessToken", "token_type": "Bearer", "expires_in": "3600"}');
            res.setStatusCode(200);
            return res;
        }
    }
    
    @isTest
    public static void testGenerateAuthToken() {
        // Set up mock callout response
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        // Call the method to test
        GoogleAuthTokenGenerator generator = new GoogleAuthTokenGenerator();
        GoogleAuthTokenGenerator.Token token = generator.generateAuthToken();
        
        // Verify the response
        System.assertEquals('mockAccessToken', token.access_token, 'Access token should match');
        System.assertEquals('Bearer', token.token_type, 'Token type should be Bearer');
        System.assertEquals('3600', token.expires_in, 'Expiration should be 3600 seconds');
    }
}