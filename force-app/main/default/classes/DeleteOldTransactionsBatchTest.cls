@IsTest
private class DeleteOldTransactionsBatchTest {

    // ── Test Setup ────────────────────────────────────────────────────────────

    @TestSetup
    static void createTestData() {
        insert new Account(Name = 'Test Account for Batch Processing');
    }

    private static Id getTestAccountId() {
        return [
            SELECT Id 
            FROM Account 
            WHERE Name = 'Test Account for Batch Processing' 
            LIMIT 1
        ].Id;
    }

    // ── Helper Methods ────────────────────────────────────────────────────────

    private static List<celsrm__Transaction__c> createTransactions(
        Integer quantity, 
        Date closeDate
    ) {
        Id accountId = getTestAccountId();
        List<celsrm__Transaction__c> transactions = new List<celsrm__Transaction__c>();

        for (Integer i = 0; i < quantity; i++) {
            transactions.add(new celsrm__Transaction__c(
                celsrm__Account__c    = accountId,
                celsrm__Close_Date__c = closeDate
                // Add additional required fields here if necessary
            ));
        }

        insert transactions;
        return transactions;
    }

    private static void verifyRecordsInserted(List<celsrm__Transaction__c> records) {
        Integer countFound = [
            SELECT COUNT() 
            FROM celsrm__Transaction__c 
            WHERE Id IN :records
        ];

        System.assertEquals(
            records.size(),
            countFound,
            'Test setup failed: Not all records were inserted. Verify required fields.'
        );
    }

    // ── Scenario 1: Old Records Should Be Deleted ─────────────────────────────

    @IsTest
    static void testOldRecordsAreDeleted() {
        List<celsrm__Transaction__c> oldTransactions =
            createTransactions(5, Date.today().addDays(-401));

        verifyRecordsInserted(oldTransactions);

        Test.startTest();
        Database.executeBatch(new DeleteOldTransactionsBatch(), 200);
        Test.stopTest();

        System.assertEquals(
            0,
            [SELECT COUNT() FROM celsrm__Transaction__c WHERE Id IN :oldTransactions],
            'All transactions older than 400 days should be deleted.'
        );
    }

    // ── Scenario 2: Recent Records Should Be Preserved ─────────────────────────

    @IsTest
    static void testRecentRecordsArePreserved() {
        List<celsrm__Transaction__c> recentTransactions =
            createTransactions(5, Date.today().addDays(-399));

        verifyRecordsInserted(recentTransactions);

        Test.startTest();
        Database.executeBatch(new DeleteOldTransactionsBatch(), 200);
        Test.stopTest();

        System.assertEquals(
            5,
            [SELECT COUNT() FROM celsrm__Transaction__c WHERE Id IN :recentTransactions],
            'Transactions newer than 400 days should NOT be deleted.'
        );
    }

    // ── Scenario 3: Boundary Condition (Exactly 400 Days) ─────────────────────

    @IsTest
    static void testBoundaryDateIsPreserved() {
        List<celsrm__Transaction__c> boundaryTransactions =
            createTransactions(3, Date.today().addDays(-400));

        verifyRecordsInserted(boundaryTransactions);

        Test.startTest();
        Database.executeBatch(new DeleteOldTransactionsBatch(), 200);
        Test.stopTest();

        System.assertEquals(
            3,
            [SELECT COUNT() FROM celsrm__Transaction__c WHERE Id IN :boundaryTransactions],
            'Transactions exactly 400 days old should NOT be deleted (strict comparison).'
        );
    }

    // ── Scenario 4: Null Close Date Should Be Ignored ─────────────────────────

    @IsTest
    static void testNullCloseDateIsIgnored() {
        List<celsrm__Transaction__c> nullDateTransactions =
            createTransactions(3, null);

        verifyRecordsInserted(nullDateTransactions);

        Test.startTest();
        Database.executeBatch(new DeleteOldTransactionsBatch(), 200);
        Test.stopTest();

        System.assertEquals(
            3,
            [SELECT COUNT() FROM celsrm__Transaction__c WHERE Id IN :nullDateTransactions],
            'Transactions with null Close Date should NOT be deleted.'
        );
    }

    // ── Scenario 5: Mixed Dataset ─────────────────────────────────────────────

    @IsTest
    static void testMixedDataDeletesOnlyOldRecords() {
        List<celsrm__Transaction__c> oldTransactions =
            createTransactions(4, Date.today().addDays(-500));

        List<celsrm__Transaction__c> recentTransactions =
            createTransactions(4, Date.today().addDays(-100));

        verifyRecordsInserted(oldTransactions);
        verifyRecordsInserted(recentTransactions);

        Test.startTest();
        Database.executeBatch(new DeleteOldTransactionsBatch(), 200);
        Test.stopTest();

        System.assertEquals(
            0,
            [SELECT COUNT() FROM celsrm__Transaction__c WHERE Id IN :oldTransactions],
            'Old transactions must be deleted.'
        );

        System.assertEquals(
            4,
            [SELECT COUNT() FROM celsrm__Transaction__c WHERE Id IN :recentTransactions],
            'Recent transactions must remain.'
        );
    }

    // ── Scenario 6: Schedulable Execution ─────────────────────────────────────

    @IsTest
    static void testSchedulableExecution() {
        String cronExpression = '0 30 0 ? * SUN';
        String jobName = 'Delete Old Transactions Weekly TEST';

        Test.startTest();
        String jobId = System.schedule(jobName, cronExpression, new DeleteOldTransactionsBatch());
        Test.stopTest();

        CronTrigger cronTrigger = [
            SELECT Id, CronExpression, State 
            FROM CronTrigger 
            WHERE Id = :jobId
        ];

        System.assertEquals(
            cronExpression,
            cronTrigger.CronExpression,
            'CRON expression should match the scheduled value.'
        );

        System.assertEquals(
            'WAITING',
            cronTrigger.State,
            'Scheduled job should be in WAITING state.'
        );
    }

    // ── Scenario 7: Empty Dataset Should Not Fail ─────────────────────────────

    @IsTest
    static void testEmptyDatasetDoesNotFail() {
        Test.startTest();
        Database.executeBatch(new DeleteOldTransactionsBatch(), 200);
        Test.stopTest();

        System.assert(true, 'Batch execution should complete without errors.');
    }
}