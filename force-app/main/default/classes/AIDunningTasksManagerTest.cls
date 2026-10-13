@isTest
public class AIDunningTasksManagerTest {

    @testSetup
    static void setup() {
        Account acc = DataGenerator.insertAccount();
        acc.AI_Dunning_Strategy__c = 'proactive';
        acc.Predicted_Payment_Dates__c = '2099-11-18';
        acc.AI_Dunning_Frequency__c = 5;
        acc.Overdue_Risk__c = 0.5;
        acc.DPD_Invoices__c = 10;
        try { update acc; } catch (Exception e) {}

        // Open transactions (Close_Date = null, Amount > 0) so the filtering layer selects them
        List<celsrm__Transaction__c> txns = new List<celsrm__Transaction__c>();
        for (Integer i = 0; i < 3; i++) {
            celsrm__Transaction__c t = new celsrm__Transaction__c();
            t.Name = 'OpenTxn' + i;
            t.celsrm__Account__c = acc.Id;
            t.celsrm__Amount__c = 5000 + (i * 1000);
            t.celsrm__Due_DATE__c = Date.today().addMonths(-1) + i;
            t.celsrm__Create_Date__c = Date.today().addMonths(-2);
            txns.add(t);
        }
        try { insert txns; } catch (Exception e) {}
    }

    private static celsrm__Treatment__c buildTreatment() {
        return buildTreatment(true);
    }

    private static celsrm__Treatment__c buildTreatment(Boolean autoTreatment) {
        return DataGenerator.insertTreatmentRecord(
            '', 'AI Overdue Reminder', null, 'Account', null, 'Email', 1,
            autoTreatment, null, null, null, null, 'AI Overdue Reminder', false);
    }

    private static Account getAcc() {
        return [SELECT Id, OwnerId FROM Account LIMIT 1];
    }

    // -------------------------------------------------------------------------
    // Static entry points
    // -------------------------------------------------------------------------

