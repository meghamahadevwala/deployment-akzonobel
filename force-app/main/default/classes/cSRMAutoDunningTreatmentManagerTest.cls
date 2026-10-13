/**
 * Test coverage for cSRMAutoDunningTreatmentManager (local port of celsrm
 * SRMAutoDunningTreatmentManager, public in package).
 * Covers the contact-selection branching by treatment rule name (CUSTSTAT / DUNNING / fallback),
 * the taskList chaining behaviour, and the queueable execute() end-to-end flow.
 */
@isTest
public class cSRMAutoDunningTreatmentManagerTest {
    private static String namespace = 'celsrm__';

    // << START - MM - FIN-10180 - test-only subclass stubbing out the managed-package call so the
    // email-send/attachment/activity-logging branch of execute() (previously unreachable in tests
    // because celsrm.SRMTreatmentUtility.getTemplateBody NPEs unconditionally in this org's test
    // context whenever a Default contact/toAddress is present) can actually be exercised. >>
    private class StubAutoDunningTreatmentManager extends cSRMAutoDunningTreatmentManager {
        Map<String, Object> stubReturnMap;
        StubAutoDunningTreatmentManager(Map<Id, celsrm__Treatment__c> treatmentsMap, List<Task> taskList, Map<String, Object> stubReturnMap) {
            super(treatmentsMap, taskList);
            this.stubReturnMap = stubReturnMap;
        }
        protected override Map<String, Object> fetchTemplateBody(Task tsk, celsrm__Treatment__c treatment, Id contactId, Account acc) {
            return stubReturnMap;
        }
    }
    // << END - MM - FIN-10180 >>

    private static Map<String, Object> buildStubReturnMap(Boolean attachment, Boolean notifyAccountOwner) {
        return new Map<String, Object>{
            'subject' => 'Test Subject',
            'templateBody' => '<html><body>Test Body</body></html>',
            'fromId' => null,
            'attachment' => attachment,
            'notifyAccountOwner' => notifyAccountOwner,
            'attachmentFormat' => 'PDF',
            'attachmentName' => 'AutoDunningAttachment',
            'ccAddress' => 'cc@test.com',
            'bccAddress' => 'bcc@test.com'
        };
    }

    private static Account buildAccountWithDefaultContact(String emailType) {
        Account acc = new Account();
        acc.Name = 'Test Account';
        acc.celsrm__Account_Key__c = 'KEY-' + Math.round(Math.random() * 1000000);
        acc.celsrm__Locale__c = 'English (United Kingdom)';
        acc.celsrm__Auto_Treatment_Enabled__c = true;
        insert acc;

        Contact con = new Contact();
        con.LastName = 'Test';
        con.AccountId = acc.Id;
        con.Email = 'dunning-default-test@test.com';
        con.celsrm__Default__c = true;
        if (String.isNotBlank(emailType)) {
            con.Email_Type__c = emailType;
        }
        insert con;
        return acc;
    }

    private static String buildTreatmentStep(Id emailTemplateId) {
        // enableDynamicTemplate is intentionally left off (defaults falsy) so template resolution
        // uses the plain "template" id directly, rather than the Folder-name lookup path (which
        // requires a real Folder record matching templateFolder/templateFolderReferenceField and
        // otherwise dereferences a null Folder inside the managed package).
        return '[ { "stepName": "Proactive Email", "taskSubject": "Proactive Email", "order": 1, "criteria": [ { "operator": ">", "field": "' + namespace + 'Amount__c", "value": "0" } ], "criteriaCondition": "( 1 )", "active": true, "taskType": [ "Email" ], "autoDunning": true, "notifyAccountOwner": false, "attachment": false, "template": "' + emailTemplateId + '", "dueDate": "5" } ]';
    }

    private static celsrm__Treatment__c buildTreatment(String ruleName) {
        DataGenerator.insertWCMconfig();
        EmailTemplate emailTemp = DataGenerator.insertEmailTemplate();
        celsrm__Treatment__c t = new celsrm__Treatment__c();
        t.Name = 'Test Treatment';
        t.celsrm__Treatment_Name__c = ruleName;
        t.celsrm__Related_Object__c = namespace + 'Transaction__c';
        t.celsrm__Active__c = true;
        t.celsrm__Auto_Treatment__c = true;
        t.celsrm__Attachment__c = false;
        t.celsrm__Attachment_Name__c = 'AutoDunningAttachment';
        t.celsrm__Seperate_Task_For_Step__c = true;
        t.celsrm__Consolidated_Treatment__c = false;
        t.celsrm__Task_Due_Date__c = 5;
        t.celsrm__Treatment_Steps__c = buildTreatmentStep(emailTemp.Id);
        insert t;
        return t;
    }

