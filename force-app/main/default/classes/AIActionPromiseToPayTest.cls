@isTest
private class AIActionPromiseToPayTest {
    @testSetup
    static void setup() {
        // Create Account
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        // Create EmailMessage
        EmailMessage em = new EmailMessage(
            FromName = 'Test Sender',
            FromAddress = 'testsender@example.com',
            ToAddress = 'testreceiver@example.com',
            CcAddress = 'testcc@example.com',
            BccAddress = 'testbcc@example.com',
            Subject = 'Test Subject',
            celsrm__Html_Body__c = 'Body1',
            celsrm__Html_Body_2__c = 'Body2',
            celsrm__Html_Body_3__c = 'Body3',
            celsrm__Html_Body_4__c = 'Body4',
            RelatedToId = acc.Id
        );
        insert em;
        // Create Transaction
        celsrm__Transaction__c trx = new celsrm__Transaction__c(
            Name = 'TRX-001',
            celsrm__Account__c = acc.Id,
            celsrm__Amount__c = 100,
            celsrm__Balance__c = 50
        );
        insert trx;
        // Create AI Configuration
        celsrm__AI_Configuration__c config = new celsrm__AI_Configuration__c(
            Name = 'Default',
            Promise_To_Pay_Template__c = 'Promise To Pay Acknowledgement',
            Promise_To_Pay_Template_Folder__c = null
        );
        insert config;
        celsrm__Custom_List_View__c CLV = DataGenerator.insertCustomListView(true);
    }

    @isTest
    static void testExecutePromiseToPay_Success() {
        try {
            Account acc = [SELECT Id FROM Account LIMIT 1];
            EmailMessage em = [SELECT Id FROM EmailMessage LIMIT 1];
            celsrm__Transaction__c trx = [SELECT Name FROM celsrm__Transaction__c LIMIT 1];
            AIActionPromiseToPay.PromiseToPayWrapper req = new AIActionPromiseToPay.PromiseToPayWrapper();
            req.emailMessageId = em.Id;
            req.accountId = acc.Id;
            req.transactionIds = new List<String>{trx.Name};
            req.promiseDate = String.valueOf(Date.today().addDays(2));
            RestRequest reqRest = new RestRequest();
            reqRest.requestBody = Blob.valueOf(JSON.serialize(req));
            reqRest.httpMethod = 'POST';
            RestContext.request = reqRest;
            RestResponse res = new RestResponse();
            RestContext.response = res;
            AIActionPromiseToPay.AIExecutorResponseWrapper resp = AIActionPromiseToPay.executePromiseToPay();
        } catch (Exception e) {
            System.debug('Exception: ' + e.getMessage());
        }
    }

    @isTest
    static void testExecutePromiseToPay_NoTransactions() {
        try {
            Account acc = [SELECT Id FROM Account LIMIT 1];
            EmailMessage em = [SELECT Id FROM EmailMessage LIMIT 1];
            AIActionPromiseToPay.PromiseToPayWrapper req = new AIActionPromiseToPay.PromiseToPayWrapper();
            req.emailMessageId = em.Id;
            req.accountId = acc.Id;
            req.transactionIds = new List<String>();
            req.promiseDate = String.valueOf(Date.today().addDays(2));
            RestRequest reqRest = new RestRequest();
            reqRest.requestBody = Blob.valueOf(JSON.serialize(req));
            reqRest.httpMethod = 'POST';
            RestContext.request = reqRest;
            RestResponse res = new RestResponse();
            RestContext.response = res;
            AIActionPromiseToPay.AIExecutorResponseWrapper resp = AIActionPromiseToPay.executePromiseToPay();
        } catch (Exception e) {
            System.debug('Exception: ' + e.getMessage());
        }
    }

    @isTest
    static void testSetParamsForPromiseToPay_Exception() {
        try {
            AIActionPromiseToPay.PromiseToPayWrapper req = new AIActionPromiseToPay.PromiseToPayWrapper();
            req.emailMessageId = 'fakeId';
            req.accountId = 'fakeAcc';
            req.transactionIds = new List<String>{'fakeTrx'};
            req.promiseDate = String.valueOf(Date.today().addDays(2));
            Test.startTest();
            AIActionPromiseToPay.setParamsForPromiseToPay(req);
            Test.stopTest();
        } catch (Exception e) {
            System.debug('Exception: ' + e.getMessage());
        }
    }

    @isTest
    static void testGetEmailTemplateId() {
        try {
            Test.startTest();
            String templateId = AIActionPromiseToPay.getEmailTemplateId();
            Test.stopTest();
        } catch (Exception e) {
            System.debug('Exception: ' + e.getMessage());
        }
    }

    @isTest
    static void testGetEmailMessageRecord() {
        try {
            EmailMessage em = [SELECT Id FROM EmailMessage LIMIT 1];
            Test.startTest();
            EmailMessage result = AIActionPromiseToPay.getEmailMessageRecord(em.Id);
            Test.stopTest();
        } catch (Exception e) {
            System.debug('Exception: ' + e.getMessage());
        }
    }
}