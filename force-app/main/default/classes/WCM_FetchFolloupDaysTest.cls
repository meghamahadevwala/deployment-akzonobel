@isTest
public with sharing class WCM_FetchFolloupDaysTest {
    public static testMethod void WCM_FetchFolloupDaysTest() {

        Account acc = DataGenerator.insertAccount();
        List<Contact> cont = DataGenerator.insertContact(acc, 2);
        celsrm__Temp_Object_Holder__c temObjHolder = DataGenerator.insertTempObjHolder();

        Map<Object,Object> inMap = new Map<Object,Object>();
        List<Object> objList = new List<Object>();
        Map<Object,Object> tempMap = new Map<Object,Object>();
        tempMap.put('Id',temObjHolder.Id);
        objList.add(tempMap);
        inMap.put('TransactionList',objList);
        inMap.put('Id', acc.Id);
        
        try{
            WCM_FetchFolloupDays fetchFolloupDays = new WCM_FetchFolloupDays();
            fetchFolloupDays.invoke('', inMap);
        }catch(Exception e){
            system.debug('Exception caused>>>>'+e.getLineNumber() + e.getMessage() );
        }
    }
}