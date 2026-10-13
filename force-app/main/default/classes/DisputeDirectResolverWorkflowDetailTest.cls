@IsTest(SeeAllData=true)
private class DisputeDirectResolverWorkflowDetailTest {
    @IsTest
    static void testLoggedInUserCreatesDirectWorkflowDetail() {
        celsrm__Dispute__c dispute = createDisputeForResolverType(
            'Logged_In_User',
            new Map<Object, Object>{
                'id' => UserInfo.getUserId(),
                'name' => UserInfo.getName()
            }
        );

        celsrm__User_Master__c currentUserMaster = [
            SELECT Id
            FROM celsrm__User_Master__c
            WHERE celsrm__User__c = :UserInfo.getUserId()
            LIMIT 1
        ];
        celsrm__Dispute_Workflow_Details__c detail = getOnlyWorkflowDetail(dispute.Id);

    }

    @IsTest
    static void testAccountOwnerCreatesDirectWorkflowDetail() {
        Account accountRow = [
            SELECT Id, OwnerId, Owner.Name
            FROM Account
            LIMIT 1
        ];

        celsrm__Dispute__c dispute = createDisputeForResolverType(
            'Account_Owner',
            new Map<Object, Object>{
                'id' => accountRow.OwnerId,
                'name' => accountRow.Owner.Name
            },
            accountRow
        );

        celsrm__User_Master__c ownerUserMaster = [
            SELECT Id
            FROM celsrm__User_Master__c
            WHERE celsrm__User__c = :accountRow.OwnerId
            LIMIT 1
        ];
        celsrm__Dispute_Workflow_Details__c detail = getOnlyWorkflowDetail(dispute.Id);

    }

    private static celsrm__Dispute__c createDisputeForResolverType(
        String resolverType,
        Map<Object, Object> resolverMap
    ) {
        Account accountRow = [
            SELECT Id, OwnerId, Owner.Name
            FROM Account
            LIMIT 1
        ];
        return createDisputeForResolverType(resolverType, resolverMap, accountRow);
    }

    private static celsrm__Dispute__c createDisputeForResolverType(
        String resolverType,
        Map<Object, Object> resolverMap,
        Account accountRow
    ) {
        celsrm__Dispute_Configuration__c config = celsrm__Dispute_Configuration__c.getOrgDefaults();
        config.SetupOwnerId = UserInfo.getOrganizationId();
        config.celsrm__Dispute_Resolver_Type__c = resolverType;
        config.celsrm__Use_Dispute_Workflow_Matrix__c = true;
        upsert config;

        celsrm__Transaction__c transactionRow = DataGenerator.insertTransaction(accountRow);
        Map<Object, Object> transactionMap = new Map<Object, Object>{
            'Id' => transactionRow.Id,
            'Name' => transactionRow.Name,
            'celsrm__Account__c' => accountRow.Id,
            'celsrm__Balance__c' => transactionRow.celsrm__Balance__c,
            'celsrm__Amount__c' => transactionRow.celsrm__Amount__c,
            'disputeAmount' => Decimal.valueOf(100),
            // << START - MM - FIN-10180 - Test class error | INVALID_OR_NULL_FOR_RESTRICTED_PICKLIST>>
            // 'disputeType' => 'Billing',
            // 'reasonCode' => 'Tax rate incorrect',
            'disputeType' => '100 Financial & Invoicing',
            'reasonCode' => '101 Cash Discount Deduction',
            // << END - MM - FIN-10180 - Test class error | INVALID_OR_NULL_FOR_RESTRICTED_PICKLIST>>
            'CurrencyIsoCode' => 'USD',
            'DisputeResolver' => resolverMap
        };
        Map<Object, Object> inMap = new Map<Object, Object>{
            'Id' => accountRow.Id,
            'TransactionList' => new List<Object>{ transactionMap },
            'NoteBody' => 'Test direct resolver workflow detail'
        };

        Test.startTest();
        Map<Object, Object> result = DisputeActionController.saveDispute(inMap);
        Test.stopTest();

        List<celsrm__Dispute__c> disputes = (List<celsrm__Dispute__c>) result.get('DisputeList');
        return disputes[0];
    }

    private static celsrm__Dispute_Workflow_Details__c getOnlyWorkflowDetail(Id disputeId) {
        List<celsrm__Dispute_Workflow_Details__c> details = [
            SELECT Id, celsrm__Dispute__c, celsrm__Status__c, celsrm__User_Master__c,
                   celsrm__Dispute_Workflow_Matrix__c, celsrm__Workflow_Level__c,
                   celsrm__Workflow_User_Type__c
            FROM celsrm__Dispute_Workflow_Details__c
            WHERE celsrm__Dispute__c = :disputeId
        ];
        
        return details[0];
    }
}