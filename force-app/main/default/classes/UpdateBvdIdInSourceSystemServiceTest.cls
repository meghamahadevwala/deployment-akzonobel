@IsTest
public class UpdateBvdIdInSourceSystemServiceTest {

    @TestSetup
    static void setupData() {
        Account acc = new Account(
            Name = 'Test Account',
            AccountNumber = '1000922611'
        );
        insert acc;

        Credit_Configuration__c cfg = new Credit_Configuration__c(
            Update_Bvd_ID_Action_Flow_Webhook__c = 'dummyWebhook'
        );
        insert cfg;
    }

    @IsTest
    static void removeSuccessAddSuccess() {

        Account acc = [
            SELECT Id, AccountNumber
            FROM Account
            LIMIT 1
        ];

        List<Map<String, String>> refMapList = new List<Map<String, String>>{
            new Map<String, String>{
                'accountId' => acc.Id,
                'accountNumber' => acc.AccountNumber,
                'creditControlArea' => '1000',
                'oldBvdId' => 'ID001',
                'newBvdId' => 'ID002'
            }
        };

        // ✅ Set mock (inner class)
        Test.setMock(HttpCalloutMock.class, new removeSuccessAddSuccess());

        Test.startTest();
            System.enqueueJob(
                new UpdateBvdIdInSourceSystemService(refMapList)
            );
        Test.stopTest();

        Account updatedAcc = [
            SELECT
                Remove_BvD_ID_From_CFIN_At__c,
                Remove_BvD_ID_From_CFIN_Message__c,
                Sync_BVD_ID_In_CFIN_At__c,
                Sync_BVD_ID_Messge__c,
                BVD_IDs_To_Be_Removed__c
            FROM Account
            WHERE Id = :acc.Id
        ];

        System.assertEquals(
            'Update successful',
            updatedAcc.Remove_BvD_ID_From_CFIN_Message__c
        );

        System.assertEquals(
            'Update successful',
            updatedAcc.Sync_BVD_ID_Messge__c
        );

        System.assertNotEquals(
            null,
            updatedAcc.Remove_BvD_ID_From_CFIN_At__c
        );

        System.assertNotEquals(
            null,
            updatedAcc.Sync_BVD_ID_In_CFIN_At__c
        );

        System.assertEquals(
            null,
            updatedAcc.BVD_IDs_To_Be_Removed__c
        );
    }

    @IsTest
    static void removeFailedAddSuccess() {

        Account acc = [
            SELECT Id, AccountNumber
            FROM Account
            LIMIT 1
        ];
        acc.BVD_IDs_To_Be_Removed__c = 'ID000';
        update acc;
        System.debug('BVD_IDs_To_Be_Removed__c::' + acc.BVD_IDs_To_Be_Removed__c);

        List<Map<String, String>> refMapList = new List<Map<String, String>>{
            new Map<String, String>{
                'accountId' => acc.Id,
                'accountNumber' => acc.AccountNumber,
                'creditControlArea' => '1000',
                'oldBvdId' => 'ID001',
                'newBvdId' => 'ID002'
            }
        };

        // ✅ Set mock (inner class)
        Test.setMock(HttpCalloutMock.class, new removeFailedAddSuccess());

        Test.startTest();
            System.enqueueJob(
                new UpdateBvdIdInSourceSystemService(refMapList)
            );
        Test.stopTest();

        Account updatedAcc = [
            SELECT
                Remove_BvD_ID_From_CFIN_At__c,
                Remove_BvD_ID_From_CFIN_Message__c,
                Sync_BVD_ID_In_CFIN_At__c,
                Sync_BVD_ID_Messge__c,
                BVD_IDs_To_Be_Removed__c
            FROM Account
            WHERE Id = :acc.Id
        ];

        System.assertEquals(
            'failed to remove',
            updatedAcc.Remove_BvD_ID_From_CFIN_Message__c
        );

        System.assertEquals(
            'Update successful',
            updatedAcc.Sync_BVD_ID_Messge__c
        );

        System.assertEquals(
            null,
            updatedAcc.Remove_BvD_ID_From_CFIN_At__c
        );

        System.assertNotEquals(
            null,
            updatedAcc.Sync_BVD_ID_In_CFIN_At__c
        );

        System.assertEquals(
            'ID000,ID001',
            updatedAcc.BVD_IDs_To_Be_Removed__c
        );
    }

