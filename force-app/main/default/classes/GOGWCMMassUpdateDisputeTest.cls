@isTest
public with sharing class GOGWCMMassUpdateDisputeTest {
    public static testMethod void GOGWCMMassUpdateDisputeTest() {
        try{
            Account ac = DataGenerator.insertAccount();
            celsrm__Transaction__c trxn = DataGenerator.insertTransaction(ac);
            List<celsrm__Dispute__c> dsList = DataGenerator.insertDispute(trxn,ac,2);
            celsrm__Custom_List_View__c listView = DataGenerator.insertCustomListView(true);
            List<Object> ObjList = new List<Object>();
            Map<Object,Object> inMap = new Map<Object,Object>();
            Map<Object,Object> disMap = new Map<Object,Object>();
            disMap.put('Id',dsList.get(0).Id);
            disMap.put('Amount',100);
            disMap.put('type','Billing');
            disMap.put('SubType','Duplicate Credit');
            disMap.put('Status','Open');
            ObjList.add(disMap);
            inMap.put('ListView',listView);
            inMap.put('DisputeGrid',ObjList);
            GOGWCMMassUpdateDispute MUD = new GOGWCMMassUpdateDispute();
            MUD.invoke('', inMap);
        }catch(Exception e){
            system.debug('Exception caused>>>>'+e.getLineNumber() + e.getMessage() );
        }
    }
}