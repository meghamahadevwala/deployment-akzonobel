@isTest
private class UserFieldValidatorTest {

    private static final String TEST_PROFILE = 'Standard User';

    @TestSetup
    static void setupTestData() {
        List<UserRole> roles = new List<UserRole>();
        
        roles.add(new UserRole(Name = 'CEO'));
        roles.add(new UserRole(Name = 'CFO'));
        roles.add(new UserRole(Name = 'VP Treasurer'));
        roles.add(new UserRole(Name = 'Director - Credit & Collections'));
        roles.add(new UserRole(Name = 'AR Manager (North America)'));
        roles.add(new UserRole(Name = 'Credit & Collections Manager (Central Team)'));
        roles.add(new UserRole(Name = 'Credit Manager (EMEA)'));
        roles.add(new UserRole(Name = 'Credit Manager (North America)'));
        roles.add(new UserRole(Name = 'RDPL (EMEA)'));
        roles.add(new UserRole(Name = 'RDPL (North America)'));
        roles.add(new UserRole(Name = 'Team Lead (EMEA)'));
        roles.add(new UserRole(Name = 'Team Lead (North America)'));
        roles.add(new UserRole(Name = 'Credit & Collection Analyst (EMEA)'));
        roles.add(new UserRole(Name = 'Credit & Collection Analyst (North America)'));
        roles.add(new UserRole(Name = 'Technical Support'));
        
        insert roles;
        
        Profile testProfile = [SELECT Id FROM Profile WHERE Name = :TEST_PROFILE LIMIT 1];
        
        List<User> testUsers = new List<User>();
        Integer counter = 0;
        
        for (UserRole role : roles) {
            counter++;
            String userEmail = 'testuser' + counter + '@akzonobel.test.com';
            testUsers.add(new User(
                FirstName = 'Test',
                LastName = 'User' + counter,
                Email = userEmail,
                Username = 'testuser' + counter + '@akzonobel.test.com' + System.now().getTime(),
                Alias = 'tuser' + counter,
                TimeZoneSidKey = 'America/Los_Angeles',
                LocaleSidKey = 'en_US',
                EmailEncodingKey = 'UTF-8',
                ProfileId = testProfile.Id,
                LanguageLocaleKey = 'en_US',
                UserRoleId = role.Id,
                FederationIdentifier = userEmail
            ));
        }
        
        insert testUsers;
    }
    
    /**
     * - System.runAs(sysAdmin): evita NPE en AccountMasterTrigger AfterInsert
     *   (el bloque non-sysadmin accede a oldMap que es null en insert)
     * - App_Name__c = 'collection': valor válido del picklist restringido que
     *   hace que el trigger ignore estas cuentas (no es 'credit')
     * - Crypto.getRandomInteger(): evita DUPLICATE_VALUE cuando el tiempo en
     *   milisegundos coincide entre ejecuciones rápidas de distintos tests
     */
    private static List<Account> createTestAccounts(Integer numberOfAccounts) {
        User sysAdmin = [
            SELECT Id FROM User 
            WHERE Profile.Name = 'System Administrator' 
            AND IsActive = true 
            LIMIT 1
        ];
        
        List<Account> accounts = new List<Account>();
        String uniqueId = String.valueOf(Math.abs(Crypto.getRandomInteger()));
        
        for (Integer i = 0; i < numberOfAccounts; i++) {
            accounts.add(new Account(
                Name = 'Test Account ' + uniqueId + ' ' + i,
                celsrm__App_Name__c = 'collection'
            ));
        }
        
        System.runAs(sysAdmin) {
            insert accounts;
        }
        
        return accounts;
    }

    private static User getUserByRole(String roleName) {
        return [
            SELECT Id, UserRole.Name, UserRoleId
            FROM User
            WHERE UserRole.Name = :roleName
            LIMIT 1
        ];
    }

