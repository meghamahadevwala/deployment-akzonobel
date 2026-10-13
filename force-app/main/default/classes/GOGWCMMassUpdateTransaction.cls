global with sharing class GOGWCMMassUpdateTransaction implements celsrm.GOGIScreenCustomLogic {
    global Map<Object, Object> invoke(String functionName, Map<Object, Object> inMap) {
        System.debug('into GOGCustomImplementation');
        System.debug('functionName ::: ' + functionName);
        System.debug('inMap 11 ::: ' + inMap);     
        System.debug('@@ inMap.containsKey(ListView) : ' + inMap.containsKey('ListView'));  
        inMap.put('VendorName','adding new value');
        
      //  String str = JSON.serialize(inMap.get('TransactionList'));       
      //  List<string> strList = str.substring(1, str.length()-1).split('}');
        set<Id> trxIdList = new set<Id>();
        set<String> trxfldList = new set<String>();
        List<celsrm__Transaction__c> trxListtoUpdate = new List<celsrm__Transaction__c>();
        
       /* for(string str1 : strList){            
            string currentString;
            if(!str1.contains('}')){
                currentString = str1 + '}';
                currentString = currentString.substringBetween('{','}');
            }
            currentString = '{'+currentString+'}';
            map<string,string> m = (map<string,string>)JSON.deserialize(currentString, map<string,string>.class);   
            trxIdList.add(m.get('Id'));                      
        }*/
        List < object > tran = (List < object > ) inMap.get('TransactionList');
             for (Object ts: tran) {
                  Map < Object, Object > m = (Map < Object, Object > ) ts;
                  Id key = (String) m.get('Id');
                  trxIdList.add(key); 
             }
        
        if(trxIdList!= null && trxIdList.size() > 0){           
            trxListtoUpdate = [select id,name,celsrm__Due_Date__c,celsrm__Latest_Note__c from celsrm__Transaction__c where id =: trxIdList];
            for(celsrm__Transaction__c trxobj : trxListtoUpdate){
                // trxobj.celsrm__Reason_Code__c = (string)inMap.get('Reason_Code');
                trxobj.celsrm__So_Number__c = (string)inMap.get('SO');
                trxobj.celsrm__Po_Number__c = (string)inMap.get('PO');
               // trxobj.celsrm__Status__c = (string)inMap.get('Status');
                // trxobj.celsrm__Bill_To_City__c = (String)inMap.get('BillToCity');
            }
            
            update trxListtoUpdate;

            if(!trxIdList.isEmpty()){
                celsrm.SRMUtilityController.insertActivity( (List<String>)new List<Id>( trxIdList ), 'celsrm__Transaction__c','Update Transaction', 100, null, UserInfo.getUserId(), null, 'Internal');
            }
        }
        Map<String, Object> refreshParentValues = new Map<String, Object>();
        System.debug('@@ inMap.containsKey(ListView) : ' + inMap.containsKey('ListView'));
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