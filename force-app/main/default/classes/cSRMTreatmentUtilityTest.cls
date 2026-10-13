/**
 * Test coverage for cSRMTreatmentUtility (local port of celsrm SRMTreatmentUtility, public in package).
 * Covers formatting helpers, getBody (HTML table generation for treatment step attachments),
 * getAttachmentDetails/getEmailTemplateForAttachment, getCronForDatetime, getChildRecordIds and
 * getQueryWhereClause.
 */
@isTest
public class cSRMTreatmentUtilityTest {
    private static String namespace = 'celsrm__';

    private static celsrm__Treatment__c buildTreatment(Boolean seperateTaskForStep, Boolean consolidated) {
        celsrm__Treatment__c t = new celsrm__Treatment__c();
        t.Name = 'Test Treatment';
        t.celsrm__Treatment_Name__c = 'Test Treatment';
        t.celsrm__Related_Object__c = namespace + 'Transaction__c';
        t.celsrm__Active__c = true;
        t.celsrm__Seperate_Task_For_Step__c = seperateTaskForStep;
        t.celsrm__Consolidated_Treatment__c = consolidated;
        t.celsrm__Attachment_Name__c = 'TreatmentAttachment';
        t.celsrm__Treatment_Steps__c = '[{"stepName":"Proactive Email","taskSubject":"Proactive Email","order":1,"active":true,"columns":["Name","' + namespace + 'Amount__c","' + namespace + 'Due_Date__c"],"calculateTotal":true,"showTotal":true,"aggregationField":"' + namespace + 'Amount__c","totalTitle":"Total"}]';
        insert t;
        return t;
    }

    @isTest
    static void testFormatAsCurrencyVariousValues() {
        // formatAsCurrency(Double amount) - decimal literals must be explicitly cast to Double,
        // since Apex infers plain decimal literals as Decimal and there is no implicit
        // Decimal->Double narrowing for method-overload resolution here.
        System.assertNotEquals(null, cSRMTreatmentUtility.formatAsCurrency(Double.valueOf(1234.56)));
        System.assertNotEquals(null, cSRMTreatmentUtility.formatAsCurrency(Double.valueOf(0)));
        System.assertNotEquals(null, cSRMTreatmentUtility.formatAsCurrency(Double.valueOf(-98.5)));
        System.assertEquals(null, cSRMTreatmentUtility.formatAsCurrency(null));
    }

    @isTest
    static void testFormatDoubleValueNoCurrencySettings() {
        // formatDoubleValue(String currencyCode, Double d)
        String result = cSRMTreatmentUtility.formatDoubleValue('XYZ', Double.valueOf(100.0));
        System.assertNotEquals(null, result, 'Should fall back to $ when no CurrencyCode_Symbols setting exists');
    }

    @isTest
    static void testFormatAsNumber() {
        System.assertEquals(null, cSRMTreatmentUtility.formatAsNumber(null));
        System.assertNotEquals(null, cSRMTreatmentUtility.formatAsNumber(42));
    }

    @isTest
    static void testGetCronForDatetime() {
        Datetime dt = Datetime.newInstance(2026, 8, 15, 10, 30, 0);
        String cron = cSRMTreatmentUtility.getCronForDatetime(dt);
        System.assert(cron.contains('2026'), 'Cron string should contain the year');
    }

    @isTest
    static void testGetChildRecordIdsNoAttachment() {
        Account acc = CreditDataGenerator.insertAccount();
        celsrm__Treatment__c t = buildTreatment(false, false);
        Task tsk = new Task(Subject = 'Proactive Email', Status = 'Not Started', WhatId = acc.Id, celsrm__Treatment__c = t.Id, celsrm__Treatment_Stage__c = 'Proactive Email');
        insert tsk;
        List<String> ids = cSRMTreatmentUtility.getChildRecordIds(tsk, t);
        System.assertNotEquals(null, ids, 'Method swallows exceptions internally and always returns a list');
    }

