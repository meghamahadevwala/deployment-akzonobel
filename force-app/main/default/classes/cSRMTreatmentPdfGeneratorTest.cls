@isTest
public with sharing class cSRMTreatmentPdfGeneratorTest {
    @isTest
    public static void testPdf() {
        string namespace = 'celsrm__';
        String accountCriteria = '{"criteria":[{"operator":"=","field":"Name","value":"Test Account"},{"operator":"=","field":"IsDeleted","value":"abcd"}],"criteriaCondition":"( 1  OR 2 )"}';
        //-- Starts | FIN-5831 | Changed By Dilshad | 9 Jul 2024 --//
        String treatmentstep = '[ { "stepName": "Proactive Email", "order": 1, "criteria": [ { "operator": ">", "field": "'+namespace+'Amount__c", "value": "0" } ], "criteriaCondition": "( 1 OR 1 )", "active": true, "taskType": [ "Email", "Call" ], "description": "", "showTotal": true, "calculateTotal": true, "aggregationField": "'+namespace+'Amount__c", "totalTitle": "'+namespace+'Amount__c", "columns": [ "Name", "'+namespace+'Amount__c", "'+namespace+'Account__c", "'+namespace+'Balance__c", "'+namespace+'So_Number__c", "'+namespace+'Po_Number__c", "'+namespace+'DPD__c", "'+namespace+'Due_Date__c", "'+namespace+'Create_Date__c" ], "autoDunning": false, "notifyAccountOwner": false, "attachment": false, "enableDynamicTemplate": false, "templateFolderReferenceField": "", "customLogicClass": "", "fromAddress": "", "taskSubject": "", "dueDate": "", "dueDateCustom": "" } ]';
        //-- Ends | FIN-5831 | Changed By Dilshad | 9 Jul 2024 --//
        Map<String, Object> treatmentRecord = new Map<String,Object>();
        treatmentRecord.put('Name', 'Test1');
        treatmentRecord.put('accountCriteria', accountCriteria);
        treatmentRecord.put('relatedObject',namespace + 'Transaction__c');
        treatmentRecord.put('segmentation', 'Bigger Account & Good Payer');
        treatmentRecord.put('treatmentSteps', treatmentstep);
        treatmentRecord.put('taskType', 'Email');
        treatmentRecord.put('templateFolderReferenceField', 'Name');
        treatmentRecord.put('emailTemplatePrefix', 'Test1');
        treatmentRecord.put('treatmentGroup', 'Test1');
        treatmentRecord.put('customLogicClass', 'Test1');
        treatmentRecord.put('segmentColor', '#FFFFFF');
        treatmentRecord.put('emailTemplate', 'Test1');
        treatmentRecord.put('templateFolder', 'Test1');
        treatmentRecord.put('treatmentName', 'Test1');
        treatmentRecord.put('dueDate', 5);
        treatmentRecord.put('order', 1);
        treatmentRecord.put('isConsolidated', false);
        treatmentRecord.put('enableDynamicTemplate', true);
        treatmentRecord.put('enableSegment', true);
        treatmentRecord.put('notifyAccountOwner', true);
        treatmentRecord.put('attachment', true);
        treatmentRecord.put('seperateTaskForStep', false);
        treatmentRecord.put('autoDunning', false);
        cSRMTreatmentPdfGeneratorTest.SaveTreatmentRecord(treatmentRecord, namespace);
        // SRMTreatmentConfiguration.SaveTreatmentRecord('','Test1',accountCriteria,namespace+'Transaction__c',treatmentstep,'Email',5,true,'','Bigger Account & Good Payer','#FFFFFF','','Test1',1,null,'','', true, true, null, null);        
        celsrm__Treatment__c treat = [SELECT Id FROM celsrm__Treatment__c LIMIT 1];
        Account acc = DataGenerator.insertAccount();
        Contact conList = DataGenerator.insertContact(acc);
        celsrm__Transaction__c transId = DataGenerator.insertTransaction(acc);
        System.assertEquals(acc.Id,transId.celsrm__Account__c, 'Account is not match');
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
        tsk.celsrm__Treatment__c = treat.id;
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
        ApexPages.currentPage().getParameters().put('taskId',tsk.Id);
        ApexPages.currentPage().getParameters().put('accountId',acc.id);
        ApexPages.currentPage().getParameters().put('taskSubject','Proactive Email');
        ApexPages.currentPage().getParameters().put('treatmentStage','Proactive Email');
        ApexPages.currentPage().getParameters().put('treatmentId',treat.id);
        ApexPages.currentPage().getParameters().put('jsonFileName','Treatment Details');
        try{
            cSRMTreatmentPdfGenerator pdfGenerate= new cSRMTreatmentPdfGenerator();
        } catch(Exception e) {
            system.debug('Exception on vf controller' + e.getMessage());
        }
        treatmentRecord.put('isConsolidated', true);
        treatmentRecord.put('Id', treat.id);
        cSRMTreatmentPdfGeneratorTest.SaveTreatmentRecord(treatmentRecord, namespace);
        try{
            cSRMTreatmentPdfGenerator pdfGenerate= new cSRMTreatmentPdfGenerator();
        } catch(Exception e) {
            system.debug('Exception on vf controller' + e.getMessage());
        }
    }
    private static String SaveTreatmentRecord(Map<String, Object> treatmentDetails, String namespace){
        celsrm__Treatment__c tre = new celsrm__Treatment__c();
        tre.name = String.valueOf(treatmentDetails.get('name'));
        tre.celsrm__Account_Criteria__c = String.valueOf(treatmentDetails.get('accountCriteria'));
        tre.celsrm__Related_Object__c = String.valueOf(treatmentDetails.get('relatedObject'));
        tre.celsrm__Treatment_Segment__c = treatmentDetails.containsKey('segmentation') ? String.valueOf(treatmentDetails.get('segmentation')) : null;
        tre.celsrm__Treatment_Steps__c = String.valueOf(treatmentDetails.get('treatmentSteps'));
        tre.celsrm__Task_Type__c = String.valueOf(treatmentDetails.get('taskType'));
        tre.celsrm__Template_Folder_Reference_Field__c = String.valueOf(treatmentDetails.get('templateFolderReferenceField'));
        tre.celsrm__Email_Template_Prefix__c = String.valueOf(treatmentDetails.get('emailTemplatePrefix'));
        tre.celsrm__Treatment_Group__c = String.valueOf(treatmentDetails.get('treatmentGroup'));
        tre.celsrm__Custom_Logic_Class__c = String.valueOf(treatmentDetails.get('customLogicClass'));
        //-- Start | FIN-6452 | Changed By Dilshad | 08-Oct-2024 --//
        tre.celsrm__Custom_Logic_For_Email_Body__c = String.valueOf(treatmentDetails.get('customEmailBodyLogicClass'));
        //-- Ends | FIN-6452 | Changed By Dilshad | 08-Oct-2024 --//
        tre.celsrm__Org_Id__c = treatmentDetails.containsKey('fromAddress') ? String.valueOf(treatmentDetails.get('fromAddress')) : null;
        tre.celsrm__Segment_Color__c = treatmentDetails.containsKey('segmentColor') ? String.valueOf(treatmentDetails.get('segmentColor')) : null;
        tre.celsrm__Email_Template__c = treatmentDetails.containsKey('emailTemplate') ? String.valueOf(treatmentDetails.get('emailTemplate')) : null;
        tre.celsrm__Template_Folder__c = treatmentDetails.containsKey('templateFolder') ? String.valueOf(treatmentDetails.get('templateFolder')) : null;
        tre.celsrm__Treatment_Name__c = String.valueOf(treatmentDetails.get('treatmentName'));

        tre.celsrm__Task_Due_Date__c = Integer.valueOf(treatmentDetails.get('dueDate'));
        tre.celsrm__Treatment_Order__c = treatmentDetails.containsKey('order') ? Integer.valueOf(treatmentDetails.get('order')) : null;

        tre.celsrm__Consolidated_Treatment__c = Boolean.valueOf(treatmentDetails.get('isConsolidated'));
        tre.celsrm__Enable_Dynamic_Template__c = Boolean.valueOf(treatmentDetails.get('enableDynamicTemplate'));
        //-- Starts | FIN-6847 | Changed By Asera | 2 Dec 2024 --//
        tre.celsrm__Enable_Dynamic_From_Address__c = treatmentDetails.containsKey('enableDynamicFromAddress') ? Boolean.valueOf(treatmentDetails.get('enableDynamicFromAddress')) : false;
        //-- End | FIN-6847 | Changed By Asera | 2 Dec 2024 --//
        tre.celsrm__Enable_Segment__c = Boolean.valueOf(treatmentDetails.get('enableSegment'));
        tre.celsrm__Notify_Account_Owner__c = Boolean.valueOf(treatmentDetails.get('notifyAccountOwner'));
        tre.celsrm__Attachment__c = Boolean.valueOf(treatmentDetails.get('attachment'));
        tre.celsrm__Seperate_Task_For_Step__c = Boolean.valueOf(treatmentDetails.get('seperateTaskForStep'));
        tre.celsrm__Auto_Treatment__c = Boolean.valueOf(treatmentDetails.get('autoDunning'));
        //-- Starts | FIN-6334 | Changed By Dilshad | 12 Aug 2024 --//
        tre.celsrm__Attachment_Format__c = String.valueOf(treatmentDetails.get('attachmentFormat'));
        //-- Ends | FIN-6334 | Changed By Dilshad | 12 Aug 2024 --//
        //-- Starts | FIN-6364 | Changed By Dilshad | saving Attachment_Name__c field | 20 Aug 2024 --//
        tre.celsrm__Attachment_Name__c = String.valueOf(treatmentDetails.get('attachmentName'));
        //-- Ends | FIN-6364 | Changed By Dilshad | saving Attachment_Name__c field | 20 Aug 2024 --//
        if (treatmentDetails.containsKey('Id') && treatmentDetails.get('Id') != '') {
            tre.Id = String.valueOf(treatmentDetails.get('Id'));
        }
        //-- Starts | FIN-6374 | Changed by Dilshad | 23 Aug 2024 --//
        tre.celsrm__Task_Owner_Queue__c = String.valueOf(treatmentDetails.get('taskOwnerQueue'));
        //-- Ends | FIN-6374 | Changed by Dilshad | 23 Aug 2024 --//
        //-- Starts | FIN-7533 | Changed by Ravi | 5 May 2025 --//
        tre.celsrm__Business_Hours__c = treatmentDetails.get('businessHours') != '' ? String.valueOf(treatmentDetails.get('businessHours')) : null;
        //-- Ends | FIN-7533 | Changed by Ravi | 5 May 2025 --//
        //-- Start | FIN-7567 | Changed By Ravi | 12-May-2025 --//
        tre.celsrm__CC_Source_Type__c = treatmentDetails.containsKey('ccSourceType') && treatmentDetails.get('ccSourceType') != '' ? String.valueOf(treatmentDetails.get('ccSourceType')) : null;
        tre.celsrm__BCC_Source_Type__c = treatmentDetails.containsKey('bccSourceType') && treatmentDetails.get('bccSourceType') != '' ? String.valueOf(treatmentDetails.get('bccSourceType')) : null;
        tre.celsrm__CC_Address__c = treatmentDetails.containsKey('ccAddress') && treatmentDetails.get('ccAddress') != '' ? String.valueOf(treatmentDetails.get('ccAddress')) : null;
        tre.celsrm__BCC_Address__c = treatmentDetails.containsKey('bccAddress') && treatmentDetails.get('bccAddress') != '' ? String.valueOf(treatmentDetails.get('bccAddress')) : null;
        //-- Ends | FIN-7567 | Changed By Ravi | 12-May-2025 --//
        System.debug('tre:'+tre);
        System.debug('customEmailBodyLogicClass:'+treatmentDetails.get('customEmailBodyLogicClass'));
        if (celsrm.GOGSecurityController.isUpsertable(namespace+'Treatment__c','name,'+namespace+'Account_Criteria__c,'+namespace+'Related_Object__c,'+namespace+'Treatment_Segment__c,'+namespace+'Treatment_Steps__c,'+namespace+'Task_Type__c,'+namespace+'Template_Folder_Reference_Field__c,'+namespace+'Email_Template_Prefix__c,'+namespace+'Treatment_Group__c,'+namespace+'Custom_Logic_Class__c,'+namespace+'Org_Id__c,'+namespace+'Segment_Color__c,'+namespace+'Email_Template__c,'+namespace+'Template_Folder__c,'+namespace+'Treatment_Name__c,'+namespace+'Task_Due_Date__c,'+namespace+'Treatment_Order__c,'+namespace+'Consolidated_Treatment__c,'+namespace+'Enable_Dynamic_Template__c,'+namespace+'Enable_Segment__c,'+namespace+'Notify_Account_Owner__c,'+namespace+'Attachment__c,'+namespace+'Seperate_Task_For_Step__c,'+namespace+'Auto_Treatment__c,'+namespace+'Attachment_Format__c,'+namespace+'Attachment_Name__c,'+namespace+'Task_Owner_Queue__c,' + namespace +'Enable_Dynamic_From_Address__c,' + namespace +'Business_Hours__c,' +  + namespace +'CC_Source_Type__c,' +  + namespace +'BCC_Source_Type__c,' +  + namespace +'CC_Address__c,' +  + namespace +'BCC_Address__c')){
            upsert tre;
        }
        return 'success';
    }
}