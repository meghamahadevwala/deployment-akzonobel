//-- Start | FIN-9672 | Changed by Ravi | 05 May 2026 --//
// Please refer to the PR for the changes—almost every line in this class has been modified.
//-- End | FIN-9672 | Changed by Ravi | 05 May 2026 --//
//-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
// Please refer to the PR for the changes—almost every line in this class has been modified.
public class DisputeReminderAndEscalationBatch implements Database.Batchable<sObject>, Database.Stateful, Schedulable {
    @TestVisible
    private ReminderEscalationRuleService ruleService;
    public Map<String, Map<String, Map<String, List<celsrm__Dispute_Workflow_Details__c>>>> finalEscalationEmailMap;
    public List<String> skippedEscalationConfigErrors;
    public String resolverType;

    private static final String FOLLOW_UP_TYPE = 'followup';
    private static final String NOTIFICATION_REMINDER = 'Reminder';
    private static final String NOTIFICATION_ESCALATION = 'Escalation';
    private static final String BUCKET_KEY_SEPARATOR = '||';
    private static final String LEGACY_SENDER_ADDRESS = celsrm__SRM_Configuration__c.getOrgDefaults().Mailbox_Email_Address__c;
    private static Id cachedOrgWideEmailAddressId;

    private class RenderedEmailContent {
        String subject;
        String htmlBody;
        String plainTextBody;
    }

    public DisputeReminderAndEscalationBatch() {
        finalEscalationEmailMap = new Map<String, Map<String, Map<String, List<celsrm__Dispute_Workflow_Details__c>>>>();
        skippedEscalationConfigErrors = new List<String>();
        resolverType = celsrm__Dispute_Configuration__c.getOrgDefaults().celsrm__Dispute_Resolver_Type__c;
        ruleService = new ReminderEscalationRuleService(resolverType);
    }

    @TestVisible
    private void addAdditionalDisputeFieldQueryPaths(Set<String> queryFields) {
        if (ruleService == null || queryFields == null) {
            return;
        }

        Set<String> baselineDisputePaths = new Set<String>{
            'celsrm__Dispute__r.celsrm__Dispute_Type__c',
            'celsrm__Dispute__r.celsrm__Reason_Code__c',
            'celsrm__Dispute__r.celsrm__Amount__c',
            'celsrm__Dispute__r.celsrm__Status__c'
        };

        for (String fieldToken : ruleService.getDisputeCriteriaFieldTokens()) {
            if (String.isBlank(fieldToken) || fieldToken.contains('.')) {
                continue;
            }
            String disputePath = 'celsrm__Dispute__r.' +
                celsrm.ApprovalConfigController.getFullApiName(fieldToken.trim());
            if (!baselineDisputePaths.contains(disputePath)) {
                queryFields.add(disputePath);
            }
        }
    }

    public Database.QueryLocator start(Database.BatchableContext context) {
        try {
            Set<String> queryFields = new Set<String>{
                'Id',
                'celsrm__Dispute__c',
                'celsrm__Dispute__r.Name',
                'celsrm__Dispute__r.celsrm__Dispute_Type__c',
                'celsrm__Dispute__r.celsrm__Reason_Code__c',
                'celsrm__Dispute__r.celsrm__Amount__c',
                'celsrm__Dispute__r.celsrm__Status__c',
                'celsrm__Dispute__r.celsrm__Transaction__r.Name',
                'celsrm__Dispute__r.celsrm__Transaction__r.celsrm__Due_Date__c',
                'celsrm__Dispute__r.celsrm__Transaction__r.celsrm__Amount__c',
                'celsrm__Dispute__r.celsrm__Account__r.Name',
                'celsrm__Dispute__r.celsrm__Account__r.AccountNumber',
                'celsrm__User_Master__c',
                'celsrm__User_Master__r.Name',
                'celsrm__User_Master__r.celsrm__Email__c',
                'celsrm__User_Master__r.celsrm__User__c',
                'celsrm__User_Master__r.celsrm__Is_External_User__c',
                'celsrm__User_Master__r.celsrm__Language__c',
                'celsrm__User_Master__r.celsrm__Manager__c',
                'celsrm__User_Master__r.celsrm__Manager__r.Name',
                'celsrm__User_Master__r.celsrm__Manager__r.celsrm__Email__c',
                'celsrm__User_Master__r.celsrm__Manager__r.celsrm__Language__c',
                'celsrm__Workflow_User_Type__c',
                'celsrm__Workflow_Level__c',
                'CreatedDate',
                'celsrm__Dispute_Workflow_Matrix__c'
            };

            queryFields.addAll(DisputeEmailColumnConfigurationService.getAllSupportedQueryPaths());
            queryFields.addAll(DisputeEmailLocalizationService.getWorkflowDetailAdditionalQueryFields());
            addAdditionalDisputeFieldQueryPaths(queryFields);

            String query = 'SELECT ' + String.join(new List<String>(queryFields), ', ') +
                ' FROM celsrm__Dispute_Workflow_Details__c WHERE celsrm__Status__c = \'Pending\'' +
                ' AND celsrm__Dispute__r.celsrm__Status__c != \'On Hold\'';
            return Database.getQueryLocator(query);
        } catch (Exception exceptionObject) {
            System.debug('start ' + exceptionObject.getMessage());
            return null;
        }
    }

