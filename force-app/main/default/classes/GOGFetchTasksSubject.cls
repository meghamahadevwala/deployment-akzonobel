global with sharing class GOGFetchTasksSubject implements celsrm.GOGIScreenCustomLogic {
  global Map<Object, Object> invoke(String functionName, Map<Object, Object> inMap) {
      system.debug('=========='+inMap);
      //List<task> l_task_subject = new list<task>();
      List<Map<String, String>> subjectMaplist = new List<Map<String, String>>();
      set<String> s_Subject = new set<String>();
      for(Task t : [Select Subject from Task where 
                      TaskSubtype != 'Email' And (NOT Subject LIKE 'Auto%') 
                      AND ((SUbject LIKE '%Notice*' )  OR (celsrm__Treatment__c != '' AND celsrm__Treatment__r.celsrm__Task_Type__c != 'Call')) AND Status != 'Completed' and Status  != 'Auto Dunning Error' and What.type=:'Account'] ){
          s_Subject.add(String.valueOf(t.Subject));
      }
        Map<string,string> m_taskSubject =  new Map<string,string>();
        m_taskSubject.put('label','All');
      m_taskSubject.put('value','All');
      subjectMaplist.add(m_taskSubject);
        for(String tSub : s_Subject){
          m_taskSubject= new Map<string,string>();
          m_taskSubject.put('label',tSub);
          m_taskSubject.put('value',tSub);
          subjectMaplist.add(m_taskSubject);
      }
    
      inMap.put('dataServiceResponse',subjectMaplist);
     // inMap.put('SubjectFilter',subjectMaplist.get(0));
      
      return inMap;
  }    
}