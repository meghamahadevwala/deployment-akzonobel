@RestResource(urlMapping='/executeNotSure/*')
global with sharing class AIActionNotSure {
    @HttpPost
    global static AIExecutorResponseWrapper executeEmailNotSure() {
        System.debug('From test class');
        AIExecutorResponseWrapper apiResponse = new AIExecutorResponseWrapper();
        System.debug('Before try executeCreateDispute');
        try {
            System.debug('Inside executeCreateDispute');
            RestRequest req = RestContext.request;
            String body = req.requestBody.toString();
            NotSureWrapper requestBody = (NotSureWrapper)JSON.deserialize(body, NotSureWrapper.class);
            if (requestBody.emailMessageId == null || requestBody.emailMessageId == '') {
                apiResponse.message = 'Email Message Id is required.';
                apiResponse.status = 'error';
            } else {
                EmailMessage message = [SELECT Id, celsrm__Agent_Status__c, celsrm__Agent_Failure_Response__c FROM EmailMessage WHERE Id = :requestBody.emailMessageId];
                message.celsrm__Agent_Failure_Response__c = requestBody.reason;
                message.celsrm__Agent_Status__c = 'Agent Not Sure';
                update message;
            }
        } catch (Exception e) {
            apiResponse.message = e.getMessage()+' | '+e.getStackTraceString();
            apiResponse.status = 'error';
        }
        return apiResponse;
    }

    //-- Wrapper Class --//
    global with sharing class AIExecutorResponseWrapper {
        global String status;
        global String message;
    }

    global with sharing class NotSureWrapper {
        public String emailMessageId;
        public String reason;
    }

}