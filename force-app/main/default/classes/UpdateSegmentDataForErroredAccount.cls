public with sharing class UpdateSegmentDataForErroredAccount implements Database.Batchable<sObject>{
    public String query;
    public UpdateSegmentDataForErroredAccount() {        
        query = 'SELECT Id, Name, Sync_Segment_Info_In_CFIN_At__c, Sync_Segment_Info_In_CFIN_Message__c FROM Account WHERE Sync_Segment_Info_In_CFIN_Message__c LIKE \'%Error:%\' OR Sync_Segment_Info_In_CFIN_Message__c LIKE \'%Exception occured:%\'';
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
                UpdateBlockInSourceSystemService.updateBlockInSAP(accIds);
            }
        }
    }

    public void finish(Database.BatchableContext BC) {
        System.debug('UpdateSegmentDataForErroredAccount Batch processing finished.');
    }
}