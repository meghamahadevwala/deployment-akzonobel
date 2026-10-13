//-- Starts |FIN-7502| Changed by Asera | 25 Nov 2025 --//
global with sharing class UserActivityActionController implements celsrm.GOGIScreenCustomLogic {

    global Map<Object, Object> invoke(String functionName, Map<Object, Object> inMap) {
        try {
            if (functionName == 'onLoadLogActivity') {
                inMap = onLoadLogActivity(inMap);
            }
        } catch (Exception ex) {
            System.debug('Class: LogActivity | Linenumber: ' + ex.getLineNumber() + ' | Message: ' + ex.getMessage());
        }
        return inMap;
    }
    public static Map<Object, Object> onLoadLogActivity(Map<Object, Object> inMap) {
        System.debug('From onLoadLogActivity: ' + JSON.serialize(inMap));
    
        try {
            // Create User Activity record
            celsrm__User_Activity__c activity = new celsrm__User_Activity__c();
    
            // Serialize full input map as metadata
            Map<String, Object> metadataMap = new Map<String, Object>{
                'ScreenObject' => inMap
            };
            String metadataJson = JSON.serialize(metadataMap);
    
            // Required fields
            activity.OwnerId = UserInfo.getUserId();
    
            if (inMap.containsKey('ggScreenName')) {
                activity.celsrm__Screen_Name__c = (String) inMap.get('ggScreenName');
            }
            activity.celsrm__Action_Performed__c = false;
    
            // Optional fields
            if (inMap.containsKey('actionTakenTime')) {
                activity.celsrm__Action_Taken_Time__c = (Datetime) inMap.get('actionTakenTime');
            }
                
            // Account assignment based on screen type
            String screenName = (String) inMap.get('ggScreenName');
            system.debug('from system debug'+ screenName);
            if (screenName == 'Reverse Dispute') {
                // Extract from nested customerName.id
                if (inMap.containsKey('customerName')) {
                    Map<Object, Object> customerMap = (Map<Object, Object>) inMap.get('customerName');
                    if (customerMap != null && customerMap.containsKey('id')) {
                        String accId = (String) customerMap.get('id');
                        if (accId != null && accId.startsWith('001')) {
                            activity.celsrm__Account__c = accId;
                        }
                    }
                }
            } else if (inMap.containsKey('accountId')) {
                // Standard fallback for other screens
                String accId = (String) inMap.get('accountId');
                if (accId != null && accId.startsWith('001')) {
                    activity.celsrm__Account__c = accId;
                }
            } else if(screenName == 'ReverseDispute') {
                Id accId = (Id) inMap.get('Id');
                activity.celsrm__Screen_Name__c = 'Account: Reverse Dispute';
                activity.celsrm__Account__c = accId;
            } else if(screenName == 'ReversePromise') {
                if(inMap.containsKey('calledFromTransactionDetailScreen') && Boolean.valueOf(inMap.get('calledFromTransactionDetailScreen')) == true) {
                    activity.celsrm__Screen_Name__c = 'Transaction: Reverse Promise';
                    Id transactionId = (Id) inMap.get('Id');
                    activity.celsrm__Transaction__c = transactionId;
                    activity.celsrm__Account__c = (Id) inMap.get('celsrm__Account__c');
                }  else {
                    activity.celsrm__Screen_Name__c = 'Account: Reverse Promise';
                    Id accId = (Id) inMap.get('Id');
                    activity.celsrm__Account__c = accId;
                }
            } else if(screenName == 'Add Note On Invoices') { 
                if(inMap.containsKey('calledFromTransactionDetailScreen') && Boolean.valueOf(inMap.get('calledFromTransactionDetailScreen')) == true) {
                    activity.celsrm__Screen_Name__c = 'Transaction: Add Note';
                    Id transactionId = (Id) inMap.get('Id');
                    activity.celsrm__Transaction__c = transactionId;
                    activity.celsrm__Account__c = (Id) inMap.get('celsrm__Account__c');
                } else {
                    activity.celsrm__Screen_Name__c = 'Account: Add Note';
                    Id accId = (Id) inMap.get('Id');
                    activity.celsrm__Account__c = accId;
                }
            } else if(screenName == 'AddNoteOnAccount') {
                activity.celsrm__Screen_Name__c = 'Account: Add Note';
                Id accId = (Id) inMap.get('Id');
                activity.celsrm__Account__c = accId;
            } else if(screenName == 'SRMTransactionGridScreen') {
                Id accId = (Id) inMap.get('Id');
                activity.celsrm__Account__c = accId;
                activity.celsrm__Screen_Name__c = 'Account: Transactions Tab';
            } else if(screenName == 'AccountNotes') {
                Id accId = (Id) inMap.get('Id');
                activity.celsrm__Account__c = accId;
                activity.celsrm__Screen_Name__c = 'Account: Notes Tab';
            } else if(screenName == 'Disputes On Account') {
                Id accId = (Id) inMap.get('Id');
                activity.celsrm__Account__c = accId;
                activity.celsrm__Screen_Name__c = 'Account: Disputes Tab';
            } else if(screenName == 'Account Collection Activity'){
                Id accId = (Id) inMap.get('Id');
                activity.celsrm__Account__c = accId;
                activity.celsrm__Screen_Name__c = 'Account: Collection Activity Tab';
            } else if(screenName == 'Collection Scorecard'){
                Id accId = (Id) inMap.get('Id');
                activity.celsrm__Account__c = accId;
                activity.celsrm__Screen_Name__c = 'Account: Scorecrad Tab';
            } else if(screenName == 'AccountDetailMailboxScreen'){
                Id accId = (Id) inMap.get('Id');
                activity.celsrm__Account__c = accId;
                activity.celsrm__Screen_Name__c = 'Account: Emails Tab';
            } else if(screenName == 'TransactionDisputeGrid'){
                Id trnId = (Id) inMap.get('Id');
                activity.celsrm__Transaction__c = trnId;
                activity.celsrm__Screen_Name__c = 'Transaction: Dispute Tab';
            } else if(screenName == 'BillingDataInTransaction'){
                Id trnId = (Id) inMap.get('Id');
                activity.celsrm__Transaction__c = trnId;
                activity.celsrm__Screen_Name__c = 'Transaction: Billing Items Tab';
            } else if(screenName == 'Transaction Collection Activity'){
                Id trnId = (Id) inMap.get('Id');
                activity.celsrm__Transaction__c = trnId;
                activity.celsrm__Screen_Name__c = 'Transaction: Collection Activity Tab';
            } else if(screenName == 'Transaction Notes'){
                Id trnId = (Id) inMap.get('Id');
                activity.celsrm__Transaction__c = trnId;
                activity.celsrm__Screen_Name__c = 'Transaction: Notes Tab';
            }
            //-- Start | FIN-8807 | Changed by Ravi | 06 Jan 2026 --//
            else if(screenName == 'CA_AddComment'){
                Id paymentBatchId = (Id) inMap.get('Id');
                activity.celsrm__Payment_Batch__c = paymentBatchId;
                activity.celsrm__Screen_Name__c = 'Payment Batch: Add Comment';
            } else if(screenName == 'CA_UploadRemittance'){
                Id paymentId = (Id) inMap.get('PaymentId');
                activity.celsrm__Cashapp_Payment__c = paymentId;
                activity.celsrm__Screen_Name__c = 'Upload Remittance';
            } else if(screenName == 'CA_composeEmailWebCash'){
                Id paymentId = (Id) inMap.get('PaymentId');
                activity.celsrm__Cashapp_Payment__c = paymentId;
                if (inMap.containsKey('accountId')) {
                    activity.celsrm__Account__c = String.valueOf(inMap.get('accountId'));
                }
                activity.celsrm__Screen_Name__c = 'Payment Batch: Send Email';
            }
            //-- End | FIN-8807 | Changed by Ravi | 06 Jan 2026 --//
    
            // Other optional relationships
            if (inMap.containsKey('transactionId')) 
                activity.celsrm__Transaction__c = (Id) inMap.get('transactionId');

                // Check if Reverse Dispute screen
            if (screenName == 'Reverse Dispute') {
                if (inMap.containsKey('Id')) {
                    activity.celsrm__Screen_Name__c = 'Dispute: Reverse Dispute';
                    String disputeId = String.valueOf(inMap.get('Id'));
                    if (disputeId != null) {
                        activity.celsrm__Dispute__c = disputeId;
                    }
                }

            } else if (inMap.containsKey('disputeId')) {
                String disputeId = String.valueOf(inMap.get('disputeId'));
                if (disputeId != null) {
                    activity.celsrm__Dispute__c = disputeId;
                }
            }
    
            activity.celsrm__Additional_Metadata__c = metadataJson;
    
            insert activity;
            System.debug('From activity: ' + activity.Id);
            if (screenName == 'Reverse Dispute') {
                inMap.put('fromDisputeDetails', 'true');
            }
            inMap.put('activityLogIdFromScreen', activity.Id);
            inMap.put('activityLogId', activity.Id);
    
        } catch (Exception e) {
            throw new AuraHandledException('Failed to log activity: ' + e.getMessage());
        }
    
        return inMap;
    }
    
    
    
}
//-- End |FIN-7502| Changed by Asera | 25 Nov 2025 --//