global with sharing class FetchCustomerCommunication  implements celsrm.GOGIScreenCustomLogic {

    global Map<Object, Object> invoke(String functionName, Map<Object, Object> inMap){
        if(functionName == 'getTransactions'){
            inMap = getTransactions(inMap);
        } else if(functionName == 'removeCommunication'){
            inMap = removeCommunication(inMap);
        } else {
            try {
            System.debug('Id>>>>' +inMap);
            String accId = (String)inMap.get('Id');
            System.debug('Id>>>>' +accId);

            
            Map<String, String> catconfig = new Map<String, String>();
            for(celsrm__Email_Category_Configuration__mdt tempconfig : [Select celsrm__Color__c, MasterLabel From celsrm__Email_Category_Configuration__mdt LIMIT 999]) {
                catconfig.put(tempconfig.MasterLabel, tempconfig.celsrm__Color__c);
            }

            List<Customer_Communication__c> ListCustComm = [SELECT Id,Called_To__c,Called_To__r.Name, Account__c,account__r.Name, Contact_Type__c,Call_Transcript__c,Text_Message_Body__c, Phone__c, Call_Recording_Link__c, Screen_Name__c, Transactions__c, User__c, User__r.Name,Status__c, Name, CreatedDate,CategoryPlain__c,Classification_Response__c FROM Customer_Communication__c where account__C =: accId order by CreatedDate desc];
            if(ListCustComm.size() > 0){
                List<Object> getCustCommList = new List<Object>();
                    for(Customer_Communication__c CustComm : ListCustComm){
                        map<Object,Object> CustCommMap = new map<Object,Object>();
                        CustCommMap.put('CustCommId', CustComm.Id);
                        String ContactByLink ='<a href="/'+ CustComm.User__c + '" target="_blank">' + CustComm.User__r.Name + '</a>';
                        CustCommMap.put('ScreenName', CustComm.Screen_Name__c);
                        CustCommMap.put('User',ContactByLink);
                        CustCommMap.put('SendByUser',ContactByLink);
                        CustCommMap.put('Status', CustComm.Status__c);
                        CustCommMap.put('ContactType', CustComm.Contact_Type__c);
                        CustCommMap.put('Phone', CustComm.Phone__c);
                        CustCommMap.put('SendByNumber', CustComm.Phone__c);
                        CustCommMap.put('SendToNumber', CustComm.Phone__c);
                        CustCommMap.put('CreatedDate', CustComm.CreatedDate);
                        CustCommMap.put('SMSDate', CustComm.CreatedDate);
                        // CustCommMap.put('CallTranscribe', CustComm.Call_Transcript__c);
                        CustCommMap.put('MessageBody', CustComm.Text_Message_Body__c);
                        if (CustComm.Call_Transcript__c != null) {
                            CustCommMap.put('CallTranscribe',String.valueOf(CustComm.Call_Transcript__c).replaceAll('\n',' ').replaceAll('\r', ' '));
                            CustCommMap.put('CallTranscribeFullText',String.valueOf(CustComm.Call_Transcript__c));
                        }
                        
                        if(CustComm.Contact_Type__c != null){
                            if(String.valueOf(CustComm.Contact_Type__c).equalsIgnoreCase('Call')){
                                CustCommMap.put('ScreenHeader', 'Call');
                            }else if(String.valueOf(CustComm.Contact_Type__c).equalsIgnoreCase('Text Message')){
                                CustCommMap.put('ScreenHeader', 'SMS');
                            }
                        }

                        if(CustComm.Called_To__c != null){
                            String ContactName ='<a href="/'+ CustComm.Called_To__c + '" target="_blank">' + CustComm.Called_To__r.Name + '</a>';
                            CustCommMap.put('ContactName', ContactName);
                            CustCommMap.put('SendBy', ContactName);
                            CustCommMap.put('SendTo', ContactName);
                        }
                        if(CustComm.Call_Recording_Link__c != null){
                            CustCommMap.put('CallRecordingLink', '<audio controls style ="height: 1.5rem;width: 7rem;"><source src ="'+CustComm.Call_Recording_Link__c+'"></audio>');
                        }

                        if(CustComm.Classification_Response__c != null){
                            CustCommMap.put('Classification_Response__c',CustComm.Classification_Response__c);
                        }
                        
                        
                        CustCommMap.put('TransactionsId',CustComm.Transactions__c);

                        String cat = CustComm.CategoryPlain__c;
                        CustCommMap.put('CategoryPlain', cat);
                        if(cat == null) {
                            CustComm.Category__c = null;
                        } else if(catconfig.containsKey(cat)) {
                            String color = 'color:' + catconfig.get(cat);
                            // CustComm.Category__c = '<b style=' + color + '>' + cat + '</b>';
                            CustCommMap.put('Category', '<b style=' + color + '>' + cat + '</b>');
                        } else {
                            CustCommMap.put('Category', '<b>'+cat+'</b>');
                        }
                        getCustCommList.Add(CustCommMap);
                    }
                inMap.put('CustomerCommunicationGrid',getCustCommList);
                }   
                system.debug('Function Name >>>'+ functionName);
                
            }catch (Exception ex) {
                String errorMessage = 'ClassName: FetchCustomerCommunication | Method: invoke() | Linenumber: ' + ex.getLineNumber() + ' | Message: ' + ex.getMessage();
                System.debug('errorMessage: ' + errorMessage);
            }
        }
    
        return inMap;
    }
    public static Map<Object, Object> getTransactions(Map<Object, Object> inMap){
			try{
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
								system.debug('selectedGridData>> ' + selectedGridData);
								Map<Object,Object> mapSelRecData = (Map<Object,Object>)selectedGridData;
                                for(Object mapSel : mapSelRecData.keySet()){
                                    System.debug('mapSelRecData keyset >> ' + mapSel);
                                }
								System.debug('InMap>>'+JSON.deserializeUntyped(JSON.serialize(mapSelRecData.get('TransactionsId'))));
								String tranString = String.valueOf(mapSelRecData.get('TransactionsId'));
                                system.debug('tranString>> ' + tranString);
								Map<String, Object> m = (Map<String, Object>)JSON.deserializeUntyped(tranString);
								List<Object> m2 = new List<Object>();
                                String objName = '';
                                
                                for(Object key : mapSelRecData.keySet()){
                                    inMap.put(key, mapSelRecData.get(key));
                                }

								if (m.containsKey('transactions')) {
									objName = 'transactions';
									m2=(List<Object>)m.get('transactions');
								} else if (m.containsKey('disputes')) {
									objName = 'disputes';
									m2=(List<Object>)m.get('disputes');
								}
								List<String> tranIdList = new List<String>();

								for(Object id : m2){
									tranIdList.add(String.valueOf(id));
								}
								if (objName == 'transactions') {
									inMap.put('ShowTransaction', 'true');
								} else if (objName == 'disputes') {
									inMap.put('ShowTransaction', 'false');
								}
								if(tranIdList.size() > 0){
									List<Object> getTranList = new List<Object>();
									if (objName == 'transactions') {
                                        system.debug('tranIdList>>' + tranIdList);
										List<celsrm__Transaction__c> tranList = [SELECT Id, Name, celsrm__Account__c, celsrm__Account__r.Name, celsrm__Amount__c, celsrm__Balance__c, celsrm__DPD__c, celsrm__Due_Date__c FROM celsrm__Transaction__c where Id IN :tranIdList];
										for(celsrm__Transaction__c tranObj :tranList){
											Map<Object,Object> tranMap = new Map<Object,Object>();
											tranMap.put('Name','<a href="' + '/'+ tranObj.Id + '" target="_blank">' + tranObj.Name + '</a>');
											tranMap.put('Account','<a href="' + '/'+ tranObj.celsrm__Account__c + '" target="_blank">' + tranObj.celsrm__Account__r.Name + '</a>');
											tranMap.put('Amount',tranObj.celsrm__Amount__c);
											tranMap.put('Balance',tranObj.celsrm__Balance__c);
											// tranMap.put('Batch',tranObj.celsrm__Batch_Number__c);
											tranMap.put('DueDate',tranObj.celsrm__Due_Date__c);
											tranMap.put('DaysPastDue',tranObj.celsrm__DPD__c);
											// tranMap.put('Name',tranObj.Name);
											getTranList.Add(tranMap);
										}  
										inMap.put('TransactionsGrid',getTranList); 
									} else if (objName == 'disputes') {
										List<celsrm__Dispute__c> tranList = [SELECT Id, Name, celsrm__Account__c, celsrm__Account__r.Name, celsrm__Amount__c, celsrm__Balance__c, celsrm__Dispute_DPD__c FROM celsrm__Dispute__c where Id IN :tranIdList];
										for(celsrm__Dispute__c tranObj :tranList){
											Map<Object,Object> tranMap = new Map<Object,Object>();
											tranMap.put('Name','<a href="' + '/'+ tranObj.Id + '" target="_blank">' + tranObj.Name + '</a>');
											tranMap.put('Account','<a href="' + '/'+ tranObj.celsrm__Account__c + '" target="_blank">' + tranObj.celsrm__Account__r.Name + '</a>');
											tranMap.put('Amount',tranObj.celsrm__Amount__c);
											tranMap.put('Balance',tranObj.celsrm__Balance__c);
											// tranMap.put('Batch',tranObj.celsrm__Batch_Number__c);
											tranMap.put('DaysPastDue',tranObj.celsrm__Dispute_DPD__c);
											getTranList.Add(tranMap);
										}
										inMap.put('DisputesGrid',getTranList); 

									}
																		 
								}
							}
						}
					}
				}
		}
		catch (Exception ex) {
			String errorMessage = 'ClassName: FetchCustomerCommunication | Method: invoke() | Linenumber: ' + ex.getLineNumber() + ' | Message: ' + ex.getMessage();
			System.debug('errorMessage: ' + errorMessage);
		}

        return inMap;
    }
    public static Map<Object, Object> removeCommunication(Map<Object, Object> inMap){
        try {
            Customer_Communication__c cc = new Customer_Communication__c();
            cc.Id = (String)inMap.get('Id');
            delete cc;
            inMap.put('success', true);
        } catch (Exception ex) {
            throw new celsrm.GOGDataServiceLoadException(ex.getMessage());  
        }
        return inMap;
    }
}