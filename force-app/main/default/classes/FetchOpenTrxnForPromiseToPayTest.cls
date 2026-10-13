@isTest
public with sharing class FetchOpenTrxnForPromiseToPayTest {
    
    @isTest
    public static void FetchOpenTrxnTest() {
        Account acc = DataGenerator.insertAccount();
        List<celsrm__Transaction__c> transList = DataGenerator.transactionInsert(acc, 2);
        Map<Object,Object> inMap = new Map<Object,Object>();
        inMap.put('Id',acc.Id);
        inMap.put('gogGridIndex',0);
        
		List<Object> listGridData = new List<Object>();
        Map<Object,Object> mapSelRecData = new Map<Object,Object>();
		
		Map<Object, Object> aData = new Map<Object,Object>();
        Map<Object, Object> bData = new Map<Object,Object>();
        List<Object> cList = new List<Object>();
        Map<Object, Object> cData = new Map<Object,Object>();
        List<String> sList = new List<String>();
        cData.put('dim','invoice_no');
        cData.put('value','testno0');
		   cData.put('end',1);
		cData.put('start',1);
        cData.put('end',1);
		cList.add(cData);
		
		cData = new Map<Object,Object>();
        cData.put('dim','amount-of-money');
        
        Map<Object,Object> mapData = new Map<Object,Object>();
        mapData.put('value',505.4);
        cData.put('value',mapData);
        cData.put('end',1);
		cData.put('start',1);
        cData.put('end',1);
        cList.add(cData);
		
        bData.put('entities',cList);
        bData.put('text','text');
        mapSelRecData.put('Classification_Response__c',JSON.serialize(bData));
		
		listGridData.add(mapSelRecData);
        inMap.put('CustomerCommunicationGrid',listGridData); 
		
        try{
            FetchOpenTrxnForPromiseToPay fetchOpen = new FetchOpenTrxnForPromiseToPay();
           fetchOpen.invoke('', inMap); 
        }catch(Exception e){
            system.debug('Exception caused>>>>'+e.getLineNumber() + e.getMessage() );
        }
    }
}