@isTest
private class GetMoodysDataServiceTest {

    // ------------------------------------------------------------------
    // Helpers
    // ------------------------------------------------------------------

    private static Account buildAccount(String key, String bvdId, String checkRule, String creditGroup,
        String paymentBehaviour, String paymentTrend) {
        return new Account(
            celsrm__App_Name__c = 'Credit',
            Name = 'GMD Test Account ' + key,
            AccountNumber = 'ACC-' + key,
            CurrencyIsoCode = 'USD',
            BvD_ID_Number__c = bvdId,
            celsrm__Account_Key__c = key,
            Is_Snoozed__c = false,
            Calculated_Credit_Limit_Group_Currency__c = 60000,
            Recommended_Credit_Limit__c = 60000,
            Moody_s_Credit_Limit__c = 0,
            celsrm__Credit_Limit__c = 50000,
            celsrm__Check_Rule__c = checkRule,
            celsrm__Risk_Class__c = '3 - Low Risk',
            celsrm__Credit_Group__c = creditGroup,
            celsrm__Credit_Control_Area__c = 'AKZO',
            celsrm__Limit_Valid_To_Date__c = Date.today().addDays(10),
            Moody_s_Change_Identified__c = true,
            celsrm__Payment_Behaviour_Text__c = paymentBehaviour,
            celsrm__Payment_Behaviour_Trend__c = paymentTrend,
            Expected_Turnover__c = 100000,
            Credit_Exposure__c = 0,
            Payment_Term_Days__c = 30,
            Region__c = 'EMEA'
        );
    }

    // Ensures a fresh, non-expired Moody's token so GetMoodysDataService does not
    // need to make an additional (unmocked) auth callout during tests.
    // NOTE: this assumes creditParamsHttpCalloutManager.getMoodysAccessToken() re-uses
    // a recently generated token without calling out. Adjust if that's not the case.
    private static void setupMoodysAuth() {
        insert new Moody_s_Auth__c(
            Access_Token__c = 'test-access-token',
            Token_Generation_Time__c = System.now()
        );
    }

    private static void setupWebhookConfig(String webhookPath) {
        Credit_Configuration__c config = Credit_Configuration__c.getOrgDefaults();
        if (config.Id == null) {
            config = new Credit_Configuration__c();
        }
        config.Update_Profile_Data_Action_Flow_Webhook__c = webhookPath;
        upsert config;
    }

    private static HttpResponse buildCompaniesDataResponse(String bvdId, Map<String, Object> extraFields) {
        Map<String, Object> record = new Map<String, Object>{
            'NAME' => 'Test Co ' + bvdId,
            'BVD_ID_NUMBER' => bvdId,
            'STATUS' => new List<String>{ 'Active' },
            'STATUS_DATE' => new List<String>{ '2026-01-01T00:00:00' },
            'INCORPORATION_DATE' => '1990-01-01T00:00:00',
            'CAPI' => 1000000
        };
        record.putAll(extraFields);
        Map<String, Object> body = new Map<String, Object>{
            'Data' => new List<Object>{ record }
        };
        HttpResponse res = new HttpResponse();
        res.setBody(JSON.serialize(body));
        res.setStatusCode(200);
        return res;
    }

    private class MockHttpResponseGenerator implements HttpCalloutMock {
        private HttpResponse mockResponse;
        public MockHttpResponseGenerator(HttpResponse mockResponse) {
            this.mockResponse = mockResponse;
        }
        public HttpResponse respond(HttpRequest req) {
            return mockResponse;
        }
    }

    // ------------------------------------------------------------------
    // execute() — source precedence / mapping tests
    // ------------------------------------------------------------------

    @isTest
    static void testExecute_ReactiveScoreLowRisk() {
        setupMoodysAuth();
        Account acc = buildAccount('REACT01', 'BVD-REACT01', 'Z05 Risk Class High',
            '0003 - RCA - Regular Credit Account', 'On Time', null);
        insert acc;

        HttpResponse mockResponse = buildCompaniesDataResponse('BVD-REACT01', new Map<String, Object>{
            'REACMORRAT' => 'AAA',
            'REACMORE_DATE' => '2026-01-05T00:00:00',
            'REACMORCREDLIMIT' => 90000.0
        });
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(mockResponse));

