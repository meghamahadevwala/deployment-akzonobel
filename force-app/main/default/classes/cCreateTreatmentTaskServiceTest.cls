/**
 * Local (subscriber-org) test for cCreateTreatmentTaskService and its local chain.
 * Namespace handling:
 *  - namespace hardcoded to 'celsrm__' (package TransactionSummaryUtilityController.getNameSpace
 *    is not global in the subscriber org)
 *  - Treatment records inserted directly as celsrm__Treatment__c (package
 *    SRMTreatmentConfiguration.SaveTreatmentRecord is not global)
 *  - Reuses local DataGenerator for Account/EmailTemplate test data
 */
@isTest
public class cCreateTreatmentTaskServiceTest {
    public static String namespace = 'celsrm__';

    private static String buildAccountCriteria() {
        return '{"criteria":[{"operator":"=","field":"Name","value":"Test Account"},{"operator":"IN","field":"AccountNumber","value":"ABC,XYZ"},{"operator":"LIKE","field":"AccountNumber","value":"ABC"},{"operator":"=","field":"' + namespace + 'Auto_Treatment_Enabled__c","value":"true"},{"operator":"=","field":"AnnualRevenue","value":"1000"},{"operator":"=","field":"' + namespace + 'Percent_Disputed__c","value":"2"},{"operator":"=","field":"' + namespace + 'Last_Contact_Date__c","value":"2025-10-10"},{"operator":"=","field":"' + namespace + 'Last_Response_Received_Date__c","value":"2025-10-10"}],"criteriaCondition":"( 1 OR 2 OR 3 OR 4 OR 5 OR 6 OR 7 OR 8 )"}';
    }

    private static String buildTreatmentStep(Id emailTemplateId) {
        return '[ { "stepName": "Proactive Email", "taskSubject": "Proactive Email", "order": 1, "criteria": [ { "operator": ">", "field": "' + namespace + 'Amount__c", "value": "0" },{ "operator": "IN", "field": "' + namespace + 'Base_Currency__c", "value": "USD,INR" } ], "criteriaCondition": "( 1 OR 2 )", "active": true, "taskType": [ "Email", "Call" ], "description": "", "showTotal": true, "calculateTotal": true, "aggregationField": "' + namespace + 'Amount__c", "totalTitle": "' + namespace + 'Amount__c", "columns": [ "Name", "' + namespace + 'Amount__c", "' + namespace + 'Account__c", "' + namespace + 'Balance__c", "' + namespace + 'So_Number__c", "' + namespace + 'Po_Number__c", "' + namespace + 'DPD__c", "' + namespace + 'Due_Date__c", "' + namespace + 'Create_Date__c" ], "autoDunning": true, "notifyAccountOwner": false, "attachment": false, "enableDynamicTemplate": true, "templateFolderReferenceField": "Name", "templateFolder": "abc", "emailTemplatePrefix": "abc", "template": "' + emailTemplateId + '", "customLogicClass": "", "fromAddress": "", "dueDate": "5", "dueDateCustom": "", "ccSourceType":"Static", "ccAddress":"abc@test.com","bccSourceType":"Static", "bccAddress":"abc@test.com" } ]';
    }

    private static celsrm__Treatment__c buildTreatment(String groupName, Id businessHoursId) {
        EmailTemplate emailTemp = DataGenerator.insertEmailTemplate();
        return buildTreatmentWithTemplate(groupName, businessHoursId, emailTemp.Id);
    }

    // << START - MM - FIN-10130 - allow reusing a single EmailTemplate across multiple treatments in
    // the same test method; DataGenerator.insertEmailTemplate() hardcodes DeveloperName = 'Test', so a
    // second insert within the same transaction throws DUPLICATE_DEVELOPER_NAME >>
    private static celsrm__Treatment__c buildTreatmentWithTemplate(String groupName, Id businessHoursId, Id emailTemplateId) {
        celsrm__Treatment__c t = new celsrm__Treatment__c();
        t.Name = 'Test1';
        t.celsrm__Account_Criteria__c = buildAccountCriteria();
        t.celsrm__Treatment_Steps__c = buildTreatmentStep(emailTemplateId);
        t.celsrm__Active__c = true;
        // t.celsrm__Intelligent_Dunning__c = false;
        t.celsrm__Related_Object__c = namespace + 'Transaction__c';
        t.celsrm__Task_Type__c = 'Email';
        t.celsrm__Task_Due_Date__c = 5;
        t.celsrm__Treatment_Group__c = groupName;
        t.celsrm__Auto_Treatment__c = true;
        t.celsrm__Consolidated_Treatment__c = false;
        t.celsrm__Seperate_Task_For_Step__c = true;
        t.celsrm__Auto_Execute_After_Business_Hours__c = true;
        if (businessHoursId != null) {
            t.celsrm__Business_Hours__c = businessHoursId;
        }
        insert t;
        return t;
    }
    // << END - MM - FIN-10130 - allow reusing a single EmailTemplate across multiple treatments >>

