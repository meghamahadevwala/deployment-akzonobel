/**
 * Local (subscriber-org) copy of celsrm ShareTaskWithContentWorkspaceDoc (public, not global).
 * Namespace handling:
 *  - Package custom setting/fields prefixed with celsrm__ (SRM_Configuration__c)
 *  - Local copy cContentWorkspaceBatch referenced by its c-prefixed name
 *  - AsyncApexJob ApexClass.Name filters updated to the local class names so the
 *    completion check tracks the local chain's running jobs.
 */
public with sharing class cShareTaskWithContentWorkspaceDoc implements Schedulable {
    private Integer runCount;
    public cShareTaskWithContentWorkspaceDoc() {
        this.runCount = 1;
    }
    public cShareTaskWithContentWorkspaceDoc(Integer count) {
        this.runCount = count;
    }
    public void execute(SchedulableContext sc) {
        // 1. Check for active jobs
        // We exclude 'ScheduledApex' to prevent the manager from counting itself
        List<AsyncApexJob> activeJobs = [
            SELECT Id, Status, ApexClass.Name
            FROM AsyncApexJob
            WHERE Status IN ('Processing', 'Preparing', 'Queued', 'Holding')
            //-- Start | FIN-9977 | Changed By Asera | 23-Jun-2026 --//
            AND ApexClass.Name NOT IN (
                'cSRMTreatmentManager',
                'cShareTaskWithContentWorkspaceDoc')
            AND ApexClass.Name IN (
                'cSRMAutoDunningTreatmentService',
                'cSRMAutoDunningTreatmentManager'
            )
            //-- End | FIN-9977 | Changed By Asera | 23-Jun-2026 --//
        ];

        if (activeJobs.isEmpty()) {
            System.debug('All jobs are completed. Performing cleanup/notification logic...');
            insertContentWorkspaceDoc();

            // Logic is done, clean up and exit
            System.abortJob(sc.getTriggerId());
            return;
        } else {
            System.debug('There are still ' + activeJobs.size() + ' active jobs.');
        }

        // 2. Abort the current job to keep the Scheduled Jobs list clean
        if (this.runCount >= 8) {
            System.debug('Reached max limit of 8 runs. Stopping.');
            System.abortJob(sc.getTriggerId());
            return;
        }

        System.abortJob(sc.getTriggerId());

        // 3. Schedule the next run in 15 minutes
        reSchedule(this.runCount + 1);
    }

    public void reSchedule(Integer nextCount) {
        DateTime now = DateTime.now();
        DateTime nextRun = now.addMinutes(15);

        // Format: Seconds Minutes Hours Day_of_month Month Day_of_week [Year]
        String cronStr = nextRun.second() + ' ' + nextRun.minute() + ' ' +
                         nextRun.hour() + ' ' + nextRun.day() + ' ' +
                         nextRun.month() + ' ? ' + nextRun.year();

        System.schedule('cShareTaskWithContentWorkspaceDoc_Step_' + nextCount, cronStr, new cShareTaskWithContentWorkspaceDoc(nextCount));
    }

    public void insertContentWorkspaceDoc() {
        // Implement your logic to insert ContentWorkspaceDoc records here
        Set<Id> taskIds = new Map<Id, Task>([SELECT Id FROM Task WHERE CreatedDate = TODAY]).keySet();

        if (taskIds.isEmpty()) return;

        List<ContentDocumentLink> contentDocumentLinks = [SELECT Id, LinkedEntityId, ContentDocumentId, IsDeleted, SystemModstamp,
                                                        ShareType, Visibility FROM ContentDocumentLink
                                                        WHERE LinkedEntityId IN :taskIds];
        Set<Id> existingContentDocIds = new Set<Id>();
        for (ContentDocumentLink contentDocumentLink : contentDocumentLinks) {
            existingContentDocIds.add(contentDocumentLink.ContentDocumentId);
        }
        Id libraryId = getLibraryId();

        Set<Id> contentWorkspaceDocumentIds = new Set<Id>();
        for (ContentWorkspaceDoc contentWorkspaceDoc : [SELECT Id, ContentWorkspaceId, ContentDocumentId, CreatedDate, SystemModstamp, IsOwner, IsDeleted
                                                        FROM ContentWorkspaceDoc
                                                        WHERE ContentDocumentId IN :existingContentDocIds AND ContentWorkspaceId = :libraryId]) {
            contentWorkspaceDocumentIds.add(contentWorkspaceDoc.ContentDocumentId);
        }

        List<String> contentDocumentMissing = new List<String>();
        for (String contentDocId : existingContentDocIds) {
            if (!contentWorkspaceDocumentIds.contains(contentDocId)) {
                contentDocumentMissing.add(contentDocId);
            }
        }
        if (contentDocumentMissing.isEmpty()) return;

        cContentWorkspaceBatch batch = new cContentWorkspaceBatch(contentDocumentMissing, libraryId);
        Database.executeBatch(batch, 200);
    }

    private Id getLibraryId() {
        String configId = celsrm__SRM_Configuration__c.getOrgDefaults().celsrm__Treatment_File_Sharing_Library_Id__c;
        if (String.isNotBlank(configId)) return (Id) configId;
        for (ContentWorkspace cw : [SELECT Id FROM ContentWorkspace WHERE Name = 'Asset Library' LIMIT 1]) return cw.Id;
        return null;
    }
}