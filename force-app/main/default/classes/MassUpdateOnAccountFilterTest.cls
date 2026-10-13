@isTest
public with sharing class MassUpdateOnAccountFilterTest {
    public static testMethod void MassUpdateOnAccountFilterTest() {
        Account acc = DataGenerator.insertAccount();
        celsrm__Transaction__c trxn = DataGenerator.insertTransaction(acc);
        celsrm__Custom_List_View__c listView =  DataGenerator.insertCustomListView(true);
        Map<Object,Object> inMap = new Map<Object,Object>();
        inMap.put('ListViewObject','celsrm__Transaction__c');
        inMap.put('ListViewParentField','celsrm__Account__c');
        List<Object> objList = new List<Object>();
        Map<Object,Object> criMap = new Map<Object,Object>();
        criMap.put('Field','Name');
        criMap.put('Operator','equals');
        objList.add(criMap);
        criMap.put('Field','celsrm__Balance__c');
        criMap.put('Operator','not equal to');
        criMap.put('LogicalOperator','AND');
        objList.add(criMap);
        inMap.put('CriteriaGrid',objList);
        inMap.put('TransactionIDSearch','Invoice-001,invoice-002');
        // inMap.put('ListView',acc.Id);
        
        // inMap.put('CriteriaGrid','[{"LogicalOperator":"AND","Value":"0","Operator":"equals","Field":"celsrm__Balance__c"},{"LogicalOperator":null,"Value":null,"Operator":"not equal to","Field":"celsrm__Close_Date__c"}]');
        inMap.put('Id',acc.Id);
        try {
            MassUpdateOnAccountFilter test = new MassUpdateOnAccountFilter();
            test.invoke('UpdateCall', inMap);
        } catch(Exception e){
            system.debug('Exception caused>>>>'+e.getLineNumber() + e.getMessage() );
        }
        try {
            MassUpdateOnAccountFilter test = new MassUpdateOnAccountFilter();
            // inMap.put('CriteriaGrid',listView.celsrm__Filter_Criteria__c);
            criMap.put('Field','celsrm__Balance__c');
            criMap.put('Operator','greater than');
            criMap.put('LogicalOperator','AND');
            objList.add(criMap);
            inMap.put('CriteriaGrid',objList);
            test.invoke('', inMap);
        } catch(Exception e){
            system.debug('Exception caused>>>>'+e.getLineNumber() + e.getMessage() );
        }
        
    }
}