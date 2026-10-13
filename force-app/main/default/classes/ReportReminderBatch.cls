public with sharing class ReportReminderBatch implements Database.Batchable<String>, Database.Stateful {

    private Id reportId;
    private String ownerReportColumnName;
    private String groupingFieldNames;
    private String accountNumberReportColumnName;
    private String emailSubject;
    private String emailBodyText;
    private String reportLabel;
    private String subjectDateFormat;
    private Id orgWideEmailAddressId;

    public Integer successCount = 0;
    public List<String> errors = new List<String>();

    public ReportReminderBatch(Report_Reminder_Config__mdt config) {
        this.reportId = (Id) config.Report_Id__c;
        this.ownerReportColumnName = config.Owner_Report_Column_Name__c;
        this.groupingFieldNames = config.Grouping_Report_Column_Names__c;
        this.accountNumberReportColumnName = config.Account_Number_Report_Column_Name__c;
        this.emailSubject = config.Email_Subject__c;
        this.emailBodyText = config.Email_Body_Text__c;
        this.reportLabel = config.Label;
        this.subjectDateFormat = config.Subject_Date_Format__c;
        this.orgWideEmailAddressId = String.isNotBlank(config.Org_Wide_Email_Address_Id__c)
            ? (Id) config.Org_Wide_Email_Address_Id__c
            : null;
    }

    public Iterable<String> start(Database.BatchableContext bc) {
        Set<String> ownerNamesWithData = ReportRunnerService.discoverOwnersWithData(reportId, ownerReportColumnName);
        return new List<String>(ownerNamesWithData);
    }

    public void execute(Database.BatchableContext bc, List<String> scope) {
        List<User> owners = [SELECT Id, Name, Email FROM User WHERE Name IN :scope AND IsActive = true];

        Set<Id> ownerIds = new Set<Id>();
        for (User u : owners) {
            ownerIds.add(u.Id);
        }

        Map<Id, User> teamLeadsByOwner = TeamLeadResolver.resolveTeamLeads(ownerIds);
        List<Messaging.SingleEmailMessage> emailsToSend = new List<Messaging.SingleEmailMessage>();
        String subject = EmailSubjectBuilder.build(emailSubject, subjectDateFormat, Date.today());

        for (User owner : owners) {
            try {
                Blob reportFile = ReportRunnerService.runReportForOwner(reportId, ownerReportColumnName, owner.Name, groupingFieldNames, accountNumberReportColumnName);

                User teamLead = teamLeadsByOwner.get(owner.Id);
                String teamLeadEmail = teamLead != null ? teamLead.Email : null;

                Messaging.SingleEmailMessage email = ReportReminderEmailBuilder.build(
                    owner.Email,
                    String.isNotBlank(teamLeadEmail) ? new List<String>{ teamLeadEmail } : null,
                    subject,
                    emailBodyText,
                    reportLabel,
                    reportFile,
                    orgWideEmailAddressId
                );
                emailsToSend.add(email);
            } catch (Exception ex) {
                errors.add('Owner ' + owner.Id + ' (' + owner.Name + '): ' + ex.getMessage());
            }
        }

        if (!emailsToSend.isEmpty()) {
            List<Messaging.SendEmailResult> results = Messaging.sendEmail(emailsToSend, false);
            for (Messaging.SendEmailResult res : results) {
                if (res.isSuccess()) {
                    successCount++;
                } else {
                    for (Messaging.SendEmailError err : res.getErrors()) {
                        errors.add('Send error: ' + err.getMessage());
                    }
                }
            }
        }
    }

    public void finish(Database.BatchableContext bc) {
        System.debug('ReportReminderBatch finished. Success: ' + successCount + ' Errors: ' + errors);
    }
}