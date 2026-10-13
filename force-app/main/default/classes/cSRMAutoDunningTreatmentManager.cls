/**
 * MM - FIN-9969 - select contact by Email_Type__c based on treatment rule name
 * Local (subscriber-org) copy of celsrm SRMAutoDunningTreatmentManager (public, not global).
 * Namespace handling:
 *  - Package custom objects/fields are prefixed with celsrm__
 *  - Global package classes/methods are referenced via the celsrm. namespace
 *    (GOGSecurityController, GOGEmailMapper.sendEmail, SRMUtilityController.insertActivity,
 *     SRMTreatmentUtility.getTemplateBody)
 *  - Local copies are referenced by their c-prefixed names (cSRMTreatmentUtility)
 *  - The dynamic-namespace variable is hardcoded to 'celsrm__'
 */
// << START - MM - FIN-10180 - marked virtual so a test-only subclass can override fetchTemplateBody >>
public virtual with sharing class cSRMAutoDunningTreatmentManager implements Queueable, Database.AllowsCallouts {
// << END - MM - FIN-10180 >>
    public celsrm__Treatment__c treatment;
    public List<Task> taskList;
    public Map<Id, celsrm__Treatment__c> treatmentsMap;
    public static String namespace = 'celsrm__';

    public cSRMAutoDunningTreatmentManager(Map<Id, celsrm__Treatment__c> treatmentsMap, List<Task> taskList) {
        this.treatmentsMap = treatmentsMap;
        this.taskList = taskList;
    }

    // << START - MM - FIN-10180 - extracted the managed-package call to getTemplateBody into an
    // overridable method so unit tests can stub out its return value. celsrm.SRMTreatmentUtility.getTemplateBody
    // cannot be exercised end-to-end in this org's test context (it NPEs unconditionally whenever a
    // Default contact/toAddress is present), which previously left the entire email-send/attachment/
    // activity-logging block (the bulk of execute()) with 0% test coverage. Behavior for real (non-test)
    // invocations is unchanged - this simply delegates to the same managed call. >>
    protected virtual Map<String, Object> fetchTemplateBody(Task tsk, celsrm__Treatment__c treatment, Id contactId, Account acc) {
        return celsrm.SRMTreatmentUtility.getTemplateBody(tsk, treatment, tsk.Id, contactId, true, null, acc);
    }
    // << END - MM - FIN-10180 >>

    public void execute(QueueableContext context) {
        if (!taskList.isEmpty()) {
            Task tsk = taskList.get(0);
            this.treatment = treatmentsMap.get(tsk.celsrm__Treatment__c);
            Id parentId = tsk.WhatId;
            Id contactId = null;
            // << START - MM - FIN-9969 - select contact by Email_Type__c based on treatment rule name >>
            // List<Contact> contactList = [SELECT Id, Name, Email, Account.Owner.Email FROM Contact WHERE AccountId = :parentId AND celsrm__Default__c = TRUE];
            // CUSTSTAT rules target contacts with Email_Type__c = 'Statement';
            // DUNNING rules target contacts with Email_Type__c = 'Dunning'.
            // Falls back to the default contact when the rule name matches neither keyword.
            String ruleName = (treatment != null && treatment.celsrm__Treatment_Name__c != null) ? treatment.celsrm__Treatment_Name__c.toUpperCase() : '';
            String emailType = null;
            if (ruleName.contains('CUSTSTAT')) {
                emailType = 'Statement';
            } else if (ruleName.contains('DUNNING')) {
                emailType = 'Dunning';
            }
            List<Contact> contactList;
            if (emailType != null) {
                // << START - MM - FIN-9969 - select contact by Email_Type__c based on treatment rule name | Owner to be added in CC if notifyAccountOwner is true >>
                contactList = [SELECT Id, Name, Email, Account.Owner.Email, CC__c, Bcc__c, celsrm__Default__c FROM Contact WHERE AccountId = :parentId AND Email_Type__c = :emailType AND (celsrm__Default__c = true OR CC__c = true OR Bcc__c = true)];
            } else {
                contactList = [SELECT Id, Name, Email, Account.Owner.Email, CC__c, Bcc__c, celsrm__Default__c FROM Contact WHERE AccountId = :parentId AND (celsrm__Default__c = true OR CC__c = true OR Bcc__c = true)];
            }
            // << END - MM - FIN-9969 - select contact by Email_Type__c based on treatment rule name >>
            List<String> toAddresses = new List<String>();
            List<String> ccAddresses = new List<String>();
            //-- Start | FIN-7567 | Changed By Ravi | 12-May-2025 --//
            List<String> bccAddresses = new List<String>();
            //-- Ends | FIN-7567 | Changed By Ravi | 12-May-2025 --//
            // << START - MM - FIN-9969 - select contact by Email_Type__c based on treatment rule name | Owner to be added in CC if notifyAccountOwner is true >>
            Map<Id, String> accIdVsOwnerEmail = new Map<Id, String>();
            // << END - MM - FIN-9969 - select contact by Email_Type__c based on treatment rule name | Owner to be added in CC if notifyAccountOwner is true >>
            if (contactList.size() > 0) {
                for (Contact con : contactList) {
                    if (!String.isBlank(con.Email) && con.celsrm__Default__c != null && con.celsrm__Default__c == true) {
                        toAddresses.add(con.Email);
                    }
                    // << START - MM - FIN-9969 - select contact by Email_Type__c based on treatment rule name | cc and bcc addresses also to be captured from the contact record >>
                    else if (con.CC__c == true) {
                        ccAddresses.add(con.Email);
                    }
                    else if (con.Bcc__c == true) {
                        bccAddresses.add(con.Email);
                    }
                    // << END - MM - FIN-9969 - select contact by Email_Type__c based on treatment rule name | cc and bcc addresses also to be captured from the contact record >>
                    if (contactId == null) {
                        contactId = con.Id;
                    }
                    // << START - MM - FIN-9969 - select contact by Email_Type__c based on treatment rule name | Owner to be added in CC if notifyAccountOwner is true >>
                    // if (con.Account != null && !String.isBlank(con.Account.Owner.Email)) {
                    //     ccAddresses.add(con.Account.Owner.Email);
                    // }
                    accIdVsOwnerEmail.put(parentId, con.Account.Owner.Email);
                    // << END - MM - FIN-9969 - select contact by Email_Type__c based on treatment rule name | Owner to be added in CC if notifyAccountOwner is true >>
                    
                }
            }
            System.debug('toAddresses>>>' + toAddresses);
            if (!toAddresses.isEmpty()) {
                Account acc = new Account();
                acc.Id = parentId;
                acc.celsrm__Last_Contact_Type__c = 'Treatment Send Email';
                // << START - MM - FIN-9969 - select contact by Email_Type__c based on treatment rule name | Owner to be added in CC if notifyAccountOwner is true >>
                String ownerEmail = accIdVsOwnerEmail.get(parentId);
                // << END - MM - FIN-9969 - select contact by Email_Type__c based on treatment rule name | Owner to be added in CC if notifyAccountOwner is true >>
                System.debug('getTemplateBody>> before>> ');

                // << START - MM - FIN-10180 - call via overridable wrapper so tests can stub the managed-package response >>
                // Map<String, Object> returnMap = celsrm.SRMTreatmentUtility.getTemplateBody(tsk, treatment, tsk.Id, contactId, true, null, acc);
                Map<String, Object> returnMap = this.fetchTemplateBody(tsk, treatment, contactId, acc);
                // << END - MM - FIN-10180 >>
                String subject = returnMap.get('subject') != null ? (String) returnMap.get('subject') : '';
                String templateBody = returnMap.get('templateBody') != null ? (String) returnMap.get('templateBody') : '';

                if (!String.isBlank(templateBody) && !String.isBlank(subject)) {
                    String fromId = returnMap.get('fromId') != null && returnMap.get('fromId') != '' ? String.valueOf(returnMap.get('fromId')) : null;
                    Boolean attachmentFlag = returnMap.get('attachment') != null ? Boolean.valueOf(returnMap.get('attachment')) : false;
                    Boolean notifyAccountOwner = returnMap.get('notifyAccountOwner') != null ? Boolean.valueOf(returnMap.get('notifyAccountOwner')) : false;

                    // << START - MM - FIN-9969 - select contact by Email_Type__c based on treatment rule name | Owner to be added in CC in the end after getting update from treatment config >>
                    // if (!notifyAccountOwner) {
                    //     ccAddresses.clear();
                    // }
                    // << END - MM - FIN-9969 - select contact by Email_Type__c based on treatment rule name | Owner to be added in CC in the end after getting update from treatment config >>
                    //-- Start | FIN-7567 | Changed By Ravi | 12-May-2025 --//
                    if (returnMap.containsKey('ccAddress') && returnMap.get('ccAddress') != null) {
                        String ccAddress = String.valueOf(returnMap.get('ccAddress'));
                        //-- Start | FIN-8492 | Changed By Asera | 09-Oct-2025 --//
                        if (!String.isBlank(ccAddress)) {
                            ccAddresses = ccAddress.split('[;,]');
                        }
                        //-- End | FIN-8492 | Changed By Asera | 09-Oct-2025 --//
                    }
                    // << START - MM - FIN-9969 - select contact by Email_Type__c based on treatment rule name | Owner to be added in CC in the end after getting update from treatment config >>
                    if (notifyAccountOwner) {
                        ccAddresses.add(ownerEmail);
                    }
                    // << END - MM - FIN-9969 - select contact by Email_Type__c based on treatment rule name | Owner to be added in CC in the end after getting update from treatment config >>
                    if (returnMap.containsKey('bccAddress') && returnMap.get('bccAddress') != null) {
                        String bccAddress = String.valueOf(returnMap.get('bccAddress'));
                        //-- Start | FIN-8492 | Changed By Asera | 09-Oct-2025 --//
                        if (!String.isBlank(bccAddress)) {
                            bccAddresses = bccAddress.split('[;,]');
                        }
                        //-- End | FIN-8492 | Changed By Asera | 09-Oct-2025 --//
                    }
                    //-- Ends | FIN-7567 | Changed By Ravi | 12-May-2025 --//
                    List<Map<String, String>> attachmentobj = new List<Map<String, String>>();
                    if (attachmentFlag) {
                        //-- Starts | FIN-6334 | Changed By Dilshad | 12 Aug 2024 --//
                        String attachmentFormat = returnMap.get('attachmentFormat') != null ? String.valueOf(returnMap.get('attachmentFormat')) : 'PDF';
                        PageReference pRef;
                        Map<String, String> attachment = new Map<String, String>();
                        ContentVersion cv = new ContentVersion();
                        if (attachmentFormat == 'Excel') {
                            ApexPage[] pages = [SELECT Id FROM ApexPage WHERE Name = 'cTreatmentExcelAttachmentGenerator' AND NamespacePrefix = NULL LIMIT 1];
                            if (!pages.isEmpty()) {
                                pRef = new PageReference('/apex/c__cTreatmentExcelAttachmentGenerator');
                                pRef.getParameters().put('taskId', tsk.Id);
                                pRef.getParameters().put('accountId', parentId);
                                pRef.getParameters().put('taskSubject', tsk.Subject);
                                pRef.getParameters().put('treatmentStage', tsk.celsrm__Treatment_Stage__c);
                                pRef.getParameters().put('treatmentId', tsk.celsrm__Treatment__c);
                                pRef.getParameters().put('jsonFileName', 'Treatment Details');
                                //-- FIN-8983 | Changed By Dilshad | 28-Jan-2026 | Start --//
                                pRef.getParameters().put('attachmentType', 'Excel');
                                //-- FIN-8983 | Changed By Dilshad | 28-Jan-2026 | End --//
                                if (Test.isRunningTest()) {
                                    cv.VersionData = Blob.valueOf('Test');
                                } else {
                                    cv.VersionData = pRef.getContent();
                                }
                            } else {
                                System.debug('Page does not exist in this org');
                                pRef = Page.celsrm__TreatmentExcelAttachmentGenerator;
                                pRef.getParameters().put('taskId', tsk.Id);
                                pRef.getParameters().put('accountId', parentId);
                                pRef.getParameters().put('taskSubject', tsk.Subject);
                                pRef.getParameters().put('treatmentStage', tsk.celsrm__Treatment_Stage__c);
                                pRef.getParameters().put('treatmentId', tsk.celsrm__Treatment__c);
                                pRef.getParameters().put('jsonFileName', 'Treatment Details');
                                //-- FIN-8983 | Changed By Dilshad | 28-Jan-2026 | Start --//
                                pRef.getParameters().put('attachmentType', 'Excel');
                                //-- FIN-8983 | Changed By Dilshad | 28-Jan-2026 | End --//
                                if (Test.isRunningTest()) {
                                    cv.VersionData = Blob.valueOf('Test');
                                } else {
                                    cv.VersionData = pRef.getContent();
                                }
                            }
                        } else {
                            //-- Ends | FIN-6334 | Changed By Dilshad | 12 Aug 2024 --//
                            ApexPage[] pages = [SELECT Id FROM ApexPage WHERE Name = 'cTreatmentPDFAttachmentGenerator' AND NamespacePrefix = NULL LIMIT 1];
                            if (!pages.isEmpty()) {
                                pRef = new PageReference('/apex/c__cTreatmentPDFAttachmentGenerator');
                                pRef.getParameters().put('taskId', tsk.Id);
                                pRef.getParameters().put('accountId', parentId);
                                pRef.getParameters().put('taskSubject', tsk.Subject);
                                pRef.getParameters().put('treatmentStage', tsk.celsrm__Treatment_Stage__c);
                                pRef.getParameters().put('treatmentId', tsk.celsrm__Treatment__c);
                                pRef.getParameters().put('jsonFileName', 'Treatment Details');
                                //-- FIN-8983 | Changed By Dilshad | 28-Jan-2026 | Start --//
                                pRef.getParameters().put('attachmentType', 'PDF');
                                //-- FIN-8983 | Changed By Dilshad | 28-Jan-2026 | End --//
                                if (Test.isRunningTest()) {
                                    cv.VersionData = Blob.valueOf('Test');
                                } else {
                                    cv.VersionData = pRef.getContentAsPDF();
                                }
                            } else {
                                System.debug('Page does not exist in this org');
                                pRef = Page.celsrm__SRMTreatmentPdfGenerator;
                                pRef.getParameters().put('taskId', tsk.Id);
                                pRef.getParameters().put('accountId', parentId);
                                pRef.getParameters().put('taskSubject', tsk.Subject);
                                pRef.getParameters().put('treatmentStage', tsk.celsrm__Treatment_Stage__c);
                                pRef.getParameters().put('treatmentId', tsk.celsrm__Treatment__c);
                                pRef.getParameters().put('jsonFileName', 'Treatment Details');
                                //-- FIN-8983 | Changed By Dilshad | 28-Jan-2026 | Start --//
                                pRef.getParameters().put('attachmentType', 'PDF');
                                //-- FIN-8983 | Changed By Dilshad | 28-Jan-2026 | End --//
                                if (Test.isRunningTest()) {
                                    cv.VersionData = Blob.valueOf('Test');
                                } else {
                                    cv.VersionData = pRef.getContentAsPDF();
                                }
                            }
                        }
                        //-- Starts | FIN-6364 | Changed By Dilshad | added Attachment_Name__c field | 20 Aug 2024 --//
                        //-- Starts | FIN-8653 | Changed By Dhwanil | 09-Oct-2025 --//
                        String attName = String.valueOf(returnMap.get('attachmentName'));
                        String attachmentName = (attName != null && attName != '' ? attName : (treatment.celsrm__Attachment_Name__c != null && treatment.celsrm__Attachment_Name__c != '' ? treatment.celsrm__Attachment_Name__c : tsk.Subject));
                        //-- Ends | FIN-8653 | Changed By Dhwanil | 09-Oct-2025 --//
                        cv.Title = attachmentName;
                        cv.PathOnClient = attachmentFormat == 'Excel' ? attachmentName + '.xls' : attachmentName + '.pdf';
                        //-- Ends | FIN-6364 | Changed By Dilshad | added Attachment_Name__c field | 20 Aug 2024 --//
                        if (celsrm.GOGSecurityController.isUpsertable('ContentVersion', 'VersionData,Title,PathOnClient')) {
                            upsert cv;
                        }
                        attachment.put('Id', cv.Id);
                        attachmentobj.add(attachment);
                    }
                    //-- Starts | FIN-6379 | Changed by Dilshad | 28 Aug 2024 --//
                    Map<Object, Object> sendEmailReturnMap = celsrm.GOGEmailMapper.sendEmail(fromId, toAddresses, subject, templateBody, null, ccAddresses, bccAddresses, attachmentobj, parentId, null);
                    if (sendEmailReturnMap.containsKey(false)) { //-- Failed to send email due to SINGLE_EMAIL_LIMIT_EXCEEDED --//
                        tsk.celsrm__Auto_Dunning_Error__c = String.valueOf(sendEmailReturnMap.get(false));
                        if (celsrm.GOGSecurityController.isUpdateable('Task', namespace + 'Auto_Dunning_Error__c')) {
                            update tsk;
                        }
                    } else {
                        tsk.celsrm__Auto_Dunning_Error__c = null;
                        tsk.Status = 'Completed';
                        if (celsrm.GOGSecurityController.isUpdateable('Task', 'Status,' + namespace + 'Auto_Dunning_Error__c')) {
                            update tsk;
                        }
                        if (celsrm.GOGSecurityController.isUpdateable('Account', 'Id,' + namespace + 'last_contact_type__c')) {
                            update acc;
                        }
                        //-- Starts | FIN-6130 | Changed by Dilshad | 24 Jul 2024 --//
                        Datetime currentDateTime = DateTime.now();
                        Map<String, String> accIdActivityMap = celsrm.SRMUtilityController.insertActivity(new List<String>{ acc.Id }, 'Account__c', tsk.Subject, currentDateTime, 100, null, UserInfo.getUserId(), null, 'Internal', null);
                        List<String> childRecordIds = new List<String>();
                        childRecordIds = cSRMTreatmentUtility.getChildRecordIds(tsk, treatment);
                        if (childRecordIds != null && childRecordIds.size() > 0 && treatment.celsrm__Related_Object__c != null) {
                            Map<String, Object> additionalFields = new Map<String, Object>();
                            additionalFields.put(namespace + 'Parent_Event__c', accIdActivityMap.get(acc.Id));
                            celsrm.SRMUtilityController.insertActivity(childRecordIds, treatment.celsrm__Related_Object__c, tsk.Subject, currentDateTime, 100, null, UserInfo.getUserId(), null, 'Internal', additionalFields);
                        }
                        //-- Ends | FIN-6130 | Changed by Dilshad | 24 Jul 2024 --//
                    }
                    //-- Ends | FIN-6379 | Changed by Dilshad | 28 Aug 2024 --//
                }
            }
        }
        taskList.remove(0);
        if (!treatmentsMap.isEmpty() && !taskList.isEmpty()) {
            System.enqueueJob(new cSRMAutoDunningTreatmentManager(treatmentsMap, taskList));
        }
    }
}