@isTest
public with sharing class GoGCustomEmailSendToAndCcTest {
    public static testMethod void GoGCustomEmailSendToAndCcTest() {
        Account acc = DataGenerator.insertAccount();
        celsrm__SRM_Configuration__c wcmConfig = DataGenerator.insertWCMconfig();
        Map<Object,Object> inMap = new Map<Object,Object>();
        inMap.put('Id',acc.Id);
        try{
           GoGCustomEmailSendToAndCc test = new GoGCustomEmailSendToAndCc();
           test.invoke('', inMap);
        }catch(Exception e){
            system.debug('Exception caused>>>>'+e.getLineNumber()+'>>>>>>>>>' + e.getMessage() );
        }
    }
    
    public static testMethod void testActivity(){
        Account acc = DataGenerator.insertAccount();
        EmailMessage emailmsg = Datagenerator.insertEmailMsg(acc.Id);
        Map<Object,Object>inMap = new Map<Object,Object>();
        inMap.put('activityData',new Map<Object,Object>{'Id'=>emailmsg.Id});
        inMap.put('Id',acc.Id);
        if(inMap.containsKey('activityData')){
             Map<Object,Object>activityData = (Map<Object,Object>)inMap.get('activityData');
        }
      
       
       // EmailMessage emailMsg = DataGenerator.insertEmailMessage(acc);
       Map<Object, Object> activityData = (Map<Object, Object>)inMap.get('activityData');
        inMap.put('Id',acc.Id);
            String emailId = (String) activityData.get('Id');
            
            try {
                emailmsg = [Select Id ,FromName,FromAddress,ToAddress,CcAddress,BccAddress,Subject,CreatedDate,HtmlBody,TextBody from EmailMessage where Id = :emailId];
            } catch (Exception e) {
                System.debug(e.getMessage());
            }
         
        inMap.put('activityData', new Map<Object,Object>{'Id'=>emailmsg.Id});
        GoGCustomEmailSendToAndCc test =new GoGCustomEmailSendToAndCc();
         Map < Object, Object > returnValue = test.invoke('',inMap);
                      
        System.assert(returnValue.containsKey('to'));
        System.assert(returnValue.containsKey('body'));
        System.assert(returnValue.containsKey('bcc'));
        System.assert(returnValue.containsKey('cc'));     
        
    }
    
    
}