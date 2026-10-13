public with sharing class RunClassificationManually implements Database.Batchable<SObject> {
    
    public RunClassificationManually() {
        
    }
    
    public Database.QueryLocator start(Database.BatchableContext BC) {
        String baseQuery = 'SELECT Id, FromName, FromAddress, ToAddress, CcAddress, BccAddress, Subject, CreatedDate,RelatedToId, TextBody, celsrm__Text_Body_1__c, celsrm__Text_Body_2__c, celsrm__Text_Body_3__c, celsrm__Text_Body_4__c, Htmlbody, celsrm__Html_Body__c, celsrm__Html_Body_2__c, celsrm__Html_Body_3__c, celsrm__Html_Body_4__c, celsrm__HasAttachment__c, celsrm__CategoryPlain__c  FROM EmailMessage WHERE celsrm__CategoryPlain__c = null and Incoming = true order by celsrm__created_date__c desc LIMIT 1';
        return Database.getQueryLocator(baseQuery);
    }
    
    public void execute(Database.BatchableContext BC, List<EmailMessage> emails) {
        if (!emails.isEmpty()) {
            celsrm.GOGCallPredictionAPI apiJob = new celsrm.GOGCallPredictionAPI(emails);
            System.enqueueJob(apiJob);
        }
    }
    
    public void finish(Database.BatchableContext BC) {
        // Optionally implement any post-processing logic here
    }
}