@isTest
public with sharing class FetchOutOfOfficeDetailTest {
    

    public static testmethod void Test1(){
		Map<Object, Object> inMap = new Map<Object, Object>();
        Map<Object, Object> aData = new Map<Object, Object>();
        Account acc = DataGenerator.insertAccount();
        List<Contact> con = DataGenerator.insertContact(acc, 2);
        EmailMessage em = DataGenerator.insertEmailMsg(acc.Id);
        OrgWideEmailAddress owd = [SELECT Id, Address FROM OrgWideEmailAddress LIMIT 1];
        aData.put('FromAddress', owd.Address);
        aData.put('Id', em.Id);
        aData.put('ToAddress', owd.Address);
        aData.put('FromName', 'Test');
        aData.put('RelatedToId',acc.Id);
        aData.put('Subject',em.Subject);
        aData.put('CreatedDate',Date.Today());
        aData.put('HtmlBody',em.HtmlBody);
        inMap.put('activityData', aData);
        FetchOutOfOfficeDetail obj = new FetchOutOfOfficeDetail();
        obj.invoke('', inMap); 
        try{
          
        }catch(Exception e){
           system.debug('Error');
        }
        //em.celsrm__Classification_Response__c = '{}';
         update em;
         
         try{
            obj.invoke('testEmailOption', inMap); 
         }catch(Exception e){
            system.debug('Error');
         }
         try{
            Map<Object,Object> assign = new Map<Object,Object>();
            assign.put('id', acc.OwnerId);
            assign.put('name', acc.Owner.name);
            inMap.put('assignTo', assign);
            inMap.put('SingleEmail', 'false');
            obj.invoke('submitOutOfOffice', inMap); 
         }catch(Exception e){
            system.debug('Error');
         }
         inMap.put('Action', 'createTask');
         try{
            obj.invoke('submitOutOfOffice', inMap); 
         }catch(Exception e){
            system.debug('Error');
         }  
         inMap.put('Action', 'forwardEmail');
         try{
            obj.invoke('submitOutOfOffice', inMap); 
         }catch(Exception e){
            system.debug('Error');
         }  
        // Insert a test OrgWideEmailAddress record
        
        // inMap.get('activityData')
    }
}