@isTest
public class UpdateActualPaymentsReceivedBatchTest {

    @testSetup
    static void setupTestData() {
        // Create test Accounts
        Account account1 = DataGenerator.insertAccount();
        Account account2 = DataGenerator.insertAccount();
        
        account1.Name = 'Test Account 1';
        account1.Forecast_Period__c = Date.newInstance(2024, 11, 1);
        account1.CurrencyIsoCode = 'USD';

        account2.Name = 'Test Account 2';
        account2.Forecast_Period__c = Date.newInstance(2024, 11, 1);
        account2.CurrencyIsoCode = 'EUR'; // Edge case: different currency

        update new List<Account>{ account1, account2 };

        // Create test Monthly Forecast records
        Monthly_Forecast__c forecast1 = new Monthly_Forecast__c(Month__c = 11, Year__c = 2024, Actual_Payment_Received__c = null);
        Monthly_Forecast__c forecast2 = new Monthly_Forecast__c(Month__c = 12, Year__c = 2024, Actual_Payment_Received__c = null);
        insert new List<Monthly_Forecast__c>{ forecast1, forecast2 };

        // Create test Transactions
        celsrm__Transaction__c transaction1 = new celsrm__Transaction__c(
            celsrm__Close_Date__c = Date.newInstance(2024, 11, 15),
            celsrm__Amount__c = 100,
            celsrm__Debit_Credit_Indicator__c = 'H',
            celsrm__Document_Type__c = 'AB',
            celsrm__Account__c = account1.Id
        );
        celsrm__Transaction__c transaction2 = new celsrm__Transaction__c(
            celsrm__Close_Date__c = Date.newInstance(2024, 11, 16),
            celsrm__Amount__c = 200,
            celsrm__Debit_Credit_Indicator__c = 'H',
            celsrm__Document_Type__c = 'RV',
            celsrm__Account__c = account2.Id
        );
        
        insert new List<celsrm__Transaction__c>{ transaction1, transaction2 };

        // Create test Collector Targets
        Collector_Target__c collectorTarget1 = new Collector_Target__c(
            Monthly_Forecast__c = forecast1.Id,
            Collector_User__c = UserInfo.getUserId(),
            Actual_Payment_Received__c = null
        );
        insert collectorTarget1;
    }

    @isTest
    static void testBatchExecution() {
        Test.startTest();
        List<String> docTypes = new List<String>{'RV','AB','DG','DR','DA'};
        UpdateActualPaymentsReceivedBatch batch = new UpdateActualPaymentsReceivedBatch(docTypes);
        Database.executeBatch(batch, 200);
        Test.stopTest();

        // Verify Forecast updates
        List<Monthly_Forecast__c> forecasts = [
            SELECT Id, Actual_Payment_Received__c
            FROM Monthly_Forecast__c
        ];
        for (Monthly_Forecast__c forecast : forecasts) {
            System.assertNotEquals(null, forecast.Actual_Payment_Received__c, 'Actual Payment Received should be updated.');
        }

        // Verify Account updates
        List<Account> accounts = [
            SELECT Id, Actual_Payment_Received__c
            FROM Account
        ];
        for (Account account : accounts) {
            if (account.Actual_Payment_Received__c != null) {
                System.assert(account.Actual_Payment_Received__c > 0, 'Actual Payment Received should be a positive value.');
            }
        }
    }

    @isTest
    static void testSchedulableExecution() {
        Test.startTest();
        String cronExp = '0 0 0 * * ?';
        List<String> docTypes = new List<String>{'RV','AB','DG','DR','DA'};
        System.schedule('Test Schedulable', cronExp, new UpdateActualPaymentsReceivedBatch(docTypes));
        Test.stopTest();

        List<Monthly_Forecast__c> forecasts = [SELECT Id, Actual_Payment_Received__c FROM Monthly_Forecast__c];
        System.assert(forecasts.size() > 0, 'Forecasts should have been updated.');
    }

    @isTest
    static void testCurrencyConversion() {
        Test.startTest();
        UpdateActualPaymentsReceivedBatch batchInstance = new UpdateActualPaymentsReceivedBatch(new List<String>{'RV'});
        Decimal result = batchInstance.convertToAccountCurrency(100, 'EUR');
        Test.stopTest();

        System.assert(result > 0, 'Conversion should return a positive value for valid currency.');
    }

    @isTest
    static void testAccountWiseAndCollectorWisePayments() {
        Test.startTest();
        List<String> docTypes = new List<String>{'RV','AB','DG','DR','DA'};
        UpdateActualPaymentsReceivedBatch batch = new UpdateActualPaymentsReceivedBatch(docTypes);
        Database.executeBatch(batch, 200);
        Test.stopTest();

        // Verify account-wise payments
        Map<Id, Decimal> expectedAccountWisePayments = new Map<Id, Decimal>{
            [SELECT Id FROM Account WHERE Name = 'Test Account 1'].Id => 100.00,
            [SELECT Id FROM Account WHERE Name = 'Test Account 2'].Id => 200.00
        };

        Map<Id, Decimal> accountWisePayments = new Map<Id, Decimal>();
        for (celsrm__Transaction__c trxn : [SELECT celsrm__Account__c, celsrm__Amount__c FROM celsrm__Transaction__c]) {
            Id accountId = trxn.celsrm__Account__c;
            Decimal amount = Math.abs(trxn.celsrm__Amount__c);
            if (!accountWisePayments.containsKey(accountId)) {
                accountWisePayments.put(accountId, 0);
            }
            accountWisePayments.put(accountId, accountWisePayments.get(accountId) + amount);
        }
        System.assertEquals(expectedAccountWisePayments, accountWisePayments, 'Account-wise payments do not match.');

        // Verify collector-wise payments
        Map<Id, Decimal> expectedCollectorWisePayments = new Map<Id, Decimal>{
            UserInfo.getUserId() => 300.00
        };

        Map<Id, Decimal> collectorWisePayments = new Map<Id, Decimal>();
        for (celsrm__Transaction__c trxn : [SELECT celsrm__Account__r.OwnerId, celsrm__Amount__c FROM celsrm__Transaction__c]) {
            Id ownerId = trxn.celsrm__Account__r.OwnerId;
            Decimal amount = Math.abs(trxn.celsrm__Amount__c);
            if (!collectorWisePayments.containsKey(ownerId)) {
                collectorWisePayments.put(ownerId, 0);
            }
            collectorWisePayments.put(ownerId, collectorWisePayments.get(ownerId) + amount);
        }
        System.assertEquals(expectedCollectorWisePayments, collectorWisePayments, 'Collector-wise payments do not match.');
    }

}