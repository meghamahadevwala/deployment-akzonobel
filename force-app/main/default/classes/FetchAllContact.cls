global with sharing class FetchAllContact implements celsrm.GOGIScreenCustomLogic {
    global Map<Object, Object> invoke(String functionName, Map<Object, Object> inMap){
        String Id = (String)inMap.get('Id');
        if (inMap.get('ggScreenName') != null && inMap.get('ggScreenName') == 'LogACallForTreatmentRule') {
            Id = (String)inMap.get('accountId');
        } 
        if(inMap.containsKey('calledFromTransactionDetailScreen') && Boolean.valueOf(inMap.get('calledFromTransactionDetailScreen')) == true) { 
            Id = (ID)inMap.get('celsrm__Account__c');
        }
        if (functionName == 'fetchDefaultContact') {
            List<Contact> con= [Select Id,phone,MobilePhone,FirstName,LastName,celsrm__Default__c,Name From Contact where AccountId =: Id AND celsrm__Default__c = true Order By Name LIMIT 1];
            if(con.size() > 0) {
                if(con.get(0).phone != null) {
                    inMap.put('ContactName', con.get(0).Id + '_' + con.get(0).phone);
                    inMap.put('ContactCalled', con.get(0).phone);
                    inMap.put('DialContactId', con.get(0).Id);
                    inMap.put('DialContact', con.get(0).phone);
                } else if(con.size() > 0 && con.get(0).MobilePhone != null) {
                    inMap.put('ContactName', con.get(0).Id + '_' + con.get(0).MobilePhone);
                    inMap.put('ContactCalled', con.get(0).MobilePhone);
                    inMap.put('DialContactId', con.get(0).Id);
                    inMap.put('DialContact', con.get(0).MobilePhone);
                } else {
                    inMap.put('ContactName', con.get(0).Id + '_' + 'blank');
                    inMap.put('ContactCalled', con.get(0).MobilePhone);
                    inMap.put('DialContactId', con.get(0).Id);
                    inMap.put('DialContact', con.get(0).MobilePhone);
                }
            }
        } else {
            List<Contact> conList = new List<Contact>();
            Map<id,Contact> mapContact= new map<id,Contact>([Select Id,phone,MobilePhone,FirstName,LastName,celsrm__Default__c,Name From Contact where AccountId =: Id Order By Name]);
            List<Map<String,String>> response = new List<Map<String,String>>();
            List<Map<String,String>> finalResponse = new List<Map<String,String>>();
            for (Contact con : mapContact.values()) {
                map<String,String> tempMap = new Map<String,String>();
                if (con.celsrm__Default__c) {
                    if(con.phone != null) {
                        tempMap.put('label', con.Name + ' (P) ( ' + con.phone + ' ) ');
                        tempMap.put('value', con.Id + '_' + con.phone);
                        response.add(tempMap);
                    } 
                    if(con.MobilePhone != null) {
                        tempMap = new Map<String,String>();
                        tempMap.put('label', con.Name + ' (M) ( ' + con.MobilePhone + ' ) ');
                        tempMap.put('value', con.Id + '_' + con.MobilePhone);
                        response.add(tempMap);
                    } 
                    
                    if (con.phone == null && con.MobilePhone == null) {
                        tempMap.put('label', con.Name);
                        tempMap.put('value', con.Id + '_' + 'blank');
                        tempMap.put('Id', con.Id);
                        response.add(tempMap);
                    }
                } else {
                    if(con.phone != null) {
                        tempMap.put('label', con.Name + ' (P) ( ' + con.phone + ' ) ');
                        tempMap.put('value', con.Id + '_' + con.phone);
                        tempMap.put('Id', con.Id);
                        response.add(tempMap);
                    } 
                    if(con.MobilePhone != null) {
                        tempMap = new Map<String,String>();
                        tempMap.put('label', con.Name + ' (M) ( ' + con.MobilePhone + ' ) ');
                        tempMap.put('value', con.Id + '_' + con.MobilePhone);
                        tempMap.put('Id', con.Id);
                        response.add(tempMap);
                    } 
                    
                    if (con.phone == null && con.MobilePhone == null) {
                        tempMap.put('label', con.Name);
                        tempMap.put('value', con.Id + '_' + 'blank');
                        tempMap.put('Id', con.Id);
                        response.add(tempMap);
                    }
                    
                }
            }
            finalResponse.addAll(response);
            inMap.put('AllContactList', mapContact);
            inMap.put('dataServiceResponse', finalResponse);
        }
        
        return inMap;
    }
}