    public void execute(SchedulableContext sc) {
        Database.executeBatch(new DisputeReminderAndEscalationBatch(), 4);
    }

    public void execute(Database.BatchableContext context, List<sObject> scope) {
        for (sObject recordObject : scope) {
            processWorkflowDetail((celsrm__Dispute_Workflow_Details__c) recordObject);
        }
        sendQueuedEmails();
        finalEscalationEmailMap.clear();
    }

    @TestVisible
    private Boolean isExternalWorkflowDetail(celsrm__Dispute_Workflow_Details__c workflowDetails) {
        DisputeUserMasterService.ResolvedUserInfo resolvedUser = DisputeUserMasterService.resolveFromWorkflowDetailRecord(workflowDetails);
        return resolvedUser != null && resolvedUser.isExternal();
    }

    @TestVisible
    private String normalizeFollowUpType(String followUpType) {
        return String.isBlank(followUpType) ? '' : followUpType.trim().toLowerCase();
    }

    @TestVisible
    private String formatEscalationLevel(Decimal escalationLevel) {
        return escalationLevel == null ? '' : String.valueOf(escalationLevel.intValue());
    }

    @TestVisible
    private String resolveRecipientEmail(celsrm__Dispute_Workflow_Details__c workflowDetails, String followUpType) {
        DisputeUserMasterService.ResolvedUserInfo resolvedUser = DisputeUserMasterService.resolveFromWorkflowDetailRecord(workflowDetails);
        String normalizedFollowUpType = normalizeFollowUpType(followUpType);

        if (resolvedUser == null) {
            return null;
        }

        if (normalizedFollowUpType == FOLLOW_UP_TYPE) {
            return resolvedUser.email;
        }

        if (!String.isBlank(resolvedUser.managerEmail)) {
            return resolvedUser.managerEmail;
        }

        return null;
    }

    @TestVisible
    private void addWorkflowDetailToEmailBucket(
        String recipientEmail,
        String followUpType,
        String escalationLevel,
        celsrm__Dispute_Workflow_Details__c workflowDetails
    ) {
        addWorkflowDetailToEmailBucket(recipientEmail, null, followUpType, escalationLevel, workflowDetails);
    }

    @TestVisible
    private void addWorkflowDetailToEmailBucket(
        String recipientEmail,
        String languageFolder,
        String followUpType,
        String escalationLevel,
        celsrm__Dispute_Workflow_Details__c workflowDetails
    ) {
        String bucketKey = buildEmailBucketKey(recipientEmail, languageFolder);
        if (!finalEscalationEmailMap.containsKey(bucketKey)) {
            finalEscalationEmailMap.put(bucketKey, new Map<String, Map<String, List<celsrm__Dispute_Workflow_Details__c>>>());
        }

        Map<String, Map<String, List<celsrm__Dispute_Workflow_Details__c>>> recipientBuckets = finalEscalationEmailMap.get(bucketKey);
        if (!recipientBuckets.containsKey(followUpType)) {
            recipientBuckets.put(followUpType, new Map<String, List<celsrm__Dispute_Workflow_Details__c>>());
        }

        Map<String, List<celsrm__Dispute_Workflow_Details__c>> levelBuckets = recipientBuckets.get(followUpType);
        if (!levelBuckets.containsKey(escalationLevel)) {
            levelBuckets.put(escalationLevel, new List<celsrm__Dispute_Workflow_Details__c>());
        }

        levelBuckets.get(escalationLevel).add(workflowDetails);
    }

