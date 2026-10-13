public with sharing class MoodysRecordSetManager implements Queueable, Database.AllowsCallouts {
    private List<String> bvDIds;
    private Integer retryCount;

    public MoodysRecordSetManager(List<String> bvDIds, Integer retryCount) {
        this.bvDIds = bvDIds;
        this.retryCount = retryCount;
    }

    public void execute(QueueableContext context) {
        String jsonBody = createJsonBody(bvDIds);
        String recordsetName = Credit_Configuration__c.getOrgDefaults().Moody_s_Record_Set_Name__c;
        if(String.isNotBlank(recordsetName)) {
            Moody_s_Auth__c MoodysAuth = creditParamsHttpCalloutManager.getMoodysAccessToken();
            if (MoodysAuth == null || String.isBlank(MoodysAuth.Access_Token__c)) return;

            HttpRequest req = new HttpRequest();
            req.setHeader('Authorization', 'Bearer ' + MoodysAuth.Access_Token__c);
            req.setEndpoint('callout:Moodys_Integration/Companies/Store/RecordSets/Add/' + recordsetName);
            req.setMethod('PUT');
            req.setHeader('Content-Type', 'application/json');
            req.setBody(jsonBody);
            req.setTimeout(120000);

            Http http = new Http();
            try {
                HttpResponse res = http.send(req);
                if (res.getStatusCode() == 200) {
                    System.debug('API call successful: ' + res.getBody());
                } else {
                    System.debug('API call failed: ' + res.getStatus() + ' - ' + res.getBody());
                    handleRetry();
                }
            } catch(System.CalloutException ex) {
                System.debug('CalloutException: ' + ex.getMessage());
                handleRetry();
            }

            upsert MoodysAuth;
        }
    }

    private void handleRetry() {
        if (retryCount < 3) {
            System.enqueueJob(new MoodysRecordSetManager(bvDIds, retryCount + 1));
        } else {
            System.debug('Max retry attempts reached for BvD IDs: ' + bvDIds);
        }
    }

    private static String createJsonBody(List<String> bvDIds) {
        String jsonBody = '{"WHERE": [{ "BvDID": ' + JSON.serialize(bvDIds) + '}]}';
        return jsonBody;
    }

    public static void enqueue(List<String> bvDIds) {
        System.enqueueJob(new MoodysRecordSetManager(bvDIds, 0));
    }
}