@RestResource(urlMapping='/DisputeApprovalService/*')
global with sharing class DisputeApprovalService {
    @HttpPost
    //-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
    global static String processDisputeAction() {
        RestRequest request = RestContext.request;
        String body = request.requestBody == null ? null : request.requestBody.toString();
        if (String.isBlank(body)) {
            return 'Request body is required.';
        }
        Map<String, Object> bodyMap = (Map<String, Object>) JSON.deserializeUntyped(body);
        String action = bodyMap.get('action') == null ? null : String.valueOf(bodyMap.get('action'));
        String recordId = bodyMap.get('recordId') == null ? null : String.valueOf(bodyMap.get('recordId'));
        String userMasterIdParam = bodyMap.get('userMasterId') == null ? null : String.valueOf(bodyMap.get('userMasterId'));
        String workflowDetailIdParam = bodyMap.get('workflowDetailId') == null ? null : String.valueOf(bodyMap.get('workflowDetailId'));
        String note = bodyMap.get('note') == null ? null : String.valueOf(bodyMap.get('note'));


        if (String.isBlank(action) || String.isBlank(recordId)) {
            return 'Required data are missing. Please check with admin.';
        }
        
        Id disputeId;
        try {
            
            disputeId = (Id) recordId.trim();
        } catch (Exception ex) {
            return 'Invalid dispute record Id.';
        }
        Id userMasterId;
        if (String.isNotBlank(userMasterIdParam)) {
            try {
                userMasterId = (Id) userMasterIdParam.trim();
            } catch (Exception ex) {
                return 'Invalid user master Id.';
            }
        }
        Id workflowDetailId;
        if (String.isNotBlank(workflowDetailIdParam)) {
            try {
                workflowDetailId = (Id) workflowDetailIdParam.trim();
            } catch (Exception ex) {
                return 'Invalid workflow detail Id.';
            }
        }
        try {
            return DisputeApprovalActionService.processApprovalAction(disputeId, action, userMasterId, workflowDetailId, note);
        } catch (Exception ex) {
            System.debug(
                'Error processing dispute approval action: ' +
                ex.getMessage() +
                ' Stacktrace: ' +
                ex.getStackTraceString()
            );
            return ex.getMessage();
        
        }
    }
}
//-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//