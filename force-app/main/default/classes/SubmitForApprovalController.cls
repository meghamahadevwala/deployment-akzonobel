public with sharing class SubmitForApprovalController {
    public class SubmitForApprovalResponse {
        @AuraEnabled public String status;
        @AuraEnabled public String message;
    }

    @AuraEnabled
    public static SubmitForApprovalResponse submitForApproval(String creditReviewId, Boolean includeAttachments){
        SubmitForApprovalResponse response = new SubmitForApprovalResponse();
        try{
            celsrm__Credit_Review__c creditReview = [SELECT Id, Name, CreatedDate, CurrencyIsoCode, celsrm__Requested_Credit_Limit__c, celsrm__Account__c, celsrm__Account__r.AccountNumber, celsrm__Account__r.celsrm__Credit_Control_Area__c, celsrm__Account__r.celsrm__Company_Code__c, celsrm__Status__c, CreatedBy.Name, celsrm__Model_Type__c, Credit_Segment_Akzo__c, Credit_Limit__c, celsrm__Risk_Class__c, Credit_Exposure__c, Expected_Turnover__c, Secured_Amount__c, celsrm__Credit_Group__c, celsrm__Account__r.Credit_Utilization_AkzoNobel__c, celsrm__Account__r.CurrencyIsoCode, Payment_Terms_Days__c, celsrm__Account_Number__c, celsrm__Account__r.Name, celsrm__Account__r.BillingStreet, celsrm__Account__r.BillingPostalCode, celsrm__Account__r.BillingCity, celsrm__Account__r.BillingState, celsrm__Account__r.BillingCountry, Moody_s_Credit_Limit__c, Requested_Valid_To_Date__c, celsrm__Notes__c FROM celsrm__Credit_Review__c WHERE Id = :creditReviewId];
            // creditReview.celsrm__Status__c = '21';
            // update creditReview;
            Schema.DescribeFieldResult fieldResult = celsrm__Credit_Review__c.celsrm__Status__c.getDescribe();
            List<Schema.PicklistEntry> picklistValues = fieldResult.getPicklistValues();
            String label = '';
            for (Schema.PicklistEntry picklistValue : picklistValues) {
                if (picklistValue.getValue() == creditReview.celsrm__Status__c) {
                    label = picklistValue.getLabel();
                    break;
                }
            }
            if(creditReview.celsrm__Status__c != '10') {
            // if(creditReview.celsrm__Status__c == '22' || creditReview.celsrm__Status__c == '23' || creditReview.celsrm__Status__c == '24' || creditReview.celsrm__Status__c == '30' || creditReview.celsrm__Status__c == '40') {
                response.status = 'error';
                response.message = 'Credit Review\'s status is ' + label + '. Can\'t submit it for approval';
                return response;
            } else {
                Map<String, String> processReceivablesData = getProcessReceivablesData(creditReview.celsrm__Account__c);


                // Related Attachments
                List<Map<String, Object>> attachmentList = new List<Map<String, Object>>();
                if(includeAttachments == true) {
                    List<ContentDocumentLink> docLinks = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :creditReviewId];
                    List<File_MIME_Type__c> MIMETypes = [SELECT Id, Name, MIME_Type__c FROM File_MIME_Type__c];
                    Map<String, String> fileExtVsFileType = new Map<String, String> ();
                    if(MIMETypes.size() > 0) {
                        for(File_MIME_Type__c MIMEType : MIMETypes) {
                            fileExtVsFileType.put(MIMEType.Name, MIMEType.MIME_Type__c);
                        }
                    }
                    if(docLinks != null && docLinks.size() > 0) {
                        List<Id> contentDocIds = new List<Id>();
                        for (ContentDocumentLink docLink : docLinks) {
                            contentDocIds.add(docLink.ContentDocumentId);
                        }
                        List<ContentVersion> versions = [SELECT Title, VersionData, ContentSize, FileExtension, ContentDocumentId, FileType 
                                                        FROM ContentVersion 
                                                        WHERE ContentDocumentId IN :contentDocIds 
                                                        AND IsLatest = true];
                        if(versions != null && versions.size() > 0) {
                            for(ContentVersion version: versions)  {
                                Map<String, Object> attachmentMap = new Map<String, Object>();
                                attachmentMap.put('attachmentFileName', version.Title + '.' + version.FileExtension);
                                attachmentMap.put('attachmentFileType', fileExtVsFileType.containsKey(version.FileExtension) ? String.valueOf(fileExtVsFileType.get(version.FileExtension)): version.FileExtension); // Get ContentType from ContentDocument
                                attachmentMap.put('attachmentFileSize', String.valueOf(version.ContentSize));
                                attachmentMap.put('attachmentContent', EncodingUtil.base64Encode(version.VersionData));
                                attachmentList.add(attachmentMap);
                            }
                        }
                    }   
                }
                
                HttpRequest req = new HttpRequest();
                // req.setEndpoint('https://qa-cam-api.cloud.akzonobel.global/onehub-integration/credit-limit-request');
                String apiUrl = '/onehub-integration/credit-limit-request';
                req.setEndpoint('callout:AppAppIntegration'+apiUrl);
                req.setMethod('POST');
                req.setHeader('Content-Type', 'application/json');

                Map<String,Object> requestMap = new Map<String,Object>();
                Map<String,Object> bodyMap = new Map<String,Object>();
                bodyMap.put('externalUuid', creditReview.Id);
                bodyMap.put('externalCaseId', creditReview.Name);
                bodyMap.put('statusCode', creditReview.celsrm__Status__c == '10' ? '21' : creditReview.celsrm__Status__c);
                bodyMap.put('createdBy', creditReview.CreatedBy.Name);

                User userRec = [SELECT Id, FederationIdentifier FROM User WHERE Id = :UserInfo.getUserId()];
                bodyMap.put('analystEmailAddress', userRec.FederationIdentifier);
                bodyMap.put('reasonCode', creditReview.celsrm__Model_Type__c);
                bodyMap.put('createdOn', creditReview.CreatedDate.format('yyyy-MM-dd HH:mm:ss'));
                bodyMap.put('statusDescription', label);
                bodyMap.put('creditSegment', creditReview.Credit_Segment_Akzo__c);
                bodyMap.put('currentCreditLimit', creditReview.Credit_Limit__c);
                bodyMap.put('riskClass', creditReview.celsrm__Risk_Class__c);
                bodyMap.put('creditExposure', creditReview.Credit_Exposure__c);
                bodyMap.put('expectedTurnover', creditReview.Expected_Turnover__c);
                bodyMap.put('securedAmount', creditReview.Secured_Amount__c);
                bodyMap.put('requestedCreditLimit', creditReview.celsrm__Requested_Credit_Limit__c);
                bodyMap.put('customerGroup', creditReview.celsrm__Credit_Group__c);
                bodyMap.put('creditLimitUtilizationPercentage', creditReview.celsrm__Account__r.Credit_Utilization_AkzoNobel__c);
                bodyMap.put('creditSegmentCurrency', creditReview.celsrm__Account__r.CurrencyIsoCode);
                bodyMap.put('paymentTermDays', creditReview.Payment_Terms_Days__c);
                bodyMap.put('requestedValidToDate', creditReview.Requested_Valid_To_Date__c);
                bodyMap.put('externalPartnerId', creditReview.celsrm__Account_Number__c );
                bodyMap.put('organizationName1', creditReview.celsrm__Account__r.Name);
                bodyMap.put('street', creditReview.celsrm__Account__r.BillingStreet);
                bodyMap.put('postCode', creditReview.celsrm__Account__r.BillingPostalCode);
                bodyMap.put('city', creditReview.celsrm__Account__r.BillingCity);
                bodyMap.put('region', creditReview.celsrm__Account__r.BillingState);
                bodyMap.put('country', creditReview.celsrm__Account__r.BillingCountry);
                bodyMap.put('telephoneNumber', ''); //TBR
                bodyMap.put('companyEmailAddress', ''); //TBR
                bodyMap.put('dueDates', processReceivablesData.get('dueDatesString'));
                bodyMap.put('commitments', processReceivablesData.get('amountsString'));
                bodyMap.put('currencyKeys', processReceivablesData.get('currenciesString'));
                bodyMap.put('starPeriod', '');  //TBR
                bodyMap.put('starRating', '');  //TBR
                bodyMap.put('starTrend', '');   //TBR
                // bodyMap.put('SYSTEM_NAME', 'CFIN');
                bodyMap.put('zzbvdAmt', creditReview.Moody_s_Credit_Limit__c);
                // bodyMap.put('idnumber', creditReview.BvD_ID_Number__c);
                bodyMap.put('source', 'sailfin');
                bodyMap.put('creditSegmentCode', creditReview.Credit_Segment_Akzo__c);
                bodyMap.put('approvedCreditLimit', creditReview.celsrm__Requested_Credit_Limit__c);
                Map<String, Object> attachments = new Map<String, Object>();
                attachments.put('attachment', attachmentList);
                bodyMap.put('attachments', attachments);
                // String notes = creditReview.celsrm__Notes__c == null ? '' : '#Description    ' + UserInfo.getUserEmail() + '    ' + String.valueOf(Datetime.now()) + '    #' + creditReview.celsrm__Notes__c.replaceAll('\r\n', '#');
                String notes = creditReview.celsrm__Notes__c == null ? '' : creditReview.celsrm__Notes__c;
                bodyMap.put('notes', notes);
                System.debug('notes:' + notes);
                requestMap.put('data', bodyMap);
                // System.debug('bodyMap>>' + bodyMap);
                System.debug(' - Heap Size: ' + (Limits.getHeapSize() / 1048576.0) + ' MB / ' + 
                     (Limits.getLimitHeapSize() / 1048576.0) + ' MB');
                if (Limits.getHeapSize() - (1048576.0 * 4.3) > Limits.getLimitHeapSize()) {
                    response.status = 'warning';
                    response.message = 'The attachment(s) are too large and exceed the heap size limit of ' + String.valueOf((Limits.getLimitHeapSize() / 1048576.0).setScale(2)) + ' MB. Would you like to proceed sending this request to the App. App. without the attachment(s)?';
                    return response;
                } else {
                    String requestBody = JSON.serialize(requestMap);
                    System.debug(' - Heap Size: ' + (Limits.getHeapSize() / 1048576.0) + ' MB / ' + 
                     (Limits.getLimitHeapSize() / 1048576.0) + ' MB');
                    // System.debug('requestBody>>>' + requestBody);
                    req.setBody(requestBody);
                    Http http = new Http();
                    HttpResponse res = http.send(req);
                    System.debug('res.getStatusCode()>>>' + res.getStatusCode());
                    System.debug('res>>>' + res);
                    if (res.getStatusCode() == 201) {
                        if (Schema.sObjectType.celsrm__Credit_Review__c.isUpdateable()) {
                            creditReview.Approval_Submitted_At__c = DateTime.now();
                            creditReview.Approval_Submitted_By__c = UserInfo.getUserId();
                            if(creditReview.celsrm__Status__c == '10') {
                                creditReview.celsrm__Status__c = '21';
                            }
                            update creditReview;
                            response.status = 'success';
                            response.message = creditReview.Name + ' submitted for approval successfully';
                        } else {
                            response.status = 'error';
                            response.message = creditReview.Name + ' submitted for approval successfully. But failed to update Credit Review Record';
                        }
                        return response;
                    } else if(res.getStatusCode() == 422) {
                        String responseBody = res.getBody();
                        // System.debug(responseBody);
                        List<Object> parsedResponse = (List<Object>) JSON.deserializeUntyped(responseBody);
                        if (parsedResponse.size() > 0) {
                            Map<String, Object> responseItem = (Map<String, Object>) parsedResponse[0];
                            String message = (String) responseItem.get('msg');
                            response.status = 'error';
                            response.message = message;
                            return response;
                        } else {
                            response.status = 'error';
                            response.message = creditReview.Name + ' can\'t submit for approval';
                            return response;
                        }
                    } else {
                        response.status = 'error';
                        response.message = creditReview.Name + ' failed to submit for approval';
                        return response;
                    }
                }
            }
        } catch(exception e){
            response.status = 'error';
            response.message = e.getMessage();
        }
        
        return response;
    }

    public static Map<String, String> getProcessReceivablesData(String accountId) {
        Map<String, String> returnVal = new Map<String, String>();
        List<celsrm__Transaction__c> openTransactions = [SELECT Id, celsrm__Due_Date__c, celsrm__Amount__c , CurrencyIsoCode, celsrm__Close_Date__c FROM celsrm__Transaction__c WHERE celsrm__Account__c = :accountId AND celsrm__Close_Date__c = null];
        List<String> dueDates = new List<String>();
        List<String> amounts = new List<String>();
        List<String> currencies = new List<String>();
        if(openTransactions != null && openTransactions.size() > 0) {
            for(celsrm__Transaction__c trans: openTransactions) {
                if(trans.celsrm__Due_Date__c != null) {
                    Date dueDate = trans.celsrm__Due_Date__c;
                    DateTime dueDateTime = DateTime.newInstance(dueDate.year(), dueDate.month(), dueDate.day());
                    String formattedDueDate = dueDateTime.format('yyyyMMdd') + '000000';
                    dueDates.add(formattedDueDate);
                }
                Decimal amount = trans.celsrm__Amount__c == null ? 0.0 : trans.celsrm__Amount__c;
                Decimal formattedAmountDecimal = amount.setScale(4);
                String formattedAmount = '';
                if(formattedAmountDecimal < 0) {
                    formattedAmount = String.valueOf(formattedAmountDecimal * -1) + '-';
                } else {
                    formattedAmount = String.valueOf(formattedAmountDecimal);
                }
                // String formattedAmount = String.valueOf(formattedAmountDecimal);
                amounts.add(formattedAmount);
                currencies.add(trans.CurrencyIsoCode);
            }
        }
        String dueDatesString = '';
        String amountsString = '';
        String currenciesString = '';
        if(dueDates.size() > 0){
            dueDatesString = String.join(dueDates, ' #') + ' #';
            System.debug('dueDatesString:' + dueDatesString);
        }
        if(amounts.size() > 0){
            amountsString = String.join(amounts, ' #') + ' #';
            System.debug('amountsString:' + amountsString);
        }
        if(currencies.size() > 0){
            currenciesString = String.join(currencies, ' #') + ' #';
            System.debug('currenciesString:' + currenciesString);
        }

        returnVal.put('dueDatesString', dueDatesString);
        returnVal.put('amountsString', amountsString);
        returnVal.put('currenciesString', currenciesString);
        return returnVal;
    }
}