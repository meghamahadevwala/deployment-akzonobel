@isTest
public with sharing class DisputeActionControllerTest {
    public static testMethod void testMethod1() {
        Account acc = DataGenerator.insertAccount();
        celsrm__Transaction__c trans = DataGenerator.insertTransaction(acc);
        EmailMessage eMsg = DataGenerator.insertEmailMsgForClassification(acc.Id, trans.Name);
        List<celsrm__Dispute__c> dispute = DataGenerator.insertDispute(trans, acc, 2);
        // START - MM - FIN-7983 - Test Coverage
        // List<celsrm__Dispute_Workflow_Matrix__c> dwmList = DataGenerator.insertDisputeWorkflowMatrix('Billing', 'Tax rate incorrect');
        List<celsrm__Dispute_Workflow_Matrix__c> dwmList = DataGenerator.insertDisputeWorkflowMatrix('100 Financial & Invoicing', '101 Cash Discount Deduction');
        // END - MM - FIN-7983 - Test Coverage
        celsrm__Dispute_Workflow_Matrix__c dwm = [SELECT Id FROM celsrm__Dispute_Workflow_Matrix__c where celsrm__Level__c = 0 ];
        celsrm__Dispute_Workflow_Details__c dwd = DataGenerator.insertDisputeWorkflowDetails(dwm, dispute[0], 'Pending', 'Resolve');
        List<ContentDocument> cdList = DataGenerator.insertContentDoc();
        celsrm__Dispute_Configuration__c disputeConfig = new celsrm__Dispute_Configuration__c();
        insert disputeConfig;

        Map<Object, Object> inMap = new Map<Object, Object>();
        inMap.put('Id', dispute[0].Id);
        // START - MM - FIN-7983 - Test Coverage
        // inMap.put('selectedReasonCode', 'Tax rate incorrect');
        // inMap.put('selectedType', 'Billing');
        inMap.put('selectedReasonCode', '101 Cash Discount Deduction');
        inMap.put('selectedType', '100 Financial & Invoicing');
        // END - MM - FIN-7983 - Test Coverage
        Map<Object, Object> invMap = new Map<Object, Object>();
        invMap.put('id', trans.Id);
        invMap.put('name', trans.Name);
        inMap.put('invoiceNumber', invMap);

        DisputeActionController disputeController = new DisputeActionController();
        disputeController.invoke('onChangeReasonCode', inMap);
        disputeController.invoke('reverseDisputeFromDisputeDetail', inMap);
        // Convert trans into a Map<String, Object>
        Map<Object, Object> transMap = new Map<Object, Object>();
        transMap.put('Id', trans.Id);
        transMap.put('celsrm__Account__c', trans.celsrm__Account__c);
        //transMap.put('celsrm__Balance__c', trans.celsrm__Balance__c);
        transMap.put('celsrm__Amount__c', trans.celsrm__Amount__c);
        transMap.put('celsrm__Promised_Amount__c', trans.celsrm__Promised_Amount__c);
        transMap.put('DisputeAmount', 1000);
        // START - MM - FIN-7983 - Test Coverage
        // transMap.put('disputeType', 'Billing');
        // transMap.put('reasonCode', 'Tax rate incorrect');
        transMap.put('disputeType', '100 Financial & Invoicing');
        transMap.put('reasonCode', '101 Cash Discount Deduction');
        // END - MM - FIN-7983 - Test Coverage
        transMap.put('totalSLADays', 2);
        transMap.put('disputeAmount', 200);
        inMap.put('Id', acc.Id); 
        inMap.put('NoteBody', 'Test Note'); 
        inMap.put('Status', 'Open');  
        inMap.put('ContactMehods', 'Email');   
        // Add other transaction details as required by your controller
        inMap.put('TransactionList', new List<Map<Object, Object>>{transMap});
        disputeController.invoke('onLoadCreateDisputeScreen', inMap);

        transMap.put('celsrm__Balance__c', trans.celsrm__Balance__c);
        inMap.put('TransactionList', new List<Map<Object, Object>>{transMap});
        Map<Object, Object> activityData = new Map<Object, Object>();
        activityData.put('Id', eMsg.Id);
        inMap.put('activityData', activityData);
        disputeController.invoke('onLoadCreateDisputeScreen', inMap);
        // disputeController.invoke('saveDispute', inMap);
        

        inMap.put('selectedReasonCode', '');
        inMap.put('selectedType', '');
        disputeController.invoke('onChangeReasonCode', inMap);

        inMap.put('Id', trans.Id); 
        inMap.put('calledFromTransactionDetailScreen', true);
        inMap.put('celsrm__Account__c', acc.Id);
        disputeController.invoke('onLoadCreateDisputeScreen', inMap);

        //-- Dispute Resolver Type is Logged_In_User --//
        disputeConfig.celsrm__Dispute_Resolver_Type__c = 'Logged_In_User';
        update disputeConfig;
        inMap.put('Id', trans.Id); 
        inMap.put('calledFromTransactionDetailScreen', true);
        inMap.put('celsrm__Account__c', acc.Id);
        disputeController.invoke('onLoadCreateDisputeScreen', inMap);

        //-- Dispute Resolver Type is Dispute_Workflow_Matrix --//
        System.debug('Dispute Resolver Type is Dispute_Workflow_Matrix');
        disputeConfig.celsrm__Dispute_Resolver_Type__c = 'Dispute_Workflow_Matrix';
        update disputeConfig;
        inMap.put('disputeResolverType', 'Dispute_Workflow_Matrix');
        // START - MM - FIN-7983 - Test Coverage
        // inMap.put('selectedReasonCode', 'Billing');
        // inMap.put('selectedType', 'Tax rate incorrect');
        inMap.put('selectedReasonCode', '100 Financial & Invoicing');
        inMap.put('selectedType', '101 Cash Discount Deduction');
        // END - MM - FIN-7983 - Test Coverage
        disputeController.invoke('onChangeReasonCode', inMap);

        //-- Starts | FIN-8207 | Change by Asera | 04-Sep-25 //
        // celsrm__Dispute_Workflow_Matrix__c dwm1 = new celsrm__Dispute_Workflow_Matrix__c();
        // dwm1.celsrm__User__c = UserInfo.getUserId();
        // dwm1.celsrm__User_Type__c = 'approver';
        // dwm1.celsrm__Optional__c = false;
        // dwm1.celsrm__Level__c = 1;
        // dwm1.celsrm__User_SLA_Days__c = 2;
        // dwm1.celsrm__Dispute_Type__c = '*';
        // dwm1.celsrm__Reason_Code__c = 'Tax rate incorrect';
        // dwm1.celsrm__Is_Active__c = true;
        // insert dwm1;
        //-- End | FIN-8207 | Change by Asera | 04-Sep-25 //

        inMap.put('disputeResolverType', 'Dispute_Workflow_Matrix');
        inMap.put('selectedReasonCode', '');
        inMap.put('selectedType', '');
        disputeController.invoke('onChangeReasonCode', inMap);
        

        

        List<Object> attachments = new List<Object>();
        Map<Object,Object> attachmentMap = new Map<Object,Object>();
        attachmentMap.put('ContentDocumentId', cdList[0].Id);
        attachments.add(attachmentMap);
        transMap.put('attachments', attachments);

        inMap.put('TransactionList', new List<Map<Object, Object>>{transMap});
        inMap.put('isFollowUp', true);
        inMap.put('ListView', null);
        inMap.put('FollowUpDate', '2023-06-30');
        disputeController.invoke('saveDispute', inMap);

        Map<Object, Object> disMap = new Map<Object, Object>();
        disMap.put('isSelected', true);
        disMap.put('Id', dispute[0].Id);
        disMap.put('invoiceId', dispute[0].celsrm__Transaction__c);
        inMap.put('DisputeList', new List<Map<Object, Object>>{disMap});
        disputeController.invoke('updateReverseDispute', inMap);
        disputeController.invoke('getTransactionListFromActivity', inMap);

        disputeController.invoke('fetchOpenDisputesForTransaction', inMap);
        //-- Starts | FIN-8207 | Change by Asera | 04-Sep-25 //
        disputeController.invoke('getDisputeTypeOptions', inMap);
        disputeController.invoke('getReasonCodeOptions', inMap);
        //-- End | FIN-8207 | Change by Asera | 04-Sep-25 //
    } 

    
    public static testMethod void testFullCoverage() {
        // Setup
        Account acc = DataGenerator.insertAccount();
        celsrm__Transaction__c trans = DataGenerator.insertTransaction(acc);
        List<celsrm__Transaction__c> transList = DataGenerator.transactionInsert(acc, 2);
        EmailMessage eMsg = DataGenerator.insertEmailMsgForClassification(acc.Id, trans.Name);
        List<ContentDocument> cdList = DataGenerator.insertContentDoc();
        
        celsrm__Dispute_Configuration__c disputeConfig = celsrm__Dispute_Configuration__c.getOrgDefaults();
        disputeConfig.SetupOwnerId = UserInfo.getOrganizationId();
        disputeConfig.celsrm__Allow_Only_Debit_Invoices__c = true;
        disputeConfig.Enable_Dispute_Resolution__c = true;
        insert disputeConfig;
        // --- 1. Test all celsrm__Dispute_Resolver_Type__c branches ---
        for (String resolverType : new List<String>{'Account_Owner', 'Logged_In_User', 'Dispute_Workflow_Matrix'}) {
            disputeConfig.celsrm__Dispute_Resolver_Type__c = resolverType;
            update disputeConfig;
    
            // --- 2. Test onLoadCreateDisputeScreen with credit and zero balance invoices ---
            Map<Object, Object> inMap = new Map<Object, Object>();
            List<Map<Object, Object>> trxnList = new List<Map<Object, Object>>();
            for (celsrm__Transaction__c t : transList) {
                Map<Object, Object> tMap = new Map<Object, Object>();
                tMap.put('Id', t.Id);
                tMap.put('Name', t.Name);
                tMap.put('celsrm__Balance__c', t.celsrm__Balance__c);
                tMap.put('celsrm__Amount__c', t.celsrm__Amount__c);
                trxnList.add(tMap);
            }
            inMap.put('TransactionList', trxnList);
            inMap.put('Id', acc.Id);
            inMap.put('NoteBody', 'Test');
            inMap.put('Status', 'Open');
            inMap.put('ContactMehods', 'Email');
            DisputeActionController ctrl = new DisputeActionController();
            ctrl.invoke('onLoadCreateDisputeScreen', inMap);
    
            // --- 3. Test onChangeReasonCode for all resolver types ---
            inMap.put('selectedReasonCode', '100 Financial & Invoicing');
            inMap.put('selectedReasonCode', '101 Cash Discount Deduction');
            inMap.put('disputeResolverType', resolverType);
            inMap.put('AccountOwnerId', UserInfo.getUserId());
            inMap.put('AccountOwnerName', UserInfo.getName());
            ctrl.invoke('onChangeReasonCode', inMap);
    
            // --- 4. Test saveDispute with attachments and follow-up ---
            Map<Object, Object> transMap = new Map<Object, Object>();
            transMap.put('Id', trans.Id);
            transMap.put('Name', trans.Name);
            transMap.put('celsrm__Balance__c', trans.celsrm__Balance__c);
            transMap.put('celsrm__Amount__c', trans.celsrm__Amount__c);
            transMap.put('disputeAmount', 100);
            transMap.put('disputeType', '100 Financial & Invoicing');
            transMap.put('reasonCode', '101 Cash Discount Deduction');
            transMap.put('totalSLADays', 2);
            transMap.put('CurrencyIsoCode', 'USD');
            // Attachments
            List<Object> attachments = new List<Object>();
            Map<Object,Object> attachmentMap = new Map<Object,Object>();
            attachmentMap.put('ContentDocumentId', cdList[0].Id);
            attachments.add(attachmentMap);
            transMap.put('attachments', attachments);
            inMap.put('TransactionList', new List<Map<Object, Object>>{transMap});
            inMap.put('isFollowUp', true);
            inMap.put('ListView', null);
            inMap.put('FollowUpDate', String.valueOf(Date.today().addDays(5)));
            inMap.put('Owner', new Map<Object,Object>{'id'=>UserInfo.getUserId(),'name'=>UserInfo.getName()});
            ctrl.invoke('saveDispute', inMap);
    
            // --- 5. Test validateDisputes error branches ---
            // Dispute amount = 0
            transMap.put('disputeAmount', 0);
            inMap.put('TransactionList', new List<Map<Object, Object>>{transMap});
    
            ctrl.invoke('saveDispute', inMap);
    
            // Dispute amount > balance
            transMap.put('disputeAmount', 999999);
            inMap.put('TransactionList', new List<Map<Object, Object>>{transMap});
            ctrl.invoke('saveDispute', inMap);
    
            // Dispute resolver missing
            transMap.put('disputeAmount', 100);
            transMap.put('DisputeResolver', new Map<Object,Object>{'id'=>null});
            inMap.put('TransactionList', new List<Map<Object, Object>>{transMap});
            ctrl.invoke('saveDispute', inMap);
    
            // --- 6. Test fetchOpenDisputesForTransaction ---
            inMap.put('TransactionList', new List<Map<Object, Object>>{transMap});
            ctrl.invoke('fetchOpenDisputesForTransaction', inMap);
    
            // --- 7. Test updateReverseDispute and reverseDisputeFromDisputeDetail ---
            Map<Object, Object> disMap = new Map<Object, Object>();
            disMap.put('isSelected', true);
            disMap.put('Id', trans.Id);
            disMap.put('invoiceId', trans.Id);
            disMap.put('AccountId', acc.Id);
            inMap.put('DisputeList', new List<Map<Object, Object>>{disMap});
            ctrl.invoke('updateReverseDispute', inMap);
    
            inMap.put('Id', trans.Id);
            inMap.put('invoiceNumber', new Map<Object,Object>{'id'=>trans.Id});
            inMap.put('customerName', new Map<Object,Object>{'id'=>acc.Id});
            ctrl.invoke('reverseDisputeFromDisputeDetail', inMap);
    
            // --- 8. Test getTransactionListFromActivity ---
            inMap.put('activityData', new Map<Object,Object>{'Id'=>eMsg.Id});
            ctrl.invoke('getTransactionListFromActivity', inMap);
    
            // --- 9. Test previewCreateDisputeEmail ---
            inMap.put('TransactionList', new List<Map<Object, Object>>{transMap});
            inMap.put('ComposeEmail', new Map<Object,Object>{'body'=>'{Disputes.summary}'});
            inMap.put('SummaryFields', 'Name,celsrm__Amount__c');
            ctrl.invoke('previewCreateDisputeEmail', inMap);
            //-- Starts | FIN-8207 | Change by Asera | 04-Sep-25 //
            inMap.put('TransactionList', new List<Map<Object, Object>>{transMap});

            inMap.put('Id', acc.Id);
            inMap.put('emailId', eMsg.Id);
            inMap.put('disputeResolverType', 'Dispute_Workflow_Matrix');

            Map<String, Object> args = new Map<String, Object>();
            args.put('invoice_numbers', new List<String>{trans.Id});
            args.put('dispute_type', '100 Financial & Invoicing');
            args.put('dispute_reason', '101 Cash Discount Deduction');
            args.put('dispute_amount', 100);
            args.put('dispute_owner', UserInfo.getUserId());
            inMap.put('summaryArguments', JSON.serialize(args));
            inMap.put('openFromSummaryAgent', 'true');
            ctrl.invoke('onLoadCreateDisputeScreen', inMap);
            String result = DisputeActionController.getSessionIdFromVFPage();
            //-- End | FIN-8207 | Change by Asera | 04-Sep-25 //
        }
    
        // --- 10. Test error in saveDispute (simulate DML exception) ---
        Test.startTest();
        DisputeActionController ctrl = new DisputeActionController();
        Map<Object, Object> inMap = new Map<Object, Object>();
        inMap.put('TransactionList', new List<Map<Object, Object>>{new Map<Object, Object>()});
        // Remove required fields to force DML error
        ctrl.invoke('saveDispute', inMap);
        Test.stopTest();
    }
}