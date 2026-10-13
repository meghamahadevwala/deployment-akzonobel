@isTest
public class CreditLimitRequestPdfControllerTest {

    @isTest
    static void testConstructorWithCreditScore() {
        Account acc = CreditDataGenerator.insertAccount();
        celsrm__Credit_Review__c cr = CreditDataGenerator.insertCreditReview(acc);

        celsrm__Credit_Score__c score = new celsrm__Credit_Score__c();
        score.celsrm__Account__c = acc.Id;
        insert score;

        Test.startTest();
        ApexPages.StandardController stdController = new ApexPages.StandardController(cr);
        CreditLimitRequestPdfController controller = new CreditLimitRequestPdfController(stdController);
        Test.stopTest();

        System.assertNotEquals(null, controller.creditReview, 'Credit review should be populated');
        System.assertEquals(cr.Id, controller.creditReview.Id);
        System.assertNotEquals(null, controller.creditScore, 'Most recent credit score for the account should be populated');
        System.assertEquals(score.Id, controller.creditScore.Id);
    }

    @isTest
    static void testConstructorWithoutCreditScore() {
        Account acc = CreditDataGenerator.insertAccount();
        celsrm__Credit_Review__c cr = CreditDataGenerator.insertCreditReview(acc);

        Test.startTest();
        ApexPages.StandardController stdController = new ApexPages.StandardController(cr);
        CreditLimitRequestPdfController controller = new CreditLimitRequestPdfController(stdController);
        Test.stopTest();

        System.assertNotEquals(null, controller.creditReview, 'Credit review should be populated');
        System.assertEquals(null, controller.creditScore, 'No credit score exists for the account, so it should stay null');
    }
}