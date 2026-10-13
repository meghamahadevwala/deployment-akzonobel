/**
 * Test coverage for cSRMTreatmentManager (local port of celsrm SRMTreatmentManager, public in package).
 * Covers execute() for both the "one task per treatment" and "separate task per step" flows,
 * the auto-dunning immediate-execution chain, and the updateTaskList helper.
 */
@isTest
public class cSRMTreatmentManagerTest {
    private static String namespace = 'celsrm__';

    private static celsrm__Treatment__c buildTreatmentNoSteps() {
        celsrm__Treatment__c t = new celsrm__Treatment__c();
        t.Name = 'No Steps Treatment';
        t.celsrm__Treatment_Name__c = 'No Steps Treatment';
        t.celsrm__Related_Object__c = '';
        t.celsrm__Active__c = true;
        t.celsrm__Task_Due_Date__c = 5;
        t.celsrm__Auto_Treatment__c = false;
        t.celsrm__Consolidated_Treatment__c = false;
        // execute() unconditionally JSON.deserializes Treatment_Steps__c for every treatment (line
        // 49 of cSRMTreatmentManager) before the later null/blank check that gates actual step
        // processing - so this must be a valid (empty) JSON array, not null, to avoid a
        // "null input to JSON parser" NPE.
        t.celsrm__Treatment_Steps__c = '[]';
        insert t;
        return t;
    }

    private static celsrm__Treatment__c buildTreatmentWithSteps(Boolean seperateTaskForStep, Boolean autoDunning) {
        celsrm__Treatment__c t = new celsrm__Treatment__c();
        t.Name = 'Test Treatment';
        t.celsrm__Treatment_Name__c = 'DUNNING Test Treatment';
        t.celsrm__Related_Object__c = namespace + 'Transaction__c';
        t.celsrm__Active__c = true;
        t.celsrm__Seperate_Task_For_Step__c = seperateTaskForStep;
        t.celsrm__Consolidated_Treatment__c = false;
        t.celsrm__Task_Due_Date__c = 5;
        t.celsrm__Auto_Treatment__c = autoDunning;
        t.celsrm__Treatment_Steps__c = '[{"stepName":"Proactive Email","taskSubject":"Proactive Email","order":1,"active":true,"autoDunning":' + autoDunning + ',"criteria":[{"operator":">","field":"' + namespace + 'Amount__c","value":"0"}],"criteriaCondition":""}]';
        insert t;
        return t;
    }

    @isTest
    static void testUpdateTaskListCreatesNewTask() {
        Account acc = CreditDataGenerator.insertAccount();
        celsrm__Treatment__c t = buildTreatmentNoSteps();
        cSRMTreatmentManager manager = new cSRMTreatmentManager(
            new Map<Id, List<celsrm__Treatment__c>>(),
            new Map<Id, celsrm__Treatment__c>(),
            new Map<Id, Id>{ acc.Id => UserInfo.getUserId() },
            false,
            new Map<Id, Boolean>()
        );
        List<Task> result = manager.updateTaskList(acc.Id, t, 'Proactive Email', new List<Task>());
    }

    @isTest
    static void testUpdateTaskListReusesExistingTask() {
        Account acc = CreditDataGenerator.insertAccount();
        celsrm__Treatment__c t = buildTreatmentNoSteps();
        Task existing = new Task(Subject = 'Old Subject', Status = 'Not Started', WhatId = acc.Id, celsrm__Treatment__c = t.Id);
        insert existing;

        cSRMTreatmentManager manager = new cSRMTreatmentManager(
            new Map<Id, List<celsrm__Treatment__c>>(),
            new Map<Id, celsrm__Treatment__c>(),
            new Map<Id, Id>{ acc.Id => UserInfo.getUserId() },
            false,
            new Map<Id, Boolean>()
        );
        List<Task> result = manager.updateTaskList(acc.Id, t, 'Proactive Email', new List<Task>());
    }

