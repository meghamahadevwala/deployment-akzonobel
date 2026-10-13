@isTest
public class AccountActionControllerTest {
    static Map<Object,Object> inMap = new Map<Object,Object>();
    public static testMethod void testMethod1() {
        // Create a test Account
        Account testAccount = DataGenerator.insertAccount();
        
        // Create a test Screen
        celsrm__Screens__c testScreen = DataGenerator.insertScreen();
        
        Test.startTest();
        // Call the method under test
        AccountActionController.AccountActionWrapper result = AccountActionController.getAccountDataAndScreenConfig(testAccount.Id, 'testScreen');
        try {
            result = AccountActionController.getAccountDataAndScreenConfig(testAccount.Id, '');
        } catch (Exception ex) {
            
        }
        try {
            result = AccountActionController.getAccountDataAndScreenConfig(testAccount.Id, 'testScreen1');
        } catch (Exception ex) {
            
        }
        
        
        inMap.put('Id', testAccount.Id);
        inMap.put('NoteBody', 'test note');
        AccountActionController accountActionController = new AccountActionController();
        Map<Object,Object> returnMap = accountActionController.invoke('saveAccountNote', inMap);
       	accountActionController.invoke('reversePromiseToPay', inMap);
        List<celsrm__Transaction__c> trxList = DataGenerator.transactionInsert(testAccount, 5);
        List<Object> transactionObjList = new List<Object>();
        for(celsrm__Transaction__c trx: trxList){
            Map<Object,Object> transactionMap = new Map<Object,Object>();
            transactionMap.put('Id', trx.Id);
            transactionObjList.add(transactionMap);
        }
        inMap.put('TransactionList', transactionObjList);
        accountActionController.invoke('reversePromiseToPay', inMap);
        accountActionController.invoke('onLoadAccountCreateTask', inMap);
        accountActionController.invoke('onSubmitAccountCreateTask', inMap);
        Test.stopTest();
        
        // Verify the result
        System.assertEquals('testScreen', result.screenConfig.get('name'), 'Screen config should contain key1 with value "value1"');
        System.assertEquals(testAccount.Id, result.accountData.Id, 'Account data should match the test account');
        System.assertEquals(inMap.get('NoteBody'), returnMap.get('LatestNote'), 'Account note should match the test note');
    }
}