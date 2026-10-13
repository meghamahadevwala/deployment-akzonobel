@isTest

public with sharing class SendStatementEmailBodyonAccountTest {
    
    public static testMethod void test(){

        User thisUser = [select Id from User where Id =: UserInfo.getUserId()];
        System.runAs(thisUser) {
            EmailTemplate temp = DataGenerator.insertTemplate();
            Account acc = DataGenerator.insertAccount();
            List<Contact> cont = DataGenerator.insertContact(acc, 2);
            EmailMessage emailMsg =  DataGenerator.insertEmailMsg(acc.Id);
            celsrm__Transaction__c trans = DataGenerator.insertTransaction(acc);

			
            Map<String, String> tempAmount = new Map<String, String>();
            tempAmount.put('TotalBalance', '50');

            Map<Object, Object> inMap = new Map<Object, Object>();
            inMap.put('Id', acc.Id);
            inMap.put('ListView', 'TestListView');
            inMap.put('returnTemplateAmount', (Object)tempAmount);
            inMap.put('defaultTemplate','Billing statement');
			inMap.put('returnTemplateAmount',null);
            inMap.put('TransIds',(String)trans.Id);
            
            SendStatementEmailBodyonAccount sentstatement = new SendStatementEmailBodyonAccount();
            sentstatement.invoke('changeListView', inMap);
        }
        

        
    }
}