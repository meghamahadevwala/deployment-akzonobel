/**
 * Ticket #948 follow-up: powers the "Deteriorated Accounts" LWC.
 * Returns Account Number, current Moody's Risk Class, and current Moody's
 * Credit Limit for every account whose Credit Score Comparison Flag is
 * 'Deterioration'.
 */
public with sharing class DeterioratedAccountsController {

    public class DeterioratedAccountWrapper {
        @AuraEnabled public Id accountId;
        @AuraEnabled public String accountNumber;
        @AuraEnabled public String moodysRiskClass;
        @AuraEnabled public Decimal moodysCreditLimit;
    }

    @AuraEnabled(cacheable=true)
    public static List<DeterioratedAccountWrapper> getDeterioratedAccounts() {
        List<DeterioratedAccountWrapper> results = new List<DeterioratedAccountWrapper>();

        for (Account acc : [
            SELECT Id, AccountNumber, Moody_s_Risk_Class__c, Moody_s_Credit_Limit__c
            FROM Account
            WHERE Credit_Score_Comparison_Flag__c = 'Deterioration'
            ORDER BY AccountNumber
        ]) {
            DeterioratedAccountWrapper w = new DeterioratedAccountWrapper();
            w.accountId = acc.Id;
            w.accountNumber = acc.AccountNumber;
            w.moodysRiskClass = acc.Moody_s_Risk_Class__c;
            w.moodysCreditLimit = acc.Moody_s_Credit_Limit__c;
            results.add(w);
        }

        return results;
    }
}