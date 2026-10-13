// << START - MM - FIN-9455 - Mass Dunning -> Replace custom placeholders and translations >> 
public with sharing class cTreatmentAttachmentGenerationController {
    public String taskId {get; set; }
    public String accountId {get; set; }
    public String taskSubject {get; set; }
    public String treatmentStage {get; set; }
    public String treatmentId {get; set; }
    public String attachmentBody {get; set; }
    public String jsonFileName {get; set; }
    // public static String namespace = GOGUtilityController.getNameSpace() != null && GOGUtilityController.getNameSpace() != '' ? GOGUtilityController.getNameSpace() + '__' : '';

    public cTreatmentAttachmentGenerationController() {
        taskId = ApexPages.currentPage().getParameters().get('taskId');
        accountId = ApexPages.currentPage().getParameters().get('accountId');
        taskSubject = ApexPages.currentPage().getParameters().get('taskSubject');
        treatmentStage = ApexPages.currentPage().getParameters().get('treatmentStage');
        treatmentId = ApexPages.currentPage().getParameters().get('treatmentId');
        jsonFileName = ApexPages.currentPage().getParameters().get('jsonFileName');
        String attachmentType = ApexPages.currentPage().getParameters().get('attachmentType');
        List<celsrm__Treatment__c> treatmentList = [SELECT Id, Name, celsrm__Attachment_Name__c, celsrm__Related_Object__c, celsrm__Treatment_Steps__c, celsrm__Template_Folder_Reference_Field__c, celsrm__Email_Template_Prefix__c, celsrm__Enable_Dynamic_Template__c, celsrm__Seperate_Task_For_Step__c, celsrm__Consolidated_Treatment__c, celsrm__Attachment_Template_Name__c, celsrm__Attachment_Template_Folder__c, celsrm__Attachment_Template_Folder_Ref_Field__c FROM celsrm__Treatment__c WHERE Id = :treatmentId WITH USER_MODE LIMIT 1];
        List<Task> taskList = [SELECT Id, Subject, celsrm__Treatment_Stage__c FROM Task WHERE Id=:taskId WITH USER_MODE LIMIT 1];
        Map<String, String> attachmentDetails = cSRMTreatmentUtility.getAttachmentDetails(attachmentType, treatmentList.get(0), taskList.get(0), accountId, jsonFileName, treatmentStage);
        System.debug(attachmentDetails.get('body'));
        attachmentBody = attachmentDetails.get('body');
        String fileName = attachmentDetails.get('fileName');
    }
}
// << END - MM - FIN-9455 - Task -> Mass Dunning -> Replace custom placeholders and translations >>