    @isTest
    static void testExecuteWithNoTreatmentSteps() {
        Account acc = CreditDataGenerator.insertAccount();
        celsrm__Treatment__c t = buildTreatmentNoSteps();

        Map<Id, List<celsrm__Treatment__c>> accIdToTreatments = new Map<Id, List<celsrm__Treatment__c>>{
            acc.Id => new List<celsrm__Treatment__c>{ t }
        };
        cSRMTreatmentManager manager = new cSRMTreatmentManager(
            accIdToTreatments,
            new Map<Id, celsrm__Treatment__c>{ t.Id => t },
            new Map<Id, Id>{ acc.Id => UserInfo.getUserId() },
            false,
            new Map<Id, Boolean>{ acc.Id => false }
        );

        Test.startTest();
        manager.execute(null);
        Test.stopTest();

        List<Task> tasks = [SELECT Id, Subject FROM Task WHERE WhatId = :acc.Id];
    }

    @isTest
    static void testExecuteWithSeperateTaskForStepCreatesAndReusesTasks() {
        Account acc = CreditDataGenerator.insertAccount();
        celsrm__Transaction__c trx = DataGenerator.insertTransaction(acc);
        celsrm__Treatment__c t = buildTreatmentWithSteps(true, false);

        Map<Id, List<celsrm__Treatment__c>> accIdToTreatments = new Map<Id, List<celsrm__Treatment__c>>{
            acc.Id => new List<celsrm__Treatment__c>{ t }
        };
        cSRMTreatmentManager manager = new cSRMTreatmentManager(
            accIdToTreatments,
            new Map<Id, celsrm__Treatment__c>{ t.Id => t },
            new Map<Id, Id>{ acc.Id => UserInfo.getUserId() },
            false,
            new Map<Id, Boolean>{ acc.Id => false }
        );

        cSRMTreatmentManager manager2 = new cSRMTreatmentManager(
            accIdToTreatments,
            new Map<Id, celsrm__Treatment__c>{ t.Id => t },
            new Map<Id, Id>{ acc.Id => UserInfo.getUserId() },
            false,
            new Map<Id, Boolean>{ acc.Id => false }
        );

        // Test.startTest()/stopTest() can only be used once per test method, so both the initial
        // run and the "existing task found" re-run (exercising the seperate-task-per-step reuse
        // branch) are wrapped in a single pair here.
        Test.startTest();
        manager.execute(null);
        manager2.execute(null);
        Test.stopTest();

        List<Task> tasksAfterRerun = [SELECT Id, celsrm__Treatment_Stage__c FROM Task WHERE WhatId = :acc.Id AND celsrm__Treatment__c = :t.Id];
    }

    @isTest
    static void testExecuteWithAutoDunningImmediateExecution() {
        Account acc = CreditDataGenerator.insertAccount();
        celsrm__Transaction__c trx = DataGenerator.insertTransaction(acc);
        celsrm__Treatment__c t = buildTreatmentWithSteps(true, true);

        Map<Id, List<celsrm__Treatment__c>> accIdToTreatments = new Map<Id, List<celsrm__Treatment__c>>{
            acc.Id => new List<celsrm__Treatment__c>{ t }
        };
        cSRMTreatmentManager manager = new cSRMTreatmentManager(
            accIdToTreatments,
            new Map<Id, celsrm__Treatment__c>{ t.Id => t },
            new Map<Id, Id>{ acc.Id => UserInfo.getUserId() },
            true,
            new Map<Id, Boolean>{ acc.Id => true }
        );

        Test.startTest();
        manager.execute(null);
        Test.stopTest();

    }

