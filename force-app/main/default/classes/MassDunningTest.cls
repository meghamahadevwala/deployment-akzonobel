@isTest
public with sharing class MassDunningTest {
    public static testMethod void MassDunningTest() {

        User thisUser = [select Id from User where Id =: UserInfo.getUserId()];
        System.runAs(thisUser) {
            String accountCriteria = '{"criteria":[{"operator":"=","field":"Name","value":"Test Account"},{"operator":"=","field":"IsDeleted","value":"abcd"}],"criteriaCondition":"( 1  OR 2 )"}';
            String treatmentstep = '[{"stepName":"Proactive Email","order":1,"criteria":[{"operator":">","field":"celsrm__Amount__c","value":"0"}],"criteriaCondition":"( 1  OR 1 )","active":true,"taskType":["Email","Call"],"description":"","showTotal":true,"aggregationField":"celsrm__Amount__c","columns":["Name","celsrm__Account__c","celsrm__Amount__c","celsrm__Balance__c","celsrm__So_Number__c","celsrm__Po_Number__c","celsrm__DPD__c","celsrm__Due_Date__c","celsrm__Create_Date__c","CreatedById"]}]'; //-- Starts | FIN-8207 | Change by Asera | 19-Aug-25 //
            EmailTemplate temp = DataGenerator.insertTemplate();
            celsrm__Treatment__c tre = DataGenerator.insertTreatmentRecord('','Test1',accountCriteria,'celsrm__Transaction__c',treatmentstep,'Email',5,true,'','Bigger Account & Good Payer','#FFFFFF',temp.Id,'Test1', false);
            tre.OwnerId = thisUser.Id;
            tre.celsrm__Active__c = true;
            update tre;
            Account acc = DataGenerator.insertAccount();
            acc.OwnerId = thisUser.Id;
            update acc;

            List<Task> taskObj = DataGenerator.inserTreatmentTask(acc, 2, tre.Id);
            List<Contact> conList = DataGenerator.insertContact(acc,1);
            celsrm__Transaction__c transId = DataGenerator.insertTransaction(acc);

            ContentVersion cv = new ContentVersion();
            cv.Title = 'Treatment Details';
            cv.PathOnClient = 'treatmentdetails.json';
            cv.VersionData = Blob.valueOf('{"Proactive Email":["'+ transId.Id +'"]}');
            cv.OwnerId = acc.OwnerId;
            cv.IsMajorVersion = true;
            Insert cv;

            List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];
            //create ContentDocumentLink record
            // ContentDocumentLink cdl = new ContentDocumentLink();
            // cdl.LinkedEntityId = opp.Id;
            // cdl.ContentDocumentId = documents[0].Id;
            // cdl.ShareType = 'V';
            // cdl.Visibility = 'AllUsers';
            // insert cdl;

            ContentDocumentLink testContentDocLink = new ContentDocumentLink(
                ContentDocumentId = documents[0].Id,
                LinkedEntityId = taskObj[0].Id,
                ShareType = 'V',
                Visibility = 'AllUsers'
            );
            insert testContentDocLink;

            Map<Object, Object> inMap = new  Map<Object, Object>();
            inMap.put('TreatmentFilter', tre.Id);
            inMap.put('AccountFilter', acc.Id);

            MassDunningController massDunningObj = new MassDunningController();
            massDunningObj.invoke('onLoadMassDunningScreen', inMap);
            massDunningObj.invoke('fetchTreatmentNames', inMap);
            massDunningObj.invoke('fetchTreatmentAccounts', inMap);
            massDunningObj.invoke('fetchTaskList', inMap);
            
            List<Map<Object, Object>> editableTaskList = new List<Map<Object, Object>>();
            for(Task task : (List<task>)inMap.get('editableTaskList')){
                Map<Object, Object> tmap = new Map<Object, Object>();
                tmap.put('celsrm__To__c', 'test@celonis.com');
                tmap.put('celsrm__Cc__c', 'test@celonis.com');
                tmap.put('Id', task.Id);
                tmap.put('isSelected', true);
                tmap.put('Subject', 'test email subject');
                tmap.put('AccountId', acc.Id);
                editableTaskList.add(tmap);
            }
            inMap.put('editableTaskList', editableTaskList);

            // list<Object> toList = new list<Object>();
            // toList.add('test@test.com');
            // toList.add('test12@test.com');
            // toList.add('test123@test.com');
            // Map<Object, Object> objMap1 = new Map<Object, Object>();
            // objMap1.put('to', toList);
            // objMap1.put('cc', toList);
            // objMap1.put('bcc', toList);
            // objMap1.put('subject', 'Testing Mail');
            // objMap1.put('body', 'Testing Mail');
            // //objMap1.put('from', acc);

            // list<Object> transcIdList = new list<Object>();
            // transcIdList.add(transId.id);
            // inMap.put('Id', taskObj[0].Id);
            // inMap.put('ComposeEmail', objMap1);
            // inMap.put('accountId', acc.id);
            // inMap.put('childObjectIds', transcIdList);
            massDunningObj.invoke('sendMassDunningEmails', inMap);
        }
        

    }
}