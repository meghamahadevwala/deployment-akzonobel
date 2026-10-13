@isTest
public with sharing class AddNoteOnInvoiceControllerTest {
    public static testMethod void testMethod1() {
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
        inMap.put('Id', ac.Id);
        inMap.put('ListView', 'OpenDebit');
        
        try{
            AddNoteOnInvoiceController addNote = new AddNoteOnInvoiceController();
            addNote.invoke('', inMap);
        }catch(Exception e) {
            system.debug('Exception in AddNoteOnInvoiceControllerTest>>>>'+e.getLineNumber() + e.getMessage() );
        }
    }
}