    private static Account getTestAccount() {
        List<Account> accounts = createTestAccounts(1);
        return accounts[0];
    }

    // ========================================================================
    // BLOCKED USER TESTS
    // ========================================================================

    @isTest
    static void testBlockedUser_CannotChangeOwnership() {
        User blockedUser = getUserByRole('Credit & Collection Analyst (EMEA)');
        User targetUser = getUserByRole('CEO');
        Account testAccount = getTestAccount();
        
        testAccount.OwnerId = blockedUser.Id;
        update testAccount;
        
        Test.startTest();
        System.runAs(blockedUser) {
            testAccount.OwnerId = targetUser.Id;
            
            try {
                update testAccount;
                System.assert(false, 'Expected DmlException was not thrown');
            } catch (DmlException e) {
                System.assert(
                    e.getMessage().contains('You do not have permission to change OwnerId'),
                    'Expected error message not found. Got: ' + e.getMessage()
                );
                System.assert(
                    e.getMessage().contains('Credit & Collection Analyst'),
                    'Expected role name in error message'
                );
            }
        }
        Test.stopTest();
        
        Account verifyAccount = [SELECT OwnerId FROM Account WHERE Id = :testAccount.Id];
        System.assertEquals(blockedUser.Id, verifyAccount.OwnerId, 'Ownership should not have changed');
    }

    /*
    @isTest
    static void testBlockedUser_CannotInsertWithDifferentOwner() {
        User blockedUser = getUserByRole('Credit & Collection Analyst (North America)');
        User targetUser = getUserByRole('CEO');
        
        Test.startTest();
        System.runAs(blockedUser) {
            Account newAccount = new Account(
                Name = 'New Test Account',
                OwnerId = targetUser.Id
            );
            
            try {
                insert newAccount;
                System.assert(false, 'Expected DmlException was not thrown');
            } catch (DmlException e) {
                System.assert(
                    e.getMessage().contains('You do not have permission to change OwnerId'),
                    'Expected error message not found'
                );
            }
        }
        Test.stopTest();
    }
    */

    // ========================================================================
    // REGIONAL RESTRICTION TESTS
    // ========================================================================

    @isTest
    static void testRegionalUser_CanAssignWithinRegion() {
        User regionalUser = getUserByRole('RDPL (EMEA)');
        User targetUser = getUserByRole('Team Lead (EMEA)');
        Account testAccount = getTestAccount();
        
        testAccount.OwnerId = regionalUser.Id;
        update testAccount;
        
        Test.startTest();
        System.runAs(regionalUser) {
            testAccount.OwnerId = targetUser.Id;
            update testAccount;
        }
        Test.stopTest();
        
        Account verifyAccount = [SELECT OwnerId FROM Account WHERE Id = :testAccount.Id];
        System.assertEquals(targetUser.Id, verifyAccount.OwnerId, 'Ownership should have changed');
    }

    @isTest
    static void testRegionalUser_CannotAssignToDifferentRegion() {
        User regionalUser = getUserByRole('RDPL (EMEA)');
        User targetUser = getUserByRole('Team Lead (North America)');
        Account testAccount = getTestAccount();
        
        testAccount.OwnerId = regionalUser.Id;
        update testAccount;
        
        Test.startTest();
        System.runAs(regionalUser) {
            testAccount.OwnerId = targetUser.Id;
            
            try {
                update testAccount;
                System.assert(false, 'Expected DmlException was not thrown');
            } catch (DmlException e) {
                System.assert(
                    e.getMessage().contains('You cannot assign this record to users from the North America region'),
                    'Expected error message not found. Got: ' + e.getMessage()
                );
                System.assert(
                    e.getMessage().contains('You can only assign records to members of your region (EMEA)'),
                    'Expected region restriction message not found'
                );
            }
        }
        Test.stopTest();
        
        Account verifyAccount = [SELECT OwnerId FROM Account WHERE Id = :testAccount.Id];
        System.assertEquals(regionalUser.Id, verifyAccount.OwnerId, 'Ownership should not have changed');
    }

