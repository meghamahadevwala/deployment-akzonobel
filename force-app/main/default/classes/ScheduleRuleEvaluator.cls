/**
 * Evaluates Report_Reminder_Config__mdt scheduling rules against a given
 * date (expected to already be "today" in the target timezone - see
 * ReportReminderScheduler, which resolves CET/CEST before calling this).
 *
 * Supported Frequency__c values: Weekly, Biweekly, Monthly.
 *
 * For Monthly, two mutually exclusive sub-rules are supported via Day_Of_Week__c:
 *   - Day_Of_Week__c = '1WD'  -> first working day (Mon-Fri) of the month
 *   - Day_Of_Week__c = 'Monday'..'Sunday' + Week_Of_Month__c (1-5)
 *     -> Nth occurrence of that weekday in the month (e.g. 2nd Monday)
 */
public with sharing class ScheduleRuleEvaluator {

    public static Boolean isDueToday(Report_Reminder_Config__mdt config, Date today) {
        if (config.Frequency__c == 'Weekly') {
            return matchesDayOfWeek(today, config.Day_Of_Week__c);
        }

        if (config.Frequency__c == 'Biweekly') {
            if (config.Biweekly_Anchor_Date__c == null || !matchesDayOfWeek(today, config.Day_Of_Week__c)) {
                return false;
            }
            Integer daysSinceAnchor = config.Biweekly_Anchor_Date__c.daysBetween(today);
            return daysSinceAnchor >= 0 && Math.mod(daysSinceAnchor, 14) == 0;
        }

        if (config.Frequency__c == 'Monthly') {
            if (config.Day_Of_Week__c == '1WD') {
                return today == firstWorkingDayOfMonth(today);
            }
            if (config.Week_Of_Month__c != null && String.isNotBlank(config.Day_Of_Week__c)) {
                Date nth = nthWeekdayOfMonth(today, config.Day_Of_Week__c, Integer.valueOf(config.Week_Of_Month__c));
                return nth != null && today == nth;
            }
        }

        return false;
    }

    private static Boolean matchesDayOfWeek(Date d, String dayOfWeekLabel) {
        if (d == null || String.isBlank(dayOfWeekLabel)) {
            return false;
        }
        return dayLabel(d) == dayOfWeekLabel;
    }

    private static String dayLabel(Date d) {
        return Datetime.newInstance(d, Time.newInstance(0, 0, 0, 0)).format('EEEE');
    }

    private static Boolean isWeekend(Date d) {
        String label = dayLabel(d);
        return label == 'Saturday' || label == 'Sunday';
    }

    private static Date firstWorkingDayOfMonth(Date anyDayInMonth) {
        Date d = Date.newInstance(anyDayInMonth.year(), anyDayInMonth.month(), 1);
        while (isWeekend(d)) {
            d = d.addDays(1);
        }
        return d;
    }

    private static Date nthWeekdayOfMonth(Date anyDayInMonth, String dayOfWeekLabel, Integer n) {
        Date d = Date.newInstance(anyDayInMonth.year(), anyDayInMonth.month(), 1);
        Integer count = 0;
        while (d.month() == anyDayInMonth.month()) {
            if (dayLabel(d) == dayOfWeekLabel) {
                count++;
                if (count == n) {
                    return d;
                }
            }
            d = d.addDays(1);
        }
        return null; // e.g. asked for 5th Monday and the month only has 4
    }
}