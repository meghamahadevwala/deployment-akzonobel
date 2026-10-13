global class MockHttpResponseGenerator implements System.HttpCalloutMock {
    global String body;
    global MockHttpResponseGenerator() {

    }
    global MockHttpResponseGenerator(String body) {
        this.body = body;
    }
    global System.HttpResponse respond(System.HttpRequest req) {
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody(this.body);
        res.setStatusCode(200);
        return res;
    }
}