public with sharing class CreditScoreManager {
    @AuraEnabled
    public static String calculateCreditScore(String creditReviewId){
        try{
            CalculateCreditScore.getCreditScore(null, creditReviewId, 'Recalculation', null);
            return 'success';
        } catch(exception e){
            system.debug('Error occured at line>>>'+e.getLineNumber()+'<< Reason is >>'+e.getMessage() );
            return 'error';
        }
        
    }
}