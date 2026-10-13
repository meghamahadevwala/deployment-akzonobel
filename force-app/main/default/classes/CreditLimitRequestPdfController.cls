public with sharing class CreditLimitRequestPdfController {
    public celsrm__Credit_Review__c creditReview { get; set; }
    public celsrm__Credit_Score__c creditScore { get; set; }

    private ApexPages.StandardController stdController;

    public CreditLimitRequestPdfController(ApexPages.StandardController controller) {
        this.stdController = controller;

        this.creditReview = [
            SELECT Id, Name, 
                   celsrm__Account__c
            FROM celsrm__Credit_Review__c
            WHERE Id = :controller.getId()
            LIMIT 1];

        List<celsrm__Credit_Score__c> scores = [
            SELECT Name FROM celsrm__Credit_Score__c 
            WHERE celsrm__Account__c = :creditReview.celsrm__Account__c 
            ORDER BY CreatedDate DESC LIMIT 1
        ];
        if (!scores.isEmpty()) {
            creditScore = scores[0];
        }
    }
}