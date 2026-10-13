global with sharing class CreditReviewParameters implements celsrm.GOGIScreenCustomLogic {

    global Map<Object, Object> invoke(String functionName, Map<Object, Object> inMap) {
        try {
            System.debug('LOGTRACE >>> invoke() called with functionName=' + functionName + ' | inMap=' + inMap);
            if (functionName == 'initiateCreditReview') {
                inMap = initiateCreditReview(inMap);
            } 
            // else if (functionName == 'updateDUNSNumber') {
            //     inMap = updateDUNSNumber(inMap);
            // } 
            else if (functionName == 'updateBvdId') {
                inMap = updateBvdId(inMap);
            } 
            else if (functionName == 'createCreditReviewRecord') {
                inMap = createCreditReviewRecord(inMap);
            } 
            // else if (functionName == 'getCreditScoreData') {
            //     inMap = getCreditScoreData(inMap);
            // } else if (functionName == 'saveCreditScoreData') {
            //     inMap = saveCreditScoreData(inMap);
            // } else if (functionName == 'getCreditScoreDataAccount') {
            //     inMap = getCreditScoreDataAccount(inMap);
            // } 
            else if (functionName == 'calculateRequestedCreditLimitEUR') {
                inMap = calculateRequestedCreditLimitEUR(inMap);
            // } 
            //-- Starts |FIN-7510| Changed by Asera | 08 JAN 2026 --//
            } else if (functionName == 'onLoadInitiateCreditReview') {
                inMap = onLoadInitiateCreditReview(inMap);
            }
            //-- End |FIN-7510| Changed by Asera | 08 JAN 2026 --//
            System.debug('LOGTRACE >>> invoke() returning inMap=' + inMap);
        } catch (Exception ex) {
            System.debug('Class: CreditReviewParameters | Linenumber: ' + ex.getLineNumber() + ' | Message: ' + ex.getMessage());
        }
        return inMap;
    }
    //-- Starts |FIN-7510| Changed by Asera | 08 JAN 2026 --//
    public static Map<Object, Object> onLoadInitiateCreditReview(Map<Object, Object> inMap){
        try{
            System.debug('Inside onLoadInitiateCreditReview >>>>');
            Id AccountId = (Id) inMap.get('Id');
            Account account = [SELECT Id, Name, AccountNumber, Duns_Number__c FROM ACCOUNT WHERE Id =: AccountId];
            try {
                Map<String, Object> metadataMap = new Map<String, Object>{
                    'AccountNumber' => account.AccountNumber,
                    'companyDunsNumber' => account.Duns_Number__c
                };
                String metadataJson = JSON.serialize(metadataMap);
                Map<String, Object> inputParams = new Map<String, Object>{
                    'userId' => UserInfo.getUserId(),
                    'pageScreenName' => 'Account Credit: Initiate Review',
                    'actionPerformed' => false,
                    'actionTakenTime' => null,
                    'accountId' => AccountId,
                    'transactionId' => null,
                    'disputeId' => null,
                    'additionalMetadata' => metadataJson
                };
                Id activityId = celsrm.SRMUtilityController.logActivity(JSON.serialize(inputParams));
                System.debug('Full activity : ' + activityId);
                inMap.put('activityLogId', activityId);
            } catch (Exception e) {
                System.debug('Error logging activity: ' + e.getMessage() + ' ' + e.getLineNumber());
                inMap.put('ggErrorMessage', e.getMessage() + ' ' + e.getLineNumber());
            } 
        } catch(Exception ex){
            System.debug('Method: onLoadFunction | Linenumber: ' + ex.getLineNumber() + ' | Message: ' + ex.getMessage());
        }
        return inMap;
    }
    //-- End |FIN-7510| Changed by Armando | 22 JUNE 2026 --//

    public static Map<Object, Object> initiateCreditReview(Map<Object, Object> inMap){
        try{
            System.debug('Inside initiateCreditReview >>>>');
            Id AccountId = (Id) inMap.get('Id');
            // FIX: added Previous_Moody_s_Risk_Class__c, Previous_Moody_s_Credit_Limit__c and Credit_Score_Comparison_Flag__c
            // to the SELECT. CreditScoreComparisonService.applyComparisonAndRollValues() reads/writes these via
            // sObject.get()/put(), and get() throws System.SObjectException at runtime if the field was not queried.
            Account account = [Select Id, Name, AccountNumber, BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry, BillingAddress,
            Owner.Name, Recommended_Credit_Limit__c, BvD_ID_Number__c, CurrencyIsoCode, Is_Snoozed__c, celsrm__Payment_Behaviour_Text__c, celsrm__Payment_Behaviour_Trend__c,TAX_ID__c,
            celsrm__Check_Rule__c, celsrm__Risk_Class__c, Moody_s_Risk_Class__c, Moody_s_Credit_Limit__c, celsrm__Credit_Limit__c, Payment_Term_Days__c, Calculated_Credit_Limit_Group_Currency__c, celsrm__Credit_Group__c, Region__c,
            Previous_Moody_s_Risk_Class__c, Previous_Moody_s_Credit_Limit__c, Credit_Score_Comparison_Flag__c from Account where Id =: AccountId];

            System.debug('LOGTRACE >>> Loaded account. Id=' + account.Id + ' | BvD_ID_Number__c=' + account.BvD_ID_Number__c
                + ' | celsrm__Check_Rule__c=' + account.celsrm__Check_Rule__c + ' | celsrm__Risk_Class__c=' + account.celsrm__Risk_Class__c
                + ' | Moody_s_Risk_Class__c(before)=' + account.Moody_s_Risk_Class__c
                + ' | Moody_s_Credit_Limit__c(before)=' + account.Moody_s_Credit_Limit__c
                + ' | celsrm__Credit_Group__c=' + account.celsrm__Credit_Group__c);

            if(account.Is_Snoozed__c == true) {
                System.debug('LOGTRACE >>> EXIT: Account is Snoozed, aborting before Moody\'s assignment.');
                inMap.put('isAccountSnoozed', true);
                inMap.put('ggErrorMessage', 'You can\'t create CLR on this account. Account is Snoozed.');
                return inMap;
            }
            
            List<String> openCrStatus = new List<String>{'10', '15', '20', '21'};
            List<celsrm__Credit_Review__c> openCrs = [SELECT Id, Name FROM celsrm__Credit_Review__c WHERE celsrm__Account__c = :AccountId AND celsrm__Status__c IN :openCrStatus];
            if(openCrs != null && openCrs.size() > 0) {
                System.debug('LOGTRACE >>> EXIT: Open Credit Review(s) already exist: ' + openCrs + ' aborting before Moody\'s assignment.');
                List<String> openCrNo = new List<String>();
                for(celsrm__Credit_Review__c cr: openCrs) {
                    openCrNo.add(cr.Name);
                }
                inMap.put('creditReviewExists', true);
                inMap.put('ggErrorMessage', 'Credit Review exists on this account: ' + String.join(openCrNo, ', '));
                return inMap;
            } else {
                inMap.put('creditReviewExists', false);
            }
    
            if(account.celsrm__Check_Rule__c == 'Z08 Risk Class Child') {
                System.debug('LOGTRACE >>> EXIT: celsrm__Check_Rule__c is Z08 Risk Class Child (this is a child account), aborting before Moody\'s assignment.');
                inMap.put('isChildAccount', true);
                inMap.put('ggErrorMessage', 'Can\'t create CLR on Child account');
                return inMap;
            } else {
                inMap.put('isChildAccount', false);
            }
    
            if(account.celsrm__Credit_Group__c == null || account.celsrm__Credit_Group__c == '') {
                System.debug('LOGTRACE >>> EXIT: celsrm__Credit_Group__c is empty, aborting before Moody\'s assignment.');
                inMap.put('isCreditGroupEmpty', true);
                inMap.put('ggErrorMessage', 'The Credit Group field is empty. Kindly update the Credit Group details.');
                return inMap;
            } else {
                inMap.put('isCreditGroupEmpty', false);
            }
    
            if(account.celsrm__Credit_Group__c == '0001 - New customer / No score' ||
                account.celsrm__Credit_Group__c == '0007 - IC - Intercompany' ||
                account.celsrm__Credit_Group__c == '0006 - PP - Payment Plan' ||
                account.celsrm__Credit_Group__c == '0008 - INAC - Inactive Customer' ||
                account.celsrm__Credit_Group__c == '0009 - RPDL - RPDL' ||
                account.celsrm__Credit_Group__c == '0010 - AGY - Agency/Lawyer' ||
                account.celsrm__Credit_Group__c == '0011 - ATR - Atradius' ||
                account.celsrm__Credit_Group__c == '0012 - WRT - Write Off' ||
                account.celsrm__Credit_Group__c == '0013 - BKR - Bankruptcy' ||
                account.celsrm__Credit_Group__c == '0014 - PCC - Pre-pay/Credit Card' ||
                account.celsrm__Credit_Group__c == '0016 - CAD - Cadex' ||
                account.celsrm__Credit_Group__c == '0004 - ALA - Legal Action'
            ) {
                System.debug('LOGTRACE >>> EXIT: celsrm__Credit_Group__c is excluded (' + account.celsrm__Credit_Group__c + '), aborting before Moody\'s assignment.');
                inMap.put('isCreditGroupInvalid', true);
                inMap.put('ggErrorMessage', 'Credit group is ' + account.celsrm__Credit_Group__c + '. Can\'t create CLR.');
                return inMap;
            } else {
                inMap.put('isCreditGroupEmpty', false);
            }
    
            inMap.put('Name', account.Name);
            inMap.put('ownerName', account.Owner.Name);
            inMap.put('bvDId', account.BvD_ID_Number__c);
            inMap.put('NationalId', account.TAX_ID__c);   
            inMap.put('BillingAddress', account.BillingAddress);
            inMap.put('BillingStreet', account.BillingStreet);
            inMap.put('BillingCity', account.BillingCity);
            inMap.put('BillingState', account.BillingState);
            inMap.put('BillingPostalCode', account.BillingPostalCode);
            inMap.put('BillingCountry', account.BillingCountry);
            if(inMap.get('RequestedCreditLimit') == null) {
                inMap.put('RequestedCreditLimit', account.Recommended_Credit_Limit__c);
            }
            inMap.put('CalculatedCreditLimit', account.Recommended_Credit_Limit__c);
            inMap.put('CurrencyIsoCode', account.CurrencyIsoCode);
            if(inMap.get('modelType') == null || (String)inMap.get('modelType') == '') {
                inMap.put('modelType', 'Recalculation');
            }
            inMap.put('CurrentCreditLimit', account.celsrm__Credit_Limit__c);
            inMap.put('MoodysCreditLimit', account.Moody_s_Credit_Limit__c);
            if(inMap.get('RequestedCreditLimitEUR') == null) {
                inMap.put('RequestedCreditLimitEUR', Account.Calculated_Credit_Limit_Group_Currency__c);
            }
            if(inMap.get('RequestedValidToDate') == null) {
                inMap.put('RequestedValidToDate', Date.today().addDays(365));
            }
            if(inMap.get('PaymentTermDays') == null) {
                inMap.put('PaymentTermDays', account.Payment_Term_Days__c);
            }
                        
            System.debug('BVD Id Number >>>> ' + account.BvD_ID_Number__c);
    
            if(account.BvD_ID_Number__c != null){
                inMap.put('fetchParams', 'true');
            } else {
                inMap.put('fetchParams', 'false');
            }
            System.debug('LOGTRACE >>> fetchParams=' + inMap.get('fetchParams') + ' (if false, method returns via getCompanyData() and SKIPS the Moody\'s block entirely)');
    
            creditParamsHttpCalloutManager calloutManager = new creditParamsHttpCalloutManager();
    
            if(inMap.get('fetchParams') == 'false') {
                System.debug('LOGTRACE >>> EXIT: no BvD_ID_Number__c on account, returning via getCompanyData(). Moody\'s fields NOT evaluated.');
                return CreditReviewParameters.getCompanyData(inMap);
            } else {
                Decimal requestCl = inMap.get('RequestedCreditLimitEUR') != null ? Decimal.valueOf(String.valueOf(inMap.get('RequestedCreditLimitEUR'))) : null;
                System.debug('LOGTRACE >>> requestCl (RequestedCreditLimitEUR)=' + requestCl + ' | threshold check (>50000) result=' + (requestCl != null && requestCl > 50000));
                if(requestCl != null && requestCl > 50000) {
                    celsrm__Credit_Score__c creditScore = fetchLatestCreditScore(account.Id);
                    System.debug('LOGTRACE >>> fetchLatestCreditScore result: ' + creditScore);
                    // Both branches below end in applyMoodysAndPropagate(...), so the account's Moody's values,
                    // its Risk Class / Check Rule and the sibling propagation are handled the same way whether
                    // the Moody's data comes from an existing Credit Score or from a fresh getBvDInfo() callout.
                    if(creditScore != null) {
                        System.debug('LOGTRACE >>> BRANCH: existing creditScore found (Id=' + creditScore.Id + ').');
                        inMap.put('creditScoreId', creditScore.Id);
                        inMap.put('existingCreditScore', true);
                        inMap.put('moreEvaluationScore', creditScore.MORE_Evaluation_Score__c);
                        inMap.put('moreEvaluationYear', creditScore.MORE_Evaluation_Year__c);
                        inMap.put('moreEvaluationCurrent', creditScore.MORE_Credit_Limit__c);
                        inMap.put('moreEvaluationProbOfDefault', creditScore.MORE_Evaluation_Probability_of_Default__c);
                        inMap.put('moreEvaluationConfifenceLevel', creditScore.MORE_Evaluation_Confidence_Level__c);
                        inMap.put('reactiveMoreEvaluationReactiveScore', creditScore.Reactive_Score__c);
                        inMap.put('reactiveMoreEvaluationReactiveDate', creditScore.Reactive_Date__c);
                        inMap.put('reactiveMoreCreditLimitCurrent', creditScore.Reactive_Credit_Limit__c);
                        inMap.put('reactiveMoreEvaluationProbOfDefault', creditScore.Reactive_Probability_of_Default__c);
                        inMap.put('reactiveMoreEvaluationConfidenceLevel', creditScore.Reactive_Confidence_Level__c);
                        inMap.put('qualitativeScoreCurrent', creditScore.Qualitative_Score__c);
                        inMap.put('qualitativeScoreDate', creditScore.Qualitative_Score_Date__c);
                        inMap.put('qualitativereditLimitCurrent', creditScore.Qualitative_Credit_Limit__c);
                        inMap.put('qualitativeScoreConfidenceLevel', creditScore.Qualitative_score_Confidence_level__c);
                        inMap.put('currentRatio', creditScore.Current_Ratio__c);
                        inMap.put('liquidityRatio', creditScore.Liquidity_Ratio__c);
                        inMap.put('status', creditScore.Status__c);
                        inMap.put('statusDate', creditScore.Status_Date__c);
                        inMap.put('incorporationDate', creditScore.Date_of_Incorporation__c);
                        inMap.put('registeredCapital', creditScore.Registered_Capital__c);

                        // Existing score: recompute Moody's values and propagate to siblings as well
                        applyMoodysAndPropagate(account, creditScore, inMap, true);
                    } else {
                        System.debug('LOGTRACE >>> BRANCH: no existing creditScore. Calling calloutManager.getBvDInfo(bvdId=' + account.BvD_ID_Number__c + ', currency=' + account.CurrencyIsoCode + ')');
                        Map<Object, Object> dnbParams = calloutManager.getBvDInfo(account.BvD_ID_Number__c, account.CurrencyIsoCode);
                        System.debug('LOGTRACE >>> getBvDInfo() returned: ' + dnbParams);
                        inMap.putAll(dnbParams);
                        creditScore = new celsrm__Credit_Score__c();
                        creditScore.CurrencyIsoCode = account.CurrencyIsoCode;
                        creditScore.BvD_ID_Number__c = account.BvD_ID_Number__c;
                        creditScore.Account_Region__c = account.Region__c;
                        creditScore.MORE_Evaluation_Score__c = inMap.get('moreEvaluationScore') != null ? String.valueOf(inMap.get('moreEvaluationScore')): null;
                        creditScore.MORE_Evaluation_Year__c = inMap.get('moreEvaluationYear') != null ? Date.valueOf(String.valueOf(inMap.get('moreEvaluationYear'))): null;
                        creditScore.MORE_Credit_Limit__c = inMap.get('moreEvaluationCurrent') != null ? Decimal.valueOf(String.valueOf(inMap.get('moreEvaluationCurrent'))): null;
                        creditScore.MORE_Evaluation_Probability_of_Default__c = inMap.get('moreEvaluationProbOfDefault') != null ? Decimal.valueOf(String.valueOf(inMap.get('moreEvaluationProbOfDefault'))): null;
                        creditScore.MORE_Evaluation_Confidence_Level__c = inMap.get('moreEvaluationConfifenceLevel') != null ? Decimal.valueOf(String.valueOf(inMap.get('moreEvaluationConfifenceLevel'))): null;
                        creditScore.Reactive_Score__c = inMap.get('reactiveMoreEvaluationReactiveScore') != null ? String.valueOf(inMap.get('reactiveMoreEvaluationReactiveScore')): null;
                        creditScore.Reactive_Date__c = inMap.get('reactiveMoreEvaluationReactiveDate') != null ? Date.valueOf(String.valueOf(inMap.get('reactiveMoreEvaluationReactiveDate'))): null;
                        creditScore.Reactive_Credit_Limit__c = inMap.get('reactiveMoreCreditLimitCurrent') != null ? Decimal.valueOf(String.valueOf(inMap.get('reactiveMoreCreditLimitCurrent'))): null;
                        creditScore.Reactive_Probability_of_Default__c = inMap.get('reactiveMoreEvaluationProbOfDefault') != null ? Decimal.valueOf(String.valueOf(inMap.get('reactiveMoreEvaluationProbOfDefault'))): null;
                        creditScore.Reactive_Confidence_Level__c = inMap.get('reactiveMoreEvaluationConfidenceLevel') != null ? Decimal.valueOf(String.valueOf(inMap.get('reactiveMoreEvaluationConfidenceLevel'))): null;
                        creditScore.Qualitative_Score__c = inMap.get('qualitativeScoreCurrent') != null ? String.valueOf(inMap.get('qualitativeScoreCurrent')): null;
                        creditScore.Qualitative_Score_Date__c = inMap.get('qualitativeScoreDate') != null ? Date.valueOf(String.valueOf(inMap.get('qualitativeScoreDate'))): null;
                        creditScore.Qualitative_Credit_Limit__c = inMap.get('qualitativereditLimitCurrent') != null ? Decimal.valueOf(String.valueOf(inMap.get('qualitativereditLimitCurrent'))): null;
                        creditScore.Qualitative_score_Confidence_level__c = inMap.get('qualitativeScoreConfidenceLevel') != null ? Decimal.valueOf(String.valueOf(inMap.get('qualitativeScoreConfidenceLevel'))): null;
                        creditScore.Current_Ratio__c = inMap.get('currentRatio') != null ? Decimal.valueOf(String.valueOf(inMap.get('currentRatio'))): null;
                        creditScore.Liquidity_Ratio__c = inMap.get('liquidityRatio') != null ? Decimal.valueOf(String.valueOf(inMap.get('liquidityRatio'))): null;
                        creditScore.Status__c = inMap.get('status') != null ? String.valueOf(inMap.get('status')): null;
                        creditScore.Status_Date__c = inMap.get('statusDate') != null ? Date.valueOf(String.valueOf(inMap.get('statusDate'))): null;
                        creditScore.Date_of_Incorporation__c = inMap.get('incorporationDate') != null ? Date.valueOf(String.valueOf(inMap.get('incorporationDate'))): null;
                        creditScore.Registered_Capital__c = inMap.get('registeredCapital') != null ? Decimal.valueOf(String.valueOf(inMap.get('registeredCapital'))): null;
                        creditScore.celsrm__Account__c = account.Id;
                        creditScore.Payment_Behaviour__c = account.celsrm__Payment_Behaviour_Text__c;
                        creditScore.Payment_Behaviour_Trend__c = account.celsrm__Payment_Behaviour_Trend__c;

                        // Fresh score: compute Moody's values, propagate to siblings and insert the Credit Score
                        applyMoodysAndPropagate(account, creditScore, inMap, false);

                        System.debug('LOGTRACE >>> inserted new celsrm__Credit_Score__c Id=' + creditScore.Id
                            + ' with Moody_s_Credit_Limit__c=' + creditScore.Moody_s_Credit_Limit__c
                            + ' Moody_s_Risk_Class__c=' + creditScore.Moody_s_Risk_Class__c);
                        inMap.put('creditScoreId', creditScore.Id);
                        inMap.put('existingCreditScore', false);
                    }
                }
                return inMap;
            }
        } catch(Exception ex){
            System.debug('Method: initiateCreditReview | Linenumber: ' + ex.getLineNumber() + ' | Message: ' + ex.getMessage());
            inMap.put('ggErrorMessage', ex.getMessage());
        }
        return inMap;
    }

    // Derives Moody's Credit Limit / Risk Class from the given Credit Score, applies them to the
    // account, propagates to sibling Credit Segments and syncs profile data to SAP/CFin.
    // Shared by both branches of initiateCreditReview (existing score / freshly fetched score).
    private static void applyMoodysAndPropagate(Account account, celsrm__Credit_Score__c creditScore, Map<Object, Object> inMap, Boolean isExistingScore) {
        Decimal accountCreditLimit = null;
        String accountRiskClass = null;
        Date cutoff = Date.today().addYears(-2);

        System.debug('LOGTRACE >>> Credit limit source check | Reactive_Date__c=' + creditScore.Reactive_Date__c
            + ' Reactive_Credit_Limit__c=' + creditScore.Reactive_Credit_Limit__c
            + ' | MORE_Evaluation_Year__c=' + creditScore.MORE_Evaluation_Year__c
            + ' MORE_Credit_Limit__c=' + creditScore.MORE_Credit_Limit__c
            + ' | Qualitative_Score_Date__c=' + creditScore.Qualitative_Score_Date__c
            + ' Qualitative_Credit_Limit__c=' + creditScore.Qualitative_Credit_Limit__c
            + ' | cutoff(2yr ago)=' + cutoff);

        if(creditScore.Reactive_Date__c != null && creditScore.Reactive_Credit_Limit__c != null && creditScore.Reactive_Date__c >= cutoff) {
            accountCreditLimit = creditScore.Reactive_Credit_Limit__c;
        } else if(creditScore.MORE_Evaluation_Year__c != null && creditScore.MORE_Credit_Limit__c != null && creditScore.MORE_Evaluation_Year__c >= cutoff) {
            accountCreditLimit = creditScore.MORE_Credit_Limit__c;
        } else if(creditScore.Qualitative_Score_Date__c != null && creditScore.Qualitative_Credit_Limit__c != null && creditScore.Qualitative_Score_Date__c >= cutoff) {
            accountCreditLimit = creditScore.Qualitative_Credit_Limit__c;
        }

        if(accountCreditLimit != null) {
            // Use the account's CURRENT payment behaviour (an existing score may hold stale values)
            String behaviour = account.celsrm__Payment_Behaviour_Text__c;
            String trend = account.celsrm__Payment_Behaviour_Trend__c;
            if(behaviour == 'On Time') {
                accountCreditLimit = accountCreditLimit * 1.2;
            } else if(behaviour == 'Late' && trend == 'Payment Behaviour Improved') {
                accountCreditLimit = accountCreditLimit * 1.1;
            }
            // All other combinations keep a 1.0 multiplier
        }

        Map<String, String> moreMap = RiskClassCheckRuleMappingService.MORE_RISK_CLASS_MAPPING;
        Map<String, String> qualMap = RiskClassCheckRuleMappingService.QUALITATIVE_RISK_CLASS_MAPPING;
        if(creditScore.Reactive_Date__c != null && creditScore.Reactive_Score__c != null && creditScore.Reactive_Date__c >= cutoff && moreMap.containsKey(creditScore.Reactive_Score__c)) {
            accountRiskClass = moreMap.get(creditScore.Reactive_Score__c);
        } else if(creditScore.MORE_Evaluation_Year__c != null && creditScore.MORE_Evaluation_Score__c != null && creditScore.MORE_Evaluation_Year__c >= cutoff && moreMap.containsKey(creditScore.MORE_Evaluation_Score__c)) {
            accountRiskClass = moreMap.get(creditScore.MORE_Evaluation_Score__c);
        } else if(creditScore.Qualitative_Score_Date__c != null && creditScore.Qualitative_Score__c != null && creditScore.Qualitative_Score_Date__c >= cutoff && qualMap.containsKey(creditScore.Qualitative_Score__c)) {
            accountRiskClass = qualMap.get(creditScore.Qualitative_Score__c);
        }

        System.debug('LOGTRACE >>> applyMoodysAndPropagate | isExistingScore=' + isExistingScore
            + ' | accountCreditLimit=' + accountCreditLimit + ' | accountRiskClass=' + accountRiskClass);

        if(accountCreditLimit != null || accountRiskClass != null) {
            // For an existing score, only roll Previous_* / comparison flag when something actually changed,
            // otherwise every screen load would overwrite the previous values with the current ones.
            Boolean valuesChanged = (accountCreditLimit != null && accountCreditLimit != account.Moody_s_Credit_Limit__c)
                || (accountRiskClass != null && accountRiskClass != account.Moody_s_Risk_Class__c);
            if(!isExistingScore || valuesChanged) {
                // Ticket #948 - Credit Score Comparison: evaluate BEFORE account.Moody_s_* are overwritten below
                CreditScoreComparisonService.applyComparisonAndRollValues(account, accountRiskClass, accountCreditLimit);
            }
            if(accountCreditLimit != null) {
                account.Moody_s_Credit_Limit__c = accountCreditLimit;
                inMap.put('MoodysCreditLimit', account.Moody_s_Credit_Limit__c);
            }
            if(accountRiskClass != null) {
                account.Moody_s_Risk_Class__c = accountRiskClass;
            }
        } else {
            System.debug('LOGTRACE >>> NEITHER accountCreditLimit NOR accountRiskClass could be computed - account Moody\'s fields are UNTOUCHED this run.');
        }

        // celsrm__Risk_Class__c/celsrm__Check_Rule__c recompute for THIS account, plus propagation of
        // BvD ID / Moody's Risk Class / Moody's Credit Limit to sibling Credit Segments (same AccountNumber).
        // Siblings' own celsrm__Risk_Class__c/celsrm__Check_Rule__c are computed reactively by the
        // "Risk Class and Check Rule 2" Flow once they're saved below (see AccountMasterTrigger).
        SiblingCreditDataPropagationService.PropagationResult propagation =
            SiblingCreditDataPropagationService.propagate(new List<Account>{ account });

        // Guard against AccountMasterTrigger re-enqueuing UpdateProfileDataInSourceSystemService while this
        // update is still cascading (source account change + siblings' reactive recompute in the same
        // transaction). Mirrors the guard GetMoodysDataService uses around its own update (FIN-10145).
        // Snapshot siblings' Risk Class / Check Rule BEFORE the update with our own query. The sibling records
        // returned by the propagation service are not guaranteed to have these fields selected, and reading
        // an unqueried field throws "SObject row was retrieved via SOQL without querying the requested field".
        Set<Id> siblingIds = new Set<Id>();
        for (Account propagatedAcc : propagation.accountsToUpdate) {
            if (propagatedAcc.Id != account.Id) {
                siblingIds.add(propagatedAcc.Id);
            }
        }
        Map<Id, Account> siblingsBefore = new Map<Id, Account>();
        if (!siblingIds.isEmpty()) {
            siblingsBefore = new Map<Id, Account>([
                SELECT Id, celsrm__Check_Rule__c, celsrm__Risk_Class__c
                FROM Account
                WHERE Id IN :siblingIds
            ]);
        }

        Boolean previousSkipProfileDataSync = UpdateProfileDataInSourceSystemService.skipProfileDataSync;
        UpdateProfileDataInSourceSystemService.skipProfileDataSync = true;
        try {
            update propagation.accountsToUpdate;
        } finally {
            UpdateProfileDataInSourceSystemService.skipProfileDataSync = previousSkipProfileDataSync;
        }
        System.debug('LOGTRACE >>> propagation.accountsToUpdate saved (source account + eligible siblings). Post-update account.Moody_s_Credit_Limit__c=' + account.Moody_s_Credit_Limit__c
            + ' | account.Moody_s_Risk_Class__c=' + account.Moody_s_Risk_Class__c
            + ' | account.celsrm__Risk_Class__c=' + account.celsrm__Risk_Class__c
            + ' | account.celsrm__Check_Rule__c=' + account.celsrm__Check_Rule__c);

        // The trigger-driven SAP/CFin sync was suppressed above, so it's rebuilt explicitly here. Siblings'
        // Risk Class / Check Rule were computed by the Flow's nested DML, so the in-memory sibling objects
        // still hold the PRE-flow values and have to be re-queried to know what actually changed.
        List<Id> profileSyncAccountIds = new List<Id>();
        if (!siblingsBefore.isEmpty()) {
            for (Account siblingAfter : [
                SELECT Id, celsrm__Check_Rule__c, celsrm__Risk_Class__c
                FROM Account
                WHERE Id IN :siblingsBefore.keySet()
            ]) {
                Account siblingBefore = siblingsBefore.get(siblingAfter.Id);
                if (siblingBefore.celsrm__Risk_Class__c != siblingAfter.celsrm__Risk_Class__c
                    || siblingBefore.celsrm__Check_Rule__c != siblingAfter.celsrm__Check_Rule__c) {
                    profileSyncAccountIds.add(siblingAfter.Id);
                }
            }
        }

        RiskClassCheckRuleMappingService.MappingResult mapped = propagation.sourceMappingResults.get(account.Id);
        // Sync the source account whenever its Risk Class OR Check Rule changed, for any user
        // (same criteria GetMoodysDataService uses). The previous condition only synced a
        // Risk-Class-only change when the running user was a System Administrator.
        System.debug('LOGTRACE >>> source mapping result: ' + mapped);
        if (mapped != null && (mapped.riskClassChanged || mapped.checkRuleChanged)) {
            profileSyncAccountIds.add(account.Id);
        }

        if (!profileSyncAccountIds.isEmpty()) {
            System.debug('LOGTRACE >>> Calling UpdateProfileDataInSourceSystemService.updateProfileDataInSAP for accountIds=' + profileSyncAccountIds);
            if(!Test.isRunningTest()) {
                UpdateProfileDataInSourceSystemService.updateProfileDataInSAP(profileSyncAccountIds);
            }
        }

        // Only a freshly fetched score is inserted; an existing one is left untouched
        if(!isExistingScore) {
            creditScore.Moody_s_Credit_Limit__c = account.Moody_s_Credit_Limit__c;
            creditScore.Moody_s_Risk_Class__c = account.Moody_s_Risk_Class__c;
            insert creditScore;
        }
    }
    

    public static celsrm__Credit_Score__c fetchLatestCreditScore(String accId) {
        List<celsrm__Credit_Score__c> creditScores = [SELECT Id, Name, celsrm__Account__c, celsrm__Credit_Review__c, 
        celsrm__Model_Type__c, celsrm__Risk_Score__c, MORE_Evaluation_Score__c, MORE_Evaluation_Year__c, MORE_Credit_Limit__c, 
        MORE_Evaluation_Probability_of_Default__c, MORE_Evaluation_Confidence_Level__c, Reactive_Score__c, Reactive_Date__c, 
        Reactive_Credit_Limit__c, Reactive_Probability_of_Default__c, Reactive_Confidence_Level__c, Qualitative_Score__c, 
        Qualitative_Score_Date__c, Qualitative_Credit_Limit__c, Qualitative_score_Confidence_level__c, Current_Ratio__c, 
        Liquidity_Ratio__c, Status__c, Status_Date__c, BvD_ID_Number__c, Moody_s_Credit_Limit__c, Payment_Behaviour__c, 
        Payment_Behaviour_Trend__c, Moody_s_Risk_Class__c, Account_Region__c, Date_of_Incorporation__c, Registered_Capital__c 
        FROM celsrm__Credit_Score__c WHERE celsrm__Account__c = :accId ORDER BY CreatedDate DESC LIMIT 1];

        System.debug('LOGTRACE >>> fetchLatestCreditScore(accId=' + accId + ') found ' + creditScores.size() + ' record(s): ' + creditScores);
        
        if(!creditScores.isEmpty()) {
            return creditScores[0];
        } else {
            return null;
        }
    }

    public Static Map<Object, Object> getCompanyData(Map<Object, Object> inMap) {
        creditParamsHttpCalloutManager calloutManager = new creditParamsHttpCalloutManager();
        List<Map<String, Object>> companyList = calloutManager.getMatchingAccounts(inMap);
        if (companyList.size() > 0) {
            System.debug(companyList);
            inMap.put('companyDetailList', companyList);
        }
        return inMap;
    }

    public static Map<Object, Object> updateBvdId(Map<Object, Object> inMap){
        try{
            Id AccountId = (Id) inMap.get('Id');
            Account acc = [SELECT Id, Name, CurrencyIsoCode, AccountNumber, Duns_Number__c 
                           FROM Account WHERE Id = :AccountId];
            acc.BvD_ID_Number__c = (String)inMap.get('bvDId');
            update acc;
    
            try {
                List<String> idSet = new List<String>();
                idSet.add(String.valueOf(inMap.get('Id')));
                celsrm.SRMUtilityController.insertActivity(idSet, 'celsrm__Account__c', 'Updated DUNS Number', null, 100, 'Initiate Review : Updated DUNS Number', UserInfo.getUserId(), null, 'Internal');
                
                Map<String, Object> metadataMap = new Map<String, Object>{
                    'AccountNumber' => acc.AccountNumber,       
                    'companyDunsNumber' => acc.Duns_Number__c  
                };
                String metadataJson = JSON.serialize(metadataMap);
                Map<String, Object> inputParams = new Map<String, Object>{
                    'userId' => UserInfo.getUserId(),
                    'pageScreenName' => 'Updated BVD Number',
                    'actionPerformed' => true,
                    'actionTakenTime' => null,
                    'accountId' => AccountId,
                    'transactionId' => null,
                    'disputeId' => null,
                    'additionalMetadata' => metadataJson
                };
                System.debug('Full json :' + JSON.serialize(inputParams));
                Id activityId = celsrm.SRMUtilityController.logActivity(JSON.serialize(inputParams));
                System.debug('Full activity : ' + activityId);
            } catch (Exception e) {
                System.debug('Error logging activity: ' + e.getMessage() + ' ' + e.getLineNumber());
                inMap.put('ggErrorMessage', e.getMessage() + ' ' + e.getLineNumber());
            }
        } catch(Exception ex){
            System.debug('Method: updateDUNSNumber | Linenumber: ' + ex.getLineNumber() + ' | Message: ' + ex.getMessage());
        }
        return inMap;
    }

    public static Map<Object, Object> createCreditReviewRecord(Map<Object, Object> inMap) {
        Id AccountId = (Id) inMap.get('Id');
        
        try {
            // ---- LOCK the account row so concurrent calls for the same account serialize ----
            // FOR UPDATE holds the row lock until this transaction commits/rolls back. If a second
            // concurrent call for the same account arrives while this transaction is still running,
            // it waits here instead of racing past the open-CLR check below.
            Account lockAcc = [SELECT Id FROM Account WHERE Id = :AccountId FOR UPDATE];

            // ---- Re-validate "no open CLR" AT THE POINT OF INSERT, not just on screen load ----
            // initiateCreditReview() performs this same check, but only at screen-load time, which
            // does not prevent two near-simultaneous submits (double-click, retried request, two
            // open tabs) from each passing that check before either one commits its insert. This
            // is the authoritative check that actually prevents duplicate CLR creation.
            List<String> openCrStatus = new List<String>{'10', '15', '20', '21'};
            List<celsrm__Credit_Review__c> openCrs = [
                SELECT Id, Name 
                FROM celsrm__Credit_Review__c 
                WHERE celsrm__Account__c = :AccountId 
                AND celsrm__Status__c IN :openCrStatus
            ];
            if (openCrs != null && openCrs.size() > 0) {
                System.debug('LOGTRACE >>> EXIT (createCreditReviewRecord): Open Credit Review(s) already exist: ' + openCrs + ' - blocking duplicate creation.');
                List<String> openCrNo = new List<String>();
                for (celsrm__Credit_Review__c cr : openCrs) {
                    openCrNo.add(cr.Name);
                }
                inMap.put('creditReviewExists', true);
                inMap.put('ggErrorMessage', 'Credit Review exists on this account: ' + String.join(openCrNo, ', '));
                return inMap;
            }

            // ---- Safety-net check: block if ANY CLR was created for this account very recently ----
            // The open-status check above cannot catch a duplicate submission (double-click, two
            // browser tabs, split screen) when the CLR being created will auto-approve out of the
            // "open" statuses (10/15/20/21) within THIS SAME transaction, before the other
            // transaction ever gets a chance to see it as "open". This happens whenever the
            // requested credit limit is at or below the 50,000 EUR threshold, or within the
            // account's Moody's credit limit - see the auto-decisioning block further below.
            // A short recency window (independent of final status) closes that gap without
            // affecting legitimate CLR creation outside of that window.
            DateTime recentCutoff = DateTime.now().addMinutes(-2);
            List<celsrm__Credit_Review__c> recentCrs = [
                SELECT Id, Name
                FROM celsrm__Credit_Review__c
                WHERE celsrm__Account__c = :AccountId
                AND CreatedDate >= :recentCutoff
            ];
            if (recentCrs != null && recentCrs.size() > 0) {
                System.debug('LOGTRACE >>> EXIT (createCreditReviewRecord): Credit Review(s) created within the last 2 minutes: ' + recentCrs + ' - blocking likely duplicate submission.');
                List<String> recentCrNo = new List<String>();
                for (celsrm__Credit_Review__c cr : recentCrs) {
                    recentCrNo.add(cr.Name);
                }
                inMap.put('creditReviewExists', true);
                inMap.put('ggErrorMessage', 'A Credit Review was just created for this account: ' + String.join(recentCrNo, ', ') + '. Please refresh the page before submitting again.');
                return inMap;
            }
            // ---- end duplicate-prevention block ----

            Account acc = [Select Id, Name, CurrencyIsoCode, celsrm__Credit_Group__c, Expected_Turnover__c, celsrm__Credit_Limit__c,
            Credit_Exposure__c, Recommended_Credit_Limit__c, BvD_ID_Number__c, Moody_s_Credit_Limit__c, celsrm__Payment_Behaviour_Text__c, 
            celsrm__Payment_Behaviour_Trend__c, Payment_Term_Days__c, celsrm__Check_Rule__c, celsrm__Risk_Class__c, Calculated_Credit_Limit_Group_Currency__c, 
            Region__c, Collateral_Amount__c  from Account where Id =:AccountId ];

            System.debug('LOGTRACE >>> createCreditReviewRecord | acc.Moody_s_Credit_Limit__c=' + acc.Moody_s_Credit_Limit__c
                + ' | acc.celsrm__Risk_Class__c=' + acc.celsrm__Risk_Class__c);
            
            celsrm__Credit_Review__c creditReviewObj = new celsrm__Credit_Review__c();
            creditReviewObj.celsrm__Account__c = acc.Id;
            creditReviewObj.BvD_ID_Number__c = acc.BvD_ID_Number__c;
            creditReviewObj.celsrm__Recommended_Credit_Limit__c = acc.Recommended_Credit_Limit__c ;
            creditReviewObj.celsrm__Requested_Credit_Limit__c = (Decimal)inMap.get('RequestedCreditLimit');
            creditReviewObj.Requested_Credit_Limit_EUR__c = Decimal.valueOf(String.valueOf(inMap.get('RequestedCreditLimitEUR')));
            creditReviewObj.celsrm__System_Credit_Limit__c = acc.Recommended_Credit_Limit__c;
            creditReviewObj.Account_Region__c = acc.Region__c;
            creditReviewObj.celsrm__Status__c = '10';
            creditReviewObj.celsrm__Model_Type__c = String.valueOf(inMap.get('modelType'));
            String creditGroup = acc.celsrm__Credit_Group__c;
            if(creditGroup != null) {
                List<String> parts = creditGroup.split(' - ', 2);
                if(parts.size() > 1) {
                    creditGroup = parts[1];
                }
            }
            creditReviewObj.celsrm__Credit_Group__c = creditGroup;
            creditReviewObj.Expected_Turnover__c = acc.Expected_Turnover__c;
            creditReviewObj.Credit_Limit__c = acc.celsrm__Credit_Limit__c;
            creditReviewObj.Credit_Exposure__c = acc.Credit_Exposure__c ;
            creditReviewObj.Payment_Terms_Days__c =  inMap.get('PaymentTermDays') != null ? ((Decimal)inMap.get('PaymentTermDays')).intValue() : null;
            creditReviewObj.CurrencyIsoCode = acc.CurrencyIsoCode ;
            creditReviewObj.Requested_Valid_To_Date__c = Date.valueOf(String.valueOf(inMap.get('RequestedValidToDate')));
            creditReviewObj.Account_Collateral_Amount__c = acc.Collateral_Amount__c ;


            //Moody's Parameters
            creditReviewObj.MORE_Evaluation_Score__c = inMap.get('moreEvaluationScore') != null ? String.valueOf(inMap.get('moreEvaluationScore')): null;
            creditReviewObj.MORE_Evaluation_Year__c = inMap.get('moreEvaluationYear') != null ? Date.valueOf(String.valueOf(inMap.get('moreEvaluationYear'))): null;
            creditReviewObj.MORE_Credit_Limit__c = inMap.get('moreEvaluationCurrent') != null ? Decimal.valueOf(String.valueOf(inMap.get('moreEvaluationCurrent'))): null;
            creditReviewObj.MORE_Evaluation_Probability_of_Default__c = inMap.get('moreEvaluationProbOfDefault') != null ? Decimal.valueOf(String.valueOf(inMap.get('moreEvaluationProbOfDefault'))): null;
            creditReviewObj.MORE_Evaluation_Confidence_Level__c = inMap.get('moreEvaluationConfifenceLevel') != null ? Decimal.valueOf(String.valueOf(inMap.get('moreEvaluationConfifenceLevel'))): null;
            creditReviewObj.Reactive_Score__c = inMap.get('reactiveMoreEvaluationReactiveScore') != null ? String.valueOf(inMap.get('reactiveMoreEvaluationReactiveScore')): null;
            creditReviewObj.Reactive_Date__c = inMap.get('reactiveMoreEvaluationReactiveDate') != null ? Date.valueOf(String.valueOf(inMap.get('reactiveMoreEvaluationReactiveDate'))): null;
            creditReviewObj.Reactive_Credit_Limit__c = inMap.get('reactiveMoreCreditLimitCurrent') != null ? Decimal.valueOf(String.valueOf(inMap.get('reactiveMoreCreditLimitCurrent'))): null;
            creditReviewObj.Reactive_Probability_of_Default__c = inMap.get('reactiveMoreEvaluationProbOfDefault') != null ? Decimal.valueOf(String.valueOf(inMap.get('reactiveMoreEvaluationProbOfDefault'))): null;
            creditReviewObj.Reactive_Confidence_Level__c     = inMap.get('reactiveMoreEvaluationConfidenceLevel') != null ? Decimal.valueOf(String.valueOf(inMap.get('reactiveMoreEvaluationConfidenceLevel'))): null;
            creditReviewObj.Qualitative_Score__c     = inMap.get('qualitativeScoreCurrent') != null ? String.valueOf(inMap.get('qualitativeScoreCurrent')): null;
            creditReviewObj.Qualitative_Score_Date__c    = inMap.get('qualitativeScoreDate') != null ? Date.valueOf(String.valueOf(inMap.get('qualitativeScoreDate'))): null;
            creditReviewObj.Qualitative_Credit_Limit__c  = inMap.get('qualitativereditLimitCurrent') != null ? Decimal.valueOf(String.valueOf(inMap.get('qualitativereditLimitCurrent'))): null;
            creditReviewObj.Qualitative_score_Confidence_level__c    = inMap.get('qualitativeScoreConfidenceLevel') != null ? Decimal.valueOf(String.valueOf(inMap.get('qualitativeScoreConfidenceLevel'))): null;
            creditReviewObj.Current_Ratio__c     = inMap.get('currentRatio') != null ? Decimal.valueOf(String.valueOf(inMap.get('currentRatio'))): null;
            creditReviewObj.Liquidity_Ratio__c   = inMap.get('liquidityRatio') != null ? Decimal.valueOf(String.valueOf(inMap.get('liquidityRatio'))): null;
            creditReviewObj.Status_Moodys__c = inMap.get('status') != null ? String.valueOf(inMap.get('status')): null;
            creditReviewObj.Status_Date_Moody__c = inMap.get('statusDate') != null ? Date.valueOf(String.valueOf(inMap.get('statusDate'))): null;
            creditReviewObj.Date_of_Incorporation__c =  inMap.get('incorporationDate') != null ? Date.valueOf(String.valueOf(inMap.get('incorporationDate'))): null;
            creditReviewObj.Registered_Capital__c = inMap.get('registeredCapital') != null ? Decimal.valueOf(String.valueOf(inMap.get('registeredCapital'))): null;

            insert creditReviewObj;

            //Update Credit Score
            if(inMap.containsKey('creditScoreId') && inMap.get('creditScoreId') != null && (String)inMap.get('creditScoreId') != '') {
                String csId = (String)inMap.get('creditScoreId');
                if(inMap.containsKey('existingCreditScore') && inMap.get('existingCreditScore') != null && (Boolean)inMap.get('existingCreditScore') == false) {
                    celsrm__Credit_Score__c cs = new celsrm__Credit_Score__c(Id = csId);
                    cs.celsrm__Credit_Review__c = creditReviewObj.Id;
                    update cs;
                }
            } 
            creditReviewObj.Moody_s_Credit_Limit__c = acc.Moody_s_Credit_Limit__c;
            System.debug('LOGTRACE >>> creditReviewObj.Moody_s_Credit_Limit__c set from acc.Moody_s_Credit_Limit__c = ' + creditReviewObj.Moody_s_Credit_Limit__c
                + ' (if this is null, the Account record itself did not have Moody_s_Credit_Limit__c populated when this method ran)');
            if(acc.celsrm__Risk_Class__c != null) {
                List<String> parts = acc.celsrm__Risk_Class__c.split(' - ', 2);
                if(parts.size() > 1) {
                    creditReviewObj.celsrm__Risk_Class__c = parts[1];
                }
            }
            
            update creditReviewObj;

            inMap.put('creditReviewId', creditReviewObj.Id);
            if(creditReviewObj.Requested_Credit_Limit_EUR__c <= 50000) {
                creditReviewObj.celsrm__Approved_Credit_Limit__c = creditReviewObj.celsrm__Requested_Credit_Limit__c;
                creditReviewObj.Approved_Valid_To_Date__c = creditReviewObj.Requested_Valid_To_Date__c;
                creditReviewObj.celsrm__Status__c = '11';
                update creditReviewObj;
                List<String> crIds = new List<String>();
                crIds.add(creditReviewObj.Id);
                if(!Test.isRunningTest()) {
                    UpdateLimitInSourceSystemService.updateCreditLimitInSAP(crIds);
                }
            } else if(creditReviewObj.Requested_Credit_Limit_EUR__c > 50000 && creditReviewObj.celsrm__Requested_Credit_Limit__c <= acc.Moody_s_Credit_Limit__c) {
                creditReviewObj.celsrm__Approved_Credit_Limit__c = creditReviewObj.celsrm__Requested_Credit_Limit__c;
                creditReviewObj.Approved_Valid_To_Date__c = creditReviewObj.Requested_Valid_To_Date__c;
                creditReviewObj.celsrm__Status__c = '12';
                update creditReviewObj;
                List<String> crIds = new List<String>();
                crIds.add(creditReviewObj.Id);
                if(!Test.isRunningTest()) {
                    UpdateLimitInSourceSystemService.updateCreditLimitInSAP(crIds);
                }
            }
            if (!Test.isRunningTest() && creditReviewObj.celsrm__Status__c == '10') {
                System.enqueueJob(new CLR_PdfForFlow(new List<String>{creditReviewObj.Id}));
            }
        } catch(Exception ex){
            System.debug('Method: updateDUNSNumber | Linenumber: ' + ex.getLineNumber() + ' | Message: ' + ex.getMessage());
        }
        return inMap;
    }

    public static Map<Object, Object> calculateRequestedCreditLimitEUR(Map<Object, Object> inMap) {
        Map<Object, Object> returnMap = new Map<Object, Object>();
        String currencyCode = (String) inMap.get('CurrencyIsoCode');
        Decimal RequestedCreditLimit = (Decimal)inMap.get('RequestedCreditLimit');
        Decimal flooredCreditLimit = (Decimal) Math.floor((Double)requestedCreditLimit);
        returnMap.put('RequestedCreditLimit', flooredCreditLimit);
        if(currencyCode != 'EUR') {
            CurrencyType currencyConv = [SELECT IsoCode, ConversionRate FROM CurrencyType WHERE IsoCode = :currencyCode];
            if(currencyConv != null) {
                returnMap.put('RequestedCreditLimitEUR', flooredCreditLimit / currencyConv.ConversionRate);
            }
        } else {
            returnMap.put('RequestedCreditLimitEUR', flooredCreditLimit);
        }
        System.debug('LOGTRACE >>> calculateRequestedCreditLimitEUR returnMap=' + returnMap);
        return returnMap;
    }

}