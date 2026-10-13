global class SendStatementAttachmentformation implements celsrm.GOGIScreenCustomLogic {
    global Map<Object, Object> invoke(String functionName, Map<Object, Object> inMap) {
        System.debug('@@ inMap : ' + inMap);
        
        String formatType = (String)inMap.get('StatementFormat');
        String attID =(String) inMap.get('AttachmentIDSendStmt');
        if(formatType != null && formatType != '' && attID != null){

            
            attachment attRec = [select Id from attachment where id =:attID ];
            String tempUrl = System.URL.getSalesforceBaseUrl().getHost().remove('-api' );
            
            tempUrl = tempUrl.replace('.my.salesforce.com','.file.force.com');
            String url = URL.getSalesforceBaseUrl().getProtocol()+'://'+tempUrl +'/servlet/servlet.FileDownload?file='+ attRec.Id;
            
            System.debug('============'+url) ;
            Pagereference pageref = new Pagereference(url);

            ContentVersion contentInsert =new ContentVersion();
            // contentInsert.ContentDocumentId = null;
            if(formatType =='PDF'){
                attRec.ContentType = 'application/pdf';
                attRec.name = 'BillingStatement.pdf';

                if (Test.IsRunningTest()){
                    attRec.Body = Blob.valueOf('Unit Test Attachment Body');
                    contentInsert.VersionData = Blob.valueOf('Unit Test Attachment Body');
                } else {
                    attRec.Body = pageref.getContent();
                    contentInsert.VersionData = pageref.getContentAsPdf();
                }   
                contentInsert.PathOnClient = '/BillingStatement' + '.pdf'; 
            }else{
                if (Test.IsRunningTest()){
                    contentInsert.VersionData = Blob.valueOf('Unit Test Attachment Body');
                } else {
                    contentInsert.VersionData = pageref.getContent();
                }
                // << START - MM - FIN-8174 - Dynamic translated headers based account local >>
                // contentInsert.PathOnClient = '/BillingStatement' + '.xlsx';
                contentInsert.PathOnClient = '/BillingStatement' + '.xls';
                // << END - MM - FIN-8174 - Dynamic translated headers based account local >>
            }

            if(inMap.containsKey('ContentIDSendStmt') && (String)inMap.get('ContentIDSendStmt') != null){
                String ContentIDSendStmt = (String)inMap.get('ContentIDSendStmt');
                //-- Starts | FIN-5766 | Changed by Asera | 25 Oct 2024 --//
                List<ContentVersion> cvList = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :ContentIDSendStmt LIMIT 1];
                if (!cvList.isEmpty() && cvList[0].ContentDocumentId != null) {
                    List<ContentDocument> cdList = [SELECT Id FROM ContentDocument WHERE Id = :cvList[0].ContentDocumentId];
                    if (!cdList.isEmpty()) {
                        delete cdList[0];
                        inMap.remove('ContentIDSendStmt');
                    } else {
                        System.debug('No ContentDocument found for the given ContentDocumentId.');
                    }
                } else {
                    System.debug('No ContentVersion found for the given ContentIDSendStmt or ContentDocumentId is null.');
                }
                //-- END | FIN-5766 | Changed by Asera | 25 Oct 2024 --//
            }
            
            update attRec;
            insert contentInsert;
            inMap.put('AttachmentIDSendStmt' ,attRec.Id);
            inMap.put('ContentIDSendStmt' ,contentInsert.Id);
            List<ContentVersion> cvList = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :contentInsert.Id WITH USER_MODE LIMIT 1];
            //-- Start | FIN-7269 | 11-April-2025 -- (Attachment Related changes)//
            if (!cvList.isEmpty()) {
                inMap.put('ContentDocID' ,cvList[0].ContentDocumentId);
            }
            //-- End | FIN-7269 | 11-April-2025 -- (Attachment Related changes)//

            
            // inMap.put('ContentDocDownloadURL', System.URL.getOrgDomainURL().toExternalForm() + '/' + contentInsert.Id);
        }
        return inMap;
    }

    public Map<Object, Object> generateExcelStatementForSSAgent(Map<Object, Object> inMap){
        PageReference pRef= Page.SendStatementExcelGenerate;
        pRef.getParameters().put('accountId',String.valueOf(inMap.get('Id')));
        pRef.getParameters().put('listView',String.valueOf(inMap.get('ListView')));
        
        System.debug('URL ::: ' + pRef.getUrl());

        

        ContentVersion contentInsert =new ContentVersion();
        contentInsert.ContentDocumentId = null;
        if (Test.IsRunningTest()){
            contentInsert.VersionData = Blob.valueOf('Unit Test Attachment Body');
        } else {
            contentInsert.VersionData = pRef.getContent();
        }
        // << START - MM - FIN-8174 - Dynamic translated headers based account local >>
        // contentInsert.PathOnClient = '/BillingStatement' + '.xlsx';
        contentInsert.PathOnClient = '/BillingStatement' + '.xls';
        // << START - MM - FIN-8174 - Dynamic translated headers based account local >>
        
        if(inMap.containsKey('ContentIDSendStmt') && (String)inMap.get('ContentIDSendStmt') != null){
            String ContentIDSendStmt = (String)inMap.get('ContentIDSendStmt');
            //-- Starts | FIN-5766 | Changed by Asera | 25 Oct 2024 --//
            List<ContentVersion> cvList = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :ContentIDSendStmt LIMIT 1];
            if (!cvList.isEmpty() && cvList[0].ContentDocumentId != null) {
                List<ContentDocument> cdList = [SELECT Id FROM ContentDocument WHERE Id = :cvList[0].ContentDocumentId];
                if (!cdList.isEmpty()) {
                    delete cdList[0];
                    inMap.remove('ContentIDSendStmt');
                } else {
                    System.debug('No ContentDocument found for the given ContentDocumentId.');
                }
            } else {
                System.debug('No ContentVersion found for the given ContentIDSendStmt or ContentDocumentId is null.');
            }
            //-- END | FIN-5766 | Changed by Asera | 25 Oct 2024 --//
        }
        
        insert contentInsert;
        inMap.put('ContentIDSendStmt' ,contentInsert.Id);
        List<ContentVersion> cvList = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :contentInsert.Id WITH USER_MODE LIMIT 1];

        if (!cvList.isEmpty()) {
            inMap.put('ContentDocID' ,cvList[0].ContentDocumentId);
        }
        return inMap;
    }
}