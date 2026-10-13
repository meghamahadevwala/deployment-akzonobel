@isTest
public class PropagateProfileDataToAccountsTest {
    private static final String SOURCE_CREDIT_GROUP = '0003 - RCA - Regular Credit Account';
    private static final String SOURCE_CHECK_RULE = 'Z03 Risk Class Low';
    private static final String SOURCE_RISK_CLASS = '3 - Low Risk';

    @testSetup
    static void setupData() {
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < 2; i++) {
            accounts.add(new Account(
                Name = 'Test Account ' + i,
                AccountNumber = 'ACC' + i,
                celsrm__Account_Key__c = 'KEY' + i,
                celsrm__Credit_Group__c = SOURCE_CREDIT_GROUP,
                celsrm__Check_Rule__c = SOURCE_CHECK_RULE,
                celsrm__Risk_Class__c = SOURCE_RISK_CLASS,
                celsrm__App_Name__c = 'Credit'
            ));
        }
        insert accounts;
    }

    @isTest
    static void testPropagatesOnlyCreditGroup() {
        Account source = [SELECT Id, AccountNumber FROM Account WHERE AccountNumber = 'ACC0' LIMIT 1];

        // Target account with same AccountNumber
        Account target = new Account(
            celsrm__Account_Key__c = 'KEYTarget Account',
            Name = 'Target Account',
            AccountNumber = source.AccountNumber,
            celsrm__App_Name__c = 'Credit'
        );
        insert target;

        // Target with different AccountNumber (should not be touched)
        Account targetNoMatch = new Account(
            celsrm__Account_Key__c = 'KEYNo Match Target',
            Name = 'No Match Target',
            AccountNumber = 'NOMATCH',
            celsrm__App_Name__c = 'Credit'
        );
        insert targetNoMatch;

        Account noMatchBefore = [
            SELECT celsrm__Credit_Group__c
            FROM Account WHERE Id = :targetNoMatch.Id
        ];

        Test.startTest();
        Database.executeBatch(new PropagateProfileDataToAccounts(new List<Id>{ source.Id }), 200);
        Test.stopTest();

        Account targetAfter = [
            SELECT celsrm__Credit_Group__c, celsrm__Check_Rule__c, celsrm__Risk_Class__c
            FROM Account WHERE Id = :target.Id
        ];
        Account noMatchAfter = [
            SELECT celsrm__Credit_Group__c
            FROM Account WHERE Id = :targetNoMatch.Id
        ];

        System.assertEquals(SOURCE_CREDIT_GROUP, targetAfter.celsrm__Credit_Group__c,
            'Credit Group should be propagated');
        // Org automation may derive these fields when Credit Group changes,
        // so only verify the batch did not copy the source values.
        System.assertNotEquals(SOURCE_CHECK_RULE, targetAfter.celsrm__Check_Rule__c,
            'Check Rule should not be copied from source');
        System.assertNotEquals(SOURCE_RISK_CLASS, targetAfter.celsrm__Risk_Class__c,
            'Risk Class should not be copied from source');
        System.assertEquals(noMatchBefore.celsrm__Credit_Group__c, noMatchAfter.celsrm__Credit_Group__c,
            'Non-matching account should not be updated');
        System.assertEquals(false, PropagateProfileDataToAccounts.skipAccountAutomation,
            'Flag should be reset after execution');
    }

    @isTest
    static void testNoUpdateWhenCreditGroupAlreadyMatches() {
        // Both setup accounts share the same Credit Group; use ACC1 as source with a matching target
        Account source = [SELECT Id, AccountNumber FROM Account WHERE AccountNumber = 'ACC1' LIMIT 1];

        Account target = new Account(
            celsrm__Account_Key__c = 'KEYSame Group Target',
            Name = 'Same Group Target',
            AccountNumber = source.AccountNumber,
            celsrm__Credit_Group__c = SOURCE_CREDIT_GROUP,
            celsrm__App_Name__c = 'Credit'
        );
        insert target;

        Test.startTest();
        Database.executeBatch(new PropagateProfileDataToAccounts(new List<Id>{ source.Id }), 200);
        Test.stopTest();

        Account targetAfter = [SELECT celsrm__Credit_Group__c FROM Account WHERE Id = :target.Id];
        System.assertEquals(SOURCE_CREDIT_GROUP, targetAfter.celsrm__Credit_Group__c);
        System.assertEquals(false, PropagateProfileDataToAccounts.skipAccountAutomation,
            'Flag should be reset even on early return');
    }
}