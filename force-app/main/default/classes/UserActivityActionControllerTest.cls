@IsTest
private class UserActivityActionControllerTest {

    @TestSetup
    static void setup() {
        insert new Account(Name = 'A1');
        insert new celsrm__Transaction__c(
            Name = 'T1',
            celsrm__Account__c = [SELECT Id FROM Account LIMIT 1].Id
        );
        insert new celsrm__Dispute__c(celsrm__Amount__c = 10, celsrm__Account__c = [SELECT Id FROM Account LIMIT 1].Id);

    }

    @IsTest
    static void testFullCoverage() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        celsrm__Transaction__c trn = [SELECT Id FROM celsrm__Transaction__c LIMIT 1];
        celsrm__Dispute__c disp = [SELECT Id FROM celsrm__Dispute__c LIMIT 1];


        List<Map<Object,Object>> tests = new List<Map<Object,Object>>{
            new Map<Object,Object>{
                'ggScreenName' => 'Reverse Dispute',
                'customerName' => new Map<Object,Object>{'id' => acc.Id},
                'Id' => disp.Id
            },
            new Map<Object,Object>{
                'ggScreenName' => 'ReverseDispute',
                'Id' => acc.Id
            },
            new Map<Object,Object>{
                'ggScreenName' => 'ReversePromise',
                'Id' => acc.Id
            },
            new Map<Object,Object>{
                'ggScreenName' => 'Add Note On Invoices',
                'calledFromTransactionDetailScreen' => true,
                'Id' => trn.Id,
                'celsrm__Account__c' => acc.Id
            },
            new Map<Object,Object>{
                'ggScreenName' => 'Add Note On Invoices',
                'Id' => acc.Id
            },
            new Map<Object,Object>{
                'ggScreenName' => 'AddNoteOnAccount',
                'Id' => acc.Id
            },
            new Map<Object,Object>{ 'ggScreenName'=>'SRMTransactionGridScreen','Id'=>acc.Id },
            new Map<Object,Object>{ 'ggScreenName'=>'AccountNotes','Id'=>acc.Id },
            new Map<Object,Object>{ 'ggScreenName'=>'Disputes On Account','Id'=>acc.Id },
            new Map<Object,Object>{ 'ggScreenName'=>'Account Collection Activity','Id'=>acc.Id },
            new Map<Object,Object>{ 'ggScreenName'=>'Collection Scorecard','Id'=>acc.Id },
            new Map<Object,Object>{ 'ggScreenName'=>'AccountDetailMailboxScreen','Id'=>acc.Id },
            new Map<Object,Object>{ 'ggScreenName'=>'TransactionDisputeGrid','Id'=>trn.Id },
            new Map<Object,Object>{ 'ggScreenName'=>'BillingDataInTransaction','Id'=>trn.Id },
            new Map<Object,Object>{ 'ggScreenName'=>'Transaction Collection Activity','Id'=>trn.Id },
            new Map<Object,Object>{ 'ggScreenName'=>'Transaction Notes','Id'=>trn.Id },
            new Map<Object,Object>{
                'ggScreenName' => 'OtherScreen',
                'accountId' => acc.Id
            },
            new Map<Object,Object>{
                'ggScreenName' => 'OtherScreen',
                'disputeId' => disp.Id
            }
        };

        for (Map<Object,Object> m : tests) {
            m.put('actionTakenTime', System.now());
            Map<Object,Object> outMap = UserActivityActionController.onLoadLogActivity(m);
            System.assert(outMap.containsKey('activityLogId'));
        }
    }

    @IsTest
    static void testInvoke() {
        UserActivityActionController ctrl = new UserActivityActionController();
        Map<Object,Object> result = ctrl.invoke('onLoadLogActivity', new Map<Object,Object>{
            'ggScreenName' => 'OtherScreen'
        });
        System.assert(result.containsKey('activityLogId'));
    }
}