global with sharing class GoGFetchFromAdress implements celsrm.GOGIScreenCustomLogic {

    global Map < Object, Object > invoke(String functionName, Map < Object, Object > inMap) {
    
    
        //System.debug('@@ inMap : ' + inMap.containsKey('activityData'));
        System.debug('@@ inMap : ' + ((Map<Object, Object>)inMap.get('activityData')));
        System.debug('@@ inMap 123: ' + inMap.keySet());
        List < Id > accIds = new List < Id > ();
        String sortfieldName = null;
        String sortOrder = null;
        if (inMap.get('TransactionList_SortColumn') != null && inMap.get('TransactionList_SortOrder') != null) {
            sortfieldName = String.valueOf(inMap.get('TransactionList_SortColumn'));
            sortOrder = String.valueOf(inMap.get('TransactionList_SortOrder'));
            if(Schema.SObjectType.celsrm__Transaction__c.fields.getMap().get(sortfieldName).getDescribe().getType() == Schema.DisplayType.TextArea) {
                sortfieldName = null;
                sortOrder = null;
            }
        }
        //By Ravi | 12-02-2020 | user preference
        String currentUser = UserInfo.getUserId();
        celsrm__User_Preference__c userPref  = new celsrm__User_Preference__c();
        try {
            userPref = [SELECT Id,celsrm__SortListViewField__c,celsrm__SortListViewOrderType__c FROM celsrm__User_Preference__c WHERE celsrm__User__c =:currentUser LIMIT 1];
        } catch (Exception e) {
            System.debug('exception>> ' + e.getMessage());
        }
        if (sortfieldName == null && sortOrder == null && userPref.celsrm__SortListViewField__c != null && userPref.celsrm__SortListViewOrderType__c != null) {
            sortfieldName = String.valueOf(userPref.celsrm__SortListViewField__c);
            sortOrder = String.valueOf(userPref.celsrm__SortListViewOrderType__c);
            if(Schema.SObjectType.celsrm__Transaction__c.fields.getMap().get(sortfieldName).getDescribe().getType() == Schema.DisplayType.TextArea) {
                sortfieldName = null;
                sortOrder = null;
            }
        }
        
        //By Ravi | 12-02-2020 | user preference
        map<string,object> tempComposeEmail = (map<string,object>)JSON.deserializeUntyped(JSON.serialize(inMap.get('ComposeEmail')));
        system.debug('tempComposeEmail >>>'+tempComposeEmail );
        system.debug('body>>>'+tempComposeEmail.get('body'));
        id parentId = null;
        if (inMap.containsKey('Id') && inMap.get('Id') != null) {
            parentId = (Id) inMap.get('Id');
            accIds.add(parentId);
            system.debug('parentId>>' + parentId);
        }
        Map < String, List < String >>  returnMap = new  Map < String, List < String >>  ();
        returnMap = UtilityController.fetchFromEmails();
        
        Map < Object, Object > returnValue = new Map < Object, Object > ();
        if (returnMap != null && returnMap.get('from') != null) {
            List < string > tempst = returnMap.get('from');
            
            returnValue.put('from', (Id) tempst.get(0));
            system.debug('tempst >>' + returnValue);
            
        }
        if(inMap.containsKey('activityData') && ((Map<Object, Object>)inMap.get('activityData')).get('celsrm__Category__c') != null){
            system.debug('Category>>' + (String)inMap.get('celsrm__Category__c'));
            String Category=  (String)((Map<Object, Object>)inMap.get('activityData')).get('celsrm__Category__c');
            
            Category = Category.stripHtmlTags();
            system.debug('Category>>' + Category);
            if(Category == 'Statement'){
                List<Id> TransIds = new List<Id>();
                inMap= ActivityDefaultTemplate(inMap,'celsrm__Transaction__c','All Open',(Id) inMap.get('Id'),'Billing statement',Category);
                for (celsrm__Transaction__c obj : (List<celsrm__Transaction__c>)inMap.get('TransactionList')) { 
                    TransIds.add(obj.Id);
                }
                
                // EmailTemplate billingTemplateList = [select id, Name, FolderId, Subject, HtmlValue, TemplateType, Body from EmailTemplate where Folder.Name != null and Folder.Name=:  (String)inMap.get('Locale__c')  and IsActive=true and Name='Billing statement'];
                    celsrm__Temp_Object_Holder__c temp = new celsrm__Temp_Object_Holder__c();
                if(!TransIds.isEmpty()){
                    temp.celsrm__key__c =  Userinfo.getUserName()+Datetime.now().getTime();
                    temp.celsrm__value__c =string.join(TransIds,',');
                    system.debug(temp.celsrm__value__c);            
                    insert Temp;
                    inMap.put('tempKey',Temp.Id);
                }        
        
                // Messaging.SingleEmailMessage message = Messaging.renderStoredEmailTemplate(billingTemplateList.id, null, (Id) inMap.get('Id'));
                String returnTemplateBody = (String)inMap.get('TempBody');
                //-- Start | FIN-8334 | Changed by Ravi | 11 sep 2025 --//
                if (returnTemplateBody.Contains('{Transactions.TotalBalance}')) {
                    Map<String,String> returnTemplateAmount = UtilityController.getTransactionTotalSummary((String)inMap.get('Id'),TransIds);
                    inMap.put('returnTemplateAmount', returnTemplateAmount);
                    // returnTemplateBody = returnTemplateBody.replace('{Transactions.TotalBalance}', returnTemplateAmount.get('TotalBalance')).replace('{Transactions.TotalBalanceWithoutCurrency}', returnTemplateAmount.get('TotalBalanceWithoutCurrency')).replace('{Transactions.TotalBalanceSummary}', returnTemplateAmount.get('TotalBalanceSummary'));
                    returnTemplateBody = returnTemplateBody.replace('{Transactions.TotalBalance}', returnTemplateAmount.get('TotalBalance'));
                }
                //-- End | FIN-8334 | Changed by Ravi | 11 sep 2025 --//
                          
                String htmlBody = UtilityController.getTransactionListViewData((Id)inMap.get('customListViewObj') ,TransIds,false,sortfieldName,sortOrder);
                returnTemplateBody = returnTemplateBody.replace('{Transaction.Summary}', htmlBody);
                
                    system.debug('returnTemplateBody>>>'+returnTemplateBody);
                String Tempbody = returnTemplateBody+'\n'+tempComposeEmail.get('body') ;
                returnValue.put('body',Tempbody );
            } else if(Category == 'Dispute'){
                try{
                    inMap= ActivityDefaultTemplate(inMap,'celsrm__Dispute__c','All Open',(Id) inMap.get('Id'),'Dispute_Escalated_Notification',Category);
                    
                    String returnTemplateBody = (String)inMap.get('TempBody');
                    system.debug('returnTemplateBody>>>'+returnTemplateBody);
                    GOGCustomEmailSend cusEmail = new GOGCustomEmailSend();
                    
                    String htmlBody = cusEmail.getTemplateSummaryDispute(inMap);
                    system.debug('htmlBody>>>'+htmlBody);
                    returnTemplateBody = returnTemplateBody.replace('{Disputes.summary}', htmlBody);
                
                    system.debug('returnTemplateBody>>>'+returnTemplateBody);
                    String Tempbody = returnTemplateBody+'\n'+tempComposeEmail.get('body') ;
                    returnValue.put('body',Tempbody );
                }catch(exception e) {
                    Throw e;
                }
            } else if(Category == 'Promised'){
                List<Id> TransIds = new List<Id>();
                inMap= ActivityDefaultTemplate(inMap,'celsrm__Transaction__c','All Open',(Id) inMap.get('Id'),'Promise To Pay Filed',Category);
                for (celsrm__Transaction__c obj : (List<celsrm__Transaction__c>)inMap.get('TransactionList')) { 
                    TransIds.add(obj.Id);
                }
                
                // EmailTemplate billingTemplateList = [select id, Name, FolderId, Subject, HtmlValue, TemplateType, Body from EmailTemplate where Folder.Name != null and Folder.Name=:  (String)inMap.get('Locale__c')  and IsActive=true and Name='Billing statement'];
                celsrm__Temp_Object_Holder__c temp = new celsrm__Temp_Object_Holder__c();
                if(!TransIds.isEmpty()){
                    temp.celsrm__key__c =  Userinfo.getUserName()+Datetime.now().getTime();
                    temp.celsrm__value__c =string.join(TransIds,',');
                    system.debug(temp.celsrm__value__c);            
                    insert Temp;
                    inMap.put('tempKey',Temp.Id);
                }        
    
                // Messaging.SingleEmailMessage message = Messaging.renderStoredEmailTemplate(billingTemplateList.id, null, (Id) inMap.get('Id'));
                String returnTemplateBody = (String)inMap.get('TempBody');
                //-- Start | FIN-8334 | Changed by Ravi | 11 sep 2025 --//
                if (returnTemplateBody.Contains('{Transactions.TotalBalance}')) {
                    Map<String,String> returnTemplateAmount = UtilityController.getTransactionTotalSummary((String)inMap.get('Id'),TransIds);
                    inMap.put('returnTemplateAmount', returnTemplateAmount);
                    // returnTemplateBody = returnTemplateBody.replace('{Transactions.TotalBalance}', returnTemplateAmount.get('TotalBalance')).replace('{Transactions.TotalBalanceWithoutCurrency}', returnTemplateAmount.get('TotalBalanceWithoutCurrency')).replace('{Transactions.TotalBalanceSummary}', returnTemplateAmount.get('TotalBalanceSummary'));
                    returnTemplateBody = returnTemplateBody.replace('{Transactions.TotalBalance}', returnTemplateAmount.get('TotalBalance'));
                }
                //-- End | FIN-8334 | Changed by Ravi | 11 sep 2025 --//
        
                // returnTemplateBody= UtilityController.getTransactionTotalSummary((String)inMap.get('Id'),TransIds,returnTemplateBody);
        
                String htmlBody = UtilityController.getTransactionListViewData((Id)inMap.get('customListViewObj') ,TransIds,false,sortfieldName,sortOrder);
                returnTemplateBody = returnTemplateBody.replace('{Promise.Summary}', htmlBody);
            
                system.debug('returnTemplateBody>>>'+returnTemplateBody);
                String Tempbody = returnTemplateBody+'\n'+tempComposeEmail.get('body') ;
                returnValue.put('body',Tempbody );
            }
        }
            
        return returnValue;

    }
    
    public static Map<Object, Object> ActivityDefaultTemplate(Map<Object, Object> inMap,String ObjectName,String viewName,Id AccountId,String TemplateName,String Category){
            celsrm__Custom_List_View__c customListViewObj = new celsrm__Custom_List_View__c();
             customListViewObj = [Select Id, Name, celsrm__Object_Fields__c, celsrm__Filter_Criteria__c,celsrm__ListView_For_Object__c From celsrm__Custom_List_View__c Where Name =:viewName and celsrm__ListView_For_Object__c =:ObjectName limit 1];
                String selectedFields = '';
                if( customListViewObj != null && customListViewObj.celsrm__Object_Fields__c != null && customListViewObj.celsrm__Object_Fields__c != ''){
                    selectedFields = UtilityController.getQueryFields(customListViewObj.celsrm__Object_Fields__c, ObjectName);
                }
              
                    
                    id key=  AccountId ;
                    List<Id> TransIds = new List<Id>();
                    String htmlBody;
                    system.debug('==key==='+key);
                    String whereCondition = '  ';
                    if(customListViewObj != null && customListViewObj.celsrm__Filter_Criteria__c != '') {
                        whereCondition = UtilityController.getQueryWhereClause(customListViewObj.celsrm__Filter_Criteria__c);
                    }
                    system.debug('==whereCondition==='+whereCondition);
                    if(whereCondition != '') {
                        if(Category =='Promise'){
                         whereCondition += ' and celsrm__Promised_Amount__c > 0 and Promise_Date__c != null ';
                        }
                        whereCondition += ' and celsrm__account__c = :key limit 5000 ';
                    } else if(whereCondition == '') {
                        if(Category =='Promise'){
                         whereCondition += ' celsrm__Promised_Amount__c > 0 and Promise_Date__c != null and ';
                        }
                        whereCondition = ' celsrm__balance__c !=0 and celsrm__account__c =:key  limit 5000 '; 
                    }
                    system.debug('==whereCondition 1 ==='+whereCondition);
                       List<string> formatedFieldName =UtilityController.getTransactionFieldformat(selectedFields.split(','),ObjectName);
                      String Queryfields = string.join(formatedFieldName,',');
                     String stringToQuery = 'Select Id,'+ Queryfields + ' from '+ObjectName +  whereCondition;
                    if(ObjectName =='celsrm__Dispute__c'){
                        list<celsrm__Dispute__c> lstTrans = database.query(stringToQuery);
                        inMap.put('DisputeList',lstTrans);
                        //inMap.put('SummaryFields',Queryfields);
                     }else{
                        list<celsrm__Transaction__c> lstTrans = database.query(stringToQuery);
                        inMap.put('TransactionList',lstTrans);
                        
                     }
                     inMap.put('SummaryFields',selectedFields);
        			EmailTemplate billingTemplateList;
                    if(Test.isRunningTest()) {
                        billingTemplateList = [select id, Name, FolderId, Subject, HtmlValue, TemplateType, Body from EmailTemplate Limit 1];
                    } else {
                        billingTemplateList = [select id, Name, FolderId, Subject, HtmlValue, TemplateType, Body from EmailTemplate where Folder.Name != null and Folder.Name=:  (String)inMap.get('Locale__c')  and IsActive=true and Name=:TemplateName];
                    }   
        
                    Messaging.SingleEmailMessage message = Messaging.renderStoredEmailTemplate(billingTemplateList.id, null, (Id) inMap.get('Id'));
                    String returnTemplateBody = message.getHtmlBody();
                    system.debug('returnTemplateBody>>>'+returnTemplateBody);
                    inMap.put('TempBody',returnTemplateBody);
                    inMap.put('customListViewObj',customListViewObj.Id);
                    
                    return inMap;
                }
}