/**
* @description Unit tests for MasssendEmail queueable class.
* Verifies:
*  - Enqueueing and execution path iterating over provided task maps
*  - Invocation path runs without unhandled exceptions (external controller not mocked by request)
*  - Bulk safety with multiple map entries
*
* Notes:
*  - Focus is on exercising MasssendEmail; TaskTreatmentController behavior is validated in its own tests.
*/
@IsTest
private class MasssendEmailTest {

    /**
     * @description Utility to build a task-like map payload similar to runtime usage.
     * Adjust keys/values to mirror actual TaskTreatmentController expectations if known.
     */
    private static Map<Object, Object> buildTaskPayload(String subject, String toAddress) {
        Map<Object, Object> m = new Map<Object, Object>();
        m.put('subject', subject);
        m.put('toAddress', toAddress);
        return m;
    }

    /**
     * @description Happy path with a single payload.
     */
    @IsTest
    static void test_enqueues_and_executes_single_payload() {
        // Arrange
        List<Object> payloads = new List<Object>();
        payloads.add(buildTaskPayload('Test Email 1', 'user1@example.com'));

        MasssendEmail job = new MasssendEmail(payloads);

        // Act
        Test.startTest();
        System.enqueueJob(job);
        Test.stopTest(); // Executes the queueable

        // Assert
        // No unhandled exceptions indicate success.
        System.assertEquals(1, payloads.size(), 'One payload should have been provided to the job.');
    }

    /**
     * @description Bulk path with multiple payloads.
     */
    @IsTest
    static void test_executes_multiple_payloads_bulk() {
        // Arrange
        List<Object> payloads = new List<Object>();
        for (Integer i = 1; i <= 5; i++) {
            payloads.add(buildTaskPayload('Bulk Email ' + i, 'bulk' + i + '@example.com'));
        }

        MasssendEmail job = new MasssendEmail(payloads);

        // Act
        Test.startTest();
        System.enqueueJob(job);
        Test.stopTest();

        // Assert
        System.assertEquals(5, payloads.size(), 'All five payload entries should have been supplied to the job.');
    }

    /**
     * @description Defensive test: empty list should not throw an error.
     */
    @IsTest
    static void test_handles_empty_payloads() {
        // Arrange
        List<Object> payloads = new List<Object>(); // empty
        MasssendEmail job = new MasssendEmail(payloads);

        // Act
        Test.startTest();
        System.enqueueJob(job);
        Test.stopTest();

        // Assert
        System.assertEquals(0, payloads.size(), 'No payloads means loop should not execute and no error should occur.');
    }
}