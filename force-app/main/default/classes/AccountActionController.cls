global with sharing class AccountActionController implements celsrm.GOGIScreenCustomLogic{

    public class AccountActionWrapper {
        @AuraEnabled 
        public Map<String, Object> screenConfig;
        @AuraEnabled 
        public string screenId;
        @AuraEnabled 
        public Account accountData;
    }
    
    @AuraEnabled(cacheable=false)
    public static AccountActionWrapper getAccountDataAndScreenConfig(String accountId, String screenName) {
        System.debug('screenName:'+screenName);
        System.debug('accountId:'+accountId);
        AccountActionWrapper accountActionWrapper = new AccountActionWrapper();
        try {
            if(screenName != null && screenName != '') {
                String configStr = '';
                Account accountObj = [SELECT Id, Name, AccountNumber, Is_Snoozed__c FROM Account WHERE Id=:accountId];
                accountActionWrapper.accountData = accountObj;
                if(screenName == 'AccountSnooze' && accountObj.Is_Snoozed__c){
                    screenName = 'RemoveSnoozeOnAccount';
                }
                List<celsrm__Screens__c> screenList = [SELECT Id, Name, celsrm__Screen_Name__c, celsrm__Is_Active__c, celsrm__Config_1__c, celsrm__Config_2__c, celsrm__Config_3__c, celsrm__Config_4__c, celsrm__Config_5__c FROM celsrm__Screens__c WHERE celsrm__Is_Active__c = TRUE AND Name =: screenName];
                if(screenList != null && screenList.size() > 0) {
                    celsrm__Screens__c screenObj = screenList.get(0);
                    if(screenObj.celsrm__Config_1__c != null) configStr += screenObj.celsrm__Config_1__c;
                    if(screenObj.celsrm__Config_2__c != null) configStr += screenObj.celsrm__Config_2__c;
                    if(screenObj.celsrm__Config_3__c != null) configStr += screenObj.celsrm__Config_3__c;
                    if(screenObj.celsrm__Config_4__c != null) configStr += screenObj.celsrm__Config_4__c;
                    if(screenObj.celsrm__Config_5__c != null) configStr += screenObj.celsrm__Config_5__c;
                    Map<String, Object> screenConfig = (Map<String, Object>) JSON.deserializeUntyped(configStr);
                    accountActionWrapper.screenConfig = screenConfig;
                    accountActionWrapper.screenId = screenObj.Id;
                } else {
                    throw new AuraHandledException(Label.GOG_No_Screen_Found);
                }
            } else {
                throw new AuraHandledException(Label.GOG_Required_Parameters_Missing_For_Screen);
            }
            return accountActionWrapper;
        } catch (Exception ex) {
            throw new AuraHandledException('Exception in AccountActionController:'+ex.getStackTraceString());
        }
    }

    global Map<Object, Object> invoke(String functionName, Map<Object, Object> inMap) {
        if(functionName == 'saveAccountNote') {
            inMap = saveAccountNote(inMap);
        } else if(functionName == 'reversePromiseToPay') {
            inMap = reversePromiseToPay(inMap);
        } 
        //--- Starts | FIN-6330 Create task on Account ---//
        else if(functionName == 'onLoadAccountCreateTask') {
            inMap = onLoadAccountCreateTask(inMap);
        } else if(functionName == 'onSubmitAccountCreateTask') {
            inMap = onSubmitAccountCreateTask(inMap);
        } 
        //--- Ends | FIN-6330 Create task on Account ---//
        return inMap;
    }

    public Map<Object, Object> saveAccountNote(Map<Object, Object> inMap) {
        Savepoint sp = Database.setSavepoint();
        Map<Object, Object> returnMap = new Map<Object, Object>();
        try {
            if (String.isBlank(String.valueOf(inMap.get('NoteBody')))) { 
                String userlanguage = UserInfo.getLanguage(); 
                String labelValue = System.Label.get('', 'Empty_Note_Error', userlanguage);
                returnMap.put('success', false);
                returnMap.put('errorMessage',labelValue);
            } else {
                Account account = new Account();
                account.Id = String.valueOf(inMap.get('Id'));
                account = (account)celsrm.SRMUtilityController.saveNoteOnRecord(account, String.valueOf(inMap.get('NoteBody'))) ;
                update account;

                //--- Starts | Insert Note in Celonis Event ---//
                List<String> idSet = new List<String>();
                idSet.add(String.valueOf(inMap.get('Id')));
                celsrm.SRMUtilityController.insertActivity(idSet, 'celsrm__Account__c', 'Note Added', 100, String.valueOf(inMap.get('NoteBody')), UserInfo.getUserId(), null, 'Internal');
                //--- Ends | Insert Note in Celonis Event ---//
                //-- Starts |FIN-7502| Changed by Asera | 25 Nov 2025 --//
                try {
                    Map<String, Object> metadataMap = new Map<String, Object>{
                        'Note' => String.valueOf(inMap.get('NoteBody')),
                        'accountIDs' => String.valueOf(inMap.get('Id')),
                        'timestamp' => String.valueOf(Datetime.now())
                    };
                    Id activityId = (Id) inMap.get('activityLogIdFromScreen');
                    system.debug('from addnote submit'+ activityId);
                    // Convert to JSON string
                    String metadataJson = JSON.serialize(metadataMap);
                    celsrm.SRMUtilityController.updateActivity(activityId, metadataJson);
                    
                    System.debug('Activity logged with Id: ' + activityId);
                } catch (Exception e) {
                    System.debug('Failed to log activity: ' + e.getMessage());
                }
                //-- End |FIN-7502| Changed by Asera | 25 Nov 2025 --//
                returnMap.put('LatestNote',account.celsrm__Latest_Note__c);
                returnMap.put('success', true);
            }
        } catch (Exception ex) {
            // An error occurred, so roll back to the savepoint
            Database.rollback(sp);

            // Optionally, log or handle the exception
            System.debug('Error: ' + ex.getMessage());
            returnMap.put('ggErrorMessage', 'There has been some error while resolving the dispute. Please contact system admin. Error:' + ex.getStackTraceString());
        }
        return returnMap;
    }

    public Map<Object, Object> reversePromiseToPay(Map<Object, Object> inMap) {
        Map<Object, Object> returnMap = new Map<Object, Object>();
        system.debug('ReversePromiseToPay >>' + JSON.serialize(inMap));
        try {
            List<Object> transactionObjList = (List<Object>)inMap.get('TransactionList');
            List<String> transactionIdList = new List<String>();
            Set<Id> accountIdSet = new Set<Id>(); // FIN-7502| Changed by Asera | 25 Nov 2025 --//

            for (Object transactionObj : transactionObjList) {
                Map<Object,Object> transactionMap = (Map<Object,Object>)transactionObj;
                String transactionId = String.valueOf(transactionMap.get('Id'));
                transactionIdList.add(transactionId);
            }
            // Added column celsrm__account__C for FIN-7502
            List<celsrm__Transaction__c> transactionList = [SELECT Id, celsrm__Promise_Date__c,celsrm__Promised_Amount__c, celsrm__Account__c,celsrm__Latest_Note__c, celsrm__Latest_Note_Entered_By__c, celsrm__Latest_Note_Date__c FROM celsrm__Transaction__c WHERE Id IN :transactionIdList AND (celsrm__Promised_Amount__c != null OR celsrm__Promised_Amount__c != 0)];
            
            if(transactionList != null && !transactionList.isEmpty()) {
                Boolean hasNoPromisedTransaction = true;
                for(celsrm__Transaction__c trxnObj : transactionList) {
                    if(trxnObj.celsrm__Promised_Amount__c > 0) {
                        hasNoPromisedTransaction = false;
                    }
                    trxnObj.celsrm__Promise_Date__c = null;
                    trxnObj.celsrm__Promised_Amount__c = 0;
                    trxnObj.celsrm__Latest_Note_Date__c = date.today();
                    trxnObj.celsrm__Latest_Note_Entered_By__c = UserInfo.getUserId();
                    trxnObj.celsrm__Latest_Note__c =  'Promise has been reversed.'; 
                    accountIdSet.add(trxnObj.celsrm__Account__c); // FIN-7502| Changed by Asera | 25 Nov 2025 --//
                }
                if(!hasNoPromisedTransaction) {
                    update transactionList;
                    if(!transactionIdList.isEmpty()){
                        celsrm.SRMUtilityController.insertActivity(transactionIdList, 'celsrm__Transaction__c', 'Promise Reversed', 100, 'Promise has been reversed', UserInfo.getUserId(), null, 'Internal');
                        //-- Starts |FIN-7502| Changed by Asera | 25 Nov 2025 --//
                        try {
                            Map<String, Object> metadataMap = new Map<String, Object>{
                                'reversePromiseToPayObj' => transactionIdList
                            };
                            Id accountIdToPass = accountIdSet.isEmpty() ? null : accountIdSet.iterator().next();
                            String metadataJson = JSON.serialize(metadataMap);
                            Map<String, Object> inputParams = new Map<String, Object>{
                                'userId' => UserInfo.getUserId(),
                                'pageScreenName' => 'Reverse PromiseToPay',
                                'actionPerformed' => false,
                                'actionTakenTime' => null,
                                'accountId' => accountIdToPass,
                                'transactionId' => null,
                                'disputeId' => null,
                                'additionalMetadata' => metadataJson
                            };
                            System.debug('Full json :' + JSON.serialize(inputParams));
                            Id activityId = celsrm.SRMUtilityController.logActivity(JSON.serialize(inputParams));
                            System.debug('Full activity : ' + activityId);
                            inMap.put('activityLogId', activityId);
                        } catch (Exception e) {
                            System.debug('Error logging activity: ' + e.getMessage() + ' ' + e.getLineNumber());
                            inMap.put('ggErrorMessage', e.getMessage() + ' ' + e.getLineNumber());
                        } 
                        //-- End |FIN-7502| Changed by Asera | 25 Nov 2025 --//
                    }
                    returnMap.put('ggSuccessMessage', Label.Promise_Reversed_Successfully);
                } else {
                    returnMap.put('ggErrorMessage', Label.No_Promise_Found_On_Invoices);
                }
            }
        } catch (Exception ex) {
            // Optionally, log or handle the exception
            System.debug('Error: ' + ex.getMessage());
            returnMap.put('ggErrorMessage', 'There has been some error while reversing the dispute. Please contact system admin. Error:' + ex.getStackTraceString());
        }
        return returnMap;
    }

    //--- Starts | FIN-6330 Create task on Account ---//
    public Map<Object, Object> onLoadAccountCreateTask(Map<Object, Object> inMap) {
        Savepoint sp = Database.setSavepoint();
        Map<Object, Object> returnMap = new Map<Object, Object>();
        try {
            String accountId = String.valueOf(inMap.get('Id'));
            Account account = [Select Id, OwnerId, owner.Name from Account where Id = :accountId];
            
            Map<Object, Object> ownerMap = new Map<Object, Object>();
            ownerMap.put('id', account.OwnerId);
            ownerMap.put('name', account.owner.Name);
            returnMap.put('assignedTo',ownerMap);
        } catch (Exception ex) {
            System.debug('Error: ' + ex.getMessage());
            returnMap.put('ggErrorMessage', 'There has been some error while resolving the dispute. Please contact system admin. Error:' + ex.getStackTraceString());
        }
        return returnMap;
    }

    public Map<Object, Object> onSubmitAccountCreateTask(Map<Object, Object> inMap) {
        Savepoint sp = Database.setSavepoint();
        Map<Object, Object> returnMap = new Map<Object, Object>();
        try {
            String accountId = String.valueOf(inMap.get('Id'));
            Map<Object,Object> ownerMap =  (Map<Object,Object>)inMap.get('assignedTo');

            Task tsk = new Task();
            tsk.Subject = String.valueOf(inMap.get('subject'));
            tsk.Status = 'Not Started';
            tsk.WhatId = accountId;
            tsk.OwnerId = (Id)ownerMap.get('id');
            tsk.Priority = String.valueOf(inMap.get('priority'));
            tsk.Description = String.valueOf(inMap.get('comment'));
            tsk.ActivityDate = Date.valueOf((String) inMap.get('dueDate'));
            tsk.IsReminderSet = true;
            insert tsk;

            List<String> idSet = new List<String>();
            idSet.add(String.valueOf(inMap.get('Id')));
            // Starts | insert Celonis Event
            celsrm.SRMUtilityController.insertActivity(idSet, 'celsrm__Account__c', 'Task Created', Datetime.now(), 100, inMap.get('comment') != null && inMap.get('comment') != '' ? String.valueOf(inMap.get('comment')) : null, UserInfo.getUserId(), null, 'Internal', null);
            // Ends | insert Celonis Event
        } catch (Exception ex) {
            System.debug('Error: ' + ex.getMessage());
            returnMap.put('ggErrorMessage', 'There has been some error while resolving the dispute. Please contact system admin. Error:' + ex.getStackTraceString());
        }
        return returnMap;
    }
    //--- Ends | FIN-6330 Create task on Account ---//
}