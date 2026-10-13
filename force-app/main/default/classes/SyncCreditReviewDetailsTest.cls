@isTest
public class SyncCreditReviewDetailsTest {

    private static RestResponse setupRestContext(String jsonBody) {
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/SyncCreditReviewDetails';
        req.httpMethod = 'POST';
        if (jsonBody != null) {
            req.requestBody = Blob.valueOf(jsonBody);
        }
        RestResponse res = new RestResponse();
        RestContext.request = req;
        RestContext.response = res;
        return res;
    }

    @isTest
    static void testMissingExternalUuid() {
        Map<String, Object> body = new Map<String, Object>{ 'statusCode' => 24 };
        RestResponse res = setupRestContext(JSON.serialize(body));

        Test.startTest();
        SyncCreditReviewDetails.syncCreditReviews();
        Test.stopTest();

        System.assertEquals(400, res.statusCode);
        System.assertEquals('externalUuid is missing!', res.responseBody.toString());
    }

    @isTest
    static void testInvalidExternalUuidFormat() {
        Map<String, Object> body = new Map<String, Object>{
            'externalUuid' => 'not-a-valid-id',
            'statusCode' => 24
        };
        RestResponse res = setupRestContext(JSON.serialize(body));

        Test.startTest();
        SyncCreditReviewDetails.syncCreditReviews();
        Test.stopTest();

        // Casting an invalid string to Id throws, which is caught and reported as a 500.
        System.assertEquals(500, res.statusCode);
    }

    @isTest
    static void testMissingStatusCode() {
        Account acc = CreditDataGenerator.insertAccount();
        celsrm__Credit_Review__c cr = CreditDataGenerator.insertCreditReview(acc);

        Map<String, Object> body = new Map<String, Object>{ 'externalUuid' => cr.Id };
        RestResponse res = setupRestContext(JSON.serialize(body));

        Test.startTest();
        SyncCreditReviewDetails.syncCreditReviews();
        Test.stopTest();

        System.assertEquals(400, res.statusCode);
        System.assertEquals('statusCode is null or emplty!', res.responseBody.toString());
    }

    @isTest
    static void testApprovedStatusUpdatesReview() {
        Account acc = CreditDataGenerator.insertAccount();
        celsrm__Credit_Review__c cr = CreditDataGenerator.insertCreditReview(acc);
        cr.App_App_Notes__c = 'Old note';
        update cr;

        Map<String, Object> body = new Map<String, Object>{
            'externalUuid' => cr.Id,
            'externalCaseId' => 'CASE-001',
            'attachments' => 'file1.pdf',
            'notes' => '#New note line 1#New note line 2#',
            'statusCode' => 24,
            'approvedCreditLimit' => 5000.0,
            'requestedValidToDate' => '2026-12-31 00:00:00',
            'SYSTEM_NAME' => 'SAP'
        };
        RestResponse res = setupRestContext(JSON.serialize(body));

        Test.startTest();
        SyncCreditReviewDetails.syncCreditReviews();
        Test.stopTest();

        System.assertEquals(200, res.statusCode);
        System.assertEquals('Credit Reviews updated successfully', res.responseBody.toString());

        celsrm__Credit_Review__c updated = [
            SELECT celsrm__Status__c, Attachments__c, App_App_Notes__c, celsrm__Approved_Credit_Limit__c,
                   Credit_Approved_Date__c, Approved_Valid_To_Date__c
            FROM celsrm__Credit_Review__c
            WHERE Id = :cr.Id
        ];
        System.assertEquals('40', updated.celsrm__Status__c, 'statusCode 24 should map to status 40');
        System.assertEquals('file1.pdf', updated.Attachments__c);
        System.assertEquals(5000.0, updated.celsrm__Approved_Credit_Limit__c);
        System.assertEquals(Date.today(), updated.Credit_Approved_Date__c);
        System.assertEquals(Date.newInstance(2026, 12, 31), updated.Approved_Valid_To_Date__c);
        System.assert(updated.App_App_Notes__c.contains('New note line 1'), 'Latest note should be prepended');
        System.assert(updated.App_App_Notes__c.contains('New note line 2'), 'Latest note should be prepended');
        System.assert(updated.App_App_Notes__c.contains('Old note'), 'Previous note should be retained');
    }

    @isTest
    static void testNonApprovedStatusPassThrough() {
        Account acc = CreditDataGenerator.insertAccount();
        celsrm__Credit_Review__c cr = CreditDataGenerator.insertCreditReview(acc);

        Map<String, Object> body = new Map<String, Object>{
            'externalUuid' => cr.Id,
            'attachments' => '',
            'statusCode' => 15
        };
        RestResponse res = setupRestContext(JSON.serialize(body));

        Test.startTest();
        SyncCreditReviewDetails.syncCreditReviews();
        Test.stopTest();

        System.assertEquals(200, res.statusCode);

        celsrm__Credit_Review__c updated = [
            SELECT celsrm__Status__c, Attachments__c, Credit_Approved_Date__c
            FROM celsrm__Credit_Review__c
            WHERE Id = :cr.Id
        ];
        System.assertEquals('15', updated.celsrm__Status__c);
        System.assertEquals(null, updated.Attachments__c, 'Empty string attachments should be stored as null');
        System.assertEquals(null, updated.Credit_Approved_Date__c, 'Non-approved status should not set the approved date');
    }
}