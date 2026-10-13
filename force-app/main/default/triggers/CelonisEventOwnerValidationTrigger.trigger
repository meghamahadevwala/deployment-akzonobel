trigger CelonisEventOwnerValidationTrigger on celsrm__Celonis_Event__c (before update) {
    
    // Filter only Promise to Pay records
    List<celsrm__Celonis_Event__c> promiseToPayRecords = new List<celsrm__Celonis_Event__c>();
    Map<Id, celsrm__Celonis_Event__c> promiseToPayOldMap = new Map<Id, celsrm__Celonis_Event__c>();
    
    for (celsrm__Celonis_Event__c event : Trigger.new) {
        // Only validate ownership for Promise to Pay events
        if (event.Name == 'Promise To Pay') {
            promiseToPayRecords.add(event);
            
            // Add to old map if it exists
            if (Trigger.oldMap.containsKey(event.Id)) {
                promiseToPayOldMap.put(event.Id, Trigger.oldMap.get(event.Id));
            }
        }
    }
    
    // Only call validator if there are Promise to Pay records to validate
    if (!promiseToPayRecords.isEmpty()) {
        UserFieldValidator.validateUserField(
            promiseToPayRecords, 
            promiseToPayOldMap,
            'OwnerId' 
        );
    }
}