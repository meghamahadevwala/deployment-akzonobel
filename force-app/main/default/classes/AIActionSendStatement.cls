@RestResource(urlMapping='/executeSendStatement/*')
global with sharing class AIActionSendStatement {
    @HttpPost
    global static AIExecutorResponseWrapper executeSendStatement(String emailMessageId, String accountId, List<String> transactionIds, String invoiceBucket) {
        AIExecutorResponseWrapper apiResponse = new AIExecutorResponseWrapper();
        System.debug('emailMessageId:'+emailMessageId);
        System.debug('accountId:'+accountId);
        System.debug('transactionIds:'+transactionIds);
        System.debug('invoiceBucket:'+invoiceBucket);
        Map<String, String> invoiceBucketMap =  new Map<String, String>();
        invoiceBucketMap.put('All Overdue Invoice','All Overdue');
        invoiceBucketMap.put('All Open Invoice','All Open');
        invoiceBucketMap.put('Disputed Invoice','Disputed');
        invoiceBucketMap.put('Promised Invoice','Promised');
        invoiceBucketMap.put('1 to 30 Aging Bucket','1 - 30');
        invoiceBucketMap.put('31 to 60 Aging Bucket','31 - 60');
        invoiceBucketMap.put('61 to 90 Aging Bucket','61 - 90');
        invoiceBucketMap.put('91 to 180 Aging Bucket','91 - 180');
        invoiceBucketMap.put('Invoice have Aging Bucket more then 180 days','Over 180');
        try {
            if(accountId == null) {
                apiResponse.message = 'To send statement Account details are needed.';
                apiResponse.status = 'error';
            } 
            // else if(transactionIds == null && (invoiceBucket == null || invoiceBucket =='')) {
            //     apiResponse.message = 'To send statement either invoice bucket or transaction details are need.';
            //     apiResponse.status = 'error';
            // } 
            else {
                invoiceBucket = invoiceBucketMap.containsKey(invoiceBucket) ? invoiceBucketMap.get(invoiceBucket) : 'All Overdue';
                //-- Starts | Set parameters for sending statement --//
                Map<Object,Object> inMap = AIActionSendStatement.setParamsForStatement(emailMessageId, accountId, transactionIds, invoiceBucket);
                //-- Ends | Set parameters for sending statement --//
        
                //-- Starts | Execute send Statement --//
                // SendStatementActionController.onSubmitSendStatement(inMap);
                //-- Ends | Execute send Statement --//

                //-- Starts | Execute Queueable --//
                System.enqueueJob(new AIActionSendStatementQueueable(inMap));
                //-- Ends | Execute Queueable --//
                if(emailMessageId != null && emailMessageId != ''){
                    Map<String,Object> reqParamMap = new Map<String,Object>();
                    reqParamMap.put('emailId',emailMessageId);
                    reqParamMap.put('actionName','Send Statement');
                    reqParamMap.put('action','actionPerform');
                    Map<String,String> response = celsrm.GOGUtilityWithoutSharingController.updateEmailActionCount(reqParamMap);
                    EmailMessage em = new EmailMessage();
                    em.Id = emailMessageId;
                    em.celsrm__Agent_Status__c = 'Processed by Agent';
                    update em;
                }
                
                apiResponse.message = 'Statement is sent successfully.';
                apiResponse.status = 'success';
            }
            
        } catch (Exception e) {
            apiResponse.message = e.getMessage()+' | '+e.getStackTraceString();
            apiResponse.status = 'error';
        }
        return apiResponse;
    }

    public static Map<Object,Object> setParamsForStatement(String emailMessageId, String accountId, List<String> transactionIds, String invoiceBucket) {
        Map<Object,Object> inMap = new Map<Object, Object>();
        //-- Set Account Id --//
        inMap.put('Id', accountId);
        inMap.put('ContactMethod', 'Email');
        inMap.put('AttachCheckBox', true);
        inMap.put('IsIncludeChild', false);
        inMap.put('UserType', 'Email Processor Agent');
        inMap.put('screenName', 'Send Statement');

        celsrm__AI_Configuration__c orgSetting = celsrm__AI_Configuration__c.getOrgDefaults();
        System.debug('Org Default Send Statement Template: ' + orgSetting.Send_Statement_Template__c);

        String templateName = orgSetting.Send_Statement_Template__c != null && orgSetting.Send_Statement_Template__c != '' ? orgSetting.Send_Statement_Template__c : 'Billing Statement';
        String folderName = orgSetting.Send_Statement_Template_Folder__c != null && orgSetting.Send_Statement_Template_Folder__c != '' ? orgSetting.Send_Statement_Template_Folder__c : '';
        
        inMap.put('defaultTemplate', templateName);
        inMap.put('StatementFormat', 'Pdf');
        inMap.put('isFollowUp', 'false');
        if (transactionIds != null && transactionIds.size() > 0) {
            List<celsrm__transaction__c> trxList = [Select Id, Name From celsrm__transaction__c Where Name IN :transactionIds AND celsrm__Account__c = :accountId AND celsrm__Close_Date__c = null];
            List<Object> records = new List<Object>();
            
            for (celsrm__transaction__c trx : trxList) {
                Map<Object, Object> currentValues = new Map<Object, Object>();
                currentValues.put('Id', trx.Id);
                records.add(currentValues);
            }

            inMap.put('TransactionList', records);
        }
        
        String listViewId = null;
        if(invoiceBucket != null && invoiceBucket !='') {
            listViewId = AIActionSendStatement.getListViewId(invoiceBucket);
        }
        
        System.debug('listViewId:'+listViewId);
        inMap.put('ListView', listViewId);
        
        Map<Object, Object> composeEmailObj = new Map<Object, Object>();

        //-- Starts | Prefetch class for to and from address execution --//
        Map<String, Object> addressMap = composeEmailCustom.invoke(inMap, null, null, 'GoGCustomEmailSendToAndCc');
        for (String key : addressMap.keySet()) {
            System.debug('===key:'+key);
            System.debug('===value:'+addressMap.get(key));
            if(key != 'emailAddressSuggestion' && key != 'enableSubmitButton') {
                composeEmailObj.put(key, addressMap.get(key));
            }
        }
        //-- Ends | Prefetch class for to and from address execution --//

        //-- Starts | Data formating class execution --//
        String templateId = getEmailTemplateId(templateName, folderName);
        if(templateId != null) {
            Map<String, Object> formattedEmail = composeEmailCustom.invoke(inMap, templateId, null, 'composeEmailCustom');
            if(formattedEmail != null) {
                for (String key : formattedEmail.keySet()) {
                    composeEmailObj.put(key, formattedEmail.get(key));
                }
            }
        }
        //-- Ends | Data formating class execution --//
        EmailMessage emailObj = null;
        if(emailMessageId != null && emailMessageId != ''){
            //-- Starts | Setting CC address --//
            composeEmailObj.put('cc', composeEmailObj.get('to'));
            //-- Ends | Setting CC address --//

            //-- Starts | Updating to address --//
            emailObj = getEmailMessageRecord(emailMessageId);
            //EmailMessage emailObj = SendStatementActionController.getEmailMessageRecord(emailMessageId);
            //getEmailMessageRecord(emailMessageId);
            if(emailObj != null) {
                List<String> toAddressList = new List<String>();
                toAddressList.add(emailObj.FromAddress);
                composeEmailObj.put('to', toAddressList);
            } else {
                throw new celsrm.CustomException('EmailMessage Id:' + emailMessageId + ' not found.');
            }
            //-- Ends | Updating to address --//
        }
        

        String emailBody = String.valueOf(composeEmailObj.get('htmlBody'));
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

        //-- Update email body with transaction list --//
        //inMap = SendStatementActionController.updateComposeEmailBody(inMap);
        // for (Object key : inMap.keySet()) {
        //     System.debug('===key:'+key);
        //     System.debug('===value:'+inMap.get(key));
        // }
        map < string, object > tempComposeEmail = (map < string, object > ) JSON.deserializeUntyped(JSON.serialize(inMap.get('ComposeEmail')));
        // for (String key : tempComposeEmail.keySet()) {
        //     System.debug('tempComposeEmail===key:'+key);
        //     System.debug('tempComposeEmail===value:'+tempComposeEmail.get(key));
        // }

        // TODO: Correct the attachment part
        if(inMap.get('StatementFormat') == 'Pdf'){
            inMap = SendStatementActionController.createStatementAttachment(inMap);
        }
        //Attachment creation is done. for content version we call queueable apex

        // if(inMap.get('StatementFormat') == 'Excel'){
            // String htmlBody = SendStatementActionController.generateAttachmentAndEmailBody(inMap);
            // htmlBody = '<html> <head><style> @page { font-family: Arial Unicode MS; font-size:10px; } body{ font-family: Arial Unicode MS; font-size:10px; } </style></head><body>' + htmlBody + '</body></html>';
            // // String contentSt = (String) inMap.get('SendStmtAttachmentContent');
            // String st =  '<head><meta http-equiv=\'Content-type\' content=\'text/html;charset=UTF-8\'><style> #txSummaryTableJS td{font-size:11px; text-align:left;  width:auto; border: solid 1px gray;padding-left: 3px;  padding-right: 3px;  white-space:nowrap;  font-family:Arial Unicode MS;}  #txSummaryTableJS th{ font-size:12px; background-color:#000000;color:White;border:1px solid gray;text-align: left;padding: 6px 6px 6px 3px;}  #txSummaryTableJS {border-collapse:collapse;padding:0px;border:1px solid gray; font-family:Arial Unicode MS;}@page {size:landscape; }</style>';
            // htmlBody = htmlBody.replace('<head>',st);
            // Blob contentBlob = Blob.valueOf(htmlBody);
            // // system.debug('contentBlob>>>'+contentBlob);
            // String encodedContent = EncodingUtil.base64Encode(contentBlob);
            // // inMap.put('SendStmtAttachmentContent', encodedContent);

            // inMap.put('finalContent', encodedContent);
            // SendStatementAttachmentInsert sendStatementAttachmentInsertObj = new SendStatementAttachmentInsert();
            // inMap = sendStatementAttachmentInsertObj.invoke('Send Statement', inMap);
            
        // }
        return inMap;
    }

    public static String getEmailTemplateId(String templateName, String folderName) {
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

    public static String getListViewId(String invoiceBucket) {
        List<celsrm__Custom_List_View__c> customListViewList = [SELECT Id FROM celsrm__Custom_List_View__c where celsrm__ListView_For_Object__c = 'celsrm__Transaction__c' and Folder_Name__c = 'Send Statement' AND Name = :invoiceBucket WITH SECURITY_ENFORCED LIMIT 1];
        if(customListViewList != null && customListViewList.size() > 0) {
            return customListViewList.get(0).Id;
        } else {
            return null;
        }
    }

    // public static EmailMessage getEmailMessageDetails(String emailId) {
    //     List<EmailMessage> emailList = [SELECT Id, FromAddress, ToAddress, Subject, celsrm__Html_Body__c, celsrm__Html_Body_2__c, celsrm__Html_Body_3__c, celsrm__Html_Body_4__c FROM EmailMessage WHERE Id = :emailId WITH SECURITY_ENFORCED LIMIT 1];
    //     if(emailList != null && emailList.size() > 0) {
    //         return emailList.get(0);
    //     } else {
    //         return null;
    //     }
    // }

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
}



//we shuold be able to send email based on invoicebucket as well as from list of transaction
// attachment should be create and send in email

//We will update status on emailmessage: if it is success or failed