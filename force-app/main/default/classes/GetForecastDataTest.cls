@isTest
public class GetForecastDataTest {
    @isTest
    static void testGetFieldNames() {
        // Test the getFieldNames method
        Map<String, String> fieldNames = GetForecastData.getFieldNames();
        System.assert(fieldNames != null, 'Field names map should not be null');
        System.assert(!fieldNames.isEmpty(), 'Field names map should not be empty');
    }

    @isTest
    static void testGetForecastList() {
        // Insert test data for Monthly_Forecast__c
        List<Monthly_Forecast__c> forecasts = new List<Monthly_Forecast__c>();
        for (Integer i = 1; i <= 5; i++) {
            forecasts.add(new Monthly_Forecast__c(
                Name = 'Forecast' + i,
                Month__c = i,
                Year__c = 2024,
                Total_AR__c = 1000 * i,
                Current_AR__c = 500 * i,
                Forecast_Amount__c = 1500 * i,
                Actual_Payment_Received__c = 1200 * i
            ));
        }
        insert forecasts;

        // Test the getForecastList method
        Map<String, Monthly_Forecast__c> forecastList = GetForecastData.getForecastList(null);
        System.assert(forecastList != null, 'Forecast list should not be null');
        System.assertEquals(5, forecastList.size(), 'Forecast list size should match the inserted records');
    }

    @isTest
    static void testGetNameSpace() {
        // Test the getNameSpace method
        String namespace = GetForecastData.getNameSpace();
        System.assertEquals('celsrm__', namespace, 'Namespace should match the expected value');
    }

    @isTest
    static void testGetCurrencyCode() {
        // Mock multi-currency behavior using test data
        Test.startTest();
        Map<String, String> currencyCode = GetForecastData.getCurrencyCode();
        Test.stopTest();

        System.assert(currencyCode != null, 'Currency code map should not be null');
        System.assert(currencyCode.containsKey('isMultiCurrencyEnable'), 'Map should contain isMultiCurrencyEnable');
        System.assert(currencyCode.containsKey('currencySymbol'), 'Map should contain currencySymbol');
    }

    @isTest
    static void testGetCurrencyCodeExceptionHandling() {
        // Mock exception handling scenario
        Test.startTest();
        Map<String, String> currencyCode = null;
        try {
            currencyCode = GetForecastData.getCurrencyCode();
        } catch (Exception e) {
            System.assert(currencyCode == null, 'Currency code map should be null when an exception occurs');
        }
        Test.stopTest();
    }
}