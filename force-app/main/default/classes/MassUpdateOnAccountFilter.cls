global with sharing class MassUpdateOnAccountFilter implements celsrm.GOGIScreenCustomLogic {
    global Map<Object, Object> invoke(String functionName, Map<Object, Object> inMap) {
        if (!inMap.containsKey('ListViewObject') || inMap.get('ListViewObject') == null || inMap.get('ListViewObject') == '') {
            throw new celsrm.GOGDataServiceLoadException('List View Object is not specified');
        }

        if (!inMap.containsKey('ListViewParentField') || inMap.get('ListViewParentField') == null || inMap.get('ListViewParentField') == '') {
            throw new celsrm.GOGDataServiceLoadException('Parent Field Api name is not specified.');
        }

        String objectName = String.valueOf(inMap.get('ListViewObject'));
        String parentFieldApiName = String.valueOf(inMap.get('ListViewParentField'));
        List<String> accId = new List<String>();
        String selectedView = String.valueOf(inMap.get('ListView'));
        String RefFields = '';
        String currUser = UserInfo.getUserId();

        Map<String, Schema.SObjectField> fMap;
        Map<string, Schema.sObjectType> describeInfo = Schema.getGlobalDescribe();
        fMap = describeInfo.get('celsrm__Transaction__c').getDescribe().Fields.getMap();

        if (functionName != 'UpdateCall') {
            if (inMap.containsKey('CriteriaGrid') && ((List<Object>) inMap.get('CriteriaGrid')).size() > 0) {
                Integer len = ((List<Object>) inMap.get('CriteriaGrid')).size() - 1;
                for (Integer i = 0; i < len; i++) {
                    Map<Object, Object> tempCriteria = (Map<Object, Object>) (((List<Object>) inMap.get('CriteriaGrid')).get(i));
                    if (!tempCriteria.containsKey('LogicalOperator') || tempCriteria.get('LogicalOperator') == null || tempCriteria.get('LogicalOperator') == '') {
                        throw new celsrm.GOGDataServiceLoadException('Enter the criteria Logical Operator in index ' + (i + 1) + '.');
                    }
                }
            }
            List<Object> lst = ((List<Object>) inMap.get('CriteriaGrid'));
            System.debug('lst>>>>>' + lst);
            for (Object o : lst) {
                Map<Object, Object> m = (Map<Object, Object>) o;
                if (m.get('Field') == null || String.valueOf(m.get('Field')) == '') {
                    throw new celsrm.GOGDataServiceLoadException('Please select field');
                } else if (m.get('Operator') == null || String.valueOf(m.get('Operator')) == '') {
                    throw new celsrm.GOGDataServiceLoadException('Please select Operator');
                }
            }
        }

        String selectfields = 'Name,celsrm__Amount__c,celsrm__Balance__c,celsrm__Latest_Note__c,celsrm__Flag__c';
        Set<string> cFieldSet = new Set<string>();
        String whereClause = '';

        if (JSON.serialize(((List<Object>) inMap.get('CriteriaGrid'))) != null && functionName != 'UpdateCall') {
            List<Map<String, String>> filters = (List<Map<String, String>>) JSON.deserialize(JSON.serialize(((List<Object>) inMap.get('CriteriaGrid'))), List<Map<String, String>>.class);
            if (filters != null && filters.size() > 0) {
                String LogicalOperator = '';
                for (Map<String, String> clause : filters) {
                    System.debug('whereClause>>> ' + whereClause);
                    System.debug('LogicalOperator.contains>>> ' + LogicalOperator.contains('OR'));
                    if (LogicalOperator.contains('OR')) {
                        whereClause = whereClause.removeEnd(')');
                    }
                    whereClause += LogicalOperator;

                    String TYPE = String.ValueOf(fMap.get(clause.get('Field')).getDescribe().getType());
                    System.debug('clause>>>>' + clause);
                    String quote = '';
                    if (TYPE == 'ID' || TYPE == 'REFERENCE' || TYPE == 'STRING' || TYPE == 'PICKLIST' || TYPE == 'TEXTAREA' ||
                            TYPE == 'ADDRESS' || TYPE == 'PHONE' || TYPE == 'URL') {
                        quote = '\'';
                    }
                    String value = clause.get('Value');
                    String str = clause.get('Operator');

                    if (whereClause == '') {
                        whereClause += ' WHERE ';
                    }
                    if (!LogicalOperator.contains('OR')) {
                        whereClause += '(';
                    }
                    if (str.equals('does not contain')) {
                        whereClause += ' ( NOT ' + clause.get('Field');
                    } else {
                        whereClause += ' ' + clause.get('Field');
                    }

                    if (str.equals('equals')) {
                        whereClause += ' = ' + (value == null ? 'null' : quote + value + quote);
                    } else if (str.equals('not equal to')) {
                        whereClause += ' != ' + (value == null ? 'null' : quote + value + quote);
                    } else if (str.equals('starts with')) {
                        whereClause += ' LIKE ' + (value == null ? 'null' : quote + value + '%' + quote);
                    } else if (str.equals('end with')) {
                        whereClause += ' LIKE ' + (value == null ? 'null' : quote + '%' + value + quote);
                    } else if (str.equals('contains')) {
                        whereClause += ' LIKE ' + (value == null ? 'null' : quote + '%' + value + '%' + quote);
                    } else if (str.equals('does not contain')) {
                        whereClause += ' LIKE ' + (value == null ? 'null' : quote + '%' + value + '%' + quote);
                    } else if (str.equals('contains in list')) {
                        whereClause += ' INCLUDES ' + (value == null ? '(null)' : '(' + '\'' + value + '\'' + ')');
                    } else if (str.equals('less than')) {
                        whereClause += ' < ' + (value == null ? 'null' : quote + value + quote);
                    } else if (str.equals('greater than')) {
                        whereClause += ' > ' + (value == null ? 'null' : quote + value + quote);
                    } else if (str.equals('less or equal')) {
                        whereClause += ' <= ' + (value == null ? 'null' : quote + value + quote);
                    } else if (str.equals('greater or equal')) {
                        whereClause += ' >= ' + (value == null ? 'null' : quote + value + quote);
                    }

                    if (str.equals('does not contain')) {
                        whereClause += ' ) ';
                    }
                    whereClause += ')';
                    LogicalOperator = (clause.get('LogicalOperator') != null && clause.get('LogicalOperator') != '' ? + ' ' + clause.get('LogicalOperator') + ' ' : '') + ' ';
                }
            }
        }

        accId.add(String.valueOf(inMap.get('Id')));
        System.debug('=============accId======' + accId);
        if (whereClause != '') {
            whereClause += ' and ' + parentFieldApiName + ' in :accId';
        } else {
            whereClause = ' where ' + parentFieldApiName + ' in :accId';
        }
        if (inMap.get('TransactionIDSearch') != null && inMap.get('TransactionIDSearch') != '') {
            List<String> strIdList = String.valueOf(inMap.get('TransactionIDSearch')).split('[\\s\\n,]+');
            whereClause += ' and Name in :strIdList';
        }
        String sortfieldName = null;
        String sortOrder = null;

        // creating map of data type compatible
        Map<String, String> m_Type = new Map<String, String>();
        m_Type.put('ID', 'id');
        m_Type.put('STRING', 'text');
        m_Type.put('TEXTAREA', 'html');
        m_Type.put('NUMBER', 'number');
        m_Type.put('CURRENCY', 'currency');
        m_Type.put('PERCENT', 'percent');
        m_Type.put('DOUBLE', 'number');
        m_Type.put('PICKLIST', 'text');
        m_Type.put('BOOLEAN', 'boolean');
        m_Type.put('EMAIL', 'email');
        m_Type.put('DATE', 'date');
        m_Type.put('DATETIME', 'datetime');
        m_Type.put('PHONE', 'phone');
        m_Type.put('REFERENCE', 'html');
        boolean isId = false;
        boolean isName = false;
        if (selectfields != null && selectfields != '') {
            for (String str : selectfields.split(',')) {
                if (str.equalsIgnoreCase('id')) {
                    isId = true;
                }
                if (str.equalsIgnoreCase('name')) {
                    isName = true;
                }
            }
        }

        System.debug('selectfields>>>>>>>>>.' + selectfields);
        Boolean addedDPDFieldManually = false;
        Boolean addedPromiseAmtFieldManually = false;
        Boolean addedDisputeAmtFieldManually = false;
        Boolean addedBalanceFieldManually = false;

        if (objectName == 'celsrm__Transaction__c') {
            if (!selectfields.contains('celsrm__Disputed_Amount__c')) {
                addedDisputeAmtFieldManually = true;
                selectfields += ',celsrm__Disputed_Amount__c';
            }
            if (!selectfields.contains('celsrm__Promised_Amount__c')) {
                addedPromiseAmtFieldManually = true;
                selectfields += ',celsrm__Promised_Amount__c';
            }
            if (!selectfields.contains('celsrm__DPD__c')) {
                addedDPDFieldManually = true;
                selectfields += ',celsrm__DPD__c';
            }
        }
        if (!selectfields.containsIgnoreCase('celsrm__Balance__c')) {
            addedBalanceFieldManually = true;
            selectfields += ',celsrm__Balance__c';
        }
        String finalQuery = 'SELECT ' + selectfields + ' FROM ' + objectName + (whereClause != '' ? whereClause : '') + ' limit 1000';

        System.debug('finalQuery >>>>>>>>>.' + finalQuery);
        List<sObject> l_values = database.query(finalQuery);
        inMap.put('l_values', l_values);
        List<String> selectField = selectfields.trim().split(',');
        List<String> refField = new List<String>();
        for (String field : selectField) {
            if (fMap.get(field).getDescribe().getType() == Schema.DisplayType.REFERENCE) {
                refField.add(field);
            }
        }
        inMap.put('refField', refField);

        if (selectfields.contains(',id')) {
            selectfields = selectfields.remove(',id');
        } else if (selectfields.contains(',Id')) {
            selectfields = selectfields.remove(',Id');
        } else if (selectfields.contains('Id,')) {
            selectfields = selectfields.remove('Id,');
        } else if (selectfields.contains('id,')) {
            selectfields = selectfields.remove('id,');
        }

        List<Map<String, Object>> l_map = new List<Map<String, Object>>();
        for (String field : selectfields.split(',')) {
            Map<String, Object> m_key_value = new Map<String, Object>();
            System.debug(field.equalsIgnoreCase('celsrm__Flag__c') + 'field>>>>>>>>.' + field);
            if (field.contains('__r.Name')) {
                field = field.replaceAll('__r.Name', '__c');
            }
            if (field.equalsIgnoreCase('celsrm__Flag__c')) {
                m_key_value.put('label', '');
                m_key_value.put('fieldName', field);
                m_key_value.put('type', 'html');
                m_key_value.put('sortable', false);
                m_key_value.put('width', 'min-width:3.2rem');
            } else if (field == 'celsrm__Latest_Note__c') {
                m_key_value.put('label', fMap.get(field).getDescribe().getLabel());
                m_key_value.put('fieldName', field);
                m_key_value.put('type', 'html');
                m_key_value.put('sortable', false);
                m_key_value.put('width', 'width:10rem');
                m_key_value.put('alternativeText', 'celsrm__Notes_sort__c');
            } else if (field.equalsIgnoreCase('Name')) {
                m_key_value.put('label', fMap.get(field).getDescribe().getLabel());
                m_key_value.put('fieldName', field);
                m_key_value.put('type', 'html');
                m_key_value.put('sortable', false);
                m_key_value.put('alternativeText', 'nameSort');
            } else if ((field != 'celsrm__DPD__c' &&
                    field != 'celsrm__Disputed_Amount__c' &&
                    field != 'celsrm__Promised_Amount__c' && field != 'celsrm__Balance__c') ||
                    ((field == 'celsrm__DPD__c' && !addedDPDFieldManually) ||
                            (field == 'celsrm__Promised_Amount__c' && !addedPromiseAmtFieldManually) ||
                            (field == 'celsrm__Disputed_Amount__c' && !addedDisputeAmtFieldManually) ||
                            (field == 'celsrm__Balance__c' && !addedBalanceFieldManually)
                    )
            ) {
                m_key_value.put('label', fMap.get(field).getDescribe().getLabel());
                m_key_value.put('fieldName', field);
                m_key_value.put('type', m_Type.get(String.valueOf(fMap.get(field).getDescribe().getType())));
                m_key_value.put('sortable', true);
            }

            if (!m_key_value.isEmpty()) {
                l_map.add(m_key_value);
            }
            System.debug('updatedColumns>>>>>>>>.' + l_map);
            inMap.put('updatedColumns', l_map);
        }
        return inMap;
    }
}