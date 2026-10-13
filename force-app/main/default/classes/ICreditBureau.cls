public interface ICreditBureau {
    Map<Object, Object> initialize(Map<Object, Object> inMap);
    Map<Object, Object> fetchCompanyList(Map<Object, Object> inMap);
    Map<Object, Object> updateBureauId(Map<Object, Object> inMap, Account account );
    Map<Object, Object> fetchParameters(Map<Object, Object> inMap);
    Map<Object, Object> prepareInMapForCreditScoreCalculation(Map<Object, Object> inMap);
    celsrm__Credit_Review__c updateOnCreditReview(Map<Object, Object> inMap, celsrm__Credit_Review__c creditReview);
    celsrm__Credit_Score__c updateOnCreditScore(Map<Object, Object> inMap, celsrm__Credit_Score__c creditScore);
}