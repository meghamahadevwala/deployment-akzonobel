public class UpdateSegmentDataForAllApprovedCLR implements Database.Batchable<sObject>{
    public String query;
    public List<String> excludeCLRNames;

    //Create Auto Approved Credit Reviews and Update in Source System
    public UpdateSegmentDataForAllApprovedCLR(List<String> excludeCLRNames, Boolean isAdmin) { 
        this.excludeCLRNames = excludeCLRNames; 
        if(isAdmin == true) {
            query = 'SELECT Id, Name, celsrm__Status__c, CreatedDate ' +
                'FROM celsrm__Credit_Review__c ' +
                'WHERE ' + 
                'CreatedById = \'' + UserInfo.getUserId() + '\' ' + 
                'AND celsrm__Status__c IN (\'11\', \'12\', \'40\') ' +
    			'AND Sync_Message__c = null ' +
                'AND celsrm__Synced_In_Source_System_At__c = null';
        } else {
            query = 'SELECT Id, Name, celsrm__Status__c, CreatedDate ' +
                'FROM celsrm__Credit_Review__c ' +
                'WHERE ' + 
                'CreatedById != \'' + UserInfo.getUserId() + '\' ' + 
                'AND celsrm__Status__c IN (\'11\', \'12\', \'40\') ' +
    			'AND Sync_Message__c = null ' +
                'AND celsrm__Synced_In_Source_System_At__c = null';
        }
    }

    public Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext BC, List<celsrm__Credit_Review__c> creditReviews) {
        if(creditReviews.size() > 0) {
            List<String> crIds = new List<String>();
            for(celsrm__Credit_Review__c cr: creditReviews) {
                if(!this.excludeCLRNames.contains(cr.Name)) {
                    crIds.add(cr.Id);
                }
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