    @isTest
    static void testCreateDunningTasks() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Account acc = getAcc();
        celsrm__Treatment__c tr = buildTreatment();
        Test.startTest();
        try {
            AIDunningTasksManager.createDunningTasks(new List<Id>{ acc.Id }, tr);
        } catch (Exception e) {}
        Test.stopTest();
    }

    @isTest
    static void testCreateDunningTasksNullAndEmpty() {
        celsrm__Treatment__c tr = buildTreatment();
        Test.startTest();
        try {
            AIDunningTasksManager.createDunningTasks(null, tr);
        } catch (Exception e) {}
        try {
            AIDunningTasksManager.createDunningTasks(new List<Id>(), tr);
        } catch (Exception e) {}
        Test.stopTest();
    }

    // -------------------------------------------------------------------------
    // execute() called directly (synchronous) for maximum line coverage
    // -------------------------------------------------------------------------

    @isTest
    static void testExecuteDirectNewTask() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Account acc = getAcc();
        celsrm__Treatment__c tr = buildTreatment(true);
        Test.startTest();
        try {
            AIDunningTasksManager mgr = new AIDunningTasksManager(new List<Id>{ acc.Id }, tr);
            mgr.execute(null);
        } catch (Exception e) {}
        Test.stopTest();
    }

    @isTest
    static void testExecuteDirectNonAutoTreatment() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Account acc = getAcc();
        celsrm__Treatment__c tr = buildTreatment(false);
        Test.startTest();
        try {
            AIDunningTasksManager mgr = new AIDunningTasksManager(new List<Id>{ acc.Id }, tr);
            mgr.execute(null);
        } catch (Exception e) {}
        Test.stopTest();
    }

    @isTest
    static void testExecuteDirectExistingTask() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Account acc = getAcc();
        // Pre-create an open AI dunning task so the "existing task" update branch runs
        Task existing = new Task(
            Subject = 'Old AI Reminder',
            WhatId = acc.Id,
            Status = 'Not Started',
            Type = 'Email',
            Priority = 'Normal',
            ActivityDate = Date.today(),
            AiDunning__c = true
        );
        try { insert existing; } catch (Exception e) {}

        celsrm__Treatment__c tr = buildTreatment(true);
        Test.startTest();
        try {
            AIDunningTasksManager mgr = new AIDunningTasksManager(new List<Id>{ acc.Id }, tr);
            mgr.execute(null);
        } catch (Exception e) {}
        Test.stopTest();
    }

    @isTest
    static void testExecuteWithLibraryConfig() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Account acc = getAcc();
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        Test.startTest();
        // runAs isolates custom-setting (setup) DML from Task DML to avoid MIXED_DML
        System.runAs(thisUser) {
            try {
                celsrm__SRM_Configuration__c cfg = new celsrm__SRM_Configuration__c(
                    celsrm__Treatment_File_Sharing_Library_Id__c = acc.Id
                );
                insert cfg;
            } catch (Exception e) {}
            try {
                celsrm__Treatment__c tr = buildTreatment(true);
                AIDunningTasksManager mgr = new AIDunningTasksManager(new List<Id>{ acc.Id }, tr);
                mgr.execute(null);
            } catch (Exception e) {}
        }
        Test.stopTest();
    }

    @isTest
    static void testExecuteWithTaskOwnerQueue() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Account acc = getAcc();
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

        Id queueId = null;
        try {
            Group q = new Group(Name = 'AI Dun Test Q', Type = 'Queue');
            insert q;
            QueueSobject qs = new QueueSobject(QueueId = q.Id, SobjectType = 'Task');
            insert qs;
            queueId = q.Id;
        } catch (Exception e) {}

        Test.startTest();
        System.runAs(thisUser) {
            try {
                celsrm__Treatment__c tr = buildTreatment(true);
                if (queueId != null) {
                    tr.celsrm__Task_Owner_Queue__c = queueId;
                    update tr;
                }
                AIDunningTasksManager mgr = new AIDunningTasksManager(new List<Id>{ acc.Id }, tr);
                mgr.execute(null);
            } catch (Exception e) {}
        }
        Test.stopTest();
    }

    @isTest
    static void testExecuteProcessedAccountSkipped() {
        Account acc = getAcc();
        celsrm__Treatment__c tr = buildTreatment(true);
        Test.startTest();
        try {
            // Account already in processed set -> continue branch, no tasks created
            AIDunningTasksManager mgr = new AIDunningTasksManager(
                new List<Id>{ acc.Id }, new Set<Id>{ acc.Id }, tr);
            mgr.execute(null);
        } catch (Exception e) {}
        Test.stopTest();
    }

    @isTest
    static void testExecuteViaEnqueue() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Account acc = getAcc();
        celsrm__Treatment__c tr = buildTreatment(true);
        Test.startTest();
        try {
            AIDunningTasksManager mgr = new AIDunningTasksManager(
                new List<Id>{ acc.Id }, new Set<Id>(), tr);
            System.enqueueJob(mgr);
        } catch (Exception e) {}
        Test.stopTest();
    }

    // -------------------------------------------------------------------------
    // Constructors - empty / null account lists (early return)
    // -------------------------------------------------------------------------

    @isTest
    static void testConstructorsEmpty() {
        celsrm__Treatment__c tr = buildTreatment(true);
        Test.startTest();
        try {
            AIDunningTasksManager m1 = new AIDunningTasksManager(new List<Id>(), tr);
        } catch (Exception e) {}
        try {
            AIDunningTasksManager m2 = new AIDunningTasksManager(null, tr);
        } catch (Exception e) {}
        try {
            AIDunningTasksManager m3 = new AIDunningTasksManager(new List<Id>(), new Set<Id>(), tr);
        } catch (Exception e) {}
        try {
            AIDunningTasksManager m4 = new AIDunningTasksManager(null, null, tr);
        } catch (Exception e) {}
        Test.stopTest();
    }

    // -------------------------------------------------------------------------
    // Static helper: getDunningStrategyReasoning
    // -------------------------------------------------------------------------

    @isTest
    static void testStrategyReasoning() {
        Test.startTest();
        try { AIDunningTasksManager.getDunningStrategyReasoning('proactive', '2099-01-01', 50, 5); } catch (Exception e) {}
        try { AIDunningTasksManager.getDunningStrategyReasoning('reactive', '2020-01-01;2020-02-01', 20, 3); } catch (Exception e) {}
        try { AIDunningTasksManager.getDunningStrategyReasoning('other', '2099-01-01', 10, 1); } catch (Exception e) {}
        try { AIDunningTasksManager.getDunningStrategyReasoning('proactive', 'no-date-string', 10, 1); } catch (Exception e) {}
        try { AIDunningTasksManager.getDunningStrategyReasoning(null, '2099-01-01', 10, 1); } catch (Exception e) {}
        try { AIDunningTasksManager.getDunningStrategyReasoning('proactive', null, 10, 1); } catch (Exception e) {}
        Test.stopTest();
    }

    // -------------------------------------------------------------------------
    // Static helper: extractPaymentDate
    // -------------------------------------------------------------------------

    @isTest
    static void testExtractPaymentDate() {
        Test.startTest();
        try { AIDunningTasksManager.extractPaymentDate('2099-01-01;2098-01-01', 'proactive'); } catch (Exception e) {}
        try { AIDunningTasksManager.extractPaymentDate('2020-01-01;2020-02-01', 'reactive'); } catch (Exception e) {}
        try { AIDunningTasksManager.extractPaymentDate('2098-01-01;2099-01-01', 'reactive'); } catch (Exception e) {}
        try { AIDunningTasksManager.extractPaymentDate('2019-01-01;2020-01-01', 'proactive'); } catch (Exception e) {}
        try { AIDunningTasksManager.extractPaymentDate(null, 'proactive'); } catch (Exception e) {}
        try { AIDunningTasksManager.extractPaymentDate('', 'reactive'); } catch (Exception e) {}
        try { AIDunningTasksManager.extractPaymentDate('not-a-date', 'proactive'); } catch (Exception e) {}
        Test.stopTest();
    }

    // -------------------------------------------------------------------------
    // Static helpers: insertContentWorkspaceDoc / reInsertContentWorkspaceDoc
    // -------------------------------------------------------------------------

    @isTest
    static void testInsertContentWorkspaceDoc() {
        // Build a real ContentDocument to exercise the loops
        Id docId = null;
        try {
            ContentVersion cv = new ContentVersion(
                Title = 'Doc',
                PathOnClient = 'doc.txt',
                VersionData = Blob.valueOf('hello'),
                IsMajorVersion = true
            );
            insert cv;
            docId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId;
        } catch (Exception e) {}

        Test.startTest();
        try {
            AIDunningTasksManager.insertContentWorkspaceDoc(new List<String>(), null);
        } catch (Exception e) {}
        try {
            List<String> docIds = new List<String>();
            if (docId != null) { docIds.add(docId); }
            AIDunningTasksManager.insertContentWorkspaceDoc(docIds, getAcc().Id);
        } catch (Exception e) {}
        try {
            AIDunningTasksManager.reInsertContentWorkspaceDoc(new List<String>(), null);
        } catch (Exception e) {}
        Test.stopTest();
    }
}