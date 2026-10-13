global with sharing class GOGWCMMassUpdateDispute implements celsrm.GOGIScreenCustomLogic {
    global Map<Object, Object> invoke(String functionName, Map<Object, Object> inMap) {
        System.debug('into GOGCustomImplementation');
        System.debug('functionName ::: ' + functionName);
        System.debug('inMap ::: ' + inMap);       
        inMap.put('VendorName','adding new value');
        
        String str = JSON.serialize(inMap.get('DisputeGrid'));       
        List<string> strList = str.substring(1, str.length()-1).split('}');
        set<Id> disIdList = new set<Id>();
        List<celsrm__Dispute__c> disListToUpdate = new List<celsrm__Dispute__c>();
    
        List < object > disputeList = (List < object > ) inMap.get('DisputeGrid');
        for (Object dispute: disputeList) {
            Map < Object, Object > m = (Map < Object, Object > ) dispute;
            Id key = (String) m.get('Id');
            disIdList.add(key); 
        }
        if(disIdList!= null && disIdList.size() > 0){           
            disListToUpdate = [select id,name,celsrm__Dispute_Type__c,celsrm__Amount__c,celsrm__Status__c,celsrm__Latest_Note__c from celsrm__Dispute__c where id =: disIdList];
            for(celsrm__Dispute__c disObj : disListToUpdate){
                disObj.celsrm__Amount__c = (Decimal)inMap.get('Amount');
                disObj.celsrm__Dispute_Type__c = (String)inMap.get('type');
                disObj.celsrm__Status__c = (string)inMap.get('Status');
                map<string,string> owner = (map<string,string>)JSON.deserialize(JSON.serialize(inMap.get('Owner')), map<string,string>.class);
                if (owner  != null && owner.get('id') != null ){
                    System.debug('inMap.get(Owner):: ' + owner);
                    System.debug('inMap.get(Owner).get(id):: ' + owner.get('id'));
                    disObj.celsrm__Owner__c = owner.get('id');
                } 
                disObj = (celsrm__Dispute__c)celsrm.SRMUtilityController.saveNoteOnRecord( disObj,disObj.celsrm__Latest_Note__c, 'Update Dispute - ',(string)inMap.get('Note'),'','') ;
            }
            
            update disListToUpdate;

            celsrm.SRMUtilityController.insertActivity( (List<String>)new List<Id>( disIdList ), 'celsrm__Dispute__c','Mass Update Dispute', 100,  'Update Dispute ' + '\n' + String.valueOf(inMap.get('Note')), UserInfo.getUserId(), null, 'Internal');
        }
        Map<String, Object> refreshParentValues = new Map<String, Object>();
        if(inMap.containsKey('ListView')) {
            refreshParentValues.put('name', 'ListView');
            refreshParentValues.put('value',inMap.get('ListView'));
            refreshParentValues.put('onChangeMethod','filterDataByViewDispute');
        }
        System.debug('@@@ refreshParentValues : '  +refreshParentValues);
        inMap.put('refreshParentValues', refreshParentValues);
        return inMap;
    }
}