global with sharing class SRM_SubmitDisputeNoteData implements celsrm.GOGIScreenCustomLogic {
    //-- DEPRICATED --//
    global Map<Object, Object> invoke(String functionName, Map<Object, Object> inMap) {
        system.debug('inmap>>>'+inMap);
        system.debug('inmap>>>'+inMap.get('Id'));
        system.debug('inmap NoteTitle>>>'+inMap.get('NoteTitle'));
        
        celsrm__Dispute__c acc =[Select id,celsrm__Latest_Note__c from celsrm__Dispute__c where id =: String.valueOf(inMap.get('Id'))];
        acc = (celsrm__Dispute__c) celsrm.SRMUtilityController.saveNoteOnRecord(acc, acc.celsrm__Latest_Note__c, 'NOTE - ', String.valueOf(inMap.get('NoteBody')), '', '') ;
               
        system.debug('inmap NoteBody>>>'+inMap.get('NoteBody'));
        
        return inMap;
    }
}