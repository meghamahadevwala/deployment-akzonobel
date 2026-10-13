global with sharing class WCM_FetchFolloupDays implements celsrm.GOGIScreenCustomLogic {
    global Map<Object, Object> invoke(String functionName, Map<Object, Object> inMap) {
        if( inMap.get('ContactnotpickcallMethod') != null && inMap.get('ContactnotpickcallMethod') =='No Answer'){
            inMap.put('FollowUpDate', Date.Today().addDays(1));
        }else if(inMap.get('ContactnotpickcallMethod') != null && inMap.get('ContactnotpickcallMethod') =='Left Voicemail'){
             inMap.put('FollowUpDate', Date.Today().addDays(2));
        }else{
             inMap.put('FollowUpDate', Date.Today().addDays(5));
        }
        
        String Id = (String)inMap.get('Id');
         try {
            if ((String)inMap.get('screenName') != 'Contact Customer') {
                List<Contact> mapContact = [Select Id,phone,Name,celsrm__Default__c From Contact where AccountId =: Id and celsrm__Default__c = True];
                if(mapContact != null && mapContact.size()>0){
                    if(mapContact.get(0).phone != null) {
                        inMap.put('ContactName', mapContact.get(0).Id + '_' + mapContact.get(0).phone);
                    } else if (mapContact.get(0).MobilePhone != null) {
                        inMap.put('ContactName', mapContact.get(0).Id + '_' + mapContact.get(0).MobilePhone);
                    } else {
                        inMap.put('ContactName', mapContact.get(0).Id + '_' + 'blank');
                    }
                    
                    inMap.put('ContactCalled', mapContact.get(0).phone);
                }else{
                    inMap.put('ContactName', '');
                    inMap.put('ContactCalled', '');
                }
            }
        } catch (Exception e) {
            System.debug(e);
        }
        
        List<Object> arr = new List<Object>();
        String trxnId = '';
        List<Id> idList = new List<Id>();
        if(inMap.containsKey('TransactionList') && inMap.get('TransactionList') != null ){
            arr = (List<Object>)inMap.get('TransactionList');
            if(arr != null && arr.size()> 0) {
                for(Integer i=0; i<arr.size();i++) {
                    idList.add( (Id)(((Map<Object, Object>)arr.get(i)).get('Id')) );
                }
            }
        }        
        system.debug('idList>>>>'+idList);
        celsrm__Temp_Object_Holder__c temp = new celsrm__Temp_Object_Holder__c();
        if(!idList.isEmpty()){
            temp.celsrm__key__c =  Userinfo.getUserName()+Datetime.now().getTime();
            temp.celsrm__value__c =string.join(idList,',');
            system.debug(temp.celsrm__value__c);            
            insert Temp;
            inmap.put('tempKey',Temp.Id);
        }
        List<User> userList = [SELECT Name FROM User WHERE Id =: UserInfo.getUserId()];
        if(userList != null && userList.size() > 0) {
            Map<String, String> currentUserMap = new Map<String, String>();
            currentUserMap.put('id', UserInfo.getUserId());
            currentUserMap.put('name', userList.get(0).Name);
            inMap.put('Owner', currentUserMap);
        }    
        
        return inMap;
    }    
}