global with sharing class GOGWCMAddNote implements celsrm.GOGIScreenCustomLogic {
    global Map<Object, Object> invoke(String functionName, Map<Object, Object> inMap) {
        System.debug('into GOGCustomImplementation');
        System.debug('functionName ::: ' + functionName);
        System.debug('inMap ::: ' + inMap);       
        inMap.put('VendorName','adding new value');
        String noteBody = String.valueOf(inMap.get('NoteBody'));
        Datetime currentDateTime = Datetime.now();
        if(inMap.get('TransactionList') != null ) { 
            String str = JSON.serialize(inMap.get('TransactionList'));  
            System.debug('str ::: ' + str );     
            
            List<string> strList = str.substring(1, str.length()-1).split('}');
            List<Id> trxIdList = new List<Id>();
            set<String> trxfldList = new set<String>();
            List<celsrm__Transaction__c> trxListtoUpdate = new List<celsrm__Transaction__c>();
            
            List < object > tran = (List < object > ) inMap.get('TransactionList');
            for (Object ts: tran) {
                Map < Object, Object > m = (Map < Object, Object > ) ts;
                Id key = (String) m.get('Id');
                trxIdList.add(key); 
                
                celsrm__Transaction__c tranObj = new celsrm__Transaction__c();
                tranObj.Id = key;
                tranObj.celsrm__Latest_Note__c = noteBody;
                tranObj.celsrm__Latest_Note_Date__c = date.today();
                tranObj.celsrm__Latest_Note_Entered_By__c = UserInfo.getUserId();
                trxListtoUpdate.add(tranObj);
            }
            if(trxListtoUpdate.size() > 0) {
                update trxListtoUpdate;
            }
            if(trxIdList!= null && trxIdList.size() > 0) {     
                if(!trxIdList.isEmpty()){
                    celsrm.SRMUtilityController.insertActivity(trxIdList, 'celsrm__Transaction__c', 'Note Added', currentDateTime, 100, noteBody, UserInfo.getUserId(), null, 'Internal');
                }
            }    
        } 
        Id key =(Id)inMap.get('Id')  ;
        if (key != null){
            Account acc = new Account();
            acc.Id = key;
            acc.celsrm__Latest_Note__c = noteBody;
            acc.celsrm__Latest_Note_Date__c = date.today();
            acc.celsrm__Latest_Note_By__c = UserInfo.getUserId();
            update acc;
            List<String> accList = new List<String>();
            accList.add(key);
            celsrm.SRMUtilityController.insertActivity(accList, 'celsrm__Account__c', 'Note Added', currentDateTime, 100, noteBody, UserInfo.getUserId(), null, 'Internal');
               
        }

        Map<String, Object> refreshParentValues = new Map<String, Object>();
        if(inMap.containsKey('ListView')) {
            refreshParentValues.put('name', 'ListView');
            refreshParentValues.put('value',inMap.get('ListView'));
            refreshParentValues.put('onChangeMethod','filterDataByView');
        }
        System.debug('@@@ refreshParentValues : '  +refreshParentValues);
        inMap.put('refreshParentValues', refreshParentValues);
        return inMap;
    }
}