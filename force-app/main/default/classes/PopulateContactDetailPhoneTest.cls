@isTest
public with sharing class PopulateContactDetailPhoneTest {
    public static testMethod void PopulateContactDetailPhoneTest() {
        try{
            Account acc = DataGenerator.insertAccount();
            List<contact> con = DataGenerator.insertContact(acc,2);
            Map<Object,Object> inMap = new Map<Object,Object>();
            inMap.put('Id',acc.Id);
            inMap.put('ContactName',con.get(0).Id);
            PopulateContactDetailPhone ACA = new PopulateContactDetailPhone();
            ACA.invoke('', inMap);
        }catch(Exception e){
            system.debug('Exception caused>>>>'+e.getLineNumber() + e.getMessage() );
        }
    }
}