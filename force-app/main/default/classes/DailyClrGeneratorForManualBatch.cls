public with sharing class DailyClrGeneratorForManualBatch implements Database.Batchable<sObject>{
    public String query;

    public DailyClrGeneratorForManualBatch() {
        query = 'SELECT Id, Name,celsrm__Total_AR__c, celsrm__Credit_Group__c , ' +
                'Expected_Turnover__c, celsrm__Risk_Class__c, celsrm__Credit_Limit__c, ' +
                'Credit_Exposure__c, CurrencyIsoCode, Recommended_Credit_Limit__c, ' +
                'celsrm__Limit_Valid_To_Date__c, BvD_ID_Number__c, Moody_s_Credit_Limit__c, ' +
                'celsrm__Payment_Behaviour_Text__c, celsrm__Payment_Behaviour_Trend__c, Payment_Term_Days__c, celsrm__Check_Rule__c, Calculated_Credit_Limit_Group_Currency__c, Region__c ' + 
                'FROM Account ' +
                'WHERE ' +
                'Is_Snoozed__c = false AND '+
                'Calculated_Credit_Limit_Group_Currency__c > 50000 AND ' +
                'Is_Recommended_CL_More_Than_Moody_s_CL__c = true AND ' +
                'Is_Recommended_CL_More_Than_Credit_Limit__c = true AND ' +
                'celsrm__Check_Rule__c NOT IN (\'Z01 Risk Class New Customer\', \'Z08 Risk Class Child\') AND ' +
                'celsrm__Credit_Group__c NOT IN (\'0001 - New customer / No score\', \'0006 - PP - Payment Plan\', \'0007 - IC - Intercompany\', \'0008 - INAC - Inactive Customer\', \'0009 - RPDL - RPDL\', \'0010 - AGY - Agency/Lawyer\', \'0011 - ATR - Atradius\', \'0012 - WRT - Write Off\', \'0013 - BKR - Bankruptcy\', \'0014 - PCC - Pre-pay/Credit Card\') AND ' +
                'Collateral_Amount__c <= 0 AND Insurance_Amount__c <= 0 AND ' +
                'Credit_Utilization_AkzoNobel__c > 70';
    }

    public Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext BC, List<Account> accounts) {
        //START - Identify the accounts for which open CLR exists
        List<Id> accIds = new List<Id>();
        for(Account acc : accounts) {
            accIds.add(acc.Id);
        }
        List<String> openCrStatus = new List<String>{'10', '15', '20', '21', '22', '23', '24'};
        List<celsrm__Credit_Review__c> existingCreditReviews = [SELECT Id, celsrm__Account__c  FROM celsrm__Credit_Review__c WHERE celsrm__Account__c IN :accIds AND celsrm__Status__c IN :openCrStatus];
        List<Id> excludeAccounts = new List<Id>();
        for (celsrm__Credit_Review__c cr : existingCreditReviews) {
            excludeAccounts.add(cr.celsrm__Account__c);
        }
        //END - Identify the accounts for which open CLR exists

        //START - Exclude Account for which CLR is approved but not updated in CFIN
        List<String> approvedCrStatus = new List<String>{'40', '11', '12'};
        List<celsrm__Credit_Review__c> existingApprovedUnsynced = [SELECT Id, celsrm__Account__c  FROM celsrm__Credit_Review__c WHERE celsrm__Account__c IN :accIds AND celsrm__Status__c IN :approvedCrStatus AND celsrm__Synced_In_Source_System_At__c = null];
        for (celsrm__Credit_Review__c cr : existingApprovedUnsynced) {
            excludeAccounts.add(cr.celsrm__Account__c);
        }
        //END - Exclude Account for which CLR is approved but not updated in CFIN

        List<celsrm__Credit_Review__c> crToBeInserted = new List<celsrm__Credit_Review__c>();
        // << START - MM - FIN-8639 - Credit scores not generated in Sailfin after monitor call>>
        // List<Account> accountsToProcess = new List<Account>();
        List<String> accountsToProcess = new List<String>();
        // << END - MM - FIN-8639 - Credit scores not generated in Sailfin after monitor call>>
        for(Account acc : accounts) {
            if(!excludeAccounts.contains(acc.Id)) {
                if(acc.BvD_ID_Number__c != null && acc.BvD_ID_Number__c != '') {
                    // << START - MM - FIN-8639 - Credit scores not generated in Sailfin after monitor call>>
                    // accountsToProcess.add(acc);
                    accountsToProcess.add(acc.Id);
                    // << END - MM - FIN-8639 - Credit scores not generated in Sailfin after monitor call>>
                } else {
                    celsrm__Credit_Review__c creditReviewObj = new celsrm__Credit_Review__c();
                    creditReviewObj.celsrm__Account__c = acc.Id;
                    creditReviewObj.BvD_ID_Number__c  = acc.BvD_ID_Number__c;
                    creditReviewObj.celsrm__Recommended_Credit_Limit__c = acc.Recommended_Credit_Limit__c;
                    creditReviewObj.celsrm__Requested_Credit_Limit__c = acc.Recommended_Credit_Limit__c;
                    creditReviewObj.Requested_Credit_Limit_EUR__c = acc.Calculated_Credit_Limit_Group_Currency__c;
                    creditReviewObj.celsrm__System_Credit_Limit__c = acc.celsrm__Credit_Limit__c;
                    creditReviewObj.Account_Region__c = acc.Region__c;
                    creditReviewObj.celsrm__Status__c = '10';
                    creditReviewObj.celsrm__Model_Type__c = 'Recalculation';
                    String creditGroup = acc.celsrm__Credit_Group__c;
                    if(creditGroup != null) {
                        List<String> parts = creditGroup.split(' - ', 2);
                        if(parts.size() > 1) {
                            creditGroup = parts[1];
                        }
                    }
                    creditReviewObj.celsrm__Credit_Group__c = creditGroup;
                    creditReviewObj.Moody_s_Credit_Limit__c = acc.Moody_s_Credit_Limit__c;
                    creditReviewObj.Expected_Turnover__c = acc.Expected_Turnover__c;
                    String riskClass = acc.celsrm__Risk_Class__c;
                    if(riskClass != null) {
                        List<String> parts = riskClass.split(' - ', 2);
                        if(parts.size() > 1) {
                            riskClass = parts[1];
                        }
                    }
                    creditReviewObj.celsrm__Risk_Class__c = riskClass;
                    creditReviewObj.Credit_Limit__c = acc.celsrm__Credit_Limit__c;
                    creditReviewObj.Credit_Exposure__c = acc.Credit_Exposure__c ;
                    creditReviewObj.Payment_Terms_Days__c = acc.Payment_Term_Days__c;
                    creditReviewObj.CurrencyIsoCode = acc.CurrencyIsoCode ;
                    Date validToDate = Date.today().addDays(365);
                    creditReviewObj.Requested_Valid_To_Date__c = validToDate;
                    // creditReviewObj.Approved_Valid_To_Date__c = validToDate;
                    // creditReviewObj.celsrm__Approved_Credit_Limit__c = acc.Recommended_Credit_Limit__c;
                    creditReviewObj.celsrm__Notes__c = 'Auto Generated Credit Limit Request for Manual Approval';
                    crToBeInserted.add(creditReviewObj);   
                }
            }
        }
        if(crToBeInserted.size() > 0){
            insert crToBeInserted;
        }
        if(accountsToProcess.size() > 0) {
            GetMoodysDataService.GetMoodysData(accountsToProcess, true, false);
        }
    }

    public void finish(Database.BatchableContext BC) {
        System.debug('DailyClrGeneratorForManualBatch - Batch processing finished.');
        if(!Test.isRunningTest()) {
            // UpdateSegmentDataForAutoApprovedCLR batch = new UpdateSegmentDataForAutoApprovedCLR();
            // Database.executeBatch(batch, 20);
        }
    }
}