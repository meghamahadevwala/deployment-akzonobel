public with sharing class AIEmailCapturePromiseTool extends celsrm.AIToolBuilder{
    public AIEmailCapturePromiseTool() {
        shouldToolAutoExecute = true;
        isActionTool = true;
        setFunction('promise_to_pay', 'Description & details about this action/tool: This captures payment commitments for invoices ; identifies the invoices their respective dates from the latest message. \n When to choose this action to execute : when commitment to pay the invoice with an approximate or certain date is provided in latest message.\n Use & utility of this action/tool : This is fairly low-risk activity, capturing promise helps system keep up-to date about the expected payment dates.\n What will system do when this action is triggered? : 1)System will update promise date , status against the invoice/s 2) system will also send an acknowledgement email autonomous over this email. ', 
            new Map<String, Object>{
                'type' => 'object',
                'properties' => new Map<String, Object> {
                    'invoice_numbers' => new Map<String, Object>{
                        'type' => 'array', 
                        'description' => 'list of invoice numbers committed to pay. This is required to link the promise to the right invoice and update the expected payment date on those invoices.', 
                        'items' => new Map<String, Object>{
                            'type' => 'string'
                        }
                    },
                    'promise_date' => new Map<String, Object>{
                        'type' => 'string', 
                        'description' => 'Analyse the email and extract promise day considering today is '+DateTime.now() + '. \nChallenging scenario & handling :\n #1 If promise day is not mentioned explicitly; assume to a later date with clear reasoning & account for ambiguity in risk.\n #2 If no promise date or very broad & unclear date is asked; an email reply is more suitable instead of capturing a vague promise date.'
                    },
                    'email_response' => new Map<String, Object>{
                        'type' => 'string', 
                        'description' => 'Generate a reply for the past email. Generate email response only in HTML Format, nothing else. sample HTML Format: <body><p>Dear [Recipient Name],</p><p>Thank....x.</p><br></body>'+
                        'Email/content rules to follow when writting :\n' +
                        '- Write from the Account Receivable team\'s perspective in crisp business language use keyword \'we\' , \'our\' .\n' +
                        '- Consider previous email threads and customer context when drafting the response.\n' +
                        '- Address the sender of the latest email. Preserve CC context when relevant.\n' +
                        '- Never include internal agent names, pipeline mechanics, Salesforce API names, or Salesforce record IDs in customer-facing text.\n' +
                        '- Do not include a human signature block.\n'
                    }
                },
                'required' => new List<String>{'invoice_numbers', 'promise_date', 'email_response'}
            }
        );
    }
    
    // public override celsrm.AIWrapper.ReturnResponse processResponse(List<celsrm.AIWrapper.Message> history, celsrm.AIWrapper.ToolCallFunction function, celsrm.AIWrapper.EmailContent emailContent) {
    //     celsrm.AIWrapper.ReturnResponse responseMap = new celsrm.AIWrapper.ReturnResponse();
    //     responseMap.isSuccess = true;
    //     responseMap.isAction = true;
    //     responseMap.actionName = function.name;
    //     responseMap.arguments = function.arguments;
    //     responseMap.AI_Job_id = emailContent != null ? emailContent.AI_Job_id : null;
        
    //     // Add the response to the conversation history
    //     history.add(new AIWrapper.Message('assistant', 'I am sending a standardized statement as requested.'));


    //     System.debug('Triggering promise_to_pay action with arguments: ' + function.arguments);
    //     // TODO : actually trigger the email here!
    //     String promiseToPayStatus = 'success';
    //     String promiseToPayMessage = 'Promise captured successfully.';
    //     try {
    //         Map<String, Object> requestBodyMap = String.isNotBlank(function.arguments)
    //             ? (Map<String, Object>)JSON.deserializeUntyped(function.arguments)
    //             : new Map<String, Object>();
    //         List<String> transactionIds = new List<String>();
    //         if(requestBodyMap.get('invoice_numbers') != null) {
    //             for(Object invoiceNumber : (List<Object>)requestBodyMap.get('invoice_numbers')) {
    //                 if(invoiceNumber != null && String.isNotBlank(String.valueOf(invoiceNumber))) {
    //                     transactionIds.add(String.valueOf(invoiceNumber));
    //                 }
    //             }
    //         }
    //         String promiseDateText = requestBodyMap.get('promise_date') != null ? String.valueOf(requestBodyMap.get('promise_date')) : null;
    //         String emailMessageId = emailContent != null ? emailContent.id : null;
    //         String accountId = emailContent != null && emailContent.account != null ? emailContent.account.id : null;

    //         if(transactionIds == null || transactionIds.isEmpty()) {
    //             promiseToPayMessage = 'For Promise to Pay, transaction details are required.';
    //             promiseToPayStatus = 'error';
    //         } else {
    //             Date promiseDate = promiseDateText != null && promiseDateText != '' ? Date.valueOf(promiseDateText) : Date.today().addDays(5);
    //             EmailMessage emailObj = new EmailMessage();
    //             List<EmailMessage> emailList = [SELECT Id, FromName, FromAddress, ToAddress, CcAddress, BccAddress, Subject, CreatedDate, Html_Body__c, Html_Body_2__c, Html_Body_3__c, Html_Body_4__c FROM EmailMessage WHERE Id = :emailMessageId WITH SECURITY_ENFORCED LIMIT 1];
    //             if(emailList != null && emailList.size() > 0) {
    //                 emailObj = emailList.get(0);
    //             }

    //             Map<Object,Object> inMap = new Map<Object, Object>();
    //             inMap.put('Id', accountId);
    //             inMap.put('UserType', 'Email Processor Agent');
    //             List<Map<Object, Object>> transactionList = new List<Map<Object, Object>>();
    //             Set<String> trxIds = new Set<String>();
    //             if(transactionIds.size() > 0) {
    //                 List<Transaction__c> transList = [Select Id, Amount__c, balance__c, Name From Transaction__c where Name IN :transactionIds AND Account__c = :accountId];
    //                 for(Transaction__c trans : transList) {
    //                     Map<Object, Object> transMap = new Map<Object, Object>();
    //                     transMap.put('Id', trans.Id);
    //                     transMap.put('invoiceNo', '<a href="' + '/'+ trans.Id + '" target="_blank">' + trans.name + '</a>');
    //                     transMap.put('Balance__c', trans.Balance__c);
    //                     transMap.put('Amount__c', trans.Amount__c);

    //                     transMap.put('PromisedAmount', trans.balance__c);

    //                     transMap.put('PromiseDate', promiseDate);
    //                     transMap.put('Name', trans.Name);
    //                     transMap.put('nameSort', trans.Name);

    //                     transactionList.add(transMap);
    //                 }
    //                 if(transactionList.size() == 0) {
    //                     inMap.put('ggErrorMessage', 'The provided transaction does not exist.');
    //                 }
    //             } else {
    //                 inMap.put('ggErrorMessage', 'Please provide at least one transaction to create a Promise to Pay.');
    //             }
    //             inMap.put('TransactionList', transactionList);
    //             inMap.put('isFollowUp', false);

    //             if(!inMap.containsKey('ggErrorMessage')) {
    //                 inMap.put('ContactMethod','Email');
    //                 inMap.put('screenName','Promise To Pay');
    //                 inMap.put('ggScreenName','Promise To Pay');
    //                 inMap.put('SummaryFields', 'Name,Promised_Amount__c,Promise_Date__c,Balance__c');

    //                 //-- Starts | Notify Customer --//
    //                 Map<String, Object> composeEmailObj = new Map<String, Object>();
    //                 Map<String, Object> addressMap = composeEmailCustom.invoke(inMap, null, null, 'GoGCustomEmailSendToAndCc');
    //                 inMap.put('notifyCustomer', true);
    //                 for (String key : addressMap.keySet()) {
    //                     System.debug('===key:'+key);
    //                     System.debug('===value:'+addressMap.get(key));
    //                     if(key != 'emailAddressSuggestion' && key != 'enableSubmitButton') {
    //                         composeEmailObj.put(key, addressMap.get(key));
    //                     }
    //                 }

    //                 //-- Starts | Data formating class execution --//
    //                 Agent_Configuration__c orgSetting = Agent_Configuration__c.getOrgDefaults();
    //                 String templateName = orgSetting.Promise_To_Pay_Template__c != null && orgSetting.Promise_To_Pay_Template__c != '' ? orgSetting.Promise_To_Pay_Template__c : 'Promise To Pay Acknowledgement';
    //                 String folderName = orgSetting.Promise_To_Pay_Template_Folder__c != null && orgSetting.Promise_To_Pay_Template_Folder__c != '' ? orgSetting.Promise_To_Pay_Template_Folder__c : '';
    //                 String templateId = null;
    //                 if (templateName != '') {
    //                     List<EmailTemplate> emailTempList = new List<EmailTemplate>();
    //                     if(folderName != '') {
    //                         emailTempList = [SELECT Id FROM EmailTemplate WHERE Name = :templateName AND Folder.Name = :folderName WITH SECURITY_ENFORCED LIMIT 1];
    //                     } else {
    //                         emailTempList = [SELECT Id FROM EmailTemplate WHERE Name = :templateName WITH SECURITY_ENFORCED LIMIT 1];
    //                     }
    //                     if(emailTempList != null && emailTempList.size() > 0) {
    //                         templateId = emailTempList.get(0).Id;
    //                     }
    //                 }
    //                 if(templateId != null) {
    //                     Map<String, Object> formattedEmail = composeEmailCustom.invoke(inMap, templateId, null, 'composeEmailCustom');
    //                     if(formattedEmail != null) {
    //                         for (String key : formattedEmail.keySet()) {
    //                             if(key == 'htmlBody'){
    //                                 composeEmailObj.put('body', formattedEmail.get(key));
    //                             } else {
    //                                 composeEmailObj.put(key, formattedEmail.get(key));
    //                             }
    //                         }
    //                     }
    //                 }
    //                 //-- Ends | Data formating class execution --//
                    
                   
    //                 //-- Starts | Setting CC address --//
    //                 composeEmailObj.put('cc', composeEmailObj.get('to'));
    //                 //-- Ends | Setting CC address --//
    //                 //-- Starts | Updating to address --//
    //                 if(emailObj != null) {
    //                     List<String> toAddressList = new List<String>();
    //                     toAddressList.add(emailObj.FromAddress);
    //                     composeEmailObj.put('to', toAddressList);
    //                 } else {
    //                     throw new CustomException('EmailMessage Id:' + emailMessageId + ' not found.');
    //                 }
    //                 //-- Ends | Updating to address --//

    //                 String emailBody = String.valueOf(composeEmailObj.get('body'));
    //                 if(emailObj != null){
    //                      //-- Starts | Updating email subject --//
    //                     String emailSubject = 'Re: '+emailObj.Subject;
    //                     composeEmailObj.put('subject', emailSubject);

    //                 //-- Starts | Updating email body --//
    //                 String incomingEmailBody = emailObj.Html_Body__c != null ? emailObj.Html_Body__c: '';
    //                 if(emailObj.Html_Body_2__c != null && emailObj.Html_Body_2__c != '') {
    //                     incomingEmailBody += emailObj.Html_Body_2__c;
    //                 }
    //                 if(emailObj.Html_Body_3__c != null && emailObj.Html_Body_3__c != '') {
    //                     incomingEmailBody += emailObj.Html_Body_3__c;
    //                 }
    //                 if(emailObj.Html_Body_4__c != null && emailObj.Html_Body_4__c != '') {
    //                     incomingEmailBody += emailObj.Html_Body_4__c;
    //                 }

    //                     String returnTemplateBody = '';
    //                     if (emailObj.FromName != null && emailObj.FromAddress != null) {
    //                         returnTemplateBody += '<br>  <hr> <b>From:</b> ' + emailObj.FromName + ' &lt;' + emailObj.FromAddress + '&gt;';
    //                     }
    //                     if (emailObj.CreatedDate != null) {
    //                         returnTemplateBody += '<br> <b>Sent:</b> ' + emailObj.CreatedDate;
    //                     }
    //                     if (emailObj.ToAddress != null) {
    //                         returnTemplateBody += '<br> <b>To:</b> ' + emailObj.ToAddress;
    //                     }
    //                     if (emailObj.CcAddress != null) {
    //                         returnTemplateBody += '<br> <b>Cc:</b> ' + emailObj.CcAddress;
    //                     }
    //                     if (emailObj.BccAddress != null) {
    //                         returnTemplateBody += '<br> <b>Bcc:</b> ' + emailObj.BccAddress;
    //                     }
    //                     if (emailObj.Subject != null) {
    //                         returnTemplateBody += '<br> <b>Subject:</b> ' + emailObj.Subject;
    //                     }
                        
    //                     returnTemplateBody += '<br>' + incomingEmailBody;

    //                     emailBody += returnTemplateBody;
    //                 }


    //                 //String emailBody = String.valueOf(composeEmailObj.get('htmlBody')) +'\n\n'+incomingEmailBody;
    //                 composeEmailObj.put('htmlBody',emailBody);
    //                 composeEmailObj.put('body',emailBody);
    //                 //-- Ends | Updating email body --//;


    //                 inMap.put('ComposeEmail',composeEmailObj);
    //                 //-- Ends | Notify Customer --//
    //             }

    //             if(inMap.containsKey('ggErrorMessage')){
    //                 promiseToPayMessage = (String)inMap.get('ggErrorMessage');
    //                 promiseToPayStatus = 'error';
    //             } else {
    //                 //new code to log activity for promise to pay action
    //                 Map<String, Object> metadataMap = new Map<String, Object>{
    //                     'source' => 'AIEmailCapturePromiseTool',
    //                     'emailMessageId' => emailMessageId,
    //                     'transactionIds' => transactionIds,
    //                     'promiseDate' => promiseDateText,
    //                     'timestamp' => String.valueOf(Datetime.now())
    //                 };

    //                 Map<String, Object> inputParams = new Map<String, Object>{
    //                     'userId' => UserInfo.getUserId(),
    //                     'pageScreenName' => 'Email Agent: Create PromiseToPay',
    //                     'actionPerformed' => false,
    //                     'actionTakenTime' => null,
    //                     'accountId' => accountId,
    //                     'transactionId' => null,
    //                     'disputeId' => null,
    //                     'additionalMetadata' => JSON.serialize(metadataMap)
    //                 };

    //                 Id activityId = SRMUtilityController.logActivity(JSON.serialize(inputParams));
    //                 if (activityId != null) {
    //                     inMap.put('activityLogId', activityId);
    //                 }
    //                 //new code to log activity for promise to pay action

    //                 inMap = PromiseToPayActionController.savePromiseToPay(inMap);
    //                 if(inMap.containsKey('ggErrorMessage')){
    //                     promiseToPayMessage = (String)inMap.get('ggErrorMessage');
    //                     promiseToPayStatus = 'error';
    //                 } else {
    //                     Map<String,Object> reqParamMap = new Map<String,Object>();
    //                     reqParamMap.put('emailId',emailMessageId);
    //                     reqParamMap.put('actionName','Promise to pay');
    //                     reqParamMap.put('action','actionPerform');
    //                     Map<String,String> response = GOGUtilityWithoutSharingController.updateEmailActionCount(reqParamMap);
    //                     EmailMessage em = new EmailMessage();
    //                     em.Id = emailMessageId;
    //                     em.Agent_Status__c = 'Processed by Agent';
    //                     update em;
    //                     promiseToPayMessage = 'Promise captured successfully.';
    //                     promiseToPayStatus = 'success';
    //                 }
    //             }
    //         }
    //     } catch (Exception e) {
    //         promiseToPayMessage = e.getMessage()+' | '+e.getStackTraceString();
    //         promiseToPayStatus = 'error';
    //     }

    //     responseMap.resultSummary = JSON.serialize(new Map<String, Object>{
    //         'isSuccess' => promiseToPayStatus == 'success',
    //         'status' => promiseToPayStatus,
    //         'message' => promiseToPayMessage,
    //         'action' => function.name
    //     });
    //     if(promiseToPayStatus == 'error') {
    //         responseMap.isSuccess = false;
    //         responseMap.errorMessage = promiseToPayMessage;
    //     } else {
    //         responseMap.isSuccess = true;
    //         responseMap.errorMessage = null;
    //     }

    //     System.debug('p2p likely completed.' + String.valueOf(responseMap));

    //     return responseMap;
    // }
}