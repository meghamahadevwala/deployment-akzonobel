@isTest
public with sharing class GOGCreateFollowupTaskTest {
    public static testMethod void testCreateFollowupTask() {
        Account acc = DataGenerator.insertAccount();
        List<celsrm__Transaction__c> transList = DataGenerator.transactionInsert(acc,2);
        List<Task> taskList = DataGenerator.insertTask(acc,1);
        List<Object> objList = new List<Object>();
        Map<Object,Object> transMap = new Map<Object,Object>();
        transMap.put('Id',transList.get(0).Id);
        transMap.put('isSelected',true);
        transMap.put('PromisedAmount',1000.5);
        transMap.put('PromiseDate',Date.today());
        objList.add(transMap);

        Map<Object,Object> compEmail = new Map<Object,Object>();
        compEmail.put('EmailBody','EmailBody');

        Map<Object,Object> inMap = new Map<Object,Object>();
        inMap.put('ggScreenName','WCMPromisToPayScreenEmailAction');
        inMap.put('ContactMethod','Email');
        inMap.put('ComposeEmail',compEmail);
        inMap.put('TransactionList',objList);
        inMap.put('Id',acc.Id);
        inMap.put('NoteBody','NoteBody');
        inMap.put('NoteTitle','NoteTitle');
        inMap.put('isFollowUp',true);
        inMap.put('FollowupDays','2019/12/12');
		GOGCreateFollowupTask test = new GOGCreateFollowupTask();
        try{
           
           test.invoke('', inMap);
        }catch(Exception e){
            system.debug('Exception caused>>>>'+e.getLineNumber()+'>>>>>>>>>' + e.getMessage() );
        }
        try{
            inMap.put('ggScreenName','SRM_SendStatementScreen');
           test.invoke('', inMap);
        }catch(Exception e){
            system.debug('Exception caused>>>>'+e.getLineNumber()+'>>>>>>>>>' + e.getMessage() );
        }
        try{
            inMap.put('NoteBody',null);
            inMap.put('ggScreenName','WCMContactCustomerScreen');
           test.invoke('', inMap);
        }catch(Exception e){
            system.debug('Exception caused>>>>'+e.getLineNumber()+'>>>>>>>>>' + e.getMessage() );
        }
    }
	
	@isTest
    public static void testSendSMS(){
		
		Account acc = DataGenerator.insertAccount();
        List<Contact> listcon = DataGenerator.insertContact(acc,1);
        Contact con = listcon.get(0);

        List<celsrm__Transaction__c> transList = DataGenerator.transactionInsert(acc,2);
        List<Task> taskList = DataGenerator.insertTask(acc,1);
        List<Object> objList = new List<Object>();
        Map<Object,Object> transMap = new Map<Object,Object>();
        transMap.put('Id',transList.get(0).Id);
        transMap.put('isSelected',true);
        transMap.put('PromisedAmount',1000.5);
        transMap.put('PromiseDate',Date.today());
        objList.add(transMap);


        Map<Object,Object> inMap = new Map<Object,Object>();
        
        inMap.put('ContactMethod','Text');
        inMap.put('TransactionList',objList);
        inMap.put('Id',acc.Id);
		inMap.put('WhatsAppNumber','+918200508550');
		inMap.put('WhatsAppNumber','+918200508550');
		inMap.put('WhatsAppMessage','Hello');
		inMap.put('contactRecordId',con.Id);
        GOGCreateFollowupTask test = new GOGCreateFollowupTask();
        
        String response = '{"message":"Hello","status":200}';
		 try{
            inMap.put('ggScreenName','Send Email');
           test.invoke('', inMap);
        }catch(Exception e){
            system.debug('Exception caused>>>>'+e.getLineNumber()+'>>>>>>>>>' + e.getMessage() );
        }
        try{
            inMap.put('ggScreenName','Log A Call');
           test.invoke('', inMap);
        }catch(Exception e){
            system.debug('Exception caused>>>>'+e.getLineNumber()+'>>>>>>>>>' + e.getMessage() );
        }
		System.Test.startTest();
				try{
					System.Test.setMock(HttpCalloutMock.class,new MockCallOutGenerator(response,200));
					inMap.put('ggScreenName','ContactCustomerr');
				   test.invoke('', inMap);
				}catch(Exception e){
					system.debug('Exception caused>>>>'+e.getLineNumber()+'>>>>>>>>>' + e.getMessage() );
				}
            System.Test.stopTest();
	}
}