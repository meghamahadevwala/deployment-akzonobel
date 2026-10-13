global with sharing class PromiseToPayActionController implements celsrm.GOGIScreenCustomLogic{
    global Map<Object, Object> invoke(String functionName, Map<Object, Object> inMap) {
        System.debug('into class => PromiseToPayActionController');
        try {
            if (functionName == 'onLoadPromiseToPay') {
                inMap = createPromiseToPayGridData(inMap);
            } else if (functionName == 'onSavePromiseToPay') {
                inMap = savePromiseToPay(inMap);
            } else if (functionName == 'getTransactionList') {
                inMap = getTransactionList(inMap);
            } else if (functionName == 'onSubmitReversePromise') {
                inMap = onSubmitReversePromise(inMap);
            } else if (functionName == 'validateReversePromise') {
                inMap = validateReversePromise(inMap);
            } else if (functionName == 'previewPromiseEmail') {
                inMap = previewCreatePromiseEmail(inMap);
            }
            // << START - MM - FIN-8174 - Dynamic translated headers based account local | on Change Account Locale on Create Dispute Screen>>
            else if(functionName == 'updateAccountLocale'){
                    inMap = updateAccountLocale(inMap);
            }
            // << END - MM - FIN-8174 - Dynamic translated headers based account local | on Change Account Locale on Create Dispute Screen>>
        } catch (Exception ex) {
            throw new celsrm.CustomException(ex.getMessage()+'::'+ex.getStackTraceString());
        }
        return inMap;
    }

    public static Map<Object,Object> savePromiseToPay(Map<Object, Object> inMap) {
        Savepoint sp = Database.setSavepoint();
        try {
            List<Object> transactionList = (List<Object>)inMap.get('TransactionList');
            String activityName = 'Promise To Pay';
            List < celsrm__Transaction__c > trxListToUpdate = new List < celsrm__Transaction__c > ();
            List < String > transIdList = new List < String > ();       //Make a list of Transaction Id in order to capture activities
            //-- Starts | FIN-9013 | Changed by Ravi | 19 Jan 2026 --//
            Set < String > accIdList = new Set < String > ();         //Make a list of Account Id in order to capture activities
            //-- Ends | FIN-9013 | Changed by Ravi | 19 Jan 2026 --//
            //Validate Promise Amount & Make transaction list to update - START
            for (Object tr : transactionList) {
                Map<Object, Object> transMap = (Map<Object, Object>)tr;
                Decimal promisedAmount = Double.valueOf(transMap.get('PromisedAmount'));
                Decimal transAmount = Double.valueOf(transMap.get('celsrm__Amount__c'));
                //Validate Promise Amount
                if(promisedAmount > transAmount) {
                    Map<Object, Object> retValMap = new Map<Object, Object>();
                    // if(promisedAmount <= 0) { promisedAmount <= 0 ||
                    //     retValMap.put('ggErrorMessage', Label.Invoice + ' ' + String.valueOf(transMap.get('nameSort')) + ' : ' + Label.Promised_Amount_Greater_Than_Zero);
                    // } 
                    //else {
                        retValMap.put('ggErrorMessage', Label.Invoice + ' ' + String.valueOf(transMap.get('nameSort')) + ' : ' + Label.Promised_Amount_Not_GT_Invoice_Amount);
                    // }
                    return retValMap;
                } else {
                    //Transaction List to update
                    celsrm__Transaction__c currentTrx = New celsrm__Transaction__c(Id=String.valueOf(transMap.get('Id')));
                    if(String.valueOf(inMap.get('NoteBody')) != null) {
                        currentTrx.celsrm__Latest_Note__c =  String.valueOf(inMap.get('NoteBody'));    
                        currentTrx.celsrm__Latest_Note_Date__c = date.today();
                        currentTrx.celsrm__Latest_Note_Entered_By__c = UserInfo.getUserId();
                    }
                    currentTrx.celsrm__Promised_Amount__c = Double.valueOf(transMap.get('PromisedAmount'));
                    currentTrx.celsrm__Promise_Date__c = date.valueOf(transMap.get('PromiseDate') + ' 00:00:00');
                    currentTrx.celsrm__Last_Contact_Date__c = date.Today();
                    currentTrx.celsrm__Last_Contacted_By__c = UserInfo.getUserId();
                    //-- Start | FIN-5707 | Changed By Dilshad | 12 Jun 2024 --//
                    currentTrx.celsrm__Broken_Promise_Amount__c = 0;
                    //-- Ends | FIN-5707 | Changed By Dilshad | 12 Jun 2024 --//
                    trxListToUpdate.add(currentTrx);
                    transIdList.add(String.valueOf(transMap.get('Id')));
                }
                //-- Start | FIN-8530 | Changed by Ravi | 10 Nov 2025 --//
                if(transMap.containsKey('celsrm__Account__c')) {
                    String accId = (String)transMap.get('celsrm__Account__c');
                    accIdList.add(accId);
                }
                //-- End | FIN-8530 | Changed by Ravi | 10 Nov 2025 --//
            }
            //Validate data & Make transaction list to update - END
    
            if(transactionList.size() > 0) {
                update trxListToUpdate;
            }
    
            //Update Account - START
            String accountId = (String) inMap.get('Id');
            //-- Start | FIN-8530 | Changed by Ravi | 10 Nov 2025 --//
            if(!accIdList.contains(accountId) && accountId.startsWithIgnoreCase('001')) {
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

            Boolean notifyCustomer = Boolean.valueOf(inMap.get('notifyCustomer'));
            // Send Email Message
            if(notifyCustomer == true) {
                //-- Starts | FIN-7025 | Changed By Dilshad | 20 Jan 2025 --//
                inMap = sendEmailToCustomer(inMap);
                if(inMap.containsKey('ggErrorMessage')) {
                    Database.rollback(sp);
                    return inMap;
                }
                //-- Ends | FIN-7025 | Changed By Dilshad | 20 Jan 2025 --//
            }
            //-- Starts | FIN-6130 | Changed by Dilshad | 25 Jul 2024 --//
            Datetime currentDateTime = DateTime.now();
            Map<String, String> accIdActivityIdMap = new Map<String, String>();
            //Capture activities for Accounts
            if(accIdList.size() > 0) {
                //-- Starts | FIN-9013 | Changed by Ravi | 19 Jan 2026 --//
                accIdActivityIdMap = celsrm.SRMUtilityController.insertActivity(new List<String>(accIdList), 'celsrm__Account__c', activityName, currentDateTime, 100, String.valueOf(inMap.get('NoteBody')), UserInfo.getUserId(), null, 'Internal', null);
                //-- End | FIN-9013 | Changed by Ravi | 19 Jan 2026 --//
            }
            //Capture activities for Transactions
            if(transIdList.size() > 0) {
                Map<String, Object> additionalFields = new Map<String, Object>();
                for (String accId : accIdActivityIdMap.keySet()) {
                    additionalFields.put('celsrm__Parent_Event__c', accIdActivityIdMap.get(accId));
                }
                celsrm.SRMUtilityController.insertActivity(transIdList, 'celsrm__Transaction__c', activityName, currentDateTime, 100, String.valueOf(inMap.get('NoteBody')), UserInfo.getUserId(), null, 'Internal', additionalFields);
            }
            //-- Ends | FIN-6130 | Changed by Dilshad | 25 Jul 2024 --//
            //-- Starts |FIN-7502| Changed by Asera | 25 Nov 2025 --//
            try {
                Map<String, Object> metadataMap = new Map<String, Object>{
                    'PromiseObj' => JSON.serialize(trxListToUpdate),
                    'timestamp' => String.valueOf(Datetime.now())
                };
                Id activityId = (Id) inMap.get('activityLogId');
                // Convert to JSON string
                String metadataJson = JSON.serialize(metadataMap);
                celsrm.SRMUtilityController.updateActivity(activityId, metadataJson);
                
                System.debug('Activity logged with Id: ' + activityId);
            } catch (Exception e) {
                System.debug('Failed to log activity: ' + e.getMessage());
            }
            //-- End |FIN-7502| Changed by Asera | 25 Nov 2025 --//
            if(inMap.containsKey('calledFromTransactionDetailScreen') && Boolean.valueOf(inMap.get('calledFromTransactionDetailScreen')) == true) { 
                inMap.put('refreshParentWindow', true);
            } else {
                Map<String, Object> refreshParentValues = new Map<String, Object>();
                refreshParentValues.put('name', 'ListView');
                refreshParentValues.put('value',inMap.get('ListView'));
                refreshParentValues.put('onChangeMethod','filterDataByView');
                inMap.put('refreshParentValues', refreshParentValues);
            }
            //-- Starts | FIN-6361 | Changed by Dilshad | 28 Aug 2024 --//
            if(inMap.containsKey('activityData') && inMap.containsKey('emailMessageId')) {
                String emailMessageId = String.valueOf(inMap.get('emailMessageId'));
                UtilityController.updateActionTakenOnEmailMessage(emailMessageId, 'Promise To Pay');
            }
            //-- Ends | FIN-6361 | Changed by Dilshad | 28 Aug 2024 --//
        } catch (DmlException dmlEx) {
            Database.rollback(sp);
            System.debug('DML Exception: ' + dmlEx.getMessage());
            System.debug(dmlEx.getStackTraceString());
            // << START - MM - FIN-8733 - Promise To Pay (Restrict after 2 counts) Incorrect error message>>
            // inMap.put('ggErrorMessage', Label.Error_In_Promise_Creation);
            inMap.put('ggErrorMessage', dmlEx.getDmlMessage(0));
            // << END - MM - FIN-8733 - Promise To Pay (Restrict after 2 counts) Incorrect error message>>
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
            inMap.put('ggErrorMessage', 'General Exception: ' + ex.getMessage());
        }
        return inMap;
    }

    public static Map<Object, Object> createFollowUpTask(Map<Object, Object> inMap){
        System.debug('functionName=>createFollowUpTask');
        try {
            String accountId = (String) inMap.get('Id');
            String note = inMap.get('NoteBody') != null && inMap.get('NoteBody') != '' ? String.valueOf(inMap.get('NoteBody')) : null;
            List<Object> transactionList = (List<Object>)inMap.get('TransactionList');
            List<String> invoiceNumberList = new List<String>();
            for(Object trans: transactionList) {
                Map<Object, Object> transMap = (Map<Object, Object>) trans;
                invoiceNumberList.add(String.valueOf(transMap.get('invoiceNo')));
            }
            
            Task openActivity = new Task();
            map < string, object > tempComposeEmail = (map < string, object > ) JSON.deserializeUntyped(JSON.serialize(inMap.get('ComposeEmail')));
            openActivity.Subject = 'Promise To Pay : Follow-Up';
            // openActivity.Description = 'Take follow up on promised invoices: '+ String.join(invoiceNumberList, ', ')+'.';
            openActivity.Description = note;
            openActivity.Status = 'Not Started';
            openActivity.WhatId = accountId;
            openActivity.ActivityDate = Date.valueOf((String) inMap.get('FollowUpDate'));
            openActivity.Type = 'Promise To Pay';
            openActivity.celsrm__Contact_Method__c = 'Email';
            openActivity.Priority = 'High';
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

    public static Map<Object, Object> createPromiseToPayGridData(Map<Object, Object> inMap){
        System.debug('functionName=>createPromiseToPayGridData');
        try {
            //-- Start | FIN-8525 | Changed by Asera | 14 Oct 2025 --//
            Set<String> closedInvoiceNumberList = new Set<String>();
            String ggErrorMessage = '';
            //-- End | FIN-8525 | Changed by Asera | 14 Oct 2025 --//
            if(inMap.containsKey('openFromSummaryAgent') && Boolean.valueOf(inMap.get('openFromSummaryAgent')) == true){
                String arguments = String.valueOf(inMap.get('summaryArguments'));
                String accId = String.valueOf(inMap.get('Id'));
                String emailId = (String) inMap.get('emailId');
                inMap.put('emailMessageId', emailId);
                inMap.put('notifyCustomer', true);
                //-- Starts | FIN-7425 | Changed by Ravi | 30-July-2025 --//
                inMap.put('ContactMethod', 'Email');
                //-- Starts | FIN-7425 | Changed by Ravi | 30-July-2025 --//
                Map<String, Object> argumentsMap = (Map<String, Object> )JSON.deserializeUntyped(arguments);
                List<String> invoiceNumbers = new List<String>();
                for (Object inv: (List<Object>)argumentsMap.get('invoice_numbers')){
                    invoiceNumbers.add(String.valueOf(inv));
                }
                String promiseDate = argumentsMap.containsKey('promise_date') ? String.valueOf(argumentsMap.get('promise_date')) : String.valueOf(Date.today().addDays(5));
                if(invoiceNumbers.size() > 0) {
                     //-- Start | FIN-8510 | Changed by Ravi | added CurrencyIsoCode Field | 10 Oct 2025 --// // Added celsrm__Close_Date__c field FIN-8525 | Changed by Asera
                     //-- Start | FIN-8201 | Changed by Ravi | added celsrm__Create_Date__c, celsrm__Due_Date__c Field | 5 Nov 2025 --//
                    // << CHANGE - MM - FIN-9536 : Sender_Document_Number__c | FIN-9798 : celsrm__Create_Date__c -> Invoice_Date_NF__c | celsrm__Due_Date__c -> Due_Date_2__c | FIN-9798 : Country_Code__c, Reference_Document_Number__c >>
                     List<celsrm__Transaction__c> transactions = [Select Id, celsrm__account__c, celsrm__Amount__c, celsrm__Close_Date__c, celsrm__balance__c, Name, CurrencyIsoCode, Invoice_Date_NF__c, Due_Date_2__c, Sender_Document_Number__c, Country_Code__c, Reference_Document_Number__c From  celsrm__Transaction__c WHere celsrm__account__c = :accId And Name IN :invoiceNumbers And celsrm__Amount__c != 0]; 
                    //-- Ends | FIN-8201 | Changed by Ravi | added celsrm__Create_Date__c, celsrm__Due_Date__c Field | 5 Nov 2025 --//
                   //-- Ends | FIN-8510 | Changed by Ravi | added CurrencyIsoCode Field | 10 Oct 2025 --// 
                    List<Map<Object, Object>> transactionList = new List<Map<Object, Object>>();
                    for(celsrm__Transaction__c trans: transactions) {
                        Map<Object, Object> transMap = new Map<Object, Object>();
                        transMap.put('Id', trans.Id);
                        transMap.put('celsrm__Balance__c', trans.celsrm__Balance__c);
                        transMap.put('celsrm__Amount__c', trans.celsrm__Amount__c);
                        transMap.put('PromiseDate', promiseDate);
                        transMap.put('Name', trans.Name);
                        transMap.put('nameSort', trans.Name);
                        //-- Start | FIN-8530 | Changed by Ravi | 10 Nov 2025 --//
                        transMap.put('celsrm__account__c', trans.celsrm__account__c);
                        //-- End | FIN-8530 | Changed by Ravi | 10 Nov 2025 --//
                        //-- Start | FIN-8201 | Changed by Ravi | 5 Nov 2025 --//
                        // << START - MM - FIN-9798 - celsrm__Create_Date__c -> Invoice_Date_NF__c | celsrm__Due_Date__c -> Due_Date_2__c >>
                        transMap.put('Invoice_Date_NF__c', trans.Invoice_Date_NF__c);
                        transMap.put('Due_Date_2__c', trans.Due_Date_2__c);
                        // << END - MM - FIN-9798 - celsrm__Create_Date__c -> Invoice_Date_NF__c | celsrm__Due_Date__c -> Due_Date_2__c >>
                        //-- Ends | FIN-8201 | Changed by Ravi | 5 Nov 2025 --//
                        //-- Start | FIN-8510 | Changed by Ravi | 10 Oct 2025 --//
                        transMap.put('CurrencyIsoCode', trans.CurrencyIsoCode);
                        //-- Ends | FIN-8510 | Changed by Ravi | 10 Oct 2025 --//
                        //-- Start | FIN-8525 | Changed by Asera | 14 Oct 2025 --//
                        if (trans.celsrm__Close_Date__c != null) {
                            closedInvoiceNumberList.add(trans.Name);
                        }
                        //-- End | FIN-8525 | Changed by Asera | 14 Oct 2025 --//
                        // << START - MM - FIN-9536 - Add Sender_Document_Number__c (Invoice#) in table & email >>
                        transMap.put('Sender_Document_Number__c', trans.Sender_Document_Number__c);
                        // << END - MM - FIN-9536 - Add Sender_Document_Number__c (Invoice#) in table & email >>
                        // << CHANGE - MM - FIN-9798 - Added Country_Code__c, Reference_Document_Number__c >>
                        transMap.put('Country_Code__c', trans.Country_Code__c);
                        transMap.put('Reference_Document_Number__c', trans.Reference_Document_Number__c);
                        transactionList.add(transMap);
                    }
                    inMap.put('TransactionList', transactionList);
                } else {
                    inMap.put('ggErrorMessage', 'Please provide at least one transaction to create a Promise to Pay.');
                    return inMap;
                }
            } else if(inMap.containsKey('activityData') && inMap.get('activityData') != null) {
                List<String> invNo = new List<String>();
                String accId = String.valueOf(inMap.get('Id'));
                Map<Object, Object> activityData = (Map<Object, Object>)inMap.get('activityData');
                System.debug('@@@ activityData: ' + activityData.keySet() );
                for(Object key: activityData.keySet()){
                    System.debug('@@@ key: ' + String.valueOf(key) );
                }
                Map<String, Object> classificationResponse = null;
                // if(!activityData.containsKey('celsrm__Classification_Response__c')) {
                //     EmailMessage em = [SELECT Id, celsrm__Classification_Response__c FROM EmailMessage WHERE Id = :String.valueOf(activityData.get('Id'))];
                //     classificationResponse = (Map<String, Object>)JSON.deserializeUntyped(em.celsrm__Classification_Response__c);
                // } else {
                //     classificationResponse = (Map<String, Object>)JSON.deserializeUntyped((String)activityData.get('celsrm__Classification_Response__c'));
                // }
                //-- Starts | FIN-6410| Changes By: Asera | 18 Sep 2024 --//
                if(String.valueOf(activityData.get('Id')) != ''){
                    String emailMessageId = String.valueOf(activityData.get('Id'));
                    String classificationResponseString = celsrm.SRMUtilityController.getClassificationResponse(emailMessageId); 
                    if(classificationResponseString != null && classificationResponseString != ''){
                        classificationResponse = (Map <string, object> ) JSON.deserializeUntyped(classificationResponseString);
                    } 
                }
                //-- End | FIN-6410| Changes By: Asera | 18 Sep 2024 --//
                if(classificationResponse != null && classificationResponse.containsKey('entities')) {
                    String txt = (String)classificationResponse.get('text');
                    List<Object> ent = (List<Object>)classificationResponse.get('entities');
                    if(ent.size() > 0) {
                        for(Object o : ent) {
                            Map<String, Object> tempMap = (Map<String, Object>)o;
                            if( String.valueOf(tempMap.get('dim')) == 'invoice_no' ) {
                                invNo.add(String.valueOf(tempMap.get('value')));
                            }
                        }
                    }
                }
                List<celsrm__Transaction__c> transactions;
                if(invNo.size() > 0) {
                    //-- Start | FIN-8510 | Changed by Ravi | added CurrencyIsoCode Field | 10 Oct 2025 --// // Added celsrm__Close_Date__c field FIN-8525 | Changed by Asera
                    //-- Start | FIN-8201 | Changed by Ravi | 5 Nov 2025 --//
                    // << CHANGE - MM - FIN-9536 : Sender_Document_Number__c | FIN-9798 : celsrm__Create_Date__c -> Invoice_Date_NF__c celsrm__Due_Date__c -> Due_Date_2__c| FIN-9798 : Country_Code__c, Reference_Document_Number__c
                    transactions = [Select Id, celsrm__account__c, celsrm__Amount__c, celsrm__Close_Date__c, celsrm__balance__c, Name, CurrencyIsoCode, Invoice_Date_NF__c, Due_Date_2__c, Sender_Document_Number__c, Country_Code__c, Reference_Document_Number__c From  celsrm__Transaction__c WHere celsrm__account__c = :accId And Name IN :invNo And celsrm__Amount__c != 0]; 
                    //-- Ends | FIN-8201 | Changed by Ravi | 5 Nov 2025 --//
                    //-- Ends | FIN-8510 | Changed by Ravi | added CurrencyIsoCode Field | 10 Oct 2025 --//
                    List<Map<Object, Object>> transactionList = new List<Map<Object, Object>>();
                    for(celsrm__Transaction__c trans: transactions) {
                        Map<Object, Object> transMap = new Map<Object, Object>();
                        transMap.put('Id', trans.Id);
                        transMap.put('celsrm__Balance__c', trans.celsrm__Balance__c);
                        transMap.put('celsrm__Amount__c', trans.celsrm__Amount__c);
                        transMap.put('Name', trans.Name);
                        transMap.put('nameSort', trans.Name);
                        //-- Start | FIN-8530 | Changed by Ravi | 10 Nov 2025 --//
                        transMap.put('celsrm__account__c', trans.celsrm__account__c);
                        //-- End | FIN-8530 | Changed by Ravi | 10 Nov 2025 --//
                        //-- Start | FIN-8201 | Changed by Ravi | 5 Nov 2025 --//
                        // << START - MM - FIN-9798 - celsrm__Create_Date__c -> Invoice_Date_NF__c | celsrm__Due_Date__c -> Due_Date_2__c >>
                        transMap.put('Invoice_Date_NF__c', trans.Invoice_Date_NF__c);
                        transMap.put('Due_Date_2__c', trans.Due_Date_2__c);
                        // << END - MM - FIN-9798 - celsrm__Create_Date__c -> Invoice_Date_NF__c | celsrm__Due_Date__c -> Due_Date_2__c >>
                        //-- Ends | FIN-8201 | Changed by Ravi | 5 Nov 2025 --//
                        //-- Start | FIN-8510 | Changed by Ravi | 10 Oct 2025 --//
                        transMap.put('CurrencyIsoCode', trans.CurrencyIsoCode);
                        //-- Ends | FIN-8510 | Changed by Ravi | 10 Oct 2025 --//
                        //-- Start | FIN-8525 | Changed by Asera | 14 Oct 2025 --//
                        if (trans.celsrm__Close_Date__c != null) {
                            closedInvoiceNumberList.add(trans.Name);
                        }
                        //-- End | FIN-8525 | Changed by Asera | 14 Oct 2025 --//
                        // << START - MM - FIN-9536 - Add Sender_Document_Number__c (Invoice#) in table & email>>
                        transMap.put('Sender_Document_Number__c', trans.Sender_Document_Number__c);
                        // << END - MM - FIN-9536 - Add Sender_Document_Number__c (Invoice#) in table & email>>
                        // << CHANGE - MM - FIN-9798 - Added Country_Code__c, Reference_Document_Number__c >>
                        transMap.put('Country_Code__c', trans.Country_Code__c);
                        transMap.put('Reference_Document_Number__c', trans.Reference_Document_Number__c);
                        transactionList.add(transMap);
                    }
                    inMap.put('TransactionList', transactionList);

                }
                //-- Starts |FIN-7502| Changed by Asera | 25 Nov 2025 --//
                try {
                    String transactionListJson = JSON.serialize(inMap.get('TransactionList'));
                    Map<String, Object> metadataMap = new Map<String, Object>{
                        'TransactionList' => transactionListJson,
                        'timestamp' => String.valueOf(Datetime.now())
                    };
                    String metadataJson = JSON.serialize(metadataMap);
                    System.debug('metadataJson size: ' + metadataJson.length());
                    Map<String, Object> inputParams = new Map<String, Object>{
                        'userId' => UserInfo.getUserId(),
                        'pageScreenName' => 'Email: Create PromiseToPay',
                        'actionPerformed' => false,
                        'actionTakenTime' => null,
                        'accountId' => accId,
                        'transactionId' => null,
                        'disputeId' => null,
                        'additionalMetadata' => metadataJson
                    };
                    System.debug('Full inputParams: ' + JSON.serialize(inputParams));
                    Id activityId = celsrm.SRMUtilityController.logActivity(JSON.serialize(inputParams));
                    System.debug('Full activity : ' + activityId);
                    inMap.put('activityLogId', activityId);
                } catch (Exception e) {
                    System.debug('Error logging activity: ' + e.getMessage() + ' ' + e.getLineNumber());
                    inMap.put('ggErrorMessage', e.getMessage() + ' ' + e.getLineNumber());
                } 
                //-- End |FIN-7502| Changed by Asera | 25 Nov 2025 --//
                //-- Starts | FIN-6361 | Changed by Dilshad | 28 Aug 2024 --//
                String emailId = (String) activityData.get('Id');
                inMap.put('emailMessageId', emailId);
                //-- Ends | FIN-6361 | Changed by Dilshad | 28 Aug 2024 --//
            } 
            // << START - MM - FIN-8174 - Dynamic translated headers based account local | Fetch account locale value>>
            String accountLocale = 'EN'; //default value 
            // << END - MM - FIN-8174 - Dynamic translated headers based account local | Fetch account locale value>>
            if(inMap.containsKey('calledFromTransactionDetailScreen') && Boolean.valueOf(inMap.get('calledFromTransactionDetailScreen')) == true) { 
                //-- Promise created from transaction detail screen --//
                String transactionId = (String) inMap.get('Id');
                 //-- Start | FIN-8510 | Changed by Ravi | added CurrencyIsoCode Field | 10 Oct 2025 --//
                
                // << CHANGE - MM - FIN-8174 : celsrm__Account__r.celsrm__Locale__c | FIN-8508 : CurrencyIsoCode | FIN-9536 : Sender_Document_Number__c | FIN-9798 : celsrm__Create_Date__c -> Invoice_Date_NF__c | celsrm__Due_Date__c -> Due_Date_2__c | FIN-9798 : Country_Code__c, Reference_Document_Number__c
                List<celsrm__Transaction__c> transactions = [SELECT Id, celsrm__account__c, celsrm__Amount__c, celsrm__balance__c, Name, Invoice_Date_NF__c, Due_Date_2__c, CurrencyIsoCode, celsrm__Account__r.celsrm__Locale__c, celsrm__Account__r.CurrencyIsoCode, Sender_Document_Number__c, Country_Code__c, Reference_Document_Number__c  From  celsrm__Transaction__c WHERE Id =: transactionId];
                 //-- Ends | FIN-8510 | Changed by Ravi | added CurrencyIsoCode Field | 10 Oct 2025 --//
                List<Map<Object, Object>> transactionList = new List<Map<Object, Object>>();
                List<Id> idList = new List<Id>();
                // << START - MM - FIN-8508 - [Promise To Pay] Total Amount in email - incorrect CurrencyISOCode>>
                String accountCurrencyIsoCode = UserInfo.getDefaultCurrency();
                if(transactions.size() > 0) {
                    accountCurrencyIsoCode = transactions[0].celsrm__Account__r.CurrencyIsoCode;
                    // << END - MM - FIN-8508 - [Promise To Pay] Total Amount in email - incorrect CurrencyISOCode>>
                    for(celsrm__Transaction__c trans: transactions) {
                        // << START - MM - FIN-8174 - Dynamic translated headers based account local | Fetch account locale value>>
                        accountLocale = trans.celsrm__Account__r.celsrm__Locale__c;
                        System.debug('celsrm__Locale__c>>' + accountLocale);
                        // << END - MM - FIN-8174 - Dynamic translated headers based account local | Fetch account locale value>>
                        Map<Object, Object> transMap = new Map<Object, Object>();
                        transMap.put('Id', trans.Id);
                        transMap.put('celsrm__Balance__c', trans.celsrm__Balance__c);
                        transMap.put('celsrm__Amount__c', trans.celsrm__Amount__c);
                        transMap.put('Name', trans.Name);
                        transMap.put('nameSort', trans.Name);
                        transMap.put('PromisedAmount', decimal.valueOf(JSON.serialize(transMap.get('celsrm__Balance__c')))); 
                        transMap.put('PromiseDate',date.today().adddays(5));
                        // << START - MM - FIN-9798 - celsrm__Create_Date__c -> Invoice_Date_NF__c | celsrm__Due_Date__c -> Due_Date_2__c >>
                        transMap.put('Invoice_Date_NF__c',trans.Invoice_Date_NF__c);
                        transMap.put('Due_Date_2__c',trans.Due_Date_2__c);
                        // << END - MM - FIN-9798 - celsrm__Create_Date__c -> Invoice_Date_NF__c | celsrm__Due_Date__c -> Due_Date_2__c >>
                        //-- Start | FIN-8530 | Changed by Ravi | 10 Nov 2025 --//
                        transMap.put('celsrm__account__c', trans.celsrm__account__c);
                        //-- End | FIN-8530 | Changed by Ravi | 10 Nov 2025 --//
                        //-- Start | FIN-8510 | Changed by Ravi | 10 Oct 2025 --//
                        transMap.put('CurrencyIsoCode', trans.CurrencyIsoCode);
                        //-- Ends | FIN-8510 | Changed by Ravi | 10 Oct 2025 --//
                        // << START - MM - FIN-9536 - Add Sender_Document_Number__c (Invoice#) in table & email >>
                        transMap.put('Sender_Document_Number__c', trans.Sender_Document_Number__c);
                        // << END - MM - FIN-9536 - Add Sender_Document_Number__c (Invoice#) in table & email >>
                        // << CHANGE - MM - FIN-9798 - Added Country_Code__c, Reference_Document_Number__c >>
                        transMap.put('Country_Code__c', trans.Country_Code__c);
                        transMap.put('Reference_Document_Number__c', trans.Reference_Document_Number__c);
                        transactionList.add(transMap);
                        idList.add( (Id)(trans.Id));
                        inMap.put('Id', trans.celsrm__account__c);
                    }
                }
                    celsrm__Temp_Object_Holder__c temp = new celsrm__Temp_Object_Holder__c();
                    if(!idList.isEmpty()){
                        temp.celsrm__key__c =  Userinfo.getUserName()+Datetime.now().getTime();
                        temp.celsrm__value__c =string.join(idList,',');
                        system.debug(temp.celsrm__value__c);            
                        insert Temp;
                        inMap.put('tempKey',Temp.Id);
                    }
                // << START - MM - FIN-8508 - [Promise To Pay] Total Amount in email - incorrect CurrencyISOCode>>
                inMap.put('accountCurrencyIsoCode', accountCurrencyIsoCode);
                // << END - MM - FIN-8508 - [Promise To Pay] Total Amount in email - incorrect CurrencyISOCode>>
                    //-- Starts |FIN-7502| Changed by Asera | 25 Nov 2025 --//
                    try {
                        String transactionListJson = JSON.serialize(inMap.get('TransactionList'));
                        Map<String, Object> metadataMap = new Map<String, Object>{
                            'TransactionList' => transactionListJson,
                            'timestamp' => String.valueOf(Datetime.now())
                        };
                        String metadataJson = JSON.serialize(metadataMap);
                        System.debug('metadataJson size: ' + metadataJson.length());
                        Map<String, Object> inputParams = new Map<String, Object>{
                            'userId' => UserInfo.getUserId(),
                            'pageScreenName' => 'Transaction: Create PromiseToPay',
                            'actionPerformed' => false,
                            'actionTakenTime' => null,
                            'accountId' => String.valueOf(inMap.get('celsrm__Account__c')),
                            'transactionId' => transactionId,
                            'disputeId' => null,
                            'additionalMetadata' => metadataJson
                        };
                        System.debug('Full inputParams: ' + JSON.serialize(inputParams));
                        Id activityId = celsrm.SRMUtilityController.logActivity(JSON.serialize(inputParams));
                        System.debug('Full activity : ' + activityId);
                        inMap.put('activityLogId', activityId);
                    } catch (Exception e) {
                        System.debug('Error logging activity: ' + e.getMessage() + ' ' + e.getLineNumber());
                        inMap.put('ggErrorMessage', e.getMessage() + ' ' + e.getLineNumber());
                    } 
                    //-- End |FIN-7502| Changed by Asera | 25 Nov 2025 --//
                inMap.put('TransactionList', transactionList);
                inMap.put('hideUpdateAllAction','true');
            } else if(inMap.containsKey('TransactionList')) {
                // << START - MM - FIN-8174 - Dynamic translated headers based account local | Fetch account locale value>>
                String accId = String.valueOf(inMap.get('Id'));
                // FIN-8508 - MM | Added field in query - CurrencyIsoCode
                Account acc = [SELECT Id, Name, celsrm__Locale__c, CurrencyIsoCode FROM Account WHERE Id=:accId];
                accountLocale = acc.celsrm__Locale__c;
                // << START - MM - FIN-8508 - [Promise To Pay] Total Amount in email - incorrect CurrencyISOCode>>
                String accountCurrencyIsoCode = UserInfo.getDefaultCurrency();
                accountCurrencyIsoCode = acc.CurrencyIsoCode;
                // << END - MM - FIN-8508 - [Promise To Pay] Total Amount in email - incorrect CurrencyISOCode>>
                System.debug('celsrm__Locale__c>>' + accountLocale);
                // << END - MM - FIN-8174 - Dynamic translated headers based account local | Fetch account locale value>>

                List<Object> trxn = (List<Object>)inMap.get('TransactionList');
                String trxnId = '';
                List<Id> idList = new List<Id>();
                List<Object> transactionList = new List<Object> ();
                //-- Start | FIN-5779 | Changed by Asera | 27 Jun 2024 --//
                Map<Id, Map<Object, Object>> trxnMapById = new Map<Id, Map<Object, Object>>();
                if(trxn != null && trxn.size() > 0) {
                    for(Integer i=0; i<trxn.size();i++) {
                        idList.add( (Id)(((Map<Object, Object>)trxn.get(i)).get('Id')) );
                        Map<Object, Object> trxnMap = (Map<Object, Object>)trxn.get(i); // Initialize trxnMap within the loop
                        trxnMapById.put((Id)(((Map<Object, Object>)trxn.get(i)).get('Id')), trxnMap);
                    }
                    // << CHANGE - MM - FIN-9717 : celsrm__Create_Date__c and celsrm__Due_Date__c | FIN-9536 : Sender_Document_Number__c | FIN-9798 : celsrm__Create_Date__c -> Invoice_Date_NF__c | celsrm__Due_Date__c -> Due_Date_2__c | FIN-9798 : Country_Code__c, Reference_Document_Number__c >>
                    // if(((Map<Object, Object>)trxn.get(0)).containsKey('celsrm__Balance__c')) {
                    if(((Map<Object, Object>)trxn.get(0)).containsKey('celsrm__Balance__c') && ((Map<Object, Object>)trxn.get(0)).containsKey('Sender_Document_Number__c') && ((Map<Object, Object>)trxn.get(0)).containsKey('Invoice_Date_NF__c') && ((Map<Object, Object>)trxn.get(0)).containsKey('Due_Date_2__c') && ((Map<Object, Object>)trxn.get(0)).containsKey('Country_Code__c') && ((Map<Object, Object>)trxn.get(0)).containsKey('Reference_Document_Number__c')) {
                        //-- Start | FIN-8525 | Changed by Asera | 14 Oct 2025 --//
                        List<celsrm__Transaction__c> transList = [SELECT Id, Name, celsrm__Close_Date__c FROM celsrm__Transaction__c WHERE Id IN: idList];
                        for(celsrm__Transaction__c trans: transList) {
                            if (trans.celsrm__Close_Date__c != null) {
                                closedInvoiceNumberList.add(trans.Name);
                            } 
                        }
                        //-- End | FIN-8525 | Changed by Asera | 14 Oct 2025 --//
                        for(Object t : trxn) {
                            Map<Object, Object> trxnMap = (Map<Object, Object>)t;
                            if (trxnMap.get('celsrm__Balance__c') != null) {
                                trxnMap.put('PromisedAmount', decimal.valueOf(JSON.serialize(trxnMap.get('celsrm__Balance__c')))); 
                            }
                            trxnMap.put('PromiseDate',date.today().adddays(5));
                            trxnMap.put('nameSort',trxnMap.get('Name'));
    
                            transactionList.add((Object) trxnMap);
                        }
                        inMap.put('TransactionList', transactionList);
                    } else {
                        //-- Start | FIN-8201 | Changed by Ravi | 5 Nov 2025 --//
                        // << CHANGE - MM - FIN-9717 : celsrm__Create_Date__c and celsrm__Due_Date__c | FIN-9536 : Sender_Document_Number__c | FIN-9798 : celsrm__Create_Date__c -> Invoice_Date_NF__c | celsrm__Due_Date__c -> Due_Date_2__c | FIN-9798 : Country_Code__c, Reference_Document_Number__c >>
                        List<celsrm__Transaction__c> transList = [SELECT Id, Name, celsrm__account__c, celsrm__Balance__c, celsrm__Close_Date__c, Invoice_Date_NF__c, Due_Date_2__c, Sender_Document_Number__c, Country_Code__c, Reference_Document_Number__c FROM celsrm__Transaction__c WHERE Id IN: idList];
                        //-- Ends | FIN-8201 | Changed by Ravi | 5 Nov 2025 --//
                        for (Integer i = 0; i < transList.size(); i++) {
                            celsrm__Transaction__c tranObj = transList.get(i);
                            Map<Object, Object> trxnMap = trxnMapById.get(tranObj.Id);
                            trxnMap.put('celsrm__Balance__c', tranObj.celsrm__Balance__c); 
                            trxnMap.put('PromisedAmount', tranObj.celsrm__Balance__c); 
                            trxnMap.put('PromiseDate',date.today().adddays(5));
                            trxnMap.put('nameSort',trxnMap.get('Name'));
                            //-- Start | FIN-8530 | Changed by Ravi | 10 Nov 2025 --//
                            trxnMap.put('celsrm__account__c', tranObj.celsrm__account__c);
                            //-- End | FIN-8530 | Changed by Ravi | 10 Nov 2025 --//
                            //-- Start | FIN-8201 | Changed by Ravi | 5 Nov 2025 --//
                            // << START - MM - FIN-9798 - celsrm__Create_Date__c -> Invoice_Date_NF__c | celsrm__Due_Date__c -> Due_Date_2__c >>
                            trxnMap.put('Invoice_Date_NF__c', tranObj.Invoice_Date_NF__c);
                            trxnMap.put('Due_Date_2__c', tranObj.Due_Date_2__c);
                            // << END - MM - FIN-9798 - celsrm__Create_Date__c -> Invoice_Date_NF__c | celsrm__Due_Date__c -> Due_Date_2__c >>
                            //-- Ends | FIN-8201 | Changed by Ravi | 5 Nov 2025 --//
                            //-- Start | FIN-8525 | Changed by Asera | 14 Oct 2025 --//
                            if (tranObj.celsrm__Close_Date__c != null) {
                                closedInvoiceNumberList.add(tranObj.Name);
                            }
                            //-- End | FIN-8525 | Changed by Asera | 14 Oct 2025 --//
                            // << START - MM - FIN-9536 - Add Sender_Document_Number__c (Invoice#) in table & email>>
                            trxnMap.put('Sender_Document_Number__c', tranObj.Sender_Document_Number__c);
                            // << END - MM - FIN-9536 - Add Sender_Document_Number__c (Invoice#) in table & email>>
                            // << CHANGE - MM - FIN-9798 - Added Country_Code__c, Reference_Document_Number__c >>
                            trxnMap.put('Country_Code__c', tranObj.Country_Code__c);
                            trxnMap.put('Reference_Document_Number__c', tranObj.Reference_Document_Number__c);
                            transactionList.add((Object) trxnMap);
                        }
                        inMap.put('TransactionList', transactionList);
                    }
                    //-- Ends | FIN-5779 | Changed by Asera | 27 Jun 2024 --//
                    celsrm__Temp_Object_Holder__c temp = new celsrm__Temp_Object_Holder__c();
                    if(!idList.isEmpty()){
                        temp.celsrm__key__c =  Userinfo.getUserName()+Datetime.now().getTime();
                        temp.celsrm__value__c =string.join(idList,',');
                        system.debug(temp.celsrm__value__c);            
                        insert Temp;
                        inMap.put('tempKey',Temp.Id);
                    }
                }
                // << START - MM - FIN-8508 - [Promise To Pay] Total Amount in email - incorrect CurrencyISOCode>>
                inMap.put('accountCurrencyIsoCode', accountCurrencyIsoCode);
                // << END - MM - FIN-8508 - [Promise To Pay] Total Amount in email - incorrect CurrencyISOCode>>
                //-- Starts |FIN-7502| Changed by Asera | 25 Nov 2025 --//
                try {
                    String transactionListJson = JSON.serialize(inMap.get('TransactionList'));
                    Map<String, Object> metadataMap = new Map<String, Object>{
                        'TransactionList' => transactionListJson,
                        'timestamp' => String.valueOf(Datetime.now())
                    };
                    String metadataJson = JSON.serialize(metadataMap);
                    System.debug('metadataJson size: ' + metadataJson.length());
                    Map<String, Object> inputParams = new Map<String, Object>{
                        'userId' => UserInfo.getUserId(),
                        'pageScreenName' => 'Account: Create PromiseToPay',
                        'actionPerformed' => false,
                        'actionTakenTime' => null,
                        'accountId' => inMap.get('Id'),
                        'transactionId' => null,
                        'disputeId' => null,
                        'additionalMetadata' => metadataJson
                    };
                    System.debug('Full inputParams: ' + JSON.serialize(inputParams));
                    Id activityId = celsrm.SRMUtilityController.logActivity(JSON.serialize(inputParams));
                    System.debug('Full activity : ' + activityId);
                    inMap.put('activityLogId', activityId);
                } catch (Exception e) {
                    System.debug('Error logging activity: ' + e.getMessage() + ' ' + e.getLineNumber());
                    inMap.put('ggErrorMessage', e.getMessage() + ' ' + e.getLineNumber());
                } 
                //-- End |FIN-7502| Changed by Asera | 25 Nov 2025 --//
                inMap.put('hideUpdateAllAction','false');
            }
            // << START - MM - FIN-8174 - Dynamic translated headers based account local | Fetch account locale value>>
            if(accountLocale != null && accountLocale != '' ){
                List<EmailTemplate> template = [SELECT Id,Folder.Name  FROM EmailTemplate where Folder.Name = :accountLocale Limit 1];
                System.debug('template>>' + template);
                if(!template.isEmpty() && template.get(0).Folder.Name == accountLocale){
                    inMap.put('accountLocale', accountLocale);
                } else{
                    inMap.put('accountLocale', 'EN');
                }
            }
            // << END - MM - FIN-8174 - Dynamic translated headers based account local | Fetch account locale value>>
            //-- Start | FIN-8525 | Changed by Asera | 14 Oct 2025 --//
            if(closedInvoiceNumberList.size() > 0) {
                String closedInvoiceNumbers = String.join(closedInvoiceNumberList, ', ');
                ggErrorMessage = String.format(Label.You_cannot_create_promise_on_closed_invoice , new List<String>{closedInvoiceNumbers});
            }
            if(ggErrorMessage != '') {
                inMap.put('ggErrorMessage', ggErrorMessage);
            }
            //-- End | FIN-8525 | Changed by Asera | 14 Oct 2025 --//
        } catch (Exception ex) {
            System.debug(ex.getStackTraceString());
            throw new celsrm.GOGDataServiceException(ex.getMessage());
        }
        return inMap;
    }

    public static Map<Object, Object> getTransactionList(Map<Object, Object> inMap){
        try{
            System.debug('Inside getTransactionList >>>>');
            // Id AccountId = (Id) inMap.get('Id');
            List<String> listTranIds = new List<String>();
            String reversePromisedError = '';
            if(inMap.containsKey('calledFromTransactionDetailScreen') && Boolean.valueOf(inMap.get('calledFromTransactionDetailScreen')) == true) { 
                listTranIds.add( String.valueOf(inMap.get('Id')));
            } else {
                if(inMap.containsKey('TransactionList')) {
                    List<Object> listTransaction = (List<Object>)inMap.get('TransactionList');
                    for (Object tran : listTransaction) {
                        Map<Object,Object> tempMap = (Map<Object,Object>)tran;
                        System.debug( '@@ tempMap : ' + tempMap);
                        System.debug( '@@ ID :  : ' + tempMap.get('Id'));
                        String id = String.valueOf(tempMap.get('Id'));
                        listTranIds.add(id);
                    }
                }
            }       
            List<map<Object,Object>> transactionList = new List<map<Object,Object>>();
            for(celsrm__Transaction__c trxn : [SELECT Id, Name, celsrm__Amount__c, celsrm__Promised_Amount__c, celsrm__Promise_Date__c, celsrm__Account__r.Id 
                                            FROM celsrm__Transaction__c WHERE Id IN :listTranIds] ){
                // if(trxn.celsrm__Promised_Amount__c > 0){
                    map<Object,Object> tempbs =  new map<Object,Object>();
                    tempbs.put('invoiceId', trxn.Id);
                    tempbs.put('invoiceNo', '<a href="' + '/'+ trxn.Id + '" target="_blank">' + trxn.name + '</a>');
                    tempbs.put('amount', trxn.celsrm__Amount__c);
                    // Starts | FIN-6708 | Sejal | 18 Nov 2024 
                    tempbs.put('promisedAmount', trxn.celsrm__Promised_Amount__c);
                    // Ends | FIN-6708 | Sejal | 18 Nov 2024 
                    tempbs.put('promisedDate', trxn.celsrm__Promise_Date__c);
                    //-- Start | FIN-8530 | Changed by Ravi | 10 Nov 2025 --//
                    tempbs.put('celsrm__Account__c',trxn.getSobject('celsrm__Account__r').get('Id'));
                    //-- End | FIN-8530 | Changed by Ravi | 10 Nov 2025 --//
                    tempbs.put('AccountId',trxn.getSobject('celsrm__Account__r').get('Id'));
                    tempbs.put('isSelected', 'true');
                    transactionList.add(tempbs);
                // } else {
                //     reversePromisedError += ',' + '<a href="' + '/'+ trxn.Id + '" target="_blank">' + trxn.name + '</a>';
                // }
            }
            inMap.put('dataServiceResponse', transactionList);
            reversePromisedError = reversePromisedError.replaceFirst(',', '');
            inMap.put('reversePromisedError', reversePromisedError);
            inMap.put('promiseList', transactionList);
            
        } catch(Exception ex){
            System.debug('Method: getTransactionList | Linenumber: ' + ex.getLineNumber() + ' | Message: ' + ex.getMessage());
        }
        return inMap;
    }

    public static Map<Object, Object> onSubmitReversePromise(Map<Object, Object> inMap){
        try
        {
            if(inMap.get('promiseList') != null){
                List<String> trnxIds = new List<String>();
                List<String> accountIDs = new List<String>();
                List<Object> transactionList = (List<Object>)inMap.get('promiseList');
                if(transactionList != null && !transactionList.isEmpty()){
                  List<celsrm__Transaction__c> listTransactionRecords = new List<celsrm__Transaction__c>();
                    for (Object record : transactionList) {
                        Map<Object,Object> tempMap = (Map<Object,Object>)record;
                        if(Boolean.valueOf(tempMap.get('isSelected'))){
                            celsrm__Transaction__c trnx = new celsrm__Transaction__c();
                            trnx.Id = String.valueOf(tempMap.get('invoiceId'));
                            trnx.celsrm__Promised_Amount__c = 0;
                            trnx.celsrm__Promise_Date__c = null;
                            trnx.celsrm__Latest_Note_Date__c = date.today();
                            trnx.celsrm__Latest_Note_Entered_By__c = UserInfo.getUserId();
                            trnx.celsrm__Latest_Note__c =  inMap.get('noteBody') != null && inMap.get('noteBody') != '' ? String.valueOf(inMap.get('noteBody')) : null;
                            listTransactionRecords.add(trnx);
                            accountIDs.add(String.valueOf(tempMap.get('AccountId')));
                            trnxIds.add(trnx.Id);
                        }
                    }
                    system.debug('listTransactionRecords :: ' + listTransactionRecords);
                    if(listTransactionRecords != null && !listTransactionRecords.isEmpty()){
                        update listTransactionRecords;
                    }
                    //-- Start | FIN-8530 | Changed by Ravi | 10 Nov 2025 --//
                    String accountId = (String) inMap.get('Id');
                    if(!accountIDs.contains(accountId) && accountId.startsWithIgnoreCase('001')){
                        accountIDs.add(accountId);
                    }
                    //-- End | FIN-8530 | Changed by Ravi | 10 Nov 2025 --//
                    if(!trnxIds.isEmpty()){
                        celsrm.SRMUtilityController.insertActivity( trnxIds, 
                            'celsrm__Transaction__c',
                            'Promise Reversed', 
                            100, 
                            inMap.get('noteBody') != null && inMap.get('noteBody') != '' ? String.valueOf(inMap.get('noteBody')) : null, 
                            UserInfo.getUserId(), 
                            null, 
                            'Internal');
                    }
                    //-- Start | FIN-5812 - 4 Point | Changed by Asera | 8 Jul 2024 --//
                      if(!accountIDs.isEmpty()){
                        celsrm.SRMUtilityController.insertActivity( accountIDs, 
                            'celsrm__Account__c',
                            'Promise Reversed', 
                            100, 
                            inMap.get('noteBody') != null && inMap.get('noteBody') != '' ? String.valueOf(inMap.get('noteBody')) : null, 
                            UserInfo.getUserId(), 
                            null, 
                            'Internal');
                    }
                     //-- Starts |FIN-7502| Changed by Asera | 25 Nov 2025 --//
                    try {
                        Map<String, Object> metadataMap = new Map<String, Object>{
                            'accountIDs' => accountIDs,
                            'trnxIds' => trnxIds,
                            'timestamp' => String.valueOf(Datetime.now())
                        };
                        Id activityId = (Id) inMap.get('activityLogIdFromScreen');
                        // Convert to JSON string
                        String metadataJson = JSON.serialize(metadataMap);
                        celsrm.SRMUtilityController.updateActivity(activityId, metadataJson);
                        
                        System.debug('Activity logged with Id: ' + activityId);
                    } catch (Exception e) {
                        System.debug('Failed to log activity: ' + e.getMessage());
                    }
                    //-- End |FIN-7502| Changed by Asera | 25 Nov 2025 --//
                    //-- End | FIN-5812 - 4 Point | Changed by Asera | 8 Jul 2024 --//
                }
            }
        } catch(Exception ex){
            System.debug('Method: onSubmitReversePromise | Linenumber: ' + ex.getLineNumber() + ' | Message: ' + ex.getMessage());
        }
        if(inMap.containsKey('calledFromTransactionDetailScreen') && Boolean.valueOf(inMap.get('calledFromTransactionDetailScreen')) == true) { 
            inMap.put('refreshParentWindow', true);
        } else{
            Map<String, Object> refreshParentValues = new Map<String, Object>();
            refreshParentValues.put('name', 'ListView');
            refreshParentValues.put('value',inMap.get('ListView'));
            refreshParentValues.put('onChangeMethod','filterDataByView');
            inMap.put('refreshParentValues', refreshParentValues);
        }
        return inMap;
    }

    public static Map<Object, Object> validateReversePromise(Map<Object, Object> inMap){
        try 
            {
                Boolean isError = false;
                String userlanguage = UserInfo.getLanguage(); 
                String labelValue = '';
                List<String> listTranIds = new List<String>();
                if(inMap.get('TransactionList') != null){
                    List<Object> listTransaction = (List<Object>)inMap.get('TransactionList');
                    // Starts | FIN-6708 | Sejal | 18 Nov 2024 
                    for (Object tran : listTransaction) {
                        Map<Object,Object> tempMap = (Map<Object,Object>)tran;
                        String id = String.valueOf(tempMap.get('Id'));
                        listTranIds.add(id);
                    }
                    for(celsrm__Transaction__c trxn : [SELECT Id, celsrm__Promised_Amount__c, celsrm__Promise_Date__c FROM celsrm__Transaction__c WHERE Id IN :listTranIds] ){
                        if(trxn.celsrm__Promised_Amount__c == 0){
                            isError = true;
                        } 
                    }
                    // Ends | FIN-6708 | Sejal | 18 Nov 2024 
                } 
                if(isError){
                    labelValue = System.Label.get('', 'Reverse_Promise_Error_List', userlanguage);
                    inMap.put('success', false);
                    inMap.put('errorMessage',labelValue);
                } else {
                    inMap.put('success', true);
                }
        } catch (Exception ex) {
            System.debug('Method: validateReversePromise | Linenumber: ' + ex.getLineNumber() + ' | Message: ' + ex.getMessage());
        }
        return inMap;
    }

    //-- Start | FIN-5808 | Changed by Asera | 10 July 2024 --//
    public static Map<Object, Object> previewCreatePromiseEmail(Map<Object, Object> inMap) {
        try {
            List < object > tran = (List < object > ) inMap.get('TransactionList');
            System.debug('TransactionList>>' + tran);
            map < string, object > tempComposeEmail = (map < string, object > ) JSON.deserializeUntyped(JSON.serialize(inMap.get('ComposeEmail')));
            system.debug('tempComposeEmail>>' + tempComposeEmail);
            String htmlBody;
            //-- Start | FIN-8510 | Changed by Ravi | 10 Oct 2025 --//
            Map<String, Double> totalPromiseAmount = new Map<String, Double>();
            //-- Ends | FIN-8510 | Changed by Ravi | 10 Oct 2025 --//
            String Fields = (String) inMap.get('SummaryFields');
            List < String > FieldsAPIlst = Fields.split(',');
            //-- Starts | FIN-8280| Changed by Asera | 17 April 2026 --//
            // List < String > fieldType = new List < String > {};
            String innerHtml = '';
            // Schema.Sobjecttype objType = Transaction__c.getSObjectType();
            // Schema.Describesobjectresult sobjRes = objType.getDescribe();
            // Map < String, Schema.Sobjectfield > fieldMap = sobjRes.fields.getMap();
            // for (String fieldName: FieldsAPIlst) {
            //     Schema.Sobjectfield field = fieldMap.get(fieldName);
            //     String fieldNames1 = field.getDescribe().getLabel();
            //     fieldType.add(fieldNames1);
            // }
            //-- FIN-9739 | Changed by Dilshad | 06-May-2026 | Start --//
            // << CHANGE - MM - FIN-10130 | Never remove accountLocale | I can't see accountLanguageCode is being set anywhere >> 
            String accountLanguageCode = inMap.containsKey('accountLanguageCode') ? String.valueOf(inMap.get('accountLanguageCode')) :  String.valueOf(inMap.get('accountLocale'));
            List<String> fieldType = celsrm.SRMUtilityController.getTransactionFieldTranslatedLabel(accountLanguageCode, 'celsrm__Transaction__c', FieldsAPIlst);
            //-- FIN-9739 | Changed by Dilshad | 06-May-2026 | End --//
            //-- END | FIN-8280| Changed by Asera | 17 April 2026 --//
            //-- Start | FIN-8048 | Changed by Ravi | 29 July 2025 --//
            innerHtml = '<table width="100%" class="billing" style="border-collapse:collapse;font-family:verdana;">';
            //-- End | FIN-8048 | Changed by Ravi | 29 July 2025 --//
            innerHtml += '<tr>';
            for (String obj: fieldType) {
                //-- Start | FIN-8048 | Changed by Ravi | 29 July 2025 --//
               innerHtml += '<th width="auto" style="border:1px solid gray;text-align:left;">' + obj + '</th>';
                //-- End | FIN-8048 | Changed by Ravi | 29 July 2025 --//
            }
            innerHtml += '</tr>';
            Object fieldvalue;
            //-- Start | FIN-8510 | Changed by Ravi | 10 Oct 2025 --//
            String screenLevelCurrencyIsoCode = inMap.containsKey('CurrencyIsoCode') ? String.valueOf(inMap.containsKey('CurrencyIsoCode')) : UserInfo.getDefaultCurrency();
            //-- Ends | FIN-8510 | Changed by Ravi | 10 Oct 2025 --//
            for (object dtx: tran) {
                Map<Object,Object> tempMap = (Map<Object,Object>)dtx;
                innerHtml += '<tr>';
                for (String fieldName: FieldsAPIlst) {
                    if (fieldName == 'celsrm__Promised_Amount__c') {
                        fieldName = 'PromisedAmount';
                    }
                    if (fieldName == 'celsrm__Promise_Date__c') {
                        fieldName = 'PromiseDate';
                    }
                    // << START - MM - FIN-9717 - Create Promise -> Preview -> celsrm__Promised_Amount__c and celsrm__Balance__c not formatted>>
                    if(fieldName == 'PromisedAmount' || fieldName == 'celsrm__Balance__c'){
                        if(tempMap.get(fieldName) != null) {
                            Decimal val = (Decimal)tempMap.get(fieldName);
                            fieldvalue = val.format();
                        } else {
                            fieldvalue = null;
                        }
                    } 
                    else if (fieldName == 'PromiseDate') {
                        fieldvalue = DateFormatter.formatDueDate(tempMap.get(fieldName), tempMap.get('Country_Code__c'));
                    }
                    else {
                        fieldvalue = tempMap.get(fieldName);
                    }
                    // fieldvalue = tempMap.get(fieldName);
                    // << END - MM - FIN-9717 - Create Promise -> Preview -> celsrm__Promised_Amount__c and celsrm__Balance__c not formatted>>
                    if (fieldvalue == null) {
                        fieldvalue = '';
                    }
                    //-- Start | FIN-8048 | Changed by Ravi | 29 July 2025 --//
                    innerHtml += '<td width="auto" style="text-align:left;border:solid 1px gray;white-space:nowrap;">' + fieldvalue + '</td>';
                    //-- End | FIN-8048 | Changed by Ravi | 29 July 2025 --//
                }
                innerHtml += '</tr>';
                double newAmt = tempMap.get('PromisedAmount') == null ? 0 : (Decimal)tempMap.get('PromisedAmount');
                // << START - MM - FIN-8503 - Instead of screen currency, use account currency>>
                String accountCurrency = UserInfo.getDefaultCurrency();
                if (inMap.keySet().contains('accountCurrencyIsoCode') && inMap.get('accountCurrencyIsoCode') != null) { 
                    accountCurrency = (String)inMap.get('accountCurrencyIsoCode');
                }
                // << END - MM - FIN-8503 - Instead of screen currency, use account currency>>
                //-- Start | FIN-8510 | Changed by Ravi | 10 Oct 2025 --//
                // << START - MM - FIN-8503 - Instead of screen currency, use account currency>>
                // String CurrencyIsoCode = tempMap.get('CurrencyIsoCode') == null ? screenLevelCurrencyIsoCode : String.valueOf(tempMap.get('CurrencyIsoCode'));
                String CurrencyIsoCode = tempMap.get('CurrencyIsoCode') == null ? accountCurrency : String.valueOf(tempMap.get('CurrencyIsoCode'));
                // << END - MM - FIN-8503 - Instead of screen currency, use account currency>>
                createMapCurBalance(CurrencyIsoCode, newAmt, totalPromiseAmount);
                // totalPromiseAmount = totalPromiseAmount + newAmt;
                //-- Ends | FIN-8510 | Changed by Ravi | 10 Oct 2025 --//
            }
            innerHtml += '<tr>';
            //-- Start | FIN-8510 | Changed by Ravi | 10 Oct 2025 --//
            String TotalBal = strTotalBalanceSummary(totalPromiseAmount);
            //-- Ends | FIN-8510 | Changed by Ravi | 10 Oct 2025 --//
            //-- Start | FIN-8048 | Changed by Ravi | 29 July 2025 --//
            innerHtml += '<td colspan=' + FieldsAPIlst.size() + ' style="text-align:right;border:solid 1px gray;white-space:nowrap;"> <b> Total</b>  ' + TotalBal + '</td>';
            //-- End | FIN-8048 | Changed by Ravi | 29 July 2025 --//
            innerHtml += '</tr>';
            innerHtml += '</table>';
            if (tempComposeEmail.containsKey('body') && tempComposeEmail.get('body') != null) {
                htmlBody = String.valueOf(tempComposeEmail.get('body'));
                if (htmlBody.contains('{Promise.Summary}') ) {
                    htmlBody = htmlBody.replace('{Promise.Summary}', innerHtml);
                }
            }
            system.debug('htmlBody>>' + innerHtml);
            inMap.put('promiseEmailPreview', htmlBody);
            inMap.put('success', true);
        } catch(Exception ex){
            System.debug('Method: previewCreatePromiseEmail | Linenumber: ' + ex.getLineNumber() + ' | Message: ' + ex.getMessage());
        }
        return inMap;
    }
    //-- End | FIN-5808 | Changed by Asera | 10 July 2024 --//

    //-- Start | FIN-8510 | Changed by Ravi | 10 Oct 2025 --//
    public static void createMapCurBalance(String currencyIsoCode, double currValue, Map<String, double> mapCurBalance){
        if(currencyIsoCode!=null && currValue!=null){
            if(mapCurBalance.containsKey(currencyIsoCode)){
                Double bal = (Double)mapCurBalance.get(currencyIsoCode);
                bal+= currValue;
                mapCurBalance.put(currencyIsoCode,bal);
            }else{
                mapCurBalance.put(currencyIsoCode,currValue);
            }
        }
    }
    public static String strTotalBalanceSummary(Map<String, double> mapCurBalance){
         String  v = '';
        if(mapCurBalance != null && mapCurBalance.size() >0){
            for(String trancurr:mapCurBalance.keyset()){
            If(trancurr != null && trancurr != ''){
                v+= UtilityController.formatDoubleValue(trancurr, mapCurBalance.get(trancurr)) +', ';
            }
            }
            v = v.substring(0,v.length()-2);
       
        }
        return v;
    }
    //-- End | FIN-8510 | Changed by Ravi | 10 Oct 2025 --//

    // << START - MM - FIN-8174 - Dynamic translated headers based account local | on Change Account Locale on Create P2P Screen>>
    public static Map<Object, Object> updateAccountLocale(Map<Object, Object> inMap) {
        try {
            String accountLocale = String.valueOf(inMap.get('accountLocale'));
            System.debug('companyCode>>' + accountLocale);
            if(accountLocale != null && accountLocale != '' ){
                List<EmailTemplate> template = [SELECT Id,Folder.Name  FROM EmailTemplate where Folder.Name = :accountLocale Limit 1];
                System.debug('template>>' + template);
                if(!template.isEmpty() && template.get(0).Folder.Name == accountLocale){
                    inMap.put('accountLocale', accountLocale);
                } else{
                    inMap.put('accountLocale', 'EN');
                }
            } else {
                inMap.put('accountLocale', 'EN');
            }
        } catch (Exception e) {
            System.debug('exception>> ' + e.getMessage());
        }
        return inMap;
    }
    // << END - MM - FIN-8174 - Dynamic translated headers based account local | on Change Account Locale on Create P2P Screen>>
}