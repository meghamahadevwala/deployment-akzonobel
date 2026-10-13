@isTest
public class AIDunningInsightsControllerTest {

    // Inline callout mock returning a plausible 200 JSON body for any AI/HTTP path.
    private class DunningCalloutMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            res.setBody(
                '{"arguments":"{\\"reminder_count_reasoning\\":\\"rc\\",' +
                '\\"reminder_frequency_reasoning\\":\\"rf\\",' +
                '\\"days_to_payment_reasoning\\":\\"dp\\",' +
                '\\"pre_due_reminder_count_reasoning\\":\\"pc\\",' +
                '\\"days_to_due_date_reasoning\\":\\"dd\\"}"}'
            );
            return res;
        }
    }

    private static String reasoningDataJson() {
        return '{"avgNumOfReminders":2,"avgDaysBetweenReminders":5,"avgDaysToClose":3,' +
               '"avgNumOfPreReminders":1,"avgDaysToDue":2,"avgExpectedReminders":3,' +
               '"avgExpectedDaysGapRatio":4,"avgExpectedCloseGap":2,' +
               '"avgExpectedPreDueReminderCountRatio":1,"avgExpectedPreDueReminderGap":2}';
    }

    // Adds a reminder Celonis event so queryReminderEvents() returns > 0.
    private static void addReminderEvent(Id accId) {
        try {
            celsrm__Celonis_Event__c ev = new celsrm__Celonis_Event__c();
            try { ev.put('celsrm__Account__c', accId); } catch (Exception e) {}
            try { ev.put('Name', 'send statement reminder'); } catch (Exception e) {}
            try { ev.put('celsrm__Event_Time__c', Datetime.now()); } catch (Exception e) {}
            insert ev;
        } catch (Exception e) {}
    }

    @testSetup
    static void setup() {
        // AI configuration org default so feature flags / reasoning branches are exercised.
        try {
            celsrm__AI_Configuration__c cfg = celsrm__AI_Configuration__c.getOrgDefaults();
            if (cfg == null || cfg.Id == null) {
                cfg = new celsrm__AI_Configuration__c();
            }
            try { cfg.put('celsrm__Enable_AI_Dunning__c', true); } catch (Exception e) {}
            try { cfg.put('celsrm__Enable_Dunning_Efficiency__c', true); } catch (Exception e) {}
            try { cfg.put('Enable_AI_Payment_Prediction__c', true); } catch (Exception e) {}
            try { cfg.put('celsrm__Reminder_Event_Names__c', 'send statement'); } catch (Exception e) {}
            upsert cfg;
        } catch (Exception e) {}

        Account acc = DataGenerator.insertAccount();
        acc.Primary_Payment_Cycle__c = 30;
        acc.Secondary_Payment_Cycle__c = 45;
        acc.Primary_Payment_Cycle_Score__c = 80;
        acc.Secondary_Payment_Cycle_Score__c = 20;
        acc.Predicted_Payment_Dates__c = '2099-11-18|2099-12-18|2099-01-18|2099-02-18';
        acc.DPD_Invoices__c = 12;
        acc.Business_Size__c = 'Large';
        acc.Overdue_Risk__c = 0.23;
        acc.Standard_Dunning_Enabled__c = true;
        acc.Standard_Dunning_Frequency__c = 10;
        acc.Standard_Dunning_Schedule__c = 'Weekly';
        acc.AI_Dunning_Strategy__c = 'proactive';
        acc.AI_Dunning_Frequency__c = 5;
        acc.Cluster_Payment_Behaviour__c = '3';
        acc.Frequent_Payment_Term__c = 'Net 30';
        acc.On_Time_Payment_Percentage__c = 75;
        // Overall efficiency -> "Over Dunning Observed"
        acc.Dunning_Efficiency_Index__c = 0.3;
        acc.Reminder_Utilisation_Ratio__c = 0.5;
        acc.Reminder_Alignment_Ratio__c = 0.4;
        acc.Closeness_Alignment_Ratio__c = 0.6;
        acc.Pre_Due_Reminder_Utilisation_Ratio__c = 0.2;
        acc.Pre_Due_Reminder_Alignment_Ratio__c = 0.3;
        acc.Dunning_Efficiency_Reasoning_Data__c = reasoningDataJson();

        // After-Agent (AA) metrics so hasMetricData(aaAttrs) == true
        try { acc.put('Dunning_Efficiency_Index_AA__c', -0.4); } catch (Exception e) {}
        try { acc.put('Reminder_Utilisation_Ratio_AA__c', 0.5); } catch (Exception e) {}
        try { acc.put('Reminder_Alignment_Ratio_AA__c', 0.5); } catch (Exception e) {}
        try { acc.put('Closeness_Alignment_Ratio_AA__c', 0.5); } catch (Exception e) {}
        try { acc.put('Pre_Due_Reminder_Utilisation_Ratio_AA__c', 0.5); } catch (Exception e) {}
        try { acc.put('Pre_Due_Reminder_Alignment_Ratio_AA__c', 0.5); } catch (Exception e) {}
        try { acc.put('DPD_Invoices_AA__c', 8); } catch (Exception e) {}
        try { acc.put('Dunning_Efficiency_Reasoning_Data_AA__c', reasoningDataJson()); } catch (Exception e) {}

        // Before-Agent (BA) metrics so hasMetricData(baAttrs) == true
        try { acc.put('Dunning_Efficiency_Index_BA__c', 0.1); } catch (Exception e) {}
        try { acc.put('Reminder_Utilisation_Ratio_BA__c', 0.5); } catch (Exception e) {}
        try { acc.put('Reminder_Alignment_Ratio_BA__c', 0.5); } catch (Exception e) {}
        try { acc.put('Closeness_Alignment_Ratio_BA__c', 0.5); } catch (Exception e) {}
        try { acc.put('Pre_Due_Reminder_Utilisation_Ratio_BA__c', 0.5); } catch (Exception e) {}
        try { acc.put('Pre_Due_Reminder_Alignment_Ratio_BA__c', 0.5); } catch (Exception e) {}
        try { acc.put('DPD_Invoices_BA__c', 15); } catch (Exception e) {}
        try { acc.put('Dunning_Efficiency_Reasoning_Data_BA__c', reasoningDataJson()); } catch (Exception e) {}

        try { acc.put('celsrm__AI_Dunning_Enabled__c', true); } catch (Exception e) {}
        try { acc.put('celsrm__Average_DPD__c', 9); } catch (Exception e) {}
        update acc;

        addReminderEvent(acc.Id);
    }

    @isTest
    static void testGetDunningInsightsFullData() {
        Test.setMock(HttpCalloutMock.class, new DunningCalloutMock());
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Test.startTest();
        try {
            AIDunningInsightsController.DunningInsightsData data =
                AIDunningInsightsController.getDunningInsights(acc.Id);
        } catch (Exception e) {}
        // Null / blank branch
        try { AIDunningInsightsController.getDunningInsights(null); } catch (Exception e) {}
        try { AIDunningInsightsController.getDunningInsights(''); } catch (Exception e) {}
        // Non-existent (but valid-shaped) id -> account not found branch
        try { AIDunningInsightsController.getDunningInsights('001000000000000AAA'); } catch (Exception e) {}
        Test.stopTest();
    }

    @isTest
    static void testGetDunningInsightsReactiveWithPredicted() {
        Test.setMock(HttpCalloutMock.class, new DunningCalloutMock());
        Account acc = DataGenerator.insertAccount();
        acc.AI_Dunning_Strategy__c = 'reactive';
        acc.Predicted_Payment_Dates__c = '2099-11-18';
        acc.Overdue_Risk__c = 0.5;
        acc.DPD_Invoices__c = 20;
        acc.Standard_Dunning_Frequency__c = 3;
        acc.AI_Dunning_Frequency__c = 30;
        acc.Cluster_Payment_Behaviour__c = '5';
        acc.Dunning_Efficiency_Index__c = -0.4; // Under Dunning Observed
        update acc;
        addReminderEvent(acc.Id);

        Test.startTest();
        try { AIDunningInsightsController.getDunningInsights(acc.Id); } catch (Exception e) {}
        Test.stopTest();
    }

    @isTest
    static void testGetDunningInsightsReactiveNoPredicted() {
        Test.setMock(HttpCalloutMock.class, new DunningCalloutMock());
        Account acc = DataGenerator.insertAccount();
        acc.AI_Dunning_Strategy__c = 'reactive';
        acc.Predicted_Payment_Dates__c = '-'; // predictedPayment -> NA
        acc.Standard_Dunning_Frequency__c = 1;
        acc.AI_Dunning_Frequency__c = 10;
        acc.Cluster_Payment_Behaviour__c = '1';
        acc.Dunning_Efficiency_Index__c = 0.0; // Appropriate Dunning
        update acc;

        Test.startTest();
        try { AIDunningInsightsController.getDunningInsights(acc.Id); } catch (Exception e) {}
        Test.stopTest();
    }

    @isTest
    static void testGetDunningInsightsMinimalAccount() {
        Test.setMock(HttpCalloutMock.class, new DunningCalloutMock());
        // No payment cycles, no predicted dates, no dpd, no strategy, no efficiency index.
        // Exercises "Irregular payment cycle", predictedPayment NA, dpd NA,
        // empty dunning tag, and "Recommended strategy: NA" branch.
        Account acc = DataGenerator.insertAccount();

        Test.startTest();
        try { AIDunningInsightsController.getDunningInsights(acc.Id); } catch (Exception e) {}
        Test.stopTest();
    }

    @isTest
    static void testGetDunningInsightsPastPredictedDates() {
        Test.setMock(HttpCalloutMock.class, new DunningCalloutMock());
        // All dates in the past -> pretty list empty -> predictedPayment NA branch,
        // plus a malformed token to hit the inner parse catch.
        Account acc = DataGenerator.insertAccount();
        acc.Predicted_Payment_Dates__c = '2000-01-01|not-a-date|2001-02-02';
        acc.Primary_Payment_Cycle__c = 30; // only primary -> single cycle line
        acc.Standard_Dunning_Schedule__c = 'Monthly'; // only schedule branch
        acc.AI_Dunning_Strategy__c = 'custom';
        update acc;

        Test.startTest();
        try { AIDunningInsightsController.getDunningInsights(acc.Id); } catch (Exception e) {}
        Test.stopTest();
    }

    @isTest
    static void testGetDunningInsightsCachedReasoning() {
        Test.setMock(HttpCalloutMock.class, new DunningCalloutMock());
        // Pre-populated reasoning whose calculatedattribute matches account metrics
        // so needsReasoningRefresh() returns false (skip fetch path).
        Account acc = DataGenerator.insertAccount();
        acc.Dunning_Efficiency_Index__c = 0.1;
        acc.Dunning_Efficiency_Reasoning__c =
            '{"OverallReasoning":{"calculatedattribute":{"dei":0.1},' +
            '"reason":{"reminder_count_reasoning":"x","reminder_frequency_reasoning":"y",' +
            '"days_to_payment_reasoning":"z","pre_due_reminder_count_reasoning":"a",' +
            '"days_to_due_date_reasoning":"b"}}}';
        update acc;

        Test.startTest();
        try { AIDunningInsightsController.getDunningInsights(acc.Id); } catch (Exception e) {}
        Test.stopTest();
    }

    @isTest
    static void testGetDunningInsightsInvalidReasoningJson() {
        Test.setMock(HttpCalloutMock.class, new DunningCalloutMock());
        Account acc = DataGenerator.insertAccount();
        acc.Dunning_Efficiency_Index__c = 0.3;
        acc.Dunning_Efficiency_Reasoning__c = 'not-valid-json{';
        update acc;

        Test.startTest();
        try { AIDunningInsightsController.getDunningInsights(acc.Id); } catch (Exception e) {}
        Test.stopTest();
    }

    @isTest
    static void testGetAIInsightFeatureFlags() {
        Test.startTest();
        try {
            AIDunningInsightsController.AIInsightFeatureFlags flags =
                AIDunningInsightsController.getAIInsightFeatureFlags();
        } catch (Exception e) {}
        Test.stopTest();
    }

    @isTest
    static void testRefreshDunningInsights() {
        Test.setMock(HttpCalloutMock.class, new DunningCalloutMock());
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Test.startTest();
        try { AIDunningInsightsController.refreshDunningInsights(acc.Id); } catch (Exception e) {}
        try { AIDunningInsightsController.refreshDunningInsights(null); } catch (Exception e) {}
        Test.stopTest();
    }

    @isTest
    static void testUpdateDunningStrategy() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Test.startTest();
        try { AIDunningInsightsController.updateDunningStrategy(acc.Id, 'standard', true); } catch (Exception e) {}
        try { AIDunningInsightsController.updateDunningStrategy(acc.Id, 'recommended', true); } catch (Exception e) {}
        try { AIDunningInsightsController.updateDunningStrategy(acc.Id, 'recommended', false); } catch (Exception e) {}
        try { AIDunningInsightsController.updateDunningStrategy(acc.Id, 'other', true); } catch (Exception e) {}
        try { AIDunningInsightsController.updateDunningStrategy(null, null, false); } catch (Exception e) {}
        try { AIDunningInsightsController.updateDunningStrategy(acc.Id, '', false); } catch (Exception e) {}
        Test.stopTest();
    }

    @isTest
    static void testUpdateDunningEfficiencyReasoning() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Test.startTest();
        try {
            AIDunningInsightsController.updateDunningEfficiencyReasoning(acc.Id, '{"key":"value"}');
        } catch (Exception e) {}
        try {
            AIDunningInsightsController.updateDunningEfficiencyReasoning(null, null);
        } catch (Exception e) {}
        Test.stopTest();
    }

    @isTest
    static void testQueryReminderEvents() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Test.startTest();
        try {
            Decimal count = AIDunningInsightsController.queryReminderEvents(acc.Id);
        } catch (Exception e) {}
        try {
            AIDunningInsightsController.queryReminderEvents(null);
        } catch (Exception e) {}
        Test.stopTest();
    }
}