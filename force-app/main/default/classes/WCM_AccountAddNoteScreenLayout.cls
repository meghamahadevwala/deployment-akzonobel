public with sharing class WCM_AccountAddNoteScreenLayout {
    public class screenWrapper {
        @AuraEnabled 
        public Map<String, Object> screenConfig;
        @AuraEnabled 
        public string screenId;
    }

    public class AccountActionWrapper {
        @AuraEnabled 
        public Map<String, Object> screenConfig;
        @AuraEnabled 
        public string screenId;
        @AuraEnabled 
        public Account accountData;
    }
    
    @AuraEnabled(cacheable=true)
    public static AccountActionWrapper getAccountDataAndScreenConfig(String accountId, String screenName) {
        System.debug('screenName:'+screenName);
        System.debug('accountId:'+accountId);
        AccountActionWrapper accountActionWrapper = new AccountActionWrapper();
        try {
            if(screenName != null && screenName != '') {
                String configStr = '';
                List<celsrm__Screens__c> screenList = [SELECT Id, Name, celsrm__Screen_Name__c, celsrm__Is_Active__c, celsrm__Config_1__c, celsrm__Config_2__c, celsrm__Config_3__c, celsrm__Config_4__c, celsrm__Config_5__c FROM celsrm__Screens__c WHERE celsrm__Is_Active__c = TRUE AND Name =: screenName];
                if(screenList != null && screenList.size() > 0) {
                    celsrm__Screens__c screenObj = screenList.get(0);
                    if(screenObj.celsrm__Config_1__c != null) configStr += screenObj.celsrm__Config_1__c;
                    if(screenObj.celsrm__Config_2__c != null) configStr += screenObj.celsrm__Config_2__c;
                    if(screenObj.celsrm__Config_3__c != null) configStr += screenObj.celsrm__Config_3__c;
                    if(screenObj.celsrm__Config_4__c != null) configStr += screenObj.celsrm__Config_4__c;
                    if(screenObj.celsrm__Config_5__c != null) configStr += screenObj.celsrm__Config_5__c;
                    Map<String, Object> screenConfig = (Map<String, Object>) JSON.deserializeUntyped(configStr);
                    accountActionWrapper.screenConfig = screenConfig;
                    accountActionWrapper.screenId = screenObj.Id;
                } else {
                    throw new AuraHandledException(Label.GOG_No_Screen_Found);
                }
                Account accountObj = [SELECT Id, Name, AccountNumber FROM Account WHERE Id=:accountId];
                accountActionWrapper.accountData = accountObj;
            } else {
                throw new AuraHandledException(Label.GOG_Required_Parameters_Missing_For_Screen);
            }
            return accountActionWrapper;
        } catch (Exception ex) {
            throw new AuraHandledException('Exception in WCM_AccountAddNoteScreenLayout:'+ex.getStackTraceString());
        }
    }

    @AuraEnabled(cacheable=true)
    public static Account AccountDetails(Id accId){
        Account acc = [select Id, Name, AccountNumber from Account where Id=:accId];
        return acc;
    }

    @AuraEnabled(cacheable=true)
    public static screenWrapper getScreenConfig(String screenName, String pageMode, String sObjectName) {
        
        screenWrapper sw = new screenWrapper();
        try {
            system.debug('screenName:'+screenName+' pageMode:'+pageMode+' sObjectName:'+sObjectName);
            List<celsrm__Screens__c> screenList = new List<celsrm__Screens__c>();
            String query = 'SELECT Id, Name, celsrm__Screen_Name__c, celsrm__Is_Active__c, celsrm__Config_1__c, celsrm__Config_2__c, celsrm__Config_3__c, celsrm__Config_4__c, celsrm__Config_5__c FROM celsrm__Screens__c WHERE celsrm__Is_Active__c = TRUE ';
            if(String.isNotBlank(screenName)) {
                query += ' AND Name = :screenName';
                System.debug('query:'+query);
                screenList = database.query(query);
            } else if(pageMode != null && sObjectName != null){
                query += ' AND celsrm__Page_Mode__c = :pageMode AND celsrm__Object__c = :sObjectName';
                Set<String> profileName = new Set<String>();
                profileName.add(UserInfo.getProfileId());
                String querywithprofile = query;
                if(profileName != null){
                    querywithprofile += ' AND celsrm__Profile__c INCLUDES (\''+profileName+'\')';
                } 
                System.debug('querywithprofile:'+querywithprofile);
                screenList = database.query(querywithprofile);
                if(screenList.size() == 0){
                    System.debug('query:'+query);
                    screenList = database.query(query);
                }
            } else {
                throw new AuraHandledException(Label.GOG_Required_Parameters_Missing_For_Screen);
            }
            if(screenList != null && screenList.size() > 0){
                celsrm__Screens__c screenObj = screenList.get(0);
                String config = '';
                System.debug('screenObj.celsrm__Config_1__c:'+screenObj.celsrm__Config_1__c);
                if(screenObj.celsrm__Config_1__c != null) config += screenObj.celsrm__Config_1__c;
                if(screenObj.celsrm__Config_2__c != null) config += screenObj.celsrm__Config_2__c;
                if(screenObj.celsrm__Config_3__c != null) config += screenObj.celsrm__Config_3__c;
                if(screenObj.celsrm__Config_4__c != null) config += screenObj.celsrm__Config_4__c;
                if(screenObj.celsrm__Config_5__c != null) config += screenObj.celsrm__Config_5__c;
                
                system.debug('config:'+config);
                Map<String, Object> con = (Map<String, Object>) JSON.deserializeUntyped(config);
                sw.screenConfig = con;
                sw.screenId = screenObj.Id;
                system.debug('sw:'+sw); 
            } else {
                throw new AuraHandledException(Label.GOG_No_Screen_Found);
            }
        } catch(Exception ex){
            System.debug('Exception: ' + ex.getMessage());
            throw new AuraHandledException(ex.getMessage());
        } 
        return sw;
    }   
}