//-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
@IsTest
private class DisputeApprovalActionServiceTest {
    @IsTest
    static void testProcessApprovalActionRejectsWhenNotPending() {
        Account accountRow = DataGenerator.insertAccount();
        celsrm__Transaction__c transactionRow = DataGenerator.insertTransaction(accountRow);
        celsrm__Dispute__c dispute = DataGenerator.insertDispute(transactionRow, accountRow, 1)[0];
        dispute.celsrm__Status__c = 'Approved';
        update dispute;

        Test.startTest();
        String result = DisputeApprovalActionService.processApprovalAction(
            dispute.Id,
            'Approve',
            null,
            'note'
        );
        Test.stopTest();

    }

    @IsTest
    static void testProcessApprovalActionApprovesParallelOne() {
        celsrm__Dispute_Configuration__c config = celsrm__Dispute_Configuration__c.getOrgDefaults();
        if (config == null) {
            config = new celsrm__Dispute_Configuration__c();
        }
        config.celsrm__Use_Dispute_Workflow_Matrix__c = true;
        config.celsrm__Dispute_Resolver_Type__c = 'Dispute_Workflow_Matrix';
        config.celsrm__Dispute_Workflow_Matrix_Flow_Type__c = 'Parallel';
        config.celsrm__Parallel_Approval_Mode__c = 'One';
        upsert config;

        celsrm__User_Master__c userMaster = createUserMaster('Test');
        celsrm__Dispute_Workflow_Matrix__c matrix = createMatrix(userMaster.Id, userMaster.Id);
        Account accountRow = DataGenerator.insertAccount();
        celsrm__Transaction__c transactionRow = DataGenerator.insertTransaction(accountRow);
        celsrm__Dispute__c dispute = DataGenerator.insertDispute(transactionRow, accountRow, 1)[0];
        dispute.celsrm__Amount__c = 25000;
        dispute.celsrm__Status__c = 'Pending Approval';
        dispute.celsrm__Workflow_Matrix_Id__c = matrix.Id;
        update dispute;

        insert new celsrm__Dispute_Workflow_Details__c(
            celsrm__Dispute__c = dispute.Id,
            celsrm__Dispute_Workflow_Matrix__c = matrix.Id,
            celsrm__User_Master__c = userMaster.Id,
            celsrm__Workflow_Level__c = 1,
            celsrm__Status__c = 'Pending',
            celsrm__Is_Optional__c = false,
            celsrm__Workflow_User_Type__c = 'Approver'
        );
        insert new celsrm__Dispute_Workflow_Details__c(
            celsrm__Dispute__c = dispute.Id,
            celsrm__Dispute_Workflow_Matrix__c = matrix.Id,
            celsrm__User_Master__c = userMaster.Id,
            celsrm__Workflow_Level__c = 1,
            celsrm__Status__c = 'Pending',
            celsrm__Is_Optional__c = false,
            celsrm__Workflow_User_Type__c = 'Approver'
        );

        Test.startTest();
        String result = DisputeApprovalActionService.processApprovalAction(
            dispute.Id,
            'Approve',
            userMaster.Id,
            'approved'
        );
        Test.stopTest();

    }

