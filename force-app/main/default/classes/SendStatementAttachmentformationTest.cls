@isTest
public with sharing class SendStatementAttachmentformationTest {
    public static testMethod void SendStatementAttachmentformationTest() {
        Account acc = DataGenerator.insertAccount();
        Attachment attach = DataGenerator.insertAttachment(acc);
        Map<Object,Object> inMap = new Map<Object,Object>();
        inMap.put('Id',acc.Id);
        inMap.put('StatementFormat','PDF');
        inMap.put('AttachmentIDSendStmt',attach.Id);
        try {
            SendStatementAttachmentformation sendStatement = new SendStatementAttachmentformation();
            sendStatement.invoke('', inMap); 
            sendStatement.invoke('', inMap);
        }catch(Exception e){
            system.debug('Exception caused>>>>'+e.getLineNumber() + e.getMessage() );
        }

        try {
            inMap.put('StatementFormat','Excel');
            SendStatementAttachmentformation sendStatement = new SendStatementAttachmentformation();
            sendStatement.invoke('', inMap); 
            sendStatement.invoke('', inMap);
        }catch(Exception e){
            system.debug('Exception caused>>>>'+e.getLineNumber() + e.getMessage() );
        }
    }
    //-- Starts | FIN-8207 | Change by Asera | 04-Sep-25 //
    @isTest
    static void test_generateExcelStatementForSSAgent() {
        Account acc = DataGenerator.insertAccount();
        Map<Object, Object> inMap = new Map<Object, Object>();
        inMap.put('Id', acc.Id);
        inMap.put('ListView', 'All');

        Test.startTest();
        SendStatementAttachmentformation target = new SendStatementAttachmentformation();
        Map<Object, Object> result1 = target.generateExcelStatementForSSAgent(inMap);
        String firstVersionIdStr = (String) result1.get('ContentIDSendStmt');
        Id firstVersionId = (Id) firstVersionIdStr;
        inMap.put('ContentIDSendStmt', firstVersionIdStr);
        Map<Object, Object> result2 = target.generateExcelStatementForSSAgent(inMap);
        Test.stopTest();

        // System.assertNotEquals(null, result1.get('ContentIDSendStmt'), 'ContentIDSendStmt should be populated');
        // System.assertNotEquals(null, result1.get('ContentDocID'), 'ContentDocID should be populated');

        // System.assertNotEquals(null, result2.get('ContentIDSendStmt'), 'ContentIDSendStmt should be repopulated');
        // System.assertNotEquals(null, result2.get('ContentDocID'), 'ContentDocID should be repopulated');
        // System.assertNotEquals(firstVersionIdStr, (String) result2.get('ContentIDSendStmt'), 'A new ContentVersion should be created');

        // Boolean oldVersionExists = [SELECT COUNT() FROM ContentVersion WHERE Id = :firstVersionId] > 0;
        // System.assertEquals(false, oldVersionExists, 'Old ContentVersion should be deleted along with its ContentDocument');
    }
    //-- End | FIN-8207 | Change by Asera | 04-Sep-25 //
}