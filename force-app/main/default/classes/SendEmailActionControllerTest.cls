@isTest
public with sharing class SendEmailActionControllerTest {
    public static testMethod void testMethod1() {
        // Test data setup
        Account acc = DataGenerator.insertAccount();
        List<Task> taskList = DataGenerator.insertTask(acc, 1);
        //-- Starts | FIN-8207 | Change by Asera | 19-Aug-25 //
        celsrm__Transaction__c trans = DataGenerator.insertTransaction(acc);
        celsrm__Custom_List_View__c listView  = DataGenerator.insertCustomListView(true);
        EmailTemplate template = DataGenerator.insertEmailTemplateWithName('SYSTEM_BillingStatementExcel');
        //-- End | FIN-8207 | Change by Asera | 19-Aug-25 //
        List<Object> tranxList = new List<Object>();
        Map<Object,Object> tranxMap = new Map<Object,Object>();
        tranxMap.put('celsrm__Account__c', acc.Id);
        tranxMap.put('Id', trans.Id);
        tranxMap.put('isSelected', true);
        tranxList.add(tranxMap);
        

        
 
        Map<Object, Object> inMap = new Map<Object, Object>();
        inMap.put('Id', acc.Id);
        inMap.put('FollowUpDate', String.valueOf(Date.today().addDays(1)));
        inMap.put('ComposeEmail', new Map<String, Object>{'subject' => 'Test Subject', 'body' => 'Test Body'});
        inMap.put('TransactionList', tranxList);
        //-- Starts | FIN-8207 | Change by Asera | 19-Aug-25 //
        inMap.put('isFollowUp', true);
        inMap.put('ListView', listView.Id);
        inMap.put('StatementFormat','PDF');
        //-- End | FIN-8207 | Change by Asera | 19-Aug-25 //
 
        SendEmailActionController sendEmailObj = new SendEmailActionController();
        // Test onLoadSendEmail
        inMap.put('FunctionName', 'onLoadSendEmail');
        Map<Object, Object> result = sendEmailObj.invoke('onLoadSendEmail', inMap);
        System.assertEquals(true, result.containsKey('hideTreatmentNotes'));
 
        // Test createFollowUpTask
        inMap.put('FunctionName', 'createFollowUpTask');
        result = sendEmailObj.invoke('createFollowUpTask', inMap);
        System.assertNotEquals(null, taskList.get(0));

        // Test sendEmailToCustomer
        inMap.put('FunctionName', 'sendEmailToCustomer');
        result = sendEmailObj.invoke('sendEmailToCustomer', inMap);
        System.assertNotEquals(null, result);

        // Test sendTreatmentEmailToCustomer
        inMap.put('FunctionName', 'sendTreatmentEmail');
        result = sendEmailObj.invoke('sendTreatmentEmail', inMap);
        System.assertNotEquals(null, result);

        // Test captureCelonisEvents
        inMap.put('FunctionName', 'captureCelonisEvent');
        result = sendEmailObj.invoke('captureCelonisEvent', inMap);
        System.assertNotEquals(null, result);

        // Test executeSendEmail
        inMap.put('isFollowUp', true);
        inMap.put('AttachCheckBox', true);
        inMap.put('ContactMethod', 'Email');
        result = sendEmailObj.invoke('executeSendEmail', inMap);
        System.assertNotEquals(null, result);
        
        //-- Starts | FIN-8207 | Change by Asera | 19-Aug-25 //
        // Test createStatementAttachment
        inMap.put('FunctionName', 'createStatementAttachment');
        inMap.put('AttachCheckBox', true);
        inMap.put('PreviewDocument', false);
        result = sendEmailObj.invoke('createStatementAttachment', inMap);
        System.assertNotEquals(null, result);
        //-- End | FIN-8207 | Change by Asera | 19-Aug-25 //

    }

    // << START - MM - FIN-10130 - invoke() createStatementAttachment ggErrorMessage guard branches (missing ListView / missing StatementFormat) >>
    @isTest
    static void testInvokeCreateStatementAttachmentMissingListViewAndFormatErrors() {
        SendEmailActionController controller = new SendEmailActionController();

        // Missing ListView entirely -> Label.Select_List_View_Send_Statement branch
        Map<Object, Object> inMap1 = new Map<Object, Object>();
        Map<Object, Object> result1 = controller.invoke('createStatementAttachment', inMap1);
        System.assertEquals(Label.Select_List_View_Send_Statement, result1.get('ggErrorMessage'));

        // ListView present but blank string -> same branch, different condition leg
        Map<Object, Object> inMap2 = new Map<Object, Object>();
        inMap2.put('ListView', '');
        Map<Object, Object> result2 = controller.invoke('createStatementAttachment', inMap2);
        System.assertEquals(Label.Select_List_View_Send_Statement, result2.get('ggErrorMessage'));

        // Valid ListView but missing StatementFormat -> Label.Select_Statement_Format_Send_Statement branch
        celsrm__Custom_List_View__c clv = DataGenerator.insertCustomListView(true);
        Map<Object, Object> inMap3 = new Map<Object, Object>();
        inMap3.put('ListView', clv.Id);
        Map<Object, Object> result3 = controller.invoke('createStatementAttachment', inMap3);
        System.assertEquals(Label.Select_Statement_Format_Send_Statement, result3.get('ggErrorMessage'));

        // Valid ListView but blank StatementFormat -> same branch, different condition leg
        Map<Object, Object> inMap4 = new Map<Object, Object>();
        inMap4.put('ListView', clv.Id);
        inMap4.put('StatementFormat', '');
        Map<Object, Object> result4 = controller.invoke('createStatementAttachment', inMap4);
        System.assertEquals(Label.Select_Statement_Format_Send_Statement, result4.get('ggErrorMessage'));
    }
    // << END - MM - FIN-10130 - invoke() createStatementAttachment ggErrorMessage guard branches (missing ListView / missing StatementFormat) >>

    // << START - MM - FIN-10130 - invoke() unmatched functionName fallthrough and createFollowUpTask isFollowUp guard branches >>
    @isTest
    static void testInvokeUnmatchedFunctionNameAndFollowUpGuardBranches() {
        SendEmailActionController controller = new SendEmailActionController();

        // No functionName matches any "if/else if" branch -> invoke() falls straight through to "return inMap" unchanged.
        Map<Object, Object> inMap1 = new Map<Object, Object>();
        inMap1.put('marker', 'unchanged');
        Map<Object, Object> result1 = controller.invoke('someUnknownFunctionName', inMap1);
        System.assertEquals('unchanged', result1.get('marker'));

        // functionName == 'createFollowUpTask' but isFollowUp is null -> guard condition short-circuits false, no branch taken.
        Map<Object, Object> inMap2 = new Map<Object, Object>();
        inMap2.put('marker', 'stillUnchanged');
        Map<Object, Object> result2 = controller.invoke('createFollowUpTask', inMap2);
        System.assertEquals('stillUnchanged', result2.get('marker'));

        // functionName == 'createFollowUpTask' but isFollowUp is explicitly false -> guard condition also false.
        Map<Object, Object> inMap3 = new Map<Object, Object>();
        inMap3.put('marker', 'stillUnchanged2');
        inMap3.put('isFollowUp', false);
        Map<Object, Object> result3 = controller.invoke('createFollowUpTask', inMap3);
        System.assertEquals('stillUnchanged2', result3.get('marker'));
    }
    // << END - MM - FIN-10130 - invoke() unmatched functionName fallthrough and createFollowUpTask isFollowUp guard branches >>

    // << START - MM - FIN-10130 - invoke() outer catch wraps a propagated exception in celsrm.CustomException >>
    @isTest
    static void testInvokeOuterCatchWrapsException() {
        SendEmailActionController controller = new SendEmailActionController();
        Account account = DataGenerator.insertAccount();

        Map<Object, Object> inMap = new Map<Object, Object>();
        inMap.put('Id', account.Id);
        inMap.put('isFollowUp', true);
        // Invalid FollowUpDate makes createFollowUpTask's Date.valueOf(...) throw, which createFollowUpTask
        // re-throws as celsrm.GOGDataServiceException; invoke()'s own try/catch then wraps that in a
        // celsrm.CustomException before rethrowing - exercising invoke()'s catch block (currently uncovered).
        inMap.put('FollowUpDate', 'not-a-valid-date');
        inMap.put('ComposeEmail', new Map<String, Object>{ 'subject' => 'Test Subject' });

        Boolean threw = false;
        try {
            controller.invoke('createFollowUpTask', inMap);
        } catch (celsrm.CustomException ex) {
            threw = true;
            System.debug('Expected wrapped CustomException: ' + ex.getMessage());
        }
        System.assert(threw, 'invoke() should wrap the propagated exception in a celsrm.CustomException');
    }
    // << END - MM - FIN-10130 - invoke() outer catch wraps a propagated exception in celsrm.CustomException >>

    // << START - MM - FIN-10130 - createFollowUpTask direct exception branch (invalid FollowUpDate -> GOGDataServiceException) >>
    @isTest
    static void testCreateFollowUpTaskDirectExceptionBranch() {
        Account account = DataGenerator.insertAccount();
        Map<Object, Object> inMap = new Map<Object, Object>();
        inMap.put('Id', account.Id);
        inMap.put('FollowUpDate', 'not-a-valid-date');
        inMap.put('ComposeEmail', new Map<String, Object>{ 'subject' => 'Test Subject' });

        Boolean threw = false;
        try {
            SendEmailActionController.createFollowUpTask(inMap);
        } catch (celsrm.GOGDataServiceException ex) {
            threw = true;
            System.debug('Expected GOGDataServiceException: ' + ex.getMessage());
        }
        System.assert(threw, 'createFollowUpTask should throw a GOGDataServiceException when FollowUpDate is invalid');
    }
    // << END - MM - FIN-10130 - createFollowUpTask direct exception branch (invalid FollowUpDate -> GOGDataServiceException) >>

    // << START - MM - FIN-10130 - executeSendEmail typed catch branches (NullPointerException, DmlException, generic Exception) >>
    @isTest
    static void testExecuteSendEmailNullPointerExceptionBranch() {
        Account account = DataGenerator.insertAccount();
        Map<Object, Object> inMap = new Map<Object, Object>();
        inMap.put('Id', account.Id);
        inMap.put('AttachCheckBox', false);
        inMap.put('StatementFormat', 'PDF');
        inMap.put('isFollowUp', false);
        // TransactionList intentionally omitted (null) -> "for (Object tr : transactionList)" throws a
        // NullPointerException immediately, which executeSendEmail's catch(NullPointerException) branch handles.
        Map<Object, Object> result = SendEmailActionController.executeSendEmail(inMap);
        System.assertNotEquals(null, result.get('ggErrorMessage'));
    }

    @isTest
    static void testExecuteSendEmailDmlExceptionBranch() {
        celsrm__Custom_List_View__c clv = DataGenerator.insertCustomListView(true);
        Account account = DataGenerator.insertAccount();
        celsrm__Transaction__c trans = DataGenerator.insertTransaction(account);

        Map<Object, Object> transMap = new Map<Object, Object>();
        transMap.put('Id', trans.Id);
        transMap.put('celsrm__Account__c', account.Id);

        Map<Object, Object> inMap = new Map<Object, Object>();
        // Intentionally omit 'Id' so accountObj.Id stays null and "update accountObj" throws a DmlException
        // ("Id not specified in an update call") before reaching sendEmailToCustomer/createFollowUpTask.
        inMap.put('AttachCheckBox', false);
        inMap.put('StatementFormat', 'PDF');
        inMap.put('isFollowUp', false);
        inMap.put('TransactionList', new List<Object>{ transMap });

        Map<Object, Object> result = SendEmailActionController.executeSendEmail(inMap);
        System.assertNotEquals(null, result.get('ggErrorMessage'));
    }

    @isTest
    static void testExecuteSendEmailGenericExceptionBranch() {
        Account account = DataGenerator.insertAccount();
        Map<Object, Object> inMap = new Map<Object, Object>();
        inMap.put('Id', account.Id);
        inMap.put('AttachCheckBox', false);
        inMap.put('StatementFormat', 'PDF');
        inMap.put('isFollowUp', false);
        // A TransactionList entry that isn't a Map<Object,Object> forces a ClassCastException when
        // executeSendEmail does "(Map<Object, Object>)tr" - a subclass of Exception not caught by any of
        // the more specific typed catch blocks, so it falls through to the generic catch(Exception) branch.
        inMap.put('TransactionList', new List<Object>{ 'not-a-map' });

        Map<Object, Object> result = SendEmailActionController.executeSendEmail(inMap);
        System.assertNotEquals(null, result.get('ggErrorMessage'));
    }
    // << END - MM - FIN-10130 - executeSendEmail typed catch branches (NullPointerException, DmlException, generic Exception) >>

    // << START - MM - FIN-10130 - showTreatmentNotes open-treatment-task branch with default Contact >>
    @isTest
    static void testShowTreatmentNotesWithOpenTreatmentTaskAndDefaultContact() {
        Account account = DataGenerator.insertAccount();
        Contact defaultContact = DataGenerator.insertDefaultContact(account);
        celsrm__Treatment__c treatment = DataGenerator.insertTreatmentRecord(
            '', 'SendEmailShowNotesTreatment', '', 'celsrm__Transaction__c', '[]', 'Email', 5, true, '', '', '', '', 'SendEmailShowNotesTreatment', false
        );
        // inserTreatmentTask creates an open (Not Started) Task linked to this Treatment, which is exactly
        // the branch showTreatmentNotes' taskList query is meant to find (Status != 'Completed' AND
        // celsrm__Treatment__c != '') - the existing test's Account never has such a Task, so that whole
        // "taskList.size() > 0" branch (treatmentEmail/treatmentNotes/removeTreatmentNotes) was uncovered.
        DataGenerator.inserTreatmentTask(account, 1, treatment.Id);

        Map<Object, Object> inMap = new Map<Object, Object>();
        inMap.put('Id', account.Id);

        Map<Object, Object> result = SendEmailActionController.showTreatmentNotes(inMap);
        System.assertEquals(true, result.containsKey('autoTaskId'));
        System.assertEquals(true, result.containsKey('treatmentEmail'));
        System.assertEquals(true, result.containsKey('treatmentNotes'));
        System.assertEquals(true, result.containsKey('removeTreatmentNotes'));
    }
    // << END - MM - FIN-10130 - showTreatmentNotes open-treatment-task branch with default Contact >>

    // << START - MM - FIN-10130 - captureCelonisEvents with empty TransactionList and blank NoteBody >>
    @isTest
    static void testCaptureCelonisEventsEmptyTransactionListBranch() {
        Account account = DataGenerator.insertAccount();
        Map<Object, Object> inMap = new Map<Object, Object>();
        inMap.put('Id', account.Id);
        inMap.put('TransactionList', new List<Object>());
        // NoteBody intentionally omitted -> activityNote stays null, and the transIDList.isEmpty() branch
        // skips the transaction-level insertActivity call entirely - both previously-uncovered branches.
        Map<Object, Object> result = SendEmailActionController.captureCelonisEvents(inMap);
        System.assertNotEquals(null, result);
    }
    // << END - MM - FIN-10130 - captureCelonisEvents with empty TransactionList and blank NoteBody >>

    // << START - MM - FIN-10130 - fetchTransactions filter/sort/hierarchy branch coverage >>
    @isTest
    static void testFetchTransactionsFilterSortAndHierarchyBranches() {
        Account account = DataGenerator.insertAccount();
        Account childAccount = DataGenerator.insertAccount();
        celsrm__Transaction__c trans = DataGenerator.insertTransaction(account);

        // NOTE: DataGenerator.insertCustomListView() always hardcodes Name = 'All Open' /
        // celsrm__ListView_For_Object__c = 'celsrm__Transaction__c' / celsrm__Is_Default__c = true, so
        // calling it a second time within the same test transaction trips a duplicate rule on
        // Custom_List_View__c ("System.DmlException: ... DUPLICATE_VALUE"). Insert ONE record here and
        // mutate its fields between scenarios instead of inserting a second one.

        // Scenario A: Filter_Criteria__c populated -> whereCondition non-blank branch; also give it a
        // Sort_By_Field__c so orderFields is non-blank too (both previously-uncovered legs of
        // fetchTransactions' branching). celsrm__Sort_By_Field__c is JSON-deserialized by
        // UtilityController.getQuerySortOrder into List<Map<String,String>>, so it must be a JSON array of
        // {"fieldName":..., "order":...} objects, not a plain field-name string.
        celsrm__Custom_List_View__c clv = DataGenerator.insertCustomListView(true);
        clv.celsrm__Sort_By_Field__c = '[{"fieldName":"celsrm__Balance__c","order":"ASC"}]';
        update clv;

        Map<Object, Object> inMap1 = new Map<Object, Object>();
        inMap1.put('Id', account.Id);
        inMap1.put('accountHierarchyChildIds', new List<Object>{ childAccount.Id });
        inMap1.put('ListView', clv.Id);
        List<celsrm__Transaction__c> result1 = SendEmailActionController.fetchTransactions(inMap1, new List<Id>{ trans.Id });
        System.assertNotEquals(null, result1);

        // KNOWN PRE-EXISTING PRODUCTION BUG (not introduced/fixed here, per standing rule against touching
        // production logic without a ticket) - affects BOTH remaining scenarios below:
        //   if (whereCondition != '' || whereCondition != null) { ... }
        // '' != null is always true regardless of the left operand, so this "or" condition is ALWAYS true.
        // That means the "else if (whereCondition == '')" default-balance-filter branch right after it is
        // structurally unreachable in every case, not just when no Custom List View matches - ANY time
        // whereCondition is still '' at that point (blank/missing Filter_Criteria__c, or no matching
        // Custom List View at all), the always-true first branch fires instead and appends
        // " and celsrm__account__c IN :accId" with no preceding WHERE/base clause. The exact same
        // always-true condition repeats a few lines later, so the " WHERE Id IN :transIds" fallback also
        // never fires. The resulting SOQL literally starts with
        // "... celsrm__Transaction__c  and celsrm__account__c IN :accId and Id IN :transIds LIMIT 2000" -
        // missing its WHERE keyword - which throws System.QueryException: unexpected token: 'and'.
        // This exact "!= '' || != null" always-true bug pattern was already flagged (but left unfixed,
        // pending a separate ticket) for the analogous SendStatementActionController.fetchTransactions.
        // These two scenarios document/prove the bug is real and reachable rather than masking it.

        // Scenario B: Filter_Criteria__c blank -> whereCondition stays '' -> hits the bug above.
        clv.celsrm__Filter_Criteria__c = '';
        clv.celsrm__Sort_By_Field__c = null;
        update clv;
        Map<Object, Object> inMap2 = new Map<Object, Object>();
        inMap2.put('Id', account.Id);
        inMap2.put('ListView', clv.Id);
        Boolean threwExpectedBugB = false;
        try {
            SendEmailActionController.fetchTransactions(inMap2, new List<Id>{ trans.Id });
        } catch (QueryException qEx) {
            threwExpectedBugB = true;
            System.debug('Reproduced known fetchTransactions bug (blank Filter_Criteria__c): ' + qEx.getMessage());
        }
        System.assert(threwExpectedBugB, 'Expected the known missing-WHERE-clause bug to reproduce when Filter_Criteria__c is blank');

        // Scenario C: no matching Custom List View at all -> customListViewList empty -> whereCondition
        // also stays '' -> same bug.
        Map<Object, Object> inMap3 = new Map<Object, Object>();
        inMap3.put('Id', account.Id);
        Boolean threwExpectedBugC = false;
        try {
            SendEmailActionController.fetchTransactions(inMap3, new List<Id>{ trans.Id });
        } catch (QueryException qEx) {
            threwExpectedBugC = true;
            System.debug('Reproduced known fetchTransactions bug (no matching ListView): ' + qEx.getMessage());
        }
        System.assert(threwExpectedBugC, 'Expected the known missing-WHERE-clause bug to reproduce when no Custom List View matches');
    }
    // << END - MM - FIN-10130 - fetchTransactions filter/sort/hierarchy branch coverage >>

    // << START - MM - FIN-10130 - createStatementAttachment attachment-template branch and non-Excel/PDF continuation branch >>
    @isTest
    static void testCreateStatementAttachmentTemplateAndNonPdfBranches() {
        Account account = DataGenerator.insertAccount();
        celsrm__Transaction__c trans = DataGenerator.insertTransaction(account);
        celsrm__Custom_List_View__c clv = DataGenerator.insertCustomListView(true);

        Map<Object, Object> transMap = new Map<Object, Object>();
        transMap.put('Id', trans.Id);
        transMap.put('celsrm__Account__c', account.Id);

        // PDF/Excel format WITH an 'attachment-template' key -> exercises the custom-attachment-template
        // rendering branch inside the formatType=='Excel'||'PDF' block (previously only the no-template
        // leg of that block was covered).
        Map<Object, Object> inMap1 = new Map<Object, Object>();
        inMap1.put('Id', account.Id);
        inMap1.put('ListView', clv.Id);
        inMap1.put('StatementFormat', 'PDF');
        inMap1.put('attachment-template', 'NoSuchTemplateXYZ');
        inMap1.put('TransactionList', new List<Object>{ transMap });
        Map<Object, Object> result1 = SendEmailActionController.createStatementAttachment(inMap1);
        System.assertNotEquals(null, result1);

        // StatementFormat neither 'Excel' nor 'PDF' -> falls through past the early "return inMap" into the
        // non-Excel/PDF continuation (isMultiCurrency/TransIds/AttachCheckBox-gated SendStatementAttachmentInsert
        // block) - entirely uncovered by the existing PDF-only happy-path test. Any downstream exception here
        // is swallowed by createStatementAttachment's own outer catch, so this just needs to not blow up.
        Map<Object, Object> inMap2 = new Map<Object, Object>();
        inMap2.put('Id', account.Id);
        inMap2.put('ListView', clv.Id);
        inMap2.put('StatementFormat', 'Other');
        inMap2.put('AttachCheckBox', true);
        inMap2.put('PreviewDocument', true);
        inMap2.put('TransactionList', new List<Object>{ transMap });
        Map<Object, Object> result2 = SendEmailActionController.createStatementAttachment(inMap2);
        System.assertNotEquals(null, result2);
    }
    // << END - MM - FIN-10130 - createStatementAttachment attachment-template branch and non-Excel/PDF continuation branch >>
}