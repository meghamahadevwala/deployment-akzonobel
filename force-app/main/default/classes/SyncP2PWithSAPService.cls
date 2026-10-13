/**
 * @class      SyncP2PWithSAPService
 * @implements Queueable, Database.AllowsCallouts
 *
 * @description
 * Queueable service responsible for synchronizing Promise to Pay (P2P) records
 * from Salesforce to SAP via a Celonis EMS webhook. Handles three action types —
 * CREATE, UPDATE, and DELETE — batching Transaction records into HTTP payloads
 * of up to 50 items per request.
 *
 * ARCHITECTURE OVERVIEW:
 * This service sits at the integration layer between two trigger entry points:
 *
 *   TransactionP2PHandlerTrigger  (after update on celsrm__Transaction__c)
 *       └─→ syncP2P(..., 'UPDATE')   guarded by allowExternalUpdate = true
 *
 *   P2PSyncTriggerCE  (after insert/delete on celsrm__Celonis_Event__c)
 *       └─→ syncP2P(..., 'CREATE')
 *       └─→ syncP2P(..., 'DELETE')
 *
 * Both triggers converge here. The service accumulates IDs from all callers
 * within the same transaction via static sets (pendingCreateIds, pendingUpdateIds,
 * pendingDeleteIds) and enqueues a single job — preventing duplicate queueable
 * submissions within the same execution context.
 *
 * GUARD FLAG — allowExternalUpdate:
 * UPDATE callouts are restricted by design. The managed package (HighRadius celsrm)
 * fires its own DML on Transaction records during internal processing, which would
 * otherwise trigger unintended UPDATE syncs to SAP. The static flag
 * allowExternalUpdate must be explicitly set to true by the caller before invoking
 * syncP2P with actionType 'UPDATE', and reset to false immediately after.
 * Any UPDATE call arriving while the flag is false is silently dropped.
 * Only TransactionP2PHandlerTrigger is authorized to set this flag.
 *
 * PAYLOAD CONSTRUCTION:
 * The SailfinCaseID is a composite key built from CompanyCode + DocumentNumber +
 * FiscalYear + InvoiceLineNo, matching SAP's document identification convention.
 * The UpdateP2P flag is set to 'X' (SAP boolean convention) only for status
 * events 20 and 30. For status 30 (broken promise), the PromisedOn date is
 * overridden to today to reflect the breach date rather than the original
 * commitment date.
 *
 * @see TransactionP2PHandlerTrigger
 * @see P2PSyncTriggerCE
 */
