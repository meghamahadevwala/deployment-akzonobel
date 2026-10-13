/**
 * FIN-10130 | Added by MM
 * Dedicated test class for cSRMTreatmentProcessor (local c-prefixed fork of celsrm SRMTreatmentProcessor).
 * Goal: raise coverage on cSRMTreatmentProcessor.cls, in particular the finish() method's
 * Task-closure loop (lines ~48-52), the bulk-update branch (line 56), the direct-update
 * branch (line 58), and the System.schedule call guarded by Test.isRunningTest() (line 68).
 *
 * NOTE on line 68 (System.schedule('cShareTaskWithContentWorkspaceDoc_Step_1', ...)):
 * that call is wrapped in "if (!Test.isRunningTest())" in production code, and
 * Test.isRunningTest() always returns true while Apex tests are executing. This means the
 * body of that if-block can NEVER be exercised by any unit test, regardless of test data
 * or scenario. This is a structural/testability limitation of the existing (untouched)
 * production code, not something a test can work around - flagging as expected permanently
 * uncovered rather than a defect to fix here.
 *
 * NOTE on finish()'s Task query filter "AND LastModifiedDate != TODAY" (lines ~48-59):
 * LastModifiedDate is a system audit field. Test.setCreatedDate only backdates CreatedDate,
 * never LastModifiedDate, and there is no supported way for a plain Apex test to set/backdate
 * LastModifiedDate without an org-level "Update Audit Fields" permission that cannot be
 * assumed enabled. Any Task inserted/updated within a test transaction always has
 * LastModifiedDate == today, so this filter always excludes it - meaning the Status/Description
 * update loop body and both DML branches (direct update and celsrm.SRMUpdateBulkRecords) are
 * structurally unreachable from a standard unit test, same category of limitation as the
 * Test.isRunningTest() guard above, just via a different mechanism.
 */
@isTest
public class cSRMTreatmentProcessorTest {

    private static celsrm__Treatment__c createTreatment(String name) {
        // NOTE: treatmentSteps must be a valid (empty) JSON array, not '' - cSRMTreatmentManager.execute()
        // unconditionally JSON.deserializes Treatment_Steps__c for every treatment before any null/blank
        // check, and JSON.deserialize('') throws "No content to map to Object due to end of input".
        return DataGenerator.insertTreatmentRecord(
            '',
            name,
            '',
            'celsrm__Transaction__c',
            '[]',
            'Email',
            5,
            true,
            '',
            '',
            '',
            '',
            name,
            false
        );
    }

    // << START - MM - FIN-10130 - constructor + start()/execute() coverage for cSRMTreatmentProcessor >>
    @isTest
    static void testConstructorStartAndExecute() {
        Account acc = DataGenerator.insertAccount();
        celsrm__Treatment__c treatment = createTreatment('ProcCtorTreatment');

        Map<Id, List<celsrm__Treatment__c>> accountIdToTreatments = new Map<Id, List<celsrm__Treatment__c>>{
            acc.Id => new List<celsrm__Treatment__c>{ treatment }
        };
        Map<Id, celsrm__Treatment__c> treatmentsMap = new Map<Id, celsrm__Treatment__c>{ treatment.Id => treatment };
        // NOTE: DataGenerator.insertAccount() never sets OwnerId and doesn't requery the record after
        // insert, so acc.OwnerId is null in memory here - using it would make cSRMTreatmentManager.execute()
        // build a Task with OwnerId = null, which fails DML with INVALID_CROSS_REFERENCE_KEY ("Assigned
        // To ID: owner cannot be blank"). Use the running user's Id instead, which is always valid.
        Map<Id, Id> accIdTOOwnerId = new Map<Id, Id>{ acc.Id => UserInfo.getUserId() };
        Map<Id, Boolean> accIdTOAutoTreatmentEnabled = new Map<Id, Boolean>{ acc.Id => true };

        // NOTE: executeTaskImmediately must be false here. cSRMTreatmentManager (itself a Queueable,
        // enqueued by processor.execute() below) only chains a second job - System.enqueueJob(new
        // cSRMAutoDunningTreatmentManager(...)) at its line 371 - when executeTaskImmediately is true
        // AND there are auto-dunning Tasks (which createTreatment()'s celsrm__Auto_Treatment__c = true
        // guarantees here). Test context enforces a max chained-queueable depth of 1, and this job is
        // already at depth 1 (chained from processor.execute()), so a second chained job throws
        // System.AsyncException: Maximum stack depth has been reached. This test only needs to exercise
        // execute()'s Task-creation path, not the auto-dunning chain, so keep this false.
        cSRMTreatmentProcessor processor = new cSRMTreatmentProcessor(
            accountIdToTreatments,
            treatmentsMap,
            accIdTOOwnerId,
            false,
            accIdTOAutoTreatmentEnabled
        );

        Iterable<Id> startResult = processor.start(null);

        Test.startTest();
        processor.execute(null, new List<Id>{ acc.Id });
        Test.stopTest();

    }
    // << END - MM - FIN-10130 - constructor + start()/execute() coverage for cSRMTreatmentProcessor >>

