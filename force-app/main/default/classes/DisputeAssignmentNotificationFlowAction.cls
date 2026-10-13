public with sharing class DisputeAssignmentNotificationFlowAction {
    //-- Start | FIN-9672 | Changed by Ravi | 05 May 2026 --//
    private static Id cachedOrgWideEmailAddressId;
    private static Set<Id> disputeIdsWithAssignmentNotificationSent = new Set<Id>();
    //-- Starts | FIN-9786 | Changed by Asera | 24-Jun-2026 --//
    private static Set<Id> workflowDetailIdsWithAssignmentNotificationSent = new Set<Id>();
    //-- Ends | FIN-9786 | Changed by Asera | 24-Jun-2026 --//
    private static Map<Id, Boolean> workflowDetailExistsByDisputeId = new Map<Id, Boolean>();
    private static final String LEGACY_SENDER_ADDRESS = celsrm__SRM_Configuration__c.getOrgDefaults().Mailbox_Email_Address__c;

    public class Request {
        @InvocableVariable(required=true)
        public Id recordId;
    }

    public class Result {
        @InvocableVariable
        public Id recordId;

        @InvocableVariable
        public String status;

        @InvocableVariable
        public String message;
    }

    @InvocableMethod(label='Send Localized Dispute Assignment Email')
    public static List<Result> sendLocalizedAssignmentEmails(List<Request> requests) {
        List<Result> results = new List<Result>();
        if (requests == null || requests.isEmpty()) {
            return results;
        }

        Set<Id> disputeIds = new Set<Id>();
        for (Request requestItem : requests) {
            if (requestItem != null && requestItem.recordId != null) {
                disputeIds.add(requestItem.recordId);
            }
        }

        Map<Id, celsrm__Dispute__c> disputesById = queryDisputes(disputeIds);
        //-- Start | FIN-9749 | Changed by Asera | 11 May 2026 --//
        Map<Id, String> userTypesByDisputeId = queryUserTypes(disputesById);
        //-- End | FIN-9749 | Changed by Asera | 11 May 2026 --//

        // Flow still decides when an assignment email should fire; this action only resolves the right template and recipient.
        for (Request requestItem : requests) {
            Result resultItem = new Result();
            resultItem.recordId = requestItem != null ? requestItem.recordId : null;
            resultItem.status = 'Skipped';
            resultItem.message = 'No dispute record was provided.';

            if (requestItem == null || requestItem.recordId == null) {
                results.add(resultItem);
                continue;
            }

            celsrm__Dispute__c disputeRecord = disputesById.get(requestItem.recordId);
            if (disputeRecord == null) {
                resultItem.message = 'Dispute record not found.';
                results.add(resultItem);
                continue;
            }
            //-- Starts | FIN-9786 | Changed by Asera | 24-Jun-2026 --//
            if (shouldSkipAssignmentNotification(disputeRecord)) {
                resultItem.message = 'Dispute assignment notification is not required for the current workflow state.';
                results.add(resultItem);
                continue;
            }
            //-- End | FIN-9786 | Changed by Asera | 24-Jun-2026 --//
            DisputeUserMasterService.ResolvedUserInfo resolvedUser = DisputeUserMasterService.resolveFromDisputeRecord(disputeRecord);
            if (resolvedUser == null || String.isBlank(resolvedUser.email)) {
                resultItem.message = 'The dispute does not have a resolver email to notify.';
                results.add(resultItem);
                continue;
            }
            //-- Start | FIN-9749 | Changed by Asera | 11 May 2026 --//
            //-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
            String templateName = resolveAssignmentTemplateName(
                disputeRecord,
                resolvedUser,
                userTypesByDisputeId.get(disputeRecord.Id)
            );
            //-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
            //-- End | FIN-9749 | Changed by Asera | 11 May 2026 --//
            String languageFolder = DisputeEmailLocalizationService.resolveAssignmentLanguage(disputeRecord);
            DisputeEmailLocalizationService.TemplateSelection templateSelection =
                DisputeEmailLocalizationService.resolveTemplate(templateName, languageFolder);

            if (templateSelection == null || templateSelection.templateId == null) {
                resultItem.message = 'No matching email template was found.';
                results.add(resultItem);
                continue;
            }

            Messaging.SingleEmailMessage renderedTemplate = Messaging.renderStoredEmailTemplate(
                templateSelection.templateId,
                null,
                disputeRecord.Id
            );

            //-- Start | FIN-9675 | Changed by Ravi | 07 May 2026 --//
            //-- Starts | FIN-9786 | Changed by Asera | 24-Jun-2026 --//
            Map<Object, Object> returnMap = sendEmailWithMapper(
                resolvedUser.email,
                enrichRenderedTemplateWithApprovalContext(
                    renderedTemplate,
                    disputeRecord.Id,
                    resolvedUser.userMasterId
                ),
                disputeRecord.Id
            );
            if (returnMap != null && returnMap.containsKey(false)) {
                resultItem.status = 'Error';
                resultItem.message = String.valueOf(returnMap.get(false));
            } else {
                resultItem.status = 'Sent';
                resultItem.message = 'Email sent successfully.';
                disputeIdsWithAssignmentNotificationSent.add(disputeRecord.Id);
            }
            //-- End | FIN-9786 | Changed by Asera | 24-Jun-2026 --//
            //-- End | FIN-9675 | Changed by Ravi | 07 May 2026 --//
            results.add(resultItem);
        }

        return results;
    }
    //-- Starts | FIN-9786 | Changed by Asera | 24-Jun-2026 --//
    public static List<Result> sendParallelApprovalEmailsForWorkflowDetails(List<Id> workflowDetailIds) {
        List<Result> results = new List<Result>();
        if (workflowDetailIds == null || workflowDetailIds.isEmpty()) {
            return results;
        }

        Map<Id, celsrm__Dispute_Workflow_Details__c> workflowDetailsById =
            queryWorkflowDetails(new Set<Id>(workflowDetailIds));

        for (Id workflowDetailId : workflowDetailIds) {
            Result resultItem = new Result();
            resultItem.recordId = workflowDetailId;
            resultItem.status = 'Skipped';
            resultItem.message = 'Workflow detail record not found.';

            //-- Starts | FIN-9786 | Changed by Asera | 24-Jun-2026 --//
            if (workflowDetailIdsWithAssignmentNotificationSent.contains(workflowDetailId)) {
                resultItem.message = 'Workflow detail assignee was already notified in this transaction.';
                results.add(resultItem);
                continue;
            }
            //-- Ends | FIN-9786 | Changed by Asera | 24-Jun-2026 --//

            celsrm__Dispute_Workflow_Details__c workflowDetail = workflowDetailsById.get(workflowDetailId);
            if (workflowDetail == null) {
                results.add(resultItem);
                continue;
            }

            if (workflowDetail.celsrm__Status__c != 'Pending') {
                resultItem.message = 'Workflow detail is not pending.';
                results.add(resultItem);
                continue;
            }

            if (isCurrentDisputeAssignment(workflowDetail)
                && disputeIdsWithAssignmentNotificationSent.contains(workflowDetail.celsrm__Dispute__c)
            ) {
                resultItem.message = 'Current dispute assignee was already notified by the dispute assignment flow.';
                results.add(resultItem);
                continue;
            }

            DisputeUserMasterService.ResolvedUserInfo resolvedUser =
                DisputeUserMasterService.resolveFromWorkflowDetailRecord(workflowDetail);
            if (resolvedUser == null || String.isBlank(resolvedUser.email)) {
                resultItem.message = 'The workflow detail does not have an assignee email to notify.';
                results.add(resultItem);
                continue;
            }

            String templateName = resolveWorkflowDetailTemplateName(
                resolvedUser,
                workflowDetail.celsrm__Workflow_User_Type__c
            );
            String languageFolder = DisputeEmailLocalizationService.resolveWorkflowDetailLanguage(
                workflowDetail,
                false
            );
            DisputeEmailLocalizationService.TemplateSelection templateSelection =
                DisputeEmailLocalizationService.resolveTemplate(templateName, languageFolder);

            if (templateSelection == null || templateSelection.templateId == null) {
                resultItem.message = 'No matching email template was found.';
                results.add(resultItem);
                continue;
            }

            Messaging.SingleEmailMessage renderedTemplate = Messaging.renderStoredEmailTemplate(
                templateSelection.templateId,
                null,
                workflowDetail.celsrm__Dispute__c
            );

            Map<Object, Object> returnMap = sendEmailWithMapper(
                resolvedUser.email,
                enrichRenderedTemplateWithApprovalContext(
                    renderedTemplate,
                    workflowDetail.celsrm__Dispute__c,
                    resolvedUser.userMasterId,
                    workflowDetail.Id
                ),
                workflowDetail.celsrm__Dispute__c
            );
            if (returnMap != null && returnMap.containsKey(false)) {
                resultItem.status = 'Error';
                resultItem.message = String.valueOf(returnMap.get(false));
            } else {
                resultItem.status = 'Sent';
                resultItem.message = 'Email sent successfully.';
                //-- Starts | FIN-9786 | Changed by Asera | 24-Jun-2026 --//
                workflowDetailIdsWithAssignmentNotificationSent.add(workflowDetail.Id);
                //-- Ends | FIN-9786 | Changed by Asera | 24-Jun-2026 --//
            }
            results.add(resultItem);
        }

        return results;
    }
    //-- End | FIN-9786 | Changed by Asera | 24-Jun-2026 --//

    //-- Starts | FIN-9786 | Changed by Asera | 24-Jun-2026 --//
    public static void sendParallelApprovalEmailsForInsertedWorkflowDetails(
        List<celsrm__Dispute_Workflow_Details__c> workflowDetails
    ) {
        if (workflowDetails == null || workflowDetails.isEmpty()) {
            return;
        }

        celsrm__Dispute_Configuration__c config = celsrm__Dispute_Configuration__c.getOrgDefaults();
        Boolean isParallelWorkflow = config != null
            && config.celsrm__Use_Dispute_Workflow_Matrix__c == true
            && !DisputeApprovalProcessController.isSequentialFlow(
                config.celsrm__Dispute_Workflow_Matrix_Flow_Type__c
            );
        if (!isParallelWorkflow) {
            return;
        }

        List<Id> workflowDetailIds = new List<Id>();
        for (celsrm__Dispute_Workflow_Details__c workflowDetail : workflowDetails) {
            if (workflowDetail != null
                && workflowDetail.Id != null
                && workflowDetail.celsrm__Status__c == 'Pending'
            ) {
                workflowDetailIds.add(workflowDetail.Id);
            }
        }

        sendParallelApprovalEmailsForWorkflowDetails(workflowDetailIds);
    }
    //-- Ends | FIN-9786 | Changed by Asera | 24-Jun-2026 --//

    // Query fields stay dynamic so the selected localization source can come from dispute, account, or user master.
    private static Map<Id, celsrm__Dispute__c> queryDisputes(Set<Id> disputeIds) {
        Map<Id, celsrm__Dispute__c> disputesById = new Map<Id, celsrm__Dispute__c>();
        if (disputeIds == null || disputeIds.isEmpty()) {
            return disputesById;
        }

        Set<String> selectFields = new Set<String>{
            'Id',
            'Name',
            'celsrm__Status__c',
            'celsrm__Account__c',
            'celsrm__Account__r.Id',
            'celsrm__Account__r.Name',
            'celsrm__Dispute_Type__c',
            'celsrm__Reason_Code__c',
            'celsrm__Amount__c',
            'Invoice_Number__c',
            'Account_Name__c',
            //-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
            'celsrm__Resolver_User_Master__c',
            'celsrm__Resolver_User_Master__r.Name',
            'celsrm__Resolver_User_Master__r.celsrm__Email__c',
            'celsrm__Resolver_User_Master__r.celsrm__User__c',
            'celsrm__Resolver_User_Master__r.celsrm__Is_External_User__c',
            'celsrm__Resolver_User_Master__r.celsrm__Language__c',
            'celsrm__Workflow_Matrix_Id__c'
            //-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
        };
        selectFields.addAll(DisputeEmailLocalizationService.getDisputeAdditionalQueryFields());

        String query = 'SELECT ' + String.join(new List<String>(selectFields), ', ') +
            ' FROM celsrm__Dispute__c WHERE Id IN :disputeIds';
        for (celsrm__Dispute__c disputeRecord : Database.query(query)) {
            disputesById.put(disputeRecord.Id, disputeRecord);
        }
        return disputesById;
    }
    //-- Starts | FIN-9786 | Changed by Asera | 24-Jun-2026 --//
    private static Map<Id, celsrm__Dispute_Workflow_Details__c> queryWorkflowDetails(Set<Id> workflowDetailIds) {
        Map<Id, celsrm__Dispute_Workflow_Details__c> workflowDetailsById =
            new Map<Id, celsrm__Dispute_Workflow_Details__c>();
        if (workflowDetailIds == null || workflowDetailIds.isEmpty()) {
            return workflowDetailsById;
        }

        Set<String> selectFields = new Set<String>{
            'Id',
            'celsrm__Dispute__c',
            'celsrm__Status__c',
            'celsrm__Workflow_User_Type__c',
            'celsrm__User_Master__c',
            'celsrm__User_Master__r.Name',
            'celsrm__User_Master__r.celsrm__Email__c',
            'celsrm__User_Master__r.celsrm__User__c',
            'celsrm__User_Master__r.celsrm__Is_External_User__c',
            'celsrm__User_Master__r.celsrm__Language__c',
            'celsrm__User_Master__r.celsrm__Manager__c',
            'celsrm__User_Master__r.celsrm__Manager__r.Name',
            'celsrm__User_Master__r.celsrm__Manager__r.celsrm__Email__c',
            'celsrm__Dispute__r.Id',
            'celsrm__Dispute__r.celsrm__Status__c',
            'celsrm__Dispute__r.celsrm__Resolver_User_Master__c',
            'celsrm__Dispute__r.celsrm__Workflow_Matrix_Id__c'
        };
        selectFields.addAll(DisputeEmailLocalizationService.getWorkflowDetailAdditionalQueryFields());

        String query = 'SELECT ' + String.join(new List<String>(selectFields), ', ') +
            ' FROM celsrm__Dispute_Workflow_Details__c WHERE Id IN :workflowDetailIds';
        for (celsrm__Dispute_Workflow_Details__c workflowDetail : Database.query(query)) {
            workflowDetailsById.put(workflowDetail.Id, workflowDetail);
        }
        return workflowDetailsById;
    }
    //-- End | FIN-9786 | Changed by Asera | 24-Jun-2026 --//
    //-- Start | FIN-9749 | Changed by Asera | 11 May 2026 --//
    private static Map<Id, String> queryUserTypes(Map<Id, celsrm__Dispute__c> disputesById) {
        Map<Id, String> userTypesByDisputeId = new Map<Id, String>();
        if (disputesById == null || disputesById.isEmpty()) {
            return userTypesByDisputeId;
        }

        Map<Id, Id> matrixIdsByDisputeId = new Map<Id, Id>();
        for (celsrm__Dispute__c disputeRecord : disputesById.values()) {
            //-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
            if (disputeRecord != null && disputeRecord.celsrm__Workflow_Matrix_Id__c != null) {
                matrixIdsByDisputeId.put(disputeRecord.Id, disputeRecord.celsrm__Workflow_Matrix_Id__c);
            //-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
            }
        }

        List<Id> matrixIds = matrixIdsByDisputeId.values();
        Map<Id, celsrm__Dispute_Workflow_Matrix__c> matrixRecordsById = new Map<Id, celsrm__Dispute_Workflow_Matrix__c>([
            SELECT Id, celsrm__User_Type__c
            FROM celsrm__Dispute_Workflow_Matrix__c
            WHERE Id IN :matrixIds
        ]);

        for (Id disputeId : matrixIdsByDisputeId.keySet()) {
            celsrm__Dispute_Workflow_Matrix__c matrixRecord = matrixRecordsById.get(matrixIdsByDisputeId.get(disputeId));
            if (matrixRecord != null) {
                userTypesByDisputeId.put(disputeId, matrixRecord.celsrm__User_Type__c);
            }
        }
        return userTypesByDisputeId;
    }

    private static String resolveAssignmentTemplateName(
        //-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
        celsrm__Dispute__c disputeRecord,
        //-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
        DisputeUserMasterService.ResolvedUserInfo resolvedUser,
        String userType
    ) {
        //-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
        Boolean isApprover = isApproverAssignment(disputeRecord, userType);

        //-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
        if (resolvedUser == null || !resolvedUser.isExternal()) {
            return DisputeEmailLocalizationService.INTERNAL_ASSIGNMENT_TEMPLATE_NAME;
        }

        //-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
        return isApprover
            ? DisputeEmailLocalizationService.EXTERNAL_ASSIGNMENT_TEMPLATE_NAME
            : DisputeEmailLocalizationService.EXTERNAL_RESOLVER_ASSIGNMENT_TEMPLATE_NAME;
        //-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
    }

    //-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//

    private static Boolean isApproverAssignment(celsrm__Dispute__c disputeRecord, String userType) {
        if (disputeRecord != null && disputeRecord.celsrm__Status__c == 'Pending Approval') {
            return true;
        }
        if (disputeRecord != null && disputeRecord.celsrm__Status__c != null
            && disputeRecord.celsrm__Status__c.contains('In Progress')) {
            return false;
        }
        return !'resolver'.equalsIgnoreCase(userType);
    }
    //-- Starts | FIN-9786 | Changed by Asera | 24-Jun-2026 --//
    private static String resolveWorkflowDetailTemplateName(
        DisputeUserMasterService.ResolvedUserInfo resolvedUser,
        String userType
    ) {
        if (resolvedUser == null || !resolvedUser.isExternal()) {
            return DisputeEmailLocalizationService.INTERNAL_ASSIGNMENT_TEMPLATE_NAME;
        }
        return 'resolver'.equalsIgnoreCase(userType)
            ? DisputeEmailLocalizationService.EXTERNAL_RESOLVER_ASSIGNMENT_TEMPLATE_NAME
            : DisputeEmailLocalizationService.EXTERNAL_ASSIGNMENT_TEMPLATE_NAME;
    }

    private static Boolean shouldSkipAssignmentNotification(celsrm__Dispute__c disputeRecord) {
        if (isParallelWorkflowAssignment(disputeRecord)) {
            return true;
        }
        return shouldSkipCompletedWorkflowAssigneeNotification(disputeRecord);
    }

    private static Boolean isParallelWorkflowAssignment(celsrm__Dispute__c disputeRecord) {
        if (disputeRecord == null) {
            return false;
        }

        celsrm__Dispute_Configuration__c config = celsrm__Dispute_Configuration__c.getOrgDefaults();
        Boolean isParallelWorkflow = config != null
            && config.celsrm__Use_Dispute_Workflow_Matrix__c == true
            && !DisputeApprovalProcessController.isSequentialFlow(
                config.celsrm__Dispute_Workflow_Matrix_Flow_Type__c
            );
        return isParallelWorkflow
            && (disputeRecord.celsrm__Workflow_Matrix_Id__c != null || hasWorkflowDetails(disputeRecord.Id));
    }

    private static Boolean hasWorkflowDetails(Id disputeId) {
        if (disputeId == null) {
            return false;
        }
        if (!workflowDetailExistsByDisputeId.containsKey(disputeId)) {
            workflowDetailExistsByDisputeId.put(disputeId, [
                SELECT COUNT()
                FROM celsrm__Dispute_Workflow_Details__c
                WHERE celsrm__Dispute__c = :disputeId
            ] > 0);
        }
        return workflowDetailExistsByDisputeId.get(disputeId);
    }

    private static Boolean isCurrentDisputeAssignment(celsrm__Dispute_Workflow_Details__c workflowDetail) {
        return workflowDetail != null
            && workflowDetail.celsrm__User_Master__c != null
            && workflowDetail.celsrm__Dispute__r != null
            && workflowDetail.celsrm__Dispute__r.celsrm__Resolver_User_Master__c == workflowDetail.celsrm__User_Master__c;
    }

    private static Boolean shouldSkipCompletedWorkflowAssigneeNotification(celsrm__Dispute__c disputeRecord) {
        if (disputeRecord == null
            || disputeRecord.celsrm__Workflow_Matrix_Id__c == null
            || disputeRecord.celsrm__Resolver_User_Master__c == null
        ) {
            return false;
        }

        //-- Starts | FIN-9786 | Changed by Asera | 24-Jun-2026 --//
        if (!hasWorkflowDetails(disputeRecord.Id)) {
            return false;
        }
        //-- Ends | FIN-9786 | Changed by Asera | 24-Jun-2026 --//

        return [
            SELECT COUNT()
            FROM celsrm__Dispute_Workflow_Details__c
            WHERE celsrm__Dispute__c = :disputeRecord.Id
            AND celsrm__User_Master__c = :disputeRecord.celsrm__Resolver_User_Master__c
            AND celsrm__Status__c = 'Pending'
        ] == 0;
    }
    //-- End | FIN-9786 | Changed by Asera | 24-Jun-2026 --//


    //-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
    //-- End | FIN-9749 | Changed by Asera | 11 May 2026 --//

    private static Id getOrgWideEmailAddressId() {
        if (cachedOrgWideEmailAddressId != null) {
            return cachedOrgWideEmailAddressId;
        }

        List<OrgWideEmailAddress> orgWideEmailAddresses = [
            SELECT Id
            FROM OrgWideEmailAddress
            WHERE Address = :LEGACY_SENDER_ADDRESS
            LIMIT 1
        ];
        cachedOrgWideEmailAddressId = orgWideEmailAddresses.isEmpty() ? null : orgWideEmailAddresses[0].Id;
        return cachedOrgWideEmailAddressId;
    }
    //-- Starts | FIN-9786 | Changed by Asera | 24-Jun-2026 --//
    private static Messaging.SingleEmailMessage enrichRenderedTemplateWithApprovalContext(
        Messaging.SingleEmailMessage renderedTemplate,
        Id disputeId,
        Id userMasterId
    ) {
        if (renderedTemplate == null || disputeId == null || userMasterId == null) {
            return renderedTemplate;
        }

        Id workflowDetailId = getPendingWorkflowDetailId(disputeId, userMasterId);
        //-- Starts | FIN-9786 | Changed by Asera | 24-Jun-2026 --//
        return enrichRenderedTemplateWithApprovalContext(
            renderedTemplate,
            disputeId,
            userMasterId,
            workflowDetailId
        );
        //-- Ends | FIN-9786 | Changed by Asera | 24-Jun-2026 --//
    }

    private static Messaging.SingleEmailMessage enrichRenderedTemplateWithApprovalContext(
        Messaging.SingleEmailMessage renderedTemplate,
        Id disputeId,
        Id userMasterId,
        Id workflowDetailId
    ) {
        //-- Starts | FIN-9786 | Changed by Asera | 24-Jun-2026 --//
        if (renderedTemplate == null || disputeId == null || userMasterId == null) {
            return renderedTemplate;
        }
        //-- Ends | FIN-9786 | Changed by Asera | 24-Jun-2026 --//

        renderedTemplate.setHtmlBody(enrichBodyWithApprovalContext(
            renderedTemplate.getHtmlBody(),
            userMasterId,
            workflowDetailId
        ));
        return renderedTemplate;
    }

    private static Id getPendingWorkflowDetailId(Id disputeId, Id userMasterId) {
        List<celsrm__Dispute_Workflow_Details__c> workflowDetails = [
            SELECT Id
            FROM celsrm__Dispute_Workflow_Details__c
            WHERE celsrm__Dispute__c = :disputeId
            AND celsrm__User_Master__c = :userMasterId
            AND celsrm__Status__c = 'Pending'
            ORDER BY celsrm__Workflow_Level__c ASC NULLS LAST, CreatedDate ASC
            LIMIT 1
        ];
        return workflowDetails.isEmpty() ? null : workflowDetails[0].Id;
    }

    private static String enrichBodyWithApprovalContext(String body, Id userMasterId, Id workflowDetailId) {
        if (String.isBlank(body)) {
            return body;
        }

        String output = removeHiddenInput(body, 'userMasterId');
        output = removeHiddenInput(output, 'workflowDetailId');
        //-- Starts | FIN-9786 | Changed by Asera | 24-Jun-2026 --//
        String hiddenInputs =
            '<input type="hidden" name="userMasterId" value="' + String.valueOf(userMasterId) + '" />';
        if (workflowDetailId != null) {
            hiddenInputs =
                '<input type="hidden" name="workflowDetailId" value="' + String.valueOf(workflowDetailId) + '" />' +
                hiddenInputs;
        }
        //-- Ends | FIN-9786 | Changed by Asera | 24-Jun-2026 --//

        if (output.contains('</form>')) {
            return output.replace('</form>', hiddenInputs + '</form>');
        }
        return output + hiddenInputs;
    }

    private static String removeHiddenInput(String body, String inputName) {
        if (String.isBlank(body) || String.isBlank(inputName)) {
            return body;
        }
        return body.replaceAll(
            '<input\\s+[^>]*name="' + inputName + '"[^>]*>',
            ''
        );
    }
    //-- End | FIN-9786 | Changed by Asera | 24-Jun-2026 --//

    //-- Start | FIN-9675 | Changed by Ravi | 07 May 2026 --//
    private static Map<Object, Object> sendEmailWithMapper(
        String recipientEmail,
        Messaging.SingleEmailMessage renderedTemplate,
        Id parentId
    ) {
        try {
            celsrm.GOGEmailMapper.SendEmailBean emailBean = new celsrm.GOGEmailMapper.SendEmailBean();
            emailBean.owea = getOrgWideEmailAddressId();
            emailBean.to = new List<String>{ recipientEmail };
            emailBean.subject = renderedTemplate.getSubject();
            emailBean.htmlBody = renderedTemplate.getHtmlBody();
            emailBean.plainTextBody = renderedTemplate.getPlainTextBody();
            emailBean.cc = null;
            emailBean.bcc = null;
            emailBean.attachment = null;
            emailBean.parentId = parentId;
            emailBean.followUpTaskDueDate = null;
            return celsrm.GOGEmailMapper.sendEmailWithBean(emailBean);
        } catch (Exception exceptionObject) {
            return new Map<Object, Object>{ false => exceptionObject.getMessage() };
        }
    }
    //-- End | FIN-9675 | Changed by Ravi | 07 May 2026 --//
    //-- End | FIN-9672 | Changed by Ravi | 05 May 2026 --//
}