global with sharing class GoGCustomEmailSendToAndCc implements celsrm.GOGIScreenCustomLogic {

    global Map < Object, Object > invoke(String functionName, Map < Object, Object > inMap) {
        System.debug('@@@ GoGCustomEmailSendToAndCc  : ');
        List < Id > accIds = new List < Id > ();
        id parentId = null;
        if (inMap.containsKey('Id') && inMap.get('Id') != null) {
            parentId = (Id) inMap.get('Id');
            accIds.add(parentId);
            system.debug('parentId>>' + parentId);
        }
        Map < String, Map < String, List < String >> > returnMap = new Map < String, Map < String, List < String >> > ();
        // << START - MM - FIN-9969 - select contact by Email_Type__c based on treatment rule name >>
        // returnMap = UtilityController.fetchEmails(accIds);
        String screenName = (String)inMap.get('ggScreenName');
        if(screenName == 'SendEmailForTreatmentRule') {
            Id taskId = (Id) inMap.get('Id');
            List<Task> listTask = [select id,WhatId,celsrm__Treatment__r.Name, celsrm__Treatment__r.celsrm__Treatment_Name__c from task where id =: taskId];
            if(listTask.size() > 0) {
                Map<Id, Id> taskIdVsAccount = new Map<Id, Id>();
                Map<Id, String> taskIdVsEmailType = new Map<Id, String>();
                taskIdVsAccount.put(listTask.get(0).Id, listTask.get(0).WhatId);    
                String ruleName = listTask.get(0).celsrm__Treatment__r.celsrm__Treatment_Name__c.toUpperCase();
              String emailType = null;
                if (ruleName.contains('CUSTSTAT')) {
                    emailType = 'Statement';
                } else if (ruleName.contains('DUNNING')) {
                    emailType = 'Dunning';
                }
                taskIdVsEmailType.put(listTask.get(0).Id, emailType);
                returnMap = UtilityController.fetchEmailsBasedOnEmailType(taskIdVsAccount, taskIdVsEmailType);
            } else {
                System.debug('Invalid Task Id passes: ' + taskId);
            }
        } else {
            returnMap = UtilityController.fetchEmails(accIds);
        }
        // << END - MM - FIN-9969 - select contact by Email_Type__c based on treatment rule name >>
        Map < Object, Object > returnValue = new Map < Object, Object > ();
        // tempComposeEmail =  (map<string,object>)JSON.deserializeUntyped(JSON.serialize(inMap.get('ComposeEmail')));

        //system.debug('tempComposeEmail>>' + tempComposeEmail);

        Map < String, list < String >> m_getMailData = new Map < String, list < String >> ();
        if (accIds != null && accIds.size() > 0) {
            for (Id accID: accIds) {
                if (returnMap != null && returnMap.get(accID).get('to') != null)
                    returnValue.put('to', returnMap.get(accID).get('to'));
                if (returnMap != null && returnMap.get(accID).get('cc') != null)
                    returnValue.put('cc', returnMap.get(accID).get('cc'));
                if (returnMap != null && returnMap.get(accID).get('bcc') != null)
                    returnValue.put('bcc', returnMap.get(accID).get('bcc'));

               if (returnMap != null && returnMap.get(accID).get('from') != null) {
                    List < string > tempst = returnMap.get(accID).get('from');
                    returnValue.put('from', (Id) tempst.get(0));
                }

            }
        }

        // if(inMap.containsKey('activityData')) {
        //     Map<Object, Object> activityData = (Map<Object, Object>)inMap.get('activityData');
        //     String htmlBody = '';
        //     if(!activityData.containsKey('celsrm__Html_Body__c') || !activityData.containsKey('FromAddress') || !activityData.containsKey('CcAddress') || !activityData.containsKey('BccAddress')) {
        //         EmailMessage em = [SELECT Id, celsrm__Html_Body__c, FromAddress, CcAddress, BccAddress FROM EmailMessage WHERE Id = :String.valueOf(activityData.get('Id'))];
        //         returnValue.put('body', em.celsrm__Html_Body__c);
        //         returnValue.put('to', em.FromAddress != null ? em.FromAddress.split(',') : new List<String>());
        //         returnValue.put('cc', em.CcAddress != null ? em.CcAddress.split(',') : new List<String>());
        //         returnValue.put('bcc', em.BccAddress != null ? em.BccAddress.split(',') : new List<String>());
        //     } else {
        //         returnValue.put('body', activityData.get('celsrm__Html_Body__c'));
        //         returnValue.put('to', activityData.get('FromAddress'));
        //         returnValue.put('cc', activityData.get('CcAddress'));
        //         returnValue.put('bcc', activityData.get('BccAddress'));
        //     }
        // }

        if(inMap.containsKey('activityData')) {
            Map<Object, Object> activityData = (Map<Object, Object>)inMap.get('activityData');
            String emailId = (String) activityData.get('Id');
            EmailMessage emailmsg = new EmailMessage();
            try {
                emailmsg = [Select Id ,FromName,FromAddress,ToAddress,CcAddress,BccAddress,Subject,CreatedDate,HtmlBody,TextBody from EmailMessage where Id = :emailId];
            } catch (Exception e) {
                System.debug(e.getMessage());
            }
            if(emailmsg != null){
                String returnTemplateBody = '';
                if (emailmsg.FromName != null && emailmsg.FromAddress != null) {
                    returnTemplateBody += '<br>  <hr> <b>From:</b> ' + emailmsg.FromName + ' &lt;' + emailmsg.FromAddress + '&gt;';
                }
                if (emailmsg.CreatedDate != null) {
                    returnTemplateBody += '<br> <b>Sent:</b> ' + emailmsg.CreatedDate;
                }
                if (emailmsg.ToAddress != null) {
                    returnTemplateBody += '<br> <b>To:</b> ' + emailmsg.ToAddress;
                }
                if (emailmsg.CcAddress != null) {
                    returnTemplateBody += '<br> <b>Cc:</b> ' + emailmsg.CcAddress;
                }
                if (emailmsg.BccAddress != null) {
                    returnTemplateBody += '<br> <b>Bcc:</b> ' + emailmsg.BccAddress;
                }
                if (emailmsg.Subject != null) {
                    returnTemplateBody += '<br> <b>Subject:</b> ' + emailmsg.Subject;
                }
                if (emailmsg.HtmlBody != null) {
                    returnTemplateBody += '<br><br>' + emailmsg.HtmlBody;
                }

                returnValue.put('body', returnTemplateBody);
                returnValue.put('to', emailmsg.FromAddress != null ? emailmsg.FromAddress.split(',') : new List<String>());
                returnValue.put('cc', emailmsg.CcAddress != null ? emailmsg.CcAddress.split(',') : new List<String>());
                returnValue.put('bcc', emailmsg.BccAddress != null ? emailmsg.BccAddress.split(',') : new List<String>());
            }

            
        }         
        returnValue.put('enableSubmitButton', true);
        //inMap.put('ComposeEmail', tempComposeEmail);
        //inMap.put('FollowupDays', Date.Today().addDays(5));
        return returnValue;

    }
}