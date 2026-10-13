/**
 * MM - FIN-9969 - select contact by Email_Type__c based on treatment rule name
 * Local (subscriber-org) copy of celsrm SRMAutoDunningTreatmentService (global in package).
 * Namespace handling:
 *  - Package custom objects/fields prefixed with celsrm__
 *  - Local copies referenced by c-prefixed names (cSRMTreatmentMapper,
 *    cSRMAutoDunningTreatmentManager, cSRMTreatmentUtility.getCronForDatetime)
 */
public with sharing class cSRMAutoDunningTreatmentService implements Database.Batchable<sObject>, Schedulable, Database.Stateful {
    public Map<Id, celsrm__Treatment__c> treatmentsMap = new Map<Id, celsrm__Treatment__c>();
    public Set<Id> accIds = new Set<Id>();
    public Set<Id> autoTreatmentIds = new Set<Id>();
    //-- Starts | FIN-8497 | Changed by Ravi | 9 Oct 2025 --//
    public List<String> stateTreatmentIds = new List<String>();
    public Datetime futureDt;
    //-- End | FIN-8497 | Changed by Ravi | 9 Oct 2025 --//

    public cSRMAutoDunningTreatmentService() {
        // << CHANGE - MM - FIN-9969 - select contact by Email_Type__c based on treatment rule name | Added celsrm__Treatment_Name__c in query>>
        List<celsrm__Treatment__c> treList = [SELECT Id, Name, celsrm__Treatment_Name__c, celsrm__Email_Template__c, celsrm__Account_Criteria__c, celsrm__Active__c, celsrm__Related_Object__c, celsrm__Treatment_Steps__c,
                                                        celsrm__Task_Due_Date__c, celsrm__Task_Type__c, celsrm__Org_Id__c, celsrm__Template_Folder_Reference_Field__c, celsrm__Email_Template_Prefix__c,
                                                        celsrm__Attachment__c, celsrm__Notify_Account_Owner__c, celsrm__Custom_Logic_Class__c, celsrm__Consolidated_Treatment__c, celsrm__Seperate_Task_For_Step__c,
                                                        celsrm__Auto_Treatment__c, celsrm__Enable_Dynamic_Template__c, celsrm__Attachment_Format__c, celsrm__Attachment_Name__c, celsrm__Custom_Logic_For_Email_Body__c,
                                                        celsrm__Enable_Dynamic_From_Address__c, celsrm__Business_Hours__c, celsrm__CC_Source_Type__c, celsrm__CC_Address__c, celsrm__BCC_Source_Type__c, celsrm__BCC_Address__c, celsrm__Auto_Execute_After_Business_Hours__c
                                                        //-- FIN-8983 | Changed By Dilshad | 27-Jan-2026 | Start --//
                                                        , celsrm__Attachment_Template_Name__c, celsrm__Attachment_Template_Folder__c, celsrm__Attachment_Template_Folder_Ref_Field__c
                                                        //-- FIN-8983 | Changed By Dilshad | 27-Jan-2026 | End --//
                                                        FROM celsrm__Treatment__c
                                                        //-- Starts | FIN-9026 | Changed by Ravi | 5 Mar 2026 | add Where clause for intelligent dunning --//
                                                        WHERE celsrm__Active__c = TRUE AND (celsrm__Auto_Treatment__c = TRUE OR celsrm__Seperate_Task_For_Step__c = TRUE)
                                                        //-- Ends | FIN-9026 | Changed by Ravi | 5 Mar 2026 | add Where clause for intelligent dunning --//
                                                        ORDER BY CreatedDate];
        //-- Starts | FIN-8497 | Changed by Ravi | 9 Oct 2025 --//
        processTreatments(treList);
        //-- Ends | FIN-8497 | Changed by Ravi | 9 Oct 2025 --//
    }
    public cSRMAutoDunningTreatmentService(String groupName) {
        // << CHANGE - MM - FIN-9969 - select contact by Email_Type__c based on treatment rule name | Added celsrm__Treatment_Name__c in query>>
        List<celsrm__Treatment__c> treList = [SELECT Id, Name, celsrm__Treatment_Name__c, celsrm__Email_Template__c, celsrm__Account_Criteria__c, celsrm__Active__c, celsrm__Related_Object__c, celsrm__Treatment_Steps__c,
                                                        celsrm__Task_Due_Date__c, celsrm__Task_Type__c, celsrm__Org_Id__c, celsrm__Template_Folder_Reference_Field__c, celsrm__Email_Template_Prefix__c,
                                                        celsrm__Attachment__c, celsrm__Notify_Account_Owner__c, celsrm__Custom_Logic_Class__c, celsrm__Consolidated_Treatment__c, celsrm__Seperate_Task_For_Step__c,
                                                        celsrm__Auto_Treatment__c, celsrm__Enable_Dynamic_Template__c, celsrm__Attachment_Format__c, celsrm__Attachment_Name__c, celsrm__Custom_Logic_For_Email_Body__c,
                                                        celsrm__Enable_Dynamic_From_Address__c, celsrm__Business_Hours__c, celsrm__CC_Source_Type__c, celsrm__CC_Address__c, celsrm__BCC_Source_Type__c, celsrm__BCC_Address__c, celsrm__Auto_Execute_After_Business_Hours__c
                                                        //-- FIN-8983 | Changed By Dilshad | 27-Jan-2026 | Start --//
                                                        , celsrm__Attachment_Template_Name__c, celsrm__Attachment_Template_Folder__c, celsrm__Attachment_Template_Folder_Ref_Field__c
                                                        //-- FIN-8983 | Changed By Dilshad | 27-Jan-2026 | End --//
                                                        FROM celsrm__Treatment__c
                                                        //-- Starts | FIN-9026 | Changed by Ravi | 5 Mar 2026 | add Where clause for intelligent dunning --//
                                                        WHERE celsrm__Active__c = TRUE AND (celsrm__Auto_Treatment__c = TRUE OR celsrm__Seperate_Task_For_Step__c = TRUE) AND celsrm__Treatment_Group__c = :groupName
                                                        //-- Ends | FIN-9026 | Changed by Ravi | 5 Mar 2026 | add Where clause for intelligent dunning --//
                                                        ORDER BY CreatedDate];
        //-- Starts | FIN-8497 | Changed by Ravi | 9 Oct 2025 --//
        processTreatments(treList);
        //-- Ends | FIN-8497 | Changed by Ravi | 9 Oct 2025 --//
    }
    //-- Starts | FIN-8497 | Changed by Ravi | 9 Oct 2025 --//
    public cSRMAutoDunningTreatmentService(List<String> treatmentIds) {
        // << CHANGE - MM - FIN-9969 - select contact by Email_Type__c based on treatment rule name | Added celsrm__Treatment_Name__c in query>>
        List<celsrm__Treatment__c> treList = [SELECT Id, Name, celsrm__Treatment_Name__c, celsrm__Email_Template__c, celsrm__Account_Criteria__c, celsrm__Active__c, celsrm__Related_Object__c, celsrm__Treatment_Steps__c,
                                                        celsrm__Task_Due_Date__c, celsrm__Task_Type__c, celsrm__Org_Id__c, celsrm__Template_Folder_Reference_Field__c, celsrm__Email_Template_Prefix__c,
                                                        celsrm__Attachment__c, celsrm__Notify_Account_Owner__c, celsrm__Custom_Logic_Class__c, celsrm__Consolidated_Treatment__c, celsrm__Seperate_Task_For_Step__c,
                                                        celsrm__Auto_Treatment__c, celsrm__Enable_Dynamic_Template__c, celsrm__Attachment_Format__c, celsrm__Attachment_Name__c, celsrm__Custom_Logic_For_Email_Body__c,
                                                        celsrm__Enable_Dynamic_From_Address__c, celsrm__Business_Hours__c, celsrm__CC_Source_Type__c, celsrm__CC_Address__c, celsrm__BCC_Source_Type__c, celsrm__BCC_Address__c, celsrm__Auto_Execute_After_Business_Hours__c
                                                        //-- FIN-8983 | Changed By Dilshad | 27-Jan-2026 | Start --//
                                                        , celsrm__Attachment_Template_Name__c, celsrm__Attachment_Template_Folder__c, celsrm__Attachment_Template_Folder_Ref_Field__c
                                                        //-- FIN-8983 | Changed By Dilshad | 27-Jan-2026 | End --//
                                                        FROM celsrm__Treatment__c
                                                        //-- Starts | FIN-9026 | Changed by Ravi | 5 Mar 2026 | add Where clause for intelligent dunning --//
                                                        WHERE celsrm__Active__c = TRUE AND (celsrm__Auto_Treatment__c = TRUE OR celsrm__Seperate_Task_For_Step__c = TRUE) AND Id IN :treatmentIds
                                                        //-- Ends | FIN-9026 | Changed by Ravi | 5 Mar 2026 | add Where clause for intelligent dunning --//
                                                        ORDER BY CreatedDate];
        processTreatments(treList);
    }
    //-- Ends | FIN-8497 | Changed by Ravi | 9 Oct 2025 --//
    public Database.QueryLocator start(Database.BatchableContext bc) {
        //-- Starts | FIN-8497 | Changed by Ravi | 9 Oct 2025 --//
        Datetime nowDt = System.now();
        futureDt = nowDt.addHours(24);
        if (treatmentsMap.isEmpty()) {
            return Database.getQueryLocator([SELECT Id FROM Account WHERE Id = NULL]);
        }
        //-- Ends | FIN-8497 | Changed by Ravi | 9 Oct 2025 --//
        //-- Starts | FIN-9026 | Changed by Ravi | 5 Mar 2026 | add Where clause for dunning enabled --//
        String query = 'SELECT Id FROM Account WHERE celsrm__Auto_Treatment_Enabled__c=true';
        return Database.getQueryLocator(query);
        //-- Ends | FIN-9026 | Changed by Ravi | 5 Mar 2026 | add Where clause for dunning enabled --//
    }
    public void execute(Database.BatchableContext ac, List<sObject> accounts) {
        if (accounts != null && accounts.size() > 0) {
            Id accId = ((List<Account>) accounts).get(0).Id;
            List<Task> lstTask = new List<Task>();
            for (Task tsk : [SELECT Id, Subject, WhatId, celsrm__Treatment_Stage__c, celsrm__Treatment__c FROM Task WHERE celsrm__Treatment__c = :treatmentsMap.keySet() AND WhatId = :accId AND Status != 'Completed']) {
                if (autoTreatmentIds.contains(tsk.celsrm__Treatment__c)) {
                    lstTask.add(tsk);
                    continue;
                }

                celsrm__Treatment__c treatment = treatmentsMap.get(tsk.celsrm__Treatment__c);
                List<cSRMTreatmentMapper.ObjectCriteria> listOfTreatmentStep = (List<cSRMTreatmentMapper.ObjectCriteria>) JSON.deserialize(treatment.celsrm__Treatment_Steps__c, List<cSRMTreatmentMapper.ObjectCriteria>.class);
                for (cSRMTreatmentMapper.ObjectCriteria treatmentStep : listOfTreatmentStep) {
                    if (treatmentStep.autoDunning && tsk.Subject == treatmentStep.taskSubject && tsk.celsrm__Treatment_Stage__c == treatmentStep.stepName) {
                        lstTask.add(tsk);
                        break;
                    }
                }
            }
            if (!lstTask.isEmpty()) {
                System.debug('taskMap>> ' + lstTask);
                System.enqueueJob(new cSRMAutoDunningTreatmentManager(treatmentsMap, lstTask));
            }
        }
    }
    public void finish(Database.BatchableContext bc) {
        //-- Starts | FIN-8497 | Changed by Ravi | 9 Oct 2025 --//
        if (!stateTreatmentIds.isEmpty()) {
            String cron = cSRMTreatmentUtility.getCronForDatetime(futureDt);
            String jobName = 'TreatmentTaskAutoExecutionJob_' + Datetime.now().getTime();
            // Schedule your Apex class
            System.schedule(jobName, cron, new cSRMAutoDunningTreatmentService(stateTreatmentIds));
        }
        //-- Ends | FIN-8497 | Changed by Ravi | 9 Oct 2025 --//
    }
    public void execute(SchedulableContext sc) {
        //-- Starts | FIN-8497 | Changed by Ravi | 9 Oct 2025 --//
        if (!stateTreatmentIds.isEmpty()) {
            Database.executeBatch(new cSRMAutoDunningTreatmentService(stateTreatmentIds), 1);
        } else {
            Database.executeBatch(new cSRMAutoDunningTreatmentService(), 1);
        }
        //-- Ends | FIN-8497 | Changed by Ravi | 9 Oct 2025 --//
    }
    //-- Starts | FIN-8497 | Changed by Ravi | 9 Oct 2025 --//
    private void processTreatments(List<celsrm__Treatment__c> treList) {
        for (celsrm__Treatment__c tre : treList) {
            if (isWithinBusinessHours(tre)) {
                this.treatmentsMap.put(tre.Id, tre);
                if (tre.celsrm__Auto_Treatment__c) {
                    autoTreatmentIds.add(tre.Id);
                }
            } else if (tre.celsrm__Auto_Execute_After_Business_Hours__c) {
                stateTreatmentIds.add(tre.Id);
            }
        }
    }
    private Boolean isWithinBusinessHours(celsrm__Treatment__c tre) {
        if (tre.celsrm__Business_Hours__c != null) {
            return BusinessHours.isWithin(tre.celsrm__Business_Hours__c, Datetime.now());
        }
        return true;
    }
    //-- Ends | FIN-8497 | Changed by Ravi | 9 Oct 2025 --//
}