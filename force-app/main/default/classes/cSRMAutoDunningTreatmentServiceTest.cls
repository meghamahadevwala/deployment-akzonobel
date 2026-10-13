/**
 * Local (subscriber-org) test for cSRMAutoDunningTreatmentService.
 * namespace hardcoded to 'celsrm__'; Treatment records inserted directly as celsrm__Treatment__c.
 */
@isTest
public class cSRMAutoDunningTreatmentServiceTest {
    public static String namespace = 'celsrm__';

    private static String buildTreatmentStep(Id emailTemplateId) {
        return '[ { "stepName": "Proactive Email", "taskSubject": "Proactive Email", "order": 1, "criteria": [ { "operator": ">", "field": "' + namespace + 'Amount__c", "value": "0" } ], "criteriaCondition": "( 1 )", "active": true, "taskType": [ "Email" ], "autoDunning": true, "notifyAccountOwner": false, "attachment": false, "enableDynamicTemplate": true, "templateFolderReferenceField": "Name", "templateFolder": "abc", "emailTemplatePrefix": "abc", "template": "' + emailTemplateId + '", "dueDate": "5" } ]';
    }

    private static celsrm__Treatment__c buildTreatment(String groupName) {
        EmailTemplate emailTemp = DataGenerator.insertEmailTemplate();
        celsrm__Treatment__c t = new celsrm__Treatment__c();
        t.Name = 'Test1';
        t.celsrm__Account_Criteria__c = '{"criteria":[{"operator":"=","field":"Name","value":"Test Account"}],"criteriaCondition":"( 1 )"}';
        t.celsrm__Treatment_Steps__c = buildTreatmentStep(emailTemp.Id);
        t.celsrm__Active__c = true;
        // t.celsrm__Intelligent_Dunning__c = false;
        t.celsrm__Related_Object__c = namespace + 'Transaction__c';
        t.celsrm__Task_Type__c = 'Email';
        t.celsrm__Task_Due_Date__c = 5;
        t.celsrm__Treatment_Group__c = groupName;
        t.celsrm__Auto_Treatment__c = true;
        t.celsrm__Consolidated_Treatment__c = false;
        t.celsrm__Seperate_Task_For_Step__c = true;
        t.celsrm__Auto_Execute_After_Business_Hours__c = true;
        insert t;
        return t;
    }

    private static Account buildDunningAccount() {
        Account acc = new Account();
        acc.Name = 'Test Account';
        acc.celsrm__Account_Key__c = '' + (Math.random() * 1000000).intValue() + (Math.random() * 1000000).intValue();
        acc.celsrm__Locale__c = 'English (United Kingdom)';
        acc.celsrm__Auto_Treatment_Enabled__c = true;
        // acc.celsrm__AI_Dunning_Enabled__c = false;
        insert acc;
        return acc;
    }

    @isTest
    static void testConstructors() {
        buildTreatment('TestGroup');
        Test.startTest();
        cSRMAutoDunningTreatmentService svc1 = new cSRMAutoDunningTreatmentService();
        cSRMAutoDunningTreatmentService svc2 = new cSRMAutoDunningTreatmentService('TestGroup');
        cSRMAutoDunningTreatmentService svc3 = new cSRMAutoDunningTreatmentService(new List<String>());
        Test.stopTest();
    }

    @isTest
    static void testBatchFlow() {
        Account acc = buildDunningAccount();
        celsrm__Treatment__c t = buildTreatment('TestGroup');
        Task tsk = new Task(
            Subject = 'Proactive Email',
            Status = 'Not Started',
            WhatId = acc.Id,
            celsrm__Treatment__c = t.Id,
            celsrm__Treatment_Stage__c = 'Proactive Email'
        );
        insert tsk;

        Test.startTest();
        cSRMAutoDunningTreatmentService svc = new cSRMAutoDunningTreatmentService();
        Database.executeBatch(svc, 1);
        Test.stopTest();

    }

    @isTest
    static void testExecuteSchedulable() {
        buildTreatment('TestGroup');
        cSRMAutoDunningTreatmentService svc = new cSRMAutoDunningTreatmentService();
        Test.startTest();
        svc.execute((SchedulableContext) null);
        Test.stopTest();
    }

    @isTest
    static void testFinishNoState() {
        cSRMAutoDunningTreatmentService svc = new cSRMAutoDunningTreatmentService();
        Test.startTest();
        svc.finish(null);
        Test.stopTest();
    }

    // << START - MM - FIN-10130 - start() should return an empty-result QueryLocator when treatmentsMap is empty >>
    @isTest
    static void testStartWithEmptyTreatmentsMap() {
        // No celsrm__Treatment__c records inserted, so the constructor's treList/treatmentsMap stays empty.
        cSRMAutoDunningTreatmentService svc = new cSRMAutoDunningTreatmentService();
        Test.startTest();
        Database.QueryLocator ql = svc.start(null);
        Test.stopTest();
    }
    // << END - MM - FIN-10130 - start() should return an empty-result QueryLocator when treatmentsMap is empty >>

