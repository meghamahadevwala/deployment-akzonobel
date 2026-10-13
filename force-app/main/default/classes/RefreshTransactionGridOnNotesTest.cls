@isTest
public with sharing class RefreshTransactionGridOnNotesTest {
    
    @isTest
    public static void test1(){
        Account acc = DataGenerator.insertAccount();
        celsrm__Transaction__c trx = DataGenerator.insertTransaction(acc);
        RefreshTransactionGridOnNotes rs = new RefreshTransactionGridOnNotes();
        Map<Object, Object> inMap = new Map<Object, Object>();
        inMap.put('Id',trx.Id);
        inMap.put('TransactionNote','Test');
        rs.invoke('test', inMap);
    }
}