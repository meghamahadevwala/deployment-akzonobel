global with sharing class GOGTaskFetchList implements celsrm.GOGIScreenCustomLogic {
    global Map<Object, Object> invoke(String functionName, Map<Object, Object> inMap) {    
        if(inMap.containsKey('ggScreenName') && inMap.get('ggScreenName') != null && String.valueOf(inMap.get('ggScreenName')).equals('WCM_TaskGridScreen')) {
            //for dunning screen
            if ([Select Subject from Task where 
            TaskSubtype != 'Email' And Subject = 'First Dunning Reminder' AND Status != 'Completed' and Status  != 'Auto Dunning Error' and What.type=:'Account' LIMIT 1].size() > 0) {
                inMap.put('SubjectFilter', 'First Dunning Reminder');
            }
        } else {
            List <Task> tlst = [Select Id,What.type,WhatId,Total_Past_Due__c,Account_Number__c, 
                            Account_Name__c,ActivityDate, Type, Subject, Status, Priority , AccountId 
                            From Task where OwnerId=:UserInfo.getUserId() AND what.type=:'Account' AND status != 'Completed' 
                            ORDER BY Priority,id limit 10 ];
            List<Map<Object,Object>> newtList = new List<Map<Object,Object>>();
            for (Task t : tlst) {
                Map<Object,Object> newTaskMap = new Map<Object,Object>();
                String subjectkey = '<a href="' + '/'+ t.Id + '"' + ' target="_blank">' + t.Subject + '</a>';
                newTaskMap.put('SubjectLink', subjectkey);
                newTaskMap.put('Subject',t.Subject);
                newTaskMap.put('Id', t.Id);
                String accountkey = '<a href="' + '/'+ t.WhatId + '"' + ' target="_blank">' + t.Account_Name__c + '</a>';
                newTaskMap.put('AccountNamelink', accountkey);
                newTaskMap.put('Account_Name__c', t.Account_Name__c);
                newTaskMap.put('Total_Past_Due__c',t.Total_Past_Due__c);
                newTaskMap.put('Priority',t.Priority);
                newTaskMap.put('Account_Number__c',t.Account_Number__c);
                newTaskMap.put('Status',t.Status);
                newTaskMap.put('WhatId', t.WhatId);
                //newTaskMap.put('BrandName',t.Brand_Name__c);
                newtList.add(newTaskMap);
            }
            system.debug('===tlst ======'+tlst );
            inMap.put('TaskList', newtList);
            system.debug('========='+inMap);
        }
        return inMap;
    }
}