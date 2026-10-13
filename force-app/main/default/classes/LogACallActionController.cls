global with sharing class LogACallActionController implements celsrm.GOGIScreenCustomLogic {
    global Map<Object, Object> invoke(String functionName, Map<Object, Object> inMap) {
        if(functionName == 'onLoadLogACall') {
            fetchCallScript(inMap);
            fetchDefaultContact(inMap);
        } else if (functionName == 'executeLogACall') {
            inMap = executeLogACall(inMap);
        }
        return inMap;
    }

    public static Map<Object, Object> executeLogACall(Map<Object, Object> inMap) {

        if(inMap.containsKey('calledFromTransactionDetailScreen') && Boolean.valueOf(inMap.get('calledFromTransactionDetailScreen')) == true) { 
            List<Object> tranList = new List<Object>();
            Map<Object, Object> transMap = new Map<Object, Object>();
            transMap.put('Id',inMap.get('Id'));
            transMap.put('celsrm__Account__c', inMap.get('celsrm__Account__c'));
            tranList.add(transMap);
            inMap.put('TransactionList',tranList);
        }

        List<Object> transactionList = (List<Object>)inMap.get('TransactionList');
        List < celsrm__Transaction__c > trxListToUpdate = new List < celsrm__Transaction__c > ();
        String activityName = 'Log A Call';
        List < String > transIdList = new List < String > ();       //Make a list of Transaction Id in order to capture activities
        //-- FIN-9611 | Changed By Dilshad | 15-Apr-2026 | Start --//
        Set < String > accIdList = new Set < String > ();         //Make a list of Account Id in order to capture activities
        //-- FIN-9611 | Changed By Dilshad | 15-Apr-2026 | End --//
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
        String accountId = '';
        if(inMap.containsKey('calledFromTransactionDetailScreen') && Boolean.valueOf(inMap.get('calledFromTransactionDetailScreen')) == true) { 
            accountId = (String) inMap.get('celsrm__Account__c');
            inMap.put('refreshParentWindow', true);
        } else {
            accountId = (String) inMap.get('Id');
        }
        //-- Start | FIN-8530 | Changed by Ravi | 10 Nov 2025 --//
        if(!accIdList.contains(accountId)){
            accIdList.add(accountId);
        }
        //-- End | FIN-8530 | Changed by Ravi | 10 Nov 2025 --//
        Account accountObj = new Account();
        accountObj.Id = accountId;
        accountObj.celsrm__Last_Contact_Date__c = date.Today();
        accountObj.celsrm__Last_Contact_Method__c = activityName;
        accountObj.celsrm__Last_Contact_Type__c = 'Phone';
        update accountObj;
        //Update Account - END

        
        Boolean isFollowUp = Boolean.valueOf(inMap.get('isFollowUp'));
        // Create Follow Up Task
        if(isFollowUp == true) {
            inMap = createFollowUpTask(inMap);
        }
        //-- Starts | FIN-6130 | Changed by Dilshad | 25 Jul 2024 --//
        Datetime currentDateTime = DateTime.now();
        //Capture activities for Accounts
        //-- Starts | FIN-7138 | changed by Sejal | 11 Feb 2024 --//
        Map<String, Object> additionalFields = new Map<String, Object>();
        additionalFields.put('Phone_Type__c', String.valueOf(inMap.get('PhoneType')));
        additionalFields.put('Response_By_Contact__c', String.valueOf(inMap.get('ResponseByContact')));
        String contactName = inMap.get('ContactName') != null ? String.valueOf(inMap.get('ContactName')).split('_')[0] : null;
        additionalFields.put('Contact__c', contactName);
        String contactDetail = inMap.get('contactDetail') != null ? String.valueOf(inMap.get('contactDetail')) : null;
        additionalFields.put('Contact_Detail__c', contactDetail);
        //-- Ends | FIN-7138 | changed by Sejal | 11 Feb 2024 --//
        Map<String, String> accIdActivityIdMap = new Map<String, String>();
        if(accIdList.size() > 0) {
            //-- Starts | FIN-7138 | commented by Sejal | 11 Feb 2024 --//
            // Map<String, Object> additionalFields = new Map<String, Object>();
            // additionalFields.put('Phone_Type__c', String.valueOf(inMap.get('PhoneType')));
            // additionalFields.put('Response_By_Contact__c', String.valueOf(inMap.get('ResponseByContact')));
            // String contactName = inMap.get('ContactName') != null ? String.valueOf(inMap.get('ContactName')).split('_')[0] : null;
            // additionalFields.put('Contact__c', contactName);
            //-- Ends | FIN-7138 | commented by Sejal | 11 Feb 2024 --//
            //-- FIN-9611 | Changed By Dilshad | 15-Apr-2026 | Start --//
            List<String> accIdStrings = new List<String>();
            for (Id accId : accIdList) {
                if (accId != null) {
                    accIdStrings.add(String.valueOf(accId));
                }
            }
            accIdActivityIdMap = celsrm.SRMUtilityController.insertActivity(accIdStrings, 'celsrm__Account__c', activityName, currentDateTime, 100, String.valueOf(inMap.get('NoteBody')), UserInfo.getUserId(), null, 'Internal', additionalFields);
            //-- FIN-9611 | Changed By Dilshad | 15-Apr-2026 | End --//
        }
        //Capture activities for Transactions
        if(transIdList.size() > 0) {
            // Map<String, Object> additionalFields = new Map<String, Object>();
            for (String accId : accIdActivityIdMap.keySet()) {
                additionalFields.put('celsrm__Parent_Event__c', accIdActivityIdMap.get(accId));
            }
            //-- Starts | FIN-7138 | commented by Sejal | 11 Feb 2024 --//
            // additionalFields.put('Phone_Type__c', String.valueOf(inMap.get('PhoneType')));
            // additionalFields.put('Response_By_Contact__c', String.valueOf(inMap.get('ResponseByContact')));
            // String contactName = inMap.get('ContactName') != null ? String.valueOf(inMap.get('ContactName')).split('_')[0] : null;
            // additionalFields.put('Contact__c', contactName);
            //-- Ends | FIN-7138 | commented by Sejal | 11 Feb 2024 --//
            celsrm.SRMUtilityController.insertActivity(transIdList, 'celsrm__Transaction__c', activityName, currentDateTime, 100, String.valueOf(inMap.get('NoteBody')), UserInfo.getUserId(), null, 'Internal', additionalFields);
            
        }
        //-- Starts |FIN-7502| Changed by Asera | 25 Nov 2025 --//
        try {
            Map<String, Object> metadataMap = new Map<String, Object>{
                'LogACallObj' => JSON.serialize(additionalFields),
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
        //-- Ends | FIN-6130 | Changed by Dilshad | 25 Jul 2024 --//
        return inMap;
    }

    public static Map<Object, Object> fetchDefaultContact(Map<Object, Object> inMap) {
        String accountId = '';
        if(inMap.containsKey('calledFromTransactionDetailScreen') && Boolean.valueOf(inMap.get('calledFromTransactionDetailScreen')) == true) { 
            accountId = (ID)inMap.get('celsrm__Account__c');
        } else {
            accountId = (String)inMap.get('Id');
        }
        List<Contact> contactList= [SELECT Id, Phone, MobilePhone FROM Contact WHERE AccountId =: accountId AND celsrm__Default__c = true ORDER BY Name LIMIT 1];
        if(contactList.size() > 0) {
            Contact contactObj = contactList.get(0);
            if(contactObj.Phone != null) {
                inMap.put('ContactName', contactObj.Id + '_' + contactObj.Phone);
                //inMap.put('ContactCalled', contactObj.Phone);
                inMap.put('DialContactId', contactObj.Id);
                inMap.put('DialContact', contactObj.Phone);
            } else if(contactList.size() > 0 && contactObj.MobilePhone != null) {
                inMap.put('ContactName', contactObj.Id + '_' + contactObj.MobilePhone);
                //inMap.put('ContactCalled', contactObj.MobilePhone);
                inMap.put('DialContactId', contactObj.Id);
                inMap.put('DialContact', contactObj.MobilePhone);
            } else {
                inMap.put('ContactName', contactObj.Id + '_' + 'blank');
                //inMap.put('ContactCalled', contactObj.MobilePhone);
                inMap.put('DialContactId', contactObj.Id);
                inMap.put('DialContact', contactObj.MobilePhone);
            }
            inMap.put('contactType', 'Contact');
        } else {
            inMap.put('contactType', 'Other');
        }
        return inMap;
    }

    public static Map<Object, Object> fetchCallScript(Map<Object, Object> inMap) {
        Set<Id> trxnId = new Set<Id>();
        //-- Starts |FIN-7502| Changed by Asera | 25 Nov 2025 --//
        String screenName = 'Account';
        Id transactionId ;
        // system.debug('inmap from fetchCallScript: ' + JSON.serialize(inMap));
        //-- End |FIN-7502| Changed by Asera | 25 Nov 2025 --//
        if(inMap.containsKey('calledFromTransactionDetailScreen') && Boolean.valueOf(inMap.get('calledFromTransactionDetailScreen')) == true) { 
            //-- Starts |FIN-7502| Changed by Asera | 25 Nov 2025 --//
            screenName = 'Transaction';
            transactionId = (Id) inMap.get('Id');
            //-- End |FIN-7502| Changed by Asera | 25 Nov 2025 --//
            trxnId.add( String.valueOf(inMap.get('Id')));
        } else {
            List<Object> transObjList = ((List<Object>)inMap.get('TransactionList'));
            for (Object transObj : transObjList) {
                Map<Object, Object> transMap = (Map<Object, Object>)transObj;
                trxnId.add((ID)transMap.get('Id'));
            }
        }
        if(trxnId != null && trxnId.size() > 0) {
            
            system.debug('trxnId>>> ' +  trxnId);
            //-- Added Field celsrm_account__c |FIN-7502| Changed by Asera | 25 Nov 2025 --//
            List<celsrm__Transaction__c> trxnsData = [Select Id, Name, celsrm__Account__c,celsrm__Last_Contact_Date__c, celsrm__Due_Date__c, celsrm__Balance__c, celsrm__DPD__c, celsrm__Disputed_Amount__c, celsrm__Promised_Amount__c, celsrm__Promise_Date__c, celsrm__Is_Broken_Promise__c, (SELECT Id, Name, celsrm__Amount__c, celsrm__Status__c, celsrm__Created_Date__c, celsrm__Last_Contact_Date__c From celsrm__Disputes__r Where celsrm__Close_Date__c = null Order By CreatedDate DESC) From celsrm__Transaction__c Where Id IN :trxnId];
            //trxnsData
            system.debug('trxnsData>>> ' +  trxnsData);
            List<celsrm__Transaction__c> disputed = new List<celsrm__Transaction__c>();
            List<celsrm__Transaction__c> brokenPromised = new List<celsrm__Transaction__c>();
            List<celsrm__Transaction__c> promisedInvoice = new List<celsrm__Transaction__c>();
            List<celsrm__Transaction__c> highDPD = new List<celsrm__Transaction__c>();
            //-- Starts |FIN-7502| Changed by Asera | 25 Nov 2025 --//
            List<Id> transactionIds = new List<Id>();
            Set<Id> accountIds = new Set<Id>();
            //-- End |FIN-7502| Changed by Asera | 25 Nov 2025 --//
            for (celsrm__Transaction__c trxnData :trxnsData) {
                //-- Starts |FIN-7502| Changed by Asera | 25 Nov 2025 --//
                 // Extract Id and AccountId
                transactionIds.add(trxnData.Id);
                if (trxnData.celsrm__Account__c != null) {
                    accountIds.add(trxnData.celsrm__Account__c);
                }
                //-- End |FIN-7502| Changed by Asera | 25 Nov 2025 --//
                if(trxnData.celsrm__Disputed_Amount__c != null && trxnData.celsrm__Disputed_Amount__c != 0) {
                    disputed.add(trxnData);
                } else if(trxnData.celsrm__Promise_Date__c != null && trxnData.celsrm__Is_Broken_Promise__c != null && trxnData.celsrm__Is_Broken_Promise__c) {
                    brokenPromised.add(trxnData);
                } else if(trxnData.celsrm__Promise_Date__c != null && (trxnData.celsrm__Is_Broken_Promise__c == null || !trxnData.celsrm__Is_Broken_Promise__c)) {
                    promisedInvoice.add(trxnData);
                } else if (trxnData.celsrm__DPD__c != null && trxnData.celsrm__DPD__c > 0){
                    highDPD.add(trxnData);
                }
            }
            String script = 'Hello Customer<br /><br />';
            script += 'Greetings! Hope you are doing well. I’m calling you to share information about some of the outstanding invoice that are yet to be paid.<br /><br />';
            
            Boolean p2p= false;
            Boolean disp = false;
            String actionTriggered = ''; //|FIN-7502| Changed by Asera | 25 Nov 2025 --//
            //for oldest DPD
            
            //for promise invoice(without broken)
            if(promisedInvoice.size() > 0) {
                p2p = true;
                actionTriggered = 'Promise'; //|FIN-7502| Changed by Asera | 25 Nov 2025 --//
                if(promisedInvoice.size() <= 3) {
                    script += '<h3><b>Promised Invoice</b></h3>Reminder : You have promised to pay for following Invoice(s)';
                    script += '<ul>';
                    for (celsrm__Transaction__c trxnData : promisedInvoice) {
                        script += '<li>';
                        script += 'Invoice <b>' + trxnData.Name + '</b> by <b>' + trxnData.celsrm__Promise_Date__c.format() + '</b> ';
                        script += '</li>';
                    }
                    script += '</ul>';
                } else {
                    script += 'Since there are multiple records in the system, I’ll share details of Invoices involving “promise” scenario, over an email for your easy reference and action. Thank you for your Time.<br />';
                }
            }
            //for broken promise invoice
            if(brokenPromised.size() > 0) {
                p2p = true;
                actionTriggered = 'Broken Promise'; //|FIN-7502| Changed by Asera | 25 Nov 2025 --//
                if(brokenPromised.size() <= 3) {
                    script += '<h3><b>Broken Promise Invoice</b></h3>';
                    script += '<ul>';
                    for (celsrm__Transaction__c trxnData : brokenPromised) {
                        script += '<li>';
                        script += 'Invoice <b>' + trxnData.Name + '</b> was promised to be paid on <b>' + trxnData.celsrm__Promise_Date__c.format() + '</b> but wasn’t paid so has been marked as broken promise. Please let us know if any additional info required else would like to receive this payment soon.';
                        script += '</li>';
                    }
                    script += '</ul>';
                } else {
                    script += 'Since there are multiple records in the system, I’ll share details of Invoices involving “promise” scenario, over an email for your easy reference and action. Thank you for your Time.<br />';
                }
            }

            if(highDPD.size() > 0) {
                if(highDPD.size() <= 3) {
                    script += '<h3><b>Open Invoice</b></h3>';
                    script += '<ul>';
                    for (celsrm__Transaction__c trxnData : highDPD) {
                        script += '<li>';
                        script += 'Invoice <b>' + trxnData.Name + '</b> of <b> $' + (trxnData.celsrm__Balance__c.format().contains('.')?trxnData.celsrm__Balance__c.format():(trxnData.celsrm__Balance__c.format()+'.00')) + '</b> has been outstanding for <b>' + trxnData.celsrm__DPD__c + '</b>.';
                        if(trxnData.celsrm__Last_Contact_Date__c != null) {
                            script += ' Last reminder was sent on <b>' + trxnData.celsrm__Last_Contact_Date__c.format() + '</b>.';
                        }
                        script += '</li>';
                    }
                    script += '</ul>';
                    //script += '<br />';
                } else {
                    //need to tell that, we will send detail on your registeered email
                    script += 'As there are multiple records showing in our system, I’ll share the list of invoices and other relevant information over an email after this call.  This will help you by providing necessary details and take the next steps. Thank you for your time. <br />';
                }
            }

            //for disputed invoice
            if(disputed.size() > 0) {
                disp = true;
                actionTriggered = 'Dispute'; //|FIN-7502| Changed by Asera | 25 Nov 2025 --//
                if(disputed.size() <= 3) {
                    script += '<h3><b>Disputed Invoice</b></h3>';
                    script += '<ul>';
                    for (celsrm__Transaction__c trxnData : disputed) {
                        
                        System.debug('@@ trxnData.celsrm__Disputes__r ' + trxnData.celsrm__Disputes__r);
                        if (trxnData.celsrm__Disputes__r.size() > 0) {
                            script += '<li>';
                            script += 'Our record shows that a dispute of <b> $' + (trxnData.celsrm__Disputed_Amount__c.format().contains('.')?trxnData.celsrm__Disputed_Amount__c.format():(trxnData.celsrm__Disputed_Amount__c.format()+'.00')) + '</b> was recorded on Invoice <b>' + trxnData.Name + '</b> having value of <b> $' + (trxnData.celsrm__Balance__c.format().contains('.')?trxnData.celsrm__Balance__c.format():(trxnData.celsrm__Balance__c.format()+'.00')) + '</b> on <b>' + trxnData.celsrm__Disputes__r[0].celsrm__Created_Date__c.format() + '</b>. The last updated status was <b>' + trxnData.celsrm__Disputes__r[0].celsrm__Status__c + '</b> as of <b>' + (trxnData.celsrm__Disputes__r[0].celsrm__Last_Contact_Date__c != null ? trxnData.celsrm__Disputes__r[0].celsrm__Last_Contact_Date__c.format() : 'today') + '</b>. Let us know if any additional inputs required.';
                            script += '</li>';
                        }
                    }
                    script += '</ul>';
                } else {
                    //need to tell that, we will send detail on your registeered email
                    script += 'Since there are multiple records in the system, I\'ll share "Dispute details" over an email for your easy reference and action. Thank you for your Time.<br />';
                }
            }
            //-- Starts |FIN-7502| Changed by Asera | 25 Nov 2025 --//
            try {
                String transactionListJson = JSON.serialize(trxnsData);
                Id accountIdForActivity = accountIds.isEmpty() ? null : new List<Id>(accountIds)[0];
                // String transactionListValue = inMap.containsKey('calledFromTransactionDetailScreen')
                //     ? String.valueOf(trxnId)
                //     : transactionListJson;
                Map<String, Object> metadataMap = new Map<String, Object>{
                    'TransactionList' => transactionListJson,
                    'Action' => actionTriggered,
                    'timestamp' => String.valueOf(Datetime.now())
                };
                String metadataJson = JSON.serialize(metadataMap);
                System.debug('metadataJson size: ' + metadataJson.length());
                Map<String, Object> inputParams = new Map<String, Object>{
                    'userId' => UserInfo.getUserId(),
                    'pageScreenName' => screenName + ': Log A Call',
                    'actionPerformed' => false,
                    'actionTakenTime' => null,
                    // 'accountId' => String.valueOf(trxnsData.celsrm__Account__c),
                    'accountId' => accountIdForActivity,
                    'transactionId' => (transactionId != null ? transactionId : null),
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
            inMap.put('CallScripts', script);
        }
        return inMap;
    }

    public static Map<Object, Object> createFollowUpTask(Map<Object, Object> inMap){
        System.debug('functionName=>createFollowUpTask');
        String accountId = (String) inMap.get('Id');
        try {
            // List<Object> trxns = (List<Object>)inMap.get('TransactionList');
            //-- validation if user is not selecting any transaction then throw error message --//
            // Boolean hasSelected = false;
            // for(Object trxn : trxns) {
            //     map < Object, Object> m = (map < Object, Object > )trxn;
            //     if( m.containsKey('isSelected') && ((Boolean)m.get('isSelected')))  {
            //         hasSelected = true;
            //         break;
            //     }
            // }
            // if(!hasSelected) {
            //     throw new celsrm.GOGDataServiceLoadException(Label.Send_Email_No_Invoice_Selected);
            // }

            Task openActivity = new Task();
            openActivity.Subject = 'Log A Call: Follow-Up';
            openActivity.Description = String.valueOf(inMap.get('ResponseByContact'));
            openActivity.Status = 'Not Started';
            openActivity.WhatId = accountId;
            openActivity.ActivityDate = Date.valueOf((String) inMap.get('FollowUpDate'));
            openActivity.Type = 'Phone';
            openActivity.celsrm__Contact_Method__c = 'Email';
            insert openActivity;
        } catch (Exception ex) {
            System.debug(ex.getStackTraceString());
            throw new celsrm.GOGDataServiceException(ex.getMessage());
        }
        return inMap;
    }
}