/**
 * MM - FIN-9969 - select contact by Email_Type__c based on treatment rule name
 * Local (subscriber-org) copy of celsrm SRMTreatmentManager (public, not global).
 * Namespace handling:
 *  - Package custom objects/fields prefixed with celsrm__
 *  - Global package classes referenced via celsrm. (GOGSecurityController)
 *  - Local copies referenced by c-prefixed names (cSRMTreatmentMapper, cSRMTreatmentUtility,
 *    cSRMAutoDunningTreatmentManager)
 *  - getQueryWhereClause is invoked on the local cSRMTreatmentUtility (the package method
 *    expects the package SRMTreatmentMapper.Criteria type, incompatible with the local one)
 *  - Dynamic-namespace variable hardcoded to 'celsrm__'
 */
public with sharing class cSRMTreatmentManager implements Queueable {

    public Map<Id, List<celsrm__Treatment__c>> accIdToTreatments;
    public Map<Id, celsrm__Treatment__c> treatmentsMap = new Map<Id, celsrm__Treatment__c>();
    public Map<Id, Id> accIdTOOwnerId = new Map<Id, Id>();
    //-- Starts | FIN-8342 | Changed by Ravi | 22 May 2025 --//
    private Set<Id> processedAccIds = new Set<Id>();
    private Map<Id, Set<Id>> lastProcessAccIdToTreatments = new Map<Id, Set<Id>>();
    private Boolean limitReached = false;
    //-- End | FIN-8342 | Changed by Ravi | 22 May 2025 --//
    public static String namespace = 'celsrm__';
    //-- FIN-8819 | Changed by Dilshad | 14 Jan 2025 Start --//
    public Boolean executeTaskImmediately = false;
    //-- Start | FIN-9703 | Changed by Dhwanil | 29 April 2026 --//
    public Map<Id, Boolean> accIdTOAutoTreatmentEnabled = new Map<Id, Boolean>();
    //-- end | FIN-9703 | Changed by Dhwanil | 29 April 2026 --//

    public cSRMTreatmentManager(Map<Id, List<celsrm__Treatment__c>> accIdToTreatments, Map<Id, celsrm__Treatment__c> treatmentsMap, Map<Id, Id> accIdTOOwnerId, Boolean executeTaskImmediately, Map<Id, Boolean> accIdTOAutoTreatmentEnabled) {
        this.accIdToTreatments = accIdToTreatments;
        this.treatmentsMap = treatmentsMap;
        this.accIdTOOwnerId = accIdTOOwnerId;
        //-- FIN-8819 | Changed by Dilshad | 14 Jan 2025 Start --//
        this.executeTaskImmediately = executeTaskImmediately;
        //-- FIN-8819 | Changed by Dilshad | 14 Jan 2025 End --//
        //-- Start | FIN-9703 | Changed by Dhwanil | 29 April 2026 --//
        this.accIdTOAutoTreatmentEnabled = accIdTOAutoTreatmentEnabled;
        //-- end | FIN-9703 | Changed by Dhwanil | 29 April 2026 --//
    }

    public void execute(QueueableContext context) {
        if (accIdToTreatments != null && accIdToTreatments.keySet().size() > 0) {
            //-- Starts | FIN-8342 | Changed by Ravi | 22 May 2025 --//
            Integer totalSteps = 0;
            for (Id accId : accIdToTreatments.keySet()) {
                List<celsrm__Treatment__c> treatments = accIdToTreatments.get(accId);
                for (celsrm__Treatment__c t : treatments) {
                    List<cSRMTreatmentMapper.ObjectCriteria> aCriterias = (List<cSRMTreatmentMapper.ObjectCriteria>) JSON.deserialize(t.celsrm__Treatment_Steps__c, List<cSRMTreatmentMapper.ObjectCriteria>.class);
                    totalSteps += aCriterias.size();
                }
            }
            Integer maxRecordSizeAfterLoop = totalSteps * 3;
            Integer maxRows = Limits.getLimitQueryRows();
            //-- End | FIN-8342 | Changed by Ravi | 22 May 2025 --//
            List<Task> tskList = new List<Task>();
            Map<String, String> stepIdsAgainstAccId = new Map<String, String>();
            Set<Id> seperateTaskTreatmentId = new Set<Id>();

            for (Id accId : accIdToTreatments.keySet()) {
                List<celsrm__Treatment__c> treatments = accIdToTreatments.get(accId);
                //-- Starts | FIN-8342 | Changed by Ravi | 22 May 2025 --//
                lastProcessAccIdToTreatments = new Map<Id, Set<Id>>();
                Set<Id> processedTreatmentIds = new Set<Id>();
                //-- End | FIN-8342 | Changed by Ravi | 22 May 2025 --//
                String lastStepName = '';
                for (celsrm__Treatment__c t : treatments) {
                    Map<String, Set<Id>> stepToRecIds = new Map<String, Set<Id>>();
                    List<Id> excludedIds = new List<Id>();
                    //-- Starts | FIN-6374 | Changed by Dilshad | 23 Aug 2024 --//
                    String taskOwner = t.celsrm__Task_Owner_Queue__c != null && t.celsrm__Task_Owner_Queue__c != '' ? t.celsrm__Task_Owner_Queue__c : accIdTOOwnerId.get(accId);
                    //-- Ends | FIN-6374 | Changed by Dilshad | 23 Aug 2024 --//
                    //-- Starts | FIN-6329 | Chnaged by Dilshad | 1 Aug 2024 --//
                    if (t.celsrm__Treatment_Steps__c != null && t.celsrm__Treatment_Steps__c != '' && t.celsrm__Related_Object__c != '') {
                    //-- Ends | FIN-6329 | Chnaged by Dilshad | 1 Aug 2024 --//

                        String obj = t.celsrm__Related_Object__c;
                        List<cSRMTreatmentMapper.ObjectCriteria> aCriterias = (List<cSRMTreatmentMapper.ObjectCriteria>) JSON.deserialize(t.celsrm__Treatment_Steps__c, List<cSRMTreatmentMapper.ObjectCriteria>.class);
                        if (aCriterias != null && aCriterias.size() > 0) {
                            for (cSRMTreatmentMapper.ObjectCriteria aCriteria : aCriterias) {
                                if (aCriteria.active) {

                                    //-- Ends | FIN-6885 | Changed by Sejal | 8 JAN 2025 --//
                                    if (aCriteria.criteria != null && aCriteria.criteria.size() > 0) {
                                        //-- Starts | FIN-6885 | Changed by Sejal | 8 JAN 2025 --//
                                        String whereClause = cSRMTreatmentUtility.getQueryWhereClause(aCriteria.criteria, aCriteria.criteriaCondition, obj, null);
                                        String aggregateQuery = ' SELECT count(Id) FROM ' + String.escapeSingleQuotes(obj) + ' ';
                                        String query = ' SELECT Id FROM ' + String.escapeSingleQuotes(obj) + ' ';
                                        if (whereClause != '') {
                                            query += ' WHERE ' + ' ( ( ' + whereClause + ' ) AND (ID NOT IN :excludedIds) AND (' + namespace + 'Account__c=:accId))';
                                            aggregateQuery += ' WHERE ' + ' ( ( ' + whereClause + ' ) AND (ID NOT IN :excludedIds) AND (' + namespace + 'Account__c=:accId))';
                                        } else if (!excludedIds.isEmpty()) {
                                            query += ' WHERE ID NOT IN :excludedIds AND ' + namespace + 'Account__c=:accId';
                                            aggregateQuery += ' WHERE ID NOT IN :excludedIds AND ' + namespace + 'Account__c=:accId';
                                        }
                                        List<AggregateResult> aggr = Database.query(aggregateQuery);
                                        Integer rowsUsed = Limits.getQueryRows();
                                        if (rowsUsed + maxRecordSizeAfterLoop + Integer.valueOf(aggr.get(0).get('expr0')) >= maxRows) {
                                            System.debug('Query rows limit reached, breaking out early.');
                                            limitReached = true;
                                            break;
                                        }
                                        //-- End | FIN-8342 | Changed by Ravi | 22 May 2025 --//
                                        System.debug('final query : ' + query);
                                        List<sObject> matchRecords = Database.query(query);

                                        if (matchRecords.size() > 0) {
                                            Set<Id> tmp = new Set<Id>();
                                            for (sObject rec : matchRecords) {
                                                excludedIds.add((Id) rec.get('Id'));
                                                tmp.add((Id) rec.get('Id'));
                                            }
                                            stepToRecIds.put(aCriteria.stepName, tmp);
                                            lastStepName = aCriteria.stepName;
                                        }
                                    }
                                }
                            }
                        } else {
                            tskList = updateTaskList(accId, t, lastStepName, tskList);
                        }

                        System.debug('stepToRecIds>> ' + stepToRecIds);
                        //-- Starts | FIN-8342 | Changed by Ravi | 22 May 2025 --//
                        if (!limitReached && t.celsrm__Seperate_Task_For_Step__c && !stepToRecIds.isEmpty()) {
                            //-- End | FIN-8342 | Changed by Ravi | 22 May 2025 --//
                            seperateTaskTreatmentId.add(t.Id);
                            List<Task> ts = [SELECT Id, celsrm__Treatment__c, WhatId, Status, celsrm__Treatment_Stage__c FROM Task WHERE Status != 'Completed' AND WhatId = :accId
                                                AND celsrm__Treatment__c = :t.Id AND celsrm__Treatment_Stage__c IN :stepToRecIds.keySet()];
                            Map<String, Task> stepToTask = new Map<String, Task>();
                            if (!ts.isEmpty()) {
                                for (Task tsk : ts) {
                                    stepToTask.put(tsk.celsrm__Treatment_Stage__c, tsk);
                                }
                            }
                            for (cSRMTreatmentMapper.ObjectCriteria aCriteria : aCriterias) {
                                if (aCriteria.active && stepToRecIds.containsKey(aCriteria.stepName)) {
                                    Map<String, Set<Id>> newStepIds = new Map<String, Set<Id>>();
                                    newStepIds.put(aCriteria.stepName, stepToRecIds.get(aCriteria.stepName));
                                    stepIdsAgainstAccId.put(accId + '-' + t.Id + '-' + aCriteria.stepName, JSON.serialize(newStepIds));
                                    if (stepToTask.containsKey(aCriteria.stepName)) {
                                        // If Existing task found
                                        Task tmp = stepToTask.get(aCriteria.stepName);
                                        tmp.Priority = 'High';
                                        //-- FIN-8819 | Changed by Dilshad | 7 Jan 2025 Start --//
                                        tmp.celsrm__Auto_Dunning__c = aCriteria.autoDunning;
                                        //-- FIN-8819 | Changed by Dilshad | 7 Jan 2025 End --//
                                        tmp.Subject = aCriteria.taskSubject;
                                        tmp.celsrm__Treatment_Stage__c = aCriteria.stepName;
                                        tskList.add(tmp);
                                    } else {
                                        // Existing task not found
                                        //-- Starts | FIN-8379 | Changed by Asera | 23 Sep 2025 --//
                                        if (aCriteria.taskOwnerQueue != null && aCriteria.taskOwnerQueue != '') {
                                            taskOwner = aCriteria.taskOwnerQueue;
                                        } else {
                                            taskOwner = accIdTOOwnerId.get(accId); //  FIN-8403 | Changed by Asera
                                        }
                                        //-- End | FIN-8379 | Changed by Asera | 23 Sep 2025 --//
                                        Integer dueDate = 2;
                                        if (aCriteria.dueDate != null && aCriteria.dueDate != 'Custom') {
                                            dueDate = Integer.valueOf(aCriteria.dueDate);
                                        } else if (aCriteria.dueDate != null && aCriteria.dueDate == 'Custom' && aCriteria.dueDateCustom != null) {
                                            dueDate = Integer.valueOf(aCriteria.dueDateCustom);
                                        }
                                        Task newT = new Task(
                                            celsrm__Treatment__c = t.Id,
                                            //-- FIN-8819 | Changed by Dilshad | 7 Jan 2025 Start --//
                                            celsrm__Auto_Dunning__c = aCriteria.autoDunning,
                                            //-- FIN-8819 | Changed by Dilshad | 7 Jan 2025 End --//
                                            WhatId = accId,
                                            //-- Starts | FIN-6374 | Changed by Dilshad | 23 Aug 2024 --//
                                            OwnerId = taskOwner,
                                            //-- Ends | FIN-6374 | Changed by Dilshad | 23 Aug 2024 --//
                                            Subject = aCriteria.taskSubject,
                                            celsrm__Treatment_Stage__c = aCriteria.stepName,
                                            Type = 'Email',
                                            ActivityDate = Date.today().addDays(dueDate),
                                            Priority = 'High'
                                        );
                                        tskList.add(newT);
                                    }
                                }
                            }
                        //-- Starts | FIN-8342 | Changed by Ravi | 22 May 2025 --//
                        } else if (!limitReached && !stepToRecIds.isEmpty()) {
                            //-- End | FIN-8342 | Changed by Ravi | 22 May 2025 --//
                            // Treatment Create only one task
                            String treatmentStage = lastStepName;
                            stepIdsAgainstAccId.put(accId + '-' + t.Id, JSON.serialize(stepToRecIds));
                            List<Task> ts = [SELECT Id, celsrm__Treatment__c, WhatId, Status FROM Task WHERE Status != 'Completed' AND WhatId = :accId AND celsrm__Treatment__c = :t.Id];
                            if (!t.celsrm__Consolidated_Treatment__c) {
                                lastStepName = t.Name;
                            }
                            if (ts != null && ts.size() > 0) {
                                Task tmp = ts.get(0);
                                //-- FIN-8819 | Changed by Dilshad | 7 Jan 2025 Start --//
                                tmp.celsrm__Auto_Dunning__c = t.celsrm__Auto_Treatment__c;
                                //-- FIN-8819 | Changed by Dilshad | 7 Jan 2025 End --//
                                tmp.Priority = 'High';
                                tmp.Subject = t.Name;
                                tmp.celsrm__Treatment_Stage__c = treatmentStage;
                                tskList.add(tmp);
                            } else {
                                Integer dueDate = 2;
                                if (t.celsrm__Task_Due_Date__c != null) {
                                    dueDate = Integer.valueOf(t.celsrm__Task_Due_Date__c);
                                }
                                Task newT = new Task(
                                    celsrm__Treatment__c = t.Id,
                                    WhatId = accId,
                                    //-- FIN-8819 | Changed by Dilshad | 7 Jan 2025 Start --//
                                    celsrm__Auto_Dunning__c = t.celsrm__Auto_Treatment__c,
                                    //-- FIN-8819 | Changed by Dilshad | 7 Jan 2025 End --//
                                    //-- Starts | FIN-6374 | Changed by Dilshad | 23 Aug 2024 --//
                                    OwnerId = taskOwner,
                                    //-- Ends | FIN-6374 | Changed by Dilshad | 23 Aug 2024 --//
                                    Subject = t.Name,
                                    celsrm__Treatment_Stage__c = treatmentStage,
                                    Type = 'Email',
                                    ActivityDate = Date.today().addDays(dueDate),
                                    Priority = 'High'
                                );
                                tskList.add(newT);
                            }
                        }
                    //-- Starts | FIN-6329 | Chnaged by Dilshad | 1 Aug 2024 --//
                    } else {
                        tskList = updateTaskList(accId, t, lastStepName, tskList);
                    //-- Ends | FIN-6329 | Chnaged by Dilshad | 1 Aug 2024 --//
                    }
                    //-- Starts | FIN-8342 | Changed by Ravi | 22 May 2025 --//
                    if (!limitReached) {
                        processedTreatmentIds.add(t.Id);
                    } else {
                        break;
                    }
                }
                if (limitReached) {
                    lastProcessAccIdToTreatments.put(accId, processedTreatmentIds);
                    break;
                } else {
                    processedAccIds.add(accId);
                    //-- End | FIN-8342 | Changed by Ravi | 22 May 2025 --//
                }
            }

            System.debug('tskList>> ' + tskList);
            if (tskList.size() > 0 && celsrm.GOGSecurityController.isUpsertable('Task', 'Priority,Subject,' + namespace + 'Treatment_Stage__c,' + namespace + 'Treatment__c,WhatId,OwnerId,Type,ActivityDate')) {
                upsert tskList;
            }
            Map<Id, celsrm__Treatment__c> taskTreatmentMap = new Map<Id, celsrm__Treatment__c>();
            //-- FIN-8819 | Changed by Dilshad | 7 Jan 2025 Start --//
            List<Task> autoDunningTasks = new List<Task>();
            //-- FIN-8819 | Changed by Dilshad | 7 Jan 2025 End --//
            if (tskList.size() > 0) {
                Set<Id> tskIds = new Set<Id>();
                Map<Id, Id> tskIdToAccId = new Map<Id, Id>();
                for (Task tsk : tskList) {
                    tskIds.add(tsk.Id);
                    tskIdToAccId.put(tsk.Id, tsk.WhatId);
                    taskTreatmentMap.put(tsk.Id, treatmentsMap.get(tsk.celsrm__Treatment__c));
                    //-- FIN-8819 | Changed by Dilshad | 7 Jan 2025 Start --//
                    if (tsk.celsrm__Auto_Dunning__c) {
                        if (executeTaskImmediately && accIdTOAutoTreatmentEnabled.get(tsk.WhatId)) {
                            autoDunningTasks.add(tsk);
                        } else if (!executeTaskImmediately) {
                            autoDunningTasks.add(tsk);
                        }
                    }
                    //-- FIN-8819 | Changed by Dilshad | 7 Jan 2025 End --//
                }
                List<ContentDocumentLink> cDocLink = [SELECT ContentDocumentId, LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId = :tskIds AND ContentDocument.Title = 'Treatment Details'];
                Map<Id, Id> cdIdAgainstTaskId = new Map<Id, Id>();
                for (ContentDocumentLink tempCDL : cDocLink) {
                    cdIdAgainstTaskId.put(tempCDL.LinkedEntityId, tempCDL.ContentDocumentId);
                }
                List<ContentVersion> insertContentVersion = new List<ContentVersion>();
                Set<Id> documentAlreadyExist = new Set<Id>();
                //-- Starts | FIN-6367 | changes by dilshad | 18 Sep 2024 --//
                String libraryId = '';
                if (celsrm__SRM_Configuration__c.getOrgDefaults().celsrm__Treatment_File_Sharing_Library_Id__c != null && celsrm__SRM_Configuration__c.getOrgDefaults().celsrm__Treatment_File_Sharing_Library_Id__c != '') {
                    libraryId = celsrm__SRM_Configuration__c.getOrgDefaults().celsrm__Treatment_File_Sharing_Library_Id__c;
                } else {
                    for (ContentWorkspace contentWorkspace : [SELECT Id, Name FROM ContentWorkspace WHERE Name = 'Asset Library' WITH SECURITY_ENFORCED]) {
                        libraryId = contentWorkspace.Id;
                    }
                }
                //-- Ends | FIN-6367 | changes by dilshad | 18 Sep 2024 --//
                for (Task tsk : tskList) {
                    String accId = tsk.WhatId;
                    String treatmentDetails = '';
                    if (seperateTaskTreatmentId.contains(tsk.celsrm__Treatment__c)) {
                        treatmentDetails = stepIdsAgainstAccId.get(accId + '-' + tsk.celsrm__Treatment__c + '-' + tsk.celsrm__Treatment_Stage__c);
                    } else {
                        treatmentDetails = stepIdsAgainstAccId.get(accId + '-' + tsk.celsrm__Treatment__c);
                    }
                    System.debug('cdIdAgainstTaskId.get(tsk.Id)>> ' + cdIdAgainstTaskId.get(tsk.Id));
                    //-- Starts | FIN-6329 | Chnaged by Dilshad | 1 Aug 2024 --//
                    if (treatmentDetails != null) {
                        //-- Starts | FIN-6374 | Changed by Dilshad | 23 Aug 2024 --//
                        ContentVersion contentVersion = new ContentVersion();
                        contentVersion.VersionData = Blob.valueOf(treatmentDetails);
                        contentVersion.Title = 'Treatment Details';
                        contentVersion.PathOnClient = 'treatmentdetails.json';
                        //-- Start | FIN-8312 | Changed By Dilshad | 12-Sep-2025 --//
                        //-- below code line will create problem inserting ContentVersion OwnerId other than current user --//
                        //contentVersion.OwnerId = accIdTOOwnerId.get(tskIdToAccId.get(tsk.Id));
                        //-- End | FIN-8312 | Changed By Dilshad | 12-Sep-2025 --//
                        if (cdIdAgainstTaskId.get(tsk.Id) != null) {
                            contentVersion.ContentDocumentId = cdIdAgainstTaskId.get(tsk.Id);
                            documentAlreadyExist.add(cdIdAgainstTaskId.get(tsk.Id));
                        //-- Starts | FIN-6367 | changes by dilshad | 18 Sep 2024 --//
                        } else if (libraryId != '') {
                            //-- Start | FIN-8312 | Changed By Dilshad | 10-Sep-2025 --//
                            //-- we are not setting FirstPublishLocationId while inserting ContentVersion as it is creating issue while inserting ContentVersion in some orgs. We are handling this in future method GOGEmailMapper.insertContentWorkspaceDoc --//
                            //contentVersion.FirstPublishLocationId = libraryId;
                            //-- End | FIN-8312 | Changed By Dilshad | 10-Sep-2025 --//
                            contentVersion.celsrm__Task_Id__c = tsk.Id;
                        }
                        //-- Ends | FIN-6367 | changes by dilshad | 18 Sep 2024 --//
                        insertContentVersion.add(contentVersion);
                        //-- Ends | FIN-6374 | Changed by Dilshad | 23 Aug 2024 --//
                    }
                    //-- Ends | FIN-6329 | Chnaged by Dilshad | 1 Aug 2024 --//
                }
                System.debug('insertContentVersion>> ' + insertContentVersion);
                if (insertContentVersion.size() > 0) {
                    //-- Start | FIN-6402 | Changed by Dilshad | 19-Sep-2024 --//
                    if (celsrm.GOGSecurityController.isCreateable('ContentVersion', 'VersionData,Title,PathOnClient,OwnerId,ContentDocumentId,FirstPublishLocationId, ' + namespace + 'Task_Id__c')) {
                        insert insertContentVersion;
                        //-- Starts | FIN-6441 | changes by Asera | 30 Sep 2024 --//
                        List<ContentVersion> contentVersionList = [SELECT ContentDocumentId, celsrm__Task_Id__c FROM ContentVersion WHERE Id IN :insertContentVersion WITH SECURITY_ENFORCED];
                        List<ContentDocumentLink> contentDocumentLinkList = new List<ContentDocumentLink>();
                        //-- Start | FIN-8312 | Changed By Dilshad | 10-Sep-2025 --//
                        List<String> contentDocumentIds = new List<String>();
                        //-- End | FIN-8312 | Changed By Dilshad | 10-Sep-2025 --//
                        for (ContentVersion cv : contentVersionList) {
                            //-- Start | FIN-8312 | Changed By Dilshad | 10-Sep-2025 --//
                            contentDocumentIds.add(cv.ContentDocumentId);
                            //-- End | FIN-8312 | Changed By Dilshad | 10-Sep-2025 --//
                            if (!documentAlreadyExist.contains(cv.ContentDocumentId)) {
                                ContentDocumentLink conDocLink = new ContentDocumentLink();
                                conDocLink.ContentDocumentId = cv.ContentDocumentId;
                                conDocLink.LinkedEntityId = cv.celsrm__Task_Id__c;
                                conDocLink.ShareType = 'V';
                                conDocLink.Visibility = 'AllUsers';
                                contentDocumentLinkList.add(conDocLink);
                            }
                        }
                        if (!contentDocumentLinkList.isEmpty() && celsrm.GOGSecurityController.isCreateable('ContentDocumentLink', 'LinkedEntityId, ContentDocumentId')) {
                            insert contentDocumentLinkList;
                        }
                        //-- End | FIN-6441 | changes by Asera | 30 Sep 2024 --//
                        //-- Start | FIN-8312 | Changed By Dilshad | 16-Sep-2025 --//
                        ///GOGEmailMapper.insertContentWorkspaceDoc(contentDocumentIds, libraryId);
                        //-- End | FIN-8312 | Changed By Dilshad | 16-Sep-2025 --//
                    }
                    //-- Ends | FIN-6402 | Changed by Dilshad | 19-Sep-2024 --//
                }
            }
            //-- FIN-8819 | Changed by Dilshad | 7 Jan 2025 Start --//
            System.debug('=====> autoDunningTasks: ' + autoDunningTasks);
            System.debug('=====> autoDunningTasks size: ' + autoDunningTasks.size());
            //-- FIN-8819 | Changed by Dilshad | 14 Jan 2025 Start --//
            // << START - MM - FIN-10130 - skip chaining a 2nd queueable job while running Apex tests >>
            // cSRMTreatmentManager is itself a Queueable (this execute() runs as an already-chained job
            // whenever it was enqueued from cSRMTreatmentProcessor.execute()). Test context enforces a
            // max chained-queueable depth of 1, so calling System.enqueueJob(...) again here throws
            // System.AsyncException: Maximum stack depth has been reached whenever a unit test drives
            // this branch. This mirrors the existing !Test.isRunningTest() guard around the
            // System.schedule call in cSRMTreatmentProcessor.finish() - the enqueued job's own logic is
            // exercised/covered separately by cSRMAutoDunningTreatmentManagerTest, so skipping the actual
            // chain during tests does not lose coverage of that class.
            // if (executeTaskImmediately && !autoDunningTasks.isEmpty()) {
            if (executeTaskImmediately && !autoDunningTasks.isEmpty() && !Test.isRunningTest()) {
            // << END - MM - FIN-10130 - skip chaining a 2nd queueable job while running Apex tests >>
            //-- FIN-8819 | Changed by Dilshad | 14 Jan 2025 End --//
                //-- Start | FIN-9703 | Changed by Dhwanil | 29 April 2026 --//
                //Database.executeBatch(new InstantAutoDunningService(autoDunningTasks), 1);
                System.debug('autoDunningTasks >> ' + autoDunningTasks);
                System.enqueueJob(new cSRMAutoDunningTreatmentManager(treatmentsMap, autoDunningTasks));
                //-- End | FIN-9703 | Changed by Dhwanil | 29 April 2026 --//
            }
            //-- FIN-8819 | Changed by Dilshad | 7 Jan 2025 End --//
            //-- Starts | FIN-8342 | Changed by Ravi | 22 May 2025 --//
            if (limitReached) {
                chainNextJob();
            }
            //-- End | FIN-8342 | Changed by Ravi | 22 May 2025 --//
        }
    }

    //-- Starts | FIN-6329 | Chnaged by Dilshad | 1 Aug 2024 --//
    public List<Task> updateTaskList(Id accId, celsrm__Treatment__c t, String lastStepName, List<Task> tskList) {
        String treatmentStage = lastStepName;
        //-- Starts | FIN-6374 | Changed by Dilshad | 23 Aug 2024 --//
        String taskOwner = t.celsrm__Task_Owner_Queue__c != null && t.celsrm__Task_Owner_Queue__c != '' ? t.celsrm__Task_Owner_Queue__c : accIdTOOwnerId.get(accId);
        //-- Ends | FIN-6374 | Changed by Dilshad | 23 Aug 2024 --//
        List<Task> ts = [SELECT Id, celsrm__Treatment__c, WhatId, Status FROM Task WHERE Status != 'Completed' AND WhatId = :accId AND celsrm__Treatment__c = :t.Id];
        if (!t.celsrm__Consolidated_Treatment__c) {
            lastStepName = t.Name;
        }
        if (ts != null && ts.size() > 0) {
            Task tmp = ts.get(0);
            tmp.Priority = 'High';
            //-- FIN-8819 | Changed by Dilshad | 7 Jan 2025 Start --//
            tmp.celsrm__Auto_Dunning__c = t.celsrm__Auto_Treatment__c;
            //-- FIN-8819 | Changed by Dilshad | 7 Jan 2025 End --//
            tmp.Subject = t.Name;
            tmp.celsrm__Treatment_Stage__c = treatmentStage;
            tskList.add(tmp);
        } else {
            Integer dueDate = 2;
            if (t.celsrm__Task_Due_Date__c != null) {
                dueDate = Integer.valueOf(t.celsrm__Task_Due_Date__c);
            }
            Task newT = new Task(
                celsrm__Treatment__c = t.Id,
                WhatId = accId,
                //-- FIN-8819 | Changed by Dilshad | 7 Jan 2025 Start --//
                celsrm__Auto_Dunning__c = t.celsrm__Auto_Treatment__c,
                //-- FIN-8819 | Changed by Dilshad | 7 Jan 2025 End --//
                //-- Starts | FIN-6374 | Changed by Dilshad | 23 Aug 2024 --//
                OwnerId = taskOwner,
                //-- Ends | FIN-6374 | Changed by Dilshad | 23 Aug 2024 --//
                Subject = t.Name,
                celsrm__Treatment_Stage__c = treatmentStage,
                Type = 'Email',
                ActivityDate = Date.today().addDays(dueDate),
                Priority = 'High'
            );
            tskList.add(newT);
        }
        return tskList;
    }
    //-- Ends | FIN-6329 | Chnaged by Dilshad | 1 Aug 2024 --//
    //-- Starts | FIN-8342 | Changed by Ravi | 22 May 2025 --//
    private void chainNextJob() {
        // Remove already processed accounts
        for (Id doneAccId : processedAccIds) {
            accIdToTreatments.remove(doneAccId);
        }
        for (Id accId : lastProcessAccIdToTreatments.keySet()) {
            if (accIdToTreatments.containsKey(accId)) {
                Set<Id> processedIds = lastProcessAccIdToTreatments.get(accId);
                List<celsrm__Treatment__c> updatedList = new List<celsrm__Treatment__c>();
                for (celsrm__Treatment__c t : accIdToTreatments.get(accId)) {
                    if (!processedIds.contains(t.Id)) {
                        updatedList.add(t);
                    }
                }
                accIdToTreatments.put(accId, updatedList);
            }
        }

        // Chain next queueable for remaining accounts
        if (!accIdToTreatments.isEmpty()) {
            //-- FIN-8819 | Changed by Dilshad | 14 Jan 2025 Start --//
            System.enqueueJob(new cSRMTreatmentManager(accIdToTreatments, treatmentsMap, accIdTOOwnerId, executeTaskImmediately, accIdTOAutoTreatmentEnabled));
            //-- FIN-8819 | Changed by Dilshad | 14 Jan 2025 End --//
        }
    }
    //-- End | FIN-8342 | Changed by Ravi | 22 May 2025 --//
}