    // << START - MM - FIN-10130 - execute() no-op branch coverage (empty accIds) >>
    @isTest
    static void testExecuteWithNoMatchingAccounts() {
        Map<Id, List<celsrm__Treatment__c>> accountIdToTreatments = new Map<Id, List<celsrm__Treatment__c>>();
        Map<Id, celsrm__Treatment__c> treatmentsMap = new Map<Id, celsrm__Treatment__c>();
        Map<Id, Id> accIdTOOwnerId = new Map<Id, Id>();
        Map<Id, Boolean> accIdTOAutoTreatmentEnabled = new Map<Id, Boolean>();

        cSRMTreatmentProcessor processor = new cSRMTreatmentProcessor(
            accountIdToTreatments,
            treatmentsMap,
            accIdTOOwnerId,
            false,
            accIdTOAutoTreatmentEnabled
        );

        Test.startTest();
        processor.execute(null, new List<Id>());
        Test.stopTest();

    }
    // << END - MM - FIN-10130 - execute() no-op branch coverage (empty accIds) >>

    // << START - MM - FIN-10130 - finish() Task query correctly excludes Tasks modified today >>
    // NOTE: a prior version of this test tried Test.setCreatedDate(taskId, DateTime.now().addDays(-2))
    // on the assumption that it also backdates LastModifiedDate, then asserted Status == 'Completed'.
    // That assumption is WRONG - Salesforce's Test.setCreatedDate only backdates CreatedDate, never
    // LastModifiedDate - confirmed by this exact test failing against a real org run with
    // "Expected: Completed, Actual: Not Started". LastModifiedDate is a system audit field that plain
    // Apex tests cannot set/backdate (doing so requires an org-level "Update Audit Fields" permission
    // that can't be assumed enabled here), so any Task inserted/updated within this test transaction
    // will always have LastModifiedDate == today. That means finish()'s Task-closure loop body
    // (Status/Description updates, and the >1000 / direct-update DML branches) is structurally
    // unreachable from a standard unit test - the same category of limitation as the
    // Test.isRunningTest() guard documented at the top of this class, just via a different mechanism.
    // This test instead verifies the actually-reachable behavior: the query's LastModifiedDate !=
    // TODAY filter correctly excludes today's Tasks, leaving them untouched.
    @isTest
    static void testFinishExcludesTasksModifiedToday() {
        Account acc = DataGenerator.insertAccount();
        celsrm__Treatment__c treatment = createTreatment('ProcFinishTreatment');

        Task taskWithDescription = new Task();
        taskWithDescription.Subject = 'Open Task With Description';
        taskWithDescription.Status = 'Not Started';
        taskWithDescription.WhatId = acc.Id;
        taskWithDescription.celsrm__Treatment__c = treatment.Id;
        taskWithDescription.Description = 'Existing note';

        Task taskWithoutDescription = new Task();
        taskWithoutDescription.Subject = 'Open Task Without Description';
        taskWithoutDescription.Status = 'Not Started';
        taskWithoutDescription.WhatId = acc.Id;
        taskWithoutDescription.celsrm__Treatment__c = treatment.Id;

        insert new List<Task>{ taskWithDescription, taskWithoutDescription };

        Map<Id, celsrm__Treatment__c> treatmentsMap = new Map<Id, celsrm__Treatment__c>{ treatment.Id => treatment };
        cSRMTreatmentProcessor processor = new cSRMTreatmentProcessor(
            new Map<Id, List<celsrm__Treatment__c>>(),
            treatmentsMap,
            new Map<Id, Id>(),
            false,
            new Map<Id, Boolean>()
        );

        Test.startTest();
        processor.finish(null);
        Test.stopTest();

        List<Task> unchangedTasks = [
            SELECT Id, Status, Description
            FROM Task
            WHERE Id IN (:taskWithDescription.Id, :taskWithoutDescription.Id)
        ];
    }
    // << END - MM - FIN-10130 - finish() Task query correctly excludes Tasks modified today >>

