public with sharing class UpdateProfileDataInSourceSystemService implements Queueable, Database.AllowsCallouts {

    public List<String> accountIds;
    // Credit Review Ids whose credit limit must be sent to SAP once this profile sync chain finishes.
    // Set by GetMoodysDataFinalizer, which can only enqueue one job and so chains both syncs through here.
    public List<String> nextCreditReviewIds;
    public static Boolean skipProfileDataSync = false;

    private static final Integer CHUNK_SIZE = 50;

    private static final Integer BYPASS_WINDOW_MINUTES = 1;

    public UpdateProfileDataInSourceSystemService(List<String> accountIds) {
        this(accountIds, null);
    }

    public UpdateProfileDataInSourceSystemService(List<String> accountIds, List<String> nextCreditReviewIds) {
        this.accountIds = accountIds;
        this.nextCreditReviewIds = nextCreditReviewIds;
    }

    /**
     * @description Queues a BARE Account (Id + only the bookkeeping fields this service
     * owns) instead of writing back the full Account instance that was queried at the
     * start of execute(). That queried instance also carries celsrm__Risk_Class__c /
     * celsrm__Check_Rule__c / celsrm__Credit_Group__c / etc. as they were when this job
     * started — but the CFin callout above is slow, and the "Risk Class and Check Rule 2"
     * Flow (or another sibling-propagation process) can update those same fields on this
     * very Account WHILE this job is waiting on the callout. If we `update` the full stale
     * instance afterwards, we silently revert whatever the Flow just saved (seen in the
     * logs: Medium/Z04 reverted back to High/Z05) — which re-fires the record-triggered
     * Flow a second time on this same Account and is a direct contributor to the
     * "flow fires twice" / "Too many queueable jobs added to the queue" symptoms, since
     * each stale-write bounce can enqueue further automation.
     *
     * Only Id + the fields this service is actually responsible for are ever put on the
     * update list, so this write can never clobber a field owned by other automation.
     */
    private void stampBypassAndQueue(Account acc, List<Account> accToBeUpdated) {
        Account bare = new Account(
            Id = acc.Id,
            Sync_Profile_Data_Message__c = acc.Sync_Profile_Data_Message__c,
            Skip_Automation_Until__c = System.now().addMinutes(BYPASS_WINDOW_MINUTES)
        );
        if (acc.Sync_Profile_Data_In_Source_System_At__c != null) {
            bare.Sync_Profile_Data_In_Source_System_At__c = acc.Sync_Profile_Data_In_Source_System_At__c;
        }
        accToBeUpdated.add(bare);
    }

    public void execute(QueueableContext context) {

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

            // NOTE: Sync_Profile_Data_Message__c / Skip_Automation_Until__c /
            // Sync_Profile_Data_In_Source_System_At__c are queried here even though this
            // method only ever WRITES them, because stampBypassAndQueue() below reads
            // Sync_Profile_Data_Message__c and Sync_Profile_Data_In_Source_System_At__c
            // back off this same in-memory instance to copy them onto a bare Account. A
            // field that was never queried AND never assigned in this execution throws
            // System.SObjectException on read (not every account goes through the branch
            // that assigns Sync_Profile_Data_In_Source_System_At__c), so querying them
            // up front keeps that read safe for every account, every branch.
            List<Account> accounts = [
                SELECT
                    Id,
                    AccountNumber,
                    Name,
                    celsrm__Credit_Group__c,
                    celsrm__Check_Rule__c,
                    celsrm__Risk_Class__c,
                    Moody_s_Credit_Limit__c,
                    celsrm__Credit_Control_Area__c,
                    Sync_Profile_Data_Message__c,
                    Skip_Automation_Until__c,
                    Sync_Profile_Data_In_Source_System_At__c
                FROM Account
                WHERE Id IN :currentChunk
            ];

            Map<String, List<Account>> accountKeyObjMap = new Map<String, List<Account>>();
            List<Map<String, Object>> accList = new List<Map<String, Object>>();
            Map<String, Object> requestBodyMap = new Map<String, Object>();
            List<Account> accToBeUpdated = new List<Account>();

            String webhookURL =
                Credit_Configuration__c.getOrgDefaults()
                    .Update_Profile_Data_Action_Flow_Webhook__c;

            if (webhookURL != null && webhookURL != '') {

                for (Account acc : accounts) {

                    String checkRule = acc.celsrm__Check_Rule__c;

                    if (checkRule != null && checkRule != '') {
                        List<String> parts = checkRule.split(' ', 2);
                        checkRule = parts[0];
                    } else {
                        checkRule = '';
                    }

                    String riskClass = (String) acc.celsrm__Risk_Class__c;

                    if (riskClass != null) {
                        List<String> parts = riskClass.split(' ', 2);

                        if (parts.size() > 1) {
                            riskClass = parts[0];
                        }
                    }

                    String creditGroup = acc.celsrm__Credit_Group__c;

                    if (creditGroup != null) {
                        List<String> parts = creditGroup.split(' ', 2);

                        if (parts.size() > 1) {
                            creditGroup = parts[0];
                        }
                    }

                    String key =
                        acc.AccountNumber +
                        '-' +
                        checkRule +
                        '-' +
                        creditGroup +
                        '-' +
                        riskClass;

                    if (accountKeyObjMap.containsKey(key)) {

                        List<Account> accountList = accountKeyObjMap.get(key);
                        accountList.add(acc);
                        accountKeyObjMap.put(key, accountList);

                    } else {

                        List<Account> accountList = new List<Account>();
                        accountList.add(acc);
                        accountKeyObjMap.put(key, accountList);

                        Map<String, Object> map1 = new Map<String, Object>();

                        map1.put('creditGroup', creditGroup);
                        map1.put('riskClass', riskClass);
                        map1.put('checkRule', checkRule);
                        map1.put(
                            'creditControlArea',
                            acc.celsrm__Credit_Control_Area__c
                        );
                        map1.put('accountNumber', acc.AccountNumber);

                        accList.add(map1);
                    }
                }

                requestBodyMap.put('updateRequests', accList);

                if (accList.size() > 0) {

                    try {

                        HttpRequest req = new HttpRequest();

                        req.setEndpoint(
                            'callout:CelonisEMS' + '/' + webhookURL
                        );

                        req.setMethod('POST');
                        req.setHeader('Content-Type', 'application/json');

                        String requestBody = JSON.serialize(requestBodyMap);

                        System.debug(requestBody);

                        req.setBody(requestBody);
                        req.setTimeout(120000);

                        Http http = new Http();
                        HttpResponse res = http.send(req);

                        System.debug('CFin webhook response | status=' + res.getStatusCode() + ' body=' + res.getBody());

                        if (res.getStatusCode() == 200) {

                            String responseBody = res.getBody();

                            if (responseBody == null || !responseBody.trim().startsWith('{')) {

                                // Any plain-text response (not a JSON object) — 'Accepted',
                                // 'Queued', or anything else the webhook might return as raw
                                // text. Previously only 'Accepted' was handled this way;
                                // everything else fell through to JSON.deserializeUntyped()
                                // below and threw (e.g. "Unexpected character ('Q' (code 81))"
                                // for a response like 'Queued').
                                String errorMessage =
                                    'Failed to update in CFIN. Error: Unexpected response from webhook: ' +
                                    responseBody;

                                for (Account acc : accounts) {

                                    acc.Sync_Profile_Data_Message__c =
                                        errorMessage;

                                    stampBypassAndQueue(
                                        acc,
                                        accToBeUpdated
                                    );
                                }

                            } else {

                                List<String> accountKeysGotResponse =
                                    new List<String>();

                                Map<String, Object> parsedResponse =
                                    (Map<String, Object>)
                                        JSON.deserializeUntyped(responseBody);

                                Map<String, Object> detailsMap =
                                    (Map<String, Object>)
                                        parsedResponse.get('details');

                                List<Object> updateResponse =
                                    (List<Object>)
                                        detailsMap.get('updateResponse');

                                for (Object obj : updateResponse) {

                                    Map<String, Object> objMap =
                                        (Map<String, Object>) obj;

                                    String accountNumber =
                                        (String) objMap.get('PARTNER');

                                    String checkRule =
                                        (String) objMap.get('CHECK_RULE');

                                    String creditGroup =
                                        (String) objMap.get('CREDIT_GROUP');

                                    String riskClass =
                                        (String) objMap.get('RISK_CLASS');

                                    String statusMsg =
                                        (String) objMap.get('STATUS_MSG');

                                    String key =
                                        accountNumber +
                                        '-' +
                                        checkRule +
                                        '-' +
                                        creditGroup +
                                        '-' +
                                        riskClass;

                                    if (accountKeyObjMap.containsKey(key)) {

                                        accountKeysGotResponse.add(key);

                                        List<Account> accountList =
                                            accountKeyObjMap.get(key);

                                        for (Account account : accountList) {

                                            if (statusMsg == 'Update successful') {

                                                account.Sync_Profile_Data_In_Source_System_At__c =
                                                    DateTime.now();

                                                account.Sync_Profile_Data_Message__c =
                                                    statusMsg;

                                            } else {

                                                account.Sync_Profile_Data_Message__c =
                                                    statusMsg;
                                            }

                                            stampBypassAndQueue(
                                                account,
                                                accToBeUpdated
                                            );
                                        }
                                    }
                                }

                                for (String accountKey : accountKeyObjMap.keySet()) {

                                    if (!accountKeysGotResponse.contains(accountKey)) {

                                        List<Account> accountList =
                                            accountKeyObjMap.get(accountKey);

                                        for (Account account : accountList) {

                                            account.Sync_Profile_Data_Message__c =
                                                'Failed to update in CFIN. Error: RFC Module Failed';

                                            stampBypassAndQueue(
                                                account,
                                                accToBeUpdated
                                            );
                                        }
                                    }
                                }
                            }

                        } else if (
                            res.getStatusCode() == 401 ||
                            res.getStatusCode() == 501 ||
                            res.getStatusCode() == 400
                        ) {

                            String responseBody = res.getBody();

                            String errorMessage;
                            if (responseBody != null && responseBody.trim().startsWith('{')) {
                                Map<String, Object> parsedResponse =
                                    (Map<String, Object>)
                                        JSON.deserializeUntyped(responseBody);

                                errorMessage =
                                    'Failed to update in CFIN. Error: ' +
                                    (String) parsedResponse.get('details');
                            } else {
                                // Same non-JSON-response gotcha as the 200 branch above —
                                // don't assume the error body is JSON either.
                                errorMessage =
                                    'Failed to update in CFIN. Error: ' + responseBody;
                            }

                            for (Account acc : accounts) {

                                acc.Sync_Profile_Data_Message__c =
                                    errorMessage;

                                stampBypassAndQueue(
                                    acc,
                                    accToBeUpdated
                                );
                            }

                        } else if (res.getStatusCode() == 500) {

                            String errorMessage =
                                'Failed to update in CFIN. Error: Internal Server Error';

                            for (Account acc : accounts) {

                                acc.Sync_Profile_Data_Message__c =
                                    errorMessage;

                                stampBypassAndQueue(
                                    acc,
                                    accToBeUpdated
                                );
                            }

                        } else if (res.getStatusCode() == 429) {

                            String errorMessage =
                                'Failed to update in CFIN. Error: Webhook rate limit';

                            for (Account acc : accounts) {

                                acc.Sync_Profile_Data_Message__c =
                                    errorMessage;

                                stampBypassAndQueue(
                                    acc,
                                    accToBeUpdated
                                );
                            }

                        } else {

                            String errorMessage =
                                'Failed to update in CFIN. Error: ' +
                                String.valueOf(res.getStatusCode());

                            for (Account acc : accounts) {

                                acc.Sync_Profile_Data_Message__c =
                                    errorMessage;

                                stampBypassAndQueue(
                                    acc,
                                    accToBeUpdated
                                );
                            }
                        }

                    } catch (Exception e) {

                        System.debug(
                            'After Response timestamp: ' +
                            System.now()
                        );

                        String errorMessage =
                            'Failed to update in CFIN. Exception occured: ' +
                            e.getMessage();

                        for (Account acc : accounts) {

                            acc.Sync_Profile_Data_Message__c =
                                errorMessage;

                            stampBypassAndQueue(
                                acc,
                                accToBeUpdated
                            );
                        }
                    }
                }

                if (accToBeUpdated.size() > 0) {
                    // This update only ever touches the bookkeeping fields this service
                    // owns (see stampBypassAndQueue above) — never celsrm__Risk_Class__c /
                    // celsrm__Check_Rule__c. But ANY update on a 'Credit' Account still
                    // fires AccountMasterTrigger's AfterUpdate logic in full, including its
                    // own profile-data-changed detection, which can call back into
                    // UpdateProfileDataInSourceSystemService.updateProfileDataInSAP() and
                    // enqueue a SECOND Queueable job inside this same transaction — which
                    // is already running as a Queueable, so Salesforce only allows 1 more
                    // job to be queued from here. That reentrant second enqueueJob is what
                    // throws "Too many queueable jobs added to the queue: 2" (seen in the
                    // logs right after a CFin sync attempt) and, more importantly, lets
                    // AccountMasterTrigger's downstream automation (the "Risk Class and
                    // Check Rule 2" Flow among it) run a second, redundant time off of this
                    // purely-bookkeeping update. skipProfileDataSync is exactly the guard
                    // GetMoodysDataService already uses around its own `update accToUpdate`
                    // for this same reason — this update needs the same guard.
                    Boolean previousSkipProfileDataSync = skipProfileDataSync;
                    skipProfileDataSync = true;
                    try {
                        update accToBeUpdated;
                    } finally {
                        skipProfileDataSync = previousSkipProfileDataSync;
                    }
                }
            }

        } catch (Exception e) {

            System.debug(
                'Exception: ' +
                e.getMessage()
            );
        }

        // Only ONE job can be enqueued from a Queueable: either the next profile chunk
        // (which keeps carrying nextCreditReviewIds forward), or, once the last chunk is
        // done, the pending SAP credit limit update handed over by GetMoodysDataFinalizer.
        if (!Test.isRunningTest()) {

            if (remainingIds.size() > 0) {

                System.enqueueJob(
                    new UpdateProfileDataInSourceSystemService(
                        remainingIds,
                        nextCreditReviewIds
                    )
                );

            } else if (nextCreditReviewIds != null && !nextCreditReviewIds.isEmpty()) {

                UpdateLimitInSourceSystemService.updateCreditLimitInSAP(nextCreditReviewIds);
            }
        }
    }

    public static void updateProfileDataInSAP(List<String> accountIds) {
        System.enqueueJob(
            new UpdateProfileDataInSourceSystemService(accountIds)
        );
    }
}