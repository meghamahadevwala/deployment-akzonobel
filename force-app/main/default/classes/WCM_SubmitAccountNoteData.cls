global with sharing class WCM_SubmitAccountNoteData implements celsrm.GOGIScreenCustomLogic {
    global Map<Object, Object> invoke(String functionName, Map<Object, Object> inMap) {
        system.debug('inmap>>>'+inMap);
        system.debug('inmap>>>'+inMap.get('Id'));
        system.debug('inmap NoteTitle>>>'+inMap.get('NoteTitle'));
        Account acc = new Account();
        acc.Id = String.valueOf(inMap.get('Id'));
        acc =  (account)celsrm.SRMUtilityController.saveNoteOnRecord(acc, String.valueOf(inMap.get('NoteBody'))) ;
        update acc;

        //--- Starts | Insert Note in Celonis Event ---//
        List<String> idSet = new List<String>();
        idSet.add(String.valueOf(inMap.get('Id')));
        celsrm.SRMUtilityController.insertActivity(idSet, 'celsrm__Account__c', 'Note Added', 100, String.valueOf(inMap.get('NoteBody')), UserInfo.getUserId(), null, 'Internal');
        //--- Ends | Insert Note in Celonis Event ---//

        inMap.put('LatestNote',acc.celsrm__Latest_Note__c);
        system.debug('inmap NoteBody>>>'+inMap.get('NoteBody'));
        return inMap;
    }
}