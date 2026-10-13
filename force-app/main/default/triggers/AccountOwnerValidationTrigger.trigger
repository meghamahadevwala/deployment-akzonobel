trigger AccountOwnerValidationTrigger on Account (before update) {

    List<Account> collectionAccounts = new List<Account>();
    Map<Id, Account> oldCollectionMap = new Map<Id, Account>();

    for (Account newAcc : Trigger.new) {

        if ('Collection'.equalsIgnoreCase(newAcc.celsrm__App_Name__c)) {
            collectionAccounts.add(newAcc);
            oldCollectionMap.put(newAcc.Id, Trigger.oldMap.get(newAcc.Id));
        }
    }

    if (!collectionAccounts.isEmpty()) {
        UserFieldValidator.validateUserField(
            collectionAccounts,
            oldCollectionMap,
            'OwnerId'
        );
    }
}