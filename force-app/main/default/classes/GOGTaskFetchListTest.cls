@isTest
public with sharing class GOGTaskFetchListTest {
    public static testMethod void GOGTaskFetchListTest() {
        List<Task> tList = DataGenerator.insertTask(null, 2);
        Map<Object,Object> inMap = new Map<Object,Object>();
        Map<Object,Object> inMap1 = new Map<Object,Object>();
        inMap.put('ggScreenName','WCM_TaskGridScreen');
        inMap1.put('ggScreenName',null);
        inMap1.put('TaskList', tList);
        try{
           GOGTaskFetchList taskFetch = new GOGTaskFetchList();
           taskFetch.invoke('', inMap);
           taskFetch.invoke('', inMap1); 
        }catch(Exception e){
            system.debug('Exception caused>>>>'+e.getLineNumber() + e.getMessage() );
        }
    }
}