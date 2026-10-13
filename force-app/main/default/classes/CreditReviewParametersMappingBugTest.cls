@isTest
private class CreditReviewParametersMappingBugTest {

    // Mirrors CreditReviewPerameterTest.buildAccount so this class can run standalone
    // without depending on the other test class's private helper.
    private static Account buildAccount(String key, String bvdId, String checkRule, String creditGroup,
        String paymentBehaviour, String paymentTrend) {
        return new Account(
            celsrm__App_Name__c = 'Credit',
            Name = 'Mapping Bug Test Account ' + key,
            CurrencyIsoCode = 'USD',
            BvD_ID_Number__c = bvdId,
            celsrm__Account_Key__c = key,
            Is_Snoozed__c = false,
            Calculated_Credit_Limit_Group_Currency__c = 240000,
            Recommended_Credit_Limit__c = 240000,
            Moody_s_Credit_Limit__c = 230000,
            celsrm__Credit_Limit__c = 220000,
            celsrm__Check_Rule__c = checkRule,
            celsrm__Credit_Group__c = creditGroup,
            celsrm__Limit_Valid_To_Date__c = Date.today().addDays(10),
            Moody_s_Change_Identified__c = false,
            celsrm__Payment_Behaviour_Text__c = paymentBehaviour,
            celsrm__Payment_Behaviour_Trend__c = paymentTrend
        );
    }

    private static String isoDate(Date d) {
        return String.valueOf(d) + 'T00:00:00';
    }

    private class MockHttpResponseGenerator implements HttpCalloutMock {
        private HttpResponse mockResponse;
        public MockHttpResponseGenerator(HttpResponse mockResponse) {
            this.mockResponse = mockResponse;
        }
        public HttpResponse respond(HttpRequest req) {
            return mockResponse;
        }
    }

    // ------------------------------------------------------------------
    // CONTROL / BASELINE
    // With ONLY a Qualitative Score present (no Reactive/MORE competing),
    // "D" correctly maps to High. This confirms the mapping table itself
    // (qualitativeRiskClassMapping) is fine — the defect is NOT here.
    // ------------------------------------------------------------------
    @isTest
    static void testControl_QualitativeScoreD_AloneMapsToHigh() {
        Account acc = buildAccount('CTRL01', 'BUG-BVD-CTRL01', 'Z05 Risk Class High',
            '0003 - RCA - Regular Credit Account', 'On Time', null);
        insert acc;

        Date qualitativeDate = Date.today().addMonths(-2);
        String body = '{"Data":[{"NAME":"Control Co","BVD_ID_NUMBER":"BUG-BVD-CTRL01",'
            + '"MODEFINNF":"D","MODEFINNFDATE":"' + isoDate(qualitativeDate) + '","MODEFINNF_CreditLimitValue":55000.0}]}';
        HttpResponse mockResponse = new HttpResponse();
        mockResponse.setBody(body);
        mockResponse.setStatusCode(200);
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(mockResponse));

        Test.startTest();
        Map<Object,Object> inMap = new Map<Object,Object>();
        inMap.put('Id', acc.Id);
        inMap.put('modelType', 'Full Review');
        inMap.put('RequestedCreditLimitEUR', 75000);
        new CreditReviewParameters().invoke('initiateCreditReview', inMap);
        Test.stopTest();

