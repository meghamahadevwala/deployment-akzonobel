global with sharing class cSRMTreatmentMapper {
    global cSRMTreatmentMapper() {

    }
    global class AccountCriteria {
        public List<Criteria> criteria; 
        public String criteriaCondition;
    }

    global class Criteria {
        global String field;
        global String operator;
        global String value;
    }

    global class ObjectCriteria {
        public String stepName;
        public String taskSubject;
        public Integer order;
        public List<Criteria> criteria; 
        public String criteriaCondition;
        public Boolean active;
        public String dueDate;
        public String dueDateCustom;
        public List<String> taskType;
        public String template;
        public String emailTemplatePrefix;
        public Boolean enableDynamicTemplate;
        //-- Starts | FIN-6847 | Changed By Asera | 2 Dec 2024 --//
        public Boolean enableDynamicFromAddress;
        //-- End | FIN-6847 | Changed By Asera | 2 Dec 2024 --//
        public String templateFolderReferenceField;
        public List<String> columns;
        public String sortField;
        public String sortDirection;
        public Boolean calculateTotal;
        public Boolean showTotal;
        public String aggregationField;
        public String totalTitle;
        public String description;
        public String fromAddress;
        public Boolean notifyAccountOwner;
        public Boolean attachment;
        //-- Starts | FIN-6334 | Changed By Dilshad | 13 Aug 2024 --//
        public String attachmentFormat;
        //-- Starts | FIN-6334 | Changed By Dilshad | 13 Aug 2024 --//
        //-- Starts | FIN-6364 | Changed By Dilshad | added Attachment_Name__c field | 20 Aug 2024 --//
        public String attachmentName;
        //-- Ends | FIN-6364 | Changed By Dilshad | added Attachment_Name__c field | 20 Aug 2024 --//
        public String customLogicClass;
        public Boolean autoDunning;
        //-- Start | FIN-6452 | Changed By Dilshad | 08-Oct-2024 --//
        public String customEmailBodyLogicClass;
        public String taskOwnerType;
        public String taskOwnerQueue;
        //-- Ends | FIN-6452 | Changed By Dilshad | 08-Oct-2024 --//
        //-- Start | FIN-7567 | Changed By Ravi | 12-May-2025 --//
        public String ccSourceType;
        public String ccAddress;
        public String bccSourceType;
        public String bccAddress;
        //-- Ends | FIN-7567 | Changed By Ravi | 12-May-2025 --//
        // << START - MM - FIN-9455 - Mass Dunning -> Replace custom placeholders and translations >> 
        //-- FIN-8983 | Changed by Dilshad | 28-Jan-2026 | Start --//
        public String attachmentTemplate;
        public String attachmentTemplateFolder;
        public String attachmentTemplateFolderReferenceField;
        //-- FIN-8983 | Changed by Dilshad | 28-Jan-2026 | End --//
        // << END - MM - FIN-9455 - Mass Dunning -> Replace custom placeholders and translations >> 
    }   
}