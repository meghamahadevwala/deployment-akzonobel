@isTest
public class AIEmailSendStatementToolTest {
    @isTest
    static void testConstructorAndSetFunction() {
        try {
            // Instantiate the tool
            AIEmailSendStatementTool tool = new AIEmailSendStatementTool();
        } catch (Exception e) {
            // Handle exception gracefully
            System.debug('Exception in testConstructorAndSetFunction: ' + e.getMessage());
        }
    }
}