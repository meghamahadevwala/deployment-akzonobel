@isTest
public class CreditLimitHistoryControllerTest {

    public class MockHttpResponseGenerator implements HttpCalloutMock {
        private HttpResponse mockResponse;

        public MockHttpResponseGenerator(HttpResponse mockResponse) {
            this.mockResponse = mockResponse;
        }

        public HttpResponse respond(HttpRequest req) {
            return mockResponse;
        }
    }

    @isTest
    static void testGetChartDetailsWithData() {
        Account acc = CreditDataGenerator.insertAccount();

        String mockBody = '{' +
            '"total": 2,' +
            '"content": {' +
                '"data": [' +
                    '{' +
                        '"CurrencyIsoCode": "EUR",' +
                        '"CHANGETIME": "2024-09-10",' +
                        '"OLDVALUE": "1000",' +
                        '"NEWVALUE": "2000",' +
                        '"USERNAME": "BYIWW"' +
                    '},' +
                    '{' +
                        '"CurrencyIsoCode": "EUR",' +
                        '"CHANGETIME": "2024-08-08",' +
                        '"OLDVALUE": "500",' +
                        '"NEWVALUE": "1000",' +
                        '"USERNAME": "BYIWW"' +
                    '}' +
                ']' +
            '}' +
        '}';
        HttpResponse mockResponse = new HttpResponse();
        mockResponse.setBody(mockBody);
        mockResponse.setStatusCode(200);

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(mockResponse));
        List<Map<String, Object>> result = CreditLimitChangeHistoryChartController.getChartDetails(acc.Id);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result list should not be null');
        System.assertEquals(2, result.size(), 'Both change history records should be returned');
        System.assertEquals('BYIWW', result[0].get('USERNAME'));
    }

    @isTest
    static void testGetChartDetailsNoData() {
        Account acc = CreditDataGenerator.insertAccount();

        HttpResponse mockResponse = new HttpResponse();
        mockResponse.setBody('{"statusCode": 403}');
        mockResponse.setStatusCode(200);

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(mockResponse));
        List<Map<String, Object>> result = CreditLimitChangeHistoryChartController.getChartDetails(acc.Id);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result list should default to an empty list, not null');
        System.assertEquals(0, result.size(), 'No change history records should be returned');
    }
}