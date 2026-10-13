// << START - MM - FIN-9047 - [Collections] Use SendGrid to send outbound emails >>
public without sharing class GOGCustomEmailSendAkzoNobel {
// global without sharing class GOGCustomEmailSendAkzoNobel implements Queueable, Database.AllowsCallouts {

    // << START - MM -  - [AkzoNobel] [Instant Auto Dunning] Email Not sent | Use queueable instead of future method for sending email >>
    // private Id fromId;
    // private String parentId;
    // private List<String> toAddress;
    // private List<String> ccAddress;
    // private List<String> bccAddress;
    // private String subject;
    // private String htmlBody;
    // private String textBody;
    // private String attachmentobjJson;

    // public GOGCustomEmailSendAkzoNobel(
    //     Id fromId,
    //     String parentId,
    //     List<String> toAddress,
    //     List<String> ccAddress,
    //     List<String> bccAddress,
    //     String subject,
    //     String htmlBody,
    //     String textBody,
    //     String attachmentobjJson
    // ) {
    //     this.fromId = fromId;
    //     this.parentId = parentId;
    //     this.toAddress = toAddress;
    //     this.ccAddress = ccAddress;
    //     this.bccAddress = bccAddress;
    //     this.subject = subject;
    //     this.htmlBody = htmlBody;
    //     this.textBody = textBody;
    //     this.attachmentobjJson = attachmentobjJson;
    // }

    // public void execute(QueueableContext context) {
    //     sendEmailAPI();
    // }
    // << END - MM - FIN-9698 - [AkzoNobel] [Instant Auto Dunning] Email Not sent | Use queueable instead of future method for sending email >>


    /**
    // << START - MM - FIN-9698 - [AkzoNobel] [Instant Auto Dunning] Email Not sent | Use queueable instead of future method for sending email >>
    private void sendEmailAPI() {
        try {
            Map<Object,Object> returnMap = new Map<Object,Object>();
            String TOAddressString = (this.toAddress != null) ? String.join(this.toAddress, ',') : null;
            String CCAddressString = (this.ccAddress != null) ? String.join(this.ccAddress, ',') : null;
            String BCCAddressString = (this.bccAddress != null) ? String.join(this.bccAddress, ',') : null;
            String fromAddress, fromName;
            Boolean hasAttachment = false;
            if (this.fromId != null && this.fromId.getSObjectType() == OrgWideEmailAddress.sObjectType) {
                OrgWideEmailAddress owe = [SELECT Address, DisplayName FROM OrgWideEmailAddress WHERE Id = :this.fromId LIMIT 1];
                fromAddress = owe.Address;
                fromName = owe.DisplayName;
            }
            Map<String, Object> personalisationMap = new Map<String, Object>();
            if(this.toAddress != null && this.toAddress.size() > 0) {
                for(String to : this.toAddress) {
                    if(personalisationMap.keySet().contains('to')) {
                        List<Object> toList = (List<Object>)personalisationMap.get('to');
                        toList.add(new Map<String, String>{
                            'email' => to
                        });
                        personalisationMap.put('to', toList);
                    } else {
                        personalisationMap.put('to', new List<Map<String, String>>{
                            new Map<String, String>{
                                'email' => to
                            }
                        });
                    }
                }
            }
            if(this.ccAddress != null && this.ccAddress.size() > 0) {
                for(String cc : this.ccAddress) {
                    if(personalisationMap.keySet().contains('cc')) {
                        List<Object> ccList = (List<Object>)personalisationMap.get('cc');
                        ccList.add(new Map<String, String>{
                            'email' => cc
                        });
                        personalisationMap.put('cc', ccList);
                    } else {
                        personalisationMap.put('cc', new List<Map<String, String>>{
                            new Map<String, String>{
                                'email' => cc
                            }
                        });
                    }
                }
            }
            if(this.bccAddress != null && this.bccAddress.size() > 0) {
                for(String bcc : this.bccAddress) {
                    if(personalisationMap.keySet().contains('bcc')) {
                        List<Object> bccList = (List<Object>)personalisationMap.get('bcc');
                        bccList.add(new Map<String, String>{
                            'email' => bcc
                        });
                        personalisationMap.put('bcc', bccList);
                    } else {
                        personalisationMap.put('bcc', new List<Map<String, String>>{
                            new Map<String, String>{
                                'email' => bcc
                            }
                        });
                    }
                }
            }
            Map<String, Object> bodyMap = new Map<String, Object>{
                            'personalizations' => new List<Map<String, Object>>{
                                    personalisationMap
                            },
                            'from' => new Map<String, String>{
                                'email' => fromAddress
                            },
                            'subject' => this.subject,
                            'content' => new List<Map<String, String>>{
                                new Map<String, String>{
                                    'type' => 'text/html',
                                    'value' => this.htmlBody
                                }
                            }
                        };
            String bodyJson = JSON.serialize(bodyMap);

            List<ContentVersion> contentVersionList = new List<ContentVersion>();
            if(this.attachmentobjJson != null && this.attachmentobjJson != '') {
                List<Map<String,String>> attachmentobj = (List<Map<String, String>>) JSON.deserialize(this.attachmentobjJson, List<Map<String, String>>.class);
                if(attachmentobj != null && attachmentobj.size() > 0) {
                    List<String> documentIdSet = new List<String>();
                    List<String> contentVersionId = new List<String>();
                    List<String> listOfFileAttachment = new List<String>();
                    for(Map<String, String> obj: attachmentobj){
                        if (obj != null) {
                            if (obj.get('Id') != null && obj.get('Id') != '') {
                                String fileId = (String)obj.get('Id');
                                documentIdSet.add(fileId);
                                // if (fileId.containsIgnoreCase('068')) {
                                //     contentVersionId.add(fileId);
                                // } else {
                                //     listOfFileAttachment.add(fileId);
                                // }
                            }
                            //  else if (obj.get('Base64') != null && obj.get('Base64') != '') {
                            //     ContentVersion contentDoc = new ContentVersion();
                            //     contentDoc.VersionData = EncodingUtil.base64Decode(obj.get('Base64'));
                            //     contentDoc.pathonclient = '/'+String.valueOf(obj.get('Title'));
                            //     listOfNewFiles.add(contentDoc);
                            // }
                        }
                    }

                    List<Map<String, String>> attachmentMapList = new List<Map<String, String>>();
                    // if(!contentVersionId.isEmpty() || !listOfFileAttachment.isEmpty()){
                    if(!documentIdSet.isEmpty() || !listOfFileAttachment.isEmpty()){
                        String contentVersionQuery = 'SELECT Id, Title, fileExtension, VersionData, ContentDocumentId FROM ContentVersion WHERE ';
                        contentVersionQuery += ' Id IN :documentIdSet';
                        contentVersionQuery += ' OR ContentDocumentId IN :documentIdSet';
                        // if(!contentVersionId.isEmpty() ){
                        //     contentVersionQuery += ' Id IN :contentVersionId';
                        // }
                        // if(!listOfFileAttachment.isEmpty()){
                        //     contentVersionQuery += ' OR ContentDocumentId IN :listOfFileAttachment';
                        // }
                        contentVersionQuery += ' ORDER BY CreatedDate DESC';
                        System.debug('contentVersionQuery>>>>' + contentVersionQuery);

                        contentVersionList = Database.query(contentVersionQuery);
                        for(ContentVersion conVersion : contentVersionList){
                            Map<String, String> attachmentMap = new Map<String, String>{
                                'filename' => conVersion.Title + '.' + conVersion.fileExtension,
                                'type' => 'application/' + conVersion.fileExtension,
                                // 'Content' => EncodingUtil.base64Encode(conVersion.VersionData)
                                'Content' => EncodingUtil.base64Encode(conVersion.VersionData),
                                'disposition' => 'attachment'
                            };
                            attachmentMapList.add(attachmentMap);
                        }
                    } 

                    if(!attachmentMapList.isEmpty() && attachmentMapList.size() > 0) {
                        hasAttachment = true;
                        bodyMap = new Map<String, Object>{
                            'personalizations' => new List<Map<String, Object>>{
                                personalisationMap
                            },
                            'from' => new Map<String, String>{
                                'email' => fromAddress
                            },
                            'subject' => this.subject,
                            'content' => new List<Map<String, String>>{
                                new Map<String, String>{
                                    'type' => 'text/html',
                                    'value' => this.htmlBody
                                }
                            },
                            'attachments' => attachmentMapList
                        };
                                    //                         'cc' => new List<Map<String, String>>{
                                    //     new Map<String, String>{
                                    //         'email' => CCAddressString
                                    //     }
                                    // },
                                    // 'bcc' => new List<Map<String, String>>{
                                    //     new Map<String, String>{
                                    //         'email' => BCCAddressString
                                    //     }
                                    // }

                        bodyJson = JSON.serialize(bodyMap);
                    }
                }
            } 
            System.debug('bodyJson>>>>'+ bodyJson);
            HttpRequest req = new HttpRequest();
            req.setEndpoint('callout:Send_Grid_Integration' + '/v3/mail/send');
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setBody(bodyJson);

            String errorId = null;
            String errorMessages = null;
            // << START - MM - FIN-9136 - Avoid callout during test execution >>
            if(!Test.isRunningTest()) {
                Http http = new Http();
                HttpResponse res = http.send(req);
                String responseBody = res.getBody();
                System.debug('responseBody>>>>' + responseBody);
                // Boolean isSuccess = false;
                if(res.getStatusCode() == 202) {
                    // isSuccess = true;
                    System.debug('Email Accepted Successfully');
                } else {
                    // isSuccess = false;
                    errorMessages = '';
                    Map<String, Object> parsedResponse = (Map<String, Object>)JSON.deserializeUntyped(responseBody);
                    if(parsedResponse.containsKey('id')) {
                        errorId = (String) parsedResponse.get('id');
                    }
                    if(parsedResponse.containsKey('errors')) {
                        List<Object> errors = (List<Object>)parsedResponse.get('errors');
                        errorMessages = 'Status code is ' + res.getStatusCode() + '.';
                        if(!errors.isEmpty()) {
                            for(Object error: errors) {
                                Map<String, Object> errorMap = (Map<String, Object>) error;
                                errorMessages += '\n' + (String) errorMap.get('message') + '.';
                            }
                        }
                    }
                }
            }
            // << END - MM - FIN-9136 - Avoid callout during test execution >>
            //  if (res.getStatusCode() == 400) {
            //     Map<String, Object> parsedResponse = (Map<String, Object>)JSON.deserializeUntyped(responseBody);
            //     errorId = (String) parsedResponse.get('id');
            //     if(parsedResponse.containsKey('id')){
            //         returnMap.put(false, 'Bad request error. Id: ' + errorId);
            //     }
            // } else if (res.getStatusCode() == 401) {
            //     Map<String, Object> parsedResponse = (Map<String, Object>)JSON.deserializeUntyped(responseBody);
            //     errorId = (String) parsedResponse.get('id');
            //     if(parsedResponse.containsKey('id')){
            //         returnMap.put(false, 'Unauthorized error. Id: ' + errorId);
            //     }
            // } else if (res.getStatusCode() == 403) {
            //     Map<String, Object> parsedResponse = (Map<String, Object>)JSON.deserializeUntyped(responseBody);
            //     errorId = (String) parsedResponse.get('id');
            //     if(parsedResponse.containsKey('id')){
            //         returnMap.put(false, 'Forbidden error. Id: ' + errorId);
            //     }
            // } else if (res.getStatusCode() == 404) {
            //     Map<String, Object> parsedResponse = (Map<String, Object>)JSON.deserializeUntyped(responseBody);
            //     errorId = (String) parsedResponse.get('id');
            //     if(parsedResponse.containsKey('id')){
            //         returnMap.put(false, 'Not found error. Id: ' + errorId);
            //     }
            // } else if (res.getStatusCode() == 405) {
            //     Map<String, Object> parsedResponse = (Map<String, Object>)JSON.deserializeUntyped(responseBody);
            //     errorId = (String) parsedResponse.get('id');
            //     if(parsedResponse.containsKey('id')){
            //         returnMap.put(false, 'Method not allowed error. Id: ' + errorId);
            //     }
            // } else if (res.getStatusCode() == 413) {
            //     Map<String, Object> parsedResponse = (Map<String, Object>)JSON.deserializeUntyped(responseBody);
            //     errorId = (String) parsedResponse.get('id');
            //     if(parsedResponse.containsKey('id')){
            //         returnMap.put(false, 'Payload too large error. Id: ' + errorId);
            //     }
            // } else if (res.getStatusCode() == 500) {
            //     Map<String, Object> parsedResponse = (Map<String, Object>)JSON.deserializeUntyped(responseBody);
            //     errorId = (String) parsedResponse.get('id');
            //     if(parsedResponse.containsKey('id')){
            //         returnMap.put(false, 'Internal server error. Id: ' + errorId);
            //     }
            // }
            // String messageId = '';
            // Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            // if (responseMap.containsKey('ErrorCode') && (Integer) responseMap.get('ErrorCode') == 0) {
            //     messageId = (String) responseMap.get('MessageID');
            // }
            // System.debug('messageId>>>>' + messageId);

            EmailMessage emailMessage = new EmailMessage();
            emailMessage.Subject = this.subject;
            emailMessage.FromAddress = fromAddress; // The "from" email address
            emailMessage.ToAddress = TOAddressString;
            emailMessage.CcAddress = CCAddressString; // Set the CC addresses
            emailMessage.BccAddress = BCCAddressString; // Set the BCC addresses
            emailMessage.Status = '3'; // '3' for Sent
            emailMessage.Incoming = false; // False for outgoing emails
            emailMessage.RelatedToId = this.parentId;
            emailMessage.MessageDate = System.now();
            emailMessage.FromName = fromName;
            emailMessage.HtmlBody = this.htmlBody; // or emailMessage.TextBody = this.textbody if it's plain text
            emailMessage.TextBody = this.textbody;
            emailMessage.SendGrid_Error_Id__c = errorId;
            emailMessage.SendGrid_Error_Messages__c = errorMessages;
            emailMessage.celsrm__HasAttachment__c = hasAttachment;
            emailMessage.IsClientManaged = hasAttachment;
            // // split html body
            // List<String> splitHtmlbody= new List<String>();
            // system.debug('Htmlbody.length() >>> ' + emailBean.htmlBody.length());

            // if( emailBean.htmlBody.length() > 131070) {
            //     for (integer i = 0; i <= Math.floor( emailBean.htmlBody.length()/131070); i++) {
            //         if((i+1)*131070 <  emailBean.htmlBody.length()){
            //             splitHtmlbody.add( emailBean.htmlBody.subString(i*131070, (i+1)*131070));
            //         }
            //         if((i+1)*131070 >  emailBean.htmlBody.length()){
            //             splitHtmlbody.add( emailBean.htmlBody.subString(i*131070,  emailBean.htmlBody.length()));
            //         } 
            //     }
            //     emailMessage.celsrm__Html_Body__c = splitHtmlbody[0];
            //     for (integer i = 1; i < splitHtmlbody.size(); i++) {
            //         if (i < 4) {
            //             emailMessage.put('celsrm__Html_Body_'+(i+1)+'__c', splitHtmlbody[i]);
            //         }
            //     }
            // } else {
            //     emailMessage.celsrm__Html_Body__c = emailBean.htmlBody;
            // }

            // // Store Text Body
            // String textbody = emailBean.htmlBody.stripHtmlTags();
            // System.debug('textbody>>>' + textbody);
            // List<String> splitTextbody=new List<String>();
            // system.debug('textbody.length() >>> ' + textbody.length());
            // if(textbody.length() > 131070) {
            //     for (integer i = 0; i <= Math.floor(textbody.length()/131070); i++) {
            //         if((i+1)*131070 < textbody.length()){
            //             splitTextbody.add(textbody.subString(i*131070, (i+1)*131070));
            //         }
            //         if((i+1)*131070 > textbody.length()){
            //             splitTextbody.add(textbody.subString(i*131070, textbody.length()));
            //         } 
            //     }
            //     for (integer i = 0; i < splitTextbody.size(); i++) {
            //         if (i < 4) {
            //             emailMessage.put('celsrm__Text_Body_'+(i+1)+'__c', splitTextbody[i]);
            //         }
            //     }
            // } else {
            //     emailMessage.celsrm__Text_Body_1__c = textbody;
            // }
            
            insert emailMessage;

            List<ContentDocumentLink> listOfContentLink = new List<ContentDocumentLink>();
            // << START - MM - FIN-9184 - [Dunning] Email message not generated for few auto dunning emails >>
            // Map<String, ContentWorkspaceDoc> conWorkDocMap = new Map<String, ContentWorkspaceDoc>();
            // << END - MM - FIN-9184 - [Dunning] Email message not generated for few auto dunning emails >>
            String shareWorkspaceId = '';
            List<ContentWorkspace> shareWorkspaceList = [SELECT Id FROM ContentWorkspace WHERE Name = 'AR Files' WITH USER_MODE LIMIT 1];
            if(shareWorkspaceList != null && shareWorkspaceList.size() > 0) {
                shareWorkspaceId = shareWorkspaceList.get(0).Id;
            }
            // << START - MM - FIN-9184 - [Dunning] Email message not generated for few auto dunning emails >>
            List<String> contentDocumentIds = new List<String>();
            // << END - MM - FIN-9184 - [Dunning] Email message not generated for few auto dunning emails >>
            for(ContentVersion conVersion : contentVersionList){
                ContentDocumentLink contentLink = new ContentDocumentLink();
                contentLink.ContentDocumentId = conVersion.ContentDocumentId;
                contentLink.LinkedEntityId = emailMessage.Id;
                contentLink.ShareType = 'V';
                listOfContentLink.add(contentLink);

                if(shareWorkspaceId != '' && shareWorkspaceId != null){
                    contentDocumentIds.add(conVersion.ContentDocumentId);
                    // << START - MM - FIN-9184 - [Dunning] Email message not generated for few auto dunning emails >>
                //     ContentWorkspaceDoc contentWorspaceDocObj = new ContentWorkspaceDoc();
                //     contentWorspaceDocObj.ContentDocumentId = conVersion.ContentDocumentId;
                //     contentWorspaceDocObj.ContentWorkspaceId = shareWorkspaceId;
                //     conWorkDocMap.put(contentWorspaceDocObj.ContentDocumentId, contentWorspaceDocObj);
                    // << END - MM - FIN-9184 - [Dunning] Email message not generated for few auto dunning emails >>
                }
                
            }
            if(!listOfContentLink.isEmpty()) {
                insert listOfContentLink;
                if(hasAttachment == true) {
                    EmailMessage em = new EmailMessage(Id = emailMessage.Id);
                    em.celsrm__HasAttachment__c = true;
                    update em;
                }
            }
            // << START - MM - FIN-9184 - [Dunning] Email message not generated for few auto dunning emails >>
            if (contentDocumentIds.size() > 0) {
                insertContentWorkspaceDoc(contentDocumentIds, shareWorkspaceId, emailMessage.Id);
            }
            // << END - MM - FIN-9184 - [Dunning] Email message not generated for few auto dunning emails >>
            // return returnMap;
        } catch (Exception e) {
            System.debug('error: ' + e.getMessage());
            throw e;
            // if (retryCount > 2) {
            //     System.debug('error: ' + e.getMessage());
            //     throw e;
            // } else {
            //     // we will try 3 times
            //     Integer randomNumber = Math.abs(Crypto.getRandomInteger()) % 200 + 1;
            //     System.sleep(randomNumber * 1000);
            //     retryCount = retryCount + 1;
            //     System.debug('Send email process failed, retry count ' + retryCount);
            //     return sendEmailAPI(toAddress, ccAddress, bccAddress, subject, body, retryCount);
            // }
        }
    }
    // << END - MM - FIN-9698 - [AkzoNobel] [Instant Auto Dunning] Email Not sent | Use queueable instead of future method for sending email >>
    */

    @future(callout=true)
    public static void sendEmailAPI(Id fromId, String parentId, List<String> toAddress, List<String> ccAddress, List<String> bccAddress, String subject, String htmlBody, String textbody, String attachmentobjJson) {
        try {
            Map<Object,Object> returnMap = new Map<Object,Object>();
            String TOAddressString = (toAddress != null) ? String.join(toAddress, ',') : null;
            String CCAddressString = (ccAddress != null) ? String.join(ccAddress, ',') : null;
            String BCCAddressString = (bccAddress != null) ? String.join(bccAddress, ',') : null;
            String fromAddress, fromName;
            Boolean hasAttachment = false;
            if (fromId != null && fromId.getSObjectType() == OrgWideEmailAddress.sObjectType) {
                OrgWideEmailAddress owe = [SELECT Address, DisplayName FROM OrgWideEmailAddress WHERE Id = :fromId LIMIT 1];
                fromAddress = owe.Address;
                fromName = owe.DisplayName;
            }
            Map<String, Object> personalisationMap = new Map<String, Object>();
            if(toAddress != null && toAddress.size() > 0) {
                for(String to : toAddress) {
                    if(personalisationMap.keySet().contains('to')) {
                        List<Object> toList = (List<Object>)personalisationMap.get('to');
                        toList.add(new Map<String, String>{
                            'email' => to
                        });
                        personalisationMap.put('to', toList);
                    } else {
                        personalisationMap.put('to', new List<Map<String, String>>{
                            new Map<String, String>{
                                'email' => to
                            }
                        });
                    }
                }
            }
            if(ccAddress != null && ccAddress.size() > 0) {
                for(String cc : ccAddress) {
                    if(personalisationMap.keySet().contains('cc')) {
                        List<Object> ccList = (List<Object>)personalisationMap.get('cc');
                        ccList.add(new Map<String, String>{
                            'email' => cc
                        });
                        personalisationMap.put('cc', ccList);
                    } else {
                        personalisationMap.put('cc', new List<Map<String, String>>{
                            new Map<String, String>{
                                'email' => cc
                            }
                        });
                    }
                }
            }
            if(bccAddress != null && bccAddress.size() > 0) {
                for(String bcc : bccAddress) {
                    if(personalisationMap.keySet().contains('bcc')) {
                        List<Object> bccList = (List<Object>)personalisationMap.get('bcc');
                        bccList.add(new Map<String, String>{
                            'email' => bcc
                        });
                        personalisationMap.put('bcc', bccList);
                    } else {
                        personalisationMap.put('bcc', new List<Map<String, String>>{
                            new Map<String, String>{
                                'email' => bcc
                            }
                        });
                    }
                }
            }
            Map<String, Object> bodyMap = new Map<String, Object>{
                            'personalizations' => new List<Map<String, Object>>{
                                    personalisationMap
                            },
                            'from' => new Map<String, String>{
                                'email' => fromAddress
                            },
                            'subject' => subject,
                            'content' => new List<Map<String, String>>{
                                new Map<String, String>{
                                    'type' => 'text/html',
                                    'value' => htmlBody
                                }
                            }
                        };
            String bodyJson = JSON.serialize(bodyMap);

            List<ContentVersion> contentVersionList = new List<ContentVersion>();
            if(attachmentobjJson != null && attachmentobjJson != '') {
                List<Map<String,String>> attachmentobj = (List<Map<String, String>>) JSON.deserialize(attachmentobjJson, List<Map<String, String>>.class);
                if(attachmentobj != null && attachmentobj.size() > 0) {
                    List<String> documentIdSet = new List<String>();
                    List<String> contentVersionId = new List<String>();
                    List<String> listOfFileAttachment = new List<String>();
                    for(Map<String, String> obj: attachmentobj){
                        if (obj != null) {
                            if (obj.get('Id') != null && obj.get('Id') != '') {
                                String fileId = (String)obj.get('Id');
                                documentIdSet.add(fileId);
                                // if (fileId.containsIgnoreCase('068')) {
                                //     contentVersionId.add(fileId);
                                // } else {
                                //     listOfFileAttachment.add(fileId);
                                // }
                            }
                            //  else if (obj.get('Base64') != null && obj.get('Base64') != '') {
                            //     ContentVersion contentDoc = new ContentVersion();
                            //     contentDoc.VersionData = EncodingUtil.base64Decode(obj.get('Base64'));
                            //     contentDoc.pathonclient = '/'+String.valueOf(obj.get('Title'));
                            //     listOfNewFiles.add(contentDoc);
                            // }
                        }
                    }

                    List<Map<String, String>> attachmentMapList = new List<Map<String, String>>();
                    // if(!contentVersionId.isEmpty() || !listOfFileAttachment.isEmpty()){
                    if(!documentIdSet.isEmpty() || !listOfFileAttachment.isEmpty()){
                        String contentVersionQuery = 'SELECT Id, Title, fileExtension, VersionData, ContentDocumentId FROM ContentVersion WHERE ';
                        contentVersionQuery += ' Id IN :documentIdSet';
                        contentVersionQuery += ' OR ContentDocumentId IN :documentIdSet';
                        // if(!contentVersionId.isEmpty() ){
                        //     contentVersionQuery += ' Id IN :contentVersionId';
                        // }
                        // if(!listOfFileAttachment.isEmpty()){
                        //     contentVersionQuery += ' OR ContentDocumentId IN :listOfFileAttachment';
                        // }
                        contentVersionQuery += ' ORDER BY CreatedDate DESC';
                        System.debug('contentVersionQuery>>>>' + contentVersionQuery);

                        contentVersionList = Database.query(contentVersionQuery);
                        for(ContentVersion conVersion : contentVersionList){
                            Map<String, String> attachmentMap = new Map<String, String>{
                                'filename' => conVersion.Title + '.' + conVersion.fileExtension,
                                'type' => 'application/' + conVersion.fileExtension,
                                // 'Content' => EncodingUtil.base64Encode(conVersion.VersionData)
                                'Content' => EncodingUtil.base64Encode(conVersion.VersionData),
                                'disposition' => 'attachment'
                            };
                            attachmentMapList.add(attachmentMap);
                        }
                    } 

                    if(!attachmentMapList.isEmpty() && attachmentMapList.size() > 0) {
                        hasAttachment = true;
                        bodyMap = new Map<String, Object>{
                            'personalizations' => new List<Map<String, Object>>{
                                personalisationMap
                            },
                            'from' => new Map<String, String>{
                                'email' => fromAddress
                            },
                            'subject' => subject,
                            'content' => new List<Map<String, String>>{
                                new Map<String, String>{
                                    'type' => 'text/html',
                                    'value' => htmlBody
                                }
                            },
                            'attachments' => attachmentMapList
                        };
                                    //                         'cc' => new List<Map<String, String>>{
                                    //     new Map<String, String>{
                                    //         'email' => CCAddressString
                                    //     }
                                    // },
                                    // 'bcc' => new List<Map<String, String>>{
                                    //     new Map<String, String>{
                                    //         'email' => BCCAddressString
                                    //     }
                                    // }

                        bodyJson = JSON.serialize(bodyMap);
                    }
                }
            } 
            System.debug('bodyJson>>>>'+ bodyJson);
            HttpRequest req = new HttpRequest();
            req.setEndpoint('callout:Microsoft_Graph');
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setBody(bodyJson);

            String errorId = null;
            String errorMessages = null;
            // << START - MM - FIN-9136 - Avoid callout during test execution >>
            if(!Test.isRunningTest()) {
                Http http = new Http();
                HttpResponse res = http.send(req);
                String responseBody = res.getBody();
                System.debug('responseBody>>>>' + responseBody);
                // Boolean isSuccess = false;
                if(res.getStatusCode() == 202) {
                    // isSuccess = true;
                    System.debug('Email Accepted Successfully');
                } else {
                    // isSuccess = false;
                    errorMessages = '';
                    Map<String, Object> parsedResponse = (Map<String, Object>)JSON.deserializeUntyped(responseBody);
                    if(parsedResponse.containsKey('id')) {
                        errorId = (String) parsedResponse.get('id');
                    }
                    if(parsedResponse.containsKey('errors')) {
                        List<Object> errors = (List<Object>)parsedResponse.get('errors');
                        errorMessages = 'Status code is ' + res.getStatusCode() + '.';
                        if(!errors.isEmpty()) {
                            for(Object error: errors) {
                                Map<String, Object> errorMap = (Map<String, Object>) error;
                                errorMessages += '\n' + (String) errorMap.get('message') + '.';
                            }
                        }
                    }
                }
            }
            // << END - MM - FIN-9136 - Avoid callout during test execution >>
            //  if (res.getStatusCode() == 400) {
            //     Map<String, Object> parsedResponse = (Map<String, Object>)JSON.deserializeUntyped(responseBody);
            //     errorId = (String) parsedResponse.get('id');
            //     if(parsedResponse.containsKey('id')){
            //         returnMap.put(false, 'Bad request error. Id: ' + errorId);
            //     }
            // } else if (res.getStatusCode() == 401) {
            //     Map<String, Object> parsedResponse = (Map<String, Object>)JSON.deserializeUntyped(responseBody);
            //     errorId = (String) parsedResponse.get('id');
            //     if(parsedResponse.containsKey('id')){
            //         returnMap.put(false, 'Unauthorized error. Id: ' + errorId);
            //     }
            // } else if (res.getStatusCode() == 403) {
            //     Map<String, Object> parsedResponse = (Map<String, Object>)JSON.deserializeUntyped(responseBody);
            //     errorId = (String) parsedResponse.get('id');
            //     if(parsedResponse.containsKey('id')){
            //         returnMap.put(false, 'Forbidden error. Id: ' + errorId);
            //     }
            // } else if (res.getStatusCode() == 404) {
            //     Map<String, Object> parsedResponse = (Map<String, Object>)JSON.deserializeUntyped(responseBody);
            //     errorId = (String) parsedResponse.get('id');
            //     if(parsedResponse.containsKey('id')){
            //         returnMap.put(false, 'Not found error. Id: ' + errorId);
            //     }
            // } else if (res.getStatusCode() == 405) {
            //     Map<String, Object> parsedResponse = (Map<String, Object>)JSON.deserializeUntyped(responseBody);
            //     errorId = (String) parsedResponse.get('id');
            //     if(parsedResponse.containsKey('id')){
            //         returnMap.put(false, 'Method not allowed error. Id: ' + errorId);
            //     }
            // } else if (res.getStatusCode() == 413) {
            //     Map<String, Object> parsedResponse = (Map<String, Object>)JSON.deserializeUntyped(responseBody);
            //     errorId = (String) parsedResponse.get('id');
            //     if(parsedResponse.containsKey('id')){
            //         returnMap.put(false, 'Payload too large error. Id: ' + errorId);
            //     }
            // } else if (res.getStatusCode() == 500) {
            //     Map<String, Object> parsedResponse = (Map<String, Object>)JSON.deserializeUntyped(responseBody);
            //     errorId = (String) parsedResponse.get('id');
            //     if(parsedResponse.containsKey('id')){
            //         returnMap.put(false, 'Internal server error. Id: ' + errorId);
            //     }
            // }
            // String messageId = '';
            // Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            // if (responseMap.containsKey('ErrorCode') && (Integer) responseMap.get('ErrorCode') == 0) {
            //     messageId = (String) responseMap.get('MessageID');
            // }
            // System.debug('messageId>>>>' + messageId);

            EmailMessage emailMessage = new EmailMessage();
            emailMessage.Subject = subject;
            emailMessage.FromAddress = fromAddress; // The "from" email address
            emailMessage.ToAddress = TOAddressString;
            emailMessage.CcAddress = CCAddressString; // Set the CC addresses
            emailMessage.BccAddress = BCCAddressString; // Set the BCC addresses
            emailMessage.Status = '3'; // '3' for Sent
            emailMessage.Incoming = false; // False for outgoing emails
            emailMessage.RelatedToId = parentId;
            emailMessage.MessageDate = System.now();
            emailMessage.FromName = fromName;
            emailMessage.HtmlBody = htmlBody; // or emailMessage.TextBody = textbody if it's plain text
            emailMessage.TextBody = textbody;
            emailMessage.SendGrid_Error_Id__c = errorId;
            emailMessage.SendGrid_Error_Messages__c = errorMessages;
            emailMessage.celsrm__HasAttachment__c = hasAttachment;
            emailMessage.IsClientManaged = hasAttachment;
            // // split html body
            // List<String> splitHtmlbody= new List<String>();
            // system.debug('Htmlbody.length() >>> ' + emailBean.htmlBody.length());

            // if( emailBean.htmlBody.length() > 131070) {
            //     for (integer i = 0; i <= Math.floor( emailBean.htmlBody.length()/131070); i++) {
            //         if((i+1)*131070 <  emailBean.htmlBody.length()){
            //             splitHtmlbody.add( emailBean.htmlBody.subString(i*131070, (i+1)*131070));
            //         }
            //         if((i+1)*131070 >  emailBean.htmlBody.length()){
            //             splitHtmlbody.add( emailBean.htmlBody.subString(i*131070,  emailBean.htmlBody.length()));
            //         } 
            //     }
            //     emailMessage.celsrm__Html_Body__c = splitHtmlbody[0];
            //     for (integer i = 1; i < splitHtmlbody.size(); i++) {
            //         if (i < 4) {
            //             emailMessage.put('celsrm__Html_Body_'+(i+1)+'__c', splitHtmlbody[i]);
            //         }
            //     }
            // } else {
            //     emailMessage.celsrm__Html_Body__c = emailBean.htmlBody;
            // }

            // // Store Text Body
            // String textbody = emailBean.htmlBody.stripHtmlTags();
            // System.debug('textbody>>>' + textbody);
            // List<String> splitTextbody=new List<String>();
            // system.debug('textbody.length() >>> ' + textbody.length());
            // if(textbody.length() > 131070) {
            //     for (integer i = 0; i <= Math.floor(textbody.length()/131070); i++) {
            //         if((i+1)*131070 < textbody.length()){
            //             splitTextbody.add(textbody.subString(i*131070, (i+1)*131070));
            //         }
            //         if((i+1)*131070 > textbody.length()){
            //             splitTextbody.add(textbody.subString(i*131070, textbody.length()));
            //         } 
            //     }
            //     for (integer i = 0; i < splitTextbody.size(); i++) {
            //         if (i < 4) {
            //             emailMessage.put('celsrm__Text_Body_'+(i+1)+'__c', splitTextbody[i]);
            //         }
            //     }
            // } else {
            //     emailMessage.celsrm__Text_Body_1__c = textbody;
            // }
            
            insert emailMessage;

            List<ContentDocumentLink> listOfContentLink = new List<ContentDocumentLink>();
            // << START - MM - FIN-9184 - [Dunning] Email message not generated for few auto dunning emails >>
            // Map<String, ContentWorkspaceDoc> conWorkDocMap = new Map<String, ContentWorkspaceDoc>();
            // << END - MM - FIN-9184 - [Dunning] Email message not generated for few auto dunning emails >>
            String shareWorkspaceId = '';
            List<ContentWorkspace> shareWorkspaceList = [SELECT Id FROM ContentWorkspace WHERE Name = 'AR Files' WITH USER_MODE LIMIT 1];
            if(shareWorkspaceList != null && shareWorkspaceList.size() > 0) {
                shareWorkspaceId = shareWorkspaceList.get(0).Id;
            }
            // << START - MM - FIN-9184 - [Dunning] Email message not generated for few auto dunning emails >>
            List<String> contentDocumentIds = new List<String>();
            // << END - MM - FIN-9184 - [Dunning] Email message not generated for few auto dunning emails >>
            for(ContentVersion conVersion : contentVersionList){
                ContentDocumentLink contentLink = new ContentDocumentLink();
                contentLink.ContentDocumentId = conVersion.ContentDocumentId;
                contentLink.LinkedEntityId = emailMessage.Id;
                contentLink.ShareType = 'V';
                listOfContentLink.add(contentLink);

                if(shareWorkspaceId != '' && shareWorkspaceId != null){
                    contentDocumentIds.add(conVersion.ContentDocumentId);
                    // << START - MM - FIN-9184 - [Dunning] Email message not generated for few auto dunning emails >>
                //     ContentWorkspaceDoc contentWorspaceDocObj = new ContentWorkspaceDoc();
                //     contentWorspaceDocObj.ContentDocumentId = conVersion.ContentDocumentId;
                //     contentWorspaceDocObj.ContentWorkspaceId = shareWorkspaceId;
                //     conWorkDocMap.put(contentWorspaceDocObj.ContentDocumentId, contentWorspaceDocObj);
                    // << END - MM - FIN-9184 - [Dunning] Email message not generated for few auto dunning emails >>
                }
                
            }
            if(!listOfContentLink.isEmpty()) {
                insert listOfContentLink;
                if(hasAttachment == true) {
                    EmailMessage em = new EmailMessage(Id = emailMessage.Id);
                    em.celsrm__HasAttachment__c = true;
                    update em;
                }
            }
            // << START - MM - FIN-9184 - [Dunning] Email message not generated for few auto dunning emails >>
            if (contentDocumentIds.size() > 0) {
                insertContentWorkspaceDoc(contentDocumentIds, shareWorkspaceId, emailMessage.Id);
            }
            // << END - MM - FIN-9184 - [Dunning] Email message not generated for few auto dunning emails >>
            // return returnMap;
        } catch (Exception e) {
            System.debug('error: ' + e.getMessage());
            throw e;
            // if (retryCount > 2) {
            //     System.debug('error: ' + e.getMessage());
            //     throw e;
            // } else {
            //     // we will try 3 times
            //     Integer randomNumber = Math.abs(Crypto.getRandomInteger()) % 200 + 1;
            //     System.sleep(randomNumber * 1000);
            //     retryCount = retryCount + 1;
            //     System.debug('Send email process failed, retry count ' + retryCount);
            //     return sendEmailAPI(toAddress, ccAddress, bccAddress, subject, body, retryCount);
            // }
        }
    }

    // << START - MM - FIN-9184 - [Dunning] Email message not generated for few auto dunning emails >>
    //-- Start | FIN-8312 | Changed By Dilshad | 16-Sep-2025 --//
    private static void insertContentWorkspaceDoc(List<String> documentIds, String contentWorkspaceId, String emailMessageId) {
        
        system.debug('Attempting to insert ContentWorkspaceDocs');
        List<ContentWorkspaceDoc> contenctWorkspaceDocList = new List<ContentWorkspaceDoc> ();
        for (ContentWorkspaceDoc ContentWorkspaceDocObj : [SELECT Id , ContentDocumentId FROM ContentWorkspaceDoc WHERE ContentDocumentId IN :documentIds AND ContentWorkspaceId = :contentWorkspaceId]) {
            Integer documentIdsIndex = documentIds.indexOf(ContentWorkspaceDocObj.ContentDocumentId);
            if(documentIdsIndex > -1){
                documentIds.remove(documentIdsIndex);
            }
        }
        for (String contentDocumentId : documentIds) {
            ContentWorkspaceDoc contentWorspaceDocObj = new ContentWorkspaceDoc();
            contentWorspaceDocObj.ContentDocumentId = contentDocumentId;
            contentWorspaceDocObj.ContentWorkspaceId = contentWorkspaceId;
            contenctWorkspaceDocList.add(contentWorspaceDocObj);
        }
        try {
            if (contenctWorkspaceDocList.size() > 0) {
                upsert contenctWorkspaceDocList;
            }
        } catch(Exception e) {
            system.debug('Error in insertContentWorkspaceDoc:'+e);
            reInsertContentWorkspaceDoc(documentIds, contentWorkspaceId, emailMessageId);
        }
    }

    // @future(callout=true)
    private static void reInsertContentWorkspaceDoc(List<String> documentIds, String contentWorkspaceId, String emailMessageId) {
        List<ContentWorkspaceDoc> contenctWorkspaceDocList = new List<ContentWorkspaceDoc> ();
        for (ContentWorkspaceDoc contentWorkspaceDocObj : [SELECT Id , ContentDocumentId FROM ContentWorkspaceDoc WHERE ContentDocumentId IN :documentIds AND ContentWorkspaceId = :contentWorkspaceId]) {
            Integer documentIdsIndex = documentIds.indexOf(contentWorkspaceDocObj.ContentDocumentId);
            if(documentIdsIndex > -1){
                documentIds.remove(documentIdsIndex);
            }
        }
        for (String contentDocumentId : documentIds) {
            ContentWorkspaceDoc contentWorspaceDocObj = new ContentWorkspaceDoc();
            contentWorspaceDocObj.ContentDocumentId = contentDocumentId;
            contentWorspaceDocObj.ContentWorkspaceId = contentWorkspaceId;
            contenctWorkspaceDocList.add(contentWorspaceDocObj);
        }
        try {
            system.debug('Attempt-1 to re-insert ContentWorkspaceDocs');
            upsert contenctWorkspaceDocList;
        } catch(Exception ex1) {
            system.debug('Error in attempt-1 inserting ContentWorkspaceDocs:' + ex1);
            try {
                system.debug('Attempt-2 to re-insert ContentWorkspaceDocs');
                upsert contenctWorkspaceDocList;
            } catch (Exception ex2) {
                system.debug('Error in attempt-2 inserting ContentWorkspaceDocs:' + ex2);
                try {
                    system.debug('Attempt-3 to re-insert ContentWorkspaceDocs');
                    upsert contenctWorkspaceDocList;
                } catch (Exception ex3) {
                    system.debug('Error in attempt-3 inserting ContentWorkspaceDocs:' + ex3);
                    try {
                        system.debug('Attempt-4 to re-insert ContentWorkspaceDocs');
                        upsert contenctWorkspaceDocList;
                    } catch (Exception ex4) {
                        system.debug('Error in attempt-4 inserting ContentWorkspaceDocs:' + ex4);
                        try {
                            system.debug('Attempt-5 to re-insert ContentWorkspaceDocs');
                            upsert contenctWorkspaceDocList;
                        } catch (Exception ex5) {
                            system.debug('Error in attempt-5 inserting ContentWorkspaceDocs:' + ex5);
                            try {
                                system.debug('Attempt-6 to re-insert ContentWorkspaceDocs');
                                upsert contenctWorkspaceDocList;
                            } catch (Exception ex6) {
                                system.debug('Attempt-6 to re-insert ContentWorkspaceDocs:' + ex6);
                                try {
                                    system.debug('Attempt-7 to re-insert ContentWorkspaceDocs');
                                    upsert contenctWorkspaceDocList;
                                } catch (Exception ex7) {
                                    system.debug('Attempt-7 to re-insert ContentWorkspaceDocs:' + ex7);
                                    try {
                                        system.debug('Attempt-8 to re-insert ContentWorkspaceDocs');
                                        upsert contenctWorkspaceDocList;
                                    } catch (Exception ex8) {
                                        system.debug('Attempt-8 to re-insert ContentWorkspaceDocs:' + ex8);
                                        try {
                                            system.debug('Attempt-9 to re-insert ContentWorkspaceDocs');
                                            upsert contenctWorkspaceDocList;
                                        } catch (Exception ex9) {
                                            system.debug('Attempt-9 to re-insert ContentWorkspaceDocs:' + ex9);
                                            try {
                                                system.debug('finale Attempt to re-insert ContentWorkspaceDocs');
                                                upsert contenctWorkspaceDocList;
                                            } catch (Exception ex10) {
                                                system.debug('The final attempt failed inserting ContentWorkspaceDocs:' + ex10);
                                                // throw new celsrm.CustomException('The final attempt failed inserting ContentWorkspaceDocs: '+ex6.getMessage());
                                                //--will capture log here in custom object--//
                                                EmailMessage em = new EmailMessage(Id = emailMessageId);
                                                em.Content_Workspace_Doc_Insert_Error__c = 'The final attempt failed inserting ContentWorkspaceDocs:' + ex10.getMessage() + '.\n' + 'DocumentIds: ' + String.join(documentIds, ', ');
                                                update em;
                                            }  
                                        }
                                    }
                                }
                            }                  
                        }
                    }
                }
            }
        }
    }
    //-- End | FIN-8312 | Changed By Dilshad | 16-Sep-2025 --//
    // << END - MM - FIN-9184 - [Dunning] Email message not generated for few auto dunning emails >>
}
// << END - MM - FIN-9047 - [Collections] Use SendGrid to send outbound emails >>