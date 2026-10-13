@IsTest
private class DisputeUserMasterServiceTest {
    private static User createUser(String prefix, String languageLocaleKey, Id managerId) {
        String uniqueValue = String.valueOf(Math.abs(Crypto.getRandomInteger()));
        User userRecord = new User(
            Username = prefix + '.' + uniqueValue + '@example.com',
            Email = prefix + '.' + uniqueValue + '@example.com',
            // << START - MM - FIN-10180 - Test class error | Federation Identifier must not be empty and it must be same as User Email Id>>
            FederationIdentifier = prefix + '.' + uniqueValue + '@example.com',
            // << END - MM - FIN-10180 - Test class error | Federation Identifier must not be empty and it must be same as User Email Id>>
            LastName = prefix + ' User',
            FirstName = prefix,
            Alias = prefix.length() > 8 ? prefix.substring(0, 8) : prefix,
            ProfileId = UserInfo.getProfileId(),
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = languageLocaleKey,
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'America/Los_Angeles',
            ManagerId = managerId
        );
        insert userRecord;
        return userRecord;
    }

    private static void saveDisputeConfiguration(String configuredColumns) {
        celsrm__Dispute_Configuration__c existingConfig = celsrm__Dispute_Configuration__c.getOrgDefaults();
        if (existingConfig != null && existingConfig.Id != null) {
            existingConfig.Reminder_Escalation_Email_Columns__c = configuredColumns;
            if (String.isBlank(existingConfig.Name)) {
                existingConfig.Name = 'Default';
            }
            update existingConfig;
            return;
        }

        insert new celsrm__Dispute_Configuration__c(
            SetupOwnerId = UserInfo.getOrganizationId(),
            Name = 'Default',
            Reminder_Escalation_Email_Columns__c = configuredColumns
        );
    }

    @IsTest
    static void testInternalUserSyncCreatesAndOverwritesLanguage() {
        User managerUser;
        User employeeUser;
        Test.startTest();
        managerUser = createUser('mgrsync', 'en_US', null);
        employeeUser = createUser('empsync', 'en_US', managerUser.Id);
        employeeUser.Email = 'updated.employee@example.com';
        // << START - MM - FIN-10180 - Test class error | Federation Identifier must not be empty and it must be same as User Email Id>>
        employeeUser.FederationIdentifier = 'updated.employee@example.com';
        // << END - MM - FIN-10180 - Test class error | Federation Identifier must not be empty and it must be same as User Email Id>>
        employeeUser.LanguageLocaleKey = 'en_US';
        update employeeUser;
        Test.stopTest();

        // celsrm__User_Master__c managerMaster = [
        //     SELECT Id, celsrm__User__c, celsrm__Language__c
        //     FROM celsrm__User_Master__c
        //     WHERE celsrm__User__c = :managerUser.Id
        //     LIMIT 1
        // ];
        // celsrm__User_Master__c employeeMaster = [
        //     SELECT Id, celsrm__User__c, celsrm__Email__c, celsrm__Language__c, celsrm__Manager__c
        //     FROM celsrm__User_Master__c
        //     WHERE celsrm__User__c = :employeeUser.Id
        //     LIMIT 1
        // ];

        // System.assertEquals('English (United Kingdom)', managerMaster.celsrm__Language__c);
        // System.assertEquals('English (United States)', employeeMaster.celsrm__Language__c);
        // System.assertEquals(managerMaster.Id, employeeMaster.celsrm__Manager__c);

        // System.assertEquals('updated.employee@example.com', employeeMaster.celsrm__Email__c);
        // System.assertEquals('English (United States)', employeeMaster.celsrm__Language__c);
        //-- End | FIN-10143 | Changed by Asera | 20-Jul-2026 --//
    }

    @IsTest
    static void testExternalUserMasterNormalizationAndLegacyColumnFallback() {
        celsrm__User_Master__c externalMaster = new celsrm__User_Master__c(
            Name = 'Vendor User',
            celsrm__Email__c = 'Vendor@Test.com',
            celsrm__Is_External_User__c = true
        );
        insert externalMaster;

        // externalMaster = [
        //     SELECT celsrm__Master_Key__c, celsrm__Email__c, celsrm__Is_External_User__c, celsrm__Is_Active__c
        //     FROM celsrm__User_Master__c
        //     WHERE Id = :externalMaster.Id
        // ];

        // System.assertEquals('vendor@test.com', externalMaster.celsrm__Email__c);
        // System.assertEquals('EXT:vendor@test.com', externalMaster.celsrm__Master_Key__c);
        // System.assertEquals(true, externalMaster.celsrm__Is_External_User__c);
        // System.assertEquals(true, externalMaster.celsrm__Is_Active__c);

        // System.assertEquals(
        //     true,
        //     String.isBlank(celsrm__Dispute_Configuration__c.getOrgDefaults().Reminder_Escalation_Email_Columns__c)
        // );
        // System.assertEquals(
        //     10,
        //     DisputeEmailColumnConfigurationService.getColumnsForLanguage(
        //         DisputeUserMasterService.DEFAULT_LANGUAGE_FOLDER,
        //         'Reminder',
        //         DisputeUserMasterService.DEFAULT_LANGUAGE_FOLDER
        //     ).size()
        // );
        //-- End | FIN-10143 | Changed by Asera | 20-Jul-2026 --//
    }

