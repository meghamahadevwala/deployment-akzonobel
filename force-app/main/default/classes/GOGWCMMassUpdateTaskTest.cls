@isTest
public with sharing class GOGWCMMassUpdateTaskTest {
    public static testMethod void GOGWCMMassUpdateTaskTest() {
        List<Task> tList = DataGenerator.insertTask(null, 1);
        Map<Object,Object> inMap = new Map<Object,Object>();
        List<Object> objList = new List<Object>();
        Map<Object,Object> idMap = new Map<Object,Object>();
        idMap.put('Id',tList.get(0).Id);
        objList.add(idMap);
        inMap.put('TaskList',objList);
        inMap.put('Status','Not Started');
        inMap.put('AssignedTo',UserInfo.getUserId());
        inMap.put('DueDate',Date.parse('12/15/19'));
        inMap.put('DunningStatus','Done');
        try{
           GOGWCMMassUpdateTask updateTask = new GOGWCMMassUpdateTask();
           updateTask.invoke('', inMap); 
        }catch(Exception e){
            system.debug('Exception caused>>>>'+e.getLineNumber() + e.getMessage() );
        }
    }
}