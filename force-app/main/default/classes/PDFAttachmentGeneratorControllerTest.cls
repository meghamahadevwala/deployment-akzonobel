@isTest
private class PDFAttachmentGeneratorControllerTest {
    @testSetup
    static void setupData() {
        Account accountRecord = DataGenerator.insertAccount();
        DataGenerator.insertContact(accountRecord);
        DataGenerator.transactionInsert(accountRecord, 2);

        insert buildListView();
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs(thisUser) {
            insert buildEmailTemplate('TestStatementPdfTemplate');
        }
    }

    @isTest
    static void testGeneratePDFAttachmentCreatesContentVersion() {
        Account accountRecord = [SELECT Id FROM Account LIMIT 1];
        celsrm__Custom_List_View__c listView = [SELECT Id FROM celsrm__Custom_List_View__c WHERE Name = 'Statement Pdf Test View' LIMIT 1];
        String tempKeyPrefix = PDFAttachmentGeneratorController.createStatementPdfTableHtmlTempChunks(
            createTestStatementTableHtml(),
            200
        );

        Map<Object, Object> inputMap = new Map<Object, Object>{
            'Id' => accountRecord.Id,
            'ListView' => listView.Id,
            'fileName' => 'Billing/Statement',
            'statementTableHtmlKey' => tempKeyPrefix,
            'ComposeEmail' => new Map<Object, Object>{
                'attachment' => new List<Object>()
            }
        };

        Test.startTest();
        Map<Object, Object> result = SendStatementActionController.generatePDFAttachment(inputMap);
        Test.stopTest();
        PDFAttachmentGeneratorController.deleteStatementPdfTempChunks(tempKeyPrefix);

        System.assertNotEquals(null, result.get('ContentIDSendStmt'), 'A ContentVersion Id should be returned.');
        System.assertNotEquals(null, result.get('ContentDocID'), 'A ContentDocument Id should be returned.');
        System.assertEquals(null, result.get('AttachmentIDSendStmt'), 'Legacy Attachment Id should not be populated.');
        System.assertEquals(null, result.get('ComposeEmail'), 'The generated PDF should not be merged into ComposeEmail during generation.');

        Id generatedVersionId = (Id)result.get('ContentIDSendStmt');
        ContentVersion generatedVersion = [
            SELECT Id, ContentDocumentId, Title, PathOnClient
            FROM ContentVersion
            WHERE Id = :generatedVersionId
            LIMIT 1
        ];
        System.assertEquals('Billing_Statement', generatedVersion.Title, 'The file name should be sanitized before save.');
        System.assertEquals('Billing_Statement.pdf', generatedVersion.PathOnClient, 'The generated file should be saved as a PDF.');
    }

    @isTest
    static void testEstimatePDFAttachmentHtmlBytesReturnsPositiveSize() {
        Account accountRecord = [SELECT Id FROM Account LIMIT 1];
        Contact contactRecord = [SELECT Id FROM Contact WHERE AccountId = :accountRecord.Id LIMIT 1];
        celsrm__Custom_List_View__c listView = [SELECT Id FROM celsrm__Custom_List_View__c WHERE Name = 'Statement Pdf Test View' LIMIT 1];
        String tempKeyPrefix = PDFAttachmentGeneratorController.createStatementPdfTableHtmlTempChunks(
            createTestStatementTableHtml(),
            200
        );

        Map<Object, Object> inputMap = new Map<Object, Object>{
            'Id' => accountRecord.Id,
            'ListView' => listView.Id,
            'StatementFormat' => 'PDF',
            'fileName' => 'Billing Statement',
            'attachment-template' => 'TestStatementPdfTemplate',
            'ContactName' => contactRecord.Id,
            'statementTableHtmlKey' => tempKeyPrefix
        };

        Test.startTest();
        Integer estimatedPdfHtmlBytes = PDFAttachmentGeneratorController.estimateStatementPdfHtmlBytes(inputMap);
        Test.stopTest();
        PDFAttachmentGeneratorController.deleteStatementPdfTempChunks(tempKeyPrefix);

        System.assert(estimatedPdfHtmlBytes > 0, 'The estimated HTML size should be positive.');
    }

