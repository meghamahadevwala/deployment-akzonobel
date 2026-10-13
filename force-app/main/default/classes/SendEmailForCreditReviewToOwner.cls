public with sharing class SendEmailForCreditReviewToOwner {
    
    public SendEmailForCreditReviewToOwner() {}

    public class Request {
        @InvocableVariable(
            required=true
            label='Credit Review Id'
            description='Provide the Id of the credit review for which the email needs to be sent.'
        )
        public Id creditReviewId;

        @InvocableVariable(
            required=true
            label='Template Unique Name'
            description='Provide the unique name of the email template to be used for sending the email.'
        )
        public String templateUniqueName;

        @InvocableVariable(
            required=true
            label='From Address'
            description='Select the from address for the email.'
        )
        public String fromAddress;

        @InvocableVariable(
            required=true
            label='Default From Address'
            description='Select the default from address in case From Address is blank.'
        )
        public String defaultFromAddress;

    }

    public class Response {
        @InvocableVariable
        public Id creditReviewId;

        @InvocableVariable
        public String status;
    }

    @InvocableMethod(
        label='Send Email for Credit Review - Owner Notification'
        description='Sends an email for the specified credit review to the specified recipient using the specified email template.'
    )
    public static List<Response> run(List<Request> requests){
        List<Response> responses = new List<Response>();

        for(Request req : requests){
            Response res = new Response();
            res.creditReviewId = req.creditReviewId;
            try {
                
                celsrm__Credit_Review__c creditReview = [SELECT Id, Name, OwnerId, Owner.Email FROM celsrm__Credit_Review__c WHERE Id = :req.creditReviewId];
                
                EmailTemplate template = [SELECT Id, Name, DeveloperName, NamespacePrefix, FolderName FROM EmailTemplate WHERE DeveloperName = :req.templateUniqueName];
                Messaging.SingleEmailMessage message = Messaging.renderStoredEmailTemplate(template.Id, null, creditReview.Id);
                String htmlBody = message.getHtmlBody();
                String textBody = message.getPlainTextBody();
                String subject = message.getSubject();


                List<String> toAddresses = new List<String>();
                String fromEmail = null;
                if(req.fromAddress != null && req.fromAddress != '') {
                    fromEmail = req.fromAddress;
                } else {
                    fromEmail = req.defaultFromAddress;
                }
                Id orgWideId = [SELECT Id FROM OrgWideEmailAddress WHERE Address = :fromEmail].Id; 
                if(creditReview.OwnerId != null) {
                    toAddresses.add(creditReview.Owner.Email);
                }
                
                // START - Send Email using product class - sendgrid
                Map<Object, Object> inMap = new Map<Object, Object>();
                Map<Object, Object>  composeEmail = new Map<Object, Object>();
                composeEmail.put('to', toAddresses);
                composeEmail.put('from', orgWideId);
                composeEmail.put('cc',null);
                composeEmail.put('bcc',null);
                composeEmail.put('attachment',null);
                composeEmail.put('subject', subject);
                composeEmail.put('body',htmlBody);
                composeEmail.put('textbody',textBody);
                inMap.put('Id', req.creditReviewId);
                inMap.put('ComposeEmail',composeEmail);
                inMap.put('ContactMethod', 'Email');
                GOGCustomEmailSend sendEmailObj = new GOGCustomEmailSend();
                if(!Test.isRunningTest()) {
                    inMap = sendEmailObj.invoke('', inMap);
                }
                // END - Send Email using product class - sendgrid
                res.status = 'Success';

            } catch(Exception e) {
                res.status = 'Failed: ' + e.getMessage();
            }

            responses.add(res);
        }

        return responses;
    }
}