public with sharing class DataGenerator {
    public static Account insertAccount() {
        Account validAccount = new Account();
        validAccount.Name = 'Test Account';
        validAccount.celsrm__Account_Key__c =''+(Math.random()* 1000000).intValue() + (Math.random()* 1000000).intValue();
        validAccount.celsrm__Locale__c = 'English (United Kingdom)';
        // validAccount.Rebateable_account_id__c = 'testAccountId';
        
        insert validAccount;
        return validAccount;
    }

    public static List<Contact> insertContact(Account acc,Integer count) {
        List<Contact> conList = new List<Contact>();
        for(Integer i = 0; i < count; i++){
            Contact con = new Contact();
            con.LastName = 'test';
            if(acc != null){
                con.AccountId = acc.Id;
                if (math.mod(i, 2) != 0) {
                    con.celsrm__Default__c = TRUE;
                }
            }
            con.Email = 'test@test.com';            
            con.CC__c = True;
            con.Bcc__c = True;
            conList.add(con);
        }

        insert conList;
        return conList;
    }
    public static Contact insertContact(Account acc) {
        User thisUser = [select Id from User where Id =: UserInfo.getUserId()];
        Contact con = new Contact();
        System.runAs(thisUser) {
            con.LastName = 'test';
            con.AccountId = acc.Id;
            con.Email = 'test@test.com';
            insert con;
        }
        return con;
    }

    public static Contact insertDefaultContact(Account acc) {
        User thisUser = [select Id from User where Id =: UserInfo.getUserId()];
        Contact con = new Contact();
        System.runAs(thisUser) {
            con.LastName = 'test';
            con.AccountId = acc.Id;
            con.Email = 'test@test.com';         
            con.CC__c = True;
            con.Bcc__c = True;
            con.celsrm__Default__c = TRUE;
            insert con;
        }
        return con;
    }

    public static List<celsrm__Dispute__c> insertDispute(celsrm__Transaction__c trx, Account ac, Integer count) {
        User thisUser = [select Id from User where Id =: UserInfo.getUserId()];
        List<celsrm__Dispute__c> validDisputeList = new List<celsrm__Dispute__c>();
        System.runAs(thisUser) {
            for(Integer i = 0; i < count; i++){
                celsrm__Dispute__c validDispute = new celsrm__Dispute__c();
                validDispute.celsrm__Account__c = ac.Id;
                validDispute.celsrm__Transaction__c = trx.Id;
                validDispute.celsrm__Amount__c = 200;
                validDispute.celsrm__Status__c = 'Open';
                // START - MM - FIN-7983 - Test Coverage
                // validDispute.celsrm__Dispute_Type__c = '100 Financial & Invoicing';
                validDispute.celsrm__Dispute_Type__c = '100 Financial & Invoicing';
                // END - MM - FIN-7983 - Test Coverage
                validDisputeList.add(validDispute);
            }
            insert validDisputeList;
        }
        return validDisputeList;
    }

    public static celsrm__Transaction__c insertTransaction(Account acc) {
        User thisUser = [select Id from User where Id =: UserInfo.getUserId()];
        celsrm__Transaction__c validTransaction = new celsrm__Transaction__c();
        System.runAs(thisUser) {
            // START - MM - FIN-7983 - Test Coverage
            Date promiseDate = dateTime.now().date().addDays(-98);
            // END - MM - FIN-7983 - Test Coverage
            validTransaction.Name = 'Test Transaction';
            validTransaction.celsrm__Account__c = acc.Id;
            validTransaction.celsrm__Balance__c = 121;
            validTransaction.celsrm__Amount__c = 10000;
            validTransaction.celsrm__Promised_Amount__c = 367;
            validTransaction.celsrm__Promise_Date__c = promiseDate;
            validTransaction.celsrm__Disputed_Amount__c = 200;
            // validTransaction.celsrm__DPD__c  = 10;
            insert validTransaction;
        }
        return validTransaction;
    }

    public static List<celsrm__Transaction__c> transactionInsert(Account acc, Integer count){
        //create transaction on Account
        List<celsrm__Transaction__c> txObjList = new List<celsrm__Transaction__c>();
        Account tempAcc = acc;

        for(Integer i=0; i<count; i++)
        {
            celsrm__Transaction__c txObj = new celsrm__Transaction__c();
            txObj.celsrm__Account__c = tempAcc.Id;
            txObj.celsrm__Amount__c = 12312 + i;
            txObj.celsrm__Balance__c = 0 + i;
            txObj.Name = 'testno' + i;
            txObj.celsrm__Due_Date__c = Date.today().addMonths(-7);
            txObj.celsrm__Close_Date__c = Date.today() +10;
            txObj.celsrm__Promised_Amount__c = 5000;
            txObj.celsrm__Disputed_Amount__c = 23000;
            txObj.celsrm__Create_Date__c = Date.today().addMonths(-9);
            txObj.celsrm__Promised_Amount__c = 5;
            // txObj.celsrm__Ship_To_City__c='xyz';
            // txObj.celsrm__Ship_To_State__c = 'Ohio';
            // txObj.Bill_To_Country__c ='US';
            // txObj.celsrm__Ship_To_Country__c ='US';
            //txObj.Transaction_Key__c = 'TRX' + System.now().format('yyyyMMddHHmmss');
            txObjList.add(txObj);
        }
       
        insert txObjList;
        return txObjList;
    }

    public static EmailTemplate insertTemplate(){
        EmailTemplate emTemp = new EmailTemplate();
        emTemp.Name = 'Billing statement';
        emTemp.FolderId = UserInfo.getUserId();
        //-- Start | FIN-8334 | Changed by Ravi | 11 sep 2025 --//
        emTemp.body = '{Transactions.TotalBalance}';
        emTemp.HtmlValue = '<div>{Transactions.TotalBalance}</div>';
        //-- End | FIN-8334 | Changed by Ravi | 11 sep 2025 --//
        // emTemp.FolderName = 'English (United Kingdom)';
        emTemp.TemplateType = 'custom';
        emTemp.IsActive = true;
        emTemp.DeveloperName = 'testName';
        
        insert emTemp;
        return emTemp;
    }

    public static List<Task> insertTask(Account acc, Integer count){
        if(acc == null){
            acc = DataGenerator.insertAccount();
        }
        List<Task> taskList = new List<Task>();
        for(Integer i=0; i<count; i++){
            Task t = new Task();
            t.Subject = 'First Dunning Reminder';
            t.Status = 'Not Started';
            t.WhatId = acc.Id;
            t.TaskSubtype = 'Call';
            t.IsReminderSet = true;
            t.ReminderDateTime = Datetime.now();
            taskList.add(t);
        }

        insert taskList;
        return taskList;
    }

    public static List<Task> inserTreatmentTask(Account acc, Integer count, String treatmentId){
        if(acc == null){
            acc = DataGenerator.insertAccount();
        }
        List<Task> taskList = new List<Task>();
        for(Integer i=0; i<count; i++){
            Task t = new Task();
            t.Subject = 'First Dunning Reminder';
            t.Status = 'Not Started';
            t.WhatId = acc.Id;
            t.TaskSubtype = 'Call';
            t.IsReminderSet = true;
            t.ReminderDateTime = Datetime.now();
            t.celsrm__Treatment__c = treatmentId;
            taskList.add(t);
        }

        insert taskList;
        return taskList;
    }

    public static celsrm__Custom_List_View__c insertCustomListView(Boolean insertFilterCriteria) {
        User thisUser = [select Id from User where Id =: UserInfo.getUserId()];
        celsrm__Custom_List_View__c cl = new celsrm__Custom_List_View__c();
        System.runAs(thisUser) {
            cl.Name =  'All Open';
            cl.celsrm__ListView_For_Object__c = 'celsrm__Transaction__c';
            cl.celsrm__Object_Fields__c = '[{"enableCopy":false,"isExport":true,"hideLabel":null,"hide":true,"onClickFunction":"","isAggregate":false,"iconClassMap":false,"iconFlag":false,"iconName":"","width":"","type":"text","fieldName":"Id"},{"enableCopy":null,"isExport":null,"hideLabel":true,"hide":null,"onClickFunction":"","isAggregate":false,"iconClassMap":false,"iconFlag":false,"iconName":"","width":"","type":"html","fieldName":"celsrm__Flag__c"},{"enableCopy":false,"isExport":false,"hideLabel":null,"hide":false,"onClickFunction":"","isAggregate":false,"iconClassMap":false,"iconFlag":false,"iconName":"","width":"","type":"link","fieldName":"Name"},{"enableCopy":null,"isExport":null,"hideLabel":null,"hide":null,"onClickFunction":"","isAggregate":false,"iconClassMap":false,"iconFlag":false,"iconName":"","width":"","type":"currency","fieldName":"celsrm__Amount__c"},{"enableCopy":null,"isExport":true,"hideLabel":null,"hide":null,"onClickFunction":"","isAggregate":false,"iconClassMap":false,"iconFlag":false,"iconName":"","width":"","type":"currency","fieldName":"celsrm__Balance__c"},{"enableCopy":null,"isExport":null,"hideLabel":null,"hide":null,"onClickFunction":"","isAggregate":false,"iconClassMap":false,"iconFlag":false,"iconName":"","width":"","type":"text","fieldName":"celsrm__Po_Number__c"},{"enableCopy":null,"isExport":null,"hideLabel":null,"hide":null,"onClickFunction":"","isAggregate":false,"iconClassMap":false,"iconFlag":false,"iconName":"","width":"","type":"text","fieldName":"celsrm__So_Number__c"},{"enableCopy":null,"isExport":null,"hideLabel":null,"hide":null,"onClickFunction":"","isAggregate":false,"iconClassMap":false,"iconFlag":false,"iconName":"","width":"","type":"date","fieldName":"celsrm__Due_Date__c"},{"enableCopy":null,"isExport":null,"hideLabel":null,"hide":null,"onClickFunction":"","isAggregate":false,"iconClassMap":false,"iconFlag":false,"iconName":"","width":"","type":"number","fieldName":"celsrm__DPD__c"},{"enableCopy":null,"isExport":null,"hideLabel":null,"hide":true,"onClickFunction":"","isAggregate":false,"iconClassMap":false,"iconFlag":false,"iconName":"","width":"","type":"text","fieldName":"CurrencyIsoCode"}]';
            cl.celsrm__Is_Default__c = true;
            if(insertFilterCriteria) {
                cl.celsrm__Filter_Criteria__c ='{"condition":"1","criterias":[{"operator":"not equal to","type":"text","fieldName":"celsrm__Account__c"}]}';
            } else {
                cl.celsrm__Filter_Criteria__c = '';
            }
            insert cl;
        }
        return cl;
    }

    public static celsrm__SRM_Configuration__c insertWCMconfig(){

        List<OrgWideEmailAddress> OWEA = [SELECT Id, Address, DisplayName FROM OrgWideEmailAddress];
        
        celsrm__SRM_Configuration__c WCMconfig = new celsrm__SRM_Configuration__c();
        if (OWEA.size() > 0) {
            WCMconfig.Mailbox_Email_Address__c = OWEA[0].Address; 
        }
        insert WCMconfig;
        return WCMconfig;
    }

    public static celsrm__Temp_Object_Holder__c insertTempObjHolder(){
        celsrm__Temp_Object_Holder__c tempObjHolder = new celsrm__Temp_Object_Holder__c();
        tempObjHolder.celsrm__Key__c = 'test@test.com';
        tempObjHolder.celsrm__value__c = 'test';

        insert tempObjHolder;
        return tempObjHolder;
    }

    public static attachment insertAttachment(Account acc){

        Blob blobContent;
        if (Test.IsRunningTest()){
            blobContent = Blob.valueOf('Unit Test Attachment Body');
        } else {
            blobContent = ApexPages.currentPage().getContentAsPDF();
        }

        attachment attach = new attachment();
        attach.ParentID= acc.Id;
        attach.Name ='Unit Test Attachment';
        attach.body = blobContent;
        insert attach;
        return attach;
    }

    public static EmailTemplate insertEmailTemplate() {
        User thisUser = [select Id from User where Id =: UserInfo.getUserId()];
        EmailTemplate e1 = new EmailTemplate();
        System.runAs(thisUser) {
            e1.Name = 'Billing statement';
            e1.DeveloperName = 'Test';
            e1.FolderId = UserInfo.getUserId();
            e1.Subject =  'Call';
            e1.Body = 'Test';
            e1.TemplateType = 'custom';
            e1.IsActive = TRUE;
            insert e1;
        }
        return e1;
    }
    //-- Starts | FIN-8207 | Change by Asera | 19-Aug-25 //
    public static EmailTemplate insertEmailTemplateWithName(String templateName) {
        User thisUser = [select Id from User where Id =: UserInfo.getUserId()];
        EmailTemplate e1 = new EmailTemplate();
        System.runAs(thisUser) {
            e1.Name = templateName;
            e1.DeveloperName = 'Test';
            e1.FolderId = UserInfo.getUserId();
            e1.Subject =  'Call';
            e1.Body = 'Test';
            e1.TemplateType = 'custom';
            e1.IsActive = TRUE;
            insert e1;
        }
        return e1;
    }
    //-- Starts | FIN-8207 | Change by Asera | 19-Aug-25 //
    public static ContentVersion insertContentVersion(Account acc){
        ContentVersion cv = new ContentVersion(
            Title = 'TestFile',
            PathOnClient = 'TestFile.pdf',
            VersionData = Blob.valueOf('Test File Body'),
            IsMajorVersion = true
        );
        insert cv;
        return cv;
    }
    //-- End | FIN-8207 | Change by Asera | 19-Aug-25 //

    public static celsrm__Score_Card_Parameter__c insertScoreCardParams(){

        celsrm__Score_Card_Parameter__c SCP = new celsrm__Score_Card_Parameter__c();
        SCP.Name = 'D&B';
        SCP.celsrm__Weight__c = 3;
        SCP.celsrm__Parameter_Type__c = 'Text';
        SCP.celsrm__Credit_Review_Field__c = 'celsrm__DNB__c';
        SCP.celsrm__Exclude_If_Missing__c = false;
        SCP.celsrm__Model_Type__c = 'Full Review';

        insert SCP;
        return SCP;
    }

    public static celsrm__Score_Card_Parameter_Value__c ScoreCardParamVal(celsrm__Score_Card_Parameter__c SCP){
        celsrm__Score_Card_Parameter_Value__c SCPV = new celsrm__Score_Card_Parameter_Value__c();
        SCPV.celsrm__Boolean_Value__c = false;
        SCPV.celsrm__Score__c = 2.2;
        SCPV.celsrm__Minimum_Number_Value__c = 2;
        SCPV.celsrm__Maximum_Number_Value__c = 3;
        SCPV.celsrm__Text_Value__c = 'test';
        SCPV.celsrm__Score_Card_Parameter__c = SCP.Id;

        insert SCPV;
        return SCPV;
    }

    public static celsrm__Credit_Review__c insertCreditReview(){
        celsrm__Credit_Review__c cr = new celsrm__Credit_Review__c();
        cr.celsrm__Country_Score__c = 23;

        insert cr;
        return cr;
    }

    public static celsrm__Screens__c insertScreen(){
        celsrm__Screens__c screen = new celsrm__Screens__c();
        screen.Name = 'testScreen';
        screen.celsrm__Is_Active__c = true;
        screen.celsrm__Page_Mode__c = 'view';
        screen.celsrm__Object__c = 'Account';
        screen.celsrm__Config_1__c = '{"theme":{},"profile":"","sObjectMode":"","sObject":"","isSObject":false,"messages":[],"searchscreen":[],"sections":[{"theme":null,"dataServices":null,"blocks":[{"theme":null,"fields":[{"typeLabel":"Checkbox","helpText":"","onchange":"","requiredCriteria":null,"required":false,"hideCriteria":null,"hide":false,"readOnlyCriteria":null,"readOnly":false,"mobileWidth":"2","tabletWidth":"2","desktopWidth":"2","options":null,"dataSourceName":"","dataSource":"","hideTitle":false,"isActive":true,"type":"checkbox","title":"Checkbox1","name":"Checkbox1"},{"typeLabel":"Textbox","helpText":"","onchange":"","targetControlName":"","requiredCriteria":null,"required":false,"hideCriteria":null,"hide":false,"readOnlyCriteria":null,"readOnly":false,"default":"","mobileWidth":"12","tabletWidth":"12","desktopWidth":"12","placeholder":"","maxLength":"255","hideTitle":false,"isActive":true,"type":"text","title":"Title","name":"Name"}],"mobileWidth":"12","tabletWidth":"12","desktopWidth":"12","hideCriteria":null,"hide":false,"hideTitle":false,"isActive":true,"title":"Block1","name":"Block1"}],"mobileWidth":"12","tabletWidth":"12","desktopWidth":"12","hideCriteria":null,"hide":false,"hideTitle":false,"isActive":true,"title":"Section1","name":"Section1"}],"variables":[],"submitDataServicesOperation":"","submitDataServices":[],"dataServices":[{"name":"Data Service1","title":"Data Service1","dsId":"Process110","dataSource":"dataService","isActive":true}],"NextScreenOnCancel":"","NextScreenOnSave":"","staticResource":"","isActive":true,"isWizard":false,"hideTitle":false,"titleValue":"","title":"NewScreen","name":"testScreen"}';
        screen.celsrm__Profile__c = UserInfo.getProfileId();

        insert screen;
        return screen;
    }

    public static EmailMessage insertEmailMsg(Id relatedtoId){
        EmailMessage em = new EmailMessage();
        em.relatedtoId = relatedtoId;
        em.ToAddress = 'testTo@mail.com';
        em.CcAddress = 'testCc@mail.com';
        em.FromAddress = 'testFrom@mail.com';
        em.BccAddress  = 'testBcc@mail.com';
        em.Subject = 'subject';
        em.HtmlBody = '<div>{Transactions.TotalBalance}</div>';
        // em.celsrm__Classification_Response__c = '{ "entities": [ { "dim": "invoice_no", "value": "'+relatedtoId+'" },       { "dim": "email", "value": { "dim": "email", "value": "testTo1@mail.com" } } ] }';

        insert em;
        return em;
    }

    public static EmailMessage insertEmailMsgForClassification(Id relatedtoId, String invoiceNo){
        EmailMessage em = new EmailMessage();
        em.relatedtoId = relatedtoId;
        em.ToAddress = 'testTo@mail.com';
        em.CcAddress = 'testCc@mail.com';
        em.FromAddress = 'testFrom@mail.com';
        em.BccAddress  = 'testBcc@mail.com';
        em.Subject = 'subject';
        em.HtmlBody = '<div>{Transactions.TotalBalance}</div>';
        // em.celsrm__Classification_Response__c = '{ "entities": [ { "dim": "invoice_no", "value": "'+invoiceNo+'" },       { "dim": "email", "value": { "dim": "email", "value": "testTo1@mail.com" } } ] }';
        insert em;
        return em;
    }

    public static celsrm__User_Preference__c insertUserPreference(Id listviewId){
        celsrm__User_Preference__c userPref = new celsrm__User_Preference__c();
        userPref.celsrm__sendStatementListView__c = listviewId;
        userPref.celsrm__SortListViewField__c = 'celsrm__Balance__c';
        userPref.celsrm__AttachmentTypes__c = 'PDF';
        userPref.celsrm__SortListViewOrderType__c = 'ASC';
        userPref.celsrm__Is_Attach_Checked__c = true;
        userPref.celsrm__User__c = UserInfo.getUserId();
        insert userPref;
        return userPref;
    }

    public static EmailMessage insertEmailMsgForVerifyPayment(Id relatedtoId){
        EmailMessage em = new EmailMessage();
        em.relatedtoId = relatedtoId;
        em.ToAddress = 'testTo@mail.com';
        em.CcAddress = 'testCc@mail.com';
        em.FromAddress = 'testFrom@mail.com';
        em.BccAddress  = 'testBcc@mail.com';
        em.Subject = 'subject';
        em.HtmlBody = '<div>{Transactions.TotalBalance}</div>';
        // em.celsrm__Classification_Response__c = '{"entities":[{"confidence":1.0,"dim":"invoice_no","value":"Test Transaction"},{"body":"4","dim":"time","end":46,"latent":true,"start":45,"value":{"grain":"hour","type":"value","value":"2020-07-24T16:00:00.000Z","values":[{"grain":"hour","type":"value","value":"2020-07-24T16:00:00.000Z"},{"grain":"hour","type":"value","value":"2020-07-25T04:00:00.000Z"},{"grain":"hour","type":"value","value":"2020-07-25T16:00:00.000Z"}]}},{"body":"6","dim":"time","end":49,"latent":true,"start":48,"value":{"grain":"hour","type":"value","value":"2020-07-24T18:00:00.000Z","values":[{"grain":"hour","type":"value","value":"2020-07-24T18:00:00.000Z"},{"grain":"hour","type":"value","value":"2020-07-25T06:00:00.000Z"},{"grain":"hour","type":"value","value":"2020-07-25T18:00:00.000Z"}]}},{"body":"3","dim":"time","end":52,"latent":true,"start":51,"value":{"grain":"hour","type":"value","value":"2020-07-24T15:00:00.000Z","values":[{"grain":"hour","type":"value","value":"2020-07-24T15:00:00.000Z"},{"grain":"hour","type":"value","value":"2020-07-25T03:00:00.000Z"},{"grain":"hour","type":"value","value":"2020-07-25T15:00:00.000Z"}]}},{"body":"2","dim":"time","end":55,"latent":true,"start":54,"value":{"grain":"hour","type":"value","value":"2020-07-24T14:00:00.000Z","values":[{"grain":"hour","type":"value","value":"2020-07-24T14:00:00.000Z"},{"grain":"hour","type":"value","value":"2020-07-25T02:00:00.000Z"},{"grain":"hour","type":"value","value":"2020-07-25T14:00:00.000Z"}]}},{"body":"4","dim":"time","end":61,"latent":true,"start":60,"value":{"grain":"hour","type":"value","value":"2020-07-24T16:00:00.000Z","values":[{"grain":"hour","type":"value","value":"2020-07-24T16:00:00.000Z"},{"grain":"hour","type":"value","value":"2020-07-25T04:00:00.000Z"},{"grain":"hour","type":"value","value":"2020-07-25T16:00:00.000Z"}]}},{"body":"6","dim":"time","end":64,"latent":true,"start":63,"value":{"grain":"hour","type":"value","value":"2020-07-24T18:00:00.000Z","values":[{"grain":"hour","type":"value","value":"2020-07-24T18:00:00.000Z"},{"grain":"hour","type":"value","value":"2020-07-25T06:00:00.000Z"},{"grain":"hour","type":"value","value":"2020-07-25T18:00:00.000Z"}]}},{"body":"3","dim":"time","end":67,"latent":true,"start":66,"value":{"grain":"hour","type":"value","value":"2020-07-24T15:00:00.000Z","values":[{"grain":"hour","type":"value","value":"2020-07-24T15:00:00.000Z"},{"grain":"hour","type":"value","value":"2020-07-25T03:00:00.000Z"},{"grain":"hour","type":"value","value":"2020-07-25T15:00:00.000Z"}]}},{"body":"2","dim":"time","end":70,"latent":true,"start":69,"value":{"grain":"hour","type":"value","value":"2020-07-24T14:00:00.000Z","values":[{"grain":"hour","type":"value","value":"2020-07-24T14:00:00.000Z"},{"grain":"hour","type":"value","value":"2020-07-25T02:00:00.000Z"},{"grain":"hour","type":"value","value":"2020-07-25T14:00:00.000Z"}]}}],"intent":{"confidence":0.6474922895431519,"name":"Paid by Customer"},"intent_ranking":[{"confidence":0.6474922895431519,"name":"Paid by Customer"},{"confidence":0.28063681721687317,"name":"Promised"},{"confidence":0.0648808553814888,"name":"Unidentified"},{"confidence":0.004223168361932039,"name":"Statement"},{"confidence":0.001672046142630279,"name":"Offset"},{"confidence":0.000748721940908581,"name":"Out of office"},{"confidence":0.00034613945172168314,"name":"Contact Update"}],"table_entity":[{"filename":"","source":"emailbody","tableData":[{"AccountNUmber":"CC980037","InvoiceNUmber":"Test Transaction"},{"AccountNUmber":"98jke","InvoiceNUmber":"sdfbdsfbdfbg"}],"tableMetadata":{"AccountNUmber":{"dim":"Account_Number","type":"Alpha Numeric"},"InvoiceNUmber":{"dim":"invoice_no","type":"Alpha Numeric"}}}],"text":"& Regards, CC980037 check this detail week  T4TD6AF3HE2 ,  T4TD6AF3HE2  , open ADVANCE ENERGY PARTNERS, LLC"}';
        insert em;
        return em;
    }
    public static celsrm__Treatment__c insertTreatmentRecord(String Id, String name, String accountCriteria, String relatedObject, String treatmentSteps, String taskType, Integer dueDate, Boolean autoDunning, String fromAddress, String segmentation, String segmentColor, String emailTemplate, String treatmentName, Boolean seperateTaskForStep){
        celsrm__Treatment__c tre = new celsrm__Treatment__c();
        tre.name = name;
        tre.celsrm__Account_Criteria__c = accountCriteria;
        tre.celsrm__Related_Object__c = relatedObject;
        tre.celsrm__Treatment_Segment__c = segmentation;
        tre.celsrm__Treatment_Steps__c = treatmentSteps;
        tre.celsrm__Task_Type__c = taskType;
        tre.celsrm__Task_Due_Date__c = dueDate;
        tre.celsrm__Auto_Treatment__c = autoDunning;
        tre.celsrm__Org_Id__c = fromAddress;
        tre.celsrm__Segment_Color__c = segmentColor;
        tre.celsrm__Email_Template__c = emailTemplate;
        tre.celsrm__Treatment_Name__c = treatmentName;
        tre.celsrm__Seperate_Task_For_Step__c = seperateTaskForStep;
        if (Id != '') {
            tre.Id = Id;
        }
        upsert tre;
        return tre;
    }

    public static List<celsrm__Dispute_Workflow_Matrix__c>  insertDisputeWorkflowMatrix(String type, String reasonCode){
        User thisUser = [select Id from User where Id =: UserInfo.getUserId()];
        List<celsrm__Dispute_Workflow_Matrix__c> dwmList = new List<celsrm__Dispute_Workflow_Matrix__c>();
        for(Integer i = 0; i < 2; i++){
            celsrm__Dispute_Workflow_Matrix__c dwm = new celsrm__Dispute_Workflow_Matrix__c();
            System.runAs(thisUser) {
                dwm.celsrm__User__c = thisUser.Id;
                dwm.celsrm__User_Type__c = 'approver';
                dwm.celsrm__Optional__c = false;
                dwm.celsrm__Level__c = i;
                dwm.celsrm__User_SLA_Days__c = 2;
                dwm.celsrm__Dispute_Type__c = type;
                dwm.celsrm__Reason_Code__c = reasonCode;
                dwm.celsrm__Is_Active__c = true;
                insert dwm;
            }
            dwmList.add(dwm);
        }

        return dwmList;
    }

    //-- Start | FIN-10143 | Changed by Asera | 20-Jul-2026 --//
    public static celsrm__Dispute_Workflow_Details__c insertDisputeWorkflowDetails(celsrm__Dispute_Workflow_Matrix__c dwm,celsrm__Dispute__c dis, String status, String userAction){
        User thisUser = [select Id from User where Id =: UserInfo.getUserId()];
        DisputeUserMasterService.syncInternalUsers(new Set<Id>{ thisUser.Id });
        celsrm__User_Master__c userMaster = DisputeUserMasterService.getInternalMastersByUserIds(new Set<Id>{ thisUser.Id }).get(thisUser.Id);
        celsrm__Dispute_Workflow_Details__c dwd = new celsrm__Dispute_Workflow_Details__c();
        dwd.celsrm__Action_Date__c = Date.today();
        dwd.celsrm__Action_Taken_By__c = thisUser.Id;
        dwd.celsrm__Dispute__c = dis.Id;
        dwd.celsrm__Dispute_Workflow_Matrix__c = dwm.Id;
        // dwd.celsrm__Expected_Closure_Date__c = Datetime.now();
        dwd.celsrm__User_Master__c = userMaster != null ? userMaster.Id : null;
        dwd.celsrm__Status__c = status;
        Integer daysBeforeToday = 2; // Change this value as needed
        // Date tempCreatedDate = Date.today().addDays(-daysBeforeToday);
        // // Set the dynamic date as Temp_Created_Date__c
        // dwd.Temp_Created_Date__c = tempCreatedDate;
        dwd.celsrm__User_Action__c = userAction;
        
        insert dwd;
        return dwd;
    }
    //-- End | FIN-10143 | Changed by Asera | 20-Jul-2026 --//

    // public static Rebate_Corp_Master_Data__c insertCorpMasterData(Rebate_Conf__c rebate){
    //     Rebate_Corp_Master_Data__c corp = new Rebate_Corp_Master_Data__c();
    //     corp.Account_Key__c = 'Test AccountKey';
    //     corp.Rebateable_account_id__c = rebate.Id;
    //     corp.Rebate_Contract_Start_Date__c = Date.today().addDays(-1);
    //     corp.Rebate_Contract_Start_Month__c = 2;
    //     corp.Rebate_Period__c = 'Quarterly';
    //     corp.Rebate_Type__c = 'cumulative';
    //     insert corp;
    //     return corp;
    // }
    
    // public static Rebate_Conf__c insertRebateConf(){
    //     Rebate_Conf__c rebate = new Rebate_Conf__c();
    //     rebate.Rebate_Start_Date__c = Date.today();
    //     rebate.Rebate_End_Date__c = Date.today();
    //     rebate.Moths_for_SE__c = 1;
    //     insert rebate;
    //     return rebate;
    // }

    // public static celsrm__Trigger_Configuration__c insertTriggerConf(){
    //     celsrm__Trigger_Configuration__c triggerConf = new celsrm__Trigger_Configuration__c();
    //     triggerConf.Dispute_create_on_partially_paid_Invoice__c = true; 
    //     insert triggerConf;
    //     return triggerConf;
    // }
    
    //-- Start | FIN-10143 | Changed by Asera | 20-Jul-2026 --//
    public static List<celsrm__Dispute_Reminder_Escalation_Matrix__c>  insertDisputeReminderEscalation(String type, String reasonCode){
        
        List<celsrm__Dispute_Reminder_Escalation_Matrix__c> dREMList = new List<celsrm__Dispute_Reminder_Escalation_Matrix__c>();
        for(Integer i = 0; i < 1; i++){
            celsrm__Dispute_Reminder_Escalation_Matrix__c drem = new celsrm__Dispute_Reminder_Escalation_Matrix__c();
            drem.Name = 'Reminder Escalation ' + i;
            drem.celsrm__Is_Active__c = true;
            drem.celsrm__Order__c = i + 1;
            drem.celsrm__Criteria__c = JSON.serialize(new Map<String, Object>{
                'criteriaCondition' => '( 1 AND 2 )',
                'criteria' => new List<Object>{
                    new Map<String, Object>{
                        'field' => 'Dispute_Type__c',
                        'operator' => '=',
                        'value' => type,
                        'fieldType' => 'PICKLIST'
                    },
                    new Map<String, Object>{
                        'field' => 'Reason_Code__c',
                        'operator' => '=',
                        'value' => reasonCode,
                        'fieldType' => 'PICKLIST'
                    }
                }
            });
            drem.celsrm__Follow_Up_Config__c = JSON.serialize(new List<Object>{
                new Map<String, Object>{
                    'userType' => 'Approver',
                    'followUpType' => 'followup',
                    'followUpDays' => 2,
                    'followUpLevel' => 1,
                    'isActive' => true
                }
            });
            insert drem;
            dREMList.add(drem);
        }
        return dREMList;
    }
    //-- End | FIN-10143 | Changed by Asera | 20-Jul-2026 --//
    public static List<celsrm__Dispute__c> insertDispute(celsrm__Transaction__c trx, Account ac, Integer count, String status) {
        User thisUser = [select Id from User where Id =: UserInfo.getUserId()];
        List<celsrm__Dispute__c> validDisputeList = new List<celsrm__Dispute__c>();
        System.runAs(thisUser) {
            for(Integer i = 0; i < count; i++){
                celsrm__Dispute__c validDispute = new celsrm__Dispute__c();
                validDispute.celsrm__Account__c = ac.Id;
                validDispute.celsrm__Transaction__c = trx.Id;
                validDispute.celsrm__Amount__c = 200;
                validDispute.celsrm__Status__c = status;
                // START - MM - FIN-7983 - Test Coverage
                // validDispute.celsrm__Reason_Code__c = 'Tax rate incorrect';
                // validDispute.celsrm__Dispute_Type__c = 'Billing';
                validDispute.celsrm__Reason_Code__c = '101 Cash Discount Deduction';
                validDispute.celsrm__Dispute_Type__c = '100 Financial & Invoicing';
                // END - MM - FIN-7983 - Test Coverage
                validDisputeList.add(validDispute);
            }
            insert validDisputeList;
        }
        return validDisputeList;
    }

    public static List<ContentDocument> insertContentDoc(){
        //Create Document
        ContentVersion cv = new ContentVersion();
        cv.Title = 'Test Document';
        cv.PathOnClient = 'TestDocument.pdf';
        cv.VersionData = Blob.valueOf('Test Content');
        cv.IsMajorVersion = true;
        cv.celsrm__Document_Key__c = 'AAAAA';
        Insert cv;

        List<ContentDocument> cdList = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];
        return cdList;
    }
}