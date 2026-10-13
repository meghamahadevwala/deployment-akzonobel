public with sharing class UpdateBvdIdInSourceSystemService implements Queueable, Database.AllowsCallouts{
    // public List<String> accountIds;
    public List<Map<String, String>> refMapList;
    // << START - MM - FIN-10426 - Remove retry logic, add serial chaining >>
    /**
    public Integer retryCount;
    public UpdateBvdIdInSourceSystemService(List<Map<String, String>> refMapList, Integer retryCount) {
        // this.accountIds = accountIds;
        this.refMapList = refMapList;
        this.retryCount = retryCount;
    }

    public UpdateBvdIdInSourceSystemService(List<Map<String, String>> refMapList) {
        this(refMapList, 0);
    }
    */
    private static final Integer CHUNK_SIZE = 25;

    public UpdateBvdIdInSourceSystemService(List<Map<String, String>> refMapList) {
        this.refMapList = refMapList;
    }
    // << END - MM - FIN-10426 - Remove retry logic, add serial chaining >>


    public void execute(QueueableContext context) {
        // << START - MM - FIN-10426 - Remove retry logic, add serial chaining >>
        // Boolean shouldRetry = false;
        List<Map<String, String>> currentChunk = new List<Map<String, String>>();
        List<Map<String, String>> remainingRefMaps = new List<Map<String, String>>();
        for(Integer i = 0; i < refMapList.size(); i++) {
            if(i < CHUNK_SIZE) {
                currentChunk.add(refMapList[i]);
            } else {
                remainingRefMaps.add(refMapList[i]);
            }
        }
        // << END - MM - FIN-10426 - Remove retry logic, add serial chaining >>
        try {
            Map<String, List<String>> deleteAccountKeyObjMap = new Map<String, List<String>>();
            Map<String, List<String>> addAccountKeyObjMap = new Map<String, List<String>>();
            List<Map<String, Object>> accList = new List<Map<String, Object>>();
            // List<Map<String, Object>> addAccList = new List<Map<String, Object>>();
            // List<Account> accToBeUpdated = new List<Account>();
            // List<String> accToBeUpdatedIds = new List<String>();
            Map<String, Account> accIdVsAccToBeUpdated = new Map<String, Account>();
            String webhookURL = Credit_Configuration__c.getOrgDefaults().Update_Bvd_ID_Action_Flow_Webhook__c;
            Map<String, List<Account>> accountNumberAccountList = new Map<String, List<Account>>();
            Map<String, Map<String, String>> deleteDataMap = new Map<String, Map<String, String>>();
            Set<String> accountIdsMaster = new Set<String>();
            if(webhookURL != null && webhookURL != '') {
                // if(refMapList.size() > 0) {
                if(currentChunk.size() > 0) { // << MM - FIN-10426 - use currentChunk >>
                    // for (Map<String, String> refMap : refMapList) {
                    for (Map<String, String> refMap : currentChunk) { // << MM - FIN-10426 - use currentChunk >>
                        String accountNumber = refMap.get('accountNumber');
                        String accountId = refMap.get('accountId');
                        String creditControlArea = refMap.get('creditControlArea');
                        String oldBvdId = refMap.get('oldBvdId');
                        String newBvdId = refMap.get('newBvdId');
                        if(oldBvdId != null && oldBvdId != '') {
                            Map<String, Object> map1 = new Map<String, Object>();
                            map1.put('accountNumber', accountNumber);
                            map1.put('bvdId', oldBvdId);
                            map1.put('delete', 'X');
                            accList.add(map1);

                            String key = accountNumber + '_' + oldBvdId;
                            if(deleteAccountKeyObjMap.containsKey(key)) {
                                List<String> accountList = deleteAccountKeyObjMap.get(key);
                                accountList.add(accountId);
                                deleteAccountKeyObjMap.put(key, accountList);
                            } else {
                                List<String> accountList = new List<String>();
                                accountList.add(accountId);
                                deleteAccountKeyObjMap.put(key, accountList);
                            }
                        }
                        if(newBvdId != null && newBvdId != '') {
                            Map<String, Object> map1 = new Map<String, Object>();
                            map1.put('accountNumber', accountNumber);
                            map1.put('bvdId', newBvdId);
                            map1.put('delete', '');
                            accList.add(map1);

                            String key = accountNumber + '_' + newBvdId;
                            if(addAccountKeyObjMap.containsKey(key)) {
                                List<String> accountList = addAccountKeyObjMap.get(key);
                                accountList.add(accountId);
                                addAccountKeyObjMap.put(key, accountList);
                            } else {
                                List<String> accountList = new List<String>();
                                accountList.add(accountId);
                                addAccountKeyObjMap.put(key, accountList);
                            }
                        }
                        accountIdsMaster.add(accountId);
                    }
                }
                
                Map<Id, Account> accIdVsAccMaster = new Map<Id, Account>(
                    [SELECT Id, BvD_ID_Number__c, BVD_IDs_To_Be_Removed__c, 
                            Remove_BvD_ID_From_CFIN_At__c, Remove_BvD_ID_From_CFIN_Message__c,
                            Sync_BVD_ID_In_CFIN_At__c, Sync_BVD_ID_Messge__c
                    FROM Account
                    WHERE Id IN :new List<String>(accountIdsMaster)]
                );

                
                if (accList.size() > 0) {
                    try {
                        Map<String, Object> requestBodyMap = new Map<String, Object>();
                        requestBodyMap.put('updateRequests', accList);
                        HttpRequest req = new HttpRequest();
                        req.setEndpoint('callout:CelonisEMS' + '/' + webhookURL);
                        req.setMethod('POST');
                        req.setHeader('Content-Type', 'application/json');
                        String requestBody = JSON.serialize(requestBodyMap);
                        System.debug(requestBody);
                        req.setBody(requestBody);
                        req.setTimeout(120000);
    
                        Http http = new Http();
                        HttpResponse res = http.send(req);
                        /**
                         * 401: {"status":"Error", "details":"Please make sure you have provided correct Authentication token"}
                         * 400: {"status":"Error", "details":"Required field is misisng"}
                         * 200: {"status":"Error","details":{"updateResponse":[{"PARTNER":"1000922611","STATUS_MSG":"Update successful","LV_IDENTIFICATIONNUMBER":"ID0000063046C"}]}}
                         */
    
                        if (res.getStatusCode() == 200) {
                            String responseBody = res.getBody();

                            if(responseBody == 'Accepted') {
                                String errorMessage = 'Failed to update in CFIN. Error: Something went wrong! (Action flow could be deactivated)';
                                for(String key: deleteAccountKeyObjMap.keySet()) {
                                    String bvdId = key.split('_')[1];
                                    List<String> accountIds = deleteAccountKeyObjMap.get(key);
                                    for(String accountId: accountIds) {
                                        if(!accIdVsAccToBeUpdated.keySet().contains(accountId)) {
                                            Account account = accIdVsAccMaster.get(accountId);
                                            account.Remove_BvD_ID_From_CFIN_Message__c = 'Failed to update in CFIN. Error: ' + errorMessage;
                                            appendBvdId(account, bvdId);
                                            // accToBeUpdated.add(account);
                                            // accToBeUpdatedIds.add(accountId);
                                            accIdVsAccToBeUpdated.put(accountId, account);
                                        } else {
                                            Account account = accIdVsAccToBeUpdated.get(accountId);
                                            account.Remove_BvD_ID_From_CFIN_Message__c = 'Failed to update in CFIN. Error: ' + errorMessage;
                                            appendBvdId(account, bvdId);
                                            // accToBeUpdated.add(account);
                                            // accToBeUpdatedIds.add(accountId);
                                            accIdVsAccToBeUpdated.put(accountId, account);
                                        }
                                    }
                                }
                                for(String key: addAccountKeyObjMap.keySet()) {
                                    List<String> accountIds = addAccountKeyObjMap.get(key);
                                    for(String accountId: accountIds) {
                                        if(!accIdVsAccToBeUpdated.keySet().contains(accountId)) {
                                            Account account = accIdVsAccMaster.get(accountId);
                                            account.Sync_BVD_ID_Messge__c = 'Failed to update in CFIN. Error: ' + errorMessage;
                                            // accToBeUpdated.add(account);
                                            // accToBeUpdatedIds.add(accountId);
                                            accIdVsAccToBeUpdated.put(accountId, account);
                                        } else {
                                            Account account = accIdVsAccToBeUpdated.get(accountId);
                                            account.Sync_BVD_ID_Messge__c = 'Failed to update in CFIN. Error: ' + errorMessage;
                                            // accToBeUpdated.add(account);
                                            // accToBeUpdatedIds.add(accountId);
                                            accIdVsAccToBeUpdated.put(accountId, account);
                                        }
                                    }
                                }
                            } else {
                                List<String> accountKeysGotResponse = new List<String>();
                                Map<String, Object> parsedResponse = (Map<String, Object>)JSON.deserializeUntyped(responseBody);
                                Map<String, Object> detailsMap = (Map<String, Object>)parsedResponse.get('details');
                                List<Object> updateResponse = (List<Object>)detailsMap.get('updateResponse');
                                for (Object obj : updateResponse) {
                                    Map<String, Object> objMap = (Map<String, Object>)obj;
                                    String accountNumber = (String)objMap.get('PARTNER');
                                    String statusMsg = (String)objMap.get('STATUS_MSG');
                                    String bvdId = (String)objMap.get('LV_IDENTIFICATIONNUMBER');
                                    String isDelete = (String)objMap.get('DELETE');
                                    // String key = creditSegment + accountNumber;
                                    String key = accountNumber + '_' + bvdId;
                                    if(isDelete == 'X') {
                                        if(deleteAccountKeyObjMap.containsKey(key)) {
                                            accountKeysGotResponse.add(key);
                                            List<String> accountIdList = deleteAccountKeyObjMap.get(key);                                
                                            for(String accountId: accountIdList) {
                                                if(!accIdVsAccToBeUpdated.keySet().contains(accountId)) {
                                                    Account account = accIdVsAccMaster.get(accountId);
                                                    if(statusMsg == 'Update successful'){
                                                        account.Remove_BvD_ID_From_CFIN_At__c = DateTime.now();
                                                        account.Remove_BvD_ID_From_CFIN_Message__c = statusMsg;
                                                        // << START - MM - FIN-10426 - Drop the removed ID so BVD_IDs_To_Be_Removed__c holds only outstanding removals >>
                                                        removeBvdId(account, bvdId);
                                                        // << END - MM - FIN-10426 - Drop the removed ID so BVD_IDs_To_Be_Removed__c holds only outstanding removals >>
                                                    } else{
                                                        appendBvdId(account, bvdId);
                                                        account.Remove_BvD_ID_From_CFIN_Message__c = statusMsg;
                                                    }
                                                    accIdVsAccToBeUpdated.put(accountId, account);
                                                } else {
                                                    Account account = accIdVsAccToBeUpdated.get(accountId);
                                                    if(statusMsg == 'Update successful'){
                                                        account.Remove_BvD_ID_From_CFIN_At__c = DateTime.now();
                                                        account.Remove_BvD_ID_From_CFIN_Message__c = statusMsg;
                                                        // << START - MM - FIN-10426 - Drop the removed ID so BVD_IDs_To_Be_Removed__c holds only outstanding removals >>
                                                        removeBvdId(account, bvdId);
                                                        // << END - MM - FIN-10426 - Drop the removed ID so BVD_IDs_To_Be_Removed__c holds only outstanding removals >>
                                                    } else{
                                                        appendBvdId(account, bvdId);
                                                        account.Remove_BvD_ID_From_CFIN_Message__c = statusMsg;
                                                    }
                                                    accIdVsAccToBeUpdated.put(accountId, account);
                                                }
                                            }
                                        }
                                    } else {
                                        if(addAccountKeyObjMap.containsKey(key)) {
                                            accountKeysGotResponse.add(key);
                                            List<String> accountIdList = addAccountKeyObjMap.get(key);                                
                                            for(String accountId: accountIdList) {
                                                if(!accIdVsAccToBeUpdated.keySet().contains(accountId)) {
                                                    // << START - MM - FIN-10426 - Use DB-loaded Account so appendBvdId appends to BVD_IDs_To_Be_Removed__c instead of overwriting it >>
                                                    // Account account = new Account(Id=accountId);
                                                    Account account = accIdVsAccMaster.get(accountId);
                                                    // << END - MM - FIN-10426 - Use DB-loaded Account so appendBvdId appends to BVD_IDs_To_Be_Removed__c instead of overwriting it >>
                                                    if(statusMsg == 'Update successful'){
                                                        account.Sync_BVD_ID_In_CFIN_At__C = DateTime.now();
                                                        account.Sync_BVD_ID_Messge__c = statusMsg;
                                                    } else{
                                                        account.Sync_BVD_ID_Messge__c = statusMsg;
                                                    }
                                                    accIdVsAccToBeUpdated.put(accountId, account);
                                                } else {
                                                    Account account = accIdVsAccToBeUpdated.get(accountId);
                                                    if(statusMsg == 'Update successful'){
                                                        account.Sync_BVD_ID_In_CFIN_At__C = DateTime.now();
                                                        account.Sync_BVD_ID_Messge__c = statusMsg;
                                                    } else{
                                                        account.Sync_BVD_ID_Messge__c = statusMsg;
                                                    }
                                                    accIdVsAccToBeUpdated.put(accountId, account);
                                                }
                                            }
                                        }
                                    }
                                }
                                for(String accountKey: deleteAccountKeyObjMap.keySet()) {
                                    String bvdId = accountKey.split('_')[1];
                                    if(!accountKeysGotResponse.contains(accountKey)) {
                                        List<String> accountIdList = deleteAccountKeyObjMap.get(accountKey);                                
                                        for(String accountId: accountIdList) {
                                            if(!accIdVsAccToBeUpdated.keySet().contains(accountId)) {
                                                Account account = accIdVsAccMaster.get(accountId);
                                                appendBvdId(account, bvdId);
                                                account.Remove_BvD_ID_From_CFIN_Message__c = 'Failed to update in CFIN. Error: RFC Module Failed';
                                                // accToBeUpdated.add(account);
                                                accIdVsAccToBeUpdated.put(accountId, account);
                                            } else {
                                                Account account = accIdVsAccToBeUpdated.get(accountId);
                                                appendBvdId(account, bvdId);
                                                account.Remove_BvD_ID_From_CFIN_Message__c = 'Failed to update in CFIN. Error: RFC Module Failed';
                                                // accToBeUpdated.add(account);
                                                accIdVsAccToBeUpdated.put(accountId, account);
                                            }
                                        }
                                    }
                                }
                                for(String accountKey: addAccountKeyObjMap.keySet()) {
                                    if(!accountKeysGotResponse.contains(accountKey)) {
                                        List<String> accountIdList = addAccountKeyObjMap.get(accountKey);                                
                                        for(String accountId: accountIdList) {
                                            if(!accIdVsAccToBeUpdated.keySet().contains(accountId)) {
                                                Account account = accIdVsAccMaster.get(accountId);
                                                account.Sync_BVD_ID_Messge__c = 'Failed to update in CFIN. Error: RFC Module Failed';
                                                // accToBeUpdated.add(account);
                                                accIdVsAccToBeUpdated.put(accountId, account);
                                            } else {
                                                Account account = accIdVsAccToBeUpdated.get(accountId);
                                                account.Sync_BVD_ID_Messge__c = 'Failed to update in CFIN. Error: RFC Module Failed';
                                                // accToBeUpdated.add(account);
                                                accIdVsAccToBeUpdated.put(accountId, account);
                                            }
                                        }
                                    }
                                }
                            }
                        } else if(res.getStatusCode() == 401 || res.getStatusCode() == 501 || res.getStatusCode() == 400) {
                            String responseBody = res.getBody();
                            Map<String, Object> parsedResponse = (Map<String, Object>)JSON.deserializeUntyped(responseBody);
                            String errorMessage = 'Failed to update in CFIN. Error: ';
                            if(parsedResponse.get('details') != null) {
                                errorMessage += (String)parsedResponse.get('details');
                            }
                            for(String key: deleteAccountKeyObjMap.keySet()) {
                                String bvdId = key.split('_')[1];
                                List<String> accountIds = deleteAccountKeyObjMap.get(key);
                                for(String accountId: accountIds) {
                                    if(!accIdVsAccToBeUpdated.keySet().contains(accountId)) {
                                        Account account = accIdVsAccMaster.get(accountId);
                                        appendBvdId(account, bvdId);
                                        account.Remove_BvD_ID_From_CFIN_Message__c = errorMessage;
                                        accIdVsAccToBeUpdated.put(accountId, account);

                                    } else {
                                        Account account = accIdVsAccToBeUpdated.get(accountId);
                                        appendBvdId(account, bvdId);
                                        account.Remove_BvD_ID_From_CFIN_Message__c = errorMessage;
                                        accIdVsAccToBeUpdated.put(accountId, account);
                                    }
                                }
                            }
                            for(String key: addAccountKeyObjMap.keySet()) {
                                List<String> accountIds = addAccountKeyObjMap.get(key);
                                for(String accountId: accountIds) {
                                    if(!accIdVsAccToBeUpdated.keySet().contains(accountId)) {
                                        Account account = accIdVsAccMaster.get(accountId);
                                        account.Sync_BVD_ID_Messge__c = errorMessage;
                                        accIdVsAccToBeUpdated.put(accountId, account);

                                    } else {
                                        Account account = accIdVsAccToBeUpdated.get(accountId);
                                        account.Sync_BVD_ID_Messge__c = errorMessage;
                                        accIdVsAccToBeUpdated.put(accountId, account);
                                    }
                                }
                            }
                        } else if(res.getStatusCode() == 500) {
                            String errorMessage = 'Failed to update in CFIN. Error: Internal Server Error';
                            for(String key: deleteAccountKeyObjMap.keySet()) {
                                String bvdId = key.split('_')[1];
                                List<String> accountIds = deleteAccountKeyObjMap.get(key);
                                for(String accountId: accountIds) {
                                    if(!accIdVsAccToBeUpdated.keySet().contains(accountId)) {
                                        Account account = accIdVsAccMaster.get(accountId);
                                        appendBvdId(account, bvdId);
                                        account.Remove_BvD_ID_From_CFIN_Message__c = errorMessage;
                                        accIdVsAccToBeUpdated.put(accountId, account);
                                    } else {
                                        Account account = accIdVsAccToBeUpdated.get(accountId);
                                        appendBvdId(account, bvdId);
                                        account.Remove_BvD_ID_From_CFIN_Message__c = errorMessage;
                                        accIdVsAccToBeUpdated.put(accountId, account);
                                    }
                                }
                            }
                            for(String key: addAccountKeyObjMap.keySet()) {
                                List<String> accountIds = addAccountKeyObjMap.get(key);
                                for(String accountId: accountIds) {
                                    if(!accIdVsAccToBeUpdated.keySet().contains(accountId)) {
                                        Account account = accIdVsAccMaster.get(accountId);
                                        account.Sync_BVD_ID_Messge__c = errorMessage;
                                        accIdVsAccToBeUpdated.put(accountId, account);
                                    } else {
                                        Account account = accIdVsAccToBeUpdated.get(accountId);
                                        account.Sync_BVD_ID_Messge__c = errorMessage;
                                        accIdVsAccToBeUpdated.put(accountId, account);
                                    }
                                }
                            }
                            // shouldRetry = true; // << MM - FIN-10426 - retry logic removed >>
                        } else if(res.getStatusCode() == 429) {
                            String errorMessage = 'Failed to update in CFIN. Error: Webhook rate limit';
                            for(String key: deleteAccountKeyObjMap.keySet()) {
                                String bvdId = key.split('_')[1];
                                List<String> accountIds = deleteAccountKeyObjMap.get(key);
                                for(String accountId: accountIds) {
                                    if(!accIdVsAccToBeUpdated.keySet().contains(accountId)) {
                                        Account account = accIdVsAccMaster.get(accountId);
                                        appendBvdId(account, bvdId);
                                        account.Remove_BvD_ID_From_CFIN_Message__c = errorMessage;
                                        accIdVsAccToBeUpdated.put(accountId, account);
                                    } else {
                                        Account account = accIdVsAccToBeUpdated.get(accountId);
                                        appendBvdId(account, bvdId);
                                        account.Remove_BvD_ID_From_CFIN_Message__c = errorMessage;
                                        accIdVsAccToBeUpdated.put(accountId, account);
                                    }
                                }
                            }
                            for(String key: addAccountKeyObjMap.keySet()) {
                                List<String> accountIds = addAccountKeyObjMap.get(key);
                                for(String accountId: accountIds) {
                                    if(!accIdVsAccToBeUpdated.keySet().contains(accountId)) {
                                        Account account = accIdVsAccMaster.get(accountId);
                                        account.Sync_BVD_ID_Messge__c = errorMessage;
                                        accIdVsAccToBeUpdated.put(accountId, account);
                                    } else {
                                        Account account = accIdVsAccToBeUpdated.get(accountId);
                                        account.Sync_BVD_ID_Messge__c = errorMessage;
                                        accIdVsAccToBeUpdated.put(accountId, account);
                                    }
                                }
                            }
                            // shouldRetry = true; // << MM - FIN-10426 - retry logic removed >>
                        } else {
                            String errorMessage = 'Failed to update in CFIN. Error: ' + String.valueOf(res.getStatusCode());
                            for(String key: deleteAccountKeyObjMap.keySet()) {
                                String bvdId = key.split('_')[1];
                                List<String> accountIds = deleteAccountKeyObjMap.get(key);
                                for(String accountId: accountIds) {
                                    if(!accIdVsAccToBeUpdated.keySet().contains(accountId)) {
                                        Account account = accIdVsAccMaster.get(accountId);
                                        appendBvdId(account, bvdId);
                                        account.Remove_BvD_ID_From_CFIN_Message__c = errorMessage;
                                        accIdVsAccToBeUpdated.put(accountId, account);
                                    } else {
                                        Account account = accIdVsAccToBeUpdated.get(accountId);
                                        appendBvdId(account, bvdId);
                                        account.Remove_BvD_ID_From_CFIN_Message__c = errorMessage;
                                        accIdVsAccToBeUpdated.put(accountId, account);
                                    }
                                }
                            }
                            for(String key: addAccountKeyObjMap.keySet()) {
                                List<String> accountIds = addAccountKeyObjMap.get(key);
                                for(String accountId: accountIds) {
                                    if(!accIdVsAccToBeUpdated.keySet().contains(accountId)) {
                                        Account account = accIdVsAccMaster.get(accountId);
                                        account.Sync_BVD_ID_Messge__c = errorMessage;
                                        accIdVsAccToBeUpdated.put(accountId, account);
                                    } else {
                                        Account account = accIdVsAccToBeUpdated.get(accountId);
                                        account.Sync_BVD_ID_Messge__c = errorMessage;
                                        accIdVsAccToBeUpdated.put(accountId, account);
                                    }
                                }
                            }
                            // shouldRetry = true; // << MM - FIN-10426 - retry logic removed >>
                        }
                    } catch (Exception e) {
                        String errorMessage = 'Failed to update in CFIN. Exception occured: ' + e.getMessage();
                        for(String key: deleteAccountKeyObjMap.keySet()) {
                            String bvdId = key.split('_')[1];
                            List<String> accountIds = deleteAccountKeyObjMap.get(key);
                            for(String accountId: accountIds) {
                                if(!accIdVsAccToBeUpdated.keySet().contains(accountId)) {
                                    Account account = accIdVsAccMaster.get(accountId);
                                    appendBvdId(account, bvdId);
                                    account.Remove_BvD_ID_From_CFIN_Message__c = errorMessage;
                                    accIdVsAccToBeUpdated.put(accountId, account);
                                } else {
                                    Account account = accIdVsAccToBeUpdated.get(accountId);
                                    appendBvdId(account, bvdId);
                                    account.Remove_BvD_ID_From_CFIN_Message__c = errorMessage;
                                    accIdVsAccToBeUpdated.put(accountId, account);
                                }
                                
                            }
                        }
                        for(String key: addAccountKeyObjMap.keySet()) {
                            List<String> accountIds = addAccountKeyObjMap.get(key);
                            for(String accountId: accountIds) {
                                if(!accIdVsAccToBeUpdated.keySet().contains(accountId)) {
                                    Account account = accIdVsAccMaster.get(accountId);
                                    account.Sync_BVD_ID_Messge__c = errorMessage;
                                    accIdVsAccToBeUpdated.put(accountId, account);
                                } else {
                                    Account account = accIdVsAccToBeUpdated.get(accountId);
                                    account.Sync_BVD_ID_Messge__c = errorMessage;
                                    accIdVsAccToBeUpdated.put(accountId, account);
                                }
                                
                            }
                        }
                        // shouldRetry = true; // << MM - FIN-10426 - retry logic removed >>
                    }
                }


                if (accIdVsAccToBeUpdated.keySet().size() > 0) {
                    update accIdVsAccToBeUpdated.values();
                }
            }
        } catch (Exception e) {
            System.debug('Exception: ' + e.getMessage());
        }
        // << START - MM - FIN-10426 - Remove retry logic, add serial chaining >>
        /**
        if (!Test.isRunningTest() && shouldRetry && retryCount < 3 && (Limits.getQueueableJobs() < Limits.getLimitQueueableJobs())) {
            System.debug('Retrying... Attempt #' + (retryCount + 1));
            System.enqueueJob(new UpdateBvdIdInSourceSystemService(refMapList, retryCount + 1));
        }
        */
        if (!Test.isRunningTest() && remainingRefMaps.size() > 0) {
            System.enqueueJob(new UpdateBvdIdInSourceSystemService(remainingRefMaps));
        }
        // << END - MM - FIN-10426 - Remove retry logic, add serial chaining >>
    }

    private static void appendBvdId(Account acc, String bvdId) {
        if(String.isBlank(bvdId)) return; 
        System.debug('BVD_IDs_To_Be_Removed__c::' + acc.BVD_IDs_To_Be_Removed__c);
        if(String.isBlank(acc.BVD_IDs_To_Be_Removed__c)) {
            acc.BVD_IDs_To_Be_Removed__c = bvdId; 
        } else {
            Set<String> ids = new Set<String>(acc.BVD_IDs_To_Be_Removed__c.split(','));
            if(!ids.contains(bvdId)) {
                acc.BVD_IDs_To_Be_Removed__c += ',' + bvdId; 
            }
        }
    }

    // << START - MM - FIN-10426 - Inverse of appendBvdId; lets BVD_IDs_To_Be_Removed__c drain as removals succeed >>
    private static void removeBvdId(Account acc, String bvdId) {
        if(String.isBlank(bvdId) || String.isBlank(acc.BVD_IDs_To_Be_Removed__c)) return;
        List<String> remainingIds = new List<String>();
        for(String existingId : acc.BVD_IDs_To_Be_Removed__c.split(',')) {
            String trimmedId = existingId.trim();
            if(String.isNotBlank(trimmedId) && trimmedId != bvdId.trim()) {
                remainingIds.add(trimmedId);
            }
        }
        acc.BVD_IDs_To_Be_Removed__c = remainingIds.isEmpty() ? null : String.join(remainingIds, ',');
    }
    // << END - MM - FIN-10426 - Inverse of appendBvdId; lets BVD_IDs_To_Be_Removed__c drain as removals succeed >>

    public static void updateBvdIdInSAP(List<Map<String, String>> refMapList) {
        System.enqueueJob(new UpdateBvdIdInSourceSystemService(refMapList));
    }
}