    @IsTest
    static void error401() {

        Account acc = [
            SELECT Id, AccountNumber
            FROM Account
            LIMIT 1
        ];

        List<Map<String, String>> refMapList = new List<Map<String, String>>{
            new Map<String, String>{
                'accountId' => acc.Id,
                'accountNumber' => acc.AccountNumber,
                'creditControlArea' => '1000',
                'oldBvdId' => 'ID001',
                'newBvdId' => 'ID002'
            }
        };

        // ✅ Set mock (inner class)
        Test.setMock(HttpCalloutMock.class, new errorResponse(401));

        Test.startTest();
            System.enqueueJob(
                new UpdateBvdIdInSourceSystemService(refMapList)
            );
        Test.stopTest();

        Account updatedAcc = [
            SELECT
                Remove_BvD_ID_From_CFIN_At__c,
                Remove_BvD_ID_From_CFIN_Message__c,
                Sync_BVD_ID_In_CFIN_At__c,
                Sync_BVD_ID_Messge__c,
                BVD_IDs_To_Be_Removed__c
            FROM Account
            WHERE Id = :acc.Id
        ];

        System.assertNotEquals(
            'Update successful',
            updatedAcc.Remove_BvD_ID_From_CFIN_Message__c
        );

        System.assertNotEquals(
            'Update successful',
            updatedAcc.Sync_BVD_ID_Messge__c
        );

        System.assertEquals(
            null,
            updatedAcc.Remove_BvD_ID_From_CFIN_At__c
        );

        System.assertEquals(
            null,
            updatedAcc.Sync_BVD_ID_In_CFIN_At__c
        );

        System.assertEquals(
            'ID001',
            updatedAcc.BVD_IDs_To_Be_Removed__c
        );
    }

    @IsTest
    static void error500() {

        Account acc = [
            SELECT Id, AccountNumber
            FROM Account
            LIMIT 1
        ];

        List<Map<String, String>> refMapList = new List<Map<String, String>>{
            new Map<String, String>{
                'accountId' => acc.Id,
                'accountNumber' => acc.AccountNumber,
                'creditControlArea' => '1000',
                'oldBvdId' => 'ID001',
                'newBvdId' => 'ID002'
            }
        };

        // ✅ Set mock (inner class)
        Test.setMock(HttpCalloutMock.class, new errorResponse(500));

        Test.startTest();
            System.enqueueJob(
                new UpdateBvdIdInSourceSystemService(refMapList)
            );
        Test.stopTest();

        Account updatedAcc = [
            SELECT
                Remove_BvD_ID_From_CFIN_At__c,
                Remove_BvD_ID_From_CFIN_Message__c,
                Sync_BVD_ID_In_CFIN_At__c,
                Sync_BVD_ID_Messge__c,
                BVD_IDs_To_Be_Removed__c
            FROM Account
            WHERE Id = :acc.Id
        ];

        System.assertNotEquals(
            'Update successful',
            updatedAcc.Remove_BvD_ID_From_CFIN_Message__c
        );

        System.assertNotEquals(
            'Update successful',
            updatedAcc.Sync_BVD_ID_Messge__c
        );

        System.assertEquals(
            null,
            updatedAcc.Remove_BvD_ID_From_CFIN_At__c
        );

        System.assertEquals(
            null,
            updatedAcc.Sync_BVD_ID_In_CFIN_At__c
        );

        System.assertEquals(
            'ID001',
            updatedAcc.BVD_IDs_To_Be_Removed__c
        );
    }

