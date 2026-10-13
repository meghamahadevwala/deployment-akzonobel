@isTest
public with sharing class OutgoingCallHandlerTest {
    

    @isTest
    public static void testInvoke(){

        Account acc = DataGenerator.insertAccount();
        List<Contact> listcon = DataGenerator.insertContact(acc,1);
        Contact con = listcon.get(0);
        Map<Object, Object> inMap = new Map<Object, Object>();
        inMap.put('account',acc.id);
        inMap.put('calledTo',con.id);
        inMap.put('Phone__c','+918200508550');
        inMap.put('screenName','Contact customer');
        inMap.put('transactions','{"transactions":["a0M6g000000OTYJEA4","a0M6g000000OTS3EAO","a0M6g000000OTc0EAG","a0M6g000000OTbKEAW"]}');

        String response = '{"status": 200,"callId": "123"}';
        Test.startTest();
            OutgoingCallHandler og = new OutgoingCallHandler();
            og.invoke('beforeOutgoingCallHandler', inMap);
        Test.stopTest();

    }
    
    @isTest
    public static void testMakeACall(){
        Account acc = DataGenerator.insertAccount();
        List<Contact> listcon = DataGenerator.insertContact(acc,1);
        Contact con = listcon.get(0);
        Map<Object, Object> inMap = new Map<Object, Object>();
        inMap.put('account',acc.id);
        inMap.put('calledTo',con.id);
        inMap.put('Phone__c','+918200508550');
        inMap.put('Phone','+918200508550');
        inMap.put('screenName','Contact customer');
        inMap.put('transactions','{"transactions":["a0M6g000000OTYJEA4","a0M6g000000OTS3EAO","a0M6g000000OTc0EAG","a0M6g000000OTbKEAW"]}');
        
        String response = '{"status": 200,"callId": "123","code":"1233"}';
        Customer_Communication__c comm = new Customer_Communication__c();
        comm.Account__c = acc.Id;
        comm.Call_SID__c = '123';
        insert comm;

        Test.startTest();
            OutgoingCallHandler og = new OutgoingCallHandler();
        
            Test.setMock(HttpCalloutMock.class,new MockCallOutGenerator(response,200));
            
            og.invoke('callToCustomer', inMap);

            Map<String, String> responseValue = new Map<String, String>();
            responseValue.put('To','+918200508550');
            responseValue.put('RecordingUrl','test');
            responseValue.put('CallStatus','Completed');
            responseValue.put('CallSid','123');
            OutgoingCallHandler.afterOutgoingCallHandler(responseValue);
            og.invoke('fetchVerifyUser', inMap);
            og.invoke('isCallerIdVerified', inMap);
            og.invoke('initCallerIDVerification', inMap);
        try{
            OutgoingCallHandler.checkChangeStatus('789654');
        } Catch(Exception e){
            System.debug('eception>>' + e);
        }
        
        OutgoingCallHandler.transcriptCallHandler(responseValue);
        Test.stopTest();
    }
}