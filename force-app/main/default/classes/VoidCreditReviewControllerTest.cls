@isTest
public class VoidCreditReviewControllerTest {
    @testSetup
    static void setupData() {
        Credit_Configuration__c creditConfig = new Credit_Configuration__c(
            Decimal_Adjustment_For_Write_Back__c = true,
            Update_Credit_Limit_Action_Flow_Webhook__c = 'AAAA'
        );

        insert creditConfig;


        //Void Without App App Communication
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
            celsrm__Account__c = acc1.Id,
            celsrm__Status__c = '10',
            Requested_Valid_To_Date__c = Date.today().addDays(30)
        );

        insert cr1;



        //Void With App App Communication
        Account acc2 = new Account(
            Name = 'Test Account 2', 
            celsrm__Account_Key__c = '2222',
            AccountNumber = '2222',
            CurrencyIsoCode = 'EUR',
            celsrm__Order_Block__c = 'X',
            celsrm__Credit_Control_Area__c = 'POPL'
        );

        insert acc2;

        celsrm__Credit_Review__c cr2 = new celsrm__Credit_Review__c(
            CurrencyIsoCode = 'EUR', 
            celsrm__Account__c = acc2.Id,
            celsrm__Status__c = '20',
            Requested_Valid_To_Date__c = Date.today().addDays(30)
        );

        insert cr2;
    }

    @isTest
    static void voideWithoutAppApp() {
        Test.startTest();
        celsrm__Credit_Review__c cr = [SELECT Id FROM celsrm__Credit_Review__c WHERE celsrm__Status__c ='10' LIMIT 1];
        Map<Object, Object> inMap = new Map<Object, Object>();
        inMap.put('Id', cr.Id);

        // HttpResponse mockResponse = new HttpResponse(); 
        // mockResponse.setBody('{"status":"Success", "details":{"updateResponse":[{"PARTNER":"1111","STATUS_MSG":"Update successful","CREDIT_LIMIT":60000,"CREDIT_SGMNT":"POPL","LIMIT_VALID_DATE":"2026-01-17"}]}}');
        // mockResponse.setStatusCode(200);
        // Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(mockResponse));

        VoidCreditReviewController controller = new VoidCreditReviewController();
        controller.invoke('onLoadVoidCreditReview', inMap);

        inMap.put('VoidReason', 'Entry error');
        controller.invoke('onSubmitVoidCreditReview', inMap);
        Test.stopTest();
    }

    @isTest
    static void voideWithAppApp201() {
        Test.startTest();
        celsrm__Credit_Review__c cr = [SELECT Id FROM celsrm__Credit_Review__c WHERE celsrm__Status__c ='20' LIMIT 1];
        Map<Object, Object> inMap = new Map<Object, Object>();
        inMap.put('Id', cr.Id);

        HttpResponse mockResponse = new HttpResponse(); 
        mockResponse.setBody('{}');
        mockResponse.setStatusCode(201);
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(mockResponse));

        VoidCreditReviewController controller = new VoidCreditReviewController();
        controller.invoke('onLoadVoidCreditReview', inMap);

        inMap.put('VoidReason', 'Entry error');
        controller.invoke('onSubmitVoidCreditReview', inMap);
        Test.stopTest();
    }

    @isTest
    static void voideWithAppApp422() {
        Test.startTest();
        celsrm__Credit_Review__c cr = [SELECT Id FROM celsrm__Credit_Review__c WHERE celsrm__Status__c ='20' LIMIT 1];
        Map<Object, Object> inMap = new Map<Object, Object>();
        inMap.put('Id', cr.Id);

        HttpResponse mockResponse = new HttpResponse(); 
        mockResponse.setBody('[{"msg":"XYZ"}]');
        mockResponse.setStatusCode(422);
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(mockResponse));

        VoidCreditReviewController controller = new VoidCreditReviewController();
        controller.invoke('onLoadVoidCreditReview', inMap);

        inMap.put('VoidReason', 'Entry error');
        controller.invoke('onSubmitVoidCreditReview', inMap);
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