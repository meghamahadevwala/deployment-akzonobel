@isTest
public with sharing class WCM_addContactFromActivityTest {
    public static testMethod void WCM_addContactFromActivityTest() {
        try{
            Account acc = DataGenerator.insertAccount();
            Map<Object,Object> inMap = new Map<Object,Object>();
            inMap.put('Id',acc.Id);
            inMap.put('Email', 'test@test.com');
            inMap.put('phone', '135465');
            inMap.put('FirstName','test');
            inMap.put('LastName','test');
            inMap.put('fax','123456');
            WCM_addContactFromActivity ACA = new WCM_addContactFromActivity();
            ACA.invoke('', inMap);
        }catch(Exception e){
            system.debug('Exception caused>>>>'+e.getLineNumber() + e.getMessage() );
        }
    }
}