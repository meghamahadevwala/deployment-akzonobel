/**
 * Batch to backfill Dispute_Amount_Local__c and Promised_Amount_Local__c on Transaction__c
 * using per-record conversion: Base_Amount__c / Amount__c (or 1 when Amount__c is blank or zero).
 * Batches over Transaction__c so each execute() stays within governor limits.
 */
public with sharing class TransactionLocalAmountBackfillBatch implements Database.Batchable<SObject> {

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(
            'SELECT Id, celsrm__Amount__c, celsrm__Base_Amount__c, celsrm__Disputed_Amount__c, celsrm__Promised_Amount__c FROM celsrm__Transaction__c'
        );
    }

    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        if (scope == null || scope.isEmpty()) {
            return;
        }
        List<celsrm__Transaction__c> transactions = (List<celsrm__Transaction__c>) scope;
        for (celsrm__Transaction__c t : transactions) {
            Decimal conversionRate = getConversionRate(t);
            t.celsrm__Dispute_Amount_Local__c = roundProduct(conversionRate, t.celsrm__Disputed_Amount__c);
            t.celsrm__Promised_Amount_Local__c = roundProduct(conversionRate, t.celsrm__Promised_Amount__c);
        }
        update transactions;
    }

    public void finish(Database.BatchableContext bc) {
        // Optional: log completion or send notification
    }

    /**
     * IF(ISBLANK(celsrm__Amount__c) OR celsrm__Amount__c = 0, 1, celsrm__Base_Amount__c / celsrm__Amount__c)
     */
    private static Decimal getConversionRate(celsrm__Transaction__c t) {
        Decimal amt = t.celsrm__Amount__c;
        if (amt == null || amt == 0) {
            return 1;
        }
        Decimal baseAmt = t.celsrm__Base_Amount__c;
        if (baseAmt == null) {
            return 1;
        }
        return baseAmt / amt;
    }

    /**
     * ROUND(conversionRate * sourceAmount, 2)
     */
    private static Decimal roundProduct(Decimal conversionRate, Decimal sourceAmount) {
        if (conversionRate == null || sourceAmount == null) {
            return null;
        }
        return (conversionRate * sourceAmount).setScale(2, RoundingMode.HALF_UP);
    }
}