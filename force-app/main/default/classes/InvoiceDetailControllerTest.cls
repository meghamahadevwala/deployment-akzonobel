@isTest
private class InvoiceDetailControllerTest {

    @isTest public static void testMethod1() {
        Account acc = DataGenerator.insertAccount();
        celsrm__Transaction__c trxn = DataGenerator.insertTransaction(acc);

        Map<Object, Object> inputMap = new Map<Object, Object>{
            'Id' => trxn.Id
        };

        // Test the controller logic
        InvoiceDetailController controller = new InvoiceDetailController();
        Map<Object, Object> resultMap = controller.invoke('onLoadInvoiceDetailScreen', inputMap);
        inputMap.put('calledFromTransactionDetailScreen', true);
        resultMap = controller.invoke('onLoadInvoiceDetailScreen', inputMap);

        // Assertion
        System.assertEquals(trxn.Name, resultMap.get('Name'));
        System.assertEquals(trxn.celsrm__Balance__c, resultMap.get('celsrm__Balance__c'));
        System.assertEquals(trxn.celsrm__Account__c, resultMap.get('celsrm__Account__c'));
        System.assertEquals('debit', resultMap.get('InvoiceType'));

        // Test with celsrm__Balance__c <= 0
        trxn.celsrm__Balance__c = -100;
        update trxn;

        // Test the controller logic
        resultMap = controller.invoke('onLoadInvoiceDetailScreen', inputMap);

        // Assertion
        System.assertEquals(trxn.Name, resultMap.get('Name'));
        System.assertEquals(trxn.celsrm__Balance__c, resultMap.get('celsrm__Balance__c'));
        System.assertEquals(trxn.celsrm__Account__c, resultMap.get('celsrm__Account__c'));
        System.assertEquals('credit', resultMap.get('InvoiceType'));
    }
}