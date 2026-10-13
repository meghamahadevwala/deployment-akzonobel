trigger DisputeWorkflowMatrixTrigger on celsrm__Dispute_Workflow_Matrix__c (before insert, before update) {
    //-- Start | FIN-9672 | Changed by Ravi | 05 May 2026 --//
    DisputeWorkflowMatrixTriggerHandler.beforeSave(Trigger.new);
    //-- End | FIN-9672 | Changed by Ravi | 05 May 2026 --//
}