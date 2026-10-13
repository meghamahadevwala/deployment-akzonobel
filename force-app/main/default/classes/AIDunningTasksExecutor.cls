public with sharing class AIDunningTasksExecutor implements Queueable, Database.AllowsCallouts {

    private List<Id> taskIds;
    private List<celsrm__Celonis_Event__c> eventsToInsert = new List<celsrm__Celonis_Event__c>();
    private Map<Id, Account> accountsToUpdate = new Map<Id, Account>();
    private Integer batchSize = 100;

    public AIDunningTasksExecutor() {}

    public AIDunningTasksExecutor(List<Id> taskIds) {
        this.taskIds = taskIds;
    }

    public void execute(QueueableContext context) {

    // if (!celsrm__AI_Configuration__c.getOrgDefaults().Auto_Execute_AI_Dunning_Tasks__c) {
    //     System.debug('Auto Execute AI Dunning Tasks is disabled in configuration. Exiting execution.');
    //     return;
    // }

    List<Task> tasks;

    // Ravi - Need a clarification: What is the use of CASE 1
    // CASE 1: First run → taskIds not provided → fetch a batch
    if (taskIds == null) {
        System.debug('taskIds is null → Fetching tasks by batch.');

        tasks = [
            SELECT Id, WhatId, Status, Subject, celsrm__Treatment__r.celsrm__Auto_Treatment__c,
                   Owner.Name, Owner.Email, Owner.Title, Owner.UserRole.Name
            FROM Task
            WHERE AiDunning__c = true
            AND Status != 'Completed'
            LIMIT :batchSize
        ];

        taskIds = new List<Id>();
        for (Task t : tasks) {
            if (t.celsrm__Treatment__r != null && t.celsrm__Treatment__r.celsrm__Auto_Treatment__c == true) {
                taskIds.add(t.Id);
            }
            
        }
        

        if (taskIds.isEmpty()) {
            System.debug('No AI Dunning tasks found.');
            return;
        }
    }
    else {
        // CASE 2: taskIds were provided externally
        System.debug('taskIds provided → Fetch corresponding tasks.');

        List<Task> taskList = [
            SELECT Id, WhatId, Status, Subject, celsrm__Treatment__c, celsrm__Treatment__r.celsrm__Auto_Treatment__c,
                   Owner.Name, Owner.Email, Owner.Title, Owner.UserRole.Name
            FROM Task
            WHERE Id IN :taskIds
        ];

        tasks = new List<Task>();
        for (Task t : taskList) {
            if (t.celsrm__Treatment__r != null && t.celsrm__Treatment__r.celsrm__Auto_Treatment__c == true) {
                tasks.add(t);
            }
        }
        if (tasks.isEmpty()) {
            System.debug('No tasks found for provided taskIds.');
            return;
        }
    }

    System.debug('Processing: ' + tasks.size() + ' tasks');

    // Custom logic
    processTasks(tasks);

    performPostTaskExecutionSuccessDML();

    // Mark tasks completed
    completeTasks(taskIds);

    // Chain next batch
    chainNextBatch(taskIds);
}


private void processTasks(List<Task> tasks) {
    List<Id> treId = new List<Id>();
    for(Task t: tasks){
        treId.add(t.celsrm__Treatment__c);
    }
    Map<Id, celsrm__Treatment__c> treatmentMap = new Map<Id, celsrm__Treatment__c>();
    for(celsrm__Treatment__c tr: [SELECT Id, celsrm__Attachment__c, celsrm__Attachment_Name__c, celsrm__Attachment_Format__c, celsrm__Transaction_Table_Columns__c, celsrm__Show_Total__c, celsrm__Aggregation_Field__c, celsrm__Total_Label__c, celsrm__Template_Generation_Prompt__c, celsrm__Enable_Multi_Language__c, celsrm__Language_Field__c, celsrm__Org_Id__c, celsrm__Enable_Dynamic_From_Address__c, celsrm__Notify_Account_Owner__c, celsrm__Enable_AI_Generated_Template__c, celsrm__Enable_Dynamic_Template__c, celsrm__Email_Template__c, celsrm__Template_Folder__c, celsrm__Template_Folder_Reference_Field__c, celsrm__Email_Template_Prefix__c FROM celsrm__Treatment__c  WHERE Id IN :treId]) {
        treatmentMap.put(tr.Id, tr);
    }
    for (Task t : tasks) {
        celsrm__Treatment__c tr = treatmentMap.get(t.celsrm__Treatment__c);
        System.debug('Processing task: ' + t.Id);

        // STEP 1: Fetch To / From / CC
        List<Contact> contactsList = [
            SELECT Id, Name, Email, Account.Owner.Email
            FROM Contact
            WHERE AccountId = :t.WhatId AND celsrm__Default__c=TRUE
        ];

        System.debug('Contacts found: ' + contactsList);

        id contactId = null;
        List < String > toAddresses = new List<String>();
        List < String > ccAddresses = new List<String>();

        if (contactsList.size() > 0) {
            for (Contact con : contactsList) {
                if (!String.isBlank(con.Email)) {
                    toAddresses.add(con.Email);
                }
                if(contactId == null){
                    contactId = con.Id;
                }
                if (con.Account != null && !String.isBlank(con.Account.Owner.Email)) {
                    ccAddresses.add(con.Account.Owner.Email);
                }
            }
        }

        if (toAddresses.isEmpty()) {
            System.debug('Missing to: Address for email . Skipping task: ' + t.Id);
            continue;
        }

        // Step 2 : Fetch list of transactions from the JSON file stored for this task
        String tempData =
            celsrm.SRMTreatmentUtility.readTreatmentDetailsFile(t.Id, 'AI Dunning Task Data');
        
        System.debug('Dunning Task Data JSON: ' + tempData);

        Map<String, Object> dunningData =  (map < string, object > ) JSON.deserializeUntyped(tempData);

        System.debug('Dunning Data: ' + dunningData);

        Set<String> txnIds = new Set<String>();
        if (dunningData != null && dunningData.containsKey('eligibleTransactionIds')) {
            List<Object> rawList = (List<Object>) dunningData.get('eligibleTransactionIds');

            for (Object o : rawList) {
                if (o != null) {
                    String s = String.valueOf(o); // Convert any object to string
                    if (!String.isBlank(s)) {
                        txnIds.add(s); // Add to Set<String>
                    }
                }
            }
        }

        // STEP 3: Generate email content (AI-based or static template)
        AIDunningTemplateGeneration.DunningEmailResult aiEmail;
        List<String> txnIdList = new List<String>(txnIds);

        Boolean useAiTemplate = tr == null || tr.celsrm__Enable_AI_Generated_Template__c;

        if (useAiTemplate) {
            String language = null;
            if (tr.celsrm__Enable_Multi_Language__c && String.isNotBlank(tr.celsrm__Language_Field__c)) {
                String langField = String.escapeSingleQuotes(tr.celsrm__Language_Field__c.trim());
                String langQuery = 'SELECT ' + langField + ' FROM Account WHERE Id = :accountId LIMIT 1';
                Id accountId = t.WhatId;
                List<SObject> langResults = Database.query(langQuery);
                if (!langResults.isEmpty() && langResults[0].get(tr.celsrm__Language_Field__c.trim()) != null) {
                    language = String.valueOf(langResults[0].get(tr.celsrm__Language_Field__c.trim()));
                }
            }

            Map<String, String> collectorDetails = new Map<String, String>();
            if (t.Owner != null) {
                collectorDetails.put('name', t.Owner.Name);
                collectorDetails.put('email', t.Owner.Email);
                collectorDetails.put('title', t.Owner.Title);
                collectorDetails.put('role', t.Owner.UserRole != null ? t.Owner.UserRole.Name : null);
            }

            try {
                aiEmail = AIDunningTemplateGeneration.generateDunningEmailContent(t, dunningData, txnIdList, tr.celsrm__Template_Generation_Prompt__c, language, collectorDetails);
            } catch (Exception ex) {
                System.debug('AI generation failed for task ' + t.Id + ': ' + ex.getMessage());
                throw new AuraHandledException('Error generating AI email template: ' + ex.getMessage());
            }
        } else {
            aiEmail = resolveStaticTemplate(tr, t, contactId);
        }
        
        Map<String, Object> tableData = AIDunningTemplateGeneration.buildTransactionHtmlTable(
            txnIdList,
            tr.celsrm__Show_Total__c,
            tr.celsrm__Aggregation_Field__c,
            tr.celsrm__Total_Label__c,
            'celsrm__Transaction__c',
            tr.celsrm__Transaction_Table_Columns__c
        );
        String transactionTable = (String)tableData.get('innerHtml');
        if (aiEmail.body != null && aiEmail.body.contains('{transactions.summary}')) {
            aiEmail.body = aiEmail.body.replace('{transactions.summary}', transactionTable);
        } else if (transactionTable != null) {
            aiEmail.body = (aiEmail.body != null ? aiEmail.body : '') + '<br/><br/>' + transactionTable;
        }
        
        // STEP 4: Create attachments + HTML table using JSON file :- create separate method
        List < Map < String, String >> attachmentobj = new List < Map < String, String >> ();
        // Boolean attachmentFlag = celsrm__AI_Configuration__c.getOrgDefaults().Attach_Transaction_Details_Excel__c;
        Boolean attachmentFlag = tr.celsrm__Attachment__c != null ? tr.celsrm__Attachment__c : false;
        if (attachmentFlag) {
            String attachmentName = tr.celsrm__Attachment_Name__c != null ? tr.celsrm__Attachment_Name__c : 'Transactions';
            String attachmentFormat = tr.celsrm__Attachment_Format__c != null ? tr.celsrm__Attachment_Format__c : 'Excel';

            String htmlString =
                '<html><head>' +
                '<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />' +
                '</head><body>';
            htmlString += (String)tableData.get('innerHtml');
            htmlString += '</body></html>';

            ContentVersion cv = new ContentVersion();
            cv.Title = attachmentName;

            if (attachmentFormat == 'PDF') {
                cv.PathOnClient = attachmentName + '.pdf';
                if (Test.isRunningTest()) {
                    cv.VersionData = Blob.valueOf('Test');
                } else {
                    PageReference pRef = Page.celsrm__SRMTreatmentPdfGenerator;
                    pRef.getParameters().put('taskId', t.Id);
                    pRef.getParameters().put('accountId', String.valueOf(t.WhatId));
                    pRef.getParameters().put('taskSubject', t.Subject);
                    pRef.getParameters().put('treatmentId', t.celsrm__Treatment__c);
                    pRef.getParameters().put('jsonFileName', 'AI Dunning Task Data');
                    pRef.getParameters().put('attachmentType', 'PDF');
                    cv.VersionData = pRef.getContentAsPDF();
                }
            } else {
                cv.PathOnClient = attachmentName + '.xls';
                if (Test.isRunningTest()) {
                    cv.VersionData = Blob.valueOf('Test');
                } else {
                    cv.VersionData = Blob.valueOf(htmlString);
                }
            }

            Boolean canUpsert = true;
            try {
                canUpsert = celsrm.GOGSecurityController.isUpsertable('ContentVersion', 'VersionData,Title,PathOnClient');
            } catch (Exception ex) {
                System.debug('Security check not available, proceeding with upsert: ' + ex.getMessage());
                canUpsert = true;
            }
            if (canUpsert) {
                upsert cv;
            }

            // 5. Add file Id to response map
            Map<String, String> attachment = new Map<String, String>();
            attachment.put('Id', cv.Id);
            attachmentobj.add(attachment);
        }

        // STEP 5: Send email using treatment email settings
        celsrm.GOGEmailMapper.SendEmailBean emailBean = new celsrm.GOGEmailMapper.SendEmailBean();
        if (tr != null && String.isNotBlank(tr.celsrm__Org_Id__c)) {
            if (tr.celsrm__Enable_Dynamic_From_Address__c) {
                String fromField = String.escapeSingleQuotes(tr.celsrm__Org_Id__c.trim());
                Id accountId = t.WhatId;
                String fromQuery = 'SELECT ' + fromField + ' FROM Account WHERE Id = :accountId LIMIT 1';
                List<SObject> fromResults = Database.query(fromQuery);
                if (!fromResults.isEmpty() && fromResults[0].get(tr.celsrm__Org_Id__c.trim()) != null) {
                    emailBean.owea = String.valueOf(fromResults[0].get(tr.celsrm__Org_Id__c.trim()));
                }
            } else {
                emailBean.owea = tr.celsrm__Org_Id__c;
            }
        }
        emailBean.to = toAddresses;
        emailBean.subject = aiEmail.subject;
        emailBean.htmlBody = aiEmail.body;
        emailBean.attachment = attachmentobj;
		emailBean.followUpTaskDueDate = null;

        Map<String, Map<String, List<String>>> emailsMap = UtilityController.fetchEmailsForTreatmentTask(new List<Task>{ t });
        if (emailsMap.containsKey(t.Id)) {
            Map<String, List<String>> taskEmails = emailsMap.get(t.Id);
            if (taskEmails.containsKey('cc') && !taskEmails.get('cc').isEmpty()) {
                emailBean.cc = taskEmails.get('cc');
            }
            if (taskEmails.containsKey('bcc') && !taskEmails.get('bcc').isEmpty()) {
                emailBean.bcc = taskEmails.get('bcc');
            }
        }
        if (tr != null && tr.celsrm__Notify_Account_Owner__c && !ccAddresses.isEmpty()) {
            if (emailBean.cc == null) {
                emailBean.cc = new List<String>();
            }
            emailBean.cc.addAll(ccAddresses);
        }

        try {
            celsrm.GOGEmailMapper.sendEmailWithBean(emailBean);
            System.debug('Email sent for task: ' + t.Id);
            registerPostSuccessActions(t, txnIds); // only fires for successfull tasks
        }
        catch (Exception ex) {
            throw new AuraHandledException('Error sending email: ' + ex.getMessage());
        }

        // STEP 6: Reset Dunning_Eligibility__c for all transactions
        resetDunningEligibility(txnIds);
    }
}

    private AIDunningTemplateGeneration.DunningEmailResult resolveStaticTemplate(celsrm__Treatment__c tr, Task t, Id contactId) {
        AIDunningTemplateGeneration.DunningEmailResult result = new AIDunningTemplateGeneration.DunningEmailResult();

        String templateId = tr.celsrm__Email_Template__c;

        if (tr.celsrm__Enable_Dynamic_Template__c && String.isNotBlank(tr.celsrm__Template_Folder_Reference_Field__c) && String.isNotBlank(tr.celsrm__Email_Template_Prefix__c)) {
            String folderRefField = String.escapeSingleQuotes(tr.celsrm__Template_Folder_Reference_Field__c.trim());
            Id accountId = t.WhatId;
            String folderQuery = 'SELECT ' + folderRefField + ' FROM Account WHERE Id = :accountId LIMIT 1';
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

        Id targetObjectId = contactId != null ? contactId : t.WhatId;
        Id whatId = t.WhatId;

        Messaging.SingleEmailMessage rendered = Messaging.renderStoredEmailTemplate(templateId, targetObjectId, whatId);
        result.subject = rendered.getSubject();
        result.body = rendered.getHtmlBody();

        return result;
    }

    private void resetDunningEligibility(Set<String> txnIds) {

        if (txnIds == null || txnIds.isEmpty()) {
            System.debug('No transaction IDs to reset.');
            return;
        }

        List<celsrm__Transaction__c> txns = new List<celsrm__Transaction__c>();

        for(String txnId : txnIds) {
            celsrm__Transaction__c t = new celsrm__Transaction__c(
                Id = txnId,
                Dunning_Eligibility__c = null
            );
            txns.add(t);
        }

        if (!txns.isEmpty()) {
            update txns;
            System.debug('Reset Dunning_Eligibility__c for ' + txns.size() + ' transactions.');
        }
    }


    /**
     * Marks the current batch of tasks as Completed
     */
    private void completeTasks(List<Id> taskIds) {
        List<Task> tasksToClose = new List<Task>();

        for (Id tId : taskIds) {
            Task t = new Task(
                Id = tId,
                Status = 'Completed'
            );
            tasksToClose.add(t);
        }

        if (!tasksToClose.isEmpty()) {
            update tasksToClose;
        }
    }

    /**
     * Chain next batch of tasks
     */
    private void chainNextBatch(List<Id> processedTaskIds) {

        List<Id> nextBatch = new List<Id>();

        List<Task> remaining = [
            SELECT Id
            FROM Task
            WHERE AiDunning__c = true
            AND Status != 'Completed'
            AND Id NOT IN :processedTaskIds
            LIMIT :batchSize
        ];

        for (Task t : remaining) nextBatch.add(t.Id);

        if (!nextBatch.isEmpty()) {
            System.enqueueJob(new AIDunningTasksExecutor(nextBatch));
            System.debug('Chained next batch: ' + nextBatch.size());
        }
    }

    private void registerPostSuccessActions(Task t, Set<String> txnIds) {

        if (t.WhatId == null) return;
    
        Date todayDate = Date.today();

        // Account Event
        celsrm__Celonis_Event__c accEvent = new celsrm__Celonis_Event__c(
            Name = t.Subject,
            celsrm__Account__c  = t.WhatId, // Account
            celsrm__Event_Time__c = todayDate,
            celsrm__Note__c = 'AI Dunning email successfully sent via Task ' + t.Id,
            Agent_Name__c = 'Dunning Agent'
        );
        eventsToInsert.add(accEvent);
    
        // Transaction Events
        for (String txnId : txnIds) {
            celsrm__Celonis_Event__c txnEvent = new celsrm__Celonis_Event__c(
                Name = t.Subject,
                celsrm__Transaction__c  = txnId,
                celsrm__Event_Time__c = todayDate,
                celsrm__Note__c = 'AI Dunning reminder sent for transaction.',
                Agent_Name__c = 'Dunning Agent'
            );
            eventsToInsert.add(txnEvent);
        }
    
        // update account level fields 
        if (!accountsToUpdate.containsKey(t.WhatId)) {
            accountsToUpdate.put(
                t.WhatId,
                new Account(
                    Id = t.WhatId,
                    Last_Dunning_Reminder_Date__c = todayDate
                )
            );
        }
    }    

    private void performPostTaskExecutionSuccessDML() {

        if (!eventsToInsert.isEmpty()) {
            insert eventsToInsert;
            System.debug('Inserted Events: ' + eventsToInsert.size());
        }
    
        if (!accountsToUpdate.isEmpty()) {
            update accountsToUpdate.values();
            System.debug('Updated Accounts: ' + accountsToUpdate.size());
        }
    }    

    /**
     * Start execution of all tasks
     */
    public static void executeAll() {
        System.enqueueJob(new AIDunningTasksExecutor());
    }
}