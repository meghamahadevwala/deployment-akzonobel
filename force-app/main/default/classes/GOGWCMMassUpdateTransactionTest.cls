@isTest
public with sharing class GOGWCMMassUpdateTransactionTest {
    public static testMethod void GOGWCMMassUpdateTransactionTest() {
        Account acc = DataGenerator.insertAccount();
        List<celsrm__Transaction__c> transList = DataGenerator.transactionInsert(acc, 2);
        List<Object> objList = new List<Object>();
        Map<Object,Object> inMap = new Map<Object,Object>();
        Map<Object,Object> transMap = new Map<Object,Object>();
        transMap.put('Id',transList.get(0).Id);
        objList.add(transMap);
        inMap.put('Reason_Code','1 - Service Call');
        inMap.put('SO','SO');
        inMap.put('PO','PO');
        inMap.put('BillToCity','BillToCity');
        inMap.put('TransactionList',objList);
        try{
            GOGWCMMassUpdateTransaction updateTrans = new GOGWCMMassUpdateTransaction();
            updateTrans.invoke('', inMap);
        }catch(Exception e){
            system.debug('Exception caused>>>>'+e.getLineNumber() + e.getMessage() );
        }
    }
}