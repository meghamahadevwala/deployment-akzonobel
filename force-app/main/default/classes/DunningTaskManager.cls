public with sharing class DunningTaskManager {

    public static Boolean shouldCreateDunningTask(Account accountRecord, celsrm__Treatment__c treatment) {
        if (accountRecord != null && accountRecord.celsrm__Total_AR__c <= 0) {
            return false;
        }

        String strategy = treatment.celsrm__Dunning_Strategy__c;
        if (strategy != null && strategy.toLowerCase().contains('reactive')) {
             return shouldCreateReactiveDunningTask(accountRecord, treatment);
        } else if (strategy != null && strategy.toLowerCase().contains('proactive')) {
             return shouldCreateProactiveDunningTask(accountRecord);
        }
        
        return false;
    }

    // public static Boolean isTotalARNegative(Id accountId) {
    //     if (accountId == null) return false;
        
    //     AggregateResult[] groupedResults = [SELECT SUM(Amount__c)total FROM Transaction__c WHERE Account__c = :accountId AND Close_Date__c = null];
    //     Decimal totalBalance = (Decimal)groupedResults[0].get('total');
        
    //     return totalBalance != null && totalBalance <= 0;
    // }

    public static Boolean shouldCreateReactiveDunningTask(Account accountRecord, celsrm__Treatment__c treatment) {
        if (accountRecord == null || accountRecord.Id == null) {
            throw new AuraHandledException('Account is required and must have an Id.');
        }

        List<Date> paymentDates = new List<Date>();
        if (accountRecord.Predicted_Payment_Dates__c != null) {
            String predictedPaymentDatesStr = String.valueOf(accountRecord.Predicted_Payment_Dates__c);
            paymentDates = UtilityController.parseDateListFromString(predictedPaymentDatesStr, '\\|');
        }

        if (paymentDates.isEmpty()) {
            return false;
        }

        Date today = Date.today();

        Date latestPastDate = null;
        for (Date d : paymentDates) {
            if (d <= today && (latestPastDate == null || d > latestPastDate)) {
                latestPastDate = d;
            }
        }

        if (latestPastDate == null) {
            return false;
        }

        Date lastPaymentDate = accountRecord.Last_Payment_Date__c;
        if (lastPaymentDate != null && lastPaymentDate >= latestPastDate) {
            return false;
        }

        Decimal avgPaymentTerm = accountRecord.Avg_Payment_Term__c != null
            ? accountRecord.Avg_Payment_Term__c : 14;
        Integer graceDays = (Integer) Math.ceil(avgPaymentTerm * 0.25);

        Date reminderDate = latestPastDate.addDays(graceDays);
        return today >= reminderDate;
    }

    public static Boolean shouldCreateProactiveDunningTask(Account accountRecord) {
        if (accountRecord == null || accountRecord.Id == null) {
            throw new AuraHandledException('Account is required and must have an Id.');
        }

        Integer dunningFreq = accountRecord.AI_Dunning_Frequency__c != null ? accountRecord.AI_Dunning_Frequency__c.intValue()  : null;
        Date lastReminderDate = null;
        if (accountRecord.Last_Dunning_Reminder_Date__c != null) lastReminderDate = accountRecord.Last_Dunning_Reminder_Date__c;

        Date today = Date.today();
        Integer dayIncrement = (dunningFreq != null && dunningFreq > 0) ? dunningFreq : 28;


        Boolean shouldCreateTask = lastReminderDate == null || (lastReminderDate != null && today == lastReminderDate.addDays(dayIncrement));
        return shouldCreateTask;
    }

}