public with sharing class PaymentPredictionController {
    
    @AuraEnabled(cacheable=true)
    public static List<PredictionWrapper> getPredictions(Id accountId,Boolean isInvoiceListRequired) {
        try {
            Account acc = [SELECT Predicted_Payment_Dates_New__c FROM Account WHERE Id = :accountId LIMIT 1];
            String rawJson = acc.Predicted_Payment_Dates_New__c;

            if (String.isBlank(rawJson)) {
                return new List<PredictionWrapper>();
            }

            PredictionData parsedData;
            try {
                String cleanedJson = (String) JSON.deserialize(rawJson, String.class);
                parsedData = (PredictionData) JSON.deserialize(cleanedJson, PredictionData.class);            } catch (Exception e) {
            }

            if (parsedData == null || parsedData.data == null) {
                return new List<PredictionWrapper>();
            }

            List<Date> predictedDates = new List<Date>();
            Map<Date, PredictionWrapper> predictionMap = new Map<Date, PredictionWrapper>();

            // we will only show future dates -- uncomment below comments for same
            // Date today = Date.today();
            for (List<String> row : parsedData.data) {
                if (row.size() >= 3) {
                    String dateStr = String.valueOf(row[0]);
                    Date d = Date.valueOf(dateStr);
                    
                    // if (d < today) {
                    //     continue;
                    // }

                    Integer confidence = Integer.valueOf(row[1]);
                    String reasoning = String.valueOf(row[2]);

                    PredictionWrapper pw = new PredictionWrapper();
                    pw.predictionDate = d;
                    pw.confidence = confidence;
                    pw.reasoning = reasoning;
                    pw.invoices = new List<InvoiceWrapper>();
                    pw.invoiceCount = 0;
                    pw.totalAmount = 0;

                    predictionMap.put(d, pw);
                    predictedDates.add(d);
                }
            }

            // Fetch invoices (Transactions) for these dates
            List<celsrm__Transaction__c> txs = [
                SELECT Name, celsrm__Amount__c, celsrm__Due_Date__c, celsrm__Posting_Date__c, Expected_Payment_Date__c, celsrm__Balance__c,
                       Expected_Payment_Date_Confidence_Score__c, Expected_Payment_Date_Reasoning__c, celsrm__DPD__c, celsrm__Document_Type__c
                FROM celsrm__Transaction__c
                WHERE celsrm__Account__c = :accountId
                AND Expected_Payment_Date__c IN :predictedDates
                AND (celsrm__Status__c = 'Open' OR celsrm__Status__c = 'Partial')
            ];

            for (celsrm__Transaction__c tx : txs) {
                Date epd = tx.Expected_Payment_Date__c;
                if (predictionMap.containsKey(epd)) {
                    PredictionWrapper pw = predictionMap.get(epd);
                    pw.invoiceCount++;
                    pw.totalAmount += (tx.celsrm__Balance__c != null ? tx.celsrm__Balance__c : 0);
                    
                    InvoiceWrapper iw = new InvoiceWrapper();
                    iw.invNumber = tx.Name;
                    iw.invoiceDate = tx.celsrm__Posting_Date__c;
                    iw.dueDate = tx.celsrm__Due_Date__c;
                    iw.balance = tx.celsrm__Balance__c;
                    iw.confidence = tx.Expected_Payment_Date_Confidence_Score__c;
                    iw.reasoning = tx.Expected_Payment_Date_Reasoning__c;
                    iw.dpd = tx.celsrm__DPD__c;
                    iw.documentType = tx.celsrm__Document_Type__c;
                    if(isInvoiceListRequired){
                        pw.invoices.add(iw);
                    }
                }
            }

            return predictionMap.values();
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    public class PredictionData {
        public List<String> column;
        public List<List<String>> data;
    }

    public class PredictionWrapper {
        @AuraEnabled public Date predictionDate;
        @AuraEnabled public Integer confidence;
        @AuraEnabled public String reasoning;
        @AuraEnabled public Integer invoiceCount;
        @AuraEnabled public Decimal totalAmount;
        @AuraEnabled public List<InvoiceWrapper> invoices;
    }

    public class InvoiceWrapper {
        @AuraEnabled public String invNumber;
        @AuraEnabled public Date invoiceDate;
        @AuraEnabled public Date dueDate;
        @AuraEnabled public Decimal balance;
        @AuraEnabled public Decimal confidence;
        @AuraEnabled public String reasoning;
        @AuraEnabled public Decimal dpd;
        @AuraEnabled public String documentType;
    }
}