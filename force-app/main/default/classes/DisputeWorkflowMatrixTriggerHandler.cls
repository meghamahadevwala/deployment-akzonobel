public with sharing class DisputeWorkflowMatrixTriggerHandler {
    //-- Start | FIN-9672 | Changed by Ravi | 05 May 2026 --//
    public static void beforeSave(List<celsrm__Dispute_Workflow_Matrix__c> newRecords) {
        if (newRecords == null || newRecords.isEmpty()) {
            return;
        }

        Set<Id> explicitMasterIds = new Set<Id>();
        Set<Id> legacyUserIds = new Set<Id>();
        Map<String, String> externalNamesByEmail = new Map<String, String>();
        Map<String, String> managerEmailsByEmail = new Map<String, String>();
            //-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
            // for (celsrm__Dispute_Workflow_Matrix__c matrixRecord : newRecords) {
            // matrixRecord.celsrm__External_Key__c = matrixRecord.celsrm__Dispute_Type__c + '-' +
            //     matrixRecord.celsrm__Reason_Code__c + '-' +
            //     matrixRecord.celsrm__User_Type__c + '-' +
            //     matrixRecord.celsrm__Level__c;DisputeUserMasterBackfillDisputeUserMasterBackfill

            // if (matrixRecord.User_Master__c != null) {
            //     explicitMasterIds.add(matrixRecord.User_Master__c);
            // } else if (matrixRecord.celsrm__User__c != null) {
            //     legacyUserIds.add(matrixRecord.celsrm__User__c);
            // } else if (!String.isBlank(matrixRecord.External_Email__c)) {
            //     String normalizedEmail = DisputeUserMasterService.normalizeEmail(matrixRecord.External_Email__c);
            //     externalNamesByEmail.put(normalizedEmail, normalizedEmail);
            //     managerEmailsByEmail.put(normalizedEmail, matrixRecord.External_Manager_Email__c);
            // }
            // }
            //-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//

        if (!legacyUserIds.isEmpty()) {
            DisputeUserMasterService.syncInternalUsers(legacyUserIds);
        }
        //-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
        // Map<Id, User_Master__c> mastersById = DisputeUserMasterService.getUserMastersById(explicitMasterIds);
        // Map<Id, User_Master__c> internalMastersByUserId = DisputeUserMasterService.getInternalMastersByUserIds(legacyUserIds);
        // Map<String, User_Master__c> externalMastersByEmail = DisputeUserMasterService.ensureExternalUserMasters(
        //     externalNamesByEmail,
        //     managerEmailsByEmail
        // );

        // Each matrix row is normalized back into the master-first model while still populating legacy snapshots.
        // for (celsrm__Dispute_Workflow_Matrix__c matrixRecord : newRecords) {
        //     User_Master__c masterRecord;
        //     if (matrixRecord.User_Master__c != null) {
        //         masterRecord = mastersById.get(matrixRecord.User_Master__c);
        //     } else if (matrixRecord.celsrm__User__c != null) {
        //         masterRecord = internalMastersByUserId.get(matrixRecord.celsrm__User__c);
        //     } else if (!String.isBlank(matrixRecord.External_Email__c)) {
        //         masterRecord = externalMastersByEmail.get(DisputeUserMasterService.normalizeEmail(matrixRecord.External_Email__c));
        //     }

        //     if (masterRecord == null) {
        //         continue;
        //     }

        //     DisputeUserMasterService.applyAssignmentToWorkflowMatrix(
        //         matrixRecord,
        //         DisputeUserMasterService.resolveUserAssignment(
        //             masterRecord.Id,
        //             masterRecord.User__c != null ? String.valueOf(masterRecord.User__c) : masterRecord.Email__c,
        //             masterRecord.Name,
        //             false,
        //             masterRecord.Manager__r != null ? masterRecord.Manager__r.Email__c : matrixRecord.External_Manager_Email__c
        //         )
        //     );
        // }
        //-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
    }
    //-- End | FIN-9672 | Changed by Ravi | 05 May 2026 --//
}