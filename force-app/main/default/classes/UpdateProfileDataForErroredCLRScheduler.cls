global class UpdateProfileDataForErroredCLRScheduler implements Schedulable {
    global void execute(SchedulableContext sc) {
        // UpdateProfileDataForErroredAccount batch = new UpdateProfileDataForErroredAccount();
        // Database.executeBatch(batch, 50);
        List<Account> accounts = [SELECT Id, Name, Sync_Profile_Data_In_Source_System_At__c, Sync_Profile_Data_Message__c FROM Account WHERE Sync_Profile_Data_Message__c LIKE '%Error:%' OR Sync_Profile_Data_Message__c LIKE '%Exception%' LIMIT 5000];
        if(accounts.size() > 0) {
            List<String> accIds = new List<String>();
            for(Account acc: accounts) {
                accIds.add(acc.Id);
            }
            if(accIds.size() > 0 && !Test.isRunningTest()){
                UpdateProfileDataInSourceSystemService.updateProfileDataInSAP(accIds);
            }
        }
    }
}