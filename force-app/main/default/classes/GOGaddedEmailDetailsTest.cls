@isTest
public with sharing class GOGaddedEmailDetailsTest {
    public static testMethod void GOGaddedEmailDetailsTest() {
        // EmailTemplate emTemp = DataGenerator.insertTemplate();
        Account acc = DataGenerator.insertAccount();
        List<Contact> conList = DataGenerator.insertContact(acc,2);
        celsrm__Transaction__c trans = DataGenerator.insertTransaction(acc);
        celsrm__SRM_Configuration__c WCM_Config = DataGenerator.insertWCMconfig();
        EmailTemplate template = DataGenerator.insertEmailTemplate();
        celsrm__Custom_List_View__c listView = DataGenerator.insertCustomListView(true);

        Map<Object,Object> inMap = new Map<Object,Object>();

        List<Object> tranxList = new List<Object>();
        Map<Object,Object> tranxMap = new Map<Object,Object>();
        inMap.put('Id',acc.Id);
        tranxMap.put('celsrm__Account__r', null);
        tranxList.add(tranxMap);

        inMap.put('EmailTemplateList', template.Id);
        inMap.put('TransactionList', tranxList);
        inMap.put('Attached',true);
        inMap.put('ListView', listView.Id);
        inMap.put('ggScreenName', 'WCM__SendEmailReminderSC');
        // inMap.put('EmailTemplateList',emTemp.Id);
        // 
        GOGaddedEmailDetails addedEmail = new GOGaddedEmailDetails();
        try{
            addedEmail.invoke('', inMap);
        }catch(Exception e){
            system.debug('Exception caused>>>>'+e.getLineNumber() + e.getMessage() );
        }

        try{
            inMap.put('Attached',false);
            addedEmail.invoke('', inMap);
        }catch(Exception e){
            system.debug('Exception caused>>>>'+e.getLineNumber() + e.getMessage() );
        }

    }
}