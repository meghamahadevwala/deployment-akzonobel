global with sharing class SendStatementActionController implements celsrm.GOGIScreenCustomLogic{
    @TestVisible
    private static final Integer STATEMENT_PDF_MAX_HTML_BYTES = 12000000;
    @TestVisible
    private static final Integer STATEMENT_PDF_URL_PARAM_MAX_LENGTH = 4000;
    @TestVisible
    private static final Integer STATEMENT_PDF_TEMP_CHUNK_SIZE = 100000;
    @TestVisible
    private static final Integer SEND_STATEMENT_EMAIL_BODY_TABLE_MAX_ROWS = 200;
    global Map<Object, Object> invoke(String functionName, Map<Object, Object> inMap) {
        System.debug('into class => SendStatementActionController');
        try {
            if (functionName == 'onLoadSendStatement') {
                inMap = onLoadSendStatement(inMap);
            } else if (functionName == 'onSubmitSendStatement') {
                inMap = onSubmitSendStatement(inMap);
            } else if (functionName == 'createStatementAttachment') {
                if(!inMap.containsKey('ListView') || inMap.get('ListView') == null || (String)inMap.get('ListView') == '') {
                    inMap.put('ggErrorMessage', Label.Select_List_View_Send_Statement);
                } else if(!inMap.containsKey('StatementFormat') || inMap.get('StatementFormat') == null || inMap.get('StatementFormat') == '') {
                    inMap.put('ggErrorMessage', Label.Select_Statement_Format_Send_Statement);
                } else {
                    inMap = createStatementAttachment(inMap);
                }
            } else if (functionName == 'changeListView') {
                return updateComposeEmailBody(inMap);
            //-- FIN-9729 | Changed by Dilshad | 04-May-2026 | Start --//
            // } else if (functionName == 'generatePublicURLforPDF') {
            //     inMap = generatePublicURLforPDF(inMap);
            
            } else if (functionName == 'generatePDFAttachment') {
                inMap = generatePDFAttachment(inMap);
            } else if (functionName == 'preparePDFAttachmentData') {
                inMap = preparePDFAttachmentData(inMap);
            } else if (functionName == 'saveStatementPdfTableHtmlChunk') {
                inMap = saveStatementPdfTableHtmlChunk(inMap);
            } else if (functionName == 'deleteStatementPdfTempChunks') {
                inMap = deleteStatementPdfTempChunks(inMap);
            //-- FIN-9729 | Changed by Dilshad | 04-May-2026 | End --//
            } else if (functionName == 'deleteAttachmentAfterSendStatement') {
                inMap = deleteAttachmentAfterSendStatement(inMap);
            } 
            // << CHANGE - MM - FIN-8174 - Dynamic translated headers based account local | Chanaged function updateCompanyCode -> updateAccountLocale>>
            else if (functionName == 'updateAccountLocale'){
                inMap = updateAccountLocale(inMap);
            }
        } catch (Exception ex) {
            throw new celsrm.CustomException(ex.getMessage()+'::'+ex.getStackTraceString());
        }
        return inMap;
    }

    public static Map<Object, Object> onLoadSendStatement(Map<Object, Object> inMap) {
        //-- Starts | FIN-8280| Changed by Asera | 17 April 2026 --//
        //-- FIN-9729 | Changed by Dilshad | 06-May-2026 | Start --//
        String accountLanguageCode = UtilityController.getAccountLanguageCode(String.valueOf(inMap.get('Id')));
        inMap.put('accountLanguageCode', accountLanguageCode);
        //-- FIN-9729 | Changed by Dilshad | 06-May-2026 | End --//
        //-- End | FIN-8280| Changed by Asera | 17 April 2026 --//

        Set<String> accountIds = new Set<String>();
        accountIds.add(String.valueOf(inMap.get('Id')));

        if (inMap.get('accountHierarchyChildIds') != null) {
            List<Object> tempList = (List<Object>)inMap.get('accountHierarchyChildIds');
            for(Object objId : tempList) {
                accountIds.add(String.valueOf(objId));
            }
        }
        inMap.put('accountIds', accountIds);
        UtilityController.TransactionQueryContext queryContext = UtilityController.buildTransactionQueryContext(inMap, accountIds);
        List<String> selectedFieldList = queryContext.selectedFields == null ? new List<String>() : new List<String>(queryContext.selectedFields);

        inMap.put('queryContext', queryContext);
        List<String> selectedFields = queryContext.selectedFields == null ? new List<String>() : new List<String>(queryContext.selectedFields);

        List<String> selectedFieldsLabel = new List<String>();
        if(accountLanguageCode != null && accountLanguageCode != ''){
            selectedFieldsLabel = UtilityController.getTranslatedLabelValues(accountLanguageCode, 'celsrm__Transaction__c', selectedFields);
        } else {
            selectedFieldsLabel = UtilityController.getTransactionFieldLabel(selectedFields);
        }
        inMap.put('selectedFieldsLabel', selectedFieldsLabel);
        System.debug('accountLanguageCode:'+accountLanguageCode);
        System.debug('selectedFieldsLabel:'+selectedFieldsLabel);


        String currentUser = UserInfo.getUserId();
        celsrm__User_Preference__c userPref  = new celsrm__User_Preference__c();
        try {
            // << START - MM - FIN-9931 - User Preference based on folder name - Send Statement >>
            // userPref = [SELECT Id,celsrm__sendStatementListView__c,celsrm__AttachmentTypes__c,celsrm__Is_Attach_Checked__c FROM celsrm__User_Preference__c WHERE celsrm__User__c =:currentUser LIMIT 1];
            String folderName = '';
            if(inMap.containsKey('ListViewFolderName') &&  inMap.get('ListViewFolderName') != null && inMap.get('ListViewFolderName') != '') {
                folderName = (String)inMap.get('ListViewFolderName');
            }
            userPref = [SELECT Id,celsrm__sendStatementListView__c,celsrm__AttachmentTypes__c,celsrm__Is_Attach_Checked__c FROM celsrm__User_Preference__c WHERE celsrm__User__c =:currentUser AND celsrm__List_View_Folder__c = :folderName LIMIT 1];
            // << END - MM - FIN-9931 - User Preference based on folder name - Send Statement >>
        } catch (Exception e) {
            System.debug('exception>> ' + e.getMessage());
        }
        if(userPref != null) {
            if (userPref.celsrm__sendStatementListView__c != null) {
                //-- Starts | FIN-6592 | Sejal | 19 Nov 2024 --//
                String ListViewId = userPref.celsrm__sendStatementListView__c;
                String currUser = UserInfo.getUserId();
                String objectName = String.valueOf(inMap.get('ListViewObject'));
                String objectParentField = String.valueOf(inMap.get('ListViewParentField'));
                String folderName = '';
                if(inMap.containsKey('ListViewFolderName') &&  inMap.get('ListViewFolderName') != null && inMap.get('ListViewFolderName') != '') {
                    folderName = (String)inMap.get('ListViewFolderName');
                }
                String query = 'Select Id, Name From celsrm__Custom_List_View__c Where celsrm__ListView_For_Object__c = :objectName ';
                query += ' AND Id = :ListViewId AND (celsrm__Is_Global__c = TRUE OR CreatedById = :currUser) ';
                if (!String.isBlank(folderName)) {
                    query += 'AND Folder_Name__c = \'' + folderName + '\' ';
                }
                // query += ' AND (Is_Global__c = TRUE ) ';
                System.debug('@@@ final query ' + query);
                List<celsrm__Custom_List_View__c> obj = Database.query(query);
                if(obj.size() > 0){
                    inMap.put('ListView',userPref.celsrm__sendStatementListView__c);
                }
                //-- Ends | FIN-6592 | Sejal | 19 Nov 2024 --//
            }
            if (userPref.celsrm__Is_Attach_Checked__c != null) {
                inMap.put('AttachCheckBox', userPref.celsrm__Is_Attach_Checked__c);
            }
            if (userPref.celsrm__AttachmentTypes__c != null) {
                inMap.put('StatementFormat', userPref.celsrm__AttachmentTypes__c);
            }
        }
        
        
        

        WCM_FetchdefaultView fetchdefaultViewObj = new WCM_FetchdefaultView();
        inMap = fetchdefaultViewObj.invoke('Send Statement', inMap);

        TaskTreatmentController taskTreatmentControllerObj = new TaskTreatmentController();
        inMap = taskTreatmentControllerObj.invoke('showTreatmentNotes', inMap);

        // << Start - ND - FIN-8132 - Email Templates based on Account Locale >>
        String accId = String.valueOf(inMap.get('Id'));
        Account account = [SELECT Id, Name, celsrm__Locale__c FROM Account WHERE Id=:accId];
        System.debug('celsrm__Locale__c>>' + account.celsrm__Locale__c);
        if(account.celsrm__Locale__c != null && account.celsrm__Locale__c != '' ){
            List<EmailTemplate> template = [SELECT Id,Folder.Name  FROM EmailTemplate where Folder.Name = :account.celsrm__Locale__c Limit 1];
            System.debug('template>>' + template);
            // << CHANGE - MM - FIN-8174 - Dynamic translated headers based account local | inMap key change CompanyCode -> accountLocale>>
            if(!template.isEmpty() && template.get(0).Folder.Name == account.celsrm__Locale__c){
                inMap.put('accountLocale', account.celsrm__Locale__c);
            } else{
                // << CHANGE - MM - FIN-8174 - Dynamic translated headers based account local | Default EN>>
                inMap.put('accountLocale', 'EN');
            }
        } else {
            // << CHANGE - MM - FIN-8174 - Dynamic translated headers based account local | Default EN>>
            inMap.put('accountLocale', 'EN');
        }

        // << End - ND - FIN-8132 - Email Templates based on Account Locale >>
        Boolean isActivityEmail = false; //|FIN-7502| Changed by Asera | 25 Nov 2025 --//
        if(inMap.containsKey('activityData')) {
            inMap.put('ListViewObject', 'celsrm__Transaction__c');
            inMap.put('ListViewParentField', 'celsrm__Account__c');
            //-- Starts | FIN-6361 | Changed by Dilshad | 28 Aug 2024 --//
            Map<Object, Object> activityData = (Map<Object, Object>)inMap.get('activityData');
            String emailId = (String) activityData.get('Id');
            inMap.put('emailMessageId', emailId);
            isActivityEmail = true; //|FIN-7502| Changed by Asera | 25 Nov 2025 --//
            //-- Ends | FIN-6361 | Changed by Dilshad | 28 Aug 2024 --//
        }
        //-- Start | FIN-8530 | Changed by Ravi | 10 Nov 2025 --//
        if (inMap.containsKey('accountHierarchyChildIds') && inMap.get('accountHierarchyChildIds') != null) {
            List<String> parentRecordIDs = new List<String>();
            if (inMap.get('accountHierarchyChildIds') != null) {
                List<Object> tempList = (List<Object>)inMap.get('accountHierarchyChildIds');
                for(Object objId : tempList) {
                    parentRecordIDs.add(String.valueOf(objId));
                }
            }
            if(inMap.get('Id') != null && parentRecordIDs.indexOf(String.valueOf(inMap.get('Id'))) != -1) {
                parentRecordIDs.remove(parentRecordIDs.indexOf(String.valueOf(inMap.get('Id'))));
            }
            List<Account> accountList = [Select Id, Name From Account where Id In :parentRecordIDs];
            String accountNames = '';
            for(Account acc : accountList) {
                accountNames += acc.Name + ', ';
            }
            accountNames = accountNames.removeEnd(', ');
            inMap.put('childAccountNames', accountNames);
        
            inMap.put('enableChildNotes', 'true');
            inMap.put('childAccountNotes', '<div id="accountBanner" style="background-color:#e3f2fd; color:#0d47a1; border:1px solid #90caf9; border-radius:8px;padding:0px 20px; width:fit-content; box-shadow:0 2px 6px rgba(0,0,0,0.15);font-size:15px; display:flex; justify-content:space-between; align-items:center;"><span><strong>Included Child Accounts: </strong>' + accountNames + '</span><span class="closeChildAccount" style="cursor:pointer; font-size:20px; font-weight:bold; margin-left:12px; color:#0d47a1;">×</span></div>');
        } else {
            inMap.put('childAccountNames', null);
            inMap.put('enableChildNotes', 'false');
        }
        //-- Starts |FIN-7502| Changed by Asera | 25 Nov 2025 --//
        try {
            // Build a new Map<String, Object> from inMap manually
            Map<String, Object> cleanMap = new Map<String, Object>();
            for (Object keyObj : inMap.keySet()) {
                if (keyObj instanceof String) {
                    String key = (String) keyObj;
                    if (key != 'removeTreatmentNotes' && key != 'treatmentNotes') {
                        cleanMap.put(key, inMap.get(key));
                    }
                }
            }
            Map<String, Object> inputParams = new Map<String, Object>{
                'userId' => UserInfo.getUserId(),
                'pageScreenName' => isActivityEmail ? 'Email: Send Statement': 'Customer: Send Statement',
                'actionPerformed' => false,
                'actionTakenTime' => null,
                'accountId' => inMap.get('Id'),
                'transactionId' => null,
                'disputeId' => null,
                'additionalMetadata' => JSON.serialize(new Map<String, Object>{
                    'SendStatementObj' => cleanMap,
                    'timestamp' => String.valueOf(Datetime.now())
                })
            };
            
            // Serialize the entire map into a JSON string
            String jsonInput = JSON.serialize(inputParams);
            
            // Log the activity with the new format
            String activityId = celsrm.SRMUtilityController.logActivity(jsonInput);
            
            // Assuming logActivity returns the activityId, you can now store it in your map
            inMap.put('activityLogId', activityId); 
            System.debug('Activity logged with Id: ' + activityId);
        } catch (Exception e) {
            System.debug('Failed to log activity: ' + e.getMessage());
        }
        //-- End |FIN-7502| Changed by Asera | 25 Nov 2025 --//
        //-- End | FIN-8530 | Changed by Ravi | 10 Nov 2025 --//
        return inMap;
    }

    // << Start - ND - FIN-8132 - Email Templates based on Account Locale >>
    // << CHANGE - MM - FIN-8174 - Dynamic translated headers based account local | inMap key change CompanyCode -> accountLocale >>
    public static Map<Object, Object> updateAccountLocale(Map<Object, Object> inMap) {
        try {
            // String accId = String.valueOf(inMap.get('Id'));
            // Account acc = [SELECT Id, Name, celsrm__Company_Code__c FROM Account WHERE Id=:accId];
            // System.debug('celsrm__Company_Code__c>>' + acc.celsrm__Company_Code__c);
            String accountLocale = String.valueOf(inMap.get('accountLocale'));
            System.debug('companyCode>>' + accountLocale);
            if(accountLocale != null && accountLocale != '' ){
                List<EmailTemplate> template = [SELECT Id,Folder.Name  FROM EmailTemplate where Folder.Name = :accountLocale Limit 1];
                System.debug('template>>' + template);
                if(!template.isEmpty() && template.get(0).Folder.Name == accountLocale){
                    inMap.put('accountLocale', accountLocale);
                } else{
                    // << CHANGE - MM - FIN-8174 - Dynamic translated headers based account local | Default EN>>
                    inMap.put('accountLocale', 'EN');
                }
            } else {
                // << CHANGE - MM - FIN-8174 - Dynamic translated headers based account local | Default EN>>
                inMap.put('accountLocale', 'EN');
            }
        } catch (Exception e) {
            System.debug('exception>> ' + e.getMessage());
        }
        return inMap;
    }
    // << End - ND - FIN-8132 - Email Templates based on Account Locale >>

    public static Map<Object, Object> onSubmitSendStatement(Map<Object, Object> inMap) {
        //-- Starts | FIN-7025 | Changed By Dilshad | 20 Jan 2025 --//
        Savepoint sp = Database.setSavepoint();
        //-- Ends | FIN-7025 | Changed By Dilshad | 20 Jan 2025 --//
        try {
            // << START - MM - FIN-9931 - User Preference based on folder name | Update user preferece on submit >>
            String ListView = (String)inMap.get('ListView');
            String formatType = (String)inMap.get('StatementFormat');
            String currentUser = UserInfo.getUserId();
            String folderName = '';
            if(inMap.containsKey('ListViewFolderName') &&  inMap.get('ListViewFolderName') != null && inMap.get('ListViewFolderName') != '') {
                folderName = (String)inMap.get('ListViewFolderName');
            }
            List<celsrm__User_Preference__c> userPrefList  = new List<celsrm__User_Preference__c>();
            userPrefList = [SELECT Id,celsrm__sendStatementListView__c,celsrm__AttachmentTypes__c,celsrm__Is_Attach_Checked__c FROM celsrm__User_Preference__c WHERE celsrm__User__c = :currentUser AND celsrm__List_View_Folder__c = :folderName LIMIT 1];
            celsrm__User_Preference__c userPref = new celsrm__User_Preference__c();
            if(userPrefList != null && userPrefList.size() > 0) {
                userPref = userPrefList.get(0);
            } else {
                userPref.celsrm__User__c = currentUser;
                userPref.celsrm__List_View_Folder__c = folderName;
            }
            userPref.celsrm__sendStatementListView__c = ListView;
            userPref.celsrm__Is_Attach_Checked__c = Boolean.valueOf(inMap.get('AttachCheckBox'));
            userPref.celsrm__AttachmentTypes__c = formatType;
            upsert userPref;
            // << END - MM - FIN-9931 - User Preference based on folder name | Update user preferece on submit >>

            String activityName = 'Send Statement';
            List<String> accIdList = new List<String>();
            //-- Start | FIN-8530 | Changed by Ravi | 10 Nov 2025 --//
            if (inMap.get('accountHierarchyChildIds') != null) {
                List<Object> tempList = (List<Object>)inMap.get('accountHierarchyChildIds');
                for(Object objId : tempList) {
                    accIdList.add(String.valueOf(objId));
                }
            }
            //-- End | FIN-8530 | Changed by Ravi | 10 Nov 2025 --//
            //Update Account - START
            String accountId = (String) inMap.get('Id');
            //-- Start | FIN-8530 | Changed by Ravi | 10 Nov 2025 --//
            if(!accIdList.contains(accountId)){
                accIdList.add(accountId);
            }
            //-- End | FIN-8530 | Changed by Ravi | 10 Nov 2025 --//
            Account accountObj = new Account();
            accountObj.Id = accountId;
            accountObj.celsrm__Last_Contact_Date__c = date.Today();
            accountObj.celsrm__Last_Contact_Method__c = activityName;
            accountObj.celsrm__Last_Contact_Type__c = 'Email';
            accountObj.celsrm__Latest_Note__c = 'Send Statement sent' + '\n' + (String)(((Map<Object,Object>)inMap.get('ComposeEmail')).get('subject'));
            accountObj.celsrm__Latest_Note_By__c = UserInfo.getUserId();
            accountObj.celsrm__Latest_Note_Date__c = date.today();
            update accountObj;
            //Update Account - END

            inMap = sendEmailToCustomer(inMap);
            //-- Starts | FIN-7025 | Changed By Dilshad | 20 Jan 2025 --//
            if(inMap.containsKey('ggErrorMessage')) {
                Database.rollback(sp);
                return inMap;
            }
            //-- Ends | FIN-7025 | Changed By Dilshad | 20 Jan 2025 --//

            Boolean isFollowUp = Boolean.valueOf(inMap.get('isFollowUp'));
            // Create Follow Up Task
            if(isFollowUp == true) {
                inMap = createFollowUpTask(inMap);
            }

            //Capture Activity on Account
            if(accIdList.size() > 0) {
                //-- Starts | FIN-6130 | Changed by Dilshad | 25 Jul 2024 --//
                //Datetime currentDateTime = Datetime.now();
                //SRMUtilityController.insertActivity(accIdList, 'celsrm__Account__c', activityName, currentDateTime, 100, null, UserInfo.getUserId(), null, 'Internal', null);
                //-- Ends | FIN-6130 | Changed by Dilshad | 25 Jul 2024 --//
            }
            // Capture Transaction Activity
            Map<Id, celsrm__Transaction__c> transMap = fetchTransactions(inMap);

            // Check if transMap is not null and has records
            if (transMap != null && !transMap.isEmpty()) {
                
                List<Id> TransIds = new List<Id>(transMap.keySet());            
                // Ensure TransIds is not empty
                if (!TransIds.isEmpty()) {
                    //-- Starts | FIN-9144 | Changed by Dhwanil | 04 Feb 2026 --//
                    TaskTreatmentController.insertTreatmentActivity(accIdList, TransIds, activityName, null);
                    //-- Ends | FIN-9144 | Changed by Dhwanil | 04 Feb 2026 --//
                    /*Datetime currentDateTime = Datetime.now();
                    SRMUtilityController.insertActivity(
                        TransIds, 
                        'celsrm__Transaction__c', 
                        activityName, 
                        currentDateTime, 
                        100, 
                        null, 
                        UserInfo.getUserId(), 
                        null, 
                        'Internal', 
                        null
                    );*/
                }
            } else {
                System.debug('No transactions found to process.');
            }
            //-- Starts |FIN-7502| Changed by Asera | 25 Nov 2025 --//
            try {
                Map<String, Object> cleanMap = new Map<String, Object>();
                for (Object keyObj : inMap.keySet()) {
                    if (keyObj instanceof String) {
                        String key = (String) keyObj;
                        if (key != 'removeTreatmentNotes' && key != 'treatmentNotes') {
                            cleanMap.put(key, inMap.get(key));
                        }
                    }
                }
                Map<String, Object> metadataMap = new Map<String, Object>{
                    'SendStatementObj' => cleanMap,
                    'timestamp' => String.valueOf(Datetime.now())
                };
                Id activityId = (Id) inMap.get('activityLogId');
                // Convert to JSON string
                String metadataJson = JSON.serialize(metadataMap);
                celsrm.SRMUtilityController.updateActivity(activityId, null);
                
                System.debug('Activity logged with Id: ' + activityId);
            } catch (Exception e) {
                System.debug('Failed to log activity: ' + e.getMessage());
            }
            //-- End |FIN-7502| Changed by Asera | 25 Nov 2025 --//
    
            //-- Starts | FIN-6361 | Changed by Dilshad | 28 Aug 2024 --//
            if(inMap.containsKey('activityData') && inMap.containsKey('emailMessageId')) {
                String emailMessageId = String.valueOf(inMap.get('emailMessageId'));
                UtilityController.updateActionTakenOnEmailMessage(emailMessageId, 'Send Statement');
            }
            //-- Ends | FIN-6361 | Changed by Dilshad | 28 Aug 2024 --//
        } catch (DmlException dmlEx) {
            Database.rollback(sp);
            System.debug('DML Exception: ' + dmlEx.getMessage());
            System.debug(dmlEx.getStackTraceString());
            inMap.put('ggErrorMessage', dmlEx.getMessage());
        } catch (QueryException queryEx) {
            Database.rollback(sp);
            System.debug('Query Exception: ' + queryEx.getMessage());
            System.debug(queryEx.getStackTraceString());
            inMap.put('ggErrorMessage', 'Query Exception: ' + queryEx.getMessage());
        } catch (NullPointerException nullEx) {
            Database.rollback(sp);
            System.debug('Null Pointer Exception: ' + nullEx.getMessage());
            System.debug(nullEx.getStackTraceString());
            inMap.put('ggErrorMessage', 'Null Pointer Exception: ' + nullEx.getMessage());
        } catch (NoAccessException noAccessEx) {
            Database.rollback(sp);
            System.debug('No Access Exception: ' + noAccessEx.getMessage());
            System.debug(noAccessEx.getStackTraceString());
            inMap.put('ggErrorMessage', 'No Access Exception: ' + noAccessEx.getMessage());
        } catch (Exception ex) {
            Database.rollback(sp);
            System.debug('General Exception: ' + ex.getMessage());
            System.debug(ex.getStackTraceString());
            inMap.put('ggErrorMessage', 'Error: ' + ex.getMessage());
        }

        return inMap;
    }

    public static Map<Object, Object> sendEmailToCustomer(Map<Object, Object> inMap) {
        GOGCustomEmailSend sendEmailObj = new GOGCustomEmailSend();
        inMap = sendEmailObj.invoke('', inMap);
        return inMap;

    }

    public static Map<Object, Object> createFollowUpTask(Map<Object, Object> inMap){
        System.debug('functionName=>createFollowUpTask');
        try {
            String accountId = (String) inMap.get('Id');
            Task openActivity = new Task();
            map < string, object > tempComposeEmail = (map < string, object > ) JSON.deserializeUntyped(JSON.serialize(inMap.get('ComposeEmail')));
            openActivity.Subject = String.valueOf(tempComposeEmail.get('subject'));
            //-- Changes regardin | FIN-6391 | Changed by Asera | 29 Aug 2024 Start --//
            // openActivity.Description = String.valueOf(tempComposeEmail.get('body'));
            //-- Changes regardin | FIN-6391 | Changed by Asera | 29 Aug 2024 End --//           
            openActivity.Status = 'Not Started';
            openActivity.WhatId = accountId;
            openActivity.ActivityDate = Date.valueOf((String) inMap.get('FollowUpDate'));
            openActivity.Type = 'Send Statement';
            openActivity.celsrm__Contact_Method__c = 'Email';
            insert openActivity;
        } catch (Exception ex) {
            System.debug(ex.getStackTraceString());
            throw new celsrm.GOGDataServiceException(ex.getMessage());
        }
        return inMap;
    
    }

    public static Map<Object, Object> updateComposeEmailBody(Map<Object, Object> inMap) {
        Map<Object, Object> returnMap = new Map<Object, Object>();
        try {
            Set<String> accountIds = new Set<String>();
            if(inMap.containsKey('accountIds')) {
                accountIds = normalizeStringSet(inMap.get('accountIds'));
            } else {
                accountIds.add(String.valueOf(inMap.get('Id')));
                if (inMap.get('accountHierarchyChildIds') != null) {
                    List<Object> tempList = (List<Object>)inMap.get('accountHierarchyChildIds');
                    for(Object objId : tempList) {
                        accountIds.add(String.valueOf(objId));
                    }
                }
            }

            

            UtilityController.TransactionQueryContext queryContext = UtilityController.buildTransactionQueryContext(inMap, accountIds);
            
            List<String> selectedFields = queryContext.selectedFields == null
                ? new List<String>()
                : new List<String>(queryContext.selectedFields);
            Map<String, String> selectedFieldsType = String.isBlank(queryContext.selectedFieldsType)
                ? new Map<String, String>()
                : (Map<String, String>)JSON.deserialize(queryContext.selectedFieldsType, Map<String, String>.class);
            
            List<celsrm__Transaction__c> transactions = UtilityController.fetchTransactions(queryContext, SEND_STATEMENT_EMAIL_BODY_TABLE_MAX_ROWS);

            List<String> selectedFieldsLabel = new List<String>();


            //-- FIN-9729 | Changed by Dilshad | 06-May-2026 | Start --//
            if(String.valueOf(inMap.get('accountLanguageCode')) != null && String.valueOf(inMap.get('accountLanguageCode')) != ''){
                selectedFieldsLabel = UtilityController.getTranslatedLabelValues(String.valueOf(inMap.get('accountLanguageCode')), 'celsrm__Transaction__c', selectedFields);
            } else {
                selectedFieldsLabel = UtilityController.getTransactionFieldLabel(selectedFields);
            }

            //Generate Compose Email Body (Html Table)
            String transactionSummaryTable = UtilityController.generateTrxnSummaryTableForEmailBody(transactions, selectedFields, selectedFieldsType, selectedFieldsLabel);
            //-- FIN-9729 | Changed by Dilshad | 06-May-2026 | End --//
            transactions.clear(); // release heap //

            // System.debug('composeEmailHtmlBody::' + composeEmailHtmlBody);
            System.debug('transactionSummaryTable::' + transactionSummaryTable);

            String composeEmailBody = generateEmailBodyFromTemplate(inMap);

            composeEmailBody = composeEmailBody.replace('{Transaction.Summary}', transactionSummaryTable);
            transactionSummaryTable = null; // release heap //

            //-- Total Balance String --//
            String currencyFieldName = UserInfo.IsMultiCurrencyOrganization() ? 'CurrencyIsoCode' : NULL;
            // << START - MM - FIN-10130 | Feature JIRA FIN-8279 - Email Attachment -> Totals by currencycode >> 
            // String transactionTotalBalanceStr = UtilityController.getTransactionTotalBalanceString(queryContext, currencyFieldName);
            Map<String, String> totalsMap = UtilityController.getTransactionTotalBalanceMap(queryContext, currencyFieldName);
            composeEmailBody = composeEmailBody.replace('{Transactions.TotalBalance}', totalsMap.containsKey('TotalBalance') ? totalsMap.get('TotalBalance') : null);
            composeEmailBody = composeEmailBody.replace('{Transactions.TotalOpenItems}', totalsMap.containsKey('TotalOpenItems') ? totalsMap.get('TotalOpenItems') : null);
            composeEmailBody = composeEmailBody.replace('{Transactions.TotalOverdueItems}', totalsMap.containsKey('TotalOverdueItems') ? totalsMap.get('TotalOverdueItems') : null);
            composeEmailBody = composeEmailBody.replace('{Transactions.TotalOverdueNotNotedItems}', totalsMap.containsKey('TotalOverdueNotNotedItems') ? totalsMap.get('TotalOverdueNotNotedItems') : null);
            // << START - MM - FIN-10130 | Feature JIRA FIN-8279 - Email Attachment -> Totals by currencycode >> 
            
            // << START - MM - FIN-9931 - User Preference based on folder name - Send Statement >>
            String ListView = (String)inMap.get('ListView');
            String formatType = (String)inMap.get('StatementFormat');
            String currentUser = UserInfo.getUserId();
            List<celsrm__User_Preference__c> userPrefList  = new List<celsrm__User_Preference__c>();
            String folderName = '';
            if(inMap.containsKey('ListViewFolderName') &&  inMap.get('ListViewFolderName') != null && inMap.get('ListViewFolderName') != '') {
                folderName = (String)inMap.get('ListViewFolderName');
            }
            userPrefList = [SELECT Id,celsrm__sendStatementListView__c,celsrm__AttachmentTypes__c,celsrm__Is_Attach_Checked__c FROM celsrm__User_Preference__c WHERE celsrm__User__c = :currentUser AND celsrm__List_View_Folder__c = :folderName LIMIT 1];
            celsrm__User_Preference__c userPref = new celsrm__User_Preference__c();
            if(userPrefList != null && userPrefList.size() > 0) {
                userPref = userPrefList.get(0);
            } else {
                userPref.celsrm__User__c = currentUser;
                userPref.celsrm__List_View_Folder__c = folderName;
            }
            userPref.celsrm__sendStatementListView__c = ListView;
            userPref.celsrm__Is_Attach_Checked__c = Boolean.valueOf(inMap.get('AttachCheckBox'));
            userPref.celsrm__AttachmentTypes__c = formatType;
            upsert userPref;
            // << END - MM - FIN-9931 - User Preference based on folder name - Send Statement >>

            Map<Object, Object> composeEmail = new Map<Object, Object>();
            if(inMap.containsKey('ComposeEmail')) {
                composeEmail = (Map<Object, Object>) inMap.get('ComposeEmail');
            }
            composeEmail.put('body', composeEmailBody);
            returnMap.put('ComposeEmail', composeEmail);

        } catch (Exception e) {
            System.debug('Error'+e.getMessage()+e.getStackTraceString());
            throw new celsrm.CustomException(e.getStackTraceString());
        }
        return returnMap;
    }

    public static Map<Object, Object> createStatementAttachment(Map<Object, Object> inMap) {
        try {
            Set<String> accId = new Set<String>();
            accId.add(String.valueOf(inMap.get('Id')));

            String formatType = (String)inMap.get('StatementFormat');   //PDF or Excel
            String ListView = (String)inMap.get('ListView');            //userPref.celsrm__sendStatementListView__c

            celsrm__Custom_List_View__c customListViewObj = new celsrm__Custom_List_View__c();
            List<celsrm__Custom_List_View__c> customListViewList = [SELECT Id, Name, celsrm__Object_Fields__c, celsrm__Filter_Criteria__c,celsrm__ListView_For_Object__c,celsrm__Sort_By_Field__c, celsrm__Sort_By_Order__c FROM celsrm__Custom_List_View__c WHERE Id = :ListView LIMIT 1];
            String selectedFields = '';
            //-- Start | FIN-8949 | Changed by Dhwanil | 30 Jan 2026 --//
            String selectedFieldsType = '';
            if(customListViewList != null && customListViewList.size() > 0) {
                customListViewObj = customListViewList.get(0);
                if(customListViewObj.celsrm__Object_Fields__c != null && customListViewObj.celsrm__Object_Fields__c != '') {
                    selectedFields = UtilityController.getQueryFields(customListViewObj.celsrm__Object_Fields__c, 'celsrm__Transaction__c');
                    selectedFieldsType = UtilityController.getQueryFieldsType(customListViewObj.celsrm__Object_Fields__c, 'celsrm__Transaction__c');
                }
            }

            inMap.put('selectedFieldTypes',selectedFieldsType);
            // list<celsrm__Transaction__c> lstTrans = fetchTransactions(inMap);
            Map<Id, celsrm__Transaction__c> transMap = fetchTransactions(inMap);
            List<celsrm__Transaction__c> lstTrans = new List<celsrm__Transaction__c>(transMap.values());
            List<StaticResource> sr = [SELECT Id FROM StaticResource WHERE Name = 'CompanyLogo' LIMIT 1];
            inMap.put('hasCompanyLogo', !sr.isEmpty());
            inMap.put('statementDate', Date.today());
            inMap.put('orgName', UserInfo.getOrganizationName());
            //--Start | FIN-9250 | Changed by Dhwanil | 18-Feb-2026 --//
            inMap.put('LOCALE', UserInfo.getLocale());
            //--End | FIN-9250 | Changed by Dhwanil | 18-Feb-2026 --//
            if (inMap.containsKey('Id') && inMap.get('Id') != null) {
                try {
                    Id accountId = (Id)inMap.get('Id');
                    Account acc = [SELECT Name, AccountNumber FROM Account WHERE Id = :accountId LIMIT 1];
                    inMap.put('customerName', acc.Name);
                    inMap.put('customerNumber', acc.AccountNumber);
                } catch (Exception e) {
                    System.debug('Could not retrieve Account details for Excel generation. Error: ' + e.getMessage());
                }
            }
            inMap.put('DueTransList',lstTrans);
            inMap.put('selectedFields',selectedFields.split(','));
            //-- Starts | FIN-8280| Changed by Asera | 17 April 2026 --//
            // List<string> FieldsLabel = UtilityController.getTransactionFieldLabel(selectedFields.split(','));
            //-- FIN-9729 | Changed by Dilshad | 06-May-2026 | Start --//
            String accountLanguageCode = (String)inMap.get('accountLanguageCode');
            List<String> FieldsLabel = new List<String>();
            if(accountLanguageCode != null && accountLanguageCode != ''){
                FieldsLabel = UtilityController.getTranslatedLabelValues(accountLanguageCode, 'celsrm__Transaction__c', selectedFields.split(','));
            } else {
                FieldsLabel = UtilityController.getTransactionFieldLabel(selectedFields.split(','));
            }
            //-- FIN-9729 | Changed by Dilshad | 06-May-2026 | End --//
            //-- End | FIN-8280| Changed by Asera | 17 April 2026 --//
            inMap.put('selectedFieldsLabel',FieldsLabel );
            //-- Start | FIN-7269 | 11-April-2025 -- (Attachment Related changes)//
            if(formatType == 'Excel' || formatType == 'PDF') {
                system.debug('from Excel createStatementAttach>>' + inMap);
                 //-- Start | FIN-9048 | Chanegs by Asera 02-Feb-2026--//
                 if(inMap.containsKey('attachment-template') && inMap.get('attachment-template') != null) {
                    try {
                        String emailAttachmentTemplate = (String)inMap.get('attachment-template');
                        String emailAttachmentTemplateFolder = inMap.containsKey('attachment-template-folder') ? (String)inMap.get('attachment-template-folder') : null;
                        List<EmailTemplate> emailTemplateList = new List<EmailTemplate>();
                        
                        if (String.isNotBlank(emailAttachmentTemplateFolder)) {
                             emailTemplateList = [SELECT Id, Name, Subject, HtmlValue, Body FROM EmailTemplate WHERE Name = :emailAttachmentTemplate AND Folder.Name =: emailAttachmentTemplateFolder WITH SECURITY_ENFORCED LIMIT 1];
                        }
                        
                        if(emailTemplateList.isEmpty()){
                             emailTemplateList = [SELECT Id, Name, Subject, HtmlValue, Body FROM EmailTemplate WHERE Name = :emailAttachmentTemplate WITH SECURITY_ENFORCED LIMIT 1];
                        }

                        if(!emailTemplateList.isEmpty()){
                            String accountId = (new list<string> (accId))[0];
                            Messaging.SingleEmailMessage message = Messaging.renderStoredEmailTemplate(emailTemplateList[0].Id, null, accountId);
                            // << START - MM - FIN-9455 - Send Statement -> Replace custom placeholders and translations >> 
                            // inMap.put('templateBody', message.getHtmlBody());
                            System.debug('Fetched template body for attachment: ' + message.getHtmlBody());
                            String attachmentHtmlBody = message.getHtmlBody();
                            if (attachmentHtmlBody.Contains('{Transactions.TotalOpenItems}') || attachmentHtmlBody.Contains('{Transactions.TotalOverdueItems}') || attachmentHtmlBody.Contains('{Transactions.TotalOverdueNotNotedItems}')) {
                                Map<String,String> returnTemplateAmount = UtilityController.getTransactionTotalSummary((String)inMap.get('Id'),new List<Id>(transMap.keySet()));
                                attachmentHtmlBody = attachmentHtmlBody.replace('{Transactions.TotalOpenItems}', returnTemplateAmount.get('TotalOpenItems'));
                                attachmentHtmlBody = attachmentHtmlBody.replace('{Transactions.TotalOverdueItems}', returnTemplateAmount.get('TotalOverdueItems'));
                                attachmentHtmlBody = attachmentHtmlBody.replace('{Transactions.TotalOverdueNotNotedItems}', returnTemplateAmount.get('TotalOverdueNotNotedItems'));
                            }
                            attachmentHtmlBody = UtilityController.replaceCustomerSpecificPlaceholders(attachmentHtmlBody, accountLanguageCode);
                            inMap.put('templateBody', attachmentHtmlBody);
                            // << END - MM - FIN-9455 - Send Statement -> Replace custom placeholders and translations >> 
                            //-- Starts | FIN-9351 | Changed by Dhwanil | 03 Mar 2026 --//
                            Map<String, String> imageMap = UtilityController.extractImagesAsBase64(message.getHtmlBody());
                            inMap.put('templateBodyImageBase64Map', imageMap);
                            //-- Ends | FIN-9351 | Changed by Dhwanil | 03 Mar 2026 --//
                        }
                    } catch(Exception e) {
                        System.debug('Template Fetch Error: ' + e.getMessage());
                    }
                }
            }     
        } catch (Exception e) {
            System.debug(e.getMessage());
        }
        return inMap;
    }

    //-- FIN-9729 | Changed by Dilshad | 04-May-2026 | Start --//
    public static Map<Object, Object> generatePDFAttachment(Map<Object, Object> inMap) {
        String pdfAttachmentPageName = 'PDFAttachmentGenerator';
        String transactionTempKeyPrefix;
        String statementTableHtmlKey = inMap == null || !inMap.containsKey('statementTableHtmlKey')
            ? null
            : String.valueOf(inMap.get('statementTableHtmlKey'));
        Map<Object, Object> returnMap = new Map<Object, Object>();
        try {
            String accountId = inMap.get('Id') == null ? null : String.valueOf(inMap.get('Id'));
            String listViewId = inMap.get('ListView') == null ? null : String.valueOf(inMap.get('ListView'));
            if (String.isBlank(accountId)) {
                inMap.put('ggErrorMessage', 'Account Id is required to generate the statement PDF.');
                return inMap;
            }
            if (String.isBlank(listViewId)) {
                inMap.put('ggErrorMessage', Label.Select_List_View_Send_Statement);
                return inMap;
            }

            String safeFileName = PDFAttachmentGeneratorController.sanitizeStatementFileName(
                inMap.get('fileName') != null ? String.valueOf(inMap.get('fileName')) : 'BillingStatement'
            );
            PageReference pRef = new PageReference('/apex/' + pdfAttachmentPageName);
            pRef.getParameters().put('accountId', accountId);
            pRef.getParameters().put('listView', listViewId);
            pRef.getParameters().put('fileName', safeFileName);
            if (inMap.containsKey('attachment-template') && inMap.get('attachment-template') != null) {
                pRef.getParameters().put('attachmentTemplate', String.valueOf(inMap.get('attachment-template')));
            }
            if (inMap.containsKey('attachment-template-folder') && inMap.get('attachment-template-folder') != null) {
                pRef.getParameters().put('attachmentTemplateFolder', String.valueOf(inMap.get('attachment-template-folder')));
            }
            if (inMap.containsKey('ContactName') && inMap.get('ContactName') != null) {
                pRef.getParameters().put('contactId', String.valueOf(inMap.get('ContactName')));
            }
            //-- FIN-9729 | Changed by Dilshad | 06-May-2026 | start --//
            if (inMap.containsKey('accountLanguageCode') && inMap.get('accountLanguageCode') != null) {
                pRef.getParameters().put('accountLanguageCode', String.valueOf(inMap.get('accountLanguageCode')));
            }
            //-- FIN-9729 | Changed by Dilshad | 06-May-2026 | End --//

            String selectedTransactionIds = PDFAttachmentGeneratorController.serializeIdsForPageParam(inMap.get('TransactionList'));
            system.debug('selectedTransactionIds>>>>>'+selectedTransactionIds);
            if (String.isNotBlank(selectedTransactionIds)) {
                if (selectedTransactionIds.length() > STATEMENT_PDF_URL_PARAM_MAX_LENGTH) {
                    transactionTempKeyPrefix = PDFAttachmentGeneratorController.createStatementPdfTempChunks(selectedTransactionIds, STATEMENT_PDF_TEMP_CHUNK_SIZE);
                    pRef.getParameters().put('selectedTransactionKey', transactionTempKeyPrefix);
                } else {
                    pRef.getParameters().put('selectedTransactionIds', selectedTransactionIds);
                }
            }

            String childAccountIds = PDFAttachmentGeneratorController.serializeIdsForPageParam(inMap.get('accountHierarchyChildIds'));
            if (String.isNotBlank(childAccountIds)) {
                pRef.getParameters().put('childAccountIds', childAccountIds);
            }
            if (String.isNotBlank(statementTableHtmlKey)) {
                pRef.getParameters().put('statementTableHtmlKey', statementTableHtmlKey);
            }

            Blob pdfBlob = Test.isRunningTest() ? Blob.valueOf('Unit Test PDF') : pRef.getContentAsPDF();
            ContentVersion generatedVersion = insertStatementPdfContentVersion(pdfBlob, safeFileName, accountId);

            //inMap.put('StatementFormat', 'PDF');
            returnMap.put('ContentIDSendStmt', generatedVersion.Id);
            returnMap.put('ContentDocID', generatedVersion.ContentDocumentId);
            
            // The generated PDF is merged into ComposeEmail.attachment at submit time in GOGCustomEmailSend.
        } catch (celsrm.CustomException e) {
            System.debug('generatePDFAttachment error: ' + e.getMessage());
            returnMap.put('ggErrorMessage', resolveStatementPdfErrorMessage(e));
        } catch (Exception e) {
            System.debug('generatePDFAttachment error: ' + e.getMessage());
            returnMap.put('ggErrorMessage', resolveStatementPdfErrorMessage(e));
        } finally {
            PDFAttachmentGeneratorController.deleteStatementPdfTempChunks(transactionTempKeyPrefix);
            PDFAttachmentGeneratorController.deleteStatementPdfTempChunks(statementTableHtmlKey);
        }
        return returnMap;
    }

    public static Map<Object, Object> preparePDFAttachmentData(Map<Object, Object> inMap) {
        Map<Object, Object> workingMap = inMap == null ? new Map<Object, Object>() : new Map<Object, Object>(inMap);
        workingMap.put('StatementFormat', 'PDF');
        workingMap = PDFAttachmentGeneratorController.buildStatementPDFRenderContext(workingMap);

        Map<Object, Object> returnMap = new Map<Object, Object>();
        returnMap.put('DueTransList', workingMap.get('DueTransList'));
        returnMap.put('selectedFields', workingMap.get('selectedFields'));
        returnMap.put('selectedFieldsLabel', workingMap.get('selectedFieldsLabel'));
        returnMap.put('selectedFieldTypes', workingMap.get('selectedFieldTypes'));
        //-- FIN-9729 | Changed by Dilshad | 12-May-2026 | Start --//
        // returnMap.put('attachmentFontFamily', workingMap.get('attachmentFontFamily'));
        // returnMap.put('attachmentFontSize', workingMap.get('attachmentFontSize'));
        //-- FIN-9729 | Changed by Dilshad | 12-May-2026 | End --//
        returnMap.put('LOCALE', workingMap.get('LOCALE'));
        return returnMap;
    }

    public static Map<Object, Object> saveStatementPdfTableHtmlChunk(Map<Object, Object> inMap) {
        Map<Object, Object> returnMap = new Map<Object, Object>();
        if (inMap == null) {
            returnMap.put('ggErrorMessage', 'Statement table chunk data is required.');
            return returnMap;
        }

        String uploadToken = inMap.get('uploadToken') == null ? null : String.valueOf(inMap.get('uploadToken'));
        Integer chunkIndex;
        if (inMap.containsKey('chunkIndex') && inMap.get('chunkIndex') != null) {
            if (inMap.get('chunkIndex') instanceof Integer) {
                chunkIndex = (Integer)inMap.get('chunkIndex');
            } else {
                chunkIndex = Integer.valueOf(String.valueOf(inMap.get('chunkIndex')));
            }
        }
        String htmlChunk = inMap.get('htmlChunk') == null ? null : String.valueOf(inMap.get('htmlChunk'));
        returnMap.put(
            'statementTableHtmlKey',
            PDFAttachmentGeneratorController.saveStatementPdfTableHtmlChunk(uploadToken, chunkIndex, htmlChunk)
        );
        return returnMap;
    }

    public static Map<Object, Object> deleteStatementPdfTempChunks(Map<Object, Object> inMap) {
        if (inMap != null) {
            String tempKeyPrefix = null;
            if (inMap.containsKey('tempKeyPrefix') && inMap.get('tempKeyPrefix') != null) {
                tempKeyPrefix = String.valueOf(inMap.get('tempKeyPrefix'));
            } else if (inMap.containsKey('statementTableHtmlKey') && inMap.get('statementTableHtmlKey') != null) {
                tempKeyPrefix = String.valueOf(inMap.get('statementTableHtmlKey'));
            }
            PDFAttachmentGeneratorController.deleteStatementPdfTempChunks(tempKeyPrefix);
        }
        return new Map<Object, Object>();
    }
    //-- FIN-9729 | Changed by Dilshad | 04-May-2026 | End --//

    @TestVisible
    private static String resolveStatementPdfErrorMessage(Exception ex) {
        String exceptionMessage = ex == null ? null : ex.getMessage();
        if (String.isBlank(exceptionMessage)) {
            return 'Error: Unable to generate statement PDF.';
        }
        return 'Error: ' + exceptionMessage;
    }

    @TestVisible
    private static ContentVersion insertStatementPdfContentVersion(Blob pdfBlob, String fileName, String firstPublishLocationId) {
        ContentVersion cv = new ContentVersion();
        cv.Title = fileName;
        cv.PathOnClient = fileName + '.pdf';
        cv.VersionData = pdfBlob;

        Boolean canUseFirstPublishLocation = String.isNotBlank(firstPublishLocationId)
            && celsrm.GOGSecurityController.isCreateable('ContentVersion', 'VersionData,Title,PathOnClient,FirstPublishLocationId');
        if (canUseFirstPublishLocation) {
            cv.FirstPublishLocationId = firstPublishLocationId;
        }

        String createableFields = canUseFirstPublishLocation
            ? 'VersionData,Title,PathOnClient,FirstPublishLocationId'
            : 'VersionData,Title,PathOnClient';
        if (!celsrm.GOGSecurityController.isCreateable('ContentVersion', createableFields)) {
            throw new celsrm.CustomException('You do not have access to create the generated statement PDF.');
        }

        insert cv;
        return [
            SELECT Id, ContentDocumentId
            FROM ContentVersion
            WHERE Id = :cv.Id
            LIMIT 1
        ];
    }

    //public static List<celsrm__Transaction__c> fetchTransactions(Map<Object, Object> inMap) {
    public static Map<Id,celsrm__Transaction__c> fetchTransactions(Map<Object, Object> inMap) {
        //Fetch Transactions - START
        Set<String> accId = new Set<String>();
        accId.add(String.valueOf(inMap.get('Id')));
        //-- Start | FIN-8530 | Changed by Ravi | 10 Nov 2025 --//
        if (inMap.get('accountHierarchyChildIds') != null) {
            List<Object> tempList = (List<Object>)inMap.get('accountHierarchyChildIds');
            for(Object objId : tempList) {
                accId.add(String.valueOf(objId));
            }
        }
        //-- End | FIN-8530 | Changed by Ravi | 10 Nov 2025 --//
        String ListView = (String)inMap.get('ListView'); 
        List<Object> transactionRecords = inMap.containsKey('TransactionList') ? (List<Object>)inMap.get('TransactionList') : new List<Object>(); //FIN-7410 Changes by ravi
        celsrm__Custom_List_View__c customListViewObj = new celsrm__Custom_List_View__c();
        List<celsrm__Custom_List_View__c> customListViewList = [SELECT Id, Name, celsrm__Object_Fields__c, celsrm__Filter_Criteria__c,celsrm__ListView_For_Object__c,celsrm__Sort_By_Field__c, celsrm__Sort_By_Order__c FROM celsrm__Custom_List_View__c WHERE Id = :ListView LIMIT 1];
        String selectedFields = '';
        String whereCondition = '';
         //-- Start | FIN-7978 | Changed By Asera | 14 July 2025 --//
         String orderFields = '';
         //-- End | FIN-7978 | Changed By Asera | 14 July 2025 --//
        if(customListViewList != null && customListViewList.size() > 0) {
            customListViewObj = customListViewList.get(0);
            if(customListViewObj.celsrm__Object_Fields__c != null && customListViewObj.celsrm__Object_Fields__c != '') {
                selectedFields = UtilityController.getQueryFields(customListViewObj.celsrm__Object_Fields__c, 'celsrm__Transaction__c');
            }
            system.debug('selectedFields===>'+selectedFields);
            if(customListViewObj.celsrm__Filter_Criteria__c != null && customListViewObj.celsrm__Filter_Criteria__c != '') {
                whereCondition = UtilityController.getQueryWhereClause(customListViewObj.celsrm__Filter_Criteria__c);
            }
            system.debug('whereCondition===>'+whereCondition);
            //-- Start | FIN-7978 | Changed By Asera | 14 July 2025 --//
            if(customListViewObj.celsrm__Sort_By_Field__c != null && customListViewObj.celsrm__Sort_By_Field__c != '') {
                orderFields = UtilityController.getQuerySortOrder(customListViewObj.celsrm__Sort_By_Field__c, true);
            }
            //-- End | FIN-7978 | Changed By Asera | 14 July 2025 --//
        }

        if(whereCondition != '' && whereCondition != null) {
            //-- Start | FIN-8530 | Changed by Ravi | 10 Nov 2025 --//
            // if ((Boolean)inMap.get('IsIncludeChild') == true) {
            //     System.debug('IsIncludeChild If Part');
            //     whereCondition += ' and (Account__c = :accId OR Account__r.parentid= :accId OR Account__r.parent.parentid= :accId )';
            // } else {
            System.debug('IsIncludeChild else part');
            whereCondition += ' and celsrm__account__c IN :accId';
            // }
            //-- End | FIN-8530 | Changed by Ravi | 10 Nov 2025 --//
        } else if(whereCondition == '') {
            //-- Start | FIN-8530 | Changed by Ravi | 10 Nov 2025 --//
            // if ((Boolean)inMap.get('IsIncludeChild') == true) {
            //     System.debug('IsIncludeChild If Part');
            //     whereCondition = ' WHERE celsrm__balance__c !=0 and (celsrm__Account__c= :accId OR celsrm__Account__r.parentid= :accId OR celsrm__Account__r.parent.parentid= :accId )';
            // } else {
            System.debug('IsIncludeChild else part');
            whereCondition = ' WHERE celsrm__balance__c !=0 and celsrm__account__c IN :accId'; 
            // }
            //-- End | FIN-8530 | Changed by Ravi | 10 Nov 2025 --//
                                        
        }
        //-- Start | FIN-7410 | 11-April-2025 -- Changes by Ravi //
        Set<String> trxIds = new Set<String>();
        if(transactionRecords != null && !transactionRecords.isEmpty()){
            for(Object obj : transactionRecords){
                Map<Object, Object> tempMap = (Map<Object, Object>)obj;
                trxIds.add(String.valueOf(tempMap.get('Id')));
            }
            if (!trxIds.isEmpty()) {
                whereCondition = whereCondition + ' AND Id IN :trxIds ';
            }
        }
        //-- End | FIN-7410 | 11-April-2025 -- (Changes By Ravi)//

        //-- Start | FIN-7978 | Changed By Asera | 14 July 2025 --//
        if(orderFields != '' || orderFields != null) {
            whereCondition += ' ' + orderFields + ' LIMIT 2000';
        } else {
            whereCondition += ' LIMIT 2000';
        }
        // whereCondition += ' LIMIT 2000';
        //-- End | FIN-7978 | Changed By Asera | 14 July 2025 --//
        system.debug('==whereCondition 1 ==='+whereCondition);

        List<string> formatedFieldName = UtilityController.getTransactionFieldformat(selectedFields.split(','),'celsrm__Transaction__c');
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
                }   
            if(st.equalsIgnoreCase('celsrm__base_balance__c') ){
                isHaveBaseBalanceField =true;
            }
            if(st.equalsIgnoreCase('currencyisocode') ){
                isHaveCurrencyIsoCodeField = true;
            }
        
        }
        String Queryfields = string.join(formatedFieldName,',');
        if(!hasRecordId) {
            Queryfields = 'id,' +  Queryfields;
        }
        if(isHaveBalanceField ==false){
            Queryfields = 'celsrm__balance__c,' +  Queryfields;
        }
        //....
        //add Base balance field id not exist in listview
        if(isHaveBaseBalanceField == false){
            Queryfields = 'celsrm__base_balance__c,' +  Queryfields;
        }
        //....
        
        if(isHaveCurrencyIsoCodeField == false &&  UserInfo.IsMultiCurrencyOrganization()){
            Queryfields = 'currencyisocode,' +  Queryfields;
        }
        if(Queryfields.endsWith(',')) {
            Queryfields = Queryfields.substring(0, Queryfields.length() - 1);
        }
        String stringToQuery = 'Select '+ Queryfields + ' from celsrm__Transaction__c ' +  whereCondition;
        System.debug('stringToQuery>>>>>>>>'+stringToQuery);

        List<celsrm__Transaction__c> lstTrans =  database.query(stringToQuery);
        Map<Id, celsrm__Transaction__c> transMap = new Map<Id, celsrm__Transaction__c>(lstTrans);
        lstTrans.clear();
        System.debug('heap Size'+ Limits.getHeapSize());
        return transMap;
    }

    public static String generateEmailBodyFromTemplate(Map<Object, Object> inMap) {
        String emailBodyContent = '<style>'
            + ' @page {'
            + '     size: A4 landscape;'
            + '     margin: 12mm 10mm 14mm 10mm;'
            + ' }'
            + ' table.txSummaryTable {'
            + '     width: 100%;'
            + '     border-collapse: collapse;'
            + '     border-spacing: 0;'
            + '     margin: 0;'
            + ' }'
            + ' table.txSummaryTable thead { display: table-header-group; }'
            + ' table.txSummaryTable tfoot { display: table-row-group; }'
            + ' table.txSummaryTable tr { page-break-inside: avoid; }'
            + ' table.txSummaryTable {'
            + '     -fs-table-paginate: paginate;'
            + '     border: 1px solid #1f2d3d;'
            + ' }'
            + ' table.txSummaryTable thead {'
            + '     display: table-header-group;'
            + ' }'
            + ' table.txSummaryTable tbody {'
            + '     display: table-row-group;'
            + ' }'
            + ' table.txSummaryTable th {'
            + '     font-weight: bold;'
            + ' }'
            + ' table.txSummaryTable th,'
            + ' table.txSummaryTable td {'
            + '     text-align: left;'
            + '     border: 1px solid #1f2d3d;'
            + '     padding: 2px;'
            + '     margin: 0;'
            + '     vertical-align: top;'
            + ' }'
            + ' table.txSummaryTable th.rightAlign,'  
            + ' table.txSummaryTable td.rightAlign {'
            + '    text-align: right;'
            + ' }'
            + '</style>';
        Map<Object, Object> composemail = (Map<Object, Object>)inMap.get('ComposeEmail');
        
        EmailTemplate emailTemplate = new EmailTemplate();
        String emailTemplateName = composemail.containskey('templateName') ? String.valueof(composemail.get('templateName')) : String.valueOf(inMap.get('defaultTemplate'));
        //-- FIN-9739 | Changed by Dilshad | 02-June-2026 | Start --//
        String emailTemplateFolder = inMap.containsKey('accountLanguageCode') ? String.valueOf(inMap.get('accountLanguageCode')) : inMap.containsKey('accountLocale') ? String.valueOf(inMap.get('accountLocale')) : null;
        if(emailTemplateName != null && emailTemplateFolder != null) {
            List<EmailTemplate> emailTemplates = [SELECT Id FROM EmailTemplate WHERE Name = :emailTemplateName AND Folder.Name = :emailTemplateFolder LIMIT 1];
            if(emailTemplates != null && emailTemplates.size() > 0) {
                emailTemplate = emailTemplates[0];
            } else {
                emailTemplate = [SELECT Id FROM EmailTemplate WHERE Name = :emailTemplateName LIMIT 1];
            }
        } else if(emailTemplateName != null) {
            emailTemplate = [SELECT Id FROM EmailTemplate WHERE Name = :emailTemplateName LIMIT 1];
        }
        //-- FIN-9739 | Changed by Dilshad | 02-June-2026 | End --//
        String accountId = (String)inMap.get('Id');
        Id ContactId;
        for (Contact conObj : [SELECT Id FROM Contact WHERE celsrm__Default__c=TRUE AND accountId = :accountId]) {
            ContactId = conObj.Id;
        }

        Messaging.SingleEmailMessage message;
        if( ContactId != null){
            message = Messaging.renderStoredEmailTemplate(emailTemplate.Id, ContactId , accountId);
        } else {
            message = Messaging.renderStoredEmailTemplate(emailTemplate.Id, null, accountId);
        }
        String bodyContent = emailBodyContent + message.getHtmlBody();

        EmailMessage emailmsg = new EmailMessage();
        try {
            emailmsg = [SELECT Id, FromName, FromAddress, ToAddress, CcAddress, BccAddress, Subject, CreatedDate, HtmlBody FROM EmailMessage WHERE relatedtoId = :accountId ORDER BY CreatedDate DESC LIMIT 1];
        } catch (Exception e) {
            System.debug(e.getMessage());
        }
        inMap.put('oldEmailmsg', emailmsg);

        if(inMap.containsKey('activityData')) {
            Map<Object, Object> activityData = (Map<Object, Object>)inMap.get('activityData');
            String emailId = (String) activityData.get('Id');
            emailmsg = new EmailMessage();
            try {
                emailmsg = [Select Id ,FromName,FromAddress,ToAddress,CcAddress,BccAddress,Subject,CreatedDate,HtmlBody,TextBody from EmailMessage where Id = :emailId];
            } catch (Exception e) {
                System.debug(e.getMessage());
            }
            if(emailmsg != null){
                if (emailmsg.FromName != null && emailmsg.FromAddress != null) {
                    bodycontent += '<br>  <hr> <b>From:</b> ' + emailmsg.FromName + ' &lt;' + emailmsg.FromAddress + '&gt;';
                }
                if (emailmsg.CreatedDate != null) {
                    bodycontent += '<br> <b>Sent:</b> ' + emailmsg.CreatedDate;
                }
                if (emailmsg.ToAddress != null) {
                    bodycontent += '<br> <b>To:</b> ' + emailmsg.ToAddress;
                }
                if (emailmsg.CcAddress != null) {
                    bodycontent += '<br> <b>Cc:</b> ' + emailmsg.CcAddress;
                }
                if (emailmsg.BccAddress != null) {
                    bodycontent += '<br> <b>Bcc:</b> ' + emailmsg.BccAddress;
                }
                if (emailmsg.Subject != null) {
                    bodycontent += '<br> <b>Subject:</b> ' + emailmsg.Subject;
                }
                if (emailmsg.HtmlBody != null) {
                    bodycontent += '<br><br>' + emailmsg.HtmlBody;
                }
                inMap.put('emailMessageId', emailmsg.Id);
            }
        }   
        return bodyContent;
    }

    // below 
    public static String getTransactionSummaryHTML(Map<Object, Object> inMap) {
        Decimal TotalBalance = 0;
        celsrm__SRM_Configuration__c systemConfig = celsrm__SRM_Configuration__c.getOrgDefaults();
        list<celsrm__Transaction__c> newLst = (list<celsrm__Transaction__c>) inMap.get('DueTransList');
        List<String> newLstFields = (list<String>) inMap.get('selectedFields');
        List<String> newLstFieldsLabel = (list<String>) inMap.get('selectedFieldsLabel');

        Schema.Sobjecttype objType = celsrm__Transaction__c.getSObjectType();
        Schema.Describesobjectresult sobjRes = objType.getDescribe();
        Map<String, Schema.Sobjectfield> fieldMap = sobjRes.fields.getMap();

        //String attachmentFontFamily = systemConfig.Attachment_Table_Font_Family__c != null ? systemConfig.Attachment_Table_Font_Family__c : 'verdana';
        //String attachmentFontSize = String.valueof(systemConfig.Attachment_Table_Font_Size__c != null ? systemConfig.Attachment_Table_Font_Size__c : 12) + 'px';
        //-- end | FIN-9543 | Changed by Dhwanil | 06 April 2026 --//
        // String ContentSt = (String) inMap.get('SendStmtAttachmentContent');
        String htmlBody = '<table class="txSummaryTable"><thead><tr>';
        for(String label: newLstFieldsLabel) {
            htmlBody = htmlBody + '<th><b>' + label + '</b></th>';
        }
        Map<String, String> fieldToType = new Map<String, String>();
        for (String fieldName: newLstFields) {
            if(fieldName != 'id' && fieldName != 'celsrm__Flag__c' && fieldName != 'celsrm__Latest_Note__c' && fieldName != 'celsrm__Latest_Note_Date__c'){
                Schema.Sobjectfield field = fieldMap.get(fieldName);
                Schema.Displaytype fieldDataType = field.getDescribe().getType();
                if(fieldDataType == Schema.DisplayType.REFERENCE){
                    fieldToType.put(fieldName, 'reference');
                } else {
                    fieldToType.put(fieldName, field.getDescribe().getType().name());
                }
            }
        }
        //-- End | FIN-5727 | Changed by Asera | 25 Oct 2024 --//
        htmlBody += '</tr></thead><tbody>';
        for (celsrm__Transaction__c trans: newLst) {
            htmlBody += '<tr>';

            for (String fName: newLstFields) {
                String fieldName = fName;
                Object fieldValue = '';
                if(fieldName != 'id' && fieldName != 'celsrm__Flag__c' && fieldName != 'celsrm__Latest_Note__c' && fieldName != 'celsrm__Latest_Note_Date__c'){
                    String rightAligned = '';
                    if(fieldToType.get(fieldName) == 'number' || fieldToType.get(fieldName) == 'currency' || fieldToType.get(fieldName) == 'percent') {
                        rightAligned = ' class="rightAlign"';
                    }
                    if(fieldToType.get(fieldName) == 'reference') {
                        fieldName = fieldName.subString(0,fieldName.length()-1)+ 'r';
                        if(trans.getSobject(fieldName) != null) {
                            fieldvalue = trans.getSobject(fieldName).get('name');
                        } else {
                            fieldvalue = '';
                        }   
                    } else if(fieldToType.get(fieldName) == 'DATE') {
                        if(trans.get(fieldName) != null){
                            Date dtTemp = (Date)trans.get(fieldName);
                            
                            fieldvalue =dtTemp.format();
                        } else {
                            fieldvalue = '';
                        }
                    } else {
                        if(fieldName == 'celsrm__balance__c') {
                            fieldName = 'Balance';
                        }
                        fieldvalue = trans.get(fieldName);
                        if(fieldvalue == null) {
                            fieldvalue = '';
                        }
                    }
                    htmlBody += '<td' + rightAligned + '>' + fieldValue + '</td>';     
                }
            }
            htmlBody += '</tr>';
            Decimal newAmt = trans.celsrm__Balance__c == null ? 0 : trans.celsrm__Balance__c;
            TotalBalance = TotalBalance + newAmt;
        }
        htmlBody += '</tbody></table>';
        return htmlBody;
    }

    public static String generateAttachmentAndEmailBody(Map<Object, Object> inMap) {
        Decimal TotalBalance = 0;
        celsrm__SRM_Configuration__c systemConfig = celsrm__SRM_Configuration__c.getOrgDefaults();
        list<celsrm__Transaction__c> newLst = (list<celsrm__Transaction__c>) inMap.get('DueTransList');
        List<String> newLstFields = (list<String>) inMap.get('selectedFields');
        List<String> newLstFieldsLabel = (list<String>) inMap.get('selectedFieldsLabel');
        //-- Starts | FIN-5727 | Changed by Asera | 25 Oct 2024 --//
        Schema.Sobjecttype objType = celsrm__Transaction__c.getSObjectType();
        Schema.Describesobjectresult sobjRes = objType.getDescribe();
        Map<String, Schema.Sobjectfield> fieldMap = sobjRes.fields.getMap();
        //-- End | FIN-5727 | Changed by Asera | 25 Oct 2024 --//

        //-- Start | FIN-9543 | Changed by Dhwanil | 06 April 2026 --//
        //String attachmentFontFamily = celsrm.SRMUtilityController.getAttachmentFontFamily();
        //String attachmentFontSize = celsrm.SRMUtilityController.getAttachmentFontSize();
        //-- end | FIN-9543 | Changed by Dhwanil | 06 April 2026 --//
        // String ContentSt = (String) inMap.get('SendStmtAttachmentContent');
        String htmlBody = '';
        // String composeEmailHtmlbody = '';
        Integer pg = 0;
        Double pageBreakAfter = 0;
        if(systemConfig.celsrm__Billing_Statement_PDF_Page_Break_First__c != null && systemConfig.celsrm__Billing_Statement_PDF_Page_Break_First__c != '' ){
            pageBreakAfter = double.valueOF(systemConfig.celsrm__Billing_Statement_PDF_Page_Break_First__c);
        }else{
            pageBreakAfter= 15;
        }
        //-- Start | FIN-9543 | Changed by Dhwanil | 06 April 2026 --//
        // String st =  '<head><meta http-equiv=\'Content-type\' content=\'text/html;charset=UTF-8\'><style> #txSummaryTableJS td{font-size:11px; text-align:left;  width:auto; border: solid 1px gray;padding-left: 3px;  padding-right: 3px;  white-space:nowrap;  font-family:Arial Unicode MS;}  #txSummaryTableJS th{ font-size:12px; background-color:#000000;color:White;border:1px solid gray;text-align: left;padding: 6px 6px 6px 3px;}  #txSummaryTableJS {border-collapse:collapse;padding:0px;border:1px solid gray; font-family:Arial Unicode MS;}@page {size:landscape; }</style>';
        htmlBody = '<table width=\'100%\' id=\'txSummaryTableJS\' style=""><tr>';
        //-- end | FIN-9543 | Changed by Dhwanil | 06 April 2026 --//
        // composeEmailHtmlbody = '<table width=\'100%\' id=\'txSummaryTableJS\'><tr>';
        for(String label: newLstFieldsLabel) {
            //-- Start | FIN-8048 | Changed by Ravi | 29 July 2025 --//
            htmlBody = htmlBody + '<th style="border:1px solid gray;text-align:left;"><b>' + label + '</b></th>';
            //-- End | FIN-8048 | Changed by Ravi | 29 July 2025 --//
        }
        //-- Starts | FIN-5727 | Changed by Asera | 25 Oct 2024 --//
        Map<String, String> fieldToType = new Map<String, String>();
        for (String fieldName: newLstFields) {
            if(fieldName != 'id' && fieldName != 'celsrm__Flag__c' && fieldName != 'celsrm__Latest_Note__c' && fieldName != 'celsrm__Latest_Note_Date__c'){
                Schema.Sobjectfield field = fieldMap.get(fieldName);
                Schema.Displaytype fieldDataType = field.getDescribe().getType();
                if(fieldDataType == Schema.DisplayType.REFERENCE){
                    fieldToType.put(fieldName, 'reference');
                } else {
                    fieldToType.put(fieldName, field.getDescribe().getType().name());
                }
            }
        }
        //-- End | FIN-5727 | Changed by Asera | 25 Oct 2024 --//
        htmlBody += '</tr>';
        for (celsrm__Transaction__c trans: newLst) {
            if(pg == pageBreakAfter && inMap.get('StatementFormat') == 'PDF') {
                htmlBody += '</table>';
                htmlBody += '<br>';
                //-- Start | FIN-8048 | Changed by Ravi | 29 July 2025 --//
                //-- Start | FIN-9543 | Changed by Dhwanil | 06 April 2026 --//
                htmlBody += '<table width=\'100%\' id=\'txSummaryTableJS\'><tr style="page-break-before:always;border-collapse:collapse;padding:0px;">';
                //-- ends | FIN-9543 | Changed by Dhwanil | 06 April 2026 --//
                //-- End | FIN-8048 | Changed by Ravi | 29 July 2025 --//
                for (Integer i = 0; i < newLstFieldsLabel.size(); i++) {
                    //-- Start | FIN-8048 | Changed by Ravi | 29 July 2025 --//
                    htmlBody = htmlBody + '<th style="border:1px solid gray;text-align:left;"><b>' + newLstFieldsLabel[i] + '</b></th>';
                    //-- End | FIN-8048 | Changed by Ravi | 29 July 2025 --//
                }
                htmlBody += '</tr>';
                pg = 0;
                if(systemConfig.celsrm__Billing_Statement_PDF_Page_Break_After__c != null && systemConfig.celsrm__Billing_Statement_PDF_Page_Break_After__c != '' ){
                    pageBreakAfter = double.valueOF(systemConfig.celsrm__Billing_Statement_PDF_Page_Break_After__c);
                }else{
                    pageBreakAfter= 40;
                }
                // pageBreakAfter = 32;
            }

            pg = pg + 1;
            htmlBody += '<tr>';
            // composeEmailHtmlbody += '</tr>';
            for (String fName: newLstFields) {
                String fieldName = fName;
                Object fieldValue = '';
                //-- Starts | FIN-5727 | Changed by Asera | 25 Oct 2024 --//
                if(fieldName != 'id' && fieldName != 'celsrm__Flag__c' && fieldName != 'celsrm__Latest_Note__c' && fieldName != 'celsrm__Latest_Note_Date__c'){
                    if(fieldToType.get(fieldName) == 'reference'){
                        
                        fieldName = fieldName.subString(0,fieldName.length()-1)+ 'r';
                        if(trans.getSobject(fieldName) != null){
                        fieldvalue = trans.getSobject(fieldName).get('name');
                        }else{
                        fieldvalue = '';
                        }
                        
                    }else if (fieldToType.get(fieldName) == 'DATE'){
                        if(trans.get(fieldName) != null){
                            Date dtTemp = (Date)trans.get(fieldName);
                            
                            fieldvalue =dtTemp.format();
                        }else {
                            fieldvalue = '';
                        }
                    }else{
                        if(fieldName == 'celsrm__balance__c'){
                            fieldName = 'Balance';
                        }
                        fieldvalue = trans.get(fieldName);
                        if(fieldvalue == null){
                            fieldvalue = '';
                        }
                    }
                    //-- Start | FIN-8048 | Changed by Ravi | 29 July 2025 --//
                    htmlBody += '<td width="auto" style="border:1px solid gray;text-align:left;white-space:nowrap;">' + fieldValue + '</td>';                
                    //-- End | FIN-8048 | Changed by Ravi | 29 July 2025 --//
                }
                //-- End | FIN-5727 | Changed by Asera | 25 Oct 2024 --//
            }
            htmlBody += '</tr>';
            // composeEmailHtmlbody += '</tr>';
            Decimal newAmt = trans.celsrm__Balance__c == null ? 0 : trans.celsrm__Balance__c;
            TotalBalance = TotalBalance + newAmt;
        }
        htmlBody += '</table>';
        // composeEmailHtmlbody += '</table>';

        return htmlBody;
        // Map<String, String> returnValMap = new Map<String, String>();
        // System.debug('composeEmailHtmlBody::' + composeEmailHtmlBody);
        // System.debug('htmlBody::' + htmlBody);
        // returnValMap.put('attachmentHtmlBody', htmlBody);
        // returnValMap.put('composeEmailHtmlBody', composeEmailHtmlbody);
        // return returnValMap;        
    }

    //-- FIN-9729 | Changed by Dilshad | 04-May-2026 | Start --//
    /*public static Map<Object, Object> generatePublicURLforPDF(Map<Object, Object> inMap) {
        if(inMap.containsKey('ContentIDSendStmt') && (String)inMap.get('ContentIDSendStmt') != null && (String)inMap.get('ContentIDSendStmt') != ''){
            String contentVersionId = (String)inMap.get('ContentIDSendStmt');
            System.debug('generatePublicURLforPDF>>' + contentVersionId);
            List<ContentVersion> cvList = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :contentVersionId LIMIT 1];
            if (cvList.isEmpty()) {
                System.debug('No ContentVersion found with Id: ' + contentVersionId);
                return inMap;
            }
            //-- Start | FIN-8509 | Changed by Ravi | 13-Oct-2025 --//
            String fileName = inMap.get('fileName') != null && inMap.get('fileName') != '' ? string.valueOf(inMap.get('fileName')) : 'BillingStatement';
            //-- Ends | FIN-8509 | Changed by Ravi | 13-Oct-2025 --//
            ContentDistribution cd = new ContentDistribution();
            cd.ContentVersionId = contentVersionId;
            //-- Start | FIN-8509 | Changed by Ravi | 13-Oct-2025 --//
            cd.Name = fileName;
            //-- Ends | FIN-8509 | Changed by Ravi | 13-Oct-2025 --//
            cd.PreferencesAllowViewInBrowser = true;
            cd.PreferencesLinkLatestVersion = true;
            cd.PreferencesExpires = true;
            cd.ExpiryDate = Date.today().addDays(1);
            insert cd;
            System.debug('public link created');
            
            cd = [SELECT Id, ContentDocumentId, DistributionPublicUrl FROM ContentDistribution WHERE Id = :cd.Id LIMIT 1];
            inMap.put('publicURL', cd.DistributionPublicUrl);
        }
        return inMap;
    }*/
    //-- FIN-9729 | Changed by Dilshad | 04-May-2026 | End --//

    public static Map<Object, Object> deleteAttachmentAfterSendStatement(Map<Object, Object> inMap) {
        if (inMap.containsKey('AttachmentIDSendStmt') && inMap.get('AttachmentIDSendStmt') != null) {
            String attachmentID = (String) inMap.get('AttachmentIDSendStmt');
            if (attachmentID != null){
                List<Attachment> attList = [SELECT Id FROM Attachment WHERE Id = :attachmentID];
                if (!attList.isEmpty()) {
                    delete attList[0];
                } else {
                    // Handle the case where Attachment is not found
                    // e.g., log a message or throw a custom exception
                }
            }  
        }

        inMap.remove('ContentIDSendStmt');
        inMap.remove('ContentDocID');
        inMap.remove('AttachmentIDSendStmt');
        return inMap;
    }

    private static Set<String> normalizeStringSet(Object rawValue) {
        Set<String> values = new Set<String>();
        if (rawValue == null) {
            return values;
        }

        if (rawValue instanceof Set<String>) {
            values.addAll((Set<String>)rawValue);
            return values;
        }

        if (rawValue instanceof List<Object>) {
            for (Object item : (List<Object>)rawValue) {
                if (item != null && String.isNotBlank(String.valueOf(item))) {
                    values.add(String.valueOf(item));
                }
            }
            return values;
        }

        if (rawValue instanceof List<String>) {
            for (String item : (List<String>)rawValue) {
                if (String.isNotBlank(item)) {
                    values.add(item);
                }
            }
            return values;
        }

        if (String.isNotBlank(String.valueOf(rawValue))) {
            values.add(String.valueOf(rawValue));
        }
        return values;
    }
    
}