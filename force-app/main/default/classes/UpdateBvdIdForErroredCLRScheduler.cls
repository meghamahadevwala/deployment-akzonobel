/**
 * MM - FIN-10426
 *
 * @description Scheduled retry for Accounts whose BvD ID writeback to CFIN failed.
 *              Modelled on UpdateProfileDataForErroredCLRScheduler, but the BvD service
 *              takes List<Map<String, String>> rather than a list of Ids, so the refMaps
 *              have to be rebuilt from the stored failure state:
 *
 *                - failed REMOVALS: one refMap per ID still listed in the comma-separated
 *                  BVD_IDs_To_Be_Removed__c (oldBvdId set, newBvdId blank)
 *                - failed ADD: one refMap using the current BvD_ID_Number__c
 *                  (newBvdId set, oldBvdId blank)
 *
 *              UpdateBvdIdInSourceSystemService skips the delete entry when oldBvdId is
 *              blank and the add entry when newBvdId is blank, so the two failure types
 *              retry independently and a success is never re-sent.
 *
 *              Removals are driven off BVD_IDs_To_Be_Removed__c, NOT off
 *              Remove_BvD_ID_From_CFIN_Message__c. That is deliberate. One Account can owe
 *              several removals while the Message field can only hold one outcome, so when
 *              a batch partially succeeds the surviving message is whichever response CFIN
 *              returned last and cannot be trusted. Since FIN-10426 the service calls
 *              removeBvdId() on success, so BVD_IDs_To_Be_Removed__c is the authoritative
 *              list of what is still outstanding: anything still in it needs retrying,
 *              and it empties to null once CFIN has accepted every removal. That makes a
 *              partial failure self-healing across runs.
 *
 *              This filter only works because BVD_IDs_To_Be_Removed__c was converted from
 *              Long Text Area to Text - Salesforce refuses to filter a LongTextArea in a
 *              WHERE clause. Do not convert it back.
 *
 *              The ADD half has no such list, so it still keys off Sync_BVD_ID_Messge__c
 *              (note: 'Messge' is the real API name). The filter is "present and not
 *              'Update successful'" rather than ProfileData's LIKE '%Error:%' because when
 *              CFIN returns a non-success STATUS_MSG the service stores that raw SAP text,
 *              which contains neither 'Error:' nor 'Exception'.
 */
global class UpdateBvdIdForErroredCLRScheduler implements Schedulable {

    private static final String SUCCESS_MSG = 'Update successful';
    private static final Integer RECORD_LIMIT = 1000;

    global void execute(SchedulableContext sc) {

        List<Account> accounts = [
            SELECT Id, AccountNumber, celsrm__Credit_Control_Area__c,
                   BvD_ID_Number__c, BVD_IDs_To_Be_Removed__c, Sync_BVD_ID_Messge__c
            FROM Account
            WHERE (BVD_IDs_To_Be_Removed__c != NULL
               OR (Sync_BVD_ID_Messge__c != NULL
                   AND Sync_BVD_ID_Messge__c != :SUCCESS_MSG))
            LIMIT :RECORD_LIMIT
        ];

        if (accounts.isEmpty()) {
            return;
        }

        List<Map<String, String>> refMapList = buildRefMapList(accounts);

        if (!refMapList.isEmpty() && !Test.isRunningTest()) {
            UpdateBvdIdInSourceSystemService.updateBvdIdInSAP(refMapList);
        }
    }

    /**
     * Split out from execute() and marked @TestVisible so the refMap-building rules
     * (comma splitting, dedup, the AccountNumber guard, the add-vs-remove split) can be
     * asserted directly. The handoff to the service in execute() sits behind
     * !Test.isRunningTest(), so this is the only part a test can meaningfully verify.
     */
    @TestVisible
    private static List<Map<String, String>> buildRefMapList(List<Account> accounts) {

        List<Map<String, String>> refMapList = new List<Map<String, String>>();

        for (Account acc : accounts) {

            // accountNumber is the CFIN partner key - nothing can be sent without it
            if (String.isBlank(acc.AccountNumber)) {
                continue;
            }

            // Outstanding removals: one refMap per pending ID
            if (String.isNotBlank(acc.BVD_IDs_To_Be_Removed__c)) {
                Set<String> pendingIds = new Set<String>();
                for (String pendingId : acc.BVD_IDs_To_Be_Removed__c.split(',')) {
                    if (String.isNotBlank(pendingId)) {
                        pendingIds.add(pendingId.trim());
                    }
                }
                for (String pendingId : pendingIds) {
                    refMapList.add(buildRefMap(acc, pendingId, ''));
                }
            }

            // Failed add: retry with whatever BvD ID the Account currently holds
            Boolean syncFailed = acc.Sync_BVD_ID_Messge__c != null
                              && acc.Sync_BVD_ID_Messge__c != SUCCESS_MSG;
            if (syncFailed && String.isNotBlank(acc.BvD_ID_Number__c)) {
                refMapList.add(buildRefMap(acc, '', acc.BvD_ID_Number__c));
            }
        }

        return refMapList;
    }

    private static Map<String, String> buildRefMap(Account acc, String oldBvdId, String newBvdId) {
        Map<String, String> refMap = new Map<String, String>();
        refMap.put('accountId',         acc.Id);
        refMap.put('accountNumber',     acc.AccountNumber);
        refMap.put('creditControlArea', acc.celsrm__Credit_Control_Area__c);
        refMap.put('oldBvdId',          oldBvdId);
        refMap.put('newBvdId',          newBvdId);
        return refMap;
    }
}