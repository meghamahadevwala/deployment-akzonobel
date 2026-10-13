@isTest
public class GraphControllerTest {

    // Helper method to create a test Monthly_Forecast__c record
    private static Monthly_Forecast__c createTestMonthlyForecast(String forecastName, Decimal forecastAmount, Integer year, Integer month) {
        Monthly_Forecast__c forecast = new Monthly_Forecast__c(
            Name = forecastName,
            Forecast_Amount__c = forecastAmount,
            Year__c = year,
            Month__c = month
        );
        insert forecast;
        return forecast;
    }

    // Helper method to create a test Cash_Monitoring__c record (excluding formula fields)
    private static Cash_Monitoring__c createTestCashMonitoring(Monthly_Forecast__c forecast, Date monitoringDate, Decimal cumulativeTarget, Decimal cumulativeReceipt, Decimal dailyReceipts) {
        Cash_Monitoring__c cm = new Cash_Monitoring__c(
            Monthly_Forecast__c = forecast.Id,
            Date__c = monitoringDate,
            Cumulative_Target__c = cumulativeTarget,
            Cumulative_Receipt__c = cumulativeReceipt,
            Daily_Receipts__c = dailyReceipts
        );
        insert cm;
        return cm;
    }

    // Helper method to create a test Collector_Target__c record (excluding formula fields)
    private static Collector_Target__c createTestCollectorTarget(Monthly_Forecast__c forecast, Decimal forecastAmount, Decimal actualPaymentReceived) {
        Collector_Target__c target = new Collector_Target__c(
            Monthly_Forecast__c = forecast.Id,
            Forecast_Amount__c = forecastAmount,
            Actual_Payment_Received__c = actualPaymentReceived
        );
        insert target;
        return target;
    }

    // Test method for getCashMonitoringManager to cover the missing lines
    @isTest
    static void testGetCashMonitoringManager() {
        // Create test data
        Monthly_Forecast__c forecast = createTestMonthlyForecast('Test Forecast', 50000, 2025, 1);

        // Test with valid values
        Cash_Monitoring__c cm1 = createTestCashMonitoring(forecast, Date.today().addDays(-7), 1000, 500, 100);
        Cash_Monitoring__c cm2 = createTestCashMonitoring(forecast, Date.today().addDays(-6), 2000, 1500, 200);
        Cash_Monitoring__c cm3 = createTestCashMonitoring(forecast, Date.today().addDays(-5), 3000, 2500, 300);

        // Test with zero or null values
        Cash_Monitoring__c cm4 = createTestCashMonitoring(forecast, Date.today().addDays(-4), 0, 0, 0);
        Cash_Monitoring__c cm5 = createTestCashMonitoring(forecast, Date.today().addDays(-3), 0, null, null);

        Test.startTest();

        // Call the method
        Map<String, Object> result = GraphController.getCashMonitoringManager(forecast.Id);

        Test.stopTest();

    }

    // Test method for collectorDashboardManager
    @isTest
    static void testCollectorDashboardManager() {
        // Create test data
        Monthly_Forecast__c forecast = createTestMonthlyForecast('Test Forecast', 50000, 2025, 1);

        // Create relevant records
        Cash_Monitoring__c cm1 = createTestCashMonitoring(forecast, Date.today().addDays(-7), 1000, 500, 100);
        Cash_Monitoring__c cm2 = createTestCashMonitoring(forecast, Date.today().addDays(-6), 2000, 1500, 200);

        Collector_Target__c target1 = createTestCollectorTarget(forecast, 1000, 900);

        Test.startTest();

        // Call the method
        Map<String, Map<String, Decimal>> result = GraphController.collectorDashboardManager(forecast.Id);

        Test.stopTest();

    }

    // Test method for getForecastCollectionChartMap
    @isTest
    static void testGetForecastCollectionChartMap() {
        // Create test data
        createTestMonthlyForecast('Test Forecast 1', 10000, 2025, 1);
        createTestMonthlyForecast('Test Forecast 2', 20000, 2025, 2);

        Test.startTest();

        // Call the method
        Map<String, Map<String, Decimal>> result = GraphController.getForecastCollectionChartMap();

        Test.stopTest();

    }

    @isTest
    static void testGetForecastIdForCurrentMonth() {
        // Test setup: Create a Monthly_Forecast__c record for the current month and year
        // Date currentDate = Date.today();
        Datetime currentDate = (Datetime.newInstance(date.today().year(), date.today().month(), date.today().day()));//.addDays(-6)
        String currentMonth = currentDate.format('MMM');
        String currentYear = currentDate.format('YY');
        String forecastName = currentMonth +'-'+ currentYear;
        
        Monthly_Forecast__c forecast = new Monthly_Forecast__c(
            Name = forecastName,
            Month__c = date.today().month(),
            Year__c = date.today().year(),
            Forecast_Amount__c = 1000.00
        );
        insert forecast;
        
        // Test execution: Call the method
        Test.startTest();
        GraphController.getForecastIdForCurrentMonth();
        Test.stopTest();
        
    }

    @isTest
    static void testGetForecastIdForCurrentMonthElseBlock() {
        // Test setup: Create two older Monthly_Forecast__c records
        Monthly_Forecast__c oldForecast1 = new Monthly_Forecast__c(
            Name = 'Older Forecast 1',
            Month__c = 10, // Example: October
            Year__c = Date.today().year() - 1, // Last year
            Forecast_Amount__c = 500
        );
        Monthly_Forecast__c oldForecast2 = new Monthly_Forecast__c(
            Name = 'Older Forecast 2',
            Month__c = 9, // Example: September
            Year__c = Date.today().year() - 1, // Last year
            Forecast_Amount__c = 400
        );
        insert new List<Monthly_Forecast__c>{oldForecast1, oldForecast2};

        // Test execution: Call the method
        Test.startTest();
        GraphController.getForecastIdForCurrentMonth();
        Test.stopTest();

    }

    @isTest
    static void testGetCashMonitoringManagerWithCurrentDate() {
        // Test Setup: Create a Monthly_Forecast__c record with today's date
        Monthly_Forecast__c forecast = new Monthly_Forecast__c(
            Name = 'Current Month Forecast',
            Month__c = Date.today().month(),
            Year__c = Date.today().year(),
            Forecast_Amount__c = 10000,
            Total_Days__c = 30
        );
        insert forecast;

        // Test Setup: Create a Cash_Monitoring__c record linked to the forecast, with today's date
        Cash_Monitoring__c cashMonitoring = new Cash_Monitoring__c(
            Date__c = Date.today(),
            Monthly_Forecast__c = forecast.Id,
            Cumulative_Target__c = 5000,
            Cumulative_Receipt__c = 4500,
            Daily_Receipts__c = 500
            // Cumulative_Target_Percent__c = 90,
            // Cumulative_Receipt_Percent__c = 80
        );
        insert cashMonitoring;

        // Test Execution: Call the method
        Test.startTest();
        Map<String, Object> result = GraphController.getCashMonitoringManager(forecast.Id);
        Test.stopTest();

    }
}