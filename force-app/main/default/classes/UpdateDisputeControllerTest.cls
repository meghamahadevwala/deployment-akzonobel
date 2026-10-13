@isTest
public with sharing class UpdateDisputeControllerTest {

    @isTest
    static void myUnitTest() {
        Account acc = DataGenerator.insertAccount();
        celsrm__Transaction__c trans = DataGenerator.insertTransaction(acc);
        List<celsrm__Dispute__c> dispute = DataGenerator.insertDispute(trans, acc, 2);
        // START - MM - FIN-7983 - Test Coverage
        // List<celsrm__Dispute_Workflow_Matrix__c> dwmList = DataGenerator.insertDisputeWorkflowMatrix('Billing', 'Tax rate incorrect');
        List<celsrm__Dispute_Workflow_Matrix__c> dwmList = DataGenerator.insertDisputeWorkflowMatrix('100 Financial & Invoicing', '101 Cash Discount Deduction');
        // END - MM - FIN-7983 - Test Coverage
        celsrm__Dispute_Workflow_Matrix__c dwm = [SELECT Id FROM celsrm__Dispute_Workflow_Matrix__c where celsrm__Level__c = 0 ];
        //-- Start | FIN-10143 | Changed by Asera | 20-Jul-2026 --//
        celsrm__Dispute_Workflow_Details__c dwd = DataGenerator.insertDisputeWorkflowDetails(dwm, dispute[0], 'Pending', 'Resolve');
        //-- End | FIN-10143 | Changed by Asera | 20-Jul-2026 --//

        Map<Object, Object> inMap = new Map<Object, Object>();
        inMap.put('Id', dispute[0].Id);
        inMap.put('type', 'Billing');
        inMap.put('reasonCode', 'Tax rate incorrect');
        inMap.put('resolutionCode', 'Paid');
        inMap.put('noteBody', 'noteBody');
        inMap.put('noteTitle', 'noteTitle');
        inMap.put('disputeAmount', dispute[0].celsrm__Amount__c);
        
        inMap.put('rootCause', 'rootCause');
        inMap.put('disputeDetailId', dwd.Id);
        inMap.put('disputeType', 'Billing');

        Map<Object,Object> userMap = new Map<Object, Object>();
        userMap.put('id', UserInfo.getUserId());
        userMap.put('name', UserInfo.getUserName());
        inMap.put('nextResolverApprover',userMap);

        Map<Object,Object> accountMap = new Map<Object, Object>();
        accountMap.put('id', acc.Id);
        accountMap.put('name', acc.Name);
        inMap.put('customerName',accountMap);

        Map<Object,Object> invoiceMap = new Map<Object, Object>();
        invoiceMap.put('id', trans.Id);
        invoiceMap.put('name', trans.Name);
        inMap.put('invoiceNumber',invoiceMap);
        

        UpdateDisputeController updateDispute = new UpdateDisputeController();
        updateDispute.invoke('onPageLoadFunction', inMap);

        dwm = [SELECT Id FROM celsrm__Dispute_Workflow_Matrix__c where celsrm__Level__c = 1 ];
        //-- Start | FIN-10143 | Changed by Asera | 20-Jul-2026 --//
        dwd = DataGenerator.insertDisputeWorkflowDetails(dwm, dispute[0], 'Pending', 'Resolve');
        //-- End | FIN-10143 | Changed by Asera | 20-Jul-2026 --//
        inMap.put('disputeDetailId', dwd.Id);
        updateDispute.invoke('onPageLoadFunction', inMap);

        inMap.put('userAction', 'add-note');
        inMap.put('doNotSubmit', '');
        updateDispute.invoke('UpdateDispute', inMap);

        inMap.put('userAction', 'reject');
        updateDispute.invoke('UpdateDispute', inMap);

        inMap.put('userAction', 'resolve');
        inMap.put('disputeMatrixId', dwm.Id);
        inMap.put('resolverApproverType', 'Approver');
        updateDispute.invoke('UpdateDispute', inMap);

        inMap.put('userAction', 'approve');
        inMap.put('disputeMatrixId', dwm.Id);
        inMap.put('resolverApproverType', 'Approver');
        inMap.put('isLastApprover', true);
        updateDispute.invoke('UpdateDispute', inMap);

        inMap.put('isLastApprover', false);
        updateDispute.invoke('UpdateDispute', inMap);

        userMap = new Map<Object, Object>();
        userMap.put('id', null);
        userMap.put('name', null);
        inMap.put('nextResolverApprover',userMap);
        inMap.put('userAction', 'resolve');
        updateDispute.invoke('UpdateDispute', inMap);

        inMap.put('isLastApprover', true);
        updateDispute.invoke('UpdateDispute', inMap);

        inMap.put('isLastApprover', false);
        inMap.put('resolverApproverType', 'Resolver');
        updateDispute.invoke('UpdateDispute', inMap);

        inMap.put('reasonCode', 'Tax rate incorrect');
        updateDispute.invoke('UpdateDispute', inMap);

        inMap.put('resolverApproverType', 'approve');
        updateDispute.invoke('UpdateDispute', inMap);

        inMap.put('userAction', 'approve');
        inMap.put('disputeMatrixId', dwm.Id);
        inMap.put('resolverApproverType', 'Approver');
        updateDispute.invoke('UpdateDispute', inMap);

        inMap.put('userAction', 'on-hold');
        inMap.put('disputeStatus', 'In Progress');
        updateDispute.invoke('UpdateDispute', inMap);

        inMap.put('userAction', 'resume');
        inMap.put('disputeStatus', 'In Progress');
        inMap.put('disputePreviousStatus', 'Pending Approval');
        updateDispute.invoke('UpdateDispute', inMap);
        
        inMap.put('customerName','test');
        updateDispute.invoke('UpdateDispute', inMap);

        inMap.put('doNotSubmit', 'test');
        updateDispute.invoke('UpdateDispute', inMap);

        inMap.put('Id', null);
        updateDispute.invoke('onPageLoadFunction', inMap);

        //celsrm__Dispute__c dis = UpdateDisputeController.setApproverOnDispute(dispute[0], UserInfo.getUserId(), dwm.Id);
    }
}