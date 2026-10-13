/* 
   Purpose: This class is used to create contentversion for attachment and submit the send statement request.
   Author: Ravi Khanpara
   Date: 03-Apr-2025
*/
public with sharing class AIActionSendStatementQueueable implements Queueable, Database.AllowsCallouts{

    Map<Object,Object> inMap = new Map<Object,Object>();

    public AIActionSendStatementQueueable(Map<Object,Object> inMap) {
        this.inMap = inMap;
    }
    public void execute(QueueableContext context) {
        if(inMap.get('StatementFormat') == 'Pdf'){
            SendStatementAttachmentformation attachmentInfo = new SendStatementAttachmentformation();
            inMap = attachmentInfo.invoke('Send Statement', inMap);
        } else if (inMap.get('StatementFormat') == 'Excel'){
            SendStatementAttachmentformation attachmentInfo = new SendStatementAttachmentformation();
            inMap = attachmentInfo.generateExcelStatementForSSAgent(inMap);
            
        }
        //-- Starts | Execute send Statement --//
        SendStatementActionController.onSubmitSendStatement(inMap);
        //-- Ends | Execute send Statement --//
    }
}