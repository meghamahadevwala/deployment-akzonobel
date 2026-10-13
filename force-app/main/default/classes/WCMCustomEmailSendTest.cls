@isTest
public with sharing class WCMCustomEmailSendTest {
    
    public static testMethod void test() {

    Account acc = DataGenerator.insertAccount();
    List<Contact> cont = DataGenerator.insertContact(acc, 2);
    celsrm__Transaction__c trans = DataGenerator.insertTransaction(acc);
    List<celsrm__Dispute__c> dispute = DataGenerator.insertDispute(trans, acc, 2);

    Map<Object,Object> inMap = new Map<Object,Object>();
    List<Map<Object,Object>> objMaplist = new List<Map<Object,Object>>();
    Map<Object,Object> tempComposeEmail = new Map<Object,Object>();
    // List<String> slist1 = new List<String>{cont[0].Id, cont[1].Id};
    List<Object> ObjList = new List<Object>();
    Map<Object,Object> objMap = new Map<Object,Object>();
    objMap.put('Id',trans.Id);
    objMap.put('isSelected', true);
    objList.add(objMap);

    List<Object> ObjList1 = new List<Object>();
    Map<String,Object> objMap1 = new Map<String,Object>();
    objMap1.put('value','value');
    objMap1.put('isSelected', true);
    objList1.add(objMap1);


    tempComposeEmail.put('from', acc.Id);
    tempComposeEmail.put('to', objList1);
    tempComposeEmail.put('subject', 'subject@mail.com');
    tempComposeEmail.put('cc', objList1);
    tempComposeEmail.put('bcc', objList1);
    tempComposeEmail.put('body', 'body'); 
        
    // for attachment
    Map<Object,Object> temp1 = new Map<Object,Object>();
    temp1.put('title', 'title, BillingStatement ,title');
    objMaplist.add(temp1);
    tempComposeEmail.put('attachment', objMaplist);
    inMap.put('SendStatement', tempComposeEmail);	
    WCMCustomEmailSend mail = new WCMCustomEmailSend();

    try{
        mail.invoke('functionName', inMap);
    } catch(Exception e){
       system.debug('Exception caused>>>>'+e.getLineNumber()+'>>>>>>>>>' + e.getMessage() );
    }

    }
}