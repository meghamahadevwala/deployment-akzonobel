@RestResource(urlmapping='/fetchProcessReceivablesData')
global class ProcessReceivablesDataFetcher {
    @HttpPost
    global static void fetchProcessReceivablesData() {
        RestResponse res = RestContext.response;
        try {
            RestRequest req = RestContext.request;
            String requestBody = req.requestBody.toString();
            System.debug('requestBody::' + requestBody);
            ProcessReceivablesDataRequest processReceivablesDataRequest = (ProcessReceivablesDataRequest) JSON.deserialize(requestBody, ProcessReceivablesDataRequest.class);
            
            if(processReceivablesDataRequest.externalUuid == null || processReceivablesDataRequest.externalUuid == '') {
                res.statusCode = 400;
                res.responseBody = Blob.valueOf('externalUuid is missing!');
                return;
            }
            if(processReceivablesDataRequest.caseType != 'CLR') {
                res.statusCode = 400;
                res.responseBody = Blob.valueOf('caseType must be CLR!');
                return;
            }
            
            Id crId = (Id)processReceivablesDataRequest.externalUuid;
            ProcessReceivablesDataQueueable.updateProcessReceivablesData(crId);
            res.statusCode = 200;
            return;
        } catch (Exception e) {
            res.statusCode = 500;
            res.responseBody = Blob.valueOf('An error occurred: ' + e.getMessage());
            return;
        }
    }
    global class ProcessReceivablesDataRequest {
        public String externalUuid;	//Id
        public String externalCaseId;	//Name
        public String creditSegment;
        public String externalPartnerId;
        public String SYSTEM_NAME;
        public String caseType; //"CLR"
    }
}