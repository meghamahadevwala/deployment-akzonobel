public with sharing class UpdateProfileDataForErroredCLR implements Database.Batchable<sObject>{
    public String query;
    public UpdateProfileDataForErroredCLR() {        
        query = 'SELECT Id, Name, Sync_Profile_Data_In_Source_System_At__c, Sync_Profile_Data_Message__c FROM Account WHERE Sync_Profile_Data_Message__c LIKE \'%Error:%\'';
    }

    public Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext BC, List<Account> accounts) {
        if(accounts.size() > 0) {
            List<String> accIds = new List<String>();
            for(Account acc: accounts) {
                accIds.add(acc.Id);
            }
            if(accIds.size() > 0 && !Test.isRunningTest()){
                UpdateProfileDataInSourceSystemService.updateProfileDataInSAP(accIds);
            }
        }
    }

    public void finish(Database.BatchableContext BC) {
        System.debug('UpdateProfileDataForErroredCLR Batch processing finished.');
    }
}