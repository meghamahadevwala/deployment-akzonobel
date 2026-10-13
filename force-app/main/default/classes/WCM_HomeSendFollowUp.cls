global with sharing class WCM_HomeSendFollowUp implements celsrm.GOGIScreenCustomLogic {
    global Map<Object, Object> invoke(String functionName, Map<Object, Object> inMap) {
        System.debug('into GOGCustomImplementation');
        System.debug('functionName ::: ' + functionName);
        System.debug('inMap ::: ' + inMap);
        inMap.put('VendorName','adding new value');
        //List<object> tsk = (List<object>)inMap.get('selectedTask');
        Map<Object, Object> selTask = (Map<Object, Object>)inMap.get('selectedTask');
        system.debug('====='+selTask );
        id key= (Id)selTask.get('WhatId');
        String AccName= (String)selTask.get('Account_Name__c');
        inMap.put('Id',key);
        inMap.put('Name',AccName);
        
        List<celsrm__Transaction__c>  trxList= new List<celsrm__Transaction__c>();
        String htmlBody;
        Account acc = [Select id, celsrm__Locale__c from account where Id =: key];
        inMap.put('Name',AccName);
        inMap.put('screenName','Send Statement');
        inMap.put('Locale',acc.celsrm__Locale__c);
        inMap.put('Locale',acc.celsrm__Locale__c);
        inMap.put('ListViewParentField','celsrm__account__c');
        inMap.put('ListViewObject','celsrm__Transaction__c');
        inMap.put('ListViewObject','celsrm__Transaction__c');
        inMap.put('FollowupDays', Date.Today().addDays(5));

        return inMap;
    }
}