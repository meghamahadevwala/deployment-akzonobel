@isTest
public class DailyCreditReviewGeneratorTest {
    @testSetup
    static void setupData() {
        //For Credit Limit <= 50K EUR
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
            Credit_Exposure__c = 16500,
            celsrm__Check_Rule__c = 'Z05 Risk Class High',
            celsrm__Credit_Group__c = '0003 - RCA - Regular Credit Account',
            celsrm__Limit_Valid_To_Date__c = Date.today().addDays(10),
            Moody_s_Change_Identified__c = false,
            celsrm__Payment_Behaviour_Text__c = 'Very Late',
            celsrm__Payment_Behaviour_Trend__c = 'Payment Behaviour Declined'
        );

        //For Credit Limit > 50K EUR
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
            Credit_Exposure__c = 19500,
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
            Credit_Exposure__c = 50000,
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
            Credit_Exposure__c = 50000,
            celsrm__Check_Rule__c = 'Z05 Risk Class High',
            celsrm__Credit_Group__c = '0003 - RCA - Regular Credit Account',
            celsrm__Limit_Valid_To_Date__c = Date.today().addDays(10),
            Moody_s_Change_Identified__c = false,
            celsrm__Payment_Behaviour_Text__c = 'Very Late',
            celsrm__Payment_Behaviour_Trend__c = 'Payment Behaviour Declined'
        );

        // << START - MM - FIN-9701 - Test Class Coverage for Credit App >>
        //For Manual case - BVD ID NULL
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
            Credit_Exposure__c = 50000,
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

        insert new List<Account>{ acc2, acc3, acc4, acc5, acc6, acc7 };
        insert new List<Moody_s_Auth__c>{ auth };
    }

    @isTest
    static void testCreditLimitLt20K() {
        Test.startTest();
        
        DailyClrGeneratorWithLt20kLimitBatch batch4 = new DailyClrGeneratorWithLt20kLimitBatch();
        Database.executeBatch(batch4, 50);
        Test.stopTest();
    }

    @isTest
    static void testCreditLimitGt20K() {
        Test.startTest();
        
        DailyClrGeneratorWithGt20kLimitBatch batch4 = new DailyClrGeneratorWithGt20kLimitBatch();
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
        DailyClrGeneratorForManualBatch batch4 = new DailyClrGeneratorForManualBatch();
        Database.executeBatch(batch4, 50);
        Test.stopTest();
    }
    
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