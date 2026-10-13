@isTest

public with sharing class WCM_SubmitAccountNoteDataTest {
    
    public static testmethod void WCM_SubmitAccountNoteDataTest() {
        Account acc = DataGenerator.insertAccount();
        celsrm__Transaction__c trans = DataGenerator.insertTransaction(acc);

        Map<Object,Object> inMap = new Map<Object,Object>();
        inMap.put('Id', acc.Id);
        inMap.put('NoteTitle', 'NoteTitle');
        inMap.put('NoteBody', 'NoteBody');

        WCM_SubmitAccountNoteData accNote = new WCM_SubmitAccountNoteData();
        accNote.invoke('', inMap);
    }
}