    @isTest
    static void testControllerBuildsAttachmentBodyFromTemplate() {
        Account accountRecord = [SELECT Id FROM Account LIMIT 1];
        Contact contactRecord = [SELECT Id FROM Contact WHERE AccountId = :accountRecord.Id LIMIT 1];
        celsrm__Custom_List_View__c listView = [SELECT Id FROM celsrm__Custom_List_View__c WHERE Name = 'Statement Pdf Test View' LIMIT 1];
        String tempKeyPrefix = PDFAttachmentGeneratorController.createStatementPdfTableHtmlTempChunks(
            createTestStatementTableHtml(),
            200
        );

        Test.setCurrentPage(Page.PDFAttachmentGenerator);
        ApexPages.currentPage().getParameters().put('accountId', accountRecord.Id);
        ApexPages.currentPage().getParameters().put('listView', listView.Id);
        ApexPages.currentPage().getParameters().put('fileName', 'Billing Statement');
        ApexPages.currentPage().getParameters().put('attachmentTemplate', 'TestStatementPdfTemplate');
        ApexPages.currentPage().getParameters().put('contactId', contactRecord.Id);
        ApexPages.currentPage().getParameters().put('statementTableHtmlKey', tempKeyPrefix);

        Test.startTest();
        PDFAttachmentGeneratorController controller = new PDFAttachmentGeneratorController();
        Test.stopTest();
        PDFAttachmentGeneratorController.deleteStatementPdfTempChunks(tempKeyPrefix);

        System.assertNotEquals('', controller.attachmentBody, 'The VF controller should expose the final attachment body.');
        System.assertNotEquals(null, controller.attachmentStyles, 'The VF controller should expose style markup separately for the page head.');
        System.assert(!controller.attachmentBody.contains('Unable to generate statement PDF.'), 'The VF controller should not fall back to the error body.');
        System.assertEquals(-1, controller.attachmentBody.toLowerCase().indexOf('<style'), 'The rendered body should not contain style blocks.');
        System.assert(controller.attachmentStyles.toLowerCase().contains('<style'), 'The page head should receive the extracted styles.');
        System.assert(controller.attachmentBody.contains('Test Statement PDF'), 'The rendered template body should be included.');
        System.assertEquals(-1, controller.attachmentBody.indexOf('{Transactions.TotalBalance}'), 'The total-balance token should be replaced in the final body.');
        System.assert(controller.attachmentBody.toLowerCase().contains('<thead>'), 'The uploaded summary table should be preserved in the final body.');
        System.assert(controller.attachmentBody.contains('testno0'), 'The final body should include the uploaded transaction table content.');
        String estimateTempKeyPrefix = PDFAttachmentGeneratorController.createStatementPdfTableHtmlTempChunks(
            createTestStatementTableHtml(),
            200
        );
        String estimatedHtml = PDFAttachmentGeneratorController.buildStatementPDFHTML(new Map<Object, Object>{
            'Id' => accountRecord.Id,
            'ListView' => listView.Id,
            'StatementFormat' => 'PDF',
            'fileName' => 'Billing Statement',
            'attachment-template' => 'TestStatementPdfTemplate',
            'ContactName' => contactRecord.Id,
            'statementTableHtmlKey' => estimateTempKeyPrefix
        });
        PDFAttachmentGeneratorController.deleteStatementPdfTempChunks(estimateTempKeyPrefix);
        System.assert(estimatedHtml.toLowerCase().contains('<thead>'), 'The summary table HTML helper should still render a thead for VF PDF repeat headers.');
        System.assert(estimatedHtml.toLowerCase().contains('<tbody>'), 'The summary table HTML helper should still render a tbody section.');
    }

