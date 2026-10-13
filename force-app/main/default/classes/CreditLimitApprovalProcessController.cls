public without sharing class CreditLimitApprovalProcessController {
    private class LevelAssignment {
        public Integer level;
        public Id userId;
        public Id queueId;
        public Boolean isOptional;
    }

    public static void initiateApprovalProcess(List<Id> creditReviewIds) {
        if (creditReviewIds == null || creditReviewIds.isEmpty()) {
            return;
        }

        celsrm__Credit_Configuration__c config = celsrm__Credit_Configuration__c.getOrgDefaults();
        Decimal autoApproveThreshold = config == null ? null : config.celsrm__Credit_Limit_Auto_Approve_Threshold__c;
        String flowType = config == null ? null : config.celsrm__Credit_Limit_Approval_Matrix_Flow_type__c;

        List<celsrm__Credit_Review__c> creditReviews = [
            SELECT Id,
                celsrm__Requested_Credit_Limit_Group_Currency__c,
                celsrm__Requested_Credit_Limit__c,
                celsrm__Requested_Limit_Valid_To_Date__c
            FROM celsrm__Credit_Review__c
            WHERE Id IN :creditReviewIds
        ];
        if (creditReviews.isEmpty()) {
            return;
        }

        List<celsrm__Credit_Review__c> reviewUpdates = new List<celsrm__Credit_Review__c>();
        Set<Id> reviewIdsForMatrixEvaluation = new Set<Id>();
        for (celsrm__Credit_Review__c creditReview : creditReviews) {
            Decimal requestedAmount = creditReview.celsrm__Requested_Credit_Limit_Group_Currency__c != null
                ? creditReview.celsrm__Requested_Credit_Limit_Group_Currency__c
                : creditReview.celsrm__Requested_Credit_Limit__c;
            if (requestedAmount == null) {
                continue;
            }

            if (autoApproveThreshold != null && requestedAmount <= autoApproveThreshold) {
                celsrm__User_master__c currentUser = [SELECT Id FROM celsrm__User_master__c WHERE celsrm__User__c = :UserInfo.getUserId() LIMIT 1];
                if(currentUser == null) {
                    creditReview.addError('No User Master record found for current user. Please contact your admin.');
                    continue;
                }
                reviewUpdates.add(new celsrm__Credit_Review__c(
                    Id = creditReview.Id,
                    celsrm__Status__c = 'Auto Approved',
                    celsrm__Approved_Credit_Limit__c = requestedAmount,
                    Credit_Approved_Date__c = Date.today(),
                    celsrm__Approved_Limit_Valid_To_Date__c = creditReview.celsrm__Requested_Limit_Valid_To_Date__c,
                    celsrm__Last_Action_Taken_By__c = currentUser.Id,
                    celsrm__Last_Action_Taken_Date__c = Date.today()
                ));
                continue;
            }
            reviewIdsForMatrixEvaluation.add(creditReview.Id);
        }

        Map<Id, Id> matrixByReviewId = new Map<Id, Id>();
        Set<Id> matrixIds = new Set<Id>();
        if (!reviewIdsForMatrixEvaluation.isEmpty()) {
            Map<Id, Id> matches = celsrm.ApprovalMatrixEvaluator.getMatchingMatrixIds(
                'celsrm__Credit_Limit_Approval_Matrix__c',
                'celsrm__Credit_Review__c',
                reviewIdsForMatrixEvaluation
            );
            for (Id reviewId : matches.keySet()) {
                Id matrixId = matches.get(reviewId);
                if (matrixId == null) {
                    continue;
                }
                matrixByReviewId.put(reviewId, matrixId);
                matrixIds.add(matrixId);
            }
        }

        Map<Id, String> matrixPayloadById = new Map<Id, String>();
        for (celsrm__Credit_Limit_Approval_Matrix__c matrixRow : [
            SELECT Id, celsrm__Approval_Matrices__c
            FROM celsrm__Credit_Limit_Approval_Matrix__c
            WHERE Id IN :matrixIds
        ]) {
            matrixPayloadById.put(matrixRow.Id, matrixRow.celsrm__Approval_Matrices__c);
        }

        Map<Id, List<LevelAssignment>> levelAssignmentsByReviewId = new Map<Id, List<LevelAssignment>>();
        Set<Id> queueIds = new Set<Id>();
        Set<Id> userIds = new Set<Id>();
        for (Id reviewId : matrixByReviewId.keySet()) {
            Id matrixId = matrixByReviewId.get(reviewId);
            List<LevelAssignment> assignments = extractLevelAssignments(matrixPayloadById.get(matrixId), flowType);
            levelAssignmentsByReviewId.put(reviewId, assignments);
            for (LevelAssignment assignment : assignments) {
                if (assignment.queueId != null) {
                    queueIds.add(assignment.queueId);
                }
                if (assignment.userId != null) {
                    userIds.add(assignment.userId);
                }
            }
        }

        Map<Id, String> queueNameById = new Map<Id, String>();
        if (!queueIds.isEmpty()) {
            for (Group queueRow : [SELECT Id, Name FROM Group WHERE Id IN :queueIds]) {
                queueNameById.put(queueRow.Id, queueRow.Name);
            }
        }

        Map<Id, String> userNameById = new Map<Id, String>();
        if (!userIds.isEmpty()) {
            for (celsrm__User_master__c userRow : [SELECT Id, Name FROM celsrm__User_master__c WHERE Id IN :userIds]) {
                userNameById.put(userRow.Id, userRow.Name);
            }
        }


        List<celsrm__Credit_Limit_Approval_Detail__c> detailRowsToInsert = new List<celsrm__Credit_Limit_Approval_Detail__c>();
        for (Id reviewId : matrixByReviewId.keySet()) {
            Id matrixId = matrixByReviewId.get(reviewId);
            reviewUpdates.add(new celsrm__Credit_Review__c(
                Id = reviewId,
                celsrm__Credit_Limit_Approval_Matrix__c = matrixId
                // Assigned_To_Users__c = assignedUserIdsCsv, // Comma separated list of user ids
                // Assigned_To_User_Names__c = assignedUserNamesCsv, // Comma separated list of user names
                // Assigned_To_Queue__c = first.queueId, // Queue ID
                // Assigned_To_Queue_Name__c = first.queueId == null ? null : queueNameById.get(first.queueId) // Queue Name
            ));
            List<LevelAssignment> assignments = levelAssignmentsByReviewId.get(reviewId);
            if (assignments == null || assignments.isEmpty()) {
                continue;
            }
            String assignedUserIdsCsv = buildAssignedUserIdsCsv(assignments);
            String assignedUserNamesCsv = '';
            if (String.isNotBlank(assignedUserIdsCsv)) {
                for (String userId : assignedUserIdsCsv.split(',')) {
                    if (userNameById.containsKey((Id) userId)) {
                        assignedUserNamesCsv += userNameById.get((Id) userId) + ',';
                    }
                }
                if (String.isNotBlank(assignedUserNamesCsv)) {
                    assignedUserNamesCsv = assignedUserNamesCsv.removeEnd(',');
                }
            }

            for (LevelAssignment assignment : assignments) {
                celsrm__Credit_Limit_Approval_Detail__c detailRow = new celsrm__Credit_Limit_Approval_Detail__c();
                detailRow.celsrm__Status__c = 'Pending';
                detailRow.celsrm__User_Master__c = assignment.userId;
                detailRow.celsrm__Queue__c = assignment.queueId;
                detailRow.celsrm__Level__c = assignment.level;
                detailRow.celsrm__Is_Optional__c = assignment.isOptional;
                detailRow.celsrm__Credit_Review__c = reviewId;
                detailRow.celsrm__Credit_Limit_Approval_Matrix__c = matrixId;
                detailRowsToInsert.add(detailRow);
            }
        }

        if (!detailRowsToInsert.isEmpty()) {
            insert detailRowsToInsert;
        }

        if (!reviewUpdates.isEmpty()) {
            update reviewUpdates;
        }
    }

    private static List<LevelAssignment> extractLevelAssignments(String approvalMatricesJson, String flowType) {
        if (String.isBlank(flowType)) {
            flowType = 'Sequential';
        }
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
            Integer rowLevel = toInteger(row.get('level'));
            Boolean isOptional = getBooleanValue(
                row.containsKey('IsOptional') ? row.get('IsOptional') : row.get('isOptional')
            );
            if (row.containsKey('isActive') && !getBooleanValue(row.get('isActive'))) {
                continue;
            }

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
                output.add(queueAssignment);
                continue;
            }

            List<Object> approverUserIds = row.get('approverUserIds') instanceof List<Object>
                ? (List<Object>) row.get('approverUserIds')
                : new List<Object>();
            if (approverUserIds.isEmpty() && row.get('approverUserId') != null) {
                approverUserIds.add(row.get('approverUserId'));
            }
            for (Object userIdObj : approverUserIds) {
                Id userId = tryParseId(userIdObj);
                if (userId == null) {
                    continue;
                }
                LevelAssignment userAssignment = new LevelAssignment();
                userAssignment.level = rowLevel;
                userAssignment.userId = userId;
                userAssignment.isOptional = isOptional;
                output.add(userAssignment);
            }
            if (isSequentialFlow(flowType)) {
                break;
            }
        }
        return output;
    }

    private static Integer toInteger(Object rawValue) {
        Decimal parsed = toDecimal(rawValue);
        return parsed == null ? null : parsed.intValue();
    }

    private static Id tryParseId(Object rawValue) {
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

    private static Boolean isSequentialFlow(String flowType) {
        if (String.isBlank(flowType)) {
            return false;
        }
        String normalized = flowType.trim().toLowerCase();
        return normalized == 'sequential' || normalized == 'sequencial';
    }

    private static String buildAssignedUserIdsCsv(List<LevelAssignment> assignments) {
        if (assignments == null || assignments.isEmpty()) {
            return null;
        }
        Set<String> uniqueUserIds = new Set<String>();
        for (LevelAssignment assignment : assignments) {
            if (assignment == null || assignment.userId == null) {
                continue;
            }
            uniqueUserIds.add(String.valueOf(assignment.userId));
        }
        if (uniqueUserIds.isEmpty()) {
            return null;
        }
        return String.join(new List<String>(uniqueUserIds), ',');
    }

    public static Decimal toDecimal(Object rawValue) {
        if (rawValue == null) {
            return null;
        }
        try {
            return Decimal.valueOf(String.valueOf(rawValue));
        } catch (Exception ex) {
            return null;
        }
    }

    public static Boolean getBooleanValue(Object rawValue) {
        if (rawValue == null) {
            return false;
        }
        if (rawValue instanceof Boolean) {
            return (Boolean) rawValue;
        }
        String normalized = String.valueOf(rawValue).trim().toLowerCase();
        return normalized == 'true' || normalized == '1' || normalized == 'yes';
    }
}