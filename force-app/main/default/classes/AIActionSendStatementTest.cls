@isTest
private class AIActionSendStatementTest {
    @testSetup
    static void setup() {
        // Create test Account
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        // Create test EmailMessage
        EmailMessage em = new EmailMessage(Subject = 'Test Subject', FromAddress = 'test@example.com', FromName = 'Test Sender', ToAddress = 'to@example.com', CcAddress = 'cc@example.com', BccAddress = 'bcc@example.com', celsrm__Html_Body__c = 'Body', celsrm__Html_Body_2__c = 'Body2', celsrm__Html_Body_3__c = 'Body3', celsrm__Html_Body_4__c = 'Body4', RelatedToId = acc.Id);
        insert em;
        // Create test AI Configuration
        celsrm__AI_Configuration__c aiConf = new celsrm__AI_Configuration__c(Send_Statement_Template__c = 'Billing Statement', Send_Statement_Template_Folder__c = '');
        insert aiConf;
        // Create test Transaction
        celsrm__transaction__c trx = new celsrm__transaction__c(Name = 'TRX-001', celsrm__Account__c = acc.Id);
        insert trx;
        celsrm__Custom_List_View__c cl = DataGenerator.insertCustomListView(true);
        cl.Name =  'All Overdue';
        cl.Folder_Name__c = 'Send Statement';
        update cl;
    }

    @isTest
    static void testExecuteSendStatement_AllParams() {
        try {
            Account acc = [SELECT Id FROM Account LIMIT 1];
            EmailMessage em = [SELECT Id FROM EmailMessage LIMIT 1];
            celsrm__transaction__c trx = [SELECT Name FROM celsrm__transaction__c LIMIT 1];
            List<String> trxIds = new List<String>{trx.Name};
            Test.startTest();
            AIActionSendStatement.AIExecutorResponseWrapper resp = AIActionSendStatement.executeSendStatement(em.Id, acc.Id, trxIds, 'All Overdue Invoice');
            Test.stopTest();
        } catch (Exception e) {
            System.debug('Exception: ' + e.getMessage());
        }
    }

    @isTest
    static void testExecuteSendStatement_NullAccount() {
        try {
            EmailMessage em = [SELECT Id FROM EmailMessage LIMIT 1];
            Test.startTest();
            AIActionSendStatement.AIExecutorResponseWrapper resp = AIActionSendStatement.executeSendStatement(em.Id, null, null, null);
            Test.stopTest();
        } catch (Exception e) {
            System.debug('Exception: ' + e.getMessage());
        }
    }

    @isTest
    static void testSetParamsForStatement_AllParams() {
        try {
            Account acc = [SELECT Id FROM Account LIMIT 1];
            EmailMessage em = [SELECT Id FROM EmailMessage LIMIT 1];
            celsrm__transaction__c trx = [SELECT Name FROM celsrm__transaction__c LIMIT 1];
            List<String> trxIds = new List<String>{trx.Name};
            Map<Object,Object> inMap = AIActionSendStatement.setParamsForStatement(em.Id, acc.Id, trxIds, 'All Overdue');
        } catch (Exception e) {
            System.debug('Exception: ' + e.getMessage());
        }
    }

    @isTest
    static void testSetParamsForStatement_NullEmail() {
        try {
            Account acc = [SELECT Id FROM Account LIMIT 1];
            celsrm__transaction__c trx = [SELECT Name FROM celsrm__transaction__c LIMIT 1];
            List<String> trxIds = new List<String>{trx.Name};
            Map<Object,Object> inMap = AIActionSendStatement.setParamsForStatement(null, acc.Id, trxIds, 'All Overdue');
        } catch (Exception e) {
            System.debug('Exception: ' + e.getMessage());
        }
    }

    @isTest
    static void testGetEmailTemplateId() {
        try {
            String templateId = AIActionSendStatement.getEmailTemplateId('Billing Statement', '');
        } catch (Exception e) {
            System.debug('Exception: ' + e.getMessage());
        }
    }

    @isTest
    static void testGetListViewId() {
        try {
            String listViewId = AIActionSendStatement.getListViewId('All Overdue');
        } catch (Exception e) {
            System.debug('Exception: ' + e.getMessage());
        }
    }

    @isTest
    static void testGetEmailMessageRecord() {
        try {
            EmailMessage em = [SELECT Id FROM EmailMessage LIMIT 1];
            EmailMessage result = AIActionSendStatement.getEmailMessageRecord(em.Id);
        } catch (Exception e) {
            System.debug('Exception: ' + e.getMessage());
        }
    }
}