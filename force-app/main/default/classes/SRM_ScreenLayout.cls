public with sharing class SRM_ScreenLayout extends VisualEditor.DynamicPickList {
    
    public override VisualEditor.DataRow getDefaultValue(){
        VisualEditor.DataRow defaultValue = new VisualEditor.DataRow('Select', 'none');
        return defaultValue;
    }
    public override VisualEditor.DynamicPickListRows getValues() {
        VisualEditor.DynamicPickListRows  myValues = new VisualEditor.DynamicPickListRows();
        VisualEditor.DataRow tmp = new VisualEditor.DataRow('Select', '');
        myValues.addRow(tmp);
        for (celsrm__Screens__c scrObj : [SELECT Id, Name FROM celsrm__Screens__c WHERE celsrm__Is_Active__c = TRUE]) {
           VisualEditor.DataRow opt = new VisualEditor.DataRow(scrObj.Name, scrObj.Name);
           myValues.addRow(opt);
        }
        return myValues;
    }
    public class screenWrapper {
        @AuraEnabled 
        public Map<String, Object> screenConfig;
        @AuraEnabled 
        public string screenId;
    }
    
     @AuraEnabled(cacheable=true)
     public static Account AccountDetails(Id accId){
        Account acc = [select Id,Name,celsrm__Locale__c from Account where Id=:accId];
        return acc;
    
    }
  
    
   @AuraEnabled(cacheable=true)
   public static TransactionDataWrapper TransactionDetails(Id TransId){
    TransactionDataWrapper returnData = new TransactionDataWrapper();
    // List<celsrm__Transaction__c> txList=[Select Name,celsrm__Account__c,celsrm__Amount__c,celsrm__Balance__c,celsrm__Create_Date__c,celsrm__Due_Date__c,celsrm__Shipment_Method__c,celsrm__Latest_Note_Date__c,celsrm__Latest_Note__c from celsrm__Transaction__c where id=:TransId]; 
    List<celsrm__Transaction__c> txList=[Select Name,celsrm__Account__c,celsrm__Amount__c,celsrm__Balance__c,celsrm__Create_Date__c,celsrm__Due_Date__c,celsrm__Latest_Note_Date__c,celsrm__Latest_Note__c from celsrm__Transaction__c where id=:TransId]; 
      Account accRec = [select Id,Name,celsrm__Locale__c from Account where Id=:txList.get(0).celsrm__Account__c];
      returnData.acc =accRec;
      returnData.transList = (List<sObject> )txList;
      return returnData;
  
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
               // throw new AuraHandledException(Label.celsrm__GOG_Required_Parameters_Missing_For_Screen);
                throw new AuraHandledException('Required_Parameters_Missing_For_Screen');
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
                throw new AuraHandledException('No_Screen_Found');
            }
        } catch(Exception ex){
            System.debug('Exception: ' + ex.getMessage());
            throw new AuraHandledException(ex.getMessage());
        } 
        return sw;
    }
    public class TransactionDataWrapper{
        @AuraEnabled
        public Account acc;
        @AuraEnabled
        public List<sObject> transList;
       
        public TransactionDataWrapper(){
            transList = new List<sObject>();
            acc=new Account();
        }
    }
}