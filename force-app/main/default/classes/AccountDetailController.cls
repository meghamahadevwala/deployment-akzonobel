global with sharing class AccountDetailController implements celsrm.GOGIScreenCustomLogic {
    global Map<Object, Object> invoke(String functionName, Map<Object, Object> inMap){
        if(functionName == 'AgingSummary') {
            inMap = getAccountAgingSummary(inMap);
        } else if (functionName == 'getAccountName'){
            inMap = getAccountName(inMap);
        } else if (functionName == 'getScoreCardDetail'){
            inMap = getScoreCardDetail(inMap);
        }
        return inMap; 
    }
    public static Map<Object, Object> getAccountAgingSummary(Map<Object, Object> inMap) {
        Map<Object, Object> returnMap = new Map<Object, Object>();
        String accountId = String.valueOf(inMap.get('Id'));
        returnMap.put('LOCALE', UserInfo.getLocale().replace('_', '-'));
        List<Account> accList = [SELECT celsrm__Total_AR__c, celsrm__Age0__c, celsrm__Age1__c, celsrm__Age2__c, celsrm__Age3__c, celsrm__Age4__c, 
        celsrm__Age5__c, celsrm__Age1_Percent__c, celsrm__Age2_Percent__c, celsrm__Age3_Percent__c, celsrm__Age4_Percent__c, celsrm__Age5_Percent__c,
        celsrm__Not_Due_Percent__c, celsrm__Closed_Invoices__c, celsrm__Invoices_1_30__c, celsrm__Invoices_31_60__c, celsrm__Invoices_61_90__c, celsrm__Invoices_91_180__c,
        celsrm__Not_Due_Invoices__c, celsrm__Open_Invoices__c, celsrm__Invoice_Over_180__c, CurrencyISOCode FROM Account WHERE Id =: accountId LIMIT 1];
        for (Account accObj : accList) {
            returnMap.put('CURRENCY_CODE', accObj.CurrencyISOCode);
            returnMap.put('OPEN_AR', accObj.celsrm__Total_AR__c);
            returnMap.put('AGE_0', accObj.celsrm__Age0__c);
            returnMap.put('AGE_1', accObj.celsrm__Age1__c);
            returnMap.put('AGE_2', accObj.celsrm__Age2__c);
            returnMap.put('AGE_3', accObj.celsrm__Age3__c);
            returnMap.put('AGE_4', accObj.celsrm__Age4__c);
            returnMap.put('AGE_5', accObj.celsrm__Age5__c);

            returnMap.put('AGE_1_PERCENT', accObj.celsrm__Age1_Percent__c);
            returnMap.put('AGE_2_PERCENT', accObj.celsrm__Age2_Percent__c);
            returnMap.put('AGE_3_PERCENT', accObj.celsrm__Age3_Percent__c);
            returnMap.put('AGE_4_PERCENT', accObj.celsrm__Age4_Percent__c);
            returnMap.put('AGE_5_PERCENT', accObj.celsrm__Age5_Percent__c);
            returnMap.put('NOT_DUE_PERCENT', accObj.celsrm__Not_Due_Percent__c);

            returnMap.put('OPEN_INVOICES', accObj.celsrm__Open_Invoices__c != null ? accObj.celsrm__Open_Invoices__c : 0);
            returnMap.put('NOT_DUE_INVOICES', accObj.celsrm__Not_Due_Invoices__c != null ? accObj.celsrm__Not_Due_Invoices__c : 0);
            returnMap.put('INVOICES_1_30', accObj.celsrm__Invoices_1_30__c != null ? accObj.celsrm__Invoices_1_30__c : 0);
            returnMap.put('INVOICES_31_60', accObj.celsrm__Invoices_31_60__c != null ? accObj.celsrm__Invoices_31_60__c : 0);
            returnMap.put('INVOICES_61_90', accObj.celsrm__Invoices_61_90__c != null ? accObj.celsrm__Invoices_61_90__c : 0);
            returnMap.put('INVOICES_91_180', accObj.celsrm__Invoices_91_180__c != null ? accObj.celsrm__Invoices_91_180__c : 0);
            returnMap.put('INVOICES_OVER_180', accObj.celsrm__Invoice_Over_180__c != null ? accObj.celsrm__Invoice_Over_180__c : 0);

            // returnMap.put('OPEN_INVOICES', accObj.Open_Invoices__c);
            // returnMap.put('INVOICES_NOT_DUE', accObj.Invoices_Not_Due__c);
            // returnMap.put('INVOICES_1_30', accObj.Invoices_1_30__c);
            // returnMap.put('INVOICES_31_60', accObj.Invoices_31_60__c);
        }
        return returnMap;
    }
    public static Map<Object, Object> getAccountName(Map<Object, Object> inMap) {
        Map<Object, Object> returnMap = new Map<Object, Object>();
        String accountId = (String)inMap.get('Id');
        if (!String.isBlank(accountId)) {
            Account accObj = [SELECT Id, Name FROM Account WHERE Id = :accountId LIMIT 1];
            returnMap.put('Id', accObj.Id);
            returnMap.put('Name', accObj.Name);
        }
        return returnMap;
    }
    
    public static Map<Object, Object> getScoreCardDetail(Map<Object, Object> inMap) {
        Map<Object, Object> returnMap = new Map<Object, Object>();
        List<Collection_Priority_Parameter__mdt> scoreCard = [SELECT MasterLabel, Parameter_Name__c, IsActive__c, Weightage__c, Score__c, Definition__c, Order__c FROM Collection_Priority_Parameter__mdt where IsActive__c=true order by Order__c asc LIMIT 10]; //FIN-9251
        if(scoreCard.size() > 0){
            returnMap.put('collectionPriorityConfig',scoreCard);
        }
        String accountId = (String)inMap.get('Id');
        if (!String.isBlank(accountId)) {
            Account accObj = [SELECT Id, Past_Due_Risk__c, Country_Rating_Risk__c, Avg_Days_Of_Delay_Risk__c, Max_Dunning_Performed_Risk__c, Risk__c, Last_Touched_Days_Risk__c, Past_Due_Max_AR_Risk__c FROM Account WHERE Id = :accountId LIMIT 1];
            returnMap.put('Id', accObj.Id);
            returnMap.put('pastDueRisk', accObj.Past_Due_Risk__c != null ? accObj.Past_Due_Risk__c : 0);
            returnMap.put('countryRating', accObj.Country_Rating_Risk__c != null ? accObj.Country_Rating_Risk__c : 0);
            returnMap.put('avgADD', accObj.Avg_Days_Of_Delay_Risk__c != null ? accObj.Avg_Days_Of_Delay_Risk__c : 0);
            returnMap.put('maxDunningPerformed', accObj.Max_Dunning_Performed_Risk__c != null ? accObj.Max_Dunning_Performed_Risk__c : 0);
            returnMap.put('totaScorecard', accObj.Risk__c != null ? accObj.Risk__c : 0);
            returnMap.put('LastTouchedDay', accObj.Last_Touched_Days_Risk__c != null ? accObj.Last_Touched_Days_Risk__c : 0);
            returnMap.put('MaxPastDueAR', accObj.Past_Due_Max_AR_Risk__c != null ? accObj.Past_Due_Max_AR_Risk__c : 0);
        }
        return returnMap;
    }

}