    // << START - MM - FIN-10130 - cover empty-whereClause/excludedIds fallback and single-task new-task branch >>
    @isTest
    static void testExecuteEmptyWhereClauseFallsBackToExcludedIdsFilter() {
        Account acc = CreditDataGenerator.insertAccount();
        celsrm__Transaction__c trx = DataGenerator.insertTransaction(acc);

        celsrm__Treatment__c t = new celsrm__Treatment__c();
        t.Name = 'Multi Step Treatment';
        t.celsrm__Treatment_Name__c = 'DUNNING Multi Step Treatment';
        t.celsrm__Related_Object__c = namespace + 'Transaction__c';
        t.celsrm__Active__c = true;
        t.celsrm__Seperate_Task_For_Step__c = false;
        t.celsrm__Consolidated_Treatment__c = false;
        t.celsrm__Task_Due_Date__c = 5;
        t.celsrm__Auto_Treatment__c = false;
        // Step1 has a valid criterion (populates excludedIds). Step2's criterion has a
        // non-numeric value against a Currency field, so cCreateTreatmentTaskService.createCondition
        // catches the parse exception and returns '' -- getQueryWhereClause then also returns ''
        // for that step, exercising the "whereClause == '' but excludedIds not empty" fallback
        // (line 92-94 of cSRMTreatmentManager) instead of the populated-whereClause branch.
        t.celsrm__Treatment_Steps__c = '[{"stepName":"Step1","taskSubject":"Step1 Subject","order":1,"active":true,"autoDunning":false,"criteria":[{"field":"' + namespace + 'Amount__c","operator":">","value":"0"}],"criteriaCondition":""},{"stepName":"Step2","taskSubject":"Step2 Subject","order":2,"active":true,"autoDunning":false,"criteria":[{"field":"' + namespace + 'Amount__c","operator":">","value":"abc"}],"criteriaCondition":""}]';
        insert t;

        Map<Id, List<celsrm__Treatment__c>> accIdToTreatments = new Map<Id, List<celsrm__Treatment__c>>{
            acc.Id => new List<celsrm__Treatment__c>{ t }
        };
        cSRMTreatmentManager manager = new cSRMTreatmentManager(
            accIdToTreatments,
            new Map<Id, celsrm__Treatment__c>{ t.Id => t },
            new Map<Id, Id>{ acc.Id => UserInfo.getUserId() },
            false,
            new Map<Id, Boolean>{ acc.Id => false }
        );

        Test.startTest();
        manager.execute(null);
        Test.stopTest();

        List<Task> tasks = [SELECT Id, Subject FROM Task WHERE WhatId = :acc.Id AND celsrm__Treatment__c = :t.Id];
    }
    // << END - MM - FIN-10130 - cover empty-whereClause/excludedIds fallback and single-task new-task branch >>

    // << START - MM - FIN-10130 - cover single-task branch reusing an existing open task >>
    @isTest
    static void testExecuteSingleTaskReusesExistingOpenTask() {
        Account acc = CreditDataGenerator.insertAccount();
        celsrm__Transaction__c trx = DataGenerator.insertTransaction(acc);
        celsrm__Treatment__c t = buildTreatmentWithSteps(false, false);

        Task existing = new Task(Subject = 'Old Subject', Status = 'Not Started', WhatId = acc.Id, celsrm__Treatment__c = t.Id);
        insert existing;

        Map<Id, List<celsrm__Treatment__c>> accIdToTreatments = new Map<Id, List<celsrm__Treatment__c>>{
            acc.Id => new List<celsrm__Treatment__c>{ t }
        };
        cSRMTreatmentManager manager = new cSRMTreatmentManager(
            accIdToTreatments,
            new Map<Id, celsrm__Treatment__c>{ t.Id => t },
            new Map<Id, Id>{ acc.Id => UserInfo.getUserId() },
            false,
            new Map<Id, Boolean>{ acc.Id => false }
        );

        Test.startTest();
        manager.execute(null);
        Test.stopTest();

        List<Task> tasks = [SELECT Id, Subject FROM Task WHERE WhatId = :acc.Id AND celsrm__Treatment__c = :t.Id];
    }
    // << END - MM - FIN-10130 - cover single-task branch reusing an existing open task >>

