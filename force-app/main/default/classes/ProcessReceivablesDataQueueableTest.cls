@isTest
public class ProcessReceivablesDataQueueableTest {
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
            celsrm__Account__c = acc1.Id,
            celsrm__Status__c = '10',
            Requested_Valid_To_Date__c = Date.today().addDays(30)
        );

        insert cr1;

        ContentVersion contentVersion = new ContentVersion(
            Title = 'Test Document',
            PathOnClient = 'TestDocument.pdf',
            VersionData = Blob.valueOf('This is a test document content')
        );
        insert contentVersion;

        ContentVersion insertedContentVersion = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion.Id LIMIT 1];
        ContentDocumentLink docLink = new ContentDocumentLink(
            ContentDocumentId = insertedContentVersion.ContentDocumentId,
            LinkedEntityId = cr1.Id
        );
        insert docLink;

        File_MIME_Type__c mimeType = new File_MIME_Type__c(
            Name = 'pdf',
            MIME_Type__c = 'application/pdf'
        );
        insert mimeType;
    }

    @isTest
    static void processReceivablesDataQueueableTest() {
        Test.startTest();

        HttpResponse mockResponse = new HttpResponse();
        mockResponse.setBody('{"status": "success"}'); 
        mockResponse.setStatusCode(200);

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(mockResponse));

        String creditReviewId = [SELECT Id FROM celsrm__Credit_Review__c LIMIT 1].Id;
        ProcessReceivablesDataQueueable.updateProcessReceivablesData(creditReviewId);

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