    @IsTest
    static void error429() {

        Account acc = [
            SELECT Id, AccountNumber
            FROM Account
            LIMIT 1
        ];

        List<Map<String, String>> refMapList = new List<Map<String, String>>{
            new Map<String, String>{
                'accountId' => acc.Id,
                'accountNumber' => acc.AccountNumber,
                'creditControlArea' => '1000',
                'oldBvdId' => 'ID001',
                'newBvdId' => 'ID002'
            }
        };

        // ✅ Set mock (inner class)
        Test.setMock(HttpCalloutMock.class, new errorResponse(429));

        Test.startTest();
            System.enqueueJob(
                new UpdateBvdIdInSourceSystemService(refMapList)
            );
        Test.stopTest();

        Account updatedAcc = [
            SELECT
                Remove_BvD_ID_From_CFIN_At__c,
                Remove_BvD_ID_From_CFIN_Message__c,
                Sync_BVD_ID_In_CFIN_At__c,
                Sync_BVD_ID_Messge__c,
                BVD_IDs_To_Be_Removed__c
            FROM Account
            WHERE Id = :acc.Id
        ];

        System.assertNotEquals(
            'Update successful',
            updatedAcc.Remove_BvD_ID_From_CFIN_Message__c
        );

        System.assertNotEquals(
            'Update successful',
            updatedAcc.Sync_BVD_ID_Messge__c
        );

        System.assertEquals(
            null,
            updatedAcc.Remove_BvD_ID_From_CFIN_At__c
        );

        System.assertEquals(
            null,
            updatedAcc.Sync_BVD_ID_In_CFIN_At__c
        );

        System.assertEquals(
            'ID001',
            updatedAcc.BVD_IDs_To_Be_Removed__c
        );
    }

    @IsTest
    static void error450() {

        Account acc = [
            SELECT Id, AccountNumber
            FROM Account
            LIMIT 1
        ];

        List<Map<String, String>> refMapList = new List<Map<String, String>>{
            new Map<String, String>{
                'accountId' => acc.Id,
                'accountNumber' => acc.AccountNumber,
                'creditControlArea' => '1000',
                'oldBvdId' => 'ID001',
                'newBvdId' => 'ID002'
            }
        };

        // ✅ Set mock (inner class)
        Test.setMock(HttpCalloutMock.class, new errorResponse(450));

        Test.startTest();
            System.enqueueJob(
                new UpdateBvdIdInSourceSystemService(refMapList)
            );
        Test.stopTest();

        Account updatedAcc = [
            SELECT
                Remove_BvD_ID_From_CFIN_At__c,
                Remove_BvD_ID_From_CFIN_Message__c,
                Sync_BVD_ID_In_CFIN_At__c,
                Sync_BVD_ID_Messge__c,
                BVD_IDs_To_Be_Removed__c
            FROM Account
            WHERE Id = :acc.Id
        ];

        System.assertNotEquals(
            'Update successful',
            updatedAcc.Remove_BvD_ID_From_CFIN_Message__c
        );

        System.assertNotEquals(
            'Update successful',
            updatedAcc.Sync_BVD_ID_Messge__c
        );

        System.assertEquals(
            null,
            updatedAcc.Remove_BvD_ID_From_CFIN_At__c
        );

        System.assertEquals(
            null,
            updatedAcc.Sync_BVD_ID_In_CFIN_At__c
        );

        System.assertEquals(
            'ID001',
            updatedAcc.BVD_IDs_To_Be_Removed__c
        );
    }


    // ✅ Inner mock class (NOT global)
    private class removeSuccessAddSuccess implements HttpCalloutMock {

        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody(
                '{"details":{"updateResponse":[' +
                '{"PARTNER":"1000922611","STATUS_MSG":"Update successful","LV_IDENTIFICATIONNUMBER":"ID001","DELETE":"X"},' +
                '{"PARTNER":"1000922611","STATUS_MSG":"Update successful","LV_IDENTIFICATIONNUMBER":"ID002","DELETE":""}' +
                ']}}'
            );
            return res;
        }
    }

    private class removeFailedAddSuccess implements HttpCalloutMock {

        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody(
                '{"details":{"updateResponse":[' +
                '{"PARTNER":"1000922611","STATUS_MSG":"failed to remove","LV_IDENTIFICATIONNUMBER":"ID001","DELETE":"X"},' +
                '{"PARTNER":"1000922611","STATUS_MSG":"Update successful","LV_IDENTIFICATIONNUMBER":"ID002","DELETE":""}' +
                ']}}'
            );
            return res;
        }
    }

    private class errorResponse implements HttpCalloutMock {
        private Integer status;
        public errorResponse(Integer status) {
            this.status = status;
        }
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(this.status);
            res.setBody(
                '{"details":"failed to process"}'
            );
            return res;
        }
    }
}