global with sharing class VoidCreditReviewController implements celsrm.GOGIScreenCustomLogic {

    global Map<Object, Object> invoke(String functionName, Map<Object, Object> inMap) {
        System.debug('into VoidCreditReviewController');
        System.debug('functionName ::: ' + functionName);
        if(functionName == 'onLoadVoidCreditReview') {
            inMap = loadVoidCreditReview(inMap);
        } else if(functionName == 'onSubmitVoidCreditReview') {
            inMap = voidCreditReview(inMap);
        }
        return inMap;
    }
    public class VoidCreditReviewResponse {
        //@AuraEnabled public String status;
        //@AuraEnabled public String message;
        public String status;
        public String message;
    }
    
    public static Map<Object, Object> loadVoidCreditReview(Map<Object, Object> inMap) {
        VoidCreditReviewResponse response = new VoidCreditReviewResponse();
        String creditReviewId = String.valueOf(inMap.get('Id'));
        celsrm__Credit_Review__c creditReview = [SELECT Id, Name, CreatedDate, CurrencyIsoCode, celsrm__Requested_Credit_Limit__c, celsrm__Account__c, celsrm__Account__r.AccountNumber, celsrm__Account__r.celsrm__Credit_Control_Area__c, celsrm__Account__r.celsrm__Company_Code__c, celsrm__Status__c, CreatedBy.Name, celsrm__Model_Type__c, Credit_Segment_Akzo__c, Credit_Limit__c, celsrm__Risk_Class__c, Credit_Exposure__c, Expected_Turnover__c, Secured_Amount__c, celsrm__Credit_Group__c, celsrm__Account__r.Credit_Utilization_AkzoNobel__c, celsrm__Account__r.CurrencyIsoCode, Payment_Terms_Days__c, celsrm__Account_Number__c, celsrm__Account__r.Name, celsrm__Account__r.BillingStreet, celsrm__Account__r.BillingPostalCode, celsrm__Account__r.BillingCity, celsrm__Account__r.BillingState, celsrm__Account__r.BillingCountry, Moody_s_Credit_Limit__c, Requested_Valid_To_Date__c, Approved_Valid_To_Date__c, celsrm__Notes__c FROM celsrm__Credit_Review__c WHERE Id = :creditReviewId];
        Schema.DescribeFieldResult fieldResult = celsrm__Credit_Review__c.celsrm__Status__c.getDescribe();
        List<Schema.PicklistEntry> picklistValues = fieldResult.getPicklistValues();
        List<String> approvedRejectedStatus = new List<String>{'11', '12', '24', '30', '40', '50'};
        String label = '';
        for (Schema.PicklistEntry picklistValue : picklistValues) {
            if (picklistValue.getValue() == creditReview.celsrm__Status__c) {
                label = picklistValue.getLabel();
                break;
            }
        }
        if(approvedRejectedStatus.contains(creditReview.celsrm__Status__c)) {
            response.status = 'error';
            response.message = 'Credit Review status is ' + label + '. You can\'t void it';
        } else {
            response.status = 'success';
    }
        inMap.put('resStatus', response.status);
        inMap.put('resMessage', response.message);
        return inMap;
    }
    //@AuraEnabled
    public static Map<Object, Object> voidCreditReview(Map<Object, Object> inMap) {
        String creditReviewId = String.valueOf(inMap.get('Id'));
        String voidReason = String.valueOf(inMap.get('VoidReason'));
        String voidStatus = '50';
        List<String> approvedRejectedStatus = new List<String>{'11', '12', '24', '30', '40', '50'};
        VoidCreditReviewResponse response = new VoidCreditReviewResponse();
        celsrm__Credit_Review__c creditReview = [SELECT Id, Name, celsrm__Status__c, Requested_Valid_To_Date__c FROM celsrm__Credit_Review__c WHERE Id = :creditReviewId];
        Schema.DescribeFieldResult fieldResult = celsrm__Credit_Review__c.celsrm__Status__c.getDescribe();
        List<Schema.PicklistEntry> picklistValues = fieldResult.getPicklistValues();
        String label = '';
        for (Schema.PicklistEntry picklistValue : picklistValues) {
            if (picklistValue.getValue() == creditReview.celsrm__Status__c) {
                label = picklistValue.getLabel();
                break;
            }
        }
        if(approvedRejectedStatus.contains(creditReview.celsrm__Status__c)) {
            response.status = 'error';
            response.message = 'Credit Review status is ' + label + '. You can\'t void it';
            
        } else if(creditReview.celsrm__Status__c == '10') { // If New (10), no need to update in App.App
            creditReview.Void_Reason__c = voidReason;
            creditReview.celsrm__Status__c = voidStatus;
            update creditReview;
            
            response.status = 'success';
            response.message = 'Successfully updated status to Void';
        } else {
            VoidCreditReviewResponse res = updateCLRStatus(creditReview.Name, Integer.valueOf(voidStatus));
            if(res.status == 'success') {
                creditReview.Void_Reason__c = voidReason;
                creditReview.celsrm__Status__c = voidStatus;
                update creditReview;
            } 
            response.status = res.status;
            response.message = res.message;
        }
        inMap.put('resStatus', response.status);
        inMap.put('resMessage', response.message);
        return inMap;
    }

    @AuraEnabled
    public static VoidCreditReviewResponse updateCLRStatus(String crName, Integer statusCode){
        VoidCreditReviewResponse response = new VoidCreditReviewResponse();
        try{
            Map<String,Object> requestMap = new Map<String,Object>();
            Map<String,Object> bodyMap = new Map<String,Object>();
            bodyMap.put('statusCode', statusCode);
            bodyMap.put('source', 'sailfin');
            requestMap.put('data', bodyMap);
            String requestBody = JSON.serialize(requestMap);
            HttpResponse res = VoidCreditReviewController.updateCLR(crName, requestBody);
            System.debug('res.getStatusCode()>>>' + res.getStatusCode());
            System.debug('res>>>' + res);
            if (res.getStatusCode() == 201) {
                if (Schema.sObjectType.celsrm__Credit_Review__c.isUpdateable()) {
                    //Update if any fields are required to update
                    response.status = 'success';
                    response.message = crName + ' status changes to Voided';
                } else {
                    response.status = 'error';
                    response.message = crName + ' status changes to Voided in App.App. But failed to update in Salesforce.';
                }
                return response;
            } else if(res.getStatusCode() == 422) {
                String responseBody = res.getBody();
                List<Object> parsedResponse = (List<Object>) JSON.deserializeUntyped(responseBody);
                if (parsedResponse.size() > 0) {
                    Map<String, Object> responseItem = (Map<String, Object>) parsedResponse[0];
                    String message = (String) responseItem.get('msg');
                    response.status = 'error';
                    response.message = message;
                    return response;
                } else {
                    response.status = 'error';
                    response.message = crName + ' failed to update in App.App.';
                    return response;
                }
            } else {
                response.status = 'error';
                response.message = crName + ' failed to update in App.App.';
                return response;
            }
        } catch(exception e){
            response.status = 'error';
            response.message = e.getMessage();
        }
        
        return response;
    }

    public static HttpResponse updateCLR(String crName, String jsonBody) {
        HttpRequest req = new HttpRequest();
        System.debug(jsonBody);
        // req.setEndpoint('https://qa-cam-api.cloud.akzonobel.global/onehub-integration/credit-limit-request');
        String apiUrl = '/onehub-integration/credit-limit-request/' + crName;
        req.setEndpoint('callout:AppAppIntegration'+apiUrl);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        //req.setHeader('Authorization', 'Basic YXBwQXBwVXNlcjpMZFZZQiQyUWJiVmVqcXFC');
        req.setBody(jsonBody);
        req.setMethod('PUT');
        Http http = new Http();
        HttpResponse res = http.send(req);
        System.debug('resBody::' + res.getBody());
        return res;
    }

}