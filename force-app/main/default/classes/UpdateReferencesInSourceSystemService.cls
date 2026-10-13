public with sharing class UpdateReferencesInSourceSystemService implements Queueable, Database.AllowsCallouts{
    public List<Map<String, String>> refMapList;
    public Integer retryCount;

    public UpdateReferencesInSourceSystemService(List<Map<String, String>> refMapList, Integer retryCount) {
        this.refMapList = refMapList;
        this.retryCount = retryCount;
    }

    public UpdateReferencesInSourceSystemService(List<Map<String, String>> refMapList) {
        this(refMapList, 0);
    }

    public void execute(QueueableContext context) {
        Boolean shouldRetry = false;
        try {

            Map<String, List<String>> accountKeyObjMap = new Map<String, List<String>>();
            List<Map<String, Object>> refList = new List<Map<String, Object>>();
            Map<String, Object> requestBodyMap = new Map<String, Object>();
            List<Account> accToBeUpdated = new List<Account>();
            String webhookURL = Credit_Configuration__c.getOrgDefaults().Update_References_Action_Flow_Webhook__c;
            List<String> oldNewParentIds =  new List<String>();
            if(webhookURL != null && webhookURL != '') {
                for (Map<String, String> refMap : refMapList) {
                    String oldParentId = refMap.get('oldParentId');
                    if(refMap.get('oldParentId') != null) {
                        oldNewParentIds.add(refMap.get('oldParentId'));
                    }
                    if(refMap.get('newParentId') != null) {
                        oldNewParentIds.add(refMap.get('newParentId'));
                    }
                }
                if(oldNewParentIds.size() > 0) {
                    Map<Id, String> accountMap = new Map<Id, String>();
                    List<Account> accounts = [SELECT Id, AccountNumber FROM Account WHERE Id IN :oldNewParentIds];
                    for (Account acc : accounts) {
                        accountMap.put(acc.Id, acc.AccountNumber);
                    }
                    for (Map<String, String> refMap : refMapList) {
                        String accountNumber = refMap.get('accountNumber');
                        String accountId = refMap.get('accountId');
                        String creditControlArea = refMap.get('creditControlArea');
                        String oldParentNumber = accountMap.get(refMap.get('oldParentId'));
                        String newParentNumber = accountMap.get(refMap.get('newParentId'));
                        if(oldParentNumber != null) {
                            Map<String, Object> map1 = new Map<String, Object>();
                            map1.put('IV_PARTNER_1', oldParentNumber);
                            map1.put('IV_PARTNER_2', accountNumber);
                            map1.put('IV_DIFFERENTIATION', creditControlArea);
                            map1.put('DELETE', 'X');
                            refList.add(map1);
                        }
                        if(newParentNumber != null) {
                            Map<String, Object> map2 = new Map<String, Object>();
                            map2.put('IV_PARTNER_1', newParentNumber);
                            map2.put('IV_PARTNER_2', accountNumber);
                            map2.put('IV_DIFFERENTIATION', creditControlArea);
                            map2.put('DELETE', '');
                            refList.add(map2);
                        }

                        String key = accountNumber + '-' + creditControlArea;
                        if(accountKeyObjMap.containsKey(key)) {
                            List<String> accountList = accountKeyObjMap.get(key);
                            accountList.add(accountId);
                            accountKeyObjMap.put(key, accountList);
                        } else {
                            List<String> accountList = new List<String>();
                            accountList.add(accountId);
                            accountKeyObjMap.put(key, accountList);
                        }
                    }
                }
                requestBodyMap.put('updateRequests', refList);
    
                if (refList.size() > 0) {
                    try {
                        
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
                         * 200: {"status":"Error","details":{"updateResponse":[{"PARTNER":"1000185253","STATUS_MSG":"Update successful"}]}}
                         */
                        if (res.getStatusCode() == 200) {
                            String responseBody = res.getBody();
                            if(responseBody == 'Accepted') {
                                String errorMessage = 'Failed to update in CFIN. Error: Something went wrong! (Action flow could be deactivated)';
                                for(Map<String, Object> ref: refList) {
                                    String creditControlArea = (String)ref.get('IV_DIFFERENTIATION');
                                    String accountNumber = (String)ref.get('IV_PARTNER_2');
                                    String key = accountNumber + '-' + creditControlArea;
                                    if(accountKeyObjMap.containsKey(key)) {
                                        List<String> accountIds = accountKeyObjMap.get(key);                                
                                        for(String accountId: accountIds) {
                                            Account acc = new Account(Id=accountId);
                                            acc.Sync_Relation_Data_In_CFIN_Message__c = errorMessage;
                                            accToBeUpdated.add(acc);
                                        }
                                    }
                                }
                            } else {
                                List<String> accountKeysGotResponse = new List<String>();
                                Map<String, Object> parsedResponse = (Map<String, Object>)JSON.deserializeUntyped(responseBody);
                                Map<String, Object> detailsMap = (Map<String, Object>)parsedResponse.get('details');
                                List<Object> updateResponse = (List<Object>)detailsMap.get('updateResponse');
                                
                                //Process Accounts with success response
                                for (Object obj : updateResponse) {
                                    Map<String, Object> objMap = (Map<String, Object>)obj;
                                    String accountNumber = (String)objMap.get('IV_PARTNER_2');
                                    String creditControlArea = (String)objMap.get('IV_DIFFERENTIATION');
                                    String statusMsg = (String)objMap.get('STATUS_MSG');
                                    String key = accountNumber + '-' + creditControlArea;
                                    if(accountKeyObjMap.containsKey(key)) {
                                        accountKeysGotResponse.add(key);
                                        List<String> accountIds = accountKeyObjMap.get(key);                                
                                        for(String accountId: accountIds) {
                                            Account account = new Account(Id=accountId);
                                            if(statusMsg == 'Update successful' || statusMsg == 'Relationship maintained successfully'){
                                                account.Sync_Relation_Data_In_CFIN_At__c = DateTime.now();
                                                account.Sync_Relation_Data_In_CFIN_Message__c = statusMsg;
                                            } else{
                                                account.Sync_Relation_Data_In_CFIN_Message__c = statusMsg;
                                            }
                                            accToBeUpdated.add(account);
                                        }
                                    }
                                }
                                //Process Account with failed RFC Module Error
                                for(String key: accountKeyObjMap.keySet()) {
                                    if(!accountKeysGotResponse.contains(key)) {
                                        List<String> accountIds = accountKeyObjMap.get(key);                                
                                        for(String accountId: accountIds) {
                                            Account account = new Account(Id=accountId);
                                            account.Sync_Relation_Data_In_CFIN_Message__c = 'Failed to update in CFIN. Error: RFC Module Failed';
                                            accToBeUpdated.add(account);
                                        }
                                    }
                                }
                            }
                        } else if(res.getStatusCode() == 401 || res.getStatusCode() == 501 || res.getStatusCode() == 400) {
                            String responseBody = res.getBody();
                            Map<String, Object> parsedResponse = (Map<String, Object>)JSON.deserializeUntyped(responseBody);
                            String errorMessage = 'Failed to update in CFIN. Error: ';
                            if(parsedResponse.get('details') != null) {
                                errorMessage += (String) parsedResponse.get('details');
                            }
                            for(Map<String, Object> ref: refList) {
                                String creditControlArea = (String)ref.get('IV_DIFFERENTIATION');
                                String accountNumber = (String)ref.get('IV_PARTNER_2');
                                String key = accountNumber + '-' + creditControlArea;
                                if(accountKeyObjMap.containsKey(key)) {
                                    List<String> accountIds = accountKeyObjMap.get(key);                                
                                    for(String accountId: accountIds) {
                                        Account acc = new Account(Id=accountId);
                                        acc.Sync_Relation_Data_In_CFIN_Message__c = errorMessage;
                                        accToBeUpdated.add(acc);
                                    }
                                }
                            }
                        } else if(res.getStatusCode() == 500) {
                            String errorMessage = 'Failed to update in CFIN. Error: Internal Server Error';
                            for(Map<String, Object> ref: refList) {
                                String creditControlArea = (String)ref.get('IV_DIFFERENTIATION');
                                String accountNumber = (String)ref.get('IV_PARTNER_2');
                                String key = accountNumber + '-' + creditControlArea;
                                if(accountKeyObjMap.containsKey(key)) {
                                    List<String> accountIds = accountKeyObjMap.get(key);                                
                                    for(String accountId: accountIds) {
                                        Account acc = new Account(Id=accountId);
                                        acc.Sync_Relation_Data_In_CFIN_Message__c = errorMessage;
                                        accToBeUpdated.add(acc);
                                    }
                                }
                            }
                            shouldRetry = true;
                        } else if(res.getStatusCode() == 429) {
                            String errorMessage = 'Failed to update in CFIN. Error: Webhook rate limit';
                            for(Map<String, Object> ref: refList) {
                                String creditControlArea = (String)ref.get('IV_DIFFERENTIATION');
                                String accountNumber = (String)ref.get('IV_PARTNER_2');
                                String key = accountNumber + '-' + creditControlArea;
                                if(accountKeyObjMap.containsKey(key)) {
                                    List<String> accountIds = accountKeyObjMap.get(key);                                
                                    for(String accountId: accountIds) {
                                        Account acc = new Account(Id=accountId);
                                        acc.Sync_Relation_Data_In_CFIN_Message__c = errorMessage;
                                        accToBeUpdated.add(acc);
                                    }
                                }
                            }
                            shouldRetry = true;
                        } else {
                            String errorMessage = 'Failed to update in CFIN. Error: ' + String.valueOf(res.getStatusCode());
                            for(Map<String, Object> ref: refList) {
                                String creditControlArea = (String)ref.get('IV_DIFFERENTIATION');
                                String accountNumber = (String)ref.get('IV_PARTNER_2');
                                String key = accountNumber + '-' + creditControlArea;
                                if(accountKeyObjMap.containsKey(key)) {
                                    List<String> accountIds = accountKeyObjMap.get(key);                                
                                    for(String accountId: accountIds) {
                                        Account acc = new Account(Id=accountId);
                                        acc.Sync_Relation_Data_In_CFIN_Message__c = errorMessage;
                                        accToBeUpdated.add(acc);
                                    }
                                }
                            }
                            shouldRetry = true;
                        }
                    } catch (Exception e) {
                        String errorMessage = 'Failed to update in CFIN. Exception occured: ' + e.getMessage();
                        for(Map<String, Object> ref: refList) {
                            String creditControlArea = (String)ref.get('IV_DIFFERENTIATION');
                            String accountNumber = (String)ref.get('IV_PARTNER_2');
                            String key = accountNumber + '-' + creditControlArea;
                            if(accountKeyObjMap.containsKey(key)) {
                                List<String> accountIds = accountKeyObjMap.get(key);                                
                                for(String accountId: accountIds) {
                                    Account acc = new Account(Id=accountId);
                                    acc.Sync_Relation_Data_In_CFIN_Message__c = errorMessage;
                                    accToBeUpdated.add(acc);
                                }
                            }
                        }
                        shouldRetry = true;
                    }
                }
    
                if (accToBeUpdated.size() > 0) {
                    update accToBeUpdated;
                }
            }
        } catch (Exception e) {
            System.debug('Exception: ' + e.getMessage());
        }
        if (!Test.isRunningTest() && shouldRetry && retryCount < 3) {
            System.debug('Retrying... Attempt #' + (retryCount + 1));
            System.enqueueJob(new UpdateReferencesInSourceSystemService(refMapList, retryCount + 1));
        }
    }

    public static void updateReferenceDataInSAP(List<Map<String, String>> refMapList) {
        System.enqueueJob(new UpdateReferencesInSourceSystemService(refMapList));
    }
}