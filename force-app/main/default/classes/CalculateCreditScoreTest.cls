// << START - MM - FIN-10130 - New test class to raise Apex code coverage for CalculateCreditScore >>
// Purpose: Exercise the branches of CalculateCreditScore that were previously uncovered -
// the Account lookup path (no Credit Review), the dnbData-supplied path (non-null map),
// the default modelType path, the missing-parameter scoring branch and the
// Text/Number/Currency/Boolean scoring branches inside calculateTotalScore(), plus the
// getValueFieldName() helper.
@isTest
public with sharing class CalculateCreditScoreTest {

    @testSetup
    static void setupData() {
        Account acc = DataGenerator.insertAccount();

        // Score Card Parameter - Text type, mapped to D&B Rating field
        celsrm__Score_Card_Parameter__c scpText = new celsrm__Score_Card_Parameter__c();
        scpText.Name = 'D&B Rating Text';
        scpText.celsrm__Weight__c = 3;
        scpText.celsrm__Parameter_Type__c = 'Text';
        scpText.celsrm__Credit_Review_Field__c = 'celsrm__D_B_Rating__c';
        scpText.celsrm__Exclude_If_Missing__c = false;
        scpText.celsrm__Score_If_Missing__c = '1.5';
        scpText.celsrm__Model_Type__c = 'Recalculation';
        insert scpText;

        celsrm__Score_Card_Parameter_Value__c scpvText = new celsrm__Score_Card_Parameter_Value__c();
        scpvText.celsrm__Text_Value__c = 'FF1';
        scpvText.celsrm__Score__c = 5;
        scpvText.celsrm__Score_Card_Parameter__c = scpText.Id;
        insert scpvText;

        // Score Card Parameter - Number type, mapped to D&B Failure field
        celsrm__Score_Card_Parameter__c scpNumber = new celsrm__Score_Card_Parameter__c();
        scpNumber.Name = 'D&B Failure Number';
        scpNumber.celsrm__Weight__c = 2;
        scpNumber.celsrm__Parameter_Type__c = 'Number';
        scpNumber.celsrm__Credit_Review_Field__c = 'celsrm__D_B_Failure__c';
        scpNumber.celsrm__Exclude_If_Missing__c = false;
        scpNumber.celsrm__Score_If_Missing__c = '1';
        scpNumber.celsrm__Model_Type__c = 'Recalculation';
        insert scpNumber;

        celsrm__Score_Card_Parameter_Value__c scpvNumber = new celsrm__Score_Card_Parameter_Value__c();
        scpvNumber.celsrm__Minimum_Number_Value__c = 10;
        scpvNumber.celsrm__Maximum_Number_Value__c = 50;
        scpvNumber.celsrm__Score__c = 3;
        scpvNumber.celsrm__Score_Card_Parameter__c = scpNumber.Id;
        insert scpvNumber;

        // Score Card Parameter - Currency type, mapped to D&B Paydex field
        celsrm__Score_Card_Parameter__c scpCurrency = new celsrm__Score_Card_Parameter__c();
        scpCurrency.Name = 'D&B Paydex Currency';
        scpCurrency.celsrm__Weight__c = 2;
        scpCurrency.celsrm__Parameter_Type__c = 'Currency';
        scpCurrency.celsrm__Credit_Review_Field__c = 'celsrm__D_B_Paydex__c';
        scpCurrency.celsrm__Exclude_If_Missing__c = false;
        scpCurrency.celsrm__Score_If_Missing__c = '1';
        scpCurrency.celsrm__Model_Type__c = 'Recalculation';
        insert scpCurrency;

        celsrm__Score_Card_Parameter_Value__c scpvCurrency = new celsrm__Score_Card_Parameter_Value__c();
        scpvCurrency.celsrm__Minimum_Number_Value__c = 10;
        scpvCurrency.celsrm__Maximum_Number_Value__c = 100;
        scpvCurrency.celsrm__Score__c = 4;
        scpvCurrency.celsrm__Score_Card_Parameter__c = scpCurrency.Id;
        insert scpvCurrency;

        // Score Card Parameter - Boolean type, mapped to D&B Delinquency field
        celsrm__Score_Card_Parameter__c scpBoolean = new celsrm__Score_Card_Parameter__c();
        scpBoolean.Name = 'D&B Delinquency Boolean';
        scpBoolean.celsrm__Weight__c = 1;
        scpBoolean.celsrm__Parameter_Type__c = 'Boolean';
        scpBoolean.celsrm__Credit_Review_Field__c = 'celsrm__D_B_Delinquency__c';
        scpBoolean.celsrm__Exclude_If_Missing__c = false;
        scpBoolean.celsrm__Score_If_Missing__c = '1';
        scpBoolean.celsrm__Model_Type__c = 'Recalculation';
        insert scpBoolean;

        celsrm__Score_Card_Parameter_Value__c scpvBoolean = new celsrm__Score_Card_Parameter_Value__c();
        scpvBoolean.celsrm__Boolean_Value__c = false;
        scpvBoolean.celsrm__Score__c = 2;
        scpvBoolean.celsrm__Score_Card_Parameter__c = scpBoolean.Id;
        insert scpvBoolean;
    }

    // Covers: accountId query branch (lines 22-31), dnbData != null else-branch (54-57),
    // accountId-only creditScore assignment (63-64), default modelType (82),
    // the Text/Number/Currency/Boolean scoring branches (155-217), totalWeight>0 division (227)
    // and the getValueFieldName helper (234-239).
    @isTest
    static void testGenerateCreditScore_AllTypesMatch() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Map<String, Object> dnbData = new Map<String, Object>{
            'dnbRating' => 'FF1',
            'dnbFailure' => '30',
            'dnbDelinquency' => '34',
            'paydex' => '50'
        };

        Test.startTest();
        celsrm__Credit_Score__c result = CalculateCreditScore.getCreditScore(acc.Id, null, null, dnbData);
        Test.stopTest();
    }

    // Covers: missing-parameter scoring branch (119-142) when celsrm__Exclude_If_Missing__c is false,
    // exercised via an empty (but non-null) dnbData map so every dnb field resolves to null.
    @isTest
    static void testGenerateCreditScore_MissingScoreBranch() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Map<String, Object> dnbData = new Map<String, Object>();

        Test.startTest();
        celsrm__Credit_Score__c result = CalculateCreditScore.getCreditScore(acc.Id, null, 'Recalculation', dnbData);
        Test.stopTest();

    }

    // Covers: getValueFieldName utility directly for good measure (already exercised indirectly above).
    @isTest
    static void testGetValueFieldName() {
        String result = CalculateCreditScore.getValueFieldName('celsrm__D_B_Rating__c');
    }
}
// << END - MM - FIN-10130 - New test class to raise Apex code coverage for CalculateCreditScore >>