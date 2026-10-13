@isTest
public class UpdateSegmentDataForAllApprovedCLRTest {

    @testSetup
    static void setupTestData() {

        // Create Credit Review records with different CreatedBy and status
        List<celsrm__Credit_Review__c> clrList = new List<celsrm__Credit_Review__c>();
        for (Integer i = 0; i < 5; i++) {
            clrList.add(new celsrm__Credit_Review__c(
                // Name = 'TestCLR_Admin_' + i,
                celsrm__Status__c = '11'
            ));
        }

        for (Integer i = 0; i < 5; i++) {
            clrList.add(new celsrm__Credit_Review__c(
                // Name = 'TestCLR_NonAdmin_' + i,
                celsrm__Status__c = '12'
            ));
        }

        insert clrList;
    }

    @isTest
    static void testBatchForAdmin() {
        List<String> excludeNames = new List<String>{'CR-0000001'};

        Test.startTest();
        UpdateSegmentDataForAllApprovedCLR batch = new UpdateSegmentDataForAllApprovedCLR(excludeNames, true);
        Database.executeBatch(batch, 10);
        Test.stopTest();

        // Add assertions as needed — for example, check that update service was called
    }

    @isTest
    static void testBatchForNonAdmin() {
        List<String> excludeNames = new List<String>{'CR-0000002'};

        Test.startTest();
        UpdateSegmentDataForAllApprovedCLR batch = new UpdateSegmentDataForAllApprovedCLR(excludeNames, false);
        Database.executeBatch(batch, 10);
        Test.stopTest();

        // Add assertions as needed — for example, check that update service was called
    }
}