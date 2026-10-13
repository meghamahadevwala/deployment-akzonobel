@isTest
public class DisputeConfigurationScreenControllerTest {
	@isTest
    static void myUnitTest() {
        // START - MM - FIN-7983 - Test Coverage
        // Dispute_Reminder_Escalation_Matrix__c dre = DataGenerator.insertDisputeReminderEscalation('Billing', 'PO overbilled (duplicated order entry)')[0];
        celsrm__Dispute_Reminder_Escalation_Matrix__c dre = DataGenerator.insertDisputeReminderEscalation('100 Financial & Invoicing', '101 Cash Discount Deduction')[0];
        // END - MM - FIN-7983 - Test Coverage

        // START - MM - FIN-7983 - Test Coverage
        // celsrm__Dispute_Workflow_Matrix__c dwm = DataGenerator.insertDisputeWorkflowMatrix('Billing', 'PO overbilled (duplicated order entry)')[0];
        celsrm__Dispute_Workflow_Matrix__c dwm = DataGenerator.insertDisputeWorkflowMatrix('100 Financial & Invoicing', '101 Cash Discount Deduction')[0];
        // END - MM - FIN-7983 - Test Coverage
        DisputeConfigurationScreenController disputeConfigurationScreenController = new DisputeConfigurationScreenController();
        Map<Object, Object> inMap = new Map<Object, Object>();
        disputeConfigurationScreenController.invoke('getDisputeWorkflowMatrixList', inMap);

        disputeConfigurationScreenController.invoke('getDisputeReminderAndEscalationMatrixList', inMap);
        //-- Starts | FIN-8207 | Change by Asera | 04-Sep-25 //
        inMap.put('Id', dwm.Id);
        inMap.put('isExternalUser' , true);
        inMap.put('externalUserEmail', 'test@test.com');
        disputeConfigurationScreenController.invoke('updateDisputeWorkflowMatrix', inMap);
        //-- End | FIN-8207 | Change by Asera | 04-Sep-25 //


        inMap.put('recordId', dre.Id);
        inMap.put('objectName', 'Dispute_Reminder_Escalation_Matrix__c');

        disputeConfigurationScreenController.invoke('onDeleteRecord', inMap);
        disputeConfigurationScreenController.invoke('activateReminderEscalation', inMap);

        inMap.put('recordId', dwm.Id);
        inMap.put('objectName', 'celsrm__Dispute_Workflow_Matrix__c');
        disputeConfigurationScreenController.invoke('onDeleteRecord', inMap);
    }
}