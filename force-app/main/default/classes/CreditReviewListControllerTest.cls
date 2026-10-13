@IsTest
private class CreditReviewListControllerTest {
    private static celsrm__User_Master__c createCurrentUserMaster() {
        celsrm__User_Master__c row = new celsrm__User_Master__c();
        row.celsrm__User__c = UserInfo.getUserId();
        row.celsrm__Is_Active__c = true;
        insert row;
        return row;
    }

    private static celsrm__User_Master__c createUserMaster(Id delegatedUserMasterId, Id managerUserMasterId, Id linkedUserId) {
        celsrm__User_Master__c row = new celsrm__User_Master__c();
        row.celsrm__Is_Active__c = true;
        row.celsrm__Delegated_User__c = delegatedUserMasterId;
        row.celsrm__Manager__c = managerUserMasterId;
        if(linkedUserId == null){
            row.celsrm__User__c = null;
            row.celsrm__Is_External_User__c = true;
            row.celsrm__Email__c = 'abc@gmail.com';
        } else {
            row.celsrm__User__c = linkedUserId;
        }
        insert row;
        return row;
    }

    private static celsrm__Credit_Review__c createPendingCreditReview() {
        Account acc = new Account(Name = 'CRL Test Account');
        insert acc;

        celsrm__Credit_Review__c review = new celsrm__Credit_Review__c();
        review.celsrm__Account__c = acc.Id;
        review.celsrm__Status__c = 'Pending';
        review.celsrm__Requested_Credit_Limit__c = 1000;
        review.celsrm__Requested_Credit_Limit_Group_Currency__c = 1000;
        insert review;
        return review;
    }

    private static Group createQueueWithCurrentUserMember() {
        String suffix = String.valueOf(DateTime.now().getTime()).right(8);
        Group queue;
        System.runAs(new User(Id = UserInfo.getUserId())) {
            queue = new Group(
                Name = 'CRL Queue ' + suffix,
                DeveloperName = 'CRLQ_' + suffix,
                Type = 'Queue'
            );
            insert queue;

            GroupMember membership = new GroupMember(
                GroupId = queue.Id,
                UserOrGroupId = UserInfo.getUserId()
            );
            insert membership;
        }
        return queue;
    }

    private static void upsertDelegatedManagerConfig(Boolean enabled) {
        System.runAs(new User(Id = UserInfo.getUserId())) {
            celsrm__Credit_Configuration__c config = celsrm__Credit_Configuration__c.getOrgDefaults();
            if (config == null) {
                config = new celsrm__Credit_Configuration__c(SetupOwnerId = UserInfo.getOrganizationId());
            }
            config.celsrm__Allow_Delegated_User_Manger_to_act__c = enabled;
            upsert config;
        }
    }

    @IsTest
    static void testOnPageLoadFunctionAssignedToMe() {
        celsrm__User_Master__c currentUserMaster = createCurrentUserMaster();
        celsrm__Credit_Review__c review = createPendingCreditReview();
        insert new celsrm__Credit_Limit_Approval_Detail__c(
            celsrm__Credit_Review__c = review.Id,
            celsrm__User_Master__c = currentUserMaster.Id,
            celsrm__Status__c = 'Pending',
            celsrm__Level__c = 1
        );

        Test.startTest();
        Map<Object, Object> result = CreditReviewListController.onPageLoadFunctionAssignedToMe(new Map<Object, Object>());
        Test.stopTest();

        List<Object> rows = (List<Object>) result.get('dataServiceResponse');
        System.assertEquals(1, rows.size(), 'Assigned to me should return one row.');
    }

    @IsTest
    static void testOnPageLoadFunctionAssignedToQueue() {
        Group queue = createQueueWithCurrentUserMember();
        celsrm__Credit_Review__c review = createPendingCreditReview();
        insert new celsrm__Credit_Limit_Approval_Detail__c(
            celsrm__Credit_Review__c = review.Id,
            celsrm__Queue__c = queue.Id,
            celsrm__Status__c = 'Pending',
            celsrm__Level__c = 1
        );

        Test.startTest();
        Map<Object, Object> result = CreditReviewListController.onPageLoadFunctionAssignedToQueue(new Map<Object, Object>());
        Test.stopTest();

        List<Object> rows = (List<Object>) result.get('dataServiceResponse');
        System.assertEquals(1, rows.size(), 'Assigned to queue should return one row.');
    }

    @IsTest
    static void testOnPageLoadFunctionAssignedToDelegated_ConfigDisabled() {
        upsertDelegatedManagerConfig(false);

        Test.startTest();
        Map<Object, Object> result = CreditReviewListController.onPageLoadFunctionAssignedToDelegated(new Map<Object, Object>());
        Test.stopTest();

        List<Object> rows = (List<Object>) result.get('dataServiceResponse');
        System.assertEquals(0, rows.size(), 'Delegated list should be empty when feature is disabled.');
    }

    @IsTest
    static void testOnPageLoadFunctionAssignedToDelegated_ConfigEnabled() {
        upsertDelegatedManagerConfig(true);
        celsrm__User_Master__c currentUserMaster = createCurrentUserMaster();
        celsrm__User_Master__c delegatedTarget = createUserMaster(currentUserMaster.Id, null, null);
        celsrm__Credit_Review__c review = createPendingCreditReview();
        insert new celsrm__Credit_Limit_Approval_Detail__c(
            celsrm__Credit_Review__c = review.Id,
            celsrm__User_Master__c = delegatedTarget.Id,
            celsrm__Status__c = 'Pending',
            celsrm__Level__c = 1
        );

        Test.startTest();
        Map<Object, Object> result = CreditReviewListController.onPageLoadFunctionAssignedToDelegated(new Map<Object, Object>());
        Test.stopTest();

        List<Object> rows = (List<Object>) result.get('dataServiceResponse');
        System.assertEquals(1, rows.size(), 'Delegated list should include delegated assignee rows.');
    }

    @IsTest
    static void testOnPageLoadFunctionAssignedToManager() {
        celsrm__User_Master__c currentUserMaster = createCurrentUserMaster();
        celsrm__User_Master__c managedTarget = createUserMaster(null, currentUserMaster.Id, null);
        celsrm__Credit_Review__c review = createPendingCreditReview();
        insert new celsrm__Credit_Limit_Approval_Detail__c(
            celsrm__Credit_Review__c = review.Id,
            celsrm__User_Master__c = managedTarget.Id,
            celsrm__Status__c = 'Pending',
            celsrm__Level__c = 1
        );

        Test.startTest();
        Map<Object, Object> result = CreditReviewListController.onPageLoadFunctionAssignedToManager(new Map<Object, Object>());
        Test.stopTest();

        List<Object> rows = (List<Object>) result.get('dataServiceResponse');
        System.assertEquals(1, rows.size(), 'Manager list should include managed assignee rows.');
    }
}