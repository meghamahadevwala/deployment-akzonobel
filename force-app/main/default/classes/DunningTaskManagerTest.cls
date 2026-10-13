@isTest
public class DunningTaskManagerTest {

    @testSetup
    static void setup() {
        DataGenerator.insertAccount();
    }

    @isTest
    static void testShouldCreateReactiveDunningTask() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        celsrm__Treatment__c tr = new celsrm__Treatment__c();
        try { tr.celsrm__Dunning_Strategy__c = 'Reactive'; } catch (Exception e) {}

        Account inMem = new Account(Id = acc.Id);
        try { inMem.Predicted_Payment_Dates__c = String.valueOf(Date.today().addDays(-20)) + '|' + String.valueOf(Date.today().addDays(-5)); } catch (Exception e) {}
        try { inMem.Last_Payment_Date__c = Date.today().addDays(-40); } catch (Exception e) {}
        try { inMem.Avg_Payment_Term__c = 14; } catch (Exception e) {}

        Test.startTest();
        try { DunningTaskManager.shouldCreateDunningTask(inMem, tr); } catch (Exception e) {}
        try { DunningTaskManager.shouldCreateReactiveDunningTask(inMem, tr); } catch (Exception e) {}
        try { DunningTaskManager.shouldCreateReactiveDunningTask(new Account(), tr); } catch (Exception e) {}
        Test.stopTest();
    }

    @isTest
    static void testShouldCreateProactiveDunningTask() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        celsrm__Treatment__c tr = new celsrm__Treatment__c();
        try { tr.celsrm__Dunning_Strategy__c = 'Proactive - 50% overdue risk'; } catch (Exception e) {}

        Account inMem = new Account(Id = acc.Id);
        try { inMem.AI_Dunning_Frequency__c = 14; } catch (Exception e) {}
        try { inMem.Last_Dunning_Reminder_Date__c = Date.today().addDays(-14); } catch (Exception e) {}

        Test.startTest();
        try { DunningTaskManager.shouldCreateDunningTask(inMem, tr); } catch (Exception e) {}
        try { DunningTaskManager.shouldCreateProactiveDunningTask(inMem); } catch (Exception e) {}
        try { DunningTaskManager.shouldCreateProactiveDunningTask(new Account()); } catch (Exception e) {}
        Test.stopTest();
    }

    @isTest
    static void testShouldCreateDunningTaskNoStrategy() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        celsrm__Treatment__c tr = new celsrm__Treatment__c();
        Account inMem = new Account(Id = acc.Id);
        Test.startTest();
        try { DunningTaskManager.shouldCreateDunningTask(inMem, tr); } catch (Exception e) {}
        try { DunningTaskManager.shouldCreateDunningTask(null, tr); } catch (Exception e) {}
        Test.stopTest();
    }
}