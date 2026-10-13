@isTest
public class CreditReviewGeneratorTest {
    @testSetup
    static void setupData() {
        //For Credit Limit Zero Case
        Account acc1 = new Account(
            // << CHANGE - MM - FIN-9701 - Test Class Coverage | Added celsrm__App_Name__c value >>
            celsrm__App_Name__c = 'Credit',
            Name = 'Test Account 1', 
            CurrencyIsoCode = 'EUR', 
            BvD_ID_Number__c = '67832', 
            celsrm__Account_Key__c = '1111',
            Is_Snoozed__c = false,
            Calculated_Credit_Limit_Group_Currency__c = 0,
            Recommended_Credit_Limit__c  = 0,
            Moody_s_Credit_Limit__c  = null,
            celsrm__Credit_Limit__c = 1000,
            celsrm__Total_AR__c = 0,
            celsrm__Total_Past_Due__c = 0,
            Total_Order_Value__c = 0,
            Open_Billing_Value__c = 0,
            Open_Delivery_Value__c = 0,
            Invoice_in_Last_12_Months__c = 0,
            celsrm__Check_Rule__c = 'Z05 Risk Class High',
            celsrm__Credit_Group__c = '0003 - RCA - Regular Credit Account',
            celsrm__Limit_Valid_To_Date__c = Date.today().addDays(10)
        );

        //For Credit Limit <= 20K EUR
        Account acc2 = new Account(
            // << CHANGE - MM - FIN-9701 - Test Class Coverage | Added celsrm__App_Name__c value >>
            celsrm__App_Name__c = 'Credit',
            Name = 'Test Account 2', 
            CurrencyIsoCode = 'EUR', 
            BvD_ID_Number__c = '67832', 
            celsrm__Account_Key__c = '2222',
            Is_Snoozed__c = false,
            Calculated_Credit_Limit_Group_Currency__c = 19000,
            Recommended_Credit_Limit__c  = 19000,
            Moody_s_Credit_Limit__c  = null,
            celsrm__Credit_Limit__c = 18000,
            celsrm__Check_Rule__c = 'Z05 Risk Class High',
            celsrm__Credit_Group__c = '0003 - RCA - Regular Credit Account',
            celsrm__Limit_Valid_To_Date__c = Date.today().addDays(10),
            Moody_s_Change_Identified__c = false,
            celsrm__Payment_Behaviour_Text__c = 'Very Late',
            celsrm__Payment_Behaviour_Trend__c = 'Payment Behaviour Declined'
        );

        //For Credit Limit > 20K EUR
        Account acc3 = new Account(
            // << CHANGE - MM - FIN-9701 - Test Class Coverage | Added celsrm__App_Name__c value >>
            celsrm__App_Name__c = 'Credit',
            Name = 'Test Account 3', 
            CurrencyIsoCode = 'EUR', 
            BvD_ID_Number__c = '67832', 
            celsrm__Account_Key__c = '3333',
            Is_Snoozed__c = false,
            Calculated_Credit_Limit_Group_Currency__c = 51000,
            Recommended_Credit_Limit__c  = 51000,
            Moody_s_Credit_Limit__c  = 53000,
            celsrm__Credit_Limit__c = 20500,
            celsrm__Check_Rule__c = 'Z05 Risk Class High',
            celsrm__Credit_Group__c = '0003 - RCA - Regular Credit Account',
            celsrm__Limit_Valid_To_Date__c = Date.today().addDays(10),
            Moody_s_Change_Identified__c = false,
            celsrm__Payment_Behaviour_Text__c = 'Very Late',
            celsrm__Payment_Behaviour_Trend__c = 'Payment Behaviour Declined'
        );
        
        
        //For Manual case
        Account acc4 = new Account(
            // << CHANGE - MM - FIN-9701 - Test Class Coverage | Added celsrm__App_Name__c value >>
            celsrm__App_Name__c = 'Credit',
            Name = 'Test Account 4', 
            CurrencyIsoCode = 'USD',
            BvD_ID_Number__c = '12345', 
            celsrm__Account_Key__c = '4444',
            Is_Snoozed__c = false,
            Calculated_Credit_Limit_Group_Currency__c = 54000,
            Recommended_Credit_Limit__c  = 54000,
            Moody_s_Credit_Limit__c  = 53000,
            celsrm__Credit_Limit__c = 22000,
            celsrm__Check_Rule__c = 'Z05 Risk Class High',
            celsrm__Credit_Group__c = '0003 - RCA - Regular Credit Account',
            celsrm__Limit_Valid_To_Date__c = Date.today().addDays(10),
            Moody_s_Change_Identified__c = true,
            celsrm__Payment_Behaviour_Text__c = 'Late',
            celsrm__Payment_Behaviour_Trend__c = 'Payment Behaviour Declined' 
        );
        //For Manual case
        Account acc5 = new Account(
            // << CHANGE - MM - FIN-9701 - Test Class Coverage | Added celsrm__App_Name__c value >>
            celsrm__App_Name__c = 'Credit',
            Name = 'Test Account 5', 
            CurrencyIsoCode = 'EUR', 
            BvD_ID_Number__c = '67890', 
            celsrm__Account_Key__c = '5555',
            Is_Snoozed__c = false,
            Calculated_Credit_Limit_Group_Currency__c = 54000,
            Recommended_Credit_Limit__c  = 54000,
            Moody_s_Credit_Limit__c  = 53000,
            celsrm__Credit_Limit__c = 22000,
            celsrm__Check_Rule__c = 'Z05 Risk Class High',
            celsrm__Credit_Group__c = '0003 - RCA - Regular Credit Account',
            celsrm__Limit_Valid_To_Date__c = Date.today().addDays(10),
            Moody_s_Change_Identified__c = false,
            celsrm__Payment_Behaviour_Text__c = 'Very Late',
            celsrm__Payment_Behaviour_Trend__c = 'Payment Behaviour Declined'
        );
        //For Manual case
        Account acc6 = new Account(
            // << CHANGE - MM - FIN-9701 - Test Class Coverage | Added celsrm__App_Name__c value >>
            celsrm__App_Name__c = 'Credit',
            Name = 'Test Account 6', 
            CurrencyIsoCode = 'EUR', 
            BvD_ID_Number__c = '67832', 
            celsrm__Account_Key__c = '6666',
            Is_Snoozed__c = false,
            Calculated_Credit_Limit_Group_Currency__c = 54000,
            Recommended_Credit_Limit__c  = 54000,
            Moody_s_Credit_Limit__c  = 53000,
            celsrm__Credit_Limit__c = 22000,
            celsrm__Check_Rule__c = 'Z05 Risk Class High',
            celsrm__Credit_Group__c = '0003 - RCA - Regular Credit Account',
            celsrm__Limit_Valid_To_Date__c = Date.today().addDays(10),
            Moody_s_Change_Identified__c = false,
            celsrm__Payment_Behaviour_Text__c = 'Very Late',
            celsrm__Payment_Behaviour_Trend__c = 'Payment Behaviour Declined'
        );

        // << START - MM - FIN-9701 - Test Class Coverage for Credit App >>
        // For Manual case - BVD ID null
        Account acc7 = new Account(
            // << CHANGE - MM - FIN-9701 - Test Class Coverage | Added celsrm__App_Name__c value >>
            celsrm__App_Name__c = 'Credit',
            Name = 'Test Account 6', 
            CurrencyIsoCode = 'EUR', 
            BvD_ID_Number__c = null, 
            celsrm__Account_Key__c = '7777',
            Is_Snoozed__c = false,
            Calculated_Credit_Limit_Group_Currency__c = 54000,
            Recommended_Credit_Limit__c  = 54000,
            Moody_s_Credit_Limit__c  = 53000,
            celsrm__Credit_Limit__c = 22000,
            celsrm__Check_Rule__c = 'Z05 Risk Class High',
            celsrm__Credit_Group__c = '0003 - RCA - Regular Credit Account',
            celsrm__Limit_Valid_To_Date__c = Date.today().addDays(10),
            Moody_s_Change_Identified__c = false,
            celsrm__Payment_Behaviour_Text__c = 'Very Late',
            celsrm__Payment_Behaviour_Trend__c = 'Payment Behaviour Declined'
        );
        // << END - MM - FIN-9701 - Test Class Coverage for Credit App >>

        // << START - MM - FIN-9701 - Test Class Coverage for Credit App >>
        // For Manual case - BVD ID null
        Account acc8 = new Account(
            // << CHANGE - MM - FIN-9701 - Test Class Coverage | Added celsrm__App_Name__c value >>
            celsrm__App_Name__c = 'Credit',
            Name = 'Test Account 6', 
            CurrencyIsoCode = 'EUR', 
            BvD_ID_Number__c = '67832', 
            celsrm__Account_Key__c = '8888',
            Is_Snoozed__c = false,
            Calculated_Credit_Limit_Group_Currency__c = 54000,
            Recommended_Credit_Limit__c  = 54000,
            Moody_s_Credit_Limit__c  = 53000,
            celsrm__Credit_Limit__c = 22000,
            celsrm__Check_Rule__c = 'Z05 Risk Class High',
            celsrm__Credit_Group__c = '0003 - RCA - Regular Credit Account',
            celsrm__Limit_Valid_To_Date__c = Date.today().addDays(10),
            Moody_s_Change_Identified__c = false,
            celsrm__Payment_Behaviour_Text__c = 'Very Late',
            celsrm__Payment_Behaviour_Trend__c = 'Payment Behaviour Declined'
        );
        // << END - MM - FIN-9701 - Test Class Coverage for Credit App >>
        
        Moody_s_Auth__c auth = new Moody_s_Auth__c(
            Access_Token__c = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c',
            Token_Generation_Time__c = System.now()
        );

        insert new List<Account>{ acc1, acc2, acc3, acc4, acc5, acc6, acc7, acc8 };
        insert new List<Moody_s_Auth__c>{ auth };

        // << START - MM - FIN-9701 - Test Class Coverage for Credit App >>
        celsrm__Credit_Score__c cs = new celsrm__Credit_Score__c(
            celsrm__Account__c = acc8.Id
        );
        insert cs;
        // << END - MM - FIN-9701 - Test Class Coverage for Credit App >>
    }