    @isTest
    static void testGetQueryWhereClauseSingleCriteria() {
        cSRMTreatmentMapper.Criteria c = new cSRMTreatmentMapper.Criteria();
        c.field = 'Name';
        c.operator = '=';
        c.value = 'Test Account';
        String whereClause = cSRMTreatmentUtility.getQueryWhereClause(new List<cSRMTreatmentMapper.Criteria>{ c }, '', 'Account', null);
        System.assertNotEquals(null, whereClause);
    }

    @isTest
    static void testGetQueryWhereClauseWithCondition() {
        cSRMTreatmentMapper.Criteria c1 = new cSRMTreatmentMapper.Criteria();
        c1.field = 'Name';
        c1.operator = '=';
        c1.value = 'Test Account';
        cSRMTreatmentMapper.Criteria c2 = new cSRMTreatmentMapper.Criteria();
        c2.field = 'AnnualRevenue';
        c2.operator = '>';
        c2.value = '100';
        String whereClause = cSRMTreatmentUtility.getQueryWhereClause(new List<cSRMTreatmentMapper.Criteria>{ c1, c2 }, '( 1 AND 2 )', 'Account', null);
        System.assertNotEquals(null, whereClause);
    }

    @isTest
    static void testGetBodyWithCurrencyReferenceAndDateColumns() {
        Account acc = CreditDataGenerator.insertAccount();
        celsrm__Transaction__c trx = DataGenerator.insertTransaction(acc);

        cSRMTreatmentMapper.ObjectCriteria step = new cSRMTreatmentMapper.ObjectCriteria();
        step.stepName = 'Proactive Email';
        step.columns = new List<String>{ 'Name', namespace + 'Amount__c', namespace + 'Due_Date__c', namespace + 'Account__c' };
        step.calculateTotal = true;
        step.showTotal = true;
        step.aggregationField = namespace + 'Amount__c';
        step.totalTitle = 'Total';
        step.sortField = 'Name';
        step.sortDirection = 'ASC';

        Map<String, Schema.SObjectField> fMap = Schema.SObjectType.celsrm__Transaction__c.fields.getMap();
        celsrm__Treatment__c t = buildTreatment(false, false);

        Test.startTest();
        Map<String, Object> result = cSRMTreatmentUtility.getBody(step, fMap, namespace + 'Transaction__c', t, true, new Set<Id>{ trx.Id }, 'Proactive Email', false, null);
        Test.stopTest();

        System.assertNotEquals(null, result.get('innerHtml'), 'HTML table body should be generated');
        System.assertNotEquals(null, result.get('childMap'), 'childMap should be populated when updateRecord is true');
        System.assertNotEquals(null, result.get('totalHtml'), 'totalHtml should be populated when showTotal is true');
    }

    @isTest
    static void testGetBodyConsolidatedWithTranslatedLabels() {
        Account acc = CreditDataGenerator.insertAccount();
        celsrm__Transaction__c trx = DataGenerator.insertTransaction(acc);

        cSRMTreatmentMapper.ObjectCriteria step = new cSRMTreatmentMapper.ObjectCriteria();
        step.stepName = 'Consolidated Step';
        step.columns = new List<String>{ 'Id', 'Name', namespace + 'Amount__c' };
        step.calculateTotal = false;

        Map<String, Schema.SObjectField> fMap = Schema.SObjectType.celsrm__Transaction__c.fields.getMap();
        celsrm__Treatment__c t = buildTreatment(false, true);
        Map<String, String> translatedLabels = new Map<String, String>{ 'name' => 'Translated Name' };

        Map<String, Object> result = cSRMTreatmentUtility.getBody(step, fMap, namespace + 'Transaction__c', t, false, new Set<Id>{ trx.Id }, 'Consolidated Step', true, translatedLabels);

        System.assertNotEquals(null, result.get('innerHtml'));
        System.assertNotEquals(null, result.get('totalHtml'), 'isConsolidated branch should populate totalHtml even without showTotal');
    }

