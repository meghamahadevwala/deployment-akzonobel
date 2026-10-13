//-- Starts | FIN-8207 | Change by Asera | 04-Sep-25 //
@isTest
public with sharing class UtilityControllerTest {
    @isTest
    static void testEqualsOperator() {
        String filterJson = '[{"Field":"Name","Operator":"equals","Value":"Test Account","LogicalOperator":"AND"}]';
        String result = UtilityController.createFilterCriteria(filterJson, 'Account');
    }

    @IsTest
    static void testGetNotesFromAccount() {
        Account acc = new Account(Name = 'Test Acc');
        acc = UtilityController.getNotesFromAccount(acc, 'Old Note', 'Meeting', 'Discussed updates', 'Template1');

        celsrm__Transaction__c trx = new celsrm__Transaction__c();
        trx = UtilityController.getNotesFromTransaction(trx,'Old transaction note','Call','Customer requested details','Template1');

        celsrm__Dispute__c dis = new celsrm__Dispute__c();
        dis = UtilityController.getNotesFromTransaction(dis,'Old dispute note', 'Review', 'Documents missing', 'Template2');

        SObject updatedAcc = UtilityController.getNotesFromSObject( acc,'Old Note', 'Email', 'Reminder sent to customer', 'Template1', 'John Doe');
    }
   
    @IsTest
    static void testWithMapEmail() {
        Map<Object, Object> emailMap = new Map<Object, Object>{ 'value' => 'user2@example.com' };
        List<Object> toAddressObj = new List<Object>{ emailMap };
        
        String contactName = UtilityController.getDefaultContactName(toAddressObj);
    }

    @isTest
    static void test_getQuerySortOrder() {
        String jsonInput = '[{"fieldName":"Name","order":"DESC"},{"fieldName":"CreatedDate"}]';
        String result = UtilityController.getQuerySortOrder(jsonInput, true);
        String result2 = UtilityController.getQuerySortOrder(jsonInput, false);   
    }

    @isTest
    static void testShouldNotifyAccountOwnerFromTreatment() {
        Task tsk = new Task(Subject = 'Proactive Email');
        celsrm__Treatment__c treatment = new celsrm__Treatment__c();
        treatment.celsrm__Seperate_Task_For_Step__c = false;
        treatment.celsrm__Notify_Account_Owner__c = true;

        System.assertEquals(true, UtilityController.shouldNotifyAccountOwner(tsk, treatment));
    }

    @isTest
    static void testShouldNotifyAccountOwnerFromStepJson() {
        Task tsk = new Task(Subject = 'Proactive Email');
        tsk.celsrm__Treatment_Stage__c = 'Proactive Email';

        celsrm__Treatment__c treatment = new celsrm__Treatment__c();
        treatment.celsrm__Seperate_Task_For_Step__c = true;
        treatment.celsrm__Notify_Account_Owner__c = false;
        treatment.celsrm__Treatment_Steps__c = '[{"stepName":"Proactive Email","taskSubject":"Proactive Email","notifyAccountOwner":true}]';

        System.assertEquals(true, UtilityController.shouldNotifyAccountOwner(tsk, treatment));
    }

    //-- FIN-9729 | Changed by Dilshad | 05-May-2026 | Start --//
    @isTest
    static void testBuildTransactionQueryContextAndFetchTransactions() {
        Account acc = DataGenerator.insertAccount();
        List<celsrm__Transaction__c> transactions = DataGenerator.transactionInsert(acc, 2);
        transactions[0].celsrm__Balance__c = 10;
        transactions[1].celsrm__Balance__c = 20;
        update transactions;
        celsrm__Custom_List_View__c listView = buildFin9729ListView('FIN9729 Query Context View', true);

        Map<Object, Object> inMap = new Map<Object, Object>{
            'ListView' => listView.Id,
            'TransactionList' => buildTransactionSelection(transactions[0].Id)
        };
        Set<String> accountIds = new Set<String>{ acc.Id };

        Test.startTest();
        UtilityController.TransactionQueryContext queryContext = UtilityController.buildTransactionQueryContext(inMap, accountIds);
        List<celsrm__Transaction__c> filteredTransactions = UtilityController.fetchTransactions(queryContext, 10);
        Test.stopTest();

        Map<String, String> selectedFieldTypes = (Map<String, String>)JSON.deserialize(
            queryContext.selectedFieldsType,
            Map<String, String>.class
        );

        System.assertEquals(1, filteredTransactions.size(), 'Only the selected transaction should be returned.');
        System.assertEquals(transactions[0].Id, filteredTransactions[0].Id, 'The selected transaction id should round-trip into the query context.');
        System.assert(queryContext.selectedFields.contains('Name'), 'The query context should include exported list view fields.');
        System.assertEquals('currency', selectedFieldTypes.get('celsrm__Balance__c'), 'Selected field types should be serialized from the list view definition.');
        System.assert(queryContext.whereCondition.contains('celsrm__Account__c IN :accountIds'), 'The account filter should be applied to the query context.');
        System.assert(queryContext.whereCondition.contains('Id IN :transactionIds'), 'The transaction filter should be applied when TransactionList is provided.');
        System.assert(queryContext.orderFields.contains('ORDER BY'), 'The query context should include sort order when configured.');
        System.assertEquals(1, queryContext.transactionIds.size(), 'Transaction ids should be extracted from the input map.');
    }

    @isTest
    static void testFetchTransactionsOverloadsAndTotalBalanceSummary() {
        Account acc = DataGenerator.insertAccount();
        List<celsrm__Transaction__c> transactions = DataGenerator.transactionInsert(acc, 2);
        transactions[0].celsrm__Balance__c = 10;
        transactions[1].celsrm__Balance__c = 20;
        update transactions;

        UtilityController.TransactionQueryContext queryContext = new UtilityController.TransactionQueryContext();
        queryContext.selectedFields = new List<String>{ 'Name', 'celsrm__Balance__c' };
        queryContext.whereCondition = 'WHERE celsrm__Account__c IN :accountIds';
        queryContext.orderFields = 'ORDER BY Name ASC';
        queryContext.accountIds.add(acc.Id);

        Test.startTest();
        List<celsrm__Transaction__c> queryContextTransactions = UtilityController.fetchTransactions(queryContext);
        List<celsrm__Transaction__c> overloadedTransactions = UtilityController.fetchTransactions(
            new List<String>{ 'Name', 'celsrm__Balance__c' },
            'WHERE Id = \'' + transactions[0].Id + '\'',
            'ORDER BY Name ASC'
        );
        String totalBalance = UtilityController.getTransactionTotalBalanceString(queryContext, null);
        Map<String, String> totalSummary = UtilityController.getTransactionTotalSummary(queryContext, null);
        Test.stopTest();

        System.assertEquals(2, queryContextTransactions.size(), 'The query-context overload should return both account transactions.');
        System.assertEquals(1, overloadedTransactions.size(), 'The legacy overload should still support direct where/order inputs.');
        System.assertEquals(transactions[0].Id, overloadedTransactions[0].Id, 'The direct overload should honor the provided where clause.');
        System.assert(!String.isBlank(totalBalance), 'A total-balance summary should be returned for matching transactions.');
        System.assert(totalBalance.contains('30'), 'The total-balance summary should include the summed balance value.');
        System.assertEquals(totalBalance, totalSummary.get('TotalBalance'), 'The summary helper should wrap the balance string without changing it.');
    }

    @isTest
    static void testBuildTransactionQueryContextUsesProvidedSortWhenAvailable() {
        Account acc = DataGenerator.insertAccount();
        celsrm__Custom_List_View__c listView = buildFin9729ListView('FIN9729 Sort Override View', true);

        Map<Object, Object> inMap = new Map<Object, Object>{
            'ListView' => listView.Id,
            'TransactionList_SortColumn' => 'celsrm__Balance__c',
            'TransactionList_SortOrder' => 'DESC'
        };

        Test.startTest();
        UtilityController.TransactionQueryContext queryContext = UtilityController.buildTransactionQueryContext(
            inMap,
            new Set<String>{ acc.Id }
        );
        Test.stopTest();

        System.assertEquals('ORDER BY celsrm__Balance__c DESC', queryContext.orderFields, 'The runtime sort parameters should override the list-view sort for the new query-context flow.');
    }

    @isTest
    static void testBuildTransactionQueryContextIgnoresTextAreaSortOverride() {
        Account acc = DataGenerator.insertAccount();
        celsrm__Custom_List_View__c listView = buildFin9729ListView('FIN9729 TextArea Sort Guard View', true);

        Map<Object, Object> inMap = new Map<Object, Object>{
            'ListView' => listView.Id,
            'TransactionList_SortColumn' => 'celsrm__Latest_Note__c',
            'TransactionList_SortOrder' => 'DESC'
        };

        Test.startTest();
        UtilityController.TransactionQueryContext queryContext = UtilityController.buildTransactionQueryContext(
            inMap,
            new Set<String>{ acc.Id }
        );
        Test.stopTest();

        System.assertEquals('ORDER BY Name ASC', queryContext.orderFields, 'Text-area sort parameters should be ignored and the list-view sort should remain in place.');
    }

    @isTest
    static void testTranslatedLabelHelpersFallbackAndGuards() {
        Test.startTest();
        List<String> resolvedLabels = UtilityController.getTranslatedLabelValues(
            'en',
            'celsrm__Transaction__c',
            new List<String>{ 'Name', 'missing_field__c', '' }
        );
        String unchangedTemplate = UtilityController.replaceAttachmentTemplateTranslatedPlaceholders(
            '<div>{Template.StatementTitle}</div>',
            ''
        );
        String nullBalance = UtilityController.getTransactionTotalBalanceString(null, null);
        List<celsrm__Transaction__c> nullContextTransactions = UtilityController.fetchTransactions((UtilityController.TransactionQueryContext)null);
        Test.stopTest();

        System.assertEquals(3, resolvedLabels.size(), 'Each requested label key should produce an output value.');
        System.assertEquals('missing_field__c', resolvedLabels[1], 'Unknown field keys should fall back to the original token.');
        System.assertEquals('', resolvedLabels[2], 'Blank field keys should be preserved.');
        System.assertEquals('<div>{Template.StatementTitle}</div>', unchangedTemplate, 'Blank language codes should leave placeholders unchanged.');
        System.assertEquals('', nullBalance, 'A null query context should return an empty balance summary.');
        System.assertEquals(0, nullContextTransactions.size(), 'A null query context should return no transactions.');
    }

    @isTest
    static void testGetPackageNamespaceHelpers() {
        Test.startTest();
        String packageNamespace = UtilityController.getPackageNamespace();
        String packageNamespacePrefix = UtilityController.getPackageNamespacePrefix();
        Test.stopTest();

        String expectedNamespace = Schema.getGlobalDescribe().containsKey('Transaction__c') ? '' : 'celsrm';
        String expectedNamespacePrefix = String.isBlank(expectedNamespace) ? '' : expectedNamespace + '__';

        System.assertEquals(expectedNamespace, packageNamespace, 'The namespace helper should return blank in dev orgs and the managed namespace in subscriber orgs.');
        System.assertEquals(expectedNamespacePrefix, packageNamespacePrefix, 'The namespace prefix helper should append the Salesforce namespace separator only when a namespace exists.');
    }
    //-- FIN-9729 | Changed by Dilshad | 05-May-2026 | End --//
    
    @testSetup
    static void setupTestData() {
        // Create test Account
        Account acc = DataGenerator.insertAccount();
        celsrm__Transaction__c trans = DataGenerator.insertTransaction(acc);
        List<Contact> cont = DataGenerator.insertContact(acc, 2);
        List<String> idList = new List<String>{ acc.Id };



        // Build input map
        Map<Object, Object> inMap = new Map<Object, Object>();
        inMap.put('Id', acc.Id);
        inMap.put('NoteBody', 'Test note for call');
        inMap.put('PhoneType', 'Mobile');
        inMap.put('ResponseByContact', 'Yes');
        inMap.put('ContactName', cont[0].Id);
        
        // Add transaction list
        List<Object> trxList = new List<Object>();
        Map<Object, Object> trxMap = new Map<Object, Object>();
        trxMap.put('Id', trans.Id);
        trxList.add(trxMap);
        inMap.put('TransactionList', trxList);
        
        Map<Object, Object> result = UtilityController.captureCelonisEventsOld(inMap, 'Log A Call');
        Map<Object, Object> result1 = UtilityController.captureCelonisEvents(inMap, idList, 'Account', 'Log A Call');
    }
    
    //-- FIN-9729 | Changed by Dilshad | 05-May-2026 | Start --//
    private static celsrm__Custom_List_View__c buildFin9729ListView(String viewName, Boolean includeSortOrder) {
        celsrm__Custom_List_View__c listView = new celsrm__Custom_List_View__c();
        listView.Name = viewName;
        listView.celsrm__User__c = UserInfo.getUserId();
        listView.celsrm__Is_Global__c = true;
        listView.celsrm__ListView_For_Object__c = 'celsrm__Transaction__c';
        listView.celsrm__Object_Fields__c =
            '[{"isExport":true,"hide":false,"type":"link","fieldName":"Name"},' +
            '{"isExport":true,"hide":false,"type":"currency","fieldName":"celsrm__Balance__c"},' +
            '{"isExport":true,"hide":false,"type":"date","fieldName":"celsrm__Due_Date__c"}]';
        if (includeSortOrder) {
            listView.celsrm__Sort_By_Field__c = '[{"fieldName":"Name","order":"ASC"}]';
        }
        insert listView;
        return listView;
    }

    private static List<Object> buildTransactionSelection(Id transactionId) {
        List<Object> selectedTransactions = new List<Object>();
        selectedTransactions.add(new Map<Object, Object>{ 'Id' => transactionId });
        return selectedTransactions;
    }
    //-- FIN-9729 | Changed by Dilshad | 05-May-2026 | End --//
}
//-- End | FIN-8207 | Change by Asera | 04-Sep-25 //