global class OneTimeUpdateRecordsBatchable implements Database.Batchable<sObject> { // created to bulk delete records - use with care!
    
   // global final String query;
    
    /*
    global OneTimeUpdateRecordsBatchable(String query) {
        this.query =  query;
    }*/

    // Start
    global Database.QueryLocator start(Database.BatchableContext bc) {
       // String query = 'SELECT Id, Moody_s_Risk_Class__c, Moody_s_Credit_Limit__c FROM Account WHERE Moody_s_Risk_Class__c != null';
       //String query = 'SELECT Id, Name, celsrm__Transaction_Key__c, New_Transaction_Key__c, celsrm__Close_Date__c, celsrm__Debit_Credit_Indicator__c FROM celsrm__Transaction__c WHERE celsrm__Debit_Credit_Indicator__c = \'H\' AND celsrm__Close_Date__c < 2025-03-25';
       
       String query = 'SELECT Id, celsrm__Transaction_Key__c, New_Transaction_Key__c, celsrm__Close_Date__c, celsrm__Debit_Credit_Indicator__c FROM celsrm__Transaction__c WHERE celsrm__Debit_Credit_Indicator__c = \'S\' AND celsrm__Transaction_Key__c LIKE \'%CFIN_CustomerAccountCreditItem_%\'';
       
       return Database.getQueryLocator(query);
        
    }
    
    // Execute
    global void execute( Database.BatchableContext bc, List<celsrm__Transaction__c> scope) {
       for(celsrm__Transaction__c trans: scope) {
            String currentKey = trans.celsrm__Transaction_Key__c;
            String newKey = trans.celsrm__Transaction_Key__c.replace('CustomerAccountCreditItem_', 'CustomerAccountDebitItem_');
            trans.celsrm__Transaction_Key__c = newKey;
        }
        update scope;
        
    }
    
    // Finish
    global void finish(Database.BatchableContext bc) {
    
    }
}