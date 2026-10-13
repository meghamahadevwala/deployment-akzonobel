global class DeleteRecordsBatchable implements Database.Batchable<sObject> { // created to bulk delete records - use with care!
    
   global final String query;
    
    global DeleteRecordsBatchable(String query) {
       this.query =  query;
    }

    // Start
    global Database.QueryLocator start(Database.BatchableContext bc) {
       return Database.getQueryLocator(this.query);
        
    }
    // Execute
    global void execute( Database.BatchableContext bc, List<celsrm__Transaction__c> scope) {
       delete scope;
        
    }
    // Finish
    global void finish(Database.BatchableContext bc) {
    
    }
}