//-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
/**
 * Generic workflow rule evaluation for dispute create-time resolver lookup.
 * Uses fieldMapping to connect rule criteria fields to UI input keys — no hardcoded field names.
 */
public without sharing class DisputeWorkflowRuleEvaluator {
    private static final String MATRIX_OBJECT_BASE = 'Dispute_Workflow_Matrix__c';
    private static final String CRITERIA_FIELD_BASE = 'Criteria__c';
    private static final String APPROVAL_MATRICES_FIELD_BASE = 'Approval_Matrices__c';
    private static final String ORDER_FIELD_BASE = 'Order__c';
    private static final String ACTIVE_FIELD_BASE = 'celsrm__Is_Active__c';

    public class RuleCriteria {
        public String fieldName;
        public String operator;
        public String value;
        public String fieldType;
    }

    public class ResolverLookupResult {
        public Boolean isSuccess;
        public Id relatedMatrixId;
        public String resolverId;
        public String resolverName;
        public Id resolverUserMasterId;
        public Boolean isExternalResolver;
        public Integer totalSLADays;

        public ResolverLookupResult(Boolean success) {
            isSuccess = success;
            isExternalResolver = false;
            totalSLADays = 0;
        }
    }

    /**
     * Evaluates a flat list of criteria (AND across rows).
     */
    public static Boolean evaluateWorkflowRule(
        Map<String, Object> inputValues,
        Map<String, String> fieldMapping,
        List<RuleCriteria> criteria
    ) {
        if (inputValues == null || fieldMapping == null || criteria == null || criteria.isEmpty()) {
            return false;
        }

        for (RuleCriteria criterion : criteria) {
            if (criterion == null || String.isBlank(criterion.fieldName) || String.isBlank(criterion.operator)) {
                return false;
            }

            String inputKey = resolveInputKey(fieldMapping, criterion.fieldName);
            if (String.isBlank(inputKey)) {
                return false;
            }

            Object actualValue = inputValues.get(inputKey);
            if (!matches(actualValue, criterion.operator, criterion.value, criterion.fieldType)) {
                return false;
            }
        }
        return true;
    }

    /**
     * Evaluates stored celsrm__Criteria__c JSON (including criteriaCondition) against UI input values.
     */
    public static Boolean evaluateWorkflowRuleJson(
        String criteriaJson,
        Map<String, Object> inputValues,
        Map<String, String> fieldMapping
    ) {
        if (String.isBlank(criteriaJson)) {
            return false;
        }

        Map<String, Object> payload = toStringObjectMap(JSON.deserializeUntyped(criteriaJson));
        List<Object> criteriaRows = toObjectList(payload.get('criteria'));
        if (criteriaRows.isEmpty()) {
            return false;
        }

        Map<Integer, Boolean> matchesByIndex = new Map<Integer, Boolean>();
        for (Integer i = 0; i < criteriaRows.size(); i++) {
            Map<String, Object> criteriaMap = toStringObjectMap(criteriaRows[i]);
            RuleCriteria criterion = new RuleCriteria();
            criterion.fieldName = criteriaMap.get('field') == null ? null : String.valueOf(criteriaMap.get('field'));
            criterion.operator = criteriaMap.get('operator') == null ? null : String.valueOf(criteriaMap.get('operator'));
            criterion.value = criteriaMap.get('value') == null ? null : String.valueOf(criteriaMap.get('value'));
            criterion.fieldType = criteriaMap.get('fieldType') == null ? null : String.valueOf(criteriaMap.get('fieldType'));
            matchesByIndex.put(
                i + 1,
                evaluateWorkflowRule(inputValues, fieldMapping, new List<RuleCriteria>{ criterion })
            );
        }

        String criteriaCondition = payload.get('criteriaCondition') == null
            ? null
            : String.valueOf(payload.get('criteriaCondition'));
        if (String.isBlank(criteriaCondition)) {
            for (Boolean isMatch : matchesByIndex.values()) {
                if (isMatch != true) {
                    return false;
                }
            }
            return true;
        }
        return evaluateCriteriaCondition(criteriaCondition, matchesByIndex);
    }

    /**
     * Matches an active workflow rule and resolves the Resolver from celsrm__Approval_Matrices__c JSON.
     * Criteria matching is delegated to celsrm.ApprovalMatrixEvaluator (same engine as credit approval).
     */
    public static ResolverLookupResult resolveResolverForCreate(
        Map<String, Object> inputValues,
        Map<String, String> fieldMapping
    ) {
        if (inputValues == null || inputValues.isEmpty() || fieldMapping == null || fieldMapping.isEmpty()) {
            return new ResolverLookupResult(false);
        }

        Map<String, Object> criteriaFieldValues = buildCriteriaFieldValues(inputValues, fieldMapping);
        if (criteriaFieldValues.isEmpty()) {
            return new ResolverLookupResult(false);
        }

        Id matrixId = celsrm.ApprovalMatrixEvaluator.getMatchingMatrixIdForFieldValues(
            MATRIX_OBJECT_BASE,
            'Dispute__c',
            criteriaFieldValues
        );
        if (matrixId == null) {
            return new ResolverLookupResult(false);
        }

        String matrixObjectApi = celsrm.ApprovalConfigController.getFullApiName(MATRIX_OBJECT_BASE);
        String matricesFieldApi = celsrm.ApprovalConfigController.getFullApiName(APPROVAL_MATRICES_FIELD_BASE);
        List<SObject> matrixRows = Database.query(
            'SELECT Id, ' + matricesFieldApi +
            ' FROM ' + matrixObjectApi +
            ' WHERE Id = :matrixId' +
            ' LIMIT 1'
        );
        if (matrixRows.isEmpty()) {
            return new ResolverLookupResult(false);
        }

        String approvalMatricesJson = String.valueOf(matrixRows[0].get(matricesFieldApi));
        ResolverLookupResult result = resolveResolverFromApprovalMatricesJson(matrixId, approvalMatricesJson);
        return result == null ? new ResolverLookupResult(false) : result;
    }

    /**
     * Maps UI input keys to celsrm__Dispute__c field API names for criteria evaluation.
     * Field mapping is defined by the caller — not hardcoded inside the evaluator.
     */
    private static Map<String, Object> buildCriteriaFieldValues(
        Map<String, Object> inputValues,
        Map<String, String> fieldMapping
    ) {
        Map<String, Object> criteriaFieldValues = new Map<String, Object>();
        for (String configFieldApi : fieldMapping.keySet()) {
            String inputKey = fieldMapping.get(configFieldApi);
            if (String.isBlank(inputKey) || !inputValues.containsKey(inputKey)) {
                continue;
            }
            Object rawValue = inputValues.get(inputKey);
            if (rawValue == null) {
                continue;
            }
            String fieldApi = celsrm.ApprovalConfigController.getFullApiName(configFieldApi);
            criteriaFieldValues.put(fieldApi, rawValue);
        }
        return criteriaFieldValues;
    }

    private static ResolverLookupResult resolveResolverFromApprovalMatricesJson(
        Id matrixId,
        String approvalMatricesJson
    ) {
        if (matrixId == null || String.isBlank(approvalMatricesJson)) {
            return new ResolverLookupResult(false);
        }

        Object rawPayload = JSON.deserializeUntyped(approvalMatricesJson);
        if (!(rawPayload instanceof List<Object>)) {
            return new ResolverLookupResult(false);
        }

        Map<String, Object> selectedResolverRow = null;
        Integer selectedLevel = null;
        Integer fallbackLevel = 0;

        for (Object rowObj : (List<Object>) rawPayload) {
            fallbackLevel++;
            if (!(rowObj instanceof Map<String, Object>)) {
                continue;
            }
            Map<String, Object> row = (Map<String, Object>) rowObj;
            if (row.containsKey('isActive') && !celsrm.ApprovalConfigController.getBooleanValue(row.get('isActive'))) {
                continue;
            }

            String userType = row.get('userType') == null ? null : String.valueOf(row.get('userType'));
            if (!isResolverRole(userType)) {
                continue;
            }

            Integer rowLevel = toInteger(row.get('level'));
            if (rowLevel == null) {
                rowLevel = toInteger(row.get('index'));
            }
            if (rowLevel == null) {
                rowLevel = fallbackLevel;
            }

            if (selectedResolverRow == null || rowLevel < selectedLevel) {
                selectedResolverRow = row;
                selectedLevel = rowLevel;
            }
        }

        if (selectedResolverRow == null) {
            return new ResolverLookupResult(false);
        }

        Id userMasterId = extractFirstApproverUserId(selectedResolverRow);
        if (userMasterId == null) {
            return new ResolverLookupResult(false);
        }

        return buildResolverFromUserMasterId(matrixId, userMasterId);
    }

    private static ResolverLookupResult buildResolverFromUserMasterId(Id matrixId, Id userMasterId) {
        List<celsrm__User_Master__c> userMasters = [
            SELECT Id, Name, celsrm__Email__c, celsrm__Is_External_User__c
            FROM celsrm__User_Master__c
            WHERE Id = :userMasterId
            LIMIT 1
        ];
        if (userMasters.isEmpty()) {
            return new ResolverLookupResult(false);
        }
        return buildResolverFromUserMasterRecord(matrixId, userMasters[0]);
    }

    private static ResolverLookupResult buildResolverFromUserMasterRecord(
        Id matrixId,
        celsrm__User_Master__c userMaster
    ) {
        ResolverLookupResult result = new ResolverLookupResult(true);
        result.relatedMatrixId = matrixId;
        result.resolverUserMasterId = userMaster.Id;
        result.resolverName = userMaster.Name;

        // Approval matrix JSON stores celsrm__User_Master__c Ids in approverUserIds — not Salesforce User Ids.
        if (userMaster.celsrm__Is_External_User__c == true && String.isNotBlank(userMaster.celsrm__Email__c)) {
            // result.resolverId = userMaster.celsrm__Email__c;
            // result.resolverName = userMaster.celsrm__Email__c;
            result.isExternalResolver = true;
            return result;
        }

        result.resolverId = String.valueOf(userMaster.Id);
        result.isExternalResolver = false;
        return result;
    }

    private static Id extractFirstApproverUserId(Map<String, Object> row) {
        List<Object> approverUserIds = row.get('approverUserIds') instanceof List<Object>
            ? (List<Object>) row.get('approverUserIds')
            : new List<Object>();
        if (approverUserIds.isEmpty() && row.get('approverUserId') != null) {
            approverUserIds.add(row.get('approverUserId'));
        }
        for (Object userIdObj : approverUserIds) {
            Id parsedId = tryParseId(userIdObj);
            if (parsedId != null) {
                return parsedId;
            }
        }
        return null;
    }

    private static String resolveInputKey(Map<String, String> fieldMapping, String fieldName) {
        if (String.isBlank(fieldName) || fieldMapping == null) {
            return null;
        }
        if (fieldMapping.containsKey(fieldName)) {
            return fieldMapping.get(fieldName);
        }

        String baseFieldApi = stripNamespaceFromFieldApi(fieldName);
        if (fieldMapping.containsKey(baseFieldApi)) {
            return fieldMapping.get(baseFieldApi);
        }

        String fullApiName = celsrm.ApprovalConfigController.getFullApiName(baseFieldApi);
        if (fieldMapping.containsKey(fullApiName)) {
            return fieldMapping.get(fullApiName);
        }

        for (String configField : fieldMapping.keySet()) {
            String configBaseField = stripNamespaceFromFieldApi(configField);
            if (configBaseField.equalsIgnoreCase(baseFieldApi) ||
                configField.equalsIgnoreCase(fieldName) ||
                configField.equalsIgnoreCase(fullApiName)) {
                return fieldMapping.get(configField);
            }
        }
        return null;
    }

    private static String stripNamespaceFromFieldApi(String fieldApi) {
        if (String.isBlank(fieldApi)) {
            return fieldApi;
        }
        String qualifiedPrefix = getPackageNamespacePrefix();
        if (String.isNotBlank(qualifiedPrefix) && fieldApi.startsWith(qualifiedPrefix)) {
            return fieldApi.substring(qualifiedPrefix.length());
        }
        return fieldApi;
    }

    private static String getPackageNamespacePrefix() {
        String className = celsrm.ApprovalConfigController.class.getName();
        if (!className.contains('.')) {
            return '';
        }
        return className.substring(0, className.indexOf('.')) + '__';
    }

    private static Boolean matches(
        Object actualValue,
        String operator,
        String criteriaValue,
        String fieldType
    ) {
        String normalizedOperator = operator == null ? '' : operator.trim().toUpperCase();
        if (normalizedOperator == '=' || normalizedOperator == 'EQUALS') {
            return compareEquals(actualValue, criteriaValue, fieldType);
        }
        if (normalizedOperator == '<>' || normalizedOperator == '!=' || normalizedOperator == 'NOT EQUALS') {
            return !compareEquals(actualValue, criteriaValue, fieldType);
        }
        if (normalizedOperator == 'CONTAINS' || normalizedOperator == 'LIKE') {
            return matchesLike(actualValue, criteriaValue);
        }
        if (normalizedOperator == 'NOT CONTAINS' || normalizedOperator == 'NOT LIKE') {
            return !matchesLike(actualValue, criteriaValue);
        }
        return false;
    }

    private static Boolean compareEquals(Object actualValue, String criteriaValue, String fieldType) {
        String actualString = actualValue == null ? '' : String.valueOf(actualValue).trim();
        String expectedString = criteriaValue == null ? '' : criteriaValue.trim();
        String normalizedType = fieldType == null ? '' : fieldType.trim().toUpperCase();
        if (String.isBlank(normalizedType) ||
            normalizedType == 'PICKLIST' ||
            normalizedType == 'STRING' ||
            normalizedType == 'TEXTAREA' ||
            normalizedType == 'PHONE' ||
            normalizedType == 'EMAIL' ||
            normalizedType == 'URL') {
            return actualString.equalsIgnoreCase(expectedString);
        }
        return actualString == expectedString;
    }

    private static Boolean matchesLike(Object actualValue, String criteriaValue) {
        if (actualValue == null || criteriaValue == null) {
            return false;
        }
        String actualString = String.valueOf(actualValue).trim().toLowerCase();
        String pattern = criteriaValue.trim().toLowerCase().replace('%', '');
        return actualString.contains(pattern);
    }

    private static Boolean isResolverRole(String userType) {
        return userType != null && userType.trim().toLowerCase() == 'resolver';
    }

    private static Boolean evaluateCriteriaCondition(
        String criteriaCondition,
        Map<Integer, Boolean> matchesByIndex
    ) {
        List<String> tokens = tokenizeCondition(criteriaCondition);
        return evaluateConditionTokens(tokens, 0, matchesByIndex).value;
    }

    private class ConditionResult {
        public Boolean value;
        public Integer nextIndex;
        public ConditionResult(Boolean value, Integer nextIndex) {
            this.value = value;
            this.nextIndex = nextIndex;
        }
    }

    private static ConditionResult evaluateConditionTokens(
        List<String> tokens,
        Integer startIndex,
        Map<Integer, Boolean> matchesByIndex
    ) {
        ConditionResult left = evaluateConditionTerm(tokens, startIndex, matchesByIndex);
        Integer index = left.nextIndex;
        while (index < tokens.size()) {
            String token = tokens[index].toUpperCase();
            if (token == 'AND') {
                ConditionResult right = evaluateConditionTerm(tokens, index + 1, matchesByIndex);
                left = new ConditionResult(left.value && right.value, right.nextIndex);
                index = right.nextIndex;
            } else if (token == 'OR') {
                ConditionResult right = evaluateConditionTerm(tokens, index + 1, matchesByIndex);
                left = new ConditionResult(left.value || right.value, right.nextIndex);
                index = right.nextIndex;
            } else {
                break;
            }
        }
        return left;
    }

    private static ConditionResult evaluateConditionTerm(
        List<String> tokens,
        Integer startIndex,
        Map<Integer, Boolean> matchesByIndex
    ) {
        if (startIndex >= tokens.size()) {
            return new ConditionResult(false, startIndex);
        }
        if (tokens[startIndex] == '(') {
            ConditionResult groupResult = evaluateConditionTokens(tokens, startIndex + 1, matchesByIndex);
            Integer nextIndex = groupResult.nextIndex;
            if (nextIndex < tokens.size() && tokens[nextIndex] == ')') {
                nextIndex++;
            }
            return new ConditionResult(groupResult.value, nextIndex);
        }
        Integer criterionIndex = Integer.valueOf(tokens[startIndex]);
        Boolean matchValue = matchesByIndex.containsKey(criterionIndex)
            ? matchesByIndex.get(criterionIndex)
            : false;
        return new ConditionResult(matchValue, startIndex + 1);
    }

    private static List<String> tokenizeCondition(String criteriaCondition) {
        List<String> tokens = new List<String>();
        if (String.isBlank(criteriaCondition)) {
            return tokens;
        }
        Matcher matcher = Pattern.compile('(\\d+)|(\\()|(\\))|(\\bAND\\b)|(\\bOR\\b)').matcher(criteriaCondition);
        while (matcher.find()) {
            if (matcher.group(1) != null) {
                tokens.add(matcher.group(1));
            } else if (matcher.group(2) != null) {
                tokens.add('(');
            } else if (matcher.group(3) != null) {
                tokens.add(')');
            } else if (matcher.group(4) != null) {
                tokens.add('AND');
            } else if (matcher.group(5) != null) {
                tokens.add('OR');
            }
        }
        return tokens;
    }

    private static Map<String, Object> toStringObjectMap(Object sourceValue) {
        if (sourceValue == null) {
            return new Map<String, Object>();
        }
        Object raw = JSON.deserializeUntyped(JSON.serialize(sourceValue));
        return raw instanceof Map<String, Object> ? (Map<String, Object>) raw : new Map<String, Object>();
    }

    private static List<Object> toObjectList(Object sourceValue) {
        return sourceValue instanceof List<Object> ? (List<Object>) sourceValue : new List<Object>();
    }

    private static Integer toInteger(Object rawValue) {
        Decimal parsed = celsrm.ApprovalConfigController.toDecimal(rawValue);
        return parsed == null ? null : parsed.intValue();
    }

    private static Id tryParseId(Object rawValue) {
        if (rawValue == null) {
            return null;
        }
        try {
            return (Id) String.valueOf(rawValue);
        } catch (Exception ex) {
            return null;
        }
    }
}
//-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//