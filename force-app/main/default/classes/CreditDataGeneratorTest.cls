@isTest
public class CreditDataGeneratorTest {

    @isTest
    static void testInsertAccount() {
        Test.startTest();
        Account acc = CreditDataGenerator.insertAccount();
        Test.stopTest();

        Account inserted = [SELECT Id, Name, celsrm__Credit_Control_Area__c FROM Account WHERE Id = :acc.Id];
        System.assertNotEquals(null, inserted.Id, 'Account should be inserted');
        System.assertEquals('Test Account', inserted.Name);
        System.assertEquals('EMEA', inserted.celsrm__Credit_Control_Area__c);
    }

    @isTest
    static void testInsertCreditReview() {
        Account acc = CreditDataGenerator.insertAccount();

        Test.startTest();
        celsrm__Credit_Review__c cr = CreditDataGenerator.insertCreditReview(acc);
        Test.stopTest();

        celsrm__Credit_Review__c inserted = [
            SELECT Id, celsrm__Status__c, celsrm__Requested_Credit_Limit__c,
                   celsrm__Requested_Credit_Limit_Group_Currency__c, celsrm__Account__c
            FROM celsrm__Credit_Review__c
            WHERE Id = :cr.Id
        ];
        System.assertNotEquals(null, inserted.Id, 'Credit Review should be inserted');
        System.assertEquals('Pending', inserted.celsrm__Status__c);
        System.assertEquals(95000, inserted.celsrm__Requested_Credit_Limit__c);
        System.assertEquals(95000, inserted.celsrm__Requested_Credit_Limit_Group_Currency__c);
        System.assertEquals(acc.Id, inserted.celsrm__Account__c);
    }

    @isTest
    static void testInsertCreditConfiguration() {
        Test.startTest();
        celsrm__Credit_Configuration__c cc = CreditDataGenerator.insertCreditConfiguration();
        Test.stopTest();

        celsrm__Credit_Configuration__c inserted = [
            SELECT Id, celsrm__Use_Credit_Limit_Approval_Matrix__c,
                   celsrm__Credit_Limit_Auto_Approve_Threshold__c,
                   celsrm__Owner_Can_Act_on_Queue_Reviews__c
            FROM celsrm__Credit_Configuration__c
            WHERE Id = :cc.Id
        ];
        System.assertNotEquals(null, inserted.Id, 'Credit Configuration should be inserted');
        System.assertEquals(true, inserted.celsrm__Use_Credit_Limit_Approval_Matrix__c);
        System.assertEquals(10000, inserted.celsrm__Credit_Limit_Auto_Approve_Threshold__c);
        System.assertEquals(true, inserted.celsrm__Owner_Can_Act_on_Queue_Reviews__c);
    }

    @isTest
    static void testInsertScoreCardParameters() {
        Test.startTest();
        CreditDataGenerator.insertScoreCardParameters('Recalculation');
        Test.stopTest();

        List<celsrm__Score_Card_Parameter__c> params = [
            SELECT Id, Name, celsrm__Model_Type__c, celsrm__Credit_Review_Field__c, celsrm__Credit_Score_Field__c
            FROM celsrm__Score_Card_Parameter__c
        ];
        System.assertEquals(1, params.size(), 'One score card parameter should be created');
        System.assertEquals('Recalculation', params[0].celsrm__Model_Type__c);

        List<celsrm__Score_Card_Parameter_Value__c> values = [
            SELECT Id, celsrm__Text_Value__c, celsrm__Score__c, celsrm__Score_Card_Parameter__c
            FROM celsrm__Score_Card_Parameter_Value__c
            WHERE celsrm__Score_Card_Parameter__c = :params[0].Id
        ];
        System.assertEquals(3, values.size(), 'Three score card parameter values should be created');
    }
}