@isTest
global class MockCallOutGenerator implements HttpCalloutMock {

    public String responseString {get;set;}
    public Integer responseCode {get;set;}
    
    public MockCallOutGenerator (String response,Integer code )
    {
        this.responseString = response;
        this.responseCode = code;
    }
    
    // Implement this interface method
    global HTTPResponse respond(HTTPRequest request) {
        // Create a fake response
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');
        response.setBody(responseString);
        response.setStatusCode(responseCode);
        return response;
    }
}