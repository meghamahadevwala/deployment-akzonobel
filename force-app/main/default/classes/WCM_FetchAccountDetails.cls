public with sharing class WCM_FetchAccountDetails {
    
    @AuraEnabled
    public static Account fetchStickyNotes(Id recordId){
        Account acc = [Select celsrm__Sticky_Note__c, celsrm__Sticky_Note_Color__c, celsrm__Latest_Note__c from Account where Id =: recordId limit 1];
        return  acc;
    }

    @AuraEnabled
    public static void saveStickyNotes(string notes,Id recordId){
        Account acc = new Account();
        acc.Id = recordId;
        acc.celsrm__Sticky_Note__c = notes;        
        update  acc;
        //return acc.Sticky_Note__c;
    }

    @AuraEnabled
    public static void saveStickyNotesColor(string noteColor,Id recordId){
        Account acc = new Account();
        acc.Id = recordId;
        acc.celsrm__Sticky_Note_Color__c = noteColor;        
        update  acc;
    }
	
	@AuraEnabled
    public static String fetchCurrencyISOCode(Id recordId){
        String currencyISOCode = '';
        
            if(UserInfo.IsMultiCurrencyOrganization()) {
				String query = 'select id,name,CurrencyIsoCode from account where id = :recordId';
                List<Account> listAcc = Database.query(query);
                if(listAcc != null && !listAcc.isEmpty()){
                    Account selectedAcc = listAcc.get(0);
                    if(selectedAcc.get('CurrencyIsoCode') != null){
                        currencyISOCode = String.valueOf(selectedAcc.get('CurrencyIsoCode'));
                    }
                }
            }
        System.debug('currencyISOCode : ' +  currencyISOCode);
		return currencyISOCode;
    }
    @AuraEnabled
    public static Map<String, Object> getChartDetails(Id recordId){
        try {
            // Account acc = [SELECT Id, Name, celsrm__Total_AR__c, celsrm__Credit_Limit__c, System_Suggested_Credit_Limit__c, Open_Billing_Value__c, Open_Delivery_Value__c, Open_Sales_Order__c FROM Account WHERE Id =: recordId];
            Account acc = [SELECT Id, Name, Order_Value_Next_30_Days__c, celsrm__Credit_Limit__c, Credit_Exposure__c, Open_Billing_Value__c, Open_Delivery_Value__c, Open_Invoice_Value__c, Open_Special_Credit_Value__c FROM Account WHERE Id =: recordId];
            Map<String, Object> returnMap = new Map<String, Object>();
            returnMap.put('totalAR', acc.Order_Value_Next_30_Days__c != null ? acc.Order_Value_Next_30_Days__c.setScale(2) : 0);
            returnMap.put('creditLimit', acc.celsrm__Credit_Limit__c != null ? acc.celsrm__Credit_Limit__c.setScale(2) : 0);
            returnMap.put('shortTermExposure', acc.Credit_Exposure__c != null ? acc.Credit_Exposure__c.setScale(2) : 0);
            returnMap.put('billingValue', acc.Open_Billing_Value__c != null ? acc.Open_Billing_Value__c.setScale(2) : 0);
            returnMap.put('deliveryValue', acc.Open_Delivery_Value__c != null ? acc.Open_Delivery_Value__c.setScale(2) : 0);
            returnMap.put('orderReceivableDelta', acc.Open_Invoice_Value__c != null ? acc.Open_Invoice_Value__c.setScale(2) : 0);
            returnMap.put('specialCreditValue', acc.Open_Special_Credit_Value__c != null ? acc.Open_Special_Credit_Value__c.setScale(2) : 0);

            
            return returnMap;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}