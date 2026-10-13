@isTest
public with sharing class WCM_HomeSendFollowUpTest {
    public static testMethod void WCM_HomeSendFollowUpTest() {
        Account acc = DataGenerator.insertAccount();
        Map<Object, Object> selTask = new Map<Object, Object>();
        selTask.put('WhatId',acc.Id);
        selTask.put('Account_Name__c',acc.Name);
        Map<Object, Object> inMap = new Map<Object, Object>();
        inMap.put('selectedTask',selTask);
        try{
            WCM_HomeSendFollowUp sendFollowUp = new WCM_HomeSendFollowUp();
            sendFollowUp.invoke('', inMap);
        }catch(Exception e){
            system.debug('Exception caused>>>>'+e.getLineNumber() + e.getMessage() );
        }
    }
}