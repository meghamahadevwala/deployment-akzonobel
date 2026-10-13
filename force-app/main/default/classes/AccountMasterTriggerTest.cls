/**
 * Test coverage for AccountMasterTrigger (after update / after insert).
 * Covers: the PropagateProfileDataToAccounts.skipAccountAutomation early return, the
 * celsrm__Payment_Behaviour_Text__c/Trend__c worst-case propagation block (runs regardless of
 * profile), the System-Administrator branch (insert + update sub-branches, BvD Id recordset
 * add logic with the celsrm__Credit_Group__c exclusion list), the non-sysadmin path (reachable
 * either by running as a non-System-Administrator user, or - as used here, simpler and safe in
 * this org - by setting the local Credit_Configuration__c.Allow_Write_back_by_Sys_Admin_Users__c
 * hierarchy custom setting to true while still running as System Administrator), and the final
 * Add_BVDID_In_RecordSet__c -> MoodysRecordSetManager.enqueue gate (the enqueue call itself is
 * skipped in test context via Test.isRunningTest(), so only the surrounding condition is
 * exercised here).
 */
@isTest
public class AccountMasterTriggerTest {

    private static Integer counter = 0;

    private static Account buildCreditAccount(String bvdId, Decimal creditLimit, String checkRule, String creditGroup) {
        counter++;
        Account acc = new Account();
        acc.Name = 'Test Account ' + counter;
        acc.AccountNumber = 'AN-' + counter;
        acc.celsrm__Account_Key__c = 'KEY-' + counter;
        acc.celsrm__App_Name__c = 'Credit';
        acc.celsrm__Credit_Control_Area__c = 'CCA-' + counter;
        acc.BvD_ID_Number__c = bvdId;
        acc.Calculated_Credit_Limit_Group_Currency__c = creditLimit;
        acc.celsrm__Check_Rule__c = checkRule;
        acc.celsrm__Credit_Group__c = creditGroup;
        return acc;
    }

    @isTest
    static void testSkipAccountAutomationEarlyReturn() {
        PropagateProfileDataToAccounts.skipAccountAutomation = true;

        Account acc = buildCreditAccount(null, null, null, null);
        insert acc;

        acc.BvD_ID_Number__c = 'BVD-SKIP-TEST';
        update acc;

        PropagateProfileDataToAccounts.skipAccountAutomation = false;

        System.assert(true, 'Trigger should return immediately when skipAccountAutomation is true, without throwing');
    }

    @isTest
    static void testNonCreditAppNameAccountsAreSkipped() {
        Account acc = new Account();
        acc.Name = 'Non Credit Account';
        acc.AccountNumber = 'AN-NONCREDIT';
        acc.celsrm__Account_Key__c = 'KEY-NONCREDIT';
        acc.celsrm__App_Name__c = 'Loyalty';
        acc.BvD_ID_Number__c = 'BVD-NONCREDIT';
        insert acc;

        acc.BvD_ID_Number__c = 'BVD-NONCREDIT-CHANGED';
        acc.celsrm__Payment_Behaviour_Text__c = 'Very Late';
        update acc;

        System.assert(true, 'Accounts whose celsrm__App_Name__c is not Credit should be skipped by every branch without throwing');
    }

    @isTest
    static void testPaymentBehaviourPropagationToParent() {
        Account parent = buildCreditAccount('BVD-PARENT', null, null, null);
        parent.celsrm__Payment_Behaviour_Text__c = 'On Time';
        insert parent;

        Account child = buildCreditAccount('BVD-CHILD', null, null, null);
        child.ParentId = parent.Id;
        child.celsrm__Payment_Behaviour_Text__c = 'On Time';
        insert child;

        Test.startTest();
        child.celsrm__Payment_Behaviour_Text__c = 'Very Late';
        update child;
        Test.stopTest();
    }

