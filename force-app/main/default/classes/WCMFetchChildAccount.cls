global with sharing class WCMFetchChildAccount implements celsrm.GOGIScreenCustomLogic {
    global Map<Object, Object> invoke(String functionName, Map<Object, Object> inMap){
        if (functionName == 'createNameLink') {
            List<Object> accList = (List<Object>)inMap.get('dataServiceResponse');
            Set<Id> accId = new Set<Id>();
            if (inMap.get('ChildAccount') != null) {
                List<Object> oldAccList = (List<Object>)inMap.get('ChildAccount');
                for (Object acc : oldAccList) {
                    if (acc != null) {
                        Map<Object,Object> tempMap = (Map<Object,Object>)acc;
                        if (tempMap.get('Id') != null) {
                            accId.add((Id)tempMap.get('Id'));    
                        }
                    }
                }
            }
            
            if (accList != null) {
                List<Object> newResponse = new List<Object>();
                for (Object acc : accList) {
                    Map<String,Object> tempMap = (Map<String,Object>)acc;
                    String name = String.valueOf(tempMap.get('accountName'));
                    Id accountid= (Id)tempMap.get('Id');
                    String key = '<a href="' + '/'+ accountid + '"' + ' target="_blank">' + name + '</a>';
                    tempMap.put('Name',key);
                    if(accId.contains(accountid)) {
                        tempMap.put('isSelected', true);
                    }
                    newResponse.add(tempMap);
                }
                inMap.put('dataServiceResponse', newResponse);   
            }
                     
        }
        //  else if(functionName == 'fetchChildAccount') {
        //         SearchClass sc = new SearchClass();
        //         inMap = sc.invoke('child', inMap);
        // } 
        else if(functionName == 'checkChildAccount') {
            string accId = (String)inMap.get('Id');
            List<Account> childAccount = [SELECT Id,Name From Account Where parentId = :accId];
            if(childAccount == null || childAccount.size() == 0) {
                inMap.put('showChildAccountButton','false');
            }
        }       
        return inMap;
    }
}