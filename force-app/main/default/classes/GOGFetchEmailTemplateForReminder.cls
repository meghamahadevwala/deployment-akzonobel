global with sharing class GOGFetchEmailTemplateForReminder implements celsrm.GOGIScreenCustomLogic {
    global Map<Object, Object> invoke(String functionName, Map<Object, Object> inMap) {
        System.debug('into GOGCustomImplementation');
        System.debug('functionName ::: ' + functionName);
        System.debug('inMap ::: ' + inMap);
        inMap.put('VendorName','adding new value');
        String AccId = (String)inMap.get('Id');
        String Acclocale = (String)inMap.get('Locale');
        
        // List<SelectOption> emailTemplatesops = new List<SelectOption>();
        List<EmailTemplate> templateList = new List<EmailTemplate>();
        List<map<string,string>> customObject = new List<map<string,string>>();
        if (Test.IsRunningTest()){
            templateList = [select id, Name from EmailTemplate where TemplateType in ('text','custom') and (NOT Name like 'SYSTEM%') and Folder.Name != null and IsActive=true order by DeveloperName ];
        }else{
            templateList = [select id, Name from EmailTemplate where TemplateType in ('text','custom') and (NOT Name like 'SYSTEM%') and Folder.Name != null and Folder.Name =: Acclocale and  IsActive=true order by DeveloperName ];
        }
        
        
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
        
        
        /* inMap.put('StatementFormat','Excel');
        inMap.put('ContactMehods','Email');
        
        List<contact> CurrentAcc = [select id, Name,Fax,Email from contact where id =: AccId and celsrm__Default__c=true];
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
        map<string,object> tempComposeEmail = (map<string,object>)JSON.deserializeUntyped(JSON.serialize(inMap.get('ComposeEmail')));
        tempComposeEmail.put('to',ToContact);
        tempComposeEmail.put('cc',ToContact);
        tempComposeEmail.put('cc',ToContact);
        
        String EmailTemplateID = (String)inMap.get('EmailTemplateList');
        EmailTemplate emtemp= [select id, Name,Subject, HtmlValue, TemplateType, Body from EmailTemplate where id =:EmailTemplateID ];
        tempComposeEmail.put('body',emtemp.HtmlValue);
        tempComposeEmail.put('subject',emtemp.Subject);*/
        
        inMap.put('dataServiceResponse',customObject);
        return inMap;
    }  
}