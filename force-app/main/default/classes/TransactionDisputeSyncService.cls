/**
 * Service: TransactionDisputeSyncService
 * Object:  celsrm__Transaction__c
 *
 * Migrated from Flow "Transaction → Auto Dispute Creation & Closure"
 *
 * Responsibilities:
 *   1. If Document Type in {AZ, DZ, ZP}  → Create a Dispute linked to the Transaction
 *   2. If Close Date changed AND is not null AND Disputed Amount != 0
 *                                         → Close all open Disputes linked to the Transaction
 *
 * Notes:
 *   - Both paths can execute in the same run (same as original Flow behavior).
 *   - Querying Account.OwnerId separately since it's not available on Trigger.new.
 *   - Verify field API names: celsrm__Close_Date__c / celsrm__Disputed_Amount__c
 *     may differ based on whether they are managed or custom fields in your org.
 */
public with sharing class TransactionDisputeSyncService {

    private static final Set<String> DISPUTE_DOC_TYPES = new Set<String>{ 'AZ', 'DZ', 'ZP' };

    // ─── Entry point from trigger ────────────────────────────────────────────

    public static void processTransactions(
        List<celsrm__Transaction__c> newList,
        Map<Id, celsrm__Transaction__c> oldMap
    ) {
        Set<Id> txIdsToCreate  = new Set<Id>();
        Set<Id> txIdsToClose   = new Set<Id>();
        Set<Id> accountIds     = new Set<Id>();

        for (celsrm__Transaction__c tx : newList) {
            celsrm__Transaction__c old = (oldMap != null) ? oldMap.get(tx.Id) : null;

            // Rama 1: Document Type match → dispute creation
            if (isDocTypeMatch(tx)) {
                txIdsToCreate.add(tx.Id);
                if (tx.celsrm__Account__c != null) {
                    accountIds.add(tx.celsrm__Account__c);
                }
            }

            // Rama 2: Close Date condition → dispute closure
            if (isCloseDateCondition(tx, old)) {
                txIdsToClose.add(tx.Id);
            }
        }

        if (!txIdsToCreate.isEmpty()) {
            createDisputes(newList, txIdsToCreate, accountIds);
        }

        if (!txIdsToClose.isEmpty()) {
            closeRelatedDisputes(txIdsToClose);
        }
    }

    // ─── Dispute creation ────────────────────────────────────────────────────

    private static void createDisputes(
        List<celsrm__Transaction__c> newList,
        Set<Id> txIds,
        Set<Id> accountIds
    ) {
        // Need Account.OwnerId — not available directly on Trigger.new
        Map<Id, Id> accountOwnerMap = new Map<Id, Id>();
        for (Account acc : [SELECT Id, OwnerId FROM Account WHERE Id IN :accountIds]) {
            accountOwnerMap.put(acc.Id, acc.OwnerId);
        }

        List<celsrm__Dispute__c> toInsert = new List<celsrm__Dispute__c>();
        for (celsrm__Transaction__c tx : newList) {
            if (!txIds.contains(tx.Id)) continue;

            toInsert.add(new celsrm__Dispute__c(
                CurrencyIsoCode                   = tx.CurrencyIsoCode,
                celsrm__Account__c                = tx.celsrm__Account__c,
                celsrm__Amount__c                 = tx.celsrm__Amount__c,
                celsrm__Dispute_Resolver__c       = accountOwnerMap.get(tx.celsrm__Account__c),
                celsrm__Dispute_Type__c           = '100 Financial & Invoicing',
                celsrm__Latest_Note_Entered_By__c = tx.celsrm__Latest_Note_Entered_By__c,
                celsrm__Latest_Note__c            = 'Auto Generated Dispute',
                celsrm__Reason_Code__c            = '108 Short Payment',
                celsrm__Status__c                 = '10 New',
                celsrm__Transaction__c            = tx.Id
            ));
        }

        if (!toInsert.isEmpty()) {
            // This insert fires DisputeSyncTrigger:
            //   - BEFORE INSERT → SLAAssignedDaysService (BU-based SLA days)
            //   - AFTER INSERT  → SyncDisputeWithSAPService (SAP sync)
            insert toInsert;
        }
    }

    // ─── Dispute closure ─────────────────────────────────────────────────────

    private static void closeRelatedDisputes(Set<Id> transactionIds) {
        List<celsrm__Dispute__c> toClose = [
            SELECT Id
            FROM celsrm__Dispute__c
            WHERE celsrm__Transaction__c IN :transactionIds
              AND celsrm__Status__c != '60 Closed'
        ];

        if (toClose.isEmpty()) return;

        for (celsrm__Dispute__c d : toClose) {
            d.celsrm__Status__c = '60 Closed';
        }

        // This update fires DisputeSyncTrigger AFTER UPDATE → SAP sync
        // Status change is one of the watched fields in DisputeSyncTrigger
        update toClose;
    }

    // ─── Condition helpers ───────────────────────────────────────────────────

    private static Boolean isDocTypeMatch(celsrm__Transaction__c tx) {
        return tx.celsrm__Document_Type__c != null
            && DISPUTE_DOC_TYPES.contains(tx.celsrm__Document_Type__c);
    }

    private static Boolean isCloseDateCondition(
        celsrm__Transaction__c tx,
        celsrm__Transaction__c old
    ) {
        // "Is Changed" in Flow: on insert = field has a value; on update = value differs from before
        Boolean closeDateChanged = (old == null)
            ? tx.celsrm__Close_Date__c != null
            : tx.celsrm__Close_Date__c != old.celsrm__Close_Date__c;

        return closeDateChanged
            && tx.celsrm__Close_Date__c != null
            && tx.celsrm__Disputed_Amount__c != null
            && tx.celsrm__Disputed_Amount__c != 0;
    }
}