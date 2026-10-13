public with sharing class GetForecastData {
    // public Static string namespace = celsrm.TransactionSummaryUtilityController.getNameSpace();
    public Static string namespace = 'celsrm__';
    @AuraEnabled
    public static Map<String, String> getFieldNames(){
        Schema.DescribeSObjectResult objDescribe = Monthly_Forecast__c.sObjectType.getDescribe();
        Map<String, Schema.SObjectField> fields = objDescribe.fields.getMap();
        
        // List<String> fieldsToPass;
        Map<String, String> fieldLabel = new Map<String, String>();
        for (Schema.SObjectFIeld field: fields.values())
        {
            fieldLabel.put(field.getDescribe().getName(), field.getDescribe().getLabel());
            // fieldsToPass.add(field.getDescribe().getLabel());
        }       
        return fieldLabel;
    }

    @AuraEnabled
    public static Map<String, Monthly_Forecast__c> getForecastList(String regionName) {
        Map<String, Monthly_Forecast__c> mp = new Map<String, Monthly_Forecast__c>();
        // Boolean isMultiCurrencyEnable = Forecast_Configuration__c.getOrgDefaults().Is_Multi_Currency_Enable__c;
        // if(celsrm.GOGSecurityController.isAccessible('Monthly_Forecast__c,Id,Name,Month__c,Year__c,Total_AR__c,Current_AR__c,Forecast_Amount__c,Actual_Payment_Received__c')){
            // String addField = isMultiCurrencyEnable == true ? 'CurrencyIsoCode, ' : '';
            // String query = 'SELECT Id, Name, CurrencyIsoCode, ' + 'Total_Days__c,'+'Trade_AR__c,'+'Current_AR__c,'+'Sales__c,'+'Six_Month_Average_Sale__c,'+'Actual_Gross_DBO__c,'+'BP_DBO__c,'+'Target_Gross_DBO__c,'+'Six_Month_Average_DBO__c,'+'Actual_DBO_Based_On_Receipt__c,'+'Cumulative_Cash_Receipt__c,'+'Exhaust_DSO_Calculation__c,'+'Exhaust_BPDSO_Calculation__c,'+'Value_Of_Previous_Month_Billing__c,'+'Cash_Target_Gross__c,'+'Actual_Collection__c FROM '+'Monthly_Forecast__c';
            String query = 'SELECT Id, Name, CurrencyIsoCode, Month__c, Year__c, Total_AR__c, Total_Days__c, DSO__c, BPDSO__c, Current_AR__c, Forecast_Amount__c, Actual_Payment_Received__c FROM Monthly_Forecast__c';
            // System.debug('regionName>>>' + regionName);
            // if (String.isNotBlank(regionName) && regionName != 'All') {
            //     query += ' WHERE '+'Region__c =: regionName ';
            // } else {
            //     query += ' WHERE ('+'Region__c = \'\' OR '+'Region__c = null) ';
            // }
            query += ' ORDER BY Year__c DESC, Month__c DESC limit 12';
            System.debug('query>>>' + query);
            List<Monthly_Forecast__c> cfs = Database.query(query);    
            for(Monthly_Forecast__c cf:cfs){
                mp.put(cf.Name,cf);
            }
        // }
        return mp;
    }

    @AuraEnabled
    public static String getNameSpace(){
        // return celsrm.TransactionSummaryUtilityController.getNameSpace();
        return 'celsrm__';
    }
    
    @AuraEnabled
    public static Map<String, String> getCurrencyCode() {
        try {
            Map<String,String> returnObj = new Map<String, String>();
            // Boolean isMultiCurrencyEnable = Forecast_Configuration__c.getOrgDefaults().Is_Multi_Currency_Enable__c;
            // System.debug('isMultiCurrencyEnable>>>' + isMultiCurrencyEnable);
            returnObj.put('isMultiCurrencyEnable', 'true');
            // if (isMultiCurrencyEnable) {
                for (SObject ct : Database.query('SELECT Id, IsoCode FROM CurrencyType WHERE IsCorporate = true')) {
                    System.debug('currencySymbol>>>' + (String)ct.get('IsoCode'));
                    returnObj.put('currencySymbol', (String)ct.get('IsoCode'));
                }
            // } 
            // else {
            //     returnObj.put('currencySymbol', UserInfo.getDefaultCurrency());
            // }
            return returnObj;
        } catch(exception e) {
            system.debug('error occurered in graph controller>> on line>>'+e.getLineNumber()+'<< reason is >>'+e.getMessage()+'<<<Cause:>>' + e.getCause());
            return null;
        }
     }
}