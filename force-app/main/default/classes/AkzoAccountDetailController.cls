public with sharing class AkzoAccountDetailController {
    @AuraEnabled(cacheable=true)
    public static List<Account> getChildAccounts(Id recordId) {
        List<Account> childAccounts = [SELECT Id, ParentId from Account WHERE ParentId = :recordId];
        return childAccounts;
    }
}