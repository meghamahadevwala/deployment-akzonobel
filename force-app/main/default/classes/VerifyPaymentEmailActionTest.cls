@isTest
public with sharing class VerifyPaymentEmailActionTest {
     @isTest public static void invokeTest() {
        Account acc = DataGenerator.insertAccount();
        celsrm__Transaction__c trxn = DataGenerator.insertTransaction(acc);
        celsrm__Transaction__c trxn1 = DataGenerator.insertTransaction(acc);
        EmailMessage em = DataGenerator.insertEmailMsgForVerifyPayment(acc.Id);
        
        Map<Object,Object> inMap = new Map<Object,Object>();
        Map<Object, Object> bData = new Map<Object,Object>();

        bData.put('Id',em.Id);
        inMap.put('activityData',bData); 
        VerifyPaymentEmailAction payAct = new VerifyPaymentEmailAction();
        try {
            payAct.invoke('fetchTrasactionData', inMap);
        } catch (Exception e) {
            System.debug(e.getMessage());
        }
        
        List<map < Object, Object > > trxnObjList = new List<map < Object, Object > >();
        map < Object, Object > tempMap = new map < Object, Object > ();
        tempMap.put('isSelected', true);
        tempMap.put('Description', 'Not Paid');
        tempMap.put('Id', trxn.Id);
        tempMap.put('celsrm__Promised_Amount__c', 100);
        tempMap.put('celsrm__Balance__c', 200);
        tempMap.put('celsrm__Promise_Date__c', String.valueOf(Date.today().addDays(5)));
        trxnObjList.add(tempMap);
         map < Object, Object > tempMap1 = new map < Object, Object > ();
        tempMap1.put('isSelected', true);
        tempMap1.put('Description', 'Paid');
        tempMap1.put('Id', trxn1.Id);
        tempMap1.put('celsrm__Promised_Amount__c', 100);
        tempMap1.put('celsrm__Balance__c', 200);
        tempMap1.put('celsrm__Promise_Date__c', String.valueOf(Date.today().addDays(5)));
        trxnObjList.add(tempMap1);
        inMap.put('TransactionList', trxnObjList);
        inMap.put('ContactMethod', 'Email');
        inMap.put('PaidSummaryFields', 'celsrm__Balance__c,celsrm__Promised_Amount__c');
        inMap.put('OpenSummaryFields', 'celsrm__Balance__c,celsrm__Promised_Amount__c');
        list<Object> toList = new list<Object>();
        toList.add('test@test.com');
        toList.add('test12@test.com');
        toList.add('test123@test.com');
        Map<Object, Object> objMap1 = new Map<Object, Object>();
        objMap1.put('to', toList);
        objMap1.put('cc', toList);
        objMap1.put('bcc', toList);
        objMap1.put('subject', 'Testing Mail');
        objMap1.put('body', '{VerifyPayment.Summary}');


        inMap.put('ComposeEmail', objMap1);
        inMap.put('RelatedToId', acc.Id);
        inMap.put('NoteBody', 'test');
        inMap.put('NoteTitle', 'test');
        List<Task> taskList = new List<Task>();
        Task t = new Task();
        t.Subject = 'Test';
        t.Status = 'Completed';
        t.WhatId = acc.Id;
        t.TaskSubtype = 'Email';
        t.IsReminderSet = true;
        t.ReminderDateTime = Datetime.now();
        taskList.add(t);

        insert taskList;
        try {
            payAct.invoke('submitVerifyPayment', inMap);
        } catch (Exception e) {
            System.debug(e.getMessage());
        }
        
    }
}