        Test.startTest();
        System.enqueueJob(new GetMoodysDataService(new List<String>{ acc.Id }, false, false));
        Test.stopTest();

        Account updated = [SELECT Moody_s_Risk_Class__c, celsrm__Risk_Class__c, celsrm__Check_Rule__c,
            Moody_s_Credit_Limit__c FROM Account WHERE Id = :acc.Id];
        System.assertEquals('Low', updated.Moody_s_Risk_Class__c);
        System.assertEquals('3 - Low Risk', updated.celsrm__Risk_Class__c);
        System.assertEquals('Z03 Risk Class Low', updated.celsrm__Check_Rule__c);
        // REACMORCREDLIMIT (90000) * On Time multiplier (1.2) = 108000
        System.assertEquals(108000.0, updated.Moody_s_Credit_Limit__c);
    }

    @isTest
    static void testExecute_MoreScoreMediumRisk() {
        setupMoodysAuth();
        Account acc = buildAccount('MORE01', 'BVD-MORE01', 'Z05 Risk Class High',
            '0003 - RCA - Regular Credit Account', 'Late', 'Payment Behaviour Improved');
        insert acc;

        HttpResponse mockResponse = buildCompaniesDataResponse('BVD-MORE01', new Map<String, Object>{
            'MORRAT' => 'BBB',
            'MORE_YEAR' => '2026-02-01T00:00:00',
            'MORCREDLIMIT' => 80000.0
        });
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(mockResponse));

        Test.startTest();
        System.enqueueJob(new GetMoodysDataService(new List<String>{ acc.Id }, false, false));
        Test.stopTest();

        Account updated = [SELECT Moody_s_Risk_Class__c, celsrm__Risk_Class__c, celsrm__Check_Rule__c
            FROM Account WHERE Id = :acc.Id];
        System.assertEquals('Medium', updated.Moody_s_Risk_Class__c);
        System.assertEquals('4 - Medium Risk', updated.celsrm__Risk_Class__c);
        System.assertEquals('Z04 Risk Class Medium', updated.celsrm__Check_Rule__c);
    }

    // Baseline sanity check for ticket #836 issue 1: with ONLY a Qualitative score present
    // (no Reactive/MORE data competing for priority), "D" must map to High.
    @isTest
    static void testExecute_QualitativeScoreD_HighRisk() {
        setupMoodysAuth();
        Account acc = buildAccount('QUAL01', 'BVD-QUAL01', 'Z05 Risk Class High',
            '0003 - RCA - Regular Credit Account', 'Very Late', 'Payment Behaviour Improved');
        insert acc;

        HttpResponse mockResponse = buildCompaniesDataResponse('BVD-QUAL01', new Map<String, Object>{
            'MODEFINNF' => 'D',
            'MODEFINNFDATE' => '2026-01-05T00:00:00',
            'MODEFINNF_CreditLimitValue' => 55000.0
        });
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(mockResponse));

        Test.startTest();
        System.enqueueJob(new GetMoodysDataService(new List<String>{ acc.Id }, false, false));
        Test.stopTest();

        Account updated = [SELECT Moody_s_Risk_Class__c, celsrm__Risk_Class__c, celsrm__Check_Rule__c
            FROM Account WHERE Id = :acc.Id];
        System.assertEquals('High', updated.Moody_s_Risk_Class__c);
        System.assertEquals('5 - High Risk', updated.celsrm__Risk_Class__c);
        System.assertEquals('Z05 Risk Class High', updated.celsrm__Check_Rule__c);
    }

    // Ticket #916: Qualitative "E" must now map to "Direct Block" internally, while
    // the CFIN-facing fields (celsrm__Risk_Class__c / celsrm__Check_Rule__c) must be
    // the same as High Risk (5 / Z05), NOT Full Credit Block (6 / Z06).
    // REQUIRES the mapping fix described above to be applied to GetMoodysDataService.
    @isTest
    static void testExecute_QualitativeScoreE_MapsToDirectBlock_916() {
        setupMoodysAuth();
        Account acc = buildAccount('QUAL02', 'BVD-QUAL02', 'Z05 Risk Class High',
            '0003 - RCA - Regular Credit Account', 'Late', 'Payment Behaviour Declined');
        insert acc;

        HttpResponse mockResponse = buildCompaniesDataResponse('BVD-QUAL02', new Map<String, Object>{
            'MODEFINNF' => 'E',
            'MODEFINNFDATE' => '2026-01-05T00:00:00',
            'MODEFINNF_CreditLimitValue' => 55000.0
        });
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(mockResponse));

        Test.startTest();
        System.enqueueJob(new GetMoodysDataService(new List<String>{ acc.Id }, false, false));
        Test.stopTest();

        Account updated = [SELECT Moody_s_Risk_Class__c, celsrm__Risk_Class__c, celsrm__Check_Rule__c
            FROM Account WHERE Id = :acc.Id];
        System.assertEquals('Direct Block', updated.Moody_s_Risk_Class__c,
            'Moody_s_Risk_Class__c should reflect the new internal classification.');
        System.assertEquals('5 - High Risk', updated.celsrm__Risk_Class__c,
            'CFIN-facing risk class must be High Risk, not Full Credit Block.');
        System.assertEquals('Z09 Risk Class Direct Block', updated.celsrm__Check_Rule__c,
            'CFIN-facing check rule must be Z09 (Direct Block), not Z05 or Z06.');
    }

    // No matching BvD data returned -> Moody_s_Change_Identified__c should flip to false
    // and the account should still be updated (but risk/limit fields untouched).
    @isTest
    static void testExecute_NoScoreData_ResetsChangeIdentifiedFlag() {
        setupMoodysAuth();
        Account acc = buildAccount('NODATA01', 'BVD-NODATA01', 'Z05 Risk Class High',
            '0003 - RCA - Regular Credit Account', 'On Time', null);
        acc.Moody_s_Change_Identified__c = true;
        insert acc;

        // The record matches the account's BvD ID (so the per-account loop actually runs)
        // but has NO score fields at all, so accountCreditLimit/accountRiskClass stay null
        // and the code falls into the "else if(Moody_s_Change_Identified__c == true)" reset branch.
        // An empty "Data":[] array would NOT exercise this branch, since the per-account loop
        // never runs at all in that case.
        HttpResponse mockResponse = new HttpResponse();
        mockResponse.setBody('{"Data":[{"NAME":"No Data Co","BVD_ID_NUMBER":"BVD-NODATA01"}]}');
        mockResponse.setStatusCode(200);
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(mockResponse));

        Test.startTest();
        System.enqueueJob(new GetMoodysDataService(new List<String>{ acc.Id }, false, false));
        Test.stopTest();

        Account updated = [SELECT Moody_s_Change_Identified__c FROM Account WHERE Id = :acc.Id];
        System.assertEquals(false, updated.Moody_s_Change_Identified__c);
    }

    // allowCreateCr = true: a Credit Review should be created and auto-approved
    // when Requested_Credit_Limit_EUR__c (via Recommended_Credit_Limit__c) is <= 50000.
    @isTest
    static void testExecute_AllowCreateCr_LowLimit_AutoApproved() {
        setupMoodysAuth();
        Account acc = buildAccount('CR01', 'BVD-CR01', 'Z05 Risk Class High',
            '0003 - RCA - Regular Credit Account', 'On Time', null);
        acc.Recommended_Credit_Limit__c = 20000;
        acc.Calculated_Credit_Limit_Group_Currency__c = 20000;
        insert acc;

        HttpResponse mockResponse = buildCompaniesDataResponse('BVD-CR01', new Map<String, Object>{
            'MORRAT' => 'A',
            'MORE_YEAR' => '2026-01-05T00:00:00',
            'MORCREDLIMIT' => 25000.0
        });
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(mockResponse));

        Test.startTest();
        System.enqueueJob(new GetMoodysDataService(new List<String>{ acc.Id }, true, false));
        Test.stopTest();

        List<celsrm__Credit_Review__c> reviews = [SELECT Id, celsrm__Status__c, celsrm__Model_Type__c
            FROM celsrm__Credit_Review__c WHERE celsrm__Account__c = :acc.Id];
        System.assertEquals(1, reviews.size());
        System.assertEquals('11', reviews[0].celsrm__Status__c);
        System.assertEquals('Recalculation', reviews[0].celsrm__Model_Type__c);
    }

    // allowCreateCr = true + isPeriodic = true -> model type must be 'Periodic Review'.
    @isTest
    static void testExecute_AllowCreateCr_Periodic_ModelType() {
        setupMoodysAuth();
        Account acc = buildAccount('CR02', 'BVD-CR02', 'Z05 Risk Class High',
            '0003 - RCA - Regular Credit Account', 'On Time', null);
        acc.Recommended_Credit_Limit__c = 20000;
        acc.Calculated_Credit_Limit_Group_Currency__c = 20000;
        insert acc;

        HttpResponse mockResponse = buildCompaniesDataResponse('BVD-CR02', new Map<String, Object>{
            'MORRAT' => 'A',
            'MORE_YEAR' => '2026-01-05T00:00:00',
            'MORCREDLIMIT' => 25000.0
        });
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(mockResponse));

        Test.startTest();
        System.enqueueJob(new GetMoodysDataService(new List<String>{ acc.Id }, true, true));
        Test.stopTest();

        List<celsrm__Credit_Review__c> reviews = [SELECT celsrm__Model_Type__c
            FROM celsrm__Credit_Review__c WHERE celsrm__Account__c = :acc.Id];
        System.assertEquals(1, reviews.size());
        System.assertEquals('Periodic Review', reviews[0].celsrm__Model_Type__c);
    }

    // allowCreateCr = false -> no Credit Review should be created.
    @isTest
    static void testExecute_AllowCreateCr_False_NoReviewCreated() {
        setupMoodysAuth();
        Account acc = buildAccount('CR03', 'BVD-CR03', 'Z05 Risk Class High',
            '0003 - RCA - Regular Credit Account', 'On Time', null);
        insert acc;

        HttpResponse mockResponse = buildCompaniesDataResponse('BVD-CR03', new Map<String, Object>{
            'MORRAT' => 'A',
            'MORE_YEAR' => '2026-01-05T00:00:00',
            'MORCREDLIMIT' => 25000.0
        });
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(mockResponse));

        Test.startTest();
        System.enqueueJob(new GetMoodysDataService(new List<String>{ acc.Id }, false, false));
        Test.stopTest();

        List<celsrm__Credit_Review__c> reviews = [SELECT Id FROM celsrm__Credit_Review__c
            WHERE celsrm__Account__c = :acc.Id];
        System.assertEquals(0, reviews.size());
    }

    // Static wrapper coverage.
    @isTest
    static void testGetMoodysDataStaticEnqueuesJob() {
        setupMoodysAuth();
        Account acc = buildAccount('STATIC01', 'BVD-STATIC01', 'Z05 Risk Class High',
            '0003 - RCA - Regular Credit Account', 'On Time', null);
        insert acc;

        HttpResponse mockResponse = new HttpResponse();
        mockResponse.setBody('{"Data":[]}');
        mockResponse.setStatusCode(200);
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(mockResponse));

        Test.startTest();
        GetMoodysDataService.GetMoodysData(new List<String>{ acc.Id }, false, false);
        Test.stopTest();

        // No exception thrown means the job was enqueued and executed successfully.
        System.assertEquals(1, [SELECT COUNT() FROM Account WHERE Id = :acc.Id]);
    }

    // ------------------------------------------------------------------
    // updateProfileData() — CFIN webhook response handling (@TestVisible)
    // ------------------------------------------------------------------

    @isTest
    static void testUpdateProfileData_SuccessResponse() {
        Account acc = buildAccount('UPD01', 'BVD-UPD01', 'Z05 Risk Class High',
            '0003 - RCA - Regular Credit Account', 'On Time', null);
        acc.celsrm__Risk_Class__c = '5 - High Risk';
        insert acc;
        setupWebhookConfig('test/webhook');

        String responseBody = '{"status":"Error","details":{"updateResponse":[' +
            '{"PARTNER":"' + acc.AccountNumber + '","CHECK_RULE":"Z05","CREDIT_GROUP":"0003",' +
            '"RISK_CLASS":"5","STATUS_MSG":"Update successful"}]}}';
        HttpResponse mockResponse = new HttpResponse();
        mockResponse.setBody(responseBody);
        mockResponse.setStatusCode(200);
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(mockResponse));

        GetMoodysDataService service = new GetMoodysDataService(new List<String>{ acc.Id }, false, false);
        Test.startTest();
        service.updateProfileData(new List<Account>{ acc });
        Test.stopTest();

        Account updated = [SELECT Sync_Profile_Data_Message__c, Sync_Profile_Data_In_Source_System_At__c
            FROM Account WHERE Id = :acc.Id];
        System.assertEquals('Update successful', updated.Sync_Profile_Data_Message__c);
        System.assertNotEquals(null, updated.Sync_Profile_Data_In_Source_System_At__c);
    }

    @isTest
    static void testUpdateProfileData_UnmatchedResponse() {
        Account acc = buildAccount('UPD02', 'BVD-UPD02', 'Z05 Risk Class High',
            '0003 - RCA - Regular Credit Account', 'On Time', null);
        insert acc;
        setupWebhookConfig('test/webhook');

        // Response references a different PARTNER/key -> account key gets no match.
        String responseBody = '{"status":"Error","details":{"updateResponse":[' +
            '{"PARTNER":"OTHER-ACCOUNT","CHECK_RULE":"Z04","CREDIT_GROUP":"0003",' +
            '"RISK_CLASS":"4","STATUS_MSG":"Update successful"}]}}';
        HttpResponse mockResponse = new HttpResponse();
        mockResponse.setBody(responseBody);
        mockResponse.setStatusCode(200);
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(mockResponse));

        GetMoodysDataService service = new GetMoodysDataService(new List<String>{ acc.Id }, false, false);
        Test.startTest();
        service.updateProfileData(new List<Account>{ acc });
        Test.stopTest();

        Account updated = [SELECT Sync_Profile_Data_Message__c FROM Account WHERE Id = :acc.Id];
        System.assertEquals('Failed to update in CFIN. Error: RFC Module Failed', updated.Sync_Profile_Data_Message__c);
    }

    @isTest
    static void testUpdateProfileData_AcceptedResponse() {
        Account acc = buildAccount('UPD03', 'BVD-UPD03', 'Z05 Risk Class High',
            '0003 - RCA - Regular Credit Account', 'On Time', null);
        insert acc;
        setupWebhookConfig('test/webhook');

        HttpResponse mockResponse = new HttpResponse();
        mockResponse.setBody('Accepted');
        mockResponse.setStatusCode(200);
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(mockResponse));

        GetMoodysDataService service = new GetMoodysDataService(new List<String>{ acc.Id }, false, false);
        Test.startTest();
        service.updateProfileData(new List<Account>{ acc });
        Test.stopTest();

        Account updated = [SELECT Sync_Profile_Data_Message__c FROM Account WHERE Id = :acc.Id];
        System.assert(updated.Sync_Profile_Data_Message__c.contains('Something went wrong'));
    }

    @isTest
    static void testUpdateProfileData_UnauthorizedResponse() {
        Account acc = buildAccount('UPD04', 'BVD-UPD04', 'Z05 Risk Class High',
            '0003 - RCA - Regular Credit Account', 'On Time', null);
        insert acc;
        setupWebhookConfig('test/webhook');

        HttpResponse mockResponse = new HttpResponse();
        mockResponse.setBody('{"status":"Error","details":"Invalid authentication token"}');
        mockResponse.setStatusCode(401);
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(mockResponse));

        GetMoodysDataService service = new GetMoodysDataService(new List<String>{ acc.Id }, false, false);
        Test.startTest();
        service.updateProfileData(new List<Account>{ acc });
        Test.stopTest();

        Account updated = [SELECT Sync_Profile_Data_Message__c FROM Account WHERE Id = :acc.Id];
        System.assert(updated.Sync_Profile_Data_Message__c.startsWith('Failed to update in CFIN. Error:'));
    }

    @isTest
    static void testUpdateProfileData_InternalServerErrorResponse() {
        Account acc = buildAccount('UPD05', 'BVD-UPD05', 'Z05 Risk Class High',
            '0003 - RCA - Regular Credit Account', 'On Time', null);
        insert acc;
        setupWebhookConfig('test/webhook');

        HttpResponse mockResponse = new HttpResponse();
        mockResponse.setBody('Internal Server Error');
        mockResponse.setStatusCode(500);
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(mockResponse));

        GetMoodysDataService service = new GetMoodysDataService(new List<String>{ acc.Id }, false, false);
        Test.startTest();
        service.updateProfileData(new List<Account>{ acc });
        Test.stopTest();

        Account updated = [SELECT Sync_Profile_Data_Message__c FROM Account WHERE Id = :acc.Id];
        System.assertEquals('Failed to update in CFIN. Error: Internal Server Error', updated.Sync_Profile_Data_Message__c);
    }

    @isTest
    static void testUpdateProfileData_RateLimitResponse() {
        Account acc = buildAccount('UPD06', 'BVD-UPD06', 'Z05 Risk Class High',
            '0003 - RCA - Regular Credit Account', 'On Time', null);
        insert acc;
        setupWebhookConfig('test/webhook');

        HttpResponse mockResponse = new HttpResponse();
        mockResponse.setBody('Too Many Requests');
        mockResponse.setStatusCode(429);
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(mockResponse));

        GetMoodysDataService service = new GetMoodysDataService(new List<String>{ acc.Id }, false, false);
        Test.startTest();
        service.updateProfileData(new List<Account>{ acc });
        Test.stopTest();

        Account updated = [SELECT Sync_Profile_Data_Message__c FROM Account WHERE Id = :acc.Id];
        System.assertEquals('Failed to update in CFIN. Error: Webhook rate limit', updated.Sync_Profile_Data_Message__c);
    }

    @isTest
    static void testUpdateProfileData_UnexpectedStatusCode() {
        Account acc = buildAccount('UPD07', 'BVD-UPD07', 'Z05 Risk Class High',
            '0003 - RCA - Regular Credit Account', 'On Time', null);
        insert acc;
        setupWebhookConfig('test/webhook');

        HttpResponse mockResponse = new HttpResponse();
        mockResponse.setBody('Not Found');
        mockResponse.setStatusCode(404);
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(mockResponse));

        GetMoodysDataService service = new GetMoodysDataService(new List<String>{ acc.Id }, false, false);
        Test.startTest();
        service.updateProfileData(new List<Account>{ acc });
        Test.stopTest();

        Account updated = [SELECT Sync_Profile_Data_Message__c FROM Account WHERE Id = :acc.Id];
        System.assertEquals('Failed to update in CFIN. Error: 404', updated.Sync_Profile_Data_Message__c);
    }

    @isTest
    static void testUpdateProfileData_ExceptionOnMalformedJson() {
        Account acc = buildAccount('UPD08', 'BVD-UPD08', 'Z05 Risk Class High',
            '0003 - RCA - Regular Credit Account', 'On Time', null);
        insert acc;
        setupWebhookConfig('test/webhook');

        // 200 status but body is not valid JSON -> triggers the catch(Exception) branch.
        HttpResponse mockResponse = new HttpResponse();
        mockResponse.setBody('{not-valid-json');
        mockResponse.setStatusCode(200);
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(mockResponse));

        GetMoodysDataService service = new GetMoodysDataService(new List<String>{ acc.Id }, false, false);
        Test.startTest();
        service.updateProfileData(new List<Account>{ acc });
        Test.stopTest();

        Account updated = [SELECT Sync_Profile_Data_Message__c FROM Account WHERE Id = :acc.Id];
        System.assert(updated.Sync_Profile_Data_Message__c.startsWith('Failed to update in CFIN. Exception occured:'));
    }

    @isTest
    static void testUpdateProfileData_WebhookNotConfigured() {
        Account acc = buildAccount('UPD09', 'BVD-UPD09', 'Z05 Risk Class High',
            '0003 - RCA - Regular Credit Account', 'On Time', null);
        insert acc;
        // Intentionally not calling setupWebhookConfig -> URL stays blank.

        GetMoodysDataService service = new GetMoodysDataService(new List<String>{ acc.Id }, false, false);
        Test.startTest();
        service.updateProfileData(new List<Account>{ acc });
        Test.stopTest();

        Account updated = [SELECT Sync_Profile_Data_Message__c FROM Account WHERE Id = :acc.Id];
        System.assertEquals('Failed to update in CFIN. Error: Webhook URL is not configured',
            updated.Sync_Profile_Data_Message__c);
    }
}