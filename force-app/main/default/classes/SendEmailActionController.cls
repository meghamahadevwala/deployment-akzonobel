global with sharing class SendEmailActionController implements celsrm.GOGIScreenCustomLogic{
    global Map<Object, Object> invoke(String functionName, Map<Object, Object> inMap) {
        System.debug('into class => SendEmailActionController');
        try {
            if (functionName == 'onLoadSendEmail') {
                //-- FIN-9739 | Changed by Dilshad | 06-May-2026 | Start --//
                inMap = onLoadSendEmail(inMap);
                //-- FIN-9739 | Changed by Dilshad | 06-May-2026 | End --//
            } else if (functionName == 'createFollowUpTask' && inMap.get('isFollowUp') != null && (boolean) inMap.get('isFollowUp')) {
                inMap = createFollowUpTask(inMap);
            } else if (functionName == 'sendEmailToCustomer') {
                inMap = sendEmailToCustomer(inMap);
            } else if (functionName == 'sendTreatmentEmail') {
                inMap = sendTreatmentEmailToCustomer(inMap);
            } else if (functionName == 'captureCelonisEvent') {
                inMap = captureCelonisEvents(inMap);
            } else if (functionName == 'executeSendEmail') {
                inMap = executeSendEmail(inMap);
            } 
            //-- Start | FIN-7406 | FIN-7400 | Changed By Megha/Asera | 11 April 2025 --//
            else if (functionName == 'createStatementAttachment') {
                if(!inMap.containsKey('ListView') || inMap.get('ListView') == null || (String)inMap.get('ListView') == '') {
                    inMap.put('ggErrorMessage', Label.Select_List_View_Send_Statement);
                } else if(!inMap.containsKey('StatementFormat') || inMap.get('StatementFormat') == null || inMap.get('StatementFormat') == '') {
                    inMap.put('ggErrorMessage', Label.Select_Statement_Format_Send_Statement);
                } else {
                    inMap = createStatementAttachment(inMap);
                }
            }
            //-- End | FIN-7406 |FIN-7400 | Changed By Megha/Asera | 11 April 2025 --//
        } catch (Exception ex) {
            throw new celsrm.CustomException(ex.getMessage()+'::'+ex.getStackTraceString());
        }
        return inMap;
    }

    public static Map<Object, Object> executeSendEmail(Map<Object, Object> inMap) {
        //-- Starts | FIN-7025 | Changed By Dilshad | 20 Jan 2025 --//
        Savepoint sp = Database.setSavepoint();
        //-- Ends | FIN-7025 | Changed By Dilshad | 20 Jan 2025 --//
        try {
            // << START - MM - FIN-9931 - User Preference based on folder name | Update user preferece on submit >>
            String folderName = 'Send Statement';
            String currentUser = UserInfo.getUserId();
            List<celsrm__User_Preference__c> userPrefList  = new List<celsrm__User_Preference__c>();
            userPrefList = [SELECT Id,celsrm__sendStatementListView__c,celsrm__AttachmentTypes__c,celsrm__Is_Attach_Checked__c FROM celsrm__User_Preference__c WHERE celsrm__User__c = :currentUser AND celsrm__List_View_Folder__c = :folderName LIMIT 1];
            celsrm__User_Preference__c userPref = new celsrm__User_Preference__c();
            if(userPrefList != null && userPrefList.size() > 0) {
                userPref = userPrefList.get(0);
            } else {
                userPref.celsrm__User__c = currentUser;
                userPref.celsrm__List_View_Folder__c = folderName;
            }
            userPref.celsrm__Is_Attach_Checked__c = Boolean.valueOf(inMap.get('AttachCheckBox'));
            userPref.celsrm__AttachmentTypes__c = (String)inMap.get('StatementFormat');
            upsert userPref;
            // << END - MM - FIN-9931 - User Preference based on folder name | Update user preferece on submit >>

            List<Object> transactionList = (List<Object>)inMap.get('TransactionList');
            List < celsrm__Transaction__c > trxListToUpdate = new List < celsrm__Transaction__c > ();
            String activityName = Label.SRM_Send_Email;
            List < String > transIdList = new List < String > ();       //Make a list of Transaction Id in order to capture activities
            //-- Start | FIN-8530 | Changed by Ravi | 10 Nov 2025 --//
            Set < String > accIdList = new Set < String > ();         //Make a list of Account Id in order to capture activities
            //-- End | FIN-8530 | Changed by Ravi | 10 Nov 2025 --//
            //Make transaction list to update - START
            for (Object tr : transactionList) {
                Map<Object, Object> transMap = (Map<Object, Object>)tr;
                String transId = (String)transMap.get('Id');
                celsrm__Transaction__c currentTrx = New celsrm__Transaction__c(Id=transId);
                if(String.valueOf(inMap.get('NoteBody')) != null) {
                    currentTrx.celsrm__Latest_Note__c =  String.valueOf(inMap.get('NoteBody'));    
                    currentTrx.celsrm__Latest_Note_Date__c = date.today();
                    currentTrx.celsrm__Latest_Note_Entered_By__c = UserInfo.getUserId();
                }
                currentTrx.celsrm__Last_Contact_Date__c = date.Today();
                currentTrx.celsrm__Last_Contacted_By__c = UserInfo.getUserId();
                trxListToUpdate.add(currentTrx);
                transIdList.add(transId);
                //-- Start | FIN-8530 | Changed by Ravi | 10 Nov 2025 --//
                if(transMap.containsKey('celsrm__Account__c')) {
                    String accId = (String)transMap.get('celsrm__Account__c');
                    accIdList.add(accId);
                }
                //-- End | FIN-8530 | Changed by Ravi | 10 Nov 2025 --//
            }
            //Make transaction list to update - END

            if(transactionList.size() > 0) {
                update trxListToUpdate;
            }

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
            update accountObj;
            //Update Account - END


            Boolean isFollowUp = Boolean.valueOf(inMap.get('isFollowUp'));
            // Create Follow Up Task
            if(isFollowUp == true) {
                inMap = createFollowUpTask(inMap);
            }
            inMap = sendEmailToCustomer(inMap);
            //-- Starts | FIN-7025 | Changed By Dilshad | 20 Jan 2025 --//
            if(inMap.containsKey('ggErrorMessage')) {
                Database.rollback(sp);
                return inMap;
            }
            //-- Ends | FIN-7025 | Changed By Dilshad | 20 Jan 2025 --//
            inMap = sendTreatmentEmailToCustomer(inMap);

            //-- Starts | FIN-6130 | Changed by Dilshad | 25 Jul 2024 --//
            Datetime currentDateTime = Datetime.now();
            Map<String, String> accIdActivityIdMap = new Map<String, String>();
            //Capture activities for Accounts
            if(accIdList.size() > 0) {
                accIdActivityIdMap = celsrm.SRMUtilityController.insertActivity(new List<String>(accIdList), 'celsrm__Account__c', activityName, currentDateTime, 100, String.valueOf(inMap.get('NoteBody')), UserInfo.getUserId(), null, 'Internal', null);
            }
            //-- Starts |FIN-7502| Changed by Asera | 25 Nov 2025 --//
            try {
                Map<String, Object> additionalFields = new Map<String, Object>();
                for (String accId : accIdActivityIdMap.keySet()) {
                    additionalFields.put('celsrm__Parent_Event__c', accIdActivityIdMap.get(accId));
                }
                system.debug('from sendEmail inmap'+ JSON.serialize(inMap));
                Id activityId = (Id) inMap.get('activityLogId');
                system.debug('from sendEmail submit'+ activityId);
                // Convert to JSON string
                String metadataJson = JSON.serialize(additionalFields);
                System.debug('Additional Field ' + metadataJson);
                celsrm.SRMUtilityController.updateActivity(activityId, metadataJson);
                
                System.debug('Activity logged with Id: ' + activityId);
            } catch (Exception e) {
                System.debug('Failed to log activity: ' + e.getMessage());
                //-- Start | FIN-8530 | Changed by Ravi | 10 Nov 2025 --//
                accIdActivityIdMap = celsrm.SRMUtilityController.insertActivity(new List<String>(accIdList), 'celsrm__Account__c', activityName, currentDateTime, 100, String.valueOf(inMap.get('NoteBody')), UserInfo.getUserId(), null, 'Internal', null);
                //-- End | FIN-8530 | Changed by Ravi | 10 Nov 2025 --//
            }
            //-- End |FIN-7502| Changed by Asera | 25 Nov 2025 --//
            //Capture activities for Transactions
            if(transIdList.size() > 0) {
                Map<String, Object> additionalFields = new Map<String, Object>();
                for (String accId : accIdActivityIdMap.keySet()) {
                    additionalFields.put('celsrm__Parent_Event__c', accIdActivityIdMap.get(accId));
                }
                celsrm.SRMUtilityController.insertActivity(transIdList, 'celsrm__Transaction__c', activityName, currentDateTime, 100, String.valueOf(inMap.get('NoteBody')), UserInfo.getUserId(), null, 'Internal', additionalFields);
            }
            //-- Ends | FIN-6130 | Changed by Dilshad | 25 Jul 2024 --//
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
    
    public static Map<Object, Object> createFollowUpTask(Map<Object, Object> inMap){
        System.debug('functionName=>createFollowUpTask');
        String accountId = (String) inMap.get('Id');
        try {
            Task openActivity = new Task();
            map < string, object > tempComposeEmail = (map < string, object > ) JSON.deserializeUntyped(JSON.serialize(inMap.get('ComposeEmail')));
            openActivity.Subject = String.valueOf(tempComposeEmail.get('subject'));
            //-- Changes regardin | FIN-6391 | Changed by Asera | 29 Aug 2024 Start --//
            // openActivity.Description = (String) tempComposeEmail.get('body');
            //-- Changes regardin | FIN-6391 | Changed by Asera | 29 Aug 2024 End --//
            openActivity.Status = 'Not Started';
            openActivity.WhatId = accountId;
            openActivity.ActivityDate = Date.valueOf((String) inMap.get('FollowUpDate'));
            openActivity.Type = 'Send Email';
            openActivity.celsrm__Contact_Method__c = 'Email';
            insert openActivity;
        } catch (Exception ex) {
            System.debug(ex.getStackTraceString());
            throw new celsrm.GOGDataServiceException(ex.getMessage());
        }
        return inMap;
    }

    public static Map<Object, Object> sendEmailToCustomer(Map<Object, Object> inMap) {
        GOGCustomEmailSend sendEmailObj = new GOGCustomEmailSend();
        inMap = sendEmailObj.invoke('', inMap);
        return inMap;

    }

    public static Map<Object, Object> sendTreatmentEmailToCustomer(Map<Object, Object> inMap){
        TaskTreatmentController ttcObj = new TaskTreatmentController();
        inMap = ttcObj.invoke('includeTreatmentOnAccount', inMap);
        return inMap;

    }

    public static Map<Object, Object> captureCelonisEvents(Map<Object, Object> inMap){
        //-- Starts | Update Last Contact information on Account --//
        String accountId = (String) inMap.get('Id');
        Account accountObj = new Account();
        accountObj.Id = accountId;
        accountObj.celsrm__Last_Contact_Date__c = date.Today();
        accountObj.celsrm__Last_Contact_Method__c = 'Send Email';
        accountObj.celsrm__Last_Contact_Type__c = 'Email';
        update accountObj;
        //-- Ends | Update Last Contact information on Account --//

        Datetime currentDateTime = Datetime.now();
        String activityNote = inMap.get('NoteBody') != null && inMap.get('NoteBody') != '' ? String.valueOf(inMap.get('NoteBody')) : null;
        //-- Starts | Capture Celonis Event at Account Level --//
        List<String> accoutIdList = new List<String>();
        accoutIdList.add(accountId);
        //-- Starts | FIN-6130 | Changed by Dilshad | 25 Jul 2024 --//
        Map<String, String> accIdActivityIdMap = new Map<String, String>();
        accIdActivityIdMap = celsrm.SRMUtilityController.insertActivity(accoutIdList, 'celsrm__Account__c', 'Send Email', currentDateTime, 100, activityNote, UserInfo.getUserId(), null, 'Internal', null);
        //-- Ends | FIN-6130 | Changed by Dilshad | 25 Jul 2024 --//
        //-- Ends | Capture Celonis Event at Account Level --//

        //-- Starts | Update Last Contact & Latest Note information on invoices --//
        List < celsrm__Transaction__c > trxList = new List < celsrm__Transaction__c > ();
        List<Object> trxns = (List<Object>)inMap.get('TransactionList');
        List<String> transIDList = new List<String>();
        for(Object trxn : trxns) {
            map < Object, Object> m = (map < Object, Object > )trxn;
            String trxId = (String)m.get('Id');
            transIDList.add(trxId);
            celsrm__Transaction__c currentTrx = New celsrm__Transaction__c(Id=trxId);
            currentTrx.celsrm__Last_Contact_Date__c = date.Today();
            currentTrx.celsrm__Last_Contacted_By__c = UserInfo.getUserId();
            if(String.valueOf(inMap.get('NoteBody')) != null) {
                currentTrx.celsrm__Latest_Note__c =  String.valueOf(inMap.get('NoteBody'));    
                currentTrx.celsrm__Latest_Note_Title__c = String.valueOf(inMap.get('NoteTitle'));
                currentTrx.celsrm__Latest_Note_Date__c = date.today();
                currentTrx.celsrm__Latest_Note_Entered_By__c = UserInfo.getUserId();
            } 
            trxList.add(currentTrx);
            
        }
        if (trxList != null && trxList.size() > 0) {
            update trxList;
        }
        //-- Ends | Update Last Contact information on invoices --//
        
        //-- Starts | Capture Celonis Event at Invoice level --//   
        if(!transIDList.isEmpty()) {
            //-- Starts | FIN-6130 | Changed by Dilshad | 25 Jul 2024 --//
            Map<String, Object> additionalFields = new Map<String, Object>();
            for (String accId : accIdActivityIdMap.keySet()) {
                additionalFields.put('celsrm__Parent_Event__c', accIdActivityIdMap.get(accId));
            }
            celsrm.SRMUtilityController.insertActivity(transIDList, 'celsrm__Transaction__c', Label.SRM_Send_Email, currentDateTime, 100, activityNote, UserInfo.getUserId(), null, 'Internal', additionalFields);
            //-- Ends | FIN-6130 | Changed by Dilshad | 25 Jul 2024 --//
        }
        //-- Ends | Capture Celonis Event at Invoice level --//

        return inMap;
    }

    public static Map<Object,Object> showTreatmentNotes(Map<Object,Object> inMap) {
        Map<Object,Object> returnMap = new Map<Object,Object>();

        // << START - MM - FIN-9931 - Show data from User Preference >>
        String folderName = 'Send Statement';
        String currentUser = UserInfo.getUserId();
        celsrm__User_Preference__c userPref  = new celsrm__User_Preference__c();
        try {
            userPref = [SELECT Id,celsrm__sendStatementListView__c,celsrm__AttachmentTypes__c,celsrm__Is_Attach_Checked__c FROM celsrm__User_Preference__c WHERE celsrm__User__c =:currentUser AND celsrm__List_View_Folder__c = :folderName LIMIT 1];
            if(userPref != null) {
                if (userPref.celsrm__Is_Attach_Checked__c != null) {
                    returnMap.put('AttachCheckBox', userPref.celsrm__Is_Attach_Checked__c);
                }
                if (userPref.celsrm__AttachmentTypes__c != null) {
                    returnMap.put('StatementFormat', userPref.celsrm__AttachmentTypes__c);
                }
            }
        } catch (Exception e) {
            System.debug('exception>> ' + e.getMessage());
        }
        // << END - MM - FIN-9931 - Show data from User Preference >>
        
		String accId = String.valueOf(inMap.get('Id'));
        // << Start - ND - FIN-8132 - Email Templates based on Account Locale >>  {value.Company_Code}
        Account acc = [SELECT Id, Name, celsrm__Locale__c FROM Account WHERE Id=:accId];
        System.debug('celsrm__Locale__c>>' + acc.celsrm__Locale__c);
        if(acc.celsrm__Locale__c != null && acc.celsrm__Locale__c != '' ){
            List<EmailTemplate> template = [SELECT Id,Folder.Name  FROM EmailTemplate where Folder.Name = :acc.celsrm__Locale__c Limit 1];
            System.debug('template>>' + template);
            // << CHANGE - MM - FIN-8174 - Dynamic translated headers based account local | inMap key change CompanyCode -> accountLocale>>
            if(!template.isEmpty() && template.get(0).Folder.Name == acc.celsrm__Locale__c){
                returnMap.put('accountLocale', acc.celsrm__Locale__c);
            } else{
                // << CHANGE - MM - FIN-8174 - Dynamic translated headers based account local | Default EN>>
                returnMap.put('accountLocale', 'EN');
            }
        } else{
            // << CHANGE - MM - FIN-8174 - Dynamic translated headers based account local | Default EN>>
            returnMap.put('accountLocale', 'EN');
        }

        // << End - ND - FIN-8132 - Email Templates based on Account Locale >>
        List<Task> taskList = [SELECT Id,Subject FROM Task WHERE WhatId=: accId AND Status != 'Completed' AND celsrm__Treatment__c != '' order by CreatedDate desc LIMIT 1];
		if(taskList.size() > 0) {
            List<contact> conList = [SELECT Id,lastname,Fax,Email,AccountId,CC__c,Bcc__c,celsrm__Default__c From Contact where celsrm__Default__c =: TRUE AND AccountId=: accId order by lastname];
			returnMap.put('autoTaskId', taskList.get(0).Id);
			String to='';
			for(Contact contact:conList){
				if (contact.Email != null && contact.Email != '') {
					to += contact.Email + '; ';
				}
			}
			returnMap.put('treatmentEmail', to.removeEnd('; '));
			returnMap.put('treatmentNotes', '<div><div class="slds-notify slds-notify_alert system-message level-warning slds-theme_warning" style="display: block;text-align: left;border-radius: 0.5rem; font-weight: 700; background-color: #fedfd0;"><span>' + Label.Treatment_Include_Notes_Before_Subject + ' <a href="' + '/'+ taskList.get(0).Id + '"' + ' target="_blank" style="color: blue;">' + taskList.get(0).Subject + '</a>. ' + Label.Treatment_Include_Notes_After_Subject + ' </span><div style="right:0;top: 0.5rem;position: absolute;"><a class="oninclude" href="javascript:void(0);" style="padding-right:5px;" title='+ Label.Treatment_Include + '>'+Label.Treatment_Include+'</a><a class="onno" href="javascript:void(0);" style="padding-right:5px;" title='+Label.Treatment_Not_Include+'>'+Label.Treatment_Not_Include+'</a></div>' );
			returnMap.put('removeTreatmentNotes', '<div><div class="slds-notify slds-notify_alert system-message level-warning slds-theme_warning" style="display: block;text-align: left;border-radius: 0.5rem; 0.5rem; font-weight: 700; background-color: #fedfd0;"><span>' + Label.Treatment_Remove_Notes_Before_Subject + ' <a href="' + '/'+ taskList.get(0).Id + '"' + ' target="_blank" style="color: blue;">' + taskList.get(0).Subject + '</a> ' +  Label.Treatment_Remove_Notes_After_Subject + ' <a href="javascript:void(0);" style="color:red;" class="removeTreatment">'+ Label.Treatment_Remove + '</a> </span></div></div>' );
		
        } else {
            returnMap.put('hideTreatmentNotes', 'true');
        }
        //-- Starts | FIN-8280| Changed by Asera | 17 April 2026 --//
        //-- FIN-9739 | Changed by Dilshad | 06-May-2026 | Start --//
        try {
            String accountId = (String) inMap.get('Id');
            returnMap.put('accountLanguageCode', UtilityController.getAccountLanguageCode(accountId));
        } catch (Exception e) {
            System.debug('Error fetching Account: ' + e.getMessage());
        }
        //-- FIN-9739 | Changed by Dilshad | 06-May-2026 | End --//
        //-- End | FIN-8280| Changed by Asera | 17 April 2026 --//
        //-- Starts |FIN-7502| Changed by Asera | 25 Nov 2025 --//
        try {
            Map<String, Object> metadataMap = new Map<String, Object>{
                'EmailObj' => returnMap
            };
            String metadataJson = JSON.serialize(metadataMap);
            Map<String, Object> inputParams = new Map<String, Object>{
                'userId' => UserInfo.getUserId(),
                'pageScreenName' => 'Account: Send Email',
                'actionPerformed' => false,
                'actionTakenTime' => null,
                'accountId' => accId,
                'transactionId' => null,
                'disputeId' => null,
                'additionalMetadata' => metadataJson
            };
            System.debug('Full json :' + JSON.serialize(inputParams));
            Id activityId = celsrm.SRMUtilityController.logActivity(JSON.serialize(inputParams));
            System.debug('Full activity : ' + activityId);
            returnMap.put('activityLogId', activityId);
        } catch (Exception e) {
            System.debug('Error logging activity: ' + e.getMessage() + ' ' + e.getLineNumber());
            returnMap.put('ggErrorMessage', e.getMessage() + ' ' + e.getLineNumber());
        } 
        //-- End |FIN-7502| Changed by Asera | 25 Nov 2025 --//
        return returnMap;

    }

     //-- Start | FIN-7406 | FIN-7400 | Changed By Megha/Asera | 11 April 2025 --//
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
                    selectedFieldstype = UtilityController.getQueryFieldsType(customListViewObj.celsrm__Object_Fields__c, 'celsrm__Transaction__c');
                }
            }
            //-- End | FIN-8949 | Changed by Dhwanil | 30 Jan 2026 --//
            // +++++++
            List<Object> transactionList = (List<Object>)inMap.get('TransactionList');
            List<Id> TransIds = new List<Id>();
            if(!transactionList.isEmpty()) {
                for(Object transObj: transactionList) {
                    Map<Object,Object> taransMap = (Map<Object,Object>)transObj;
                    TransIds.add((Id)taransMap.get('Id'));
                }
            }
            List<celsrm__Transaction__c> lstTrans = fetchTransactions(inMap, TransIds);
            // +++++++
            //-- Start | FIN-8949 | Changed By Dhwanil | 30 Jan 2026 --//
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
            //-- End | FIN-8949 | Changed By Dhwanil | 30 Jan 2026 --//
            // Map<Id, celsrm__Transaction__c> transMap = fetchTransactions(inMap);
            // List<celsrm__Transaction__c> lstTrans = new List<celsrm__Transaction__c>(transMap.values());
            inMap.put('DueTransList',lstTrans);
            inMap.put('selectedFields',selectedFields.split(','));
            //-- Start | FIN-8949 | Changed By Dhwanil | 30 Jan 2026 --//
            inMap.put('selectedFieldTypes',selectedFieldsType);
            //-- Starts | FIN-8280| Changed by Asera | 17 April 2026 --//
            // List<string> FieldsLabel = UtilityController.getTransactionFieldLabel(selectedFields.split(','));
            //-- FIN-9739 | Changed by Dilshad | 06-May-2026 | Start --//
            String accountLanguageCode = (String)inMap.get('accountLanguageCode');
            List<String> FieldsLabel = new List<String>();
            if(accountLanguageCode != null && accountLanguageCode != ''){
                FieldsLabel = celsrm.SRMUtilityController.getTransactionFieldTranslatedLabel(accountLanguageCode, 'celsrm__Transaction__c', selectedFields.split(','));
            } else {
                FieldsLabel = UtilityController.getTransactionFieldLabel(selectedFields.split(','));
            }
            //-- FIN-9739 | Changed by Dilshad | 06-May-2026 | End --//
            //-- End | FIN-8280| Changed by Asera | 17 April 2026 --//
            inMap.put('selectedFieldsLabel',FieldsLabel );
            //-- Start | FIN-7812 | Changed By Ravi | 14 July 2025 --//
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
                            // << START - MM - FIN-9455 - Send Statement -> use custom template for attachment >> 
                            // inMap.put('templateBody', message.getHtmlBody());
                            System.debug('Fetched template body for attachment: ' + message.getHtmlBody());
                            String attachmentHtmlBody = message.getHtmlBody();
                            if (attachmentHtmlBody.Contains('{Transactions.TotalOpenItems}') || attachmentHtmlBody.Contains('{Transactions.TotalOverdueItems}') || attachmentHtmlBody.Contains('{Transactions.TotalOverdueNotNotedItems}')) {
                                List<String> transactionIds = new List<String>();
                                for (celsrm__Transaction__c transObj : lstTrans) {
                                    transactionIds.add(transObj.Id);
                                }
                                Map<String,String> returnTemplateAmount = UtilityController.getTransactionTotalSummary((String)inMap.get('Id'), transactionIds);
                                attachmentHtmlBody = attachmentHtmlBody.replace('{Transactions.TotalOpenItems}', returnTemplateAmount.get('TotalOpenItems'));
                                attachmentHtmlBody = attachmentHtmlBody.replace('{Transactions.TotalOverdueItems}', returnTemplateAmount.get('TotalOverdueItems'));
                                attachmentHtmlBody = attachmentHtmlBody.replace('{Transactions.TotalOverdueNotNotedItems}', returnTemplateAmount.get('TotalOverdueNotNotedItems'));
                            }
                            attachmentHtmlBody = UtilityController.replaceCustomerSpecificPlaceholders(attachmentHtmlBody, accountLanguageCode);
                            inMap.put('templateBody', attachmentHtmlBody);
                            // << END - MM - FIN-9455 - Send Statement -> use custom template for attachment >> 

                            //-- Starts | FIN-9351 | Changed by Dhwanil | 03 Mar 2026 --//
                            Map<String, String> imageMap = UtilityController.extractImagesAsBase64(message.getHtmlBody());
                            inMap.put('templateBodyImageBase64Map', imageMap);
                            //-- Ends | FIN-9351 | Changed by Dhwanil | 03 Mar 2026 --//

                            //-- Start | FIN-9543 | Changed by Dhwanil | 06 April 2026 --//
                            celsrm__SRM_Configuration__c systemConfig = celsrm__SRM_Configuration__c.getOrgDefaults();
                            inMap.put('attachmentFontFamily',systemConfig.celsrm__Attachment_Table_Font_Family__c);
                            inMap.put('attachmentFontSize',systemConfig.celsrm__Attachment_Table_Font_Size__c);
                            //-- End | FIN-9543 | Changed by Dhwanil | 06 April 2026 --//
                        }
                    } catch(Exception e) {
                        System.debug('Template Fetch Error: ' + e.getMessage());
                    }
                }
                //-- End | FIN-9048 | Chanegs by Asera 02-Feb-2026--//
                return inMap;
            }
            //-- End | FIN-8949 | Changed By Dhwanil | 30 Jan 2026 --//
            //-- Start | FIN-7812 | Changed By Ravi | 14 July 2025 --//
            inMap.put('isMultiCurrency',  UserInfo.IsMultiCurrencyOrganization());
            // List<Id> TransIds = new List<Id>(transMap.keySet());
            // for (celsrm__Transaction__c obj : lstTrans) { 
            //     TransIds.add(obj.Id);
            // }
            inMap.put('TransIds', String.join(TransIds,','));
            System.debug('@@@@ inMap : ' + inMap);

            
            //Generate Compose Email & Attachment Body (Html Table)
            // Map<String, String> htmlBodyMap = generateAttachmentAndEmailBody(inMap);
            String htmlBody = '';//SendStatementActionController.generateAttachmentAndEmailBody(inMap);
            // String composeEmailHtmlBody = htmlBodyMap.get('composeEmailHtmlBody');

            // System.debug('composeEmailHtmlBody::' + composeEmailHtmlBody);
            System.debug('htmlBody::' + htmlBody);
            

            //To update compose email body only if we change the list view
            // if(updateComposeEmail == true) {
                // String composeEmailBody = generateComposeEmailBody(inMap, htmlBody);
                // Map<Object, Object> composeEmail = (Map<Object, Object>) inMap.get('ComposeEmail');
                // composeEmail.put('body', composeEmailBody);
                // inMap.put('ComposeEmail', composeEmail);
            // }

            inMap.remove('DueTransList');
            inMap.remove('selectedFields');
            inMap.remove('selectedFieldsLabel');
            inMap.remove('TransIds');
            inMap.remove('returnTemplateAmount');

            // If AttachCheckBox is true then only execute further code for attachment
            if(inMap.get('AttachCheckBox') == true || inMap.get('PreviewDocument') == true) {
                //-- Start | FIN-7412 | 14-April-2025 -- (Attachment Related changes) Change by Ravi//
                // PageReference pRef= Page.celsrm__PreviewStatement;
                // pRef.getParameters().put('formatType','Excel');
                // pRef.getParameters().put('accId',((new list<string> (accId))[0]));
                // pRef.getParameters().put('ScreenName','SendStatement');
                
                // System.debug('URL ::: ' + pRef.getUrl());

                // String contentTemplate;
                // if (Test.IsRunningTest()){
                //     Blob fileContent;
                //     fileContent = Blob.valueOf('Unit Test Attachment {Transactions.TotalBalance} Body');
                //     contentTemplate = fileContent.toString();
                // } else {
                //     contentTemplate = pRef.getContent().toString();
                // }
                // String emailAttachmentTemplate = 'SYSTEM_BillingStatementExcel';
                //-- Starts | FIN-9421 | Changed by Dhwanil Shah | 17 March 2026 --//
                String templatename = 'SYSTEM_BillingStatementExcel';
                if(inMap.containsKey('templateName'))
                {
                    templatename=(String)inMap.get('templateName');
                }
                List<EmailTemplate> emailTemplateList = [SELECT Id, Name, Folder.Name FROM EmailTemplate WHERE Name = :templatename WITH SECURITY_ENFORCED LIMIT 1];
                //-- End | FIN-9421 | Changed by Dhwanil Shah | 17 March 2026 --//
                String templateId;
                if (emailTemplateList != null && emailTemplateList.size() > 0) {
                    templateId = emailTemplateList.get(0).Id;
                }
                Messaging.SingleEmailMessage message = Messaging.renderStoredEmailTemplate((Id)templateId, null, (Id)((new list<string> (accId))[0]));
                String contentTemplate = message.getHtmlBody();
                //-- Start | FIN-8334 | Changed by Ravi | 11 sep 2025 --//
                // << START - MM - FIN-8279 - Email Attachment -> Totals by currencycode >> 
                // if (contentTemplate.Contains('{Transactions.TotalBalance}')) {
                if (contentTemplate.Contains('{Transactions.TotalBalance}') || contentTemplate.Contains('{Transactions.TotalOpenItems}') || contentTemplate.Contains('{Transactions.TotalOverdueItems}') || contentTemplate.Contains('{Transactions.TotalOverdueNotNotedItems}')) {
                // << END - MM - FIN-8279 - Email Attachment -> Totals by currencycode >> 
                    Map<String,String> returnTemplateAmount = UtilityController.getTransactionTotalSummary((String)inMap.get('Id'),TransIds);
                    inMap.put('returnTemplateAmount', returnTemplateAmount);
                    contentTemplate = contentTemplate.replaceAll(
                        '(?i)font-family\\s*:\\s*[^;]*\\s*;',
                        'font-family: Arial Unicode MS;'
                    );
                    // contentTemplate = contentTemplate.replace('{Transactions.TotalBalance}', returnTemplateAmount.get('TotalBalance')).replace('{Transactions.TotalBalanceWithoutCurrency}', returnTemplateAmount.get('TotalBalanceWithoutCurrency')).replace('{Transactions.TotalBalanceSummary}', returnTemplateAmount.get('TotalBalanceSummary'));
                    contentTemplate = contentTemplate.replace('{Transactions.TotalBalance}', returnTemplateAmount.get('TotalBalance'));
                    // << START - MM - FIN-8279 - Email Attachment -> Totals by currencycode >> 
                    contentTemplate = contentTemplate.replace('{Transactions.TotalOpenItems}', returnTemplateAmount.get('TotalOpenItems'));
                    contentTemplate = contentTemplate.replace('{Transactions.TotalOverdueItems}', returnTemplateAmount.get('TotalOverdueItems'));
                    contentTemplate = contentTemplate.replace('{Transactions.TotalOverdueNotNotedItems}', returnTemplateAmount.get('TotalOverdueNotNotedItems'));
                    // << END - MM - FIN-8279 - Email Attachment -> Totals by currencycode >> 
                }
                //-- End | FIN-8334 | Changed by Ravi | 11 sep 2025 --//
                // inMap.put('SendStmtAttachmentContent', contentTemplate );
                //-- Start | FIN-8048 | Changed by Ravi | 29 July 2025 --//
                contentTemplate = '<html><head><style>@page{font-family:Arial Unicode MS;font-size:10px;}</style></head><body>' + contentTemplate + '</body></html>';
                //-- End | FIN-8048 | Changed by Ravi | 29 July 2025 --//
                //-- End | FIN-7412 | 14-April-2025 -- (Attachment Related changes) Change by Ravi//
                // String contentSt = (String) inMap.get('SendStmtAttachmentContent');
                //-- Start | FIN-8048 | Changed by Ravi | 29 July 2025 --//
                String st =  '<head><meta http-equiv=\'Content-type\' content=\'text/html;charset=UTF-8\'><style> #txSummaryTableJS td{text-align:left;border:solid 1px gray;white-space:nowrap;}  #txSummaryTableJS th{border:1px solid gray;text-align:left;} #txSummaryTableJS {border-collapse:collapse;padding:0px;border:1px solid gray;}@page{size:landscape;}</style>';
                //-- End | FIN-8048 | Changed by Ravi | 29 July 2025 --//
                contentTemplate = contentTemplate.replace('<head>',st);
                contentTemplate = contentTemplate.replace('{Transaction.Summary}', htmlBody);
                // << START - MM - FIN-8174 - Dynamic translated headers based account local | template placeholders>>
                contentTemplate = UtilityController.replaceCustomerSpecificPlaceholders(contentTemplate, accountLanguageCode);
                // << END - MM - FIN-8174 - Dynamic translated headers based account local | template placeholders>>
                system.debug('contentTemplate>>>'+contentTemplate);
                Blob contentBlob = Blob.valueOf(contentTemplate);
                system.debug('contentBlob>>>'+contentBlob);
                String encodedContent = EncodingUtil.base64Encode(contentBlob);
                // inMap.put('SendStmtAttachmentContent', encodedContent);

                inMap.put('finalContent', encodedContent);
                SendStatementAttachmentInsert sendStatementAttachmentInsertObj = new SendStatementAttachmentInsert();
                inMap = sendStatementAttachmentInsertObj.invoke('Send Statement', inMap);
            }           
        } catch (Exception e) {
            System.debug(e.getMessage());
        }
        System.debug('inMap:::' + inMap);
        return inMap;
    }
    //-- End | FIN-7406 | FIN-7400 | Changed By Megha/Asera | 11 April 2025 --//

    //-- Start | FIN-7406 | FIN-7400 | Changed By Megha/Asera | 11 April 2025 --//
    public static List<celsrm__Transaction__c> fetchTransactions(Map<Object, Object> inMap, List<Id> transIds) {
        //Fetch Transactions - START
        Set<String> accId = new Set<String>();
        accId.add(String.valueOf(inMap.get('Id')));
        //-- Start | FIN-8530 | Changed by Ravi | 10 Nov 2025 --//
        if (inMap.get('accountHierarchyChildIds') != null) {
            List<Object> tempList = (List<Object>) inMap.get('accountHierarchyChildIds');
            for (Object obj : tempList) {
                accId.add(String.valueOf(obj));
            }
        }
        //-- End | FIN-8530 | Changed by Ravi | 10 Nov 2025 --//
        String ListView = (String)inMap.get('ListView');       
        celsrm__Custom_List_View__c customListViewObj = new celsrm__Custom_List_View__c();
        List<celsrm__Custom_List_View__c> customListViewList = [SELECT Id, Name, celsrm__Object_Fields__c, celsrm__Filter_Criteria__c,celsrm__ListView_For_Object__c,celsrm__Sort_By_Field__c, celsrm__Sort_By_Order__c FROM celsrm__Custom_List_View__c WHERE Id = :ListView LIMIT 1];
        String selectedFields = '';
        String whereCondition = '';
        String orderFields = '';
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
            if(customListViewObj.celsrm__Sort_By_Field__c != null && customListViewObj.celsrm__Sort_By_Field__c != '') {
                orderFields = UtilityController.getQuerySortOrder(customListViewObj.celsrm__Sort_By_Field__c, true);
            }
            system.debug('orderBy===>'+orderFields);
        }

        if(whereCondition != '' || whereCondition != null) {
            //-- Start | FIN-8530 | Changed by Ravi | 10 Nov 2025 --//
            // if ((Boolean)inMap.get('IsIncludeChild') == true) {
            //     System.debug('IsIncludeChild If Part');
            //     whereCondition += ' and (celsrm__Account__c= :accId OR celsrm__Account__r.parentid= :accId OR celsrm__Account__r.parent.parentid= :accId )';
            // } else {
                System.debug('IsIncludeChild else part');
                whereCondition += ' and celsrm__account__c IN :accId';
            // }
            //-- End | FIN-8530 | Changed by Ravi | 10 Nov 2025 --//
        } else if(whereCondition == '') {
            //-- Start | FIN-8530 | Changed by Ravi | 10 Nov 2025 --//
            // if ((Boolean)inMap.get('IsIncludeChild') == true) {
            //     System.debug('IsIncludeChild If Part');
            //     whereCondition = ' celsrm__balance__c !=0 and (celsrm__Account__c= :accId OR celsrm__Account__r.parentid= :accId OR celsrm__Account__r.parent.parentid= :accId )';
            // } else {
                System.debug('IsIncludeChild else part');
                whereCondition = ' celsrm__balance__c !=0 and celsrm__account__c IN :accId'; 
            // }   
            //-- End | FIN-8530 | Changed by Ravi | 10 Nov 2025 --//                    
        }

        if(whereCondition != '' || whereCondition != null) {
            whereCondition += ' and Id IN :transIds'; 
        } else {
            whereCondition += ' WHERE Id IN :transIds'; 
        }
        
        //-- Start | FIN-7409 | Changed By Megha | 11 April 2025 --//
        if(orderFields != '' || orderFields != null) {
            whereCondition += ' ' + orderFields + ' LIMIT 2000';
        } else {
            whereCondition += ' LIMIT 2000';
        }
        //-- End | FIN-7409 | Changed By Megha | 11 April 2025 --//


        // whereCondition += ' LIMIT 2000';
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
        // Map<Id, celsrm__Transaction__c> transMap = new Map<Id, celsrm__Transaction__c>(lstTrans);
        // lstTrans.clear();
        // System.debug('heap Size'+ Limits.getHeapSize());
        return lstTrans;
    }
    //-- End | FIN-7406 | FIN-7400 | Changed By Megha/Asera | 11 April 2025 --//
    //-- FIN-9739 | Changed by Dilshad | 06-May-2026 | Start --//
    public static Map<Object, Object> onLoadSendEmail(Map<Object, Object> inMap) {
        Map<Object,Object> returnMap = new Map<Object,Object>();
        // Set treatment notes //
        returnMap = showTreatmentNotes(inMap);
        // Set account language code //
        String accountLanguageCode = UtilityController.getAccountLanguageCode(String.valueOf(inMap.get('Id')));
        returnMap.put('accountLanguageCode', accountLanguageCode);
        // Capture activity //
        try {
            Map<String, Object> metadataMap = new Map<String, Object>{
                'EmailObj' => returnMap
            };
            String metadataJson = JSON.serialize(metadataMap);
            Map<String, Object> inputParams = new Map<String, Object>{
                'userId' => UserInfo.getUserId(),
                'pageScreenName' => 'Account: Send Email',
                'actionPerformed' => false,
                'actionTakenTime' => null,
                'accountId' => String.valueOf(inMap.get('Id')),
                'transactionId' => null,
                'disputeId' => null,
                'additionalMetadata' => metadataJson
            };
            System.debug('Full json :' + JSON.serialize(inputParams));
            Id activityId = celsrm.SRMUtilityController.logActivity(JSON.serialize(inputParams));
            System.debug('Full activity : ' + activityId);
            returnMap.put('activityLogId', activityId);
        } catch (Exception e) {
            System.debug('Error logging activity: ' + e.getMessage() + ' ' + e.getLineNumber());
            returnMap.put('ggErrorMessage', e.getMessage() + ' ' + e.getLineNumber());
        } 
        //-- End |FIN-7502| Changed by Asera | 25 Nov 2025 --//
        return returnMap;
    }
    //-- FIN-9739 | Changed by Dilshad | 06-May-2026 | End --//
}