    @isTest
    static void testRegionalUser_CannotAssignToHigherHierarchy() {
        User regionalUser = getUserByRole('Team Lead (EMEA)');
        User targetUser = getUserByRole('Credit Manager (EMEA)');
        Account testAccount = getTestAccount();
        
        testAccount.OwnerId = regionalUser.Id;
        update testAccount;
        
        Test.startTest();
        System.runAs(regionalUser) {
            testAccount.OwnerId = targetUser.Id;
            
            try {
                update testAccount;
                System.assert(false, 'Expected DmlException was not thrown');
            } catch (DmlException e) {
                System.assert(
                    e.getMessage().contains('You cannot assign records to users with higher authority'),
                    'Expected hierarchy error message not found. Got: ' + e.getMessage()
                );
                System.assert(
                    e.getMessage().contains('Credit Manager'),
                    'Expected target role in error message'
                );
            }
        }
        Test.stopTest();
    }

    @isTest
    static void testRegionalUser_CanAssignToLowerHierarchy() {
        User creditManager = getUserByRole('Credit Manager (EMEA)');
        User teamLead = getUserByRole('Team Lead (EMEA)');
        Account testAccount = getTestAccount();
        
        testAccount.OwnerId = creditManager.Id;
        update testAccount;
        
        Test.startTest();
        System.runAs(creditManager) {
            testAccount.OwnerId = teamLead.Id;
            update testAccount;
        }
        Test.stopTest();
        
        Account verifyAccount = [SELECT OwnerId FROM Account WHERE Id = :testAccount.Id];
        System.assertEquals(teamLead.Id, verifyAccount.OwnerId, 'Ownership should have changed');
    }

    // ========================================================================
    // UNRESTRICTED USER TESTS
    // ========================================================================

    /**
     * FIX: Después de transferir ownership dentro de runAs, el usuario pierde
     * acceso al record (ya no es owner). Se resetea ownership entre cada paso.
     */
    @isTest
    static void testUnrestrictedUser_CanAssignAcrossRegions() {
        User ceoUser = getUserByRole('CEO');
        User targetUserEMEA = getUserByRole('Team Lead (EMEA)');
        User targetUserNA = getUserByRole('Team Lead (North America)');
        Account testAccount = getTestAccount();
        
        testAccount.OwnerId = ceoUser.Id;
        update testAccount;
        
        Test.startTest();
        // Primer paso: CEO asigna a EMEA
        System.runAs(ceoUser) {
            testAccount.OwnerId = targetUserEMEA.Id;
            update testAccount;
        }
        
        // Verificar primer paso
        Account verifyEMEA = [SELECT OwnerId FROM Account WHERE Id = :testAccount.Id];
        System.assertEquals(targetUserEMEA.Id, verifyEMEA.OwnerId, 'Should have assigned to EMEA');
        
        // Resetear ownership a CEO para el segundo paso
        testAccount.OwnerId = ceoUser.Id;
        update testAccount;
        
        // Segundo paso: CEO asigna a North America
        System.runAs(ceoUser) {
            testAccount.OwnerId = targetUserNA.Id;
            update testAccount;
        }
        Test.stopTest();
        
        Account verifyNA = [SELECT OwnerId FROM Account WHERE Id = :testAccount.Id];
        System.assertEquals(targetUserNA.Id, verifyNA.OwnerId, 'Should have assigned to North America');
    }

