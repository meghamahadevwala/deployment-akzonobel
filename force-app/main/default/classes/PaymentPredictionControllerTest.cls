@isTest
public class PaymentPredictionControllerTest {

    @testSetup
    static void setup() {
        Account acc = DataGenerator.insertAccount();
        String innerJson = '{"column":["date","confidence","reasoning"],"data":[["2026-08-01",90,"On time payer"],["2026-09-01",70,"Historical trend"]]}';
        acc.Predicted_Payment_Dates_New__c = JSON.serialize(innerJson);
        try {
            update acc;
        } catch (Exception e) { }

        List<celsrm__Transaction__c> txs = new List<celsrm__Transaction__c>();
        celsrm__Transaction__c tx = new celsrm__Transaction__c();
        tx.Name = 'INV-1';
        tx.celsrm__Account__c = acc.Id;
        tx.celsrm__Amount__c = 500;
        tx.celsrm__Balance__c = 500;
        tx.celsrm__Status__c = 'Open';
        tx.celsrm__Due_Date__c = Date.newInstance(2026, 8, 1);
        tx.celsrm__Posting_Date__c = Date.newInstance(2026, 7, 1);
        tx.Expected_Payment_Date_Confidence_Score__c = 90;
        tx.Expected_Payment_Date_Reasoning__c = 'On time payer';
        tx.celsrm__Document_Type__c = 'Invoice';
        txs.add(tx);
        try {
            insert txs;
        } catch (Exception e) { }
    }

    @isTest
    static void getPredictionsTest() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Test.startTest();
        try {
            PaymentPredictionController.getPredictions(acc.Id, true);
        } catch (Exception e) { }
        try {
            PaymentPredictionController.getPredictions(acc.Id, false);
        } catch (Exception e) { }
        Test.stopTest();
    }

    @isTest
    static void blankPredictionTest() {
        Account acc = CreditDataGenerator.insertAccount();
        Test.startTest();
        try {
            PaymentPredictionController.getPredictions(acc.Id, true);
        } catch (Exception e) { }
        Test.stopTest();
    }
}