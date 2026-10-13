global with sharing class FetchOutOfOfficeDetail implements celsrm.GOGIScreenCustomLogic{
    global Map<Object, Object> invoke(String functionName, Map<Object, Object> inMap) {
        System.debug('into FetchOutOfOfficeDetail');
        if (functionName.endsWithIgnoreCase('EmailOption')) {
            inMap = EmailOption(inMap);
        } if (functionName.endsWithIgnoreCase('submitOutOfOffice')) {
            inMap = submitOutOfOffice(inMap);
        } else {
            List<String> toAddress = new List<String>();
            Date dueDate;
            if(inMap.containsKey('activityData')) {
                System.debug('@@@ activityData : ' + inMap.get('activityData'));
                Map<Object, Object> aData = (Map<Object, Object>)inMap.get('activityData');
                System.debug('@@@ adata: ' + aData );
                // if(aData.containsKey('celsrm__Classification_Response__c') == false){
                //     String t = (String)aData.get('Id');
                //     EmailMessage result = [SELECT celsrm__Classification_Response__c from EmailMessage where Id =: t];
                //     aData.put('celsrm__Classification_Response__c',result.celsrm__Classification_Response__c);
                // }
                //-- Starts | FIN-6410| Changes By: Asera | 19 Sep 2024 --//
                if(String.valueOf(aData.get('Id')) != ''){
                    String emailMessageId = (String)aData.get('Id');
                    String classificationResponseString = celsrm.SRMUtilityController.getClassificationResponse(emailMessageId); 
                    if(classificationResponseString != null && classificationResponseString != ''){
                        aData.put('celsrm__Classification_Response__c', classificationResponseString);
                    } 
                }
                //-- End | FIN-6410| Changes By: Asera | 19 Sep 2024 --//
                String ToAdd = (String)aData.get('ToAddress');
                if(aData.containsKey('celsrm__Classification_Response__c')) {
                    Map<String, Object> res = (Map<String, Object>)JSON.deserializeUntyped((String)aData.get('celsrm__Classification_Response__c'));
                    if(res.containsKey('entities')) {
                        List<Object> ent = (List<Object>)res.get('entities');
                        if(ent.size() > 0) {
                            Boolean anyEmail = false;
                            Boolean anyTask = false;
                            for(Object o : ent) {
                                Map<String, Object> tempMap = (Map<String, Object>)o;
                                if( String.valueOf(tempMap.get('dim')).equalsIgnoreCase('email') ) {
                                   
                                    Map<String,Object> emailValueMap = (Map<String,Object>)tempMap.get('value');
                                    if (!(String.valueOf(emailValueMap.get('value'))).equals(ToAdd)) {
                                        toAddress.add(String.valueOf(emailValueMap.get('value')));
                                    }
                                    
                                    inMap.put('ShowOperation', 'Email');
                                    anyEmail = true;
                                }
                                if( String.valueOf(tempMap.get('dim')).equalsIgnoreCase('time') ) {
                                    Map<String, Object> tempTimeMap = (Map<String, Object>)tempMap.get('value');
                                    if (dueDate == null && (String.valueOf(tempTimeMap.get('grain')).equalsIgnoreCase('day') || String.valueOf(tempTimeMap.get('grain')).equalsIgnoreCase('week'))) {
                                        String temp = String.valueOf(tempTimeMap.get('value'));
                                        dueDate= Date.valueOf(temp );
                                        inMap.put('showTaskDetail', 'true');
                                        inMap.put('ShowOperation', 'Task');
                                        anyTask = true;
                                    }
                                }
                            }
                            if (anyEmail && anyTask) {
                                inMap.put('ShowOperation', 'Both');
                            }
                        }
                        if (dueDate == null) {
                            dueDate = Date.today().addDays(7);
                        }
                    }
                }
                if (aData.containsKey('RelatedToId')) {
                    String relatedId = (String)aData.get('RelatedToId');
                    Account acc = [SELECT OwnerId,Owner.name from Account where Id =: relatedId];
                    Map<String,String> assign = new Map<String,String>();
                    assign.put('id', acc.OwnerId);
                    assign.put('name', acc.Owner.name);
                    inMap.put('assignTo', assign);
                }
                if (toAddress.size() > 1) {
                    if (aData.containsKey('FromName')) {
                        String fromName = (String)aData.get('FromName');
                        inMap.put('Notes', fromName + ' has given alternate contact detail which you can select from below list. Do you want to forward this email?');
                    } else {
                        String FromAddress = (String)aData.get('FromAddress');
                        inMap.put('Notes', FromAddress + ' has given alternate contact detail which you can select from below list. Do you want to forward this email?');
                    }
                    inMap.put('SingleEmail', 'false');
                } else if (toAddress.size() == 1) {
                    if (aData.containsKey('FromName')) {
                        String fromName = (String)aData.get('FromName');
                        inMap.put('Notes', fromName + ' has provide us email of ' + toAddress.get(0) + ' on behalf. Do you want to forward this email to '+ toAddress.get(0) + '?');
                    } else {
                        String FromAddress = (String)aData.get('FromAddress');
                        inMap.put('Notes', FromAddress + ' has provide us email of ' + toAddress.get(0) + ' on behalf. Do you want to forward this email to '+ toAddress.get(0) + '?');
                    }
                    inMap.put('SingleEmail', 'true');
                }
                inMap.put('toAddress', toAddress);
                inMap.put('dueDate', dueDate);
                inMap.put('subject', (String)aData.get('Subject'));
            }
        }
        
        return inMap;
    }

    public static Map<Object, Object> EmailOption(Map<Object, Object> inMap) {
        if(inMap.containsKey('activityData')) {
            List<String> toAddress = new List<String>();
            System.debug('@@@ activityData : ' + inMap.get('activityData'));
            Map<Object, Object> aData = (Map<Object, Object>)inMap.get('activityData');
            System.debug('@@@ adata: ' + aData );
            // if(aData.containsKey('celsrm__Classification_Response__c') == false){
            //     String t = (String)aData.get('Id');
            //     EmailMessage result = [SELECT celsrm__Classification_Response__c from EmailMessage where Id =: t];
            //     aData.put('celsrm__Classification_Response__c',result.celsrm__Classification_Response__c);
            // }
            //-- Start | FIN-6410| Changes By: Asera | 19 Sep 2024 --//
            if(String.valueOf(aData.get('Id')) != ''){
                String emailMessageId = (String)aData.get('Id');
                String classificationResponseString = celsrm.SRMUtilityController.getClassificationResponse(emailMessageId); 
                if(classificationResponseString != null && classificationResponseString != ''){
                    aData.put('celsrm__Classification_Response__c', classificationResponseString);
                } 
            }
            //-- End | FIN-6410| Changes By: Asera | 19 Sep 2024 --//
            String ToAdd = (String)aData.get('ToAddress');
            if(aData.containsKey('celsrm__Classification_Response__c')) {
                Map<String, Object> res = (Map<String, Object>)JSON.deserializeUntyped((String)aData.get('celsrm__Classification_Response__c'));
                if(res.containsKey('entities')) {
                    List<Object> ent = (List<Object>)res.get('entities');
                    if(ent.size() > 0) {
                        for(Object o : ent) {
                            Map<String, Object> tempMap = (Map<String, Object>)o;
                            if( String.valueOf(tempMap.get('dim')).equalsIgnoreCase('email') ) {
                                Map<String,Object> emailValueMap = (Map<String,Object>)tempMap.get('value');
                                if (!(String.valueOf(emailValueMap.get('value'))).equals(ToAdd)) {
                                    toAddress.add(String.valueOf(emailValueMap.get('value')));
                                }
                            }
                        }
                    }
                }
            }
            List<Map<String,String>> optList = new List<Map<String,String>>();
            if (toAddress.size() > 1) {
                for (String toad : toAddress) {
                    Map<String,String> opt = new Map<String,String>();
                    opt.put('label', toad);
                    opt.put('Email', toad);
                    optList.add(opt);
                }
            } else if (toAddress.size() == 1) {
                Map<String,String> opt = new Map<String,String>();
                if (aData.containsKey('FromName')) {
                    String fromName = (String)aData.get('FromName');
                    opt.put('label', fromName + ' has provide us email ' + toAddress.get(0) + ' behalf of him. Do you want to forward this email?');
                    opt.put('Email', toAddress.get(0));
                } else {
                    String FromAddress = (String)aData.get('FromAddress');
                    opt.put('label', FromAddress + ' has provide us email ' + toAddress.get(0) + ' behalf of him. Do you want to forward this email?');
                    opt.put('Email', toAddress.get(0));
                }
                optList.add(opt);
            }
            inMap.put('dataServiceResponse', optList);
        }
        return inMap;
    }

    public static Map<Object, Object> submitOutOfOffice(Map<Object, Object> inMap) {
        String successMessage = '';
        String taskMessage = '';
        String emailMessage = '';
        if (inMap.containsKey('Action') && (((String)inMap.get('Action')).equalsIgnoreCase('createTask') || ((String)inMap.get('Action')).equalsIgnoreCase('Both'))) {
            Map<Object,Object> assignTo = (Map<Object,Object>)inMap.get('assignTo');
            String temp = String.valueOf(inMap.get('dueDate'));
            Task tsk = new Task();
            tsk.Subject = (String)inMap.get('subject');
            tsk.ActivityDate = Date.valueOf(temp );
            tsk.OwnerId = (String)assignTo.get('id');
            tsk.Status='Not Started';
            insert tsk;
            taskMessage = 'Task Created Successfully';
        }
        if (inMap.containsKey('Action') && (((String)inMap.get('Action')).equalsIgnoreCase('forwardEmail') || ((String)inMap.get('Action')).equalsIgnoreCase('Both'))) {
            String fromId;
            List < String > Toaddress = new List < String >();
            List < String > ccaddress = new List < String >();
            List < String > bccaddress = new List < String >();
            List < Map < String, String >> attachmentobj = new List < Map < String, String >>();
            String htmlBody;
            String textbody;
            String subject;
            id parentId = null;
            
            if(inMap.containsKey('activityData')) {
                
                System.debug('@@@ activityData : ' + inMap.get('activityData'));
                Map<Object, Object> aData = (Map<Object, Object>)inMap.get('activityData');
                String fromAddress = String.valueOf(aData.get('ToAddress'));
                
                OrgWideEmailAddress owd = [SELECT Id, Address FROM OrgWideEmailAddress where Address =: fromAddress Limit 1];
                fromId = owd.Id;
                String ccAdd = String.valueOf(aData.get('FromAddress'));
                ccaddress.add(ccAdd);
                if (aData.containsKey('RelatedToId') && aData.get('RelatedToId') != null) {
                    parentId = (Id) aData.get('RelatedToId');
                    // system.debug('parentId>>' + parentId);
                }
                if (aData.containsKey('Subject') && aData.get('Subject') != null) {
                    String sub = (String) aData.get('Subject');
                    if (sub.contains('FW:')) {
                        subject = sub;
                    } else {
                        subject = 'FW: ' + sub;
                    }
                    // system.debug('parentId>>' + parentId);
                }
                String pBody = '';
                if (ccAdd != null && ccAdd != '') {
                    pBody += '<b>From:</b> ' + ccAdd + '<br/>';
                }
                if (aData.containsKey('CreatedDate') && aData.get('CreatedDate') != null) {
                    String temp = String.valueOf(aData.get('CreatedDate'));
                    pBody += '<b>Sent:</b> ' + Date.valueOf(temp ) + '<br/>';
                }
                if (fromAddress != null) {
                    pBody += '<b>To:</b> ' + fromAddress + '<br/>';
                }
                if (subject != null && subject != '') {
                    pBody += '<b>Subject:</b> ' + subject + '<br/>';
                }
                if (aData.containsKey('HtmlBody') && aData.get('HtmlBody') != null) {
                    htmlBody = '<br/> <hr>' + pBody + '<br/>' + String.valueOf(aData.get('HtmlBody'));
                }
            }
            emailMessage = 'Email Forward on ';
            if (inMap.containsKey('SingleEmail') && ((String)inMap.get('SingleEmail')).equalsIgnoreCase('true')) {
                List<Object> toAdd = (List<Object>)inMap.get('toAddress');
                for (Object  tempAdd: toAdd) {
                    String add = (String)tempAdd;
                    Toaddress.add(add);
                    emailMessage += add;
                }
            } else if (inMap.containsKey('SingleEmail') && ((String)inMap.get('SingleEmail')).equalsIgnoreCase('false')) {
                if (inMap.containsKey('AddressGrid') && inMap.get('AddressGrid') != null) {
                    List<Object> addGrid = (List<Object>)inMap.get('AddressGrid');
                    for (Object  addG: addGrid) {
                        Map<Object,Object> tempAddress = (Map<Object,Object>)addG; 
                        String add = (String)tempAddress.get('Email');
                        Toaddress.add(add);
                        emailMessage += add + ' ';
                    }
                    emailMessage = emailMessage.removeEnd(',');
                }
                
            }
            // celsrm.GOGEmailMapper.sendEmail(fromId, Toaddress, subject, htmlBody, textbody, ccaddress, bccaddress, attachmentobj, parentId);

			celsrm.GOGEmailMapper.SendEmailBean emailBean1 = new celsrm.GOGEmailMapper.SendEmailBean();
			emailBean1.owea = fromId;
			emailBean1.to = Toaddress;
			emailBean1.subject = subject;
			emailBean1.htmlBody = htmlBody;
			emailBean1.plainTextBody = textbody;
			emailBean1.cc = ccaddress;
			emailBean1.bcc = bccaddress;
			emailBean1.attachment = attachmentobj;
			emailBean1.parentId = parentId;
			emailBean1.followUpTaskDueDate = null;
			celsrm.GOGEmailMapper.sendEmailWithBean(emailBean1);
        }
        if (taskMessage != '' && emailMessage != '') {
            successMessage = taskMessage + ' AND ' + emailMessage;
        } else if (taskMessage != '') {
            successMessage = taskMessage;
        } else if (emailMessage != '') {
            successMessage = emailMessage;
        }
        inMap.put('successMessage', successMessage);
        return inMap;
    }
}