@isTest
public with sharing class WCM_LoadContactDetailFromActivityTest {
    public static testMethod void WCM_LoadContactDetailFromActivityTest() {
        Account acc = DataGenerator.insertAccount();
        Map<Object,Object> accMap = new Map<Object,Object>();
        accMap.put('id',acc.Id);
        accMap.put('name',acc.Name);

        Map<Object, Object> inMap = new Map<Object,Object>();
        Map<Object, Object> aData = new Map<Object,Object>();
        Map<Object, Object> bData = new Map<Object,Object>();
        List<Object> cList = new List<Object>();
        Map<Object, Object> cData = new Map<Object,Object>();
        List<String> sList = new List<String>();
        cData.put('entity','email');
        cData.put('value','test@test.com');
        cList.add(cData);
        bData.put('entities',cList);
        bData.put('text','text');
        aData.put('Classification_Response__c',JSON.serialize(bData));
        inMap.put('activityData',aData);
        try{
           WCM_LoadContactDetailFromActivity loadContact = new WCM_LoadContactDetailFromActivity();
           loadContact.invoke('', inMap); 
        }catch(Exception e){
            system.debug('Exception caused>>>>'+e.getLineNumber() + e.getMessage() );
        }
    }
}