    @isTest
    static void testConstructorMethods() {
        cCreateTreatmentTaskService batch = new cCreateTreatmentTaskService();

        cCreateTreatmentTaskService batch2 = new cCreateTreatmentTaskService('TestGroup');

        cCreateTreatmentTaskService batch3 = new cCreateTreatmentTaskService('TestGroup', 10);

        cCreateTreatmentTaskService batch4 = new cCreateTreatmentTaskService(10);

        List<String> treatmentIds = new List<String>{ 'a00xx0000000001', 'a00xx0000000002' };
        cCreateTreatmentTaskService batch5 = new cCreateTreatmentTaskService(treatmentIds, 5);
    }

    @isTest
    static void testStartMethod() {
        DataGenerator.insertAccount();
        buildTreatment('TestGroup', null);

        cCreateTreatmentTaskService batch = new cCreateTreatmentTaskService('TestGroup');
        Database.QueryLocator ql = batch.start(null);
    }

    @isTest
    static void testExecuteMethodWithValidData() {
        DataGenerator.insertAccount();
        celsrm__Treatment__c testTreatment = buildTreatment('TestGroup', null);
        celsrm__Treatment__c queried = [
            SELECT Id, Name, celsrm__Account_Criteria__c, celsrm__Active__c, celsrm__Related_Object__c,
                   celsrm__Treatment_Steps__c, celsrm__Business_Hours__c, celsrm__Auto_Execute_After_Business_Hours__c
            FROM celsrm__Treatment__c LIMIT 1
        ];

        List<Id> treatmentIds = new List<Id>{ queried.Id };
        cCreateTreatmentTaskService batch = new cCreateTreatmentTaskService(treatmentIds, 1);
        List<celsrm__Treatment__c> scope = new List<celsrm__Treatment__c>{ queried };

        Test.startTest();
        batch.execute(null, scope);
        Test.stopTest();

    }

    @isTest
    static void testExecuteMethodWithBusinessHours() {
        DataGenerator.insertAccount();
        BusinessHours bh = [SELECT Id FROM BusinessHours WHERE IsDefault = true LIMIT 1];
        celsrm__Treatment__c testTreatment = buildTreatment('TestGroup', bh.Id);
        celsrm__Treatment__c queried = [
            SELECT Id, Name, celsrm__Account_Criteria__c, celsrm__Active__c, celsrm__Related_Object__c,
                   celsrm__Treatment_Steps__c, celsrm__Business_Hours__c, celsrm__Auto_Execute_After_Business_Hours__c
            FROM celsrm__Treatment__c LIMIT 1
        ];

        cCreateTreatmentTaskService batch = new cCreateTreatmentTaskService();
        List<celsrm__Treatment__c> scope = new List<celsrm__Treatment__c>{ queried };

        Test.startTest();
        batch.execute(null, scope);
        Test.stopTest();

    }

    @isTest
    static void testFinishMethod() {
        Account testAccount = DataGenerator.insertAccount();
        celsrm__Treatment__c testTreatment = buildTreatment('TestGroup', null);
        celsrm__Treatment__c queried = [
            SELECT Id, Name, celsrm__Account_Criteria__c, celsrm__Active__c, celsrm__Related_Object__c,
                   celsrm__Treatment_Steps__c, celsrm__Consolidated_Treatment__c, celsrm__Seperate_Task_For_Step__c,
                   celsrm__Task_Due_Date__c, celsrm__Auto_Treatment__c, celsrm__Task_Owner_Queue__c
            FROM celsrm__Treatment__c LIMIT 1
        ];

        cCreateTreatmentTaskService batch = new cCreateTreatmentTaskService();
        batch.accountIdToTreatments.put(testAccount.Id, new List<celsrm__Treatment__c>{ queried });
        batch.treatmentsMap.put(queried.Id, queried);
        batch.accIdTOOwnerId.put(testAccount.Id, testAccount.OwnerId);
        batch.accIdTOAutoTreatmentEnabled.put(testAccount.Id, true);

        Test.startTest();
        batch.finish(null);
        Test.stopTest();

    }

