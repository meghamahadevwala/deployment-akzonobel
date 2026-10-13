global with sharing class FetchOpenTrxn implements celsrm.GOGIScreenCustomLogic {
    global Map<Object, Object> invoke(String functionName, Map<Object, Object> inMap) {
        System.debug('into FetchOpenTrxn');
        try {
            List<String> invNo = new List<String>();
            String accId = String.valueOf(inMap.get('Id'));
            if(inMap.containsKey('activityData')) {
                System.debug('@@@ activityData : ' + inMap.get('activityData'));
                Map<Object, Object> aData = (Map<Object, Object>)inMap.get('activityData');
                System.debug('@@@ adata: ' + aData );
                if(aData.containsKey('Classification_Response__c')) {
                    Map<String, Object> res = (Map<String, Object>)JSON.deserializeUntyped((String)aData.get('Classification_Response__c'));
                    if(res.containsKey('entities')) {
                        String txt = (String)res.get('text');
                        List<Object> ent = (List<Object>)res.get('entities');
                        if(ent.size() > 0) {
                            for(Object o : ent) {
                                Map<String, Object> tempMap = (Map<String, Object>)o;
                                if( String.valueOf(tempMap.get('dim')) == 'invoice_no' ) {
                                    invNo.add(String.valueOf(tempMap.get('value')));
                                }
                            }
                        }
                    }
                }
                
            }
            System.debug('final invoices which we get :: ' + invNo);
            List<celsrm__Transaction__c> trxn;
            if(invNo.size() > 0) {
                trxn = [Select Id, celsrm__account__c, celsrm__Amount__c, celsrm__balance__c, Name From  celsrm__Transaction__c WHere celsrm__account__c = :accId And Name IN :invNo And celsrm__Amount__c != 0];
                String s = JSON.serialize(trxn);
                s = '{ "data" : ' + s + ' } ';
                Map<String, Object> tmp = (Map<String, Object>)JSON.deserializeUntyped(s);
                //List<Map<String, Object>> obj = (List<Map<String, Object>>)JSON.deserialize(JSON.serialize(trxn), List<Map<String, Object>>.class);
                for(Object o : (List<Object>)tmp.get('data')) {
                    ((Map<String, Object>)o).put('isSelected', true);
                }
                inMap.put('TransactionList', tmp.get('data'));
            } else {
                trxn = [Select Id, celsrm__account__c, celsrm__Amount__c, celsrm__balance__c, Name From  celsrm__Transaction__c WHere celsrm__account__c = :accId And celsrm__Amount__c != 0];
                inMap.put('TransactionList', trxn);
            }
            System.debug('final trxn : ' + inMap.get('TransactionList'));
        } catch(Exception e) {
            System.debug(e.getMessage());
            System.debug(e.getStackTraceString());
        }
        
        
        return inMap;
    }
}