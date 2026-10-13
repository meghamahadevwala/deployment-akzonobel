@IsTest
private class SendEmailForCreditReviewToOwnerTest {
    private static Integer seed = 0;

    private static celsrm__Credit_Review__c createCreditReview() {
        seed++;
        Account acc = new Account(Name = 'SECRTO Test Account ' + seed + ' ' + DateTime.now().getTime());
        insert acc;
        celsrm__Credit_Review__c review = new celsrm__Credit_Review__c(
            celsrm__Account__c = acc.Id,
            celsrm__Status__c = 'Pending',
            celsrm__Requested_Credit_Limit__c = 700,
            celsrm__Requested_Credit_Limit_Group_Currency__c = 700
        );
        insert review;
        return review;
    }

    @IsTest
    static void testRun_ReturnsFailedForMissingReview() {
        SendEmailForCreditReviewToOwner.Request req = new SendEmailForCreditReviewToOwner.Request();
        req.creditReviewId = 'a0Y000000000000AAA';
        req.templateUniqueName = 'NON_EXISTENT_TEMPLATE';
        req.fromAddress = 'missing@example.com';
        req.defaultFromAddress = 'missing@example.com';

        Test.startTest();
        List<SendEmailForCreditReviewToOwner.Response> responses =
            SendEmailForCreditReviewToOwner.run(new List<SendEmailForCreditReviewToOwner.Request>{ req });
        Test.stopTest();

        System.assertEquals(1, responses.size());
        System.assertEquals(req.creditReviewId, responses[0].creditReviewId);
        System.assert(responses[0].status != null && responses[0].status.startsWith('Failed:'));
    }

    @IsTest
    static void testRun_ReturnsFailedForMissingTemplateAfterValidReview() {
        celsrm__Credit_Review__c review = createCreditReview();

        SendEmailForCreditReviewToOwner.Request req = new SendEmailForCreditReviewToOwner.Request();
        req.creditReviewId = review.Id;
        req.templateUniqueName = 'NON_EXISTENT_TEMPLATE_' + String.valueOf(DateTime.now().getTime());
        req.fromAddress = null;
        req.defaultFromAddress = 'missing@example.com';

        Test.startTest();
        List<SendEmailForCreditReviewToOwner.Response> responses =
            SendEmailForCreditReviewToOwner.run(new List<SendEmailForCreditReviewToOwner.Request>{ req });
        Test.stopTest();

        System.assertEquals(1, responses.size());
        System.assertEquals(review.Id, responses[0].creditReviewId);
        System.assert(responses[0].status != null && responses[0].status.startsWith('Failed:'));
    }
}