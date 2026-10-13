global with sharing class GOGWCMMassUpdateTask implements celsrm.GOGIScreenCustomLogic {
    global Map<Object, Object> invoke(String functionName, Map<Object, Object> inMap) {
        System.debug('into GOGCustomImplementation');
        System.debug('functionName ::: ' + functionName);
        System.debug('inMap ::: ' + inMap);       
        inMap.put('VendorName','adding new value');
        
        String str = JSON.serialize(inMap.get('TaskList'));       
        List<string> strList = str.substring(1, str.length()-1).split('}');
        set<Id> trxIdList = new set<Id>();
        set<String> trxfldList = new set<String>();
        List<Task> trxListtoUpdate = new List<Task>();
        
        for(string str1 : strList){            
            string currentString;
            if(!str1.contains('}')){
                currentString = str1 + '}';
                currentString = currentString.substringBetween('{','}');
            }
            currentString = '{'+currentString+'}';
            map<string,string> m = (map<string,string>)JSON.deserialize(currentString, map<string,string>.class);   
            trxIdList.add(m.get('Id'));                      
        }
        
        if(trxIdList!= null && trxIdList.size() > 0){           
            trxListtoUpdate = [Select t.What.type,t.ownerId, t.ActivityDate,t.Account.Name, t.celsrm__Notes__c, t.WhatId, t.Type, t.SystemModstamp, t.Subject, t.Status, t.Id, t.Priority , t.Description, t.CallType, t.CallObject, t.AccountId, t.Owner.Email From Task t where id =: trxIdList];
            for(Task trxobj : trxListtoUpdate){
                trxobj.Status = (String)inMap.get('Status');
                trxobj.ownerId = (String)inMap.get('AssignedTo');
                trxobj.ActivityDate = (date)inMap.get('DueDate');
                trxobj.celsrm__dunning_status__c = (String)inMap.get('DunningStatus'); 
            }
            
            update trxListtoUpdate;
        }
        
        return inMap;
    }
}