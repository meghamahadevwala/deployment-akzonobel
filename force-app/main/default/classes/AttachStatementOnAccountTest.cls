@isTest

public with sharing class AttachStatementOnAccountTest {

    static Map<Object,Object> inMap = new Map<Object,Object>();
    static AttachStatementOnAccount statement = new AttachStatementOnAccount();

    public static testMethod void test1() {

        Account acc = DataGenerator.insertAccount();
        List<celsrm__Transaction__c> trans = DataGenerator.transactionInsert(acc,2);
        celsrm__Custom_List_View__c CLV = DataGenerator.insertCustomListView(true);
        CLV.Name = 'System Default View';
        update CLV;

        List<Object> objList = new List<Object>();
        Map<Object, Object> objMap = new Map<Object, Object>();
        objMap.put('Id', trans[0].Id);
        objList.add(objMap);
        objMap.put('Id', trans[1].Id);
        objMap.put('isSelected', true);
        objMap.put('Title', 'BillingStatement');
        objList.add(objMap);

        Map<Object, Object> objMap1 = new Map<Object, Object>();
        objMap1.put('attachment', objList);

        inMap.put('ComposeEmail', objMap1);
        inMap.put('TransactionList', objList);
        inMap.put('StatementFormat', 'PDF');
        inMap.put('ggScreenName', 'OTCPromisToPayScreenEmailAction');
        inMap.put('tempKey', 'key');
        inMap.put('ListView', null);

        statement.invoke('', inMap);
    }

    public static testMethod void test2() {

        Account acc = DataGenerator.insertAccount();
        List<celsrm__Transaction__c> trans = DataGenerator.transactionInsert(acc,2);
        celsrm__Custom_List_View__c CLV = DataGenerator.insertCustomListView(true);
        CLV.Name = 'System Default View';
        update CLV;

        List<Object> objList = new List<Object>();
        Map<Object, Object> objMap = new Map<Object, Object>();
        objMap.put('Id', trans[0].Id);
        objList.add(objMap);
        objMap.put('Id', trans[1].Id);
        objMap.put('isSelected', true);
        objMap.put('Title', 'title');
        objList.add(objMap);

        Map<Object, Object> objMap1 = new Map<Object, Object>();
        objMap1.put('attachment', objList);

        inMap.put('ComposeEmail', objMap1);
        inMap.put('TransactionList', objList);
        inMap.put('StatementFormat', 'Excel');
        inMap.put('ggScreenName', 'OTCPromisToPayScreenEmailAction');
        inMap.put('tempKey', 'key');
        inMap.put('ListView', null);

        statement.invoke('', inMap);

        // objMap1 = new Map<Object, Object>();
        // objMap1.put('attachment', objList);
        // inMap.put('ComposeEmail', objMap1);
        // statement.invoke('', inMap);

        // inMap.put('ComposeEmail', null);
        // statement.invoke('', inMap);
    }
}