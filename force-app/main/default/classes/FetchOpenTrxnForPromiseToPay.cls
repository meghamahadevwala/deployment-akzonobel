global with sharing class FetchOpenTrxnForPromiseToPay implements celsrm.GOGIScreenCustomLogic {

    global Map<Object, Object> invoke(String functionName, Map<Object, Object> inMap) {
        System.debug('into FetchOpenTrxnForPromiseToPay');
        try {
            List<String> listInvoiceNo = new List<String>();
            String accId = String.valueOf(inMap.get('Id'));
            List<Account> listAcc = [select id,Name from Account where Id =: accId];
			if(!listAcc.isEmpty()){
				inMap.put('Name',listAcc.get(0).Name);
			}
            if(inMap.containsKey('gogGridIndex')){
                Decimal selectedGridId = (Decimal) inMap.get('gogGridIndex');
                System.debug('selectedGridId >> ' + selectedGridId);
				double PromisedAmt;
				date PromiseDT=null;
                if(selectedGridId >= 0){
                    List<Object> listGridData = (List<Object>)inMap.get('CustomerCommunicationGrid');
                    System.debug('listGridData Size >> ' + listGridData.size());
                    if(!listGridData.isEmpty()){
                        System.debug('listGridData Selected >> ' + selectedGridId.intValue());
                        Object selectedGridData = listGridData.get(selectedGridId.intValue());
                        if(selectedGridData != null){
                            
                            Map<Object,Object> mapSelRecData = (Map<Object,Object>)selectedGridData;
                            System.debug('mapSelRecData keyset >> ' + mapSelRecData.keySet());
                            System.debug('Contains Classification_Response__c >> ' + mapSelRecData.containsKey('Classification_Response__c'));
                            if(mapSelRecData.containsKey('Classification_Response__c')) {
                                System.debug('Class Res >> ' + mapSelRecData.get('Classification_Response__c'));
                                Map<String, Object> res = (Map<String, Object>)JSON.deserializeUntyped((String)mapSelRecData.get('Classification_Response__c'));
                                    if(res.containsKey('entities')) {
                                        String txt = (String)res.get('text');
                                        List<Object> ent = (List<Object>)res.get('entities');
                                        if(ent.size() > 0) {
                                            for(Object o : ent) {
                                                Map<String, Object> tempMap = (Map<String, Object>)o;
                                                System.debug(' String.valueOf(tempMap.get(dim))>>> ' +  String.valueOf(tempMap.get('dim')) + ' <<>>> ' +  String.valueOf(tempMap.get('dim')) == 'invoice_no');
                                                if( String.valueOf(tempMap.get('dim')) == 'invoice_no' ) {
                                                    listInvoiceNo.add(String.valueOf(tempMap.get('value')));
                                                }
												
												if( ((Map<String, Object>)o).get('dim') == 'amount-of-money' ) {
													System.debug('@@@ amount: ' + ((Map<String, Object>)o).get('value'));
													Map<String, Object> innerMap = ((Map<String, Object>)((Map<String, Object>)o).get('value'));
													PromisedAmt = Double.valueOf(innerMap.get('value'));
													System.debug('@@@ PromisedAmt : ' + PromisedAmt );
												}
												
												if( ((Map<String, Object>)o).get('dim') == 'time' ) {
													Map<String, Object> obj =  ((Map<String, Object>)((Map<String, Object>)o).get('value'));
													if(obj.containsKey('type') ) {
														//for single date
														if(String.valueOf(obj.get('type')).equals('value')) {
															String temp = (String)obj.get('value');
															PromiseDT= Date.valueOf(temp );
														//for date range
														} else if(String.valueOf(obj.get('type')).equals('interval')) {
															Map<String, Object> temp = (Map<String, Object>)obj.get('to');
															PromiseDT= Date.valueOf((String)temp.get('value'));
														}
													}
												}
                                            }
                                        }
                                    }
                                }
                        }
                    }
                }
                
                System.debug('final invoices which we get :: ' + listInvoiceNo);
                List<celsrm__Transaction__c> trxn;
                if(listInvoiceNo.size() > 0) {
                    trxn = [Select Id, celsrm__account__c, celsrm__Amount__c, celsrm__balance__c, Name,celsrm__account__r.Name From  celsrm__Transaction__c WHere celsrm__account__c = :accId And Name IN :listInvoiceNo And celsrm__Amount__c != 0];
                    String s = JSON.serialize(trxn);
                    System.debug('TRX sie >> ' + trxn.size());
                    
                    s = '{ "data" : ' + s + ' } ';
                    Map<String, Object> tmp = (Map<String, Object>)JSON.deserializeUntyped(s);
                    //List<Map<String, Object>> obj = (List<Map<String, Object>>)JSON.deserialize(JSON.serialize(trxn), List<Map<String, Object>>.class);
                    for(Object o : (List<Object>)tmp.get('data')) {
                        Map<String, Object> selectedTX = (Map<String, Object>)o;
                        //((Map<String, Object>)o).put('isSelected', true);
                        System.debug('selectedTX keys>> ' + selectedTX.keyset());
                        System.debug('selectedTX >> ' + selectedTX.get('celsrm__Balance__c'));
                        selectedTX.put('isSelected', true);
						System.debug('PromisedAmt >> ' + PromisedAmt  + ' Promise Date >> ' + PromiseDT);
						if( PromisedAmt != null && PromiseDT !=null)
						{
							selectedTX.put('PromisedAmount', decimal.valueOf(PromisedAmt ));
							selectedTX.put('PromiseDate', PromiseDT);
						}else{
							selectedTX.put('PromisedAmount', selectedTX.get('celsrm__Balance__c'));
							selectedTX.put('PromiseDate', Date.today().adddays(5));
                        }
                        selectedTX.put('DisputeAmount', selectedTX.get('celsrm__Amount__c'));
                    }
                    
 
                    inMap.put('TransactionList', tmp.get('data'));
                } else {
                    trxn = [Select Id, celsrm__account__c, celsrm__Amount__c, celsrm__balance__c, Name,celsrm__account__r.Name From  celsrm__Transaction__c WHere celsrm__account__c = :accId And celsrm__Amount__c != 0];
                    inMap.put('TransactionList', trxn);
                }

                if(!trxn.isEmpty()){
                    System.debug('Acc name >>>>>>' + trxn.get(0));
                    // inMap.put('Name',trxn.get(0).get('celsrm__account__r.Name'));
                    // System.debug('Acc Name >>>' + inMap.get('Name'));
                }
                System.debug('final trxn : ' + inMap.get('TransactionList'));
            }
            
        } catch(Exception e) {
            System.debug('Error at lin nuber >>> ' + e.getLineNumber());
            System.debug(e.getMessage());
            System.debug(e.getStackTraceString());
        }
        return inMap;
    }
}