global with sharing class CustomerSupportClass implements celsrm.GOGIScreenCustomLogic {
    global Map<Object, Object> invoke(String functionName, Map<Object, Object> inMap) {
        try {
            if (functionName == 'ExtractData') {
                inMap = ExtractData(inMap);
            } else if (functionName == 'SendEmail') {
                inMap = SendEmail(inMap);
            }
        } catch (Exception ex) {
            String errorMessage = 'ClassName: CustomerSupportClass | Method: invoke() | Linenumber: ' + ex.getLineNumber() + ' | Message: ' + ex.getMessage();
            System.debug('errorMessage: ' + errorMessage);
        }
        return inMap;
    }
    
    public static Map<Object, Object> ExtractData(Map<Object, Object> inMap){
        try {
            Organization o = [SELECT Id, Name FROM Organization LIMIT 1];
            inMap.put('Company', o.Name);
            
            Id uId = UserInfo.getUserId();
            User u = [SELECT Id, Name, Email, Phone, MobilePhone FROM User WHERE Id =: uId];
            inMap.put('From', u.Name);
            inMap.put('EmailAddress', u.Email);
            if (u.MobilePhone != null && u.MobilePhone != '') {
                inMap.put('ContactNumber', u.MobilePhone);
            } else if (u.Phone != null && u.Phone != '') {
                inMap.put('ContactNumber', u.Phone);
            }
        } catch (Exception ex) {
            String errorMessage = 'ClassName: CustomerSupportClass | Method: ExtractData() | Linenumber: ' + ex.getLineNumber() + ' | Message: ' + ex.getMessage();
            System.debug('errorMessage: ' + errorMessage);
        }
        return inMap;
    }
    
    public static Map<Object, Object> SendEmail(Map<Object, Object> inMap){
        try {
            System.debug('into CustomerSupportClass');
            String uniqueNumber = generateUniqueNumber();
            inMap.put('uniqueNumber', uniqueNumber);
            
            Messaging.SingleEmailMessage sailfinMessage = new Messaging.SingleEmailMessage();
            List<String> to = new List<String>();
            to.add('support@sailfin.tech');
            sailfinMessage.setToAddresses(to);
            
            List<String> bcc = new List<String>();
            bcc.add('hitesh.patel@sftpl.com');
            sailfinMessage.setBccAddresses(bcc);
            
            String subject = 'Support-ticket - #' + uniqueNumber + ' - ' + String.valueOf(inMap.get('Company'));
            sailfinMessage.setSubject(subject);
            
            String ContactNumber = '';
            if (String.valueOf(inMap.get('ContactNumber')) != null && String.valueOf(inMap.get('ContactNumber')) != '') {
                ContactNumber = String.valueOf(inMap.get('ContactNumber'));
            }
            
            String htmlBody = '<table style="border-collapse: collapse;" border="1"><tr><td><b>From</b></td><td>' + String.valueOf(inMap.get('From')) + '</td></tr><tr><td><b>Contact Number</b></td><td>' + ContactNumber + '</td></tr><tr><td><b>Email Address</b></td><td>' + String.valueOf(inMap.get('EmailAddress')) + '</td></tr><tr><td><b>Company</b></td><td>' + String.valueOf(inMap.get('Company')) + '</td></tr><tr><td><b>Issue severity</b></td><td>' + String.valueOf(inMap.get('IssueSeverity')) + '</td></tr><tr><td><b>Brief Description of the issue</b></td><td>' + String.valueOf(inMap.get('IssueBriefDescription'));
            if (String.valueOf(inMap.get('ErrorMessage')) != null && String.valueOf(inMap.get('ErrorMessage')) != '') {
                htmlBody = htmlBody + '</td></tr><tr><td><b>Error message displayed</b></td><td>' + String.valueOf(inMap.get('ErrorMessage'));
            }
            if (String.valueOf(inMap.get('IssueReproduceSteps')) != null && String.valueOf(inMap.get('IssueReproduceSteps')) != '') {
                htmlBody = htmlBody + '</td></tr><tr><td><b>Steps to reproduce the issue</b></td><td>' + String.valueOf(inMap.get('IssueReproduceSteps'));
            }
            htmlBody = htmlBody + '</td></tr></table>';
            System.debug('htmlBody>>>' + htmlBody);
            sailfinMessage.setHtmlBody(htmlBody);
            
            List<Object> Attachment = (List<Object>)inMap.get('Attachment');
            System.debug('Attachment>>>' + Attachment);
            if (Attachment != null && Attachment.size() > 0) {
                List<String> listOfFileAttachment = new List<String>();
                for(Object att: Attachment){
                    Map<Object, Object> obj = (Map<Object, Object>)att;
                    if (obj != null) {
                        if (obj.get('ContentDocumentId') != null && obj.get('ContentDocumentId') != '') {
                            Id fileId = (Id)obj.get('ContentDocumentId');
                            listOfFileAttachment.add(fileId);
                        }
                    }
                }
                System.debug('listOfFileAttachment>>>' + listOfFileAttachment);
                List<String> contentVersionId = new List<String>();
                if(!listOfFileAttachment.isEmpty()){
                    for(ContentVersion a : [Select Id, ContentDocumentId FROM ContentVersion WHERE ContentDocumentId IN: listOfFileAttachment]){
                        contentVersionId.add(String.valueOf(a.Id));
                    }
                }
                System.debug('contentVersionId>>>' + contentVersionId);
                sailfinMessage.setEntityAttachments(contentVersionId);
            }
            System.debug('sailfinMessage>>>' + sailfinMessage);
            Messaging.SendEmailResult[] sailfinResults = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {sailfinMessage});
            System.debug('sailfinResults>>>' + sailfinResults);
            for (Messaging.SendEmailResult ser : sailfinResults) {
                System.debug('Email result ' + ser.IsSuccess());
                if (!ser.IsSuccess()) {
                    inMap.put('ggErrorMessage', 'Please Contact System Administration');
                    inMap.put('returnResult', false);
                }
            }
            
            Messaging.SingleEmailMessage userMessage = new Messaging.SingleEmailMessage();
            OrgWideEmailAddress orgEmail = [SELECT Id, Address FROM OrgWideEmailAddress WHERE Address = 'support@sailfin.tech' LIMIT 1];
            if (orgEmail.Id != null) {
                userMessage.setOrgWideEmailAddressId(orgEmail.Id);
            }
            
            List<String> uto = new List<String>();
            uto.add(String.valueOf(inMap.get('EmailAddress')));
            userMessage.setToAddresses(uto);
            
            List<String> ucc = new List<String>();
            ucc.add('support@sailfin.tech');
            userMessage.setCcAddresses(ucc);
            
            String uSubject = 'Support ticket - #' + uniqueNumber;
            userMessage.setSubject(uSubject);
            
            String userHtmlBody = '<p>Thank you for taking the time to write to us. We will get on it right away and get back to you shortly.<br />For urgent inquiries please call us on +1 408 475 7752 or write to us at <a href="mailto:support@sailfin.tech">support@sailfin.tech</a></p><br /><p>Regards</p><p>Sailfin Technologies<br /><a href="https://www.sailfin.tech" target="_blank">https://www.sailfin.tech</a></p>';
            System.debug('userHtmlBody>>>' + userHtmlBody);
            userMessage.setHtmlBody(userHtmlBody);
            
            Messaging.SendEmailResult[] userResults = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {userMessage});
            for (Messaging.SendEmailResult ser : userResults) {
                System.debug('Email result ' + ser.IsSuccess());
                if (!ser.IsSuccess()) {
                    inMap.put('ggErrorMessage', 'Please Contact System Administration');
                    inMap.put('returnResult', false);
                }
            }
            
        } catch (Exception ex) {
            String errorMessage = 'ClassName: CustomerSupportClass | Method: SendEmail() | Linenumber: ' + ex.getLineNumber() + ' | Message: ' + ex.getMessage();
            System.debug('errorMessage: ' + errorMessage);
        }
        return inMap;
    }
    
    public static String generateUniqueNumber(){
        Double s = 99999999;
        Double d = math.random() * s;
        Set<Integer> alreadyUsed = new Set<Integer>();

        Integer randomNum;
        do {
            randomNum = (Integer)d;
            //added "randomNum <= 0" if random number is generated with negative value
        } while ( alreadyUsed.contains(randomNum) || randomNum <= 0 );
        alreadyUsed.add(randomNum);
        system.debug('******Unique Number****' + randomNum);
        
        return randomNum + '';
    }
}