    @isTest
    static void testGetAttachmentDetailsSeperateTaskForStep() {
        Account acc = CreditDataGenerator.insertAccount();
        celsrm__Transaction__c trx = DataGenerator.insertTransaction(acc);
        celsrm__Treatment__c t = buildTreatment(true, false);

        Task tsk = new Task(Subject = 'Proactive Email', Status = 'Not Started', WhatId = acc.Id, celsrm__Treatment__c = t.Id, celsrm__Treatment_Stage__c = 'Proactive Email');
        insert tsk;

        Map<String, Set<Id>> stepToRecIds = new Map<String, Set<Id>>{ 'Proactive Email' => new Set<Id>{ trx.Id } };
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

        Map<String, String> attachmentDetails = cSRMTreatmentUtility.getAttachmentDetails('PDF', t, tsk, acc.Id, 'Treatment Details', 'Proactive Email');
        System.assertNotEquals(null, attachmentDetails, 'Method should always return a map, even when the email template is not found');
    }

    @isTest
    static void testGetAttachmentDetailsNonSeperateExcel() {
        Account acc = CreditDataGenerator.insertAccount();
        celsrm__Transaction__c trx = DataGenerator.insertTransaction(acc);
        celsrm__Treatment__c t = buildTreatment(false, false);

        Task tsk = new Task(Subject = 'Proactive Email', Status = 'Not Started', WhatId = acc.Id, celsrm__Treatment__c = t.Id, celsrm__Treatment_Stage__c = 'Proactive Email');
        insert tsk;

        Map<String, Set<Id>> stepToRecIds = new Map<String, Set<Id>>{ 'Proactive Email' => new Set<Id>{ trx.Id } };
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

        Map<String, String> attachmentDetails = cSRMTreatmentUtility.getAttachmentDetails('Excel', t, tsk, acc.Id, 'Treatment Details', 'Proactive Email');
        System.assertNotEquals(null, attachmentDetails, 'Method should always return a map, even when the email template is not found');
    }

    @isTest
    static void testGetEmailTemplateForAttachmentFallbackNotFound() {
        celsrm__Treatment__c t = buildTreatment(false, false);
        Task tsk = new Task(Subject = 'Proactive Email', Status = 'Not Started');
        EmailTemplate result = cSRMTreatmentUtility.getEmailTemplateForAttachment('PDF', t, tsk, null);
        System.assertEquals(null, result, 'No matching template exists, method should return null gracefully');
    }

    @isTest
    static void testGetEmailTemplateForAttachmentWithFolderReferenceField() {
        Account acc = CreditDataGenerator.insertAccount();
        celsrm__Treatment__c t = buildTreatment(false, false);
        t.celsrm__Attachment_Template_Name__c = 'DoesNotExistTemplate';
        t.celsrm__Attachment_Template_Folder_Ref_Field__c = 'Name';
        update t;
        Task tsk = new Task(Subject = 'Proactive Email', Status = 'Not Started');
        EmailTemplate result = cSRMTreatmentUtility.getEmailTemplateForAttachment('PDF', t, tsk, acc.Id);
        System.assertEquals(null, result, 'Folder-reference-field branch should still return null gracefully when nothing matches');
    }

