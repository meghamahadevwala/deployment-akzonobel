//Usages: The trigger should update the credit and scorecard related information back to the account level. 

trigger CreditReviewTriggerForAccountUpdate on celsrm__Credit_Review__c (after insert, after update) {

    if (celsrm__Trigger_Configuration__c.getOrgDefaults().Insert_Credit_Review_Account_Update__c) {
    
        if((Trigger.isInsert || Trigger.isUpdate) && Trigger.isAfter) {
            Set<Id> accountIds = new Set<Id>();
            for (celsrm__Credit_Review__c tempCR : Trigger.new) {
                if (tempCR.celsrm__Account__c != null) {
                    accountIds.add(tempCR.celsrm__Account__c);
                }
            }
            // Query Accounts once
            Map<Id, Account> accountMap = new Map<Id, Account>([
                SELECT Id,
                       celsrm__Risk_Score__c,
                       celsrm__Credit_Appoved_Date__c,
                       celsrm__Latest_Note__c,
                       celsrm__Credit_Limit__c,
                       celsrm__Limit_Valid_To_Date__c
                FROM Account
                WHERE Id IN :accountIds
            ]);
            List<Account> accountsToUpdate = new List<Account>();
            Set<String> approvedStatuses = new Set<String>{
                '40','11','12'
            };

            for (celsrm__Credit_Review__c tempCR : Trigger.new) {
                Account acc = accountMap.get(tempCR.celsrm__Account__c);
                celsrm__Credit_Review__c oldCR;
                if (Trigger.isUpdate) {
                    oldCR = Trigger.oldMap.get(tempCR.Id);
                }
                if (acc != null) {
                    if(Trigger.isInsert) {
                        acc.celsrm__Latest_Credit_Review__c = tempCR.Id;
                        if (approvedStatuses.contains(tempCR.celsrm__Status__c)) {
                            acc.celsrm__Credit_Limit__c = tempCR.celsrm__Approved_Credit_Limit__c;
                            acc.celsrm__Limit_Valid_To_Date__c = tempCR.Approved_Valid_To_Date__c;
                        }
                        accountsToUpdate.add(acc);
                    }
                    else if (Trigger.isUpdate) {
                        if(oldCR != null && oldCR.celsrm__Status__c != tempCR.celsrm__Status__c && approvedStatuses.contains(tempCR.celsrm__Status__c)) {
                            // acc.celsrm__Last_Credit_Review_Date__c = acc.celsrm__Credit_Appoved_Date__c = tempCR.Credit_Approved_Date__c;
                            acc.celsrm__Credit_Limit__c = tempCR.celsrm__Approved_Credit_Limit__c;
                            acc.celsrm__Limit_Valid_To_Date__c = tempCR.Approved_Valid_To_Date__c;
                            accountsToUpdate.add(acc);
                        }
                    }
                }
                //-- Starts |FIN-7510| Changed by Asera | 08 JAN 2026 --//
                if (Trigger.isUpdate) {
                    if (oldCR != null && tempCR.celsrm__Status__c != oldCR.celsrm__Status__c) {
                        try {
                            List<String> idSet = new List<String>{ tempCR.Id };
                            celsrm.SRMUtilityController.insertActivity(
                                idSet,
                                'celsrm__Credit_Review__c',
                                'Status Change',
                                null,
                                100,
                                'Credit Review Status Changed',
                                UserInfo.getUserId(),
                                null,
                                'Internal'
                            );

                            Map<String, Object> metadataMap =
                                new Map<String, Object>{
                                    'oldStatus' => oldCR.celsrm__Status__c,
                                    'newStatus' => tempCR.celsrm__Status__c,
                                    'creditReviewId' => tempCR.Id,
                                    'accountId' => tempCR.celsrm__Account__c
                                };

                            Map<String, Object> inputParams =
                                new Map<String, Object>{
                                    'userId' => UserInfo.getUserId(),
                                    'pageScreenName' => 'Credit Review : Status Change',
                                    'actionPerformed' => true,
                                    'actionTakenTime' => null,
                                    'accountId' => tempCR.celsrm__Account__c,
                                    'transactionId' => null,
                                    'creditReviewId' => tempCR.Id,
                                    'disputeId' => null,
                                    'additionalMetadata' => JSON.serialize(metadataMap)
                                };

                            celsrm.SRMUtilityController.logActivity( JSON.serialize(inputParams));

                        } catch (Exception e) {
                            System.debug(
                                'Error logging Credit Review activity: ' +
                                e.getMessage() + ' Line: ' + e.getLineNumber()
                            );
                        }
                    }
                }
            }
            //-- End |FIN-7510| Changed by Asera | 08 JAN 2026 --//
            // Update once
            if(!accountsToUpdate.isEmpty()) {
                Map<Id,Account> uniqueAccounts =
                    new Map<Id,Account>();
                for(Account acc : accountsToUpdate) {
                    uniqueAccounts.put(acc.Id, acc);
                }
                update uniqueAccounts.values();
            }
        }
    }
}