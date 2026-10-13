@isTest
public with sharing class GOGWCMAddNoteTest {
    public static testMethod void GOGWCMAddNoteTest() {
        Account ac = DataGenerator.insertAccount();
        celsrm__Transaction__c trxn = DataGenerator.insertTransaction(ac);
        Map<Object,Object> inMap = new Map<Object,Object>();
        List<Object> transList = New List<Object>();
        Map<Object,Object> objMap = new Map<Object,Object>();
        objMap.put('Id', trxn.Id);
        transList.add(objMap);
        inMap.put('TransactionList',transList);
        inMap.put('NoteTitle','NoteTitle');
        inMap.put('NoteBody','NoteBody');
        inMap.put('WhatId',ac.Id);
        inMap.put('Id',ac.Id);
        try{
            GOGWCMAddNote addNote = new GOGWCMAddNote();
            addNote.invoke('', inMap);
        }catch(Exception e){
            system.debug('Exception caused>>>>'+e.getLineNumber() + e.getMessage() );
        }
    }
}