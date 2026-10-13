@isTest
public with sharing class CustomerSupportClassTest {
    public static testMethod void test() {
        
        // User userObj = DataGenerator.insertUser();
        ContentVersion cv = new ContentVersion();
        cv.Title = 'Test Document';
        cv.PathOnClient = 'TestDocument.pdf';
        cv.VersionData = Blob.valueOf('Test Content');
        cv.IsMajorVersion = true;
        insert cv;

        cv = [SELECT Id, ContentDocumentId FROM ContentVersion LIMIT 1];
        Map<Object, Object> inMap = new Map<Object, Object>();
        List<Object> Attachment = new List<Object>();
        Map<Object, Object> obj = new Map<Object, Object>();
        obj.put('ContentDocumentId', cv.ContentDocumentId);
        Attachment.add(obj);

        CustomerSupportClass customerSupport = new CustomerSupportClass();
        customerSupport.invoke('ExtractData', inMap);

        inMap.put('Attachment', Attachment);
        inMap.put('ErrorMessage','ErrorMessage');
        inMap.put('IssueReproduceSteps','IssueReproduceSteps');
        inMap.put('EmailAddress', 'test@mail.com');
        customerSupport.invoke('SendEmail', inMap);

    }
}