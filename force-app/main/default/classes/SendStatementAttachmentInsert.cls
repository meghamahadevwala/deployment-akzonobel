global class SendStatementAttachmentInsert implements celsrm.GOGIScreenCustomLogic {
    global Map<Object, Object> invoke(String functionName, Map<Object, Object> inMap) {
        System.debug('@@ inMap : ' + inMap);
        
   
        String formatType = (String)inMap.get('StatementFormat');
        // String fileType = '';
        // String ext = '';
        if(formatType != null && formatType != '' ){
        // if(formatType == 'PDF') {
        //     ext = '.pdf';
        //     fileType = 'PDF';
        // } else if(formatType == 'Excel') {
        //     ext = '.xls';
        //     fileType = 'XLS';
        // }
        
        // String trxnId = '';
        // Map<Object, Object> returnData = new Map<Object, Object>();
        
        
        
        // System.debug('@@ formatType : ' + formatType);
      
        
     /*   PageReference pRef= Page.PreviewStatement;
        pRef.getParameters().put('formatType',formatType);
        pRef.getParameters().put('accId',accId);
        pRef.getParameters().put('txIds',trxnId);
        
        System.debug('URL ::: ' + pRef.getUrl());
        Blob fileContent;
        String content;
        String contentTemplate;
        if(formatType =='Excel'){
            fileContent = pRef.getContent();
            contentTemplate = pRef.getContent().toString(); 
            content = EncodingUtil.base64Encode(pRef.getContent());
        }else{
            fileContent = pRef.getContentAsPDF();
            contentTemplate = pRef.getContent().toString(); 
            content = EncodingUtil.base64Encode(pRef.getContentAsPDF());
        }*/
            //-- Start | FIN-8509 | Changed by Ravi | 13-Oct-2025 --//
            String fileName = inMap.get('fileName') != null && inMap.get('fileName') != '' ? string.valueOf(inMap.get('fileName')) : 'BillingStatement';
            //-- Ends | FIN-8509 | Changed by Ravi | 13-Oct-2025 --//
            celsrm__Temp_Object_Holder__c temp = new celsrm__Temp_Object_Holder__c();
            
            temp.celsrm__key__c =  Userinfo.getUserName()+Datetime.now().getTime();
                   
            insert Temp;
            inMap.put('tempKey',Temp.Id);
            
            attachment att = new attachment();
            att.ParentID= Temp.Id;
            
            att.body= EncodingUtil.base64Decode((String)inMap.get('finalContent'));
            //att.body= Blob.valueOf('test content');
            if(formatType =='Excel'){
            att.ContentType = 'application/vnd.ms-excel';
            //-- Start | FIN-8509 | Changed by Ravi | 13-Oct-2025 --//
            att.name = fileName + '.xls';
            //-- Ends | FIN-8509 | Changed by Ravi | 13-Oct-2025 --//
            }else{
            //  att.ContentType = 'application/pdf';
                //-- Start | FIN-8509 | Changed by Ravi | 13-Oct-2025 --//
                att.name = fileName + '.pdf';
                //-- Ends | FIN-8509 | Changed by Ravi | 13-Oct-2025 --//
            }
            insert att;
            inMap.put('AttachmentIDSendStmt' ,att.Id);
        /* String url = 'https://ggdemo1-dev-ed--c.documentforce.com/servlet/servlet.FileDownload?file='+ att.Id;
            
         Pagereference pageref = new Pagereference(url);
        if(formatType =='PDF'){
        att.ContentType = 'application/pdf';
        att.name = 'test.pdf';
        att.Body =pageref.getContentAsPdf();
        }
        update att;*/
        
         
        //deleting exising statement
        /*List<ContentDocumentLink> existingLink = [Select Id, LinkedEntityId, ContentDocumentId From ContentDocumentLink Where ContentDocument.Title LIKE 'BillingStatement' AND LinkedEntityId = :accId];
        List<ContentDocument> cd = new List<ContentDocument>();
        for(ContentDocumentLink cdl : existingLink) {
            cd.add(new ContentDocument(Id=cdl.ContentDocumentId));
        }
        if(cd.size() > 0) {
            delete cd;
        }
        //deleting exising statement
        
        ContentVersion contentInsert =new ContentVersion();
        contentInsert.VersionData = fileContent;
        contentInsert.PathOnClient = '/BillingStatement' + ext;
        insert contentInsert;
        
        String contentRecId = contentInsert.Id;
        
        ContentVersion contentListFileUpload = [Select Id, ContentDocumentId, Title, FileType, ContentSize, VersionData FROM ContentVersion WHERE Id = :contentRecId];
        ContentDocumentLink contentLink =new ContentDocumentLink();
        contentLink.ContentDocumentId = contentListFileUpload.ContentDocumentId;
        contentLink.LinkedEntityId = accId;
        contentLink.ShareType = 'V';
        insert contentLink;*/
        
        
     /*   Map<String, String> dataMap = new Map<String, String>();
        dataMap.put('Id',null);
        dataMap.put('Title','BillingStatement' + ext);
        dataMap.put('FileType',fileType);
        dataMap.put('Base64',content);
        
        System.debug('@@@@ 111 inMap : ' + inMap);*/
        
     /*   if(inMap.containsKey('ComposeEmail') && inMap.get('ComposeEmail') != null) {
            Map<Object, Object> compMap = (Map<Object, Object>)inMap.get('ComposeEmail');
            if(compMap.containsKey('attachment') && compMap.get('attachment') != null) {
                List<Object> att = (List<Object>)compMap.get('attachment');
                if(att != null && att.size() > 0) {
                    Boolean found = false;
                    for(Integer i=0; i<att.size(); i++) {
                        if(((String)((Map<Object, Object>)att[i]).get('Title')).contains('BillingStatement')) {
                            att[i] = dataMap;
                            found = true;
                            break;
                        }
                    }
                    if(!found) {
                        att.add(dataMap);
                    }
                    //inMap.put('attachment' , att);
                } else {
                    compMap.put('attachment' , new List<Object>{ dataMap });
                }
            } else {
                compMap.put('attachment' , new List<Object>{ dataMap });
            }
        } else {
            List<Object> attachment = new List<Object> {dataMap};
            inMap.put('ComposeEmail' , new Map<String, Object>{ 'attachment' => attachment });
        }*/
        }
        System.debug('@@@@ inMap : ' + inMap);
        return inMap;
    }
}