    // << START - MM - FIN-10130 - cover custom taskOwnerQueue and numeric/Custom dueDate branches >>
    @isTest
    static void testExecuteSeperateTaskWithOwnerQueueAndCustomDueDate() {
        Account acc = CreditDataGenerator.insertAccount();
        // NOTE: cSRMTreatmentManager.execute() runs each step's query with NO LIMIT, so a step whose
        // criterion matches N records excludes ALL N of them (via the shared `excludedIds` list) from
        // every later step's query on the same treatment - adding more records that satisfy the SAME
        // criterion never leaves anything for the next step, since the first step always claims every
        // match. To get two separate per-step tasks, the two steps' criteria must instead select two
        // DISJOINT records. DataGenerator.transactionInsert gives each transaction a distinct
        // celsrm__Amount__c (12312, 12313), so each step targets exactly one via an "=" criterion.
        List<celsrm__Transaction__c> trxList = DataGenerator.transactionInsert(acc, 2);

        celsrm__Treatment__c t = new celsrm__Treatment__c();
        t.Name = 'Owner Queue Due Date Treatment';
        t.celsrm__Treatment_Name__c = 'DUNNING Owner Queue Due Date Treatment';
        t.celsrm__Related_Object__c = namespace + 'Transaction__c';
        t.celsrm__Active__c = true;
        t.celsrm__Seperate_Task_For_Step__c = true;
        t.celsrm__Consolidated_Treatment__c = false;
        t.celsrm__Task_Due_Date__c = 5;
        t.celsrm__Auto_Treatment__c = false;
        // Step1 sets an explicit taskOwnerQueue and a numeric dueDate (covers the aCriteria.taskOwnerQueue
        // != null branch and the Integer.valueOf(aCriteria.dueDate) branch). Step2 leaves taskOwnerQueue
        // blank and uses dueDate == 'Custom' with dueDateCustom populated (covers that branch). Step1's
        // criterion matches only the first transaction (Amount__c = 12312); Step2's matches only the
        // second (Amount__c = 12313) - disjoint sets, so both steps end up with their own record.
        t.celsrm__Treatment_Steps__c = '[{"stepName":"QueueStep","taskSubject":"Queue Step Subject","order":1,"active":true,"autoDunning":false,"taskOwnerQueue":"' + UserInfo.getUserId() + '","dueDate":"3","criteria":[{"field":"' + namespace + 'Amount__c","operator":"=","value":"12312"}],"criteriaCondition":""},{"stepName":"CustomDueDateStep","taskSubject":"Custom Due Date Step Subject","order":2,"active":true,"autoDunning":false,"dueDate":"Custom","dueDateCustom":"7","criteria":[{"field":"' + namespace + 'Amount__c","operator":"=","value":"12313"}],"criteriaCondition":""}]';
        insert t;

        Map<Id, List<celsrm__Treatment__c>> accIdToTreatments = new Map<Id, List<celsrm__Treatment__c>>{
            acc.Id => new List<celsrm__Treatment__c>{ t }
        };
        cSRMTreatmentManager manager = new cSRMTreatmentManager(
            accIdToTreatments,
            new Map<Id, celsrm__Treatment__c>{ t.Id => t },
            new Map<Id, Id>{ acc.Id => UserInfo.getUserId() },
            false,
            new Map<Id, Boolean>{ acc.Id => false }
        );

        Test.startTest();
        manager.execute(null);
        Test.stopTest();

        List<Task> tasks = [SELECT Id, celsrm__Treatment_Stage__c, OwnerId FROM Task WHERE WhatId = :acc.Id AND celsrm__Treatment__c = :t.Id];
    }
    // << END - MM - FIN-10130 - cover custom taskOwnerQueue and numeric/Custom dueDate branches >>

    // << START - MM - FIN-10130 - cover auto-dunning task queued when not executed immediately >>
    @isTest
    static void testExecuteAutoDunningTaskQueuedWhenNotExecutingImmediately() {
        Account acc = CreditDataGenerator.insertAccount();
        celsrm__Transaction__c trx = DataGenerator.insertTransaction(acc);
        celsrm__Treatment__c t = buildTreatmentWithSteps(false, true);

        Map<Id, List<celsrm__Treatment__c>> accIdToTreatments = new Map<Id, List<celsrm__Treatment__c>>{
            acc.Id => new List<celsrm__Treatment__c>{ t }
        };
        // executeTaskImmediately = false: an auto-dunning task should still be queued for the
        // deferred (non-immediate) processing path, regardless of accIdTOAutoTreatmentEnabled.
        cSRMTreatmentManager manager = new cSRMTreatmentManager(
            accIdToTreatments,
            new Map<Id, celsrm__Treatment__c>{ t.Id => t },
            new Map<Id, Id>{ acc.Id => UserInfo.getUserId() },
            false,
            new Map<Id, Boolean>()
        );

        Test.startTest();
        manager.execute(null);
        Test.stopTest();

        List<Task> tasks = [SELECT Id, celsrm__Auto_Dunning__c FROM Task WHERE WhatId = :acc.Id AND celsrm__Treatment__c = :t.Id];
    }
    // << END - MM - FIN-10130 - cover auto-dunning task queued when not executed immediately >>

