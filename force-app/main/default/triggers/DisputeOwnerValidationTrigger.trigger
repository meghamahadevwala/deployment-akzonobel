trigger DisputeOwnerValidationTrigger on celsrm__Dispute__c (before update) {
    UserFieldValidator.validateUserField(
        Trigger.new,
        Trigger.oldMap,
        'celsrm__Owner__c'
    );
}