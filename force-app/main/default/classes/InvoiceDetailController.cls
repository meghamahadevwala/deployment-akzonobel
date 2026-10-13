global with sharing class InvoiceDetailController implements celsrm.GOGIScreenCustomLogic {
    global Map<Object, Object> invoke(String functionName, Map<Object, Object> inMap) {
        String recordId = (String)inMap.get('Id');
        system.debug('from transaction screen>>' + JSON.serialize(inMap));
        if(functionName == 'onLoadInvoiceDetailScreen') {
            List<celsrm__Transaction__c> trxnList = [SELECT Id, Name, celsrm__Close_Date__c, celsrm__Balance__c, celsrm__Promised_Amount__c, celsrm__Account__c FROM celsrm__Transaction__c WHERE Id =: recordId]; // Added closed date
            for(celsrm__Transaction__c trxnObj: trxnList) {
                inMap.put('Name', trxnObj.Name);
                inMap.put('celsrm__Balance__c', trxnObj.celsrm__Balance__c);
                inMap.put('celsrm__Account__c', trxnObj.celsrm__Account__c);
                //-- Start | FIN-8525 | Changed by Asera | 14 Oct 2025 --//
                if(trxnObj.celsrm__Balance__c > 0 && trxnObj.celsrm__Close_Date__c == null) {
                    inMap.put('InvoiceType', 'debit');
                //-- End | FIN-8525 | Changed by Asera | 14 Oct 2025 --//
                } else {
                    inMap.put('InvoiceType', 'credit');
                }
                //-- Starts | FIN-7796 | Changed by Dilshad | 26-Jun-2025 --//
                //-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
                if(trxnObj.celsrm__Balance__c > 0 || !celsrm__Dispute_Configuration__c.getOrgDefaults().celsrm__Allow_Only_Debit_Invoices__c) {
                    inMap.put('ShowCreateDisputeButton', 'true');
                } 
                //-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
                //-- Ends | FIN-7796 | Changed by Dilshad | 26-Jun-2025 --//
                if(trxnObj.celsrm__Promised_Amount__c > 0) {
                    inMap.put('celsrm__Promised_Amount__c', 'true');
                } else {
                    inMap.put('celsrm__Promised_Amount__c', 'false');
                }
                //-- Starts |FIN-7502| Changed by Asera | 25 Nov 2025 --//
                if(String.valueOf(inMap.get('calledFromTransactionDetailScreen')) == 'true') {
                    try {
                        // String transactionListJson = JSON.serialize(inMap.get('TransactionList'));
                        Map<String, Object> metadataMap = new Map<String, Object>{
                            'TransactionList' => trxnObj,
                            'timestamp' => String.valueOf(Datetime.now())
                        };
                        String metadataJson = JSON.serialize(metadataMap);
                        Map<String, Object> inputParams = new Map<String, Object>{
                            'userId' => UserInfo.getUserId(),
                            'pageScreenName' => 'Transaction Detail Screen',
                            'actionPerformed' => false,
                            'actionTakenTime' => null,
                            'accountId' => inMap.get('celsrm__Account__c'),
                            'transactionId' => recordId,
                            'disputeId' => null,
                            'additionalMetadata' => metadataJson
                        };
                        System.debug('Full inputParams: ' + JSON.serialize(inputParams));
                        Id activityId = celsrm.SRMUtilityController.logActivity(JSON.serialize(inputParams));
                        System.debug('Full activity : ' + activityId);
                        inMap.put('activityLogId', activityId);
                    } catch (Exception e) {
                        System.debug('Error logging activity: ' + e.getMessage() + ' ' + e.getLineNumber());
                        inMap.put('ggErrorMessage', e.getMessage() + ' ' + e.getLineNumber());
                    } 
                }
                //-- End |FIN-7502| Changed by Asera | 25 Nov 2025 --//
                //-- Start | FIN-8525 | Changed by Asera | 14 Oct 2025 --//
                if(trxnObj.celsrm__Close_Date__c != null) {
                    inMap.put('ShowCreateDisputeButton', 'false');
                }
                //-- End | FIN-8525 | Changed by Asera | 14 Oct 2025 --//

            }
        }
        return inMap;
    }

}