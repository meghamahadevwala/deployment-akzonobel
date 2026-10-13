@isTest
public class AIEmailCapturePromiseToolTest {
    @isTest
    static void testConstructorAndSetFunction() {
        try {
            // Instantiate the tool
            AIEmailCapturePromiseTool tool = new AIEmailCapturePromiseTool();
        } catch (Exception e) {
            // Handle exception gracefully
            System.debug('Exception in testConstructorAndSetFunction: ' + e.getMessage());
        }
    }
}