/**
 * MM - FIN-9969 - select contact by Email_Type__c based on treatment rule name
 * Local (subscriber-org) copy of celsrm CreateTreatmentTaskService (global in package).
 * Namespace handling:
 *  - Package custom objects/fields prefixed with celsrm__
 *  - Local copies referenced by c-prefixed names (cSRMTreatmentMapper, cSRMTreatmentProcessor,
 *    cSRMTreatmentUtility)
 *  - createCondition / removeParentheses are kept here (mirroring the package class) and are
 *    also reused by cSRMTreatmentUtility.getQueryWhereClause.
 */
public with sharing class cCreateTreatmentTaskService implements Database.Batchable<sObject>, Schedulable, Database.Stateful {
    public Map<Id, List<celsrm__Treatment__c>> accountIdToTreatments = new Map<Id, List<celsrm__Treatment__c>>();
    public String groupName;
    public Integer batchsize = 4;
    public Map<Id, celsrm__Treatment__c> treatmentsMap = new Map<Id, celsrm__Treatment__c>();
    public Map<Id, Id> accIdTOOwnerId = new Map<Id, Id>();
    //-- Start | FIN-9703 | Changed by Dhwanil | 29 April 2026 --//
    public Map<Id, Boolean> accIdTOAutoTreatmentEnabled = new Map<Id, Boolean>();
    //-- End | FIN-9703 | Changed by Dhwanil | 29 April 2026 --//
    public List<String> treatmentIds;
    public List<String> stateTreatmentIds = new List<String>();
    public Datetime futureDt;

    public cCreateTreatmentTaskService() {
        this.setConstructorParams(null, null, 4);
    }

    public cCreateTreatmentTaskService(String groupName) {
        this.setConstructorParams(groupName, null, 4);
    }

    public cCreateTreatmentTaskService(String groupName, Integer batchsize) {
        this.setConstructorParams(groupName, null, batchsize);
    }

    public cCreateTreatmentTaskService(Integer batchsize) {
        this.setConstructorParams(null, null, batchsize);
    }

    public cCreateTreatmentTaskService(List<String> treatmentIds, Integer batchsize) {
        this.setConstructorParams(null, treatmentIds, batchsize);
    }

    public void setConstructorParams(String groupName, List<String> treatmentIds, Integer batchsize) {
        this.treatmentIds = treatmentIds;
        this.batchsize = batchsize;
        this.groupName = groupName;
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        Datetime nowDt = System.now();
        futureDt = nowDt.addHours(24);
        //-- Start | FIN-9703 | Changed by Dhwanil | 29 April 2026 --//
        // << START - MM - FIN-9969 - select contact by Email_Type__c based on treatment rule name | No need to filter based on celsrm__Intelligent_Dunning__c flag>>
        // String query = 'SELECT ' + getTreatmentFieldList() + ' FROM celsrm__Treatment__c WHERE celsrm__Active__c=TRUE AND celsrm__Intelligent_Dunning__c=FALSE';
        String query = 'SELECT ' + getTreatmentFieldList() + ' FROM celsrm__Treatment__c WHERE celsrm__Active__c=TRUE';
        // << END - MM - FIN-9969 - select contact by Email_Type__c based on treatment rule name | No need to filter based on celsrm__Intelligent_Dunning__c flag >>
        //-- End | FIN-9703 | Changed by Dhwanil | 29 April 2026 --//
        if (groupName != null) {
            query += ' AND celsrm__Treatment_Group__c = :groupName ';
        }
        if (treatmentIds != null && !treatmentIds.isEmpty()) {
            query += ' AND Id IN :treatmentIds ';
        }
        query += ' ORDER BY CreatedDate';
        return Database.getQueryLocator(query);
    }

    //-- Start | FIN-9703 | Changed by Dhwanil | 29 April 2026 --//
    private static String getTreatmentFieldList() {
        List<String> fieldNames = new List<String>();
        fieldNames.addAll(Schema.SObjectType.celsrm__Treatment__c.fields.getMap().keySet());
        fieldNames.sort();
        return String.join(fieldNames, ', ');
    }
    //-- End | FIN-9703 | Changed by Dhwanil | 29 April 2026 --//

    public void execute(Database.BatchableContext bc, List<sObject> scope) {
        if (scope != null && scope.size() > 0) {
            for (celsrm__Treatment__c treatment : (List<celsrm__Treatment__c>) scope) {
                try {
                    Boolean isWithin = true;
                    if (treatment.celsrm__Business_Hours__c != null) {
                        isWithin = BusinessHours.isWithin(treatment.celsrm__Business_Hours__c, Datetime.now());
                    }
                    if (!isWithin && treatment.celsrm__Auto_Execute_After_Business_Hours__c) {
                        stateTreatmentIds.add(treatment.Id);
                    }
                    if (isWithin && treatment.celsrm__Account_Criteria__c != null && !treatment.celsrm__Account_Criteria__c.equals('')) {
                        treatmentsMap.put(treatment.Id, treatment);
                        cSRMTreatmentMapper.AccountCriteria aCriteria =
                            (cSRMTreatmentMapper.AccountCriteria) JSON.deserialize(
                                treatment.celsrm__Account_Criteria__c,
                                cSRMTreatmentMapper.AccountCriteria.class
                            );
                        String condition = aCriteria.criteriaCondition;
                        List<String> conditionList = condition.split(' ');
                        if (condition == '') {
                            conditionList = new List<String>();
                        }
                        String whereClause = '';
                        String operator = '';
                        if (aCriteria.criteria != null && aCriteria.criteria.size() > 0) {
                            for (Integer i = 0; i < aCriteria.criteria.size(); i++) {
                                String tmpWhere = cCreateTreatmentTaskService.createCondition(aCriteria.criteria.get(i), 'Account');
                                System.debug(' @@ tmpWhere : ' + tmpWhere);
                                if (tmpWhere != null) {
                                    if (condition == '' && tmpWhere != '') {
                                        if (i > 0 && operator != '') {
                                            whereClause += 'AND ( ' + tmpWhere + ')';
                                        } else {
                                            whereClause += ' ( ' + tmpWhere + ')';
                                            operator = 'AND';
                                        }
                                    } else {
                                        Integer index = i + 1;
                                        String currenIndex = String.valueOf(index);
                                        Integer len = conditionList.size();
                                        for (Integer l = len - 1; l >= 0; l--) {
                                            if (conditionList[l].isWhitespace()) {
                                                conditionList.remove(l);
                                            }
                                        }
                                        len = conditionList.size();
                                        for (Integer j = 0; j < len; j++) {
                                            if (currenIndex.equalsignorecase(conditionList[j])) {
                                                if (tmpWhere == '') {
                                                    conditionList[j] = '';
                                                    if (
                                                        j + 1 < len &&
                                                        conditionList[j + 1].contains(')') &&
                                                        !conditionList[j - 1].contains('(')
                                                    ) {
                                                        conditionList[j - 1] = '';
                                                    } else if (j + 1 < len && !conditionList[j + 1].contains(')')) {
                                                        conditionList[j + 1] = '';
                                                    }
                                                } else {
                                                    conditionList[j] = tmpWhere;
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            if (conditionList.size() > 0) {
                                // System.debug('@@@@conditionList:::: ' + conditionList);
                                conditionList = cCreateTreatmentTaskService.removeParentheses(conditionList);
                                whereClause = String.join(conditionList, ' ');
                                // System.debug('@@@ whereClause :::: ' + whereClause);
                            }
                            String query = ' SELECT Id, OwnerId, celsrm__Auto_Treatment_Enabled__c FROM Account ';
                            //-- Starts | FIN-9026 | Changed by Ravi | 5 Mar 2026 --//
                            // query += ' WHERE celsrm__AI_Dunning_Enabled__c = TRUE';
                            if (whereClause != '') {
                                // query += ' AND ' + ' ( ( ' + whereClause + ' ) ) ';
                                query += ' WHERE ' + ' ( ( ' + whereClause + ' ) ) ';
                            }
                            //-- End | FIN-9026 | Changed by Ravi | 5 Mar 2026 --//
                            System.debug('query>>>' + query);
                            List<Account> finalAccounts = Database.query(query);

                            if (!finalAccounts.isEmpty()) {
                                for (Account fAcc : finalAccounts) {
                                    accIdTOOwnerId.put(fAcc.Id, fAcc.OwnerId);
                                    //-- Start | FIN-9703 | Changed by Dhwanil | 29 April 2026 --//
                                    accIdTOAutoTreatmentEnabled.put(fAcc.Id, fAcc.celsrm__Auto_Treatment_Enabled__c);
                                    //-- ends | FIN-9703 | Changed by Dhwanil | 29 April 2026 --//
                                    if (accountIdToTreatments.containsKey(fAcc.Id)) {
                                        List<celsrm__Treatment__c> tmp = accountIdToTreatments.get(fAcc.Id);
                                        tmp.add(treatment);
                                        accountIdToTreatments.put(fAcc.Id, tmp);
                                    } else {
                                        accountIdToTreatments.put(fAcc.Id, new List<celsrm__Treatment__c>{ treatment });
                                    }
                                }
                            }
                        }
                    }
                } catch (Exception e) {
                    System.debug('Error while processing treatment ' + treatment.Name + ': ' + e.getMessage());
                }
            }
        }
    }

    public void finish(Database.BatchableContext bc) {
        if (!accountIdToTreatments.isEmpty()) {
            //-- Start | FIN-9703 | Changed by Dhwanil | 29 April 2026 --//
            Database.executeBatch(
                new cSRMTreatmentProcessor(accountIdToTreatments, treatmentsMap, accIdTOOwnerId, true, accIdTOAutoTreatmentEnabled),
                batchsize
            );
            //-- end | FIN-9703 | Changed by Dhwanil | 29 April 2026 --//
        }
        if (!stateTreatmentIds.isEmpty()) {
            String cron = cSRMTreatmentUtility.getCronForDatetime(futureDt);
            String jobName = 'TreatmentTaskCreationJob_' + Datetime.now().getTime();
            System.schedule(jobName, cron, new cCreateTreatmentTaskService(stateTreatmentIds, batchsize));
        }
    }

    public void execute(SchedulableContext sc) {
        if (!stateTreatmentIds.isEmpty()) {
            Database.executeBatch(new cCreateTreatmentTaskService(stateTreatmentIds, batchsize), 1);
        } else {
            Database.executeBatch(new cCreateTreatmentTaskService(batchsize), 1);
        }
    }

    public static List<String> removeParentheses(List<String> conditionList) {
        Integer len = conditionList.size();
        for (Integer i = len - 1; i >= 0; i--) {
            if (conditionList[i].isWhitespace()) {
                conditionList.remove(i);
            }
        }
        len = conditionList.size();
        for (Integer j = 0; j < len; j++) {
            if (conditionList[j].equalsignorecase('(')) {
                if (conditionList[j + 1].equalsignorecase(')')) {
                    conditionList[j] = '';
                    conditionList[j + 1] = '';
                    if (
                        j + 2 < len &&
                        conditionList[j + 2].equalsignorecase(')') &&
                        (conditionList[j - 1] == 'AND' || conditionList[j - 1] == 'OR')
                    ) {
                        conditionList[j - 1] = '';
                    } else if (j + 2 < len && (conditionList[j + 2] == 'AND' || conditionList[j + 2] == 'OR')) {
                        conditionList[j + 2] = '';
                    }
                    conditionList = removeParentheses(conditionList);
                    break;
                }
            }
        }
        return conditionList;
    }

    public static String createCondition(cSRMTreatmentMapper.Criteria c, String obj) {
        // System.debug('Account Criteria>>>' + c);
        String clause = '';
        if (c.value == null || c.value.trim() == '' || c.value.trim() == 'null') {
            clause += ' ( ' + c.field + ' ' + c.operator + ' NULL ) ';
        } else {
            String fieldtype = String.valueOf(
                Schema.getGlobalDescribe().get(obj).getDescribe().fields.getMap().get(c.field).getDescribe().getType()
            );
            String quotes = '';
            // Handle IN, NOT IN, INCLUDE, EXCLUDE, LIKE, and NOT LIKE without bind variables
            if (c.operator == 'IN' || c.operator == 'NOT IN' || c.operator == 'INCLUDE' || c.operator == 'EXCLUDE') {
                List<String> valuesList = c.value.split(',');
                String formattedValues = '';
                String actualOperator = (c.operator == 'INCLUDE')
                    ? 'IN'
                    : (c.operator == 'EXCLUDE') ? 'NOT IN' : c.operator;
                for (String val : valuesList) {
                    val = val.trim();
                    if (
                        fieldtype.equalsIgnoreCase('boolean') ||
                        fieldtype.equalsIgnoreCase('Integer') ||
                        fieldtype.equalsIgnoreCase('Long') ||
                        fieldtype.equalsIgnoreCase('Double') ||
                        fieldtype.equalsIgnoreCase('Currency') ||
                        fieldtype.equalsIgnoreCase('Percent')
                    ) {
                        formattedValues += val + ',';
                    } else {
                        formattedValues += '\'' + String.escapeSingleQuotes(val) + '\',';
                    }
                }
                formattedValues = formattedValues.removeEnd(',');
                clause += ' ( ' + c.field + ' ' + actualOperator + ' (' + formattedValues + ') ) ';
            } else if (c.operator == 'LIKE' || c.operator == 'NOT LIKE') {
                String value = '%' + c.value + '%';
                clause += (c.operator == 'NOT LIKE' ? 'NOT(' : ' ( ') + c.field + ' ' + 'LIKE' + ' \'' + value + '\' ) ';
            } else if (fieldtype.equalsIgnoreCase('boolean')) {
                if (c.value.equalsIgnoreCase('true') || c.value.equalsIgnoreCase('false')) {
                    Boolean value = Boolean.valueOf(c.value);
                    clause += ' ( ' + c.field + ' ' + c.operator + ' ' + quotes + value + quotes + ' ) ';
                }
            } else if (fieldtype.equalsIgnoreCase('Integer')) {
                try {
                    Integer value = Integer.valueOf(c.value);
                    clause += ' ( ' + c.field + ' ' + c.operator + ' ' + quotes + value + quotes + ' ) ';
                } catch (Exception e3) {
                    System.debug('Value Is not Integer');
                }
            } else if (fieldtype.equalsIgnoreCase('Long')) {
                try {
                    Long value = Long.valueOf(c.value);
                    clause += ' ( ' + c.field + ' ' + c.operator + ' ' + quotes + value + quotes + ' ) ';
                } catch (Exception e3) {
                    System.debug('Value Is not Long');
                }
            } else if (fieldtype.equalsIgnoreCase('Double')) {
                try {
                    Double value = Double.valueOf(c.value);
                    clause += ' ( ' + c.field + ' ' + c.operator + ' ' + quotes + value + quotes + ' ) ';
                } catch (Exception e3) {
                    System.debug('Value Is not Double');
                }
            } else if (fieldtype.equalsIgnoreCase('Currency')) {
                try {
                    Decimal value = Decimal.valueOf(c.value);
                    clause += ' ( ' + c.field + ' ' + c.operator + ' ' + quotes + value + quotes + ' ) ';
                } catch (Exception e3) {
                    System.debug('Value Is not Decimal');
                }
            } else if (fieldtype.equalsIgnoreCase('Percent')) {
                try {
                    Double value = Double.valueOf(c.value);
                    clause += ' ( ' + c.field + ' ' + c.operator + ' ' + quotes + value + quotes + ' ) ';
                } catch (Exception e3) {
                    System.debug('Value Is not Double');
                }
            } else if (fieldtype.equalsIgnoreCase('Date')) {
                try {
                    Date.valueOf(c.value);
                    clause += ' ( ' + c.field + ' ' + c.operator + ' ' + quotes + c.value + quotes + ' ) ';
                } catch (Exception e3) {
                    System.debug('Value Is not Date Format');
                }
            } else if (fieldtype.equalsIgnoreCase('DateTime')) {
                try {
                    Date.valueOf(c.value);
                    clause += ' ( DAY_ONLY( ' + c.field + ')' + ' ' + c.operator + ' ' + quotes + c.value + quotes + ' ) ';
                } catch (Exception e3) {
                    System.debug('Value Is not Date Format');
                }
            } else if (fieldtype.equalsIgnoreCase('Time')) {
                // No direct formatting for Time in this context
            } else {
                quotes = '\'';
                String value = String.valueOf(c.value);
                if (c.operator == 'LIKE') {
                    value = '%' + value + '%';
                }
                clause += ' ( ' + c.field + ' ' + c.operator + ' ' + quotes + value + quotes + ' ) ';
            }
        }
        return clause;
    }
}