global with sharing class DunningFetchAllDefaultContact implements celsrm.GOGIScreenCustomLogic {
    global Map<Object, Object> invoke(String functionName, Map<Object, Object> inMap){
        system.debug('============='+inMap);
        String Id ='';
        if( inMap.containsKey('rowValues')){
            Map < Object, Object > m = (Map < Object, Object > )inMap.get('rowValues');
            system.debug('===m=========='+m);
            Id  = (String) m.get('AccountId');  
        }else{
            Id = (String)inMap.get('Id');
        }
         
        List<Contact> conList = new List<Contact>();
        Map<id,Contact> mapContact= new map<id,Contact>([Select Id,email,Name,celsrm__Default__c From Contact where AccountId =: Id]);
        List<Map<String,String>> response = new List<Map<String,String>>();
        List<Map<String,String>> finalResponse = new List<Map<String,String>>();
       
        for (Contact con : mapContact.values()) {
            map<String,String> tempMap = new Map<String,String>();
            if (con.celsrm__Default__c) {
                 tempMap.put('label', con.Email);
                tempMap.put('value', con.Email);
                finalResponse.add(tempMap);
            } else {
                tempMap.put('label', con.Email);
                tempMap.put('value', con.Email);
                response.add(tempMap);
            }
        }
        
        finalResponse.addAll(response);
     
        inMap.put('dataServiceResponse', finalResponse);
        
        return inMap;
    }
}