@isTest
public with sharing class WCMUpdateTransactionTest {
    
    public static testMethod void WCMUpdateTransactionTest() {

        Account acc = DataGenerator.insertAccount();
        celsrm__Transaction__c trans = DataGenerator.insertTransaction(acc);
        Map<Object,Object> inMap = new Map<Object,Object>();

        List<Object> ObjList = new List<Object>();
        Map<Object,Object> objMap1 = new Map<Object,Object>();
        objMap1.put('Id',trans.Id);
        objMap1.put('PromisedAmount', 2333);
        objMap1.put('PromiseDate',System.today());
        objList.add(objMap1);

        inMap.put('TransactionList', ObjList);
        WCMUpdateTransaction updateTran = new WCMUpdateTransaction();
        updateTran.invoke('', inMap);
    }
}