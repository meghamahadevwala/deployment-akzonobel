@isTest
public with sharing class FetchOpenTrxnTest {
    public static testMethod void FetchOpenTrxnTest() {
        Account acc = DataGenerator.insertAccount();
        List<celsrm__Transaction__c> transList = DataGenerator.transactionInsert(acc, 2);
        Map<Object,Object> inMap = new Map<Object,Object>();
        inMap.put('Id',acc.Id);
        
        Map<Object, Object> aData = new Map<Object,Object>();
        Map<Object, Object> bData = new Map<Object,Object>();
        List<Object> cList = new List<Object>();
        Map<Object, Object> cData = new Map<Object,Object>();
        List<String> sList = new List<String>();
        cData.put('entity','invoice_no');
        cData.put('start',1);
        cData.put('end',1);
        cList.add(cData);
        bData.put('entities',cList);
        bData.put('text','text');
        aData.put('Classification_Response__c',JSON.serialize(bData));
        inMap.put('activityData',aData);        
        try{
           FetchOpenTrxn fetchOpen = new FetchOpenTrxn();
           fetchOpen.invoke('', inMap); 
        }catch(Exception e){
            system.debug('Exception caused>>>>'+e.getLineNumber() + e.getMessage() );
        }
    }
}