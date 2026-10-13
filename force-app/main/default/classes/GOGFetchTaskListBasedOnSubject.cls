global class GOGFetchTaskListBasedOnSubject implements celsrm.GOGIScreenCustomLogic {
    global Map<Object, Object> invoke(String functionName, Map<Object, Object> inMap) {
        system.debug('functionName>>>'+functionName);
        if(functionName == 'GOGFetchTaskListBasedOnSubject'){
            system.debug(String.valueOf(inMap.get('SubjectFilter'))+'<<<<<inMap>>>'+inMap.get('SubjectFilter'));
            system.debug('UserInfo.getUserId()>>'+UserInfo.getUserId());
            List <Task> tlst = new List<Task>();
            if(String.valueOf(inMap.get('SubjectFilter'))  != 'All' ){
                tlst= [Select t.Id,t.What.type,t.ownerId, t.ActivityDate,t.Account_Name__c, t.celsrm__Notes__c,Total_Past_Due__c,Total_AR__c, 
                                t.WhatId, t.Type, t.SystemModstamp, t.Subject, t.Status, t.Priority , t.Description, 
                                t.CallType, t.CallObject, t.AccountId,t.celsrm__Treatment__c,
                                t.Owner.Email From Task t where t.Subject =:String.valueOf(inMap.get('SubjectFilter')) and
                                t.Status != 'Completed' and t.Status  != 'Auto Dunning Error' and t.what.type=:'Account' and ownerId =:UserInfo.getUserId() and t.celsrm__Treatment__r.celsrm__Task_Type__c != 'Call'] ;
            System.debug('tlst>>>'+tlst);
        }else{

            tlst= [Select t.Id,t.What.type,t.ownerId, t.ActivityDate,t.Account_Name__c, t.celsrm__Notes__c,Total_Past_Due__c,Total_AR__c, 
                                t.WhatId, t.Type, t.SystemModstamp, t.Subject, t.Status, t.Priority , t.Description, 
                                t.CallType, t.CallObject, t.AccountId, t.celsrm__Treatment__c,
                                t.Owner.Email From Task t where ((t.SUbject LIKE '%Notice*' ) OR (celsrm__Treatment__c != '' AND celsrm__Treatment__r.celsrm__Task_Type__c != 'Call')) and
                                t.Status != 'Completed' and t.Status  != 'Auto Dunning Error' and t.what.type=:'Account' and ownerId =:UserInfo.getUserId()] ;
        }
            List < Id > AccIDs = new List< Id >();
            
            for(Task ts: tlst ){            
                system.debug('ts'+ts);
                AccIDs.add(ts.WhatID);                    
            }
            // celsrm__SRM_Configuration__c systemConfig = celsrm__SRM_Configuration__c.getOrgDefaults();
            
            // List<OrgWideEmailAddress> listName = [SELECT Id, Address, DisplayName FROM OrgWideEmailAddress where address=:systemConfig.Mailbox_Email_Address__c ];
           
            if(!AccIDs.isEmpty()){
                Map< String, Map<String, List<String>> > returnMap = UtilityController.fetchEmails(AccIDs);
                for(Task t : tlst) {
                    if(returnMap != null && returnMap.get(t.whatId).get('to') != null)
                        t.celsrm__To__c = string.join(returnMap.get(t.whatId).get('to'),';');
                    if(returnMap != null && returnMap.get(t.whatId).get('bcc') != null)
                        t.celsrm__Bcc__c =  string.join(returnMap.get(t.whatId).get('bcc'),';');
                    if(returnMap != null && returnMap.get(t.whatId).get('cc') != null)
                        t.celsrm__Cc__c = string.join(returnMap.get(t.whatId).get('cc'),';');
                    if(returnMap != null && returnMap.get(t.whatId).get('from') != null)
                        t.celsrm__From__c = Id.ValueOf(string.join(returnMap.get(t.whatId).get('from'),','));   
                   //t.AccountName ='<a href="' + '/'+ t['AccountId'] + '"' + ' target="_blank">' + t['Account_Name__c'] + '</a>';
                   // t.celsrm__From__c = Id.ValueOf(string.join(returnMap.get(t.whatId).get('from'),','));
                }
            }
            inMap.put('editableTaskList', tlst);
            inMap.put('isVisibleDataGrid','false');
           
             inMap.put('CountNumberOfTask','<b>Task# : '+String.ValueOf(tlst.Size()) + '</b>'); 
            //return inMap;
        }
        else if(functionName == 'GOGFetchTaskListBasedOnSubjectOnExecution'){
            set<Id> s_taskID = new set<Id>();
            String str = JSON.serialize(inMap.get('selectedTask')); 
            List<object> tsk = (List<object>)System.JSON.deserializeUntyped(str);
            String treatmentTask = JSON.serialize(inMap.get('selectedTreatmentTask')); 
            List<object> tskTre = (List<object>)System.JSON.deserializeUntyped(treatmentTask);
            system.debug(tsk );
            
            for(Object ts : tsk){
                Map<String, Object> m = (Map<String, Object>)ts;
                Id key = (String)m.get('Id');
                s_taskID.add(key);
            }
            for(Object ts : tskTre){
                Map<String, Object> m = (Map<String, Object>)ts;
                Id key = (String)m.get('Id');
                s_taskID.add(key);
            }
            List <Task> tlst = [Select t.Id,t.What.type,t.ownerId, t.ActivityDate,t.Account.Name, t.Account_Name__c,t.celsrm__Notes__c, 
                                t.WhatId, t.Type, t.SystemModstamp, t.Subject, t.Status, t.Priority , t.Description, 
                                t.CallType, t.CallObject, t.AccountId,t.celsrm__Treatment__c,
                                t.Owner.Email From Task t where t.Id IN: s_taskID and ownerId =:UserInfo.getUserId() ] ;
            inMap.put('TaskList',tlst);
            inMap.put('CountNumberOfTask',tlst.Size());            
        }
        return inMap;
    }
}