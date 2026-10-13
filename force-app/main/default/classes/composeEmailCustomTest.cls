@isTest
public with sharing class composeEmailCustomTest {
    public static testmethod void composeEmailCustomTest() {

        Map<Object, Object> currentValues = new Map<Object, Object>();
        Map<String,Object> mapOfExtraParam = new Map<String,Object>();

        User thisUser = [select Id from User where Id =: UserInfo.getUserId()];
        System.runAs(thisUser) {
            EmailTemplate temp = DataGenerator.insertTemplate();
            Account acc = DataGenerator.insertAccount();
            List<Contact> con = DataGenerator.insertContact(acc, 2);
            EmailMessage em = DataGenerator.insertEmailMsg(acc.Id);
            celsrm__Custom_List_View__c CLV = DataGenerator.insertCustomListView(true);
            CLV.Name = 'System Default View';
            update CLV;

            celsrm__User_Preference__c userPref = DataGenerator.insertUserPreference(CLV.Id);

            List<Object> ObjList = new List<Object>();
            Map<Object,Object> objMap1 = new Map<Object,Object>();
            objMap1.put('Id',acc.Id);
            objList.add(objMap1);

            currentValues.put('Id', acc.Id);
            currentValues.put('ListView', CLV.Id);
            currentValues.put('TransactionList', ObjList);
            currentValues.put('TransactionList_SortColumn', 'celsrm__Balance__c');
            currentValues.put('TransactionList_SortOrder', 'ASC');

            composeEmailCustom.invoke(currentValues, temp.Id, mapOfExtraParam, 'GoGCustomEmailSendToAndCc');

            composeEmailCustom.invoke(currentValues, temp.Id, mapOfExtraParam, 'composeEmailCustom');

            currentValues.put('TransactionList', null);
            currentValues.put('screenName', 'Send Statement');
            currentValues.put('IsIncludeChild', true);
            composeEmailCustom.invoke(currentValues, temp.Id, mapOfExtraParam, 'composeEmailCustom');

            currentValues.put('IsIncludeChild', false);
            composeEmailCustom.invoke(currentValues, temp.Id, mapOfExtraParam, 'composeEmailCustom');
        }
    }

    public static testmethod void composeEmailTaskTest() {

        Map<Object, Object> currentValues = new Map<Object, Object>();
        Map<String,Object> mapOfExtraParam = new Map<String,Object>();
        celsrm__SRM_Configuration__c systemConfig = DataGenerator.insertWCMconfig();

        Account acc = DataGenerator.insertAccount();
        String accountCriteria = '{"criteria":[{"operator":"=","field":"Name","value":"Test Account"},{"operator":"=","field":"IsDeleted","value":"abcd"}],"criteriaCondition":"( 1  OR 2 )"}';
        String treatmentstep = '[{"stepName":"Proactive Email","order":1,"criteria":[{"operator":">","field":"celsrm__Amount__c","value":"0"}],"criteriaCondition":"( 1  OR 1 )","active":true,"taskType":["Email","Call"],"description":"","showTotal":true,"aggregationField":"celsrm__Amount__c","columns":["Name","celsrm__Account__c","celsrm__Amount__c","celsrm__Balance__c","celsrm__So_Number__c","celsrm__Po_Number__c","celsrm__DPD__c","celsrm__Due_Date__c","celsrm__Create_Date__c","CreatedById"]}]';
        celsrm__Transaction__c transId = DataGenerator.insertTransaction(acc);
        celsrm__Treatment__c tre = DataGenerator.insertTreatmentRecord('','Test1',accountCriteria,'celsrm__Transaction__c',treatmentstep,'Call;Email',5,true,'','Bigger Account & Good Payer','#FFFFFF','','Test1', false);

    
        Task tsk = new Task();
        tsk.Subject = 'Proactive Email';
        tsk.Status = 'Not Started';
        tsk.WhatId = acc.Id;
        tsk.TaskSubtype = 'Call';
        tsk.celsrm__Treatment__c = tre.id;
        tsk.IsReminderSet = true;
        tsk.ReminderDateTime = Datetime.now();
        insert tsk;

        User thisUser = [select Id from User where Id =: UserInfo.getUserId()];
        System.runAs(thisUser) {
            EmailTemplate emailTemp = DataGenerator.insertTemplate();
            List<Contact> con = DataGenerator.insertContact(acc, 2);
            EmailMessage em = DataGenerator.insertEmailMsg(acc.Id);
            celsrm__Custom_List_View__c CLV = DataGenerator.insertCustomListView(true);
            CLV.Name = 'System Default View';
            update CLV;


            List<string> stepList = new list<string>();
            stepList.add('Proactive Email');

            List<Object> stepA = new List<Object>();
            Map<Object,Object> step1 = new Map<Object,Object>();
            step1.put('isSelected', true);
            step1.put('Id', transId.id);
            step1.put('celsrm__Amount__c', 0);
            step1.put('celsrm__Balance__c', 100);
            step1.put('celsrm__So_Number__c', '#0456');
            step1.put('celsrm__Create_Date__c', Date.today());
            stepA.add(step1);
            
            list<Map<object,Object>> listofField = new list<Map<object,Object>>();
            Map<object,Object> m_key_value = new Map<object,Object>();
            m_key_value.put('label','Name');
            m_key_value.put('fieldName','Name');
            m_key_value.put('type','html');
            m_key_value.put('sortable',false);
            listofField.add(m_key_value);
            Map<object,Object> m_key_value1 = new Map<object,Object>();
            m_key_value1.put('label','celsrm__Balance__c');
            m_key_value1.put('fieldName','celsrm__Balance__c');
            m_key_value1.put('type','CURRENCY');
            m_key_value1.put('sortable',false);
            listofField.add(m_key_value1);
            Map<object,Object> m_key_value2 = new Map<object,Object>();
            m_key_value2.put('label','celsrm__Base_Currency__c');
            m_key_value2.put('fieldName','celsrm__Base_Currency__c');
            m_key_value2.put('type','CURRENCY');
            m_key_value2.put('sortable',false);
            listofField.add(m_key_value2);
            Map<object,Object> m_key_value3 = new Map<object,Object>();
            m_key_value3.put('label','celsrm__Discount_Date__c');
            m_key_value3.put('fieldName','celsrm__Discount_Date__c');
            m_key_value3.put('type','DATE');
            m_key_value3.put('sortable',false);
            listofField.add(m_key_value3);
            Map<object,Object> m_key_value4 = new Map<object,Object>();
            m_key_value4.put('label','CreatedDate');
            m_key_value4.put('fieldName','CreatedDate');
            m_key_value4.put('type','DATETIME');
            m_key_value4.put('sortable',false);
            listofField.add(m_key_value4);
            
            list<Map<object,Object>> listofValue = new list<Map<object,Object>>();
            Map<object,Object> m_key_valueObject = new Map<object,Object>();
            m_key_valueObject.put('celsrm__Transaction__c','celsrm__Transaction__c');
            m_key_valueObject.put('celsrm__Balance__c',200);
            m_key_valueObject.put('CreatedDate','2015-09-28T21:43:36.000z');
            m_key_valueObject.put('celsrm__Discount_Date__c',Date.today());
            m_key_valueObject.put('celsrm__Base_Currency__c','USD');
            m_key_valueObject.put('Name','Name');
            listofValue.add(m_key_valueObject);

            list<Object> transcIdList = new list<Object>();
            transcIdList.add(transId.id);

            Map<Object, Object> inMapForFormattingEmail = new  Map<Object, Object>();   
            inMapForFormattingEmail.put('accountId',acc.id);
            inMapForFormattingEmail.put('Id',tsk.id);
            inMapForFormattingEmail.put('EmailTemplate',emailTemp.id);
            inMapForFormattingEmail.put('objectName','celsrm__Transaction__c');
            inMapForFormattingEmail.put('listOfStep',stepList);
            inMapForFormattingEmail.put('Proactive Email',stepA);
            inMapForFormattingEmail.put('Proactive Email'+'value',listofValue);
            inMapForFormattingEmail.put('Proactive Email'+'columns',listofField);
            inMapForFormattingEmail.put('Proactive Email'+'description','this is test');
            inMapForFormattingEmail.put('Proactive Email'+'aggregationField','celsrm__Balance__c');
            inMapForFormattingEmail.put('Proactive Email'+'showTotal',true);
            inMapForFormattingEmail.put('Proactive Email'+'totalTitle','celsrm__Balance__c');
            inMapForFormattingEmail.put('childObjectIds', transcIdList);
            inMapForFormattingEmail.put('taskSubject', 'Proactive Email');
            inMapForFormattingEmail.put('isTaskScreen', true);
            inMapForFormattingEmail.put('seperateTaskForStep', true);
            inMapForFormattingEmail.put('treatmentStage', 'Proactive Email');
            composeEmailCustom.invoke(inMapForFormattingEmail, emailTemp.Id, new Map<String,Object>(), 'setDataFormattingForTreatment');

            // trtDataForEmail.invoke(inMapForFormattingEmail, null, null);
            list<Map<String,Object>> listofField1 = new list<Map<String,Object>>();
            Map<String,Object> m_key_valuee = new Map<String,Object>();
            m_key_valuee.put('label','Name');
            m_key_valuee.put('fieldName','Name');
            m_key_valuee.put('type','html');
            m_key_valuee.put('sortable',false);
            listofField1.add(m_key_valuee);
            Map<String,Object> m_key_valuee1 = new Map<String,Object>();
            m_key_valuee1.put('label','celsrm__Balance__c');
            m_key_valuee1.put('fieldName','celsrm__Balance__c');
            m_key_valuee1.put('type','CURRENCY');
            m_key_valuee1.put('sortable',false);
            listofField1.add(m_key_valuee1);
            Map<String,Object> m_key_valuee2 = new Map<String,Object>();
            m_key_valuee2.put('label','celsrm__Base_Currency__c');
            m_key_valuee2.put('fieldName','celsrm__Base_Currency__c');
            m_key_valuee2.put('type','CURRENCY');
            m_key_valuee2.put('sortable',false);
            listofField1.add(m_key_valuee2);
            Map<String,Object> m_key_valuee3 = new Map<String,Object>();
            m_key_valuee3.put('label','celsrm__Discount_Date__c');
            m_key_valuee3.put('fieldName','celsrm__Discount_Date__c');
            m_key_valuee3.put('type','DATE');
            m_key_valuee3.put('sortable',false);
            listofField1.add(m_key_valuee3);
            Map<String,Object> m_key_valuee4 = new Map<String,Object>();
            m_key_valuee4.put('label','CreatedDate');
            m_key_valuee4.put('fieldName','CreatedDate');
            m_key_valuee4.put('type','DATETIME');
            m_key_valuee4.put('sortable',false);
            listofField1.add(m_key_valuee4);
            Map<String,Object> m_key_valuee5 = new Map<String,Object>();
            m_key_valuee5.put('label','Acc');
            m_key_valuee5.put('fieldName','celsrm__Account__c');
            m_key_valuee5.put('type','html');
            m_key_valuee5.put('sortable',false);
            listofField1.add(m_key_valuee5);
            Map<String,Object> m_key_valuee6 = new Map<String,Object>();
            m_key_valuee6.put('label','createdby');
            m_key_valuee6.put('fieldName','CreatedById');
            m_key_valuee6.put('type','html');
            m_key_valuee6.put('sortable',false);
            listofField1.add(m_key_valuee6);
            inMapForFormattingEmail.put('Proactive Email'+'columns',listofField1);
            inMapForFormattingEmail.put('seperateTaskForStep', false);
            composeEmailCustom.invoke(inMapForFormattingEmail, emailTemp.Id, new Map<String,Object>(), 'setDataFormattingForTreatment');

            update systemConfig;
            composeEmailCustom.invoke(inMapForFormattingEmail, emailTemp.Id, new Map<String,Object>(), 'setDataFormattingForTreatment');

        }
    }

    public static testmethod void composeEmailTaskAddsAccountOwnerToCcWhenNotifyEnabled() {
        DataGenerator.insertWCMconfig();

        Account acc = DataGenerator.insertAccount();
        DataGenerator.insertDefaultContact(acc);

        String accountCriteria = '{"criteria":[{"operator":"=","field":"Name","value":"Test Account"}],"criteriaCondition":"( 1 )"}';
        String treatmentstep = '[{"stepName":"Proactive Email","order":1,"criteria":[{"operator":">","field":"celsrm__Amount__c","value":"0"}],"criteriaCondition":"( 1 )","active":true,"taskType":["Email"],"description":"","showTotal":true,"aggregationField":"celsrm__Amount__c","columns":["Name"]}]';
        celsrm__Treatment__c tre = DataGenerator.insertTreatmentRecord('', 'Notify Owner Treatment', accountCriteria, 'celsrm__Transaction__c', treatmentstep, 'Email', 5, true, '', 'Bigger Account & Good Payer', '#FFFFFF', '', 'Notify Owner Treatment', false);
        tre.put('celsrm__Notify_Account_Owner__c', true);
        update tre;

        Task tsk = new Task();
        tsk.Subject = 'Proactive Email';
        tsk.Status = 'Not Started';
        tsk.WhatId = acc.Id;
        tsk.TaskSubtype = 'Call';
        tsk.celsrm__Treatment__c = tre.Id;
        tsk.IsReminderSet = true;
        tsk.ReminderDateTime = Datetime.now();
        insert tsk;

        User currentUser = [SELECT Id, Email FROM User WHERE Id = :UserInfo.getUserId()];
        System.assertNotEquals(null, currentUser.Email, 'The running user must have an email for this test.');

        Map<Object, Object> currentValues = new Map<Object, Object>{
            'Id' => tsk.Id,
            'accountId' => acc.Id
        };

        Test.startTest();
        Map<String, Object> result = composeEmailCustom.invoke(currentValues, null, null, 'GoGCustomEmailSendToAndCc');
        Test.stopTest();

        List<String> ccValues = (List<String>)result.get('cc');
        System.assertNotEquals(null, ccValues, 'CC should be populated when notify account owner is enabled.');
        System.assert(ccValues.contains(currentUser.Email), 'CC should include the account owner email when notify account owner is enabled.');
    }

    public static testmethod void composeEmailTaskAddsAccountOwnerToCcFromStepWhenSeparateTaskEnabled() {
        DataGenerator.insertWCMconfig();

        Account acc = DataGenerator.insertAccount();
        DataGenerator.insertDefaultContact(acc);

        String accountCriteria = '{"criteria":[{"operator":"=","field":"Name","value":"Test Account"}],"criteriaCondition":"( 1 )"}';
        String treatmentstep = '[{"stepName":"Proactive Email","taskSubject":"Proactive Email","order":1,"criteria":[{"operator":">","field":"celsrm__Amount__c","value":"0"}],"criteriaCondition":"( 1 )","active":true,"taskType":["Email"],"description":"","showTotal":true,"aggregationField":"celsrm__Amount__c","columns":["Name"],"notifyAccountOwner":true}]';
        celsrm__Treatment__c tre = DataGenerator.insertTreatmentRecord('', 'Separate Notify Owner Treatment', accountCriteria, 'celsrm__Transaction__c', treatmentstep, 'Email', 5, true, '', 'Bigger Account & Good Payer', '#FFFFFF', '', 'Separate Notify Owner Treatment', true);
        tre.put('celsrm__Notify_Account_Owner__c', false);
        update tre;

        Task tsk = new Task();
        tsk.Subject = 'Proactive Email';
        tsk.Status = 'Not Started';
        tsk.WhatId = acc.Id;
        tsk.TaskSubtype = 'Call';
        tsk.celsrm__Treatment__c = tre.Id;
        tsk.celsrm__Treatment_Stage__c = 'Proactive Email';
        tsk.IsReminderSet = true;
        tsk.ReminderDateTime = Datetime.now();
        insert tsk;

        User currentUser = [SELECT Id, Email FROM User WHERE Id = :UserInfo.getUserId()];
        System.assertNotEquals(null, currentUser.Email, 'The running user must have an email for this test.');

        Map<Object, Object> currentValues = new Map<Object, Object>{
            'Id' => tsk.Id,
            'accountId' => acc.Id
        };

        Test.startTest();
        Map<String, Object> result = composeEmailCustom.invoke(currentValues, null, null, 'GoGCustomEmailSendToAndCc');
        Test.stopTest();

        List<String> ccValues = (List<String>)result.get('cc');
        System.assertNotEquals(null, ccValues, 'CC should be populated when step notify account owner is enabled.');
        System.assert(ccValues.contains(currentUser.Email), 'CC should include the account owner email when the matching step notify flag is enabled.');
    }

    //-- FIN-9729 | Changed by Dilshad | 05-May-2026 | Start --//
    public static testmethod void updateComposeEmailBodyUsesUserPreferenceListViewForSendStatement() {
        Account acc = DataGenerator.insertAccount();
        DataGenerator.insertContact(acc, 2);
        DataGenerator.insertTransaction(acc);
        celsrm__Custom_List_View__c listView = DataGenerator.insertCustomListView(false);
        DataGenerator.insertUserPreference(listView.Id);

        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        EmailTemplate templateRecord;
        System.runAs(thisUser) {
            templateRecord = buildUpdateComposeEmailTemplate('UpdateComposeEmailBodySendStatement');
            insert templateRecord;
        }

        Map<Object, Object> currentValues = new Map<Object, Object>{
            'Id' => acc.Id,
            'screenName' => 'Send Statement'
        };
        // START - MM - FIN-7983 - Test Coverage
        currentValues.put('AttachCheckBox', true);
        // END - MM - FIN-7983 - Test Coverage
        Test.startTest();
        Map<String, Object> result = composeEmailCustom.invoke(
            currentValues,
            templateRecord.Id,
            new Map<String, Object>(),
            'updateComposeEmailBody'
        );
        Test.stopTest();

        Map<Object, Object> composeEmail = (Map<Object, Object>)result.get('ComposeEmail');
        String htmlBody = String.valueOf(result.get('htmlBody'));

        System.assertNotEquals(null, composeEmail, 'ComposeEmail should be returned for the update-compose-email flow.');
        System.assertEquals(htmlBody, String.valueOf(composeEmail.get('body')), 'htmlBody should mirror ComposeEmail.body.');
        System.assertEquals(String.valueOf(templateRecord.Id), String.valueOf(composeEmail.get('templateId')), 'ComposeEmail should use the selected template Id.');
        System.assertEquals(templateRecord.Name, String.valueOf(composeEmail.get('templateName')), 'ComposeEmail should use the selected template name.');
        System.assertEquals('Update Compose Subject', String.valueOf(result.get('subject')), 'The rendered template subject should be returned.');
        System.assertEquals(-1, htmlBody.indexOf('{Transaction.Summary}'), 'The transaction summary token should be replaced.');
        System.assertEquals(-1, htmlBody.indexOf('{Transactions.TotalBalance}'), 'The total-balance token should be replaced.');
        System.assert(htmlBody.toLowerCase().contains('<table'), 'The updated email body should include the rendered transaction summary table.');
    }

    public static testmethod void updateComposeEmailBodyUsesDefaultListViewWhenScreenIsNotSendStatement() {
        Account acc = DataGenerator.insertAccount();
        DataGenerator.insertContact(acc, 2);
        DataGenerator.insertTransaction(acc);
        DataGenerator.insertCustomListView(false);

        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        EmailTemplate templateRecord;
        System.runAs(thisUser) {
            templateRecord = buildUpdateComposeEmailTemplate('UpdateComposeEmailBodyDefaultView');
            insert templateRecord;
        }

        Map<Object, Object> currentValues = new Map<Object, Object>{
            'Id' => acc.Id,
            'screenName' => 'Account Overview'
        };
        // START - MM - FIN-7983 - Test Coverage
        currentValues.put('AttachCheckBox', true);
        // END - MM - FIN-7983 - Test Coverage

        Test.startTest();
        Map<String, Object> result = composeEmailCustom.invoke(
            currentValues,
            templateRecord.Id,
            new Map<String, Object>(),
            'updateComposeEmailBody'
        );
        Test.stopTest();

        String htmlBody = String.valueOf(result.get('htmlBody'));
        System.assertNotEquals(null, result.get('ComposeEmail'), 'A ComposeEmail payload should be built when the default list view is resolved.');
        System.assertEquals('Update Compose Subject', String.valueOf(result.get('subject')), 'The rendered template subject should be returned.');
        System.assert(htmlBody.toLowerCase().contains('<table'), 'The default list-view branch should still build the transaction summary table.');
    }

    public static testmethod void updateComposeEmailBodyReplacesStaleTemplateContext() {
        Account acc = DataGenerator.insertAccount();
        DataGenerator.insertContact(acc, 2);
        DataGenerator.insertTransaction(acc);
        DataGenerator.insertCustomListView(false);

        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        EmailTemplate selectedTemplate;
        System.runAs(thisUser) {
            selectedTemplate = buildUpdateComposeEmailTemplate('UpdateComposeEmailBodySelectedTemplate');
            insert selectedTemplate;
        }

        Map<Object, Object> currentValues = new Map<Object, Object>{
            'Id' => acc.Id,
            'screenName' => 'Account Overview',
            'ComposeEmail' => new Map<Object, Object>{
                'templateId' => '00X000000000000AAA',
                'templateName' => 'Stale Template',
                'subject' => 'Stale Subject',
                'body' => '<div>Stale Body</div>'
            }
        };

        currentValues.put('AttachCheckBox', true);
        Test.startTest();
        Map<String, Object> result = composeEmailCustom.invoke(
            currentValues,
            selectedTemplate.Id,
            new Map<String, Object>(),
            'updateComposeEmailBody'
        );
        Test.stopTest();

        Map<Object, Object> composeEmail = (Map<Object, Object>)result.get('ComposeEmail');
        System.assertEquals(String.valueOf(selectedTemplate.Id), String.valueOf(composeEmail.get('templateId')), 'Stale template Id should be replaced with the selected template Id.');
        System.assertEquals(selectedTemplate.Name, String.valueOf(composeEmail.get('templateName')), 'Stale template name should be replaced with the selected template name.');
        System.assertNotEquals('Stale Body', String.valueOf(composeEmail.get('body')), 'The returned body should be generated from the selected template.');
    }

    public static testmethod void updateComposeEmailBodyUsesSummaryAgentShortcut() {
        Map<Object, Object> currentValues = new Map<Object, Object>{
            'openFromSummaryAgent' => true,
            'summaryArguments' => JSON.serialize(new Map<String, Object>{
                'email_response' => '<div>Agent generated body</div>'
            }),
            'activityData' => new Map<Object, Object>{
                'Subject' => 'Agent Subject'
            }
        };

        Test.startTest();
        Map<String, Object> result = composeEmailCustom.invoke(
            currentValues,
            null,
            new Map<String, Object>(),
            'updateComposeEmailBody'
        );
        Test.stopTest();

        System.assertEquals('<div>Agent generated body</div>', String.valueOf(result.get('htmlBody')), 'The summary-agent shortcut should return the provided AI-composed body.');
        System.assertEquals('Agent Subject', String.valueOf(result.get('subject')), 'The summary-agent shortcut should preserve the activity subject.');
    }

    private static EmailTemplate buildUpdateComposeEmailTemplate(String templateName) {
        EmailTemplate templateRecord = new EmailTemplate();
        templateRecord.Name = templateName;
        templateRecord.DeveloperName = templateName;
        templateRecord.FolderId = UserInfo.getUserId();
        templateRecord.Subject = 'Update Compose Subject';
        templateRecord.Body = '<div>Compose Email Test</div><div>{Transaction.Summary}</div><div>{Transactions.TotalBalance}</div>';
        templateRecord.HtmlValue = '<div>Compose Email Test</div><div>{Transaction.Summary}</div><div>{Transactions.TotalBalance}</div>';
        templateRecord.TemplateType = 'custom';
        templateRecord.IsActive = true;
        return templateRecord;
    }
    //-- FIN-9729 | Changed by Dilshad | 05-May-2026 | End --//
}