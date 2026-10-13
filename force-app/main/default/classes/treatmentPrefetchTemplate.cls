global with sharing class treatmentPrefetchTemplate implements celsrm.GOGIScreenCustomLogic {
    global Map < Object, Object > invoke(String functionName, Map < Object, Object > inMap) {
        
        inMap = createEmailBody(inMap);
        return inMap;
    }
    public static Map<Object,Object> createEmailBody(Map<Object,Object> inMap){
        // celsrm__SRM_Configuration__c systemConfig = celsrm__SRM_Configuration__c.getOrgDefaults();
        System.debug('@@@ treatmentPrefetchTemplate  : ');
        Boolean isTaskScreen = inMap.containsKey('isTaskScreen') ? (Boolean)inMap.get('isTaskScreen') : false;
        List < Id > accIds = new List < Id > ();
        id parentId = null;
        if (inMap.containsKey('accountId') && inMap.get('accountId') != null) {
            parentId = (Id) inMap.get('accountId');
            accIds.add(parentId);
            system.debug('parentId>>' + parentId);
        }
        
        Map < String, Map < String, List < String >> > returnMap = new Map < String, Map < String, List < String >> > ();
        returnMap = UtilityController.fetchEmails(accIds);
        Map < Object, Object > returnValue = new Map < Object, Object > ();
        // tempComposeEmail =  (map<string,object>)JSON.deserializeUntyped(JSON.serialize(inMap.get('ComposeEmail')));

        //system.debug('tempComposeEmail>>' + tempComposeEmail);

        Map < String, list < String >> m_getMailData = new Map < String, list < String >> ();
        if (accIds != null && accIds.size() > 0) {
            for (Id accID: accIds) {
                if (returnMap != null && returnMap.get(accID).get('to') != null)
                    returnValue.put('to', returnMap.get(accID).get('to'));
                if (returnMap != null && returnMap.get(accID).get('cc') != null)
                    returnValue.put('cc', returnMap.get(accID).get('cc'));
                if (returnMap != null && returnMap.get(accID).get('bcc') != null)
                    returnValue.put('bcc', returnMap.get(accID).get('bcc'));
            }
        }
        if (inMap.containsKey('fromAddress') && inMap.get('fromAddress') != null) {
            returnValue.put('from', (Id) inMap.get('fromAddress'));
        }
        
        returnValue.put('enableSubmitButton', true);

        EmailTemplate template = new EmailTemplate();
        // String templateId;
        String recordId = (String)inMap.get('Id');
        String templateId = inMap.get('EmailTemplate') != null ? (String)inMap.get('EmailTemplate') : null;
        if (templateId != null) {
            String objectName = (String)inMap.get('objectName');
            // template = [SELECT Id FROM EmailTemplate where Id = :defaultTemplate Limit 1];
            // templateId = template.Id;
            // recordId = (String)inMap.get('Id');
            List<Object> listOfStep = inMap.get('listOfStep') != null ? (List<Object>)inMap.get('listOfStep') : new List<Object>();
            String taskSubject = inMap.get('taskSubject') != null ? (String)inMap.get('taskSubject') :'';
            String treatmentStage = inMap.get('treatmentStage') != null ? (String)inMap.get('treatmentStage') :'';
            Boolean seperateTaskForStep = inMap.get('seperateTaskForStep') != null ? (Boolean)inMap.get('seperateTaskForStep') : false;
            Boolean isConsolidated = inMap.get('isConsolidated') != null ? (Boolean)inMap.get('isConsolidated') : false;
            
            // Integer len = listOfStep.size() - 1;
            List<Contact> con = new List<Contact>();
            try {
                con = [Select Id From Contact where celsrm__Default__c=true and accountId=:parentId];
                if (con == null || con.size() == 0) {
                    con = [Select Id From Contact where accountId=:parentId];
                }
            } catch (Exception e) {
                System.debug(e.getMessage());
            }
            
            Id ContactId ;
            if(con!= null && con.size()>0){
                ContactId =con.get(0).Id;
            }
            Messaging.SingleEmailMessage message = Messaging.renderStoredEmailTemplate(templateId,ContactId, recordId);
            // returnValue.put('subject', message.getSubject());
            returnValue.put('subject', message.getSubject());
            String returnTemplateBody = message.getHtmlBody();
            Map<string, Schema.sObjectType> describeInfo = Schema.getGlobalDescribe();
            Map<String, Schema.SObjectField> fieldMap = describeInfo.get(objectName.toLowerCase()).getDescribe().Fields.getMap();
            List<Object> childObjectIds = (List<Object>)inMap.get('childObjectIds');
            // table create
            if ((seperateTaskForStep || isConsolidated) && ( returnTemplateBody.containsIgnoreCase('{treatment}') || Test.isRunningTest())) {
                Double TotalBalance = 0;
                
                // Schema.Sobjecttype objType = objectName.getSObjectType();
                // Schema.Describesobjectresult sobjRes = objType.getDescribe();
                // Map<String, Schema.Sobjectfield> fieldMap = sobjRes.fields.getMap();
                List<String> columnsNameList = new List<String>();
                List<String> TempSelFlds= new List<String>();
                if(inMap.containsKey(treatmentStage + 'columns') && inMap.get(treatmentStage + 'columns') != null){
                    List<Object> columns = (List<Object>)inMap.get(treatmentStage + 'columns');
                    if (columns.size() > 0) {
                        for (Object field : columns) {
                            String fieldName = '';
                            try {
                                Map<Object,Object> fieldInfo = (Map<Object,Object>)field;
                                fieldName = (String)fieldInfo.get('fieldName');
                                
                            } catch (Exception e) {
                                Map<String,Object> fieldInfo = (Map<String,Object>)field;
                                fieldName = (String)fieldInfo.get('fieldName');
                            }
                            if (fieldName != 'RemoveCommunication') {
                                columnsNameList.add(fieldName);
                                if(fieldMap.get(fieldName.trim().toLowerCase()).getDescribe().isCustom() && fieldMap.get(fieldName.trim().toLowerCase()).getDescribe().getType() == Schema.DisplayType.REFERENCE){
                                    fieldName= fieldName.subString(0,fieldName.length()-1)+ 'r.Name';
                                    TempSelFlds.add(fieldName);
                                } else if (!fieldMap.get(fieldName.trim().toLowerCase()).getDescribe().isCustom() && fieldMap.get(fieldName.trim().toLowerCase()).getDescribe().getType() == Schema.DisplayType.REFERENCE) {
                                    fieldName= fieldName.subString(0,fieldName.length()-2)+ '.Name';
                                    TempSelFlds.add(fieldName);
                                } else {
                                    TempSelFlds.add(fieldName);
                                }
                            }
                            
                        }
                    }
                }
                Boolean idContains = false;
                if (TempSelFlds.contains('Id') || TempSelFlds.contains('id')) {
                    idContains = true;
                }
                if (UserInfo.IsMultiCurrencyOrganization() && !TempSelFlds.contains('CurrencyIsoCode')) {
                    TempSelFlds.add('CurrencyIsoCode');
                }
                String queryFieldName = TempSelFlds.size() > 0 ? String.join(TempSelFlds, ',') : '';
                // List<Object> childObjectIds = (List<Object>)inMap.get('childObjectIds');
                List<Id> childIds = new List<Id>();
                if (isTaskScreen) {
                    for (Object step : listOfStep) {
                        if (inMap.containsKey(step) && inMap.get(step) != null) {
                            List<Object> values = (List<Object>)inMap.get(step);
                            if (values.size() > 0) {
                                for (Object vals : values) {
                                    Map<Object,Object> val =(Map<Object,Object>)vals;
                                    System.debug('val--> ' + val);
                                    System.debug('val.get(isSelected)--> ' + val.get('isSelected'));
                                    if (val.containsKey('isSelected') && (Boolean)val.get('isSelected') == true) {
                                        childIds.add((Id)val.get('Id'));
                                    }
                                }
                            }
                        }
                    }
                } else {
                    for(Object Ids : childObjectIds){
                        childIds.add((String)Ids);
                    }
                }
                // String ObjectName = ((Id)childObjectIds.get(0)).getSObjectType().getDescribe().getName();
                String query = '';
                if (idContains == true && queryFieldName != '') {
                    query = 'SELECT ' + queryFieldName + ' FROM ' + ObjectName + ' where Id=:childIds';
                } else if (queryFieldName != '') {
                    query = 'SELECT Id, ' + queryFieldName + ' FROM ' + ObjectName + ' where Id=:childIds';
                } else {
                    query = 'SELECT Id, Name FROM ' + ObjectName + ' where Id=:childIds';
                }
                if (ObjectName.equalsIgnoreCase('celsrm__transaction__c')) {
                    // query += ' order by celsrm__DPD__c desc';
                    query += ' order by celsrm__DPD__c desc';
                } else if (ObjectName.equalsIgnoreCase('celsrm__dispute__c')) {
                    query += ' order by celsrm__Dispute_DPD__c desc';
                }
                List<SObject> childObjectRecords = Database.query(query);
                String innerHtml= '';
                Integer j=0;
                if (columnsNameList.size() == 0) {
                    columnsNameList.add('Name');
                }
                if (columnsNameList.size() > 0) {
                    //-- Start | FIN-8048 | Changed by Ravi | 29 July 2025 --//
                    innerHtml = '<style>@page{size:landscape;}</style><table width="100%" class="billing" style="border-collapse:collapse;padding:0px;font-family:verdana;">';
                    //-- End | FIN-8048 | Changed by Ravi | 29 July 2025 --//
                    innerHtml += '<tr>';
                    for (String tempColumn : columnsNameList) {
                        //-- Start | FIN-8048 | Changed by Ravi | 29 July 2025 --//
                        innerHtml += '<th width="auto" style="border:1px solid gray;text-align:left;">'+fieldMap.get(tempColumn.toLowerCase()).getDescribe().getLabel() +'</th>';
                        //-- End | FIN-8048 | Changed by Ravi | 29 July 2025 --//
                    }
                    innerHtml += '</tr>';
                    Map<String,Double> totalMap = new Map<String,Double>();
                    Double total = 0;
                    String aggregationField = '';
                    String totalTitle = '';
                    if(inMap.containsKey(treatmentStage + 'showTotal') && inMap.get(treatmentStage + 'showTotal') != null && (Boolean)inMap.get(treatmentStage + 'showTotal') && inMap.containsKey(treatmentStage + 'aggregationField') && inMap.get(treatmentStage + 'aggregationField') != null){
                        aggregationField = String.valueOf(inMap.get(treatmentStage + 'aggregationField'));
                        if(inMap.containsKey(treatmentStage + 'totalTitle') && inMap.get(treatmentStage + 'totalTitle') != null){
                            totalTitle = String.valueOf(inMap.get(treatmentStage + 'totalTitle'));
                        }
                    }
                    for (Sobject tempRecord : childObjectRecords) {
                        j=j+1;
                        innerHtml += '<tr>';
                        for (String fieldName : columnsNameList) {
                            Object fieldValue = '';
                            
                            if (fieldMap.get(fieldName).getDescribe().getType() == Schema.DisplayType.REFERENCE) {
                                
                                String tempfield= '';
                                if (fieldMap.get(fieldName.toLowerCase()).getDescribe().isCustom()) {
                                    tempfield= fieldName.subString(0,fieldName.length()-1)+ 'r';
                                } else {
                                    tempfield= fieldName.subString(0,fieldName.length()-2);
                                }
                                fieldValue = tempRecord.getSobject(tempfield).get('Name');
                            } else if (fieldMap.get(fieldName).getDescribe().getType().name() == 'CURRENCY'){
                                if (tempRecord.get(fieldName) != null) {
                                    Double dtTemp = (Double)tempRecord.get(fieldName);
                                    String currencyIsoCode = ( String )(UserInfo.IsMultiCurrencyOrganization() ? tempRecord.get('CurrencyIsoCode') : UserInfo.getDefaultCurrency());           
                                        
                                    fieldvalue =formatDoubleValue(currencyIsoCode ,dtTemp );
                                }
                            
                            } else if (fieldMap.get(fieldName).getDescribe().getType().name() == 'DATETIME'){
                                if (tempRecord.get(fieldName) != null) {
                                    Datetime dtTemp = (Datetime)tempRecord.get(fieldName);
                                    
                                    fieldvalue =dtTemp.format();
                                }
                            } else if (fieldMap.get(fieldName).getDescribe().getType().name() == 'DATE'){
                                if (tempRecord.get(fieldName) != null) {
                                    Date dtTemp = (Date)tempRecord.get(fieldName);
                                    
                                    fieldvalue =dtTemp.format();
                                }
                            } else{
                            fieldvalue = tempRecord.get(fieldName);
                                if(fieldvalue == null){
                                    fieldvalue = '';
                                }
                            }
                            if (aggregationField != '' &&  aggregationField == fieldName) {
                                Double dtTemp = 0.0;
                                if(tempRecord.get(fieldName) != null){
                                    dtTemp = (Double)tempRecord.get(fieldName);
                                } else if (tempRecord.get(fieldName) != null) {
                                    dtTemp = (Double)tempRecord.get(fieldName);
                                }
                                if (fieldMap.get(fieldName).getDescribe().getType().name() == 'CURRENCY') {
                                        
                                    String currencyIsoCode = ( String )(UserInfo.IsMultiCurrencyOrganization() ? tempRecord.get('CurrencyIsoCode') : UserInfo.getDefaultCurrency());           
                                    if (totalMap.get(currencyIsoCode) != null) {
                                        Double finalValue = totalMap.get(currencyIsoCode) + dtTemp;
                                        totalMap.put(currencyIsoCode, finalValue);
                                    } else {
                                        totalMap.put(currencyIsoCode, dtTemp);
                                    }
                                } else {
                                    total = total + dtTemp;
                                }
                            }
                            //-- Start | FIN-8048 | Changed by Ravi | 29 July 2025 --//
                            innerHtml += '<td width="auto" style="text-align:left;border:solid 0.5px gray;white-space:nowrap;">'+ fieldvalue+'</td>';
                            //-- End | FIN-8048 | Changed by Ravi | 29 July 2025 --//
                        }
                        innerHtml += '</tr>';
                    }
                    innerHtml += '</table><br>';
                    if (aggregationField != '') {
                        if (total > 0) {
                            innerHtml += '<span style="float:right">' + totalTitle + ' ' + total + '</span>';
                        } else {
                            if (totalMap.keySet().size() > 0) {
                                innerHtml += '<span style="float:right">' + totalTitle + ' ';
                                for (String code : totalMap.keySet()) {
                                    innerHtml += formatDoubleValue(code ,totalMap.get(code) ) + ',';
                                }
                                innerHtml = innerHtml.removeEnd(',') + '</span>';
                            } else {
                                innerHtml += '<span style="float:right">' + totalTitle + ' 0.0' + '</span>';
                            }
                        }
                    }
                    innerHtml += '<br>';
                    String description = inMap.containsKey(treatmentStage + 'description') && inMap.get(treatmentStage + 'description') != null ? (String)inMap.get(treatmentStage + 'description') : '';
                    returnTemplateBody = returnTemplateBody.replace('{treatment}', description + innerHtml);
                }
                
                System.debug('body>>> ' + returnTemplateBody);
            } else if (!seperateTaskForStep && (returnTemplateBody.containsIgnoreCase('{treatment') || Test.isRunningTest())) {
                for (Object step : listOfStep) {
                    String innerHtml= '';
                    Integer j=0; 
                    if (inMap.containsKey(step + 'value') && inMap.get(step + 'value') != null) {
                        List<Object> values = (List<Object>)inMap.get(step + 'value');
                        if (values.size() > 0) {
                            if (inMap.containsKey(step + 'columns') && inMap.get(step + 'columns') != null) {
                                List<Object> columns = (List<Object>)inMap.get(step + 'columns');
                                if (columns.size() > 0) {
                                    //-- Start | FIN-8048 | Changed by Ravi | 29 July 2025 --//
                                    innerHtml = '<style>@page{size:landscape;}</style><table width="100%" class="billing" style="border-collapse:collapse;padding:0px;font-family:verdana;">';
                                    //-- End | FIN-8048 | Changed by Ravi | 29 July 2025 --//
                                    innerHtml += '<tr>';
                                    for (Object field : columns) {
                                        try {
                                            Map<Object,Object> fieldInfo = (Map<Object,Object>)field;
                                            //-- Start | FIN-8048 | Changed by Ravi | 29 July 2025 --//
                                            innerHtml += '<th width="auto" style="border:1px solid gray;text-align:left;">'+fieldInfo.get('label')+'</th>';
                                            //-- End | FIN-8048 | Changed by Ravi | 29 July 2025 --//
                                        } catch (Exception e) {
                                            Map<String,Object> fieldInfo = (Map<String,Object>)field;
                                            //-- Start | FIN-8048 | Changed by Ravi | 29 July 2025 --//
                                            innerHtml += '<th width="auto" style="border:1px solid gray;text-align:left;">'+fieldInfo.get('label')+'</th>';
                                            //-- End | FIN-8048 | Changed by Ravi | 29 July 2025 --//
                                        }
                                        
                                        
                                    }
                                    innerHtml += '</tr>';
                                    Object fieldvalue;
                                    Map<String,Double> totalMap = new Map<String,Double>();
                                    Double total = 0;
                                    String aggregationField = '';
                                    String totalTitle = '';
                                    if(inMap.containsKey(step + 'showTotal') && inMap.get(step + 'showTotal') != null && (Boolean)inMap.get(step + 'showTotal') && inMap.containsKey(step + 'aggregationField') && inMap.get(step + 'aggregationField') != null){
                                        aggregationField = String.valueOf(inMap.get(step + 'aggregationField'));
                                        if(inMap.containsKey(step + 'totalTitle') && inMap.get(step + 'totalTitle') != null){
                                            totalTitle = String.valueOf(inMap.get(step + 'totalTitle'));
                                        }
                                    }
                                    for (Object vals : values) {
                                        Map<Object,Object> val = new Map<Object,Object>();
                                        Map<String,Object> val1 = new Map<String,Object>();
                                        Boolean objectMap = true;
                                        Boolean printRow = true;
                                        if (vals instanceof Map<Object,Object>) {
                                            val =(Map<Object,Object>)vals;
                                            if (isTaskScreen && val.containsKey('isSelected') && (Boolean)val.get('isSelected') == false) {
                                                printRow = false;
                                            }
                                        } else {
                                            String objVal = JSON.serialize(vals);
                                            val1 = (Map<String, Object>)JSON.deserializeUntyped(objVal);
                                            if (isTaskScreen && val1.containsKey('isSelected') && (Boolean)val1.get('isSelected') == false) {
                                                printRow = false;
                                            }
                                            objectMap = false;
                                        }
                                        if (printRow) {
                                            j=j+1;
                                            innerHtml += '<tr>';
                                            // if (objectMap) {
                                            //     childObjectIds.add(val.get('Id'));
                                            // } else {
                                            //     childObjectIds.add(val1.get('Id'));
                                            // }
                                            
                                            for (Object field : columns) {
                                                String fieldName = '';
                                                try {
                                                    Map<Object,Object> fieldInfo = (Map<Object,Object>)field;
                                                    fieldName = (String)fieldInfo.get('fieldName');
                                                } catch (Exception e) {
                                                    Map<String,Object> fieldInfo = (Map<String,Object>)field;
                                                    fieldName = (String)fieldInfo.get('fieldName');
                                                }
                                                if (fieldName != 'RemoveCommunication') {
                                                    if (fieldName.equalsIgnoreCase('name') || fieldMap.get(fieldName).getDescribe().getType() == Schema.DisplayType.REFERENCE) {
                                                        String tempfield = '';
                                                        if (objectMap) {
                                                            tempfield = fieldName + '-email';
                                                            fieldvalue = val.get(tempfield);
                                                        } else {
                                                            if (fieldName.equalsIgnoreCase('name')) {
                                                                tempfield = fieldName;
                                                            } else if (fieldMap.get(fieldName.toLowerCase()).getDescribe().isCustom()) {
                                                                tempfield= fieldName.subString(0,fieldName.length()-1)+ 'r';
                                                            } else {
                                                                tempfield= fieldName.subString(0,fieldName.length()-2);
                                                            }
                                                            System.debug('tempfield--> ' + tempfield);
                                                            System.debug('val1--> ' + val1);
                                                            if (!fieldName.equalsIgnoreCase('name')) {
                                                                Map<String,object> tempvalue = (Map<String,object>)val1.get(tempfield);
                                                                if (tempvalue != null) {
                                                                    fieldvalue = tempvalue.get('Name');
                                                                } else {
                                                                    fieldvalue = '';
                                                                }
                                                            } else {
                                                                fieldvalue = val1.get(tempfield);
                                                            }
                                                            
                                                            
                                                        }
                                                        
                                                    } else if (fieldMap.get(fieldName).getDescribe().getType().name() == 'CURRENCY'){
                                                        if(objectMap && val.get(fieldName) != null){
                                                            Double dtTemp = (Double)val.get(fieldName);
                                                            String currencyIsoCode = ( String )(UserInfo.IsMultiCurrencyOrganization() ? val.get('CurrencyIsoCode') : UserInfo.getDefaultCurrency());           
                                                                
                                                            fieldvalue =formatDoubleValue(currencyIsoCode ,dtTemp );
                                                        } else if(!objectMap && val1.get(fieldName) != null){
                                                            Double dtTemp = (Double)val1.get(fieldName);
                                                            String currencyIsoCode = ( String )(UserInfo.IsMultiCurrencyOrganization() ? val1.get('CurrencyIsoCode') : UserInfo.getDefaultCurrency());           
                                                                
                                                            fieldvalue =formatDoubleValue(currencyIsoCode ,dtTemp );
                                                        } else{
                                                            fieldvalue = '';
                                                        }
                                                    
                                                    } else if (fieldMap.get(fieldName).getDescribe().getType().name() == 'DATETIME'){
                                                        if (objectMap && val.get(fieldName) != null) {
                                                            List<String> dateList = String.valueOf(val.get(fieldName)).split('T');
                                                            String tempDate = dateList.get(0);
                                                            String tempTime = dateList.get(1).split('.000Z').get(0);
                                                            String finalDate = tempDate + ' ' + tempTime;
                                                            Datetime myDate = Datetime.valueOf(finalDate);
                                                            fieldvalue = myDate.format();
                                                        } else if(!objectMap && val1.get(fieldName) != null) {
                                                            List<String> dateList = String.valueOf(val.get(fieldName)).split('T');
                                                            String tempDate = dateList.get(0);
                                                            String tempTime = dateList.get(1).split('.000Z').get(0);
                                                            String finalDate = tempDate + ' ' + tempTime;
                                                            Datetime myDate = Datetime.valueOf(finalDate);
                                                            fieldvalue = myDate.format();
                                                        }
                                                    } else if (fieldMap.get(fieldName).getDescribe().getType().name() == 'DATE'){
                                                        if (objectMap && val.get(fieldName) != null) {
                                                            Date myDate = date.valueOf(String.valueOf(val.get(fieldName)));
                                                            fieldvalue = myDate.format();
                                                        } else if(!objectMap && val1.get(fieldName) != null) {
                                                            Date myDate = date.valueOf(String.valueOf(val1.get(fieldName)));
                                                            fieldvalue = myDate.format();
                                                        }
                                                    } else{
                                                        if (objectMap) {
                                                            fieldvalue = val.get(fieldName);
                                                        } else {
                                                            fieldvalue = val1.get(fieldName);
                                                        }
                                                        
                                                        if(fieldvalue == null){
                                                            fieldvalue = '';
                                                        }
                                                    }
                                                    System.debug('aggregationField--> ' + aggregationField + 'aggregationField == fieldName --> ' + fieldName);
                                                    if (aggregationField != '' &&  aggregationField == fieldName) {
                                                        Double dtTemp = 0.0;
                                                        if(objectMap && val.get(fieldName) != null){
                                                            dtTemp = (Double)val.get(fieldName);
                                                        } else if (!objectMap && val1.get(fieldName) != null) {
                                                            dtTemp = (Double)val1.get(fieldName);
                                                        }
                                                        if (fieldMap.get(fieldName).getDescribe().getType().name() == 'CURRENCY') {
                                                                
                                                            String currencyIsoCode = ( String )(UserInfo.IsMultiCurrencyOrganization() ? val.get('CurrencyIsoCode') : UserInfo.getDefaultCurrency());           
                                                            if (totalMap.get(currencyIsoCode) != null) {
                                                                Double finalValue = totalMap.get(currencyIsoCode) + dtTemp;
                                                                totalMap.put(currencyIsoCode, finalValue);
                                                            } else {
                                                                totalMap.put(currencyIsoCode, dtTemp);
                                                            }
                                                        } else {
                                                            total = total + dtTemp;
                                                        }
                                                    }
                                                    //-- Start | FIN-8048 | Changed by Ravi | 29 July 2025 --//
                                                    innerHtml += '<td width="auto" style="text-align:left;border:solid 0.5px gray;white-space:nowrap;">'+ fieldvalue+'</td>';
                                                    //-- End | FIN-8048 | Changed by Ravi | 29 July 2025 --//
                                                }
                                            }
                                            innerHtml += '</tr>';
                                        }
                                        
                                    }
                                    
                                    innerHtml += '</table><br>';
                                    if (aggregationField != '') {
                                        if (total > 0) {
                                            innerHtml += '<span style="float:right">' + totalTitle + ' ' + total + '</span>';
                                        } else {
                                            if (totalMap.keySet().size() > 0) {
                                                innerHtml += '<span style="float:right">' + totalTitle + ' ';
                                                for (String code : totalMap.keySet()) {
                                                    innerHtml += formatDoubleValue(code ,totalMap.get(code) ) + ',';
                                                }
                                                innerHtml = innerHtml.removeEnd(',') + '</span>';
                                            } else {
                                                innerHtml += '<span style="float:right">' + totalTitle + ' 0.0' + '</span>';
                                            }
                                        }
                                    }
                                    innerHtml += '<br>';
                                    String description = inMap.containsKey(step + 'description') && inMap.get(step + 'description') != null ? (String)inMap.get(step + 'description') : '';
                                    returnTemplateBody = returnTemplateBody.replace('{treatment.' + step + '}', description + innerHtml);
                                }
                            }
                        }
                    }
                    
                }
            }
            if (returnTemplateBody.containsIgnoreCase('{treatment')) {
                for (Integer i = 1; i >0 ; i++) {
                    if (returnTemplateBody.containsIgnoreCase('{treatment')) {
                        Integer result = returnTemplateBody.indexOfIgnoreCase('{treatment', 0);
                        Integer result1 = returnTemplateBody.indexOfIgnoreCase('}', result);
                        System.debug('result>> ' + result + ' <<result1>> ' + result1);
                        String sub = returnTemplateBody.substring(result, result1 + 1);
                        returnTemplateBody = returnTemplateBody.replace(sub,'');
                    } else {
                        i = 0;
                        break;
                    }
                }
            }
            returnValue.put('body', returnTemplateBody);
            //-- Starts | FIN-8085 | Changed by Ravi | 4 Aug 2025 --//
            // Task tsk = [SELECT Id, Subject, WhatId, celsrm__Treatment__c FROM Task WHERE Id=:recordId];
            // String treatmentId = tsk.celsrm__Treatment__c;
            // celsrm__Treatment__c treatment = [Select Id, Name, celsrm__Email_Template__c, celsrm__Account_Criteria__c, celsrm__Active__c, celsrm__Related_Object__c, celsrm__Treatment_Steps__c,celsrm__Task_Due_Date__c,celsrm__Task_Type__c,celsrm__Org_Id__c,celsrm__Template_Folder_Reference_Field__c, celsrm__Email_Template_Prefix__c From celsrm__Treatment__c Where Id=:treatmentId];
            //-- Ends | FIN-8085 | Changed by Ravi | 4 Aug 2025 --//
            // Map<String, String> returnBodyMap = celsrm.SRMTreatmentUtility.getTemplateBody(tsk, treatment, systemConfig, recordId, ContactId, false);
            // String subject = returnBodyMap.get('subject') != null ? returnBodyMap.get('subject') : '';
            // String templateBody = returnBodyMap.get('templateBody') != null ? returnBodyMap.get('templateBody') : '';
            // returnValue.put('subject', taskSubject + ' : ' + subject);
            // returnValue.put('body', templateBody);
        }
        if(isTaskScreen) {
            List<Object> listOfStep = inMap.get('listOfStep') != null ? (List<Object>)inMap.get('listOfStep') : new List<Object>();
            Map<String, Set<Id>> stepToRecIds = new Map<String, Set<Id>>();
            for (Object step : listOfStep) {
                if (inMap.containsKey(step) && inMap.get(step) != null) {
                    List<Object> values = (List<Object>)inMap.get(step);
                    if (values.size() > 0) {
                        Set<Id> tmp = new Set<Id>();
                        for (Object vals : values) {
                            Map<Object,Object> val =(Map<Object,Object>)vals;
                            if (val.containsKey('isSelected') && (Boolean)val.get('isSelected') == true) {
                                tmp.add((Id)val.get('Id'));
                            }
                        }
                        if (tmp.size() > 0) {
                            stepToRecIds.put((String)step, tmp);
                        }
                    }
                }
            }
            String fileNameTemp = 'Treatment Details Temp';
            List<ContentDocumentLink> listContentDLTemp = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId =: recordId];
            Set<Id> conDocIdsTemp = new Set<Id>();
            for(ContentDocumentLink conDL : listContentDLTemp){
                conDocIdsTemp.add(conDL.ContentDocumentId);
            }
            List<ContentDocument> listContentDocTemp = [SELECT Id, FileExtension, Title, LastModifiedDate FROM ContentDocument WHERE Id IN :conDocIdsTemp and Title =: fileNameTemp];
            if(!listContentDocTemp.isEmpty()){
                ContentDocument selectedContentDoc = listContentDocTemp.get(0);
                ContentVersion contentVersion = new ContentVersion(
                    ContentDocumentId = selectedContentDoc.Id,
                    Title = 'Treatment Details Temp',
                    PathOnClient = 'treatmentdetailstemp.json',
                    ReasonForChange = 'updated records',
                    VersionData = Blob.valueOf(JSON.serialize(stepToRecIds)),
                    IsMajorVersion = true
                );
                insert contentVersion;
            } else {
                ContentVersion version = new ContentVersion();
                version.VersionData = Blob.valueOf(JSON.serialize(stepToRecIds));
                version.Title = 'Treatment Details Temp'; 
                version.PathOnClient = 'treatmentdetailsTemp.json';
                insert version;
    
                // get content document
                List<ContentVersion> cVer = [Select Id, ContentDocumentId, Title, FileType, ContentSize, VersionData FROM ContentVersion WHERE Id = :version.Id];
    
                if(cVer != null && cVer.size() > 0) {
                    //link file with the task
                    system.debug('ContentDocumentId>>>>>> ' + cVer.get(0).ContentDocumentId);
                    ContentDocumentLink contentLink =new ContentDocumentLink();
                    contentLink.ContentDocumentId = cVer.get(0).ContentDocumentId;
                    contentLink.LinkedEntityId = recordId;
                    contentLink.ShareType = 'V';
                    insert contentLink;
                }
            }
        }
        // returnValue.put('childObjectIds', childObjectIds);

        //inMap.put('ComposeEmail', tempComposeEmail);
        //inMap.put('FollowupDays', Date.Today().addDays(5));
        return returnValue;
    }
    public static String formatDoubleValue(String currencyCode, Double d) {
        String formattedCurrencyStr;
        //  String doubleVal = formatAsCurrency(d);
        String doubleVal = d.format();
        // if(currencyCode!=null && currencyCode!=''){
        celsrm__CurrencyCode_Symbols__c currencyCodesettings = celsrm__CurrencyCode_Symbols__c.getInstance(currencyCode);
        
        //String doubleVal =  Decimal.valueOf(d).setScale(2).toPlainString();
        
        if(currencyCodesettings!=null && currencyCodesettings.celsrm__Currency_Symbol__c!=null  ){
            formattedCurrencyStr = currencyCodesettings.celsrm__Currency_Symbol__c + ' ' + doubleVal;
        }
        // }  
        else{
            formattedCurrencyStr = '$' + ' ' +doubleVal;
        }
        return formattedCurrencyStr;
    }
}