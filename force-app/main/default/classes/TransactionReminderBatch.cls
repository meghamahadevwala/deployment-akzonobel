/**
 * Batch class to process transactions and calculate reminder-related fields
 * based on related events.
 * 
 * Fields calculated:
 * - Number_Of_Reminders__c: Count of events that include this transaction
 * - Last_Reminder_Date__c: Date of the most recent event with type "reminder"
 * - Gaps_Between_Reminders__c: Average gap between reminder events
 * - Number_Of_Pre_Due_Reminders__c: Count of reminders sent before invoice closing date
 * - Last_Pre_Due_Reminder_Date__c: Date of the last reminder sent before closing date
 */
public class TransactionReminderBatch implements Database.Batchable<sObject>, Database.Stateful {
    
    private Id accountId;
    
    // Cached reminder filters
    private String reminderNameWhereClause;

    public TransactionReminderBatch(Id accountId) {
        this.accountId = accountId;
        this.reminderNameWhereClause = UtilityController.getReminderEventsConfiguration();
    }
    
    public TransactionReminderBatch() {
        this(null);
    }
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        // Calculate date 6 months ago
        Date sixMonthsAgo = Date.today().addMonths(-6);

        // product level opt -- put amount and posting key (doc type etc) to custom listview
        // Ravi - Need to clarify: we need to calculate for only open invoice. because on close invoice no one can send reminder.
        String query = 'SELECT Id, celsrm__Account__c, Number_Of_Reminders__c, ' +
                      'Last_Reminder_Date__c, Gaps_Between_Reminders__c, ' +
                      'celsrm__Amount__c, celsrm__Posting_Key__c, Status__c, celsrm__Create_Date__c, ' +
                      'celsrm__Close_Date__c, Number_Of_Pre_Due_Reminders__c, Last_Pre_Due_Reminder_Date__c,celsrm__Due_Date__c ' +
                      'FROM celsrm__Transaction__c ' +
                      'WHERE celsrm__Amount__c > 100 ' +
                    //   'AND Status__c = \'Closed\' ' +
                    //'AND Close_Date__c >= :sixMonthsAgo ' +
                      'AND celsrm__Posting_Key__c = \'01\'';
        
        if (accountId != null) {
            query += ' AND celsrm__Account__c = :accountId';
        }
        
