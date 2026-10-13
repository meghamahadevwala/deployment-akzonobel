@isTest

public with sharing class SRM_SubmitDisputeNoteDataTest {
    
    public static testmethod void SRM_SubmitDisputeNoteData() {

        Account acc = DataGenerator.insertAccount();
        celsrm__Transaction__c trans = DataGenerator.insertTransaction(acc);
        List<celsrm__Dispute__c> ds = DataGenerator.insertDispute(trans ,acc,2);

        Map<Object,Object> inMap = new Map<Object,Object>();
        inMap.put('Id', ds.get(0).Id);
        inMap.put('NoteTitle', 'NoteTitle');
        inMap.put('NoteBody', 'NoteBody');

        SRM_SubmitDisputeNoteData accNote = new SRM_SubmitDisputeNoteData();
        accNote.invoke('', inMap);
    }
}