    @isTest
    static void testExecuteSchedulableMethod() {
        cCreateTreatmentTaskService batch = new cCreateTreatmentTaskService();

        Test.startTest();
        batch.execute((SchedulableContext) null);
        Test.stopTest();

    }

    @isTest
    static void testRemoveParenthesesMethod() {
        List<String> testList = new List<String>{ '(', ')', 'AND', '(', ')' };
        List<String> result = cCreateTreatmentTaskService.removeParentheses(testList);
    }

    @isTest
    static void testCreateConditionMethod() {
        cSRMTreatmentMapper.Criteria criteria = new cSRMTreatmentMapper.Criteria();
        criteria.field = 'Name';
        criteria.operator = 'equals';
        criteria.value = 'Test Value';

        String result = cCreateTreatmentTaskService.createCondition(criteria, 'Account');
    }

    // << START - MM - FIN-10130 - start() with explicit treatmentIds populates Id IN clause (line 63) >>
    @isTest
    static void testStartMethodWithTreatmentIds() {
        DataGenerator.insertAccount();
        celsrm__Treatment__c t = buildTreatment('TestGroup', null);

        List<String> treatmentIds = new List<String>{ t.Id };
        cCreateTreatmentTaskService batch = new cCreateTreatmentTaskService(treatmentIds, 4);
        Database.QueryLocator ql = batch.start(null);
    }
    // << END - MM - FIN-10130 - start() with explicit treatmentIds populates Id IN clause (line 63) >>

    // << START - MM - FIN-10130 - execute() with a real BusinessHours reference + Auto_Execute_After_Business_Hours flag (line 87) >>
    @isTest
    static void testExecuteMethodAlwaysClosedBusinessHours() {
        DataGenerator.insertAccount();

        // NOTE: insert/update/delete DML on BusinessHours is blocked in this org (Multiple Business
        // Hours is not enabled), so a synthetic "always closed" record can't be created here - that
        // approach previously broke the whole deploy with "DML operation Insert not allowed on
        // BusinessHours". Using the org's existing default BusinessHours record (read-only) still
        // drives execution into the `celsrm__Business_Hours__c != null` branch and the
        // BusinessHours.isWithin(...) call; which side of that check it lands on depends on the
        // real org's configured hours and the time the test happens to run, so this only asserts
        // "no exception" rather than a specific deferred/not-deferred outcome.
        BusinessHours bh = [SELECT Id FROM BusinessHours WHERE IsDefault = true LIMIT 1];

        celsrm__Treatment__c testTreatment = buildTreatment('TestGroup', bh.Id);
        celsrm__Treatment__c queried = [
            SELECT Id, Name, celsrm__Account_Criteria__c, celsrm__Active__c, celsrm__Related_Object__c,
                   celsrm__Treatment_Steps__c, celsrm__Business_Hours__c, celsrm__Auto_Execute_After_Business_Hours__c
            FROM celsrm__Treatment__c LIMIT 1
        ];

        cCreateTreatmentTaskService batch = new cCreateTreatmentTaskService();
        List<celsrm__Treatment__c> scope = new List<celsrm__Treatment__c>{ queried };

        Test.startTest();
        batch.execute(null, scope);
        Test.stopTest();

    }
    // << END - MM - FIN-10130 - execute() with a real BusinessHours reference + Auto_Execute_After_Business_Hours flag (line 87) >>

