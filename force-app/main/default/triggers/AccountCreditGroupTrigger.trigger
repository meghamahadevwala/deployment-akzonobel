trigger AccountCreditGroupTrigger on Account (before insert, before update) {
    AccountCreditGroupService.applyCreditConfiguration(Trigger.new, Trigger.oldMap);
}