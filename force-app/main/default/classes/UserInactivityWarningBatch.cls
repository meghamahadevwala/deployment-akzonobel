global class UserInactivityWarningBatch implements Schedulable {
    global void execute(SchedulableContext sc) {
        Integer deactivationThreshold = 90;
        Integer warningThreshold = 83; // 90 - 7 days
        
        Date warningCutoff = Date.today().addDays(-warningThreshold);
        Date deactivationCutoff = Date.today().addDays(-deactivationThreshold);
        
        // Users hitting the 7-day warning window today
        List<User> usersToWarn = [
            SELECT Id, Name, Email, LastLoginDate 
            FROM User 
            WHERE IsActive = true 
            AND LastLoginDate = :warningCutoff  // exact day match, runs daily
            AND Profile.Name NOT IN ('System Administrator') // exclude admins/integration users
        ];
        
        sendWarningEmails(usersToWarn);
        
        // Users actually past the threshold — deactivate
        List<User> usersToDeactivate = [
            SELECT Id FROM User 
            WHERE IsActive = true 
            AND LastLoginDate < :deactivationCutoff
            AND Profile.Name NOT IN ('System Administrator')
        ];
        
        if (!usersToDeactivate.isEmpty()) {
            for (User u : usersToDeactivate) {
                u.IsActive = false;
            }
            update usersToDeactivate;
        }
    }
    
    private void sendWarningEmails(List<User> users) {
        if (users.isEmpty()) return;
        
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        for (User u : users) {
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(new List<String>{u.Email});
            email.setSubject('Action Required: Your account will be deactivated in 7 days');
            email.setPlainTextBody(
                'Hi ' + u.Name + ',\n\n' +
                'Your Salesforce account has been inactive and is scheduled for deactivation in 7 days ' +
                'due to inactivity policy. If you own any Accounts, please migrate ownership to a colleague ' +
                'or contact your Credit & Collections Manager before this date to avoid orphaned records.\n\n' +
                'If you believe this is an error, please log in before the deactivation date or contact your admin.'
            );
            emails.add(email);
        }
        Messaging.sendEmail(emails);
    }
}