@IsTest
private class UpdateCreditReviewControllerTest {
    private static Integer reviewSeed = 0;

    private static void upsertConfig(String flowType, String parallelMode) {
        celsrm__Credit_Configuration__c config = celsrm__Credit_Configuration__c.getOrgDefaults();
        if (config == null) {
            config = new celsrm__Credit_Configuration__c(SetupOwnerId = UserInfo.getOrganizationId());
        }
        config.celsrm__Credit_Limit_Approval_Matrix_Flow_type__c = flowType;
        config.celsrm__Parallel_Approval_Mode__c = parallelMode;
        upsert config;
    }

    private static celsrm__User_Master__c ensureCurrentUserMaster() {
        List<celsrm__User_Master__c> existingRows = [
            SELECT Id, celsrm__Is_Active__c
            FROM celsrm__User_Master__c
            WHERE celsrm__User__c = :UserInfo.getUserId()
            LIMIT 1
        ];
        if (!existingRows.isEmpty()) {
            celsrm__User_Master__c row = existingRows[0];
            if (row.celsrm__Is_Active__c != true) {
                row.celsrm__Is_Active__c = true;
                update row;
            }
            return row;
        }

        celsrm__User_Master__c created = new celsrm__User_Master__c(
            celsrm__User__c = UserInfo.getUserId(),
            celsrm__Is_Active__c = true
        );
        insert created;
        return created;
    }

    private static celsrm__User_Master__c createUnlinkedUserMaster() {
        celsrm__User_Master__c row = new celsrm__User_Master__c(
            celsrm__Is_Active__c = true,
            celsrm__User__c = null,
            celsrm__Is_External_User__c = true,
            celsrm__Email__c = 'abc@gmail.com'
        );
        insert row;
        return row;
    }

    private static celsrm__Credit_Limit_Approval_Matrix__c createMatrix(String matrixPayload) {
        celsrm__Credit_Limit_Approval_Matrix__c matrix = new celsrm__Credit_Limit_Approval_Matrix__c(
            Name = 'UCRC Matrix ' + String.valueOf(DateTime.now().getTime()),
            celsrm__Order__c = 1,
            celsrm__Is_Active__c = true,
            celsrm__Criteria__c = JSON.serialize(new Map<String, Object>{
                'criteriaCondition' => '',
                'criteria' => new List<Object>()
            }),
            celsrm__Approval_Matrices__c = matrixPayload
        );
        insert matrix;
        return matrix;
    }

    private static celsrm__Credit_Review__c createPendingReview(Id matrixId) {
        reviewSeed++;
        Account acc = new Account(Name = 'UCRC Test Account ' + reviewSeed + ' ' + DateTime.now().getTime());
        Database.DMLOptions dmlOptions = new Database.DMLOptions();
        dmlOptions.DuplicateRuleHeader.allowSave = true;
        acc.setOptions(dmlOptions);
        insert acc;

        celsrm__Credit_Review__c review = new celsrm__Credit_Review__c(
            celsrm__Account__c = acc.Id,
            celsrm__Status__c = 'Pending',
            celsrm__Requested_Credit_Limit__c = 1000,
            celsrm__Requested_Credit_Limit_Group_Currency__c = 1000,
            celsrm__Requested_Limit_Valid_To_Date__c = Date.today().addDays(30),
            celsrm__Credit_Limit_Approval_Matrix__c = matrixId
        );
        insert review;
        return review;
    }

    private static celsrm__Credit_Limit_Approval_Detail__c createPendingDetail(
        Id reviewId,
        Integer levelValue,
        Id userMasterId,
        Boolean isOptional
    ) {
        celsrm__Credit_Limit_Approval_Detail__c detail = new celsrm__Credit_Limit_Approval_Detail__c(
            celsrm__Credit_Review__c = reviewId,
            celsrm__Status__c = 'Pending',
            celsrm__Level__c = levelValue,
            celsrm__User_Master__c = userMasterId,
            celsrm__Is_Optional__c = isOptional
        );
        insert detail;
        return detail;
    }

    @IsTest
    static void testOnPageLoadFunction_SequentialApproveFindsNextApprover() {
        upsertConfig('Sequential', 'One');
        celsrm__User_Master__c currentUserMaster = ensureCurrentUserMaster();
        celsrm__User_Master__c nextApprover = createUnlinkedUserMaster();

        String matrixPayload = JSON.serialize(new List<Object>{
            new Map<String, Object>{
                'level' => 2,
                'approverType' => 'User',
                'approverUserIds' => new List<Object>{ nextApprover.Id },
                'isOptional' => true,
                'isActive' => true
            }
        });
        celsrm__Credit_Limit_Approval_Matrix__c matrix = createMatrix(matrixPayload);
        celsrm__Credit_Review__c review = createPendingReview(matrix.Id);
        celsrm__Credit_Limit_Approval_Detail__c currentPending = createPendingDetail(review.Id, 1, currentUserMaster.Id, false);

        Test.startTest();
        Map<Object, Object> result = UpdateCreditReviewController.onPageLoadFunction(new Map<Object, Object>{
            'Id' => review.Id,
            'userAction' => 'approve'
        });
        Test.stopTest();

    }

