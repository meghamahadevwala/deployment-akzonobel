@isTest
public class HttpRestCalloutTest {

    private class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            // Create a mock HTTP response
            HTTPResponse res = new HTTPResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"key": "value"}');
            res.setStatusCode(200);
            return res;
        }
    }

    @isTest
    public static void testMakeAcallout() {
        // Set up mock callout response
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        // Call the method to test
        HttpRestCallout.HttpCalloutResponse response = HttpRestCallout.makeAcallout(
            'https://mockurl.com', // replace with your mock endpoint
            'GET', // specify method type
            null, // no body for GET request
            new Map<String, String>{'Authorization' => 'Bearer mockToken'}, // add any required headers
            false // indicate whether the response should be treated as Blob data
        );

        // Verify the response
        System.assertEquals(200, response.statusCode, 'Status code should be 200');
        System.assertEquals('{"key": "value"}', response.response, 'Response body should match');
    }
}