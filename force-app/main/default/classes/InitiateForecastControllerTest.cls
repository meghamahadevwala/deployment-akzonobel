@isTest
public class InitiateForecastControllerTest {

    @isTest
    static void testInvoke() {
        // Create a mock input map for the 'initiateForecast' function
        Map<Object, Object> inputMap = new Map<Object, Object>();
        inputMap.put('Period', '01-2025');  // Sample period in MM-YYYY format
        inputMap.put('avgDSO', '30');       // Sample average DSO value
        inputMap.put('bpDSO', '40');        // Sample BPDSO value

        // Create a mock UpdateForecastBatch class (since this is executed asynchronously, we can't check its results directly)
        Test.startTest();
        
        // Execute the invoke method
        InitiateForecastController controller = new InitiateForecastController();
        Map<Object, Object> result = controller.invoke('initiateForecast', inputMap);
        
        Test.stopTest();

        // Verify the result
        System.assertNotEquals(result, null, 'Result map should not be null');
        System.assertEquals(result.get('Period'), '01-2025', 'Period should match the input');
        System.assertEquals(result.get('avgDSO'), '30', 'avgDSO should match the input');
        System.assertEquals(result.get('bpDSO'), '40', 'bpDSO should match the input');

        // Verify that the batch job was added to the job queue (since it is executed asynchronously)
        // This will check if the batch job is created after invoking the function
        List<AsyncApexJob> jobs = [SELECT Id, Status, JobType FROM AsyncApexJob WHERE JobType = 'BatchApex'];
        System.assert(!jobs.isEmpty(), 'There should be at least one batch job queued.');
    }

    @isTest
    static void testInvokeExceptionHandling() {
        // Create a mock input map for the 'initiateForecast' function with invalid data
        Map<Object, Object> inputMap = new Map<Object, Object>();
        inputMap.put('Period', 'InvalidPeriod');  // Invalid period format
        inputMap.put('avgDSO', 'invalidValue');  // Invalid DSO value
        inputMap.put('bpDSO', 'invalidValue');   // Invalid BPDSO value

        // Test exception handling
        try {
            Test.startTest();
            
            // Execute the invoke method with invalid data
            InitiateForecastController controller = new InitiateForecastController();
            controller.invoke('initiateForecast', inputMap);
            
            Test.stopTest();
            System.assert(false, 'Exception was expected due to invalid input.');
        } catch (Exception e) {
            Test.stopTest();
            System.assert(e.getMessage().contains('::'), 'Exception message should contain stack trace information');
        }
    }
}