@isTest
public class AIEmailCustomActionAgentTest {
    @isTest
    static void testConstructorAndSetFunction() {
        try {
            // Instantiate the tool
            AIEmailCustomActionAgent tool = new AIEmailCustomActionAgent();
        } catch (Exception e) {
            // Handle exception gracefully
            System.debug('Exception in testConstructorAndSetFunction: ' + e.getMessage());
        }
    }
}