    @TestVisible
    private void recordMissingRecipientError(
        celsrm__Dispute_Workflow_Details__c workflowDetails,
        String followUpType,
        String escalationLevel
    ) {
        String normalizedFollowUpType = normalizeFollowUpType(followUpType);
        String recipientFieldName = normalizedFollowUpType == FOLLOW_UP_TYPE
            ? 'celsrm__User_Master__r.celsrm__Email__c'
            : 'celsrm__User_Master__r.celsrm__Manager__r.celsrm__Email__c';

        String disputeName = workflowDetails.celsrm__Dispute__r != null ? workflowDetails.celsrm__Dispute__r.Name : '';
        skippedEscalationConfigErrors.add(
            'DisputeReminderAndEscalationBatch configuration error: Missing ' + recipientFieldName +
            ' for workflow detail ' + workflowDetails.Id +
            ', dispute ' + workflowDetails.celsrm__Dispute__c +
            ' (' + disputeName + ')' +
            ', workflow matrix ' + workflowDetails.celsrm__Dispute_Workflow_Matrix__c +
            ', follow up type ' + followUpType +
            ', escalation level ' + escalationLevel + '.'
        );
    }

    public void processWorkflowDetail(celsrm__Dispute_Workflow_Details__c workflowDetails) {
        if (ruleService == null) {
            return;
        }

        List<ReminderEscalationRuleService.FollowUpEntry> followUpEntries = ruleService.getFollowUpEntries(workflowDetails);
        if (followUpEntries == null || followUpEntries.isEmpty()) {
            return;
        }

        for (ReminderEscalationRuleService.FollowUpEntry followUpEntry : followUpEntries) {
            Decimal followUpDays = followUpEntry.followUpDays == null ? 0 : followUpEntry.followUpDays;
            Date calculatedEscalationDate = workflowDetails.CreatedDate.date().addDays(
                Integer.valueOf(followUpDays.intValue())
            );

            if (calculatedEscalationDate != Date.today()) {
                continue;
            }

            String followUpType = normalizeFollowUpType(followUpEntry.followUpType);
            String escalationLevel = formatEscalationLevel(followUpEntry.followUpLevel);
            String recipientEmail = resolveRecipientEmail(workflowDetails, followUpType);

            if (String.isBlank(recipientEmail)) {
                recordMissingRecipientError(workflowDetails, followUpType, escalationLevel);
                break;
            }

            String languageFolder = DisputeEmailLocalizationService.resolveWorkflowDetailLanguage(
                workflowDetails,
                followUpType != FOLLOW_UP_TYPE
            );
            addWorkflowDetailToEmailBucket(
                recipientEmail,
                languageFolder,
                followUpType,
                escalationLevel,
                workflowDetails
            );
            break;
        }
    }

    public void finish(Database.BatchableContext context) {
        sendQueuedEmails();
        finalEscalationEmailMap.clear();
    }