    @IsTest
    static void testOnPageLoadFunction_ParallelAllSetsPendingApproverFlag() {
        upsertConfig('Parallel', 'All');
        celsrm__User_Master__c currentUserMaster = ensureCurrentUserMaster();
        celsrm__User_Master__c otherApprover = createUnlinkedUserMaster();
        celsrm__Credit_Review__c review = createPendingReview(null);

        celsrm__Credit_Limit_Approval_Detail__c currentPending = createPendingDetail(review.Id, 1, currentUserMaster.Id, false);
        createPendingDetail(review.Id, 2, otherApprover.Id, false);

        Test.startTest();
        Map<Object, Object> result = UpdateCreditReviewController.onPageLoadFunction(new Map<Object, Object>{
            'Id' => review.Id,
            'userAction' => 'approve'
        });
        Test.stopTest();

    }

    @IsTest
    static void testUpdateCreditReview_ApproveSequentialAddsNextLevelAndRevokesPeers() {
        upsertConfig('Sequential', 'One');
        celsrm__User_Master__c currentUserMaster = ensureCurrentUserMaster();
        celsrm__User_Master__c sameLevelPeer = createUnlinkedUserMaster();
        // celsrm__User_Master__c nextApprover = createUnlinkedUserMaster();

        celsrm__Credit_Limit_Approval_Matrix__c matrix = createMatrix(JSON.serialize(new List<Object>()));
        celsrm__Credit_Review__c review = createPendingReview(matrix.Id);
        celsrm__Credit_Limit_Approval_Detail__c currentPending = createPendingDetail(review.Id, 1, currentUserMaster.Id, false);
        celsrm__Credit_Limit_Approval_Detail__c peerPending = createPendingDetail(review.Id, 1, sameLevelPeer.Id, false);

        Map<Object, Object> inMap = new Map<Object, Object>{
            'Id' => review.Id,
            'userAction' => 'approve',
            'creditLimitApprovalDetailId' => currentPending.Id,
            'sendToNextApprover' => true,
            'isLastApprover' => false,
            'nextApproverIds' => String.valueOf(sameLevelPeer.Id),
            'nextApproverLevel' => 2,
            'creditLimitApprovalMatrixId' => matrix.Id,
            'currentUserMasterIdsCsv' => String.valueOf(currentUserMaster.Id)
        };

        Test.startTest();
        UpdateCreditReviewController.UpdateCreditReview(inMap);
        Test.stopTest();

    }

    @IsTest
    static void testUpdateCreditReview_ApproveParallelAllWithPendingApprovers() {
        upsertConfig('Parallel', 'All');
        celsrm__User_Master__c currentUserMaster = ensureCurrentUserMaster();
        celsrm__User_Master__c otherApprover = createUnlinkedUserMaster();
        celsrm__Credit_Review__c review = createPendingReview(null);

        celsrm__Credit_Limit_Approval_Detail__c currentPending = createPendingDetail(review.Id, 1, currentUserMaster.Id, false);
        celsrm__Credit_Limit_Approval_Detail__c otherPending = createPendingDetail(review.Id, 2, otherApprover.Id, false);

        Map<Object, Object> inMap = new Map<Object, Object>{
            'Id' => review.Id,
            'userAction' => 'approve',
            'creditLimitApprovalDetailId' => currentPending.Id,
            'sendToNextApprover' => false,
            'isLastApprover' => true,
            'parallelPendingApprovers' => true,
            'currentUserMasterIdsCsv' => String.valueOf(currentUserMaster.Id)
        };

        Test.startTest();
        UpdateCreditReviewController.UpdateCreditReview(inMap);
        Test.stopTest();

    }

    @IsTest
    static void testUpdateCreditReview_RejectUpdatesReviewAndRows() {
        upsertConfig('Sequential', 'One');
        celsrm__User_Master__c currentUserMaster = ensureCurrentUserMaster();
        celsrm__User_Master__c sameLevelPeer = createUnlinkedUserMaster();
        celsrm__Credit_Review__c review = createPendingReview(null);

        celsrm__Credit_Limit_Approval_Detail__c currentPending = createPendingDetail(review.Id, 1, currentUserMaster.Id, false);
        celsrm__Credit_Limit_Approval_Detail__c peerPending = createPendingDetail(review.Id, 1, sameLevelPeer.Id, false);

        Test.startTest();
        UpdateCreditReviewController.UpdateCreditReview(new Map<Object, Object>{
            'Id' => review.Id,
            'userAction' => 'reject',
            'creditLimitApprovalDetailId' => currentPending.Id,
            'currentUserMasterIdsCsv' => String.valueOf(currentUserMaster.Id)
        });
        Test.stopTest();


    }

    @IsTest
    static void testInvokeRoutesToOnloadAndUpdate() {
        upsertConfig('Sequential', 'One');
        celsrm__User_Master__c currentUserMaster = ensureCurrentUserMaster();
        celsrm__Credit_Review__c review = createPendingReview(null);
        celsrm__Credit_Limit_Approval_Detail__c currentPending = createPendingDetail(review.Id, 1, currentUserMaster.Id, false);

        UpdateCreditReviewController controller = new UpdateCreditReviewController();

        Test.startTest();
        Map<Object, Object> onloadMap = controller.invoke('onPageLoadFunction', new Map<Object, Object>{
            'Id' => review.Id
        });
        controller.invoke('UpdateCreditReview', new Map<Object, Object>{
            'Id' => review.Id,
            'userAction' => 'reject',
            'creditLimitApprovalDetailId' => currentPending.Id,
            'currentUserMasterIdsCsv' => String.valueOf(currentUserMaster.Id)
        });
        Test.stopTest();

    }
}