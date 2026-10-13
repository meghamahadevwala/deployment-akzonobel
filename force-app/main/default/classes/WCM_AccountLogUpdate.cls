global with sharing class WCM_AccountLogUpdate implements celsrm.GOGIScreenCustomLogic {
    global Map<Object, Object> invoke(String functionName, Map<Object, Object> inMap) {
        System.debug('into GOGCustomImplementation');
        System.debug('functionName ::: ' + functionName);
        System.debug('inMap ::: ' + inMap);
        inMap.put('VendorName','adding new value');
        String AccId = (String)inMap.get('WhatId');
        if( AccId ==null || AccId ==''){
            AccId = (String)inMap.get('Id');
        }
        
        //update collection rating field on Account
        if(AccId != null || AccId != ''){
            Account CurrentAcc = [select id, Name from Account where id =: AccId]; // Neesd to add 'celsrm__Contact_method__c' field
            CurrentAcc.celsrm__Last_Contact_Date__c = date.Today(); 
            CurrentAcc.celsrm__Last_Contact_Type__c = (string)inMap.get('screenName');
            CurrentAcc.celsrm__Last_Contact_Method__c = (string)inMap.get('ContactMethod');
            
            if(CurrentAcc != null){            
                System.debug('CurrentAcc>>'+CurrentAcc);
                update CurrentAcc;            
            }
        }
        return inMap;
        
    }
    
}