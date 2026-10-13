/**
 * Batch class to calculate RUR, RAR, CAR, and DEI metrics for transactions
 * and store the mean DEI in Account records.
 * 
 * Metrics calculated:
 * - RUR (Reminders Utilisation Ratio): weightage = 0.75
 * - RAR (Reminders Alignment Ratio): weightage = 0.1
 * - CAR (Closeness Alignment Ratio): weightage = 0.5
 * - DEI (weighted sum of RUR, RAR, CAR) at transaction level
 */
public class TransactionMetricsBatch implements Database.Batchable<sObject>, Database.Stateful {
    
    private Id accountId;
    
    // Maps to store metric values by Account for aggregation
    private Map<Id, List<Decimal>> accountDEIMap = new Map<Id, List<Decimal>>();
    private Map<Id, List<Decimal>> accountRURMap = new Map<Id, List<Decimal>>();
    private Map<Id, List<Decimal>> accountRARMap = new Map<Id, List<Decimal>>();
    private Map<Id, List<Decimal>> accountCARMap = new Map<Id, List<Decimal>>();
    private Map<Id, List<Decimal>> accountPRURMap = new Map<Id, List<Decimal>>();
    private Map<Id, List<Decimal>> accountPRARMap = new Map<Id, List<Decimal>>();
    // maps to store average values by account for gen AI description
    private Map<Id, List<Decimal>> accountAvgNumOfRemindersMap = new Map<Id, List<Decimal>>();
    private Map<Id, List<Decimal>> accountAvgDaysBetweenRemindersMap = new Map<Id, List<Decimal>>();
    private Map<Id, List<Decimal>> accountAvgDaysToCloseMap = new Map<Id, List<Decimal>>();
    private Map<Id, List<Decimal>> accountAvgNumOfPreRemindersMap = new Map<Id, List<Decimal>>();
    private Map<Id, List<Decimal>> accountAvgDaysToDueMap = new Map<Id, List<Decimal>>();

    // NEW MAPS FOR EXPECTED FIELDS
    private Map<Id, List<Decimal>> accountAvgExpectedRemindersMap = new Map<Id, List<Decimal>>();
    private Map<Id, List<Decimal>> accountAvgExpectedDaysGapMap = new Map<Id, List<Decimal>>();
    private Map<Id, List<Decimal>> accountAvgExpectedCloseGapMap = new Map<Id, List<Decimal>>();
    private Map<Id, List<Decimal>> accountAvgExpectedPreDueCountMap = new Map<Id, List<Decimal>>();
    private Map<Id, List<Decimal>> accountAvgExpectedPreDueGapMap = new Map<Id, List<Decimal>>();
    
    // Configuration values (can be moved to custom settings)
    private static final Decimal RUR_WEIGHTAGE = 0.75;
    private static final Decimal RAR_WEIGHTAGE = 0.01;
    private static final Decimal CAR_WEIGHTAGE = 0.005;
    private static final Decimal PRUR_WEIGHTAGE = 0.005;
    private static final Decimal PRAR_WEIGHTAGE = 0.005;

    /** File title for versioned dunning efficiency snapshot attached to Account. Query ContentVersion by VersionNumber for history. */
    private static final String DUNNING_EFFICIENCY_FILE_TITLE = 'Dunning Efficiency Metrics';
    private static final String DUNNING_EFFICIENCY_FILE_PATH = 'DunningEfficiencyMetrics.json';

    
    public TransactionMetricsBatch(Id accountId) {
        this.accountId = accountId;
    }
    
    public TransactionMetricsBatch() {
        this(null);
    }
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        // Calculate date 6 months ago
        Date sixMonthsAgo = Date.today().addMonths(-6);
        
        String query = 'SELECT Id, celsrm__Account__c, celsrm__Amount__c, ' +
                      'celsrm__Posting_Key__c, celsrm__Status__c, ' +
                      'celsrm__Close_Date__c, Number_Of_Reminders__c, Last_Reminder_Date__c, Gaps_Between_Reminders__c, ' +
                      'Number_Of_Pre_Due_Reminders__c, Last_Pre_Due_Reminder_Date__c, ' +
                      'celsrm__Due_Date__c, celsrm__DPD__c ' +
                      'FROM celsrm__Transaction__c ' +
                      'WHERE celsrm__Amount__c > 100 ' +
                      'AND celsrm__Status__c = \'Closed\' ' +
                      'AND celsrm__Create_Date__c >= :sixMonthsAgo ' +
                      'AND celsrm__Posting_Key__c = \'01\'';
        
