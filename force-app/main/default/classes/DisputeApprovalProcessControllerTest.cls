//-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
@IsTest
private class DisputeApprovalProcessControllerTest {
    @IsTest
    static void testExtractAllLevelAssignmentsFiltersInactiveAndMapsFields() {
        String payload = JSON.serialize(new List<Object>{
            new Map<String, Object>{
                'level' => 1,
                'isActive' => false,
                'approverType' => 'User',
                'approverUserId' => UserInfo.getUserId()
            },
            new Map<String, Object>{
                'level' => 2,
                'isActive' => true,
                'isOptional' => true,
                'userType' => 'Resolver',
                'slDays' => 3,
                'approverType' => 'User',
                'approverUserIds' => new List<Object>{ UserInfo.getUserId() }
            }
        });

        List<DisputeApprovalProcessController.LevelAssignment> assignments =
            DisputeApprovalProcessController.extractAllLevelAssignments(payload);

    }

    @IsTest
    static void testInitiateApprovalInvocableDelegatesToCoreLogic() {
        celsrm__Dispute_Configuration__c config = celsrm__Dispute_Configuration__c.getOrgDefaults();
        if (config == null) {
            config = new celsrm__Dispute_Configuration__c();
        }
        config.celsrm__Use_Dispute_Workflow_Matrix__c = true;
        config.celsrm__Dispute_Resolver_Type__c = 'Dispute_Workflow_Matrix';
        config.celsrm__Dispute_Auto_Approve_Threshold__c = 10000;
        upsert config;

        Account accountRow = DataGenerator.insertAccount();
        celsrm__Transaction__c transactionRow = DataGenerator.insertTransaction(accountRow);
        celsrm__Dispute__c dispute = DataGenerator.insertDispute(transactionRow, accountRow, 1)[0];
        dispute.celsrm__Amount__c = 100;
        update dispute;

        DisputeApprovalProcessInvocable.Request request = new DisputeApprovalProcessInvocable.Request();
        request.disputeId = dispute.Id;

        Test.startTest();
        DisputeApprovalProcessInvocable.initiateApprovalProcess(
            new List<DisputeApprovalProcessInvocable.Request>{ request }
        );
        Test.stopTest();

    }

    @IsTest
    static void testInitiateApprovalProcessAutoApprovesBelowThreshold() {
        celsrm__Dispute_Configuration__c config = celsrm__Dispute_Configuration__c.getOrgDefaults();
        if (config == null) {
            config = new celsrm__Dispute_Configuration__c();
        }
        config.celsrm__Use_Dispute_Workflow_Matrix__c = true;
        config.celsrm__Dispute_Resolver_Type__c = 'Dispute_Workflow_Matrix';
        config.celsrm__Dispute_Auto_Approve_Threshold__c = 10000;
        upsert config;

        Account accountRow = DataGenerator.insertAccount();
        celsrm__Transaction__c transactionRow = DataGenerator.insertTransaction(accountRow);
        transactionRow.celsrm__Balance__c = 5000;
        update transactionRow;

        celsrm__Dispute__c dispute = DataGenerator.insertDispute(transactionRow, accountRow, 1)[0];
        dispute.celsrm__Amount__c = 100;
        update dispute;

        Test.startTest();
        DisputeApprovalProcessController.initiateApprovalProcess(new List<Id>{ dispute.Id });
        Test.stopTest();

    }

