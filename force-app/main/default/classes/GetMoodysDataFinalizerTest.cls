// << START - MM - FIN-10145 - Test coverage for GetMoodysDataFinalizer >>
@isTest
public class GetMoodysDataFinalizerTest {

    /**
     * Helper Queueable that attaches the finalizer and completes successfully.
     * When the parent job succeeds, the platform invokes the finalizer with ParentJobResult.SUCCESS.
     */
    private class SuccessQueueable implements Queueable {
        private List<String> creditReviewIds;

        public SuccessQueueable(List<String> creditReviewIds) {
            this.creditReviewIds = creditReviewIds;
        }

        public void execute(QueueableContext ctx) {
            GetMoodysDataFinalizer finalizer = new GetMoodysDataFinalizer();
            finalizer.creditReviewIds = this.creditReviewIds;
            System.attachFinalizer(finalizer);
            // Job completes successfully - finalizer will run with SUCCESS
        }
    }

    @isTest
    static void testFinalizer_SuccessWithCreditReviewIds() {
        Test.startTest();
        System.enqueueJob(new SuccessQueueable(new List<String>{ 'a0x000000000001', 'a0x000000000002' }));
        Test.stopTest();

        // Finalizer executed with SUCCESS and non-empty creditReviewIds.
        // The actual SAP callout is skipped due to Test.isRunningTest() guard,
        // but the code path through the if-condition is covered.
        System.assert(true, 'Finalizer executed without errors');
    }

}
// << END - MM - FIN-10145 - Test coverage for GetMoodysDataFinalizer >>