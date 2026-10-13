// << START - MM - FIN-8174 - Dynamic translated headers based account local | For Treatment (Excel)>>
public with sharing class cTreatmentExcelAttachmentController {
    public String taskId {get; set; }
    public String accountId {get; set; }
    public String taskSubject {get; set; }
    public String treatmentStage {get; set; }
    public String treatmentId {get; set; }
    public String tableBody {get; set; }
    public String jsonFileName {get; set; }

    // public cTreatmentExcelAttachmentController() {
    //     tableBody = 'ctest body';
    // }

    public cTreatmentExcelAttachmentController() {
        taskId = ApexPages.currentPage().getParameters().get('taskId');
        accountId = ApexPages.currentPage().getParameters().get('accountId');
        taskSubject = ApexPages.currentPage().getParameters().get('taskSubject');
        treatmentStage = ApexPages.currentPage().getParameters().get('treatmentStage');
        treatmentId = ApexPages.currentPage().getParameters().get('treatmentId');
        jsonFileName = ApexPages.currentPage().getParameters().get('jsonFileName');
        List<celsrm__Treatment__c> treatmentList = new List<celsrm__Treatment__c>();
        //-- Start | FIN-8208| Changed by Asera | 17 April 2026 --// - Dynamic translated headers based account local
        String accountLocal = 'EN';
		if (String.isNotBlank(accountId)) {
			List<Account> accountsForLocale = [SELECT Id, celsrm__Locale__c FROM Account WHERE Id = :accountId LIMIT 1];
			if (!accountsForLocale.isEmpty()) {
				accountLocal = accountsForLocale[0].celsrm__Locale__c != null ? accountsForLocale[0].celsrm__Locale__c : 'EN';
			}
		}
        //-- End | FIN-8208| Changed by Asera | 17 April 2026 --// - Dynamic translated headers based account local
        if(celsrm.GOGSecurityController.isAccessible('celsrm__Treatment__c', 'Id,Name,celsrm__Related_Object__c,celsrm__Treatment_Steps__c,celsrm__Template_Folder_Reference_Field__c,celsrm__Email_Template_Prefix__c,celsrm__Enable_Dynamic_Template__c,celsrm__Seperate_Task_For_Step__c,celsrm__Consolidated_Treatment__c')) {
            treatmentList = [SELECT Id, Name, celsrm__Related_Object__c, celsrm__Treatment_Steps__c, celsrm__Template_Folder_Reference_Field__c, celsrm__Email_Template_Prefix__c, celsrm__Enable_Dynamic_Template__c, celsrm__Seperate_Task_For_Step__c, celsrm__Consolidated_Treatment__c FROM celsrm__Treatment__c WHERE Id=:treatmentId LIMIT 1];
        }
        List<EmailTemplate> em = new List<EmailTemplate>();
        if(treatmentList.get(0).celsrm__Enable_Dynamic_Template__c){
            if (treatmentList.get(0).celsrm__Template_Folder_Reference_Field__c != null && treatmentList.get(0).celsrm__Template_Folder_Reference_Field__c != '') {
                String query = 'SELECT ' +  String.escapeSingleQuotes(treatmentList.get(0).celsrm__Template_Folder_Reference_Field__c) + ' FROM Account WHERE Id=:accountId';
                System.debug('query>> ' + query);
                List<Account> accList = Database.query(query);
                if (!accList.isEmpty() && accList.size() > 0) {
                    String folderName = (String)accList.get(0).get(treatmentList.get(0).celsrm__Template_Folder_Reference_Field__c);
                    if (folderName != null && folderName != '') {
                        // << START - MM - FIN-8324 - [Akzonobel] Use common template for all attachments>>
                        // em = [SELECT Id FROM EmailTemplate WHERE Folder.Name = :folderName AND Name = 'System_TreatmentExcelAttachment' AND IsActive = TRUE WITH SECURITY_ENFORCED LIMIT 1];
                        em = [SELECT Id FROM EmailTemplate WHERE Folder.Name = :folderName AND Name = 'SYSTEM_BillingStatementExcel' AND IsActive = TRUE WITH SECURITY_ENFORCED LIMIT 1];
                        // << END - MM - FIN-8324 - [Akzonobel] Use common template for all attachments>>
                        if (em.isEmpty() || em.size() == 0) {
                            // << START - MM - FIN-8324 - [Akzonobel] Use common template for all attachments>>
                            // em = [SELECT Id FROM EmailTemplate WHERE Name ='System_TreatmentExcelAttachment' AND IsActive = TRUE WITH SECURITY_ENFORCED LIMIT 1];
                            em = [SELECT Id FROM EmailTemplate WHERE Name ='SYSTEM_BillingStatementExcel' AND IsActive = TRUE WITH SECURITY_ENFORCED LIMIT 1];
                            // << END - MM - FIN-8324 - [Akzonobel] Use common template for all attachments>>
                        }
                    } else {
                        // << START - MM - FIN-8324 - [Akzonobel] Use common template for all attachments>>
                        // em = [SELECT Id FROM EmailTemplate WHERE Name ='System_TreatmentExcelAttachment' AND IsActive = TRUE WITH SECURITY_ENFORCED LIMIT 1];
                        em = [SELECT Id FROM EmailTemplate WHERE Name ='SYSTEM_BillingStatementExcel' AND IsActive = TRUE WITH SECURITY_ENFORCED LIMIT 1];
                        // << END - MM - FIN-8324 - [Akzonobel] Use common template for all attachments>>
                    }
                }
            }
        } else {
            // << START - MM - FIN-8324 - [Akzonobel] Use common template for all attachments>>
            // em = [SELECT Id FROM EmailTemplate WHERE Name ='System_TreatmentExcelAttachment' AND IsActive = TRUE WITH SECURITY_ENFORCED LIMIT 1];
            em = [SELECT Id FROM EmailTemplate WHERE Name ='SYSTEM_BillingStatementExcel' AND IsActive = TRUE WITH SECURITY_ENFORCED LIMIT 1];
            // << END - MM - FIN-8324 - [Akzonobel] Use common template for all attachments>>
        }
        
        String templateBody = '';
        if (!em.isEmpty() && em.size() > 0) {
            List<Contact> con = new List<Contact>();
            try {
                con = [SELECT Id FROM Contact WHERE celsrm__Default__c=true AND accountId=:accountId WITH SECURITY_ENFORCED];
                if (con == null || con.size() == 0) {
                    con = [SELECT Id FROM Contact WHERE accountId=:accountId WITH SECURITY_ENFORCED];
                }
            } catch (Exception e) {
                System.debug(e.getMessage());
            }
            
            Id ContactId = null;
            if(con!= null && con.size()>0){
                ContactId =con.get(0).Id;
            }
            Messaging.SingleEmailMessage message = Messaging.renderStoredEmailTemplate(em.get(0).Id, ContactId, accountId);
            templateBody = message.getHtmlBody();
            templateBody = templateBody.remove('<strong> Total :&nbsp;&nbsp; </strong> {Transactions.TotalBalance}');
        }
        if (templateBody != '') {
            String stepsData = celsrm.SRMTreatmentUtility.readTreatmentDetailsFile(taskId, jsonFileName);
            if (stepsData != '') {
                if (treatmentList.size() > 0) {
                    String childObjAPIName = treatmentList.get(0).celsrm__Related_Object__c;
                    Map<string, Schema.sObjectType> describeInfo = Schema.getGlobalDescribe();
                    Map<String, Schema.SObjectField> fMap = describeInfo.get(childObjAPIName.toLowerCase()).getDescribe().Fields.getMap();
                    Map<String, String> fieldApiVsTranslatedLabel = celsrm.SRMUtilityController.getTranslatedLabelMapForObject(accountLocal, childObjAPIName); //-- Start | FIN-8208| Changed by Asera | 17 April 2026 --// - Dynamic translated headers based account local
                    List<cSRMTreatmentMapper.ObjectCriteria> listOfTreatmentStep = (List<cSRMTreatmentMapper.ObjectCriteria>)JSON.deserialize(treatmentList.get(0).celsrm__Treatment_Steps__c, List<cSRMTreatmentMapper.ObjectCriteria>.class);
                    Map<String, Object> mapStepsDataObj =  (map < string, object > ) JSON.deserializeUntyped(stepsData);
                    
                    if (treatmentList.get(0).celsrm__Seperate_Task_For_Step__c || treatmentList.get(0).celsrm__Consolidated_Treatment__c){
                        Set<Id> childIds = new Set<Id>();
                        for(String mapStepsDataKey : mapStepsDataObj.keySet()){
                            for (Object ids : (List<Object>) mapStepsDataObj.get(mapStepsDataKey)) {
                                childIds.add((Id)ids);
                            }
                        }
                        if (childIds != null && childIds.size() > 0) {
                            Double TotalBalance = 0;
                            List<String> columnsNameList = new List<String>();
                            List<String> TempSelFlds= new List<String>();
                            for (cSRMTreatmentMapper.ObjectCriteria treStep: listOfTreatmentStep) {
                                if (treatmentStage == treStep.stepName) {
                                    Map<String, Object> returnBodyMap = cSRMTreatmentUtility.getBody(treStep, fMap, childObjAPIName, treatmentList.get(0), false, childIds, treStep.stepName, true, fieldApiVsTranslatedLabel);
                                    String htmlBody = returnBodyMap.get('innerHtml') != null ? (String)returnBodyMap.get('innerHtml') : '';
                                    tableBody = templateBody.replace('{Transaction.Summary}', htmlBody);
                                    // << START - MM - FIN-8174 - Dynamic translated headers based account local | template placeholders>>
                                    tableBody = UtilityController.replaceCustomerSpecificPlaceholders(tableBody, accountLocal);
                                    // << END - MM - FIN-8174 - Dynamic translated headers based account local | template placeholders>> 
                                    // << START - MM - FIN-8279 - Email Attachment -> Totals by currencycode >> 
                                    Map<String, Double> TotalOpenItems = returnBodyMap.get('TotalOpenItems') != null ? (Map<String, Double>)returnBodyMap.get('TotalOpenItems'): new Map<String, Double>();
                                    Map<String, Double> TotalOverdueItems = returnBodyMap.get('TotalOverdueItems') != null ? (Map<String, Double>)returnBodyMap.get('TotalOverdueItems'): new Map<String, Double>();
                                    Map<String, Double> TotalOverdueNotNotedItems = returnBodyMap.get('TotalOverdueNotNotedItems') != null ? (Map<String, Double>)returnBodyMap.get('TotalOverdueNotNotedItems'): new Map<String, Double>();
                                    Map<String, String> returnMap = fetchAgreegatedAmount(TotalOpenItems, TotalOverdueItems, TotalOverdueNotNotedItems);
                                    tableBody = tableBody.replace('{Transactions.TotalOpenItems}', returnMap.get('TotalOpenItems'));
                                    tableBody = tableBody.replace('{Transactions.TotalOverdueItems}', returnMap.get('TotalOverdueItems'));
                                    tableBody = tableBody.replace('{Transactions.TotalOverdueNotNotedItems}', returnMap.get('TotalOverdueNotNotedItems'));
                                    // << END - MM - FIN-8279 - Email Attachment -> Totals by currencycode >> 
                                }
                                
                            }
                        }
                    
                    } else if(!treatmentList.get(0).celsrm__Consolidated_Treatment__c) {
                        // << START - MM - FIN-8279 - Email Attachment -> Totals by currencycode >> 
                        Map<String, Double> TotalOpenItems = new Map<String, Double>();
                        Map<String, Double> TotalOverdueItems = new Map<String, Double>();
                        Map<String, Double> TotalOverdueNotNotedItems = new Map<String, Double>();
                        // << END - MM - FIN-8279 - Email Attachment -> Totals by currencycode >> 
                        tableBody = '';
                        for (cSRMTreatmentMapper.ObjectCriteria treStep: listOfTreatmentStep) {
                            String stepName = treStep.stepName != null ? String.valueOf(treStep.stepName) : '';
                            if(mapStepsDataObj.containsKey(String.valueOf(treStep.stepName))){
                                List<Object> objChildIds = (List<Object>) mapStepsDataObj.get(String.valueOf(treStep.stepName));
                                Set<Id> childId = new Set<Id>();
                                if (objChildIds != null && objChildIds.size() > 0) {
                                    for(Object a: objChildIds){
                                        childId.add(String.valueOf(a));
                                    }
                                }
                                if (childId != null && childId.size() > 0) {
                                    Map<String, Object> returnBodyMap = cSRMTreatmentUtility.getBody(treStep, fMap, childObjAPIName, treatmentList.get(0), false, childId, stepName, false, fieldApiVsTranslatedLabel);
                                    String htmlBody = returnBodyMap.get('innerHtml') != null ? (String)returnBodyMap.get('innerHtml') : '';
                                    tableBody += htmlBody;
                                    // << START - MM - FIN-8279 - Email Attachment -> Totals by currencycode >> 
                                    Map<String, Double> TotalOpenItemsTemp = returnBodyMap.get('TotalOpenItems') != null ? (Map<String, Double>)returnBodyMap.get('TotalOpenItems'): new Map<String, Double>();
                                    Map<String, Double> TotalOverdueItemsTemp = returnBodyMap.get('TotalOverdueItems') != null ? (Map<String, Double>)returnBodyMap.get('TotalOverdueItems'): new Map<String, Double>();
                                    Map<String, Double> TotalOverdueNotNotedItemsTemp = returnBodyMap.get('TotalOverdueNotNotedItems') != null ? (Map<String, Double>)returnBodyMap.get('TotalOverdueNotNotedItems'): new Map<String, Double>();
                                    if(TotalOpenItemsTemp.keySet().size() > 0) {
                                        for(String key: TotalOpenItemsTemp.keySet()) {
                                            if(TotalOpenItems.containsKey(key)) {
                                                TotalOpenItems.put(key, TotalOpenItems.get(key) + TotalOpenItemsTemp.get(key));
                                            } else {    
                                                TotalOpenItems.put(key, TotalOpenItemsTemp.get(key));
                                            }
                                        }
                                    }
                                    if(TotalOverdueItemsTemp.keySet().size() > 0) {
                                        for(String key: TotalOverdueItemsTemp.keySet()) {
                                            if(TotalOverdueItems.containsKey(key)) {
                                                TotalOverdueItems.put(key, TotalOverdueItems.get(key) + TotalOverdueItemsTemp.get(key));
                                            } else {    
                                                TotalOverdueItems.put(key, TotalOverdueItemsTemp.get(key));
                                            }
                                        }
                                    }

                                    if(TotalOverdueNotNotedItemsTemp.keySet().size() > 0) {
                                        for(String key: TotalOverdueNotNotedItemsTemp.keySet()) {
                                            if(TotalOverdueNotNotedItems.containsKey(key)) {
                                                TotalOverdueNotNotedItems.put(key, TotalOverdueNotNotedItems.get(key) + TotalOverdueNotNotedItemsTemp.get(key));
                                            } else {    
                                                TotalOverdueNotNotedItems.put(key, TotalOverdueNotNotedItemsTemp.get(key));
                                            }
                                        }
                                    }
                                    // << END - MM - FIN-8279 - Email Attachment -> Totals by currencycode >> 
                                }
                            }
                        }
                        tableBody = tableBody.removeEnd('<br><br>');
                        tableBody = templateBody.replace('{Transaction.Summary}', tableBody);
                        // << START - MM - FIN-8279 - Email Attachment -> Totals by currencycode >> 
                        Map<String, String> returnMap = fetchAgreegatedAmount(TotalOpenItems, TotalOverdueItems, TotalOverdueNotNotedItems);
                        tableBody = tableBody.replace('{Transactions.TotalOpenItems}', returnMap.get('TotalOpenItems'));
                        tableBody = tableBody.replace('{Transactions.TotalOverdueItems}', returnMap.get('TotalOverdueItems'));
                        tableBody = tableBody.replace('{Transactions.TotalOverdueNotNotedItems}', returnMap.get('TotalOverdueNotNotedItems'));
                        // << END - MM - FIN-8279 - Email Attachment -> Totals by currencycode >> 
                        // << START - MM - FIN-8174 - Dynamic translated headers based account local | template placeholders>>
                        tableBody = UtilityController.replaceCustomerSpecificPlaceholders(tableBody, accountLocal);
                        // << END - MM - FIN-8174 - Dynamic translated headers based account local | template placeholders>> 
                    }
                }
            }
        }
    }

    // << START - MM - FIN-8174 - Dynamic translated headers based account local | template placeholders>>
    private static  Map<String, String>  fetchAgreegatedAmount(Map<String, Double> TotalOpenItems, Map<String, Double> openItemsForOverDue, Map<String, Double> openItemsForOverDueNotNoted) {
        List<String> openItemsTotal = new List<String>();
        if(TotalOpenItems.keySet().size() > 0) {
            for(String curr : TotalOpenItems.keySet()) {
                openItemsTotal.add(curr + ' ' + String.valueOf(cSRMTreatmentUtility.formatAsCurrency(TotalOpenItems.get(curr))));
            }
        }

        List<String> openItemsForOverDueTotal = new List<String>();
        if(openItemsForOverDue.keySet().size() > 0) {
            for(String curr : openItemsForOverDue.keySet()) {
                openItemsForOverDueTotal.add(curr + ' ' + String.valueOf(cSRMTreatmentUtility.formatAsCurrency(openItemsForOverDue.get(curr))));
            }
        }

        List<String> openItemsForOverDueNotNotedTotal = new List<String>();
        if(openItemsForOverDueNotNoted.keySet().size() > 0) {
            for(String curr : openItemsForOverDueNotNoted.keySet()) {
                openItemsForOverDueNotNotedTotal.add(curr + ' ' + String.valueOf(cSRMTreatmentUtility.formatAsCurrency(openItemsForOverDueNotNoted.get(curr))));
            }
        }
        Map<String, String> returnMap = new Map<String, String>();
        returnMap.put('TotalOpenItems', String.join(openItemsTotal, ', '));
        returnMap.put('TotalOverdueItems', String.join(openItemsForOverDueTotal, ', '));
        returnMap.put('TotalOverdueNotNotedItems', String.join(openItemsForOverDueNotNotedTotal, ', '));
        return returnMap;
    }
    // << END - MM - FIN-8174 - Dynamic translated headers based account local | template placeholders>>
}
// << END - MM - FIN-8174 - Dynamic translated headers based account local | For Treatment (Excel)>>