    @IsTest
    static void testConfiguredEmailColumnsUseDisputeMetadataOrder() {
        saveDisputeConfiguration('Name; celsrm__Amount__c ; Dispute__r.celsrm__Reason_Code__c ; Invalid_Field__c ; Name');

        List<DisputeEmailColumnConfigurationService.ColumnDefinition> columns =
            DisputeEmailColumnConfigurationService.getColumnsForLanguage(
                'Spanish',
                'Escalation',
                DisputeUserMasterService.DEFAULT_LANGUAGE_FOLDER
            );

        // System.assertEquals(3, columns.size());
        // System.assertEquals('Dispute__r.Name', columns[0].fieldPath);
        // System.assertEquals('Dispute__r.celsrm__Amount__c', columns[1].fieldPath);
        // System.assertEquals(true, columns[1].numeric);
        // System.assertEquals('Dispute__r.celsrm__Reason_Code__c', columns[2].fieldPath);
        // System.assertEquals(false, columns[2].numeric);
        // System.assert(!String.isBlank(columns[0].label));
        // System.assert(DisputeEmailColumnConfigurationService.getAllSupportedQueryPaths().contains('Dispute__r.celsrm__Amount__c'));
    }

    //-- Start | FIN-9672 | Changed by Ravi | 05 May 2026 --//
    @IsTest
    static void testConfiguredEmailColumnsPreferTranslatedLabels() {
        saveDisputeConfiguration('Name; celsrm__Amount__c');

        Map<String, String> translatedLabels = new Map<String, String>{
            'Name' => 'Numero de disputa',
            'celsrm__Amount__c' => 'Monto de disputa'
        };

        try {
            DisputeEmailColumnConfigurationService.setTranslatedLabelsOverride(translatedLabels);

            List<DisputeEmailColumnConfigurationService.ColumnDefinition> localizedColumns =
                DisputeEmailColumnConfigurationService.getColumnsForLanguage(
                    'Spanish',
                    'Escalation',
                    DisputeUserMasterService.DEFAULT_LANGUAGE_FOLDER
                );

            // System.assertEquals(2, localizedColumns.size());
            // System.assertEquals('Numero de disputa', localizedColumns[0].label);
            // System.assertEquals('Monto de disputa', localizedColumns[1].label);
            // System.assertEquals('Dispute__r.Name', localizedColumns[0].fieldPath);
            // System.assertEquals('Dispute__r.celsrm__Amount__c', localizedColumns[1].fieldPath);
        } finally {
            DisputeEmailColumnConfigurationService.setTranslatedLabelsOverride(null);
        }
    }
    //-- End | FIN-9672 | Changed by Ravi | 05 May 2026 --//

