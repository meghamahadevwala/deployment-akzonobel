global with sharing class FetchUserPreference implements celsrm.GOGIScreenCustomLogic {
    global Map<Object, Object> invoke(String functionName, Map<Object, Object> inMap) {
        //System.debug('inMap.get(TransactionList)' + inMap.get('TransactionList'));
        String currentUser = UserInfo.getUserId();
        //inMap.put('CallScripts', );
        //for call transcript
        if(inMap.get('screenName') != null && (String.valueOf(inMap.get('screenName'))).equalsIgnoreCase('Contact Customer') && inMap.get('TransactionList') != null) {
            Set<Id> trxnId = new Set<Id>();
            List<Object> trxn = ((List<Object>)inMap.get('TransactionList'));
            if(trxn != null && trxn.size() > 0) {
                for (Object o : trxn) {
                    Map<Object, Object> tr = (Map<Object, Object>)o;
                    trxnId.add((ID)tr.get('Id'));
                }
                system.debug('trxnId>>> ' +  trxnId);
                List<celsrm__Transaction__c> trxnsData = [Select Id, Name, celsrm__Last_Contact_Date__c, celsrm__Due_Date__c, celsrm__Balance__c, celsrm__DPD__c, celsrm__Disputed_Amount__c, celsrm__Promised_Amount__c, celsrm__Promise_Date__c, celsrm__Is_Broken_Promise__c, (Select Id, Name, celsrm__Amount__c, celsrm__Status__c, celsrm__Created_Date__c, celsrm__Last_Contact_Date__c From celsrm__Disputes__r Where celsrm__Close_Date__c = null Order By CreatedDate DESC) From celsrm__Transaction__c Where Id IN :trxnId];
                //trxnsData
                system.debug('trxnsData>>> ' +  trxnsData);
                List<celsrm__Transaction__c> disputed = new List<celsrm__Transaction__c>();
                List<celsrm__Transaction__c> brokenPromised = new List<celsrm__Transaction__c>();
                List<celsrm__Transaction__c> promisedInvoice = new List<celsrm__Transaction__c>();
                List<celsrm__Transaction__c> highDPD = new List<celsrm__Transaction__c>();
                for (celsrm__Transaction__c trxnData :trxnsData) {
                    if(trxnData.celsrm__Disputed_Amount__c != null && trxnData.celsrm__Disputed_Amount__c != 0) {
                        disputed.add(trxnData);
                    } else if(trxnData.celsrm__Promise_Date__c != null && trxnData.celsrm__Is_Broken_Promise__c != null && trxnData.celsrm__Is_Broken_Promise__c) {
                        brokenPromised.add(trxnData);
                    } else if(trxnData.celsrm__Promise_Date__c != null && (trxnData.celsrm__Is_Broken_Promise__c == null || !trxnData.celsrm__Is_Broken_Promise__c)) {
                        promisedInvoice.add(trxnData);
                    } else if (trxnData.celsrm__DPD__c != null && trxnData.celsrm__DPD__c > 0){
                        highDPD.add(trxnData);
                    }
                }
                
                String script = 'Hello Customer<br /><br />';
                script += 'Greetings! Hope you are doing well. I’m calling you to share information about some of the outstanding invoice that are yet to be paid.<br /><br />';
                
                Boolean p2p= false;
                Boolean disp = false;
                //for oldest DPD
               
                //for promise invoice(without broken)
                if(promisedInvoice.size() > 0) {
                    p2p = true;
                    if(promisedInvoice.size() <= 3) {
                        script += '<h3><b>Promised Invoice</b></h3>Reminder : You have promised to pay for following Invoice(s)';
                        script += '<ul>';
                        for (celsrm__Transaction__c trxnData : promisedInvoice) {
                            script += '<li>';
                            script += 'Invoice <b>' + trxnData.Name + '</b> by <b>' + trxnData.celsrm__Promise_Date__c.format() + '</b> ';
                            script += '</li>';
                            // messageScript += 'Invoice ' + trxnData.Name + ' was promised to be paid on ' + trxnData.celsrm__Promise_Date__c.format() + ' but wasn’t paid so has been marked as broken promise. Please let us know if any additional info required else would like to receive this payment soon. ';
                        }
                        script += '</ul>';
                        //script += '<br />';
                    } else {
                        script += 'Since there are multiple records in the system, I’ll share details of Invoices involving “promise” scenario, over an email for your easy reference and action. Thank you for your Time.<br />';
                    }
                }
                //for broken promise invoice
                if(brokenPromised.size() > 0) {
                    p2p = true;
                    if(brokenPromised.size() <= 3) {
                        script += '<h3><b>Broken Promise Invoice</b></h3>';
                        script += '<ul>';
                        for (celsrm__Transaction__c trxnData : brokenPromised) {
                            script += '<li>';
                            script += 'Invoice <b>' + trxnData.Name + '</b> was promised to be paid on <b>' + trxnData.celsrm__Promise_Date__c.format() + '</b> but wasn’t paid so has been marked as broken promise. Please let us know if any additional info required else would like to receive this payment soon.';
                            script += '</li>';
                            // messageScript += 'Invoice ' + trxnData.Name + ' was promised to be paid on ' + trxnData.celsrm__Promise_Date__c.format() + ' but wasn’t paid so has been marked as broken promise. Please let us know if any additional info required else would like to receive this payment soon. ';
                        }
                        script += '</ul>';
                        //script += '<br />';
                    } else {
                        script += 'Since there are multiple records in the system, I’ll share details of Invoices involving “promise” scenario, over an email for your easy reference and action. Thank you for your Time.<br />';
                    }
                }

                if(highDPD.size() > 0) {
                    if(highDPD.size() <= 3) {
                        script += '<h3><b>Open Invoice</b></h3>';
                        script += '<ul>';
                        for (celsrm__Transaction__c trxnData : highDPD) {
                            script += '<li>';
                            script += 'Invoice <b>' + trxnData.Name + '</b> of <b> $' + (trxnData.celsrm__Balance__c.format().contains('.')?trxnData.celsrm__Balance__c.format():(trxnData.celsrm__Balance__c.format()+'.00')) + '</b> has been outstanding for <b>' + trxnData.celsrm__DPD__c + '</b>.';
                            if(trxnData.celsrm__Last_Contact_Date__c != null) {
                                script += ' Last reminder was sent on <b>' + trxnData.celsrm__Last_Contact_Date__c.format() + '</b>.';
                            }
                            script += '</li>';
                        }
                        script += '</ul>';
                        //script += '<br />';
                    } else {
                        //need to tell that, we will send detail on your registeered email
                        script += 'As there are multiple records showing in our system, I’ll share the list of invoices and other relevant information over an email after this call.  This will help you by providing necessary details and take the next steps. Thank you for your time. <br />';
                    }
                }

                 //for disputed invoice
                 if(disputed.size() > 0) {
                    disp = true;
                    if(disputed.size() <= 3) {
                        script += '<h3><b>Disputed Invoice</b></h3>';
                        script += '<ul>';
                        for (celsrm__Transaction__c trxnData : disputed) {
                            
                            System.debug('@@ trxnData.celsrm__Disputes__r ' + trxnData.celsrm__Disputes__r);
                            if (trxnData.celsrm__Disputes__r.size() > 0) {
                                script += '<li>';
                                script += 'Our record shows that a dispute of <b> $' + (trxnData.celsrm__Disputed_Amount__c.format().contains('.')?trxnData.celsrm__Disputed_Amount__c.format():(trxnData.celsrm__Disputed_Amount__c.format()+'.00')) + '</b> was recorded on Invoice <b>' + trxnData.Name + '</b> having value of <b> $' + (trxnData.celsrm__Balance__c.format().contains('.')?trxnData.celsrm__Balance__c.format():(trxnData.celsrm__Balance__c.format()+'.00')) + '</b> on <b>' + trxnData.celsrm__Disputes__r[0].celsrm__Created_Date__c.format() + '</b>. The last updated status was <b>' + trxnData.celsrm__Disputes__r[0].celsrm__Status__c + '</b> as of <b>' + (trxnData.celsrm__Disputes__r[0].celsrm__Last_Contact_Date__c != null ? trxnData.celsrm__Disputes__r[0].celsrm__Last_Contact_Date__c.format() : 'today') + '</b>. Let us know if any additional inputs required.';
                                script += '</li>';
                                // messageScript += 'Our record shows that a dispute of ' + trxnData.celsrm__Transaction_Disputed_Amount__c.format() + ' was recorded on Invoice ' + trxnData.Name + ' having value of ' + trxnData.celsrm__Balance__c.format() + ' on ' + trxnData.celsrm__Disputes__r[0].celsrm__Created_Date__c.format() + '. The last updated status was ' + trxnData.celsrm__Disputes__r[0].celsrm__Status__c + ' as of ' + (trxnData.celsrm__Disputes__r[0].celsrm__Last_Contact_Date__c != null ? trxnData.celsrm__Disputes__r[0].celsrm__Last_Contact_Date__c.format() : 'today') + '. Let us know if any additional inputs required. ';
                            }
                            // script += 'Our record shows that a dispute of <b>' + trxnData.celsrm__Transaction_Disputed_Amount__c.format() + '</b> was recorded on Invoice <b>' + trxnData.Name + '</b> having value of <b>' + trxnData.celsrm__Balance__c.format() + '</b> on <b>' + trxnData.celsrm__Disputes__r[0].celsrm__Created_Date__c.format() + '</b>. The last updated status was <b>' + trxnData.celsrm__Disputes__r[0].celsrm__Status__c + '</b> as of <b>' + (trxnData.celsrm__Disputes__r[0].celsrm__Last_Contact_Date__c != null ? trxnData.celsrm__Disputes__r[0].celsrm__Last_Contact_Date__c.format() : 'today') + '</b>. Let us know if any additional inputs required.';
                            
                        }
                        script += '</ul>';
                        //script += '<br />';
                    } else {
                        //need to tell that, we will send detail on your registeered email
                        script += 'Since there are multiple records in the system, I\'ll share "Dispute details" over an email for your easy reference and action. Thank you for your Time.<br />';
                    }
                }
                
                String messageScript = 'There are few updates on Invoice(s)';
                if(disp && p2p) {
                    messageScript += ' with regards to disputes & promise to pay. To get more details visit link : sf.lnk/t9MOq4Om54cY';
                } else if (disp) {
                    messageScript += ' with regards to disputes. To get more details visit link : sf.lnk/t9MOq4Om54cY';
                } else if (p2p) {
                    messageScript += ' with regards to promise to pay. To get more details visit link : sf.lnk/t9MOq4Om54cY';
                } else {
                    messageScript += '. To get more details visit link : sf.lnk /t9MOq4Om54cY';
                }
                  
                inMap.put('CallScripts', script);
                inMap.put('WhatsAppMessage', messageScript);
            }
        }
        //for call transcript
        celsrm__User_Preference__c userPref  = new celsrm__User_Preference__c();
        try {
            userPref = [SELECT Id,celsrm__sendStatementListView__c,celsrm__AttachmentTypes__c,celsrm__Is_Attach_Checked__c FROM celsrm__User_Preference__c WHERE celsrm__User__c =:currentUser LIMIT 1];
        } catch (Exception e) {
            System.debug('exception>> ' + e.getMessage());
        }
        if (inMap.get('screenName') != null && (String.valueOf(inMap.get('screenName'))).equalsIgnoreCase('Send Statement')) {
            if(userPref != null && userPref.celsrm__sendStatementListView__c != null){
                inMap.put('ListView',userPref.celsrm__sendStatementListView__c);
            }
            if (userPref != null && userPref.celsrm__Is_Attach_Checked__c != null) {
                inMap.put('AttachCheckBox', userPref.celsrm__Is_Attach_Checked__c);
            }
            if (userPref != null && userPref.celsrm__AttachmentTypes__c != null) {
                inMap.put('StatementFormat', userPref.celsrm__AttachmentTypes__c);
            }
        } else if (inMap.get('ggScreenName') != null && (String.valueOf(inMap.get('ggScreenName'))).equalsIgnoreCase('Send Email')) {
            if (userPref != null && userPref.celsrm__Is_Attach_Checked__c != null) {
                inMap.put('AttachCheckBox',(Boolean)userPref.celsrm__Is_Attach_Checked__c);
            }
            if (userPref != null && userPref.celsrm__AttachmentTypes__c != null) {
                inMap.put('StatementFormat',String.valueOf(userPref.celsrm__AttachmentTypes__c));
            } 
        } else {
            if (userPref != null && userPref.celsrm__Is_Attach_Checked__c != null) {
                inMap.put('Attached',(Boolean)userPref.celsrm__Is_Attach_Checked__c);
            }
        }
        
        return inMap;
    }
}