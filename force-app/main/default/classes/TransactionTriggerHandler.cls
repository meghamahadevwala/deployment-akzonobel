public with sharing class TransactionTriggerHandler {
    public static void handleDisputeClosure(Map<Id, celsrm__Transaction__c> newMap) {
        try {
            celsrm__Trigger_Configuration__c triggerConfig = celsrm__Trigger_Configuration__c.getOrgDefaults();
            if(triggerConfig.Auto_Dispute_Closure_for_Cleared_Invoice__c) {
                Set<Id> invoiceIds = newMap.keySet();
                Set<Id> disputeIds = new Set<Id>();
                Set<Id> transIds = new Set<Id>();
                Set<Id> accIds = new Set<Id>();
                //-- Starts | Update dispute - We will close all such dispute --//
                //-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 -- added namesapce on fields celsrm__Workflow_Matrix_Id__c//
                List<celsrm__Dispute__c> disputeList = [SELECT Id, celsrm__Status__c, celsrm__Latest_Note_Title__c, celsrm__Latest_Note__c, celsrm__Latest_Note_Date__c, 
                celsrm__Latest_Note_Entered_By__c, celsrm__Dispute_Resolver__c, celsrm__Workflow_Matrix_Id__c, celsrm__Transaction__c, celsrm__Transaction__r.celsrm__Account__c 
                FROM celsrm__Dispute__c WHERE celsrm__Transaction__c IN:invoiceIds AND celsrm__Transaction__r.celsrm__Close_Date__c != NULL AND celsrm__Status__c IN ('In Progress', 'Pending Approval', 'On Hold', 'Pending Resolution')];
                if(disputeList != null && disputeList.size() > 0) {
                    for (celsrm__Dispute__c disObj : disputeList) {
                        disObj.Is_Auto_Closed__c = true;
                        disObj.celsrm__Status__c = 'Auto Closed';
                        disObj.celsrm__Latest_Note_Title__c = 'Dispute Auto Closed'; 
                        disObj.celsrm__Latest_Note__c = 'Dispute is closed because invoice is cleared.';
                        disObj.celsrm__Latest_Note_Date__c = Date.today();
                        disObj.celsrm__Latest_Note_Entered_By__c = UserInfo.getUserId();
                        //-- Start | FIN-9672 | Changed by Ravi | 05 May 2026 --//
                        //-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
                        disObj.celsrm__Resolver_User_Master__c = null;
                        //-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
                        //-- End | FIN-9672 | Changed by Ravi | 05 May 2026 --//
                        disObj.celsrm__Dispute_Resolver__c = null;
                        disObj.celsrm__Workflow_Matrix_Id__c = null;
                        disObj.celsrm__Close_Date__c = Date.Today();
                        disputeIds.add(disObj.Id);
                        transIds.add(disObj.celsrm__Transaction__c);
                        accIds.add(disObj.celsrm__Transaction__r.celsrm__Account__c);
                    }
                    update disputeList;
                }
                //-- Ends | Update dispute - We will close all such dispute --//

                //-- Starts | Update dispute workflow detail --//
                //-- Start | FIN-10143 | Changed by Asera | 20-Jul-2026 --//
                List<celsrm__Dispute_Workflow_Details__c> dwdList = [
                    SELECT Id, celsrm__Status__c, celsrm__Action_Date__c, celsrm__User_Action__c, celsrm__Action_Taken_By__c
                    FROM celsrm__Dispute_Workflow_Details__c
                    WHERE celsrm__Dispute__c IN: disputeIds
                    AND celsrm__Status__c = 'Pending'
                ];
                
                if(dwdList != null && dwdList.size() > 0) {
                    for (celsrm__Dispute_Workflow_Details__c dwdObj : dwdList) {
                        dwdObj.celsrm__Status__c = 'Auto Completed';
                        dwdObj.celsrm__Action_Date__c = Date.today();
                        dwdObj.celsrm__User_Action__c = '-';
                        dwdObj.celsrm__Action_Taken_By__c = UserInfo.getUserId();
                    }
                    update dwdList;
                }
                //-- End | FIN-10143 | Changed by Asera | 20-Jul-2026 --//
                //-- Ends | Update dispute workflow detail --//
                //-- Starts | Capture celonis event at dispute level --//
                if(disputeIds.size() > 0) {
                    List<String> disputeIdList = new List<String>();
                    for (Id id : disputeIds) {
                        disputeIdList.add(String.valueOf(id));
                    }
                    celsrm.SRMUtilityController.insertActivity( disputeIdList, 'celsrm__Dispute__c', 'Dispute Auto Closed', 100, 'Dispute is closed because invoice is cleared.', UserInfo.getUserId(), null, 'Internal');
                }
                //-- Ends | Capture celonis event at dispute level --//

                // //-- Starts | Capture celonis event at transaction level --//
                // if(transIds.size() > 0) {
                //     List<String> transList = new List<String>();
                //     for (Id id : transIds) {
                //         transList.add(String.valueOf(id));
                //     }
                //     celsrm.SRMUtilityController.insertActivity(transList, 'celsrm__Transaction__c', 'Dispute Auto Closed', 100, 'Dispute is closed because invoice is cleared.', UserInfo.getUserId(), null, 'Internal');
                // }
                // //-- Ends | Capture celonis event at transaction level --//

                // //-- Starts | Capture celonis event at account level --//
                // if(accIds.size() > 0) {
                //     List<String> accList = new List<String>();
                //     for (Id id : accIds) {
                //         accList.add(String.valueOf(id));
                //     }
                //     celsrm.SRMUtilityController.insertActivity(accList, 'celsrm__Account__c', 'Dispute Auto Closed', 100, 'Dispute is closed because invoice is cleared.', UserInfo.getUserId(), null, 'Internal');
                // }
                // //-- Ends | Capture celonis event at account level --//
            }
        } catch (Exception ex) {
            System.debug('Error in Trigger TransactionTrigger: ' + ex.getMessage()+ '. =>' + ex.getStackTraceString());
        }
    }
}