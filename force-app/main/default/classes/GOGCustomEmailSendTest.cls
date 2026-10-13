@isTest
public with sharing class GOGCustomEmailSendTest {
    
    public static testMethod void test() {

    Account acc = DataGenerator.insertAccount();
    List<Contact> cont = DataGenerator.insertContact(acc, 2);
    celsrm__Transaction__c trans = DataGenerator.insertTransaction(acc);
    List<celsrm__Dispute__c> dispute = DataGenerator.insertDispute(trans, acc, 2);
    celsrm__User_Preference__c userPref = DataGenerator.insertUserPreference(null);

    Map<Object,Object> inMap = new Map<Object,Object>();
    List<Map<Object,Object>> objMaplist = new List<Map<Object,Object>>();
    Map<Object,Object> tempComposeEmail = new Map<Object,Object>();
    // List<String> slist1 = new List<String>{cont[0].Id, cont[1].Id};
    List<Object> ObjList = new List<Object>();
    Map<Object,Object> objMap = new Map<Object,Object>();
    objMap.put('Id',trans.Id);
    objMap.put('isSelected', true);
    objList.add(objMap);

    List<Object> ObjList1 = new List<Object>();
    Map<String,Object> objMap1 = new Map<String,Object>();
    objMap1.put('value','value');
    objMap1.put('isSelected', true);
    objList1.add(objMap1);


    tempComposeEmail.put('from', acc.Id);
    tempComposeEmail.put('to', objList1);
    tempComposeEmail.put('subject', 'subject@mail.com');
    tempComposeEmail.put('cc', objList1);
    tempComposeEmail.put('bcc', objList1);
    tempComposeEmail.put('body', 'body{Promise.Summary}'); 


    // for attachment
    Map<Object,Object> temp1 = new Map<Object,Object>();
    temp1.put('Title', 'Title, BillingStatement ,Title');
    objMaplist.add(temp1);
    tempComposeEmail.put('attachment', objMaplist);
    inMap.put('Id', acc.Id);
    inMap.put('notebody', 'notebody');
    inMap.put('ContactMehods', 'Email');
    inMap.put('ComposeEmail', tempComposeEmail);
    inMap.put('AttachCheckBox', true);
    inMap.put('SummaryFields', 'Name,celsrm__Balance__c,celsrm__base_balance__c,celsrm__Flag__c,celsrm__Promised_Amount__c');
    inMap.put('ggScreenName', 'WCMPromisToPayScreenEmailAction');
    inMap.put('TransactionList', ObjList);
    inMap.put('screenName', 'Promise To Pay');
    inMap.put('ContactMethod', 'Email');
    GOGCustomEmailSend mail = new GOGCustomEmailSend();

    try{ 
        mail.invoke('functionName', inMap);
    } catch(Exception e){
       system.debug('Exception caused>>>>'+e.getLineNumber()+'>>>>>>>>>' + e.getMessage() );
    }

    try{
        ObjList = new List<Object>();
        objMap = new Map<Object,Object>();
        objMap.put('Id', dispute[0].Id);
        ObjList.add(objMap);
        objMap.put('Id', dispute[1].Id);
        ObjList.add(objMap);

        tempComposeEmail.put('body', '{Disputes.summary}body'); 
        inMap.put('ComposeEmail', tempComposeEmail);
        inMap.put('SummaryFields', 'Name,celsrm__Balance__c,celsrm__Amount__c,celsrm__Account__c,celsrm__Latest_Note_Date__c');
        inMap.put('DisputeGrid', ObjList);
        inMap.put('screenName','Dispute');
        mail.invoke('functionName', inMap);
    } catch(Exception e){
       system.debug('Exception caused>>>>'+e.getLineNumber()+'>>>>>>>>>' + e.getMessage() );
    }

    try{
        tempComposeEmail.put('attachment', objMaplist);
        tempComposeEmail.put('body', null);
        tempComposeEmail.put('textbody', 'textbody');
        inMap.put('ComposeEmail', tempComposeEmail);
        inMap.put('screenName', 'Send Statement');
        inMap.put('ListViewObject', 'celsrm__Transaction__c');
        inMap.put('ListView', 'test');
        inMap.put('TransactionList_SortColumn', 'celsrm__Balance__c');
        inMap.put('TransactionList_SortOrder', 'ASC');

        mail.invoke('functionName1', inMap);
        inMap.put('ggScreenName', 'WCM__SendEmailReminderSC');
        inMap.put('ListViewObject', 'celsrm__Dispute__c');
        mail.invoke('functionName1', inMap);

    } catch(Exception e){
        system.debug('Exception caused>>>>'+e.getLineNumber()+'>>>>>>>>>' + e.getMessage() );
    }
    
    try{
        inMap.put('screenName', 'Send Statement');
        inMap.put('SummaryFields', 'Name,celsrm__Balance__c');
        mail.invoke('functionName2', inMap);
    } catch(Exception e){
        system.debug('Exception caused>>>>'+e.getLineNumber()+'>>>>>>>>>' + e.getMessage() );
    }

    try{
        inMap.put('ComposeEmail', null);
        mail.invoke('functionName3', inMap);
    } catch(Exception e){
        system.debug('Exception caused>>>>'+e.getLineNumber()+'>>>>>>>>>' + e.getMessage() );
    }

  //  EmailAddressSuggestion emailAdd = new EmailAddressSuggestion();
   // emailAdd.invoke('',inMap);
    }

    //-- FIN-9729 | Changed By Dilshad | 05-May-2026 | Start --//
    public static testMethod void testMergeGeneratedStatementAttachmentAddsPdfToComposeEmail() {
        Map<Object, Object> inMap = new Map<Object, Object>{
            'ContentIDSendStmt' => '068000000000001AAA',
            'fileName' => 'Billing Statement',
            'ComposeEmail' => new Map<Object, Object>{
                'attachment' => new List<Object>()
            }
        };

        Test.startTest();
        GOGCustomEmailSend.mergeGeneratedStatementAttachment(inMap);
        Test.stopTest();

        Map<Object, Object> composeEmail = (Map<Object, Object>)inMap.get('ComposeEmail');
        List<Object> attachments = (List<Object>)composeEmail.get('attachment');
        Map<Object, Object> attachment = (Map<Object, Object>)attachments[0];

        System.assertEquals(1, attachments.size(), 'The generated statement PDF should be added as an attachment.');
        System.assertEquals('068000000000001AAA', String.valueOf(attachment.get('Id')), 'The generated ContentVersion id should be stored on the attachment entry.');
        System.assertEquals('Billing Statement.pdf', String.valueOf(attachment.get('Title')), 'The generated attachment title should use the PDF file name.');
        System.assertEquals('PDF', String.valueOf(attachment.get('FileType')), 'The generated statement attachment should be marked as a PDF.');
    }

    public static testMethod void testMergeGeneratedStatementAttachmentReplacesExistingStatementReference() {
        List<Object> attachments = new List<Object>{
            new Map<Object, Object>{
                'Id' => '068OLD000000000AAA',
                'Title' => 'Billing Statement.pdf',
                'FileType' => 'PDF'
            }
        };
        Map<Object, Object> inMap = new Map<Object, Object>{
            'ContentIDSendStmt' => '068NEW000000000AAA',
            'fileName' => 'Billing Statement',
            'ComposeEmail' => new Map<Object, Object>{
                'attachment' => attachments
            }
        };

        Test.startTest();
        GOGCustomEmailSend.mergeGeneratedStatementAttachment(inMap);
        Test.stopTest();

        Map<Object, Object> composeEmail = (Map<Object, Object>)inMap.get('ComposeEmail');
        List<Object> mergedAttachments = (List<Object>)composeEmail.get('attachment');
        Map<Object, Object> mergedAttachment = (Map<Object, Object>)mergedAttachments[0];

        System.assertEquals(1, mergedAttachments.size(), 'The existing statement attachment entry should be replaced instead of duplicated.');
        System.assertEquals('068NEW000000000AAA', String.valueOf(mergedAttachment.get('Id')), 'The merged attachment should point at the latest generated ContentVersion.');
    }

    public static testMethod void testCleanupGeneratedStatementAttachmentIfUncheckedRemovesMergedAttachment() {
        List<Object> attachments = new List<Object>{
            new Map<Object, Object>{
                'Id' => '068000000000001AAA',
                'Title' => 'Billing Statement.pdf',
                'FileType' => 'PDF'
            },
            new Map<Object, Object>{
                'Id' => '068000000000002AAA',
                'Title' => 'Keep Me.pdf',
                'FileType' => 'PDF'
            }
        };
        Map<Object, Object> inMap = new Map<Object, Object>{
            'screenName' => 'Send Statement',
            'AttachCheckBox' => false,
            'ContentIDSendStmt' => '068000000000001AAA',
            'ContentDocID' => '069000000000001AAA',
            'ComposeEmail' => new Map<Object, Object>{
                'attachment' => attachments
            }
        };

        Test.startTest();
        GOGCustomEmailSend.cleanupGeneratedStatementAttachmentIfUnchecked(inMap);
        Test.stopTest();

        Map<Object, Object> composeEmail = (Map<Object, Object>)inMap.get('ComposeEmail');
        List<Object> remainingAttachments = (List<Object>)composeEmail.get('attachment');
        Map<Object, Object> remainingAttachment = (Map<Object, Object>)remainingAttachments[0];

        System.assertEquals(1, remainingAttachments.size(), 'Only the generated statement attachment should be removed.');
        System.assertEquals('068000000000002AAA', String.valueOf(remainingAttachment.get('Id')), 'Unrelated attachments should remain in ComposeEmail.');
        System.assertEquals(false, inMap.containsKey('ContentIDSendStmt'), 'The generated statement ContentVersion id should be cleared when attachments are unchecked.');
        System.assertEquals(false, inMap.containsKey('ContentDocID'), 'The generated statement ContentDocument id should be cleared when attachments are unchecked.');
    }
    //-- FIN-9729 | Changed By Dilshad | 05-May-2026 | End --//
}