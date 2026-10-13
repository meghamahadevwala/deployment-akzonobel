public with sharing class UpdateForecastBatch implements Database.Batchable<SObject>, Database.Stateful, Schedulable {
    private List<String> documentTypes;
    private Integer forecastMonth;
    private Integer forecastYear;
    private Date firstDayOfForecastMonth;
    private Date lastDayOfMonth;
    private Decimal cumulativeOverallSum = 0;  // Holds total sum across all batches in corporate currency
    private Decimal cumulativeOverallTotalAR = 0; // Holds total AR across all batches in corporate currency
    private Decimal cumulativeOverallCurrentAR = 0; // Holds current AR across all batches in corporate currency
    private Map<Id, Decimal> accountSumMap = new Map<Id, Decimal>();  // Holds account-wise sums in corporate currency
    private Map<Id, Decimal> ownerSumMap = new Map<Id, Decimal>();  // Holds owner-wise sums in corporate currency
    private Map<Date, Decimal> expectedPaymentDateTargetMap = new Map<Date, Decimal>();
    private Integer DSO;
    private Integer BPDSO;
    private Map<String, Decimal> currencyConversionMap;


    public UpdateForecastBatch(Integer month, Integer year, Integer DSO, Integer BPDSO) {
        this(month, year, DSO, BPDSO, null);
    }

    public UpdateForecastBatch(Integer month, Integer year, Integer DSO, Integer BPDSO, List<String> documentTypes) {
        this.forecastMonth = month;
        this.forecastYear = year;
        this.DSO = DSO;
        this.BPDSO = BPDSO;
        this.documentTypes = getDocumentTypesOrDefault(documentTypes);
        this.firstDayOfForecastMonth = Date.newInstance(year, month, 1);
        Integer numberOfDays = Date.daysInMonth(year, month);
		lastDayOfMonth = Date.newInstance(year, month, numberOfDays);
    }

    public Database.QueryLocator start(Database.BatchableContext BC) {
        // Query transactions with balances in corporate currency
        String query = 'SELECT Id, Forecast_Period__c, celsrm__Group_Balance__c, celsrm__Account__c, celsrm__Account__r.OwnerId, ' +
               'celsrm__Create_Date__c, celsrm__Due_Date__c, celsrm__Close_Date__c, celsrm__Document_Type__c, Expected_Payment_Date__c ' +
               'FROM celsrm__Transaction__c ' +
               'WHERE Expected_Payment_Date__c <= :lastDayOfMonth ' +
               'AND celsrm__Document_Type__c IN :documentTypes ' +
               'AND (celsrm__Close_Date__c = null OR celsrm__Close_Date__c > :firstDayOfForecastMonth) ' +
               'AND celsrm__Create_Date__c <= :firstDayOfForecastMonth ' +
               'AND celsrm__Group_Balance__c != null ' +
               'AND celsrm__Debit_Credit_Indicator__c = \'S\' ';
            //    'AND Forecasting_Test_Txn__c = true';
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext BC, List<SObject> scope) {
        List<celsrm__Transaction__c> transactionsToUpdate = new List<celsrm__Transaction__c>();
        // Calculate overall sum and account-wise sum for each transaction in corporate currency
        for (celsrm__Transaction__c trxn : (List<celsrm__Transaction__c>)scope) {
            // check if forecast is being initiated for future month or not, update forecast period on transactions only if forecast being done for current or past months
            if (forecastYear < System.today().year() ||  (forecastYear == System.today().year() && forecastMonth <= System.today().month())) {
                if(trxn.Forecast_Period__c == NULL || (trxn.Forecast_Period__c != NULL && trxn.Forecast_Period__c <= firstDayOfForecastMonth)){
                    celsrm__Transaction__c txnToUpdate = new celsrm__Transaction__c(
                        Id = trxn.Id,
                        Forecast_Period__c = firstDayOfForecastMonth
                    );
                    transactionsToUpdate.add(txnToUpdate);
                }
            }
            Decimal balanceInCorporateCurrency = Math.abs(trxn.celsrm__Group_Balance__c != null ? trxn.celsrm__Group_Balance__c : 0);
            
            cumulativeOverallSum += balanceInCorporateCurrency;

            if (trxn.celsrm__Account__c != null) {
                Id accountId = trxn.celsrm__Account__c;
                accountSumMap.put(accountId,
                    accountSumMap.get(accountId) != null ? accountSumMap.get(accountId) + balanceInCorporateCurrency : balanceInCorporateCurrency
                );
            }

            // Owner-level grouping
            if (trxn.celsrm__Account__r != null && trxn.celsrm__Account__r.OwnerId != null) {
                Id ownerId = trxn.celsrm__Account__r.OwnerId;
                ownerSumMap.put(ownerId,
                    ownerSumMap.get(ownerId) != null ? ownerSumMap.get(ownerId) + balanceInCorporateCurrency : balanceInCorporateCurrency
                );
            }

            // Expected Payment Date wise grouping, used for daily cumulative target calculation
            Date expectedPaymentDate = trxn.Expected_Payment_Date__c;
            expectedPaymentDateTargetMap.put(expectedPaymentDate,
                expectedPaymentDateTargetMap.get(expectedPaymentDate) != null ? expectedPaymentDateTargetMap.get(expectedPaymentDate) + balanceInCorporateCurrency : balanceInCorporateCurrency
            );
        }
        if(transactionsToUpdate.size() > 0){
            update transactionsToUpdate;
        }
    }

    public void finish(Database.BatchableContext BC) {
        
        // Construct the Name field value
        String forecastName = getForecastName(forecastYear, forecastMonth);

        // Get total days in the month
        Integer totalDays = getDaysInMonth(forecastYear, forecastMonth);

        // Query for existing forecast record for the specified month and year
        List<Monthly_Forecast__c> existingForecasts = [
            SELECT Id, Forecast_Amount__c, Total_AR__c, Current_AR__c
            FROM Monthly_Forecast__c
            WHERE Month__c = :forecastMonth AND Year__c = :forecastYear
            LIMIT 1
        ];

        Monthly_Forecast__c forecast;
        Boolean isNewForecast = existingForecasts.isEmpty();

        if (isNewForecast) {
            // No existing forecast, create a new one
            forecast = new Monthly_Forecast__c(
                Month__c = forecastMonth,
                Year__c = forecastYear
            );
        } else {
            // Update existing forecast
            forecast = existingForecasts[0];
        }
        forecast.Name = forecastName;
        forecast.Total_Days__c = totalDays;
        forecast.Forecast_Amount__c = cumulativeOverallSum;
        
        
		system.debug('firstDayOfForecastMonth:'+firstDayOfForecastMonth);
        List<AggregateResult> results = [
            SELECT SUM(celsrm__Group_Balance__c) totalAmount
            FROM celsrm__Transaction__c 
            WHERE (celsrm__Close_Date__c = NULL OR celsrm__Close_Date__c > :firstDayOfForecastMonth) 
            	AND celsrm__Document_Type__c IN :documentTypes 
            	AND celsrm__Create_Date__c <= :firstDayOfForecastMonth
                // AND Forecasting_Test_Txn__c = true
        ];
        
        // Loop through the results and populate the map
        for (AggregateResult ar : results) {
            cumulativeOverallTotalAR = (Decimal) ar.get('totalAmount');
        }
        forecast.Total_AR__c = cumulativeOverallTotalAR;
        
        List<AggregateResult> results2 = [
            SELECT SUM(celsrm__Group_Balance__c) totalAmount
            FROM celsrm__Transaction__c 
            WHERE (celsrm__Close_Date__c = NULL OR celsrm__Close_Date__c > :firstDayOfForecastMonth)
            	AND celsrm__Document_Type__c IN :documentTypes 
            	AND celsrm__Create_Date__c <= :firstDayOfForecastMonth
            	AND celsrm__DPD__c <= 0
                // AND Forecasting_Test_Txn__c = true
        ];
        
        // Loop through the results and populate the map
        for (AggregateResult ar : results2) {
            if(ar.get('totalAmount') != null){
            	cumulativeOverallCurrentAR = Math.abs((Decimal) ar.get('totalAmount'));
            }
        }
        forecast.Current_AR__c = cumulativeOverallCurrentAR;
        
        if(DSO == null || BPDSO == null){
            ForecastScreenNew forecastScreen = new ForecastScreenNew(documentTypes);
            Map<Object,Object> inMap = new Map<Object,Object>();
            inMap.put('Period', String.valueOf(forecastMonth)+'-'+String.valueOf(forecastYear));
            Map<Object,Object> result = forecastScreen.invoke('GetAverageDSO', inMap);
            DSO = Integer.valueOf(result.get('avgDSO'));
            BPDSO = Integer.valueOf(result.get('bpDSO'));
        } 
        forecast.DSO__c = DSO;
        forecast.BPDSO__c = BPDSO;
        
        // Insert or update the forecast record in corporate currency
        if (isNewForecast) {
            insert forecast;
        } else {
            update forecast;
        }

        Id forecastId = forecast.Id;

        //calculate day wise cumulative target for cash monitoring
        System.debug('expectedPaymentDateTargetMap:: ' + expectedPaymentDateTargetMap);
        
        List<Cash_Monitoring__c> cashMonitoringRecordsToUpdate = new List<Cash_Monitoring__c>();
        List<Cash_Monitoring__c> cashMonitoringRecordsToInsert = new List<Cash_Monitoring__c>();
        List<Cash_Monitoring__c> existingRecords = [SELECT Id, Date__c FROM Cash_Monitoring__c 
                                            WHERE Monthly_Forecast__c = :forecastId];
        for (Integer day = 1; day <= totalDays; day++) {
            Date currentDate = firstDayOfForecastMonth.addDays(day - 1);
            Boolean dateAlreadyExists = false;            
            Decimal cumulativeTarget = 0;
            // Iterate over the map's keys and calculate the sum
            for (Date expectedPaymentDate : expectedPaymentDateTargetMap.keySet()) {
                if (expectedPaymentDate <= currentDate) { // Check if the expectedPaymentDate is less than or equal to currentDate
                    cumulativeTarget += expectedPaymentDateTargetMap.get(expectedPaymentDate); // Add the value to the sum
                }
            }
            // Check if the currentDate exists in the Date__c column
            for (Cash_Monitoring__c record : existingRecords) {
                if (record.Date__c == currentDate) {
                    // If a matching record is found, mark it and break the loop
                    dateAlreadyExists = true;
                    record.Cumulative_Target__c = cumulativeTarget;
                    cashMonitoringRecordsToUpdate.add(record);
                    break;
                }
            }
            if(!dateAlreadyExists){
                Cash_Monitoring__c cashMonitoring = new Cash_Monitoring__c(
                    Monthly_Forecast__c = forecast.Id,
                    Date__c = currentDate,
                    Cumulative_Target__c = cumulativeTarget
                );
                cashMonitoringRecordsToInsert.add(cashMonitoring);
            }
        }

        if(!cashMonitoringRecordsToUpdate.isEmpty()){
            update cashMonitoringRecordsToUpdate; //update existing cash monitoring records for cumulative target
        }

        if(!cashMonitoringRecordsToInsert.isEmpty()){
            insert cashMonitoringRecordsToInsert; // insert existing cash monitoring records for cumulative target
        }

        // Calculate total AR for all accounts involved in corporate currency
        List<Id> accountIds = new List<Id>(accountSumMap.keySet());

        // Update Account records with account-specific sums in their local currency
        if (forecastYear < System.today().year() ||  (forecastYear == System.today().year() && forecastMonth <= System.today().month())) {
            List<Account> accountsToUpdate = new List<Account>();
            List<Account> eligibleAccounts = [
                SELECT Id, CurrencyIsoCode
                FROM Account
                WHERE Id IN :accountIds
                AND (
                    (Forecast_Period__c = NULL)
                    OR 
                    (Forecast_Period__c != NULL AND Forecast_Period__c <= :firstDayOfForecastMonth)
                )
            ];

            for (Account acc : eligibleAccounts) {
                Decimal forecastAmountInCorporateCurrency = accountSumMap.get(acc.Id);
                Decimal forecastAmountInAccountCurrency = convertToAccountCurrency(forecastAmountInCorporateCurrency, acc.CurrencyIsoCode);
                
                Account account = new Account(
                    Id = acc.Id,
                    Forecast_Period__c = firstDayOfForecastMonth,
                    Forecast_Amount__c = forecastAmountInAccountCurrency,
                    Actual_Payment_Received__c = null  // Clear Actual_Payment_Received__c for specified month/year
                );
                accountsToUpdate.add(account);
            }
            if (!accountsToUpdate.isEmpty()) {
                update accountsToUpdate;
            }
        }

        // Update Collector_Target__c for owner-wise sums
        if (!ownerSumMap.isEmpty()) {
            List<Collector_Target__c> collectorsToUpdate = new List<Collector_Target__c>();

            // Query existing Collector_Target__c records for the owners
            Map<Id, Collector_Target__c> existingCollectorMap = new Map<Id, Collector_Target__c>();
            List<Collector_Target__c> existingCollectors = [
                SELECT Id, Collector_User__c, Forecast_Amount__c, Monthly_Forecast__c
                FROM Collector_Target__c
                WHERE Monthly_Forecast__c = :forecastId
            ];
            for (Collector_Target__c collector : existingCollectors) {
                existingCollectorMap.put(collector.Collector_User__c, collector);
            }

            // Iterate over owner-wise sums
            for (Id ownerId : ownerSumMap.keySet()) {
                Decimal forecastAmount = ownerSumMap.get(ownerId);

                if (existingCollectorMap.containsKey(ownerId)) {
                    // Update existing record
                    Collector_Target__c existingCollector = existingCollectorMap.get(ownerId);
                    existingCollector.Forecast_Amount__c = forecastAmount;
                    collectorsToUpdate.add(existingCollector);
                } else {
                    // Insert new record
                    collectorsToUpdate.add(new Collector_Target__c(
                        Collector_User__c = ownerId,
                        Forecast_Amount__c = forecastAmount,
                        Monthly_Forecast__c = forecastId
                    ));
                }
            }

            if (!collectorsToUpdate.isEmpty()) {
                upsert collectorsToUpdate;
            }
        }

        //calculate cash monitoring for past months
        if (forecastYear < System.today().year() ||  (forecastYear == System.today().year() && forecastMonth < System.today().month())) {
            // Date firstDate = Date.newInstance(forecastYear, forecastMonth, 1);
            Date firstDayOfForecastMonth = Date.newInstance(forecastYear, forecastMonth, 1);
            Integer totalDaysInMonth = Date.daysInMonth(forecastYear, forecastMonth);
            for (Integer monitoringDay = 1; monitoringDay <= totalDaysInMonth; monitoringDay++) {
                // Date monitoringDate = firstDayOfForecastMonth.addDays(monitoringDay - 1);
                Date monitoringDate = firstDayOfForecastMonth.addDays(monitoringDay - 1);
                Database.executeBatch(new DailyCashMonitoringBatch(monitoringDate,documentTypes));
            }
        }
    }

    public void execute(SchedulableContext sc) {
        Database.executeBatch(new UpdateForecastBatch(forecastMonth, forecastYear, DSO, BPDSO, documentTypes), 200);
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

    private Integer getDaysInMonth(Integer year, Integer month) {
        Boolean isLeapYear = (Math.mod(year, 4) == 0 && Math.mod(year, 100) != 0) || (Math.mod(year, 400) == 0);
        switch on month {
            when 1, 3, 5, 7, 8, 10, 12 {
                return 31;
            }
            when 4, 6, 9, 11 {
                return 30;
            }
            when 2 {
                return isLeapYear ? 29 : 28;
            }
        }
        return 0;
    }

    private String getForecastName(Integer forecastYear, Integer forecastMonth) {
        String monthAbbreviation = '';
        switch on forecastMonth {
            when 1 { monthAbbreviation = 'Jan'; }
            when 2 { monthAbbreviation = 'Feb'; }
            when 3 { monthAbbreviation = 'Mar'; }
            when 4 { monthAbbreviation = 'Apr'; }
            when 5 { monthAbbreviation = 'May'; }
            when 6 { monthAbbreviation = 'Jun'; }
            when 7 { monthAbbreviation = 'Jul'; }
            when 8 { monthAbbreviation = 'Aug'; }
            when 9 { monthAbbreviation = 'Sep'; }
            when 10 { monthAbbreviation = 'Oct'; }
            when 11 { monthAbbreviation = 'Nov'; }
            when 12 { monthAbbreviation = 'Dec'; }
        }
        
        // Format the year to two digits
        String yearAbbreviation = String.valueOf(forecastYear).right(2);
        
        // Construct the Name field value
        String forecastName = monthAbbreviation + '-' + yearAbbreviation;

        return forecastName;
    }

    private static List<String> getDocumentTypesOrDefault(List<String> documentTypes) {
        if (documentTypes == null || documentTypes.isEmpty()) {
            return new List<String>{'RV','AB','DG','DR','DA'};
        }
        return new List<String>(documentTypes);
    }
}