@isTest

public with sharing class CreditReviewPerameterTest {

    @testSetup
    static void setupData() {
        // << CHANGE - MM - FIN-9701 - Test Class Coverage | Multiplied Calculated_Credit_Limit_Group_Currency__c, Recommended_Credit_Limit__c, Moody_s_Credit_Limit__c and celsrm__Credit_Limit__c by 10 to ensure that the credit limit is above 50K EUR for the test class coverage >>

        //Without BVD ID
        Account acc1 = new Account(
            // << CHANGE - MM - FIN-9701 - Test Class Coverage | Added celsrm__App_Name__c value >>
            celsrm__App_Name__c = 'Credit',
            Name = 'Test Account 1', 
            CurrencyIsoCode = 'USD',
            BvD_ID_Number__c = null, 
            celsrm__Account_Key__c = '1111',
            Is_Snoozed__c = false,
            Calculated_Credit_Limit_Group_Currency__c = 240000,
            Recommended_Credit_Limit__c  = 240000,
            Moody_s_Credit_Limit__c  = 230000,
            celsrm__Credit_Limit__c = 220000,
            celsrm__Check_Rule__c = 'Z05 Risk Class High',
            celsrm__Credit_Group__c = '0003 - RCA - Regular Credit Account',
            celsrm__Limit_Valid_To_Date__c = Date.today().addDays(10),
            Moody_s_Change_Identified__c = true,
            celsrm__Payment_Behaviour_Text__c = 'Late',
            celsrm__Payment_Behaviour_Trend__c = 'Payment Behaviour Declined' 
        );

        Account acc2 = new Account(
            // << CHANGE - MM - FIN-9701 - Test Class Coverage | Added celsrm__App_Name__c value >>
            celsrm__App_Name__c = 'Credit',
            Name = 'Test Account 2', 
            CurrencyIsoCode = 'EUR', 
            BvD_ID_Number__c = '12345', 
            celsrm__Account_Key__c = '2222',
            Is_Snoozed__c = false,
            Calculated_Credit_Limit_Group_Currency__c = 240000,
            Recommended_Credit_Limit__c  = 240000,
            Moody_s_Credit_Limit__c  = 230000,
            celsrm__Credit_Limit__c = 220000,
            celsrm__Check_Rule__c = 'Z05 Risk Class High',
            celsrm__Credit_Group__c = '0003 - RCA - Regular Credit Account',
            celsrm__Limit_Valid_To_Date__c = Date.today().addDays(10),
            Moody_s_Change_Identified__c = false,
            celsrm__Payment_Behaviour_Text__c = 'Very Late',
            celsrm__Payment_Behaviour_Trend__c = 'Payment Behaviour Declined'
        );
        
        
        Account acc3 = new Account(
            // << CHANGE - MM - FIN-9701 - Test Class Coverage | Added celsrm__App_Name__c value >>
            celsrm__App_Name__c = 'Credit',
            Name = 'Test Account 3', 
            CurrencyIsoCode = 'EUR', 
            BvD_ID_Number__c = '54321', 
            celsrm__Account_Key__c = '3333',
            Is_Snoozed__c = false,
            Calculated_Credit_Limit_Group_Currency__c = 240000,
            Recommended_Credit_Limit__c  = 240000,
            Moody_s_Credit_Limit__c  = 230000,
            celsrm__Credit_Limit__c = 220000,
            celsrm__Check_Rule__c = 'Z05 Risk Class High',
            celsrm__Credit_Group__c = '0003 - RCA - Regular Credit Account',
            celsrm__Limit_Valid_To_Date__c = Date.today().addDays(10),
            Moody_s_Change_Identified__c = false,
            celsrm__Payment_Behaviour_Text__c = 'Very Late',
            celsrm__Payment_Behaviour_Trend__c = 'Payment Behaviour Declined'
        );
        
        

        Moody_s_Auth__c auth = new Moody_s_Auth__c(
            Access_Token__c = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c',
            Token_Generation_Time__c = System.now()
        );


        insert new List<Account>{ acc1, acc2, acc3 };
        insert new List<Moody_s_Auth__c>{ auth };
            
        celsrm__Credit_Score__c  cs = new celsrm__Credit_Score__c(
            celsrm__Account__c = acc3.Id
        );
        insert new List<celsrm__Credit_Score__c>{ cs };
    }

    @isTest 
    public static void InitiateCreditReviewWithoutDUNS() {
        Test.startTest();
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account 1' LIMIT 1];
        Map<Object,Object> inMap = new Map<Object,Object>();
        inMap.put('Id', acc.Id);
        CreditReviewParameters creditReviewParameters = new CreditReviewParameters();

        // << START - MM - FIN-9701 - Test Class Coverage for Credit App >>
        creditReviewParameters.invoke('onLoadInitiateCreditReview', inMap);
        // << END - MM - FIN-9701 - Test Class Coverage for Credit App >>
        inMap.put('modelType', 'Full Review');
        HttpResponse mockResponse = new HttpResponse();
        mockResponse.setBody('[{"Hint":"Selected","Score":0.71,"Name":"THORNTON ENGINEERING AUSTRALIA PTY LTD","Address":"183-185 LITTLE MALOP ST","Postcode":"3220","City":"GEELONG","Country":"AU","National_Id":"22 087 898 753","NationalIdLabel":"ABN","LegalForm":"Proprietary limited company","Status":"Active","Isin":null,"BvDId":"AU087898753"},{"Hint":"Unlikely","Score":0.51,"Name":"CAVALIER BREMWORTH (AUSTRALIA)LIMITED","Address":"7 GRAYSON AVENUE","Postcode":"2104","City":"PAPATOETOE","Country":"NZ","National_Id":"76605","NationalIdLabel":"Company number","LegalForm":"Limited company","Status":"Active","Isin":null,"BvDId":"NZ9429040607047"},{"Hint":"Unlikely","Score":0.5,"Name":"EJ & VD THORNTON","Address":null,"Postcode":"6166","City":null,"Country":"AU","National_Id":"93 793 184 918","NationalIdLabel":"ABN","LegalForm":"Family partnership","Status":"Inactive (no precision)","Isin":null,"BvDId":"AU93793184918"}]');
        mockResponse.setStatusCode(200);
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(mockResponse));
        creditReviewParameters.invoke('initiateCreditReview', inMap);

        inMap.put('bvDId', '12345');
        creditReviewParameters.invoke('updateBvdId', inMap);

        creditReviewParameters.invoke('calculateRequestedCreditLimitEUR', inMap);

        Test.stopTest();
    }


    @isTest 
    public static void InitiateCreditReviewWithBVD() {
        Test.startTest();
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account 2' LIMIT 1];
        Map<Object,Object> inMap = new Map<Object,Object>();
        inMap.put('Id', acc.Id);
        CreditReviewParameters creditReviewParameters = new CreditReviewParameters();
        inMap.put('modelType', 'Full Review');
        HttpResponse mockResponse = new HttpResponse(); 
        mockResponse.setBody('{"SearchSummary":{"TotalRecordsFound":1,"Offset":0,"RecordsReturned":1,"DatabaseInfo":{"ReleaseNumber":"357","UpdateNumber":"357001","UpdateDate":"2025-01-11T00:00:00","VersionNumber":"129.00","IndexationDate":"2025-01-06T00:00:00"},"Sort":{"DESC":"OPRE"}},"Data":[{"NAME":"NATIONAL FIRE FIGHTING MANUFACTURING FZCO","BVD_ID_NUMBER":"12345","EMPL":5000,"MORRAT":null,"MORE_YEAR":null,"MORCREDLIMIT":null,"MORDEF":null,"MORCONF":null,"REACMORRAT":null,"REACMORE_DATE":null,"REACMORCREDLIMIT":null,"REACMORDEF":null,"REACMORCONF":null,"MODEFINNF":"B","MODEFINNFDATE":"2025-01-05T00:00:00","MODEFINNF_CreditLimitValue":65415863.45475811,"MODEFINNFCONF":16,"CURR":null,"LIQR":null,"STATUS":["Active"],"STATUS_DATE":null,"INCORPORATION_DATE":"1965-01-01T00:00:00","CAPI":null}]}');
        mockResponse.setStatusCode(200);
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(mockResponse));
        creditReviewParameters.invoke('initiateCreditReview', inMap);
        creditReviewParameters.invoke('createCreditReviewRecord', inMap);
        Test.stopTest();
    }
    
    
    @isTest 
    public static void InitiateCreditReviewWithBVDExistingCs() {
        Test.startTest();
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account 3' LIMIT 1];
        Map<Object,Object> inMap = new Map<Object,Object>();
        inMap.put('Id', acc.Id);
        CreditReviewParameters creditReviewParameters = new CreditReviewParameters();
        inMap.put('modelType', 'Full Review');
        creditReviewParameters.invoke('initiateCreditReview', inMap);
        creditReviewParameters.invoke('createCreditReviewRecord', inMap);
        Test.stopTest();
    }

    // << START - MM - FIN-10130 - Additional test coverage for CreditReviewParameters uncovered branches >>

    private static Account buildAccount(String key, String bvdId, Boolean snoozed, String checkRule,
        String creditGroup, String paymentBehaviour, String paymentTrend) {
        return new Account(
            celsrm__App_Name__c = 'Credit',
            Name = 'Test Account ' + key,
            CurrencyIsoCode = 'USD',
            BvD_ID_Number__c = bvdId,
            celsrm__Account_Key__c = key,
            Is_Snoozed__c = snoozed,
            Calculated_Credit_Limit_Group_Currency__c = 240000,
            Recommended_Credit_Limit__c = 240000,
            Moody_s_Credit_Limit__c = 230000,
            celsrm__Credit_Limit__c = 220000,
            celsrm__Check_Rule__c = checkRule,
            celsrm__Credit_Group__c = creditGroup,
            celsrm__Limit_Valid_To_Date__c = Date.today().addDays(10),
            Moody_s_Change_Identified__c = false,
            celsrm__Payment_Behaviour_Text__c = paymentBehaviour,
            celsrm__Payment_Behaviour_Trend__c = paymentTrend
        );
    }

    // Covers invoke() outer catch (calculateRequestedCreditLimitEUR has no internal try/catch,
    // so a null RequestedCreditLimit causes Math.floor(null) to NPE and propagate to invoke()'s catch).
    @isTest
    static void testInvokeCatchesUnhandledExceptionFromCalculateEUR() {
        Test.startTest();
        Map<Object,Object> inMap = new Map<Object,Object>();
        inMap.put('CurrencyIsoCode', 'EUR');
        // Intentionally NOT putting 'RequestedCreditLimit' -> null -> NPE inside calculateRequestedCreditLimitEUR
        CreditReviewParameters creditReviewParameters = new CreditReviewParameters();
        Map<Object,Object> result = creditReviewParameters.invoke('calculateRequestedCreditLimitEUR', inMap);
        Test.stopTest();
    }

    // Covers the EUR (else) branch of calculateRequestedCreditLimitEUR
    @isTest
    static void testCalculateRequestedCreditLimitEURDirectEURCurrency() {
        Test.startTest();
        Map<Object,Object> inMap = new Map<Object,Object>();
        inMap.put('CurrencyIsoCode', 'EUR');
        inMap.put('RequestedCreditLimit', 45000.75);
        CreditReviewParameters creditReviewParameters = new CreditReviewParameters();
        Map<Object,Object> result = creditReviewParameters.invoke('calculateRequestedCreditLimitEUR', inMap);
        Test.stopTest();
    }

    // Covers onLoadInitiateCreditReview's outer catch (SOQL query throws when Id is null/not found)
    @isTest
    static void testOnLoadInitiateCreditReviewAccountQueryException() {
        Test.startTest();
        Map<Object,Object> inMap = new Map<Object,Object>();
        inMap.put('Id', null);
        CreditReviewParameters creditReviewParameters = new CreditReviewParameters();
        Map<Object,Object> result = creditReviewParameters.invoke('onLoadInitiateCreditReview', inMap);
        Test.stopTest();
    }

    // Covers initiateCreditReview's outer catch (SOQL query throws when Id is null/not found)
    @isTest
    static void testInitiateCreditReviewAccountQueryException() {
        Test.startTest();
        Map<Object,Object> inMap = new Map<Object,Object>();
        inMap.put('Id', null);
        CreditReviewParameters creditReviewParameters = new CreditReviewParameters();
        Map<Object,Object> result = creditReviewParameters.invoke('initiateCreditReview', inMap);
        Test.stopTest();
    }

    // Covers updateBvdId's outer catch (SOQL query throws when Id is null/not found)
    @isTest
    static void testUpdateBvdIdAccountQueryException() {
        Test.startTest();
        Map<Object,Object> inMap = new Map<Object,Object>();
        inMap.put('Id', null);
        inMap.put('bvDId', '99999');
        CreditReviewParameters creditReviewParameters = new CreditReviewParameters();
        Map<Object,Object> result = creditReviewParameters.invoke('updateBvdId', inMap);
        Test.stopTest();
    }

    // Covers the Is_Snoozed__c early-return branch of initiateCreditReview
    @isTest
    static void testInitiateCreditReviewSnoozedAccount() {
        Account acc = buildAccount('SNZ001', null, true, 'Z05 Risk Class High', '0003 - RCA - Regular Credit Account', null, null);
        insert acc;
        Test.startTest();
        Map<Object,Object> inMap = new Map<Object,Object>();
        inMap.put('Id', acc.Id);
        CreditReviewParameters creditReviewParameters = new CreditReviewParameters();
        Map<Object,Object> result = creditReviewParameters.invoke('initiateCreditReview', inMap);
        Test.stopTest();
    }

    // Covers the "open Credit Review already exists" early-return branch of initiateCreditReview
    @isTest
    static void testInitiateCreditReviewOpenCrExists() {
        Account acc = buildAccount('OCR001', null, false, 'Z05 Risk Class High', '0003 - RCA - Regular Credit Account', null, null);
        insert acc;
        celsrm__Credit_Review__c cr = new celsrm__Credit_Review__c(
            celsrm__Account__c = acc.Id,
            celsrm__Status__c = '10'
        );
        insert cr;
        Test.startTest();
        Map<Object,Object> inMap = new Map<Object,Object>();
        inMap.put('Id', acc.Id);
        CreditReviewParameters creditReviewParameters = new CreditReviewParameters();
        Map<Object,Object> result = creditReviewParameters.invoke('initiateCreditReview', inMap);
        Test.stopTest();
    }

    // Covers the "child account" (Z08 Risk Class Child) early-return branch of initiateCreditReview
    @isTest
    static void testInitiateCreditReviewChildAccount() {
        Account acc = buildAccount('CHILD01', null, false, 'Z08 Risk Class Child', '0003 - RCA - Regular Credit Account', null, null);
        insert acc;
        Test.startTest();
        Map<Object,Object> inMap = new Map<Object,Object>();
        inMap.put('Id', acc.Id);
        CreditReviewParameters creditReviewParameters = new CreditReviewParameters();
        Map<Object,Object> result = creditReviewParameters.invoke('initiateCreditReview', inMap);
        Test.stopTest();
    }

    // Covers the "empty Credit Group" early-return branch of initiateCreditReview
    @isTest
    static void testInitiateCreditReviewCreditGroupEmpty() {
        Account acc = buildAccount('CGE001', null, false, 'Z05 Risk Class High', null, null, null);
        insert acc;
        Test.startTest();
        Map<Object,Object> inMap = new Map<Object,Object>();
        inMap.put('Id', acc.Id);
        CreditReviewParameters creditReviewParameters = new CreditReviewParameters();
        Map<Object,Object> result = creditReviewParameters.invoke('initiateCreditReview', inMap);
        Test.stopTest();
    }

    // Covers the "excluded Credit Group" early-return branch of initiateCreditReview
    @isTest
    static void testInitiateCreditReviewCreditGroupInvalid() {
        Account acc = buildAccount('CGI001', null, false, 'Z05 Risk Class High', '0001 - New customer / No score', null, null);
        insert acc;
        Test.startTest();
        Map<Object,Object> inMap = new Map<Object,Object>();
        inMap.put('Id', acc.Id);
        CreditReviewParameters creditReviewParameters = new CreditReviewParameters();
        Map<Object,Object> result = creditReviewParameters.invoke('initiateCreditReview', inMap);
        Test.stopTest();
    }

    // Covers the default modelType='Recalculation' fallback (caller does not pre-populate 'modelType')
    @isTest
    static void testInitiateCreditReviewDefaultModelType() {
        Account acc = buildAccount('MODEL01', null, false, 'Z05 Risk Class High', '0003 - RCA - Regular Credit Account', null, null);
        insert acc;
        HttpResponse mockResponse = new HttpResponse();
        mockResponse.setBody('[]');
        mockResponse.setStatusCode(200);
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(mockResponse));
        Test.startTest();
        Map<Object,Object> inMap = new Map<Object,Object>();
        inMap.put('Id', acc.Id);
        // Intentionally NOT setting 'modelType' so the default fallback branch executes
        CreditReviewParameters creditReviewParameters = new CreditReviewParameters();
        Map<Object,Object> result = creditReviewParameters.invoke('initiateCreditReview', inMap);
        Test.stopTest();
    }

    // Covers the REACTIVE credit-limit/risk-class source branches and the "On Time" payment multiplier
    @isTest
    static void testInitiateCreditReviewReactiveSourceOnTimePayment() {
        Account acc = buildAccount('REACT01', 'REACT-BVD-1', false, 'Z05 Risk Class High', '0003 - RCA - Regular Credit Account', 'On Time', null);
        insert acc;
        HttpResponse mockResponse = new HttpResponse();
        mockResponse.setBody('{"Data":[{"NAME":"Reactive Test Co","BVD_ID_NUMBER":"REACT-BVD-1","REACMORRAT":"AAA","REACMORE_DATE":"2026-01-05T00:00:00","REACMORCREDLIMIT":90000.55}]}');
        mockResponse.setStatusCode(200);
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(mockResponse));
        Test.startTest();
        Map<Object,Object> inMap = new Map<Object,Object>();
        inMap.put('Id', acc.Id);
        inMap.put('modelType', 'Full Review');
        // Pre-populate RequestedCreditLimitEUR so we don't rely on the account.Calculated_Credit_Limit_Group_Currency__c
        // fallback assignment at initiateCreditReview() line ~171 (see bug note below).
        inMap.put('RequestedCreditLimitEUR', 75000);
        CreditReviewParameters creditReviewParameters = new CreditReviewParameters();
        Map<Object,Object> result = creditReviewParameters.invoke('initiateCreditReview', inMap);
        Test.stopTest();
    }

    // Covers the MORE credit-limit/risk-class source branches, the "Late"+"Improved" payment multiplier,
    // and the protected Key Account check-rule branch (celsrm__Check_Rule__c left unchanged)
    @isTest
    static void testInitiateCreditReviewMoreSourceLateImprovedKeyAccount() {
        Account acc = buildAccount('MORE01', 'MORE-BVD-1', false, 'Z07 Risk Class Key Account', '0003 - RCA - Regular Credit Account', 'Late', 'Payment Behaviour Improved');
        insert acc;
        HttpResponse mockResponse = new HttpResponse();
        mockResponse.setBody('{"Data":[{"NAME":"More Test Co","BVD_ID_NUMBER":"MORE-BVD-1","MORRAT":"BBB","MORE_YEAR":"2026-02-01T00:00:00","MORCREDLIMIT":80000.25}]}');
        mockResponse.setStatusCode(200);
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(mockResponse));
        Test.startTest();
        Map<Object,Object> inMap = new Map<Object,Object>();
        inMap.put('Id', acc.Id);
        inMap.put('modelType', 'Full Review');
        inMap.put('RequestedCreditLimitEUR', 75000);
        CreditReviewParameters creditReviewParameters = new CreditReviewParameters();
        Map<Object,Object> result = creditReviewParameters.invoke('initiateCreditReview', inMap);
        Test.stopTest();
    }

    // Covers the "Very Late" + "Payment Behaviour Improved" payment multiplier branch (qualitative source)
    @isTest
    static void testInitiateCreditReviewQualitativeSourceVeryLateImproved() {
        Account acc = buildAccount('QUAL01', 'QUAL-BVD-1', false, 'Z05 Risk Class High', '0003 - RCA - Regular Credit Account', 'Very Late', 'Payment Behaviour Improved');
        insert acc;
        HttpResponse mockResponse = new HttpResponse();
        mockResponse.setBody('{"Data":[{"NAME":"Qual Test Co","BVD_ID_NUMBER":"QUAL-BVD-1","MODEFINNF":"B","MODEFINNFDATE":"2026-01-05T00:00:00","MODEFINNF_CreditLimitValue":50000.11}]}');
        mockResponse.setStatusCode(200);
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(mockResponse));
        Test.startTest();
        Map<Object,Object> inMap = new Map<Object,Object>();
        inMap.put('Id', acc.Id);
        inMap.put('modelType', 'Full Review');
        inMap.put('RequestedCreditLimitEUR', 75000);
        CreditReviewParameters creditReviewParameters = new CreditReviewParameters();
        Map<Object,Object> result = creditReviewParameters.invoke('initiateCreditReview', inMap);
        Test.stopTest();
    }

    // Covers the "Late" + "Payment Behaviour Declined" payment multiplier branch (qualitative source)
    @isTest
    static void testInitiateCreditReviewQualitativeSourceLateDeclined() {
        Account acc = buildAccount('QUAL02', 'QUAL-BVD-2', false, 'Z05 Risk Class High', '0003 - RCA - Regular Credit Account', 'Late', 'Payment Behaviour Declined');
        insert acc;
        HttpResponse mockResponse = new HttpResponse();
        mockResponse.setBody('{"Data":[{"NAME":"Qual Test Co 2","BVD_ID_NUMBER":"QUAL-BVD-2","MODEFINNF":"C","MODEFINNFDATE":"2026-01-05T00:00:00","MODEFINNF_CreditLimitValue":50000.11}]}');
        mockResponse.setStatusCode(200);
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(mockResponse));
        Test.startTest();
        Map<Object,Object> inMap = new Map<Object,Object>();
        inMap.put('Id', acc.Id);
        inMap.put('modelType', 'Full Review');
        inMap.put('RequestedCreditLimitEUR', 75000);
        CreditReviewParameters creditReviewParameters = new CreditReviewParameters();
        Map<Object,Object> result = creditReviewParameters.invoke('initiateCreditReview', inMap);
        Test.stopTest();
    }

    // << START - Ticket #916 - Qualitative Score E now maps to Direct Block, CFIN fields stay High Risk / Z05 >>
    @isTest
    static void testInitiateCreditReviewQualitativeScoreE_MapsToDirectBlock_916() {
        Account acc = buildAccount('QUAL03', 'QUAL-BVD-3', false, 'Z05 Risk Class High', '0003 - RCA - Regular Credit Account', 'On Time', null);
        insert acc;
        HttpResponse mockResponse = new HttpResponse();
        mockResponse.setBody('{"Data":[{"NAME":"Qual Test Co 3","BVD_ID_NUMBER":"QUAL-BVD-3","MODEFINNF":"E","MODEFINNFDATE":"2026-01-05T00:00:00","MODEFINNF_CreditLimitValue":50000.11}]}');
        mockResponse.setStatusCode(200);
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(mockResponse));
        Test.startTest();
        Map<Object,Object> inMap = new Map<Object,Object>();
        inMap.put('Id', acc.Id);
        inMap.put('modelType', 'Full Review');
        inMap.put('RequestedCreditLimitEUR', 75000);
        CreditReviewParameters creditReviewParameters = new CreditReviewParameters();
        Map<Object,Object> result = creditReviewParameters.invoke('initiateCreditReview', inMap);
        Test.stopTest();

        Account updated = [SELECT Moody_s_Risk_Class__c, celsrm__Risk_Class__c, celsrm__Check_Rule__c FROM Account WHERE Id = :acc.Id];
        System.assertEquals('Direct Block', updated.Moody_s_Risk_Class__c,
            'Moody_s_Risk_Class__c should reflect the new internal classification.');
        System.assertEquals('5 - High Risk', updated.celsrm__Risk_Class__c,
            'CFIN-facing risk class must be High Risk, not Full Credit Block.');
        System.assertEquals('Z09 Risk Class Direct Block', updated.celsrm__Check_Rule__c,
            'CFIN-facing check rule must be Z09 (Direct Block), not Z05 or Z06.');
    }
    // << END - Ticket #916 >>

    // Covers createCreditReviewRecord's <=50000 EUR "auto approve" branch (status '11', celsrm__Approved_Credit_Limit__c set)
    @isTest
    static void testCreateCreditReviewRecordLowLimitApprovedBranch() {
        Account acc = buildAccount('CLR01', null, false, 'Z05 Risk Class High', '0003 - RCA - Regular Credit Account', 'On Time', null);
        insert acc;
        Test.startTest();
        Map<Object,Object> inMap = new Map<Object,Object>();
        inMap.put('Id', acc.Id);
        inMap.put('modelType', 'Recalculation');
        inMap.put('RequestedCreditLimit', 20000.00);
        inMap.put('RequestedCreditLimitEUR', 20000);
        inMap.put('RequestedValidToDate', Date.today().addDays(30));
        inMap.put('PaymentTermDays', 30.00);
        Map<Object,Object> result = CreditReviewParameters.createCreditReviewRecord(inMap);
        Test.stopTest();
    }

    // Covers createCreditReviewRecord's outer catch (SOQL query throws when Id is null/not found)
    @isTest
    static void testCreateCreditReviewRecordAccountQueryException() {
        Test.startTest();
        Map<Object,Object> inMap = new Map<Object,Object>();
        inMap.put('Id', null);
        Map<Object,Object> result = CreditReviewParameters.createCreditReviewRecord(inMap);
        Test.stopTest();
    }

    // << END - MM - FIN-10130 - Additional test coverage for CreditReviewParameters uncovered branches >>

    // << START - Test Coverage for Recommended_Credit_Limit__c vs Credit_Exposure__c validation >>

    // Covers: Recommended_Credit_Limit__c cannot be set lower than Credit_Exposure__c,
    // neither to 0 nor to any other number below it
    @isTest
    static void testRecommendedCreditLimitCannotBeLessThanCreditExposure() {
        Account acc = buildAccount('RCL01', null, false, 'Z05 Risk Class High',
            '0003 - RCA - Regular Credit Account', 'On Time', null);
        acc.Credit_Exposure__c = 50000;
        insert acc;

        Test.startTest();

        // Attempt 1: set Recommended_Credit_Limit__c to 0 while Credit_Exposure__c (50000) is greater -> should fail
        Account accToZero = new Account(Id = acc.Id, Recommended_Credit_Limit__c = 0);
        try {
            update accToZero;
            System.assert(false, 'Expected a validation error when setting Recommended_Credit_Limit__c to 0 below Credit_Exposure__c');
        } catch (DmlException e) {
            System.assertEquals(StatusCode.FIELD_CUSTOM_VALIDATION_EXCEPTION, e.getDmlType(0),
                'Unexpected error type: ' + e.getMessage());
        }

        // Attempt 2: set Recommended_Credit_Limit__c to another number (20000) still below Credit_Exposure__c (50000) -> should fail
        Account accToLowerNumber = new Account(Id = acc.Id, Recommended_Credit_Limit__c = 20000);
        try {
            update accToLowerNumber;
            System.assert(false, 'Expected a validation error when setting Recommended_Credit_Limit__c below Credit_Exposure__c');
        } catch (DmlException e) {
            System.assertEquals(StatusCode.FIELD_CUSTOM_VALIDATION_EXCEPTION, e.getDmlType(0),
                'Unexpected error type: ' + e.getMessage());
        }

        Test.stopTest();
    }

    // Covers the allowed exception: Recommended_Credit_Limit__c = 0 is only valid when
    // Credit_Exposure__c = 0 AND Invoice_in_Last_12_Months__c = 0
    @isTest
    static void testRecommendedCreditLimitZeroAllowedWhenNoExposureAndNoInvoices() {
        Account acc = buildAccount('RCL02', null, false, 'Z05 Risk Class High',
            '0003 - RCA - Regular Credit Account', 'On Time', null);
        acc.Credit_Exposure__c = 0;
        acc.Invoice_in_Last_12_Months__c = 0;
        insert acc;

        Test.startTest();
        Account accToZero = new Account(Id = acc.Id, Recommended_Credit_Limit__c = 0);
        update accToZero; // should not throw
        Test.stopTest();

        Account updatedAcc = [SELECT Recommended_Credit_Limit__c FROM Account WHERE Id = :acc.Id];
        System.assertEquals(0, updatedAcc.Recommended_Credit_Limit__c,
            'Recommended_Credit_Limit__c should remain 0 when exposure and invoices are both 0');
    }

    // Covers the case where Credit_Exposure__c is non-zero but Invoice_in_Last_12_Months__c is 0:
    // setting Recommended_Credit_Limit__c to 0 must still fail, since BOTH fields need to be 0
    @isTest
    static void testRecommendedCreditLimitZeroRejectedWhenExposureNonZeroButInvoicesZero() {
        Account acc = buildAccount('RCL03', null, false, 'Z05 Risk Class High',
            '0003 - RCA - Regular Credit Account', 'On Time', null);
        acc.Credit_Exposure__c = 15000;
        acc.Invoice_in_Last_12_Months__c = 0;
        insert acc;

        Test.startTest();
        Account accToZero = new Account(Id = acc.Id, Recommended_Credit_Limit__c = 0);
        try {
            update accToZero;
            System.assert(false, 'Expected a validation error when Credit_Exposure__c is non-zero, even with Invoice_in_Last_12_Months__c at 0');
        } catch (DmlException e) {
            System.assertEquals(StatusCode.FIELD_CUSTOM_VALIDATION_EXCEPTION, e.getDmlType(0),
                'Unexpected error type: ' + e.getMessage());
        }
        Test.stopTest();
    }

    // Covers the case where Invoice_in_Last_12_Months__c is non-zero but Credit_Exposure__c is 0:
    // setting Recommended_Credit_Limit__c to 0 must still fail, since BOTH fields need to be 0
    @isTest
    static void testRecommendedCreditLimitZeroRejectedWhenInvoicesNonZeroButExposureZero() {
        Account acc = buildAccount('RCL04', null, false, 'Z05 Risk Class High',
            '0003 - RCA - Regular Credit Account', 'On Time', null);
        acc.Credit_Exposure__c = 0;
        acc.Invoice_in_Last_12_Months__c = 25000;
        insert acc;

        Test.startTest();
        Account accToZero = new Account(Id = acc.Id, Recommended_Credit_Limit__c = 0);
        try {
            update accToZero;
            System.assert(false, 'Expected a validation error when Invoice_in_Last_12_Months__c is non-zero, even with Credit_Exposure__c at 0');
        } catch (DmlException e) {
            System.assertEquals(StatusCode.FIELD_CUSTOM_VALIDATION_EXCEPTION, e.getDmlType(0),
                'Unexpected error type: ' + e.getMessage());
        }
        Test.stopTest();
    }

    // << END - Test Coverage for Recommended_Credit_Limit__c vs Credit_Exposure__c validation >>

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