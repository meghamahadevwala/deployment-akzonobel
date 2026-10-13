@isTest
public class UpdateBlockInSourceSystemServiceTest {
    @testSetup
    static void setupData() {
        Account acc1 = new Account(
            Name = 'Test Account 1', 
            CurrencyIsoCode = 'EUR', 
            celsrm__Account_Key__c = '1111',
            AccountNumber = '1111',
            celsrm__Credit_Limit__c = 60000,
            celsrm__Credit_Control_Area__c = 'POPL',
            celsrm__Limit_Valid_To_Date__c = Date.today().addDays(30),
            celsrm__Order_Block__c = 'X'
        );


        Credit_Configuration__c creditConfig = new Credit_Configuration__c(
            Decimal_Adjustment_For_Write_Back__c = false,
            Update_Credit_Limit_Action_Flow_Webhook__c = 'AAAA'
        );

        insert creditConfig;


        insert new List<Account>{ acc1 };
    }

    @isTest
    static void updateBlock200() {
        Test.startTest();
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account 1' LIMIT 1];
        List<String> clAccountIds = new List<String>();
        clAccountIds.add(acc.Id);

        HttpResponse mockResponse = new HttpResponse(); 
        mockResponse.setBody('{"status":"Success", "details":{"updateResponse":[{"PARTNER":"1111","STATUS_MSG":"Update successful","CREDIT_LIMIT":60000,"CREDIT_SGMNT":"POPL","LIMIT_VALID_DATE":"2026-01-17"}]}}');
        mockResponse.setStatusCode(200);
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(mockResponse));

        UpdateBlockInSourceSystemService.updateBlockInSAP(clAccountIds);
        Test.stopTest();
    }

    @isTest
    static void updateBlock401() {
        Test.startTest();
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account 1' LIMIT 1];
        List<String> clAccountIds = new List<String>();
        clAccountIds.add(acc.Id);

        HttpResponse mockResponse = new HttpResponse(); 
        mockResponse.setBody('{"status":"Error", "details":"Failed to update"}');
        mockResponse.setStatusCode(401);
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(mockResponse));

        UpdateBlockInSourceSystemService.updateBlockInSAP(clAccountIds);
        Test.stopTest();
    }

    @isTest
    static void updateBlock500() {
        Test.startTest();
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account 1' LIMIT 1];
        List<String> clAccountIds = new List<String>();
        clAccountIds.add(acc.Id);

        HttpResponse mockResponse = new HttpResponse(); 
        mockResponse.setBody('{}');
        mockResponse.setStatusCode(500);
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(mockResponse));

        UpdateBlockInSourceSystemService.updateBlockInSAP(clAccountIds);
        Test.stopTest();
    }

    @isTest
    static void updateBlock429() {
        Test.startTest();
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account 1' LIMIT 1];
        List<String> clAccountIds = new List<String>();
        clAccountIds.add(acc.Id);

        HttpResponse mockResponse = new HttpResponse(); 
        mockResponse.setBody('{}');
        mockResponse.setStatusCode(429);
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(mockResponse));

        UpdateBlockInSourceSystemService.updateBlockInSAP(clAccountIds);
        Test.stopTest();
    }

    @isTest
    static void updateBlockOther() {
        Test.startTest();
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account 1' LIMIT 1];
        List<String> clAccountIds = new List<String>();
        clAccountIds.add(acc.Id);

        HttpResponse mockResponse = new HttpResponse(); 
        mockResponse.setBody('{}');
        mockResponse.setStatusCode(300);
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(mockResponse));

        UpdateBlockInSourceSystemService.updateBlockInSAP(clAccountIds);
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