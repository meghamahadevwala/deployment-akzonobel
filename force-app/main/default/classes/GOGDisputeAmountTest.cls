@isTest
public with sharing class GOGDisputeAmountTest {
    public static testMethod void GOGDisputeAmountTest() {
        Account acc = DataGenerator.insertAccount();
        celsrm__Transaction__c trxn = DataGenerator.insertTransaction(acc);
        List<celsrm__Dispute__c> dsList = DataGenerator.insertDispute(trxn,acc,2);
        Map<Object,Object> inMap = new Map<Object,Object>();
        inMap.put('Id',acc.Id);
        
        Map<Object,Object> objMap = new Map<Object,Object>();
        Map<Object, Object> aData = new Map<Object,Object>();
        Map<Object, Object> bData = new Map<Object,Object>();
        List<Object> cList = new List<Object>();
        Map<Object, Object> cData = new Map<Object,Object>();
        String dateS = Datetime.now().format('yyyy-MM-dd');
        List<Object> objList = new List<Object>();
        objMap.put('celsrm__Balance__c',15.5);
        objMap.put('celsrm__Amount__c',15.5);
        objList.add(objMap);
        cData.put('entity','time');
        cData.put('value',dateS);
        cData.put('end',1);
        cList.add(cData);
        bData.put('entities',cList);
        aData.put('Classification_Response__c',JSON.serialize(bData));
        inMap.put('activityData',aData); 
        inMap.put('TransactionList',objList); 
        inMap.put('ggScreenName','WCMQuickPromisToPayScreen');     
        try{
           GOGDisputeAmount disAmt = new GOGDisputeAmount();
           disAmt.invoke('', inMap);
        }catch(Exception e){
            system.debug('Exception caused>>>>'+e.getLineNumber()+'>>>>>>>>>' + e.getMessage() );
        }

        // try{
        //     cData.put('value',15.5);
        //     cList.add(cData);
        //     bData.put('entities',cList);
        //     aData.put('Classification_Response__c',JSON.serialize(bData));
        //     inMap.put('activityData',aData); 
        //     inMap.put('TransactionList',objList);
        //     inMap.put('ggScreenName','WCMQuickPromisToPayScreen');
        //    GOGDisputeAmount disAmt3 = new GOGDisputeAmount();
        //    disAmt3.invoke('', inMap);
        // }catch(Exception e){
        //     system.debug('Exception caused>>>>'+e.getLineNumber()+'>>>>>>>>>' + e.getMessage() );
        // }

        try{
            inMap.put('ggScreenName','WCMCreateDisputeScreen');
           GOGDisputeAmount disAmt1 = new GOGDisputeAmount();
           disAmt1.invoke('', inMap);
        }catch(Exception e){
            system.debug('Exception caused>>>>'+e.getLineNumber() + e.getMessage() );
        }

        try{
            inMap.put('ggScreenName','WCMPromisToPayScreen');
           GOGDisputeAmount disAmt2 = new GOGDisputeAmount();
           disAmt2.invoke('', inMap);
        }catch(Exception e){
            system.debug('Exception caused>>>>'+e.getLineNumber() + e.getMessage() );
        }
    }
    //-- Starts | FIN-8207 | Change by Asera | 19-Aug-25 //
    @isTest
    static void testInvoke_setsPromiseFields_andTempKey_withStringTime_andAmount() {
        Account accountRecord = DataGenerator.insertAccount();
        celsrm__Transaction__c transactionRecord = DataGenerator.insertTransaction(accountRecord);
        DataGenerator.insertDispute(transactionRecord, accountRecord, 1);

        Map<Object, Object> inMap = new Map<Object, Object>();

        Map<Object, Object> activityData = new Map<Object, Object>();
        // << START - MM - FIN-8233 - Deployment - 19 Aug 2025 | test class bug>>
        EmailMessage msg = DataGenerator.insertEmailMsg(accountRecord.Id);
        activityData.put('Id', msg.Id);
        // << END - MM - FIN-8233 - Deployment - 19 Aug 2025 | test class bug>>
        Map<Object, Object> classification = new Map<Object, Object>();
                List<Object> entities = new List<Object>();
 
        String dateString = Datetime.now().format('yyyy-MM-dd');
 
        Map<String, Object> timeEntity = new Map<String, Object>();
        timeEntity.put('entity', 'time');
        timeEntity.put('value', dateString);
        timeEntity.put('end', 1);
        entities.add(timeEntity);

        Map<String, Object> amountEntity = new Map<String, Object>();
        amountEntity.put('entity', 'amount-of-money');
        amountEntity.put('value', 15.5);
        entities.add(amountEntity);

        classification.put('entities', entities);
        classification.put('text', 'Promise to pay 15.5 on ' + dateString);
        activityData.put('Classification_Response__c', JSON.serialize(classification));

        Map<Object, Object> transactionMap = new Map<Object, Object>();
        transactionMap.put('Id', transactionRecord.Id);
        transactionMap.put('celsrm__Balance__c', 15.5);
        transactionMap.put('celsrm__Amount__c', 15.5);
        List<Object> transactionList = new List<Object>{ transactionMap };

        inMap.put('activityData', activityData);
        inMap.put('TransactionList', transactionList);
        inMap.put('ggScreenName', 'WCMQuickPromisToPayScreen');

        GOGDisputeAmount logic = new GOGDisputeAmount();
        Map<Object, Object> outMap = logic.invoke('', inMap);

        System.assert(outMap != null, 'invoke should return a map');
        System.assert(outMap.containsKey('TransactionList'), 'Returned map should contain TransactionList');

        List<Object> outTrxList = (List<Object>) outMap.get('TransactionList');
        System.assertEquals(1, outTrxList.size(), 'Should return one transaction');
        Map<Object, Object> outTrx = (Map<Object, Object>) outTrxList[0];

        System.assertEquals(Date.today().addDays(5), (Date) outTrx.get('PromiseDate'), 'PromiseDate should be set to today + 5');
        System.assertEquals(Decimal.valueOf('15.5'), (Decimal) outTrx.get('PromisedAmount'), 'PromisedAmount should be set from celsrm__Balance__c');

        System.assert(outMap.containsKey('tempKey'), 'tempKey should be set when Transaction Ids are present');
        System.assertNotEquals(null, outMap.get('tempKey'), 'tempKey should not be null');
    }

    @isTest
    static void testInvoke_timeEntityAsObject_mapBranchCovered() {
        Account accountRecord = DataGenerator.insertAccount();
        celsrm__Transaction__c transactionRecord = DataGenerator.insertTransaction(accountRecord);

        Map<Object, Object> inMap = new Map<Object, Object>();

        Map<Object, Object> activityData = new Map<Object, Object>();
        // << START - MM - FIN-8233 - Deployment - 19 Aug 2025 | test class bug>>
        EmailMessage msg = DataGenerator.insertEmailMsg(accountRecord.Id);
        activityData.put('Id', msg.Id);
        // << END - MM - FIN-8233 - Deployment - 19 Aug 2025 | test class bug>>
        Map<Object, Object> classification = new Map<Object, Object>();
                List<Object> entities = new List<Object>();
 
        String dateString = Datetime.now().addDays(3).format('yyyy-MM-dd');
 
        Map<String, Object> timeValue = new Map<String, Object>();
        timeValue.put('to', dateString);
        Map<String, Object> timeEntity = new Map<String, Object>();
        timeEntity.put('entity', 'time');
        timeEntity.put('value', timeValue);
        entities.add(timeEntity);

        classification.put('entities', entities);
        classification.put('text', 'Promise by ' + dateString);
        activityData.put('Classification_Response__c', JSON.serialize(classification));

        Map<Object, Object> transactionMap = new Map<Object, Object>();
        transactionMap.put('Id', transactionRecord.Id);
        transactionMap.put('celsrm__Balance__c', 42);
        List<Object> transactionList = new List<Object>{ transactionMap };

        inMap.put('activityData', activityData);
        inMap.put('TransactionList', transactionList);
        inMap.put('ggScreenName', 'WCMPromisToPayScreen');

        GOGDisputeAmount logic = new GOGDisputeAmount();
        Map<Object, Object> outMap = logic.invoke('', inMap);

        List<Object> outTrxList = (List<Object>) outMap.get('TransactionList');
        Map<Object, Object> outTrx = (Map<Object, Object>) outTrxList[0];

        System.assertEquals(Date.today().addDays(5), (Date) outTrx.get('PromiseDate'));
        System.assertEquals(Decimal.valueOf('42'), (Decimal) outTrx.get('PromisedAmount'));
        System.assert(outMap.containsKey('tempKey'));
    }

    @isTest
    static void testInvoke_withoutActivityData_stillSetsDefaults() {
        Account accountRecord = DataGenerator.insertAccount();
        celsrm__Transaction__c transactionRecord = DataGenerator.insertTransaction(accountRecord);

        Map<Object, Object> transactionMap = new Map<Object, Object>();
        transactionMap.put('Id', transactionRecord.Id);
        transactionMap.put('celsrm__Balance__c', 10);
        List<Object> transactionList = new List<Object>{ transactionMap };

        Map<Object, Object> inMap = new Map<Object, Object>();
        inMap.put('TransactionList', transactionList);

        GOGDisputeAmount logic = new GOGDisputeAmount();
        Map<Object, Object> outMap = logic.invoke('', inMap);

        List<Object> outTrxList = (List<Object>) outMap.get('TransactionList');
        Map<Object, Object> outTrx = (Map<Object, Object>) outTrxList[0];

        System.assertEquals(Date.today().addDays(5), (Date) outTrx.get('PromiseDate'));
        System.assertEquals(Decimal.valueOf('10'), (Decimal) outTrx.get('PromisedAmount'));
        System.assert(outMap.containsKey('tempKey'));
    }
    //-- End | FIN-8207 | Change by Asera | 19-Aug-25 //
}