global class TaskTreatmentController implements celsrm.GOGIScreenCustomLogic {

    global Map<Object, Object> invoke(String functionName, Map<Object, Object> inMap) {
        if (functionName == 'returnGridData') {
            inMap = returnGridData(inMap);
        } else if (functionName == 'customSendEmail') {
            inMap = customSendEmail(inMap,true);
        } else if (functionName == 'logACall') {
            inMap = logACall(inMap);
        } else if (functionName == 'FetchCallScript') {
            inMap = FetchCallScript(inMap);
        } else if (functionName == 'showTreatmentNotes') {
            inMap = showTreatmentNotes(inMap);
        } else if (functionName == 'includeTreatmentOnAccount') {
            inMap = includeTreatmentOnAccount(inMap);
        } else if (functionName == 'fetchContactEmailForAccount') {
            inMap = fetchContactEmailForAccount(inMap);
		//-- Start | FIN-8209 | Changed By Dilshad | 13-Aug-2025 --//
		} else if (functionName == 'getConsolidatedData') {
            inMap = getConsolidatedData(inMap);
        } else if(functionName == 'getPreDataForExcelFileGeneration'){
            inMap = getPreDataForExcelFileGeneration(inMap);
		} else if(functionName == 'uploadExcelFile'){
			String contentVersionId = uploadExcelFile(inMap);
			inMap.put('contentVersionId', contentVersionId);
		//-- FIN-9747 | Changed by Dilshad | 12-May-2026 | Start --//
		} else if(functionName == 'savePdfHtmlChunk'){
			inMap = savePdfHtmlChunk(inMap);
		} else if(functionName == 'deletePdfTempChunks'){
			inMap = deletePdfTempChunks(inMap);
		} else if(functionName == 'generatePDFAttachment'){
			inMap = generatePDFAttachment(inMap);
		} else if(functionName == 'getPreDataForPDFAttachment'){
			inMap = getPreDataForPDFAttachment(inMap);
		}
		//-- FIN-9747 | Changed by Dilshad | 12-May-2026 | End --//
		//-- FIN-8540 | Changed by Ravi | 15-Jun-2026 | Start --//
		else if(functionName == 'getAIDunningTemplate'){
			inMap = getAIDunningTemplate(inMap);
		}
		//-- FIN-8540 | Changed by Ravi | 15-Jun-2026 | End --//
		//-- End | FIN-8209 | Changed By Dilshad | 13-Aug-2025 --//
		//-- End | FIN-8209 | Changed By Dilshad | 13-Aug-2025 --//
		 else if (functionName == 'setAccountLocale') {
            inMap = setAccountLocale(inMap);
        } else if (functionName == 'updateAccountLocale'){
			inMap = updateAccountLocale(inMap);
		}
        return inMap;
    }
	//-- FIN-8540 | Changed by Ravi | 15-Jun-2026 | Start --//
	@AuraEnabled
	public static Map<Object, Object> getAIDunningTemplate(Map<Object, Object> inMap){
		Map<Object, Object> resultMap = new Map<Object, Object>();
		Boolean isAiDunning = inMap.get('aiDunning') == true || inMap.get('aiDunning') == 'true';
		if (!isAiDunning) {
			return resultMap;
		}
		String taskId = (String)inMap.get('Id');

		Task taskRec = [SELECT Id, WhatId, celsrm__Treatment__c, Owner.Name, Owner.Email, Owner.Title, Owner.UserRole.Name FROM Task WHERE Id = :taskId LIMIT 1];
		celsrm__Treatment__c treatment = [SELECT Id, Name, celsrm__Template_Generation_Prompt__c, celsrm__Show_Total__c, celsrm__Aggregation_Field__c, celsrm__Total_Label__c, celsrm__Transaction_Table_Columns__c, celsrm__Enable_Multi_Language__c, celsrm__Language_Field__c, celsrm__Enable_AI_Generated_Template__c, celsrm__Enable_Dynamic_Template__c, celsrm__Email_Template__c, celsrm__Template_Folder__c, celsrm__Template_Folder_Reference_Field__c, celsrm__Email_Template_Prefix__c FROM celsrm__Treatment__c WHERE Id = :taskRec.celsrm__Treatment__c];
		String tempData =
            celsrm.SRMTreatmentUtility.readTreatmentDetailsFile(taskId, 'AI Dunning Task Data');
        
        System.debug('Dunning Task Data JSON: ' + tempData);

        Map<String, Object> dunningData =  (map < string, object > ) JSON.deserializeUntyped(tempData);

		AIDunningTemplateGeneration.DunningEmailResult aiEmail;

		if (treatment.celsrm__Enable_AI_Generated_Template__c) {
			String language = null;
			if (treatment.celsrm__Enable_Multi_Language__c && String.isNotBlank(treatment.celsrm__Language_Field__c)) {
				String langField = String.escapeSingleQuotes(treatment.celsrm__Language_Field__c.trim());
				Id accountId = taskRec.WhatId;
				String langQuery = 'SELECT ' + langField + ' FROM Account WHERE Id = :accountId LIMIT 1';
				List<SObject> langResults = Database.query(langQuery);
				if (!langResults.isEmpty() && langResults[0].get(treatment.celsrm__Language_Field__c.trim()) != null) {
					language = String.valueOf(langResults[0].get(treatment.celsrm__Language_Field__c.trim()));
				}
			}
			Map<String, String> collectorDetails = new Map<String, String>();
			if (taskRec.Owner != null) {
				collectorDetails.put('name', taskRec.Owner.Name);
				collectorDetails.put('email', taskRec.Owner.Email);
				collectorDetails.put('title', taskRec.Owner.Title);
				collectorDetails.put('role', taskRec.Owner.UserRole != null ? taskRec.Owner.UserRole.Name : null);
			}
			try {
				aiEmail = AIDunningTemplateGeneration.generateDunningEmailContent(null, dunningData, null, treatment.celsrm__Template_Generation_Prompt__c, language, collectorDetails);
			} catch (Exception ex) {
				System.debug('AI generation failed for task ' + taskId + ': ' + ex.getMessage());
				throw new AuraHandledException('Error generating AI email template: ' + ex.getMessage());
			}
		} else {
			aiEmail = resolveStaticTemplateForTask(treatment, taskRec);
		}
		
		List<Id> txnIdList = new List<Id>();
        if (dunningData != null && dunningData.containsKey('eligibleTransactionIds')) {
            List<Object> rawList = (List<Object>) dunningData.get('eligibleTransactionIds');

            for (Object o : rawList) {
                if (o != null) {
                    String s = String.valueOf(o).trim();
                    if (String.isNotBlank(s)) {
                        try {
                            txnIdList.add(Id.valueOf(s));
                        } catch (Exception e) {
                            System.debug('Skipping invalid Id in eligibleTransactionIds: ' + s);
                        }
                    }
                }
            }
        }
		Map<String, Object> tableData = AIDunningTemplateGeneration.buildTransactionHtmlTable(
            txnIdList,
            treatment.celsrm__Show_Total__c,
            treatment.celsrm__Aggregation_Field__c,
            treatment.celsrm__Total_Label__c,
            'celsrm__Transaction__c',
            treatment.celsrm__Transaction_Table_Columns__c
        );
        String transactionTable = (String)tableData.get('innerHtml');
        if (aiEmail.body != null && aiEmail.body.contains('{transactions.summary}')) {
            aiEmail.body = aiEmail.body.replace('{transactions.summary}', transactionTable);
        } else if (transactionTable != null) {
            aiEmail.body = (aiEmail.body != null ? aiEmail.body : '') + '<br/><br/>' + transactionTable;
        }

		Map<String, String> composeEmail = new Map<String, String>();
		composeEmail.put('subject', aiEmail.subject);
		composeEmail.put('body', aiEmail.body);
		resultMap.put('ComposeEmail', composeEmail);
        
		return resultMap;
	}
	//-- FIN-8540 | Changed by Ravi | 15-Jun-2026 | End --//

	@AuraEnabled
    public static String readTreatmentDetailsFile(String taskID, String fileName){
		String stepsData = '';
		
        List<ContentDocumentLink> listContentDL = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId =: taskID];
        Set<Id> conDocIds = new Set<Id>();
        for(ContentDocumentLink conDL : listContentDL){
            conDocIds.add(conDL.ContentDocumentId);
        }
        List<ContentDocument> listContentDoc = [SELECT Id, FileExtension, Title, LastModifiedDate FROM ContentDocument WHERE Id IN :conDocIds and Title =: fileName];
        if(!listContentDoc.isEmpty()){
			ContentDocument selectedContentDoc = listContentDoc.get(0);
			List<ContentVersion> listContentVer = [SELECT VersionData FROM ContentVersion WHERE ContentDocumentId = :selectedContentDoc.Id AND IsLatest = true];
			if(!listContentVer.isEmpty()){
                
				if(listContentVer.get(0).VersionData != null){
					stepsData = listContentVer.get(0).VersionData.toString();
					system.debug('@@ stepsData >>>' + stepsData);
					
				}
                
			}
        }
		return stepsData;
	}

	@AuraEnabled
	public static Map<String, Object> getScreenConfig(String taskID){
		Map<String,Object> config = new Map<String,Object>();
		Map<String,Object> sectionConfig = new Map<String,Object>();
		//-- FIN-8540 | Changed by Ravi | 15-Jun-2026 | Start --//
		List<Task> listTask = [select id,Subject,celsrm__Treatment__c,WhatId,Status, celsrm__Treatment_Stage__c, AiDunning__c from task where id =: taskID];
		
		// AI Dunning - Simplified Screen Config 
		if(listTask != null && !listTask.isEmpty() && listTask.get(0).AiDunning__c == true) {
			return getAiDunningScreenConfig(listTask.get(0), taskID);
		}
		//-- FIN-8540 | Changed by Ravi | 15-Jun-2026 | End --//
		ID treatmentId = listTask.get(0).celsrm__Treatment__c;
		//-- Start | FIN-8209 | Changed By Dilshad | Added celsrm__Attachment_Name__c in query | 13-Aug-2025 --//
		List<celsrm__Treatment__c> listTreatment = [select id,Name,celsrm__Email_Template__c,celsrm__Related_Object__c,celsrm__Treatment_Steps__c,
														celsrm__Task_Type__c, celsrm__Template_Folder_Reference_Field__c, celsrm__Email_Template_Prefix__c, 
														celsrm__Custom_Logic_Class__c, celsrm__Seperate_Task_For_Step__c,
														celsrm__Auto_Treatment__c, celsrm__Enable_Dynamic_Template__c, celsrm__Attachment__c, celsrm__Attachment_Format__c, celsrm__Attachment_Name__c,
														//-- Start | FIN-9041 | Chanegs by Asera 02-Feb-2026--//
														celsrm__Attachment_Template_Name__c, celsrm__Attachment_Template_Folder__c, celsrm__Attachment_Template_Folder_Ref_Field__c
														//-- End | FIN-9041 | Chanegs by Asera 02-Feb-2026--//
														FROM celsrm__Treatment__c 
														where id =:treatmentId ];
		//-- End | FIN-8209 | Changed By Dilshad | 13-Aug-2025 --//
		celsrm__Treatment__c treatment = listTreatment.get(0);

		//-- Starts | FIN-6885 | Changed by Sejal | 24 JAN 2025 --//
		List<ObjectCriteria> listOfTreatmentStep =  (List<ObjectCriteria> ) JSON.deserialize(listTreatment.get(0).celsrm__Treatment_Steps__c, List<ObjectCriteria>.class);
		List<String> listOfStep = new List<String>();
		//-- Starts | FIN-8209 | Changed By Dilshad/Asera | 13-Aug-2025 --//
		// for (ObjectCriteria treStep: listOfTreatmentStep) {
		// 	if(treStep.active){
		// 		listOfStep.add(treStep.stepName);
		// 	}
		// }

		Map<String, Object> mapStepsDataObj = new Map<String, Object>();
		String stepsData = celsrm.SRMTreatmentUtility.readTreatmentDetailsFile(taskID,'Treatment Details');
		if (stepsData != '') {
			mapStepsDataObj =  (map < string, object > ) JSON.deserializeUntyped(stepsData);
			// Convert the Set of keys into a List before assigning
			listOfStep = new List<String>(mapStepsDataObj.keySet()); 
		}
		//-- End | FIN-8209 | Changed By Dilshad/Asera | 13-Aug-2025 --//
		//-- Ends | FIN-6885 | Changed by Sejal | 24 JAN 2025 --//
		List<Map<String,Object>> section = new List<Map<String,Object>>();
		List<Map<String,Object>> block = new List<Map<String,Object>>();

		Map<String,Object> blockConfig = new Map<String,Object>();
		blockConfig.put('name', '');
		blockConfig.put('title', '');
		blockConfig.put('isActive', true);
		blockConfig.put('hideTitle', false);
		blockConfig.put('readOnly', false);
		blockConfig.put('readOnlyCriteria', null);
		blockConfig.put('hide', false);
		blockConfig.put('hideCriteria', null);
		blockConfig.put('desktopWidth', 12);
		blockConfig.put('tabletWidth', 12);
		blockConfig.put('mobileWidth', 12);
		blockConfig.put('buttons', new List<String>());
		blockConfig.put('theme', new Map<String,String>());

		List<Map<String,Object>> headerFieldConfig = new List<Map<String,Object>>();
		Map<String,Object> textConfig = new Map<String,Object>();
		textConfig.put('name', 'priority');
		textConfig.put('title', 'Priority');
		textConfig.put('type', 'text');
		textConfig.put('isActive', true);
		textConfig.put('hideTitle', false);
		textConfig.put('maxLength', 255);
		textConfig.put('desktopWidth', 3);
		textConfig.put('tabletWidth', 12);
		textConfig.put('mobileWidth', 12);
		textConfig.put('default', '');
		textConfig.put('readOnly', true);
		textConfig.put('readOnlyCriteria', null);
		textConfig.put('hide', false);
		textConfig.put('hideCriteria', null);
		textConfig.put('required', false);
		textConfig.put('requiredCriteria', null);
		textConfig.put('targetControlName', '');
		textConfig.put('onchange', '');
		textConfig.put('helpText', '');
		Map<String,Object> priorityConfig = new Map<String,Object>(textConfig);
		textConfig.put('name', 'status');
		textConfig.put('title', 'Status');
		Map<String,Object> statusConfig = new Map<String,Object>(textConfig);

		Map<String,Object> dueDateConfig = new Map<String,Object>();
		dueDateConfig.put('name', 'dueDate');
		dueDateConfig.put('title', 'Due Date');
		dueDateConfig.put('type', 'date');
		dueDateConfig.put('isActive', true);
		dueDateConfig.put('hideTitle', false);
		dueDateConfig.put('allowFutureDate', true);
		dueDateConfig.put('allowPastDate', true);
		dueDateConfig.put('desktopWidth', 3);
		dueDateConfig.put('tabletWidth', 12);
		dueDateConfig.put('mobileWidth', 12);
		dueDateConfig.put('readOnly', true);
		dueDateConfig.put('readOnlyCriteria', null);
		dueDateConfig.put('hide', false);
		dueDateConfig.put('hideCriteria', null);
		dueDateConfig.put('required', false);
		dueDateConfig.put('requiredCriteria', null);
		dueDateConfig.put('onchange', '');
		dueDateConfig.put('helpText', '');

		Map<String,Object> defaultLookupConfig = new Map<String,Object>();
		defaultLookupConfig.put('name', 'relatedTo');
		defaultLookupConfig.put('title', 'Account');
		defaultLookupConfig.put('type', 'reference');
		defaultLookupConfig.put('isActive', true);
		defaultLookupConfig.put('hideTitle', false);
		defaultLookupConfig.put('dataSource', '');
		defaultLookupConfig.put('dataSourceName', '');
		defaultLookupConfig.put('columns', new List<String>());
		defaultLookupConfig.put('rowSize', 10);
		defaultLookupConfig.put('data', new List<String>());
		defaultLookupConfig.put('desktopWidth', 2);
		defaultLookupConfig.put('tabletWidth', 12);
		defaultLookupConfig.put('mobileWidth', 12);
		defaultLookupConfig.put('default', new Map<String,String>()	);
		defaultLookupConfig.put('readOnly', true);
		defaultLookupConfig.put('readOnlyCriteria', null);
		defaultLookupConfig.put('hide', false);
		defaultLookupConfig.put('hideCriteria', null);
		defaultLookupConfig.put('required', false);
		defaultLookupConfig.put('requiredCriteria', null);
		defaultLookupConfig.put('hideLabel', false);
		defaultLookupConfig.put('onchange', '');
		defaultLookupConfig.put('helpText', '');
		Map<String,Object> accountConfig = new Map<String,Object>(defaultLookupConfig);
		defaultLookupConfig.put('name', 'assignedTo');
		defaultLookupConfig.put('title', 'Assigned To');
		defaultLookupConfig.put('desktopWidth', 3);
		Map<String,Object> ownerConfig = new Map<String,Object>(defaultLookupConfig);

		Map<String,Object> textAreaRichConfig = new Map<String,Object>();
		textAreaRichConfig.put('name', 'creditUtilization');
		textAreaRichConfig.put('title', 'Credit Utilization');
		textAreaRichConfig.put('type', 'textarearich');
		textAreaRichConfig.put('isActive', true);
		textAreaRichConfig.put('hideTitle', false);
		textAreaRichConfig.put('labelvisible', false);
		textAreaRichConfig.put('maxLength', 1024);
		textAreaRichConfig.put('maxLine', 3);
		textAreaRichConfig.put('height', 264);
		textAreaRichConfig.put('desktopWidth', 2);
		textAreaRichConfig.put('tabletWidth', 12);
		textAreaRichConfig.put('mobileWidth', 12);
		textAreaRichConfig.put('readOnly', true);
		textAreaRichConfig.put('readOnlyCriteria', null);
		textAreaRichConfig.put('hide', false);
		textAreaRichConfig.put('hideCriteria', null);
		textAreaRichConfig.put('required', false);
		textAreaRichConfig.put('requiredCriteria', null);
		textAreaRichConfig.put('onchange', '');
		textAreaRichConfig.put('helpText', '');
		Map<String,Object> creditUtilizationConfig = new Map<String,Object>(textAreaRichConfig);

		Map<String,Object> currencyConfig = new Map<String,Object>();
		currencyConfig.put('name', 'creditRemaining');
		currencyConfig.put('title', 'Credit Remaining');
		currencyConfig.put('type', 'currency');
		currencyConfig.put('isActive', true);
		currencyConfig.put('hideTitle', false);
		currencyConfig.put('maxLength', 16);
		currencyConfig.put('decimalPlaces', 0);
		currencyConfig.put('desktopWidth', 2);
		currencyConfig.put('tabletWidth', 12);
		currencyConfig.put('mobileWidth', 12);
		currencyConfig.put('readOnly', true);
		currencyConfig.put('readOnlyCriteria', null);
		currencyConfig.put('hide', false);
		currencyConfig.put('hideCriteria', null);
		currencyConfig.put('required', false);
		currencyConfig.put('requiredCriteria', null);
		currencyConfig.put('onchange', '');
		currencyConfig.put('helpText', '');
		Map<String,Object> creditRemainingConfig = new Map<String,Object>(currencyConfig);
		currencyConfig.put('name', 'totalAR');
		currencyConfig.put('title', 'Total AR');
		Map<String,Object> totalARConfig = new Map<String,Object>(currencyConfig);
		currencyConfig.put('name', 'totalPastDue');
		currencyConfig.put('title', 'Total Past Due');
		Map<String,Object> totalPastDueConfig = new Map<String,Object>(currencyConfig);
		currencyConfig.put('name', 'totalDisputed');
		currencyConfig.put('title', 'Total Disputed');
		Map<String,Object> totalDisputedConfig = new Map<String,Object>(currencyConfig);
		currencyConfig.put('name', 'current');
		currencyConfig.put('title', 'Current');
		Map<String,Object> currentConfig = new Map<String,Object>(currencyConfig);
		currencyConfig.put('name', 'age1');
		currencyConfig.put('title', '1-30');
		Map<String,Object> age1Config = new Map<String,Object>(currencyConfig);
		currencyConfig.put('name', 'age2');
		currencyConfig.put('title', '31-60');
		Map<String,Object> age2Config = new Map<String,Object>(currencyConfig);
		currencyConfig.put('name', 'age3');
		currencyConfig.put('title', '61-90');
		Map<String,Object> age3Config = new Map<String,Object>(currencyConfig);
		currencyConfig.put('name', 'age4');
		currencyConfig.put('title', '91-180');
		Map<String,Object> age4Config = new Map<String,Object>(currencyConfig);
		currencyConfig.put('name', 'age5');
		currencyConfig.put('title', 'Over 180');
		Map<String,Object> age5Config = new Map<String,Object>(currencyConfig);

		// headerFieldConfig.add(accountConfig);
		headerFieldConfig.add(ownerConfig);
		headerFieldConfig.add(priorityConfig);
		headerFieldConfig.add(dueDateConfig);
		headerFieldConfig.add(statusConfig);

		//-- FIN-8540 | Changed by Ravi | 15-Jun-2026 | Start --//
		Map<String,Object> aiDunningConfig = new Map<String,Object>();
		aiDunningConfig.put('name', 'isAiDunning');
		aiDunningConfig.put('title', 'AI Dunning');
		aiDunningConfig.put('type', 'checkbox');
		aiDunningConfig.put('isActive', true);
		aiDunningConfig.put('hideTitle', false);
		aiDunningConfig.put('desktopWidth', 3);
		aiDunningConfig.put('tabletWidth', 12);
		aiDunningConfig.put('mobileWidth', 12);
		aiDunningConfig.put('default', 'false');
		aiDunningConfig.put('readOnly', true);
		aiDunningConfig.put('readOnlyCriteria', null);
		aiDunningConfig.put('hide', true);
		aiDunningConfig.put('hideCriteria', null);
		aiDunningConfig.put('required', false);
		aiDunningConfig.put('requiredCriteria', null);
		aiDunningConfig.put('targetControlName', '');
		aiDunningConfig.put('onchange', '');
		aiDunningConfig.put('helpText', '');
		headerFieldConfig.add(aiDunningConfig);
		//-- FIN-8540 | Changed by Ravi | 15-Jun-2026 | End --//
		// headerFieldConfig.add(blankSpaceConfig);
		List<Map<String,Object>> treatmentFieldConfig = new List<Map<String,Object>>(headerFieldConfig);
		blockConfig.put('name', 'Treatment Details');
		blockConfig.put('title', 'Treatment Details');
		blockConfig.put('fields', treatmentFieldConfig);
		Map<String,Object> blockTpConfig = new Map<String,Object>(blockConfig);
		block.add(blockTpConfig);	
		headerFieldConfig = new List<Map<String,Object>>();
		headerFieldConfig.add(accountConfig);
		headerFieldConfig.add(creditUtilizationConfig);
		headerFieldConfig.add(creditRemainingConfig);
		headerFieldConfig.add(totalARConfig);
		headerFieldConfig.add(totalPastDueConfig);
		headerFieldConfig.add(totalDisputedConfig);
		headerFieldConfig.add(currentConfig);
		headerFieldConfig.add(age1Config);
		headerFieldConfig.add(age2Config);
		headerFieldConfig.add(age3Config);
		headerFieldConfig.add(age4Config);
		headerFieldConfig.add(age5Config);
		blockConfig.put('name', 'Account Details');
		blockConfig.put('title', 'Account Details');
		blockConfig.put('fields', headerFieldConfig);
		Map<String,Object> blockADConfig = new Map<String,Object>(blockConfig);
		block.add(blockADConfig);
		Map<String,Object> defaultGridConfig = new Map<String,Object>();
		defaultGridConfig.put('name', '');
		defaultGridConfig.put('title', '');
		defaultGridConfig.put('type', 'datagrid');
		defaultGridConfig.put('isActive', true);
		defaultGridConfig.put('hideTitle', true);
		defaultGridConfig.put('dataSource', '');
		defaultGridConfig.put('dataSourceName', '');
		defaultGridConfig.put('hide', false);
		defaultGridConfig.put('hideCriteria', null);
		defaultGridConfig.put('desktopWidth', 12);
		defaultGridConfig.put('tabletWidth', 12);
		defaultGridConfig.put('mobileWidth', 12);
		defaultGridConfig.put('cellcolor', new List<String>());
		defaultGridConfig.put('columns', new List<String>());
		defaultGridConfig.put('rowcolor', new List<String>());
		defaultGridConfig.put('keyfield', '');
		defaultGridConfig.put('disablepagination', false);
		defaultGridConfig.put('rowSize', 10);
		defaultGridConfig.put('hideCheckbox', false);
		defaultGridConfig.put('showRowNumber', false);
		defaultGridConfig.put('sortedBy', '');
		defaultGridConfig.put('defaultSortDirection', 'desc');
		defaultGridConfig.put('enableInfiniteLoading', true);
		defaultGridConfig.put('loadMoreOffset', 1);
		defaultGridConfig.put('isLoading', true);
		defaultGridConfig.put('maxRowSelection', 100);
		defaultGridConfig.put('multiSelect', true);
		defaultGridConfig.put('orderBy', '');
		defaultGridConfig.put('isSearchable', false);
		//-- Starts | FIN-8209 | Changed By Dilshad | 13-Aug-2025 --//
		defaultGridConfig.put('exportExcel', true);
		//-- Ends | FIN-8209 | Changed By Dilshad | 13-Aug-2025 --//
		defaultGridConfig.put('enableAdvanceSearch', false);
		defaultGridConfig.put('onchange', 'onSelectRow');
		defaultGridConfig.put('helpText', '');

		if(!listOfStep.isEmpty()){
			for(String stepName : listOfStep){
					defaultGridConfig.put('name', stepName);
					defaultGridConfig.put('title', stepName);
					// defaultButtonConfig.put('name', stepName + '-button');
					blockConfig.put('name', stepName + 'block');
					blockConfig.put('title', stepName);
					blockConfig.put('hide', true);
					blockConfig.put('hideCriteria', JSON.deserializeUntyped('{ "rules": [{ "condition": "==", "criteriagroup": null, "field": { "type": "text", "ReferenceTo": "", "picklistVal": "", "label": "' + stepName + 'blockShow", "name": "'+ stepName + 'blockShow", "value": "false" } }], "operator": "&&" }'));
					Map<String,Object> gridConfig = new Map<String,Object>(defaultGridConfig);
					// Map<String,Object> buttonConfig = new Map<String,Object>(defaultButtonConfig);
					List<Map<String,Object>> fieldConfig = new List<Map<String,Object>>();
					// fieldConfig.add(buttonConfig);
					fieldConfig.add(gridConfig);
					blockConfig.put('fields', fieldConfig);
					Map<String,Object> blockTempConfig = new Map<String,Object>(blockConfig);
					block.add(blockTempConfig);	
			}
		}
		sectionConfig.put('name', '');
		sectionConfig.put('title', '');
		sectionConfig.put('isActive', true);
		sectionConfig.put('hideTitle', true);
		sectionConfig.put('hide', false);
		sectionConfig.put('hideCriteria', null);
		sectionConfig.put('desktopWidth', 12);
		sectionConfig.put('tabletWidth', 12);
		sectionConfig.put('mobileWidth', 12);
		sectionConfig.put('blocks', block);
		sectionConfig.put('dataServices', new List<String>());
		sectionConfig.put('theme', new Map<String,String>());
		System.debug('sectionConfig.>> ' + sectionConfig);
		section.add(sectionConfig);
		
		List<Map<String,Object>> actionList = new List<Map<String,Object>>();
		Map<String,Object> tempAction = new Map<String,Object>();
		// if (listTask.get(0).Status != 'Completed'){
			tempAction.put('name', 'Edit');
			tempAction.put('title', 'Edit');
			tempAction.put('dataSource', 'newScreen');
			tempAction.put('dataSourceName', 'EditTaskForTreatmentRule');
			tempAction.put('iconName', 'utility:edit');
			tempAction.put('screenSize', 'small-width');
			tempAction.put('targetScreenAlignemnt', 'center-screen');
			tempAction.put('active', true);
			tempAction.put('activeCriteria', JSON.deserializeUntyped('{"rules":[{"condition":"==","criteriagroup":null,"field":{"type":"text","ReferenceTo":"","picklistVal":"","label":"showAction","name":"showAction","value":"true"}}],"operator":"&&"})'));
			tempAction.put('selectIcon', false);
			tempAction.put('iconClassMap', false);
			tempAction.put('label', '');

			Map<String,Object> sendEditAction = new Map<String,Object>(tempAction);
			actionList.add(sendEditAction);
		// }
		String taskType = '';
		String template = null;
		List<EmailTemplate> billingTemplateList = new List<EmailTemplate>();
		ID parentId = listTask.get(0).WhatId;
		String customLogicClass = '';
		Boolean isattachment = false;
		//-- Starts | FIN-6948 | Changed by Ravi | 2 JAN 2025 --//
		String attachmentFormat = '';
		//-- Ends | FIN-6948 | Changed by Ravi | 2 JAN 2025 --//
		//-- Starts | FIN-8209 | Changed By Dilshad | 13-Aug-2025 --//
		String attachmentName = '';
		//-- End | FIN-8209 | Changed By Dilshad | 13-Aug-2025 --//
		//-- Start | FIN-9041 | Chanegs by Asera 02-Feb-2026--//
		String attachmentTemplateFolder = '';
		String attachmentTemplate = 'System_BillingStatementPDF';
		String attachmentTemplateFolderRefField = '';
		//-- End | FIN-9041 | Chanegs by Asera 02-Feb-2026--//
		if(treatment.celsrm__Seperate_Task_For_Step__c && treatment.celsrm__Treatment_Steps__c != null){
			// List<ObjectCriteria> listOfTreatmentStep = (List<ObjectCriteria>)JSON.deserialize(treatment.celsrm__Treatment_Steps__c, List<ObjectCriteria>.class);
			for(ObjectCriteria treatmentStep : listOfTreatmentStep) {
				if (listTask.get(0).Subject == treatmentStep.taskSubject && listTask.get(0).celsrm__Treatment_Stage__c == treatmentStep.stepName) {
					template = treatmentStep.template;
					taskType = treatmentStep.taskType != null ? treatmentStep.taskType.toString() : '';
					customLogicClass = treatmentStep.customLogicClass;
					isattachment = treatmentStep.attachment;
					//-- Starts | FIN-6948 | Changed by Ravi | 2 JAN 2025 --//
					attachmentFormat = treatmentStep.attachmentFormat;
					//-- Ends | FIN-6948 | Changed by Ravi | 2 JAN 2025 --//
					//-- Starts | FIN-8209| Changed By Dilshad | 13-Aug-2025 --//
					attachmentName = treatmentStep.attachmentName;
					//-- End | FIN-8209 | Changed By Dilshad | 13-Aug-2025 --//
					//-- Start | FIN-9041 | Chanegs by Asera 02-Feb-2026--//
					attachmentTemplateFolder = treatmentStep.attachmentTemplateFolder;
					attachmentTemplate = treatmentStep.attachmentTemplate;
					attachmentTemplateFolderRefField = treatmentStep.attachmentTemplateFolderReferenceField;
					//-- End | FIN-9041 | Chanegs by Asera 02-Feb-2026--//
					if(treatmentStep.enableDynamicTemplate != null && (Boolean)treatmentStep.enableDynamicTemplate){
						String templatePrefix = treatmentStep.emailTemplatePrefix;
						if (treatmentStep.templateFolderReferenceField != null && treatmentStep.templateFolderReferenceField != '' && templatePrefix != null && templatePrefix !='') {
							String query = 'SELECT ' +  treatmentStep.templateFolderReferenceField + ' FROM Account WHERE Id=:parentId';
							List<Account> accList = Database.query(query);
							if (!accList.isEmpty() && accList.size() > 0) {
								templatePrefix = templatePrefix + '%';
								String folderName = string.valueOf(accList.get(0).get(treatmentStep.templateFolderReferenceField));
								if (folderName != null && folderName != '') {
									billingTemplateList = [SELECT id FROM EmailTemplate WHERE Folder.Name = :folderName AND Name LIKE :templatePrefix AND IsActive = TRUE];
								}
								if (!billingTemplateList.isEmpty() && billingTemplateList.size() > 0) {
									template = billingTemplateList.get(0).Id;
								}
							}
						}
					}
					break;
				}
			}
		} else if(!treatment.celsrm__Seperate_Task_For_Step__c) {
			template = treatment.celsrm__Email_Template__c;
			taskType = treatment.celsrm__Task_Type__c;
			customLogicClass = treatment.celsrm__Custom_Logic_Class__c;
			isattachment = treatment.celsrm__Attachment__c;
			//-- Starts | FIN-6948 | Changed by Ravi | 2 Jan 2025 --//
			attachmentFormat = treatment.celsrm__Attachment_Format__c;
			//-- Ends | FIN-6948 | Changed by Ravi | 2 Jan 2025 --//
			//-- Start | FIN-8209 | Changed By Dilshad | 13-Aug-2025 --//
			attachmentName = treatment.celsrm__Attachment_Name__c;
			//-- End | FIN-8209 | Changed By Dilshad | 13-Aug-2025 --//
			//-- Start | FIN-9041 | Chanegs by Asera 02-Feb-2026--//
			attachmentTemplateFolder = treatment.celsrm__Attachment_Template_Folder__c;
			attachmentTemplate = treatment.celsrm__Attachment_Template_Name__c;
			attachmentTemplateFolderRefField = treatment.celsrm__Attachment_Template_Folder_Ref_Field__c;
			//-- End | FIN-9041 | Chanegs by Asera 02-Feb-2026--//
			if(treatment.celsrm__Enable_Dynamic_Template__c){
				String templatePrefix = treatment.celsrm__Email_Template_Prefix__c != null ? (String)treatment.celsrm__Email_Template_Prefix__c : '';
				if (treatment.celsrm__Template_Folder_Reference_Field__c != null && treatment.celsrm__Template_Folder_Reference_Field__c != '' && templatePrefix != null && templatePrefix !='') {
					String query = 'SELECT ' +  treatment.celsrm__Template_Folder_Reference_Field__c + ' FROM Account WHERE Id=:parentId';
					List<Account> accList = Database.query(query);
					if (!accList.isEmpty() && accList.size() > 0) {
						templatePrefix = templatePrefix + '%';
						String folderName = string.valueOf(accList.get(0).get(treatment.celsrm__Template_Folder_Reference_Field__c));
						if (folderName != null && folderName != '') {
							billingTemplateList = [SELECT id FROM EmailTemplate WHERE Folder.Name = :folderName AND Name LIKE :templatePrefix AND IsActive = TRUE];
						}
						if (!billingTemplateList.isEmpty() && billingTemplateList.size() > 0) {
							template = billingTemplateList.get(0).Id;
						}
					}
				}
			}
		}
		// if((treatment.celsrm__Seperate_Task_For_Step__c || treatment.celsrm__Consolidated_Treatment__c) && treatment.celsrm__Treatment_Steps__c != null) {
		// 	List<ObjectCriteria> aCriterias = (List<ObjectCriteria>)JSON.deserialize(treatment.celsrm__Treatment_Steps__c, List<ObjectCriteria>.class);
		// 	if(aCriterias != null && aCriterias.size() > 0) {
		// 		for(ObjectCriteria aCriteria : aCriterias) {
		// 			if (listTask.get(0).Subject == aCriteria.taskSubject && listTask.get(0).celsrm__Treatment_Stage__c == aCriteria.stepName) {
		// 				template = aCriteria.template;
		// 				if(treatment.celsrm__Enable_Dynamic_Template__c){
		// 					String templatePrefix = aCriteria.emailTemplatePrefix;
		// 					if (treatment.celsrm__Template_Folder_Reference_Field__c != null && treatment.celsrm__Template_Folder_Reference_Field__c != '' && templatePrefix != null && templatePrefix !='') {
		// 						String query = 'SELECT ' +  treatment.celsrm__Template_Folder_Reference_Field__c + ' FROM Account WHERE Id=:parentId';
		// 						List<Account> accList = Database.query(query);
		// 						if (!accList.isEmpty() && accList.size() > 0) {
		// 							templatePrefix = templatePrefix + '%';
		// 							String folderName = (String)accList.get(0).get(treatment.celsrm__Template_Folder_Reference_Field__c);
		// 							if (folderName != null && folderName != '') {
		// 								billingTemplateList = [SELECT id FROM EmailTemplate WHERE Folder.Name = :folderName AND Name LIKE :templatePrefix AND IsActive = TRUE];
		// 							}
		// 							if (!billingTemplateList.isEmpty() && billingTemplateList.size() > 0) {
		// 								template = billingTemplateList.get(0).Id;
		// 							}
		// 						}
		// 					}
		// 				}
		// 				break;
		// 			}
		// 		}
		// 	}
		// } else if (!treatment.celsrm__Consolidated_Treatment__c && treatment.celsrm__Email_Template__c != null) {
		// 	system.debug('treatment.celsrm__Email_Template__c>>> ' + treatment.celsrm__Email_Template__c);
		// 	template = treatment.celsrm__Email_Template__c;
		// 	if(treatment.celsrm__Enable_Dynamic_Template__c){
		// 		String templatePrefix = treatment.celsrm__Email_Template_Prefix__c;
		// 		if (treatment.celsrm__Template_Folder_Reference_Field__c != null && treatment.celsrm__Template_Folder_Reference_Field__c != '' && templatePrefix != null && templatePrefix !='') {
		// 			String query = 'SELECT ' +  treatment.celsrm__Template_Folder_Reference_Field__c + ' FROM Account WHERE Id=:parentId';
		// 			List<Account> accList = Database.query(query);
		// 			if (!accList.isEmpty() && accList.size() > 0) {
		// 				templatePrefix = templatePrefix + '%';
		// 				String folderName = (String)accList.get(0).get(treatment.celsrm__Template_Folder_Reference_Field__c);
		// 				if (folderName != null && folderName != '') {
		// 					billingTemplateList = [SELECT id FROM EmailTemplate WHERE Folder.Name = :folderName AND Name LIKE :templatePrefix AND IsActive = TRUE];
		// 				}
		// 				if (!billingTemplateList.isEmpty() && billingTemplateList.size() > 0) {
		// 					template = billingTemplateList.get(0).Id;
		// 				}
		// 			}
		// 		}
		// 	}
		// }
		if (listTask.get(0).Status != 'Completed' && taskType.containsIgnoreCase('Email')) {
			tempAction.put('name', 'SendEmail');
			tempAction.put('title', 'Send Email');
			tempAction.put('dataSource', 'staticResourceFunctionName');
			tempAction.put('dataSourceName', 'openSendEMailScreen');
			tempAction.put('iconName', 'utility:email');
			tempAction.put('screenSize', 'large-width');
			tempAction.put('active', true);
			tempAction.put('activeCriteria', JSON.deserializeUntyped('{"rules":[{"condition":"==","criteriagroup":null,"field":{"type":"text","ReferenceTo":"","picklistVal":"","label":"showAction","name":"showAction","value":"true"}}],"operator":"&&"})'));
			tempAction.put('selectIcon', false);
			tempAction.put('iconClassMap', false);
			tempAction.put('label', '');

			Map<String,Object> sendEmailAction = new Map<String,Object>(tempAction);
			actionList.add(sendEmailAction);
		}
		if (listTask.get(0).Status != 'Completed' && taskType.containsIgnoreCase('Call')) {
			tempAction.put('name', 'logaCall');
			tempAction.put('title', 'Make A Call');
			tempAction.put('dataSource', 'staticResourceFunctionName');
			tempAction.put('dataSourceName', 'openMakeACallScreen');
			tempAction.put('iconName', 'utility:log_a_call');
			tempAction.put('screenSize', 'large-width');
			tempAction.put('active', true);
			tempAction.put('activeCriteria', JSON.deserializeUntyped('{"rules":[{"condition":"==","criteriagroup":null,"field":{"type":"text","ReferenceTo":"","picklistVal":"","label":"showAction","name":"showAction","value":"true"}}],"operator":"&&"})'));
			tempAction.put('selectIcon', false);
			tempAction.put('iconClassMap', false);
			tempAction.put('label', '');
			Map<String,Object> logACallAction = new Map<String,Object>(tempAction);
			actionList.add(logACallAction);
		}
		Map<String,Object> isAttachmentMap = new Map<String,Object>();
		isAttachmentMap.put('name', 'isAttachment');
		isAttachmentMap.put('value', String.valueOf(isattachment));
		//-- Starts | FIN-6948 | Changed by Ravi | 2 Jan 2025 --//
		Map<String,Object> attachmentFormatMap = new Map<String,Object>();
		attachmentFormatMap.put('name', 'attachmentFormat');
		attachmentFormatMap.put('value', String.valueOf(attachmentFormat));
		//-- Ends | FIN-6948 | Changed by Ravi | 2 Jan 2025 --//
		//-- Start | FIN-8209 | Changed By Dilshad | 13-Aug-2025 --//
		Map<String,Object> attachmentNameMap = new Map<String,Object>();
		attachmentNameMap.put('name', 'attachmentName');
		attachmentNameMap.put('value', String.valueOf(attachmentName));
		//-- End | FIN-8209 | Changed By Dilshad | 13-Aug-2025 --//
		Map<String,Object> variableMap = new Map<String,Object>();
		//-- Starts | FIN-6579 | Changed by Asera | 24 Oct 2024 --//
		Map<String,Object> emailTemplateMap = new Map<String,Object>();
		emailTemplateMap.put('name', 'emailTemplate');
		emailTemplateMap.put('value', template);
		//-- Ends | FIN-6579 | Changed by Asera | 24 Oct 2024 --//
		Map<String,Object> objectMap = new Map<String,Object>();
		objectMap.put('name', 'objectName');
		objectMap.put('value', treatment.celsrm__Related_Object__c);
		Map<String,Object> stageMap = new Map<String,Object>();
		stageMap.put('name', 'treatmentStage');
		stageMap.put('value', listTask.get(0).celsrm__Treatment_Stage__c);
		Map<String,Object> seperateTaskForStepMap = new Map<String,Object>();
		seperateTaskForStepMap.put('name', 'seperateTaskForStep');
		seperateTaskForStepMap.put('value', String.valueOf(treatment.celsrm__Seperate_Task_For_Step__c));
		//Map<String,Object> isConsolidatedMap = new Map<String,Object>();
		//isConsolidatedMap.put('name', 'isConsolidated');
		//isConsolidatedMap.put('value', treatment.celsrm__Consolidated_Treatment__c);
		Map<String,Object> treatmentNameMap = new Map<String,Object>();
		treatmentNameMap.put('name', 'treatmentName');
		treatmentNameMap.put('value', treatment.Name);

		//-- Starts | FIN-6130 | Changed by Asera | 29 Aug 2024 --//
		variableMap.put('name', 'showAction');
		variableMap.put('value', 'false');
		//-- End | FIN-6130 | Changed by Asera | 29 Aug 2024 --//
		//-- Start | FIN-9041 | Chanegs by Asera 02-Feb-2026--//
		Map<String,Object> attachmentTemplateMap = new Map<String,Object>();
		attachmentTemplateMap.put('name', 'attachmentTemplate');
		attachmentTemplateMap.put('value', String.valueOf(attachmentTemplate));
		Map<String,Object> attachmentTemplateFolderMap = new Map<String,Object>();
		attachmentTemplateFolderMap.put('name', '	');
		attachmentTemplateFolderMap.put('value', String.valueOf(attachmentTemplateFolder));
		Map<String,Object> attachmentTemplateFolderRefFieldMap = new Map<String,Object>();
		attachmentTemplateFolderRefFieldMap.put('name', 'attachmentTemplateFolderRefField');
		attachmentTemplateFolderRefFieldMap.put('value', String.valueOf(attachmentTemplateFolderRefField));
		//-- End | FIN-9041 | Chanegs by Asera 02-Feb-2026--//
		List<Map<String,Object>> variables = new List<Map<String,Object>>();
		variables.add(isAttachmentMap);
		//-- Starts | FIN-6948 | Changed by Ravi | 2 Jan 2025 --//
		variables.add(attachmentFormatMap);
		//-- Ends | FIN-6948 | Changed by Ravi | 2 Jan 2025 --//
		//-- Start | FIN-8209 | Changed By Dilshad | 13-Aug-2025 --//
		variables.add(attachmentNameMap);
		//-- End | FIN-8209 | Changed By Dilshad | 13-Aug-2025 --//
		variables.add(variableMap);
		variables.add(objectMap);
		variables.add(treatmentNameMap);
		variables.add(stageMap);
		variables.add(seperateTaskForStepMap);
		//-- Starts | FIN-6579 | Changed by Asera | 24 Oct 2024 --//
		variables.add(emailTemplateMap);
		//-- Ends | FIN-6579 | Changed by Asera | 24 Oct 2024 --//
		//-- Start | FIN-9041 | Chanegs by Asera 02-Feb-2026--//
		variables.add(attachmentTemplateMap);
		variables.add(attachmentTemplateFolderMap);
		variables.add(attachmentTemplateFolderRefFieldMap);
		//-- End | FIN-9041 | Chanegs by Asera 02-Feb-2026--//
		//variables.add(isConsolidatedMap);

		config.put('name', listTask.get(0).Subject);
		config.put('title', listTask.get(0).Subject);
		config.put('type', 'screen');
		config.put('titleValue', '{value.accountName}');
		config.put('hideTitle', false);
		config.put('titleIcon', 'standard:task');
		config.put('isWizard', false);
		config.put('showSaveAndNext', false);
		config.put('isActive', true);
		config.put('staticResource', 'TaskDetail');
		config.put('saveRedirection', new Map<String,String>());
		config.put('cancelRedirection', new Map<String,String>());
		config.put('submitProperties', new Map<String,String>());
		config.put('actions', actionList);
		config.put('dataServices', new List<String>());
		config.put('submitDataServices', new List<String>());
		config.put('submitDataServicesOperation', '');
		config.put('variables', variables);
		config.put('sections', section);
		config.put('searchscreen', new List<String>());
		config.put('messages', new List<String>());
		config.put('successMessage', '');
		config.put('isSObject', false);
		config.put('sObject', '');
		config.put('sObjectMode', '');
		config.put('showEditButton', false);
		config.put('profile', '');
		config.put('onLoadFunction', 'onPageLoadSetView');
		config.put('theme', new Map<String,String>());
		config.put('enableSubmitButton', true);
		System.debug('config.>> ' + config);
		return config;
	}

	@AuraEnabled
	public static Map<Object,Object> returnGridData(Map<Object,Object> inMap){
		String taskID = (String)inMap.get('Id');
		// String stepsData = readTreatmentDetailsFile(taskID);
		// Map<String, Object> mapStepsData =  (Map<String, Object> ) JSON.deserializeUntyped(stepsData);
		String childObjAPIName = '';
		//-- Starts | FIN-6885 | Changed by Sejal | 24 JAN 2025 --//
		//-- FIN-8540 | Changed by Ravi | 15-Jun-2026 | Start --//
		List<Task> listTask = [select id,Subject,OwnerId,Owner.Name,WhatId,What.Name,Priority,ActivityDate,celsrm__Treatment__c,Status, AccountId, AiDunning__c from task where id =: taskID];
		
		// AI Dunning Task - Simplified Grid Data 
		System.debug('listTaskData: ' + listTask);
		inMap.put('isAiDunning', listTask.get(0).AiDunning__c);
		//-- FIN-8540 | Changed by Ravi | 15-Jun-2026 | End --//
		if(!listTask.isEmpty()){
			//-- FIN-8540 | Changed by Ravi | 15-Jun-2026 | Start | Method move from below to up --//
			//-- Starts | FIN-6130 | Changed by Asera | 29 Aug 2024 --//
			Id taskOwnerId = listTask.get(0).OwnerId;
			Id loggedInUserId = UserInfo.getUserId();
			// Check if the OwnerId is the logged-in user
			if (taskOwnerId == loggedInUserId) {
				inMap.put('showAction', 'true');
			} else {
				try {
					// Check if the OwnerId is a queue
					Group taskOwnerGroup = [SELECT Id FROM Group WHERE Id = :taskOwnerId LIMIT 1];
					if (taskOwnerGroup != null) {
						// Query to find all the queues the logged-in user belongs to, including sub-queues
						List<GroupMember> userGroups = [
							SELECT GroupId 
							FROM GroupMember 
							WHERE UserOrGroupId = :loggedInUserId
						];
						// Check if the logged-in user belongs to the task's queue or any of its sub-queues
						for (GroupMember gm : userGroups) {
							if (gm.GroupId == taskOwnerId) {
									inMap.put('showAction', 'true');
									break;
							}
						}
					}
				} catch (QueryException e) {
					// Handle the case where the taskOwnerId is not a queue ID (e.g., another user ID)
					inMap.put('showAction', 'false');
				}
				
			}

			if( listTask.get(0).AiDunning__c == true) {
				return getAiDunningGridData(listTask.get(0), inMap);
			}
			//-- FIN-8540 | Changed by Ravi | 15-Jun-2026 | End --//

			ID treatmentId = listTask.get(0).celsrm__Treatment__c;
			String accountId = listTask.get(0).AccountId;
			//-- Starts | FIN-9225 | Changed by Dhwanil | 23 Feb 2026 --//
			String taskStatus = listTask.get(0).Status;
			//-- End | FIN-9225 | Changed by Dhwanil | 23 Feb 2026 --//
			//-- Start | FIN-8209 | Changed By Dilshad | celsrm__Consolidated_Treatment__c has been added in query | 13-Aug-2025 --//
			List<celsrm__Treatment__c> listTreatment = [SELECT Id,celsrm__Related_Object__c,celsrm__Treatment_Steps__c,celsrm__Org_Id__c, celsrm__Consolidated_Treatment__c FROM celsrm__Treatment__c WHERE Id =:treatmentId ];
			//-- End | FIN-8209 | Changed By Dilshad | 13-Aug-2025 --//
			//-- Starts | FIN-7945 | Changed by Ravi | 10 sep 2025 --//
			Boolean isMultiCurrencyEnabled = UserInfo.isMultiCurrencyOrganization();
			//-- Ends | FIN-7945 | Changed by Ravi | 10 sep 2025 --//
			if(!listTreatment.isEmpty()){
				childObjAPIName = listTreatment.get(0).celsrm__Related_Object__c;
				//-- Starts | FIN-8280| Changed by Asera | 17 April 2026 --//
				String accountLocale = 'EN';
				try {
					Account acc = [SELECT Id, celsrm__Locale__c FROM Account WHERE Id = :accountId];
					accountLocale = acc.celsrm__Locale__c;
				} catch (Exception e) {
						System.debug('Error fetching Account: ' + e.getMessage());
				}
				Map<String, String> fieldApiVsTranslatedLabel = celsrm.SRMUtilityController.getTranslatedLabelMapForObject(accountLocale, childObjAPIName); //FIN-8208| Changed by Asera | 17 April 2026 --// - Dynamic translated headers based account local
				//-- End | FIN-8280| Changed by Asera | 17 April 2026 --//
				//-- Start | FIN-8029 | Changed By Dilshad | 13-Aug-2025 --//
				inMap.put('isConsolidated', Boolean.valueOf(String.valueOf(listTreatment.get(0).celsrm__Consolidated_Treatment__c)));
				//-- End | FIN-8029 | Changed By Dilshad | 13-Aug-2025 --//
				// Map<String, Set<Id>> mapStepsData = new Map<String, Set<Id>>();
				// Map<String, Object> mapStepsDataObj = new Map<String, Object>();
				// // if (listTask.get(0).Status == 'Completed') {
				// 	String stepsData = celsrm.SRMTreatmentUtility.readTreatmentDetailsFile(taskID, 'Treatment Details');
				// 	if (stepsData != '') {
				// 		mapStepsDataObj =  (map < string, object > ) JSON.deserializeUntyped(stepsData);
				// 		for(String mapStepsDataKey : mapStepsDataObj.keySet()){
				// 			Set<Id> childId = new Set<Id>();
				// 			for (Object ids : (List<Object>) mapStepsDataObj.get(mapStepsDataKey)) {
				// 				childId.add((Id)ids);
				// 			}
				// 			mapStepsData.put(mapStepsDataKey, childId);
				// 		}
				// 	}		
				// } else {
				// 	mapStepsData = getReletedObjectIds(listTreatment.get(0),listTask.get(0).WhatId);
				// }
				// Map<String, Set<Id>> mapStepsData = getReletedObjectIds(listTreatment.get(0),listTask.get(0).WhatId);
		//-- Ends | FIN-6885 | Changed by Sejal | 24 JAN 2025 --//	
				List<ObjectCriteria> listOfTreatmentStep =  (List<ObjectCriteria> ) JSON.deserialize(listTreatment.get(0).celsrm__Treatment_Steps__c, List<ObjectCriteria>.class);
				List<String> listOfStep = new List<String>();
				List<Id> excludedIds = new List<Id>();		
				//-- Starts | FIN-8209 | Changed By Dilshad/Asera | 13-Aug-2025 --//
				Map<String, Object> mapStepsDataObj = new Map<String, Object>();
				List<String> listOfStepInFile = new List<String>();
				String stepsData = celsrm.SRMTreatmentUtility.readTreatmentDetailsFile(taskID,'Treatment Details');
				if (stepsData != '') {
					mapStepsDataObj =  (map < string, object > ) JSON.deserializeUntyped(stepsData);
					// Convert the Set of keys into a List before assigning
					listOfStepInFile = new List<String>(mapStepsDataObj.keySet()); 
				}
				//-- End | FIN-8209 | Changed By Dilshad/Asera | 13-Aug-2025 --//
				for (ObjectCriteria treStep: listOfTreatmentStep) {
					//-- Starts | FIN-6885 | Changed by Sejal | 24 JAN 2025 --//
					// if (mapStepsData.containsKey(treStep.stepName) && treStep.description != null) {
					// 	inMap.put(treStep.stepName + 'description', treStep.description);
					// }
					// if(mapStepsData.containsKey(treStep.stepName)){
					// 	inMap.put(treStep.stepName + 'showTotal', treStep.showTotal);
					// 	inMap.put(treStep.stepName + 'aggregationField', treStep.aggregationField);
					// 	inMap.put(treStep.stepName + 'totalTitle', treStep.totalTitle);
					// }
					// if(mapStepsData.containsKey(treStep.stepName)){
					if(treStep.active && listOfStepInFile.contains(treStep.stepName)){ //-- Added condtion | FIN-8209 | Changed By Dilshad/Asera | 13-Aug-2025 --//
						if (treStep.description != null) {
							inMap.put(treStep.stepName + 'description', treStep.description);
						}
						inMap.put(treStep.stepName + 'showTotal', treStep.showTotal);
						inMap.put(treStep.stepName + 'aggregationField', treStep.aggregationField);
						inMap.put(treStep.stepName + 'totalTitle', treStep.totalTitle);
						//-- Ends | FIN-6885 | Changed by Sejal | 24 JAN 2025 --//	
						listOfStep.add(treStep.stepName);
						List<String> objColumns = treStep.columns;
						List<String> columns = new List<String>();
						
						// List<Object> objChildIds = (List<Object>) mapStepsData.get(String.valueOf(treStep.get('stepName')));
						// List<String> childIds = new List<String>();
						// if (objChildIds != null && objChildIds.size() > 0) {
						// 	for(Object a: objChildIds){
						// 		childIds.add(String.valueOf(a));
						// 	}
						// }
						// Set<Id> childIds = mapStepsData.get(treStep.stepName);
						String query = '';
						Map<string, Schema.sObjectType> describeInfo = Schema.getGlobalDescribe();
                    	Map<String, Schema.SObjectField> fMap = describeInfo.get(childObjAPIName.toLowerCase()).getDescribe().Fields.getMap();
						//-- Starts | FIN-6885 | Changed by Sejal | 6 JAN 2025 --//
						List<celsrm.SRMTreatmentMapper.Criteria> criteriaList = new List<celsrm.SRMTreatmentMapper.Criteria>();
						for(Criteria c: treStep.criteria){
							celsrm.SRMTreatmentMapper.Criteria criteriaSet = new celsrm.SRMTreatmentMapper.Criteria();
							criteriaSet.field = c.field;
							criteriaSet.operator = c.operator;
							criteriaSet.value = c.value;
							criteriaList.add(criteriaSet);
						}
						String whereClause = celsrm.SRMTreatmentUtility.getQueryWhereClause(criteriaList, treStep.criteriaCondition, childObjAPIName, null);
						System.debug('whereClause>>>>>>>>>>'+whereClause);
						//-- Starts | FIN-9225 | Changed by Dhwanil | 23 Feb 2026 --//
                        List<String> transactionIdList = new List<String>();
                        List<Object> dataList = (List<Object>) mapStepsDataObj.get(treStep.stepName);
                        for (Object item : dataList) {
                            transactionIdList.add((String) item);
                        }
                        //-- Ends | FIN-9225 | Changed by Dhwanil | 23 Feb 2026 --//

						//-- Ends | FIN-6885 | Changed by Sejal | 6 JAN 2025 --//
						if (objColumns != null && objColumns.size() > 0) {
							
							for (String a : objColumns){
								columns.add(a);
								String st = a;
								if(fMap.get(st.trim().toLowerCase()).getDescribe().isCustom() && fMap.get(st.trim().toLowerCase()).getDescribe().getType() == Schema.DisplayType.REFERENCE){
									st= st.subString(0,st.length()-1)+ 'r.Name';
									columns.add(st);
								} else if (!fMap.get(st.trim().toLowerCase()).getDescribe().isCustom() && fMap.get(st.trim().toLowerCase()).getDescribe().getType() == Schema.DisplayType.REFERENCE) {
									st= st.subString(0,st.length()-2)+ '.Name';
									columns.add(st);
								}
							}
							//-- Start | FIN-8209 | Changed By Dilshad | 13-Aug-2025 --//
							//-- Adding currency field if not present in columns --//
							//-- Starts | FIN-7945 | Changed by Ravi | 10 Sep 2025 --//
							isMultiCurrencyEnabled = Schema.sObjectType.Account.fields.getMap().containsKey('CurrencyIsoCode');
							if(isMultiCurrencyEnabled && !columns.contains('CurrencyIsoCode')) {
								columns.add('CurrencyIsoCode');
							}
							//-- Ends | FIN-7945 | Changed by Ravi | 10 Sep 2025 --//
							//-- End | FIN-8209 | Changed By Dilshad | 13-Aug-2025 --//
							String field = String.Join(columns,',');
							//-- Starts | FIN-6885 | Changed by Sejal | 6 JAN 2025 --//
							// if (columns.contains('Id')) {
							// 	query = 'SELECT ' + field + ' FROM ' + childObjAPIName + ' WHERE ID =:childIds';
							// } else {
							// 	query = 'SELECT Id,' + field + ' FROM ' + childObjAPIName + ' WHERE ID =:childIds';
							// }
							if (columns.contains('Id')) {
								query = 'SELECT ' + field + ' FROM ' + childObjAPIName;
							} else {
								query = 'SELECT Id,' + field + ' FROM ' + childObjAPIName;
							}
						} else {
							query = 'SELECT Id,Name FROM ' + childObjAPIName ;
						}

						//-- Starts | FIN-9225 | Changed by Dhwanil | 23 Feb 2026 --//
						if(whereClause != '' && taskStatus != 'Completed') { 
							query += ' WHERE ' + ' ( ( ' + whereClause + ' )  AND (ID NOT IN :excludedIds) AND celsrm__Account__c=:accountId)';
						} 
						else if(whereClause != '' && taskStatus == 'Completed') {
							query += ' WHERE ID IN :transactionIdList';
						}
						//-- Ends | FIN-9225 | Changed by Dhwanil | 23 Feb 2026 --//
						// else if (!childIds.isEmpty()) {
						// 	query += ' WHERE ID =:childIds';
						// }

						// << START - MM - FIN-9497 - Task -> Send Email -> PIP subtotal calculation >> 
						String sortField = treStep.sortField;
						String sortDirection = treStep.sortDirection != null ? treStep.sortDirection : 'ASC';
						if(sortField != null && sortField != ''){
							query += ' ORDER BY ' + sortField + ' ' + sortDirection;
						}
						// << END - MM - FIN-9497 - Task -> Send Email -> PIP subtotal calculation >> 
						System.debug('query>>>>>'+ query);
						//-- Ends | FIN-6885 | Changed by Sejal | 6 JAN 2025 --//
						List<SObject> childObjRecord = Database.query(query);
						Map<String,String> m_Type = new Map<String,String>();
						m_Type.put('ID','id');
						m_Type.put('STRING','text');
						m_Type.put('TEXTAREA','html');
						m_Type.put('NUMBER','number');
						m_Type.put('CURRENCY','currency');
						m_Type.put('DOUBLE','number');
						m_Type.put('PERCENT','percent');
						m_Type.put('PICKLIST','text');
						m_Type.put('BOOLEAN','boolean');
						m_Type.put('EMAIL','email');
						m_Type.put('PHONE','phone');
						m_Type.put('DATE','date');
						m_Type.put('DATETIME','datetime');
						//-- Starts | FIN-8506 | Changed by Ravi | 5 Nov 2025 --//
						m_Type.put('REFERENCE','lookup');
						//-- Ends | FIN-8506 | Changed by Ravi | 5 Nov 2025 --//

						list<Map<String,Object>> listofField = new list<Map<String,Object>>();
						List<String> refField = new List<String>();
						if (objColumns != null && objColumns.size() > 0) {
							for(Object fie : objColumns){
								String field = String.valueOf(fie);
								if (!field.equalsIgnoreCase('ID')) {
									Map<String,Object> m_key_value = new Map<String,Object>();
									//-- Starts | FIN-8280| Changed by Asera | 17 April 2026 --//
										String key = field.trim().toLowerCase();
									if (fieldApiVsTranslatedLabel != null && !fieldApiVsTranslatedLabel.isEmpty() && fieldApiVsTranslatedLabel.containsKey(key)) {
										m_key_value.put('label',fieldApiVsTranslatedLabel.get(key));
									} else {
										m_key_value.put('label',fMap.get(field).getDescribe().getLabel());
									}
									if(field.equalsIgnoreCase('Name')){
										// m_key_value.put('label',fMap.get(field).getDescribe().getLabel());
										m_key_value.put('fieldName',field);
										//-- Starts | FIN-8506 | Changed by Ravi | 5 Nov 2025 --//
										m_key_value.put('type','link');
										//-- Ends | FIN-8506 | Changed by Ravi | 5 Nov 2025 --//
										m_key_value.put('sortable',false);
									} else {
										// m_key_value.put('label',fMap.get(field).getDescribe().getLabel());
										m_key_value.put('fieldName',field);
										m_key_value.put('type',m_Type.get(String.valueOf(fMap.get(field).getDescribe().getType())) == 'double' ? 'number' : m_Type.get(String.valueOf(fMap.get(field).getDescribe().getType())));
										m_key_value.put('sortable',true);
									}
									//-- END | FIN-8280| Changed by Asera | 17 April 2026 --//
									
									listofField.add(m_key_value);
								}
								if(fMap.get(field).getDescribe().getType() == Schema.DisplayType.REFERENCE){
									refField.add(field);
								}
							}
							// if (listTask.get(0).Status != 'Completed') {
							// 	Map<String,Object> m_key_value1 = new Map<String,Object>();
							// 	m_key_value1.put('label','');
							// 	m_key_value1.put('fieldName','RemoveCommunication');
							// 	m_key_value1.put('type','html');
							// 	m_key_value1.put('sortable',false);
							// 	m_key_value1.put('onClickFunction','removeCommunication');
							// 	m_key_value1.put('width','25px');
							// 	listofField.add(m_key_value1);
							// }
							
						} else {
							Map<String,Object> m_key_value = new Map<String,Object>();
							m_key_value.put('label',fMap.get('Name').getDescribe().getLabel());
							m_key_value.put('fieldName','Name');
							//-- Starts | FIN-8506 | Changed by Ravi | 5 Nov 2025 --//
							m_key_value.put('type','link');
							//-- Ends | FIN-8506 | Changed by Ravi | 5 Nov 2025 --//
							m_key_value.put('sortable',true);
							listofField.add(m_key_value);
						}
						inMap.put(treStep.stepName + 'refField',refField);
						inMap.put(treStep.stepName + 'columns',listofField);
						//-- Start | FIN-8209 | Changed By Dilshad | 13-Aug-2025 --//
						inMap.put(treStep.stepName, childObjRecord);
						//-- End | FIN-8209 | Changed By Dilshad | 13-Aug-2025 --//
						
						//-- Starts | FIN-6885 | Changed by Sejal | 6 JAN 2025 --//
						if(childObjRecord.size() > 0) {
							//-- Starts | FIN-8383 | Changed by ASERA | 23 Sep 2025 --//
							inMap.put(treStep.stepName + 'blockShow', 'true');
							//-- End | FIN-8383 | Changed by ASERA | 23 Sep 2025 --//
							Set<Id> tmp = new Set<Id>();
							for(sObject rec : childObjRecord) {
								excludedIds.add((Id)rec.get('Id'));
							}
						} else {
							//-- Starts | FIN-8383 | Changed by ASERA | 23 Sep 2025 --//
							inMap.put(treStep.stepName + 'blockShow', 'false');
							//-- End | FIN-8383 | Changed by ASERA | 23 Sep 2025 --//
						}
						//-- Ends | FIN-6885 | Changed by Sejal | 6 JAN 2025 --//
					}
				}
				inMap.put('listOfStep', listOfStep);
			}
			inMap.put('taskSubject', listTask.get(0).Subject);
			inMap.put('priority', listTask.get(0).Priority);
			inMap.put('dueDate', listTask.get(0).ActivityDate);
			
			Map<String,String> owner = new Map<String,String>();
			owner.put('id', listTask.get(0).OwnerId);
			owner.put('name', listTask.get(0).Owner.Name);
			
			inMap.put('assignedTo', owner);
			Map<String,String> what = new Map<String,String>();
			what.put('id', listTask.get(0).WhatId);
			what.put('name', listTask.get(0).What.Name);
			inMap.put('accountName', listTask.get(0).What.Name);
			inMap.put('accountId', listTask.get(0).WhatId);
			inMap.put('relatedTo', what);
			inMap.put('status', listTask.get(0).Status);
			//-- Starts | FIN-7945 | Changed by Ravi | 10 Sep 2025 --//
			String baseFields = 'Credit_Utilization__c, celsrm__Credit_Remaining__c, ' +
                    'celsrm__Total_AR__c, celsrm__Total_Past_Due__c, ' +
                    'celsrm__Total_Disputed__c, celsrm__Age0__c, celsrm__Age1__c, ' +
                    'celsrm__Age2__c, celsrm__Age3__c, celsrm__Age4__c, ' +
                    'celsrm__Age5__c, celsrm__Locale__c';
			if(isMultiCurrencyEnabled){
				baseFields += ', CurrencyIsoCode';
			}
			String soql = 'SELECT ' + baseFields + ' FROM Account WHERE Id = \'' +listTask.get(0).WhatId + '\'';
			Account acc = Database.query(soql);
			String currencyIso = isMultiCurrencyEnabled ? acc.CurrencyIsoCode : UserInfo.getDefaultCurrency();
			inMap.put('CurrencyIsoCode', currencyIso);
			//-- Ends | FIN-7945 | Changed by Ravi | 10 Sep 2025 --//
			inMap.put('creditUtilization', acc.Credit_Utilization__c);
			inMap.put('creditRemaining', acc.celsrm__Credit_Remaining__c);
			inMap.put('totalAR', acc.celsrm__Total_AR__c);
			inMap.put('totalPastDue', acc.celsrm__Total_Past_Due__c);
			inMap.put('totalDisputed', acc.celsrm__Total_Disputed__c);
			inMap.put('current', acc.celsrm__Age0__c);
			inMap.put('age1', acc.celsrm__Age1__c);
			inMap.put('age2', acc.celsrm__Age2__c);
			inMap.put('age3', acc.celsrm__Age3__c);
			inMap.put('age4', acc.celsrm__Age4__c);
			inMap.put('age5', acc.celsrm__Age5__c);
			inMap.put('fromAddress', listTreatment.get(0).celsrm__Org_Id__c);

			//-- FIN-8540 | Changed by Ravi | 15-Jun-2026 | Start | Comment as code move upword --//
			//-- Starts | FIN-6130 | Changed by Asera | 29 Aug 2024 --//
			// Id taskOwnerId = listTask.get(0).OwnerId;
			// Id loggedInUserId = UserInfo.getUserId();
			// // Check if the OwnerId is the logged-in user
			// if (taskOwnerId == loggedInUserId) {
			// 	inMap.put('showAction', 'true');
        	// } else {
			// 	try {
			// 		// Check if the OwnerId is a queue
			// 		Group taskOwnerGroup = [SELECT Id FROM Group WHERE Id = :taskOwnerId LIMIT 1];
			// 		if (taskOwnerGroup != null) {
			// 			// Query to find all the queues the logged-in user belongs to, including sub-queues
			// 			List<GroupMember> userGroups = [
			// 				SELECT GroupId 
			// 				FROM GroupMember 
			// 				WHERE UserOrGroupId = :loggedInUserId
			// 			];
			// 			// Check if the logged-in user belongs to the task's queue or any of its sub-queues
			// 			for (GroupMember gm : userGroups) {
			// 				if (gm.GroupId == taskOwnerId) {
			// 						inMap.put('showAction', 'true');
			// 						break;
			// 				}
			// 			}
			// 		}
			// 	} catch (QueryException e) {
			// 		// Handle the case where the taskOwnerId is not a queue ID (e.g., another user ID)
			// 		inMap.put('showAction', 'false');
			//   }
				
			// }
			// //-- End | FIN-6130 | Changed by Asera | 29 Aug 2024 --//
			//-- FIN-8540 | Changed by Ravi | 15-Jun-2026 | End --//

		}
		//-- Starts | FIN-6329 | changes by Dilshad | 1 Aug 2024 --//
		inMap.put('childObjAPIName', childObjAPIName);
		//-- Ends | FIN-6329 | changes by Dilshad | 1 Aug 2024 --//
		
		return inMap;
	}
	
	@AuraEnabled	
	public static Task TaskDetails(Id taskId){
        Task task = [select Id from Task where Id=:taskId];
        return task;
    
    }
	@AuraEnabled
	public static Map<Object, Object> FetchCallScript(Map<Object,Object> inMap){
		String taskID = (String)inMap.get('Id');
		List<Task> listTask = [select id,celsrm__Treatment__c from task where id =: taskID];
		ID treatmentId = listTask.get(0).celsrm__Treatment__c;
		List<celsrm__Treatment__c> listTreatment = [select id,Name, celsrm__Task_Type__c from celsrm__Treatment__c where id =:treatmentId ];
		if(listTreatment.get(0).celsrm__Task_Type__c != null && (listTreatment.get(0).celsrm__Task_Type__c).containsIgnoreCase('Email')){
			inMap.put('showEmailOnLogACall','true');
		}
		List<Object> childObjectIds = inMap.get('childObjectIds') != null ? (List<Object>)inMap.get('childObjectIds') : new List<Object>();
		List<Id> childIds = new List<Id>();
		List<Object> listOfStep = inMap.get('listOfStep') != null ? (List<Object>)inMap.get('listOfStep') : new List<Object>();
		for (Object step : listOfStep) {
			if (inMap.containsKey(step) && inMap.get(step) != null) {
				List<Object> values = (List<Object>)inMap.get(step);
				if (values.size() > 0) {
					for (Object vals : values) {
						Map<Object,Object> val =(Map<Object,Object>)vals;
						if (val.containsKey('isSelected') && (Boolean)val.get('isSelected') == true) {
							childIds.add((Id)val.get('Id'));
						}
					}
				}
			}
		}
		// for(Object Ids : childObjectIds){
		// 	childIds.add((String)Ids);
		// }
		if (childObjectIds.size() > 0) {
			String ObjectName = ((Id)childObjectIds.get(0)).getSObjectType().getDescribe().getName();
			if (ObjectName.equalsIgnoreCase('celsrm__Transaction__c')) {
				Map<Id,celsrm__Transaction__c> trxnsData = new Map<Id,celsrm__Transaction__c>([Select Id, Name, celsrm__DPD__c, celsrm__Last_Contact_Date__c, celsrm__Balance__c From celsrm__Transaction__c Where Id IN :childIds]);
				
				String script = 'Hello Customer<br /><br />';
				script += 'Greetings! Hope you are doing well. I’m calling you to share information about some of the outstanding invoice that are yet to be paid.<br />';
				//for oldest DPD
				for (Object step : listOfStep) {
					script += '<br />';
					script += '<h3>' + step + ':</h3>';
					script += '<ul>';
					if (inMap.containsKey(step) && inMap.get(step) != null) {
						List<Object> values = (List<Object>)inMap.get(step);
						for (Object vals : values) {
							Map<Object,Object> val =(Map<Object,Object>)vals;
							Id trxId = (Id)val.get('Id');
							celsrm__Transaction__c trxnData = trxnsData.get(trxId);
							script += '<li>';
							script += 'Invoice <b>' + trxnData.Name + '</b> of <b> $' +(trxnData.celsrm__Balance__c.format().contains('.')?trxnData.celsrm__Balance__c.format():(trxnData.celsrm__Balance__c.format()+'.00')) + '</b> has been outstanding for <b>' + (trxnData.celsrm__DPD__c != null ? trxnData.celsrm__DPD__c : 0) + '</b>.';
							if(trxnData.celsrm__Last_Contact_Date__c != null) {
								script += ' Last reminder was sent on <b>' + trxnData.celsrm__Last_Contact_Date__c.format() + '</b>.';
							}
							script += '</li>';
							
							
						}
						script += '</ul>';
							//script += '<br />';
					}
				}
				inMap.put('CallScripts', script);
			} else if (ObjectName.equalsIgnoreCase('celsrm__Dispute__c')) {
				Map<Id,celsrm__Dispute__c> trxnsData = new Map<Id,celsrm__Dispute__c>([Select Id, Name, celsrm__Dispute_DPD__c, celsrm__Dispute_Type__c,celsrm__Last_Contact_Date__c, celsrm__Balance__c From celsrm__Dispute__c Where Id IN :childIds]);
				
				String script = 'Hello Customer<br /><br />';
				script += 'Greetings! Hope you are doing well. I’m calling you to share information about some of the outstanding invoice that are yet to be paid.<br />';
				//for oldest DPD
				for (Object step : listOfStep) {
					script += '<br />';
					script += '<h3>' + step + ':</h3>';
					script += '<ul>';
					if (inMap.containsKey(step) && inMap.get(step) != null) {
						List<Object> values = (List<Object>)inMap.get(step);
						for (Object vals : values) {
							Map<Object,Object> val =(Map<Object,Object>)vals;
							Id trxId = (Id)val.get('Id');
							celsrm__Dispute__c trxnData = trxnsData.get(trxId);
							script += '<li>';
							script += 'Dispute <b>' + trxnData.Name + '</b> due to <b>' + trxnData.celsrm__Dispute_Type__c + '</b> of <b> $' +(trxnData.celsrm__Balance__c.format().contains('.')?trxnData.celsrm__Balance__c.format():(trxnData.celsrm__Balance__c.format()+'.00')) + '</b> has been outstanding for <b>' + (trxnData.celsrm__Dispute_DPD__c != null ? trxnData.celsrm__Dispute_DPD__c : 0)+ '</b>.';
							if(trxnData.celsrm__Last_Contact_Date__c != null) {
								script += ' Last reminder was sent on <b>' + trxnData.celsrm__Last_Contact_Date__c.format() + '</b>.';
							}
							script += '</li>';
							
							
						}
						script += '</ul>';
							//script += '<br />';
					}
				}
				inMap.put('CallScripts', script);
			}
		}
		
		inMap.put('FollowUpDate', '7');
		inMap.put('FollowupDaysCustom', Date.today().addDays(7));
		return inMap;
	}

	@AuraEnabled	
	public static Map<Object,Object> logACall(Map<Object,Object> inMap){
		
		String AccId = (String)inMap.get('accountId');

		List<Account> CurrentAccList = [SELECT id, Name FROM Account WHERE id =: AccId];
		if (!CurrentAccList.isEmpty()) {
			for(Account CurrentAcc : CurrentAccList) {
				CurrentAcc.celsrm__Last_Contact_Date__c = date.Today();
				CurrentAcc.celsrm__Last_Contact_Type__c = (string) inMap.get('screenName');
				CurrentAcc.celsrm__Last_Contact_Method__c = 'Phone';
			}
			update CurrentAccList;
		}
		List<Task> tskList = new List<Task>();
		String taskId = (String)inMap.get('Id');

		Task tk = [SELECT Id, WhatId, Subject, Status, AccountId, celsrm__Treatment__c, celsrm__Call_Status__c FROM Task WHERE Id =: taskId];
		tk.celsrm__Call_Status__c = inMap.get('ContactnotpickcallMethod') != null ? (String)inMap.get('ContactnotpickcallMethod') : 'Answered';
		tk.Status = 'Completed';
		tskList.add(tk);

		if (inMap.containsKey('isFollowup') && (Boolean)inMap.get('isFollowup')) {
			Task updaeTk = tk.clone(false, false, false, false);
			if (inMap.containsKey('FollowupDays') && inMap.get('FollowupDays') != null && String.valueOf(inMap.get('FollowupDays')).equalsIgnoreCase('custom')) {
				updaeTk.ActivityDate = date.valueOf(String.valueOf(inMap.get('FollowupDaysCustom')));
			} else if (inMap.containsKey('FollowupDays') && inMap.get('FollowupDays') != null && !String.valueOf(inMap.get('FollowupDays')).equalsIgnoreCase('custom')) {
				Integer addday = Integer.valueOf(String.valueOf(inMap.get('FollowupDays')));
				updaeTk.ActivityDate = date.today().addDays(addday);
			}
			updaeTk.Status = 'Not Started';
			updaeTk.celsrm__Call_Status__c ='';
			tskList.add(updaeTk);
		}

		Task callTask = new Task();
		callTask.Subject = 'Call : ' + tk.Subject;
		callTask.Status = 'Completed';
		callTask.whoId= String.valueOf(inMap.get('DialContactId'));
		callTask.WhatId = AccId;
		callTask.ActivityDate = date.today();
		callTask.Type = String.valueOf(inMap.get('ContactMethod'));
		tskList.add(callTask);

		upsert tskList;

		List<Object> childObjectIds = (List<Object>)inMap.get('childObjectIds');
		List<Id> childIds = new List<Id>();
		List<Object> listOfStep = inMap.get('listOfStep') != null ? (List<Object>)inMap.get('listOfStep') : new List<Object>();
		Map<String, String> mapOfIdAgainStep = new Map<String, String>();
		for (Object step : listOfStep) {
			if (inMap.containsKey(step) && inMap.get(step) != null) {
				List<Object> values = (List<Object>)inMap.get(step);
				if (values.size() > 0) {
					for (Object vals : values) {
						Map<Object,Object> val =(Map<Object,Object>)vals;
						if (val.containsKey('isSelected') && (Boolean)val.get('isSelected') == true) {
							childIds.add((Id)val.get('Id'));
							mapOfIdAgainStep.put((String)val.get('Id'), (String)step);
						}
					}
				}
			}
		}
		
		String ObjectName = ((Id)childObjectIds.get(0)).getSObjectType().getDescribe().getName();
		String query = 'select id, celsrm__Treatment_Notes__c from ' + ObjectName + ' where id in : childIds ';
		System.debug('query--> ' + query);
		List<sObject> transList=Database.query(query);
		Map<Id,SObject> MapTransOlderNotes = new Map<Id,SObject>();
		//-- Starts | FIN-6130 | Changed by Dilshad | 26 Jun 2024 --//
		List<String> transactionIds = new List<String>();
		//-- Ends | FIN-6130 | Changed by Dilshad | 26 Jun 2024 --//
		for(SObject trans : transList){
			MapTransOlderNotes.put((Id)trans.get('Id'),trans);
			//-- Starts | FIN-6130 | Changed by Dilshad | 26 Jun 2024 --//
			transactionIds.add(String.valueOf(trans.get('Id')));
			//-- Ends | FIN-6130 | Changed by Dilshad | 26 Jun 2024 --//
		}
		List<Sobject> childObjList = new List<Sobject>();
			
		
		for (Id Ids : childIds) {
			Schema.SObjectType token =((Id)Ids).getSObjectType();
			Sobject child = token.newSobject();
			Id childId = (Id)Ids;
			child.put('Id', (Id)Ids);
			child.put('celsrm__Last_Contact_Date__c', date.today());
			child.put('celsrm__Last_Contacted_By__c', UserInfo.getUserId());
			String notes = '';
			if(String.valueOf(inMap.get('NoteBody')) != null){
				notes = String.valueOf(inMap.get('treatmentName')) + ' - ' + mapOfIdAgainStep.get((String)Ids) + '\n' + String.valueOf(inMap.get('NoteBody')) + '\n' + UserInfo.getName() +':'+ date.today().month()+'/'+date.today().day() + '/'+ date.today().year() + '\n\n' + (MapTransOlderNotes.get(childId).get('celsrm__Treatment_Notes__c') != null && MapTransOlderNotes.get(childId).get('celsrm__Treatment_Notes__c') != '' ? MapTransOlderNotes.get(childId).get('celsrm__Treatment_Notes__c') : '');
				child.put('celsrm__Treatment_Notes__c', notes);
			} else {
				notes = String.valueOf(inMap.get('treatmentName')) + ' - ' + mapOfIdAgainStep.get((String)Ids) + '\n' + UserInfo.getName() +':'+ date.today().month()+'/'+date.today().day() + '/'+ date.today().year() + '\n\n' + (MapTransOlderNotes.get(childId).get('celsrm__Treatment_Notes__c') != null && MapTransOlderNotes.get(childId).get('celsrm__Treatment_Notes__c') != '' ? MapTransOlderNotes.get(childId).get('celsrm__Treatment_Notes__c') : '');
				child.put('celsrm__Treatment_Notes__c', notes);
			}
			//-- Starts | FIN-6905 | Changed by Ravi | 2 Jan 2025 --//
			child.put('celsrm__Last_Dunning_Date__c', date.today());
			child.put('celsrm__Last_Treatment__c', tk.celsrm__Treatment__c);
			//-- Starts | FIN-6905 | Changed by Ravi | 2 Jan 2025 --//
			childObjList.add(child);
		}
		if (!childObjList.isEmpty()) {
			update childObjList;
		}
		if (inMap.get('ContactCalled') != '' && inMap.get('ContactCalled') != null && inMap.get('ContactCalled') != '' && inMap.get('ContactCalled') != null) {	
			Contact con = new contact();	
			con.Id = String.valueOf(inMap.get('DialContactId'));	
			con.Phone = String.valueOf(inMap.get('ContactCalled'));	
			update con;	
		}
		
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
		String fileName = 'Treatment Details';
		for (Task tsk : tskList) {
			if(tsk.Status == 'Not Started'){
				ContentVersion version = new ContentVersion();
				version.VersionData = Blob.valueOf(JSON.serialize(stepToRecIds));
				version.Title = 'Treatment Details'; 
				version.PathOnClient = 'treatmentdetails.json';
				insert version;

				// get content document
				List<ContentVersion> cVer = [Select Id, ContentDocumentId, Title, FileType, ContentSize, VersionData FROM ContentVersion WHERE Id = :version.Id];

				if(cVer != null && cVer.size() > 0) {
					//link file with the task
					system.debug('ContentDocumentId>>>>>> ' + cVer.get(0).ContentDocumentId);
					ContentDocumentLink contentLink =new ContentDocumentLink();
					contentLink.ContentDocumentId = cVer.get(0).ContentDocumentId;
					contentLink.LinkedEntityId = tsk.Id;
					contentLink.ShareType = 'V';
					insert contentLink;
				}
			}
		}
		List<ContentDocumentLink> listContentDL = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId =: taskID];
		Set<Id> conDocIds = new Set<Id>();
		for(ContentDocumentLink conDL : listContentDL){
			conDocIds.add(conDL.ContentDocumentId);
		}
		List<ContentDocument> listContentDoc = [SELECT Id, FileExtension, Title, LastModifiedDate FROM ContentDocument WHERE Id IN :conDocIds and Title =: fileName];
		if(!listContentDoc.isEmpty()){
			ContentDocument selectedContentDoc = listContentDoc.get(0);
			ContentVersion contentVersion = new ContentVersion(
				ContentDocumentId = selectedContentDoc.Id,
				Title = 'Treatment Details',
				PathOnClient = 'treatmentdetails.json',
				ReasonForChange = 'updated records',
				VersionData = Blob.valueOf(JSON.serialize(stepToRecIds)),
				IsMajorVersion = true
			);
			insert contentVersion;
		}
		
		//-- Starts | FIN-6130 | Changed by Dilshad | 26 Jun 2024 --//
		//-- Capture Activity --//
		List<String> accList = new List<String>();
		accList.add(AccId);
		//-- Start | FIN-8209 | Changed By Dilshad/Asera | 13-Aug-2025 --//
		insertTreatmentActivity(accList, transactionIds, tk.Subject, null);
		//-- End | FIN-8209 | Changed By Dilshad/Asera | 13-Aug-2025 --//
		//-- Ends | FIN-6130 | Changed by Dilshad | 26 Jun 2024 --//

		return inMap;
	}
	@AuraEnabled
	public static Map<Object,Object> customSendEmail(Map<Object,Object> inMap, Boolean updateObj){
		String taskId = (String)inMap.get('Id');
		Savepoint sp = Database.setSavepoint();
		try {
			if (inMap != null && inMap.containsKey('ComposeEmail') && inMap.get('ComposeEmail') != null) {
				//-- Starts | FIN-6130 | Changed by Dilshad | 26 Jun 2024 --//
				//-- Starts | FIN-6334 | Changed By Dilshad | 13 Aug 2024 --//
				Task tk = [SELECT Id, Subject, celsrm__Treatment__c, celsrm__Treatment__r.celsrm__Attachment_Format__c FROM Task WHERE Id =: taskId];
				//-- Ends | FIN-6334 | Changed By Dilshad | 13 Aug 2024 --//
				//-- Ends | FIN-6130 | Changed by Dilshad | 26 Jun 2024 --//
				id parentId = null;
					if (inMap.containsKey('accountId') && inMap.get('accountId') != null) {
						 parentId = (Id) inMap.get('accountId');
					}
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
				
				List < Map < String, String >> attachmentobj = new List < Map < String, String >> ();
				if (inMap.containsKey('isAttachment') && Boolean.valueOf(inMap.get('isAttachment'))) {
					//-- Starts | FIN-6334 | Changed By Dilshad | 13 Aug 2024 --//
					//-- Starts | FIN-6948 | Changed by Ravi | 2 Jan 2025 --//
					String attachmentFormat = String.valueOf(inMap.get('attachmentFormat'));
					//-- Starts | FIN-8653 | Changed by Dhwanil | 16 DEC 2025 --//
					String treatmentattachmentName = String.valueOf(inMap.get('attachmentName'));
					//-- Ends | FIN-8653 | Changed by Dhwanil | 16 DEC 2025 --//
					Boolean isDunningScreen = inMap.containsKey('isDunningScreen') ? Boolean.valueOf(inMap.get('isDunningScreen')) : false ;
					
					//-- Ends | FIN-6948 | Changed by Ravi | 2 Jan 2025 --//
					//-- Start | FIN-8209 | Changed By Dilshad | 13-Aug-2025 --//
					if(attachmentFormat == 'Excel' && isDunningScreen) { //-- Mass Dunning --//
						// << START - MM - FIN-9455 - Mass Dunning -> Replace custom placeholders and translations >>
						// PageReference pRef= Page.celsrm__TreatmentExcelAttachmentGenerator;
						PageReference pRef= Page.cTreatmentExcelAttachmentGenerator;
						// << END - MM - FIN-9455 - Mass Dunning -> Replace custom placeholders and translations >>
						pRef.getParameters().put('taskId',tk.Id);
						pRef.getParameters().put('accountId',parentId);
						pRef.getParameters().put('taskSubject',String.valueOf(inMap.get('taskSubject')));
						pRef.getParameters().put('treatmentStage',String.valueOf(inMap.get('treatmentStage')));
						pRef.getParameters().put('treatmentId',tk.celsrm__Treatment__c);
						//-- Starts | FIN-6948 | Changed by Ravi | 3 JAN 2025 --//
						pRef.getParameters().put('jsonFileName',isDunningScreen ? 'Treatment Details' : 'Treatment Details Temp');
						//-- Ends | FIN-6948 | Changed by Ravi | 3 JAN 2025 --//
						//-- FIN-8983 | Changed By Dilshad | 30-Jan-2026 | Start --//
						pRef.getParameters().put('attachmentType','Excel');
						//-- FIN-8983 | Changed By Dilshad | 30-Jan-2026 | End --//
						ContentVersion cv = new ContentVersion();
						if (Test.isRunningTest()) {
							cv.VersionData = blob.valueOf('Test');
						} else {
							cv.VersionData = pRef.getContent();
						}
						//-- Start | FIN-8653 | Changed By Dhwanil | 16 dec 2025 --//
                  		treatmentattachmentName = (treatmentattachmentName!=null && treatmentattachmentName!='' ? treatmentattachmentName : 'Treatment-' + String.valueOf(inMap.get('taskSubject')));
						cv.Title = treatmentattachmentName;
						cv.PathOnClient = treatmentattachmentName + '.xls';
						//-- End | FIN-8653 | Changed By Dhwanil | 16 dec 2025 --//
						upsert cv;
						Map < String, String > attachment = new Map < String, String > ();
						attachment.put('Id', cv.Id);
						attachmentobj.add(attachment);
					} else if((attachmentFormat == 'Excel' || attachmentFormat == 'PDF') && !isDunningScreen) { //-- Manual Dunning --//
						if (inMap.containsKey('contentVersionId')) {
							Map<String, String> attachment = new Map<String, String>();
							attachment.put('Id', String.valueOf(inMap.get('contentVersionId')));
							attachmentobj.add(attachment);
							system.debug('attachmentobj-->' + attachmentobj);
						}
					//-- End | FIN-8209 | Changed By Dilshad | 13-Aug-2025 --//
					} else {
					//-- Ends | FIN-6334 | Changed By Dilshad | 13 Aug 2024 --//
						// << START - MM - FIN-9455 - Mass Dunning -> Replace custom placeholders and translations >>
						// PageReference pRef = Page.celsrm__SRMTreatmentPdfGenerator;
						PageReference pRef = Page.cTreatmentPDFAttachmentGenerator;
						// << END - MM - FIN-9455 - Mass Dunning -> Replace custom placeholders and translations >>
						pRef.getParameters().put('taskId',tk.Id);
						pRef.getParameters().put('accountId',parentId);
						pRef.getParameters().put('taskSubject',String.valueOf(inMap.get('taskSubject')));
						pRef.getParameters().put('treatmentStage',String.valueOf(inMap.get('treatmentStage')));
						pRef.getParameters().put('treatmentId',tk.celsrm__Treatment__c);
						//-- Starts | FIN-6948 | Changed by Ravi | 3 JAN 2025 --//
						pRef.getParameters().put('jsonFileName',isDunningScreen ? 'Treatment Details' : 'Treatment Details Temp');
						//-- Ends | FIN-6948 | Changed by Ravi | 3 JAN 2025 --//
						//-- FIN-8983 | Changed By Dilshad | 30-Jan-2026 | Start --//
						pRef.getParameters().put('attachmentType','PDF');
						//-- FIN-8983 | Changed By Dilshad | 30-Jan-2026 | End --//
						ContentVersion cv = new ContentVersion();
						if (Test.isRunningTest()) {
							cv.VersionData = blob.valueOf('Test');
						} else {
							cv.VersionData = pRef.getContentAsPDF();
						}
						//-- Start | FIN-8653 | Changed By Dhwanil | 16 dec 2025 --//
                        treatmentattachmentName = (treatmentattachmentName!=null && treatmentattachmentName!='' ? treatmentattachmentName : 'Treatment-' + String.valueOf(inMap.get('taskSubject')));
						cv.Title = treatmentattachmentName;
						cv.PathOnClient = treatmentattachmentName + '.pdf';
						//-- End | FIN-8653 | Changed By Dhwanil | 16 dec 2025 --//
						upsert cv;
						Map < String, String > attachmentTable = new Map < String, String > ();
						attachmentTable.put('Id', cv.Id);
						attachmentobj.add(attachmentTable);
					}
				}
				
				
				if (tempComposeEmail.containsKey('attachment') && tempComposeEmail.get('attachment') != null && ((List < object > ) tempComposeEmail.get('attachment')).size() > 0) {
						 List < Object > lst = ((List < Object > ) tempComposeEmail.get('attachment'));
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
				} else if (tempComposeEmail.containsKey('textbody') && tempComposeEmail.get('textbody') != null) {
						 textbody = String.valueOf(tempComposeEmail.get('textbody'));
					} else {
						 throw new celsrm.GOGDataServiceLoadException('Please enter value into body');
					}
				
				celsrm.GOGEmailMapper.sendEmail(fromId, Toaddress, subject, htmlBody, textbody, ccaddress, bccaddress, attachmentobj, parentId, null);
				if(inMap.containsKey('ggErrorMessage')) {
					Database.rollback(sp);
					return inMap;
			  	}
				
	
					if (updateObj) {
						 // Update File Start
					//-- Starts | FIN-6885 | Changed by Sejal | 24 JAN 2025 --//	
						 Map<String, Set<Id>> stepToRecIds = new Map<String, Set<Id>>();
					if(inMap.containsKey('stepToRecIds') && inMap.get('stepToRecIds') != null){
						//-- Start | FIN-8048 | Changed by Ravi | 23 July 2025 --//
						try {
							stepToRecIds = (Map<String, Set<Id>>)inMap.get('stepToRecIds');
						} catch (Exception e) {
							Object rawStepToRecIds = inMap.get('stepToRecIds');
							if (rawStepToRecIds != null) {
								Map<Object, Object> tempMap = (Map<Object, Object>)rawStepToRecIds;
								for (Object keyObj : tempMap.keySet()) {
									String key = (String)keyObj;
									List<Object> idListObj = (List<Object>)tempMap.get(keyObj);
									Set<Id> idSet = new Set<Id>();
									for (Object idObj : idListObj) {
										idSet.add((Id)idObj);
									}
									stepToRecIds.put(key, idSet);
								}
							}
						}
						//-- End | FIN-8048 | Changed by Ravi | 23 July 2025 --//
					} else {
						//-- Start | FIN-8048 | Changed by Ravi | 23 July 2025 --//
						List<Object> listOfStep = inMap.get('listOfStep') != null ? (List<Object>)inMap.get('listOfStep') : new List<Object>();
						//-- Start | FIN-8048 | Changed by Ravi | 23 July 2025 --//
						for (Object step : listOfStep) {
							if (inMap.containsKey(step) && inMap.get(step) != null) {
								List<Object> values = (List<Object>)inMap.get(step);
								if (values.size() > 0) {
									Set<Id> tmp = new Set<Id>();
									for (Object vals : values) {
										Map<Object,Object> val =(Map<Object,Object>)vals;
										if (!val.containsKey('isSelected') || (val.containsKey('isSelected') && (Boolean)val.get('isSelected') == true)) {
											tmp.add((Id)val.get('Id'));
										}
									}
									if (tmp.size() > 0) {
										stepToRecIds.put((String)step, tmp);
									}
								}
							}
						}
					}
					if(inMap.containsKey('updateDocument') && Boolean.valueOf(String.ValueOf(inMap.get('updateDocument'))) == true){
						String fileName = 'Treatment Details';
						List<ContentDocumentLink> listContentDL = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId =: taskID];
						Set<Id> conDocIds = new Set<Id>();
						for(ContentDocumentLink conDL : listContentDL){
							conDocIds.add(conDL.ContentDocumentId);
						}
						List<ContentDocument> listContentDoc = [SELECT Id, FileExtension, Title, LastModifiedDate FROM ContentDocument WHERE Id IN :conDocIds and Title =: fileName];
						if(!listContentDoc.isEmpty()){
							ContentDocument selectedContentDoc = listContentDoc.get(0);
							ContentVersion contentVersion = new ContentVersion(
								ContentDocumentId = selectedContentDoc.Id,
								Title = 'Treatment Details',
								PathOnClient = 'treatmentdetails.json',
								ReasonForChange = 'updated records',
								VersionData = Blob.valueOf(JSON.serialize(stepToRecIds)),
								IsMajorVersion = true
							);
							insert contentVersion;
						}
						
						String fileNameTemp = 'Treatment Details Temp';
						List<ContentDocumentLink> listContentDLTemp = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId =: taskID];
						Set<Id> conDocIdsTemp = new Set<Id>();
						for(ContentDocumentLink conDL : listContentDLTemp){
							conDocIdsTemp.add(conDL.ContentDocumentId);
						}
						List<ContentDocument> listContentDocTemp = [SELECT Id, FileExtension, Title, LastModifiedDate FROM ContentDocument WHERE Id IN :conDocIdsTemp and Title =: fileNameTemp];
						delete listContentDocTemp;
					}
					//-- Ends | FIN-6885 | Changed by Sejal | 24 JAN 2025 --//	
					tk.Status = 'Completed';
					update tk;
	
					
					List<Object> childObjectIds = (List<Object>)inMap.get('childObjectIds');
					String childObjectName = (String)inMap.get('objectName');
					String accId = inMap.containsKey('accountId') && inMap.get('accountId') != null ? (String) inMap.get('accountId') : '';
					Account acc = new Account();
					acc.Id = accId;
					acc.celsrm__Last_Contact_Method__c  = 'Email';
					acc.celsrm__Last_Contact_Type__c = 'Treatment Send Email';
					acc.celsrm__Last_Contact_Date__c = date.today();
					update acc;
	
					List<Sobject> childObjList = new List<Sobject>();
					//-- Starts | FIN-6130 | Changed by Dilshad | 26 Jun 2024 --//
					List<String> transactionIds = new List<String>();
					//-- Ends | FIN-6130 | Changed by Dilshad | 26 Jun 2024 --//
					//-- Start | FIN-8209 | Changed By Dilshad/Asera | 13-Aug-2025 --//
					Map<Id, Map<String, Object>> transactionFieldMap = new Map<Id, Map<String, Object>>();
					String currentUserId = UserInfo.getUserId();
					String currentUserName = UserInfo.getName();
					Date currentDate = date.today();
					for(String step : stepToRecIds.keySet()){
						String treatmentNote =  String.valueOf(inMap.get('treatmentName')) + ' - ' + step + '\n' + currentUserName +':'+ date.today().month()+'/'+date.today().day() + '/'+ date.today().year();
						for(Id Ids : stepToRecIds.get(Step)){

							transactionIds.add(String.valueOf(Ids));
							Map<String, Object> txnFields = new Map<String, Object>();
							txnFields.put('celsrm__Treatment_Notes__c', treatmentNote);
							txnFields.put('celsrm__Last_Dunning_Date__c', currentDate);
							txnFields.put('celsrm__Last_Treatment__c', tk.celsrm__Treatment__c);
							transactionFieldMap.put(Ids, txnFields);

						}
					}
						
					//-- Starts | FIN-6130 | Changed by Dilshad | 26 Jun 2024 --//
					List<String> accList = new List<String>();
					accList.add(accId);
					insertTreatmentActivity(accList, transactionIds, tk.Subject, transactionFieldMap);
					//-- Start | FIN-8209 | Changed By Dilshad/Asera | 13-Aug-2025 --//
					//-- Ends | FIN-6130 | Changed by Dilshad | 26 Jun 2024 --//
					
				}
			}
		} catch (DmlException dmlEx) {
			Database.rollback(sp);
			System.debug('DML Exception: ' + dmlEx.getMessage());
			System.debug(dmlEx.getStackTraceString());
			inMap.put('ggErrorMessage', dmlEx.getMessage());
	  	}
      return inMap;
   }
	@AuraEnabled	
	public static Map<Object,Object> fetchContactEmailForAccount(Map<Object,Object> inMap){
		String accId = String.valueOf(inMap.get('Id'));
		List<contact> conList = [SELECT Id,lastname,Name,Fax,Email,AccountId,CC__c,Bcc__c,celsrm__Default__c From Contact where AccountId=: accId order by lastname];
		List<Map<String, String>> emailList = new List<Map<String, String>>();
		System.debug('conList>> ' + conList);
		for(Contact contact:conList){
			if (contact.Email != null && contact.Email != '') {
				Map<String, String> emailMap = new Map<String, String>();
				emailMap.put('label', contact.Name + ' (' + contact.Email + ')');
				emailMap.put('value', contact.Email);
				emailList.add(emailMap);
			}
		}
		System.debug('emailList>> ' + emailList);
		inMap.put('dataServiceResponse', emailList);
		return inMap;
	}
	
	@AuraEnabled	
	public static Map<Object,Object> showTreatmentNotes(Map<Object,Object> inMap){
		String accId = String.valueOf(inMap.get('Id'));
        List<Task> taskList = [SELECT Id,Subject FROM Task WHERE WhatId=: accId AND Status != 'Completed' AND celsrm__Treatment__c!='' order by CreatedDate desc LIMIT 1];
		if (taskList.size() == 0) {
			inMap.put('hideTreatmentNotes', 'true');
			// inMap.put('autoTaskId', taskList.get(0).Id);
		} else {
			List<contact> conList = [SELECT Id,lastname,Fax,Email,AccountId,CC__c,Bcc__c,celsrm__Default__c From Contact where celsrm__Default__c =: TRUE AND AccountId=: accId order by lastname];
			inMap.put('autoTaskId', taskList.get(0).Id);
			String to='';
			for(Contact contact:conList){
				if (contact.Email != null && contact.Email != '') {
					to += contact.Email + '; ';
				}
			}
			inMap.put('treatmentEmail', to.removeEnd('; '));
			inMap.put('treatmentNotes', '<div data-aura-rendered-by="271:0;p" data-aura-class="oneSystemMessage"><div class="slds-notify slds-notify_alert system-message level-warning slds-theme_warning" style="display: block;text-align: left;border-radius: 0.5rem;" data-message-id="loginAsSystemMessage" aria-live="polite" data-index="0" aria-atomic="true" data-aura-rendered-by="1:187;a"><span data-aura-rendered-by="3:187;a">' + Label.Treatment_Include_Notes_Before_Subject + ' <a href="' + '/'+ taskList.get(0).Id + '"' + ' target="_blank" style="color: blue;">' + taskList.get(0).Subject + '</a>. ' + Label.Treatment_Include_Notes_After_Subject + ' </span><div style="right:0;top: 0.5rem;position: absolute;"><a class="oninclude" href="javascript:void(0);" style="padding-right:5px;" title='+ Label.Treatment_Include + '>'+Label.Treatment_Include+'</a><a class="onno" href="javascript:void(0);" style="padding-right:5px;" title='+Label.Treatment_Not_Include+'>'+Label.Treatment_Not_Include+'</a></div>' );
			inMap.put('removeTreatmentNotes', '<div data-aura-rendered-by="271:0;p" data-aura-class="oneSystemMessage"><div class="slds-notify slds-notify_alert system-message level-warning slds-theme_warning" style="display: block;text-align: left;border-radius: 0.5rem;" data-message-id="loginAsSystemMessage" aria-live="polite" data-index="0" aria-atomic="true" data-aura-rendered-by="1:187;a"><span data-aura-rendered-by="3:187;a">' + Label.Treatment_Remove_Notes_Before_Subject + ' <a href="' + '/'+ taskList.get(0).Id + '"' + ' target="_blank" style="color: blue;">' + taskList.get(0).Subject + '</a> ' +  Label.Treatment_Remove_Notes_After_Subject + ' <a href="javascript:void(0);" style="color:red;" class="removeTreatment">'+ Label.Treatment_Remove + '</a> </span></div></div>' );
		}
        return inMap;
    }

	@AuraEnabled	
	public static Map<Object,Object> includeTreatmentOnAccount(Map<Object,Object> inMap){
		String treatmentButtonName = inMap.get('treatmentButtonName') != null ? String.valueOf(inMap.get('treatmentButtonName')) : '';
		if (treatmentButtonName.equalsIgnoreCase('Include')) {
			//-- Starts | FIN-6130 | Changed by Dilshad | 30 Jul 2024 --//
			String contactMethodName = (String) JSON.serialize(inMap.get('ContactMethod'));
			contactMethodName = contactMethodName.replaceall('"', '');
			//-- Ends | FIN-6130 | Changed by Dilshad | 30 Jul 2024 --//
			String treatmentEmail = String.valueOf(inMap.get('treatmentEmail'));
			String accountId = String.valueOf(inMap.get('Id'));
			String taskId = String.valueOf(inMap.get('autoTaskId'));	
			Task tsk = [SELECT Id, Subject, WhatId, celsrm__Treatment__c, celsrm__Treatment_Stage__c FROM Task WHERE Id =: taskId];
			id parentId = tsk.WhatId;
			String treatmentId = tsk.celsrm__Treatment__c;
			celsrm__Treatment__c treatment = [Select Id, Name, celsrm__Email_Template__c, celsrm__Account_Criteria__c, celsrm__Active__c, celsrm__Related_Object__c, celsrm__Treatment_Steps__c,
												celsrm__Task_Due_Date__c,celsrm__Task_Type__c,celsrm__Org_Id__c,celsrm__Template_Folder_Reference_Field__c, celsrm__Email_Template_Prefix__c, 
												celsrm__Attachment__c, celsrm__Notify_Account_Owner__c, celsrm__Custom_Logic_Class__c, celsrm__Consolidated_Treatment__c, celsrm__Seperate_Task_For_Step__c,
												celsrm__Auto_Treatment__c, celsrm__Enable_Dynamic_Template__c
												FROM celsrm__Treatment__c  Where Id=:treatmentId];
						
			List < String > Toaddress = null;
			List < String > ccaddress = null;
			List < String > bccaddress = null;
			//-- Starts | FIN-6130 | Changed by Dilshad | 30 Jul 2024 --//
			if (contactMethodName == 'Email') {
				//-- Ends | FIN-6130 | Changed by Dilshad | 30 Jul 2024 --//
				system.debug('tempComposeEmail--> ' + inMap.get('ComposeEmail'));
				map < string, object > tempComposeEmail = (map < string, object > ) JSON.deserializeUntyped(JSON.serialize(inMap.get('ComposeEmail')));
				system.debug('tempComposeEmail--> ' + tempComposeEmail);
				if (tempComposeEmail != null && tempComposeEmail.containsKey('to') && tempComposeEmail.get('to') != null && ((List < object > ) tempComposeEmail.get('to')).size() > 0) {
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

				
				if (tempComposeEmail != null && tempComposeEmail.containsKey('bcc') && tempComposeEmail.get('bcc') != null && ((List < Object > ) tempComposeEmail.get('bcc')).size() > 0) {
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
			} else {
				Toaddress = treatmentEmail.split(';');
			}
			//-- Starts | FIN-6130 | Changed by Dilshad | 30 Jul 2024 --//
			// if (contactMethodName == 'Phone' && inMap.containsKey('isFollowUp') && (Boolean)inMap.get('isFollowUp')) {
			// 	Task updaeTk = tsk.clone(false, false, false, false);
			// 	// tk.id = (String)inMap.get('Id');
			// 	updaeTk.ActivityDate = date.valueOf(String.valueOf(inMap.get('FollowUpDate')));
				
			// 	updaeTk.Status = 'Not Started';
			// 	updaeTk.celsrm__Call_Status__c ='';	
			// 	insert updaeTk;
			// }
			//-- Ends | FIN-6130 | Changed by Dilshad | 30 Jul 2024 --//
			if (contactMethodName == 'Phone' && treatment.celsrm__Task_Type__c.equalsIgnoreCase('call')) {
				Task callTask = new Task();
				callTask.Subject = 'Call : ' + tsk.Subject;
				callTask.Status = 'Completed';
				callTask.whoId= String.valueOf(inMap.get('DialContactId'));
				callTask.WhatId = parentId;
				callTask.ActivityDate = date.today();
                callTask.Type = String.valueOf(inMap.get('ContactMethod'));
				insert callTask;
			}
			
			Map<String, Object> returnBodyMap = celsrm.SRMTreatmentUtility.getTemplateBody(tsk, treatment, tsk.Id, null, true, null, null);
            String subject = returnBodyMap.get('subject') != null ? tsk.Subject + ' : '  + returnBodyMap.get('subject') : '';
            String templateBody = returnBodyMap.get('templateBody') != null ? String.valueOf(returnBodyMap.get('templateBody')) : '';
			String fromId = returnBodyMap.get('fromId') != null && returnBodyMap.get('fromId') != '' ? String.valueOf(returnBodyMap.get('fromId')) : null;
			Boolean attachmentFlag = returnBodyMap.get('attachment') != null ? Boolean.valueOf(returnBodyMap.get('attachment')) : false;
			
			system.debug('Toaddress--> ' + Toaddress);
			tsk.Status = 'Completed';
			update tsk;
			//-- Starts | FIN-6130 | Changed by Dilshad | 30 Jul 2024 --//
			if (attachmentFlag && contactMethodName == 'Email') {
				//-- Ends | FIN-6130 | Changed by Dilshad | 30 Jul 2024 --//
				List < Map < String, String >> attachmentobj = new List < Map < String, String >> ();
				if (treatment.celsrm__Attachment__c) {
					PageReference pRef= Page.celsrm__SRMTreatmentPdfGenerator;
					pRef.getParameters().put('taskId',taskId);
					pRef.getParameters().put('accountId',accountId);
					pRef.getParameters().put('taskSubject',tsk.Subject);
					pRef.getParameters().put('treatmentId',treatmentId);
					pRef.getParameters().put('treatmentStage',tsk.celsrm__Treatment_Stage__c);
					pRef.getParameters().put('jsonFileName','Treatment Details');
					ContentVersion cv = new ContentVersion();
					if (Test.isRunningTest()) {
						cv.VersionData = blob.valueOf('Test');
					} else {
						cv.VersionData = pRef.getContentAsPDF();
					}
					cv.Title = 'Treatment-' + tsk.Subject;
					cv.PathOnClient = 'treatment-' + tsk.Subject + '.pdf';
					upsert cv;
					Map < String, String > attachmentTable = new Map < String, String > ();
					attachmentTable.put('Id', cv.Id);
					attachmentobj.add(attachmentTable);
				}
				
				celsrm.GOGEmailMapper.sendEmail(fromId, Toaddress, subject, templateBody, null, ccaddress, bccaddress, attachmentobj, parentId, null);    
			}
			//-- Starts | FIN-6130 | Changed by Dilshad | 26 Jul 2024 --//
			Datetime currentDateTime = DateTime.now();
			Map<String, String> accIdActivityMap = celsrm.SRMUtilityController.insertActivity(new List<String>{accountId}, 'celsrm__Account__c', tsk.Subject, currentDateTime, 100, null, UserInfo.getUserId(), null, 'Internal', null);
			List<String> childRecordIds = new List<String>();
			childRecordIds = getChildRecordIds(tsk, treatment);
			if(childRecordIds != null && childRecordIds.size() > 0 && treatment.celsrm__Related_Object__c != null) {
				Map<String, Object> additionalFields = new Map<String, Object>();
				additionalFields.put('celsrm__Parent_Event__c', accIdActivityMap.get(accountId));
				celsrm.SRMUtilityController.insertActivity(childRecordIds, treatment.celsrm__Related_Object__c, tsk.Subject, currentDateTime, 100, null, UserInfo.getUserId(), null, 'Internal', additionalFields);
			}
			//-- Ends | FIN-6130 | Changed by Dilshad | 26 Jul 2024 --//
		}
		
		return inMap;
	}

	//-- Starts | FIN-6130 | Changed by Dilshad | 26 Jul 2024 --//
	public static void insertTreatmentActivity(List<String> accList, List<String> transactionIds, String activityName, Map<Id, Map<String, Object>>  transactionFieldMap) {
		Datetime currentDateTime = Datetime.now();
		//-- Insert Actvity at Account Level --//
		Map<String, String> accIdActivityIdMap = new Map<String, String>();
        accIdActivityIdMap = celsrm.SRMUtilityController.insertActivity(accList, 'celsrm__Account__c', activityName, currentDateTime, 100, null, UserInfo.getUserId(), null, 'Internal', null);
		//-- Insert Actvity at Transaction Level --//
		Map<String, Object> additionalFields = new Map<String, Object>();
		for (String accId : accIdActivityIdMap.keySet()) {
			additionalFields.put('celsrm__Parent_Event__c', accIdActivityIdMap.get(accId));
		}
		//-- Start | FIN-8209 | Changed By Dilshad/Asera | 13-Aug-2025 --//
		InsertTransactionActivityBatch insertTransactionActivity = new InsertTransactionActivityBatch(transactionIds, 'celsrm__Transaction__c', activityName, currentDateTime, additionalFields, transactionFieldMap);
		Database.executeBatch(insertTransactionActivity, 2000);
		//-- End | FIN-8209 | Changed By Dilshad/Asera | 13-Aug-2025 --//
	}
	public static List<String> getChildRecordIds(Task tsk, celsrm__Treatment__c treatment) {
		List<String> childIds = new List<String>();
		try {
			Map<String, Object> mapStepsDataObj = new Map<String, Object>();
			String stepsData = celsrm.SRMTreatmentUtility.readTreatmentDetailsFile(tsk.Id,'Treatment Details');
			mapStepsDataObj =  (Map<String, Object> ) JSON.deserializeUntyped(stepsData);
			
			for(String mapStepsDataKey : mapStepsDataObj.keySet()){
				for (Object ids : (List<Object>) mapStepsDataObj.get(mapStepsDataKey)) {
					childIds.add((Id)ids);
				}
			}
		} catch (Exception ex) {
			System.debug('Exception: ' + ex.getStackTraceString());
		}
		
		return childIds;
	}
	//-- Start | FIN-8209 | Changed By Dilshad | 13-Aug-2025 --//

	// << Start - ND - FIN-8132 - Email Templates based on Account Locale >> | Changed by ND - {value.emailTemplate}
	// << CHANGE - MM - FIN-8174 - Dynamic translated headers based account local | Change key CompanyCode to accountLocale>>
	public static Map<Object, Object> setAccountLocale(Map<Object, Object> inMap) {
        try {
			String accId = String.valueOf(inMap.get('accountId'));
			Account acc = [SELECT Id, Name, celsrm__Locale__c FROM Account WHERE Id=:accId];
			System.debug('celsrm__Locale__c>>' + acc.celsrm__Locale__c);
			if(acc.celsrm__Locale__c != null && acc.celsrm__Locale__c != '' ){
				List<EmailTemplate> template = [SELECT Id,Folder.Name  FROM EmailTemplate where Folder.Name = :acc.celsrm__Locale__c Limit 1];
				System.debug('template>>' + template);
				if(!template.isEmpty() && template.get(0).Folder.Name == acc.celsrm__Locale__c){
					inMap.put('accountLocale', acc.celsrm__Locale__c);
				} else{
					inMap.put('accountLocale', 'EN');
				}
			} else {
				inMap.put('accountLocale', 'EN');
			}
		} catch (Exception e) {
			System.debug('exception>> ' + e.getMessage());
        }
		return inMap;
	}
	// << End - ND - FIN-8132 - Email Templates based on Account Locale >> | Changed by ND

	// << Start - ND - FIN-8132 - Email Templates based on Account Locale >>
	// << CHANGE - MM - FIN-8174 - Dynamic translated headers based account local | Change key CompanyCode to accountLocale>>
    public static Map<Object, Object> updateAccountLocale(Map<Object, Object> inMap) {
        try {
            // String accId = String.valueOf(inMap.get('Id'));
            // Account acc = [SELECT Id, Name, celsrm__Company_Code__c FROM Account WHERE Id=:accId];
            // System.debug('celsrm__Company_Code__c>>' + acc.celsrm__Company_Code__c);
            String accountLocale = String.valueOf(inMap.get('accountLocale'));
            System.debug('accountLocale>>' + accountLocale);
            if(accountLocale != null && accountLocale != '' ){
                List<EmailTemplate> template = [SELECT Id,Folder.Name  FROM EmailTemplate where Folder.Name = :accountLocale Limit 1];
                System.debug('template>>' + template);
                if(!template.isEmpty() && template.get(0).Folder.Name == accountLocale){
                    inMap.put('accountLocale', accountLocale);
                } else{
                    inMap.put('accountLocale', 'EN');
                }
            } else {
                inMap.put('accountLocale', 'EN');
            }
        } catch (Exception e) {
            System.debug('exception>> ' + e.getMessage());
        }
        return inMap;
    }
    // << End - ND - FIN-8132 - Email Templates based on Account Locale >>

	@AuraEnabled
	public static String uploadExcelFile(Map<Object, Object> fileData) {
		String base64Data = String.valueOf(fileData.get('finalContent'));
		String fileName = String.valueOf(fileData.get('fileName'));
        ContentVersion contentVersion = new ContentVersion();
        contentVersion.Title = fileName;
        contentVersion.PathOnClient = '/' + fileName;
        contentVersion.VersionData = EncodingUtil.base64Decode(base64Data);
        Database.insert(contentVersion, Accesslevel.USER_MODE);
		return contentVersion.Id;
    }

	public static Map<Object,Object> getConsolidatedData(Map<Object,Object> inMap) {
		Map<Object,Object> returnMap = new Map<Object,Object>();
		List<Object> listOfStep = (List<Object>)inMap.get('listOfStep');
		List<Object> columnList = (List<Object>)inMap.get(listOfStep.get(listOfStep.size() - 1)+'columns');
		List<Object> childObjectIdsObj = (List<Object>)inMap.get('childObjectIds');
		List<Id> childObjectIds = new List<Id>();
		if (childObjectIdsObj != null) {
			for (Object obj : childObjectIdsObj) {
				if (obj != null) {
					childObjectIds.add((Id)obj);
				}
			}
		}
		List<String> columns = new List<String>();
		for (Object col : columnList) {
			Map<Object, Object> colMap = (Map<Object, Object>)col;
			String fieldName = (String)colMap.get('fieldName');
			columns.add(fieldName);
		}
		Boolean isMultiCurrencyEnabled = Schema.sObjectType.Account.fields.getMap().containsKey('CurrencyIsoCode');
		if(isMultiCurrencyEnabled && !columns.contains('CurrencyIsoCode')) {
			columns.add('CurrencyIsoCode');
		}
		String fields = String.join(columns, ', ');
		String childObjectName = (String)inMap.get('childObjAPIName');

		String query = 'SELECT ' + fields + ' FROM ' + childObjectName + ' WHERE Id IN :childObjectIds';
		
		List<SObject> childObjRecord = Database.query(query);
		returnMap.put('columns', columnList);
		returnMap.put('data', childObjRecord);
		return returnMap;
	}

	public static Map<Object,Object> getPreDataForExcelFileGeneration(Map<Object,Object> inMap) {
		
		Map<Object,Object> returnMap = new Map<Object,Object>();
		//-- FIN-8540 | Changed by Ravi | 15-Jun-2026 | Start --//
		// AI Dunning - restructure transaction data into listOfStep format for client-side Excel/PDF generation
		if (inMap.containsKey('isAiDunning') && (inMap.get('isAiDunning') == true || inMap.get('isAiDunning') == 'true')) {
			Map<Object, Object> gridData = returnGridData(inMap);
			String stepName = 'Transactions';
			returnMap.put('listOfStep', new List<String>{ stepName });
			returnMap.put(stepName, gridData.get('aiTransactions'));
			returnMap.put(stepName + 'columns', gridData.get('aiTransactionscolumns'));
			returnMap.put('orgName', UserInfo.getOrganizationName());
			List<StaticResource> sr = [SELECT Id FROM StaticResource WHERE Name = 'CompanyLogo' LIMIT 1];
			returnMap.put('hasCompanyLogo', !sr.isEmpty());
			if (inMap.containsKey('accountId') && inMap.get('accountId') != null) {
				try {
					Id accountId = (Id)inMap.get('accountId');
					Account acc = [SELECT Name, AccountNumber FROM Account WHERE Id = :accountId LIMIT 1];
					returnMap.put('customerName', acc.Name);
					returnMap.put('customerNumber', acc.AccountNumber);
				} catch (Exception e) {
					System.debug('Could not retrieve Account details for Excel generation. Error: ' + e.getMessage());
				}
			}
			returnMap.put('statementDate', Date.today());
			return returnMap;
		}
		//-- FIN-8540 | Changed by Ravi | 15-Jun-2026 | End --//

		if(inMap.containsKey('isConsolidated') && (Boolean)inMap.get('isConsolidated')){
			List<Object> listOfStep = (List<Object>)inMap.get('listOfStep');
			List<Object> columnList = (List<Object>)inMap.get(listOfStep.get(listOfStep.size() - 1)+'columns');
			List<Object> childObjectIdsObj = (List<Object>)inMap.get('childObjectIds');
			Map<String,String> fieldDataTypeMap = new Map<String,String>();
			List<Id> childObjectIds = new List<Id>();
			if (childObjectIdsObj != null) {
				for (Object obj : childObjectIdsObj) {
					if (obj != null) {
						childObjectIds.add((Id)obj);
					}
				}
			}
			List<String> columns = new List<String>();
			String childObjectName = (String)inMap.get('childObjAPIName');
			for (Object col : columnList) {
				Map<Object, Object> colMap = (Map<Object, Object>)col;
				String fieldName = (String)colMap.get('fieldName');
				columns.add(fieldName);
				system.debug(childObjectName+'::'+fieldName);
				system.debug(UtilityController.getfieldDataType(childObjectName, fieldName));
				fieldDataTypeMap.put(fieldName, UtilityController.getfieldDataType(childObjectName, fieldName));
			}
			system.debug(fieldDataTypeMap);
			Boolean isMultiCurrencyEnabled = Schema.sObjectType.Account.fields.getMap().containsKey('CurrencyIsoCode');
			if(isMultiCurrencyEnabled && !columns.contains('CurrencyIsoCode')) {
				columns.add('CurrencyIsoCode'); 
			}
			String fields = String.join(columns, ', ');

			String query = 'SELECT ' + fields + ' FROM ' + childObjectName + ' WHERE Id IN :childObjectIds';
			
			List<SObject> childObjRecord = Database.query(query);
			returnMap.put('columns', columnList);
			returnMap.put('fieldDataTypeMap', fieldDataTypeMap);
			returnMap.put('data', childObjRecord);
			returnMap.put('listOfStep',listOfStep);

			// ✅ Add group total title from inMap
			if (!listOfStep.isEmpty())  {
				String firstStep = (String)listOfStep[0];
				if (inMap.containsKey(firstStep + 'totalTitle')) {
					returnMap.put('listOfStep', listOfStep);
					returnMap.put(firstStep + 'totalTitle', inMap.get(firstStep + 'totalTitle'));
					returnMap.put(firstStep + 'aggregationField', inMap.get(firstStep + 'aggregationField'));
					returnMap.put(firstStep + 'showTotal', inMap.get(firstStep + 'showTotal'));
				}
			}
		} else {
			returnMap = returnGridData(inMap);
		}
		returnMap.put('orgName', UserInfo.getOrganizationName());
		List<StaticResource> sr = [SELECT Id FROM StaticResource WHERE Name = 'CompanyLogo' LIMIT 1];
        returnMap.put('hasCompanyLogo', !sr.isEmpty());
		//--Start | FIN-9250 | Changed by Dhwanil | 18-Feb-2026 --//
		returnMap.put('LOCALE', UserInfo.getLocale());
		//--End | FIN-9250 | Changed by Dhwanil | 18-Feb-2026 --//
		if (inMap.containsKey('accountId') && inMap.get('accountId') != null) {
			Id accountId = (Id)inMap.get('accountId');
			try {
				Account acc = [SELECT Name, AccountNumber FROM Account WHERE Id = :accountId LIMIT 1];
				returnMap.put('customerName', acc.Name);
				returnMap.put('customerNumber', acc.AccountNumber);
			} catch (Exception e) {
				System.debug('Could not retrieve Account details for Excel generation. Error: ' + e.getMessage());
			}
			//-- Start | FIN-9041 | Chanegs by Asera 02-Feb-2026--//
			if(inMap.containsKey('attachmentTemplate') && inMap.get('attachmentTemplate') != null){
				try{
					String templateName = (String)inMap.get('attachmentTemplate');
					String staticFolder = inMap.containsKey('attachmentTemplateFolder') ? (String)inMap.get('attachmentTemplateFolder') : null;
					String folderRefField = inMap.containsKey('attachmentTemplateFolderRefField') ? (String)inMap.get('attachmentTemplateFolderRefField') : null;
					String targetFolderName = null;

					if(String.isNotBlank(folderRefField)){
						String queryString = 'SELECT ' + String.escapeSingleQuotes(folderRefField) + ' FROM Account WHERE Id=:accountId';
						try {
							List<Account> accList = Database.query(queryString);
							if (!accList.isEmpty()) {
								Object dynamicFolderObj = accList.get(0).get(folderRefField);
								if(dynamicFolderObj != null) {
									String dynamicFolder = String.valueOf(dynamicFolderObj);
									if(String.isNotBlank(dynamicFolder)){
										targetFolderName = dynamicFolder;
									}
								}
							}
						} catch(Exception e) {
							System.debug('Error querying dynamic folder: ' + e.getMessage());
						}
					}
					
					// If Dynamic failed or was skipped, use Static
					if(String.isBlank(targetFolderName) && String.isNotBlank(staticFolder)){
						targetFolderName = staticFolder;
					}

					List<EmailTemplate> emailTemplateList = new List<EmailTemplate>();
					if(String.isNotBlank(targetFolderName)){
						emailTemplateList = [SELECT Id,Subject,HtmlValue,Body FROM EmailTemplate WHERE Name=:templateName AND Folder.Name=:targetFolderName AND IsActive = TRUE WITH SECURITY_ENFORCED LIMIT 1];
					}
					
					// Fallback: Global search by Name only
					if(emailTemplateList.isEmpty()){
						emailTemplateList = [SELECT Id,Subject,HtmlValue,Body FROM EmailTemplate WHERE Name=:templateName AND IsActive = TRUE WITH SECURITY_ENFORCED LIMIT 1];
					}

					if(!emailTemplateList.isEmpty()){
						Messaging.SingleEmailMessage msg = Messaging.renderStoredEmailTemplate(emailTemplateList[0].Id,null,accountId);
						// << START - MM - FIN-9455 - Task -> Send Email -> Replace custom placeholders and translations >> 
						//  
						String attachmentHtmlBody = msg.getHtmlBody();
						if((inMap.containsKey('isConsolidated') && (Boolean)inMap.get('isConsolidated'))){
							System.debug('Fetched template body for attachment: ' + msg.getHtmlBody());
							if (attachmentHtmlBody.Contains('{Transactions.TotalOpenItems}') || attachmentHtmlBody.Contains('{Transactions.TotalOverdueItems}') || attachmentHtmlBody.Contains('{Transactions.TotalOverdueNotNotedItems}')) {
								List<Object> transIdObjects = (List<Object>)inMap.get('childObjectIds');
								List<String> transIds = new List<String>();
								for(Object transIdObject: transIdObjects) {
									transIds.add((String)transIdObject);
								}
								Map<String,String> returnTemplateAmount = UtilityController.getTransactionTotalSummary((String)inMap.get('Id'), transIds);
								attachmentHtmlBody = attachmentHtmlBody.replace('{Transactions.TotalBalance}', returnTemplateAmount.get('TotalBalance'));
								attachmentHtmlBody = attachmentHtmlBody.replace('{Transactions.TotalOpenItems}', returnTemplateAmount.get('TotalOpenItems'));
								attachmentHtmlBody = attachmentHtmlBody.replace('{Transactions.TotalOverdueItems}', returnTemplateAmount.get('TotalOverdueItems'));
								attachmentHtmlBody = attachmentHtmlBody.replace('{Transactions.TotalOverdueNotNotedItems}', returnTemplateAmount.get('TotalOverdueNotNotedItems'));
							}
						} else {
							String taskID = (String)inMap.get('Id');
							List<Task> listTask = [select id,Subject,OwnerId,Owner.Name,WhatId,What.Name,Priority,ActivityDate,celsrm__Treatment__c,Status, AccountId from task where id =: taskID];
							if(!listTask.isEmpty()) {
								ID treatmentId = listTask.get(0).celsrm__Treatment__c;
								List<celsrm__Treatment__c> listTreatment = [SELECT Id,celsrm__Related_Object__c,celsrm__Treatment_Steps__c,celsrm__Org_Id__c, celsrm__Consolidated_Treatment__c FROM celsrm__Treatment__c WHERE Id =:treatmentId ];
								if(!listTreatment.isEmpty()) {
									List<ObjectCriteria> listOfTreatmentStep =  (List<ObjectCriteria> ) JSON.deserialize(listTreatment.get(0).celsrm__Treatment_Steps__c, List<ObjectCriteria>.class);
									for (ObjectCriteria treStep: listOfTreatmentStep) {
										if(treStep.active){
											List<String> transIds = new List<String>();
											if(returnMap.keySet().contains(treStep.stepName)) {
												List<SObject> childObjRecords = (List<SObject>) returnMap.get(treStep.stepName);
												if(childObjRecords != null && !childObjRecords.isEmpty()){
													for(SObject childObjRecord: childObjRecords) {
														Id recordId = (Id) childObjRecord.get('Id');
														transIds.add((String)recordId);
													}
												}
											}
											Map<String,String> returnTemplateAmount = UtilityController.getTransactionTotalSummary((String)inMap.get('Id'), transIds);
											attachmentHtmlBody = attachmentHtmlBody.replace('{' + treStep.stepName + '.Transactions.TotalBalance}', returnTemplateAmount.get('TotalBalance'));
											attachmentHtmlBody = attachmentHtmlBody.replace('{' + treStep.stepName + '.Transactions.TotalOpenItems}', returnTemplateAmount.get('TotalOpenItems'));
											attachmentHtmlBody = attachmentHtmlBody.replace('{' + treStep.stepName + '.Transactions.TotalOverdueItems}', returnTemplateAmount.get('TotalOverdueItems'));
											attachmentHtmlBody = attachmentHtmlBody.replace('{' + treStep.stepName + '.Transactions.TotalOverdueNotNotedItems}', returnTemplateAmount.get('TotalOverdueNotNotedItems'));
										}
									}
								}
							}
						}
						Account acc = [SELECT Id , celsrm__Locale__c FROM Account WHERE Id = :accountId LIMIT 1];
						String accountLocale = acc.celsrm__Locale__c != null ? acc.celsrm__Locale__c : 'EN';
						attachmentHtmlBody = UtilityController.replaceCustomerSpecificPlaceholders(attachmentHtmlBody, accountLocale);
						returnMap.put('templateBody', attachmentHtmlBody);
						// << END - MM - FIN-9455 - Task -> Send Email -> Replace custom placeholders and translations >> 

						//-- Starts | FIN-9351 | Changed by Dhwanil | 03 Mar 2026 --//
						Map<String, String> imageMap = UtilityController.extractImagesAsBase64(msg.getHtmlBody());
						returnMap.put('templateBodyImageBase64Map', imageMap);
						//-- Ends | FIN-9351 | Changed by Dhwanil | 03 Mar 2026 --//
					}
				} catch(Exception e){
					System.debug('Template Fetch Error: '+e.getMessage());
				}
			}
			//-- End | FIN-9041 | Chanegs by Asera 02-Feb-2026--//
		}
		returnMap.put('statementDate', Date.today());
		//-- Start | FIN-9543 | Changed by Dhwanil | 06 April 2026 --//
		celsrm__SRM_Configuration__c systemConfig = celsrm__SRM_Configuration__c.getOrgDefaults();
		returnMap.put('attachmentFontFamily',systemConfig.celsrm__Attachment_Table_Font_Family__c);
		returnMap.put('attachmentFontSize',systemConfig.celsrm__Attachment_Table_Font_Size__c);
		//-- End | FIN-9543 | Changed by Dhwanil | 06 April 2026 --//
		return returnMap;
	}
	
	//-- FIN-8540 | Changed by Ravi | 15-Jun-2026 | Start --//
	//-- Start | AI Dunning - Helper Methods | Changed By User | Date --//
	private static AIDunningTemplateGeneration.DunningEmailResult resolveStaticTemplateForTask(celsrm__Treatment__c tr, Task taskRec) {
		AIDunningTemplateGeneration.DunningEmailResult result = new AIDunningTemplateGeneration.DunningEmailResult();
		String templateId = tr.celsrm__Email_Template__c;
		Id parentId = taskRec.WhatId;

		if (tr.celsrm__Enable_Dynamic_Template__c && String.isNotBlank(tr.celsrm__Template_Folder_Reference_Field__c) && String.isNotBlank(tr.celsrm__Email_Template_Prefix__c)) {
			String folderRefField = String.escapeSingleQuotes(tr.celsrm__Template_Folder_Reference_Field__c.trim());
			String folderQuery = 'SELECT ' + folderRefField + ' FROM Account WHERE Id = :parentId LIMIT 1';
			List<SObject> folderResults = Database.query(folderQuery);
			if (!folderResults.isEmpty() && folderResults[0].get(tr.celsrm__Template_Folder_Reference_Field__c.trim()) != null) {
				String folderName = String.valueOf(folderResults[0].get(tr.celsrm__Template_Folder_Reference_Field__c.trim()));
				String templatePrefix = tr.celsrm__Email_Template_Prefix__c + '%';
				List<EmailTemplate> matchingTemplates = [
					SELECT Id FROM EmailTemplate
					WHERE FolderName = :folderName AND Name LIKE :templatePrefix AND IsActive = true
					LIMIT 1
				];
				if (!matchingTemplates.isEmpty()) {
					templateId = matchingTemplates[0].Id;
				}
			}
		}

		if (String.isBlank(templateId)) {
			throw new AuraHandledException('No email template configured for treatment: ' + tr.Id);
		}

		List<Contact> contacts = [SELECT Id FROM Contact WHERE AccountId = :parentId AND celsrm__Default__c = true LIMIT 1];
		Id targetObjectId = !contacts.isEmpty() ? contacts[0].Id : parentId;

		Messaging.SingleEmailMessage rendered = Messaging.renderStoredEmailTemplate(templateId, targetObjectId, parentId);
		result.subject = rendered.getSubject();
		result.body = rendered.getHtmlBody();

		return result;
	}

	/**
	 * Returns simplified screen config for AI Dunning tasks
	 */
	private static Map<String, Object> getAiDunningScreenConfig(Task taskRecord, String taskID) {
		Map<String, Object> config = new Map<String, Object>();
		Map<String, Object> sectionConfig = new Map<String, Object>();
		List<Map<String, Object>> section = new List<Map<String, Object>>();
		List<Map<String, Object>> block = new List<Map<String, Object>>();
		// Check if multi-currency is enabled
		Boolean isMultiCurrencyEnabled = Schema.sObjectType.Account.fields.getMap().containsKey('CurrencyIsoCode');

		celsrm__Treatment__c treatment = [SELECT Id, celsrm__Attachment__c, celsrm__Attachment_Format__c, celsrm__Attachment_Name__c FROM celsrm__Treatment__c WHERE Id = :taskRecord.celsrm__Treatment__c LIMIT 1];
		
		// Build simplified block config
		Map<String, Object> blockConfig = new Map<String, Object>();
		blockConfig.put('name', 'AI Dunning Task Details');
		blockConfig.put('title', 'AI Dunning Task Details');
		blockConfig.put('isActive', true);
		blockConfig.put('hideTitle', false);
		blockConfig.put('readOnly', false);
		blockConfig.put('readOnlyCriteria', null);
		blockConfig.put('hide', false);
		blockConfig.put('hideCriteria', null);
		blockConfig.put('desktopWidth', 12);
		blockConfig.put('tabletWidth', 12);
		blockConfig.put('mobileWidth', 12);
		blockConfig.put('buttons', new List<String>());
		blockConfig.put('theme', new Map<String,String>());
		
		List<Map<String, Object>> fieldConfig = new List<Map<String, Object>>();
		
		// Assigned To field
		Map<String, Object> assignedToConfig = new Map<String, Object>();
		assignedToConfig.put('name', 'assignedTo');
		assignedToConfig.put('title', 'Assigned To');
		assignedToConfig.put('type', 'reference');
		assignedToConfig.put('isActive', true);
		assignedToConfig.put('hideTitle', false);
		assignedToConfig.put('dataSource', '');
		assignedToConfig.put('dataSourceName', '');
		assignedToConfig.put('columns', new List<String>());
		assignedToConfig.put('rowSize', 10);
		assignedToConfig.put('data', new List<String>());
		assignedToConfig.put('desktopWidth', 3);
		assignedToConfig.put('tabletWidth', 12);
		assignedToConfig.put('mobileWidth', 12);
		assignedToConfig.put('readOnly', true);
		assignedToConfig.put('readOnlyCriteria', null);
		assignedToConfig.put('hide', false);
		assignedToConfig.put('hideCriteria', null);
		assignedToConfig.put('required', false);
		assignedToConfig.put('requiredCriteria', null);
		assignedToConfig.put('hideLabel', false);
		assignedToConfig.put('onchange', '');
		assignedToConfig.put('helpText', '');
		fieldConfig.add(assignedToConfig);
		
		// Status field
		Map<String, Object> statusConfig = new Map<String, Object>();
		statusConfig.put('name', 'status');
		statusConfig.put('title', 'Status');
		statusConfig.put('type', 'text');
		statusConfig.put('isActive', true);
		statusConfig.put('hideTitle', false);
		statusConfig.put('maxLength', 255);
		statusConfig.put('desktopWidth', 3);
		statusConfig.put('tabletWidth', 12);
		statusConfig.put('mobileWidth', 12);
		statusConfig.put('default', '');
		statusConfig.put('readOnly', true);
		statusConfig.put('readOnlyCriteria', null);
		statusConfig.put('hide', false);
		statusConfig.put('hideCriteria', null);
		statusConfig.put('required', false);
		statusConfig.put('requiredCriteria', null);
		statusConfig.put('targetControlName', '');
		statusConfig.put('onchange', '');
		statusConfig.put('helpText', '');

		fieldConfig.add(statusConfig);
		
		// Subject field
		Map<String, Object> subjectConfig = new Map<String, Object>();
		subjectConfig.put('name', 'taskSubject');
		subjectConfig.put('title', 'Subject');
		subjectConfig.put('type', 'text');
		subjectConfig.put('isActive', true);
		subjectConfig.put('desktopWidth', 3);
		subjectConfig.put('tabletWidth', 12);
		subjectConfig.put('mobileWidth', 12);
		subjectConfig.put('default', '');
		subjectConfig.put('readOnly', true);
		subjectConfig.put('readOnlyCriteria', null);
		subjectConfig.put('hide', false);
		subjectConfig.put('hideCriteria', null);
		subjectConfig.put('required', false);
		subjectConfig.put('requiredCriteria', null);
		subjectConfig.put('targetControlName', '');
		subjectConfig.put('onchange', '');
		subjectConfig.put('helpText', '');
		fieldConfig.add(subjectConfig);
		
		// Name field (Task Name)
		// Map<String, Object> nameConfig = new Map<String, Object>();
		// nameConfig.put('name', 'name');
		// nameConfig.put('title', 'Name');
		// nameConfig.put('type', 'text');
		// nameConfig.put('isActive', true);
		// nameConfig.put('desktopWidth', 3);
		// nameConfig.put('tabletWidth', 12);
		// nameConfig.put('mobileWidth', 12);
		// nameConfig.put('readOnly', true);
		// nameConfig.put('readOnlyCriteria', null);
		// nameConfig.put('hide', false);
		// nameConfig.put('hideCriteria', null);
		// nameConfig.put('required', false);
		// nameConfig.put('requiredCriteria', null);
		// nameConfig.put('targetControlName', '');
		// nameConfig.put('onchange', '');
		// nameConfig.put('helpText', '');
		// fieldConfig.add(nameConfig);
		
		// Due Date field
		Map<String, Object> dueDateConfig = new Map<String, Object>();
		dueDateConfig.put('name', 'dueDate');
		dueDateConfig.put('title', 'Due Date');
		dueDateConfig.put('type', 'date');
		dueDateConfig.put('isActive', true);
		dueDateConfig.put('hideTitle', false);
		dueDateConfig.put('allowFutureDate', true);
		dueDateConfig.put('allowPastDate', true);
		dueDateConfig.put('desktopWidth', 3);
		dueDateConfig.put('tabletWidth', 12);
		dueDateConfig.put('mobileWidth', 12);
		dueDateConfig.put('readOnly', true);
		dueDateConfig.put('readOnlyCriteria', null);
		dueDateConfig.put('hide', false);
		dueDateConfig.put('hideCriteria', null);
		dueDateConfig.put('required', false);
		dueDateConfig.put('requiredCriteria', null);
		dueDateConfig.put('onchange', '');
		dueDateConfig.put('helpText', '');
		fieldConfig.add(dueDateConfig);
		
		// Related To (Account) field
		Map<String, Object> relatedToConfig = new Map<String, Object>();
		relatedToConfig.put('name', 'relatedTo');
		relatedToConfig.put('title', 'Account');
		relatedToConfig.put('type', 'reference');
		relatedToConfig.put('isActive', true);
		relatedToConfig.put('hideTitle', false);
		relatedToConfig.put('dataSource', '');
		relatedToConfig.put('dataSourceName', '');
		relatedToConfig.put('columns', new List<String>());
		relatedToConfig.put('rowSize', 10);
		relatedToConfig.put('data', new List<String>());
		relatedToConfig.put('desktopWidth', 3);
		relatedToConfig.put('tabletWidth', 12);
		relatedToConfig.put('mobileWidth', 12);
		relatedToConfig.put('default', new Map<String,String>()	);
		relatedToConfig.put('readOnly', true);
		relatedToConfig.put('readOnlyCriteria', null);
		relatedToConfig.put('hide', false);
		relatedToConfig.put('hideCriteria', null);
		relatedToConfig.put('required', false);
		relatedToConfig.put('requiredCriteria', null);
		relatedToConfig.put('hideLabel', false);
		relatedToConfig.put('onchange', '');
		relatedToConfig.put('helpText', '');


		fieldConfig.add(relatedToConfig);
		
		// Priority field
		Map<String, Object> priorityConfig = new Map<String, Object>();
		priorityConfig.put('name', 'priority');
		priorityConfig.put('title', 'Priority');
		priorityConfig.put('type', 'text');
		priorityConfig.put('isActive', true);
		priorityConfig.put('desktopWidth', 3);
		priorityConfig.put('tabletWidth', 12);
		priorityConfig.put('mobileWidth', 12);
		priorityConfig.put('readOnly', true);
		priorityConfig.put('readOnlyCriteria', null);
		priorityConfig.put('hide', false);
		priorityConfig.put('hideCriteria', null);
		priorityConfig.put('required', false);
		priorityConfig.put('requiredCriteria', null);
		priorityConfig.put('targetControlName', '');
		priorityConfig.put('onchange', '');
		priorityConfig.put('helpText', '');
		fieldConfig.add(priorityConfig);
		
		// Activity Currency field (if multi-currency enabled)
		if(isMultiCurrencyEnabled) {
			Map<String, Object> currencyConfig = new Map<String, Object>();
			currencyConfig.put('name', 'activityCurrency');
			currencyConfig.put('title', 'Activity Currency');
			currencyConfig.put('type', 'currency');
			currencyConfig.put('isActive', true);
			currencyConfig.put('hideTitle', false);
		    currencyConfig.put('maxLength', 16);
			currencyConfig.put('decimalPlaces', 0);
			currencyConfig.put('desktopWidth', 3);
			currencyConfig.put('tabletWidth', 12);
			currencyConfig.put('mobileWidth', 12);
			currencyConfig.put('readOnly', true);
			currencyConfig.put('readOnlyCriteria', null);
			currencyConfig.put('hide', false);
			currencyConfig.put('hideCriteria', null);
			currencyConfig.put('required', false);
			currencyConfig.put('requiredCriteria', null);
			currencyConfig.put('onchange', '');
			currencyConfig.put('helpText', '');
			fieldConfig.add(currencyConfig);
		}
		// AI Dunning identifier field
		Map<String, Object> aiDunningConfig = new Map<String, Object>();
		aiDunningConfig.put('name', 'isAiDunning');
		aiDunningConfig.put('title', 'AI Dunning');
		aiDunningConfig.put('type', 'boolean');
		aiDunningConfig.put('isActive', true);
		aiDunningConfig.put('hideTitle', false);
		aiDunningConfig.put('desktopWidth', 3);
		aiDunningConfig.put('tabletWidth', 12);
		aiDunningConfig.put('mobileWidth', 12);
		aiDunningConfig.put('default', true);
		aiDunningConfig.put('readOnly', true);
		aiDunningConfig.put('readOnlyCriteria', null);
		aiDunningConfig.put('hide', false);
		aiDunningConfig.put('hideCriteria', null);
		aiDunningConfig.put('required', false);
		aiDunningConfig.put('requiredCriteria', null);
		aiDunningConfig.put('targetControlName', '');
		aiDunningConfig.put('onchange', '');
		aiDunningConfig.put('helpText', '');
		fieldConfig.add(aiDunningConfig);
		// Dunning Strategy Reasoning field
		Map<String, Object> reasoningConfig = new Map<String, Object>();
		reasoningConfig.put('name', 'dunningStrategyReasoning');
		reasoningConfig.put('title', 'Dunning Strategy Reasoning');
		reasoningConfig.put('type', 'textarearich');
		reasoningConfig.put('isActive', true);
		reasoningConfig.put('hideTitle', false);
		reasoningConfig.put('labelvisible', false);
		reasoningConfig.put('maxLength', 5000);
		reasoningConfig.put('maxLine', 3);
		reasoningConfig.put('height', 264);
		reasoningConfig.put('desktopWidth', 12);
		reasoningConfig.put('tabletWidth', 12);
		reasoningConfig.put('mobileWidth', 12);
		reasoningConfig.put('readOnly', true);
		reasoningConfig.put('readOnlyCriteria', null);
		reasoningConfig.put('hide', false);
		reasoningConfig.put('hideCriteria', null);
		reasoningConfig.put('required', false);
		reasoningConfig.put('requiredCriteria', null);
		reasoningConfig.put('onchange', '');
		reasoningConfig.put('helpText', '');
		fieldConfig.add(reasoningConfig);

		
		
		// Add fields block
		blockConfig.put('fields', fieldConfig);
		block.add(blockConfig);

		// Add AI Transactions grid block
		Map<String, Object> gridBlock = new Map<String, Object>(blockConfig);
		gridBlock.put('name', 'aiTransactionsBlock');
		gridBlock.put('title', 'Transactions');
		gridBlock.put('hide', false);
		gridBlock.put('hideCriteria', JSON.deserializeUntyped('{ "rules": [{ "condition": "==", "criteriagroup": null, "field": { "type": "text", "ReferenceTo": "", "picklistVal": "", "label": "aiTransactionsBlockShow", "name": "aiTransactionsBlockShow", "value": "true" } }], "operator": "&&" }'));
		List<Map<String, Object>> gridFields = new List<Map<String, Object>>();
		Map<String, Object> gridConfig = new Map<String, Object>();
		gridConfig.put('name', 'aiTransactions');
		gridConfig.put('title', 'Transactions');
		gridConfig.put('type', 'datagrid');
		gridConfig.put('isActive', true);
		gridConfig.put('hideTitle', true);
		gridConfig.put('dataSource', '');
		gridConfig.put('dataSourceName', '');
		gridConfig.put('hide', false);
		gridConfig.put('hideCriteria', null);
		gridConfig.put('desktopWidth', 12);
		gridConfig.put('tabletWidth', 12);
		gridConfig.put('mobileWidth', 12);
		gridConfig.put('cellcolor', new List<String>());
		gridConfig.put('columns', new List<String>());
		gridConfig.put('rowcolor', new List<String>());
		gridConfig.put('keyfield', 'Id');
		gridConfig.put('disablepagination', false);
		gridConfig.put('rowSize', 10);
		gridConfig.put('hideCheckbox', false);
		gridConfig.put('showRowNumber', false);
		gridConfig.put('sortedBy', '');
		gridConfig.put('defaultSortDirection', 'desc');
		gridConfig.put('enableInfiniteLoading', false);
		gridConfig.put('loadMoreOffset', 1);
		gridConfig.put('isLoading', false);
		gridConfig.put('maxRowSelection', 100);
		gridConfig.put('multiSelect', false);
		gridConfig.put('orderBy', '');
		gridConfig.put('isSearchable', false);
		gridConfig.put('exportExcel', true);
		gridConfig.put('enableAdvanceSearch', false);
		gridConfig.put('onchange', '');
		gridConfig.put('helpText', '');
		gridFields.add(gridConfig);
		gridBlock.put('fields', gridFields);
		block.add(gridBlock);
		
		sectionConfig.put('name', '');
		sectionConfig.put('title', '');
		sectionConfig.put('isActive', true);
		sectionConfig.put('hideTitle', true);
		sectionConfig.put('hide', false);
		sectionConfig.put('hideCriteria', null);
		sectionConfig.put('desktopWidth', 12);
		sectionConfig.put('tabletWidth', 12);
		sectionConfig.put('mobileWidth', 12);
		sectionConfig.put('blocks', block);
		sectionConfig.put('dataServices', new List<String>());
		sectionConfig.put('theme', new Map<String, String>());
		section.add(sectionConfig);
		

		// Build action list with CTAs similar to regular treatment screen
		List<Map<String, Object>> actionList = new List<Map<String, Object>>();
		Map<String, Object> tempAction = new Map<String, Object>();
		
		// Edit action
		tempAction.put('name', 'Edit');
		tempAction.put('title', 'Edit');
		tempAction.put('dataSource', 'newScreen');
		tempAction.put('dataSourceName', 'EditTaskForTreatmentRule');
		tempAction.put('iconName', 'utility:edit');
		tempAction.put('screenSize', 'small-width');
		tempAction.put('targetScreenAlignemnt', 'center-screen');
		tempAction.put('active', true);
		tempAction.put('activeCriteria', JSON.deserializeUntyped('{"rules":[{"condition":"==","criteriagroup":null,"field":{"type":"text","ReferenceTo":"","picklistVal":"","label":"showAction","name":"showAction","value":"true"}}],"operator":"&&"}'));
		// tempAction.put('selectIcon', false);
		// tempAction.put('iconClassMap', false);
		// tempAction.put('label', '');
		Map<String, Object> editAction = new Map<String, Object>(tempAction);
		actionList.add(editAction);
		
		if (taskRecord.Status != 'Completed') {
			tempAction.put('name', 'SendEmail');
			tempAction.put('title', 'Send Email');
			tempAction.put('dataSource', 'staticResourceFunctionName');
			tempAction.put('dataSourceName', 'openSendEMailScreen');
			tempAction.put('iconName', 'utility:email');
			tempAction.put('screenSize', 'large-width');
			tempAction.put('active', true);
			tempAction.put('activeCriteria', JSON.deserializeUntyped('{"rules":[{"condition":"==","criteriagroup":null,"field":{"type":"text","ReferenceTo":"","picklistVal":"","label":"showAction","name":"showAction","value":"true"}}],"operator":"&&"})'));
			tempAction.put('selectIcon', false);
			tempAction.put('iconClassMap', false);
			tempAction.put('label', '');

			Map<String,Object> sendEmailAction = new Map<String,Object>(tempAction);
			actionList.add(sendEmailAction);
		}
		
		// Build variables
		List<Map<String, Object>> variables = new List<Map<String, Object>>();
		Map<String, Object> showActionVar = new Map<String, Object>();
		showActionVar.put('name', 'showAction');
		showActionVar.put('value', 'false');
		variables.add(showActionVar);

		Map<String, Object> isAttachmentVar = new Map<String, Object>();
		isAttachmentVar.put('name', 'isAttachment');
		isAttachmentVar.put('value', String.valueOf(treatment.celsrm__Attachment__c));
		variables.add(isAttachmentVar);

		Map<String, Object> attachmentFormatVar = new Map<String, Object>();
		attachmentFormatVar.put('name', 'attachmentFormat');
		attachmentFormatVar.put('value', String.valueOf(treatment.celsrm__Attachment_Format__c != null ? treatment.celsrm__Attachment_Format__c : ''));
		variables.add(attachmentFormatVar);

		Map<String, Object> attachmentNameVar = new Map<String, Object>();
		attachmentNameVar.put('name', 'attachmentName');
		attachmentNameVar.put('value', String.valueOf(treatment.celsrm__Attachment_Name__c != null ? treatment.celsrm__Attachment_Name__c : ''));
		variables.add(attachmentNameVar);

		config.put('name', taskRecord.Subject);
		config.put('title', taskRecord.Subject);
		config.put('type', 'screen');
		config.put('titleValue', '{value.accountName}');
		config.put('hideTitle', false);
		config.put('titleIcon', 'standard:task');
		config.put('isWizard', false);
		config.put('showSaveAndNext', false);
		config.put('isActive', true);
		config.put('staticResource', 'TaskDetail');
		config.put('saveRedirection', new Map<String, String>());
		config.put('cancelRedirection', new Map<String, String>());
		config.put('submitProperties', new Map<String, String>());
		config.put('actions', actionList);
		config.put('dataServices', new List<String>());
		config.put('submitDataServices', new List<String>());
		config.put('submitDataServicesOperation', '');
		config.put('variables', variables);
		config.put('sections', section);
		config.put('searchscreen', new List<String>());
		config.put('messages', new List<String>());
		config.put('successMessage', '');
		config.put('isSObject', false);
		config.put('sObject', '');
		config.put('sObjectMode', '');
		config.put('showEditButton', false);
		config.put('profile', '');
		config.put('onLoadFunction', 'onPageLoadSetView');
		config.put('theme', new Map<String, String>());
		config.put('enableSubmitButton', true);
		
		return config;
	}
	
	/**
	 * Returns simplified grid data for AI Dunning tasks
	 */
	private static Map<Object, Object> getAiDunningGridData(Task taskRecord, Map<Object, Object> inMap) {
		Map<Object, Object> resultMap = new Map<Object, Object>();
		celsrm__AI_Configuration__c orgSetting = celsrm__AI_Configuration__c.getOrgDefaults();
		// String emailTemplate = orgSetting != null ? orgSetting.AI_Dunning_Email_Template__c : null;
		resultMap.put('isAiDunning', taskRecord.AiDunning__c);
		resultMap.put('showAction', inMap.get('showAction'));
		resultMap.put('accountId', taskRecord.WhatId);
		// resultMap.put('emailTemplate', emailTemplate);
		// Get Account details - query Task with What relationship
		Task taskWithRelations = [SELECT Id, WhatId, What.Name, OwnerId, Owner.Name, 
								   AccountId, Account.CurrencyIsoCode 
								   FROM Task WHERE Id = :taskRecord.Id LIMIT 1];
		
		Boolean isMultiCurrencyEnabled = Schema.sObjectType.Account.fields.getMap().containsKey('CurrencyIsoCode');
		String accountName = taskWithRelations.What != null ? String.valueOf(taskWithRelations.What.get('Name')) : null;
		String currencyIso = null;
		
		if(isMultiCurrencyEnabled && taskWithRelations.Account != null) {
			currencyIso = String.valueOf(taskWithRelations.Account.get('CurrencyIsoCode'));
		}
		
		// Get Owner details from relationship
		String ownerName = taskWithRelations.Owner != null ? String.valueOf(taskWithRelations.Owner.get('Name')) : null;
		
		// Set basic task fields
		resultMap.put('taskSubject', taskRecord.Subject);
		resultMap.put('priority', taskRecord.Priority);
		resultMap.put('dueDate', taskRecord.ActivityDate);
		resultMap.put('status', taskRecord.Status);
		
		// Set assignedTo
		if(taskRecord.OwnerId != null && ownerName != null) {
			Map<String, String> ownerMap = new Map<String, String>();
			ownerMap.put('id', taskRecord.OwnerId);
			ownerMap.put('name', ownerName);
			resultMap.put('assignedTo', ownerMap);
		}
		
		// Set relatedTo (Account)
		if(taskRecord.WhatId != null && accountName != null) {
			Map<String, String> accountMap = new Map<String, String>();
			accountMap.put('id', taskRecord.WhatId);
			accountMap.put('name', accountName);
			resultMap.put('relatedTo', accountMap);
			resultMap.put('accountName', accountName);
			resultMap.put('accountId', taskRecord.WhatId);
		}
		
		// Set Name (Task Name)
		resultMap.put('name', taskRecord.Subject);
		
		// Set Activity Currency
		if(isMultiCurrencyEnabled && currencyIso != null) {
			resultMap.put('activityCurrency', currencyIso);
		} else if(!isMultiCurrencyEnabled) {
			resultMap.put('activityCurrency', UserInfo.getDefaultCurrency());
		}
		
		// Get Dunning Strategy Reasoning from attached file
		String dunningStrategyReasoning = String.valueOf(getTaskJsonData(taskRecord.Id).get('dunningStrategyReasoning'));
		resultMap.put('dunningStrategyReasoning', dunningStrategyReasoning);
		resultMap.put('aiDunning', true);

		// Populate transactions grid data from AI Dunning attachment
		Map<String, Object> aiPayload = getTaskJsonData(taskRecord.Id);
		System.debug('aiPayload: ' + aiPayload);
		//if(aiPayload != null && aiPayload.containsKey('eligibleTransactionIds')
		if(aiPayload != null) {
			List<Id> txnIds = new List<Id>();
			if(aiPayload.containsKey('eligibleTransactionIds')) {
				List<Object> rawIds = (List<Object>)aiPayload.get('eligibleTransactionIds');
				if(rawIds != null) {
					for(Object obj : rawIds) {
						if(obj != null) {
							try {
								String idStr = String.valueOf(obj);
								if(!String.isBlank(idStr)) {
									txnIds.add(Id.valueOf(idStr));
								}
							} catch (Exception e) {
								System.debug('Skipping non-Id value in eligibleTransactionIds: ' + obj);
							}
						}
					}
				}
			}
			Map<Id, String> reasonMap = new Map<Id, String>();
			if(aiPayload.containsKey('reasonMappingForTransactionIds')) {
				Map<String, Object> rawReasonMap = (Map<String, Object>)aiPayload.get('reasonMappingForTransactionIds');
				if(rawReasonMap != null) {
					for(String keyStr : rawReasonMap.keySet()) {
						if(String.isNotBlank(keyStr)) {
							try {
								Id keyId = Id.valueOf(keyStr);
								reasonMap.put(keyId, String.valueOf(rawReasonMap.get(keyStr)));
							} catch (Exception e) {
								System.debug('Skipping non-Id key in reasonMappingForTransactionIds: ' + keyStr);
							}
						}
					}
				}
			}
            System.debug('txnIDs List'+ txnIds);
			if(!txnIds.isEmpty()) {
				celsrm__Treatment__c treatment = [SELECT Id, celsrm__Transaction_Table_Columns__c FROM celsrm__Treatment__c WHERE Id = :taskRecord.celsrm__Treatment__c LIMIT 1];
				String txnTableColumns = treatment.celsrm__Transaction_Table_Columns__c;
				List<String> columnListRaw = (txnTableColumns != null && txnTableColumns != '') ? txnTableColumns.split(',') : new List<String>{ 'Name', 'Balance__c', 'DPD__c', 'Last_Contact_Date__c' };
				List<String> columnList = new List<String>();
				for (String c : columnListRaw) {
					String trimmed = c.trim();
					if (String.isNotBlank(trimmed)) {
						columnList.add(trimmed);
					}
				}

				Map<String, Schema.SObjectField> fMap = Schema.SObjectType.celsrm__Transaction__c.fields.getMap();
				Set<String> queryFieldSet = new Set<String>{ 'Id' };
				for (String col : columnList) {
					if (fMap.containsKey(col.toLowerCase())) {
						queryFieldSet.add(col);
					}
				}
				if (isMultiCurrencyEnabled && !queryFieldSet.contains('CurrencyIsoCode')) {
					queryFieldSet.add('CurrencyIsoCode');
				}
				List<String> queryFields = new List<String>(queryFieldSet);
				String soql = 'SELECT ' + String.join(queryFields, ', ') + ' FROM celsrm__Transaction__c WHERE Id IN :txnIds';
				System.debug('Dynamic txn columns: ' + columnList);
				System.debug('Dynamic txn SOQL: ' + soql);
				List<SObject> txns = Database.query(soql);

				List<Map<String, Object>> columns = new List<Map<String, Object>>();
				for (String col : columnList) {
					String colLower = col.toLowerCase();
					if (!fMap.containsKey(colLower)) continue;
					Schema.DescribeFieldResult fd = fMap.get(colLower).getDescribe();
					String fieldType = fd.getType().name();
					String colType = 'text';
					if (fieldType == 'CURRENCY' ) colType = 'currency';
					else if (fieldType == 'INTEGER' || fieldType == 'LONG' || fieldType == 'DOUBLE') colType = 'number';
					else if (fieldType == 'DATE' || fieldType == 'DATETIME') colType = 'date';
					else if (colLower == 'name') colType = 'html';
					columns.add(buildColumn(fd.getLabel(), col, colType, true));
				}
				if (isMultiCurrencyEnabled && !columnList.contains('CurrencyIsoCode')) {
					columns.add(buildColumn('Currency', 'CurrencyIsoCode', 'text', true));
				}
				columns.add(buildColumn('Reason', 'Reason', 'text', false));

				List<Map<String, Object>> rows = new List<Map<String, Object>>();
				for (SObject t : txns) {
					Map<String, Object> row = new Map<String, Object>();
					row.put('Id', (Id)t.get('Id'));
					for (String col : columnList) {
						if (fMap.containsKey(col.toLowerCase())) {
							row.put(col, t.get(col));
						}
					}
					if (isMultiCurrencyEnabled) {
						row.put('CurrencyIsoCode', t.get('CurrencyIsoCode'));
					}
					row.put('Reason', reasonMap.containsKey((Id)t.get('Id')) ? reasonMap.get((Id)t.get('Id')) : '');
					rows.add(row);
				}

				System.debug('gridZData:' + rows);
				resultMap.put('aiTransactionscolumns', columns);
				resultMap.put('aiTransactions', rows);
				resultMap.put('aiTransactionsBlockShow', 'true');
			} else {
				// Even if no transactions, set empty arrays to ensure grid renders
				resultMap.put('aiTransactionscolumns', new List<Map<String, Object>>());
				resultMap.put('aiTransactions', new List<Map<String, Object>>());
				resultMap.put('aiTransactionsBlockShow', 'false');
			}
		} else {
			// If no payload, set empty arrays
			resultMap.put('aiTransactionscolumns', new List<Map<String, Object>>());
			resultMap.put('aiTransactions', new List<Map<String, Object>>());
			resultMap.put('aiTransactionsBlockShow', 'false');
		}
				
		
		System.debug('resultMap.>> ' + resultMap);
		return resultMap;
	}
	
	private static Map<String, Object> getTaskJsonData(String taskId) {

		Map<String,Object> emptyData = new Map<String, Object>();

		try {
			// Find ContentDocument linked to this task
			List<ContentDocumentLink> listContentDL = [
				SELECT ContentDocumentId 
				FROM ContentDocumentLink 
				WHERE LinkedEntityId = :taskId
			];

			System.debug('listContentDL.>> ' + listContentDL);
			
			if(listContentDL.isEmpty()) {
				return emptyData;
			}
			
			Set<Id> conDocIds = new Set<Id>();
			for(ContentDocumentLink conDL : listContentDL) {
				conDocIds.add(conDL.ContentDocumentId);
			}
			
			System.debug('conDocIds.>> ' + conDocIds);
			// Get the latest ContentVersion
			List<ContentVersion> listContentVer = [
				SELECT VersionData 
				FROM ContentVersion 
				WHERE ContentDocumentId IN :conDocIds AND ContentDocument.Title = 'AI Dunning Task Data'
				AND IsLatest = true
				LIMIT 1
			];
			
			if(listContentVer.isEmpty() || listContentVer.get(0).VersionData == null) {
				return emptyData;
			}
			
			// Parse JSON and extract dunningStrategyReasoning
			String jsonData = listContentVer.get(0).VersionData.toString();
			Map<String, Object> jsonMap = (Map<String, Object>) JSON.deserializeUntyped(jsonData);

			System.debug('jsonMap.>> ' + jsonMap);
			System.debug('eligTxnIds' + jsonMap.get('eligibleTransactionIds'));
			
			return jsonMap;
			
		} catch (Exception e) {
			System.debug('Error reading Dunning Strategy Reasoning: ' + e.getMessage());
			return emptyData;
		}
	}


	private static Map<String, Object> buildColumn(String label, String fieldName, String type, Boolean sortable) {
		Map<String, Object> col = new Map<String, Object>();
		col.put('label', label);
		col.put('fieldName', fieldName);
		col.put('type', type);
		col.put('sortable', sortable);
		return col;
	}
	//-- FIN-8540 | Changed by Ravi | 15-Jun-2026 | End --//
	//-- FIN-9747 | Changed by Dilshad | 12-May-2026 | Start --//
	@AuraEnabled
	public static Map<Object, Object> getPreDataForPDFAttachment(Map<Object, Object> inMap) {
		Map<Object, Object> returnMap = new Map<Object, Object>();
		List<Object> listOfStep = inMap.get('listOfStep') != null ? (List<Object>)inMap.get('listOfStep') : new List<Object>();
		Map<String, List<Id>> stepToRecIds = getOrderedStepToRecordIds(inMap, listOfStep);
		String childObjectName = resolveAttachmentChildObjectName(inMap);
		Schema.SObjectType childObjectType = getSObjectTypeByName(childObjectName);
		Map<String, Schema.SObjectField> childFieldMap = childObjectType == null ? new Map<String, Schema.SObjectField>() : childObjectType.getDescribe().fields.getMap();
		Boolean isMultiCurrencyEnabled = Schema.sObjectType.Account.fields.getMap().containsKey('CurrencyIsoCode');
		Boolean isConsolidated = inMap.containsKey('isConsolidated') && Boolean.valueOf(String.valueOf(inMap.get('isConsolidated')));

		if (isConsolidated) {
			String consolidatedStep = listOfStep.isEmpty() ? null : String.valueOf(listOfStep.get(listOfStep.size() - 1));
			List<Object> columnList = String.isBlank(consolidatedStep) || !inMap.containsKey(consolidatedStep + 'columns') || inMap.get(consolidatedStep + 'columns') == null
				? new List<Object>()
				: (List<Object>)inMap.get(consolidatedStep + 'columns');
			List<String> queryColumns = getAttachmentQueryColumns(inMap, consolidatedStep, childFieldMap, isMultiCurrencyEnabled);
			List<Id> orderedRecordIds = new List<Id>();
			for (Object stepObj : listOfStep) {
				String step = String.valueOf(stepObj);
				if (stepToRecIds.containsKey(step) && stepToRecIds.get(step) != null) {
					orderedRecordIds.addAll(stepToRecIds.get(step));
				}
			}

			List<SObject> orderedRecords = new List<SObject>();
			if (!orderedRecordIds.isEmpty() && String.isNotBlank(childObjectName) && !queryColumns.isEmpty()) {
				Set<Id> orderedIdSet = new Set<Id>(orderedRecordIds);
				String query = 'SELECT ' + String.join(queryColumns, ', ') + ' FROM ' + childObjectName + ' WHERE Id IN :orderedIdSet';
				Map<Id, SObject> recordMap = new Map<Id, SObject>(Database.query(query));
				for (Id recordId : orderedRecordIds) {
					if (recordMap.containsKey(recordId)) {
						orderedRecords.add(recordMap.get(recordId));
					}
				}
			}

			returnMap.put('columns', columnList);
			returnMap.put('data', orderedRecords);
			returnMap.put('listOfStep', listOfStep);
			if (!listOfStep.isEmpty()) {
				String firstStep = String.valueOf(listOfStep.get(0));
				if (inMap.containsKey(firstStep + 'totalTitle')) {
					returnMap.put(firstStep + 'totalTitle', inMap.get(firstStep + 'totalTitle'));
					returnMap.put(firstStep + 'aggregationField', inMap.get(firstStep + 'aggregationField'));
					returnMap.put(firstStep + 'showTotal', inMap.get(firstStep + 'showTotal'));
				}
			}
		} else {
			for (Object stepObj : listOfStep) {
				String step = String.valueOf(stepObj);
				List<Id> orderedIds = stepToRecIds.containsKey(step) ? stepToRecIds.get(step) : new List<Id>();
				List<SObject> orderedRecords = new List<SObject>();

				if (!orderedIds.isEmpty() && String.isNotBlank(childObjectName)) {
					Set<Id> orderedIdSet = new Set<Id>(orderedIds);
					List<String> queryColumns = getAttachmentQueryColumns(inMap, step, childFieldMap, isMultiCurrencyEnabled);
					String query = 'SELECT ' + String.join(queryColumns, ', ') + ' FROM ' + childObjectName + ' WHERE Id IN :orderedIdSet';
					Map<Id, SObject> recordMap = new Map<Id, SObject>(Database.query(query));
					for (Id recordId : orderedIds) {
						if (recordMap.containsKey(recordId)) {
							orderedRecords.add(recordMap.get(recordId));
						}
					}
				}
				returnMap.put(step, orderedRecords);
			}
		}

		returnMap.put('listOfStep', listOfStep);
		returnMap.put('orgName', UserInfo.getOrganizationName());
		List<StaticResource> sr = [SELECT Id FROM StaticResource WHERE Name = 'CompanyLogo' LIMIT 1];
		returnMap.put('hasCompanyLogo', !sr.isEmpty());
		returnMap.put('LOCALE', UserInfo.getLocale());

		if (inMap.containsKey('accountId') && inMap.get('accountId') != null) {
			Id accountId = (Id)inMap.get('accountId');
			try {
				Account acc = [SELECT Name, AccountNumber FROM Account WHERE Id = :accountId LIMIT 1];
				returnMap.put('customerName', acc.Name);
				returnMap.put('customerNumber', acc.AccountNumber);
			} catch (Exception e) {
				System.debug('Could not retrieve Account details for PDF generation. Error: ' + e.getMessage());
			}

			// << START - MM - FIN-10130 - Task -> Send Email -> PDF Non Consolidated attachment: fetch the attachment
			// template body here (mirrors the working Excel flow in getPreDataForExcelFileGeneration) and resolve the
			// step-scoped {StepName.Transactions.TotalOpenItems}/TotalOverdueItems/TotalOverdueNotNotedItems/TotalBalance
			// tokens per treatment step, so the client can insert each step's table at its own
			// {StepName.Transaction.Summary} marker without going through the generic single-marker VF template merge >>
			if (!isConsolidated && inMap.containsKey('attachmentTemplate') && inMap.get('attachmentTemplate') != null) {
				try {
					String templateName = (String)inMap.get('attachmentTemplate');
					String staticFolder = inMap.containsKey('attachmentTemplateFolder') ? (String)inMap.get('attachmentTemplateFolder') : null;
					String folderRefField = inMap.containsKey('attachmentTemplateFolderRefField') ? (String)inMap.get('attachmentTemplateFolderRefField') : null;
					String targetFolderName = null;

					if (String.isNotBlank(folderRefField)) {
						String queryString = 'SELECT ' + String.escapeSingleQuotes(folderRefField) + ' FROM Account WHERE Id=:accountId';
						try {
							List<Account> accList = Database.query(queryString);
							if (!accList.isEmpty()) {
								Object dynamicFolderObj = accList.get(0).get(folderRefField);
								if (dynamicFolderObj != null) {
									String dynamicFolder = String.valueOf(dynamicFolderObj);
									if (String.isNotBlank(dynamicFolder)) {
										targetFolderName = dynamicFolder;
									}
								}
							}
						} catch (Exception e) {
							System.debug('Error querying dynamic folder: ' + e.getMessage());
						}
					}

					if (String.isBlank(targetFolderName) && String.isNotBlank(staticFolder)) {
						targetFolderName = staticFolder;
					}

					List<EmailTemplate> emailTemplateList = new List<EmailTemplate>();
					if (String.isNotBlank(targetFolderName)) {
						emailTemplateList = [SELECT Id, Subject, HtmlValue, Body FROM EmailTemplate WHERE Name = :templateName AND Folder.Name = :targetFolderName AND IsActive = TRUE WITH SECURITY_ENFORCED LIMIT 1];
					}
					if (emailTemplateList.isEmpty()) {
						emailTemplateList = [SELECT Id, Subject, HtmlValue, Body FROM EmailTemplate WHERE Name = :templateName AND IsActive = TRUE WITH SECURITY_ENFORCED LIMIT 1];
					}

					if (!emailTemplateList.isEmpty()) {
						Messaging.SingleEmailMessage msg = Messaging.renderStoredEmailTemplate(emailTemplateList[0].Id, null, accountId);
						String attachmentHtmlBody = msg.getHtmlBody();

						String taskID = (String)inMap.get('Id');
						if (String.isNotBlank(taskID)) {
							List<Task> listTask = [SELECT Id, celsrm__Treatment__c FROM Task WHERE Id = :taskID];
							if (!listTask.isEmpty()) {
								ID treatmentId = listTask.get(0).celsrm__Treatment__c;
								List<celsrm__Treatment__c> listTreatment = [SELECT Id, celsrm__Treatment_Steps__c FROM celsrm__Treatment__c WHERE Id = :treatmentId];
								if (!listTreatment.isEmpty()) {
									List<ObjectCriteria> listOfTreatmentStep = (List<ObjectCriteria>) JSON.deserialize(listTreatment.get(0).celsrm__Treatment_Steps__c, List<ObjectCriteria>.class);
									for (ObjectCriteria treStep : listOfTreatmentStep) {
										if (treStep.active) {
											List<String> transIds = new List<String>();
											if (returnMap.keySet().contains(treStep.stepName)) {
												List<SObject> childObjRecords = (List<SObject>) returnMap.get(treStep.stepName);
												if (childObjRecords != null && !childObjRecords.isEmpty()) {
													for (SObject childObjRecord : childObjRecords) {
														Id recordId = (Id) childObjRecord.get('Id');
														transIds.add((String)recordId);
													}
												}
											}
											Map<String, String> returnTemplateAmount = UtilityController.getTransactionTotalSummary(taskID, transIds);
											attachmentHtmlBody = attachmentHtmlBody.replace('{' + treStep.stepName + '.Transactions.TotalBalance}', returnTemplateAmount.get('TotalBalance'));
											attachmentHtmlBody = attachmentHtmlBody.replace('{' + treStep.stepName + '.Transactions.TotalOpenItems}', returnTemplateAmount.get('TotalOpenItems'));
											attachmentHtmlBody = attachmentHtmlBody.replace('{' + treStep.stepName + '.Transactions.TotalOverdueItems}', returnTemplateAmount.get('TotalOverdueItems'));
											attachmentHtmlBody = attachmentHtmlBody.replace('{' + treStep.stepName + '.Transactions.TotalOverdueNotNotedItems}', returnTemplateAmount.get('TotalOverdueNotNotedItems'));
										}
									}
								}
							}
						}

						Account accForLocale = [SELECT Id, celsrm__Locale__c FROM Account WHERE Id = :accountId LIMIT 1];
						String accountLocale = accForLocale.celsrm__Locale__c != null ? accForLocale.celsrm__Locale__c : 'EN';
						attachmentHtmlBody = UtilityController.replaceCustomerSpecificPlaceholders(attachmentHtmlBody, accountLocale);
						returnMap.put('templateBody', attachmentHtmlBody);
					}
				} catch (Exception e) {
					System.debug('PDF attachment template fetch/replace error: ' + e.getMessage());
				}
			}
			// << END - MM - FIN-10130 - Task -> Send Email -> PDF Non Consolidated attachment: fetch the attachment
		}

		returnMap.put('statementDate', Date.today());
		return returnMap;
	}
	//-- End | FIN-8209 | Changed By Dilshad | 13-Aug-2025 --//
	//-- Ends | FIN-6130 | Changed by Dilshad | 26 Jul 2024 --//
	//-- FIN-9729 | Changed by Dilshad | 07-May-2026 | Start --//
	@AuraEnabled
	public static Map<Object, Object> savePdfHtmlChunk(Map<Object, Object> inMap) {
		Map<Object, Object> returnMap = new Map<Object, Object>();
		try {
			if (inMap == null) {
				returnMap.put('ggErrorMessage', 'PDF HTML chunk data is required.');
				return returnMap;
			}
	
			String uploadToken = inMap.get('uploadToken') == null ? null : String.valueOf(inMap.get('uploadToken'));
			Integer chunkIndex;
			if (inMap.containsKey('chunkIndex') && inMap.get('chunkIndex') != null) {
				if (inMap.get('chunkIndex') instanceof Integer) {
					chunkIndex = (Integer)inMap.get('chunkIndex');
				} else {
					chunkIndex = Integer.valueOf(String.valueOf(inMap.get('chunkIndex')));
				}
			}
			String htmlChunk = inMap.get('htmlChunk') == null ? null : String.valueOf(inMap.get('htmlChunk'));
			returnMap.put(
				'prebuiltAttachmentHtmlKey',
				PDFAttachmentGeneratorController.saveStatementPdfTableHtmlChunk(uploadToken, chunkIndex, htmlChunk)
			);
		} catch (Exception ex) {
			returnMap.put('ggErrorMessage', ex.getMessage());
		}
		return returnMap;
	}

	@AuraEnabled
	public static Map<Object, Object> deletePdfTempChunks(Map<Object, Object> inMap) {
		if (inMap != null) {
			String tempKeyPrefix = null;
			if (inMap.containsKey('tempKeyPrefix') && inMap.get('tempKeyPrefix') != null) {
				tempKeyPrefix = String.valueOf(inMap.get('tempKeyPrefix'));
			} else if (inMap.containsKey('prebuiltAttachmentHtmlKey') && inMap.get('prebuiltAttachmentHtmlKey') != null) {
				tempKeyPrefix = String.valueOf(inMap.get('prebuiltAttachmentHtmlKey'));
			}
			PDFAttachmentGeneratorController.deleteStatementPdfTempChunks(tempKeyPrefix);
		}
		return new Map<Object, Object>();
	}

	@AuraEnabled
	public static Map<Object, Object> generatePDFAttachment(Map<Object, Object> inMap) {
		Map<Object, Object> returnMap = new Map<Object, Object>();
		String prebuiltAttachmentHtmlKey = inMap == null || !inMap.containsKey('prebuiltAttachmentHtmlKey')
			? null
			: String.valueOf(inMap.get('prebuiltAttachmentHtmlKey'));
		try {
			String accountId = inMap != null && inMap.get('accountId') != null
				? String.valueOf(inMap.get('accountId'))
				: inMap != null && inMap.get('Id') != null
					? String.valueOf(inMap.get('Id'))
					: null;
			if (String.isBlank(accountId)) {
				returnMap.put('ggErrorMessage', 'Account Id is required to generate the PDF attachment.');
				return returnMap;
			}
			if (String.isBlank(prebuiltAttachmentHtmlKey)) {
				returnMap.put('ggErrorMessage', 'PDF attachment HTML is required to generate the PDF attachment.');
				return returnMap;
			}

			String safeFileName = sanitizePdfAttachmentFileName(
				inMap != null && inMap.get('fileName') != null ? String.valueOf(inMap.get('fileName')) : 'TreatmentAttachment'
			);
			PageReference pRef = new PageReference('/apex/PDFAttachmentGenerator');
			pRef.getParameters().put('accountId', accountId);
			pRef.getParameters().put('fileName', safeFileName);
			pRef.getParameters().put('prebuiltAttachmentHtmlKey', prebuiltAttachmentHtmlKey);
			if (inMap != null && inMap.containsKey('renderWithAttachmentTemplate') && inMap.get('renderWithAttachmentTemplate') != null) {
				pRef.getParameters().put('renderWithAttachmentTemplate', String.valueOf(inMap.get('renderWithAttachmentTemplate')));
			}
			if (inMap != null && inMap.containsKey('attachmentTemplate') && inMap.get('attachmentTemplate') != null) {
				pRef.getParameters().put('attachmentTemplate', String.valueOf(inMap.get('attachmentTemplate')));
			}
			if (inMap != null && inMap.containsKey('attachmentTemplateFolder') && inMap.get('attachmentTemplateFolder') != null) {
				pRef.getParameters().put('attachmentTemplateFolder', String.valueOf(inMap.get('attachmentTemplateFolder')));
			}
			if (inMap != null && inMap.containsKey('attachmentTemplateFolderRefField') && inMap.get('attachmentTemplateFolderRefField') != null) {
				pRef.getParameters().put('attachmentTemplateFolderRefField', String.valueOf(inMap.get('attachmentTemplateFolderRefField')));
			}
			// << START - MM - FIN-10130 - Forward selected transaction/child record Ids so the PDF attachment can resolve
			// {Transactions.TotalOpenItems}/{Transactions.TotalOverdueItems}/{Transactions.TotalOverdueNotNotedItems} placeholders >>
			if (inMap != null && inMap.containsKey('childObjectIds') && inMap.get('childObjectIds') instanceof List<Object>) {
				List<String> transIdStrings = new List<String>();
				for (Object idObj : (List<Object>)inMap.get('childObjectIds')) {
					if (idObj != null) {
						transIdStrings.add(String.valueOf(idObj));
					}
				}
				if (!transIdStrings.isEmpty()) {
					pRef.getParameters().put('transIds', String.join(transIdStrings, ','));
				}
			}
			// << END - MM - FIN-10130 - Forward selected transaction/child record Ids so the PDF attachment can resolve

			Blob pdfBlob = Test.isRunningTest() ? Blob.valueOf('Unit Test PDF') : pRef.getContentAsPDF();
			ContentVersion contentVersion = new ContentVersion();
			contentVersion.Title = safeFileName;
			contentVersion.PathOnClient = '/' + safeFileName + '.pdf';
			contentVersion.VersionData = pdfBlob;
			Database.insert(contentVersion, Accesslevel.USER_MODE);

			returnMap.put('contentVersionId', contentVersion.Id);
		} catch (Exception ex) {
			System.debug('TaskTreatmentController.generatePDFAttachment error: ' + ex.getMessage());
			returnMap.put('ggErrorMessage', ex.getMessage());
		} finally {
			PDFAttachmentGeneratorController.deleteStatementPdfTempChunks(prebuiltAttachmentHtmlKey);
		}
		return returnMap;
	}

	private static String sanitizePdfAttachmentFileName(String fileName) {
		String safeFileName = PDFAttachmentGeneratorController.sanitizeStatementFileName(fileName);
		if (safeFileName != null && safeFileName.toLowerCase().endsWith('.pdf')) {
			safeFileName = safeFileName.substring(0, safeFileName.length() - 4);
		}
		return String.isBlank(safeFileName) ? 'TreatmentAttachment' : safeFileName;
	}
	//-- FIN-9729 | Changed by Dilshad | 07-May-2026 | End --//

	private static Map<String, List<Id>> getOrderedStepToRecordIds(Map<Object, Object> inMap, List<Object> listOfStep) {
		Map<String, List<Id>> stepToRecIds = new Map<String, List<Id>>();
		if (inMap == null) {
			return stepToRecIds;
		}

		if (inMap.containsKey('stepToRecIds') && inMap.get('stepToRecIds') != null) {
			Object rawStepToRecIds = inMap.get('stepToRecIds');
			if (rawStepToRecIds instanceof Map<Object, Object>) {
				Map<Object, Object> rawStepMap = (Map<Object, Object>)rawStepToRecIds;
				for (Object stepKeyObj : rawStepMap.keySet()) {
					String stepKey = String.valueOf(stepKeyObj);
					List<Id> orderedIds = new List<Id>();
					Object rawIds = rawStepMap.get(stepKeyObj);
					if (rawIds instanceof List<Object>) {
						for (Object idObj : (List<Object>)rawIds) {
							if (idObj != null) {
								orderedIds.add((Id)idObj);
							}
						}
					} else if (rawIds != null) {
						orderedIds.add((Id)rawIds);
					}
					if (!orderedIds.isEmpty()) {
						stepToRecIds.put(stepKey, orderedIds);
					}
				}
			}
		}

		if (!stepToRecIds.isEmpty()) {
			return stepToRecIds;
		}

		for (Object stepObj : listOfStep) {
			String step = String.valueOf(stepObj);
			if (inMap.containsKey(step) && inMap.get(step) != null) {
				List<Id> orderedIds = new List<Id>();
				for (Object rowObj : (List<Object>)inMap.get(step)) {
					Map<Object, Object> rowMap = (Map<Object, Object>)rowObj;
					if (!rowMap.containsKey('isSelected') || Boolean.valueOf(String.valueOf(rowMap.get('isSelected')))) {
						orderedIds.add((Id)rowMap.get('Id'));
					}
				}
				if (!orderedIds.isEmpty()) {
					stepToRecIds.put(step, orderedIds);
				}
			}
		}
		return stepToRecIds;
	}

	private static String resolveAttachmentChildObjectName(Map<Object, Object> inMap) {
		if (inMap == null) {
			return null;
		}
		if (inMap.containsKey('childObjAPIName') && inMap.get('childObjAPIName') != null) {
			return String.valueOf(inMap.get('childObjAPIName'));
		}
		if (inMap.containsKey('objectName') && inMap.get('objectName') != null) {
			return String.valueOf(inMap.get('objectName'));
		}
		if (inMap.containsKey('childObjectIds') && inMap.get('childObjectIds') != null) {
			List<Object> childObjectIds = (List<Object>)inMap.get('childObjectIds');
			if (!childObjectIds.isEmpty() && childObjectIds[0] != null) {
				return ((Id)childObjectIds[0]).getSObjectType().getDescribe().getName();
			}
		}
		return null;
	}

	private static Schema.SObjectType getSObjectTypeByName(String objectName) {
		if (String.isBlank(objectName)) {
			return null;
		}
		Map<String, Schema.SObjectType> describeMap = Schema.getGlobalDescribe();
		if (describeMap.containsKey(objectName)) {
			return describeMap.get(objectName);
		}
		for (String describeKey : describeMap.keySet()) {
			if (describeKey != null && describeKey.equalsIgnoreCase(objectName)) {
				return describeMap.get(describeKey);
			}
		}
		return null;
	}

	private static List<String> getAttachmentQueryColumns(
		Map<Object, Object> inMap,
		String step,
		Map<String, Schema.SObjectField> childFieldMap,
		Boolean isMultiCurrencyEnabled
	) {
		List<String> columns = new List<String>{ 'Id' };
		List<Object> columnList = inMap.containsKey(step + 'columns') && inMap.get(step + 'columns') != null
			? (List<Object>)inMap.get(step + 'columns')
			: new List<Object>();

		for (Object colObj : columnList) {
			Map<Object, Object> colMap = (Map<Object, Object>)colObj;
			String fieldName = colMap.containsKey('fieldName') && colMap.get('fieldName') != null ? String.valueOf(colMap.get('fieldName')) : null;
			if (String.isBlank(fieldName) || fieldName == 'RemoveCommunication') {
				continue;
			}
			if (!containsStringIgnoreCase(columns, fieldName)) {
				columns.add(fieldName);
			}

			Schema.SObjectField fieldDescribe = getSObjectFieldIgnoreCase(childFieldMap, fieldName);
			if (fieldDescribe != null && fieldDescribe.getDescribe().getType() == Schema.DisplayType.REFERENCE) {
				String relationshipFieldName = fieldName;
				if (fieldDescribe.getDescribe().isCustom()) {
					relationshipFieldName = fieldName.substring(0, fieldName.length() - 1) + 'r.Name';
				} else {
					relationshipFieldName = fieldName.substring(0, fieldName.length() - 2) + '.Name';
				}
				if (!containsStringIgnoreCase(columns, relationshipFieldName)) {
					columns.add(relationshipFieldName);
				}
			}
		}

		if (isMultiCurrencyEnabled && !containsStringIgnoreCase(columns, 'CurrencyIsoCode')) {
			columns.add('CurrencyIsoCode');
		}
		return columns;
	}

	private static Schema.SObjectField getSObjectFieldIgnoreCase(Map<String, Schema.SObjectField> fieldMap, String fieldName) {
		if (fieldMap == null || String.isBlank(fieldName)) {
			return null;
		}
		if (fieldMap.containsKey(fieldName)) {
			return fieldMap.get(fieldName);
		}
		for (String fieldKey : fieldMap.keySet()) {
			if (fieldKey != null && fieldKey.equalsIgnoreCase(fieldName)) {
				return fieldMap.get(fieldKey);
			}
		}
		return null;
	}

	private static Boolean containsStringIgnoreCase(List<String> values, String expectedValue) {
		if (values == null || String.isBlank(expectedValue)) {
			return false;
		}
		for (String existingValue : values) {
			if (existingValue != null && existingValue.equalsIgnoreCase(expectedValue)) {
				return true;
			}
		}
		return false;
	}
	//-- Start | FIN-9778 | Changed by Dhwanil | 22 May 2026 --//
	public static Map<String, String> getFieldApiVsTranslatedLabelMap(String accountLocale, String childObjAPIName) {
		return celsrm.SRMUtilityController.getTranslatedLabelMapForObject(accountLocale, childObjAPIName);
	}
	//-- End | FIN-9778 | Changed by Dhwanil | 22 May 2026 --//
	//-- FIN-9747 | Changed by Dilshad | 12-May-2026 | End --//
	public class ObjectCriteria {
        public String stepName;
        public String taskSubject;
        public Integer order;
        public List<Criteria> criteria; 
        public String criteriaCondition;
        public Boolean active;
        public String dueDate;
        public String dueDateCustom;
        public List<String> taskType;
        public String template;
        public String emailTemplatePrefix;
        public Boolean enableDynamicTemplate;
        public String templateFolderReferenceField;
        public List<String> columns;
        public String sortField;
        public String sortDirection;
        public Boolean calculateTotal;
        public Boolean showTotal;
        public String aggregationField;
        public String totalTitle;
        public String description;
		// << START - MM - FIN-9969 - select contact by Email_Type__c based on treatment rule name | Added enableDynamicFromAddress to fetch dynamic from address in fetchEmailsForTreatmentTask>>
		public Boolean enableDynamicFromAddress;
		// << END - MM - FIN-9969 - select contact by Email_Type__c based on treatment rule name | Added enableDynamicFromAddress to fetch dynamic from address in fetchEmailsForTreatmentTask >>
        public String fromAddress;
        public Boolean notifyAccountOwner;
        public Boolean attachment;
        public String customLogicClass;
        public Boolean autoDunning;
		//-- Starts | FIN-6948 | Changed by Ravi | 3 JAN 2025 --//
		public String attachmentFormat;
		//-- Emds | FIN-6948 | Changed by Ravi | 3 JAN 2025 --//
		//-- Start | FIN-8209 | Changed By Dilshad | 13-Aug-2025 --//
		public String attachmentName;
		//-- End |FIN-8209| Changed By Dilshad | 13-Aug-2025 --//
		//-- Start | FIN-9041 | Chanegs by Asera 02-Feb-2026--//
		public String attachmentTemplate;
		public String attachmentTemplateFolder;
		public String attachmentTemplateFolderReferenceField;
		//-- End | FIN-9041 | Chanegs by Asera 02-Feb-2026--//
		public String ccSourceType;
        public String ccAddress;
        public String bccSourceType;
        public String bccAddress;
	}
	public class Criteria {
        public String field;
        public String operator;
        public String value;
    }
}