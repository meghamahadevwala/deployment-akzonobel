// << START - MM - FIN-10145 - Fix Too many queueable jobs error by using Finalizer for UpdateLimitInSourceSystemService >>
public with sharing class GetMoodysDataFinalizer implements Finalizer {
    public List<String> creditReviewIds;
    // Accounts whose Risk Class / Check Rule changed during GetMoodysDataService and must be synced to CFin.
    public List<String> profileSyncAccountIds;

    public GetMoodysDataFinalizer() {
        this.creditReviewIds = new List<String>();
        this.profileSyncAccountIds = new List<String>();
    }

    /**
     * @description A Finalizer can enqueue only ONE Queueable job. When both the CFin profile sync and the
     * SAP credit limit update are pending, the profile sync job is enqueued here and carries the Credit
     * Review Ids along; UpdateProfileDataInSourceSystemService triggers the credit limit update once its
     * last chunk finishes. This keeps a single chain of jobs instead of two parallel enqueues.
     *
     * Test.isRunningTest() only wraps the actual enqueue calls, so the branching logic stays covered
     * by GetMoodysDataServiceTest (Finalizers run on Test.stopTest()).
     */
    public void execute(FinalizerContext ctx) {
        if (ctx.getResult() != ParentJobResult.SUCCESS) {
            return;
        }

        Boolean hasProfileSync = profileSyncAccountIds != null && !profileSyncAccountIds.isEmpty();
        Boolean hasLimitUpdates = creditReviewIds != null && !creditReviewIds.isEmpty();

        if (hasProfileSync) {
            UpdateProfileDataInSourceSystemService profileJob = new UpdateProfileDataInSourceSystemService(
                profileSyncAccountIds,
                hasLimitUpdates ? creditReviewIds : null
            );
            if (!Test.isRunningTest()) {
                System.enqueueJob(profileJob);
            }
        } else if (hasLimitUpdates) {
            if (!Test.isRunningTest()) {
                UpdateLimitInSourceSystemService.updateCreditLimitInSAP(creditReviewIds);
            }
        }
    }
}
// << END - MM - FIN-10145 - Fix Too many queueable jobs error by using Finalizer for UpdateLimitInSourceSystemService >>