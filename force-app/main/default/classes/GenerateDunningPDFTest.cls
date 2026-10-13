@isTest 
public class GenerateDunningPDFTest {
    public static testMethod void Case() {
        try{
            Account acc = DataGenerator.insertAccount();
            List<Contact> conList = DataGenerator.insertContact(acc,1);
            celsrm__Custom_List_View__c cl = DataGenerator.insertCustomListView(True);
            // celsrm__Custom_List_View__c cl1 = DataGenerator.insertCustomListView(False);
            celsrm__Temp_Object_Holder__c tempObjholder = DataGenerator.insertTempObjHolder();
            EmailTemplate TempEmailTemplate = DataGenerator.insertEmailTemplate();
            List<Task> tsk = DataGenerator.insertTask(acc,1);
            celsrm__SRM_Configuration__c SRMconfig = DataGenerator.insertWCMconfig();

            // List<OrgWideEmailAddress> listName = [SELECT Id, Address, DisplayName FROM OrgWideEmailAddress];

            Map<Object, Object> automatedTask = new Map<object,object>() ;
            automatedTask.put('Id', tsk[0].Id);
            automatedTask.put('WhatId', acc.Id);
            automatedTask.put('Type', 'Call');
            automatedTask.put('Subject', TempEmailTemplate.Name);
            automatedTask.put('celsrm__To__c', 'test@test.com');
            automatedTask.put('celsrm__Bcc__c', 'test@test.com');
            automatedTask.put('celsrm__Cc__c', 'test@test.com');

            Map<String, String> returnTemplateAmount = new Map<String,String>();
            returnTemplateAmount.put('TotalBalance', '100');
            returnTemplateAmount.put('TotalBalanceWithoutCurrency', '100');
            returnTemplateAmount.put('TotalBalanceSummary', '100');
            

            System.assertEquals(acc.Id,tsk[0].WhatID);
            GenerateDunningPDF w1 = new GenerateDunningPDF(automatedTask ,tempObjholder.Id,'PDF',(String)cl.Id, returnTemplateAmount);
            GenerateDunningPDF w2 = new GenerateDunningPDF(automatedTask ,tempObjholder.Id,'Excel',(String)cl.Id, returnTemplateAmount);
            Map<Object, Object> automatedTask1 = new Map<object,object>() ;
            automatedTask1.put('Id', tsk[0].Id);
            automatedTask1.put('WhatId', acc.Id);
            automatedTask1.put('Type', 'Call');
            GenerateDunningPDF w3 = new GenerateDunningPDF(automatedTask1 ,null,'Excel',(String)cl.Id, returnTemplateAmount);
            
            List<Object> obj = new List<Object>();
            obj.add(automatedTask1);
            SemiAutoDunningBatch w4 = new SemiAutoDunningBatch(obj ,'Excel',(String)cl.Id);

            Test.startTest();        
            System.enqueueJob(w1);
            System.enqueueJob(w3);
            System.enqueueJob(w2);
            Database.executeBatch(w4,10);
            Test.stopTest();
        } Catch (Exception ex) {
            System.debug('Exception:'+ex.getMessage() + '<<line:: ' + ex.getLineNumber());
        } 
    }
}