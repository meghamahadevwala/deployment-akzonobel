@IsTest
private class CreditReviewApprovalServiceTest {

    @IsTest
    static void testProcessCreditReviewAction_MissingRequiredData() {
        RestRequest request = new RestRequest();
        request.requestBody = Blob.valueOf('{}');
        RestContext.request = request;
        RestContext.response = new RestResponse();

        String result = CreditReviewApprovalService.processCreditReviewAction();

        System.assertEquals('Required data are missing. Please check with admin.', result);
    }

    @IsTest
    static void testProcessCreditReviewAction_CreditReviewNotFound() {
        RestRequest request = new RestRequest();
        request.requestBody = Blob.valueOf(JSON.serialize(new Map<String, Object>{
            'action' => 'approve',
            'recordId' => '001000000000000AAA',
            'userMasterId' => '001000000000000AAA',
            'workflowDetailId' => '001000000000000AAA'
        }));
        RestContext.request = request;
        RestContext.response = new RestResponse();

        String result = CreditReviewApprovalService.processCreditReviewAction();

        System.assertEquals('Credit review not found.', result);
    }

    @IsTest
    static void testProcessCreditReviewAction_NoUserMasterFound() {
        celsrm__Credit_Review__c review = createPendingCreditReview();
        RestRequest request = new RestRequest();
        request.requestBody = Blob.valueOf(JSON.serialize(new Map<String, Object>{
            'action' => 'approve',
            'recordId' => review.Id,
            'userMasterId' => '001000000000000AAA',
            'workflowDetailId' => '001000000000000AAA'
        }));
        RestContext.request = request;
        RestContext.response = new RestResponse();

        String result = CreditReviewApprovalService.processCreditReviewAction();

        System.assertEquals('No user master found for provided userMasterId.', result);
    }

    @IsTest
    static void testProcessCreditReviewAction_UnauthorizedWorkflowDetail() {
        celsrm__User_Master__c currentUserMaster = createCurrentUserMaster();
        celsrm__Credit_Review__c review = createPendingCreditReview();

        RestRequest request = new RestRequest();
        request.requestBody = Blob.valueOf(JSON.serialize(new Map<String, Object>{
            'action' => 'approve',
            'recordId' => review.Id,
            'userMasterId' => currentUserMaster.Id,
            'workflowDetailId' => '001000000000000AAA'
        }));
        RestContext.request = request;
        RestContext.response = new RestResponse();

        String result = CreditReviewApprovalService.processCreditReviewAction();
    }

    @IsTest
    static void testProcessCreditReviewAction_ApproveSuccess() {
        celsrm__User_Master__c currentUserMaster = createCurrentUserMaster();
        celsrm__Credit_Limit_Approval_Matrix__c matrix = createApprovalMatrix(currentUserMaster.Id);
        celsrm__Credit_Review__c review = createPendingCreditReview();
        review.celsrm__Credit_Limit_Approval_Matrix__c = matrix.Id;
        update review;

        celsrm__Credit_Limit_Approval_Detail__c detail = new celsrm__Credit_Limit_Approval_Detail__c(
            celsrm__Credit_Review__c = review.Id,
            celsrm__Credit_Limit_Approval_Matrix__c = matrix.Id,
            celsrm__User_Master__c = currentUserMaster.Id,
            celsrm__Status__c = 'Pending',
            celsrm__Level__c = 1,
            celsrm__Is_Optional__c = false
        );
        insert detail;

        RestRequest request = new RestRequest();
        request.requestBody = Blob.valueOf(JSON.serialize(new Map<String, Object>{
            'action' => 'approve',
            'recordId' => review.Id,
            'userMasterId' => currentUserMaster.Id,
            'workflowDetailId' => detail.Id,
            'note' => 'Approved via REST test'
        }));
        RestContext.request = request;
        RestContext.response = new RestResponse();

        Test.startTest();
        String result = CreditReviewApprovalService.processCreditReviewAction();
        Test.stopTest();

        System.assert(result.contains('Credit review'), 'Expected a credit review status message.');
        System.assert(result.contains('successfully'), 'Expected success text in response.');

        celsrm__Credit_Review__c updatedReview = [
            SELECT celsrm__Status__c, celsrm__Last_Action_Taken_By__c
            FROM celsrm__Credit_Review__c
            WHERE Id = :review.Id
            LIMIT 1
        ];
        System.assertEquals('Approved', updatedReview.celsrm__Status__c);
        System.assertNotEquals(null, updatedReview.celsrm__Last_Action_Taken_By__c);
    }

    private static celsrm__Credit_Review__c createPendingCreditReview() {
        Account account = new Account(Name = 'Credit Review Account ' + String.valueOf(DateTime.now().getTime()));
        insert account;

        celsrm__Credit_Review__c review = new celsrm__Credit_Review__c(
            celsrm__Account__c = account.Id,
            celsrm__Status__c = 'Pending',
            celsrm__Requested_Credit_Limit__c = 1000,
            celsrm__Requested_Credit_Limit_Group_Currency__c = 1000,
            celsrm__Requested_Limit_Valid_To_Date__c = Date.today().addDays(30)
        );
        insert review;
        return review;
    }

    private static celsrm__User_Master__c createCurrentUserMaster() {
        List<celsrm__User_Master__c> existing = [
            SELECT Id, celsrm__Is_Active__c
            FROM celsrm__User_Master__c
            WHERE celsrm__User__c = :UserInfo.getUserId()
            LIMIT 1
        ];
        if (!existing.isEmpty()) {
            celsrm__User_Master__c current = existing[0];
            if (current.celsrm__Is_Active__c != true) {
                current.celsrm__Is_Active__c = true;
                update current;
            }
            return current;
        }
        celsrm__User_Master__c userMaster = new celsrm__User_Master__c(
            celsrm__User__c = UserInfo.getUserId(),
            celsrm__Is_Active__c = true
        );
        insert userMaster;
        return userMaster;
    }

    private static celsrm__Credit_Limit_Approval_Matrix__c createApprovalMatrix(Id level1UserMasterId) {
        String payload = JSON.serialize(new List<Object>{
            new Map<String, Object>{
                'level' => 1,
                'approverType' => 'User',
                'approverUserIds' => new List<Object>{ level1UserMasterId },
                'isActive' => true,
                'isOptional' => false
            }
        });
        celsrm__Credit_Limit_Approval_Matrix__c matrix = new celsrm__Credit_Limit_Approval_Matrix__c(
            Name = 'CRAS Matrix',
            celsrm__Order__c = 1,
            celsrm__Is_Active__c = true,
            celsrm__Criteria__c = JSON.serialize(new Map<String, Object>{
                'criteriaCondition' => '',
                'criteria' => new List<Object>()
            }),
            celsrm__Approval_Matrices__c = payload
        );
        insert matrix;
        return matrix;
    }
}