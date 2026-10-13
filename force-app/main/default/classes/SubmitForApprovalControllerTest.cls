@isTest
private class SubmitForApprovalControllerTest {
    
    public class MockHttpResponseGenerator implements HttpCalloutMock {
        private HttpResponse mockResponse;
        
        public MockHttpResponseGenerator(HttpResponse mockResponse) {
            this.mockResponse = mockResponse;
        }

        public HttpResponse respond(HttpRequest req) {
            return mockResponse;
        }
    }

    static testMethod void test_submitForApproval_201() {
        // Create Account
        Account acc = new Account(
            Name = 'Test Account',
            AccountNumber = '123456',
            BillingStreet = '123 Main St',
            BillingPostalCode = '123456',
            BillingCity = 'TestCity',
            BillingState = 'TestState',
            BillingCountry = 'TestCountry',
            celsrm__Credit_Control_Area__c = 'Area1',
            celsrm__Company_Code__c = 'Comp1',
            CurrencyIsoCode = 'EUR'
        );
        insert acc;

        // Create Credit Review
        celsrm__Credit_Review__c cr = new celsrm__Credit_Review__c(
            celsrm__Account__c = acc.Id,
            celsrm__Status__c = '10', // Valid status
            celsrm__Requested_Credit_Limit__c = 10000,
            Credit_Limit__c = 8000,
            celsrm__Risk_Class__c = 'Low',
            Credit_Exposure__c = 2000,
            Expected_Turnover__c = 50000,
            Secured_Amount__c = 1000,
            celsrm__Credit_Group__c = 'Group1',
            Payment_Terms_Days__c = 30,
            Moody_s_Credit_Limit__c = 12000,
            Requested_Valid_To_Date__c = Date.today().addMonths(6),
            celsrm__Model_Type__c = 'Model-A',
            celsrm__Notes__c = 'Some notes'
        );
        insert cr;

        // Create Open Transactions
        celsrm__Transaction__c trans = new celsrm__Transaction__c(
            celsrm__Account__c = acc.Id,
            celsrm__Due_Date__c = Date.today().addDays(15),
            celsrm__Amount__c = 1000,
            CurrencyIsoCode = 'EUR'
        );
        insert trans;

        // Create File_MIME_Type
        insert new File_MIME_Type__c(Name='pdf', MIME_Type__c='application/pdf');

        // Insert dummy ContentVersion
        ContentVersion cv = new ContentVersion(
            Title = 'Test File',
            PathOnClient = 'test.pdf',
            VersionData = Blob.valueOf('dummy data')
        );
        insert cv;

        // Re-query to get ContentDocumentId
        cv = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];

        insert new ContentDocumentLink(
            LinkedEntityId = cr.Id,
            ContentDocumentId = cv.ContentDocumentId,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );

        
        Test.startTest();

        HttpResponse mockResponse = new HttpResponse();
        mockResponse.setBody('{}');
        mockResponse.setStatusCode(201);
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(mockResponse));
        SubmitForApprovalController.SubmitForApprovalResponse resp = 
            SubmitForApprovalController.submitForApproval(cr.Id, true);
        Test.stopTest();    
    }

    static testMethod void test_submitForApproval_422() {
        Account acc = new Account(
            Name = 'Test Account2',
            AccountNumber = '123456',
            BillingStreet = '123 Main St',
            BillingPostalCode = '123456',
            BillingCity = 'TestCity',
            BillingState = 'TestState',
            BillingCountry = 'TestCountry',
            celsrm__Credit_Control_Area__c = 'Area1',
            celsrm__Company_Code__c = 'Comp1',
            CurrencyIsoCode = 'EUR'
        );
        insert acc;

        celsrm__Credit_Review__c cr = new celsrm__Credit_Review__c(
            celsrm__Account__c = acc.Id,
            celsrm__Status__c = '10'
        );
        insert cr;

        Test.startTest();

        HttpResponse mockResponse = new HttpResponse();
        mockResponse.setBody('[{"msg": "Invalid data for approval"}]');
        mockResponse.setStatusCode(422);
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(mockResponse));
        SubmitForApprovalController.SubmitForApprovalResponse resp = 
            SubmitForApprovalController.submitForApproval(cr.Id, false);

        Test.stopTest();

    }

//     static testMethod void test_submitForApproval_withAttachments_largeHeap() {
//     // Create Account and Credit Review
//     Account acc = new Account(Name='Test Account3', CurrencyIsoCode='EUR');
//     insert acc;

//     celsrm__Credit_Review__c cr = new celsrm__Credit_Review__c(
//         celsrm__Account__c=acc.Id,
//         celsrm__Status__c='10'
//     );
//     insert cr;

//     // Create File_MIME_Type
//     insert new File_MIME_Type__c(Name='pdf', MIME_Type__c='application/pdf');

//     // Insert dummy ContentVersion
//     ContentVersion cv = new ContentVersion(
//         Title = 'Test File',
//         PathOnClient = 'test.pdf',
//         VersionData = Blob.valueOf('dummy data')
//     );
//     insert cv;

//     // Re-query to get ContentDocumentId
//     cv = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];

//     insert new ContentDocumentLink(
//         LinkedEntityId = cr.Id,
//         ContentDocumentId = cv.ContentDocumentId,
//         ShareType = 'V',
//         Visibility = 'AllUsers'
//     );

//     Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

//     SubmitForApprovalController.SubmitForApprovalResponse resp = 
//         SubmitForApprovalController.submitForApproval(cr.Id, true);

// }


//     static testMethod void test_submitForApproval_callout422() {
//         Account acc = new Account(Name='Test Acc 422', CurrencyIsoCode='EUR');
//         insert acc;

//         celsrm__Credit_Review__c cr = new celsrm__Credit_Review__c(
//             celsrm__Account__c=acc.Id,
//             celsrm__Status__c='10'
//         );
//         insert cr;

//         Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

//         SubmitForApprovalController.SubmitForApprovalResponse resp = 
//             SubmitForApprovalController.submitForApproval(cr.Id, false);

//     }

//     static testMethod void test_submitForApproval_exceptionHandling() {
//         SubmitForApprovalController.SubmitForApprovalResponse resp = 
//             SubmitForApprovalController.submitForApproval(null, false);

//     }
}