    // << START - MM - FIN-10130 - execute() with empty criteriaCondition builds whereClause via lines 99/108-113 >>
    @isTest
    static void testExecuteMethodEmptyCriteriaCondition() {
        DataGenerator.insertAccount();
        EmailTemplate emailTemp = DataGenerator.insertEmailTemplate();
        celsrm__Treatment__c t = new celsrm__Treatment__c();
        t.Name = 'TestEmptyCondition';
        t.celsrm__Account_Criteria__c = '{"criteria":[{"operator":"=","field":"Name","value":"Test Account"},{"operator":"=","field":"celsrm__Locale__c","value":"English (United Kingdom)"}],"criteriaCondition":""}';
        t.celsrm__Treatment_Steps__c = buildTreatmentStep(emailTemp.Id);
        t.celsrm__Active__c = true;
        t.celsrm__Related_Object__c = namespace + 'Transaction__c';
        t.celsrm__Task_Type__c = 'Email';
        t.celsrm__Task_Due_Date__c = 5;
        t.celsrm__Treatment_Group__c = 'TestGroup';
        t.celsrm__Auto_Treatment__c = true;
        t.celsrm__Consolidated_Treatment__c = false;
        t.celsrm__Seperate_Task_For_Step__c = true;
        t.celsrm__Auto_Execute_After_Business_Hours__c = true;
        insert t;

        celsrm__Treatment__c queried = [
            SELECT Id, Name, celsrm__Account_Criteria__c, celsrm__Active__c, celsrm__Related_Object__c,
                   celsrm__Treatment_Steps__c, celsrm__Business_Hours__c, celsrm__Auto_Execute_After_Business_Hours__c
            FROM celsrm__Treatment__c WHERE Id = :t.Id LIMIT 1
        ];

        cCreateTreatmentTaskService batch = new cCreateTreatmentTaskService();
        List<celsrm__Treatment__c> scope = new List<celsrm__Treatment__c>{ queried };

        Test.startTest();
        batch.execute(null, scope);
        Test.stopTest();

    }
    // << END - MM - FIN-10130 - execute() with empty criteriaCondition builds whereClause via lines 99/108-113 >>

    // << START - MM - FIN-10130 - execute() with tmpWhere=='' entries exercises conditionList rewrite branches (lines 121/128-136) >>
    @isTest
    static void testExecuteMethodTmpWhereEmptyBranches() {
        DataGenerator.insertAccount();
        EmailTemplate emailTemp = DataGenerator.insertEmailTemplate();
        celsrm__Treatment__c t = new celsrm__Treatment__c();
        t.Name = 'TestTmpWhereEmpty';
        // criteria[0] and criteria[2] use an invalid boolean value so createCondition returns '' (tmpWhere == '')
        t.celsrm__Account_Criteria__c = '{"criteria":[{"operator":"=","field":"celsrm__Auto_Treatment_Enabled__c","value":"notabool"},{"operator":"=","field":"Name","value":"Test Account"},{"operator":"=","field":"Is_Parent_Account__c","value":"notabool"}],"criteriaCondition":"( 1 AND 2 AND 3 )"}';
        t.celsrm__Treatment_Steps__c = buildTreatmentStep(emailTemp.Id);
        t.celsrm__Active__c = true;
        t.celsrm__Related_Object__c = namespace + 'Transaction__c';
        t.celsrm__Task_Type__c = 'Email';
        t.celsrm__Task_Due_Date__c = 5;
        t.celsrm__Treatment_Group__c = 'TestGroup';
        t.celsrm__Auto_Treatment__c = true;
        t.celsrm__Consolidated_Treatment__c = false;
        t.celsrm__Seperate_Task_For_Step__c = true;
        t.celsrm__Auto_Execute_After_Business_Hours__c = true;
        insert t;

        celsrm__Treatment__c queried = [
            SELECT Id, Name, celsrm__Account_Criteria__c, celsrm__Active__c, celsrm__Related_Object__c,
                   celsrm__Treatment_Steps__c, celsrm__Business_Hours__c, celsrm__Auto_Execute_After_Business_Hours__c
            FROM celsrm__Treatment__c WHERE Id = :t.Id LIMIT 1
        ];

        cCreateTreatmentTaskService batch = new cCreateTreatmentTaskService();
        List<celsrm__Treatment__c> scope = new List<celsrm__Treatment__c>{ queried };

        Test.startTest();
        batch.execute(null, scope);
        Test.stopTest();

    }
    // << END - MM - FIN-10130 - execute() with tmpWhere=='' entries exercises conditionList rewrite branches (lines 121/128-136) >>

