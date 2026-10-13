public without sharing class CollectionBlockingService {

    // ---------- Constants ----------
    private static final String  DUNNING_DISPUTE       = 'A';
    private static final String  DUNNING_P2P           = 'B';
    private static final String  DUNNING_NONE          = '';

    private static final String  BROKEN                = 'Broken';
    private static final String  UNBROKEN              = 'Unbroken';
    private static final Decimal BROKEN_THRESHOLD      = 3;

    // Status_Event__c value on the Transaction that means the Promise To Pay
    // has been reversed. When this is set, the Broken_Flag__c is blanked out.
    private static final String  REVERSED_EVENT_STATUS = '30';

    private static final Set<String> ACTIVE_DISPUTE_STATUSES = new Set<String>{
        '30 Waiting For Information',
        '50 To Be Credited'
    };

    // ---------- Entry point ----------
    public static void recalculate(Set<Id> txIds) {
        if (txIds == null || txIds.isEmpty()) {
            return;
        }

        Map<Id, Datetime> latestDispute = loadLatestDisputeDates(txIds);
        Map<Id, Datetime> latestP2P     = loadLatestP2PDates(txIds);

        List<celsrm__Transaction__c> txList = [
            SELECT Id,
                   celsrm__Promised_Amount__c,
                   celsrm__Dunning_Block__c,
                   Grace_period__c,
                   Broken_Flag__c,
                   Status_Event__c
            FROM celsrm__Transaction__c
            WHERE Id IN :txIds
        ];

        List<celsrm__Transaction__c> updates = new List<celsrm__Transaction__c>();

        for (celsrm__Transaction__c tx : txList) {
            String blockValue  = computeDunningBlock(tx, latestDispute.get(tx.Id), latestP2P.get(tx.Id));
            String brokenValue = computeBrokenFlag(tx);

            Boolean dunningChanged = tx.celsrm__Dunning_Block__c != blockValue;
            Boolean brokenChanged  = tx.Broken_Flag__c           != brokenValue;

            if (dunningChanged || brokenChanged) {
                celsrm__Transaction__c upd = new celsrm__Transaction__c(Id = tx.Id);
                if (dunningChanged) upd.celsrm__Dunning_Block__c = blockValue;
                if (brokenChanged)  upd.Broken_Flag__c           = brokenValue;
                updates.add(upd);
            }
        }

        if (!updates.isEmpty()) {
            update updates;
        }
    }

    // ---------- Queries ----------
    private static Map<Id, Datetime> loadLatestDisputeDates(Set<Id> txIds) {
        Map<Id, Datetime> result = new Map<Id, Datetime>();
        for (celsrm__Dispute__c d : [
            SELECT Id, celsrm__Transaction__c, CreatedDate
            FROM celsrm__Dispute__c
            WHERE celsrm__Transaction__c IN :txIds
              AND celsrm__Status__c IN :ACTIVE_DISPUTE_STATUSES
            ORDER BY CreatedDate DESC
        ]) {
            if (!result.containsKey(d.celsrm__Transaction__c)) {
                result.put(d.celsrm__Transaction__c, d.CreatedDate);
            }
        }
        return result;
    }

    private static Map<Id, Datetime> loadLatestP2PDates(Set<Id> txIds) {
        Map<Id, Datetime> result = new Map<Id, Datetime>();
        for (celsrm__Celonis_Event__c ev : [
            SELECT Id, celsrm__Transaction__c, CreatedDate
            FROM celsrm__Celonis_Event__c
            WHERE celsrm__Transaction__c IN :txIds
              AND Name = 'Promise To Pay'
            ORDER BY CreatedDate DESC
        ]) {
            if (!result.containsKey(ev.celsrm__Transaction__c)) {
                result.put(ev.celsrm__Transaction__c, ev.CreatedDate);
            }
        }
        return result;
    }

    // ---------- Business rules ----------
    private static String computeDunningBlock(
        celsrm__Transaction__c tx,
        Datetime latestDisputeDt,
        Datetime latestP2PDt
    ) {
        Boolean hasDispute = latestDisputeDt != null;
        Boolean hasP2P     = latestP2PDt != null
                          && tx.celsrm__Promised_Amount__c != null
                          && tx.celsrm__Promised_Amount__c > 0;

        if (hasDispute && hasP2P) {
            return latestDisputeDt > latestP2PDt ? DUNNING_DISPUTE : DUNNING_P2P;
        }
        if (hasDispute) return DUNNING_DISPUTE;
        if (hasP2P)     return DUNNING_P2P;
        return DUNNING_NONE;
    }

    /**
     * Broken flag rules:
     *  - If Status_Event__c == '30' (Promise To Pay reversed) -> null/blank.
     *  - Else if Grace_period__c > 3 -> 'Broken'.
     *  - Else if Grace_period__c is not null -> 'Unbroken'.
     *  - Else -> null.
     */
    private static String computeBrokenFlag(celsrm__Transaction__c tx) {
        if (tx.Status_Event__c == REVERSED_EVENT_STATUS) {
            return null;
        }
        if (tx.Grace_period__c == null) {
            return null;
        }
        return tx.Grace_period__c > BROKEN_THRESHOLD ? BROKEN : UNBROKEN;
    }
}