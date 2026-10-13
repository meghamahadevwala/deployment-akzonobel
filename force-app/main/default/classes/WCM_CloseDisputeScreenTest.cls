@isTest

public with sharing class WCM_CloseDisputeScreenTest {
    
    public static testMethod void test1(){

        Account acc = DataGenerator.insertAccount();
        celsrm__Transaction__c trans = DataGenerator.insertTransaction(acc);
        List<celsrm__Dispute__c> dispute = DataGenerator.insertDispute(trans, acc, 2);

        Map<Object, Object> inMap = new Map<Object, Object>();

        inMap.put('Id', dispute[0].Id);
        inMap.put('type', 'Billing');
        inMap.put('resolutionCode', 'Paid');
        inMap.put('noteBody', 'noteBody');
        inMap.put('noteTitle', 'noteTitle');

        WCM_CloseDisputeScreen closeDisScreen = new WCM_CloseDisputeScreen();
        closeDisScreen.invoke('SaveCloseDispute', inMap);

        closeDisScreen.invoke('FetchCloseDispute', inMap);
    }
}