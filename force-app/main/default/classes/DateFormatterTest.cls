// << START - MM - FIN-10130 - New test class created to cover DateFormatter branches (Object overload, all country format groups, pad2, default fallback) >>
@isTest
private class DateFormatterTest {

    @isTest
    static void testFormatDueDateObjectOverload_withDate() {
        Date d = Date.newInstance(2024, 3, 5);
        String result = DateFormatter.formatDueDate((Object) d, (Object) 'US');
        System.assertEquals('03/05/2024', result, 'Date instanceof branch should format using US pattern');
    }

    @isTest
    static void testFormatDueDateObjectOverload_withDatetime() {
        Datetime dt = Datetime.newInstance(2023, 12, 25, 10, 30, 0);
        String result = DateFormatter.formatDueDate((Object) dt, (Object) 'DE');
        System.assertEquals('25.12.2023', result, 'Datetime instanceof branch should convert to Date and format using DE pattern');
    }

    @isTest
    static void testFormatDueDateObjectOverload_withStringLikeObject() {
        // Not a Date, not a Datetime, not null -> exercises Date.valueOf(String.valueOf(...)) branch
        String dateAsString = '2022-01-15';
        String result = DateFormatter.formatDueDate((Object) dateAsString, (Object) 'CA');
        System.assertEquals('2022-01-15', result, 'Generic object branch should parse via Date.valueOf and format using CA pattern (YYYY-MM-DD)');
    }

    @isTest
    static void testFormatDueDateObjectOverload_withNullDateAndNullCountry() {
        String result = DateFormatter.formatDueDate((Object) null, (Object) null);
        System.assertEquals(null, result, 'Null date object should propagate to null dueDate and return null');
    }

    @isTest
    static void testFormatDueDate_nullDate() {
        String result = DateFormatter.formatDueDate((Date) null, 'US');
        System.assertEquals(null, result, 'Null date should short-circuit to null regardless of country code');
    }

    @isTest
    static void testFormatDueDate_blankCountryCode() {
        Date d = Date.newInstance(2024, 6, 7);
        System.assertEquals(String.valueOf(d), DateFormatter.formatDueDate(d, null), 'Null country code should default to String.valueOf(date)');
        System.assertEquals(String.valueOf(d), DateFormatter.formatDueDate(d, '   '), 'Blank/whitespace country code should default to String.valueOf(date)');
        System.assertEquals(String.valueOf(d), DateFormatter.formatDueDate(d, ''), 'Empty country code should default to String.valueOf(date)');
    }

    @isTest
    static void testFormatDueDate_ddDotMmDotYyyy() {
        Date d = Date.newInstance(2024, 3, 5); // single digit day & month -> exercises pad2 zero-pad branch
        String result = DateFormatter.formatDueDate(d, 'de'); // lowercase to exercise trim().toUpperCase()
        System.assertEquals('05.03.2024', result, 'DE should map to DD.MM.YYYY with zero-padded day/month');
    }

    @isTest
    static void testFormatDueDate_ddSlashMmSlashYyyy() {
        Date d = Date.newInstance(2024, 11, 22); // double digit day & month -> exercises pad2 no-pad branch
        String result = DateFormatter.formatDueDate(d, ' FR '); // surrounding whitespace to exercise trim()
        System.assertEquals('22/11/2024', result, 'FR should map to DD/MM/YYYY');
    }

    @isTest
    static void testFormatDueDate_ddDashMmDashYyyy() {
        Date d = Date.newInstance(2024, 2, 29); // leap year edge case
        String result = DateFormatter.formatDueDate(d, 'NL');
        System.assertEquals('29-02-2024', result, 'NL should map to DD-MM-YYYY and handle leap day correctly');
    }

    @isTest
    static void testFormatDueDate_mmSlashDdSlashYyyy() {
        Date d = Date.newInstance(2024, 7, 4);
        String result = DateFormatter.formatDueDate(d, 'US');
        System.assertEquals('07/04/2024', result, 'US should map to MM/DD/YYYY');
    }

    @isTest
    static void testFormatDueDate_yyyyDotMmDotDd() {
        Date d = Date.newInstance(2024, 1, 9);
        String result = DateFormatter.formatDueDate(d, 'KR');
        System.assertEquals('2024.01.09', result, 'KR should map to YYYY.MM.DD');
    }

    @isTest
    static void testFormatDueDate_yyyySlashMmSlashDd() {
        Date d = Date.newInstance(2024, 10, 31);
        String result = DateFormatter.formatDueDate(d, 'JP');
        System.assertEquals('2024/10/31', result, 'JP should map to YYYY/MM/DD');
    }

    @isTest
    static void testFormatDueDate_yyyyDashMmDashDd() {
        Date d = Date.newInstance(2024, 12, 1);
        String result = DateFormatter.formatDueDate(d, 'CA');
        System.assertEquals('2024-12-01', result, 'CA should map to YYYY-MM-DD');
    }

    @isTest
    static void testFormatDueDate_unrecognizedCountryCode_defaultsToStringValueOf() {
        Date d = Date.newInstance(2024, 5, 17);
        String result = DateFormatter.formatDueDate(d, 'ZZ'); // not present in COUNTRY_TO_FORMAT map
        System.assertEquals(String.valueOf(d), result, 'Unrecognized country code should fall through all branches to default String.valueOf(dueDate)');
    }
}
// << END - MM - FIN-10130 - New test class created to cover DateFormatter branches (Object overload, all country format groups, pad2, default fallback) >>