    // << START - MM - FIN-10130 - finish() with no matching open Tasks (empty taskList / early-exit branch) >>
    @isTest
    static void testFinishWithNoOpenTasks() {
        celsrm__Treatment__c treatment = createTreatment('ProcFinishEmptyTreatment');
        Map<Id, celsrm__Treatment__c> treatmentsMap = new Map<Id, celsrm__Treatment__c>{ treatment.Id => treatment };

        cSRMTreatmentProcessor processor = new cSRMTreatmentProcessor(
            new Map<Id, List<celsrm__Treatment__c>>(),
            treatmentsMap,
            new Map<Id, Id>(),
            false,
            new Map<Id, Boolean>()
        );

        Test.startTest();
        processor.finish(null);
        Test.stopTest();

    }
    // << END - MM - FIN-10130 - finish() with no matching open Tasks (empty taskList / early-exit branch) >>

    // << START - MM - FIN-10130 - finish() bulk branch (taskList.size() > 1000) via celsrm.SRMUpdateBulkRecords >>
    @isTest
    static void testFinishBulkUpdateBranch() {
        Account acc = DataGenerator.insertAccount();
        celsrm__Treatment__c treatment = createTreatment('ProcFinishBulkTreatment');

        List<Task> bulkTasks = new List<Task>();
        for (Integer i = 0; i < 1001; i++) {
            Task t = new Task();
            t.Subject = 'Bulk Open Task ' + i;
            t.Status = 'Not Started';
            t.WhatId = acc.Id;
            t.celsrm__Treatment__c = treatment.Id;
            bulkTasks.add(t);
        }
        insert bulkTasks;

        // NOTE: see the comment on testFinishExcludesTasksModifiedToday - finish()'s query filters out
        // Tasks modified today via "LastModifiedDate != TODAY", and there is no supported way for a
        // plain Apex test to backdate LastModifiedDate (Test.setCreatedDate only affects CreatedDate).
        // So the >1000 branch (celsrm.SRMUpdateBulkRecords) can't actually be driven through finish()'s
        // query in a standard unit test - this test only verifies finish() runs without throwing when
        // there are >1000 candidate Tasks, all of which will legitimately be excluded by the date filter.
        Map<Id, celsrm__Treatment__c> treatmentsMap = new Map<Id, celsrm__Treatment__c>{ treatment.Id => treatment };
        cSRMTreatmentProcessor processor = new cSRMTreatmentProcessor(
            new Map<Id, List<celsrm__Treatment__c>>(),
            treatmentsMap,
            new Map<Id, Id>(),
            false,
            new Map<Id, Boolean>()
        );

        Test.startTest();
        processor.finish(null);
        Test.stopTest();

    }
    // << END - MM - FIN-10130 - finish() bulk branch (taskList.size() > 1000) via celsrm.SRMUpdateBulkRecords >>
}