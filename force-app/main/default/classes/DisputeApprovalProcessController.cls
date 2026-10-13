//-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
public without sharing class DisputeApprovalProcessController {
    private static final String STATUS_OPEN = 'Open';
    private static final String STATUS_APPROVED = 'Approved';
    private static final String STATUS_REJECTED = 'Rejected';
    private static final String STATUS_AUTO_CLOSED = 'Auto Closed';

    public class LevelAssignment {
        public Integer level;
        public Id userMasterId;
        public Id queueId;
        public Boolean isOptional;
        public String userType;
        public Decimal slDays;
    }

    public static void initiateApprovalProcess(List<Id> disputeIds) {
        if (disputeIds == null || disputeIds.isEmpty()) {
            return;
        }

        celsrm__Dispute_Configuration__c config = celsrm__Dispute_Configuration__c.getOrgDefaults();
        //-- Starts | FIN-9786 | Changed by Asera | 24-Jun-2026 --//
        if (config == null
            || config.celsrm__Use_Dispute_Workflow_Matrix__c != true
            || config.celsrm__Dispute_Resolver_Type__c != 'Dispute_Workflow_Matrix'
        ) {
            return;
        }
        //-- Ends | FIN-9786 | Changed by Asera | 24-Jun-2026 --//

        Decimal autoApproveThreshold = config.celsrm__Dispute_Auto_Approve_Threshold__c;
        String flowType = config.celsrm__Dispute_Workflow_Matrix_Flow_Type__c;
        String parallelMode = normalizeParallelApprovalMode(config.celsrm__Parallel_Approval_Mode__c);

        List<celsrm__Dispute__c> disputes = [
            SELECT Id, celsrm__Amount__c, celsrm__Balance__c, celsrm__Status__c, celsrm__Workflow_Matrix_Id__c
            FROM celsrm__Dispute__c
            WHERE Id IN :disputeIds
        ];
        if (disputes.isEmpty()) {
            return;
        }

        List<celsrm__Dispute__c> disputeUpdates = new List<celsrm__Dispute__c>();
        Set<Id> disputeIdsForMatrixEvaluation = new Set<Id>();

        Map<Id, Id> matrixByDisputeId = new Map<Id, Id>();
        Set<Id> matrixIds = new Set<Id>();

        Set<String> closureStatuses = getDisputeClosureStatuses();
        for (celsrm__Dispute__c dispute : disputes) {
            if (String.isNotBlank(dispute.celsrm__Status__c) && closureStatuses.contains(dispute.celsrm__Status__c)) {
                continue;
            }
            Decimal disputeAmount = dispute.celsrm__Amount__c != null ? dispute.celsrm__Amount__c : dispute.celsrm__Balance__c;
            if (disputeAmount == null) {
                continue;
            }

            if (autoApproveThreshold != null && disputeAmount <= autoApproveThreshold) {
                disputeUpdates.add(new celsrm__Dispute__c(
                    Id = dispute.Id,
                    celsrm__Status__c = STATUS_AUTO_CLOSED,
                    Last_Touched_By__c = UserInfo.getUserId(),
                    Last_Touched_Date__c = Date.today()
                ));
                continue;
            }

            if (dispute.celsrm__Workflow_Matrix_Id__c != null) {
                matrixByDisputeId.put(dispute.Id, dispute.celsrm__Workflow_Matrix_Id__c);
                matrixIds.add(dispute.celsrm__Workflow_Matrix_Id__c);
            } else {
                disputeIdsForMatrixEvaluation.add(dispute.Id);
            }
        }

        if (!disputeIdsForMatrixEvaluation.isEmpty()) {
            Map<Id, Id> matches = celsrm.ApprovalMatrixEvaluator.getMatchingMatrixIds(
                'Dispute_Workflow_Matrix__c',
                'Dispute__c',
                disputeIdsForMatrixEvaluation
            );
            for (Id disputeId : matches.keySet()) {
                Id matrixId = matches.get(disputeId);
                if (matrixId == null) {
                    continue;
                }
                matrixByDisputeId.put(disputeId, matrixId);
                matrixIds.add(matrixId);
            }
        }

        Map<Id, String> matrixPayloadById = new Map<Id, String>();
        for (celsrm__Dispute_Workflow_Matrix__c matrixRow : [
            SELECT Id, celsrm__Approval_Matrices__c
            FROM celsrm__Dispute_Workflow_Matrix__c
            WHERE Id IN :matrixIds
        ]) {
            matrixPayloadById.put(matrixRow.Id, matrixRow.celsrm__Approval_Matrices__c);
        }

        Map<Id, List<LevelAssignment>> allAssignmentsByDisputeId = new Map<Id, List<LevelAssignment>>();
        for (Id disputeId : matrixByDisputeId.keySet()) {
            Id matrixId = matrixByDisputeId.get(disputeId);
            List<LevelAssignment> assignments = extractAllLevelAssignments(matrixPayloadById.get(matrixId));
            if (!assignments.isEmpty()) {
                allAssignmentsByDisputeId.put(disputeId, assignments);
            }
        }

        List<celsrm__Dispute_Workflow_Details__c> detailRowsToInsert = new List<celsrm__Dispute_Workflow_Details__c>();
        for (Id disputeId : matrixByDisputeId.keySet()) {
            Id matrixId = matrixByDisputeId.get(disputeId);
            List<LevelAssignment> allAssignments = allAssignmentsByDisputeId.get(disputeId);
            if (allAssignments == null || allAssignments.isEmpty()) {
                continue;
            }

            // disputeUpdates.add(new celsrm__Dispute__c(
            //     Id = disputeId,
            //     celsrm__Status__c = STATUS_OPEN
            // ));

            Boolean isSequential = isSequentialFlow(flowType);
            Integer initialLevel = isSequential ? getMinimumLevel(allAssignments) : null;
            //-- Starts | FIN-9786 | Changed by Asera | 24-Jun-2026 --//
            List<LevelAssignment> assignmentsToActivate = isSequential
                ? allAssignments
                : getInitialParallelAssignments(allAssignments);
            //-- Ends | FIN-9786 | Changed by Asera | 24-Jun-2026 --//
            for (LevelAssignment assignment : assignmentsToActivate) {
                if (isSequential && assignment.level != initialLevel) {
                    continue;
                }
                detailRowsToInsert.add(buildDetailRow(disputeId, matrixId, assignment));
            }
        }

        if (!detailRowsToInsert.isEmpty()) {
            insert detailRowsToInsert;
            if (!isSequentialFlow(flowType)) {
                DisputeAssignmentNotificationFlowAction.sendParallelApprovalEmailsForWorkflowDetails(
                    getWorkflowDetailIds(detailRowsToInsert)
                );
            }
        }
        if (!disputeUpdates.isEmpty()) {
            update disputeUpdates;
        }
    }

    private static List<Id> getWorkflowDetailIds(List<celsrm__Dispute_Workflow_Details__c> workflowDetails) {
        List<Id> workflowDetailIds = new List<Id>();
        if (workflowDetails == null) {
            return workflowDetailIds;
        }
        for (celsrm__Dispute_Workflow_Details__c workflowDetail : workflowDetails) {
            if (workflowDetail != null && workflowDetail.Id != null) {
                workflowDetailIds.add(workflowDetail.Id);
            }
        }
        return workflowDetailIds;
    }

    public static List<LevelAssignment> extractAllLevelAssignments(String approvalMatricesJson) {
        List<LevelAssignment> output = new List<LevelAssignment>();
        if (String.isBlank(approvalMatricesJson)) {
            return output;
        }

        Object rawPayload = JSON.deserializeUntyped(approvalMatricesJson);
        if (!(rawPayload instanceof List<Object>)) {
            return output;
        }

        for (Object rowObj : (List<Object>) rawPayload) {
            if (!(rowObj instanceof Map<String, Object>)) {
                continue;
            }
            Map<String, Object> row = (Map<String, Object>) rowObj;
            if (row.containsKey('isActive') && !celsrm.ApprovalConfigController.getBooleanValue(row.get('isActive'))) {
                continue;
            }

            Integer rowLevel = toInteger(row.get('level'));
            if (rowLevel == null) {
                rowLevel = toInteger(row.get('index'));
            }
            Boolean isOptional = celsrm.ApprovalConfigController.getBooleanValue(
                row.containsKey('IsOptional') ? row.get('IsOptional') : row.get('isOptional')
            );
            String userType = row.get('userType') == null
                ? (row.get('User_Type__c') == null
                    ? (row.get('role') == null ? 'Approver' : String.valueOf(row.get('role')))
                    : String.valueOf(row.get('User_Type__c')))
                : String.valueOf(row.get('userType'));
            Decimal slDays = celsrm.ApprovalConfigController.toDecimal(
                row.containsKey('slDays') ? row.get('slDays') : row.get('celsrm__User_SLA_Days__c')
            );

            String approverType = row.get('approverType') == null ? 'User' : String.valueOf(row.get('approverType'));
            if (approverType == 'Queue') {
                Id queueId = tryParseId(row.get('approverQueueId'));
                if (queueId == null) {
                    continue;
                }
                LevelAssignment queueAssignment = new LevelAssignment();
                queueAssignment.level = rowLevel;
                queueAssignment.queueId = queueId;
                queueAssignment.isOptional = isOptional;
                queueAssignment.userType = userType;
                queueAssignment.slDays = slDays;
                output.add(queueAssignment);
                continue;
            }

            List<Object> approverUserIds = row.get('approverUserIds') instanceof List<Object>
                ? (List<Object>) row.get('approverUserIds')
                : new List<Object>();
            if (approverUserIds.isEmpty() && row.get('approverUserId') != null) {
                approverUserIds.add(row.get('approverUserId'));
            }
            if (approverUserIds.isEmpty() && row.get('approverUsers') instanceof List<Object>) {
                for (Object approverObj : (List<Object>) row.get('approverUsers')) {
                    if (approverObj instanceof Map<String, Object>) {
                        Map<String, Object> approverMap = (Map<String, Object>) approverObj;
                        if (approverMap.get('id') != null) {
                            approverUserIds.add(approverMap.get('id'));
                        }
                    }
                }
            }
            for (Object userIdObj : approverUserIds) {
                Id userMasterId = tryParseId(userIdObj);
                if (userMasterId == null) {
                    continue;
                }
                LevelAssignment userAssignment = new LevelAssignment();
                userAssignment.level = rowLevel;
                userAssignment.userMasterId = userMasterId;
                userAssignment.isOptional = isOptional;
                userAssignment.userType = userType;
                userAssignment.slDays = slDays;
                output.add(userAssignment);
            }
        }
        return output;
    }

    public static celsrm__Dispute_Workflow_Details__c buildDetailRow(
        Id disputeId,
        Id matrixId,
        LevelAssignment assignment
    ) {
        celsrm__Dispute_Workflow_Details__c detailRow = new celsrm__Dispute_Workflow_Details__c();
        detailRow.celsrm__Status__c = 'Pending';
        detailRow.celsrm__Dispute__c = disputeId;
        detailRow.celsrm__Dispute_Workflow_Matrix__c = matrixId;
        detailRow.celsrm__Workflow_Level__c = assignment.level;
        detailRow.celsrm__User_Master__c = assignment.userMasterId;
        detailRow.celsrm__Queue__c = assignment.queueId;
        detailRow.celsrm__Is_Optional__c = assignment.isOptional;
        detailRow.celsrm__Workflow_User_Type__c = assignment.userType;
        detailRow.celsrm__User_SLA_Days__c = assignment.slDays;
        return detailRow;
    }

    public static String buildWorkflowDetailKey(celsrm__Dispute_Workflow_Details__c detail) {
        return String.valueOf(detail.celsrm__Workflow_Level__c) + ':' +
            String.valueOf(detail.celsrm__User_Master__c) + ':' +
            String.valueOf(detail.celsrm__Queue__c);
    }

    public static Set<String> getExistingWorkflowDetailKeys(Id disputeId) {
        Set<String> existingKeys = new Set<String>();
        if (disputeId == null) {
            return existingKeys;
        }
        for (celsrm__Dispute_Workflow_Details__c existingDetail : [
            SELECT celsrm__Workflow_Level__c, celsrm__User_Master__c, celsrm__Queue__c
            FROM celsrm__Dispute_Workflow_Details__c
            WHERE celsrm__Dispute__c = :disputeId
        ]) {
            existingKeys.add(buildWorkflowDetailKey(existingDetail));
        }
        return existingKeys;
    }

    public static Boolean insertWorkflowDetailIfMissing(
        Id disputeId,
        Id matrixId,
        LevelAssignment assignment
    ) {
        if (disputeId == null || matrixId == null || assignment == null) {
            return false;
        }
        celsrm__Dispute_Workflow_Details__c candidate = buildDetailRow(disputeId, matrixId, assignment);
        Set<String> existingKeys = getExistingWorkflowDetailKeys(disputeId);
        if (existingKeys.contains(buildWorkflowDetailKey(candidate))) {
            return false;
        }
        insert candidate;
        return true;
    }

    //-- Starts | FIN-9786 | Changed by Asera | 24-Jun-2026 --//
    public static List<Id> insertParallelApproverDetailsIfMissing(
        Id disputeId,
        Id matrixId
    ) {
        List<Id> insertedDetailIds = new List<Id>();
        if (disputeId == null || matrixId == null) {
            return insertedDetailIds;
        }

        List<celsrm__Dispute_Workflow_Matrix__c> matrixRows = [
            SELECT Id, celsrm__Approval_Matrices__c
            FROM celsrm__Dispute_Workflow_Matrix__c
            WHERE Id = :matrixId
            LIMIT 1
        ];
        if (matrixRows.isEmpty() || String.isBlank(matrixRows[0].celsrm__Approval_Matrices__c)) {
            return insertedDetailIds;
        }

        List<LevelAssignment> approverAssignments = getApproverAssignments(
            extractAllLevelAssignments(matrixRows[0].celsrm__Approval_Matrices__c)
        );
        if (approverAssignments.isEmpty()) {
            return insertedDetailIds;
        }

        Set<String> existingKeys = getExistingWorkflowDetailKeys(disputeId);
        List<celsrm__Dispute_Workflow_Details__c> rowsToInsert = new List<celsrm__Dispute_Workflow_Details__c>();
        for (LevelAssignment assignment : approverAssignments) {
            celsrm__Dispute_Workflow_Details__c candidate = buildDetailRow(disputeId, matrixId, assignment);
            if (!existingKeys.contains(buildWorkflowDetailKey(candidate))) {
                rowsToInsert.add(candidate);
            }
        }
        if (rowsToInsert.isEmpty()) {
            return insertedDetailIds;
        }

        insert rowsToInsert;
        insertedDetailIds.addAll(getWorkflowDetailIds(rowsToInsert));
        DisputeAssignmentNotificationFlowAction.sendParallelApprovalEmailsForWorkflowDetails(insertedDetailIds);
        return insertedDetailIds;
    }

    public static void skipPendingResolverWorkflowDetails(Id disputeId, Id excludeDetailId) {
        if (disputeId == null) {
            return;
        }

        List<celsrm__Dispute_Workflow_Details__c> pendingResolvers = [
            SELECT Id
            FROM celsrm__Dispute_Workflow_Details__c
            WHERE celsrm__Dispute__c = :disputeId
            AND celsrm__Status__c = 'Pending'
            AND Id != :excludeDetailId
            AND celsrm__Workflow_User_Type__c = 'Resolver'
        ];
        for (celsrm__Dispute_Workflow_Details__c detail : pendingResolvers) {
            detail.celsrm__Status__c = 'Skipped';
        }
        if (!pendingResolvers.isEmpty()) {
            update pendingResolvers;
        }
    }
    //-- Ends | FIN-9786 | Changed by Asera | 24-Jun-2026 --//

    public static void insertNextLevelDetailsIfMissing(
        Id disputeId,
        Id matrixId,
        Integer completedLevel
    ) {
        if (disputeId == null || matrixId == null) {
            return;
        }

        List<celsrm__Dispute_Workflow_Matrix__c> matrixRows = [
            SELECT Id, celsrm__Approval_Matrices__c
            FROM celsrm__Dispute_Workflow_Matrix__c
            WHERE Id = :matrixId
            LIMIT 1
        ];
        if (matrixRows.isEmpty() || String.isBlank(matrixRows[0].celsrm__Approval_Matrices__c)) {
            return;
        }

        List<LevelAssignment> allAssignments = extractAllLevelAssignments(matrixRows[0].celsrm__Approval_Matrices__c);
        if (allAssignments.isEmpty()) {
            return;
        }

        Integer nextLevel = null;
        for (LevelAssignment assignment : allAssignments) {
            if (assignment.level == null) {
                continue;
            }
            if (completedLevel != null && assignment.level <= completedLevel) {
                continue;
            }
            if (nextLevel == null || assignment.level < nextLevel) {
                nextLevel = assignment.level;
            }
        }
        if (nextLevel == null) {
            return;
        }

        Set<String> existingKeys = getExistingWorkflowDetailKeys(disputeId);
        List<celsrm__Dispute_Workflow_Details__c> rowsToInsert = new List<celsrm__Dispute_Workflow_Details__c>();
        for (LevelAssignment assignment : allAssignments) {
            if (assignment.level != nextLevel) {
                continue;
            }
            celsrm__Dispute_Workflow_Details__c candidate = buildDetailRow(disputeId, matrixId, assignment);
            if (!existingKeys.contains(buildWorkflowDetailKey(candidate))) {
                rowsToInsert.add(candidate);
            }
        }
        if (!rowsToInsert.isEmpty()) {
            insert rowsToInsert;
        }
    }

    public static Integer getMinimumLevel(List<LevelAssignment> assignments) {
        Integer minLevel = null;
        for (LevelAssignment assignment : assignments) {
            if (assignment == null || assignment.level == null) {
                continue;
            }
            if (minLevel == null || assignment.level < minLevel) {
                minLevel = assignment.level;
            }
        }
        return minLevel == null ? 1 : minLevel;
    }

    //-- Starts | FIN-9786 | Changed by Asera | 24-Jun-2026 --//
    private static List<LevelAssignment> getInitialParallelAssignments(List<LevelAssignment> assignments) {
        List<LevelAssignment> resolverAssignments = getResolverAssignments(assignments);
        return resolverAssignments.isEmpty() ? getApproverAssignments(assignments) : resolverAssignments;
    }

    private static List<LevelAssignment> getResolverAssignments(List<LevelAssignment> assignments) {
        List<LevelAssignment> resolverAssignments = new List<LevelAssignment>();
        if (assignments == null) {
            return resolverAssignments;
        }
        for (LevelAssignment assignment : assignments) {
            if (assignment != null && isResolverUserType(assignment.userType)) {
                resolverAssignments.add(assignment);
            }
        }
        return resolverAssignments;
    }

    private static List<LevelAssignment> getApproverAssignments(List<LevelAssignment> assignments) {
        List<LevelAssignment> approverAssignments = new List<LevelAssignment>();
        if (assignments == null) {
            return approverAssignments;
        }
        for (LevelAssignment assignment : assignments) {
            if (assignment != null && !isResolverUserType(assignment.userType)) {
                approverAssignments.add(assignment);
            }
        }
        return approverAssignments;
    }

    public static Boolean isResolverUserType(String userType) {
        return String.isNotBlank(userType) && userType.trim().equalsIgnoreCase('resolver');
    }
    //-- Ends | FIN-9786 | Changed by Asera | 24-Jun-2026 --//

    public static Boolean isSequentialFlow(String flowType) {
        if (String.isBlank(flowType)) {
            return false;
        }
        String normalized = flowType.trim().toLowerCase();
        return normalized == 'sequential' || normalized == 'sequencial';
    }

    public static String normalizeParallelApprovalMode(Object rawValue) {
        String mode = rawValue == null ? null : String.valueOf(rawValue).trim();
        return mode == 'One' ? 'One' : 'All';
    }

    public static Integer toInteger(Object rawValue) {
        Decimal parsed = celsrm.ApprovalConfigController.toDecimal(rawValue);
        return parsed == null ? null : parsed.intValue();
    }

    public static Id tryParseId(Object rawValue) {
        if (rawValue == null) {
            return null;
        }
        String value = String.valueOf(rawValue);
        if (String.isBlank(value)) {
            return null;
        }
        try {
            return (Id) value;
        } catch (Exception ex) {
            return null;
        }
    }

    public static Set<String> getDisputeClosureStatuses() {
        Set<String> statuses = new Set<String>();
        celsrm__Dispute_Configuration__c config = celsrm__Dispute_Configuration__c.getOrgDefaults();
        if (config != null && String.isNotBlank(config.celsrm__Dispute_Closure_Status__c)) {
            for (String statusValue : config.celsrm__Dispute_Closure_Status__c.split(',')) {
                String trimmed = statusValue.trim();
                if (!String.isBlank(trimmed)) {
                    statuses.add(trimmed);
                }
            }
        }
        if (statuses.isEmpty()) {
            statuses.addAll(new List<String>{
                STATUS_APPROVED,
                STATUS_REJECTED,
                STATUS_AUTO_CLOSED,
                'Cancelled',
                'Closed'
            });
        }
        return statuses;
    }

    public static Boolean isDisputeClosureStatus(String statusValue) {
        return String.isNotBlank(statusValue) && getDisputeClosureStatuses().contains(statusValue);
    }

    public static String getApprovedStatusValue() {
        return STATUS_APPROVED;
    }

    public static String getRejectedStatusValue() {
        return STATUS_REJECTED;
    }
}
//-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//