global class SendStatementOnAccount implements celsrm.GOGIScreenCustomLogic {
    global Map<Object, Object> invoke(String functionName, Map<Object, Object> inMap) {
        System.debug('@@ inMap : ' + inMap);
        Set<String> accId = new Set<String>();
        accId.add(String.valueOf(inMap.get('Id')));
        //List<Object> arr = (List<Object>)inMap.get('TransactionList');
        String formatType = (String)inMap.get('StatementFormat');
        String ListView = (String)inMap.get('ListView');
        String contentTemplate;
        List<String> trxIdSet = new List<String>();
        Integer contactCustomerPreviewLimit;
        String sortfieldName = null;
        String sortOrder = null;
        if (inMap.get('TransactionList_SortColumn') != null && inMap.get('TransactionList_SortOrder') != null) {
            sortfieldName = String.valueOf(inMap.get('TransactionList_SortColumn'));
            sortOrder = String.valueOf(inMap.get('TransactionList_SortOrder'));
            if(Schema.SObjectType.celsrm__Transaction__c.fields.getMap().get(sortfieldName).getDescribe().getType() == Schema.DisplayType.TextArea) {
                sortfieldName = null;
                sortOrder = null;
            }
        }

        // String currentUser = UserInfo.getUserId();
        // celsrm__User_Preference__c userPref  = new celsrm__User_Preference__c();
        // try {
        //     userPref = [SELECT Id,celsrm__SortListViewField__c,celsrm__SortListViewOrderType__c FROM celsrm__User_Preference__c WHERE celsrm__User__c =:currentUser LIMIT 1];
        // } catch (Exception e) {
        //     System.debug('exception>> ' + e.getMessage());
        // }
        // if (sortfieldName == null && sortOrder == null && userPref.celsrm__SortListViewField__c != null && userPref.celsrm__SortListViewOrderType__c != null) {
        //     sortfieldName = String.valueOf(userPref.celsrm__SortListViewField__c);
        //     sortOrder = String.valueOf(userPref.celsrm__SortListViewOrderType__c);
        //     if(Schema.SObjectType.celsrm__Transaction__c.fields.getMap().get(sortfieldName).getDescribe().getType() == Schema.DisplayType.TextArea) {
        //         sortfieldName = null;
        //         sortOrder = null;
        //     }
        // }
        //By Ravi | 12-02-2020 | user preference
        if(functionName == 'contactCustomerPreview' || functionName == 'exportAll') {
            String trxId =  inMap.get('trxnId') != null ? (String)inMap.get('trxnId') : '';
            if(trxId != '') {
                trxIdSet = trxId.split(',');
            }
            celsrm__SRM_Configuration__c systemConfig = celsrm__SRM_Configuration__c.getOrgDefaults();
            contactCustomerPreviewLimit = (Integer)systemConfig.statement_limit__c;
            //-- Start | FIN-9543 | Changed by Dhwanil | 06 April 2026 --//
            inMap.put('attachmentFontFamily',systemConfig.celsrm__Attachment_Table_Font_Family__c);
            inMap.put('attachmentFontSize',systemConfig.celsrm__Attachment_Table_Font_Size__c);
            //-- End | FIN-9543 | Changed by Dhwanil | 06 April 2026 --//
        }
        if ((inMap.get('AttachCheckBox') != null && (Boolean)inMap.get('AttachCheckBox')) || (inMap.get('preview') != null && (Boolean)inMap.get('preview'))) {
            PageReference pRef= Page.celsrm__PreviewStatement;
            // << NOTE - MM - FIN-8324 - [Akzonobel] Use common template for all attachments | Keep formatType is Excel always>>
            pRef.getParameters().put('formatType','Excel');
            pRef.getParameters().put('accId',((new list<string> (accId))[0]));
            pRef.getParameters().put('ScreenName','SendStatement');
            
            System.debug('URL ::: ' + pRef.getUrl());
            if (Test.IsRunningTest()){
                Blob fileContent;
                fileContent = Blob.valueOf('Unit Test Attachment {Transactions.TotalBalance} Body');
                contentTemplate = fileContent.toString();
            } else {
                contentTemplate = pRef.getContent().toString();
            }
        }
        celsrm__Custom_List_View__c customListViewObj = new celsrm__Custom_List_View__c();
        List<celsrm__Custom_List_View__c> customListViewList = [SELECT Id, Name, celsrm__Object_Fields__c, celsrm__Filter_Criteria__c,celsrm__ListView_For_Object__c,celsrm__Sort_By_Field__c, celsrm__Sort_By_Order__c FROM celsrm__Custom_List_View__c WHERE Id = :ListView LIMIT 1];
        String selectedFields = '';
        //-- Start | FIN-8949 | Changed by Dhwanil | 30 Jan 2026 --//
        String selectedFieldTypes = '';
        //-- End | FIN-8949 | Changed by Dhwanil | 30 Jan 2026 --//
        String whereCondition = '  ';
        if(customListViewList != null && customListViewList.size() > 0) {
            customListViewObj = customListViewList.get(0);
            if(customListViewObj.celsrm__Object_Fields__c != null && customListViewObj.celsrm__Object_Fields__c != '') {
                selectedFields = UtilityController.getQueryFields(customListViewObj.celsrm__Object_Fields__c, 'celsrm__Transaction__c');
                selectedFieldTypes = UtilityController.getQueryFieldsType(customListViewObj.celsrm__Object_Fields__c, 'celsrm__Transaction__c');
            }
            system.debug('selectedFields===>'+selectedFields);
            if(customListViewObj.celsrm__Filter_Criteria__c != null && customListViewObj.celsrm__Filter_Criteria__c != '') {
                whereCondition = UtilityController.getQueryWhereClause(customListViewObj.celsrm__Filter_Criteria__c);
            }
            system.debug('whereCondition===>'+whereCondition);
        }
                

        if(functionName != 'contactCustomerPreview' && functionName != 'exportAll') {
            if(whereCondition != '' && whereCondition != null) { // FIN-9048 | Chanegs by Asera condtion wrong erlier 
                if ((Boolean)inMap.get('IsIncludeChild') == true) {
                    System.debug('IsIncludeChild If Part');
                    whereCondition += ' and (celsrm__Account__c= :accId OR celsrm__Account__r.parentid= :accId OR celsrm__Account__r.parent.parentid= :accId )';
                } else {
                    System.debug('IsIncludeChild else part');
                    whereCondition += ' and celsrm__account__c = :accId';
                }
            } else if(whereCondition == '') {
                if ((Boolean)inMap.get('IsIncludeChild') == true) {
                    System.debug('IsIncludeChild If Part');
                    whereCondition = ' celsrm__balance__c !=0 and (celsrm__Account__c= :accId OR celsrm__Account__r.parentid= :accId OR celsrm__Account__r.parent.parentid= :accId )';
                } else {
                    System.debug('IsIncludeChild else part');
                    whereCondition = ' celsrm__balance__c !=0 and celsrm__account__c =:accId'; 
                }
                                            
            }
        }

        if(functionName == 'exportAll'){
            //-- Start | FIN-8530 | Changed by Ravi | 10 Nov 2025 --//
            if (inMap.get('accountHierarchyChildIds') != null) {
                List<Object> tempList = (List<Object>)inMap.get('accountHierarchyChildIds');
                for(Object objId : tempList) {
                    accId.add(String.valueOf(objId));
                }
            }
            //-- End | FIN-8530 | Changed by Ravi | 10 Nov 2025 --//
            if(trxIdSet.size() > 0){
                whereCondition += ' and Id = :trxIdSet ';
            } else {
                whereCondition += ' and celsrm__account__c = :accId ';
            }
        } else if(functionName == 'contactCustomerPreview') {
            if(whereCondition == '  ' || whereCondition == '') {
                whereCondition += ' WHERE Id = :trxIdSet';
            } else {
                whereCondition += ' and Id = :trxIdSet';
            }
            
            
            if (sortfieldName != null && sortOrder != null) {
                whereCondition += ' ORDER BY ' + sortfieldName + ' ' + sortOrder;
            } else if (customListViewObj.celsrm__Sort_By_Field__c != null && customListViewObj.celsrm__Sort_By_Field__c != '') {
                whereCondition += ' ' + UtilityController.getQuerySortOrder(customListViewObj.celsrm__Sort_By_Field__c, true);
            }
            

        } else if (functionName != 'contactCustomerPreview' && sortfieldName != null && sortOrder != null) {
            whereCondition += ' ORDER BY ' + sortfieldName + ' ' + sortOrder;
        } else if (functionName != 'contactCustomerPreview' && customListViewObj.celsrm__Sort_By_Field__c != null && customListViewObj.celsrm__Sort_By_Field__c != '') {
            whereCondition += ' ' + UtilityController.getQuerySortOrder(customListViewObj.celsrm__Sort_By_Field__c, true);
        }

        //-- Starts : Set Limit for Query --//
        if (contactCustomerPreviewLimit != null && contactCustomerPreviewLimit != 0) {
            whereCondition += ' LIMIT :contactCustomerPreviewLimit';
        } else {
            whereCondition += ' LIMIT 50000';
        }
        //-- Ends : Set Limit for Query --//
                system.debug('==whereCondition 1 ==='+whereCondition);
                // List<celsrm__Transaction__c> lstTrans = UtilityController.getTransactionList(selectedFields,whereCondition);
                
                List<string> formatedFieldName = UtilityController.getTransactionFieldformat(selectedFields.split(','),'celsrm__Transaction__c');
                List<string> finalFieldList = new List<string>();
                Boolean isHaveBalanceField = false;
                Boolean isHaveBaseBalanceField = false;
                Boolean isHaveCurrencyIsoCodeField = false;
                Boolean hasRecordId = false;
                for(String st:formatedFieldName){
                    if(st.equalsIgnoreCase('id') ){
                        hasRecordId = true;
                    } else if(st.equalsIgnoreCase('celsrm__balance__c') ){
                        isHaveBalanceField =true;
                        }   
                    if(st.equalsIgnoreCase('celsrm__base_balance__c') ){
                        isHaveBaseBalanceField =true;
                    }
                    if(st.equalsIgnoreCase('currencyisocode') ){
                        isHaveCurrencyIsoCodeField = true;
                    }
                
                }
                String Queryfields = string.join(formatedFieldName,',');
                if(!hasRecordId) {
                    Queryfields = 'id,' +  Queryfields;
                }
                if(isHaveBalanceField ==false){
                    Queryfields = 'celsrm__balance__c,' +  Queryfields;
                }
                //....
                //add Base balance field id not exist in listview
                if(isHaveBaseBalanceField == false){
                    Queryfields = 'celsrm__base_balance__c,' +  Queryfields;
                }
                //....
                
                if(isHaveCurrencyIsoCodeField == false &&  UserInfo.IsMultiCurrencyOrganization()){
                    Queryfields = 'currencyisocode,' +  Queryfields;
                }
                if(Queryfields.endsWith(',')) {
                    Queryfields = Queryfields.substring(0, Queryfields.length() - 1);
                }
                String stringToQuery = 'Select '+ Queryfields + ' from celsrm__Transaction__c ' +  whereCondition;
                System.debug('stringToQuery>>>>>>>>'+stringToQuery);

                list<celsrm__Transaction__c> lstTrans = database.query(stringToQuery);
                //-- Starts | FIN-8949 | Changed by Dhwanil | 30 Jan 2026 --//
                List<StaticResource> sr = [SELECT Id FROM StaticResource WHERE Name = 'CompanyLogo' LIMIT 1];
                inMap.put('hasCompanyLogo', !sr.isEmpty());
                inMap.put('statementDate', Date.today());
                inMap.put('orgName', UserInfo.getOrganizationName());
                //--Start | FIN-9250 | Changed by Dhwanil | 18-Feb-2026 --//
                inMap.put('LOCALE', UserInfo.getLocale());
                //--End | FIN-9250 | Changed by Dhwanil | 18-Feb-2026 --//
                if (inMap.containsKey('Id') && inMap.get('Id') != null) {
                    try {
                        Id accountId = (Id)inMap.get('Id');
                        Account acc = [SELECT Name, AccountNumber FROM Account WHERE Id = :accountId LIMIT 1];
                        inMap.put('customerName', acc.Name);
                        inMap.put('customerNumber', acc.AccountNumber);
                    } catch (Exception e) {
                        System.debug('Could not retrieve Account details for Excel generation. Error: ' + e.getMessage());
                    }
                }
                //-- End | FIN-8949 | Changed by Dhwanil | 30 Jan 2026 --//
                inMap.put('DueTransList',lstTrans );
                inMap.put('selectedFields',selectedFields.split(','));
                inMap.put('selectedFieldTypes',selectedFieldTypes);
                //-- Starts | FIN-8280| Changed by Asera | 17 April 2026 --//
                // List<string> FieldsLabel = UtilityController.getTransactionFieldLabel(selectedFields.split(','));
                String accountLocale = (String)inMap.get('accountLocale');
                List<String> FieldsLabel = new List<String>();
                if(accountLocale != null && accountLocale != ''){
                    FieldsLabel = celsrm.SRMUtilityController.getTransactionFieldTranslatedLabel(accountLocale, 'celsrm__Transaction__c', selectedFields.split(','));
                } else {
                    FieldsLabel = UtilityController.getTransactionFieldLabel(selectedFields.split(','));
                }
                //-- End | FIN-8280| Changed by Asera | 17 April 2026 --//
                inMap.put('selectedFieldsLabel',FieldsLabel );
                //-- Start | FIN-9048 | Chanegs by Asera 02-Feb-2026--//
                if(formatType == 'Excel' || formatType == 'PDF') {
                    if(inMap.containsKey('attachment-template') && inMap.get('attachment-template') != null) {
                        try {
                            String emailAttachmentTemplate = (String)inMap.get('attachment-template');
                            String emailAttachmentTemplateFolder = inMap.containsKey('attachment-template-folder') ? (String)inMap.get('attachment-template-folder') : null;
                            List<EmailTemplate> emailTemplateList = new List<EmailTemplate>();
                            
                            if (String.isNotBlank(emailAttachmentTemplateFolder)) {
                                emailTemplateList = [SELECT Id, Name, Subject, HtmlValue, Body FROM EmailTemplate WHERE Name = :emailAttachmentTemplate AND Folder.Name =: emailAttachmentTemplateFolder WITH SECURITY_ENFORCED LIMIT 1];
                            }
                            
                            if(emailTemplateList.isEmpty()){
                                emailTemplateList = [SELECT Id, Name, Subject, HtmlValue, Body FROM EmailTemplate WHERE Name = :emailAttachmentTemplate WITH SECURITY_ENFORCED LIMIT 1];
                            }

                            if(!emailTemplateList.isEmpty()){
                                String accountId = (new list<string> (accId))[0];
                                Messaging.SingleEmailMessage message = Messaging.renderStoredEmailTemplate(emailTemplateList[0].Id, null, accountId);
                                // << START - MM - FIN-9455 - Send Email -> Replace custom placeholders and translations >> 
                                // inMap.put('templateBody', message.getHtmlBody());
                                System.debug('Fetched template body for attachment: ' + message.getHtmlBody());
                                String attachmentHtmlBody = message.getHtmlBody();
                                if (attachmentHtmlBody.Contains('{Transactions.TotalOpenItems}') || attachmentHtmlBody.Contains('{Transactions.TotalOverdueItems}') || attachmentHtmlBody.Contains('{Transactions.TotalOverdueNotNotedItems}')) {
                                    List<String> transactionIds = new List<String>();
                                    for (celsrm__Transaction__c transObj : lstTrans) {
                                        transactionIds.add(transObj.Id);
                                    }
                                    Map<String,String> returnTemplateAmount = UtilityController.getTransactionTotalSummary((String)inMap.get('Id'), transactionIds);
                                    attachmentHtmlBody = attachmentHtmlBody.replace('{Transactions.TotalOpenItems}', returnTemplateAmount.get('TotalOpenItems'));
                                    attachmentHtmlBody = attachmentHtmlBody.replace('{Transactions.TotalOverdueItems}', returnTemplateAmount.get('TotalOverdueItems'));
                                    attachmentHtmlBody = attachmentHtmlBody.replace('{Transactions.TotalOverdueNotNotedItems}', returnTemplateAmount.get('TotalOverdueNotNotedItems'));
                                }
                                attachmentHtmlBody = UtilityController.replaceCustomerSpecificPlaceholders(attachmentHtmlBody, accountLocale);
                                inMap.put('templateBody', attachmentHtmlBody);
                                // << END - MM - FIN-9455 - Send Email -> Replace custom placeholders and translations >> 
                            }
                        } catch(Exception e) {
                            System.debug('Template Fetch Error: ' + e.getMessage());
                        }
                    }
                }
                //-- End | FIN-9048 | Chanegs by Asera 02-Feb-2026--//
                inMap.put('isMultiCurrency',  UserInfo.IsMultiCurrencyOrganization());
                system.debug('test>>>>>>>>>');
                List<String> TransIds = new List<String>();
                for (celsrm__Transaction__c obj : lstTrans) { 
                    TransIds.add(obj.Id);
                }
                inMap.put('TransIds', String.join(TransIds,','));
                system.debug('functionName>>'+functionName);
                system.debug('AttachCheckBox>>'+(Boolean)inMap.get('AttachCheckBox'));
                system.debug('preview>>'+(Boolean)inMap.get('preview'));
                if (functionName != 'exportAll' && ((Boolean)inMap.get('AttachCheckBox') || (inMap.get('preview') != null && (Boolean)inMap.get('preview')))) {
                    //-- Start | FIN-8334 | Changed by Ravi | 11 sep 2025 --//
                    // << START - MM - FIN-10130 | Feature JIRA FIN-8279 - Email Attachment -> Totals by currencycode >> 
                    // if (contentTemplate.Contains('{Transactions.TotalBalance}')) {
                    if (contentTemplate.Contains('{Transactions.TotalBalance}') || contentTemplate.Contains('{Transactions.TotalOpenItems}') || contentTemplate.Contains('{Transactions.TotalOverdueItems}') || contentTemplate.Contains('{Transactions.TotalOverdueNotNotedItems}')) {
                    // << END - MM - FIN-10130 | Feature JIRA FIN-8279 - Email Attachment -> Totals by currencycode >> 
                        Map<String,String> returnTemplateAmount = UtilityController.getTransactionTotalSummary((String)inMap.get('Id'),TransIds);
                        inMap.put('returnTemplateAmount', returnTemplateAmount);
                        contentTemplate = contentTemplate.replace('{Transactions.TotalBalance}', returnTemplateAmount.get('TotalBalance'));
                        // << START - MM - FIN-10130 | Feature JIRA FIN-8279 - Email Attachment -> Totals by currencycode >> 
                        contentTemplate = contentTemplate.replace('{Transactions.TotalOpenItems}', returnTemplateAmount.get('TotalOpenItems'));
                        contentTemplate = contentTemplate.replace('{Transactions.TotalOverdueItems}', returnTemplateAmount.get('TotalOverdueItems'));
                        contentTemplate = contentTemplate.replace('{Transactions.TotalOverdueNotNotedItems}', returnTemplateAmount.get('TotalOverdueNotNotedItems'));
                        // << END - MM - FIN-10130 | Feature JIRA FIN-8279 - Email Attachment -> Totals by currencycode >> 
                    }
                    //-- End | FIN-8334 | Changed by Ravi | 11 sep 2025 --//
                    // << START - MM - FIN-10130 | Feature JIRA FIN-8279 - Email Attachment -> Totals by currencycode >> 
                    contentTemplate = UtilityController.replaceCustomerSpecificPlaceholders(contentTemplate, accountLocale);
                    // << END - MM - FIN-10130 | Feature JIRA FIN-8279 - Email Attachment -> Totals by currencycode >> 
                    inMap.put('SendStmtAttachmentContent',contentTemplate );

                    //-- Starts | FIN-9351 | Changed by Dhwanil | 03 Mar 2026 --//
					Map<String, String> imageMap = UtilityController.extractImagesAsBase64(contentTemplate);
					inMap.put('templateBodyImageBase64Map', imageMap);
					//-- Ends | FIN-9351 | Changed by Dhwanil | 03 Mar 2026 --//
                }
            //}
            System.debug('@@@@ inMap : ' + inMap);
        
           
        return inMap;
    }
}