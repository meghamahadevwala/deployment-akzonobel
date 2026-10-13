public without sharing class CollectionBlockingServiceDebug {

    private static final String LOG_TAG = '[CBS-DEBUG] ';

    public static void diagnose(Set<Id> txIds) {
        System.debug(LOG_TAG + '========================================');
        System.debug(LOG_TAG + 'START diagnose()');
        System.debug(LOG_TAG + 'txIds received: ' + txIds);
        System.debug(LOG_TAG + 'txIds size: ' + (txIds == null ? 0 : txIds.size()));
        System.debug(LOG_TAG + '========================================');

        if (txIds == null || txIds.isEmpty()) {
            System.debug(LOG_TAG + 'ABORT: txIds is null or empty. Nothing to diagnose.');
            return;
        }

        Map<Id, Datetime> latestDispute = loadLatestDisputeDates(txIds);
        Map<Id, Datetime> latestP2P     = loadLatestP2PDates(txIds);

        System.debug(LOG_TAG + '---- SUMMARY MAPS ----');
        System.debug(LOG_TAG + 'latestDispute map (' + latestDispute.size() + ' keys): ' + latestDispute);
        System.debug(LOG_TAG + 'latestP2P map (' + latestP2P.size() + ' keys): ' + latestP2P);

        System.debug(LOG_TAG + '---- QUERYING TRANSACTIONS ----');
        List<celsrm__Transaction__c> txList = [
            SELECT Id,
                   Name,
                   celsrm__Promised_Amount__c,
                   celsrm__Dunning_Block__c,
                   Grace_period__c,
                   Broken_Flag__c,
                   Status_Event__c
            FROM celsrm__Transaction__c
            WHERE Id IN :txIds
        ];
        System.debug(LOG_TAG + 'Transactions returned: ' + txList.size() + ' (requested: ' + txIds.size() + ')');

        if (txList.size() < txIds.size()) {
            Set<Id> foundIds = new Map<Id, celsrm__Transaction__c>(txList).keySet();
            Set<Id> missingIds = txIds.clone();
            missingIds.removeAll(foundIds);
            System.debug(LOG_TAG + '⚠️ WARNING: Some txIds did not return a record (deleted? no access? wrong object?): ' + missingIds);
        }

        for (celsrm__Transaction__c tx : txList) {
            System.debug(LOG_TAG + '----------------------------------------');
            System.debug(LOG_TAG + 'PROCESSING Tx: ' + tx.Id + ' (' + tx.Name + ')');
            System.debug(LOG_TAG + '  RAW FIELD VALUES:');
            System.debug(LOG_TAG + '    celsrm__Promised_Amount__c = ' + tx.celsrm__Promised_Amount__c
                         + ' (isNull=' + (tx.celsrm__Promised_Amount__c == null) + ')');
            System.debug(LOG_TAG + '    celsrm__Dunning_Block__c   = "' + tx.celsrm__Dunning_Block__c + '"');
            System.debug(LOG_TAG + '    Grace_period__c            = ' + tx.Grace_period__c);
            System.debug(LOG_TAG + '    Broken_Flag__c             = "' + tx.Broken_Flag__c + '"');
            System.debug(LOG_TAG + '    Status_Event__c            = "' + tx.Status_Event__c + '"');

            Datetime disputeDt = latestDispute.get(tx.Id);
            Datetime p2pDt     = latestP2P.get(tx.Id);

            System.debug(LOG_TAG + '  LOOKUP RESULTS:');
            System.debug(LOG_TAG + '    disputeDt from map = ' + disputeDt);
            System.debug(LOG_TAG + '    p2pDt from map     = ' + p2pDt);

            Boolean hasDispute = disputeDt != null;
            Boolean amountNotNull = tx.celsrm__Promised_Amount__c != null;
            Boolean amountPositive = amountNotNull && tx.celsrm__Promised_Amount__c > 0;
            Boolean hasP2P = p2pDt != null && amountNotNull && amountPositive;

            System.debug(LOG_TAG + '  BOOLEAN BREAKDOWN:');
            System.debug(LOG_TAG + '    hasDispute            = ' + hasDispute);
            System.debug(LOG_TAG + '    p2pDt != null         = ' + (p2pDt != null));
            System.debug(LOG_TAG + '    amount != null        = ' + amountNotNull);
            System.debug(LOG_TAG + '    amount > 0            = ' + amountPositive);
            System.debug(LOG_TAG + '    hasP2P (final AND)    = ' + hasP2P);

            if (p2pDt != null && !hasP2P) {
                System.debug(LOG_TAG + '  🔴 FLAG: P2P event exists but hasP2P=false → likely Promised_Amount__c problem!');
            }

            String computedBlock  = computeDunningBlock(tx, disputeDt, p2pDt, hasDispute, hasP2P, disputeDt != null && p2pDt != null);
            String computedBroken = computeBrokenFlag(tx);

            Boolean dunningChanged = tx.celsrm__Dunning_Block__c != computedBlock;
            Boolean brokenChanged  = tx.Broken_Flag__c != computedBroken;

            System.debug(LOG_TAG + '  RESULT:');
            System.debug(LOG_TAG + '    Dunning_Block  actual="' + tx.celsrm__Dunning_Block__c + '"  computed="' + computedBlock + '"  changed=' + dunningChanged);
            System.debug(LOG_TAG + '    Broken_Flag    actual="' + tx.Broken_Flag__c + '"  computed="' + computedBroken + '"  changed=' + brokenChanged);

            if (!dunningChanged && !brokenChanged) {
                System.debug(LOG_TAG + '  ℹ️ No changes would be made for this record — update() would skip it silently.');
            }
        }

        System.debug(LOG_TAG + '========================================');
        System.debug(LOG_TAG + 'END diagnose()');
        System.debug(LOG_TAG + '========================================');
    }

    // ---------- Queries (idénticas al original, sin DML, con logging detallado) ----------
    private static Map<Id, Datetime> loadLatestDisputeDates(Set<Id> txIds) {
        System.debug(LOG_TAG + '---- QUERYING DISPUTES ----');
        List<celsrm__Dispute__c> disputes = [
            SELECT Id, celsrm__Transaction__c, celsrm__Status__c, CreatedDate
            FROM celsrm__Dispute__c
            WHERE celsrm__Transaction__c IN :txIds
              AND celsrm__Status__c IN ('30 Waiting For Information', '50 To Be Credited')
            ORDER BY CreatedDate DESC
        ];
        System.debug(LOG_TAG + 'Disputes returned (active statuses only): ' + disputes.size());

        Map<Id, Datetime> result = new Map<Id, Datetime>();
        for (celsrm__Dispute__c d : disputes) {
            System.debug(LOG_TAG + '  Dispute ' + d.Id + ' | Tx=' + d.celsrm__Transaction__c
                         + ' | Status="' + d.celsrm__Status__c + '" | CreatedDate=' + d.CreatedDate);
            if (!result.containsKey(d.celsrm__Transaction__c)) {
                result.put(d.celsrm__Transaction__c, d.CreatedDate);
                System.debug(LOG_TAG + '    -> Set as LATEST dispute for this Tx');
            } else {
                System.debug(LOG_TAG + '    -> Skipped (already have a more recent one for this Tx)');
            }
        }
        return result;
    }

    private static Map<Id, Datetime> loadLatestP2PDates(Set<Id> txIds) {
        System.debug(LOG_TAG + '---- QUERYING P2P EVENTS (celsrm__Celonis_Event__c, Name = Promise To Pay) ----');

        // Primero, sin filtro de Name, para ver TODOS los eventos de estas transacciones
        List<celsrm__Celonis_Event__c> allEvents = [
            SELECT Id, celsrm__Transaction__c, Name, CreatedDate
            FROM celsrm__Celonis_Event__c
            WHERE celsrm__Transaction__c IN :txIds
            ORDER BY CreatedDate DESC
        ];
        System.debug(LOG_TAG + 'ALL Celonis_Event__c for these Tx (any Name): ' + allEvents.size());
        for (celsrm__Celonis_Event__c ev : allEvents) {
            System.debug(LOG_TAG + '  [ALL] Event ' + ev.Id + ' | Tx=' + ev.celsrm__Transaction__c
                         + ' | Name="' + ev.Name + '" | CreatedDate=' + ev.CreatedDate);
        }

        List<celsrm__Celonis_Event__c> p2pEvents = [
            SELECT Id, celsrm__Transaction__c, Name, CreatedDate
            FROM celsrm__Celonis_Event__c
            WHERE celsrm__Transaction__c IN :txIds
              AND Name = 'Promise To Pay'
            ORDER BY CreatedDate DESC
        ];
        System.debug(LOG_TAG + 'P2P-filtered events (Name = "Promise To Pay"): ' + p2pEvents.size());

        if (allEvents.size() > 0 && p2pEvents.isEmpty()) {
            System.debug(LOG_TAG + '🔴 FLAG: Hay eventos Celonis para estas Tx, pero NINGUNO con Name exacto "Promise To Pay". Revisa el valor real del campo Name (mayúsculas, espacios, label vs API value).');
        }

        Map<Id, Datetime> result = new Map<Id, Datetime>();
        for (celsrm__Celonis_Event__c ev : p2pEvents) {
            System.debug(LOG_TAG + '  [P2P] Event ' + ev.Id + ' | Tx=' + ev.celsrm__Transaction__c + ' | CreatedDate=' + ev.CreatedDate);
            if (!result.containsKey(ev.celsrm__Transaction__c)) {
                result.put(ev.celsrm__Transaction__c, ev.CreatedDate);
                System.debug(LOG_TAG + '    -> Set as LATEST P2P for this Tx');
            } else {
                System.debug(LOG_TAG + '    -> Skipped (already have a more recent one for this Tx)');
            }
        }
        return result;
    }

    // ---------- Reglas (idénticas al original, con logging de la decisión) ----------
    private static String computeDunningBlock(
        celsrm__Transaction__c tx,
        Datetime latestDisputeDt,
        Datetime latestP2PDt,
        Boolean hasDispute,
        Boolean hasP2P,
        Boolean bothPresent
    ) {
        System.debug(LOG_TAG + '  computeDunningBlock() -> hasDispute=' + hasDispute + ' hasP2P=' + hasP2P);

        if (hasDispute && hasP2P) {
            String winner = latestDisputeDt > latestP2PDt ? 'A (dispute more recent)' : 'B (P2P more recent)';
            System.debug(LOG_TAG + '    Both present. disputeDt=' + latestDisputeDt + ' vs p2pDt=' + latestP2PDt + ' -> ' + winner);
            return latestDisputeDt > latestP2PDt ? 'A' : 'B';
        }
        if (hasDispute) {
            System.debug(LOG_TAG + '    Only dispute present -> A');
            return 'A';
        }
        if (hasP2P) {
            System.debug(LOG_TAG + '    Only P2P present -> B');
            return 'B';
        }
        System.debug(LOG_TAG + '    Neither present -> "" (blank)');
        return '';
    }

    private static String computeBrokenFlag(celsrm__Transaction__c tx) {
        System.debug(LOG_TAG + '  computeBrokenFlag() -> Status_Event__c="' + tx.Status_Event__c + '" Grace_period__c=' + tx.Grace_period__c);

        if (tx.Status_Event__c == '30') {
            System.debug(LOG_TAG + '    Status_Event__c == 30 (reversed) -> null');
            return null;
        }
        if (tx.Grace_period__c == null) {
            System.debug(LOG_TAG + '    Grace_period__c is null -> null');
            return null;
        }
        String result = tx.Grace_period__c > 3 ? 'Broken' : 'Unbroken';
        System.debug(LOG_TAG + '    Grace_period__c=' + tx.Grace_period__c + ' > 3 ? -> ' + result);
        return result;
    }
}