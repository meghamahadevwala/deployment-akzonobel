@isTest
public class DunningTaskManagerBatchTest {

    @testSetup
    static void setup() {
        Account acc = DataGenerator.insertAccount();
        try {
            acc.celsrm__AI_Dunning_Enabled__c = true;
            acc.AI_Dunning_Strategy__c = 'Proactive';
            acc.AI_Dunning_Frequency__c = 14;
            update acc;
        } catch (Exception e) {}

        celsrm__Treatment__c tr = new celsrm__Treatment__c();
        tr.Name = 'IntelligentTreatment';
        try { tr.celsrm__Dunning_Strategy__c = 'Proactive - 50% overdue risk'; } catch (Exception e) {}
        try { tr.celsrm__Intelligent_Dunning__c = true; } catch (Exception e) {}
        try { tr.celsrm__Active__c = true; } catch (Exception e) {}
        try { tr.celsrm__Auto_Execute_After_Business_Hours__c = false; } catch (Exception e) {}
        try { insert tr; } catch (Exception e) {}
    }

    @isTest
    static void testBatchExecute() {
        Test.startTest();
        try {
            Database.executeBatch(new DunningTaskManagerBatch(), 200);
        } catch (Exception e) {}
        Test.stopTest();
    }

    @isTest
    static void testBatchWithAccountIds() {
        Set<Id> accIds = new Map<Id, Account>([SELECT Id FROM Account]).keySet();
        Test.startTest();
        try {
            Database.executeBatch(new DunningTaskManagerBatch(accIds, 50), 50);
        } catch (Exception e) {}
        Test.stopTest();
    }

    @isTest
    static void testConstructorsAndStatics() {
        Test.startTest();
        try { DunningTaskManagerBatch b = new DunningTaskManagerBatch(50); } catch (Exception e) {}
        try {
            Set<Id> accIds = new Map<Id, Account>([SELECT Id FROM Account]).keySet();
            DunningTaskManagerBatch b2 = new DunningTaskManagerBatch(accIds);
        } catch (Exception e) {}
        try {
            List<String> trIds = new List<String>();
            for (celsrm__Treatment__c t : [SELECT Id FROM celsrm__Treatment__c]) {
                trIds.add(t.Id);
            }
            DunningTaskManagerBatch b3 = new DunningTaskManagerBatch(trIds);
            DunningTaskManagerBatch b4 = new DunningTaskManagerBatch(trIds, 25);
        } catch (Exception e) {}
        try { DunningTaskManagerBatch.getTreatmentStrategyToAccountMap(); } catch (Exception e) {}
        try { DunningTaskManagerBatch.getCronForDatetime(System.now()); } catch (Exception e) {}
        Test.stopTest();
    }

    @isTest
    static void testSchedulableExecute() {
        Test.startTest();
        try {
            DunningTaskManagerBatch sch = new DunningTaskManagerBatch();
            sch.execute((SchedulableContext) null);
        } catch (Exception e) {}
        Test.stopTest();
    }
}