@isTest
public class DailyCashMonitoringBatchTest {

    @isTest
    static void testDailyCashMonitoringBatch() {
        // Step 1: Set up test data
        Date testDate = Date.today();
        
        // Create a Monthly_Forecast__c record
        Monthly_Forecast__c monthlyForecast = new Monthly_Forecast__c(
            Name = 'Jan-24',
            Month__c = 01,
            Year__c = 2024,
            Total_AR__c = 5000.20,
            Current_AR__c = 3000.12,
            Forecast_Amount__c = 1000.00,
            Actual_Payment_Received__c = 100.00,
            Total_Days__c = 31,
            BPDSO__c = 39,
            DSO__c = 189
        );
        insert monthlyForecast;

        // Create a Cash_Monitoring__c record and associate it with the Monthly_Forecast__c record
        Cash_Monitoring__c cashMonitoring = new Cash_Monitoring__c(
            Date__c = testDate,
            Daily_Receipts__c = 0,
            Cumulative_Receipt__c = 0,
            Monthly_Forecast__c = monthlyForecast.Id // Link to the Monthly_Forecast__c record
        );
        insert cashMonitoring;

        // Create Transaction records for the aggregate queries to work
        Account acc = DataGenerator.insertAccount();
        List<celsrm__Transaction__c> trxns = new List<celsrm__Transaction__c>();
        
        for (Integer i = 0; i < 5; i++) {
            trxns.add(new celsrm__Transaction__c(
                celsrm__Group_Balance__c = 100,
                celsrm__Close_Date__c = testDate,
                celsrm__Document_Type__c = 'RV',
                celsrm__Amount__c = 1000,
                celsrm__Debit_Credit_Indicator__c = 'H',
                celsrm__Account__c = acc.Id
            ));
        }
        insert trxns;

        // Step 2: Execute the batch
        Test.startTest();
        
        // Create an instance of the batch with the test date
        List<String> docTypes = new List<String>{'RV','AB','DG','DR','DA'};
        DailyCashMonitoringBatch batch = new DailyCashMonitoringBatch(testDate, docTypes);
        
        // Execute the batch using the test data
        Database.executeBatch(batch);
        
        Test.stopTest();

    }
}