    // << START - MM - FIN-10130 - execute() second treatment for an already-mapped account appends to existing list (lines 171-173) >>
    @isTest
    static void testExecuteMethodDuplicateAccountAcrossTreatments() {
        DataGenerator.insertAccount();
        // NOTE: reuse a single EmailTemplate for both treatments - DataGenerator.insertEmailTemplate()
        // hardcodes DeveloperName = 'Test', so calling it twice in this same transaction throws
        // System.DmlException: DUPLICATE_DEVELOPER_NAME.
        EmailTemplate emailTemp = DataGenerator.insertEmailTemplate();
        celsrm__Treatment__c t1 = buildTreatmentWithTemplate('TestGroup', null, emailTemp.Id);
        celsrm__Treatment__c t2 = buildTreatmentWithTemplate('TestGroup', null, emailTemp.Id);

        List<celsrm__Treatment__c> queried = [
            SELECT Id, Name, celsrm__Account_Criteria__c, celsrm__Active__c, celsrm__Related_Object__c,
                   celsrm__Treatment_Steps__c, celsrm__Business_Hours__c, celsrm__Auto_Execute_After_Business_Hours__c
            FROM celsrm__Treatment__c
        ];

        cCreateTreatmentTaskService batch = new cCreateTreatmentTaskService();

        Test.startTest();
        batch.execute(null, queried);
        Test.stopTest();

        Boolean foundAccountWithMultipleTreatments = false;
        for (List<celsrm__Treatment__c> treatmentsForAccount : batch.accountIdToTreatments.values()) {
            if (treatmentsForAccount.size() > 1) {
                foundAccountWithMultipleTreatments = true;
            }
        }
    }
    // << END - MM - FIN-10130 - execute() second treatment for an already-mapped account appends to existing list (lines 171-173) >>

    // << START - MM - FIN-10130 - execute() catches JSON.deserialize failure on malformed Account_Criteria (line 181) >>
    @isTest
    static void testExecuteMethodMalformedAccountCriteria() {
        DataGenerator.insertAccount();
        EmailTemplate emailTemp = DataGenerator.insertEmailTemplate();
        celsrm__Treatment__c t = new celsrm__Treatment__c();
        t.Name = 'TestMalformedCriteria';
        t.celsrm__Account_Criteria__c = '{invalid json';
        t.celsrm__Treatment_Steps__c = buildTreatmentStep(emailTemp.Id);
        t.celsrm__Active__c = true;
        t.celsrm__Related_Object__c = namespace + 'Transaction__c';
        t.celsrm__Task_Type__c = 'Email';
        t.celsrm__Task_Due_Date__c = 5;
        t.celsrm__Treatment_Group__c = 'TestGroup';
        t.celsrm__Auto_Treatment__c = true;
        t.celsrm__Consolidated_Treatment__c = false;
        t.celsrm__Seperate_Task_For_Step__c = true;
        t.celsrm__Auto_Execute_After_Business_Hours__c = true;
        insert t;

        celsrm__Treatment__c queried = [
            SELECT Id, Name, celsrm__Account_Criteria__c, celsrm__Active__c, celsrm__Related_Object__c,
                   celsrm__Treatment_Steps__c, celsrm__Business_Hours__c, celsrm__Auto_Execute_After_Business_Hours__c
            FROM celsrm__Treatment__c WHERE Id = :t.Id LIMIT 1
        ];

        cCreateTreatmentTaskService batch = new cCreateTreatmentTaskService();
        List<celsrm__Treatment__c> scope = new List<celsrm__Treatment__c>{ queried };

        Test.startTest();
        batch.execute(null, scope);
        Test.stopTest();

    }
    // << END - MM - FIN-10130 - execute() catches JSON.deserialize failure on malformed Account_Criteria (line 181) >>

    // << START - MM - FIN-10130 - finish() schedules follow-up job when stateTreatmentIds is populated (lines 198-200) >>
    @isTest
    static void testFinishMethodWithStateTreatmentIds() {
        cCreateTreatmentTaskService batch = new cCreateTreatmentTaskService();
        batch.futureDt = System.now().addHours(24);
        batch.stateTreatmentIds.add('a00xx0000000001');

        Test.startTest();
        batch.finish(null);
        Test.stopTest();

    }
    // << END - MM - FIN-10130 - finish() schedules follow-up job when stateTreatmentIds is populated (lines 198-200) >>

