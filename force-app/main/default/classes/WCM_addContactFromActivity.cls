global with sharing class WCM_addContactFromActivity implements celsrm.GOGIScreenCustomLogic {
    global Map<Object, Object> invoke(String functionName, Map<Object, Object> inMap) {
        inMap.put('VendorName','adding new value');
        //Id AccId = (Id)inMap.get('WhatId');
        
        Contact con= new Contact();
        con.AccountId = (Id)inMap.get('Id');
        if(inMap.get('Email') != null ) {
            Con.Email = String.valueOf(inMap.get('Email'));
        }
        if(inMap.get('phone') != null ) {
            Con.Phone = String.valueOf(inMap.get('phone'));
        }
        if(inMap.get('FirstName') != null ) {
            Con.FirstName = String.valueOf(inMap.get('FirstName'));
        }
        if(inMap.get('LastName') != null ) {
            Con.LastName = String.valueOf(inMap.get('LastName'));
        }
        if(inMap.get('fax') != null ) {
            Con.fax= String.valueOf(inMap.get('fax'));
        }
        Con.celsrm__Default__c= true;
        insert con;
        
        return inMap;
    }
    
}