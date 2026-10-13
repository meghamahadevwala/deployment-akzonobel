@isTest

public with sharing class CreditScoreManagerTest {

    public static testMethod void CreditScoreManagerTest() {
        celsrm__Credit_Review__c cr = DataGenerator.insertCreditReview();

        CreditScoreManager.calculateCreditScore(cr.Id);

        CreditScoreManager.calculateCreditScore(cr.Id);
    }
}