        Account updated = [SELECT Moody_s_Risk_Class__c, celsrm__Risk_Class__c FROM Account WHERE Id = :acc.Id];
        System.assertEquals('High', updated.Moody_s_Risk_Class__c,
            'Control check: in isolation, Qualitative Score D must map to High. '
            + 'If this fails, the mapping table itself is broken (different bug than #836 issue 1).');
        System.assertEquals('5 - High Risk', updated.celsrm__Risk_Class__c);
    }

    // ------------------------------------------------------------------
    // TICKET #836 (issue 1) — reproduction
    //
    // A stale-but-still-valid MORE score (Medium) is present alongside a more
    // recent Qualitative Score D (which alone would give High, per the control
    // test above). Because the code picks Reactive > MORE > Qualitative by
    // FIXED priority — never comparing dates across sources — the older MORE
    // data wins and the account is misclassified as Medium instead of High.
    //
    // NOTE: this test intentionally asserts the CURRENT (buggy) outcome so it
    // documents the defect. Once the precedence fix is agreed with the
    // business (most-recent-wins vs. most-severe-wins — see the theoretical
    // doc), update the assertions below to the TODO block at the bottom.
    // ------------------------------------------------------------------
    @isTest
    static void testBug836_StaleMoreScoreOverridesMoreRecentQualitativeD() {
        Account acc = buildAccount('BUG01', 'BUG-BVD-01', 'Z05 Risk Class High',
            '0003 - RCA - Regular Credit Account', 'On Time', null);
        insert acc;

        Date staleMoreDate = Date.today().addMonths(-22);        // old but still within the 2-year window
        Date recentQualitativeDate = Date.today().addMonths(-2); // clearly more recent than staleMoreDate

        String body = '{"Data":[{"NAME":"Bug836 Co","BVD_ID_NUMBER":"BUG-BVD-01",'
            + '"MORRAT":"BBB","MORE_YEAR":"' + isoDate(staleMoreDate) + '","MORCREDLIMIT":40000.0,'
            + '"MODEFINNF":"D","MODEFINNFDATE":"' + isoDate(recentQualitativeDate) + '","MODEFINNF_CreditLimitValue":55000.0}]}';
        HttpResponse mockResponse = new HttpResponse();
        mockResponse.setBody(body);
        mockResponse.setStatusCode(200);
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(mockResponse));

        Test.startTest();
        Map<Object,Object> inMap = new Map<Object,Object>();
        inMap.put('Id', acc.Id);
        inMap.put('modelType', 'Full Review');
        inMap.put('RequestedCreditLimitEUR', 75000);
        new CreditReviewParameters().invoke('initiateCreditReview', inMap);
        Test.stopTest();

        Account updated = [SELECT Moody_s_Risk_Class__c, celsrm__Risk_Class__c, celsrm__Check_Rule__c
            FROM Account WHERE Id = :acc.Id];

        // --- CURRENT (buggy) behavior being documented for ticket #836 ---
        System.assertEquals('Medium', updated.Moody_s_Risk_Class__c,
            'BUG #836: the older MORE score (Medium, 22 months old) wins over the more recent '
            + 'Qualitative Score D (High, 2 months old) purely because of fixed source priority '
            + '(Reactive > MORE > Qualitative), not because of recency. This reproduces the exact '
            + 'symptom reported for CR-0464386.');
        System.assertEquals('4 - Medium Risk', updated.celsrm__Risk_Class__c);
        System.assertEquals('Z04 Risk Class Medium', updated.celsrm__Check_Rule__c);

        // --- TODO: once the precedence fix is implemented, replace the block above with: ---
        // System.assertEquals('High', updated.Moody_s_Risk_Class__c);
        // System.assertEquals('5 - High Risk', updated.celsrm__Risk_Class__c);
        // System.assertEquals('Z05 Risk Class High', updated.celsrm__Check_Rule__c);
    }

    // ------------------------------------------------------------------
    // TICKET #836 (issue 1) — systemic reproduction, different source pair
    //
    // Same root cause as the test above, but between Reactive and MORE instead
    // of MORE and Qualitative — demonstrates this is a defect in the
    // precedence chain itself, not something specific to the Qualitative
    // Score D case.
    // ------------------------------------------------------------------
    @isTest
    static void testBug836_StaleReactiveScoreOverridesMoreRecentMoreScore() {
        Account acc = buildAccount('BUG02', 'BUG-BVD-02', 'Z05 Risk Class High',
            '0003 - RCA - Regular Credit Account', 'On Time', null);
        insert acc;

        Date staleReactiveDate = Date.today().addMonths(-23); // old but still within the 2-year window
        Date recentMoreDate = Date.today().addMonths(-1);     // clearly more recent than staleReactiveDate

        String body = '{"Data":[{"NAME":"Bug836 Co 2","BVD_ID_NUMBER":"BUG-BVD-02",'
            + '"REACMORRAT":"AAA","REACMORE_DATE":"' + isoDate(staleReactiveDate) + '","REACMORCREDLIMIT":90000.0,'
            + '"MORRAT":"B","MORE_YEAR":"' + isoDate(recentMoreDate) + '","MORCREDLIMIT":40000.0}]}';
        HttpResponse mockResponse = new HttpResponse();
        mockResponse.setBody(body);
        mockResponse.setStatusCode(200);
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(mockResponse));

        Test.startTest();
        Map<Object,Object> inMap = new Map<Object,Object>();
        inMap.put('Id', acc.Id);
        inMap.put('modelType', 'Full Review');
        inMap.put('RequestedCreditLimitEUR', 75000);
        new CreditReviewParameters().invoke('initiateCreditReview', inMap);
        Test.stopTest();

        Account updated = [SELECT Moody_s_Risk_Class__c, celsrm__Risk_Class__c FROM Account WHERE Id = :acc.Id];

        // --- CURRENT (buggy) behavior being documented ---
        System.assertEquals('Low', updated.Moody_s_Risk_Class__c,
            'BUG #836 (systemic): a stale Reactive score (Low, 23 months old) wins over a much more '
            + 'recent MORE score (High, 1 month old), purely due to fixed source priority. Same root '
            + 'cause as the MORE-vs-Qualitative case, different pair of sources.');
        System.assertEquals('3 - Low Risk', updated.celsrm__Risk_Class__c);

        // --- TODO: once the precedence fix is implemented, replace the block above with: ---
        // System.assertEquals('High', updated.Moody_s_Risk_Class__c);
        // System.assertEquals('5 - High Risk', updated.celsrm__Risk_Class__c);
    }
}