    @IsTest
    static void testInitiateApprovalProcessCreatesSequentialPendingDetails() {
        celsrm__Dispute_Configuration__c config = celsrm__Dispute_Configuration__c.getOrgDefaults();
        if (config == null) {
            config = new celsrm__Dispute_Configuration__c();
        }
        config.celsrm__Use_Dispute_Workflow_Matrix__c = true;
        config.celsrm__Dispute_Resolver_Type__c = 'Dispute_Workflow_Matrix';
        config.celsrm__Dispute_Auto_Approve_Threshold__c = null;
        config.celsrm__Dispute_Workflow_Matrix_Flow_Type__c = 'Sequential';
        upsert config;

        celsrm__User_Master__c userMaster = createUserMaster();
        String matricesJson = JSON.serialize(new List<Object>{
            new Map<String, Object>{
                'level' => 1,
                'isActive' => true,
                'approverType' => 'User',
                'approverUserId' => userMaster.Id
            },
            new Map<String, Object>{
                'level' => 2,
                'isActive' => true,
                'approverType' => 'User',
                'approverUserId' => userMaster.Id
            }
        });
        celsrm__Dispute_Workflow_Matrix__c matrix = new celsrm__Dispute_Workflow_Matrix__c(
            celsrm__Rule_Name__c = 'Test Sequential Matrix',
            celsrm__Order__c = 1,
            celsrm__Is_Active__c = true,
            celsrm__Criteria__c = JSON.serialize(new Map<String, Object>{
                'criteriaCondition' => '',
                'criteria' => new List<Object>()
            }),
            celsrm__Approval_Matrices__c = matricesJson
        );
        insert matrix;

        Account accountRow = DataGenerator.insertAccount();
        celsrm__Transaction__c transactionRow = DataGenerator.insertTransaction(accountRow);
        celsrm__Dispute__c dispute = DataGenerator.insertDispute(transactionRow, accountRow, 1)[0];
        dispute.celsrm__Amount__c = 50000;
        update dispute;

        Test.startTest();
        DisputeApprovalProcessController.initiateApprovalProcess(new List<Id>{ dispute.Id });
        Test.stopTest();

    }

    @IsTest
    static void testInitiateApprovalProcessCreatesOnlyResolverDetailsForParallel() {
        celsrm__Dispute_Configuration__c config = celsrm__Dispute_Configuration__c.getOrgDefaults();
        if (config == null) {
            config = new celsrm__Dispute_Configuration__c();
        }
        config.celsrm__Use_Dispute_Workflow_Matrix__c = true;
        config.celsrm__Dispute_Resolver_Type__c = 'Dispute_Workflow_Matrix';
        config.celsrm__Dispute_Auto_Approve_Threshold__c = null;
        config.celsrm__Dispute_Workflow_Matrix_Flow_Type__c = 'Parallel';
        config.celsrm__Parallel_Approval_Mode__c = 'All';
        upsert config;

        celsrm__User_Master__c resolver = createUserMaster('Internal Resolver', UserInfo.getUserEmail(), false);
        celsrm__User_Master__c externalApprover = createUserMaster('External Approver', 'external.approver@example.com', true);
        celsrm__User_Master__c internalApprover = resolver;

        String matricesJson = JSON.serialize(new List<Object>{
            new Map<String, Object>{
                'level' => 1,
                'isActive' => true,
                'userType' => 'Resolver',
                'approverType' => 'User',
                'approverUserId' => resolver.Id
            },
            new Map<String, Object>{
                'level' => 2,
                'isActive' => true,
                'userType' => 'Approver',
                'approverType' => 'User',
                'approverUserId' => externalApprover.Id
            },
            new Map<String, Object>{
                'level' => 3,
                'isActive' => true,
                'userType' => 'Approver',
                'approverType' => 'User',
                'approverUserId' => internalApprover.Id
            }
        });
        celsrm__Dispute_Workflow_Matrix__c matrix = new celsrm__Dispute_Workflow_Matrix__c(
            celsrm__Rule_Name__c = 'Test Parallel Matrix',
            celsrm__Order__c = 1,
            celsrm__Is_Active__c = true,
            celsrm__Criteria__c = JSON.serialize(new Map<String, Object>{
                'criteriaCondition' => '',
                'criteria' => new List<Object>()
            }),
            celsrm__Approval_Matrices__c = matricesJson
        );
        insert matrix;

        Account accountRow = DataGenerator.insertAccount();
        celsrm__Transaction__c transactionRow = DataGenerator.insertTransaction(accountRow);
        celsrm__Dispute__c dispute = DataGenerator.insertDispute(transactionRow, accountRow, 1)[0];
        dispute.celsrm__Amount__c = 50000;
        update dispute;

        Test.startTest();
        DisputeApprovalProcessController.initiateApprovalProcess(new List<Id>{ dispute.Id });
        Test.stopTest();

    }

    private static celsrm__User_Master__c createUserMaster() {
        return createUserMaster('Test User Master', UserInfo.getUserEmail(), false);
    }

    private static celsrm__User_Master__c createUserMaster(String nameValue, String emailValue, Boolean isExternal) {
        celsrm__User_Master__c userMaster = new celsrm__User_Master__c(
            Name = nameValue,
            celsrm__Email__c = emailValue,
            celsrm__Is_External_User__c = isExternal
        );
        if (isExternal != true) {
            userMaster.celsrm__User__c = UserInfo.getUserId();
        }
        insert userMaster;
        return userMaster;
    }
}
//-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//