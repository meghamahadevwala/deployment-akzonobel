public with sharing class UtilityController {
    
    private static Map < String, Double > rateMap = new  Map < String, Double >();
    public Map<String,Double> mapCurBalance{get;set;}
    // << START - MM - FIN-9546 - custom placeholder TotalOpenItems in attachment - celsrm__Close_Date__c flag is missing>> 
    public Map<String,Double> mapCurBalanceOpen{get;set;}
    // << END - MM - FIN-9546 - custom placeholder TotalOpenItems in attachment - celsrm__Close_Date__c flag is missing>> 
    // << START - MM - FIN-8279 - Email Attachment -> Totals by currencycode >>
    public Map<String,Double> mapCurBalanceForOverDue{get;set;}
    public Map<String,Double> mapCurBalanceForOverDueNotNoted{get;set;}
    // << END - MM - FIN-8279 - Email Attachment -> Totals by currencycode >>
    //-- Start | FIN-8334 | Changed by Ravi | 11 sep 2025 --//
    // public Set<String> crCodes {get;set;}
    // public boolean currencyChange = false;
    // public String transactioncurr;
    // public Double totalBillingBal = 0;
    //-- Start | FIN-8334 | Changed by Ravi | 11 sep 2025 --//
    //-- Starts | FIN-8280| Changed by Asera | 17 April 2026 --//
    public static String getTransactionListViewData( String selectedView, String[] transactionIds, boolean renderAsPDF, String sortFieldName, String SortOrder ) {
        return getTransactionListViewData( selectedView, transactionIds, renderAsPDF, sortFieldName, SortOrder, null );
    }
    public static String getTransactionListViewData(String selectedView, String[] transactionIds, boolean renderAsPDF, String sortFieldName, String SortOrder, String accountId) {
    //-- END | FIN-8280| Changed by Asera | 17 April 2026 --//
        List<celsrm__Custom_List_View__c> dbView = [SELECT Id, Name, celsrm__ListView_For_Object__c, celsrm__Object_Fields__c, celsrm__Filter_Criteria__c, celsrm__Sort_By_Field__c, celsrm__Sort_By_Order__c FROM celsrm__Custom_List_View__c WHERE Id = :selectedView];
        //-- Start | FIN-6777 | Changed by Ravi | 11 Aug 2024 --//
        if(dbView.size() == 0) {
            String currUser = UserInfo.getUserId();
            dbView = [SELECT Id, Name, celsrm__ListView_For_Object__c, celsrm__Object_Fields__c, celsrm__Filter_Criteria__c, celsrm__Sort_By_Field__c, celsrm__Sort_By_Order__c From celsrm__Custom_List_View__c Where celsrm__ListView_For_Object__c = 'celsrm__Transaction__c' and celsrm__Is_Default__c = true and (CreatedById = :currUser or celsrm__Is_Global__c = true) order by CreatedDate DESC LIMIT 1];
        } 
        //-- End | FIN-6777 | Changed by Ravi | 11 Aug 2024 --//
        Map<String, Schema.SObjectField> fMap;
        List<String> selectedFieldList = new List<String>();
    
        String whereClause = 'id IN :transactionIds';
        
        if (sortFieldName != null && SortOrder != null && sortFieldName != '' && SortOrder != '') {
            whereClause += ' ORDER BY ' + sortFieldName + ' ' + SortOrder + ' LIMIT 500';
        } else if (dbView.size() > 0 && dbView[0].celsrm__Sort_By_Field__c != null && dbView[0].celsrm__Sort_By_Field__c != '') {  //-- Start | FIN-7978 | Changed By Asera | 14 July 2025 -- we have removed condtion for celsrm__Sort_By_Order__c not in use//
            whereClause += ' ' + UtilityController.getQuerySortOrder(dbView[0].celsrm__Sort_By_Field__c, true) + ' LIMIT 500';
        } else {
            whereClause += ' LIMIT 500';
        } 
        String selectedFields = '';
        if (dbView.size() > 0 && dbView[0].celsrm__Object_Fields__c != null) {
            System.debug('celsrm__Object_Fields__c>>' + dbView[0].celsrm__Object_Fields__c);
            selectedFields = UtilityController.getQueryFields(dbView[0].celsrm__Object_Fields__c, dbView[0].celsrm__ListView_For_Object__c);
            System.debug('Inside selectedFieldList>>' + selectedFieldList);
        }
        selectedFieldList = selectedFields.split(',');
       	System.debug('selectedFieldList>>' + selectedFieldList);
        List<string> formatedFieldName = UtilityController.getTransactionFieldformat(selectedFieldList, 'celsrm__Transaction__c');
        String Queryfields = String.join(formatedFieldName, ',');
        String stringToQuery = 'SELECT ' + Queryfields + ' FROM celsrm__Transaction__c WHERE ' + whereClause;
        List<celsrm__Transaction__c> TransactionList = Database.query(stringToQuery);
        //-- Starts | FIN-8280| Changed by Asera | 17 April 2026 --//
        String TransactionSummary = '';
        if(accountId != null && accountId != ''){
            String accountLocale = 'EN';
            try {
                Account acc = [SELECT Id, celsrm__Locale__c FROM Account WHERE Id = :accountId];
                TransactionSummary = UtilityController.getTransactionSummary(TransactionList, selectedFieldList, renderAsPDF, acc.celsrm__Locale__c);
            } catch (Exception e) {
                System.debug('Error fetching Account: ' + e.getMessage());
            }
        } else {
            TransactionSummary = UtilityController.getTransactionSummary(TransactionList, selectedFieldList, renderAsPDF);
        } 
        //-- END | FIN-8280| Changed by Asera | 17 April 2026 --//   
        return TransactionSummary;
    }    

 public static Map<String, String> getTransactionTotalSummary(String AccountID, List <String> transactionIds) {
 

    UtilityController lvUtil = new UtilityController();
    lvUtil.TotalInvoiceBalance(transactionIds);
    //-- Start | FIN-8334 | Changed by Ravi | 11 sep 2025 --//
    // String formattedAmt = '';
    // String currencyIsoCode = UserInfo.getDefaultCurrency();
    // if (UserInfo.IsMultiCurrencyOrganization()) {

    //     List < Account > acc = UtilityController.getAccountWithCurrencyIsoCode(accountId);
    //     if (acc != null && acc.size() > 0) {
    //         currencyIsoCode = (String) acc.get(0).get('CurrencyIsoCode');
    //     }

    // }
    // Double totalTransactionBalance = lvUtil.getTotalTransactionBalance();
    // Boolean currencyChanged = lvUtil.getcurrencyChanged();
    // String txcurr = lvUtil.getTransactionCurrencyChanged();
    //-- End | FIN-8334 | Changed by Ravi | 11 sep 2025 --//
    String totalBalanceSummary = lvUtil.strTotalBalanceSummary();
    // << START - MM - FIN-9546 - custom placeholder TotalOpenItems in attachment - celsrm__Close_Date__c flag is missing>> 
    String totalBalanceOpenSummary = lvUtil.strTotalBalanceOpenSummary();
    // << END - MM - FIN-9546 - custom placeholder TotalOpenItems in attachment - celsrm__Close_Date__c flag is missing>> 
    String totalBalanceOverDueSummary = lvUtil.strTotalBalanceForOverDueSummary();
    String totalBalanceOverDueNotNotedSummary = lvUtil.strTotalBalanceForOverDueNotNotedSummary();
    //system.debug('--txcurr --'+txcurr);
    // system.debug('--currencyChanged --'+currencyChanged);
    //-- Start | FIN-8334 | Changed by Ravi | 11 sep 2025 --//
    // if (totalTransactionBalance != null) {
    //     if (currencyChanged == true && (UserInfo.IsMultiCurrencyOrganization() == true  || test.isRunningTest())) {
    //         formattedAmt = UtilityController.formatDoubleValue(currencyIsoCode, totalTransactionBalance);
    //     } else if (currencyChanged == false && (UserInfo.IsMultiCurrencyOrganization() == true  || test.isRunningTest())) {
    //         formattedAmt = UtilityController.formatDoubleValue(txcurr, totalTransactionBalance);
    //     } else {
    //         formattedAmt = UtilityController.formatDoubleValue(currencyIsoCode, totalTransactionBalance);
    //         system.debug('--formattedAmt --' + formattedAmt);
    //     }
    // }
    //-- End | FIN-8334 | Changed by Ravi | 11 sep 2025 --//
    // system.debug('--innerHtml--' + formattedAmt + totalTransactionBalance + totalBalanceSummary);
    system.debug('--innerHtml--' + totalBalanceSummary);
    Map<String, String> returnMap = new Map<String,string>();
    //-- Start | FIN-8334 | Changed by Ravi | 11 sep 2025 --//
    returnMap.put('TotalBalance',totalBalanceSummary);
    // returnMap.put('TotalBalanceWithoutCurrency',String.valueOf(totalTransactionBalance));
    // returnMap.put('TotalBalanceSummary',totalBalanceSummary);
    //-- End | FIN-8334 | Changed by Ravi | 11 sep 2025 --//
    // << START - MM - FIN-8279 - Email Attachment -> Totals by currencycode >>
    // << START - MM - FIN-9546 - custom placeholder TotalOpenItems in attachment - celsrm__Close_Date__c flag is missing>> 
    // returnMap.put('TotalOpenItems', totalBalanceSummary);
    returnMap.put('TotalOpenItems', totalBalanceOpenSummary);
    // << END - MM - FIN-9546 - custom placeholder TotalOpenItems in attachment - celsrm__Close_Date__c flag is missing>> 
    returnMap.put('TotalOverdueItems', totalBalanceOverDueSummary);
    returnMap.put('TotalOverdueNotNotedItems', totalBalanceOverDueNotNotedSummary);
    // << END - MM - FIN-8279 - Email Attachment -> Totals by currencycode >>
    return returnMap;
 }

    public static String formatDoubleValue(String currencyCode, Double d) {
        String formattedCurrencyStr;
        String doubleVal = formatAsCurrency(d);
        // String doubleVal = d.format();
        // if(currencyCode!=null && currencyCode!=''){
        celsrm__CurrencyCode_Symbols__c currencyCodesettings = celsrm__CurrencyCode_Symbols__c.getInstance(currencyCode);
        
        //String doubleVal =  Decimal.valueOf(d).setScale(2).toPlainString();
        
        if(currencyCodesettings!=null && currencyCodesettings.celsrm__Currency_Symbol__c!=null  ){
            formattedCurrencyStr = currencyCodesettings.celsrm__Currency_Symbol__c + ' ' + doubleVal;
        }
        // }  
        else{
            formattedCurrencyStr = '$' + ' ' +doubleVal;
        }
        return formattedCurrencyStr;
    }
    
    public static double getConversionRate(String inputCurrencyCode) {
        Double rate = 1.0;
        String userId = UserInfo.getUserId();
        rate = getOnDemandConversionRate(inputCurrencyCode);
        return rate;
    }
    
    public static Double getOnDemandConversionRate( String inputCurrencyCode ) {
        
        Double rate = rateMap.get(inputCurrencyCode);
        return (rate == null) ? 1.0 : rate;
    }
    
    public static String formatAsCurrency(Double amount) {
        
        String userLocale = UserInfo.getLocale();
        if(amount!=null)
        {   
            if ( 'de_DE_EURO'.equalsIgnoreCase(userLocale) || 'de'.equalsIgnoreCase(userLocale) || 'pt_BR'.equalsIgnoreCase(userLocale) || 'de_DE'.equalsIgnoreCase(userLocale)){
                //Convert String to Decimal
                Decimal currencyindec = Decimal.valueof(amount);
                //Convert String to Integer
                Long curdecint = currencyindec.longValue();
                //Get value after PRECISION
                decimal cents = currencyindec - currencyindec.longValue();
                //Set scale 2
                cents = cents.setScale(2);                
                if(cents.toPlainString().startsWith('-')){
                    return  curdecint.format() + ',' + cents.toPlainString().substring(3);
                }else
                    return  curdecint.format() + ',' + cents.toPlainString().substring(2);
            } else {
                //Convert String to Decimal
                Decimal currencyindec = Decimal.valueof(amount);
                //Convert String to Integer
                Long curdecint = currencyindec.longValue();
                //Get value after PRECISION
                decimal cents = currencyindec - currencyindec.longValue();
                cents = cents.setScale(2);
                if(curdecint == 0 ){
                    return cents.toPlainString().substring(0);
                }
                if(cents.toPlainString().startsWith('-0.')){
                    return curdecint.format() + cents.toPlainString().substring(2);
                }else
                    return curdecint.format() + cents.toPlainString().substring(1);
            }
        }
        return null;
    }
    public static Map< String, Map<String, List<String>> > fetchEmailsForTreatmentTask(List<Task> taskList) {
        Map< String, Map<String, List<String>> > returnMap = new Map< String, Map<String, List<String>> >();
        Map<Id, List<Task>> treatmentToTasks = new Map<Id, List<Task>>();
        Set<Id> treatmentIds = new Set<Id>();
        Set<Id> accountIds = new Set<Id>();

        // << START - MM - FIN-9969 - select contact by Email_Type__c based on treatment rule name | We need to return orgwide Id for FromAddress >>
        Map<string,OrgWideEmailAddress> orgwideadd= new Map<string,OrgWideEmailAddress>();
        List<OrgWideEmailAddress> listName = [SELECT Id, Address, DisplayName FROM OrgWideEmailAddress];
        System.debug ('listName<>>>'+listName);
        for(OrgWideEmailAddress lw : listName) {
            orgwideadd.put(lw.Address,lw);
        }
        // << END - MM - FIN-9969 - select contact by Email_Type__c based on treatment rule name | We need to return orgwide Id for FromAddress >>
        // Group tasks by treatment and collect account IDs
        for (Task tsk : taskList) {
            if (tsk.celsrm__Treatment__c != null) {
                treatmentIds.add(tsk.celsrm__Treatment__c);

                if (!treatmentToTasks.containsKey(tsk.celsrm__Treatment__c)) {
                    treatmentToTasks.put(tsk.celsrm__Treatment__c, new List<Task>());
                }
                treatmentToTasks.get(tsk.celsrm__Treatment__c).add(tsk);
            }
            if (tsk.WhatId != null) {
                accountIds.add(tsk.WhatId);
            }
        }
        //-- Start | FIN-9629 | Changed by Dhwanil | 23 April 2026 --//
        Map<Id, celsrm__Treatment__c> treatmentMap = new Map<Id, celsrm__Treatment__c>(
            [SELECT Id, celsrm__Seperate_Task_For_Step__c, celsrm__CC_Source_Type__c, celsrm__CC_Address__c,
            celsrm__BCC_Source_Type__c, celsrm__BCC_Address__c, celsrm__Treatment_Steps__c,
            celsrm__Notify_Account_Owner__c,
            // << START - MM - FIN-9969 - select contact by Email_Type__c based on treatment rule name | FromAddress based on treatment configuration >>
            celsrm__Enable_Dynamic_From_Address__c, celsrm__Org_Id__c
            // << END - MM - FIN-9969 - select contact by Email_Type__c based on treatment rule name | FromAddress based on treatment configuration >>
            FROM celsrm__Treatment__c 
            WHERE Id IN :treatmentIds]
        );
        //-- end | FIN-9629 | Changed by Dhwanil | 23 April 2026 --//

        Set<String> fieldNamesToQuery = new Set<String>();
        for (celsrm__Treatment__c tre : treatmentMap.values()) {
            if (tre.celsrm__Seperate_Task_For_Step__c) {
                List<TaskTreatmentController.ObjectCriteria> listOfTreatmentStep = (List<TaskTreatmentController.ObjectCriteria>)JSON.deserialize(tre.celsrm__Treatment_Steps__c, List<TaskTreatmentController.ObjectCriteria>.class);
                for (TaskTreatmentController.ObjectCriteria step : listOfTreatmentStep) {
                    // << START - MM - FIN-9969 - select contact by Email_Type__c based on treatment rule name | FromAddress based on treatment configuration >>
                    if(step.enableDynamicFromAddress == true && String.isNotBlank(step.fromAddress)) {
                        fieldNamesToQuery.add(step.fromAddress);
                    } 
                    // << END - MM - FIN-9969 - select contact by Email_Type__c based on treatment rule name | FromAddress based on treatment configuration >>
                    if (step.ccSourceType == 'field' && String.isNotBlank(step.ccAddress)) {
                        fieldNamesToQuery.add(step.ccAddress);
                    }
                    if (step.bccSourceType == 'field' && String.isNotBlank(step.bccAddress)) {
                        fieldNamesToQuery.add(step.bccAddress);
                    }
                }
            } else {
                // << START - MM - FIN-9969 - select contact by Email_Type__c based on treatment rule name | FromAddress based on treatment configuration >>
                if (tre.celsrm__Enable_Dynamic_From_Address__c == true && String.isNotBlank(tre.celsrm__Org_Id__c)) {
                    fieldNamesToQuery.add(tre.celsrm__Org_Id__c);
                }
                // << END - MM - FIN-9969 - select contact by Email_Type__c based on treatment rule name | FromAddress based on treatment configuration >>
                if (tre.celsrm__CC_Source_Type__c == 'field' && String.isNotBlank(tre.celsrm__CC_Address__c)) {
                    fieldNamesToQuery.add(tre.celsrm__CC_Address__c);
                }
                if (tre.celsrm__BCC_Source_Type__c == 'field' && String.isNotBlank(tre.celsrm__BCC_Address__c)) {
                    fieldNamesToQuery.add(tre.celsrm__BCC_Address__c);
                }
            }
        }

        Map<Id, Account> accountMap = new Map<Id, Account>();
        //-- Start | FIN-9629 | Changed by Dhwanil | 23 April 2026 --//
        Map<Id, String> accountOwnerEmailMap = new Map<Id, String>();
        if (!accountIds.isEmpty()) {
            String query = 'SELECT Id, Owner.Email';
            if (!fieldNamesToQuery.isEmpty()) {
                query += ', ' + String.join(new List<String>(fieldNamesToQuery), ', ');
            }
            query += ' FROM Account WHERE Id IN :accountIds';
            for (Account acc : Database.query(query)) {
                accountMap.put(acc.Id, acc);
                accountOwnerEmailMap.put(acc.Id, acc.Owner != null ? acc.Owner.Email : null);
            }
        }
        //-- end | FIN-9629 | Changed by Dhwanil | 23 April 2026 --//
        for (Id treatmentId : treatmentToTasks.keySet()) {
            celsrm__Treatment__c tre = treatmentMap.get(treatmentId);
            List<Task> tasks = treatmentToTasks.get(treatmentId);
    
            for (Task tsk : tasks) {
                String accId = String.valueOf(tsk.WhatId);
                Map<String, List<String>> emailMap = new Map<String, List<String>>();
                List<String> ccList = new List<String>();
                List<String> bccList = new List<String>();
                //-- Start | FIN-9629 | Changed by Dhwanil | 23 April 2026 --//
                if (tre.celsrm__Seperate_Task_For_Step__c) {
                    List<TaskTreatmentController.ObjectCriteria> listOfTreatmentStep = (List<TaskTreatmentController.ObjectCriteria>)JSON.deserialize(tre.celsrm__Treatment_Steps__c, List<TaskTreatmentController.ObjectCriteria>.class);
                    for (TaskTreatmentController.ObjectCriteria step : listOfTreatmentStep) {
                        if (tsk.Subject == step.taskSubject && tsk.celsrm__Treatment_Stage__c == step.stepName) {
                            // << START - MM - FIN-9969 - select contact by Email_Type__c based on treatment rule name | FromAddress based on treatment configuration >>
                            if(step.enableDynamicFromAddress != null && (Boolean)step.enableDynamicFromAddress) {
                                if(accountMap.containsKey(accId)) {
                                    Account acc = accountMap.get(accId);
                                    String value = String.valueOf(step.fromAddress);
                                    if(orgwideadd.containsKey(value)) {
                                        emailMap.put('from', new List<String>{orgwideadd.get(value).Id});
                                    } else {
                                        System.debug('OrgWideEmailAddress not found for address: ' + value);
                                    }
                                }
							} else {
                                if(orgwideadd.containsKey(step.fromAddress)) {
                                    emailMap.put('from', new List<String>{orgwideadd.get(step.fromAddress).Id});
                                } else {
                                    System.debug('OrgWideEmailAddress not found for address: ' + step.fromAddress);
                                }
							}
                            // << END - MM - FIN-9969 - select contact by Email_Type__c based on treatment rule name | FromAddress based on treatment configuration >>
                            Map<String, Object> result = getEmailAddress(step.ccSourceType, step.ccAddress, step.bccSourceType, step.bccAddress, accId, accountMap);
                            addDelimitedEmails(ccList, result.get('cc'));
                            addDelimitedEmails(bccList, result.get('bcc'));
                        }
                    }
                } else {
                    // << START - MM - FIN-9969 - select contact by Email_Type__c based on treatment rule name | FromAddress based on treatment configuration >>
                    if(tre.celsrm__Enable_Dynamic_From_Address__c) {
                        if(accountMap.containsKey(accId)) {
                            Account acc = accountMap.get(accId);
                            String value = String.valueOf(tre.celsrm__Org_Id__c);
                            if(orgwideadd.containsKey(value)) {
                                emailMap.put('from', new List<String>{orgwideadd.get(value).Id});
                            } else {
                                System.debug('OrgWideEmailAddress not found for address: ' + value);
                            }
                        }
                    } else {
                        if(orgwideadd.containsKey(tre.celsrm__Org_Id__c)) {
                            emailMap.put('from', new List<String>{orgwideadd.get(tre.celsrm__Org_Id__c).Id});
                        } else {
                            System.debug('OrgWideEmailAddress not found for address: ' + tre.celsrm__Org_Id__c);
                        }
                    }
                    // << END - MM - FIN-9969 - select contact by Email_Type__c based on treatment rule name | FromAddress based on treatment configuration >>
                    Map<String, Object> result = getEmailAddress(tre.celsrm__CC_Source_Type__c, tre.celsrm__CC_Address__c, tre.celsrm__BCC_Source_Type__c, tre.celsrm__BCC_Address__c, accId, accountMap);
                    addDelimitedEmails(ccList, result.get('cc'));
                    addDelimitedEmails(bccList, result.get('bcc'));
                }

                if (shouldNotifyAccountOwner(tsk, tre) && accountOwnerEmailMap.containsKey(tsk.WhatId)) {
                    addEmailIfMissing(ccList, accountOwnerEmailMap.get(tsk.WhatId));
                }
                //-- end | FIN-9629 | Changed by Dhwanil | 23 April 2026 --//
                emailMap.put('cc', ccList);
                emailMap.put('bcc', bccList);
                returnMap.put(tsk.Id, emailMap);
            }
        }

        return returnMap;
    }
    //-- Start | FIN-9629 | Changed by Dhwanil | 23 April 2026 --//
    public static Map<Id, String> getAccountOwnerEmails(Set<Id> accountIds) {
        Map<Id, String> accountOwnerEmailMap = new Map<Id, String>();
        if (accountIds == null || accountIds.isEmpty()) {
            return accountOwnerEmailMap;
        }

        for (Account acc : [SELECT Id, Owner.Email FROM Account WHERE Id IN :accountIds]) {
            accountOwnerEmailMap.put(acc.Id, acc.Owner != null ? acc.Owner.Email : null);
        }

        return accountOwnerEmailMap;
    }

    public static Boolean shouldNotifyAccountOwner(Task tsk, celsrm__Treatment__c treatment) {
        if (tsk == null || treatment == null) {
            return false;
        }

        if (treatment.celsrm__Seperate_Task_For_Step__c == true) {
            if (String.isBlank(treatment.celsrm__Treatment_Steps__c)) {
                return false;
            }

            List<TaskTreatmentController.ObjectCriteria> listOfTreatmentStep = (List<TaskTreatmentController.ObjectCriteria>)JSON.deserialize(
                treatment.celsrm__Treatment_Steps__c,
                List<TaskTreatmentController.ObjectCriteria>.class
            );

            for (TaskTreatmentController.ObjectCriteria step : listOfTreatmentStep) {
                if (tsk.Subject == step.taskSubject && tsk.celsrm__Treatment_Stage__c == step.stepName) {
                    return step.notifyAccountOwner == true;
                }
            }
            return false;
        }

        return treatment.celsrm__Notify_Account_Owner__c == true;
    }

    public static void addDelimitedEmails(List<String> targetEmails, Object emailValue) {
        if (targetEmails == null || emailValue == null || String.isBlank(String.valueOf(emailValue))) {
            return;
        }
        for (String email : String.valueOf(emailValue).split('[;,]')) {
            addEmailIfMissing(targetEmails, email);
        }
    }

    public static void addEmailIfMissing(List<String> targetEmails, String email) {
        if (targetEmails == null || String.isBlank(email)) {
            return;
        }

        String trimmedEmail = email.trim();
        if (!String.isBlank(trimmedEmail) && !targetEmails.contains(trimmedEmail)) {
            targetEmails.add(trimmedEmail);
        }
    }
    //-- Start | FIN-9629 | Changed by Dhwanil | 23 April 2026 --//
    public static Map<String, Object> getEmailAddress(String ccSourceType, String ccValue,
                                                  String bccSourceType, String bccValue,
                                                  String accId,
                                                  Map<Id, Account> accountMap) {
        Map<String, Object> returnValues = new Map<String, Object>();
        Map<String, String> fieldNameMap = new Map<String, String>();

        //-- Starts | FIN-8634 | Changed by Dhwanil | 26 Nov 2025 --//
        // Handle CC
        if (String.isNotBlank(ccSourceType)) {
            if (ccSourceType.equalsIgnoreCase('static') && String.isNotBlank(ccValue) && ccValue!='') {
                returnValues.put('cc', ccValue);
            } else if (ccSourceType.equalsIgnoreCase('field') && ccValue != null   && ccValue!='') {
                fieldNameMap.put('cc', ccValue);
            }
        } else {
            returnValues.put('cc', null);
        }

        // Handle BCC
        if (String.isNotBlank(bccSourceType)) {
            if (bccSourceType.equalsIgnoreCase('static') && String.isNotBlank(bccValue) && bccValue!='') {
                returnValues.put('bcc', bccValue);
            } else if (bccSourceType.equalsIgnoreCase('field') && bccValue != null  && bccValue!='') {
                fieldNameMap.put('bcc', bccValue);
            }
        } else {
            returnValues.put('bcc', null);
        }
        //-- Ends | FIN-8634 | Changed by Dhwanil | 26 Nov 2025 --//
        // Get dynamic field values from Account map
        if (!fieldNameMap.isEmpty() && accountMap.containsKey(Id.valueOf(accId))) {
            Account acc = accountMap.get(Id.valueOf(accId));
            for (String key : fieldNameMap.keySet()) {
                String fieldApi = fieldNameMap.get(key);
                String value = String.valueOf(acc.get(fieldApi));
                returnValues.put(key, value);
            }
        }

        return returnValues;
    }

    // << START - MM - FIN-9969 - select contact by Email_Type__c based on treatment rule name >>
    public static Map< String, Map<String, List<String>> > fetchEmailsBasedOnEmailType(Map<Id, Id> taskIdVsAccount, Map<Id, String> taskIdVsEmailType) {
        Map< String, Map<String, List<String>> > returnMap = new Map< String, Map<String, List<String>> >();
        Map< Id, Account > accs = new Map < Id, Account >([ select Id, OwnerId, celsrm__Auto_Treatment_Enabled__c, From_Email__c from Account where Id in : taskIdVsAccount.values()]);
        // << START - MM - FIN-8421 - Assign default FromAddress from orgwideemailaddress based on Account.FromEmail >>
        Map<String, String> accVsFromAddresses = new Map<String, String>();
        for ( Account acc:  accs.values()) {
            accVsFromAddresses.put(acc.Id, acc.From_Email__c);
        }

        Map<string,OrgWideEmailAddress> orgwideadd= new Map<string,OrgWideEmailAddress>();
        List<OrgWideEmailAddress> listName = [SELECT Id, Address, DisplayName FROM OrgWideEmailAddress where address IN :accVsFromAddresses.values() ];
        System.debug ('listName<>>>'+listName);
        if(listName.size() == 0) {
            celsrm__SRM_Configuration__c systemConfig = celsrm__SRM_Configuration__c.getOrgDefaults();
            listName = [SELECT Id, Address, DisplayName FROM OrgWideEmailAddress where address=:systemConfig.Mailbox_Email_Address__c ];
        }
        for(OrgWideEmailAddress lw : listName) {
            orgwideadd.put(lw.Address,lw);
        }
        // << END - MM - FIN-8421 - Assign default FromAddress from Account.FromEmail>>

        List<Contact> con = [SELECT Id,lastname,Fax,Email,AccountId,CC__c,Bcc__c,celsrm__Default__c,Email_Type__c From Contact where AccountId IN :taskIdVsAccount.values() AND (celsrm__Default__c =: TRUE OR CC__c=:True OR Bcc__c=:True) order by lastname];
        map<Id,List<Contact>> accIdVSContactId = new Map<Id,List<Contact>>();
        for(Contact ct : con){
            if(accIdVSContactId.containsKey(ct.AccountId)){
                List<Contact> contactList = accIdVSContactId.get(ct.AccountId);
                contactList.add(ct);
                accIdVSContactId.put(ct.AccountId,contactList);
            }else{
                accIdVSContactId.put(ct.AccountId, new List<Contact> { ct});
            }
        }
        for (String taskId:  taskIdVsAccount.keySet()) {
            System.debug('taskId>>>'+taskId);
            Id accId = taskIdVsAccount.get(taskId);
            String emailType = taskIdVsEmailType.get(taskId);
            List<String> to = new List<String>();
            List<String> cc = new List<String>();
            List<String> bcc = new List<String>();
            List<String> fromadd = new List<String>();
            Map<String, List<String>> emailsMap = new Map<String, List<String>>();
            //System.debug('acc.contacts>>>>'+acc.contacts);
            if(accIdVSContactId.containsKey(accId))
            {
                for(Contact contact:accIdVSContactId.get(accId)){
                    if (emailType == null) {
                        System.debug('Task Email Type is missing');
                        break;
                    }
                    if (contact.Email_Type__c != emailType) {
                        System.debug('Contact Email Type does not match Task Email Type');
                        continue;
                    }
                    if(contact.celsrm__Default__c == true && contact.Email != null ){
                        to.add(contact.Email);
                        emailsMap.put('to', to);
                    } else if(contact.CC__c == true && contact.Email != null){
                        cc.add(contact.Email);
                        emailsMap.put('cc', cc);
                        
                    } else if(contact.Bcc__c == true && contact.Email != null){
                        bcc.add(contact.Email);
                        emailsMap.put('bcc', bcc);
                    }
                    
                }
            }
            if(accVsFromAddresses.containsKey(accId)) {
                String fromEmail = accVsFromAddresses.get(accId);
                if (orgwideadd.containsKey(fromEmail)) {
                    fromadd.add(orgwideadd.get(fromEmail).Id);
                    emailsMap.put('from', fromadd);
                } else {
                    System.debug('OrgWideEmailAddress not found for address: ' + fromEmail);
                }
            }
            system.debug('<<<<<<<<emailsMap>>>>>>'+emailsMap);
            returnMap.put(taskId, emailsMap);
        }
        
        return returnMap;
    }
    // << END - MM - FIN-9969 - select contact by Email_Type__c based on treatment rule name | Copied from fetchEmails() method just to avoid impact on existing functionality >>
    public static Map< String, Map<String, List<String>> > fetchEmails(List<Id> accIds) {
        Map< String, Map<String, List<String>> > returnMap = new Map< String, Map<String, List<String>> >();
        Map< Id, Account > accs = new Map < Id, Account >([ select Id, OwnerId, celsrm__Auto_Treatment_Enabled__c, From_Email__c from Account where Id in : accIds]);
        // << START - MM - FIN-8421 - Assign default FromAddress from Account.FromEmail>>
        // << START - MM - FIN-9969 - select contact by Email_Type__c based on treatment rule name | FromAddress won't populated for the bulk accounts >>
        Map<String, String> accVsFromAddresses = new Map<String, String>();
        // << END - MM - FIN-9969 - select contact by Email_Type__c based on treatment rule name | FromAddress won't populated for the bulk accounts >>
        Set<String> fromAddresses = new Set<String>();
        for ( Account acc:  accs.values()) {
            fromAddresses.add(acc.From_Email__c);
            // << START - MM - FIN-9969 - select contact by Email_Type__c based on treatment rule name | FromAddress won't populated for the bulk accounts >>
            accVsFromAddresses.put(acc.Id, acc.From_Email__c);
            // << END - MM - FIN-9969 - select contact by Email_Type__c based on treatment rule name | FromAddress won't populated for the bulk accounts >>
        }

        Map<string,OrgWideEmailAddress> orgwideadd= new Map<string,OrgWideEmailAddress>();
        List<OrgWideEmailAddress> listName = [SELECT Id, Address, DisplayName FROM OrgWideEmailAddress where address IN :fromAddresses ];
        System.debug ('listName<>>>'+listName);
        if(listName.size() == 0) {
            celsrm__SRM_Configuration__c systemConfig = celsrm__SRM_Configuration__c.getOrgDefaults();
            listName = [SELECT Id, Address, DisplayName FROM OrgWideEmailAddress where address=:systemConfig.Mailbox_Email_Address__c ];
        }
        for(OrgWideEmailAddress lw : listName) {
            orgwideadd.put(lw.Address,lw);
        }
        // << END - MM - FIN-8421 - Assign default FromAddress from Account.FromEmail>>

        List<Contact> con = [SELECT Id,lastname,Fax,Email,AccountId,CC__c,Bcc__c,celsrm__Default__c From Contact where AccountId IN :accIds AND (celsrm__Default__c =: TRUE OR CC__c=:True OR Bcc__c=:True) order by lastname];
        map<Id,List<Contact>> accIdVSContactId = new Map<Id,List<Contact>>();
        for(Contact ct : con){
            if(accIdVSContactId.containsKey(ct.AccountId)){
                List<Contact> contactList = accIdVSContactId.get(ct.AccountId);
                contactList.add(ct);
                accIdVSContactId.put(ct.AccountId,contactList);
            }else{
                accIdVSContactId.put(ct.AccountId, new List<Contact> { ct});
            }
        }
        // << START - MM - FIN-8421 - Assign default FromAddress from Account.FromEmail>>
        // Map<string,OrgWideEmailAddress> orgwideadd= new Map<string,OrgWideEmailAddress>();
        // celsrm__SRM_Configuration__c systemConfig = celsrm__SRM_Configuration__c.getOrgDefaults();
        // List<OrgWideEmailAddress> listName = [SELECT Id, Address, DisplayName FROM OrgWideEmailAddress where address=:systemConfig.Mailbox_Email_Address__c ];
        
        // System.debug ('listName<>>>'+listName);
        // for(OrgWideEmailAddress lw : listName) {
        //     orgwideadd.put(lw.Address,lw);
        // }
        // << END - MM - FIN-8421 - Assign default FromAddress from Account.FromEmail>>
        for ( Account acc:  accs.values()) {
            System.debug('acc>>>'+acc);
            List<String> to = new List<String>();
            List<String> cc = new List<String>();
            List<String> bcc = new List<String>();
            List<String> fromadd = new List<String>();
            Map<String, List<String>> emailsMap = new Map<String, List<String>>();
            //System.debug('acc.contacts>>>>'+acc.contacts);
            if(accIdVSContactId.containsKey(acc.Id))
            {
                for(Contact contact:accIdVSContactId.get(acc.Id)){
                    if(contact.celsrm__Default__c == true && contact.Email != null ){
                        to.add(contact.Email);
                        emailsMap.put('to', to);
                    } else if(contact.CC__c == true && contact.Email != null){
                        cc.add(contact.Email);
                        emailsMap.put('cc', cc);
                        
                    } else if(contact.Bcc__c == true && contact.Email != null){
                        bcc.add(contact.Email);
                        emailsMap.put('bcc', bcc);
                    }
                    
                }
            }
            // << START - MM - FIN-9969 - select contact by Email_Type__c based on treatment rule name | FromAddress won't populated for the bulk accounts >>
            //  if (listName  != null && listName.size() > 0){
            //     fromadd.add(listName.get(0).Id);
            //     emailsMap.put('from',fromadd  );
            // }
            if(accVsFromAddresses.containsKey(acc.Id)) {
                String fromEmail = accVsFromAddresses.get(acc.Id);
                if (orgwideadd.containsKey(fromEmail)) {
                    fromadd.add(orgwideadd.get(fromEmail).Id);
                    emailsMap.put('from', fromadd);
                } else {
                    System.debug('OrgWideEmailAddress not found for address: ' + fromEmail);
                }
            }
            // << END - MM - FIN-9969 - select contact by Email_Type__c based on treatment rule name | FromAddress won't populated for the bulk accounts >>
          /*  system.debug('acc.from__c>>>'+acc.celsrm__from__c);
            if (listName  != null ){
                fromadd .add(listName.get(0).Id);
                emailsMap.put('from',fromadd  );
            }*/
            /* if(acc.from__c != null && acc.from__c != ''){
                    String frmid ;
                    if(orgwideadd.get(acc.from__c) != null){
                    frmid =orgwideadd.get(acc.from__c).Id;
                    }else{
                    frmid =orgwideadd.get(UserInfo.getUserEmail()).Id;
                    }
                    fromadd.add(frmid );
                    emailsMap.put('from', fromadd );
                    }else{
                    String frmid =orgwideadd.get(UserInfo.getUserEmail()).Id;
                    system.debug('========'+frmid );
                    fromadd .add(frmid );
                    emailsMap.put('from', fromadd );
                    }*/
            system.debug('<<<<<<<<emailsMap>>>>>>'+emailsMap);
            returnMap.put(acc.Id, emailsMap);
        }
        
        return returnMap;
    }
    
    public static list<celsrm__Transaction__c> getTransactionList(String fieldsToQuery, String whereClause){
        String stringToQuery = 'Select '+ fieldsToQuery + ' from celsrm__Transaction__c ' +  whereClause ;
        system.debug('stringToQuery>>>>>>>>'+stringToQuery);
        list<celsrm__Transaction__c> lstTransaction = database.query(stringToQuery);
        return lstTransaction;
    }
    //-- Starts | FIN-8280| Changed by Asera | 17 April 2026 --//
    public static String getTransactionSummary( List<celsrm__Transaction__c> trxList, List<String> FieldsAPIlst, boolean isPageBreak){
        return getTransactionSummary( trxList, FieldsAPIlst, isPageBreak, null );
    }
    
    public static String getTransactionSummary(list<celsrm__Transaction__c> trxList, List<String> FieldsAPIlst, boolean isPageBreak, String accountLocale){
    //-- END | FIN-8280| Changed by Asera | 17 April 2026 --//
        celsrm__SRM_Configuration__c systemConfig = celsrm__SRM_Configuration__c.getOrgDefaults();
        
        system.debug('systemConfig>>>'+systemConfig.celsrm__Billing_Statement_PDF_Page_Break_First__c);
        Double TotalBalance = 0;
        Double pageBreakAfter = 0;
        if(systemConfig.celsrm__Billing_Statement_PDF_Page_Break_First__c != null && systemConfig.celsrm__Billing_Statement_PDF_Page_Break_First__c != '' ){
            pageBreakAfter = double.valueOF(systemConfig.celsrm__Billing_Statement_PDF_Page_Break_First__c);
        }else{
            pageBreakAfter= 22;
        }
        Integer j=0; 
        List<String> fieldType = new List<String>{};
        Schema.Sobjecttype objType = celsrm__Transaction__c.getSObjectType();
        Schema.Describesobjectresult sobjRes = objType.getDescribe();
        Map<String, Schema.Sobjectfield> fieldMap = sobjRes.fields.getMap();
        String innerHtml= '';
        
        //-- Start | FIN-9543 | Changed by Dhwanil | 06 April 2026 --//
        String attachmentFontFamily = systemConfig.celsrm__Attachment_Table_Font_Family__c != null ? systemConfig.celsrm__Attachment_Table_Font_Family__c : 'verdana';
        String attachmentFontSize = String.valueof(systemConfig.celsrm__Attachment_Table_Font_Size__c != null ? systemConfig.celsrm__Attachment_Table_Font_Size__c : 12) + 'px';
        //-- End | FIN-9543 | Changed by Dhwanil | 06 April 2026 --//
        //-- Starts | FIN-8280| Changed by Asera | 17 April 2026 --//
        if(accountLocale != null && accountLocale != ''){
            List<String> fields = new List<String>();
            for(String fieldName : FieldsAPIlst) {
                if(fieldName != 'id' && fieldName != 'celsrm__Flag__c' && fieldName != 'celsrm__Latest_Note__c' && fieldName !='celsrm__Latest_Note_Date__c') {
                    fields.add(fieldName);
                }
            } 
            fieldType = celsrm.SRMUtilityController.getTransactionFieldTranslatedLabel(accountLocale, 'celsrm__Transaction__c', fields);
        } else {
            for(String fieldName : FieldsAPIlst) {
                if(fieldName != 'id' && fieldName != 'celsrm__Flag__c' && fieldName != 'celsrm__Latest_Note__c' && fieldName !='celsrm__Latest_Note_Date__c') {
                    Schema.Sobjectfield field = fieldMap.get(fieldName);
                    if(field != null){
                        String fieldNames1 = field.getDescribe().getLabel();
                        fieldType.add(fieldNames1);
                    }
                }
            } 
        }
        //-- END | FIN-8280| Changed by Asera | 17 April 2026 --//
        
        //-- Start | FIN-8048 | Changed by Ravi | 29 July 2025 --//
        //-- Start | FIN-9543 | Changed by Dhwanil | 06 April 2026 --//
        innerHtml = '<style>@page{size:landscape;}</style><table width="100%" class="billing" style="border-collapse:collapse;padding:0px;font-family:'+attachmentFontFamily+';font-size:'+attachmentFontSize+';">';
        //-- End | FIN-9543 | Changed by Dhwanil | 06 April 2026 --//
        //-- End | FIN-8048 | Changed by Ravi | 29 July 2025 --//
        innerHtml += '<tr >';
        for(String obj : fieldType) {
            //-- Start | FIN-8048 | Changed by Ravi | 29 July 2025 --//
            innerHtml += '<th width="auto" style="border:1px solid gray;text-align:left;">'+obj+'</th>';
            //-- End | FIN-8048 | Changed by Ravi | 29 July 2025 --//
        }
        innerHtml += '</tr>';
        Object fieldvalue;
        
        for(celsrm__Transaction__c dtx : trxList) {
            
            if(j==pageBreakAfter && isPageBreak) {
                
                innerHtml += '</table>';
                //-- Start | FIN-8048 | Changed by Ravi | 29 July 2025 --//
                //-- Start | FIN-9543 | Changed by Dhwanil | 06 April 2026 --//
                innerHtml += '<table width="100%" class="billing" style="border-collapse:collapse;padding:0px;font-family:'+attachmentFontFamily+';font-size:'+attachmentFontSize+';">';
                //-- End | FIN-9543 | Changed by Dhwanil | 06 April 2026 --//
                //-- End | FIN-8048 | Changed by Ravi | 29 July 2025 --//
                innerHtml += '<tr style="page-break-before:always;">';
                
                for(String fieldName : fieldType) {
                    //-- Start | FIN-8048 | Changed by Ravi | 29 July 2025 --//
                    innerHtml += '<th width="auto" style="border:1px solid gray;text-align:left;">'+fieldName +'</th>';
                    //-- End | FIN-8048 | Changed by Ravi | 29 July 2025 --//
                }
                innerHtml += '</tr>';
                
                
                j=0; 
                if(systemConfig.celsrm__Billing_Statement_PDF_Page_Break_After__c != null && systemConfig.celsrm__Billing_Statement_PDF_Page_Break_After__c != '' ){
                    pageBreakAfter = double.valueOF(systemConfig.celsrm__Billing_Statement_PDF_Page_Break_After__c);
                }else{
                    pageBreakAfter= 40;
                }
            }
            
            j=j+1;
            innerHtml += '<tr>';
            //-- Start | FIN-9021 | changed by dhwanil | 22-Jan-2026 --//            
            for(String fieldName : FieldsAPIlst){
                String falign = 'left';
                 if(fieldName != 'id' && fieldName != 'celsrm__Flag__c' && fieldName != 'celsrm__Latest_Note__c' && fieldName != 'celsrm__Latest_Note_Date__c'){
                
                Schema.Sobjectfield field = fieldMap.get(fieldName);
                Schema.Displaytype fieldDataType = field.getDescribe().getType();
                String fType = field.getDescribe().getType().name();
                if(fieldName == 'celsrm__balance__c'){
                    fieldName = 'Balance';
                }
                if(fieldDataType == Schema.DisplayType.REFERENCE){
                    
                    fieldName = fieldName.subString(0,fieldName.length()-1)+ 'r';
                    system.debug('----fieldName utility'+fieldName);
                    if(dtx.getSobject(fieldName) != null){
                    fieldvalue = dtx.getSobject(fieldName).get('name');
                    }else{
                    fieldvalue = '';
                    }
                    
                }else if (fType == 'DATE'){
                    if(dtx.get(fieldName) != null){
                        system.debug('----else ifff'+fieldName);
                        Date dtTemp = (Date)dtx.get(fieldName);
                        
                        fieldvalue =dtTemp.format();
                    }else {
                        fieldvalue = '';
                    }
                }else{
                    
                    fieldvalue = dtx.get(fieldName);
                    // if(fieldName == 'celsrm__Base_Amount__c'){
                    //     fieldvalue = dtx.get('celsrm__Base_Currency__c') + fieldvalue.toString();
                    // }
                    if(fieldvalue == null){
                        fieldvalue = '';
                    }
                }
                if(fType == 'DOUBLE' || fType == 'INTEGER' || fType == 'LONG' || fType == 'CURRENCY')
                {
                    falign = 'right';
                }
                //-- Start | FIN-8048 | Changed by Ravi | 29 July 2025 --//
                innerHtml += '<td width="auto" style="text-align:'+falign+';border:solid 0.5px gray;white-space:nowrap;">'+ fieldvalue+'</td>';
                //-- End | FIN-8048 | Changed by Ravi | 29 July 2025 --//
            }
            }
            //-- Start | FIN-9021 | changed by dhwanil | 22-Jan-2026 --//
            innerHtml += '</tr>';
        }
        innerHtml += '</table>';
        return innerHtml;
    }
    
    public static String createFilterCriteria(String filterCriteria, String objectName){
        String whereClause = '';
        Map<string, Schema.sObjectType> describeInfo = Schema.getGlobalDescribe();
        Map<String, Schema.SObjectField> fMap;
        fMap = describeInfo.get(objectName.toLowerCase()).getDescribe().Fields.getMap();
        List<Map<String, String>> filters = (List<Map<String, String>>)JSON.deserialize(filterCriteria, List<Map<String, String>>.class);
        if(filters != null && filters.size() > 0) {
            String LogicalOperator = '';
            for(Map<String, String> clause : filters) {
                System.debug('whereClause>>> ' +  whereClause);
                System.debug('LogicalOperator.contains>>> ' + LogicalOperator.contains('OR'));
                if(LogicalOperator.contains('OR')) {
                    whereClause = whereClause.removeEnd(')');
                }
                whereClause += LogicalOperator;
                // if(!LogicalOperator.contains('OR')) {
                //     whereClause += '(';
                // }
                String TYPE = String.ValueOf(fMap.get(clause.get('Field')).getDescribe().getType());
                system.debug('clause>>>>'+clause);
                //Default for BOOLEAN, DOUBLE, CURRENCY, INTEGER, DATETIME, DATE
                String quote = '';
                if(TYPE == 'ID' || TYPE == 'REFERENCE' || TYPE == 'STRING' || TYPE == 'PICKLIST' || TYPE == 'TEXTAREA' ||
                   TYPE == 'ADDRESS' || TYPE == 'PHONE' || TYPE == 'URL') {
                       quote = '\'';
                   } 
                String value = clause.get('Value');
                String str = clause.get('Operator');
                        
               if(whereClause == '') {
                    whereClause += ' WHERE ';
                    // if(str.equals('does not contain')) {
                    //     whereClause += ' WHERE ( NOT ' + clause.get('Field');
                    // } else {
                    //     whereClause += ' WHERE ' + clause.get('Field');
                    // }
                }
                if(!LogicalOperator.contains('OR')) {
                    whereClause += '(';
                }
                if(str.equals('does not contain')) {
                    whereClause += ' ( NOT ' + clause.get('Field');
                } else {
                    whereClause += ' ' + clause.get('Field');
                }
                
                if(str.equals('equals')) {
                    whereClause += ' = ' + (value == null || value == '' ? 'null' : quote + value + quote);
                } else if(str.equals('not equal to')) {
                    whereClause += ' != ' + (value == null || value == '' ? 'null' : quote + value + quote);
                } else if(str.equals('starts with')) {
                    whereClause += ' LIKE ' + (value == null || value == '' ? 'null' : quote + value + '%' + quote);
                } else if(str.equals('end with')) {
                    whereClause += ' LIKE ' + (value == null || value == '' ? 'null' : quote + '%' + value + quote);
                } else if(str.equals('contains')) {
                    whereClause += ' LIKE ' + (value == null || value == '' ? 'null' : quote + '%' + value + '%' + quote);
                } else if(str.equals('does not contain')) {
                    whereClause += ' NOT LIKE ' + (value == null || value == '' ? 'null' : quote + '%' + value + '%' + quote);
                } else if(str.equals('contains in list')) {
                    whereClause += ' INCLUDES ' + (value == null || value == '' ? '(null)' : '(' + '\'' + value + '\'' + ')');
                } else if(str.equals('less than')) {
                    whereClause += ' < ' + (value == null ? 'null' : quote + value + quote);
                } else if(str.equals('greater than')) {
                    whereClause += ' > ' + (value == null ? 'null' : quote + value + quote);
                } else if(str.equals('less or equal')) {
                    whereClause += ' <= ' + (value == null ? 'null' : quote + value + quote);
                } else if(str.equals('greater or equal')) {
                    whereClause += ' >= ' + (value == null ? 'null' : quote + value + quote);
                }
                
                if(str.equals('does not contain')) {
                    whereClause += ' ) ';
                }
                whereClause += ')';
                LogicalOperator = (clause.get('LogicalOperator') != null && clause.get('LogicalOperator') != '' ? + ' ' + clause.get('LogicalOperator') + ' ' : '') + ' ';
                // whereClause += (clause.get('LogicalOperator') != null && clause.get('LogicalOperator') != '' ? + ' ' + clause.get('LogicalOperator') + ' ' : '') + ' ';
            }
        }
        return whereClause;
    }

    public static List<String> getTransactionFieldformat(List<String> FieldsAPIlst, String sObjAPIName){
        
        Double TotalBalance = 0;
        List<String> fieldType = new List<String>{};
        Map<String,Schema.SObjectType> objList = Schema.getGlobalDescribe(); 
        Schema.SObjectType objType = objList.get(sObjAPIName); 
        Schema.Describesobjectresult sobjRes = objType.getDescribe();
        Map<String, Schema.Sobjectfield> fieldMap = sobjRes.fields.getMap();
        
        for(String fieldName : FieldsAPIlst) {
            
            Schema.Sobjectfield field = fieldMap.get(fieldName.trim());
            if(field != null){
                System.debug('fieldMap.get(fieldName)' + fieldMap.get(fieldName));
                System.debug('fieldName>>>'+field.getDescribe());
                System.debug('fieldMap>>>'+field.getDescribe());
                System.debug('field>>>>'+field);
                String fieldNames1 = field.getDescribe().getLabel();
                String fType = field.getDescribe().getType().name();
                if(fType == 'CURRENCY'){
                    if(fieldName == 'celsrm__balance__c'){
                        String trmp = 'FORMAT('+fieldName +') Balance';
                        fieldType.add(trmp);
                        fieldType.add('celsrm__balance__c');
                    } else {
                        String trmp = 'FORMAT('+fieldName +')';
                        fieldType.add(trmp);
                    }
                //-- Starts | FIN-8999| Changes By: Asera | 19 JAN 2026 --//
                } else if(fType == 'DOUBLE' || fType == 'INTEGER' || fType == 'LONG'){
                    String trmp = 'FORMAT('+fieldName +')';
                    fieldType.add(trmp);
                //-- End | FIN-8999| Changes By: Asera | 19 JAN 2026 --//
                } else if(fType == 'REFERENCE') {
                    fieldName = fieldName.subString(0,fieldName.length()-1)+ 'r.name';
                    fieldType.add(fieldName);
                } else{
                    fieldType.add(fieldName );
                }
            }
        } 
        return fieldType;
    }
    
    public static List<String> getTransactionFieldLabel(List<String> FieldsAPIlst){
        
        Double TotalBalance = 0;
        List<String> fieldType = new List<String>{};
            Schema.Sobjecttype objType = celsrm__Transaction__c.getSObjectType();
        Schema.Describesobjectresult sobjRes = objType.getDescribe();
        Map<String, Schema.Sobjectfield> fieldMap = sobjRes.fields.getMap();
        
        for(String fieldName : FieldsAPIlst) {
            
            Schema.Sobjectfield field = fieldMap.get(fieldName);
            if(field != null){
                String fieldNames1 = field.getDescribe().getLabel();
                fieldType.add(fieldNames1);
            }
            // system.debug('---fieldType---'+fieldType);
        } 
        return fieldType;
        
    }

    // TO BE DELETED - MM
    // << START - MM - FIN-8174 - Dynamic translated headers based account local >>
    public static List<String> getTransactionFieldTranslatedLabel(String accountLocale, String objectAPIName, List<String> FieldsAPIlst){
        Double TotalBalance = 0;
        List<String> fieldType = new List<String>{};
        Map<String, String> fieldAPINameVsLabel = new Map<String, String>();
        Map<string, Schema.sObjectType> describeInfo = Schema.getGlobalDescribe();
        if (describeInfo.containsKey(objectAPIName)) {
            Map<String, Schema.SObjectField> fieldMap = describeInfo.get(objectAPIName.toLowerCase()).getDescribe().Fields.getMap();
            for(String fieldName : FieldsAPIlst) {
                Schema.Sobjectfield field = fieldMap.get(fieldName);
                if(field != null){
                    String fieldNames1 = field.getDescribe().getLabel();
                    fieldAPINameVsLabel.put(fieldName.toLowerCase(), fieldNames1);
                }
            }
        }
        // Get translated labels
        
        //Could be possible user has abc in template but field API Name is ABC in translated label object
        List<String> FieldsAPIlstLower = new List<String>();
        for(String fieldName : FieldsAPIlst) {
            FieldsAPIlstLower.add(fieldName.toLowerCase());
        }
        List<celsrm__Translated_Label__c> translatedLabels = [SELECT Id, celsrm__Object_API_Name__c, Name, celsrm__Label__c FROM celsrm__Translated_Label__c WHERE celsrm__Language__c = :accountLocale AND celsrm__Object_API_Name__c = :objectAPIName AND Name IN :FieldsAPIlstLower];
        if(translatedLabels.size() > 0) {
            for(celsrm__Translated_Label__c translatedLabel: translatedLabels) {
                fieldAPINameVsLabel.put(translatedLabel.Name, translatedLabel.celsrm__Label__c);
            }
        }
        for(String fieldName : FieldsAPIlst) {
            if(fieldAPINameVsLabel.containsKey(fieldName.toLowerCase())){
                fieldType.add(fieldAPINameVsLabel.get(fieldName.toLowerCase()));
            } else {
                fieldType.add(fieldName);
            }
        }
        return fieldType;
    }
    // << END - MM - FIN-8174 - Dynamic translated headers based account local >>

    // << START - MM - FIN-10130 | Feature JIRA FIN-8279 - Email Attachment -> Totals by currencycode >> 
    public static String replaceCustomerSpecificPlaceholdersByID(String contentTemplate, String accountId) {
        Account acc = [SELECT Id, celsrm__Locale__c FROM Account WHERE Id =: accountId];
        String locale = acc.celsrm__Locale__c != null ? acc.celsrm__Locale__c : 'EN';
        return replaceCustomerSpecificPlaceholders(contentTemplate, locale);
    }
    // << END - MM - FIN-10130 | Feature JIRA FIN-8279 - Email Attachment -> Totals by currencycode >> 

    // << START - MM - FIN-8174 - Dynamic translated headers based account local >>
    public static String replaceCustomerSpecificPlaceholders(String contentTemplate, String accountLocale) {
        // Identify email template placeholders ({Template.})
        Pattern p = Pattern.compile('\\{Template\\.([^}]*)\\}');
        Matcher m = p.matcher(contentTemplate);
        List<String> emailTemplatePlaceHolders = new List<String>();
        while (m.find()) {
            emailTemplatePlaceHolders.add(m.group(1));
        }
        
        // Fetch email template placeholders translation
        System.debug('emailTemplatePlaceHolders::' + emailTemplatePlaceHolders);
        List<String> translatedPlaceHolders = celsrm.SRMUtilityController.getTransactionFieldTranslatedLabel(accountLocale, 'Template', emailTemplatePlaceHolders);
        System.debug('translatedPlaceHolders::' + translatedPlaceHolders);
        
        // Replace email template placeholders with translations
        Integer columnCounter = 0;
        for (String placeHolder : emailTemplatePlaceHolders){
            if(translatedPlaceHolders.size() - 1 >= columnCounter) {
                contentTemplate = contentTemplate.replace('{Template.' + placeHolder + '}', translatedPlaceHolders[columnCounter]);
            }
            columnCounter++;
        }
        System.debug('contentTemplate::'+ contentTemplate);
        return contentTemplate;
    }
    // << END - MM - FIN-8174 - Dynamic translated headers based account local >>
    
    public static Map<String, List<String>> fetchFromEmails() {
        
        celsrm__SRM_Configuration__c systemConfig = celsrm__SRM_Configuration__c.getOrgDefaults();
        Map<String, List<String>> emailsMap = new Map<String, List<String>>();
        List<OrgWideEmailAddress> listName = [SELECT Id, Address, DisplayName FROM OrgWideEmailAddress where address=:systemConfig.Mailbox_Email_Address__c ];
        System.debug('@@ listName : ' + listName);
        List<String> fromadd = new List<String>();
        System.debug('@@ fromAdd : ');
        if (listName  != null && listName.size()>0 ){
            fromadd .add(listName.get(0).Id);
            emailsMap.put('from',fromadd  );
            
        }
        
        system.debug('return data : ' + emailsMap);
        return emailsMap;
    }

    public static Map<String, List<String>> fetchFromEmail(List<String> possibleFromAddresses) {
        List<String> fromadd = new List<String>();
        Map<String, List<String>> emailsMap = new Map<String, List<String>>();
        if(possibleFromAddresses != null && !possibleFromAddresses.isEmpty()) {
            List<OrgWideEmailAddress> listName = [SELECT Id, Address, DisplayName FROM OrgWideEmailAddress where address IN :possibleFromAddresses ];
            if (listName  != null && listName.size()>0){
                fromadd .add(listName.get(0).Id);
                emailsMap.put('from',fromadd  );
                
            }
        } else {
            celsrm__SRM_Configuration__c systemConfig = celsrm__SRM_Configuration__c.getOrgDefaults();
            List<OrgWideEmailAddress> listName = [SELECT Id, Address, DisplayName FROM OrgWideEmailAddress where address=:systemConfig.Mailbox_Email_Address__c ];
            if (listName  != null && listName.size()>0){
                fromadd .add(listName.get(0).Id);
                emailsMap.put('from',fromadd  );
                
            }
        }
        return emailsMap;
    }
    
    public void TotalInvoiceBalance(List<String> transactionIds){
        String tempSOQLQuery='';
        //-- Start | FIN-8334 | Changed by Ravi | 11 sep 2025 --//
        // totalBillingBal = 0.0;
        //-- End | FIN-8334 | Changed by Ravi | 11 sep 2025 --//
        mapCurBalance = new Map<String,Double>();
        // << START - MM - FIN-8279 - Email Attachment -> Totals by currencycode >>
        mapCurBalanceForOverDue = new Map<String,Double>();
        mapCurBalanceForOverDueNotNoted = new Map<String,Double>();
        // << END - MM - FIN-8279 - Email Attachment -> Totals by currencycode >>
        // << START - MM - FIN-9546 - custom placeholder TotalOpenItems in attachment - celsrm__Close_Date__c flag is missing>> 
        mapCurBalanceOpen = new Map<String,Double>();
        // << END - MM - FIN-9546 - custom placeholder TotalOpenItems in attachment - celsrm__Close_Date__c flag is missing>> 
        //-- Start | FIN-8334 | Changed by Ravi | 11 sep 2025 --//
        // crCodes = new Set<String>();
        //-- End | FIN-8334 | Changed by Ravi | 11 sep 2025 --//
        if(UserInfo.IsMultiCurrencyOrganization()){
             // << START - MM - FIN-8279 - Email Attachment -> Totals by currencycode >> 
            // tempSOQLQuery = 'Select CurrencyIsoCode ,celsrm__balance__c, celsrm__base_balance__c From celsrm__Transaction__c where   Id in :transactionIds Limit 9999';
            // << CHANGE - MM - FIN-9546 - custom placeholder TotalOpenItems in attachment - celsrm__Close_Date__c flag is missing | Added celsrm__Close_Date__c in query>> 
            tempSOQLQuery = 'Select CurrencyIsoCode ,celsrm__balance__c, celsrm__base_balance__c, celsrm__DPD__c, Noted__c, celsrm__Close_Date__c From celsrm__Transaction__c where   Id in :transactionIds Limit 9999';
            // << END - MM - FIN-8279 - Email Attachment -> Totals by currencycode >>
        }else{
            // << START - MM - FIN-8279 - Email Attachment -> Totals by currencycode >> 
            // tempSOQLQuery = 'Select celsrm__balance__c, celsrm__base_balance__c From celsrm__Transaction__c where   Id in :transactionIds Limit 9999';
            // << CHANGE - MM - FIN-9546 - custom placeholder TotalOpenItems in attachment - celsrm__Close_Date__c flag is missing | Added celsrm__Close_Date__c in query>> 
            tempSOQLQuery = 'Select celsrm__balance__c, celsrm__base_balance__c, celsrm__DPD__c, Noted__c, celsrm__Close_Date__c From celsrm__Transaction__c where   Id in :transactionIds Limit 9999';
            // << END - MM - FIN-8279 - Email Attachment -> Totals by currencycode >> 
        }
        List<celsrm__Transaction__c> nextTransactions = Database.query(tempSOQLQuery);
        //-- Start | FIN-8334 | Changed by Ravi | 11 sep 2025 --//
        // String txcurrency;
        //-- End | FIN-8334 | Changed by Ravi | 11 sep 2025 --//
         String CurrencyIsoCode ='USD';
         //-- Start | FIN-8334 | Changed by Ravi | 11 sep 2025 --//
        // if(UserInfo.IsMultiCurrencyOrganization()){
                
                // celsrm__Transaction__c transcur = new celsrm__Transaction__c();
                // if(nextTransactions.size() > 0)
                //      transcur = nextTransactions.get(0);
                 
                //    txcurrency = (String)transcur.get('CurrencyIsoCode');
                   
                //    for(celsrm__Transaction__c tx : nextTransactions ){
                //        if(! ((String)tx.get('CurrencyIsoCode')).equalsIgnoreCase(txcurrency)){
                       
                //           // currencyChanged = true;
                //            currencyChange = true;
                           
                //            break;
                //         }
                        
                //    }
                //    if(currencyChange == false){
                //        transactioncurr = txcurrency;
                //    }
                // }
                //-- End | FIN-8334 | Changed by Ravi | 11 sep 2025 --//
                for(celsrm__Transaction__c nextTr : nextTransactions ) {
                 
                  currencyIsoCode = (String)(UserInfo.IsMultiCurrencyOrganization() ? nextTr.get('CurrencyIsoCode') : UserInfo.getDefaultCurrency());
                    populateMapCurBalance(currencyIsoCode,double.valueof(nextTr.celsrm__balance__c));
                    // << START - MM - FIN-8279 - Email Attachment -> Totals by currencycode >>
                    // if(!mapCurBalanceForOverDue.containsKey(currencyIsoCode)) {
                    //     populateMapCurBalanceForOverDue(currencyIsoCode, Double.valueOf(0.0));
                    // }
                    // if(!mapCurBalanceForOverDueNotNoted.containsKey(currencyIsoCode)) {
                    //     populateMapCurBalanceForOverDueNotNoted(currencyIsoCode, Double.valueOf(0.0));
                    // }
                    // << START - MM - FIN-9546 - custom placeholder TotalOpenItems in attachment - celsrm__Close_Date__c flag is missing>> 
                    if(nextTr.celsrm__Close_Date__c == null) {
                        populateMapCurBalanceOpen(currencyIsoCode,double.valueof(nextTr.celsrm__balance__c));
                    } else {
                        if(!mapCurBalanceOpen.keySet().contains(currencyIsoCode)) {
                            mapCurBalanceOpen.put(currencyIsoCode, 0.0);
                        }
                    }
                    // << END - MM - FIN-9546 - custom placeholder TotalOpenItems in attachment - celsrm__Close_Date__c flag is missing>> 
                    if(nextTr.celsrm__DPD__c != null && nextTr.celsrm__DPD__c > 0) {
                        populateMapCurBalanceForOverDue(currencyIsoCode,double.valueof(nextTr.celsrm__balance__c));
                        if(nextTr.Noted__c == null || nextTr.Noted__c == '') {
                            populateMapCurBalanceForOverDueNotNoted(currencyIsoCode,double.valueof(nextTr.celsrm__balance__c));
                        } 
                        // << START - MM - FIN-9546 - custom placeholder TotalOpenItems in attachment - celsrm__Close_Date__c flag is missing>> 
                        else {
                            if(!mapCurBalanceForOverDueNotNoted.keySet().contains(currencyIsoCode)) {
                                mapCurBalanceForOverDueNotNoted.put(currencyIsoCode, 0.0);
                            }
                        }
                        // << END - MM - FIN-9546 - custom placeholder TotalOpenItems in attachment - celsrm__Close_Date__c flag is missing>> 
                    } 
                    // << START - MM - FIN-9546 - custom placeholder TotalOpenItems in attachment - celsrm__Close_Date__c flag is missing>> 
                    else {
                        if(!mapCurBalanceForOverDue.keySet().contains(currencyIsoCode)) {
                            mapCurBalanceForOverDue.put(currencyIsoCode, 0.0);
                        }
                        if(!mapCurBalanceForOverDueNotNoted.keySet().contains(currencyIsoCode)) {
                            mapCurBalanceForOverDueNotNoted.put(currencyIsoCode, 0.0);
                        }
                    }
                    // << END - MM - FIN-9546 - custom placeholder TotalOpenItems in attachment - celsrm__Close_Date__c flag is missing>> 
                    // << END - MM - FIN-8279 - Email Attachment -> Totals by currencycode >>
                    //-- Start | FIN-8334 | Changed by Ravi | 11 sep 2025 --//
                    // if(currencyChange == true && (UserInfo.IsMultiCurrencyOrganization()== true || test.isRunningTest())){
                                        
                    //         if(nextTr.celsrm__base_balance__c != null)
                    //             totalBillingBal = totalBillingBal + nextTr.celsrm__base_balance__c;  
                    //     }else if ((UserInfo.IsMultiCurrencyOrganization()== true || test.isRunningTest()) && currencyChange == false){
                    //           if(nextTr.celsrm__balance__c != null)
                    //             totalBillingBal = totalBillingBal + nextTr.celsrm__balance__c;   
                     
                    //  }else{
                    //         if(nextTr.celsrm__balance__c != null)
                    //             totalBillingBal = totalBillingBal + nextTr.celsrm__balance__c;   
                     
                    // }     
                    //-- End | FIN-8334 | Changed by Ravi | 11 sep 2025 --//      
                       
                }
        // return null;
    }

    public String strTotalBalanceSummary(){
         String  v = '';
      
        
        if(mapCurBalance != null && mapCurBalance.size() >0){
            for(String trancurr:mapCurBalance.keyset()){
            If(trancurr != null && trancurr != ''){
                //-- Start | FIN-8334 | Changed by Ravi | 11 sep 2025 --//
                // v+= trancurr+' : '+UtilityController.formatAsCurrency(mapCurBalance.get(trancurr))+', ';
                v+= UtilityController.formatDoubleValue(trancurr, mapCurBalance.get(trancurr)) +', ';
                //-- End | FIN-8334 | Changed by Ravi | 11 sep 2025 --//
            }
            }
            v = v.substring(0,v.length()-2);
       
        }
        //System.debug('----v-------'+v);
        return v;
            
    }
    private void populateMapCurBalance(String currencyIsoCode, double currValue){
        if(currencyIsoCode!=null && currValue!=null){
            
           // system.debug('crCodes----' + crCodes);
            //-- Start | FIN-8334 | Changed by Ravi | 11 sep 2025 --//
            if(mapCurBalance.containsKey(currencyIsoCode)){
            //-- End | FIN-8334 | Changed by Ravi | 11 sep 2025 --//
                Double bal = (Double)mapCurBalance.get(currencyIsoCode);
               // system.debug('bal----' + bal);
                bal+= currValue;
                mapCurBalance.put(currencyIsoCode,bal);
            }else{
                //-- Start | FIN-8334 | Changed by Ravi | 11 sep 2025 --//
                // crCodes.add(currencyIsoCode);
                //-- End | FIN-8334 | Changed by Ravi | 11 sep 2025 --//
              //  system.debug('currValue----' + currValue);
                mapCurBalance.put(currencyIsoCode,currValue);
            }
            
          //  system.debug('mapCurBalance----' + mapCurBalance);
        }
    }

    // << START - MM - FIN-8279 - Email Attachment -> Totals by currencycode >> 
    private void populateMapCurBalanceForOverDue(String currencyIsoCode, double currValue){
        if(currencyIsoCode!=null && currValue!=null){
            
            if(mapCurBalanceForOverDue.containsKey(currencyIsoCode)){
                Double bal = (Double)mapCurBalanceForOverDue.get(currencyIsoCode);
                bal+= currValue;
                mapCurBalanceForOverDue.put(currencyIsoCode,bal);
            }else{
                mapCurBalanceForOverDue.put(currencyIsoCode,currValue);
            }
        }
    }
    // << END - MM - FIN-8279 - Email Attachment -> Totals by currencycode >> 

    // << START - MM - FIN-9546 - custom placeholder TotalOpenItems in attachment - celsrm__Close_Date__c flag is missing>> 
    private void populateMapCurBalanceOpen(String currencyIsoCode, double currValue){
        if(currencyIsoCode!=null && currValue!=null){
            
            if(mapCurBalanceOpen.containsKey(currencyIsoCode)){
                Double bal = (Double)mapCurBalanceOpen.get(currencyIsoCode);
                bal+= currValue;
                mapCurBalanceOpen.put(currencyIsoCode,bal);
            }else{
                mapCurBalanceOpen.put(currencyIsoCode,currValue);
            }
        }
    }

    public String strTotalBalanceOpenSummary(){
         String  v = '';
        if(mapCurBalanceOpen != null && mapCurBalanceOpen.size() >0){
            for(String trancurr:mapCurBalanceOpen.keyset()){
            If(trancurr != null && trancurr != ''){
                v+= UtilityController.formatDoubleValue(trancurr, mapCurBalanceOpen.get(trancurr)) +', ';
              }
            }
            v = v.substring(0,v.length()-2);
        }
        //System.debug('----v-------'+v);
        return v;
    }
    // << END - MM - FIN-9546 - custom placeholder TotalOpenItems in attachment - celsrm__Close_Date__c flag is missing>> 

    public String strTotalBalanceForOverDueSummary(){
         String  v = '';
        if(mapCurBalanceForOverDue != null && mapCurBalanceForOverDue.size() >0){
            for(String trancurr:mapCurBalanceForOverDue.keyset()){
            If(trancurr != null && trancurr != ''){
                v+= UtilityController.formatDoubleValue(trancurr, mapCurBalanceForOverDue.get(trancurr)) +', ';
              }
            }
            v = v.substring(0,v.length()-2);
        }
        //System.debug('----v-------'+v);
        return v;
    }

    // << START - MM - FIN-8279 - Email Attachment -> Totals by currencycode >> 
    private void populateMapCurBalanceForOverDueNotNoted(String currencyIsoCode, double currValue){
        if(currencyIsoCode!=null && currValue!=null){
            
            if(mapCurBalanceForOverDueNotNoted.containsKey(currencyIsoCode)){
                Double bal = (Double)mapCurBalanceForOverDueNotNoted.get(currencyIsoCode);
                bal+= currValue;
                mapCurBalanceForOverDueNotNoted.put(currencyIsoCode,bal);
            }else{
                mapCurBalanceForOverDueNotNoted.put(currencyIsoCode,currValue);
            }
        }
    }
    // << END - MM - FIN-8279 - Email Attachment -> Totals by currencycode >> 

    public String strTotalBalanceForOverDueNotNotedSummary(){
         String  v = '';
        if(mapCurBalanceForOverDueNotNoted != null && mapCurBalanceForOverDueNotNoted.size() >0){
            for(String trancurr:mapCurBalanceForOverDueNotNoted.keyset()){
            If(trancurr != null && trancurr != ''){
                v+= UtilityController.formatDoubleValue(trancurr, mapCurBalanceForOverDueNotNoted.get(trancurr)) +', ';
              }
            }
            v = v.substring(0,v.length()-2);
        }
        //System.debug('----v-------'+v);
        return v;
    }

     //-- Start | FIN-8334 | Changed by Ravi | 11 sep 2025 --//
    // public static List < Account > getAccountWithCurrencyIsoCode ( String accId  ) {

 
    //     if(UserInfo.IsMultiCurrencyOrganization()){
    //         String SOQLQuery = 'Select CurrencyIsoCode from Account where id=:accId Limit 1';
    //         ApexPages.StandardSetController con = new ApexPages.StandardSetController(Database.getQueryLocator(SOQLQuery ));
    //         List < Account > acc =(List < Account >)con.getRecords();
    //          return acc;
    //     }else{
    //         return new List<Account>();
    //     }
    //  }
    
    //  public Double getTotalTransactionBalance() {
    //     return totalBillingBal;
    // }
   
    // public Boolean getCurrencyChanged() {
    //     return currencyChange;
    // }
    // public String getTransactionCurrencyChanged() {
    //     return transactioncurr;
    // }
     //-- End | FIN-8334 | Changed by Ravi | 11 sep 2025 --//
    public static Account getNotesFromAccount( Account acc,String olderValueNotes,String NoteTitle,String NewNotesBody,String TemplateName   ) {
        String ntBody='';
        if(NoteTitle != null){
            ntBody = NoteTitle + '\n'+NewNotesBody;
        }else{
            ntBody = NewNotesBody;
        }
        // if(olderValueNotes != null){
        // acc.celsrm__Notes__c = ntBody+'\n'+UserInfo.getName() +':'+date.today().year()+'-'+date.today().month()+'-'+date.today().day() +'\n'+'\n'+olderValueNotes;
        // }else{
        // acc.celsrm__Notes__c =ntBody+'\n'+UserInfo.getName() +':'+date.today().year()+'-'+date.today().month()+'-'+date.today().day() ;   
        // } 
        acc.celsrm__Latest_Note__c = NewNotesBody;
        acc.celsrm__Latest_Note_Date__c = Date.Today();
        // acc.celsrm__Latest_Note_By__c = UserInfo.getUserId();
        acc.celsrm__Latest_Note_Title__c = NoteTitle ;
        // acc.celsrm__Latest_Simple_Note__c =NewNotesBody;
        
        return acc;
     }

     public static celsrm__Transaction__c getNotesFromTransaction(celsrm__Transaction__c trxobj,String olderValueNotes,String NoteTitle,String NewNotesBody ,String TemplateName  ) {
            trxobj.celsrm__Latest_Note_Title__c = NoteTitle;
            trxobj.celsrm__Latest_Note_Date__c = date.today();
            trxobj.celsrm__Latest_Note__c  =  NoteTitle+'\n'+ NewNotesBody ;
            // trxobj.celsrm__Latest_Note_Entered_By__c = UserInfo.getUserId();           
            // trxobj.celsrm__Notes__c =   NoteTitle +'\n'+ NewNotesBody +'\n'+ UserInfo.getName() + ':' +date.today().year()+'-'+date.today().month()+'-'+date.today().day() +  '\n\n' + (olderValueNotes != null && olderValueNotes != ''? olderValueNotes : '') ;
            return trxobj;
     }
      public static celsrm__Dispute__c getNotesFromTransaction(celsrm__Dispute__c dis,String olderValueNotes,String NoteTitle,String NewNotesBody ,String TemplateName  ) {
            dis.put('celsrm__Latest_Note_Title__c' , NoteTitle);
            dis.celsrm__Latest_Note_Date__c = date.today();
            //  currentTrx.Latest_Note__c = String.valueOf(inMap.get('NoteTitle')) + '\n' + String.valueOf(inMap.get('NoteBody'));
            dis.celsrm__Latest_Note__c =  NewNotesBody  ;     
            // dis.celsrm__Latest_Note_Entered_By__c = UserInfo.getUserId();
            // dis.celsrm__Notes__c = NoteTitle + '\n' + NewNotesBody   +'\n'+UserInfo.getName() + ':' + date.today().year()+'-'+date.today().month()+'-'+date.today().day() + '\n\n' + (olderValueNotes  != null && olderValueNotes  != '' ? olderValueNotes  : '');
            return dis;
     }
     public static SObject getNotesFromSObject(SObject sobj,String olderValueNotes,String NoteTitle,String NewNotesBody ,String TemplateName ,String ContactName  ) {
                  String NoteTitleEmail='';
                if (NoteTitle== 'Email'){
                    NoteTitleEmail = 'EMAILED - ';
                }else if(NoteTitle   == 'Phone'){
                    NoteTitleEmail = 'PHONED - ';
                }else if(NoteTitle   == 'Fax'){
                    NoteTitleEmail = 'FAXED - ';
                }else if(NoteTitle   == 'Save'){
                    NoteTitleEmail = 'CREATE - ';
                }
            sobj.put('celsrm__Latest_Note_Title__c' , NoteTitle);
            sobj.put('celsrm__Latest_Note_Date__c' ,date.today());
            //  currentTrx.Latest_Note__c = String.valueOf(inMap.get('NoteTitle')) + '\n' + String.valueOf(inMap.get('NoteBody'));
            sobj.put('celsrm__Latest_Note__c' ,  NewNotesBody ) ;     
            // sobj.put('celsrm__Latest_Note_Entered_By__c', UserInfo.getUserId());
            // sobj.put('celsrm__Notes__c', NoteTitle + NewNotesBody  +TemplateName   +'\n'+UserInfo.getName() + ':' + date.today().year()+'-'+date.today().month()+'-'+date.today().day() + '\n\n' + (olderValueNotes  != null && olderValueNotes  != '' ? olderValueNotes  : ''));
            return sobj;
     }
     public static String getDefaultContactName(List<object> Toaddressobj){
          system.debug('======Toaddressobj====='+ Toaddressobj);
         List<String> Toaddress = new List < string > ();
          for (object obj: Toaddressobj) {
                    if (obj instanceof String) {
                        Toaddress.add(String.valueOf(obj));
                    } else {
                        Map<Object, Object> newMap = (Map<Object, Object>)obj;
                        Toaddress.add(String.valueOf(newMap.get('value')));
                    }
                }
               
                String ContactName = Toaddress.get(0).trim().split('@')[0];
                return ContactName;
                
     }
     public static String getDefaultContactMethodName(String NoteTitle){
            String NoteTitleEmail='';
                if (NoteTitle== 'Email'){
                    NoteTitleEmail = 'EMAILED - ';
                }else if(NoteTitle   == 'Phone'){
                    NoteTitleEmail = 'PHONED - ';
                }else if(NoteTitle   == 'Fax'){
                    NoteTitleEmail = 'FAXED - ';
                }else if(NoteTitle   == 'DNC'){
                    NoteTitleEmail = 'CREATE - ';
                }
          return NoteTitleEmail;
    }

    public static string getQueryWhereClause(String filterCriteria) {
        String whereClause = '';
        if(filterCriteria != null) {
            Map<String, Object> filterObj = (Map<String,Object>)JSON.deserializeUntyped(filterCriteria);
            List<Object> criteriasRaw = (List<Object>) filterObj.get('criterias');
            List<Map<String, Object>> filters = new List<Map<String, Object>>();
            for(Object criteria : criteriasRaw) {
                filters.add((Map<String, Object>) criteria);
            }

            String criteriaCondition = String.valueOf(filterObj.get('condition'));

            List<String>  conditionList =  new List<String>();
            List<String>  conditionListValue =  new List<String>();
            if (criteriaCondition != null && criteriaCondition != ' ') {
                conditionList = criteriaCondition.split(' ');   // ["(1","AND","2)"]
            }
            Integer conditionListLength = conditionList.size();

            for (Integer l = 0; l < conditionListLength; l++) {
                if (conditionList[l].isWhitespace()) {
                    conditionList.remove(l);
                    continue;
                }
                conditionListValue.add(conditionList[l]);

                System.debug('conditionList[l]:::' + conditionList[l]);
                System.debug('conditionListValue:::' + conditionListValue);
            }


            if(filters.size() > 0) {
                Map<String, String> filtersMap = new Map<String, String>();
                for(Integer i=0; i<filters.size(); i++) {
                    System.debug('conditionListValue:::' + conditionListValue);
                    String field = String.valueOf(filters[i].get('fieldName'));
                    String operator = String.valueOf(filters[i].get('operator'));
                    String value = String.valueOf(filters[i].get('value'));
                    String type = String.valueOf(filters[i].get('type'));

                    String tmpWhere = defaultViewClass.buildQuery(field, operator, value, type);
                    filtersMap.put(String.valueOf(i + 1), tmpWhere);
                }
                if(conditionListValue.size() > 0 && filtersMap.size() > 0) {//[1, AND, 2)AND, 3]
                    for(Integer i=0; i<conditionListValue.size(); i++) {
                        // String conditionPart = conditionListValue[i];
                        List<String> conditionParts = conditionListValue[i].split('');
                        for(Integer j=0; j<conditionParts.size(); j++) {
                            if(filtersMap.containsKey(conditionParts[j])) {
                                conditionParts[Integer.valueOf(j)] = filtersMap.get(conditionParts[j]);
                            }
                        }
                        System.debug('conditionParts:::'+ conditionParts);
                        conditionListValue[i] = String.join(conditionParts, '');
                        System.debug('conditionListValue:::'+ conditionListValue);
                    }
                }
                if(conditionListValue.size() > 0) {
                    System.debug('@@@@conditionList:::: ' + conditionListValue);
                    conditionListValue = defaultViewClass.removeParentheses(conditionListValue);
                    whereClause = ' WHERE ' + string.join(conditionListValue,' ');
                    System.debug('@@@ whereClause :::: ' + whereClause);
                }    
            }
        }
        return whereClause;
    }

    public static string getQueryFields(String objectFields, String objectName) {
        String selectedFields = '';
        List<String> objFieldList = new List<String>();
        List<Object> fieldList = (List<Object>)JSON.deserializeUntyped(objectFields);
        for (Object fieldObj : fieldList) {
            Map <String, Object> fieldMap = (Map <String, Object> ) fieldObj;
            String fieldName = (String)fieldMap.get('fieldName');
            if(fieldMap.get('isExport') != null && (Boolean)fieldMap.get('isExport') == true && (Boolean)fieldMap.get('hide') != true) {
                objFieldList.add(fieldName);
            } 
        }
        selectedFields = string.join(objFieldList,',');
        return selectedFields;
    }
    //-- Start | FIN-8949 | Changed By Dhwanil | 30 Jan 2026 --//
    public static string getQueryFieldsType(String objectFields, String objectName) {
        String selectedFieldstype = '';
        Map<String, String> objFieldList = new Map<String, String>();
        List<Object> fieldList = (List<Object>)JSON.deserializeUntyped(objectFields);
        for (Object fieldObj : fieldList) {
            Map <String, Object> fieldMap = (Map <String, Object> ) fieldObj;
            String fieldName = (String)fieldMap.get('fieldName');
            if(fieldMap.get('isExport') != null && (Boolean)fieldMap.get('isExport') == true && (Boolean)fieldMap.get('hide') != true) {
                objFieldList.put(fieldName, (String)fieldMap.get('type'));
            } 
        }
        selectedFieldstype = JSON.serialize(objFieldList);
        return selectedFieldstype;
    }

    public static String getFieldDataType(String objectApiName, String fieldApiName) {

        if (String.isBlank(objectApiName) || String.isBlank(fieldApiName)) {
            return null;
        }

        // Get all objects
        Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();

        if (!globalDescribe.containsKey(objectApiName)) {
            return null;
        }

        Schema.SObjectType sObjectType = globalDescribe.get(objectApiName);
        Schema.DescribeSObjectResult objDescribe = sObjectType.getDescribe();

        // Get fields
        Map<String, Schema.SObjectField> fieldMap = objDescribe.fields.getMap();

        if (!fieldMap.containsKey(fieldApiName)) {
            return null;
        }

        Schema.DescribeFieldResult fieldDescribe = fieldMap.get(fieldApiName).getDescribe();

        // Return normalized datatype
        return String.valueOf(fieldDescribe.getType()).toLowerCase();
    }
    //-- End | FIN-8949 | Changed By Dhwanil | 30 Jan 2026 --//

    public static String getQuerySortOrder(String sortByFieldObj, Boolean addOrderByClause) {
        String sortOrderStr = '';
        List<String> sortings = new List<String>();
        List<Map<String, String>> sortByFields = (List<Map<String, String>>)JSON.deserialize(sortByFieldObj, List<Map<String, String>>.class);
        if(sortByFields.size() > 0) {
            for(Map<String, String> sortByFieldMap: sortByFields) {
                String sortByFieldStr = '';
                if(sortByFieldMap.get('fieldName') != null && sortByFieldMap.get('fieldName') != '') {
                    sortByFieldStr += String.valueOf(sortByFieldMap.get('fieldName'));
                }
                if(sortByFieldMap.get('order') != null && sortByFieldMap.get('order') != '') {
                    sortByFieldStr += ' ' + String.valueOf(sortByFieldMap.get('order'));
                } else {
                    sortByFieldStr += ' ASC';
                }
                sortings.add(sortByFieldStr);
            }
            sortOrderStr = addOrderByClause ? 'ORDER BY '+String.join(sortings, ', ') : String.join(sortings, ', ');
        }
        return sortOrderStr;
    }
    
    public static Map<Object, Object> captureCelonisEventsOld(Map<Object, Object> inMap, String activityName) { 
        //-- activityName will be like 'Send Email', 'Log A Call', etc --//
        //-- Starts | Update Last Contact information on Account --//
        String accountId = (String) inMap.get('Id');
        Account accountObj = new Account();
        accountObj.Id = accountId;
        accountObj.celsrm__Last_Contact_Date__c = date.Today();
        accountObj.celsrm__Last_Contact_Method__c = activityName;
        accountObj.celsrm__Last_Contact_Type__c = activityName == 'Send Email' ? 'Email' : activityName == 'Log A Call' ? 'Phone' : '';
        update accountObj;
        //-- Ends | Update Last Contact information on Account --//

        Datetime currentDateTime = Datetime.now();
        String activityNote = inMap.get('NoteBody') != null && inMap.get('NoteBody') != '' ? String.valueOf(inMap.get('NoteBody')) : null;
        //-- Starts | Capture Celonis Event at Account Level --//
        List<String> accoutIdList = new List<String>();
        accoutIdList.add(accountId);
        if(activityName == 'Log A Call') {
            List<celsrm__Celonis_Event__c> activityList = new List<celsrm__Celonis_Event__c>();
            celsrm__Celonis_Event__c activity = new celsrm__Celonis_Event__c();
            activity.celsrm__Account__c = accountId;
            activity.celsrm__Activity_Id__c = 'E-'+String.valueOf(Datetime.now().getTime()).substring(5, 13) + (Math.abs(Crypto.getRandomInteger()) / 100);
            activity.celsrm__Event_Id__c = 'E-'+String.valueOf(Datetime.now().getTime()).substring(5, 13) + (Math.abs(Crypto.getRandomInteger()) / 100);
            activity.Name = activityName;
            activity.celsrm__Event_Time__c = currentDateTime;
            activity.celsrm__Metadata__c = null;
            activity.celsrm__Note__c = activityNote;
            activity.celsrm__Sorting__c = 100;
            activity.celsrm__Source_System__c = 'Internal';
            activity.celsrm__User__c = UserInfo.getUserId();
            activity.Phone_Type__c = String.valueOf(inMap.get('PhoneType'));
            activity.Response_By_Contact__c = String.valueOf(inMap.get('ResponseByContact'));
            activity.Contact__c = String.valueOf(inMap.get('ContactName')).split('_')[0];
            activityList.add(activity);
            insert activityList;
        } else {
            celsrm.SRMUtilityController.insertActivity(accoutIdList, 'celsrm__Account__c', activityName, currentDateTime, 100, activityNote, UserInfo.getUserId(), null, 'Internal');
        }
        //-- Ends | Capture Celonis Event at Account Level --//

        //-- Starts | Update Last Contact & Latest Note information on invoices --//
        List < celsrm__Transaction__c > trxList = new List < celsrm__Transaction__c > ();
        List<Object> trxns = (List<Object>) inMap.get('TransactionList');
        List<String> transIDList = new List<String>();
        for(Object trxn : trxns) {
            map < Object, Object> m = (map < Object, Object > )trxn;
            String trxId = (String)m.get('Id');
            transIDList.add(trxId);
            celsrm__Transaction__c currentTrx = New celsrm__Transaction__c(Id=trxId);
            currentTrx.celsrm__Last_Contact_Date__c = date.Today();
            currentTrx.celsrm__Last_Contacted_By__c = UserInfo.getUserId();
            if(String.valueOf(inMap.get('NoteBody')) != null) {
                currentTrx.celsrm__Latest_Note__c =  String.valueOf(inMap.get('NoteBody'));    
                //currentTrx.celsrm__Latest_Note_Title__c = String.valueOf(inMap.get('NoteTitle'));
                currentTrx.celsrm__Latest_Note_Date__c = date.today();
                currentTrx.celsrm__Latest_Note_Entered_By__c = UserInfo.getUserId();
            }
            trxList.add(currentTrx);
            
        }
        if (trxList != null && trxList.size() > 0) {
            update trxList;
        }
        //-- Ends | Update Last Contact information on invoices --//
        
        //-- Starts | Capture Celonis Event at Invoice level --//   
        
        if(!transIDList.isEmpty()) {
            if(activityName == 'Log A Call') {
                List<celsrm__Celonis_Event__c> activityList = new List<celsrm__Celonis_Event__c>();
                for (String tranId : transIDList) {
                    celsrm__Celonis_Event__c activity = new celsrm__Celonis_Event__c();
                    activity.celsrm__Transaction__c = tranId;
                    activity.celsrm__Activity_Id__c = 'E'+String.valueOf(Datetime.now().getTime());
                    activity.Name = activityName;
                    activity.celsrm__Event_Time__c = currentDateTime;
                    activity.celsrm__Metadata__c = null;
                    activity.celsrm__Note__c = activityNote;
                    activity.celsrm__Sorting__c = 100;
                    activity.celsrm__Source_System__c = 'Internal';
                    activity.celsrm__User__c = UserInfo.getUserId();
                    activity.Phone_Type__c = String.valueOf(inMap.get('PhoneType'));
                    activity.Response_By_Contact__c = String.valueOf(inMap.get('ResponseByContact'));
                    activity.Contact__c = inMap.get('ContactName') != null ? String.valueOf(inMap.get('ContactName')).split('_')[0] : null;
                    activityList.add(activity);
                }
                insert activityList;
            } else {
                celsrm.SRMUtilityController.insertActivity(transIDList, 'celsrm__Transaction__c', activityName, currentDateTime, 100, activityNote, UserInfo.getUserId(), null, 'Internal');
            }
        }
        //-- Ends | Capture Celonis Event at Invoice level --//

        return inMap;
    }

    public static Map<Object, Object> captureCelonisEvents(Map<Object, Object> inMap, List<String> idList, String objectName, String activityName) { 
        Datetime currentDateTime = Datetime.now();
        String activityNote = inMap.get('NoteBody') != null && inMap.get('NoteBody') != '' ? String.valueOf(inMap.get('NoteBody')) : null;
        List<celsrm__Celonis_Event__c> activityList = new List<celsrm__Celonis_Event__c>();
        Integer index = 0;
        for(String recordId: idList) {
            celsrm__Celonis_Event__c activity = new celsrm__Celonis_Event__c();
            String relatedFieldName = objectName;
            if(objectName == 'Account') {
                relatedFieldName = 'celsrm__Account__c';
            } 
            activity.put(relatedFieldName, recordId);
            activity.Name = activityName;
            activity.celsrm__Event_ID__c = 'E' + String.valueOf(Datetime.now().getTime()) + index;
            activity.celsrm__Activity_Id__c = 'E' + String.valueOf(Datetime.now().getTime()) + index;
            
            activity.celsrm__Event_Time__c = currentDateTime;
            activity.celsrm__Metadata__c = null;
            activity.celsrm__Note__c = activityNote;
            activity.celsrm__Sorting__c = 100;
            activity.celsrm__Source_System__c = 'Internal';
            activity.celsrm__User__c = UserInfo.getUserId();
            if(activityName == 'Log A Call') {
                activity.Phone_Type__c = String.valueOf(inMap.get('PhoneType'));
                activity.Response_By_Contact__c = String.valueOf(inMap.get('ResponseByContact'));
                activity.Contact__c = inMap.get('ContactName') != null && inMap.get('ContactName') != '' ? String.valueOf(inMap.get('ContactName')).split('_')[0] : null;
            }
            activityList.add(activity);
            index++;
        }
        insert activityList;
        return inMap;
    }

    //-- This method will return corporate currency or group currency --//
    @AuraEnabled
    public static String getCorporateCurrency() {
        String corporateCurrency = UserInfo.getDefaultCurrency();
        if(UserInfo.isMultiCurrencyOrganization()) {
            List<CurrencyType> currencies = [SELECT Id, IsCorporate, IsoCode FROM CurrencyType WHERE IsActive=true];
            for (CurrencyType cur : currencies) {
                if (cur.IsCorporate) {
                    corporateCurrency = cur.IsoCode;
                }
            }
        }
        return corporateCurrency;
    }

    @InvocableMethod
    public static List<String> getRandomNumbers(List<Integer> requests) {
        List<String> randomNumbers = new List<String>();
        for (Integer req : requests) {
            String randomNumber = 'E-'+String.valueOf(Datetime.now().getTime()).substring(5, 13) + (Math.abs(Crypto.getRandomInteger()) / 100);
            randomNumbers.add(randomNumber);
        }
        return randomNumbers;
    }
    //-- Starts | FIN-7296 | 18 Mar 2024 --//
    //-- Starts | FIN-6361 | Changed by Dilshad | 28 Aug 2024 --//
    //-- This method updates action Taken on EmailMessage --//
    public static void updateActionTakenOnEmailMessage(String emailMessageId, String actionName) {
         //-- Starts | FIN-7392 | Changed by Asera | 11 Apr 2025 --//
         Map<String,Object> reqParamMap = new Map<String,Object>();
         reqParamMap.put('emailId', emailMessageId);
         reqParamMap.put('actionName', actionName);
         reqParamMap.put('action','actionPerform');
         Map<String,String> response = celsrm.GOGUtilityWithoutSharingController.updateEmailActionCount(reqParamMap);
         if (response.containsKey('Error')) {
             throw new celsrm.GOGDataServiceLoadException(response.get('Error'));         
         }
        //-- End | FIN-7392 | Changed by Asera | 11 Apr 2025 --//
        // EmailMessage em = [
        //     SELECT Id, celsrm__Action_Taken__c, celsrm__Action_Taken_By__c, celsrm__Action_Taken_Time__c, celsrm__Action_Details__c
        //     FROM EmailMessage
        //     WHERE Id = :emailMessageId
        //     LIMIT 1
        // ];
        // // Check if "Action Taken" field is already populated
        // if (String.isBlank(em.celsrm__Action_Taken__c)) {
        //     em.celsrm__Action_Taken__c = actionName;
        //     em.celsrm__Action_Taken_By__c = UserInfo.getUserId();
        //     em.celsrm__Action_Taken_Time__c = Date.today();
        // }

        // String newActionEntry = 'Action: '+ actionName + '\n'+
        //                         'Action Taken By: ' + UserInfo.getName() + '\n'+
        //                         'Action Taken On: '+ DateTime.now().format('yyyy-MM-dd HH:mm:ss') + '(GMT)'+'\n' +
        //                         '-------------------------------------------------------------\n'; 
        
        // if (String.isNotBlank(em.celsrm__Action_Details__c)) {
        //     em.celsrm__Action_Details__c += '\n'+ newActionEntry;
        // } else{
        //     em.celsrm__Action_Details__c = '-------------------------------------------------------------\n'+newActionEntry;
        // }
        // update em;
    }
    //-- Ends | FIN-6361 | Changed by Dilshad | 28 Aug 2024 --//
    //-- Ends | FIN-7296 | 18 Mar 2024 --//

    //-- Starts |FIN-7502| Changed by Asera | 25 Nov 2025 --//
    @AuraEnabled(cacheable=false)
    public static Id logActivity(String inputParamsJson) {
        if (String.isBlank(inputParamsJson)) {
            throw new AuraHandledException('Missing input JSON for logActivity');
        }
    
        try {
            Map<String, Object> inputParams = (Map<String, Object>) JSON.deserializeUntyped(inputParamsJson);
            if(inputParams.containsKey('recordId')) {
                Id recordId = (Id) inputParams.get('recordId');
                String sObjName = recordId.getSObjectType().getDescribe().getName();
                system.debug('from utility log'+ sObjName);
                if(sObjName.toLowerCase() == 'account') {
                    inputParams.put('accountId', recordId);
                } else if (sObjName.toLowerCase() == 'task') {
                    inputParams.put('pageScreenName', 'Task Details Screen');
                    System.debug('from 2: ' + sObjName);
                    
                    Id relatedId = getRelatedAccountId(recordId);
                    System.debug('from 3: ' + relatedId);
                    
                    if (relatedId != null) {
                        String prefix = String.valueOf(relatedId).substring(0, 3);
                
                        if (prefix == '001') {
                            inputParams.put('accountId', relatedId);
                        } else if (prefix == 'a0N') {
                            inputParams.put('transactionId', relatedId);
                        } else if (prefix == 'a0C') {
                            inputParams.put('disputeId', relatedId);
                        } else {
                            System.debug('Unrecognized prefix: ' + prefix);
                        }
                    }
                } else if (sObjName.toLowerCase() == 'celsrm__celonis_event__c') {
                    Map<String, Id> relatedIds = UtilityController.getRelatedIdsFromEvent(recordId);
                
                    if (relatedIds.containsKey('accountId')) {
                        inputParams.put('accountId', relatedIds.get('accountId'));
                    }
                    if (relatedIds.containsKey('transactionId')) {
                        inputParams.put('transactionId', relatedIds.get('transactionId'));
                    }
                    if (relatedIds.containsKey('disputeId')) {
                        inputParams.put('disputeId', relatedIds.get('disputeId'));
                    }
                //-- Starts |FIN-7510| Changed by Asera | 08 JAN 2026 --//
                } else if (sObjName.toLowerCase() == 'celsrm__Credit_Review__c') {
                    inputParams.put('creditReviewId', recordId);
                }
                //-- End |FIN-7510| Changed by Asera | 08 JAN 2026 --//
            }
            
            celsrm__User_Activity__c activity = new celsrm__User_Activity__c(
                OwnerId = (Id)inputParams.get('userId'),
                celsrm__Screen_Name__c = (String)inputParams.get('pageScreenName'),
                celsrm__Action_Performed__c = (Boolean)inputParams.get('actionPerformed'),
                celsrm__Action_Taken_Time__c = (Datetime)inputParams.get('actionTakenTime'),
                celsrm__Account__c = (Id)inputParams.get('accountId'),
                celsrm__Transaction__c = (Id)inputParams.get('transactionId'),
                celsrm__Dispute__c = (Id)inputParams.get('disputeId'),
                //-- Starts |FIN-7510| Changed by Asera | 08 JAN 2026 --//
                celsrm__Credit_Review__c = (Id)inputParams.get('creditReviewId'), 
                //-- End |FIN-7510| Changed by Asera | 08 JAN 2026 --//
                celsrm__Additional_Metadata__c = (String)inputParams.get('additionalMetadata')
            );
            // activity.put()
            insert activity;
            return activity.Id;
        } catch (Exception e) {
            throw new AuraHandledException('Failed to log activity: ' + e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static Id getRelatedAccountId(Id taskId) {
        Task t = [
            SELECT Id, WhatId
            FROM Task
            WHERE Id = :taskId
            LIMIT 1
        ];

        // Check if WhatId is an Account (starts with '001')
        if (t.WhatId != null) {
            return t.WhatId;
        }

        return null; // No Account related
    }


    @AuraEnabled(cacheable=true)
    public static Map<String, Id> getRelatedIdsFromEvent(Id eventId) {
        Map<String, Id> relatedIds = new Map<String, Id>();
    
        try {
            celsrm__Celonis_Event__c evt = [
                SELECT Id,
                       celsrm__Account__c,
                       celsrm__Transaction__c,
                       celsrm__Dispute__c
                FROM celsrm__Celonis_Event__c
                WHERE Id = :eventId
                LIMIT 1
            ];
    
            System.debug('Fetched Event: ' + evt);
    
            if (evt.celsrm__Account__c != null) {
                relatedIds.put('accountId', evt.celsrm__Account__c);
            }
    
            if (evt.celsrm__Transaction__c != null) {
                relatedIds.put('transactionId', evt.celsrm__Transaction__c);
            }
    
            if (evt.celsrm__Dispute__c != null) {
                relatedIds.put('disputeId', evt.celsrm__Dispute__c);
            }
    
        } catch (Exception e) {
            System.debug('Error in getRelatedIdsFromEvent: ' + e.getMessage());
        }
    
        return relatedIds;
    }
    //-- Starts |FIN-7502| Changed by Asera | 25 Nov 2025 --//

    //-- Starts | FIN-9351 | Changed by Dhwanil | 03 Mar 2026 --//
    public static Map<String, String> extractImagesAsBase64(String html) {

        Map<String, String> imageMap = new Map<String, String>();
        if (String.isBlank(html)) return imageMap;
    
        // Use fully qualified System.Pattern to avoid static error
        System.Pattern pattern = System.Pattern.compile(
            '(?i)<img[^>]+src=[\'"]([^\'"]+)[\'"]'
        );
        System.Matcher matcher = pattern.matcher(html);
    
        while (matcher.find()) {
    
            String imageUrl = matcher.group(1);
            System.debug('Processing imageUrl: ' + imageUrl);
    
            if (String.isBlank(imageUrl)) continue;
    
            try {
    
                // -------------------------------------------------
                // ✅ 1️⃣ HANDLE CONTENTVERSION (068 ID)
                // -------------------------------------------------
                System.Pattern idPattern = System.Pattern.compile('(068[a-zA-Z0-9]{12,15})');
                System.Matcher idMatcher = idPattern.matcher(imageUrl);
    
                if (idMatcher.find()) {
    
                    String versionId = idMatcher.group(1);
                    System.debug('Detected ContentVersion Id: ' + versionId);
    
                    ContentVersion cv = [
                        SELECT VersionData, FileType
                        FROM ContentVersion
                        WHERE Id = :versionId
                        LIMIT 1
                    ];
    
                    String base64 = EncodingUtil.base64Encode(cv.VersionData);
    
                    String contentType = 'image/png';
                    if (cv.FileType == 'JPG' || cv.FileType == 'JPEG') {
                        contentType = 'image/jpeg';
                    }
    
                    String dataUrl = 'data:' + contentType + ';base64,' + base64;
    
                    imageMap.put(imageUrl, dataUrl);
                    continue; // skip callout
                }
    
                // -------------------------------------------------
                // ✅ 2️⃣ FALLBACK FOR EXTERNAL URL (HTTP CALLOUT)
                // -------------------------------------------------
                Http http = new Http();
                HttpRequest req = new HttpRequest();
                req.setEndpoint(imageUrl);
                req.setMethod('GET');
                req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId());
    
                HttpResponse res = http.send(req);
    
                if (res.getStatusCode() == 200) {
    
                    Blob imageBlob = res.getBodyAsBlob();
                    String base64 = EncodingUtil.base64Encode(imageBlob);
    
                    String contentType = res.getHeader('Content-Type');
                    if (String.isBlank(contentType)) {
                        contentType = 'image/png';
                    }
    
                    String dataUrl = 'data:' + contentType + ';base64,' + base64;
    
                    imageMap.put(imageUrl, dataUrl);
                }
    
            } catch (Exception e) {
                System.debug('Image conversion error: ' + e.getMessage());
            }
        }
    
        return imageMap;
    }
    //-- Ends | FIN-9351 | Changed by Dhwanil | 03 Mar 2026 --//
    //-- FIN-9729 | Changed by Dilshad | 27-Apr-2026 | Start --//
    public static TransactionQueryContext buildTransactionQueryContext(Map<Object, Object> inMap, Set<String> accountIds) {
        TransactionQueryContext queryContext = new TransactionQueryContext();
        if (accountIds != null) {
            queryContext.accountIds.addAll(accountIds);
        }

        String listViewId = inMap != null && inMap.get('ListView') != null ? String.valueOf(inMap.get('ListView')) : null;
        if (String.isBlank(listViewId)) {
            return queryContext;
        }

        List<celsrm__Custom_List_View__c> customListViewList = [
            SELECT Id, Name, celsrm__Object_Fields__c, celsrm__Filter_Criteria__c, celsrm__ListView_For_Object__c, celsrm__Sort_By_Field__c, celsrm__Sort_By_Order__c
            FROM celsrm__Custom_List_View__c
            WHERE Id = :listViewId
            LIMIT 1
        ];
        if (customListViewList.isEmpty()) {
            return queryContext;
        }

        celsrm__Custom_List_View__c customListViewObj = customListViewList[0];
        if (String.isNotBlank(customListViewObj.celsrm__Object_Fields__c)) {
            queryContext.selectedFields = UtilityController.getQueryFieldList(customListViewObj.celsrm__Object_Fields__c, 'celsrm__Transaction__c');
            queryContext.selectedFieldsType = JSON.serialize(
                UtilityController.getQueryFieldsTypeList(customListViewObj.celsrm__Object_Fields__c, 'celsrm__Transaction__c')
            );
        }

        if (String.isNotBlank(customListViewObj.celsrm__Filter_Criteria__c)) {
            queryContext.whereCondition = UtilityController.getQueryWhereClause(customListViewObj.celsrm__Filter_Criteria__c);
        }
        queryContext.whereCondition += String.isNotBlank(queryContext.whereCondition)
            ? ' AND celsrm__Account__c IN :accountIds'
            : ' WHERE celsrm__Balance__c != 0 AND celsrm__Account__c IN :accountIds';

        Set<String> transactionIds = extractTransactionIds(inMap);
        if (!transactionIds.isEmpty()) {
            queryContext.transactionIds.addAll(transactionIds);
            queryContext.whereCondition += ' AND Id IN :transactionIds';
        }

        String overrideOrderFields = resolveTransactionOrderFields(inMap);
        if (String.isNotBlank(overrideOrderFields)) {
            queryContext.orderFields = overrideOrderFields;
        } else if (String.isNotBlank(customListViewObj.celsrm__Sort_By_Field__c)) {
            queryContext.orderFields = UtilityController.getQuerySortOrder(customListViewObj.celsrm__Sort_By_Field__c, true);
        }

        return queryContext;
    }

    private static String resolveTransactionOrderFields(Map<Object, Object> inMap) {
        if (inMap == null || inMap.get('TransactionList_SortColumn') == null || inMap.get('TransactionList_SortOrder') == null) {
            return null;
        }

        String sortFieldName = String.valueOf(inMap.get('TransactionList_SortColumn'));
        String sortOrder = String.valueOf(inMap.get('TransactionList_SortOrder'));
        if (String.isBlank(sortFieldName) || String.isBlank(sortOrder)) {
            return null;
        }

        Map<String, Schema.SObjectField> transactionFieldMap = Schema.SObjectType.celsrm__Transaction__c.fields.getMap();
        if (!transactionFieldMap.containsKey(sortFieldName)) {
            return null;
        }

        Schema.DisplayType fieldDisplayType = transactionFieldMap.get(sortFieldName).getDescribe().getType();
        if (fieldDisplayType == Schema.DisplayType.TextArea) {
            return null;
        }

        String normalizedSortOrder = sortOrder.trim().toUpperCase();
        if (normalizedSortOrder != 'ASC' && normalizedSortOrder != 'DESC') {
            return null;
        }

        return 'ORDER BY ' + sortFieldName + ' ' + normalizedSortOrder;
    }

    public static String generateTrxnSummaryTableForEmailBody(List<celsrm__Transaction__c> transactions, List<String> selectedFields, Map<String, String> selectedFieldsType, List<String> selectedFieldsLabel) {
        Decimal TotalBalance = 0;
        Schema.Sobjecttype objType = celsrm__Transaction__c.getSObjectType();
        Schema.Describesobjectresult sobjRes = objType.getDescribe();
        Map<String, Schema.Sobjectfield> fieldMap = sobjRes.fields.getMap();
        String htmlBody = '';
        
        Map<String, String> fieldToType = new Map<String, String>();
        for (String fieldName: selectedFields) {
            if(fieldName != 'id' && fieldName != 'celsrm__Flag__c' && fieldName != 'celsrm__Latest_Note__c' && fieldName != 'celsrm__Latest_Note_Date__c'){
                fieldToType.put(fieldName, fieldMap.get(fieldName).getDescribe().getType().name());
            }
        }
        htmlBody = '<table class="txSummaryTable" border="1" cellspacing="0" cellpadding="2"><tr>';
        Integer labelIndex = 0;
        for (String fieldName : selectedFields) {
            if(fieldName != 'id' && fieldName != 'celsrm__Flag__c' && fieldName != 'celsrm__Latest_Note__c' && fieldName != 'celsrm__Latest_Note_Date__c'){
                String headerAlignment = '';
                String fieldDataType = fieldToType.get(fieldName);
                if (fieldDataType != null) {
                    String normalizedFieldType = fieldDataType.toLowerCase();
                    if (normalizedFieldType == 'currency' || normalizedFieldType == 'number' || normalizedFieldType == 'percent' ||
                        normalizedFieldType == 'double' || normalizedFieldType == 'integer') {
                        headerAlignment = ' class="rightAlign"';
                    }
                }
                String label = labelIndex < selectedFieldsLabel.size() ? selectedFieldsLabel[labelIndex] : fieldName;
                htmlBody = htmlBody + '<th' + headerAlignment + '><b>' + label + '</b></th>';
                labelIndex++;
            }
        }
        htmlBody += '</tr>';
        for (celsrm__Transaction__c trans: transactions) {
            htmlBody += '<tr>';
            for (String fName: selectedFields) {
                String fieldName = fName;
                Object fieldValue = '';
                if(fieldName != 'id' && fieldName != 'celsrm__Flag__c' && fieldName != 'celsrm__Latest_Note__c' && fieldName != 'celsrm__Latest_Note_Date__c') {
                    String rightAligned = '';
                    String fieldDataType = fieldToType.get(fieldName);
                    if (fieldDataType != null) {
                        String normalizedFieldType = fieldDataType.toLowerCase();
                        if (normalizedFieldType == 'currency' || normalizedFieldType == 'number' || normalizedFieldType == 'percent' ||
                            normalizedFieldType == 'double' || normalizedFieldType == 'integer') {
                            rightAligned = ' class="rightAlign"';
                        }
                    }
                    if(fieldToType.get(fieldName) == 'REFERENCE') {
                        fieldName = fieldName.subString(0,fieldName.length()-1)+ 'r';
                        if(trans.getSobject(fieldName) != null) {
                            fieldvalue = trans.getSobject(fieldName).get('name');
                        } else {
                            fieldvalue = '';
                        }
                    } else if (fieldToType.get(fieldName) == 'DATE'){
                        if(trans.get(fieldName) != null){
                            Date dtTemp = (Date)trans.get(fieldName);
                            
                            fieldvalue =dtTemp.format();
                        }else {
                            fieldvalue = '';
                        }
                    } else{
                        if(fieldName == 'celsrm__balance__c'){
                            fieldName = 'Balance';
                        }
                        fieldvalue = trans.get(fieldName);
                        if(fieldvalue == null){
                            fieldvalue = '';
                        }
                    }
                    htmlBody += '<td' + rightAligned + '>' + fieldValue + '</td>';      
                }
            }
            htmlBody += '</tr>';
            Decimal newAmt = trans.celsrm__Balance__c == null ? 0 : trans.celsrm__Balance__c;
            TotalBalance = TotalBalance + newAmt;
        }
        htmlBody += '</table>';

        return htmlBody; 
    }

    public static List<celsrm__Transaction__c> fetchTransactions(TransactionQueryContext queryContext) {
        return fetchTransactions(queryContext, null);
    }

    public static List<celsrm__Transaction__c> fetchTransactions(TransactionQueryContext queryContext, Integer maxRows) {
        if (queryContext == null) {
            return new List<celsrm__Transaction__c>();
        }
        if (String.isBlank(queryContext.whereCondition) && (queryContext.accountIds == null || queryContext.accountIds.isEmpty())) {
            return new List<celsrm__Transaction__c>();
        }

        Set<String> accountIds = queryContext.accountIds == null ? new Set<String>() : queryContext.accountIds;
        Set<String> transactionIds = queryContext.transactionIds == null ? new Set<String>() : queryContext.transactionIds;
        return fetchTransactionsInternal(
            queryContext.selectedFields,
            queryContext.whereCondition,
            queryContext.orderFields,
            accountIds,
            transactionIds,
            maxRows
        );
    }

    public static List<celsrm__Transaction__c> fetchTransactions(List<String> selectedFields, String whereCondition, String orderFields) {
        return fetchTransactionsInternal(selectedFields, whereCondition, orderFields, new Set<String>(), new Set<String>(), 5000);
    }

    private static List<celsrm__Transaction__c> fetchTransactionsInternal(
        List<String> selectedFields,
        String whereCondition,
        String orderFields,
        Set<String> accountIds,
        Set<String> transactionIds,
        Integer maxRows
    ) {
        //Fetch Transactions - START
        System.debug('==whereCondition===' + whereCondition);
        System.debug('==orderFields ===' + orderFields);
        //SELECT CurrencyISOCode, SUM(celsrm__Amount__c) FROM celsrm__Transaction__c WHERE celsrm__Close_Date__c = NULL and celsrm__Balance__c > 0 GROUP BY CurrencyISOCode

        List<String> safeSelectedFields = selectedFields == null ? new List<String>() : new List<String>(selectedFields);
        List<String> formatedFieldName = UtilityController.getTransactionFieldformat(safeSelectedFields, 'celsrm__Transaction__c');
        Boolean isHaveBalanceField = false;
        Boolean isHaveBaseBalanceField = false;
        Boolean isHaveCurrencyIsoCodeField = false;
        Boolean hasRecordId = false;
        for (String st : formatedFieldName) {
            if (st.equalsIgnoreCase('id')) {
                hasRecordId = true;
            } else if (st.equalsIgnoreCase('celsrm__balance__c')) {
                isHaveBalanceField = true;
            }
            if (st.equalsIgnoreCase('celsrm__base_balance__c')) {
                isHaveBaseBalanceField = true;
            }
            if (st.equalsIgnoreCase('currencyisocode')) {
                isHaveCurrencyIsoCodeField = true;
            }
        }

        String queryFields = string.join(formatedFieldName, ',');
        if (!hasRecordId) {
            queryFields = 'id,' + queryFields;
        }
        if (isHaveBalanceField == false) {
            queryFields = 'celsrm__balance__c,' + queryFields;
        }
        //....
        //add Base balance field id not exist in listview
        if (isHaveBaseBalanceField == false) {
            queryFields = 'celsrm__base_balance__c,' + queryFields;
        }
        //....

        if (isHaveCurrencyIsoCodeField == false && UserInfo.IsMultiCurrencyOrganization()) {
            queryFields = 'currencyisocode,' + queryFields;
        }
        if (queryFields.endsWith(',')) {
            queryFields = queryFields.substring(0, queryFields.length() - 1);
        }

        String querySuffix = '';
        if (String.isNotBlank(whereCondition)) {
            querySuffix += ' ' + whereCondition.trim();
        }
        if (String.isNotBlank(orderFields)) {
            querySuffix += ' ' + orderFields.trim();
        }

        Integer safeMaxRows = (maxRows == null || maxRows <= 0) ? 5000 : maxRows;
        String stringToQuery = 'SELECT ' + queryFields + ' FROM celsrm__Transaction__c' + querySuffix + ' LIMIT ' + safeMaxRows;
        System.debug('stringToQuery>>>>>>>>' + stringToQuery);

        List<celsrm__Transaction__c> transactions = Database.query(stringToQuery);
        System.debug('heap Size'+ Limits.getHeapSize());
        return transactions;
    }

    private static Set<String> extractTransactionIds(Map<Object, Object> inMap) {
        Set<String> transactionIds = new Set<String>();
        if (inMap == null || !inMap.containsKey('TransactionList') || inMap.get('TransactionList') == null) {
            return transactionIds;
        }

        Object rawTransactionList = inMap.get('TransactionList');
        if (!(rawTransactionList instanceof List<Object>)) {
            return transactionIds;
        }

        for (Object transactionObj : (List<Object>)rawTransactionList) {
            if (transactionObj == null) {
                continue;
            }
            if (transactionObj instanceof Map<Object, Object>) {
                Map<Object, Object> transactionMap = (Map<Object, Object>)transactionObj;
                if (transactionMap.containsKey('Id') && transactionMap.get('Id') != null) {
                    transactionIds.add(String.valueOf(transactionMap.get('Id')));
                }
            } else {
                transactionIds.add(String.valueOf(transactionObj));
            }
        }

        return transactionIds;
    }

    public static List<String> getQueryFieldList(String objectFields, String objectName) {
        List<String> objFieldList = new List<String>();
        List<Object> fieldList = (List<Object>)JSON.deserializeUntyped(objectFields);
        for (Object fieldObj : fieldList) {
            Map <String, Object> fieldMap = (Map <String, Object> ) fieldObj;
            String fieldName = (String)fieldMap.get('fieldName');
            if(fieldMap.get('isExport') != null && (Boolean)fieldMap.get('isExport') == true && (Boolean)fieldMap.get('hide') != true) {
                objFieldList.add(fieldName);
            } 
        }
        return objFieldList;
    }

    public static Map<String, String> getQueryFieldsTypeList(String objectFields, String objectName) {
        Map<String, String> objFieldList = new Map<String, String>();
        List<Object> fieldList = (List<Object>)JSON.deserializeUntyped(objectFields);
        for (Object fieldObj : fieldList) {
            Map <String, Object> fieldMap = (Map <String, Object> ) fieldObj;
            String fieldName = (String)fieldMap.get('fieldName');
            if(fieldMap.get('isExport') != null && (Boolean)fieldMap.get('isExport') == true && (Boolean)fieldMap.get('hide') != true) {
                objFieldList.put(fieldName, (String)fieldMap.get('type'));
            } 
        }
        return objFieldList;
    }
    //-- FIN-9602 | Changed by Dilshad | 27-Apr-2026 | End --//
    //-- FIN-9729 | Changed by Dilshad | 04-May-2026 | Start --//
    public static List<String> getTranslatedLabelValues(String languageCode, String objectAPIName, List<String> labelKeys) {
        if (String.isBlank(languageCode)) {
            return  UtilityController.getTransactionFieldLabel(labelKeys);
        }
        List<String> resolvedLabels = new List<String>();
        if (labelKeys == null) {
            return resolvedLabels;
        }

        Map<String, String> defaultLabelMap = getObjectFieldLabelMap(objectAPIName, labelKeys);
        Map<String, String> translatedLabelMap = getTranslatedLabelValueMap(
            languageCode,
            new Set<String>{ objectAPIName },
            new Set<String>(labelKeys)
        );
        String objectKey = String.isBlank(objectAPIName) ? '' : objectAPIName.trim().toLowerCase();

        for (String labelKey : labelKeys) {
            if (String.isBlank(labelKey)) {
                resolvedLabels.add(labelKey);
                continue;
            }

            String translatedValueKey = objectKey + '::' + labelKey.trim().toLowerCase();
            if (translatedLabelMap.containsKey(translatedValueKey)) {
                resolvedLabels.add(translatedLabelMap.get(translatedValueKey));
            } else if (defaultLabelMap.containsKey(labelKey.trim().toLowerCase())) {
                resolvedLabels.add(defaultLabelMap.get(labelKey.trim().toLowerCase()));
            } else {
                resolvedLabels.add(labelKey);
            }
        }
        return resolvedLabels;
    }

    public static String replaceAttachmentTemplateTranslatedPlaceholders(String contentTemplate, String languageCode) {
        if (String.isBlank(contentTemplate) || String.isBlank(languageCode)) {
            return contentTemplate;
        }

        Pattern placeholderPattern = Pattern.compile('\\{([A-Za-z]+)\\.([^}]*)\\}');
        Matcher placeholderMatcher = placeholderPattern.matcher(contentTemplate);
        Map<String, Set<String>> objectApiNameVsTokens = new Map<String, Set<String>>();
        while (placeholderMatcher.find()) {
            String objectAPIName = normalizeAttachmentTemplateObjectAPIName(placeholderMatcher.group(1));
            String tokenName = placeholderMatcher.group(2) == null ? null : placeholderMatcher.group(2).trim();
            if (String.isBlank(objectAPIName) || String.isBlank(tokenName)) {
                continue;
            }

            if (!objectApiNameVsTokens.containsKey(objectAPIName)) {
                objectApiNameVsTokens.put(objectAPIName, new Set<String>());
            }
            objectApiNameVsTokens.get(objectAPIName).add(tokenName);
        }

        if (objectApiNameVsTokens.isEmpty()) {
            return contentTemplate;
        }

        Set<String> objectAPINames = new Set<String>();
        Set<String> tokenNames = new Set<String>();
        for (String objectAPIName : objectApiNameVsTokens.keySet()) {
            objectAPINames.add(objectAPIName);
            tokenNames.addAll(objectApiNameVsTokens.get(objectAPIName));
        }

        Map<String, String> translatedLabelMap = getTranslatedLabelValueMap(languageCode, objectAPINames, tokenNames);
        if (translatedLabelMap.isEmpty()) {
            return contentTemplate;
        }

        Map<String, String> placeholderVsReplacement = new Map<String, String>();
        placeholderMatcher = placeholderPattern.matcher(contentTemplate);
        while (placeholderMatcher.find()) {
            String fullPlaceholder = placeholderMatcher.group(0);
            String objectAPIName = normalizeAttachmentTemplateObjectAPIName(placeholderMatcher.group(1));
            String tokenName = placeholderMatcher.group(2) == null ? null : placeholderMatcher.group(2).trim();
            if (String.isBlank(objectAPIName) || String.isBlank(tokenName)) {
                continue;
            }

            String translatedValueKey = objectAPIName.toLowerCase() + '::' + tokenName.toLowerCase();
            if (translatedLabelMap.containsKey(translatedValueKey)) {
                placeholderVsReplacement.put(fullPlaceholder, translatedLabelMap.get(translatedValueKey));
            }
        }

        for (String fullPlaceholder : placeholderVsReplacement.keySet()) {
            contentTemplate = contentTemplate.replace(fullPlaceholder, placeholderVsReplacement.get(fullPlaceholder));
        }
        return contentTemplate;
    }

    private static Map<String, String> getTranslatedLabelValueMap(
        String languageCode,
        Set<String> objectAPINames,
        Set<String> labelKeys
    ) {
        System.debug('languageCode:'+languageCode);
        System.debug('objectAPINames:'+objectAPINames);
        System.debug('labelKeys:'+labelKeys);
        Map<String, String> translatedLabelMap = new Map<String, String>();
        if (String.isBlank(languageCode) || objectAPINames == null || objectAPINames.isEmpty()) {
            return translatedLabelMap;
        }

        Set<String> normalizedObjectKeys = new Set<String>();
        for (String objectAPIName : objectAPINames) {
            if (String.isNotBlank(objectAPIName)) {
                normalizedObjectKeys.add(objectAPIName.trim().toLowerCase());
            }
        }
        if (normalizedObjectKeys.isEmpty()) {
            return translatedLabelMap;
        }

        Set<String> normalizedLabelKeys = new Set<String>();
        if (labelKeys != null) {
            for (String labelKey : labelKeys) {
                if (String.isNotBlank(labelKey)) {
                    normalizedLabelKeys.add(labelKey.trim().toLowerCase());
                }
            }
        }

        for (celsrm__Translated_Label__c translatedLabel : [
            SELECT Name, celsrm__Object_API_Name__c, celsrm__Label__c
            FROM celsrm__Translated_Label__c
            WHERE celsrm__Language__c = :languageCode
            AND celsrm__Object_API_Name__c IN :objectAPINames
        ]) {
            if (
                String.isBlank(translatedLabel.Name) ||
                String.isBlank(translatedLabel.celsrm__Object_API_Name__c) ||
                !normalizedObjectKeys.contains(translatedLabel.celsrm__Object_API_Name__c.trim().toLowerCase())
            ) {
                continue;
            }

            String labelKey = translatedLabel.Name.trim().toLowerCase();
            if (!normalizedLabelKeys.isEmpty() && !normalizedLabelKeys.contains(labelKey)) {
                continue;
            }

            translatedLabelMap.put(
                translatedLabel.celsrm__Object_API_Name__c.trim().toLowerCase() + '::' + labelKey,
                translatedLabel.celsrm__Label__c
            );
        }
        return translatedLabelMap;
    }

    private static Map<String, String> getObjectFieldLabelMap(String objectAPIName, List<String> fieldKeys) {
        Map<String, String> fieldKeyVsLabel = new Map<String, String>();
        if (String.isBlank(objectAPIName) || fieldKeys == null || fieldKeys.isEmpty()) {
            return fieldKeyVsLabel;
        }

        Map<String, Schema.SObjectType> describeInfo = Schema.getGlobalDescribe();
        if (!describeInfo.containsKey(objectAPIName.toLowerCase())) {
            return fieldKeyVsLabel;
        }

        Map<String, Schema.SObjectField> fieldMap = describeInfo.get(objectAPIName.toLowerCase()).getDescribe().fields.getMap();
        for (String fieldKey : fieldKeys) {
            if (String.isBlank(fieldKey) || !fieldMap.containsKey(fieldKey)) {
                continue;
            }

            Schema.SObjectField fieldRef = fieldMap.get(fieldKey);
            if (fieldRef != null) {
                fieldKeyVsLabel.put(fieldKey.trim().toLowerCase(), fieldRef.getDescribe().getLabel());
            }
        }
        return fieldKeyVsLabel;
    }

    private static String normalizeAttachmentTemplateObjectAPIName(String rawPrefix) {
        if (String.isBlank(rawPrefix)) {
            return null;
        }

        String normalizedPrefix = rawPrefix.trim().toLowerCase();
        if (normalizedPrefix == 'template') {
            return 'Template';
        }
        if (normalizedPrefix == 'customlabel') {
            return 'customLabel';
        }
        if (normalizedPrefix == 'translatedlabel') {
            return 'translatedLabel';
        }
        return null;
    }

    private static final String DEFAULT_STATEMENT_PAGE_SIZE = 'A4 landscape';
    public static String getStatementPageSize() {
        celsrm__SRM_Configuration__c systemConfig = celsrm__SRM_Configuration__c.getOrgDefaults();
        String statementMode = systemConfig == null ? null : systemConfig.celsrm__Statement_Mode__c;
        if (String.isBlank(statementMode)) {
            return DEFAULT_STATEMENT_PAGE_SIZE;
        }

        String normalizedMode = statementMode.trim().toLowerCase();
        if (normalizedMode == 'portrait') {
            return 'A4 portrait';
        }
        if (normalizedMode == 'landscape') {
            return 'A4 landscape';
        }
        return DEFAULT_STATEMENT_PAGE_SIZE;
    }

    public static Map<String, String> getTransactionTotalSummary(TransactionQueryContext queryContext, String groupByField) {
        String totalBalanceSummary = getTransactionTotalBalanceString(queryContext, groupByField);
        System.debug('--innerHtml--' + totalBalanceSummary);
        Map<String, String> returnMap = new Map<String, String>();
        returnMap.put('TotalBalance', totalBalanceSummary);
        return returnMap;
    }

    public static String getTransactionTotalBalanceString(TransactionQueryContext queryContext, String groupByField) {
        if (queryContext == null) {
            return '';
        }

        Set<String> accountIds = queryContext.accountIds == null ? new Set<String>() : queryContext.accountIds;
        Set<String> transactionIds = queryContext.transactionIds == null ? new Set<String>() : queryContext.transactionIds;
        String normalizedWhereClause = normalizeQueryWhereClause(queryContext.whereCondition);
        String safeGroupByField = sanitizeAggregateFieldName(groupByField);
        Boolean hasGrouping = String.isNotBlank(safeGroupByField);
        //-- Start | FIN-9911 | Changed by Dhwanil | 15-Jun-2026 | Replaced aggregate SOQL with Decimal row-level summing --//
        List<String> queryFields = new List<String>{ 'celsrm__Balance__c' };
        if (hasGrouping && !safeGroupByField.equalsIgnoreCase('celsrm__Balance__c')) {
            queryFields.add(safeGroupByField);
        }

        String stringToQuery =
            'SELECT ' + String.join(queryFields, ', ') +
            ' FROM celsrm__Transaction__c ' +
            normalizedWhereClause;
        System.debug('getTransactionTotalBalanceString query>>' + stringToQuery);

        List<String> totalBalanceParts = new List<String>();
        if (!hasGrouping) {
            Decimal totalAmount = 0.0;
            for (celsrm__Transaction__c transactionRecord : (List<celsrm__Transaction__c>)Database.query(stringToQuery)) {
                Decimal balanceAmount = transactionRecord.celsrm__Balance__c;
                totalAmount += balanceAmount == null ? 0.0 : balanceAmount;
            }
            if (totalAmount != 0) {
                totalBalanceParts.add(UtilityController.formatDoubleValue(UserInfo.getDefaultCurrency(), totalAmount));
            }
        } else {
            Map<String, Decimal> totalAmountByGroup = new Map<String, Decimal>();
            for (celsrm__Transaction__c transactionRecord : (List<celsrm__Transaction__c>)Database.query(stringToQuery)) {
                String groupValue = transactionRecord.get(safeGroupByField) == null ? null : String.valueOf(transactionRecord.get(safeGroupByField));
                if (String.isBlank(groupValue)) {
                    continue;
                }

                Decimal balanceAmount = transactionRecord.celsrm__Balance__c;
                Decimal existingTotal = totalAmountByGroup.containsKey(groupValue) ? totalAmountByGroup.get(groupValue) : 0.0;
                Decimal newTotal = existingTotal + (balanceAmount == null ? 0.0 : balanceAmount);
                totalAmountByGroup.put(groupValue, newTotal);
            }

            for (String groupValue : totalAmountByGroup.keySet()) {
                Decimal totalAmount = totalAmountByGroup.get(groupValue);
                if (safeGroupByField.equalsIgnoreCase('CurrencyIsoCode')) {
                    totalBalanceParts.add(UtilityController.formatDoubleValue(groupValue, totalAmount));
                } else {
                    totalBalanceParts.add(groupValue + ' : ' + UtilityController.formatAsCurrency(totalAmount));
                }
            }
        }
        //-- End | FIN-9911 | Changed by Dhwanil | 15-Jun-2026 | Replaced aggregate SOQL with Decimal row-level summing --//

        return totalBalanceParts.isEmpty() ? '' : String.join(totalBalanceParts, ', ');
    }

    // << START - MM - FIN-10130 | Feature JIRA FIN-8279 - Email Attachment -> Totals by currencycode >> 
    public static Map<String, String> getTransactionTotalBalanceMap(TransactionQueryContext queryContext, String groupByField) {
        if (queryContext == null) {
            return new Map<String, String>();
        }

        Set<String> accountIds = queryContext.accountIds == null ? new Set<String>() : queryContext.accountIds;
        Set<String> transactionIds = queryContext.transactionIds == null ? new Set<String>() : queryContext.transactionIds;
        String normalizedWhereClause = normalizeQueryWhereClause(queryContext.whereCondition);
        String safeGroupByField = sanitizeAggregateFieldName(groupByField);
        Boolean hasGrouping = String.isNotBlank(safeGroupByField);
        //-- Start | FIN-9911 | Changed by Dhwanil | 15-Jun-2026 | Replaced aggregate SOQL with Decimal row-level summing --//
        List<String> queryFields = new List<String>{ 'celsrm__Balance__c', 'celsrm__Close_Date__c', 'Noted__c', 'celsrm__DPD__c' };
        if (hasGrouping && !safeGroupByField.equalsIgnoreCase('celsrm__Balance__c')) {
            queryFields.add(safeGroupByField);
        }

        String stringToQuery =
            'SELECT ' + String.join(queryFields, ', ') +
            ' FROM celsrm__Transaction__c ' +
            normalizedWhereClause;
        System.debug('getTransactionTotalBalanceString query>>' + stringToQuery);

        List<String> totalBalanceParts = new List<String>();
        List<String> totalOpenBalanceParts = new List<String>();
        List<String> totalOverDueBalanceParts = new List<String>();
        List<String> totalOverDueNotNotedBalanceParts = new List<String>();
        if (!hasGrouping) {
            Decimal totalAmount = 0.0;
            Decimal totalOpenAmount = 0.0;
            Decimal totalOverDueAmount = 0.0;
            Decimal totalOverDueNotNotedAmount = 0.0;
            for (celsrm__Transaction__c transactionRecord : (List<celsrm__Transaction__c>)Database.query(stringToQuery)) {
                Decimal balanceAmount = transactionRecord.celsrm__Balance__c;
                totalAmount += balanceAmount == null ? 0.0 : balanceAmount;
                if(transactionRecord.celsrm__Close_Date__c == null) {
                    totalOpenAmount += balanceAmount == null ? 0.0 : balanceAmount;
                }
                if(transactionRecord.celsrm__DPD__c != null && transactionRecord.celsrm__DPD__c > 0) {
                    totalOverDueAmount += balanceAmount == null ? 0.0 : balanceAmount;
                    if(transactionRecord.Noted__c == null || transactionRecord.Noted__c == '') {
                        totalOverDueNotNotedAmount += balanceAmount == null ? 0.0 : balanceAmount;
                    }
                }
            }
                totalBalanceParts.add(UtilityController.formatDoubleValue(UserInfo.getDefaultCurrency(), totalAmount));
                totalOpenBalanceParts.add(UtilityController.formatDoubleValue(UserInfo.getDefaultCurrency(), totalOpenAmount));
                totalOverDueBalanceParts.add(UtilityController.formatDoubleValue(UserInfo.getDefaultCurrency(), totalOverDueAmount));
                totalOverDueNotNotedBalanceParts.add(UtilityController.formatDoubleValue(UserInfo.getDefaultCurrency(), totalOverDueNotNotedAmount));
        } else {
            Map<String, Decimal> totalAmountByGroup = new Map<String, Decimal>();
            Map<String, Decimal> totalOpenAmountByGroup = new Map<String, Decimal>();
            Map<String, Decimal> totalOverDueAmountByGroup = new Map<String, Decimal>();
            Map<String, Decimal> totalOverDueNotNotedAmountByGroup = new Map<String, Decimal>();
            for (celsrm__Transaction__c transactionRecord : (List<celsrm__Transaction__c>)Database.query(stringToQuery)) {
                String groupValue = transactionRecord.get(safeGroupByField) == null ? null : String.valueOf(transactionRecord.get(safeGroupByField));
                if (String.isBlank(groupValue)) {
                    continue;
                }

                Decimal balanceAmount = transactionRecord.celsrm__Balance__c;
                Decimal existingTotal = totalAmountByGroup.containsKey(groupValue) ? totalAmountByGroup.get(groupValue) : 0.0;
                Decimal newTotal = existingTotal + (balanceAmount == null ? 0.0 : balanceAmount);
                totalAmountByGroup.put(groupValue, newTotal);

                existingTotal = totalOpenAmountByGroup.containsKey(groupValue) ? totalOpenAmountByGroup.get(groupValue) : 0.0;
                if (transactionRecord.celsrm__Close_Date__c == null) {
                    newTotal = existingTotal + (balanceAmount == null ? 0.0 : balanceAmount);
                } else {
                    newTotal = existingTotal;
                }
                totalOpenAmountByGroup.put(groupValue, newTotal);
                
                existingTotal = totalOverDueAmountByGroup.containsKey(groupValue) ? totalOverDueAmountByGroup.get(groupValue) : 0.0;
                if (transactionRecord.celsrm__DPD__c != null && transactionRecord.celsrm__DPD__c > 0) {
                    newTotal = existingTotal + (balanceAmount == null ? 0.0 : balanceAmount);
                } else {
                    newTotal = existingTotal;
                }
                totalOverDueAmountByGroup.put(groupValue, newTotal);

                existingTotal = totalOverDueNotNotedAmountByGroup.containsKey(groupValue) ? totalOverDueNotNotedAmountByGroup.get(groupValue) : 0.0;
                if (transactionRecord.celsrm__DPD__c != null && transactionRecord.celsrm__DPD__c > 0 && (transactionRecord.Noted__c == null || transactionRecord.Noted__c == '')) {
                    newTotal = existingTotal + (balanceAmount == null ? 0.0 : balanceAmount);
                } else {
                    newTotal = existingTotal;
                }
                totalOverDueNotNotedAmountByGroup.put(groupValue, newTotal);
            }

            for (String groupValue : totalAmountByGroup.keySet()) {
                Decimal totalAmount = totalAmountByGroup.get(groupValue);
                if (safeGroupByField.equalsIgnoreCase('CurrencyIsoCode')) {
                    totalBalanceParts.add(UtilityController.formatDoubleValue(groupValue, totalAmount));
                } else {
                    totalBalanceParts.add(groupValue + ' : ' + UtilityController.formatAsCurrency(totalAmount));
                }
            }
            for (String groupValue : totalOpenAmountByGroup.keySet()) {
                Decimal totalAmount = totalOpenAmountByGroup.get(groupValue);
                if (safeGroupByField.equalsIgnoreCase('CurrencyIsoCode')) {
                    totalOpenBalanceParts.add(UtilityController.formatDoubleValue(groupValue, totalAmount));
                } else {
                    totalOpenBalanceParts.add(groupValue + ' : ' + UtilityController.formatAsCurrency(totalAmount));
                }
            }
            for (String groupValue : totalOverDueAmountByGroup.keySet()) {
                Decimal totalAmount = totalOverDueAmountByGroup.get(groupValue);
                if (safeGroupByField.equalsIgnoreCase('CurrencyIsoCode')) {
                    totalOverDueBalanceParts.add(UtilityController.formatDoubleValue(groupValue, totalAmount));
                } else {
                    totalOverDueBalanceParts.add(groupValue + ' : ' + UtilityController.formatAsCurrency(totalAmount));
                }
            }
            for (String groupValue : totalOverDueNotNotedAmountByGroup.keySet()) {
                Decimal totalAmount = totalOverDueNotNotedAmountByGroup.get(groupValue);
                if (safeGroupByField.equalsIgnoreCase('CurrencyIsoCode')) {
                    totalOverDueNotNotedBalanceParts.add(UtilityController.formatDoubleValue(groupValue, totalAmount));
                } else {
                    totalOverDueNotNotedBalanceParts.add(groupValue + ' : ' + UtilityController.formatAsCurrency(totalAmount));
                }
            }
        }
        //-- End | FIN-9911 | Changed by Dhwanil | 15-Jun-2026 | Replaced aggregate SOQL with Decimal row-level summing --//

        Map<String, String> returnMap = new Map<String, String>();
        returnMap.put('TotalBalance', totalBalanceParts.isEmpty() ? '' : String.join(totalBalanceParts, ', '));
        returnMap.put('TotalOpenItems', totalBalanceParts.isEmpty() ? '' : String.join(totalOpenBalanceParts, ', '));
        returnMap.put('TotalOverdueItems', totalBalanceParts.isEmpty() ? '' : String.join(totalOverDueBalanceParts, ', '));
        returnMap.put('TotalOverdueNotNotedItems', totalBalanceParts.isEmpty() ? '' : String.join(totalOverDueNotNotedBalanceParts, ', '));
        return returnMap;
    }
    // << END - MM - FIN-10130 | Feature JIRA FIN-8279 - Email Attachment -> Totals by currencycode >> 

    private static String normalizeQueryWhereClause(String whereClause) {
        String normalizedWhereClause = String.isBlank(whereClause)
            ? 'WHERE Close_Date__c = NULL AND Balance__c > 0'
            : whereClause.trim();
        if (!normalizedWhereClause.toLowerCase().startsWith('where ')) {
            normalizedWhereClause = 'WHERE ' + normalizedWhereClause;
        }
        return normalizedWhereClause;
    }

    private static String sanitizeAggregateFieldName(String fieldName) {
        if (String.isBlank(fieldName)) {
            return null;
        }
        if (!Pattern.matches('[A-Za-z0-9_\\.]+', fieldName)) {
            return 'CurrencyIsoCode';
        }
        return fieldName.trim();
    }

    public static String formatDoubleValue(String currencyCode, Decimal d) {
        return formatDoubleValue(currencyCode, d == null ? null : Double.valueOf(d));
    }

    public static String formatAsCurrency(Decimal amount) {
        return formatAsCurrency(amount == null ? null : Double.valueOf(amount));
    }

    public static String getPackageNamespace() {
        return getNamespaceFromObjectApiName('Transaction__c');
    }

    public static String getPackageNamespacePrefix() {
        String namespaceValue = getPackageNamespace();
        return String.isBlank(namespaceValue) ? '' : namespaceValue + '__';
    }

    private static String getNamespaceFromObjectApiName(String baseObjectApiName) {
        if (String.isBlank(baseObjectApiName)) {
            return '';
        }

        Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
        if (globalDescribe.containsKey(baseObjectApiName)) {
            return '';
        }

        String managedObjectApiName = 'celsrm__' + baseObjectApiName;
        if (globalDescribe.containsKey(managedObjectApiName)) {
            return 'celsrm';
        }

        for (String objectApiName : globalDescribe.keySet()) {
            if (
                objectApiName != null &&
                objectApiName.endsWith(baseObjectApiName) &&
                objectApiName.length() > baseObjectApiName.length()
            ) {
                Integer namespaceSeparatorIndex = objectApiName.indexOf('__');
                if (namespaceSeparatorIndex > 0) {
                    return objectApiName.substring(0, namespaceSeparatorIndex);
                }
            }
        }
        return '';
    }

    public static String getAccountLanguageCode(String accountId) {
        String accountLanguageCode = 'en';
        try {
            // << START - MM - FIN-10130 - Akzonobel Deployments | Akzonobel to use only celsrm__Locale__c>>
            // Account acc = [SELECT Id, celsrm__Locale__c, Language_Code__c FROM Account WHERE Id = :accountId];
            // accountLanguageCode = acc.Language_Code__c != null ? acc.Language_Code__c.trim().toLowerCase() : acc.celsrm__Locale__c != null ? acc.celsrm__Locale__c.trim().toLowerCase() : 'en';
            Account acc = [SELECT Id, celsrm__Locale__c FROM Account WHERE Id = :accountId];
            accountLanguageCode = acc.celsrm__Locale__c != null ? acc.celsrm__Locale__c.trim().toLowerCase() : 'en';
            // << END - MM - FIN-10130 - Akzonobel Deployments | Akzonobel to use only celsrm__Locale__c>>
        } catch (Exception e) {
            System.debug('Error fetching Account: ' + e.getMessage());
        }
        return accountLanguageCode;
    }

    public class TransactionQueryContext {
        public List<String> selectedFields { get; set; }
        public String selectedFieldsType { get; set; }
        public String whereCondition { get; set; }
        public String orderFields { get; set; }
        public Set<String> accountIds { get; set; }
        public Set<String> transactionIds { get; set; }

        public TransactionQueryContext() {
            selectedFields = new List<String>();
            selectedFieldsType = '';
            whereCondition = '';
            orderFields = '';
            accountIds = new Set<String>();
            transactionIds = new Set<String>();
        }
    }
    //-- FIN-9729 | Changed by Dilshad | 04-May-2026 | End --//
    //-- FIN-8540 | Changed by Ravi | 15-Jun-2026 | Start --//
    public static List<Date> parseDateListFromString(String dateString, String separator) {

        if (String.isBlank(separator)) {
            separator = '\\|';
        }

        List<Date> dateList = new List<Date>();
        if (String.isBlank(dateString)) {
            return dateList;
        }
        //  Short-circuit if string clearly isn't a date list
        if (!Pattern.matches('.*\\d{4}-\\d{2}-\\d{2}.*', dateString)) {
            System.debug('Non-date message received, skipping parse: ' + dateString);
            return dateList;
        }
        System.debug('separator>> ' + separator);
        List<String> dateParts = dateString.split(Pattern.quote(separator));

        System.debug('dateParts, dateString ' + dateParts  + ' ' + dateString);
        
        for (String part : dateParts) {
            String trimmed = part.trim();
            if (!String.isBlank(trimmed)) {
                try {
                    // Date.valueOf expects 'YYYY-MM-DD'
                    dateList.add(Date.valueOf(trimmed));
                } catch (Exception e) {
                   System.debug('Failed to parse date from string part: ' + trimmed + ' Error: ' + e.getMessage());
                }
            }
        }
        return dateList;
    }

    public static String getReminderEventsConfiguration() {
        celsrm__AI_Configuration__c cfg =
            celsrm__AI_Configuration__c.getOrgDefaults();

        String reminderEventTypes =
            String.isBlank(cfg.celsrm__Reminder_Event_Names__c)
            ? 'send statement'
            : cfg.celsrm__Reminder_Event_Names__c;

        List<String> reminderTypes = reminderEventTypes.toLowerCase().split(',');

        List<String> conditions = new List<String>();
        for (String t : reminderTypes) {
            t = t.trim();
            if (!String.isBlank(t)) {
                conditions.add(
                    'Name LIKE \'%' +
                    String.escapeSingleQuotes(t) + '%\''
                );
            }
        }

        return
            conditions.isEmpty()
            ? ''
            : ' AND (' + String.join(conditions, ' OR ') + ')';
    }
    //-- FIN-8540 | Changed by Ravi | 15-Jun-2026 | End --//
}