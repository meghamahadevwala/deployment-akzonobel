public with sharing class DailyCashMonitoringBatch implements Database.Batchable<SObject>, Schedulable {
    private List<String> documentTypes;
    private Date targetDate;
    private Map<String, Decimal> currencyConversionMap;

    public DailyCashMonitoringBatch() {
        this(null, null);
    }

    public DailyCashMonitoringBatch(Date inputDate) {
        this(inputDate, null);
    }

    public DailyCashMonitoringBatch(Date inputDate, List<String> documentTypes) {
        this.targetDate = inputDate == null ? Date.today() : inputDate;
        this.documentTypes = getDocumentTypesOrDefault(documentTypes);
        System.debug('Inside Constructor');
        System.debug('targetDate:: '+ this.targetDate);

    }

    public void execute(SchedulableContext sc) {
        Database.executeBatch(new DailyCashMonitoringBatch(null, documentTypes));
    }

    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        String query = 'SELECT Id FROM Cash_Monitoring__c WHERE Date__c = :targetDate LIMIT 1';
        return Database.getQueryLocator(query);
    }

    
    public void execute(Database.BatchableContext bc, List<Cash_Monitoring__c> scope) {
        if (scope.isEmpty()) {
            // If no record exists, abort the batch execution
            System.debug('No record found in Cash_Monitoring__c for the given date. Aborting batch execution.');
            return;
        }
        Decimal dailyReceipts = 0;
        Decimal cumulativeReceipts = 0;


        // Aggregate query to calculate daily receipts
        List<AggregateResult> dailyResults = [
            SELECT SUM(celsrm__Group_Balance__c) totalDaily
            FROM celsrm__Transaction__c
            WHERE celsrm__Close_Date__c = :targetDate
            AND celsrm__Document_Type__c IN :documentTypes 
            AND celsrm__Group_Balance__c != null 
            AND celsrm__Debit_Credit_Indicator__c = 'S'
            // AND Forecasting_Test_Txn__c = true
        ];
        System.debug('dailyResults:: '+ dailyResults);
        if (!dailyResults.isEmpty()) {
            dailyReceipts = (Decimal)dailyResults[0].get('totalDaily');
        } else {
            dailyReceipts = 0; // Or handle the case as needed
        }

        List<AggregateResult> cumulativeResults = [
            SELECT celsrm__Account__c accountId, SUM(celsrm__Group_Balance__c) totalCumulative
            FROM celsrm__Transaction__c
            WHERE CALENDAR_MONTH(celsrm__Close_Date__c) = :targetDate.month()
            AND CALENDAR_YEAR(celsrm__Close_Date__c) = :targetDate.year()
            AND celsrm__Close_Date__c <= :targetDate
            AND celsrm__Document_Type__c IN :documentTypes 
            AND celsrm__Group_Balance__c != null 
            AND celsrm__Debit_Credit_Indicator__c = 'S'
            // AND Forecasting_Test_Txn__c = true
            GROUP BY celsrm__Account__c
        ];

        Map<Id, Decimal> accountCumulativeRecieptMap = new Map<Id, Decimal>();
        Set<Id> uniqueAccountIds = new Set<Id>();

        System.debug('cumulativeResults:: '+ cumulativeResults);
        for (AggregateResult result : cumulativeResults) {
            Id accountId = (Id) result.get('accountId');
            Decimal totalCumulative = (Decimal) result.get('totalCumulative');
            
            accountCumulativeRecieptMap.put(accountId, totalCumulative);
            uniqueAccountIds.add(accountId);
            
            // Aggregate total cumulative receipts
            cumulativeReceipts += totalCumulative;
        }

        Map<Id, Account> validAccounts = new Map<Id, Account>();
        if (!uniqueAccountIds.isEmpty()) {
            List<Account> fetchedAccounts = [
                SELECT Id, Forecast_Period__c 
                FROM Account 
                WHERE Id IN :uniqueAccountIds
            ];
            
            for (Account acc : fetchedAccounts) {
                if (acc.Forecast_Period__c != null &&
                    acc.Forecast_Period__c.month() == targetDate.month() &&
                    acc.Forecast_Period__c.year() == targetDate.year()) {
                    validAccounts.put(acc.Id, acc);
                }
            }
        }

        // Query all accounts in validAccounts to get their CurrencyIsoCode
        Map<Id, String> accountCurrencyMap = new Map<Id, String>();
        for (Account acc : [SELECT Id, CurrencyIsoCode FROM Account WHERE Id IN :validAccounts.keySet()]) {
            accountCurrencyMap.put(acc.Id, acc.CurrencyIsoCode);
        }

        // If no results found, check for previous date
        if (cumulativeResults.isEmpty() && targetDate.day() != 1) {
            Date previousDate = targetDate.addDays(-1);
            List<Cash_Monitoring__c> cumulativeRec = [
                SELECT Cumulative_Receipt__c 
                FROM Cash_Monitoring__c 
                WHERE Date__c = :previousDate 
                LIMIT 1
            ];
            if (!cumulativeRec.isEmpty()) {
                cumulativeReceipts = (Decimal) cumulativeRec[0].get('Cumulative_Receipt__c');
            } else {
                cumulativeReceipts = 0;
            }
        } else if (cumulativeResults.isEmpty()) {
            cumulativeReceipts = 0;
        }

        // Update Cash_Monitoring__c record
        Cash_Monitoring__c cashMonitoringRecord = scope[0];
        cashMonitoringRecord.Daily_Receipts__c = dailyReceipts != null ? Math.abs(dailyReceipts) : 0;
        cashMonitoringRecord.Cumulative_Receipt__c = cumulativeReceipts != null ? Math.abs(cumulativeReceipts) : 0;
        // Update only accounts that match the forecast period condition
        List<Account> accountsToUpdate = new List<Account>();
        for (Id accountId : validAccounts.keySet()) {
            // Get the currency code for the current account
            String accountCurrency = accountCurrencyMap.get(accountId);
            accountsToUpdate.add(new Account(
                Id = accountId,
                Actual_Payment_Received__c = convertToAccountCurrency(accountCumulativeRecieptMap.get(accountId), accountCurrency) // Update field with sum
            ));
        }

        // Update accounts in chunks of 200
        if (!accountsToUpdate.isEmpty()) {
            Integer batchSize = 200;
            Integer totalSize = accountsToUpdate.size();

            for (Integer i = 0; i < totalSize; i += batchSize) {
                // Create a new batch list manually
                List<Account> batch = new List<Account>();

                // Manually select the sublist to avoid using subList method
                for (Integer j = i; j < Math.min(i + batchSize, totalSize); j++) {
                    batch.add(accountsToUpdate[j]);
                }

                // Perform the update
                Database.update(batch, false); // Allows partial success
            }
        }


        update cashMonitoringRecord;
    }



    // Finish method
    public void finish(Database.BatchableContext BC) {
        System.debug('Batch processing completed for date: ' + targetDate);
    }

    private Decimal convertToAccountCurrency(Decimal amountInCorporateCurrency, String currencyIsoCode) {
        Decimal exchangeRate = getExchangeRate(currencyIsoCode);
        return amountInCorporateCurrency * exchangeRate;
    }

    private Decimal getExchangeRate(String currencyIsoCode) {
        // Initialize the map if it is null
        if (currencyConversionMap == null) {
            // Query all conversion rates and populate the map
            currencyConversionMap = new Map<String, Decimal>();
            for (CurrencyType cur : [SELECT IsoCode, ConversionRate FROM CurrencyType]) {
                currencyConversionMap.put(cur.IsoCode, cur.ConversionRate != null ? cur.ConversionRate : 1.0);
            }
        }

        // Return the conversion rate from the map, defaulting to 1.0 if not found
        if (currencyConversionMap.containsKey(currencyIsoCode)) {
            return currencyConversionMap.get(currencyIsoCode);
        } else {
            System.debug('Currency not found in map for ISO Code: ' + currencyIsoCode);
            return 1.0;
        }
    }

    private static List<String> getDocumentTypesOrDefault(List<String> documentTypes) {
        if (documentTypes == null || documentTypes.isEmpty()) {
            return new List<String>{'RV','AB','DG','DR','DA'};
        }
        return new List<String>(documentTypes);
    }
}