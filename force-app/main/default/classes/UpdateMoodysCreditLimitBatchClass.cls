public with sharing class UpdateMoodysCreditLimitBatchClass implements Database.Batchable<sObject>{
    public String query;
    
    public UpdateMoodysCreditLimitBatchClass() {
        query = 'SELECT Id FROM Account ' +
                'WHERE ' +
                'BvD_ID_Number__c != null AND ' +
                'celsrm__App_Name__c = \'Credit\' AND ' +
                'BvD_ID_Number__c != \'\' AND ' +
                'celsrm__Check_Rule__c NOT IN (\'Z01 Risk Class New Customer\', \'Z08 Risk Class Child\') AND ' +
                'celsrm__Credit_Group__c NOT IN (\'0001 - New customer / No score\', \'0007 - IC - Intercompany\', \'0008 - INAC - Inactive Customer\', \'0009 - RPDL - RPDL\', \'0010 - AGY - Agency/Lawyer\', \'0011 - ATR - Atradius\', \'0012 - WRT - Write Off\', \'0013 - BKR - Bankruptcy\', \'0014 - PCC - Pre-pay/Credit Card\',\'0006 - PP - Payment Plan\',\'0016 - CAD - Cadex\', \'0004 - ALA - Legal Action\', \'0005 - EMP - Employee\') AND ' +
                'celsrm__Credit_Group__c != null AND ' +
                'celsrm__Credit_Group__c != \'\' AND ' +
                'Calculated_Credit_Limit_Group_Currency__c > 50000 AND ' +
                'Moody_s_Change_Identified__c = true ' +
                'ORDER BY CurrencyIsoCode, BvD_ID_Number__c';
        // query = 'SELECT Id, Name, CurrencyIsoCode, BvD_ID_Number__c, celsrm__Payment_Behavior__c, celsrm__Payment_Behaviour_Text__c, celsrm__Payment_Behaviour_Trend__c, Recommended_Credit_Limit__c, Expected_Turnover__c, celsrm__Credit_Limit__c, Credit_Exposure__c, Payment_Term_Days__c, celsrm__Check_Rule__c, celsrm__Risk_Class__c, celsrm__Credit_Group__c, Calculated_Credit_Limit_Group_Currency__c, Moody_s_Change_Identified__c FROM Account WHERE BvD_ID_Number__c != null and BvD_ID_Number__c != \'\' AND celsrm__Check_Rule__c NOT IN (\'Z01 Risk Class New Customer\', \'Z08 Risk Class Child\') AND celsrm__Credit_Group__c NOT IN (\'0001 - New customer / No score\', \'0007 - IC - Intercompany\', \'0008 - INAC - Inactive Customer\', \'0009 - RPDL - RPDL\', \'0010 - AGY - Agency/Lawyer\', \'0011 - ATR - Atradius\', \'0012 - WRT - Write Off\', \'0013 - BKR - Bankruptcy\', \'0014 - PCC - Pre-pay/Credit Card\') AND  BvD_ID_Number__c IN (\'DE8010014601\', \'DK55828415\', \'US131759068L\', \'US382252096\', \'SE5561938134\', \'FR353669419\', \'SE5560125220\', \'IT00397130584\', \'NO877270122\', \'SG198500823K\', \'US135240622L\') ORDER BY CurrencyIsoCode, BvD_ID_Number__c';
        // query = 'SELECT Id, Name, CurrencyIsoCode, BvD_ID_Number__c, celsrm__Payment_Behavior__c, celsrm__Payment_Behaviour_Text__c, celsrm__Payment_Behaviour_Trend__c, Recommended_Credit_Limit__c, Expected_Turnover__c, celsrm__Credit_Limit__c, Credit_Exposure__c, Payment_Term_Days__c, celsrm__Check_Rule__c, celsrm__Risk_Class__c, celsrm__Credit_Group__c, Calculated_Credit_Limit_Group_Currency__c, Moody_s_Change_Identified__c FROM Account WHERE BvD_ID_Number__c != null and BvD_ID_Number__c != \'\' AND celsrm__Check_Rule__c NOT IN (\'Z01 Risk Class New Customer\', \'Z08 Risk Class Child\') AND celsrm__Credit_Group__c NOT IN (\'0001 - New customer / No score\', \'0007 - IC - Intercompany\', \'0008 - INAC - Inactive Customer\', \'0009 - RPDL - RPDL\', \'0010 - AGY - Agency/Lawyer\', \'0011 - ATR - Atradius\', \'0012 - WRT - Write Off\', \'0013 - BKR - Bankruptcy\', \'0014 - PCC - Pre-pay/Credit Card\') AND Moody_s_Change_Identified__c = true  ORDER BY CurrencyIsoCode, BvD_ID_Number__c';
    }

    public Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext BC, List<Account> accounts) {
        // << START - MM - FIN-8639 - Credit scores not generated in Sailfin after monitor call>>
        // GetMoodysDataService.GetMoodysData(accounts, false, false);
        List<String> accountsToProcessFinal = new List<String>();
        for(Account acc: accounts) {
            accountsToProcessFinal.add(acc.Id);
        }
        GetMoodysDataService.GetMoodysData(accountsToProcessFinal, false, false);
    }

    public void finish(Database.BatchableContext BC) {
        System.debug('Batch processing finished.');
    }
}