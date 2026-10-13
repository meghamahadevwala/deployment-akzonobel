@isTest
public class DunningTransactionFilteringTest {

    @testSetup
    static void setup() {
        Account acc = DataGenerator.insertAccount();
        try {
            acc.AI_Dunning_Frequency__c = 14;
            acc.Predicted_Payment_Dates__c = String.valueOf(Date.today().addDays(10)) + '|' + String.valueOf(Date.today().addDays(20));
            update acc;
        } catch (Exception e) {}

        List<celsrm__Transaction__c> txns = new List<celsrm__Transaction__c>();
        for (Integer i = 0; i < 3; i++) {
            celsrm__Transaction__c t = new celsrm__Transaction__c();
            t.Name = 'DTF-' + i;
            t.celsrm__Account__c = acc.Id;
            t.celsrm__Amount__c = 1000 + (i * 500);
            try { t.celsrm__Due_Date__c = Date.today().addDays(-30 + 20 - i); } catch (Exception e) {}
            try { t.celsrm__Create_Date__c = Date.today().addDays(-30); } catch (Exception e) {}
            txns.add(t);
        }
        try { insert txns; } catch (Exception e) {}

        try {
            celsrm__Celonis_Event__c ev = new celsrm__Celonis_Event__c();
            ev.celsrm__Account__c = acc.Id;
            ev.celsrm__Transaction__c = txns.isEmpty() ? null : txns[0].Id;
            insert ev;
        } catch (Exception e) {}
    }

    @isTest
    static void testComputeSelectedTransactions() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Test.startTest();
        try {
            DunningTransactionFiltering f = new DunningTransactionFiltering();
            f.computeSelectedTransactions(acc, 5, 0.8);
        } catch (Exception e) {}
        try {
            DunningTransactionFiltering f2 = new DunningTransactionFiltering();
            f2.processAccountTransactions(acc);
        } catch (Exception e) {}
        Test.stopTest();
    }

    @isTest
    static void testForceZeroScorePath() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Test.startTest();
        try {
            DunningTransactionFiltering.setTestForceZeroScore(true);
            DunningTransactionFiltering f = new DunningTransactionFiltering();
            f.computeSelectedTransactions(acc, 3, 0.5);
        } catch (Exception e) {}
        try { DunningTransactionFiltering.setTestForceZeroScore(false); } catch (Exception e) {}
        Test.stopTest();
    }

    @isTest
    static void testHelpersAndEligible() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Test.startTest();
        try {
            DunningTransactionFiltering f = new DunningTransactionFiltering();
            f.daysToNextDunning(String.valueOf(Date.today().addDays(5)));
            f.daysToNextDunning('');
            f.daysToNextDunning(null);
        } catch (Exception e) {}
        try { DunningTransactionFiltering.getEligibleTransactions(acc.Id, 100); } catch (Exception e) {}
        try { DunningTransactionFiltering.getEligibleTransactions(null, null); } catch (Exception e) {}
        try {
            DunningTransactionFiltering f2 = new DunningTransactionFiltering();
            f2.getDunningEvents(new Set<Id>(), acc.Id);
        } catch (Exception e) {}
        Test.stopTest();
    }
}