    @isTest
    static void testUnrestrictedUser_StillRespectsHierarchy() {
        User arManager = getUserByRole('AR Manager (North America)');
        User director = getUserByRole('Director - Credit & Collections');
        Account testAccount = getTestAccount();
        
        testAccount.OwnerId = arManager.Id;
        update testAccount;
        
        Test.startTest();
        System.runAs(arManager) {
            testAccount.OwnerId = director.Id;
            
            try {
                update testAccount;
                System.assert(false, 'Expected DmlException was not thrown');
            } catch (DmlException e) {
                System.assert(
                    e.getMessage().contains('You cannot assign records to users with higher authority'),
                    'Expected hierarchy error message not found. Got: ' + e.getMessage()
                );
            }
        }
        Test.stopTest();
    }

    /**
     * FIX: Resetear ownership a CEO entre asignaciones para evitar
     * INSUFFICIENT_ACCESS_ON_CROSS_REFERENCE_ENTITY.
     */
    @isTest
    static void testCEO_CanAssignToAnyRole() {
        User ceoUser = getUserByRole('CEO');
        User director = getUserByRole('Director - Credit & Collections');
        User arManager = getUserByRole('AR Manager (North America)');
        Account testAccount = getTestAccount();
        
        testAccount.OwnerId = ceoUser.Id;
        update testAccount;
        
        Test.startTest();
        // Primer paso: CEO asigna a Director
        System.runAs(ceoUser) {
            testAccount.OwnerId = director.Id;
            update testAccount;
        }
        
        Account verifyDirector = [SELECT OwnerId FROM Account WHERE Id = :testAccount.Id];
        System.assertEquals(director.Id, verifyDirector.OwnerId, 'CEO should assign to Director');
        
        // Resetear ownership a CEO para el segundo paso
        testAccount.OwnerId = ceoUser.Id;
        update testAccount;
        
        // Segundo paso: CEO asigna a AR Manager
        System.runAs(ceoUser) {
            testAccount.OwnerId = arManager.Id;
            update testAccount;
        }
        Test.stopTest();
        
        Account verifyARManager = [SELECT OwnerId FROM Account WHERE Id = :testAccount.Id];
        System.assertEquals(arManager.Id, verifyARManager.OwnerId, 'CEO should assign to AR Manager');
    }

    /**
     * FIX: Resetear ownership a Technical Support entre asignaciones.
     */
    @isTest
    static void testTechnicalSupport_HasUnrestrictedAccess() {
        User techSupport = getUserByRole('Technical Support');
        User targetUserEMEA = getUserByRole('RDPL (EMEA)');
        User targetUserNA = getUserByRole('RDPL (North America)');
        Account testAccount = getTestAccount();
        
        testAccount.OwnerId = techSupport.Id;
        update testAccount;
        
        Test.startTest();
        // Primer paso
        System.runAs(techSupport) {
            testAccount.OwnerId = targetUserEMEA.Id;
            update testAccount;
        }
        
        Account verifyEMEA = [SELECT OwnerId FROM Account WHERE Id = :testAccount.Id];
        System.assertEquals(targetUserEMEA.Id, verifyEMEA.OwnerId, 'Technical Support should assign to EMEA');
        
        // Resetear ownership
        testAccount.OwnerId = techSupport.Id;
        update testAccount;
        
        // Segundo paso
        System.runAs(techSupport) {
            testAccount.OwnerId = targetUserNA.Id;
            update testAccount;
        }
        Test.stopTest();
        
        Account verifyNA = [SELECT OwnerId FROM Account WHERE Id = :testAccount.Id];
        System.assertEquals(targetUserNA.Id, verifyNA.OwnerId, 'Technical Support should assign to North America');
    }

    // ========================================================================
    // EDGE CASES AND SPECIAL SCENARIOS
    // ========================================================================

