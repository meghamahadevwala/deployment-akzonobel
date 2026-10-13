global class CreditFieldsMigrationTemp implements Database.Batchable<sObject>{
    // Start
    global Database.QueryLocator start(Database.BatchableContext bc) {
        // String query = 'SELECT Id,App_Name__c,celsrm__App_Name__c,Check_Rule__c,celsrm__Check_Rule__c,Credit_Group__c,celsrm__Credit_Group__c,Limit_Valid_To_Date__c,celsrm__Limit_Valid_To_Date__c,Payment_Behaviour__c,celsrm__Payment_Behaviour_Text__c,Payment_Behaviour_Trend__c,celsrm__Payment_Behaviour_Trend__c,Risk_Class__c,celsrm__Risk_Class__c FROM Account WHERE App_Name__c = \'Credit\'';
        String query = 'SELECT Id, celsrm__Credit_Group__c, celsrm__Risk_Class__c, celsrm__Synced_In_Source_System_At__c FROM celsrm__Credit_Review__c';
        return Database.getQueryLocator(query);
    }
 
    // Execute
    global void execute( Database.BatchableContext bc, List<celsrm__Credit_Review__c> scope) {    
		for (celsrm__Credit_Review__c clr : scope) {
            System.debug(clr.celsrm__Credit_Group__c);
        }
        // update scope;
    }
    
    // Finish
    global void finish(Database.BatchableContext bc) {
    }
}