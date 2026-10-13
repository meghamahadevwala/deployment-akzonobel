@isTest
public with sharing class SendStatementOnAccountTest {
    public static testMethod void SendStatementOnAccountTest() {
        
        Map<Object, Object> inMap = new Map<Object, Object>();

        User thisUser = [select Id from User where Id =: UserInfo.getUserId()];
        System.runAs(thisUser) {
            Account acc = DataGenerator.insertAccount();
            celsrm__Custom_List_View__c listView = DataGenerator.insertCustomListView(true);
            celsrm__Transaction__c trans = DataGenerator.insertTransaction(acc);
            EmailTemplate temp = [Select Name From EmailTemplate LIMIT 1];
            System.debug('temp>>>>'+temp.Name);

            List<Object> ObjList = new List<Object>();
            Map<Object,Object> objMap1 = new Map<Object,Object>();
            objMap1.put('Id',acc.Id);
            objList.add(objMap1);
            
            
            inMap.put('Id', acc.Id);
            inMap.put('TransactionList', ObjList);
            inMap.put('StatementFormat', 'PDF');
            inMap.put('ListView', listView.Id);

            Map<Object,Object> objMap2 = new Map<Object,Object>();
            objMap2.put('Id',acc.Id);
            objList.add(objMap2);
            SendStatementOnAccount send1 = new SendStatementOnAccount();

            inMap.put('StatementFormat', 'Excel');           
            
            try{
                inMap.put('AttachCheckBox', true);
                inMap.put('preview', true);
                send1.invoke('changeListView', inMap);
            } catch(NullPointerException ex) {
                System.debug('NullPointerException one>>' +  ex);
            }
            try {
                inMap.put('screenName', 'Send Statement');
                inMap.put('TransactionList', null);
                send1.invoke('changeListView', inMap);
            } catch (NullPointerException ex) {
                System.debug('NullPointerException two>>' +  ex);
            }

            List<celsrm__Transaction__c> transList = DataGenerator.transactionInsert(acc, 2);
            String trxnId = transList[0].Id + ',' + transList[1].Id;

            inMap.put('trxnId', trxnId);
            inMap.put('AttachCheckBox', true);
            inMap.put('preview', true);
            inMap.put('IsIncludeChild', true);

            send1.invoke('contactCustomerPreview', inMap);
            send1.invoke('exportAll', inMap);
            try{
                send1.invoke('', inMap);
            } catch (Exception ex){
                System.debug('exception '+ex);
            }
        }    
    }
}