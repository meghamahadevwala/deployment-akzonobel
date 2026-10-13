public with sharing class PaymentBehaviourMultiplierService {

    /**
     * Returns the payment behaviour multiplier for a given (behaviour, trend)
     * combination. HIGHER is BETTER. Computed as: base(behaviour) + modifier(trend).
     *
     * IMPORTANT: celsrm__Payment_Behaviour_Text__c (behaviour) is the PRIMARY
     * signal and always dominates celsrm__Payment_Behaviour_Trend__c
     * (secondary/tie-breaker). The gap between behaviour tiers (0.2) is
     * intentionally larger than the full swing of the trend modifier
     * (+/-0.05, i.e. a 0.1 range), so trend can NEVER push a worse behaviour
     * above a better one. Example: Very Late + Improved (0.85) is still
     * WORSE than Late + Declined (0.95), because Late beats Very Late
     * regardless of trend.
     *
     * Base score by Behaviour (celsrm__Payment_Behaviour_Text__c):
     *   On Time            -> 1.2
     *   Late               -> 1.0
     *   Very Late          -> 0.8
     *   No Data Available / unmapped -> 1.0 (neutral, same tier as Late)
     *
     * Modifier by Trend (celsrm__Payment_Behaviour_Trend__c), applied to
     * ANY behaviour above:
     *   Payment Behaviour Improved -> +0.05
     *   Payment Behaviour Declined -> -0.05
     *   No Data Available / unmapped -> 0.00 (no change)
     *
     * Examples: On Time+Improved=1.25 | On Time+Declined=1.15 |
     *           Late+Improved=1.05     | Late+Declined=0.95 |
     *           Very Late+Improved=0.85 | Very Late+Declined=0.75
     *
     * @param behaviour The celsrm__Payment_Behaviour_Text__c value.
     * @param trend The celsrm__Payment_Behaviour_Trend__c value.
     * @return The multiplier associated with the combination.
     */
    public static Decimal getMultiplier(String behaviour, String trend) {
        return getBaseScore(behaviour) + getTrendModifier(trend);
    }

    private static Decimal getBaseScore(String behaviour) {
        if (behaviour == 'On Time') {
            return 1.2;
        } else if (behaviour == 'Late') {
            return 1.0;
        } else if (behaviour == 'Very Late') {
            return 0.8;
        }
        // 'No Data Available' or any unmapped value -> neutral baseline,
        // same tier as 'Late'.
        return 1.0;
    }

    private static Decimal getTrendModifier(String trend) {
        if (trend == 'Payment Behaviour Improved') {
            return 0.05;
        } else if (trend == 'Payment Behaviour Declined') {
            return -0.05;
        }
        // 'No Data Available' or any unmapped value -> no adjustment.
        return 0.00;
    }
}