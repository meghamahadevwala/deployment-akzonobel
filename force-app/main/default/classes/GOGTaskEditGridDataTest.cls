@isTest
public with sharing class GOGTaskEditGridDataTest {
    public static testMethod void GOGTaskEditGridDataTest() {
        List<Task> tList = DataGenerator.insertTask(null, 2);
        celsrm__SRM_Configuration__c wcmConfig = DataGenerator.insertWCMconfig();
        Map<Object,Object> inMap = new Map<Object,Object>();
        List<Object> objList = new List<Object>();
        Map<Object,Object> tMap = new Map<Object,Object>();
        tMap.put('Id',tList.get(0).Id);
        objList.add(tMap);
        inMap.put('TaskList',objList);
        try{
            GOGTaskEditGridData editGridData = new GOGTaskEditGridData();
            editGridData.invoke('', inMap);
        }catch(Exception e){
            system.debug('Exception caused>>>>'+e.getLineNumber() + e.getMessage() );
        }
    }
}