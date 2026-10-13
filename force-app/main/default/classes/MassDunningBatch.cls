public with sharing class MassDunningBatch implements Queueable, Database.AllowsCallouts{
    
    Map<String, Object> taskMap = new Map<String, Object>();
    //-- Start | FIN-88653 | Changed by Dhwanil | 23 dec 2025 --//
    List<Object> taskMaplist = new List<Object>();
    //-- End | FIN-88653 | Changed by Dhwanil | 23 dec 2025 --//
    //-- Start | FIN-8313 | Changed by Ravi | 10 sep 2025 --//
    List<Task> taskList = new List<Task>();
    Integer batchSize = 5;
    //-- End | FIN-8313 | Changed by Ravi | 10 sep 2025 --//
    public MassDunningBatch(Map<String, Object> taskMap) {
        this.taskMap = taskMap;
        System.debug('start>>>>>>>');
        try{
            //-- Starts | FIN-8313 | Changed by Ravi | 10 SEP 2025 --//
            //-- Starts | FIN-9629 | Changed by Dhwanil | 28 April 2026 --//
            //-- Starts | FIN-9778 | Changed by Asera | 11 Jun 2026 added column Consolidated_Treatment__c --//
            this.taskList = [
                SELECT Id, celsrm__Treatment__c, celsrm__Treatment__r.celsrm__Related_Object__c, celsrm__Treatment__r.celsrm__Treatment_Steps__c,
                celsrm__Treatment__r.celsrm__Org_Id__c, celsrm__Treatment__r.celsrm__Seperate_Task_For_Step__c, celsrm__Treatment_Stage__c,
                celsrm__Treatment__r.celsrm__Email_Template__c, celsrm__Treatment__r.Name, Subject, celsrm__Treatment__r.celsrm__Attachment__c, 
                celsrm__Treatment__r.celsrm__Enable_Dynamic_Template__c, celsrm__Treatment__r.celsrm__Email_Template_Prefix__c, celsrm__Treatment__r.celsrm__Attachment_Name__c,
                celsrm__Treatment__r.celsrm__Template_Folder_Reference_Field__c, celsrm__Treatment__r.celsrm__Attachment_Format__c,
                celsrm__Treatment__r.celsrm__Notify_Account_Owner__c , celsrm__Treatment__r.celsrm__Consolidated_Treatment__c
                FROM Task WHERE Id = :taskMap.keyset()
            ];
            System.debug('start>>>>>>> ' + this.taskList.size());
            //-- Ends | FIN-8313 | Changed by Ravi | 10 SEP 2025 --//
            //-- Ends | FIN-9629 | Changed by Dhwanil | 28 April 2026 --//
        } catch (Exception e) {
            System.debug('start ' + e.getMessage());
            // return null;
       }
    }
    //-- Start | FIN-8313 | Changed by Ravi | 10 sep 2025 --//
    public MassDunningBatch(Map<String, Object> taskMap, List<Task> taskList) {
        this.taskMap = taskMap;
        this.taskList = taskList;
    }
    //-- End | FIN-8313 | Changed by Ravi | 10 sep 2025 --//

    

    // public Database.Querylocator start(Database.BatchableContext bc){
    //     System.debug('start>>>>>>>');
    //     try{
    //         //-- Starts | FIN-6948 | Changed by Ravi | 3 JAN 2025 --//
    //          return Database.getQueryLocator([
    //             SELECT Id, celsrm__Treatment__c, celsrm__Treatment__r.celsrm__Related_Object__c, celsrm__Treatment__r.celsrm__Treatment_Steps__c,
    //             celsrm__Treatment__r.celsrm__Org_Id__c, celsrm__Treatment__r.celsrm__Seperate_Task_For_Step__c, celsrm__Treatment_Stage__c,
    //             celsrm__Treatment__r.celsrm__Email_Template__c, celsrm__Treatment__r.Name, Subject, celsrm__Treatment__r.celsrm__Attachment__c, 
    //             celsrm__Treatment__r.celsrm__Enable_Dynamic_Template__c, celsrm__Treatment__r.celsrm__Email_Template_Prefix__c,
    //             celsrm__Treatment__r.celsrm__Template_Folder_Reference_Field__c, celsrm__Treatment__r.celsrm__Attachment_Format__c
    //             FROM Task WHERE Id = :taskMap.keyset()
    //         ]);
    //         //-- Ends | FIN-6948 | Changed by Ravi | 3 JAN 2025 --//
    //     } catch (Exception e) {
    //         System.debug('start ' + e.getMessage());
    //         return null;
    //    }
    // }
    //-- Start | FIN-8313 | Changed by Ravi | 10 sep 2025 --//
    public void execute(QueueableContext context) {
    // public void execute(Database.BatchableContext bc, List<Object> taskList){
        System.debug('in execute method');
        // System.debug('taskTreatmentMap>>>>>'+taskList);
        List<Task> currentBatch = new List<Task>();

        // Pick the first 4 (or less if fewer remain)
        Integer count = Math.min(batchSize, taskList.size());
        for (Integer i = 0; i < count; i++) {
            currentBatch.add(taskList[i]);
        }
        //-- Starts | FIN-9629 | Changed by Dhwanil | 28 April 2026 --//
        Set<Id> accountIds = new Set<Id>();
        for (Task task : currentBatch) {
            if (taskMap.containsKey(task.Id)) {
                Map<Object, Object> currentTaskMap = (Map<Object, Object>)taskMap.get(task.Id);
                if (currentTaskMap.get('AccountId') != null) {
                    accountIds.add(Id.valueOf(String.valueOf(currentTaskMap.get('AccountId'))));
                }
            }
        }
        Map<Id, String> accountOwnerEmailMap = UtilityController.getAccountOwnerEmails(accountIds);
        //-- Ends | FIN-9629 | Changed by Dhwanil | 28 April 2026 --//

        for(Task task : currentBatch){
            //-- End | FIN-8313 | Changed by Ravi | 10 sep 2025 --//
            if(taskMap.containsKey(task.Id)){
                Map<Object, Object> taskMap = (map<Object, Object>)taskMap.get(task.Id);
                system.debug('taskMap>>>>>' + taskMap);
                //-- Starts | FIN-6948 | Changed by Ravi | 3 JAN 2025 --//
                String parentId = String.valueOf(taskMap.get('AccountId'));
                celsrm__Treatment__c treatment = task.celsrm__Treatment__r;
                Id templateId = treatment.celsrm__Email_Template__c;
                String childObjAPIName = treatment.celsrm__Related_Object__c;
                Boolean isattachment = treatment.celsrm__Attachment__c;
                String attachmentFormat = treatment.celsrm__Attachment_Format__c;
                //-- Starts | FIN-8653 | Changed by Dhwanil | 16 DEC 2025 --//
                String attachmentName = treatment.celsrm__Attachment_Name__c;
                //-- Ends | FIN-8653 | Changed by Dhwanil | 16 DEC 2025 --//
                List<EmailTemplate> billingTemplateList = new List<EmailTemplate>();
                if(!treatment.celsrm__Seperate_Task_For_Step__c && treatment.celsrm__Enable_Dynamic_Template__c){
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
                                templateId = billingTemplateList.get(0).Id;
                            }
                        }
                    }
                }
                //-- Ends | FIN-6948 | Changed by Ravi | 3 JAN 2025 --//
                // Map<String, Set<Id>> mapStepsData = new Map<String, Set<Id>>();
                // Map<String, Object> mapStepsDataObj = new Map<String, Object>();
                // String stepsData = celsrm.SRMTreatmentUtility.readTreatmentDetailsFile(task.Id, 'Treatment Details');
                // if (stepsData != '') {
                //     mapStepsDataObj =  (map < string, object > ) JSON.deserializeUntyped(stepsData);
                //     for(String mapStepsDataKey : mapStepsDataObj.keySet()){
                //         Set<Id> childId = new Set<Id>();
                //         for (Object ids : (List<Object>) mapStepsDataObj.get(mapStepsDataKey)) {
                //             childId.add((Id)ids);
                //         }
                //         mapStepsData.put(mapStepsDataKey, childId);
                //     }
                // }
                List<TaskTreatmentController.ObjectCriteria> listOfTreatmentStep =  (List<TaskTreatmentController.ObjectCriteria> ) JSON.deserialize(task.celsrm__Treatment__r.celsrm__Treatment_Steps__c, List<TaskTreatmentController.ObjectCriteria>.class);
                List<String> listOfStep = new List<String>();
                Map<String, Set<Id>> stepToRecIds = new Map<String, Set<Id>>();
                Set<Id> childIds = new Set<Id>();
                //-- Starts | FIN-6885 | Changed by Sejal | 6 JAN 2025 --//
                List<Id> excludedIds = new List<Id>();
                //-- Ends | FIN-6885 | Changed  by Sejal | 6 JAN 2025 --//
                for (TaskTreatmentController.ObjectCriteria treStep: listOfTreatmentStep) {
                    //-- Starts | FIN-6948 | Changed by Ravi | 3 JAN 2025 --//
                    if(task.celsrm__Treatment__r.celsrm__Seperate_Task_For_Step__c){
                        if (task.Subject == treStep.taskSubject && task.celsrm__Treatment_Stage__c == treStep.stepName) {
                            templateId = treStep.template;
                            isattachment = treStep.attachment;
                            attachmentFormat = treStep.attachmentFormat;
                            //-- Starts | FIN-8653 | Changed by Dhwanil | 16 DEC 2025 --//
                            attachmentName = treStep.attachmentName!=null && treStep.attachmentName!='' ? treStep.attachmentName : attachmentName;
                            //-- Ends | FIN-8653 | Changed by Dhwanil | 16 DEC 2025 --//
                            if(treStep.enableDynamicTemplate != null && (Boolean)treStep.enableDynamicTemplate){
                                String templatePrefix = treStep.emailTemplatePrefix;
                                if (treStep.templateFolderReferenceField != null && treStep.templateFolderReferenceField != '' && templatePrefix != null && templatePrefix !='') {
                                    String query = 'SELECT ' +  treStep.templateFolderReferenceField + ' FROM Account WHERE Id=:parentId';
                                    List<Account> accList = Database.query(query);
                                    if (!accList.isEmpty() && accList.size() > 0) {
                                        templatePrefix = templatePrefix + '%';
                                        String folderName = string.valueOf(accList.get(0).get(treStep.templateFolderReferenceField));
                                        if (folderName != null && folderName != '') {
                                            billingTemplateList = [SELECT id FROM EmailTemplate WHERE Folder.Name = :folderName AND Name LIKE :templatePrefix AND IsActive = TRUE];
                                        }
                                        if (!billingTemplateList.isEmpty() && billingTemplateList.size() > 0) {
                                            templateId = billingTemplateList.get(0).Id;
                                        }
                                    }
                                }
                            }
                        }
                    }
                    //-- Ends | FIN-6948 | Changed by Ravi | 3 JAN 2025 --//
                    // if (mapStepsData.containsKey(treStep.stepName) && treStep.description != null) {
					// 	taskMap.put(treStep.stepName + 'description', treStep.description);
					// }
					// if(mapStepsData.containsKey(treStep.stepName)){
					// 	taskMap.put(treStep.stepName + 'showTotal', treStep.showTotal);
					// 	taskMap.put(treStep.stepName + 'aggregationField', treStep.aggregationField);
					// 	taskMap.put(treStep.stepName + 'totalTitle', treStep.totalTitle);
					// }
                    // if(mapStepsData.containsKey(treStep.stepName)){
                    if(treStep.active){
                        if (treStep.description != null) {
                            taskMap.put(treStep.stepName + 'description', treStep.description);
                        }
                        taskMap.put(treStep.stepName + 'showTotal', treStep.showTotal);
                        taskMap.put(treStep.stepName + 'aggregationField', treStep.aggregationField);
                        taskMap.put(treStep.stepName + 'totalTitle', treStep.totalTitle);

						listOfStep.add(treStep.stepName);
						List<String> objColumns = treStep.columns;
						List<String> columns = new List<String>();
						
						// childIds = mapStepsData.get(treStep.stepName);
						String query = '';
						Map<string, Schema.sObjectType> describeInfo = Schema.getGlobalDescribe();
                    	Map<String, Schema.SObjectField> fMap = describeInfo.get(childObjAPIName.toLowerCase()).getDescribe().Fields.getMap();
                        //-- Starts | FIN-6885 | Changed by Sejal | 24 JAN 2025 --//
						List<celsrm.SRMTreatmentMapper.Criteria> criteriaList = new List<celsrm.SRMTreatmentMapper.Criteria>();
						for(TaskTreatmentController.Criteria c: treStep.criteria){
							celsrm.SRMTreatmentMapper.Criteria criteriaSet = new celsrm.SRMTreatmentMapper.Criteria();
							criteriaSet.field = c.field;
							criteriaSet.operator = c.operator;
							criteriaSet.value = c.value;
							criteriaList.add(criteriaSet);
						}
						String whereClause = celsrm.SRMTreatmentUtility.getQueryWhereClause(criteriaList, treStep.criteriaCondition, childObjAPIName, null);
						// String whereClause = getStepFilterCriteria(treStep.criteria, treStep.criteriaCondition, childObjAPIName);
						System.debug('whereClause>>>>>>>>>>'+whereClause);
						//-- Ends | FIN-6885 | Changed by Sejal | 24 JAN 2025 --//
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
                            //-- Starts | FIN-7945 | Changed by Ravi | 10 Sep 2025 --//
                            if(UserInfo.isMultiCurrencyOrganization() && !columns.contains('CurrencyIsoCode')) {
								columns.add('CurrencyIsoCode');
							}
                            //-- Ends | FIN-7945 | Changed by Ravi | 10 Sep 2025 --//
							String field = String.Join(columns,',');
                        //-- Starts | FIN-6885 | Changed by Sejal | 6 JAN 2025 --//
                            // if (columns.contains('Id')) {
                            //  query = 'SELECT ' + field + ' FROM ' + childObjAPIName + ' WHERE ID =:childIds';
                            // } else {
                            //  query = 'SELECT Id,' + field + ' FROM ' + childObjAPIName + ' WHERE ID =:childIds';
                            // }
							if (columns.contains('Id')) {
								query = 'SELECT ' + field + ' FROM ' + childObjAPIName;
							} else {
								query = 'SELECT Id,' + field + ' FROM ' + childObjAPIName;
							}
						} else {
                            // query = 'SELECT Id,Name FROM ' + childObjAPIName + ' WHERE ID =:childIds';
                            query = 'SELECT Id,Name FROM ' + childObjAPIName ;
						}

                        if(whereClause != '') {
                            query += ' WHERE ' + ' ( ( ' + whereClause + ' )  AND (ID NOT IN :excludedIds) AND celsrm__Account__c=:parentId)';
                        } 
                        // else if (!childIds.isEmpty()) {
                        //     query += ' WHERE ID =:childIds';
                        // }

                        System.debug('query>>>>>'+ query);
                        List<SObject> childObjRecord = Database.query(query);

                        //-- Ends | FIN-6885 | Changed by Sejal | 6 JAN 2025 --//
                        
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
                        m_Type.put('REFERENCE','html');

                        list<Map<String,Object>> listofField = new list<Map<String,Object>>();
                        // List<String> refField = new List<String>();
                        if (objColumns != null && objColumns.size() > 0) {
                            for(Object fie : objColumns){
                                String field = String.valueOf(fie);
                                if (!field.equalsIgnoreCase('ID')) {
                                    Map<String,Object> m_key_value = new Map<String,Object>();
                                    if(field.equalsIgnoreCase('Name')){
                                        m_key_value.put('label',fMap.get(field).getDescribe().getLabel());
                                        m_key_value.put('fieldName',field);
                                        m_key_value.put('type','html');
                                        m_key_value.put('sortable',false);
                                    } else {
                                        m_key_value.put('label',fMap.get(field).getDescribe().getLabel());
                                        m_key_value.put('fieldName',field);
                                        m_key_value.put('type',m_Type.get(String.valueOf(fMap.get(field).getDescribe().getType())) == 'double' ? 'number' : m_Type.get(String.valueOf(fMap.get(field).getDescribe().getType())));
                                        m_key_value.put('sortable',true);
                                    }
                                    
                                    listofField.add(m_key_value);
                                }
                                // if(fMap.get(field).getDescribe().getType() == Schema.DisplayType.REFERENCE){
                                //     refField.add(field);
                                // }
                            }
                            
                        } else {
                            Map<String,Object> m_key_value = new Map<String,Object>();
                            m_key_value.put('label',fMap.get('Name').getDescribe().getLabel());
                            m_key_value.put('fieldName','Name');
                            m_key_value.put('type','html');
                            m_key_value.put('sortable',true);
                            listofField.add(m_key_value);
                        }
                        // inMap.put(treStep.stepName + 'refField',refField);
                        taskMap.put(treStep.stepName + 'columns',listofField);
                        taskMap.put(treStep.stepName + 'value',childObjRecord);
                        taskMap.put(treStep.stepName ,childObjRecord);
                        
                        //-- Starts | FIN-6885 | Changed by Sejal | 6 JAN 2025 --//
                        Set<Id> stepchildIds = new Set<Id>();
                        if(childObjRecord.size() > 0) {
                            for(sObject rec : childObjRecord) {
                                excludedIds.add((Id)rec.get('Id'));
                                stepchildIds.add((Id)rec.get('Id'));
                                childIds.add((Id)rec.get('Id'));
                            }
                        }
                        stepToRecIds.put(treStep.stepName, stepchildIds);
                        //-- Ends | FIN-6885 | Changed by Sejal | 6 JAN 2025 --//
                    }
                }
                
                List<Object> anyList = new List<Object>();
                //-- Starts | FIN-8444 | Changed by Asera | 7 Oct 2025 --//
                // for (Id idValue : childIds) {
                //     anyList.add(idValue);
                // }
                for (String step : stepToRecIds.keySet()) {
                    anyList.add((stepToRecIds.get(step)));
                }
                //-- Starts | FIN-8444 | Changed by Asera | 7 Oct 2025 --//

                taskMap.put('stepToRecIds', stepToRecIds);
                taskMap.put('accountId', taskMap.get('AccountId'));
                taskMap.put('objectName', 'celsrm__Transaction__c');
                taskMap.put('listOfStep', listOfStep);
                taskMap.put('childObjectIds', anyList);
                taskMap.put('taskSubject', taskMap.get('Subject'));
                taskMap.put('treatmentName', task.celsrm__Treatment__r.Name);
                taskMap.put('treatmentStage', task.celsrm__Treatment_Stage__c);
                // taskMap.put('seperateTaskForStep',  String.ValueOf(task.celsrm__Treatment__r.celsrm__Seperate_Task_For_Step__c));
                taskMap.put('seperateTaskForStep', task.celsrm__Treatment__r.celsrm__Seperate_Task_For_Step__c);
                //-- Starts | FIN-6948 | Changed by Ravi | 3 JAN 2025 --//
                taskMap.put('isAttachment', isattachment);
                taskMap.put('attachmentFormat', attachmentFormat);
                //-- Starts | FIN-8653 | Changed by Dhwanil | 16 DEC 2025 --//
                taskMap.put('attachmentName', attachmentName);
                //-- Ends | FIN-8653 | Changed by Dhwanil | 16 DEC 2025 --//
                taskMap.put('isTaskScreen', false);
                taskMap.put('isDunningScreen', true);
                //-- Starts | FIN-9778 | Changed by Asera | 11 Jun 2026 --//
                taskMap.put('isConsolidated', task.celsrm__Treatment__r.celsrm__Consolidated_Treatment__c);
                //-- End | FIN-9778 | Changed by Asera | 11 Jun 2026 --//

                //-- Ends | FIN-6948 | Changed by Ravi | 3 JAN 2025 --// 
                Map<String, Object> ComposeEmail = composeEmailCustom.setDataFormattingForTreatment(taskMap, templateId, null, null);
                System.debug('ComposeEmail >>>' + ComposeEmail);
                //-- Starts | FIN-88653 | Changed by Dhwanil | 23 dec 2025 --//
                taskMap.put('Treatment Details Temp', ComposeEmail.get('Treatment Details Temp'));
                //-- Ends | FIN-88653 | Changed by Dhwanil | 23 dec 2025 --//
                ComposeEmail.put('from', taskMap.get('celsrm__From__c'));
                if((String)taskMap.get('celsrm__To__c') != null){
                    String toAddress = (String)taskMap.get('celsrm__To__c');
                    List<String> toList = toAddress.split(';');
                    ComposeEmail.put('to', toList);
                }
                //-- Starts | FIN-9629 | Changed by Dhwanil | 28 April 2026 --//
                List<String> ccList = new List<String>();
                UtilityController.addDelimitedEmails(ccList, taskMap.get('celsrm__Cc__c'));
                if (UtilityController.shouldNotifyAccountOwner(task, treatment) && accountOwnerEmailMap.containsKey(Id.valueOf(parentId))) {
                    UtilityController.addEmailIfMissing(ccList, accountOwnerEmailMap.get(Id.valueOf(parentId)));
                }
                if(!ccList.isEmpty()){
                    ComposeEmail.put('cc', ccList);
                }
                //-- Ends | FIN-9629 | Changed by Dhwanil | 28 April 2026 --//
                if(!String.isBlank((String)taskMap.get('celsrm__Bcc__c'))){
                    String bccAddress = (String)taskMap.get('celsrm__Bcc__c');
                    List<String> bccList = bccAddress.split(';');
                    ComposeEmail.put('bcc', bccList);
                } 
                ComposeEmail.put('subject', ComposeEmail.get('subject'));
                ComposeEmail.put('body', ComposeEmail.get('htmlBody'));
                taskMap.put('ComposeEmail', ComposeEmail);
                System.debug('ComposeEmail >>>' + taskMap.get('ComposeEmail'));
                //TaskTreatmentController.customSendEmail(taskMap, true);
                //-- Starts | FIN-88653 | Changed by Dhwanil | 23 dec 2025 --//
                taskMaplist.add(taskMap);
                //-- Ends | FIN-88653 | Changed by Dhwanil | 23 dec 2025 --//
            }
        }
        //-- Start | FIN-8313 | Changed by Ravi | 10 sep 2025 --//
        for (Integer i = 0; i < count; i++) {
            taskList.remove(0); // always remove first element
        }

        // Continue if tasks remain
        if (!taskList.isEmpty()) {
            System.enqueueJob(new MassDunningBatch(taskMap, taskList));
        }
        else
        {   //-- Starts | FIN-88653 | Changed by Dhwanil | 23 dec 2025 --//
            if(taskMaplist.size()>0 && !Test.isRunningTest())
            {
                System.enqueueJob(new MasssendEmail(taskMaplist));
            }
            //-- Ends | FIN-88653 | Changed by Dhwanil | 23 dec 2025 --//
        }
        //-- End | FIN-8313 | Changed by Ravi | 10 sep 2025 --//
    }

    public void finish(Database.BatchableContext bc){
        
    }
}