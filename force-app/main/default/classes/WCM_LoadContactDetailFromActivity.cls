global with sharing class WCM_LoadContactDetailFromActivity implements celsrm.GOGIScreenCustomLogic {
    global Map<Object, Object> invoke(String functionName, Map<Object, Object> inMap) {
        Map<String,Object> relatedToMap = new Map<String,Object>();
        relatedToMap.put('id', inMap.get('Id'));
        relatedToMap.put('name', inMap.get('Name'));
        inMap.put('Account',relatedToMap);
        String trxnId = '';
        double PromisedAmt;
        String ContactEmail;
        date PromiseDT=null;
        List<Id> idList = new List<Id>();
        if(inMap.containsKey('activityData')) {
            Map<Object, Object> aData = (Map<Object, Object>)inMap.get('activityData');
            //-- Starts | FIN-6361 | Changed by Dilshad | 28 Aug 2024 --//
            String emailId = (String) aData.get('Id');
            inMap.put('emailMessageId', emailId);
            //-- Ends | FIN-6361 | Changed by Dilshad | 28 Aug 2024 --//
            //-- Starts | FIN-6410| Changes By: Asera | 19 Sep 2024 --//
            if(emailId != ''){
                String classificationResponseString = celsrm.SRMUtilityController.getClassificationResponse(emailId); 
                if(classificationResponseString != null && classificationResponseString != ''){
                    aData.put('Classification_Response__c', classificationResponseString);
                } 
            }
            //-- End | FIN-6410| Changes By: Asera | 19 Sep 2024 --//
            if(aData.containsKey('Classification_Response__c')) {
                Map<String, Object> res = (Map<String, Object>)JSON.deserializeUntyped((String)aData.get('Classification_Response__c'));
                if(res.containsKey('entities')) {
                    String txt = (String)res.get('text');
                    List<Object> ent = (List<Object>)res.get('entities');
                    if(ent.size() > 0) {
                        for(Object o : ent) {
                            if( ((Map<String, Object>)o).get('entity') == 'email' ) {
                                ContactEmail= String.valueOf(((Map<String, Object>)o).get('value'));
                            }
                        
                        }
                    }
                }
            }
        }
        inMap.put('Email', ContactEmail);
        return inMap;
    }
}