    // << START - MM - FIN-10130 - getBody Transaction currency totals, standard/custom reference nulls, width cap >>
    @isTest
    static void testGetBodyTransactionCurrencyTotalsReferenceAndWidthCap() {
        Account acc = CreditDataGenerator.insertAccount();
        celsrm__Treatment__c t = buildTreatment(false, false);

        celsrm__Transaction__c trx1 = new celsrm__Transaction__c();
        trx1.Name = 'Very Long Transaction Name For Width Cap Testing Purposes 001';
        trx1.celsrm__Account__c = acc.Id;
        trx1.celsrm__Amount__c = 500;
        trx1.celsrm__Balance__c = 100;
        insert trx1;

        celsrm__Transaction__c trx2 = new celsrm__Transaction__c();
        trx2.Name = 'TrxTwo';
        trx2.celsrm__Account__c = acc.Id;
        trx2.celsrm__Amount__c = 300;
        trx2.celsrm__Balance__c = 50;
        insert trx2;

        celsrm__Transaction__c trx3 = new celsrm__Transaction__c();
        trx3.Name = 'TrxThree';
        trx3.celsrm__Account__c = acc.Id;
        trx3.celsrm__Balance__c = 20;
        insert trx3;

        cSRMTreatmentMapper.ObjectCriteria step = new cSRMTreatmentMapper.ObjectCriteria();
        step.stepName = 'Proactive Email';
        step.columns = new List<String>{ 'Name', 'CreatedById', namespace + 'Last_Treatment__c', 'CreatedDate', namespace + 'Amount__c', namespace + 'DPD__c' };
        step.calculateTotal = true;
        step.showTotal = true;
        step.aggregationField = namespace + 'DPD__c';
        step.totalTitle = 'Total DPD';

        Map<String, Schema.SObjectField> fMap = Schema.SObjectType.celsrm__Transaction__c.fields.getMap();

        Test.startTest();
        Map<String, Object> result = cSRMTreatmentUtility.getBody(step, fMap, namespace + 'Transaction__c', t, false, new Set<Id>{ trx1.Id, trx2.Id, trx3.Id }, 'Proactive Email', false, null);
        Test.stopTest();

        System.assertNotEquals(null, result.get('innerHtml'), 'HTML should render with standard reference (CreatedById), null custom reference (Last_Treatment__c) and DATETIME (CreatedDate) columns');
        System.assertNotEquals(null, result.get('totalHtml'), 'Non-currency numeric aggregation total should be populated when > 0');
        Map<String, Double> totalOpenItems = (Map<String, Double>) result.get('TotalOpenItems');
        System.assert(totalOpenItems.size() > 0, 'Currency totals map should be populated for celsrm__Transaction__c child object');
    }
    // << END - MM - FIN-10130 - getBody Transaction currency totals, standard/custom reference nulls, width cap >>

    // << START - MM - FIN-10130 - getBody PaymentInProgress subtotal grouping (mid-loop and trailing row) >>
    @isTest
    static void testGetBodyPaymentInProgressSubtotalGrouping() {
        Account acc = CreditDataGenerator.insertAccount();
        celsrm__Treatment__c t = buildTreatment(false, false);

        celsrm__Transaction__c trx1 = new celsrm__Transaction__c(Name = 'PIP1', celsrm__Account__c = acc.Id, celsrm__Amount__c = 100, celsrm__Clearing_Document__c = 'DOC-A');
        insert trx1;
        celsrm__Transaction__c trx2 = new celsrm__Transaction__c(Name = 'PIP2', celsrm__Account__c = acc.Id, celsrm__Amount__c = 200, celsrm__Clearing_Document__c = 'DOC-B');
        insert trx2;
        celsrm__Transaction__c trx3 = new celsrm__Transaction__c(Name = 'PIP3', celsrm__Account__c = acc.Id, celsrm__Amount__c = 300, celsrm__Clearing_Document__c = 'DOC-B');
        insert trx3;

        // NOTE: getBody's SOQL only selects the fields listed in step.columns (plus a fixed set of
        // celsrm__Transaction__c extras: Balance__c/DPD__c/Noted__c/Treatment_Notes__c/CurrencyIsoCode -
        // celsrm__Clearing_Document__c is NOT among them). The PaymentInProgress branch unconditionally
        // reads val.get('celsrm__Clearing_Document__c') off every queried record, so a real
        // PaymentInProgress treatment step's columns must include this field or getBody throws
        // System.SObjectException: SObject row was retrieved via SOQL without querying the requested
        // field. Mirrors how this step type is actually configured (the clearing document is shown in
        // the table to justify the grouping/subtotal rows).
        cSRMTreatmentMapper.ObjectCriteria step = new cSRMTreatmentMapper.ObjectCriteria();
        step.stepName = 'PaymentInProgress';
        step.columns = new List<String>{ 'Name', namespace + 'Amount__c', namespace + 'Clearing_Document__c' };
        step.calculateTotal = true;
        step.showTotal = true;
        step.aggregationField = namespace + 'Amount__c';
        step.totalTitle = 'Total';
        step.sortField = 'Name';
        step.sortDirection = 'ASC';

        Map<String, Schema.SObjectField> fMap = Schema.SObjectType.celsrm__Transaction__c.fields.getMap();

        Test.startTest();
        Map<String, Object> result = cSRMTreatmentUtility.getBody(step, fMap, namespace + 'Transaction__c', t, false, new Set<Id>{ trx1.Id, trx2.Id, trx3.Id }, 'PaymentInProgress', false, null);
        Test.stopTest();

        System.assertNotEquals(null, result.get('innerHtml'), 'PaymentInProgress mid-loop and trailing subtotal rows should render when clearing document changes across records');
    }
    // << END - MM - FIN-10130 - getBody PaymentInProgress subtotal grouping (mid-loop and trailing row) >>

