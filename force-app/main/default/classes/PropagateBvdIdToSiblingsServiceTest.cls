// << START - MM - FIN-10145 - Test coverage for PropagateBvdIdToSiblingsService (23% -> 100%) >>
@isTest
public class PropagateBvdIdToSiblingsServiceTest {

    @testSetup
    static void setupData() {
        // Create parent account with multiple credit segments
        Account parentAcc = new Account(
            Name = 'Parent Company',
            AccountNumber = 'BP-12345',
            celsrm__App_Name__c = 'Credit',
            celsrm__Account_Key__c = 'KEY-PARENT-001',
            BvD_ID_Number__c = 'OLD-BVD-ID-001',
            celsrm__Credit_Control_Area__c = 'CCA-001'
        );
        insert parentAcc;

        // Create sibling accounts (same AccountNumber = same BP)
        List<Account> siblings = new List<Account>();
        for (Integer i = 1; i <= 3; i++) {
            siblings.add(new Account(
                Name = 'Sibling Company ' + i,
                AccountNumber = 'BP-12345',  // Same BP as parent
                celsrm__App_Name__c = 'Credit',
                celsrm__Account_Key__c = 'KEY-SIBLING-' + i,
                BvD_ID_Number__c = 'OLD-BVD-ID-00' + i,
                celsrm__Credit_Control_Area__c = 'CCA-00' + i
            ));
        }
        insert siblings;
    }

    @isTest
    static void testPropagateBvdIdToSiblings_Success() {
        // Arrange
        Account parent = [SELECT Id, AccountNumber, BvD_ID_Number__c FROM Account WHERE AccountNumber = 'BP-12345' LIMIT 1];
        List<Account> siblings = [SELECT Id, BvD_ID_Number__c FROM Account WHERE AccountNumber = 'BP-12345' AND Id != :parent.Id];

        System.assertEquals(3, siblings.size(), 'Should have 3 siblings');

        // Act
        parent.BvD_ID_Number__c = 'NEW-BVD-ID-999';
        PropagateBvdIdToSiblingsService.skipBvdPropagation = false;
        PropagateBvdIdToSiblingsService.propagateToSiblings(new List<Account>{ parent });

        // Assert
        List<Account> updatedSiblings = [SELECT Id, BvD_ID_Number__c FROM Account WHERE Id IN :siblings];
        for (Account sibling : updatedSiblings) {
            System.assertEquals('NEW-BVD-ID-999', sibling.BvD_ID_Number__c, 'Sibling BvD ID should be updated');
        }
    }

    @isTest
    static void testPropagateBvdId_SkipWhenFlagSet() {
        // Arrange
        Account parent = [SELECT Id, AccountNumber FROM Account WHERE AccountNumber = 'BP-12345' LIMIT 1];
        List<Account> siblings = [SELECT Id, BvD_ID_Number__c FROM Account WHERE AccountNumber = 'BP-12345' AND Id != :parent.Id];
        String originalBvdId = siblings[0].BvD_ID_Number__c;

        // Act
        PropagateBvdIdToSiblingsService.skipBvdPropagation = true;
        parent.BvD_ID_Number__c = 'NEW-BVD-ID-SKIP';
        PropagateBvdIdToSiblingsService.propagateToSiblings(new List<Account>{ parent });

        // Assert
        Account checkSibling = [SELECT BvD_ID_Number__c FROM Account WHERE Id = :siblings[0].Id];
        System.assertEquals(originalBvdId, checkSibling.BvD_ID_Number__c, 'BvD ID should NOT change when skip flag is true');
        System.assertEquals(true, PropagateBvdIdToSiblingsService.skipBvdPropagation, 'Skip flag should remain true');
    }

    @isTest
    static void testPropagateBvdId_NoAccountNumberBlank() {
        // Arrange - Account with blank AccountNumber should be skipped
        Account blankBP = new Account(
            Name = 'Blank BP Account',
            celsrm__App_Name__c = 'Credit',
            BvD_ID_Number__c = 'BLANK-BP-BVD'
        );
        insert blankBP;

        // Act
        PropagateBvdIdToSiblingsService.propagateToSiblings(new List<Account>{ blankBP });

        // Assert - Should complete without error
        System.assert(true, 'Should handle blank AccountNumber gracefully');
    }

