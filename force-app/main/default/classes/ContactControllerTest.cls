@isTest
public class ContactControllerTest {
      public static testMethod void Case(){
        Account acc = DataGenerator.insertAccount();
        Account acc2 = DataGenerator.insertAccount();
        DataGenerator.insertDefaultContact(acc);
        String accountCriteria = '{"criteria":[{"operator":"=","field":"Name","value":"Test Account"},{"operator":"=","field":"IsDeleted","value":"abcd"}],"criteriaCondition":"( 1  OR 2 )"}';
        String treatmentstep = '[{"stepName":"Proactive Email","order":1,"criteria":[{"operator":">","field":"celsrm__Amount__c","value":"0"}],"criteriaCondition":"( 1  OR 1 )","active":true,"taskType":["Email","Call"],"description":"","showTotal":true,"aggregationField":"celsrm__Amount__c","columns":["Name","celsrm__Account__c","celsrm__Amount__c","celsrm__Balance__c","celsrm__So_Number__c","celsrm__Po_Number__c","celsrm__DPD__c","celsrm__Due_Date__c","celsrm__Create_Date__c","CreatedById"]}]';
        celsrm__Treatment__c tre = DataGenerator.insertTreatmentRecord('','Test1',accountCriteria,'celsrm__Transaction__c',treatmentstep,'Call;Email',5,true,'','Bigger Account & Good Payer','#FFFFFF','','Test1', false);
        
        celsrm__Transaction__c transId = DataGenerator.insertTransaction(acc);
        set<Id> transIdSet = new set<Id>();
        transIdSet.add(transId.id);
        Map<String, Set<Id>> stepToRecIds = new Map<String, Set<Id>>();
        stepToRecIds.put('Proactive Email',transIdSet);
        String treatmentDetails = JSON.serialize(stepToRecIds);
        Task tsk = new Task();
        tsk.Subject = 'Proactive Email';
        tsk.Status = 'Not Started';
        tsk.WhatId = acc.Id;
        tsk.TaskSubtype = 'Call';
        tsk.celsrm__Treatment__c = tre.id;
        tsk.IsReminderSet = true;
        tsk.celsrm__Treatment_Stage__c = 'Proactive Email';
        tsk.ReminderDateTime = Datetime.now();
        insert tsk;
          
          User thisUser = [select Id from User where Id =: UserInfo.getUserId()];
     
        ContentVersion contentVersion = new ContentVersion(
            Title = 'Treatment Details',
            PathOnClient = 'treatmentdetails.json',
            ReasonForChange = 'updated records',
            VersionData = Blob.valueOf(treatmentDetails),
            IsMajorVersion = true
        );
        insert contentVersion;

        ContentDocumentLink cDocLink  = new ContentDocumentLink();
        System.runAs(thisUser) {
            cDocLink.LinkedEntityId = tsk.id;
            cDocLink.ContentDocumentId = [SELECT Id FROM ContentDocument LIMIT 1].Id;
            insert cDocLink;
        } 
          
        ContactController agingchart= new ContactController();
        ContactController.getContactRecord(acc.id);   
        ContactController.getTotalOpenTask(acc.Id);
        ContactController.getTotalBucket(acc.Id);
        ContactController.getDefaultContactRecord(acc.Id);
        ContactController.getLatestTreatmentTask(acc.Id);
     }
}