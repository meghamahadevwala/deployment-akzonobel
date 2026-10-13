// public with sharing class OutgoingCallHandler {
    global class OutgoingCallHandler implements celsrm.GOGIScreenCustomLogic {
        global Map<Object, Object> invoke(String functionName, Map<Object, Object> inMap){
            if(functionName == 'beforeOutgoingCallHandler'){
                inMap = beforeOutgoingCallHandler(inMap);
            }
            if(functionName == 'callToCustomer'){
               inMap = callToCustomer(inMap);
            }
            if (functionName == 'fetchVerifyUser') {
                inMap = fetchVerifyUser(inMap);
            }
            if (functionName == 'isCallerIdVerified') {
                inMap = isCallerIdVerified(inMap);
            }
            if (functionName == 'initCallerIDVerification') {
                inMap = initCallerIDVerification(inMap);
            }
            if (functionName == 'checkChangeStatus') {
                String callStatus = checkChangeStatus(String.valueOf(inMap.get('CustomerCommunicationId')));
                inMap.put('callStatus', callStatus);
            }
            
            return inMap;
        }
    
        @AuraEnabled
        public static Map<Object, Object> beforeOutgoingCallHandler(Map<Object, Object> values) {
            System.debug('into beforeOutgoingCallHandler>>>');
            System.debug('values>>'+ values);
            System.debug('values.keySet()>>'+ values.keySet());
            System.debug('values.values()>>'+ values.values());
            Customer_Communication__c comObj = new Customer_Communication__c();
            comObj.Account__c = String.valueOf(values.get('account'));
            comObj.Transactions__c = JSON.serialize(values.get('transactions'));
            comObj.Phone__c = String.valueOf(values.get('contactNo'));
            comObj.Called_To__c = String.valueOf(values.get('calledTo'));
            comObj.Screen_Name__c =  String.valueOf(values.get('screenName'));
            comObj.Status__c = 'Call Initiation';
            comObj.User__c = UserInfo.getUserId();
            comObj.Contact_Type__c = 'Call';
            
            System.debug('comObj>>>'+comObj);
            insert comObj;
            return values;
        }
    
        public static void afterOutgoingCallHandler(Map<String,String> responseValue){
            System.debug('responseValue>>'+ responseValue);
            
            for (String key : responseValue.keySet()) {
                System.debug('responseValue.key>> '+ key + ' <<>> ' + responseValue.get(key));
            }
            String phone = responseValue.get('To');
            String status = responseValue.get('CallStatus');
            String callSID = responseValue.get('CallSid');
            String recordingURL = responseValue.get('RecordingUrl');
            
            List<Customer_Communication__c> listCommunicationObj = [SELECT Id, Name,Account__c,Call_SID__c FROM Customer_Communication__c WHERE Call_SID__c =: callSID];
    
            if(listCommunicationObj != null && listCommunicationObj.size() > 0){
                Customer_Communication__c comObjOld = listCommunicationObj.get(0);
                Customer_Communication__c comObjNew = new Customer_Communication__c();
                comObjNew.Id = comObjOld.Id;
                if(status != null && status.length() > 0){
                    if(status == 'completed'){
                        comObjNew.Status__c = 'Call Completed';
                    } else if(status == 'failed') {
                        comObjNew.Status__c = 'Call Failed';
                    } else if(status == 'canceled') {
                        comObjNew.Status__c = 'Call Cancelled';
                    } else {
                        comObjNew.Status__c = 'no status';    
                    }
                }
    
                if(recordingURL != null && recordingURL.length() > 0){
                    comObjNew.Call_Recording_Link__c = responseValue.get('RecordingUrl');
                }
                
                
                
                update comObjNew;
    
                // insert document //
                ContentVersion cv = new ContentVersion();
                cv.Title = 'Call Recording';
                cv.PathOnClient = 'recording.txt';
                cv.VersionData = Blob.valueOf(JSON.serialize(responseValue));
                cv.IsMajorVersion = true;
                Insert cv;
    
                String contentRecId = cv.Id;
    
                ContentVersion contentListFileUpload = [Select Id, ContentDocumentId, Title, FileType, ContentSize, VersionData FROM ContentVersion WHERE Id = :contentRecId];
                ContentDocumentLink contentLink =new ContentDocumentLink();
                contentLink.ContentDocumentId = contentListFileUpload.ContentDocumentId;
                contentLink.LinkedEntityId = comObjOld.Id;
                insert contentLink;
            }
            
        }
    
        @future (callout=true)
        public static void APIcall(String endpoint){
            System.debug('endpoint>>>>'+endpoint);
                // String endpoint = responseValue.get('RecordingUrl');
    
            Http h = new Http();
            HttpRequest request = new HttpRequest();
            request.setEndpoint(endpoint);
            request.setMethod('GET');
            request.setTimeout(120000);
    
            HttpResponse response = h.send(request);
    
            System.debug('response>>>'+ response.getBody());
            
        }
        @AuraEnabled
        public static string checkChangeStatus(String Id){
            Customer_Communication__c listCommunicationObj = [SELECT Id, Status__c FROM Customer_Communication__c WHERE Id =: Id];
            return listCommunicationObj.Status__c;
        }
        @AuraEnabled
        public static Map<Object, Object> callToCustomer(Map<Object, Object> values) {
            /*System.debug('inside call to customer..');
            Map<String,String> headers = new Map<String,String>();
            headers.put('Content-Type', 'application/json');
    
            
    
            User loggedInUser = [select id,Phone from user where id =: userinfo.getuserId()];
            if(loggedInUser != null){
                
                celsrm__SRM_Configuration__c systemConfig = celsrm__SRM_Configuration__c.getOrgDefaults();

                //String endpointbaseURL = systemConfig.TwilioBaseURL__c;
				//String callbackBaseURL = systemConfig.Twilio_Callback_Base_URL__c;
                //String callCenterNo = systemConfig.TwilioFromNumber__c;

                String endPoint = endpointbaseURL + '/start';
				String callbackURL = callbackBaseURL + '/services/apexrest/twilio-callback';
                System.debug('endPoint : ' + endPoint);

                //String callCenterNo = '+18135447697';// Sailfin_Demo
                //String callCenterNo = '+14083171600';// My_FirstTwillio
                String customerNo =  String.valueOf(values.get('contactNo'));
                System.debug('Agent Number : ' + loggedInUser.Phone + ',customerNo : ' + customerNo);
                String body = '{"agentNo":"' + loggedInUser.Phone +'",    "callCenterNo":"' + callCenterNo +'",   "confId":"c123",    "customerNo":"' + customerNo +'","orgName":"WCMQA","callUsingAgentNo":true,"callbackURL":"' + callbackURL + '"' + '}';
                
                System.debug('body : ' + body);
                //Sailfin_Demo Project
                //String response = makeAcallout('https://ginger-starfish-5814.twil.io/start','POST',body,headers);
                
                //My First Project
                String response = makeAcallout(endPoint,'POST',body,headers);
                if(response != null && response.length() > 0){
                    System.debug('inside response...');
                    Map < string, object > mapResult = (Map < string, object >) JSON.deserializeUntyped(response);
                    System.debug('inside map...' + mapResult);
                    if(mapResult != null && !mapResult.isEmpty()){
                        if(mapResult.containsKey('status')){
                            System.debug('inside Status...' + mapResult.get('status'));
                            Customer_Communication__c comObj = new Customer_Communication__c();
                            comObj.Account__c = String.valueOf(values.get('account'));
                            if (values.get('transactions') != null && values.get('transactions') != '') {
                                comObj.Transactions__c = JSON.serialize(values.get('transactions'));
                            }
                            comObj.Phone__c = String.valueOf(values.get('contactNo'));
                            comObj.Called_To__c = String.valueOf(values.get('calledTo'));
                            comObj.Screen_Name__c =  String.valueOf(values.get('screenName'));
                            comObj.Status__c = 'Call Initiation';
                            comObj.User__c = UserInfo.getUserId();
                            comObj.TranscribeStatus__c = 'Pending';
                            comObj.Contact_Type__c = 'Call';
                            if(mapResult.containsKey('callId')){
                                comObj.Call_SID__c = (String)mapResult.get('callId'); 
                            }
                            
                            System.debug('comObj>>>'+comObj);
                            insert comObj;
                            values.put('CustomerCommunicationId', comObj.Id);
                            System.debug('comObj ID >>>'+comObj.Id);
                        }
                        
                    }
                }
                
                
            }*/
            return values;
        }
    
        
        // public static String makeAcallout(String endPoint,String methodType,String body,Map<String,String> headers){
        //     try{
        //        Http http = new Http();
               
        //        HttpRequest request = new HttpRequest();
        //        request.setEndpoint(endPoint);
        //        request.setTimeout(120000);
        //        request.setMethod(methodType);
               
        //         if(headers != null && headers.size() > 0){
        //             for(String headerName :headers.keyset()){
        //                 request.setHeader(headerName, headers.get(headerName));
        //             }
        //         }
                
        //         if(body != null && body.length() > 0){
        //             request.setBody(body);
        //         }
        //         HttpResponse response = http.send(request);
        //         System.debug('Response Code: ' + response.getStatusCode());
        //         System.debug('Response Body: ' +response.getBody());
        //         if(response.getStatusCode() == 200){
        //             return response.getBody();
        //         }else{
        //             return null;
        //         }
                
        //     }catch(Exception e){
        //        System.debug(' ERROR :: callout() :: ' + e);
        //        system.debug(' ERROR :: callout() :: ' + e.getMessage());
        //    }
        //    return null;
        // }

        @AuraEnabled
        public static Map<Object, Object> fetchVerifyUser(Map<Object, Object> values) {
            List<User> userList = [SELECT Id,Name,Profile.Name,Phone,Email FROM User WHERE ProfileId=: UserInfo.getProfileId()];
            if (userList.size() > 0) {
                Set<Id> userId = new Set<Id>();
                for (User u : userList) {
                    userId.add(u.Id);
                }
                List<celsrm__User_Preference__c> userPrefList = [SELECT Id, is_CallerId_verify__c,celsrm__User__c FROM celsrm__User_Preference__c WHERE celsrm__User__c=:userId ];
                Map<Id,Boolean> verifyMap = new Map<Id,Boolean>();
                if (userPrefList.size() > 0) {
                    for (celsrm__User_Preference__c userPref : userPrefList) {
                        verifyMap.put(userPref.celsrm__User__c, userPref.is_CallerId_verify__c);
                    }
                }
                List<Map<String,Object>> returnList = new List<Map<String,Object>>();
                for (User user : userList) {
                    Map<String,Object>  returnMap = new Map<String,Object>();
                    returnMap.put('Username',user.Name);
                    returnMap.put('ProfileName',user.Profile.Name);
                    returnMap.put('Phone',user.Phone);
                    returnMap.put('Id',user.Id);
                    returnMap.put('Email',user.Email);
                    if (verifyMap.get(user.Id) != null) {
                        returnMap.put('isCallerIdVerify', verifyMap.get(user.Id)); 
                    } else {
                        returnMap.put('isCallerIdVerify',false); 
                    }
                    
                    returnList.add(returnMap);
                }
                values.put('dataServiceResponse', returnList);
            }
            return values;
        }
       public static void transcriptCallHandler(Map<String,String> responseValue){
            System.debug('responseValue>>'+ responseValue);
            System.debug('responseValue.keySet()>>'+ responseValue.keySet());
            System.debug('responseValue.values()>>'+ responseValue.values());
            String callSID = responseValue.get('CallSid');
            String transcriptionText = responseValue.get('TranscriptionText');
            
            List<Customer_Communication__c> listCommunicationObj = [SELECT Id, Name,Account__c,Call_SID__c,Call_Transcript__c FROM Customer_Communication__c WHERE Call_SID__c =: callSID];

            if(listCommunicationObj != null && listCommunicationObj.size() > 0){
                Customer_Communication__c comObjOld = listCommunicationObj.get(0);
                Customer_Communication__c comObjNew = new Customer_Communication__c();
                comObjNew.Id = comObjOld.Id;
                

                if(transcriptionText != null && transcriptionText.length() > 0){
                    comObjNew.Call_Transcript__c = transcriptionText;
                }             
                update comObjNew;
            }
            
      }
      
      @AuraEnabled
      public static Map<Object, Object> isCallerIdVerified(Map<Object, Object> values) {
        List<celsrm__User_Preference__c> userPref = [SELECT Id,is_CallerId_verify__c FROM celsrm__User_Preference__c WHERE celsrm__User__c =:UserInfo.getUserId()];
        if(!userPref.isEmpty()){
            if(userPref.get(0).is_CallerId_verify__c){
                values.put('isCallerIdVerified', true);
            }else{
                User loggedInUser = [select id,Phone from user where id =: userinfo.getuserId()];
                values.put('isCallerIdVerified', false);
                values.put('UserPhoneNumber', loggedInUser.Phone);
            }
        }else{
            User loggedInUser = [select id,Phone from user where id =: userinfo.getuserId()];
            values.put('isCallerIdVerified', false);
            values.put('UserPhoneNumber', loggedInUser.Phone);
        }
        return values;
      }
      
      @AuraEnabled
      public static Map<Object, Object> initCallerIDVerification(Map<Object, Object> values) {
        List<Map<String,String>> listUsersToVerify = new List<Map<String,String>>();
        /*Map<String,String> mapUserNameVsPhone = new Map<String,String>();
        mapUserNameVsPhone.put('userId',UserInfo.getUserId());
        mapUserNameVsPhone.put('to',(String)values.get('phone'));
        mapUserNameVsPhone.put('username',UserInfo.getName());
        listUsersToVerify.add(mapUserNameVsPhone);
        
        string listUsers = JSON.serialize(listUsersToVerify);
        
        System.debug('listUsers : ' + listUsers);

        Map<String,String> headers = new Map<String,String>();
        headers.put('Content-Type', 'application/json');
        
        celsrm__SRM_Configuration__c systemConfig = celsrm__SRM_Configuration__c.getOrgDefaults();

        //String endpointbaseURL = systemConfig.TwilioBaseURL__c;
		//String callbackBaseURL = systemConfig.Twilio_Callback_Base_URL__c;
        //String callCenterNo = systemConfig.TwilioFromNumber__c;

        String endPoint = endpointbaseURL + '/verify-caller-id';
		String callbackURL = callbackBaseURL + '/services/apexrest/twilio-callback';
        
        //String body = '{"users":' + listUsers +'}';
        String body = '{"callbackURL":"' + callbackURL +'","users":' + listUsers +'}';
        System.debug('Body :' + body);
        String responseStr = OutgoingCallHandler.makeAcallout(endPoint,'POST',body,headers);
        
        if(responseStr != null){
            System.debug('inside responseStr...');
            List<Object> listResult =  (List<Object>) JSON.deserializeUntyped(responseStr);
            if(!listResult.isEmpty()){
                System.debug('Result list :: ' + listResult);
                List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
                for(Object result : listResult){
                    Map<String,Object> resultMap = (Map<String,Object>) result;
                
                    if(resultMap.containsKey('success')){
                        Boolean isSuccess = (Boolean) resultMap.get('success');
                        if(isSuccess){
                            values.put('OTP',resultMap.get('code'));
                        }
                    }
                }
                System.debug('mails >>> ' + mails);
                Messaging.sendEmail(mails);
            }
        }*/
        
        
        return values;
      }
      
    }