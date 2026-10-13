public with sharing class UpdateActualPaymentsReceivedBatch implements Database.Batchable<SObject>, Database.Stateful, Schedulable {
    private static final Integer BATCH_SIZE = 200;
    private Map<String, Decimal> currencyConversionMap;
    private List<String> documentTypes;

    public UpdateActualPaymentsReceivedBatch(List<String> documentTypes) {
        this.documentTypes = documentTypes;
    }
    
    public Database.QueryLocator start(Database.BatchableContext BC) {
        // Query Forecast records where Actual_Payment_Received__c is null, sorted by month and year in ascending order
        String query = 'SELECT Id, Month__c, Year__c ' +
                       'FROM Monthly_Forecast__c ' +
                       'WHERE Actual_Payment_Received__c = null ' +
                       'ORDER BY Year__c ASC, Month__c ASC';
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext BC, List<SObject> scope) {
        Map<Id, Decimal> forecastActualPayments = new Map<Id, Decimal>();
        Map<Id, Map<Id, Decimal>> forecastAccountPayments = new Map<Id, Map<Id, Decimal>>();
        Map<Id, Map<Id, Decimal>> forecastCollectorPayments = new Map<Id, Map<Id, Decimal>>();

        for (Monthly_Forecast__c forecast : (List<Monthly_Forecast__c>) scope) {
            Map<Id, Decimal> accountWisePayments = new Map<Id, Decimal>();
            Map<Id, Decimal> collectorWisePayments = new Map<Id, Decimal>();
            Integer forecastMonth = (Integer) forecast.Month__c;
            Integer forecastYear = (Integer) forecast.Year__c;

            // Query transactions for the specific month and year
            List<celsrm__Transaction__c> transactions = [
                SELECT Id, celsrm__Group_Balance__c, celsrm__Account__c, celsrm__Account__r.OwnerId 
                FROM celsrm__Transaction__c
                WHERE CALENDAR_MONTH(celsrm__Close_Date__c) = :forecastMonth
                AND CALENDAR_YEAR(celsrm__Close_Date__c) = :forecastYear
                AND celsrm__Document_Type__c IN :documentTypes 
                AND celsrm__Group_Balance__c != null 
                AND celsrm__Debit_Credit_Indicator__c = 'S'
                // AND Forecasting_Test_Txn__c = true
            ];

            Decimal overallBalanceSum = 0;
            for (celsrm__Transaction__c trxn : transactions) {
                overallBalanceSum += Math.abs(trxn.celsrm__Group_Balance__c);

                // Calculate account-wise sums
                if (trxn.celsrm__Account__c != null) {
                    if (!accountWisePayments.containsKey(trxn.celsrm__Account__c)) {
                        accountWisePayments.put(trxn.celsrm__Account__c, 0);
                    }
                    accountWisePayments.put(trxn.celsrm__Account__c, 
                                            accountWisePayments.get(trxn.celsrm__Account__c) + Math.abs(trxn.celsrm__Group_Balance__c));
                }

                if (trxn.celsrm__Account__r.OwnerId != null) {
                    if (!collectorWisePayments.containsKey(trxn.celsrm__Account__r.OwnerId)) {
                        collectorWisePayments.put(trxn.celsrm__Account__r.OwnerId, 0);
                    }
                    collectorWisePayments.put(trxn.celsrm__Account__r.OwnerId,
                        collectorWisePayments.get(trxn.celsrm__Account__r.OwnerId) + Math.abs(trxn.celsrm__Group_Balance__c));
                }
            }

            forecastActualPayments.put(forecast.Id, overallBalanceSum);
            forecastAccountPayments.put(forecast.Id, accountWisePayments);
            forecastCollectorPayments.put(forecast.Id, collectorWisePayments);
        }

        // Fetch all relevant accounts in one go
        Set<Id> accountIds = new Set<Id>();
        for (Map<Id, Decimal> accountMap : forecastAccountPayments.values()) {
            accountIds.addAll(accountMap.keySet());
        }
        Map<Id, Account> accountsInScope = new Map<Id, Account>([
            SELECT Id, Forecast_Period__c, CurrencyIsoCode
            FROM Account
            WHERE Id IN :accountIds
        ]);

        // Update accounts in smaller batches
        List<Account> accountsToUpdate = new List<Account>();
        for (Monthly_Forecast__c forecast : (List<Monthly_Forecast__c>) scope) {
            Map<Id, Decimal> accountPayments = forecastAccountPayments.get(forecast.Id);
            for (Id accountId : accountPayments.keySet()) {
                Account account = accountsInScope.get(accountId);
                if (account != null && account.Forecast_Period__c != null && forecast.Month__c == account.Forecast_Period__c.month() && forecast.Year__c == account.Forecast_Period__c.year()) {
                    Decimal accountSumInCorporateCurrency = accountPayments.get(accountId);
                    Decimal actualPaymentReceivedAmountInAccountCurrency = convertToAccountCurrency(accountSumInCorporateCurrency, account.CurrencyIsoCode);
                    
                    Account accountToUpdate = new Account(Id = accountId);
                    accountToUpdate.Actual_Payment_Received__c = actualPaymentReceivedAmountInAccountCurrency;
                    accountsToUpdate.add(accountToUpdate);
                    
                    // Process in batches of 200
                    if (accountsToUpdate.size() == BATCH_SIZE) {
                        update accountsToUpdate;
                        accountsToUpdate.clear();
                    }
                }
            }
        }
        // Final update for any remaining accounts
        if (!accountsToUpdate.isEmpty()) {
            update accountsToUpdate;
        }

        //update collector forecast
        System.debug('forecastCollectorPayments: '+ forecastCollectorPayments);
        Set<Id> forecastIds = forecastCollectorPayments.keySet();
        List<Collector_Target__c> collectorTargetsToUpdate = new List<Collector_Target__c>();

        // Iterate through each forecastId
        for (Id forecastId : forecastIds) {
            // Query scoped Collector_Target__c records for this forecastId
            List<Collector_Target__c> scopedCollectorTargets = [
                SELECT Id, Monthly_Forecast__c, Collector_User__c, Actual_Payment_Received__c
                FROM Collector_Target__c
                WHERE Monthly_Forecast__c = :forecastId
            ];
            System.debug('scopedCollectorTargets:: '+ scopedCollectorTargets);
            // Get the collectorPayments map for this forecastId
            Map<Id, Decimal> collectorPayments = forecastCollectorPayments.get(forecastId);

            // Iterate through scopedCollectorTargets and update payments if the OwnerId is present in collectorPayments
            for (Collector_Target__c target : scopedCollectorTargets) {
                if (collectorPayments.containsKey(target.Collector_User__c)) {
                    target.Actual_Payment_Received__c = collectorPayments.get(target.Collector_User__c);
                    collectorTargetsToUpdate.add(target);

                    // Update in batches
                    if (collectorTargetsToUpdate.size() == BATCH_SIZE) {
                        update collectorTargetsToUpdate;
                        collectorTargetsToUpdate.clear();
                    }
                }
            }
            // Final update for remaining records
            if (!collectorTargetsToUpdate.isEmpty()) {
                update collectorTargetsToUpdate;
                collectorTargetsToUpdate.clear();
            }
        }


        // Update Forecast records in smaller batches
        List<Monthly_Forecast__c> forecastsToUpdate = new List<Monthly_Forecast__c>();
        for (Monthly_Forecast__c forecast : (List<Monthly_Forecast__c>) scope) {
            forecast.Actual_Payment_Received__c = forecastActualPayments.get(forecast.Id);
            forecastsToUpdate.add(forecast);
            
            if (forecastsToUpdate.size() == BATCH_SIZE) {
                update forecastsToUpdate;
                forecastsToUpdate.clear();
            }
        }
        // Final update for any remaining forecasts
        if (!forecastsToUpdate.isEmpty()) {
            update forecastsToUpdate;
        }
    }

    public void finish(Database.BatchableContext BC) {
        // Optional: Logic to run after the batch completes, if needed
    }

    public void execute(SchedulableContext sc) {
        Database.executeBatch(new UpdateActualPaymentsReceivedBatch(documentTypes), 200);
    }

    // Convert to account currency
    public Decimal convertToAccountCurrency(Decimal amountInCorporateCurrency, String currencyIsoCode) {
        Decimal exchangeRate = getExchangeRate(currencyIsoCode);
        return amountInCorporateCurrency * exchangeRate;
    }

    // Fetch exchange rate
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
}