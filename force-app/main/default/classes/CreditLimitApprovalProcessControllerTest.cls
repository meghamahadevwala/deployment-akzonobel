@IsTest
private class CreditLimitApprovalProcessControllerTest {
    private static celsrm__Credit_Configuration__c upsertConfig(Decimal threshold, String flowType) {
        celsrm__Credit_Configuration__c config = celsrm__Credit_Configuration__c.getOrgDefaults();
        if (config == null) {
            config = new celsrm__Credit_Configuration__c(SetupOwnerId = UserInfo.getOrganizationId());
        }
        config.celsrm__Credit_Limit_Auto_Approve_Threshold__c = threshold;
        config.celsrm__Credit_Limit_Approval_Matrix_Flow_type__c = flowType;
        upsert config;
        return config;
    }

    private static celsrm__User_Master__c createUserMaster() {
        List<celsrm__User_Master__c> existingRows = [
            SELECT Id, celsrm__User__c, celsrm__Is_Active__c
            FROM celsrm__User_Master__c
            WHERE celsrm__User__c = :UserInfo.getUserId()
            LIMIT 1
        ];
        if (!existingRows.isEmpty()) {
            celsrm__User_Master__c existing = existingRows[0];
            if (existing.celsrm__Is_Active__c != true) {
                existing.celsrm__Is_Active__c = true;
                update existing;
            }
            return existing;
        }
        celsrm__User_Master__c row = new celsrm__User_Master__c();
        row.celsrm__User__c = UserInfo.getUserId();
        row.celsrm__Is_Active__c = true;
        insert row;
        return row;
    }

    private static celsrm__Credit_Review__c createCreditReview(Decimal requestedLimit) {
        Account acc = new Account(Name = 'CRP Test Account ' + String.valueOf(DateTime.now().getTime()));
        insert acc;

        celsrm__Credit_Review__c review = new celsrm__Credit_Review__c();
        review.celsrm__Account__c = acc.Id;
        review.celsrm__Requested_Credit_Limit__c = requestedLimit;
        review.celsrm__Requested_Credit_Limit_Group_Currency__c = requestedLimit;
        review.celsrm__Requested_Limit_Valid_To_Date__c = Date.today().addDays(30);
        insert review;
        return review;
    }

    private static celsrm__Credit_Limit_Approval_Matrix__c createMatrix(String nameValue, String approvalMatricesJson) {
        celsrm__Credit_Limit_Approval_Matrix__c matrix = new celsrm__Credit_Limit_Approval_Matrix__c();
        matrix.Name = nameValue;
        matrix.celsrm__Order__c = 1;
        matrix.celsrm__Is_Active__c = true;
        matrix.celsrm__Criteria__c = JSON.serialize(new Map<String, Object>{
            'criteriaCondition' => '',
            'criteria' => new List<Object>()
        });
        matrix.celsrm__Approval_Matrices__c = approvalMatricesJson;
        insert matrix;
        return matrix;
    }

    @IsTest
    static void testInitiateApprovalProcess_AutoApprove() {
        createUserMaster();
        upsertConfig(100, 'Sequential');
        celsrm__Credit_Review__c review = createCreditReview(50);

        Test.startTest();
        CreditLimitApprovalProcessController.initiateApprovalProcess(new List<Id>{ review.Id });
        Test.stopTest();

        celsrm__Credit_Review__c updated = [
            SELECT celsrm__Status__c, celsrm__Approved_Credit_Limit__c, Credit_Approved_Date__c, celsrm__Approved_Limit_Valid_To_Date__c
            FROM celsrm__Credit_Review__c
            WHERE Id = :review.Id
            LIMIT 1
        ];
        System.assertEquals('Auto Approved', updated.celsrm__Status__c, 'Below-threshold review should auto approve.');
        System.assertEquals(50, updated.celsrm__Approved_Credit_Limit__c, 'Approved amount should match requested amount.');
        System.assertEquals(Date.today(), updated.Credit_Approved_Date__c, 'Approved date should be set.');
        System.assertEquals(review.celsrm__Requested_Limit_Valid_To_Date__c, updated.celsrm__Approved_Limit_Valid_To_Date__c);

        Integer detailCount = [
            SELECT COUNT()
            FROM celsrm__Credit_Limit_Approval_Detail__c
            WHERE celsrm__Credit_Review__c = :review.Id
        ];
        System.assertEquals(0, detailCount, 'Auto-approved review should not create workflow details.');
    }

