public with sharing class DunningProcessingBatch implements Database.Batchable<SObject> {

    private String region;
    private String treatmentName;

    public DunningProcessingBatch(String region, String treatmentName) {
        this.region = region;
        this.treatmentName = treatmentName;
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, celsrm__DPD__c, Invoice_Dunning_Level__c
            FROM celsrm__Transaction__c
            WHERE celsrm__Close_Date__c = NULL
              AND celsrm__Dunning_Block__c NOT IN ('A', 'B')
              AND celsrm__Account__r.Region__c = :region
              AND celsrm__Due_Date__c < TODAY
              AND Sender_Document_Number__c = '9994891242'
        ]);
    }

    public void execute(Database.BatchableContext bc, List<celsrm__Transaction__c> scope) {
        List<celsrm__Transaction__c> toUpdate = new List<celsrm__Transaction__c>();

        for (celsrm__Transaction__c tx : scope) {
            Decimal newLevel = calculateLevel(tx.celsrm__DPD__c);

            if (tx.Invoice_Dunning_Level__c != newLevel) {
                toUpdate.add(new celsrm__Transaction__c(
                    Id = tx.Id,
                    Invoice_Dunning_Level__c = newLevel
                ));
            }
        }

        if (!toUpdate.isEmpty()) {
            update toUpdate;
        }
    }

    public void finish(Database.BatchableContext bc) {
        Database.executeBatch(
            new cCreateTreatmentTaskService(treatmentName),
            1
        );
    }

    private static Decimal calculateLevel(Decimal dpd) {
        if (dpd == null) return 0;
        if (dpd <= 3)   return 0;
        if (dpd <= 17)  return 1;
        if (dpd <= 31)  return 2;
        if (dpd <= 45)  return 3;
        return 4;
    }
}