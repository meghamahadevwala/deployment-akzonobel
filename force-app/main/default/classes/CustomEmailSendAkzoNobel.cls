// << START - HP - FIN-9810 - [AkzoNobel] My Emails -> Send Email using custom apex class >>
global with sharing class CustomEmailSendAkzoNobel implements celsrm.SendEmailCustomLogicInterface {
    global Map<String, Object> invoke(celsrm.GOGEmailMapper.SendEmailBean emailBean){
        Map<String, Object> returnMap = new Map<String, Object>();
        System.debug('Tesing>>>>>');
        System.debug('emailBean>>>>>' + emailBean);
        String messageId;
        // << START - MM - FIN-9136 - [Send Email] Revert custom class changes >>
        String attachmentobjJson = JSON.serialize(emailBean.attachment);
        // GOGCustomEmailSendAkzoNobel.sendEmailAPI(emailBean.owea, emailBean.parentId ,emailBean.to, emailBean.cc, null, emailBean.subject, emailBean.htmlBody, emailBean.plainTextBody, attachmentobjJson);
        // << START - MM - FIN-9698 - [AkzoNobel] [Instant Auto Dunning] Email Not sent | Use queueable instead of future method for sending email >>
        // System.enqueueJob(
        //     new GOGCustomEmailSendAkzoNobel(
        //         emailBean.owea,
        //         emailBean.parentId,
        //         emailBean.to,
        //         emailBean.cc,
        //         null,
        //         emailBean.subject,
        //         emailBean.htmlBody,
        //         emailBean.plainTextBody,
        //         attachmentobjJson
        //     )
        // );
        GOGCustomEmailSendAkzoNobel.sendEmailAPI(
                emailBean.owea,
                emailBean.parentId,
                emailBean.to,
                emailBean.cc,
                null,
                emailBean.subject,
                emailBean.htmlBody,
                emailBean.plainTextBody,
                attachmentobjJson
            );
        // << END - MM - FIN-9698 - [AkzoNobel] [Instant Auto Dunning] Email Not sent | Use queueable instead of future method for sending email >>

        // << END - MM - FIN-9136 - [Send Email] Revert custom class changes >>
        // if(messageId != null){
        //     Map<String, Object> emailMessageFields = new Map<String, Object>();
        //     emailMessageFields.put('Postmark_Message_Id__c', messageId);
        //     returnMap.put('emailMessageFields', emailMessageFields);
        // }
        returnMap.put('success', true);

        return returnMap;
    }
}
// << END - HP - FIN-9810 - [AkzoNobel] My Emails -> Send Email using custom apex class >>