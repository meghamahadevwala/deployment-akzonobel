/**
 * Batch job that deletes celsrm__Transaction__c records where
 * celsrm__Close_Date__c is older than 400 days.
 * Scheduled: every Sunday at 1:30 AM CET (00:30 UTC).
 *
 * Schedule CRON: '0 30 0 ? * SUN'
 */
public class DeleteOldTransactionsBatch
        implements Database.Batchable<SObject>, Schedulable {

    private static final Integer DAYS_THRESHOLD = 100;

    // ── Schedulable ──────────────────────────────────────────────────────────

    public void execute(SchedulableContext sc) {
        Database.executeBatch(new DeleteOldTransactionsBatch(), 200);
    }

    // ── Batchable ─────────────────────────────────────────────────────────────

    public Database.QueryLocator start(Database.BatchableContext bc) {
        Date cutoffDate = Date.today().addDays(-DAYS_THRESHOLD);
        return Database.getQueryLocator([
            SELECT Id
            FROM celsrm__Transaction__c
            WHERE celsrm__Close_Date__c < :cutoffDate
            AND celsrm__Close_Date__c != null
        ]);
    }

    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        List<Database.DeleteResult> results =
            Database.delete(scope, false); // allOrNothing = false

        for (Database.DeleteResult dr : results) {
            if (!dr.isSuccess()) {
                for (Database.Error err : dr.getErrors()) {
                    System.debug(LoggingLevel.ERROR,
                        'DeleteOldTransactionsBatch error on Id ' + dr.getId()
                        + ' → ' + err.getStatusCode() + ': ' + err.getMessage());
                }
            }
        }
    }

    public void finish(Database.BatchableContext bc) {
        System.debug(LoggingLevel.INFO,
            'DeleteOldTransactionsBatch finished. Job Id: ' + bc.getJobId());
    }
}