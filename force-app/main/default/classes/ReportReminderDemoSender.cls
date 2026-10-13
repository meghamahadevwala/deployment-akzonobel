public with sharing class ReportReminderDemoSender {

    public class DemoSendResult {
        public Boolean success;
        public String message;
    }

    private static Report_Reminder_Config__mdt getConfig(String configDeveloperName) {
        List<Report_Reminder_Config__mdt> configs = [
            SELECT Label, Report_Id__c, Owner_Report_Column_Name__c, Grouping_Report_Column_Names__c,
                   Account_Number_Report_Column_Name__c,
                   Org_Wide_Email_Address_Id__c,
                   Email_Subject__c, Email_Body_Text__c, Subject_Date_Format__c
            FROM Report_Reminder_Config__mdt
            WHERE DeveloperName = :configDeveloperName
            LIMIT 1
        ];
        return configs.isEmpty() ? null : configs[0];
    }

    public static DemoSendResult sendSampleNow(String configDeveloperName, Id ownerId) {
        DemoSendResult result = new DemoSendResult();

        Report_Reminder_Config__mdt config = getConfig(configDeveloperName);
        if (config == null) {
            result.success = false;
            result.message = 'No Report_Reminder_Config__mdt found with DeveloperName ' + configDeveloperName;
            return result;
        }

        User owner = [SELECT Id, Name, Email FROM User WHERE Id = :ownerId LIMIT 1];
        Map<Id, User> teamLeads = TeamLeadResolver.resolveTeamLeads(new Set<Id>{ owner.Id });
        User teamLead = teamLeads.get(owner.Id);

        try {
            Blob reportFile = ReportRunnerService.runReportForOwner(
                (Id) config.Report_Id__c,
                config.Owner_Report_Column_Name__c,
                owner.Name,
                config.Grouping_Report_Column_Names__c,
                config.Account_Number_Report_Column_Name__c
            );

            String subject = '[SAMPLE] ' + EmailSubjectBuilder.build(config.Email_Subject__c, config.Subject_Date_Format__c, Date.today());

            Messaging.SingleEmailMessage email = ReportReminderEmailBuilder.build(
                owner.Email,
                (teamLead != null && String.isNotBlank(teamLead.Email)) ? new List<String>{ teamLead.Email } : null,
                subject,
                config.Email_Body_Text__c,
                config.Label,
                reportFile,
                String.isNotBlank(config.Org_Wide_Email_Address_Id__c) ? (Id) config.Org_Wide_Email_Address_Id__c : null
            );

            result = send(email, owner.Email, teamLead != null ? teamLead.Email : null);
        } catch (Exception ex) {
            result.success = false;
            result.message = ex.getMessage();
        }

        return result;
    }

    public static DemoSendResult sendSampleNowForTeamLead(String configDeveloperName, Id teamLeadId) {
        DemoSendResult result = new DemoSendResult();

        Report_Reminder_Config__mdt config = getConfig(configDeveloperName);
        if (config == null) {
            result.success = false;
            result.message = 'No Report_Reminder_Config__mdt found with DeveloperName ' + configDeveloperName;
            return result;
        }

        User teamLead = [SELECT Id, Name, Email FROM User WHERE Id = :teamLeadId LIMIT 1];
        List<User> directReports = [SELECT Id, Name, Email FROM User WHERE ManagerId = :teamLeadId AND IsActive = true];

        if (directReports.isEmpty()) {
            result.success = false;
            result.message = 'This user has no active direct reports (ManagerId match) in this org - '
                + 'use sendSampleNowCustom() instead to test without a real hierarchy.';
            return result;
        }

        List<String> ownerNames = new List<String>();
        List<String> ownerEmails = new List<String>();
        for (User u : directReports) {
            ownerNames.add(u.Name);
            if (String.isNotBlank(u.Email)) {
                ownerEmails.add(u.Email);
            }
        }

        return sendCustomInternal(config, teamLead.Email, ownerNames, teamLead.Name, ownerEmails);
    }

    public static DemoSendResult sendSampleNowCustom(String configDeveloperName, String recipientEmail, List<String> ownerNamesToFilter) {
        Report_Reminder_Config__mdt config = getConfig(configDeveloperName);
        if (config == null) {
            DemoSendResult result = new DemoSendResult();
            result.success = false;
            result.message = 'No Report_Reminder_Config__mdt found with DeveloperName ' + configDeveloperName;
            return result;
        }
        return sendCustomInternal(config, recipientEmail, ownerNamesToFilter, null, null);
    }

    private static DemoSendResult sendCustomInternal(
        Report_Reminder_Config__mdt config,
        String recipientEmail,
        List<String> ownerNames,
        String personalizedNameForSubject,
        List<String> ccEmails
    ) {
        DemoSendResult result = new DemoSendResult();

        try {
            Blob reportFile = ReportRunnerService.runReportForOwners(
                (Id) config.Report_Id__c,
                config.Owner_Report_Column_Name__c,
                ownerNames,
                config.Grouping_Report_Column_Names__c,
                config.Account_Number_Report_Column_Name__c
            );

            String subject = '[SAMPLE] ' + EmailSubjectBuilder.build(config.Email_Subject__c, config.Subject_Date_Format__c, Date.today());
            if (String.isNotBlank(personalizedNameForSubject)) {
                subject += ' - ' + personalizedNameForSubject;
            }

            Messaging.SingleEmailMessage email = ReportReminderEmailBuilder.build(
                recipientEmail,
                ccEmails,
                subject,
                config.Email_Body_Text__c,
                config.Label,
                reportFile,
                String.isNotBlank(config.Org_Wide_Email_Address_Id__c) ? (Id) config.Org_Wide_Email_Address_Id__c : null
            );

            result = send(email, recipientEmail, ccEmails != null && !ccEmails.isEmpty() ? String.join(ccEmails, ', ') : null);
            if (result.success) {
                result.message += ' (owners filtered: ' + String.join(ownerNames, ', ') + ')';
            }
        } catch (Exception ex) {
            result.success = false;
            result.message = ex.getMessage();
        }

        return result;
    }

    public static DemoSendResult sendSampleNowForTeamLeadRedirected(String configDeveloperName, Id teamLeadId, String redirectToEmail) {
        DemoSendResult result = new DemoSendResult();

        Report_Reminder_Config__mdt config = getConfig(configDeveloperName);
        if (config == null) {
            result.success = false;
            result.message = 'No Report_Reminder_Config__mdt found with DeveloperName ' + configDeveloperName;
            return result;
        }

        User teamLead = [SELECT Id, Name, Email FROM User WHERE Id = :teamLeadId LIMIT 1];
        List<User> directReports = [SELECT Id, Name, Email FROM User WHERE ManagerId = :teamLeadId AND IsActive = true];

        if (directReports.isEmpty()) {
            result.success = false;
            result.message = 'This user has no active direct reports (ManagerId match) - nothing to redirect-test. '
                + 'Use sendSampleNowCustomRedirected() instead to simulate a recipient without real hierarchy.';
            return result;
        }

        List<String> ownerNames = new List<String>();
        List<String> ownerEmails = new List<String>();
        for (User u : directReports) {
            ownerNames.add(u.Name);
            if (String.isNotBlank(u.Email)) {
                ownerEmails.add(u.Email);
            }
        }

        String simulatedRecipientLabel = teamLead.Name + ' (' + teamLead.Email + ')'
            + ' | Would also CC: ' + (ownerEmails.isEmpty() ? '(none)' : String.join(ownerEmails, ', '));
        return sendRedirectedInternal(config, redirectToEmail, simulatedRecipientLabel, ownerNames, teamLead.Name);
    }

    public static DemoSendResult sendSampleNowCustomRedirected(
        String configDeveloperName,
        String redirectToEmail,
        String simulatedRecipientLabel,
        List<String> ownerNamesToFilter
    ) {
        Report_Reminder_Config__mdt config = getConfig(configDeveloperName);
        if (config == null) {
            DemoSendResult result = new DemoSendResult();
            result.success = false;
            result.message = 'No Report_Reminder_Config__mdt found with DeveloperName ' + configDeveloperName;
            return result;
        }
        return sendRedirectedInternal(config, redirectToEmail, simulatedRecipientLabel, ownerNamesToFilter, null);
    }

    private static DemoSendResult sendRedirectedInternal(
        Report_Reminder_Config__mdt config,
        String redirectToEmail,
        String simulatedRecipientLabel,
        List<String> ownerNames,
        String personalizedNameForSubject
    ) {
        DemoSendResult result = new DemoSendResult();

        try {
            Blob reportFile = ReportRunnerService.runReportForOwners(
                (Id) config.Report_Id__c,
                config.Owner_Report_Column_Name__c,
                ownerNames,
                config.Grouping_Report_Column_Names__c,
                config.Account_Number_Report_Column_Name__c
            );

            String subject = '[REDIRECTED TEST] ' + EmailSubjectBuilder.build(config.Email_Subject__c, config.Subject_Date_Format__c, Date.today());
            if (String.isNotBlank(personalizedNameForSubject)) {
                subject += ' - ' + personalizedNameForSubject;
            }

            String redirectNotice = 'This is a TEST send. In production, this email would have gone to: '
                + simulatedRecipientLabel + ', covering ' + ownerNames.size()
                + ' owner(s): ' + String.join(ownerNames, ', ') + '.';

            Messaging.SingleEmailMessage email = ReportReminderEmailBuilder.build(
                redirectToEmail,
                null,
                subject,
                config.Email_Body_Text__c,
                config.Label,
                reportFile,
                String.isNotBlank(config.Org_Wide_Email_Address_Id__c) ? (Id) config.Org_Wide_Email_Address_Id__c : null,
                redirectNotice
            );

            result = send(email, redirectToEmail, null);
            if (result.success) {
                result.message += ' | Real recipient would have been: ' + simulatedRecipientLabel;
            }
        } catch (Exception ex) {
            result.success = false;
            result.message = ex.getMessage();
        }

        return result;
    }

    public static DemoSendResult sendAllSampleNowRedirected(String configDeveloperName, String redirectToEmail) {
        DemoSendResult result = new DemoSendResult();

        Report_Reminder_Config__mdt config = getConfig(configDeveloperName);
        if (config == null) {
            result.success = false;
            result.message = 'No Report_Reminder_Config__mdt found with DeveloperName ' + configDeveloperName;
            return result;
        }

        Set<String> ownerNamesWithData = ReportRunnerService.discoverOwnersWithData(
            (Id) config.Report_Id__c,
            config.Owner_Report_Column_Name__c
        );

        if (ownerNamesWithData.isEmpty()) {
            result.success = false;
            result.message = 'The report currently has no qualifying rows for any owner - nothing to send.';
            return result;
        }

        List<User> owners = [SELECT Id, Name, Email, ManagerId FROM User WHERE Name IN :ownerNamesWithData AND IsActive = true];

        Map<Id, List<String>> ownerNamesByTeamLead = new Map<Id, List<String>>();
        Map<Id, List<String>> ownerEmailsByTeamLead = new Map<Id, List<String>>();
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

        if (ownerNamesByTeamLead.isEmpty()) {
            result.success = false;
            result.message = 'Found owners with qualifying report data, but none have an active Manager set - nothing to send.';
            return result;
        }

        Set<Id> managerIds = ownerNamesByTeamLead.keySet();
        List<User> teamLeads = [SELECT Id, Name, Email FROM User WHERE Id IN :managerIds AND IsActive = true LIMIT 11];
        Boolean truncated = teamLeads.size() > 10;
        if (truncated) {
            teamLeads.remove(10);
        }

        if (teamLeads.isEmpty()) {
            result.success = false;
            result.message = 'Found owners with qualifying report data, but none of their Managers are active Users - nothing to send.';
            return result;
        }

        String baseSubject = EmailSubjectBuilder.build(config.Email_Subject__c, config.Subject_Date_Format__c, Date.today());
        Id owaId = String.isNotBlank(config.Org_Wide_Email_Address_Id__c) ? (Id) config.Org_Wide_Email_Address_Id__c : null;

        List<Messaging.SingleEmailMessage> emailsToSend = new List<Messaging.SingleEmailMessage>();
        List<String> teamLeadSummaries = new List<String>();
        List<String> teamLeadNamesForSend = new List<String>();

        for (User teamLead : teamLeads) {
            List<String> ownerNames = ownerNamesByTeamLead.get(teamLead.Id);
            if (ownerNames == null || ownerNames.isEmpty()) {
                continue;
            }
            List<String> ownerEmails = ownerEmailsByTeamLead.get(teamLead.Id);

            try {
                Blob reportFile = ReportRunnerService.runReportForOwners(
                    (Id) config.Report_Id__c, config.Owner_Report_Column_Name__c, ownerNames,
                    config.Grouping_Report_Column_Names__c, config.Account_Number_Report_Column_Name__c
                );

                String redirectNotice = 'This is a TEST send. In production, this email would have gone to: '
                    + teamLead.Name + ' (' + teamLead.Email + '), covering ' + ownerNames.size()
                    + ' owner(s): ' + String.join(ownerNames, ', ') + '. Would also CC: '
                    + (ownerEmails == null || ownerEmails.isEmpty() ? '(none)' : String.join(ownerEmails, ', ')) + '.';

                Messaging.SingleEmailMessage email = ReportReminderEmailBuilder.build(
                    redirectToEmail, null, '[REDIRECTED TEST] ' + baseSubject + ' - ' + teamLead.Name,
                    config.Email_Body_Text__c, config.Label, reportFile, owaId, redirectNotice
                );
                emailsToSend.add(email);
                teamLeadNamesForSend.add(teamLead.Name);
            } catch (Exception ex) {
                teamLeadSummaries.add(teamLead.Name + ' [FAILED TO BUILD: ' + ex.getMessage() + ']');
            }
        }

        if (emailsToSend.isEmpty()) {
            result.success = false;
            result.message = 'Found team leads but building their report attachments failed for all of them: '
                + String.join(teamLeadSummaries, '; ');
            return result;
        }

        Messaging.SendEmailResult[] sendResults = Messaging.sendEmail(emailsToSend, false);
        Integer successCount = 0;
        for (Integer i = 0; i < sendResults.size(); i++) {
            Messaging.SendEmailResult sr = sendResults[i];
            String teamLeadName = teamLeadNamesForSend[i];
            if (sr.isSuccess()) {
                successCount++;
                teamLeadSummaries.add(teamLeadName);
            } else {
                List<String> sendErrorMessages = new List<String>();
                for (Messaging.SendEmailError err : sr.getErrors()) {
                    sendErrorMessages.add(err.getStatusCode() + ': ' + err.getMessage());
                }
                teamLeadSummaries.add(teamLeadName + ' [SEND FAILED: ' + String.join(sendErrorMessages, ' | ') + ']');
            }
        }

        result.success = successCount > 0;
        result.message = successCount + '/' + emailsToSend.size() + ' emails sent to ' + redirectToEmail
            + '. Team leads covered: ' + String.join(teamLeadSummaries, '; ')
            + (truncated ? ' | ⚠️ There are MORE than 10 eligible team leads - only the first 10 were processed (synchronous email cap).' : '');

        return result;
    }

    private static DemoSendResult send(Messaging.SingleEmailMessage email, String toAddress, String ccAddress) {
        DemoSendResult result = new DemoSendResult();

        Messaging.SendEmailResult[] sendResults = Messaging.sendEmail(
            new List<Messaging.SingleEmailMessage>{ email },
            false
        );

        if (sendResults[0].isSuccess()) {
            result.success = true;
            result.message = 'Sample sent to ' + toAddress + (String.isNotBlank(ccAddress) ? ' (cc: ' + ccAddress + ')' : '');
        } else {
            result.success = false;
            result.message = sendResults[0].getErrors()[0].getMessage();
        }

        return result;
    }
}