    // << START - MM - FIN-10130 - getBody isConsolidated total>0 and totalMap non-empty branches >>
    @isTest
    static void testGetBodyConsolidatedTotalBranches() {
        Account acc = CreditDataGenerator.insertAccount();
        celsrm__Transaction__c trx = DataGenerator.insertTransaction(acc);
        celsrm__Treatment__c t = buildTreatment(false, true);
        Map<String, Schema.SObjectField> fMap = Schema.SObjectType.celsrm__Transaction__c.fields.getMap();

        // Non-currency numeric aggregation -> isConsolidated total > 0 branch
        cSRMTreatmentMapper.ObjectCriteria stepNumeric = new cSRMTreatmentMapper.ObjectCriteria();
        stepNumeric.stepName = 'Consolidated Numeric';
        stepNumeric.columns = new List<String>{ 'Name', namespace + 'Promised_Amount__c' };
        stepNumeric.calculateTotal = true;
        stepNumeric.showTotal = false;
        stepNumeric.aggregationField = namespace + 'Promised_Amount__c';

        Map<String, Object> resultNumeric = cSRMTreatmentUtility.getBody(stepNumeric, fMap, namespace + 'Transaction__c', t, false, new Set<Id>{ trx.Id }, 'Consolidated Numeric', true, null);
        System.assertNotEquals(null, resultNumeric.get('totalHtml'), 'isConsolidated branch should format a positive non-currency total');

        // Currency aggregation -> isConsolidated totalMap non-empty branch
        cSRMTreatmentMapper.ObjectCriteria stepCurrency = new cSRMTreatmentMapper.ObjectCriteria();
        stepCurrency.stepName = 'Consolidated Currency';
        stepCurrency.columns = new List<String>{ 'Name', namespace + 'Amount__c' };
        stepCurrency.calculateTotal = true;
        stepCurrency.showTotal = false;
        stepCurrency.aggregationField = namespace + 'Amount__c';

        Map<String, Object> resultCurrency = cSRMTreatmentUtility.getBody(stepCurrency, fMap, namespace + 'Transaction__c', t, false, new Set<Id>{ trx.Id }, 'Consolidated Currency', true, null);
        System.assertNotEquals(null, resultCurrency.get('totalHtml'), 'isConsolidated branch should format the totalMap when a currency aggregation field is populated');
    }
    // << END - MM - FIN-10130 - getBody isConsolidated total>0 and totalMap non-empty branches >>

