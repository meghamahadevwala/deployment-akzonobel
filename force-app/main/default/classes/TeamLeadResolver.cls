/**
 * Resolves the "team lead" for a given account owner using the standard
 * Salesforce role/user hierarchy field: User.ManagerId.
 */
public with sharing class TeamLeadResolver {

    /**
     * Returns a map of OwnerId -> Team Lead User record (Id, Name, Email).
     * Bulk-safe: pass all owner Ids from the batch scope in one call.
     */
    public static Map<Id, User> resolveTeamLeads(Set<Id> ownerIds) {
        Map<Id, User> result = new Map<Id, User>();

        if (ownerIds == null || ownerIds.isEmpty()) {
            return result;
        }

        for (User u : [
            SELECT Id, ManagerId, Manager.Id, Manager.Name, Manager.Email
            FROM User
            WHERE Id IN :ownerIds
        ]) {
            if (u.Manager != null && u.Manager.Email != null) {
                result.put(u.Id, u.Manager);
            }
        }

        return result;
    }
}