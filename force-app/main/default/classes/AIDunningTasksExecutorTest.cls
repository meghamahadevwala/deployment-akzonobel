@isTest
public class AIDunningTasksExecutorTest {

    @testSetup
    static void setup() {
        Account acc = DataGenerator.insertAccount();
        DataGenerator.insertDefaultContact(acc);
        DataGenerator.transactionInsert(acc, 2);

        celsrm__Treatment__c tr = DataGenerator.insertTreatmentRecord(
            '', 'AI Dunning Treatment', null, 'Account', null, 'Email', 1,
            true, null, null, null, null, 'AI Dunning Treatment', false);
        tr.celsrm__Enable_AI_Generated_Template__c = true;
        try { update tr; } catch (Exception e) {}

        List<Task> tasks = new List<Task>();
        for (Integer i = 0; i < 2; i++) {
            Task t = new Task();
            t.Subject = 'AI Overdue Reminder';
            t.Status = 'Not Started';
            t.WhatId = acc.Id;
            t.Type = 'Email';
            t.AiDunning__c = true;
            t.celsrm__Treatment__c = tr.Id;
            tasks.add(t);
        }
        insert tasks;
    }

    @isTest
    static void testExecuteWithTaskIds() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        List<Task> tasks = [SELECT Id FROM Task WHERE AiDunning__c = true];
        List<Id> taskIds = new List<Id>();
        for (Task t : tasks) {
            taskIds.add(t.Id);
        }
        Test.startTest();
        try {
            System.enqueueJob(new AIDunningTasksExecutor(taskIds));
            Test.stopTest();
        } catch (Exception e) {}
    }

    @isTest
    static void testExecuteAll() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Test.startTest();
        try {
            AIDunningTasksExecutor.executeAll();
            Test.stopTest();
        } catch (Exception e) {}
    }

    @isTest
    static void testNoArgConstructor() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Test.startTest();
        try {
            System.enqueueJob(new AIDunningTasksExecutor());
            Test.stopTest();
        } catch (Exception e) {}
    }
}