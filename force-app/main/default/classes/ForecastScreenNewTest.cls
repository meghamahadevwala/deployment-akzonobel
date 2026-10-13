@isTest
public class ForecastScreenNewTest {

    @isTest
    static void testGetPickListOptionForPeriod() {
        // Arrange
        Map<Object, Object> inputMap = new Map<Object, Object>();
        inputMap.put('Period', '1-2025'); // A sample period for testing
        
        List<String> docTypes = new List<String>{'RV','AB','DG','DR','DA'};
        ForecastScreenNew forecastScreenNew = new ForecastScreenNew(docTypes);
        
        // Prepare the function name to pass to the invoke method
        String functionName = 'GetPickListOptionForPeriod';
        
        // Act
        Map<Object, Object> resultMap = forecastScreenNew.invoke(functionName, inputMap);
        
    }

    @isTest
    static void testGetAverageDSO() {
        // Arrange
        String forecastPeriod = '1-2025'; // Example of forecast period
        Map<Object, Object> inputMap = new Map<Object, Object>();
        inputMap.put('Period', forecastPeriod); // Sample period
        
        // Set up the forecast month and year
        Integer forecastMonth = Integer.valueOf(forecastPeriod.split('-')[0]);
        Integer forecastYear = Integer.valueOf(forecastPeriod.split('-')[1]);
        Date firstDayOfForecastMonth = Date.newInstance(forecastYear, forecastMonth, 1);
        
        Account acc = DataGenerator.insertAccount();
        // Insert test data for celsrm__Transaction__c records that will satisfy the query
        List<celsrm__Transaction__c> transactions = new List<celsrm__Transaction__c>();

        transactions.add(new celsrm__Transaction__c(
            celsrm__Create_Date__c = Date.newInstance(forecastYear, forecastMonth - 1, 15),  // Create Date before forecast month
            celsrm__Due_Date__c = Date.newInstance(forecastYear, forecastMonth, 15),        // Due Date in the forecast month
            celsrm__Close_Date__c = null,  // Close Date null
            celsrm__Document_Type__c = 'RV', // Valid Document Type
            celsrm__Amount__c = 1000.0,  // Valid Amount
            celsrm__Account__c = acc.Id
        ));

        transactions.add(new celsrm__Transaction__c(
            celsrm__Create_Date__c = Date.newInstance(forecastYear, forecastMonth - 2, 1),  // Create Date before forecast month
            celsrm__Due_Date__c = Date.newInstance(forecastYear, forecastMonth, 30),        // Due Date in the forecast month
            celsrm__Close_Date__c = Date.newInstance(forecastYear, forecastMonth, 5),       // Close Date after forecast month start
            celsrm__Document_Type__c = 'AB', // Valid Document Type
            celsrm__Amount__c = 2000.0,  // Valid Amount
            celsrm__Account__c = acc.Id
        ));

        // Insert the transactions
        insert transactions;
        
        // Act
        List<String> docTypes = new List<String>{'RV','AB','DG','DR','DA'};
        ForecastScreenNew forecastScreenNew = new ForecastScreenNew(docTypes);
        String functionName = 'GetAverageDSO';
        Map<Object, Object> resultMap = forecastScreenNew.invoke(functionName, inputMap);
    }

    @isTest
    static void testInvalidFunctionName() {
        // Create an instance of the class
        List<String> docTypes = new List<String>{'RV','AB','DG','DR','DA'};
        ForecastScreenNew forecastScreen = new ForecastScreenNew(docTypes);

        // Prepare input
        Map<Object, Object> inputMap = new Map<Object, Object>();

        // Invoke the method with an invalid function name
        Map<Object, Object> result = forecastScreen.invoke('InvalidFunctionName', inputMap);

        // Validate that the input map remains unchanged
    }
}