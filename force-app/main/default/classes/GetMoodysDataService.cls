public with sharing class GetMoodysDataService implements Queueable, Database.AllowsCallouts {
    // << START - MM - FIN-8639 - Credit scores not generated in Sailfin after monitor call>>
    // public List<Account> iaccounts;
    public List<String> iaccounts;
    // << END - MM - FIN-8639 - Credit scores not generated in Sailfin after monitor call>>
    public Boolean allowCreateCr;
    public Boolean isPeriodic;
    
    // << START - MM - FIN-8639 - Credit scores not generated in Sailfin after monitor call>>
    public GetMoodysDataService(List<String> accounts, Boolean allowCreateCr, Boolean isPeriodic) {
    // << END - MM - FIN-8639 - Credit scores not generated in Sailfin after monitor call>>
        this.iaccounts = accounts;
        this.allowCreateCr = allowCreateCr;
        this.isPeriodic = isPeriodic;
    }

    public void execute(QueueableContext context) {
        // << START - MM - FIN-10145 - Fix Too many queueable jobs error by deferring UpdateLimitInSourceSystemService to Finalizer >>
        GetMoodysDataFinalizer finalizer = new GetMoodysDataFinalizer();
        System.attachFinalizer(finalizer);
        // << END - MM - FIN-10145 - Fix Too many queueable jobs error by deferring UpdateLimitInSourceSystemService to Finalizer >>
        try {
            List<celsrm__Credit_Review__c> crToInsert = new List<celsrm__Credit_Review__c>();
            List<celsrm__Credit_Score__c> csToInsert = new List<celsrm__Credit_Score__c>();
            List<Account> accToUpdate = new List<Account>();
            List<String> accToUpdateInCFIN = new List<String>();
            List<Account> accToUpdateProfileData = new List<Account>();
            List<String> currencyList = new List<String>();
            Map<String, List<Account>> bvdIdAccountMap = new Map<String, List<Account>>();
            Map<String, List<Account>> accountsByCurrency = new Map<String, List<Account>>();
            Map<String, Set<String>> bvdIdsByCurrency = new Map<String, Set<String>>();
            // Refactor: moreRiskClassMapping / qualitativeRiskClassMapping / riskClassMapping / checkRuleMapping
            // were duplicated verbatim in CreditReviewParameters. They now live in RiskClassCheckRuleMappingService;
            // MORE_RISK_CLASS_MAPPING and QUALITATIVE_RISK_CLASS_MAPPING are used directly below (score derivation),
            // and riskClassMapping/checkRuleMapping were only used in the Risk Class/Check Rule assignment block,
            // which is now RiskClassCheckRuleMappingService.mapRiskClassAndCheckRule(...).
            Map<String, Decimal> conversionRateMap = new Map<String, Decimal>();
            Moody_s_Auth__c MoodysAuth = creditParamsHttpCalloutManager.getMoodysAccessToken();
            String accessToken;
            if(MoodysAuth != null) {
                accessToken = MoodysAuth.Access_Token__c;
            }
            // FIX: added Moody_s_Risk_Class__c, Previous_Moody_s_Risk_Class__c, Previous_Moody_s_Credit_Limit__c and
            // Credit_Score_Comparison_Flag__c to the SELECT — CreditScoreComparisonService.evaluate()/applyComparisonAndRollValues()
            // read/write these via sObject.get()/put(), and get() throws System.SObjectException at runtime if the field
            // was not queried. That exception was being silently swallowed by the catch(Exception e) below, aborting all
            // processing (no Credit_Score__c/Credit_Review__c inserted, no Account update).
            List<Account> accountRecords = [SELECT Id, Name, AccountNumber, celsrm__Credit_Control_Area__c, CurrencyIsoCode, BvD_ID_Number__c, celsrm__Payment_Behavior__c, 
                                            celsrm__Payment_Behaviour_Text__c, celsrm__Payment_Behaviour_Trend__c, Recommended_Credit_Limit__c, Expected_Turnover__c, 
                                            celsrm__Credit_Limit__c, celsrm__Limit_Valid_To_Date__c, Moody_s_Credit_Limit__c, Moody_s_Risk_Class__c, Credit_Exposure__c, 
                                            Payment_Term_Days__c, celsrm__Check_Rule__c, celsrm__Risk_Class__c, celsrm__Credit_Group__c, 
                                            Calculated_Credit_Limit_Group_Currency__c, Moody_s_Change_Identified__c, Region__c,
                                            Previous_Moody_s_Risk_Class__c, Previous_Moody_s_Credit_Limit__c, Credit_Score_Comparison_Flag__c
                                            FROM Account 
                                            WHERE 
                                            Id IN :iaccounts 
                                            ORDER BY CurrencyIsoCode, BvD_ID_Number__c];
            for(Account acc: accountRecords) {
                //Accounts By CurrencyIsoCode
                if(accountsByCurrency.containsKey(acc.CurrencyIsoCode)){
                    List<Account> existingAccs = accountsByCurrency.get(acc.CurrencyIsoCode);
                    existingAccs.add(acc);
                    accountsByCurrency.put(acc.CurrencyIsoCode, existingAccs);


                    Set<String> existingbvdIds = bvdIdsByCurrency.get(acc.CurrencyIsoCode);
                    existingbvdIds.add(acc.BvD_ID_Number__c);
                    bvdIdsByCurrency.put(acc.CurrencyIsoCode, existingbvdIds);
                } else {
                    List<Account> existingAccs = new List<Account>();
                    existingAccs.add(acc);
                    accountsByCurrency.put(acc.CurrencyIsoCode, existingAccs);


                    Set<String> existingbvdIds = new Set<String>();
                    existingbvdIds.add(acc.BvD_ID_Number__c);
                    bvdIdsByCurrency.put(acc.CurrencyIsoCode, existingbvdIds);
                }

                //Accounts By BVDID
                if(bvdIdAccountMap.containsKey(acc.BvD_ID_Number__c)){
                    List<Account> existingAccs = bvdIdAccountMap.get(acc.BvD_ID_Number__c);
                    existingAccs.add(acc);
                    bvdIdAccountMap.put(acc.BvD_ID_Number__c, existingAccs);
                } else {
                    List<Account> existingAccs = new List<Account>();
                    existingAccs.add(acc);
                    bvdIdAccountMap.put(acc.BvD_ID_Number__c, existingAccs);
                }
            }

            if (allowCreateCr == true) {
                List<CurrencyType> currencyConv = [SELECT IsoCode, ConversionRate FROM CurrencyType WHERE IsoCode IN :accountsByCurrency.keySet()];
                for (CurrencyType ct : currencyConv) {
                    conversionRateMap.put(ct.IsoCode, ct.ConversionRate);
                }
            }

            // For each CurrencyIsoCode, Seperately call the API (Max 100 allows)
            for(String currencyIsoCode : accountsByCurrency.keySet()){
                List<Account> accounts = accountsByCurrency.get(currencyIsoCode);
                Set<String> bvdIds = bvdIdsByCurrency.get(currencyIsoCode);
                System.debug('CurrencyIsoCode::' + currencyIsoCode);
                System.debug('Accounts::' + accounts.size());
                creditParamsHttpCalloutManager calloutManager = new creditParamsHttpCalloutManager();
                System.debug('bvdIds::' + bvdIds);
                List<Map<Object, Object>> bvdData = getBvDInfoForMultipleAccounts(bvdIds, currencyIsoCode, accessToken);
                if(bvdData.size() > 0) {
                    for (Map<Object, Object> bvdMap : bvdData) {
                        String bvdId = (String) bvdMap.get('bvdId');
                        
                        if(!bvdIdAccountMap.containsKey(bvdId)) {
                            continue;
                        } else {
                            List<Account> matchedAccounts = bvdIdAccountMap.get(bvdId);
                            System.debug('BVDID::' + bvdId);
                            System.debug('Accounts::' + matchedAccounts.size());
                            //For all the accounts with same BVDID, Create Credit Score and Update Credit Limit + Risk Class
                            for(Account account: matchedAccounts) {
                                if(account.CurrencyIsoCode == currencyIsoCode) {
                                    celsrm__Credit_Score__c creditScore = new celsrm__Credit_Score__c();
                                    creditScore.CurrencyIsoCode = currencyIsoCode;
                                    creditScore.BvD_ID_Number__c = bvdId;
                                    creditScore.Account_Region__c = account.Region__c;
                                    creditScore.MORE_Evaluation_Score__c = bvdMap.get('moreEvaluationScore') != null ? (String) bvdMap.get('moreEvaluationScore'): null;
                                    creditScore.MORE_Evaluation_Year__c = bvdMap.get('moreEvaluationYear') != null ? Date.valueOf(String.valueOf(bvdMap.get('moreEvaluationYear'))): null;
                                    creditScore.MORE_Credit_Limit__c = bvdMap.get('moreEvaluationCurrent') != null ? Decimal.valueOf(String.valueOf(bvdMap.get('moreEvaluationCurrent'))): null;
                                    creditScore.MORE_Evaluation_Probability_of_Default__c = bvdMap.get('moreEvaluationProbOfDefault') != null ? Decimal.valueOf(String.valueOf(bvdMap.get('moreEvaluationProbOfDefault'))): null;
                                    creditScore.MORE_Evaluation_Confidence_Level__c = bvdMap.get('moreEvaluationConfifenceLevel') != null ? Decimal.valueOf(String.valueOf(bvdMap.get('moreEvaluationConfifenceLevel'))): null;
                                    creditScore.Reactive_Score__c = bvdMap.get('reactiveMoreEvaluationReactiveScore') != null ? String.valueOf(bvdMap.get('reactiveMoreEvaluationReactiveScore')): null;
                                    creditScore.Reactive_Date__c = bvdMap.get('reactiveMoreEvaluationReactiveDate') != null ? Date.valueOf(String.valueOf(bvdMap.get('reactiveMoreEvaluationReactiveDate'))): null;
                                    creditScore.Reactive_Credit_Limit__c = bvdMap.get('reactiveMoreCreditLimitCurrent') != null ? Decimal.valueOf(String.valueOf(bvdMap.get('reactiveMoreCreditLimitCurrent'))): null;
                                    creditScore.Reactive_Probability_of_Default__c = bvdMap.get('reactiveMoreEvaluationProbOfDefault') != null ? Decimal.valueOf(String.valueOf(bvdMap.get('reactiveMoreEvaluationProbOfDefault'))): null;
                                    creditScore.Reactive_Confidence_Level__c = bvdMap.get('reactiveMoreEvaluationConfidenceLevel') != null ? Decimal.valueOf(String.valueOf(bvdMap.get('reactiveMoreEvaluationConfidenceLevel'))): null;
                                    creditScore.Qualitative_Score__c = bvdMap.get('qualitativeScoreCurrent') != null ? String.valueOf(bvdMap.get('qualitativeScoreCurrent')): null;
                                    creditScore.Qualitative_Score_Date__c = bvdMap.get('qualitativeScoreDate') != null ? Date.valueOf(String.valueOf(bvdMap.get('qualitativeScoreDate'))): null;
                                    creditScore.Qualitative_Credit_Limit__c = bvdMap.get('qualitativereditLimitCurrent') != null ? Decimal.valueOf(String.valueOf(bvdMap.get('qualitativereditLimitCurrent'))): null;
                                    creditScore.Qualitative_score_Confidence_level__c = bvdMap.get('qualitativeScoreConfidenceLevel') != null ? Decimal.valueOf(String.valueOf(bvdMap.get('qualitativeScoreConfidenceLevel'))): null;
                                    creditScore.Current_Ratio__c = bvdMap.get('currentRatio') != null ? Decimal.valueOf(String.valueOf(bvdMap.get('currentRatio'))): null;
                                    creditScore.Liquidity_Ratio__c = bvdMap.get('liquidityRatio') != null ? Decimal.valueOf(String.valueOf(bvdMap.get('liquidityRatio'))): null;
                                    creditScore.Status__c = bvdMap.get('status') != null ? String.valueOf(bvdMap.get('status')): null;
                                    creditScore.Status_Date__c = bvdMap.get('statusDate') != null ? Date.valueOf(String.valueOf(bvdMap.get('statusDate'))): null;
                                    // << START - MM - FIN-8657 - Date of Incorporation: invalid date: Wed Aug 06 00:00:00 GMT 1102>>
                                    if(bvdMap.get('incorporationDate') != null) {
                                        Date incorporationDate = Date.valueOf(String.valueOf(bvdMap.get('incorporationDate')));
                                        if (incorporationDate.year() < 1700) {
                                            creditScore.Date_of_Incorporation__c = null;
                                        } else {
                                            creditScore.Date_of_Incorporation__c = incorporationDate;
                                        }
                                    } else {
                                        creditScore.Date_of_Incorporation__c = null;
                                    }
                                    // << END - MM - FIN-8657 - Date of Incorporation: invalid date: Wed Aug 06 00:00:00 GMT 1102>>
                                    creditScore.Registered_Capital__c = bvdMap.get('registeredCapital') != null ? Decimal.valueOf(String.valueOf(bvdMap.get('registeredCapital'))): null;
                                    creditScore.celsrm__Account__c = account.Id;
                                    creditScore.Payment_Behaviour__c = account.celsrm__Payment_Behaviour_Text__c;
                                    creditScore.Payment_Behaviour_Trend__c = account.celsrm__Payment_Behaviour_Trend__c;

                                    // Check for MORE data and process accordingly
                                    Decimal accountCreditLimit = null;
                                    String accountRiskClass = null;
                                    if(creditScore.Reactive_Date__c != null && creditScore.Reactive_Credit_Limit__c != null && creditScore.Reactive_Date__c >= Date.today().addYears(-2)) {
                                        accountCreditLimit = creditScore.Reactive_Credit_Limit__c;
                                    } else if(creditScore.MORE_Evaluation_Year__c != null && creditScore.MORE_Credit_Limit__c != null && creditScore.MORE_Evaluation_Year__c >= Date.today().addYears(-2)) {
                                        accountCreditLimit = creditScore.MORE_Credit_Limit__c;
                                    } else if(creditScore.Qualitative_Score_Date__c != null && creditScore.Qualitative_Credit_Limit__c != null && creditScore.Qualitative_Score_Date__c >= Date.today().addYears(-2)) {
                                        accountCreditLimit = creditScore.Qualitative_Credit_Limit__c;
                                    }

                                    if(accountCreditLimit != null) {
                                        if(account.celsrm__Payment_Behaviour_Text__c == 'On Time') {
                                            accountCreditLimit = accountCreditLimit * 1.2;
                                        } else if(account.celsrm__Payment_Behaviour_Text__c == 'Late' && account.celsrm__Payment_Behaviour_Trend__c == 'Payment Behaviour Improved') {
                                            accountCreditLimit = accountCreditLimit * 1.1;
                                        } else if(account.celsrm__Payment_Behaviour_Text__c == 'Very Late' && account.celsrm__Payment_Behaviour_Trend__c == 'Payment Behaviour Improved') {
                                            accountCreditLimit = accountCreditLimit * 1.0;
                                        } else if(account.celsrm__Payment_Behaviour_Text__c == 'Late' && account.celsrm__Payment_Behaviour_Trend__c == 'Payment Behaviour Declined') {
                                            accountCreditLimit = accountCreditLimit * 1.0;
                                        } else if(account.celsrm__Payment_Behaviour_Text__c == 'Very Late' && account.celsrm__Payment_Behaviour_Trend__c == 'Payment Behaviour Declined') {
                                            accountCreditLimit = accountCreditLimit * 1.0;
                                        }
                                    }

                                    if(creditScore.Reactive_Date__c != null && creditScore.Reactive_Score__c != null &&  creditScore.Reactive_Date__c >= Date.today().addYears(-2) && RiskClassCheckRuleMappingService.MORE_RISK_CLASS_MAPPING.containsKey(creditScore.Reactive_Score__c)) {
                                    accountRiskClass = RiskClassCheckRuleMappingService.MORE_RISK_CLASS_MAPPING.get(creditScore.Reactive_Score__c );
                                    } else if(creditScore.MORE_Evaluation_Year__c != null && creditScore.MORE_Evaluation_Score__c != null && creditScore.MORE_Evaluation_Year__c >= Date.today().addYears(-2) && RiskClassCheckRuleMappingService.MORE_RISK_CLASS_MAPPING.containsKey(creditScore.MORE_Evaluation_Score__c)) {
                                        accountRiskClass = RiskClassCheckRuleMappingService.MORE_RISK_CLASS_MAPPING.get(creditScore.MORE_Evaluation_Score__c);
                                    } else if(creditScore.Qualitative_Score_Date__c != null && creditScore.Qualitative_Score__c != null && creditScore.Qualitative_Score_Date__c >= Date.today().addYears(-2) && RiskClassCheckRuleMappingService.QUALITATIVE_RISK_CLASS_MAPPING.containsKey(creditScore.Qualitative_Score__c)) {
                                        accountRiskClass = RiskClassCheckRuleMappingService.QUALITATIVE_RISK_CLASS_MAPPING.get(creditScore.Qualitative_Score__c);
                                    }
                                    if(accountCreditLimit != null || accountRiskClass != null) {
                                        account.Moody_s_Change_Identified__c = false;

                                        // << START - Ticket #948 - Credit Score Comparison Flag >>
                                        // Evaluate BEFORE Moody_s_Risk_Class__c / Moody_s_Credit_Limit__c are overwritten below,
                                        // so the service can read the current (soon-to-be-previous) values. An unmapped Risk
                                        // Class is handled internally by the service (treated as neutral, not thrown), so no
                                        // extra try/catch is needed here.
                                        CreditScoreComparisonService.applyComparisonAndRollValues(account, accountRiskClass, accountCreditLimit);
                                        // << END - Ticket #948 - Credit Score Comparison Flag >>

                                        if(accountCreditLimit != null) {
                                            account.Moody_s_Credit_Limit__c = accountCreditLimit;
                                            creditScore.Moody_s_Credit_Limit__c = accountCreditLimit;
                                        }
                                        if(accountRiskClass != null) {
                                            account.Moody_s_Risk_Class__c = accountRiskClass;
                                            creditScore.Moody_s_Risk_Class__c = accountRiskClass;

                                            //Update Risk Class and Check Rule for account
                                            // Refactor: extracted to RiskClassCheckRuleMappingService, shared with
                                            // CreditReviewParameters.initiateCreditReview() (same mapping tables /
                                            // Z08-Z02 exclusion / Z07-Z06 protection logic). Kept inline here
                                            // (rather than deferred to SiblingCreditDataPropagationService.propagate())
                                            // because the celsrm__Credit_Review__c built further below, in this SAME
                                            // loop iteration, reads account.celsrm__Risk_Class__c — it needs the
                                            // freshly recomputed value, not the pre-Moody's one. Sibling propagation
                                            // still happens once, after this loop — see propagateToSiblingsOnly below.
                                            RiskClassCheckRuleMappingService.MappingResult mapped =
                                                RiskClassCheckRuleMappingService.applyRiskClassAndCheckRule(account, accountRiskClass);

                                            if(mapped.applied && (mapped.riskClassChanged || mapped.checkRuleChanged)) {
                                                accToUpdateProfileData.add(account);
                                            }
                                        }
                                        accToUpdate.add(account);
                                    } else if(account.Moody_s_Change_Identified__c == true) {
                                        account.Moody_s_Change_Identified__c = false;
                                        accToUpdate.add(account);
                                    }
                                    csToInsert.add(creditScore);


                                    if(allowCreateCr == true) {
                                        celsrm__Credit_Review__c creditReviewObj = new celsrm__Credit_Review__c();
                                        creditReviewObj.celsrm__Account__c = account.Id;
                                        creditReviewObj.BvD_ID_Number__c = bvdId;
                                        creditReviewObj.celsrm__Recommended_Credit_Limit__c = account.Recommended_Credit_Limit__c ;
                                        creditReviewObj.celsrm__Requested_Credit_Limit__c = account.Recommended_Credit_Limit__c;
                                        creditReviewObj.Account_Region__c = account.Region__c;
                                        if(conversionRateMap != null && conversionRateMap.containsKey(account.CurrencyIsoCode)) {
                                            creditReviewObj.Requested_Credit_Limit_EUR__c = account.Recommended_Credit_Limit__c / conversionRateMap.get(account.CurrencyIsoCode);
                                        } else {
                                            creditReviewObj.Requested_Credit_Limit_EUR__c = account.Recommended_Credit_Limit__c;
                                        }
                                        
                                        creditReviewObj.celsrm__System_Credit_Limit__c = account.Recommended_Credit_Limit__c;
                                        creditReviewObj.celsrm__Status__c = '10';
                                        if(this.isPeriodic == true) {
                                            creditReviewObj.celsrm__Model_Type__c = 'Periodic Review';
                                        } else {
                                            creditReviewObj.celsrm__Model_Type__c = 'Recalculation';
                                        }
                                        String creditGroup = account.celsrm__Credit_Group__c;
                                        if(creditGroup != null) {
                                            List<String> parts = creditGroup.split(' - ', 2);
                                            if(parts.size() > 1) {
                                                creditGroup = parts[1];
                                            }
                                        }
                                        creditReviewObj.celsrm__Credit_Group__c = creditGroup;
                                        creditReviewObj.Expected_Turnover__c = account.Expected_Turnover__c;
                                        String riskClass = account.celsrm__Risk_Class__c;
                                        if(account.celsrm__Risk_Class__c != null) {
                                            List<String> parts = riskClass.split(' - ', 2);
                                            if(parts.size() > 1) {
                                                riskClass = parts[1];
                                            }
                                        }
                                        creditReviewObj.celsrm__Risk_Class__c = riskClass;
                                        creditReviewObj.Credit_Limit__c = account.celsrm__Credit_Limit__c;
                                        creditReviewObj.Credit_Exposure__c = account.Credit_Exposure__c ;
                                        creditReviewObj.Payment_Terms_Days__c = account.Payment_Term_Days__c;
                                        creditReviewObj.CurrencyIsoCode = account.CurrencyIsoCode ;
                                        creditReviewObj.Requested_Valid_To_Date__c = Date.today().addDays(365);


                                        //Moody's Parameters
                                        creditReviewObj.MORE_Evaluation_Score__c = creditScore.MORE_Evaluation_Score__c;
                                        creditReviewObj.MORE_Evaluation_Year__c = creditScore.MORE_Evaluation_Year__c;
                                        creditReviewObj.MORE_Credit_Limit__c = creditScore.MORE_Credit_Limit__c;
                                        creditReviewObj.MORE_Evaluation_Probability_of_Default__c = creditScore.MORE_Evaluation_Probability_of_Default__c;
                                        creditReviewObj.MORE_Evaluation_Confidence_Level__c = creditScore.MORE_Evaluation_Confidence_Level__c;
                                        creditReviewObj.Reactive_Score__c = creditScore.Reactive_Score__c;
                                        creditReviewObj.Reactive_Date__c = creditScore.Reactive_Date__c;
                                        creditReviewObj.Reactive_Credit_Limit__c = creditScore.Reactive_Credit_Limit__c;
                                        creditReviewObj.Reactive_Probability_of_Default__c = creditScore.Reactive_Probability_of_Default__c;
                                        creditReviewObj.Reactive_Confidence_Level__c     = creditScore.Reactive_Confidence_Level__c;
                                        creditReviewObj.Qualitative_Score__c     = creditScore.Qualitative_Score__c;
                                        creditReviewObj.Qualitative_Score_Date__c    = creditScore.Qualitative_Score_Date__c;
                                        creditReviewObj.Qualitative_Credit_Limit__c  = creditScore.Qualitative_Credit_Limit__c;
                                        creditReviewObj.Qualitative_score_Confidence_level__c    = creditScore.Qualitative_score_Confidence_level__c;
                                        creditReviewObj.Current_Ratio__c     = creditScore.Current_Ratio__c;
                                        creditReviewObj.Liquidity_Ratio__c   = creditScore.Liquidity_Ratio__c;
                                        creditReviewObj.Status_Moodys__c = creditScore.Status__c;
                                        creditReviewObj.Status_Date_Moody__c = creditScore.Status_Date__c;
                                        creditReviewObj.Date_of_Incorporation__c =  creditScore.Date_of_Incorporation__c;
                                        creditReviewObj.Moody_s_Credit_Limit__c = creditScore.Moody_s_Credit_Limit__c;
                                        creditReviewObj.Registered_Capital__c = creditScore.Registered_Capital__c;
                                        creditReviewObj.celsrm__Notes__c = 'Auto Generated Credit Limit Request for Manual Approval';
                                        crToInsert.add(creditReviewObj);
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Refactor: propagate BvD ID / Moody's Risk Class / Moody's Credit Limit to
            // sibling Credit Segments (same AccountNumber). Source accounts (accToUpdate)
            // already had their own celsrm__Risk_Class__c / celsrm__Check_Rule__c recomputed
            // inline above; siblings' own recompute happens reactively via the
            // "Risk Class and Check Rule 2" Flow once they're saved below.
            List<Account> siblingsToUpdate = SiblingCreditDataPropagationService.propagateToSiblingsOnly(accToUpdate);
            if (!siblingsToUpdate.isEmpty()) {
                accToUpdate.addAll(siblingsToUpdate);
            }

            // << START - MM - FIN-8659 - Moody's Change Identified not marked as false>>
            if(accToUpdateProfileData.size() > 0) {
                if(!Test.isRunningTest()) {
                    updateProfileData(accToUpdateProfileData);
                }
            }
            // << END - MM - FIN-8659 - Moody's Change Identified not marked as false>>
            if(crToInsert.size() > 0) {
                insert crToInsert;
                for (Integer i = 0; i < crToInsert.size(); i++) {
                    csToInsert[i].celsrm__Credit_Review__c = crToInsert[i].Id;
                }
            
            }

            if(csToInsert.size() > 0) {
                insert csToInsert;
            }
            
            if(accToUpdate.size() > 0) {
                // << START - MM - FIN-10145 - Fix Too many queueable jobs error if allowed for system admin >>
                UpdateProfileDataInSourceSystemService.skipProfileDataSync = true;
                update accToUpdate;
                UpdateProfileDataInSourceSystemService.skipProfileDataSync = false;
                // << END - MM - FIN-10145 - Fix Too many queueable jobs error if allowed for system admin >>
            }

            if(crToInsert.size() > 0) {
                List<celsrm__Credit_Review__c> crToUpdate = new List<celsrm__Credit_Review__c>();
                List<String> crIdsForCreditLimitUpdates = new List<String>();
                for(celsrm__Credit_Review__c creditReviewObj: crToInsert) {
                    if(creditReviewObj.Requested_Credit_Limit_EUR__c <= 50000) {
                        creditReviewObj.celsrm__Approved_Credit_Limit__c = creditReviewObj.celsrm__Requested_Credit_Limit__c;
                        creditReviewObj.Approved_Valid_To_Date__c = creditReviewObj.Requested_Valid_To_Date__c;
                        creditReviewObj.celsrm__Status__c = '11';
                        crToUpdate.add(creditReviewObj);
                        crIdsForCreditLimitUpdates.add(creditReviewObj.Id);
                    } else if(creditReviewObj.Requested_Credit_Limit_EUR__c > 50000 && creditReviewObj.celsrm__Requested_Credit_Limit__c <= creditReviewObj.Moody_s_Credit_Limit__c) {
                        creditReviewObj.celsrm__Approved_Credit_Limit__c = creditReviewObj.celsrm__Requested_Credit_Limit__c;
                        creditReviewObj.Approved_Valid_To_Date__c = creditReviewObj.Requested_Valid_To_Date__c;
                        creditReviewObj.celsrm__Status__c = '12';
                        crToUpdate.add(creditReviewObj);
                        crIdsForCreditLimitUpdates.add(creditReviewObj.Id);
                    }
                }

                if(crToUpdate.size() > 0) {
                    update crToUpdate;
                    // << START - MM - FIN-10145 - Fix Too many queueable jobs error by deferring UpdateLimitInSourceSystemService to Finalizer >>
                    finalizer.creditReviewIds = crIdsForCreditLimitUpdates;
                    // << END - MM - FIN-10145 - Fix Too many queueable jobs error by deferring UpdateLimitInSourceSystemService to Finalizer >>
                }
            }

            upsert MoodysAuth;
            
        } catch (Exception e) {
            System.debug('Exception: ' + e.getMessage());
        }
    }

    // << START - MM - FIN-8659 - Moody's Change Identified not marked as false>>
    @TestVisible
    public void updateProfileData(List<Account> accounts) {
    // << END - MM - FIN-8659 - Moody's Change Identified not marked as false>>
        Map<String, List<Account>> accountKeyObjMap = new Map<String, List<Account>>();
        List<Map<String, Object>> accList = new List<Map<String, Object>>();
        Map<String, Object> requestBodyMap = new Map<String, Object>();
        List<Account> accToBeUpdated = new List<Account>();
        String webhookURL = Credit_Configuration__c.getOrgDefaults().Update_Profile_Data_Action_Flow_Webhook__c;
        // << START - MM - FIN-9224 - [Akzonobel] [Credit] Propagate the profile data updates to all accounts>>
        List<Id> accountIdTobePropagated = new List<Id>();
        // << END - MM - FIN-9224 - [Akzonobel] [Credit] Propagate the profile data updates to all accounts>>
        if(webhookURL != null && webhookURL != '') {
            for (Account acc : accounts) {
                String checkRule = acc.celsrm__Check_Rule__c;
                if(checkRule != null && checkRule != '') {
                    List<String> parts = checkRule.split(' ', 2);
                    checkRule = parts[0];
                } else {
                    checkRule = '';
                }
                String riskClass = (String)acc.celsrm__Risk_Class__c;
                if(riskClass != null) {
                    List<String> parts = riskClass.split(' ', 2);
                    if(parts.size() > 1) {
                        riskClass = parts[0];
                    }
                }
                String creditGroup = acc.celsrm__Credit_Group__c;
                if(creditGroup != null) {
                    List<String> parts = creditGroup.split(' ', 2);
                    if(parts.size() > 1) {
                        creditGroup = parts[0];
                    }
                }

                String key = acc.AccountNumber + '-' + checkRule + '-' + creditGroup + '-' + riskClass;
                if(accountKeyObjMap.containsKey(key)) {
                    List<Account> accountList = accountKeyObjMap.get(key);
                    accountList.add(acc);
                    accountKeyObjMap.put(key, accountList);
                } else {
                    List<Account> accountList = new List<Account>();
                    accountList.add(acc);
                    accountKeyObjMap.put(key, accountList);


                    // Call only once per partner
                    Map<String, Object> map1 = new Map<String, Object>();
                    map1.put('creditGroup', creditGroup);
                    map1.put('riskClass', riskClass);
                    map1.put('checkRule', checkRule);
                    map1.put('creditControlArea', acc.celsrm__Credit_Control_Area__c);
                    map1.put('accountNumber', acc.AccountNumber);
                    accList.add(map1);
                }
            }
            requestBodyMap.put('updateRequests', accList);

            if (accList.size() > 0) {
                try {
                    
                    HttpRequest req = new HttpRequest();
                    req.setEndpoint('callout:CelonisEMS' + '/' + webhookURL);
                    req.setMethod('POST');
                    req.setHeader('Content-Type', 'application/json');
                    String requestBody = JSON.serialize(requestBodyMap);
                    System.debug(requestBody);
                    req.setBody(requestBody);
                    req.setTimeout(120000);

                    Http http = new Http();
                    HttpResponse res = http.send(req);
                    /**
                     * 401: {"status":"Error", "details":"Please make sure you have provided correct Authentication token"}
                     * 400: {"status":"Error", "details":"Required field is misisng"}
                     * 200: {"status":"Error","details":{"updateResponse":[{"PARTNER":"1000185253","STATUS_MSG":"Update successful"}]}}
                     */
                    if (res.getStatusCode() == 200) {
                        String responseBody = res.getBody();
                        if(responseBody == 'Accepted') {
                            String errorMessage = 'Failed to update in CFIN. Error: Something went wrong! (Action flow could be deactivated)';
                            for(Account acc : accounts) {
                                acc.Sync_Profile_Data_Message__c = errorMessage;
                                accToBeUpdated.add(acc);
                            }
                        } else {
                            List<String> accountKeysGotResponse = new List<String>();
                            Map<String, Object> parsedResponse = (Map<String, Object>)JSON.deserializeUntyped(responseBody);
                            Map<String, Object> detailsMap = (Map<String, Object>)parsedResponse.get('details');
                            List<Object> updateResponse = (List<Object>)detailsMap.get('updateResponse');
    
                            for (Object obj : updateResponse) {
                                Map<String, Object> objMap = (Map<String, Object>)obj;
                                String accountNumber = (String)objMap.get('PARTNER');
                                String checkRule = (String)objMap.get('CHECK_RULE');
                                String creditGroup = (String)objMap.get('CREDIT_GROUP');
                                String riskClass = (String)objMap.get('RISK_CLASS');
                                String statusMsg = (String)objMap.get('STATUS_MSG');
                                String key = accountNumber + '-' + checkRule + '-' + creditGroup + '-' + riskClass;
                                if(accountKeyObjMap.containsKey(key)) {
                                    accountKeysGotResponse.add(key);
                                    List<Account> accountList = accountKeyObjMap.get(key);                                
                                    for(Account account: accountList) {
                                        if(statusMsg == 'Update successful'){
                                            account.Sync_Profile_Data_In_Source_System_At__c = DateTime.now();
                                            account.Sync_Profile_Data_Message__c = statusMsg;
                                            // << START - MM - FIN-9224 - [Akzonobel] [Credit] Propagate the profile data updates to all accounts>>
                                            accountIdTobePropagated.add(account.Id);
                                            // << END - MM - FIN-9224 - [Akzonobel] [Credit] Propagate the profile data updates to all accounts>>
                                        } else{
                                            account.Sync_Profile_Data_Message__c = statusMsg;
                                        }
                                        accToBeUpdated.add(account);
                                    }
                                }
                            }
                            for(String accountKey: accountKeyObjMap.keySet()) {
                                if(!accountKeysGotResponse.contains(accountKey)) {
                                    List<Account> accountList = accountKeyObjMap.get(accountKey);                                
                                    for(Account account: accountList) {
                                        account.Sync_Profile_Data_Message__c = 'Failed to update in CFIN. Error: RFC Module Failed';
                                        accToBeUpdated.add(account);
                                    }
                                }
                            }
                        }
                    } else if(res.getStatusCode() == 401 || res.getStatusCode() == 501 || res.getStatusCode() == 400) {
                        String responseBody = res.getBody();
                        Map<String, Object> parsedResponse = (Map<String, Object>)JSON.deserializeUntyped(responseBody);
                        String errorMessage = 'Failed to update in CFIN. Error: ' + (String)parsedResponse.get('details');
                        for(Account acc : accounts) {
                            acc.Sync_Profile_Data_Message__c = errorMessage;
                            accToBeUpdated.add(acc);
                        }
                    } else if(res.getStatusCode() == 500) {
                        String errorMessage = 'Failed to update in CFIN. Error: Internal Server Error';
                        for(Account acc : accounts) {
                            acc.Sync_Profile_Data_Message__c = errorMessage;
                            accToBeUpdated.add(acc);
                        }
                    } else if(res.getStatusCode() == 429) {
                        String errorMessage = 'Failed to update in CFIN. Error: Webhook rate limit';
                        for(Account acc : accounts) {
                            acc.Sync_Profile_Data_Message__c = errorMessage;
                            accToBeUpdated.add(acc);
                        }
                    } else {
                        String errorMessage = 'Failed to update in CFIN. Error: ' + String.valueOf(res.getStatusCode());
                        for(Account acc : accounts) {
                            acc.Sync_Profile_Data_Message__c = errorMessage;
                            accToBeUpdated.add(acc);
                        }
                    }
                } catch (Exception e) {
                    System.debug('After Response timestamp: ' + System.now());
                    String errorMessage = 'Failed to update in CFIN. Exception occured: ' + e.getMessage();
                    for(Account acc : accounts) {
                        acc.Sync_Profile_Data_Message__c = errorMessage;
                        accToBeUpdated.add(acc);
                    }
                }
            }

        } else {
            for(Account acc : accounts) {
                String errorMessage = 'Failed to update in CFIN. Error: Webhook URL is not configured';
                acc.Sync_Profile_Data_Message__c = errorMessage;
                accToBeUpdated.add(acc);
            }
        }
        // << START - MM - FIN-8659 - Moody's Change Identified not marked as false>>
        if(accToBeUpdated.size() > 0) {
            update accToBeUpdated;
        }
        // << END - MM - FIN-8659 - Moody's Change Identified not marked as false>>
        // << START - MM - FIN-9224 - [Akzonobel] [Credit] Propagate the profile data updates to all accounts>>
        if(accountIdTobePropagated.size() > 0) {
            PropagateProfileDataToAccounts batch = new PropagateProfileDataToAccounts(accountIdTobePropagated);
            Database.executeBatch(batch, 25);
        }
        // << END - MM - FIN-9224 - [Akzonobel] [Credit] Propagate the profile data updates to all accounts>>
    }

    public List<Map<Object, Object>> getBvDInfoForMultipleAccounts(Set<String> bvdIds, String currencyIsoCode, String accessToken) {
        Map<String, Object> requestBody = new Map<String, Object>();
        if(currencyIsoCode == null || currencyIsoCode == '') {
            currencyIsoCode = 'EUR';
        }
        // WHERE clause with dynamic BvDID
        Map<String, List<String>> whereClause = new Map<String, List<String>>();
        whereClause.put('BvDID', new List<String>(bvdIds));
        
        // Construct SELECT section of the body
        List<Object> selectList = new List<Object>{
            new Map<String, Object>{
                'NAME' => new Map<String, String>{ 
                    'AS' => 'NAME' 
                }
            },
            new Map<String, Object>{
                'BVD_ID_NUMBER' => new Map<String, String>{
                    'AS' => 'BVD_ID_NUMBER' 
                }
            }
            ,
            new Map<String, Object>{
                'EMPL' => new Map<String, String>{ 
                    'AS' => 'EMPL'
                }
            },
            new Map<String, Object>{
                'MORRAT' => new Map<String, Object>{
                    'INDEXORYEAR' => '0',
                    'AS' => 'MORRAT' 
                }
            },
            new Map<String, Object>{
                'MORE_YEAR' => new Map<String, Object>{
                    'INDEXORYEAR' => '0', 
                    'AS' => 'MORE_YEAR' 
                }
            },
            new Map<String, Object>{ 
                'MORCREDLIMIT' => new Map<String, Object>{ 
                    'FILTERS' => 'Filter.Name=FinancialStrengthFilter;FinancialStrengthFilter.Mode=FSSummary', 
                    'CURRENCY' => currencyIsoCode, 
                    'UNIT' => 0, 
                    'INDEXORYEAR' => '0', 
                    'AS' => 'MORCREDLIMIT' 
                } 
            },
            new Map<String, Object>{ 
                'MORDEF' => new Map<String, Object>{ 
                    'INDEXORYEAR' => '0', 
                    'AS' => 'MORDEF' 
                } 
            },
            new Map<String, Object>{ 
                'MORCONF' => new Map<String, Object>{ 
                    'INDEXORYEAR' => '0', 
                    'AS' => 'MORCONF' 
                } 
            },
            new Map<String, Object>{ 
                'REACMORRAT' => new Map<String, Object>{ 
                    'INDEXORYEAR' => '0', 
                    'AS' => 'REACMORRAT' 
                } 
            },
            new Map<String, Object>{ 
                'REACMORE_DATE' => new Map<String, Object>{ 
                    'INDEXORYEAR' => '0', 
                    'AS' => 'REACMORE_DATE' 
                } 
            },
            new Map<String, Object>{ 
                'REACMORCREDLIMIT' => new Map<String, Object>{ 
                    'CURRENCY' => currencyIsoCode, 
                    'UNIT' => 0, 
                    'INDEXORYEAR' => '0', 
                    'AS' => 'REACMORCREDLIMIT' 
                } 
            },
            new Map<String, Object>{ 
                'REACMORDEF' => new Map<String, Object>{ 
                    'INDEXORYEAR' => '0', 
                    'AS' => 'REACMORDEF' 
                } 
            },
            new Map<String, Object>{ 
                'REACMORCONF' => new Map<String, Object>{ 
                    'INDEXORYEAR' => '0', 
                    'AS' => 'REACMORCONF' 
                } 
            },
            new Map<String, Object>{ 
                'MODEFINNF' => new Map<String, Object>{ 
                    'FILTERS' => 'Filter.Name=FinancialStrengthFilter;FinancialStrengthFilter.Mode=FSSummary', 
                    'INDEXORYEAR' => '0', 
                    'AS' => 'MODEFINNF' 
                } 
            },
            new Map<String, Object>{ 
                'MODEFINNFDATE' => new Map<String, Object>{ 
                    'INDEXORYEAR' => '0', 
                    'AS' => 'MODEFINNFDATE' 
                } 
            },
            new Map<String, Object>{ 
                'MODEFINNF_CreditLimitValue' => new Map<String, Object>{ 
                    'FILTERS' => 'Filter.Name=FinancialStrengthFilter;FinancialStrengthFilter.Mode=FSSummary', 
                    'CURRENCY' => currencyIsoCode, 
                    'UNIT' => 0, 
                    'INDEXORYEAR' => '0', 
                    'AS' => 'MODEFINNF_CreditLimitValue' 
                } 
            },
            new Map<String, Object>{ 
                'MODEFINNFCONF' => new Map<String, Object>{ 
                    'INDEXORYEAR' => '0', 
                    'AS' => 'MODEFINNFCONF' 
                } 
            },
            new Map<String, Object>{ 
                'CURR' => new Map<String, Object>{ 
                    'UNIT' => 0, 
                    'INDEXORYEAR' => '0', 
                    'AS' => 'CURR' 
                } 
            },
            new Map<String, Object>{ 
                'LIQR' => new Map<String, Object>{ 
                    'MODELID' => 'IND', 
                    'UNIT' => 0, 
                    'INDEXORYEAR' => '0', 
                    'AS' => 'LIQR' 
                } 
            },
            new Map<String, Object>{ 
                'STATUS' => new Map<String, Object>{ 
                    'LIMIT' => 1, 
                    'AS' => 'STATUS' 
                } 
            },
            new Map<String, Object>{ 
                'STATUS_DATE' => new Map<String, Object>{ 
                    'LIMIT' => 1, 
                    'AS' => 'STATUS_DATE' 
                } 
            },
            new Map<String, Object>{ 
                'INCORPORATION_DATE' => new Map<String, Object>{ 
                    'AS' => 'INCORPORATION_DATE' 
                } 
            },
            new Map<String, Object>{ 
                'CAPI' => new Map<String, Object>{ 
                    'CURRENCY' => currencyIsoCode,
                    'MODELID' => 'IND', 
                    'UNIT' => 0, 
                    'INDEXORYEAR' => '0', 
                    'AS' => 'CAPI' 
                } 
            }
        };
        
        // Add WHERE and SELECT sections to the request body
        requestBody.put('WHERE', new List<Map<String, List<String>>>{ whereClause });
        requestBody.put('select', selectList);
        
        // Add RANGE and ORDERBY
        requestBody.put('RANGE', new Map<String, Integer>{ 'MAX' => 100, 'OFFSET' => 0 });
        requestBody.put('ORDERBY', new Map<String, String>{ 'DESC' => 'OPRE' });

        // Convert the request body to JSON
        String jsonBody = JSON.serialize(requestBody);
        System.debug('RequestBody::' + jsonBody);


        Http h = new Http();
        HttpRequest req = new HttpRequest();
        req.setHeader('Authorization', 'Bearer ' + accessToken);
        req.setEndpoint('callout:Moodys_Integration' + '/companies/data');
        req.setMethod('POST');
        req.setBody(jsonBody);
        req.setTimeout(120000);
        System.debug('Request>>>' + req);
        HttpResponse res = h.send(req);
        System.debug('res>>>>>'+ res);
        if (res.getStatusCode() == 200) {
            return getBvdDetailsForMultipleAccounts(res);
        }
        return null;

    }

    public List<Map<Object, Object>> getBvdDetailsForMultipleAccounts(HttpResponse response){
        String responseBody = response.getBody();
        System.debug('ResponseBody::' + responseBody);
        Map<String, Object> parsedResponseList = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
        List<Object> dataList = (List<Object>) parsedResponseList.get('Data');
        List<Map<Object, Object>> bvdDetails = new List<Map<Object, Object>>();
        if(dataList.size() > 0) {
            for (Object data: dataList) {
                Map<String, Object> bvdMap = (Map<String, Object>) data;
    
                Map<Object, Object> inMap = new Map<Object, Object>();
                inMap.put('bvdId', bvdMap.get('BVD_ID_NUMBER') != null ? (String) bvdMap.get('BVD_ID_NUMBER'): null);
                inMap.put('moreEvaluationScore', bvdMap.get('MORRAT') != null ? (String) bvdMap.get('MORRAT'): null);
                inMap.put('moreEvaluationYear', bvdMap.get('MORE_YEAR') != null ? DateTime.valueOf(((String) bvdMap.get('MORE_YEAR')).replaceAll('T', ' ')).date(): null);
                inMap.put('moreEvaluationCurrent', bvdMap.get('MORCREDLIMIT') != null ? Decimal.valueOf(String.valueOf(bvdMap.get('MORCREDLIMIT'))): null); //MORE credit limit - current
                inMap.put('moreEvaluationProbOfDefault', bvdMap.get('MORDEF') != null ? Decimal.valueOf(String.valueOf(bvdMap.get('MORDEF'))): null);   //MORE evaluation - Probability of default
                inMap.put('moreEvaluationConfifenceLevel', bvdMap.get('MORCONF') != null ? Decimal.valueOf(String.valueOf(bvdMap.get('MORCONF'))): null);   //MORE evaluation - Confidence level
                inMap.put('reactiveMoreEvaluationReactiveScore', bvdMap.get('REACMORRAT') != null ? (String) bvdMap.get('REACMORRAT'): null);   //Reactive MORE evaluation - Reactive score
                inMap.put('reactiveMoreEvaluationReactiveDate', bvdMap.get('REACMORE_DATE') != null ? DateTime.valueOf(((String) bvdMap.get('REACMORE_DATE')).replaceAll('T', ' ')).date(): null);  //Reactive MORE evaluation - Reactive date
                inMap.put('reactiveMoreCreditLimitCurrent', bvdMap.get('REACMORCREDLIMIT') != null ? Decimal.valueOf(String.valueOf(bvdMap.get('REACMORCREDLIMIT'))): null);    //Reactive MORE credit limit - current
                inMap.put('reactiveMoreEvaluationProbOfDefault', bvdMap.get('REACMORDEF') != null ? Decimal.valueOf(String.valueOf(bvdMap.get('REACMORDEF'))): null);   //Reactive MORE evaluation - Reactive probability of default
                inMap.put('reactiveMoreEvaluationConfidenceLevel', bvdMap.get('REACMORCONF') != null ? Decimal.valueOf(String.valueOf(bvdMap.get('REACMORCONF'))): null);   //Reactive MORE evaluation - Reactive confidence level
                inMap.put('qualitativeScoreCurrent', bvdMap.get('MODEFINNF') != null ? (String) bvdMap.get('MODEFINNF'): null); //Qualitative score – current
                inMap.put('qualitativeScoreDate', bvdMap.get('MODEFINNFDATE') != null ? DateTime.valueOf(((String) bvdMap.get('MODEFINNFDATE')).replaceAll('T', ' ')).date(): null);    //Qualitative score - Date
                inMap.put('qualitativereditLimitCurrent', bvdMap.get('MODEFINNF_CreditLimitValue') != null ? Decimal.valueOf(String.valueOf(bvdMap.get('MODEFINNF_CreditLimitValue'))): null);  //Qualitative credit limit – current
                inMap.put('qualitativeScoreConfidenceLevel', bvdMap.get('MODEFINNFCONF') != null ? Decimal.valueOf(String.valueOf(bvdMap.get('MODEFINNFCONF'))): null); //Qualitative score - Confidence level (%)
                inMap.put('currentRatio', bvdMap.get('CURR') != null ? Decimal.valueOf(String.valueOf(bvdMap.get('CURR'))): null);   //Current ratio
                inMap.put('liquidityRatio', bvdMap.get('LIQR') != null ? Decimal.valueOf(String.valueOf(bvdMap.get('LIQR'))): null); //Liquidity ratio
                inMap.put('status', bvdMap.get('STATUS') != null && ((List<Object>)bvdMap.get('STATUS')).size() > 0 ? (String) (((List<Object>)bvdMap.get('STATUS'))[0]): null); //Status
                inMap.put('statusDate', bvdMap.get('STATUS_DATE') != null && ((List<Object>)bvdMap.get('STATUS_DATE')).size() > 0 ? DateTime.valueOf(((String) (((List<Object>)bvdMap.get('STATUS_DATE'))[0])).replaceAll('T', ' ')).date(): null); //Status
                inMap.put('incorporationDate', bvdMap.get('INCORPORATION_DATE') != null ? DateTime.valueOf(((String) bvdMap.get('INCORPORATION_DATE')).replaceAll('T', ' ')).date(): null);
                inMap.put('registeredCapital', bvdMap.get('CAPI') != null ? Decimal.valueOf(String.valueOf(bvdMap.get('CAPI'))): null);  //registeredCapital
    
                bvdDetails.add(inMap);
            }
        }
        return bvdDetails;
    }

    // << START - MM - FIN-8639 - Credit scores not generated in Sailfin after monitor call>>
    public static void GetMoodysData(List<String> accounts, Boolean allowCreateCr, Boolean isPeriodic) {
        System.enqueueJob(new GetMoodysDataService(accounts, allowCreateCr, isPeriodic));
    }
    // << END - MM - FIN-8639 - Credit scores not generated in Sailfin after monitor call>>
}