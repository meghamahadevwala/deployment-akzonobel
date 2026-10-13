public with sharing class SyncDisputeWithCelonisService implements Queueable, Database.AllowsCallouts {

    @TestVisible private static Set<Id> pendingCreateIds = new Set<Id>();
    @TestVisible private static Set<Id> pendingUpdateIds = new Set<Id>();
    private static Boolean isEnqueued = false;

    private List<Id> createIds;
    private List<Id> updateIds;

    private static Integer MAX_RETRIES = 0;

    public SyncDisputeWithCelonisService(List<Id> createIds, List<Id> updateIds) {
        this.createIds = createIds;
        this.updateIds = updateIds;
    }

    public void execute(QueueableContext context) {

        processDisputes(createIds, 'CREATE');
        processDisputes(updateIds, 'UPDATE');

        isEnqueued = false;
    }

    private void processDisputes(List<Id> ids, String actionType){

        if(ids == null || ids.isEmpty()) return;

        List<celsrm__Dispute__c> disputes = [
            SELECT
                Id,
                Name,
                Company_Code__c,
                celsrm__Dispute_Type__c,
                celsrm__Reason_Code__c,
                I2C_Dispute_Processor__c,
                celsrm__Status__c,
                Expected_Closure_Date__c,
                celsrm__Transaction__c,
                celsrm__Transaction__r.Name,
                celsrm__Transaction__r.celsrm__Fiscal_Year__c,
                celsrm__Transaction__r.celsrm__Invoice_Line_No__c
            FROM celsrm__Dispute__c
            WHERE Id IN :ids
            AND celsrm__Account__r.celsrm__Account_Key__c LIKE 'CFIN%'
        ];

        if(disputes.isEmpty()) return;

        List<Map<String,Object>> payload = new List<Map<String,Object>>();

        for(celsrm__Dispute__c d : disputes){

            Map<String,Object> dispute = new Map<String,Object>();

            dispute.put('SailfinCaseID', d.Name);
            dispute.put('Category', d.celsrm__Dispute_Type__c);
            dispute.put('Reason', d.celsrm__Reason_Code__c);
            dispute.put('Processor', d.I2C_Dispute_Processor__c);
            dispute.put('Status', d.celsrm__Status__c);
            dispute.put('PlannedCloseDate', d.Expected_Closure_Date__c);
            dispute.put('CFINCompanyCode', d.Company_Code__c);

            if(d.celsrm__Transaction__r != null){

                dispute.put(
                    'InvoiceLineNumber',
                    d.celsrm__Transaction__r.celsrm__Invoice_Line_No__c
                );

                dispute.put(
                    'FiscalYear',
                    d.celsrm__Transaction__r.celsrm__Fiscal_Year__c
                );

                dispute.put(
                    'CFINDocNumber',
                    d.celsrm__Transaction__r.Name
                );
            }

            payload.add(dispute);
        }

        sendBatches(payload, actionType);
    }


    private void sendBatches(List<Map<String,Object>> payload, String actionType){

        Integer batchSize = 50;

        String webhookURL =
            Collection_Configuration__c.getOrgDefaults().Dispute_Sync_Webhook__c;

        Http http = new Http();

        for(Integer i = 0; i < payload.size(); i += batchSize){

            List<Map<String,Object>> batch = new List<Map<String,Object>>();

            for(Integer j = i; j < i + batchSize && j < payload.size(); j++){
                batch.add(payload[j]);
            }

            Map<String,Object> body = new Map<String,Object>{
                'disputes' => batch,
                'actionType' => actionType
            };

            HttpRequest req = new HttpRequest();

            req.setEndpoint('callout:CelonisEMS/' + webhookURL);
            req.setMethod('POST');
            req.setHeader('Content-Type','application/json');
            req.setTimeout(20000);
            req.setBody(JSON.serialize(body));

            sendWithRetry(http, req, 0);
        }
    }


    private void sendWithRetry(Http http, HttpRequest req, Integer attempt){

        try{

            HttpResponse res = http.send(req);

            if(res.getStatusCode() >= 300){

                if(attempt < MAX_RETRIES){

                    sendWithRetry(http, req, attempt + 1);

                }else{

                    System.debug('Celonis failed after retries: ' + res.getBody());
                }
            }

        }catch(Exception e){

            if(attempt < MAX_RETRIES){

                sendWithRetry(http, req, attempt + 1);

            }else{

                System.debug('Celonis exception: ' + e.getMessage());
            }
        }
    }


    public static void syncDisputes(List<Id> disputeIds, Boolean isCreate){

        if(disputeIds == null || disputeIds.isEmpty()) return;

        if(isCreate){
            pendingCreateIds.addAll(disputeIds);
        }
        else{
            pendingUpdateIds.addAll(disputeIds);
        }

        if(!isEnqueued){

            isEnqueued = true;

            System.enqueueJob(

                new SyncDisputeWithCelonisService(

                    new List<Id>(pendingCreateIds),
                    new List<Id>(pendingUpdateIds)

                )
            );
        }
    }
}