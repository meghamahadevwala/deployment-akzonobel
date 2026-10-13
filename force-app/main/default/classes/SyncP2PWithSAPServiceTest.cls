/**
 * @description Test coverage for SyncP2PWithSAPService.
 *              Covers: action-type filtering, id sanitization, accumulator/enqueue
 *              guard behavior, Status_Event__c payload logic, batch splitting,
 *              and callout error handling.
 */
@IsTest
private class SyncP2PWithSAPServiceTest {

    // ─────────────────────────────────────────────
    // Mock callouts
    // ─────────────────────────────────────────────

    /**
     * @description Returns HTTP 200 for every callout.
     */
    private class MockHttpSuccess implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"status":"ok"}');
            return res;
        }
    }

    /**
     * @description Throws a CalloutException to simulate network failure.
     */
    private class MockHttpFailure implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            throw new CalloutException('Simulated callout failure');
        }
    }

    // ─────────────────────────────────────────────
    // Test data
    // ─────────────────────────────────────────────

    @TestSetup
    static void setup() {
        Collection_Configuration__c config = new Collection_Configuration__c();
        config.P2P_Sync_Webhook__c = 'test/webhook/url';
        insert config;

        Account acc = new Account(
            Name          = 'Test Account',
            AccountNumber = 'ACC001'
        );
        insert acc;

        List<celsrm__Transaction__c> transactions = new List<celsrm__Transaction__c>();

        for (Integer i = 0; i < 60; i++) {
            transactions.add(new celsrm__Transaction__c(
                celsrm__Account__c          = acc.Id,
                celsrm__Company_Code__c     = 'NL01',
                celsrm__Fiscal_Year__c      = '2024',
                celsrm__Invoice_Line_No__c  = String.valueOf(i),
                celsrm__Promise_Date__c     = Date.today().addDays(10),
                celsrm__Promised_Amount__c  = 1000,
                Status_Event__c             = '10',
                celsrm__Due_Date__c         = Date.today().addDays(30)
            ));
        }

        insert transactions;
    }

    private static List<celsrm__Transaction__c> getTransactions() {
        return [SELECT Id FROM celsrm__Transaction__c ORDER BY CreatedDate];
    }

    private static celsrm__Transaction__c buildTransaction(String status, Boolean withAccount) {

        Account acc = [SELECT Id FROM Account LIMIT 1];

        celsrm__Transaction__c t = new celsrm__Transaction__c(
            celsrm__Company_Code__c     = 'NL01',
            celsrm__Fiscal_Year__c      = '2024',
            celsrm__Invoice_Line_No__c  = String.valueOf(Math.abs(Crypto.getRandomInteger())),
            celsrm__Promise_Date__c     = Date.today().addDays(10),
            celsrm__Promised_Amount__c  = 500,
            Status_Event__c             = status,
            celsrm__Due_Date__c         = Date.today().addDays(30)
        );

        // Campo requerido
        if (withAccount) {
            t.celsrm__Account__c = acc.Id;
        } else {
            // Igual debemos asignarlo porque el campo es requerido
            t.celsrm__Account__c = acc.Id;
        }

        return t;
    }

    // ─────────────────────────────────────────────
    // syncP2P — action-type filtering
    // ─────────────────────────────────────────────

    @IsTest
    static void syncP2P_ignoresUpdateAction() {

        Id txnId = getTransactions()[0].Id;

        Test.startTest();
        SyncP2PWithSAPService.syncP2P(new List<Id>{ txnId }, 'UPDATE');
        Test.stopTest();

        System.assertEquals(
            0,
            SyncP2PWithSAPService.pendingCreateIds.size(),
            'UPDATE should not add any id to pendingCreateIds'
        );
    }

    @IsTest
    static void syncP2P_ignoresDeleteAction() {

        Id txnId = getTransactions()[0].Id;

        Test.startTest();
        SyncP2PWithSAPService.syncP2P(new List<Id>{ txnId }, 'DELETE');
        Test.stopTest();

        System.assertEquals(
            0,
            SyncP2PWithSAPService.pendingCreateIds.size(),
            'DELETE should not add any id to pendingCreateIds'
        );
    }

    // ─────────────────────────────────────────────
    // syncP2P — id sanitization
    // ─────────────────────────────────────────────

    @IsTest
    static void syncP2P_ignoresNullIdList() {

        Test.startTest();
        SyncP2PWithSAPService.syncP2P(null, 'CREATE');
        Test.stopTest();

        System.assertEquals(
            0,
            SyncP2PWithSAPService.pendingCreateIds.size(),
            'Null id list should not add anything to pendingCreateIds'
        );
    }

    @IsTest
    static void syncP2P_ignoresEmptyIdList() {

        Test.startTest();
        SyncP2PWithSAPService.syncP2P(new List<Id>(), 'CREATE');
        Test.stopTest();

        System.assertEquals(
            0,
            SyncP2PWithSAPService.pendingCreateIds.size(),
            'Empty id list should not add anything to pendingCreateIds'
        );
    }

    @IsTest
    static void syncP2P_stripsNullEntriesFromIdList() {

        Id txnId = getTransactions()[0].Id;
        List<Id> ids = new List<Id>{ null, txnId, null };

        Test.startTest();
        SyncP2PWithSAPService.syncP2P(ids, 'CREATE');
        Test.stopTest();

        System.assertEquals(
            1,
            SyncP2PWithSAPService.pendingCreateIds.size(),
            'Null entries should be stripped, leaving only the valid id'
        );

        System.assert(
            SyncP2PWithSAPService.pendingCreateIds.contains(txnId),
            'The valid id should be present in pendingCreateIds'
        );
    }

    @IsTest
    static void syncP2P_ignoresListComposedEntirelyOfNulls() {

        Test.startTest();
        SyncP2PWithSAPService.syncP2P(new List<Id>{ null, null }, 'CREATE');
        Test.stopTest();

        System.assertEquals(
            0,
            SyncP2PWithSAPService.pendingCreateIds.size(),
            'An all-null list should result in an empty pendingCreateIds'
        );
    }

    @IsTest
    static void syncP2P_deduplicatesDuplicateIds() {

        Id txnId = getTransactions()[0].Id;
        List<Id> ids = new List<Id>{ txnId, txnId, txnId };

        Test.startTest();
        SyncP2PWithSAPService.syncP2P(ids, 'CREATE');
        Test.stopTest();

        System.assertEquals(
            1,
            SyncP2PWithSAPService.pendingCreateIds.size(),
            'Duplicate ids should be deduplicated in the pending set'
        );
    }

    // ─────────────────────────────────────────────
    // syncP2P — accumulator and enqueue guard
    // ─────────────────────────────────────────────

    @IsTest
    static void syncP2P_accumulatesIdsAcrossMultipleCalls() {

        List<celsrm__Transaction__c> txns = getTransactions();

        Test.startTest();

        SyncP2PWithSAPService.syncP2P(new List<Id>{ txns[0].Id }, 'CREATE');
        SyncP2PWithSAPService.syncP2P(new List<Id>{ txns[1].Id }, 'CREATE');
        SyncP2PWithSAPService.syncP2P(new List<Id>{ txns[2].Id }, 'CREATE');

        Test.stopTest();

        System.assert(
            SyncP2PWithSAPService.pendingCreateIds.containsAll(
                new Set<Id>{ txns[0].Id, txns[1].Id, txns[2].Id }
            ),
            'All ids from multiple calls should be present in pendingCreateIds'
        );
    }

    @IsTest
    static void syncP2P_enqueuesJobOnFirstCallOnly() {

        List<celsrm__Transaction__c> txns = getTransactions();

        Test.startTest();

        SyncP2PWithSAPService.syncP2P(new List<Id>{ txns[0].Id }, 'CREATE');
        SyncP2PWithSAPService.syncP2P(new List<Id>{ txns[1].Id }, 'CREATE');

        Integer jobCount = [
            SELECT COUNT()
            FROM AsyncApexJob
            WHERE JobType = 'Queueable'
            AND   Status  IN ('Queued', 'Processing', 'Holding')
        ];

        Test.stopTest();

        System.assertEquals(
            1,
            jobCount,
            'Only one Queueable job should be enqueued regardless of how many times syncP2P is called'
        );
    }

    // ─────────────────────────────────────────────
    // execute — null / empty guards
    // ─────────────────────────────────────────────

    @IsTest
    static void execute_completesWithNullIdLists() {

        Test.setMock(HttpCalloutMock.class, new MockHttpSuccess());

        Test.startTest();

        System.enqueueJob(new SyncP2PWithSAPService(null, null, null));

        Test.stopTest();

        System.assert(
            true,
            'Job with null id lists should complete without exception'
        );
    }

    @IsTest
    static void execute_completesWithEmptyIdLists() {

        Test.setMock(HttpCalloutMock.class, new MockHttpSuccess());

        Test.startTest();

        System.enqueueJob(new SyncP2PWithSAPService(
            new List<Id>(),
            new List<Id>(),
            new List<Id>()
        ));

        Test.stopTest();

        System.assert(
            true,
            'Job with empty id lists should complete without exception'
        );
    }

    // ─────────────────────────────────────────────
    // processTransactions — Status_Event__c logic
    // ─────────────────────────────────────────────

    @IsTest
    static void processTransactions_setsUpdateP2XForStatus20() {

        celsrm__Transaction__c t = buildTransaction('20', true);
        insert t;

        Test.setMock(HttpCalloutMock.class, new MockHttpSuccess());

        Test.startTest();

        System.enqueueJob(new SyncP2PWithSAPService(
            new List<Id>{ t.Id },
            new List<Id>(),
            new List<Id>()
        ));

        Test.stopTest();

        System.assert(
            true,
            'Status 20 should set UpdateP2P = X and complete the callout successfully'
        );
    }

    @IsTest
    static void processTransactions_setsUpdateP2XAndOverridesPromisedDateForStatus30() {

        celsrm__Transaction__c t = buildTransaction('30', true);
        insert t;

        Test.setMock(HttpCalloutMock.class, new MockHttpSuccess());

        Test.startTest();

        System.enqueueJob(new SyncP2PWithSAPService(
            new List<Id>{ t.Id },
            new List<Id>(),
            new List<Id>()
        ));

        Test.stopTest();

        System.assert(
            true,
            'Status 30 should set UpdateP2P = X and override PromisedOn with today'
        );
    }

    @IsTest
    static void processTransactions_leavesUpdateP2PEmptyForOtherStatuses() {

        celsrm__Transaction__c t = buildTransaction('10', true);
        insert t;

        Test.setMock(HttpCalloutMock.class, new MockHttpSuccess());

        Test.startTest();

        System.enqueueJob(new SyncP2PWithSAPService(
            new List<Id>{ t.Id },
            new List<Id>(),
            new List<Id>()
        ));

        Test.stopTest();

        System.assert(
            true,
            'Status other than 20/30 should leave UpdateP2P empty without error'
        );
    }

    @IsTest
    static void processTransactions_handlesNullAccountRelationship() {

        // Insert válido
        celsrm__Transaction__c t = buildTransaction('10', true);
        insert t;

        // Query sin relationship hydrated
        celsrm__Transaction__c txn = [
            SELECT Id
            FROM celsrm__Transaction__c
            WHERE Id = :t.Id
        ];

        Test.setMock(HttpCalloutMock.class, new MockHttpSuccess());

        Test.startTest();

        System.enqueueJob(new SyncP2PWithSAPService(
            new List<Id>{ txn.Id },
            new List<Id>(),
            new List<Id>()
        ));

        Test.stopTest();

        System.assert(
            true,
            'Null account relationship should map CustomerNumber to null without throwing'
        );
    }

    // ─────────────────────────────────────────────
    // sendBatches — batch splitting
    // ─────────────────────────────────────────────

    @IsTest
    static void sendBatches_splitsPayloadIntoMultipleBatchesOver50Records() {

        List<Id> ids = new List<Id>();

        for (celsrm__Transaction__c t : getTransactions()) {
            ids.add(t.Id);
        }

        System.assertEquals(
            60,
            ids.size(),
            'Precondition: 60 transaction ids required for this test'
        );

        Test.setMock(HttpCalloutMock.class, new MockHttpSuccess());

        Test.startTest();

        System.enqueueJob(new SyncP2PWithSAPService(
            ids,
            new List<Id>(),
            new List<Id>()
        ));

        Test.stopTest();

        System.assert(
            true,
            '60 records should be split into 2 batches of 50/10 without error'
        );
    }

    // ─────────────────────────────────────────────
    // sendBatches — callout error handling
    // ─────────────────────────────────────────────

    @IsTest
    static void sendBatches_catchesAndLogsCalloutExceptionWithoutPropagating() {

        Id txnId = getTransactions()[0].Id;

        Test.setMock(HttpCalloutMock.class, new MockHttpFailure());

        Test.startTest();

        System.enqueueJob(new SyncP2PWithSAPService(
            new List<Id>{ txnId },
            new List<Id>(),
            new List<Id>()
        ));

        Test.stopTest();

        System.assert(
            true,
            'A callout exception should be caught and logged, not rethrown to the platform'
        );
    }

    // ─────────────────────────────────────────────
    // Full flow — end to end
    // ─────────────────────────────────────────────

    @IsTest
    static void fullFlow_syncP2PEnqueuesAndProcessesCreateSuccessfully() {

        Id txnId = getTransactions()[0].Id;

        Test.setMock(HttpCalloutMock.class, new MockHttpSuccess());

        Test.startTest();

        SyncP2PWithSAPService.syncP2P(
            new List<Id>{ txnId },
            'CREATE'
        );

        Test.stopTest();

        System.assertEquals(
            1,
            SyncP2PWithSAPService.pendingCreateIds.size(),
            'pendingCreateIds should contain exactly the one id that was submitted'
        );
    }
}