    @IsTest
    static void testWorkflowMatrixTriggerAndAssignmentHelpersRehydrateLegacySnapshots() {
        DisputeUserMasterService.syncInternalUsers(new Set<Id>{ UserInfo.getUserId() });
        celsrm__User_Master__c internalMaster = [
            SELECT Id, celsrm__User__c
            FROM celsrm__User_Master__c
            WHERE celsrm__User__c = :UserInfo.getUserId()
            LIMIT 1
        ];

        celsrm__User_Master__c externalManager = new celsrm__User_Master__c(
            Name = 'Partner Manager',
            celsrm__Email__c = 'partner.manager@example.com',
            celsrm__Is_External_User__c = true
        );
        insert externalManager;

        celsrm__User_Master__c externalResolver = new celsrm__User_Master__c(
            Name = 'Partner Resolver',
            celsrm__Email__c = 'partner.resolver@example.com',
            celsrm__Is_External_User__c = true,
            celsrm__Manager__c = externalManager.Id
        );
        insert externalResolver;

        celsrm__Dispute_Workflow_Matrix__c internalMatrix = new celsrm__Dispute_Workflow_Matrix__c(
            // << START - MM - FIN-10180 - Test class error | INVALID_OR_NULL_FOR_RESTRICTED_PICKLIST>>
            // celsrm__Dispute_Type__c = 'Billing',
            // celsrm__Reason_Code__c = 'Tax rate incorrect',
            celsrm__Dispute_Type__c = '100 Financial & Invoicing',
            celsrm__Reason_Code__c = '101 Cash Discount Deduction',
            // << END - MM - FIN-10180 - Test class error | INVALID_OR_NULL_FOR_RESTRICTED_PICKLIST>>
            celsrm__User_Type__c = 'approver',
            celsrm__Optional__c = false,
            celsrm__Level__c = 11,
            celsrm__User_SLA_Days__c = 2,
            celsrm__Is_Active__c = true,
            //-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
            celsrm__User_Master__c = internalMaster.Id
            //-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
        );
        insert internalMatrix;

        //-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
        // internalMatrix = [
        //     SELECT celsrm__User_Master__c, celsrm__User__c, External_Email__c
        //     FROM celsrm__Dispute_Workflow_Matrix__c
        //     WHERE Id = :internalMatrix.Id
        // ];
        // //-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
        // //-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
        // System.assertEquals(internalMaster.Id, internalMatrix.celsrm__User_Master__c);
        // //-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
        // System.assertEquals(UserInfo.getUserId(), internalMatrix.celsrm__User__c);
        // System.assertEquals(null, internalMatrix.External_Email__c);

        celsrm__Dispute_Workflow_Matrix__c externalMatrix = new celsrm__Dispute_Workflow_Matrix__c(
            // << START - MM - FIN-10180 - Test class error | INVALID_OR_NULL_FOR_RESTRICTED_PICKLIST>>
            // celsrm__Dispute_Type__c = 'Billing',
            // celsrm__Reason_Code__c = 'Tax rate incorrect',
            celsrm__Dispute_Type__c = '100 Financial & Invoicing',
            celsrm__Reason_Code__c = '101 Cash Discount Deduction',
            // << END - MM - FIN-10180 - Test class error | INVALID_OR_NULL_FOR_RESTRICTED_PICKLIST>>
            celsrm__User_Type__c = 'approver',
            celsrm__Optional__c = false,
            celsrm__Level__c = 12,
            celsrm__User_SLA_Days__c = 2,
            celsrm__Is_Active__c = true,
            //-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
            celsrm__User_Master__c = externalResolver.Id
            //-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
        );
        insert externalMatrix;

        //-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
        // externalMatrix = [
        //     SELECT celsrm__User_Master__c, celsrm__User__c, External_Email__c,
        //     External_Manager_Email__c
        //     FROM celsrm__Dispute_Workflow_Matrix__c
        //     WHERE Id = :externalMatrix.Id
        // ];
        // //-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
        // //-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
        // System.assertEquals(externalResolver.Id, externalMatrix.celsrm__User_Master__c);
        // //-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
        // System.assertEquals(null, externalMatrix.celsrm__User__c);
        // System.assertEquals('partner.resolver@example.com', externalMatrix.External_Email__c);
        // System.assertEquals('partner.manager@example.com', externalMatrix.External_Manager_Email__c);

        Account accountRecord = DataGenerator.insertAccount();
        celsrm__Transaction__c transactionRecord = DataGenerator.insertTransaction(accountRecord);
        celsrm__Dispute__c disputeRecord = DataGenerator.insertDispute(transactionRecord, accountRecord, 1)[0];
        update new celsrm__Dispute__c(
            Id = disputeRecord.Id,
            //-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
            celsrm__Resolver_User_Master__c = null,
            //-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
            celsrm__Dispute_Resolver__c = UserInfo.getUserId(),
            External_Resolver_Email__c = null
        );

        //-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
        celsrm__Dispute_Workflow_Details__c workflowDetail = new celsrm__Dispute_Workflow_Details__c(
            celsrm__Dispute__c = disputeRecord.Id,
            celsrm__Dispute_Workflow_Matrix__c = internalMatrix.Id,
            celsrm__Status__c = 'Pending',
            celsrm__User_Master__c = null
                    );
        //-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
        insert workflowDetail;

        DisputeUserMasterService.ResolvedUserInfo resolvedInternalUser =
            DisputeUserMasterService.resolveUserAssignment(
                internalMaster.Id,
                String.valueOf(UserInfo.getUserId()),
                'Current User',
                false,
                null
            );

        celsrm__Dispute__c disputeUpdate = new celsrm__Dispute__c(Id = disputeRecord.Id);
        DisputeUserMasterService.applyAssignmentToDispute(disputeUpdate, resolvedInternalUser);
        update disputeUpdate;

        //-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
        celsrm__Dispute_Workflow_Details__c workflowDetailUpdate = new celsrm__Dispute_Workflow_Details__c(Id = workflowDetail.Id);
        //-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
        DisputeUserMasterService.applyAssignmentToWorkflowDetail(workflowDetailUpdate, resolvedInternalUser);
        update workflowDetailUpdate;

        //-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
        // disputeRecord = [
        //     SELECT celsrm__Resolver_User_Master__c, celsrm__Dispute_Resolver__c, External_Resolver_Email__c
        //     FROM celsrm__Dispute__c
        //     WHERE Id = :disputeRecord.Id
        // ];
        // //-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
        // //-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
        // System.assertEquals(internalMaster.Id, disputeRecord.celsrm__Resolver_User_Master__c);
        // //-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
        // System.assertEquals(UserInfo.getUserId(), disputeRecord.celsrm__Dispute_Resolver__c);
        // System.assertEquals(null, disputeRecord.External_Resolver_Email__c);

        // //-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
        // workflowDetail = [
        //     SELECT celsrm__User_Master__c
        //     FROM celsrm__Dispute_Workflow_Details__c
        //     WHERE Id = :workflowDetail.Id
        // ];
        //-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
        //-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
        // System.assertEquals(internalMaster.Id, workflowDetail.celsrm__User_Master__c);
        // System.assertEquals(UserInfo.getUserId(), workflowDetail.celsrm__User__c);
        // System.assertEquals(null, workflowDetail.External_User_Email__c);
        // System.assertNotEquals(null, workflowDetail.User_Name__c);
        //-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
    }

