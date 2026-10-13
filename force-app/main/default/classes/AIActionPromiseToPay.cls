@RestResource(urlMapping='/executePromiseToPay/*')
global with sharing class AIActionPromiseToPay {
    
    @HttpPost
    global static AIExecutorResponseWrapper executePromiseToPay() {
        AIExecutorResponseWrapper apiResponse = new AIExecutorResponseWrapper();
        try {
            RestRequest req = RestContext.request;
            String body = req.requestBody.toString();
            PromiseToPayWrapper requestBody = (PromiseToPayWrapper)JSON.deserialize(body, PromiseToPayWrapper.class);
            System.debug('requestBody:'+body);
            System.debug('requestBody:'+requestBody);
            if(requestBody.transactionIds == null || requestBody.transactionIds.isEmpty()) {
                apiResponse.message = 'For Promise to Pay, transaction details are required.';
                apiResponse.status = 'error';
            } else {
                //-- Set parameters for sending statement --//
                Map<Object,Object> inMap = AIActionPromiseToPay.setParamsForPromiseToPay(requestBody);
                //-- Create Attachment --//
                if(inMap.containsKey('ggErrorMessage')){
                    apiResponse.message = (String)inMap.get('ggErrorMessage');
                    apiResponse.status = 'error';
                } else {
                    //-- Execute send Statement --//
                    inMap = PromiseToPayActionController.savePromiseToPay(inMap);
                    if(inMap.containsKey('ggErrorMessage')){
                        apiResponse.message = (String)inMap.get('ggErrorMessage');
                        apiResponse.status = 'error';
                    } else {
                        Map<String,Object> reqParamMap = new Map<String,Object>();
                        reqParamMap.put('emailId',requestBody.emailMessageId);
                        reqParamMap.put('actionName','Promise to pay');
                        reqParamMap.put('action','actionPerform');
                        Map<String,String> response = celsrm.GOGUtilityWithoutSharingController.updateEmailActionCount(reqParamMap);
                        EmailMessage em = new EmailMessage();
                        em.Id = requestBody.emailMessageId;
                        em.celsrm__Agent_Status__c = 'Processed by Agent';
                        update em;
                        apiResponse.message = 'Promise captured successfully.';
                        apiResponse.status = 'success';
                    }
                }
                
            }
        } catch (Exception e) {
            apiResponse.message = e.getMessage()+' | '+e.getStackTraceString();
            apiResponse.status = 'error';
        }
        return apiResponse;
    }

    public static Map<Object,Object> setParamsForPromiseToPay(PromiseToPayWrapper requestBody) {
        String emailMessageId = requestBody.emailMessageId;
        String accountId = requestBody.accountId;
        List<String> transactionIds = requestBody.transactionIds; 
        Date promiseDate = requestBody.promiseDate != null && requestBody.promiseDate != '' ? Date.valueOf(requestBody.promiseDate) : Date.today().addDays(5);
        EmailMessage emailObj = getEmailMessageRecord(emailMessageId);
        Map<Object,Object> inMap = new Map<Object, Object>();
        inMap.put('Id', accountId);
        inMap.put('UserType', 'Email Processor Agent');
        List<Map<Object, Object>> transactionList = new List<Map<Object, Object>>();
        Set<String> trxIds = new Set<String>(); 
        if(transactionIds.size() > 0) {
            List<celsrm__Transaction__c> transList = [Select Id, celsrm__Amount__c, celsrm__balance__c, Name From celsrm__Transaction__c where Name IN :transactionIds AND celsrm__Account__c = :accountId];
            for(celsrm__Transaction__c trans : transList) {
                Map<Object, Object> transMap = new Map<Object, Object>();
                transMap.put('Id', trans.Id);
                transMap.put('invoiceNo', '<a href="' + '/'+ trans.Id + '" target="_blank">' + trans.name + '</a>');
                transMap.put('celsrm__Balance__c', trans.celsrm__Balance__c);
                transMap.put('celsrm__Amount__c', trans.celsrm__Amount__c);

                transMap.put('PromisedAmount', trans.celsrm__balance__c);

                transMap.put('PromiseDate', promiseDate);
                transMap.put('Name', trans.Name);
                transMap.put('nameSort', trans.Name);

                transactionList.add(transMap);
            }
            if(transactionList.size() == 0) {
                inMap.put('ggErrorMessage', 'The provided transaction does not exist.');
                return inMap;
            }
        } else {
            inMap.put('ggErrorMessage', 'Please provide at least one transaction to create a Promise to Pay.');
            return inMap;
        }
        inMap.put('TransactionList', transactionList);
        inMap.put('isFollowUp', false);

        
        inMap.put('ContactMethod','Email');
        inMap.put('screenName','Promise To Pay');
        inMap.put('ggScreenName','Promise To Pay');
        inMap.put('SummaryFields', 'Name,celsrm__Promised_Amount__c,celsrm__Promise_Date__c,celsrm__Balance__c');

        //-- Starts | Notify Customer --//
        Map<String, Object> composeEmailObj = new Map<String, Object>();
        Map<String, Object> addressMap = composeEmailCustom.invoke(inMap, null, null, 'GoGCustomEmailSendToAndCc');
        inMap.put('notifyCustomer', true);
        for (String key : addressMap.keySet()) {
            System.debug('===key:'+key);
            System.debug('===value:'+addressMap.get(key));
            if(key != 'emailAddressSuggestion' && key != 'enableSubmitButton') {
                composeEmailObj.put(key, addressMap.get(key));
            }
        }

        //-- Starts | Data formating class execution --//
        String templateId = getEmailTemplateId();
        if(templateId != null) {
            Map<String, Object> formattedEmail = composeEmailCustom.invoke(inMap, templateId, null, 'composeEmailCustom');
            if(formattedEmail != null) {
                for (String key : formattedEmail.keySet()) {
                    if(key == 'htmlBody'){
                        composeEmailObj.put('body', formattedEmail.get(key));
                    } else {
                        composeEmailObj.put(key, formattedEmail.get(key));
                    }
                }
            }
        }
        //-- Ends | Data formating class execution --//
        
       
        //-- Starts | Setting CC address --//
        composeEmailObj.put('cc', composeEmailObj.get('to'));
        //-- Ends | Setting CC address --//
        //-- Starts | Updating to address --//
        if(emailObj != null) {
            List<String> toAddressList = new List<String>();
            toAddressList.add(emailObj.FromAddress);
            composeEmailObj.put('to', toAddressList);
        } else {
            throw new celsrm.CustomException('EmailMessage Id:' + emailMessageId + ' not found.');
        }
        //-- Ends | Updating to address --//

        String emailBody = String.valueOf(composeEmailObj.get('body'));
        if(emailObj != null){
             //-- Starts | Updating email subject --//
            String emailSubject = 'Re: '+emailObj.Subject;
            composeEmailObj.put('subject', emailSubject);

        //-- Starts | Updating email body --//
        String incomingEmailBody = emailObj.celsrm__Html_Body__c != null ? emailObj.celsrm__Html_Body__c: '';
        if(emailObj.celsrm__Html_Body_2__c != null && emailObj.celsrm__Html_Body_2__c != '') {
            incomingEmailBody += emailObj.celsrm__Html_Body_2__c;
        }
        if(emailObj.celsrm__Html_Body_3__c != null && emailObj.celsrm__Html_Body_3__c != '') {
            incomingEmailBody += emailObj.celsrm__Html_Body_3__c;
        }
        if(emailObj.celsrm__Html_Body_4__c != null && emailObj.celsrm__Html_Body_4__c != '') {
            incomingEmailBody += emailObj.celsrm__Html_Body_4__c;
        }

            String returnTemplateBody = '';
            if (emailObj.FromName != null && emailObj.FromAddress != null) {
                returnTemplateBody += '<br>  <hr> <b>From:</b> ' + emailObj.FromName + ' &lt;' + emailObj.FromAddress + '&gt;';
            }
            if (emailObj.CreatedDate != null) {
                returnTemplateBody += '<br> <b>Sent:</b> ' + emailObj.CreatedDate;
            }
            if (emailObj.ToAddress != null) {
                returnTemplateBody += '<br> <b>To:</b> ' + emailObj.ToAddress;
            }
            if (emailObj.CcAddress != null) {
                returnTemplateBody += '<br> <b>Cc:</b> ' + emailObj.CcAddress;
            }
            if (emailObj.BccAddress != null) {
                returnTemplateBody += '<br> <b>Bcc:</b> ' + emailObj.BccAddress;
            }
            if (emailObj.Subject != null) {
                returnTemplateBody += '<br> <b>Subject:</b> ' + emailObj.Subject;
            }
            
            returnTemplateBody += '<br>' + incomingEmailBody;

            emailBody += returnTemplateBody;
        }


        //String emailBody = String.valueOf(composeEmailObj.get('htmlBody')) +'\n\n'+incomingEmailBody;
        composeEmailObj.put('htmlBody',emailBody);
        composeEmailObj.put('body',emailBody);
        //-- Ends | Updating email body --//;


        inMap.put('ComposeEmail',composeEmailObj);
        //-- Ends | Notify Customer --//
        return inMap;
    }

    public static String getEmailTemplateId() {
        celsrm__AI_Configuration__c orgSetting = celsrm__AI_Configuration__c.getOrgDefaults();
        String templateName = orgSetting.Promise_To_Pay_Template__c != null && orgSetting.Promise_To_Pay_Template__c != '' ? orgSetting.Promise_To_Pay_Template__c : 'Promise To Pay Acknowledgement';
        String folderName = orgSetting.Promise_To_Pay_Template_Folder__c != null && orgSetting.Promise_To_Pay_Template_Folder__c != '' ? orgSetting.Promise_To_Pay_Template_Folder__c : '';
        
        if (templateName != '') {
            List<EmailTemplate> emailTempList = new List<EmailTemplate>();
            if(folderName != '') {
                emailTempList = [SELECT Id FROM EmailTemplate WHERE Name = :templateName AND Folder.Name = :folderName WITH SECURITY_ENFORCED LIMIT 1];
            } else {
                emailTempList = [SELECT Id FROM EmailTemplate WHERE Name = :templateName WITH SECURITY_ENFORCED LIMIT 1];
            }
            if(emailTempList != null && emailTempList.size() > 0) {
                return emailTempList.get(0).Id;
            }
        }
        return null;
    }
    public static EmailMessage getEmailMessageRecord(String emailMessageId) {
        EmailMessage emailObj = new EmailMessage();
        List<EmailMessage> emailList = [SELECT Id, FromName, FromAddress, ToAddress, CcAddress, BccAddress, Subject, CreatedDate, celsrm__Html_Body__c, celsrm__Html_Body_2__c, celsrm__Html_Body_3__c, celsrm__Html_Body_4__c FROM EmailMessage WHERE Id = :emailMessageId WITH SECURITY_ENFORCED LIMIT 1];
        if(emailList != null && emailList.size() > 0) {
            emailObj = emailList.get(0);
        } 
        return emailObj;
    }
    
    //-- Wrapper Class --//
    global with sharing class AIExecutorResponseWrapper {
        global String status;
        global String message;
    }

    global with sharing class PromiseToPayWrapper {
        public String emailMessageId;
        public String accountId;
        public List<String> transactionIds;
        public String promiseDate;
    }
}