public with sharing class SyncP2PWithSAPService implements Queueable, Database.AllowsCallouts {

    /**
     * Accumulator sets that collect IDs across all syncP2P calls within a single
     * Apex transaction. Cleared implicitly when the queueable job is enqueued,
     * since the job captures a snapshot of the sets at enqueue time.
     * Exposed as @TestVisible to allow assertion in unit tests without
     * calling the full queueable execution path.
     */
    @TestVisible private static Set<Id> pendingCreateIds = new Set<Id>();
    @TestVisible private static Set<Id> pendingUpdateIds = new Set<Id>();
    @TestVisible private static Set<Id> pendingDeleteIds = new Set<Id>();

    /**
     * Guard flag that restricts UPDATE syncs to authorized callers only.
     * Must be set to true immediately before calling syncP2P with 'UPDATE'
     * and reset to false immediately after. Any UPDATE arriving while this
     * flag is false will be silently ignored.
     *
     * @see TransactionP2PHandlerTrigger
     */
    public static Boolean allowExternalUpdate = false;

    /**
     * Deduplication flag that ensures only one queueable job is enqueued
     * per Apex transaction, regardless of how many times syncP2P is called.
     */
    private static Boolean isEnqueued = false;

    private List<Id> createIds;
    private List<Id> updateIds;
    private List<Id> deleteIds;

    /**
     * @description Constructs the service with the three ID lists to process.
     * Instantiated internally by syncP2P; should not be called directly.
     *
     * @param createIds  Transaction IDs for which a CREATE payload will be sent.
     * @param updateIds  Transaction IDs for which an UPDATE payload will be sent.
     * @param deleteIds  Transaction IDs for which a DELETE payload will be sent.
     */
    public SyncP2PWithSAPService(List<Id> createIds, List<Id> updateIds, List<Id> deleteIds) {
        this.createIds = createIds;
        this.updateIds = updateIds;
        this.deleteIds = deleteIds;
    }

    /**
     * @description Queueable entry point. Processes CREATE, UPDATE, and DELETE
     * batches in sequence and resets the enqueue guard on completion.
     *
     * @param context  Queueable execution context provided by the platform.
     */
    public void execute(QueueableContext context) {
        processTransactions(createIds, 'CREATE');
        processTransactions(updateIds, 'UPDATE');
        processTransactions(deleteIds, 'DELETE');
        isEnqueued = false;
    }

    /**
     * @description Queries the full Transaction data for the given IDs, builds
     * the P2P payload maps, and delegates to sendBatches for HTTP dispatch.
     *
     * PAYLOAD NOTES:
     * - SailfinCaseID is a composite SAP document key:
     *   CompanyCode_DocumentNumber_FiscalYear_InvoiceLineNo
     * - UpdateP2P is set to 'X' (SAP boolean) only for Status_Event__c 20 or 30.
     * - For Status_Event__c == '30' (broken promise), PromisedOn is overridden
     *   to today's date to record the breach date, not the original promise date.
     *
     * @param ids         List of Transaction IDs to process.
     * @param actionType  One of: 'CREATE', 'UPDATE', 'DELETE'.
     */
    private void processTransactions(List<Id> ids, String actionType) {
        if (ids == null || ids.isEmpty()) return;

        List<celsrm__Transaction__c> transactions = [
            SELECT Id,
                   Name,
                   celsrm__Fiscal_Year__c,
                   celsrm__Invoice_Line_No__c,
                   celsrm__Account__r.AccountNumber,
                   celsrm__Company_Code__c,
                   celsrm__Promise_Date__c,
                   celsrm__Promised_Amount__c,
                   Status_Event__c,
                   celsrm__Due_Date__c
            FROM celsrm__Transaction__c
            WHERE Id IN :ids
            AND celsrm__Account__r.celsrm__Account_Key__c LIKE 'CFIN%'
        ];

        if (transactions.isEmpty()) return;

        List<Map<String, Object>> payload = new List<Map<String, Object>>();

        for (celsrm__Transaction__c t : transactions) {

            String sailfinCaseId =
                t.celsrm__Company_Code__c + '_' +
                t.Name + '_' +
                t.celsrm__Fiscal_Year__c + '_' +
                t.celsrm__Invoice_Line_No__c;

            String updateP2P = '';
            if (t.Status_Event__c == '20' || t.Status_Event__c == '30') {
                updateP2P = 'X';
            }

            Date promisedDate = t.celsrm__Promise_Date__c;
            if (t.Status_Event__c == '30') {
                promisedDate = Date.today();
            }

            Map<String, Object> p2pData = new Map<String, Object>();
            p2pData.put('SailfinCaseID',    sailfinCaseId);
            p2pData.put('CustomerNumber',   t.celsrm__Account__r != null ? t.celsrm__Account__r.AccountNumber : null);
            p2pData.put('CompanyCode',      t.celsrm__Company_Code__c);
            p2pData.put('DocumentNumber',   t.Name);
            p2pData.put('PromisedOn',       promisedDate);
            p2pData.put('PromisedFor',      t.celsrm__Promised_Amount__c);
            p2pData.put('Status',           t.Status_Event__c);
            p2pData.put('UpdateP2P',        updateP2P);
            p2pData.put('DueDate',          t.celsrm__Due_Date__c);
            p2pData.put('Notes',            '');

            payload.add(p2pData);
        }

        sendBatches(payload, actionType);
    }

    /**
     * @description Splits the payload into batches of up to 50 items and sends
     * each batch as a POST request to the Celonis EMS webhook endpoint.
     *
     * The webhook URL is read from the org-default Collection_Configuration__c
     * custom setting. The named credential 'CelonisEMS' handles authentication.
     * Each request carries the full batch under the key 'p2pArray' along with
     * the actionType, allowing the receiving Celonis Action Flow to route
     * processing accordingly.
     *
     * Failures are logged via System.debug and do not throw, to avoid rolling
     * back the parent transaction due to a non-critical integration error.
     *
     * @param payload     List of P2P data maps to send.
     * @param actionType  One of: 'CREATE', 'UPDATE', 'DELETE'. Forwarded as-is
     *                    to the Celonis endpoint.
     */
    private void sendBatches(List<Map<String, Object>> payload, String actionType) {
        if (payload == null || payload.isEmpty()) return;

        Integer batchSize = 50;
        String webhookURL = Collection_Configuration__c.getOrgDefaults().P2P_Sync_Webhook__c;
        Http http = new Http();

        for (Integer i = 0; i < payload.size(); i += batchSize) {

            List<Map<String, Object>> batch = new List<Map<String, Object>>();
            for (Integer j = i; j < i + batchSize && j < payload.size(); j++) {
                batch.add(payload[j]);
            }

            Map<String, Object> body = new Map<String, Object>{
                'p2pArray'   => batch,
                'actionType' => actionType
            };

            HttpRequest req = new HttpRequest();
            req.setEndpoint('callout:CelonisEMS/' + webhookURL);
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setHeader('$Credentials.EMS.AppKey', 'AppKey');
            req.setTimeout(20000);
            req.setBody(JSON.serialize(body));

            try {
                HttpResponse res = http.send(req);
                System.debug('P2P Sync response status: ' + res.getStatusCode());
                System.debug('P2P Sync response body: '   + res.getBody());
            } catch (Exception e) {
                System.debug('P2P Sync error: ' + e.getMessage());
            }
        }
    }

    /**
     * @description Public entry point for all callers. Accumulates IDs into the
     * appropriate pending set and enqueues a single job per Apex transaction.
     *
     * GUARD — UPDATE restriction:
     * UPDATE syncs are only processed when allowExternalUpdate is true at the
     * moment of the call. This prevents the HighRadius managed package (which
     * performs its own DML on Transaction records) from inadvertently triggering
     * SAP updates. The flag must be set and cleared by the caller in the same
     * synchronous block.
     *
     * DEDUPLICATION:
     * isEnqueued ensures at most one queueable job is submitted per transaction,
     * even if syncP2P is called multiple times (e.g. from both triggers firing
     * in the same execution context). All IDs collected before the enqueue call
     * are snapshotted into the job constructor.
     *
     * @param ids         Transaction IDs to sync. Nulls are removed silently.
     * @param actionType  One of: 'CREATE', 'UPDATE', 'DELETE'.
     */
    public static void syncP2P(List<Id> ids, String actionType) {
        if (ids == null || ids.isEmpty()) return;

        if (actionType == 'UPDATE' && !allowExternalUpdate) return;

        Set<Id> cleanIds = new Set<Id>(ids);
        cleanIds.remove(null);
        if (cleanIds.isEmpty()) return;

        if (actionType == 'CREATE') {
            pendingCreateIds.addAll(cleanIds);
        } else if (actionType == 'UPDATE') {
            pendingUpdateIds.addAll(cleanIds);
        } else if (actionType == 'DELETE') {
            pendingDeleteIds.addAll(cleanIds);
        }

        if (!isEnqueued) {
            isEnqueued = true;
            System.enqueueJob(
                new SyncP2PWithSAPService(
                    new List<Id>(pendingCreateIds),
                    new List<Id>(pendingUpdateIds),
                    new List<Id>(pendingDeleteIds)
                )
            );
        }
    }
}