    private void sendQueuedEmails() {
        for (String bucketKey : finalEscalationEmailMap.keySet()) {
            String recipientEmail = extractRecipientEmail(bucketKey);
            String languageFolder = extractLanguageFolder(bucketKey);
            Map<String, Map<String, List<celsrm__Dispute_Workflow_Details__c>>> recipientBuckets = finalEscalationEmailMap.get(bucketKey);

            for (String followUpType : recipientBuckets.keySet()) {
                Map<String, List<celsrm__Dispute_Workflow_Details__c>> levelBuckets = recipientBuckets.get(followUpType);
                String templateName = followUpType == FOLLOW_UP_TYPE
                    ? DisputeEmailLocalizationService.REMINDER_TEMPLATE_NAME
                    : DisputeEmailLocalizationService.ESCALATION_TEMPLATE_NAME;
                String notificationType = followUpType == FOLLOW_UP_TYPE ? NOTIFICATION_REMINDER : NOTIFICATION_ESCALATION;

                for (String escalationLevel : levelBuckets.keySet()) {
                    List<celsrm__Dispute_Workflow_Details__c> workflowDetails = levelBuckets.get(escalationLevel);
                    if (workflowDetails == null || workflowDetails.isEmpty()) {
                        continue;
                    }

                    for (celsrm__Dispute_Workflow_Details__c workflowDetail : workflowDetails) {
                        RenderedEmailContent emailContent = buildEmailContent(
                            languageFolder,
                            templateName,
                            notificationType,
                            escalationLevel,
                            new List<celsrm__Dispute_Workflow_Details__c>{ workflowDetail }
                        );
                        if (emailContent != null) {
                            sendEmailWithMapper(
                                recipientEmail,
                                emailContent,
                                workflowDetail.celsrm__Dispute__c,
                                followUpType,
                                escalationLevel
                            );
                        }
                    }
                }
            }
        }
    }

    private RenderedEmailContent buildEmailContent(
        String languageFolder,
        String templateName,
        String notificationType,
        String escalationLevel,
        List<celsrm__Dispute_Workflow_Details__c> workflowDetails
    ) {
        DisputeEmailLocalizationService.TemplateSelection templateSelection = DisputeEmailLocalizationService.resolveTemplate(
            templateName,
            languageFolder
        );

        if (templateSelection == null || templateSelection.templateId == null) {
            skippedEscalationConfigErrors.add(
                'DisputeReminderAndEscalationBatch configuration error: Template "' + templateName +
                '" could not be found for language folder "' + languageFolder + '".'
            );
            return null;
        }

        Messaging.SingleEmailMessage renderedTemplate = Messaging.renderStoredEmailTemplate(
            templateSelection.templateId,
            null,
            workflowDetails[0].celsrm__Dispute__c
        );
        if (renderedTemplate == null) {
            return null;
        }

        List<DisputeEmailColumnConfigurationService.ColumnDefinition> columns =
            DisputeEmailColumnConfigurationService.getColumnsForLanguage(
                templateSelection.folderName,
                notificationType,
                DisputeEmailLocalizationService.getDefaultLanguageFolder()
            );

        String subject = renderedTemplate.getSubject();
        if (subject != null) {
            subject = subject.replace('{FOLLOW_UP_ESCALATION_LEVEL}', escalationLevel);
        }

        String summaryHtml = buildSummaryHtml(columns, workflowDetails);
        String summaryText = buildSummaryText(columns, workflowDetails);
        String htmlBody = renderedTemplate.getHtmlBody() != null ? renderedTemplate.getHtmlBody() : renderedTemplate.getPlainTextBody();
        String plainTextBody = renderedTemplate.getPlainTextBody() != null ? renderedTemplate.getPlainTextBody() : renderedTemplate.getHtmlBody();

        htmlBody = htmlBody != null ? htmlBody.replace('{dispute.summary}', summaryHtml) : summaryHtml;
        plainTextBody = plainTextBody != null ? plainTextBody.replace('{dispute.summary}', summaryText) : summaryText;

        RenderedEmailContent emailContent = new RenderedEmailContent();
        emailContent.subject = subject;
        emailContent.htmlBody = htmlBody;
        emailContent.plainTextBody = plainTextBody;
        return emailContent;
    }

    private String buildSummaryHtml(
        List<DisputeEmailColumnConfigurationService.ColumnDefinition> columns,
        List<celsrm__Dispute_Workflow_Details__c> workflowDetails
    ) {
        String html = '<table width="100%" class="billing" style="border-collapse:collapse;padding:0px; font-family:verdana; border: 1px solid black;">';
        html += '<thead><tr>';
        for (DisputeEmailColumnConfigurationService.ColumnDefinition column : columns) {
            html += '<th style="border: 1px solid black;">' + escapeHtml(column.label) + '</th>';
        }
        html += '</tr></thead><tbody>';

        for (celsrm__Dispute_Workflow_Details__c workflowDetail : workflowDetails) {
            html += '<tr>';
            for (DisputeEmailColumnConfigurationService.ColumnDefinition column : columns) {
                Object rawValue = DisputeEmailColumnConfigurationService.resolveValue(workflowDetail, column.fieldPath);
                String style = column.numeric
                    ? 'text-align: right;border: 1px solid black;'
                    : 'border: 1px solid black;';
                html += '<td style="' + style + '">' + escapeHtml(stringifyValue(rawValue)) + '</td>';
            }
            html += '</tr>';
        }
        html += '</tbody></table>';
        return html;
    }

