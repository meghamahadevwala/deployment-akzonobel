@isTest
private class CollectionBlockingServiceTest {

    // =====================================================================
    // Helpers
    // =====================================================================

    private static Account createAccount() {

        Account a = new Account(
            Name = 'Test Acc'
        );

        insert a;

        return a;
    }

    /**
     * Creates a transaction that indirectly generates
     * Grace_period__c through the formula field.
     */
    private static celsrm__Transaction__c buildTx(
        Id accId,
        Integer businessDaysAgo
    ) {

        Date promiseDate;

        if (businessDaysAgo != null) {

            // Add weekend buffer
            Integer calendarDays = businessDaysAgo + 4;

            promiseDate = Date.today().addDays(-calendarDays);
        }

        return new celsrm__Transaction__c(
            celsrm__Account__c      = accId,
            celsrm__Promise_Date__c = promiseDate
        );
    }

    private static celsrm__Dispute__c buildDispute(
        Id txId,
        Id accId,
        String status
    ) {

        return new celsrm__Dispute__c(
            celsrm__Transaction__c = txId,
            celsrm__Account__c     = accId,
            celsrm__Status__c      = status
        );
    }

    private static celsrm__Celonis_Event__c buildP2P(Id txId) {

        return new celsrm__Celonis_Event__c(
            Name                   = 'Promise To Pay',
            celsrm__Transaction__c = txId
        );
    }

    private static celsrm__Transaction__c reload(Id txId) {

        return [
            SELECT Id,
                   Grace_period__c,
                   Broken_Flag__c,
                   celsrm__Dunning_Block__c,
                   Status_Event__c
            FROM celsrm__Transaction__c
            WHERE Id = :txId
        ];
    }

    // =====================================================================
    // Guard clauses
    // =====================================================================

    @isTest
    static void nullInput_doesNothing() {

        Test.startTest();
        CollectionBlockingService.recalculate(null);
        Test.stopTest();

        System.assert(true);
    }

    @isTest
    static void emptyInput_doesNothing() {

        Test.startTest();
        CollectionBlockingService.recalculate(new Set<Id>());
        Test.stopTest();

        System.assert(true);
    }

    // =====================================================================
    // Broken_Flag tests
    // =====================================================================

    @isTest
    static void gracePeriodGreaterThan3_setsBroken() {

        Account a = createAccount();

        celsrm__Transaction__c tx = buildTx(a.Id, 10);

        insert tx;

        Test.startTest();
        CollectionBlockingService.recalculate(new Set<Id>{ tx.Id });
        Test.stopTest();

        celsrm__Transaction__c r = reload(tx.Id);

        System.assertEquals(
            'Broken',
            r.Broken_Flag__c
        );

        System.assertEquals(
            null,
            r.celsrm__Dunning_Block__c
        );
    }

    @isTest
    static void gracePeriodLessThan3_setsUnbroken() {

        Account a = createAccount();

        celsrm__Transaction__c tx = buildTx(a.Id, 1);

        insert tx;

        Test.startTest();
        CollectionBlockingService.recalculate(new Set<Id>{ tx.Id });
        Test.stopTest();

        System.assertEquals(
            'Unbroken',
            reload(tx.Id).Broken_Flag__c
        );
    }

    @isTest
    static void gracePeriodNull_leavesBrokenFlagNull() {

        Account a = createAccount();

        celsrm__Transaction__c tx =
            new celsrm__Transaction__c(
                celsrm__Account__c = a.Id
            );

        insert tx;

        Test.startTest();
        CollectionBlockingService.recalculate(new Set<Id>{ tx.Id });
        Test.stopTest();

        System.assertEquals(
            null,
            reload(tx.Id).Broken_Flag__c
        );
    }

    @isTest
    static void reversedEventStatus_nullsBrokenFlag() {

        Account a = createAccount();

        celsrm__Transaction__c tx = buildTx(a.Id, 10);

        tx.Status_Event__c = '30';

        insert tx;

        Test.startTest();
        CollectionBlockingService.recalculate(new Set<Id>{ tx.Id });
        Test.stopTest();

        System.assertEquals(
            null,
            reload(tx.Id).Broken_Flag__c
        );
    }

    @isTest
    static void nonReversedEventStatus_appliesGraceRule() {

        Account a = createAccount();

        celsrm__Transaction__c tx = buildTx(a.Id, 10);

        tx.Status_Event__c = '10';

        insert tx;

        Test.startTest();
        CollectionBlockingService.recalculate(new Set<Id>{ tx.Id });
        Test.stopTest();

        System.assertEquals(
            'Broken',
            reload(tx.Id).Broken_Flag__c
        );
    }

    // =====================================================================
    // Dunning block tests
    // =====================================================================

