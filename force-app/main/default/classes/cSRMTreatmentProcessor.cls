/**
 * Local (subscriber-org) copy of celsrm SRMTreatmentProcessor (public, not global).
 * Namespace handling:
 *  - Package custom objects/fields prefixed with celsrm__
 *  - Global package classes referenced via celsrm. (SRMUpdateBulkRecords, GOGSecurityController)
 *  - Local copies referenced by c-prefixed names (cSRMTreatmentManager, cShareTaskWithContentWorkspaceDoc)
 */
public with sharing class cSRMTreatmentProcessor implements Database.Batchable<Id>, Database.Stateful {
    public Map<Id, List<celsrm__Treatment__c>> accountIdToTreatments;
    public Map<Id, celsrm__Treatment__c> treatmentsMap = new Map<Id, celsrm__Treatment__c>();
    public Map<Id, Id> accIdTOOwnerId = new Map<Id, Id>();
    //-- Start | FIN-9703 | Changed by Dhwanil | 29 April 2026 --//
    public Map<Id, Boolean> accIdTOAutoTreatmentEnabled = new Map<Id, Boolean>();
    //-- End | FIN-9703 | Changed by Dhwanil | 29 April 2026 --//
    //-- FIN-8819 | Changed by Dilshad | 14 Jan 2025 Start --//
    public Boolean executeTaskImmediately = false;

    public cSRMTreatmentProcessor(Map<Id, List<celsrm__Treatment__c>> accountIdToTreatments, Map<Id, celsrm__Treatment__c> treatmentsMap, Map<Id, Id> accIdTOOwnerId, Boolean executeTaskImmediately, Map<Id, Boolean> accIdTOAutoTreatmentEnabled) {
    //-- FIN-8819 | Changed by Dilshad | 14 Jan 2025 End --//
        this.accountIdToTreatments = accountIdToTreatments;
        this.treatmentsMap = treatmentsMap;
        this.accIdTOOwnerId = accIdTOOwnerId;
        //-- FIN-8819 | Changed by Dilshad | 14 Jan 2025 Start --//
        this.executeTaskImmediately = executeTaskImmediately;
        //-- FIN-8819 | Changed by Dilshad | 14 Jan 2025 End --//
        //-- Start | FIN-9703 | Changed by Dhwanil | 29 April 2026 --//
        this.accIdTOAutoTreatmentEnabled = accIdTOAutoTreatmentEnabled;
        //-- end | FIN-9703 | Changed by Dhwanil | 29 April 2026
    }
    public Iterable<Id> start(Database.BatchableContext bc) {
        return accountIdToTreatments.keySet();
    }
    public void execute(Database.BatchableContext bc, List<Id> accIds) {
        Map<Id, List<celsrm__Treatment__c>> accToTreatments = new Map<Id, List<celsrm__Treatment__c>>();
        for (Id accId : accIds) {
            List<celsrm__Treatment__c> treatments = accountIdToTreatments.get(accId);
            accToTreatments.put(accId, treatments);
        }
        if (!accToTreatments.isEmpty()) {
            //-- FIN-8819 | Changed by Dilshad | 14 Jan 2025 Start --//
            System.enqueueJob(new cSRMTreatmentManager(accToTreatments, treatmentsMap, accIdTOOwnerId, executeTaskImmediately, accIdTOAutoTreatmentEnabled));
            //-- FIN-8819 | Changed by Dilshad | 14 Jan 2025 End --//
        }
    }
    public void finish(Database.BatchableContext bc) {
        List<Task> taskList = [SELECT Id, celsrm__Treatment__c, WhatId, Status, Description FROM Task WHERE Status != 'Completed' AND celsrm__Treatment__c IN :treatmentsMap.keySet() AND LastModifiedDate != TODAY];
        for (Task tsk : taskList) {
            tsk.Status = 'Completed';
            if (tsk.Description != null) {
                tsk.Description = tsk.Description + ' Auto Closure by system.';
            } else {
                tsk.Description = 'Auto Closure by system.';
            }
        }
        if (taskList.size() > 1000) {
            System.enqueueJob(new celsrm.SRMUpdateBulkRecords(taskList, 1000));
        } else if (taskList.size() > 0 && celsrm.GOGSecurityController.isUpdateable('Task', 'Status,Description')) {
            update taskList;
        }
        DateTime now = DateTime.now();
        DateTime nextRun = now.addMinutes(15);

        // Format: Seconds Minutes Hours Day_of_month Month Day_of_week [Year]
        String cronStr = nextRun.second() + ' ' + nextRun.minute() + ' ' +
                         nextRun.hour() + ' ' + nextRun.day() + ' ' +
                         nextRun.month() + ' ? ' + nextRun.year();
        if (!Test.isRunningTest()) {
            System.schedule('cShareTaskWithContentWorkspaceDoc_Step_1', cronStr, new cShareTaskWithContentWorkspaceDoc());
        }
    }
}