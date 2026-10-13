@isTest
public class ActivityComposeEmailControllerTest {
    
    @testSetup
    static void setupData() {
       // Create User Preference
       Account acc = DataGenerator.insertAccount();
       celsrm__User_Preference__c userPref = DataGenerator.insertUserPreference(acc.Id);
       celsrm__Custom_List_View__c customListView  = DataGenerator.insertCustomListView(true);
       EmailTemplate template = DataGenerator.insertEmailTemplate();

       EmailTemplate templateObj = [SELECT Id, FolderId, Folder.Name FROM EmailTemplate WHERE Id =: String.valueOf(template.Id)];   
       celsrm__Transaction__c validTransaction = DataGenerator.insertTransaction(acc);
       celsrm__Temp_Object_Holder__c tempObjHolder =DataGenerator.insertTempObjHolder();
       List<celsrm__Transaction__c> transList = DataGenerator.transactionInsert(acc,2);
       Map<Object,Object> tempComposeEmail = new Map<Object,Object>();
       tempComposeEmail.put('body','body');
        
       celsrm__SRM_Configuration__c systemConfig =  DataGenerator.insertWCMconfig();
       Map<String, List<String>> emailsMap = new Map<String, List<String>>();
       
       List<OrgWideEmailAddress> listName = [SELECT Id, Address, DisplayName FROM OrgWideEmailAddress where address=:systemConfig.Mailbox_Email_Address__c ];
       System.debug('@@ listName : ' + listName);
       List<String> fromadd = new List<String>();
       System.debug('@@ fromAdd : ');
       if (listName  != null ){
        fromadd .add(listName.get(0).Id);
        emailsMap.put('from',fromadd  );
        }
         //-- Starts | FIN-8207 | Change by Asera | 04-Sep-25 //
       // Create the input map with the Account Id
        Map<Object, Object> currentValues = new Map<Object, Object>();
        currentValues.put('Id', acc.Id);
        
        // Call the method under test
        Test.startTest();
        Map<String, Object> result = ActivityComposeEmailController.setDataFormattingForEmail(currentValues, template.Id, new Map<String, Object>(),'TestFunction');
        Test.stopTest();

        // Create the input maps with custom subject data
        Map<Object, Object> composeEmail = new Map<Object, Object>();
        composeEmail.put('subject', 'Custom Subject from ComposeEmail');
        
        Map<Object, Object> activityData = new Map<Object, Object>();
        activityData.put('Subject', 'Custom Subject from ActivityData'); // Note: This field is checked but not used for the final subject.
        currentValues.put('activityData', activityData);
        currentValues.put('ComposeEmail', composeEmail);
        Map<String, Object> result1 = ActivityComposeEmailController.setDataFormattingForEmail(currentValues,template.Id, new Map<String, Object>(), 'TestFunction');
        //-- End | FIN-8207 | Change by Asera | 04-Sep-25 //
    }
    
    @isTest
    static void testActivityDefaultTemplate() {
        // Setup the input map for the test
        Map<Object, Object> inputMap = new Map<Object, Object>();
        inputMap.put('Id', UserInfo.getUserId());
        inputMap.put('Locale__c','en_US');
        inputMap.put('activityData', new Map<Object, Object>{ 'celsrm__Category__c' => 'Promised' });
        String category='Dispute';
        // Call the ActivityDefaultTemplate method
        String whereCondition = '';
        Test.startTest();
        Map < String, List<String> > returnValue = new Map < String, List<String> >();
        returnValue.put('from' ,new List<String>{'test@gmail.com'} );
        Map<Object, Object> resultMap = ActivityComposeEmailController.ActivityDefaultTemplate(inputMap,'celsrm__Transaction__c','All Open',(Id)inputMap.get('Id'), 'Billing statement', category);
        Test.stopTest();
        // Verify the results
        System.assert(resultMap != null);
        System.assert(resultMap.containsKey('TransactionList'), 'TransactionList should be populated');
        System.assert(resultMap.containsKey('TempBody'), 'TempBody should be populated');
    }
    @isTest
    static void testInvokeWithNoSortFields() {
       
        // Prepare input data without sort fields
        Map<Object, Object> currentValues = new Map<Object, Object>();
        currentValues.put('Id', [SELECT Id FROM Account LIMIT 1].Id);
        currentValues.put('ComposeEmail', new Map<String, Object>{ 'body' => 'Test Body' });
        currentValues.put('activityData', new Map<Object, Object>{ 'celsrm__Category__c' => 'Statement' ,'FromAddress' => 'test@gmail.com;test1@gmail.com', 'ToAddress' => 'test@gmail.com;test1@gmail.com' , 'CcAddress' => 'test@gmail.com;test1@gmail.com'}); //-- Starts | FIN-8207 | Change by Asera | 04-Sep-25 //

        
        // Execute the method
        Map<String, Object> result = ActivityComposeEmailController.invoke(currentValues, null, new Map<String, Object>(), 'GoGFetchFromAdress'); 
    }
    
    
    @isTest
    static void testInvokeForPromisedCategory() {
       
        // Prepare input data for Promised category
        Map<Object, Object> currentValues = new Map<Object, Object>();
        currentValues.put('Id', [SELECT Id FROM Account LIMIT 1].Id);
        currentValues.put('ComposeEmail', new Map<String, Object>{ 'body' => 'Test Body' });
        currentValues.put('activityData', new Map<Object, Object>{ 'celsrm__Category__c' => 'Promised' ,'FromAddress' => 'test@gmail.com;test1@gmail.com', 'ToAddress' => 'test@gmail.com;test1@gmail.com' , 'CcAddress' => 'test@gmail.com;test1@gmail.com'});//-- Starts | FIN-8207 | Change by Asera | 04-Sep-25 //

        
        // Execute the method
        Test.startTest();
        Map<String, Object> result = ActivityComposeEmailController.invoke(currentValues, null, new Map<String, Object>(), 'GoGFetchFromAdress');
        Test.stopTest();
        
        // Assertions
        // System.assertNotEquals(null, result.get('body'), 'The body should be set');
    }

     static void testInvokeGoGFetchFromAdress1() {
        // Prepare input data
        
        Map < String, Object > returnValue = new Map < String, Object > ();
        Map<Object, Object> currentValues = new Map<Object, Object>();
        currentValues.put('Id', [SELECT Id FROM Account LIMIT 1].Id);
        currentValues.put('TransactionList_SortColumn', 'TestField');
        currentValues.put('TransactionList_SortOrder', 'ASC');
        currentValues.put('ComposeEmail', new Map<String, Object>{ 'body' => 'Test Body' });
        currentValues.put('activityData', new Map<Object, Object>{ 'celsrm__Category__c' => 'Dispute' ,'FromAddress' => 'test@gmail.com;test1@gmail.com', 'ToAddress' => 'test@gmail.com;test1@gmail.com' , 'CcAddress' => 'test@gmail.com;test1@gmail.com'});
        currentValues.put('TransactionList', new List<Object>{'TestObject'}); //-- Starts | FIN-8207 | Change by Asera | 04-Sep-25 //
        
        // Execute the method
        Map<String, Object> result = ActivityComposeEmailController.invoke(currentValues, null, new Map<String, Object>(), 'GoGFetchFromAdress');
    }
   

}