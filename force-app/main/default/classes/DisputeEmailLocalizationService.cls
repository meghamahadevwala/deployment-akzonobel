public with sharing class DisputeEmailLocalizationService {
    //-- Start | FIN-9672 | Changed by Ravi | 05 May 2026 --//
    public static final String SOURCE_ACCOUNT = 'Account';
    public static final String SOURCE_DISPUTE = 'Dispute';
    public static final String SOURCE_USER_MASTER = 'UserMaster';
    public static final String LANGUAGE_FIELD_NAME = 'Language__c';
    public static final String REMINDER_TEMPLATE_NAME = 'Dispute Reminder';
    public static final String ESCALATION_TEMPLATE_NAME = 'Dispute Escalation';
    public static final String INTERNAL_ASSIGNMENT_TEMPLATE_NAME = 'Email Alert To Dispute Resolver';
    //-- Start | FIN-9749 | Changed by Asera | 11 May 2026 --//
    public static final String EXTERNAL_ASSIGNMENT_TEMPLATE_NAME = 'Email Alert To External Dispute Approver';
    public static final String EXTERNAL_RESOLVER_ASSIGNMENT_TEMPLATE_NAME = 'Email Alert To External Dispute Resolver';
    //-- End | FIN-9749 | Changed by Asera | 11 May 2026 --//
    public static final String OWNER_APPROVED_TEMPLATE_NAME = 'Email Alert To Dispute Owner (Approve)';
    public static final String OWNER_REJECTED_TEMPLATE_NAME = 'Email Alert To Dispute Owner (Reject)';
    public static final String LEGACY_DISPUTE_MANAGEMENT_FOLDER = 'Dispute Management';
    public static final String LEGACY_DISPUTE_REMINDER_FOLDER = 'Dispute Reminder & Escalation';

    //-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
    private static final String NAMESPACE_PREFIX = 'celsrm__';
    //-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
    private static Map<String, Id> templateIdsByLookupKey = new Map<String, Id>();
    private static celsrm__Dispute_Configuration__c cachedConfig;

    public class TemplateSelection {
        public Id templateId;
        public String folderName;
        public String templateName;
    }

    public static celsrm__Dispute_Configuration__c getConfig() {
        if (cachedConfig == null) {
            cachedConfig = celsrm__Dispute_Configuration__c.getOrgDefaults();
        }
        return cachedConfig;
    }

    public static String getDefaultLanguageFolder() {
        return getConfig() != null ? getConfig().Default_Email_Language_Folder__c : null;
    }

    // Callers build dynamic SOQL, so only the configured language source field is exposed here.
    public static Set<String> getWorkflowDetailAdditionalQueryFields() {
        Set<String> queryFields = new Set<String>();
        String sourceObject = getConfiguredSourceObject();
        String configuredField = getValidatedConfiguredFieldApi(sourceObject);

        if (String.isBlank(configuredField)) {
            return queryFields;
        }
        //-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
        if (sourceObject == SOURCE_ACCOUNT) {
            queryFields.add('celsrm__Dispute__r.celsrm__Account__r.' + configuredField);
        } else if (sourceObject == SOURCE_DISPUTE) {
            queryFields.add('celsrm__Dispute__r.' + configuredField);
        } else if (sourceObject == SOURCE_USER_MASTER) {
            queryFields.add('celsrm__User_Master__r.' + configuredField);
            queryFields.add('celsrm__User_Master__r.celsrm__Manager__r.' + configuredField);
        }
        //-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//

        return queryFields;
    }

    public static Set<String> getDisputeAdditionalQueryFields() {
        Set<String> queryFields = new Set<String>();
        String sourceObject = getConfiguredSourceObject();
        String configuredField = getValidatedConfiguredFieldApi(sourceObject);

        if (String.isBlank(configuredField)) {
            return queryFields;
        }
        if (sourceObject == SOURCE_ACCOUNT) {
            queryFields.add('celsrm__Account__r.' + configuredField);
        } else if (sourceObject == SOURCE_DISPUTE) {
            queryFields.add(configuredField);
        } else if (sourceObject == SOURCE_USER_MASTER) {
            //-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
            queryFields.add('celsrm__Resolver_User_Master__r.' + configuredField);
            //-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
        }

        return queryFields;
    }

    public static Set<String> getOwnerNotificationAdditionalQueryFields() {
        Set<String> queryFields = new Set<String>();
        String sourceObject = getConfiguredSourceObject();
        String configuredField = getValidatedConfiguredFieldApi(sourceObject);

        if (String.isBlank(configuredField)) {
            return queryFields;
        }

        if (sourceObject == SOURCE_ACCOUNT) {
            queryFields.add('celsrm__Account__r.' + configuredField);
        } else if (sourceObject == SOURCE_DISPUTE) {
            queryFields.add(configuredField);
        }

        return queryFields;
    }

    // Assignment emails resolve language from dispute context because there is no workflow detail yet.
    public static String resolveAssignmentLanguage(celsrm__Dispute__c disputeRecord) {
        String sourceObject = getConfiguredSourceObject();
        String configuredField = getValidatedConfiguredFieldApi(sourceObject);
        String languageValue;

        if (sourceObject == SOURCE_ACCOUNT) {
            languageValue = getDisputeAccountFieldValue(disputeRecord, configuredField);
        } else if (sourceObject == SOURCE_DISPUTE) {
            languageValue = getFieldValue(disputeRecord, configuredField);
        } else if (sourceObject == SOURCE_USER_MASTER) {
            languageValue = getDisputeUserMasterFieldValue(disputeRecord, configuredField);
        }

        return normalizeLanguageFolder(languageValue);
    }

    public static String resolveOwnerNotificationLanguage(
        celsrm__Dispute__c disputeRecord,
        User ownerUser,
        //-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
        celsrm__User_Master__c ownerUserMaster
        //-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
    ) {
        String sourceObject = getConfiguredSourceObject();
        String configuredField = getValidatedConfiguredFieldApi(sourceObject);
        String languageValue;

        if (sourceObject == SOURCE_ACCOUNT) {
            languageValue = getDisputeAccountFieldValue(disputeRecord, configuredField);
        } else if (sourceObject == SOURCE_DISPUTE) {
            languageValue = getFieldValue(disputeRecord, configuredField);
        } else if (sourceObject == SOURCE_USER_MASTER) {
            languageValue = getOwnerUserMasterFieldValue(ownerUser, ownerUserMaster, configuredField);
        }

        return normalizeLanguageFolder(languageValue);
    }

    //-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
    public static Map<Id, celsrm__User_Master__c> getUserMastersByUserId(Set<Id> userIds) {
        Map<Id, celsrm__User_Master__c> userMastersByUserId = new Map<Id, celsrm__User_Master__c>();
    //-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
        if (userIds == null || userIds.isEmpty()) {
            return userMastersByUserId;
        }

        //-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
        String languageFieldApi = getFullApiName(LANGUAGE_FIELD_NAME);
        Set<String> selectFields = new Set<String>{ 'Id', 'celsrm__User__c', languageFieldApi };
        //-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
        String configuredField = getValidatedConfiguredFieldApi(SOURCE_USER_MASTER);
        if (!String.isBlank(configuredField)) {
            selectFields.add(configuredField);
        }

        String query = 'SELECT ' + String.join(new List<String>(selectFields), ', ') +
            //-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
            ' FROM celsrm__User_Master__c WHERE celsrm__User__c IN :userIds';
        for (celsrm__User_Master__c userMaster : Database.query(query)) {
            if (userMaster.celsrm__User__c != null) {
                userMastersByUserId.put(userMaster.celsrm__User__c, userMaster);
            //-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
            }
        }
        return userMastersByUserId;
    }

    // Reminder and escalation can point at different user-master records, so the caller passes the escalation flag in.
    //-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
    public static String resolveWorkflowDetailLanguage(
        celsrm__Dispute_Workflow_Details__c workflowDetail,
        Boolean escalationEmail
    ) {
    //-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
        String sourceObject = getConfiguredSourceObject();
        String configuredField = getValidatedConfiguredFieldApi(sourceObject);
        String languageValue;

        if (sourceObject == SOURCE_ACCOUNT) {
            languageValue = getWorkflowDetailAccountFieldValue(workflowDetail, configuredField);
        } else if (sourceObject == SOURCE_DISPUTE) {
            languageValue = getWorkflowDetailDisputeFieldValue(workflowDetail, configuredField);
        } else if (sourceObject == SOURCE_USER_MASTER) {
            languageValue = getWorkflowDetailUserMasterFieldValue(workflowDetail, configuredField, escalationEmail);
        }

        return normalizeLanguageFolder(languageValue);
    }

    // Folder resolution now uses the configured field value directly so admins control the template folder name.
    public static String normalizeLanguageFolder(String languageValue) {
        if (String.isBlank(languageValue)) {
            return null;
        }
        return languageValue.trim();
    }

    // Template lookup falls through language -> default language -> legacy folder so older org setups keep working.
    public static TemplateSelection resolveTemplate(String templateName, String resolvedLanguageFolder) {
        List<String> candidateFolders = new List<String>();
        if (!String.isBlank(resolvedLanguageFolder)) {
            candidateFolders.add(resolvedLanguageFolder);
        }

        String defaultLanguageFolder = getDefaultLanguageFolder();
        if (!String.isBlank(defaultLanguageFolder) && !candidateFolders.contains(defaultLanguageFolder)) {
            candidateFolders.add(defaultLanguageFolder);
        }

        String legacyFolder = getLegacyFolderName(templateName);
        if (!String.isBlank(legacyFolder) && !candidateFolders.contains(legacyFolder)) {
            candidateFolders.add(legacyFolder);
        }

        for (String folderName : candidateFolders) {
            String cacheKey = templateName + '|' + folderName;
            if (templateIdsByLookupKey.containsKey(cacheKey)) {
                TemplateSelection cachedSelection = new TemplateSelection();
                cachedSelection.templateId = templateIdsByLookupKey.get(cacheKey);
                cachedSelection.folderName = folderName;
                cachedSelection.templateName = templateName;
                if (cachedSelection.templateId != null) {
                    return cachedSelection;
                }
                continue;
            }

            List<EmailTemplate> templates = [
                SELECT Id
                FROM EmailTemplate
                WHERE Name = :templateName
                  AND Folder.Name = :folderName
                LIMIT 1
            ];
            templateIdsByLookupKey.put(cacheKey, templates.isEmpty() ? null : templates[0].Id);

            if (!templates.isEmpty()) {
                TemplateSelection selection = new TemplateSelection();
                selection.templateId = templates[0].Id;
                selection.folderName = folderName;
                selection.templateName = templateName;
                return selection;
            }
        }

        return null;
    }

    public static String getLegacyFolderName(String templateName) {
        if (templateName == REMINDER_TEMPLATE_NAME || templateName == ESCALATION_TEMPLATE_NAME) {
            return LEGACY_DISPUTE_REMINDER_FOLDER;
        }
        return LEGACY_DISPUTE_MANAGEMENT_FOLDER;
    }

    private static String getValidatedConfiguredFieldApi(String sourceObject) {
        sourceObject = normalizeSourceObject(sourceObject);
        String configuredField = getConfig() != null ? getConfig().Email_Language_Field_API_Name__c : null;
        if (String.isBlank(configuredField)) {
            return null;
        }

        //-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
        if (sourceObject == SOURCE_ACCOUNT) {
            return resolveFieldApi(configuredField, Account.SObjectType);
        }
        if (sourceObject == SOURCE_DISPUTE) {
            return resolveFieldApi(configuredField, celsrm__Dispute__c.SObjectType);
        }
        if (sourceObject == SOURCE_USER_MASTER) {
            return resolveFieldApi(configuredField, celsrm__User_Master__c.SObjectType);
        }
        return null;
        //-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
    }

    private static String getConfiguredSourceObject() {
        return normalizeSourceObject(getConfig() != null ? getConfig().Email_Language_Source_Object__c : null);
    }

    // Custom settings cannot use picklists here, so we normalize the text value into the supported options.
    private static String normalizeSourceObject(String sourceObject) {
        if (String.isBlank(sourceObject)) {
            return null;
        }

        String normalizedValue = sourceObject.trim().toLowerCase().replace('_', '').replace(' ', '');
        if (normalizedValue == 'account') {
            return SOURCE_ACCOUNT;
        }
        if (normalizedValue == 'dispute') {
            return SOURCE_DISPUTE;
        }
        if (normalizedValue == 'usermaster') {
            return SOURCE_USER_MASTER;
        }
        return sourceObject.trim();
    }

    private static String getDisputeAccountFieldValue(celsrm__Dispute__c disputeRecord, String fieldApi) {
        if (disputeRecord == null || String.isBlank(fieldApi) || disputeRecord.celsrm__Account__r == null) {
            return null;
        }
        return String.valueOf(disputeRecord.celsrm__Account__r.get(fieldApi));
    }

    private static String getDisputeUserMasterFieldValue(celsrm__Dispute__c disputeRecord, String fieldApi) {
        //-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
        if (disputeRecord == null || disputeRecord.celsrm__Resolver_User_Master__r == null) {
            return null;
        }

        SObject userMasterRel = disputeRecord.celsrm__Resolver_User_Master__r;
        if (!String.isBlank(fieldApi)) {
            return String.valueOf(userMasterRel.get(fieldApi));
        }

        if (isLanguageField(fieldApi)) {
            return String.valueOf(userMasterRel.get(getFullApiName(LANGUAGE_FIELD_NAME)));
        }

        return null;
    }

    //-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
    private static String getOwnerUserMasterFieldValue(
        User ownerUser,
        celsrm__User_Master__c ownerUserMaster,
        String fieldApi
    ) {
        if (!String.isBlank(fieldApi) && ownerUserMaster != null) {
            return String.valueOf(ownerUserMaster.get(fieldApi));
        }

        if (isLanguageField(fieldApi) && ownerUserMaster != null) {
            return ownerUserMaster.celsrm__Language__c;
        }

        if (isLanguageField(fieldApi) && ownerUser != null) {
            return String.valueOf(ownerUser.get('LanguageLabel'));
        }

        return null;
    }
    //-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
    //-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
    private static String getWorkflowDetailAccountFieldValue(
        celsrm__Dispute_Workflow_Details__c workflowDetail,
        String fieldApi
    ) {
        if (workflowDetail == null || String.isBlank(fieldApi) ||
            workflowDetail.celsrm__Dispute__r == null || workflowDetail.celsrm__Dispute__r.celsrm__Account__r == null) {
            return null;
        }
        return String.valueOf(workflowDetail.celsrm__Dispute__r.celsrm__Account__r.get(fieldApi));
    }

    private static String getWorkflowDetailDisputeFieldValue(
        celsrm__Dispute_Workflow_Details__c workflowDetail,
        String fieldApi
    ) {
        if (workflowDetail == null || String.isBlank(fieldApi) || workflowDetail.celsrm__Dispute__r == null) {
            return null;
        }
        return String.valueOf(workflowDetail.celsrm__Dispute__r.get(fieldApi));
    }
    //-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//

    private static String getWorkflowDetailUserMasterFieldValue(
        //-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
        celsrm__Dispute_Workflow_Details__c workflowDetail,
        //-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
        String fieldApi,
        Boolean escalationEmail
    ) {
        if (workflowDetail == null) {
            return null;
        }

        //-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
        SObject userMasterRel = workflowDetail.celsrm__User_Master__r;
        //-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
        if (!String.isBlank(fieldApi)) {
            //-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
            if (escalationEmail && userMasterRel != null) {
                SObject managerRel = userMasterRel.getSObject(getFullApiName('Manager__r'));
                if (managerRel != null) {
                    return String.valueOf(managerRel.get(fieldApi));
                }
            } else if (!escalationEmail && userMasterRel != null) {
                return String.valueOf(userMasterRel.get(fieldApi));
            //-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
            }
        }

        //-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
        if (isLanguageField(fieldApi)) {
        //-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
            if (escalationEmail) {
                //-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
                if (userMasterRel != null) {
                    SObject managerRel = userMasterRel.getSObject(getFullApiName('Manager__r'));
                    if (managerRel != null) {
                        return String.valueOf(managerRel.get(getFullApiName(LANGUAGE_FIELD_NAME)));
                    }
                //-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
                }
                //-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
                if (userMasterRel != null && userMasterRel.get(getFullApiName('User__c')) != null) {
                    return queryUserLanguage((Id) userMasterRel.get(getFullApiName('User__c')));
                //-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
                }
            //-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
            } else if (userMasterRel != null) {
                return String.valueOf(userMasterRel.get(getFullApiName(LANGUAGE_FIELD_NAME)));
            //-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
            }
        }

        return null;
    }

    private static String getFieldValue(SObject recordObject, String fieldApi) {
        if (recordObject == null || String.isBlank(fieldApi)) {
            return null;
        }
        return String.valueOf(recordObject.get(fieldApi));
    }

    //-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
    private static String resolveFieldApi(String configuredField, Schema.SObjectType sObjectType) {
        if (String.isBlank(configuredField) || sObjectType == null) {
            return null;
        }

        Map<String, Schema.SObjectField> fieldMap = sObjectType.getDescribe().fields.getMap();
        if (fieldMap.containsKey(configuredField)) {
            return configuredField;
        }

        String namespacedField = getFullApiName(configuredField);
        return fieldMap.containsKey(namespacedField) ? namespacedField : null;
    }

    private static Boolean isLanguageField(String fieldApi) {
        return String.isBlank(fieldApi)
            || fieldApi == LANGUAGE_FIELD_NAME
            || fieldApi == getFullApiName(LANGUAGE_FIELD_NAME);
    }

    private static String getFullApiName(String baseFieldApiName) {
        if (String.isBlank(baseFieldApiName)) {
            return null;
        }
        if (baseFieldApiName.startsWith(NAMESPACE_PREFIX)) {
            return baseFieldApiName;
        }
        return NAMESPACE_PREFIX + baseFieldApiName;
    //-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
    }

    private static String queryUserLanguage(Id userId) {
        //-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
        List<celsrm__User_Master__c> userMasters = [
            SELECT Id, celsrm__Language__c
            FROM celsrm__User_Master__c
            WHERE celsrm__User__c = :userId
            LIMIT 1
        ];
        if (!userMasters.isEmpty() && !String.isBlank(userMasters[0].celsrm__Language__c)) {
            return userMasters[0].celsrm__Language__c;
        }

        //-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
        //-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
        List<User> users = [
            SELECT toLabel(LanguageLocaleKey) LanguageLabel
            FROM User
            WHERE Id = :userId
            LIMIT 1
        ];
        //-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
        //-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
        return users.isEmpty() ? null : String.valueOf(users[0].get('LanguageLabel'));
        //-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
    }
    //-- End | FIN-9672 | Changed by Ravi | 05 May 2026 --//
}