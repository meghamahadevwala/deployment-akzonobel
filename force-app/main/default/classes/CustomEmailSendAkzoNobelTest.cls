// << START - MM - FIN-9133 - [AkzoNobel] My Emails -> Send Email using custom apex class >>
@isTest
public with sharing class CustomEmailSendAkzoNobelTest {
    @isTest
    static void testCustomEmailSendAkzoNobel() {
        CustomEmailSendAkzoNobel customEmailSendAkzoNobel = new CustomEmailSendAkzoNobel();
        celsrm.GOGEmailMapper.SendEmailBean emailBean = new celsrm.GOGEmailMapper.SendEmailBean();
        emailBean.to = new List<String>{'test@example.com'};
        emailBean.cc = new List<String>{'test@example.com'};
        emailBean.subject = 'Test Subject';
        emailBean.htmlBody = 'Test HTML Body';
        emailBean.plainTextBody = 'Test Plain Text Body';
        Map<String, Object> result = customEmailSendAkzoNobel.invoke(emailBean);
        System.debug('Result: ' + result);
    }

    /**
     * Test email sending with attachments
     */
    @isTest
    static void testSendEmailWithAttachment() {
        Test.startTest();
        
        // Create test content document and version
        ContentVersion cv = new ContentVersion();
        cv.Title = 'TestFile';
        cv.PathOnClient = '/TestFile.pdf';
        cv.VersionData = Blob.valueOf('Test Content');
        cv.IsMajorVersion = true;
        insert cv;
        
        CustomEmailSendAkzoNobel customEmailSendAkzoNobel = new CustomEmailSendAkzoNobel();
        celsrm.GOGEmailMapper.SendEmailBean emailBean = new celsrm.GOGEmailMapper.SendEmailBean();
        emailBean.to = new List<String>{'recipient@example.com'};
        emailBean.cc = new List<String>{'cc@example.com'};
        emailBean.subject = 'Test Email With Attachment';
        emailBean.htmlBody = '<html><body>Test HTML Body with Attachment</body></html>';
        emailBean.plainTextBody = 'Test Plain Text Body with Attachment';
        emailBean.attachment = new List<Map<String, String>>{
            new Map<String, String>{
                'Id' => cv.Id,
                'Title' => 'TestFile',
                'fileExtension' => 'pdf'
            }
        };
        
        Map<String, Object> result = customEmailSendAkzoNobel.invoke(emailBean);
        
        Test.stopTest();
        
        System.assertEquals(true, result.get('success'), 'Email should be sent successfully');
        
        // Verify EmailMessage was created with attachment flag
        List<EmailMessage> emailMessages = [SELECT Id, Subject, celsrm__HasAttachment__c FROM EmailMessage LIMIT 1];
        System.assertEquals(1, emailMessages.size(), 'One email message should be created');
        System.assertEquals(true, emailMessages[0].celsrm__HasAttachment__c, 'Email should have attachment flag set');
        
        // Verify ContentDocumentLink was created
        List<ContentDocumentLink> contentLinks = [SELECT Id, ContentDocumentId, LinkedEntityId, ShareType FROM ContentDocumentLink WHERE LinkedEntityId = :emailMessages[0].Id];
        System.assertEquals(1, contentLinks.size(), 'One content document link should be created');
        System.assertEquals('V', contentLinks[0].ShareType, 'ShareType should be V (Viewer)');
    }
}
// << END - MM - FIN-9133 - [AkzoNobel] My Emails -> Send Email using custom apex class >>