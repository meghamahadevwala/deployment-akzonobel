/**
 * Builds email subjects like "Child Account Set Up w/o Parent 08/2026"
 * (Subject_Date_Format__c = 'MM/YYYY') or "Open and Pending Credit Limit
 * Request 8/10/2026" (Subject_Date_Format__c = 'Date').
 */
public with sharing class EmailSubjectBuilder {

    public static String build(String reportLabel, String dateFormat, Date asOf) {
        if (dateFormat == 'MM/YYYY') {
            return reportLabel + ' ' + formatMonthYear(asOf);
        }
        if (dateFormat == 'Date') {
            return reportLabel + ' ' + asOf.format();
        }
        return reportLabel; // no date suffix configured
    }

    private static String formatMonthYear(Date d) {
        String mm = String.valueOf(d.month()).leftPad(2, '0');
        return mm + '/' + String.valueOf(d.year());
    }
}