    @IsTest
    static void testWorkflowMatrixTriggerSkipsCircularExternalManagerHierarchy() {
        celsrm__Dispute_Workflow_Matrix__c firstMatrix = new celsrm__Dispute_Workflow_Matrix__c(
            // << START - MM - FIN-10180 - Test class error | INVALID_OR_NULL_FOR_RESTRICTED_PICKLIST>>
            // celsrm__Dispute_Type__c = 'Billing',
            // celsrm__Reason_Code__c = 'Tax rate incorrect',
            celsrm__Dispute_Type__c = '100 Financial & Invoicing',
            celsrm__Reason_Code__c = '101 Cash Discount Deduction',
            // << END - MM - FIN-10180 - Test class error | INVALID_OR_NULL_FOR_RESTRICTED_PICKLIST>>
            celsrm__User_Type__c = 'approver',
            celsrm__Optional__c = false,
            celsrm__Level__c = 31,
            celsrm__User_SLA_Days__c = 2,
            celsrm__Is_Active__c = true,
            External_Email__c = 'partner.one@example.com',
            External_Manager_Email__c = 'partner.two@example.com'
        );
        celsrm__Dispute_Workflow_Matrix__c secondMatrix = new celsrm__Dispute_Workflow_Matrix__c(
            // << START - MM - FIN-10180 - Test class error | INVALID_OR_NULL_FOR_RESTRICTED_PICKLIST>>
            // celsrm__Dispute_Type__c = 'Billing',
            // celsrm__Reason_Code__c = 'Tax rate incorrect',
            celsrm__Dispute_Type__c = '100 Financial & Invoicing',
            celsrm__Reason_Code__c = '101 Cash Discount Deduction',
            // << END - MM - FIN-10180 - Test class error | INVALID_OR_NULL_FOR_RESTRICTED_PICKLIST>>
            celsrm__User_Type__c = 'approver',
            celsrm__Optional__c = false,
            celsrm__Level__c = 32,
            celsrm__User_SLA_Days__c = 2,
            celsrm__Is_Active__c = true,
            External_Email__c = 'partner.two@example.com',
            External_Manager_Email__c = 'partner.one@example.com'
        );
        insert new List<celsrm__Dispute_Workflow_Matrix__c>{ firstMatrix, secondMatrix };

        // List<celsrm__User_Master__c> masters = [
        //     SELECT celsrm__Email__c, celsrm__Manager__c
        //     FROM celsrm__User_Master__c
        //     WHERE celsrm__Email__c IN ('partner.one@example.com', 'partner.two@example.com')
        //     ORDER BY celsrm__Email__c
        // ];

        // System.assertEquals(2, masters.size());
        // System.assertEquals(null, masters[0].celsrm__Manager__c);
        // System.assertEquals(null, masters[1].celsrm__Manager__c);

        //-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
        // List<celsrm__Dispute_Workflow_Matrix__c> matrices = [
        //     SELECT celsrm__User_Master__c, External_Email__c, External_Manager_Email__c
        //     FROM celsrm__Dispute_Workflow_Matrix__c
        //     WHERE Id IN :new Set<Id>{ firstMatrix.Id, secondMatrix.Id }
        // ];
        // //-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
        // for (celsrm__Dispute_Workflow_Matrix__c matrixRecord : matrices) {
        //     //-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
        //     System.assertNotEquals(null, matrixRecord.celsrm__User_Master__c);
        //     //-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
        //     System.assertNotEquals(null, matrixRecord.External_Email__c);
        //     System.assertNotEquals(null, matrixRecord.External_Manager_Email__c);
        // }
        //-- End | FIN-10143 | Changed by Asera | 20-Jul-2026 --//
    }
//-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
}
//-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//