public class UndeleteTransactionsBatch implements Database.Batchable<sObject> {

    // Define the date filter
    private DateTime deletedAfter;

    // Constructor to pass the date filter
    public UndeleteTransactionsBatch(DateTime deletedAfter) {
        this.deletedAfter = deletedAfter;
    }

    // Start method - query the records to undelete
    public Database.QueryLocator start(Database.BatchableContext bc) {
        // Query to retrieve the deleted records based on the deletedAfter filter
        String query = 'SELECT Id, celsrm__Transaction_Key__c FROM celsrm__Transaction__c ' +
                       'WHERE IsDeleted = TRUE ' +
                       'AND LastModifiedDate >= :deletedAfter ' +
                       'AND SystemModstamp != NULL ' +
                       'ALL ROWS';
        return Database.getQueryLocator(query);
    }

    // Execute method - undelete the records
    public void execute(Database.BatchableContext bc, List<sObject> scope) {
        List<celsrm__Transaction__c> transactionsToUndelete = new List<celsrm__Transaction__c>();
        
        // Collect all the Transaction Keys from the deleted records
        Set<String> transactionKeysToCheck = new Set<String>();
        for (sObject obj : scope) {
            celsrm__Transaction__c trans = (celsrm__Transaction__c) obj;
            transactionKeysToCheck.add(trans.celsrm__Transaction_Key__c);
        }

        // Query for existing records with the same Transaction Keys
        Map<String, celsrm__Transaction__c> existingRecordsMap = new Map<String, celsrm__Transaction__c>();
        for (celsrm__Transaction__c existing : [ 
            SELECT Id, celsrm__Transaction_Key__c 
            FROM celsrm__Transaction__c 
            WHERE celsrm__Transaction_Key__c IN :transactionKeysToCheck
        ]) {
            existingRecordsMap.put(existing.celsrm__Transaction_Key__c, existing);
        }

        // Filter out the records that have already been created as new ones (same Transaction Key)
        for (sObject obj : scope) {
            celsrm__Transaction__c trans = (celsrm__Transaction__c) obj;
            if (!existingRecordsMap.containsKey(trans.celsrm__Transaction_Key__c)) {
                transactionsToUndelete.add(trans);
            }
        }

        // Undelete the records that are not recreated
        if (!transactionsToUndelete.isEmpty()) {
            undelete transactionsToUndelete;
        }
    }

    // Finish method - optional for logging or notifications
    public void finish(Database.BatchableContext bc) {
        // Optionally, add any finishing logic, like logging or notifying
        System.debug('Batch process completed for undeleting transactions.');
    }
}