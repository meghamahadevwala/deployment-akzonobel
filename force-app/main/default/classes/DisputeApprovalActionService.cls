//-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
public with sharing class DisputeApprovalActionService {
    public static String processApprovalAction(
        Id disputeId,
        String action,
        Id userMasterId,
        String note
    ) {
        return processApprovalAction(disputeId, action, userMasterId, null, note);
    }

    public static String processApprovalAction(
        Id disputeId,
        String action,
        Id userMasterId,
        Id workflowDetailId,
        String note
    ) {
        if (disputeId == null) {
            return 'Dispute Id is required.';
        }
        if (String.isBlank(action)) {
            return 'Action is required.';
        }

        String normalizedAction = action.trim().toLowerCase();
        if (normalizedAction != 'approve' && normalizedAction != 'reject' && normalizedAction != 'resolve') {
            return 'Action must be Approve, Reject, or Resolve.';
        }

        celsrm__Dispute__c dispute = [
            SELECT Id, celsrm__Status__c, celsrm__Workflow_Matrix_Id__c, celsrm__Owner__c
            FROM celsrm__Dispute__c
            WHERE Id = :disputeId
            LIMIT 1
        ];

        if (DisputeApprovalProcessController.isDisputeClosureStatus(dispute.celsrm__Status__c)) {
            return 'Dispute approval already processed. Current status: ' + dispute.celsrm__Status__c;
        }
        if (dispute.celsrm__Workflow_Matrix_Id__c == null) {
            return 'No workflow matrix is assigned to this dispute.';
        }

        celsrm__Dispute_Configuration__c config = celsrm__Dispute_Configuration__c.getOrgDefaults();
        String flowType = config == null ? 'Sequential' : config.celsrm__Dispute_Workflow_Matrix_Flow_Type__c;
        String parallelMode = DisputeApprovalProcessController.normalizeParallelApprovalMode(
            config == null ? null : config.celsrm__Parallel_Approval_Mode__c
        );
        //-- Starts | FIN-9786 | Changed by Asera | 24-Jun-2026 --//
        Boolean isSequential = DisputeApprovalProcessController.isSequentialFlow(flowType);
        //-- Ends | FIN-9786 | Changed by Asera | 24-Jun-2026 --//
        Boolean allowDelegated = config != null && config.celsrm__Allow_Delegated_User_Manger_to_act__c;
        Boolean allowOwnerQueue = config != null && config.celsrm__Owner_Can_Act_on_Queue_Disputes__c;

        Set<Id> actingUserMasterIds = resolveActingUserMasterIds(userMasterId);
        if (actingUserMasterIds.isEmpty()) {
            return 'No user master found for the acting user.';
        }

        List<celsrm__Dispute_Workflow_Details__c> pendingDetails = [
            SELECT Id, celsrm__Workflow_Level__c, celsrm__User_Master__c, celsrm__Queue__c,
                   celsrm__Is_Optional__c, celsrm__Status__c, celsrm__Dispute_Workflow_Matrix__c,
                   celsrm__Workflow_User_Type__c
            FROM celsrm__Dispute_Workflow_Details__c
            WHERE celsrm__Dispute__c = :disputeId
            AND celsrm__Status__c = 'Pending'
            ORDER BY celsrm__Workflow_Level__c ASC NULLS LAST, CreatedDate ASC
        ];
        if (pendingDetails.isEmpty()) {
            return 'No pending approval steps found for this dispute.';
        }

        celsrm__Dispute_Workflow_Details__c actingDetail = findActingDetail(
            dispute,
            pendingDetails,
            actingUserMasterIds,
            allowDelegated,
            allowOwnerQueue,
            workflowDetailId
        );
        if (actingDetail == null) {
            return 'Current user is not eligible to act on pending approval steps.';
        }

        //-- Starts | FIN-9786 | Changed by Asera | 24-Jun-2026 --//
        Boolean actingOnResolverStep = isResolverWorkflowStep(actingDetail.celsrm__Workflow_User_Type__c);
        if (!isSequential) {
            if (normalizedAction == 'resolve' && !actingOnResolverStep) {
                return 'Resolve action is only available during the resolver phase.';
            }
            if (normalizedAction == 'approve' && actingOnResolverStep) {
                return 'Approve action is only available during the approval phase.';
            }
            if (normalizedAction == 'approve' && dispute.celsrm__Status__c != 'Pending Approval') {
                return 'Approval is not available until the dispute is pending approval.';
            }
            if (normalizedAction == 'resolve' && dispute.celsrm__Status__c == 'Pending Approval') {
                return 'Resolution phase is already completed for this dispute.';
            }
        }
        //-- Ends | FIN-9786 | Changed by Asera | 24-Jun-2026 --//

        closeOpenTasksForDispute(disputeId, userMasterId);

        Date actionDate = Date.today();
        actingDetail.celsrm__Status__c = normalizedAction == 'approve'
            ? 'Approved'
            : (normalizedAction == 'reject' ? 'Rejected' : 'Resolved');
        actingDetail.celsrm__User_Action__c = getUserActionValue(normalizedAction);
        actingDetail.celsrm__Action_Taken_By__c = UserInfo.getUserId();
        actingDetail.celsrm__Action_Date__c = actionDate;
        update actingDetail;

        celsrm__Dispute__c disputeUpdate = new celsrm__Dispute__c(
            Id = dispute.Id,
            Last_Touched_By__c = UserInfo.getUserId(),
            Last_Touched_Date__c = actionDate
        );

        if (normalizedAction == 'resolve') {
            if (isSequential) {
                activateNextSequentialLevel(dispute, actingDetail.celsrm__Workflow_Level__c);
                if (applyNextPendingAssignmentToDispute(disputeId, disputeUpdate)) {
                    update disputeUpdate;
                    return 'Dispute has been resolved and assigned to the next workflow step.';
                }
            //-- Starts | FIN-9786 | Changed by Asera | 24-Jun-2026 --//
            } else {
                applyFinalActionUserMasterToDispute(disputeUpdate, actingDetail);
                if (parallelMode == 'All' && hasRequiredPendingResolverDetails(disputeId)) {
                    update disputeUpdate;
                    return 'Dispute has been resolved. Waiting for other resolvers.';
                }

                DisputeApprovalProcessController.skipPendingResolverWorkflowDetails(disputeId, actingDetail.Id);
                List<Id> approverDetailIds = DisputeApprovalProcessController.insertParallelApproverDetailsIfMissing(
                    disputeId,
                    dispute.celsrm__Workflow_Matrix_Id__c
                );
                if (!approverDetailIds.isEmpty() || hasPendingApproverDetails(disputeId)) {
                    disputeUpdate.celsrm__Status__c = 'Pending Approval';
                    update disputeUpdate;
                    return 'Dispute has been resolved. Waiting for approvers.';
                }
            }
            //-- Ends | FIN-9786 | Changed by Asera | 24-Jun-2026 --//
            disputeUpdate.celsrm__Status__c = DisputeApprovalProcessController.getApprovedStatusValue();
            applyFinalActionUserMasterToDispute(disputeUpdate, actingDetail);
            disputeUpdate.External_Resolver_Email__c = null;
            disputeUpdate.celsrm__Workflow_Matrix_Id__c = null;
            disputeUpdate.celsrm__Close_Date__c = actionDate;
            skipRemainingPendingDetails(disputeId, null);
            update disputeUpdate;
            return 'Dispute has been resolved successfully.';
        }

        if (normalizedAction == 'reject') {
            disputeUpdate.celsrm__Status__c = DisputeApprovalProcessController.getRejectedStatusValue();
            applyFinalActionUserMasterToDispute(disputeUpdate, actingDetail);
            disputeUpdate.External_Resolver_Email__c = null;
            disputeUpdate.celsrm__Workflow_Matrix_Id__c = null;
            disputeUpdate.celsrm__Close_Date__c = actionDate;
            rejectRemainingPendingDetails(disputeId, actingDetail.Id);
            update disputeUpdate;
            return 'Dispute has been rejected successfully.';
        }

        if (isSequential) {
            if (!isCurrentLevelComplete(disputeId, actingDetail.celsrm__Workflow_Level__c)) {
                update disputeUpdate;
                return 'Approval recorded. Waiting for other approvers at the current level.';
            }
            activateNextSequentialLevel(dispute, actingDetail.celsrm__Workflow_Level__c);
            Boolean hasRequiredPending = hasRequiredPendingDetails(disputeId);
            if (!hasRequiredPending) {
                disputeUpdate.celsrm__Status__c = DisputeApprovalProcessController.getApprovedStatusValue();
                applyFinalActionUserMasterToDispute(disputeUpdate, actingDetail);
                disputeUpdate.External_Resolver_Email__c = null;
                disputeUpdate.celsrm__Workflow_Matrix_Id__c = null;
                skipRemainingPendingDetails(disputeId, null);
            } else {
                applyNextPendingAssignmentToDispute(disputeId, disputeUpdate);
            }
            update disputeUpdate;
            return hasRequiredPending
                ? 'Approval recorded. Next approval level has been activated.'
                : 'Dispute has been approved successfully.';
        }

        if (parallelMode == 'One') {
            disputeUpdate.celsrm__Status__c = DisputeApprovalProcessController.getApprovedStatusValue();
            applyFinalActionUserMasterToDispute(disputeUpdate, actingDetail);
            skipRemainingPendingDetails(disputeId, actingDetail.Id);
            update disputeUpdate;
            return 'Dispute has been approved successfully.';
        }

        //-- Starts | FIN-9786 | Changed by Asera | 24-Jun-2026 --//
        if (!hasRequiredPendingApproverDetails(disputeId)) {
        //-- Ends | FIN-9786 | Changed by Asera | 24-Jun-2026 --//
            disputeUpdate.celsrm__Status__c = DisputeApprovalProcessController.getApprovedStatusValue();
            applyFinalActionUserMasterToDispute(disputeUpdate, actingDetail);
            skipRemainingPendingDetails(disputeId, null);
            update disputeUpdate;
            return 'Dispute has been approved successfully.';
        }

        update disputeUpdate;
        return 'Approval recorded. Waiting for other approvers.';
    }

    private static Set<Id> resolveActingUserMasterIds(Id userMasterId) {
        Set<Id> userMasterIds = new Set<Id>();
        if (userMasterId != null) {
            for (celsrm__User_Master__c userMaster : [SELECT Id FROM celsrm__User_Master__c WHERE Id = :userMasterId LIMIT 1]) {
                userMasterIds.add(userMaster.Id);
            }
        }
        if (userMasterIds.isEmpty()) {
            userMasterIds.addAll(CreditReviewAccessUtil.getCurrentUserMasterIds(UserInfo.getUserId()));
        }
        return userMasterIds;
    }

    private static celsrm__Dispute_Workflow_Details__c findActingDetail(
        celsrm__Dispute__c dispute,
        List<celsrm__Dispute_Workflow_Details__c> pendingDetails,
        Set<Id> actingUserMasterIds,
        Boolean allowDelegated,
        Boolean allowOwnerQueue,
        Id workflowDetailId
    ) {
        Set<Id> actingQueueIds = CreditReviewAccessUtil.getQueueIdsForUserWithNestedGroups(UserInfo.getUserId());

        if (workflowDetailId != null) {
            for (celsrm__Dispute_Workflow_Details__c detail : pendingDetails) {
                if (detail.Id == workflowDetailId && isDirectlyEligibleDetail(
                    dispute,
                    detail,
                    actingUserMasterIds,
                    actingQueueIds,
                    allowOwnerQueue
                )) {
                    return detail;
                }
            }
            return null;
        }

        for (celsrm__Dispute_Workflow_Details__c detail : pendingDetails) {
            if (detail.celsrm__User_Master__c != null && actingUserMasterIds.contains(detail.celsrm__User_Master__c)) {
                return detail;
            }
        }

        for (celsrm__Dispute_Workflow_Details__c detail : pendingDetails) {
            if (detail.celsrm__Queue__c == null || !actingQueueIds.contains(detail.celsrm__Queue__c)) {
                continue;
            }
            if (dispute.celsrm__Owner__c == UserInfo.getUserId() && allowOwnerQueue != true) {
                continue;
            }
            return detail;
        }

        if (allowDelegated && !actingUserMasterIds.isEmpty()) {
            Set<Id> pendingUserMasterIds = new Set<Id>();
            Set<Id> pendingQueueIds = new Set<Id>();
            for (celsrm__Dispute_Workflow_Details__c detail : pendingDetails) {
                if (detail.celsrm__User_Master__c != null) {
                    pendingUserMasterIds.add(detail.celsrm__User_Master__c);
                }
                if (detail.celsrm__Queue__c != null) {
                    pendingQueueIds.add(detail.celsrm__Queue__c);
                }
            }
            if (!pendingUserMasterIds.isEmpty() &&
                CreditReviewAccessUtil.isDelegatedOrManagerForAnyMaster(pendingUserMasterIds, actingUserMasterIds)
            ) {
                for (celsrm__Dispute_Workflow_Details__c detail : pendingDetails) {
                    if (detail.celsrm__User_Master__c != null) {
                        return detail;
                    }
                }
            }
            if (!pendingQueueIds.isEmpty()) {
                Set<Id> queueMemberUserIds = CreditReviewAccessUtil.getUserIdsForQueuesWithNestedGroups(pendingQueueIds);
                if (!queueMemberUserIds.isEmpty() &&
                    CreditReviewAccessUtil.isDelegatedOrManagerForAnySalesforceUser(queueMemberUserIds, actingUserMasterIds)
                ) {
                    for (celsrm__Dispute_Workflow_Details__c detail : pendingDetails) {
                        if (detail.celsrm__Queue__c != null) {
                            return detail;
                        }
                    }
                }
            }
        }
        return null;
    }

    private static Boolean isDirectlyEligibleDetail(
        celsrm__Dispute__c dispute,
        celsrm__Dispute_Workflow_Details__c detail,
        Set<Id> actingUserMasterIds,
        Set<Id> actingQueueIds,
        Boolean allowOwnerQueue
    ) {
        if (detail == null) {
            return false;
        }
        if (detail.celsrm__User_Master__c != null && actingUserMasterIds.contains(detail.celsrm__User_Master__c)) {
            return true;
        }
        if (detail.celsrm__Queue__c == null || !actingQueueIds.contains(detail.celsrm__Queue__c)) {
            return false;
        }
        return dispute == null || dispute.celsrm__Owner__c != UserInfo.getUserId() || allowOwnerQueue == true;
    }

    private static Boolean applyNextPendingAssignmentToDispute(Id disputeId, celsrm__Dispute__c disputeUpdate) {
        if (disputeId == null || disputeUpdate == null) {
            return false;
        }
        List<celsrm__Dispute_Workflow_Details__c> nextDetails = [
            SELECT Id, celsrm__User_Master__c, celsrm__Dispute_Workflow_Matrix__c, celsrm__Workflow_User_Type__c
            FROM celsrm__Dispute_Workflow_Details__c
            WHERE celsrm__Dispute__c = :disputeId
            AND celsrm__Status__c = 'Pending'
            ORDER BY celsrm__Workflow_Level__c ASC NULLS LAST, CreatedDate ASC
            LIMIT 1
        ];
        if (nextDetails.isEmpty()) {
            return false;
        }

        celsrm__Dispute_Workflow_Details__c nextDetail = nextDetails[0];
        disputeUpdate.celsrm__Resolver_User_Master__c = nextDetail.celsrm__User_Master__c;
        disputeUpdate.External_Resolver_Email__c = null;
        disputeUpdate.celsrm__Workflow_Matrix_Id__c = nextDetail.celsrm__Dispute_Workflow_Matrix__c;
        disputeUpdate.celsrm__Status__c = isResolverWorkflowStep(nextDetail.celsrm__Workflow_User_Type__c)
            ? 'In Progress'
            : 'Pending Approval';
        return true;
    }

    private static Boolean isResolverWorkflowStep(String workflowUserType) {
        //-- Starts | FIN-9786 | Changed by Asera | 24-Jun-2026 --//
        return DisputeApprovalProcessController.isResolverUserType(workflowUserType);
        //-- Ends | FIN-9786 | Changed by Asera | 24-Jun-2026 --//
    }

    private static void applyFinalActionUserMasterToDispute(
        celsrm__Dispute__c disputeUpdate,
        celsrm__Dispute_Workflow_Details__c actingDetail
    ) {
        if (disputeUpdate == null || actingDetail == null || actingDetail.celsrm__User_Master__c == null) {
            return;
        }
        disputeUpdate.celsrm__Resolver_User_Master__c = actingDetail.celsrm__User_Master__c;
        disputeUpdate.External_Resolver_Email__c = null;
    }

    private static String getUserActionValue(String normalizedAction) {
        if (normalizedAction == 'approve') {
            return 'Approved';
        }
        if (normalizedAction == 'reject') {
            return 'Rejected';
        }
        if (normalizedAction == 'resolve') {
            return 'Dispute Resolved';
        }
        return normalizedAction;
    }

    private static void closeOpenTasksForDispute(Id disputeId, Id userMasterId) {
        if (disputeId == null) {
            return;
        }

        Id taskOwnerId = resolveTaskOwnerId(userMasterId);
        if (taskOwnerId == null) {
            return;
        }

        List<Task> tasksToClose = [
            SELECT Id, Status
            FROM Task
            WHERE RecurrenceType = null
            AND WhatId = :disputeId
            AND OwnerId = :taskOwnerId
            AND Status != 'Completed'
        ];
        if (tasksToClose.isEmpty()) {
            return;
        }

        for (Task taskRecord : tasksToClose) {
            taskRecord.Status = 'Completed';
        }
        Database.update(tasksToClose, AccessLevel.SYSTEM_MODE);
    }

    private static Id resolveTaskOwnerId(Id userMasterId) {
        if (userMasterId == null) {
            return UserInfo.getUserId();
        }

        List<celsrm__User_Master__c> userMasters = [
            SELECT celsrm__User__c
            FROM celsrm__User_Master__c
            WHERE Id = :userMasterId
            LIMIT 1
        ];
        if (!userMasters.isEmpty() && userMasters[0].celsrm__User__c != null) {
            return userMasters[0].celsrm__User__c;
        }
        return UserInfo.getUserId();
    }

    private static Boolean isCurrentLevelComplete(Id disputeId, Decimal currentLevel) {
        for (celsrm__Dispute_Workflow_Details__c detail : [
            SELECT Id, celsrm__Is_Optional__c
            FROM celsrm__Dispute_Workflow_Details__c
            WHERE celsrm__Dispute__c = :disputeId
            AND celsrm__Workflow_Level__c = :currentLevel
            AND celsrm__Status__c = 'Pending'
        ]) {
            if (detail.celsrm__Is_Optional__c != true) {
                return false;
            }
        }
        return true;
    }

    private static void activateNextSequentialLevel(celsrm__Dispute__c dispute, Decimal completedLevel) {
        Integer completedLevelInt = completedLevel == null ? null : completedLevel.intValue();
        DisputeApprovalProcessController.insertNextLevelDetailsIfMissing(
            dispute.Id,
            dispute.celsrm__Workflow_Matrix_Id__c,
            completedLevelInt
        );
    }

    private static String buildDetailKey(celsrm__Dispute_Workflow_Details__c detail) {
        return DisputeApprovalProcessController.buildWorkflowDetailKey(detail);
    }

    private static Boolean hasPendingDetails(Id disputeId) {
        return hasRequiredPendingDetails(disputeId) || hasOptionalPendingDetails(disputeId);
    }

    private static Boolean hasRequiredPendingDetails(Id disputeId) {
        return [
            SELECT COUNT()
            FROM celsrm__Dispute_Workflow_Details__c
            WHERE celsrm__Dispute__c = :disputeId
            AND celsrm__Status__c = 'Pending'
            AND celsrm__Is_Optional__c != true
        ] > 0;
    }

    private static Boolean hasOptionalPendingDetails(Id disputeId) {
        return [
            SELECT COUNT()
            FROM celsrm__Dispute_Workflow_Details__c
            WHERE celsrm__Dispute__c = :disputeId
            AND celsrm__Status__c = 'Pending'
            AND celsrm__Is_Optional__c = true
        ] > 0;
    }

    //-- Starts | FIN-9786 | Changed by Asera | 24-Jun-2026 --//
    private static Boolean hasPendingApproverDetails(Id disputeId) {
        return [
            SELECT COUNT()
            FROM celsrm__Dispute_Workflow_Details__c
            WHERE celsrm__Dispute__c = :disputeId
            AND celsrm__Status__c = 'Pending'
            AND (celsrm__Workflow_User_Type__c = null OR celsrm__Workflow_User_Type__c != 'Resolver')
        ] > 0;
    }

    private static Boolean hasRequiredPendingResolverDetails(Id disputeId) {
        return [
            SELECT COUNT()
            FROM celsrm__Dispute_Workflow_Details__c
            WHERE celsrm__Dispute__c = :disputeId
            AND celsrm__Status__c = 'Pending'
            AND celsrm__Is_Optional__c != true
            AND celsrm__Workflow_User_Type__c = 'Resolver'
        ] > 0;
    }

    private static Boolean hasRequiredPendingApproverDetails(Id disputeId) {
        return [
            SELECT COUNT()
            FROM celsrm__Dispute_Workflow_Details__c
            WHERE celsrm__Dispute__c = :disputeId
            AND celsrm__Status__c = 'Pending'
            AND celsrm__Is_Optional__c != true
            AND (celsrm__Workflow_User_Type__c = null OR celsrm__Workflow_User_Type__c != 'Resolver')
        ] > 0;
    }
    //-- Ends | FIN-9786 | Changed by Asera | 24-Jun-2026 --//

    private static void skipRemainingPendingDetails(Id disputeId, Id excludeDetailId) {
        List<celsrm__Dispute_Workflow_Details__c> pendingToSkip = [
            SELECT Id
            FROM celsrm__Dispute_Workflow_Details__c
            WHERE celsrm__Dispute__c = :disputeId
            AND celsrm__Status__c = 'Pending'
            AND Id != :excludeDetailId
        ];
        for (celsrm__Dispute_Workflow_Details__c detail : pendingToSkip) {
            detail.celsrm__Status__c = 'Skipped';
        }
        if (!pendingToSkip.isEmpty()) {
            update pendingToSkip;
        }
    }

    private static void rejectRemainingPendingDetails(Id disputeId, Id excludeDetailId) {
        List<celsrm__Dispute_Workflow_Details__c> pendingToReject = [
            SELECT Id
            FROM celsrm__Dispute_Workflow_Details__c
            WHERE celsrm__Dispute__c = :disputeId
            AND celsrm__Status__c = 'Pending'
            AND Id != :excludeDetailId
        ];
        for (celsrm__Dispute_Workflow_Details__c detail : pendingToReject) {
            detail.celsrm__Status__c = 'Rejected';
            detail.celsrm__User_Action__c = 'Revoked Due To Rejection';
            detail.celsrm__Action_Date__c = Date.today();
            detail.celsrm__Action_Taken_By__c = UserInfo.getUserId();
        }
        if (!pendingToReject.isEmpty()) {
            update pendingToReject;
        }
    }
}
//-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//