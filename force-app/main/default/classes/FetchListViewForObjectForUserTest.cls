@isTest
public with sharing class FetchListViewForObjectForUserTest {
    public static testMethod void FetchListViewForObjectForUserTest() {
        Account acc = DataGenerator.insertAccount();
        celsrm__Custom_List_View__c listView = DataGenerator.insertCustomListView(true);
        Map<Object,Object> inMap = new Map<Object,Object>();
        inMap.put('ListViewObject','celsrm__Transaction__c');
        inMap.put('ListViewParentField','celsrm__Balance__c');
        try{
            FetchListViewForObjectForUser listViewObj = new FetchListViewForObjectForUser();
            listViewObj.invoke('', inMap);
        }catch(Exception e){
            system.debug('Exception caused>>>>'+e.getLineNumber() + e.getMessage() );
        }
    }
}