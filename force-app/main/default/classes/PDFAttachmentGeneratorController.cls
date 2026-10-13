public with sharing class PDFAttachmentGeneratorController {
    public String attachmentBody { get; private set; }
    public String attachmentStyles { get; private set; }
    public String fileName { get; private set; }
    public String statementPageSize {
        get {
            return UtilityController.getStatementPageSize();
        }
        private set;
    }

    private class StatementPdfSections {
        public String beforeSummary;
        public String afterSummary;
    }

    private class StatementPDFViewModel {
        public String attachmentStyles;
        public String attachmentBody;

        public StatementPDFViewModel() {
            attachmentStyles = '';
            attachmentBody = '';
        }
    }

    public PDFAttachmentGeneratorController() {
        try {
            fileName = sanitizeStatementFileName(ApexPages.currentPage().getParameters().get('fileName'));
            Map<Object, Object> inputMap = new Map<Object, Object>{
                'Id' => ApexPages.currentPage().getParameters().get('accountId'),
                'ListView' => ApexPages.currentPage().getParameters().get('listView'),
                'StatementFormat' => 'PDF',
                'fileName' => fileName
            };

            String attachmentTemplate = ApexPages.currentPage().getParameters().get('attachmentTemplate');
            if (String.isNotBlank(attachmentTemplate)) {
                inputMap.put('attachment-template', attachmentTemplate);
            }

            String attachmentTemplateFolder = ApexPages.currentPage().getParameters().get('attachmentTemplateFolder');
            if (String.isNotBlank(attachmentTemplateFolder)) {
                inputMap.put('attachment-template-folder', attachmentTemplateFolder);
            }

            String attachmentTemplateFolderRefField = ApexPages.currentPage().getParameters().get('attachmentTemplateFolderRefField');
            if (String.isNotBlank(attachmentTemplateFolderRefField)) {
                inputMap.put('attachment-template-folder-ref-field', attachmentTemplateFolderRefField);
            }

            String contactId = ApexPages.currentPage().getParameters().get('contactId');
            if (String.isNotBlank(contactId)) {
                inputMap.put('ContactName', contactId);
            }

            List<Object> transactionList = buildTransactionList(
                ApexPages.currentPage().getParameters().get('selectedTransactionIds')
            );
            if (transactionList.isEmpty()) {
                transactionList = buildTransactionListFromTempKey(
                    ApexPages.currentPage().getParameters().get('selectedTransactionKey')
                );
            }
            if (!transactionList.isEmpty()) {
                inputMap.put('TransactionList', transactionList);
            }

            List<Object> childAccountIds = buildIdList(
                ApexPages.currentPage().getParameters().get('childAccountIds')
            );
            if (!childAccountIds.isEmpty()) {
                inputMap.put('accountHierarchyChildIds', childAccountIds);
            }

            String statementTableHtmlKey = ApexPages.currentPage().getParameters().get('statementTableHtmlKey');
            if (String.isNotBlank(statementTableHtmlKey)) {
                inputMap.put('statementTableHtmlKey', statementTableHtmlKey);
            }

            String prebuiltAttachmentHtmlKey = ApexPages.currentPage().getParameters().get('prebuiltAttachmentHtmlKey');
            if (String.isNotBlank(prebuiltAttachmentHtmlKey)) {
                inputMap.put('prebuiltAttachmentHtmlKey', prebuiltAttachmentHtmlKey);
            }

            String renderWithAttachmentTemplate = ApexPages.currentPage().getParameters().get('renderWithAttachmentTemplate');
            if (String.isNotBlank(renderWithAttachmentTemplate)) {
                inputMap.put('renderWithAttachmentTemplate', renderWithAttachmentTemplate);
            }

            // << START - MM - FIN-10130 - Task -> Send Email PDF attachment: carry forward selected transaction/child
            // record Ids so resolveStatementTotalBalanceDisplayMap can compute TotalOpenItems/TotalOverdueItems/
            // TotalOverdueNotNotedItems placeholders instead of resolving them as blank >>
            String transIds = ApexPages.currentPage().getParameters().get('transIds');
            if (String.isNotBlank(transIds)) {
                inputMap.put('TransIds', transIds);
            }
            // << END - MM - FIN-10130 - Task -> Send Email PDF attachment: carry forward selected transaction/child

            StatementPDFViewModel viewModel;
            if (hasPrebuiltAttachmentHtml(inputMap)) {
                viewModel = buildPrebuiltAttachmentHtmlViewModel(inputMap);
            } else if (hasPrebuiltStatementTableHtml(inputMap)) {
                viewModel = buildPrebuiltStatementPDFViewModel(inputMap);
            } else {
                throw new celsrm.CustomException('Statement table content is required to generate the statement PDF.');
            }
            attachmentStyles = viewModel.attachmentStyles;
            attachmentBody = viewModel.attachmentBody;
            system.debug('attachmentBody:'+attachmentBody);
            ApexPages.currentPage().getHeaders().put('content-disposition', 'inline; filename=' + fileName + '.pdf');
        } catch (Exception ex) {
            System.debug('PDFAttachmentGeneratorController error: ' + ex.getMessage());
            attachmentStyles = '';
            attachmentBody = '<div>Unable to generate statement PDF.</div>';
        }
    }

    public static String buildStatementPDFHTML(Map<Object, Object> inMap) {
        if (hasPrebuiltAttachmentHtml(inMap)) {
            return buildPrebuiltAttachmentHtmlViewModel(inMap).attachmentBody;
        }
        if (!hasPrebuiltStatementTableHtml(inMap)) {
            throw new celsrm.CustomException('Statement table content is required to generate the statement PDF.');
        }
        return buildPrebuiltStatementPDFViewModel(inMap).attachmentBody;
    }

    public static Integer estimateStatementPdfHtmlBytes(Map<Object, Object> inMap) {
        String pdfHtml = buildStatementPDFHTML(inMap);
        return Blob.valueOf(pdfHtml == null ? '' : pdfHtml).size();
    }

    public static String createStatementPdfTempChunks(String selectedTransactionIds, Integer chunkSize) {
        if (String.isBlank(selectedTransactionIds)) {
            return null;
        }
        return createStatementPdfChunkPayload(
            'SendStmtPdf_' + UserInfo.getUserId() + '_' + Datetime.now().getTime(),
            selectedTransactionIds,
            chunkSize,
            'You do not have access to prepare the statement selection for PDF rendering.'
        );
    }

    public static String createStatementPdfTableHtmlTempChunks(String tableHtml, Integer chunkSize) {
        if (String.isBlank(tableHtml)) {
            return null;
        }
        return createStatementPdfChunkPayload(
            'SendStmtPdfHtml_' + UserInfo.getUserId() + '_' + Datetime.now().getTime(),
            tableHtml,
            chunkSize,
            'You do not have access to prepare the statement table for PDF rendering.'
        );
    }

    public static String saveStatementPdfTableHtmlChunk(String uploadToken, Integer chunkIndex, String htmlChunk) {
        if (String.isBlank(uploadToken)) {
            throw new celsrm.CustomException('Statement table upload token is required.');
        }
        if (chunkIndex == null || chunkIndex < 0) {
            throw new celsrm.CustomException('Statement table chunk index is invalid.');
        }
        if (String.isBlank(htmlChunk)) {
            throw new celsrm.CustomException('Statement table chunk data is required.');
        }
        if (!celsrm.GOGSecurityController.isCreateable('celsrm__Temp_Object_Holder__c', 'celsrm__Key__c,celsrm__value__c')) {
            throw new celsrm.CustomException('You do not have access to store statement table chunks.');
        }

        String keyPrefix = getStatementPdfTableHtmlKeyPrefix(uploadToken);
        insert new celsrm__Temp_Object_Holder__c(
            celsrm__Key__c = keyPrefix + '_' + String.valueOf(chunkIndex).leftPad(5, '0'),
            celsrm__value__c = htmlChunk
        );
        return keyPrefix;
    }

    public static String getStatementPdfTableHtmlKey(String uploadToken) {
        return String.isBlank(uploadToken) ? null : getStatementPdfTableHtmlKeyPrefix(uploadToken);
    }

    public static void deleteStatementPdfTempChunks(String keyPrefix) {
        if (String.isBlank(keyPrefix) || !Schema.sObjectType.celsrm__Temp_Object_Holder__c.isDeletable()) {
            return;
        }

        List<celsrm__Temp_Object_Holder__c> tempChunks = [
            SELECT Id
            FROM celsrm__Temp_Object_Holder__c
            WHERE celsrm__Key__c LIKE :(keyPrefix + '%')
        ];
        if (!tempChunks.isEmpty()) {
            delete tempChunks;
        }
    }

    @TestVisible
    private static String getStatementPdfTableHtmlKeyPrefix(String uploadToken) {
        if (String.isBlank(uploadToken)) {
            return null;
        }
        String safeUploadToken = uploadToken.replaceAll('[^A-Za-z0-9_-]+', '');
        if (String.isBlank(safeUploadToken)) {
            safeUploadToken = String.valueOf(Datetime.now().getTime());
        }
        return 'SendStmtPdfHtml_' + UserInfo.getUserId() + '_' + safeUploadToken;
    }

    @TestVisible
    private static Boolean hasPrebuiltStatementTableHtml(Map<Object, Object> inMap) {
        return inMap != null
            && inMap.containsKey('statementTableHtmlKey')
            && inMap.get('statementTableHtmlKey') != null
            && String.isNotBlank(String.valueOf(inMap.get('statementTableHtmlKey')));
    }

    @TestVisible
    private static Boolean hasPrebuiltAttachmentHtml(Map<Object, Object> inMap) {
        return inMap != null
            && inMap.containsKey('prebuiltAttachmentHtmlKey')
            && inMap.get('prebuiltAttachmentHtmlKey') != null
            && String.isNotBlank(String.valueOf(inMap.get('prebuiltAttachmentHtmlKey')));
    }

    @TestVisible
    private static String rebuildStatementPdfTableHtmlFromTempKey(String tempKeyPrefix) {
        return rebuildStatementPdfChunkPayload(tempKeyPrefix);
    }

    @TestVisible
    private static Map<Object, Object> buildStatementPDFTemplateContext(Map<Object, Object> inMap) {
        String listViewId = inMap.get('ListView') == null ? null : String.valueOf(inMap.get('ListView'));
        if (String.isBlank(listViewId)) {
            throw new celsrm.CustomException('List View is required to generate the statement PDF.');
        }

        Set<String> accountIds = normalizeStringSet(inMap.get('accountIds'));
        if (accountIds.isEmpty()) {
            if (inMap.get('Id') != null) {
                accountIds.add(String.valueOf(inMap.get('Id')));
            }
            if (inMap.get('accountHierarchyChildIds') != null) {
                for (Object childAccountId : (List<Object>)inMap.get('accountHierarchyChildIds')) {
                    if (childAccountId != null) {
                        accountIds.add(String.valueOf(childAccountId));
                    }
                }
            }
            inMap.put('accountIds', new List<String>(accountIds));
        }

        UtilityController.TransactionQueryContext queryContext = inMap.get('queryContext') instanceof UtilityController.TransactionQueryContext
            ? (UtilityController.TransactionQueryContext)inMap.get('queryContext')
            : null;
        if (queryContext == null) {
            queryContext = UtilityController.buildTransactionQueryContext(inMap, accountIds);
            inMap.put('queryContext', queryContext);
        }

        List<String> selectedFieldList = new List<String>();
        if (inMap.containsKey('selectedFields') && inMap.get('selectedFields') != null) {
            selectedFieldList.addAll(normalizeStringList(inMap.get('selectedFields')));
        } else if (queryContext.selectedFields != null) {
            selectedFieldList.addAll(queryContext.selectedFields);
            inMap.put('selectedFields', selectedFieldList);
        }

        List<String> selectedFieldLabels = normalizeStringList(inMap.get('selectedFieldsLabel'));
        if (selectedFieldLabels.isEmpty() || (!selectedFieldList.isEmpty() && selectedFieldLabels.size() != selectedFieldList.size())) {
            String accountLanguageCode = inMap.containsKey('accountLanguageCode') && inMap.get('accountLanguageCode') != null ? String.valueOf(inMap.get('accountLanguageCode')) : null;
            inMap.put('selectedFieldsLabel', UtilityController.getTranslatedLabelValues(accountLanguageCode, 'celsrm__Transaction__c', selectedFieldList));
        }
        if (!inMap.containsKey('selectedFieldTypes') || inMap.get('selectedFieldTypes') == null) {
            inMap.put('selectedFieldTypes', queryContext.selectedFieldsType);
        }
        return inMap;
    }

    private static Set<String> normalizeStringSet(Object rawValue) {
        Set<String> values = new Set<String>();
        if (rawValue == null) {
            return values;
        }

        if (rawValue instanceof Set<String>) {
            values.addAll((Set<String>)rawValue);
            return values;
        }

        if (rawValue instanceof List<Object>) {
            for (Object item : (List<Object>)rawValue) {
                if (item != null && String.isNotBlank(String.valueOf(item))) {
                    values.add(String.valueOf(item));
                }
            }
            return values;
        }

        if (rawValue instanceof List<String>) {
            for (String item : (List<String>)rawValue) {
                if (String.isNotBlank(item)) {
                    values.add(item);
                }
            }
            return values;
        }

        if (String.isNotBlank(String.valueOf(rawValue))) {
            values.add(String.valueOf(rawValue));
        }
        return values;
    }

    private static List<String> normalizeStringList(Object rawValue) {
        List<String> values = new List<String>();
        if (rawValue == null) {
            return values;
        }

        if (rawValue instanceof List<String>) {
            for (String item : (List<String>)rawValue) {
                if (String.isNotBlank(item)) {
                    values.add(item);
                }
            }
            return values;
        }

        if (rawValue instanceof List<Object>) {
            for (Object item : (List<Object>)rawValue) {
                if (item != null && String.isNotBlank(String.valueOf(item))) {
                    values.add(String.valueOf(item));
                }
            }
            return values;
        }

        if (String.isNotBlank(String.valueOf(rawValue))) {
            values.add(String.valueOf(rawValue));
        }
        return values;
    }

    @TestVisible
    private static String createStatementPdfChunkPayload(String keyPrefix, String payloadValue, Integer chunkSize, String accessErrorMessage) {
        if (String.isBlank(payloadValue)) {
            return null;
        }
        if (!celsrm.GOGSecurityController.isCreateable('celsrm__Temp_Object_Holder__c', 'celsrm__Key__c,celsrm__value__c')) {
            throw new celsrm.CustomException(accessErrorMessage);
        }

        Integer safeChunkSize = (chunkSize == null || chunkSize <= 0) ? 100000 : chunkSize;
        List<celsrm__Temp_Object_Holder__c> tempChunks = new List<celsrm__Temp_Object_Holder__c>();
        Integer chunkIndex = 0;
        for (Integer startIndex = 0; startIndex < payloadValue.length(); startIndex += safeChunkSize) {
            Integer endIndex = Math.min(startIndex + safeChunkSize, payloadValue.length());
            tempChunks.add(new celsrm__Temp_Object_Holder__c(
                celsrm__Key__c = keyPrefix + '_' + String.valueOf(chunkIndex).leftPad(5, '0'),
                celsrm__value__c = payloadValue.substring(startIndex, endIndex)
            ));
            chunkIndex++;
        }
        insert tempChunks;
        return keyPrefix;
    }

    @TestVisible
    private static String rebuildStatementPdfChunkPayload(String tempKeyPrefix) {
        if (String.isBlank(tempKeyPrefix) || !celsrm.GOGSecurityController.isAccessible('celsrm__Temp_Object_Holder__c', 'Id,celsrm__Key__c,celsrm__value__c')) {
            return null;
        }

        List<celsrm__Temp_Object_Holder__c> tempChunks = [
            SELECT Id, celsrm__Key__c, celsrm__value__c
            FROM celsrm__Temp_Object_Holder__c
            WHERE celsrm__Key__c LIKE :(tempKeyPrefix + '%')
            ORDER BY celsrm__Key__c ASC
        ];

        String rebuiltValue = '';
        for (celsrm__Temp_Object_Holder__c tempChunk : tempChunks) {
            rebuiltValue += tempChunk.celsrm__value__c == null ? '' : tempChunk.celsrm__value__c;
        }
        return rebuiltValue;
    }

    public static String serializeIdsForPageParam(Object rawValue) {
        if (rawValue == null) {
            return null;
        }
        if (rawValue instanceof String) {
            return String.valueOf(rawValue);
        }

        List<String> ids = new List<String>();
        if (rawValue instanceof List<Object>) {
            for (Object entry : (List<Object>)rawValue) {
                if (entry == null) {
                    continue;
                }
                if (entry instanceof Map<Object, Object>) {
                    Map<Object, Object> entryMap = (Map<Object, Object>)entry;
                    if (entryMap.containsKey('Id') && entryMap.get('Id') != null) {
                        ids.add(String.valueOf(entryMap.get('Id')));
                    }
                } else {
                    ids.add(String.valueOf(entry));
                }
            }
        }
        return ids.isEmpty() ? null : String.join(ids, ',');
    }

    public static String sanitizeStatementFileName(String fileName) {
        return sanitizeFileName(fileName);
    }

    public static Map<Object, Object> buildStatementPDFRenderContext(Map<Object, Object> inMap) {
        inMap = buildStatementPDFTemplateContext(inMap);
        UtilityController.TransactionQueryContext queryContext = (UtilityController.TransactionQueryContext)inMap.get('queryContext');
        List<celsrm__Transaction__c> lstTrans = UtilityController.fetchTransactions(queryContext);

        inMap.put('DueTransList', lstTrans);
        return inMap;
    }

    @TestVisible
    private static StatementPDFViewModel buildPrebuiltStatementPDFViewModel(Map<Object, Object> inMap) {
        Map<Object, Object> workingMap = inMap == null ? new Map<Object, Object>() : new Map<Object, Object>(inMap);
        workingMap.put('StatementFormat', 'PDF');
        workingMap = buildStatementPDFTemplateContext(workingMap);

        String templateBody = renderStatementPdfTemplateBody(workingMap);
        if (String.isBlank(templateBody)) {
            templateBody = '<div>{Transaction.Summary}</div>';
        }

        String tableHtml = rebuildStatementPdfTableHtmlFromTempKey(String.valueOf(workingMap.get('statementTableHtmlKey')));
        
        // << START - MM - FIN-10130 | Feature JIRA FIN-8279 - Email Attachment -> Totals by currencycode >> 
        // String totalBalanceDisplay = resolveStatementTotalBalanceDisplay(workingMap);
        // String mergedTemplateBody = applyStatementTotalBalanceTokens(templateBody, totalBalanceDisplay);
        Map<String, String> totalBalanceDisplayMap = resolveStatementTotalBalanceDisplayMap(workingMap);
        String mergedTemplateBody = applyStatementTotalBalanceTokens(templateBody, totalBalanceDisplayMap.get('TotalBalance'));
        mergedTemplateBody = applyStatementTotalOpenItemsTokens(mergedTemplateBody, totalBalanceDisplayMap.get('TotalOpenItems'));
        mergedTemplateBody = applyStatementTotalOverdueItemsTokens(mergedTemplateBody, totalBalanceDisplayMap.get('TotalOverdueItems'));
        mergedTemplateBody = applyStatementTotalOverdueNotNotedItemsTokens(mergedTemplateBody, (String)totalBalanceDisplayMap.get('TotalOverdueNotNotedItems'));
        mergedTemplateBody = UtilityController.replaceCustomerSpecificPlaceholdersByID(mergedTemplateBody, (String)inMap.get('Id'));
        // << END - MM - FIN-10130 | Feature JIRA FIN-8279 - Email Attachment -> Totals by currencycode >> 
        StatementPdfSections templateSections = splitTemplateByTransactionSummary(mergedTemplateBody);

        StatementPDFViewModel viewModel = new StatementPDFViewModel();
        viewModel.attachmentStyles = extractStatementPDFStyles(mergedTemplateBody);
        viewModel.attachmentBody = 
            normalizeStatementPDFFragment(templateSections.beforeSummary, workingMap) +
            (String.isBlank(tableHtml) ? '' : tableHtml) +
            normalizeStatementPDFFragment(templateSections.afterSummary, workingMap);
        return viewModel;
    }

    @TestVisible
    private static StatementPDFViewModel buildPrebuiltAttachmentHtmlViewModel(Map<Object, Object> inMap) {
        Map<Object, Object> workingMap = inMap == null ? new Map<Object, Object>() : new Map<Object, Object>(inMap);
        String attachmentHtml = rebuildStatementPdfChunkPayload(String.valueOf(workingMap.get('prebuiltAttachmentHtmlKey')));
        Boolean renderWithAttachmentTemplate = shouldRenderWithAttachmentTemplate(workingMap);
        String templateBody = renderWithAttachmentTemplate ? renderStatementPdfTemplateBody(workingMap) : null;
        // << START - MM - FIN-10130 | Task -> Send Email (Replace custom place holders)>> 
        Map<String, String> totalBalanceDisplayMap = resolveStatementTotalBalanceDisplayMap(workingMap);
        templateBody = applyStatementTotalBalanceTokens(templateBody, totalBalanceDisplayMap.get('TotalBalance'));
        templateBody = applyStatementTotalOpenItemsTokens(templateBody, totalBalanceDisplayMap.get('TotalOpenItems'));
        templateBody = applyStatementTotalOverdueItemsTokens(templateBody, totalBalanceDisplayMap.get('TotalOverdueItems'));
        templateBody = applyStatementTotalOverdueNotNotedItemsTokens(templateBody, (String)totalBalanceDisplayMap.get('TotalOverdueNotNotedItems'));
        templateBody = UtilityController.replaceCustomerSpecificPlaceholdersByID(templateBody, (String)inMap.get('Id'));
        // << END - MM - FIN-10130 | Task -> Send Email (Replace custom place holders)>> 
        StatementPDFViewModel viewModel = new StatementPDFViewModel();
        if (String.isNotBlank(templateBody) && templateBody.contains('{Transaction.Summary}')) {
            StatementPdfSections templateSections = splitTemplateByTransactionSummary(templateBody);
            String normalizedAttachmentHtml = normalizeStatementPDFFragment(attachmentHtml, workingMap);
            viewModel.attachmentStyles = extractStatementPDFStyles(templateBody) + extractStatementPDFStyles(attachmentHtml);
            viewModel.attachmentBody =
                normalizeStatementPDFFragment(templateSections.beforeSummary, workingMap) +
                normalizedAttachmentHtml +
                normalizeStatementPDFFragment(templateSections.afterSummary, workingMap);
        } else if (String.isNotBlank(templateBody)) {
            viewModel.attachmentStyles = extractStatementPDFStyles(templateBody);
            viewModel.attachmentBody = normalizeStatementPDFFragment(templateBody, workingMap);
        } else {
            viewModel.attachmentStyles = extractStatementPDFStyles(attachmentHtml);
            viewModel.attachmentBody = normalizeStatementPDFFragment(attachmentHtml, workingMap);
        }
        return viewModel;
    }

    @TestVisible
    private static StatementPdfSections splitTemplateByTransactionSummary(String templateBody) {
        StatementPdfSections sections = new StatementPdfSections();
        String safeTemplateBody = String.isBlank(templateBody) ? '' : templateBody;
        Integer summaryTokenIndex = safeTemplateBody.indexOf('{Transaction.Summary}');

        if (summaryTokenIndex < 0) {
            sections.beforeSummary = safeTemplateBody;
            sections.afterSummary = '';
            return sections;
        }

        sections.beforeSummary = safeTemplateBody.substring(0, summaryTokenIndex);
        sections.afterSummary = safeTemplateBody.substring(summaryTokenIndex + '{Transaction.Summary}'.length());
        sections.afterSummary = sections.afterSummary.replace('{Transaction.Summary}', '');
        return sections;
    }

    @TestVisible
    private static String applyStatementTotalBalanceTokens(String templateBody, String totalBalanceDisplay) {
        String safeTemplateBody = String.isBlank(templateBody) ? '<div>{Transaction.Summary}</div>' : templateBody;
        String safeTotalBalanceDisplay = totalBalanceDisplay == null ? '' : totalBalanceDisplay;
        safeTemplateBody = safeTemplateBody.replace('{Transactions.TotalBalance}', safeTotalBalanceDisplay);
        safeTemplateBody = safeTemplateBody.replace('{Transactions.TotalBalanceWithoutCurrency}', safeTotalBalanceDisplay);
        safeTemplateBody = safeTemplateBody.replace('{Transactions.TotalBalanceSummary}', safeTotalBalanceDisplay);
        return safeTemplateBody;
    }

    @TestVisible
    private static String applyStatementTotalOpenItemsTokens(String templateBody, String totalBalanceDisplay) {
        String safeTemplateBody = String.isBlank(templateBody) ? '<div>{Transaction.Summary}</div>' : templateBody;
        String safeTotalBalanceDisplay = totalBalanceDisplay == null ? '' : totalBalanceDisplay;
        safeTemplateBody = safeTemplateBody.replace('{Transactions.TotalOpenItems}', safeTotalBalanceDisplay);
        safeTemplateBody = safeTemplateBody.replace('{Transactions.TotalOpenItemsWithoutCurrency}', safeTotalBalanceDisplay);
        safeTemplateBody = safeTemplateBody.replace('{Transactions.TotalOpenItemsSummary}', safeTotalBalanceDisplay);
        return safeTemplateBody;
    }

    @TestVisible
    private static String applyStatementTotalOverdueItemsTokens(String templateBody, String totalBalanceDisplay) {
        String safeTemplateBody = String.isBlank(templateBody) ? '<div>{Transaction.Summary}</div>' : templateBody;
        String safeTotalBalanceDisplay = totalBalanceDisplay == null ? '' : totalBalanceDisplay;
        safeTemplateBody = safeTemplateBody.replace('{Transactions.TotalOverdueItems}', safeTotalBalanceDisplay);
        safeTemplateBody = safeTemplateBody.replace('{Transactions.TotalOverdueItemsWithoutCurrency}', safeTotalBalanceDisplay);
        safeTemplateBody = safeTemplateBody.replace('{Transactions.TotalOverdueItemsSummary}', safeTotalBalanceDisplay);
        return safeTemplateBody;
    }

    @TestVisible
    private static String applyStatementTotalOverdueNotNotedItemsTokens(String templateBody, String totalBalanceDisplay) {
        String safeTemplateBody = String.isBlank(templateBody) ? '<div>{Transaction.Summary}</div>' : templateBody;
        String safeTotalBalanceDisplay = totalBalanceDisplay == null ? '' : totalBalanceDisplay;
        safeTemplateBody = safeTemplateBody.replace('{Transactions.TotalOverdueNotNotedItems}', safeTotalBalanceDisplay);
        safeTemplateBody = safeTemplateBody.replace('{Transactions.TotalOverdueNotNotedItemsWithoutCurrency}', safeTotalBalanceDisplay);
        safeTemplateBody = safeTemplateBody.replace('{Transactions.TotalOverdueNotNotedItemsSummary}', safeTotalBalanceDisplay);
        return safeTemplateBody;
    }

    @TestVisible
    private static String normalizeStatementPDFFragment(String htmlFragment, Map<Object, Object> inMap) {
        String normalizedBody = String.isBlank(htmlFragment) ? '' : htmlFragment;
        normalizedBody = inlineStatementPDFImages(normalizedBody, inMap);
        normalizedBody = removeTagWithContent(normalizedBody, 'script');
        normalizedBody = removeTagWithContent(normalizedBody, 'noscript');
        normalizedBody = removeTagWithContent(normalizedBody, 'title');
        normalizedBody = removeTagWithContent(normalizedBody, 'style');
        normalizedBody = removeSingletonTag(normalizedBody, '!DOCTYPE');
        normalizedBody = removeSingletonTag(normalizedBody, '?xml');
        normalizedBody = removeSingletonTag(normalizedBody, 'meta');
        normalizedBody = removeSingletonTag(normalizedBody, 'link');
        normalizedBody = removeHtmlComments(normalizedBody);
        normalizedBody = unwrapTagContent(normalizedBody, 'body');
        normalizedBody = removeTagOnly(normalizedBody, 'html');
        normalizedBody = removeTagOnly(normalizedBody, 'head');
        normalizedBody = removeTagOnly(normalizedBody, 'body');
        return normalizedBody;
    }

    @TestVisible
    private static String renderStatementPdfTemplateBody(Map<Object, Object> inMap) {
        String templateName = getTemplateConfigValue(inMap, 'attachment-template', 'attachmentTemplate');
        if (String.isBlank(templateName)) {
            templateName = 'System_BillingStatementPDF';
        }
        String templateFolderName = resolveStatementTemplateFolderName(inMap);
        String accountId = inMap.get('Id') == null ? null : String.valueOf(inMap.get('Id'));
        Id contactId = resolveStatementContactId(inMap);

        List<EmailTemplate> emailTemplateList = new List<EmailTemplate>();
        if (String.isNotBlank(templateFolderName)) {
            emailTemplateList = [
                SELECT Id, Name, Subject, HtmlValue, Body
                FROM EmailTemplate
                WHERE Name = :templateName AND Folder.Name = :templateFolderName
                WITH SECURITY_ENFORCED
                LIMIT 1
            ];
        }
        if (emailTemplateList.isEmpty()) {
            emailTemplateList = [
                SELECT Id, Name, Subject, HtmlValue, Body
                FROM EmailTemplate
                WHERE Name = :templateName
                WITH SECURITY_ENFORCED
                LIMIT 1
            ];
        }
        if (emailTemplateList.isEmpty() && templateName != 'System_BillingStatementPDF') {
            emailTemplateList = [
                SELECT Id, Name, Subject, HtmlValue, Body
                FROM EmailTemplate
                WHERE Name = 'System_BillingStatementPDF'
                WITH SECURITY_ENFORCED
                LIMIT 1
            ];
        }
        if (emailTemplateList.isEmpty()) {
            return '';
        }

        Messaging.SingleEmailMessage renderedMessage = Messaging.renderStoredEmailTemplate(
            emailTemplateList[0].Id,
            contactId,
            (Id)accountId
        );
        String renderedBody = renderedMessage != null ? renderedMessage.getHtmlBody() : '';
        System.debug('renderedBody:'+renderedBody);
        if (String.isNotBlank(renderedBody)) {
            //inMap.put('templateBodyImageBase64Map', UtilityController.extractImagesAsBase64(renderedBody));
        }
        
        return renderedBody;
    }

    @TestVisible
    private static Boolean shouldRenderWithAttachmentTemplate(Map<Object, Object> inMap) {
        if (inMap == null || !inMap.containsKey('renderWithAttachmentTemplate') || inMap.get('renderWithAttachmentTemplate') == null) {
            return false;
        }
        return 'true'.equalsIgnoreCase(String.valueOf(inMap.get('renderWithAttachmentTemplate')));
    }

    @TestVisible
    private static String resolveStatementTemplateFolderName(Map<Object, Object> inMap) {
        String templateFolderName = getTemplateConfigValue(inMap, 'attachment-template-folder', 'attachmentTemplateFolder');
        String folderRefField = getTemplateConfigValue(
            inMap,
            'attachment-template-folder-ref-field',
            'attachmentTemplateFolderRefField'
        );

        if (String.isBlank(folderRefField) || inMap == null || inMap.get('Id') == null) {
            return templateFolderName;
        }

        String accountId = String.valueOf(inMap.get('Id'));
        String queryString = 'SELECT ' + String.escapeSingleQuotes(folderRefField) + ' FROM Account WHERE Id = :accountId';
        try {
            List<Account> accList = Database.query(queryString);
            if (!accList.isEmpty()) {
                Object dynamicFolderObj = accList.get(0).get(folderRefField);
                if (dynamicFolderObj != null && String.isNotBlank(String.valueOf(dynamicFolderObj))) {
                    return String.valueOf(dynamicFolderObj);
                }
            }
        } catch (Exception ex) {
            System.debug('PDFAttachmentGeneratorController.resolveStatementTemplateFolderName error: ' + ex.getMessage());
        }
        return templateFolderName;
    }

    @TestVisible
    private static String getTemplateConfigValue(Map<Object, Object> inMap, String primaryKey, String alternateKey) {
        if (inMap == null) {
            return null;
        }
        if (inMap.containsKey(primaryKey) && inMap.get(primaryKey) != null && String.isNotBlank(String.valueOf(inMap.get(primaryKey)))) {
            return String.valueOf(inMap.get(primaryKey));
        }
        if (String.isNotBlank(alternateKey) && inMap.containsKey(alternateKey) && inMap.get(alternateKey) != null && String.isNotBlank(String.valueOf(inMap.get(alternateKey)))) {
            return String.valueOf(inMap.get(alternateKey));
        }
        return null;
    }

    @TestVisible
    private static List<Object> buildTransactionList(String commaSeparatedIds) {
        List<Object> transactionList = new List<Object>();
        if (String.isBlank(commaSeparatedIds)) {
            return transactionList;
        }

        for (String recordId : commaSeparatedIds.split(',')) {
            if (String.isBlank(recordId)) {
                continue;
            }
            transactionList.add(new Map<Object, Object>{
                'Id' => recordId.trim()
            });
        }
        return transactionList;
    }

    @TestVisible
    private static List<Object> buildIdList(String commaSeparatedIds) {
        List<Object> ids = new List<Object>();
        if (String.isBlank(commaSeparatedIds)) {
            return ids;
        }

        for (String recordId : commaSeparatedIds.split(',')) {
            if (String.isNotBlank(recordId)) {
                ids.add(recordId.trim());
            }
        }
        return ids;
    }

    @TestVisible
    private static List<Object> buildTransactionListFromTempKey(String tempKeyPrefix) {
        List<Object> transactionList = new List<Object>();
        String serializedIds = rebuildStatementPdfChunkPayload(tempKeyPrefix);
        if (String.isBlank(serializedIds)) {
            return transactionList;
        }
        return buildTransactionList(serializedIds);
    }

    @TestVisible
    private static String sanitizeFileName(String fileName) {
        String safeFileName = String.isBlank(fileName) ? 'BillingStatement' : fileName.trim();
        safeFileName = safeFileName.replaceAll('[\\\\/:*?\"<>|]+', '_');
        return String.isBlank(safeFileName) ? 'BillingStatement' : safeFileName;
    }

    public static String extractStatementPDFStyles(String html) {
        if (String.isBlank(html)) {
            return '';
        }

        String extractedStyles = '';
        String workingHtml = html;
        String lowerHtml = workingHtml.toLowerCase();
        while (true) {
            Integer startIndex = lowerHtml.indexOf('<style');
            if (startIndex < 0) {
                break;
            }

            Integer openEndIndex = lowerHtml.indexOf('>', startIndex);
            if (openEndIndex < 0) {
                break;
            }

            Integer endIndex = lowerHtml.indexOf('</style>', openEndIndex + 1);
            if (endIndex < 0) {
                break;
            }

            extractedStyles += '<style type="text/css">' + workingHtml.substring(openEndIndex + 1, endIndex) + '</style>';
            workingHtml = workingHtml.substring(endIndex + 8);
            lowerHtml = workingHtml.toLowerCase();
        }
        return extractedStyles;
    }

    @TestVisible
    private static String removeTagWithContent(String html, String tagName) {
        if (String.isBlank(html) || String.isBlank(tagName)) {
            return html;
        }

        String result = html;
        String lowerTag = tagName.toLowerCase();
        while (true) {
            String lowerResult = result.toLowerCase();
            Integer startIndex = lowerResult.indexOf('<' + lowerTag);
            if (startIndex < 0) {
                break;
            }

            Integer startCloseIndex = lowerResult.indexOf('>', startIndex);
            if (startCloseIndex < 0) {
                result = result.substring(0, startIndex);
                break;
            }

            Integer endIndex = lowerResult.indexOf('</' + lowerTag + '>', startCloseIndex + 1);
            if (endIndex < 0) {
                result = result.substring(0, startIndex) + result.substring(startCloseIndex + 1);
                continue;
            }

            result = result.substring(0, startIndex) + result.substring(endIndex + lowerTag.length() + 3);
        }

        return result;
    }

    @TestVisible
    private static String removeSingletonTag(String html, String tagName) {
        if (String.isBlank(html) || String.isBlank(tagName)) {
            return html;
        }

        String result = html;
        String lowerTag = tagName.toLowerCase();
        while (true) {
            String lowerResult = result.toLowerCase();
            Integer startIndex = lowerResult.indexOf('<' + lowerTag);
            if (startIndex < 0) {
                break;
            }

            Integer endIndex = lowerResult.indexOf('>', startIndex);
            if (endIndex < 0) {
                result = result.substring(0, startIndex);
                break;
            }

            result = result.substring(0, startIndex) + result.substring(endIndex + 1);
        }

        return result;
    }

    @TestVisible
    private static String removeHtmlComments(String html) {
        if (String.isBlank(html)) {
            return html;
        }

        String result = html;
        while (true) {
            Integer startIndex = result.indexOf('<!--');
            if (startIndex < 0) {
                break;
            }

            Integer endIndex = result.indexOf('-->', startIndex + 4);
            if (endIndex < 0) {
                result = result.substring(0, startIndex);
                break;
            }

            result = result.substring(0, startIndex) + result.substring(endIndex + 3);
        }

        return result;
    }

    @TestVisible
    private static String unwrapTagContent(String html, String tagName) {
        if (String.isBlank(html) || String.isBlank(tagName)) {
            return html;
        }

        String lowerHtml = html.toLowerCase();
        String lowerTag = tagName.toLowerCase();
        Integer openIndex = lowerHtml.indexOf('<' + lowerTag);
        if (openIndex < 0) {
            return html;
        }

        Integer openEndIndex = lowerHtml.indexOf('>', openIndex);
        if (openEndIndex < 0) {
            return html;
        }

        Integer closeIndex = lowerHtml.lastIndexOf('</' + lowerTag + '>');
        if (closeIndex < 0 || closeIndex <= openEndIndex) {
            return html.substring(openEndIndex + 1);
        }

        return html.substring(openEndIndex + 1, closeIndex);
    }

    @TestVisible
    private static String removeTagOnly(String html, String tagName) {
        if (String.isBlank(html) || String.isBlank(tagName)) {
            return html;
        }

        String result = removeSingletonTag(html, tagName);
        result = removeSingletonTag(result, '/' + tagName);
        return result;
    }

    @TestVisible
    private static String inlineStatementPDFImages(String html, Map<Object, Object> inMap) {
        if (String.isBlank(html) || inMap == null || !inMap.containsKey('templateBodyImageBase64Map') || inMap.get('templateBodyImageBase64Map') == null) {
            return html;
        }

        Map<String, String> imageMap = (Map<String, String>)inMap.get('templateBodyImageBase64Map');
        for (String imageUrl : imageMap.keySet()) {
            String dataUrl = imageMap.get(imageUrl);
            if (String.isNotBlank(imageUrl) && String.isNotBlank(dataUrl)) {
                html = html.replace(imageUrl, dataUrl);
            }
        }
        return html;
    }

    @TestVisible
    private static String resolveStatementTotalBalanceDisplay(Map<Object, Object> inMap) {
        try {
            if (inMap != null && inMap.containsKey('queryContext') && inMap.get('queryContext') != null) {
                Map<String, String> totalMap = UtilityController.getTransactionTotalSummary(
                    (UtilityController.TransactionQueryContext)inMap.get('queryContext'),
                    'CurrencyIsoCode'
                );
                if (totalMap != null && totalMap.containsKey('TotalBalance') && totalMap.get('TotalBalance') != null) {
                    return totalMap.get('TotalBalance');
                }
            }

            List<Id> transactionIds = new List<Id>();
            if (inMap.containsKey('TransIds') && String.isNotBlank((String)inMap.get('TransIds'))) {
                for (String transactionId : ((String)inMap.get('TransIds')).split(',')) {
                    if (String.isNotBlank(transactionId)) {
                        transactionIds.add((Id)transactionId.trim());
                    }
                }
            }

            if (!transactionIds.isEmpty()) {
                Map<String, String> totalMap = UtilityController.getTransactionTotalSummary(
                    String.valueOf(inMap.get('Id')),
                    transactionIds
                );
                if (totalMap != null && totalMap.containsKey('TotalBalance') && totalMap.get('TotalBalance') != null) {
                    return totalMap.get('TotalBalance');
                }
            }
        } catch (Exception e) {
            System.debug('resolveStatementTotalBalanceDisplay error: ' + e.getMessage());
        }

        Decimal totalBalance = 0;
        if (inMap.containsKey('DueTransList') && inMap.get('DueTransList') != null) {
            for (celsrm__Transaction__c transactionRecord : (List<celsrm__Transaction__c>)inMap.get('DueTransList')) {
                totalBalance += transactionRecord.celsrm__Balance__c == null ? 0 : transactionRecord.celsrm__Balance__c;
            }
        }
        return totalBalance.setScale(2).format();
    }

    // << START - MM - FIN-10130 | Feature JIRA FIN-8279 - Email Attachment -> Totals by currencycode >> 
    @TestVisible
    private static Map<String, String> resolveStatementTotalBalanceDisplayMap(Map<Object, Object> inMap) {
        Map<String, String> returnMap = new Map<String, String>();
        try {
            if (inMap != null && inMap.containsKey('queryContext') && inMap.get('queryContext') != null) {
                Map<String, String> totalMap = UtilityController.getTransactionTotalBalanceMap(
                    (UtilityController.TransactionQueryContext)inMap.get('queryContext'),
                    'CurrencyIsoCode'
                );
                if (totalMap != null && totalMap.containsKey('TotalBalance') && totalMap.get('TotalBalance') != null) {
                    returnMap.put('TotalBalance', totalMap.get('TotalBalance'));
                }
                if (totalMap != null && totalMap.containsKey('TotalOpenItems') && totalMap.get('TotalOpenItems') != null) {
                    returnMap.put('TotalOpenItems', totalMap.get('TotalOpenItems'));
                }
                if (totalMap != null && totalMap.containsKey('TotalOverdueItems') && totalMap.get('TotalOverdueItems') != null) {
                    returnMap.put('TotalOverdueItems', totalMap.get('TotalOverdueItems'));
                }
                if (totalMap != null && totalMap.containsKey('TotalOverdueNotNotedItems') && totalMap.get('TotalOverdueNotNotedItems') != null) {
                    returnMap.put('TotalOverdueNotNotedItems', totalMap.get('TotalOverdueNotNotedItems'));
                }
                return returnMap;
            }

            List<Id> transactionIds = new List<Id>();
            if (inMap.containsKey('TransIds') && String.isNotBlank((String)inMap.get('TransIds'))) {
                for (String transactionId : ((String)inMap.get('TransIds')).split(',')) {
                    if (String.isNotBlank(transactionId)) {
                        transactionIds.add((Id)transactionId.trim());
                    }
                }
            } else if (inMap.containsKey('TransIds') && String.isNotBlank((String)inMap.get('TransIds'))) {
                for (String transactionId : ((String)inMap.get('TransIds')).split(',')) {
                    if (String.isNotBlank(transactionId)) {
                        transactionIds.add((Id)transactionId.trim());
                    }
                }
            }

            if (!transactionIds.isEmpty()) {
                Map<String, String> totalMap = UtilityController.getTransactionTotalSummary(
                    String.valueOf(inMap.get('Id')),
                    transactionIds
                );
                if (totalMap != null && totalMap.containsKey('TotalBalance') && totalMap.get('TotalBalance') != null) {
                    returnMap.put('TotalBalance', totalMap.get('TotalBalance'));
                }
                if (totalMap != null && totalMap.containsKey('TotalOpenItems') && totalMap.get('TotalOpenItems') != null) {
                    returnMap.put('TotalOpenItems', totalMap.get('TotalOpenItems'));
                }
                if (totalMap != null && totalMap.containsKey('TotalOverdueItems') && totalMap.get('TotalOverdueItems') != null) {
                    returnMap.put('TotalOverdueItems', totalMap.get('TotalOverdueItems'));
                }
                if (totalMap != null && totalMap.containsKey('TotalOverdueNotNotedItems') && totalMap.get('TotalOverdueNotNotedItems') != null) {
                    returnMap.put('TotalOverdueNotNotedItems', totalMap.get('TotalOverdueNotNotedItems'));
                }
                return returnMap;
            }
        } catch (Exception e) {
            System.debug('resolveStatementTotalBalanceDisplay error: ' + e.getMessage());
        }

        Decimal totalBalance = 0;
        if (inMap.containsKey('DueTransList') && inMap.get('DueTransList') != null) {
            List<Id> transactionIds = new List<Id>();
            for (celsrm__Transaction__c transactionRecord : (List<celsrm__Transaction__c>)inMap.get('DueTransList')) {
                transactionIds.add(transactionRecord.Id);
            }
            Map<String, String> totalMap = UtilityController.getTransactionTotalSummary(
                String.valueOf(inMap.get('Id')),
                transactionIds
            );
            if (totalMap != null && totalMap.containsKey('TotalBalance') && totalMap.get('TotalBalance') != null) {
                returnMap.put('TotalBalance', totalMap.get('TotalBalance'));
            }
            if (totalMap != null && totalMap.containsKey('TotalOpenItems') && totalMap.get('TotalOpenItems') != null) {
                returnMap.put('TotalOpenItems', totalMap.get('TotalOpenItems'));
            }
            if (totalMap != null && totalMap.containsKey('TotalOverdueItems') && totalMap.get('TotalOverdueItems') != null) {
                returnMap.put('TotalOverdueItems', totalMap.get('TotalOverdueItems'));
            }
            if (totalMap != null && totalMap.containsKey('TotalOverdueNotNotedItems') && totalMap.get('TotalOverdueNotNotedItems') != null) {
                returnMap.put('TotalOverdueNotNotedItems', totalMap.get('TotalOverdueNotNotedItems'));
            }
        }
        return returnMap;
    }
    // << END - MM - FIN-10130 | Feature JIRA FIN-8279 - Email Attachment -> Totals by currencycode >> 

    @TestVisible
    private static Id resolveStatementContactId(Map<Object, Object> inMap) {
        if (inMap == null || !inMap.containsKey('ContactName') || inMap.get('ContactName') == null) {
            return null;
        }
        String contactId = String.valueOf(inMap.get('ContactName'));
        return String.isNotBlank(contactId) && contactId.startsWith('003') ? (Id)contactId : null;
    }
}