public with sharing class ProcessReceivablesDataQueueable implements Queueable, Database.AllowsCallouts{
    public String crId;

    public ProcessReceivablesDataQueueable(String crId) {
        this.crId = crId;
    }

    public void execute(QueueableContext context) {
        try {

            celsrm__Credit_Review__c creditReview = [SELECT Id, Name, CreatedDate, CurrencyIsoCode, celsrm__Requested_Credit_Limit__c, celsrm__Account__c, celsrm__Account__r.AccountNumber, celsrm__Account__r.celsrm__Credit_Control_Area__c, celsrm__Account__r.celsrm__Company_Code__c, celsrm__Status__c, CreatedBy.Name, celsrm__Model_Type__c, Credit_Segment_Akzo__c, Credit_Limit__c, celsrm__Risk_Class__c, Credit_Exposure__c, Expected_Turnover__c, Secured_Amount__c, celsrm__Credit_Group__c, celsrm__Account__r.Credit_Utilization_AkzoNobel__c, celsrm__Account__r.CurrencyIsoCode, Payment_Terms_Days__c, celsrm__Account_Number__c, celsrm__Account__r.Name, celsrm__Account__r.BillingStreet, celsrm__Account__r.BillingPostalCode, celsrm__Account__r.BillingCity, celsrm__Account__r.BillingState, celsrm__Account__r.BillingCountry, Moody_s_Credit_Limit__c, Requested_Valid_To_Date__c, celsrm__Notes__c FROM celsrm__Credit_Review__c WHERE Id = :crId];
            Schema.DescribeFieldResult fieldResult = celsrm__Credit_Review__c.celsrm__Status__c.getDescribe();
            List<Schema.PicklistEntry> picklistValues = fieldResult.getPicklistValues();
            String label = '';
            for (Schema.PicklistEntry picklistValue : picklistValues) {
                if (picklistValue.getValue() == creditReview.celsrm__Status__c) {
                    label = picklistValue.getLabel();
                    break;
                }
            }
            Map<String, String> processReceivablesData = SubmitForApprovalController.getProcessReceivablesData(creditReview.celsrm__Account__c);


            // Related Attachments
            List<Map<String, Object>> attachmentList = new List<Map<String, Object>>();
            List<ContentDocumentLink> docLinks = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :crId];
            List<File_MIME_Type__c> MIMETypes = [SELECT Id, Name, MIME_Type__c FROM File_MIME_Type__c];
            Map<String, String> fileExtVsFileType = new Map<String, String> ();
            if(MIMETypes.size() > 0) {
                for(File_MIME_Type__c MIMEType : MIMETypes) {
                    fileExtVsFileType.put(MIMEType.Name, MIMEType.MIME_Type__c);
                }
            }
            for (ContentDocumentLink docLink : docLinks) {
                List<ContentVersion> versions = [SELECT Title, VersionData, ContentSize, FileExtension, ContentDocumentId, FileType 
                                                FROM ContentVersion 
                                                WHERE ContentDocumentId = :docLink.ContentDocumentId 
                                                ORDER BY VersionNumber DESC 
                                                LIMIT 1];
                if (!versions.isEmpty()) {
                    ContentVersion version = versions[0];
                    Map<String, Object> attachmentMap = new Map<String, Object>();
                    attachmentMap.put('attachmentFileName', version.Title + '.' + version.FileExtension);
                    attachmentMap.put('attachmentFileType', fileExtVsFileType.containsKey(version.FileExtension) ? String.valueOf(fileExtVsFileType.get(version.FileExtension)): version.FileExtension); // Get ContentType from ContentDocument
                    attachmentMap.put('attachmentFileSize', String.valueOf(version.ContentSize));
                    attachmentMap.put('attachmentContent', EncodingUtil.base64Encode(version.VersionData));
                    attachmentList.add(attachmentMap);
                }
            }


            HttpRequest req = new HttpRequest();
            // req.setEndpoint('https://qa-cam-api.cloud.akzonobel.global/onehub-integration/credit-limit-request');
            String apiUrl = '/onehub-integration/credit-limit-request/' + creditReview.Name;
            req.setEndpoint('callout:AppAppIntegration'+apiUrl);
            req.setMethod('PUT');
            req.setHeader('Content-Type', 'application/json');

            Map<String,Object> requestMap = new Map<String,Object>();
            Map<String,Object> bodyMap = new Map<String,Object>();
            bodyMap.put('externalUuid', creditReview.Id);
            bodyMap.put('externalCaseId', creditReview.Name);
            bodyMap.put('statusCode', creditReview.celsrm__Status__c == '10' ? '21' : creditReview.celsrm__Status__c);
            bodyMap.put('createdBy', creditReview.CreatedBy.Name);
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
            System.debug('requestMap>>' + JSON.serialize(requestMap));


            // Map<String, String> processReceivablesData = SubmitForApprovalController.getProcessReceivablesData(creditReview.celsrm__Account__c);

            // Map<String,Object> requestMap = new Map<String,Object>();
            // Map<String,Object> bodyMap = new Map<String,Object>();
            // bodyMap.put('dueDates', processReceivablesData.get('dueDatesString'));
            // bodyMap.put('commitments', processReceivablesData.get('amountsString'));
            // bodyMap.put('currencyKeys', processReceivablesData.get('currenciesString'));
            // bodyMap.put('statusCode', creditReview.celsrm__Status__c);
            // bodyMap.put('source', 'sailfin');
            // requestMap.put('data', bodyMap);

            VoidCreditReviewController.updateCLR(creditReview.Name, JSON.serialize(requestMap));
        } catch (Exception e) {
            System.debug('Exception: ' + e.getMessage());
        }
    }

    public static void updateProcessReceivablesData(String crId) {
        System.enqueueJob(new ProcessReceivablesDataQueueable(crId));
    }
}