//-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
// Please refer to the PR for the changes—almost every line in this class has been modified.
//-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
global with sharing class UpdateDisputeController implements celsrm.GOGIScreenCustomLogic {
    global Map<Object, Object> invoke(String functionName, Map<Object, Object> inMap){
        try {
            system.debug('FunctionName>>>>>'+functionName);
            if(functionName == 'onPageLoadFunction'){
                inMap = onPageLoadFunction(inMap);
            } else if(functionName == 'UpdateDispute') {
                updateDisputeWorkflow(inMap);
            } 
        } catch(exception ex){
            String errorMessage = 'ClassName: DisputeResolutionController | Method: invoke() | Linenumber: ' + ex.getLineNumber() + ' | Message: ' + ex.getMessage();
            System.debug('errorMessage: ' + errorMessage);
        }

        return inMap;
    }

    public static Map<Object, Object> onPageLoadFunction(Map<Object, Object> inMap) {
        String disputeId = (String)inMap.get('Id');
        
        //-- Current Resolver's User Level --//
        //-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
        //-- Starts | FIN-9786 | Changed by Asera | 24-Jun-2026 --//
        List<celsrm__Dispute_Workflow_Details__c> dwdList = [
            SELECT Id, celsrm__Workflow_Level__c, celsrm__Workflow_User_Type__c,
                   celsrm__Dispute__c, celsrm__Dispute_Workflow_Matrix__c, celsrm__User_Master__c,
                   celsrm__Queue__c, celsrm__Is_Optional__c, celsrm__User_SLA_Days__c
            FROM celsrm__Dispute_Workflow_Details__c
            WHERE celsrm__Dispute__c = :disputeId AND celsrm__Status__c = 'Pending'
            ORDER BY celsrm__Workflow_Level__c ASC NULLS LAST, CreatedDate ASC
        ];
        //-- Ends | FIN-9786 | Changed by Asera | 24-Jun-2026 --//
        //-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
        if(dwdList != null && dwdList.size() > 0) {
            //-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
            celsrm__Dispute_Workflow_Details__c dwdObj = dwdList.get(0);
            //-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
            inMap.put('disputeDetailId', dwdObj.Id);
            
            if(inMap.get('userAction') != null && ((String)inMap.get('userAction') == 'add-note' 
                || (String)inMap.get('userAction') == 'on-hold' || (String)inMap.get('userAction') == 'resume' || (String)inMap.get('userAction') == 'reject')) {
                    //-- Starts |FIN-7502| Changed by Asera | 25 Nov 2025 --//
                    try {
                        //-- Start | FIN-9672 | Changed by Ravi | 05 May 2026 --//
                        String customerId = null;
                        //-- End | FIN-9672 | Changed by Ravi | 05 May 2026 --//
                        if (inMap.containsKey('customerName')) {
                            Map<Object, Object> customerMap = (Map<Object, Object>) inMap.get('customerName');
                            customerId = String.valueOf(customerMap.get('id'));
                        }

                        String resolverId = '';
                        if (inMap.containsKey('disputeResolver')) {
                            Map<Object, Object> resolverMap = (Map<Object, Object>) inMap.get('disputeResolver');
                            resolverId = String.valueOf(resolverMap.get('id'));
                        }

                        Decimal disputeAmount = (inMap.containsKey('disputeAmount') && inMap.get('disputeAmount') != null)
                            ? (Decimal) inMap.get('disputeAmount') : 0;

                        String disputeType = (inMap.containsKey('disputeType')) ? String.valueOf(inMap.get('disputeType')) : '';
                        String reasonCode = (inMap.containsKey('reasonCode')) ? String.valueOf(inMap.get('reasonCode')) : '';

                        // Prepare input params
                        Map<String, Object> metadataMap = new Map<String, Object>{
                            'disputeAmount'    => disputeAmount,
                            'customerId'       => customerId,
                            'disputeType'      => disputeType,
                            'reasonCode'       => reasonCode,
                            'disputeResolver'  => resolverId,
                            'latestNote'       => inMap.get('latestNote')
                        };
                        String screenName = (String) inMap.get('ggScreenName');

                        if (screenName == 'Add Note On Dispute') {
                            screenName = 'Dispute: Add Note';
                        } else if (screenName == 'Dispute On Hold') {
                            screenName = 'Dispute: On Hold';
                        } else if (screenName == 'Dispute Rejected') {
                            screenName = 'Dispute: Rejected';
                        } else if (screenName == 'Dispute Resumed') {
                            screenName = 'Dispute: Resumed';
                        }
                        String metadataJson = JSON.serialize(metadataMap);
                        Map<String, Object> inputParams = new Map<String, Object>{
                            'userId' => UserInfo.getUserId(),
                            'pageScreenName' => screenName,
                            'actionPerformed' => false,
                            'actionTakenTime' => null,
                            'accountId' => customerId,
                            'transactionId' => null,
                            'disputeId' => disputeId,
                            'additionalMetadata' => metadataJson
                        };
                        System.debug('Full json :' + JSON.serialize(inputParams));
                        Id activityId = celsrm.SRMUtilityController.logActivity(JSON.serialize(inputParams));
                        System.debug('Full activity : ' + activityId);
                        inMap.put('activityLogId', activityId);
                    } catch (Exception e) {
                        System.debug('Error logging activity: ' + e.getMessage() + ' ' + e.getLineNumber());
                        inMap.put('ggErrorMessage', e.getMessage() + ' ' + e.getLineNumber());
                    }
                    //-- End |FIN-7502| Changed by Asera | 25 Nov 2025 --//
            } else {
                //-- Starts | FIN-7796 | Changed by Dilshad | 30-Jun-2025 --//
                if(String.valueOf(inMap.get('disputeResolverType')) == 'Dispute_Workflow_Matrix') { //-- case when dispute resolver type is Dispute Worlflow Matrix --//
                //-- Ends | FIN-7796 | Changed by Dilshad | 30-Jun-2025 --//
                    //-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
                    populateNextWorkflowStep(inMap, dwdObj);
                    //-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
                } else { //-- case when dispute resolver type is Account Owner or Logged In User --//
                    //-- Starts | FIN-7796 | Changed by Dilshad | 30-Jun-2025 --//
                    inMap.put('isLastApprover', 'true');
                    //-- Ends | FIN-7796 | Changed by Dilshad | 30-Jun-2025 --//
                }
            } 
        } else {
            inMap.put('stopExecution', true);
            inMap.put('ggErrorMessage', 'You are not authorized to take action on this dispute.');
            inMap.put('doNotSubmit', 'You are not authorized to take action on this dispute.');
        }
        celsrm__Dispute__c dispute = [SELECT Name, celsrm__Account__r.Id, celsrm__Account__r.Name,celsrm__Account__r.AccountNumber, celsrm__Transaction__r.Name, celsrm__Transaction__r.Id, celsrm__Dispute_Type__c, celsrm__Reason_Code__c FROM celsrm__Dispute__c WHERE Id = :disputeId];
        inMap.put('disputeNumber', dispute.Name);
        inMap.put('disputeType', dispute.celsrm__Dispute_Type__c);
        inMap.put('reasonCode', dispute.celsrm__Reason_Code__c);
        //--- Add Customer Number Field in Dispute Detail Screen --//
        Map<String, String> custObj = new Map<String, String>();
        custObj.put('id', dispute.celsrm__Account__r.Id);
        custObj.put('name', dispute.celsrm__Account__r.Name);
        inMap.put('customerName', custObj);
        inMap.put('customerNumber', dispute.celsrm__Account__r.AccountNumber);


        system.debug('inMap:'+inMap);
        return inMap;
    }
    
    public static Map<Object, Object> updateDisputeWorkflow(Map<Object, Object> inMap) {
        system.debug('doNotSubmit===>'+inMap.get('doNotSubmit'));
        String userAction = String.valueOf(inMap.get('userAction'));
        if(inMap.get('doNotSubmit') != null && String.valueOf(inMap.get('doNotSubmit')) != '' && (celsrm__Dispute_Configuration__c.getOrgDefaults().Enable_Dispute_Resolution__c) ) {
            inMap.put('ggErrorMessage', String.valueOf(inMap.get('doNotSubmit')));
        } else {
            Savepoint sp = Database.setSavepoint();
            try {
                String disputeId = (String)inMap.get('Id');
                //-- Update Dispute --//
                celsrm__Dispute__c dispObj = new celsrm__Dispute__c();
                dispObj.Id = disputeId;
                String disputeNoteTitle = inMap.get('noteTitle') != null && inMap.get('noteTitle') != '' ? String.valueOf(inMap.get('noteTitle')) : null;
                dispObj.celsrm__Latest_Note_Title__c = disputeNoteTitle;
                String disputeNote = inMap.get('noteBody') != null && inMap.get('noteBody') != '' ? String.valueOf(inMap.get('noteBody')) : null;
                if(disputeNote != null) {
                    dispObj.celsrm__Latest_Note__c = disputeNote;
                    dispObj.celsrm__Latest_Note_Date__c = Date.today();
                    dispObj.celsrm__Latest_Note_Entered_By__c = UserInfo.getUserId();
                }
                dispObj.Last_Touched_Date__c = Date.today();
                dispObj.Last_Touched_By__c = UserInfo.getUserId();
                //String disputeResolverId = String.valueOf(((Map<Object, Object>)inMap.get('nextResolverApprover')).get('id'));
                if(userAction == 'add-note') {
                    update dispObj;
                    //-- Starts |FIN-7502| Changed by Asera | 25 Nov 2025 --//
                    try {
                        Map<String, Object> metadataMap = new Map<String, Object>{
                            'DisputeObj' => JSON.serialize(dispObj),
                            'timestamp' => String.valueOf(Datetime.now())
                        };
                        Id activityId = (Id) inMap.get('activityLogId');
                        // Convert to JSON string
                        String metadataJson = JSON.serialize(metadataMap);
                        celsrm.SRMUtilityController.updateActivity(activityId, metadataJson);
                        
                        System.debug('Activity logged with Id: ' + activityId);
                    } catch (Exception e) {
                        System.debug('Failed to log activity: ' + e.getMessage());
                    }
                    //-- End |FIN-7502| Changed by Asera | 25 Nov 2025 --//
                } else if(userAction == 'reject') {
                    //-- Current User has rejected dispute --//
                    rejectDispute(inMap, dispObj);
                    //-- Starts : Update Dispute Workflow Detail --//
                    String tempNote = dispObj.Rejection_Code__c != null ? ' - ' + dispObj.Rejection_Code__c : '';
                    updateRejectedDisputeWorkflowDetail(String.valueOf(inMap.get('disputeDetailId')), 'Dispute Rejected' + tempNote);
                    rejectRemainingPendingWorkflowDetails(dispObj.Id, String.valueOf(inMap.get('disputeDetailId')));
                    //-- Ends : Update Dispute Workflow Detail --//
                } else if (userAction == 'resolve') {
                    resolveDispute(inMap, dispObj);
                    //-- Starts : Update Dispute Workflow Detail --//
                    String tempNote = dispObj.celsrm__Resolution_Code__c != null ? ' - ' + dispObj.celsrm__Resolution_Code__c : '';
                    updateDisputeWorkflowDetails(String.valueOf(inMap.get('disputeDetailId')), 'Dispute Resolved' + tempNote);
                    //-- Ends : Update Dispute Workflow Detail --//
                } else if (userAction == 'approve') {
                    approveDispute(inMap, dispObj);
                    //-- Starts : Update Dispute Workflow Detail --//
                    String tempNote = dispObj.celsrm__Resolution_Code__c != null ? ' - ' + dispObj.celsrm__Resolution_Code__c : '';
                    updateDisputeWorkflowDetails(String.valueOf(inMap.get('disputeDetailId')), 'Dispute Approved' + tempNote);
                    //-- Ends : Update Dispute Workflow Detail --// 
                } else if (userAction == 'on-hold') {
                    onHoldDispute(inMap, dispObj);
                } else if (userAction == 'resume') {
                    resumeDispute(inMap, dispObj);
                }   

                //-- Start : Insert Celonis Event for Dispute --//
                List<String> disputeList = new List<String>();
                String userActionStr = '';
                if (userAction == 'resolve') {
                    userActionStr = 'Dispute Resolved';
                } else if (userAction == 'approve') {
                    userActionStr = 'Dispute Approved';
                } else if (userAction == 'reject') {
                    userActionStr = 'Dispute Rejected';
                } else if (userAction == 'add-note') {
                    userActionStr = 'Note Added';
                } else if (userAction == 'on-hold') {
                    userActionStr = 'Dispute On Hold';
                } else if (userAction == 'resume') {
                    userActionStr = 'Dispute Resumed';
                } 
                disputeList.add(disputeId);
                if(!disputeList.isEmpty()) {
                    // celsrm.SRMUtilityController.insertActivity( disputeList, 'celsrm__Dispute__c', userActionStr, 100, disputeNote, UserInfo.getUserId(), null, 'Internal');
                    insertActivity( disputeList, 'celsrm__Dispute__c', userActionStr, null, 100, disputeNote, UserInfo.getUserId(), null, 'Internal', null);
                    
                }
                //-- Ends : Insert Celonis Event for Dispute --//

                //-- Start : Insert Celonis Event for Transaction --//
                // List<String> transList = new List<String>();
                // String transactionId = String.valueOf(((Map<Object, Object>)inMap.get('invoiceNumber')).get('id'));
                // transList.add(transactionId);
                // if(!transList.isEmpty()) {
                //     celsrm.SRMUtilityController.insertActivity( transList, 'celsrm__Transaction__c', userActionStr, 100, disputeNote, UserInfo.getUserId(), null, 'Internal');
                // }
                //-- Ends : Insert Celonis Event for Dispute --//

                //-- Start : Insert Celonis Event for Account --//
                // List<String> accList = new List<String>();
                // String accountId = String.valueOf(((Map<Object, Object>)inMap.get('customerName')).get('id'));
                // accList.add(accountId);
                // if(!accList.isEmpty()) {
                //     celsrm.SRMUtilityController.insertActivity( accList, 'celsrm__Account__c', userActionStr, 100, disputeNote, UserInfo.getUserId(), null, 'Internal');
                // }
                //-- Ends : Insert Celonis Event for Account --//
            } catch (Exception ex) {
                // An error occurred, so roll back to the savepoint
                Database.rollback(sp);

                // Optionally, log or handle the exception
                System.debug('Error: ' + ex.getMessage());
                inMap.put('ggErrorMessage', 'There has been some error while resolving the dispute. Please contact system admin. Error:' + ex.getStackTraceString());
            }
        }
        return inMap;
    }

    public static void rejectDispute(Map<Object, Object> inMap, celsrm__Dispute__c dispObj) {
        dispObj.Rejection_Code__c = inMap.get('rejectionCode') != null && inMap.get('rejectionCode') != '' ? String.valueOf(inMap.get('rejectionCode')) : null;
        dispObj.Reject_Reason__c = inMap.get('rejectReason') != null && inMap.get('rejectReason') != '' ? String.valueOf(inMap.get('rejectReason')) : null;
        dispObj.celsrm__Status__c = 'Rejected';
        //-- Start | FIN-9672 | Changed by Ravi | 05 May 2026 --//
        //-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
        applyFinalActionUserMasterToDispute(dispObj, inMap);
        //-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
        dispObj.celsrm__Dispute_Resolver__c = null;
        dispObj.External_Resolver_Email__c = null;
        //-- End | FIN-9672 | Changed by Ravi | 05 May 2026 --//
        dispObj.celsrm__Workflow_Matrix_Id__c = null;
        dispObj.celsrm__Close_Date__c = Date.Today();
        update dispObj;
        //-- Starts |FIN-7502| Changed by Asera | 25 Nov 2025 --//
        try {
            //-- Start | FIN-9672 | Changed by Ravi | 05 May 2026 --//
            if (celsrm__Golden_Gate_Configuration__c.getOrgDefaults().celsrm__User_Tracking__c) {
            //-- End | FIN-9672 | Changed by Ravi | 05 May 2026 --//   
            //-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
            Map<String, Object> metadataMap = new Map<String, Object>{
                'DisputeObj' => JSON.serialize(dispObj),
                'timestamp' => String.valueOf(Datetime.now())
            };
            Id activityId = (Id) inMap.get('activityLogId');
            // Convert to JSON string
            String metadataJson = JSON.serialize(metadataMap);
            //-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
                celsrm.SRMUtilityController.updateActivity(activityId, metadataJson);
         
                System.debug('Activity logged with Id: ' + activityId);
            
            //-- Start | FIN-9672 | Changed by Ravi | 05 May 2026 --//
            }
            //-- End | FIN-9672 | Changed by Ravi | 05 May 2026 --//
        } catch (Exception e) {
            System.debug('Failed to log activity: ' + e.getMessage());
        }
        //-- End |FIN-7502| Changed by Asera | 25 Nov 2025 --//
    }

    public static void resolveDispute(Map<Object, Object> inMap, celsrm__Dispute__c dispObj) {
        //-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
        String disputeResolverId = getNextResolverApproverId(inMap);
        System.debug('disputeResolverId' + disputeResolverId);
        Boolean shouldAssignNextWorkflowStep = shouldAssignNextWorkflowStepOnResolve();
        //-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
        dispObj.celsrm__Resolution_Code__c = inMap.get('resolutionCode') != null && inMap.get('resolutionCode') != '' ? String.valueOf(inMap.get('resolutionCode')) : null;
        dispObj.Root_Cause__c = String.valueOf(inMap.get('rootCause'));
        //-- Starts | FIN-9786 | Changed by Asera | 24-Jun-2026 --//
        if (!shouldAssignNextWorkflowStep && isMatrixApprovalWorkflowEnabled()) {
            completeParallelResolverPhase(inMap, dispObj);
            update dispObj;
            return;
        }
        //-- Ends | FIN-9786 | Changed by Asera | 24-Jun-2026 --//
        if(disputeResolverId != null && disputeResolverId != '') {
            //-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
            //-- If celsrm__Dispute_Resolver__c is not the last approver/resolver --//
            //-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
            String disputeMatrixId = inMap.get('disputeMatrixId') != null && inMap.get('disputeMatrixId') != '' ? String.valueOf(inMap.get('disputeMatrixId')) : null;
            //-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
            if (shouldAssignNextWorkflowStep) {
                if (isValidDisputeResolverId(disputeResolverId)) {
                    dispObj.celsrm__Resolver_User_Master__c = disputeResolverId;
                    dispObj.External_Resolver_Email__c = null;
                } else {
                    dispObj.celsrm__Resolver_User_Master__c = null;
                    dispObj.External_Resolver_Email__c = disputeResolverId;
                }
            } else {
                applyFinalActionUserMasterToDispute(dispObj, inMap);
            }
            dispObj.celsrm__Workflow_Matrix_Id__c = disputeMatrixId;
            //-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//

            //-- If Next Resolver/Approver is 'Approver' --//
            if(String.valueOf(inMap.get('resolverApproverType')) == 'Approver') {
                dispObj.celsrm__Status__c = 'Pending Approval';
            }            

            //-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
            if (shouldAssignNextWorkflowStep) {
                progressWorkflowAfterResolverHandoff(inMap, dispObj.Id, disputeMatrixId);
            }
            //-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
        }  else {
            //-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
            //-- If celsrm__Dispute_Resolver__c is the last approver/resolver or Current User has removed Next Resolver/Approver --//
            //-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
            
            //-- The current user is the last approver (approver limit > dispute amount)
            if(inMap.get('isLastApprover') != null && Boolean.valueOf(inMap.get('isLastApprover'))) {
                applyFinalActionUserMasterToDispute(dispObj, inMap);
                //-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
                dispObj.celsrm__Workflow_Matrix_Id__c = null;
                //-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
                dispObj.celsrm__Status__c = 'Approved';
                dispObj.celsrm__Close_Date__c = Date.Today();
            } else {
                if (!shouldAssignNextWorkflowStep) {
                    applyFinalActionUserMasterToDispute(dispObj, inMap);
                    if (hasPendingApproverWorkflowDetails(dispObj.Id, inMap)) {
                        dispObj.celsrm__Status__c = 'Pending Approval';
                    } else {
                        applyFinalActionUserMasterToDispute(dispObj, inMap);
                        dispObj.celsrm__Workflow_Matrix_Id__c = null;
                        dispObj.celsrm__Status__c = 'Approved';
                        dispObj.celsrm__Close_Date__c = Date.Today();
                    }
                } else if(String.valueOf(inMap.get('resolverApproverType')) == 'Resolver') {
                    //-- The current user has manually removed next resolver. So we will assign next approver to dispute --//
                    //-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
                    NextWorkflowStep approverStep = findHighestLevelApproverStep(
                        inMap.get('disputeMatrixId') != null ? Id.valueOf(String.valueOf(inMap.get('disputeMatrixId'))) : null
                    );
                    if (approverStep != null) {
                        Map<Object, Object> nextResolverApprover = buildNextResolverApproverMap(approverStep.userMaster);
                        String nextResolverId = nextResolverApprover == null ? null : String.valueOf(nextResolverApprover.get('id'));

                        applyResolvedAssigneeToDispute(dispObj, nextResolverId);

                        dispObj.celsrm__Workflow_Matrix_Id__c = approverStep.matrixId;
                    //-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
                        dispObj.celsrm__Status__c = 'Pending Approval';
                        //-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
                        if (isMatrixApprovalWorkflowEnabled()) {
                            DisputeApprovalProcessController.insertWorkflowDetailIfMissing(
                                dispObj.Id,
                                approverStep.matrixId,
                                approverStep.assignment
                            );
                        } else {
                            insertDisputeWorkflowDetails(dispObj.Id, String.valueOf(approverStep.matrixId), nextResolverId);
                        }
                        //-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
                    } else {
                        //-- approver do not exists : we will complete the dispute flow --//
                        dispObj.celsrm__Resolver_User_Master__c = null;
                        dispObj.External_Resolver_Email__c = null;
                        //-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
                        dispObj.celsrm__Workflow_Matrix_Id__c = null;
                        //-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
                        dispObj.celsrm__Status__c = 'Approved';
                        dispObj.celsrm__Close_Date__c = Date.Today();
                    }
                } else {
                    //-- The current user has manually removed next approver. So we will complete the dispute --//
                    //-- Start | FIN-9672 | Changed by Ravi | 05 May 2026 --//
                    //-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
                    dispObj.celsrm__Resolver_User_Master__c = null;
                    //-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
                    //-- End | FIN-9672 | Changed by Ravi | 05 May 2026 --//
                    dispObj.celsrm__Resolver_User_Master__c = null;
                    dispObj.External_Resolver_Email__c = null;
                    //-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
                    dispObj.celsrm__Workflow_Matrix_Id__c = null;
                    //-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
                    dispObj.celsrm__Status__c = 'Approved';
                    dispObj.celsrm__Close_Date__c = Date.Today();
                }
            }
        }
        update dispObj;
    }
    private static Boolean isValidDisputeResolverId(String disputeResolverId) {
        Id parsedId = tryParseId(disputeResolverId);
        return parsedId != null && parsedId.getSObjectType() == celsrm__User_Master__c.SObjectType;
    }

    private static Id tryParseId(String idValue) {
        if (String.isBlank(idValue)) {
            return null;
        }
        try {
            return Id.valueOf(idValue);
        } catch (Exception ex) {
            return null;
        }
    }

    private static Boolean isSalesforceUserId(String idValue) {
        Id parsedId = tryParseId(idValue);
        return parsedId != null && parsedId.getSObjectType() == User.SObjectType;
    }

    private static DisputeUserMasterService.ResolvedUserInfo resolveNextResolverApprover(
        Map<Object, Object> nextResolverApprover
    ) {
        if (nextResolverApprover == null) {
            return null;
        }

        String userMasterIdValue = nextResolverApprover.get('userMasterId') != null
            ? String.valueOf(nextResolverApprover.get('userMasterId'))
            : null;
        String assigneeValue = nextResolverApprover.get('id') != null
            ? String.valueOf(nextResolverApprover.get('id'))
            : null;
        String displayName = nextResolverApprover.get('name') != null
            ? String.valueOf(nextResolverApprover.get('name'))
            : null;

        Id userMasterId = isValidDisputeResolverId(userMasterIdValue)
            ? Id.valueOf(userMasterIdValue)
            : null;
        if (userMasterId == null && isValidDisputeResolverId(assigneeValue)) {
            userMasterId = Id.valueOf(assigneeValue);
        }

        String userIdOrEmail = userMasterId == null ? assigneeValue : null;
        Boolean shouldCreateExternalMaster = !String.isBlank(userIdOrEmail) && !isSalesforceUserId(userIdOrEmail);
        return DisputeUserMasterService.resolveUserAssignment(
            userMasterId,
            userIdOrEmail,
            displayName,
            shouldCreateExternalMaster,
            null
        );
    }

    private static String getResolvedAssigneeIdOrEmail(Map<Object, Object> nextResolverApprover) {
        DisputeUserMasterService.ResolvedUserInfo resolvedUser = resolveNextResolverApprover(nextResolverApprover);
        if (resolvedUser != null && resolvedUser.userMasterId != null) {
            return String.valueOf(resolvedUser.userMasterId);
        }
        if (resolvedUser != null && !String.isBlank(resolvedUser.email)) {
            return resolvedUser.email;
        }
        if (nextResolverApprover == null || nextResolverApprover.get('id') == null) {
            return null;
        }
        return String.valueOf(nextResolverApprover.get('id'));
    }

    private static void applyResolvedAssigneeToDispute(celsrm__Dispute__c dispObj, String assigneeIdOrEmail) {
        if (dispObj == null) {
            return;
        }
        if (isValidDisputeResolverId(assigneeIdOrEmail)) {
            dispObj.celsrm__Resolver_User_Master__c = assigneeIdOrEmail;
            dispObj.External_Resolver_Email__c = null;
            return;
        }
        dispObj.celsrm__Resolver_User_Master__c = null;
        dispObj.External_Resolver_Email__c = assigneeIdOrEmail;
    }

    private static void applyFinalActionUserMasterToDispute(celsrm__Dispute__c dispObj, Map<Object, Object> inMap) {
        if (dispObj == null) {
            return;
        }
        Id actingUserMasterId = getWorkflowDetailUserMasterId(inMap);
        if (actingUserMasterId == null) {
            dispObj.celsrm__Resolver_User_Master__c = null;
            dispObj.External_Resolver_Email__c = null;
            return;
        }
        dispObj.celsrm__Resolver_User_Master__c = actingUserMasterId;
        dispObj.External_Resolver_Email__c = null;
    }

    public static void approveDispute(Map<Object, Object> inMap, celsrm__Dispute__c dispObj) {
        //-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
        String disputeResolverId = getNextResolverApproverId(inMap);
        //-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
        //-- Starts | FIN-9786 | Changed by Asera | 24-Jun-2026 --//
        if (isParallelMatrixWorkflowEnabled()) {
            refreshParallelPendingApproverStep(inMap, dispObj);
            disputeResolverId = getNextResolverApproverId(inMap);
        }
        //-- Ends | FIN-9786 | Changed by Asera | 24-Jun-2026 --//
        dispObj.celsrm__Resolution_Code__c = inMap.get('resolutionCode') != null && inMap.get('resolutionCode') != '' ? String.valueOf(inMap.get('resolutionCode')) : null;
        dispObj.Root_Cause__c = String.valueOf(inMap.get('rootCause'));
        if(inMap.get('isLastApprover') != null && Boolean.valueOf(inMap.get('isLastApprover'))) {
            //-- The current user is the last approver (approver limit > dispute amount)
            applyFinalActionUserMasterToDispute(dispObj, inMap);
            //-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
            dispObj.celsrm__Workflow_Matrix_Id__c = null;
            //-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
            dispObj.celsrm__Status__c = 'Approved';
            dispObj.celsrm__Close_Date__c = Date.Today();
        } else if(disputeResolverId != null && disputeResolverId != '') {
            //-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
            //-- If celsrm__Resolver_User_Master__c is not the last approver/resolver --//
            //-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
            String disputeMatrixId = inMap.get('disputeMatrixId') != null && inMap.get('disputeMatrixId') != '' ? String.valueOf(inMap.get('disputeMatrixId')) : null;
            //-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
            applyResolvedAssigneeToDispute(dispObj, disputeResolverId);
            //-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
            
            //-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
            dispObj.celsrm__Workflow_Matrix_Id__c = disputeMatrixId;
            progressWorkflowAfterResolverHandoff(inMap, dispObj.Id, disputeMatrixId);
            //-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
        } else {
            //-- The current user has manually removed next resolver. We will complete the dispute flow --//
            applyFinalActionUserMasterToDispute(dispObj, inMap);
            //-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
            dispObj.celsrm__Workflow_Matrix_Id__c = null;
            //-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
            dispObj.celsrm__Status__c = 'Approved';
            dispObj.celsrm__Close_Date__c = Date.Today();
        }
        update dispObj;
    }

    public static void onHoldDispute(Map<Object, Object> inMap, celsrm__Dispute__c dispObj) {
        dispObj.Hold_Reason__c = inMap.get('holdReason') != null && inMap.get('holdReason') != '' ? String.valueOf(inMap.get('holdReason')) : null;
        dispObj.Previous_Status__c = String.valueOf(inMap.get('disputeStatus'));
        dispObj.celsrm__Status__c = 'On Hold';
        update dispObj;
        //-- Starts |FIN-7502| Changed by Asera | 25 Nov 2025 --//
        try {
            Map<String, Object> metadataMap = new Map<String, Object>{
                'DisputeObj' => JSON.serialize(dispObj),
                'timestamp' => String.valueOf(Datetime.now())
            };
            Id activityId = (Id) inMap.get('activityLogId');
            // Convert to JSON string
            String metadataJson = JSON.serialize(metadataMap);
            celsrm.SRMUtilityController.updateActivity(activityId, metadataJson);
            
            System.debug('Activity logged with Id: ' + activityId);
        } catch (Exception e) {
            System.debug('Failed to log activity: ' + e.getMessage());
        }
        //-- End |FIN-7502| Changed by Asera | 25 Nov 2025 --//
    }

    public static void resumeDispute(Map<Object, Object> inMap, celsrm__Dispute__c dispObj) {
        dispObj.Hold_Reason__c = inMap.get('holdReason') != null && inMap.get('holdReason') != '' ? String.valueOf(inMap.get('holdReason')) : null;
        dispObj.celsrm__Status__c = String.valueOf(inMap.get('disputePreviousStatus'));
        dispObj.Previous_Status__c = null;
        update dispObj;
        //-- Starts |FIN-7502| Changed by Asera | 25 Nov 2025 --//
        try {
            Map<String, Object> metadataMap = new Map<String, Object>{
                'DisputeObj' => JSON.serialize(dispObj),
                'timestamp' => String.valueOf(Datetime.now())
            };
            Id activityId = (Id) inMap.get('activityLogId');
            // Convert to JSON string
            String metadataJson = JSON.serialize(metadataMap);
            celsrm.SRMUtilityController.updateActivity(activityId, metadataJson);
            
            System.debug('Activity logged with Id: ' + activityId);
        } catch (Exception e) {
            System.debug('Failed to log activity: ' + e.getMessage());
        }
        //-- End |FIN-7502| Changed by Asera | 25 Nov 2025 --//
    }

     //-- Insert Dispute Workflow Detail --//
     public static void insertDisputeWorkflowDetails(String disputeId, String disputeMatrixId, String disputeResolverId) {
        //-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
        celsrm__Dispute_Workflow_Details__c dwdInsObj = new celsrm__Dispute_Workflow_Details__c();
        dwdInsObj.celsrm__Dispute__c = disputeId;
        dwdInsObj.celsrm__Status__c = 'Pending';
        dwdInsObj.celsrm__Dispute_Workflow_Matrix__c = disputeMatrixId;
        if (isValidDisputeResolverId(disputeResolverId)) {
            dwdInsObj.celsrm__user_master__c = disputeResolverId;
            // dwdInsObj.celsrm__External_User_Email__c = null;
        } else {
            dwdInsObj.celsrm__user_master__c = null;
            // dwdInsObj.celsrm__External_User_Email__c = disputeResolverId;
        }
        //-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
        
        insert dwdInsObj;
    }

//-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//

    private static Boolean isMatrixApprovalWorkflowEnabled() {
        celsrm__Dispute_Configuration__c config = celsrm__Dispute_Configuration__c.getOrgDefaults();
        return config != null && config.celsrm__Use_Dispute_Workflow_Matrix__c == true;
    }

    private static Boolean shouldAssignNextWorkflowStepOnResolve() {
        celsrm__Dispute_Configuration__c config = celsrm__Dispute_Configuration__c.getOrgDefaults();
        if (config == null || config.celsrm__Use_Dispute_Workflow_Matrix__c != true) {
            return true;
        }
        return DisputeApprovalProcessController.isSequentialFlow(
            config.celsrm__Dispute_Workflow_Matrix_Flow_Type__c
        );
    }

    //-- Starts | FIN-9786 | Changed by Asera | 24-Jun-2026 --//
    private static Boolean isParallelMatrixWorkflowEnabled() {
        celsrm__Dispute_Configuration__c config = celsrm__Dispute_Configuration__c.getOrgDefaults();
        return config != null
            && config.celsrm__Use_Dispute_Workflow_Matrix__c == true
            && !DisputeApprovalProcessController.isSequentialFlow(
                config.celsrm__Dispute_Workflow_Matrix_Flow_Type__c
            );
    }
    //-- Ends | FIN-9786 | Changed by Asera | 24-Jun-2026 --//

    private static String getNextResolverApproverId(Map<Object, Object> inMap) {
        if (inMap == null || !(inMap.get('nextResolverApprover') instanceof Map<Object, Object>)) {
            return null;
        }
        Map<Object, Object> nextResolverApprover = (Map<Object, Object>) inMap.get('nextResolverApprover');
        return getResolvedAssigneeIdOrEmail(nextResolverApprover);
    }

    private static Integer getCompletedWorkflowLevel(Map<Object, Object> inMap) {
        if (inMap == null || inMap.get('disputeDetailId') == null) {
            return null;
        }
        Id completedDetailId;
        try {
            completedDetailId = Id.valueOf(String.valueOf(inMap.get('disputeDetailId')));
        } catch (Exception ex) {
            return null;
        }
        List<celsrm__Dispute_Workflow_Details__c> completedRows = [
            SELECT celsrm__Workflow_Level__c
            FROM celsrm__Dispute_Workflow_Details__c
            WHERE Id = :completedDetailId
            LIMIT 1
        ];
        return completedRows.isEmpty() ? null : getWorkflowDetailLevel(completedRows[0]);
    }

    private static Id getWorkflowDetailUserMasterId(Map<Object, Object> inMap) {
        if (inMap == null || inMap.get('disputeDetailId') == null) {
            return null;
        }

        Id workflowDetailId = tryParseId(String.valueOf(inMap.get('disputeDetailId')));
        if (workflowDetailId == null) {
            return null;
        }

        List<celsrm__Dispute_Workflow_Details__c> workflowDetails = [
            SELECT celsrm__User_Master__c
            FROM celsrm__Dispute_Workflow_Details__c
            WHERE Id = :workflowDetailId
            LIMIT 1
        ];
        return workflowDetails.isEmpty() ? null : workflowDetails[0].celsrm__User_Master__c;
    }

    private static Boolean hasPendingApproverWorkflowDetails(Id disputeId, Map<Object, Object> inMap) {
        if (disputeId == null) {
            return false;
        }

        Id currentDetailId = null;
        if (inMap != null && inMap.get('disputeDetailId') != null) {
            currentDetailId = tryParseId(String.valueOf(inMap.get('disputeDetailId')));
        }

        return [
            SELECT COUNT()
            FROM celsrm__Dispute_Workflow_Details__c
            WHERE celsrm__Dispute__c = :disputeId
            AND celsrm__Status__c = 'Pending'
            AND Id != :currentDetailId
            AND (celsrm__Workflow_User_Type__c = null OR celsrm__Workflow_User_Type__c != 'Resolver')
        ] > 0;
    }

    //-- Starts | FIN-9786 | Changed by Asera | 24-Jun-2026 --//
    private static void completeParallelResolverPhase(Map<Object, Object> inMap, celsrm__Dispute__c dispObj) {
        if (dispObj == null || dispObj.Id == null) {
            return;
        }

        applyFinalActionUserMasterToDispute(dispObj, inMap);
        Id matrixId = getParallelWorkflowMatrixId(inMap, dispObj.Id);
        if (matrixId == null) {
            dispObj.celsrm__Workflow_Matrix_Id__c = null;
            dispObj.celsrm__Status__c = 'Approved';
            dispObj.celsrm__Close_Date__c = Date.Today();
            return;
        }

        dispObj.celsrm__Workflow_Matrix_Id__c = matrixId;
        String parallelMode = getParallelWorkflowAggregationMode();
        if (parallelMode == 'All' && hasRequiredPendingResolverWorkflowDetails(dispObj.Id, inMap)) {
            return;
        }

        DisputeApprovalProcessController.skipPendingResolverWorkflowDetails(
            dispObj.Id,
            getCurrentWorkflowDetailId(inMap)
        );
        List<Id> approverDetailIds = DisputeApprovalProcessController.insertParallelApproverDetailsIfMissing(
            dispObj.Id,
            matrixId
        );
        if (!approverDetailIds.isEmpty() || hasPendingApproverWorkflowDetails(dispObj.Id, inMap)) {
            dispObj.celsrm__Status__c = 'Pending Approval';
            return;
        }

        dispObj.celsrm__Workflow_Matrix_Id__c = null;
        dispObj.celsrm__Status__c = 'Approved';
        dispObj.celsrm__Close_Date__c = Date.Today();
    }

    private static String getParallelWorkflowAggregationMode() {
        celsrm__Dispute_Configuration__c config = celsrm__Dispute_Configuration__c.getOrgDefaults();
        return DisputeApprovalProcessController.normalizeParallelApprovalMode(
            config == null ? null : config.celsrm__Parallel_Approval_Mode__c
        );
    }

    private static Boolean hasRequiredPendingResolverWorkflowDetails(Id disputeId, Map<Object, Object> inMap) {
        if (disputeId == null) {
            return false;
        }

        Id currentDetailId = getCurrentWorkflowDetailId(inMap);
        return [
            SELECT COUNT()
            FROM celsrm__Dispute_Workflow_Details__c
            WHERE celsrm__Dispute__c = :disputeId
            AND celsrm__Status__c = 'Pending'
            AND Id != :currentDetailId
            AND celsrm__Is_Optional__c != true
            AND celsrm__Workflow_User_Type__c = 'Resolver'
        ] > 0;
    }

    private static Id getParallelWorkflowMatrixId(Map<Object, Object> inMap, Id disputeId) {
        Id matrixId = inMap != null && inMap.get('disputeMatrixId') != null
            ? tryParseId(String.valueOf(inMap.get('disputeMatrixId')))
            : null;
        if (matrixId != null || disputeId == null) {
            return matrixId;
        }

        List<celsrm__Dispute__c> disputes = [
            SELECT celsrm__Workflow_Matrix_Id__c
            FROM celsrm__Dispute__c
            WHERE Id = :disputeId
            LIMIT 1
        ];
        return disputes.isEmpty() ? null : disputes[0].celsrm__Workflow_Matrix_Id__c;
    }

    private static Id getCurrentWorkflowDetailId(Map<Object, Object> inMap) {
        return inMap != null && inMap.get('disputeDetailId') != null
            ? tryParseId(String.valueOf(inMap.get('disputeDetailId')))
            : null;
    }
    //-- Ends | FIN-9786 | Changed by Asera | 24-Jun-2026 --//

    private static void progressWorkflowAfterResolverHandoff(
        Map<Object, Object> inMap,
        Id disputeId,
        String disputeMatrixId
    ) {
        if (disputeId == null || String.isBlank(disputeMatrixId)) {
            return;
        }

        if (!isMatrixApprovalWorkflowEnabled()) {
            insertDisputeWorkflowDetails(String.valueOf(disputeId), disputeMatrixId, getNextResolverApproverId(inMap));
            return;
        }

        Id matrixId = Id.valueOf(disputeMatrixId);
        Integer completedLevel = getCompletedWorkflowLevel(inMap);
        celsrm__Dispute_Configuration__c config = celsrm__Dispute_Configuration__c.getOrgDefaults();
        String flowType = config == null ? null : config.celsrm__Dispute_Workflow_Matrix_Flow_Type__c;

        if (DisputeApprovalProcessController.isSequentialFlow(flowType)) {
            DisputeApprovalProcessController.insertNextLevelDetailsIfMissing(disputeId, matrixId, completedLevel);
            return;
        }

        NextWorkflowStep nextStep = findNextActiveWorkflowStep(matrixId, completedLevel);
        if (nextStep != null && nextStep.assignment != null) {
            DisputeApprovalProcessController.insertWorkflowDetailIfMissing(
                disputeId,
                matrixId,
                nextStep.assignment
            );
        }
    }

//-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
    //-- Starts : Update Dispute Workflow Detail --//
    public static void updateDisputeWorkflowDetails(String disputeDetailId, String userAction) {
        //-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
        celsrm__Dispute_Workflow_Details__c dwdUpdObj = new celsrm__Dispute_Workflow_Details__c();
        //-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
        dwdUpdObj.Id = disputeDetailId;
        //-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
        dwdUpdObj.celsrm__Status__c = 'Completed';
        dwdUpdObj.celsrm__User_Action__c = userAction;
        dwdUpdObj.celsrm__Action_Date__c = Date.today();
        dwdUpdObj.celsrm__Action_Taken_By__c = UserInfo.getUserId();
        //-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
        update dwdUpdObj;
    }

    private static void updateRejectedDisputeWorkflowDetail(String disputeDetailId, String userAction) {
        Id workflowDetailId = tryParseId(disputeDetailId);
        if (workflowDetailId == null) {
            return;
        }

        celsrm__Dispute_Workflow_Details__c dwdUpdObj = new celsrm__Dispute_Workflow_Details__c();
        dwdUpdObj.Id = workflowDetailId;
        dwdUpdObj.celsrm__Status__c = 'Rejected';
        dwdUpdObj.celsrm__User_Action__c = userAction;
        dwdUpdObj.celsrm__Action_Date__c = Date.today();
        dwdUpdObj.celsrm__Action_Taken_By__c = UserInfo.getUserId();
        update dwdUpdObj;
    }

    private static void rejectRemainingPendingWorkflowDetails(Id disputeId, String currentDetailIdValue) {
        if (disputeId == null) {
            return;
        }

        Id currentDetailId = tryParseId(currentDetailIdValue);
        List<celsrm__Dispute_Workflow_Details__c> pendingToReject = [
            SELECT Id
            FROM celsrm__Dispute_Workflow_Details__c
            WHERE celsrm__Dispute__c = :disputeId
            AND celsrm__Status__c = 'Pending'
            AND Id != :currentDetailId
        ];
        for (celsrm__Dispute_Workflow_Details__c workflowDetail : pendingToReject) {
            workflowDetail.celsrm__Status__c = 'Rejected';
            workflowDetail.celsrm__User_Action__c = 'Revoked Due To Rejection';
            workflowDetail.celsrm__Action_Date__c = Date.today();
            workflowDetail.celsrm__Action_Taken_By__c = UserInfo.getUserId();
        }
        if (!pendingToReject.isEmpty()) {
            update pendingToReject;
        }
    }
    //-- Ends : Update Dispute Workflow Detail --//

    //-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
    private class NextWorkflowStep {
        public Id matrixId;
        public DisputeApprovalProcessController.LevelAssignment assignment;
        public celsrm__User_Master__c userMaster;
    }

    private static void populateNextWorkflowStep(Map<Object, Object> inMap, celsrm__Dispute_Workflow_Details__c currentDetail) {
        Id matrixId = currentDetail == null ? null : currentDetail.celsrm__Dispute_Workflow_Matrix__c;
        if (matrixId == null) {
            inMap.put('isLastApprover', 'true');
            return;
        }

        //-- Starts | FIN-9786 | Changed by Asera | 24-Jun-2026 --//
        NextWorkflowStep nextStep;
        if (isParallelMatrixWorkflowEnabled()) {
            nextStep = findNextPendingWorkflowStep(
                currentDetail.celsrm__Dispute__c,
                matrixId,
                currentDetail.Id,
                null
            );
        } else {
            Integer currentLevel = getWorkflowDetailLevel(currentDetail);
            nextStep = findNextActiveWorkflowStep(matrixId, currentLevel);
        }
        //-- Ends | FIN-9786 | Changed by Asera | 24-Jun-2026 --//
        if (nextStep == null) {
            inMap.put('isLastApprover', 'true');
            return;
        }

        //-- Starts | FIN-9786 | Changed by Asera | 24-Jun-2026 --//
        applyNextWorkflowStepToInput(inMap, nextStep, matrixId);
        //-- Ends | FIN-9786 | Changed by Asera | 24-Jun-2026 --//
    }

    //-- Starts | FIN-9786 | Changed by Asera | 24-Jun-2026 --//
    private static void refreshParallelPendingApproverStep(Map<Object, Object> inMap, celsrm__Dispute__c dispObj) {
        if (dispObj == null || dispObj.Id == null) {
            return;
        }

        Id matrixId = getParallelWorkflowMatrixId(inMap, dispObj.Id);
        NextWorkflowStep nextStep = findNextPendingWorkflowStep(
            dispObj.Id,
            matrixId,
            getCurrentWorkflowDetailId(inMap),
            'Approver'
        );
        if (nextStep == null) {
            inMap.put('isLastApprover', 'true');
            inMap.remove('nextResolverApprover');
            return;
        }

        inMap.put('isLastApprover', 'false');
        applyNextWorkflowStepToInput(inMap, nextStep, matrixId);
    }

    private static void applyNextWorkflowStepToInput(
        Map<Object, Object> inMap,
        NextWorkflowStep nextStep,
        Id matrixId
    ) {
        if (inMap == null || nextStep == null || nextStep.assignment == null) {
            return;
        }
        inMap.put(
            'resolverApproverType',
            isResolverUserType(nextStep.assignment.userType) ? 'Resolver' : 'Approver'
        );
        inMap.put('resolverIsOptional', nextStep.assignment.isOptional == true ? 'true' : 'false');
        inMap.put('disputeMatrixId', String.valueOf(matrixId));
        inMap.put('nextResolverApprover', buildNextResolverApproverMap(nextStep.userMaster));
    }

    private static NextWorkflowStep findNextPendingWorkflowStep(
        Id disputeId,
        Id matrixId,
        Id currentDetailId,
        String workflowUserType
    ) {
        if (disputeId == null || matrixId == null) {
            return null;
        }

        List<celsrm__Dispute_Workflow_Details__c> pendingDetails;
        if (String.isBlank(workflowUserType)) {
            pendingDetails = [
                SELECT Id, celsrm__Workflow_Level__c, celsrm__Workflow_User_Type__c,
                       celsrm__Dispute_Workflow_Matrix__c, celsrm__User_Master__c,
                       celsrm__User_Master__r.Name, celsrm__User_Master__r.celsrm__Email__c,
                       celsrm__User_Master__r.celsrm__User__c,
                       celsrm__User_Master__r.celsrm__Is_External_User__c,
                       celsrm__Queue__c, celsrm__Is_Optional__c, celsrm__User_SLA_Days__c
                FROM celsrm__Dispute_Workflow_Details__c
                WHERE celsrm__Dispute__c = :disputeId
                AND celsrm__Dispute_Workflow_Matrix__c = :matrixId
                AND celsrm__Status__c = 'Pending'
                AND Id != :currentDetailId
                ORDER BY celsrm__Workflow_Level__c ASC NULLS LAST, CreatedDate ASC
                LIMIT 1
            ];
        } else {
            pendingDetails = [
                SELECT Id, celsrm__Workflow_Level__c, celsrm__Workflow_User_Type__c,
                       celsrm__Dispute_Workflow_Matrix__c, celsrm__User_Master__c,
                       celsrm__User_Master__r.Name, celsrm__User_Master__r.celsrm__Email__c,
                       celsrm__User_Master__r.celsrm__User__c,
                       celsrm__User_Master__r.celsrm__Is_External_User__c,
                       celsrm__Queue__c, celsrm__Is_Optional__c, celsrm__User_SLA_Days__c
                FROM celsrm__Dispute_Workflow_Details__c
                WHERE celsrm__Dispute__c = :disputeId
                AND celsrm__Dispute_Workflow_Matrix__c = :matrixId
                AND celsrm__Status__c = 'Pending'
                AND Id != :currentDetailId
                AND celsrm__Workflow_User_Type__c = :workflowUserType
                ORDER BY celsrm__Workflow_Level__c ASC NULLS LAST, CreatedDate ASC
                LIMIT 1
            ];
        }
        return pendingDetails.isEmpty() ? null : buildNextWorkflowStepFromDetail(pendingDetails[0], matrixId);
    }

    private static NextWorkflowStep buildNextWorkflowStepFromDetail(
        celsrm__Dispute_Workflow_Details__c pendingDetail,
        Id matrixId
    ) {
        if (pendingDetail == null || pendingDetail.celsrm__User_Master__c == null) {
            return null;
        }

        DisputeApprovalProcessController.LevelAssignment assignment =
            new DisputeApprovalProcessController.LevelAssignment();
        assignment.level = getWorkflowDetailLevel(pendingDetail);
        assignment.userMasterId = pendingDetail.celsrm__User_Master__c;
        assignment.queueId = pendingDetail.celsrm__Queue__c;
        assignment.isOptional = pendingDetail.celsrm__Is_Optional__c;
        assignment.userType = pendingDetail.celsrm__Workflow_User_Type__c;
        assignment.slDays = pendingDetail.celsrm__User_SLA_Days__c;

        NextWorkflowStep nextStep = new NextWorkflowStep();
        nextStep.matrixId = matrixId;
        nextStep.assignment = assignment;
        nextStep.userMaster = pendingDetail.celsrm__User_Master__r;
        return nextStep;
    }
    //-- Ends | FIN-9786 | Changed by Asera | 24-Jun-2026 --//

    private static NextWorkflowStep findNextActiveWorkflowStep(Id matrixId, Integer currentLevel) {
        if (matrixId == null) {
            return null;
        }

        List<DisputeApprovalProcessController.LevelAssignment> assignments = loadMatrixAssignments(matrixId);
        if (assignments.isEmpty()) {
            return null;
        }

        Integer nextLevel = null;
        for (DisputeApprovalProcessController.LevelAssignment assignment : assignments) {
            if (assignment.level == null) {
                continue;
            }
            if (currentLevel != null && assignment.level <= currentLevel) {
                continue;
            }
            if (nextLevel == null || assignment.level < nextLevel) {
                nextLevel = assignment.level;
            }
        }
        if (nextLevel == null) {
            return null;
        }

        Set<Id> userMasterIds = new Set<Id>();
        for (DisputeApprovalProcessController.LevelAssignment assignment : assignments) {
            if (assignment.level == nextLevel && assignment.userMasterId != null) {
                userMasterIds.add(assignment.userMasterId);
            }
        }
        if (userMasterIds.isEmpty()) {
            return null;
        }

        Map<Id, celsrm__User_Master__c> userMastersById = loadUserMastersById(userMasterIds);
        for (DisputeApprovalProcessController.LevelAssignment assignment : assignments) {
            if (assignment.level != nextLevel || assignment.userMasterId == null) {
                continue;
            }
            celsrm__User_Master__c userMaster = userMastersById.get(assignment.userMasterId);
            if (userMaster == null) {
                continue;
            }
            NextWorkflowStep nextStep = new NextWorkflowStep();
            nextStep.matrixId = matrixId;
            nextStep.assignment = assignment;
            nextStep.userMaster = userMaster;
            return nextStep;
        }
        return null;
    }

    private static NextWorkflowStep findHighestLevelApproverStep(Id matrixId) {
        if (matrixId == null) {
            return null;
        }

        List<DisputeApprovalProcessController.LevelAssignment> assignments = loadMatrixAssignments(matrixId);
        Integer highestApproverLevel = null;
        for (DisputeApprovalProcessController.LevelAssignment assignment : assignments) {
            if (assignment.userMasterId == null || !isApproverUserType(assignment.userType)) {
                continue;
            }
            if (highestApproverLevel == null || assignment.level > highestApproverLevel) {
                highestApproverLevel = assignment.level;
            }
        }
        if (highestApproverLevel == null) {
            return null;
        }

        Set<Id> userMasterIds = new Set<Id>();
        for (DisputeApprovalProcessController.LevelAssignment assignment : assignments) {
            if (assignment.level == highestApproverLevel && assignment.userMasterId != null &&
                isApproverUserType(assignment.userType)) {
                userMasterIds.add(assignment.userMasterId);
            }
        }
        Map<Id, celsrm__User_Master__c> userMastersById = loadUserMastersById(userMasterIds);
        for (DisputeApprovalProcessController.LevelAssignment assignment : assignments) {
            if (assignment.level != highestApproverLevel || assignment.userMasterId == null ||
                !isApproverUserType(assignment.userType)) {
                continue;
            }
            celsrm__User_Master__c userMaster = userMastersById.get(assignment.userMasterId);
            if (userMaster == null) {
                continue;
            }
            NextWorkflowStep nextStep = new NextWorkflowStep();
            nextStep.matrixId = matrixId;
            nextStep.assignment = assignment;
            nextStep.userMaster = userMaster;
            return nextStep;
        }
        return null;
    }

    private static List<DisputeApprovalProcessController.LevelAssignment> loadMatrixAssignments(Id matrixId) {
        List<celsrm__Dispute_Workflow_Matrix__c> matrixRows = [
            SELECT Id, celsrm__Approval_Matrices__c
            FROM celsrm__Dispute_Workflow_Matrix__c
            WHERE Id = :matrixId
            LIMIT 1
        ];
        if (matrixRows.isEmpty() || String.isBlank(matrixRows[0].celsrm__Approval_Matrices__c)) {
            return new List<DisputeApprovalProcessController.LevelAssignment>();
        }
        return DisputeApprovalProcessController.extractAllLevelAssignments(matrixRows[0].celsrm__Approval_Matrices__c);
    }

    private static Map<Id, celsrm__User_Master__c> loadUserMastersById(Set<Id> userMasterIds) {
        Map<Id, celsrm__User_Master__c> userMastersById = new Map<Id, celsrm__User_Master__c>();
        if (userMasterIds == null || userMasterIds.isEmpty()) {
            return userMastersById;
        }
        for (celsrm__User_Master__c userMaster : [
            SELECT Id, Name, celsrm__Email__c, celsrm__User__c, celsrm__Is_External_User__c
            FROM celsrm__User_Master__c
            WHERE Id IN :userMasterIds
        ]) {
            userMastersById.put(userMaster.Id, userMaster);
        }
        return userMastersById;
    }

    private static Map<Object, Object> buildNextResolverApproverMap(celsrm__User_Master__c userMaster) {
        Map<Object, Object> raUserObject = new Map<Object, Object>();
        if (userMaster == null) {
            return raUserObject;
        }
        raUserObject.put('id', userMaster.Id);
        raUserObject.put('userMasterId', userMaster.Id);
        raUserObject.put('userId', userMaster.celsrm__User__c);
        raUserObject.put('email', userMaster.celsrm__Email__c);
        raUserObject.put('isExternalUser', userMaster.celsrm__Is_External_User__c == true);
        raUserObject.put('name', userMaster.Name);
        return raUserObject;
    }

    private static Integer getWorkflowDetailLevel(celsrm__Dispute_Workflow_Details__c detailRow) {
        if (detailRow == null) {
            return null;
        }
        if (detailRow.celsrm__Workflow_Level__c != null) {
            return detailRow.celsrm__Workflow_Level__c.intValue();
        }
        // if (detailRow. != null) {
        //     return detailRow.Level__c.intValue();
        // }
        return null;
    }

    private static Boolean isResolverUserType(String userType) {
        return String.isNotBlank(userType) && userType.trim().equalsIgnoreCase('resolver');
    }

    private static Boolean isApproverUserType(String userType) {
        return String.isNotBlank(userType) && userType.trim().equalsIgnoreCase('approver');
    }

    //-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
    //-- Starts |FIN-7502| Changed by Asera | 25 Nov 2025 --//
    private static Map<String, String> insertActivity(List<String> idSet, String objectName, String activityName, DateTime eventTime, Integer sorting, String note, String userId, String metadata, String sourceSystem, Map<String, Object> additionalFields) {
        System.debug('into insertActivity of UpdateDisputeController');
        String namespace = 'celsrm__';
        List<SObject> recordsToUpdate = new List<SObject>();
        Map<String, String> returnMap = new Map<String, String>();
        if(idSet != null && idSet.size() > 0){
            List<celsrm__Celonis_Event__c> activityList = new List<celsrm__Celonis_Event__c>();
            celsrm__Celonis_Event__c activity = new celsrm__Celonis_Event__c();
            for (String recordId : idSet) {
                activity = new celsrm__Celonis_Event__c();
                activity.put(objectName, recordId);
                if(objectName != null && objectName == namespace + 'Account__c') {
                    Account record = new Account();
                    record.Id =  recordId;
                    record.celsrm__Last_Contact_Date__c = eventTime != null ? Date.valueOf(eventTime) : Date.today();
                    record.celsrm__Last_Contact_Method__c = activityName;
                    recordsToUpdate.add(record);
                }
                if(objectName != null && objectName == namespace + 'Transaction__c') {
                    celsrm__Transaction__c record = new celsrm__Transaction__c();
                    record.Id =  recordId;
                    record.celsrm__Last_Contact_Date__c = eventTime != null ? Date.valueOf(eventTime) : Date.today();
                    record.celsrm__Last_Contacted_By__c = userId != null ? userId : UserInfo.getUserId();
                    recordsToUpdate.add(record);
                }
                if(objectName != null && objectName == namespace + 'Dispute__c') {
                    celsrm__Dispute__c record = new celsrm__Dispute__c();
                    record.Id =  recordId;
                    record.celsrm__Last_Contact_Date__c = eventTime != null ? Date.valueOf(eventTime) : Date.today();
                    record.celsrm__Last_Contacted_By__c = userId != null ? userId : UserInfo.getUserId();
                    recordsToUpdate.add(record);
                }
                String eventID = 'E-'+String.valueOf(Datetime.now().getTime()).substring(5, 13) + (Math.abs(Crypto.getRandomInteger()) / 100);
                activity.celsrm__Activity_Id__c = eventID;
                activity.celsrm__Event_ID__c = eventID;
                activity.Name = activityName;
                activity.celsrm__Event_Time__c = eventTime != null ? eventTime : DateTime.now();
                activity.celsrm__Metadata__c = metadata;
                activity.celsrm__Note__c = note;
                activity.celsrm__Sorting__c = sorting;
                activity.celsrm__Source_System__c = sourceSystem;
                activity.celsrm__User__c = userId != null ? userId : UserInfo.getUserId();
                activity.celsrm__Has_Note__c = note != null && note != '' ? true : false;
                if(additionalFields != null) {
                    for (String fieldName : additionalFields.keySet()) {
                        activity.put(fieldName, additionalFields.get(fieldName));
                    }
                }
                activityList.add(activity);
                
            }
            //-- Start | FIN-6402 | Changed by Dilshad | 23-Sep-2024 --//
            List<String> fieldNameList = new List<String>();
            for(String fieldName: activity.getPopulatedFieldsAsMap().keySet()) {
                fieldName = !fieldName.startsWithIgnoreCase(namespace) && fieldName.endsWithIgnoreCase('__c')  ? namespace + fieldName : fieldName;
                fieldNameList.add(fieldName);
            }
            System.debug('fieldNameList-->' + fieldNameList);
            if(celsrm.GOGSecurityController.isCreateable(namespace + 'Celonis_Event__c', String.join(fieldNameList,','))) {
                insert activityList;
            }
            //-- Ends | FIN-6402 | Changed by Dilshad | 23-Sep-2024 --//
            for (celsrm__Celonis_Event__c activityObj : activityList) {
                returnMap.put(String.valueOf(activityObj.get(objectName)), activityObj.Id);
            }
        } 
        if(!recordsToUpdate.isEmpty()){
            update recordsToUpdate;
        }
        System.debug('<<< activity inserted >>>');
        return returnMap;
    }
    //-- End |FIN-7502| Changed by Asera | 25 Nov 2025 --//
//-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
}
//-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//