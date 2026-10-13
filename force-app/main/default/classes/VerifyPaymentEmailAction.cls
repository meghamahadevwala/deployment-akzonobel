global with sharing class VerifyPaymentEmailAction implements celsrm.GOGIScreenCustomLogic {
    global Map<Object, Object> invoke(String functionName, Map<Object, Object> inMap) {
        if(functionName == 'fetchTrasactionData'){
            inMap = fetchTrasactionData(inMap);
        } else if(functionName == 'submitVerifyPayment'){
            inMap = submitVerifyPayment(inMap);
        }
        return inMap;
    }
    @AuraEnabled
    public static Map<Object, Object> fetchTrasactionData(Map<Object, Object> inMap){
        double PromisedAmt;
        date PromiseDT=null;
        if(inMap.containsKey('activityData')) {
            Map<Object, Object> aData = (Map<Object, Object>)inMap.get('activityData');
            String t = (String)aData.get('Id');
            // EmailMessage result = [SELECT celsrm__Classification_Response__c from EmailMessage where Id =: t];
            // Map<String, Object> res = (Map<String, Object>)JSON.deserializeUntyped((String)result.celsrm__Classification_Response__c);
            //-- Starts | FIN-6410| Changes By: Asera | 19 Sep 2024 --//
            Map<String, Object> res = new Map<String, Object>();
            if(t != ''){
                String classificationResponseString = celsrm.SRMUtilityController.getClassificationResponse(t); 
                if(classificationResponseString != null && classificationResponseString != ''){
                    res = (Map <string, object> ) JSON.deserializeUntyped(classificationResponseString);
                } 
            }
            //-- End | FIN-6410| Changes By: Asera | 19 Sep 2024 --//
            List<String> invoiceNoList = new List<String>();
            if(res.containsKey('entities')) {
                List<Object> ent = (List<Object>)res.get('entities');
                if(ent.size() > 0) {
                    for(Object o : ent) {
                        Map<String, Object> tempMap = (Map<String, Object>)o;
                        if( tempMap.get('dim') == 'invoice_no' ) {
                            String invoiceValue = (String)(tempMap.get('value'));
                            invoiceNoList.add(invoiceValue);
                        }
                        if( tempMap.get('dim') == 'amount-of-money' ) {
                            System.debug('@@@ amount: ' + (tempMap.get('value')));
                            Map<String, Object> innerMap = ((Map<String, Object>)tempMap.get('value'));
                            PromisedAmt = Double.valueOf(innerMap.get('value'));
                            System.debug('@@@ PromisedAmt : ' + PromisedAmt );
                        }
                        if(tempMap.get('dim') == 'time' ) {
                            Map<String, Object> obj =  ((Map<String, Object>)tempMap.get('value'));
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
            if(res.containsKey('table_entity')){
                List<Object> tableEnt = (List<Object>)res.get('table_entity');
                for(Object o : tableEnt) {
                    Map<String, Object> tempMap = (Map<String, Object>)o;
                    if (tempMap.containsKey('source') && String.valueOf(tempMap.get('source')).equalsIgnoreCase('emailbody')) {
                        if (tempMap.containsKey('tableMetadata') && tempMap.containsKey('tableData')) {
                            Map<String, Object> tableMetaData = (Map<String, Object>)tempMap.get('tableMetadata');
                            String fieldName = '';
                            for (String tableMetaDataKey : tableMetaData.keySet()) {
                                Map<String,Object> meta = (Map<String,Object>)tableMetaData.get(tableMetaDataKey);
                                if (meta.containsKey('dim') && meta.get('dim') != null && meta.get('dim') == 'invoice_no') {
                                    fieldName = tableMetaDataKey;
                                    break;
                                }
                            }
                            if (fieldName != '') {
                                List<Object> tableData = (List<Object>)tempMap.get('tableData');
                                if (tableData.size() > 0) {
                                    for (Object td : tableData) {
                                        Map<String,Object> tablerow = (Map<String,Object>)td;
                                        if (tablerow.get(fieldName) != null) {
                                            invoiceNoList.add(String.valueOf(tablerow.get(fieldName)));
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            if (!invoiceNoList.isEmpty() && invoiceNoList.size() > 0) {
                List<celsrm__transaction__c> trxList = [SELECT Id,Name,celsrm__Amount__c,celsrm__Balance__c,celsrm__Close_Date__c FROM celsrm__transaction__c WHERE Name IN :invoiceNoList];
                if (trxList.size() > 0) {
                    List<Map<String,Object>> trasactionList = new List<Map<String,Object>>();
                    for (celsrm__transaction__c trx : trxList) {
                        Map<String,Object> tempTrx = new Map<String,Object>();
                        tempTrx.put('Name', trx.Name);
                        tempTrx.put('Id', trx.Id);
                        tempTrx.put('celsrm__Amount__c', trx.celsrm__Amount__c);
                        tempTrx.put('celsrm__Balance__c', trx.celsrm__Balance__c);
                        tempTrx.put('celsrm__Close_Date__c', trx.celsrm__Close_Date__c);
                        if (trx.celsrm__Balance__c == 0 || trx.celsrm__Balance__c == null) {
                            tempTrx.put('Description', 'Paid');
                        } else {
                            tempTrx.put('Description', 'Not Paid');
                            if (PromisedAmt != null && PromiseDT !=null) {
                                tempTrx.put('celsrm__Promised_Amount__c',decimal.valueOf(PromisedAmt )); 
                                tempTrx.put('celsrm__Promise_Date__c',PromiseDT );
                            } else {
                                tempTrx.put('celsrm__Promised_Amount__c',trx.celsrm__Balance__c); 
                                tempTrx.put('celsrm__Promise_Date__c',date.today().adddays(5));
                            }
                        }
                        
                        trasactionList.add(tempTrx);
                    }
                    inMap.put('TransactionList', trasactionList);
                }
            }
        }
        return inMap;
    }
    @AuraEnabled
    public static Map<Object, Object> submitVerifyPayment(Map<Object, Object> inMap){
        List<Object> trxns = (List<Object>)inMap.get('TransactionList');
         Set<Id> TransIDS = new Set<Id>();
        for(Object trxn : trxns) {
            map < Object, Object> m = (map < Object, Object > )trxn;
             Id trxId = (Id)m.get('Id');
                
            if (m.containsKey('isSelected') && ((Boolean)m.get('isSelected')) && m.containsKey('Description') && m.get('Description') != null && m.get('Description') != 'Paid') {
               TransIDS.add(trxId );
                System.debug('celsrm__Promised_Amount__c-->'+Double.valueOf(m.get('celsrm__Promised_Amount__c')));
                System.debug('celsrm__Promised_Amount__c-->'+m.get('celsrm__Promised_Amount__c') == null || Double.valueOf(m.get('celsrm__Promised_Amount__c')) <= 0 || (Double.valueOf(m.get('celsrm__Promised_Amount__c')) > Double.valueOf(m.get('celsrm__Balance__c'))));
                if (m.containsKey('celsrm__Promised_Amount__c') && (m.get('celsrm__Promised_Amount__c') == null || Double.valueOf(m.get('celsrm__Promised_Amount__c')) <= 0 || (Double.valueOf(m.get('celsrm__Promised_Amount__c')) > Double.valueOf(m.get('celsrm__Balance__c'))))) {
                    throw new celsrm.GOGDataServiceLoadException('Please Enter Valid Promised Amount For ' + m.get('Name'));
                }
                if (m.containsKey('celsrm__Promise_Date__c') && (m.get('celsrm__Promise_Date__c') == null || date.valueOf((String)m.get('celsrm__Promise_Date__c')) < Date.today())) {
                    throw new celsrm.GOGDataServiceLoadException('Please Select Valid Promised Date For ' + m.get('Name'));
                }
            }
        }
        if (TransIDS.isEmpty() || TransIDS.size() == 0) {
            throw new celsrm.GOGDataServiceLoadException('Please Select atleast one Transaction for Promise');
        }
        Map<id,celsrm__Transaction__c> MapTransOlderNotes=new Map<Id,celsrm__Transaction__c>([select id, celsrm__Latest_Note__c from celsrm__Transaction__c where id in : TransIDS ]); 
        List < celsrm__Transaction__c > trxList = new List < celsrm__Transaction__c > ();
        for(Object trxn : trxns) {
            map < Object, Object> m = (map < Object, Object > )trxn;
            String trxId = (String)m.get('Id'); 
            celsrm__Transaction__c currentTrx = New celsrm__Transaction__c(Id=trxId  );
            if(String.valueOf(inMap.get('NoteBody')) != null){
                currentTrx.celsrm__Latest_Note_Title__c = String.valueOf(inMap.get('NoteTitle'));
                currentTrx.celsrm__Latest_Note_Date__c = date.today();
                //  currentTrx.Latest_Note__c = String.valueOf(inMap.get('NoteTitle')) + '\n' + String.valueOf(inMap.get('NoteBody'));
                currentTrx.celsrm__Latest_Note__c =  String.valueOf(inMap.get('NoteBody'));     
                // currentTrx.celsrm__Latest_Notes_Entered_By__c = UserInfo.getUserId();
                // currentTrx.celsrm__Notes__c = date.today().day() + '-' + date.today().month() + '-' + date.today().year() + ':' + UserInfo.getName() + ':' + String.valueOf(inMap.get('NoteTitle')) + '\n' + String.valueOf(inMap.get('NoteBody')) + '\n\n' + (MapTransOlderNotes.get(trxId).celsrm__Notes__c != null && MapTransOlderNotes.get(trxId).celsrm__Notes__c != '' ? MapTransOlderNotes.get(trxId).celsrm__Notes__c : '');
                // currentTrx.celsrm__Notes__c = date.newInstance(date.today().year(),date.today().month(),date.today().day()).format() + ':' + UserInfo.getName() + ':' + String.valueOf(inMap.get('NoteTitle')) + '\n' + String.valueOf(inMap.get('NoteBody')) + '\n\n' + (MapTransOlderNotes.get(trxId).celsrm__Notes__c != null && MapTransOlderNotes.get(trxId).celsrm__Notes__c != '' ? MapTransOlderNotes.get(trxId).celsrm__Notes__c : '');
            }
            if (m.containsKey('Description') && m.get('Description') != null && m.get('Description') != 'Paid') {
                currentTrx.celsrm__Promised_Amount__c = Double.valueOf(m.get('celsrm__Promised_Amount__c'));
                currentTrx.celsrm__Promise_Date__c = date.valueOf(m.get('celsrm__Promise_Date__c') + ' 00:00:00');
            }
            trxList.add(currentTrx);
        }
        if (trxList != null && trxList.size() > 0) {
            update trxList;
        }
        String Contactmethodstr = (String) JSON.serialize(inMap.get('ContactMethod'));
        Contactmethodstr = Contactmethodstr.replaceall('"', '');
        if (Contactmethodstr == 'Email' && inMap.containsKey('ComposeEmail') && inMap.get('ComposeEmail') != null) {
            map < string, object > tempComposeEmail = (map < string, object > ) JSON.deserializeUntyped(JSON.serialize(inMap.get('ComposeEmail')));
            Id fromId = null;
            if (tempComposeEmail.containsKey('from') && tempComposeEmail.get('from') != null && String.valueOf(tempComposeEmail.get('from')) != '') {
                fromId = (Id) tempComposeEmail.get('from');
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
            } else {
                throw new celsrm.GOGDataServiceLoadException('Please enter TO Email Address');
            }

            String subject;
            if (tempComposeEmail.containsKey('subject') && tempComposeEmail.get('subject') != null) {
                subject = String.valueOf(tempComposeEmail.get('subject'));
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
            }

            List < Map < String, String >> attachmentobj = null;
            if (tempComposeEmail.containsKey('attachment') && tempComposeEmail.get('attachment') != null && ((List < object > ) tempComposeEmail.get('attachment')).size() > 0) {
                List < Object > lst = ((List < Object > ) tempComposeEmail.get('attachment'));
                attachmentobj = new List < Map < String, String >> ();
                for (Object obj: lst) {
                    if (obj != null) {
                        Map < String, Object > tmp = (Map < String, Object > ) obj;
                        if (tmp != null && !tmp.isEmpty()) {
                            Map < String, String > attachment = new Map < String, String > ();
                            for (String key: tmp.keySet()) {
                                attachment.put(key, (String) tmp.get(key));
                            }
                            attachmentobj.add(attachment);
                        }
                    }
                }
            }

            String htmlBody;
            String textbody;
            if (tempComposeEmail.containsKey('body') && tempComposeEmail.get('body') != null) {
                htmlBody = String.valueOf(tempComposeEmail.get('body'));
                if (htmlBody.contains('{VerifyPayment.Summary}')) {
                    String output = getTemplateSummary(inMap);
                    htmlBody = htmlBody.replace('{VerifyPayment.Summary}', output);
                }
            } else if (tempComposeEmail.containsKey('textbody') && tempComposeEmail.get('textbody') != null) {
                textbody = String.valueOf(tempComposeEmail.get('textbody'));
                if (textbody.contains('{VerifyPayment.Summary}')) {
                    String output = getTemplateSummary(inMap);
                    textbody = textbody.replace('{VerifyPayment.Summary}', output);
                }
            } else {
                throw new celsrm.GOGDataServiceLoadException('Please enter value into body');
            }

            id parentId = null;
            if (inMap.containsKey('RelatedToId') && inMap.get('RelatedToId') != null) {
                parentId = (Id) inMap.get('RelatedToId');
            }
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
            celsrm.GOGEmailMapper.sendEmailWithBean(emailBean);

            if(inMap.containsKey('activityData')) {
                Map<Object, Object> aData = (Map<Object, Object>)inMap.get('activityData');
                String emailId = (String)aData.get('Id');
                EmailMessage ems = new EmailMessage();
                ems.Id = emailId;
                // ems.celsrm__Action__c = 'Verify Payment';
                // ems.celsrm__Action_By__c = UserInfo.getUserId();
                // ems.celsrm__Action_On__c = Datetime.now();
                update ems;
            }
        }
        return inMap;
    }

    Public static String getTemplateSummary(Map < Object, Object > inMap) {
        List<object> tran = (List<object>) inMap.get('TransactionList');
        String summaryFields = (String) inMap.get('PaidSummaryFields');
        List<String> FieldsAPIlst = summaryFields.split(',');
        summaryFields = (String) inMap.get('OpenSummaryFields');
        List<String> openFieldsAPIlst = summaryFields.split(',');
        String paidInnerHtml = '';
        //-- Start | FIN-8048 | Changed by Ravi | 29 July 2025 --//
        paidInnerHtml = '<table width="100%" class="billing" style="border-collapse:collapse;padding:0px;border:1px solid gray;font-family:verdana;">';
        //-- End | FIN-8048 | Changed by Ravi | 29 July 2025 --//
        paidInnerHtml += '<tr>';
        String openInnerHtml = paidInnerHtml;
        Schema.Sobjecttype objType = celsrm__Transaction__c.getSObjectType();
        Schema.Describesobjectresult sobjRes = objType.getDescribe();
        Map < String, Schema.Sobjectfield > fieldMap = sobjRes.fields.getMap();
        for (String fieldName: FieldsAPIlst) {
            Schema.Sobjectfield field = fieldMap.get(fieldName);
            String fieldNames1 = field.getDescribe().getLabel();
            //-- Start | FIN-8048 | Changed by Ravi | 29 July 2025 --//
            paidInnerHtml += '<th width="auto" style="border:1px solid gray;text-align:left;">' + fieldNames1 + '</th>';
            //-- End | FIN-8048 | Changed by Ravi | 29 July 2025 --//
        }
        for (String fieldName: openFieldsAPIlst) {
            Schema.Sobjectfield field = fieldMap.get(fieldName);
            String fieldNames1 = field.getDescribe().getLabel();
            //-- Start | FIN-8048 | Changed by Ravi | 29 July 2025 --//
            openInnerHtml += '<th width="auto" style="border:1px solid gray;text-align:left;">' + fieldNames1 + '</th>';
            //-- End | FIN-8048 | Changed by Ravi | 29 July 2025 --//
        }
        paidInnerHtml += '</tr>';
        openInnerHtml += '</tr>';
        Object fieldvalue;
        Map<String,Double> mapCurBalance = new Map<String,Double>();
        for (Object ts: tran) {
            
            Map < Object, Object > dtx = (Map < Object, Object > ) ts;
            if (dtx.containsKey('Description') && dtx.get('Description') != null && dtx.get('Description') == 'Paid') {
                paidInnerHtml += '<tr>';
                for (String fieldName: FieldsAPIlst) {
                    Schema.Sobjectfield field = fieldMap.get(fieldName);
                    Schema.Displaytype fieldDataType = field.getDescribe().getType();
                    String fType = field.getDescribe().getType().name();

                    if (fieldDataType == Schema.DisplayType.REFERENCE) {

                        fieldName = fieldName.subString(0, fieldName.length() - 1) + 'r.name';
                        fieldvalue = dtx.get(fieldName);

                    } else if (fType == 'CURRENCY'){
                    if (dtx.get(fieldName) != null) {
                        Double dtTemp = (Double)dtx.get(fieldName);
                        String currencyIsoCode = ( String )(UserInfo.IsMultiCurrencyOrganization() ? dtx.get('CurrencyIsoCode') : UserInfo.getDefaultCurrency());           
                            
                            fieldvalue =UtilityController.formatDoubleValue(currencyIsoCode ,dtTemp );
                            }else{
                                fieldvalue = '';
                            }
                    
                    }
                    // else if (fType == 'DATE') {
                    //     if (dtx.get(fieldName) != null) {
                    //         // system.debug('----else ifff');
                    //         Date dtTemp = (Date)((String) dtx.get(fieldName));

                    //         fieldvalue = dtTemp.format();
                    //     } else {
                    //         fieldvalue = '';
                    //     }
                    // }
                     else {

                        fieldvalue = dtx.get(fieldName);
                        if (fieldvalue == null) {
                            fieldvalue = '';
                        }
                    }
                    //-- Start | FIN-8048 | Changed by Ravi | 29 July 2025 --//
                    paidInnerHtml += '<td width="auto" style="text-align:left;border:solid 1px gray;white-space:nowrap;">' + fieldvalue + '</td>';
                    //-- End | FIN-8048 | Changed by Ravi | 29 July 2025 --//
                }
                paidInnerHtml += '</tr>';
            }
            if (!dtx.containsKey('Description') || dtx.get('Description') != 'Paid') {
                openInnerHtml += '<tr>';
                for (String fieldName: openFieldsAPIlst) {
                    Schema.Sobjectfield field = fieldMap.get(fieldName);
                    Schema.Displaytype fieldDataType = field.getDescribe().getType();
                    String fType = field.getDescribe().getType().name();

                    if (fieldName == 'celsrm__Promised_Amount__c') {
                        String currencyIsoCode = ( String )(UserInfo.IsMultiCurrencyOrganization() ? dtx.get('CurrencyIsoCode') != null ? dtx.get('CurrencyIsoCode') : UserInfo.getDefaultCurrency() : UserInfo.getDefaultCurrency());           
                        if(mapCurBalance.containsKey(currencyIsoCode )){
                            double newAmt = dtx.get(fieldName) == null ? 0 : (double)dtx.get(fieldName);
                            newAmt +=  mapCurBalance.get(currencyIsoCode);
                            mapCurBalance.put(currencyIsoCode,newAmt);
                            
                        }else{
                            double newAmt = dtx.get(fieldName) == null ? 0 : (double)dtx.get(fieldName);
                            
                            mapCurBalance.put(currencyIsoCode,newAmt);
                        }
                        
                    }
                    if (fieldDataType == Schema.DisplayType.REFERENCE) {

                        fieldName = fieldName.subString(0, fieldName.length() - 1) + 'r.name';
                        fieldvalue = dtx.get(fieldName);

                    } else if (fType == 'CURRENCY'){
                    if (dtx.get(fieldName) != null) {
                        Double dtTemp = (Double)dtx.get(fieldName);
                        String currencyIsoCode = ( String )(UserInfo.IsMultiCurrencyOrganization() ? dtx.get('CurrencyIsoCode') : UserInfo.getDefaultCurrency());           
                            
                            fieldvalue =UtilityController.formatDoubleValue(currencyIsoCode ,dtTemp );
                            }else{
                                fieldvalue = '';
                            }
                    
                    // }else if (fType == 'DATE') {
                    //     if (dtx.get(fieldName) != null) {
                    //         // system.debug('----else ifff');
                    //         Date dtTemp = (Date) dtx.get(fieldName);

                    //         fieldvalue = dtTemp.format();
                    //     } else {
                    //         fieldvalue = '';
                    //     }
                    } else {

                        fieldvalue = dtx.get(fieldName);
                        if (fieldvalue == null) {
                            fieldvalue = '';
                        }
                    }
                    //-- Start | FIN-8048 | Changed by Ravi | 29 July 2025 --//
                    openInnerHtml += '<td width="auto" style="text-align:left;border:solid 1px gray;white-space:nowrap;">' + fieldvalue + '</td>';
                    //-- End | FIN-8048 | Changed by Ravi | 29 July 2025 --//
                }
                openInnerHtml += '</tr>';
            }
        }
        openInnerHtml += '<tr>';
        String  v = '';
        if(mapCurBalance != null && mapCurBalance.size() >0){
            for(String trancurr:mapCurBalance.keyset()){
            If(trancurr != null && trancurr != ''){
                v+= trancurr+' : '+UtilityController.formatAsCurrency(mapCurBalance.get(trancurr))+', ';
              }
            }
            v = v.substring(0,v.length()-2);
       
        }
        String TotalBal = v;
        //-- Start | FIN-8048 | Changed by Ravi | 29 July 2025 --//
        openInnerHtml += '<td colspan=' + openFieldsAPIlst.size() + ' style="text-align:right;width:auto;border:solid 1px gray;white-space:nowrap;"> <b> Total</b>  ' + TotalBal + '</td>';
        //-- End | FIN-8048 | Changed by Ravi | 29 July 2025 --//
        openInnerHtml += '</tr>';
        openInnerHtml += '</table>';
        paidInnerHtml += '</table>';
        return 'Following Invoice(s) are closed in our System:<br>' + paidInnerHtml + '<br>Following Invoice(s) are open in our System:<br>' + openInnerHtml;
    }
}