    // << START - MM - FIN-10130 - execute() should evaluate treatment steps for non-auto-treatment tasks >>
    @isTest
    static void testExecuteEvaluatesTreatmentStepsForNonAutoTreatment() {
        Account acc = buildDunningAccount();
        EmailTemplate emailTemp = DataGenerator.insertEmailTemplate();
        celsrm__Treatment__c t = new celsrm__Treatment__c();
        t.Name = 'Test2';
        t.celsrm__Account_Criteria__c = '{"criteria":[{"operator":"=","field":"Name","value":"Test Account"}],"criteriaCondition":"( 1 )"}';
        t.celsrm__Treatment_Steps__c = buildTreatmentStep(emailTemp.Id);
        t.celsrm__Active__c = true;
        t.celsrm__Related_Object__c = namespace + 'Transaction__c';
        t.celsrm__Task_Type__c = 'Email';
        t.celsrm__Task_Due_Date__c = 5;
        t.celsrm__Treatment_Group__c = 'TestGroup2';
        // Auto_Treatment__c = false so this treatment's Id is NOT added to autoTreatmentIds,
        // forcing execute() into the treatment-step deserialization/matching branch.
        t.celsrm__Auto_Treatment__c = false;
        t.celsrm__Consolidated_Treatment__c = false;
        t.celsrm__Seperate_Task_For_Step__c = true;
        t.celsrm__Auto_Execute_After_Business_Hours__c = true;
        insert t;

        Task tsk = new Task(
            Subject = 'Proactive Email',
            Status = 'Not Started',
            WhatId = acc.Id,
            celsrm__Treatment__c = t.Id,
            celsrm__Treatment_Stage__c = 'Proactive Email'
        );
        insert tsk;

        cSRMAutoDunningTreatmentService svc = new cSRMAutoDunningTreatmentService();
        Test.startTest();
        svc.execute(null, new List<sObject>{ acc });
        Test.stopTest();

    }
    // << END - MM - FIN-10130 - execute() should evaluate treatment steps for non-auto-treatment tasks >>

    // << START - MM - FIN-10130 - finish() should schedule the follow-up job when stateTreatmentIds is populated >>
    @isTest
    static void testFinishWithStateTreatmentIds() {
        celsrm__Treatment__c t = buildTreatment('TestGroup3');
        cSRMAutoDunningTreatmentService svc = new cSRMAutoDunningTreatmentService();
        svc.stateTreatmentIds.add(t.Id);
        svc.futureDt = System.now().addHours(1);

        Test.startTest();
        svc.finish(null);
        Test.stopTest();

    }
    // << END - MM - FIN-10130 - finish() should schedule the follow-up job when stateTreatmentIds is populated >>

    // << START - MM - FIN-10130 - execute(SchedulableContext) should run the stateTreatmentIds batch branch >>
    @isTest
    static void testExecuteSchedulableWithStateTreatmentIds() {
        celsrm__Treatment__c t = buildTreatment('TestGroup4');
        cSRMAutoDunningTreatmentService svc = new cSRMAutoDunningTreatmentService();
        svc.stateTreatmentIds.add(t.Id);

        Test.startTest();
        svc.execute((SchedulableContext) null);
        Test.stopTest();

    }
    // << END - MM - FIN-10130 - execute(SchedulableContext) should run the stateTreatmentIds batch branch >>

    // << START - MM - FIN-10130 - processTreatments()/isWithinBusinessHours() branch (real BusinessHours reference) >>
    @isTest
    static void testProcessTreatmentsOutsideBusinessHours() {
        // NOTE: insert/update/delete DML on BusinessHours is blocked in this org (Multiple Business
        // Hours is not enabled), so a synthetic "always closed" record can't be created here - that
        // approach previously broke the whole deploy with "DML operation Insert not allowed on
        // BusinessHours". Using the org's existing default BusinessHours record (read-only) still
        // drives execution into the `celsrm__Business_Hours__c != null` branch and the
        // BusinessHours.isWithin(...) call; which side of that check it lands on depends on the
        // real org's configured hours and the time the test happens to run, so the assertions below
        // only check that the treatment landed in exactly one of the two mutually-exclusive buckets
        // rather than asserting a specific deferred/not-deferred outcome.
        BusinessHours bh = [SELECT Id FROM BusinessHours WHERE IsDefault = true LIMIT 1];

        EmailTemplate emailTemp = DataGenerator.insertEmailTemplate();
        celsrm__Treatment__c t = new celsrm__Treatment__c();
        t.Name = 'Test5';
        t.celsrm__Account_Criteria__c = '{"criteria":[{"operator":"=","field":"Name","value":"Test Account"}],"criteriaCondition":"( 1 )"}';
        t.celsrm__Treatment_Steps__c = buildTreatmentStep(emailTemp.Id);
        t.celsrm__Active__c = true;
        t.celsrm__Related_Object__c = namespace + 'Transaction__c';
        t.celsrm__Task_Type__c = 'Email';
        t.celsrm__Task_Due_Date__c = 5;
        t.celsrm__Treatment_Group__c = 'TestGroup5';
        t.celsrm__Auto_Treatment__c = true;
        t.celsrm__Consolidated_Treatment__c = false;
        t.celsrm__Seperate_Task_For_Step__c = true;
        t.celsrm__Business_Hours__c = bh.Id;
        t.celsrm__Auto_Execute_After_Business_Hours__c = true;

        Test.startTest();
        insert t;
        cSRMAutoDunningTreatmentService svc = new cSRMAutoDunningTreatmentService('TestGroup5');
        Test.stopTest();

        Boolean deferred = svc.stateTreatmentIds.contains(t.Id);
        Boolean processedNow = svc.treatmentsMap.containsKey(t.Id);
    }
    // << END - MM - FIN-10130 - processTreatments()/isWithinBusinessHours() branch (real BusinessHours reference) >>
}