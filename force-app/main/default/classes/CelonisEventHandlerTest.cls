/**************************************************************************************************
CLASS
CelonisEventHandlerTest.cls
**************************************************************************************************/
@isTest
private class CelonisEventHandlerTest {

    // Assumes CelonisEventTrigger (before insert) calls
    // CelonisEventHandler.validateBeforeInsert(Trigger.new)

    private static final Integer GRACE_PERIOD_HOURS = 24;

    // ============================================================
    // TEST DATA HELPERS
    // ============================================================

    private static Account createAccount() {
        Account acc = new Account(Name = 'Test Account P2P');
        insert acc;
        return acc;
    }

    private static celsrm__Transaction__c createTransaction(Id accId, String statusEvent) {
        celsrm__Transaction__c tx = new celsrm__Transaction__c(
            celsrm__Account__c = accId,
            Status_Event__c = statusEvent
        );
        insert tx;
        return tx;
    }

    private static celsrm__Celonis_Event__c createEvent(Id txId, String eventName) {
        celsrm__Celonis_Event__c ev = new celsrm__Celonis_Event__c(
            Name = eventName,
            celsrm__Transaction__c = txId
        );
        insert ev;
        return ev;
    }

    // Pushes a record's CreatedDate back in time, simulating age for the 24h window logic.
    private static void ageRecord(Id recordId, Integer hoursAgo) {
        Test.setCreatedDate(recordId, Datetime.now().addHours(-hoursAgo));
    }

    // ============================================================
    // SCENARIO 1: Reversal within 24h — should NOT count toward the limit
    // ============================================================

    @isTest
    static void testReversalWithin24Hours_DoesNotCount() {
        Account acc = createAccount();
        celsrm__Transaction__c tx = createTransaction(acc.Id, '10');

        celsrm__Celonis_Event__c promise1 = createEvent(tx.Id, 'Promise To Pay');

        Test.startTest();
        // Reversed almost immediately (well within the 24h grace period)
        createEvent(tx.Id, 'Promise Reversed');

        // A second promise should be allowed — promise1 must not count
        Boolean errorThrown = false;
        try {
            createEvent(tx.Id, 'Promise To Pay');
        } catch (DmlException e) {
            errorThrown = true;
        }
        Test.stopTest();

        System.assert(!errorThrown, 'A promise reversed within 24h should not block a new one.');
    }

    // ============================================================
    // SCENARIO 2: Reversal after 24h — counts, and blocks the 3rd promise
    // ============================================================

    @isTest
    static void testReversalAfter24Hours_CountsTowardLimit() {
        Account acc = createAccount();
        celsrm__Transaction__c tx = createTransaction(acc.Id, '10');

        // Promise 1: created 30h ago, reversed now -> outside grace period, counts
        celsrm__Celonis_Event__c promise1 = createEvent(tx.Id, 'Promise To Pay');
        ageRecord(promise1.Id, 30);
        createEvent(tx.Id, 'Promise Reversed');

        // Promise 2: same pattern -> also counts. Total reaches 2.
        celsrm__Celonis_Event__c promise2 = createEvent(tx.Id, 'Promise To Pay');
        ageRecord(promise2.Id, 30);
        createEvent(tx.Id, 'Promise Reversed');

        Test.startTest();
        DmlException caught = null;
        try {
            createEvent(tx.Id, 'Promise To Pay');
        } catch (DmlException e) {
            caught = e;
        }
        Test.stopTest();

        System.assertNotEquals(null, caught, 'Third promise should be blocked once 2 count toward the limit.');
        System.assert(
            caught.getMessage().contains('Maximum 2 Promise To Pay allowed.'),
            'Unexpected error message: ' + caught.getMessage()
        );
    }

    // ============================================================
    // SCENARIO 3: Active promise blocks a second one
    // ============================================================

