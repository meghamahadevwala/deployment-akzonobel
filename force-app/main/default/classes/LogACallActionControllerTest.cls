@isTest
public with sharing class LogACallActionControllerTest {
    public static testMethod void testMethod1() {
        // Test data setup
        Account acc = DataGenerator.insertAccount();
        List<Contact> con = DataGenerator.insertContact(acc, 1);
        con[0].celsrm__Default__c = true;
        update con;

        List<Task> taskList = DataGenerator.insertTask(acc, 1);
        celsrm__Transaction__c trans = DataGenerator.insertTransaction(acc);
        List<Object> tranxList = new List<Object>();
        Map<Object,Object> tranxMap = new Map<Object,Object>();
        tranxMap.put('celsrm__Account__c', acc.Id);
        tranxMap.put('Id', trans.Id);
        tranxMap.put('isSelected', true);
        tranxList.add(tranxMap);
 
        Map<Object, Object> inMap = new Map<Object, Object>();
        inMap.put('Id', acc.Id);
        inMap.put('FollowUpDate', String.valueOf(Date.today().addDays(1)));
        inMap.put('TransactionList', tranxList);
        inMap.put('isFollowUp', true);
        LogACallActionController logACallObj = new LogACallActionController();
        // Test onLoadSendEmail
        Map<Object, Object> result = logACallObj.invoke('onLoadLogACall', inMap);
        
        con[0].Phone = '123-456-7890';
        update con;
        trans.celsrm__Disputed_Amount__c = 0;
        update trans;
        result = logACallObj.invoke('onLoadLogACall', inMap);
        System.assertNotEquals(null, taskList.get(0));

        con[0].Phone = null;
        con[0].MobilePhone = '123-456-7890';
        update con;
        trans.celsrm__Promise_Date__c = Date.today().addDays(1);
        update trans;
        result = logACallObj.invoke('onLoadLogACall', inMap);
        System.assertNotEquals(null, taskList.get(0));

        trans.celsrm__Promise_Date__c = null;
        update trans;
        result = logACallObj.invoke('onLoadLogACall', inMap);
        System.assertNotEquals(null, taskList.get(0));

        // Test createFollowUpTask
        inMap.put('calledFromTransactionDetailScreen', true);
        inMap.put('Id', trans.Id);
        inMap.put('NoteBody', 'test note');
        inMap.put('celsrm__Account__c', acc.Id);
        result = logACallObj.invoke('executeLogACall', inMap);
        System.assertNotEquals(null, taskList.get(0));

        // Map<Object, Object> transMap3 = new Map<Object, Object>();
        trans.celsrm__Promised_Amount__c = 0;
        trans.celsrm__Promise_Date__c = null;
        trans.celsrm__Disputed_Amount__c = 0;
        trans.celsrm__Due_Date__c = (datetime.now().addDays(-2)).date();
        update trans;
        result = logACallObj.invoke('onLoadLogACall', inMap);
 
    }
}