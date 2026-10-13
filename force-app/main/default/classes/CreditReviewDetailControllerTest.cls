@IsTest
private class CreditReviewDetailControllerTest {
    private static void upsertConfig(Boolean useCustomApproval, Boolean allowDelegatedManager, Boolean ownerCanActOnQueue) {
        celsrm__Credit_Configuration__c config = celsrm__Credit_Configuration__c.getOrgDefaults();
        if (config == null) {
            config = new celsrm__Credit_Configuration__c(SetupOwnerId = UserInfo.getOrganizationId());
        }
        config.celsrm__Use_Credit_Limit_Approval_Matrix__c = useCustomApproval;
        config.celsrm__Allow_Delegated_User_Manger_to_act__c = allowDelegatedManager;
        config.celsrm__Owner_Can_Act_on_Queue_Reviews__c = ownerCanActOnQueue;
        upsert config;
    }

    private static celsrm__User_Master__c createOrGetCurrentUserMaster() {
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
        celsrm__User_Master__c row = new celsrm__User_Master__c(
            celsrm__User__c = UserInfo.getUserId(),
            celsrm__Is_Active__c = true
        );
        insert row;
        return row;
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

    private static celsrm__Credit_Review__c createPendingReview() {
        Account acc = new Account(Name = 'CR Detail Test Account ' + String.valueOf(DateTime.now().getTime()));
        insert acc;
        celsrm__Credit_Review__c review = new celsrm__Credit_Review__c(
            celsrm__Account__c = acc.Id,
            celsrm__Status__c = 'Pending',
            celsrm__Requested_Credit_Limit__c = 1000,
            celsrm__Requested_Credit_Limit_Group_Currency__c = 1000
        );
        insert review;
        return review;
    }

    private static celsrm__Credit_Limit_Approval_Matrix__c createMatrix(String payloadJson) {
        celsrm__Credit_Limit_Approval_Matrix__c matrix = new celsrm__Credit_Limit_Approval_Matrix__c(
            Name = 'CR Detail Matrix',
            celsrm__Order__c = 1,
            celsrm__Is_Active__c = true,
            celsrm__Criteria__c = JSON.serialize(new Map<String, Object>{
                'criteriaCondition' => '',
                'criteria' => new List<Object>()
            }),
            celsrm__Approval_Matrices__c = payloadJson
        );
        insert matrix;
        return matrix;
    }

    @IsTest
    static void testOnPageLoadFunction_DirectAssignedUserHasAccess() {
        upsertConfig(true, false, false);
        celsrm__User_Master__c currentUserMaster = createOrGetCurrentUserMaster();
        celsrm__Credit_Review__c review = createPendingReview();
        insert new celsrm__Credit_Limit_Approval_Detail__c(
            celsrm__Credit_Review__c = review.Id,
            celsrm__User_Master__c = currentUserMaster.Id,
            celsrm__Status__c = 'Pending',
            celsrm__Level__c = 1
        );

        Test.startTest();
        Map<Object, Object> result = CreditReviewDetailController.onPageLoadFunction(
            new Map<Object, Object>{ 'Id' => review.Id }
        );
        Test.stopTest();

        System.assertEquals('true', String.valueOf(result.get('CurrentUserIsApprover')));
        System.assertEquals('Direct user assignment.', String.valueOf(result.get('accessReason')));
        System.assertEquals('true', String.valueOf(result.get('UseCustomApprovalProcess')));
        System.assertNotEquals(null, result.get('creditReviewNumber'));
    }

    @IsTest
    static void testOnPageLoadFunction_NoAccessWhenNotAssigned() {
        upsertConfig(true, false, false);
        celsrm__User_Master__c currentUserMaster = createOrGetCurrentUserMaster();
        celsrm__User_Master__c otherUserMaster = createUnlinkedUserMaster();
        celsrm__Credit_Review__c review = createPendingReview();
        insert new celsrm__Credit_Limit_Approval_Detail__c(
            celsrm__Credit_Review__c = review.Id,
            celsrm__User_Master__c = otherUserMaster.Id,
            celsrm__Status__c = 'Pending',
            celsrm__Level__c = 1
        );

        Test.startTest();
        Map<Object, Object> result = CreditReviewDetailController.onPageLoadFunction(
            new Map<Object, Object>{ 'Id' => review.Id }
        );
        Test.stopTest();

        System.assertEquals('false', String.valueOf(result.get('CurrentUserIsApprover')));
        System.assertEquals(
            'Current user is not eligible to act on pending entries.',
            String.valueOf(result.get('accessReason'))
        );
    }

    @IsTest
    static void testOnLoadCreditReviewWorkflowMatrix_UserRowsAndCurrentApprover() {
        celsrm__User_Master__c currentUserMaster = createOrGetCurrentUserMaster();
        celsrm__User_Master__c otherUserMaster = createUnlinkedUserMaster();
        String matrixPayload = JSON.serialize(new List<Object>{
            new Map<String, Object>{
                'level' => 1,
                'approverType' => 'User',
                'approverUserIds' => new List<Object>{ currentUserMaster.Id, otherUserMaster.Id },
                'IsOptional' => true,
                'isActive' => true
            }
        });
        celsrm__Credit_Limit_Approval_Matrix__c matrix = createMatrix(matrixPayload);
        celsrm__Credit_Review__c review = createPendingReview();
        review.celsrm__Credit_Limit_Approval_Matrix__c = matrix.Id;
        update review;

        insert new celsrm__Credit_Limit_Approval_Detail__c(
            celsrm__Credit_Review__c = review.Id,
            celsrm__User_Master__c = currentUserMaster.Id,
            celsrm__Status__c = 'Pending',
            celsrm__Level__c = 1
        );

        Test.startTest();
        Map<Object, Object> result = CreditReviewDetailController.onLoadCreditReviewWorkflowMatrix(
            new Map<Object, Object>{ 'Id' => review.Id }
        );
        Test.stopTest();

        List<Object> rows = (List<Object>) result.get('dataServiceResponse');
        System.assertEquals(2, rows.size(), 'Both configured approver user rows should be returned.');

        Boolean foundCurrentApprover = false;
        for (Object rowObj : rows) {
            Map<Object, Object> row = (Map<Object, Object>) rowObj;
            Map<String, Object> assignee = (Map<String, Object>) row.get('assignee');
            if (String.valueOf(assignee.get('id')) == String.valueOf(currentUserMaster.Id)) {
                foundCurrentApprover = Boolean.valueOf(String.valueOf(row.get('isCurrentApprover')));
            }
        }
        System.assertEquals(true, foundCurrentApprover, 'Current pending approver row should be flagged.');
    }

    @IsTest
    static void testFetchCreditReviewWorkflowHistory() {
        celsrm__User_Master__c currentUserMaster = createOrGetCurrentUserMaster();
        celsrm__Credit_Review__c review = createPendingReview();
        insert new celsrm__Credit_Limit_Approval_Detail__c(
            celsrm__Credit_Review__c = review.Id,
            celsrm__User_Master__c = currentUserMaster.Id,
            celsrm__Status__c = 'Completed',
            celsrm__Level__c = 1,
            celsrm__User_Action__c = 'Credit Review Approved',
            celsrm__Action_Date__c = Date.today(),
            celsrm__Action_Taken_By__c = createOrGetCurrentUserMaster().Id,
            celsrm__Is_Optional__c = true
        );

        Test.startTest();
        Map<Object, Object> result = CreditReviewDetailController.fetchCreditReviewWorkflowHistory(
            new Map<Object, Object>{ 'Id' => review.Id }
        );
        Test.stopTest();

        List<Object> rows = (List<Object>) result.get('dataServiceResponse');
        System.assertEquals(1, rows.size(), 'History should return inserted detail row.');
        Map<Object, Object> historyRow = (Map<Object, Object>) rows[0];
        System.assertEquals('Completed', String.valueOf(historyRow.get('status')));
        System.assertEquals('Credit Review Approved', String.valueOf(historyRow.get('actionName')));
        System.assertEquals(true, Boolean.valueOf(String.valueOf(historyRow.get('isOptional'))));
        System.assertNotEquals(null, historyRow.get('actionTakenBy'), 'Action taker should be returned.');
        System.assertNotEquals(null, historyRow.get('assignee'), 'Assignee should be returned.');
    }
}