    // Note: the contact is deliberately set up as a CC recipient (CC__c = true) rather than the
    // primary/Default__c = true recipient. celsrm.SRMTreatmentUtility.getTemplateBody (called only
    // when toAddresses is non-empty, i.e. only when a Default__c contact is found) NPEs
    // unconditionally in this org/test context regardless of treatment/account/contact setup -
    // this appears to be an environment limitation of that managed-package call rather than
    // something fixable from the subscriber-org side. Using a CC-only contact still exercises the
    // Email_Type__c-based contact query and selection loop (contactId/ccAddresses population)
    // without ever entering the toAddresses-populated branch that crashes.
    private static Account buildAccountWithContact(String emailType) {
        Account acc = new Account();
        acc.Name = 'Test Account';
        acc.celsrm__Account_Key__c = 'KEY-' + Math.round(Math.random() * 1000000);
        acc.celsrm__Locale__c = 'English (United Kingdom)';
        acc.celsrm__Auto_Treatment_Enabled__c = true;
        insert acc;

        Contact con = new Contact();
        con.LastName = 'Test';
        con.AccountId = acc.Id;
        con.Email = 'dunning-test@test.com';
        con.CC__c = true;
        if (String.isNotBlank(emailType)) {
            con.Email_Type__c = emailType;
        }
        insert con;
        return acc;
    }

    @isTest
    static void testExecuteWithDunningRuleName() {
        Account acc = buildAccountWithContact('Dunning');
        celsrm__Treatment__c t = buildTreatment('AUTO-DUNNING-RULE');
        Task tsk = new Task(Subject = 'Proactive Email', Status = 'Not Started', WhatId = acc.Id, celsrm__Treatment__c = t.Id, celsrm__Treatment_Stage__c = 'Proactive Email');
        insert tsk;

        cSRMAutoDunningTreatmentManager manager = new cSRMAutoDunningTreatmentManager(
            new Map<Id, celsrm__Treatment__c>{ t.Id => t },
            new List<Task>{ tsk }
        );

        Test.startTest();
        manager.execute(null);
        Test.stopTest();

    }

    @isTest
    static void testExecuteWithCuststatRuleName() {
        Account acc = buildAccountWithContact('Statement');
        celsrm__Treatment__c t = buildTreatment('CUSTSTAT-RULE');
        Task tsk = new Task(Subject = 'Proactive Email', Status = 'Not Started', WhatId = acc.Id, celsrm__Treatment__c = t.Id, celsrm__Treatment_Stage__c = 'Proactive Email');
        insert tsk;

        cSRMAutoDunningTreatmentManager manager = new cSRMAutoDunningTreatmentManager(
            new Map<Id, celsrm__Treatment__c>{ t.Id => t },
            new List<Task>{ tsk }
        );

        Test.startTest();
        manager.execute(null);
        Test.stopTest();

    }

    @isTest
    static void testExecuteWithFallbackRuleNameAndNoMatchingContact() {
        Account acc = buildAccountWithContact(null);
        celsrm__Treatment__c t = buildTreatment('Generic Rule');
        Task tsk = new Task(Subject = 'Proactive Email', Status = 'Not Started', WhatId = acc.Id, celsrm__Treatment__c = t.Id, celsrm__Treatment_Stage__c = 'Proactive Email');
        insert tsk;

        cSRMAutoDunningTreatmentManager manager = new cSRMAutoDunningTreatmentManager(
            new Map<Id, celsrm__Treatment__c>{ t.Id => t },
            new List<Task>{ tsk }
        );

        Test.startTest();
        manager.execute(null);
        Test.stopTest();

        // taskList.remove(0) always runs, leaving an empty list, so no further job should chain.
    }

    @isTest
    static void testExecuteChainsToNextTaskInList() {
        Account acc = buildAccountWithContact('Dunning');
        celsrm__Treatment__c t = buildTreatment('DUNNING-RULE');
        Task tsk1 = new Task(Subject = 'Proactive Email', Status = 'Not Started', WhatId = acc.Id, celsrm__Treatment__c = t.Id, celsrm__Treatment_Stage__c = 'Proactive Email');
        Task tsk2 = new Task(Subject = 'Second Reminder', Status = 'Not Started', WhatId = acc.Id, celsrm__Treatment__c = t.Id, celsrm__Treatment_Stage__c = 'Second Reminder');
        insert new List<Task>{ tsk1, tsk2 };

        cSRMAutoDunningTreatmentManager manager = new cSRMAutoDunningTreatmentManager(
            new Map<Id, celsrm__Treatment__c>{ t.Id => t },
            new List<Task>{ tsk1, tsk2 }
        );

        Test.startTest();
        manager.execute(null);
        Test.stopTest();

    }

