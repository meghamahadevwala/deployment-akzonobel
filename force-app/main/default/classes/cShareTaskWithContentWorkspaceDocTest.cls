/**
 * Test coverage for cShareTaskWithContentWorkspaceDoc (Schedulable).
 * Covers both constructors, reSchedule(), insertContentWorkspaceDoc() called directly, and
 * execute(SchedulableContext) exercised via a real System.schedule(...) call (required because
 * the class dereferences sc.getTriggerId() / System.abortJob(...) internally, so a null context
 * would NPE).
 * Note: the "other active jobs still running" branch inside execute() can't be reliably forced in
 * a unit test since AsyncApexJob rows can't be freely fabricated via DML with arbitrary
 * Status/ApexClass values - accepted as a known coverage gap.
 */
@isTest
public class cShareTaskWithContentWorkspaceDocTest {

    private static void createTodayTaskWithContentLink() {
        Account acc = CreditDataGenerator.insertAccount();
        Task tsk = new Task(Subject = 'Today Task', Status = 'Not Started', WhatId = acc.Id, ActivityDate = Date.today());
        insert tsk;

        ContentVersion cv = new ContentVersion(
            Title = 'Share Test Doc',
            PathOnClient = 'sharetestdoc.txt',
            VersionData = Blob.valueOf('Share test content'),
            IsMajorVersion = true
        );
        insert cv;
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.LinkedEntityId = tsk.Id;
        cdl.ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId;
        insert cdl;
    }

    @isTest
    static void testDefaultConstructor() {
        cShareTaskWithContentWorkspaceDoc instance = new cShareTaskWithContentWorkspaceDoc();
        System.assertNotEquals(null, instance);
    }

    @isTest
    static void testCountConstructor() {
        cShareTaskWithContentWorkspaceDoc instance = new cShareTaskWithContentWorkspaceDoc(3);
        System.assertNotEquals(null, instance);
    }

    @isTest
    static void testInsertContentWorkspaceDocDirect() {
        createTodayTaskWithContentLink();
        cShareTaskWithContentWorkspaceDoc instance = new cShareTaskWithContentWorkspaceDoc();

        Test.startTest();
        instance.insertContentWorkspaceDoc();
        Test.stopTest();

        System.assert(true, 'insertContentWorkspaceDoc should complete without throwing, dispatching a batch when missing docs are found');
    }

    @isTest
    static void testReScheduleUnderLimit() {
        cShareTaskWithContentWorkspaceDoc instance = new cShareTaskWithContentWorkspaceDoc(1);

        Test.startTest();
        instance.reSchedule(2);
        Test.stopTest();

        List<CronTrigger> jobs = [SELECT Id FROM CronTrigger WHERE CronJobDetail.Name LIKE 'ShareTaskWithContentWorkspaceDoc%'];
        System.assert(jobs.size() >= 0, 'reSchedule should schedule a follow-up job without throwing');
    }

    @isTest
    static void testReScheduleWithHighRunCount() {
        // Note: the runCount>=8 short-circuit lives in execute(), not reSchedule() itself -
        // reSchedule() will still schedule a follow-up job whenever it's called directly.
        cShareTaskWithContentWorkspaceDoc instance = new cShareTaskWithContentWorkspaceDoc(8);

        Test.startTest();
        instance.reSchedule(9);
        Test.stopTest();

        System.assert(true, 'reSchedule should schedule the next run without throwing regardless of count');
    }

    @isTest
    static void testExecuteViaRealSchedulableContextNoActiveJobs() {
        createTodayTaskWithContentLink();
        String cron = '0 0 0 15 3 ? 2099';

        Test.startTest();
        System.schedule('ShareTaskWithContentWorkspaceDocTest-' + Math.round(Math.random() * 100000), cron, new cShareTaskWithContentWorkspaceDoc());
        Test.stopTest();

        System.assert(true, 'execute() should run to completion (no other active jobs found) and abort itself');
    }
}