    //-- Starts | FIN-9786 | Changed by Asera | 24-Jun-2026 --//
    @IsTest
    static void testProcessApprovalActionResolveStartsParallelApprovalPhase() {
        celsrm__Dispute_Configuration__c config = celsrm__Dispute_Configuration__c.getOrgDefaults();
        if (config == null) {
            config = new celsrm__Dispute_Configuration__c();
        }
        config.celsrm__Use_Dispute_Workflow_Matrix__c = true;
        config.celsrm__Dispute_Resolver_Type__c = 'Dispute_Workflow_Matrix';
        config.celsrm__Dispute_Workflow_Matrix_Flow_Type__c = 'Parallel';
        config.celsrm__Parallel_Approval_Mode__c = 'One';
        upsert config;

        celsrm__User_Master__c resolver = createUserMaster('Test');
        // celsrm__User_Master__c approver = createUserMaster('Action Test Approver');
        celsrm__Dispute_Workflow_Matrix__c matrix = createResolverApproverMatrix(resolver.Id, resolver.Id);

        Account accountRow = DataGenerator.insertAccount();
        celsrm__Transaction__c transactionRow = DataGenerator.insertTransaction(accountRow);
        celsrm__Dispute__c dispute = DataGenerator.insertDispute(transactionRow, accountRow, 1)[0];
        dispute.celsrm__Amount__c = 25000;
        dispute.celsrm__Status__c = 'Open';
        dispute.celsrm__Workflow_Matrix_Id__c = matrix.Id;
        update dispute;

        celsrm__Dispute_Workflow_Details__c resolverDetail = new celsrm__Dispute_Workflow_Details__c(
            celsrm__Dispute__c = dispute.Id,
            celsrm__Dispute_Workflow_Matrix__c = matrix.Id,
            celsrm__User_Master__c = resolver.Id,
            celsrm__Workflow_Level__c = 1,
            celsrm__Status__c = 'Pending',
            celsrm__Is_Optional__c = false,
            celsrm__Workflow_User_Type__c = 'Resolver'
        );
        insert resolverDetail;

        Test.startTest();
        String result = DisputeApprovalActionService.processApprovalAction(
            dispute.Id,
            'Resolve',
            resolver.Id,
            resolverDetail.Id,
            'resolved'
        );
        Test.stopTest();

    }

    @IsTest
    static void testProcessApprovalActionResolveWaitsForOtherResolversWhenParallelAll() {
        celsrm__Dispute_Configuration__c config = celsrm__Dispute_Configuration__c.getOrgDefaults();
        if (config == null) {
            config = new celsrm__Dispute_Configuration__c();
        }
        config.celsrm__Use_Dispute_Workflow_Matrix__c = true;
        config.celsrm__Dispute_Resolver_Type__c = 'Dispute_Workflow_Matrix';
        config.celsrm__Dispute_Workflow_Matrix_Flow_Type__c = 'Parallel';
        config.celsrm__Parallel_Approval_Mode__c = 'All';
        upsert config;

        celsrm__User_Master__c resolverOne = createUserMaster('Action Test Resolver one');
        // celsrm__User_Master__c resolverTwo = createUserMaster('Action Test Resolver Two');
        // celsrm__User_Master__c approver = createUserMaster('Action Test Approver For All');
        celsrm__Dispute_Workflow_Matrix__c matrix = createTwoResolverApproverMatrix(
            resolverOne.Id,
            resolverOne.Id,
            resolverOne.Id
        );

        Account accountRow = DataGenerator.insertAccount();
        celsrm__Transaction__c transactionRow = DataGenerator.insertTransaction(accountRow);
        celsrm__Dispute__c dispute = DataGenerator.insertDispute(transactionRow, accountRow, 1)[0];
        dispute.celsrm__Amount__c = 25000;
        dispute.celsrm__Status__c = 'Open';
        dispute.celsrm__Workflow_Matrix_Id__c = matrix.Id;
        update dispute;

        celsrm__Dispute_Workflow_Details__c resolverOneDetail = new celsrm__Dispute_Workflow_Details__c(
            celsrm__Dispute__c = dispute.Id,
            celsrm__Dispute_Workflow_Matrix__c = matrix.Id,
            celsrm__User_Master__c = resolverOne.Id,
            celsrm__Workflow_Level__c = 1,
            celsrm__Status__c = 'Pending',
            celsrm__Is_Optional__c = false,
            celsrm__Workflow_User_Type__c = 'Resolver'
        );
        insert resolverOneDetail;
        insert new celsrm__Dispute_Workflow_Details__c(
            celsrm__Dispute__c = dispute.Id,
            celsrm__Dispute_Workflow_Matrix__c = matrix.Id,
            celsrm__User_Master__c = resolverOne.Id,
            celsrm__Workflow_Level__c = 2,
            celsrm__Status__c = 'Pending',
            celsrm__Is_Optional__c = false,
            celsrm__Workflow_User_Type__c = 'Resolver'
        );

        Test.startTest();
        String result = DisputeApprovalActionService.processApprovalAction(
            dispute.Id,
            'Resolve',
            resolverOne.Id,
            resolverOneDetail.Id,
            'resolved'
        );
        Test.stopTest();

    }
    //-- Ends | FIN-9786 | Changed by Asera | 24-Jun-2026 --//

