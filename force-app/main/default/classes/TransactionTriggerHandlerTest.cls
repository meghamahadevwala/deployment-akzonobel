@isTest
public with sharing class TransactionTriggerHandlerTest {
    public static testMethod void testMethod1() {
        celsrm__Trigger_Configuration__c triggerConf = new celsrm__Trigger_Configuration__c();
        triggerConf.Auto_Dispute_Closure_for_Cleared_Invoice__c = true;
        insert triggerConf;
        Account acc = DataGenerator.insertAccount();
        celsrm__Transaction__c trx = DataGenerator.insertTransaction(acc);
        trx.celsrm__Close_Date__c = Date.today();
        update trx;
        
        List<celsrm__Dispute__c> disList = DataGenerator.insertDispute(trx, acc, 1, 'In Progress');
        List<celsrm__Dispute_Workflow_Matrix__c> dwmList = DataGenerator.insertDisputeWorkflowMatrix('100 Financial & Invoicing', '101 Cash Discount Deduction');
        //-- Start | FIN-10143 | Changed by Asera | 20-Jul-2026 --//
        celsrm__Dispute_Workflow_Details__c dwd = DataGenerator.insertDisputeWorkflowDetails(dwmList.get(0), disList.get(0), 'Pending', 'Test');
        //-- End | FIN-10143 | Changed by Asera | 20-Jul-2026 --//
        
        Map<Id, celsrm__Transaction__c> newMap = new Map<Id, celsrm__Transaction__c>();
        newMap.put(trx.Id, trx);
        //TransactionTriggerHandler triggerHandleObj = new TransactionTriggerHandler();
        TransactionTriggerHandler.handleDisputeClosure(newMap);
        
        // celsrm__Trigger_Configuration__c validTC = DataGenerator.insertTriggerConf();
        // validTC.Auto_Dispute_Closure_for_Cleared_Invoice__c = true;
        // update validTC;
        // 
        // triggerHandleObj.handleDisputeClosure();
    }
}