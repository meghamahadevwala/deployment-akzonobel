public with sharing class UpdateBlockInSourceSystemService implements Queueable, Database.AllowsCallouts{
    public List<String> accountIds;
    public Integer retryCount;
    public UpdateBlockInSourceSystemService(List<String> accountIds, Integer retryCount) {
        this.accountIds = accountIds;
        this.retryCount = retryCount;
    }

    public UpdateBlockInSourceSystemService(List<String> accountIds) {
        this(accountIds, 0);
    }

    public void execute(QueueableContext context) {
        Boolean shouldRetry = false;
        try {
            List<Account> accounts = [SELECT Id, CurrencyIsoCode, celsrm__Credit_Limit__c, AccountNumber, celsrm__Credit_Control_Area__c, celsrm__Limit_Valid_To_Date__c, celsrm__Order_Block__c, Sync_Segment_Info_In_CFIN_At__c, Sync_Segment_Info_In_CFIN_Message__c FROM Account WHERE Id IN :accountIds];

            Map<String, Account> accountKeyObjMap = new Map<String, Account>();
            List<Map<String, Object>> accountList = new List<Map<String, Object>>();
            Map<String, Object> requestBodyMap = new Map<String, Object>();
            List<Account> accToBeUpdated = new List<Account>();
            String webhookURL = Credit_Configuration__c.getOrgDefaults().Update_Credit_Limit_Action_Flow_Webhook__c;
            if(webhookURL != null && webhookURL != '') {
                for (Account acc : accounts) {
                    String key = acc.celsrm__Credit_Control_Area__c + acc.AccountNumber;
                    accountKeyObjMap.put(key, acc);
    
                    Map<String, Object> map1 = new Map<String, Object>();
                    Decimal creditLimit = acc.celsrm__Credit_Limit__c;
                    if(creditLimit != null) {
                    //     creditLimit = calculateRequestedCreditLimit(creditLimit, cr.CurrencyIsoCode);
                    creditLimit = creditLimit.setScale(2);
                     }
                    
                    map1.put('approvedCreditLimit', creditLimit);
                    map1.put('accountNumber', acc.AccountNumber);
                    map1.put('creditControlArea', acc.celsrm__Credit_Control_Area__c);
                    if(acc.celsrm__Limit_Valid_To_Date__c != null) {
                        map1.put('limitValidToDate', acc.celsrm__Limit_Valid_To_Date__c);
                    }
                    map1.put('xblocked', acc.celsrm__Order_Block__c);
                    accountList.add(map1);
                }
                requestBodyMap.put('updateRequests', accountList);
    
                if (accountList.size() > 0) {
                    try {
                        HttpRequest req = new HttpRequest();
                        req.setEndpoint('callout:CelonisEMS' + '/' + webhookURL);
                        req.setMethod('POST');
                        req.setHeader('Content-Type', 'application/json');
                        String requestBody = JSON.serialize(requestBodyMap);
                        req.setBody(requestBody);
                        req.setTimeout(120000);
    
                        Http http = new Http();
                        HttpResponse res = http.send(req);
                        /**
                         * 401: {"status":"Error", "details":"Please make sure you have provided correct Authentication token"}
                         * 400: {"status":"Error", "details":"Required field is misisng"}
                         * 200: {"status":"Success", "details":{"updateResponse":[{"PARTNER":"1001099997","STATUS_MSG":"Update successful","CREDIT_LIMIT":50000,"CREDIT_SGMNT":"DPUY","LIMIT_VALID_DATE":"2025-11-18"}]}}
                         */
    
                        if (res.getStatusCode() == 200) {
                            String responseBody = res.getBody();
                            List<String> accountKeysGotResponse = new List<String>();
                            Map<String, Object> parsedResponse = (Map<String, Object>)JSON.deserializeUntyped(responseBody);
                            Map<String, Object> detailsMap = (Map<String, Object>)parsedResponse.get('details');
                            List<Object> updateResponse = (List<Object>)detailsMap.get('updateResponse');
    
                            for (Object obj : updateResponse) {
                                Map<String, Object> objMap = (Map<String, Object>)obj;
                                String creditSegment = (String)objMap.get('CREDIT_SGMNT');
                                String accountNumber = (String)objMap.get('PARTNER');
                                String statusMsg = (String)objMap.get('STATUS_MSG');
                                String key = creditSegment + accountNumber;
                                if(accountKeyObjMap.containsKey(key)) {
                                    accountKeysGotResponse.add(key);
                                    Account acc = accountKeyObjMap.get(key);
                                    if(statusMsg == 'Update successful'){
                                        acc.Sync_Segment_Info_In_CFIN_At__c = DateTime.now();
                                        acc.Sync_Segment_Info_In_CFIN_Message__c = statusMsg;
                                    } else{
                                        // cr.celsrm__Status__c = '50';
                                        acc.Sync_Segment_Info_In_CFIN_Message__c = statusMsg + '. Hence making it Voided.';
                                    }
                                    accToBeUpdated.add(acc);
                                }
                            }

                            for(String key: accountKeyObjMap.keySet()) {
                                if(!accountKeysGotResponse.contains(key)) {
                                    Account acc = accountKeyObjMap.get(key);  
                                    String msg = 'Failed to update in CFIN. Error: RFC Module Failed';
                                    acc.Sync_Segment_Info_In_CFIN_Message__c = msg;
                                    accToBeUpdated.add(acc);
                                }
                            }
                        } else if(res.getStatusCode() == 401 || res.getStatusCode() == 400) {
                            String responseBody = res.getBody();
                            Map<String, Object> parsedResponse = (Map<String, Object>)JSON.deserializeUntyped(responseBody);
                            String errorMessage = '';
                            if(parsedResponse.get('details') != null) {
                                errorMessage = (String) parsedResponse.get('details');
                            }
                            for(Map<String, Object> cr: accountList) {
                                String creditSegment = (String)cr.get('creditControlArea');
                                String accountNumber = (String)cr.get('accountNumber');
                                String key = creditSegment + accountNumber;
                                if(accountKeyObjMap.containsKey(key)) {
                                    Account acc = accountKeyObjMap.get(key);
                                    acc.Sync_Segment_Info_In_CFIN_Message__c = 'Failed to update in CFIN. Error: ' + errorMessage;
                                    accToBeUpdated.add(acc);
                                }
                            }
                        } else if(res.getStatusCode() == 500) {
                            String errorMessage = 'Failed to update in CFIN. Error: Internal Server Error';
                            for(Map<String, Object> cr: accountList) {
                                String creditSegment = (String)cr.get('creditControlArea');
                                String accountNumber = (String)cr.get('accountNumber');
                                String key = creditSegment + accountNumber;
                                if(accountKeyObjMap.containsKey(key)) {
                                    Account acc = accountKeyObjMap.get(key);
                                    acc.Sync_Segment_Info_In_CFIN_Message__c = errorMessage;
                                    accToBeUpdated.add(acc);
                                }
                            }
                            shouldRetry = true;
                        }  else if(res.getStatusCode() == 429) {
                            String errorMessage = 'Failed to update in CFIN. Error: Webhook rate limit';
                            for(Map<String, Object> cr: accountList) {
                                String creditSegment = (String)cr.get('creditControlArea');
                                String accountNumber = (String)cr.get('accountNumber');
                                String key = creditSegment + accountNumber;
                                if(accountKeyObjMap.containsKey(key)) {
                                    Account acc = accountKeyObjMap.get(key);
                                    acc.Sync_Segment_Info_In_CFIN_Message__c = errorMessage;
                                    accToBeUpdated.add(acc);
                                }
                            }
                            shouldRetry = true;
                        } else {
                            String errorMessage = 'Failed to update in CFIN. Error: ' + String.valueOf(res.getStatusCode());
                            for(Map<String, Object> cr: accountList) {
                                String creditSegment = (String)cr.get('creditControlArea');
                                String accountNumber = (String)cr.get('accountNumber');
                                String key = creditSegment + accountNumber;
                                if(accountKeyObjMap.containsKey(key)) {
                                    Account acc = accountKeyObjMap.get(key);
                                    acc.Sync_Segment_Info_In_CFIN_Message__c = errorMessage;
                                    accToBeUpdated.add(acc);
                                }
                            }
                            shouldRetry = true;
                        }
                    } catch (Exception e) {
                        String errorMessage = 'Failed to update in CFIN. Exception occured: ' + e.getMessage();
                        for(Map<String, Object> cr: accountList) {
                            String creditSegment = (String)cr.get('creditControlArea');
                            String accountNumber = (String)cr.get('accountNumber');
                            String key = creditSegment + accountNumber;
                            if(accountKeyObjMap.containsKey(key)) {
                                Account acc = accountKeyObjMap.get(key);
                                acc.Sync_Segment_Info_In_CFIN_Message__c = errorMessage;
                                accToBeUpdated.add(acc);
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
            System.enqueueJob(new UpdateBlockInSourceSystemService(accountIds, retryCount + 1));
        }
    }

    public static void updateBlockInSAP(List<String> accountIds) {
        System.enqueueJob(new UpdateBlockInSourceSystemService(accountIds));
    }
}