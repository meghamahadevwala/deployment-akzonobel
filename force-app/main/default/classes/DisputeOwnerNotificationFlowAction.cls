public with sharing class DisputeOwnerNotificationFlowAction {
    //-- Start | FIN-9672 | Changed by Ravi | 05 May 2026 --//
    private static final String NOTIFICATION_APPROVED = 'Approved';
    private static final String NOTIFICATION_REJECTED = 'Rejected';
    private static final String LEGACY_SENDER_ADDRESS = celsrm__SRM_Configuration__c.getOrgDefaults().Mailbox_Email_Address__c;
    private static Id cachedOrgWideEmailAddressId;

    public class Request {
        @InvocableVariable(required=true)
        public Id recordId;

        @InvocableVariable(required=true)
        public String notificationType;
    }

    public class Result {
        @InvocableVariable
        public Id recordId;

        @InvocableVariable
        public String status;

        @InvocableVariable
        public String message;
    }

    @InvocableMethod(label='Send Localized Dispute Owner Email')
    public static List<Result> sendLocalizedOwnerEmails(List<Request> requests) {
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
        Set<Id> ownerIds = new Set<Id>();
        for (celsrm__Dispute__c disputeRecord : disputesById.values()) {
            if (disputeRecord.celsrm__Owner__c != null) {
                ownerIds.add(disputeRecord.celsrm__Owner__c);
            }
        }

        Map<Id, User> ownersById = queryOwners(ownerIds);
        //-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
        Map<Id, celsrm__User_Master__c> ownerMastersByUserId = DisputeEmailLocalizationService.getUserMastersByUserId(ownerIds);
        //-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//

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

            if (disputeRecord.celsrm__Owner__c == null) {
                resultItem.message = 'The dispute does not have an owner to notify.';
                results.add(resultItem);
                continue;
            }

            User ownerUser = ownersById.get(disputeRecord.celsrm__Owner__c);
            if (ownerUser == null || String.isBlank(ownerUser.Email)) {
                resultItem.message = 'The dispute owner does not have an email address.';
                results.add(resultItem);
                continue;
            }

            String templateName = getTemplateName(requestItem.notificationType);
            if (String.isBlank(templateName)) {
                resultItem.message = 'Unsupported owner notification type.';
                results.add(resultItem);
                continue;
            }

            String languageFolder = DisputeEmailLocalizationService.resolveOwnerNotificationLanguage(
                disputeRecord,
                ownerUser,
                ownerMastersByUserId.get(disputeRecord.celsrm__Owner__c)
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
                disputeRecord.Id
            );

            //-- Start | FIN-9675 | Changed by Ravi | 07 May 2026 --//
            Map<Object, Object> returnMap = sendEmailWithMapper(
                ownerUser.Email,
                renderedTemplate,
                disputeRecord.Id
            );
            if (returnMap != null && returnMap.containsKey(false)) {
                resultItem.status = 'Error';
                resultItem.message = String.valueOf(returnMap.get(false));
            } else {
                resultItem.status = 'Sent';
                resultItem.message = 'Email sent successfully.';
            }
            //-- End | FIN-9675 | Changed by Ravi | 07 May 2026 --//
            results.add(resultItem);
        }

        return results;
    }

    private static String getTemplateName(String notificationType) {
        String normalizedType = String.isBlank(notificationType) ? null : notificationType.trim().toLowerCase();
        if (normalizedType == NOTIFICATION_APPROVED.toLowerCase()) {
            return DisputeEmailLocalizationService.OWNER_APPROVED_TEMPLATE_NAME;
        }
        if (normalizedType == NOTIFICATION_REJECTED.toLowerCase()) {
            return DisputeEmailLocalizationService.OWNER_REJECTED_TEMPLATE_NAME;
        }
        return null;
    }

    private static Map<Id, celsrm__Dispute__c> queryDisputes(Set<Id> disputeIds) {
        Map<Id, celsrm__Dispute__c> disputesById = new Map<Id, celsrm__Dispute__c>();
        if (disputeIds == null || disputeIds.isEmpty()) {
            return disputesById;
        }

        Set<String> selectFields = new Set<String>{
            'Id',
            'Name',
            'celsrm__Owner__c',
            'celsrm__Status__c',
            'celsrm__Account__c',
            'celsrm__Account__r.Id',
            'celsrm__Account__r.Name',
            'celsrm__Dispute_Type__c',
            'celsrm__Reason_Code__c',
            'celsrm__Amount__c',
            'Invoice_Number__c',
            'Account_Name__c',
            'Owner_Name__c',
            'Rejection_Code__c',
            'Reject_Reason__c'
        };
        selectFields.addAll(DisputeEmailLocalizationService.getOwnerNotificationAdditionalQueryFields());

        String query = 'SELECT ' + String.join(new List<String>(selectFields), ', ') +
            ' FROM celsrm__Dispute__c WHERE Id IN :disputeIds';
        for (celsrm__Dispute__c disputeRecord : Database.query(query)) {
            disputesById.put(disputeRecord.Id, disputeRecord);
        }
        return disputesById;
    }

    private static Map<Id, User> queryOwners(Set<Id> ownerIds) {
        Map<Id, User> ownersById = new Map<Id, User>();
        if (ownerIds == null || ownerIds.isEmpty()) {
            return ownersById;
        }

        for (User ownerUser : [
            SELECT Id, Email, toLabel(LanguageLocaleKey) LanguageLabel
            FROM User
            WHERE Id IN :ownerIds
        ]) {
            ownersById.put(ownerUser.Id, ownerUser);
        }
        return ownersById;
    }

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