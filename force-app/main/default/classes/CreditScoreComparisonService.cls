/**
 * Ticket #948 - Credit Score Comparison
 *
 * Compares the latest generated Moody's Risk Class / Credit Limit against
 * the previously stored values on the Account, and sets an overall
 * Credit Score Comparison Flag (Deterioration / Improvement / No Change).
 *
 * Intended call site: right before you overwrite Previous_Moody_s_Risk_Class__c /
 * Previous_Moody_s_Credit_Limit__c with the new values (e.g. inside
 * GetMoodysDataService or CreditReviewParameters, wherever the new Moody's
 * data is applied to the Account).
 */
public inherited sharing class CreditScoreComparisonService {

    // Current values on Account
    private static final String FLD_CURRENT_RISK_CLASS   = 'Moody_s_Risk_Class__c';
    private static final String FLD_CURRENT_CREDIT_LIMIT = 'Moody_s_Credit_Limit__c';
    // Previous values on Account
    private static final String FLD_PREVIOUS_RISK_CLASS   = 'Previous_Moody_s_Risk_Class__c';
    private static final String FLD_PREVIOUS_CREDIT_LIMIT = 'Previous_Moody_s_Credit_Limit__c';
    // Result flag on Account
    private static final String FLD_COMPARISON_FLAG = 'Credit_Score_Comparison_Flag__c';

    public static final String FLAG_DETERIORATION = 'Deterioration';
    public static final String FLAG_IMPROVEMENT   = 'Improvement';
    public static final String FLAG_NO_CHANGE     = 'No Change';

    // Minimum relative variation on Moody's Credit Limit required for the change
    // to be considered Improvement/Deterioration instead of No Change.
    // Consider moving this to a Custom Metadata Type (e.g. Credit_Comparison_Settings__mdt)
    // if it needs to be admin-configurable.
    private static final Decimal SIGNIFICANT_CHANGE_THRESHOLD = 0.10; // 10%

    // Risk hierarchy: lower number = lower risk. Configure centrally so the
    // direction of change is unambiguous. Consider moving this to a Custom
    // Metadata Type (e.g. Risk_Class_Rank__mdt) if it needs to be admin-configurable.
    //
    // Confirmed against CreditReviewParameters/GetMoodysDataService riskClassMapping
    // (Ticket #916): 'Full Credit Block' (code 6) is a distinct, more severe state than
    // 'Direct Block' (code 5, same tier as 'High' for CFIN purposes) — ranked accordingly.
    private static final Map<String, Integer> RISK_CLASS_RANK = new Map<String, Integer>{
        'Low'                => 1,
        'Medium'             => 2,
        'High'               => 3,
        'Direct Block'       => 4,
        'Full Credit Block'  => 5
    };

    public class ComparisonResult {
        public String riskClassChange;    // Deterioration / Improvement / No Change / null (no data)
        public String creditLimitChange;  // Deterioration / Improvement / No Change / null (no data)
        public String overallFlag;        // Deterioration / Improvement / No Change / null (no comparison possible)
    }

    /**
     * Evaluates the comparison and returns the result WITHOUT mutating the Account.
     * Call this before you overwrite the Previous_* fields with the new values,
     * passing in the account's current (about-to-become-previous) state.
     */
    public static ComparisonResult evaluate(Account previousState, String newRiskClass, Decimal newCreditLimit) {
        ComparisonResult result = new ComparisonResult();

        Object prevRiskClassObj   = previousState.get(FLD_CURRENT_RISK_CLASS);
        Object prevCreditLimitObj = previousState.get(FLD_CURRENT_CREDIT_LIMIT);

        String prevRiskClass     = prevRiskClassObj == null ? null : String.valueOf(prevRiskClassObj);
        Decimal prevCreditLimit  = prevCreditLimitObj == null ? null : (Decimal) prevCreditLimitObj;

        // Rule #2: only one score available (no previous) -> flag stays null.
        // NOTE: prevCreditLimit == 0 counts as "no previous data", matching
        // compareCreditLimit() below — Moody_s_Credit_Limit__c defaults to 0 on
        // accounts that never had a real Moody's assignment yet, and that must
        // not be read as a genuine previous value.
        Boolean hasPrevious = String.isNotBlank(prevRiskClass)
            || (prevCreditLimit != null && prevCreditLimit != 0);
        if (!hasPrevious) {
            return result; // all fields remain null
        }

        result.riskClassChange   = compareRiskClass(prevRiskClass, newRiskClass);
        result.creditLimitChange = compareCreditLimit(prevCreditLimit, newCreditLimit);
        result.overallFlag       = resolveOverallFlag(result.riskClassChange, result.creditLimitChange);

        return result;
    }

    /**
     * Convenience wrapper: evaluates the comparison, stamps the flag onto the
     * SObject (in memory only — caller is responsible for DML), and rolls the
     * current values into the Previous_* fields for the next comparison cycle.
     * Pass the Account as it currently exists in the DB (pre-update) as `acc`.
     */
    public static void applyComparisonAndRollValues(Account acc, String newRiskClass, Decimal newCreditLimit) {
        ComparisonResult result = evaluate(acc, newRiskClass, newCreditLimit);

        acc.put(FLD_COMPARISON_FLAG, result.overallFlag);

        // Roll current -> previous BEFORE the caller overwrites current with new values
        acc.put(FLD_PREVIOUS_RISK_CLASS, acc.get(FLD_CURRENT_RISK_CLASS));
        acc.put(FLD_PREVIOUS_CREDIT_LIMIT, acc.get(FLD_CURRENT_CREDIT_LIMIT));
    }

    private static String compareRiskClass(String previous, String current) {
        if (String.isBlank(previous) || String.isBlank(current)) {
            return null;
        }
        Integer prevRank = RISK_CLASS_RANK.get(previous);
        Integer currRank = RISK_CLASS_RANK.get(current);

        if (prevRank == null || currRank == null) {
            // Unknown/unmapped risk class value (e.g. a new picklist value added to
            // Moody_s_Risk_Class__c that hasn't been added to RISK_CLASS_RANK yet).
            // Treat as neutral/no-comparison rather than throwing, so one unmapped
            // value can't silently abort the whole caller's batch (callers such as
            // GetMoodysDataService wrap everything in a single try/catch). Logged so
            // it's still visible and RISK_CLASS_RANK can be updated.
            System.debug('LOGTRACE >>> CreditScoreComparisonService: unmapped Risk Class in comparison - previous="'
                + previous + '", current="' + current + '". Treating as no comparison. Add the missing value(s) to RISK_CLASS_RANK.');
            return null;
        }
        if (currRank > prevRank) {
            return FLAG_DETERIORATION;
        } else if (currRank < prevRank) {
            return FLAG_IMPROVEMENT;
        }
        return FLAG_NO_CHANGE;
    }

    /**
     * Only flags Improvement/Deterioration when the relative change vs. the
     * previous credit limit is >= SIGNIFICANT_CHANGE_THRESHOLD (10%) in either
     * direction. Smaller fluctuations are treated as No Change.
     */
    private static String compareCreditLimit(Decimal previous, Decimal current) {
        // Treat both null AND 0 as "no meaningful previous data" — Moody_s_Credit_Limit__c
        // can sit at 0 on accounts that never got a real Moody's assignment yet, and
        // comparing 0 -> a real value must NOT read as a genuine credit limit Improvement.
        if (previous == null || previous == 0 || current == null) {
            return null;
        }

        Decimal percentChange = (current - previous) / previous;

        if (percentChange >= SIGNIFICANT_CHANGE_THRESHOLD) {
            return FLAG_IMPROVEMENT;
        } else if (percentChange <= -SIGNIFICANT_CHANGE_THRESHOLD) {
            return FLAG_DETERIORATION;
        }
        return FLAG_NO_CHANGE;
    }

    /**
     * Rule #5: any deterioration in either attribute -> overall Deterioration.
     * Else if at least one attribute improves -> Improvement.
     * Else -> No Change.
     * (Attributes with null/no-data are treated as neutral — they don't
     * contribute to either direction.)
     */
    private static String resolveOverallFlag(String riskClassChange, String creditLimitChange) {
        if (riskClassChange == FLAG_DETERIORATION || creditLimitChange == FLAG_DETERIORATION) {
            return FLAG_DETERIORATION;
        }
        if (riskClassChange == FLAG_IMPROVEMENT || creditLimitChange == FLAG_IMPROVEMENT) {
            return FLAG_IMPROVEMENT;
        }
        return FLAG_NO_CHANGE;
    }

    public class CreditScoreComparisonException extends Exception {}
}