        return Database.getQueryLocator(query);
    }
    
    /**
     * Execute method - processes each batch of transactions
     */
    public void execute(Database.BatchableContext bc, List<sObject> scope) {

        List<celsrm__Transaction__c> invoices =
            (List<celsrm__Transaction__c>) scope;

        Set<Id> invoiceIds = new Set<Id>();
        for (celsrm__Transaction__c i : invoices) {
            invoiceIds.add(i.Id);
        }

        Map<Id, List<celsrm__Celonis_Event__c>> eventsByInvoice =
            groupEventsByInvoice(queryReminderEvents(invoiceIds));

        System.debug('$:eventsByInvoice ' + eventsByInvoice);
        System.debug('$invoices'+ invoices);

        List<celsrm__Transaction__c> updates = new List<celsrm__Transaction__c>();

        for (celsrm__Transaction__c inv : invoices) {
            List<celsrm__Celonis_Event__c> reminders =
                eventsByInvoice.get(inv.Id);
            List<celsrm__Celonis_Event__c> remindersPostDueDate =
                filterEventsByDueDate(reminders, inv.celsrm__Due_Date__c);

            if (reminders == null || reminders.isEmpty()) {
                inv.Number_Of_Reminders__c = 0;
                inv.Last_Reminder_Date__c = null;
                inv.Gaps_Between_Reminders__c = null;
                inv.Number_Of_Pre_Due_Reminders__c = null;
                inv.Last_Pre_Due_Reminder_Date__c = null;
            } else {
                applyReminderMetrics(inv, reminders,remindersPostDueDate);
            }

            updates.add(inv);
        }

        System.debug('$$eventsByInvoice: ' + eventsByInvoice);
        System.debug('$$invoices: ' + invoices);
        System.debug('$$updates: ' + updates);

        if (!updates.isEmpty()) {
            update updates;
        }
    }
    
    /**
     * Helper class to sort events by ActivityDate
     */
    private void applyReminderMetrics(
        celsrm__Transaction__c inv,
        List<celsrm__Celonis_Event__c> reminders,
        List<celsrm__Celonis_Event__c> remindersPostDueDate
    ) {
        inv.Number_Of_Reminders__c = remindersPostDueDate.size();

        // Last reminder date
        inv.Last_Reminder_Date__c =
        remindersPostDueDate.isEmpty()
            ? null
            : remindersPostDueDate[remindersPostDueDate.size() - 1]
                .celsrm__Event_Time__c.date();

        // Gaps
        if (remindersPostDueDate.size() > 1) {
            Decimal totalGap = 0;
            Integer count = 0;

            for (Integer i = 1; i < remindersPostDueDate.size(); i++) {
                Date d1 = remindersPostDueDate[i - 1].celsrm__Event_Time__c.date();
                Date d2 = remindersPostDueDate[i].celsrm__Event_Time__c.date();
                if (d1 != null && d2 != null) {
                    totalGap += d1.daysBetween(d2);
                    count++;
                }
            }
            inv.Gaps_Between_Reminders__c =
                count > 0 ? Math.ceil(totalGap / count) : null;
        } else {
            inv.Gaps_Between_Reminders__c = null;
        }

        // Pre-due reminders
        Date dueDate = inv.celsrm__Due_Date__c;
        Integer preDueCount = 0;
        Date lastPreDueDate;

        if (dueDate != null) {
            for (celsrm__Celonis_Event__c r : reminders) {
                Date rd = r.celsrm__Event_Time__c.date();
                if (rd != null && rd <= dueDate) {
                    preDueCount++;
                    if (lastPreDueDate == null || rd > lastPreDueDate) {
                        lastPreDueDate = rd;
                    }
                }
            }
        }

        inv.Number_Of_Pre_Due_Reminders__c =
            preDueCount > 0 ? preDueCount : null;
        inv.Last_Pre_Due_Reminder_Date__c = lastPreDueDate;
    }

    private Map<Id, List<celsrm__Celonis_Event__c>>
    groupEventsByInvoice(List<celsrm__Celonis_Event__c> events) {

        Map<Id, List<celsrm__Celonis_Event__c>> result = new Map<Id, List<celsrm__Celonis_Event__c>>();

        for (celsrm__Celonis_Event__c e : events) {
            if (!result.containsKey(e.celsrm__Transaction__c)) {
                result.put(e.celsrm__Transaction__c,
                           new List<celsrm__Celonis_Event__c>());
            }
            result.get(e.celsrm__Transaction__c).add(e);
        }
        return result;
    }

    private List<celsrm__Celonis_Event__c>
    queryReminderEvents(Set<Id> invoiceIds) {

        if(invoiceIds == null || invoiceIds.isEmpty()) {
            return new List<celsrm__Celonis_Event__c>();
        }

        String q =
            'SELECT Id, celsrm__Transaction__c, celsrm__Event_Time__c, Name ' +
            'FROM celsrm__Celonis_Event__c ' +
            'WHERE celsrm__Transaction__c IN :invoiceIds ' ;

        if(String.isNotBlank(reminderNameWhereClause)){
            q += reminderNameWhereClause;
        }
        q+= ' ORDER BY celsrm__Transaction__c, celsrm__Event_Time__c ASC';

        return Database.query(q);
    }

    private List<celsrm__Celonis_Event__c> filterEventsByDueDate(
    List<celsrm__Celonis_Event__c> reminders,
    Date dueDate
    ) {
        List<celsrm__Celonis_Event__c> result =
            new List<celsrm__Celonis_Event__c>();

        if (reminders == null || reminders.isEmpty() || dueDate == null) {
            return result;
        }

        for (celsrm__Celonis_Event__c r : reminders) {
            if (r.celsrm__Event_Time__c == null) {
                continue;
            }

            Date reminderDate = r.celsrm__Event_Time__c.date();
            if (reminderDate != null && reminderDate > dueDate) {
                result.add(r);
            }
        }

        return result;
    }

        /**
     * Finish method - called after all batches are processed
     */
    public void finish(Database.BatchableContext bc) {        
    }

}