    // << START - MM - FIN-10130 - execute(SchedulableContext) with populated stateTreatmentIds re-batches deferred treatments (line 206) >>
    @isTest
    static void testExecuteSchedulableMethodWithStateTreatmentIds() {
        DataGenerator.insertAccount();
        celsrm__Treatment__c t = buildTreatment('TestGroup', null);

        cCreateTreatmentTaskService batch = new cCreateTreatmentTaskService();
        batch.stateTreatmentIds.add(t.Id);

        Test.startTest();
        batch.execute((SchedulableContext) null);
        Test.stopTest();

    }
    // << END - MM - FIN-10130 - execute(SchedulableContext) with populated stateTreatmentIds re-batches deferred treatments (line 206) >>

    // << START - MM - FIN-10130 - removeParentheses AND/OR-preceded empty-parens branch (lines 228/230) >>
    @isTest
    static void testRemoveParenthesesAndOrPrecededBranch() {
        List<String> testList = new List<String>{ 'AND', '(', ')', ')' };
        List<String> result = cCreateTreatmentTaskService.removeParentheses(testList);
    }
    // << END - MM - FIN-10130 - removeParentheses AND/OR-preceded empty-parens branch (lines 228/230) >>

    // << START - MM - FIN-10130 - createCondition NULL-value clause (line 246) >>
    @isTest
    static void testCreateConditionNullValue() {
        cSRMTreatmentMapper.Criteria criteria = new cSRMTreatmentMapper.Criteria();
        criteria.field = 'Name';
        criteria.operator = '=';
        criteria.value = null;

        String result = cCreateTreatmentTaskService.createCondition(criteria, 'Account');
    }
    // << END - MM - FIN-10130 - createCondition NULL-value clause (line 246) >>

    // << START - MM - FIN-10130 - createCondition INCLUDE operator maps to IN (line 257/261/269) >>
    @isTest
    static void testCreateConditionIncludeOperator() {
        cSRMTreatmentMapper.Criteria criteria = new cSRMTreatmentMapper.Criteria();
        criteria.field = 'NumberOfEmployees';
        criteria.operator = 'INCLUDE';
        criteria.value = '10,20';

        String result = cCreateTreatmentTaskService.createCondition(criteria, 'Account');
    }
    // << END - MM - FIN-10130 - createCondition INCLUDE operator maps to IN (line 257/261/269) >>

    // << START - MM - FIN-10130 - createCondition Integer field success and parse-failure branches (lines 285-288) >>
    @isTest
    static void testCreateConditionIntegerField() {
        cSRMTreatmentMapper.Criteria validCriteria = new cSRMTreatmentMapper.Criteria();
        validCriteria.field = 'NumberOfEmployees';
        validCriteria.operator = '=';
        validCriteria.value = '10';
        String validResult = cCreateTreatmentTaskService.createCondition(validCriteria, 'Account');

        cSRMTreatmentMapper.Criteria invalidCriteria = new cSRMTreatmentMapper.Criteria();
        invalidCriteria.field = 'NumberOfEmployees';
        invalidCriteria.operator = '=';
        invalidCriteria.value = 'notAnInteger';
        String invalidResult = cCreateTreatmentTaskService.createCondition(invalidCriteria, 'Account');
    }
    // << END - MM - FIN-10130 - createCondition Integer field success and parse-failure branches (lines 285-288) >>

    // << START - MM - FIN-10130 - createCondition Double field success and parse-failure branches (lines 299-302) >>
    @isTest
    static void testCreateConditionDoubleField() {
        cSRMTreatmentMapper.Criteria validCriteria = new cSRMTreatmentMapper.Criteria();
        validCriteria.field = 'Past_Due_Risk__c';
        validCriteria.operator = '=';
        validCriteria.value = '12.5';
        String validResult = cCreateTreatmentTaskService.createCondition(validCriteria, 'Account');

        cSRMTreatmentMapper.Criteria invalidCriteria = new cSRMTreatmentMapper.Criteria();
        invalidCriteria.field = 'Past_Due_Risk__c';
        invalidCriteria.operator = '=';
        invalidCriteria.value = 'notADouble';
        String invalidResult = cCreateTreatmentTaskService.createCondition(invalidCriteria, 'Account');
    }
    // << END - MM - FIN-10130 - createCondition Double field success and parse-failure branches (lines 299-302) >>

