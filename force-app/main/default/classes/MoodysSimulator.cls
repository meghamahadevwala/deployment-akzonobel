/**
 * @description Simulates what a Moody's callout response would produce — no HTTP callout,
 * no mocking needed — by writing directly to Moody_s_Risk_Class__c / Moody_s_Credit_Limit__c
 * on a REAL, already-existing Account, then running the exact same propagation the production
 * classes use. Meant to be run from Execute Anonymous in a sandbox against an account that
 * already has real sibling Credit Segments (same AccountNumber, celsrm__App_Name__c = 'Credit'),
 * so you can watch AccountMasterTrigger + the "Risk Class and Check Rule" Flows fire for real
 * and inspect the result via Debug Logs.
 *
 * WARNING: this is NOT a test context — Test.isRunningTest() is false when run from Execute
 * Anonymous — so any SAP/CFin callout guarded by !Test.isRunningTest() in the code this
 * touches (UpdateProfileDataInSourceSystemService, UpdateBvdIdInSourceSystemService,
 * GetMoodysDataService.updateProfileData/Celonis) WILL fire for real. Only run this against a
 * sandbox where those Named Credentials point somewhere safe, not production endpoints.
 *
 * Usage (Execute Anonymous):
 *   MoodysSimulator.simulateMoodysUpdate('001XXXXXXXXXXXXXXX', 3); // 3 = High
 */
public class MoodysSimulator {

    // 1 = Low, 2 = Medium, 3 = High, 4 = Direct Block. 'Full Credit Block' is intentionally
    // left out — it's assigned manually elsewhere (e.g. INAC), never derived from Moody's.
    private static final Map<Integer, String> NUMBER_TO_RISK_CLASS = new Map<Integer, String>{
        1 => 'Low',
        2 => 'Medium',
        3 => 'High',
        4 => 'Direct Block'
    };

    public static void simulateMoodysUpdate(Id accountId, Integer riskClassNumber) {
        if (!NUMBER_TO_RISK_CLASS.containsKey(riskClassNumber)) {
            throw new IllegalArgumentException(
                'riskClassNumber must be 1 (Low), 2 (Medium), 3 (High), or 4 (Direct Block). Got: ' + riskClassNumber
            );
        }
        String simulatedRiskClass = NUMBER_TO_RISK_CLASS.get(riskClassNumber);

        Account acc = [
            SELECT Id, AccountNumber, BvD_ID_Number__c, Moody_s_Risk_Class__c, Moody_s_Credit_Limit__c,
                   celsrm__Risk_Class__c, celsrm__Check_Rule__c, celsrm__Credit_Group__c,
                   celsrm__App_Name__c
            FROM Account
            WHERE Id = :accountId
        ];

        System.debug('LOGTRACE >>> MoodysSimulator: BEFORE | Id=' + acc.Id + ' AccountNumber=' + acc.AccountNumber
            + ' Moody_s_Risk_Class__c=' + acc.Moody_s_Risk_Class__c
            + ' celsrm__Risk_Class__c=' + acc.celsrm__Risk_Class__c
            + ' celsrm__Check_Rule__c=' + acc.celsrm__Check_Rule__c);

        // Simulated Moody's response — this is the part a real callout would normally fill in.
        acc.Moody_s_Risk_Class__c = simulatedRiskClass;
        acc.Moody_s_Credit_Limit__c = 10000 * riskClassNumber; // arbitrary but deterministic

        // Same call production code makes: recompute source RC/CR + propagate raw Moody's
        // data to eligible siblings (their own RC/CR is computed reactively by the Flow once
        // the update below saves them).
        SiblingCreditDataPropagationService.PropagationResult propagation =
            SiblingCreditDataPropagationService.propagate(new List<Account>{ acc });

        update propagation.accountsToUpdate;

        System.debug('LOGTRACE >>> MoodysSimulator: AFTER (source) | celsrm__Risk_Class__c=' + acc.celsrm__Risk_Class__c
            + ' celsrm__Check_Rule__c=' + acc.celsrm__Check_Rule__c);
        System.debug('LOGTRACE >>> MoodysSimulator: ' + propagation.accountsToUpdate.size()
            + ' account(s) saved in one update (source + eligible siblings). Re-query siblings '
            + 'by AccountNumber=' + acc.AccountNumber + ' to see what the Flow computed for each.');
    }
}