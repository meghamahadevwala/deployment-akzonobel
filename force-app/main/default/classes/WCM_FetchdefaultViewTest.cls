@isTest
public with sharing class WCM_FetchdefaultViewTest {
    public static testMethod void WCM_FetchdefaultViewTest() {
        try{
            Account acc = DataGenerator.insertAccount();
            List<Task> t = DataGenerator.insertTask(acc, 2);
            celsrm__SRM_Configuration__c WCM_Config = DataGenerator.insertWCMconfig();
            celsrm__Custom_List_View__c tempListView = DataGenerator.insertCustomListView(true);
            List<Contact> conList = DataGenerator.insertContact(acc,2);
            // List<OrgWideEmailAddress> listName = [SELECT Id, Address, DisplayName FROM OrgWideEmailAddress where address=:WCM_Config.Mailbox_Email_Address__c ];
            Map<Object,Object> inMap = new Map<Object,Object>();
            inMap.put('Id',acc.Id);
            inMap.put('ListViewObject','celsrm__Transaction__c');
            inMap.put('ggScreenName','WCM_TaskGridScreen');
            inMap.put('ListView','');
            inMap.put('View','');
            WCM_FetchdefaultView defaultView = new WCM_FetchdefaultView();
            defaultView.invoke('Send Statement', inMap);
        }catch(Exception e){
            system.debug('Exception caused>>>>'+e.getLineNumber() + e.getMessage() );
        }

        // test class for WCM_FetchAccountDetails
        try{
            Account acc = DataGenerator.insertAccount();
            WCM_FetchAccountDetails.fetchStickyNotes(acc.Id);
            WCM_FetchAccountDetails.saveStickyNotes('test note', acc.Id);
            WCM_FetchAccountDetails.saveStickyNotesColor('test color', acc.Id);
            WCM_FetchAccountDetails.fetchCurrencyISOCode(acc.Id);
            WCM_FetchAccountDetails.getChartDetails(acc.Id);

        } catch(Exception ex){
            system.debug('Exception >>>>'+ex.getLineNumber() + ex.getMessage() );
        }
    }
}