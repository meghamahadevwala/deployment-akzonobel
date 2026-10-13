global with sharing class WCM_FetchdefaultView implements celsrm.GOGIScreenCustomLogic {
    global Map<Object, Object> invoke(String functionName, Map<Object, Object> inMap) {
        system.debug('=========='+inMap);
        String currUser = UserInfo.getUserId();
        String accId = String.valueOf(inMap.get('Id'));
        String objectName = String.valueOf(inMap.get('ListViewObject'));
        String objectParentField = String.valueOf(inMap.get('ListViewParentField'));
        System.debug(' @@ currUser : ' + currUser);
        System.debug(' @@ accId : ' + accId );
        System.debug(' @@ objectName : ' + objectName );
        System.debug(' @@ objectParentField : ' + objectParentField );
        System.debug('listview : ' + inMap.get('ListView'));
        //By Ravi | 12-02-2020 | user preference
        celsrm__User_Preference__c userPref  = new celsrm__User_Preference__c();
        List<celsrm__Custom_List_View__c> obj = new List<celsrm__Custom_List_View__c>();
        if ((inMap.containsKey('ListView') && (String.valueOf(inMap.get('ListView')) == null || String.valueOf(inMap.get('ListView')) == '')) || (inMap.containsKey('View') && (String.valueOf(inMap.get('View')) == null|| String.valueOf(inMap.get('View')) == '')) ) {
            try {
                String query= '';
                query = 'SELECT Id,celsrm__sendStatementListView__c,celsrm__Is_Attach_Checked__c,celsrm__AttachmentTypes__c FROM celsrm__User_Preference__c WHERE celsrm__User__c =:currUser LIMIT 1';
                userPref = Database.query(query);
            } catch (Exception e) {
                System.debug('exception>> ' + e.getMessage());
            }
            
            if (userPref != null && userPref.celsrm__sendStatementListView__c != null && userPref.celsrm__sendStatementListView__c != '') {
                obj = [Select Id, Name From celsrm__Custom_List_View__c Where Id =: userPref.celsrm__sendStatementListView__c LIMIT 1 ];
            } else {
                String query = 'Select Id, Name From celsrm__Custom_List_View__c Where celsrm__ListView_For_Object__c = :objectName ';
                query += ' AND (celsrm__Is_Global__c = TRUE OR CreatedById = :currUser) AND celsrm__Is_Default__c = TRUE ORDER BY name ASC';
                System.debug('@@@ final query ' + query);
                obj = Database.query(query);
            } 
            System.debug('Obj>> ' + obj); 
        }
        
        //By Ravi | 12-02-2020 | user preference
        if(inMap.containsKey('ListView') && obj.size() > 0){
            inMap.put('ListView',obj.get(0).Id);
        }
        else if(inMap.containsKey('View') && obj.size() > 0){
            inMap.put('View',obj.get(0).Id);
        }
         if( functionName == 'Send Statement'){
             //By Ravi | 12-02-2020 | user preference
            
            if (userPref != null && userPref.celsrm__AttachmentTypes__c != null) {
                inMap.put('StatementFormat', userPref.celsrm__AttachmentTypes__c);
            }
            //By Ravi | 12-02-2020 | user preference
             String Id = (String)inMap.get('Id');
            List<Contact> mapContact = [Select Id,phone,Name,celsrm__Default__c From Contact where AccountId =: Id and celsrm__Default__c = True];
            if(mapContact != null && mapContact.size()>0){
                inMap.put('ContactName', mapContact.get(0).Id);
                inMap.put('ContactCalled', mapContact.get(0).phone);
            }else{
                inMap.put('ContactName', '');
                inMap.put('ContactCalled', '');
            }
        }
        if( inMap.get('ggScreenName') == 'WCM_TaskGridScreen'){
            //By Ravi | 12-02-2020 | user preference
            if (userPref != null && userPref.celsrm__Is_Attach_Checked__c != null) {
                inMap.put('IsAttached', userPref.celsrm__Is_Attach_Checked__c);
            }
            if (userPref != null && userPref.celsrm__AttachmentTypes__c != null) {
                inMap.put('attachtype', userPref.celsrm__AttachmentTypes__c);
            }
            //By Ravi | 12-02-2020 | user preference
        List<Task> tsubj = [Select Subject from Task where 
                        TaskSubtype != 'Email' And (NOT Subject LIKE 'Auto%') 
                        AND (SUbject LIKE '%Notice*' ) AND Status != 'Completed' and Status  != 'Auto Dunning Error' and What.type=:'Account' and ownerId=:UserInfo.getUserId() limit 1] ;
            
          if( tsubj != null && tsubj.size()>0){
           inMap.put('SubjectFilter',tsubj.get(0).SUbject);
           
             List <Task> tlst = [Select t.Id,t.What.type,t.ownerId, t.ActivityDate,t.Account_Name__c, t.celsrm__Notes__c, Total_Past_Due__c,Total_AR__c, 
                                t.WhatId, t.Type, t.SystemModstamp, t.Subject, t.Status, t.Priority , t.Description, 
                                t.CallType, t.CallObject, t.AccountId,t.celsrm__Treatment__c,
                                t.Owner.Email From Task t where t.Subject =:tsubj.get(0).SUbject and
                                t.Status != 'Completed' and t.Status  != 'Auto Dunning Error' and t.what.type=:'Account' and t.ownerId =:UserInfo.getUserId()] ;
                List < Id > AccIDs = new List< Id >();
            
            for(Task ts: tlst ){            
                system.debug('ts'+ts);
                AccIDs.add(ts.WhatID);                    
            }
            //  celsrm__SRM_Configuration__c systemConfig = celsrm__SRM_Configuration__c.getOrgDefaults();
            
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
                        // t.celsrm__From__c = Id.ValueOf(listName.get(0).Id);
                }
            }
            // inMap.put('isVisibleDataGrid',false);
              inMap.put('CountNumberOfTask','<b>Task# : '+String.ValueOf(tlst.Size()) + '</b>'); 
              inMap.put('editableTaskList', tlst);
              }else{
                  throw new celsrm.GOGDataServiceLoadException('There is no task for Dunning');
              }
         }
        return inMap;
    }    
}