public with sharing class ReportReminderEmailBuilder {
    public static Messaging.SingleEmailMessage build(
        String toEmail,
        List<String> ccEmails,
        String subject,
        String bodyText,
        String reportLabel,
        Blob reportAttachment,
        Id orgWideEmailAddressId
    ) {
        return build(toEmail, ccEmails, subject, bodyText, reportLabel, reportAttachment, orgWideEmailAddressId, null);
    }

    /**
     * @param ccEmails           List of CC addresses (team lead's CC'd owners, or the single
     *                           owner's CC'd team lead, depending on Recipient_Mode__c). Pass
     *                           null or an empty list for no CC.
     * @param redirectNoticeHtml Optional banner prepended to the body, used by test/redirect
     *                           methods to state who the real recipient(s) would have been.
     */
    public static Messaging.SingleEmailMessage build(
        String toEmail,
        List<String> ccEmails,
        String subject,
        String bodyText,
        String reportLabel,
        Blob reportAttachment,
        Id orgWideEmailAddressId,
        String redirectNoticeHtml
    ) {
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setToAddresses(new List<String>{ toEmail });
        if (ccEmails != null && !ccEmails.isEmpty()) {
            email.setCcAddresses(ccEmails);
        }
        if (orgWideEmailAddressId != null) {
            email.setOrgWideEmailAddressId(orgWideEmailAddressId);
        }
        email.setSubject(subject);
        // NOTE: no longer auto-appends "Please find the full report ... attached" - the
        // configured Email_Body_Text__c is now expected to already state that itself
        // (per the updated business-required body copy).
        String htmlBody = (String.isNotBlank(redirectNoticeHtml)
                ? '<p style="background:#fff3cd;border:1px solid #ffc107;padding:10px;"><strong>TEST MODE:</strong> ' + redirectNoticeHtml + '</p>'
                : '')
            + '<p>' + bodyText.replace('\n', '<br/>') + '</p>';
        email.setHtmlBody(htmlBody);
        String plainBody = (String.isNotBlank(redirectNoticeHtml) ? '[TEST MODE] ' + redirectNoticeHtml + '\n\n' : '')
            + bodyText;
        email.setPlainTextBody(plainBody);
        Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
        attachment.setFileName(reportLabel.replace(' ', '_') + '.xls');
        attachment.setBody(reportAttachment);
        attachment.setContentType('application/vnd.ms-excel');
        email.setFileAttachments(new List<Messaging.EmailFileAttachment>{ attachment });
        email.setSaveAsActivity(false);
        return email;
    }
}