    @isTest
    static void testUserWithoutRole_IsRestricted() {
        Profile testProfile = [SELECT Id FROM Profile WHERE Name = :TEST_PROFILE LIMIT 1];
        String noRoleEmail = 'norole@akzonobel.test.com';
        User noRoleUser = new User(
            FirstName = 'No',
            LastName = 'Role',
            Email = noRoleEmail,
            Username = 'norole@akzonobel.test.com' + System.now().getTime(),
            Alias = 'norole',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = testProfile.Id,
            LanguageLocaleKey = 'en_US',
            FederationIdentifier = noRoleEmail
        );
        insert noRoleUser;
        
        User targetUser = getUserByRole('CEO');
        Account testAccount = getTestAccount();
        
        Test.startTest();
        System.runAs(noRoleUser) {
            testAccount.OwnerId = targetUser.Id;
            
            try {
                update testAccount;
                System.assert(false, 'Expected DmlException was not thrown');
            } catch (DmlException e) {
                System.assert(
                    e.getMessage().contains('You do not have permission to change OwnerId'),
                    'Expected error for user without role'
                );
            }
        }
        Test.stopTest();
    }

    @isTest
    static void testBulkUpdate_MixedScenarios() {
        User regionalUser = getUserByRole('RDPL (EMEA)');
        User targetValid = getUserByRole('Team Lead (EMEA)');
        User targetInvalid = getUserByRole('Team Lead (North America)');
        
        List<Account> accounts = createTestAccounts(5);
        
        for (Account acc : accounts) {
            acc.OwnerId = regionalUser.Id;
        }
        update accounts;
        
        Test.startTest();
        System.runAs(regionalUser) {
            accounts[0].OwnerId = targetValid.Id;
            accounts[1].OwnerId = targetValid.Id;
            accounts[2].OwnerId = targetInvalid.Id;
            accounts[3].OwnerId = targetInvalid.Id;
            
            try {
                update accounts;
                System.assert(false, 'Expected DmlException was not thrown');
            } catch (DmlException e) {
                System.assert(e.getMessage().contains('North America'), 'Expected region error');
                System.assertEquals(2, e.getNumDml(), 'Should have 2 failed records');
            }
        }
        Test.stopTest();
    }

    /**
     * FIX: Validation rule en el org bloquea cambios en Name.
     * Se usa Description en su lugar para probar que otros campos se pueden editar.
     */
    @isTest
    static void testNoOwnershipChange_NoValidation() {
        User blockedUser = getUserByRole('Credit & Collection Analyst (EMEA)');
        Account testAccount = getTestAccount();
        
        testAccount.OwnerId = blockedUser.Id;
        update testAccount;
        
        Test.startTest();
        System.runAs(blockedUser) {
            testAccount.Description = 'Updated Description';
            testAccount.Phone = '555-1234';
            update testAccount;
        }
        Test.stopTest();
        
        Account verifyAccount = [SELECT Description, Phone FROM Account WHERE Id = :testAccount.Id];
        System.assertEquals('Updated Description', verifyAccount.Description, 'Description should have been updated');
        System.assertEquals('555-1234', verifyAccount.Phone, 'Phone should have been updated');
    }

    /*
    @isTest
    static void testInsert_WithValidations() {
        User regionalUser = getUserByRole('RDPL (EMEA)');
        User targetValid = getUserByRole('Team Lead (EMEA)');
        User targetInvalid = getUserByRole('Team Lead (North America)');
        
        Test.startTest();
        System.runAs(regionalUser) {
            Account validAccount = new Account(
                Name = 'Valid Insert',
                OwnerId = targetValid.Id
            );
            insert validAccount;
            
            Account invalidAccount = new Account(
                Name = 'Invalid Insert',
                OwnerId = targetInvalid.Id
            );
            
            try {
                insert invalidAccount;
                System.assert(false, 'Expected DmlException was not thrown');
            } catch (DmlException e) {
                System.assert(
                    e.getMessage().contains('You cannot assign this record to users from the North America region'),
                    'Expected region error on insert'
                );
            }
        }
        Test.stopTest();
    }
    */