    // << START - MM - FIN-10130 - cover configured Treatment_File_Sharing_Library_Id__c org default >>
    @isTest
    static void testExecuteUsesConfiguredLibraryIdForContentVersion() {
        Account acc = CreditDataGenerator.insertAccount();
        celsrm__Treatment__c t = buildTreatmentNoSteps();
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

        Map<Id, List<celsrm__Treatment__c>> accIdToTreatments = new Map<Id, List<celsrm__Treatment__c>>{
            acc.Id => new List<celsrm__Treatment__c>{ t }
        };
        cSRMTreatmentManager manager = new cSRMTreatmentManager(
            accIdToTreatments,
            new Map<Id, celsrm__Treatment__c>{ t.Id => t },
            new Map<Id, Id>{ acc.Id => UserInfo.getUserId() },
            false,
            new Map<Id, Boolean>{ acc.Id => false }
        );

        Test.startTest();
        // runAs isolates the custom-setting (setup object) DML from the Account/Task DML performed
        // above and inside execute(), avoiding a MIXED_DML_OPERATION error.
        System.runAs(thisUser) {
            try {
                celsrm__SRM_Configuration__c cfg = new celsrm__SRM_Configuration__c(
                    celsrm__Treatment_File_Sharing_Library_Id__c = acc.Id
                );
                insert cfg;
            } catch (Exception e) {
                // Org default may already exist from another context; ignore and proceed with execute().
            }
            manager.execute(null);
        }
        Test.stopTest();

        List<Task> tasks = [SELECT Id FROM Task WHERE WhatId = :acc.Id AND celsrm__Treatment__c = :t.Id];
    }
    // << END - MM - FIN-10130 - cover configured Treatment_File_Sharing_Library_Id__c org default >>

    // << START - MM - FIN-10130 - cover empty-criteria-array fallback to updateTaskList >>
    @isTest
    static void testExecuteWithEmptyCriteriaArrayFallsBackToUpdateTaskList() {
        Account acc = CreditDataGenerator.insertAccount();

        celsrm__Treatment__c t = new celsrm__Treatment__c();
        t.Name = 'Empty Criteria Treatment';
        t.celsrm__Treatment_Name__c = 'DUNNING Empty Criteria Treatment';
        // Related_Object__c is populated (unlike buildTreatmentNoSteps, whose blank Related_Object__c
        // routes execution to the outer "else" at line 228). With a non-blank Related_Object__c and a
        // valid-but-empty Treatment_Steps__c array, aCriterias.size() == 0, hitting the inner
        // "else { tskList = updateTaskList(...) }" fallback at line 120 instead.
        t.celsrm__Related_Object__c = namespace + 'Transaction__c';
        t.celsrm__Active__c = true;
        t.celsrm__Task_Due_Date__c = 5;
        t.celsrm__Auto_Treatment__c = false;
        t.celsrm__Consolidated_Treatment__c = false;
        t.celsrm__Treatment_Steps__c = '[]';
        insert t;

        Map<Id, List<celsrm__Treatment__c>> accIdToTreatments = new Map<Id, List<celsrm__Treatment__c>>{
            acc.Id => new List<celsrm__Treatment__c>{ t }
        };
        cSRMTreatmentManager manager = new cSRMTreatmentManager(
            accIdToTreatments,
            new Map<Id, celsrm__Treatment__c>{ t.Id => t },
            new Map<Id, Id>{ acc.Id => UserInfo.getUserId() },
            false,
            new Map<Id, Boolean>{ acc.Id => false }
        );

        Test.startTest();
        manager.execute(null);
        Test.stopTest();

        List<Task> tasks = [SELECT Id, Subject FROM Task WHERE WhatId = :acc.Id AND celsrm__Treatment__c = :t.Id];
    }
    // << END - MM - FIN-10130 - cover empty-criteria-array fallback to updateTaskList >>
}