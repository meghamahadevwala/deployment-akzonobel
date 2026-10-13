global with sharing class PromiseReversalController implements celsrm.GOGIScreenCustomLogic{

    global Map<Object, Object> invoke(String functionName, Map<Object, Object> inMap) {
        try {
            if (functionName == 'getTransactionList') {
                inMap = getTransactionList(inMap);
            } else if (functionName == 'onSubmitReversePromise') {
                inMap = onSubmitReversePromise(inMap);
            } 
        } catch (Exception ex) {
            System.debug('Class: CreditReviewParameters | Linenumber: ' + ex.getLineNumber() + ' | Message: ' + ex.getMessage());
        }
        return inMap;
    }

    public static Map<Object, Object> getTransactionList(Map<Object, Object> inMap){
        try{
            System.debug('Inside getTransactionList >>>>');
            Id AccountId = (Id) inMap.get('Id');

            if(inMap.containsKey('TransactionList')) {
                List<Object> listTransaction = (List<Object>)inMap.get('TransactionList');
                List<String> listTranIds = new List<String>();
                System.debug( '@@ listTransaction : ' + listTransaction);

                for (Object tran : listTransaction) {
                    Map<Object,Object> tempMap = (Map<Object,Object>)tran;
                    System.debug( '@@ tempMap : ' + tempMap);
                    System.debug( '@@ ID :  : ' + tempMap.get('Id'));
                    String id = String.valueOf(tempMap.get('Id'));
                    listTranIds.add(id);
                }
                List<map<Object,Object>> transactionList = new List<map<Object,Object>>();
                for(celsrm__Transaction__c trxn : [SELECT Id, Name, celsrm__Amount__c, celsrm__Promised_Amount__c, celsrm__Promise_Date__c 
                                                FROM celsrm__Transaction__c WHERE Id IN :listTranIds] ){
                    map<Object,Object> tempbs =  new map<Object,Object>();
                    tempbs.put('invoiceId', trxn.Id);
                    tempbs.put('invoiceNo', '<a href="' + '/'+ trxn.Id + '" target="_blank">' + trxn.name + '</a>');
                    tempbs.put('amount', trxn.celsrm__Amount__c);
                    tempbs.put('promisedAmount', trxn.celsrm__Promised_Amount__c);
                    tempbs.put('promisedDate', trxn.celsrm__Promise_Date__c);
                    transactionList.add(tempbs);
                }
                inMap.put('dataServiceResponse', transactionList);
            }
            
        } catch(Exception ex){
            System.debug('Method: getTransactionList | Linenumber: ' + ex.getLineNumber() + ' | Message: ' + ex.getMessage());
        }
        return inMap;
    }

    public static Map<Object, Object> onSubmitReversePromise(Map<Object, Object> inMap){
        try{
            System.debug('Inside onSubmitReversePromise >>>>');
            if(inMap.get('promiseList') != null){
                List<String> trnxIds = new List<String>();
                List<Object> transactionList = (List<Object>)inMap.get('promiseList');
                if(transactionList != null && !transactionList.isEmpty()){
                  List<celsrm__Transaction__c> listTransactionRecords = new List<celsrm__Transaction__c>();
                    for (Object record : transactionList) {
                        Map<Object,Object> tempMap = (Map<Object,Object>)record;
                        if(Boolean.valueOf(tempMap.get('isSelected'))){
                            celsrm__Transaction__c trnx = new celsrm__Transaction__c();
                            trnx.Id = String.valueOf(tempMap.get('invoiceId'));
                            trnx.celsrm__Promised_Amount__c = 0;
                            trnx.celsrm__Promise_Date__c = null;
                            trnx.celsrm__Latest_Note_Date__c = date.today();
                            trnx.celsrm__Latest_Note_Entered_By__c = UserInfo.getUserId();
                            trnx.celsrm__Latest_Note__c =  inMap.get('noteBody') != null && inMap.get('noteBody') != '' ? String.valueOf(inMap.get('noteBody')) : null;
                            listTransactionRecords.add(trnx);
                            trnxIds.add(trnx.Id);
                        }
                    }
                    system.debug('listTransactionRecords :: ' + listTransactionRecords);
                    if(listTransactionRecords != null && !listTransactionRecords.isEmpty()){
                        update listTransactionRecords;
                    }
                    if(!trnxIds.isEmpty()){
                        celsrm.SRMUtilityController.insertActivity( trnxIds, 
                            'celsrm__Transaction__c',
                            'Promise Reversed', 
                            100, 
                            inMap.get('noteBody') != null && inMap.get('noteBody') != '' ? String.valueOf(inMap.get('noteBody')) : null, 
                            UserInfo.getUserId(), 
                            null, 
                            'Internal');
                    }
                }
            }
        } catch(Exception ex){
            System.debug('Method: onSubmitReversePromise | Linenumber: ' + ex.getLineNumber() + ' | Message: ' + ex.getMessage());
        }
        Map<String, Object> refreshParentValues = new Map<String, Object>();
        refreshParentValues.put('name', 'ListView');
        refreshParentValues.put('value',inMap.get('ListView'));
        refreshParentValues.put('onChangeMethod','filterDataByView');
        inMap.put('refreshParentValues', refreshParentValues);
        return inMap;
    }
}