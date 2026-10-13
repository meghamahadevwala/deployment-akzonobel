public with sharing class UpdateInSourceSystemManager {

    public class UpdateCreditLimitResponse {
        @AuraEnabled public String status;
        @AuraEnabled public String message;
    }

    //Used in Aura Component for "Update in SAP" action
    @AuraEnabled
    public static UpdateCreditLimitResponse updateCreditLimit(String creditReviewId){
        UpdateCreditLimitResponse response = new UpdateCreditLimitResponse();
        celsrm__Credit_Review__c creditReview = [SELECT Id, CurrencyIsoCode, celsrm__Approved_Credit_Limit__c, celsrm__Account_Number__c , Credit_Segment_Akzo__c , celsrm__Account__c, celsrm__Account__r.celsrm__Company_Code__c,celsrm__Account__r.celsrm__Order_Block__c, celsrm__Status__c, Requested_Valid_To_Date__c, Approved_Valid_To_Date__c, celsrm__Synced_In_Source_System_At__c  FROM celsrm__Credit_Review__c WHERE Id = :creditReviewId];
        Account account = [SELECT Id, CurrencyIsoCode, Sync_Segment_Info_In_CFIN_At__c, Sync_Segment_Info_In_CFIN_Message__c  FROM Account WHERE Id = :creditReview.celsrm__Account__c];
        try{
            if(creditReview.celsrm__Synced_In_Source_System_At__c != null) {
                response.status = 'error';
                response.message = 'Credit Limit is already synced with CFIN System';
                return response;
            }
            if(creditReview.celsrm__Status__c == '40' || creditReview.celsrm__Status__c == '11' || creditReview.celsrm__Status__c == '12') {
                String webhookURL = Credit_Configuration__c.getOrgDefaults().Update_Credit_Limit_Action_Flow_Webhook__c;
                if(webhookURL == null || webhookURL == '') {
                    response.status = 'error';
                    response.message = 'Configure Webhook URL to update the credit limit.';
                    return response;
                }
                HttpRequest req = new HttpRequest();
                req.setEndpoint('callout:CelonisEMS' + '/' + webhookURL);
                req.setMethod('POST');
                req.setHeader('Content-Type', 'application/json');
                List<Map<String, Object>> creditReviewList = new List<Map<String, Object>>();
                Map<String,Object> bodyMap = new Map<String,Object>();
                Map<String, Object> requestBodyMap = new Map<String, Object>();
                bodyMap.put('currrencyIsoCode', creditReview.CurrencyIsoCode);
                Decimal creditLimit = creditReview.celsrm__Approved_Credit_Limit__c;
                Boolean isDecimalConversionRequired = Credit_Configuration__c.getOrgDefaults().Decimal_Adjustment_For_Write_Back__c;
                if(creditLimit != null && isDecimalConversionRequired == true) {
                    creditLimit = calculateRequestedCreditLimit(creditLimit, creditReview.CurrencyIsoCode);
                }
                if(creditLimit != null) {
                     creditLimit = creditLimit.setScale(2);
                }
                bodyMap.put('approvedCreditLimit', creditLimit);
                bodyMap.put('accountNumber', creditReview.celsrm__Account_Number__c );
                bodyMap.put('creditControlArea', creditReview.Credit_Segment_Akzo__c );
                if(creditReview.Approved_Valid_To_Date__c != null) {
                    bodyMap.put('limitValidToDate', creditReview.Approved_Valid_To_Date__c);
                } else {
                    bodyMap.put('limitValidToDate', creditReview.Requested_Valid_To_Date__c);
                }
                bodyMap.put('xblocked', creditReview.celsrm__Account__r.celsrm__Order_Block__c);
                creditReviewList.add(bodyMap);
                requestBodyMap.put('updateRequests', creditReviewList);
                
                
                String requestBody = JSON.serialize(requestBodyMap);
                System.debug('requestBody>>>' + requestBody);
                req.setBody(requestBody);
                req.setTimeout(120000);

                Http http = new Http();
                System.debug('Before Request timestamp: ' + System.now());
                HttpResponse res = http.send(req);
                System.debug('After Response timestamp: ' + System.now());

                System.debug(res.getBody());
                /**
                 * 401: {"status":"Error", "details":"Please make sure you have provided correct Authentication token"}
                 * 400: {"status":"Error", "details":"Required field is misisng"}
                 * 200: {"status":"Success", "details":{"updateResponse":[{"PARTNER":"1001099997","STATUS_MSG":"Update successful","CREDIT_LIMIT":50000,"CREDIT_SGMNT":"DPUY","LIMIT_VALID_DATE":"2025-11-18"}]}}
                 */
                if (res.getStatusCode() == 200) {
                    String responseBody = res.getBody();
                    if(responseBody == 'Accepted') {
                        String errorMessage = 'Failed to update in CFIN. Error: Something went wrong! (Action flow could be deactivated)';
                        creditReview.celsrm__Synced_In_Source_System_At__c = null;
                        creditReview.Sync_Message__c = errorMessage;
                        account.Sync_Segment_Info_In_CFIN_Message__c = errorMessage;
                        update creditReview;
                        update account;
                        response.status = 'error';
                        response.message = errorMessage;
                    } else {
                        Map<String, Object> parsedResponse = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
                        Map<String, Object> detailsMap = (Map<String, Object>)parsedResponse.get('details');
                        List<Object> updateResponse = (List<Object>)detailsMap.get('updateResponse');
                        if(updateResponse.size() > 0) {
                            Map<String, Object> objMap = (Map<String, Object>)updateResponse[0];
                            String statusMsg = (String)objMap.get('STATUS_MSG');
                            if (statusMsg == 'Update successful') {
                                creditReview.celsrm__Synced_In_Source_System_At__c = DateTime.now();
                                account.Sync_Segment_Info_In_CFIN_At__c = DateTime.now();
                                response.status = 'success';
                            } else {
                                creditReview.celsrm__Synced_In_Source_System_At__c = null;
                                response.status = 'error';
                            }
                            creditReview.Sync_Message__c = statusMsg;
                            account.Sync_Segment_Info_In_CFIN_Message__c = statusMsg;
                            response.message = statusMsg;
                            update creditReview;
                            update account;
                        } else {
                            String msg = 'Failed to update in CFIN. Error: RFC Module Failed';
                            creditReview.celsrm__Synced_In_Source_System_At__c = null;
                            creditReview.Sync_Message__c = msg;
                            account.Sync_Segment_Info_In_CFIN_Message__c = msg;
                            response.message = msg;
                            update creditReview;
                            update account;
                        }
                    }
                } else if(res.getStatusCode() == 401 || res.getStatusCode() == 400) {
                    String responseBody = res.getBody();
                    Map<String, Object> parsedResponse = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
                    String errorMessage = 'Failed to update in CFIN. Error: ' + (String)parsedResponse.get('details');
                    creditReview.celsrm__Synced_In_Source_System_At__c = null;
                    creditReview.Sync_Message__c = errorMessage;
                    account.Sync_Segment_Info_In_CFIN_Message__c = errorMessage;
                    update creditReview;
                    update account;
                    response.status = 'error';
                    response.message = errorMessage;
                }  else if(res.getStatusCode() == 500) {
                    String errorMessage = 'Failed to update in CFIN. Error: Internal Server Error';
                    creditReview.celsrm__Synced_In_Source_System_At__c = null;
                    creditReview.Sync_Message__c = errorMessage;
                    account.Sync_Segment_Info_In_CFIN_Message__c = errorMessage;
                    update creditReview;
                    update account;
                    response.status = 'error';
                    response.message = errorMessage;
                } else if(res.getStatusCode() == 429) {
                    String errorMessage = 'Failed to update in CFIN. Error: Webhook rate limit';
                    creditReview.celsrm__Synced_In_Source_System_At__c = null;
                    creditReview.Sync_Message__c = errorMessage;
                    account.Sync_Segment_Info_In_CFIN_Message__c = errorMessage;
                    update creditReview;
                    update account;
                    response.status = 'error';
                    response.message = errorMessage;
                } else {
                    String errorMessage = 'Failed to update in CFIN. Error: ' + String.valueOf(res.getStatusCode());
                    creditReview.celsrm__Synced_In_Source_System_At__c = null;
                    creditReview.Sync_Message__c = errorMessage;
                    account.Sync_Segment_Info_In_CFIN_Message__c = errorMessage;
                    update creditReview;
                    update account;
                    response.status = 'error';
                    response.message = errorMessage;
                }
            } else {
                response.status = 'error';
                response.message = 'Credit limit can be updated only for approved credit review.';
            }
        } catch(exception e){
            System.debug('After Response timestamp: ' + System.now());
            String errorMessage = 'Failed to update in CFIN. Exception occured: ' + e.getMessage();
            account.Sync_Segment_Info_In_CFIN_Message__c = errorMessage;
            creditReview.celsrm__Synced_In_Source_System_At__c = null;
            creditReview.Sync_Message__c = errorMessage;
            update creditReview;
            update account;
            response.status = 'error';
            response.message =  errorMessage;
        }
        //-- Starts |FIN-7510| Changed by Asera | 08 JAN 2026 --//
        try {
                
            List<String> idSet = new List<String>();
            idSet.add(creditReview.Id);
            celsrm.SRMUtilityController.insertActivity(idSet, 'celsrm__Credit_Review__c', 'Updated in SAP', null, 100, 'Credit Review : Updated in SAP', UserInfo.getUserId(), null, 'Internal');
            // String metadataJson = JSON.serialize(bodyMap);
            Map<String, Object> inputParams = new Map<String, Object>{
                'userId' => UserInfo.getUserId(),
                'pageScreenName' => 'Updated in SAP',
                'actionPerformed' => true,
                'actionTakenTime' => null,
                'accountId' => creditReview.celsrm__Account__c,
                'transactionId' => null,
                'disputeId' => null,
                'creditReviewId' => creditReview.Id,
                'additionalMetadata' => null
            };
            System.debug('Full json :' + JSON.serialize(inputParams));
            Id activityId = celsrm.SRMUtilityController.logActivity(JSON.serialize(inputParams));
            System.debug('Full activity : ' + activityId);
        } catch (Exception e) {
            System.debug('Error logging activity: ' + e.getMessage() + ' ' + e.getLineNumber());
        } 
        //-- End |FIN-7510| Changed by Asera | 08 JAN 2026 --//
        return response;
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