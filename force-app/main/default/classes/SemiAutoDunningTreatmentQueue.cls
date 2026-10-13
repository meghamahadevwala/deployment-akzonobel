public with sharing class SemiAutoDunningTreatmentQueue implements Queueable, Database.AllowsCallouts {
    Boolean Isattached;
    List<Object> tskList;
    public SemiAutoDunningTreatmentQueue(List<object> tskList, Boolean Isattached) {
        this.tskList = tskList;
        this.Isattached = Isattached;
    }
    public void execute(QueueableContext context) {
        for(Object ts : tskList){
            Map<Object, Object> automatedTask = (Map<Object, Object>)ts;
            String accountId = (String)automatedTask.get('WhatId');
            String taskId = String.valueOf(automatedTask.get('Id'));    
            //-- Starts | FIN-9629 | Changed by Dhwanil | 28 April 2026 --//
            Task tsk = [SELECT Id, Subject, WhatId, celsrm__Treatment__c, celsrm__Treatment_Stage__c FROM Task WHERE Id =: taskId];
            //-- ends | FIN-9629 | Changed by Dhwanil | 28 April 2026 --//
            // Map<Object,Object> inMap = new Map<Object,Object>();
            // inMap.put('Id', tsk.Id);
            // inMap.put('accountId', accountId);
            // inMap = TaskTreatmentController.returnGridData(inMap);
            // List<Object> childObjectIds = new List<Object>();
            // Map<String, Set<Id>> stepToRecIds = new Map<String, Set<Id>>();
            // List<Object> listOfStep = (List<Object>)inMap.get('listOfStep');
            // for (Object step : listOfStep) {
            //  if (inMap.containsKey(step + 'value') && inMap.get(step + 'value') != null) {
            //      inMap.put(step, inMap.get(step + 'value'));
            //      List<Object> values = (List<Object>)inMap.get(step + 'value');
            //         if (values.size() > 0) {
            //          Set<Id> tmp = new Set<Id>();
            //          for (Object vals : values) {
            //              String objVal = JSON.serialize(vals);
            //              Map<String, Object> val = (Map<String, Object>)JSON.deserializeUntyped(objVal);
            //              childObjectIds.add(val.get('Id'));
            //              tmp.add((Id)val.get('Id'));
            //          }
            //          if (tmp.size() > 0) {
            //              stepToRecIds.put((String)step, tmp);
            //          }
            //      }
            //  }
            // }
            // inMap.put('childObjectIds',childObjectIds);
            // List<EmailTemplate> billingTemplateList = new List<EmailTemplate>();
            // Account acc = [select Id,Name,celsrm__Locale__c from Account where Id=:accountId];
            // if(acc.celsrm__Locale__c != null && acc.celsrm__Locale__c != '' ){
            //     billingTemplateList = [select id, Name, FolderId, Subject, HtmlValue, TemplateType, Body from EmailTemplate where Folder.Name != null and Folder.Name=:acc.celsrm__Locale__c  and Name=:tsk.Subject AND IsActive = TRUE];
            // }
            /*else{
                billingTemplateList = [select id, Name, FolderId, Subject, HtmlValue, TemplateType, Body from EmailTemplate where Name=:tsk.Subject AND IsActive = TRUE];
            } */
            String parentId = tsk.WhatId;
            String treatmentId = tsk.celsrm__Treatment__c;
            //-- Starts | FIN-9629 | Changed by Dhwanil | 28 April 2026 --//
            celsrm__Treatment__c treatment = [Select Id, Name, celsrm__Email_Template__c, celsrm__Account_Criteria__c, celsrm__Active__c, celsrm__Related_Object__c, celsrm__Treatment_Steps__c,celsrm__Task_Due_Date__c,celsrm__Task_Type__c,celsrm__Org_Id__c, celsrm__Template_Folder_Reference_Field__c, celsrm__Email_Template_Prefix__c, celsrm__Seperate_Task_For_Step__c, celsrm__Notify_Account_Owner__c From celsrm__Treatment__c Where Id=:treatmentId];
            Map<Id, String> accountOwnerEmailMap = UtilityController.getAccountOwnerEmails(new Set<Id>{Id.valueOf(parentId)});
            //-- Ends | FIN-9629 | Changed by Dhwanil | 28 April 2026 --//
            celsrm__SRM_Configuration__c systemConfig = celsrm__SRM_Configuration__c.getOrgDefaults();

            // String template = null;
            // if(systemConfig.celsrm__Consolidated_Treatment__c && treatment.celsrm__Treatment_Steps__c != null) {
            //  List<TaskTreatmentController.ObjectCriteria> aCriterias = (List<TaskTreatmentController.ObjectCriteria>)JSON.deserialize(treatment.celsrm__Treatment_Steps__c, List<TaskTreatmentController.ObjectCriteria>.class);
            //  if(aCriterias != null && aCriterias.size() > 0) {
            //      for(TaskTreatmentController.ObjectCriteria aCriteria : aCriterias) {
            //          if (tsk.Subject == aCriteria.stepName) {
            //              template = aCriteria.template;
            //              if(systemConfig.celsrm__Enable_Dynamic_Template_In_Treatment__c){
            //                  String templatePrefix = aCriteria.emailTemplatePrefix;
            //                  if (treatment.celsrm__Template_Folder_Reference_Field__c != null && treatment.celsrm__Template_Folder_Reference_Field__c != '' && templatePrefix != null && templatePrefix !='') {
            //                      String query = 'SELECT ' +  treatment.celsrm__Template_Folder_Reference_Field__c + ' FROM Account WHERE Id=:parentId';
            //                      List<Account> accList = Database.query(query);
            //                      if (!accList.isEmpty() && accList.size() > 0) {
            //                          templatePrefix = templatePrefix + '%';
            //                          String folderName = (String)accList.get(0).get(treatment.celsrm__Template_Folder_Reference_Field__c);
            //                          if (folderName != null && folderName != '') {
            //                              billingTemplateList = [SELECT id FROM EmailTemplate WHERE Folder.Name = :folderName AND Name LIKE :templatePrefix AND IsActive = TRUE];
            //                          }
            //                          if (!billingTemplateList.isEmpty() && billingTemplateList.size() > 0) {
            //                              template = billingTemplateList.get(0).Id;
            //                          }
            //                      }
            //                  }
            //              }
                            
            //              break;
            //          }
            //      }
            //  }
            // } else if (!systemConfig.celsrm__Consolidated_Treatment__c && treatment.celsrm__Email_Template__c != null) {
            //  template = treatment.celsrm__Email_Template__c;
            //  if(systemConfig.celsrm__Enable_Dynamic_Template_In_Treatment__c){
            //      String templatePrefix = treatment.celsrm__Email_Template_Prefix__c;
            //      if (treatment.celsrm__Template_Folder_Reference_Field__c != null && treatment.celsrm__Template_Folder_Reference_Field__c != '' && templatePrefix != null && templatePrefix !='') {
            //          String query = 'SELECT ' +  treatment.celsrm__Template_Folder_Reference_Field__c + ' FROM Account WHERE Id=:parentId';
            //          List<Account> accList = Database.query(query);
            //          if (!accList.isEmpty() && accList.size() > 0) {
            //              templatePrefix = templatePrefix + '%';
            //              String folderName = (String)accList.get(0).get(treatment.celsrm__Template_Folder_Reference_Field__c);
            //              if (folderName != null && folderName != '') {
            //                  billingTemplateList = [SELECT id FROM EmailTemplate WHERE Folder.Name = :folderName AND Name LIKE :templatePrefix AND IsActive = TRUE];
            //              }
            //              if (!billingTemplateList.isEmpty() && billingTemplateList.size() > 0) {
            //                  template = billingTemplateList.get(0).Id;
            //              }
            //          }
            //      }
            //  }
            // }
            // inMap.put('EmailTemplate', template);
            // inMap.put('objectName', treatment.celsrm__Related_Object__c);

            Id fromId = treatment.celsrm__Org_Id__c != null && treatment.celsrm__Org_Id__c != '' ? treatment.celsrm__Org_Id__c : null;
            

            List < String > Toaddress = new List<String>();
            List < String > ccaddress = new List<String>();
            List < String > bccaddress = new List<String>();
            if(automatedTask.get('celsrm__To__c') != null && automatedTask.get('celsrm__To__c') != '') {
                List<String> toAdd = (List<string>)((string)automatedTask.get('celsrm__To__c')).split(',');
                for (String to : toAdd) {
                    Toaddress.addAll(to.split(';'));
                }
                // Toaddress = (List<string>)((string)automatedTask.get('celsrm__To__c')).split(',');
            } else {
                throw new celsrm.GOGDataServiceLoadException('Please enter TO Email Address');
            }
            if(automatedTask.get('celsrm__Bcc__c') != null && automatedTask.get('celsrm__Bcc__c') != ''){
                List<String> bccAdd = (List<string>)((string)automatedTask.get('celsrm__Bcc__c')).split(',');
                for (String bcc : bccAdd) {
                    bccaddress.addAll(bcc.split(';'));
                }
                // bccaddress = (List<string>)((string)automatedTask.get('celsrm__Bcc__c')).split(',');
            }
            //-- Starts | FIN-9629 | Changed by Dhwanil | 28 April 2026 --//
            if(automatedTask.get('celsrm__Cc__c') != null && automatedTask.get('celsrm__Cc__c') != ''){
                UtilityController.addDelimitedEmails(ccaddress, automatedTask.get('celsrm__Cc__c'));
                // ccaddress = (List<string>)((string)automatedTask.get('celsrm__Cc__c')).split(',');
            }
            if (UtilityController.shouldNotifyAccountOwner(tsk, treatment) && accountOwnerEmailMap.containsKey(Id.valueOf(parentId))) {
                UtilityController.addEmailIfMissing(ccaddress, accountOwnerEmailMap.get(Id.valueOf(parentId)));
            }
            //-- Ends | FIN-9629 | Changed by Dhwanil | 28 April 2026 --//
            // inMap = treatmentDataFormattingEmail.createEmailBody(inMap);

            // String subject = String.valueOf(inMap.get('subject'));
            // String templateBody = String.valueOf(inMap.get('body'));
            Map<String, Object> returnBodyMap = celsrm.SRMTreatmentUtility.getTemplateBody(tsk, treatment, systemConfig, tsk.Id, null, true, null, null);
            String subject = returnBodyMap.get('subject') != null ? (String) tsk.Subject + ' : '  + (String) returnBodyMap.get('subject') : '';
            String templateBody = returnBodyMap.get('templateBody') != null ? (String) returnBodyMap.get('templateBody') : '';
            if (Test.IsRunningTest() && (templateBody == '' || templateBody == null)) {
                templateBody = 'Test';
            }
            
            // List<Sobject> childObjList = new List<Sobject>();
            // for(String step : stepToRecIds.keySet()){
            //  for(Id Ids : stepToRecIds.get(Step)){
            //      Schema.SObjectType token =(Ids).getSObjectType();
            //      Sobject child = token.newSobject();

            //      child.put('Id', (Id)Ids);
            //      child.put('celsrm__Last_Contact_Date__c', date.today());
            //      child.put('celsrm__Last_Contacted_By__c', UserInfo.getUserId());
            //      child.put('celsrm__Treatment_Notes__c', String.valueOf(inMap.get('treatmentName')) + ' - ' + step + '\n' + UserInfo.getName() +':'+ date.today().month()+'/'+date.today().day() + '/'+ date.today().year());
            //      childObjList.add(child);
            //  }
            // }

            // if (childObjList.size() > 0) {
            //  update childObjList;
            // }
            
            tsk.Status = 'Completed';
            update tsk;
            
            Account acc = new Account();
            acc.Id = parentId;
            acc.celsrm__Last_Contact_Method__c  = 'Email';
            acc.celsrm__Last_Contact_Type__c = 'Treatment Send Email';
            acc.celsrm__Last_Contact_Date__c = date.today();
            update acc;
            
            // createTreatmentDetailFileForCompletedTask(tsk.celsrm__Treatment__c, tsk.WhatId, tsk.Id);
            List < Map < String, String >> attachmentobj = new List < Map < String, String >> ();
            if(Isattached){
                PageReference pRef= Page.celsrm__SRMTreatmentPdfGenerator;
                pRef.getParameters().put('taskId',taskId);
                pRef.getParameters().put('accountId',accountId);
                pRef.getParameters().put('taskSubject',tsk.Subject);
                pRef.getParameters().put('treatmentId',treatmentId);
                pRef.getParameters().put('jsonFileName','Treatment Details');
                ContentVersion cv = new ContentVersion();
                if (Test.isRunningTest()) {
                    cv.VersionData = blob.valueOf('Test');
                } else {
                    cv.VersionData = pRef.getContentAsPDF();
                }
                cv.Title = 'Treatment-' + tsk.Subject;
                cv.PathOnClient = 'treatment-' + tsk.Subject + '.pdf';
                upsert cv;
                Map < String, String > attachmentTable = new Map < String, String > ();
                attachmentTable.put('Id', cv.Id);
                attachmentobj.add(attachmentTable);
            }
            
            system.debug('fromId--> ' + fromId);
            system.debug('Toaddress--> ' + Toaddress);
            system.debug('subject--> ' + subject);
            system.debug('templateBody--> ' + templateBody);
            system.debug('ccaddress--> ' + ccaddress);
            system.debug('bccaddress--> ' + bccaddress);
            system.debug('attachmentobj--> ' + attachmentobj);
            system.debug('parentId--> ' + parentId);
            // Map<Object, Object> tempMap = celsrm.GOGEmailMapper.sendCustomEmail(fromId, Toaddress, subject, templateBody, null, ccaddress, bccaddress, attachmentobj, parentId);

            celsrm.GOGEmailMapper.SendEmailBean emailBean = new celsrm.GOGEmailMapper.SendEmailBean();
            emailBean.owea = fromId;
            emailBean.to = Toaddress;
            emailBean.subject = subject;
            emailBean.htmlBody = templateBody;
            emailBean.plainTextBody = null;
            emailBean.cc = ccaddress;
            emailBean.bcc = bccaddress;
            emailBean.attachment = attachmentobj;
            emailBean.parentId = parentId;
            emailBean.followUpTaskDueDate = null;
            Map<Object, Object> tempMap = celsrm.GOGEmailMapper.sendEmailWithBean(emailBean);
            for(Object t : tempMap.keySet()){
                System.debug('>>>> ' + t + ' <<>> ' + tempMap.get(t));
            }
            if(tempMap.containsKey(false)){
                throw new celsrm.GOGDataServiceLoadException((String)tempMap.get(false));
            }

        }
    }
}