    @isTest
    static void testRegionExtraction_VariousFormats() {
        User userWithParentheses = getUserByRole('RDPL (EMEA)');
        User anotherRegionalUser = getUserByRole('Team Lead (North America)');
        
        Account testAccount = getTestAccount();
        testAccount.OwnerId = userWithParentheses.Id;
        update testAccount;
        
        Test.startTest();
        System.runAs(userWithParentheses) {
            testAccount.OwnerId = anotherRegionalUser.Id;
            
            try {
                update testAccount;
                System.assert(false, 'Expected DmlException was not thrown');
            } catch (DmlException e) {
                System.assert(
                    e.getMessage().contains('North America'),
                    'Region should be extracted from parentheses'
                );
                System.assert(
                    e.getMessage().contains('EMEA'),
                    'Current user region should be extracted'
                );
            }
        }
        Test.stopTest();
    }

    @isTest
    static void testGenericValidation_WorksWithAnyField() {
        User regionalUser = getUserByRole('Credit Manager (EMEA)');
        User targetUser = getUserByRole('RDPL (EMEA)');
        Account testAccount = getTestAccount();
        
        testAccount.OwnerId = regionalUser.Id;
        update testAccount;
        
        Test.startTest();
        System.runAs(regionalUser) {
            testAccount.OwnerId = targetUser.Id;
            
            Map<Id, Account> oldMap = new Map<Id, Account>([
                SELECT Id, OwnerId 
                FROM Account 
                WHERE Id = :testAccount.Id
            ]);
            
            List<Account> newList = new List<Account>{testAccount};
            
            UserFieldValidator.validateUserField(newList, oldMap, 'OwnerId');
            
            update testAccount;
        }
        Test.stopTest();
        
        Account verifyAccount = [SELECT OwnerId FROM Account WHERE Id = :testAccount.Id];
        System.assertEquals(targetUser.Id, verifyAccount.OwnerId, 'Generic validation should work');
    }

    @isTest
    static void testRoleHierarchyLevels() {
        User ceoUser = getUserByRole('CEO');
        User cfoUser = getUserByRole('CFO');
        User directorUser = getUserByRole('Director - Credit & Collections');
        
        Account testAccount = getTestAccount();
        
        Test.startTest();
        
        testAccount.OwnerId = ceoUser.Id;
        update testAccount;
        
        System.runAs(ceoUser) {
            testAccount.OwnerId = directorUser.Id;
            update testAccount;
        }
        
        testAccount.OwnerId = cfoUser.Id;
        update testAccount;
        
        System.runAs(cfoUser) {
            testAccount.OwnerId = directorUser.Id;
            update testAccount;
        }
        
        Test.stopTest();
    }

    /**
     * FIX: Resetear ownership a Central Team Manager entre asignaciones.
     */
    @isTest
    static void testCentralTeamManager_UnrestrictedAccess() {
        User centralManager = getUserByRole('Credit & Collections Manager (Central Team)');
        User targetEMEA = getUserByRole('Team Lead (EMEA)');
        User targetNA = getUserByRole('Team Lead (North America)');
        Account testAccount = getTestAccount();
        
        testAccount.OwnerId = centralManager.Id;
        update testAccount;
        
        Test.startTest();
        // Primer paso
        System.runAs(centralManager) {
            testAccount.OwnerId = targetEMEA.Id;
            update testAccount;
        }
        
        Account verifyEMEA = [SELECT OwnerId FROM Account WHERE Id = :testAccount.Id];
        System.assertEquals(targetEMEA.Id, verifyEMEA.OwnerId, 'Central Team should assign to EMEA');
        
        // Resetear ownership
        testAccount.OwnerId = centralManager.Id;
        update testAccount;
        
        // Segundo paso
        System.runAs(centralManager) {
            testAccount.OwnerId = targetNA.Id;
            update testAccount;
        }
        Test.stopTest();
        
        Account verifyNA = [SELECT OwnerId FROM Account WHERE Id = :testAccount.Id];
        System.assertEquals(targetNA.Id, verifyNA.OwnerId, 'Central Team should assign to North America');
    }
}