    @isTest
    static void testCreditLimitZero() {
        Test.startTest();
        
        CreditReviewGeneratorWithZeroLimitBatch batch4 = new CreditReviewGeneratorWithZeroLimitBatch();
        Database.executeBatch(batch4, 50);
        Test.stopTest();
    }

    @isTest
    static void testCreditLimitLt20K() {
        Test.startTest();
        
        CreditReviewGeneratorWithLt20kLimitBatch batch4 = new CreditReviewGeneratorWithLt20kLimitBatch();
        Database.executeBatch(batch4, 50);
        Test.stopTest();
    }

    @isTest
    static void testCreditLimitGt20K() {
        Test.startTest();
        
        CreditReviewGeneratorWithGt20kLimitBatch batch4 = new CreditReviewGeneratorWithGt20kLimitBatch();
        Database.executeBatch(batch4, 50);
        Test.stopTest();
    }
    
    @isTest
    static void testManual() {
        Test.startTest();
        
        List<Account> accounts = [SELECT Id, Name,celsrm__Total_AR__c, celsrm__Credit_Group__c , Expected_Turnover__c, celsrm__Risk_Class__c, celsrm__Credit_Limit__c, Credit_Exposure__c, CurrencyIsoCode, Recommended_Credit_Limit__c, celsrm__Limit_Valid_To_Date__c, BvD_ID_Number__c, Moody_s_Credit_Limit__c, celsrm__Payment_Behaviour_Text__c, celsrm__Payment_Behaviour_Trend__c, Payment_Term_Days__c, celsrm__Check_Rule__c, Calculated_Credit_Limit_Group_Currency__c FROM Account];
        
        
        HttpResponse mockResponse = new HttpResponse();
        mockResponse.setBody('{"SearchSummary":{"TotalRecordsFound":1,"Offset":0,"RecordsReturned":1,"DatabaseInfo":{"ReleaseNumber":"357","UpdateNumber":"357001","UpdateDate":"2025-01-11T00:00:00","VersionNumber":"129.00","IndexationDate":"2025-01-06T00:00:00"},"Sort":{"DESC":"OPRE"}},"Data":[{"NAME":"NATIONAL FIRE FIGHTING MANUFACTURING FZCO","BVD_ID_NUMBER":"12345","EMPL":5000,"MORRAT":null,"MORE_YEAR":null,"MORCREDLIMIT":null,"MORDEF":null,"MORCONF":null,"REACMORRAT":null,"REACMORE_DATE":null,"REACMORCREDLIMIT":null,"REACMORDEF":null,"REACMORCONF":null,"MODEFINNF":"B","MODEFINNFDATE":"2025-01-05T00:00:00","MODEFINNF_CreditLimitValue":65415863.45475811,"MODEFINNFCONF":16,"CURR":null,"LIQR":null,"STATUS":["Active"],"STATUS_DATE":null,"INCORPORATION_DATE":"1965-01-01T00:00:00","CAPI":null}]}');
        mockResponse.setStatusCode(200);

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(mockResponse));
        //Boolean allowCreateCr = true;
        //System.enqueueJob(new GetMoodysDataService(accounts, allowCreateCr));
        CreditReviewGeneratorForManualBatch batch4 = new CreditReviewGeneratorForManualBatch();
        Database.executeBatch(batch4, 50);
        Test.stopTest();
    }

    // << START - MM - FIN-9701 - Test Class Coverage for Credit App >>
    @isTest
    static void testManualCSAvailable() {
        Test.startTest();
        
        List<Account> accounts = [SELECT Id, Name,celsrm__Total_AR__c, celsrm__Credit_Group__c , Expected_Turnover__c, celsrm__Risk_Class__c, celsrm__Credit_Limit__c, Credit_Exposure__c, CurrencyIsoCode, Recommended_Credit_Limit__c, celsrm__Limit_Valid_To_Date__c, BvD_ID_Number__c, Moody_s_Credit_Limit__c, celsrm__Payment_Behaviour_Text__c, celsrm__Payment_Behaviour_Trend__c, Payment_Term_Days__c, celsrm__Check_Rule__c, Calculated_Credit_Limit_Group_Currency__c FROM Account WHERE celsrm__Account_Key__c = '8888'];
        
        
        HttpResponse mockResponse = new HttpResponse();
        mockResponse.setBody('{"SearchSummary":{"TotalRecordsFound":1,"Offset":0,"RecordsReturned":1,"DatabaseInfo":{"ReleaseNumber":"357","UpdateNumber":"357001","UpdateDate":"2025-01-11T00:00:00","VersionNumber":"129.00","IndexationDate":"2025-01-06T00:00:00"},"Sort":{"DESC":"OPRE"}},"Data":[{"NAME":"NATIONAL FIRE FIGHTING MANUFACTURING FZCO","BVD_ID_NUMBER":"12345","EMPL":5000,"MORRAT":null,"MORE_YEAR":null,"MORCREDLIMIT":null,"MORDEF":null,"MORCONF":null,"REACMORRAT":null,"REACMORE_DATE":null,"REACMORCREDLIMIT":null,"REACMORDEF":null,"REACMORCONF":null,"MODEFINNF":"B","MODEFINNFDATE":"2025-01-05T00:00:00","MODEFINNF_CreditLimitValue":65415863.45475811,"MODEFINNFCONF":16,"CURR":null,"LIQR":null,"STATUS":["Active"],"STATUS_DATE":null,"INCORPORATION_DATE":"1965-01-01T00:00:00","CAPI":null}]}');
        mockResponse.setStatusCode(200);

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(mockResponse));
        //Boolean allowCreateCr = true;
        //System.enqueueJob(new GetMoodysDataService(accounts, allowCreateCr));
        CreditReviewGeneratorForManualBatch batch4 = new CreditReviewGeneratorForManualBatch();
        Database.executeBatch(batch4, 50);
        Test.stopTest();
    }
    // << END - MM - FIN-9701 - Test Class Coverage for Credit App >>

    // << START - MM - FIN-10145 - Test coverage for updateProfileData method >>
    @isTest
    static void testUpdateProfileData_Success200() {
        // Setup Credit_Configuration__c with webhook URL
        Credit_Configuration__c config = Credit_Configuration__c.getOrgDefaults();
        config.Update_Profile_Data_Action_Flow_Webhook__c = 'webhook/action-flows/test-webhook-id';
        upsert config;

        List<Account> accounts = [SELECT Id, Name, AccountNumber, celsrm__Credit_Control_Area__c,
            celsrm__Check_Rule__c, celsrm__Risk_Class__c, celsrm__Credit_Group__c, Sync_Profile_Data_Message__c,
            Sync_Profile_Data_In_Source_System_At__c
            FROM Account WHERE celsrm__Account_Key__c = '4444'];

        // Mock response with successful profile data update
        HttpResponse mockRes = new HttpResponse();
        mockRes.setStatusCode(200);
        mockRes.setBody('{"status":"Success","details":{"updateResponse":[{"PARTNER":"' + accounts[0].AccountNumber + '","CHECK_RULE":"Z05","CREDIT_GROUP":"0003","RISK_CLASS":"5","STATUS_MSG":"Update successful"}]}}');

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(mockRes));

        Test.startTest();
        GetMoodysDataService service = new GetMoodysDataService(new List<String>(), true, false);
        service.updateProfileData(accounts);
        Test.stopTest();
    }

    @isTest
    static void testUpdateProfileData_Accepted200() {
        Credit_Configuration__c config = Credit_Configuration__c.getOrgDefaults();
        config.Update_Profile_Data_Action_Flow_Webhook__c = 'webhook/action-flows/test-webhook-id';
        upsert config;

        List<Account> accounts = [SELECT Id, Name, AccountNumber, celsrm__Credit_Control_Area__c,
            celsrm__Check_Rule__c, celsrm__Risk_Class__c, celsrm__Credit_Group__c, Sync_Profile_Data_Message__c
            FROM Account WHERE celsrm__Account_Key__c = '4444'];

        HttpResponse mockRes = new HttpResponse();
        mockRes.setStatusCode(200);
        mockRes.setBody('Accepted');

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(mockRes));

        Test.startTest();
        GetMoodysDataService service = new GetMoodysDataService(new List<String>(), true, false);
        service.updateProfileData(accounts);
        Test.stopTest();
    }

    @isTest
    static void testUpdateProfileData_Error401() {
        Credit_Configuration__c config = Credit_Configuration__c.getOrgDefaults();
        config.Update_Profile_Data_Action_Flow_Webhook__c = 'webhook/action-flows/test-webhook-id';
        upsert config;

        List<Account> accounts = [SELECT Id, Name, AccountNumber, celsrm__Credit_Control_Area__c,
            celsrm__Check_Rule__c, celsrm__Risk_Class__c, celsrm__Credit_Group__c, Sync_Profile_Data_Message__c
            FROM Account WHERE celsrm__Account_Key__c = '4444'];

        HttpResponse mockRes = new HttpResponse();
        mockRes.setStatusCode(401);
        mockRes.setBody('{"status":"Error","details":"Please make sure you have provided correct Authentication token"}');

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(mockRes));

        Test.startTest();
        GetMoodysDataService service = new GetMoodysDataService(new List<String>(), true, false);
        service.updateProfileData(accounts);
        Test.stopTest();
    }

    @isTest
    static void testUpdateProfileData_Error500() {
        Credit_Configuration__c config = Credit_Configuration__c.getOrgDefaults();
        config.Update_Profile_Data_Action_Flow_Webhook__c = 'webhook/action-flows/test-webhook-id';
        upsert config;

        List<Account> accounts = [SELECT Id, Name, AccountNumber, celsrm__Credit_Control_Area__c,
            celsrm__Check_Rule__c, celsrm__Risk_Class__c, celsrm__Credit_Group__c, Sync_Profile_Data_Message__c
            FROM Account WHERE celsrm__Account_Key__c = '4444'];

        HttpResponse mockRes = new HttpResponse();
        mockRes.setStatusCode(500);
        mockRes.setBody('Internal Server Error');

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(mockRes));

        Test.startTest();
        GetMoodysDataService service = new GetMoodysDataService(new List<String>(), true, false);
        service.updateProfileData(accounts);
        Test.stopTest();
    }

    @isTest
    static void testUpdateProfileData_Error429() {
        Credit_Configuration__c config = Credit_Configuration__c.getOrgDefaults();
        config.Update_Profile_Data_Action_Flow_Webhook__c = 'webhook/action-flows/test-webhook-id';
        upsert config;

        List<Account> accounts = [SELECT Id, Name, AccountNumber, celsrm__Credit_Control_Area__c,
            celsrm__Check_Rule__c, celsrm__Risk_Class__c, celsrm__Credit_Group__c, Sync_Profile_Data_Message__c
            FROM Account WHERE celsrm__Account_Key__c = '4444'];

        HttpResponse mockRes = new HttpResponse();
        mockRes.setStatusCode(429);
        mockRes.setBody('Too Many Requests');

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(mockRes));

        Test.startTest();
        GetMoodysDataService service = new GetMoodysDataService(new List<String>(), true, false);
        service.updateProfileData(accounts);
        Test.stopTest();
    }

    @isTest
    static void testUpdateProfileData_WebhookNull() {
        // Do NOT set Credit_Configuration__c webhook URL - leave it null
        List<Account> accounts = [SELECT Id, Name, AccountNumber, celsrm__Credit_Control_Area__c,
            celsrm__Check_Rule__c, celsrm__Risk_Class__c, celsrm__Credit_Group__c, Sync_Profile_Data_Message__c
            FROM Account WHERE celsrm__Account_Key__c = '4444'];

        Test.startTest();
        GetMoodysDataService service = new GetMoodysDataService(new List<String>(), true, false);
        service.updateProfileData(accounts);
        Test.stopTest();
    }

    @isTest
    static void testUpdateProfileData_ResponseNoMatch() {
        // Test case where response PARTNER doesn't match any account key
        Credit_Configuration__c config = Credit_Configuration__c.getOrgDefaults();
        config.Update_Profile_Data_Action_Flow_Webhook__c = 'webhook/action-flows/test-webhook-id';
        upsert config;

        List<Account> accounts = [SELECT Id, Name, AccountNumber, celsrm__Credit_Control_Area__c,
            celsrm__Check_Rule__c, celsrm__Risk_Class__c, celsrm__Credit_Group__c, Sync_Profile_Data_Message__c
            FROM Account WHERE celsrm__Account_Key__c = '4444'];

        // Response with a PARTNER that doesn't match the account's key
        HttpResponse mockRes = new HttpResponse();
        mockRes.setStatusCode(200);
        mockRes.setBody('{"status":"Success","details":{"updateResponse":[{"PARTNER":"NOMATCH","CHECK_RULE":"Z05","CREDIT_GROUP":"0003","RISK_CLASS":"5","STATUS_MSG":"Update successful"}]}}');

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(mockRes));

        Test.startTest();
        GetMoodysDataService service = new GetMoodysDataService(new List<String>(), true, false);
        service.updateProfileData(accounts);
        Test.stopTest();
    }

    @isTest
    static void testUpdateProfileData_OtherStatusCode() {
        Credit_Configuration__c config = Credit_Configuration__c.getOrgDefaults();
        config.Update_Profile_Data_Action_Flow_Webhook__c = 'webhook/action-flows/test-webhook-id';
        upsert config;

        List<Account> accounts = [SELECT Id, Name, AccountNumber, celsrm__Credit_Control_Area__c,
            celsrm__Check_Rule__c, celsrm__Risk_Class__c, celsrm__Credit_Group__c, Sync_Profile_Data_Message__c
            FROM Account WHERE celsrm__Account_Key__c = '4444'];

        HttpResponse mockRes = new HttpResponse();
        mockRes.setStatusCode(403);
        mockRes.setBody('Forbidden');

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(mockRes));

        Test.startTest();
        GetMoodysDataService service = new GetMoodysDataService(new List<String>(), true, false);
        service.updateProfileData(accounts);
        Test.stopTest();
    }
    // << END - MM - FIN-10145 - Test coverage for updateProfileData method >>

    public class MockHttpResponseGenerator implements HttpCalloutMock {
        private HttpResponse mockResponse;

        public MockHttpResponseGenerator(HttpResponse mockResponse) {
            this.mockResponse = mockResponse;
        }

        public HttpResponse respond(HttpRequest req) {
            return mockResponse;
        }
    }
}