@isTest
public with sharing class CalculateImpactedAmountBatchTest {

    public static testmethod void test1() {
        User thisUser = [select Id from User where Id =: UserInfo.getUserId()];
        
        Account acc = new Account();
        acc.Name = 'Test Account';
        acc.celsrm__Account_Key__c =''+(Math.random()* 1000000).intValue() + (Math.random()* 1000000).intValue();
        acc.celsrm__Locale__c = 'English (United Kingdom)';
        acc.celsrm__Average_DPD__c = 10;
        acc.celsrm__Total_Past_Due__c = 1000;
        insert acc;

        
        
        celsrm__Transaction__c trans1 = new celsrm__Transaction__c();
        System.runAs(thisUser) {
            Date promiseDate = System.today().addDays(-30);
            trans1.Name = 'Test trans1';
            trans1.celsrm__Account__c = acc.Id;
            trans1.celsrm__Balance__c = 1000;
            trans1.celsrm__Base_Balance__c = 1000;
            trans1.celsrm__Amount__c = 1000;
            trans1.celsrm__Promised_Amount__c = 1000;
            trans1.celsrm__Promise_Date__c = promiseDate;
            trans1.celsrm__Broken_Promise_Amount__c = 1000;
            trans1.celsrm__Close_Date__c = NULL;
            trans1.celsrm__Due_Date__c = System.today().addDays(30);
            insert trans1;
        }
        system.debug('trans1:'+trans1);
        celsrm__Transaction__c trans2 = new celsrm__Transaction__c();
        System.runAs(thisUser) {
            Date promiseDate = Date.newInstance(2024, 3, 8);
            trans2.Name = 'Test trans2';
            trans2.celsrm__Account__c = acc.Id;
            trans2.celsrm__Balance__c = 1000;
            trans2.celsrm__Base_Balance__c = 1000;
            trans2.celsrm__Amount__c = 10000;
            trans2.celsrm__Disputed_Amount__c = 1000;
            trans2.celsrm__Close_Date__c = null;
            trans2.celsrm__Due_Date__c = System.today().addDays(30);
            insert trans2;
        }
        system.debug('trans2:'+trans2);
        celsrm__Transaction__c trans3 = new celsrm__Transaction__c();
        System.runAs(thisUser) {
            Date promiseDate = Date.newInstance(2024, 3, 8);
            trans3.Name = 'Test trans3';
            trans3.celsrm__Account__c = acc.Id;
            trans3.celsrm__Balance__c = 121;
            trans3.celsrm__Base_Balance__c = 121;
            trans3.celsrm__Amount__c = 10000;
            trans3.celsrm__Due_Date__c = System.today().addDays(-30);
            trans3.celsrm__Close_Date__c = null;
            insert trans3;
        }
        system.debug('trans3:'+trans3);
        List<celsrm__Transaction__c> abc = [SELECT Id,Name,Impacted_Amount__c,Impacted_Amount_Reason__c FROM celsrm__Transaction__c];
        system.debug('abc:'+abc);
        CalculateImpactedAmountBatch impactedAmountBatch = new CalculateImpactedAmountBatch();
        database.ExecuteBatch(impactedAmountBatch ,1);

    }
}