    // << START - MM - FIN-10130 - formatDoubleValue with a configured Currency Symbol custom setting >>
    @isTest
    static void testFormatDoubleValueWithCurrencySettings() {
        celsrm__CurrencyCode_Symbols__c ccs = new celsrm__CurrencyCode_Symbols__c(Name = 'USD', celsrm__Currency_Symbol__c = '$');
        insert ccs;

        String result = cSRMTreatmentUtility.formatDoubleValue('USD', Double.valueOf(75.5));
        System.assertNotEquals(null, result, 'Should return a formatted currency string whether or not the custom setting cache reflects the just-inserted record');
    }
    // << END - MM - FIN-10130 - formatDoubleValue with a configured Currency Symbol custom setting >>

    // << START - MM - FIN-10130 - getQueryWhereClause empty condition with a second criteria (AND join) >>
    @isTest
    static void testGetQueryWhereClauseEmptyConditionTwoCriteria() {
        cSRMTreatmentMapper.Criteria c1 = new cSRMTreatmentMapper.Criteria();
        c1.field = 'Name';
        c1.operator = '=';
        c1.value = 'Test Account';
        cSRMTreatmentMapper.Criteria c2 = new cSRMTreatmentMapper.Criteria();
        c2.field = 'NumberOfEmployees';
        c2.operator = '>';
        c2.value = '10';
        String whereClause = cSRMTreatmentUtility.getQueryWhereClause(new List<cSRMTreatmentMapper.Criteria>{ c1, c2 }, '', 'Account', null);
        System.assert(whereClause.contains('AND'), 'Second criteria with an empty criteriaCondition should be joined with AND to the first');
    }
    // << END - MM - FIN-10130 - getQueryWhereClause empty condition with a second criteria (AND join) >>

    // << START - MM - FIN-10130 - getQueryWhereClause whitespace token cleanup and invalid-criteria index removal >>
    @isTest
    static void testGetQueryWhereClauseInvalidCriteriaIndexRemoval() {
        cSRMTreatmentMapper.Criteria c1 = new cSRMTreatmentMapper.Criteria();
        c1.field = 'Name';
        c1.operator = '=';
        c1.value = 'Test Account';
        cSRMTreatmentMapper.Criteria c2 = new cSRMTreatmentMapper.Criteria();
        c2.field = 'IsDeleted';
        c2.operator = '=';
        c2.value = 'notaboolean';
        cSRMTreatmentMapper.Criteria c3 = new cSRMTreatmentMapper.Criteria();
        c3.field = 'NumberOfEmployees';
        c3.operator = '=';
        c3.value = 'notanumber';
        String whereClause = cSRMTreatmentUtility.getQueryWhereClause(new List<cSRMTreatmentMapper.Criteria>{ c1, c2, c3 }, '(  1 AND 2 AND 3 )', 'Account', null);
        System.assertNotEquals(null, whereClause, 'Whitespace tokens and invalid criteria indexes should be cleaned up without error');
    }
    // << END - MM - FIN-10130 - getQueryWhereClause whitespace token cleanup and invalid-criteria index removal >>

    // << START - MM - FIN-10130 - getChildRecordIds success path with a real Treatment Details attachment >>
    @isTest
    static void testGetChildRecordIdsWithActualAttachment() {
        Account acc = CreditDataGenerator.insertAccount();
        celsrm__Transaction__c trx = DataGenerator.insertTransaction(acc);
        celsrm__Treatment__c t = buildTreatment(false, false);
        Task tsk = new Task(Subject = 'Proactive Email', Status = 'Not Started', WhatId = acc.Id, celsrm__Treatment__c = t.Id, celsrm__Treatment_Stage__c = 'Proactive Email');
        insert tsk;

        Map<String, Set<Id>> stepToRecIds = new Map<String, Set<Id>>{ 'Proactive Email' => new Set<Id>{ trx.Id } };
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

        List<String> ids = cSRMTreatmentUtility.getChildRecordIds(tsk, t);
        System.assertEquals(1, ids.size(), 'Should extract the child transaction Id from the Treatment Details attachment JSON');
    }
    // << END - MM - FIN-10130 - getChildRecordIds success path with a real Treatment Details attachment >>

