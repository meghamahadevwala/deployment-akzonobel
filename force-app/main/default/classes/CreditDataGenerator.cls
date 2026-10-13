public with sharing class CreditDataGenerator {
    public static Account insertAccount() {
        Account acc = new Account();
        acc.Name = 'Test Account';
        acc.celsrm__Credit_Control_Area__c = 'EMEA';
        insert acc;
        return acc;
    }
    public static celsrm__Credit_Review__c insertCreditReview(Account acc) {
        celsrm__Credit_Review__c creditReview = new celsrm__Credit_Review__c();
        creditReview.celsrm__Status__c = 'Pending';
        creditReview.celsrm__Requested_Credit_Limit__c = 95000;
        creditReview.celsrm__Requested_Credit_Limit_Group_Currency__c = 95000;
        creditReview.celsrm__Account__c = acc.Id;
        insert creditReview;
        return creditReview;
    }

    public static celsrm__Credit_Configuration__c insertCreditConfiguration() {
        celsrm__Credit_Configuration__c cc = new celsrm__Credit_Configuration__c();
        cc.celsrm__Use_Credit_Limit_Approval_Matrix__c = true;
        cc.celsrm__Credit_Limit_Auto_Approve_Threshold__c = 10000;
        cc.celsrm__Owner_Can_Act_on_Queue_Reviews__c = true;
        insert cc;
        return cc;
    }


    public static void insertScoreCardParameters(String matrixType) {
        // Create only one Score Card Parameter for D&B rating
        List<celsrm__Score_Card_Parameter__c> params = new List<celsrm__Score_Card_Parameter__c>();
        List<celsrm__Score_Card_Parameter_Value__c> values = new List<celsrm__Score_Card_Parameter_Value__c>();

        celsrm__Score_Card_Parameter__c param = new celsrm__Score_Card_Parameter__c();
        param.Name = 'D&B Rating Score';
        param.celsrm__Weight__c = 100;
        param.celsrm__Parameter_Type__c = 'Text';
        param.celsrm__Exclude_If_Missing__c = false;
        param.celsrm__Score_If_Missing__c = null;
        param.celsrm__Model_Type__c = matrixType;
        param.celsrm__Credit_Review_Field__c = 'celsrm__D_B_Rating__c';
        param.celsrm__Credit_Score_Field__c = 'celsrm__D_B_Rating_Score__c';
        params.add(param);

        // Values for D_B_Rating
        celsrm__Score_Card_Parameter_Value__c val1 = new celsrm__Score_Card_Parameter_Value__c();
        val1.celsrm__Text_Value__c = 'FF1';
        val1.celsrm__Score__c = 5;
        values.add(val1);

        celsrm__Score_Card_Parameter_Value__c val2 = new celsrm__Score_Card_Parameter_Value__c();
        val2.celsrm__Text_Value__c = 'BB';
        val2.celsrm__Score__c = 6;
        values.add(val2);

        celsrm__Score_Card_Parameter_Value__c val3 = new celsrm__Score_Card_Parameter_Value__c();
        val3.celsrm__Text_Value__c = 'CC';
        val3.celsrm__Score__c = 7;
        values.add(val3);

        insert params;

        // Set parent IDs for values
        val1.celsrm__Score_Card_Parameter__c = param.Id;
        val2.celsrm__Score_Card_Parameter__c = param.Id;
        val3.celsrm__Score_Card_Parameter__c = param.Id;

        insert values;
    }
}