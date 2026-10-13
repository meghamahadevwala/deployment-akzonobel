global with sharing class UpdateCreditReviewController implements celsrm.GOGIScreenCustomLogic {
    global Map<Object, Object> invoke(String functionName, Map<Object, Object> inMap){
        try {
            system.debug('FunctionName>>>>>'+functionName);
            if(functionName == 'onPageLoadFunction'){
                inMap = onPageLoadFunction(inMap);
            } else if(functionName == 'UpdateCreditReview') {
                UpdateCreditReview(inMap);
            } 
        } catch(exception ex){
            String errorMessage = 'ClassName: UpdateCreditReviewController | Method: invoke() | Linenumber: ' + ex.getLineNumber() + ' | Message: ' + ex.getMessage();
            System.debug('errorMessage: ' + errorMessage);
        }

        return inMap;
    }

    public static Map<Object, Object> onPageLoadFunction(Map<Object, Object> inMap) {
        Id currentUserId = UserInfo.getUserId();
        String creditReviewId = (String) inMap.get('Id');
        celsrm__Credit_Review__c creditReview = [
            SELECT Id, Name, celsrm__Account__c, celsrm__Account__r.AccountNumber, celsrm__Account__r.Name, CurrencyIsoCode, celsrm__Credit_Limit_Approval_Matrix__c,
                celsrm__Requested_Credit_Limit__c, celsrm__Requested_Credit_Limit_Group_Currency__c, celsrm__Credit_Control_Area__c, celsrm__Credit_Segment__c
            FROM celsrm__Credit_Review__c
            WHERE Id = :creditReviewId
            LIMIT 1
        ];
        inMap.put('creditReviewNumber', creditReview.Name);
        inMap.put('customerNumber', creditReview.celsrm__Account__r.AccountNUmber);
        inMap.put('customerName', new Map<String, Object>{
            'id' => creditReview.celsrm__Account__c,
            'name' => creditReview.celsrm__Account__r.Name
        });
        inMap.put('creditControlArea', creditReview.celsrm__Credit_Control_Area__c);
        inMap.put('creditSegment', creditReview.celsrm__Credit_Segment__c);
        inMap.put('requestedCreditLimit', creditReview.celsrm__Requested_Credit_Limit__c);
        inMap.put('requestedCreditLimitGroup', creditReview.celsrm__Requested_Credit_Limit_Group_Currency__c);
        inMap.put('currencyIsoCode', creditReview.CurrencyIsoCode);
        inMap.put('creditLimitApprovalMatrixId', creditReview.celsrm__Credit_Limit_Approval_Matrix__c);
        // Default behavior
        inMap.put('sendToNextApprover', false);
        inMap.put('approverIsOptional', 'false');
        inMap.put('isLastApprover', 'true');

        String flowType = celsrm__Credit_Configuration__c.getOrgDefaults().celsrm__Credit_Limit_Approval_Matrix_Flow_type__c;
        Boolean isSequentialFlow = isSequentialFlowType(flowType);
        inMap.put('isSequentialFlow', String.valueOf(isSequentialFlow));
        List<celsrm__Credit_Limit_Approval_Detail__c> pendingDetails = [
            SELECT Id, celsrm__Level__c, celsrm__User_Master__c, celsrm__Queue__c, CreatedDate, celsrm__Is_Optional__c
            FROM celsrm__Credit_Limit_Approval_Detail__c
            WHERE celsrm__Credit_Review__c = :creditReviewId
            AND celsrm__Status__c = 'Pending'
            ORDER BY celsrm__Level__c ASC, CreatedDate ASC
        ];
        // There is no pending details for the credit review
        if (pendingDetails.isEmpty()) {
            inMap.put('stopExecution', true);
            inMap.put('ggErrorMessage', 'You are not authorized to take action on this credit review.');
            inMap.put('doNotSubmit', 'You are not authorized to take action on this credit review.');
            return inMap;
        }

        // Current user's user master Id
        Set<Id> currentUserMasterIds = getCurrentUserMasterIdsFromMap(inMap, currentUserId);
        // Current user's user master Id + user master Id where current user is delegated/manager
        Set<Id> actionableUserMasterIds = getActionableUserMasterIds(currentUserMasterIds);
        // Queue access is derived from actor user-master context.
        Set<Id> currentUserQueueIds = getQueueIdsForUserMasters(currentUserMasterIds, currentUserId);
        // Find the current pending detail for the current user
        celsrm__Credit_Limit_Approval_Detail__c currentPendingDetail = null;
        if(inMap.keySet().contains('creditLimitApprovalDetailId') && inMap.get('creditLimitApprovalDetailId') != null){
            Id providedDetailId = tryParseId(String.valueOf(inMap.get('creditLimitApprovalDetailId')));
            if(providedDetailId != null){
                for(celsrm__Credit_Limit_Approval_Detail__c detail : pendingDetails){
                    if(detail.Id == providedDetailId){
                        currentPendingDetail = detail;
                    }
                }
            }
        }
        if(currentPendingDetail == null){
            currentPendingDetail = findCurrentPendingDetailForUser(
                pendingDetails,
                isSequentialFlow,
                currentUserMasterIds,
                actionableUserMasterIds,
                currentUserQueueIds
            );
        }
        
        if (currentPendingDetail == null) {
            inMap.put('stopExecution', true);
            inMap.put('ggErrorMessage', 'You are not authorized to take action on this credit review.');
            inMap.put('doNotSubmit', 'You are not authorized to take action on this credit review.');
            return inMap;
        }
        inMap.put('creditLimitApprovalDetailId', currentPendingDetail.Id);
        inMap.put('isCurrentDetailOptional', currentPendingDetail.celsrm__Is_Optional__c);
        if ((String) inMap.get('userAction') != 'approve') {
            return inMap;
        }

        // If parallel flow, no next approver resolution on onload.
        if (!isSequentialFlow) {
            // Parallel: no next approver resolution on onload.
            inMap.put('sendToNextApprover', false);
            inMap.put('isLastApprover', 'true');
            String parallelMode = celsrm__Credit_Configuration__c.getOrgDefaults().celsrm__Parallel_Approval_Mode__c;
            Boolean isParallelAllMode = isParallelAllMode(parallelMode);
            if(isParallelAllMode) {
                Integer pendingOtherApprovers = [
                    SELECT COUNT()
                    FROM celsrm__Credit_Limit_Approval_Detail__c
                    WHERE celsrm__Credit_Review__c = :creditReview.Id
                    AND celsrm__Status__c = 'Pending'
                    AND Id != :currentPendingDetail.Id
                    AND celsrm__Is_Optional__c = false
                ];
                if (pendingOtherApprovers > 0) {
                    inMap.put('parallelPendingApprovers', 'true');
                    return inMap;
                }
            }
            inMap.put('parallelPendingApprovers', 'false');
            return inMap;
        }

        // Find the next level and next approver
        Integer nextLevel = Integer.valueOf(currentPendingDetail.celsrm__Level__c + 1);
        // Find the credit limit approval matrix configuration
        celsrm__Credit_Limit_Approval_Matrix__c matrixConfig = [
            SELECT Id, Name, celsrm__Approval_Matrices__c
            FROM celsrm__Credit_Limit_Approval_Matrix__c
            WHERE Id = :creditReview.celsrm__Credit_Limit_Approval_Matrix__c
            LIMIT 1
        ];
        // If no approval matrices found, no next approver resolution on onload.
        if (String.isBlank(matrixConfig.celsrm__Approval_Matrices__c)) {
            inMap.put('sendToNextApprover', false);
            inMap.put('isLastApprover', 'true');
            return inMap;
        }

        // Parse the approval matrices
        Object parsedPayload = JSON.deserializeUntyped(matrixConfig.celsrm__Approval_Matrices__c);
        if (!(parsedPayload instanceof List<Object>)) {
            inMap.put('sendToNextApprover', false);
            inMap.put('isLastApprover', 'true');
            return inMap;
        }

        // Find the next level rows
        List<Map<String, Object>> nextLevelRows = new List<Map<String, Object>>();
        for (Object rowObj : (List<Object>) parsedPayload) {
            if (!(rowObj instanceof Map<String, Object>)) {
                continue;
            }
            Map<String, Object> row = (Map<String, Object>) rowObj;
            Decimal rowLevelDecimal = CreditLimitApprovalProcessController.toDecimal(row.get('level'));
            Integer rowLevel = rowLevelDecimal == null ? null : rowLevelDecimal.intValue();
            if (rowLevel == null || rowLevel != nextLevel) {
                continue;
            }
            Boolean isActive = row.containsKey('isActive')
                ? CreditLimitApprovalProcessController.getBooleanValue(row.get('isActive'))
                : true;
            if (!isActive) {
                continue;
            }
            nextLevelRows.add(row);
        }

        if (nextLevelRows.isEmpty()) {
            inMap.put('sendToNextApprover', false);
            inMap.put('isLastApprover', 'true');
            return inMap;
        }

        Set<Id> nextApproverUserIds = new Set<Id>();
        Set<Id> queueIds = new Set<Id>();
        for (Map<String, Object> approverRow : nextLevelRows) {
            List<Object> approverUserIds = approverRow.get('approverUserIds') instanceof List<Object>
                ? (List<Object>) approverRow.get('approverUserIds')
                : new List<Object>();
            if (approverUserIds.isEmpty() && approverRow.get('approverUserId') != null) {
                approverUserIds.add(approverRow.get('approverUserId'));
            }
            for (Object userObj : approverUserIds) {
                if (userObj == null) {
                    continue;
                }
                try {
                    nextApproverUserIds.add((Id) String.valueOf(userObj));
                } catch (Exception ex) {
                    // ignore malformed ids
                }
            }
            if (approverRow.get('approverQueueId') != null) {
                try {
                    queueIds.add((Id) String.valueOf(approverRow.get('approverQueueId')));
                } catch (Exception ex) {
                    // ignore malformed ids
                }
            }
        }

        Map<Id, String> userNameById = new Map<Id, String>();
        if (!nextApproverUserIds.isEmpty()) {
            for (celsrm__User_Master__c userRow : [SELECT Id, Name FROM celsrm__User_Master__c WHERE Id IN :nextApproverUserIds]) {
                userNameById.put(userRow.Id, userRow.Name);
            }
        }
        Map<Id, String> queueNameById = new Map<Id, String>();
        if (!queueIds.isEmpty()) {
            for (Group queueRow : [SELECT Id, Name FROM Group WHERE Id IN :queueIds]) {
                queueNameById.put(queueRow.Id, queueRow.Name);
            }
        }

        List<String> nextApproverNames = new List<String>();
        List<String> nextApproverIds = new List<String>();
        for (Id userId : nextApproverUserIds) {
            nextApproverIds.add(String.valueOf(userId));
            if (userNameById.containsKey(userId)) {
                nextApproverNames.add(userNameById.get(userId));
            }
        }
        for (Id queueId : queueIds) {
            nextApproverIds.add(String.valueOf(queueId));
            if (queueNameById.containsKey(queueId)) {
                nextApproverNames.add(queueNameById.get(queueId));
            }
        }

        Boolean approverIsOptional = CreditLimitApprovalProcessController.getBooleanValue(
            nextLevelRows[0].containsKey('IsOptional') ? nextLevelRows[0].get('IsOptional') : nextLevelRows[0].get('isOptional')
        );
        inMap.put('sendToNextApprover', true);
        inMap.put('approverIsOptional', approverIsOptional ? 'true' : 'false');
        inMap.put('nextApproverLevel', nextLevel);
        inMap.put('creditLimitApprovalMatrixId', matrixConfig.Id);
        inMap.put('isLastApprover', 'false');
        inMap.put('nextApprover', new Map<Object, Object>{
            'id' => nextApproverIds.isEmpty() ? null : nextApproverIds[0],
            'name' => String.join(nextApproverNames, ', ')
        });
        inMap.put('nextApproverIds', String.join(nextApproverIds, ','));
        return inMap;
    }

    public static Map<Object, Object> UpdateCreditReview(Map<Object, Object> inMap) {
        String userAction = String.valueOf(inMap.get('userAction'));
        Id actingUserMasterId = getPrimaryUserMasterId(inMap);
        if (inMap.get('doNotSubmit') != null && String.valueOf(inMap.get('doNotSubmit')) != '') {
            inMap.put('ggErrorMessage', String.valueOf(inMap.get('doNotSubmit')));
            return inMap;
        }
        if (actingUserMasterId == null || !isValidUserId(actingUserMasterId)) {
            inMap.put('ggErrorMessage', 'Unable to resolve current user master context for this action.');
            return inMap;
        }

        Savepoint sp = Database.setSavepoint();
        try {
            celsrm__Credit_Configuration__c config = celsrm__Credit_Configuration__c.getOrgDefaults();
            String flowType = config == null ? null : config.celsrm__Credit_Limit_Approval_Matrix_Flow_type__c;
            String parallelMode = config == null ? null : config.celsrm__Parallel_Approval_Mode__c;
            // Core runtime switches used by both review-status transition and detail-row transition.
            Boolean isSequentialFlow = isSequentialFlowType(flowType);
            Boolean isParallelAllMode = isParallelAllMode(parallelMode);

            String creditReviewId = (String) inMap.get('Id');
            celsrm__Credit_Review__c creditReview = [
                SELECT Id, celsrm__Notes__c, celsrm__Requested_Credit_Limit__c, celsrm__Requested_Limit_Valid_To_Date__c,
                    celsrm__Credit_Limit_Approval_Matrix__c
                FROM celsrm__Credit_Review__c
                WHERE Id = :creditReviewId
                LIMIT 1
            ];

            String creditReviewNote = inMap.get('noteBody') != null && inMap.get('noteBody') != ''
                ? String.valueOf(inMap.get('noteBody'))
                : null;
            if (creditReviewNote != null) {
                String userName = UserInfo.getName();
                Boolean isExternalUser = inMap.get('isExternalUser') != null ? Boolean.valueOf(inMap.get('isExternalUser')) : false;
                if (isExternalUser) {
                    userName = String.valueOf(inMap.get('userId'));
                }
                creditReviewNote = 'Note added by ' + userName + ' on ' + Datetime.now().format('dd MMM yyyy HH:mm:ss') + ' : ' + creditReviewNote;
                creditReview.celsrm__Notes__c = creditReviewNote + '\n\n' + (creditReview.celsrm__Notes__c == null ? '' : creditReview.celsrm__Notes__c);
            }

            if (userAction == 'approve') {
                String currentDetailId = inMap.get('creditLimitApprovalDetailId') == null
                    ? null
                    : String.valueOf(inMap.get('creditLimitApprovalDetailId'));
                Boolean parallelPendingApprovers = false;
                if (!isSequentialFlow && isParallelAllMode) {
                    Object parallelPendingValue = inMap.get('parallelPendingApprovers');
                    if (parallelPendingValue != null && String.valueOf(parallelPendingValue) != '') {
                        parallelPendingApprovers = Boolean.valueOf(String.valueOf(parallelPendingValue));
                    } else {
                        // Fallback for stale/direct invoke paths where onload map value is unavailable.
                        parallelPendingApprovers = hasParallelPendingApprovers(creditReview.Id, currentDetailId);
                    }
                }
                approveCreditReview(
                    inMap,
                    creditReview,
                    isSequentialFlow,
                    isParallelAllMode,
                    parallelPendingApprovers,
                    actingUserMasterId
                );
                updateDisputeWorkflowDetails(
                    creditReviewId,
                    String.valueOf(inMap.get('creditLimitApprovalDetailId')),
                    'Credit Review Approved',
                    shouldRevokePeerRowsOnApprove(isSequentialFlow, isParallelAllMode, parallelPendingApprovers),
                    // Sequential: only current active level exists and should be processed.
                    isSequentialFlow,
                    actingUserMasterId
                );
            } else if (userAction == 'reject') {
                rejectCreditReview(inMap, creditReview, isSequentialFlow, isParallelAllMode, actingUserMasterId);
                updateDisputeWorkflowDetails(
                    creditReviewId,
                    String.valueOf(inMap.get('creditLimitApprovalDetailId')),
                    'Credit Review Rejected',
                    // shouldRevokePeerRowsOnReject(isSequentialFlow, isParallelAllMode),
                    true,
                    isSequentialFlow,
                    actingUserMasterId
                );
            }
        } catch (Exception ex) {
            Database.rollback(sp);
            inMap.put('ggErrorMessage', 'There has been some error while resolving the credit review. Error: ' + ex.getMessage());
        }
        return inMap;
    }

    public static void rejectCreditReview(
        Map<Object, Object> inMap,
        celsrm__Credit_Review__c creditReview,
        Boolean isSequentialFlow,
        Boolean isParallelAllMode,
        Id actingUserMasterId
    ) {
        /**
        String currentDetailId = inMap.get('creditLimitApprovalDetailId') == null ? null : String.valueOf(inMap.get('creditLimitApprovalDetailId'));
        Boolean isLastApprover = inMap.get('isLastApprover') != null && Boolean.valueOf(String.valueOf(inMap.get('isLastApprover')));
        Boolean sendToNextApprover = inMap.get('sendToNextApprover') != null && Boolean.valueOf(String.valueOf(inMap.get('sendToNextApprover')));
        Boolean isCurrentDetailOptional = inMap.get('isCurrentDetailOptional') != null && Boolean.valueOf(String.valueOf(inMap.get('isCurrentDetailOptional')));
        if (!isSequentialFlow && (!isParallelAllMode || isCurrentDetailOptional)) {
            // Parallel-One rule:
            // do not finalize the credit review while any other pending approver row still exists.
            Integer pendingOtherApprovers = [
                SELECT COUNT()
                FROM celsrm__Credit_Limit_Approval_Detail__c
                WHERE celsrm__Credit_Review__c = :creditReview.Id
                AND celsrm__Status__c = 'Pending'
                AND Id != :currentDetailId
            ];
            // If there are other pending approvers, do not reject the credit review.
            if (pendingOtherApprovers > 0) {
                creditReview.celsrm__Last_Action_Taken_By__c = actingUserMasterId;
                creditReview.celsrm__Last_Action_Taken_Date__c = Date.valueof(System.now());
                update creditReview;
                return;
            }
        }   
        // If no next approver or current approver is terminal approver, reject the credit review (Parallel Approval Mode: All mode will also fall under this)
        if (!sendToNextApprover || isLastApprover) {
            // Final rejection (no next level or current approver is terminal approver).
            creditReview.celsrm__Status__c = 'Rejected';
            creditReview.celsrm__Last_Action_Taken_By__c = actingUserMasterId;
            creditReview.celsrm__Last_Action_Taken_Date__c = Date.valueof(System.now());
            update creditReview;
            return;
        }
        */
        // Reject credit review immediately upon rejection action regardless of pending approver rows, for both sequential and parallel flows.
        creditReview.celsrm__Status__c = 'Rejected';
        creditReview.celsrm__Last_Action_Taken_By__c = actingUserMasterId;
        creditReview.celsrm__Last_Action_Taken_Date__c = Date.valueof(System.now());
        update creditReview;
        return;
    }

    public static void approveCreditReview(
        Map<Object, Object> inMap,
        celsrm__Credit_Review__c creditReview,
        Boolean isSequentialFlow,
        Boolean isParallelAllMode,
        Boolean parallelPendingApprovers,
        Id actingUserMasterId
    ) {
        Boolean sendToNextApprover = inMap.get('sendToNextApprover') != null && Boolean.valueOf(String.valueOf(inMap.get('sendToNextApprover')));
        Boolean isLastApprover = inMap.get('isLastApprover') != null && Boolean.valueOf(String.valueOf(inMap.get('isLastApprover')));
        String nextApproverIdsCsv = inMap.get('nextApproverIds') == null ? null : String.valueOf(inMap.get('nextApproverIds'));
        String creditLimitApprovalMatrixId = inMap.get('creditLimitApprovalMatrixId') == null ? null : String.valueOf(inMap.get('creditLimitApprovalMatrixId'));
        Integer nextApproverLevel = inMap.get('nextApproverLevel') == null ? null : Integer.valueOf(String.valueOf(inMap.get('nextApproverLevel')));

        if (!isSequentialFlow && isParallelAllMode) {
            // Parallel-All rule:
            // do not finalize the credit review while any other pending approver row still exists.
            // If there are other pending approvers, do not approve the credit review.
            if (parallelPendingApprovers) {
                creditReview.celsrm__Last_Action_Taken_By__c = actingUserMasterId;
                creditReview.celsrm__Last_Action_Taken_Date__c = Date.valueof(System.now());
                update creditReview;
                return;
            }
        }

        // If no next approver or current approver is terminal approver, approve the credit review (Parallel Approval Mode: One case will also fall under this)
        if (!sendToNextApprover || isLastApprover) {
            // Final approval (no next level or current approver is terminal approver).
            creditReview.celsrm__Status__c = 'Approved';
            creditReview.celsrm__Approved_Limit_Valid_To_Date__c = creditReview.celsrm__Requested_Limit_Valid_To_Date__c;
            creditReview.celsrm__Approved_Credit_Limit__c = creditReview.celsrm__Requested_Credit_Limit__c;
            creditReview.Credit_Approved_Date__c = Date.valueof(System.now());
            creditReview.celsrm__Last_Action_Taken_By__c = actingUserMasterId;
            creditReview.celsrm__Last_Action_Taken_Date__c = Date.valueof(System.now());
            update creditReview;
            return;
        }

        // If no next approver ids, approve the credit review (Parallel Approval Mode: All case will also fall under this)
        if (String.isBlank(nextApproverIdsCsv)) {
            // Safety fallback: if next level was expected but no approver ids are derivable,
            // close as final approval instead of leaving review in limbo.
            creditReview.celsrm__Status__c = 'Approved';
            creditReview.celsrm__Approved_Limit_Valid_To_Date__c = creditReview.celsrm__Requested_Limit_Valid_To_Date__c;
            creditReview.celsrm__Approved_Credit_Limit__c = creditReview.celsrm__Requested_Credit_Limit__c;
            creditReview.Credit_Approved_Date__c = Date.valueof(System.now());
            creditReview.celsrm__Last_Action_Taken_By__c = actingUserMasterId;
            creditReview.celsrm__Last_Action_Taken_Date__c = Date.valueof(System.now());
            update creditReview;
            return;
        }

        List<String> nextApproverIds = new List<String>();
        for (String idValue : nextApproverIdsCsv.split(',')) {
            if (String.isBlank(idValue)) {
                continue;
            }
            nextApproverIds.add(idValue.trim());
        }

        List<String> userIds = new List<String>();
        List<String> queueIdCandidates = new List<String>();
        for (String approverId : nextApproverIds) {
            if (isValidUserId(approverId)) {
                userIds.add(approverId);
            } else if (isValidQueueId(approverId)) {
                queueIdCandidates.add(approverId);
            }
        }
        // Sequential path inserts next-level pending rows now.
        // Parallel path usually pre-creates rows at review initiation; this still acts as safe fallback
        // when onload has already determined sendToNextApprover=true.
        insertDisputeWorkflowDetails(creditReview.Id, creditLimitApprovalMatrixId, nextApproverIds, nextApproverLevel);
    }

    private static Boolean isValidUserId(String userId) {
        if (String.isBlank(userId)) {
            return false;
        }
        Id parsedId = tryParseId(userId);
        return parsedId != null && parsedId.getSObjectType() == celsrm__User_Master__c.SObjectType;
    }

    private static Boolean isValidQueueId(String queueId) {
        if (String.isBlank(queueId)) {
            return false;
        }
        Id parsedId = tryParseId(queueId);
        return parsedId != null && parsedId.getSObjectType() == Group.SObjectType;
    }

    private static void insertDisputeWorkflowDetails(
        String creditReviewId,
        String approvalMatrixId,
        List<String> nextApproverIds,
        Integer nextApproverLevel
    ) {
        if (nextApproverIds == null || nextApproverIds.isEmpty()) {
            return;
        }
        List<celsrm__Credit_Limit_Approval_Detail__c> detailsToInsert = new List<celsrm__Credit_Limit_Approval_Detail__c>();
        for (String approverId : nextApproverIds) {
            if (String.isBlank(approverId)) {
                continue;
            }
            celsrm__Credit_Limit_Approval_Detail__c workflowDetail = new celsrm__Credit_Limit_Approval_Detail__c();
            workflowDetail.celsrm__Status__c = 'Pending';
            workflowDetail.celsrm__Level__c = nextApproverLevel;
            if (isValidUserId(approverId)) {
                workflowDetail.celsrm__User_Master__c = approverId;
            } else if (isValidQueueId(approverId)) {
                workflowDetail.celsrm__Queue__c = approverId;
            } else {
                // Fallback: preserve approver id in debug info path via note field if needed later.
                // Keeping row creation so workflow doesn't block unexpectedly.
            }
            workflowDetail.celsrm__Credit_Review__c = creditReviewId;
            workflowDetail.celsrm__Credit_Limit_Approval_Matrix__c = approvalMatrixId;
            detailsToInsert.add(workflowDetail);
        }
        if (!detailsToInsert.isEmpty()) {
            insert detailsToInsert;
        }
    }

    // creditReviewId: parent Credit Review whose pending detail rows are being updated.
    // creditReviewApprovalDetailId: concrete detail row selected as the acting/current row from onload.
    // userAction: action label to stamp on completed actor rows (e.g., Approved/Rejected).
    // revokePeerRows: when true, non-actor pending rows in scope are marked Revoked.
    // restrictToCurrentLevel: when true, updates only pending rows at current acting level (sequential behavior).
    // actingUserMasterId: user master context used for action stamping.
    private static void updateDisputeWorkflowDetails(
        String creditReviewId,
        String creditReviewApprovalDetailId,
        String userAction,
        Boolean revokePeerRows,
        Boolean restrictToCurrentLevel,
        Id actingUserMasterId
    ) {
        if (String.isBlank(creditReviewId) || String.isBlank(creditReviewApprovalDetailId)) {
            return;
        }

        celsrm__Credit_Limit_Approval_Detail__c currentDetail = [
            SELECT Id, celsrm__Level__c
            FROM celsrm__Credit_Limit_Approval_Detail__c
            WHERE Id = :creditReviewApprovalDetailId
            LIMIT 1
        ];

        Decimal currentLevel = currentDetail.celsrm__Level__c;
        String pendingDetailsQuery = 'SELECT Id, celsrm__User_Master__c, celsrm__Status__c FROM celsrm__Credit_Limit_Approval_Detail__c ' +
            'WHERE celsrm__Credit_Review__c = :creditReviewId AND celsrm__Status__c = \'Pending\'';
        if (restrictToCurrentLevel) {
            // Sequential: process only active level rows.
            pendingDetailsQuery += ' AND celsrm__Level__c = :currentLevel';
        }
        List<celsrm__Credit_Limit_Approval_Detail__c> pendingRowsAtLevel = Database.query(pendingDetailsQuery);
        if (pendingRowsAtLevel.isEmpty()) {
            return;
        }

        List<celsrm__Credit_Limit_Approval_Detail__c> detailsToUpdate = new List<celsrm__Credit_Limit_Approval_Detail__c>();
        for (celsrm__Credit_Limit_Approval_Detail__c pendingDetail : pendingRowsAtLevel) {
            // Always complete only the selected acting detail row.
            Boolean isActorRow = pendingDetail.Id == currentDetail.Id;

            celsrm__Credit_Limit_Approval_Detail__c updateRow = new celsrm__Credit_Limit_Approval_Detail__c();
            updateRow.Id = pendingDetail.Id;
            if (isActorRow) {
                updateRow.celsrm__Status__c = 'Completed';
                updateRow.celsrm__User_Action__c = userAction;
                updateRow.celsrm__Action_Date__c = Date.today();
                updateRow.celsrm__Action_Taken_By__c = actingUserMasterId;
                detailsToUpdate.add(updateRow);
            } else if (revokePeerRows) {
                // Sequential and parallel-one: once one actor resolves, peer pending rows are revoked.
                updateRow.celsrm__Status__c = 'Revoked';
                detailsToUpdate.add(updateRow);
            }
        }

        if (!detailsToUpdate.isEmpty()) {
            update detailsToUpdate;
        }
    }

    private static Id tryParseId(String rawId) {
        if (String.isBlank(rawId)) {
            return null;
        }
        try {
            return (Id) rawId.trim();
        } catch (Exception ex) {
            return null;
        }
    }

    private static Set<Id> getCurrentUserMasterIds(Id currentUserId) {
        Set<Id> userMasterIds = new Set<Id>();
        if (currentUserId == null) {
            return userMasterIds;
        }
        for (celsrm__User_Master__c currentUserMaster : [
            SELECT Id
            FROM celsrm__User_Master__c
            WHERE celsrm__User__c = :currentUserId
        ]) {
            userMasterIds.add(currentUserMaster.Id);
        }
        return userMasterIds;
    }

    private static Set<Id> getActionableUserMasterIds(Set<Id> currentUserMasterIds) {
        Set<Id> actionableIds = new Set<Id>();
        if (currentUserMasterIds != null) {
            actionableIds.addAll(currentUserMasterIds);
        }
        if (actionableIds.isEmpty()) {
            return actionableIds;
        }

        // If acting as delegated/manager, include those assigned user masters too.
        String queryString = 'SELECT Id, celsrm__Delegated_User__c';
        if (hasUserMasterField('celsrm__Manager__c')) {
            queryString += ', celsrm__Manager__c';
        }
        queryString += ' FROM celsrm__User_Master__c WHERE celsrm__Delegated_User__c IN :actionableIds';
        if (hasUserMasterField('celsrm__Manager__c')) {
            queryString += ' OR celsrm__Manager__c IN :actionableIds';
        }
        for (SObject row : Database.query(queryString)) {
            Id rowId = (Id) row.get('Id');
            if (rowId != null) {
                actionableIds.add(rowId);
            }
        }
        return actionableIds;
    }

    private static Set<Id> getCurrentUserMasterIdsFromMap(Map<Object, Object> inMap, Id currentUserId) {
        Set<Id> userMasterIds = new Set<Id>();
        if (inMap != null && inMap.containsKey('currentUserMasterIdsCsv') && inMap.get('currentUserMasterIdsCsv') != null) {
            String idsCsv = String.valueOf(inMap.get('currentUserMasterIdsCsv'));
            for (String idValue : idsCsv.split(',')) {
                Id parsedId = tryParseId(idValue);
                if (parsedId != null && parsedId.getSObjectType() == celsrm__User_Master__c.SObjectType) {
                    userMasterIds.add(parsedId);
                }
            }
        }
        if (userMasterIds.isEmpty()) {
            userMasterIds = getCurrentUserMasterIds(currentUserId);
            if (inMap != null) {
                inMap.put('currentUserMasterIdsCsv', serializeIdSet(userMasterIds));
            }
        }
        return userMasterIds;
    }

    private static Set<Id> getQueueIdsForUserMasters(Set<Id> userMasterIds, Id fallbackUserId) {
        Set<Id> queueIds = new Set<Id>();
        Set<Id> userIds = new Set<Id>();
        if (userMasterIds != null && !userMasterIds.isEmpty()) {
            for (celsrm__User_Master__c userMaster : [
                SELECT celsrm__User__c
                FROM celsrm__User_Master__c
                WHERE Id IN :userMasterIds
            ]) {
                if (userMaster.celsrm__User__c != null) {
                    userIds.add(userMaster.celsrm__User__c);
                }
            }
        }
        if (userIds.isEmpty() && fallbackUserId != null) {
            userIds.add(fallbackUserId);
        }
        for (Id userId : userIds) {
            queueIds.addAll(CreditReviewAccessUtil.getQueueIdsForUserWithNestedGroups(userId));
        }
        return queueIds;
    }

    private static Id getPrimaryUserMasterId(Map<Object, Object> inMap) {
        Set<Id> userMasterIds = getCurrentUserMasterIdsFromMap(inMap, null);
        for (Id userMasterId : userMasterIds) {
            return userMasterId;
        }
        return null;
    }

    private static String serializeIdSet(Set<Id> idSet) {
        if (idSet == null || idSet.isEmpty()) {
            return '';
        }
        List<String> ids = new List<String>();
        for (Id idValue : idSet) {
            if (idValue != null) {
                ids.add(String.valueOf(idValue));
            }
        }
        return String.join(ids, ',');
    }

    private static Boolean hasUserMasterField(String fieldName) {
        return !String.isBlank(fieldName) && celsrm__User_Master__c.SObjectType.getDescribe().fields.getMap().containsKey(fieldName);
    }

    // Find the current pending detail for the current user
    private static celsrm__Credit_Limit_Approval_Detail__c findCurrentPendingDetailForUser(
        List<celsrm__Credit_Limit_Approval_Detail__c> pendingDetails,
        Boolean isSequentialFlow,
        Set<Id> currentUserMasterIds,
        Set<Id> actionableUserMasterIds,
        Set<Id> currentUserQueueIds
    ) {
        if (pendingDetails == null || pendingDetails.isEmpty()) {
            return null;
        }

        List<celsrm__Credit_Limit_Approval_Detail__c> candidateRows = new List<celsrm__Credit_Limit_Approval_Detail__c>();
        if (isSequentialFlow) {
            // Sequential: action must happen only on the current active level.
            Decimal activeLevel = pendingDetails[0].celsrm__Level__c;
            for (celsrm__Credit_Limit_Approval_Detail__c row : pendingDetails) {
                if (row.celsrm__Level__c == activeLevel) {
                    candidateRows.add(row);
                }
            }
        } else {
            // Parallel: rows can exist across levels, so consider all pending rows.
            candidateRows.addAll(pendingDetails);
        }

        // 1) Direct user-master assignment always has first priority.
        for (celsrm__Credit_Limit_Approval_Detail__c row : candidateRows) {
            if (row.celsrm__User_Master__c != null && currentUserMasterIds.contains(row.celsrm__User_Master__c)) {
                return row;
            }
        }
        // 2) Queue assignment for queues where current user is a member (nested groups included).
        for (celsrm__Credit_Limit_Approval_Detail__c row : candidateRows) {
            if (row.celsrm__Queue__c != null && currentUserQueueIds.contains(row.celsrm__Queue__c)) {
                return row;
            }
        }
        // 3) Delegated/manager acting on behalf of assigned user-master.
        for (celsrm__Credit_Limit_Approval_Detail__c row : candidateRows) {
            if (row.celsrm__User_Master__c != null && actionableUserMasterIds.contains(row.celsrm__User_Master__c)) {
                return row;
            }
        }
        // 4) Queue assignment where current user is delegated/manager of any queue member.
        Set<Id> candidateQueueIds = new Set<Id>();
        for (celsrm__Credit_Limit_Approval_Detail__c row : candidateRows) {
            if (row.celsrm__Queue__c != null) {
                candidateQueueIds.add(row.celsrm__Queue__c);
            }
        }
        Set<Id> delegatedManagerAccessibleQueueIds = CreditReviewAccessUtil.getDelegatedManagerAccessibleQueueIds(
            candidateQueueIds,
            currentUserMasterIds
        );
        for (celsrm__Credit_Limit_Approval_Detail__c row : candidateRows) {
            if (row.celsrm__Queue__c != null && delegatedManagerAccessibleQueueIds.contains(row.celsrm__Queue__c)) {
                return row;
            }
        }
        return null;
    }

    private static Boolean isSequentialFlowType(String flowType) {
        // Keep support for historical misspelling "Sequencial".
        return String.isBlank(flowType) || flowType.equalsIgnoreCase('Sequential') || flowType.equalsIgnoreCase('Sequencial');
    }

    private static Boolean isParallelAllMode(String parallelMode) {
        return !String.isBlank(parallelMode) && parallelMode.equalsIgnoreCase('All');
    }

    // Approve revoke policy:
    // - Sequential: revoke other pending rows at current level.
    // - Parallel-One: revoke peer pending rows.
    // - Parallel-All: revoke peers only after no required pending approvers remain.
    private static Boolean shouldRevokePeerRowsOnApprove(
        Boolean isSequentialFlow,
        Boolean isParallelAllMode,
        Boolean parallelPendingApprovers
    ) {
        if (isSequentialFlow) {
            return true;
        }
        if (!isParallelAllMode) {
            return true;
        }
        return !parallelPendingApprovers;
    }

    // Reject revoke policy:
    // - Sequential: revoke peer rows at current level.
    // - Parallel-One: do not revoke peers while waiting for other approvers.
    // - Parallel-All: revoke peers for the acted scope.
    private static Boolean shouldRevokePeerRowsOnReject(Boolean isSequentialFlow, Boolean isParallelAllMode) {
        if (isSequentialFlow) {
            return true;
        }
        return isParallelAllMode;
    }

    // true means there are still required (non-optional) pending approvers
    // besides the currently acted detail row.
    private static Boolean hasParallelPendingApprovers(Id creditReviewId, String currentDetailId) {
        if (creditReviewId == null || String.isBlank(currentDetailId)) {
            return false;
        }
        Integer pendingOtherApprovers = [
            SELECT COUNT()
            FROM celsrm__Credit_Limit_Approval_Detail__c
            WHERE celsrm__Credit_Review__c = :creditReviewId
            AND celsrm__Status__c = 'Pending'
            AND Id != :currentDetailId
            AND celsrm__Is_Optional__c = false
        ];
        return pendingOtherApprovers > 0;
    }

}