    @isTest
    static void testControllerUsesPrebuiltStatementTableHtmlWhenProvided() {
        Account accountRecord = [SELECT Id FROM Account LIMIT 1];
        Contact contactRecord = [SELECT Id FROM Contact WHERE AccountId = :accountRecord.Id LIMIT 1];
        celsrm__Custom_List_View__c listView = [SELECT Id FROM celsrm__Custom_List_View__c WHERE Name = 'Statement Pdf Test View' LIMIT 1];
        String tableHtml = '<table class="txSummaryTable"><thead><tr><th>Document</th></tr></thead><tbody><tr><td>发票 1001</td></tr></tbody></table>';

        Test.startTest();
        String tempKeyPrefix = PDFAttachmentGeneratorController.createStatementPdfTableHtmlTempChunks(tableHtml, 50);
        Test.setCurrentPage(Page.PDFAttachmentGenerator);
        ApexPages.currentPage().getParameters().put('accountId', accountRecord.Id);
        ApexPages.currentPage().getParameters().put('listView', listView.Id);
        ApexPages.currentPage().getParameters().put('fileName', 'Billing Statement');
        ApexPages.currentPage().getParameters().put('attachmentTemplate', 'TestStatementPdfTemplate');
        ApexPages.currentPage().getParameters().put('contactId', contactRecord.Id);
        ApexPages.currentPage().getParameters().put('statementTableHtmlKey', tempKeyPrefix);

        PDFAttachmentGeneratorController controller = new PDFAttachmentGeneratorController();
        PDFAttachmentGeneratorController.deleteStatementPdfTempChunks(tempKeyPrefix);
        Test.stopTest();

        System.assertNotEquals('', controller.attachmentBody, 'The controller should render the attachment body directly when prebuilt table HTML is provided.');
        System.assert(controller.attachmentBody.contains('发票 1001'), 'The prebuilt multilingual table HTML should be merged into the PDF body.');
    }

    @isTest
    static void testControllerUsesGenericPrebuiltAttachmentHtmlWhenProvided() {
        Account accountRecord = [SELECT Id FROM Account LIMIT 1];
        String tempKeyPrefix = PDFAttachmentGeneratorController.createStatementPdfTableHtmlTempChunks(
            createTestAttachmentHtml(),
            50
        );

        Test.startTest();
        Test.setCurrentPage(Page.PDFAttachmentGenerator);
        ApexPages.currentPage().getParameters().put('accountId', accountRecord.Id);
        ApexPages.currentPage().getParameters().put('fileName', 'Treatment Attachment');
        ApexPages.currentPage().getParameters().put('prebuiltAttachmentHtmlKey', tempKeyPrefix);

        PDFAttachmentGeneratorController controller = new PDFAttachmentGeneratorController();
        PDFAttachmentGeneratorController.deleteStatementPdfTempChunks(tempKeyPrefix);
        Test.stopTest();

        System.assertNotEquals('', controller.attachmentBody, 'The controller should render generic prebuilt attachment HTML when provided.');
        System.assert(controller.attachmentBody.contains('Treatment Summary'), 'The generic attachment body content should be preserved.');
        System.assertEquals(-1, controller.attachmentBody.toLowerCase().indexOf('<style'), 'The generic attachment body should have styles extracted for the page head.');
        System.assert(controller.attachmentStyles.toLowerCase().contains('<style'), 'The page head should receive extracted styles for generic attachment HTML.');
    }

    @isTest
    static void testTaskTreatmentGeneratePDFAttachmentCreatesContentVersion() {
        Account accountRecord = [SELECT Id FROM Account LIMIT 1];
        String tempKeyPrefix = PDFAttachmentGeneratorController.createStatementPdfTableHtmlTempChunks(
            createTestAttachmentHtml(),
            50
        );

        Test.startTest();
        Map<Object, Object> result = TaskTreatmentController.generatePDFAttachment(new Map<Object, Object>{
            'accountId' => accountRecord.Id,
            'fileName' => 'Treatment/Test',
            'prebuiltAttachmentHtmlKey' => tempKeyPrefix
        });
        Test.stopTest();
        PDFAttachmentGeneratorController.deleteStatementPdfTempChunks(tempKeyPrefix);

        System.assertNotEquals(null, result.get('contentVersionId'), 'A generated PDF ContentVersion Id should be returned for task treatment attachments.');

        ContentVersion generatedVersion = [
            SELECT Id, Title, PathOnClient
            FROM ContentVersion
            WHERE Id = :((Id)result.get('contentVersionId'))
            LIMIT 1
        ];
        System.assertEquals('Treatment_Test', generatedVersion.Title, 'The generated task-treatment PDF file name should be sanitized before save.');
        System.assertEquals('/Treatment_Test.pdf', generatedVersion.PathOnClient, 'The generated task-treatment PDF should be saved as a PDF content version.');
    }


