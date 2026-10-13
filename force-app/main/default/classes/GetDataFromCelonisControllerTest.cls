@isTest
public class GetDataFromCelonisControllerTest {
    public class MockHttpResponseGenerator implements HttpCalloutMock {
        private HttpResponse mockResponse;
        
        public MockHttpResponseGenerator(HttpResponse mockResponse) {
            this.mockResponse = mockResponse;
        }

        public HttpResponse respond(HttpRequest req) {
            return mockResponse;
        }
    }
    public static testMethod Void  fetchSalesOrderData() {
        Account acc = DataGenerator.insertAccount();
        celsrm__Transaction__c trans = DataGenerator.insertTransaction(acc);
        Map<Object, Object> inMap = new Map<Object, Object>();
        // inMap.put('Id', trans.Id);
        inMap.put('page', 2);
        inMap.put('pageSize', 10);

        // Start Test
        Test.startTest();

        String mockBody = '{' +
            '"total": 2,' +
            '"content": {' +
                '"data": [' +
                    '{' +
                        '"CREDITSEGMENTCURRENCY": "EUR",' +
                        '"SOURCESYSTEMINSTANCE": "SAP_DE",' +
                        '"CREDITCONTROLAREA": "DE01",' +
                        '"PERIODSTOANALYZECURRENTDATE": "2025-07",' +
                        '"OPENSALESORDERVALUEINCREDITSEGMENTCURRENCY": "15000.758"' +
                    '},' +
                    '{' +
                        '"CREDITSEGMENTCURRENCY": "USD",' +
                        '"SOURCESYSTEMINSTANCE": "SAP_US",' +
                        '"CREDITCONTROLAREA": "US01",' +
                        '"PERIODSTOANALYZECURRENTDATE": "2025-07",' +
                        '"OPENSALESORDERVALUEINCREDITSEGMENTCURRENCY": "23500.1"' +
                    '}' +
                ']' +
            '}' +
        '}';
        HttpResponse mockResponse = new HttpResponse();
        mockResponse.setBody(mockBody);
        mockResponse.setStatusCode(200);
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(mockResponse));

        // Call the method to test
        GetDataFromCelonisController getDataFromCelonis = new GetDataFromCelonisController();
        // Map<Object, Object> resultMap = getDataFromCelonis.invoke('BILLING_DATA', inMap);
        inMap.put('Id', acc.Id);  
        Map<Object, Object> resultMap1 = getDataFromCelonis.invoke('getSalesOrderData', inMap);
        
