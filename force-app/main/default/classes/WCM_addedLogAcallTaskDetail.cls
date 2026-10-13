global with sharing class WCM_addedLogAcallTaskDetail implements celsrm.GOGIScreenCustomLogic {
    global Map<Object, Object> invoke(String functionName, Map<Object, Object> inMap) {
        inMap.put('VendorName','adding new value');
        
        Map<String,Object> assignedToMap = new Map<String,Object>();
        assignedToMap.put('id', UserInfo.getUserId());
        assignedToMap.put('name', UserInfo.getName());
        inMap.put('AssignedTo',assignedToMap);
        if(inMap.get('ScreenName')=='TaskEditScreen'){
            if((Id)inMap.get('Id') != null){
                Map<String,Object> relatedToMap = new Map<String,Object>();
                Account tk = [Select id,Name from Account where id =:(Id)inMap.get('Id') ];
                relatedToMap.put('id', tk.Id);
                system.debug('======relatedToMap1======='+relatedToMap);
                relatedToMap.put('name', tk.Name);
                
                inMap.put('RelatedTo',relatedToMap);
            }
           // system.debug('======taskId======='+(Id)inMap.get('TaskId'));
            if(inMap != null && inMap.get('TaskId') != '' && (Id)inMap.get('TaskId') != null){
                 Map<String,String> tempAssignedto = new Map<String,String>();
                task tsk = [Select id,subject,status,OwnerId, Owner.Name, IsReminderSet, ReminderDateTime from task where id =:(Id)inMap.get('TaskId') ];
                tempAssignedto.put('id', tsk.OwnerId);
                tempAssignedto.put('name', tsk.Owner.Name);
                inMap.put('AssignedTo',tempAssignedto);
                inMap.put('subject',tsk.subject);
                inMap.put('status',tsk.status );
                inMap.put('ReminderDateTime',tsk.ReminderDateTime);
                if(tsk.ReminderDateTime  != null){
                    inMap.put('showReminderSection', 'true');
                    inMap.put('ReminderSet',true);
                }
            }else{
                inMap.put('subject','First dunning Reminder');
                inMap.put('status','Not Started');
            }
            inMap.put('DueDate',date.today()+5);
            
        }else{
            Map<String,Object> relatedToMap = new Map<String,Object>();
            relatedToMap.put('id', inMap.get('WhatId'));
            relatedToMap.put('name', inMap.get('Account_Name__c'));
            inMap.put('RelatedTo',relatedToMap);
            inMap.put('DueDate',date.today());
        }
        system.debug('============='+inMap);
        return inMap;
    }
    
}