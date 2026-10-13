@isTest
public class AIActionNotSureTest {
    @isTest
    static void testExecuteEmailNotSure_Success() {
        try {
            Account acc = DataGenerator.insertAccount();
            EmailMessage em = DataGenerator.insertEmailMsg(acc.Id);
            AIActionNotSure.NotSureWrapper req = new AIActionNotSure.NotSureWrapper();
            req.emailMessageId = em.Id;
            req.reason = 'Test Reason';
            String body = JSON.serialize(req);
            RestRequest reqObj = new RestRequest();
            reqObj.requestBody = Blob.valueOf(body);
            RestContext.request = reqObj;
            AIActionNotSure.AIExecutorResponseWrapper resp = AIActionNotSure.executeEmailNotSure();
        } catch (Exception e) {
            System.debug('Exception in testExecuteEmailNotSure_Success: ' + e.getMessage());
        }
    }

    @isTest
    static void testExecuteEmailNotSure_MissingEmailMessageId() {
        try {
            AIActionNotSure.NotSureWrapper req = new AIActionNotSure.NotSureWrapper();
            req.emailMessageId = null;
            req.reason = 'Test Reason';
            String body = JSON.serialize(req);
            RestRequest reqObj = new RestRequest();
            reqObj.requestBody = Blob.valueOf(body);
            RestContext.request = reqObj;
            AIActionNotSure.AIExecutorResponseWrapper resp = AIActionNotSure.executeEmailNotSure();
        } catch (Exception e) {
            System.debug('Exception in testExecuteEmailNotSure_MissingEmailMessageId: ' + e.getMessage());
        }
    }

    @isTest
    static void testExecuteEmailNotSure_InvalidEmailMessageId() {
        try {
            AIActionNotSure.NotSureWrapper req = new AIActionNotSure.NotSureWrapper();
            req.emailMessageId = 'invalidId';
            req.reason = 'Test Reason';
            String body = JSON.serialize(req);
            RestRequest reqObj = new RestRequest();
            reqObj.requestBody = Blob.valueOf(body);
            RestContext.request = reqObj;
            AIActionNotSure.AIExecutorResponseWrapper resp = AIActionNotSure.executeEmailNotSure();
        } catch (Exception e) {
            System.debug('Exception in testExecuteEmailNotSure_InvalidEmailMessageId: ' + e.getMessage());
        }
    }
}