@isTest
public class UpdateReferencesInSourceSystemTest {
    @testSetup
    static void setupData() {
        Account acc1 = new Account(
            Name = 'Test Account 1', 
            CurrencyIsoCode = 'EUR', 
            celsrm__Account_Key__c = '1111',
            AccountNumber = '1111',
            celsrm__Credit_Control_Area__c = 'POPL',
            ParentId = null
        );

        insert acc1;

        Account acc2 = new Account(
            Name = 'Test Account 2', 
            CurrencyIsoCode = 'EUR', 
            celsrm__Account_Key__c = '2222',
            AccountNumber = '2222',
            celsrm__Credit_Control_Area__c = 'POPL',
            ParentId = acc1.Id
        );

        insert acc2;

        Account acc3 = new Account(
            Name = 'Test Account 3', 
            CurrencyIsoCode = 'EUR', 
            celsrm__Account_Key__c = '3333',
            AccountNumber = '3333',
            celsrm__Credit_Control_Area__c = 'POPL',
            ParentId = null
        );

        insert acc3;

        Credit_Configuration__c creditConfig = new Credit_Configuration__c(
            Update_References_Action_Flow_Webhook__c = 'AAAA'
        );
        insert creditConfig;
    }

    @isTest
    static void updateRefData200() {
        Test.startTest();
        Account acc = [SELECT Id, AccountNumber, celsrm__Credit_Control_Area__c, ParentId FROM Account WHERE Name = 'Test Account 2' LIMIT 1];
        Account newParent = [SELECT Id, AccountNumber, celsrm__Credit_Control_Area__c FROM Account WHERE Name = 'Test Account 3' LIMIT 1];
        List<Map<String, String>> objMapList = new List<Map<String, String>>();
        
        Map<String, String> objMap = new Map<String, String>();
        objMap.put('accountId', acc.Id);
        objMap.put('accountNumber', acc.AccountNumber);
        objMap.put('creditControlArea', acc.celsrm__Credit_Control_Area__c);
        objMap.put('oldParentId', acc.ParentId);
        objMap.put('newParentId', newParent.Id);

        objMapList.add(objMap);

        HttpResponse mockResponse = new HttpResponse(); 
        mockResponse.setBody('{"status":"Success", "details":{"updateResponse":[{"IV_PARTNER_2":"2222","STATUS_MSG":"Update successful","IV_DIFFERENTIATION":"POPL"}]}}');
        mockResponse.setStatusCode(200);
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(mockResponse));

        UpdateReferencesInSourceSystemService.updateReferenceDataInSAP(objMapList);
        Test.stopTest();
    }

    @isTest
    static void updateRefData401() {
        Test.startTest();
        Account acc = [SELECT Id, AccountNumber, celsrm__Credit_Control_Area__c, ParentId FROM Account WHERE Name = 'Test Account 2' LIMIT 1];
        Account newParent = [SELECT Id, AccountNumber, celsrm__Credit_Control_Area__c FROM Account WHERE Name = 'Test Account 3' LIMIT 1];
        List<Map<String, String>> objMapList = new List<Map<String, String>>();
        
        Map<String, String> objMap = new Map<String, String>();
        objMap.put('accountId', acc.Id);
        objMap.put('accountNumber', acc.AccountNumber);
        objMap.put('creditControlArea', acc.celsrm__Credit_Control_Area__c);
        objMap.put('oldParentId', acc.ParentId);
        objMap.put('newParentId', newParent.Id);

        objMapList.add(objMap);

        HttpResponse mockResponse = new HttpResponse(); 
        mockResponse.setBody('{"status":"Error", "details":"Failed to update"}');
        mockResponse.setStatusCode(401);
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(mockResponse));

        UpdateReferencesInSourceSystemService.updateReferenceDataInSAP(objMapList);
        Test.stopTest();
    }

    @isTest
    static void updateRefData429() {
        Test.startTest();
        Account acc = [SELECT Id, AccountNumber, celsrm__Credit_Control_Area__c, ParentId FROM Account WHERE Name = 'Test Account 2' LIMIT 1];
        Account newParent = [SELECT Id, AccountNumber, celsrm__Credit_Control_Area__c FROM Account WHERE Name = 'Test Account 3' LIMIT 1];
        List<Map<String, String>> objMapList = new List<Map<String, String>>();
        
        Map<String, String> objMap = new Map<String, String>();
        objMap.put('accountId', acc.Id);
        objMap.put('accountNumber', acc.AccountNumber);
        objMap.put('creditControlArea', acc.celsrm__Credit_Control_Area__c);
        objMap.put('oldParentId', acc.ParentId);
        objMap.put('newParentId', newParent.Id);

        objMapList.add(objMap);

        HttpResponse mockResponse = new HttpResponse(); 
        mockResponse.setBody('{"status":"Error", "details":"Failed to update"}');
        mockResponse.setStatusCode(429);
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(mockResponse));

        UpdateReferencesInSourceSystemService.updateReferenceDataInSAP(objMapList);
        Test.stopTest();
    }

    @isTest
    static void updateRefData430() {
        Test.startTest();
        Account acc = [SELECT Id, AccountNumber, celsrm__Credit_Control_Area__c, ParentId FROM Account WHERE Name = 'Test Account 2' LIMIT 1];
        Account newParent = [SELECT Id, AccountNumber, celsrm__Credit_Control_Area__c FROM Account WHERE Name = 'Test Account 3' LIMIT 1];
        List<Map<String, String>> objMapList = new List<Map<String, String>>();
        
        Map<String, String> objMap = new Map<String, String>();
        objMap.put('accountId', acc.Id);
        objMap.put('accountNumber', acc.AccountNumber);
        objMap.put('creditControlArea', acc.celsrm__Credit_Control_Area__c);
        objMap.put('oldParentId', acc.ParentId);
        objMap.put('newParentId', newParent.Id);

        objMapList.add(objMap);

        HttpResponse mockResponse = new HttpResponse(); 
        mockResponse.setBody('{"status":"Error", "details":"Failed to update"}');
        mockResponse.setStatusCode(429);
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(mockResponse));

        UpdateReferencesInSourceSystemService.updateReferenceDataInSAP(objMapList);
        Test.stopTest();
    }

    @isTest
    static void updateRefData500() {
        Test.startTest();
        Account acc = [SELECT Id, AccountNumber, celsrm__Credit_Control_Area__c, ParentId FROM Account WHERE Name = 'Test Account 2' LIMIT 1];
        Account newParent = [SELECT Id, AccountNumber, celsrm__Credit_Control_Area__c FROM Account WHERE Name = 'Test Account 3' LIMIT 1];
        List<Map<String, String>> objMapList = new List<Map<String, String>>();
        
        Map<String, String> objMap = new Map<String, String>();
        objMap.put('accountId', acc.Id);
        objMap.put('accountNumber', acc.AccountNumber);
        objMap.put('creditControlArea', acc.celsrm__Credit_Control_Area__c);
        objMap.put('oldParentId', acc.ParentId);
        objMap.put('newParentId', newParent.Id);

        objMapList.add(objMap);

        HttpResponse mockResponse = new HttpResponse(); 
        mockResponse.setBody('{}');
        mockResponse.setStatusCode(500);
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(mockResponse));

        UpdateReferencesInSourceSystemService.updateReferenceDataInSAP(objMapList);
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