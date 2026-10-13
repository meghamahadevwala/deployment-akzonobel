global with sharing class SendStatementEmailBodyonAccount implements celsrm.GOGIScreenCustomLogic {
    global Map<Object, Object> invoke(String functionName, Map<Object, Object> inMap){
        system.debug('Locale==='+(String)inMap.get('Locale'));
            if(functionName == 'changeListView'){
                EmailTemplate template = new EmailTemplate();
                if(inMap.get('defaultTemplate') != null){
                    String defaultTemplate = (String)inMap.get('defaultTemplate');
                    // << START - MM - FIN-9548 - [Akzonobel] [Send Statement] On change listview - body pick template using the name (not filtering by foldername)>>
                    String accountLocale = (String)inMap.get('accountLocale');
                    // << END - MM - FIN-9548 - [Akzonobel] [Send Statement] On change listview - body pick template using the name (not filtering by foldername)>>
                    //-- Start | FIN-9421 | Changed by Dhwanil Shah | 18 March 2026 --//
                     system.debug( 'defaultTemplate>>>' + defaultTemplate);
                     Map<Object, Object> composemail = (Map<Object, Object>)inMap.get('ComposeEmail');
                     // << CHANGE - MM - FIN-9992 - Added composemail != null criteria to avoid null pointer exception>>
                     if(composemail != null && composemail.containskey('templateName'))
                            defaultTemplate = String.valueof(composemail.get('templateName'));
                    //-- End | FIN-9421 | Changed by Dhwanil Shah | 18 March 2026 --//
                    // if(inMap.get('Locale') != null) {
                    //     String Locale = (String)inMap.get('Locale');
                    //     template = [SELECT Id FROM EmailTemplate where Name = :defaultTemplate and Folder.Name = :Locale Limit 1];
                    // } else {
                        // << START - MM - FIN-9548 - [Akzonobel] [Send Statement] On change listview - body pick template using the name (not filtering by foldername)>>
                        // template = [SELECT Id FROM EmailTemplate where Name = :defaultTemplate Limit 1];
                        template = [SELECT Id FROM EmailTemplate where Name = :defaultTemplate and Folder.Name = :accountLocale Limit 1];
                        // << END - MM - FIN-9548 - [Akzonobel] [Send Statement] On change listview - body pick template using the name (not filtering by foldername)>>
                    //}
                   
                }
                List<Contact> con = new List<Contact>();
                try {
                    con = [Select Id From Contact where celsrm__Default__c=true and accountId=:(String)inMap.get('Id')];
                } catch (Exception e) {
                    System.debug(e.getMessage());
                }
                
                Id ContactId ;
                if(con!= null && con.size()>0){
                    ContactId =con.get(0).Id;
                }
                Messaging.SingleEmailMessage message;
                if( ContactId != null){
                    message = Messaging.renderStoredEmailTemplate(template.Id,ContactId , (Id) inMap.get('Id'));
                }else{
                    message = Messaging.renderStoredEmailTemplate(template.Id,null, (Id) inMap.get('Id'));
                }
                String returnTemplateBody = message.getHtmlBody();
                String ListView = (String)inMap.get('ListView');

                // List<String> tList = (List<String>)JSON.deserialize(inMap.get('TransIds') , List<String>.class);
                //-- Start | FIN-8334 | Changed by Ravi | 11 sep 2025 --//
                if (returnTemplateBody.Contains('{Transactions.TotalBalance}')) {
                    if(inMap.get('returnTemplateAmount') != null) {
                        Map<String,String> returnTemplateAmount = (map<string,string>)JSON.deserialize(JSON.serialize(inMap.get('returnTemplateAmount')), map<string,string>.class);
                        returnTemplateBody = returnTemplateBody.replace('{Transactions.TotalBalance}', returnTemplateAmount.get('TotalBalance'));
                    } else {
                        String trxId = (String)inMap.get('TransIds');
                        Map<String,String> returnTemplateAmount = UtilityController.getTransactionTotalSummary((String)inMap.get('Id'), ((List<String>)trxId.split(',')));
                        System.debug('----returnTemplateAmount---------' + returnTemplateAmount);
                        returnTemplateBody = returnTemplateBody.replace('{Transactions.TotalBalance}', returnTemplateAmount.get('TotalBalance'));
                    }
                   
                }
                //-- End | FIN-8334 | Changed by Ravi | 11 sep 2025 --//
               // String htmlBody = UtilityController.getTransactionListViewData(ListView ,tList,false);
                inMap.put('BodyContent',returnTemplateBody);
                EmailMessage emailmsg = new EmailMessage();
                try {
                    emailmsg = [Select Id ,FromName,FromAddress,ToAddress,CcAddress,BccAddress,Subject,CreatedDate,HtmlBody from EmailMessage where relatedtoId =:(String)inMap.get('Id') order by CreatedDate desc limit 1];
                } catch (Exception e) {
                    System.debug(e.getMessage());
                }
                inMap.put('oldEmailmsg', emailmsg);
            }   
       
        return inMap;
    }
}