global with sharing class AccountSnoozeController implements celsrm.GOGIScreenCustomLogic{
   
    global Map<Object, Object> invoke(String functionName, Map<Object, Object> inMap) {
        try {
            if (functionName == 'onLoadFunction') {
                inMap = onLoadFunction(inMap);
            } else if (functionName == 'onSubmit') {
                inMap = onSubmit(inMap);
            } else if(functionName == 'removeSnooze') {
                inMap = removeSnooze(inMap);
            //-- Starts |FIN-7502| Changed by Asera | 25 Nov 2025 --//
            } else if(functionName == 'onLoadRemoveSnooze'){
                inMap = onLoadRemoveSnooze(inMap);
            }
            //-- End |FIN-7502| Changed by Asera | 25 Nov 2025 --//
        } catch (Exception ex) {
            System.debug('Class: CreditReviewParameters | Linenumber: ' + ex.getLineNumber() + ' | Message: ' + ex.getMessage());
        }
        return inMap;
    }
    
    public static Map<Object, Object> onLoadFunction(Map<Object, Object> inMap){
        try{
            System.debug('Inside onLoadFunction >>>>');
            Id AccountId = (Id) inMap.get('Id');
            Account account = [SELECT Id, Name, AccountNumber FROM ACCOUNT WHERE Id =: AccountId];
            //-- Starts |FIN-7502| Changed by Asera | 25 Nov 2025 --//
            try {
                Map<String, Object> metadataMap = new Map<String, Object>{
                    'AccountNumber' => account.AccountNumber
                };
                String metadataJson = JSON.serialize(metadataMap);
                Map<String, Object> inputParams = new Map<String, Object>{
                    'userId' => UserInfo.getUserId(),
                    'pageScreenName' => 'Account: Snooze',
                    'actionPerformed' => false,
                    'actionTakenTime' => null,
                    'accountId' => AccountId,
                    'transactionId' => null,
                    'disputeId' => null,
                    'additionalMetadata' => metadataJson
                };
                Id activityId = celsrm.SRMUtilityController.logActivity(JSON.serialize(inputParams));
                System.debug('Full activity : ' + activityId);
                inMap.put('activityLogId', activityId);
            } catch (Exception e) {
                System.debug('Error logging activity: ' + e.getMessage() + ' ' + e.getLineNumber());
                inMap.put('ggErrorMessage', e.getMessage() + ' ' + e.getLineNumber());
            } 
            //-- End |FIN-7502| Changed by Asera | 25 Nov 2025 --//
            inMap.put('AccountNumber', account.AccountNumber);

        } catch(Exception ex){
            System.debug('Method: onLoadFunction | Linenumber: ' + ex.getLineNumber() + ' | Message: ' + ex.getMessage());
        }
        return inMap;
    }

    //-- Starts |FIN-7502| Changed by Asera | 25 Nov 2025 --//
    public static Map<Object, Object> onLoadRemoveSnooze(Map<Object, Object> inMap){
        try{
            System.debug('Inside onLoadFunction >>>>');
            Id AccountId = (Id) inMap.get('Id');
            Account account = [SELECT Id, Name, AccountNumber FROM ACCOUNT WHERE Id =: AccountId];
            try {
                Map<String, Object> metadataMap = new Map<String, Object>{
                    'AccountNumber' => account.AccountNumber
                };
                String metadataJson = JSON.serialize(metadataMap);
                Map<String, Object> inputParams = new Map<String, Object>{
                    'userId' => UserInfo.getUserId(),
                    'pageScreenName' => 'Account: Remove Snooze',
                    'actionPerformed' => false,
                    'actionTakenTime' => null,
                    'accountId' => AccountId,
                    'transactionId' => null,
                    'disputeId' => null,
                    'additionalMetadata' => metadataJson
                };
                Id activityId = celsrm.SRMUtilityController.logActivity(JSON.serialize(inputParams));
                System.debug('Full activity : ' + activityId);
                inMap.put('activityLogId', activityId);
            } catch (Exception e) {
                System.debug('Error logging activity: ' + e.getMessage() + ' ' + e.getLineNumber());
                inMap.put('ggErrorMessage', e.getMessage() + ' ' + e.getLineNumber());
            } 
            inMap.put('AccountNumber', account.AccountNumber);

        } catch(Exception ex){
            System.debug('Method: onLoadFunction | Linenumber: ' + ex.getLineNumber() + ' | Message: ' + ex.getMessage());
        }
        return inMap;
    }
    //-- End |FIN-7502| Changed by Asera | 25 Nov 2025 --//

    public static Map<Object, Object> onSubmit(Map<Object, Object> inMap){
        try{
            System.debug('Inside onSubmit >>>>');
            Id AccountId = (Id) inMap.get('Id');
            String note = inMap.get('NoteBody') != null && inMap.get('NoteBody') != '' ? String.valueOf(inMap.get('NoteBody')) : null;

            Account account = new Account();
            account.Id = AccountId;
            account.Is_Snoozed__c = true;
            account.Snoozed_Reason__c = (String)inMap.get('Reason');
            account.Snoozed_Reminder_Date__c = date.valueOf(String.valueOf(inMap.get('SnoozeUntil')));
            account.celsrm__Latest_Note__c = note;
            account.celsrm__Latest_Note_Date__c = Date.Today();
            account.celsrm__Latest_Note_By__c = UserInfo.getUserId();
            account.celsrm__Last_Contact_Date__c = Date.Today(); 
            account.celsrm__Last_Contact_Method__c = 'Snooze';
            update account;
            Datetime currentDateTime = Datetime.now();
            //-- Starts |FIN-7502| Changed by Asera | 25 Nov 2025 --//
            try {
                Map<String, Object> metadataMap = new Map<String, Object>{
                    'Snooze/UnsnoozeObj' => account,
                    'timestamp' => String.valueOf(Datetime.now())
                };
                Id activityId = (Id) inMap.get('activityLogId');
                system.debug('from snooze submit'+ activityId);
                // Convert to JSON string
                String metadataJson = JSON.serialize(metadataMap);
                celsrm.SRMUtilityController.updateActivity(activityId, metadataJson);
                
                System.debug('Activity logged with Id: ' + activityId);
            } catch (Exception e) {
                System.debug('Failed to log activity: ' + e.getMessage());
            }
            //-- End |FIN-7502| Changed by Asera | 25 Nov 2025 --//
            celsrm.SRMUtilityController.insertActivity( new List<String>{AccountId}, 'celsrm__Account__c','Account Snoozed', currentDateTime, 100, note, UserInfo.getUserId(), null, 'Internal');
        } catch(Exception ex){
            System.debug('Method: onSubmit | Linenumber: ' + ex.getLineNumber() + ' | Message: ' + ex.getMessage());
        }
        return inMap;
    }
    public Map<Object, Object> removeSnooze(Map<Object, Object> inMap) {
        Savepoint sp = Database.setSavepoint();
        Map<Object, Object> returnMap = new Map<Object, Object>();
        try {
            if (String.isBlank(String.valueOf(inMap.get('NoteBody')))) { 
                String userlanguage = UserInfo.getLanguage(); 
                String labelValue = System.Label.get('', 'Empty_Note_Error', userlanguage);
                returnMap.put('success', false);
                returnMap.put('errorMessage',labelValue);
            } else {
                String note = inMap.get('NoteBody') != null && inMap.get('NoteBody') != '' ? String.valueOf(inMap.get('NoteBody')) : null;
                Account account = new Account();
                account.Id = String.valueOf(inMap.get('Id'));
                account.Is_Snoozed__c = false;
                account.Snoozed_Reason__c = null;
                account.Snoozed_Reminder_Date__c = null;
                account.celsrm__Last_Contact_Date__c = Date.Today(); 
                account.celsrm__Last_Contact_Method__c = 'Snooze Removed';
                account.celsrm__Latest_Note__c = note;
                account.celsrm__Latest_Note_Date__c = Date.Today();
                account.celsrm__Latest_Note_By__c = UserInfo.getUserId();
                update account;

                //--- Starts | Insert Note in Celonis Event ---//
                List<String> idSet = new List<String>();
                idSet.add(String.valueOf(inMap.get('Id')));
                celsrm.SRMUtilityController.insertActivity(idSet, 'celsrm__Account__c', 'Account Snooze Removed', 100, String.valueOf(inMap.get('NoteBody')), UserInfo.getUserId(), null, 'Internal');
                //--- Ends | Insert Note in Celonis Event ---//
                returnMap.put('LatestNote',account.celsrm__Latest_Note__c);
                returnMap.put('success', true);
                //-- Starts |FIN-7502| Changed by Asera | 25 Nov 2025 --//
                try {
                    Map<String, Object> metadataMap = new Map<String, Object>{
                        'Snooze/UnsnoozeObj' => account,
                        'timestamp' => String.valueOf(Datetime.now())
                    };
                    Id activityId = (Id) inMap.get('activityLogId');
                    system.debug('from snooze submit'+ activityId);
                    // Convert to JSON string
                    String metadataJson = JSON.serialize(metadataMap);
                    celsrm.SRMUtilityController.updateActivity(activityId, metadataJson);
                    
                    System.debug('Activity logged with Id: ' + activityId);
                } catch (Exception e) {
                    System.debug('Failed to log activity: ' + e.getMessage());
                }
                //-- End |FIN-7502| Changed by Asera | 25 Nov 2025 --//
            }
        } catch (Exception ex) {
            // An error occurred, so roll back to the savepoint
            Database.rollback(sp);

            // Optionally, log or handle the exception
            System.debug('Error: ' + ex.getMessage());
            returnMap.put('ggErrorMessage', 'There has been some error while Snooze Removed. Please contact system admin. Error:' + ex.getStackTraceString());
        }
        return returnMap;
    }
}