    @isTest
    static void testNormalizeStatementPdfFragmentSanitizesAndInlinesImages() {
        Map<Object, Object> inputMap = new Map<Object, Object>{
            'templateBodyImageBase64Map' => new Map<String, String>{
                '/servlet/servlet.ImageServer?id=068000000000001AAA' => 'data:image/png;base64,ABC123'
            }
        };

        String rawHtml =
            '<html><head><meta charset="UTF-8"/><style>.banner{color:red;}</style><script>alert(1);</script></head>' +
            '<body><div class="banner">Statement Body</div><img src="/servlet/servlet.ImageServer?id=068000000000001AAA"/></body></html>';

        String normalizedHtml = PDFAttachmentGeneratorController.normalizeStatementPDFFragment(rawHtml, inputMap);

        System.assert(normalizedHtml.contains('Statement Body'), 'The inner body content should be preserved.');
        System.assert(normalizedHtml.contains('data:image/png;base64,ABC123'), 'Template images should be inlined for VF PDF rendering.');
        System.assertEquals(-1, normalizedHtml.toLowerCase().indexOf('<script'), 'Scripts should be removed from the normalized HTML.');
        System.assertEquals(-1, normalizedHtml.toLowerCase().indexOf('<html'), 'Outer html tags should be stripped before render.');
        System.assertEquals(-1, normalizedHtml.toLowerCase().indexOf('<style'), 'Style tags should be removed from the normalized fragment.');
    }

    @isTest
    static void testLargeTransactionSelectionUsesTempChunks() {
        List<String> fakeIds = new List<String>();
        for (Integer i = 0; i < 400; i++) {
            fakeIds.add('001000000000001AAA');
        }
        String serializedIds = String.join(fakeIds, ',');

        Test.startTest();
        String tempKeyPrefix = PDFAttachmentGeneratorController.createStatementPdfTempChunks(serializedIds, 100000);
        List<Object> rebuiltTransactionList = PDFAttachmentGeneratorController.buildTransactionListFromTempKey(tempKeyPrefix);
        PDFAttachmentGeneratorController.deleteStatementPdfTempChunks(tempKeyPrefix);
        Test.stopTest();

        System.assertEquals(fakeIds.size(), rebuiltTransactionList.size(), 'Chunked transaction ids should round-trip through celsrm__Temp_Object_Holder__c.');
        System.assertEquals(
            '001000000000001AAA',
            String.valueOf(((Map<Object, Object>)rebuiltTransactionList[0]).get('Id')),
            'The rebuilt transaction list should preserve the original ids.'
        );
    }

    @isTest
    static void testEstimateStatementPdfHtmlBytesReturnsBodySize() {
        Account accountRecord = [SELECT Id FROM Account LIMIT 1];
        Contact contactRecord = [SELECT Id FROM Contact WHERE AccountId = :accountRecord.Id LIMIT 1];
        celsrm__Custom_List_View__c listView = [SELECT Id FROM celsrm__Custom_List_View__c WHERE Name = 'Statement Pdf Test View' LIMIT 1];
        String tempKeyPrefix = PDFAttachmentGeneratorController.createStatementPdfTableHtmlTempChunks(
            createTestStatementTableHtml(),
            200
        );

        Map<Object, Object> inputMap = new Map<Object, Object>{
            'Id' => accountRecord.Id,
            'ListView' => listView.Id,
            'StatementFormat' => 'PDF',
            'fileName' => 'Billing Statement',
            'attachment-template' => 'TestStatementPdfTemplate',
            'ContactName' => contactRecord.Id,
            'statementTableHtmlKey' => tempKeyPrefix
        };

        Integer estimatedSize = PDFAttachmentGeneratorController.estimateStatementPdfHtmlBytes(inputMap);
        PDFAttachmentGeneratorController.deleteStatementPdfTempChunks(tempKeyPrefix);
        System.assert(estimatedSize > 0, 'The pre-render estimator should return a positive HTML size.');
    }

