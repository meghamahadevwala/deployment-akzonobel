public with sharing class ReportReminderScheduler implements Schedulable {
    private static final String TARGET_TIMEZONE = 'Europe/Berlin'; // CET (UTC+1) / CEST (UTC+2)
    public void execute(SchedulableContext sc) {
        Datetime nowUtc = Datetime.now();
        String currentCetHourMinute = nowUtc.format('HH:mm', TARGET_TIMEZONE);
        Date todayCet = Date.valueOf(nowUtc.format('yyyy-MM-dd', TARGET_TIMEZONE));
        List<Report_Reminder_Config__mdt> configs = [
            SELECT DeveloperName, Label, Report_Id__c, Frequency__c, Day_Of_Week__c,
                   Week_Of_Month__c, Biweekly_Anchor_Date__c, Send_Hour_CET__c,
                   Email_Subject__c, Email_Body_Text__c, Subject_Date_Format__c,
                   Owner_Report_Column_Name__c,
                   Org_Wide_Email_Address_Id__c,
                   Recipient_Mode__c, Active__c
            FROM Report_Reminder_Config__mdt
            WHERE Active__c = true
        ];
        for (Report_Reminder_Config__mdt config : configs) {
            if (String.isBlank(config.Send_Hour_CET__c) || config.Send_Hour_CET__c != currentCetHourMinute) {
                continue; // not this config's target hour
            }
            if (!ScheduleRuleEvaluator.isDueToday(config, todayCet)) {
                continue;
            }
            dispatch(config);
        }
    }
    private void dispatch(Report_Reminder_Config__mdt config) {
        if (config.Recipient_Mode__c == 'TeamLead_Only') {
            Database.executeBatch(new TeamLeadReportBatch(config), 25);
        } else {
            // Default: Owner_With_TeamLead_CC (original ticket #816 behavior)
            Database.executeBatch(new ReportReminderBatch(config), 50);
        }
    }
}