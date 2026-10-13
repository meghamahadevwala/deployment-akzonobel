global with sharing class WCMUpdateTransaction implements celsrm.GOGIScreenCustomLogic {
    global Map<Object, Object> invoke(String functionName, Map<Object, Object> inMap) {
        String str = JSON.serialize(inMap.get('TransactionList'));
        List<celsrm__Transaction__c> trxList = new List<celsrm__Transaction__c>();
        List<Object> trxns = (List<Object>)inMap.get('TransactionList');  
        for(Object trxn : trxns) {
                map < Object, Object> m = (map < Object, Object > )trxn;
                String trxId = (String)m.get('Id'); 
                celsrm__Transaction__c currentTrx = New celsrm__Transaction__c(Id=trxId  );
                currentTrx.celsrm__Promised_Amount__c = Double.valueOf(m.get('PromisedAmount'));
                currentTrx.celsrm__Promise_Date__c = date.valueOf(m.get('PromiseDate') + ' 00:00:00');
                trxList.add(currentTrx);
        }
        
        if(trxList != null && trxList.size() > 0){           
            update trxList;
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