    @IsTest
    static void testInitiateApprovalProcess_SequentialCreatesLevelOneOnly() {
        upsertConfig(0, 'Sequential');
        celsrm__User_Master__c approver = createUserMaster();
        celsrm__Credit_Review__c review = createCreditReview(500);

        String matricesJson = JSON.serialize(new List<Object>{
            new Map<String, Object>{
                'level' => 1,
                'approverType' => 'User',
                'approverUserIds' => new List<Object>{ approver.Id },
                'isOptional' => true,
                'isActive' => true
            },
            new Map<String, Object>{
                'level' => 2,
                'approverType' => 'User',
                'approverUserIds' => new List<Object>{ approver.Id },
                'isOptional' => false,
                'isActive' => true
            }
        });
        celsrm__Credit_Limit_Approval_Matrix__c matrix = createMatrix('Sequential Matrix', matricesJson);

        Test.startTest();
        CreditLimitApprovalProcessController.initiateApprovalProcess(new List<Id>{ review.Id });
        Test.stopTest();

        celsrm__Credit_Review__c updated = [
            SELECT celsrm__Credit_Limit_Approval_Matrix__c
            FROM celsrm__Credit_Review__c
            WHERE Id = :review.Id
            LIMIT 1
        ];
        System.assertEquals(matrix.Id, updated.celsrm__Credit_Limit_Approval_Matrix__c, 'Matched matrix should be stamped.');

        List<celsrm__Credit_Limit_Approval_Detail__c> details = [
            SELECT celsrm__Level__c, celsrm__User_Master__c, celsrm__Queue__c, celsrm__Is_Optional__c, celsrm__Status__c
            FROM celsrm__Credit_Limit_Approval_Detail__c
            WHERE celsrm__Credit_Review__c = :review.Id
            ORDER BY celsrm__Level__c ASC
        ];
        System.assertEquals(1, details.size(), 'Sequential should create only first level assignments.');
        System.assertEquals(1, details[0].celsrm__Level__c.intValue());
        System.assertEquals(approver.Id, details[0].celsrm__User_Master__c);
        System.assertEquals(null, details[0].celsrm__Queue__c);
        System.assertEquals(true, details[0].celsrm__Is_Optional__c);
        System.assertEquals('Pending', details[0].celsrm__Status__c);
    }

    @IsTest
    static void testInitiateApprovalProcess_ParallelCreatesAllConfiguredLevels() {
        upsertConfig(0, 'Parallel');
        celsrm__User_Master__c approver = createUserMaster();
        Group queue = new Group(Name = 'CR Test Queue', DeveloperName = 'CR_Test_Queue', Type = 'Queue');
        insert queue;
        celsrm__Credit_Review__c review = createCreditReview(1000);

        String matricesJson = JSON.serialize(new List<Object>{
            new Map<String, Object>{
                'level' => 1,
                'approverType' => 'User',
                'approverUserIds' => new List<Object>{ approver.Id },
                'isOptional' => false,
                'isActive' => true
            },
            new Map<String, Object>{
                'level' => 2,
                'approverType' => 'Queue',
                'approverQueueId' => queue.Id,
                'IsOptional' => true,
                'isActive' => true
            }
        });
        celsrm__Credit_Limit_Approval_Matrix__c matrix = createMatrix('Parallel Matrix', matricesJson);

        Test.startTest();
        CreditLimitApprovalProcessController.initiateApprovalProcess(new List<Id>{ review.Id });
        Test.stopTest();

        celsrm__Credit_Review__c updated = [
            SELECT celsrm__Credit_Limit_Approval_Matrix__c
            FROM celsrm__Credit_Review__c
            WHERE Id = :review.Id
            LIMIT 1
        ];
        System.assertEquals(matrix.Id, updated.celsrm__Credit_Limit_Approval_Matrix__c);

        List<celsrm__Credit_Limit_Approval_Detail__c> details = [
            SELECT celsrm__Level__c, celsrm__User_Master__c, celsrm__Queue__c, celsrm__Is_Optional__c, celsrm__Status__c
            FROM celsrm__Credit_Limit_Approval_Detail__c
            WHERE celsrm__Credit_Review__c = :review.Id
            ORDER BY celsrm__Level__c ASC
        ];
        System.assertEquals(2, details.size(), 'Parallel should create details for all configured levels.');
        System.assertEquals(1, details[0].celsrm__Level__c.intValue());
        System.assertEquals(approver.Id, details[0].celsrm__User_Master__c);
        System.assertEquals(false, details[0].celsrm__Is_Optional__c);
        System.assertEquals(2, details[1].celsrm__Level__c.intValue());
        System.assertEquals(queue.Id, details[1].celsrm__Queue__c);
        System.assertEquals(true, details[1].celsrm__Is_Optional__c);
        System.assertEquals('Pending', details[1].celsrm__Status__c);
    }
}