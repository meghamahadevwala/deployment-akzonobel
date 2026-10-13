// << START - MM - FIN-8439 - Mailbox filter on My Emails>>
global with sharing class FetchMailBoxForUser implements celsrm.GOGIScreenCustomLogic{
    global Map<Object, Object> invoke(String functionName, Map<Object, Object> inMap) {
        String currUser = UserInfo.getUserId();
        User currUserObj = [SELECT Id, Mailbox_Access__c FROM User WHERE Id = :currUser]; // Mailbox_Access__c is a multi-select picklist field in User object
        List<String> mailboxAccess = new List<String>();
        if(currUserObj.Mailbox_Access__c != null && currUserObj.Mailbox_Access__c != ''){
            mailboxAccess = currUserObj.Mailbox_Access__c.split(';');
        }
        // List<String> mailboxAccess = currUserObj.Mailbox_Access__c.split(',');
        List<String> mailboxIds = new List<String>();
        List<Map<String,String>> returnOptions = new List<Map<string,String>>();
        Map<String,String> tmp;
        for(String mailbox : mailboxAccess){
            tmp = new Map<String,String>();
            tmp.put('label', mailbox);
            tmp.put('value', mailbox);
            returnOptions.add(tmp);
        }
        inMap.put('dataServiceResponse', returnOptions);
        return inMap;
    }
}
// << END - MM - FIN-8439 - Mailbox filter on My Emails>>