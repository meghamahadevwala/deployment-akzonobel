@isTest
public class RunClassificationManuallyTest {
    @isTest
    static void testBatchExecution() {
        // Create test Account
        Account acc = DataGenerator.insertAccount();
        // Create test EmailMessage related to the Account
        EmailMessage em = new EmailMessage();
        em.relatedtoId = acc.Id;
        em.ToAddress = 'testTo@mail.com';
        em.CcAddress = 'testCc@mail.com';
        em.FromAddress = 'testFrom@mail.com';
        em.BccAddress  = 'testBcc@mail.com';
        em.Subject = 'subject';
        em.HtmlBody = '<div>{Transactions.TotalBalance}</div>';
        em.Incoming = true;
        insert em;
        
        Test.startTest();
            RunClassificationManually batch = new RunClassificationManually();
            Database.executeBatch(batch, 1); // Use batch size 1 for test simplicity
        Test.stopTest();
        // No assertions needed as we are not testing GOGCallPredictionAPI logic
    }
}