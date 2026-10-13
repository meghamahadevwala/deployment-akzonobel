global with sharing class composeEmailCustom implements celsrm.EmailTemplateCustomLogicInterface {
    global static Map<String, Object> invoke(Map<Object, Object> currentValues, Id templateId, Map<String,Object> mapOfExtraParam, String functionName){
        Map<String, Object> returnVal = new Map<String, Object>();
        if(functionName == 'GoGCustomEmailSendToAndCc') {
            returnVal = setPreFatchEmailValue(currentValues);
        } else if (functionName == 'composeEmailCustom') {
            returnVal = setDataFormattingForEmail(currentValues,templateId,mapOfExtraParam, functionName);
        } else if (functionName == 'setDataFormattingForTreatment') {
            // by Sejal 10/06/2024 | data formatting for send email from task detail page
            returnVal = setDataFormattingForTreatment(currentValues, templateId,mapOfExtraParam, functionName);
        //-- FIN-9729 | Changed by Dilshad | 04-May-2026 | Start --//
        // configure this method on compose email component as Formatting Method
        } else if (functionName == 'updateComposeEmailBody') {
            returnVal = updateComposeEmailBody(currentValues, templateId, mapOfExtraParam, functionName);
        }
        //-- FIN-9729 | Changed by Dilshad | 04-May-2026 | End --//
        return returnVal ;
    }

    // Start Pre Fatch class //Test Deployment
    public static Map<String, Object> setPreFatchEmailValue(Map<Object, Object> currentValues) {

        Map<String, Object> returnVal = new Map<String, Object>();
        String namespace = UtilityController.getPackageNamespacePrefix();
        // Start Pre fatch class Data
        List < Id > accIds = new List < Id > ();
        //-- Starts | FIN-6130 | Changed by Dilshad | 29 Jun 2024 --//
        String sObjName;
        //-- Ends | FIN-6130 | Changed by Dilshad | 29 Jun 2024 --//
        String accountId = '';
        List<Task> taskList = new List<Task>();
        Boolean isTask = false;
        Id recordId = null;
        if (currentValues.containsKey('Id') && currentValues.get('Id') != null) {
            recordId = (Id)currentValues.get('Id');
            //-- Starts | FIN-6130 | Changed by Dilshad | 29 Jun 2024 --//
            sObjName = recordId.getSObjectType().getDescribe().getName();
            //-- Ends | FIN-6130 | Changed by Dilshad | 29 Jun 2024 --//
          
            if(sObjName == 'celsrm__Transaction__c') {
                if(currentValues.get('celsrm__Account__c') != null) {
                    accountId = (String) currentValues.get('celsrm__Account__c');
                } else {
                    returnVal.put('ggErrorMessage', Label.Not_Able_To_Get_Accounts_Record_Id);
                }
            } else if(sObjName == 'Task'){
                isTask = true;
                if(currentValues.get('accountId') != null) {
                    accountId = (String) currentValues.get('accountId');
                } else {
                    returnVal.put('ggErrorMessage', Label.Not_Able_To_Get_Accounts_Record_Id);
                }
                taskList = [Select Id, celsrm__Treatment__c, WhatId, Subject, celsrm__Treatment_Stage__c From Task Where Id = :recordId];
            } else {
                accountId = (String) currentValues.get('Id');
            }
            if(accountId != '') {
                accIds.add(accountId);
            }
            system.debug('accountId>>' + accountId);
        }
        Map < String, Map < String, List < String >> > returnMap = new Map < String, Map < String, List < String >> > ();
        // << START - MM - FIN-9969 - select contact by Email_Type__c based on treatment rule name >>
        // returnMap = UtilityController.fetchEmails(accIds);
        String screenName = (String)currentValues.get('ggScreenName');
        if(screenName == 'SendEmailForTreatmentRule') {
            Id taskId = (Id) currentValues.get('Id');
            List<Task> listTask = [select id,WhatId,celsrm__Treatment__r.Name, celsrm__Treatment__r.celsrm__Treatment_Name__c from task where id =: taskId];
            if(listTask.size() > 0) {
                Map<Id, Id> taskIdVsAccount = new Map<Id, Id>();
                Map<Id, String> taskIdVsEmailType = new Map<Id, String>();
                taskIdVsAccount.put(listTask.get(0).Id, listTask.get(0).WhatId);    
                String ruleName = listTask.get(0).celsrm__Treatment__r.celsrm__Treatment_Name__c.toUpperCase();
                String emailType = null;
                if (ruleName.contains('CUSTSTAT')) {
                    emailType = 'Statement';
                } else if (ruleName.contains('DUNNING')) {
                    emailType = 'Dunning';
                }
                taskIdVsEmailType.put(listTask.get(0).Id, emailType);
                returnMap = UtilityController.fetchEmailsBasedOnEmailType(taskIdVsAccount, taskIdVsEmailType);
            } else {
                System.debug('Invalid Task Id passes: ' + taskId);
            }
        } else {
            returnMap = UtilityController.fetchEmails(accIds);
        }
        // << END - MM - FIN-9969 - select contact by Email_Type__c based on treatment rule name >>
        
        Map < String, list < String >> m_getMailData = new Map < String, list < String >> ();

        // START || FIN-7209 || From MyEmailActivity, to and cc should populate for reply, forward
        // If activitydata is not null, prefetch triggered through MyEmail Send Statement
        if(currentValues.containsKey('activityData') && currentValues.get('activityData') != null) { 
            Map<Object, Object> activityData = (Map<Object, Object>)currentValues.get('activityData');
            
            if (activityData != null) {
                if (activityData.get('HtmlBody') != null) {
                    String pBody = '';
                    if (activityData.get('FromAddress') != null) {
                        pBody += '<b>From:</b> ' + activityData.get('FromAddress') + '<br/>';
                    }
                    if (activityData.get('CreatedDate') != null) {
                        pBody += '<b>Sent:</b> ' + activityData.get('CreatedDate') + '<br/>';
                    }
                    if (activityData.get('ToAddress') != null) {
                        pBody += '<b>To:</b> ' + activityData.get('ToAddress') + '<br/>';
                    }
                    if (activityData.get('CcAddress') != null) {
                        pBody += '<b>Cc:</b> ' + activityData.get('CcAddress') + '<br/>';
                    }
                    if (activityData.get('Subject') != null) {
                        pBody += '<b>Subject:</b> ' + activityData.get('Subject') + '<br/>';
                    }
                     pBody += activityData.get('HtmlBody');
                    returnVal.put('body', '<hr>' + pBody);
                }
                if (activityData.get('FromAddress') != null) {
                    returnVal.put('to', activityData.get('FromAddress'));
                }
                if (activityData.get('CcAddress') != null) {
                    returnVal.put('cc',  activityData.get('CcAddress'));
                    // system.debug('CCAddress: ' + activityData.get('CcAddress'));
                
                    // // Get CcAddress and remove all spaces
                    // String ccEmails = ((String) activityData.get('CcAddress')).replace(' ', '');
                    // List<String> combinedEmails = new List<String>();
                
                    // // Split CC emails using semicolon and add them to the list
                    // List<String> ccEmailList = ccEmails.split(';');
                    // for (String email : ccEmailList) {
                    //     if (!String.isBlank(email)) { 
                    //         combinedEmails.add(email);
                    //     }
                    // }
                
                    // // Iterate over account IDs and add 'to' addresses
                    // for (Id accID: accIds) { 
                    //     if (returnMap != null && returnMap.get(accID) != null && returnMap.get(accID).get('to') != null) {
                    //         system.debug('returnMap from if before >>> ' + returnMap.get(accID).get('to'));
                
                    //         List<String> toEmails = returnMap.get(accID).get('to');
                    //         for (String email : toEmails) {
                    //             String trimmedEmail = email.replace(' ', '');
                    //             if (!String.isBlank(trimmedEmail)) {
                    //                 combinedEmails.add(trimmedEmail);
                    //             }
                    //         }
                    //     }
                    // }
                    // String finalEmailList = String.join(combinedEmails, ';');
                
                    // system.debug('Final Combined Email String: ' + finalEmailList);
                    // returnVal.put('cc', finalEmailList);
                }
                if (activityData.get('BccAddress') != null) {
                    returnVal.put('Bcc',  activityData.get('BccAddress'));
                }
            }
        } else {
            Map< String, Map<String, List<String>> > treatmentEmails = new Map< String, Map<String, List<String>> >();
            if(isTask){
                treatmentEmails = UtilityController.fetchEmailsForTreatmentTask(taskList);
            }
            Map<String, List<String>> finalMap = new Map<String, List<String>>();
            // << START - MM - FIN-9969 - select contact by Email_Type__c based on treatment rule name | fetchEmailsBasedOnEmailType returns data by task while fetchEmails returns data by account Id >>
            // Merge entries from returnMap (account-based)
            // if (returnMap != null && returnMap.containsKey(accountId)) {
            //     for (String key : returnMap.get(accountId).keySet()) {
            //         if (!finalMap.containsKey(key)) {
            //             finalMap.put(key, new List<String>());
            //         }
            //         finalMap.get(key).addAll(returnMap.get(accountId).get(key));
            //     }
            // }
            if(screenName == 'SendEmailForTreatmentRule') {
                String taskId = (String)currentValues.get('Id');
                if (returnMap != null && returnMap.containsKey(taskId)) {
                    for (String key : returnMap.get(taskId).keySet()) {
                        if (!finalMap.containsKey(key)) {
                            finalMap.put(key, new List<String>());
                        }
                        finalMap.get(key).addAll(returnMap.get(taskId).get(key));
                    }
                }
            } else {
                if (returnMap != null && returnMap.containsKey(accountId)) {
                    for (String key : returnMap.get(accountId).keySet()) {
                        if (!finalMap.containsKey(key)) {
                            finalMap.put(key, new List<String>());
                        }
                        finalMap.get(key).addAll(returnMap.get(accountId).get(key));
                    }
                }
            }
            // << END - MM - FIN-9969 - select contact by Email_Type__c based on treatment rule name | fetchEmailsBasedOnEmailType returns data by task while fetchEmails returns data by account Id >>

            // Merge entries from treatmentEmails (treatment-based)
            if (treatmentEmails != null && treatmentEmails.containsKey(recordId)) {
                for (String key : treatmentEmails.get(recordId).keySet()) {
                    if (!finalMap.containsKey(key)) {
                        finalMap.put(key, new List<String>());
                    }
                    finalMap.get(key).addAll(treatmentEmails.get(recordId).get(key));
                }
            }

            if(finalMap.containsKey('to') && !finalMap.get('to').isEmpty())
                returnVal.put('to', finalMap.get('to'));
            if(finalMap.containsKey('bcc') && !finalMap.get('bcc').isEmpty())
                returnVal.put('bcc', finalMap.get('bcc'));
            if(finalMap.containsKey('cc') && !finalMap.get('cc').isEmpty())
                returnVal.put('cc', finalMap.get('cc'));
            if(finalMap.containsKey('from') && !finalMap.get('from').isEmpty()){
                List < string > tempst = finalMap.get('from');
                returnVal.put('from', (Id) tempst.get(0));
            }
        }
        if(!returnVal.containsKey('from') && returnMap.containsKey(accountId) && returnMap.get(accountId).containsKey('from')){
            List < string > tempst = returnMap.get(accountId).get('from');
            returnVal.put('from', (Id) tempst.get(0));
        }
        
        // END || FIN-7209 || From MyEmailActivity, to and cc should populate for reply, forward
        returnVal.put('enableSubmitButton', true); 
        //-- Starts | FIN-6130 | Changed by Dilshad | 29 Jun 2024 --//
        if(sObjName == 'Task') {
            //-- Starts | FIN-6892| Changes By: Asera | 18 Dec 2024 --//
            String fromAddress = getDynamicFromAddress(currentValues, accountId);
            if(fromAddress != null || fromAddress != ''){
                returnVal.put('from', fromAddress);
            }
            //-- End | FIN-6892| Changes By: Asera | 18 Dec 2024 --//

            // String taskId = (String)currentValues.get('Id');
            // Task taskObj = [SELECT Id, Subject, WhatId, celsrm__Treatment__c, celsrm__Treatment_Stage__c FROM Task WHERE Id =: taskId];
            // String treatmentId = taskObj.celsrm__Treatment__c;
            // celsrm__Treatment__c treatment = [Select Id, Name, celsrm__Email_Template__c, celsrm__Account_Criteria__c, celsrm__Active__c, celsrm__Related_Object__c, celsrm__Treatment_Steps__c,
            //                                     celsrm__Task_Due_Date__c,celsrm__Task_Type__c,celsrm__Org_Id__c,celsrm__Template_Folder_Reference_Field__c, celsrm__Email_Template_Prefix__c, 
            //                                     celsrm__Attachment__c, celsrm__Notify_Account_Owner__c, celsrm__Custom_Logic_Class__c, celsrm__Consolidated_Treatment__c, celsrm__Seperate_Task_For_Step__c,
            //                                     celsrm__Auto_Treatment__c, celsrm__Enable_Dynamic_Template__c, celsrm__Attachment_Name__c, celsrm__Attachment_Format__c, celsrm__Custom_Logic_For_Email_Body__c
            //                                     FROM celsrm__Treatment__c  Where Id=:treatmentId];
            // Map<String, Object> returnBodyMap = celsrm.SRMTreatmentUtility.getTemplateBody(taskObj, treatment, taskObj.Id, null, true, null, null);
            // // String subject = returnBodyMap.get('subject') != null ? taskObj.Subject + ' : '  + returnBodyMap.get('subject') : '';
            // // String templateBody = returnBodyMap.get('templateBody') != null ? String.valueOf(returnBodyMap.get('templateBody')) : '';
            // String fromId = returnBodyMap.get('fromId') != null && returnBodyMap.get('fromId') != '' ? String.valueOf(returnBodyMap.get('fromId')) : null;
            // // Map<String, String> composeEmail = new Map<String, String>();
            // // returnVal.put('subject', subject);
            // //returnVal.put('body', templateBody);
            // returnVal.put('from', fromId);
        }
        //-- Ends | FIN-6130 | Changed by Dilshad | 29 Jun 2024 --//
        // End Pre fatch Class Data

        // Start for Email Address Suggestion
        Map<Object, Object> emailAddressSuggestionMap = new Map<Object, Object>();
        List<Map<String, String>> emailList = new List<Map<String, String>>();
        Map<String, String> emailMap;
       // String AccountId = String.valueOf(currentValues.get('Id'));
        Set<id> AccountIds= new set<id>();
        Map<Id,Account> MapAccountParent = new Map<id,Account>([Select id from Account Where ParentId =: accountId Or Id =:accountId LIMIT 5000]);
        system.debug('============'+ accountId );
        AccountIds = MapAccountParent.keySet();
        for(Contact contList : [Select Id, Name, Email FROM Contact WHERE AccountId in :AccountIds  ]){
            emailMap = new Map<String, String>();
            if(contList.Name != null && contList.Email != null){
            emailMap.put('label', contList.Name);
            emailMap.put('value', contList.Email);
            emailList.add(emailMap);
            }
        }
        if(emailList != null && emailList.size()>0){
            emailAddressSuggestionMap.put('toSuggestion',emailList);
            emailAddressSuggestionMap.put('bccSuggestion',emailList);
            emailAddressSuggestionMap.put('ccSuggestion',emailList);
        }
        returnVal.put('emailAddressSuggestion',emailAddressSuggestionMap);
        // End Email Address Sugeestion
        return returnVal;
    }
    // End Pre fatch Class 

    public static Map<String, Object> setDataFormattingForEmail(Map<Object, Object> currentValues, Id templateId, Map<String,Object> mapOfExtraParam, String functionName) {
        Map<String, Object> returnVal = new Map<String, Object>();
        if(currentValues.containsKey('openFromSummaryAgent') && Boolean.valueOf(currentValues.get('openFromSummaryAgent')) == true){
            String arguments = String.valueOf(currentValues.get('summaryArguments'));
            Map<String, Object> argumentsMap = (Map<String, Object> )JSON.deserializeUntyped(arguments);
            // returnVal.put('subject',message.getSubject());
            Boolean haveTag = false;
            if(argumentsMap.containsKey('email_response') && argumentsMap.get('email_response') != null){
                String htmlBody = (String)argumentsMap.get('email_response');
                returnVal.put('htmlBody',htmlBody);
                if(htmlBody.contains('{Transaction.Summary}')){
                    haveTag = true;
                }
            }
            if(currentValues.containsKey('activityData') && currentValues.get('activityData') != null) { 
                Map<Object, Object> activityData = (Map<Object, Object>)currentValues.get('activityData');
                if (activityData.get('Subject') != null) {
                    returnVal.put('subject', activityData.get('Subject'));
                }
            }
            if(!haveTag){
                return returnVal;
            }
            
            
        }
        string abc = '';
        String sortfieldName = null;
        String sortOrder = null;
        if (currentValues.get('TransactionList_SortColumn') != null && currentValues.get('TransactionList_SortOrder') != null) {
            sortfieldName = String.valueOf(currentValues.get('TransactionList_SortColumn'));
            sortOrder = String.valueOf(currentValues.get('TransactionList_SortOrder'));
            if(Schema.SObjectType.celsrm__Transaction__c.fields.getMap().get(sortfieldName).getDescribe().getType() == Schema.DisplayType.TextArea) {
                sortfieldName = null;
                sortOrder = null;
            }
        }
        //By Ravi | 12-02-2020 | user preference
        String currentUser = UserInfo.getUserId();
        celsrm__User_Preference__c userPref  = new celsrm__User_Preference__c();
        // START || FIN-7286 || Fetched list view value from user pref for composeEmail
        try {
            userPref = [SELECT Id,celsrm__SortListViewField__c,celsrm__SortListViewOrderType__c, celsrm__sendStatementListView__c FROM celsrm__User_Preference__c WHERE celsrm__User__c =:currentUser LIMIT 1];
        } catch (Exception e) {
            System.debug('exception>> ' + e.getMessage());
        }
        // End || FIN-7286 || Fetched list view value from user pref for composeEmail
        if (sortfieldName == null && sortOrder == null && userPref.celsrm__SortListViewField__c != null && userPref.celsrm__SortListViewOrderType__c != null) {
            sortfieldName = String.valueOf(userPref.celsrm__SortListViewField__c);
            sortOrder = String.valueOf(userPref.celsrm__SortListViewOrderType__c);
            if(Schema.SObjectType.celsrm__Transaction__c.fields.getMap().get(sortfieldName).getDescribe().getType() == Schema.DisplayType.TextArea) {
                sortfieldName = null;
                sortOrder = null;
            }
        }
        
        //By Ravi | 12-02-2020 | user preference
        system.debug('currentValues>>'+currentValues);
        system.debug('templateHtmlBody>>'+templateId);
        system.debug('mapOfExtraParam>>'+mapOfExtraParam);
        List<String> TransIds = new List<String>();
        List<Object> records = (List<Object>)currentValues.get('TransactionList');
        system.debug('records>>>'+records);
        system.debug('currentValues.get(Id) : ' + currentValues.get('Id'));
        String ListView = (String)currentValues.get('ListView');
        //when PromiseToPay Screen will open from Activity then will set default template
        // START || FIN-7286 || Checks only for sendStatement screen
        if((ListView == null || ListView == '') && currentValues.get('screenName') != 'Send Statement') {
            //TODO:: Need to make it conifgurable
            List<celsrm__Custom_List_View__c> dbView = [SELECT Id FROM celsrm__Custom_List_View__c WHERE celsrm__ListView_For_Object__c = 'celsrm__Transaction__c' AND celsrm__Is_Default__c = TRUE];
            ListView = dbView.get(0).id;
        } else if (ListView == null && currentValues.get('screenName') == 'Send Statement') {
            ListView = (String)userPref.celsrm__sendStatementListView__c;
        }
        // END || FIN-7286 || Checks only for sendStatement screen
        System.debug(' @@ ListView : ' + ListView);
        String htmlBody;
        List<Contact> con =[Select Id,Name From Contact where celsrm__Default__c=true and accountId=:(String)currentValues.get('Id')];
        Id ContactId ;
        // String ContactNameEmail='';
        if(con!= null && con.size()>0){
            ContactId =con.get(0).Id;
            // ContactNameEmail = con.get(0).name;
        } 

        Messaging.SingleEmailMessage message;
        if( ContactId != null){
            message = Messaging.renderStoredEmailTemplate(templateId,ContactId , (Id) currentValues.get('Id'));
        }else{
            message = Messaging.renderStoredEmailTemplate(templateId,null, (Id) currentValues.get('Id'));
        }
        String returnTemplateBody = message.getHtmlBody();
        if(returnVal.containsKey('htmlBody')){
            returnTemplateBody = (String)returnVal.get('htmlBody');
        }
        if(returnTemplateBody == null ){
            returnTemplateBody = message.getPlainTextBody().replaceAll('\n','</br>');
        }
        system.debug('returnTemplateBody>>>>>'+returnTemplateBody);
        if(records  != null){
        Integer rowNum = 0; 
        Double totalBillingBal = 0;
    
        
        for (Object obj : records) { 
                Map<Object,Object> m_S_O =  new Map<Object,Object>();
                m_S_O = (Map<Object,Object>)obj;
                TransIds.add((String)m_S_O.get('Id'));
                system.debug('obj>>>>>>>>>'+obj);
        }
        // htmlBody += '</table>';
        //abc = returnTemplateBody + htmlBody;//abc 
         //-- Start | FIN-8334 | Changed by Ravi | 11 sep 2025 --//
        if (returnTemplateBody.Contains('{Transactions.TotalBalance}')) {
            Map<String,String> returnTemplateAmount = UtilityController.getTransactionTotalSummary((String)currentValues.get('Id'),TransIds);
            returnTemplateBody = returnTemplateBody.replace('{Transactions.TotalBalance}', returnTemplateAmount.get('TotalBalance'));
            //-- End | FIN-8334 | Changed by Ravi | 11 sep 2025 --//
        }
        htmlBody = UtilityController.getTransactionListViewData(ListView, TransIds, false, sortfieldName, sortOrder, (String)currentValues.get('Id')); // FIN-8280| Changed by Asera | 17 April 2026 --//
        
        returnVal.put('htmlBody',returnTemplateBody.replace('{Transaction.Summary}', htmlBody));
        } else if(records == null && currentValues.get('screenName') == 'Send Statement') {
            //-- Start | FIN-6777 | Changed by Ravi | 11 Aug 2024 --//
            List<celsrm__Custom_List_View__c> dbView = new List<celsrm__Custom_List_View__c>();
            dbView = [Select Id, Name, celsrm__Object_Fields__c, celsrm__Filter_Criteria__c,celsrm__ListView_For_Object__c,celsrm__Sort_By_Field__c,celsrm__Sort_By_Order__c From celsrm__Custom_List_View__c Where Id = :ListView limit 1];
            
            if(dbView.size() == 0) {
                dbView = [Select Id, Name, celsrm__Object_Fields__c, celsrm__Filter_Criteria__c,celsrm__ListView_For_Object__c,celsrm__Sort_By_Field__c,celsrm__Sort_By_Order__c From celsrm__Custom_List_View__c Where celsrm__ListView_For_Object__c = 'celsrm__Transaction__c' and celsrm__Is_Default__c = true and (CreatedById = :currentUser or celsrm__Is_Global__c = true) order by CreatedDate DESC LIMIT 1];
            } 
            celsrm__Custom_List_View__c customListViewObj = dbView.get(0);
            //-- Ends | FIN-6777 | Changed by Ravi | 11 Aug 2024 --//
            String selectedFields = '';
            if(customListViewObj.celsrm__Object_Fields__c != null && customListViewObj.celsrm__Object_Fields__c != '') {
                selectedFields = UtilityController.getQueryFields(customListViewObj.celsrm__Object_Fields__c, 'celsrm__Transaction__c');
            }
            //-- Start | FIN-8530 | Changed by Ravi | 10 Nov 2025 --//
            Set<String> accId = new Set<String>();
            accId.add(String.valueOf(currentValues.get('Id')));
            if (currentValues.get('accountHierarchyChildIds') != null) {
                List<Object> tempList = (List<Object>)currentValues.get('accountHierarchyChildIds');
                for(Object objId : tempList) {
                    accId.add(String.valueOf(objId));
                }
            }
            //-- End | FIN-8530 | Changed by Ravi | 10 Nov 2025 --//
            id key= (String)currentValues.get('Id');
            system.debug('==key==='+key);
            String whereCondition = '  ';
            if(customListViewObj != null && customListViewObj.celsrm__Filter_Criteria__c != '') {
                whereCondition = UtilityController.getQueryWhereClause(customListViewObj.celsrm__Filter_Criteria__c);
            }
            system.debug('==whereCondition==='+whereCondition);
            if(whereCondition != ''  && whereCondition != null) {
                //-- Start | FIN-8530 | Changed by Ravi | 10 Nov 2025 --//
                // if ((Boolean)currentValues.get('IsIncludeChild') == true) {
                //     System.debug('IsIncludeChild If Part');
                //     whereCondition += ' and (celsrm__Account__c= :key OR celsrm__Account__r.parentid= :key OR celsrm__Account__r.parent.parentid= :key ) ';
                // } else {
                    System.debug('IsIncludeChild else part');
                    whereCondition += ' and celsrm__account__c IN :accId ';
                // }   
                //-- End | FIN-8530 | Changed by Ravi | 10 Nov 2025 --//                        
            } else if(whereCondition == '') {
                //-- Start | FIN-8530 | Changed by Ravi | 10 Nov 2025 --//
                // if ((Boolean)currentValues.get('IsIncludeChild') == true) {
                //     System.debug('IsIncludeChild If Part');
                //     whereCondition = ' celsrm__balance__c !=0 and (celsrm__Account__c= :key OR celsrm__Account__r.parentid= :key OR celsrm__Account__r.parent.parentid= :key ) ';
                // } else {
                    System.debug('IsIncludeChild else part');                                    
                    whereCondition = ' celsrm__balance__c !=0 and celsrm__account__c IN :accId '; 
                // }    
                //-- End | FIN-8530 | Changed by Ravi | 10 Nov 2025 --//                      
            }
            if (sortfieldName != null && sortOrder != null) {
                whereCondition += ' ORDER BY ' + sortfieldName + ' ' + sortOrder + ' limit 5000';
            } else if (customListViewObj.celsrm__Sort_By_Field__c != null && customListViewObj.celsrm__Sort_By_Field__c != '') {
                whereCondition += ' ' + UtilityController.getQuerySortOrder(customListViewObj.celsrm__Sort_By_Field__c, true) + ' LIMIT 5000';
            } else {
                whereCondition += ' limit 5000';
            }
            system.debug('==whereCondition 1 ==='+whereCondition);
            
            List<string> formatedFieldName = UtilityController.getTransactionFieldformat(selectedFields.split(','), 'celsrm__Transaction__c');
            List<string> finalFieldList = new List<string>();
            Boolean isHaveBalanceField = false;
            Boolean isHaveBaseBalanceField = false;
            Boolean isHaveCurrencyIsoCodeField = false;
            Boolean hasRecordId = false;
            for(String st:formatedFieldName){
                if(st.equalsIgnoreCase('id') ){
                    hasRecordId = true;
                } else if(st.equalsIgnoreCase('celsrm__balance__c') ){
                    isHaveBalanceField =true;
                } else if(st.equalsIgnoreCase('celsrm__base_balance__c') ){
                    isHaveBaseBalanceField =true;
                } else if(st.equalsIgnoreCase('currencyisocode') ){
                    isHaveCurrencyIsoCodeField = true;
                }
            }
            String Queryfields = string.join(formatedFieldName,',');
            if(!hasRecordId) {
                Queryfields = 'id,' +  Queryfields;
            }
            if(isHaveBalanceField == false){
                Queryfields = 'celsrm__balance__c,' +  Queryfields;
            }
            //....
            //add Base balance field id not exist in listview
            if(isHaveBaseBalanceField == false) {
                Queryfields = 'celsrm__base_balance__c,' +  Queryfields;
            }
            //....
            
            if(isHaveCurrencyIsoCodeField == false &&  UserInfo.IsMultiCurrencyOrganization()){
                Queryfields = 'currencyisocode,' +  Queryfields;
            }
            String stringToQuery = 'SELECT '+ Queryfields + ' FROM celsrm__Transaction__c ' +  whereCondition;
            list<celsrm__Transaction__c> lstTrans = database.query(stringToQuery);
            
            for (celsrm__Transaction__c obj : lstTrans) { 
                TransIds.add(obj.Id);
            }
            //-- Start | FIN-8334 | Changed by Ravi | 11 sep 2025 --//
            if (returnTemplateBody.Contains('{Transactions.TotalBalance}')) {
                Map<String,String> returnTemplateAmount = UtilityController.getTransactionTotalSummary((String)currentValues.get('Id'),TransIds);
                returnTemplateBody = returnTemplateBody.replace('{Transactions.TotalBalance}', returnTemplateAmount.get('TotalBalance'));
                //-- End | FIN-8334 | Changed by Ravi | 11 sep 2025 --//
            } 
            htmlBody = UtilityController.getTransactionListViewData(ListView ,TransIds,false,sortfieldName,sortOrder, (String)currentValues.get('Id')); //FIN-8280| Changed by Asera | 17 April 2026 --//
            returnTemplateBody = returnTemplateBody.replace('{Transaction.Summary}', htmlBody);

            //Added condition and also make use to actioned email message isntead of latest
            // if(currentValues.containsKey('activityData')) {
            //     Map<Object, Object> activityData = (Map<Object, Object>)currentValues.get('activityData');
            //     String emailId = (String) activityData.get('Id');
            //     EmailMessage emailmsg = new EmailMessage();
            //     try {
            //         emailmsg = [Select Id ,FromName,FromAddress,ToAddress,CcAddress,BccAddress,Subject,CreatedDate,HtmlBody,TextBody from EmailMessage where Id = :emailId];
            //     } catch (Exception e) {
            //         System.debug(e.getMessage());
            //     }
            //     if(emailmsg != null){
            //         if (emailmsg.FromName != null && emailmsg.FromAddress != null) {
            //             returnTemplateBody += '<br>  <hr> <b>From:</b> ' + emailmsg.FromName + ' &lt;' + emailmsg.FromAddress + '&gt;';
            //         }
            //         if (emailmsg.CreatedDate != null) {
            //             returnTemplateBody += '<br> <b>Sent:</b> ' + emailmsg.CreatedDate;
            //         }
            //         if (emailmsg.ToAddress != null) {
            //             returnTemplateBody += '<br> <b>To:</b> ' + emailmsg.ToAddress;
            //         }
            //         if (emailmsg.CcAddress != null) {
            //             returnTemplateBody += '<br> <b>Cc:</b> ' + emailmsg.CcAddress;
            //         }
            //         if (emailmsg.BccAddress != null) {
            //             returnTemplateBody += '<br> <b>Bcc:</b> ' + emailmsg.BccAddress;
            //         }
            //         if (emailmsg.Subject != null) {
            //             returnTemplateBody += '<br> <b>Subject:</b> ' + emailmsg.Subject;
            //         }
            //         if (emailmsg.HtmlBody != null) {
            //             returnTemplateBody += '<br><br>' + emailmsg.HtmlBody;
            //         }
            //     }
            // }            
            returnVal.put('htmlBody',returnTemplateBody);
                
        }else {
            returnVal.put('htmlBody',returnTemplateBody);
        }
        if(!returnVal.containsKey('subject')){
            returnVal.put('subject',message.getSubject());
        }
        
        return returnVal;
    }
 
    // by Sejal 10/06/2024 | data formatting for send email from task detail page
    public static Map<String,Object> setDataFormattingForTreatment(Map<Object,Object> inMap,  Id templateId, Map<String,Object> mapOfExtraParam, String functionName){
        System.debug('@@@ treatmentPrefetchTemplate  : ');
        //-- Starts | FIN-88653 | Changed by Dhwanil | 23 dec 2025 --//
        Boolean isTaskScreen = inMap.containsKey('isTaskScreen') ? (Boolean)inMap.get('isTaskScreen') : false;
        Boolean isDunningScreen = inMap.containsKey('isDunningScreen') ? (Boolean)inMap.get('isDunningScreen') : false;
        String treatmentStage;
        //-- Ends | FIN-88653 | Changed by Dhwanil | 23 dec 2025 --//
        Boolean seperateTaskForStep = false;
        List < Id > accIds = new List < Id > ();
        id parentId = null;
        if (inMap.containsKey('accountId') && inMap.get('accountId') != null) {
            parentId = (Id) inMap.get('accountId');
            accIds.add(parentId);
            system.debug('parentId>>' + parentId);
        }
        Map < String, Object > returnValue = new Map < String, Object > ();
        returnValue.put('enableSubmitButton', true);

        EmailTemplate template = new EmailTemplate();
        // String templateId;
        String recordId = (String)inMap.get('Id');
        if (templateId != null) {
            String objectName = (String)inMap.get('objectName');
            List<Object> listOfStep = inMap.get('listOfStep') != null ? (List<Object>)inMap.get('listOfStep') : new List<Object>();
            String taskSubject = inMap.get('taskSubject') != null ? (String)inMap.get('taskSubject') :'';
            //-- Starts | FIN-88653 | Changed by Dhwanil | 23 dec 2025 --//
            treatmentStage = inMap.get('treatmentStage') != null ? (String)inMap.get('treatmentStage') :'';
            seperateTaskForStep = inMap.get('seperateTaskForStep') != null ? Boolean.valueOf(String.valueOf(inMap.get('seperateTaskForStep'))) : false;
            Boolean isConsolidated = inMap.get('isConsolidated') != null ? Boolean.valueOf(String.valueOf(inMap.get('isConsolidated'))) : false;
            //-- Ends | FIN-88653 | Changed by Dhwanil | 23 dec 2025 --//
            
            // Integer len = listOfStep.size() - 1;
            List<Contact> con = new List<Contact>();
            try {
                con = [Select Id From Contact where celsrm__Default__c=true and accountId=:parentId];
                if (con == null || con.size() == 0) {
                    con = [Select Id From Contact where accountId=:parentId];
                }
            } catch (Exception e) {
                System.debug(e.getMessage());
            }
            
            Id ContactId ;
            if(con!= null && con.size()>0){
                ContactId =con.get(0).Id;
            }
            System.debug('templateId>>>>' + templateId);
            System.debug('ContactId>>>>' + ContactId);
            System.debug('parentId>>>>' + parentId);
            Messaging.SingleEmailMessage message = Messaging.renderStoredEmailTemplate(templateId,ContactId, parentId);
            returnValue.put('subject', message.getSubject());
            String returnTemplateBody = message.getHtmlBody();
            Map<string, Schema.sObjectType> describeInfo = Schema.getGlobalDescribe();
            Map<String, Schema.SObjectField> fieldMap = describeInfo.get(objectName.toLowerCase()).getDescribe().Fields.getMap();
            //-- Start | FIN-9778 | Changed by Asera | 11 June 2026 --//
            String accountLocale = 'EN';
            try {
                Account acc = [SELECT Id, celsrm__Locale__c FROM Account WHERE Id = :parentId];
                accountLocale = acc.celsrm__Locale__c == null ? 'EN' : acc.celsrm__Locale__c;
             } catch (Exception e) {
                   System.debug('Error fetching Account: ' + e.getMessage());
             }
            Map<String, String> fieldApiVsTranslatedLabel = celsrm.SRMUtilityController.getTranslatedLabelMapForObject(accountLocale, 'celsrm__Transaction__c'); 
            //-- End | FIN-9778 | Changed by Asera | 11 June 2026 --//
            List<Object> childObjectIds = (List<Object>)inMap.get('childObjectIds');
            // table create
            //-- Start | FIN-9778 | Changed by Dhwanil | 25 May 2026 --//
            if ((seperateTaskForStep || isConsolidated) && (returnTemplateBody.containsIgnoreCase('{treatment}') || returnTemplateBody.containsIgnoreCase('{Transaction.Summary}') || Test.isRunningTest())) {
            //-- End | FIN-9778 | Changed by Dhwanil | 25 May 2026 --//
                Double TotalBalance = 0;
                List<String> columnsNameList = new List<String>();
                List<String> TempSelFlds= new List<String>();
                if(inMap.containsKey(treatmentStage + 'columns') && inMap.get(treatmentStage + 'columns') != null){
                    List<Object> columns = (List<Object>)inMap.get(treatmentStage + 'columns');
                    if (columns.size() > 0) {
                        for (Object field : columns) {
                            String fieldName = '';
                            try {
                                Map<Object,Object> fieldInfo = (Map<Object,Object>)field;
                                fieldName = (String)fieldInfo.get('fieldName');
                                
                            } catch (Exception e) {
                                Map<String,Object> fieldInfo = (Map<String,Object>)field;
                                fieldName = (String)fieldInfo.get('fieldName');
                            }
                            if (fieldName != 'RemoveCommunication') {
                                columnsNameList.add(fieldName);
                                if(fieldMap.get(fieldName.trim().toLowerCase()).getDescribe().isCustom() && fieldMap.get(fieldName.trim().toLowerCase()).getDescribe().getType() == Schema.DisplayType.REFERENCE){
                                    fieldName= fieldName.subString(0,fieldName.length()-1)+ 'r.Name';
                                    TempSelFlds.add(fieldName);
                                } else if (!fieldMap.get(fieldName.trim().toLowerCase()).getDescribe().isCustom() && fieldMap.get(fieldName.trim().toLowerCase()).getDescribe().getType() == Schema.DisplayType.REFERENCE) {
                                    fieldName= fieldName.subString(0,fieldName.length()-2)+ '.Name';
                                    TempSelFlds.add(fieldName);
                                } else {
                                    TempSelFlds.add(fieldName);
                                }
                            }
                            
                        }
                    }
                }
                Boolean idContains = false;
                if (TempSelFlds.contains('Id') || TempSelFlds.contains('id')) {
                    idContains = true;
                }
                if (UserInfo.IsMultiCurrencyOrganization() && !TempSelFlds.contains('CurrencyIsoCode')) {
                    TempSelFlds.add('CurrencyIsoCode');
                }
                String queryFieldName = TempSelFlds.size() > 0 ? String.join(TempSelFlds, ',') : '';
                List<Id> childIds = new List<Id>();
                //-- Starts | FIN-88653 | Changed by Dhwanil | 23 dec 2025 --//
                if (isTaskScreen || isDunningScreen) { //-- Ends | FIN-88653 | Changed by Dhwanil | 23 dec 2025 --//
                    for (Object step : listOfStep) {
                        if (inMap.containsKey(step) && inMap.get(step) != null) {
                            List<Object> values = (List<Object>)inMap.get(step);
                            if (values.size() > 0) {
                                for (Object vals : values) {
                                    try{
                                        Map<Object,Object> val =(Map<Object,Object>)vals;
                                        System.debug('val--> ' + val);
                                        System.debug('val.get(isSelected)--> ' + val.get('isSelected'));
                                        if (val.containsKey('isSelected') && (Boolean)val.get('isSelected') == true) {
                                            childIds.add((Id)val.get('Id'));
                                        }
                                    } catch (Exception e) {
                                        celsrm__Transaction__c trx = (celsrm__Transaction__c)vals;
                                        childIds.add(trx.Id);
                                    }
                                }
                            }
                        }
                    }
                } else {
                    for(Object Ids : childObjectIds){
                        //-- Starts | FIN-8444 | Changed by Asera | 7 Oct 2025 --//
                        Set<Id> idsSet = (Set<Id>) Ids;
                        childIds.addAll(idsSet);
                        // childIds.add((String)Ids);
                        //-- Starts | FIN-8444 | Changed by Asera | 7 Oct 2025 --//
                    }
                }
                String query = '';
                if (idContains == true && queryFieldName != '') {
                    query = 'SELECT ' + queryFieldName + ' FROM ' + ObjectName + ' where Id=:childIds';
                } else if (queryFieldName != '') {
                    query = 'SELECT Id, ' + queryFieldName + ' FROM ' + ObjectName + ' where Id=:childIds';
                } else {
                    query = 'SELECT Id, Name FROM ' + ObjectName + ' where Id=:childIds';
                }
                if (ObjectName.equalsIgnoreCase('celsrm__transaction__c')) {
                    // query += ' order by celsrm__DPD__c desc';
                    query += ' order by celsrm__DPD__c desc';
                } else if (ObjectName.equalsIgnoreCase('celsrm__dispute__c')) {
                    query += ' order by celsrm__Dispute_DPD__c desc';
                }
                List<SObject> childObjectRecords = Database.query(query);
                String innerHtml= '';
                Integer j=0;
                if (columnsNameList.size() == 0) {
                    columnsNameList.add('Name');
                }
                if (columnsNameList.size() > 0) {
                    //-- Start | FIN-8048 | Changed by Ravi | 29 July 2025 --//
                    innerHtml = '<style>@page{size:landscape;}</style><table width="100%" class="billing" style="border-collapse:collapse;padding:0px;font-family:verdana;">';
                    //-- End | FIN-8048 | Changed by Ravi | 29 July 2025 --//
                    innerHtml += '<tr>';
                    for (String tempColumn : columnsNameList) {
                        //-- Start | FIN-8048 | Changed by Ravi | 29 July 2025 --//
                        //-- Start | FIN-9778 | Changed by Dhwanil | 22 May 2026 --//
                        //-- Start | FIN-9778 | Changed by Asera | 11 June 2026 --//
                        // String fieldKey = tempColumn.trim().toLowerCase();
                        // String headerLabel = fieldApiVsTranslatedLabel != null && !fieldApiVsTranslatedLabel.isEmpty() && fieldApiVsTranslatedLabel.containsKey(fieldKey)
                        //     ? fieldApiVsTranslatedLabel.get(fieldKey)
                        //     : fieldMap.get(tempColumn.toLowerCase()).getDescribe().getLabel();
                        innerHtml += '<th width="auto" style="border:1px solid gray;text-align:center;">'+ fieldApiVsTranslatedLabel.get(tempColumn.toLowerCase()) +'</th>';
                        //-- Start | FIN-9778 | Changed by Asera | 11 June 2026 --//
                        //-- End | FIN-9778 | Changed by Dhwanil | 22 May 2026 --//
                        //-- End | FIN-8048 | Changed by Ravi | 29 July 2025 --//
                    }
                    innerHtml += '</tr>';
                    Map<String,Double> totalMap = new Map<String,Double>();
                    Double total = 0;
                    String aggregationField = '';
                    String totalTitle = '';
                    if(inMap.containsKey(treatmentStage + 'showTotal') && inMap.get(treatmentStage + 'showTotal') != null && (Boolean)inMap.get(treatmentStage + 'showTotal') && inMap.containsKey(treatmentStage + 'aggregationField') && inMap.get(treatmentStage + 'aggregationField') != null){
                        aggregationField = String.valueOf(inMap.get(treatmentStage + 'aggregationField'));
                        if(inMap.containsKey(treatmentStage + 'totalTitle') && inMap.get(treatmentStage + 'totalTitle') != null){
                            totalTitle = String.valueOf(inMap.get(treatmentStage + 'totalTitle'));
                        }
                    }
                    //-- Start | FIN-9021 | Changed by Dhwanil | 22 Jan 2026 --//
                    for (Sobject tempRecord : childObjectRecords) {
                        j=j+1;
                        innerHtml += '<tr>';
                        for (String fieldName : columnsNameList) {
                            Object fieldValue = '';
                            String falign = 'left';
                            if (fieldMap.get(fieldName).getDescribe().getType() == Schema.DisplayType.REFERENCE) {
                                
                                String tempfield= '';
                                if (fieldMap.get(fieldName.toLowerCase()).getDescribe().isCustom()) {
                                    tempfield= fieldName.subString(0,fieldName.length()-1)+ 'r';
                                } else {
                                    tempfield= fieldName.subString(0,fieldName.length()-2);
                                }
                                fieldValue = tempRecord.getSobject(tempfield).get('Name');
                            } else if (fieldMap.get(fieldName).getDescribe().getType().name() == 'CURRENCY'){
                                if (tempRecord.get(fieldName) != null) {
                                    Double dtTemp = (Double)tempRecord.get(fieldName);
                                    String currencyIsoCode = ( String )(UserInfo.IsMultiCurrencyOrganization() ? tempRecord.get('CurrencyIsoCode') : UserInfo.getDefaultCurrency());           
                                        
                                    fieldvalue =formatDoubleValue(currencyIsoCode ,dtTemp );
                                }
                            
                            } else if (fieldMap.get(fieldName).getDescribe().getType().name() == 'DATETIME'){
                                if (tempRecord.get(fieldName) != null) {
                                    Datetime dtTemp = (Datetime)tempRecord.get(fieldName);
                                    
                                    fieldvalue =dtTemp.format();
                                }
                            } else if (fieldMap.get(fieldName).getDescribe().getType().name() == 'DATE'){
                                if (tempRecord.get(fieldName) != null) {
                                    Date dtTemp = (Date)tempRecord.get(fieldName);
                                    
                                    fieldvalue =dtTemp.format();
                                }
                            } else if (fieldMap.get(fieldName).getDescribe().getType().name() == 'INTEGER' || fieldMap.get(fieldName).getDescribe().getType().name() == 'DOUBLE' || fieldMap.get(fieldName).getDescribe().getType().name() == 'PERCENT'){
                                //-- Start | FIN-9574 | Changed By Dhwanil | 23 Apr 2026 --//
                                String currencyIsoCode = ( String )(UserInfo.IsMultiCurrencyOrganization() ? tempRecord.get('CurrencyIsoCode') : UserInfo.getDefaultCurrency());       
                                system.debug((Double)tempRecord.get(fieldName));
                                fieldvalue = (tempRecord.get(fieldName)!=null)?((Double)tempRecord.get(fieldName)).format():null;
                                //-- Ends | FIN-9574 | Changed By Dhwanil | 23 Apr 2026 --//
                            }else{
                            fieldvalue = tempRecord.get(fieldName);
                                if(fieldvalue == null){
                                    fieldvalue = '';
                                }
                            }
                            String fType = fieldMap.get(fieldName).getDescribe().getType().name();
                            if(fType == 'INTEGER' || fType == 'DOUBLE' || fType == 'DECIMAL' || fType == 'PERCENTAGE' || fType == 'CURRENCY'){
                                falign = 'right';
                            }
                            if (aggregationField != '' &&  aggregationField == fieldName) {
                                Double dtTemp = 0.0;
                                if(tempRecord.get(fieldName) != null){
                                    dtTemp = (Double)tempRecord.get(fieldName);
                                } else if (tempRecord.get(fieldName) != null) {
                                    dtTemp = (Double)tempRecord.get(fieldName);
                                }
                                if (fieldMap.get(fieldName).getDescribe().getType().name() == 'CURRENCY') {
                                        
                                    String currencyIsoCode = ( String )(UserInfo.IsMultiCurrencyOrganization() ? tempRecord.get('CurrencyIsoCode') : UserInfo.getDefaultCurrency());           
                                    if (totalMap.get(currencyIsoCode) != null) {
                                        Double finalValue = totalMap.get(currencyIsoCode) + dtTemp;
                                        totalMap.put(currencyIsoCode, finalValue);
                                    } else {
                                        totalMap.put(currencyIsoCode, dtTemp);
                                    }
                                } else {
                                    total = total + dtTemp;
                                }
                            }
                            //-- Start | FIN-8048 | Changed by Ravi | 29 July 2025 --//
                            innerHtml += '<td width="auto" style="text-align:'+falign+';border:1px solid gray;white-space:nowrap;">'+ fieldvalue+'</td>';
                            //-- End | FIN-8048 | Changed by Ravi | 29 July 2025 --//
                        }
                        innerHtml += '</tr>';
                    }
                    //--- End | FIN-9021 | Changed by Dhwanil | 22 January 2026 ---//
                    innerHtml += '</table><br>';
                    if (aggregationField != '') {
                        if (total > 0) {
                            innerHtml += '<span style="float:right">' + totalTitle + ' ' + total + '</span>';
                        } else {
                            if (totalMap.keySet().size() > 0) {
                                innerHtml += '<span style="float:right">' + totalTitle + ' ';
                                for (String code : totalMap.keySet()) {
                                    innerHtml += formatDoubleValue(code ,totalMap.get(code) ) + ',';
                                }
                                innerHtml = innerHtml.removeEnd(',') + '</span>';
                            } else {
                                innerHtml += '<span style="float:right">' + totalTitle + ' 0.0' + '</span>';
                            }
                        }
                    }
                    innerHtml += '<br>';
                    String description = inMap.containsKey(treatmentStage + 'description') && inMap.get(treatmentStage + 'description') != null ? (String)inMap.get(treatmentStage + 'description') : '';
                    returnTemplateBody = returnTemplateBody.replace('{treatment}', description + innerHtml);
                    //-- Start | FIN-9778 | Changed by Dhwanil | 25 May 2026 --//
                    returnTemplateBody = returnTemplateBody.replace('{Transaction.Summary}', innerHtml);
                    //-- End | FIN-9778 | Changed by Dhwanil | 25 May 2026 --//
                }
                
                System.debug('body>>> ' + returnTemplateBody);
            //-- Start | FIN-9778 | Changed by Dhwanil | 25 May 2026 --//
            } else if (!seperateTaskForStep && (returnTemplateBody.containsIgnoreCase('{treatment') || returnTemplateBody.containsIgnoreCase('{Transaction.Summary}') || Test.isRunningTest())) {
            //-- End | FIN-9778 | Changed by Dhwanil | 25 May 2026 --//
                for (Object step : listOfStep) {
                    String innerHtml= '';
                    Integer j=0; 
                    system.debug('step>>>>>>'+step);
                    //-- Start | FIN-8334 | Changed by Ravi | 11 sep 2025 --//
                    if (inMap.containsKey(step) && inMap.get(step) != null) {
                    //-- End | FIN-8334 | Changed by Ravi | 11 sep 2025 --//
                        // List<Object> values = (List<Object>)inMap.get(step + 'value');
                        List<Object> values = (List<Object>)inMap.get(step);
                        if (values.size() > 0) {
                            if (inMap.containsKey(step + 'columns') && inMap.get(step + 'columns') != null) {
                                List<Object> columns = (List<Object>)inMap.get(step + 'columns');
                                if (columns.size() > 0) {
                                    //-- Start | FIN-8048 | Changed by Ravi | 29 July 2025 --//
                                    innerHtml = '<style>@page{size:landscape;}</style><table width="100%" class="billing" style="border-collapse:collapse;padding:0px;font-family:verdana;">';
                                    //-- End | FIN-8048 | Changed by Ravi | 29 July 2025 --//
                                    innerHtml += '<tr>';
                                    for (Object field : columns) {
                                        try {
                                            Map<Object,Object> fieldInfo = (Map<Object,Object>)field;
                                            //-- Start | FIN-8048 | Changed by Ravi | 29 July 2025 --//
                                            //-- Start | FIN-9778 | Changed by Dhwanil | 22 May 2026 --//
                                            String fieldName = String.valueOf(fieldInfo.get('fieldName'));
                                            String fieldKey = fieldName.trim().toLowerCase();
                                            String headerLabel = fieldApiVsTranslatedLabel != null && !fieldApiVsTranslatedLabel.isEmpty() && fieldApiVsTranslatedLabel.containsKey(fieldKey)
                                                ? fieldApiVsTranslatedLabel.get(fieldKey)
                                                : String.valueOf(fieldInfo.get('label'));
                                            innerHtml += '<th width="auto" style="border:1px solid gray;text-align:center;">'+headerLabel+'</th>';
                                            //-- End | FIN-9778 | Changed by Dhwanil | 22 May 2026 --//
                                            //-- End | FIN-8048 | Changed by Ravi | 29 July 2025 --//
                                        } catch (Exception e) {
                                            Map<String,Object> fieldInfo = (Map<String,Object>)field;
                                            //-- Start | FIN-8048 | Changed by Ravi | 29 July 2025 --//
                                            //-- Start | FIN-9778 | Changed by Dhwanil | 22 May 2026 --//
                                            String stringFieldName = String.valueOf(fieldInfo.get('fieldName'));
                                            String stringFieldKey = stringFieldName.trim().toLowerCase();
                                            String stringHeaderLabel = fieldApiVsTranslatedLabel != null && !fieldApiVsTranslatedLabel.isEmpty() && fieldApiVsTranslatedLabel.containsKey(stringFieldKey)
                                                ? fieldApiVsTranslatedLabel.get(stringFieldKey)
                                                : String.valueOf(fieldInfo.get('label'));
                                            innerHtml += '<th width="auto" style="border:1px solid gray;text-align:center;">'+stringHeaderLabel+'</th>';
                                            //-- End | FIN-9778 | Changed by Dhwanil | 22 May 2026 --//
                                            //-- End | FIN-8048 | Changed by Ravi | 29 July 2025 --//
                                        }
                                        
                                        
                                    }
                                    innerHtml += '</tr>';
                                    Object fieldvalue;
                                    Map<String,Double> totalMap = new Map<String,Double>();
                                    Double total = 0;
                                    String aggregationField = '';
                                    String totalTitle = '';
                                    if(inMap.containsKey(step + 'showTotal') && inMap.get(step + 'showTotal') != null && (Boolean)inMap.get(step + 'showTotal') && inMap.containsKey(step + 'aggregationField') && inMap.get(step + 'aggregationField') != null){
                                        aggregationField = String.valueOf(inMap.get(step + 'aggregationField'));
                                        if(inMap.containsKey(step + 'totalTitle') && inMap.get(step + 'totalTitle') != null){
                                            totalTitle = String.valueOf(inMap.get(step + 'totalTitle'));
                                        }
                                    }
                                    for (Object vals : values) {
                                        String falign = 'left';
                                        Map<Object,Object> val = new Map<Object,Object>();
                                        Map<String,Object> val1 = new Map<String,Object>();
                                        Boolean objectMap = true;
                                        Boolean printRow = true;
                                        if (vals instanceof Map<Object,Object>) {
                                            val =(Map<Object,Object>)vals;
                                            if (isTaskScreen && val.containsKey('isSelected') && (Boolean)val.get('isSelected') == false) {
                                                printRow = false;
                                            }
                                        } else {
                                            String objVal = JSON.serialize(vals);
                                            val1 = (Map<String, Object>)JSON.deserializeUntyped(objVal);
                                            if (isTaskScreen && val1.containsKey('isSelected') && (Boolean)val1.get('isSelected') == false) {
                                                printRow = false;
                                            }
                                            objectMap = false;
                                        }
                                        if (printRow) {
                                            j=j+1;
                                            innerHtml += '<tr>';
                                            for (Object field : columns) {
                                                String fieldName = '';
                                                try {
                                                    Map<Object,Object> fieldInfo = (Map<Object,Object>)field;
                                                    fieldName = (String)fieldInfo.get('fieldName');
                                                } catch (Exception e) {
                                                    Map<String,Object> fieldInfo = (Map<String,Object>)field;
                                                    fieldName = (String)fieldInfo.get('fieldName');
                                                }
                                                if (fieldName != 'RemoveCommunication') {
                                                    if (fieldName.equalsIgnoreCase('name') || fieldMap.get(fieldName).getDescribe().getType() == Schema.DisplayType.REFERENCE) {
                                                        String tempfield = '';
                                                        if (objectMap) {
                                                            tempfield = fieldName + '-email';
                                                            fieldvalue = val.get(tempfield);
                                                        } else {
                                                            if (fieldName.equalsIgnoreCase('name')) {
                                                                tempfield = fieldName;
                                                            } else if (fieldMap.get(fieldName.toLowerCase()).getDescribe().isCustom()) {
                                                                tempfield= fieldName.subString(0,fieldName.length()-1)+ 'r';
                                                            } else {
                                                                tempfield= fieldName.subString(0,fieldName.length()-2);
                                                            }
                                                            System.debug('tempfield--> ' + tempfield);
                                                            System.debug('val1--> ' + val1);
                                                            if (!fieldName.equalsIgnoreCase('name')) {
                                                                Map<String,object> tempvalue = (Map<String,object>)val1.get(tempfield);
                                                                if (tempvalue != null) {
                                                                    fieldvalue = tempvalue.get('Name');
                                                                } else {
                                                                    fieldvalue = '';
                                                                }
                                                            } else {
                                                                fieldvalue = val1.get(tempfield);
                                                            }
                                                        }
                                                        
                                                    } else if (fieldMap.get(fieldName).getDescribe().getType().name() == 'CURRENCY'){
                                                        if(objectMap && val.get(fieldName) != null){
                                                            Double dtTemp = (Double)val.get(fieldName);
                                                            String currencyIsoCode = ( String )(UserInfo.IsMultiCurrencyOrganization() ? val.get('CurrencyIsoCode') : UserInfo.getDefaultCurrency());           
                                                                
                                                            fieldvalue =formatDoubleValue(currencyIsoCode ,dtTemp );
                                                        } else if(!objectMap && val1.get(fieldName) != null){
                                                            Double dtTemp = (Double)val1.get(fieldName);
                                                            String currencyIsoCode = ( String )(UserInfo.IsMultiCurrencyOrganization() ? val1.get('CurrencyIsoCode') : UserInfo.getDefaultCurrency());           
                                                                
                                                            fieldvalue =formatDoubleValue(currencyIsoCode ,dtTemp );
                                                        } else{
                                                            fieldvalue = '';
                                                        }
                                                    
                                                    } else if (fieldMap.get(fieldName).getDescribe().getType().name() == 'DATETIME'){
                                                        if (objectMap && val.get(fieldName) != null) {
                                                            List<String> dateList = String.valueOf(val.get(fieldName)).split('T');
                                                            String tempDate = dateList.get(0);
                                                            String tempTime = dateList.get(1).split('.000Z').get(0);
                                                            String finalDate = tempDate + ' ' + tempTime;
                                                            Datetime myDate = Datetime.valueOf(finalDate);
                                                            fieldvalue = myDate.format();
                                                        } else if(!objectMap && val1.get(fieldName) != null) {
                                                            // Start | Sejal 10/12/2024 | bug change (from val to val1)
                                                            List<String> dateList = String.valueOf(val1.get(fieldName)).split('T');
                                                            // End | Sejal 10/12/2024 | bug change (from val to val1)
                                                            String tempDate = dateList.get(0);
                                                            String tempTime = dateList.get(1).split('.000Z').get(0);
                                                            String finalDate = tempDate + ' ' + tempTime;
                                                            Datetime myDate = Datetime.valueOf(finalDate);
                                                            fieldvalue = myDate.format();
                                                        }
                                                    } else if (fieldMap.get(fieldName).getDescribe().getType().name() == 'DATE'){
                                                        if (objectMap && val.get(fieldName) != null) {
                                                            Date myDate = date.valueOf(String.valueOf(val.get(fieldName)));
                                                            fieldvalue = myDate.format();
                                                        } else if(!objectMap && val1.get(fieldName) != null) {
                                                            Date myDate = date.valueOf(String.valueOf(val1.get(fieldName)));
                                                            fieldvalue = myDate.format();
                                                        }
                                                    } else if (fieldMap.get(fieldName).getDescribe().getType().name() == 'INTEGER' || fieldMap.get(fieldName).getDescribe().getType().name() == 'DOUBLE' || fieldMap.get(fieldName).getDescribe().getType().name() == 'PERCENT'){   
                                                        //-- Start | FIN-9574 | Changed By Dhwanil | 23 Apr 2026 --//      
                                                        if (objectMap && val.get(fieldName) != null) {
                                                            fieldvalue =((Double)val.get(fieldName)).format();
                                                        } else if(!objectMap && val1.get(fieldName) != null) {
                                                            fieldvalue =((Double)val1.get(fieldName)).format();
                                                        }
                                                        //-- Ends | FIN-9574 | Changed By Dhwanil | 23 Apr 2026 --//
                                                    }else{
                                                        if (objectMap) {
                                                            fieldvalue = val.get(fieldName);
                                                        } else {
                                                            fieldvalue = val1.get(fieldName);
                                                        }
                                                        
                                                        if(fieldvalue == null){
                                                            fieldvalue = '';
                                                        }
                                                    }
                                                    String fType = fieldMap.get(fieldName).getDescribe().getType().name();
                                                    if(fType == 'INTEGER' || fType == 'DOUBLE' || fType == 'DECIMAL' || fType == 'PERCENTAGE' || fType == 'CURRENCY'){
                                                        falign = 'right';
                                                    }
                                                    System.debug('aggregationField--> ' + aggregationField + 'aggregationField == fieldName --> ' + fieldName);
                                                    if (aggregationField != '' &&  aggregationField == fieldName) {
                                                        Double dtTemp = 0.0;
                                                        if(objectMap && val.get(fieldName) != null){
                                                            dtTemp = (Double)val.get(fieldName);
                                                        } else if (!objectMap && val1.get(fieldName) != null) {
                                                            dtTemp = (Double)val1.get(fieldName);
                                                        }
                                                        if (fieldMap.get(fieldName).getDescribe().getType().name() == 'CURRENCY') {
                                                            //-- Start | FIN-8334 | Changed by Ravi | 11 sep 2025 --//
                                                            String currencyIsoCode =  UserInfo.getDefaultCurrency(); 
                                                            if(UserInfo.IsMultiCurrencyOrganization()){
                                                                if(objectMap && val.get(fieldName) != null) {
                                                                    currencyIsoCode = (String)val.get('CurrencyIsoCode');
                                                                } else if (!objectMap && val1.get(fieldName) != null) {
                                                                    currencyIsoCode = (String)val1.get('CurrencyIsoCode');
                                                                }

                                                            }   
                                                            //-- End | FIN-8334 | Changed by Ravi | 11 sep 2025 --//
                                                            if (totalMap.get(currencyIsoCode) != null) {
                                                                Double finalValue = totalMap.get(currencyIsoCode) + dtTemp;
                                                                totalMap.put(currencyIsoCode, finalValue);
                                                            } else {
                                                                totalMap.put(currencyIsoCode, dtTemp);
                                                            }
                                                        } else {
                                                            total = total + dtTemp;
                                                        }
                                                    }
                                                    //-- Start | FIN-8048 | Changed by Ravi | 29 July 2025 --//
                                                    innerHtml += '<td width="auto" style="text-align:'+falign+';border:1px solid gray;white-space:nowrap;">'+ fieldvalue+'</td>';
                                                    //-- End | FIN-8048 | Changed by Ravi | 29 July 2025 --//
                                                }
                                            }
                                            innerHtml += '</tr>';
                                        }
                                        
                                    }
                                    
                                    innerHtml += '</table><br>';
                                    if (aggregationField != '') {
                                        if (total > 0) {
                                            innerHtml += '<span style="float:right">' + totalTitle + ' ' + total + '</span>';
                                        } else {
                                            if (totalMap.keySet().size() > 0) {
                                                innerHtml += '<span style="float:right">' + totalTitle + ' ';
                                                for (String code : totalMap.keySet()) {
                                                    innerHtml += formatDoubleValue(code ,totalMap.get(code) ) + ',';
                                                }
                                                innerHtml = innerHtml.removeEnd(',') + '</span>';
                                            } else {
                                                innerHtml += '<span style="float:right">' + totalTitle + ' 0.0' + '</span>';
                                            }
                                        }
                                    }
                                    innerHtml += '<br>';
                                    String description = inMap.containsKey(step + 'description') && inMap.get(step + 'description') != null ? (String)inMap.get(step + 'description') : '';
                                    returnTemplateBody = returnTemplateBody.replace('{treatment.' + step + '}', description + innerHtml);
                                    //-- Start | FIN-9778 | Changed by Dhwanil | 25 May 2026 --//
                                    returnTemplateBody = returnTemplateBody.replace('{Transaction.Summary}', description + innerHtml);
                                    //-- End | FIN-9778 | Changed by Dhwanil | 25 May 2026 --//
                                }
                            }
                        }
                    }
                    
                }
            }
            if (returnTemplateBody.containsIgnoreCase('{treatment')) {
                for (Integer i = 1; i >0 ; i++) {
                    if (returnTemplateBody.containsIgnoreCase('{treatment')) {
                        Integer result = returnTemplateBody.indexOfIgnoreCase('{treatment', 0);
                        Integer result1 = returnTemplateBody.indexOfIgnoreCase('}', result);
                        System.debug('result>> ' + result + ' <<result1>> ' + result1);
                        String sub = returnTemplateBody.substring(result, result1 + 1);
                        returnTemplateBody = returnTemplateBody.replace(sub,'');
                    } else {
                        i = 0;
                        break;
                    }
                }
            }
            returnValue.put('htmlBody', returnTemplateBody);
            Task tsk = [SELECT Id, Subject, WhatId, celsrm__Treatment__c FROM Task WHERE Id=:recordId];
            String treatmentId = tsk.celsrm__Treatment__c;
            celsrm__Treatment__c treatment = [Select Id, Name, celsrm__Email_Template__c, celsrm__Account_Criteria__c, celsrm__Active__c, celsrm__Related_Object__c, celsrm__Treatment_Steps__c,celsrm__Task_Due_Date__c,celsrm__Task_Type__c,celsrm__Org_Id__c,celsrm__Template_Folder_Reference_Field__c, celsrm__Email_Template_Prefix__c From celsrm__Treatment__c Where Id=:treatmentId];
        }
        //-- Starts | FIN-88653 | Changed by Dhwanil | 23 dec 2025 --//
        if(isTaskScreen || isDunningScreen) { //-- Ends | FIN-88653 | Changed by Dhwanil | 23 dec 2025 --//
            List<Object> listOfStep = inMap.get('listOfStep') != null ? (List<Object>)inMap.get('listOfStep') : new List<Object>();
            Map<String, Set<Id>> stepToRecIds = new Map<String, Set<Id>>();
            //-- Start | FIN-8209 | Changed By Dilshad/Asera | 13-Aug-2025 --//
            if(inMap.containsKey('stepToRecIds') && inMap.get('stepToRecIds') != null){
                try {
                    stepToRecIds = (Map<String, Set<Id>>)inMap.get('stepToRecIds');
                } catch (Exception e) {
                    Object rawStepToRecIds = inMap.get('stepToRecIds');
                    if (rawStepToRecIds != null) {
                        Map<Object, Object> tempMap = (Map<Object, Object>)rawStepToRecIds;
                        for (Object keyObj : tempMap.keySet()) {
                            String key = (String)keyObj;
                            List<Object> idListObj = (List<Object>)tempMap.get(keyObj);
                            Set<Id> idSet = new Set<Id>();
                            for (Object idObj : idListObj) {
                                idSet.add((Id)idObj);
                            }
                            stepToRecIds.put(key, idSet);
                        }
                    }
                }
            } else {
                for (Object step : listOfStep) {
                    if (inMap.containsKey(step) && inMap.get(step) != null) {
                        List<Object> values = (List<Object>)inMap.get(step);
                        if (values.size() > 0) {
                            Set<Id> tmp = new Set<Id>();
                            for (Object vals : values) {
                                try{
                                    Map<Object,Object> val =(Map<Object,Object>)vals;
                                    if (val.containsKey('isSelected') && (Boolean)val.get('isSelected') == true) {
                                        tmp.add((Id)val.get('Id'));
                                    }
                                } catch (Exception e) {
                                    celsrm__Transaction__c trx = (celsrm__Transaction__c)vals;
                                    tmp.add(trx.Id);
                                }
                            }
                            if (tmp.size() > 0) {
                                stepToRecIds.put((String)step, tmp);
                            }
                        }
                    }
                }
            }
            //-- End | FIN-8209 | Changed By Dilshad/Asera | 13-Aug-2025 --//
            //-- Starts | FIN-88653 | Changed by Dhwanil | 23 dec 2025 --//
            String fileNameTemp = isDunningScreen ? 'Treatment Details':'Treatment Details Temp';
            //-- Ends | FIN-88653 | Changed by Dhwanil | 23 dec 2025 --//
            List<ContentDocumentLink> listContentDLTemp = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId =: recordId];
            Set<Id> conDocIdsTemp = new Set<Id>();
            for(ContentDocumentLink conDL : listContentDLTemp){
                conDocIdsTemp.add(conDL.ContentDocumentId);
            }
            List<ContentDocument> listContentDocTemp = [SELECT Id, FileExtension, Title, LastModifiedDate FROM ContentDocument WHERE Id IN :conDocIdsTemp and Title =: fileNameTemp];
            //-- Starts | FIN-88653 | Changed by Dhwanil | 23 dec 2025 --//
            Map<String, Set<Id>> tempstepToRecIds = new Map<String, Set<Id>>();
            if(seperateTaskForStep && treatmentStage!=null)
            {
                tempstepToRecIds.put(treatmentStage,stepToRecIds.get(treatmentStage));
            }
            else {
                tempstepToRecIds.putAll(stepToRecIds);
            }
            //-- Ends | FIN-88653 | Changed by Dhwanil | 23 dec 2025 --//
            if(!listContentDocTemp.isEmpty()){
                ContentDocument selectedContentDoc = listContentDocTemp.get(0);
                //-- Starts | FIN-88653 | Changed by Dhwanil | 23 dec 2025 --//
                ContentVersion contentVersion = new ContentVersion(
                    ContentDocumentId = selectedContentDoc.Id,
                    Title = isDunningScreen ? 'Treatment Details':'Treatment Details Temp',
                    PathOnClient = isDunningScreen ? 'treatmentdetails.json':'treatmentdetailstemp.json',
                    ReasonForChange = 'updated records',
                    VersionData = Blob.valueOf(JSON.serialize(tempstepToRecIds)),
                    IsMajorVersion = true
                );
                //-- Ends | FIN-88653 | Changed by Dhwanil | 23 dec 2025 --//
                insert contentVersion;
            } else {
                ContentVersion version = new ContentVersion();
                //-- Starts | FIN-88653 | Changed by Dhwanil | 23 dec 2025 --//
                version.VersionData = Blob.valueOf(JSON.serialize(tempstepToRecIds));
                version.Title = isDunningScreen ? 'Treatment Details':'Treatment Details Temp';
                                version.PathOnClient = isDunningScreen ? 'treatmentdetailsTemptreatmentdetails.json':'treatmentdetailstemp.json';
                insert version;
    
                // get content document
                List<ContentVersion> cVer = [Select Id, ContentDocumentId, Title, FileType, ContentSize, VersionData FROM ContentVersion WHERE Id = :version.Id];
    
                if(cVer != null && cVer.size() > 0) {
                    //link file with the task
                    system.debug('ContentDocumentId>>>>>> ' + cVer.get(0).ContentDocumentId);
                    ContentDocumentLink contentLink =new ContentDocumentLink();
                    contentLink.ContentDocumentId = cVer.get(0).ContentDocumentId;
                    contentLink.LinkedEntityId = recordId;
                    contentLink.ShareType = 'V';
                    insert contentLink;
                }
                //-- Ends | FIN-88653 | Changed by Dhwanil | 23 dec 2025 --//
            }
        }
        return returnValue;
    }
    public static String formatDoubleValue(String currencyCode, Double d) {
        String formattedCurrencyStr;
        String doubleVal = d.format();
        celsrm__CurrencyCode_Symbols__c currencyCodesettings = celsrm__CurrencyCode_Symbols__c.getInstance(currencyCode);
        
        if(currencyCodesettings!=null && currencyCodesettings.celsrm__Currency_Symbol__c!=null  ){
            formattedCurrencyStr = currencyCodesettings.celsrm__Currency_Symbol__c + ' ' + doubleVal;
        }
        else{
            formattedCurrencyStr = '$' + ' ' +doubleVal;
        }
        return formattedCurrencyStr;
    }

    //-- Starts | FIN-6892| Changes By: Asera | 18 Dec 2024 --//
    public static String getDynamicFromAddress(Map<Object, Object> currentValues, String parentId){
        String taskId = (String)currentValues.get('Id');
        String fromAddress = '';
        Task taskObj = [SELECT Id, Subject, WhatId, celsrm__Treatment__c, celsrm__Treatment_Stage__c FROM Task WHERE Id =: taskId];
        if(taskObj.celsrm__Treatment__c != null) { 
            String treatmentId = taskObj.celsrm__Treatment__c;
            celsrm__Treatment__c treatment = [Select Id, Name, celsrm__Email_Template__c, celsrm__Account_Criteria__c, celsrm__Active__c, celsrm__Related_Object__c, celsrm__Treatment_Steps__c,
                                                celsrm__Task_Due_Date__c,celsrm__Task_Type__c,celsrm__Org_Id__c,celsrm__Template_Folder_Reference_Field__c, celsrm__Email_Template_Prefix__c, 
                                                celsrm__Attachment__c, celsrm__Notify_Account_Owner__c, celsrm__Custom_Logic_Class__c, celsrm__Consolidated_Treatment__c, celsrm__Seperate_Task_For_Step__c,
                                                celsrm__Auto_Treatment__c, celsrm__Enable_Dynamic_Template__c, celsrm__Attachment_Name__c, celsrm__Attachment_Format__c, celsrm__Custom_Logic_For_Email_Body__c, celsrm__Enable_Dynamic_From_Address__c
                                                FROM celsrm__Treatment__c  Where Id=:treatmentId];

            Map<String, Id> emailToOweaIdMap = new Map<String, Id>();
            for (OrgWideEmailAddress owea : [SELECT Id, Address FROM OrgWideEmailAddress]) {
                    emailToOweaIdMap.put(owea.Address.toLowerCase(), owea.Id);
            }
            List<Object> listOfTreatmentStep = (List<Object>) JSON.deserializeUntyped(treatment.celsrm__Treatment_Steps__c);
            System.debug('listOfTreatmentStep>>>' + listOfTreatmentStep);
            if(!treatment.celsrm__Seperate_Task_For_Step__c) {
                if(treatment.celsrm__Enable_Dynamic_From_Address__c){
                    String query = 'SELECT ' +  String.escapeSingleQuotes(treatment.celsrm__Org_Id__c) + ' FROM Account WHERE Id=:parentId';
                    List<Account> accList = Database.query(query);
                    if (!accList.isEmpty() && accList.size() > 0) {
                        String fromAdd = string.valueOf(accList.get(0).get(treatment.celsrm__Org_Id__c));
                        System.debug('fromId>>>>1'+ fromAdd);
                        String lowerCaseEmail = fromAdd != null ? fromAdd.toLowerCase() : '';
                        if (fromAdd != null && String.valueOf(fromAdd).trim() != '' && emailToOweaIdMap.containsKey(lowerCaseEmail)) {
                            String fromId = emailToOweaIdMap.get(lowerCaseEmail);
                            fromAddress = fromId;
                        } else {
                                fromAddress = treatment.celsrm__Org_Id__c;
                                System.debug('Org_Id__c is null or empty for the record.');
                        }
                    }
                } else {
                    fromAddress = treatment.celsrm__Org_Id__c;
                }                             
            } else if(treatment.celsrm__Seperate_Task_For_Step__c && listOfTreatmentStep != null && listOfTreatmentStep.size() > 0){

                for(Object treatmentStep : listOfTreatmentStep) {
                        System.debug('step>>>1' + treatmentStep); 
                        Map<String, Object> step = (Map<String, Object>)treatmentStep;
                        System.debug('step>>>2' + step);
                        // Correctly accessing the key using get()
                        if (step.get('enableDynamicFromAddress') != null && (Boolean) step.get('enableDynamicFromAddress')) {
                            String query = 'SELECT ' + String.escapeSingleQuotes((String) step.get('fromAddress')) + ' FROM Account WHERE Id=:parentId';
                            List<Account> accList = Database.query(query);
                            if (!accList.isEmpty() && accList.size() > 0) {
                                String fromAdd = String.valueOf(accList.get(0).get((String) step.get('fromAddress')));
                                String lowerCaseEmail = fromAdd != null ? fromAdd.toLowerCase() : '';
                                if (fromAdd != null && fromAdd.trim() != '' && emailToOweaIdMap.containsKey(lowerCaseEmail)) {
                                    String fromId = emailToOweaIdMap.get(lowerCaseEmail);
                                    fromAddress = fromId;
                                } else {
                                    fromAddress = (String) step.get('fromAddress');
                                    System.debug('fromAddress is null or empty for the record.');
                                }
                                break;
                            }
                           
                        } else {
                            fromAddress = (String) step.get('fromAddress');
                        }
                }
            }
        }
        return fromAddress;
    }
    //-- End | FIN-6892| Changes By: Asera | 18 Dec 2024 --/
    //-- FIN-9729 | Changed by Dilshad | 04-May-2026 | Start --//
    public static Map<String, Object> updateComposeEmailBody(
        Map<Object, Object> currentValues,
        Id templateId,
        Map<String, Object> mapOfExtraParam,
        String functionName
    ) {
        if(currentValues != null && currentValues.containsKey('openFromSummaryAgent') && Boolean.valueOf(currentValues.get('openFromSummaryAgent')) == true){
            return setDataFormattingForEmail(currentValues, templateId, mapOfExtraParam, functionName);
        }

        Map<String, Object> returnVal = new Map<String, Object>();
        Map<Object, Object> workingValues = currentValues == null
            ? new Map<Object, Object>()
            : new Map<Object, Object>(currentValues);

        String listViewId = resolveComposeEmailListView(workingValues);
        if (String.isNotBlank(listViewId)) {
            workingValues.put('ListView', listViewId);
        }

        ensureComposeEmailTemplateContext(workingValues, templateId);

        try {
            Map<Object, Object> updateResult = SendStatementActionController.updateComposeEmailBody(workingValues);
            if (updateResult != null && updateResult.containsKey('ComposeEmail')) {
                Map<Object, Object> composeEmail = (Map<Object, Object>)updateResult.get('ComposeEmail');
                if (composeEmail != null) {
                    returnVal.put('ComposeEmail', composeEmail);
                    if (composeEmail.containsKey('body')) {
                        returnVal.put('htmlBody', composeEmail.get('body'));
                    }
                }
            }
            if (updateResult != null && updateResult.containsKey('returnTemplateAmount')) {
                returnVal.put('returnTemplateAmount', updateResult.get('returnTemplateAmount'));
            }
        } catch (Exception ex) {
            System.debug('setDataFormattingForEmailUsingUpdateComposeEmailBody error: ' + ex.getMessage());
            throw ex;
        }

        Messaging.SingleEmailMessage message = renderEmailTemplateMessage(templateId, workingValues);
        if (message != null) {
            if (!returnVal.containsKey('subject')) {
                returnVal.put('subject', message.getSubject());
            }
            //-- Start | FIN-9913 | Changed by Dhwanil | 10-Jun-2026 | --//
            // Keep the nested ComposeEmail payload aligned with the values consumed by the screen.
            Map<Object, Object> composeEmail = returnVal.containsKey('ComposeEmail') && returnVal.get('ComposeEmail') != null
                ? (Map<Object, Object>)returnVal.get('ComposeEmail')
                : new Map<Object, Object>();
            if (returnVal.containsKey('htmlBody')) {
                composeEmail.put('htmlBody', returnVal.get('htmlBody'));
            }
            if (!composeEmail.containsKey('subject') || composeEmail.get('subject') == null) {
                composeEmail.put('subject', message.getSubject());
            }
            if (!composeEmail.containsKey('body') && message.getHtmlBody() != null) {
                composeEmail.put('body', message.getHtmlBody());
                returnVal.put('htmlBody', message.getHtmlBody());
            }
            returnVal.put('ComposeEmail', composeEmail);
            //-- End | FIN-9913 | Changed by Dhwanil | 10-Jun-2026 | --//
        }

        return returnVal;
    }

    private static String resolveComposeEmailListView(Map<Object, Object> currentValues) {
        String currentUser = UserInfo.getUserId();
        celsrm__User_Preference__c userPref;
        try {
            userPref = [
                SELECT Id, celsrm__sendStatementListView__c
                FROM celsrm__User_Preference__c
                WHERE celsrm__User__c = :currentUser
                LIMIT 1
            ];
        } catch (Exception e) {
            System.debug('resolveComposeEmailListView exception>> ' + e.getMessage());
        }

        String listViewId = currentValues != null && currentValues.get('ListView') != null
            ? String.valueOf(currentValues.get('ListView'))
            : null;
        String screenName = currentValues != null && currentValues.get('screenName') != null
            ? String.valueOf(currentValues.get('screenName'))
            : null;

        if (String.isBlank(listViewId) && screenName != 'Send Statement') {
            List<celsrm__Custom_List_View__c> dbView = [
                SELECT Id
                FROM celsrm__Custom_List_View__c
                WHERE celsrm__ListView_For_Object__c = 'celsrm__Transaction__c' AND celsrm__Is_Default__c = TRUE
                LIMIT 1
            ];
            if (!dbView.isEmpty()) {
                listViewId = dbView[0].Id;
            }
        } else if (String.isBlank(listViewId) && userPref != null) {
            listViewId = userPref.celsrm__sendStatementListView__c;
        }
        return listViewId;
    }

    private static void ensureComposeEmailTemplateContext(Map<Object, Object> currentValues, Id templateId) {
        Map<Object, Object> composeEmail = currentValues != null && currentValues.containsKey('ComposeEmail') &&
            currentValues.get('ComposeEmail') != null
            ? new Map<Object, Object>((Map<Object, Object>)currentValues.get('ComposeEmail'))
            : new Map<Object, Object>();

        if (templateId != null) {
            List<EmailTemplate> emailTemplates = [
                SELECT Id, Name
                FROM EmailTemplate
                WHERE Id = :templateId
                LIMIT 1
            ];
            if (!emailTemplates.isEmpty()) {
                //-- Start | FIN-9913 | Changed by Dhwanil | 10-Jun-2026 | --//
                // The selected template must win over stale ComposeEmail state from the previous selection.
                composeEmail.put('templateId', emailTemplates[0].Id);
                composeEmail.put('templateName', emailTemplates[0].Name);
                //-- End | FIN-9913 | Changed by Dhwanil | 10-Jun-2026 | --//
                currentValues.put('defaultTemplate', emailTemplates[0].Name);
            }
        }

        currentValues.put('ComposeEmail', composeEmail);
    }

    private static Messaging.SingleEmailMessage renderEmailTemplateMessage(Id templateId, Map<Object, Object> currentValues) {
        if (templateId == null || currentValues == null || currentValues.get('Id') == null) {
            return null;
        }

        Id accountId = (Id)currentValues.get('Id');
        Id contactId;
        List<Contact> contacts = [
            SELECT Id
            FROM Contact
            WHERE celsrm__Default__c = true AND AccountId = :accountId
            LIMIT 1
        ];
        if (!contacts.isEmpty()) {
            contactId = contacts[0].Id;
        }

        return contactId != null
            ? Messaging.renderStoredEmailTemplate(templateId, contactId, accountId)
            : Messaging.renderStoredEmailTemplate(templateId, null, accountId);
    }
    //-- FIN-9729 | Changed by Dilshad | 04-May-2026 | End --//
}