@isTest
public with sharing class SendStatementAttachmentInsertTest {
    public static testMethod void SendStatementAttachmentInsertTest() {
        Account acc = DataGenerator.insertAccount();
        celsrm__Temp_Object_Holder__c objHolder = DataGenerator.insertTempObjHolder();
        attachment attch = DataGenerator.insertAttachment(acc);
        Map<Object,Object> inMap = new Map<Object,Object>();
        inMap.put('StatementFormat','PDF');
        inMap.put('finalContent','finalContent');

        try{
           SendStatementAttachmentInsert test = new SendStatementAttachmentInsert();
           test.invoke('', inMap);
        }catch(Exception e){
            system.debug('Exception caused>>>>'+e.getLineNumber()+'>>>>>>>>>' + e.getMessage() );
        }

        try{
            inMap.put('StatementFormat','Excel');
            SendStatementAttachmentInsert test1 = new SendStatementAttachmentInsert();
            test1.invoke('', inMap);
        }catch(Exception e){
            system.debug('Exception caused>>>>'+e.getLineNumber()+'>>>>>>>>>' + e.getMessage() );
        }
    }
}