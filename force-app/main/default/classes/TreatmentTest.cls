@isTest
public with sharing class TreatmentTest {

    @isTest
    public static void testTreatment1() {
        celsrm__SRM_Configuration__c systemConfig = DataGenerator.insertWCMconfig();
        String accountCriteria = '{"criteria":[{"operator":"=","field":"Name","value":"Test Account"},{"operator":"=","field":"IsDeleted","value":"abcd"}],"criteriaCondition":"( 1  OR 2 )"}';
        String treatmentstep = '[{"stepName":"Proactive Email","order":1,"criteria":[{"operator":">","field":"celsrm__Amount__c","value":"0"}],"criteriaCondition":"( 1  OR 1 )","active":true,"taskType":["Email","Call"],"description":"","showTotal":true,"aggregationField":"celsrm__Amount__c","columns":["Name","celsrm__Account__c","celsrm__Amount__c","celsrm__Balance__c","celsrm__So_Number__c","celsrm__Po_Number__c","celsrm__DPD__c","celsrm__Due_Date__c","celsrm__Create_Date__c","CreatedById"]}]';
        celsrm__Treatment__c tre = DataGenerator.insertTreatmentRecord('','Test1',accountCriteria,'celsrm__Transaction__c',treatmentstep,'Call;Email',5,true,'','Bigger Account & Good Payer','#FFFFFF','','Test1', false);
        Account acc = DataGenerator.insertAccount();
        List<Contact> conList = DataGenerator.insertContact(acc,1);
        celsrm__Transaction__c transId = DataGenerator.insertTransaction(acc);
        List<celsrm__Dispute__c> disList = DataGenerator.insertDispute(transId, acc, 1);
        
        set<Id> transIdSet = new set<Id>();
        transIdSet.add(transId.id);
        Map<String, Set<Id>> stepToRecIds = new Map<String, Set<Id>>();
        stepToRecIds.put('Proactive Email',transIdSet);
        String treatmentDetails = JSON.serialize(stepToRecIds);
        //List<Task> taskInsert = DataGenerator.insertTask(acc,2);
        Task tsk = new Task();
        tsk.Subject = 'Proactive Email';
        tsk.Status = 'Not Started';
        tsk.WhatId = acc.Id;
        tsk.TaskSubtype = 'Call';
        tsk.celsrm__Treatment__c = tre.id;
        tsk.IsReminderSet = true;
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
         
        //Database.executeBatch(new SRMTreatmentService(), 1);
        string stepsData = celsrm.SRMTreatmentUtility.readTreatmentDetailsFile(tsk.Id,'Treatment Details');
        TaskTreatmentController.TaskDetails(tsk.Id);
        Map<string,Object> getScreenConfigMap = TaskTreatmentController.getScreenConfig(tsk.Id);
        
        Map<Object, Object> inMap = new  Map<Object, Object>();
        TaskTreatmentController treatCon = new TaskTreatmentController();
        List<Object> objList = new List<Object>();
        Map<Object, Object> objMap = new Map<Object, Object>();
        inMap.put('Id', tsk.Id);
        inMap.put('isSelected', true);
        treatCon.invoke('returnGridData', inMap);
        List<Object> childobjId = new List<Object>();
        childobjId.add(transId.id);
        inMap.put('childObjectIds', childobjId);
        List<Object> listOfStep = new List<Object>();
        listOfStep.add('Proactive Email');
        inMap.put('listOfStep', listOfStep);
        List<Object> step = new List<Object>();

        Map<Object,Object> step2 = new Map<Object,Object>();
        step2.put('isSelected', true);
        step2.put('Id', transId.Id);
        step2.put('celsrm__Balance__c', 100);
        step2.put('celsrm__So_Number__c', '#0456');
        step2.put('celsrm__Create_Date__c', Date.today());
        step.add(step2);
        inMap.put('Proactive Email', step);
        List<Map<Object,Object>> stepOfValue = new List<Map<Object,Object>>();
        Map<Object,Object> val = new Map<Object,Object>();
        val.put('Id', transId.id);
        stepOfValue.add(val);
        inMap.put('Proactive Emailvalue', stepOfValue);
        
        treatCon.invoke('FetchCallScript', inMap);
        inMap.put('accountId', acc.Id);
        inMap.put('isFollowup', true);
        inMap.put('FollowupDays', '7');
        inMap.put('NoteBody', 'hello');
        treatCon.invoke('logACall', inMap);
        inMap.put('Id', acc.Id);
        treatCon.invoke('showTreatmentNotes', inMap);
        Map<Object, Object> inMapForEmail = new  Map<Object, Object>();
        objMap.put('Id', acc);
        objList.add(objMap);

        list<Object> toList = new list<Object>();
        toList.add('test@test.com');
        toList.add('test12@test.com');
        toList.add('test123@test.com');
        Map<Object, Object> objMap1 = new Map<Object, Object>();
        objMap1.put('to', toList);
        objMap1.put('cc', toList);
        objMap1.put('bcc', toList);
        objMap1.put('subject', 'Testing Mail');
        objMap1.put('body', 'Testing Mail');
        //objMap1.put('from', acc);

        list<Object> transcIdList = new list<Object>();
        transcIdList.add(transId.id);
        inMapForEmail.put('Id', tsk.Id);
        inMapForEmail.put('ComposeEmail', objMap1);
        inMapForEmail.put('accountId', acc.id);
        inMapForEmail.put('childObjectIds', transcIdList);
        treatCon.invoke('customSendEmail', inMapForEmail);
       
        inMapForEmail.put('treatmentButtonName', 'Include');
        inMapForEmail.put('ContactMethod', 'Email');
        inMapForEmail.put('autoTaskId', tsk.Id);
        inMapForEmail.put('Id', acc.Id);
        try {
            treatCon.invoke('includeTreatmentOnAccount', inMapForEmail);
        } catch (Exception e) {
            system.debug('Exception on includeTreatmentOnAccount' + e.getMessage());
        }
        

        EmailTemplate emailTemp = [select id,Body,IsActive,HtmlValue from EmailTemplate where IsActive = true AND Description = null LIMIT 1];

        list<Map<object,Object>> listofField = new list<Map<object,Object>>();
        Map<object,Object> m_key_value = new Map<object,Object>();
        m_key_value.put('label','Name');
        m_key_value.put('fieldName','Name');
        m_key_value.put('type','html');
        m_key_value.put('sortable',false);
        listofField.add(m_key_value);
        Map<object,Object> m_key_value1 = new Map<object,Object>();
        m_key_value1.put('label','celsrm__Balance__c');
        m_key_value1.put('fieldName','celsrm__Balance__c');
        m_key_value1.put('type','CURRENCY');
        m_key_value1.put('sortable',false);
        listofField.add(m_key_value1);
        Map<object,Object> m_key_value2 = new Map<object,Object>();
        m_key_value2.put('label','celsrm__Base_Currency__c');
        m_key_value2.put('fieldName','celsrm__Base_Currency__c');
        m_key_value2.put('type','CURRENCY');
        m_key_value2.put('sortable',false);
        listofField.add(m_key_value2);
        Map<object,Object> m_key_value3 = new Map<object,Object>();
        m_key_value3.put('label','celsrm__Discount_Date__c');
        m_key_value3.put('fieldName','celsrm__Discount_Date__c');
        m_key_value3.put('type','DATE');
        m_key_value3.put('sortable',false);
        listofField.add(m_key_value3);
        Map<object,Object> m_key_value4 = new Map<object,Object>();
        m_key_value4.put('label','CreatedDate');
        m_key_value4.put('fieldName','CreatedDate');
        m_key_value4.put('type','DATETIME');
        m_key_value4.put('sortable',false);
        listofField.add(m_key_value4);

        list<Map<object,Object>> listofValue = new list<Map<object,Object>>();
        Map<object,Object> m_key_valueObject = new Map<object,Object>();
        m_key_valueObject.put('celsrm__Transaction__c','celsrm__Transaction__c');
        m_key_valueObject.put('celsrm__Balance__c',200);
        m_key_valueObject.put('CreatedDate','2015-09-28T21:43:36.000z');
        m_key_valueObject.put('celsrm__Discount_Date__c',Date.today());
        m_key_valueObject.put('celsrm__Base_Currency__c','USD');
        m_key_valueObject.put('Name','Name');
        listofValue.add(m_key_valueObject);
        treatmentPrefetchTemplate trtForEmail =  new treatmentPrefetchTemplate();
        // treatmentDataFormattingEmail trtDataForEmail =  new treatmentDataFormattingEmail();
        List<string> stepList = new list<string>();
        stepList.add('Proactive Email');
        List<Object> stepA = new List<Object>();
        Map<Object,Object> step1 = new Map<Object,Object>();
        step1.put('isSelected', true);
        step1.put('Id', transId.id);
        step1.put('celsrm__Amount__c', 0);
        step1.put('celsrm__Balance__c', 100);
        step1.put('celsrm__So_Number__c', '#0456');
        step1.put('celsrm__Create_Date__c', Date.today());
        stepA.add(step1);
        Map<Object, Object> inMapForFormattingEmail = new  Map<Object, Object>();   
        inMapForFormattingEmail.put('accountId',acc.id);
        inMapForFormattingEmail.put('Id',tsk.id);
        inMapForFormattingEmail.put('EmailTemplate',emailTemp.id);
        inMapForFormattingEmail.put('objectName','celsrm__Transaction__c');
        inMapForFormattingEmail.put('listOfStep',stepList);
        inMapForFormattingEmail.put('Proactive Email',stepA);
        inMapForFormattingEmail.put('Proactive Email'+'value',listofValue);
        inMapForFormattingEmail.put('Proactive Email'+'columns',listofField);
        inMapForFormattingEmail.put('Proactive Email'+'description','this is test');
        inMapForFormattingEmail.put('Proactive Email'+'aggregationField','celsrm__Balance__c');
        inMapForFormattingEmail.put('Proactive Email'+'showTotal',true);
        inMapForFormattingEmail.put('Proactive Email'+'totalTitle','celsrm__Balance__c');
        inMapForFormattingEmail.put('childObjectIds', transcIdList);
        inMapForFormattingEmail.put('taskSubject', 'Proactive Email');
        inMapForFormattingEmail.put('isTaskScreen', true);
        inMapForFormattingEmail.put('seperateTaskForStep', true);
        inMapForFormattingEmail.put('treatmentStage', 'Proactive Email');
        trtForEmail.invoke('', inMapForFormattingEmail);
        // trtDataForEmail.invoke(inMapForFormattingEmail, null, null);
        list<Map<String,Object>> listofField1 = new list<Map<String,Object>>();
        Map<String,Object> m_key_valuee = new Map<String,Object>();
        m_key_valuee.put('label','Name');
        m_key_valuee.put('fieldName','Name');
        m_key_valuee.put('type','html');
        m_key_valuee.put('sortable',false);
        listofField1.add(m_key_valuee);
        Map<String,Object> m_key_valuee1 = new Map<String,Object>();
        m_key_valuee1.put('label','celsrm__Balance__c');
        m_key_valuee1.put('fieldName','celsrm__Balance__c');
        m_key_valuee1.put('type','CURRENCY');
        m_key_valuee1.put('sortable',false);
        listofField1.add(m_key_valuee1);
        Map<String,Object> m_key_valuee2 = new Map<String,Object>();
        m_key_valuee2.put('label','celsrm__Base_Currency__c');
        m_key_valuee2.put('fieldName','celsrm__Base_Currency__c');
        m_key_valuee2.put('type','CURRENCY');
        m_key_valuee2.put('sortable',false);
        listofField1.add(m_key_valuee2);
        Map<String,Object> m_key_valuee3 = new Map<String,Object>();
        m_key_valuee3.put('label','celsrm__Discount_Date__c');
        m_key_valuee3.put('fieldName','celsrm__Discount_Date__c');
        m_key_valuee3.put('type','DATE');
        m_key_valuee3.put('sortable',false);
        listofField1.add(m_key_valuee3);
        Map<String,Object> m_key_valuee4 = new Map<String,Object>();
        m_key_valuee4.put('label','CreatedDate');
        m_key_valuee4.put('fieldName','CreatedDate');
        m_key_valuee4.put('type','DATETIME');
        m_key_valuee4.put('sortable',false);
        listofField1.add(m_key_valuee4);
        Map<String,Object> m_key_valuee5 = new Map<String,Object>();
        m_key_valuee5.put('label','Acc');
        m_key_valuee5.put('fieldName','celsrm__Account__c');
        m_key_valuee5.put('type','html');
        m_key_valuee5.put('sortable',false);
        listofField1.add(m_key_valuee5);
        Map<String,Object> m_key_valuee6 = new Map<String,Object>();
        m_key_valuee6.put('label','createdby');
        m_key_valuee6.put('fieldName','CreatedById');
        m_key_valuee6.put('type','html');
        m_key_valuee6.put('sortable',false);
        listofField1.add(m_key_valuee6);
        inMapForFormattingEmail.put('Proactive Email'+'columns',listofField1);
        inMapForFormattingEmail.put('seperateTaskForStep', false);
        trtForEmail.invoke('', inMapForFormattingEmail);
        update systemConfig;
        trtForEmail.invoke('', inMapForFormattingEmail);
        // trtDataForEmail.invoke(inMapForFormattingEmail, null, null);
        String crnyCode = treatmentPrefetchTemplate.formatDoubleValue('USD',Double.valueOf(840));
        inMapForEmail.put('Id', acc.Id);
        treatCon.invoke('fetchContactEmailForAccount', inMapForEmail);
        inMapForEmail.put('ContactMethod', 'Phone');
        inMapForEmail.put('treatmentEmail', 'test@test.com');
        inMapForEmail.put('isFollowup', true);
        inMapForEmail.put('FollowupDays', Date.today().addDays(5));
        
        try {
            ContentVersion contentVersion1 = new ContentVersion(
                Title = 'Treatment Details',
                PathOnClient = 'treatmentdetails.json',
                ReasonForChange = 'updated records',
                VersionData = Blob.valueOf(treatmentDetails),
                IsMajorVersion = true
            );
            insert contentVersion1;

            ContentDocumentLink cDocLink1  = new ContentDocumentLink();
            System.runAs(thisUser) {
                cDocLink1.LinkedEntityId = tsk.id;
                cDocLink1.ContentDocumentId = [SELECT Id FROM ContentDocument LIMIT 1].Id;
                insert cDocLink1;
            } 
            treatCon.invoke('includeTreatmentOnAccount', inMapForEmail);
        } catch (Exception e) {
            system.debug('Exception on includeTreatmentOnAccount' + e.getMessage());
        }
        Map<Object, Object> automatedTask = new Map<Object, Object>();
        automatedTask.put('WhatId',acc.Id);
        automatedTask.put('Id',tsk.Id);
        automatedTask.put('celsrm__To__c','test@test.com');
        automatedTask.put('celsrm__Bcc__c','test@test.com');
        automatedTask.put('celsrm__Cc__c','test@test.com');
        List<Object> tskList = new List<Object>();
        tskList.add(automatedTask);
        try {
            ContentVersion contentVersion1 = new ContentVersion(
                Title = 'Treatment Details',
                PathOnClient = 'treatmentdetails.json',
                ReasonForChange = 'updated records',
                VersionData = Blob.valueOf(treatmentDetails),
                IsMajorVersion = true
            );
            insert contentVersion1;
            ContentVersion cVer = [Select Id, ContentDocumentId, Title, FileType, ContentSize, VersionData FROM ContentVersion WHERE Id = :contentVersion1.Id];
            ContentDocumentLink cDocLink1  = new ContentDocumentLink();
            System.runAs(thisUser) {
                cDocLink1.LinkedEntityId = tsk.id;
                cDocLink1.ContentDocumentId = cVer.ContentDocumentId;
                insert cDocLink1;
            } 
            SemiAutoDunningTreatmentBatch bafl1 = new SemiAutoDunningTreatmentBatch(tskList, true);
            Database.executeBatch(bafl1,1);
        } catch (Exception e) {
            system.debug('Exception on includeTreatmentOnAccount' + e.getMessage());
        }
    }

    //  @isTest
    // public static void testTreatment2() {
    //     String accountCriteria1 = '{"criteria":[{"operator":"=","field":"Name","value":"Test Account"},{"operator":"=","field":"IsDeleted","value":"abcd"}],"criteriaCondition":"( 1  OR 2 )"}';
    //     String treatmentstep1 = '[{"stepName":"Proactive Email","order":1,"criteria":[{"operator":"=","field":"celsrm__Tax_Exempt__c","value":true},{"operator":">","field":"celsrm__Base_Amount__c","value":"0"},{"operator":"=","field":"celsrm__Promises_Risk__c","value":"0"},{"operator":">","field":"celsrm__Close_Date__c","value":"2020/02/02"}],"criteriaCondition":"( 1  OR 1 )","active":true,"taskType":["Email","Call"],"description":"","columns":["Name","celsrm__Tax_Exempt__c","celsrm__Balance__c","celsrm__So_Number__c","celsrm__Po_Number__c","celsrm__DPD__c","celsrm__Due_Date__c","celsrm__Create_Date__c"]}]';
    //     TreatmentConfiguration.SaveTreatmentRecord('','Test1',accountCriteria1,'celsrm__Transaction__c',treatmentstep1,'Call',5,true,'','Bigger Account & Good Payer','#FFFFFF','','Test1');
    //     Account acc1 = DataGenerator.insertAccount();
    //     try{
    //         DataGenerator.insertTransaction(acc1);
    //         Database.executeBatch(new SRMTreatmentService(), 1);
    //     }catch(Exception e){
    //         System.debug('Exception>> ' + e.getMessage());      
    //     }
    // }
}