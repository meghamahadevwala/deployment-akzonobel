global with sharing class GOGaddedEmailDetails implements celsrm.GOGIScreenCustomLogic {
    global Map<Object, Object> invoke(String functionName, Map<Object, Object> inMap) {
        System.debug('into GOGCustomImplementation');
        System.debug('functionName ::: ' + functionName);
        System.debug('inMap ::: ' + inMap);
        inMap.put('VendorName','adding new value');
        Set<String> AccId = new Set<String>();
        AccId.add(String.valueOf(inMap.get('Id')));
        List<String> TransIds = new List<String>();
        List<Object> records = (List<Object>)inMap.get('TransactionList');
        system.debug('records>>>'+records);
        String htmlBody;
        String sortfieldName = null;
        String sortOrder = null;
        if (inMap.get('TransactionList_SortColumn') != null && inMap.get('TransactionList_SortOrder') != null) {
            sortfieldName = String.valueOf(inMap.get('TransactionList_SortColumn'));
            sortOrder = String.valueOf(inMap.get('TransactionList_SortOrder'));
            if(Schema.SObjectType.celsrm__Transaction__c.fields.getMap().get(sortfieldName).getDescribe().getType() == Schema.DisplayType.TextArea) {
                sortfieldName = null;
                sortOrder = null;
            }
        }
        //By Ravi | 12-02-2020 | user preference
        String currentUser = UserInfo.getUserId();
        celsrm__User_Preference__c userPref  = new celsrm__User_Preference__c();
        try {
            userPref = [SELECT Id,celsrm__SortListViewField__c,celsrm__SortListViewOrderType__c FROM celsrm__User_Preference__c WHERE celsrm__User__c =:currentUser LIMIT 1];
        } catch (Exception e) {
            System.debug('exception>> ' + e.getMessage());
        }
        if (sortfieldName == null && sortOrder == null && userPref.celsrm__SortListViewField__c != null && userPref.celsrm__SortListViewOrderType__c != null) {
            sortfieldName = String.valueOf(userPref.celsrm__SortListViewField__c);
            sortOrder = String.valueOf(userPref.celsrm__SortListViewOrderType__c);
            if(Schema.SObjectType.celsrm__Transaction__c.fields.getMap().get(sortfieldName).getDescribe().getType() == Schema.DisplayType.TextArea) {
                sortfieldName = null;
                sortOrder = null;
            }
        }
        
        //By Ravi | 12-02-2020 | user preference
        for(Object trxn : records) {
            map < Object, Object> m = (map < Object, Object > )trxn;
            if (m.get('celsrm__Account__r') != null) {
                AccId.add(String.valueOf(((Map<Object,Object>)m.get('celsrm__Account__r')).get('Id')));                
            }
        }
       // List<SelectOption> emailTemplatesops = new List<SelectOption>();
      /*   List<map<string,string>> customObject = new List<map<string,string>>();
        List<EmailTemplate> templateList = [select id, Name from EmailTemplate where TemplateType in ('text','custom') and (NOT Name like 'SYSTEM%') and Folder.Name != null and Folder.Name != '' and  IsActive=true order by DeveloperName ];
        
        if(templateList != null && templateList.size() >0 ){
            for(EmailTemplate et : templateList) {
                if(et  != null ){
               // emailTemplatesops.add(new Selectoption(et.Id, et.Name));
                   map<string,string> tmp = new map<string,string>();
                    tmp.put('label',et.Name);
                    tmp.put('value',et.Id);
                    customObject.add(tmp);
                }
            }
        }
        
        inMap.put('dataServiceResponse',customObject);*/
        system.debug('========AccId==='+ AccId);
        system.debug('========Attached==='+inMap.get('Attached'));
        if(inMap.get('Attached') == true){
            inMap.put('StatementFormat','Excel');
        }else{
        
        inMap.put('StatementFormat','');
        }
        inMap.put('ContactMethod','Email');
       // String AccId = (String)inMap.get('Id');
         List<contact> CurrentAcc = [select id, Name,Fax,Email from contact where AccountId in :AccId and celsrm__Default__c=true];
         List<string> DefaultContact = new List<string>();
         List<string> ToContact = new List<string>();
         if(CurrentAcc != null && CurrentAcc.size()>0){
             String conemailst =CurrentAcc.get(0).Email;
             ToContact.add(CurrentAcc.get(0).Email);
             if (CurrentAcc.size()>1){
                 for(contact con :CurrentAcc){
                     if(conemailst != con.email)
                     DefaultContact.add(con.email);
                   }
               }
         
         }
            //celsrm.GOGEmailMapper.sendEmail( fromId, Toaddress, subject, htmlBody, null, ccaddress, bccaddress, attachmentobj, parentId );
           Map<Object, Object>  tempComposeEmail = new Map<Object, Object>();
            
            tempComposeEmail.put('to',ToContact);
            tempComposeEmail.put('cc',DefaultContact);
           /* Map<String, List<String>>  returnMap = UtilityController.fetchFromEmails();
            if (returnMap != null && returnMap.get('from') != null) {
                List<string> tempst = returnMap.get('from');
                tempComposeEmail.put('from', (Id) tempst.get(0));
                system.debug('tempst >>' + tempComposeEmail.get('from'));
            }*/
           // tempComposeEmail.put('cc',ToContact);
          // OrgWideEmailAddress owdlist = [SELECT Id FROM OrgWideEmailAddress where Address=:UserInfo.getUserEmail() limit 1];

          //  tempComposeEmail.put('from',owdlist.ID);
            
            String EmailTemplateID = (String)inMap.get('EmailTemplateList');
             Messaging.SingleEmailMessage message = Messaging.renderStoredEmailTemplate(EmailTemplateID, null, (Id) inMap.get('Id'));
           // EmailTemplate emtemp= [select id, Name,Subject, HtmlValue, TemplateType, Body from EmailTemplate where id =:EmailTemplateID ];
           if((String)message.getHtmlBody() == null ){
               tempComposeEmail.put('textbody',(String)message.getPlainTextBody());
            } else {
                // tempComposeEmail.put('body',(String)message.getHtmlBody());
                String returnTemplateBody = message.getHtmlBody();
                String ListView = (String)inMap.get('ListView');
                if(inMap.get('ggScreenName') == 'WCM__SendEmailReminderSC'){
                    if(records  != null){
                        Integer rowNum = 0; 
                        Double totalBillingBal = 0;
                        
                        for (Object obj : records) { 
                                Map<Object,Object> m_S_O =  new Map<Object,Object>();
                                m_S_O = (Map<Object,Object>)obj;
                                TransIds.add((String)m_S_O.get('Id'));
                                system.debug('obj>>>>>>>>>'+obj);
                        }
                        //-- Start | FIN-8334 | Changed by Ravi | 11 sep 2025 --//
                        if (returnTemplateBody.Contains('{Transactions.TotalBalance}')) {
                            Map<String,String> returnTemplateAmount = UtilityController.getTransactionTotalSummary((String)inMap.get('Id'),TransIds);
                            // returnTemplateBody = returnTemplateBody.replace('{Transactions.TotalBalance}', returnTemplateAmount.get('TotalBalance')).replace('{Transactions.TotalBalanceWithoutCurrency}', returnTemplateAmount.get('TotalBalanceWithoutCurrency')).replace('{Transactions.TotalBalanceSummary}', returnTemplateAmount.get('TotalBalanceSummary'));
                            returnTemplateBody = returnTemplateBody.replace('{Transactions.TotalBalance}', returnTemplateAmount.get('TotalBalance'));
                            //-- End | FIN-8334 | Changed by Ravi | 11 sep 2025 --//
                        }        
                                
                        htmlBody = UtilityController.getTransactionListViewData(ListView ,TransIds,false,sortfieldName,sortOrder);
        
        
                        returnTemplateBody=returnTemplateBody.replace('{Transaction.Summary}', htmlBody);
                    }

                }
                tempComposeEmail.put('body',returnTemplateBody);
            }
            
            tempComposeEmail.put('subject',message.getSubject());
            inMap.put('ComposeEmail',tempComposeEmail);
            
         return inMap;
        }
       
    }