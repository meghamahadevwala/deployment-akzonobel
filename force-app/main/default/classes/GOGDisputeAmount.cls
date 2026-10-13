global with sharing class GOGDisputeAmount implements celsrm.GOGIScreenCustomLogic {
    global Map<Object, Object> invoke(String functionName, Map<Object, Object> inMap) {
        System.debug('into GOGDisputeAmount :: ' + inMap.get('TransactionList'));
        System.debug('ggScreenName :: ' + inMap.get('ggScreenName'));
        
        
        if(inMap.containsKey('TransactionList')) {
            List<Object> trxn = (List<Object>)inMap.get('TransactionList');
            String trxnId = '';
            double PromisedAmt;
            date PromiseDT=null;
            List<Id> idList = new List<Id>();
            if(inMap.containsKey('activityData')) {
                System.debug('@@@ activityData : ' + inMap.get('activityData'));
                Map<Object, Object> aData = (Map<Object, Object>)inMap.get('activityData');
                System.debug('@@@ adata: ' + aData );
                //-- Starts | FIN-6410| Changes By: Asera | 19 Sep 2024 --//
                if(String.valueOf(aData.get('Id')) != ''){
                    String emailMessageId = (String)aData.get('Id');
                    String classificationResponseString = celsrm.SRMUtilityController.getClassificationResponse(emailMessageId); 
                    if(classificationResponseString != null && classificationResponseString != ''){
                        aData.put('Classification_Response__c', classificationResponseString);
                    } 
                }
                //-- End | FIN-6410| Changes By: Asera | 19 Sep 2024 --//
                if(aData.containsKey('Classification_Response__c')) {
                    Map<String, Object> res = (Map<String, Object>)JSON.deserializeUntyped((String)aData.get('Classification_Response__c'));
                    if(res.containsKey('entities')) {
                        String txt = (String)res.get('text');
                         System.debug('@@@ txt ' +txt );
                        List<Object> ent = (List<Object>)res.get('entities');
                        if(ent.size() > 0) {
                            for(Object o : ent) {
                          
                                if( ((Map<String, Object>)o).get('entity') == 'amount-of-money' ) {
                                    System.debug('@@@ amount: ' + ((Map<String, Object>)o).get('value'));
                                    PromisedAmt = Double.valueOf(((Map<String, Object>)o).get('value'));
                                    System.debug('@@@ PromisedAmt : ' + PromisedAmt );
                                }
                                 if( ((Map<String, Object>)o).get('entity') == 'time' ) {
                                        object obj =  ((Map<String, Object>)o).get('value');
                                        System.debug('@@@ temp : ' +( obj instanceof String));
                                        if(obj instanceof String){
                                            String temp = (String) ((Map<String, Object>)o).get('value');
                                            System.debug('@@@ temp : ' + temp );
                                            PromiseDT= Date.valueOf(temp );
                                            System.debug('@@@ PromiseDT : ' + PromiseDT);
                                        }else{
                                            Map<String,Object> tempmap = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(((Map<String, Object>)o).get('value'))); 
                                            System.debug('@@@ tempmap : ' + tempmap );
                                            String temp = (String) tempmap.get('to');
                                            PromiseDT= Date.valueOf(temp );
                                            System.debug('@@@ PromiseDT : ' + PromiseDT);
                                        }
                                 }
                            }
                        }
                    }
                }
            }
            system.debug('>>>>>>'+inMap.get('screenName'));
            if(trxn != null && trxn.size() > 0) {
                for(Object t : trxn) {
                    Map<Object, Object> trxnMap = (Map<Object, Object>)t;
                    System.debug('trxnMap::'+trxnMap);
                    System.debug('trxnMapAmount::'+trxnMap.get('amount'));
                    system.debug('PromisedAmt Date>>>'+PromisedAmt +PromiseDT );
                    trxnMap.put('PromisedAmount',decimal.valueOf(JSON.serialize(trxnMap.get('celsrm__Balance__c')))); 
                    trxnMap.put('PromiseDate',date.today().adddays(5));
                    // if( PromisedAmt != null && PromiseDT !=null && inMap.get('ggScreenName')== 'WCMPromisToPayScreenEmailAction')
                    // {
                    //     trxnMap.put('PromisedAmount', decimal.valueOf(PromisedAmt )); 
                    //     trxnMap.put('PromiseDate',PromiseDT );
                    //     system.debug('PromisedAmt Date>>>'+PromisedAmt +PromiseDT );

                    //     system.debug('trxnMap>>>'+trxnMap);
                    // }else if(PromisedAmt == null && PromiseDT !=null && inMap.get('ggScreenName')== 'WCMPromisToPayScreenEmailAction')
                    // {
                         
                    //      trxnMap.put('PromisedAmount',decimal.valueOf(JSON.serialize(trxnMap.get('celsrm__Balance__c')))); 
                    //      trxnMap.put('PromiseDate',PromiseDT );
                    
                    // }else if(PromisedAmt != null && PromiseDT ==null && inMap.get('ggScreenName')== 'WCMPromisToPayScreenEmailAction')
                    // {
                    //      trxnMap.put('PromisedAmount',decimal.valueOf(PromisedAmt ));  
                    //      trxnMap.put('PromiseDate',date.today().adddays(5));
                    
                    // }
                }
                
                for(Integer i=0; i<trxn.size();i++) {
                    idList.add( (Id)(((Map<Object, Object>)trxn.get(i)).get('Id')) );
                }
                celsrm__Temp_Object_Holder__c temp = new celsrm__Temp_Object_Holder__c();
                if(!idList.isEmpty()){
                    temp.celsrm__key__c =  Userinfo.getUserName()+Datetime.now().getTime();
                    temp.celsrm__value__c =string.join(idList,',');
                    system.debug(temp.celsrm__value__c);            
                    insert Temp;
                    inmap.put('tempKey',Temp.Id);
                }

            }
        }
        system.debug('inMapData::'+inMap.get('TransactionList'));
        return inMap;
    }
    
}