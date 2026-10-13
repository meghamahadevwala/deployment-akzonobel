@isTest
public class UpdateLimitInSourceSystemServiceTest {
    @testSetup
    static void setupData() {
        Account acc1 = new Account(
            Name = 'Test Account 1', 
            celsrm__Account_Key__c = '1111',
            AccountNumber = '1111',
            CurrencyIsoCode = 'EUR',
            celsrm__Order_Block__c = 'X',
            celsrm__Credit_Control_Area__c = 'POPL'
        );

        insert acc1;

        celsrm__Credit_Review__c cr1 = new celsrm__Credit_Review__c(
            CurrencyIsoCode = 'EUR', 
            celsrm__Approved_Credit_Limit__c = 60000,
            celsrm__Account__c = acc1.Id,
            celsrm__Status__c = '11',
            Requested_Valid_To_Date__c = Date.today().addDays(30),
            Approved_Valid_To_Date__c = Date.today().addDays(30)
        );

        insert cr1;

        Credit_Configuration__c creditConfig = new Credit_Configuration__c(
            Decimal_Adjustment_For_Write_Back__c = true,
            Update_Credit_Limit_Action_Flow_Webhook__c = 'AAAA'
        );

        insert creditConfig;
    }

    @isTest
    static void updateCreditLimit200() {
        Test.startTest();
        celsrm__Credit_Review__c cr = [SELECT Id FROM celsrm__Credit_Review__c LIMIT 1];
        List<String> clrList = new List<String>();
        clrList.add(cr.Id);

        HttpResponse mockResponse = new HttpResponse(); 
        mockResponse.setBody('{"status":"Success", "details":{"updateResponse":[{"PARTNER":"1111","STATUS_MSG":"Update successful","CREDIT_LIMIT":60000,"CREDIT_SGMNT":"POPL","LIMIT_VALID_DATE":"2026-01-17"}]}}');
        mockResponse.setStatusCode(200);
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(mockResponse));

        UpdateLimitInSourceSystemService.updateCreditLimitInSAP(clrList);
        Test.stopTest();
    }

    @isTest
    static void updateCreditLimit200Accepted() {
        Test.startTest();
        celsrm__Credit_Review__c cr = [SELECT Id FROM celsrm__Credit_Review__c LIMIT 1];
        List<String> clrList = new List<String>();
        clrList.add(cr.Id);

        HttpResponse mockResponse = new HttpResponse(); 
        mockResponse.setBody('Accepted');
        mockResponse.setStatusCode(200);
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(mockResponse));

        UpdateLimitInSourceSystemService.updateCreditLimitInSAP(clrList);
        Test.stopTest();
    }

    @isTest
    static void updateCreditLimit401() {
        Test.startTest();
        celsrm__Credit_Review__c cr = [SELECT Id FROM celsrm__Credit_Review__c LIMIT 1];
        List<String> clrList = new List<String>();
        clrList.add(cr.Id);

        HttpResponse mockResponse = new HttpResponse(); 
        mockResponse.setBody('{"status":"Error", "details":"Failed to update"}');
        mockResponse.setStatusCode(401);
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(mockResponse));

        UpdateLimitInSourceSystemService.updateCreditLimitInSAP(clrList);
        Test.stopTest();
    }

    @isTest
    static void updateCreditLimit500() {
        Test.startTest();
        celsrm__Credit_Review__c cr = [SELECT Id FROM celsrm__Credit_Review__c LIMIT 1];
        List<String> clrList = new List<String>();
        clrList.add(cr.Id);

        HttpResponse mockResponse = new HttpResponse(); 
        mockResponse.setBody('{}');
        mockResponse.setStatusCode(500);
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(mockResponse));

        UpdateLimitInSourceSystemService.updateCreditLimitInSAP(clrList);
        Test.stopTest();
    }

    @isTest
    static void updateCreditLimit429() {
        Test.startTest();
        celsrm__Credit_Review__c cr = [SELECT Id FROM celsrm__Credit_Review__c LIMIT 1];
        List<String> clrList = new List<String>();
        clrList.add(cr.Id);

        HttpResponse mockResponse = new HttpResponse(); 
        mockResponse.setBody('{}');
        mockResponse.setStatusCode(429);
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(mockResponse));

        UpdateLimitInSourceSystemService.updateCreditLimitInSAP(clrList);
        Test.stopTest();
    }

    @isTest
    static void updateCreditLimitOther() {
        Test.startTest();
        celsrm__Credit_Review__c cr = [SELECT Id FROM celsrm__Credit_Review__c LIMIT 1];
        List<String> clrList = new List<String>();
        clrList.add(cr.Id);

        HttpResponse mockResponse = new HttpResponse(); 
        mockResponse.setBody('{}');
        mockResponse.setStatusCode(300);
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(mockResponse));

        UpdateLimitInSourceSystemService.updateCreditLimitInSAP(clrList);
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