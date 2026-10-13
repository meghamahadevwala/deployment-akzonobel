@isTest
public with sharing class FetchCustomerCommunicationTest {
    
    @isTest
    public static void testGetRecord(){

        Account acc = DataGenerator.insertAccount();
        Contact con = DataGenerator.insertContact(acc, 1).get(0);

        celsrm__Transaction__c tran = new celsrm__Transaction__c();
        tran.celsrm__Account__c = acc.id;
        tran.celsrm__Balance__c = 72403;
        tran.celsrm__Amount__c = 72403;
        // tran.celsrm__Batch_Number__c = 'SAP20160726';
        // tran.celsrm__DPD__c = 20;
        //tran.celsrm__DPD__c = 20;

        insert tran;

        Customer_Communication__c cc = new Customer_Communication__c();
        cc.Account__c = acc.id;
        cc.Call_Recording_Link__c = 'test';
        cc.Called_To__c = con.Id;
        cc.Call_Transcript__c = 'Hello. Good morning';
        
        cc.Phone__c = '+919276655362';
        cc.Screen_Name__c = 'Contact Customer';

        String tranList = '{"transactions":["' +  tran.Id +  '"]}';
        cc.Transactions__c = tranList;
        cc.Contact_Type__c = 'Call';
        cc.Classification_Response__c = 'test';
        cc.CategoryPlain__c = 'Call';
        insert cc;
        List<Object> CustomerCommunicationGrid = new List<Object>();
        Map<Object,Object> ccMap = new Map<Object,Object>();
        ccMap.put('TransactionsId',tranList);
        ccMap.put('Account__c',acc.id);
        ccMap.put('Call_Recording_Link__c','test');
        ccMap.put('Screen_Name__c','Contact Customer');
        CustomerCommunicationGrid.add(ccMap);
        Map<Object, Object> inMap = new Map<Object, Object>();
        inMap.put('Id', acc.Id);
        inMap.put('TransactionsId', tranList);
        inMap.put('CustomerCommunicationGrid', CustomerCommunicationGrid);
        inMap.put('gogGridIndex', 0);
        
        
        Map<Object, Object> deleteMap = new Map<Object, Object>();
        deleteMap.put('Id', cc.Id);
        Test.startTest();
            new FetchCustomerCommunication().invoke('',inMap); 
            new FetchCustomerCommunication().invoke('getTransactions',inMap); 
            
            new FetchCustomerCommunication().invoke('removeCommunication',deleteMap); 
        Test.stopTest();
    }
}