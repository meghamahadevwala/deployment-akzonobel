public with sharing class SendEmailForCreditReviewAssignTo {
    
    public SendEmailForCreditReviewAssignTo() {}

    public class Request {
        @InvocableVariable(
            required=true
            label='Credit Limit Workflow Id'
            description='Provide the Id of the credit limit workflow for which the email needs to be sent.'
        )
        public Id creditLimitApprovalDetailId;

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
        public Id creditLimitApprovalDetailId;

        @InvocableVariable
        public String status;
    }

    @InvocableMethod(
        label='Send Email for Credit Review - Assignment Notification'
        description='Sends an email for the specified credit review to the specified recipient using the specified email template.'
    )
    public static List<Response> run(List<Request> requests){
        List<Response> responses = new List<Response>();

        for(Request req : requests){
            Response res = new Response();
            res.creditLimitApprovalDetailId = req.creditLimitApprovalDetailId;
            try {
                
                celsrm__Credit_Limit_Approval_Detail__c creditLimitApprovalDetail = [SELECT Id, celsrm__Credit_Review__c, celsrm__User_Master__c, celsrm__Queue__c, celsrm__User_Master__r.celsrm__Email__c, celsrm__User_Master__r.celsrm__Is_External_User__c FROM celsrm__Credit_Limit_Approval_Detail__c WHERE Id = :req.creditLimitApprovalDetailId];
                celsrm__Credit_Review__c creditReview = [SELECT Id, Name FROM celsrm__Credit_Review__c WHERE Id = :creditLimitApprovalDetail.celsrm__Credit_Review__c];
                
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
                if(creditLimitApprovalDetail.celsrm__User_Master__c != null) {
                    toAddresses.add(creditLimitApprovalDetail.celsrm__User_Master__r.celsrm__Email__c);
                    if(creditLimitApprovalDetail.celsrm__User_Master__r.celsrm__Is_External_User__c == true) {
                        htmlBody = enrichHtmlBodyWithUserMasterIdAndDetailId(htmlBody, creditLimitApprovalDetail.celsrm__User_Master__c, creditLimitApprovalDetail.Id);
                    }
                } else if(creditLimitApprovalDetail.celsrm__Queue__c != null) {
                    Set<Id> userIds = getAllUsersInQueue(creditLimitApprovalDetail.celsrm__Queue__c);
                    List<User> users = [SELECT Id, email FROM User WHERE Id IN :userIds];
                    for(User user : users) {
                        toAddresses.add(user.Email);
                    }
                    // Get queeu anme
                    Group queue = [SELECT Id, Name FROM Group WHERE Id = :creditLimitApprovalDetail.celsrm__Queue__c];
                    String queueName = queue.Name;
                    htmlBody = htmlBody.replace('{approvalDetail.queuename}', queueName);
                    textBody = textBody.replace('{approvalDetail.queuename}', queueName);
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
                inMap.put('Id', creditReview.Id);
                inMap.put('ComposeEmail',composeEmail);
                inMap.put('ContactMethod', 'Email');
                if(!Test.isRunningTest()) {
                    GOGCustomEmailSend sendEmailObj = new GOGCustomEmailSend();
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

    private static String enrichHtmlBodyWithUserMasterIdAndDetailId(String htmlBody, Id userMasterId, Id workflowDetailId) {
        if (String.isBlank(htmlBody) || userMasterId == null || workflowDetailId == null) {
            return htmlBody;
        }
        String output = htmlBody;
        String hiddenInputs = '<input type="hidden" name="workflowDetailId" value="' + String.valueOf(workflowDetailId) + '" />' + '<input type="hidden" name="userMasterId" value="' + String.valueOf(userMasterId) + '" />';
        return output.replace('</form>', hiddenInputs + '</form>');
    }

    // Get all users in a queue, including nested groups at any depth
    private static Set<Id> getAllUsersInQueue(Id queueId) {
        Set<Id> allUserIds = new Set<Id>();
        Set<Id> groupsToProcess = new Set<Id>{ queueId };
        Set<Id> processedGroups = new Set<Id>();

        while (!groupsToProcess.isEmpty()) {
            Set<Id> nextGroups = new Set<Id>();
            Set<Id> potentialGroups = new Set<Id>();

            // Get all members of the current groups
            for (GroupMember gm : [
                SELECT UserOrGroupId
                FROM GroupMember
                WHERE GroupId IN :groupsToProcess
            ]) {
                potentialGroups.add(gm.UserOrGroupId);
            }

            // Check which are groups
            Map<Id, Group> groupMap = new Map<Id, Group>([
                SELECT Id, Type FROM Group WHERE Id IN :potentialGroups
            ]);

            for (Id memberId : potentialGroups) {
                if (groupMap.containsKey(memberId) && (groupMap.get(memberId).Type == 'Queue' || groupMap.get(memberId).Type == 'Regular')) {
                    // It's a group, add to next iteration if not processed
                    if (!processedGroups.contains(memberId)) {
                        nextGroups.add(memberId);
                    }
                } else {
                    // It's a user, add to user set
                    allUserIds.add(memberId);
                }
            }

            processedGroups.addAll(groupsToProcess);
            groupsToProcess = nextGroups;
        }

        return allUserIds;
    }
}