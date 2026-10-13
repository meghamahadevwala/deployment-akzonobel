global with sharing class CreditReviewDetailController implements celsrm.GOGIScreenCustomLogic {
    global Map<Object, Object> invoke(String functionName, Map<Object, Object> inMap) {
        try {
            if (functionName == 'onPageLoadFunction') {
                inMap = onPageLoadFunction(inMap);
            } else if(functionName == 'onLoadCreditReviewWorkflowMatrix'){
                inMap = onLoadCreditReviewWorkflowMatrix(inMap);
            } else if(functionName == 'fetchCreditReviewWorkflowHistory'){
                inMap = fetchCreditReviewWorkflowHistory(inMap);
            }
        } catch (Exception ex) {
            String errorMessage =
                'ClassName: CreditReviewDetailController | Method: invoke() | Linenumber: ' +
                ex.getLineNumber() + ' | Message: ' + ex.getMessage();
            System.debug('errorMessage: ' + errorMessage);
        }
        return inMap;
    }

    public static Map<Object, Object> onPageLoadFunction(Map<Object, Object> inMap) {
        String creditReviewId = (String) inMap.get('Id');
        Map<Object, Object> returnMap = new Map<Object, Object>();
        celsrm__Credit_Review__c creditReview = [
            SELECT Id, Name, celsrm__Status__c, OwnerId
            FROM celsrm__Credit_Review__c
            WHERE Id = :creditReviewId
            LIMIT 1
        ];

        Id currentUserId = UserInfo.getUserId();
        celsrm__Credit_Configuration__c config = celsrm__Credit_Configuration__c.getOrgDefaults();
        Boolean allowDelegatedUserOrManagerToAct = config != null && config.celsrm__Allow_Delegated_User_Manger_to_act__c;
        Boolean allowOwnerToActOnInternalTeamReview = config != null && config.celsrm__Owner_Can_Act_on_Queue_Reviews__c;

        returnMap.put('creditReviewNumber', creditReview.Name);
        returnMap.put('CreditReviewStatus', creditReview.celsrm__Status__c);
        returnMap.put(
            'UseCustomApprovalProcess',
            (config != null && config.celsrm__Use_Credit_Limit_Approval_Matrix__c) ? 'true' : 'false'
        );

        Boolean hasAccess = validateUserAccess(
            creditReview,
            currentUserId,
            allowDelegatedUserOrManagerToAct,
            allowOwnerToActOnInternalTeamReview,
            returnMap
        );
        returnMap.put('CurrentUserIsApprover', String.valueOf(hasAccess));
        return returnMap;
    }

    public static Map<Object, Object> onLoadCreditReviewWorkflowMatrix(Map<Object, Object> inMap) {
        String creditReviewId = (String) inMap.get('Id');
        List<Map<Object, Object>> responseRows = new List<Map<Object, Object>>();
        if (String.isBlank(creditReviewId)) {
            inMap.put('dataServiceResponse', responseRows);
            return inMap;
        }

        celsrm__Credit_Review__c creditReview = [
            SELECT Id, celsrm__Credit_Limit_Approval_Matrix__c
            FROM celsrm__Credit_Review__c
            WHERE Id = :creditReviewId
            LIMIT 1
        ];
        if (creditReview.celsrm__Credit_Limit_Approval_Matrix__c == null) {
            inMap.put('dataServiceResponse', responseRows);
            return inMap;
        }

        celsrm__Credit_Limit_Approval_Matrix__c matrix = [
            SELECT Id, Name, celsrm__Approval_Matrices__c
            FROM celsrm__Credit_Limit_Approval_Matrix__c
            WHERE Id = :creditReview.celsrm__Credit_Limit_Approval_Matrix__c
            LIMIT 1
        ];
        if (String.isBlank(matrix.celsrm__Approval_Matrices__c)) {
            inMap.put('dataServiceResponse', responseRows);
            return inMap;
        }

        Object rawPayload = JSON.deserializeUntyped(matrix.celsrm__Approval_Matrices__c);
        if (!(rawPayload instanceof List<Object>)) {
            inMap.put('dataServiceResponse', responseRows);
            return inMap;
        }

        Set<Id> userIds = new Set<Id>();
        Set<Id> queueIds = new Set<Id>();
        for (Object rowObj : (List<Object>) rawPayload) {
            if (!(rowObj instanceof Map<String, Object>)) {
                continue;
            }
            Map<String, Object> row = (Map<String, Object>) rowObj;
            List<Object> approverUserIds = row.get('approverUserIds') instanceof List<Object>
                ? (List<Object>) row.get('approverUserIds')
                : new List<Object>();
            for (Object userObj : approverUserIds) {
                Id userId = tryParseId(userObj);
                if (userId != null) {
                    userIds.add(userId);
                }
            }
            Id queueId = tryParseId(row.get('approverQueueId'));
            if (queueId != null) {
                queueIds.add(queueId);
            }
        }

        Map<Id, String> userNameById = new Map<Id, String>();
        if (!userIds.isEmpty()) {
            for (celsrm__User_Master__c userRow : [
                SELECT Id, Name
                FROM celsrm__User_Master__c
                WHERE Id IN :userIds
            ]) {
                userNameById.put(userRow.Id, userRow.Name);
            }
        }
        Map<Id, String> queueNameById = new Map<Id, String>();
        if (!queueIds.isEmpty()) {
            for (Group queueRow : [
                SELECT Id, Name
                FROM Group
                WHERE Id IN :queueIds
            ]) {
                queueNameById.put(queueRow.Id, queueRow.Name);
            }
        }

        Set<String> pendingApproverKeys = new Set<String>();
        for (celsrm__Credit_Limit_Approval_Detail__c pendingRow : [
            SELECT celsrm__User_Master__c, celsrm__Queue__c, celsrm__Level__c
            FROM celsrm__Credit_Limit_Approval_Detail__c
            WHERE celsrm__Credit_Review__c = :creditReview.Id
            AND celsrm__Status__c = 'Pending'
        ]) {
            Integer pendingLevel = pendingRow.celsrm__Level__c == null ? null : pendingRow.celsrm__Level__c.intValue();
            if (pendingRow.celsrm__User_Master__c != null) {
                pendingApproverKeys.add(buildApproverKey('USER', pendingRow.celsrm__User_Master__c, pendingLevel));
            }
            if (pendingRow.celsrm__Queue__c != null) {
                pendingApproverKeys.add(buildApproverKey('QUEUE', pendingRow.celsrm__Queue__c, pendingLevel));
            }
        }

        for (Object rowObj : (List<Object>) rawPayload) {
            if (!(rowObj instanceof Map<String, Object>)) {
                continue;
            }
            Map<String, Object> row = (Map<String, Object>) rowObj;
            Integer level = CreditLimitApprovalProcessController.toDecimal(row.get('level')) == null
                ? null
                : CreditLimitApprovalProcessController.toDecimal(row.get('level')).intValue();

            Boolean isOptional = CreditLimitApprovalProcessController.getBooleanValue(row.get('IsOptional'));
            Boolean isActive = CreditLimitApprovalProcessController.getBooleanValue(row.get('isActive'));
            List<Object> approverUserIds = row.get('approverUserIds') instanceof List<Object>
                ? (List<Object>) row.get('approverUserIds')
                : new List<Object>();
            if (approverUserIds.isEmpty() && row.get('approverUserId') != null) {
                approverUserIds.add(row.get('approverUserId'));
            }
            for (Object userObj : approverUserIds) {
                Id userId = tryParseId(userObj);
                if (userId == null) {
                    continue;
                }
                Map<Object, Object> recordObject = new Map<Object, Object>();
                recordObject.put('Id', String.valueOf(level) + '_' + String.valueOf(userId));
                recordObject.put('name', matrix.Name);
                recordObject.put('level', level);
                Map<String, Object> userLink = new Map<String, Object>();
                userLink.put('id', userId);
                userLink.put('name', userNameById.get(userId));
                recordObject.put('assignee', userLink);
                recordObject.put('isOptional', isOptional);
                recordObject.put('isActive', isActive);
                recordObject.put('isCurrentApprover', pendingApproverKeys.contains(buildApproverKey('USER', userId, level)));
                responseRows.add(recordObject);
            }

            Id queueId = tryParseId(row.get('approverQueueId'));
            if (queueId != null) {
                Map<Object, Object> recordObject = new Map<Object, Object>();
                recordObject.put('Id', String.valueOf(level) + '_' + String.valueOf(queueId));
                recordObject.put('name', matrix.Name);
                recordObject.put('level', level);
                Map<String, Object> queueLink = new Map<String, Object>();
                queueLink.put('id', queueId);
                queueLink.put('name', queueNameById.get(queueId));
                recordObject.put('assignee', queueLink);
                recordObject.put('isOptional', isOptional);
                recordObject.put('isActive', isActive);
                recordObject.put('isCurrentApprover', pendingApproverKeys.contains(buildApproverKey('QUEUE', queueId, level)));
                responseRows.add(recordObject);
            }
        }

        inMap.put('dataServiceResponse', responseRows);
        return inMap;
    }

    public static Map<Object, Object> fetchCreditReviewWorkflowHistory(Map<Object, Object> inMap) {
        String creditReviewId = (String) inMap.get('Id');
        List<Map<Object, Object>> responseRows = new List<Map<Object, Object>>();
        if (String.isBlank(creditReviewId)) {
            inMap.put('dataServiceResponse', responseRows);
            return inMap;
        }

        List<celsrm__Credit_Limit_Approval_Detail__c> detailRows = [
            SELECT Id, celsrm__Status__c, celsrm__Level__c, CreatedDate,
                celsrm__Action_Date__c, celsrm__User_Action__c, celsrm__Action_Taken_By__c, celsrm__Action_Taken_By__r.Name,
                celsrm__User_Master__c, celsrm__User_Master__r.Name,
                celsrm__Queue__c, celsrm__Is_Optional__c
            FROM celsrm__Credit_Limit_Approval_Detail__c
            WHERE celsrm__Credit_Review__c = :creditReviewId
            ORDER BY celsrm__Level__c ASC, CreatedDate ASC
        ];

        // get queue name for the queue id
        Set<Id> queueIds = new Set<Id>();
        for (celsrm__Credit_Limit_Approval_Detail__c detailRow : detailRows) {
            if (detailRow.celsrm__Queue__c != null) {
                queueIds.add(detailRow.celsrm__Queue__c);
            }
        }
        Map<Id, String> queueNameById = new Map<Id, String>();
        if (!queueIds.isEmpty()) {
            for (Group queueRow : [
                SELECT Id, Name
                FROM Group
                WHERE Id IN :queueIds
            ]) {
                queueNameById.put(queueRow.Id, queueRow.Name);
            }
        }
        for (celsrm__Credit_Limit_Approval_Detail__c detailRow : detailRows) {
            Map<Object, Object> row = new Map<Object, Object>();
            row.put('Id', detailRow.Id);
            row.put('status', detailRow.celsrm__Status__c);
            row.put('level', detailRow.celsrm__Level__c);
            row.put('createdDate', detailRow.CreatedDate);
            row.put('actionDate', detailRow.celsrm__Action_Date__c);
            row.put('actionName', detailRow.celsrm__User_Action__c);
            if (detailRow.celsrm__Action_Taken_By__c != null) {
                row.put('actionTakenBy', new Map<String, Object>{
                    'id' => detailRow.celsrm__Action_Taken_By__c,
                    'name' => detailRow.celsrm__Action_Taken_By__r == null ? null : detailRow.celsrm__Action_Taken_By__r.Name
                });
            }
            if (detailRow.celsrm__User_Master__c != null) {
                row.put('assignee', new Map<String, Object>{
                    'id' => detailRow.celsrm__User_Master__c,
                    'name' => detailRow.celsrm__User_Master__r == null ? null : detailRow.celsrm__User_Master__r.Name
                });
            } else if (detailRow.celsrm__Queue__c != null) {
                row.put('assignee', new Map<String, Object>{
                    'id' => detailRow.celsrm__Queue__c,
                    'name' => queueNameById.get(detailRow.celsrm__Queue__c)
                });
            }
            row.put('isOptional', detailRow.celsrm__Is_Optional__c);
            responseRows.add(row);
        }

        inMap.put('dataServiceResponse', responseRows);
        return inMap;
    }

    private static Boolean validateUserAccess(
        celsrm__Credit_Review__c creditReview,
        Id currentUserId,
        Boolean allowDelegatedUserOrManagerToAct,
        Boolean allowOwnerToActOnInternalTeamReview,
        Map<Object, Object> returnMap
    ) {
        Set<Id> currentUserMasterIds = CreditReviewAccessUtil.getCurrentUserMasterIds(currentUserId);
        Set<Id> currentUserQueueIds = CreditReviewAccessUtil.getQueueIdsForUserWithNestedGroups(currentUserId);

        List<celsrm__Credit_Limit_Approval_Detail__c> pendingDetailRows = [
            SELECT Id, celsrm__User_Master__c, celsrm__Queue__c
            FROM celsrm__Credit_Limit_Approval_Detail__c
            WHERE celsrm__Credit_Review__c = :creditReview.Id
            AND celsrm__Status__c = 'Pending'
        ];

        Set<Id> pendingUserMasterIds = new Set<Id>();
        Set<Id> pendingQueueIds = new Set<Id>();
        for (celsrm__Credit_Limit_Approval_Detail__c detailRow : pendingDetailRows) {
            if (detailRow.celsrm__User_Master__c != null) {
                pendingUserMasterIds.add(detailRow.celsrm__User_Master__c);
            }
            if (detailRow.celsrm__Queue__c != null) {
                pendingQueueIds.add(detailRow.celsrm__Queue__c);
            }
        }

        if (CreditReviewAccessUtil.hasIntersection(currentUserMasterIds, pendingUserMasterIds)) {
            returnMap.put('accessReason', 'Direct user assignment.');
            return true;
        }
        if (CreditReviewAccessUtil.hasIntersection(currentUserQueueIds, pendingQueueIds)) {
            // Owner can act on queue-assigned review only when config allows it.
            if (creditReview.OwnerId == currentUserId && allowOwnerToActOnInternalTeamReview != true) {
                returnMap.put('accessReason', 'Owner is restricted on queue-assigned review by configuration.');
                return false;
            }
            returnMap.put('accessReason', 'Direct queue assignment.');
            return true;
        }

        if (allowDelegatedUserOrManagerToAct == true && !currentUserMasterIds.isEmpty()) {
            if (!pendingUserMasterIds.isEmpty() &&
                CreditReviewAccessUtil.isDelegatedOrManagerForAnyMaster(pendingUserMasterIds, currentUserMasterIds)
            ) {
                returnMap.put('accessReason', 'Delegated/manager access for assigned user.');
                return true;
            }

            if (!pendingQueueIds.isEmpty()) {
                Set<Id> queueMemberUserIds = CreditReviewAccessUtil.getUserIdsForQueuesWithNestedGroups(pendingQueueIds);
                if (!queueMemberUserIds.isEmpty() &&
                    CreditReviewAccessUtil.isDelegatedOrManagerForAnySalesforceUser(queueMemberUserIds, currentUserMasterIds)
                ) {
                    returnMap.put('accessReason', 'Delegated/manager access via queue member.');
                    return true;
                }
            }
        }

        returnMap.put('accessReason', 'Current user is not eligible to act on pending entries.');
        return false;
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

    private static String buildApproverKey(String assigneeType, Id assigneeId, Integer level) {
        String levelToken = level == null ? 'NA' : String.valueOf(level);
        return assigneeType + ':' + String.valueOf(assigneeId) + ':' + levelToken;
    }

}