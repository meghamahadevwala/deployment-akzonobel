public with sharing class TeamLeadReportBatch implements Database.Batchable<Id>, Database.Stateful {

    private Id reportId;
    private String ownerReportColumnName;
    private String groupingFieldNames;
    private String accountNumberReportColumnName;
    private String emailSubjectBase;
    private String emailBodyText;
    private String reportLabel;
    private String subjectDateFormat;
    private Id orgWideEmailAddressId;

    private Map<Id, List<String>> ownerNamesByTeamLead = new Map<Id, List<String>>();
    private Map<Id, List<String>> ownerEmailsByTeamLead = new Map<Id, List<String>>();

    public Integer successCount = 0;
    public List<String> errors = new List<String>();

    public TeamLeadReportBatch(Report_Reminder_Config__mdt config) {
        this.reportId = (Id) config.Report_Id__c;
        this.ownerReportColumnName = config.Owner_Report_Column_Name__c;
        this.groupingFieldNames = config.Grouping_Report_Column_Names__c;
        this.accountNumberReportColumnName = config.Account_Number_Report_Column_Name__c;
        this.emailSubjectBase = config.Email_Subject__c;
        this.emailBodyText = config.Email_Body_Text__c;
        this.reportLabel = config.Label;
        this.subjectDateFormat = config.Subject_Date_Format__c;
        this.orgWideEmailAddressId = String.isNotBlank(config.Org_Wide_Email_Address_Id__c)
            ? (Id) config.Org_Wide_Email_Address_Id__c
            : null;
    }

    public Iterable<Id> start(Database.BatchableContext bc) {
        Set<String> ownerNamesWithData = ReportRunnerService.discoverOwnersWithData(reportId, ownerReportColumnName);
        if (ownerNamesWithData.isEmpty()) {
            return new List<Id>();
        }

        List<User> owners = [SELECT Id, Name, Email, ManagerId FROM User WHERE Name IN :ownerNamesWithData AND IsActive = true];

        for (User owner : owners) {
            if (owner.ManagerId == null) {
                continue;
            }
            if (!ownerNamesByTeamLead.containsKey(owner.ManagerId)) {
                ownerNamesByTeamLead.put(owner.ManagerId, new List<String>());
                ownerEmailsByTeamLead.put(owner.ManagerId, new List<String>());
            }
            ownerNamesByTeamLead.get(owner.ManagerId).add(owner.Name);
            if (String.isNotBlank(owner.Email)) {
                ownerEmailsByTeamLead.get(owner.ManagerId).add(owner.Email);
            }
        }

        return new List<Id>(ownerNamesByTeamLead.keySet());
    }

    public void execute(Database.BatchableContext bc, List<Id> scope) {
        List<User> teamLeads = [SELECT Id, Name, Email FROM User WHERE Id IN :scope AND IsActive = true];

        String baseSubject = EmailSubjectBuilder.build(emailSubjectBase, subjectDateFormat, Date.today());
        List<Messaging.SingleEmailMessage> emailsToSend = new List<Messaging.SingleEmailMessage>();

        for (User teamLead : teamLeads) {
            List<String> ownerNames = ownerNamesByTeamLead.get(teamLead.Id);
            if (ownerNames == null || ownerNames.isEmpty()) {
                continue;
            }
            List<String> ownerEmails = ownerEmailsByTeamLead.get(teamLead.Id);

            try {
                Blob reportFile = ReportRunnerService.runReportForOwners(reportId, ownerReportColumnName, ownerNames, groupingFieldNames, accountNumberReportColumnName);

                String personalizedSubject = baseSubject + ' - ' + teamLead.Name;

                Messaging.SingleEmailMessage email = ReportReminderEmailBuilder.build(
                    teamLead.Email,
                    ownerEmails,
                    personalizedSubject,
                    emailBodyText,
                    reportLabel,
                    reportFile,
                    orgWideEmailAddressId
                );
                emailsToSend.add(email);
            } catch (Exception ex) {
                errors.add('Team Lead ' + teamLead.Id + ' (' + teamLead.Name + '): ' + ex.getMessage());
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
        System.debug('TeamLeadReportBatch finished. Success: ' + successCount + ' Errors: ' + errors);
    }
}