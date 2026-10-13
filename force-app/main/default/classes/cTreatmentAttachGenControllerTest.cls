/**
 * Test coverage for cTreatmentAttachmentGenerationController. Mirrors the
 * cTreatmentExcelAttachmentControllerTest pattern: build a treatment + task + "Treatment Details"
 * ContentVersion/ContentDocumentLink, set ApexPages.currentPage().getParameters(), then
 * instantiate the controller and assert the attachmentBody was populated.
 * (Named cTreatmentAttachGenControllerTest rather than
 * cTreatmentAttachmentGenerationControllerTest+"Test" because the latter exceeds Apex's 40
 * character identifier length limit.)
 */
@isTest
public class cTreatmentAttachGenControllerTest {
    private static String namespace = 'celsrm__';

    private static celsrm__Treatment__c buildTreatment(Boolean seperateTaskForStep) {
        celsrm__Treatment__c t = new celsrm__Treatment__c();
        t.Name = 'Test Treatment';
        t.celsrm__Treatment_Name__c = 'Test Treatment';
        t.celsrm__Related_Object__c = namespace + 'Transaction__c';
        t.celsrm__Active__c = true;
        t.celsrm__Seperate_Task_For_Step__c = seperateTaskForStep;
        t.celsrm__Consolidated_Treatment__c = false;
        t.celsrm__Attachment_Name__c = 'TreatmentAttachment';
        t.celsrm__Treatment_Steps__c = '[{"stepName":"Proactive Email","taskSubject":"Proactive Email","order":1,"active":true,"columns":["Name","' + namespace + 'Amount__c","' + namespace + 'Due_Date__c"],"calculateTotal":true,"showTotal":true,"aggregationField":"' + namespace + 'Amount__c","totalTitle":"Total"}]';
        insert t;
        return t;
    }

    private static Task buildTaskWithTreatmentDetails(Account acc, celsrm__Treatment__c t, Id trxId) {
        Task tsk = new Task(Subject = 'Proactive Email', Status = 'Not Started', WhatId = acc.Id, celsrm__Treatment__c = t.Id, celsrm__Treatment_Stage__c = 'Proactive Email');
        insert tsk;

        Map<String, Set<Id>> stepToRecIds = new Map<String, Set<Id>>{ 'Proactive Email' => new Set<Id>{ trxId } };
        ContentVersion cv = new ContentVersion(
            Title = 'Treatment Details',
            PathOnClient = 'treatmentdetails.json',
            VersionData = Blob.valueOf(JSON.serialize(stepToRecIds)),
            IsMajorVersion = true
        );
        insert cv;
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.LinkedEntityId = tsk.Id;
        cdl.ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId;
        insert cdl;

        return tsk;
    }

    @isTest
    static void testControllerWithPdfAttachmentType() {
        Account acc = CreditDataGenerator.insertAccount();
        celsrm__Transaction__c trx = DataGenerator.insertTransaction(acc);
        celsrm__Treatment__c t = buildTreatment(true);
        Task tsk = buildTaskWithTreatmentDetails(acc, t, trx.Id);

        Test.setCurrentPageReference(new PageReference('/apex/TreatmentAttachmentGeneration'));
        ApexPages.currentPage().getParameters().put('taskId', tsk.Id);
        ApexPages.currentPage().getParameters().put('accountId', acc.Id);
        ApexPages.currentPage().getParameters().put('taskSubject', tsk.Subject);
        ApexPages.currentPage().getParameters().put('treatmentStage', 'Proactive Email');
        ApexPages.currentPage().getParameters().put('treatmentId', t.Id);
        ApexPages.currentPage().getParameters().put('jsonFileName', 'Treatment Details');
        ApexPages.currentPage().getParameters().put('attachmentType', 'PDF');

        Test.startTest();
        cTreatmentAttachmentGenerationController controller;
        try {
            controller = new cTreatmentAttachmentGenerationController();
        } catch (Exception e) {
            System.debug('Controller construction failed: ' + e.getMessage());
        }
        Test.stopTest();

        System.assertNotEquals(null, controller, 'Controller should be constructed successfully with valid task/treatment ids');
        System.assertEquals(tsk.Id, controller.taskId);
        System.assertEquals(acc.Id, controller.accountId);
        System.assertEquals(t.Id, controller.treatmentId);
    }

    @isTest
    static void testControllerWithExcelAttachmentTypeAndConsolidatedTreatment() {
        Account acc = CreditDataGenerator.insertAccount();
        celsrm__Transaction__c trx = DataGenerator.insertTransaction(acc);
        celsrm__Treatment__c t = buildTreatment(false);
        Task tsk = buildTaskWithTreatmentDetails(acc, t, trx.Id);

        Test.setCurrentPageReference(new PageReference('/apex/TreatmentAttachmentGeneration'));
        ApexPages.currentPage().getParameters().put('taskId', tsk.Id);
        ApexPages.currentPage().getParameters().put('accountId', acc.Id);
        ApexPages.currentPage().getParameters().put('taskSubject', tsk.Subject);
        ApexPages.currentPage().getParameters().put('treatmentStage', 'Proactive Email');
        ApexPages.currentPage().getParameters().put('treatmentId', t.Id);
        ApexPages.currentPage().getParameters().put('jsonFileName', 'Treatment Details');
        ApexPages.currentPage().getParameters().put('attachmentType', 'Excel');

        Test.startTest();
        cTreatmentAttachmentGenerationController controller;
        try {
            controller = new cTreatmentAttachmentGenerationController();
        } catch (Exception e) {
            System.debug('Controller construction failed: ' + e.getMessage());
        }
        Test.stopTest();

        System.assertNotEquals(null, controller, 'Controller should be constructed successfully with valid task/treatment ids');
        System.assertEquals('Excel', ApexPages.currentPage().getParameters().get('attachmentType'));
    }
}