        if (accountId != null) {
            query += ' AND celsrm__Account__c = :accountId';
        }
        
        return Database.getQueryLocator(query);
    }
    
    /**
     * Execute method - processes each batch of transactions
     */
    public void execute(Database.BatchableContext bc, List<sObject> scope) {
        // Cast sObject list to celsrm__Transaction__c list
        List<celsrm__Transaction__c> transactions = (List<celsrm__Transaction__c>)scope;

        
        // Query all related reminder events for these transactions
        celsrm__AI_Configuration__c orgSetting = celsrm__AI_Configuration__c.getOrgDefaults();
        String reminderEventTypes = orgSetting.celsrm__Reminder_Event_Names__c != null && orgSetting.celsrm__Reminder_Event_Names__c != '' 
            ? orgSetting.celsrm__Reminder_Event_Names__c : 'send statement';
        // Ravi - Need to clarify: Ideal_Dpd_Adjusted_Reminder_Gap_Days__c is not mentioned in document.
        // Decimal expectedRemindersCount = orgSetting.Ideal_Dpd_Adjusted_Reminder_Gap_Days__c ?? 1;
        Decimal expectedRemindersCount = 1;
        Decimal expectedDaysGap = orgSetting.celsrm__Ideal_Days_Between_Reminders__c ?? 7;
        Decimal expectedCloseGap = orgSetting.celsrm__Ideal_Days_Last_Reminder_To_Close_Date__c ?? 5;
        Decimal expectedPreDueReminderCount = orgSetting.celsrm__Ideal_Reminder_Count_Before_Due_Date__c ?? 1;
        Decimal expectedPreDueReminderGap = orgSetting.celsrm__Ideal_Days_PreReminder_To_Due_Date__c ?? 7;    
        Decimal minDpdForDunning = orgSetting.celsrm__Min_DPD_For_Dunning__c ?? 5;

        // Process each transaction and calculate metrics
        for (celsrm__Transaction__c txn : transactions) {
            // Calculate DPD if not already set
            Decimal dpd = txn.celsrm__DPD__c != null ? txn.celsrm__DPD__c : 0;
            Decimal normalizedDpd = dpd;
            if (dpd != null && dpd < minDpdForDunning) {
                normalizedDpd = 0;
            }
            Decimal normalisedExpectedReminders = Math.floor(normalizedDpd/expectedRemindersCount);
            Decimal deviation = 0.0001;
            
            Decimal num_of_reminders = txn.Number_Of_Reminders__c ?? 0;
            Decimal gaps_between_reminders = txn.Gaps_Between_Reminders__c ?? 0;
            Decimal actualCloseGap = 0;
            if (txn.celsrm__Close_Date__c != null && txn.Last_Reminder_Date__c != null) {
                // actualCloseGap = txn.celsrm__Close_Date__c.daysBetween(txn.Last_Reminder_Date__c);
                actualCloseGap = txn.Last_Reminder_Date__c.daysBetween(txn.celsrm__Close_Date__c);
            }
            Decimal number_of_pre_due_reminders = txn.Number_Of_Pre_Due_Reminders__c;
            Date last_pre_due_reminder_date = txn.Last_Pre_Due_Reminder_Date__c;
            // 1. Calculate RUR (Reminders Utilisation Ratio)
            Decimal rur = 0;
            if (normalisedExpectedReminders > 0) {
                
                rur = ((num_of_reminders - normalisedExpectedReminders) / (normalisedExpectedReminders + 1));
                if(rur > 1)rur=1;
                else if(rur < -1)rur= -1;
            }
            
            // 2. Calculate RAR (Reminders Alignment Ratio)
            Decimal rar = 0;
            Decimal expectedDaysGapRatio = gaps_between_reminders / expectedDaysGap;
            if ( expectedDaysGap > 0 && gaps_between_reminders > 0) {
                
                rar = 1 - expectedDaysGapRatio;

                if(num_of_reminders == 0 && normalizedDpd==0)rar=0;
                else if(num_of_reminders == 0 && normalizedDpd > 0)rar=-1;
                else rar = (1 - gaps_between_reminders)/(expectedDaysGap + deviation);

                if(rar > 1)rar = 1;
                else if(rar < -1) rar=-1;

            }

            // 3. Calculate CAR (Closeness Alignment Ratio)
            Decimal car = 0;
            if (txn.celsrm__Close_Date__c != null && txn.Last_Reminder_Date__c !=null && txn.celsrm__Close_Date__c >= txn.Last_Reminder_Date__c && expectedCloseGap > 0) {
                if(num_of_reminders == 0 && normalizedDpd==0)car=0;
                else if(num_of_reminders == 0 && normalizedDpd > 0)car=-1;
                else car = (1 - actualCloseGap)/(expectedCloseGap + deviation);

                if(car > 1)car = 1;
                else if(car < -1) car=-1;

            }
            
            Decimal prur = 0;
            Decimal expectedPreDueReminderCountRatio = normalizedDpd > 0 ? expectedPreDueReminderCount : 0;
            if(number_of_pre_due_reminders > 0 && expectedPreDueReminderCount > 0) {


                prur = (number_of_pre_due_reminders - expectedPreDueReminderCountRatio) / (expectedPreDueReminderCountRatio + 1);

                if(prur > 1)prur = 1;
                else if(prur < -1) prur=-1;
            }

            Decimal prar = 0;
            Date dueDate = txn.celsrm__Due_Date__c;
            Decimal daysToDue ;
            if(dueDate != null && last_pre_due_reminder_date != null){
                daysToDue = dueDate.daysBetween(last_pre_due_reminder_date);
            }
            if(last_pre_due_reminder_date != null && dueDate != null && expectedPreDueReminderGap > 0) {

                if(num_of_reminders == 0 && normalizedDpd==0)prar=0;
                else if(num_of_reminders == 0 && normalizedDpd > 3*minDpdForDunning)prar=-1;
                else prar = (1 - daysToDue) / (expectedPreDueReminderGap + deviation);

                if(prar > 1)prar = 1;
                else if(prar < -1) prar=-1;
            }
            // 4. Calculate DEI (weighted sum)
            Decimal dei = (RUR_WEIGHTAGE * rur) + (RAR_WEIGHTAGE * rar) + (CAR_WEIGHTAGE * car) + (PRUR_WEIGHTAGE * prur) + (PRAR_WEIGHTAGE * prar);
            System.debug('Log will start here');
            // System.debug('Txn : ' + txn.Id + 'DPD: ' + normalizedDpd + ', ExpectedReminder: ' + normalisedExpectedReminders + ', RAR: ' + rar + ', CAR:' + car + ', PRUR:' + prur + ', PRAR:' + prar);
            // System.debug('Txn : ' + txn.Id + 'DEI: ' + dei + ', RUR: ' + rur + ', RAR: ' + rar + ', CAR:' + car + ', PRUR:' + prur + ', PRAR:' + prar);
            System.debug('Txn : ' + txn.Id + ' DPD: ' + normalizedDpd );
            System.debug('Txn : ' + txn.Id + ' RUR: ' + rur + ' ExpectedReminder: ' + normalisedExpectedReminders + ' Num of Reminders: ' + num_of_reminders );
            System.debug('Txn : ' + txn.Id + ' RAR: ' + rar + ' ExpectedDaysGap: ' + expectedDaysGap + ' Gaps between reminders: ' + gaps_between_reminders + ' Num of Reminders: ' + num_of_reminders);
            System.debug('Txn : ' + txn.Id + ' CAR: ' + car + ' ExpectedCloseGap: ' + expectedCloseGap + ' ActualCloseGap: ' + actualCloseGap + ' Num of Reminders: ' + num_of_reminders);
            System.debug('Txn : ' + txn.Id + ' PRUR: ' + prur + ' ExpectedPreDueReminderCount: ' + expectedPreDueReminderCountRatio + ' Number of Pre Due Reminders: ' + number_of_pre_due_reminders + ' Num of Pre Due Reminders: ' + number_of_pre_due_reminders);
            System.debug('Txn : ' + txn.Id + ' PRAR: ' + prar + ' ExpectedPreDueReminderGap: ' + expectedPreDueReminderGap + ' Num of Pre Due Reminders: ' + number_of_pre_due_reminders);
            // Store DEI, RUR, RAR, CAR for account aggregation
            if (txn.celsrm__Account__c != null) {
                // Store DEI
                if (!accountDEIMap.containsKey(txn.celsrm__Account__c)) {
                    accountDEIMap.put(txn.celsrm__Account__c, new List<Decimal>());
                }
                accountDEIMap.get(txn.celsrm__Account__c).add(dei);
                
                // Store RUR
                if (!accountRURMap.containsKey(txn.celsrm__Account__c)) {
                    accountRURMap.put(txn.celsrm__Account__c, new List<Decimal>());
                }
                if(gaps_between_reminders != null && gaps_between_reminders > 0){
                    accountRURMap.get(txn.celsrm__Account__c).add(rur);
                }
                
                // Store RAR
                if (!accountRARMap.containsKey(txn.celsrm__Account__c)) {
                    accountRARMap.put(txn.celsrm__Account__c, new List<Decimal>());
                }
                accountRARMap.get(txn.celsrm__Account__c).add(rar);
                
                // Store CAR
                if (!accountCARMap.containsKey(txn.celsrm__Account__c)) {
                    accountCARMap.put(txn.celsrm__Account__c, new List<Decimal>());
                }
                if(actualCloseGap != null && actualCloseGap > 0){
                    if(car!=0)accountCARMap.get(txn.celsrm__Account__c).add(car);
                }
                
                // Store PRUR
                if (!accountPRURMap.containsKey(txn.celsrm__Account__c)) {
                    accountPRURMap.put(txn.celsrm__Account__c, new List<Decimal>());
                }
                accountPRURMap.get(txn.celsrm__Account__c).add(prur);
                
                // Store PRAR
                if (!accountPRARMap.containsKey(txn.celsrm__Account__c)) {
                    accountPRARMap.put(txn.celsrm__Account__c, new List<Decimal>());
                }
                if(daysToDue != null && daysToDue > 0){
                    accountPRARMap.get(txn.celsrm__Account__c).add(prar);
                }

                // store num of reminders
                if (!accountAvgNumOfRemindersMap.containsKey(txn.celsrm__Account__c)) {
                    accountAvgNumOfRemindersMap.put(txn.celsrm__Account__c, new List<Decimal>());
                }
                if(num_of_reminders != null && num_of_reminders > 0){
                    accountAvgNumOfRemindersMap.get(txn.celsrm__Account__c).add(num_of_reminders);
                }

                // store days between reminders
                if (!accountAvgDaysBetweenRemindersMap.containsKey(txn.celsrm__Account__c)) {
                    accountAvgDaysBetweenRemindersMap.put(txn.celsrm__Account__c, new List<Decimal>());
                }
                if(gaps_between_reminders != null && gaps_between_reminders > 0){
                    accountAvgDaysBetweenRemindersMap.get(txn.celsrm__Account__c).add(gaps_between_reminders);
                }

                // store days to close
                if (!accountAvgDaysToCloseMap.containsKey(txn.celsrm__Account__c)) {
                    accountAvgDaysToCloseMap.put(txn.celsrm__Account__c, new List<Decimal>());
                }
                if (txn.celsrm__Close_Date__c != null && txn.Last_Reminder_Date__c != null && actualCloseGap != null) {
                    accountAvgDaysToCloseMap.get(txn.celsrm__Account__c).add(actualCloseGap);
                }

                // store days to due
                if (!accountAvgDaysToDueMap.containsKey(txn.celsrm__Account__c)) {
                    accountAvgDaysToDueMap.put(txn.celsrm__Account__c, new List<Decimal>());
                }
                if (txn.celsrm__Due_Date__c != null && txn.Last_Pre_Due_Reminder_Date__c != null) {
                    Decimal dueReminderGap = txn.celsrm__Due_Date__c.daysBetween(txn.Last_Pre_Due_Reminder_Date__c);
                    accountAvgDaysToDueMap.get(txn.celsrm__Account__c).add(dueReminderGap);
                }

                // store days to payment
                if (!accountAvgNumOfPreRemindersMap.containsKey(txn.celsrm__Account__c)) {
                    accountAvgNumOfPreRemindersMap.put(txn.celsrm__Account__c, new List<Decimal>());
                }

                if(number_of_pre_due_reminders != null && number_of_pre_due_reminders > 0){
                    accountAvgNumOfPreRemindersMap.get(txn.celsrm__Account__c).add(number_of_pre_due_reminders);
                }
                Id accId = txn.celsrm__Account__c;
                initializeAndAdd(accountAvgExpectedRemindersMap, accId, normalisedExpectedReminders);
                initializeAndAdd(accountAvgExpectedDaysGapMap, accId, expectedDaysGap);
                initializeAndAdd(accountAvgExpectedCloseGapMap, accId, expectedCloseGap);
                initializeAndAdd(accountAvgExpectedPreDueCountMap, accId, expectedPreDueReminderCountRatio);
                initializeAndAdd(accountAvgExpectedPreDueGapMap, accId, expectedPreDueReminderGap);
                
            }
        }
    }
    
    /**
     * Finish method - aggregates DEI at account level and updates Account records
     */
    public void finish(Database.BatchableContext bc) {
        // Get all account IDs
        // Get all account IDs from all maps
        Set<Id> accountIds = new Set<Id>();
        accountIds.addAll(accountDEIMap.keySet());
        accountIds.addAll(accountRURMap.keySet());
        accountIds.addAll(accountRARMap.keySet());
        accountIds.addAll(accountCARMap.keySet());
        accountIds.addAll(accountPRURMap.keySet());
        accountIds.addAll(accountPRARMap.keySet());
        if (accountIds.isEmpty()) {
            System.debug('No accounts to update');
            return;
        }
        
                
        // Calculate mean DEI, RUR, RAR, CAR, PRAR, PRUR for each account

        List<Account> accountsToUpdate = new List<Account>();
        Map<Id, String> accountIdToPayload = new Map<Id, String>();

        DateTime nowDt = DateTime.now();
        for (Id accId : accountIds) {
            Account acc = new Account(Id = accId);

            Decimal dei = calculateMean(accountDEIMap.get(accId));
            Decimal rur = calculateMean(accountRURMap.get(accId));
            Decimal rar = calculateMean(accountRARMap.get(accId));
            Decimal car = calculateMean(accountCARMap.get(accId));
            Decimal prur = calculateMean(accountPRURMap.get(accId));
            Decimal prar = calculateMean(accountPRARMap.get(accId));

            acc.Dunning_Efficiency_Index__c = dei;
            acc.Reminder_Utilisation_Ratio__c = rur;
            acc.Reminder_Alignment_Ratio__c = rar;
            acc.Closeness_Alignment_Ratio__c = car;
            acc.Pre_Due_Reminder_Utilisation_Ratio__c = prur;
            acc.Pre_Due_Reminder_Alignment_Ratio__c = prar;
            // acc.Last_AI_Dunning_Insight_Date__c = nowDt;

            // store avg values in single json string
            Map<String, Object> dataMap = new Map<String, Object>();

            dataMap.put('avgNumOfReminders',  calculateMean(accountAvgNumOfRemindersMap.get(accId)));
            dataMap.put('avgDaysBetweenReminders',calculateMean(accountAvgDaysBetweenRemindersMap.get(accId)));
            dataMap.put('avgDaysToClose', calculateMean(accountAvgDaysToCloseMap.get(accId)) );
            dataMap.put('avgDaysToDue', calculateMean(accountAvgDaysToDueMap.get(accId)));
            dataMap.put('avgNumOfPreReminders', calculateMean(accountAvgNumOfPreRemindersMap.get(accId)));

            dataMap.put('avgExpectedReminders', calculateMean(accountAvgExpectedRemindersMap.get(accId)));
            dataMap.put('avgExpectedDaysGapRatio', calculateMean(accountAvgExpectedDaysGapMap.get(accId)));
            dataMap.put('avgExpectedCloseGap', calculateMean(accountAvgExpectedCloseGapMap.get(accId)));
            dataMap.put('avgExpectedPreDueReminderCountRatio', calculateMean(accountAvgExpectedPreDueCountMap.get(accId)));
            dataMap.put('avgExpectedPreDueReminderGap', calculateMean(accountAvgExpectedPreDueGapMap.get(accId)));

            acc.Dunning_Efficiency_Reasoning_Data__c = JSON.serialize(dataMap);

            accountsToUpdate.add(acc);

            // Build versioned file payload: SOQL ContentVersion by VersionNumber returns this snapshot
            Map<String, Object> filePayload = new Map<String, Object>();
            filePayload.put('lastUpdated', nowDt.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss\'Z\''));
            filePayload.put('accountId', String.valueOf(accId));
            filePayload.put('dunningEfficiencyIndex', dei);
            filePayload.put('reminderUtilisationRatio', rur);
            filePayload.put('reminderAlignmentRatio', rar);
            filePayload.put('closenessAlignmentRatio', car);
            filePayload.put('preDueReminderUtilisationRatio', prur);
            filePayload.put('preDueReminderAlignmentRatio', prar);
            filePayload.put('reasoningData', dataMap);
            accountIdToPayload.put(accId, JSON.serialize(filePayload));
        }

        if (!accountsToUpdate.isEmpty()) {
            update accountsToUpdate;
            System.debug('Updated ' + accountsToUpdate.size() + ' accounts with Mean DEI');
        }

        attachVersionedFileToAccounts(accountIds, accountIdToPayload);
    }

    /**
     * Create or update the versioned file per account. One file per account (Title = DUNNING_EFFICIENCY_FILE_TITLE).
     * Each run adds a new ContentVersion so querying by VersionNumber returns the correct snapshot.
     */
    private void attachVersionedFileToAccounts(Set<Id> accountIds, Map<Id, String> accountIdToPayload) {
        if (accountIds == null || accountIds.isEmpty() || accountIdToPayload == null || accountIdToPayload.isEmpty()) {
            return;
        }

        List<ContentDocumentLink> existingLinks = [
            SELECT ContentDocumentId, LinkedEntityId
            FROM ContentDocumentLink
            WHERE LinkedEntityId IN :accountIds
              AND ContentDocument.Title = :DUNNING_EFFICIENCY_FILE_TITLE
        ];

        Map<Id, Id> accountIdToContentDocumentId = new Map<Id, Id>();
        for (ContentDocumentLink cdl : existingLinks) {
            accountIdToContentDocumentId.put(cdl.LinkedEntityId, cdl.ContentDocumentId);
        }

        List<Id> accountIdList = new List<Id>();
        accountIdList.addAll(accountIds);
        accountIdList.sort();

        List<ContentVersion> cvsToInsert = new List<ContentVersion>();
        List<Integer> newDocIndices = new List<Integer>();

        for (Integer i = 0; i < accountIdList.size(); i++) {
            Id accId = accountIdList[i];
            String payload = accountIdToPayload.get(accId);
            if (String.isBlank(payload)) {
                continue;
            }

            ContentVersion cv = new ContentVersion();
            cv.Title = DUNNING_EFFICIENCY_FILE_TITLE;
            cv.PathOnClient = DUNNING_EFFICIENCY_FILE_PATH;
            cv.VersionData = Blob.valueOf(payload);
            cv.IsMajorVersion = true;

            Id existingDocId = accountIdToContentDocumentId.get(accId);
            if (existingDocId != null) {
                cv.ContentDocumentId = existingDocId;
            } else {
                newDocIndices.add(i);
            }
            cvsToInsert.add(cv);
        }

        if (cvsToInsert.isEmpty()) {
            return;
        }

        insert cvsToInsert;

        if (newDocIndices.isEmpty()) {
            return;
        }

        Map<Id, Id> cvIdToContentDocumentId = new Map<Id, Id>();
        for (ContentVersion cv : [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id IN :cvsToInsert]) {
            cvIdToContentDocumentId.put(cv.Id, cv.ContentDocumentId);
        }

        List<ContentDocumentLink> links = new List<ContentDocumentLink>();
        for (Integer idx : newDocIndices) {
            ContentVersion cv = cvsToInsert[idx];
            Id docId = cvIdToContentDocumentId.get(cv.Id);
            if (docId == null) {
                continue;
            }
            ContentDocumentLink cdl = new ContentDocumentLink();
            cdl.ContentDocumentId = docId;
            cdl.LinkedEntityId = accountIdList[idx];
            cdl.ShareType = 'V';
            cdl.Visibility = 'AllUsers';
            links.add(cdl);
        }

        if (!links.isEmpty()) {
            insert links;
            System.debug('Attached ' + links.size() + ' new Dunning Efficiency Metrics files to Accounts');
        }
    }

    private static Decimal calculateMean(List<Decimal> values) {
        if (values == null || values.isEmpty()) {
            return null;
        }
    
        Decimal sum = 0;
        Integer count = 0;
    
        for (Decimal val : values) {
            if (val == null) {
                continue;
            }
            sum += val;
            count++;
        }
    
        if (count == 0) {
            return null;
        }
    
        Decimal mean = sum / count;
        return mean.setScale(2);
    }

    // Helper to keep execute method clean
    private void initializeAndAdd(Map<Id, List<Decimal>> targetMap, Id accId, Decimal val) {
        if (!targetMap.containsKey(accId)) {
            targetMap.put(accId, new List<Decimal>());
        }
        targetMap.get(accId).add(val);
    }
    
}