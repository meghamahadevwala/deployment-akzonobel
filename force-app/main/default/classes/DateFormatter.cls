public with sharing class DateFormatter {
    private static final String F_DD_DOT_MM_DOT_YYYY = 'DD.MM.YYYY';
    private static final String F_DD_SLASH_MM_SLASH_YYYY = 'DD/MM/YYYY';
    private static final String F_DD_DASH_MM_DASH_YYYY = 'DD-MM-YYYY';
    private static final String F_MM_SLASH_DD_SLASH_YYYY = 'MM/DD/YYYY';
    private static final String F_YYYY_DOT_MM_DOT_DD = 'YYYY.MM.DD';
    private static final String F_YYYY_SLASH_MM_SLASH_DD = 'YYYY/MM/DD';
    private static final String F_YYYY_DASH_MM_DASH_DD = 'YYYY-MM-DD';

    private static final Map<String, String> COUNTRY_TO_FORMAT = buildCountryToFormat();

    public static String formatDueDate(Object dueDateObj, Object countryCodeObj) {
        Date dueDateVal;
        if (dueDateObj instanceof Date) {
            dueDateVal = (Date) dueDateObj;
        } else if (dueDateObj instanceof Datetime) {
            dueDateVal = ((Datetime) dueDateObj).date();
        } else if (dueDateObj != null) {
            dueDateVal = Date.valueOf(String.valueOf(dueDateObj));
        }
        String countryCode = countryCodeObj == null ? null : String.valueOf(countryCodeObj);
        return formatDueDate(dueDateVal, countryCode);
    }


    public static String formatDueDate(Date dueDate, String countryCode) {
        if (dueDate == null) return null;
        if (String.isBlank(countryCode)) return String.valueOf(dueDate); // default

        String cc = countryCode.trim().toUpperCase();
        String formatKey = COUNTRY_TO_FORMAT.get(cc);

        Integer day = dueDate.day();
        Integer month = dueDate.month();
        Integer year = dueDate.year();

        if (formatKey == F_DD_DOT_MM_DOT_YYYY) {
            return pad2(day) + '.' + pad2(month) + '.' + String.valueOf(year);
        } else if (formatKey == F_DD_SLASH_MM_SLASH_YYYY) {
            return pad2(day) + '/' + pad2(month) + '/' + String.valueOf(year);
        } else if (formatKey == F_DD_DASH_MM_DASH_YYYY) {
            return pad2(day) + '-' + pad2(month) + '-' + String.valueOf(year);
        } else if (formatKey == F_MM_SLASH_DD_SLASH_YYYY) {
            return pad2(month) + '/' + pad2(day) + '/' + String.valueOf(year);
        } else if (formatKey == F_YYYY_DOT_MM_DOT_DD) {
            return String.valueOf(year) + '.' + pad2(month) + '.' + pad2(day);
        } else if (formatKey == F_YYYY_SLASH_MM_SLASH_DD) {
            return String.valueOf(year) + '/' + pad2(month) + '/' + pad2(day);
        } else if (formatKey == F_YYYY_DASH_MM_DASH_DD) {
            return String.valueOf(year) + '-' + pad2(month) + '-' + pad2(day);
        }

        return String.valueOf(dueDate); // default
    }

    private static String pad2(Integer n) {
        return (n < 10 ? '0' : '') + String.valueOf(n);
    }

    private static Map<String, String> buildCountryToFormat() {
        Map<String, String> m = new Map<String, String>();

        addCountries(m, F_DD_DOT_MM_DOT_YYYY, new Set<String>{
            'AL','AM','AT','AZ','BA','BG','BY','CH','CZ','DE','EE','FI','GE','HR','IS','KG','KZ','LV','MD','ME','MK','NO','PL','RO','RS','RU','SI','SK','TJ','TM','TR','UA','UZ'
        });

        addCountries(m, F_DD_SLASH_MM_SLASH_YYYY, new Set<String>{
            'AD','AE','AF','AO','AR','AU','BE','BF','BH','BI','BJ','BN','BO','BS','BT','BZ','CD','CF','CG','CL','CM','CO','CR','CU','CV','CY','DJ','DO','DZ','EC','EG','ES','ET','FR','GA','GB','GH','GM','GN','GR','GT','GY','HN','HT','ID','IE','IL','IQ','IR','IT','JM','JO','KE','KH','KM','KW','LA','LB','LK','LR','LU','LY','MA','MC','MG','ML','MM','MR','MT','MU','MW','MX','MY','MZ','NE','NG','NI','NP','NZ','OM','PA','PE','PK','PT','PY','QA','RW','SA','SC','SD','SG','SL','SN','SO','SV','SY','TD','TG','TH','TN','TT','TZ','UG','UY','VE','VN','YE','ZM','ZW'
        });

        addCountries(m, F_DD_DASH_MM_DASH_YYYY, new Set<String>{'BD','DK','IN','NL','BR'});
        addCountries(m, F_MM_SLASH_DD_SLASH_YYYY, new Set<String>{'PH','US'});
        addCountries(m, F_YYYY_DOT_MM_DOT_DD, new Set<String>{'HU','KP','KR','MN'});
        addCountries(m, F_YYYY_SLASH_MM_SLASH_DD, new Set<String>{'BW','JP','LS','NA','TW','ZA'});
        addCountries(m, F_YYYY_DASH_MM_DASH_DD, new Set<String>{'CA','CN','LT','SE'});

        return m;
    }

    private static void addCountries(Map<String, String> mapRef, String formatKey, Set<String> countries) {
        for (String c : countries) {
            mapRef.put(c, formatKey);
        }
    }
}