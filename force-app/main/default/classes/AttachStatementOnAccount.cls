global class AttachStatementOnAccount implements celsrm.GOGIScreenCustomLogic {
    global Map<Object, Object> invoke(String functionName, Map<Object, Object> inMap) {
        System.debug('@@ inMap : ' + inMap);
        
        String accId = (String)inMap.get('Id');
        List<Object> arr = (List<Object>)inMap.get('TransactionList');
        String formatType = (String)inMap.get('StatementFormat');
        String fileType = '';
        String ext = '';
        if(formatType != null && formatType != '' ){
        if(formatType == 'PDF') {
            ext = '.pdf';
            fileType = 'PDF';
        } else if(formatType == 'Excel') {
            ext = '.xls';
            fileType = 'XLS';
        }
        
        String trxnId = '';
        Map<Object, Object> returnData = new Map<Object, Object>();
        
        if(arr != null && arr.size()> 0) {
        
            for(Integer i=0; i<arr.size();i++) {
                map < Object, Object> m = (map < Object, Object > )arr.get(i);
                if(inMap.get('ggScreenName') == 'OTCPromisToPayScreenEmailAction' && ( !m.containsKey('isSelected') || !((Boolean)m.get('isSelected')) )) {
                    continue;
                }
                if(i == arr.size()-1) {
                    trxnId += m.get('Id');
                } else {
                    trxnId += m.get('Id') + ',';
                }
            }
                    
            //String url = 'https://ggdemo1-dev-ed--c.visualforce.com/apex/PreviewStatement?formatType='+formatType+'&accId='+accId+'&txIds='+trxnId;
            //window.open(url,'_blank');
        }
        
        System.debug('@@ formatType : ' + formatType);
        System.debug('@@ accId : ' + accId);
        System.debug('@@ trxnId : ' + trxnId);
        
        PageReference pRef= Page.celsrm__PreviewStatement;
        pRef.getParameters().put('formatType',formatType);
        pRef.getParameters().put('accId',accId);
        if(inMap.containsKey('tempKey') && inMap.get('tempKey') != null && inMap.get('tempKey') != '' ){
            pRef.getParameters().put('key',(String)inMap.get('tempKey'));
        } else{
            pRef.getParameters().put('txIds',trxnId);
        }
        
        if(inMap.get('ListView') == null) {
            //TODO:: Need to make it conifgurable
            List<celsrm__Custom_List_View__c> dbView = [SELECT Id FROM celsrm__Custom_List_View__c WHERE celsrm__ListView_For_Object__c ='celsrm__Transaction__c' and Name='System Default View'];
            pRef.getParameters().put('ListView',dbView.get(0).id);
        } else{
            pRef.getParameters().put('ListView',(String)inMap.get('ListView'));
        }
        
        System.debug('URL ::: ' + pRef.getUrl());
        Blob fileContent;
        String content;
        if(formatType =='Excel'){
            if (Test.IsRunningTest()){
                fileContent = Blob.valueOf('Unit Test Attachment Body');
                content = EncodingUtil.base64Encode(fileContent);
            } else {
                fileContent = pRef.getContent();
                content = EncodingUtil.base64Encode(pRef.getContent());
            }
        }else{
            if (Test.IsRunningTest()){
                fileContent = Blob.valueOf('Unit Test Attachment Body');
                content = EncodingUtil.base64Encode(fileContent);
            } else {
                fileContent = pRef.getContentAsPDF();
                content = EncodingUtil.base64Encode(pRef.getContentAsPDF());
            }    
        }
        
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
        //-- Start | FIN-8509 | Changed by Ravi | 13-Oct-2025 --//
        String fileName = inMap.get('fileName') != null && inMap.get('fileName') != '' ? string.valueOf(inMap.get('fileName')) : 'BillingStatement';
        //-- Ends | FIN-8509 | Changed by Ravi | 13-Oct-2025 --//
        Map<String, String> dataMap = new Map<String, String>();
        dataMap.put('Id',null);
        //-- Start | FIN-8509 | Changed by Ravi | 13-Oct-2025 --//
        dataMap.put('Title',fileName + ext);
        //-- Ends |FIN-8509 | Changed by Ravi | 13-Oct-2025 --//
        dataMap.put('FileType',fileType);
        dataMap.put('Base64',content);
        
        System.debug('@@@@ 111 inMap : ' + inMap.get('ComposeEmail'));
        
        if(inMap.containsKey('ComposeEmail') && inMap.get('ComposeEmail') != null) {
            Map<Object, Object> compMap = (Map<Object, Object>)inMap.get('ComposeEmail');
            if(compMap.containsKey('attachment') && compMap.get('attachment') != null) {
                List<Object> att = (List<Object>)compMap.get('attachment');
                if(att != null && att.size() > 0) {
                    // Boolean found = false;
                    // for(Integer i=0; i<att.size(); i++) {
                    //     if(((String)((Map<Object, Object>)att[i]).get('Title')).contains('BillingStatement')) {
                    //         att[i] = dataMap;
                    //         found = true;
                    //         break;
                    //     }
                    // }
                    // if(!found) {
                    //     att.add(dataMap);
                    // }
                    att.add(dataMap);
                    compMap.put('attachment', att);
                    //inMap.put('attachment' , att);
                } else {
                    compMap.put('attachment' , new List<Object>{ dataMap });
                }
            } else {
                compMap.put('attachment' , new List<Object>{ dataMap });
            }
             inMap.put('ComposeEmail' , compMap);
        } else {
            List<Object> attachment = new List<Object> {dataMap};
            inMap.put('ComposeEmail' , new Map<String, Object>{ 'attachment' => attachment });
        }
        }
        System.debug('@@@@ inMap.get ' + inMap.get('ComposeEmail'));
        System.debug('@@@@ inMap : ' + inMap);
        return inMap;
    }
}