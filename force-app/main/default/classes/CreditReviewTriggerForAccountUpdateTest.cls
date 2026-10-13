@isTest
public class CreditReviewTriggerForAccountUpdateTest {

    private static void enableTriggerConfig() {
        celsrm__Trigger_Configuration__c conf = new celsrm__Trigger_Configuration__c();
        conf.Insert_Credit_Review_Account_Update__c = true;
        insert conf;
    }

    @isTest
    static void testInsertWithApprovedStatusUpdatesAccount() {
        enableTriggerConfig();
        Account acc = CreditDataGenerator.insertAccount();

        celsrm__Credit_Review__c cr = new celsrm__Credit_Review__c();
        cr.celsrm__Account__c = acc.Id;
        cr.celsrm__Status__c = '40';
        cr.celsrm__Approved_Credit_Limit__c = 60000;
        cr.Approved_Valid_To_Date__c = Date.today().addDays(365);

        Test.startTest();
        insert cr;
        Test.stopTest();

        Account updated = [SELECT celsrm__Latest_Credit_Review__c, celsrm__Credit_Limit__c, celsrm__Limit_Valid_To_Date__c FROM Account WHERE Id = :acc.Id];
        System.assertEquals(cr.Id, updated.celsrm__Latest_Credit_Review__c, 'Latest credit review should be linked on insert');
        System.assertEquals(60000, updated.celsrm__Credit_Limit__c, 'Approved credit limit should propagate to the account');
        System.assertEquals(cr.Approved_Valid_To_Date__c, updated.celsrm__Limit_Valid_To_Date__c);
    }

    @isTest
    static void testInsertWithPendingStatusDoesNotUpdateLimit() {
        enableTriggerConfig();
        Account acc = CreditDataGenerator.insertAccount();

        celsrm__Credit_Review__c cr = new celsrm__Credit_Review__c();
        cr.celsrm__Account__c = acc.Id;
        cr.celsrm__Status__c = '10';

        Test.startTest();
        insert cr;
        Test.stopTest();

        Account updated = [SELECT celsrm__Latest_Credit_Review__c, celsrm__Credit_Limit__c FROM Account WHERE Id = :acc.Id];
        System.assertEquals(cr.Id, updated.celsrm__Latest_Credit_Review__c, 'Latest credit review should still be linked on insert');
        System.assertEquals(null, updated.celsrm__Credit_Limit__c, 'Pending status should not set the account credit limit');
    }

    @isTest
    static void testUpdateToApprovedStatusUpdatesAccount() {
        enableTriggerConfig();
        Account acc = CreditDataGenerator.insertAccount();

        celsrm__Credit_Review__c cr = new celsrm__Credit_Review__c();
        cr.celsrm__Account__c = acc.Id;
        cr.celsrm__Status__c = '10';
        insert cr;

        cr.celsrm__Status__c = '40';
        cr.celsrm__Approved_Credit_Limit__c = 80000;
        cr.Approved_Valid_To_Date__c = Date.today().addDays(180);

        Test.startTest();
        update cr;
        Test.stopTest();

        Account updated = [SELECT celsrm__Credit_Limit__c, celsrm__Limit_Valid_To_Date__c FROM Account WHERE Id = :acc.Id];
        System.assertEquals(80000, updated.celsrm__Credit_Limit__c, 'Status change to approved should propagate the new credit limit');
        System.assertEquals(cr.Approved_Valid_To_Date__c, updated.celsrm__Limit_Valid_To_Date__c);
    }

    @isTest
    static void testUpdateWithoutStatusChangeDoesNotUpdateAccount() {
        enableTriggerConfig();
        Account acc = CreditDataGenerator.insertAccount();

        celsrm__Credit_Review__c cr = new celsrm__Credit_Review__c();
        cr.celsrm__Account__c = acc.Id;
        cr.celsrm__Status__c = '40';
        cr.celsrm__Approved_Credit_Limit__c = 60000;
        cr.Approved_Valid_To_Date__c = Date.today().addDays(365);
        insert cr;

        // Change an unrelated field only - status stays the same.
        cr.App_App_Notes__c = 'no status change';

        Test.startTest();
        update cr;
        Test.stopTest();

        Account updated = [SELECT celsrm__Credit_Limit__c FROM Account WHERE Id = :acc.Id];
        System.assertEquals(60000, updated.celsrm__Credit_Limit__c, 'Credit limit set on insert should remain unchanged');
    }

    @isTest
    static void testTriggerConfigurationDisabledSkipsLogic() {
        // No celsrm__Trigger_Configuration__c record inserted - org default checkbox defaults to false.
        Account acc = CreditDataGenerator.insertAccount();

        celsrm__Credit_Review__c cr = new celsrm__Credit_Review__c();
        cr.celsrm__Account__c = acc.Id;
        cr.celsrm__Status__c = '40';
        cr.celsrm__Approved_Credit_Limit__c = 60000;
        cr.Approved_Valid_To_Date__c = Date.today().addDays(365);

        Test.startTest();
        insert cr;
        Test.stopTest();

        Account updated = [SELECT celsrm__Latest_Credit_Review__c, celsrm__Credit_Limit__c FROM Account WHERE Id = :acc.Id];
        System.assertEquals(null, updated.celsrm__Latest_Credit_Review__c, 'Trigger logic should be skipped when the setting is disabled');
        System.assertEquals(null, updated.celsrm__Credit_Limit__c);
    }
}