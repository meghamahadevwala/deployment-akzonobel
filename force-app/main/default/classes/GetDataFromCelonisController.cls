global with sharing class GetDataFromCelonisController implements celsrm.GOGIScreenCustomLogic{
    global Map<Object, Object> invoke(String functionName, Map<Object, Object> inMap) {
        system.debug('inmap val is'+inMap);
        Map<Object, Object> returnMap = new Map<Object, Object>();
        //--- GETTING BILLING DATA ---//
        if(functionName == 'BILLING_DATA') {
            returnMap = getBillingData(inMap);
        } else if(functionName == 'getSalesOrderData') {
            returnMap = getSalesOrderData(inMap);
        } else if(functionName == 'getDeliveryOrderData') {
            returnMap = getDeliveryOrderData(inMap);
        } else if(functionName == 'getSalesOrdersBillingData') {
            returnMap = getSalesOrdersBillingData(inMap);
        } else if(functionName == 'getSoftCreditExposures') {
            returnMap = getSoftCreditExposures(inMap);
        } else if(functionName == 'getCreditLimitChanges') {
            returnMap = getCreditLimitChanges(inMap);
        }
        return returnMap;
    }

    public Map<Object, Object> getBillingData(Map<Object, Object> inMap) {
        Integer page = Integer.valueOf(inMap.get('page'));
        Integer pageSize = Integer.valueOf(inMap.get('pageSize'));
        String recordId = String.valueOf(inMap.get('Id'));
        Map<Object, Object> returnMap = new Map<Object, Object>();
        List<celsrm__Transaction__c> transactionList = [SELECT celsrm__Reference__c, celsrm__Client__c, celsrm__Source_System__c FROM celsrm__Transaction__c WHERE Id =: recordId];
        if(transactionList != null && transactionList.size() > 0) {
            celsrm__Transaction__c tObj = transactionList.get(0);
            String targetRecordId = 'BILLING_ITEM'; // it will come from inMap later
            List<String> columnList = new List<String>{'BILLING_ITEM_ID', 'BILLING_DOC', 'BILLING_POS', 'BILLING_NET_VALUE', 'BILLING_INVOICED_QUANTITY', 'BILLING_TAX_AMOUNT', 'BILLING_SALES_DOCUMENT', 'BILLING_SALES_DOCUMENT_ITEM', 'BILLING_MATERIAL', 'BILLING_TEXT'};
            List<String> filterExpList = new List<String>();
            filterExpList.add('BILLING_DOC eq ' + tObj.celsrm__Reference__c);
            IAPIService intelligenceAPIService = new IAPIService();
            Map<String, Object> resultMap = intelligenceAPIService.invoke(targetRecordId, columnList, filterExpList, null, null, page, pageSize);
            // Celonis_Team_Details__c celTeamDetails = Celonis_Team_Details__c.getOrgDefaults();
            if(resultMap.get('content') != null) {
                List<Object> dataList = (List<Object>)((Map<String, Object>)resultMap.get('content')).get('data');
                Integer totalRecordCount = (Integer)resultMap.get('total');
                returnMap.put('dataServiceResponse', dataList);
                returnMap.put('totalRecordCount', totalRecordCount);
            } else if(resultMap.get('statusCode') == 403) {
                returnMap.put('ggErrorMessage', 'Error while fetching data from celonis. Error Code: 403 (forbidden).');
            }
        }
        return returnMap;
    }

    public Map<Object, Object> getSalesOrderData(Map<Object, Object> inMap) {
        Integer page = Integer.valueOf(inMap.get('page'));
        Integer pageSize = Integer.valueOf(inMap.get('pageSize'));
        String recordId = String.valueOf(inMap.get('Id'));
        Map<Object, Object> returnMap = new Map<Object, Object>();
        List<Account> accountList = [SELECT celsrm__Client__c, AccountNumber, celsrm__Company_Code__c, celsrm__Source_System__c, celsrm__Credit_Control_Area__c FROM Account WHERE Id =: recordId];
        if(accountList != null && accountList.size() > 0) {
            Account accountObj = accountList.get(0);
            String targetRecordId = 'O_CUSTOM_ORDER';
            // List<String> columnList = new List<String>{'ORDER_NUMBER', 'DOCUMENT_AMOUNT','REQUESTED_DELIVERY_DATE', 'BLOCK_STATUS', 'TYPE', 'DOCUMENT_CURRENCY_KEY'};
            List<String> columnList = new List<String>{'SOURCESYSTEMINSTANCE', 'CREDITCONTROLAREA','PERIODSTOANALYZECURRENTDATE', 'OPENSALESORDERVALUEINCREDITSEGMENTCURRENCY', 'CREDITSEGMENTCURRENCY'};
            // List<String> columnList = new List<String>{'CUSTOMER_CLIENT', 'CREDIT_CONTROL_AREA', 'OPEN_SALES_ORDER_VALUE', 'CURRENCY_KEY'};
            List<String> filterExpList = new List<String>();
            filterExpList.add('SOURCESYSTEMINSTANCE eq ' + accountObj.celsrm__Client__c);
            filterExpList.add('ACCOUNTNUMBER eq ' + accountObj.AccountNumber);
            filterExpList.add('SOURCESYSTEMTYPE eq ' + accountObj.celsrm__Source_System__c);
            filterExpList.add('CREDITCONTROLAREA eq ' + accountObj.celsrm__Credit_Control_Area__c);
            List<String> sortByList = new List<String>();
            sortByList.add('PERIODSTOANALYZECURRENTDATE');
            IAPIService intelligenceAPIService = new IAPIService();
            Map<String, Object> resultMap = intelligenceAPIService.invoke(targetRecordId, columnList, filterExpList, sortByList, null, page, pageSize);
            // Celonis_Team_Details__c celTeamDetails = Celonis_Team_Details__c.getOrgDefaults();
            if(resultMap.get('content') != null) {
                List<Object> dataList = (List<Object>)((Map<String, Object>)resultMap.get('content')).get('data');
                Integer totalRecordCount = (Integer)resultMap.get('total');
                List<Map<String, Object>> finalList = new List<Map<String, Object>>();
                for(Object data: dataList) {
                    if(data instanceOf Map<String, Object>) {
                        Map<String, Object> salesOrderMap = (Map<String, Object>) data;
                        Map<String, Object> finalSalesOrderMap = new Map<String, Object>();
                        finalSalesOrderMap.put('CurrencyIsoCode', salesOrderMap.get('CREDITSEGMENTCURRENCY') != null ? String.valueOf(salesOrderMap.get('CREDITSEGMENTCURRENCY')) : null);
                        finalSalesOrderMap.put('CUSTOMER_CLIENT', salesOrderMap.get('SOURCESYSTEMINSTANCE') != null ? String.valueOf(salesOrderMap.get('SOURCESYSTEMINSTANCE')) : null);
                        finalSalesOrderMap.put('CREDIT_CONTROL_AREA', salesOrderMap.get('CREDITCONTROLAREA') != null ? String.valueOf(salesOrderMap.get('CREDITCONTROLAREA')) : null);
                        finalSalesOrderMap.put('PERIOD_TO_ANALYZE_CURRENT_DATE', salesOrderMap.get('PERIODSTOANALYZECURRENTDATE') != null ? String.valueOf(salesOrderMap.get('PERIODSTOANALYZECURRENTDATE')): null);
                        finalSalesOrderMap.put('OPEN_SALES_ORDER_VALUE', salesOrderMap.get('OPENSALESORDERVALUEINCREDITSEGMENTCURRENCY') != null ? Decimal.valueOf(String.valueOf(salesOrderMap.get('OPENSALESORDERVALUEINCREDITSEGMENTCURRENCY'))).setScale(2) : null);
                        finalList.add(finalSalesOrderMap);
                    }
                }
                System.debug('finalList::'+ finalList);
                returnMap.put('dataServiceResponse', finalList);
                returnMap.put('totalRecordCount', totalRecordCount);
            }
        }
        return returnMap;
    }

    public Map<Object, Object> getDeliveryOrderData(Map<Object, Object> inMap) {
        Integer page = Integer.valueOf(inMap.get('page'));
        Integer pageSize = Integer.valueOf(inMap.get('pageSize'));
        String recordId = String.valueOf(inMap.get('Id'));
        Map<Object, Object> returnMap = new Map<Object, Object>();
        List<Account> accountList = [SELECT celsrm__Client__c, AccountNumber, celsrm__Company_Code__c, celsrm__Source_System__c, celsrm__Credit_Control_Area__c FROM Account WHERE Id =: recordId];
        if(accountList != null && accountList.size() > 0) {
            Account accountObj = accountList.get(0);
            String targetRecordId = 'O_CUSTOM_BILLINGCREDIT';
            List<String> columnList = new List<String>{'SOURCESYSTEMINSTANCE', 'CREDITCONTROLAREA','PERIODSTOANALYZECURRENTDATE', 'OPENDELIVERYCREDITINCREDITSEGMENTCURRENCY', 'CREDITSEGMENTCURRENCY'};
            List<String> filterExpList = new List<String>();
            filterExpList.add('SOURCESYSTEMINSTANCE eq ' + accountObj.celsrm__Client__c);
            filterExpList.add('ACCOUNTNUMBER eq ' + accountObj.AccountNumber);
            filterExpList.add('SOURCESYSTEMTYPE eq ' + accountObj.celsrm__Source_System__c);
            filterExpList.add('CREDITCONTROLAREA eq ' + accountObj.celsrm__Credit_Control_Area__c);
            filterExpList.add('OPENDELIVERYCREDITINCREDITSEGMENTCURRENCY gt 0');
            List<String> sortByList = new List<String>();
            sortByList.add('PERIODSTOANALYZECURRENTDATE');
            IAPIService intelligenceAPIService = new IAPIService();
            Map<String, Object> resultMap = intelligenceAPIService.invoke(targetRecordId, columnList, filterExpList, sortByList, null, page, pageSize);
            // Celonis_Team_Details__c celTeamDetails = Celonis_Team_Details__c.getOrgDefaults();
            if(resultMap.get('content') != null) {
                List<Object> dataList = (List<Object>)((Map<String, Object>)resultMap.get('content')).get('data');
                Integer totalRecordCount = (Integer)resultMap.get('total');
                List<Map<String, Object>> finalList = new List<Map<String, Object>>();
                for(Object data: dataList) {
                    if(data instanceOf Map<String, Object>) {
                        Map<String, Object> deliveryOrderMap = (Map<String, Object>) data;
                        Map<String, Object> finalDeliveryOrderMap = new Map<String, Object>();
                        finalDeliveryOrderMap.put('CurrencyIsoCode', deliveryOrderMap.get('CREDITSEGMENTCURRENCY') != null ? String.valueOf(deliveryOrderMap.get('CREDITSEGMENTCURRENCY')) : null);
                        finalDeliveryOrderMap.put('CUSTOMER_CLIENT', deliveryOrderMap.get('SOURCESYSTEMINSTANCE') != null ? String.valueOf(deliveryOrderMap.get('SOURCESYSTEMINSTANCE')) : null);
                        finalDeliveryOrderMap.put('CREDIT_CONTROL_AREA', deliveryOrderMap.get('CREDITCONTROLAREA') != null ? String.valueOf(deliveryOrderMap.get('CREDITCONTROLAREA')) : null);
                        finalDeliveryOrderMap.put('PERIOD_TO_ANALYZE_CURRENT_DATE', deliveryOrderMap.get('PERIODSTOANALYZECURRENTDATE') != null ? String.valueOf(deliveryOrderMap.get('PERIODSTOANALYZECURRENTDATE')): null);
                        finalDeliveryOrderMap.put('OPEN_DELIVERY_CREDIT', deliveryOrderMap.get('OPENDELIVERYCREDITINCREDITSEGMENTCURRENCY') != null ? Decimal.valueOf(String.valueOf(deliveryOrderMap.get('OPENDELIVERYCREDITINCREDITSEGMENTCURRENCY'))).setScale(2) : null);
                        
                        finalList.add(finalDeliveryOrderMap);
                    }
                }
                System.debug('finalList::'+ finalList);
                returnMap.put('dataServiceResponse', finalList);
                returnMap.put('totalRecordCount', totalRecordCount);
            }
        }
        return returnMap;
    }

    public Map<Object, Object> getSalesOrdersBillingData(Map<Object, Object> inMap) {
        Map<Object, Object> returnMap = new Map<Object, Object>();
        try{
            Integer page = Integer.valueOf(inMap.get('page'));
            Integer pageSize = Integer.valueOf(inMap.get('pageSize'));
            String recordId = String.valueOf(inMap.get('Id'));
            List<Account> accountList = [SELECT celsrm__Client__c, AccountNumber, celsrm__Company_Code__c, celsrm__Source_System__c, celsrm__Credit_Control_Area__c FROM Account WHERE Id =: recordId];
            if(accountList != null && accountList.size() > 0) {
                Account accountObj = accountList.get(0);
                String targetRecordId = 'O_CUSTOM_BILLINGCREDIT';
                List<String> columnList = new List<String>{'SOURCESYSTEMINSTANCE', 'CREDITCONTROLAREA','PERIODSTOANALYZECURRENTDATE', 'OPENBILLINGCREDITINCREDITSEGMENTCURRENCY', 'CREDITSEGMENTCURRENCY'};
                List<String> filterExpList = new List<String>();
                filterExpList.add('SOURCESYSTEMINSTANCE eq ' + accountObj.celsrm__Client__c);
                filterExpList.add('ACCOUNTNUMBER eq ' + accountObj.AccountNumber);
                filterExpList.add('SOURCESYSTEMTYPE eq ' + accountObj.celsrm__Source_System__c);
                filterExpList.add('CREDITCONTROLAREA eq ' + accountObj.celsrm__Credit_Control_Area__c);
                filterExpList.add('OPENBILLINGCREDITINCREDITSEGMENTCURRENCY gt 0');
                List<String> sortByList = new List<String>();
                sortByList.add('PERIODSTOANALYZECURRENTDATE');
                IAPIService intelligenceAPIService = new IAPIService();
                Map<String, Object> resultMap = intelligenceAPIService.invoke(targetRecordId, columnList, filterExpList, sortByList, null, page, pageSize);
                // Celonis_Team_Details__c celTeamDetails = Celonis_Team_Details__c.getOrgDefaults();
                if(resultMap.get('content') != null) {
                    List<Object> dataList = (List<Object>)((Map<String, Object>)resultMap.get('content')).get('data');
                    Integer totalRecordCount = (Integer)resultMap.get('total');
                    List<Map<String, Object>> finalList = new List<Map<String, Object>>();
                    for(Object data: dataList) {
                        if(data instanceOf Map<String, Object>) {
                            Map<String, Object> billingOrderMap = (Map<String, Object>) data;
                            Map<String, Object> finalBillingOrderMap = new Map<String, Object>();
                            finalBillingOrderMap.put('CurrencyIsoCode', billingOrderMap.get('CREDITSEGMENTCURRENCY') != null ? String.valueOf(billingOrderMap.get('CREDITSEGMENTCURRENCY')) : null);
                            finalBillingOrderMap.put('CUSTOMER_CLIENT', billingOrderMap.get('SOURCESYSTEMINSTANCE') != null ? String.valueOf(billingOrderMap.get('SOURCESYSTEMINSTANCE')) : null);
                            finalBillingOrderMap.put('CREDIT_CONTROL_AREA', billingOrderMap.get('CREDITCONTROLAREA') != null ? String.valueOf(billingOrderMap.get('CREDITCONTROLAREA')) : null);
                            finalBillingOrderMap.put('PERIOD_TO_ANALYZE_CURRENT_DATE', billingOrderMap.get('PERIODSTOANALYZECURRENTDATE') != null ? String.valueOf(billingOrderMap.get('PERIODSTOANALYZECURRENTDATE')): null);
                            finalBillingOrderMap.put('OPEN_BILLING_CREDIT', billingOrderMap.get('OPENBILLINGCREDITINCREDITSEGMENTCURRENCY') != null ? Decimal.valueOf(String.valueOf(billingOrderMap.get('OPENBILLINGCREDITINCREDITSEGMENTCURRENCY'))).setScale(2) : null);
                            // finalBillingOrderMap.put('OPEN_BILLING_CREDIT', 3928.95);
                            finalList.add(finalBillingOrderMap);
                        }
                    }
                    System.debug('finalList::'+ finalList);
                    returnMap.put('dataServiceResponse', finalList);
                    returnMap.put('totalRecordCount', totalRecordCount);
                }
            }
        } catch (Exception e) {
            System.debug('Erorr: '+ e.getMessage());
        }
        return returnMap;
    }

    public Map<Object, Object> getSoftCreditExposures(Map<Object, Object> inMap) {
        Integer page = Integer.valueOf(inMap.get('page'));
        // Integer pageSize = Integer.valueOf(inMap.get('pageSize'));
        Integer pageSize = 50;
        String recordId = String.valueOf(inMap.get('Id'));
        Map<Object, Object> returnMap = new Map<Object, Object>();
        List<Account> accountList = [SELECT celsrm__Client__c, AccountNumber, celsrm__Company_Code__c, celsrm__Source_System__c, celsrm__Credit_Control_Area__c, CurrencyIsoCode FROM Account WHERE Id =: recordId];
        if(accountList != null && accountList.size() > 0) {
            Account accountObj = accountList.get(0);
            String targetRecordId = 'O_CUSTOM_SHORTTERMINC';
            List<String> columnList = new List<String>{'SOURCESYSTEMINSTANCE', 'ACCOUNTNUMBER', 'CREDITCONTROLAREA', 'PERIODSTOANALYZECURRENTDATE', 'DUERECEIVABLESVALUELOCAL','SALESORDERVALUELOCAL', 'RUNNINGDELTALOCAL'};
            List<String> filterExpList = new List<String>();
            filterExpList.add('SOURCESYSTEMINSTANCE eq ' + accountObj.celsrm__Client__c);
            filterExpList.add('ACCOUNTNUMBER eq ' + accountObj.AccountNumber);
            filterExpList.add('CREDITCONTROLAREA eq ' + accountObj.celsrm__Credit_Control_Area__c);
            // filterExpList.add('COMPANY_CODE eq ' + accountObj.celsrm__Company_Code__c);
            filterExpList.add('SOURCESYSTEMTYPE eq ' + accountObj.celsrm__Source_System__c);

            List<String> sortByList = new List<String>();
            sortByList.add('PERIODSTOANALYZECURRENTDATE');
            IAPIService intelligenceAPIService = new IAPIService();
            Map<String, Object> resultMap = intelligenceAPIService.invoke(targetRecordId, columnList, filterExpList, sortByList, null, page, pageSize);
            // Celonis_Team_Details__c celTeamDetails = Celonis_Team_Details__c.getOrgDefaults();
            if(resultMap.get('content') != null) {
                List<Object> dataList = (List<Object>)((Map<String, Object>)resultMap.get('content')).get('data');
                Integer totalRecordCount = (Integer)resultMap.get('total');
                List<Map<String, Object>> finalList = new List<Map<String, Object>>();
                Integer maxIndex = -1;
                Decimal maxvalue = -999999999999.0;
                for(Object data: dataList) {
                    if(data instanceOf Map<String, Object>) {
                        Map<String, Object> softCreditExpMap = (Map<String, Object>) data;
                        Map<String, Object> finalSoftCreditExpMap = new Map<String, Object>();

                        finalSoftCreditExpMap.put('CurrencyIsoCode',accountObj.CurrencyIsoCode);
                        finalSoftCreditExpMap.put('PERIOD_TO_ANALYZE_CURRENT_DATE', softCreditExpMap.get('PERIODSTOANALYZECURRENTDATE') != null ? String.valueOf(softCreditExpMap.get('PERIODSTOANALYZECURRENTDATE')) : null);
                        finalSoftCreditExpMap.put('DUE_RECEIVABLES_VALUE_LOCAL', softCreditExpMap.get('DUERECEIVABLESVALUELOCAL') != null ? Decimal.valueOf(String.valueOf(softCreditExpMap.get('DUERECEIVABLESVALUELOCAL'))).setScale(2) : null);
                        finalSoftCreditExpMap.put('SALES_ORDER_VALUE_LOCAL', softCreditExpMap.get('SALESORDERVALUELOCAL') != null ? Decimal.valueOf(String.valueOf(softCreditExpMap.get('SALESORDERVALUELOCAL'))).setScale(2): null);
                        finalSoftCreditExpMap.put('RUNNING_DELTA', softCreditExpMap.get('RUNNINGDELTALOCAL') != null ? Decimal.valueOf(String.valueOf(softCreditExpMap.get('RUNNINGDELTALOCAL'))).setScale(2) : null);
                        if(maxvalue <= Decimal.valueOf(String.valueOf(softCreditExpMap.get('RUNNINGDELTALOCAL')))) {
                            maxvalue = Decimal.valueOf(String.valueOf(softCreditExpMap.get('RUNNINGDELTALOCAL')));
                            maxIndex = dataList.indexOf(data);
                            // maxIndex = maxIndex + 1;
                        }
                        finalList.add(finalSoftCreditExpMap);
                    }
                }
                if(maxIndex != -1) {
                    finalList[maxIndex].put('IS_MAX', true);
                }
                System.debug('finalList::'+ finalList);
                returnMap.put('dataServiceResponse', finalList);
                returnMap.put('totalRecordCount', totalRecordCount);
            }
        }
        return returnMap;
    }

    public Map<Object, Object> getCreditLimitChanges(Map<Object, Object> inMap) {
        Integer page = Integer.valueOf(inMap.get('page'));
        Integer pageSize = Integer.valueOf(inMap.get('pageSize'));
        String recordId = String.valueOf(inMap.get('Id'));
        Map<Object, Object> returnMap = new Map<Object, Object>();
        List<Account> accountList = [SELECT celsrm__Client__c, AccountNumber, celsrm__Company_Code__c, celsrm__Source_System__c, celsrm__Credit_Control_Area__c, CurrencyIsoCode FROM Account WHERE Id =: recordId];
        if(accountList != null && accountList.size() > 0) {
            Account accountObj = accountList.get(0);
            String targetRecordId = 'O_CUSTOM_CREDITLIMITCHANGEHISTORY';
            List<String> columnList = new List<String>{'SOURCESYSTEMTYPE', 'SOURCESYSTEMINSTANCE', 'ACCOUNTNUMBER', 'CREDITCONTROLAREA', 'CHANGETIME', 'OLDVALUE','NEWVALUE','USERNAME'};
            List<String> filterExpList = new List<String>();
            Date todayDate = Date.today();
            Date oneYearBefore = todayDate.addYears(-1);
            DateTime oneYearBeforeDateTime = DateTime.newInstance(oneYearBefore.year(), oneYearBefore.month(), oneYearBefore.day());
            String formattedDate = oneYearBeforeDateTime.format('yyyy-MM-dd');

            
            filterExpList.add('SOURCESYSTEMINSTANCE eq ' + accountObj.celsrm__Client__c);
            filterExpList.add('ACCOUNTNUMBER eq ' + accountObj.AccountNumber);
            filterExpList.add('CREDITCONTROLAREA eq ' + accountObj.celsrm__Credit_Control_Area__c);
            filterExpList.add('CHANGETIME gt ' + formattedDate);
            filterExpList.add('SOURCESYSTEMTYPE eq ' + accountObj.celsrm__Source_System__c);

            List<String> sortByList = new List<String>();
            sortByList.add('-CHANGETIME');
            IAPIService intelligenceAPIService = new IAPIService();
            Map<String, Object> resultMap = intelligenceAPIService.invoke(targetRecordId, columnList, filterExpList, null, null, page, pageSize);
            // Celonis_Team_Details__c celTeamDetails = Celonis_Team_Details__c.getOrgDefaults();
            if(resultMap.get('content') != null) {
                List<Object> dataList = (List<Object>)((Map<String, Object>)resultMap.get('content')).get('data');
                Integer totalRecordCount = (Integer)resultMap.get('total');
                List<Map<String, Object>> finalList = new List<Map<String, Object>>();
                for(Object data: dataList) {
                    if(data instanceOf Map<String, Object>) {
                        Map<String, Object> clchMap = (Map<String, Object>) data;

                        // Map<String, Object> billingOrderMap = (Map<String, Object>) data;
                        Map<String, Object> finalClchMap = new Map<String, Object>();
                        finalClchMap.put('CurrencyIsoCode',accountObj.CurrencyIsoCode);
                        finalClchMap.put('EVENTTIME', clchMap.get('CHANGETIME') != null ? String.valueOf(clchMap.get('CHANGETIME')) : null);
                        finalClchMap.put('OLD_VALUE', clchMap.get('OLDVALUE') != null ? Decimal.valueOf(String.valueOf(clchMap.get('OLDVALUE')).trim()).setScale(2) : null);
                        finalClchMap.put('NEW_VALUE', clchMap.get('NEWVALUE') != null ? Decimal.valueOf(String.valueOf(clchMap.get('NEWVALUE')).trim()).setScale(2) : null);
                        finalClchMap.put('USERNAME', clchMap.get('USERNAME') != null ? String.valueOf(clchMap.get('USERNAME')) : null);
                        
                        finalList.add(finalClchMap);
                    }
                }
                System.debug('finalList::'+ finalList);
                returnMap.put('dataServiceResponse', finalList);
                returnMap.put('totalRecordCount', totalRecordCount);
            }
        }
        return returnMap;
    }
}