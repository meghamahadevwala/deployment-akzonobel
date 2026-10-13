@isTest
public with sharing class PromiseReversalControllerTest {
    @isTest
    public static void test1(){
        Account acc = DataGenerator.insertAccount();
        celsrm__Transaction__c trans = DataGenerator.insertTransaction(acc);

        Map<Object, Object> inMap = new Map<Object, Object>();
        List<Object> tranxList = new List<Object>();
        inMap.put('Id',acc.Id);
        Map<Object, Object> transMap = new Map<Object, Object>();
        Date promiseDate = Date.newInstance(2024, 3, 8);
        transMap.put('Id', trans.Id);
        transMap.put('invoiceId', trans.Id);
        transMap.put('celsrm__Account__c', trans.celsrm__Account__c);
        transMap.put('celsrm__Balance__c', trans.celsrm__Balance__c);
        transMap.put('celsrm__Amount__c', trans.celsrm__Amount__c);
        transMap.put('celsrm__Promised_Amount__c', trans.celsrm__Promised_Amount__c);
        transMap.put('celsrm__Disputed_Amount__c', 1000);
        transMap.put('celsrm__Promise_Date__c', promiseDate );
        transMap.put('celsrm__Is_Broken_Promise__c', 100 );
        transMap.put('disputeType', 'Billing');
        transMap.put('reasonCode', 'Tax rate incorrect');
        transMap.put('totalSLADays', 2);
        transMap.put('isSelected', 'true');
        tranxList.add(transMap);
        inMap.put('TransactionList', tranxList);
        inMap.put('promiseList', tranxList);
        PromiseReversalController prc = new PromiseReversalController();
        prc.invoke('getTransactionList', inMap);
        prc.invoke('onSubmitReversePromise', inMap);
        
    }
}