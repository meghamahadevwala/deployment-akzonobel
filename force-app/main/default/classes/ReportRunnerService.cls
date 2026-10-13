/**
 * Runs an Analytics report filtered by one or more Account Owners and
 * converts the result into a styled Excel-compatible Blob for email
 * attachment (HTML table saved with an .xls extension). Also supports
 * discovering, directly from the report's own groupings, which owners
 * currently have at least one qualifying row.
 *
 * Account Owner and any additional grouping-style columns (e.g. RPDL, Credit
 * Segment) are NOT pulled from the Analytics API's own grouping structure -
 * the API refuses to expose a report's Group Rows By fields as regular
 * Detail Columns, and reconstructing per-row values from the grouping VALUE
 * tree directly proved unreliable for multi-level reports. Instead, they're
 * resolved via a direct SOQL query against Account, joined on Account
 * Number - a normal, reliably ordered Detail Column present in the export.
 */
public with sharing class ReportRunnerService {

    public class ReportRunException extends Exception {}

    private static final String OWNER_TOKEN = 'OWNER';
    private static final String GROUPING_DELIMITER = '/';
    // Default Analytics API column name for Account Number, used when a
    // config doesn't specify one. Most reports (base object = Account) use
    // this. Reports whose base object is something else (e.g. "Open and
    // Pending Credit Limit Request", base object = Credit Limit Request)
    // expose Account Number under a different name, e.g.
    // "FK_ACC_ACCOUNT_NUMBER" - CONFIRMED via debug that assuming
    // 'ACCOUNT_NUMBER' universally silently broke the Account join (index
    // -1 -> no rows matched -> Owner/grouping columns rendered blank).
    private static final String DEFAULT_ACCOUNT_NUMBER_COLUMN = 'ACCOUNT_NUMBER';

    private class ExportRow {
        Map<String, String> groupingValues = new Map<String, String>();
        List<String> detailValues;
    }

    public static Set<String> discoverOwnersWithData(Id reportId, String ownerReportColumnName) {
        Reports.ReportResults results;
        try {
            results = Reports.ReportManager.runReport(reportId, true);
        } catch (Exception ex) {
            throw new ReportRunException('Failed to run report ' + reportId + ' for owner discovery: ' + ex.getMessage());
        }

        Integer ownerDepth = findGroupingDepth(results.getReportMetadata().getGroupingsDown(), ownerReportColumnName);

        Set<String> ownerNames = new Set<String>();
        Reports.Dimension groupingsDown = results.getGroupingsDown();
        if (groupingsDown == null) {
            return ownerNames;
        }

        if (ownerDepth < 0) {
            collectLeafGroupLabels(groupingsDown.getGroupings(), ownerNames);
            return ownerNames;
        }

        collectGroupLabelsAtDepth(groupingsDown.getGroupings(), 0, ownerDepth, ownerNames);
        return ownerNames;
    }

    private static Integer findGroupingDepth(List<Reports.GroupingInfo> groupingInfos, String ownerReportColumnName) {
        if (groupingInfos == null) {
            return -1;
        }
        for (Integer i = 0; i < groupingInfos.size(); i++) {
            if (groupingInfos[i].getName() == ownerReportColumnName) {
                return i;
            }
        }
        return -1;
    }

    private static void collectGroupLabelsAtDepth(List<Reports.GroupingValue> groupings, Integer currentDepth, Integer targetDepth, Set<String> ownerNames) {
        if (groupings == null) {
            return;
        }
        for (Reports.GroupingValue grouping : groupings) {
            if (currentDepth == targetDepth) {
                if (String.isNotBlank(grouping.getLabel())) {
                    ownerNames.add(grouping.getLabel());
                }
            } else if (grouping.getGroupings() != null && !grouping.getGroupings().isEmpty()) {
                collectGroupLabelsAtDepth(grouping.getGroupings(), currentDepth + 1, targetDepth, ownerNames);
            }
        }
    }

    private static void collectLeafGroupLabels(List<Reports.GroupingValue> groupings, Set<String> ownerNames) {
        if (groupings == null) {
            return;
        }
        for (Reports.GroupingValue grouping : groupings) {
            List<Reports.GroupingValue> children = grouping.getGroupings();
            if (children != null && !children.isEmpty()) {
                collectLeafGroupLabels(children, ownerNames);
            } else if (String.isNotBlank(grouping.getLabel())) {
                ownerNames.add(grouping.getLabel());
            }
        }
    }

    /**
     * @param accountNumberReportColumnName Analytics API column name this report
     *                                      uses for Account Number (used to join
     *                                      against Account via SOQL). Pass null/
     *                                      blank to use the default 'ACCOUNT_NUMBER'.
     */
    public static Blob runReportForOwner(Id reportId, String ownerReportColumnName, String ownerFilterValue, String groupingFieldNamesDelimited, String accountNumberReportColumnName) {
        return runReportForOwners(reportId, ownerReportColumnName, new List<String>{ ownerFilterValue }, groupingFieldNamesDelimited, accountNumberReportColumnName);
    }

    public static Blob runReportForOwners(Id reportId, String ownerReportColumnName, List<String> ownerFilterValues, String groupingFieldNamesDelimited, String accountNumberReportColumnName) {
        Reports.ReportMetadata reportMetadata = Reports.ReportManager.describeReport(reportId).getReportMetadata();

        List<Reports.ReportFilter> filters = reportMetadata.getReportFilters();
        if (filters == null) {
            filters = new List<Reports.ReportFilter>();
        }

        Integer existingCount = filters.size();

        List<Integer> ownerFilterIndices = new List<Integer>();
        for (Integer i = 0; i < ownerFilterValues.size(); i++) {
            Reports.ReportFilter ownerFilter = new Reports.ReportFilter();
            ownerFilter.setColumn(ownerReportColumnName);
            ownerFilter.setOperator('equals');
            ownerFilter.setValue('\'' + ownerFilterValues[i].replace('\'', '\\\'') + '\'');
            filters.add(ownerFilter);
            ownerFilterIndices.add(existingCount + i + 1);
        }

        reportMetadata.setReportFilters(filters);

        String ownerOrGroup = '(' + String.join(ownerFilterIndices, ' OR ') + ')';
        List<String> booleanParts = new List<String>();
        for (Integer i = 1; i <= existingCount; i++) {
            booleanParts.add(String.valueOf(i));
        }
        booleanParts.add(ownerOrGroup);
        reportMetadata.setReportBooleanFilter(String.join(booleanParts, ' AND '));

        Reports.ReportResults results;
        try {
            results = Reports.ReportManager.runReport(reportId, reportMetadata, true);
        } catch (Exception ex) {
            throw new ReportRunException('Failed to run report ' + reportId + ' for owner(s) [' + String.join(ownerFilterValues, ', ') + ']: ' + ex.getMessage());
        }

        String acctNumCol = String.isNotBlank(accountNumberReportColumnName) ? accountNumberReportColumnName : DEFAULT_ACCOUNT_NUMBER_COLUMN;
        return buildStyledExcelFromReport(results, groupingFieldNamesDelimited, acctNumCol);
    }

    private static Blob buildStyledExcelFromReport(Reports.ReportResults results, String groupingFieldNamesDelimited, String accountNumberColumnApiName) {
        List<String> orderedColumnNames = results.getReportMetadata().getDetailColumns();
        Map<String, Reports.DetailColumn> columnInfoByName = results.getReportExtendedMetadata().getDetailColumnInfo();

        List<String> detailHeaderLabels = new List<String>();
        for (String colApiName : orderedColumnNames) {
            Reports.DetailColumn colInfo = columnInfoByName.get(colApiName);
            detailHeaderLabels.add(colInfo != null ? colInfo.getLabel() : colApiName);
        }

        Integer accountNumberIdx = orderedColumnNames.indexOf(accountNumberColumnApiName);
        if (accountNumberIdx < 0) {
            // Column not found under the configured name - Owner/grouping columns
            // will render blank for every row rather than throwing, so this is
            // surfaced loudly instead of failing silently like before.
            throw new ReportRunException('Account Number column "' + accountNumberColumnApiName
                + '" was not found among this report\'s Detail Columns - check '
                + 'Account_Number_Report_Column_Name__c against the report\'s actual columns.');
        }

        List<List<String>> rawDetailRows = new List<List<String>>();
        Set<String> accountNumbersInReport = new Set<String>();

        Map<String, Object> rawFactMap = results.getFactMap();
        for (String factKey : rawFactMap.keySet()) {
            Object rawFact = rawFactMap.get(factKey);
            if (!(rawFact instanceof Reports.ReportFactWithDetails)) {
                continue;
            }
            Reports.ReportFactWithDetails factWithDetails = (Reports.ReportFactWithDetails) rawFact;
            for (Reports.ReportDetailRow row : factWithDetails.getRows()) {
                List<String> rowValues = new List<String>();
                for (Reports.ReportDataCell cell : row.getDataCells()) {
                    rowValues.add(cell.getLabel() == null ? '' : cell.getLabel());
                }
                rawDetailRows.add(rowValues);
                if (accountNumberIdx < rowValues.size()) {
                    String acctNum = rowValues[accountNumberIdx];
                    if (String.isNotBlank(acctNum)) {
                        accountNumbersInReport.add(acctNum);
                    }
                }
            }
        }

        List<String> groupingKeys = new List<String>();
        if (String.isNotBlank(groupingFieldNamesDelimited)) {
            for (String token : groupingFieldNamesDelimited.split(GROUPING_DELIMITER)) {
                String trimmed = token.trim();
                if (String.isNotBlank(trimmed)) {
                    groupingKeys.add(trimmed);
                }
            }
        }
        Boolean ownerInGroupingKeys = groupingKeys.contains(OWNER_TOKEN);

        Set<String> realAccountFields = new Set<String>();
        for (String key : groupingKeys) {
            if (key != OWNER_TOKEN) {
                realAccountFields.add(key);
            }
        }

        Map<String, Account> accountByNumber = new Map<String, Account>();
        if (!accountNumbersInReport.isEmpty()) {
            String extraSelect = realAccountFields.isEmpty() ? '' : (', ' + String.join(new List<String>(realAccountFields), ', '));
            String acctQuery = 'SELECT Id, AccountNumber, Owner.Name' + extraSelect
                + ' FROM Account WHERE AccountNumber IN :accountNumbersInReport';
            for (Account acc : Database.query(acctQuery)) {
                if (String.isNotBlank(acc.AccountNumber)) {
                    accountByNumber.put(acc.AccountNumber, acc);
                }
            }
        }

        List<ExportRow> allRows = new List<ExportRow>();
        for (List<String> rowValues : rawDetailRows) {
            ExportRow er = new ExportRow();
            er.detailValues = rowValues;

            Account acc = null;
            if (accountNumberIdx < rowValues.size()) {
                acc = accountByNumber.get(rowValues[accountNumberIdx]);
            }

            for (String key : groupingKeys) {
                String val = '';
                if (acc != null) {
                    if (key == OWNER_TOKEN) {
                        val = acc.Owner != null ? acc.Owner.Name : '';
                    } else {
                        Object raw = acc.get(key);
                        val = raw == null ? '' : String.valueOf(raw);
                    }
                }
                er.groupingValues.put(key, val);
            }
            if (!ownerInGroupingKeys) {
                er.groupingValues.put(OWNER_TOKEN, acc != null && acc.Owner != null ? acc.Owner.Name : '');
            }

            allRows.add(er);
        }

        List<String> headerLabels = new List<String>();
        for (String key : groupingKeys) {
            headerLabels.add(groupingDisplayLabel(key));
        }
        if (!ownerInGroupingKeys) {
            headerLabels.add('Account Owner');
        }
        headerLabels.addAll(detailHeaderLabels);

        String headerRow = '';
        for (String label : headerLabels) {
            headerRow += headerCellHtml(label);
        }

        List<String> bodyRowFragments;
        if (groupingKeys.isEmpty()) {
            bodyRowFragments = new List<String>();
            for (ExportRow er : allRows) {
                bodyRowFragments.add(dataCellHtml(er.groupingValues.get(OWNER_TOKEN)) + detailCellsHtml(er.detailValues));
            }
        } else {
            bodyRowFragments = renderGroupedRows(allRows, groupingKeys, 0, !ownerInGroupingKeys);
        }

        String bodyRows = '';
        for (String fragment : bodyRowFragments) {
            bodyRows += '<tr>' + fragment + '</tr>';
        }

        String html = '<html xmlns:x="urn:schemas-microsoft-com:office:excel">'
            + '<head><meta charset="UTF-8"/></head>'
            + '<body>'
            + '<table border="1" cellspacing="0" cellpadding="0" '
            + 'style="border-collapse:collapse;font-family:Arial,sans-serif;font-size:11pt;">'
            + '<tr>' + headerRow + '</tr>'
            + bodyRows
            + '</table>'
            + '</body></html>';

        return Blob.valueOf(html);
    }

    private static List<String> renderGroupedRows(List<ExportRow> rows, List<String> keys, Integer keyIndex, Boolean appendPlainOwnerColumn) {
        if (keyIndex >= keys.size()) {
            List<String> baseFragments = new List<String>();
            for (ExportRow er : rows) {
                String fragment = appendPlainOwnerColumn ? dataCellHtml(er.groupingValues.get(OWNER_TOKEN)) : '';
                fragment += detailCellsHtml(er.detailValues);
                baseFragments.add(fragment);
            }
            return baseFragments;
        }

        String key = keys[keyIndex];
        List<String> valuesInOrder = new List<String>();
        Map<String, List<ExportRow>> rowsByValue = new Map<String, List<ExportRow>>();
        for (ExportRow er : rows) {
            String val = er.groupingValues.get(key);
            if (!rowsByValue.containsKey(val)) {
                rowsByValue.put(val, new List<ExportRow>());
                valuesInOrder.add(val);
            }
            rowsByValue.get(val).add(er);
        }

        List<String> result = new List<String>();
        for (String val : valuesInOrder) {
            List<ExportRow> groupRows = rowsByValue.get(val);
            List<String> subFragments = renderGroupedRows(groupRows, keys, keyIndex + 1, appendPlainOwnerColumn);
            for (Integer i = 0; i < subFragments.size(); i++) {
                String prefix = (i == 0) ? mergedGroupCellHtml(val, groupRows.size()) : '';
                result.add(prefix + subFragments[i]);
            }
        }
        return result;
    }

    private static String detailCellsHtml(List<String> detailValues) {
        String html = '';
        for (String val : detailValues) {
            html += dataCellHtml(val);
        }
        return html;
    }

    private static String groupingDisplayLabel(String key) {
        if (key == OWNER_TOKEN) {
            return 'Account Owner';
        }
        try {
            Schema.SObjectField field = Account.sObjectType.getDescribe().fields.getMap().get(key);
            return field != null ? field.getDescribe().getLabel() : key;
        } catch (Exception ex) {
            return key;
        }
    }

    private static String headerCellHtml(String label) {
        return '<th style="background-color:#D9D9D9;color:#000000;font-weight:bold;'
            + 'border:1px solid #999999;padding:4px 6px;text-align:left;white-space:nowrap;'
            + 'mso-number-format:\'\\@\';">'
            + label.escapeHtml4()
            + '</th>';
    }

    private static String dataCellHtml(String val) {
        return '<td style="border:1px solid #cccccc;padding:4px 6px;white-space:nowrap;'
            + 'mso-number-format:\'\\@\';">'
            + val.escapeHtml4()
            + '</td>';
    }

    private static String mergedGroupCellHtml(String val, Integer rowCount) {
        return '<td rowspan="' + rowCount + '" style="border:1px solid #cccccc;padding:4px 6px;'
            + 'white-space:nowrap;vertical-align:middle;text-align:center;font-weight:bold;'
            + 'mso-number-format:\'\\@\';">'
            + val.escapeHtml4()
            + '</td>';
    }
}