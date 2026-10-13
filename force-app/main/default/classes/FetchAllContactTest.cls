@IsTest
public with sharing class FetchAllContactTest {
   
    public static testMethod void FetchAllContactTest() {
        try{
            Account acc = DataGenerator.insertAccount();
            List<contact> con = DataGenerator.insertContact(acc,2);  
          
            Map<Object,Object> inMap = new Map<Object,Object>();
            inMap.put('Id',acc.Id);
           
           FetchAllContact ACA = new FetchAllContact();
            Map<Object,Object>resultMap = ACA.invoke('fetchDefaultContact',inMap);
            ACA.invoke('fetchDefaultContact', inMap);
            ACA.invoke('fetchAllContact', inMap);
           ACA.invoke('', inMap);
        
        }catch(Exception e){
            system.debug('Exception caused>>>>'+e.getLineNumber() + e.getMessage() );
        }
    }

    
    @isTest
    static void myUnitTester() {
        try{
            Account acc = DataGenerator.insertAccount();
          // Contact con1 = new Contact(AccountId=acc.Id,phone='123456789',MobilePhone='12345',LastName='test',celsrm__Default__c=true,Name='');
          Contact con = new Contact();
       
            con.LastName = 'test';
            con.AccountId = acc.Id;
            con.Email = 'test@test.com';         
            con.CC__c = True;
            con.Bcc__c = True;
            con.celsrm__Default__c = TRUE;
            con.phone='123456789';
            con.MobilePhone='12345';
            //con.Name='test name';
            insert con;
           // insert new List<Contact>(con);
            Map<Object,Object> inMap = new Map<Object,Object>();
            inMap.put('Id',acc.Id);
           
           FetchAllContact ACA = new FetchAllContact();
            Map<Object,Object>resultMap = ACA.invoke('fetchDefaultContact',inMap);
            ACA.invoke('fetchDefaultContact', inMap);
            ACA.invoke('fetchAllContact', inMap);
           ACA.invoke('', inMap);
        
        }catch(Exception e){
            system.debug('Exception caused>>>>'+e.getLineNumber() + e.getMessage() );
        }
    }

}