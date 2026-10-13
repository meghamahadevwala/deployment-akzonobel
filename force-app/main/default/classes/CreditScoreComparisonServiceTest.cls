@IsTest
private class CreditScoreComparisonServiceTest {

    private static Account buildAccount(String riskClass, Decimal creditLimit) {
        Account acc = new Account(Name = 'Test Account');
        if (riskClass != null) {
            acc.put('Moody_s_Risk_Class__c', riskClass);
        }
        if (creditLimit != null) {
            acc.put('Moody_s_Credit_Limit__c', creditLimit);
        }
        return acc;
    }

    @IsTest
    static void testNoPreviousScore_FlagStaysNull() {
        Account acc = buildAccount(null, null);
        CreditScoreComparisonService.ComparisonResult result =
            CreditScoreComparisonService.evaluate(acc, 'Medium', 50000);

        System.assertEquals(null, result.overallFlag);
        System.assertEquals(null, result.riskClassChange);
        System.assertEquals(null, result.creditLimitChange);
    }

    @IsTest
    static void testRiskClassDeterioration_LowToMedium() {
        Account acc = buildAccount('Low', 50000);
        CreditScoreComparisonService.ComparisonResult result =
            CreditScoreComparisonService.evaluate(acc, 'Medium', 50000);

        System.assertEquals(CreditScoreComparisonService.FLAG_DETERIORATION, result.riskClassChange);
        System.assertEquals(CreditScoreComparisonService.FLAG_NO_CHANGE, result.creditLimitChange);
        System.assertEquals(CreditScoreComparisonService.FLAG_DETERIORATION, result.overallFlag);
    }

    @IsTest
    static void testRiskClassImprovement_HighToMedium() {
        Account acc = buildAccount('High', 50000);
        CreditScoreComparisonService.ComparisonResult result =
            CreditScoreComparisonService.evaluate(acc, 'Medium', 50000);

        System.assertEquals(CreditScoreComparisonService.FLAG_IMPROVEMENT, result.riskClassChange);
        System.assertEquals(CreditScoreComparisonService.FLAG_IMPROVEMENT, result.overallFlag);
    }

    @IsTest
    static void testCreditLimitIncrease_Improvement() {
        // +50% vs previous -> well above the 10% threshold
        Account acc = buildAccount('Medium', 40000);
        CreditScoreComparisonService.ComparisonResult result =
            CreditScoreComparisonService.evaluate(acc, 'Medium', 60000);

        System.assertEquals(CreditScoreComparisonService.FLAG_IMPROVEMENT, result.creditLimitChange);
        System.assertEquals(CreditScoreComparisonService.FLAG_IMPROVEMENT, result.overallFlag);
    }

    @IsTest
    static void testCreditLimitDecrease_Deterioration() {
        // -33.3% vs previous -> well beyond the 10% threshold
        Account acc = buildAccount('Medium', 60000);
        CreditScoreComparisonService.ComparisonResult result =
            CreditScoreComparisonService.evaluate(acc, 'Medium', 40000);

        System.assertEquals(CreditScoreComparisonService.FLAG_DETERIORATION, result.creditLimitChange);
        System.assertEquals(CreditScoreComparisonService.FLAG_DETERIORATION, result.overallFlag);
    }

    @IsTest
    static void testCreditLimitIncrease_BelowThreshold_NoChange() {
        // +5% vs previous -> below the 10% threshold, must be No Change
        Account acc = buildAccount('Medium', 100000);
        CreditScoreComparisonService.ComparisonResult result =
            CreditScoreComparisonService.evaluate(acc, 'Medium', 105000);

        System.assertEquals(CreditScoreComparisonService.FLAG_NO_CHANGE, result.creditLimitChange);
        System.assertEquals(CreditScoreComparisonService.FLAG_NO_CHANGE, result.overallFlag);
    }

    @IsTest
    static void testCreditLimitDecrease_BelowThreshold_NoChange() {
        // -5% vs previous -> below the 10% threshold, must be No Change
        Account acc = buildAccount('Medium', 100000);
        CreditScoreComparisonService.ComparisonResult result =
            CreditScoreComparisonService.evaluate(acc, 'Medium', 95000);

        System.assertEquals(CreditScoreComparisonService.FLAG_NO_CHANGE, result.creditLimitChange);
        System.assertEquals(CreditScoreComparisonService.FLAG_NO_CHANGE, result.overallFlag);
    }

    @IsTest
    static void testCreditLimitIncrease_ExactlyAtThreshold_Improvement() {
        // Exactly +10% -> boundary is inclusive, must count as Improvement
        Account acc = buildAccount('Medium', 100000);
        CreditScoreComparisonService.ComparisonResult result =
            CreditScoreComparisonService.evaluate(acc, 'Medium', 110000);

        System.assertEquals(CreditScoreComparisonService.FLAG_IMPROVEMENT, result.creditLimitChange);
        System.assertEquals(CreditScoreComparisonService.FLAG_IMPROVEMENT, result.overallFlag);
    }

