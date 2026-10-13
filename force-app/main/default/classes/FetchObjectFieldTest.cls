@isTest
public with sharing class FetchObjectFieldTest {
    public static testMethod void FetchObjectFieldTest() {
        Map<Object,Object> inMap = new Map<Object,Object>();
        Map<Object,Object> mapValues = new Map<Object,Object>();
        Map<Object,Object> inMap1 = new Map<Object,Object>();
        mapValues.put('ListViewObject','Contact');
        FetchObjectField fetchObjField = new FetchObjectField();
        try{
            inMap.put('values',mapValues);
            fetchObjField.invoke('DualListBox', inMap);
        }catch(Exception e){
            system.debug('Exception caused>>>>'+e.getLineNumber() + e.getMessage() );
        }

        try{
            inMap1.put('ListViewObject','Contact');
            fetchObjField.invoke('', inMap1);
        }catch(Exception e){
            system.debug('Exception caused>>>>'+e.getLineNumber() + e.getMessage() );
        }
    }
}