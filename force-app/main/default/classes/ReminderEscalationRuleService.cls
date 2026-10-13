public with sharing class ReminderEscalationRuleService {
    private static final String DISPUTE_OBJECT_BASE = 'Dispute__c';
    //-- Start | FIN-10143 | Changed by Asera | 20-Jul-2026 --//
    private static final String REMINDER_ESCALATION_MATRIX_OBJECT_API = 'celsrm__Dispute_Reminder_Escalation_Matrix__c';
    //-- End | FIN-10143 | Changed by Asera | 20-Jul-2026 --//
    private static final String ORDER_FIELD_BASE = 'Order__c';
    private static final String CRITERIA_FIELD_BASE = 'Criteria__c';
    private static final String FOLLOW_UP_CONFIG_FIELD_BASE = 'Follow_Up_Config__c';
    //-- Start | FIN-10143 | Changed by Asera | 20-Jul-2026 --//
    /*
    private static final String REMINDER_ESCALATION_MATRIX_OBJECT_BASE = 'Dispute_Reminder_Escalation_Matrix__c';
    private static final String LEGACY_USER_TYPE_FIELD_BASE = 'User_Type__c';
    private static final String LEGACY_REASON_CODE_FIELD_BASE = 'Reason_Code__c';
    private static final String LEGACY_DISPUTE_TYPE_FIELD_BASE = 'Dispute_Type__c';
    private static final String LEGACY_FOLLOW_UP_TYPE_FIELD_BASE = 'Follow_Up_Type__c';
    private static final String LEGACY_FOLLOW_UP_DAYS_FIELD_BASE = 'Follow_Up_Escalation_Days__c';
    private static final String LEGACY_FOLLOW_UP_LEVEL_FIELD_BASE = 'Follow_Up_Escalation_Level__c';
    */
    //-- End | FIN-10143 | Changed by Asera | 20-Jul-2026 --//
    private static final String LOGGED_IN_USER_RESOLVER_TYPE = 'Logged_In_User';

    public class FollowUpEntry {
        public String followUpType;
        public Decimal followUpDays;
        public Decimal followUpLevel;
    }

    private final String resolverType;
    private final List<celsrm__Dispute_Reminder_Escalation_Matrix__c> dynamicRules;
    //-- Start | FIN-10143 | Changed by Asera | 20-Jul-2026 --//
    /*
    private final Map<String, List<celsrm__Dispute_Reminder_Escalation_Matrix__c>> legacyMatrixMap;
    */
    //-- End | FIN-10143 | Changed by Asera | 20-Jul-2026 --//
    private final Set<String> disputeCriteriaFieldTokens;

    public ReminderEscalationRuleService(String resolverType) {
        this.resolverType = resolverType;
        this.dynamicRules = new List<celsrm__Dispute_Reminder_Escalation_Matrix__c>();
        //-- Start | FIN-10143 | Changed by Asera | 20-Jul-2026 --//
        /*
        this.legacyMatrixMap = new Map<String, List<celsrm__Dispute_Reminder_Escalation_Matrix__c>>();
        */
        //-- End | FIN-10143 | Changed by Asera | 20-Jul-2026 --//
        this.disputeCriteriaFieldTokens = new Set<String>();
        loadConfiguration();
    }

    public Set<String> getDisputeCriteriaFieldTokens() {
        return new Set<String>(disputeCriteriaFieldTokens);
    }

    public List<FollowUpEntry> getFollowUpEntries(celsrm__Dispute_Workflow_Details__c workflowDetails) {
        if (workflowDetails == null) {
            return new List<FollowUpEntry>();
        }

        SObject disputeRecord = buildDisputeRecordFromWorkflowDetail(workflowDetails);
        if (disputeRecord == null) {
            //-- Start | FIN-10143 | Changed by Asera | 20-Jul-2026 --//
            /*
            return getLegacyFollowUpEntries(workflowDetails);
            */
            //-- End | FIN-10143 | Changed by Asera | 20-Jul-2026 --//
            return new List<FollowUpEntry>();
        }

        String criteriaFieldApi = celsrm.ApprovalConfigController.getFullApiName(CRITERIA_FIELD_BASE);
        String followUpConfigFieldApi = celsrm.ApprovalConfigController.getFullApiName(FOLLOW_UP_CONFIG_FIELD_BASE);
        String disputeObjectApiName = celsrm.ApprovalConfigController.getFullApiName(DISPUTE_OBJECT_BASE);
        //-- Start | FIN-10143 | Changed by Asera | 20-Jul-2026 --//
        /*
        Boolean dynamicRuleMatched = false;
        */
        //-- End | FIN-10143 | Changed by Asera | 20-Jul-2026 --//

        for (celsrm__Dispute_Reminder_Escalation_Matrix__c rule : dynamicRules) {
            String criteriaJson = (String) rule.get(criteriaFieldApi);
            if (!celsrm.ApprovalMatrixEvaluator.matchesCriteriaForRecord(
                criteriaJson,
                disputeObjectApiName,
                disputeRecord
            )) {
                continue;
            }

            //-- Start | FIN-10143 | Changed by Asera | 20-Jul-2026 --//
            /*
            dynamicRuleMatched = true;
            */
            //-- End | FIN-10143 | Changed by Asera | 20-Jul-2026 --//
            String followUpConfigJson = (String) rule.get(followUpConfigFieldApi);
            List<FollowUpEntry> entries = buildFollowUpEntriesFromConfig(
                followUpConfigJson,
                workflowDetails.celsrm__Workflow_User_Type__c
            );
            if (!entries.isEmpty()) {
                return entries;
            }
        }

        //-- Start | FIN-10143 | Changed by Asera | 20-Jul-2026 --//
        /*
        if (dynamicRuleMatched) {
            return new List<FollowUpEntry>();
        }

        return getLegacyFollowUpEntries(workflowDetails);
        */
        //-- End | FIN-10143 | Changed by Asera | 20-Jul-2026 --//
        return new List<FollowUpEntry>();
    }

    private void loadConfiguration() {
        //-- Start | FIN-10143 | Changed by Asera | 20-Jul-2026 --//
        /*
        String matrixObjectApiName = celsrm.ApprovalConfigController.getFullApiName(REMINDER_ESCALATION_MATRIX_OBJECT_BASE);
        */
        String matrixObjectApiName = REMINDER_ESCALATION_MATRIX_OBJECT_API;
        //-- End | FIN-10143 | Changed by Asera | 20-Jul-2026 --//
        String orderFieldApi = celsrm.ApprovalConfigController.getFullApiName(ORDER_FIELD_BASE);
        String criteriaFieldApi = celsrm.ApprovalConfigController.getFullApiName(CRITERIA_FIELD_BASE);
        String followUpConfigFieldApi = celsrm.ApprovalConfigController.getFullApiName(FOLLOW_UP_CONFIG_FIELD_BASE);

        List<String> selectFields = new List<String>{
            'Id',
            'Name',
            'celsrm__Is_Active__c',
            orderFieldApi,
            criteriaFieldApi,
            followUpConfigFieldApi
        };
        //-- Start | FIN-10143 | Changed by Asera | 20-Jul-2026 --//
        /*
        selectFields.addAll(getAvailableLegacyFieldApis(matrixObjectApiName));
        */
        //-- End | FIN-10143 | Changed by Asera | 20-Jul-2026 --//

        List<celsrm__Dispute_Reminder_Escalation_Matrix__c> matrixList = Database.query(
            'SELECT ' + String.join(selectFields, ', ') +
            ' FROM ' + matrixObjectApiName +
            ' WHERE celsrm__Is_Active__c = true' +
            ' ORDER BY ' + orderFieldApi + ' ASC NULLS LAST'
        );

        for (celsrm__Dispute_Reminder_Escalation_Matrix__c matrix : matrixList) {
            String criteriaJson = (String) matrix.get(criteriaFieldApi);
            if (hasMatchableCriteria(criteriaJson)) {
                dynamicRules.add(matrix);
                disputeCriteriaFieldTokens.addAll(collectCriteriaFieldTokens(criteriaJson));
            }
            //-- Start | FIN-10143 | Changed by Asera | 20-Jul-2026 --//
            /*
            else {
                addLegacyMatrixRecord(matrix);
            }
            */
            //-- End | FIN-10143 | Changed by Asera | 20-Jul-2026 --//
        }
    }

    //-- Start | FIN-10143 | Changed by Asera | 20-Jul-2026 --//
    /*
    private List<FollowUpEntry> getLegacyFollowUpEntries(celsrm__Dispute_Workflow_Details__c workflowDetails) {
        List<celsrm__Dispute_Reminder_Escalation_Matrix__c> matchingList = getMatchingLegacyConfigRecords(
            workflowDetails.celsrm__Workflow_User_Type__c,
            workflowDetails.celsrm__Dispute__r != null ? workflowDetails.celsrm__Dispute__r.celsrm__Reason_Code__c : null,
            workflowDetails.celsrm__Dispute__r != null ? workflowDetails.celsrm__Dispute__r.celsrm__Dispute_Type__c : null
        );
        if (matchingList == null || matchingList.isEmpty()) {
            return new List<FollowUpEntry>();
        }

        List<FollowUpEntry> entries = new List<FollowUpEntry>();
        for (celsrm__Dispute_Reminder_Escalation_Matrix__c matrix : matchingList) {
            FollowUpEntry entry = buildFollowUpEntryFromLegacyMatrix(matrix);
            if (entry != null) {
                entries.add(entry);
            }
        }
        return entries;
    }

    private List<celsrm__Dispute_Reminder_Escalation_Matrix__c> getMatchingLegacyConfigRecords(
        String userType,
        String reason,
        String disputeType
    ) {
        String safeReason = reason == null ? '' : reason;
        String safeDisputeType = disputeType == null ? '' : disputeType;
        String safeUserType = userType == null ? '' : userType;
        List<String> priorityKeys = new List<String>();

        if (resolverType == LOGGED_IN_USER_RESOLVER_TYPE) {
            priorityKeys.add(safeReason + safeDisputeType);
            priorityKeys.add('*' + safeDisputeType);
            priorityKeys.add(safeReason + '*');
            priorityKeys.add('*' + '*');
        } else {
            priorityKeys.add(safeUserType + safeReason + safeDisputeType);
            priorityKeys.add(safeUserType + '*' + safeDisputeType);
            priorityKeys.add(safeUserType + safeReason + '*');
            priorityKeys.add(safeUserType + '*' + '*');
            priorityKeys.add('*' + safeReason + safeDisputeType);
            priorityKeys.add('*' + '*' + safeDisputeType);
            priorityKeys.add('*' + safeReason + '*');
            priorityKeys.add('*' + '*' + '*');
        }

        for (String key : priorityKeys) {
            if (legacyMatrixMap.containsKey(key)) {
                return legacyMatrixMap.get(key);
            }
        }
        return null;
    }

    private void addLegacyMatrixRecord(celsrm__Dispute_Reminder_Escalation_Matrix__c matrix) {
        String key;
        if (resolverType == LOGGED_IN_USER_RESOLVER_TYPE) {
            key = valueOrBlank(getLegacyFieldValue(matrix, LEGACY_REASON_CODE_FIELD_BASE))
                + valueOrBlank(getLegacyFieldValue(matrix, LEGACY_DISPUTE_TYPE_FIELD_BASE));
        } else {
            key = valueOrBlank(getLegacyFieldValue(matrix, LEGACY_USER_TYPE_FIELD_BASE))
                + valueOrBlank(getLegacyFieldValue(matrix, LEGACY_REASON_CODE_FIELD_BASE))
                + valueOrBlank(getLegacyFieldValue(matrix, LEGACY_DISPUTE_TYPE_FIELD_BASE));
        }
        if (!legacyMatrixMap.containsKey(key)) {
            legacyMatrixMap.put(key, new List<celsrm__Dispute_Reminder_Escalation_Matrix__c>());
        }
        legacyMatrixMap.get(key).add(matrix);
    }
    */
    //-- End | FIN-10143 | Changed by Asera | 20-Jul-2026 --//

    //-- Start | FIN-10143 | Changed by Asera | 20-Jul-2026 --//
    private List<FollowUpEntry> buildFollowUpEntriesFromConfig(
        String followUpConfigJson,
        String workflowUserType
    ) {
        List<Map<String, Object>> matrixRows = parseFollowUpConfigRows(followUpConfigJson);
        List<FollowUpEntry> entries = new List<FollowUpEntry>();
        Boolean enforceUserType = resolverType != LOGGED_IN_USER_RESOLVER_TYPE;

        for (Map<String, Object> matrixRow : matrixRows) {
            if (!isMatrixRowActive(matrixRow)) {
                continue;
            }
            if (enforceUserType && !userTypesMatch(workflowUserType, (String) matrixRow.get('userType'))) {
                continue;
            }
            FollowUpEntry entry = buildFollowUpEntryFromMatrixRow(matrixRow);
            if (entry != null) {
                entries.add(entry);
            }
        }
        return entries;
    }
    /*
    private List<FollowUpEntry> buildFollowUpEntriesFromConfig(
        String followUpConfigJson,
        celsrm__Dispute_Reminder_Escalation_Matrix__c legacyFallbackRecord,
        String workflowUserType
    ) {
        List<Map<String, Object>> matrixRows = parseFollowUpConfigRows(followUpConfigJson, legacyFallbackRecord);
        List<FollowUpEntry> entries = new List<FollowUpEntry>();
        Boolean enforceUserType = resolverType != LOGGED_IN_USER_RESOLVER_TYPE;

        for (Map<String, Object> matrixRow : matrixRows) {
            if (!isMatrixRowActive(matrixRow)) {
                continue;
            }
            if (enforceUserType && !userTypesMatch(workflowUserType, (String) matrixRow.get('userType'))) {
                continue;
            }
            FollowUpEntry entry = buildFollowUpEntryFromMatrixRow(matrixRow);
            if (entry != null) {
                entries.add(entry);
            }
        }
        return entries;
    }
    */
    //-- End | FIN-10143 | Changed by Asera | 20-Jul-2026 --//

    //-- Start | FIN-10143 | Changed by Asera | 20-Jul-2026 --//
    /*
    private FollowUpEntry buildFollowUpEntryFromLegacyMatrix(celsrm__Dispute_Reminder_Escalation_Matrix__c matrix) {
        if (matrix == null) {
            return null;
        }
        Map<String, Object> matrixRow = new Map<String, Object>{
            'followUpType' => getLegacyFieldValue(matrix, LEGACY_FOLLOW_UP_TYPE_FIELD_BASE),
            'followUpDays' => matrix.get(celsrm.ApprovalConfigController.getFullApiName(LEGACY_FOLLOW_UP_DAYS_FIELD_BASE)),
            'followUpLevel' => matrix.get(celsrm.ApprovalConfigController.getFullApiName(LEGACY_FOLLOW_UP_LEVEL_FIELD_BASE)),
            'isActive' => true
        };
        return buildFollowUpEntryFromMatrixRow(matrixRow);
    }
    */
    //-- End | FIN-10143 | Changed by Asera | 20-Jul-2026 --//

    private FollowUpEntry buildFollowUpEntryFromMatrixRow(Map<String, Object> matrixRow) {
        if (matrixRow == null) {
            return null;
        }
        Decimal followUpDays = celsrm.ApprovalConfigController.toDecimal(matrixRow.get('followUpDays'));
        if (followUpDays == null) {
            return null;
        }

        FollowUpEntry entry = new FollowUpEntry();
        entry.followUpType = normalizeFollowUpType((String) matrixRow.get('followUpType'));
        entry.followUpDays = followUpDays;
        entry.followUpLevel = celsrm.ApprovalConfigController.toDecimal(matrixRow.get('followUpLevel'));
        if (entry.followUpLevel == null || entry.followUpLevel <= 0) {
            entry.followUpLevel = 1;
        }
        return entry;
    }

    //-- Start | FIN-10143 | Changed by Asera | 20-Jul-2026 --//
    private List<Map<String, Object>> parseFollowUpConfigRows(String followUpConfigJson) {
        List<Map<String, Object>> rows = new List<Map<String, Object>>();
        if (!String.isBlank(followUpConfigJson)) {
            Object parsed = JSON.deserializeUntyped(followUpConfigJson);
            if (parsed instanceof List<Object>) {
                for (Object rowObj : (List<Object>) parsed) {
                    if (rowObj instanceof Map<String, Object>) {
                        rows.add((Map<String, Object>) rowObj);
                    } else if (rowObj instanceof Map<Object, Object>) {
                        rows.add(toStringObjectMap((Map<Object, Object>) rowObj));
                    }
                }
            } else if (parsed instanceof Map<String, Object>) {
                rows.add((Map<String, Object>) parsed);
            } else if (parsed instanceof Map<Object, Object>) {
                rows.add(toStringObjectMap((Map<Object, Object>) parsed));
            }
        }
        return rows;
    }
    /*
    private List<Map<String, Object>> parseFollowUpConfigRows(
        String followUpConfigJson,
        celsrm__Dispute_Reminder_Escalation_Matrix__c legacyFallbackRecord
    ) {
        List<Map<String, Object>> rows = new List<Map<String, Object>>();
        if (!String.isBlank(followUpConfigJson)) {
            Object parsed = JSON.deserializeUntyped(followUpConfigJson);
            if (parsed instanceof List<Object>) {
                for (Object rowObj : (List<Object>) parsed) {
                    if (rowObj instanceof Map<String, Object>) {
                        rows.add((Map<String, Object>) rowObj);
                    } else if (rowObj instanceof Map<Object, Object>) {
                        rows.add(toStringObjectMap((Map<Object, Object>) rowObj));
                    }
                }
            } else if (parsed instanceof Map<String, Object>) {
                rows.add((Map<String, Object>) parsed);
            } else if (parsed instanceof Map<Object, Object>) {
                rows.add(toStringObjectMap((Map<Object, Object>) parsed));
            }
        }

        if (rows.isEmpty() && legacyFallbackRecord != null) {
            rows.add(new Map<String, Object>{
                'followUpType' => getLegacyFieldValue(legacyFallbackRecord, LEGACY_FOLLOW_UP_TYPE_FIELD_BASE),
                'followUpDays' => legacyFallbackRecord.get(celsrm.ApprovalConfigController.getFullApiName(LEGACY_FOLLOW_UP_DAYS_FIELD_BASE)),
                'followUpLevel' => legacyFallbackRecord.get(celsrm.ApprovalConfigController.getFullApiName(LEGACY_FOLLOW_UP_LEVEL_FIELD_BASE)),
                'userType' => getLegacyFieldValue(legacyFallbackRecord, LEGACY_USER_TYPE_FIELD_BASE),
                'isActive' => true
            });
        }
        return rows;
    }
    */
    //-- End | FIN-10143 | Changed by Asera | 20-Jul-2026 --//

    private SObject buildDisputeRecordFromWorkflowDetail(celsrm__Dispute_Workflow_Details__c workflowDetails) {
        if (workflowDetails == null || workflowDetails.celsrm__Dispute__c == null) {
            return null;
        }

        String disputeObjectApiName = celsrm.ApprovalConfigController.getFullApiName(DISPUTE_OBJECT_BASE);
        Schema.SObjectType disputeType = Schema.getGlobalDescribe().get(disputeObjectApiName);
        if (disputeType == null) {
            return null;
        }

        SObject disputeRecord = disputeType.newSObject();
        disputeRecord.put('Id', workflowDetails.celsrm__Dispute__c);

        if (workflowDetails.celsrm__Dispute__r != null) {
            Map<String, Object> populatedDisputeFields = workflowDetails.celsrm__Dispute__r.getPopulatedFieldsAsMap();
            Map<String, Schema.SObjectField> fieldMap = disputeType.getDescribe().fields.getMap();
            for (String fieldToken : disputeCriteriaFieldTokens) {
                String fieldApi = celsrm.ApprovalConfigController.getFullApiName(fieldToken);
                if (String.isBlank(fieldApi) || !fieldMap.containsKey(fieldApi)) {
                    continue;
                }
                if (populatedDisputeFields.containsKey(fieldApi)) {
                    disputeRecord.put(fieldApi, populatedDisputeFields.get(fieldApi));
                }
            }
            for (String baselineFieldBase : new List<String>{
                'Dispute_Type__c',
                'Reason_Code__c',
                'Amount__c',
                'Status__c'
            }) {
                String baselineFieldApi = celsrm.ApprovalConfigController.getFullApiName(baselineFieldBase);
                if (fieldMap.containsKey(baselineFieldApi) && populatedDisputeFields.containsKey(baselineFieldApi)) {
                    disputeRecord.put(baselineFieldApi, populatedDisputeFields.get(baselineFieldApi));
                }
            }
        }
        return disputeRecord;
    }

    private Boolean hasMatchableCriteria(String criteriaJson) {
        if (String.isBlank(criteriaJson) || criteriaJson == 'null') {
            return false;
        }
        try {
            Map<String, Object> payload = toStringObjectMap(JSON.deserializeUntyped(criteriaJson));
            List<Object> criteriaRows = payload.get('criteria') instanceof List<Object>
                ? (List<Object>) payload.get('criteria')
                : new List<Object>();
            return !criteriaRows.isEmpty();
        } catch (Exception ex) {
            return false;
        }
    }

    private Set<String> collectCriteriaFieldTokens(String criteriaJson) {
        Set<String> fields = new Set<String>();
        if (String.isBlank(criteriaJson)) {
            return fields;
        }
        try {
            Map<String, Object> payload = toStringObjectMap(JSON.deserializeUntyped(criteriaJson));
            List<Object> criteriaRows = payload.get('criteria') instanceof List<Object>
                ? (List<Object>) payload.get('criteria')
                : new List<Object>();
            for (Object criteriaObj : criteriaRows) {
                Map<String, Object> criteriaMap = toStringObjectMap(criteriaObj);
                String fieldToken = criteriaMap.get('field') == null ? null : String.valueOf(criteriaMap.get('field'));
                if (!String.isBlank(fieldToken)) {
                    fields.add(fieldToken);
                }
            }
        } catch (Exception ex) {
            return fields;
        }
        return fields;
    }

    private Boolean isMatrixRowActive(Map<String, Object> matrixRow) {
        if (matrixRow == null || !matrixRow.containsKey('isActive')) {
            return true;
        }
        return celsrm.ApprovalConfigController.getBooleanValue(matrixRow.get('isActive'));
    }

    private Boolean userTypesMatch(String workflowUserType, String configuredUserType) {
        return normalizeUserType(workflowUserType) == normalizeUserType(configuredUserType);
    }

    private String normalizeUserType(String rawUserType) {
        String normalized = String.isBlank(rawUserType) ? '' : rawUserType.trim().toLowerCase();
        if (normalized == 'resolver') {
            return 'resolver';
        }
        if (normalized == 'approver') {
            return 'approver';
        }
        return normalized;
    }

    private String normalizeFollowUpType(String followUpType) {
        String normalized = String.isBlank(followUpType) ? 'followup' : followUpType.trim().toLowerCase();
        return normalized == 'escalation' ? 'escalation' : 'followup';
    }

    //-- Start | FIN-10143 | Changed by Asera | 20-Jul-2026 --//
    /*
    private String valueOrBlank(String rawValue) {
        return rawValue == null ? '' : rawValue;
    }

    private String getLegacyFieldValue(SObject matrixRecord, String fieldBase) {
        if (matrixRecord == null) {
            return null;
        }
        String fieldApi = celsrm.ApprovalConfigController.getFullApiName(fieldBase);
        return matrixRecord.get(fieldApi) == null ? null : String.valueOf(matrixRecord.get(fieldApi));
    }

    private List<String> getAvailableLegacyFieldApis(String matrixObjectApiName) {
        List<String> legacyFieldApis = new List<String>();
        Schema.SObjectType matrixType = Schema.getGlobalDescribe().get(matrixObjectApiName);
        if (matrixType == null) {
            return legacyFieldApis;
        }

        Map<String, Schema.SObjectField> fieldMap = matrixType.getDescribe().fields.getMap();
        for (String fieldBase : new List<String>{
            LEGACY_USER_TYPE_FIELD_BASE,
            LEGACY_REASON_CODE_FIELD_BASE,
            LEGACY_DISPUTE_TYPE_FIELD_BASE,
            LEGACY_FOLLOW_UP_TYPE_FIELD_BASE,
            LEGACY_FOLLOW_UP_DAYS_FIELD_BASE,
            LEGACY_FOLLOW_UP_LEVEL_FIELD_BASE
        }) {
            String fieldApi = celsrm.ApprovalConfigController.getFullApiName(fieldBase);
            if (!String.isBlank(fieldApi) && fieldMap.containsKey(fieldApi)) {
                legacyFieldApis.add(fieldApi);
            }
        }
        return legacyFieldApis;
    }
    */
    //-- End | FIN-10143 | Changed by Asera | 20-Jul-2026 --//

    private Map<String, Object> toStringObjectMap(Object rawValue) {
        if (rawValue == null) {
            return new Map<String, Object>();
        }
        if (rawValue instanceof Map<String, Object>) {
            return (Map<String, Object>) rawValue;
        }
        if (rawValue instanceof Map<Object, Object>) {
            return toStringObjectMap((Map<Object, Object>) rawValue);
        }
        return new Map<String, Object>();
    }

    private Map<String, Object> toStringObjectMap(Map<Object, Object> rawMap) {
        Map<String, Object> output = new Map<String, Object>();
        if (rawMap == null) {
            return output;
        }
        for (Object keyObj : rawMap.keySet()) {
            output.put(String.valueOf(keyObj), rawMap.get(keyObj));
        }
        return output;
    }
}