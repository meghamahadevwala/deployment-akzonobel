global with sharing class GOGCreateFollowupTask implements celsrm.GOGIScreenCustomLogic {
    global Map < Object, Object > invoke(String functionName, Map < Object, Object > inMap) {
        System.debug('into GOGCustomImplementation');
        System.debug('functionName ::: ' + functionName);
        System.debug('inMap.keySet() ::: ' + inMap.keySet());
        for(Object str : inMap.keySet()) {
            System.debug('inMap.keys ::: ' + str);    
        }
        inMap.put('VendorName', 'adding new value');
        String activityName = '';
        String activityNote = inMap.get('NoteBody') != null && inMap.get('NoteBody') != '' ? String.valueOf(inMap.get('NoteBody')) : null;
        Set<Id> TransIDS = new Set<Id>();
        List<String> invoiceNumberList = new List<String>();
        Set<String> AccId = new Set<String>();
        AccId.add(String.valueOf(inMap.get('Id')));

        // try{
        //     String contactMethod = (string) inMap.get('ContactMehods');
        //     if(contactMethod == 'Text'){
        //         System.debug('send sms from here............');
                
        //         Map<String,String> headers = new Map<String,String>();
        //         headers.put('Content-Type', 'application/json');
                
        //         String phNumber = (String) inMap.get('WhatsAppNumber');
        //         String message = (String) inMap.get('WhatsAppMessage');
        //         System.debug('Number : ' + phNumber);
        //         System.debug('Message  : ' + message);
                
        //         String endPoint = 'https://mantis-butterfly-7576.twil.io/sms';
        //         String body = '{"to":"' + phNumber +'","message":"' + message +'"}';
        //         System.debug('Body :' + body);
        //         String response = OutgoingCallHandler.makeAcallout(endPoint,'POST',body,headers);
        //         System.debug('response : ' + response);

        //         if(response != null && response.length() > 0){
        //             System.debug('inside response...');
        //             Map < string, object > mapResult = (Map < string, object >) JSON.deserializeUntyped(response);
        //             System.debug('inside map...' + mapResult);
        //             if(mapResult != null && !mapResult.isEmpty()){
        //                 if(mapResult.containsKey('status')){
        //                     Integer smsStatusCode = Integer.valueOf(mapResult.get('status'));
        //                     System.debug('inside Status...' + smsStatusCode);
        //                     Customer_Communication__c comObj = new Customer_Communication__c();
        //                     comObj.Account__c = String.valueOf(inMap.get('Id'));
        //                     if (inMap.get('TransactionList') != null && inMap.get('TransactionList') != '') {
        //                         set<String> trxfldList = new set<String>();
        //                         List < object > tran = (List < object > ) inMap.get('TransactionList');
        //                         for (Object ts: tran) {
        //                             Map < Object, Object > m = (Map < Object, Object > ) ts;
        //                             Id key = (String) m.get('Id');
        //                             trxfldList.add(key); 
        //                         }
        //                         Map<String,Object> mapTran = new Map<String,Object>();
        //                      mapTran.put('transactions',trxfldList);
                             
        //                     comObj.Transactions__c = JSON.serialize(mapTran);
        //                 }
        //                 comObj.Phone__c = phNumber;
        //                 comObj.Called_To__c = String.valueOf(inMap.get('contactRecordId'));
        //                 comObj.Screen_Name__c =  'Contact Customer';
                        
		// 				comObj.Contact_Type__c = 'Text Message';
        //                 comObj.User__c = UserInfo.getUserId();
                        
        //                 if(smsStatusCode == 200){
        //                     comObj.Status__c = 'SMS Sent';
        //                 }else{
        //                     comObj.Status__c = 'SMS Failed';
        //                 }

        //                 if(mapResult.containsKey('sid')){
        //                     comObj.Call_SID__c = (String)mapResult.get('sid'); 
        //                 }
                        
        //                 System.debug('comObj>>>'+comObj);
        //                 insert comObj;
                        
        //                 System.debug('comObj ID >>>'+comObj.Id);
        //             }
                    
        //         }
        //     }
		// }
        // }catch(Exception e){
        //     System.debug('Error in sending SMS : ' + e.getMessage());
        // }

        try {
            List<Object> trxns = (List<Object>)inMap.get('TransactionList');
            if (inMap.get('ggScreenName') != 'SRM_SendStatementScreen') {
                for(Object trxn : trxns) {
                    map < Object, Object> m = (map < Object, Object > )trxn;
                    if (m.get('celsrm__Account__r') != null) {
                        AccId.add(String.valueOf(((Map<Object,Object>)m.get('celsrm__Account__r')).get('Id')));
                    }
                }
            }
            
            
            //validation if user is not selecting any transaction then throw error message
            if(inMap.get('ggScreenName') == 'WCMPromisToPayScreenEmailAction' || inMap.get('ggScreenName') == 'WCMCreateDisputeScreenEmailAction') {
                Boolean hasSelected = false;
                for(Object trxn : trxns) {
                    map < Object, Object> m = (map < Object, Object > )trxn;
                    System.debug('@@@ m : ' + m);
                    System.debug('@@@ m.containsKey isSelected : ' + m.containsKey('isSelected'));
                    System.debug('@@@ misSelected : ' + m.get('isSelected'));
                    if( m.containsKey('isSelected') && ((Boolean)m.get('isSelected')))  {
                        hasSelected = true;
                        break;
                    }
                }
                System.debug('@@@ hasSelected : ' + hasSelected);
                if(!hasSelected) {
                    throw new celsrm.GOGDataServiceLoadException('Please select atleast one Transaction for Promise');
                }
            }
            
            System.debug('AccId=' + AccId);
            //update collection rating field on Account
            List<Account> CurrentAccList = [SELECT Id, Name FROM Account WHERE id =: AccId]; // Need to add 'celsrm__Contact_method__c' field
          /*  CurrentAcc.Rating_Count__c = (CurrentAcc.Rating_Count__c == null ? 0 : CurrentAcc.Rating_Count__c) + 1;
            if (Integer.valueOf(inMap.get('CollectionRating')) != null) {
                CurrentAcc.Rating_Sum__c = (CurrentAcc.Rating_Sum__c == null ? 0 : CurrentAcc.Rating_Sum__c) + Integer.valueOf(inMap.get('CollectionRating'));
            }*/
            for(Account CurrentAcc : CurrentAccList) {
                CurrentAcc.celsrm__Last_Contact_Date__c = date.Today();
                CurrentAcc.celsrm__Last_Contact_Method__c = (string) inMap.get('ContactMethod');
                CurrentAcc.celsrm__Last_Contact_Type__c = (string) inMap.get('ContactMethod') == 'Phone' ? 'Phone' : (string) inMap.get('screenName');
                if((inMap.get('ggScreenName') == 'SRM_SendStatementScreen')) {
                    CurrentAcc.celsrm__Latest_Note__c = 'Send Statement sent' + '\n' + (String)(((Map<Object,Object>)inMap.get('ComposeEmail')).get('subject'));
                    CurrentAcc.celsrm__Latest_Note_By__c = UserInfo.getUserId();
                    CurrentAcc.celsrm__Latest_Note_Date__c = date.today();
                    //CurrentAcc.celsrm__Latest_Note_Title__c = 'Send Statement sent' + '\n' + (String)(((Map<Object,Object>)inMap.get('ComposeEmail')).get('subject'));
                    //CurrentAcc.celsrm__Latest_Simple_Note__c = 'Send Statement sent' + '\n' + (String)(((Map<Object,Object>)inMap.get('ComposeEmail')).get('subject'));
                    activityName = 'Send Statement';
                    activityNote = 'Statement Sent' + '\n' + (String)(((Map<Object,Object>)inMap.get('ComposeEmail')).get('subject'));
                }
            }
            
            if (CurrentAccList != null) {
                System.debug('CurrentAcc>>' + CurrentAccList);
                update CurrentAccList;
            }
    
            //update comment on tasks
            String EmailBody = '';
            if (String.valueOf(inMap.get('ContactMethod')) == 'Email') {
                map < string, object > tempComposeEmail = (map < string, object > ) JSON.deserializeUntyped(JSON.serialize(inMap.get('ComposeEmail')));
                List < Object > attchmentList = new List < Object > ();
                if (tempComposeEmail != null && tempComposeEmail.get('attachment') != null) {
                    attchmentList = (List < Object > ) JSON.deserializeUntyped(JSON.serialize(tempComposeEmail.get('attachment')));
                    system.debug('-attchmentList-' + attchmentList);
                }
                if (tempComposeEmail != null && tempComposeEmail.get('EmailBody') != null) {
                    system.debug('tempComposeEmail.get(to)>>' + tempComposeEmail.get('EmailBody'));
                    EmailBody = (String) tempComposeEmail.get('EmailBody');
                }
            }
            system.debug('-EmailBody -' + EmailBody);
            if (inMap.get('TransactionList') != null && inMap.get('TransactionList') != '') {
                TransIDS = new Set<Id>();
                for(Object trxn : trxns) {
                    map < Object, Object> m = (map < Object, Object > )trxn;
                    System.debug('@@@ m : ' + m);
                    System.debug('@@@ m.containsKey isSelected : ' + m.containsKey('isSelected'));
                    System.debug('@@@ misSelected : ' + m.get('isSelected'));
                    if((inMap.get('ggScreenName') == 'WCMPromisToPayScreenEmailAction' ||inMap.get('ggScreenName') == 'WCMCreateDisputeScreenEmailAction') && ( !m.containsKey('isSelected') || !((Boolean)m.get('isSelected')) )) {
                        continue;
                    }
                    Id trxId = (Id)m.get('Id');
                    invoiceNumberList.add(String.valueOf(m.get('invoiceNo')));
                    TransIDS.add(trxId);
                }
                //Map<id,celsrm__Transaction__c> MapTransOlderNotes = new Map<Id,celsrm__Transaction__c>([SELECT Id FROM celsrm__Transaction__c WHERE Id IN : TransIDS ]); 
                List < celsrm__Transaction__c > trxList = new List < celsrm__Transaction__c > ();
                
                for(Object trxn : trxns) {
                    map < Object, Object> m = (map < Object, Object > )trxn;
                    System.debug('@@@ m : ' + m);
                    System.debug('@@@ m.containsKey isSelected : ' + m.containsKey('isSelected'));
                    System.debug('@@@ misSelected : ' + m.get('isSelected'));
                    if((inMap.get('ggScreenName') == 'WCMPromisToPayScreenEmailAction' ||inMap.get('ggScreenName') == 'WCMCreateDisputeScreenEmailAction') && ( !m.containsKey('isSelected') || !((Boolean)m.get('isSelected')) )) {
                        continue;
                    }
                    
                    String trxId = (String)m.get('Id');
                    celsrm__Transaction__c currentTrx = New celsrm__Transaction__c(Id=trxId  );
                    if((inMap.get('ggScreenName') == 'Send Email')) {
                        currentTrx.celsrm__Last_Contact_Date__c = date.Today();
                        currentTrx.celsrm__Last_Contacted_By__c = UserInfo.getUserId();
                        activityName = 'Send Email';
                    } else if((inMap.get('ggScreenName') == 'Log A Call')) {
                        currentTrx.celsrm__Last_Contact_Date__c = date.Today();
                        currentTrx.celsrm__Last_Contacted_By__c = UserInfo.getUserId();
                        activityName = 'Log A Call';
                    } else if ((string) inMap.get('screenName') == 'Promise To Pay' || inMap.get('ggScreenName') == 'WCMPromisToPayScreenEmailAction') {
                        currentTrx.celsrm__Promised_Amount__c = Double.valueOf(m.get('PromisedAmount'));
                        currentTrx.celsrm__Promise_Date__c = date.valueOf(m.get('PromiseDate') + ' 00:00:00');
                        activityName = 'Promise To Pay';
                    }
   
                     if(String.valueOf(inMap.get('NoteBody')) != null) {
                        currentTrx.celsrm__Latest_Note__c =  String.valueOf(inMap.get('NoteBody'));    
                        currentTrx.celsrm__Latest_Note_Title__c = String.valueOf(inMap.get('NoteTitle'));
                        currentTrx.celsrm__Latest_Note_Date__c = date.today();
                        currentTrx.celsrm__Latest_Note_Entered_By__c = UserInfo.getUserId();
                    } 

                    
                    trxList.add(currentTrx);
                    
                }
                System.debug('@@@ 2222' + trxList);
                if (trxList != null && trxList.size() > 0) {
                    update trxList;
                }
            }
    
            if (inMap.get('ContactMethod') =='Phone' && inMap.get('ContactCalled') != '' && inMap.get('ContactCalled') != null && inMap.get('ContactCalled') != '' && inMap.get('ContactCalled') != null) {	
                Contact con = new contact();	
                con.Id = String.valueOf(inMap.get('DialContactId'));	
                con.Phone = String.valueOf(inMap.get('ContactCalled'));	
                update con;	
            }

            if(inMap.get('ggScreenName') == 'WCM__SendEmailReminderSC'){ //--Depricated --//
                activityName = 'Send Email Reminder';
                activityNote = 'Email Reminder Sent ' + '\n' + (String)inMap.get('EmailTemplateList');
            }
            if(activityName != '') {
                Datetime currentDateTime = Datetime.now();
                if(!AccId.isEmpty()) {
                    //-- Starts | FIN-6130 | Changed by Dilshad | 25 Jun 2024 --//
                    Map<String, Object> additionalFields;
                    if(activityName == 'Log A Call') {
                        additionalFields = new Map<String, Object>();
                        additionalFields.put('Phone_Type__c', String.valueOf(inMap.get('PhoneType')));
                        additionalFields.put('Response_By_Contact__c', String.valueOf(inMap.get('ResponseByContact')));
                        additionalFields.put('Contact__c', String.valueOf(inMap.get('ContactName')).split('_')[0]);
                    } 
                    celsrm.SRMUtilityController.insertActivity(new List<String>(AccId), 'celsrm__Account__c', activityName, currentDateTime, 100, activityNote, UserInfo.getUserId(), null, 'Internal', additionalFields);
                    //-- Ends | FIN-6130 | Changed by Dilshad | 25 Jun 2024 --//
                }
                if(!TransIDS.isEmpty()) {
                    //-- Starts | FIN-6130 | Changed by Dilshad | 25 Jun 2024 --//
                    Map<String, Object> additionalFields;
                    if(activityName == 'Log A Call') {
                        additionalFields = new Map<String, Object>();
                        additionalFields.put('Phone_Type__c', String.valueOf(inMap.get('PhoneType')));
                        additionalFields.put('Response_By_Contact__c', String.valueOf(inMap.get('ResponseByContact')));
                        String contactName = inMap.get('ContactName') != null ? String.valueOf(inMap.get('ContactName')).split('_')[0] : null;
                        additionalFields.put('Contact__c', contactName);
                    } 
                    celsrm.SRMUtilityController.insertActivity((List<String>)new List<Id>( TransIDS ), 'celsrm__Transaction__c', activityName, currentDateTime, 100, activityNote, UserInfo.getUserId(), null, 'Internal', additionalFields);
                    //-- Ends | FIN-6130 | Changed by Dilshad | 25 Jun 2024 --//
                }
            }

            List < Task > lstTask = new List < Task > ();
    
            //for Activity history
            for (String tempAccId : AccId) {
                Task activityTask = new Task();
                String subject = String.valueOf(inMap.get('ContactMethod'));
                // boolean notadded = false;
                // if (inMap.get('NoteTitle') != null && inMap.get('NoteTitle') != '') {
                //     notadded = true;
                // }
        
                subject = subject + ':' + 'Follow-Up';
        
                activityTask.Subject = subject;
                activityTask.Description = String.valueOf(inMap.get('EmailBody'));
                activityTask.celsrm__Notes__c = String.valueOf(inMap.get('NoteBody'));
                activityTask.Status = 'Completed';
                // activityTask.OwnerId = String.valueOf(inMap.get('OwnerId'));
                 if(inMap.get('ContactMethod') =='Phone'){
                    activityTask.whoId= String.valueOf(inMap.get('DialContactId'));
                    activityTask.celsrm__Notes__c= String.valueOf(inMap.get('NotePhone'));
                }
                activityTask.WhatId = tempAccId;
                activityTask.ActivityDate = date.today();
                activityTask.Type = String.valueOf(inMap.get('ContactMethod'));
                activityTask.celsrm__Contact_Method__c = (string) inMap.get('screenName');
                lstTask.add(activityTask);
        
            }
            
            if (lstTask != null && lstTask.size() > 0) {
                insert lstTask;
            }
            system.debug('========================' + (boolean) inMap.get('isFollowUp'));
            if (inMap.get('isFollowUp') != null && (boolean) inMap.get('isFollowUp')) {
    
                List < Task > lstOpenTask = new List < Task > ();
                for (String tempAccId : AccId) {
                    Task openActivity = new Task();
                    if (inMap.get('ContactMethod') != null ) {
                        if (String.valueOf(inMap.get('ContactMethod')) == 'Email') {
                            map < string, object > tempComposeEmail = (map < string, object > ) JSON.deserializeUntyped(JSON.serialize(inMap.get('ComposeEmail')));
                            String subjectOpen = String.valueOf(tempComposeEmail.get('subject'));
                
                            openActivity.Subject = subjectOpen;
                        } else {
                            openActivity.Subject = String.valueOf(inMap.get('ContactMethod')) + ': Follow-Up';
                        }
                    }
                    if(String.valueOf(inMap.get('screenName')) == 'Promise To Pay') {
                        openActivity.Subject = 'Promise To Pay : Follow-Up';
                        openActivity.Description = 'Take follow up on promised invoices: '+ String.join(invoiceNumberList, ', ')+'.';
                    }
                    
                    if (inMap.get('Didnotpickcall') != null && (boolean) inMap.get('Didnotpickcall')) {
                        openActivity.Description = String.valueOf(inMap.get('DidnotpickcallDescription'));
                    } else if(inMap.get('EmailBody') != null && inMap.get('EmailBody') != '') {
                        openActivity.Description = String.valueOf(inMap.get('EmailBody'));
                    } else if(String.valueOf(inMap.get('ContactMethod')) == 'Create Dispute') {
                        openActivity.Description = 'Take follow up on dispute created for invoices '+ String.join(invoiceNumberList, ', ')+'.';
                    } 

                    openActivity.Status = 'Not Started';
                    openActivity.WhatId = tempAccId;
                    openActivity.ActivityDate = Date.valueOf((String) inMap.get('FollowUpDate'));
                    openActivity.Type = String.valueOf(inMap.get('ContactMethod'));
                    openActivity.celsrm__Contact_Method__c = (string) inMap.get('screenName');
                    lstOpenTask.add(openActivity);
                }
                if (lstOpenTask != null && lstOpenTask.size() > 0) {
                    insert lstOpenTask;
                }
            }
            system.debug('######');
        } catch (celsrm.GOGDataServiceTransformException gste) {
            throw new celsrm.GOGDataServiceTransformException(gste.getMessage());
        } catch (celsrm.GOGDataServiceLoadException gsle) {
            throw new celsrm.GOGDataServiceLoadException(gsle.getMessage());
        } catch (celsrm.GOGDataServiceExtractException dsee) {
            throw new celsrm.GOGDataServiceExtractException(dsee.getMessage());
        } catch (Exception ex) {
            throw new celsrm.GOGDataServiceException(ex.getMessage());
        }
        return inMap;
    }
}