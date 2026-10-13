public with sharing class AIDunningTemplateGeneration {

    public class DunningEmailResult {
        public String subject;
        public String body;
    }

    public static DunningEmailResult generateDunningEmailContent(
        Task t,
        Map<String, Object> dunningData,
        List<Id> txnIds,
        String additionalPrompt,
        String language,
        Map<String, String> collectorDetails
    ) {
        DunningEmailResult result = new DunningEmailResult();

        celsrm.AIWrapper.ReturnResponse aiResponse = AIDunningGenAiController.getAiDunningEmailTemplate(dunningData, additionalPrompt, language, collectorDetails);        
        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(aiResponse.resultSummary);
        result.subject = (String) responseMap.get('subject');
        String aiTemplateHtml = (String) responseMap.get('emailTemplateHtml');

        // Append HTML table
        // String htmlTable = getTableHtml(txnIds);
        // Map<String, Object> txnTable = buildTransactionHtmlTable(
        //     txnIds,
        //     true,                         
        //     'Amount__c',                  
        //     'Total Amount:',
        //     'Transaction__c'
        // );

        // FINAL HTML BODY = AI HTML + table
        result.body = aiTemplateHtml;

        return result;
    }

    public static Map<String, Object> buildTransactionHtmlTable(
        List<Id> transactionIds,
        Boolean includeTotals,
        String aggregateField,
        String totalLabel,
        String objectApiName,
        String txnTableColumns
    ){
            // String txnTableColumns = celsrm__AI_Configuration__c.getOrgDefaults().Transaction_Table_Columns__c;
            List<String> columnListRaw = (txnTableColumns != null && txnTableColumns !='') ?  txnTableColumns.split(',') : null;
            List<String> columnList = new List<String>();
            if (columnListRaw != null) {
                for (String c : columnListRaw) {
                    String trimmed = c.trim();
                    if (String.isNotBlank(trimmed)) {
                        columnList.add(trimmed);
                    }
                }
            }
            Map<string, Schema.sObjectType> describeInfo = Schema.getGlobalDescribe();
            Map<String, Schema.SObjectField> fMap = describeInfo.get(objectApiName).getDescribe().Fields.getMap();
            Map<String, Object> returnMap = new Map<String, Object>();
            Map<String, String> columnTypes = new Map<String, String>();
            Map<String, Boolean> isCustomReference = new Map<String, Boolean>();
            List<String> queryFields = new List<String>();

            if (columnList.isEmpty()) {
                returnMap.put('innerHtml', '');
                return returnMap;
            }

            //    1. Build column list + detect reference fields
            List<String> validColumns = new List<String>();
            for (String col : columnList) {
                Schema.SObjectField sField = fMap.get(col.toLowerCase());
                if (sField == null) continue;
                validColumns.add(col);
                Schema.DescribeFieldResult fd = sField.getDescribe();
                String type = fd.getType().name();
                columnTypes.put(col, type);

                Boolean isCustom = false;

                if (type == 'REFERENCE') {
                    isCustom = fd.isCustom();
                    isCustomReference.put(col, isCustom);

                    // Add main field (Id)
                    queryFields.add(col);

                    // Add reference.Name
                    if (isCustom) {
                        queryFields.add(col.subString(0, col.length() - 1) + 'r.Name');
                    } else {
                        queryFields.add(col.subString(0, col.length() - 2) + '.Name');
                    }
                } else {
                    queryFields.add(col);
                }
            }
            columnList = validColumns;

            // Add CurrencyIsoCode automatically
            if (UserInfo.isMultiCurrencyOrganization() && !queryFields.contains('CurrencyIsoCode')) {
                queryFields.add('CurrencyIsoCode');
            }

            //    2. Prepare SOQL
            String soql = 'SELECT ' + String.join(queryFields, ',') +
                        ' FROM ' + objectApiName +
                        ' WHERE Id IN :transactionIds';

            List<SObject> results = Database.query(soql);

            //    3. Build HTML table
            String html = '<table width="100%" class="billing" style="border-collapse:collapse;padding:0px;font-family:verdana;">';

            //    4. Header Row
            html += '<tr>';
            for (String c : columnList) {
                Boolean numeric = columnTypes.get(c) == 'CURRENCY' ||
                                columnTypes.get(c) == 'DOUBLE' ||
                                columnTypes.get(c) == 'NUMBER' ||
                                columnTypes.get(c) == 'PERCENT';

                String align = numeric ? 'right' : 'left';
                html += '<th style="border:1px solid gray;text-align:' + align + ';">' +
                        fMap.get(c.toLowerCase()).getDescribe().getLabel() +
                        '</th>';
            }
            html += '</tr>';

            //    5. Populate Rows
            Map<String, Double> multiTotals = new Map<String, Double>();
            Double total = 0;

            for (SObject row : results) {
                html += '<tr>';

                for (String c : columnList) {
                    Object value;

                    // Resolve REFERENCE.Name
                    if (columnTypes.get(c) == 'REFERENCE') {
                        String prefix = isCustomReference.get(c)
                            ? c.substring(0, c.length()-1) + 'r'
                            : c.substring(0, c.length()-2);

                        SObject refVal = row.getSObject(prefix);
                        value = (refVal != null) ? refVal.get('Name') : '';
                    }
                    else if (columnTypes.get(c) == 'CURRENCY') {
                        if (row.get(c) != null) {
                            Double d = (Double)row.get(c);
                            String iso = UserInfo.isMultiCurrencyOrganization() ?
                                        (String)row.get('CurrencyIsoCode') :
                                        UserInfo.getDefaultCurrency();
                            value = UtilityController.formatDoubleValue(iso, d);
                        } else {
                            value = '';
                        }
                    }
                    else if (columnTypes.get(c) == 'DATE') {
                        value = row.get(c) != null ? ((Date)row.get(c)).format() : '';
                    }
                    else if (columnTypes.get(c) == 'DATETIME') {
                        value = row.get(c) != null ? ((Datetime)row.get(c)).format() : '';
                    }
                    else {
                        value = row.get(c) != null ? row.get(c) : '';
                    }

                    /* --- Accumulate Totals if needed --- */
                    if (includeTotals && aggregateField == c && row.get(c) != null) {
                        if (columnTypes.get(c) == 'CURRENCY') {
                            Double d = (Double)row.get(c);
                            String iso = UserInfo.isMultiCurrencyOrganization() ?
                                        (String)row.get('CurrencyIsoCode') :
                                        UserInfo.getDefaultCurrency();

                            multiTotals.put(iso, (multiTotals.containsKey(iso) ? multiTotals.get(iso) : 0) + d);
                        } else {
                            total += (Double)row.get(c);
                        }
                    }

                    Boolean numeric = columnTypes.get(c) == 'CURRENCY' ||
                                    columnTypes.get(c) == 'DOUBLE' ||
                                    columnTypes.get(c) == 'NUMBER' ||
                                    columnTypes.get(c) == 'PERCENT';

                    String align = numeric ? 'right' : 'left';

                    html += '<td style="text-align:' + align +
                            ';border:0.5px solid gray;white-space:nowrap;">' +
                            value +
                            '</td>';
                }

                html += '</tr>';
            }

            html += '</table>';

            //    6. Totals Rendering
            if (includeTotals) {
                String totalsHtml = '';

                if (total > 0) {
                    totalsHtml = String.valueOf(total);
                    html += '<span style="float:right;">' + totalLabel + ' ' + total + '</span>';
                } else if (!multiTotals.isEmpty()) {
                    html += '<span style="float:right;">' + totalLabel + ' ';
                    for (String iso : multiTotals.keySet()) {
                        String formatted = UtilityController.formatDoubleValue(iso, multiTotals.get(iso));
                        totalsHtml += formatted + ', ';
                        html += formatted + ', ';
                    }
                    totalsHtml = totalsHtml.removeEnd(', ');
                    html = html.removeEnd(', ') + '</span>';
                }

                returnMap.put('totalHtml', totalsHtml);
            }

            returnMap.put('innerHtml', html);
            return returnMap;
        }

}