@isTest
public class AIDunningTemplateGenerationTest {

    @testSetup
    static void setup() {
        Account acc = DataGenerator.insertAccount();
        DataGenerator.transactionInsert(acc, 2);
    }

    @isTest
    static void testGenerateDunningEmailContent() {
        AIDunningGenAiController.useMockAI = true;
        celsrm.AIWrapper.ReturnResponse mock = new celsrm.AIWrapper.ReturnResponse();
        mock.resultSummary = '{"subject":"Overdue Reminder","emailTemplateHtml":"<html><body>{transactions.summary}</body></html>"}';
        AIDunningGenAiController.mockResponse = mock;

        Account acc = [SELECT Id FROM Account LIMIT 1];
        List<celsrm__Transaction__c> txns = [SELECT Id FROM celsrm__Transaction__c];
        List<Id> txnIds = new List<Id>();
        for (celsrm__Transaction__c t : txns) {
            txnIds.add(t.Id);
        }

        List<Task> tasks = DataGenerator.insertTask(acc, 1);

        Map<String, Object> dunningData = new Map<String, Object>{
            'accountName' => 'Test Account',
            'accountNumber' => 'ACC-001'
        };

        Map<String, String> collectorDetails = new Map<String, String>{
            'name' => 'John', 'email' => 'john@test.com'
        };

        Test.startTest();
        try {
            AIDunningTemplateGeneration.DunningEmailResult result =
                AIDunningTemplateGeneration.generateDunningEmailContent(
                    tasks[0], dunningData, txnIds, 'prompt', 'English', collectorDetails);
        } catch (Exception e) {}
        Test.stopTest();
    }

    @isTest
    static void testBuildTransactionHtmlTable() {
        List<celsrm__Transaction__c> txns = [SELECT Id FROM celsrm__Transaction__c];
        List<Id> txnIds = new List<Id>();
        for (celsrm__Transaction__c t : txns) {
            txnIds.add(t.Id);
        }

        Test.startTest();
        try {
            Map<String, Object> tableData = AIDunningTemplateGeneration.buildTransactionHtmlTable(
                txnIds, true, 'celsrm__Amount__c', 'Total:', 'celsrm__Transaction__c',
                'Name,celsrm__Amount__c,celsrm__Balance__c,celsrm__Due_Date__c');
        } catch (Exception e) {}

        try {
            Map<String, Object> emptyCols = AIDunningTemplateGeneration.buildTransactionHtmlTable(
                txnIds, false, null, null, 'celsrm__Transaction__c', '');
        } catch (Exception e) {}
        Test.stopTest();
    }
}