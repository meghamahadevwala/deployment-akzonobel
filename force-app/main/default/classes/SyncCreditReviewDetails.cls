@RestResource(urlmapping='/SyncCreditReviewDetails')
global class SyncCreditReviewDetails {
    @HttpPost
    global static void syncCreditReviews() {
        RestResponse res = RestContext.response;
        try {
            RestRequest req = RestContext.request;
            String requestBody = req.requestBody.toString();
            System.debug('requestBody::' + requestBody);
            CreditReviewRequest creditReviewRequest = (CreditReviewRequest) JSON.deserialize(requestBody, CreditReviewRequest.class);
            
            if(creditReviewRequest.externalUuid == null || creditReviewRequest.externalUuid == '') {
                res.statusCode = 400;
                res.responseBody = Blob.valueOf('externalUuid is missing!');
                return;
            }
            
            Id crId = (Id)creditReviewRequest.externalUuid;
            celsrm__Credit_Review__c creditReview = [SELECT Id, Attachments__c, Sales_Approval_Status__c, App_App_Notes__c, Finance_Approval_Status__c, celsrm__Approved_Credit_Limit__c, celsrm__Status__c, celsrm__Requested_Credit_Limit__c, Credit_Approved_Date__c, Requested_Valid_To_Date__c FROM celsrm__Credit_Review__c WHERE Id = :crId];
            if(creditReview == null) {
                res.statusCode = 400;
                res.responseBody = Blob.valueOf('Invalid externalUuid!');
                return;
            } else if (creditReviewRequest.statusCode == null) {
                res.statusCode = 400;
                res.responseBody = Blob.valueOf('statusCode is null or emplty!');
                return;
            } else {
                String status = String.valueOf(creditReviewRequest.statusCode);
                if(status == '24') {
                	creditReview.celsrm__Status__c = '40';
                } else {
                    creditReview.celsrm__Status__c = status;
                }
                creditReview.Attachments__c = creditReviewRequest.attachments == '' ? null : creditReviewRequest.attachments;
                
                // Show latest note + old note
                String oldNote = creditReview.App_App_Notes__c == null ? '' : creditReview.App_App_Notes__c;
                String latestNote = creditReviewRequest.notes == null ? '' : creditReviewRequest.notes; // + '\n\n'
                // Ignore starting #
                if(latestNote.startsWith('#')) {
                    latestNote = latestNote.substring(1);
                }
                // Ignore ending #
                if(latestNote.endsWith('#')) {
                    latestNote = latestNote.substring(0, latestNote.length() - 1);
                }
                // Replace in between # with new line
                latestNote = latestNote.replaceAll('#', '\n');
                creditReview.App_App_Notes__c   = (latestNote == '' ? '' : String.valueOf(Datetime.now()) + '\n' + latestNote + '\n\n') + oldNote;
                
                
                if(creditReviewRequest.requestedValidToDate != null) {
                    DateTime datetimeValue = DateTime.valueOf(creditReviewRequest.requestedValidToDate);
                    creditReview.Approved_Valid_To_Date__c = datetimeValue.date();
                }
                if(creditReview.celsrm__Status__c == '22' || creditReview.celsrm__Status__c == '23' || creditReview.celsrm__Status__c == '24' || creditReview.celsrm__Status__c == '40') {
                    creditReview.Credit_Approved_Date__c = Date.today();
                    creditReview.celsrm__Approved_Credit_Limit__c  = creditReviewRequest.approvedCreditLimit == null ? 0.0 : creditReviewRequest.approvedCreditLimit;
                    if (creditReview.Approved_Valid_To_Date__c == null) {
                        creditReview.Approved_Valid_To_Date__c = creditReview.Requested_Valid_To_Date__c;
                    }
                }
                update creditReview;
                
                if(creditReview.celsrm__Status__c == '40') {
                	List<String> crIds = new List<String>();
                    crIds.add(creditReview.Id);
                    if(!Test.isRunningTest()) {
                        UpdateLimitInSourceSystemService.updateCreditLimitInSAP(crIds);
                    }
            	}
                res.statusCode = 200;
                res.responseBody = Blob.valueOf('Credit Reviews updated successfully');
                return;
            }
        } catch (Exception e) {
            res.statusCode = 500;
            res.responseBody = Blob.valueOf('An error occurred: ' + e.getMessage());
            return;
        }
    }
    
    // Apex class to represent each credit review
    global class CreditReviewRequest {
        public String externalUuid;
        public String externalCaseId;
        public String attachments;
        public String notes;
        public Integer statusCode;
        public Integer approvalStatus1;
        public Integer approvalStatus2;
        public Double approvedCreditLimit;
        public String requestedValidToDate;
        public String SYSTEM_NAME;
    }
}