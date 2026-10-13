public with sharing class UpdateLimitInSourceSystemService implements Queueable, Database.AllowsCallouts {

    public List<String> creditReviewIds;
    
    public UpdateLimitInSourceSystemService(List<String> creditReviewIds) {
        this.creditReviewIds = creditReviewIds;
    }

    public void execute(QueueableContext context) {
        try {
            List<celsrm__Credit_Review__c> creditReviews = [SELECT Id, CurrencyIsoCode, celsrm__Approved_Credit_Limit__c, celsrm__Account_Number__c, Credit_Segment_Akzo__c, celsrm__Account__r.celsrm__Company_Code__c, celsrm__Account__r.celsrm__Order_Block__c, celsrm__Status__c, Requested_Valid_To_Date__c, Approved_Valid_To_Date__c, celsrm__Account__c FROM celsrm__Credit_Review__c WHERE Id IN :creditReviewIds];

            Map<String, celsrm__Credit_Review__c> creditReviewKeyObjMap = new Map<String, celsrm__Credit_Review__c>();
            List<Map<String, Object>> creditReviewList = new List<Map<String, Object>>();
            Map<String, Object> requestBodyMap = new Map<String, Object>();
            List<celsrm__Credit_Review__c> crToBeUpdated = new List<celsrm__Credit_Review__c>();
            List<Account> accToBeUpdated = new List<Account>();
            String webhookURL = Credit_Configuration__c.getOrgDefaults().Update_Credit_Limit_Action_Flow_Webhook__c;
            if(webhookURL != null && webhookURL != '') {
                for (celsrm__Credit_Review__c cr : creditReviews) {
                    String key = cr.Credit_Segment_Akzo__c + cr.celsrm__Account_Number__c;
                    creditReviewKeyObjMap.put(key, cr);
    
                    Map<String, Object> map1 = new Map<String, Object>();
                    Decimal creditLimit = cr.celsrm__Approved_Credit_Limit__c;
                    Boolean isDecimalConversionRequired = Credit_Configuration__c.getOrgDefaults().Decimal_Adjustment_For_Write_Back__c;
                    if(creditLimit != null && isDecimalConversionRequired == true) {
                        creditLimit = calculateRequestedCreditLimit(creditLimit, cr.CurrencyIsoCode);
                     }
                     if(creditLimit != null) {
                          creditLimit = creditLimit.setScale(2);
                      }
                    map1.put('approvedCreditLimit', creditLimit);
                    map1.put('accountNumber', cr.celsrm__Account_Number__c);
                    map1.put('creditControlArea', cr.Credit_Segment_Akzo__c);
                    if(cr.Approved_Valid_To_Date__c != null) {
                        map1.put('limitValidToDate', cr.Approved_Valid_To_Date__c);
                    } else {
                        map1.put('limitValidToDate', cr.Requested_Valid_To_Date__c);
                    }
                    map1.put('xblocked', cr.celsrm__Account__r.celsrm__Order_Block__c);
                    creditReviewList.add(map1);
                }
                requestBodyMap.put('updateRequests', creditReviewList);
    
                if (creditReviewList.size() > 0) {
                    try {
                        HttpRequest req = new HttpRequest();
                        req.setEndpoint('callout:CelonisEMS' + '/' + webhookURL);
                        req.setMethod('POST');
                        req.setHeader('Content-Type', 'application/json');
                        String requestBody = JSON.serialize(requestBodyMap);
                        req.setBody(requestBody);
                        req.setTimeout(120000);
    
                        Http http = new Http();
                        System.debug('Before Request timestamp: ' + System.now());
                        HttpResponse res = http.send(req);
                        System.debug('After Response timestamp: ' + System.now());
                        /**
                         * 401: {"status":"Error", "details":"Please make sure you have provided correct Authentication token"}
                         * 400: {"status":"Error", "details":"Required field is misisng"}
                         * 200: {"status":"Success", "details":{"updateResponse":[{"PARTNER":"1001099997","STATUS_MSG":"Update successful","CREDIT_LIMIT":50000,"CREDIT_SGMNT":"DPUY","LIMIT_VALID_DATE":"2025-11-18"}]}}
                         */
    
                        if (res.getStatusCode() == 200) {
                            String responseBody = res.getBody();
                            if(responseBody == 'Accepted') {
                                String errorMessage = 'Failed to update in CFIN. Error: Something went wrong! (Action flow could be deactivated)';
                                for(Map<String, Object> cr: creditReviewList) {
                                    String creditSegment = (String)cr.get('creditControlArea');
                                    String accountNumber = (String)cr.get('accountNumber');
                                    String key = creditSegment + accountNumber;
                                    if(creditReviewKeyObjMap.containsKey(key)) {
                                        celsrm__Credit_Review__c crVar = creditReviewKeyObjMap.get(key);
                                        Account acc = new Account(Id=crVar.celsrm__Account__c);
                                        crVar.celsrm__Synced_In_Source_System_At__c = null;
                                        crVar.Sync_Message__c = errorMessage;
                                        acc.Sync_Segment_Info_In_CFIN_Message__c = errorMessage;
                                        crToBeUpdated.add(crVar);
                                        accToBeUpdated.add(acc);
                                    }
                                }
                            } else {
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
                                    if(creditReviewKeyObjMap.containsKey(key)) {
                                        accountKeysGotResponse.add(key);
                                        celsrm__Credit_Review__c cr = creditReviewKeyObjMap.get(key);
                                        Account acc = new Account(Id=cr.celsrm__Account__c);
                                        if(statusMsg == 'Update successful'){
                                            Datetime currentTime = DateTime.now();
                                            cr.celsrm__Synced_In_Source_System_At__c = currentTime;
                                            cr.Sync_Message__c = statusMsg;
                                            acc.Sync_Segment_Info_In_CFIN_At__c = currentTime;
                                            acc.Sync_Segment_Info_In_CFIN_Message__c = statusMsg;
                                        } else{
                                            // cr.celsrm__Status__c = '50';
                                            cr.celsrm__Synced_In_Source_System_At__c = null;
                                            cr.Sync_Message__c = statusMsg;
                                            acc.Sync_Segment_Info_In_CFIN_Message__c = statusMsg;
                                        }
                                        crToBeUpdated.add(cr);
                                        accToBeUpdated.add(acc);
                                    }
                                }
                                for(String key: creditReviewKeyObjMap.keySet()) {
                                    if(!accountKeysGotResponse.contains(key)) {
                                        celsrm__Credit_Review__c cr = creditReviewKeyObjMap.get(key);  
                                        Account acc = new Account(Id=cr.celsrm__Account__c);
                                        String msg = 'Failed to update in CFIN. Error: RFC Module Failed';
                                        cr.Sync_Message__c = msg;
                                        acc.Sync_Segment_Info_In_CFIN_Message__c = msg;
                                        crToBeUpdated.add(cr);
                                        accToBeUpdated.add(acc);
                                    }
                                }
                            }
                        } else if(res.getStatusCode() == 401 || res.getStatusCode() == 400) {
                            String responseBody = res.getBody();
                            Map<String, Object> parsedResponse = (Map<String, Object>)JSON.deserializeUntyped(responseBody);
                            String errorMessage = 'Failed to update in CFIN. Error: ' + (String)parsedResponse.get('details');
                            for(Map<String, Object> cr: creditReviewList) {
                                String creditSegment = (String)cr.get('creditControlArea');
                                String accountNumber = (String)cr.get('accountNumber');
                                String key = creditSegment + accountNumber;
                                if(creditReviewKeyObjMap.containsKey(key)) {
                                    celsrm__Credit_Review__c crVar = creditReviewKeyObjMap.get(key);
                                    Account acc = new Account(Id=crVar.celsrm__Account__c);
                                    crVar.celsrm__Synced_In_Source_System_At__c = null;
                                    crVar.Sync_Message__c = errorMessage;
                                    acc.Sync_Segment_Info_In_CFIN_Message__c = errorMessage;
                                    crToBeUpdated.add(crVar);
                                    accToBeUpdated.add(acc);
                                }
                            }
                        } else if(res.getStatusCode() == 500) {
                            String errorMessage = 'Failed to update in CFIN. Error: Internal Server Error';
                            for(Map<String, Object> cr: creditReviewList) {
                                String creditSegment = (String)cr.get('creditControlArea');
                                String accountNumber = (String)cr.get('accountNumber');
                                String key = creditSegment + accountNumber;
                                if(creditReviewKeyObjMap.containsKey(key)) {
                                    celsrm__Credit_Review__c crVar = creditReviewKeyObjMap.get(key);
                                    Account acc = new Account(Id=crVar.celsrm__Account__c);
                                    crVar.celsrm__Synced_In_Source_System_At__c = null;
                                    crVar.Sync_Message__c = errorMessage;
                                    acc.Sync_Segment_Info_In_CFIN_Message__c = errorMessage;
                                    crToBeUpdated.add(crVar);
                                    accToBeUpdated.add(acc);
                                }
                            }
                        } else if(res.getStatusCode() == 429) {
                            String errorMessage = 'Failed to update in CFIN. Error: Webhook rate limit';
                            for(Map<String, Object> cr: creditReviewList) {
                                String creditSegment = (String)cr.get('creditControlArea');
                                String accountNumber = (String)cr.get('accountNumber');
                                String key = creditSegment + accountNumber;
                                if(creditReviewKeyObjMap.containsKey(key)) {
                                    celsrm__Credit_Review__c crVar = creditReviewKeyObjMap.get(key);
                                    Account acc = new Account(Id=crVar.celsrm__Account__c);
                                    crVar.celsrm__Synced_In_Source_System_At__c = null;
                                    crVar.Sync_Message__c = errorMessage;
                                    acc.Sync_Segment_Info_In_CFIN_Message__c = errorMessage;
                                    crToBeUpdated.add(crVar);
                                    accToBeUpdated.add(acc);
                                }
                            }
                        } else {
                            String errorMessage = 'Failed to update in CFIN. Error: ' + String.valueOf(res.getStatusCode());
                            for(Map<String, Object> cr: creditReviewList) {
                                String creditSegment = (String)cr.get('creditControlArea');
                                String accountNumber = (String)cr.get('accountNumber');
                                String key = creditSegment + accountNumber;
                                if(creditReviewKeyObjMap.containsKey(key)) {
                                    celsrm__Credit_Review__c crVar = creditReviewKeyObjMap.get(key);
                                    Account acc = new Account(Id=crVar.celsrm__Account__c);
                                    crVar.celsrm__Synced_In_Source_System_At__c = null;
                                    crVar.Sync_Message__c = errorMessage;
                                    acc.Sync_Segment_Info_In_CFIN_Message__c = errorMessage;
                                    crToBeUpdated.add(crVar);
                                    accToBeUpdated.add(acc);
                                }
                            }
                        }
                    } catch (Exception e) {
                        System.debug('After Response timestamp: ' + System.now());
                        String errorMessage = 'Failed to update in CFIN. Exception occured: ' + e.getMessage();
                        for(Map<String, Object> cr: creditReviewList) {
                            String creditSegment = (String)cr.get('creditControlArea');
                            String accountNumber = (String)cr.get('accountNumber');
                            String key = creditSegment + accountNumber;
                            if(creditReviewKeyObjMap.containsKey(key)) {
                                celsrm__Credit_Review__c crVar = creditReviewKeyObjMap.get(key);
                                Account acc = new Account(Id=crVar.celsrm__Account__c);
                                crVar.celsrm__Synced_In_Source_System_At__c = null;
                                crVar.Sync_Message__c = errorMessage;
                                acc.Sync_Segment_Info_In_CFIN_Message__c = errorMessage;
                                crToBeUpdated.add(crVar);
                                accToBeUpdated.add(acc);
                            }
                        }
                    }
                }
    
                if (crToBeUpdated.size() > 0) {
                    update crToBeUpdated;
                }   
                if (accToBeUpdated.size() > 0) {
                    update accToBeUpdated;
                }
            }
        } catch (Exception e) {
            System.debug('Exception: ' + e.getMessage());
        }
    }

    public static void updateCreditLimitInSAP(List<String> creditReviewIds) {
        System.enqueueJob(new UpdateLimitInSourceSystemService(creditReviewIds));
    }
    private static Decimal calculateRequestedCreditLimit(Decimal creditLimit, String currencyCode) {
        Map<Object, Object> returnMap = new Map<Object, Object>();
        CurrencyType currencyConv = [SELECT IsoCode, DecimalPlaces FROM CurrencyType WHERE IsoCode = :currencyCode];
        if(currencyConv != null) {
            if(currencyConv.DecimalPlaces == 0) {
                return creditLimit / 100;
            } else if(currencyConv.DecimalPlaces == 1) {
                return creditLimit / 10;
            } else if(currencyConv.DecimalPlaces == 3) {
                return creditLimit * 10;
            }
        }
        return creditLimit;
    }
}