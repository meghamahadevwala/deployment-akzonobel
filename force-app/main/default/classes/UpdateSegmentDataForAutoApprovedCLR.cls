public class UpdateSegmentDataForAutoApprovedCLR implements Database.Batchable<sObject>{
    public String query;

    //Create Auto Approved Credit Reviews and Update in Source System
    public UpdateSegmentDataForAutoApprovedCLR() {        
        query = 'SELECT Id, Name, celsrm__Status__c, CreatedDate ' +
                'FROM celsrm__Credit_Review__c ' +
                'WHERE CreatedDate = TODAY ' + 
                'AND CreatedById = \'' + UserInfo.getUserId() + '\' ' + 
                'AND celsrm__Status__c IN (\'11\', \'12\') ' +
    			'AND Sync_Message__c = null ' +
                'AND celsrm__Synced_In_Source_System_At__c = null';


    }

    public Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext BC, List<celsrm__Credit_Review__c> creditReviews) {
        if(creditReviews.size() > 0) {
            List<String> crIds = new List<String>();
            for(celsrm__Credit_Review__c cr: creditReviews) {
                crIds.add(cr.Id);
            }
            if(crIds.size() > 0 && !Test.isRunningTest()){
                UpdateLimitInSourceSystemService.updateCreditLimitInSAP(crIds);
            }
        }
    }

    public void finish(Database.BatchableContext BC) {
        System.debug('Batch processing finished.');
    }
}