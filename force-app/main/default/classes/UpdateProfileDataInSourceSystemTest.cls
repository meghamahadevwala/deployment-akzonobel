@isTest
public class UpdateProfileDataInSourceSystemTest {
    @testSetup
    static void setupData() {
        Account acc1 = new Account(
            // << CHANGE - MM - FIN-9701 - Test Class Coverage | Added celsrm__App_Name__c value >>
            celsrm__App_Name__c = 'Credit',
            Name = 'Test Account 1', 
            CurrencyIsoCode = 'EUR', 
            celsrm__Account_Key__c = '1111-POPL',
            AccountNumber = '1111',
            celsrm__Credit_Control_Area__c = 'POPL',
            celsrm__Check_Rule__c = 'Z05 Risk Class High',
            celsrm__Credit_Group__c = '0003 - RCA - Regular Credit Account',
            celsrm__Risk_Class__c = '3 - Low Risk'
        );


        Credit_Configuration__c creditConfig = new Credit_Configuration__c(
            Update_Profile_Data_Action_Flow_Webhook__c = 'AAAA'
        );

        insert creditConfig;
        insert new List<Account>{ acc1 };
    }

    @isTest
    static void updateProfileData200() {
        Test.startTest();
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account 1' LIMIT 1];
        List<String> accountIds = new List<String>();
        accountIds.add(acc.Id);

        HttpResponse mockResponse = new HttpResponse(); 
        // << START - MM - FIN-9701 - Test Class Coverage for Credit App >>
        // mockResponse.setBody('{"status":"Success", "details":{"updateResponse":[{"PARTNER":"1111","STATUS_MSG":"Update successful"}]}}');
        mockResponse.setBody('{"status":"Success", "details":{"updateResponse":[{"PARTNER":"1111","CHECK_RULE":"Z05","CREDIT_GROUP":"0003","RISK_CLASS":"3","STATUS_MSG":"Update successful"}]}}');
        // << END - MM - FIN-9701 - Test Class Coverage for Credit App >>
        mockResponse.setStatusCode(200);
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(mockResponse));

        UpdateProfileDataInSourceSystemService.updateProfileDataInSAP(accountIds);
        Test.stopTest();
    }

    // << START - MM - FIN-9701 - Test Class Coverage for Credit App >>
    @isTest
    static void updateProfileData200Missing() {
        Test.startTest();
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account 1' LIMIT 1];
        List<String> accountIds = new List<String>();
        accountIds.add(acc.Id);

        HttpResponse mockResponse = new HttpResponse(); 
        mockResponse.setBody('{"status":"Success", "details":{"updateResponse":[]}}');
        mockResponse.setStatusCode(200);
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(mockResponse));

        UpdateProfileDataInSourceSystemService.updateProfileDataInSAP(accountIds);
        Test.stopTest();
    }
    // << END - MM - FIN-9701 - Test Class Coverage for Credit App >>

    @isTest
    static void updateProfileData401() {
        Test.startTest();
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account 1' LIMIT 1];
        List<String> accountIds = new List<String>();
        accountIds.add(acc.Id);

        HttpResponse mockResponse = new HttpResponse(); 
        mockResponse.setBody('{"status":"Error", "details":"Failed to update"}');
        mockResponse.setStatusCode(401);
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(mockResponse));

        UpdateProfileDataInSourceSystemService.updateProfileDataInSAP(accountIds);
        Test.stopTest();
    }

    @isTest
    static void updateProfileData500() {
        Test.startTest();
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account 1' LIMIT 1];
        List<String> accountIds = new List<String>();
        accountIds.add(acc.Id);

        HttpResponse mockResponse = new HttpResponse(); 
        mockResponse.setBody('{}');
        mockResponse.setStatusCode(500);
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(mockResponse));

        UpdateProfileDataInSourceSystemService.updateProfileDataInSAP(accountIds);
        Test.stopTest();
    }

    @isTest
    static void updateProfileData429() {
        Test.startTest();
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account 1' LIMIT 1];
        List<String> accountIds = new List<String>();
        accountIds.add(acc.Id);

        HttpResponse mockResponse = new HttpResponse(); 
        mockResponse.setBody('{}');
        mockResponse.setStatusCode(429);
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(mockResponse));

        UpdateProfileDataInSourceSystemService.updateProfileDataInSAP(accountIds);
        Test.stopTest();
    }

    @isTest
    static void updateProfileDataOther() {
        Test.startTest();
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account 1' LIMIT 1];
        List<String> accountIds = new List<String>();
        accountIds.add(acc.Id);

        HttpResponse mockResponse = new HttpResponse(); 
        mockResponse.setBody('{}');
        mockResponse.setStatusCode(300);
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(mockResponse));

        UpdateProfileDataInSourceSystemService.updateProfileDataInSAP(accountIds);
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