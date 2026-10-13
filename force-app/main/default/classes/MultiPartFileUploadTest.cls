@isTest
public class MultiPartFileUploadTest {

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
    public static void testUploadFile() {
        // Set up test data
        Blob fileBody = Blob.valueOf('Mock file content');
        String fileName = 'mockfile.txt';
        String reqEndPoint = 'https://mockendpoint.com';
        String authToken = 'mockAuthToken';

        // Set up mock callout response
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        // Call the method to test
        HttpRestCallout.HttpCalloutResponse response = MultiPartFileUpload.uploadFile(
            fileBody,
            fileName,
            reqEndPoint,
            authToken
        );

        // Verify the response
        System.assertEquals(200, response.statusCode, 'Status code should be 200');
        System.assertEquals('{"key": "value"}', response.response, 'Response body should match');
    }
}