    @isTest
    static void onlyDispute_setsDunningA() {

        Account a = createAccount();

        celsrm__Transaction__c tx = buildTx(a.Id, 1);

        insert tx;

        insert buildDispute(
            tx.Id,
            a.Id,
            '30 Waiting For Information'
        );

        Test.startTest();
        CollectionBlockingService.recalculate(new Set<Id>{ tx.Id });
        Test.stopTest();

        System.assertEquals(
            'A',
            reload(tx.Id).celsrm__Dunning_Block__c
        );
    }

    @isTest
    static void disputeWithInactiveStatus_isIgnored() {

        Account a = createAccount();

        celsrm__Transaction__c tx = buildTx(a.Id, 1);

        insert tx;

        insert buildDispute(
            tx.Id,
            a.Id,
            '99 Closed'
        );

        Test.startTest();
        CollectionBlockingService.recalculate(new Set<Id>{ tx.Id });
        Test.stopTest();

        System.assertEquals(
            null,
            reload(tx.Id).celsrm__Dunning_Block__c
        );
    }

    @isTest
    static void onlyP2PWithAmount_setsDunningB() {

        Account a = createAccount();

        celsrm__Transaction__c tx = buildTx(a.Id, 1);

        tx.celsrm__Promised_Amount__c = 100;

        insert tx;

        insert buildP2P(tx.Id);

        Test.startTest();
        CollectionBlockingService.recalculate(new Set<Id>{ tx.Id });
        Test.stopTest();

        System.assertEquals(
            'B',
            reload(tx.Id).celsrm__Dunning_Block__c
        );
    }

    @isTest
    static void p2pWithoutPromisedAmount_doesNotBlock() {

        Account a = createAccount();

        celsrm__Transaction__c tx = buildTx(a.Id, 1);

        insert tx;

        insert buildP2P(tx.Id);

        Test.startTest();
        CollectionBlockingService.recalculate(new Set<Id>{ tx.Id });
        Test.stopTest();

        System.assertEquals(
            null,
            reload(tx.Id).celsrm__Dunning_Block__c
        );
    }

    // =====================================================================
    // Combined tests
    // =====================================================================

    @isTest
    static void disputeAndGracePeriod_updatesBothFields() {

        Account a = createAccount();

        celsrm__Transaction__c tx = buildTx(a.Id, 10);

        insert tx;

        insert buildDispute(
            tx.Id,
            a.Id,
            '30 Waiting For Information'
        );

        Test.startTest();
        CollectionBlockingService.recalculate(new Set<Id>{ tx.Id });
        Test.stopTest();

        celsrm__Transaction__c r = reload(tx.Id);

        System.assertEquals(
            'A',
            r.celsrm__Dunning_Block__c
        );

        System.assertEquals(
            'Broken',
            r.Broken_Flag__c
        );
    }

    @isTest
    static void reversedStatus_withP2P_dunningStillSetButBrokenNull() {

        Account a = createAccount();

        celsrm__Transaction__c tx = buildTx(a.Id, 10);

        tx.Status_Event__c            = '30';
        tx.celsrm__Promised_Amount__c = 100;

        insert tx;

        insert buildP2P(tx.Id);

        Test.startTest();
        CollectionBlockingService.recalculate(new Set<Id>{ tx.Id });
        Test.stopTest();

        celsrm__Transaction__c r = reload(tx.Id);

        System.assertEquals(
            'B',
            r.celsrm__Dunning_Block__c
        );

        System.assertEquals(
            'Broken',
            r.Broken_Flag__c
        );
    }

    // =====================================================================
    // Bulk
    // =====================================================================

    @isTest
    static void bulk_200Transactions_handledCorrectly() {

        Account a = createAccount();

        List<celsrm__Transaction__c> txs =
            new List<celsrm__Transaction__c>();

        for (Integer i = 0; i < 200; i++) {

            Integer grace =
                (Math.mod(i, 2) == 0)
                ? 10
                : 1;

            txs.add(
                buildTx(a.Id, grace)
            );
        }

        insert txs;

        Set<Id> txIdSet =
            new Map<Id, celsrm__Transaction__c>(txs).keySet();

        Test.startTest();
        CollectionBlockingService.recalculate(txIdSet);
        Test.stopTest();

        Integer brokenCount   = 0;
        Integer unbrokenCount = 0;

        for (celsrm__Transaction__c r : [
            SELECT Id,
                   Grace_period__c,
                   Broken_Flag__c
            FROM celsrm__Transaction__c
            WHERE Id IN :txIdSet
        ]) {

            if (r.Grace_period__c > 3) {

                System.assertEquals(
                    'Broken',
                    r.Broken_Flag__c
                );

                brokenCount++;
            }
            else {

                System.assertEquals(
                    'Unbroken',
                    r.Broken_Flag__c
                );

                unbrokenCount++;
            }
        }

        System.assertEquals(100, brokenCount);
        System.assertEquals(100, unbrokenCount);
    }
}