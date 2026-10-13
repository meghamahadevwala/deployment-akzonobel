/**
 * Generates randomized Moody's (BvD Orbis) responses for end-to-end stress testing
 * in sandboxes where the real Moody's endpoint is not reachable.
 * Also implements HttpCalloutMock so it can be reused from unit tests via Test.setMock.
 */
public with sharing class MoodysMockResponseGenerator implements HttpCalloutMock {

    // One-off stress test switch: set to true, deploy to UAT, run, then revert
    private static final Boolean MOCK_ENABLED = true;

    // Scenario probabilities (percent)
    @TestVisible private static Integer missingCompanyRatePct = 5; // BvD ID not returned by Moody's
    @TestVisible private static Integer nullFieldRatePct = 15;     // a given score block comes back empty
    @TestVisible private static Integer staleDateRatePct = 20;     // score date older than 2 years
    @TestVisible private static Integer badIncorporationRatePct = 2; // incorporation year < 1700 (FIN-8657)

    private static final List<String> MORE_RATINGS = new List<String>{
        'AAA', 'AA', 'A', 'BBB', 'BB', 'B', 'CCC', 'CC', 'C', 'D', 'N/A' // N/A = unmapped rating
    };
    private static final List<String> QUALITATIVE_SCORES = new List<String>{ 'A', 'B', 'C', 'D', 'E' };
    private static final List<String> STATUSES = new List<String>{
        'Active', 'Active (insolvency proceedings)', 'Dissolved', 'In liquidation', 'Bankruptcy'
    };

    /** True only in a sandbox with MOCK_ENABLED on. Never true in tests or production. */
    public static Boolean isEnabled() {
        return MOCK_ENABLED
            && !Test.isRunningTest()
            && [SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox;
    }

    public HttpResponse respond(HttpRequest req) {
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');

        List<Object> data = new List<Object>();
        for (String bvdId : extractBvdIds(req.getBody())) {
            if (hit(missingCompanyRatePct)) {
                continue;
            }
            data.add(buildCompany(bvdId));
        }

        res.setStatusCode(200);
        res.setBody(JSON.serialize(new Map<String, Object>{ 'Data' => data }));
        return res;
    }

    private static List<String> extractBvdIds(String body) {
        List<String> bvdIds = new List<String>();
        if (String.isBlank(body)) {
            return bvdIds;
        }
        Map<String, Object> parsed = (Map<String, Object>) JSON.deserializeUntyped(body);
        List<Object> whereList = (List<Object>) parsed.get('WHERE');
        if (whereList == null) {
            return bvdIds;
        }
        for (Object clause : whereList) {
            List<Object> ids = (List<Object>) ((Map<String, Object>) clause).get('BvDID');
            if (ids == null) {
                continue;
            }
            for (Object id : ids) {
                if (id != null) {
                    bvdIds.add(String.valueOf(id));
                }
            }
        }
        return bvdIds;
    }

    private static Map<String, Object> buildCompany(String bvdId) {
        Map<String, Object> company = new Map<String, Object>{
            'NAME' => 'Mock Company ' + bvdId,
            'BVD_ID_NUMBER' => bvdId,
            'EMPL' => randomInt(1, 50000)
        };

        // MORE evaluation block
        Boolean hasMore = !hit(nullFieldRatePct);
        company.put('MORRAT', hasMore ? pick(MORE_RATINGS) : null);
        company.put('MORE_YEAR', hasMore ? randomScoreDate() : null);
        company.put('MORCREDLIMIT', hasMore ? randomAmount(10000, 5000000) : null);
        company.put('MORDEF', hasMore ? randomDecimal(0, 30) : null);
        company.put('MORCONF', hasMore ? randomDecimal(40, 100) : null);

        // Reactive MORE block
        Boolean hasReactive = !hit(nullFieldRatePct);
        company.put('REACMORRAT', hasReactive ? pick(MORE_RATINGS) : null);
        company.put('REACMORE_DATE', hasReactive ? randomScoreDate() : null);
        company.put('REACMORCREDLIMIT', hasReactive ? randomAmount(10000, 5000000) : null);
        company.put('REACMORDEF', hasReactive ? randomDecimal(0, 30) : null);
        company.put('REACMORCONF', hasReactive ? randomDecimal(40, 100) : null);

        // Qualitative block
        Boolean hasQualitative = !hit(nullFieldRatePct);
        company.put('MODEFINNF', hasQualitative ? pick(QUALITATIVE_SCORES) : null);
        company.put('MODEFINNFDATE', hasQualitative ? randomScoreDate() : null);
        company.put('MODEFINNF_CreditLimitValue', hasQualitative ? randomAmount(5000, 2000000) : null);
        company.put('MODEFINNFCONF', hasQualitative ? randomDecimal(40, 100) : null);

        // Ratios, status and company profile
        company.put('CURR', hit(nullFieldRatePct) ? null : randomDecimal(0, 5));
        company.put('LIQR', hit(nullFieldRatePct) ? null : randomDecimal(0, 5));
        company.put('STATUS', new List<Object>{ pick(STATUSES) });
        company.put('STATUS_DATE', new List<Object>{ formatDate(Date.today().addDays(-randomInt(0, 3650))) });
        company.put('INCORPORATION_DATE', hit(badIncorporationRatePct)
            ? '1102-08-06T00:00:00'
            : formatDate(Date.newInstance(randomInt(1900, 2023), randomInt(1, 12), randomInt(1, 28))));
        company.put('CAPI', hit(nullFieldRatePct) ? null : randomAmount(1000, 100000000));

        return company;
    }

    /** Recent date (valid for the 2-year window) or a stale one, depending on staleDateRatePct. */
    private static String randomScoreDate() {
        Integer daysAgo = hit(staleDateRatePct) ? randomInt(740, 2000) : randomInt(0, 700);
        return formatDate(Date.today().addDays(-daysAgo));
    }

    /** Moody's date format, e.g. 2025-03-31T00:00:00 */
    private static String formatDate(Date d) {
        return String.valueOf(d.year()).leftPad(4, '0') + '-' +
               String.valueOf(d.month()).leftPad(2, '0') + '-' +
               String.valueOf(d.day()).leftPad(2, '0') + 'T00:00:00';
    }

    private static Boolean hit(Integer ratePct) {
        return Math.random() * 100 < ratePct;
    }

    private static Integer randomInt(Integer min, Integer max) {
        return min + Math.floor(Math.random() * (max - min + 1)).intValue();
    }

    private static Decimal randomDecimal(Integer min, Integer max) {
        return Decimal.valueOf(min + Math.random() * (max - min)).setScale(2);
    }

    private static Decimal randomAmount(Integer min, Integer max) {
        return Decimal.valueOf(randomInt(min, max));
    }

    private static String pick(List<String> values) {
        return values[randomInt(0, values.size() - 1)];
    }
}