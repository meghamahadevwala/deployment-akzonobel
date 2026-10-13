public class AccountMasterTriggerHandler {
    // Static variable to prevent recursion
    public static Boolean isRecursionFlagSet = false;

    // Future method for updating parent accounts
    @future
    public static void updateParentAccounts(Set<Id> parentIds) {
        // Query and update parent accounts asynchronously to prevent recursion
        Map<Id, Integer> parentChildCountMap = new Map<Id, Integer>();
        
        // Aggregate query to count child records
        List<AggregateResult> childCounts = [
            SELECT ParentId, COUNT(Id) childCount 
            FROM Account 
            WHERE ParentId IN :parentIds 
            GROUP BY ParentId
        ];
        
        // Populate the map with the child count for each parent
        for (AggregateResult ar : childCounts) {
            Id parentId = (Id) ar.get('ParentId');
            Integer count = (Integer) ar.get('childCount');
            parentChildCountMap.put(parentId, count);
        }
        
        // Prepare parent accounts to update
        List<Account> accountsToUpdate = new List<Account>();
        for (Id parentId : parentIds) {
            Account parent = new Account(Id = parentId);
            parent.Is_Parent_Account__c = parentChildCountMap.containsKey(parentId) && parentChildCountMap.get(parentId) > 0;
            accountsToUpdate.add(parent);
        }
        
        // Perform the update on parent accounts
        if (!accountsToUpdate.isEmpty()) {
            update accountsToUpdate;
        }
    }
}