    @IsTest
    static void testCreditLimitDecrease_ExactlyAtThreshold_Deterioration() {
        // Exactly -10% -> boundary is inclusive, must count as Deterioration
        Account acc = buildAccount('Medium', 100000);
        CreditScoreComparisonService.ComparisonResult result =
            CreditScoreComparisonService.evaluate(acc, 'Medium', 90000);

        System.assertEquals(CreditScoreComparisonService.FLAG_DETERIORATION, result.creditLimitChange);
        System.assertEquals(CreditScoreComparisonService.FLAG_DETERIORATION, result.overallFlag);
    }

    @IsTest
    static void testMixedSignals_DeteriorationWins() {
        // Risk class improves, credit limit worsens (-33.3%, above threshold) -> overall Deterioration
        Account acc = buildAccount('High', 60000);
        CreditScoreComparisonService.ComparisonResult result =
            CreditScoreComparisonService.evaluate(acc, 'Medium', 40000);

        System.assertEquals(CreditScoreComparisonService.FLAG_IMPROVEMENT, result.riskClassChange);
        System.assertEquals(CreditScoreComparisonService.FLAG_DETERIORATION, result.creditLimitChange);
        System.assertEquals(CreditScoreComparisonService.FLAG_DETERIORATION, result.overallFlag);
    }

    @IsTest
    static void testNoChangeInEitherAttribute() {
        Account acc = buildAccount('Medium', 50000);
        CreditScoreComparisonService.ComparisonResult result =
            CreditScoreComparisonService.evaluate(acc, 'Medium', 50000);

        System.assertEquals(CreditScoreComparisonService.FLAG_NO_CHANGE, result.riskClassChange);
        System.assertEquals(CreditScoreComparisonService.FLAG_NO_CHANGE, result.creditLimitChange);
        System.assertEquals(CreditScoreComparisonService.FLAG_NO_CHANGE, result.overallFlag);
    }

    @IsTest
    static void testDirectBlockIsHighestRisk() {
        Account acc = buildAccount('High', 50000);
        CreditScoreComparisonService.ComparisonResult result =
            CreditScoreComparisonService.evaluate(acc, 'Direct Block', 50000);

        System.assertEquals(CreditScoreComparisonService.FLAG_DETERIORATION, result.riskClassChange);
    }

    // Unmapped Risk Class values (e.g. a new picklist value not yet added to
    // RISK_CLASS_RANK) must be treated as neutral/no-comparison rather than
    // throwing, so one unmapped value can't silently abort the whole caller's
    // batch (see CreditScoreComparisonService.compareRiskClass()).
    @IsTest
    static void testUnmappedRiskClass_TreatedAsNeutral() {
        Account acc = buildAccount('Unknown Value', 50000);
        CreditScoreComparisonService.ComparisonResult result =
            CreditScoreComparisonService.evaluate(acc, 'Medium', 50000);

        System.assertEquals(null, result.riskClassChange,
            'Unmapped Risk Class must be treated as no-comparison, not throw.');
        // Credit limit unchanged (50000 -> 50000) -> No Change; risk class contributes
        // nothing (null), so overall flag reflects only the credit limit comparison.
        System.assertEquals(CreditScoreComparisonService.FLAG_NO_CHANGE, result.creditLimitChange);
        System.assertEquals(CreditScoreComparisonService.FLAG_NO_CHANGE, result.overallFlag);
    }

    @IsTest
    static void testCreditLimitZeroPrevious_TreatedAsNoData_NotImprovement() {
        // Regression test: Moody_s_Credit_Limit__c sitting at 0 (never assigned) must NOT
        // be read as a real previous value — going from 0 to a real limit must not register
        // as a Credit Limit Improvement.
        Account acc = buildAccount('Medium', 0);
        CreditScoreComparisonService.ComparisonResult result =
            CreditScoreComparisonService.evaluate(acc, 'Medium', 65000);

        System.assertEquals(null, result.creditLimitChange,
            'Previous Credit Limit of 0 must be treated as "no data", not a real value to compare against.');
        System.assertEquals(CreditScoreComparisonService.FLAG_NO_CHANGE, result.overallFlag,
            'With Risk Class unchanged and Credit Limit having no real previous data, overall flag must be No Change, not Improvement.');
    }

    @IsTest
    static void testApplyComparisonAndRollValues_RollsCurrentIntoPrevious() {
        Account acc = buildAccount('Low', 50000);
        acc.put('Previous_Moody_s_Risk_Class__c', 'Low');
        acc.put('Previous_Moody_s_Credit_Limit__c', 45000);

        // Risk class deteriorates (Low -> Medium); credit limit moves +10% (55000 vs 50000),
        // which is exactly at the threshold and would itself be Improvement, but
        // Deterioration always wins in resolveOverallFlag.
        CreditScoreComparisonService.applyComparisonAndRollValues(acc, 'Medium', 55000);

        System.assertEquals('Low', acc.get('Previous_Moody_s_Risk_Class__c'));
        System.assertEquals(50000, acc.get('Previous_Moody_s_Credit_Limit__c'));
        System.assertEquals(CreditScoreComparisonService.FLAG_DETERIORATION, acc.get('Credit_Score_Comparison_Flag__c'));
    }
}