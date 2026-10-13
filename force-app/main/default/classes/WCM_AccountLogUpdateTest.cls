@isTest
public with sharing class WCM_AccountLogUpdateTest {
    public static testMethod void WCM_AccountLogUpdateTest() {
        try{
            Account acc = DataGenerator.insertAccount();
            Map<Object,Object> objMap = new Map<Object,Object>();
            objMap.put('WhatId',acc.Id);
            objMap.put('screenName','test');
            objMap.put('ContactMethod','test');
            WCM_AccountLogUpdate ALU = new WCM_AccountLogUpdate();
            ALU.invoke('', objMap);
        }catch(Exception e){
            system.debug('Exception caused>>>>'+e.getLineNumber() + e.getMessage() );
        }
        try{
            Map<Object,Object> objMap1 = new Map<Object,Object>();
            objMap1.put('WhatId',null);
            WCM_AccountLogUpdate ALU = new WCM_AccountLogUpdate();
            ALU.invoke('', objMap1);
        }catch(Exception e){
            system.debug('Exception caused>>>>'+e.getLineNumber() + e.getMessage() );
        }
    }
}