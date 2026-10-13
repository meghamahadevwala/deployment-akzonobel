global with sharing class DisputeDetailController implements celsrm.GOGIScreenCustomLogic {
    global Map<Object, Object> invoke(String functionName, Map<Object, Object> inMap){
        try {
            system.debug('FunctionName>>>>>'+functionName);
            //inMap.put('functionName', functionName);
            if(functionName == 'onPageLoadFunction'){
                inMap = onPageLoadFunction(inMap);
            } else if(functionName == 'onLoadWorkflowHistory'){
                inMap = fetchDisputeWorkflowHistory(inMap);
            } else if(functionName == 'fetchRelatedActivities'){
                inMap = fetchRelatedActivities(inMap);
            } else if(functionName == 'OnLoadDisputeWorkflowMatrix'){
                inMap = OnLoadDisputeWorkflowMatrix(inMap);
            }
            // else if(functionName == 'onHoldDispute'){
            //     inMap = onHoldDispute(inMap);
            // }
        } catch(exception ex){
            String errorMessage = 'ClassName: CA_ApplyCashController | Method: invoke() | Linenumber: ' + ex.getLineNumber() + ' | Message: ' + ex.getMessage();
            System.debug('errorMessage: ' + errorMessage);
        }
        return inMap;
    }
    //-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
    public static Map<Object, Object> OnLoadDisputeWorkflowMatrix(Map<Object, Object> inMap){
        List<Map<Object, Object>> recordObjectList = new List<Map<Object, Object>>();
        try {
            Id matrixId = resolveMatrixIdForDefinedWorkflow(inMap);
            if (matrixId == null) {
                inMap.put('dataServiceResponse', recordObjectList);
                return inMap;
            }

            celsrm__Dispute_Workflow_Matrix__c matrix = [
                SELECT Id, Name, celsrm__Approval_Matrices__c, celsrm__Escalation_Email__c
                FROM celsrm__Dispute_Workflow_Matrix__c
                WHERE Id = :matrixId
                LIMIT 1
            ];
            if (String.isBlank(matrix.celsrm__Approval_Matrices__c)) {
                inMap.put('dataServiceResponse', recordObjectList);
                return inMap;
            }

            List<DisputeApprovalProcessController.LevelAssignment> assignments =
                DisputeApprovalProcessController.extractAllLevelAssignments(matrix.celsrm__Approval_Matrices__c);
            if (assignments.isEmpty()) {
                inMap.put('dataServiceResponse', recordObjectList);
                return inMap;
            }

            Set<Id> userMasterIds = new Set<Id>();
            Set<Id> queueIds = new Set<Id>();
            for (DisputeApprovalProcessController.LevelAssignment assignment : assignments) {
                if (assignment.userMasterId != null) {
                    userMasterIds.add(assignment.userMasterId);
                }
                if (assignment.queueId != null) {
                    queueIds.add(assignment.queueId);
                }
            }

            Map<Id, celsrm__User_Master__c> userMastersById = new Map<Id, celsrm__User_Master__c>();
            if (!userMasterIds.isEmpty()) {
                for (celsrm__User_Master__c userMaster : [
                    SELECT Id, Name, celsrm__Email__c, celsrm__User__c, celsrm__Is_External_User__c
                    FROM celsrm__User_Master__c
                    WHERE Id IN :userMasterIds
                ]) {
                    userMastersById.put(userMaster.Id, userMaster);
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

            assignments.sort(new DefinedWorkflowAssignmentComparator());
            String escalationEmailValue = matrix.celsrm__Escalation_Email__c == null ? '' : String.valueOf(matrix.celsrm__Escalation_Email__c);

            for (DisputeApprovalProcessController.LevelAssignment assignment : assignments) {
                if (assignment.userMasterId != null) {
                    celsrm__User_Master__c userMaster = userMastersById.get(assignment.userMasterId);
                    if (userMaster == null) {
                        continue;
                    }
                    recordObjectList.add(
                        buildDefinedWorkflowRowFromUserMaster(
                            matrix,
                            assignment,
                            userMaster,
                            escalationEmailValue
                        )
                    );
                    continue;
                }

                if (assignment.queueId != null) {
                    recordObjectList.add(
                        buildDefinedWorkflowRowFromQueue(
                            matrix,
                            assignment,
                            queueNameById.get(assignment.queueId),
                            escalationEmailValue
                        )
                    );
                }
            }


            inMap.put('dataServiceResponse', recordObjectList);

        } catch (Exception ex) {
            String errorMessage = 'ClassName: DisputeDetailController | Method: OnLoadDisputeWorkflowMatrix() | Linenumber: ' + ex.getLineNumber() + ' | Message: ' + ex.getMessage();
            System.debug('errorMessage: ' + errorMessage);
        }
        return inMap;
    }

    private static Id resolveMatrixIdForDefinedWorkflow(Map<Object, Object> inMap) {
        String disputeId = inMap == null ? null : (String) inMap.get('Id');
        if (String.isBlank(disputeId)) {
            return null;
        }

        String matrixFieldApi = getDisputeMatrixLookupFieldApi();
        if (String.isBlank(matrixFieldApi)) {
            return null;
        }

        String queryString =
            'SELECT Id, ' + matrixFieldApi +
            ' FROM celsrm__Dispute__c WHERE Id = :disputeId LIMIT 1';
        List<celsrm__Dispute__c> disputes = Database.query(queryString);
        if (disputes.isEmpty()) {
            return null;
        }

        //-- Starts | FIN-9786 | Changed by Asera | 24-Jun-2026 --//
        return readDisputeMatrixId(disputes[0], matrixFieldApi);
        //-- Ends | FIN-9786 | Changed by Asera | 24-Jun-2026 --//
    }

    private static String getDisputeMatrixLookupFieldApi() {
        Map<String, Schema.SObjectField> disputeFieldMap = celsrm__Dispute__c.SObjectType.getDescribe().fields.getMap();
        if (disputeFieldMap.containsKey('celsrm__Workflow_Matrix_Id__c')) {
            return 'celsrm__Workflow_Matrix_Id__c';
        }
        if (disputeFieldMap.containsKey('celsrm__Dispute_Workflow_Matrix__c')) {
            return 'celsrm__Dispute_Workflow_Matrix__c';
        }
        return null;
    }

    private static Id readDisputeMatrixId(celsrm__Dispute__c disputeRecord, String matrixFieldApi) {
        if (disputeRecord == null || String.isBlank(matrixFieldApi)) {
            return null;
        }
        //-- Starts | FIN-9786 | Changed by Asera | 24-Jun-2026 --//
        Object matrixValue = disputeRecord.get(matrixFieldApi);
        if (matrixValue == null) {
            return null;
        }

        String matrixIdValue = String.valueOf(matrixValue);
        try {
            return String.isBlank(matrixIdValue) ? null : Id.valueOf(matrixIdValue);
        } catch (Exception ex) {
            return null;
        }
        //-- Ends | FIN-9786 | Changed by Asera | 24-Jun-2026 --//
    }

    private static Map<Object, Object> buildDefinedWorkflowRowFromUserMaster(
        celsrm__Dispute_Workflow_Matrix__c matrix,
        DisputeApprovalProcessController.LevelAssignment assignment,
        celsrm__User_Master__c userMaster,
        String escalationEmailValue
    ) {
        Map<Object, Object> recordObject = new Map<Object, Object>();
        recordObject.put('Id', String.valueOf(assignment.level) + '_' + String.valueOf(userMaster.Id));
        recordObject.put('name', matrix.Name);
        recordObject.put('ruleName', matrix.Name);
        recordObject.put('userType', assignment.userType);
        recordObject.put('SLADays', assignment.slDays == null ? '' : String.valueOf(assignment.slDays));
        recordObject.put('escalationEmail', escalationEmailValue);
        recordObject.put('level', assignment.level == null ? '' : String.valueOf(assignment.level));

        String emailValue = userMaster.celsrm__Email__c;
        if (userMaster.celsrm__Is_External_User__c == true || userMaster.celsrm__User__c == null) {
            recordObject.put('isExternalUser', userMaster.celsrm__Is_External_User__c );

            recordObject.put('userEmail', emailValue);
            recordObject.put('userName', userMaster.Name);
            if (String.isNotBlank(emailValue)) {
                Map<String, Object> userLink = new Map<String, Object>();
                userLink.put('id', emailValue);
                userLink.put('name', String.isBlank(userMaster.Name) ? emailValue : userMaster.Name);
                recordObject.put('userLink', userLink);
            }
            return recordObject;
        }

        recordObject.put('userEmail', emailValue);
        recordObject.put('userId', userMaster.celsrm__User__c);
        recordObject.put('userName', userMaster.Name);
        Map<String, Object> userLink = new Map<String, Object>();
        userLink.put('id', userMaster.celsrm__User__c);
        userLink.put('name', userMaster.Name);
        recordObject.put('userLink', userLink);
        return recordObject;
    }

    private static Map<Object, Object> buildDefinedWorkflowRowFromQueue(
        celsrm__Dispute_Workflow_Matrix__c matrix,
        DisputeApprovalProcessController.LevelAssignment assignment,
        String queueName,
        String escalationEmailValue
    ) {
        Map<Object, Object> recordObject = new Map<Object, Object>();
        recordObject.put('Id', String.valueOf(assignment.level) + '_' + String.valueOf(assignment.queueId));
        recordObject.put('name', matrix.Name);
        recordObject.put('ruleName', matrix.Name);
        recordObject.put('userType', assignment.userType);
        recordObject.put('SLADays', assignment.slDays == null ? '' : String.valueOf(assignment.slDays));
        recordObject.put('escalationEmail', escalationEmailValue);
        recordObject.put('level', assignment.level == null ? '' : String.valueOf(assignment.level));
        recordObject.put('userEmail', '');
        recordObject.put('userName', queueName);
        Map<String, Object> userLink = new Map<String, Object>();
        userLink.put('id', assignment.queueId);
        userLink.put('name', queueName);
        recordObject.put('userLink', userLink);
        return recordObject;
    }

    private class DefinedWorkflowAssignmentComparator implements System.Comparator<DisputeApprovalProcessController.LevelAssignment> {
        public Integer compare(
            DisputeApprovalProcessController.LevelAssignment first,
            DisputeApprovalProcessController.LevelAssignment second
        ) {
            Integer firstLevel = first == null || first.level == null ? 999999 : first.level;
            Integer secondLevel = second == null || second.level == null ? 999999 : second.level;
            if (firstLevel == secondLevel) {
                return 0;
            }
            return firstLevel < secondLevel ? -1 : 1;
        }
    }

//-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
    public static Map<Object, Object> onPageLoadFunction(Map<Object, Object> inMap){
        String disputeId = (String)inMap.get('Id');
        //-- Start | FIN-9672 | Changed by Ravi | 05 May 2026 --//
        //-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
        celsrm__Dispute__c dispute = [SELECT Name, celsrm__Account__r.Id, celsrm__Account__r.Name,celsrm__Account__r.AccountNumber, celsrm__Transaction__r.Name, 
            celsrm__Transaction__c, celsrm__Dispute_Type__c, celsrm__Reason_Code__c, celsrm__Status__c, celsrm__Amount__c, celsrm__Resolution_Code__c, 
            Root_Cause__c, Expected_Closure_Date__c, Previous_Status__c, celsrm__Transaction__r.celsrm__Amount__c, celsrm__Days_To_Identify__c,
            celsrm__Days_To_Resolve__c, celsrm__Transaction__r.celsrm__DPD__c, Days_Dispute_Outstanding__c, Dispute_SLA_Days__c, SLA_Breached__c, 
            celsrm__Owner__c, celsrm__Owner__r.Name, celsrm__Created_Date__c, Rejection_Code__c, celsrm__Latest_Note__c, CreatedById, CreatedBy.Name,
            LastModifiedById, LastModifiedBy.Name, celsrm__Dispute_Resolver__c, celsrm__Dispute_Resolver__r.Name,
            celsrm__Resolver_User_Master__c, celsrm__Resolver_User_Master__r.Name, celsrm__Resolver_User_Master__r.celsrm__Email__c,
            celsrm__Resolver_User_Master__r.celsrm__User__c, celsrm__Resolver_User_Master__r.celsrm__Is_External_User__c, External_Resolver_Email__c
            FROM celsrm__Dispute__c WHERE Id = :disputeId];
        //-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
        //-- End | FIN-9672 | Changed by Ravi | 05 May 2026 --//
        inMap.put('disputeInformation', '<span style="font-size: 14px;font-weight: 600;padding: 0.25rem 0.5rem;background: #eee;border-radius: 0.25rem;width: 100%;float: left;">Dispute Information</span>');
        inMap.put('disputeNumber', dispute.Name);
        inMap.put('disputeResolverId', dispute.celsrm__Dispute_Resolver__c);
        inMap.put('disputeType', dispute.celsrm__Dispute_Type__c);
        inMap.put('reasonCode', dispute.celsrm__Reason_Code__c);
        inMap.put('disputeStatus', dispute.celsrm__Status__c);
        inMap.put('disputePreviousStatus', dispute.Previous_Status__c);
        inMap.put('disputeAmount', dispute.celsrm__Amount__c);
        inMap.put('expectedClosureDate', dispute.Expected_Closure_Date__c);
        inMap.put('invoiceAmount', dispute.celsrm__Transaction__r.celsrm__Amount__c);
        inMap.put('daysToIdentify', dispute.celsrm__Days_To_Identify__c);
        inMap.put('daysToResolve', dispute.celsrm__Days_To_Resolve__c);
        inMap.put('invoiceDPD', dispute.celsrm__Transaction__r.celsrm__DPD__c);
        inMap.put('daysDisputeOutstanding', dispute.Days_Dispute_Outstanding__c);
        inMap.put('disputeSLADays', dispute.Dispute_SLA_Days__c);
        inMap.put('slaBreached', dispute.SLA_Breached__c);
        inMap.put('createdDate', dispute.celsrm__Created_Date__c);
        inMap.put('customerNumber', dispute.celsrm__Account__r.AccountNumber);
        //--- Add Customer Number Field in Dispute Detail Screen --//
        Map<String, String> custObj = new Map<String, String>();
        custObj.put('id', dispute.celsrm__Account__r.Id);
        custObj.put('name', dispute.celsrm__Account__r.Name);
        inMap.put('customerName', custObj);
        //-- adding owner in dispute detail screen --//
        Map<String, String> ownerObj = new Map<String, String>();
        ownerObj.put('id', dispute.celsrm__Owner__c);
        ownerObj.put('name', dispute.celsrm__Owner__r.Name);
        inMap.put('disputeOwner', ownerObj);
        //--- Add Invoice No field in Dispute Detail screen ---//
        Map<String, String> invObj = new Map<String, String>();
        invObj.put('id', dispute.celsrm__Transaction__c);
        invObj.put('name', dispute.celsrm__Transaction__r.Name);
        inMap.put('invoiceNumber', invObj);
        //-- add dispute resolver --//
        Map<String, String> resObj = new Map<String, String>();
        //-- Start | FIN-9672 | Changed by Ravi | 05 May 2026 --//
        DisputeUserMasterService.ResolvedUserInfo resolvedUser = DisputeUserMasterService.resolveFromDisputeRecord(dispute);
        if(resolvedUser != null){
            resObj.put('id', resolvedUser.isExternal() ? resolvedUser.email : String.valueOf(resolvedUser.userId));
            if (resolvedUser.userMasterId != null) {
                resObj.put('userMasterId', String.valueOf(resolvedUser.userMasterId));
            }
            resObj.put('name', resolvedUser.name);
        }
        inMap.put('disputeResolver', resObj);
        
        inMap.put('resolutionInformation', '<span style="font-size: 14px;font-weight: 600;padding: 0.25rem 0.5rem;background: #eee;border-radius: 0.25rem;width: 100%;float: left;">Resolution Information</span>');
        inMap.put('resolutionCode', dispute.celsrm__Resolution_Code__c);
        inMap.put('rejectionCode', dispute.Rejection_Code__c);
        inMap.put('rootCause', dispute.Root_Cause__c); //
        inMap.put('latestNote', dispute.celsrm__Latest_Note__c); 

        inMap.put('systemInformation', '<span style="font-size: 14px;font-weight: 600;padding: 0.25rem 0.5rem;background: #eee;border-radius: 0.25rem;width: 100%;float: left;">System Information</span>');
        Map<String, String> createdByObj = new Map<String, String>();
        createdByObj.put('id', dispute.CreatedById);
        createdByObj.put('name', dispute.CreatedBy.Name);
        inMap.put('createdBy', createdByObj);
        Map<String, String> lastModByObj = new Map<String, String>();
        lastModByObj.put('id', dispute.LastModifiedById);
        lastModByObj.put('name', dispute.LastModifiedBy.Name);
        inMap.put('lastModifiedBy', lastModByObj);

        inMap.put('activityInformation', '<span style="font-size: 14px;font-weight: 600;padding: 0.25rem 0.5rem;background: #eee;border-radius: 0.25rem;width: 100%;float: left;">Activity Information</span>');

        inMap.put('filesInformation', '<span style="font-size: 14px;font-weight: 600;padding: 0.25rem 0.5rem;background: #eee;border-radius: 0.25rem;width: 100%;float: left;">Files Information</span>');
        //-- Start | FIN-9672 | Changed by Ravi | 05 May 2026 --//
        celsrm__Dispute_Configuration__c config = celsrm__Dispute_Configuration__c.getOrgDefaults();
        if(resolvedUser != null && resolvedUser.userId == UserInfo.getUserId()) {
        //-- End | FIN-9672 | Changed by Ravi | 05 May 2026 --//
            inMap.put('CurrentUserIsResolver', 'true');
        } else if(dispute.celsrm__Owner__c == UserInfo.getUserId()) {
            inMap.put('CurrentUserIsOwner', 'true');
        }
        //-- Starts | FIN-9786 | Changed by Asera | 24-Jun-2026 --//
        if (isParallelWorkflow(config) && hasPendingWorkflowActionForCurrentUser(dispute, UserInfo.getUserId(), config, inMap)) {
            inMap.put('CurrentUserIsResolver', 'true');
        }
        //-- End | FIN-9786 | Changed by Asera | 24-Jun-2026 --//
        inMap.put('currentUser', UserInfo.getUserId());
        //-- Starts |FIN-7502| Changed by Asera | 25 Nov 2025 --//
        try {
            Map<String, Object> metadataMap = new Map<String, Object>{
                'disputeResolverId' => dispute.celsrm__Dispute_Resolver__c,
                'disputeType' => dispute.celsrm__Dispute_Type__c,
                'reasonCode' => dispute.celsrm__Reason_Code__c,
                'disputeStatus' => dispute.celsrm__Status__c,
                'disputeAmount' => dispute.celsrm__Amount__c,
                'invoiceAmount' => dispute.celsrm__Transaction__r.celsrm__Amount__c,
                'disputeSLADays' => dispute.Dispute_SLA_Days__c,
                'createdDate' => dispute.celsrm__Created_Date__c,
                'disputeResolver' => JSON.serialize(inMap.get('disputeResolver'))
            };
            String metadataJson = JSON.serialize(metadataMap);
            Map<String, Object> inputParams = new Map<String, Object>{
                'userId' => UserInfo.getUserId(),
                'pageScreenName' => 'Dispute Details Screen',
                'actionPerformed' => false,
                'actionTakenTime' => null,
                'accountId' => dispute.celsrm__Account__r.Id,
                'transactionId' => dispute.celsrm__Transaction__c,
                'disputeId' => (String)inMap.get('Id'),
                'additionalMetadata' => metadataJson
            };
            Id activityId = celsrm.SRMUtilityController.logActivity(JSON.serialize(inputParams));
            System.debug('Full activity : ' + activityId);
            inMap.put('activityLogId', activityId);
        } catch (Exception e) {
            System.debug('Error logging activity: ' + e.getMessage() + ' ' + e.getLineNumber());
            inMap.put('ggErrorMessage', e.getMessage() + ' ' + e.getLineNumber());
        } 
        //-- End |FIN-7502| Changed by Asera | 25 Nov 2025 --//
        system.debug('CurrentUserIsResolver:'+inMap.get('CurrentUserIsResolver'));
        //-- Starts | FIN-7796 | Changed by Dilshad | 30-Jun-2025 --//
        String disputeResolverType = config != null && !String.isEmpty(config.celsrm__Dispute_Resolver_Type__c) ? config.celsrm__Dispute_Resolver_Type__c : 'Account_Owner';
        inMap.put('disputeResolverType', disputeResolverType);
        //-- Ends | FIN-7796 | Changed by Dilshad | 30-Jun-2025 --//
        return inMap;
    }
    //-- Starts | FIN-9786 | Changed by Asera | 24-Jun-2026 --//
    private static Boolean isParallelWorkflow(celsrm__Dispute_Configuration__c config) {
        return config != null
            && config.celsrm__Use_Dispute_Workflow_Matrix__c == true
            && !DisputeApprovalProcessController.isSequentialFlow(config.celsrm__Dispute_Workflow_Matrix_Flow_Type__c);
    }

    private static Boolean hasPendingWorkflowActionForCurrentUser(
        celsrm__Dispute__c dispute,
        Id currentUserId,
        celsrm__Dispute_Configuration__c config,
        Map<Object, Object> inMap
    ) {
        if (dispute == null || currentUserId == null) {
            return false;
        }

        Boolean allowDelegatedUserOrManagerToAct = config != null && config.celsrm__Allow_Delegated_User_Manger_to_act__c;
        Boolean allowOwnerQueue = config != null && config.celsrm__Owner_Can_Act_on_Queue_Disputes__c;
        Set<Id> currentUserMasterIds = CreditReviewAccessUtil.getCurrentUserMasterIds(currentUserId);
        Set<Id> currentUserQueueIds = CreditReviewAccessUtil.getQueueIdsForUserWithNestedGroups(currentUserId);

        List<celsrm__Dispute_Workflow_Details__c> pendingDetails = [
            SELECT Id, celsrm__User_Master__c, celsrm__Queue__c
            FROM celsrm__Dispute_Workflow_Details__c
            WHERE celsrm__Dispute__c = :dispute.Id
            AND celsrm__Status__c = 'Pending'
        ];

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

        if (CreditReviewAccessUtil.hasIntersection(currentUserMasterIds, pendingUserMasterIds)) {
            inMap.put('parallelWorkflowAccessReason', 'Direct user assignment.');
            return true;
        }
        if (CreditReviewAccessUtil.hasIntersection(currentUserQueueIds, pendingQueueIds)) {
            if (dispute.celsrm__Owner__c == currentUserId && allowOwnerQueue != true) {
                inMap.put('parallelWorkflowAccessReason', 'Owner is restricted on queue-assigned dispute by configuration.');
                return false;
            }
            inMap.put('parallelWorkflowAccessReason', 'Direct queue assignment.');
            return true;
        }

        if (allowDelegatedUserOrManagerToAct == true && !currentUserMasterIds.isEmpty()) {
            if (!pendingUserMasterIds.isEmpty()
                && CreditReviewAccessUtil.isDelegatedOrManagerForAnyMaster(pendingUserMasterIds, currentUserMasterIds)
            ) {
                inMap.put('parallelWorkflowAccessReason', 'Delegated/manager access for assigned user.');
                return true;
            }

            if (!pendingQueueIds.isEmpty()) {
                Set<Id> queueMemberUserIds = CreditReviewAccessUtil.getUserIdsForQueuesWithNestedGroups(pendingQueueIds);
                if (!queueMemberUserIds.isEmpty()
                    && CreditReviewAccessUtil.isDelegatedOrManagerForAnySalesforceUser(queueMemberUserIds, currentUserMasterIds)
                ) {
                    inMap.put('parallelWorkflowAccessReason', 'Delegated/manager access via queue member.');
                    return true;
                }
            }
        }

        inMap.put('parallelWorkflowAccessReason', 'Current user is not eligible to act on pending workflow entries.');
        return false;
    }
    //-- End | FIN-9786 | Changed by Asera | 24-Jun-2026 --//

    //-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
    public static Map<Object, Object> fetchDisputeWorkflowHistory(Map<Object, Object> inMap){
        String disputeId = (String)inMap.get('Id');
        List<Map<Object,Object>> recordObjectList = new List<Map<Object,Object>>();
        if (String.isBlank(disputeId)) {
            inMap.put('dataServiceResponse', recordObjectList);
            return inMap;
        }
        List<celsrm__Dispute_Workflow_Details__c> dwdList = [
            SELECT Id, celsrm__Status__c, celsrm__Action_Date__c, celsrm__User_Action__c,
                   celsrm__Action_Taken_By__c, celsrm__Action_Taken_By__r.Name,
                   celsrm__User_Master__c, celsrm__User_Master__r.Name, celsrm__User_Master__r.celsrm__Email__c, celsrm__User_Master__r.celsrm__User__c,
                   celsrm__User_Master__r.celsrm__Is_External_User__c, celsrm__Queue__c, celsrm__Workflow_Level__c, celsrm__Workflow_User_Type__c
            FROM celsrm__Dispute_Workflow_Details__c
            WHERE celsrm__Dispute__c = :disputeId
            ORDER BY celsrm__Workflow_Level__c ASC NULLS LAST, CreatedDate ASC
        ];

        Set<Id> queueIds = new Set<Id>();
        for (celsrm__Dispute_Workflow_Details__c detailRow : dwdList) {
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

        for (celsrm__Dispute_Workflow_Details__c disputeWD : dwdList){
            Map<Object,Object> recordObject = new Map<Object,Object>();
            recordObject.put('status', disputeWD.celsrm__Status__c);
            recordObject.put('actionDate', disputeWD.celsrm__Action_Date__c);
            recordObject.put('actionName', disputeWD.celsrm__User_Action__c);
            recordObject.put('TATMet', null);
            recordObject.put('level', disputeWD.celsrm__Workflow_Level__c);
            recordObject.put('userType', disputeWD.celsrm__Workflow_User_Type__c);

            if (disputeWD.celsrm__Queue__c != null) {
                String queueName = queueNameById.get(disputeWD.celsrm__Queue__c);
                recordObject.put('userEmail', '');
                recordObject.put('userName', queueName);
                Map<String, Object> userLink = new Map<String, Object>();
                userLink.put('id', disputeWD.celsrm__Queue__c);
                userLink.put('name', queueName);
                recordObject.put('userLink', userLink);
            } else if (disputeWD.celsrm__User_Master__c != null) {
                String displayName = disputeWD.celsrm__User_Master__r == null ?  null : disputeWD.celsrm__User_Master__r.Name;
                String displayEmail = disputeWD.celsrm__User_Master__r == null ? null : disputeWD.celsrm__User_Master__r.celsrm__Email__c;
                Boolean isExternal = disputeWD.celsrm__User_Master__r != null && disputeWD.celsrm__User_Master__r.celsrm__Is_External_User__c == true;
                Id salesforceUserId = disputeWD.celsrm__User_Master__r == null ? null : disputeWD.celsrm__User_Master__r.celsrm__User__c;

                // if (String.isBlank(displayEmail)) {
                //     displayEmail = disputeWD.External_User_Email__c;
                // }
                // if (String.isBlank(displayEmail) && disputeWD.User__r != null) {
                //     displayEmail = disputeWD.User__r.Email;
                // }
                // if (String.isBlank(displayName)) {
                //     displayName = disputeWD.User_Name__c;
                // }
                // if (String.isBlank(displayName) && disputeWD.User__r != null) {
                //     displayName = disputeWD.User__r.Name;
                // }

                recordObject.put('userEmail', displayEmail);
                recordObject.put('userName', displayName);

                Map<String, Object> userLink = new Map<String, Object>();
                if (!isExternal && salesforceUserId != null) {
                    userLink.put('id', salesforceUserId);
                } else if (!String.isBlank(displayEmail)) {
                    userLink.put('id', displayEmail);
                } else {
                    userLink.put('id', disputeWD.celsrm__User_Master__c);
                }
                userLink.put('name', displayName);
                recordObject.put('userLink', userLink);
            } 
            // else if (disputeWD.External_User_Email__c != null) {
            //     recordObject.put('userEmail', disputeWD.External_User_Email__c);
            //     recordObject.put('userName', disputeWD.User_Name__c);
            // } 
            else {
                // recordObject.put('userEmail', disputeWD.User__r == null ? null : disputeWD.User__r.Email);
                // recordObject.put('userName', disputeWD.User_Name__c);
                // if (disputeWD.celsrm__User__c != null) {
                //     Map<String, Object> userLink = new Map<String, Object>();
                //     userLink.put('id', disputeWD.celsrm__User__c);
                //     userLink.put('name', disputeWD.User__r == null ? disputeWD.User_Name__c : disputeWD.User__r.Name);
                //     recordObject.put('userLink', userLink);
                // }
            }


            if (disputeWD.celsrm__Action_Taken_By__c != null) {
                Map<String, Object> actionTakenBy = new Map<String, Object>();
                actionTakenBy.put('id', disputeWD.celsrm__Action_Taken_By__c);
                actionTakenBy.put('name', disputeWD.celsrm__Action_Taken_By__r == null ? null : disputeWD.celsrm__Action_Taken_By__r.Name);
                recordObject.put('actionTakenBy', actionTakenBy);
            }
            recordObjectList.add(recordObject);
        }
        inMap.put('dataServiceResponse', recordObjectList);
        return inMap;
    }
    //-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//


    public static Map<Object, Object> fetchRelatedActivities(Map<Object, Object> inMap){
        String disputeId = (String)inMap.get('Id');
        
        List<Object> activityListObject = new List<Object>(); 
        List<celsrm__Celonis_Event__c> activityList = [SELECT Id, Name, celsrm__Event_Time__c, celsrm__Note__c, celsrm__User__c,
        celsrm__User__r.name, CreatedDate FROM celsrm__Celonis_Event__c WHERE celsrm__Dispute__c=: disputeId ORDER BY celsrm__Event_Time__c DESC];
        // if (celsrm.GOGSecurityController.isAccessible('Celonis_Event__c','name,Account__c,Transaction__c,Activity_Id__c,Event_Time__c,Metadata__c,Note__c,Sorting__c,Source_System__c,User__c')){
        if(activityList.size() > 0){
            
            for(celsrm__Celonis_Event__c activity : activityList){
                Map<Object,Object> activityMap = new Map<Object,Object>();
                activityMap.put('activity', activity.Name);
                activityMap.put('user', '<a href="/'+ activity.celsrm__User__c + '" target="_blank">' + activity.celsrm__User__r.name + '</a>');
                activityMap.put('timestamp', activity.celsrm__Event_Time__c);
                activityMap.put('notes', activity.celsrm__Note__c);
                activityListObject.add(activityMap);
            }
        } 
        System.debug('>>>>>'+ activityListObject);
        inMap.put('dataServiceResponse',activityListObject);
        return inMap;
    }

    // public static Map<Object, Object> onHoldDispute(Map<Object, Object> inMap){
    //     System.debug('into onHoldDispute method >>>');
    //     String disputeId = (String)inMap.get('Id');
    //     celsrm__Dispute__c dispute = new celsrm__Dispute__c();
    //     dispute.id = String.valueOf(inMap.get('Id'));
    //     //celsrm__Dispute__c dispute =[Select id,celsrm__Notes__c from celsrm__Dispute__c where id =: String.valueOf(inMap.get('Id'))];
    //     if(inMap.get('NoteBody') != null){      
    //         dispute.celsrm__Latest_Note_Date__c = date.today();
    //         dispute.celsrm__Latest_Note__c  =  String.valueOf(inMap.get('NoteBody'));
    //         dispute.celsrm__Latest_Note_Entered_By__c = UserInfo.getUserId();  
    //         dispute.celsrm__Status__c = 'On Hold';
    //         dispute.Hold_Reason__c = String.valueOf(inMap.get('holdReason'));
    //         update dispute;
    //     }
    //     celsrm.SRMUtilityController.insertActivity(new List<String>{dispute.Id}, 'Dispute__c', 'Hold Dispute', 100, String.valueOf(inMap.get('NoteBody')), UserInfo.getUserId(), null, 'Internal' );
    //     System.debug('onHoldDispute over >>>'+inMap.get('NoteBody'));
    //     return inMap;
    // }
}