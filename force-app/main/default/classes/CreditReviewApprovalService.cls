@RestResource(urlMapping='/CreditReviewApprovalService/*')
global with sharing class CreditReviewApprovalService {

    @HttpPost
    global static string processCreditReviewAction() {
        RestRequest request = RestContext.request;
        RestResponse response = RestContext.response;
        String body = request.requestBody.toString();
        System.debug('body:'+body);
        Map<String, Object> bodyMap = (Map<String, Object>) JSON.deserializeUntyped(body);
        String action = String.valueOf(bodyMap.get('action')); // 'Approve' or 'Reject'
        String recordId = String.valueOf(bodyMap.get('recordId'));
        String userMasterIdParam = String.valueOf(bodyMap.get('userMasterId'));
        String note = String.valueOf(bodyMap.get('note'));
        String workflowDetailId = String.valueOf(bodyMap.get('workflowDetailId'));

        try {
            if (String.isBlank(action) || String.isBlank(recordId)) {
                return 'Required data are missing. Please check with admin.';
            }
            List<celsrm__Credit_Review__c> creditReviews = [SELECT Id, Name, celsrm__Status__c FROM celsrm__Credit_Review__c WHERE Id = :recordId];
            if (creditReviews.isEmpty()) {
                System.debug('Credit review not found');
                return 'Credit review not found.';
            }
            celsrm__Credit_Review__c creditReview = creditReviews[0];

            if (creditReview.celsrm__Status__c != 'Pending') {
                String message = 'Credit review already processed. Current status: ' + creditReview.celsrm__Status__c;
                System.debug(message);
                return message;
            }

            Map<Object, Object> inMap = new Map<Object, Object>();
            inMap.put('Id', creditReview.Id);
            String userAction = action.toLowerCase() == 'approve' ? 'approve' : 'reject';
            inMap.put('userAction', userAction.toLowerCase());
            inMap.put('noteBody', note);

            Set<Id> currentUserMasterIds = new Set<Id>();
            Id providedUserMasterId = tryParseId(userMasterIdParam);
            if (providedUserMasterId != null && providedUserMasterId.getSObjectType() == celsrm__User_Master__c.SObjectType) {
                for (celsrm__User_Master__c userMaster : [SELECT Id FROM celsrm__User_Master__c WHERE Id = :providedUserMasterId LIMIT 1]) {
                    currentUserMasterIds.add(userMaster.Id);
                }
            }
            if (currentUserMasterIds.isEmpty()) {
                return 'No user master found for provided userMasterId.';
            }

            inMap.put('currentUserMasterIdsCsv', serializeIdSet(currentUserMasterIds));
            
            Id currentPendingDetail = tryParseId(workflowDetailId);
            if (currentPendingDetail == null) {
                return 'Approval reference data is invalid or missing.';
            }
            inMap.put('creditLimitApprovalDetailId', currentPendingDetail);
            inMap = UpdateCreditReviewController.onPageLoadFunction(inMap);

            if(inMap.get('stopExecution') == true){
                 system.debug('Error: ' + inMap.get('ggErrorMessage'));
                 return 'Error: ' + inMap.get('ggErrorMessage');
            }

            UpdateCreditReviewController.UpdateCreditReview(inMap);
            
            system.debug('Credit review ' + creditReview.Name + ' has been ' + action + 'd successfully.');
            return 'Credit review ' + creditReview.Name + ' has been ' + (action == 'approve' ? 'approve' : 'rejecte') + 'd successfully.';

        } catch (Exception e) {
            System.debug('Error processing credit review action: ' + e.getMessage() + ' Stacktrace: ' + e.getStackTraceString());
            return e.getMessage();
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
}