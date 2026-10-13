public with sharing class MoodysDataMonitor implements Queueable, Database.AllowsCallouts{

    private Integer offset;

    public MoodysDataMonitor(Integer offset) {
        this.offset = offset;
    }

    public void execute(QueueableContext context) {
        try {
            // Prepare the HTTP request
            String recordsetName = Credit_Configuration__c.getOrgDefaults().Moody_s_Record_Set_Name__c;
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            String endPoint = '/companies/data';
            // String accessToken = creditParamsHttpCalloutManager.generateNewMoodysAccessToken();
            Moody_s_Auth__c MoodysAuth = creditParamsHttpCalloutManager.getMoodysAccessToken();
            String accessToken;
            if(MoodysAuth != null) {
                accessToken = MoodysAuth.Access_Token__c;
            }
            request.setHeader('Authorization', 'Bearer ' + accessToken);
            request.setEndpoint('callout:Moodys_Integration' + endPoint);
            request.setTimeout(120000);
            request.setMethod('POST');
            request.setHeader('Content-Type', 'application/json');
            
            Date startDate = Date.today().addDays(-7);
            Date endDate = Date.today();

            // Create the request body dynamically with the given offset
            String requestBody = JSON.serialize(new Map<String, Object>{
                'WHERE' => new Map<String, Object>{
                    'AND' => new List<Object>{
                        new Map<String, Object>{'RecordSet' => recordsetName},
                        new Map<String, Object>{
                            'UpdatedReport' => new Map<String, Object>{
                                'Period' => new Map<String, String>{'Start' => String.valueOf(startDate), 'End' => String.valueOf(endDate)},
                                'General' => new List<String>{'O', 'P', 'Q', 'R', '8'},
                                'FinancialStrength' => new List<String>{'MORERA', 'REACMORRAT', 'QSCORE'}
                            }
                        }
                    }
                },
                'SELECT' => new List<String>{'NAME', 'BVDID'},
                'RANGE' => new Map<String, Object>{'OFFSET' => offset, 'MAX' => 100}
            });
            
            request.setBody(requestBody);
            System.debug('requestBody>>' + requestBody);
            System.debug('requestEndPoint>>' + request.getEndpoint());
            System.debug('accessToken>>' + accessToken);
            HttpResponse response = http.send(request);
            upsert MoodysAuth;
            if (response.getStatusCode() == 200) {
                // Parse the response
                Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                Map<String, Object> searchSummary = (Map<String, Object>) responseMap.get('SearchSummary');
                Integer totalRecords = (Integer) searchSummary.get('TotalRecordsFound');
                Integer recordsReturned = (Integer) searchSummary.get('RecordsReturned');
                
                // Retrieve and process data
                if(responseMap.get('Data') != null) {
                    System.debug('responseMap.get(\'Data\')' + responseMap.get('Data'));
                    List<Object> data = (List<Object>) responseMap.get('Data');
                    processAccountUpdates(data, totalRecords, recordsReturned, offset);
                }
                // Calculate the next offset
                Integer newOffset = offset + recordsReturned;
                
                if (newOffset < totalRecords) {
                    System.enqueueJob(new MoodysDataMonitor(newOffset));
                }
            } else {
                System.debug('Failed request: ' + response.getBody());
            }
        } catch (Exception e) {
            System.debug('Error: ' + e.getMessage());
        }
    }

    private static void processAccountUpdates(List<Object> data, Integer totalRecords, Integer recordsReturned, Integer offset) {
        if (data == null || data.isEmpty()) {
            return;
        }
        List<String> bvdIds = new List<String>();
        for(Object detailObj: data) {
            Map<String, Object> detailMap = (Map<String, Object>) detailObj;
            String bvdId = detailMap.get('BVDID') == null ? null : (String)detailMap.get('BVDID');
            System.debug('bvdId::' + bvdId);
            if(bvdId != null) {
                bvdIds.add(bvdId);
            }
        }

        if(bvdIds.size() > 0) {
            List<Account> accounts = [SELECT Id, Name, CurrencyIsoCode, BvD_ID_Number__c, Moody_s_Change_Identified__c FROM Account WHERE BvD_ID_Number__c IN :bvdIds AND celsrm__Credit_Group__c NOT IN ('0004 - ALA - Legal Action', '0005 - EMP - Employee')];
            if(accounts.size() > 0) {
                for(Account acc: accounts) {
                    acc.Moody_s_Change_Identified__c = true;
                }
                update accounts;
            }
        }
    }
}