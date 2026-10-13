global with sharing class WCMCustomEmailSend implements celsrm.GOGIScreenCustomLogic {
    global Map<Object, Object> invoke(String functionName, Map<Object, Object> inMap) {
        system.debug('functionName>>' + functionName);
        system.debug('inMap>>' + inMap);
        system.debug('inMap.keySet()>>' + inMap.keySet());
        System.debug('InMap Value:' + inMap.get('notebody'));

      
        String str = JSON.serialize(inMap.get('SendStatement'));

        system.debug('str ' + str);
        map < string, object > tempComposeEmail = (map < string, object > ) JSON.deserializeUntyped(JSON.serialize(inMap.get('SendStatement')));
        system.debug('tempComposeEmail>>' + tempComposeEmail);

        Id fromId = null;
        if (tempComposeEmail.containsKey('from') && tempComposeEmail.get('from') != null && String.valueOf(tempComposeEmail.get('from')) != '') {
            fromId = (Id) tempComposeEmail.get('from');
            system.debug('fromId>>' + fromId);
        }

        List < String > Toaddress = null;
        if (tempComposeEmail.containsKey('to') && tempComposeEmail.get('to') != null && ((List < object > ) tempComposeEmail.get('to')).size() > 0) {
            Toaddress = new List < string > ();
            List < object > Toaddressobj = ((List < object > ) tempComposeEmail.get('to'));
            for (object obj: Toaddressobj) {
                if (obj instanceof String) {
                    Toaddress.add(String.valueOf(obj));
                } else {
                    Map<String, Object> newMap = (Map<String, Object>)obj;
                    Toaddress.add(String.valueOf(newMap.get('value')));
                }
            }
            system.debug('Toaddress>>' + Toaddress);
        } else {
            throw new celsrm.GOGDataServiceLoadException('Please enter TO Email Address');
        }

        String subject;
        if (tempComposeEmail.containsKey('subject') && tempComposeEmail.get('subject') != null) {
            subject = String.valueOf(tempComposeEmail.get('subject'));
            system.debug('subject>>' + subject);
        } else {
            throw new celsrm.GOGDataServiceLoadException('Please enter value into Subject');
        }

        List < String > ccaddress = null;
        if (tempComposeEmail != null && tempComposeEmail.containsKey('cc') && tempComposeEmail.get('cc') != null && ((List < object > ) tempComposeEmail.get('cc')).size() > 0) {
            List < object > ccaddressls = ((List < object > ) tempComposeEmail.get('cc'));
            ccaddress = new List < string > ();
            for (object obj: ccaddressls) {
                if (obj != null) {
                    ccaddress.add(String.valueOf(obj));
                }
            }
            system.debug('ccaddress>>' + ccaddress);
        }

        List < String > bccaddress = null;
        if (tempComposeEmail.containsKey('bcc') && tempComposeEmail.get('bcc') != null && ((List < Object > ) tempComposeEmail.get('bcc')).size() > 0) {
            List < object > bccaddressls = ((List < object > ) tempComposeEmail.get('bcc'));
            bccaddress = new List < string > ();
            for (object obj: bccaddressls) {
                if (obj != null) {
                    bccaddress.add(String.valueOf(obj));
                }
            }
            system.debug('bccaddress>>' + bccaddress);
        }

        //List<Id> attachmentls = null;
        List < Map < String, String >> attachmentobj = null;
        if (tempComposeEmail.containsKey('attachment') && tempComposeEmail.get('attachment') != null && ((List < object > ) tempComposeEmail.get('attachment')).size() > 0) {
            List < Object > lst = ((List < Object > ) tempComposeEmail.get('attachment'));
            attachmentobj = new List < Map < String, String >> ();
            System.debug('@@@@ lst : ' + lst);
            for (Object obj: lst) {
                if (obj != null) {
                    Map < String, Object > tmp = (Map < String, Object > ) obj;
                    System.debug('@@@@ tmp : ' + tmp);
                    if (tmp != null && !tmp.isEmpty()) {
                        Map < String, String > attachment = new Map < String, String > ();
                        for (String key: tmp.keySet()) {
                            System.debug('@@@@ tmp key : ' + key);
                            System.debug('@@@@ tmp val: ' + tmp.get(key));
                            attachment.put(key, (String) tmp.get(key));
                        }
                        attachmentobj.add(attachment);
                    }
                }
            }
        }

        String htmlBody;
        if (tempComposeEmail.containsKey('body') && tempComposeEmail.get('body') != null) {
            htmlBody = String.valueOf(tempComposeEmail.get('body'));
            system.debug('htmlBody>>' + htmlBody);
        } else {
            throw new celsrm.GOGDataServiceLoadException('Please enter value into body');
        }

        id parentId = null;
        if (inMap.containsKey('Id') && inMap.get('Id') != null) {
            parentId = (Id) inMap.get('Id');
            system.debug('parentId>>' + parentId);
        }

        // celsrm.GOGEmailMapper.sendEmail(fromId, Toaddress, subject, htmlBody, null, ccaddress, bccaddress, attachmentobj, parentId);

        celsrm.GOGEmailMapper.SendEmailBean emailBean = new celsrm.GOGEmailMapper.SendEmailBean();
        emailBean.owea = fromId;
        emailBean.to = Toaddress;
        emailBean.subject = subject;
        emailBean.htmlBody = htmlBody;
        emailBean.plainTextBody = null;
        emailBean.cc = ccaddress;
        emailBean.bcc = bccaddress;
        emailBean.attachment = attachmentobj;
        emailBean.parentId = parentId;
        emailBean.followUpTaskDueDate = null;
        celsrm.GOGEmailMapper.sendEmailWithBean(emailBean);
        
        return inMap;
    }
}