global with sharing class GOGCustomEmailSend implements celsrm.GOGIScreenCustomLogic {
    global Map < Object, Object > invoke(String functionName, Map < Object, Object > inMap) {
        system.debug('functionName>>' + functionName);
        system.debug('inMap>>' + inMap);
        system.debug('inMap.keySet()>>' + inMap.keySet());
        System.debug('InMap Value:' + inMap.get('notebody'));
        String Contactmethodstr = (String) JSON.serialize(inMap.get('ContactMethod'));
        Contactmethodstr = Contactmethodstr.replaceall('"', '');
        system.debug('Contactmethodstr >>' + Contactmethodstr);
        //-- FIN-9729 | Changed By Dilshad | 24-Apr-2026 | Start --//
        cleanupGeneratedStatementAttachmentIfUnchecked(inMap);
        //-- FIN-9729 | Changed By Dilshad | 24-Apr-2026 | End --//
        //-- Condition Changed | FIN-7406 |7400 | Changed By Megha/Asera | 12 Jun 2025 --//
        if ((Boolean) inMap.get('AttachCheckBox') != null && (Boolean) inMap.get('AttachCheckBox') && ((String) inMap.get('screenName') != 'Send Statement' && (String) inMap.get('screenName') != 'Send Email')) {
            system.debug('inMap>>' + inMap);
            AttachStatementOnAccount obj = new AttachStatementOnAccount();
            obj.invoke(functionName, inMap);
        } 
        //-- Condition Changed | FIN-7406 |7400 | Changed By Megha/Asera | 12 Jun 2025 --//
        //-- FIN-9729 | Changed By Dilshad | 24-Apr-2026 | Start --//
        else if ((Boolean) inMap.get('AttachCheckBox') != null && (Boolean) inMap.get('AttachCheckBox') && ((String) inMap.get('screenName') == 'Send Statement' || (String) inMap.get('screenName') == 'Send Email')) {
            system.debug('inMap>>' + inMap);
            mergeGeneratedStatementAttachment(inMap);
        }
        //-- FIN-9729 | Changed By Dilshad | 24-Apr-2026 | End --//
        if (Contactmethodstr == 'Email' && inMap.containsKey('ComposeEmail') && inMap.get('ComposeEmail') != null) {
            // String str = JSON.serialize(inMap.get('ComposeEmail'));

            // system.debug('str ' + str);
            map < string, object > tempComposeEmail = (map < string, object > ) JSON.deserializeUntyped(JSON.serialize(inMap.get('ComposeEmail')));
            system.debug('tempComposeEmail>>' + tempComposeEmail);

            Id fromId = null;
            if (tempComposeEmail.containsKey('from') && tempComposeEmail.get('from') != null && String.valueOf(tempComposeEmail.get('from')) != '') {
                fromId = (Id) tempComposeEmail.get('from');
                system.debug('fromId>>' + fromId);
            }

            List < String > Toaddress = null;
            if (tempComposeEmail.containsKey('to') && tempComposeEmail.get('to') != null && ((List < object > ) tempComposeEmail.get('to')).size() > 0) {
                Toaddress = new List < string > ();
                List < object > Toaddressobj = ((List < object > ) tempComposeEmail.get('to'));
                for (object obj: Toaddressobj) {
                    if (obj instanceof String) {
                        Toaddress.add(String.valueOf(obj));
                    } else {
                        Map<String, Object> newMap = (Map<String, Object>)obj;
                        Toaddress.add(String.valueOf(newMap.get('value')));
                    }
                }
                system.debug('Toaddress>>' + Toaddress);
            } else {
                throw new celsrm.GOGDataServiceLoadException('Please enter TO Email Address');
            }

            String subject;
            if (tempComposeEmail.containsKey('subject') && tempComposeEmail.get('subject') != null) {
                subject = String.valueOf(tempComposeEmail.get('subject'));
                system.debug('subject>>' + subject);
            } else {
                throw new celsrm.GOGDataServiceLoadException('Please enter value into Subject');
            }

            List < String > ccaddress = null;
            if (tempComposeEmail != null && tempComposeEmail.containsKey('cc') && tempComposeEmail.get('cc') != null && ((List < object > ) tempComposeEmail.get('cc')).size() > 0) {
                List < object > ccaddressls = ((List < object > ) tempComposeEmail.get('cc'));
                ccaddress = new List < string > ();
                for (object obj: ccaddressls) {
                    if (obj instanceof String) {
                        ccaddress.add(String.valueOf(obj));
                    } else {
                        Map<String, Object> newMap = (Map<String, Object>)obj;
                        ccaddress.add(String.valueOf(newMap.get('value')));
                    }
                }
                system.debug('ccaddress>>' + ccaddress);
            }

            List < String > bccaddress = null;
            if (tempComposeEmail.containsKey('bcc') && tempComposeEmail.get('bcc') != null && ((List < Object > ) tempComposeEmail.get('bcc')).size() > 0) {
                List < object > bccaddressls = ((List < object > ) tempComposeEmail.get('bcc'));
                bccaddress = new List < string > ();
                for (object obj: bccaddressls) {
                    if (obj instanceof String) {
                        bccaddress.add(String.valueOf(obj));
                    } else {
                        Map<String, Object> newMap = (Map<String, Object>)obj;
                        bccaddress.add(String.valueOf(newMap.get('value')));
                    }
                }
                system.debug('bccaddress>>' + bccaddress);
            }

            //List<Id> attachmentls = null;
            List < Map < String, String >> attachmentobj = null;
            if (tempComposeEmail.containsKey('attachment') && tempComposeEmail.get('attachment') != null && ((List < object > ) tempComposeEmail.get('attachment')).size() > 0) {
                List < Object > lst = ((List < Object > ) tempComposeEmail.get('attachment'));
                attachmentobj = new List < Map < String, String >> ();
                System.debug('@@@@ lst : ' + lst);
                for (Object obj: lst) {
                    if (obj != null) {
                        Map < String, Object > tmp = (Map < String, Object > ) obj;
                        System.debug('@@@@ tmp : ' + tmp);
                        if (tmp != null && !tmp.isEmpty()) {
                            Map < String, String > attachment = new Map < String, String > ();
                            for (String key: tmp.keySet()) {
                                System.debug('@@@@ tmp key : ' + key);
                                System.debug('@@@@ tmp val: ' + tmp.get(key));
                                attachment.put(key, (String) tmp.get(key));
                            }
                            attachmentobj.add(attachment);
                        }
                    }
                }
                //            system.debug('attachmentls>>'+attachmentls);
            }

            String htmlBody;
            String textbody;
            system.debug('======Dispute======');
            if (tempComposeEmail.containsKey('body') && tempComposeEmail.get('body') != null) {
                htmlBody = String.valueOf(tempComposeEmail.get('body'));
                if ((htmlBody.contains('{Promise.Summary}') && inMap.get('screenName') == 'Promise To Pay') ) {
                    String output = getTemplateSummaryPromiseToPay(inMap);
                    htmlBody = htmlBody.replace('{Promise.Summary}', output);
                }
                if ((htmlBody.contains('{Disputes.summary}') && (inMap.get('screenName') == 'Dispute' || inMap.get('screenName') == 'Send Email Dispute'))) {
                    String output = getTemplateSummaryDispute(inMap);
                    htmlBody = htmlBody.replace('{Disputes.summary}', output);
                }
                system.debug('htmlBody>>' + htmlBody);
            } else if (tempComposeEmail.containsKey('textbody') && tempComposeEmail.get('textbody') != null) {
                textbody = String.valueOf(tempComposeEmail.get('textbody'));
                
            } else {
                throw new celsrm.GOGDataServiceLoadException('Please enter value into body');
            }

            id parentId = null;
            if (inMap.containsKey('Id') && inMap.get('Id') != null) {
                parentId = (Id) inMap.get('Id');
                system.debug('parentId>>' + parentId);
            }

            //By Ravi | 12-02-2020 | user preference
            String currentUser = UserInfo.getUserId();
            String objectName = inMap.get('ListViewObject') != null ? String.valueOf(inMap.get('ListViewObject')) : '';
            celsrm__User_Preference__c userPref  = new celsrm__User_Preference__c();
            try {
                userPref = [SELECT Id FROM celsrm__User_Preference__c WHERE celsrm__User__c =:currentUser LIMIT 1];
            } catch (Exception e) {
                System.debug('exception>> ' + e.getMessage());
            }
            System.debug('objectName>>>> ' + objectName);
            if (inMap.get('screenName') != null && !(String.valueOf(inMap.get('screenName'))).equalsIgnoreCase('Send Statement') && objectName.equalsIgnoreCase('celsrm__Transaction__c')) {
                if (inMap.get('ListView') != null && inMap.get('ListView') != '') {
                    userPref.celsrm__SelectedTransactionListView__c = String.valueOf(inMap.get('ListView'));
                }
                if (inMap.get('TransactionList_SortColumn') != null && inMap.get('TransactionList_SortColumn') != '') {
                    userPref.celsrm__SortListViewField__c = String.valueOf(inMap.get('TransactionList_SortColumn'));
                }
                if(inMap.get('TransactionList_SortOrder') != null && inMap.get('TransactionList_SortOrder') != '') {
                    userPref.celsrm__SortListViewOrderType__c = String.valueOf(inMap.get('TransactionList_SortOrder'));
                }
            } else if (inMap.get('screenName') != null && !(String.valueOf(inMap.get('screenName'))).equalsIgnoreCase('Send Statement') && objectName.equalsIgnoreCase('celsrm__Dispute__c')){
                if (inMap.get('ListView') != null && inMap.get('ListView') != '') {
                    userPref.celsrm__SelectedDisputeListView__c   = String.valueOf(inMap.get('ListView'));
                }
                if (inMap.get('DisputeGrid_SortColumn') != null && inMap.get('DisputeGrid_SortColumn') != '') {
                    userPref.celsrm__DisputeSortListViewField__c = String.valueOf(inMap.get('DisputeGrid_SortColumn'));
                }
                if(inMap.get('DisputeGrid_SortOrder') != null && inMap.get('DisputeGrid_SortOrder') != '') {
                    userPref.celsrm__DisputeSortListViewOrderType__c = String.valueOf(inMap.get('DisputeGrid_SortOrder'));
                }
            } else {
                if (inMap.get('ListView') != null && inMap.get('ListView') != '') {
                    userPref.celsrm__sendStatementListView__c = String.valueOf(inMap.get('ListView'));
                }
            }
            if (inMap.get('ggScreenName') != null && String.valueOf(inMap.get('ggScreenName')) != 'WCM_SendEmailDisputeSC' && String.valueOf(inMap.get('ggScreenName')) == 'WCM__SendEmailReminderSC') {
                userPref.celsrm__Is_Attach_Checked__c = inMap.get('Attached') != null ? (Boolean) inMap.get('Attached') : false;
            } else if(inMap.get('ggScreenName') != null && String.valueOf(inMap.get('ggScreenName')) != 'WCM_SendEmailDisputeSC') {
                userPref.celsrm__Is_Attach_Checked__c = inMap.get('AttachCheckBox') != null ? (Boolean) inMap.get('AttachCheckBox') : false;
                if (inMap.get('StatementFormat') != null) {
                    userPref.celsrm__AttachmentTypes__c = String.valueOf(inMap.get('StatementFormat'));
                }
                
            }
            System.debug('userPref>>>> ' + userPref);
            userPref.celsrm__User__c = currentUser;
            // userPref.celsrm__Org_Wide_Email__c = fromId;
            upsert userPref;
            
            //By Ravi | 12-02-2020 | user preference

            system.debug('=========================attachment '+attachmentobj);

            // celsrm.GOGEmailMapper.sendEmail(fromId, Toaddress, subject, htmlBody, textbody, ccaddress, bccaddress, attachmentobj, parentId);

            celsrm.GOGEmailMapper.SendEmailBean emailBean = new celsrm.GOGEmailMapper.SendEmailBean();
            emailBean.owea = fromId;
            emailBean.to = Toaddress;
            emailBean.subject = subject;
            emailBean.htmlBody = htmlBody;
            emailBean.plainTextBody = textbody;
            emailBean.cc = ccaddress;
            emailBean.bcc = bccaddress;
            emailBean.attachment = attachmentobj;
            emailBean.parentId = parentId;
            emailBean.followUpTaskDueDate = null;
            //-- Starts | FIN-7425 | Changed By Ravi | 12 Aug 2025 --//
            emailBean.sentByAgent = inMap.containsKey('UserType') && inMap.get('UserType') == 'Email Processor Agent' ? true : false;
            //-- Ends | FIN-7425 | Changed By Ravi | 12 Aug 2025 --//
            Map<Object, Object> returnMap = celsrm.GOGEmailMapper.sendEmailWithBean(emailBean);
            //-- Starts | FIN-7025 | Changed By Dilshad | 20 Jan 2025 --//
            if(returnMap.containsKey(false)) {
                inMap.put('ggErrorMessage', String.valueOf(returnMap.get(false)));
            }
            //-- Ends | FIN-7025 | Changed By Dilshad | 20 Jan 2025 --//
        } else if (Contactmethodstr == 'Email') {
            throw new celsrm.GOGDataServiceLoadException('Please enter TO Email Address');
        }
        if((inMap.containsKey('screenName') && ((String)inMap.get('screenName')) != 'Send Statement') || test.isRunningTest()) {
            Map<String, Object> refreshParentValues = new Map<String, Object>();
            if(inMap.containsKey('ListView')) {
                refreshParentValues.put('name', 'ListView');
                refreshParentValues.put('value',inMap.get('ListView'));
                if((String)inMap.get('ListViewObject') == 'celsrm__Dispute__c') {
                    refreshParentValues.put('onChangeMethod','filterDataByViewDispute');
                } else {
                    refreshParentValues.put('onChangeMethod','filterDataByView');
                }
            }
            System.debug('@@@ refreshParentValues : '  +refreshParentValues);
            inMap.put('refreshParentValues', refreshParentValues);
        }
        return inMap;
    }

    public String getTemplateSummaryPromiseToPay(Map < Object, Object > inMap) {
        List < object > tran = (List < object > ) inMap.get('TransactionList');
        String Fields = (String) inMap.get('SummaryFields');
        // String FieldsHeaders = (String)inMap.get('SummaryHeaders');
        List < String > FieldsAPIlst = Fields.split(',');
        //-- Start | FIN-8510 | Changed by Ravi | 10 Oct 2025 --//
        Map<String, Double> totalPromiseAmount = new Map<String, Double>();
        //-- Ends | FIN-8510 | Changed by Ravi | 10 Oct 2025 --//
        List < String > fieldType = new List < String > {};
        Schema.Sobjecttype objType = celsrm__Transaction__c.getSObjectType();
        Schema.Describesobjectresult sobjRes = objType.getDescribe();
        Map < String, Schema.Sobjectfield > fieldMap = sobjRes.fields.getMap();
        String innerHtml = '';

        //-- Starts | FIN-8280| Changed by Asera | 17 April 2026 --//
        // for (String fieldName: FieldsAPIlst) {

        //     Schema.Sobjectfield field = fieldMap.get(fieldName);
        //     String fieldNames1 = field.getDescribe().getLabel();
        //     fieldType.add(fieldNames1);
        //     // system.debug('---fieldType---'+fieldType);
        // }
        //-- FIN-9739 | Changed by Dilshad | 06-May-2026 | Start --//
        String accountLanguageCode = inMap.containsKey('accountLanguageCode') ? String.valueOf(inMap.get('accountLanguageCode')) :  String.valueOf(inMap.get('accountLocale'));
        fieldType = celsrm.SRMUtilityController.getTransactionFieldTranslatedLabel(accountLanguageCode, 'celsrm__Transaction__c', FieldsAPIlst);
        //-- FIN-9739 | Changed by Dilshad | 06-May-2026 | End --//
        //-- End | FIN-8280| Changed by Asera | 17 April 2026 --//
        
        set < Id > tansIdList = new set < Id > ();
        for (Object ts: tran) {
            
            Map < Object, Object > m = (Map < Object, Object > ) ts;
            System.debug('@@@ inMap.get ggScreenName  : ' + inMap.get('ggScreenName'));
            System.debug('@@@ m.containsKey isSelected  : ' + inMap.get('ggScreenName'));
            System.debug('@@@ m.get isSelected  : ' + m.get('isSelected'));
            if(inMap.get('ggScreenName') == 'WCMPromisToPayScreenEmailAction' && ( !m.containsKey('isSelected') || !((Boolean)m.get('isSelected')) )) {
                continue;
            }
            Id key = (String) m.get('Id');
            tansIdList.add(key);
        }
        String query = '';
        List < string > formatedFieldName = UtilityController.getTransactionFieldformat(FieldsAPIlst, 'celsrm__Transaction__c');
        List < String > mdformatedFieldName = new List < String > ();
        for (String fld: formatedFieldName) {
            if (fld == 'format(celsrm__Promised_Amount__c)') {
                fld = 'celsrm__Promised_Amount__c';
                mdformatedFieldName.add(fld);
            } else {
                mdformatedFieldName.add(fld);
            }
        }
        if(mdformatedFieldName.indexOf('CurrencyIsoCode') == -1) {
            mdformatedFieldName.add('CurrencyIsoCode');
        }
        String Queryfields = string.join(mdformatedFieldName, ',');
        query = 'select' + ' ' + Queryfields + ',format(celsrm__Promised_Amount__c) PromisedAmount';
        query = query + ' ' + 'from celsrm__Transaction__c';
        query = query + ' ' + 'Where Id in:tansIdList';
        system.debug('---query---' + query);
        List < celsrm__Transaction__c > trxList = Database.query(query);
        //-- Start | FIN-8048 | Changed by Ravi | 29 July 2025 --//
        innerHtml = '<table width="100%" class="billing" style="border-collapse:collapse;padding:0px;border:1px solid gray;">';
        //-- End | FIN-8048 | Changed by Ravi | 29 July 2025 --//
        innerHtml += '<tr>';
        for (String obj: fieldType) {
            //-- Start | FIN-8048 | Changed by Ravi | 29 July 2025 --//
           innerHtml += '<th width="auto" style="border:1px solid gray;text-align:left;">' + obj + '</th>';
           //-- End | FIN-8048 | Changed by Ravi | 29 July 2025 --//
        }
        innerHtml += '</tr>';
        Object fieldvalue;
        //-- Start | FIN-8510 | Changed by Ravi | 10 Oct 2025 --//
        String screenLevelCurrencyIsoCode = inMap.containsKey('CurrencyIsoCode') ? String.valueOf(inMap.containsKey('CurrencyIsoCode')) : UserInfo.getDefaultCurrency();
        //-- Ends | FIN-8510 | Changed by Ravi | 10 Oct 2025 --//
        for (celsrm__Transaction__c dtx: trxList) {
            innerHtml += '<tr>';

            for (String fieldName: FieldsAPIlst) {
                Schema.Sobjectfield field = fieldMap.get(fieldName);
                Schema.Displaytype fieldDataType = field.getDescribe().getType();
                String fType = field.getDescribe().getType().name();
                if (fieldName == 'celsrm__Promised_Amount__c') {
                    fieldName = 'PromisedAmount';
                }
                // << START - MM - FIN-9717 - Create Promise -> Sent Email -> celsrm__Balance__c not formatted>>
                if (fieldName == 'celsrm__balance__c') {
                    fieldName = 'Balance';
                }
                // << END - MM - FIN-9717 - Create Promise -> Sent Email -> celsrm__Balance__c not formatted>>
                if (fieldDataType == Schema.DisplayType.REFERENCE) {

                    fieldName = fieldName.subString(0, fieldName.length() - 1) + 'r';
                    fieldvalue = dtx.getSobject(fieldName).get('name');

                } else if (fType == 'DATE') {
                    if (dtx.get(fieldName) != null) {
                        system.debug('----else ifff');
                        Date dtTemp = (Date) dtx.get(fieldName);

                        fieldvalue = dtTemp.format();
                    } else {
                        fieldvalue = '';
                    }
                } else {

                    fieldvalue = dtx.get(fieldName);
                    if (fieldvalue == null) {
                        fieldvalue = '';
                    }
                }
                //-- Start | FIN-8048 | Changed by Ravi | 29 July 2025 --//
                innerHtml += '<td width="auto" style="text-align:left;border:solid 1px gray;white-space:nowrap;">' + fieldvalue + '</td>';
                //-- End | FIN-8048 | Changed by Ravi | 29 July 2025 --//
            }
            innerHtml += '</tr>';
            double newAmt = dtx.celsrm__Promised_Amount__c == null ? 0 : dtx.celsrm__Promised_Amount__c;
            // << START - MM - FIN-8503 - Instead of screen currency, use account currency>>
            String accountCurrency = UserInfo.getDefaultCurrency();
            if (inMap.keySet().contains('accountCurrencyIsoCode') && inMap.get('accountCurrencyIsoCode') != null) { 
                accountCurrency = (String)inMap.get('accountCurrencyIsoCode');
            }
            // << END - MM - FIN-8503 - Instead of screen currency, use account currency>>
            //-- Start | FIN-8510 | Changed by Ravi | 10 Oct 2025 --//
            // << START - MM - FIN-8503 - Instead of screen currency, use account currency>>
            // String CurrencyIsoCode = dtx.get('CurrencyIsoCode') == null ? screenLevelCurrencyIsoCode : String.valueOf(dtx.get('CurrencyIsoCode'));
            String CurrencyIsoCode = dtx.get('CurrencyIsoCode') == null ? accountCurrency : String.valueOf(dtx.get('CurrencyIsoCode'));
            // << END - MM - FIN-8503 - Instead of screen currency, use account currency>>
            PromiseToPayActionController.createMapCurBalance(CurrencyIsoCode, newAmt, totalPromiseAmount);
            // totalPromiseAmount = totalPromiseAmount + newAmt;
            //-- Ends | FIN-8510 | Changed by Ravi | 10 Oct 2025 --//
        }
        innerHtml += '<tr>';
        //-- Start | FIN-8510 | Changed by Ravi | 10 Oct 2025 --//
        String TotalBal = PromiseToPayActionController.strTotalBalanceSummary(totalPromiseAmount);
        //-- Ends | FIN-8510 | Changed by Ravi | 10 Oct 2025 --//
        //-- Start | FIN-8048 | Changed by Ravi | 29 July 2025 --//
        innerHtml += '<td colspan=' + FieldsAPIlst.size() + ' style="text-align:right;border:solid 1px gray;white-space:nowrap;"> <b> Total</b>  ' + TotalBal + '</td>';
        //-- End | FIN-8048 | Changed by Ravi | 29 July 2025 --//
        innerHtml += '</tr>';
        innerHtml += '</table>';
        return innerHtml;
    }

    public String getTemplateSummaryDispute(Map < Object, Object > inMap) {
        List < celsrm__Dispute__c> tran = new List < celsrm__Dispute__c>();
        system.debug('---displist---' + inMap.get('DisputeGrid') );
        String Fields = (String) inMap.get('SummaryFields');
        if(inMap.containsKey('DisputeList') ){
         tran = (List < celsrm__Dispute__c> ) inMap.get('DisputeList');
         }
       // system.debug('---tran---' + tran);
       set < Id > disputeIdList = new set < Id > ();
        if(inMap.containsKey('DisputeGrid') ){
         List < object > tran2 = (List < object > ) inMap.get('DisputeGrid');
          for (Object ts: tran2) {
                try{
                    Map < Object, Object > m = (Map < Object, Object > ) ts;
                    Id key = (String) m.get('Id');
                    disputeIdList .add(key);
                    
                } Catch(Exception ex){
                    Map < string, Object > m = (Map < string, Object > ) ts;
                    Id key = (String) m.get('Id');
                    disputeIdList .add(key);

                }
            
          }
           String finalQuery = 'SELECT ' +Fields+' FROM celsrm__Dispute__c Where Id in:disputeIdList';
                System.debug('final query : ' + finalQuery);
                tran  = database.query(finalQuery);
       // tran = (List < celsrm__Dispute__c> )tran2 ;
        
        }
        system.debug('---tran---' + tran);
        
        system.debug('---Fields---' + Fields);
        //-- Start | FIN-8510 | Changed by Ravi | 10 Oct 2025 --//
        Map<String, Double> totalDisputeAmount = new Map<String, Double>();
        //-- Ends | FIN-8510 | Changed by Ravi | 10 Oct 2025 --//
        // String FieldsHeaders = (String)inMap.get('SummaryHeaders');
        List < String > FieldsAPIlst = Fields.split(',');
        List < String > fieldType = new List < String > {};
        Schema.Sobjecttype objType = celsrm__Dispute__c.getSObjectType();
        Schema.Describesobjectresult sobjRes = objType.getDescribe();
        Map < String, Schema.Sobjectfield > fieldMap = sobjRes.fields.getMap();
        String innerHtml = '';
       
        // << START - MM - FIN-8174 - Dynamic translated headers based account local | Dynamic headers in Dispute Email table>>
        // for (String fieldName: FieldsAPIlst) {

        //     Schema.Sobjectfield field = fieldMap.get(fieldName);
        //     String fieldNames1 = field.getDescribe().getLabel();
        //     fieldType.add(fieldNames1);
        //     system.debug('---fieldType---' + fieldType);
        // }
        String accountLanguageCode = inMap.containsKey('accountLanguageCode') ? String.valueOf(inMap.get('accountLanguageCode')) :  String.valueOf(inMap.get('accountLocale'));
        fieldType = celsrm.SRMUtilityController.getTransactionFieldTranslatedLabel(accountLanguageCode, 'celsrm__Dispute__c', FieldsAPIlst);
        // << END - MM - FIN-8174 - Dynamic translated headers based account local | Dynamic headers in Dispute Email table>>
         system.debug('---tran---' + tran);
        set < Id > tansIdList = new set < Id > ();
        for (celsrm__Dispute__c ts: tran) {
                 system.debug('---ts---' + ts);
           //   Map<Object, Object> m = (Map<Object, Object>)ts;
            //  system.debug('---m---' + m);
          /*  if(inMap.get('ggScreenName') == 'WCMCreateDisputeScreenEmailAction' ) {
                continue;
            }*/
            Id key = (String) ts.get('Id');
            tansIdList.add(key);
        }
        system.debug('---tansIdList ---' + tansIdList);
        String query = '';
        List < string > formatedFieldName = UtilityController.getTransactionFieldformat(FieldsAPIlst, 'celsrm__Dispute__c');
        List < String > mdformatedFieldName = new List < String > ();
        system.debug('---formatedFieldName ---' + formatedFieldName);
        for (String fld: formatedFieldName) {
            if (fld == 'format(celsrm__Amount__c)') {
                fld = 'celsrm__Amount__c';
                mdformatedFieldName.add(fld);
            } else {
                mdformatedFieldName.add(fld);
            }
        }
        if(mdformatedFieldName.indexOf('CurrencyIsoCode') == -1) {
            mdformatedFieldName.add('CurrencyIsoCode');
        }
        String Queryfields = string.join(mdformatedFieldName, ',');
        query = 'select' + ' ' + Queryfields + ',format(celsrm__Amount__c) Amount';
        //query = 'select' + ' ' + Queryfields + ',celsrm__Transaction__r.Name,celsrm__Account__r.Name,format(celsrm__Amount__c) Amount';
        query = query + ' ' + 'from celsrm__Dispute__c';
        query = query + ' ' + 'Where Id in:tansIdList';
        system.debug('---query---' + query);
        //  string trxquery = 'select id,name,celsrm__balance__c,Amount__c,celsrm__account__c,account__r.Name from celsrm__Dispute__c where celsrm__balance__c !=0 and celsrm__account__c //=: accountID and id in :transactionIds limit 5000';
        List < celsrm__Dispute__c > trxList = Database.query(query);
        //-- Start | FIN-8048 | Changed by Ravi | 29 July 2025 --//
        innerHtml = '<table width="100%" class="billing" style="border-collapse:collapse;font-family:verdana;">';
        //-- End | FIN-8048 | Changed by Ravi | 29 July 2025 --//
        innerHtml += '<tr>';
        for (String obj: fieldType) {
           // innerHtml += '<th width="auto" style="background-color:#D7CEC7;color:#76323F;border:1px solid gray;text-align: left;padding: 6px 6px 6px 3px;font-family:verdana ;">' + obj + '</th>';
           //-- Start | FIN-8048 | Changed by Ravi | 29 July 2025 --// 
           innerHtml += '<th width="auto" style="border:1px solid gray;text-align:left;">' + obj + '</th>';
            //-- End | FIN-8048 | Changed by Ravi | 29 July 2025 --//
        }
        innerHtml += '</tr>';
        Object fieldvalue;
        //-- Start | FIN-8510 | Changed by Ravi | 10 Oct 2025 --//
        String screenLevelCurrencyIsoCode = inMap.containsKey('CurrencyIsoCode') ? String.valueOf(inMap.containsKey('CurrencyIsoCode')) : UserInfo.getDefaultCurrency();
        //-- Ends | FIN-8510 | Changed by Ravi | 10 Oct 2025 --//
        for (celsrm__Dispute__c dtx: trxList) {
            innerHtml += '<tr>';
            for (String fieldName: FieldsAPIlst) {
                Schema.Sobjectfield field = fieldMap.get(fieldName);
                Schema.Displaytype fieldDataType = field.getDescribe().getType();
                String fType = field.getDescribe().getType().name();
                if (fieldName == 'celsrm__Amount__c') {
                    fieldName = 'Amount';
                }
                if (fieldDataType == Schema.DisplayType.REFERENCE) {

                    fieldName = fieldName.subString(0, fieldName.length() - 1) + 'r';
                    fieldvalue = dtx.getSobject(fieldName).get('name');

                } else if (fType == 'DATE') {
                    if (dtx.get(fieldName) != null) {
                        system.debug('----else ifff');
                        Date dtTemp = (Date) dtx.get(fieldName);

                        fieldvalue = dtTemp.format();
                    } else {
                        fieldvalue = '';
                    }
                } else {

                    fieldvalue = dtx.get(fieldName);
                    if (fieldvalue == null) {
                        fieldvalue = '';
                    }
                }
                //-- Start | FIN-8048 | Changed by Ravi | 29 July 2025 --//
                innerHtml += '<td width="auto" style="text-align:left;border:solid 1px gray;white-space:nowrap;">' + fieldvalue + '</td>';
                //-- End | FIN-8048 | Changed by Ravi | 29 July 2025 --//
            }
            innerHtml += '</tr>';
            double newAmt = dtx.celsrm__Amount__c == null ? 0 : dtx.celsrm__Amount__c;
            // << START - MM - FIN-8503 - Instead of screen currency, use account currency>>
            String accountCurrency = UserInfo.getDefaultCurrency();
            if (inMap.keySet().contains('accountCurrencyIsoCode') && inMap.get('accountCurrencyIsoCode') != null) { 
                accountCurrency = (String)inMap.get('accountCurrencyIsoCode');
            }
            // << END - MM - FIN-8503 - Instead of screen currency, use account currency>>
            //-- Start | FIN-8510 | Changed by Ravi | 10 Oct 2025 --//
            // << START - MM - FIN-8503 - Instead of screen currency, use account currency>>
            // String CurrencyIsoCode = dtx.get('CurrencyIsoCode') == null ? screenLevelCurrencyIsoCode : String.valueOf(dtx.get('CurrencyIsoCode'));
            String CurrencyIsoCode = dtx.get('CurrencyIsoCode') == null ? accountCurrency : String.valueOf(dtx.get('CurrencyIsoCode'));
            // << END - MM - FIN-8503 - Instead of screen currency, use account currency>>
            PromiseToPayActionController.createMapCurBalance(CurrencyIsoCode, newAmt, totalDisputeAmount);
            // totalDisputeAmount = totalDisputeAmount + newAmt;
            //-- Ends | FIN-8510 | Changed by Ravi | 10 Oct 2025 --//
        }
        innerHtml += '<tr>';
        //-- Start | FIN-8510 | Changed by Ravi | 10 Oct 2025 --//
        String TotalBal = PromiseToPayActionController.strTotalBalanceSummary(totalDisputeAmount);
        //-- Ends | FIN-8510 | Changed by Ravi | 10 Oct 2025 --//
        //-- Start | FIN-8048 | Changed by Ravi | 29 July 2025 --//
        innerHtml += '<td colspan=' + FieldsAPIlst.size() + ' style="text-align:right;border:solid 1px gray;white-space:nowrap;"> <b> Total</b>  ' + TotalBal + '</td>';
        //-- End | FIN-8048 | Changed by Ravi | 29 July 2025 --//
        innerHtml += '</tr>';
        innerHtml += '</table>';
        return innerHtml;
    }

    //-- FIN-9729 | Changed By Dilshad | 24-Apr-2026 | Start --//
    @TestVisible
    private static void mergeGeneratedStatementAttachment(Map<Object, Object> inMap) {
        if (inMap == null) {
            return;
        }

        String contentVersionId = inMap.containsKey('ContentIDSendStmt') && inMap.get('ContentIDSendStmt') != null
            ? String.valueOf(inMap.get('ContentIDSendStmt'))
            : null;
        if (String.isBlank(contentVersionId)) {
            return;
        }

        String fileName = inMap.get('fileName') != null && String.valueOf(inMap.get('fileName')).trim() != ''
            ? String.valueOf(inMap.get('fileName')).trim()
            : 'BillingStatement';
        if (fileName.toLowerCase().endsWith('.pdf')) {
            fileName = fileName.substring(0, fileName.length() - 4);
        }

        String fileTitle = fileName + '.pdf';
        Map<Object, Object> statementAttachment = new Map<Object, Object>{
            'Id' => contentVersionId,
            'Title' => fileTitle,
            'FileType' => 'PDF'
        };

        Map<Object, Object> composeEmail = inMap.containsKey('ComposeEmail') && inMap.get('ComposeEmail') != null
            ? (Map<Object, Object>)inMap.get('ComposeEmail')
            : new Map<Object, Object>();
        List<Object> attachments = composeEmail.containsKey('attachment') && composeEmail.get('attachment') != null
            ? (List<Object>)composeEmail.get('attachment')
            : new List<Object>();

        Boolean replaced = false;
        for (Integer i = 0; i < attachments.size(); i++) {
            if (attachments[i] == null) {
                continue;
            }

            Map<Object, Object> currentAttachment = (Map<Object, Object>)attachments[i];
            String currentId = currentAttachment.containsKey('Id') && currentAttachment.get('Id') != null
                ? String.valueOf(currentAttachment.get('Id'))
                : null;
            String currentTitle = currentAttachment.containsKey('Title') && currentAttachment.get('Title') != null
                ? String.valueOf(currentAttachment.get('Title'))
                : (currentAttachment.containsKey('title') && currentAttachment.get('title') != null
                    ? String.valueOf(currentAttachment.get('title'))
                    : null);

            if (
                currentId == contentVersionId ||
                (String.isNotBlank(currentTitle) && currentTitle.contains(fileName))
            ) {
                attachments[i] = statementAttachment;
                replaced = true;
                break;
            }
        }

        if (!replaced) {
            attachments.add(statementAttachment);
        }

        composeEmail.put('attachment', attachments);
        inMap.put('ComposeEmail', composeEmail);
    }

    @TestVisible
    private static void cleanupGeneratedStatementAttachmentIfUnchecked(Map<Object, Object> inMap) {
        if (inMap == null) {
            return;
        }

        String screenName = inMap.containsKey('screenName') && inMap.get('screenName') != null
            ? String.valueOf(inMap.get('screenName'))
            : null;
        Boolean isStatementScreen = screenName == 'Send Statement' || screenName == 'Send Email';
        Boolean attachEnabled = inMap.containsKey('AttachCheckBox') && inMap.get('AttachCheckBox') != null
            ? (Boolean)inMap.get('AttachCheckBox')
            : false;
        if (!isStatementScreen || attachEnabled) {
            return;
        }

        String contentVersionId = inMap.containsKey('ContentIDSendStmt') && inMap.get('ContentIDSendStmt') != null
            ? String.valueOf(inMap.get('ContentIDSendStmt'))
            : null;
        if (String.isBlank(contentVersionId)) {
            return;
        }

        removeGeneratedStatementAttachmentReference(inMap, contentVersionId);
        inMap.remove('ContentIDSendStmt');
        inMap.remove('ContentDocID');
    }

    @TestVisible
    private static void removeGeneratedStatementAttachmentReference(Map<Object, Object> inMap, String contentVersionId) {
        if (
            inMap == null ||
            !inMap.containsKey('ComposeEmail') ||
            inMap.get('ComposeEmail') == null ||
            String.isBlank(contentVersionId)
        ) {
            return;
        }

        Map<Object, Object> composeEmail = (Map<Object, Object>)inMap.get('ComposeEmail');
        if (!composeEmail.containsKey('attachment') || composeEmail.get('attachment') == null) {
            return;
        }

        List<Object> attachments = (List<Object>)composeEmail.get('attachment');
        for (Integer i = attachments.size() - 1; i >= 0; i--) {
            if (attachments[i] == null) {
                continue;
            }

            Map<Object, Object> attachment = (Map<Object, Object>)attachments[i];
            String currentId = attachment.containsKey('Id') && attachment.get('Id') != null
                ? String.valueOf(attachment.get('Id'))
                : null;
            if (currentId == contentVersionId) {
                attachments.remove(i);
            }
        }

        composeEmail.put('attachment', attachments);
        inMap.put('ComposeEmail', composeEmail);
    }
    //-- FIN-9729 | Changed By Dilshad | 24-Apr-2026 | End --//
}