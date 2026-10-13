public with sharing class DisputeEmailColumnConfigurationService {
    //-- Start | FIN-9672 | Changed by Ravi | 05 May 2026 --//
    @TestVisible
    private static Map<String, String> translatedLabelsOverrideByFieldApi;
    private static Map<String, List<ColumnDefinition>> localizedColumnsByCacheKey = new Map<String, List<ColumnDefinition>>();

    public class ColumnDefinition {
        public String label;
        public String fieldPath;
        public Boolean numeric;

        public ColumnDefinition(String labelValue, String fieldPathValue, Boolean numericValue) {
            label = labelValue;
            fieldPath = fieldPathValue;
            numeric = numericValue;
        }
    }

    private static final String DISPUTE_RELATIONSHIP_PREFIX = 'celsrm__Dispute__r.';
    private static final String TRANSLATED_LABEL_OBJECT_API = 'celsrm__Translated_Label__c';
    private static final String TRANSLATED_LABEL_FIELD_API = 'celsrm__Label__c';
    private static final String TRANSLATED_LANGUAGE_FIELD_API = 'celsrm__Language__c';
    private static final String TRANSLATED_OBJECT_FIELD_API = 'celsrm__Object_API_Name__c';
    private static final String TRANSLATED_OBJECT_API_NAME = 'celsrm__Dispute__c';

    private static final List<ColumnDefinition> LEGACY_DEFAULT_COLUMNS = new List<ColumnDefinition>{
        new ColumnDefinition('Dispute #', 'celsrm__Dispute__r.Name', false),
        new ColumnDefinition('Invoice #', 'celsrm__Dispute__r.celsrm__Transaction__r.Name', false),
        new ColumnDefinition('Dispute Created Date', 'CreatedDate', false),
        new ColumnDefinition('Due Date', 'celsrm__Dispute__r.celsrm__Transaction__r.celsrm__Due_Date__c', false),
        new ColumnDefinition('Invoice Amount', 'celsrm__Dispute__r.celsrm__Transaction__r.celsrm__Amount__c', true),
        new ColumnDefinition('Dispute Amount', 'celsrm__Dispute__r.celsrm__Amount__c', true),
        new ColumnDefinition('Dispute Type', 'celsrm__Dispute__r.celsrm__Dispute_Type__c', false),
        new ColumnDefinition('Reason Code', 'celsrm__Dispute__r.celsrm__Reason_Code__c', false),
        new ColumnDefinition('Customer #', 'celsrm__Dispute__r.celsrm__Account__r.AccountNumber', false),
        new ColumnDefinition('Customer Name', 'celsrm__Dispute__r.celsrm__Account__r.Name', false)
    };

    // Returns the semicolon-configured dispute columns in the admin-entered order.
    // Column selection is shared across languages, and direct dispute-field labels prefer translated-label records keyed by field API.
    // If admins leave the field blank, the batch keeps using the legacy 10-column layout for backward compatibility.
    public static List<ColumnDefinition> getColumnsForLanguage(
        String languageFolder,
        String notificationType,
        String defaultLanguageFolder
    ) {
        List<ColumnDefinition> configuredColumns = getConfiguredDisputeColumns();
        String cacheKey = buildLocalizedColumnsCacheKey(
            languageFolder,
            notificationType,
            defaultLanguageFolder,
            configuredColumns.isEmpty() ? 'LEGACY' : getConfiguredColumnFieldValue()
        );
        if (!localizedColumnsByCacheKey.containsKey(cacheKey)) {
            List<ColumnDefinition> baseColumns = configuredColumns.isEmpty() ? LEGACY_DEFAULT_COLUMNS : configuredColumns;
            Map<String, String> translatedLabelsByFieldApi = getTranslatedLabelsByFieldApi(
                baseColumns,
                languageFolder,
                defaultLanguageFolder
            );
            localizedColumnsByCacheKey.put(
                cacheKey,
                buildLocalizedColumns(baseColumns, translatedLabelsByFieldApi)
            );
        }
        return localizedColumnsByCacheKey.get(cacheKey);
    }

    // The batch query preloads every legacy and configured column path once so rendering stays dynamic without extra SOQL.
    public static Set<String> getAllSupportedQueryPaths() {
        Set<String> queryPaths = new Set<String>();
        for (ColumnDefinition column : LEGACY_DEFAULT_COLUMNS) {
            queryPaths.add(column.fieldPath);
        }

        for (ColumnDefinition column : getConfiguredDisputeColumns()) {
            if (isSupportedFieldPath(column.fieldPath)) {
                queryPaths.add(column.fieldPath);
            }
        }
        return queryPaths;
    }

    public static Boolean isSupportedFieldPath(String fieldPath) {
        if (String.isBlank(fieldPath)) {
            return false;
        }

        List<String> segments = fieldPath.trim().split('\\.');
        if (segments.size() == 1) {
            return fieldExists(celsrm__Dispute_Workflow_Details__c.SObjectType, segments[0]);
        }
        if (segments.size() == 2) {
            if (segments[0] == 'celsrm__User_Master__r') {
                return fieldExists(celsrm__User_Master__c.SObjectType, segments[1]);
            }
            if (segments[0] == 'celsrm__Dispute__r') {
                return fieldExists(celsrm__Dispute__c.SObjectType, segments[1]);
            }
            return false;
        }
        if (segments.size() == 3 && segments[0] == 'celsrm__Dispute__r') {
            if (segments[1] == 'celsrm__Transaction__r') {
                return fieldExists(celsrm__Transaction__c.SObjectType, segments[2]);
            }
            if (segments[1] == 'celsrm__Account__r') {
                return fieldExists(Account.SObjectType, segments[2]);
            }
        }
        return false;
    }

    public static Object resolveValue(celsrm__Dispute_Workflow_Details__c workflowDetail, String fieldPath) {
        if (workflowDetail == null || !isSupportedFieldPath(fieldPath)) {
            return null;
        }

        // Field paths are constrained to a few safe relationship shapes so admins can configure columns without arbitrary traversal.
        List<String> segments = fieldPath.trim().split('\\.');
        if (segments.size() == 1) {
            return workflowDetail.get(segments[0]);
        }
        if (segments.size() == 2) {
            SObject parentRecord;
            if (segments[0] == 'celsrm__User_Master__r') {
                parentRecord = workflowDetail.celsrm__User_Master__r;
            } else {
                parentRecord = workflowDetail.celsrm__Dispute__r;
            }
            return parentRecord == null ? null : parentRecord.get(segments[1]);
        }

        SObject disputeRecord = workflowDetail.celsrm__Dispute__r;
        if (disputeRecord == null) {
            return null;
        }
        SObject parentRecord = segments[1] == 'celsrm__Transaction__r'
            ? disputeRecord.getSObject('celsrm__Transaction__r')
            : disputeRecord.getSObject('celsrm__Account__r');
        return parentRecord == null ? null : parentRecord.get(segments[2]);
    }

    public static Boolean isNumericFieldPath(String fieldPath) {
        Schema.DisplayType displayType = getFieldDisplayType(fieldPath);
        return displayType == Schema.DisplayType.Currency ||
            displayType == Schema.DisplayType.Double ||
            displayType == Schema.DisplayType.Integer ||
            displayType == Schema.DisplayType.Long ||
            displayType == Schema.DisplayType.Percent;
    }

    // Admins now enter dispute field API names in a single semicolon-separated custom-setting field.
    // Base labels come from field describe metadata and can then be overridden by translated-label records keyed by dispute field API.
    private static List<ColumnDefinition> getConfiguredDisputeColumns() {
        String configuredColumns = getConfiguredColumnFieldValue();
        if (String.isBlank(configuredColumns)) {
            return new List<ColumnDefinition>();
        }

        List<ColumnDefinition> columns = new List<ColumnDefinition>();
        Set<String> seenFieldApis = new Set<String>();
        for (String configuredValue : configuredColumns.replace('\r', ';').replace('\n', ';').split(';')) {
            String disputeFieldApi = normalizeConfiguredDisputeFieldApi(configuredValue);
            if (String.isBlank(disputeFieldApi) || seenFieldApis.contains(disputeFieldApi)) {
                continue;
            }
            if (!fieldExists(celsrm__Dispute__c.SObjectType, disputeFieldApi)) {
                continue;
            }

            Schema.DescribeFieldResult fieldDescribe = getFieldDescribe(celsrm__Dispute__c.SObjectType, disputeFieldApi);
            columns.add(new ColumnDefinition(
                fieldDescribe.getLabel(),
                DISPUTE_RELATIONSHIP_PREFIX + disputeFieldApi,
                isNumericDisplayType(fieldDescribe.getType())
            ));
            seenFieldApis.add(disputeFieldApi);
        }
        return columns;
    }

    private static String getConfiguredColumnFieldValue() {
        celsrm__Dispute_Configuration__c disputeConfig = celsrm__Dispute_Configuration__c.getOrgDefaults();
        return disputeConfig != null ? disputeConfig.Reminder_Escalation_Email_Columns__c : null;
    }

    @TestVisible
    private static void setTranslatedLabelsOverride(Map<String, String> translatedLabels) {
        translatedLabelsOverrideByFieldApi = translatedLabels;
        localizedColumnsByCacheKey.clear();
    }

    private static String buildLocalizedColumnsCacheKey(
        String languageFolder,
        String notificationType,
        String defaultLanguageFolder,
        String configuredColumnsKey
    ) {
        return normalizeLookupValue(languageFolder) + '|' +
            normalizeLookupValue(notificationType) + '|' +
            normalizeLookupValue(defaultLanguageFolder) + '|' +
            normalizeLookupValue(configuredColumnsKey);
    }

    private static List<ColumnDefinition> buildLocalizedColumns(
        List<ColumnDefinition> baseColumns,
        Map<String, String> translatedLabelsByFieldApi
    ) {
        List<ColumnDefinition> localizedColumns = new List<ColumnDefinition>();
        for (ColumnDefinition baseColumn : baseColumns) {
            String disputeFieldApi = getTranslatableDisputeFieldApi(baseColumn);
            String translatedLabel = translatedLabelsByFieldApi.get(normalizeLookupValue(disputeFieldApi));
            localizedColumns.add(
                new ColumnDefinition(
                    String.isBlank(translatedLabel) ? baseColumn.label : translatedLabel,
                    baseColumn.fieldPath,
                    baseColumn.numeric
                )
            );
        }
        return localizedColumns;
    }

    private static Map<String, String> getTranslatedLabelsByFieldApi(
        List<ColumnDefinition> baseColumns,
        String languageFolder,
        String defaultLanguageFolder
    ) {
        if (translatedLabelsOverrideByFieldApi != null) {
            return normalizeTranslationMap(translatedLabelsOverrideByFieldApi);
        }

        Schema.SObjectType translatedLabelType = Schema.getGlobalDescribe().get(TRANSLATED_LABEL_OBJECT_API);
        if (translatedLabelType == null || baseColumns == null || baseColumns.isEmpty()) {
            return new Map<String, String>();
        }

        Map<String, Schema.SObjectField> translatedLabelFields = translatedLabelType.getDescribe().fields.getMap();
        if (!translatedLabelFields.containsKey(TRANSLATED_LABEL_FIELD_API) ||
            !translatedLabelFields.containsKey(TRANSLATED_LANGUAGE_FIELD_API) ||
            !translatedLabelFields.containsKey(TRANSLATED_OBJECT_FIELD_API)) {
            return new Map<String, String>();
        }

        Set<String> disputeFieldApis = new Set<String>();
        for (ColumnDefinition baseColumn : baseColumns) {
            String disputeFieldApi = getTranslatableDisputeFieldApi(baseColumn);
            if (!String.isBlank(disputeFieldApi)) {
                disputeFieldApis.add(disputeFieldApi);
            }
        }
        if (disputeFieldApis.isEmpty()) {
            return new Map<String, String>();
        }

        Set<String> candidateLanguageFolders = new Set<String>();
        if (!String.isBlank(languageFolder)) {
            candidateLanguageFolders.add(languageFolder.trim());
        }
        if (!String.isBlank(defaultLanguageFolder)) {
            candidateLanguageFolders.add(defaultLanguageFolder.trim());
        }
        if (candidateLanguageFolders.isEmpty()) {
            return new Map<String, String>();
        }

        String translatedObjectApiName = TRANSLATED_OBJECT_API_NAME;
        String query = 'SELECT Name, ' + TRANSLATED_LABEL_FIELD_API + ', ' + TRANSLATED_LANGUAGE_FIELD_API +
            ' FROM ' + TRANSLATED_LABEL_OBJECT_API +
            ' WHERE Name IN :disputeFieldApis' +
            ' AND ' + TRANSLATED_LABEL_FIELD_API + ' != null' +
            ' AND ' + TRANSLATED_OBJECT_FIELD_API + ' = :translatedObjectApiName' +
            ' AND ' + TRANSLATED_LANGUAGE_FIELD_API + ' IN :candidateLanguageFolders';
        List<SObject> translationRecords = Database.query(query);
        Map<String, String> translatedLabelsByFieldApi = new Map<String, String>();
        Map<String, Integer> bestScoreByFieldApi = new Map<String, Integer>();
        for (SObject translationRecord : translationRecords) {
            String disputeFieldApi = getStringFieldValue(translationRecord, 'Name');
            String translatedLabel = getStringFieldValue(translationRecord, TRANSLATED_LABEL_FIELD_API);
            if (String.isBlank(disputeFieldApi) || String.isBlank(translatedLabel)) {
                continue;
            }

            String normalizedFieldApi = normalizeLookupValue(disputeFieldApi);
            Integer matchScore = scoreTranslationRecord(translationRecord, languageFolder, defaultLanguageFolder);
            Integer currentScore = bestScoreByFieldApi.get(normalizedFieldApi);
            if (currentScore == null || matchScore > currentScore) {
                bestScoreByFieldApi.put(normalizedFieldApi, matchScore);
                translatedLabelsByFieldApi.put(normalizedFieldApi, translatedLabel.trim());
            }
        }
        return translatedLabelsByFieldApi;
    }

    private static Integer scoreTranslationRecord(
        SObject translationRecord,
        String languageFolder,
        String defaultLanguageFolder
    ) {
        Integer score = 0;
        String recordLanguageFolder = getStringFieldValue(translationRecord, TRANSLATED_LANGUAGE_FIELD_API);

        if (!String.isBlank(languageFolder) &&
            normalizeLookupValue(recordLanguageFolder) == normalizeLookupValue(languageFolder)) {
            score += 100;
        } else if (!String.isBlank(defaultLanguageFolder) &&
            normalizeLookupValue(recordLanguageFolder) == normalizeLookupValue(defaultLanguageFolder)) {
            score += 50;
        }

        return score;
    }

    private static String getStringFieldValue(SObject recordObject, String fieldApi) {
        if (recordObject == null || String.isBlank(fieldApi)) {
            return null;
        }
        Object fieldValue = recordObject.get(fieldApi);
        return fieldValue == null ? null : String.valueOf(fieldValue);
    }

    private static Map<String, String> normalizeTranslationMap(Map<String, String> translatedLabels) {
        Map<String, String> normalizedMap = new Map<String, String>();
        if (translatedLabels == null) {
            return normalizedMap;
        }

        for (String translationKey : translatedLabels.keySet()) {
            String translatedLabel = translatedLabels.get(translationKey);
            if (String.isBlank(translationKey) || String.isBlank(translatedLabel)) {
                continue;
            }
            normalizedMap.put(normalizeLookupValue(translationKey), translatedLabel.trim());
        }
        return normalizedMap;
    }

    private static String getTranslatableDisputeFieldApi(ColumnDefinition columnDefinition) {
        if (columnDefinition == null || String.isBlank(columnDefinition.fieldPath)) {
            return null;
        }

        String fieldPath = columnDefinition.fieldPath.trim();
        if (!fieldPath.startsWith(DISPUTE_RELATIONSHIP_PREFIX)) {
            return null;
        }

        String disputeFieldPath = fieldPath.substring(DISPUTE_RELATIONSHIP_PREFIX.length());
        return disputeFieldPath.contains('.') ? null : disputeFieldPath;
    }

    private static String normalizeLookupValue(String rawValue) {
        return String.isBlank(rawValue) ? '' : rawValue.trim().toLowerCase();
    }

    private static String normalizeConfiguredDisputeFieldApi(String configuredValue) {
        if (String.isBlank(configuredValue)) {
            return null;
        }

        String normalizedValue = configuredValue.trim();
        if (normalizedValue.startsWith(DISPUTE_RELATIONSHIP_PREFIX)) {
            normalizedValue = normalizedValue.substring(DISPUTE_RELATIONSHIP_PREFIX.length());
        }

        // Only direct dispute fields are supported in the semicolon config so labels/types can come from dispute metadata.
        return normalizedValue.contains('.') ? null : normalizedValue;
    }

    private static Schema.DisplayType getFieldDisplayType(String fieldPath) {
        if (!isSupportedFieldPath(fieldPath)) {
            return null;
        }

        List<String> segments = fieldPath.trim().split('\\.');
        if (segments.size() == 1) {
            return getFieldDescribe(celsrm__Dispute_Workflow_Details__c.SObjectType, segments[0]).getType();
        }
        if (segments.size() == 2) {
            return segments[0] == 'celsrm__User_Master__r'
                ? getFieldDescribe(celsrm__User_Master__c.SObjectType, segments[1]).getType()
                : getFieldDescribe(celsrm__Dispute__c.SObjectType, segments[1]).getType();
        }
        return segments[1] == 'celsrm__Transaction__r'
            ? getFieldDescribe(celsrm__Transaction__c.SObjectType, segments[2]).getType()
            : getFieldDescribe(Account.SObjectType, segments[2]).getType();
    }

    private static Boolean fieldExists(Schema.SObjectType sObjectType, String fieldName) {
        return sObjectType.getDescribe().fields.getMap().containsKey(fieldName);
    }

    private static Boolean isNumericDisplayType(Schema.DisplayType displayType) {
        return displayType == Schema.DisplayType.Currency ||
            displayType == Schema.DisplayType.Double ||
            displayType == Schema.DisplayType.Integer ||
            displayType == Schema.DisplayType.Long ||
            displayType == Schema.DisplayType.Percent;
    }

    private static Schema.DescribeFieldResult getFieldDescribe(Schema.SObjectType sObjectType, String fieldName) {
        return sObjectType.getDescribe().fields.getMap().get(fieldName).getDescribe();
    }
    //-- End | FIN-9672 | Changed by Ravi | 05 May 2026 --//
}