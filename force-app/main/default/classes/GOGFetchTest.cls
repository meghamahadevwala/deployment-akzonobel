@isTest
public with sharing class GOGFetchTest { 

    static Map<Object, Object> inMap = new Map<Object, Object>();

    public static testMethod void Test(){

        Account acc = DataGenerator.insertAccount();

        inMap.put('Id', acc.Id);
        inMap.put('Locale', UserInfo.getName());

        GOGFetchEmailTemplateForReminder fetch = new GOGFetchEmailTemplateForReminder();
        fetch.invoke('', inMap);
        
        GOGFetchOrgWideAddresses getOWA = new GOGFetchOrgWideAddresses();
        getOWA.invoke('', inMap);

        // inMap.put('SubjectFilter', 'Email');
        // GOGFetchTaskListBasedOnSubject taskList = new GOGFetchTaskListBasedOnSubject();
        // taskList.invoke('GOGFetchTaskListBasedOnSubject', inMap);
        // taskList.invoke('GOGFetchTaskListBasedOnSubjectOnExecution', inMap);
    }

	public static testMethod void Test1(){
        User thisUser = [select Id from User where Id =: UserInfo.getUserId()];
        System.runAs(thisUser) {

            Account acc = DataGenerator.insertAccount();
            EmailTemplate template = DataGenerator.insertEmailTemplate();
            List<Task> task = DataGenerator.insertTask(acc, 2);
            List<Contact> cont = DataGenerator.insertContact(acc, 3);
            cont[1].celsrm__Default__c = false;
            cont[2].CC__c = false;
            update cont;

            List<Object> ObjList = new List<Object>();
            Map<Object,Object> objMap1 = new Map<Object,Object>();
            objMap1.put('Id',task[0].Id);
            objMap1.put('Id', task[1].Id);
            objList.add(objMap1);

            List<Task> t = DataGenerator.insertTask(acc, 1);
            celsrm__SRM_Configuration__c wcmConfig = DataGenerator.insertWCMconfig();
            inMap.put('SubjectFilter', 'First Dunning Reminder');
            inMap.put('selectedTask', ObjList);
            List<Object> treatTsk = new List<Object>();
            inMap.put('selectedTreatmentTask', treatTsk);
            System.debug('inmap?>>>'+inMap);

            GOGFetchTaskListBasedOnSubject taskList = new GOGFetchTaskListBasedOnSubject();
            taskList.invoke('GOGFetchTaskListBasedOnSubject', inMap);
            taskList.invoke('GOGFetchTaskListBasedOnSubjectOnExecution', inMap);

            GOGFetchTasksSubject taskSub = new GOGFetchTasksSubject();
            taskSub.invoke('', inMap);
        }
    }    

    // public static testMethod void Test1(){}
}