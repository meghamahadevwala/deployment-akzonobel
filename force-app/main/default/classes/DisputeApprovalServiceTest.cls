@isTest
public class DisputeApprovalServiceTest {
    @testSetup
    static void setup() {
        // Create Account
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        // Create Transaction
        celsrm__Transaction__c trx = new celsrm__Transaction__c(
            Name = 'TRX-001',
            celsrm__Account__c = acc.Id,
            celsrm__Amount__c = 100,
            celsrm__Balance__c = 100
        );
        insert trx;
        // Create Dispute Configuration
        celsrm__Dispute_Configuration__c config = new celsrm__Dispute_Configuration__c(
            Name = 'Default',
            celsrm__Dispute_Closure_Status__c = 'Approved,Rejected,Auto Closed,Cancelled',
            celsrm__Dispute_Resolver_Type__c = 'Account_Owner'
        );
        insert config;
        // Create Dispute
        celsrm__Dispute__c dispute = new celsrm__Dispute__c(
            celsrm__Status__c = 'Pending Approval',
            celsrm__Dispute_Type__c = '100 Financial & Invoicing',
            celsrm__Reason_Code__c = '101 Cash Discount Deduction',
            celsrm__Amount__c = 100,
            celsrm__Account__c = acc.Id,
            celsrm__Transaction__c = trx.Id
        );
        insert dispute;
        //-- Start | FIN-10143 | Changed by Asera | 20-Jul-2026 --//
        celsrm__User_Master__c externalUserMaster = new celsrm__User_Master__c(
            Name = 'Test User',
            celsrm__Email__c = 'testuser@example.com',
            celsrm__Is_External_User__c = true
        );
        insert externalUserMaster;
        celsrm__Dispute_Workflow_Details__c dwd = new celsrm__Dispute_Workflow_Details__c(
            celsrm__Dispute__c = dispute.Id,
            celsrm__User_Master__c = externalUserMaster.Id,
            celsrm__Status__c = 'Pending'
        );
        //-- End | FIN-10143 | Changed by Asera | 20-Jul-2026 --//
        insert dwd;
    }

    @isTest
    static void testProcessDisputeActionApprove() {
        try {
            celsrm__Dispute__c dispute = [SELECT Id FROM celsrm__Dispute__c LIMIT 1];
            String body = '{"action":"Approve","recordId":"' + dispute.Id + '","note":"Test note","userEmail":"testuser@example.com"}';
            RestRequest req = new RestRequest();
            req.requestUri = '/services/apexrest/DisputeApprovalService/';
            req.httpMethod = 'POST';
            req.requestBody = Blob.valueOf(body);
            RestContext.request = req;
            RestContext.response = new RestResponse();
            String result = DisputeApprovalService.processDisputeAction();
        } catch (Exception e) {
            System.debug('Exception: ' + e.getMessage());
        }
    }

    @isTest
    static void testProcessDisputeActionReject() {
        try {
            celsrm__Dispute__c dispute = [SELECT Id FROM celsrm__Dispute__c LIMIT 1];
            String body = '{"action":"Reject","recordId":"' + dispute.Id + '","note":"Test note","userEmail":"testuser@example.com"}';
            RestRequest req = new RestRequest();
            req.requestUri = '/services/apexrest/DisputeApprovalService/';
            req.httpMethod = 'POST';
            req.requestBody = Blob.valueOf(body);
            RestContext.request = req;
            RestContext.response = new RestResponse();
            String result = DisputeApprovalService.processDisputeAction();
        } catch (Exception e) {
            System.debug('Exception: ' + e.getMessage());
        }
    }

    @isTest
    static void testProcessDisputeActionDisputeNotFound() {
        try {
            String body = '{"action":"Approve","recordId":"a0X000000000000AAA","note":"Test note","userEmail":"testuser@example.com"}';
            RestRequest req = new RestRequest();
            req.requestUri = '/services/apexrest/DisputeApprovalService/';
            req.httpMethod = 'POST';
            req.requestBody = Blob.valueOf(body);
            RestContext.request = req;
            RestContext.response = new RestResponse();
            String result = DisputeApprovalService.processDisputeAction();
        } catch (Exception e) {
            System.debug('Exception: ' + e.getMessage());
        }
    }

    @isTest
    static void testProcessDisputeActionAlreadyClosed() {
        try {
            celsrm__Dispute__c dispute = [SELECT Id FROM celsrm__Dispute__c LIMIT 1];
            dispute.celsrm__Status__c = 'Approved';
            update dispute;
            String body = '{"action":"Approve","recordId":"' + dispute.Id + '","note":"Test note","userEmail":"testuser@example.com"}';
            RestRequest req = new RestRequest();
            req.requestUri = '/services/apexrest/DisputeApprovalService/';
            req.httpMethod = 'POST';
            req.requestBody = Blob.valueOf(body);
            RestContext.request = req;
            RestContext.response = new RestResponse();
            String result = DisputeApprovalService.processDisputeAction();
        } catch (Exception e) {
            System.debug('Exception: ' + e.getMessage());
        }
    }

    @isTest
    static void testProcessDisputeActionUnauthorized() {
        try {
            celsrm__Dispute__c dispute = [SELECT Id FROM celsrm__Dispute__c LIMIT 1];
            String body = '{"action":"Approve","recordId":"' + dispute.Id + '","note":"Test note","userEmail":"unauthorized@example.com"}';
            RestRequest req = new RestRequest();
            req.requestUri = '/services/apexrest/DisputeApprovalService/';
            req.httpMethod = 'POST';
            req.requestBody = Blob.valueOf(body);
            RestContext.request = req;
            RestContext.response = new RestResponse();
            String result = DisputeApprovalService.processDisputeAction();
        } catch (Exception e) {
            System.debug('Exception: ' + e.getMessage());
        }
    }

    @isTest
    static void testProcessDisputeActionMissingData() {
        try {
            String body = '{"action":null,"recordId":null,"note":"Test note","userEmail":null}';
            RestRequest req = new RestRequest();
            req.requestUri = '/services/apexrest/DisputeApprovalService/';
            req.httpMethod = 'POST';
            req.requestBody = Blob.valueOf(body);
            RestContext.request = req;
            RestContext.response = new RestResponse();
            String result = DisputeApprovalService.processDisputeAction();
        } catch (Exception e) {
            System.debug('Exception: ' + e.getMessage());
        }
    }
}