    @isTest
    static void testActivePromiseBlocksSecond() {
        Account acc = createAccount();
        celsrm__Transaction__c tx = createTransaction(acc.Id, '10');

        createEvent(tx.Id, 'Promise To Pay'); // left open, never reversed

        Test.startTest();
        DmlException caught = null;
        try {
            createEvent(tx.Id, 'Promise To Pay');
        } catch (DmlException e) {
            caught = e;
        }
        Test.stopTest();

        System.assertNotEquals(null, caught, 'A second promise should be blocked while one is still active.');
        System.assert(
            caught.getMessage().contains('Only 1 active Promise To Pay allowed.'),
            'Unexpected error message: ' + caught.getMessage()
        );
    }

    // ============================================================
    // SCENARIO 4: Closed transaction blocks any new promise
    // ============================================================

    @isTest
    static void testClosedTransactionBlocksPromise() {
        Account acc = createAccount();
        celsrm__Transaction__c tx = createTransaction(acc.Id, '20'); // closed

        Test.startTest();
        DmlException caught = null;
        try {
            createEvent(tx.Id, 'Promise To Pay');
        } catch (DmlException e) {
            caught = e;
        }
        Test.stopTest();

        System.assertNotEquals(null, caught, 'A closed transaction should reject new promises.');
        System.assert(
            caught.getMessage().contains('Transaction is closed.'),
            'Unexpected error message: ' + caught.getMessage()
        );
    }

    // ============================================================
    // SCENARIO 5: Boundary — just under vs. just over 24h
    // ============================================================

    @isTest
    static void testGracePeriodBoundary() {
        Account acc = createAccount();

        // Just under 24h -> excluded from the count
        celsrm__Transaction__c tx1 = createTransaction(acc.Id, '10');
        celsrm__Celonis_Event__c promiseA = createEvent(tx1.Id, 'Promise To Pay');
        ageRecord(promiseA.Id, 23); // reversed ~23h after creation
        createEvent(tx1.Id, 'Promise Reversed');

        // Just over 24h -> counted
        celsrm__Transaction__c tx2 = createTransaction(acc.Id, '10');
        celsrm__Celonis_Event__c promiseB = createEvent(tx2.Id, 'Promise To Pay');
        ageRecord(promiseB.Id, 25); // reversed ~25h after creation
        createEvent(tx2.Id, 'Promise Reversed');

        Test.startTest();

        // tx1: promiseA excluded -> a new promise should be allowed without hitting the limit
        Boolean tx1ErrorThrown = false;
        try {
            createEvent(tx1.Id, 'Promise To Pay');
        } catch (DmlException e) {
            tx1ErrorThrown = true;
        }

        // tx2: promiseB counted, but that's only 1/2 -> a second promise should still be allowed
        Boolean tx2ErrorThrown = false;
        try {
            createEvent(tx2.Id, 'Promise To Pay');
        } catch (DmlException e) {
            tx2ErrorThrown = true;
        }

        Test.stopTest();

        System.assert(!tx1ErrorThrown, 'Promise reversed just under 24h should not count toward the limit.');
        System.assert(!tx2ErrorThrown, 'A single promise reversed just over 24h should not yet hit the 2-promise limit.');
    }

    // ============================================================
    // SCENARIO 6: Bulkification — multiple transactions in one DML, no cross-contamination
    // ============================================================

    @isTest
    static void testBulkInsertAcrossMultipleTransactions() {
        Account acc = createAccount();
        celsrm__Transaction__c tx1 = createTransaction(acc.Id, '10');
        celsrm__Transaction__c tx2 = createTransaction(acc.Id, '10');

        List<celsrm__Celonis_Event__c> events = new List<celsrm__Celonis_Event__c>{
            new celsrm__Celonis_Event__c(Name = 'Promise To Pay', celsrm__Transaction__c = tx1.Id),
            new celsrm__Celonis_Event__c(Name = 'Promise To Pay', celsrm__Transaction__c = tx2.Id)
        };

        Test.startTest();
        Boolean errorThrown = false;
        try {
            insert events;
        } catch (DmlException e) {
            errorThrown = true;
        }
        Test.stopTest();

        System.assert(!errorThrown, 'Independent transactions in the same bulk insert should not interfere with each other.');
    }
}