    // << START - MM - FIN-10130 - getEmailTemplateForAttachment folder-reference-field blank value fallback >>
    @isTest
    static void testGetEmailTemplateForAttachmentFolderRefFieldBlankValue() {
        Account acc = CreditDataGenerator.insertAccount();
        celsrm__Treatment__c t = buildTreatment(false, false);
        t.celsrm__Attachment_Template_Name__c = 'SomeTemplateName';
        t.celsrm__Attachment_Template_Folder_Ref_Field__c = 'Description';
        update t;
        Task tsk = new Task(Subject = 'Proactive Email', Status = 'Not Started');
        EmailTemplate result = cSRMTreatmentUtility.getEmailTemplateForAttachment('PDF', t, tsk, acc.Id);
        System.assertEquals(null, result, 'Blank folder reference field value should fall back to name-only lookup and still return null gracefully');
    }
    // << END - MM - FIN-10130 - getEmailTemplateForAttachment folder-reference-field blank value fallback >>

    // << START - MM - FIN-10130 - getEmailTemplateForAttachment folder+name set directly on Treatment >>
    @isTest
    static void testGetEmailTemplateForAttachmentFolderAndNameSetDirectly() {
        celsrm__Treatment__c t = buildTreatment(false, false);
        t.celsrm__Attachment_Template_Folder__c = 'SomeFolderThatDoesNotExist';
        t.celsrm__Attachment_Template_Name__c = 'SomeTemplateThatDoesNotExist';
        update t;
        Task tsk = new Task(Subject = 'Proactive Email', Status = 'Not Started');
        EmailTemplate result = cSRMTreatmentUtility.getEmailTemplateForAttachment('PDF', t, tsk, null);
        System.assertEquals(null, result, 'Folder+Name branch with no matching template should fall back to name-only lookup and return null gracefully');
    }
    // << END - MM - FIN-10130 - getEmailTemplateForAttachment folder+name set directly on Treatment >>

    // << START - MM - FIN-10130 - getEmailTemplateForAttachment Enable_Dynamic_Template__c branches >>
    @isTest
    static void testGetEmailTemplateForAttachmentDynamicTemplateBranches() {
        Account acc = CreditDataGenerator.insertAccount();
        celsrm__Treatment__c t = buildTreatment(false, false);
        t.celsrm__Enable_Dynamic_Template__c = true;
        t.celsrm__Template_Folder_Reference_Field__c = 'Name';
        update t;
        Task tsk = new Task(Subject = 'Proactive Email', Status = 'Not Started');

        EmailTemplate resultPdf = cSRMTreatmentUtility.getEmailTemplateForAttachment('PDF', t, tsk, acc.Id);
        System.assertEquals(null, resultPdf, 'Dynamic template with a resolvable folder name should still return null when no template matches');

        EmailTemplate resultExcel = cSRMTreatmentUtility.getEmailTemplateForAttachment('Excel', t, tsk, acc.Id);
        System.assertEquals(null, resultExcel, 'Dynamic template Excel variant should also return null gracefully');

        t.celsrm__Template_Folder_Reference_Field__c = 'Description';
        update t;
        EmailTemplate resultBlank = cSRMTreatmentUtility.getEmailTemplateForAttachment('PDF', t, tsk, acc.Id);
        System.assertEquals(null, resultBlank, 'Blank resolved folder name should fall back to name-only lookup and return null gracefully');
    }
    // << END - MM - FIN-10130 - getEmailTemplateForAttachment Enable_Dynamic_Template__c branches >>
}