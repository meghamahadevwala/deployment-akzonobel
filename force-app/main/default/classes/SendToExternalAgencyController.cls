public with sharing class SendToExternalAgencyController {

    @AuraEnabled
    public static String sendToAgency(Id recordId) {
        try {
            // TODO: once we have the API doc, the HTTP POST goes here
            //
            // HttpRequest req = new HttpRequest();
            // req.setEndpoint('callout:NamedCredentialName/endpoint');
            // req.setMethod('POST');
            // req.setHeader('Content-Type', 'application/json');
            // req.setBody(JSON.serialize(payload));
            //
            // Http http = new Http();
            // HttpResponse res = http.send(req);
            //
            // if (res.getStatusCode() != 200) {
            //     throw new AuraHandledException('Agency error: ' + res.getBody());
            // }

            return 'OK';
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}