        // resultMap1 = getDataFromCelonis.invoke('getDeliveryOrderData', inMap);
        // resultMap1 = getDataFromCelonis.invoke('getSalesOrdersBillingData', inMap);
        // resultMap1 = getDataFromCelonis.invoke('getSoftCreditExposures', inMap);
        // resultMap1 = getDataFromCelonis.invoke('getCreditLimitChanges', inMap);
        // End Test
        Test.stopTest();
    }

    public static testMethod Void  fetchBillingData() {
        Account acc = DataGenerator.insertAccount();
        celsrm__Transaction__c trans = DataGenerator.insertTransaction(acc);
        Map<Object, Object> inMap = new Map<Object, Object>();
        inMap.put('Id', trans.Id);
        inMap.put('page', 2);
        inMap.put('pageSize', 10);

        // Start Test
        Test.startTest();

        String mockBody = '{' +
            '"total": 2,' +
            '"content": {' +
                '"data": [' +
                    '{' +
                        '"BILLING_ITEM_ID": "01",' +
                        '"BILLING_DOC": "RV",' +
                        '"BILLING_POS": "12311",' +
                        '"BILLING_NET_VALUE": "1628.23",' +
                        '"BILLING_INVOICED_QUANTITY": "2"' +
                    '},' +
                    '{' +
                        '"BILLING_ITEM_ID": "02",' +
                        '"BILLING_DOC": "YH",' +
                        '"BILLING_POS": "123111",' +
                        '"BILLING_NET_VALUE": "1628.44",' +
                        '"BILLING_INVOICED_QUANTITY": "3"' +
                    '}' +
                ']' +
            '}' +
        '}';
        HttpResponse mockResponse = new HttpResponse();
        mockResponse.setBody(mockBody);
        mockResponse.setStatusCode(200);
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(mockResponse));

        GetDataFromCelonisController getDataFromCelonis = new GetDataFromCelonisController();
        Map<Object, Object> resultMap = getDataFromCelonis.invoke('BILLING_DATA', inMap);

        Test.stopTest();
    }

    public static testMethod Void  fetchDeliveryData() {
        Account acc = DataGenerator.insertAccount();
        celsrm__Transaction__c trans = DataGenerator.insertTransaction(acc);
        Map<Object, Object> inMap = new Map<Object, Object>();
        inMap.put('Id', acc.Id);
        inMap.put('page', 2);
        inMap.put('pageSize', 10);

        // Start Test
        Test.startTest();

        String mockBody = '{' +
            '"total": 2,' +
            '"content": {' +
                '"data": [' +
                    '{' +
                        '"CREDITSEGMENTCURRENCY": "EUR",' +
                        '"SOURCESYSTEMINSTANCE": "103",' +
                        '"CREDITCONTROLAREA": "SDW",' +
                        '"PERIODSTOANALYZECURRENTDATE": "2024-09-10",' +
                        '"OPENDELIVERYCREDITINCREDITSEGMENTCURRENCY": "2"' +
                    '},' +
                    '{' +
                        '"CREDITSEGMENTCURRENCY": "EUR",' +
                        '"SOURCESYSTEMINSTANCE": "103",' +
                        '"CREDITCONTROLAREA": "SDW",' +
                        '"PERIODSTOANALYZECURRENTDATE": "2024-09-10",' +
                        '"OPENDELIVERYCREDITINCREDITSEGMENTCURRENCY": "3"' +
                    '}' +
                ']' +
            '}' +
        '}';
        HttpResponse mockResponse = new HttpResponse();
        mockResponse.setBody(mockBody);
        mockResponse.setStatusCode(200);
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(mockResponse));

        GetDataFromCelonisController getDataFromCelonis = new GetDataFromCelonisController();
        Map<Object, Object> resultMap = getDataFromCelonis.invoke('getDeliveryOrderData', inMap);

        Test.stopTest();
    }

    public static testMethod Void  fetchSalesOrderBillingData() {
        Account acc = DataGenerator.insertAccount();
        celsrm__Transaction__c trans = DataGenerator.insertTransaction(acc);
        Map<Object, Object> inMap = new Map<Object, Object>();
        inMap.put('Id', acc.Id);
        inMap.put('page', 2);
        inMap.put('pageSize', 10);

        // Start Test
        Test.startTest();

        String mockBody = '{' +
            '"total": 2,' +
            '"content": {' +
                '"data": [' +
                    '{' +
                        '"CurrencyIsoCode": "EUR",' +
                        '"CUSTOMER_CLIENT": "103",' +
                        '"CREDIT_CONTROL_AREA": "SDW",' +
                        '"PERIOD_TO_ANALYZE_CURRENT_DATE": "2024-09-10",' +
                        '"OPEN_BILLING_CREDIT": "27319"' +
                    '},' +
                    '{' +
                        '"CurrencyIsoCode": "EUR",' +
                        '"CUSTOMER_CLIENT": "103",' +
                        '"CREDIT_CONTROL_AREA": "SDW",' +
                        '"PERIOD_TO_ANALYZE_CURRENT_DATE": "2024-09-10",' +
                        '"OPEN_BILLING_CREDIT": "3221"' +
                    '}' +
                ']' +
            '}' +
        '}';
        HttpResponse mockResponse = new HttpResponse();
        mockResponse.setBody(mockBody);
        mockResponse.setStatusCode(200);
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(mockResponse));

        GetDataFromCelonisController getDataFromCelonis = new GetDataFromCelonisController();
        Map<Object, Object> resultMap = getDataFromCelonis.invoke('getSalesOrdersBillingData', inMap);

        Test.stopTest();
    }

    public static testMethod Void  fetchExposureData() {
        Account acc = DataGenerator.insertAccount();
        celsrm__Transaction__c trans = DataGenerator.insertTransaction(acc);
        Map<Object, Object> inMap = new Map<Object, Object>();
        inMap.put('Id', acc.Id);
        inMap.put('page', 2);
        inMap.put('pageSize', 10);

        // Start Test
        Test.startTest();

        String mockBody = '{' +
            '"total": 2,' +
            '"content": {' +
                '"data": [' +
                    '{' +
                        '"CurrencyIsoCode": "EUR",' +
                        '"DUERECEIVABLESVALUELOCAL": "2424",' +
                        '"SALESORDERVALUELOCAL": "24124",' +
                        '"PERIODSTOANALYZECURRENTDATE": "2024-09-10",' +
                        '"RUNNINGDELTALOCAL": "27319"' +
                    '},' +
                    '{' +
                        '"CurrencyIsoCode": "EUR",' +
                        '"DUERECEIVABLESVALUELOCAL": "2424",' +
                        '"SALESORDERVALUELOCAL": "24124",' +
                        '"PERIODSTOANALYZECURRENTDATE": "2024-09-10",' +
                        '"RUNNINGDELTALOCAL": "27319"' +
                    '}' +
                ']' +
            '}' +
        '}';
        HttpResponse mockResponse = new HttpResponse();
        mockResponse.setBody(mockBody);
        mockResponse.setStatusCode(200);
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(mockResponse));

        GetDataFromCelonisController getDataFromCelonis = new GetDataFromCelonisController();
        Map<Object, Object> resultMap = getDataFromCelonis.invoke('getSoftCreditExposures', inMap);

        Test.stopTest();
    }

    public static testMethod Void  fetchLimitChangesData() {
        Account acc = DataGenerator.insertAccount();
        celsrm__Transaction__c trans = DataGenerator.insertTransaction(acc);
        Map<Object, Object> inMap = new Map<Object, Object>();
        inMap.put('Id', acc.Id);
        inMap.put('page', 2);
        inMap.put('pageSize', 10);

        // Start Test
        Test.startTest();

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
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(mockResponse));

        GetDataFromCelonisController getDataFromCelonis = new GetDataFromCelonisController();
        Map<Object, Object> resultMap = getDataFromCelonis.invoke('getCreditLimitChanges', inMap);

        Test.stopTest();
    }
}