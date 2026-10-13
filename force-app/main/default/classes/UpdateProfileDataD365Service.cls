/**
* D365 write-back for Account profile data. Standalone Queueable, same pattern as
* UpdateProfileDataInSourceSystemService (CFIN), but a direct HTTP call per Account.
*
* ROUTING IS NOT DONE HERE. The caller (routing class) must only pass Account Ids whose
* source system is D365:
*     UpdateProfileDataD365Service.updateProfileDataInD365(d365AccountIds);
*
* Fixed (no Credit_Configuration__c fields needed):
*   - Named Credential : D365_Writeback  (carries URL + auth)
*   - Payload          : {"_request": {...8 fields...}}, built in buildRequest() below
*
* Result fields on Account:
*   - Sync_Customer_Details_in_D365__c    : "Message" from the D365 response (or error text)
*   - Sync_Customer_Details_in_D365_at__c : time of successful sync
*
* Defaults:
*   - Credit limit blank      -> 0
*   - Limit valid-to blank    -> 2099-12-31 00:00:00.000
*/
public with sharing class UpdateProfileDataD365Service implements Queueable, Database.AllowsCallouts {
 
    public List<String> accountIds;
    // Same hand-over as the CFIN class. Only pass this to ONE of the two services, otherwise
    // the SAP credit limit update would run twice.
    public List<String> nextCreditReviewIds;
 
    private static final Integer CHUNK_SIZE = 50;
    private static final Integer BYPASS_WINDOW_MINUTES = 1;
    private static final String ENDPOINT = 'callout:D365_Writeback_Customer';
 
    // Salesforce allows max 120s of TOTAL callout time per transaction.
    private static final Integer CALLOUT_BUDGET_MS = 110000;
    private static final Integer CALL_TIMEOUT_MS = 20000;
 
    // Defaults for blank values, so D365 can deserialize the contract.
    private static final Decimal DEFAULT_CREDIT_LIMIT = 0;
    private static final String DEFAULT_D365_DATE = '2099-12-31 00:00:00.000';
 
    public UpdateProfileDataD365Service(List<String> accountIds) {
        this(accountIds, null);
    }
 
    public UpdateProfileDataD365Service(List<String> accountIds, List<String> nextCreditReviewIds) {
        this.accountIds = accountIds;
        this.nextCreditReviewIds = nextCreditReviewIds;
    }
 
    public static void updateProfileDataInD365(List<String> accountIds) {
        System.enqueueJob(new UpdateProfileDataD365Service(accountIds));
    }
 
    public void execute(QueueableContext context) {
 
        Long startedAt = System.currentTimeMillis();
 
        List<String> currentChunk = new List<String>();
        List<String> remainingIds = new List<String>();
 
        for (Integer i = 0; i < accountIds.size(); i++) {
            if (i < CHUNK_SIZE) {
                currentChunk.add(accountIds[i]);
            } else {
                remainingIds.add(accountIds[i]);
            }
        }
 
        try {
 
            List<Account> accounts = [
                SELECT
                    Id,
                    AccountNumber,
                    celsrm__Credit_Control_Area__c,
                    celsrm__Risk_Class__c,
                    celsrm__Check_Rule__c,
                    celsrm__Credit_Group__c,
                    celsrm__Credit_Limit__c,
                    celsrm__Limit_Valid_To_Date__c,
                    BvD_ID_Number__c
                FROM Account
                WHERE Id IN :currentChunk
            ];
 
            List<Account> accToBeUpdated = new List<Account>();
 
            for (Account acc : accounts) {
 
                Long remainingMs = CALLOUT_BUDGET_MS - (System.currentTimeMillis() - startedAt);
 
                if (remainingMs < 1000) {
                    // Out of callout time for this job: push this Account to the next job
                    // instead of failing it.
                    remainingIds.add(String.valueOf(acc.Id));
                    continue;
                }
 
                String msg;
                Boolean ok = false;
 
                try {
 
                    HttpRequest req = new HttpRequest();
                    req.setEndpoint(ENDPOINT);
                    req.setMethod('POST');
                    req.setHeader('Content-Type', 'application/json');
                    req.setHeader('Accept', 'application/json');
                    req.setBody(JSON.serialize(buildRequest(acc)));
                    req.setTimeout(Math.min(CALL_TIMEOUT_MS, remainingMs.intValue()));
 
                    System.debug('D365 REQUEST | account=' + acc.AccountNumber + ' body=' + req.getBody());
 
                    HttpResponse res = new Http().send(req);
 
                    System.debug('D365 HTTP response | account=' + acc.AccountNumber + ' status=' + res.getStatusCode() + ' body=' + res.getBody());
 
                    // D365 returns {"$id":"1","Success":false,"Message":"..."}, often with HTTP 200,
                    // so success is decided by the "Success" flag, not only the status code.
                    Map<String, Object> parsed = parseBody(res.getBody());
                    String d365Message = (parsed != null && parsed.get('Message') != null)
                        ? String.valueOf(parsed.get('Message'))
                        : null;
 
                    Boolean httpOk = res.getStatusCode() >= 200 && res.getStatusCode() < 300;
                    Boolean d365Ok = parsed == null || parsed.get('Success') == null || parsed.get('Success') == true;
 
                    ok = httpOk && d365Ok;
 
                    if (String.isNotBlank(d365Message)) {
                        msg = d365Message;
                    } else if (ok) {
                        msg = 'D365 Update Successful';
                    } else {
                        msg = 'D365 Update Failed: ' + res.getBody();
                    }
 
                } catch (Exception ex) {
                    msg = 'D365 Exception: ' + ex.getMessage();
                }
 
                if (String.isBlank(msg)) {
                    msg = ok ? 'D365 Update Successful' : 'D365 Update Failed';
                }
 
                // Bare Account: only the bookkeeping fields this service owns (same idea as the
                // CFIN class), so we never overwrite fields other automation changed meanwhile.
                Account bare = new Account(
                    Id = acc.Id,
                    // Keep within the message field length so one long error can't fail the whole DML.
                    Sync_Customer_Details_in_D365__c = msg.abbreviate(255),
                    Skip_Automation_Until__c = System.now().addMinutes(BYPASS_WINDOW_MINUTES)
                );
                if (ok) {
                    bare.Sync_Customer_Details_in_D365_at__c = System.now();
                }
                accToBeUpdated.add(bare);
            }
 
            if (accToBeUpdated.size() > 0) {
                // Same guard as the CFIN class: stops AccountMasterTrigger from enqueueing a
                // second Queueable from inside this Queueable. DML only after all callouts.
                Boolean previousSkip = UpdateProfileDataInSourceSystemService.skipProfileDataSync;
                UpdateProfileDataInSourceSystemService.skipProfileDataSync = true;
                try {
                    update accToBeUpdated;
                } finally {
                    UpdateProfileDataInSourceSystemService.skipProfileDataSync = previousSkip;
                }
            }
 
        } catch (Exception e) {
            System.debug('Exception: ' + e.getMessage());
        }
 
        // Only ONE job can be enqueued from a Queueable: the next chunk, or (after the last
        // chunk) the pending SAP credit limit update.
        if (!Test.isRunningTest()) {
 
            if (remainingIds.size() > 0) {
                System.enqueueJob(new UpdateProfileDataD365Service(remainingIds, nextCreditReviewIds));
 
            } else if (nextCreditReviewIds != null && !nextCreditReviewIds.isEmpty()) {
                UpdateLimitInSourceSystemService.updateCreditLimitInSAP(nextCreditReviewIds);
            }
        }
    }
 
    // Returns the D365 JSON body as a map, or null if it is empty / not a JSON object.
    private static Map<String, Object> parseBody(String body) {
        if (String.isBlank(body)) {
            return null;
        }
        try {
            Object o = JSON.deserializeUntyped(body);
            return (o instanceof Map<String, Object>) ? (Map<String, Object>) o : null;
        } catch (Exception e) {
            return null;
        }
    }
 
    // The payload. Edit the field mapping here if D365 or the Account fields change.
    // Blank text fields are left out (D365 contract can fail on nulls).
    private static Map<String, Object> buildRequest(Account acc) {
        Map<String, Object> r = new Map<String, Object>();
        putIfNotNull(r, 'CustAccount',                  acc.AccountNumber);
        putIfNotNull(r, 'DataAreaId',                   acc.celsrm__Credit_Control_Area__c);
        putIfNotNull(r, 'AnkCustSegmentationId',        firstToken(acc.celsrm__Risk_Class__c));
        putIfNotNull(r, 'AnkRiskCategoryId',            firstToken(acc.celsrm__Check_Rule__c));
        putIfNotNull(r, 'CredManGroupId',               firstToken(acc.celsrm__Credit_Group__c));
        putIfNotNull(r, 'CustCreditMaxMST',             asCreditLimit(acc.celsrm__Credit_Limit__c));
        putIfNotNull(r, 'CredManCreditLimitExpiryDate', asD365Date(acc.celsrm__Limit_Valid_To_Date__c));
        putIfNotNull(r, 'AnkBVDnr',                     acc.BvD_ID_Number__c);
        return new Map<String, Object>{ '_request' => r };
    }
 
    private static void putIfNotNull(Map<String, Object> m, String key, Object value) {
        if (value != null && !(value instanceof String && String.isBlank((String) value))) {
            m.put(key, value);
        }
    }
 
    // Same as CFIN: Risk Class / Check Rule / Credit Group are sent as the first word (the code).
    private static String firstToken(String v) {
        return String.isBlank(v) ? null : v.trim().split(' ', 2)[0];
    }
 
    // Credit limit sent as a number. Blank -> 0.
    private static Decimal asCreditLimit(Decimal v) {
        return v == null ? DEFAULT_CREDIT_LIMIT : v;
    }
 
    // D365 expects e.g. '2026-10-31 00:00:00.000'. Works for Date or DateTime fields.
    // Blank -> 2099-12-31 00:00:00.000.
    private static String asD365Date(Object v) {
        if (v == null) {
            return DEFAULT_D365_DATE;
        }
        Datetime dt = (v instanceof Date)
            ? Datetime.newInstance((Date) v, Time.newInstance(0, 0, 0, 0))
            : (Datetime) v;
        return dt.format('yyyy-MM-dd HH:mm:ss.SSS');
    }
}