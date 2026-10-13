global with sharing class SemiAutoDunningBatch implements Database.Batchable<Object>, Database.Stateful{
    
    List<Id> automatedTasksToClose = new List<Id>();
    String selectedLocale = '';
    String emailSubject = '';
    String emailTemplateBody = '';
    public String trxnId {get; set; }
    public set<ID> TaskIdFromPreviousSc= new set<Id>();
    public String AttachType{get;set;}
    public List<object> Taskobjlt;
    public Map<id, Task> mapTaskObj;
    List<Object> obj;
    String ListView;    
    
    global SemiAutoDunningBatch(List<object> obj,String attachTypes, String ListView ){
        AttachType = attachTypes;
        this.obj = obj;
        this.ListView = ListView;
    }
    
    global List<Object> start(Database.BatchableContext bc){
        return obj;
    }
    
    global void execute(Database.BatchableContext bc, List<Object> sObjs){
        trxnId= '';
        celsrm__Custom_List_View__c customListViewObj = new celsrm__Custom_List_View__c();
        customListViewObj = [Select Id, Name, celsrm__ListView_For_Object__c, celsrm__Object_Fields__c, celsrm__Filter_Criteria__c From celsrm__Custom_List_View__c Where Id = :ListView limit 1];
        String selectedFields = '';
        if( customListViewObj != null && customListViewObj.celsrm__Object_Fields__c != null && customListViewObj.celsrm__Object_Fields__c != ''){
            selectedFields = UtilityController.getQueryFields(customListViewObj.celsrm__Object_Fields__c, customListViewObj.celsrm__ListView_For_Object__c);
        }
        for (Object ts : sObjs) {
            Map<Object, Object> automatedTask = (Map<Object, Object>)ts;
            id key= (Id)automatedTask.get('WhatId');
            String whereCondition = '';
            if(customListViewObj != null && customListViewObj.celsrm__Filter_Criteria__c != '') {
                whereCondition = UtilityController.getQueryWhereClause(customListViewObj.celsrm__Filter_Criteria__c);
            }
            if(whereCondition != '') {
                whereCondition += ' and celsrm__account__c = '+ '\'' + key + '\'' +' limit 700 ';
            } else if(whereCondition == '') {
                whereCondition = ' celsrm__balance__c !=0 and celsrm__account__c = '+ '\'' + key + '\'' +'  limit 700'; 
            } 
            List<celsrm__Transaction__c> lstTrans = UtilityController.getTransactionList(selectedFields,whereCondition);
            Map<id,celsrm__Transaction__c>  trxMap= new Map<id,celsrm__Transaction__c>();
            for(celsrm__Transaction__c trnsObj : lstTrans){
                trxMap.put(trnsObj.Id, trnsObj);
            }
            
            celsrm__Temp_Object_Holder__c temp = new celsrm__Temp_Object_Holder__c();
            temp.celsrm__key__c =  Userinfo.getUserName()+Datetime.now().getTime();
            set<Id> temptxIds = trxMap.KeySet();
            List<Id> idList = new List<Id>();
            idList.addAll(temptxIds);
            temp.celsrm__value__c =string.join(idList,',');          
            insert Temp; 
             Map<String,String> returnTemplateAmount = UtilityController.getTransactionTotalSummary(key,idList);           
            System.enqueueJob(new GenerateDunningPDF (automatedTask,temp.Id,AttachType,ListView ,returnTemplateAmount ));
        }
    }
    
    global void finish(Database.BatchableContext bc){
        
    }
}