    private String buildSummaryText(
        List<DisputeEmailColumnConfigurationService.ColumnDefinition> columns,
        List<celsrm__Dispute_Workflow_Details__c> workflowDetails
    ) {
        List<String> lines = new List<String>();
        List<String> headerCells = new List<String>();
        for (DisputeEmailColumnConfigurationService.ColumnDefinition column : columns) {
            headerCells.add(column.label);
        }
        lines.add(String.join(headerCells, ' | '));

        for (celsrm__Dispute_Workflow_Details__c workflowDetail : workflowDetails) {
            List<String> rowValues = new List<String>();
            for (DisputeEmailColumnConfigurationService.ColumnDefinition column : columns) {
                rowValues.add(stringifyValue(DisputeEmailColumnConfigurationService.resolveValue(workflowDetail, column.fieldPath)));
            }
            lines.add(String.join(rowValues, ' | '));
        }
        return String.join(lines, '\n');
    }

    private String buildEmailBucketKey(String recipientEmail, String languageFolder) {
        return recipientEmail + BUCKET_KEY_SEPARATOR + (languageFolder == null ? '' : languageFolder);
    }

    private String extractRecipientEmail(String bucketKey) {
        Integer separatorIndex = bucketKey.indexOf(BUCKET_KEY_SEPARATOR);
        return separatorIndex == -1 ? bucketKey : bucketKey.substring(0, separatorIndex);
    }

    private String extractLanguageFolder(String bucketKey) {
        Integer separatorIndex = bucketKey.indexOf(BUCKET_KEY_SEPARATOR);
        return separatorIndex == -1 ? null : bucketKey.substring(separatorIndex + BUCKET_KEY_SEPARATOR.length());
    }

    private void sendEmailWithMapper(
        String recipientEmail,
        RenderedEmailContent emailContent,
        Id parentId,
        String followUpType,
        String escalationLevel
    ) {
        try {
            celsrm.GOGEmailMapper.SendEmailBean emailBean = new celsrm.GOGEmailMapper.SendEmailBean();
            emailBean.owea = getOrgWideEmailAddressId();
            emailBean.to = new List<String>{ recipientEmail };
            emailBean.subject = emailContent.subject;
            emailBean.htmlBody = emailContent.htmlBody;
            emailBean.plainTextBody = emailContent.plainTextBody;
            emailBean.cc = null;
            emailBean.bcc = null;
            emailBean.attachment = null;
            emailBean.parentId = parentId;
            emailBean.followUpTaskDueDate = null;

            Map<Object, Object> returnMap = celsrm.GOGEmailMapper.sendEmailWithBean(emailBean);
            if (returnMap != null && returnMap.containsKey(false)) {
                skippedEscalationConfigErrors.add(
                    'DisputeReminderAndEscalationBatch email send error: ' + String.valueOf(returnMap.get(false)) +
                    ' Recipient ' + recipientEmail +
                    ', dispute ' + parentId +
                    ', follow up type ' + followUpType +
                    ', escalation level ' + escalationLevel + '.'
                );
            }
        } catch (Exception exceptionObject) {
            skippedEscalationConfigErrors.add(
                'DisputeReminderAndEscalationBatch email send exception: ' + exceptionObject.getMessage() +
                ' Recipient ' + recipientEmail +
                ', dispute ' + parentId +
                ', follow up type ' + followUpType +
                ', escalation level ' + escalationLevel + '.'
            );
        }
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

    private String stringifyValue(Object rawValue) {
        return rawValue == null ? '' : String.valueOf(rawValue);
    }

    private String escapeHtml(String rawValue) {
        return rawValue == null ? '' : rawValue.escapeHtml4();
    }
}
//-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//