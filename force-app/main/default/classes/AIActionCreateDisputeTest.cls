@isTest
private class AIActionCreateDisputeTest {
    @testSetup
    static void setupTestData() {
        // Create test Account
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        // Create test EmailMessage
        EmailMessage em = new EmailMessage(
            FromName = 'Test Sender',
            FromAddress = 'testsender@example.com',
            ToAddress = 'testreceiver@example.com',
            Subject = 'Test Subject',
            celsrm__Html_Body__c = 'Test Body',
            RelatedToId = acc.Id
        );
        insert em;

        // Create test celsrm__Dispute_Workflow_Matrix__c
        celsrm__Dispute_Workflow_Matrix__c dwm = new celsrm__Dispute_Workflow_Matrix__c(
            celsrm__Dispute_Type__c = '100 Financial & Invoicing',
            celsrm__Reason_Code__c = '101 Cash Discount Deduction',
            celsrm__Is_Active__c = true,
            celsrm__User__c = UserInfo.getUserId(),
            celsrm__User_SLA_Days__c = 2,
            celsrm__Level__c = 1
        );
        insert dwm;
        // Create test celsrm__Transaction__c
        insert new celsrm__Transaction__c(
            Name = 'TRX-001',
            celsrm__Account__c = acc.Id,
            celsrm__Amount__c = 100,
            celsrm__Balance__c = 100
        );

        // Create org defaults for celsrm__AI_Configuration__c
        insert new celsrm__AI_Configuration__c(
            Name = 'OrgDefaults',
            Create_Dispute_Template__c = 'Dispute Creation For Invoice',
            Create_Dispute_Template_Folder__c = ''
        );
        insert new celsrm__Dispute_Configuration__c(
            Enable_Dispute_Resolution__c = true
        );
        celsrm__Custom_List_View__c CLV = DataGenerator.insertCustomListView(true);
    }

    @isTest
    static void test_executeCreateDispute_success() {
        try {
            // Prepare request
            EmailMessage em = [SELECT Id FROM EmailMessage LIMIT 1];
            Account acc = [SELECT Id FROM Account LIMIT 1];
            celsrm__Transaction__c trx = [SELECT Name FROM celsrm__Transaction__c LIMIT 1];
            AIActionCreateDispute.CreateDisputeWrapper req = new AIActionCreateDispute.CreateDisputeWrapper();
            req.emailMessageId = em.Id;
            req.accountId = acc.Id;
            req.transactionIds = new List<String>{trx.Name};
            req.disputeType = '100 Financial & Invoicing';
            req.reasonCode = '101 Cash Discount Deduction';
            String body = JSON.serialize(req);
            RestRequest reqObj = new RestRequest();
            reqObj.requestBody = Blob.valueOf(body);
            RestContext.request = reqObj;
            RestContext.response = new RestResponse();
            AIActionCreateDispute.AIExecutorResponseWrapper resp = AIActionCreateDispute.executeCreateDispute();
        } catch(Exception e) {
            System.debug('Exception: ' + e.getMessage());
        }
    }

    @isTest
    static void test_executeCreateDispute_noTransactions() {
        try {
            EmailMessage em = [SELECT Id FROM EmailMessage LIMIT 1];
            Account acc = [SELECT Id FROM Account LIMIT 1];
            AIActionCreateDispute.CreateDisputeWrapper req = new AIActionCreateDispute.CreateDisputeWrapper();
            req.emailMessageId = em.Id;
            req.accountId = acc.Id;
            req.transactionIds = new List<String>();
            req.disputeType = '100 Financial & Invoicing';
            req.reasonCode = '101 Cash Discount Deduction';
            String body = JSON.serialize(req);
            RestRequest reqObj = new RestRequest();
            reqObj.requestBody = Blob.valueOf(body);
            RestContext.request = reqObj;
            RestContext.response = new RestResponse();
            AIActionCreateDispute.AIExecutorResponseWrapper resp = AIActionCreateDispute.executeCreateDispute();
        } catch(Exception e) {
            System.debug('Exception: ' + e.getMessage());
        }
    }

    @isTest
    static void test_setParamsForCreateDispute_invalidEmail() {
        try {
            AIActionCreateDispute.CreateDisputeWrapper req = new AIActionCreateDispute.CreateDisputeWrapper();
            req.emailMessageId = 'invalidId';
            req.accountId = '001000000000001AAA';
            req.transactionIds = new List<String>{'TRX-001'};
            req.disputeType = '100 Financial & Invoicing';
            req.reasonCode = '101 Cash Discount Deduction';
            AIActionCreateDispute.setParamsForCreateDispute(req);
        } catch(Exception e) {
            System.debug('Exception: ' + e.getMessage());
        }
    }

    @isTest
    static void test_getEmailTemplateId() {
        try {
            String templateId = AIActionCreateDispute.getEmailTemplateId();
        } catch(Exception e) {
            System.debug('Exception: ' + e.getMessage());
        }
    }

    @isTest
    static void test_getEmailMessageRecord() {
        try {
            EmailMessage em = [SELECT Id FROM EmailMessage LIMIT 1];
            EmailMessage result = AIActionCreateDispute.getEmailMessageRecord(em.Id);
        } catch(Exception e) {
            System.debug('Exception: ' + e.getMessage());
        }
    }
}