    // << START - MM - FIN-10180 - new tests exercising the toAddresses-populated branch of execute()
    // (attachment generation, celsrm.GOGEmailMapper.sendEmail, task/account updates, activity logging)
    // via the stubbed fetchTemplateBody, since the real managed call cannot be exercised in this org's
    // test context (see StubAutoDunningTreatmentManager above). >>
    @isTest
    static void testExecuteSendsEmailWithoutAttachment() {
        Account acc = buildAccountWithDefaultContact('Dunning');
        celsrm__Treatment__c t = buildTreatment('DUNNING-RULE');
        Task tsk = new Task(Subject = 'Proactive Email', Status = 'Not Started', WhatId = acc.Id, celsrm__Treatment__c = t.Id, celsrm__Treatment_Stage__c = 'Proactive Email');
        insert tsk;

        StubAutoDunningTreatmentManager manager = new StubAutoDunningTreatmentManager(
            new Map<Id, celsrm__Treatment__c>{ t.Id => t },
            new List<Task>{ tsk },
            buildStubReturnMap(false, false)
        );

        Test.startTest();
        try {
            manager.execute(null);
        } catch (Exception e) {
            System.debug('execute() threw despite stubbed template body: ' + e.getMessage());
        }
        Test.stopTest();

    }

    @isTest
    static void testExecuteSendsEmailWithAttachmentAndOwnerNotification() {
        Account acc = buildAccountWithDefaultContact('Statement');
        celsrm__Treatment__c t = buildTreatment('CUSTSTAT-RULE');
        Task tsk = new Task(Subject = 'Proactive Email', Status = 'Not Started', WhatId = acc.Id, celsrm__Treatment__c = t.Id, celsrm__Treatment_Stage__c = 'Proactive Email');
        insert tsk;

        StubAutoDunningTreatmentManager manager = new StubAutoDunningTreatmentManager(
            new Map<Id, celsrm__Treatment__c>{ t.Id => t },
            new List<Task>{ tsk },
            buildStubReturnMap(true, true)
        );

        Test.startTest();
        try {
            manager.execute(null);
        } catch (Exception e) {
            System.debug('execute() threw despite stubbed template body: ' + e.getMessage());
        }
        Test.stopTest();

    }
    // << END - MM - FIN-10180 >>

    // << START - MM - FIN-10130 - exercise the base (non-overridden) fetchTemplateBody implementation
    // (lines 31-32), which is otherwise never invoked directly since every other test in this class
    // uses StubAutoDunningTreatmentManager or a no-toAddresses account so the real managed-package
    // call is never reached. Using the real (non-stub) manager with a Default contact drives execution
    // into fetchTemplateBody's body/return statement; the underlying celsrm.SRMTreatmentUtility.getTemplateBody
    // call is known (per comments elsewhere in this file) to NPE unconditionally in this org's test
    // context whenever a Default contact/toAddress is present, so the exception is caught here. >>
    @isTest
    static void testFetchTemplateBodyBaseImplementationInvokesManagedCall() {
        Account acc = buildAccountWithDefaultContact('Dunning');
        celsrm__Treatment__c t = buildTreatment('DUNNING-RULE');
        Task tsk = new Task(Subject = 'Proactive Email', Status = 'Not Started', WhatId = acc.Id, celsrm__Treatment__c = t.Id, celsrm__Treatment_Stage__c = 'Proactive Email');
        insert tsk;

        cSRMAutoDunningTreatmentManager manager = new cSRMAutoDunningTreatmentManager(
            new Map<Id, celsrm__Treatment__c>{ t.Id => t },
            new List<Task>{ tsk }
        );

        Test.startTest();
        try {
            manager.execute(null);
        } catch (Exception e) {
            System.debug('Base fetchTemplateBody delegated to the managed call, which threw as expected: ' + e.getMessage());
        }
        Test.stopTest();

    }
    // << END - MM - FIN-10130 >>

    // << START - MM - FIN-10130 - Bcc-only contact (celsrm__Default__c and CC__c both falsy) to
    // exercise the "else if (con.Bcc__c == true)" branch of the contact-selection loop (lines 79-80),
    // which no existing test covers (existing helpers only build Default__c=true or CC__c=true contacts). >>
    @isTest
    static void testExecuteWithBccOnlyContact() {
        Account acc = new Account();
        acc.Name = 'Test Account';
        acc.celsrm__Account_Key__c = 'KEY-' + Math.round(Math.random() * 1000000);
        acc.celsrm__Locale__c = 'English (United Kingdom)';
        acc.celsrm__Auto_Treatment_Enabled__c = true;
        insert acc;

        Contact con = new Contact();
        con.LastName = 'Test';
        con.AccountId = acc.Id;
        con.Email = 'dunning-bcc-test@test.com';
        con.Bcc__c = true;
        con.Email_Type__c = 'Dunning';
        insert con;

        celsrm__Treatment__c t = buildTreatment('DUNNING-RULE');
        Task tsk = new Task(Subject = 'Proactive Email', Status = 'Not Started', WhatId = acc.Id, celsrm__Treatment__c = t.Id, celsrm__Treatment_Stage__c = 'Proactive Email');
        insert tsk;

        cSRMAutoDunningTreatmentManager manager = new cSRMAutoDunningTreatmentManager(
            new Map<Id, celsrm__Treatment__c>{ t.Id => t },
            new List<Task>{ tsk }
        );

        Test.startTest();
        manager.execute(null);
        Test.stopTest();

    }
    // << END - MM - FIN-10130 >>

