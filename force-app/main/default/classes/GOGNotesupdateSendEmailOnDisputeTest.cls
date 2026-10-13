@isTest
public with sharing class GOGNotesupdateSendEmailOnDisputeTest {
    public static testMethod void GOGNotesupdateSendEmailOnDisputeTest() {
        // List<Task> t = DataGenerator.insertTask(2);
        Account acc = DataGenerator.insertAccount();
        celsrm__Transaction__c trxn = DataGenerator.insertTransaction(acc);
        List<celsrm__Dispute__c> dsList = DataGenerator.insertDispute(trxn,acc,2);
        List<Object> objList = new List<Object>();
        Map<Object,Object> objMap = new Map<Object,Object>();
        objMap.put('Id',dsList.get(0).Id);
        objList.add(objMap);
        Map<Object,Object> inMap = new Map<Object,Object>();
        inMap.put('DisputeGrid',objList);
        inMap.put('NoteTitle','NoteTitle');
        inMap.put('NoteBody','NoteBody');
        try{
            GOGNotesupdateSendEmailOnDispute sendEmailDispute = new GOGNotesupdateSendEmailOnDispute();
            sendEmailDispute.invoke('', inMap);
        }catch(Exception e){
            system.debug('Exception caused>>>>'+e.getLineNumber() + e.getMessage() );
        }
    }
}