    private static String createTestStatementTableHtml() {
        return '<table class="txSummaryTable"><thead><tr><th>Name</th><th>Amount</th></tr></thead><tbody>' +
            '<tr><td>testno0</td><td>$ 100.00</td></tr>' +
            '<tr><td>testno1</td><td>$ 200.00</td></tr>' +
            '</tbody></table>';
    }

    private static String createTestAttachmentHtml() {
        return '<html><head><style>.summary-title{font-weight:bold;}</style></head><body><div class="summary-title">Treatment Summary</div><div><table class="txSummaryTable"><thead><tr><th>Name</th></tr></thead><tbody><tr><td>Step 1</td></tr></tbody></table></div></body></html>';
    }

    // Additional coverage for PDFAttachmentGeneratorController (69% -> ~80%): constructor exception
    // fallback, buildStatementPDFHTML's own "content required" guard, serializeIdsForPageParam
    // variants, resolveStatementContactId variants, the childAccountIds -> buildIdList path, the
    // renderWithAttachmentTemplate=true merge branch, and the dynamic attachment-template-folder-ref-field
    // lookup (success + invalid-field fallback).
    @isTest
    static void testConstructorFallsBackToErrorBodyWhenNoContentProvided() {
        Account accountRecord = [SELECT Id FROM Account LIMIT 1];
        celsrm__Custom_List_View__c listView = [SELECT Id FROM celsrm__Custom_List_View__c WHERE Name = 'Statement Pdf Test View' LIMIT 1];

        Test.setCurrentPage(Page.PDFAttachmentGenerator);
        ApexPages.currentPage().getParameters().put('accountId', accountRecord.Id);
        ApexPages.currentPage().getParameters().put('listView', listView.Id);
        ApexPages.currentPage().getParameters().put('fileName', 'Billing Statement');
        // Deliberately omit statementTableHtmlKey and prebuiltAttachmentHtmlKey so neither
        // hasPrebuiltStatementTableHtml nor hasPrebuiltAttachmentHtml is satisfied.

        Test.startTest();
        PDFAttachmentGeneratorController controller = new PDFAttachmentGeneratorController();
        Test.stopTest();

        System.assertEquals('', controller.attachmentStyles, 'Styles should be blank on the error fallback path.');
        System.assert(controller.attachmentBody.contains('Unable to generate statement PDF.'), 'Constructor should catch the CustomException and fall back to the error body.');
    }

    @isTest
    static void testBuildStatementPDFHTMLThrowsWhenNoContentProvided() {
        Account accountRecord = [SELECT Id FROM Account LIMIT 1];
        celsrm__Custom_List_View__c listView = [SELECT Id FROM celsrm__Custom_List_View__c WHERE Name = 'Statement Pdf Test View' LIMIT 1];

        Boolean threw = false;
        try {
            PDFAttachmentGeneratorController.buildStatementPDFHTML(new Map<Object, Object>{
                'Id' => accountRecord.Id,
                'ListView' => listView.Id
            });
        } catch (celsrm.CustomException e) {
            threw = true;
        }

        System.assert(threw, 'buildStatementPDFHTML should throw when neither prebuilt statement table nor prebuilt attachment HTML is supplied.');
    }