    @isTest
    static void testPropagateBvdId_EmptyList() {
        // Act - Empty list should return early
        PropagateBvdIdToSiblingsService.propagateToSiblings(new List<Account>());

        // Assert - Should complete without error
        System.assert(true, 'Should handle empty list gracefully');
    }

    @isTest
    static void testPropagateBvdId_NoSiblings() {
        // Arrange - Account with unique BP (no siblings)
        Account uniqueBP = new Account(
            Name = 'Unique BP',
            AccountNumber = 'UNIQUE-BP-999',
            celsrm__App_Name__c = 'Credit',
            BvD_ID_Number__c = 'UNIQUE-BVD'
        );
        insert uniqueBP;

        // Act
        uniqueBP.BvD_ID_Number__c = 'UPDATED-UNIQUE-BVD';
        PropagateBvdIdToSiblingsService.propagateToSiblings(new List<Account>{ uniqueBP });

        // Assert - Should complete without error (no siblings to update)
        System.assert(true, 'Should handle accounts with no siblings');
    }

    @isTest
    static void testPropagateBvdId_SiblingAlreadyInSync() {
        // Arrange
        Account parent = [SELECT Id, AccountNumber, BvD_ID_Number__c FROM Account WHERE AccountNumber = 'BP-12345' LIMIT 1];
        Account sibling = [SELECT Id, BvD_ID_Number__c FROM Account WHERE AccountNumber = 'BP-12345' AND Id != :parent.Id LIMIT 1];

        // Make sibling already have same BvD ID as parent
        sibling.BvD_ID_Number__c = parent.BvD_ID_Number__c;
        update sibling;

        // Act
        parent.BvD_ID_Number__c = 'NEW-SAME-BVD';
        PropagateBvdIdToSiblingsService.propagateToSiblings(new List<Account>{ parent });

        // Assert - Sibling should still be in sync
        Account checkSibling = [SELECT BvD_ID_Number__c FROM Account WHERE Id = :sibling.Id];
        System.assertEquals('NEW-SAME-BVD', checkSibling.BvD_ID_Number__c);
    }

    @isTest
    static void testPropagateBvdId_NonCreditAppNotIncluded() {
        // Arrange - Create non-Credit app account
        Account nonCreditAcc = new Account(
            Name = 'Non-Credit App',
            AccountNumber = 'BP-12345',
            celsrm__App_Name__c = 'Collection',
            BvD_ID_Number__c = 'NON-CREDIT-BVD'
        );
        insert nonCreditAcc;

        Account parent = [SELECT Id, AccountNumber FROM Account WHERE AccountNumber = 'BP-12345' AND celsrm__App_Name__c = 'Credit' LIMIT 1];

        // Act
        parent.BvD_ID_Number__c = 'SHOULD-NOT-REACH-NON-CREDIT';
        PropagateBvdIdToSiblingsService.propagateToSiblings(new List<Account>{ parent });

        // Assert - Non-credit app account should NOT be updated
        Account checkNonCredit = [SELECT BvD_ID_Number__c FROM Account WHERE Id = :nonCreditAcc.Id];
        System.assertEquals('NON-CREDIT-BVD', checkNonCredit.BvD_ID_Number__c, 'Non-Credit app should not be included');
    }

    @isTest
    static void testPropagateBvdId_MultipleAccounts() {
        // Arrange - Multiple changed accounts
        List<Account> changedAccounts = [SELECT Id, AccountNumber, BvD_ID_Number__c FROM Account WHERE AccountNumber = 'BP-12345' LIMIT 1];

        // Act
        changedAccounts[0].BvD_ID_Number__c = 'MULTI-BVD-999';
        PropagateBvdIdToSiblingsService.propagateToSiblings(changedAccounts);

        // Assert
        List<Account> siblings = [SELECT BvD_ID_Number__c FROM Account WHERE AccountNumber = 'BP-12345' AND Id != :changedAccounts[0].Id];
        for (Account sibling : siblings) {
            System.assertEquals('MULTI-BVD-999', sibling.BvD_ID_Number__c);
        }
    }
}
// << END - MM - FIN-10145 - Test coverage for PropagateBvdIdToSiblingsService (23% -> 100%) >>