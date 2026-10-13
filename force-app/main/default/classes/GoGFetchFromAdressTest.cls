@isTest
public with sharing class GoGFetchFromAdressTest {
    public static testMethod void GoGFetchFromAdressTest() {

        User thisUser = [select Id from User where Id =: UserInfo.getUserId()];
        System.runAs(thisUser) {
            Account acc = DataGenerator.insertAccount();
            EmailTemplate template = DataGenerator.insertEmailTemplate();

            EmailTemplate templateObj = [SELECT Id, FolderId, Folder.Name FROM EmailTemplate WHERE Id =: String.valueOf(template.Id)];           
            System.debug('templateObj>'+templateObj); 
            celsrm__SRM_Configuration__c WCM_Config = DataGenerator.insertWCMconfig();
            celsrm__Custom_List_View__c customListView= DataGenerator.insertCustomListView(true);
            celsrm__User_Preference__c userPref = DataGenerator.insertUserPreference(customListView.Id);
            List<celsrm__Transaction__c> transList = DataGenerator.transactionInsert(acc,2);
            // EmailTemplate billingTemplateList = [select id, Name, FolderId, Subject, HtmlValue, TemplateType, Body from EmailTemplate where Folder.Name != null and Folder.Name= 'English (United Kingdom)' and IsActive=true and Name='Billing statement' limit 1];
            // EmailTemplate emailTemp = DataGenerator.insertEmailTemplate();
            // System.debug('billingTemplateList>>>>>'+billingTemplateList);

            Map<Object,Object> inMap = new Map<Object,Object>();

            Map<Object,Object> tempComposeEmail = new Map<Object,Object>();
            tempComposeEmail.put('body','body');
            Map<Object,Object> activityData = new Map<Object,Object>();
            activityData.put('celsrm__Category__c','Statement');

            inMap.put('TransactionList',transList);
            inMap.put('ComposeEmail',tempComposeEmail);
            inMap.put('activityData',activityData);
            inMap.put('Locale__c',templateObj.Folder.Name);
            inMap.put('Id',acc.Id);
            //-- Start | FIN-8334 | Changed by Ravi | 11 sep 2025 --//
            inMap.put('TempBody', '<div>body{Transactions.TotalBalance}</div');
            //-- End | FIN-8334 | Changed by Ravi | 11 sep 2025 --//

            try{
                GoGFetchFromAdress test = new GoGFetchFromAdress();
                test.invoke('', inMap);
                List<String> operation = new List<String>{'[{"Field":"Balance__c","Operator":"equals","Value":"121","rowNum":"0"}]',
                                                    '[{"Field":"Balance__c","Operator":"contains","Value":"2","rowNum":"0"}]',
                                                    '[{"Field":"Balance__c","Operator":"does not contain","Value":"2","rowNum":"0"}]',
                                                    '[{"Field":"Balance__c","Operator":"contains in list","Value":"2","rowNum":"0"}]',
                                                    '[{"Field":"Balance__c","Operator":"less than","Value":"122","rowNum":"0"}]',
                                                    '[{"Field":"Balance__c","Operator":"greater than","Value":"121","rowNum":"0"}]',
                                                    '[{"Field":"Balance__c","Operator":"less or equal","Value":"121","rowNum":"0"}]',
                                                    '[{"Field":"Balance__c","Operator":"greater or equal","Value":"121","rowNum":"0"}]',
                                                    '[{"Field":"Balance__c","Operator":"starts with","Value":"1","rowNum":"0"}]',
                                                    '[{"Field":"Balance__c","Operator":"end with","Value":"1","rowNum":"0"}]'};
                List<String> category = new List<String>{'Dispute', 'Promised'};

                for(Integer i =0; i<10; i++){
                    customListView.celsrm__Filter_Criteria__c = operation[i];
                    update customListView;

                    // if(i<2){
                    //     activityData.put('Category__c',category[i]);
                    //     inMap.put('activityData',activityData);
                    // }
                    test.invoke('', inMap);
                }

            }catch(Exception e){
                system.debug('Exception caused>>>>'+e.getLineNumber()+'>>>>>>>>>' + e.getMessage() );
            }
        }    
    }

    public static testMethod void GoGFetchFromAdressTest1(){
        Account acc = DataGenerator.insertAccount();
        celsrm__SRM_Configuration__c WCM_Config = DataGenerator.insertWCMconfig();
        celsrm__Custom_List_View__c customListView= DataGenerator.insertCustomListView(true);
        customListView.celsrm__ListView_For_Object__c = 'Dispute__c';
        customListView.celsrm__Object_Fields__c = 'name,balance__c,Account__c';
        update customListView;

        List<celsrm__Transaction__c> transList = DataGenerator.transactionInsert(acc,2);

        Map<Object,Object> inMap = new Map<Object,Object>();

        Map<Object,Object> tempComposeEmail = new Map<Object,Object>();
        tempComposeEmail.put('body','body');
        Map<Object,Object> activityData = new Map<Object,Object>();
        activityData.put('celsrm__Category__c','Dispute');

        inMap.put('TransactionList',transList);
        inMap.put('ComposeEmail',tempComposeEmail);
        inMap.put('activityData',activityData);
        inMap.put('Locale__c','English (United Kingdom)');
        inMap.put('Id',acc.Id);
        inMap.put('TransactionList_SortColumn','celsrm__Balance__c');
        inMap.put('TransactionList_SortOrder','ASC');
        //-- Start | FIN-8334 | Changed by Ravi | 11 sep 2025 --//
        inMap.put('TempBody', '<div>body{Transactions.TotalBalance}, {Disputes.summary}body</div>');
        //-- End | FIN-8334 | Changed by Ravi | 11 sep 2025 --//

        try{
            GoGFetchFromAdress test = new GoGFetchFromAdress();
            System.debug('Test@123');
            test.invoke('', inMap);
        }catch(Exception e){
            system.debug('Exception caused>>>>'+e.getLineNumber()+'>>>>>>>>>' + e.getMessage() );
        }
    } 

    public static testMethod void GoGFetchFromAdressTest2(){
        Account acc = DataGenerator.insertAccount();
        celsrm__SRM_Configuration__c WCM_Config = DataGenerator.insertWCMconfig();
        celsrm__Custom_List_View__c customListView= DataGenerator.insertCustomListView(true);
        List<celsrm__Transaction__c> transList = DataGenerator.transactionInsert(acc,2);

        Map<Object,Object> inMap = new Map<Object,Object>();

        Map<Object,Object> tempComposeEmail = new Map<Object,Object>();
        tempComposeEmail.put('body','body');
        Map<Object,Object> activityData = new Map<Object,Object>();
        activityData.put('celsrm__Category__c','Promised');

        inMap.put('TransactionList',transList);
        inMap.put('ComposeEmail',tempComposeEmail);
        inMap.put('activityData',activityData);
        inMap.put('Locale__c','English (United Kingdom)');
        inMap.put('Id',acc.Id);
        //-- Start | FIN-8334 | Changed by Ravi | 11 sep 2025 --//
        inMap.put('TempBody', '<div>{Transactions.TotalBalance}</div>');
        //-- End | FIN-8334 | Changed by Ravi | 11 sep 2025 --//

        try{
            GoGFetchFromAdress test = new GoGFetchFromAdress();
            test.invoke('', inMap);
        }catch(Exception e){
            system.debug('Exception caused>>>>'+e.getLineNumber()+'>>>>>>>>>' + e.getMessage() );
        }
    } 
}