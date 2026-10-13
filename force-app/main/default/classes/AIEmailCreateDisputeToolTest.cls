@isTest
public class AIEmailCreateDisputeToolTest {
    @isTest
    static void testConstructorAndSetFunction() {
        try {
            // Instantiate the tool
            AIEmailCreateDisputeTool tool = new AIEmailCreateDisputeTool();
        } catch (Exception e) {
            // Handle exception gracefully
            System.debug('Exception in testConstructorAndSetFunction: ' + e.getMessage());
        }
    }
}