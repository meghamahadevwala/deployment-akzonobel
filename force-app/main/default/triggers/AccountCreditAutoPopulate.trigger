trigger AccountCreditAutoPopulate on Account (before insert, before update) {
    AccountCreditAutoPopulateService.applyDefaults(Trigger.new);
}