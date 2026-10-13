@IsTest
private class DeterioratedAccountsControllerTest {

    @isTest
    static void testGetDeterioratedAccounts_ReturnsOnlyDeterioratedOnes() {
        Account deteriorated = new Account(
            Name = 'Deteriorated Co',
            AccountNumber = 'DET001',
            celsrm__Account_Key__c = 'TEST_DAC_DET001',
            Moody_s_Risk_Class__c = 'High',
            Moody_s_Credit_Limit__c = 40000,
            Credit_Score_Comparison_Flag__c = 'Deterioration'
        );
        Account improved = new Account(
            Name = 'Improved Co',
            AccountNumber = 'IMP001',
            celsrm__Account_Key__c = 'TEST_DAC_IMP001',
            Moody_s_Risk_Class__c = 'Low',
            Moody_s_Credit_Limit__c = 90000,
            Credit_Score_Comparison_Flag__c = 'Improvement'
        );
        Account noChange = new Account(
            Name = 'No Change Co',
            AccountNumber = 'NOC001',
            celsrm__Account_Key__c = 'TEST_DAC_NOC001',
            Moody_s_Risk_Class__c = 'Medium',
            Moody_s_Credit_Limit__c = 60000,
            Credit_Score_Comparison_Flag__c = 'No Change'
        );
        insert new List<Account>{ deteriorated, improved, noChange };

        Test.startTest();
        List<DeterioratedAccountsController.DeterioratedAccountWrapper> results =
            DeterioratedAccountsController.getDeterioratedAccounts();
        Test.stopTest();

        System.assertEquals(1, results.size(),
            'Only the account flagged as Deterioration should be returned.');
        System.assertEquals('DET001', results[0].accountNumber);
        System.assertEquals('High', results[0].moodysRiskClass);
        System.assertEquals(40000, results[0].moodysCreditLimit);
    }

    @isTest
    static void testGetDeterioratedAccounts_NoneFlagged_ReturnsEmptyList() {
        Account acc = new Account(
            Name = 'Stable Co',
            AccountNumber = 'STB001',
            celsrm__Account_Key__c = 'TEST_DAC_STB001',
            Moody_s_Risk_Class__c = 'Low',
            Moody_s_Credit_Limit__c = 100000,
            Credit_Score_Comparison_Flag__c = 'No Change'
        );
        insert acc;

        Test.startTest();
        List<DeterioratedAccountsController.DeterioratedAccountWrapper> results =
            DeterioratedAccountsController.getDeterioratedAccounts();
        Test.stopTest();

        System.assertEquals(0, results.size(),
            'No accounts are flagged Deterioration, so the list should be empty.');
    }
}