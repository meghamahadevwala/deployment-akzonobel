global with sharing class AddNoteOnInvoiceController implements celsrm.GOGIScreenCustomLogic {
    global Map<Object, Object> invoke(String functionName, Map<Object, Object> inMap) {      
        Savepoint sp = Database.setSavepoint();
        try {
            //-- Starts |FIN-7502| Changed by Asera | 25 Nov 2025 --//
            List<Id> trxIdList = new List<Id>(); 
            List<Map<String, Object>> noteObjList = new List<Map<String, Object>>();
            //-- End |FIN-7502| Changed by Asera | 25 Nov 2025 --//
            if (String.isBlank(String.valueOf(inMap.get('NoteBody')))) { 
                String userlanguage = UserInfo.getLanguage(); 
                String labelValue = System.Label.get('', 'Empty_Note_Error', userlanguage);
                inMap.put('ggErrorMessage', labelValue);
            } else {
                String noteBody = String.valueOf(inMap.get('NoteBody'));
                Datetime currentDateTime = Datetime.now();
                String accountId = '';  
                if(inMap.get('TransactionList') != null ) { //-- In case of multiple transaction - called from account detail screen --//
                    List <Object> transObjList = (List <Object>) inMap.get('TransactionList');
                    for (Object trnObj: transObjList) {
                        Map <Object, Object> trnMap = (Map <Object, Object> ) trnObj;
                        Id key = (String) trnMap.get('Id');
                        trxIdList.add(key); 
                    }
                     
                } else { //-- In case of multiple transaction - called from account detail screen --//
                    String transactionId = (String) inMap.get('Id');
                    trxIdList.add(transactionId);
                    inMap.put('refreshParentWindow', true);
                }
                
                List<celsrm__Transaction__c> transObjList = [SELECT Id, celsrm__Account__c FROM celsrm__Transaction__c WHERE Id IN: trxIdList];
                if(transObjList != null && transObjList.size() > 0) {
                    for(celsrm__Transaction__c trxnObj : transObjList) {
                        trxnObj.celsrm__Latest_Note__c = noteBody;
                        trxnObj.celsrm__Latest_Note_Date__c = date.today();
                        trxnObj.celsrm__Latest_Note_Entered_By__c = UserInfo.getUserId();
                        accountId = trxnObj.celsrm__Account__c;
                        //-- Starts |FIN-7502| Changed by Asera | 25 Nov 2025 --//
                        Map<String, Object> noteDetails = new Map<String, Object>{
                            'transactionId' => trxnObj.Id,
                            'accountId' => trxnObj.celsrm__Account__c,
                            'noteBody' => noteBody,
                            'noteDate' => Date.today(),
                            'enteredBy' => UserInfo.getUserId()
                        };
                        noteObjList.add(noteDetails);
                        //-- End |FIN-7502| Changed by Asera | 25 Nov 2025 --//
                    }
                    update transObjList;
        
                    if(trxIdList!= null && trxIdList.size() > 0) {     
                        if(!trxIdList.isEmpty()){
                            celsrm.SRMUtilityController.insertActivity(trxIdList, 'celsrm__Transaction__c', 'Note Added', currentDateTime, 100, noteBody, UserInfo.getUserId(), null, 'Internal');
                        }
                    }
                }
                
                if(accountId != '') {
                    Account accountObj = new Account(); 
                    accountObj.Id = accountId;
                    accountObj.celsrm__Last_Contact_Date__c = Date.Today(); 
                    accountObj.celsrm__Last_Contact_Type__c = 'Note';
                    accountObj.celsrm__Last_Contact_Method__c = 'Invoice Note';
                    update accountObj;        
                }
    
                Map<String, Object> refreshParentValues = new Map<String, Object>();
                if(inMap.containsKey('ListView')) {
                    refreshParentValues.put('name', 'ListView');
                    refreshParentValues.put('value',inMap.get('ListView'));
                    refreshParentValues.put('onChangeMethod','filterDataByView');
                }
                System.debug('@@@ refreshParentValues : '  +refreshParentValues);
                inMap.put('refreshParentValues', refreshParentValues);
            }
            //-- Starts |FIN-7502| Changed by Asera | 25 Nov 2025 --//
            try {
                Map<String, Object> metadataMap = new Map<String, Object>{
                    'NoteObj' => JSON.serialize(noteObjList),
                    'TransactionsId' => trxIdList,
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
        } catch (Exception ex) {
            // An error occurred, so roll back to the savepoint
            Database.rollback(sp);

            // Optionally, log or handle the exception
            System.debug('Error: ' + ex.getMessage());
            inMap.put('ggErrorMessage', 'There has been some error while resolving the dispute. Please contact system admin. Error:' + ex.getStackTraceString());
        }
        return inMap;
    }
}