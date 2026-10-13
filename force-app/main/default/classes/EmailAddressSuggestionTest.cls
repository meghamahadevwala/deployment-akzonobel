@isTest
public with sharing class EmailAddressSuggestionTest {
    public static testMethod void EmailAddressSuggestionTest() {
        try{
            Account acc = DataGenerator.insertAccount();
            List<contact> con = DataGenerator.insertContact(acc,2);
            Map<Object,Object> inMap = new Map<Object,Object>();
            inMap.put('Id',acc.Id);
            EmailAddressSuggestion ACA = new EmailAddressSuggestion();
            ACA.invoke('', inMap);
        }catch(Exception e){
            system.debug('Exception caused>>>>'+e.getLineNumber() + e.getMessage() );
        }
    }
}