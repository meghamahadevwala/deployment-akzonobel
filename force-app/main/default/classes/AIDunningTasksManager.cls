public with sharing class AIDunningTasksManager implements Queueable {

    /**
     * Set to true when deploying to an org with the celsrm managed package installed.
     * Set to false for unmanaged / unpackaged orgs.
     */
    private static final Boolean IS_MANAGED = true;
    private static final String NS = IS_MANAGED ? 'celsrm__' : '';

    private List<Id> accountIds;
    private Map<Id, Account> accountMap = new Map<Id, Account>();
    private Set<Id> processedAccIds = new Set<Id>();
    private Boolean queryLimitReached = false;
    private celsrm__Treatment__c treatment;
    
    private class TaskFilePayload {
        public Task taskRecord;
        public Set<Id> eligibleTransactionIds;
        public Map<Id, String> reasonMap;

        public TaskFilePayload(Task taskRecord, Set<Id> eligibleTransactionIds, Map<Id, String> reasonMap) {
            this.taskRecord = taskRecord;
            this.eligibleTransactionIds = (eligibleTransactionIds == null) ? new Set<Id>() : new Set<Id>(eligibleTransactionIds);
            this.reasonMap = (reasonMap == null) ? new Map<Id, String>() : new Map<Id, String>(reasonMap);
        }
    }
    
    public AIDunningTasksManager(List<Id> accountIds, celsrm__Treatment__c treatment) {
        this.accountIds = accountIds != null ? accountIds : new List<Id>();
        this.treatment = treatment;
        if(this.accountIds.isEmpty()) {
            System.debug('No account IDs to process');
            return;
        }
        String constrQuery = 'SELECT Id, OwnerId, Name, AccountNumber, DPD_Invoices__c, Overdue_Risk__c, ' +
            NS + 'Total_AR__c, CurrencyIsoCode, AI_Dunning_Strategy__c, Predicted_Payment_Dates__c, ' +
            'AI_Dunning_Frequency__c FROM Account WHERE Id IN :accountIdList WITH SECURITY_ENFORCED';
        List<Id> accountIdList = this.accountIds;
        this.accountMap = new Map<Id, Account>((List<Account>) Database.query(constrQuery));
    }

    public AIDunningTasksManager(List<Id> accountIds, Set<Id> processedAccIds, celsrm__Treatment__c treatment) {
        this.accountIds = accountIds != null ? accountIds : new List<Id>();
        this.treatment = treatment;
        if(this.accountIds.isEmpty()) {
            System.debug('No account IDs to process');
            return;
        }
        this.processedAccIds = processedAccIds != null ? processedAccIds : new Set<Id>();
        String constrQuery = 'SELECT Id, OwnerId, Name, AccountNumber, DPD_Invoices__c, Overdue_Risk__c, ' +
            NS + 'Total_AR__c, CurrencyIsoCode, AI_Dunning_Strategy__c, Predicted_Payment_Dates__c, ' +
            'AI_Dunning_Frequency__c FROM Account WHERE Id IN :accountIdList WITH SECURITY_ENFORCED';
        List<Id> accountIdList = this.accountIds;
        this.accountMap = new Map<Id, Account>((List<Account>) Database.query(constrQuery));
    }

    public void execute(QueueableContext context) {
        if (accountIds == null || accountIds.isEmpty()) {
            System.debug('No account IDs to process');
            return;
        }

        List<Task> taskList = new List<Task>();
        Map<Id,TaskFilePayload> taskFilePayloads = new Map<Id,TaskFilePayload>();
        
        String subjectLabel = String.isNotBlank(treatment.Name) ? treatment.Name : 'AI Overdue Reminder';
        Id treatmentId = treatment.Id;
        Integer dueDays = 1;
        if (treatment.celsrm__Task_Due_Date__c != null) {
            try {
                dueDays = Integer.valueOf(String.valueOf(treatment.celsrm__Task_Due_Date__c));
            } catch (Exception e) {
                dueDays = 1;
            }
        }

        for (Id accId : accountIds) {
            if (processedAccIds.contains(accId)) {
                continue;
            }
            
            DunningTransactionFiltering.EligibleTransactionResult result = 
                DunningTransactionFiltering.getEligibleTransactions(accId, 100);
            
            System.debug('Eligible Transaction Result for Account ' + accId + ' : ' + result);
            if (result.queryLimitReached) {
                System.debug('Query limit reached for account: ' + accId);
                queryLimitReached = true;
                break;
            }
            
            if (!result.queryLimitReached && result.transactions != null && !result.transactions.isEmpty()) {
                Account accountRecord = accountMap.get(accId);
                Id taskOwner = accountRecord != null ? accountRecord.OwnerId : UserInfo.getUserId();
                if (treatment.celsrm__Task_Owner_Queue__c != null) {
                    taskOwner = treatment.celsrm__Task_Owner_Queue__c;
                }
                
                Set<Id> eligibleTxnIds = new Set<Id>();
                Map<Id, String> txnIdToReason = new Map<Id, String>();
                
                for (DunningTransactionFiltering.SelectedTxn txn : result.transactions) {
                    if (txn == null || txn.transactionId == null) {
                        continue;
                    }
                    eligibleTxnIds.add(txn.transactionId);
                    txnIdToReason.put(txn.transactionId, txn.dunningEligibilityReason);
                }
                
                if (!eligibleTxnIds.isEmpty()) {
                    Task dunningTask = getExistingAiTask(accId);

                    if (dunningTask == null) {
                        dunningTask = new Task(
                            Subject = subjectLabel,
                            WhatId = accId,
                            OwnerId = taskOwner,
                            Type = 'Email',
                            Priority = 'High',
                            ActivityDate = Date.today().addDays(dueDays),
                            AiDunning__c = true
                        );
                        dunningTask.put('celsrm__Treatment__c', treatmentId);
                    } else {
                        dunningTask.Subject = subjectLabel;
                        dunningTask.OwnerId = taskOwner;
                        dunningTask.Priority = 'High';
                        dunningTask.ActivityDate = Date.today().addDays(dueDays);
                        dunningTask.Type = 'Email';
                        dunningTask.AiDunning__c = true;
                        dunningTask.put('celsrm__Treatment__c', treatmentId);
                    }

                    dunningTask.Description = 'Eligible transactions: ';
                    
                    taskList.add(dunningTask);
                    taskFilePayloads.put(accId, new TaskFilePayload(dunningTask, eligibleTxnIds, txnIdToReason));
                }
            }
            
            processedAccIds.add(accId);
        }

        if (taskList.size() > 0) {
            String taskFields = 'Priority,Subject,WhatId,OwnerId,Type,ActivityDate,AiDunning,Description,' + 'celsrm__Treatment__c';
            
            Boolean canUpsert = true;
            try {
                canUpsert = celsrm.GOGSecurityController.isUpsertable('Task', taskFields);
            } catch (Exception ex) {
                System.debug('Security check not available, proceeding with upsert: ' + ex.getMessage());
                canUpsert = true;
            }
            
            if (canUpsert) {
                try {
                    upsert taskList;

                    Map<Id, TaskFilePayload> taskIdToPayloadMap = new Map<Id, TaskFilePayload>();
                    for (Task tsk : taskList) {
                        if (tsk.Id != null && tsk.WhatId != null) {
                            taskIdToPayloadMap.put(tsk.id, taskFilePayloads.get(tsk.WhatId));
                        }
                    }

                    List<Id> taskIds = new List<Id>(taskIdToPayloadMap.keySet());

                    if (!taskIdToPayloadMap.isEmpty()) {
                        createContentVersionsInBulk(taskIdToPayloadMap);
                        if (treatment.celsrm__Auto_Treatment__c) {
                            AIDunningTasksExecutor executor = new AIDunningTasksExecutor(taskIds);
                            System.enqueueJob(executor);
                        }
                    }

                    System.debug('Successfully upserted ' + taskList.size() + ' dunning tasks');
                } catch (Exception ex) {
                    System.debug('Error upserting tasks: ' + ex.getMessage());
                }
            } else {
                System.debug('Security check failed for Task upsert');
            }
        }
        
        if (queryLimitReached) {
            chainNextJob();
        }
    }
    
    private void createContentVersionsInBulk(
    Map<Id, TaskFilePayload> taskIdToPayloadMap
) {
    try {
        Set<Id> taskIds = taskIdToPayloadMap.keySet();
        Map<Id, Id> existingDocPerTask = new Map<Id, Id>();

        List<ContentDocumentLink> existingLinks = [
            SELECT ContentDocumentId, LinkedEntityId
            FROM ContentDocumentLink
            WHERE LinkedEntityId IN :taskIds
              AND ContentDocument.Title = 'AI Dunning Task Data'
        ];

        for (ContentDocumentLink cdl : existingLinks) {
            existingDocPerTask.put(cdl.LinkedEntityId, cdl.ContentDocumentId);
        }

        Set<Id> documentsAlreadyExist = new Set<Id>();
        List<ContentVersion> cvsToInsert = new List<ContentVersion>();

        for (Id taskId : taskIds) {
            TaskFilePayload payload = taskIdToPayloadMap.get(taskId);
            if (payload == null || payload.taskRecord == null) continue;

            Id accId = payload.taskRecord.WhatId;

            Map<String, Object> jsonData = new Map<String, Object>();
            String dunningStrategy = accountMap.get(accId) != null ? accountMap.get(accId).AI_Dunning_Strategy__c : treatment.celsrm__Dunning_Strategy__c;
            String predictedPaymentDate = accountMap.get(accId) != null ? accountMap.get(accId).Predicted_Payment_Dates__c : null;
            Integer overdue_risk = accountMap.get(accId) != null ? Math.round(100*accountMap.get(accId).Overdue_Risk__c) : null;
            Decimal dunningFreq = accountMap.get(accId) != null ? accountMap.get(accId).AI_Dunning_Frequency__c : null;
            String strategyBasedReasoning = getDunningStrategyReasoning(dunningStrategy, predictedPaymentDate, overdue_risk, dunningFreq);

            jsonData.put('accountId', String.valueOf(accId));
            jsonData.put('accountName', accountMap.get(accId) != null ? accountMap.get(accId).Name : null);
            jsonData.put('accountNumber', accountMap.get(accId) != null ? accountMap.get(accId).AccountNumber : null);
            jsonData.put('dunningStrategy', dunningStrategy);
            jsonData.put('dunningStrategyReasoning', strategyBasedReasoning);

            jsonData.put('eligibleTransactionIds', payload.eligibleTransactionIds);
            jsonData.put('reasonMappingForTransactionIds', payload.reasonMap);

            jsonData.put('dpdInvoices', accountMap.get(accId) != null ? accountMap.get(accId).DPD_Invoices__c : null);
            jsonData.put('overdueRisk', accountMap.get(accId) != null ? accountMap.get(accId).Overdue_Risk__c : null);
            jsonData.put('totalAR', accountMap.get(accId) != null ? accountMap.get(accId).get(NS + 'Total_AR__c') : null);
            jsonData.put('currency', accountMap.get(accId) != null ? accountMap.get(accId).CurrencyIsoCode : null);
            jsonData.put('overdueRiskCategory', accountMap.get(accId) != null ? accountMap.get(accId).Overdue_Risk__c : null);

            String pathOnClient = 'aiDunningTaskData.json';

            ContentVersion cv = new ContentVersion();
            cv.Title = 'AI Dunning Task Data';
            cv.PathOnClient = pathOnClient;
            cv.VersionData = Blob.valueOf(JSON.serialize(jsonData));
            cv.IsMajorVersion = true;
            cv.put(NS + 'Task_Id__c', taskId);

            Id existingDocId = existingDocPerTask.get(taskId);
            if (existingDocId != null) {
                cv.ContentDocumentId = existingDocId;
                documentsAlreadyExist.add(existingDocId);
            }

            cvsToInsert.add(cv);
        }

        if (!cvsToInsert.isEmpty()) {
            insert cvsToInsert;

            Map<Id, ContentVersion> cvMap = new Map<Id, ContentVersion>(
                (List<ContentVersion>) Database.query(
                    'SELECT Id, ContentDocumentId, ' + NS + 'Task_Id__c FROM ContentVersion WHERE Id IN :cvsToInsert'
                )
            );

            List<ContentDocumentLink> links = new List<ContentDocumentLink>();
            List<String> contentDocumentIds = new List<String>();

            for (ContentVersion cv : cvMap.values()) {
                contentDocumentIds.add(cv.ContentDocumentId);

                String cvTaskId = (String) cv.get(NS + 'Task_Id__c');
                if (cvTaskId != null && !documentsAlreadyExist.contains(cv.ContentDocumentId)) {
                    ContentDocumentLink cdl = new ContentDocumentLink();
                    cdl.ContentDocumentId = cv.ContentDocumentId;
                    cdl.LinkedEntityId = cvTaskId;
                    cdl.ShareType = 'V';
                    links.add(cdl);
                }
            }

            if (!links.isEmpty()) {
                insert links;
            }

            String libraryId = '';
            if(celsrm__SRM_Configuration__c.getOrgDefaults().celsrm__Treatment_File_Sharing_Library_Id__c != null && celsrm__SRM_Configuration__c.getOrgDefaults().celsrm__Treatment_File_Sharing_Library_Id__c != '') {
                libraryId = celsrm__SRM_Configuration__c.getOrgDefaults().celsrm__Treatment_File_Sharing_Library_Id__c;
            } else {
                for (ContentWorkspace contentWorkspace : [SELECT Id, Name FROM ContentWorkspace WHERE Name = 'AR Files' WITH SECURITY_ENFORCED]) {
                        libraryId = contentWorkspace.Id;
                }
            }
            insertContentWorkspaceDoc(contentDocumentIds, libraryId);
        }

    } catch (Exception ex) {
        System.debug('Error: ' + ex.getMessage());
        System.debug(ex.getStackTraceString());
    }
}


    private Task getExistingAiTask(Id accountId) {
        if (accountId == null) {
            return null;
        }
        
        List<Task> existingTasks = [
            SELECT Id, Subject, OwnerId, WhatId, Type, Priority, ActivityDate, Description, AiDunning__c
            FROM Task
            WHERE Status != 'Completed'
            AND WhatId = :accountId
            AND AiDunning__c = true
            WITH SECURITY_ENFORCED
            LIMIT 1
        ];
        
        return existingTasks.isEmpty() ? null : existingTasks.get(0);
    }

    private void chainNextJob() {
        List<Id> remainingAccountIds = new List<Id>();
        for (Id accId : accountIds) {
            if (!processedAccIds.contains(accId)) {
                remainingAccountIds.add(accId);
            }
        }
        
        if (!remainingAccountIds.isEmpty()) {
            System.enqueueJob(new AIDunningTasksManager(remainingAccountIds, processedAccIds, this.treatment));
            System.debug('Chained next AIDunningTaskManager job for ' + remainingAccountIds.size() + ' remaining accounts');
        }
    }

    public static void createDunningTasks(List<Id> accountIds, celsrm__Treatment__c treatment) {
        if (accountIds != null && accountIds.size() > 0) {
            System.enqueueJob(new AIDunningTasksManager(accountIds, treatment));
            System.debug('Initiated AIDunningTaskManager for ' + accountIds.size() + ' accounts');
        }
    }

    public static void insertContentWorkspaceDoc(List<String> documentIds, String contentWorkspaceId) {
        
        system.debug('Attempting to insert ContentWorkspaceDocs');
        List<ContentWorkspaceDoc> contenctWorkspaceDocList = new List<ContentWorkspaceDoc> ();
        for (ContentWorkspaceDoc ContentWorkspaceDocObj : [SELECT Id , ContentDocumentId FROM ContentWorkspaceDoc WHERE ContentDocumentId IN :documentIds AND ContentWorkspaceId = :contentWorkspaceId]) {
            Integer documentIdsIndex = documentIds.indexOf(ContentWorkspaceDocObj.ContentDocumentId);
            if(documentIdsIndex > -1){
                documentIds.remove(documentIdsIndex);
            }
        }
        for (String contentDocumentId : documentIds) {
            ContentWorkspaceDoc contentWorspaceDocObj = new ContentWorkspaceDoc();
            contentWorspaceDocObj.ContentDocumentId = contentDocumentId;
            contentWorspaceDocObj.ContentWorkspaceId = contentWorkspaceId;
            contenctWorkspaceDocList.add(contentWorspaceDocObj);
        }
        try {
            if (contenctWorkspaceDocList.size() > 0) {
                Database.upsert(contenctWorkspaceDocList, false, AccessLevel.USER_MODE);
            }
        } catch(Exception e) {
            system.debug('Error in insertContentWorkspaceDoc:'+e);
            reInsertContentWorkspaceDoc(documentIds, contentWorkspaceId);
        }
    }

    public static String getDunningStrategyReasoning(String dunningStrategy, String predictedDates, Integer overdueRisk, Decimal dunningFreq) {
        if(dunningStrategy == null) return '';
    //  Short-circuit if string clearly isn't a date list
    if (!Pattern.matches('.*\\d{4}-\\d{2}-\\d{2}.*', predictedDates)) {
        System.debug('Non-date message received, skipping parse: ' + predictedDates);
        return '';
    }
    Date dateReq = extractPaymentDate(predictedDates, dunningStrategy.toLowerCase());
    if (dunningStrategy != null && dunningStrategy.toLowerCase() == 'proactive') {
        return 'As part of a proactive approach, we are reaching out to ensure timely payment. This account has ' + String.valueof(overdueRisk) + ' % overdue risk with no dunning in last ' + String.valueof(dunningFreq) + ' days, and the reminder is intended ' +
               'to prevent any potential delays and maintain a smooth payment cycle. ';
    
    } else if (dunningStrategy != null && dunningStrategy.toLowerCase() == 'reactive') {
        return 'As the account is low-risk and a good payer, we have sent a reminder as the last payment cycle was missed. ' +
               'Payment was expected as usual on ' + String.valueOf(dateReq) +
               ' but was missed, thus following up for overdue invoices ';
    } else {
        return '';
    }
}

public static Date extractPaymentDate(
    String predictedPaymentDate,
    String dunningStrategy
) {
    if (String.isBlank(predictedPaymentDate)) {
        return null;
    }

    //  Short-circuit if string clearly isn't a date list
    if (!Pattern.matches('.*\\d{4}-\\d{2}-\\d{2}.*', predictedPaymentDate)) {
        System.debug('Non-date message received, skipping parse: ' + predictedPaymentDate);
        return null;
    }

    Date todayDate = Date.today();
    List<String> dateStrings = predictedPaymentDate.split(';');

    List<Date> dates = new List<Date>();
    for (String d : dateStrings) {
        dates.add(Date.valueOf(d.trim()));
    }

    dates.sort();

    Date result = null;

    if (dunningStrategy == 'proactive') {
        // Nearest upcoming date (>= today)
        for (Date d : dates) {
            if (d >= todayDate) {
                result = d;
                break;
            }
        }
    } else {
        // Last missed date (< today)
        for (Date d : dates) {
            if (d < todayDate) {
                result = d;
            } else {
                break;
            }
        }
    }

    return result;
}

@future(callout=true)
    public static void reInsertContentWorkspaceDoc(List<String> documentIds, String contentWorkspaceId) {
        List<ContentWorkspaceDoc> contenctWorkspaceDocList = new List<ContentWorkspaceDoc> ();
        for (ContentWorkspaceDoc contentWorkspaceDocObj : [SELECT Id , ContentDocumentId FROM ContentWorkspaceDoc WHERE ContentDocumentId IN :documentIds AND ContentWorkspaceId = :contentWorkspaceId]) {
            Integer documentIdsIndex = documentIds.indexOf(contentWorkspaceDocObj.ContentDocumentId);
            if(documentIdsIndex > -1){
                documentIds.remove(documentIdsIndex);
            }
        }
        for (String contentDocumentId : documentIds) {
            ContentWorkspaceDoc contentWorspaceDocObj = new ContentWorkspaceDoc();
            contentWorspaceDocObj.ContentDocumentId = contentDocumentId;
            contentWorspaceDocObj.ContentWorkspaceId = contentWorkspaceId;
            contenctWorkspaceDocList.add(contentWorspaceDocObj);
        }
        try {
            system.debug('Attempt-1 to re-insert ContentWorkspaceDocs');
            Database.upsert(contenctWorkspaceDocList, false, AccessLevel.USER_MODE);
        } catch(Exception ex1) {
            system.debug('Error in attempt-1 inserting ContentWorkspaceDocs:' + ex1);
            try {
                system.debug('Attempt-2 to re-insert ContentWorkspaceDocs');
                Database.upsert(contenctWorkspaceDocList, false, AccessLevel.USER_MODE);
            } catch (Exception ex2) {
                system.debug('Error in attempt-2 inserting ContentWorkspaceDocs:' + ex2);
                try {
                    system.debug('Attempt-3 to re-insert ContentWorkspaceDocs');
                    Database.upsert(contenctWorkspaceDocList, false, AccessLevel.USER_MODE);
                } catch (Exception ex3) {
                    system.debug('Error in attempt-3 inserting ContentWorkspaceDocs:' + ex3);
                    try {
                        system.debug('Attempt-4 to re-insert ContentWorkspaceDocs');
                        Database.upsert(contenctWorkspaceDocList, false, AccessLevel.USER_MODE);
                    } catch (Exception ex4) {
                        system.debug('Error in attempt-4 inserting ContentWorkspaceDocs:' + ex4);
                        try {
                            system.debug('Attempt-5 to re-insert ContentWorkspaceDocs');
                            Database.upsert(contenctWorkspaceDocList, false,AccessLevel.USER_MODE);
                        } catch (Exception ex5) {
                            system.debug('Error in attempt-5 inserting ContentWorkspaceDocs:' + ex5);
                            try {
                                system.debug('finale Attempt to re-insert ContentWorkspaceDocs');
                                Database.upsert(contenctWorkspaceDocList, false, AccessLevel.USER_MODE);
                            } catch (Exception ex6) {
                                system.debug('The final attempt failed inserting ContentWorkspaceDocs:' + ex6);
                                throw new AuraHandledException('The final attempt failed inserting ContentWorkspaceDocs: '+ex6.getMessage());
                            }                    
                        }
                    }
                }
            }
        }
    }
}