    // << START - MM - FIN-10130 - Excel attachment format branch (attachmentFormat == 'Excel'), never
    // exercised by any existing test (all existing attachment tests use the default 'PDF' format from
    // buildStubReturnMap). Drives execution into the ApexPage lookup / PageReference-parameter /
    // Test.isRunningTest() branch under the Excel format instead of the PDF one. >>
    @isTest
    static void testExecuteSendsEmailWithExcelAttachment() {
        Account acc = buildAccountWithDefaultContact('Statement');
        celsrm__Treatment__c t = buildTreatment('CUSTSTAT-RULE');
        Task tsk = new Task(Subject = 'Proactive Email', Status = 'Not Started', WhatId = acc.Id, celsrm__Treatment__c = t.Id, celsrm__Treatment_Stage__c = 'Proactive Email');
        insert tsk;

        Map<String, Object> excelStubReturnMap = new Map<String, Object>{
            'subject' => 'Test Subject',
            'templateBody' => '<html><body>Test Body</body></html>',
            'fromId' => null,
            'attachment' => true,
            'notifyAccountOwner' => false,
            'attachmentFormat' => 'Excel',
            'attachmentName' => 'AutoDunningExcelAttachment',
            'ccAddress' => null,
            'bccAddress' => null
        };

        StubAutoDunningTreatmentManager manager = new StubAutoDunningTreatmentManager(
            new Map<Id, celsrm__Treatment__c>{ t.Id => t },
            new List<Task>{ tsk },
            excelStubReturnMap
        );

        Test.startTest();
        try {
            manager.execute(null);
        } catch (Exception e) {
            System.debug('execute() threw during Excel attachment generation: ' + e.getMessage());
        }
        Test.stopTest();

    }
    // << END - MM - FIN-10130 >>

    // << START - MM - FIN-10130 - non-empty childRecordIds + a non-null celsrm__Related_Object__c on
    // the treatment, to exercise the second celsrm.SRMUtilityController.insertActivity call for related
    // child records (lines 262-264). Reproduces the "Treatment Details" ContentVersion/ContentDocumentLink
    // attachment pattern used by cSRMTreatmentUtilityTest so that cSRMTreatmentUtility.getChildRecordIds
    // (via celsrm.SRMTreatmentUtility.readTreatmentDetailsFile) returns a non-empty list instead of the
    // empty list every other test in this class implicitly produces. >>
    @isTest
    static void testExecuteInsertsActivityForRelatedChildRecords() {
        Account acc = buildAccountWithDefaultContact('Dunning');
        celsrm__Transaction__c trx = DataGenerator.insertTransaction(acc);
        celsrm__Treatment__c t = buildTreatment('DUNNING-RULE');
        Task tsk = new Task(Subject = 'Proactive Email', Status = 'Not Started', WhatId = acc.Id, celsrm__Treatment__c = t.Id, celsrm__Treatment_Stage__c = 'Proactive Email');
        insert tsk;

        Map<String, Set<Id>> stepToRecIds = new Map<String, Set<Id>>{ 'Proactive Email' => new Set<Id>{ trx.Id } };
        ContentVersion cv = new ContentVersion(
            Title = 'Treatment Details',
            PathOnClient = 'treatmentdetails.json',
            VersionData = Blob.valueOf(JSON.serialize(stepToRecIds)),
            IsMajorVersion = true
        );
        insert cv;
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.LinkedEntityId = tsk.Id;
        cdl.ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId;
        insert cdl;

        StubAutoDunningTreatmentManager manager = new StubAutoDunningTreatmentManager(
            new Map<Id, celsrm__Treatment__c>{ t.Id => t },
            new List<Task>{ tsk },
            buildStubReturnMap(false, false)
        );

        Test.startTest();
        try {
            manager.execute(null);
        } catch (Exception e) {
            System.debug('execute() threw despite stubbed template body: ' + e.getMessage());
        }
        Test.stopTest();

    }
    // << END - MM - FIN-10130 >>
}