public with sharing class DunningTransactionFiltering {
    @TestVisible private static Boolean testForceZeroScore = false;
    @TestVisible private static void setTestForceZeroScore(Boolean v) { testForceZeroScore = v; }

    // Internal structures to hold computed components and selection
    private class TxnDetail {
        public Id txnId;
        public Decimal scaledAmount;
        public Decimal scaledDPD;
        public Integer reminders;
        public Decimal reminderScore;
        public Decimal riskScore;
        public Decimal impact;
        public Decimal score;
        public Decimal contribution;
        public String dunningEligibilityReason; // New: Reason for eligibility/ineligibility
    }

    private class SelectionResult {
        public List<Id> selectedIds;
        public Map<Id, TxnDetail> detailsById;
        public Decimal totalTps;
        public Decimal nucleusP;
    }

    private static SelectionResult lastSelectionResult;

    // Configurable knobs for selection (used to parameterize nucleus and top-N)
    private static Integer configMaxN;
    private static Decimal configNucleusP;

    // Public result item for integration
    public class SelectedTxn {
        public Id transactionId;
        public String transactionName;
        public Decimal tps;
        public Long timeTakenMs;
        public String dunningEligibilityReason; // New: Reason for eligibility/ineligibility
        public SelectedTxn(Id transactionId, String transactionName, Decimal tps, Long timeTakenMs, String dunningEligibilityReason) {
            this.transactionId = transactionId;
            this.transactionName = transactionName;
            this.tps = tps;
            this.timeTakenMs = timeTakenMs;
            this.dunningEligibilityReason = dunningEligibilityReason;
        }
    }

    // Result wrapper for eligible transactions with query limit check
    public class EligibleTransactionResult {
        public Boolean queryLimitReached;
        public List<SelectedTxn> transactions;
        
        public EligibleTransactionResult(Boolean queryLimitReached, List<SelectedTxn> transactions) {
            this.queryLimitReached = queryLimitReached;
            this.transactions = (transactions == null) ? new List<SelectedTxn>() : transactions;
        }
    }

    // One-shot API: run computation and return selected transactions with TPS and time taken
    public List<SelectedTxn> computeSelectedTransactions(Account acc, Integer maxN, Decimal nucleusP) {
        Long startTime = System.currentTimeMillis();
        configMaxN = maxN;
        configNucleusP = nucleusP;
        Long endTime;
        try {
            processAccountTransactions(acc);
            List<SelectedTxn> out = new List<SelectedTxn>();
            endTime = System.currentTimeMillis();
            Long timeTaken = endTime - startTime;
            if (lastSelectionResult != null && lastSelectionResult.selectedIds != null) {
                for (Id tid : lastSelectionResult.selectedIds) {
                    Decimal tps = 0;
                    String reason = '';
                    if (lastSelectionResult.detailsById != null && lastSelectionResult.detailsById.containsKey(tid)) {
                        tps = lastSelectionResult.detailsById.get(tid).score;
                        reason = lastSelectionResult.detailsById.get(tid).dunningEligibilityReason;
                    }
                    out.add(new SelectedTxn(tid, null, tps, timeTaken, reason));
                }
            }
            System.debug('computeSelectedTransactions: total time taken = ' + (endTime - startTime) + ' ms');
            return out;
        } finally {
            configMaxN = null;
            configNucleusP = null;
        }
    }

    // Helper to compute risk score based on Account.AI_Dunning_Frequency__c	
    private Decimal computeRiskScoreFromDunningFrequency(Account acc) {
        Long startTime = System.currentTimeMillis();
        if (acc == null) {
            return 0;
        }
        Decimal frequency = 0;
        try {
            // Handle numeric or null
            if (acc.AI_Dunning_Frequency__c != null) {
                Object v = acc.AI_Dunning_Frequency__c;
                if (v instanceof Decimal) {
                    frequency = (Decimal)v;
                } else if (v instanceof Integer) {
                    frequency = Decimal.valueOf((Integer)v);
                } else {
                    frequency = Decimal.valueOf(String.valueOf(v));
                }
            }
        } catch (Exception ex) {
            // default frequency remains 0
        }

        // Map exact days to risk score
        // make configurable ranges instead of a static number -- custom metadata
        Decimal result = 0;
        if (frequency == 7) result = 0.75;
        else if (frequency == 14) result = 0.5;
        else if (frequency == 21) result = 0.25;
        else if (frequency == 28) result = 0;
        else result = 0; // default if no match

        Long endTime = System.currentTimeMillis();
        System.debug('computeRiskScoreFromDunningFrequency: time taken = ' + (endTime - startTime) + ' ms');
        return result;
    }

    /**
     * Returns the number of days from today to the nearest future date in the list parsed from futurePaymentDate.
     * If no valid future date is found, returns null.
     */
    public Integer daysToNextDunning(String futurePaymentDate) {
        if (String.isBlank(futurePaymentDate)) {
            return null;
        }
        List<Date> futureDates = UtilityController.parseDateListFromString(futurePaymentDate,'');
        if (futureDates == null || futureDates.isEmpty()) {
            return null;
        }
        Date today = Date.today();
        // Filter only dates that are strictly in the future (not today)
        List<Date> validFutureDates = new List<Date>();
        for (Date d : futureDates) {
            if (d != null && d > today) {
                validFutureDates.add(d);
            }
        }
        if (validFutureDates.isEmpty()) {
            return null;
        }
        // Sort the dates ascending
        validFutureDates.sort();
        Date nearest = validFutureDates[0];
        Integer daysBetween = today.daysBetween(nearest);
        // If daysBetween is negative or null, return null
        if (daysBetween == null || daysBetween < 0) {
            return null;
        }
        return daysBetween;
    }
    
    public void processAccountTransactions(Account acc) {
        Long startTime = System.currentTimeMillis();
        if (acc == null || acc.Id == null) {
            return;
        }

        String accId = acc.Id;
        
        Long t0 = System.currentTimeMillis();
        // Fetch specific attributes from the Account object
        Account accountDetails = [
            SELECT Id, Name, AI_Dunning_Frequency__c, Predicted_Payment_Dates__c
            FROM Account 
            WHERE Id = :acc.Id
            LIMIT 1
        ];
        Long t1 = System.currentTimeMillis();
        System.debug('processAccountTransactions: Account query time = ' + (t1 - t0) + ' ms');
        
        // 1. Fetch Transaction records with filter and specific columns
        t0 = System.currentTimeMillis();
        List<celsrm__Transaction__c> transactions = [
            SELECT Id, Name, celsrm__Amount__c, celsrm__Create_Date__c, celsrm__DPD__c, Dunning_eligibility__c
            FROM celsrm__Transaction__c 
            WHERE celsrm__Account__c = :acc.Id 
            AND celsrm__Close_Date__c = null
            AND celsrm__Amount__c > 0
        ];
        t1 = System.currentTimeMillis();
        System.debug('processAccountTransactions: len'+transactions.size() +'Transaction query time = ' + (t1 - t0) + ' ms');
        
        t0 = System.currentTimeMillis();
        Set<Id> transactionIds = new Set<Id>();
        for (celsrm__Transaction__c trans : transactions) {
            transactionIds.add(trans.Id);
        }

        List<celsrm__Celonis_Event__c> events = getDunningEvents(transactionIds, accId);

        t1 = System.currentTimeMillis();
        System.debug('processAccountTransactions: Event query time = ' + (t1 - t0) + ' ms ' + events.size());
        // Delegate processing of queried data to another function
        t0 = System.currentTimeMillis();
        handleQueriedData(accountDetails, transactions, events);
        t1 = System.currentTimeMillis();
        System.debug('processAccountTransactions: handleQueriedData time = ' + (t1 - t0) + ' ms');
        Long endTime = System.currentTimeMillis();
        System.debug('processAccountTransactions: total time taken = ' + (endTime - startTime) + ' ms');
    }
    
    // New function to handle all the queried inputs
    private void handleQueriedData(
        Account accountDetails, 
        List<celsrm__Transaction__c> transactions, 
        List<celsrm__Celonis_Event__c> event
    ) {
        Long startTime = System.currentTimeMillis();
        System.debug('Found ' + transactions.size());
        System.debug('Found ' + event.size() + ' custom records related to account/transactions');

        if (transactions.isEmpty()) {
            System.debug('No transactions to process.');
            Long endTime = System.currentTimeMillis();
            System.debug('handleQueriedData: total time taken = ' + (endTime - startTime) + ' ms');
            return;
        }

        // 1. Scale DPD and Amount for all transactions
        Long t0 = System.currentTimeMillis();
        Decimal minDPD = 0.0;
        Decimal maxDPD = 60.0;
        Decimal minAmt = 100.0;
        Decimal maxAmt = null;
        for (celsrm__Transaction__c t : transactions) {
            if (t.celsrm__Amount__c != null) {
                if (maxAmt == null || t.celsrm__Amount__c > maxAmt) maxAmt = t.celsrm__Amount__c;
            }
        }
        Decimal dpdRange = (maxDPD != null && minDPD != null) ? (maxDPD - minDPD) : 0;
        Decimal amtRange = (maxAmt != null && minAmt != null) ? (maxAmt - minAmt) : 0;
        Long t1 = System.currentTimeMillis();
        System.debug('handleQueriedData: Scaling DPD/Amount time = ' + (t1 - t0) + ' ms' );

        // 2. Build a map of transactionId to number of reminders from event list
        t0 = System.currentTimeMillis();
        Map<Id, Integer> txToReminders = new Map<Id, Integer>();
        for (celsrm__Celonis_Event__c e : event) {
            System.debug('Checking for ' + e);
            if (e.celsrm__Transaction__c != null) {
                if (!txToReminders.containsKey(e.celsrm__Transaction__c)) {
                    txToReminders.put(e.celsrm__Transaction__c, 1);
                } else {
                    txToReminders.put(e.celsrm__Transaction__c, txToReminders.get(e.celsrm__Transaction__c) + 1);
                    System.debug('Found match' + e.celsrm__Transaction__c);
                }
            }
        }
        t1 = System.currentTimeMillis();
        System.debug('handleQueriedData: Build reminders map time = ' + (t1 - t0) + ' ms');

        // 3. Calculate risk score for each transaction (use Account.AI_Dunning_Frequency__c mapping)
        t0 = System.currentTimeMillis();
        // Map<Id, Decimal> txToRiskScore = new Map<Id, Decimal>();
        Decimal accountRiskScore = computeRiskScoreFromDunningFrequency(accountDetails);
        // for (celsrm__Transaction__c t : transactions) {
        //     txToRiskScore.put(t.Id, accountRiskScore);
        // }
        t1 = System.currentTimeMillis();
        System.debug('handleQueriedData: Risk score calculation time = ' + (t1 - t0) + ' ms');

        // 4. Calculate score for each transaction
        t0 = System.currentTimeMillis();
        Map<Id, Decimal> txToScore = new Map<Id, Decimal>();
        Map<Id, TxnDetail> detailById = new Map<Id, TxnDetail>();
        Decimal totalScore = 0;
        Decimal epsilon = 0.00001;
        for (celsrm__Transaction__c t : transactions) {
            // Self-scaled DPD
            Decimal scaledDPD = 0;
            Decimal cappedDpd = t.celsrm__DPD__c;
            // Risk score
            // Decimal riskScore = txToRiskScore.containsKey(t.Id) ? txToRiskScore.get(t.Id) : 0;

            if (t.celsrm__DPD__c != null && dpdRange > 0) {
                if(t.celsrm__DPD__c < minDPD){
                    cappedDpd = minDPD;
                } else if (t.celsrm__DPD__c > maxDPD){
                    cappedDpd = maxDPD;
                }else{
                    cappedDpd = t.celsrm__DPD__c;
                }
                scaledDPD = cappedDpd / maxDPD;
                scaledDPD = scaledDPD * (1 + accountRiskScore);
            }
            // Self-scaled Amount
            Decimal scaledAmt = 0;
            if (t.celsrm__Amount__c != null && amtRange > 0) {
                scaledAmt = (t.celsrm__Amount__c - minAmt) / amtRange;
            }
            // Number of reminders
            Integer reminders = txToReminders.containsKey(t.Id) ? txToReminders.get(t.Id) : 0;
            
            Decimal reminderScore = 1.0 / (1.0 + reminders);
            if(reminders >3 ){
                reminderScore = 1;
            }
            if(t.celsrm__DPD__c<0){
                reminderScore = 0;
            }

            //NEW : Impact of missing following up this txn in
            Decimal penalty = 0;
            Decimal daysBetween = daysToNextDunning(accountDetails.Predicted_Payment_Dates__c);
            Decimal DpdMissedInNext = 0;
            Decimal scaledDpdMissedInNext = 0;
            Decimal cappedDpdMissedInNext = 0;
            if(daysBetween==null){
                daysBetween = accountDetails.AI_Dunning_Frequency__c;
            }
            if(daysBetween!=null){
                DpdMissedInNext = (t.celsrm__DPD__c == null) ? maxDPD : (t.celsrm__DPD__c + daysBetween);
                // Self-scaled DPD
                if (DpdMissedInNext != null && dpdRange > 0) {
                    if(DpdMissedInNext < minDPD){
                        cappedDpdMissedInNext = minDPD;
                    } else if (DpdMissedInNext > maxDPD){
                        cappedDpdMissedInNext = maxDPD;
                    }else{
                        cappedDpdMissedInNext = DpdMissedInNext;
                    }
                    scaledDpdMissedInNext = cappedDpdMissedInNext / maxDPD;
                    scaledDpdMissedInNext = scaledDpdMissedInNext * (1 + accountRiskScore);

                }
                penalty = (scaledDpdMissedInNext + epsilon) * (scaledAmt + epsilon);
            }


            // Final score
            // Impact term per Python: (amount_scaled + 0.001) * (dpd_scaled + 0.001)
            Decimal impact = (scaledAmt + epsilon) * (scaledDPD + epsilon) ;
            Decimal score;
            if (testForceZeroScore && Test.isRunningTest()) {
                score = 0;
            } else {
                score = (0.55 * impact) + (0.2 * penalty) + (0.25 * reminderScore) ;
            }
            txToScore.put(t.Id, score);
            totalScore += score;

            // Reasoning for dunning_eligibility__c
            String reason = '';
            Decimal cappedDpdSafe = (cappedDpd == null) ? 0 : cappedDpd;
            Decimal cappedNextSafe = (cappedDpdMissedInNext == null) ? 0 : cappedDpdMissedInNext;
            Integer pct = (Integer)Math.round(score * 100);
            reason = 'Risk score: ' +  pct + '%' +
                     ', Previous Number of Reminders: ' + String.valueOf(reminders) ;
                    //  ', cappedDpd DPD: ' + String.valueOf(cappedDpdSafe.setScale(5, RoundingMode.HALF_UP)) +   
                    //  ', cappedDpdNext DPD: ' + String.valueOf(cappedNextSafe.setScale(5, RoundingMode.HALF_UP)) +                     
                    //  ', Scaled DPD: ' + String.valueOf(scaledDPD.setScale(2, RoundingMode.HALF_UP)) +
                    //  ', Scaled Amount: ' + String.valueOf(scaledAmt.setScale(2, RoundingMode.HALF_UP)) +
                    //  ', Impact(dpdxamt): ' + String.valueOf(impact.setScale(5, RoundingMode.HALF_UP)) +
                    //  ', Penalty(dpd+'+daysBetween+' x amt): ' + String.valueOf(penalty.setScale(5, RoundingMode.HALF_UP)) +
                    //  ', Reminder Score: ' + String.valueOf(reminderScore.setScale(5, RoundingMode.HALF_UP)) +
                    //  ', A/C risk Score: ' + String.valueOf(riskScore.setScale(5, RoundingMode.HALF_UP));

            if(reminders>3){
                // reason = 'via Call/Manual | ' + reason; 
            }
            // capture detail
            TxnDetail d = new TxnDetail();
            d.txnId = t.Id;
            d.scaledAmount = scaledAmt;
            d.scaledDPD = scaledDPD;
            d.reminders = reminders;
            d.reminderScore = reminderScore;
            d.riskScore = accountRiskScore;
            d.impact = impact;
            d.score = score;
            d.dunningEligibilityReason = reason;
            detailById.put(t.Id, d);
        }
        t1 = System.currentTimeMillis();
        System.debug('handleQueriedData: Score calculation time = ' + (t1 - t0) + ' ms');

        // 5. Calculate contribution of each transaction
        t0 = System.currentTimeMillis();
        Map<Id, Decimal> txToContribution = new Map<Id, Decimal>();
        for (celsrm__Transaction__c t : transactions) {
            Decimal score = txToScore.containsKey(t.Id) ? txToScore.get(t.Id) : 0;
            Decimal contribution = (totalScore > 0) ? (score / totalScore) : 0;
            txToContribution.put(t.Id, contribution);
            if (detailById.containsKey(t.Id)) {
                detailById.get(t.Id).contribution = contribution;
            }
        }
        t1 = System.currentTimeMillis();
        System.debug('handleQueriedData: Contribution calculation time = ' + (t1 - t0) + ' ms');


        // 7. Nucleus selection per Python logic
        t0 = System.currentTimeMillis();
        Integer maxN = (configMaxN == null) ? 5 : configMaxN;
        Decimal nucleusP = (configNucleusP == null) ? 0.8 : configNucleusP;

        // Build sortable list with Score and fallback (Amount*DPD)
        // are all transaction open
        boolean allOpen = true;
        List<Map<String, Object>> txScoreList = new List<Map<String, Object>>();
        for (celsrm__Transaction__c t : transactions) {
            if( t.celsrm__DPD__c > 0){
                allOpen = false ;
            }
            Decimal score = txToScore.containsKey(t.Id) ? txToScore.get(t.Id) : 0;
            Decimal fallbackScore = 0;
            if (t.celsrm__Amount__c != null && t.celsrm__DPD__c != null) {
                fallbackScore = t.celsrm__Amount__c * t.celsrm__DPD__c;
            }
            Map<String, Object> entry = new Map<String, Object>();
            entry.put('Id', t.Id);
            entry.put('Score', score);
            entry.put('Fallback', fallbackScore);
            txScoreList.add(entry);
        }

        // Sort by Score descending
        if(allOpen){
            nucleusP = 0.5;
        }
        

        txScoreList.sort(new ScoreDescComparator());

        Decimal totalTps = totalScore;
        System.debug('totalTps : ' + totalTps);
        List<Id> selectedIds = new List<Id>();

        if (totalTps == 0) {
            // Fallback: sort by Amount*DPD and take top maxN
            txScoreList.sort(new FallbackDescComparator());
            Integer count = 0;
            for (Map<String, Object> entry : txScoreList) {
                selectedIds.add((Id)entry.get('Id'));
                count++;
                if (count >= maxN) break;
            }
            System.debug('Fallback selection (total TPS = 0). Top-N by Amount*DPD: ' + selectedIds);
        } else {
            // Nucleus by cumulative TPS percentage
            Decimal cumulativeTps = 0;
            for (Map<String, Object> entry : txScoreList) {
                Decimal s = (Decimal)entry.get('Score');
                String reasonOpen = '';
                if(allOpen ){
                    String reason = detailById.get((Id)entry.get('Id')).dunningEligibilityReason;

                    if (detailById.containsKey((Id)entry.get('Id'))) {
                        reasonOpen += ' All open';
                    }
                    if( s <= 0.1){ //0.4 because for penalty : max (0.09) for lower DPD and lower a/c risk score ( DPD <30 days /scaled dpd : 0.5) 0.5*0.2 the values are at max 0.55/2
                        s = 0;
                        if (detailById.containsKey((Id)entry.get('Id'))) {
                            reasonOpen += ', thus ignoring below Risk score 0.1';
                        }
                    }
                    detailById.get((Id)entry.get('Id')).dunningEligibilityReason = reasonOpen + reason;

                }
                if ( s > 0){
                    cumulativeTps += s;
                    Decimal pct = (totalTps > 0) ? (cumulativeTps / totalTps) : 0;
                    if (!selectedIds.contains((Id)entry.get('Id'))) {
                        selectedIds.add((Id)entry.get('Id'));
                    }
                    if (pct >= nucleusP) {
                        break;
                    }
                }
            }
            System.debug('Nucleus selection by cumulative TPS <= ' + nucleusP + ': ' + selectedIds.size() +' out of ' + transactions.size() + 'Details for' + detailById.size());
        }
        t1 = System.currentTimeMillis();
        System.debug('handleQueriedData: Nucleus selection time = ' + (t1 - t0) + ' ms');

        // Store selection result for tests
        t0 = System.currentTimeMillis();
        lastSelectionResult = new SelectionResult();
        lastSelectionResult.selectedIds = selectedIds;
        lastSelectionResult.detailsById = detailById;
        lastSelectionResult.totalTps = totalTps;
        lastSelectionResult.nucleusP = nucleusP;
        t1 = System.currentTimeMillis();
        System.debug('handleQueriedData: Store selection result time = ' + (t1 - t0) + ' ms');

        // Clear dunning_eligibility__c for all transactions belonging to the account
        List<celsrm__Transaction__c> allTxnsToClear = [
            SELECT Id, Dunning_eligibility__c
            FROM celsrm__Transaction__c
            WHERE celsrm__Account__c = :accountDetails.Id
        ];
        List<celsrm__Transaction__c> txnsToClear = new List<celsrm__Transaction__c>();
        for (celsrm__Transaction__c t : allTxnsToClear) {
            if (t.Dunning_eligibility__c != null) {
                txnsToClear.add(new celsrm__Transaction__c(
                    Id = t.Id,
                    Dunning_eligibility__c = 'Eligible : NO | '
                ));
            }
        }
        if (!txnsToClear.isEmpty()) {
            try {
                update txnsToClear;
                System.debug('Cleared Dunning_eligibility__c for ' + txnsToClear.size() + ' transactions.');
            } catch (Exception ex) {
                System.debug('Failed to clear Dunning_eligibility__c: ' + ex.getMessage());
            }
        }

        // 8. Update dunning_eligibility__c field for all transactions with the reasoning
        t0 = System.currentTimeMillis();
        List<celsrm__Transaction__c> txnsToUpdate = new List<celsrm__Transaction__c>();
        for (celsrm__Transaction__c t : transactions) {
            if (detailById.containsKey(t.Id)) {
                String reason = detailById.get(t.Id).dunningEligibilityReason;
                // Only update if changed or blank
                if(selectedIds.contains(t.Id)){
                    reason = 'Eligible : YES | ' + reason;
                }else{
                    reason = 'Eligible : NO  | ' + reason;
                }
                if (true) {
                    celsrm__Transaction__c tUpd = new celsrm__Transaction__c(
                        Id = t.Id,
                        Dunning_eligibility__c = reason
                    );
                    txnsToUpdate.add(tUpd);
                }
            }else{
                celsrm__Transaction__c tUpd = new celsrm__Transaction__c(
                        Id = t.Id,
                        Dunning_eligibility__c = 'detailById not found'
                );
                txnsToUpdate.add(tUpd);
            }
        }
        if (!txnsToUpdate.isEmpty()) {
            try {
                update txnsToUpdate;
                System.debug('Updated Dunning_eligibility__c for ' + txnsToUpdate.size() + ' transactions.');
            } catch (Exception ex) {
                System.debug('Failed to update Dunning_eligibility__c: ' + ex.getMessage());
            }
        }
        t1 = System.currentTimeMillis();
        System.debug('handleQueriedData: Dunning_eligibility__c update time = ' + (t1 - t0) + ' ms');

        Long endTime = System.currentTimeMillis();
        System.debug('handleQueriedData: total time taken = ' + (endTime - startTime) + ' ms');
    }

    /**
     * Get eligible transactions for an account while respecting query limits.
     * Returns both eligible and non-eligible transactions along with reasons.
     */
    public static EligibleTransactionResult getEligibleTransactions(Id accountId, Integer buffer) {
        if (accountId == null) {
            return new EligibleTransactionResult(false, new List<SelectedTxn>());
        }

        Integer queryBuffer = (buffer == null) ? 100 : buffer;
        Integer rowsUsed = Limits.getQueryRows();
        Integer rowsLimit = Limits.getLimitQueryRows();

        Integer transactionCount = [
            SELECT COUNT()
            FROM celsrm__Transaction__c
            WHERE celsrm__Account__c = :accountId
            AND celsrm__Close_Date__c = null
            AND celsrm__Amount__c > 0
            WITH SECURITY_ENFORCED
        ];

        if (rowsUsed + transactionCount + queryBuffer > rowsLimit) {
            System.debug('Query limit would be reached. rowsUsed: ' + rowsUsed +
                         ', transactionCount: ' + transactionCount +
                         ', buffer: ' + queryBuffer +
                         ', limit: ' + rowsLimit);
            return new EligibleTransactionResult(true, new List<SelectedTxn>());
        }

        DunningTransactionFiltering filter = new DunningTransactionFiltering();
        Account placeholderAccount = new Account(Id = accountId);
        Integer maxN = 5;
        Decimal nucleusP = 0.8;
        List<SelectedTxn> selectedTxns = filter.computeSelectedTransactions(placeholderAccount, maxN, nucleusP);

        return new EligibleTransactionResult(false, selectedTxns);
    }

    public List<celsrm__Celonis_Event__c> getDunningEvents (Set<Id> transactionIds, Id accId) {

        List<celsrm__Celonis_Event__c> events = new List<celsrm__Celonis_Event__c>();
        String reminderEventsWhereClause = UtilityController.getReminderEventsConfiguration();
        String soql;

        if (!transactionIds.isEmpty()) {

            soql =
                'SELECT Id, Name, celsrm__Transaction__c, celsrm__Account__c, CreatedDate ' +
                'FROM celsrm__Celonis_Event__c ' +
                'WHERE (celsrm__Account__c = :accId ' +
                'OR celsrm__Transaction__c IN :transactionIds)';
        
        } else {
        
            soql =
                'SELECT Id, Name, celsrm__Transaction__c, celsrm__Account__c, CreatedDate ' +
                'FROM celsrm__Celonis_Event__c ' +
                'WHERE celsrm__Account__c = :accId';
        }
        
        if (!String.isBlank(reminderEventsWhereClause)) {
            soql += reminderEventsWhereClause;
        }

        events = Database.query(soql);

        return events;

    }

    // Helper comparator class for sorting by Score descending
    private class ScoreDescComparator implements System.Comparator<Map<String, Object>> {
        public Integer compare(Map<String, Object> a, Map<String, Object> b) {
            Decimal scoreA = (Decimal)a.get('Score');
            Decimal scoreB = (Decimal)b.get('Score');
            if (scoreA == scoreB) return 0;
            return (scoreA > scoreB) ? -1 : 1;
        }
    }

    // Helper comparator: sort by Fallback descending (Amount * DPD)
    private class FallbackDescComparator implements System.Comparator<Map<String, Object>> {
        public Integer compare(Map<String, Object> a, Map<String, Object> b) {
            Decimal fa = (Decimal)a.get('Fallback');
            Decimal fb = (Decimal)b.get('Fallback');
            if (fa == fb) return 0;
            return (fa > fb) ? -1 : 1;
        }
    }
}