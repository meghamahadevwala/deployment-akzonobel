global with sharing class AIDunningInsightsController {

    /**
     * Set to true when deploying to an org with the celsrm managed package installed.
     * Set to false for unmanaged / unpackaged orgs.
     */
    private static final Boolean IS_MANAGED = true;
    private static final String NS = IS_MANAGED ? 'celsrm__' : '';
    
    /**
     * Fetch AI Dunning Insights for a given account
     * @param accountId - The Account ID to fetch insights for
     * @return DunningInsightsData - Object containing payment behavior, overdueRisk, strategies, and email automations
     */
    @AuraEnabled
    public static DunningInsightsData getDunningInsights(String accountId) {
        return getDunningInsightsInternal(accountId, false);
    }

    @AuraEnabled(cacheable=true)
    public static AIInsightFeatureFlags getAIInsightFeatureFlags() {
        celsrm__AI_Configuration__c aiConfig = celsrm__AI_Configuration__c.getOrgDefaults();
        AIInsightFeatureFlags flags = new AIInsightFeatureFlags();
        flags.enableAIDunning = (aiConfig != null && aiConfig.celsrm__Enable_AI_Dunning__c == true);
        flags.enableAIPaymentPrediction = (aiConfig != null && aiConfig.Enable_AI_Payment_Prediction__c == true);
        return flags;
    }

    @AuraEnabled
    public static DunningInsightsData refreshDunningInsights(String accountId) {
        if (String.isBlank(accountId)) {
            throw new AuraHandledException('Account ID cannot be null or empty');
        }
        // Recalculate dunning efficiency by running the batch for this account.
        // Batch finish() will update Last_AI_Dunning_Insight_Date__c when done.
        Database.executeBatch(new TransactionMetricsBatch(accountId), 200);
        DunningInsightsData data = getDunningInsightsInternal(accountId, false);
        data.calculationInProgress = true;
        return data;
    }

    private static DunningInsightsData getDunningInsightsInternal(String accountId, Boolean stampDate) {
        try {
            if (String.isBlank(accountId)) {
                throw new IllegalArgumentException('Account ID cannot be null or empty');
            }

            DunningInsightsData insights = new DunningInsightsData();

            // Fetch Account data (dynamic SOQL for namespace toggle)
            String accQuery =
                'SELECT Id, Name, ' +
                'Primary_Payment_Cycle__c, Secondary_Payment_Cycle__c, Predicted_Payment_Dates__c, ' +
                'DPD_Invoices__c, Business_Size__c, Overdue_Risk__c, Standard_Dunning_Frequency__c, ' +
                'Standard_Dunning_Schedule__c, Standard_Dunning_Enabled__c, ' + NS + 'AI_Dunning_Enabled__c, ' +
                'AI_Dunning_Strategy__c, AI_Dunning_Frequency__c, Cluster_Payment_Behaviour__c, ' +
                'Dunning_Efficiency_Index__c, Reminder_Utilisation_Ratio__c, Reminder_Alignment_Ratio__c, ' +
                'Closeness_Alignment_Ratio__c, Pre_Due_Reminder_Utilisation_Ratio__c, Pre_Due_Reminder_Alignment_Ratio__c, ' +
                'Dunning_Efficiency_Index_BA__c, Dunning_Efficiency_Index_AA__c, ' +
                'DPD_Invoices_BA__c, DPD_Invoices_AA__c, ' +
                'Reminder_Utilisation_Ratio_BA__c, Reminder_Utilisation_Ratio_AA__c, ' +
                'Reminder_Alignment_Ratio_BA__c, Reminder_Alignment_Ratio_AA__c, ' +
                'Closeness_Alignment_Ratio_BA__c, Closeness_Alignment_Ratio_AA__c, ' +
                'Pre_Due_Reminder_Utilisation_Ratio_BA__c, Pre_Due_Reminder_Utilisation_Ratio_AA__c, ' +
                'Pre_Due_Reminder_Alignment_Ratio_BA__c, Pre_Due_Reminder_Alignment_Ratio_AA__c, ' +
                'Dunning_Efficiency_Reasoning_Data_BA__c, Dunning_Efficiency_Reasoning_Data_AA__c, ' +
                'Dunning_Efficiency_Reasoning__c, Dunning_Efficiency_Reasoning_Data__c, Primary_Payment_Cycle_Score__c, ' +
                'Secondary_Payment_Cycle_Score__c, Frequent_Payment_Term__c, Last_AI_Dunning_Insight_Date__c, ' +
                'AI_Dunning_Enabled_Date__c, ' +
                'On_Time_Payment_Percentage__c, ' + NS + 'Average_DPD__c ' +
                'FROM Account WHERE Id = :accountId LIMIT 1';
            List<SObject> accRows = Database.query(accQuery);
            if (accRows == null || accRows.isEmpty()) {
                throw new IllegalArgumentException('Account not found: ' + accountId);
            }
            Account acc = (Account) accRows[0];

            insights.lastInsightDate = (DateTime) acc.get('Last_AI_Dunning_Insight_Date__c');

            // Visibility flags from celsrm__AI_Configuration__c custom setting
            celsrm__AI_Configuration__c aiConfig = celsrm__AI_Configuration__c.getOrgDefaults();
            insights.enableAIDunning = (aiConfig != null && aiConfig.celsrm__Enable_AI_Dunning__c == true);
            insights.enableDunningEfficiency = (aiConfig != null && aiConfig.celsrm__Enable_Dunning_Efficiency__c == true);

            // Populate Payment Behaviour
            insights.paymentBehaviour = new PaymentBehaviour();
            // Payment Cycle: show primary then secondary (if present). If none present, show fallback text.
            List<String> paymentCyclesList = new List<String>();

            if (acc.Primary_Payment_Cycle__c != null) {
                String scoreStr = acc.Primary_Payment_Cycle_Score__c != null ? String.valueOf(acc.Primary_Payment_Cycle_Score__c.setScale(0)) : 'N/A';
                paymentCyclesList.add(
                    'Primary cycle : ' + acc.Primary_Payment_Cycle__c.setScale(0) + ' days ( ' + scoreStr + '% probability)'
                );
            }
            if (acc.Secondary_Payment_Cycle__c != null) {
                String scoreStr = acc.Secondary_Payment_Cycle_Score__c != null ? String.valueOf(acc.Secondary_Payment_Cycle_Score__c.setScale(0)) : 'N/A';
                paymentCyclesList.add(
                    'Secondary cycle : ' + acc.Secondary_Payment_Cycle__c.setScale(0) + ' days ( ' + scoreStr + '% probability)'
                );
            }
            if (paymentCyclesList.isEmpty()) {
                paymentCyclesList.add('Irregular payment cycle');
            }
            if(acc.Frequent_Payment_Term__c != null){
                paymentCyclesList.add(
                    String.valueOf('Frequent payment term : ' + acc.Frequent_Payment_Term__c)
                );
            }
            
            insights.paymentBehaviour.paymentCycles = paymentCyclesList;

            // Predicted payment dates: stored as pipe-separated YYYY-MM-DD values (e.g. 2025-11-18|2025-12-18)
            if (acc.Predicted_Payment_Dates__c != null && acc.Predicted_Payment_Dates__c != '-') {
                List<String> rawDates = acc.Predicted_Payment_Dates__c.split('\\|');
                List<String> pretty = new List<String>();
                for (String dStr : rawDates) {
                    // to show at max 3 payment dates
                    if (pretty.size() == 3) break;

                    dStr = dStr.trim();
                    if (String.isBlank(dStr)) continue;
                    try {
                            Date d = Date.valueOf(dStr);
                            if(d < Date.today())continue;
                            // Format as 'dd MMM yyyy' for good UX, e.g. '18 Nov 2025'
                            pretty.add(DateTime.newInstance(d.year(), d.month(), d.day(), 0, 0, 0).format('dd MMM yyyy'));
                        } catch (Exception ex) {
                            // If parsing fails, add raw token
                            pretty.add(dStr);
                        }
                }
                if (!pretty.isEmpty()) {
                    insights.paymentBehaviour.predictedPayment = String.join(pretty, ', ');
                } else {
                    insights.paymentBehaviour.predictedPayment = 'NA';
                }
            } else {
                insights.paymentBehaviour.predictedPayment = 'NA';
            }

            // DPD now comes from DPD_Invoices__c
            // Show absolute integer (no decimal) instead of a decimal string
            Integer dpdInt = 0;
            if (acc.DPD_Invoices__c != null) {
                try {
                    // parse as string -> decimal safely, then take integer absolute value
                    // Decimal dpdDec = Decimal.valueOf(String.valueOf(acc.DPD_Invoices__c));
                    dpdInt = Math.abs((Integer) acc.DPD_Invoices__c);
                    insights.paymentBehaviour.dpd = String.valueOf(dpdInt) + ' days';
                } catch (Exception ex) {
                    // fallback to raw string if parsing fails
                    insights.paymentBehaviour.dpd = String.valueOf(acc.DPD_Invoices__c);
                }
            } else {
                insights.paymentBehaviour.dpd = 'NA';
            }
            insights.paymentBehaviour.businessSize = acc.Business_Size__c != null ? acc.Business_Size__c : 'NA';

            insights.paymentBehaviour.avgPaymentTerm = acc.Frequent_Payment_Term__c;
            insights.paymentBehaviour.onTimePaymentPct = acc.On_Time_Payment_Percentage__c;
            insights.paymentBehaviour.primaryCycleDays = acc.Primary_Payment_Cycle__c;
            insights.paymentBehaviour.primaryCycleScore = acc.Primary_Payment_Cycle_Score__c;
            insights.paymentBehaviour.secondaryCycleDays = acc.Secondary_Payment_Cycle__c;
            insights.paymentBehaviour.secondaryCycleScore = acc.Secondary_Payment_Cycle_Score__c;
            insights.paymentBehaviour.avgDaysLate = dpdInt;

            // Populate Overdue Risk
            // Parse the stored value (could be decimal like 0.23) and convert to an absolute percentage integer (e.g., 23)
            Integer overdueRiskInt = 0;
            if (acc.Overdue_Risk__c != null) {
                try {
                    Decimal od = Decimal.valueOf(String.valueOf(acc.Overdue_Risk__c));
                    // Use the arithmetic operator to multiply the decimal by 100 to avoid visibility issues with Decimal.multiply
                    overdueRiskInt = Math.abs((od * 100).intValue());
                } catch (Exception ex) {
                    try {
                        // Last resort: try integer parse
                        overdueRiskInt = Math.abs(Integer.valueOf(String.valueOf(acc.Overdue_Risk__c)));
                    } catch (Exception ex2) {
                        overdueRiskInt = 0;
                    }
                }
            }
            insights.overdueRisk = overdueRiskInt;

            // Populate Standard Strategy (from Account or defaults)
            insights.standardStrategy = new DunningStrategy();
            // it will be true only if dunning is already working on this account
            Decimal reminderEventsCount = queryReminderEvents(accountId);
            // we have to check reminderEventsCount > 0 as well before going to prod
            insights.standardStrategy.enabled = (acc.Standard_Dunning_Enabled__c && reminderEventsCount > 0) ? true : false;
            // insights.standardStrategy.enabled = acc.Standard_Dunning_Enabled__c ;

            // Dunning Frequency formatting: combine Standard_Dunning_Frequency__c and Standard_Dunning_Schedule__c
            String stdFreq = acc.Standard_Dunning_Frequency__c != null ? String.valueOf(acc.Standard_Dunning_Frequency__c) : null;
            String stdSchedule = acc.Standard_Dunning_Schedule__c != null ? acc.Standard_Dunning_Schedule__c : null;
            if (stdFreq != null && stdSchedule != null) {
                insights.standardStrategy.reminderFrequency = stdFreq + ' days, ' + stdSchedule;
            } else if (stdFreq != null) {
                insights.standardStrategy.reminderFrequency = stdFreq + ' days';
            } else if (stdSchedule != null) {
                insights.standardStrategy.reminderFrequency = stdSchedule;
            } else {
                insights.standardStrategy.reminderFrequency = 'NA';
            }

            // Build Standard Dunning insights per provided rules
            // Placeholders: <dpd> from DPD_Invoices__c, <current_dunning_frequency> = Standard_Dunning_Frequency__c
            Integer standardFreqInt = 0;
            Integer recommendedFreqInt = 0;
            Integer clusterBehavior = 0;
            Integer dpdHistoric = 0;
            try {
                if (acc.Standard_Dunning_Frequency__c != null) standardFreqInt = Integer.valueOf(acc.Standard_Dunning_Frequency__c);
            } catch (Exception e) { /* ignore */ }
            try {
                if (acc.AI_Dunning_Frequency__c != null) recommendedFreqInt = Integer.valueOf(acc.AI_Dunning_Frequency__c);
            } catch (Exception e) { /* ignore */ }
            try {
                if (acc.Cluster_Payment_Behaviour__c != null) clusterBehavior = Integer.valueOf(acc.Cluster_Payment_Behaviour__c);
            } catch (Exception e) { /* ignore */ }
            try {
                if (acc.DPD_Invoices__c != null) {
                    dpdHistoric = dpdInt;
                }
            } catch (Exception e) { /* ignore */ }

            if (Math.abs((standardFreqInt - recommendedFreqInt)) >= 5 && clusterBehavior <= 2) {
                insights.standardStrategy.insights = 'Good payer with ' + String.valueOf(dpdHistoric) + ' days of historic DPD, dunning reminders are aggressive every ' + String.valueOf(standardFreqInt) + ' days.';
            } else if (Math.abs((recommendedFreqInt - standardFreqInt)) >= 5 && clusterBehavior > 2) {
                insights.standardStrategy.insights = 'Late payer with ' + String.valueOf(dpdHistoric) + ' days of historic DPD, dunning reminders are less frequent.';
            } else {
                insights.standardStrategy.insights = 'Standard rule based dunning applied which does not change as customer\'s re-payment behaviour changes';
            }

            // Populate Recommended (AI) Strategy
            insights.recommendedStrategy = new DunningStrategy();
            Boolean aiEnabled = (Boolean) acc.get(NS + 'AI_Dunning_Enabled__c');
            insights.recommendedStrategy.enabled = (aiEnabled != null ? aiEnabled : false);
            insights.recommendedStrategy.enabledDate = (DateTime) acc.get('AI_Dunning_Enabled_Date__c');
            insights.recommendedStrategy.strategy = acc.AI_Dunning_Strategy__c != null ? acc.AI_Dunning_Strategy__c : 'NA';
            insights.recommendedStrategy.reminderFrequency = acc.AI_Dunning_Frequency__c != null ? String.valueOf(acc.AI_Dunning_Frequency__c) + ' days' : 'NA';
            // Show overdue risk as absolute percentage integer (e.g., 23%)
            insights.recommendedStrategy.overdueRisk = (acc.Overdue_Risk__c != null) ? String.valueOf(overdueRiskInt) + '%' : 'NA';

            // Dunning Strategy messaging rules (for demo: always show)
            String strat = insights.recommendedStrategy.strategy != null ? insights.recommendedStrategy.strategy.toLowerCase() : '';
            Boolean hasPredicted = (acc.Predicted_Payment_Dates__c != null && String.isNotBlank(acc.Predicted_Payment_Dates__c));
            if (strat == 'proactive') {
                insights.recommendedStrategy.insights = 'Proactively, Remind every few days';
            } else if (strat == 'reactive') {
                if (hasPredicted) {
                    insights.recommendedStrategy.insights = 'Remind 2 days after missed payment cycle is found';
                } else {
                    insights.recommendedStrategy.insights = 'Remind once a month if high dues are present';
                }
            } else {
                insights.recommendedStrategy.insights = 'Recommended strategy: ' + insights.recommendedStrategy.strategy;
            }

            // ── Dunning Efficiency Reasoning (structured JSON) ──
            Map<String, Object> reasoningJson = new Map<String, Object>();
            if (String.isNotBlank(acc.Dunning_Efficiency_Reasoning__c)) {
                try {
                    reasoningJson = (Map<String, Object>) JSON.deserializeUntyped(acc.Dunning_Efficiency_Reasoning__c);
                } catch (Exception ex) {
                    reasoningJson = new Map<String, Object>();
                }
            }

            Boolean reasoningChanged = false;

            // ── Overall Reasoning ──
            Map<String, Object> overallAttrs = buildCalculatedAttributes(
                acc.Dunning_Efficiency_Index__c, acc.Reminder_Utilisation_Ratio__c,
                acc.Reminder_Alignment_Ratio__c, acc.Closeness_Alignment_Ratio__c,
                acc.Pre_Due_Reminder_Utilisation_Ratio__c, acc.Pre_Due_Reminder_Alignment_Ratio__c
            );
            String overallTag = computeDunningTag(acc.Dunning_Efficiency_Index__c);
            Map<String, Object> overallSection = getReasoningSection(reasoningJson, 'OverallReasoning');

            if (needsReasoningRefresh(overallSection, overallAttrs)) {
                Map<String, Object> reasonData = fetchAIReasoning(
                    acc, overallTag, acc.DPD_Invoices__c, acc.Dunning_Efficiency_Reasoning_Data__c
                );
                overallSection = buildReasoningSection(overallAttrs, reasonData);
                reasoningJson.put('OverallReasoning', overallSection);
                reasoningChanged = true;
            }

            // ── After Agent (AA) Reasoning ──
            Map<String, Object> aaAttrs = buildCalculatedAttributes(
                (Decimal) acc.get('Dunning_Efficiency_Index_AA__c'),
                (Decimal) acc.get('Reminder_Utilisation_Ratio_AA__c'),
                (Decimal) acc.get('Reminder_Alignment_Ratio_AA__c'),
                (Decimal) acc.get('Closeness_Alignment_Ratio_AA__c'),
                (Decimal) acc.get('Pre_Due_Reminder_Utilisation_Ratio_AA__c'),
                (Decimal) acc.get('Pre_Due_Reminder_Alignment_Ratio_AA__c')
            );
            String aaTag = computeDunningTag((Decimal) acc.get('Dunning_Efficiency_Index_AA__c'));
            Map<String, Object> aaSection = getReasoningSection(reasoningJson, 'reasonAfterAgent');

            if (hasMetricData(aaAttrs) && needsReasoningRefresh(aaSection, aaAttrs)) {
                Map<String, Object> aaReasonData = fetchAIReasoning(
                    acc, aaTag, (Decimal) acc.get('DPD_Invoices_AA__c'),
                    (String) acc.get('Dunning_Efficiency_Reasoning_Data_AA__c')
                );
                aaSection = buildReasoningSection(aaAttrs, aaReasonData);
                reasoningJson.put('reasonAfterAgent', aaSection);
                reasoningChanged = true;
            }

            // ── Before Agent (BA) Reasoning ──
            Map<String, Object> baAttrs = buildCalculatedAttributes(
                (Decimal) acc.get('Dunning_Efficiency_Index_BA__c'),
                (Decimal) acc.get('Reminder_Utilisation_Ratio_BA__c'),
                (Decimal) acc.get('Reminder_Alignment_Ratio_BA__c'),
                (Decimal) acc.get('Closeness_Alignment_Ratio_BA__c'),
                (Decimal) acc.get('Pre_Due_Reminder_Utilisation_Ratio_BA__c'),
                (Decimal) acc.get('Pre_Due_Reminder_Alignment_Ratio_BA__c')
            );
            String baTag = computeDunningTag((Decimal) acc.get('Dunning_Efficiency_Index_BA__c'));
            Map<String, Object> baSection = getReasoningSection(reasoningJson, 'reasonBeforeAgent');

            if (hasMetricData(baAttrs) && needsReasoningRefresh(baSection, baAttrs)) {
                Map<String, Object> baReasonData = fetchAIReasoning(
                    acc, baTag, (Decimal) acc.get('DPD_Invoices_BA__c'),
                    (String) acc.get('Dunning_Efficiency_Reasoning_Data_BA__c')
                );
                baSection = buildReasoningSection(baAttrs, baReasonData);
                reasoningJson.put('reasonBeforeAgent', baSection);
                reasoningChanged = true;
            }

            if (reasoningChanged) {
                updateDunningEfficiencyReasoning(accountId, JSON.serialize(reasoningJson));
            }

            insights.dunningEfficiencyResult = buildEfficiencyResult(overallAttrs, overallSection, overallTag);
            insights.aiDunningEfficiencyResult = buildEfficiencyResult(aaAttrs, aaSection, aaTag);
            insights.standardDunningEfficiencyResult = buildEfficiencyResult(baAttrs, baSection, baTag);

            // if (stampDate) {
            //     try {
            //         DateTime nowDt = DateTime.now();
            //         Account accUpdate = new Account(Id = accountId);
            //         accUpdate.Last_AI_Dunning_Insight_Date__c = nowDt;
            //         update accUpdate;
            //         insights.lastInsightDate = nowDt;
            //     } catch (Exception stampEx) {
            //         System.debug('Failed to stamp Last_AI_Dunning_Insight_Date__c: ' + stampEx.getMessage());
            //     }
            // }

            return insights;

        } catch (QueryException qe) {
            throw new AuraHandledException('Error querying account: ' + qe.getMessage());
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching dunning insights: ' + e.getMessage());
        }
    }

    /**
     * Update dunning strategy preference for an account
     */
    @AuraEnabled
    public static void updateDunningStrategy(String accountId, String strategyType, Boolean enabled) {
        try {
            if (String.isBlank(accountId) || String.isBlank(strategyType)) {
                throw new IllegalArgumentException('Account ID and Strategy Type cannot be null');
            }

            Account acc = new Account(Id = accountId);
            
            if (strategyType == 'standard') {
                acc.Standard_Dunning_Enabled__c = enabled;
            } else if (strategyType == 'recommended') {
                acc.put(NS + 'AI_Dunning_Enabled__c', enabled);
                acc.AI_Dunning_Enabled_Date__c = DateTime.now();
            }
            
            update acc;

            if (strategyType == 'recommended') {
                String eventName = enabled ? 'AI Dunning Enabled' : 'AI Dunning Disabled';
                List<String> idList = new List<String>{ accountId };
                celsrm.SRMUtilityController.insertActivity(idList, NS + 'Account__c', eventName, 100, eventName, UserInfo.getUserId(), null, 'Internal');
            }
        } catch (Exception e) {
            throw new AuraHandledException('Error updating dunning strategy: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static void updateDunningEfficiencyReasoning(String accountId, String reasoning){
        try {
            Account accToUpdate = new Account(Id = accountId);          
            accToUpdate.Dunning_Efficiency_Reasoning__c = reasoning;
            update accToUpdate;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static Decimal queryReminderEvents(String accId) {

        String reminderNameWhereClause = UtilityController.getReminderEventsConfiguration();
        
        String soql =
        'SELECT Id, ' + NS + 'Transaction__c ' +
        'FROM ' + NS + 'Celonis_Event__c ' +
        'WHERE ' + NS + 'Account__c = :accId';

        if (!String.isBlank(reminderNameWhereClause)) {
            soql += reminderNameWhereClause;
        }

        List<SObject> events = Database.query(soql);

        return events.size();

    }

    private static String computeDunningTag(Decimal dei) {
        if (dei == null) return '';
        if (dei > 0.25) return 'Over Dunning Observed';
        if (dei < -0.25) return 'Under Dunning Observed';
        return 'Appropriate Dunning';
    }

    private static Map<String, Object> buildCalculatedAttributes(
        Decimal dei, Decimal rur, Decimal rar, Decimal car, Decimal prur, Decimal prar
    ) {
        Map<String, Object> attrs = new Map<String, Object>();
        attrs.put('dei', dei);
        attrs.put('rur', rur);
        attrs.put('rar', rar);
        attrs.put('car', car);
        attrs.put('prur', prur);
        attrs.put('prar', prar);
        return attrs;
    }

    private static Map<String, Object> getReasoningSection(Map<String, Object> reasoningJson, String key) {
        if (reasoningJson.containsKey(key)) {
            try {
                return (Map<String, Object>) reasoningJson.get(key);
            } catch (Exception e) {
                return new Map<String, Object>();
            }
        }
        return new Map<String, Object>();
    }

    private static Boolean hasMetricData(Map<String, Object> attrs) {
        for (String key : attrs.keySet()) {
            if (attrs.get(key) != null) return true;
        }
        return false;
    }

    private static Boolean needsReasoningRefresh(Map<String, Object> section, Map<String, Object> currentAttrs) {
        if (section == null || section.isEmpty() || !section.containsKey('calculatedattribute')) {
            return true;
        }
        Map<String, Object> storedAttrs;
        try {
            storedAttrs = (Map<String, Object>) section.get('calculatedattribute');
        } catch (Exception e) {
            return true;
        }
        if (storedAttrs == null) return true;

        for (String key : currentAttrs.keySet()) {
            Object currentVal = currentAttrs.get(key);
            Object storedVal = storedAttrs.get(key);
            if (currentVal == null && storedVal == null) continue;
            if (currentVal == null || storedVal == null) return true;
            try {
                Decimal currentDec = (Decimal) currentVal;
                Decimal storedDec = Decimal.valueOf(String.valueOf(storedVal));
                if (currentDec.setScale(4) != storedDec.setScale(4)) return true;
            } catch (Exception e) {
                return true;
            }
        }
        return false;
    }

    private static Map<String, Object> fetchAIReasoning(
        Account acc, String dunningTag, Decimal dpdInvoices, String reasoningDataJson
    ) {
        Map<String, Object> efficiencyData = new Map<String, Object>();
        if (String.isNotBlank(reasoningDataJson)) {
            efficiencyData = (Map<String, Object>) JSON.deserializeUntyped(reasoningDataJson);
        }

        Map<String, Object> params = new Map<String, Object>();
        params.put('accountName', acc.Name);
        params.put('dunningTag', dunningTag);
        params.put('historicDpd', dpdInvoices != null ? Math.abs(dpdInvoices.intValue()) : 0);
        params.put('actualReminders', (Decimal) efficiencyData.get('avgNumOfReminders'));
        params.put('actualGap', (Decimal) efficiencyData.get('avgDaysBetweenReminders'));
        params.put('actualClosure', (Decimal) efficiencyData.get('avgDaysToClose'));
        params.put('preDueCount', (Decimal) efficiencyData.get('avgNumOfPreReminders'));
        params.put('preDueAlignment', (Decimal) efficiencyData.get('avgDaysToDue'));
        params.put('averageDPD', (Decimal) acc.get(NS + 'Average_DPD__c'));
        params.put('expRem', efficiencyData.get('avgExpectedReminders') != null ? String.valueOf(efficiencyData.get('avgExpectedReminders')) : 'N/A');
        params.put('expGap', efficiencyData.get('avgExpectedDaysGapRatio') != null ? String.valueOf(efficiencyData.get('avgExpectedDaysGapRatio')) : 'N/A');
        params.put('expClos', efficiencyData.get('avgExpectedCloseGap') != null ? String.valueOf(efficiencyData.get('avgExpectedCloseGap')) : 'N/A');
        params.put('expPreCount', efficiencyData.get('avgExpectedPreDueReminderCountRatio') != null ? String.valueOf(efficiencyData.get('avgExpectedPreDueReminderCountRatio')) : 'N/A');
        params.put('expPreGap', efficiencyData.get('avgExpectedPreDueReminderGap') != null ? String.valueOf(efficiencyData.get('avgExpectedPreDueReminderGap')) : 'N/A');

        Object jsonResponse = AIDunningGenAiController.getDunningEfficiencyReasoning(params);
        Map<String, Object> reasonData = new Map<String, Object>();
        if (jsonResponse != null) {
            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(jsonResponse));
            String arguments = (String) responseMap.get('arguments');
            if (String.isNotBlank(arguments)) {
                reasonData = (Map<String, Object>) JSON.deserializeUntyped(arguments);
            }
        }
        return reasonData;
    }

    private static Map<String, Object> buildReasoningSection(
        Map<String, Object> calculatedAttrs, Map<String, Object> reasonData
    ) {
        Map<String, Object> section = new Map<String, Object>();
        section.put('calculatedattribute', calculatedAttrs);
        Map<String, Object> reasons = new Map<String, Object>();
        reasons.put('reminder_count_reasoning', reasonData.get('reminder_count_reasoning'));
        reasons.put('reminder_frequency_reasoning', reasonData.get('reminder_frequency_reasoning'));
        reasons.put('days_to_payment_reasoning', reasonData.get('days_to_payment_reasoning'));
        reasons.put('pre_due_reminder_count_reasoning', reasonData.get('pre_due_reminder_count_reasoning'));
        reasons.put('days_to_due_date_reasoning', reasonData.get('days_to_due_date_reasoning'));
        section.put('reason', reasons);
        return section;
    }

    private static DunningEfficiencyResult buildEfficiencyResult(
        Map<String, Object> attrs, Map<String, Object> section, String tag
    ) {
        DunningEfficiencyResult result = new DunningEfficiencyResult();
        result.dei = (Decimal) attrs.get('dei');
        result.rur = (Decimal) attrs.get('rur');
        result.rar = (Decimal) attrs.get('rar');
        result.car = (Decimal) attrs.get('car');
        result.prur = (Decimal) attrs.get('prur');
        result.prar = (Decimal) attrs.get('prar');
        result.dunningTag = tag;

        Map<String, Object> reasons = new Map<String, Object>();
        if (section != null && section.containsKey('reason')) {
            try {
                reasons = (Map<String, Object>) section.get('reason');
            } catch (Exception e) { /* ignore */ }
        }
        result.countReasoning = (String) reasons.get('reminder_count_reasoning');
        result.freqReasoning = (String) reasons.get('reminder_frequency_reasoning');
        result.paymentReasoning = (String) reasons.get('days_to_payment_reasoning');
        result.preDueCountReasoning = (String) reasons.get('pre_due_reminder_count_reasoning');
        result.dueDateReasoning = (String) reasons.get('days_to_due_date_reasoning');
        return result;
    }

    // Wrapper Classes
    public class DunningInsightsData {
        @AuraEnabled
        public PaymentBehaviour paymentBehaviour { get; set; }

        @AuraEnabled
        public Integer overdueRisk { get; set; }

        @AuraEnabled
        public DunningStrategy standardStrategy { get; set; }

        @AuraEnabled
        public DunningStrategy recommendedStrategy { get; set; }

        @AuraEnabled
        public DunningEfficiencyResult dunningEfficiencyResult { get; set; }

        @AuraEnabled
        public DunningEfficiencyResult aiDunningEfficiencyResult { get; set; }

        @AuraEnabled
        public DunningEfficiencyResult standardDunningEfficiencyResult { get; set; }

        @AuraEnabled
        public DateTime lastInsightDate { get; set; }

        @AuraEnabled
        public Boolean enableDunningEfficiency { get; set; }

        @AuraEnabled
        public Boolean enableAIDunning { get; set; }

        /** True when refresh triggered TransactionMetricsBatch; UI should show "calculation in progress" message. */
        @AuraEnabled
        public Boolean calculationInProgress { get; set; }
    }

    public class AIInsightFeatureFlags {
        @AuraEnabled
        public Boolean enableAIDunning { get; set; }

        @AuraEnabled
        public Boolean enableAIPaymentPrediction { get; set; }
    }

    public class PaymentBehaviour {
        
        @AuraEnabled
        public List<String> paymentCycles { get; set; }

        @AuraEnabled
        public String predictedPayment { get; set; }

        @AuraEnabled
        public String dpd { get; set; }

        @AuraEnabled
        public String businessSize { get; set; }

        @AuraEnabled
        public String avgPaymentTerm { get; set; }

        @AuraEnabled
        public Decimal onTimePaymentPct { get; set; }

        @AuraEnabled
        public Decimal primaryCycleDays { get; set; }

        @AuraEnabled
        public Decimal primaryCycleScore { get; set; }

        @AuraEnabled
        public Decimal secondaryCycleDays { get; set; }

        @AuraEnabled
        public Decimal secondaryCycleScore { get; set; }

        @AuraEnabled
        public Integer avgDaysLate { get; set; }
    }

    public class DunningStrategy {
        @AuraEnabled
        public String frequency { get; set; }

        @AuraEnabled
        public Boolean enabled { get; set; }

        @AuraEnabled
        public String insights { get; set; }

        @AuraEnabled
        public String name { get; set; }

        @AuraEnabled
        public String reminderFrequency { get; set; }
        
        // Additional properties for LWC
        @AuraEnabled
        public String strategy { get; set; }

        @AuraEnabled
        public String overdueRisk { get; set; }

        @AuraEnabled
        public DateTime enabledDate { get; set; }
    }

    public class DunningEfficiencyResult {
        @AuraEnabled
        public Decimal dei { get; set; }

        @AuraEnabled
        public Decimal rur { get; set; }

        @AuraEnabled
        public Decimal rar { get; set; }

        @AuraEnabled
        public Decimal car { get; set; }

        @AuraEnabled
        public Decimal prur { get; set; }

        @AuraEnabled
        public Decimal prar { get; set; }

        @AuraEnabled 
        public String countReasoning { get; set; }

        @AuraEnabled 
        public String freqReasoning { get; set; }

        @AuraEnabled 
        public String paymentReasoning { get; set; }

        @AuraEnabled 
        public String preDueCountReasoning { get; set; }

        @AuraEnabled 
        public String dueDateReasoning { get; set; }

        @AuraEnabled
        public String dunningTag { get; set; }
        
    }

}