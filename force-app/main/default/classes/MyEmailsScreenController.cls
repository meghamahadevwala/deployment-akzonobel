// << START - MM - FIN-8487 - Mailbox filter on My Emails>>
global with sharing class MyEmailsScreenController implements celsrm.GOGIScreenCustomLogic {
    global Map<Object, Object> invoke(String functionName, Map<Object, Object> inMap) {
        if(functionName == 'onLoadMyEmails') {
            inMap = fetchAssignedMailBox(inMap);
        }
        return inMap;
    }
    
    public static Map<Object, Object> fetchAssignedMailBox(Map<Object, Object> inMap) {
        User user = [SELECT Id, Mailbox_Access__c FROM User WHERE Id = :UserInfo.getUserId()];
        String mailboxAccess = user.Mailbox_Access__c;
        String firstValue;
        if (mailboxAccess != null && mailboxAccess.contains(';')) {
            firstValue = mailboxAccess.split(';')[0];
        } else {
            firstValue = mailboxAccess;
        }
        inMap.put('MailboxPickList', firstValue);
        return inMap;
    }
}
// << START - MM - FIN-8487 - Mailbox filter on My Emails>>