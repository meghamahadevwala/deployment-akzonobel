@isTest
public with sharing class PromiseToPayActionControllerTest {
    @isTest
    static void myUnitTest() {
        Map<Object, Object> inMap = new Map<Object, Object>();

        Account account = DataGenerator.insertAccount();
        celsrm__Transaction__c trans = DataGenerator.insertTransaction(account);

        celsrm__Custom_List_View__c customListView = DataGenerator.insertCustomListView(true);
        // EmailMessage emailMessage = DataGenerator.insertEmailMsg(account.Id);        

        // emailMessage.celsrm__Classification_Response__c = '{ "entities": [ { "dim": "invoice_no", "value": "'+trans.Name+'" }, 		{ "dim": "email", "value": { "dim": "email", "value": "testTo1@mail.com" } } ] }';
        // update emailMessage;
        customListView.celsrm__User__c = UserInfo.getUserId();
        update customListView;

        Map<Object, Object> transMap = new Map<Object, Object>();
        transMap.put('Id', trans.Id);
        transMap.put('celsrm__Account__c', trans.celsrm__Account__c);
        transMap.put('celsrm__Balance__c', trans.celsrm__Balance__c);
        transMap.put('celsrm__Amount__c', trans.celsrm__Amount__c);
        transMap.put('celsrm__Promised_Amount__c', trans.celsrm__Promised_Amount__c);
        // transMap.put('DisputeAmount', 1000);
        // transMap.put('disputeType', 'Billing');
        // transMap.put('reasonCode', 'Tax rate incorrect');
        transMap.put('totalSLADays', 2);
        transMap.put('disputeAmount', 200);

        inMap.put('TransactionList', new List<Map<Object, Object>>{transMap});
        inMap.put('Id', account.Id);
        inMap.put('isFollowUp', true);
        inMap.put('notifyCustomer', true);

        DateTime todayDate = System.today();
        inMap.put('FollowUpDate', todayDate.format('yyyy-MM-dd'));
        inMap.put('NoteBody', 'Test note');
        inMap.put('ComposeEmail', new Map<String, Object>{});

        // Map<Object, Object> activityData = new Map<Object, Object>();
        // activityData.put('Id', emailMessage.Id);
        // inMap.put('activityData', activityData);
        PromiseToPayActionController promiseToPayActionController = new PromiseToPayActionController();
        
        promiseToPayActionController.invoke('onLoadPromiseToPay', inMap);
        promiseToPayActionController.invoke('onSavePromiseToPay', inMap);
        promiseToPayActionController.invoke('getTransactionList', inMap);
        promiseToPayActionController.invoke('onSubmitReversePromise', inMap);

        inMap.put('Id', trans.Id);
        inMap.put('calledFromTransactionDetailScreen', true);
        promiseToPayActionController.invoke('onLoadPromiseToPay', inMap);
        promiseToPayActionController.invoke('onSavePromiseToPay', inMap);
        promiseToPayActionController.invoke('getTransactionList', inMap);
        
        promiseToPayActionController.invoke('validateReversePromise', inMap);
        

        Map<Object,Object> tempComposeEmail = new Map<Object,Object>();
        List<Object> ObjList1 = new List<Object>();
        Map<String,Object> objMap1 = new Map<String,Object>();
        objMap1.put('value','value');
        objMap1.put('isSelected', true);
        objList1.add(objMap1);
        tempComposeEmail.put('from', account.Id);
        tempComposeEmail.put('to', objList1);
        tempComposeEmail.put('subject', 'subject@mail.com');
        tempComposeEmail.put('cc', objList1);
        tempComposeEmail.put('bcc', objList1);
        tempComposeEmail.put('body', 'body{Promise.summary}'); 
        inMap.put('ComposeEmail', tempComposeEmail);
        inMap.put('SummaryFields', 'Name,celsrm__Create_Date__c,celsrm__Balance__c,celsrm__Base_Balance__c,celsrm__Promise_Date__c,celsrm__Promised_Amount__c');
        promiseToPayActionController.invoke('previewPromiseEmail', inMap);
    }

    @isTest
    static void myUnitTest2() {
        Map<Object, Object> inMap = new Map<Object, Object>();

        Account account = DataGenerator.insertAccount();
        celsrm__Transaction__c trans = DataGenerator.insertTransaction(account);

        celsrm__Custom_List_View__c customListView = DataGenerator.insertCustomListView(true);
        EmailMessage emailMessage = DataGenerator.insertEmailMsg(account.Id);        

        // emailMessage.celsrm__Classification_Response__c = '{ "entities": [ { "dim": "invoice_no", "value": "'+trans.Name+'" }, 		{ "dim": "email", "value": { "dim": "email", "value": "testTo1@mail.com" } } ] }';
        // update emailMessage;
        customListView.celsrm__User__c = UserInfo.getUserId();
        update customListView;

        Map<Object, Object> transMap = new Map<Object, Object>();
        transMap.put('Id', trans.Id);
        transMap.put('celsrm__Account__c', trans.celsrm__Account__c);
        transMap.put('celsrm__Balance__c', trans.celsrm__Balance__c);
        transMap.put('celsrm__Amount__c', trans.celsrm__Amount__c);
        transMap.put('celsrm__Promised_Amount__c', trans.celsrm__Promised_Amount__c);
        // transMap.put('DisputeAmount', 1000);
        // transMap.put('disputeType', 'Billing');
        // transMap.put('reasonCode', 'Tax rate incorrect');
        transMap.put('totalSLADays', 2);
        transMap.put('disputeAmount', 200);

        inMap.put('TransactionList', new List<Map<Object, Object>>{transMap});
        inMap.put('Id', account.Id);
        inMap.put('isFollowUp', true);
        inMap.put('notifyCustomer', true);

        DateTime todayDate = System.today();
        inMap.put('FollowUpDate', todayDate.format('yyyy-MM-dd'));
        inMap.put('NoteBody', 'Test note');
        inMap.put('ComposeEmail', new Map<String, Object>{});

        Map<Object, Object> activityData = new Map<Object, Object>();
        activityData.put('Id', emailMessage.Id);
        inMap.put('activityData', activityData);
        PromiseToPayActionController promiseToPayActionController = new PromiseToPayActionController();
        
        promiseToPayActionController.invoke('onLoadPromiseToPay', inMap);
        promiseToPayActionController.invoke('onSavePromiseToPay', inMap);
        promiseToPayActionController.invoke('getTransactionList', inMap);
        promiseToPayActionController.invoke('onSubmitReversePromise', inMap);

        inMap.put('Id', trans.Id);
        inMap.put('calledFromTransactionDetailScreen', true);
        promiseToPayActionController.invoke('onLoadPromiseToPay', inMap);
        promiseToPayActionController.invoke('onSavePromiseToPay', inMap);
        promiseToPayActionController.invoke('getTransactionList', inMap);
        
        promiseToPayActionController.invoke('validateReversePromise', inMap);
        

        Map<Object,Object> tempComposeEmail = new Map<Object,Object>();
        List<Object> ObjList1 = new List<Object>();
        Map<String,Object> objMap1 = new Map<String,Object>();
        objMap1.put('value','value');
        objMap1.put('isSelected', true);
        objList1.add(objMap1);
        tempComposeEmail.put('from', account.Id);
        tempComposeEmail.put('to', objList1);
        tempComposeEmail.put('subject', 'subject@mail.com');
        tempComposeEmail.put('cc', objList1);
        tempComposeEmail.put('bcc', objList1);
        tempComposeEmail.put('body', 'body{Promise.summary}'); 
        inMap.put('ComposeEmail', tempComposeEmail);
        inMap.put('SummaryFields', 'Name,celsrm__Create_Date__c,celsrm__Balance__c,celsrm__Base_Balance__c,celsrm__Promise_Date__c,celsrm__Promised_Amount__c');
        promiseToPayActionController.invoke('previewPromiseEmail', inMap);
    }
}