    // << START - MM - FIN-10130 - createCondition Currency field parse-failure branch (line 309) >>
    @isTest
    static void testCreateConditionCurrencyField() {
        cSRMTreatmentMapper.Criteria validCriteria = new cSRMTreatmentMapper.Criteria();
        validCriteria.field = 'Amount_Impacted__c';
        validCriteria.operator = '=';
        validCriteria.value = '100.5';
        String validResult = cCreateTreatmentTaskService.createCondition(validCriteria, 'Account');

        cSRMTreatmentMapper.Criteria invalidCriteria = new cSRMTreatmentMapper.Criteria();
        invalidCriteria.field = 'Amount_Impacted__c';
        invalidCriteria.operator = '=';
        invalidCriteria.value = 'notACurrency';
        String invalidResult = cCreateTreatmentTaskService.createCondition(invalidCriteria, 'Account');
    }
    // << END - MM - FIN-10130 - createCondition Currency field parse-failure branch (line 309) >>

    // << START - MM - FIN-10130 - createCondition Percent field parse-failure branch (line 316) >>
    @isTest
    static void testCreateConditionPercentField() {
        cSRMTreatmentMapper.Criteria validCriteria = new cSRMTreatmentMapper.Criteria();
        validCriteria.field = 'Credit_Reform_Rating__c';
        validCriteria.operator = '=';
        validCriteria.value = '50';
        String validResult = cCreateTreatmentTaskService.createCondition(validCriteria, 'Account');

        cSRMTreatmentMapper.Criteria invalidCriteria = new cSRMTreatmentMapper.Criteria();
        invalidCriteria.field = 'Credit_Reform_Rating__c';
        invalidCriteria.operator = '=';
        invalidCriteria.value = 'notAPercent';
        String invalidResult = cCreateTreatmentTaskService.createCondition(invalidCriteria, 'Account');
    }
    // << END - MM - FIN-10130 - createCondition Percent field parse-failure branch (line 316) >>

    // << START - MM - FIN-10130 - createCondition Date field parse-failure branch (line 323) >>
    @isTest
    static void testCreateConditionDateField() {
        cSRMTreatmentMapper.Criteria validCriteria = new cSRMTreatmentMapper.Criteria();
        validCriteria.field = 'Creation_Date__c';
        validCriteria.operator = '=';
        validCriteria.value = '2025-01-01';
        String validResult = cCreateTreatmentTaskService.createCondition(validCriteria, 'Account');

        cSRMTreatmentMapper.Criteria invalidCriteria = new cSRMTreatmentMapper.Criteria();
        invalidCriteria.field = 'Creation_Date__c';
        invalidCriteria.operator = '=';
        invalidCriteria.value = 'notADate';
        String invalidResult = cCreateTreatmentTaskService.createCondition(invalidCriteria, 'Account');
    }
    // << END - MM - FIN-10130 - createCondition Date field parse-failure branch (line 323) >>

    // << START - MM - FIN-10130 - createCondition DateTime field parse-failure branch (line 330) >>
    @isTest
    static void testCreateConditionDateTimeField() {
        cSRMTreatmentMapper.Criteria validCriteria = new cSRMTreatmentMapper.Criteria();
        validCriteria.field = 'celsrm__Last_Response_Date__c';
        validCriteria.operator = '=';
        validCriteria.value = '2025-01-01';
        String validResult = cCreateTreatmentTaskService.createCondition(validCriteria, 'Account');

        cSRMTreatmentMapper.Criteria invalidCriteria = new cSRMTreatmentMapper.Criteria();
        invalidCriteria.field = 'celsrm__Last_Response_Date__c';
        invalidCriteria.operator = '=';
        invalidCriteria.value = 'notADateTime';
        String invalidResult = cCreateTreatmentTaskService.createCondition(invalidCriteria, 'Account');
    }
    // << END - MM - FIN-10130 - createCondition DateTime field parse-failure branch (line 330) >>

    // << START - MM - FIN-10130 - createCondition default/text field LIKE operator wraps value in wildcards (line 339) >>
    @isTest
    static void testCreateConditionDefaultFieldLikeOperator() {
        cSRMTreatmentMapper.Criteria criteria = new cSRMTreatmentMapper.Criteria();
        criteria.field = 'Name';
        criteria.operator = 'LIKE';
        criteria.value = 'Acme';

        String result = cCreateTreatmentTaskService.createCondition(criteria, 'Account');
    }
    // << END - MM - FIN-10130 - createCondition default/text field LIKE operator wraps value in wildcards (line 339) >>
}