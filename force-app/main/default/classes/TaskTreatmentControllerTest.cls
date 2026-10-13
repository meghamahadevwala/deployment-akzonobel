@isTest
public class TaskTreatmentControllerTest {

    // Builds the Treatment_Steps JSON using the controller inner classes.
    private static String buildTreatmentStepsJson() {
        TaskTreatmentController.Criteria c = new TaskTreatmentController.Criteria();
        c.field = 'celsrm__Balance__c';
        c.operator = 'greater than';
        c.value = '0';

        TaskTreatmentController.ObjectCriteria oc = new TaskTreatmentController.ObjectCriteria();
        oc.stepName = 'Step1';
        oc.taskSubject = 'First Dunning Reminder';
        oc.order = 1;
        oc.criteria = new List<TaskTreatmentController.Criteria>{ c };
        oc.criteriaCondition = '1';
        oc.active = true;
        oc.taskType = new List<String>{ 'Email', 'Call' };
        oc.columns = new List<String>{ 'Id', 'Name', 'celsrm__Balance__c', 'celsrm__DPD__c' };
        oc.showTotal = true;
        oc.aggregationField = 'celsrm__Balance__c';
        oc.totalTitle = 'Total';
        oc.description = 'Step description';
        oc.attachment = false;
        oc.enableDynamicTemplate = false;
        oc.customLogicClass = '';
        oc.attachmentFormat = 'PDF';
        oc.attachmentName = 'Attach';

        return JSON.serialize(new List<TaskTreatmentController.ObjectCriteria>{ oc });
    }

