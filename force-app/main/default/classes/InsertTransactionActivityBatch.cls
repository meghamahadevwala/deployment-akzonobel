//-- Start | FIN-8209 | Changed By Dilshad/Asera | 13-Aug-2025 --//
public with sharing class InsertTransactionActivityBatch implements Database.Batchable<Object>, Database.Stateful{
    List<String> sObjectIds = new List<String>();
    String sObjectName = '';
    String activityName = '';
    Datetime currentDateTime;
    Map<String, Object> additionalFields = new Map<String, Object>();
    Map<Id, Map<String, Object>> transactionFieldMap = new Map<Id, Map<String, Object>>();
    public InsertTransactionActivityBatch(List<String> sObjectIds, String sObjectName, String activityName, Datetime currentDateTime, Map<String, Object> additionalFields, Map<Id, Map<String, Object>> transactionFieldMap) {
        this.sObjectIds = sObjectIds;
        this.sObjectName = sObjectName;
        this.activityName = activityName;
        this.currentDateTime = currentDateTime;
        this.additionalFields = additionalFields;
        this.transactionFieldMap = transactionFieldMap;
    }

    public Database.QueryLocator start(Database.BatchableContext BC) {
        String baseQuery = 'SELECT Id FROM '+sObjectName+' WHERE Id IN: sObjectIds';
        return Database.getQueryLocator(baseQuery);
    }

    public void execute(Database.BatchableContext BC, List<Object> recordList) {
        List<String> recordIds = new List<String>();
        for (celsrm__Transaction__c rec : (List<celsrm__Transaction__c>)recordList) {
            recordIds.add((String)rec.get('Id'));
        }
        celsrm.SRMUtilityController.insertActivity(recordIds, sObjectName, activityName, currentDateTime, 100, null, UserInfo.getUserId(), null, 'Internal', null, transactionFieldMap);
    }

    public void finish(Database.BatchableContext context) {  
    }
//-- End | FIN-8209 | Changed By Dilshad/Asera | 13-Aug-2025 --//
}