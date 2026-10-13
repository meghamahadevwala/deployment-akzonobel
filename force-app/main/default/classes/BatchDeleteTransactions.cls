global class BatchDeleteTransactions implements Database.Batchable<sObject>{
    // Start
    global Database.QueryLocator start(Database.BatchableContext bc) {
        String query = 'SELECT Id,celsrm__App_Name__c,celsrm__Check_Rule__c,celsrm__Credit_Group__c,celsrm__Limit_Valid_To_Date__c,celsrm__Payment_Behaviour_Text__c,celsrm__Payment_Behaviour_Trend__c,celsrm__Risk_Class__c FROM Account';
        return Database.getQueryLocator(query);
    }
 
    // Execute
    global void execute( Database.BatchableContext bc, List<Account> scope) {    
        List<Account> accountsToUpdate = new List<Account>();
		for (Account acc : scope) {
            System.debug(acc.celsrm__App_Name__c);
        }
    }
    
    // Finish
    global void finish(Database.BatchableContext bc) {
    }
}