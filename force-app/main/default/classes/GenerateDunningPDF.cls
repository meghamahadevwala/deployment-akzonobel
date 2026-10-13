public with sharing class GenerateDunningPDF implements Queueable, Database.AllowsCallouts {
    private Map<Object, Object> automatedTask;
    private String TempId;
    public String selectedLocale;
    public String emailSubject = '';
    public String emailTemplateBody = '';
    public celsrm__Temp_Object_Holder__c tempObjholder;
    public String AttachType;
    public String ListView;
    public Id ContactId;
    public Map<String,String> amountTotalST;
    public Static string namespace = 'celsrm__';
    
    public GenerateDunningPDF (Map<Object, Object> tskObj, String TempobjId, String AttachType, String ListView, Map<String,String> returnTemplateAmount) {
         if (TempobjId != null) {
           tempObjholder = [select Id, celsrm__Value__c, celsrm__key__c from celsrm__Temp_Object_Holder__c where Id =: TempobjId];
           
         }
         if( (Id)tskObj.get('WhatId') != null ){
             List<Contact> con = [Select id from Contact where accountId=:(Id)tskObj.get('WhatId') and celsrm__Default__c= true order by LastName limit 1 ] ;
             if(con.size()>0){
                 this.ContactId = con.get(0).id;
             }else{
                 List<Contact> con2 = [Select id from Contact where name='AP Contact' limit 1 ] ;
                 if(con2.size()>0){
                 this.ContactId = con2.get(0).id;
                 }
             }
         }
         this.amountTotalST = returnTemplateAmount;
        this.automatedTask= tskObj;
        this.TempId= TempobjId;
        this.AttachType= AttachType;
        this.ListView = ListView;
    }
    public void execute(QueueableContext context) {
        
        setTemplateBody( (String)automatedTask.get('Subject'), selectedLocale,automatedTask);
        boolean emailSuccess = SendToAllDefault(automatedTask);  
        if(emailSuccess == true){   
            Account acu = [select id, celsrm__Last_Contact_Date__c,celsrm__Latest_Note__c from Account where Id=: (Id)automatedTask.get('WhatId')];
            
            Account acc= new Account(id =(Id)automatedTask.get('WhatId'));
            acc.celsrm__Last_Contact_Date__c = date.today();   
            acc.celsrm__Last_Contact_Method__c = 'Email';
            acc.celsrm__Last_Contact_Type__c = 'Dunning';
            acc = (Account) celsrm.SRMUtilityController.saveNoteOnRecord(acc,acu.celsrm__Latest_Note__c ,'EMAILED - ',(String)automatedTask.get('Subject') +' via Dunning','',((string)automatedTask.get('celsrm__To__c')).split('@')[0] ) ;
           /* acc.celsrm__Note_Date__c = Date.Today();
            if(acu.celsrm__Notes__c != null){
                acc.celsrm__Notes__c =acc.celsrm__Notes__c =(String)automatedTask.get('Subject') +' via Dunning'+'\n'+UserInfo.getName() +':'+date.today().year()+'-'+date.today().month()+'-'+date.today().day() +'\n'+'\n'+acu.celsrm__Notes__c;
                acc.celsrm__Latest_Note__c = (String)automatedTask.get('Subject')+' - '+'The Statement sent to the customer via Dunning';
            }else{
                acc.celsrm__Notes__c =acc.celsrm__Notes__c =(String)automatedTask.get('Subject') +' via Dunning'+'\n'+UserInfo.getName() +':'+date.today().year()+'-'+date.today().month()+'-'+date.today().day() ;
                acc.celsrm__Latest_Note__c = (String)automatedTask.get('Subject')+' - '+'The Statement sent to the customer via Dunning';
            }  */
                               
               
            update acc;
            
            // String DTFormat = celsrm__SRM_Configuration__c.getOrgDefaults().celsrm__Date_Format_Of_Append_Note__c != null ? celsrm__SRM_Configuration__c.getOrgDefaults().celsrm__Date_Format_Of_Append_Note__c : 'mm/dd/yyyy';
            String DTFormat = 'mm/dd/yyyy';
            DateTime dt = DateTime.now();
            String dateTimeStr = dt.format(DTFormat);
             
            Task tskobj = new task(id=(Id)automatedTask.get('Id'));
            tskobj.celsrm__Notes__c = 'EMAILED -'+((string)automatedTask.get('celsrm__To__c')).split('@')[0] +'\n'+(String)automatedTask.get('Subject') +' via Dunning'+'\n'+UserInfo.getName()+':'+dateTimeStr ;
            tskobj.status = 'Completed';
            tskobj.celsrm__Dunning_Status__c = 'Done';
            
            update tskobj;
            List < celsrm__Transaction__c > txList = [Select id,celsrm__Latest_Note__c from celsrm__Transaction__c where id =: tempObjholder.celsrm__Value__c.split(',')];
            List< celsrm__Transaction__c > updateTransaction = new List< celsrm__Transaction__c >();
            for(celsrm__Transaction__c tx :txList){
                 celsrm__Transaction__c  txTemp = new  celsrm__Transaction__c (id=tx.id);
               
                txTemp = (celsrm__Transaction__c) celsrm.SRMUtilityController.saveNoteOnRecord(tx,tx.celsrm__Latest_Note__c ,'EMAILED - ',(String)automatedTask.get('Subject') +' via Dunning','',((string)automatedTask.get('celsrm__To__c')).split('@')[0] ) ;
                // txTemp.Dunning__c = true;
                txTemp.celsrm__Last_Contact_Date__c = date.today(); 
                txTemp.celsrm__Last_Contacted_By__c = UserInfo.getUserId();
                updateTransaction.add(txTemp);
            }
            update updateTransaction;
        } else{
            
            Task tskobj = new task(id=(Id)automatedTask.get('Id'));
            tskobj.status = 'Auto Dunning Error';
            tskobj.celsrm__Auto_Dunning_Error__c= 'Subject does not match with emailTemplate';
             
            update tskobj;
        }                         
    }
    
    private void setTemplateBody( String automatedTaskSubject, String selectedLocale,Map<Object, Object> tsk)
    {
        try{
            String selectedTemplateId = '';
            EmailTemplate selected = null;
            List<EmailTemplate> billingTemplateList = new  List<EmailTemplate>();
            
            if(selectedLocale != null && selectedLocale != '' ){
                billingTemplateList = [select id, Name, FolderId, Subject, HtmlValue, TemplateType, Body from EmailTemplate where Folder.Name != null and Folder.Name=:selectedLocale  and Name=:automatedTaskSubject AND IsActive = TRUE];
            }else{
                billingTemplateList = [select id, Name, FolderId, Subject, HtmlValue, TemplateType, Body from EmailTemplate where Name=:automatedTaskSubject AND IsActive = TRUE];
            } 
            
            selectedLocale=null;       
            if(billingTemplateList != null && billingTemplateList.size() > 0){
                selected =billingTemplateList.get(0);
                selectedTemplateId = billingTemplateList.get(0).Id;
            }
            
            if(selected != null && selectedTemplateId != ''){   
                Messaging.SingleEmailMessage message= Messaging.renderStoredEmailTemplate(selectedTemplateId , ContactId, (Id) tsk.get('WhatId'));
                emailTemplateBody  = message.getHtmlBody();
                emailSubject  = message.getSubject();
                String htmlBody;
                
                
                List < celsrm__Transaction__c > txList = getSelectedTransactions((String) tsk.get('WhatId'));
                
                celsrm__Custom_List_View__c customListViewObj = new celsrm__Custom_List_View__c();
                customListViewObj = [SELECT Id, celsrm__Object_Fields__c FROM celsrm__Custom_List_View__c WHERE Id = :ListView LIMIT 1];
                boolean isPageBreak;
                if( AttachType != null && AttachType != '' && AttachType == 'PDF' ){
                    isPageBreak = true;
                }else{
                    isPageBreak = false;
                }
                String selectedFields = '';
                if(customListViewObj != null && customListViewObj.celsrm__Object_Fields__c != null && customListViewObj.celsrm__Object_Fields__c != '') {
                    selectedFields = UtilityController.getQueryFields(customListViewObj.celsrm__Object_Fields__c, 'celsrm__Transaction__c');
                }
                
                htmlBody = UtilityController.getTransactionSummary(txList, selectedFields.split(','), false);
                
                emailTemplateBody  = emailTemplateBody.replace('{Transaction.Summary}', htmlBody);
                //-- Start | FIN-8334 | Changed by Ravi | 11 sep 2025 --//
                emailTemplateBody  = emailTemplateBody.replace('{Transactions.TotalBalance}', amountTotalST.get('TotalBalance'));    
                //-- End | FIN-8334 | Changed by Ravi | 11 sep 2025 --//
                
                
            }else{
                emailTemplateBody = '';
                emailSubject = '';              
            }
        }catch(Exception Ex){
            throw Ex;
            
        }
    }
    
    
    public Double totalBillingBal {get; set; }
    
    
    public List<celsrm__Transaction__c> getSelectedTransactions( String id) {
        String namespace = 'celsrm__';
        List<celsrm__Transaction__c> txList = new List<celsrm__Transaction__c>();
        totalBillingBal = 0;
        String txSelectQuery='';
        String whereCondition = '';
        celsrm__Custom_List_View__c customListViewObj = new celsrm__Custom_List_View__c();
        customListViewObj = [SELECT Id, Name, celsrm__Object_Fields__c FROM celsrm__Custom_List_View__c WHERE Id = :ListView LIMIT 1];
        String selectedFields = '';
        if( customListViewObj != null && customListViewObj.celsrm__Object_Fields__c != null && customListViewObj.celsrm__Object_Fields__c != ''){
            selectedFields = UtilityController.getQueryFields(customListViewObj.celsrm__Object_Fields__c, 'celsrm__Transaction__c');
        }
        String[] transactionIds;
         
        if (tempObjholder != null && tempObjholder.celsrm__Value__c != null) {
            transactionIds = tempObjholder.celsrm__Value__c.split(',');
        }
          
        whereCondition   = 'id in :transactionIds limit 2000';
          
        List<string> formatedFieldName = UtilityController.getTransactionFieldformat(selectedFields.split(','),namespace +'Transaction__c');
        String Queryfields = string.join(formatedFieldName,',');
        String stringToQuery = 'Select ' + Queryfields + ' from celsrm__Transaction__c where ' + whereCondition;
  
        txList = database.query(stringToQuery);
        /*for(celsrm__Transaction__c tx : txList)
            totalBillingBal = totalBillingBal + Double.valueOf((tx.get(namespace+'Balance__c') != null ? tx.get(namespace+'Balance__c') : 0));
        */
        return txList;
    }
    
    
    public boolean SendToAllDefault(Map<Object, Object> tsk)
    {
        Boolean success = false;
        String fileType = '';
        String ext = '';
        Map<String, String> dataMap = new Map<String, String>();
        List<Map<String, String>> attachmentobj = new List<Map<String, String>>();
        celsrm__SRM_Configuration__c systemConfig = celsrm__SRM_Configuration__c.getOrgDefaults();
            
        List<OrgWideEmailAddress> listName = [SELECT Id, Address, DisplayName FROM OrgWideEmailAddress where address=:systemConfig.Mailbox_Email_Address__c ];
        if(AttachType != null && AttachType != '' ){
            if(AttachType == 'PDF') {
                ext = '.pdf';
                fileType = 'PDF';
            } else if(AttachType == 'Excel') {
                ext = '.xls';
                fileType = 'XLS';
            }
           
            Map<Object, Object> returnData = new Map<Object, Object>();            
            
            PageReference pRef= Page.celsrm__PreviewStatement;
            pRef.getParameters().put('formatType',AttachType);
            pRef.getParameters().put('accId',(Id) tsk.get('WhatId'));
            pRef.getParameters().put('ListView',ListView);
            pRef.getParameters().put('key',TempId);
            
            Blob fileContent;
            String content;
            
            if(AttachType =='Excel'){
                if(Test.isRunningTest()) { 
                    fileContent = blob.valueOf('Unit.Test');
                    content = EncodingUtil.base64Encode(blob.valueOf('Unit.Test'));
                }  else {
                    fileContent = pRef.getContent();
                    content = EncodingUtil.base64Encode(pRef.getContent());
                }
            }else{
                if(Test.isRunningTest()) { 
                    fileContent = blob.valueOf('Unit.Test');
                    content = EncodingUtil.base64Encode(blob.valueOf('Unit.Test'));
                } else {
                    fileContent = pRef.getContentAsPDF();
                    content = EncodingUtil.base64Encode(pRef.getContentAsPDF());
                }
                
            }
            
            dataMap.put('Id',null);
            dataMap.put('Title','BillingStatement' + ext);
            dataMap.put('FileType',fileType);
            dataMap.put('Base64',content);
            
            attachmentobj.add(dataMap);
        }
        List<Object> attachment = new List<Object> {dataMap};
        List<string> Addto = new List<string>();
        List<String> Addbcc = new List<string>();
        List<String> Addcc = new List<string>();
        
        if(tsk.get('celsrm__To__c') != null ){
            List<String> toAdd = (List<string>)((string)tsk.get('celsrm__To__c')).split(',');
            for (String to : toAdd) {
                Addto.addAll(to.split(';'));
            }
        }
        if(tsk.get('celsrm__Bcc__c') != null){
            List<String> bccAdd = (List<string>)((string)tsk.get('celsrm__Bcc__c')).split(',');
            for (String bcc : bccAdd) {
                Addbcc.addAll(bcc.split(';'));
            }
        }
        if(tsk.get('celsrm__Cc__c') != null){
            List<String> ccAdd = (List<string>)((string)tsk.get('celsrm__Cc__c')).split(',');
            for (String cc : ccAdd) {
                Addcc.addAll(cc.split(';'));
            }
        }
        if((emailTemplateBody != null && emailTemplateBody.trim() != '') && (emailSubject != null && emailSubject.trim() != '')){
            
            try{ 
                // celsrm.GOGEmailMapper.sendEmail( listName.get(0).Id, Addto , emailSubject, emailTemplateBody, null, Addcc , Addbcc , attachmentobj, (Id) tsk.get('WhatId'));
                
                celsrm.GOGEmailMapper.SendEmailBean emailBean = new celsrm.GOGEmailMapper.SendEmailBean();
				emailBean.owea = listName.get(0).Id;
				emailBean.to = Addto;
				emailBean.subject = emailSubject;
				emailBean.htmlBody = emailTemplateBody;
				emailBean.plainTextBody = null;
				emailBean.cc = Addcc;
				emailBean.bcc = Addbcc;
				emailBean.attachment = attachmentobj;
				emailBean.parentId = (Id) tsk.get('WhatId');
				emailBean.followUpTaskDueDate = null;
				celsrm.GOGEmailMapper.sendEmailWithBean(emailBean);
                success = true;
                
                
            } catch(Exception e){
                if(e.getMessage().contains('SINGLE_EMAIL_LIMIT_EXCEEDED')){
                    success = true;
                }else{
                    success = false;
                }
            }
        }
        return success;
    }
}