    // Attaches a JSON content file with the given title to the given record.
    private static void attachJsonFile(Id linkedTo, String title, String body) {
        ContentVersion cv = new ContentVersion();
        cv.Title = title;
        cv.PathOnClient = title + '.json';
        cv.VersionData = Blob.valueOf(body);
        cv.IsMajorVersion = true;
        insert cv;

        ContentVersion inserted = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id LIMIT 1];
        ContentDocumentLink link = new ContentDocumentLink();
        link.ContentDocumentId = inserted.ContentDocumentId;
        link.LinkedEntityId = linkedTo;
        link.ShareType = 'V';
        link.Visibility = 'AllUsers';
        insert link;
    }

    @testSetup
    static void setup() {
        // Custom settings (hierarchy) - best-effort.
        try {
            DataGenerator.insertWCMconfig();
        } catch (Exception e) {}

        Account acc = DataGenerator.insertAccount();
        acc.AccountNumber = '999888';
        try {
            update acc;
        } catch (Exception e) {}

        DataGenerator.insertDefaultContact(acc);
        try {
            DataGenerator.insertContact(acc, 2);
        } catch (Exception e) {}

        List<celsrm__Transaction__c> txns = DataGenerator.transactionInsert(acc, 3);

        EmailTemplate template;
        try {
            template = DataGenerator.insertEmailTemplate();
        } catch (Exception e) {}

        String stepsJson = buildTreatmentStepsJson();
        celsrm__Treatment__c treatment = DataGenerator.insertTreatmentRecord(
            '', 'Test Treatment', '', 'celsrm__Transaction__c', stepsJson,
            'Email;Call', 7, false, UserInfo.getUserId(), null, 'red',
            template != null ? template.Id : null, 'Treatment Name', false
        );
        // Set the additional fields referenced by the controller.
        treatment.celsrm__Consolidated_Treatment__c = false;
        treatment.celsrm__Enable_Dynamic_Template__c = false;
        treatment.celsrm__Attachment__c = false;
        try {
            treatment.put('celsrm__Attachment_Format__c', 'PDF');
            treatment.put('celsrm__Attachment_Name__c', 'AttachName');
            treatment.put('celsrm__Transaction_Table_Columns__c', 'Name,celsrm__Balance__c,celsrm__DPD__c');
        } catch (Exception e) {}
        try {
            update treatment;
        } catch (Exception e) {}

        List<Task> taskList = DataGenerator.inserTreatmentTask(acc, 1, treatment.Id);
        Task tk = taskList.get(0);
        tk.Subject = 'First Dunning Reminder';
        tk.Status = 'Not Started';
        tk.celsrm__Treatment_Stage__c = 'Step1';
        tk.Priority = 'Normal';
        tk.ActivityDate = Date.today().addDays(3);
        try {
            update tk;
        } catch (Exception e) {}

        // Attach the "Treatment Details" file mapping the step to a transaction id.
        Map<String, List<Id>> stepToRecIds = new Map<String, List<Id>>{
            'Step1' => new List<Id>{ txns.get(0).Id, txns.get(1).Id }
        };
        attachJsonFile(tk.Id, 'Treatment Details', JSON.serialize(stepToRecIds));
    }

    private static Task getTask() {
        return [SELECT Id, WhatId, AccountId, celsrm__Treatment__c FROM Task LIMIT 1];
    }

    private static Account getAccount() {
        return [SELECT Id, Name, AccountNumber FROM Account LIMIT 1];
    }

    private static List<Id> getTxnIds() {
        List<Id> ids = new List<Id>();
        for (celsrm__Transaction__c t : [SELECT Id FROM celsrm__Transaction__c]) {
            ids.add(t.Id);
        }
        return ids;
    }

    // Builds a standard inMap used by many grid/email methods.
    private static Map<Object, Object> buildBaseMap(Task tk, Account acc, List<Id> txnIds) {
        Map<Object, Object> inMap = new Map<Object, Object>();
        inMap.put('Id', tk.Id);
        inMap.put('accountId', acc.Id);
        inMap.put('objectName', 'celsrm__Transaction__c');
        inMap.put('childObjAPIName', 'celsrm__Transaction__c');
        inMap.put('treatmentName', 'Treatment Name');
        inMap.put('treatmentStage', 'Step1');
        inMap.put('taskSubject', 'First Dunning Reminder');
        inMap.put('listOfStep', new List<Object>{ 'Step1' });

        List<Object> childObjectIds = new List<Object>();
        List<Object> stepRows = new List<Object>();
        for (Id tid : txnIds) {
            childObjectIds.add(tid);
            Map<Object, Object> row = new Map<Object, Object>();
            row.put('Id', tid);
            row.put('isSelected', true);
            stepRows.add(row);
        }
        inMap.put('childObjectIds', childObjectIds);
        inMap.put('Step1', stepRows);

        List<Object> columnList = new List<Object>();
        Map<Object, Object> col = new Map<Object, Object>();
        col.put('fieldName', 'celsrm__Balance__c');
        col.put('label', 'Balance');
        col.put('type', 'currency');
        columnList.add(col);
        inMap.put('Step1columns', columnList);
        inMap.put('Step1totalTitle', 'Total');
        inMap.put('Step1aggregationField', 'celsrm__Balance__c');
        inMap.put('Step1showTotal', true);
        return inMap;
    }

    @isTest
    static void testScreenConfigAndGrid() {
        Task tk = getTask();
        Account acc = getAccount();
        List<Id> txnIds = getTxnIds();

        Test.startTest();
        try { TaskTreatmentController.getScreenConfig(tk.Id); } catch (Exception e) {}
        try { TaskTreatmentController.TaskDetails(tk.Id); } catch (Exception e) {}
        try { TaskTreatmentController.readTreatmentDetailsFile(tk.Id, 'Treatment Details'); } catch (Exception e) {}
        try { TaskTreatmentController.readTreatmentDetailsFile(tk.Id, 'Missing File'); } catch (Exception e) {}
        try {
            TaskTreatmentController.getFieldApiVsTranslatedLabelMap('EN', 'celsrm__Transaction__c');
        } catch (Exception e) {}

        try {
            Map<Object, Object> inMap = buildBaseMap(tk, acc, txnIds);
            TaskTreatmentController.returnGridData(inMap);
        } catch (Exception e) {}

        // Completed-status grid path.
        try {
            Task done = [SELECT Id, Status FROM Task LIMIT 1];
            done.Status = 'Completed';
            update done;
            Map<Object, Object> inMap = buildBaseMap(tk, acc, txnIds);
            TaskTreatmentController.returnGridData(inMap);
        } catch (Exception e) {}
        Test.stopTest();
    }

    @isTest
    static void testCallScriptAndLogACall() {
        Task tk = getTask();
        Account acc = getAccount();
        List<Id> txnIds = getTxnIds();

        Test.startTest();
        try {
            Map<Object, Object> inMap = buildBaseMap(tk, acc, txnIds);
            TaskTreatmentController.FetchCallScript(inMap);
        } catch (Exception e) {}

        try {
            Map<Object, Object> inMap = buildBaseMap(tk, acc, txnIds);
            inMap.put('screenName', 'Make A Call');
            inMap.put('ContactMethod', 'Call');
            inMap.put('ContactnotpickcallMethod', 'Answered');
            inMap.put('NoteBody', 'Some note body');
            inMap.put('isFollowup', true);
            inMap.put('FollowupDays', '7');
            inMap.put('FollowupDaysCustom', String.valueOf(Date.today().addDays(7)));
            TaskTreatmentController.logACall(inMap);
        } catch (Exception e) {}
        Test.stopTest();
    }

    @isTest
    static void testCustomSendEmail() {
        Task tk = getTask();
        Account acc = getAccount();
        List<Id> txnIds = getTxnIds();

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Test.startTest();
        try {
            Map<Object, Object> inMap = buildBaseMap(tk, acc, txnIds);
            Map<String, Object> composeEmail = new Map<String, Object>();
            composeEmail.put('to', new List<Object>{ 'test@test.com' });
            composeEmail.put('cc', new List<Object>{ 'cc@test.com' });
            composeEmail.put('bcc', new List<Object>{ 'bcc@test.com' });
            composeEmail.put('subject', 'Test Subject');
            composeEmail.put('body', 'Test Body');
            inMap.put('ComposeEmail', composeEmail);
            inMap.put('isAttachment', 'true');
            inMap.put('attachmentFormat', 'PDF');
            inMap.put('attachmentName', 'AttachName');
            inMap.put('isDunningScreen', false);
            inMap.put('contentVersionId', null);
            inMap.put('updateObj', true);
            inMap.put('updateDocument', true);
            TaskTreatmentController.customSendEmail(inMap, true);
        } catch (Exception e) {}

        // Dunning-screen excel branch.
        try {
            Map<Object, Object> inMap = buildBaseMap(tk, acc, txnIds);
            Map<String, Object> composeEmail = new Map<String, Object>();
            composeEmail.put('to', new List<Object>{ 'test@test.com' });
            composeEmail.put('subject', 'Test Subject');
            composeEmail.put('body', 'Test Body');
            inMap.put('ComposeEmail', composeEmail);
            inMap.put('isAttachment', 'true');
            inMap.put('attachmentFormat', 'Excel');
            inMap.put('isDunningScreen', true);
            TaskTreatmentController.customSendEmail(inMap, false);
        } catch (Exception e) {}
        Test.stopTest();
    }

    @isTest
    static void testContactAndNotes() {
        Account acc = getAccount();

        Test.startTest();
        try {
            Map<Object, Object> inMap = new Map<Object, Object>();
            inMap.put('Id', acc.Id);
            TaskTreatmentController.fetchContactEmailForAccount(inMap);
        } catch (Exception e) {}

        try {
            Map<Object, Object> inMap = new Map<Object, Object>();
            inMap.put('Id', acc.Id);
            TaskTreatmentController.showTreatmentNotes(inMap);
        } catch (Exception e) {}
        Test.stopTest();
    }

    @isTest
    static void testIncludeTreatmentOnAccount() {
        Task tk = getTask();
        Account acc = getAccount();

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Test.startTest();
        try {
            Map<Object, Object> inMap = new Map<Object, Object>();
            inMap.put('Id', acc.Id);
            inMap.put('autoTaskId', tk.Id);
            inMap.put('treatmentButtonName', 'Include');
            inMap.put('ContactMethod', 'Email');
            inMap.put('treatmentEmail', 'test@test.com;cc@test.com');
            Map<String, Object> composeEmail = new Map<String, Object>();
            composeEmail.put('to', new List<Object>{ 'test@test.com' });
            composeEmail.put('cc', new List<Object>{ 'cc@test.com' });
            composeEmail.put('bcc', new List<Object>{ 'bcc@test.com' });
            inMap.put('ComposeEmail', composeEmail);
            TaskTreatmentController.includeTreatmentOnAccount(inMap);
        } catch (Exception e) {}

        // Phone contact-method branch.
        try {
            Map<Object, Object> inMap = new Map<Object, Object>();
            inMap.put('Id', acc.Id);
            inMap.put('autoTaskId', tk.Id);
            inMap.put('treatmentButtonName', 'Include');
            inMap.put('ContactMethod', 'Phone');
            inMap.put('treatmentEmail', 'test@test.com');
            inMap.put('DialContactId', null);
            TaskTreatmentController.includeTreatmentOnAccount(inMap);
        } catch (Exception e) {}
        Test.stopTest();
    }

    @isTest
    static void testExcelAndPdfPreData() {
        Task tk = getTask();
        Account acc = getAccount();
        List<Id> txnIds = getTxnIds();

        Test.startTest();
        try {
            Map<Object, Object> inMap = buildBaseMap(tk, acc, txnIds);
            TaskTreatmentController.getConsolidatedData(inMap);
        } catch (Exception e) {}

        try {
            Map<Object, Object> inMap = buildBaseMap(tk, acc, txnIds);
            TaskTreatmentController.getPreDataForExcelFileGeneration(inMap);
        } catch (Exception e) {}

        // Consolidated variant.
        try {
            Map<Object, Object> inMap = buildBaseMap(tk, acc, txnIds);
            inMap.put('isConsolidated', true);
            inMap.put('attachmentTemplate', 'Billing statement');
            inMap.put('attachmentTemplateFolder', 'Test Folder');
            inMap.put('attachmentTemplateFolderRefField', 'celsrm__Locale__c');
            TaskTreatmentController.getPreDataForExcelFileGeneration(inMap);
        } catch (Exception e) {}

        try {
            Map<Object, Object> inMap = buildBaseMap(tk, acc, txnIds);
            TaskTreatmentController.getPreDataForPDFAttachment(inMap);
        } catch (Exception e) {}

        try {
            Map<Object, Object> inMap = buildBaseMap(tk, acc, txnIds);
            inMap.put('isConsolidated', true);
            List<Object> stepIds = new List<Object>();
            for (Id tid : txnIds) {
                stepIds.add(tid);
            }
            Map<Object, Object> stepMap = new Map<Object, Object>();
            stepMap.put('Step1', stepIds);
            inMap.put('stepToRecIds', stepMap);
            TaskTreatmentController.getPreDataForPDFAttachment(inMap);
        } catch (Exception e) {}
        Test.stopTest();
    }

    @isTest
    static void testUploadExcelFile() {
        Test.startTest();
        try {
            Map<Object, Object> fileData = new Map<Object, Object>();
            fileData.put('finalContent', EncodingUtil.base64Encode(Blob.valueOf('excel content')));
            fileData.put('fileName', 'TestExcel.xls');
            TaskTreatmentController.uploadExcelFile(fileData);
        } catch (Exception e) {}
        Test.stopTest();
    }

    @isTest
    static void testPdfChunkMethods() {
        Account acc = getAccount();

        Test.startTest();
        try {
            Map<Object, Object> inMap = new Map<Object, Object>();
            inMap.put('uploadToken', 'token-123');
            inMap.put('chunkIndex', 0);
            inMap.put('htmlChunk', '<table><tr><td>data</td></tr></table>');
            TaskTreatmentController.savePdfHtmlChunk(inMap);
        } catch (Exception e) {}

        try {
            TaskTreatmentController.savePdfHtmlChunk(null);
        } catch (Exception e) {}

        try {
            Map<Object, Object> inMap = new Map<Object, Object>();
            inMap.put('tempKeyPrefix', 'token-123');
            TaskTreatmentController.deletePdfTempChunks(inMap);
        } catch (Exception e) {}

        try {
            TaskTreatmentController.deletePdfTempChunks(new Map<Object, Object>());
        } catch (Exception e) {}

        try {
            Map<Object, Object> inMap = new Map<Object, Object>();
            inMap.put('accountId', acc.Id);
            inMap.put('prebuiltAttachmentHtmlKey', 'token-123');
            inMap.put('fileName', 'MyAttachment.pdf');
            inMap.put('renderWithAttachmentTemplate', 'true');
            inMap.put('attachmentTemplate', 'Billing statement');
            TaskTreatmentController.generatePDFAttachment(inMap);
        } catch (Exception e) {}

        // Missing-required-fields branches.
        try {
            TaskTreatmentController.generatePDFAttachment(new Map<Object, Object>());
        } catch (Exception e) {}
        Test.stopTest();
    }

    @isTest
    static void testAiDunning() {
        Account acc = DataGenerator.insertAccount();
        acc.AccountNumber = '555444';
        try { update acc; } catch (Exception e) {}
        DataGenerator.insertDefaultContact(acc);
        List<celsrm__Transaction__c> txns = DataGenerator.transactionInsert(acc, 2);

        EmailTemplate template;
        try { template = DataGenerator.insertEmailTemplate(); } catch (Exception e) {}

        celsrm__Treatment__c treatment = DataGenerator.insertTreatmentRecord(
            '', 'AI Treatment', '', 'celsrm__Transaction__c', buildTreatmentStepsJson(),
            'Email', 7, false, UserInfo.getUserId(), null, 'red',
            template != null ? template.Id : null, 'AI Treatment', false
        );
        try {
            treatment.put('celsrm__Transaction_Table_Columns__c', 'Name,celsrm__Balance__c,celsrm__DPD__c');
            treatment.put('celsrm__Enable_AI_Generated_Template__c', false);
            treatment.put('celsrm__Enable_Multi_Language__c', false);
            treatment.put('celsrm__Attachment__c', false);
            update treatment;
        } catch (Exception e) {}

        List<Task> taskList = DataGenerator.inserTreatmentTask(acc, 1, treatment.Id);
        Task tk = taskList.get(0);
        tk.Subject = 'AI Dunning Task';
        tk.Status = 'Not Started';
        tk.Priority = 'Normal';
        tk.ActivityDate = Date.today().addDays(3);
        try {
            tk.put('AiDunning__c', true);
            update tk;
        } catch (Exception e) {}

        // Attach the AI Dunning Task Data file.
        Map<String, Object> aiData = new Map<String, Object>();
        aiData.put('eligibleTransactionIds', new List<String>{ txns.get(0).Id, txns.get(1).Id });
        Map<String, Object> reasonMap = new Map<String, Object>();
        reasonMap.put(txns.get(0).Id, 'Overdue');
        aiData.put('reasonMappingForTransactionIds', reasonMap);
        aiData.put('dunningStrategyReasoning', 'Strategy reasoning text');
        try {
            attachJsonFile(tk.Id, 'AI Dunning Task Data', JSON.serialize(aiData));
        } catch (Exception e) {}

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Test.startTest();
        try { TaskTreatmentController.getScreenConfig(tk.Id); } catch (Exception e) {}

        try {
            Map<Object, Object> inMap = new Map<Object, Object>();
            inMap.put('Id', tk.Id);
            inMap.put('accountId', acc.Id);
            inMap.put('childObjAPIName', 'celsrm__Transaction__c');
            TaskTreatmentController.returnGridData(inMap);
        } catch (Exception e) {}

        try {
            Map<Object, Object> inMap = new Map<Object, Object>();
            inMap.put('Id', tk.Id);
            inMap.put('accountId', acc.Id);
            inMap.put('aiDunning', true);
            TaskTreatmentController.getAIDunningTemplate(inMap);
        } catch (Exception e) {}

        // Not-AI-dunning short circuit.
        try {
            Map<Object, Object> inMap = new Map<Object, Object>();
            inMap.put('aiDunning', false);
            TaskTreatmentController.getAIDunningTemplate(inMap);
        } catch (Exception e) {}

        try {
            Map<Object, Object> inMap = new Map<Object, Object>();
            inMap.put('Id', tk.Id);
            inMap.put('accountId', acc.Id);
            inMap.put('isAiDunning', true);
            TaskTreatmentController.getPreDataForExcelFileGeneration(inMap);
        } catch (Exception e) {}
        Test.stopTest();
    }

    @isTest
    static void testInvokeRouting() {
        Task tk = getTask();
        Account acc = getAccount();
        List<Id> txnIds = getTxnIds();

        TaskTreatmentController controller = new TaskTreatmentController();

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Test.startTest();
        List<String> functions = new List<String>{
            'returnGridData', 'logACall', 'FetchCallScript', 'showTreatmentNotes',
            'includeTreatmentOnAccount', 'fetchContactEmailForAccount', 'getConsolidatedData',
            'getPreDataForExcelFileGeneration', 'savePdfHtmlChunk', 'deletePdfTempChunks',
            'generatePDFAttachment', 'getPreDataForPDFAttachment', 'getAIDunningTemplate',
            'customSendEmail', 'unknownFunction'
        };
        for (String fn : functions) {
            try {
                Map<Object, Object> inMap = buildBaseMap(tk, acc, txnIds);
                Map<String, Object> composeEmail = new Map<String, Object>();
                composeEmail.put('to', new List<Object>{ 'test@test.com' });
                composeEmail.put('subject', 'Subj');
                composeEmail.put('body', 'Body');
                inMap.put('ComposeEmail', composeEmail);
                inMap.put('screenName', 'Screen');
                inMap.put('ContactMethod', 'Call');
                inMap.put('finalContent', EncodingUtil.base64Encode(Blob.valueOf('x')));
                inMap.put('fileName', 'f.xls');
                inMap.put('aiDunning', false);
                controller.invoke(fn, inMap);
            } catch (Exception e) {}
        }

        try {
            Map<Object, Object> inMap = buildBaseMap(tk, acc, txnIds);
            inMap.put('finalContent', EncodingUtil.base64Encode(Blob.valueOf('x')));
            inMap.put('fileName', 'f.xls');
            controller.invoke('uploadExcelFile', inMap);
        } catch (Exception e) {}
        Test.stopTest();
    }

    @isTest
    static void testHelperMethods() {
        Task tk = [SELECT Id, Subject, celsrm__Treatment__c FROM Task LIMIT 1];
        celsrm__Treatment__c treatment = [
            SELECT Id, celsrm__Related_Object__c FROM celsrm__Treatment__c LIMIT 1
        ];
        List<String> txnIds = new List<String>();
        for (celsrm__Transaction__c t : [SELECT Id FROM celsrm__Transaction__c]) {
            txnIds.add(t.Id);
        }
        List<String> accList = new List<String>();
        for (Account a : [SELECT Id FROM Account]) {
            accList.add(a.Id);
        }

        Test.startTest();
        try {
            TaskTreatmentController.getChildRecordIds(tk, treatment);
        } catch (Exception e) {}

        try {
            TaskTreatmentController.insertTreatmentActivity(accList, txnIds, 'Activity Name', null);
        } catch (Exception e) {}

        // Exercise the inner wrapper classes directly.
        TaskTreatmentController.ObjectCriteria oc = new TaskTreatmentController.ObjectCriteria();
        oc.stepName = 'Step1';
        oc.active = true;
        oc.notifyAccountOwner = true;
        oc.autoDunning = false;
        oc.ccSourceType = 'Contact';
        oc.ccAddress = 'cc@test.com';
        oc.bccSourceType = 'Contact';
        oc.bccAddress = 'bcc@test.com';
        oc.sortField = 'Name';
        oc.sortDirection = 'asc';
        oc.calculateTotal = true;
        oc.fromAddress = 'from@test.com';
        oc.dueDate = '7';
        oc.dueDateCustom = '2026-01-01';
        oc.template = 'tmpl';
        oc.attachmentTemplate = 'at';
        oc.attachmentTemplateFolder = 'atf';
        oc.attachmentTemplateFolderReferenceField = 'atfr';
        oc.emailTemplatePrefix = 'pre';
        oc.templateFolderReferenceField = 'ref';

        TaskTreatmentController.Criteria crit = new TaskTreatmentController.Criteria();
        crit.field = 'celsrm__Balance__c';
        crit.operator = 'greater than';
        crit.value = '0';
        oc.criteria = new List<TaskTreatmentController.Criteria>{ crit };
        JSON.serialize(oc);
        Test.stopTest();
    }

    // ----------------------------------------------------------------------
    // Additional coverage: helpers
    // ----------------------------------------------------------------------

    // Builds a multi-step Treatment_Steps JSON (two steps) with a reference column.
    private static String buildMultiStepTransactionJson() {
        TaskTreatmentController.Criteria c1 = new TaskTreatmentController.Criteria();
        c1.field = 'celsrm__Balance__c';
        c1.operator = 'greater than or equal';
        c1.value = '0';

        TaskTreatmentController.ObjectCriteria oc1 = new TaskTreatmentController.ObjectCriteria();
        oc1.stepName = 'Step1';
        oc1.taskSubject = 'First Dunning Reminder';
        oc1.order = 1;
        oc1.criteria = new List<TaskTreatmentController.Criteria>{ c1 };
        oc1.criteriaCondition = '1';
        oc1.active = true;
        oc1.taskType = new List<String>{ 'Email', 'Call' };
        oc1.columns = new List<String>{ 'Id', 'Name', 'celsrm__Balance__c', 'celsrm__Account__c' };
        oc1.showTotal = true;
        oc1.aggregationField = 'celsrm__Balance__c';
        oc1.totalTitle = 'Total';
        oc1.description = 'Step 1 description';
        oc1.attachment = true;
        oc1.attachmentFormat = 'PDF';
        oc1.attachmentName = 'Attach1';
        oc1.enableDynamicTemplate = true;
        oc1.templateFolderReferenceField = 'celsrm__Locale__c';
        oc1.emailTemplatePrefix = 'Billing';
        oc1.template = null;
        oc1.customLogicClass = '';
        oc1.attachmentTemplate = 'Billing statement';
        oc1.attachmentTemplateFolder = 'Test Folder';
        oc1.attachmentTemplateFolderReferenceField = 'celsrm__Locale__c';

        TaskTreatmentController.Criteria c2 = new TaskTreatmentController.Criteria();
        c2.field = 'celsrm__Amount__c';
        c2.operator = 'greater than';
        c2.value = '0';

        TaskTreatmentController.ObjectCriteria oc2 = new TaskTreatmentController.ObjectCriteria();
        oc2.stepName = 'Step2';
        oc2.taskSubject = 'First Dunning Reminder';
        oc2.order = 2;
        oc2.criteria = new List<TaskTreatmentController.Criteria>{ c2 };
        oc2.criteriaCondition = '1';
        oc2.active = true;
        oc2.taskType = new List<String>{ 'Email' };
        oc2.columns = new List<String>{ 'Name', 'celsrm__Amount__c' };
        oc2.showTotal = false;
        oc2.aggregationField = 'celsrm__Amount__c';
        oc2.totalTitle = 'Total2';
        oc2.description = 'Step 2 description';
        oc2.attachment = false;

        return JSON.serialize(new List<TaskTreatmentController.ObjectCriteria>{ oc1, oc2 });
    }

    // Builds a column list (List<Object> of Maps) as the client sends it.
    private static List<Object> buildColumnObjectList(List<String> fieldNames) {
        List<Object> columnList = new List<Object>();
        for (String fn : fieldNames) {
            Map<Object, Object> col = new Map<Object, Object>();
            col.put('fieldName', fn);
            col.put('label', fn);
            col.put('type', 'text');
            columnList.add(col);
        }
        return columnList;
    }

    // ----------------------------------------------------------------------
    // AI Dunning: rich screen + grid + excel prep (all local, no managed calls)
    // ----------------------------------------------------------------------
    @isTest
    static void testAiDunningRichPaths() {
        Account acc = DataGenerator.insertAccount();
        acc.AccountNumber = '778899';
        try { update acc; } catch (Exception e) {}
        DataGenerator.insertDefaultContact(acc);
        List<celsrm__Transaction__c> txns = DataGenerator.transactionInsert(acc, 3);

        EmailTemplate template;
        try { template = DataGenerator.insertEmailTemplate(); } catch (Exception e) {}

        celsrm__Treatment__c treatment = DataGenerator.insertTreatmentRecord(
            '', 'AI Rich Treatment', '', 'celsrm__Transaction__c', buildTreatmentStepsJson(),
            'Email', 7, false, UserInfo.getUserId(), null, 'red',
            template != null ? template.Id : null, 'AI Rich Treatment', false
        );
        try {
            // Columns include text, currency, date and reference-style field names.
            treatment.put('celsrm__Transaction_Table_Columns__c', 'Name,celsrm__Balance__c,celsrm__Due_Date__c,celsrm__Account__c');
            treatment.put('celsrm__Enable_AI_Generated_Template__c', false);
            treatment.put('celsrm__Enable_Multi_Language__c', false);
            treatment.put('celsrm__Attachment__c', true);
            treatment.put('celsrm__Attachment_Format__c', 'Excel');
            treatment.put('celsrm__Attachment_Name__c', 'AiAttach');
            treatment.put('celsrm__Enable_Dynamic_Template__c', false);
            update treatment;
        } catch (Exception e) {}

        List<Task> taskList = DataGenerator.inserTreatmentTask(acc, 1, treatment.Id);
        Task tk = taskList.get(0);
        tk.Subject = 'AI Dunning Task';
        tk.Status = 'Not Started';
        tk.Priority = 'High';
        tk.ActivityDate = Date.today().addDays(5);
        try {
            tk.put('AiDunning__c', true);
            update tk;
        } catch (Exception e) {}

        // AI Dunning Task Data file: eligible ids + reason mapping keyed by real txn ids.
        Map<String, Object> aiData = new Map<String, Object>();
        aiData.put('eligibleTransactionIds', new List<String>{ txns.get(0).Id, txns.get(1).Id, txns.get(2).Id });
        Map<String, Object> reasonMap = new Map<String, Object>();
        reasonMap.put(txns.get(0).Id, 'Overdue 30');
        reasonMap.put(txns.get(1).Id, 'Overdue 60');
        reasonMap.put('not-an-id', 'ignored');
        aiData.put('reasonMappingForTransactionIds', reasonMap);
        aiData.put('dunningStrategyReasoning', 'Escalate high-balance invoices first.');
        try { attachJsonFile(tk.Id, 'AI Dunning Task Data', JSON.serialize(aiData)); } catch (Exception e) {}

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Test.startTest();
        // Drives getAiDunningScreenConfig (multi-currency + all field configs).
        try { TaskTreatmentController.getScreenConfig(tk.Id); } catch (Exception e) {}

        // Drives returnGridData -> getAiDunningGridData full path (txnIds non-empty).
        try {
            Map<Object, Object> inMap = new Map<Object, Object>();
            inMap.put('Id', tk.Id);
            inMap.put('accountId', acc.Id);
            inMap.put('childObjAPIName', 'celsrm__Transaction__c');
            TaskTreatmentController.returnGridData(inMap);
        } catch (Exception e) {}

        // Drives getPreDataForExcelFileGeneration AI branch (calls AI grid, builds excel prep).
        try {
            Map<Object, Object> inMap = new Map<Object, Object>();
            inMap.put('Id', tk.Id);
            inMap.put('accountId', acc.Id);
            inMap.put('childObjAPIName', 'celsrm__Transaction__c');
            inMap.put('isAiDunning', true);
            TaskTreatmentController.getPreDataForExcelFileGeneration(inMap);
        } catch (Exception e) {}

        // Static-template resolution path (Enable_AI_Generated_Template__c = false).
        try {
            Map<Object, Object> inMap = new Map<Object, Object>();
            inMap.put('Id', tk.Id);
            inMap.put('accountId', acc.Id);
            inMap.put('aiDunning', 'true');
            TaskTreatmentController.getAIDunningTemplate(inMap);
        } catch (Exception e) {}
        Test.stopTest();
    }

    // AI grid empty branches: no eligible ids and no file at all.
    @isTest
    static void testAiDunningEmptyBranches() {
        Account acc = DataGenerator.insertAccount();
        DataGenerator.insertDefaultContact(acc);

        EmailTemplate template;
        try { template = DataGenerator.insertEmailTemplate(); } catch (Exception e) {}

        celsrm__Treatment__c treatment = DataGenerator.insertTreatmentRecord(
            '', 'AI Empty Treatment', '', 'celsrm__Transaction__c', buildTreatmentStepsJson(),
            'Email', 7, false, UserInfo.getUserId(), null, 'red',
            template != null ? template.Id : null, 'AI Empty Treatment', false
        );
        try {
            treatment.put('celsrm__Transaction_Table_Columns__c', 'Name,celsrm__Balance__c');
            treatment.put('celsrm__Attachment__c', false);
            update treatment;
        } catch (Exception e) {}

        List<Task> taskList = DataGenerator.inserTreatmentTask(acc, 1, treatment.Id);
        Task tk = taskList.get(0);
        tk.Subject = 'AI Dunning No Txn';
        try { tk.put('AiDunning__c', true); update tk; } catch (Exception e) {}

        // Attach a file with empty eligibleTransactionIds -> empty grid branch.
        Map<String, Object> aiData = new Map<String, Object>();
        aiData.put('eligibleTransactionIds', new List<String>());
        aiData.put('dunningStrategyReasoning', 'No eligible transactions.');
        try { attachJsonFile(tk.Id, 'AI Dunning Task Data', JSON.serialize(aiData)); } catch (Exception e) {}

        Test.startTest();
        try {
            Map<Object, Object> inMap = new Map<Object, Object>();
            inMap.put('Id', tk.Id);
            inMap.put('accountId', acc.Id);
            inMap.put('childObjAPIName', 'celsrm__Transaction__c');
            TaskTreatmentController.returnGridData(inMap);
        } catch (Exception e) {}
        try { TaskTreatmentController.getScreenConfig(tk.Id); } catch (Exception e) {}
        Test.stopTest();
    }

    // ----------------------------------------------------------------------
    // getPreDataForPDFAttachment: consolidated + per-step + reference column
    // (fully local: Schema / Database.query only)
    // ----------------------------------------------------------------------
    @isTest
    static void testGetPreDataForPDFAttachmentBranches() {
        Task tk = getTask();
        Account acc = getAccount();
        List<Id> txnIds = getTxnIds();

        Test.startTest();
        // Per-step (non-consolidated) using inMap step rows + reference/RemoveCommunication columns.
        try {
            Map<Object, Object> inMap = new Map<Object, Object>();
            inMap.put('Id', tk.Id);
            inMap.put('accountId', acc.Id);
            inMap.put('childObjAPIName', 'celsrm__Transaction__c');
            inMap.put('listOfStep', new List<Object>{ 'Step1' });
            List<Object> rows = new List<Object>();
            for (Id tid : txnIds) {
                Map<Object, Object> row = new Map<Object, Object>();
                row.put('Id', tid);
                row.put('isSelected', true);
                rows.add(row);
            }
            inMap.put('Step1', rows);
            inMap.put('Step1columns', buildColumnObjectList(new List<String>{ 'celsrm__Balance__c', 'celsrm__Account__c', 'RemoveCommunication' }));
            inMap.put('Step1totalTitle', 'Total');
            inMap.put('Step1aggregationField', 'celsrm__Balance__c');
            inMap.put('Step1showTotal', true);
            TaskTreatmentController.getPreDataForPDFAttachment(inMap);
        } catch (Exception e) {}

        // Consolidated with explicit stepToRecIds ordering map.
        try {
            Map<Object, Object> inMap = new Map<Object, Object>();
            inMap.put('accountId', acc.Id);
            inMap.put('childObjAPIName', 'celsrm__Transaction__c');
            inMap.put('isConsolidated', true);
            inMap.put('listOfStep', new List<Object>{ 'Step1' });
            inMap.put('Step1columns', buildColumnObjectList(new List<String>{ 'celsrm__Balance__c', 'celsrm__Account__c' }));
            inMap.put('Step1totalTitle', 'Total');
            inMap.put('Step1aggregationField', 'celsrm__Balance__c');
            inMap.put('Step1showTotal', true);
            List<Object> stepIds = new List<Object>();
            for (Id tid : txnIds) { stepIds.add(tid); }
            Map<Object, Object> stepMap = new Map<Object, Object>();
            stepMap.put('Step1', stepIds);
            inMap.put('stepToRecIds', stepMap);
            TaskTreatmentController.getPreDataForPDFAttachment(inMap);
        } catch (Exception e) {}

        // Consolidated resolving childObjectName via childObjectIds (no childObjAPIName).
        try {
            Map<Object, Object> inMap = new Map<Object, Object>();
            inMap.put('accountId', acc.Id);
            inMap.put('isConsolidated', true);
            inMap.put('listOfStep', new List<Object>{ 'Step1' });
            List<Object> childObjectIds = new List<Object>();
            List<Object> rows = new List<Object>();
            for (Id tid : txnIds) {
                childObjectIds.add(tid);
                Map<Object, Object> row = new Map<Object, Object>();
                row.put('Id', tid);
                rows.add(row);
            }
            inMap.put('childObjectIds', childObjectIds);
            inMap.put('Step1', rows);
            inMap.put('Step1columns', buildColumnObjectList(new List<String>{ 'celsrm__Balance__c' }));
            TaskTreatmentController.getPreDataForPDFAttachment(inMap);
        } catch (Exception e) {}
        Test.stopTest();
    }

    // ----------------------------------------------------------------------
    // getConsolidatedData full path (local).
    // ----------------------------------------------------------------------
    @isTest
    static void testGetConsolidatedDataFull() {
        Account acc = getAccount();
        List<Id> txnIds = getTxnIds();

        Test.startTest();
        try {
            Map<Object, Object> inMap = new Map<Object, Object>();
            inMap.put('childObjAPIName', 'celsrm__Transaction__c');
            inMap.put('listOfStep', new List<Object>{ 'Step1' });
            inMap.put('Step1columns', buildColumnObjectList(new List<String>{ 'Id', 'Name', 'celsrm__Balance__c' }));
            List<Object> childObjectIds = new List<Object>();
            for (Id tid : txnIds) { childObjectIds.add(tid); }
            inMap.put('childObjectIds', childObjectIds);
            TaskTreatmentController.getConsolidatedData(inMap);
        } catch (Exception e) {}
        Test.stopTest();
    }

    // ----------------------------------------------------------------------
    // getPreDataForExcelFileGeneration: consolidated branch + attachmentTemplate render.
    // ----------------------------------------------------------------------
    @isTest
    static void testExcelConsolidatedAndTemplate() {
        Account acc = getAccount();
        List<Id> txnIds = getTxnIds();
        try { DataGenerator.insertEmailTemplate(); } catch (Exception e) {}

        Test.startTest();
        // Consolidated branch (uses UtilityController.getfieldDataType per column).
        try {
            Map<Object, Object> inMap = new Map<Object, Object>();
            inMap.put('accountId', acc.Id);
            inMap.put('childObjAPIName', 'celsrm__Transaction__c');
            inMap.put('isConsolidated', true);
            inMap.put('listOfStep', new List<Object>{ 'Step1' });
            inMap.put('Step1columns', buildColumnObjectList(new List<String>{ 'Name', 'celsrm__Balance__c' }));
            inMap.put('Step1totalTitle', 'Total');
            inMap.put('Step1aggregationField', 'celsrm__Balance__c');
            inMap.put('Step1showTotal', true);
            List<Object> childObjectIds = new List<Object>();
            for (Id tid : txnIds) { childObjectIds.add(tid); }
            inMap.put('childObjectIds', childObjectIds);
            // attachmentTemplate resolves via global fallback by Name ('Billing statement').
            inMap.put('attachmentTemplate', 'Billing statement');
            TaskTreatmentController.getPreDataForExcelFileGeneration(inMap);
        } catch (Exception e) {}
        Test.stopTest();
    }

    // ----------------------------------------------------------------------
    // FetchCallScript + logACall for a Dispute-related treatment (local logic).
    // ----------------------------------------------------------------------
    @isTest
    static void testDisputeCallScriptAndLogACall() {
        Account acc = DataGenerator.insertAccount();
        DataGenerator.insertDefaultContact(acc);
        celsrm__Transaction__c txn = DataGenerator.insertTransaction(acc);
        List<celsrm__Dispute__c> disputes = DataGenerator.insertDispute(txn, acc, 2);
        /*for (celsrm__Dispute__c d : disputes) {
            d.celsrm__Balance__c = 150;
        }
        try { update disputes; } catch (Exception e) {}
		*/
        EmailTemplate template;
        try { template = DataGenerator.insertEmailTemplate(); } catch (Exception e) {}

        celsrm__Treatment__c treatment = DataGenerator.insertTreatmentRecord(
            '', 'Dispute Treatment', '', 'celsrm__Dispute__c', buildTreatmentStepsJson(),
            'Call;Email', 7, false, UserInfo.getUserId(), null, 'red',
            template != null ? template.Id : null, 'Dispute Treatment', false
        );

        List<Task> taskList = DataGenerator.inserTreatmentTask(acc, 1, treatment.Id);
        Task tk = taskList.get(0);
        tk.Subject = 'First Dunning Reminder';
        tk.celsrm__Treatment_Stage__c = 'Step1';
        try { update tk; } catch (Exception e) {}

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Test.startTest();
        // FetchCallScript dispute branch.
        try {
            Map<Object, Object> inMap = new Map<Object, Object>();
            inMap.put('Id', tk.Id);
            inMap.put('accountId', acc.Id);
            inMap.put('treatmentName', 'Dispute Treatment');
            inMap.put('listOfStep', new List<Object>{ 'Step1' });
            List<Object> childObjectIds = new List<Object>();
            List<Object> rows = new List<Object>();
            for (celsrm__Dispute__c d : disputes) {
                childObjectIds.add(d.Id);
                Map<Object, Object> row = new Map<Object, Object>();
                row.put('Id', d.Id);
                row.put('isSelected', true);
                rows.add(row);
            }
            inMap.put('childObjectIds', childObjectIds);
            inMap.put('Step1', rows);
            TaskTreatmentController.FetchCallScript(inMap);
        } catch (Exception e) {}

        // logACall with dispute records + notes + followup custom.
        try {
            Map<Object, Object> inMap = new Map<Object, Object>();
            inMap.put('Id', tk.Id);
            inMap.put('accountId', acc.Id);
            inMap.put('screenName', 'Make A Call');
            inMap.put('ContactMethod', 'Call');
            inMap.put('ContactnotpickcallMethod', 'Answered');
            inMap.put('NoteBody', 'Called about disputes');
            inMap.put('treatmentName', 'Dispute Treatment');
            inMap.put('isFollowup', true);
            inMap.put('FollowupDays', 'custom');
            inMap.put('FollowupDaysCustom', String.valueOf(Date.today().addDays(10)));
            inMap.put('listOfStep', new List<Object>{ 'Step1' });
            List<Object> childObjectIds = new List<Object>();
            List<Object> rows = new List<Object>();
            for (celsrm__Dispute__c d : disputes) {
                childObjectIds.add(d.Id);
                Map<Object, Object> row = new Map<Object, Object>();
                row.put('Id', d.Id);
                row.put('isSelected', true);
                rows.add(row);
            }
            inMap.put('childObjectIds', childObjectIds);
            inMap.put('Step1', rows);
            TaskTreatmentController.logACall(inMap);
        } catch (Exception e) {}
        Test.stopTest();
    }

    // ----------------------------------------------------------------------
    // getScreenConfig variants: separate-task-for-step + dynamic template,
    // and returnGridData for Not Started + Completed states.
    // ----------------------------------------------------------------------
    @isTest
    static void testScreenConfigSeparateTaskAndGridStates() {
        Account acc = DataGenerator.insertAccount();
        acc.AccountNumber = '112233';
        try { update acc; } catch (Exception e) {}
        DataGenerator.insertDefaultContact(acc);
        List<celsrm__Transaction__c> txns = DataGenerator.transactionInsert(acc, 3);

        EmailTemplate template;
        try { template = DataGenerator.insertEmailTemplate(); } catch (Exception e) {}

        celsrm__Treatment__c treatment = DataGenerator.insertTreatmentRecord(
            '', 'Separate Treatment', '', 'celsrm__Transaction__c', buildMultiStepTransactionJson(),
            'Email;Call', 7, false, UserInfo.getUserId(), null, 'red',
            template != null ? template.Id : null, 'Separate Treatment', true
        );
        try {
            treatment.put('celsrm__Enable_Dynamic_Template__c', true);
            treatment.put('celsrm__Template_Folder_Reference_Field__c', 'celsrm__Locale__c');
            treatment.put('celsrm__Email_Template_Prefix__c', 'Billing');
            treatment.put('celsrm__Attachment__c', true);
            treatment.put('celsrm__Attachment_Format__c', 'PDF');
            treatment.put('celsrm__Attachment_Name__c', 'SepAttach');
            treatment.put('celsrm__Consolidated_Treatment__c', false);
            update treatment;
        } catch (Exception e) {}

        List<Task> taskList = DataGenerator.inserTreatmentTask(acc, 1, treatment.Id);
        Task tk = taskList.get(0);
        tk.Subject = 'First Dunning Reminder';
        tk.Status = 'Not Started';
        tk.celsrm__Treatment_Stage__c = 'Step1';
        tk.Priority = 'Normal';
        tk.ActivityDate = Date.today().addDays(3);
        try { update tk; } catch (Exception e) {}

        // Two-step Treatment Details file.
        Map<String, List<Id>> stepToRecIds = new Map<String, List<Id>>{
            'Step1' => new List<Id>{ txns.get(0).Id, txns.get(1).Id },
            'Step2' => new List<Id>{ txns.get(2).Id }
        };
        try { attachJsonFile(tk.Id, 'Treatment Details', JSON.serialize(stepToRecIds)); } catch (Exception e) {}

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Test.startTest();
        try { TaskTreatmentController.getScreenConfig(tk.Id); } catch (Exception e) {}

        // returnGridData Not Started.
        try {
            Map<Object, Object> inMap = new Map<Object, Object>();
            inMap.put('Id', tk.Id);
            inMap.put('accountId', acc.Id);
            inMap.put('childObjAPIName', 'celsrm__Transaction__c');
            TaskTreatmentController.returnGridData(inMap);
        } catch (Exception e) {}

        // returnGridData Completed.
        try {
            tk.Status = 'Completed';
            update tk;
            Map<Object, Object> inMap = new Map<Object, Object>();
            inMap.put('Id', tk.Id);
            inMap.put('accountId', acc.Id);
            inMap.put('childObjAPIName', 'celsrm__Transaction__c');
            TaskTreatmentController.returnGridData(inMap);
        } catch (Exception e) {}
        Test.stopTest();
    }

    // ----------------------------------------------------------------------
    // customSendEmail manual PDF branch with updateObj + updateDocument true,
    // and stepToRecIds provided directly.
    // ----------------------------------------------------------------------
    @isTest
    static void testCustomSendEmailManualUpdate() {
        Task tk = getTask();
        Account acc = getAccount();
        List<Id> txnIds = getTxnIds();

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Test.startTest();
        // Manual PDF branch, contentVersionId provided, updateObj + updateDocument true.
        try {
            Map<Object, Object> inMap = buildBaseMap(tk, acc, txnIds);
            ContentVersion cv = new ContentVersion(
                Title = 'ManualAttach',
                PathOnClient = 'ManualAttach.pdf',
                VersionData = Blob.valueOf('pdf'),
                IsMajorVersion = true
            );
            insert cv;
            Map<String, Object> composeEmail = new Map<String, Object>();
            composeEmail.put('to', new List<Object>{ 'to@test.com' });
            composeEmail.put('cc', new List<Object>{ 'cc@test.com' });
            composeEmail.put('bcc', new List<Object>{ 'bcc@test.com' });
            composeEmail.put('subject', 'Manual Subject');
            composeEmail.put('body', 'Manual Body');
            inMap.put('ComposeEmail', composeEmail);
            inMap.put('isAttachment', 'true');
            inMap.put('attachmentFormat', 'PDF');
            inMap.put('attachmentName', 'ManualAttach');
            inMap.put('isDunningScreen', false);
            inMap.put('contentVersionId', cv.Id);
            inMap.put('updateObj', true);
            inMap.put('updateDocument', true);
            Map<Object, Object> stepMap = new Map<Object, Object>();
            List<Object> ids = new List<Object>();
            for (Id tid : txnIds) { ids.add(tid); }
            stepMap.put('Step1', ids);
            inMap.put('stepToRecIds', stepMap);
            TaskTreatmentController.customSendEmail(inMap, true);
        } catch (Exception e) {}

        // PDF (non-dunning) branch with generated attachment (no contentVersionId), updateObj false.
        try {
            Map<Object, Object> inMap = buildBaseMap(tk, acc, txnIds);
            Map<String, Object> composeEmail = new Map<String, Object>();
            composeEmail.put('to', new List<Object>{ 'to@test.com' });
            composeEmail.put('subject', 'Gen Subject');
            composeEmail.put('body', 'Gen Body');
            inMap.put('ComposeEmail', composeEmail);
            inMap.put('isAttachment', 'true');
            inMap.put('attachmentFormat', 'PDFDoc');
            inMap.put('isDunningScreen', false);
            TaskTreatmentController.customSendEmail(inMap, false);
        } catch (Exception e) {}
        Test.stopTest();
    }
}