@isTest
public with sharing class DunningFetchAllDefaultContactTest {
    public static testMethod void FetchAllContactTest() {
        try{
            Account acc = DataGenerator.insertAccount();
            List<contact> con = DataGenerator.insertContact(acc,2);
            Map<Object,Object> inMap = new Map<Object,Object>();
            inMap.put('Id',acc.Id);
            Map<Object,Object> criMap = new Map<Object,Object>();
            criMap.put('AccountId',acc.id);
           
            inMap.put('rowValues',criMap );
            DunningFetchAllDefaultContact ACA = new DunningFetchAllDefaultContact();
            ACA.invoke('', inMap);
        }catch(Exception e){
            system.debug('Exception caused>>>>'+e.getLineNumber() + e.getMessage() );
        }
    }
}