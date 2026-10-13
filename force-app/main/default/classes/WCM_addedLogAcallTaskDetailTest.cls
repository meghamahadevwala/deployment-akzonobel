@isTest
public with sharing class WCM_addedLogAcallTaskDetailTest {
    public static testMethod void WCM_addedLogAcallTaskDetailTest() {
        Account acc = DataGenerator.insertAccount();
        List<Task> tList = DataGenerator.insertTask(acc, 1);
        Map<Object,Object> inMap = new Map<Object,Object>();
        inMap.put('Id',acc.Id);
        inMap.put('ScreenName','TaskEditScreen');
        inMap.put('TaskId',tList.get(0).Id);
        Map<Object,Object> inMap1 = new Map<Object,Object>();
        inMap1.put('ScreenName','test');
        inMap1.put('WhatId',acc.Id);
        inMap1.put('Account_Name__c',acc.Name);
        try{
           WCM_addedLogAcallTaskDetail test = new WCM_addedLogAcallTaskDetail();
           test.invoke('', inMap); 
           test.invoke('', inMap1);
        }catch(Exception e){
            system.debug('Exception caused>>>>'+e.getLineNumber() + e.getMessage() );
        }
    }
}