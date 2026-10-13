@RestResource(urlMapping='/executeCreateDispute/*')
global with sharing class AIActionCreateDispute {
    @HttpPost
    global static AIExecutorResponseWrapper executeCreateDispute() {
        System.debug('From test class');
        AIExecutorResponseWrapper apiResponse = new AIExecutorResponseWrapper();
        System.debug('Before try executeCreateDispute');
        try {
            System.debug('Inside executeCreateDispute');
            RestRequest req = RestContext.request;
            String body = req.requestBody.toString();
            CreateDisputeWrapper requestBody = (CreateDisputeWrapper)JSON.deserialize(body, CreateDisputeWrapper.class);
            System.debug('requestBody:'+body);
            System.debug('requestBody:'+requestBody);
            if(requestBody.transactionIds == null || requestBody.transactionIds.isEmpty()) {
                apiResponse.message = 'For Create Dispute, transaction details are required.';
                apiResponse.status = 'error';
            } else {
                //-- Set parameters for sending statement --//
                Map<Object,Object> inMap = AIActionCreateDispute.setParamsForCreateDispute(requestBody);
                //-- Create Attachment --//
                if(inMap.containsKey('ggErrorMessage')){
                    apiResponse.message = (String)inMap.get('ggErrorMessage');
                    apiResponse.status = 'error';
                } else {
                    //-- Execute send Statement --//
                    inMap = DisputeActionController.saveDispute(inMap);
                    if(inMap.containsKey('ggErrorMessage')){
                        apiResponse.message = (String)inMap.get('ggErrorMessage');
                        apiResponse.status = 'error';
                    } else {
                        Map<String,Object> reqParamMap = new Map<String,Object>();
                        reqParamMap.put('emailId',requestBody.emailMessageId);
                        reqParamMap.put('actionName','Create Dispute');
                        reqParamMap.put('action','actionPerform');
                        Map<String,String> response = celsrm.GOGUtilityWithoutSharingController.updateEmailActionCount(reqParamMap);
                        EmailMessage em = new EmailMessage();
                        em.Id = requestBody.emailMessageId;
                        em.celsrm__Agent_Status__c = 'Processed by Agent';
                        update em;
                        apiResponse.message = 'Dispute Created successfully.';
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

    public static Map<Object,Object> setParamsForCreateDispute(CreateDisputeWrapper requestBody) {
        // Log the incoming request body for debugging
        System.debug('requestBody >>>> '+ requestBody);
    
        // Extract necessary fields from the requestBody object
        String emailMessageId = requestBody.emailMessageId;
        String accountId = requestBody.accountId;
        List<String> transactionIds = requestBody.transactionIds;
        String disputeType = requestBody.disputeType;
        String reasonCode = requestBody.reasonCode;
    
        // Retrieve the EmailMessage object using the provided emailMessageId
        EmailMessage emailObj = getEmailMessageRecord(emailMessageId);
    
        // Fetch the dispute workflow matrix based on dispute type and reason code
        //-- Start | FIN-9672 | Changed by Ravi | 05 May 2026 --//
        //-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
        List<celsrm__Dispute_Workflow_Matrix__c> workflowMatrix = [SELECT Id, celsrm__User_Master__c, celsrm__User_Master__r.Name, celsrm__User_Master__r.celsrm__Email__c,
        celsrm__User_Master__r.celsrm__User__c, celsrm__User_Master__r.celsrm__Is_External_User__c, celsrm__User_Master__r.celsrm__Language__c, celsrm__User_Master__r.celsrm__Manager__r.celsrm__Email__c,
        celsrm__User__c, celsrm__User__r.Name, celsrm__User_SLA_Days__c, External_Email__c, External_Manager_Email__c
        FROM celsrm__Dispute_Workflow_Matrix__c 
        WHERE celsrm__Dispute_Type__c =:disputeType 
        AND celsrm__Reason_Code__c =:reasonCode 
        AND celsrm__Is_Active__c = true 
        ORDER BY celsrm__Level__c LIMIT 1];
        //-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
        //-- End | FIN-9672 | Changed by Ravi | 05 May 2026 --//
    
        // Initialize a map to store parameters to be returned
        Map<Object,Object> inMap = new Map<Object, Object>();
        inMap.put('Id', accountId);  // Add accountId to the map
        inMap.put('UserType', 'Email Processor Agent');
        // Initialize a list to hold the transaction data
        List<Map<Object, Object>> transactionList = new List<Map<Object, Object>>();
    
        // Initialize a map to store disputer (user) details
        Map<Object, Object> disputerObject = new Map<Object, Object>();
    
        // Use a Set to avoid duplicate transaction IDs
        Set<String> trxIds = new Set<String>();
    
        // Check if the transaction list is not empty
        if(transactionIds.size() > 0) {
            // Query transactions based on provided transaction IDs and account ID
            List<celsrm__Transaction__c> transList = [SELECT Id, celsrm__Amount__c, celsrm__balance__c, Name, CurrencyIsoCode 
            FROM celsrm__Transaction__c 
            WHERE Name IN :transactionIds AND celsrm__Account__c = :accountId AND celsrm__Close_Date__c = null];
            System.debug('transList >>>> '+ transList);

            // Iterate over each transaction and populate the map with required details
            for(celsrm__Transaction__c trans : transList) {
                Map<Object, Object> transMap = new Map<Object, Object>();
                transMap.put('Id', trans.Id);
                transMap.put('invoiceNo', '<a href="' + '/'+ trans.Id + '" target="_blank">' + trans.name + '</a>');
                transMap.put('celsrm__Balance__c', trans.celsrm__Balance__c);
                transMap.put('celsrm__Amount__c', trans.celsrm__Amount__c);
                transMap.put('Name', trans.Name);
                transMap.put('nameSort', trans.Name);
    
                // Add additional fields like dispute amount and type
                transMap.put('disputeAmount', trans.celsrm__Balance__c); // Amount to dispute
                transMap.put('disputeType', disputeType);
                transMap.put('CurrencyIsoCode', trans.CurrencyIsoCode);
    
                // If dispute resolution is enabled, set up workflow matrix and SLA days
                if(celsrm__Dispute_Configuration__c.getOrgDefaults().Enable_Dispute_Resolution__c) {
                    if(workflowMatrix != null && workflowMatrix.size() > 0) {
                        Integer totalSLADays = 0;
    
                        // Calculate total SLA days from the workflow matrix
                        for (celsrm__Dispute_Workflow_Matrix__c dwmObj: workflowMatrix) {
                            if(dwmObj.celsrm__User_SLA_Days__c != null){
                                totalSLADays += Integer.valueOf(String.valueOf(dwmObj.celsrm__User_SLA_Days__c));
                            }
                        }
                        //-- Start | FIN-9672 | Changed by Ravi | 05 May 2026 --//
                        DisputeUserMasterService.ResolvedUserInfo resolvedUser = DisputeUserMasterService.resolveFromMatrixRecord(workflowMatrix[0]);
                        disputerObject.put('Id', resolvedUser != null ? (resolvedUser.isExternal() ? resolvedUser.email : resolvedUser.userId) : null);
                        disputerObject.put('Name', resolvedUser != null ? resolvedUser.name : null);
                        disputerObject.put('userMasterId', resolvedUser != null ? resolvedUser.userMasterId : null);
                        transMap.put('WorkflowMatrix', workflowMatrix[0].Id);
                        transMap.put('totalSLADays', totalSLADays);
                        transMap.put('isExternalResolver', resolvedUser != null && resolvedUser.isExternal());
                        //-- End | FIN-9672 | Changed by Ravi | 05 May 2026 --//
                    }
                } else {
                    // If dispute resolution is not enabled, assign current user as the resolver
                    transMap.put('disputeType', disputeType);
                    transMap.put('reasonCode', reasonCode);
                    transMap.put('DisputeResolver', UserInfo.getUserId());
                }
    
                // Assign disputer details and link to the transaction
                transMap.put('DisputeResolver', disputerObject);
                transMap.put('Transaction__c', trans.Id);
    
                // Add the transaction map to the transaction list
                transactionList.add(transMap);
                System.debug('transactionList >>>> '+ transactionList);
            }
    
            // If no transactions found, return an error message
            if(transactionList.size() == 0) {
                inMap.put('ggErrorMessage', 'The provided transaction does not exist or either closed.');
                return inMap;
            }
        } else {
            // If no transaction IDs provided, return an error message
            inMap.put('ggErrorMessage', 'Please provide at least one transaction to create a dispute.');
            return inMap;
        }
    
        // Add the list of transactions to the parameters map
        inMap.put('TransactionList', transactionList);

        inMap.put('ContactMethod','Email');
        // inMap.put('ContactMethod','Email');
        inMap.put('screenName','Dispute');
        inMap.put('ggScreenName','Create Dispute');
        inMap.put('SummaryFields', 'Name,celsrm__Amount__c,celsrm__Transaction__c,celsrm__Dispute_Type__c,celsrm__Created_Date__c');

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
    
    
        // Return the populated map with all necessary details
        return inMap;
    }
    

    public static String getEmailTemplateId() {
        celsrm__AI_Configuration__c orgSetting = celsrm__AI_Configuration__c.getOrgDefaults();
        String templateName = orgSetting.Create_Dispute_Template__c != null && orgSetting.Create_Dispute_Template__c != '' ? orgSetting.Create_Dispute_Template__c : 'Dispute Creation For Invoice';
        String folderName = orgSetting.Create_Dispute_Template_Folder__c != null && orgSetting.Create_Dispute_Template_Folder__c != '' ? orgSetting.Create_Dispute_Template_Folder__c : '';
        
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
        // List<EmailMessage> emailList = [SELECT Id, FromAddress, ToAddress, Subject, HtmlBody FROM EmailMessage WHERE Id = :emailMessageId WITH SECURITY_ENFORCED LIMIT 1];
        List<EmailMessage> emailList = [
            SELECT Id, FromName, FromAddress, ToAddress, CcAddress, BccAddress, Subject, CreatedDate, celsrm__Html_Body__c, celsrm__Html_Body_2__c, celsrm__Html_Body_3__c, celsrm__Html_Body_4__c
            FROM EmailMessage 
            WHERE Id = :emailMessageId 
            WITH SECURITY_ENFORCED 
            LIMIT 1
        ];
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

    global with sharing class CreateDisputeWrapper {
        public String emailMessageId;
        public String accountId;
        public List<String> transactionIds;
        public String disputeType;
        public String reasonCode;
    }
}