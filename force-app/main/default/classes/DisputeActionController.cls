global with sharing class DisputeActionController implements celsrm.GOGIScreenCustomLogic {
    global Map<Object, Object> invoke(String functionName, Map<Object, Object> inMap) {
        System.debug('into CreateDisputeController');
        System.debug('functionName ::: ' + functionName);
        if(functionName == 'onLoadCreateDisputeScreen') {
            inMap = onLoadCreateDisputeScreen(inMap);
        } else if(functionName == 'onChangeReasonCode') {
            inMap = onChangeReasonCode(inMap);
        } else if(functionName == 'saveDispute') {
            Map<Object, Object> errorMap = validateDisputes(inMap);
            if(errorMap != null) {
                return errorMap;
            } else {
                saveDispute(inMap);
            }
        } else if (functionName == 'fetchOpenDisputesForTransaction') {
            inMap = fetchOpenDisputesForTransaction(inMap);
        } else if(functionName == 'updateReverseDispute') {
            inMap = updateReverseDispute(inMap);
        } else if(functionName == 'reverseDisputeFromDisputeDetail'){
            inMap = reverseDisputeFromDisputeDetail(inMap);
        } else if(functionName == 'previewCreateDisputeEmail'){
            inMap = previewCreateDisputeEmail(inMap);
        } 
        //-- Starts | FIN-7859 | Changed by Ravi | 24-Jul-2025 --//
        else if(functionName == 'getDisputeTypeOptions'){
            PicklistOptions typeOptions = getPicklistOptions('celsrm__Dispute__c', 'celsrm__Dispute_Type__c', null, null);
            inMap.put('dataServiceResponse', typeOptions.options);
        } else if(functionName == 'getReasonCodeOptions'){
            PicklistOptions reasonCodeOptions = getPicklistOptions('celsrm__Dispute__c', 'celsrm__Reason_Code__c', 'celsrm__Dispute_Type__c', null);
            inMap.put('dataServiceResponse', reasonCodeOptions.options);
        }
        //-- Ends | FIN-7859 | Changed by Ravi | 24-Jul-2025 --//
        //-- Starts | FIN-8626 | Changed by Asera | 14 Nov 2025 --//
        else if(functionName == 'setDisputeResolverType'){
            //-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
            String disputeResolverType = !String.isEmpty(celsrm__Dispute_Configuration__c.getOrgDefaults().celsrm__Dispute_Resolver_Type__c) ? celsrm__Dispute_Configuration__c.getOrgDefaults().celsrm__Dispute_Resolver_Type__c : '';
            //-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
            inMap.put('disputeResolverType', disputeResolverType);
        }
        //-- End | FIN-8626 | Changed by Asera | 14 Nov 2025 --//
        // << START - MM - FIN-8174 - Dynamic translated headers based account local | on Change Account Locale on Create Dispute Screen>>
        else if(functionName == 'updateAccountLocale'){
                inMap = updateAccountLocale(inMap);
        }
        // << END - MM - FIN-8174 - Dynamic translated headers based account local | on Change Account Locale on Create Dispute Screen>>
        return inMap;    
    }
    
    public static Map<Object, Object> onLoadCreateDisputeScreen(Map<Object, Object> inMap) {
        //-- Starts | FIN-7796 | Changed by Dilshad | 30-Jun-2025 --//
        String disputeResolverType = !String.isEmpty(celsrm__Dispute_Configuration__c.getOrgDefaults().celsrm__Dispute_Resolver_Type__c) ? celsrm__Dispute_Configuration__c.getOrgDefaults().celsrm__Dispute_Resolver_Type__c : 'Account_Owner';
        inMap.put('disputeResolverType', disputeResolverType);
        //-- Ends | FIN-7796 | Changed by Dilshad | 30-Jun-2025 --//
        if(inMap.containsKey('openFromSummaryAgent') && Boolean.valueOf(inMap.get('openFromSummaryAgent')) == true){
            getTransactionListFromSummaryAgent(inMap);
            if (inMap.containsKey('ggErrorMessage') && inMap.get('ggErrorMessage') != null) {
                return inMap;
            }
            inMap.put('notifyCustomer', true);
            //-- Starts | FIN-7425 | Changed by Ravi | 30-July-2025 --//
            inMap.put('ContactMethod', 'Email');
            //-- Starts | FIN-7425 | Changed by Ravi | 30-July-2025 --//
        } else if(inMap.containsKey('activityData') && inMap.get('activityData') != null) { //-- create dispute screen is opened from activity component --//
            getTransactionListFromActivity(inMap);
        }
        List<String> existingDisputes = new List<String>();
        system.debug('calledFromTransactionDetailScreen:'+inMap.containsKey('calledFromTransactionDetailScreen'));
        // << START - MM - FIN-8174 - Dynamic translated headers based account local | Fetch account locale value>>
        String accountLocale = 'EN'; //default value 
        // << END - MM - FIN-8174 - Dynamic translated headers based account local | Fetch account locale value>>
        if(inMap.containsKey('calledFromTransactionDetailScreen') && Boolean.valueOf(inMap.get('calledFromTransactionDetailScreen')) == true) { 
            //-- Dispute created from transaction detail screen --//
            List<Map<Object, Object>> resultMapList = new List<Map<Object, Object>>();
            //-- Start | FIN-8525 | Changed by Asera | 14 Oct 2025 --//
            Set<String> closedInvoiceNumberList = new Set<String>();
            String ggErrorMessage = '';
            //-- End | FIN-8525 | Changed by Asera | 14 Oct 2025 --//
            String transactionId = (String) inMap.get('Id');
            system.debug('transactionId:'+transactionId);
            //-- Start | FIN-5814 | Changed By Megha | 8 July 2024 --//
            //-- Starts | FIN-7796 | Changed by Dilshad | 30-Jun-2025 --//
            //-- Start | FIN-8201 | Changed By Ravi | 5 Nov 2024 --//
            
            // CHANGE - MM - FIN-8503 : CurrencyIsoCode | FIN-8174 : celsrm__Account__r.celsrm__Locale__c & celsrm__Account__r.CurrencyIsoCode | FIN-8493 : Sender_Document_Number__c | FIN-9931 : Reference_Document_Number__c | FIN-9798 : celsrm__Create_Date__c -> Invoice_Date_NF__c | FIN-9798 : Due_Date_2__c, Country_Code__c
            // List<celsrm__Transaction__c> transList = [SELECT Id, Name, celsrm__Amount__c, celsrm__Close_Date__c, celsrm__Balance__c, celsrm__Disputed_Amount__c, CurrencyIsoCode, celsrm__Account__c, celsrm__Account__r.OwnerId, celsrm__Account__r.Owner.Name, celsrm__Create_Date__c FROM celsrm__Transaction__c WHERE Id =: transactionId]; // Added Closed Date field | FIN-8525 | Changed by Asera | 14 Oct 2025 --//
            List<celsrm__Transaction__c> transList = [SELECT Id, Name, celsrm__Amount__c, celsrm__Close_Date__c, celsrm__Balance__c, celsrm__Disputed_Amount__c, CurrencyIsoCode, celsrm__Account__c, celsrm__Account__r.OwnerId, celsrm__Account__r.Owner.Name, Invoice_Date_NF__c, celsrm__Account__r.celsrm__Locale__c, celsrm__Account__r.CurrencyIsoCode, Sender_Document_Number__c, Due_Date_2__c, Country_Code__c, Reference_Document_Number__c FROM celsrm__Transaction__c WHERE Id =: transactionId]; // Added Closed 
            //-- Ends | FIN-8201 | Changed By Ravi | 5 Nov 2024 --//
            //-- Ends | FIN-7796 | Changed by Dilshad | 30-Jun-2025 --//
            //-- End | FIN-5814 | Changed By Megha | 8 July 2024 --//
            // << START - MM - FIN-8503 - Create Dispute -> Total Amount in email - incorrect CurrencyISOCode>>
            String accountCurrencyIsoCode = UserInfo.getDefaultCurrency();
            // << END - MM - FIN-8503 - Create Dispute -> Total Amount in email - incorrect CurrencyISOCode>>
            if(transList != null && transList.size() > 0) {
                // << START - MM - FIN-8503 - Create Dispute -> Total Amount in email - incorrect CurrencyISOCode>>
                accountCurrencyIsoCode = transList[0].celsrm__Account__r.CurrencyIsoCode;
                // << END - MM - FIN-8503 - Create Dispute -> Total Amount in email - incorrect CurrencyISOCode>>
                for (celsrm__Transaction__c tranObj: transList) {
                    // << START - MM - FIN-8174 - Dynamic translated headers based account local | Fetch account locale value>>
                    accountLocale = tranObj.celsrm__Account__r.celsrm__Locale__c;
                    System.debug('celsrm__Locale__c>>' + accountLocale);
                    // << END - MM - FIN-8174 - Dynamic translated headers based account local | Fetch account locale value>>
                    Map<Object, Object> transactionMap = new Map<Object, Object>();
                    transactionMap.put('Id', tranObj.Id);
                    transactionMap.put('Name', tranObj.Name);
                    transactionMap.put('celsrm__Balance__c', tranObj.celsrm__Balance__c);
                    transactionMap.put('celsrm__Amount__c', tranObj.celsrm__Amount__c);
                    transactionMap.put('disputeAmount', tranObj.celsrm__Balance__c);
                    // << START - MM - FIN-8493 - Dispute Summary - columns arrangement>>
                    transactionMap.put('Sender_Document_Number__c', tranObj.Sender_Document_Number__c);
                    // << END - MM - FIN-8493 - Dispute Summary - columns arrangement>>
                    // << START - MM - FIN-9931 - Dispute → Preview → Reference_Document_Number__c value not populated>>
                    transactionMap.put('Reference_Document_Number__c', tranObj.Reference_Document_Number__c);
                    // << START - MM - FIN-9931 - Dispute → Preview → Reference_Document_Number__c value not populated>>
                    //-- Start | FIN-8530 | Changed by Ravi | 10 Nov 2025 --//
                    transactionMap.put('celsrm__Account__c', tranObj.celsrm__Account__c);
                    //-- End | FIN-8530 | Changed by Ravi | 10 Nov 2025 --//
                    //-- Start | FIN-8201 | Changed By Ravi | 5 Nov 2024 --//
                    // << CHANGE - MM - FIN-9798 - celsrm__Create_Date__c -> Invoice_Date_NF__c >>
                    transactionMap.put('celsrm__Create_Date__c', tranObj.Invoice_Date_NF__c);
                    //-- Ends | FIN-8201 | Changed By Ravi | 5 Nov 2024 --//
                    //-- Start | FIN-8530 | Changed by Ravi | 10 Nov 2025 --//
                    transactionMap.put('celsrm__Account__c', tranObj.celsrm__Account__c);
                    //-- End | FIN-8530 | Changed by Ravi | 10 Nov 2025 --//
                    //-- Start | FIN-5814 | Changed By Megha | 8 July 2024 --//
                    transactionMap.put('CurrencyIsoCode', tranObj.CurrencyIsoCode);
                    //-- End | FIN-5814 | Changed By Megha | 8 July 2024 --//
                    //-- Starts | FIN-7796 | Changed by Dilshad | 30-Jun-2025 --//
                    Map<Object,Object> resolverMap = new Map<Object,Object>();
                    //-- Setting Setting Dispute Resolver for Scenario as Account Owner--//
                    if(disputeResolverType == 'Account_Owner') { //-- Dispute Resolver Type is Account Owner --//
                        resolverMap.put('id', tranObj.celsrm__Account__r.OwnerId);
                        resolverMap.put('name', tranObj.celsrm__Account__r.Owner.Name);
                    } else if(disputeResolverType == 'Logged_In_User') { //-- Dispute Resolver Type is Logged In user --//
                        resolverMap.put('id', UserInfo.getUserId());
                        resolverMap.put('name', UserInfo.getName());
                    }
                    transactionMap.put('DisputeResolver', resolverMap);
                    transactionMap.put('WorkflowMatrix', null);
                    transactionMap.put('totalSLADays', null);
                    // << START - MM - FIN-9798 - Added Due_Date_2__c, Country_Code__c >>
                    transactionMap.put('Due_Date_2__c', tranObj.Due_Date_2__c);
                    transactionMap.put('Country_Code__c', tranObj.Country_Code__c);
                    // << START - MM - FIN-9798 - Added Due_Date_2__c, Country_Code__c >>
                    //-- Ends | FIN-7796 | Changed by Dilshad | 30-Jun-2025 --//
                    resultMapList.add(transactionMap);
                    //-- Start | FIN-8525 | Changed by Asera | 14 Oct 2025 --//
                    if (tranObj.celsrm__Close_Date__c != null) {
                        closedInvoiceNumberList.add(tranObj.Name);
                    }
                    //-- End | FIN-8525 | Changed by Asera | 14 Oct 2025 --//
                }
                // << START - MM - FIN-8503 - Create Dispute -> Total Amount in email - incorrect CurrencyISOCode>>
                inMap.put('accountCurrencyIsoCode', accountCurrencyIsoCode);
                // << END - MM - FIN-8503 - Create Dispute -> Total Amount in email - incorrect CurrencyISOCode>>
                inMap.put('TransactionList', resultMapList);
                inMap.put('hideUpdateAllAction','true');
                system.debug('from transaction'+ JSON.serialize(inMap));
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
                        'pageScreenName' => 'Transaction: Create Dispute',
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
                //-- Start | FIN-8525 | Changed by Asera | 14 Oct 2025 --//
                if(closedInvoiceNumberList.size() > 0) {
                    String closedInvoiceNumbers = String.join(closedInvoiceNumberList, ', ');
                    ggErrorMessage = String.format(Label.You_cannot_create_dispute_on_closed_invoice , new List<String>{closedInvoiceNumbers});
                }
                if(ggErrorMessage != '') {
                    inMap.put('ggErrorMessage', ggErrorMessage);
                }
                //-- End | FIN-8525 | Changed by Asera | 14 Oct 2025 --//
            }
        }
        //-- Starts | FIN-7425 | Changed by Ravi | 30-July-2025 --// 
        else if(inMap.containsKey('TransactionList')) { 
        //-- Ends | FIN-7425 | Changed by Ravi | 30-July-2025 --//  
        // << START - MM - FIN-8174 - Dynamic translated headers based account local | Fetch account locale value>>
            String accId = String.valueOf(inMap.get('Id'));
            // FIN-8503 - MM | Added field in query - CurrencyIsoCode
            Account acc = [SELECT Id, Name, celsrm__Locale__c, CurrencyIsoCode FROM Account WHERE Id=:accId];
            // << START - MM - FIN-8503 - Create Dispute -> Total Amount in email - incorrect CurrencyISOCode>>
            String accountCurrencyIsoCode = UserInfo.getDefaultCurrency();
            accountCurrencyIsoCode = acc.CurrencyIsoCode;
            // << END - MM - FIN-8503 - Create Dispute -> Total Amount in email - incorrect CurrencyISOCode>>
            accountLocale = acc.celsrm__Locale__c;
            System.debug('celsrm__Locale__c>>' + accountLocale);
            // << END - MM - FIN-8174 - Dynamic translated headers based account local | Fetch account locale value>>  
            //-- Dispute created from account detail screen --//
            List<Object> trxnList = (List<Object>)inMap.get('TransactionList');
            if(trxnList != null && trxnList.size() > 0) {
                List<String> creditInvoiceNumberList = new List<String>();
                List<String> zeroBalanceInvoiceNumberList = new List<String>();
                //-- Start | FIN-8525 | Changed by Asera | 14 Oct 2025 --//
                Set<String> closedInvoiceNumberList = new Set<String>();
                //-- End | FIN-8525 | Changed by Asera | 14 Oct 2025 --//
                String ggErrorMessage = '';
                //-- Starts | FIN-7796 | Changed by Dilshad | 30-Jun-2025 --//
                
                List<Id> idList = new List<Id>();
                for(Integer i=0; i<trxnList.size();i++) {
                    idList.add( (Id)(((Map<Object, Object>)trxnList.get(i)).get('Id')) );
                }
                //-- Start | FIN-8510 | Changed by Ravi | added CurrencyIsoCode Field | 10 Oct 2025 --//
                // FIN-8493 - MM | Added field in query - Sender_Document_Number__c
                // FIN-9931 - MM | Added field in query - Reference_Document_Number__c
                List<celsrm__Transaction__c> transList = [SELECT Id, Name, celsrm__Balance__c, celsrm__Disputed_Amount__c, celsrm__Close_Date__c, celsrm__Account__r.OwnerId, celsrm__Account__r.Owner.Name, CurrencyIsoCode, Sender_Document_Number__c, Reference_Document_Number__c FROM celsrm__Transaction__c WHERE Id IN: idList]; // added closed date field | FIN-8525 | Changed by Asera | 14 Oct 2025 --//
                //-- Ends | FIN-8510 | Changed by Ravi | 10 Oct 2025 --//
                //-- Start |FIN-8167| Changed By Asera | 12 Aug 2025 --//
                Map<Id, celsrm__Transaction__c> transactionsById = new Map<Id, celsrm__Transaction__c>();
                for(celsrm__Transaction__c trans : transList) {
                    transactionsById.put(trans.Id, trans);
                }
                //-- End |FIN-8167| Changed By Asera | 12 Aug 2025 --//
                for (Integer i = 0; i < trxnList.size(); i++) {
                    Map<Object, Object> trxnMap = (Map<Object, Object>)trxnList.get(i);
                    Id transactionId = (Id)trxnMap.get('Id');
                    celsrm__Transaction__c tranObj = transactionsById.get(transactionId);  // FIN-8167| Changed By Asera | 12 Aug 2025  one line changes--//
                    //-- Start |FIN-5812 - 5| Changed By Asera | 9 July 2024 --//
                    //-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
                    if(celsrm__Dispute_Configuration__c.getOrgDefaults().celsrm__Allow_Only_Debit_Invoices__c && tranObj.celsrm__Balance__c < 0) {
                        creditInvoiceNumberList.add(tranObj.Name);
                    } 
                    //-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
                    //-- Start |FIN-5812 - 5| Changed By Asera | 9 July 2024 --//
                    if (tranObj.celsrm__Balance__c == 0) {
                        zeroBalanceInvoiceNumberList.add(tranObj.Name);
                    } else {
                        trxnMap.put('disputeAmount', tranObj.celsrm__Balance__c);
                    }
                    // << START - MM - FIN-8493 - Dispute Summary - columns arrangement>>
                    trxnMap.put('Sender_Document_Number__c', tranObj.Sender_Document_Number__c);
                    // << END - MM - FIN-8493 - Dispute Summary - columns arrangement>>
                    // << START - MM - FIN-9931 - Dispute → Preview → Reference_Document_Number__c value not populated>>
                    trxnMap.put('Reference_Document_Number__c', tranObj.Reference_Document_Number__c);
                    // << END - MM - FIN-9931 - Dispute → Preview → Reference_Document_Number__c value not populated>>
                    //-- Start | FIN-8525 | Changed by Asera | 14 Oct 2025 --//
                    if (tranObj.celsrm__Close_Date__c != null) {
                        closedInvoiceNumberList.add(tranObj.Name);
                    }
                    //-- End | FIN-8525 | Changed by Asera | 14 Oct 2025 --//
                    if(!trxnMap.containsKey('DisputeResolver')){
                        Map<Object,Object> resolverMap = new Map<Object,Object>();
                        //-- Dispute Resolver Type is Account Owner --//
                        if(disputeResolverType == 'Account_Owner') {
                            resolverMap.put('id', tranObj.celsrm__Account__r.OwnerId);
                            resolverMap.put('name', tranObj.celsrm__Account__r.Owner.Name);
                        } else if(disputeResolverType == 'Logged_In_User') {
                        //-- Dispute Resolver Type is Logged In user --//
                            resolverMap.put('id', UserInfo.getUserId());
                            resolverMap.put('name', UserInfo.getName());
                        }
                        trxnMap.put('DisputeResolver', resolverMap);
                        trxnMap.put('WorkflowMatrix', null);
                        trxnMap.put('totalSLADays', null);
                        //-- Start | FIN-8510 | Changed by Ravi | 10 Oct 2025 --//
                        trxnMap.put('CurrencyIsoCode', tranObj.CurrencyIsoCode);
                        //-- Ends | FIN-8510 | Changed by Ravi | 10 Oct 2025 --//
                    }
                    
                    if(tranObj.celsrm__Disputed_Amount__c > 0) {
                        existingDisputes.add((String)trxnMap.get('Name'));
                    }
                }
                transactionsById = null;  // FIN-8167| Changed By Asera | 12 Aug 2025  one line changes--//
                //-- Starts |FIN-7502| Changed by Asera | 25 Nov 2025 --//
                try {
                    Map<String, Object> metadataMap = new Map<String, Object>{
                        'TransactionList' => inMap.get('TransactionList'),
                        'timestamp' => String.valueOf(Datetime.now())
                    };
                
                    String metadataJson = JSON.serialize(metadataMap);
                
                    Map<String, Object> inputParams = new Map<String, Object>{
                        'userId' => UserInfo.getUserId(),
                        'pageScreenName' => 'Account: Create Dispute',
                        'actionPerformed' => false,
                        'actionTakenTime' => null,
                        'accountId' => String.valueOf(inMap.get('Id')),
                        'transactionId' => null,
                        'disputeId' => null,
                        'additionalMetadata' => metadataJson
                    };
                
                    Id activityId = celsrm.SRMUtilityController.logActivity(JSON.serialize(inputParams));
                    System.debug('Full activity account: ' + activityId);
                    inMap.put('activityLogId', activityId);
                } catch (Exception e) {
                    System.debug('Error logging activity: ' + e.getMessage());
                    inMap.put('logActivityError', e.getMessage());
                }
                //-- End |FIN-7502| Changed by Asera | 25 Nov 2025 --//
                //-- Start |FIN-5812 - 5| Changed By Asera | 9 July 2024 --//
                if(creditInvoiceNumberList.size() > 0) {
                    String creditInvoiceNumbers = String.join(creditInvoiceNumberList, ', ');
                    ggErrorMessage = String.format(Label.No_Dispute_On_Credit_Invoice, new List<String>{creditInvoiceNumbers});
                }
                //-- Ends | FIN-7796 | Changed by Dilshad | 30-Jun-2025 --//
                //-- Start | FIN-5812 - 5 | Changed By Asera | 9 July 2024 --//
                if(zeroBalanceInvoiceNumberList.size() > 0) {
                    String zeroBalanceInvoiceNumbers = String.join(zeroBalanceInvoiceNumberList, ', ');
                    if(ggErrorMessage != '') {
                        ggErrorMessage = '\n'+String.format(Label.No_Dispute_On_Zero_Balance_Invoice, new List<String>{zeroBalanceInvoiceNumbers});
                    } else {
                        ggErrorMessage = String.format(Label.No_Dispute_On_Zero_Balance_Invoice, new List<String>{zeroBalanceInvoiceNumbers});
                    }
                }
                //-- Start | FIN-8525 | Changed by Asera | 14 Oct 2025 --//
                if(closedInvoiceNumberList.size() > 0) {
                    String closedInvoiceNumbers = String.join(closedInvoiceNumberList, ', ');
                    ggErrorMessage = String.format(Label.You_cannot_create_dispute_on_closed_invoice , new List<String>{closedInvoiceNumbers});
                }
                //-- End | FIN-8525 | Changed by Asera | 14 Oct 2025 --//
                if(ggErrorMessage != '') {
                    Map<Object, Object> returnMap  = new Map<Object, Object>();
                    returnMap.put('ggErrorMessage', ggErrorMessage);
                    return returnMap;
                }
            }
            // << START - MM - FIN-8503 - Create Dispute -> Total Amount in email - incorrect CurrencyISOCode>>
            inMap.put('accountCurrencyIsoCode', accountCurrencyIsoCode);
            // << END - MM - FIN-8503 - Create Dispute -> Total Amount in email - incorrect CurrencyISOCode>>
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
        //-- Starts: Set current user as owner of the dispute --//
        Map<Object, Object> ownerMap = new Map<Object, Object>();
        ownerMap.put('id', UserInfo.getUserId());
        ownerMap.put('name', UserInfo.getName());
        inMap.put('Owner', ownerMap);
        //-- Ends: Set current user as owner of the dispute --//

        //-- Starts: Set follow-up date --//
        inMap.put('FollowUpDate', Date.today().addDays(5));
        //-- Ends: Set follow-up date --//

        //-- Starts: Disputes already exist for selected transactions --//
        inMap.put('existingDisputes', String.join(existingDisputes, ', '));
        String enableDisputeReslover = String.valueOf(celsrm__Dispute_Configuration__c.getOrgDefaults().Enable_Dispute_Resolution__c);
        inMap.put('Enable_Dispute_Resolution__c', enableDisputeReslover);
        //-- Ends: Disputes already exist for selected transactions --//
        return inMap;
    }

    public static Map<Object, Object> getTransactionListFromSummaryAgent(Map<Object, Object> inMap) {
        //-- Start | FIN-8525 | Changed by Asera | 14 Oct 2025 --//
        Set<String> closedInvoiceNumberList = new Set<String>();
        String ggErrorMessage = '';
        //-- End | FIN-8525 | Changed by Asera | 14 Oct 2025 --//
        String arguments = String.valueOf(inMap.get('summaryArguments'));
        String accId = String.valueOf(inMap.get('Id'));
        String emailId = (String) inMap.get('emailId');
        inMap.put('emailMessageId', emailId);
        inMap.put('notifyCustomer', true);
        Map<String, Object> argumentsMap = (Map<String, Object> )JSON.deserializeUntyped(arguments);
        List<String> invoiceNumbers = new List<String>();
        for (Object inv: (List<Object>)argumentsMap.get('invoice_numbers')){
            invoiceNumbers.add(String.valueOf(inv));
        }
        List<celsrm__Transaction__c> transactions;
        if(invoiceNumbers.size() > 0) {
            String WorkflowMatrix = '';
            Integer totalSLADays = 0;
            //-- Starts | FIN-7425 | Changed by Ravi | 30-July-2025 --//
            Boolean isExternalResolver = false;
            Map<String, Object> resolverMap = new Map<String, Object>();
            //-- Ends | FIN-7425 | Changed by Ravi | 30-July-2025 --//
            Map<Object,Object> result;
            if(String.valueOf(inMap.get('disputeResolverType')) == 'Dispute_Workflow_Matrix' && (String)argumentsMap.get('dispute_type') != null && (String)argumentsMap.get('dispute_reason') != null){
                result = new Map<Object, Object>();
                result.put('selectedReasonCode', (String)argumentsMap.get('dispute_reason'));
                result.put('selectedType', (String)argumentsMap.get('dispute_type'));
                //-- Starts | FIN-7425 | Changed by Ravi | 30-July-2025 --//
                result.put('disputeResolverType', (String)inMap.get('disputeResolverType'));
                //-- Ends | FIN-7425 | Changed by Ravi | 30-July-2025 --//
                result = onChangeReasonCode(result);
                WorkflowMatrix = (String)result.get('relatedMatrixId');
                totalSLADays = (Integer)result.get('totalSLADays');
                //-- Starts | FIN-7425 | Changed by Ravi | 30-July-2025 --//
                resolverMap.put('id', result.get('resolverId'));
                resolverMap.put('name', result.get('resolverName'));
                //-- Start | FIN-9672 | Changed by Ravi | 05 May 2026 --//
                resolverMap.put('userMasterId', result.get('resolverUserMasterId'));
                //-- End | FIN-9672 | Changed by Ravi | 05 May 2026 --//
                isExternalResolver = (Boolean)result.get('isExternalResolver');
                
                //-- Ends | FIN-7425 | Changed by Ravi | 30-July-2025 --//
            }
            //-- Start | FIN-5814 | Changed By Megha | 8 July 2024 --//
            //-- Start | FIN-7425 | Changed By Ravi | 13 Aug 2025 --//
            // << CHANGE - MM - FIN-9536 : Sender_Document_Number__c | FIN-9798 : celsrm__Create_Date__c -> Invoice_Date_NF__c | FIN-9798 : Due_Date_2__c, Country_Code__c | FIN-9931 : Reference_Document_Number__c
            transactions = [SELECT Id, celsrm__Account__c, celsrm__Balance__c, Name, CurrencyIsoCode, celsrm__Amount__c, celsrm__Close_Date__c, celsrm__Account__r.OwnerId, celsrm__Account__r.Owner.Name, Invoice_Date_NF__c, Sender_Document_Number__c, Due_Date_2__c, Country_Code__c, Reference_Document_Number__c FROM  celsrm__Transaction__c WHERE celsrm__Account__c = :accId And Name IN :invoiceNumbers And celsrm__Amount__c != 0]; // Added Closed date | FIN-8525 | Changed by Asera | 14 Oct 2025 --//
            //-- End | FIN-7425 | Changed By Ravi | 13 Aug 2025 --//
            //-- End | FIN-5814 | Changed By Megha | 8 July 2024 --//
            List<Map<Object, Object>> transactionList = new List<Map<Object, Object>>();
            for(celsrm__Transaction__c trans: transactions) {
                Map<Object, Object> transMap = new Map<Object, Object>();
                transMap.put('Id', trans.Id);
                transMap.put('celsrm__Balance__c', trans.celsrm__Balance__c);
                //-- Start | FIN-5815 | Changed By Megha | 8 July 2024 --//
                transMap.put('celsrm__Amount__c', trans.celsrm__Amount__c);
                //-- End | FIN-5815 | Changed By Megha | 8 July 2024 --//
                //-- Start | FIN-7425 | Changed By Ravi | 13 Aug 2025 --//
                // << START - MM - FIN-9798 - celsrm__Create_Date__c -> Invoice_Date_NF__c >>
                transMap.put('celsrm__Create_Date__c', trans.Invoice_Date_NF__c);
                //-- End | FIN-7425 | Changed By Ravi | 13 Aug 2025 --//
                //-- Start | FIN-8530 | Changed by Ravi | 10 Nov 2025 --//
                transMap.put('celsrm__Account__c', trans.celsrm__Account__c);
                //-- End | FIN-8530 | Changed by Ravi | 10 Nov 2025 --//
                transMap.put('Name', trans.Name);
                transMap.put('NameSort', trans.Name);
                transMap.put('disputeType', argumentsMap.get('dispute_type'));
                transMap.put('reasonCode', argumentsMap.get('dispute_reason'));
                if((String)argumentsMap.get('dispute_type') != null && (String)argumentsMap.get('dispute_reason') != null){
                    transMap.put('WorkflowMatrix', WorkflowMatrix);
                    transMap.put('totalSLADays', totalSLADays);
                    //-- Starts | FIN-7425 | Changed by Ravi | 30-July-2025 --//
                    transMap.put('isExternalResolver', isExternalResolver);
                    //-- Ends | FIN-7425 | Changed by Ravi | 30-July-2025 --//
                }
                //-- Starts | FIN-7425 | Changed by Ravi | 30-July-2025 --//
                if(String.valueOf(inMap.get('disputeResolverType')) == 'Dispute_Workflow_Matrix'){
                    System.debug('DisputeResolver 1>>> ' + resolverMap);
                    transMap.put('DisputeResolver', resolverMap);
                } else if(String.valueOf(inMap.get('disputeResolverType')) == 'Logged_In_User') { //-- Dispute Resolver Type is Logged In user --//
                    System.debug('DisputeResolver 2>>> ' + resolverMap);
                    resolverMap.put('id', UserInfo.getUserId());
                    resolverMap.put('name', UserInfo.getName());
                    transMap.put('DisputeResolver', resolverMap);
                } else {
                    System.debug('DisputeResolver 3>>> ' + resolverMap);
                    resolverMap.put('id', trans.celsrm__Account__r.OwnerId);
                    resolverMap.put('name', trans.celsrm__Account__r.Owner.Name);
                    transMap.put('DisputeResolver', resolverMap);
                }
                //-- Ends | FIN-7425 | Changed by Ravi | 30-July-2025 --//
                //-- Start | FIN-5814 | Changed By Megha | 8 July 2024 --//
                transMap.put('CurrencyIsoCode', trans.CurrencyIsoCode);
                //-- End | FIN-5814 | Changed By Megha | 8 July 2024 --//
                //-- Start | FIN-8525 | Changed by Asera | 14 Oct 2025 --// 
                if (trans.celsrm__Close_Date__c != null) {
                    closedInvoiceNumberList.add(trans.Name);
                }
                //-- End | FIN-8525 | Changed by Asera | 14 Oct 2025 --//
                // << START - MM - FIN-9536 - Add Sender_Document_Number__c (Invoice#) in table & email>>
                transMap.put('Sender_Document_Number__c', trans.Sender_Document_Number__c);
                // << END - MM - FIN-9536 - Add Sender_Document_Number__c (Invoice#) in table & email>>
                // << START - MM - FIN-9931 - Dispute → Preview → Reference_Document_Number__c value not populated>>
                transMap.put('Reference_Document_Number__c', trans.Reference_Document_Number__c);
                // << END - MM - FIN-9931 - Dispute → Preview → Reference_Document_Number__c value not populated>>
                // << START - MM - FIN-9798 - Added Due_Date_2__c, Country_Code__c >>
                transMap.put('Due_Date_2__c', trans.Due_Date_2__c);
                transMap.put('Country_Code__c', trans.Country_Code__c);
                // << END - MM - FIN-9798 - Added Due_Date_2__c, Country_Code__c >>
                transactionList.add(transMap);
            }
            inMap.put('TransactionList', transactionList);
            //-- Start | FIN-8525 | Changed by Asera | 14 Oct 2025 --//
            if(closedInvoiceNumberList.size() > 0) {
                String closedInvoiceNumbers = String.join(closedInvoiceNumberList, ', ');
                ggErrorMessage = String.format(Label.You_cannot_create_dispute_on_closed_invoice , new List<String>{closedInvoiceNumbers});
            }
            if(ggErrorMessage != '') {
                inMap.put('ggErrorMessage', ggErrorMessage);
            }
            //-- End | FIN-8525 | Changed by Asera | 14 Oct 2025 --//

        } else {
            inMap.put('ggErrorMessage', 'Please provide at least one transaction to create a Promise to Pay.');
            return inMap;
        }
        inMap.put('createMultipleDispute', true);
        return inMap;
    }
    //-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
    private static Map<String, String> getCreateDisputeFieldMapping() {
        Map<String, String> fieldMapping = new Map<String, String>{
            'Dispute_Type__c' => 'disputeType',
            'Reason_Code__c' => 'reasonCode',
            'Amount__c' => 'disputeAmount'
        };
        for (String baseFieldApi : new Map<String, String>(fieldMapping).keySet()) {
            String namespacedFieldApi = celsrm.ApprovalConfigController.getFullApiName(baseFieldApi);
            if (String.isNotBlank(namespacedFieldApi) && !fieldMapping.containsKey(namespacedFieldApi)) {
                fieldMapping.put(namespacedFieldApi, fieldMapping.get(baseFieldApi));
            }
        }
        return fieldMapping;
    }

    private static Map<String, Object> buildCreateDisputeInputValues(Map<Object, Object> inMap) {
        Map<String, Object> inputValues = new Map<String, Object>();
        if (inMap == null) {
            return inputValues;
        }

        putInputValueIfPresent(inputValues, 'disputeType', inMap.get('selectedType'));
        putInputValueIfPresent(inputValues, 'reasonCode', inMap.get('selectedReasonCode'));

        Map<Object, Object> selectedRow = extractSelectedTransactionRowForResolver(inMap);
        putInputValueIfPresent(inputValues, 'disputeType', selectedRow.get('disputeType'));
        putInputValueIfPresent(inputValues, 'reasonCode', selectedRow.get('reasonCode'));
        putDecimalInputValueIfPresent(inputValues, 'disputeAmount', selectedRow.get('disputeAmount'));
        if (!inputValues.containsKey('disputeAmount') && selectedRow.get('amount') != null) {
            putDecimalInputValueIfPresent(inputValues, 'disputeAmount', selectedRow.get('amount'));
        }
        return inputValues;
    }

    private static Map<Object, Object> extractSelectedTransactionRowForResolver(Map<Object, Object> inMap) {
        if (inMap.containsKey('selectedTransactionRow') && inMap.get('selectedTransactionRow') instanceof Map<Object, Object>) {
            return (Map<Object, Object>) inMap.get('selectedTransactionRow');
        }
        if (!inMap.containsKey('TransactionList') || !(inMap.get('TransactionList') instanceof List<Object>)) {
            return new Map<Object, Object>();
        }
        List<Object> transactionList = (List<Object>) inMap.get('TransactionList');
        if (transactionList.isEmpty()) {
            return new Map<Object, Object>();
        }
        Integer rowIndex = resolveSelectedRowIndex(inMap, transactionList.size());
        Object rowObj = transactionList.get(rowIndex);
        return rowObj instanceof Map<Object, Object> ? (Map<Object, Object>) rowObj : new Map<Object, Object>();
    }

    private static Integer resolveSelectedRowIndex(Map<Object, Object> inMap, Integer listSize) {
        List<String> rowIndexKeys = new List<String>{
            'selectedRowIndex',
            'rowNum',
            'gogGridIndex'
        };
        for (String key : rowIndexKeys) {
            if (inMap == null || inMap.get(key) == null) {
                continue;
            }
            try {
                Integer rowIndex = Integer.valueOf(String.valueOf(inMap.get(key)));
                if (rowIndex >= 0 && rowIndex < listSize) {
                    return rowIndex;
                }
            } catch (Exception ex) {
                continue;
            }
        }
        return 0;
    }

    private static void putInputValueIfPresent(Map<String, Object> inputValues, String key, Object rawValue) {
        if (rawValue == null) {
            return;
        }
        String valueString = String.valueOf(rawValue).trim();
        if (String.isNotBlank(valueString) && valueString != 'null') {
            inputValues.put(key, valueString);
        }
    }

    private static void putDecimalInputValueIfPresent(Map<String, Object> inputValues, String key, Object rawValue) {
        if (rawValue == null) {
            return;
        }
        try {
            if (rawValue instanceof Decimal) {
                inputValues.put(key, (Decimal) rawValue);
            } else if (rawValue instanceof Integer) {
                inputValues.put(key, Decimal.valueOf((Integer) rawValue));
            } else if (rawValue instanceof Long) {
                inputValues.put(key, Decimal.valueOf((Long) rawValue));
            } else if (rawValue instanceof Double) {
                inputValues.put(key, Decimal.valueOf((Double) rawValue));
            } else {
                String valueString = String.valueOf(rawValue).trim();
                if (String.isNotBlank(valueString) && valueString != 'null') {
                    inputValues.put(key, Decimal.valueOf(valueString));
                }
            }
        } catch (Exception ex) {
            // Invalid amount from UI — omit so criteria can still match on other fields.
        }
    }
    //-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//

    //-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//

    public static Map<Object, Object> onChangeReasonCode(Map<Object, Object> inMap) {
        //-- Dispute Resolver Type is Dispute Workflow Matrix --//
        //-- Starts | FIN-7796 | Changed by Dilshad | 30-Jun-2025 --//
        if(String.valueOf(inMap.get('disputeResolverType')) == 'Dispute_Workflow_Matrix') {
            
            Map<String, Object> inputValues = buildCreateDisputeInputValues(inMap);
            Map<String, String> fieldMapping = getCreateDisputeFieldMapping();

            DisputeWorkflowRuleEvaluator.ResolverLookupResult lookupResult =
                DisputeWorkflowRuleEvaluator.resolveResolverForCreate(inputValues, fieldMapping);

            if (lookupResult != null && lookupResult.isSuccess == true) {
                inMap.put('resolverId', lookupResult.resolverId);
                inMap.put('resolverName', lookupResult.resolverName);
                inMap.put('resolverUserMasterId', lookupResult.resolverUserMasterId);
                inMap.put('isExternalResolver', lookupResult.isExternalResolver);
                inMap.put('relatedMatrixId', lookupResult.relatedMatrixId);
                inMap.put('totalSLADays', lookupResult.totalSLADays);
                return inMap;
            }

            Map<Object, Object> returnMap = new Map<Object, Object>();
            returnMap.put('resolverId', null);
            returnMap.put('resolverName', null);
                    //-- Start | FIN-9672 | Changed by Ravi | 05 May 2026 --//
            returnMap.put('resolverUserMasterId', null);
                    //-- End | FIN-9672 | Changed by Ravi | 05 May 2026 --//
            returnMap.put('relatedMatrixId', null);
            returnMap.put('totalSLADays', null);
            returnMap.put('ggErrorMessage', Label.Configuration_Missing_No_Resolver_Found);
            return returnMap;
        }
        //-- Ends | FIN-7796 | Changed by Dilshad | 30-Jun-2025 --//
        return inMap;
    }
    //-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//


    //-- This method will validate dispute data --//
    public static Map<Object, Object> validateDisputes(Map<Object, Object> inMap) {
        List < Object > trxnsObjList = (List < Object > ) inMap.get('TransactionList');
        Map<Object, Object> returnMap = new Map<Object, Object>();
        List<String> disputeResolverMissing = new List<String>();
        List<String> disputeAmountInvalid = new List<String>();
        for (Object trxnObj: trxnsObjList) {
            Map <Object, Object> trxnMap = (Map <Object, Object> ) trxnObj;
            //-- Starts | FIN-7796 | Changed by Dilshad | 30-Jun-2025 --//
            Map<Object,Object> resolverMap = (Map<Object,Object>)trxnMap.get('DisputeResolver');
            if(resolverMap != null && resolverMap.get('id') == null) {
                disputeResolverMissing.add((String)trxnMap.get('Name'));
            }
            //-- Ends | FIN-7796 | Changed by Dilshad | 30-Jun-2025 --//
            //-- Start |FIN-5812 - 5| Changed By Asera | 9 July 2024 --//
            Decimal transAmount = Double.valueOf(trxnMap.get('celsrm__Balance__c'));
            if (trxnMap != null && trxnMap.get('disputeAmount') != null && (Decimal)trxnMap.get('disputeAmount') == 0) {
                disputeAmountInvalid.add((String)trxnMap.get('Name'));
            } else if((Decimal)trxnMap.get('disputeAmount') > 0 && (Decimal)trxnMap.get('disputeAmount') > transAmount){
                disputeAmountInvalid.add((String)trxnMap.get('Name'));
            } else if ((Decimal)trxnMap.get('disputeAmount') < 0 && (Decimal)trxnMap.get('disputeAmount') < transAmount) {
                disputeAmountInvalid.add((String)trxnMap.get('Name'));
            }
            //-- Start |FIN-5812 - 5| Changed By Asera | 9 July 2024 --//
        }
        String errorMessage = '';
        //-- Starts | FIN-7796 | Changed by Dilshad: labels added | 30-Jun-2025 --//
        if(disputeAmountInvalid.size() > 0) {
            errorMessage += Label.Dispute_Amount_Is_Invalid + ' ' + String.join(disputeAmountInvalid, ', ') + '. ' + Label.Provide_Valid_Dispute_Amount;
        }
        if(disputeResolverMissing.size() > 0) {
            errorMessage += Label.Dispute_Resolver_Is_Missing + ' ' + String.join(disputeResolverMissing, ', ') + '. ' + Label.Please_Configure_Dispute_Resolver;
        }
        //-- Ends | FIN-7796 | Changed by Dilshad: labels Added | 30-Jun-2025 --//
        if(errorMessage != '') {
            returnMap.put('ggErrorMessage', errorMessage);
            returnMap.put('stopExecution', true);
            return returnMap;
        } else {
            return null;
        }
    }

    //-- This method will save dispute details --//
    public static Map<Object, Object> saveDispute(Map<Object, Object> inMap) {
        Savepoint sp = Database.setSavepoint();
        try {
            List < Object > trxnsObjList = (List < Object > ) inMap.get('TransactionList');
            //-- Starts: Save Dispute List --//
            System.debug('====saveDispute====');
            List<celsrm__Dispute__c> insertDisputeList = new List<celsrm__Dispute__c>();
            //-- Starts | FIN-6130 | Changed by Dilshad | 26 Jun 2024 --//
            Set<String> accountIDs = new Set<String>();
            //-- Ends | FIN-6130 | Changed by Dilshad | 26 Jun 2024 --//
            List<String> trxnIDs = new List<String>();
            List<String> invoiceNumberList = new List<String>();
            
            String note = inMap.get('NoteBody') != null && inMap.get('NoteBody') != '' ? String.valueOf(inMap.get('NoteBody')) : null;
            Map<String, Object> transactionDocumentMap = new Map<String, Object>();
            List<ContentDocumentLink> cdlList = new List<ContentDocumentLink>();
            // << START - MM - FIN-8420 - Assigne Status based on Notify>>
            String disputeStatus = (String)inMap.get('disputeStatus');
            // << END - MM - FIN-8420 - Assigne Status based on Notify>>
            //-- Starts | FIN-9786 | Changed by Asera | 24-Jun-2026 --//
            String disputeResolverType = !String.isEmpty(celsrm__Dispute_Configuration__c.getOrgDefaults().celsrm__Dispute_Resolver_Type__c)
                ? celsrm__Dispute_Configuration__c.getOrgDefaults().celsrm__Dispute_Resolver_Type__c
                : 'Account_Owner';
            Boolean shouldCreateDirectWorkflowDetail = disputeResolverType == 'Logged_In_User'
                || disputeResolverType == 'Account_Owner';
            //-- Ends | FIN-9786 | Changed by Asera | 24-Jun-2026 --//

            for (Object trxnObj: trxnsObjList) {
                Map < Object, Object > trxnMap = (Map < Object, Object > ) trxnObj;
                Id key = (String) trxnMap.get('Id');
                trxnIDs.add(key);
                celsrm__Dispute__c disputeObj = new celsrm__Dispute__c();
                if(inMap.containsKey('calledFromTransactionDetailScreen') && Boolean.valueOf(inMap.get('calledFromTransactionDetailScreen')) == true) { 
                    //-- Dispute created from transaction detail screen --//
                    disputeObj.celsrm__Account__c = String.valueOf(inMap.get('celsrm__Account__c'));
                } else if (trxnMap.get('celsrm__Account__r') != null) {
                    disputeObj.celsrm__Account__c = String.valueOf(((Map<Object,Object>)trxnMap.get('celsrm__Account__r')).get('Id'));
                } 
                //-- Start | FIN-8530 | Changed by Ravi | 10 Nov 2025 --//
                else if (trxnMap.get('celsrm__Account__c') != null) {
                    disputeObj.celsrm__Account__c = String.valueOf(trxnMap.get('celsrm__Account__c'));
                } 
                //-- End | FIN-8530 | Changed by Ravi | 10 Nov 2025 --//
                else {
                    disputeObj.celsrm__Account__c = String.valueOf(inMap.get('Id'));
                }
                accountIDs.add(disputeObj.celsrm__Account__c);
                invoiceNumberList.add(String.valueOf(trxnMap.get('Name')));
                disputeObj.celsrm__Amount__c = (Decimal)trxnMap.get('disputeAmount');
                disputeObj.celsrm__Transaction__c = String.valueOf(trxnMap.get('Id'));
                
                if(inMap.get('Owner') != null && inMap.get('Owner') != '') {
                    Map<Object,Object> ownerMap = (Map<Object,Object>)inMap.get('Owner');
                    //owner = (map<string,string>)JSON.deserialize(JSON.serialize(inMap.get('Owner')), map<string,string>.class);
                    if (ownerMap.get('id') != null && ownerMap.get('id') != '' ){
                        disputeObj.celsrm__Owner__c = String.valueOf(ownerMap.get('id'));
                    } else {
                        disputeObj.celsrm__Owner__c = UserInfo.getUserId();
                    }
                }
                if(note != null) {
                    disputeObj.celsrm__Latest_Note__c = note;
                    disputeObj.celsrm__Latest_Note_Entered_By__c = UserInfo.getUserId();
                }
                if(trxnMap != null && trxnMap.get('disputeType') != null ){
                    disputeObj.celsrm__Dispute_Type__c = String.valueOf(trxnMap.get('disputeType'));
                    disputeObj.celsrm__Reason_Code__c = String.valueOf(trxnMap.get('reasonCode'));
                }
                //-- Starts | FIN-7796 | Changed by Dilshad | 26-Jun-2025 --//
                //-- Starts | FIN-9786 | Changed by Asera | 24-Jun-2026 --//
                if(disputeResolverType == 'Dispute_Workflow_Matrix') {
                //-- Ends | FIN-9786 | Changed by Asera | 24-Jun-2026 --//
                    // disputeObj.Workflow_Matrix_Id__c = String.valueOf(trxnMap.get('WorkflowMatrix'));
                    disputeObj.celsrm__Workflow_Matrix_Id__c = String.valueOf(trxnMap.get('WorkflowMatrix'));
                    disputeObj.Dispute_SLA_Days__c = Integer.valueOf(String.valueOf(trxnMap.get('totalSLADays')));
                } 
                Map<Object,Object> resolverMap = (Map<Object,Object>)trxnMap.get('DisputeResolver');
                //-- Start | FIN-9672 | Changed by Ravi | 05 May 2026 --//
                //-- Starts | FIN-9786 | Changed by Asera | 24-Jun-2026 --//
                Object resolverIdentifierValue = resolverMap != null
                    ? (resolverMap.get('id') != null ? resolverMap.get('id') : resolverMap.get('Id'))
                    : null;
                Object resolverNameValue = resolverMap != null
                    ? (resolverMap.get('name') != null ? resolverMap.get('name') : resolverMap.get('Name'))
                    : null;
                //-- Ends | FIN-9786 | Changed by Asera | 24-Jun-2026 --//
                Id resolverUserMasterId = resolverMap != null && resolverMap.get('userMasterId') != null
                    ? Id.valueOf(String.valueOf(resolverMap.get('userMasterId')))
                    : null;
                //-- Starts | FIN-9786 | Changed by Asera | 24-Jun-2026 --//
                String resolverIdentifier = resolverIdentifierValue != null ? String.valueOf(resolverIdentifierValue) : null;
                //-- Ends | FIN-9786 | Changed by Asera | 24-Jun-2026 --//
                DisputeUserMasterService.ResolvedUserInfo resolvedResolver = DisputeUserMasterService.resolveUserAssignment(
                    resolverUserMasterId,
                    resolverIdentifier,
                    //-- Starts | FIN-9786 | Changed by Asera | 24-Jun-2026 --//
                    resolverNameValue != null ? String.valueOf(resolverNameValue) : null,
                    //-- Ends | FIN-9786 | Changed by Asera | 24-Jun-2026 --//
                    trxnMap.get('isExternalResolver') != null && Boolean.valueOf(trxnMap.get('isExternalResolver')),
                    null
                );
                DisputeUserMasterService.applyAssignmentToDispute(disputeObj, resolvedResolver);
                //-- End | FIN-9672 | Changed by Ravi | 05 May 2026 --//
                //-- Ends | FIN-7796 | Changed by Dilshad | 26-Jun-2025 --//
                // << START - MM - FIN-8420 - Assigne Status based on Notify>>
                // disputeObj.celsrm__Status__c = 'In Progress';
                disputeObj.celsrm__Status__c = disputeStatus != null ? disputeStatus : '10 New';
                // << END - MM - FIN-8420 - Assigne Status based on Notify>>
                //-- Start | FIN-5814 | Changed By Megha | 8 July 2024 --//
                disputeObj.CurrencyIsoCode = String.valueOf(trxnMap.get('CurrencyIsoCode'));
                //-- End | FIN-5814 | Changed By Megha | 8 July 2024 --//
                System.debug('disputeObj' +disputeObj);
                insertDisputeList.add(disputeObj);
                List<Object> attachmentList = (List<Object>) trxnMap.get('attachments');
                transactionDocumentMap.put(key, attachmentList);
            }
            //-- Start | FIN-8530 | Changed by Ravi | 10 Nov 2025 --//
            String accountId = (String) inMap.get('Id');
            if(!accountIDs.contains(accountId) && accountId.startsWithIgnoreCase('001')){
                accountIDs.add(accountId);
            }
            //-- End | FIN-8530 | Changed by Ravi | 10 Nov 2025 --//
            System.debug('insertDisputeList' +insertDisputeList);
            if(insertDisputeList != null && insertDisputeList.size() > 0){
                insert insertDisputeList;
            }
            //-- Ends: Save Dispute List --//
            inMap.put('DisputeList', insertDisputeList);
            List<String> disIds = new List<String>();
            //-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
            List<celsrm__Dispute_Workflow_Details__c> workflowDetailList = new List<celsrm__Dispute_Workflow_Details__c>();
            //-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
            //-- Starts: Update attachments & insert workflow details for disputes --//
            Set<String> isLinkAvailableAccount = new Set<String> ();
            for (celsrm__Dispute__c dispute: insertDisputeList) {
                disIds.add(dispute.Id);
                List<Object> aList = (List<Object>)transactionDocumentMap.get(dispute.celsrm__Transaction__c);
                if(aList != null && aList.size() > 0) {
                    for (Object attachmentObj : aList) {
                        Map < Object, Object > attachmentMap = (Map < Object, Object > ) attachmentObj;
                        //-- Attachments on Dispute --//
                        ContentDocumentLink newLinkDis = new ContentDocumentLink();
                        newLinkDis.ContentDocumentId = String.valueOf(attachmentMap.get('ContentDocumentId'));
                        newLinkDis.LinkedEntityId = dispute.Id;
                        newLinkDis.ShareType = 'V'; // 'V' for Viewer access, use 'I' for Inferred permission
                        newLinkDis.Visibility = 'AllUsers'; // 'AllUsers' for public access, use 'InternalUsers' for internal access
                        cdlList.add(newLinkDis);
                        //-- Attachments on Account --//
                        String key = String.valueOf(attachmentMap.get('ContentDocumentId')) +  dispute.celsrm__Account__c;
                        if(!isLinkAvailableAccount.contains(key)){
                            ContentDocumentLink newLinkAcc = new ContentDocumentLink();
                            isLinkAvailableAccount.add(key);
                            newLinkAcc.ContentDocumentId = String.valueOf(attachmentMap.get('ContentDocumentId'));
                            newLinkAcc.LinkedEntityId = dispute.celsrm__Account__c;
                            newLinkAcc.ShareType = 'V'; 
                            newLinkAcc.Visibility = 'AllUsers'; 
                            cdlList.add(newLinkAcc);
                        }
                    }
                }
                //-- Starts | FIN-9786 | Changed by Asera | 24-Jun-2026 --//
                if(shouldCreateDirectWorkflowDetail) {
                    //-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
                    celsrm__Dispute_Workflow_Details__c workflowDetail = new celsrm__Dispute_Workflow_Details__c();
                    workflowDetail.celsrm__Status__c = 'Pending';
                    workflowDetail.celsrm__Dispute__c = dispute.Id;
                    workflowDetail.celsrm__Workflow_Level__c = 1;
                    // workflowDetail.celsrm__Workflow_User_Type__c = 'Resolver';
                    //-- Start | FIN-9672 | Changed by Ravi | 05 May 2026 --//
                    DisputeUserMasterService.applyAssignmentToWorkflowDetail(
                        workflowDetail,
                        DisputeUserMasterService.resolveUserAssignment(
                            dispute.celsrm__Resolver_User_Master__c,
                            dispute.celsrm__Dispute_Resolver__c != null
                                ? String.valueOf(dispute.celsrm__Dispute_Resolver__c)
                                : dispute.External_Resolver_Email__c,
                            null,
                            !String.isBlank(dispute.External_Resolver_Email__c),
                            null
                        )
                    );
                    //-- End | FIN-9672 | Changed by Ravi | 05 May 2026 --//
                    workflowDetailList.add(workflowDetail);
                }
                //-- Ends | FIN-9786 | Changed by Asera | 24-Jun-2026 --//
            }
            if(cdlList != null && cdlList.size() > 0) {
                insert cdlList;
            }
            //-- Starts | FIN-9786 | Changed by Asera | 24-Jun-2026 --//
            if(shouldCreateDirectWorkflowDetail && workflowDetailList.size() > 0) {
                insert workflowDetailList;
            }
            //-- Ends | FIN-9786 | Changed by Asera | 24-Jun-2026 --//
            //-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
            //-- Ends: Update attachments & insert workflow details for disputes --//
            //-- Starts: Capture Follow-Up Task --//
            if (inMap.get('isFollowUp') != null && Boolean.valueOf(inMap.get('isFollowUp'))) {
                Task followUpTask = new Task();
                followUpTask.Subject = 'Create Dispute : Follow-Up';
                // followUpTask.Description = 'Take follow up on dispute created for invoices '+ String.join(invoiceNumberList, ', ') + '.';
                followUpTask.Description = note;
                followUpTask.Status = 'Not Started';
                followUpTask.WhatId = inMap.containsKey('calledFromTransactionDetailScreen') && Boolean.valueOf(inMap.get('calledFromTransactionDetailScreen')) == true ? String.valueOf(inMap.get('celsrm__Account__c')) : String.valueOf(inMap.get('Id'));
                followUpTask.ActivityDate = Date.valueOf((String) inMap.get('FollowUpDate'));
                followUpTask.Type = 'Create Dispute';
                followUpTask.Priority = 'High';
                Database.insert(followUpTask, AccessLevel.SYSTEM_MODE);
            }
            //-- Ends: Capture Follow-Up Task --//
            //-- Starts: Capture Celonis activity for dispute, transaction and account --//
            Datetime currentDateTime = Datetime.now();
            //-- Starts | FIN-6130 | Changed by Dilshad | 26 Jun 2024 --//
            Map<String, String> accIdActivityIdMap = new Map<String, String>();
            Map<String, Object> additionalFields = new Map<String, Object>();
            if(inMap.containsKey('UserType') && inMap.get('UserType') != null){
                additionalFields.put('User_Type__c', inMap.get('UserType'));
            }
            if(!accountIDs.isEmpty()){
                List<String> accountIdsList = new List<String>(accountIds);
                accIdActivityIdMap = celsrm.SRMUtilityController.insertActivity(accountIdsList, 'Account__c', 'Dispute Created', currentDateTime, 100, note, UserInfo.getUserId(), null, 'Internal', additionalFields);
            }
            // Map<String, Object> additionalFields = new Map<String, Object>();
            for (String accId : accIdActivityIdMap.keySet()) {
                additionalFields.put('Parent_Event__c', accIdActivityIdMap.get(accId));
            }
            if(!trxnIDs.isEmpty()){
                celsrm.SRMUtilityController.insertActivity(trxnIDs, 'Transaction__c', 'Dispute Created', currentDateTime, 100, note, UserInfo.getUserId(), null, 'Internal', additionalFields);
            }
            if(!disIds.isEmpty()){
                celsrm.SRMUtilityController.insertActivity(disIds, 'celsrm__Dispute__c', 'Dispute Created', currentDateTime, 100, note, UserInfo.getUserId(), null, 'Internal', additionalFields);
            }
            //-- Ends | FIN-6130 | Changed by Dilshad | 26 Jun 2024 --//
            //-- Ends: Capture Celonis activity for dispute, transaction and account --//
            //-- Starts: Send email to customer --//
            GOGCustomEmailSend sendEmailObj = new GOGCustomEmailSend();
            inMap = sendEmailObj.invoke('', inMap);
            //-- Starts | FIN-7025 | Changed By Dilshad | 20 Jan 2025 --//
            if(inMap.containsKey('ggErrorMessage')) {
                Database.rollback(sp);
                return inMap;
            }
            //-- Ends | FIN-7025 | Changed By Dilshad | 20 Jan 2025 --//
            //-- Ends: Send email to customer --//
            //-- Starts: Refresh transaction grid to reflect dispute icons --//
            Map<String, Object> refreshParentValues = new Map<String, Object>();
            if(inMap.containsKey('ListView')) {
                refreshParentValues.put('name', 'ListView');
                refreshParentValues.put('value', inMap.get('ListView'));
                refreshParentValues.put('onChangeMethod','filterDataByView');
            }
            inMap.put('refreshParentValues', refreshParentValues);
            //-- Starts |FIN-7502| Changed by Asera | 25 Nov 2025 --//
            try {
                Map<String, Object> metadataMap = new Map<String, Object>{
                    'DisputeObj' => JSON.serialize(insertDisputeList),
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
            //-- Ends: Refresh transaction grid to reflect dispute icons --//
            //-- Starts | FIN-6361 | Changed by Dilshad | 28 Aug 2024 --//
            system.debug('check emailId >>> ' + inMap.get('emailMessageId'));
            //-- Starts | FIN-7691 | Changed by Dilshad | 27 May 2025 --//
            if(inMap.get('emailMessageId') != null && inMap.get('emailMessageId') != '') {
            //-- Ends | FIN-7691 | Changed by Dilshad | 27 May 2025 --//
                String emailMessageId = String.valueOf(inMap.get('emailMessageId'));
                UtilityController.updateActionTakenOnEmailMessage(emailMessageId, 'Dispute Created');
            }
            //-- Ends | FIN-6361 | Changed by Dilshad | 28 Aug 2024 --//
            //-- Start | FIN-6854 | Changed By Dilshad | 24 Jan 2025 --//
            // if(trxnIDs != null && trxnIDs.size() > 0) {
            //     NextBestActionController.clearNextBestAction(trxnIDs);
            // }
            //-- Start | FIN-6854 | Changed By Dilshad | 24 Jan 2025 --// 
        } catch (DmlException dmlEx) {
            Database.rollback(sp);
            System.debug('DML Exception: ' + dmlEx.getMessage());
            System.debug(dmlEx.getStackTraceString());
            if(dmlEx.getMessage().contains('Storage limit exceeded. Please contact system admin.')) {
                inMap.put('ggErrorMessage', '');
            } else {
                inMap.put('ggErrorMessage', Label.Error_In_Dispute_Creation);
            }
            
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

    public static Map<Object, Object> getTransactionListFromActivity(Map<Object, Object> inMap) {
        //-- Start | FIN-8525 | Changed by Asera | 14 Oct 2025 --//
        Set<String> closedInvoiceNumberList = new Set<String>();
        String ggErrorMessage = '';
        //-- End | FIN-8525 | Changed by Asera | 14 Oct 2025 --//
        List<String> invNo = new List<String>();
        String accId = String.valueOf(inMap.get('Id'));
        Map<Object, Object> activityData = (Map<Object, Object>)inMap.get('activityData');
        Map<String, Object> classificationResponse = null;
        // if(!activityData.containsKey('celsrm__Classification_Response__c')) {
        //     List<EmailMessage> emList = [SELECT Id, celsrm__Classification_Response__c FROM EmailMessage WHERE Id = :String.valueOf(activityData.get('Id'))];
        //     if(emList != null && emList.size() > 0 && emList.get(0).celsrm__Classification_Response__c != null) {
        //         EmailMessage em = emList.get(0);
        //         classificationResponse = (Map<String, Object>)JSON.deserializeUntyped(em.celsrm__Classification_Response__c);
        //         inMap.put('emailMessageId', em.Id);
        //     } else {
        //         inMap.put('enableSubmitButton', false);
        //     }
        // } else {
        //     classificationResponse = (Map<String, Object>)JSON.deserializeUntyped((String)activityData.get('celsrm__Classification_Response__c'));
        // }
        //-- Starts | FIN-6410| Changes By: Asera | 18 Sep 2024 --//
        if(String.valueOf(activityData.get('Id')) != ''){
            String emailMessageId = String.valueOf(activityData.get('Id'));
            // FIN-7330 || Checks on Activity Data EmailMsg ID for caputuring Dispute event.
            inMap.put('emailMessageId', emailMessageId);
            String classificationResponseString = celsrm.SRMUtilityController.getClassificationResponse(emailMessageId); 
            if(classificationResponseString != null && classificationResponseString != ''){
                classificationResponse = (Map <string, object> ) JSON.deserializeUntyped(classificationResponseString);
                inMap.put('emailMessageId', emailMessageId);
            } else {
                inMap.put('enableSubmitButton', false);
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
            //-- Start | FIN-5814 | Changed By Megha | 8 July 2024 --//
            //-- Start | FIN-8201 | Changed By Ravi | 5 Nov 2024 --//
            // << CHANGE - MM - FIN-9536 : Sender_Document_Number__c | FIN-9798 : celsrm__Create_Date__c -> Invoice_Date_NF__c | FIN-9798 : Due_Date_2__c, Country_Code__c | FIN-9931 : Reference_Document_Number__c
            transactions = [SELECT Id, celsrm__Account__c, celsrm__Close_Date__c, celsrm__Balance__c, Name, CurrencyIsoCode, celsrm__Amount__c, Invoice_Date_NF__c, Sender_Document_Number__c, Due_Date_2__c, Country_Code__c, Reference_Document_Number__c FROM  celsrm__Transaction__c WHERE celsrm__Account__c = :accId And Name IN :invNo And celsrm__Amount__c != 0]; // Added Closed Date field | FIN-8525 | Changed by Asera | 14 Oct 2025 --//
            //-- Ends | FIN-8201 | Changed By Ravi | 5 Nov 2024 --//
            //-- End | FIN-5814 | Changed By Megha | 8 July 2024 --//
            List<Map<Object, Object>> transactionList = new List<Map<Object, Object>>();
            for(celsrm__Transaction__c trans: transactions) {
                Map<Object, Object> transMap = new Map<Object, Object>();
                transMap.put('Id', trans.Id);
                transMap.put('celsrm__Balance__c', trans.celsrm__Balance__c);
                //-- Start | FIN-5815 | Changed By Megha | 8 July 2024 --//
                transMap.put('celsrm__Amount__c', trans.celsrm__Amount__c);
                //-- End | FIN-5815 | Changed By Megha | 8 July 2024 --//
                //-- Start | FIN-8530 | Changed by Ravi | 10 Nov 2025 --//
                transMap.put('celsrm__Account__c', trans.celsrm__Account__c);
                //-- End | FIN-8530 | Changed by Ravi | 10 Nov 2025 --//
                transMap.put('Name', trans.Name);
                transMap.put('NameSort', trans.Name);
                //-- Start | FIN-8201 | Changed By Ravi | 5 Nov 2024 --//
                // << CHANGE - MM - FIN-9798 - celsrm__Create_Date__c -> Invoice_Date_NF__c >>
                transMap.put('celsrm__Create_Date__c', trans.Invoice_Date_NF__c);
                //-- End | FIN-8201 | Changed By Ravi | 5 Nov 2024 --//
                //-- Start | FIN-5814 | Changed By Megha | 8 July 2024 --//
                transMap.put('CurrencyIsoCode', trans.CurrencyIsoCode);
                //-- End | FIN-5814 | Changed By Megha | 8 July 2024 --//
                // << START - MM - FIN-9536 - Add Sender_Document_Number__c (Invoice#) in table & email>>
                transMap.put('Sender_Document_Number__c', trans.Sender_Document_Number__c);
                // << END - MM - FIN-9536 - Add Sender_Document_Number__c (Invoice#) in table & email>>
                // << START - MM - FIN-9931 - Dispute → Preview → Reference_Document_Number__c value not populated>>
                transMap.put('Reference_Document_Number__c', trans.Reference_Document_Number__c);
                // << END - MM - FIN-9931 - Dispute → Preview → Reference_Document_Number__c value not populated>>
                // << START - MM - FIN-9798 - Added Due_Date_2__c, Country_Code__c >>
                transMap.put('Due_Date_2__c', trans.Due_Date_2__c);
                transMap.put('Country_Code__c', trans.Country_Code__c);
                // << END - MM - FIN-9798 - Added Due_Date_2__c, Country_Code__c >>
                transactionList.add(transMap);
                //-- Start | FIN-8525 | Changed by Asera | 14 Oct 2025 --//
                if (trans.celsrm__Close_Date__c != null) {
                    closedInvoiceNumberList.add(trans.Name);
                }
                //-- End | FIN-8525 | Changed by Asera | 14 Oct 2025 --//

            }
            inMap.put('TransactionList', transactionList);
            //-- Start | FIN-8525 | Changed by Asera | 14 Oct 2025 --//
            if(closedInvoiceNumberList.size() > 0) {
                String closedInvoiceNumbers = String.join(closedInvoiceNumberList, ', ');
                ggErrorMessage = String.format(Label.You_cannot_create_dispute_on_closed_invoice , new List<String>{closedInvoiceNumbers});
            }
            if(ggErrorMessage != '') {
                inMap.put('ggErrorMessage', ggErrorMessage);
            }
            //-- End | FIN-8525 | Changed by Asera | 14 Oct 2025 --//
        }
        //-- Starts |FIN-7502| Changed by Asera | 25 Nov 2025 --//
        try {
            Map<String, Object> metadataMap = new Map<String, Object>{
                'TransactionList' => inMap.get('TransactionList'),
                'EmailMsgId' => String.valueOf(activityData.get('Id')),
                'timestamp' => String.valueOf(Datetime.now())
            };
        
            String metadataJson = JSON.serialize(metadataMap);
        
            Map<String, Object> inputParams = new Map<String, Object>{
                'userId' => UserInfo.getUserId(),
                'pageScreenName' => 'Email: Create Dispute',
                'actionPerformed' => false,
                'actionTakenTime' => null,
                'accountId' => accId,
                'transactionId' => null,
                'disputeId' => null,
                'additionalMetadata' => metadataJson
            };
        
            Id activityId = celsrm.SRMUtilityController.logActivity(JSON.serialize(inputParams));
            inMap.put('activityLogId', activityId);
        } catch (Exception e) {
            System.debug('Error logging activity: ' + e.getMessage());
            inMap.put('logActivityError', e.getMessage());
        }   
        //-- End |FIN-7502| Changed by Asera | 25 Nov 2025 --//     
        inMap.put('createMultipleDispute', true);
        return inMap;
    }

    //-- This method will cancel the selected disputes --//
    public static Map<Object, Object> updateReverseDispute(Map<Object, Object> inMap) {
        Savepoint sp = Database.setSavepoint();
        try {
            if(inMap.get('DisputeList') != null) {
                //-- Start | FIN-5812 - 3 | Changed by Asera  -- (Chanegs reagrding added action on account and transaction//
                Set<String> accountIDs = new Set<String>();
                Set<String> trxnIDs = new Set<String>();
                List<String> disIds = new List<String>();
                List<Object> listDispute = (List<Object>)inMap.get('DisputeList');
                if(listDispute != null && !listDispute.isEmpty()){
                    List<celsrm__Dispute__c> listDisputeRecords = new List<celsrm__Dispute__c>();
                    List<celsrm__Transaction__c> listTransactionRecords = new List<celsrm__Transaction__c>();
                    for (Object disp : listDispute) {
                        Map<Object,Object> tempMap = (Map<Object,Object>)disp;
                        if(Boolean.valueOf(tempMap.get('isSelected'))){
                            // update dispute information
                            celsrm__Dispute__c tempDispute = new celsrm__Dispute__c();
                            tempDispute.Id = String.valueOf(tempMap.get('Id'));
                            // << START - MM - FIN-8420 - Assigne Status based on Notify>>
                            // tempDispute.celsrm__Status__c = 'Cancelled';
                            tempDispute.celsrm__Status__c = '80 Voided';
                            // << END - MM - FIN-8420 - Assigne Status based on Notify>>
                            tempDispute.celsrm__Close_Date__c = Date.Today();
                            tempDispute.celsrm__Latest_Note_Date__c = date.today();
                            tempDispute.celsrm__Latest_Note_Entered_By__c = UserInfo.getUserId();
                            tempDispute.celsrm__Latest_Note__c =  inMap.get('noteBody') != null && inMap.get('noteBody') != '' ? String.valueOf(inMap.get('noteBody')) : null;
                            listDisputeRecords.add(tempDispute);
                            disIds.add(tempDispute.Id);

                            celsrm__Transaction__c trnx = new celsrm__Transaction__c();
                            trnx.Id = String.valueOf(tempMap.get('invoiceId'));
                            accountIDs.add(String.valueOf(tempMap.get('AccountId')));
                            trnx.celsrm__Disputed_Amount__c = 0;
                            listTransactionRecords.add(trnx);
                            trxnIDs.add(trnx.Id);
                        }
                    }
                    if(listDisputeRecords != null && !listDisputeRecords.isEmpty()){
                        update listDisputeRecords;
                        //update listTransactionRecords;
                        //  update dispute workflow detail information
                        //-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
                        List<celsrm__Dispute_Workflow_Details__c> dwdList = [SELECT Id, celsrm__Workflow_Level__c, celsrm__Workflow_User_Type__c  FROM celsrm__Dispute_Workflow_Details__c WHERE celsrm__Dispute__c IN :disIds AND celsrm__Status__c = 'Pending'];
                        if(dwdList != null && dwdList.size() > 0) {
                          for(celsrm__Dispute_Workflow_Details__c dwdUpdObj: dwdList){
                            dwdUpdObj.celsrm__Status__c = 'Auto Completed';
                            dwdUpdObj.celsrm__User_Action__c = 'Dispute Reversed';
                            dwdUpdObj.celsrm__Action_Date__c = Date.today();
                            dwdUpdObj.celsrm__Action_Taken_By__c = UserInfo.getUserId();
                          }
                          update dwdList;
                        }
                        //-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
                    }
                    //-- Start | FIN-8530 | Changed by Ravi | 10 Nov 2025 --//
                    String accountId = (String) inMap.get('Id');
                    if(!accountIDs.contains(accountId) && accountId.startsWithIgnoreCase('001')){
                        accountIDs.add(accountId);
                    }
                    //-- End | FIN-8530 | Changed by Ravi | 10 Nov 2025 --//
                    Datetime currentDateTime = Datetime.now();
                    if(!disIds.isEmpty()){
                        celsrm.SRMUtilityController.insertActivity(disIds, 'celsrm__Dispute__c', 'Dispute Reversed', 100, inMap.get('noteBody') != null && inMap.get('noteBody') != '' ? String.valueOf(inMap.get('noteBody')) : null, UserInfo.getUserId(), null, 'Internal');
                    }
                    if(!accountIDs.isEmpty()){
                        celsrm.SRMUtilityController.insertActivity(new List<String>(accountIDs), 'celsrm__Account__c', 'Dispute Reversed', currentDateTime, 100, inMap.get('noteBody') != null && inMap.get('noteBody') != '' ? String.valueOf(inMap.get('noteBody')) : null, UserInfo.getUserId(), null, 'Internal');
                    }
                    if(!trxnIDs.isEmpty()){
                        celsrm.SRMUtilityController.insertActivity(new List<String>(trxnIDs), 'celsrm__Transaction__c', 'Dispute Reversed', currentDateTime, 100, inMap.get('noteBody') != null && inMap.get('noteBody') != '' ? String.valueOf(inMap.get('noteBody')) : null, UserInfo.getUserId(), null, 'Internal');
                    }
                    //-- Starts |FIN-7502| Changed by Asera | 25 Nov 2025 --//
                    try {
                        Map<String, Object> metadataMap = new Map<String, Object>{
                                    'DisputeIds' => disIds,
                                    'accountIDs' => accountIDs,
                                    'trxnIDs' => trxnIDs,
                                    'listDispute' => listDispute
                                };
                        Map<String, Object> metadataMapJson = new Map<String, Object>{
                            'DisputeObj' => metadataMap,
                            'timestamp' => String.valueOf(Datetime.now())
                        };
                        Id activityId = (Id) inMap.get('activityLogIdFromScreen');
                        // Convert to JSON string
                        String metadataJson = JSON.serialize(metadataMapJson);
                        celsrm.SRMUtilityController.updateActivity(activityId, metadataJson);
                        
                        System.debug('Activity logged with Id: ' + activityId);
                    } catch (Exception e) {
                        System.debug('Failed to log activity: ' + e.getMessage());
                    }
                    //-- End |FIN-7502| Changed by Asera | 25 Nov 2025 --//
                     //-- End | FIN-5812 - 3 | Changed by Asera  --//

                }
            }
        } catch(Exception ex) {
            // An error occurred, so roll back to the savepoint
            Database.rollback(sp);

            // Optionally, log or handle the exception
            System.debug('Error: ' + ex.getMessage());
            inMap.put('ggErrorMessage', 'There has been some error while reversing the dispute. Please contact system admin. Error:' + ex.getStackTraceString());
        }
        Map<String, Object> refreshParentValues = new Map<String, Object>();
        refreshParentValues.put('name', 'ListView');
        refreshParentValues.put('value',inMap.get('ListView'));
        refreshParentValues.put('onChangeMethod','filterDataByView');
        inMap.put('refreshParentValues', refreshParentValues);
        return inMap;
    }

    public static Map<Object, Object> reverseDisputeFromDisputeDetail(Map<Object, Object> inMap) {
        Savepoint sp = Database.setSavepoint();
        try {
            String disputeId =  String.valueOf(inMap.get('Id'));
            celsrm__Dispute__c disputeRecord = new celsrm__Dispute__c();
            disputeRecord.Id = disputeId;
            // << START - MM - FIN-8420 - Assigne Status based on Notify>>
            // disputeRecord.celsrm__Status__c = 'Cancelled';
            disputeRecord.celsrm__Status__c = '80 Voided';
            // << END - MM - FIN-8420 - Assigne Status based on Notify>>
            disputeRecord.celsrm__Close_Date__c = Date.Today();
            disputeRecord.celsrm__Latest_Note_Date__c = date.today();
            disputeRecord.celsrm__Latest_Note_Entered_By__c = UserInfo.getUserId();
            disputeRecord.celsrm__Latest_Note__c =  inMap.get('noteBody') != null && inMap.get('noteBody') != '' ? String.valueOf(inMap.get('noteBody')) : null;
            update disputeRecord;

            celsrm__Transaction__c trnx = new celsrm__Transaction__c();
            trnx.Id = String.valueOf(((Map<Object, Object>)inMap.get('invoiceNumber')).get('id'));
            trnx.celsrm__Disputed_Amount__c = 0;
            update trnx;
            //-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
            List<celsrm__Dispute_Workflow_Details__c> dwdList = [SELECT Id, celsrm__Workflow_Level__c, celsrm__Workflow_User_Type__c FROM celsrm__Dispute_Workflow_Details__c WHERE celsrm__Dispute__c = :disputeId AND celsrm__Status__c = 'Pending'];
            if(dwdList != null && dwdList.size() > 0) {
                for(celsrm__Dispute_Workflow_Details__c dwdUpdObj: dwdList){
                    dwdUpdObj.celsrm__Status__c = 'Auto Completed';
                    dwdUpdObj.celsrm__User_Action__c = 'Dispute Reversed';
                    dwdUpdObj.celsrm__Action_Date__c = Date.today();
                    dwdUpdObj.celsrm__Action_Taken_By__c = UserInfo.getUserId();
                }
                update dwdList;
            }
            //-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//

            celsrm.SRMUtilityController.insertActivity(new List<String>{disputeId}, 'celsrm__Dispute__c', 'Dispute Reversed', 100, inMap.get('noteBody') != null && inMap.get('noteBody') != '' ? String.valueOf(inMap.get('noteBody')) : null, UserInfo.getUserId(), null, 'Internal');
             //-- Start |FIN-5812 - 3| Changed By Asera | 9 July 2024 --//
            if(inMap.containsKey('customerName')){
                String AccountId =  String.valueOf(((Map<Object, Object>)inMap.get('customerName')).get('id'));
                celsrm.SRMUtilityController.insertActivity(new List<String>{AccountId}, 'celsrm__Account__c', 'Dispute Reversed', 100, inMap.get('noteBody') != null && inMap.get('noteBody') != '' ? String.valueOf(inMap.get('noteBody')) : null, UserInfo.getUserId(), null, 'Internal');
            }
            if(inMap.containsKey('invoiceNumber')){
                String invoiceId =  String.valueOf(((Map<Object, Object>)inMap.get('invoiceNumber')).get('id'));
                celsrm.SRMUtilityController.insertActivity(new List<String>{invoiceId}, 'celsrm__Transaction__c', 'Dispute Reversed', 100, inMap.get('noteBody') != null && inMap.get('noteBody') != '' ? String.valueOf(inMap.get('noteBody')) : null, UserInfo.getUserId(), null, 'Internal');
            }
            //-- Starts |FIN-7502| Changed by Asera | 25 Nov 2025 --//
            system.debug('from reverseDispute check>>' + JSON.serialize(inMap));
            if (String.valueOf(inMap.get('fromDisputeDetails')) == 'true') {
                try {
                    System.debug('Logging from Dispute Details...');
            
                    Map<String, Object> inputParams = new Map<String, Object>{
                        'disputeNumber'   => inMap.get('disputeNumber'),
                        'InvoiceNumber'   => JSON.serialize(inMap.get('invoiceNumber')),
                        'disputeResolver' => JSON.serialize(inMap.get('disputeResolver')),
                        'customerName'    => JSON.serialize(inMap.get('customerName')),
                        'invoiceAmount'   => inMap.get('invoiceAmount'),
                        'reasonCode'      => inMap.get('reasonCode'),
                        'disputeAmount'   => inMap.get('disputeAmount'),
                        'disputeType'     => inMap.get('disputeType')
                    };
            
                    System.debug('Dispute Input Params: ' + JSON.serialize(inputParams));
            
                    Map<String, Object> metadataMap = new Map<String, Object>{
                        'reverseDisputeObj' => inputParams,
                        'timestamp'         => String.valueOf(Datetime.now())
                    };
            
                    Id activityId = (Id) inMap.get('activityLogIdFromScreen');
                    System.debug('Activity Id (fromDisputeDetails): ' + activityId);
            
                    if (activityId == null) {
                        System.debug('Warning: activityLogIdFromScreen is null');
                    }
            
                    String metadataJson = JSON.serialize(metadataMap);
                    System.debug('Serialized Metadata: ' + metadataJson);
            
                    celsrm.SRMUtilityController.updateActivity(activityId, metadataJson);
                    System.debug('Activity updated with Id: ' + activityId);
            
                } catch (Exception e) {
                    System.debug('Exception occurred in fromDisputeDetails block: ' + e.getMessage() + ' at line ' + e.getLineNumber());
                }
            } else {
                try {
                    System.debug('Logging from default reverse dispute path...');
            
                    // Safely get Invoice ID
                    String invoiceId;
                    if (inMap.containsKey('invoiceNumber')) {
                        Map<Object, Object> invoiceMap = (Map<Object, Object>) inMap.get('invoiceNumber');
                        invoiceId = String.valueOf(invoiceMap.get('id'));
                    }
            
                    // Safely get Account ID
                    String accountId;
                    if (inMap.containsKey('customerName')) {
                        Map<Object, Object> customerMap = (Map<Object, Object>) inMap.get('customerName');
                        accountId = String.valueOf(customerMap.get('id'));
                    }
            
                    System.debug('Extracted Invoice ID: ' + invoiceId);
                    System.debug('Extracted Account ID: ' + accountId);
            
                    Map<String, Object> metadataMap = new Map<String, Object>{
                        'InvoiceNumber' => invoiceId
                    };
            
                    String metadataJson = JSON.serialize(metadataMap);
            
                    Map<String, Object> inputParams = new Map<String, Object>{
                        'userId'            => UserInfo.getUserId(),
                        'pageScreenName'    => 'Account: Reverse Dispute',
                        'actionPerformed'   => false,
                        'actionTakenTime'   => null,
                        'accountId'         => accountId,
                        'transactionId'     => null,
                        'disputeId'         => String.valueOf(inMap.get('Id')),
                        'additionalMetadata'=> metadataJson
                    };
            
                    System.debug('Prepared JSON inputParams: ' + JSON.serialize(inputParams));
            
                    Id activityId = celsrm.SRMUtilityController.logActivity(JSON.serialize(inputParams));
                    System.debug('Activity created with Id: ' + activityId);
            
                    inMap.put('activityLogId', activityId);
            
                } catch (Exception e) {
                    System.debug('Exception in reverse dispute fallback: ' + e.getMessage() + ' at line ' + e.getLineNumber());
                    inMap.put('ggErrorMessage', e.getMessage() + ' at line ' + e.getLineNumber());
                }
            }
            //-- End |FIN-7502| Changed by Asera | 25 Nov 2025 --//
            
            //-- End |FIN-5812 - 3| Changed By Asera | 9 July 2024 --//
            
        } catch(Exception ex) {
            // An error occurred, so roll back to the savepoint
            Database.rollback(sp);

            // Optionally, log or handle the exception
            System.debug('Error: ' + ex.getMessage());
            inMap.put('ggErrorMessage', 'There has been some error while reversing the dispute. Please contact system admin. Error:' + ex.getStackTraceString());
        }
        return inMap;
    }
    //-- This method will fetch open disputes for the selected transactions --//
    public static Map<Object, Object> fetchOpenDisputesForTransaction(Map<Object, Object> inMap) {
        List<Object> listTransaction = (List<Object>)inMap.get('TransactionList');
        List<String> listTranIds = new List<String>();
        for (Object tran : listTransaction) {
            Map<Object,Object> tempMap = (Map<Object,Object>)tran;
            String id = String.valueOf(tempMap.get('Id'));
            listTranIds.add(id);
        }

        System.debug('listTranIds : ' + listTranIds);
        celsrm__Dispute_Configuration__c disputeConfig = celsrm__Dispute_Configuration__c.getOrgDefaults();
        List<String> disputeClosureStatusList = new List<String>();
        if(disputeConfig.celsrm__Dispute_Closure_Status__c != null && disputeConfig.celsrm__Dispute_Closure_Status__c != '') {
            for (String disClosureStatus : disputeConfig.celsrm__Dispute_Closure_Status__c.split(',')) {
                disputeClosureStatusList.add(disClosureStatus.trim());
            }
        } else {
            disputeClosureStatusList = new List<String>{'Approved', 'Rejected', 'Auto Closed', 'Cancelled'};
        }
        //-- Start | FIN-9672 | Changed by Ravi | 05 May 2026 --//
        //-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
        List<celsrm__Dispute__c> listDisputeRecords = [SELECT id,name,celsrm__Balance__c,celsrm__Account__r.Id,celsrm__Account__r.name,celsrm__Account__r.accountnumber,
                                                        createddate,celsrm__Transaction__c, celsrm__Transaction__r.name,celsrm__Latest_Note_Date__c,
                                                        celsrm__Dispute_Type__c, celsrm__Reason_Code__c, celsrm__Amount__c, celsrm__Dispute_Resolver__c,
                                                        celsrm__Dispute_Resolver__r.name, celsrm__Resolver_User_Master__c, celsrm__Resolver_User_Master__r.Name,
                                                        celsrm__Resolver_User_Master__r.celsrm__Email__c, celsrm__Resolver_User_Master__r.celsrm__Is_External_User__c, External_Resolver_Email__c,
                                                        celsrm__Status__c
                                                        FROM celsrm__Dispute__c WHERE celsrm__Transaction__c in :listTranIds AND celsrm__Status__c NOT IN:disputeClosureStatusList AND celsrm__Balance__c != 0];
       
        //-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//                                                 //-- End | FIN-9672 | Changed by Ravi | 05 May 2026 --//
        System.debug(listDisputeRecords);

        List<map<Object,Object>> dispList = new List<map<Object,Object>>();

        if(listDisputeRecords != null && !listDisputeRecords.isEmpty()){
            for(celsrm__Dispute__c disp : listDisputeRecords){
                map<Object,Object> tempbs =  new map<Object,Object>();
                String tempPay = '<a href="' + '/'+ disp.Id + '" target="_blank">' + disp.name + '</a>';
                tempbs.put('isSelected', true);
                tempbs.put('Name', tempPay);
                tempbs.put('NameSort', disp.name);
                tempbs.put('celsrm__Balance__c', disp.celsrm__Balance__c);
                tempbs.put('Id', disp.Id);
                tempbs.put('AccountId',disp.getSobject('celsrm__Account__r').get('Id'));
                tempbs.put('AccountName', disp.getSobject('celsrm__Account__r').get('name'));
                tempbs.put('AccountNumber', disp.getSobject('celsrm__Account__r').get('accountnumber'));
                tempbs.put('CreatedDate', disp.createddate);
                tempbs.put('invoiceId', disp.celsrm__Transaction__c);
                // tempbs.put('InvoiceNumber', disp.getSobject('celsrm__Transaction__r').get('name'));
                tempbs.put('InvoiceNumber', '<a href="' + '/'+ disp.celsrm__Transaction__c + '" target="_blank">' + disp.getSobject('celsrm__Transaction__r').get('name') + '</a>'); 
                tempbs.put('notes', disp.celsrm__Latest_Note_Date__c);
                tempbs.put('disputeType', disp.celsrm__Dispute_Type__c);
                tempbs.put('reasonCode', disp.celsrm__Reason_Code__c);
                tempbs.put('amount', disp.celsrm__Amount__c);
                //-- Start | FIN-9672 | Changed by Ravi | 05 May 2026 --//
                DisputeUserMasterService.ResolvedUserInfo resolvedResolver = DisputeUserMasterService.resolveFromDisputeRecord(disp);
                if(resolvedResolver != null) {
                    if(resolvedResolver.isExternal()){
                        tempbs.put('disputeResolver', !String.isBlank(resolvedResolver.name) ? resolvedResolver.name : resolvedResolver.email);
                    } else if(resolvedResolver.userId != null){
                        tempbs.put('disputeResolver', '<a href="' + '/'+ resolvedResolver.userId + '" target="_blank">' + resolvedResolver.name + '</a>');
                    }
                //-- End | FIN-9672 | Changed by Ravi | 05 May 2026 --//
                }
                tempbs.put('status', disp.celsrm__Status__c);

                dispList.add(tempbs);
            }
        }
        System.debug(dispList);
        inMap.put('dataServiceResponse', dispList);
        return inMap;
    }

    //-- Start | FIN-5808 | Changed by Asera | 10 July 2024 --//
    public static Map<Object, Object> previewCreateDisputeEmail(Map<Object, Object> inMap) {
        try {
            List < object > tran = (List < object > ) inMap.get('TransactionList');
            System.debug('TransactionList>>' + tran);
            map < string, object > tempComposeEmail = (map < string, object > ) JSON.deserializeUntyped(JSON.serialize(inMap.get('ComposeEmail')));
            system.debug('tempComposeEmail>>' + tempComposeEmail);
            String htmlBody;
            String Fields = (String) inMap.get('SummaryFields');
            List < String > FieldsAPIlst = Fields.split(',');
            List < String > fieldType = new List < String > {};
            String innerHtml = '';
            //-- Starts | FIN-8280| Changed by Asera | 17 April 2026 --//
            // Schema.Sobjecttype objType = Dispute__c.getSObjectType();
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
            fieldType = celsrm.SRMUtilityController.getTransactionFieldTranslatedLabel(accountLanguageCode, 'celsrm__Dispute__c', FieldsAPIlst);
            //-- FIN-9739 | Changed by Dilshad | 06-May-2026 | End --//
            //-- End | FIN-8280| Changed by Asera | 17 April 2026 --//
            System.debug('fieldType>>>' + fieldType);
            System.debug('FieldsAPIlst>>>>' + FieldsAPIlst);
            //-- Start | FIN-8510 | Changed by Ravi | 10 Oct 2025 --//
            Map<String, Double> totalDisputeAmount = new Map<String, Double>();
            //-- Ends | FIN-8510 | Changed by Ravi | 10 Oct 2025 --//
            //-- Start | FIN-8048 | Changed by Ravi | 29 July 2025 --//
            innerHtml = '<table width="100%" class="billing" style="border-collapse:collapse;padding:0px;font-family:verdana;">';
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
            for (Object dtx: tran) {
                Map<Object,Object> tempMap = (Map<Object,Object>)dtx;
                System.debug('tempMap>>>' + tempMap);
                innerHtml += '<tr>';
                for (String fieldName: FieldsAPIlst) {
                        if (fieldName == 'celsrm__Amount__c') {
                            fieldName = 'disputeAmount';
                        }
                        if (fieldName == 'celsrm__Dispute_Type__c') {
                            fieldName = 'disputeType';
                        } 
                        if (fieldName == 'celsrm__Created_Date__c'){
                            fieldName = 'celsrm__Create_Date__c';
                        }
                        if (fieldName == 'celsrm__Transaction__c'){
                            fieldvalue = tempMap.get('Name');
                        } else if(fieldName == 'Name'){
                            fieldvalue = '****';
                        } 
                        // << START - MM - FIN-9931 - Dispute → Preview → Values are not comma saperated >>
                        else if(fieldName == 'disputeAmount'){
                            if(tempMap.get(fieldName) != null) {
                                Decimal val = (Decimal)tempMap.get(fieldName);
                                fieldvalue = val.format();
                            } else {
                                fieldvalue = null;
                            }
                        }
                        // << END - MM - FIN-9931 - Dispute → Preview → Values are not comma saperated >> 
                        else {
                            fieldvalue = tempMap.get(fieldName);
                        }
                        if (fieldvalue == null) {
                            fieldvalue = '';
                        }
                    //-- Start | FIN-8048 | Changed by Ravi | 29 July 2025 --//
                    innerHtml += '<td width="auto" style="text-align:left;border:solid 1px gray;white-space:nowrap;">' + fieldvalue + '</td>';
                    //-- End | FIN-8048 | Changed by Ravi | 29 July 2025 --//
                }
                innerHtml += '</tr>';
                double newAmt =  tempMap.get('disputeAmount') == null ? 0 : (Decimal)tempMap.get('disputeAmount');
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
                PromiseToPayActionController.createMapCurBalance(CurrencyIsoCode, newAmt, totalDisputeAmount);
                // totalDisputeAmount = totalDisputeAmount + newAmt;
                //-- Ends | FIN-8510 | Changed by Ravi | 10 Oct 2025 --//
                
            }
            innerHtml += '<tr>';
            //-- Start | FIN-8510 | Changed by Ravi | 10 Oct 2025 --//
            String TotalBal = PromiseToPayActionController.strTotalBalanceSummary(totalDisputeAmount);
            //-- Ends | FIN-8510 | Changed by Ravi | 10 Oct 2025 --//
            //-- Start | FIN-8048 | Changed by Ravi | 29 July 2025 --//
            innerHtml += '<td colspan=' + FieldsAPIlst.size() + ' style="text-align:right;width:auto;border:solid 1px gray;white-space:nowrap;"> <b> Total</b>  ' + TotalBal + '</td>';
            //-- End | FIN-8048 | Changed by Ravi | 29 July 2025 --//
            innerHtml += '</tr>';
            innerHtml += '</table>';
            if (tempComposeEmail.containsKey('body') && tempComposeEmail.get('body') != null) {
                htmlBody = String.valueOf(tempComposeEmail.get('body'));
                if (htmlBody.contains('{Disputes.summary}') ) {
                    htmlBody = htmlBody.replace('{Disputes.summary}', innerHtml);
                }
            }
            system.debug('htmlBody>>' + innerHtml);
            inMap.put('DisputeEmailPreview', htmlBody);
            inMap.put('success', true);
        } catch(Exception ex){
            System.debug('Method: previewCreateDisputeEmail | Linenumber: ' + ex.getLineNumber() + ' | Message: ' + ex.getMessage());
        }
        return inMap;
    }
    //-- End | FIN-5808 | Changed by Asera | 10 July 2024 --//

    //-- Starts | FIN-7859 | Changed by Ravi | 24-Jul-2025 --//
    public static PicklistOptions getPicklistOptions(String objectName, String dependentField, String controllingField, string recordTypeId) {
        PicklistOptions picklistOptionsWrapper = new PicklistOptions();
        Map<String, Object> mapStringoptionsBasedOnRecordType = new Map<String, Object>();

        try {
            List<Map<string,object>> returnOptions = new List<Map<string,object>>();
            Schema.SObjectType objType = Schema.getGlobalDescribe().get(objectName);
            if(objType != null) {
                Schema.DescribeSObjectResult describeResult = objType.getDescribe();
                List<Schema.PicklistEntry> controllingValues;
                Map<String, Schema.SObjectField> fMap = describeResult.fields.getMap();
                if(fMap.get(dependentField).getDescribe().getController() != null){
                    controllingField = String.valueOf(fMap.get(dependentField).getDescribe().getController());
                    picklistOptionsWrapper.controllingField = controllingField;
                }
                if (controllingField != null && controllingField != '') {
                    if (fMap.get(controllingField) != null) {
                        controllingValues = new List<Schema.PicklistEntry>();
                        controllingValues = fMap.get(controllingField).getDescribe().getPicklistValues();

                        if( recordTypeId != null && recordTypeId != '' ){
                            List<Object> optionsBasedOnRecordType = new List<Object>();
                            String endPoint = URL.getOrgDomainUrl().toExternalForm() + '/services/data/v45.0/ui-api/object-info/'+objectName+'/picklist-values/'+recordTypeId+'/'+dependentField;
                            Map<String, String> header = new Map<String, String>();
                            header.put('Content-Type','application/json; charset=UTF-8');
                            header.put('Authorization','Bearer ' + getSessionIdFromVFPage());
                            header.put('Accept','application/json');
                            celsrm.GOGHTTPRequestMapper httpRequest = new celsrm.GOGHTTPRequestMapper(null, null, null, endpoint, header, 'GET', null);
                            Map<String, Object> response = httpRequest.send();
                            if((Boolean)response.get('success')) {
                                Map<String,Object> responseMap = (Map<String,Object>) JSON.deserializeUntyped(String.valueOf(response.get('response')));
                                if( responseMap.containsKey('values') && responseMap.get('values') != null ){
                                    optionsBasedOnRecordType = ((List<Object>) responseMap.get('values'));
                                }
                                
                                for(Integer i = 0 ; i < optionsBasedOnRecordType.size(); i++){
                                    Map<String,Object> tempMap = new Map<String, Object>();
                                    tempMap = (Map<String,Object>) optionsBasedOnRecordType.get(i);
                                    mapStringoptionsBasedOnRecordType.put(String.valueOf(tempMap.get('value')),optionsBasedOnRecordType.get(i));
                                }
                            }
                        
                        }

                    } else {
                        picklistOptionsWrapper.errorMessage = controllingField + ' '+Label.celsrm.GOG_Field_Does_Not_Exist+' '+ objectName;
                        return picklistOptionsWrapper;
                    }
                }
                if (fMap.get(dependentField) != null) {
                    List<Schema.PicklistEntry> dependentValues = fMap.get(dependentField).getDescribe().getPicklistValues();
                    if(mapStringoptionsBasedOnRecordType != null && mapStringoptionsBasedOnRecordType.size() > 0){
                        for(Integer i = (dependentValues.size()-1); i >= 0  ; i--){
                            if( !mapStringoptionsBasedOnRecordType.containsKey(dependentValues.get(i).getValue()) ){
                                dependentValues.remove(i);
                            }
                        }
                    }
                    String defaultValue = '';
                    for(Schema.PicklistEntry currDependentValue : dependentValues) {
                        if(currDependentValue.getLabel() == '*' || currDependentValue.getValue() == '*'){
                            continue;
                        }
                        Map<String, object> option = new Map<String, object>();
                        option.put('label', currDependentValue.getLabel());
                        option.put('value', currDependentValue.getValue());
                        option.put('controllingValues',new List<String>());
                        //-- Starts | Issue #401 | 04-12-2019 | Changes by: Dilshad Shaikh --//
                        if(currDependentValue.isDefaultValue()){
                            option.put('default',true);
                            defaultValue = currDependentValue.getValue();
                        }
                        //-- Ends | Issue #401 | 04-12-2019 | Changes by: Dilshad Shaikh --//
                        
                        if (controllingValues != null) {
                            String jsonString = JSON.serialize(currDependentValue);
                            MyPickListInfo info = (MyPickListInfo) JSON.deserialize(jsonString, MyPickListInfo.class);
                            if(info.validFor != null) {
                                String hexString = EncodingUtil.convertToHex(EncodingUtil.base64Decode(info.validFor)).toUpperCase();
                                
                                Integer baseCount = 0;
                                for(Integer curr : hexString.getChars()) {
                                    Integer val = 0;

                                    if(curr >= 65) {
                                        val = curr - 65 + 10;
                                    } else {
                                        val = curr - 48;
                                    }

                                    if((val & 8) == 8) {
                                        List<String> opt = (List<String>) option.get('controllingValues');
                                        opt.add((controllingValues[baseCount + 0].getValue()));
                                    }
                                    if((val & 4) == 4) {
                                        List<String> opt = (List<String>) option.get('controllingValues');
                                        opt.add((controllingValues[baseCount + 1].getValue()));
                                    }
                                    if((val & 2) == 2) {
                                        List<String> opt = (List<String>) option.get('controllingValues');
                                        opt.add((controllingValues[baseCount + 2].getValue()));
                                    }
                                    if((val & 1) == 1) {
                                        List<String> opt = (List<String>) option.get('controllingValues');
                                        opt.add((controllingValues[baseCount + 3].getValue()));
                                    }
                                    baseCount += 4;
                                }  
                            }
                        }
                        returnOptions.add(option);      
                    } 
                    picklistOptionsWrapper.options = returnOptions;
                    if(defaultValue != '') {
                        picklistOptionsWrapper.defaultValue = defaultValue;
                    }
                } else {
                    picklistOptionsWrapper.errorMessage = dependentField + ' '+Label.celsrm.GOG_Field_Does_Not_Exist+' '+ objectName;
                    return picklistOptionsWrapper;
                }
            } else {
                picklistOptionsWrapper.errorMessage = Label.celsrm.GOG_Object_Does_Not_Exist+' '+ objectName;
                return picklistOptionsWrapper;
            }
        } catch (Exception ex) {
            System.debug('Error:'+ex.getStackTraceString());
            picklistOptionsWrapper.errorMessage = ex.getStackTraceString();
        }
        System.debug('picklistOptionsWrapper: ' + picklistOptionsWrapper);
        return picklistOptionsWrapper;
    }
    public static String getSessionIdFromVFPage() {
        String content='';
        if(!Test.isRunningTest()){
         content = Page.celsrm__SessionIdGenerator.getContent().toString();
        }else{
           content= 'Start_Of_Session_Id'+Userinfo.getSessionID()+'End_Of_Session_Id' ;
        }
        // String content = visualforcePage.getContent().toString();;
        Integer s = content.indexOf('Start_Of_Session_Id') + 'Start_Of_Session_Id'.length();
        Integer e = content.indexOf('End_Of_Session_Id');
        return content.substring(s, e);
    }
    public class PicklistOptions {
        @AuraEnabled
        public List<Map<String, Object>> options;
        @AuraEnabled
        public String errorMessage = null; 
        @AuraEnabled
        public string controllingField;
        @AuraEnabled
        public string defaultValue;
    }
    public class MyPickListInfo {
        public String validFor;
    }
    //-- Ends | FIN-7859 | Changed by Ravi | 24-Jul-2025 --//

    // << START - MM - FIN-8174 - Dynamic translated headers based account local | on Change Account Locale on Create Dispute Screen>>
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
    // << END - MM - FIN-8174 - Dynamic translated headers based account local | on Change Account Locale on Create Dispute Screen>>
}