    @isTest
    static void testSerializeIdsForPageParamVariants() {
        System.assertEquals(null, PDFAttachmentGeneratorController.serializeIdsForPageParam(null));
        System.assertEquals('abc', PDFAttachmentGeneratorController.serializeIdsForPageParam('abc'));

        List<Object> mapEntries = new List<Object>{
            new Map<Object, Object>{ 'Id' => '001000000000001AAA' },
            new Map<Object, Object>{ 'Id' => '001000000000002AAA' },
            null
        };
        System.assertEquals('001000000000001AAA,001000000000002AAA', PDFAttachmentGeneratorController.serializeIdsForPageParam(mapEntries));

        List<Object> plainEntries = new List<Object>{ '001000000000003AAA' };
        System.assertEquals('001000000000003AAA', PDFAttachmentGeneratorController.serializeIdsForPageParam(plainEntries));

        List<Object> emptyEntries = new List<Object>{ new Map<Object, Object>() };
        System.assertEquals(null, PDFAttachmentGeneratorController.serializeIdsForPageParam(emptyEntries));
    }

    @isTest
    static void testResolveStatementContactIdVariants() {
        System.assertEquals(null, PDFAttachmentGeneratorController.resolveStatementContactId(null));
        System.assertEquals(null, PDFAttachmentGeneratorController.resolveStatementContactId(new Map<Object, Object>()));
        System.assertEquals(null, PDFAttachmentGeneratorController.resolveStatementContactId(new Map<Object, Object>{ 'ContactName' => null }));
        System.assertEquals(null, PDFAttachmentGeneratorController.resolveStatementContactId(new Map<Object, Object>{ 'ContactName' => '005000000000001AAA' }));

        Contact contactRecord = [SELECT Id FROM Contact LIMIT 1];
        Id resolvedContactId = PDFAttachmentGeneratorController.resolveStatementContactId(new Map<Object, Object>{ 'ContactName' => contactRecord.Id });
        System.assertEquals(contactRecord.Id, resolvedContactId, 'A well-formed Contact Id (003 prefix) should be returned as-is.');
    }

    @isTest
    static void testChildAccountIdsAreIncludedViaBuildIdList() {
        Account accountRecord = [SELECT Id FROM Account LIMIT 1];
        Contact contactRecord = [SELECT Id FROM Contact WHERE AccountId = :accountRecord.Id LIMIT 1];
        celsrm__Custom_List_View__c listView = [SELECT Id FROM celsrm__Custom_List_View__c WHERE Name = 'Statement Pdf Test View' LIMIT 1];
        String tempKeyPrefix = PDFAttachmentGeneratorController.createStatementPdfTableHtmlTempChunks(
            createTestStatementTableHtml(),
            200
        );

        Test.setCurrentPage(Page.PDFAttachmentGenerator);
        ApexPages.currentPage().getParameters().put('accountId', accountRecord.Id);
        ApexPages.currentPage().getParameters().put('listView', listView.Id);
        ApexPages.currentPage().getParameters().put('fileName', 'Billing Statement');
        ApexPages.currentPage().getParameters().put('attachmentTemplate', 'TestStatementPdfTemplate');
        ApexPages.currentPage().getParameters().put('contactId', contactRecord.Id);
        ApexPages.currentPage().getParameters().put('statementTableHtmlKey', tempKeyPrefix);
        ApexPages.currentPage().getParameters().put('childAccountIds', accountRecord.Id + ',' + accountRecord.Id);

        Test.startTest();
        PDFAttachmentGeneratorController controller = new PDFAttachmentGeneratorController();
        Test.stopTest();
        PDFAttachmentGeneratorController.deleteStatementPdfTempChunks(tempKeyPrefix);

        System.assert(!controller.attachmentBody.contains('Unable to generate statement PDF.'), 'Supplying childAccountIds should not break rendering.');
    }

