@IsTest
private class SendEmailForCreditReviewAssignToTest {
    private static Integer seed = 0;

    private static celsrm__User_Master__c createCurrentUserMaster() {
        List<celsrm__User_Master__c> existingRows = [
            SELECT Id, celsrm__Is_Active__c
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

        celsrm__User_Master__c created = new celsrm__User_Master__c(
            celsrm__User__c = UserInfo.getUserId(),
            celsrm__Is_Active__c = true
        );
        insert created;
        return created;
    }

    private static celsrm__Credit_Review__c createCreditReview() {
        seed++;
        Account acc = new Account(Name = 'SECRA Test Account ' + seed + ' ' + DateTime.now().getTime());
        insert acc;
        celsrm__Credit_Review__c review = new celsrm__Credit_Review__c(
            celsrm__Account__c = acc.Id,
            celsrm__Status__c = 'Pending',
            celsrm__Requested_Credit_Limit__c = 500,
            celsrm__Requested_Credit_Limit_Group_Currency__c = 500
        );
        insert review;
        return review;
    }

    @IsTest
    static void testRun_ReturnsFailedForMissingDetail() {
        SendEmailForCreditReviewAssignTo.Request req = new SendEmailForCreditReviewAssignTo.Request();
        req.creditLimitApprovalDetailId = 'a0Z000000000000AAA';
        req.templateUniqueName = 'NON_EXISTENT_TEMPLATE';
        req.fromAddress = 'missing@example.com';
        req.defaultFromAddress = 'missing@example.com';

        Test.startTest();
        List<SendEmailForCreditReviewAssignTo.Response> responses =
            SendEmailForCreditReviewAssignTo.run(new List<SendEmailForCreditReviewAssignTo.Request>{ req });
        Test.stopTest();

        System.assertEquals(1, responses.size());
        System.assertEquals(req.creditLimitApprovalDetailId, responses[0].creditLimitApprovalDetailId);
        System.assert(responses[0].status != null && responses[0].status.startsWith('Failed:'));
    }

    @IsTest
    static void testRun_ReturnsFailedForMissingTemplateAfterValidDetail() {
        celsrm__User_Master__c userMaster = createCurrentUserMaster();
        celsrm__Credit_Review__c review = createCreditReview();
        celsrm__Credit_Limit_Approval_Detail__c detail = new celsrm__Credit_Limit_Approval_Detail__c(
            celsrm__Credit_Review__c = review.Id,
            celsrm__User_Master__c = userMaster.Id,
            celsrm__Status__c = 'Pending',
            celsrm__Level__c = 1
        );
        insert detail;

        SendEmailForCreditReviewAssignTo.Request req = new SendEmailForCreditReviewAssignTo.Request();
        req.creditLimitApprovalDetailId = detail.Id;
        req.templateUniqueName = 'NON_EXISTENT_TEMPLATE_' + String.valueOf(DateTime.now().getTime());
        req.fromAddress = null;
        req.defaultFromAddress = 'missing@example.com';

        Test.startTest();
        List<SendEmailForCreditReviewAssignTo.Response> responses =
            SendEmailForCreditReviewAssignTo.run(new List<SendEmailForCreditReviewAssignTo.Request>{ req });
        Test.stopTest();

        System.assertEquals(1, responses.size());
        System.assertEquals(detail.Id, responses[0].creditLimitApprovalDetailId);
        System.assert(responses[0].status != null && responses[0].status.startsWith('Failed:'));
    }
}