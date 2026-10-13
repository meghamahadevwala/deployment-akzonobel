public with sharing class CalculateImpactedAmountBatch implements Database.Batchable<sObject>, Schedulable {
    public Database.QueryLocator start(Database.BatchableContext context) {
        System.debug('start>>>>>>>');
        try{
             return Database.getQueryLocator([
                SELECT Id, Name
                FROM Account
                WHERE (celsrm__Total_Past_Due__c > 0 OR Disputed_Amount__c > 0 OR celsrm__Total_Broken_Promise_Amount__c > 0 )]);
        } catch (Exception e) {
            System.debug('start ' + e.getMessage());
            return null;
       }
    }

    public void execute(SchedulableContext sc) { 
        Database.executeBatch(new CalculateImpactedAmountBatch(), 1);
    }
    public void execute(Database.BatchableContext context, List<sObject> scope) {
        Map<Id, Account> accountMap = new Map<Id, Account>();
        for (sObject record : scope) {
            Account accountObj = (Account) record;
            accountObj.Impacted_Amount_By_Promise__c = 0;
            accountObj.Impacted_Amount_By_Disputes__c = 0;
            accountObj.Impacted_Amount_By_DPD__c = 0;
            accountMap.put(accountObj.Id, accountObj);
        }
        calculateImpactedAmount(accountMap);
    }

    public void finish(Database.BatchableContext context) {
        
    }
    public void calculateImpactedAmount(Map<Id, Account> accountMap) {
        for (celsrm__Transaction__c tranx : [
            SELECT celsrm__Account__c, Impacted_Amount_Reason__c, Impacted_Amount__c
            FROM celsrm__Transaction__c
            WHERE Impacted_Amount__c != 0 
                AND celsrm__Account__c IN :accountMap.keySet() 
                AND celsrm__Close_Date__c = NULL
            ORDER BY celsrm__Create_Date__c ASC 
            LIMIT 50000
        ]) {
            Id accountId = tranx.celsrm__Account__c;
            String impactReason = tranx.Impacted_Amount_Reason__c;
            Decimal impactedAmount = tranx.Impacted_Amount__c;
            if (!accountMap.containsKey(accountId)) {
                accountMap.put(accountId, new Account(Id = accountId, Impacted_Amount_By_Promise__c = 0, Impacted_Amount_By_Disputes__c = 0, Impacted_Amount_By_DPD__c = 0));
            }
            Account accObj = accountMap.get(accountId);
            if(impactReason == 'Broken Promise') {
                accObj.Impacted_Amount_By_Promise__c += impactedAmount;
            } else if(impactReason == 'Disputed Invoice') {
                accObj.Impacted_Amount_By_Disputes__c += impactedAmount;
            } else if(impactReason == 'Higher DPD') {
                accObj.Impacted_Amount_By_DPD__c += impactedAmount;
            }
            accountMap.put(accountId, accObj);
        }
        system.debug('accountMap:'+accountMap);
        update accountMap.values();
    }
}