    @isTest
    static void testRenderWithAttachmentTemplateMergesTemplateAndPrebuiltHtml() {
        Account accountRecord = [SELECT Id FROM Account LIMIT 1];
        Contact contactRecord = [SELECT Id FROM Contact WHERE AccountId = :accountRecord.Id LIMIT 1];
        String tempKeyPrefix = PDFAttachmentGeneratorController.createStatementPdfTableHtmlTempChunks(
            createTestAttachmentHtml(),
            50
        );

        Test.setCurrentPage(Page.PDFAttachmentGenerator);
        ApexPages.currentPage().getParameters().put('accountId', accountRecord.Id);
        ApexPages.currentPage().getParameters().put('fileName', 'Treatment Attachment');
        ApexPages.currentPage().getParameters().put('prebuiltAttachmentHtmlKey', tempKeyPrefix);
        ApexPages.currentPage().getParameters().put('attachmentTemplate', 'TestStatementPdfTemplate');
        ApexPages.currentPage().getParameters().put('contactId', contactRecord.Id);
        ApexPages.currentPage().getParameters().put('renderWithAttachmentTemplate', 'true');

        Test.startTest();
        PDFAttachmentGeneratorController controller = new PDFAttachmentGeneratorController();
        Test.stopTest();
        PDFAttachmentGeneratorController.deleteStatementPdfTempChunks(tempKeyPrefix);

        System.assert(!controller.attachmentBody.contains('Unable to generate statement PDF.'), 'Rendering with an attachment template should not fall back to the error body.');
        System.assert(controller.attachmentBody.contains('Test Statement PDF') || controller.attachmentBody.contains('Treatment Summary'),
            'The merged body should include content from either the rendered template or the prebuilt attachment HTML.');
    }

    @isTest
    static void testResolveStatementTemplateFolderNameDynamicFieldLookupAndInvalidFieldFallback() {
        Account accountRecord = [SELECT Id, Name FROM Account LIMIT 1];

        String resolvedFolderName = PDFAttachmentGeneratorController.resolveStatementTemplateFolderName(new Map<Object, Object>{
            'Id' => accountRecord.Id,
            'attachment-template-folder-ref-field' => 'Name'
        });
        System.assertEquals(accountRecord.Name, resolvedFolderName, 'When the ref field resolves to a non-blank value, it should be used as the folder name.');

        String fallbackFolderName = PDFAttachmentGeneratorController.resolveStatementTemplateFolderName(new Map<Object, Object>{
            'Id' => accountRecord.Id,
            'attachment-template-folder' => 'DefaultFolder',
            'attachment-template-folder-ref-field' => 'This_Field_Does_Not_Exist__c'
        });
        System.assertEquals('DefaultFolder', fallbackFolderName, 'An invalid dynamic field should be caught and fall back to the static folder name.');
    }

    private static celsrm__Custom_List_View__c buildListView() {
        String namespace = 'celsrm__';
        celsrm__Custom_List_View__c listView = new celsrm__Custom_List_View__c();
        listView.Name = 'Statement Pdf Test View';
        listView.celsrm__Object_Fields__c =
            '[{"enableCopy":false,"isExport":true,"hide":false,"type":"link","fieldName":"Name"},' +
            '{"enableCopy":false,"isExport":true,"hide":false,"type":"currency","fieldName":"' + namespace + 'Amount__c"},' +
            '{"enableCopy":false,"isExport":true,"hide":false,"type":"currency","fieldName":"' + namespace + 'Balance__c"},' +
            '{"enableCopy":false,"isExport":true,"hide":false,"type":"date","fieldName":"' + namespace + 'Due_Date__c"}]';
        listView.celsrm__User__c = UserInfo.getUserId();
        listView.celsrm__Is_Global__c = true;
        listView.celsrm__ListView_For_Object__c = 'celsrm__Transaction__c';
        return listView;
    }

    private static EmailTemplate buildEmailTemplate(String templateName) {
        EmailTemplate templateRecord = new EmailTemplate();
        templateRecord.Name = templateName;
        templateRecord.DeveloperName = templateName;
        templateRecord.FolderId = UserInfo.getUserId();
        templateRecord.Subject = 'Statement';
        templateRecord.Body = '<style>.statement-title{font-weight:bold;}</style><div class="statement-title">Test Statement PDF</div><div>{Transaction.Summary}</div><div>{Transactions.TotalBalance}</div>';
        templateRecord.HtmlValue = '<style>.statement-title{font-weight:bold;}</style><div class="statement-title">Test Statement PDF</div><div>{Transaction.Summary}</div><div>{Transactions.TotalBalance}</div>';
        templateRecord.TemplateType = 'custom';
        templateRecord.IsActive = true;
        return templateRecord;
    }
}