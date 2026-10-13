global with sharing class RefreshTransactionGridOnNotes implements celsrm.GOGIScreenCustomLogic{
    global Map<Object, Object> invoke(String functionName, Map<Object, Object> inMap) {
        String transactionId = String.valueOf(inMap.get('Id'));
        String transactionNote = String.valueOf(inMap.get('TransactionNote'));
        celsrm__Transaction__c trx = new celsrm__Transaction__c();
        trx.celsrm__Latest_Note__c = transactionNote;
        trx.Id = transactionId;
        update trx;
        Map<String, Object> refreshParentValues = new Map<String, Object>();
        // if(inMap.containsKey('ListView')) {
            refreshParentValues.put('name', 'ListView');
            refreshParentValues.put('value',inMap.get('ListView'));
            refreshParentValues.put('onChangeMethod','OnChangeViewCreate');
        // }
        System.debug('@@@ refreshParentValues : '  +refreshParentValues);
        inMap.put('refreshParentValues', refreshParentValues);
        return inMap;
    }
}