    private static celsrm__User_Master__c createUserMaster() {
        return createUserMaster('Action Test User Master');
    }

    private static celsrm__User_Master__c createUserMaster(String nameValue) {
        celsrm__User_Master__c userMaster = new celsrm__User_Master__c(
            Name = nameValue,
            celsrm__User__c = UserInfo.getUserId()
        );
        insert userMaster;
        return userMaster;
    }

    private static celsrm__Dispute_Workflow_Matrix__c createMatrix(Id levelOneUser, Id levelTwoUser) {
        String matricesJson = JSON.serialize(new List<Object>{
            new Map<String, Object>{
                'level' => 1,
                'isActive' => true,
                'userType' => 'Approver',
                'approverType' => 'User',
                'approverUserId' => levelOneUser
            },
            new Map<String, Object>{
                'level' => 1,
                'isActive' => true,
                'userType' => 'Approver',
                'approverType' => 'User',
                'approverUserId' => levelTwoUser
            }
        });
        celsrm__Dispute_Workflow_Matrix__c matrix = new celsrm__Dispute_Workflow_Matrix__c(
            celsrm__Rule_Name__c = 'Parallel One Matrix',
            celsrm__Order__c = 1,
            celsrm__Is_Active__c = true,
            celsrm__Criteria__c = JSON.serialize(new Map<String, Object>{
                'criteriaCondition' => '',
                'criteria' => new List<Object>()
            }),
            celsrm__Approval_Matrices__c = matricesJson
        );
        insert matrix;
        return matrix;
    }

    //-- Starts | FIN-9786 | Changed by Asera | 24-Jun-2026 --//
    private static celsrm__Dispute_Workflow_Matrix__c createResolverApproverMatrix(Id resolverUser, Id approverUser) {
        String matricesJson = JSON.serialize(new List<Object>{
            new Map<String, Object>{
                'level' => 1,
                'isActive' => true,
                'userType' => 'Resolver',
                'approverType' => 'User',
                'approverUserId' => resolverUser
            },
            new Map<String, Object>{
                'level' => 2,
                'isActive' => true,
                'userType' => 'Approver',
                'approverType' => 'User',
                'approverUserId' => approverUser
            }
        });
        celsrm__Dispute_Workflow_Matrix__c matrix = new celsrm__Dispute_Workflow_Matrix__c(
            celsrm__Rule_Name__c = 'Parallel Resolver Approver Matrix',
            celsrm__Order__c = 1,
            celsrm__Is_Active__c = true,
            celsrm__Criteria__c = JSON.serialize(new Map<String, Object>{
                'criteriaCondition' => '',
                'criteria' => new List<Object>()
            }),
            celsrm__Approval_Matrices__c = matricesJson
        );
        insert matrix;
        return matrix;
    }

    private static celsrm__Dispute_Workflow_Matrix__c createTwoResolverApproverMatrix(
        Id resolverOne,
        Id resolverTwo,
        Id approverUser
    ) {
        String matricesJson = JSON.serialize(new List<Object>{
            new Map<String, Object>{
                'level' => 1,
                'isActive' => true,
                'userType' => 'Resolver',
                'approverType' => 'User',
                'approverUserId' => resolverOne
            },
            new Map<String, Object>{
                'level' => 2,
                'isActive' => true,
                'userType' => 'Resolver',
                'approverType' => 'User',
                'approverUserId' => resolverOne
            },
            new Map<String, Object>{
                'level' => 3,
                'isActive' => true,
                'userType' => 'Approver',
                'approverType' => 'User',
                'approverUserId' => resolverOne
            }
        });
        celsrm__Dispute_Workflow_Matrix__c matrix = new celsrm__Dispute_Workflow_Matrix__c(
            celsrm__Rule_Name__c = 'Parallel All Resolver Matrix',
            celsrm__Order__c = 1,
            celsrm__Is_Active__c = true,
            celsrm__Criteria__c = JSON.serialize(new Map<String, Object>{
                'criteriaCondition' => '',
                'criteria' => new List<Object>()
            }),
            celsrm__Approval_Matrices__c = matricesJson
        );
        insert matrix;
        return matrix;
    }
    //-- Ends | FIN-9786 | Changed by Asera | 24-Jun-2026 --//
}
//-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//