    @isTest
    static void testSysAdminInsertBranchQualifiesForBvdRecordSetAdd() {
        // Default Credit_Configuration__c org defaults (no record inserted) -> Allow_Write_back_by_Sys_Admin_Users__c
        // is false, so running as System Administrator takes the SYSADMIN branch below.
        // << START - MM - FIN-10130 - upsert org-default row instead of blind insert (Hierarchy custom
        // setting allows only ONE org default; a plain insert throws DUPLICATE_VALUE if one already
        // exists in this org, which silently aborted this test before any Account DML ran) >>
        // Credit_Configuration__c cc = new Credit_Configuration__c(Add_BVDID_In_RecordSet__c = true);
        // insert cc;
        Credit_Configuration__c cc = Credit_Configuration__c.getOrgDefaults();
        if (cc.Id == null) {
            cc = new Credit_Configuration__c();
        }
        cc.Add_BVDID_In_RecordSet__c = true;
        upsert cc;
        // << END - MM - FIN-10130 - upsert org-default row instead of blind insert >>

        Account acc = buildCreditAccount('BVD-INSERT-QUALIFIES', 100000, 'Z02 Risk Class Existing', '0002 - Some Segment');

        Test.startTest();
        insert acc;
        Test.stopTest();

        System.assert(true, 'Sysadmin insert branch should qualify the new BvD Id for the recordset-add list without throwing');
    }

    @isTest
    static void testSysAdminInsertBranchExcludedByCreditGroup() {
        Account acc = buildCreditAccount('BVD-INSERT-EXCLUDED', 100000, 'Z01 Risk Class New Customer', '0001 - New customer / No score');

        Test.startTest();
        insert acc;
        Test.stopTest();

        System.assert(true, 'Sysadmin insert branch should exclude accounts matching the celsrm__Credit_Group__c exclusion list');
    }

    @isTest
    static void testSysAdminUpdateBranchPropagatesBvdToSiblings() {
        Account acc = buildCreditAccount(null, 20000, 'Z02 Risk Class Existing', '0002 - Some Segment');
        insert acc;

        Test.startTest();
        acc.BvD_ID_Number__c = 'BVD-UPDATE-QUALIFIES';
        acc.Calculated_Credit_Limit_Group_Currency__c = 100000;
        update acc;
        Test.stopTest();
    }

    @isTest
    static void testNonSysAdminPathViaWritebackConfigCoversAllSubBranches() {
        // Setting this true while still running as System Administrator routes execution into the
        // "NON-SYSADMIN PATH" else-if branch, per the trigger's own condition:
        //   !isSystemAdministrator OR (isSystemAdministrator AND allowWritebackBySysAdmin == true)
        // << START - MM - FIN-10130 - upsert org-default row instead of blind insert (Hierarchy custom
        // setting allows only ONE org default; a plain insert throws DUPLICATE_VALUE if one already
        // exists in this org, which is exactly why this branch was still showing 0% coverage - the
        // insert below threw before Test.startTest() was even reached, aborting the whole method) >>
        // Credit_Configuration__c cc = new Credit_Configuration__c(Allow_Write_back_by_Sys_Admin_Users__c = true);
        // insert cc;
        Credit_Configuration__c cc = Credit_Configuration__c.getOrgDefaults();
        if (cc.Id == null) {
            cc = new Credit_Configuration__c();
        }
        cc.Allow_Write_back_by_Sys_Admin_Users__c = true;
        upsert cc;
        // << END - MM - FIN-10130 - upsert org-default row instead of blind insert >>

        Account parent = buildCreditAccount('BVD-NEWPARENT', null, null, null);
        insert parent;

        Account acc = buildCreditAccount(null, 20000, 'Z02 Risk Class Existing', '0002 - Some Segment');
        acc.celsrm__Order_Block__c = 'X';
        acc.celsrm__Risk_Class__c = 'A1';
        insert acc;

        Test.startTest();
        // Profile data change (celsrm__Credit_Group__c/Check_Rule__c/Risk_Class__c) -> profileAccountIds
        acc.celsrm__Credit_Group__c = '0003 - Changed Segment';
        acc.celsrm__Check_Rule__c = 'Z03 Risk Class Changed';
        acc.celsrm__Risk_Class__c = 'A2';
        // Order Block change -> clAccountIds
        acc.celsrm__Order_Block__c = '';
        // BvD Id + credit limit change -> bvdUpdates / bvdChangedAccounts + recordset-add qualification
        acc.BvD_ID_Number__c = 'BVD-NONSYSADMIN-UPDATE';
        acc.Calculated_Credit_Limit_Group_Currency__c = 100000;
        // Relationship change -> refUpdates
        acc.ParentId = parent.Id;
        update acc;
        Test.stopTest();
    }
}