trigger AccountMasterTrigger on Account (after update, after insert) {

    static Set<Id> processedDpdIds = new Set<Id>();

    if (PropagateProfileDataToAccounts.skipAccountAutomation) {
        return;
    }

    if (trigger.isAfter) {
        String profileName = [SELECT Profile.Name FROM User WHERE Id = :UserInfo.getUserId()].Profile.Name;
        List<String> bvdIdsAdd = new List<String>();
        Boolean allowWritebackBySysAdmin = Credit_Configuration__c.getOrgDefaults().Allow_Write_back_by_Sys_Admin_Users__c;
        if (profileName.equalsIgnoreCase('System Administrator')) {
            if (trigger.isUpdate && allowWritebackBySysAdmin == false) {
                List<Account> bvdChangedAccounts = new List<Account>();

                for (Account newAcc : Trigger.new) {
                    if (newAcc.celsrm__App_Name__c == null || newAcc.celsrm__App_Name__c.toLowerCase() != 'credit') {
                        continue;
                    }
                    Account oldAcc = Trigger.oldMap.get(newAcc.Id);

                    if (oldAcc.BvD_ID_Number__c != newAcc.BvD_ID_Number__c) {
                        bvdChangedAccounts.add(newAcc);
                    }

                    if (oldAcc.BvD_ID_Number__c != newAcc.BvD_ID_Number__c ||
                        oldAcc.Calculated_Credit_Limit_Group_Currency__c != newAcc.Calculated_Credit_Limit_Group_Currency__c ||
                        oldAcc.celsrm__Check_Rule__c != newAcc.celsrm__Check_Rule__c ||
                        oldAcc.celsrm__Credit_Group__c != newAcc.celsrm__Credit_Group__c) {
                        if (newAcc.BvD_ID_Number__c != null && newAcc.BvD_ID_Number__c != '' &&
                            newAcc.Calculated_Credit_Limit_Group_Currency__c > 50000 &&
                            newAcc.celsrm__Check_Rule__c != 'Z08 Risk Class Child' &&
                            newAcc.celsrm__Credit_Group__c != '0001 - New customer / No score' &&
                            newAcc.celsrm__Credit_Group__c != '0007 - IC - Intercompany' &&
                            newAcc.celsrm__Credit_Group__c != '0008 - INAC - Inactive Customer' &&
                            newAcc.celsrm__Credit_Group__c != '0009 - RPDL - RPDL' &&
                            newAcc.celsrm__Credit_Group__c != '0010 - AGY - Agency/Lawyer' &&
                            newAcc.celsrm__Credit_Group__c != '0011 - ATR - Atradius' &&
                            newAcc.celsrm__Credit_Group__c != '0012 - WRT - Write Off' &&
                            newAcc.celsrm__Credit_Group__c != '0013 - BKR - Bankruptcy' &&
                            newAcc.celsrm__Credit_Group__c != '0014 - PCC - Pre-pay/Credit Card' &&
                            newAcc.celsrm__Credit_Group__c != '0016 - CAD - Cadex' &&
                            newAcc.celsrm__Credit_Group__c != '0006 - PP - Payment Plan') {
                            if (oldAcc.Calculated_Credit_Limit_Group_Currency__c != newAcc.Calculated_Credit_Limit_Group_Currency__c) {
                                if (oldAcc.Calculated_Credit_Limit_Group_Currency__c <= 50000) {
                                    bvdIdsAdd.add(newAcc.BvD_ID_Number__c);
                                }
                            } else {
                                bvdIdsAdd.add(newAcc.BvD_ID_Number__c);
                            }
                        }
                    }
                }

                if (!bvdChangedAccounts.isEmpty()) {
                    PropagateBvdIdToSiblingsService.propagateToSiblings(bvdChangedAccounts);
                }

            } else if (trigger.isInsert) {
                for (Account newAcc : Trigger.new) {
                    if (newAcc.celsrm__App_Name__c == null || newAcc.celsrm__App_Name__c.toLowerCase() != 'credit') {
                        continue;
                    }
                    if (newAcc.BvD_ID_Number__c != null && newAcc.BvD_ID_Number__c != '' &&
                        newAcc.Calculated_Credit_Limit_Group_Currency__c > 50000 &&
                        newAcc.celsrm__Check_Rule__c != 'Z08 Risk Class Child' &&
                        newAcc.celsrm__Credit_Group__c != '0001 - New customer / No score' &&
                        newAcc.celsrm__Credit_Group__c != '0007 - IC - Intercompany' &&
                        newAcc.celsrm__Credit_Group__c != '0008 - INAC - Inactive Customer' &&
                        newAcc.celsrm__Credit_Group__c != '0009 - RPDL - RPDL' &&
                        newAcc.celsrm__Credit_Group__c != '0010 - AGY - Agency/Lawyer' &&
                        newAcc.celsrm__Credit_Group__c != '0011 - ATR - Atradius' &&
                        newAcc.celsrm__Credit_Group__c != '0012 - WRT - Write Off' &&
                        newAcc.celsrm__Credit_Group__c != '0013 - BKR - Bankruptcy' &&
                        newAcc.celsrm__Credit_Group__c != '0014 - PCC - Pre-pay/Credit Card' &&
                        newAcc.celsrm__Credit_Group__c != '0016 - CAD - Cadex' &&
                        newAcc.celsrm__Credit_Group__c != '0006 - PP - Payment Plan' &&
                        newAcc.celsrm__Credit_Group__c != '0004 - ALA - Legal Action' &&
                        newAcc.celsrm__Credit_Group__c != '0005 - EMP - Employee') {
                        bvdIdsAdd.add(newAcc.BvD_ID_Number__c);
                    }
                }
            }
        }
        if (!profileName.equalsIgnoreCase('System Administrator') ||
                (profileName.equalsIgnoreCase('System Administrator') && allowWritebackBySysAdmin == true)) {
            // ── NON-SYSADMIN PATH ─────────────────────────────────────────────
            if (trigger.isUpdate) {
                List<String>             profileAccountIds   = new List<String>();
                List<String>             clAccountIds        = new List<String>();
                List<Map<String,String>> refUpdates          = new List<Map<String,String>>();
                List<Map<String,String>> bvdUpdates          = new List<Map<String,String>>();
                List<Account>            bvdChangedAccounts  = new List<Account>();
                List<Id>                 cgChangedAccountIds = new List<Id>();

                for (Account newAcc : Trigger.new) {
                    if (newAcc.celsrm__App_Name__c == null || newAcc.celsrm__App_Name__c.toLowerCase() != 'credit') {
                        continue;
                    }
                    Account oldAcc = Trigger.oldMap.get(newAcc.Id);

                    // To manage Profile data Changes
                    if (oldAcc.celsrm__Credit_Group__c != newAcc.celsrm__Credit_Group__c ||
                        oldAcc.celsrm__Check_Rule__c   != newAcc.celsrm__Check_Rule__c   ||
                        oldAcc.celsrm__Risk_Class__c   != newAcc.celsrm__Risk_Class__c) {
                        profileAccountIds.add(newAcc.Id);
                    }

                    // To propagate Credit Group to sibling accounts (same AccountNumber)
                    if (oldAcc.celsrm__Credit_Group__c != newAcc.celsrm__Credit_Group__c &&
                        newAcc.AccountNumber != null) {
                        cgChangedAccountIds.add(newAcc.Id);
                    }

                    // To manage Order Block Changes
                    if (oldAcc.celsrm__Order_Block__c != newAcc.celsrm__Order_Block__c) {
                        clAccountIds.add(newAcc.Id);
                    }

                    if (oldAcc.BvD_ID_Number__c != newAcc.BvD_ID_Number__c ||
                        oldAcc.Calculated_Credit_Limit_Group_Currency__c != newAcc.Calculated_Credit_Limit_Group_Currency__c ||
                        oldAcc.celsrm__Check_Rule__c != newAcc.celsrm__Check_Rule__c ||
                        oldAcc.celsrm__Credit_Group__c != newAcc.celsrm__Credit_Group__c) {
                        if (oldAcc.BvD_ID_Number__c != newAcc.BvD_ID_Number__c) {
                            Map<String,String> objMap = new Map<String,String>();
                            objMap.put('accountId',         newAcc.Id);
                            objMap.put('accountNumber',     newAcc.AccountNumber);
                            objMap.put('creditControlArea', newAcc.celsrm__Credit_Control_Area__c);
                            objMap.put('oldBvdId',          oldAcc.BvD_ID_Number__c);
                            objMap.put('newBvdId',          newAcc.BvD_ID_Number__c);
                            bvdUpdates.add(objMap);
                            bvdChangedAccounts.add(newAcc);
                        }

                        if (newAcc.BvD_ID_Number__c != null && newAcc.BvD_ID_Number__c != '' &&
                            newAcc.Calculated_Credit_Limit_Group_Currency__c > 50000 &&
                            newAcc.celsrm__Check_Rule__c != 'Z08 Risk Class Child' &&
                            newAcc.celsrm__Credit_Group__c != '0001 - New customer / No score' &&
                            newAcc.celsrm__Credit_Group__c != '0007 - IC - Intercompany' &&
                            newAcc.celsrm__Credit_Group__c != '0008 - INAC - Inactive Customer' &&
                            newAcc.celsrm__Credit_Group__c != '0009 - RPDL - RPDL' &&
                            newAcc.celsrm__Credit_Group__c != '0010 - AGY - Agency/Lawyer' &&
                            newAcc.celsrm__Credit_Group__c != '0011 - ATR - Atradius' &&
                            newAcc.celsrm__Credit_Group__c != '0012 - WRT - Write Off' &&
                            newAcc.celsrm__Credit_Group__c != '0013 - BKR - Bankruptcy' &&
                            newAcc.celsrm__Credit_Group__c != '0014 - PCC - Pre-pay/Credit Card' &&
                            newAcc.celsrm__Credit_Group__c != '0016 - CAD - Cadex' &&
                            newAcc.celsrm__Credit_Group__c != '0006 - PP - Payment Plan') {
                            if (oldAcc.Calculated_Credit_Limit_Group_Currency__c != newAcc.Calculated_Credit_Limit_Group_Currency__c) {
                                if (oldAcc.Calculated_Credit_Limit_Group_Currency__c <= 50000) {
                                    bvdIdsAdd.add(newAcc.BvD_ID_Number__c);
                                }
                            } else {
                                bvdIdsAdd.add(newAcc.BvD_ID_Number__c);
                            }
                        }
                    }

                    // To manage relationship changes
                    if (oldAcc.ParentId != newAcc.ParentId) {
                        Map<String,String> objMap = new Map<String,String>();
                        objMap.put('accountId',         newAcc.Id);
                        objMap.put('accountNumber',     newAcc.AccountNumber);
                        objMap.put('creditControlArea', newAcc.celsrm__Credit_Control_Area__c);
                        objMap.put('oldParentId',       oldAcc.ParentId);
                        objMap.put('newParentId',       newAcc.ParentId);
                        refUpdates.add(objMap);
                    }
                }

                if (profileAccountIds.size() > 0 && !Test.isRunningTest() && !UpdateProfileDataInSourceSystemService.skipProfileDataSync) {
                    UpdateProfileDataInSourceSystemService.updateProfileDataInSAP(profileAccountIds);
                }
                if (bvdUpdates.size() > 0 && !Test.isRunningTest()) {
                    UpdateBvdIdInSourceSystemService.updateBvdIdInSAP(bvdUpdates);
                }
                if (clAccountIds.size() > 0 && !Test.isRunningTest()) {
                    UpdateBlockInSourceSystemService.updateBlockInSAP(clAccountIds);
                }
                if (refUpdates.size() > 0 && !Test.isRunningTest()) {
                    UpdateReferencesInSourceSystemService.updateReferenceDataInSAP(refUpdates);
                }
                if (!bvdChangedAccounts.isEmpty()) {
                    PropagateBvdIdToSiblingsService.propagateToSiblings(bvdChangedAccounts);
                }
                // Synchronous, in the same transaction as this save (see
                // PropagateProfileDataToAccounts.propagateSync) — assumes small volumes, a manual
                // Account edit has at most a handful of Credit Segments sharing the AccountNumber.
                // A bulk job that changes Credit Group on many accounts at once should go through
                // GetMoodysDataService's async Database.executeBatch(...) path instead.
                if (!cgChangedAccountIds.isEmpty()) {
                    PropagateProfileDataToAccounts.propagateSync(cgChangedAccountIds);
                }
            }
            // ── END NON-SYSADMIN PATH ──────────────────────────────────────────
        }

        Boolean addBVDIDInRecordSet = Credit_Configuration__c.getOrgDefaults().Add_BVDID_In_RecordSet__c;
        if (addBVDIDInRecordSet == true && bvdIdsAdd.size() > 0 && !Test.isRunningTest()) {
            MoodysRecordSetManager.enqueue(bvdIdsAdd);
        }
    }

}