public class UserFieldValidator {

    // Roles that CANNOT change ownership at all
    private static final Set<String> BLOCKED_ROLES = new Set<String>{
        'Credit & Collection Analyst'
    };

    // Roles that are restricted to their own region
    private static final Set<String> REGIONAL_ROLES = new Set<String>{
        'RDPL',
        'Team Lead',
        'Credit Manager'
    };

    // Roles that can assign to any region
    private static final Set<String> UNRESTRICTED_ROLES = new Set<String>{
        'CEO',
        'CFO',
        'VP Treasurer',
        'Director - Credit & Collections',
        'AR Manager',
        'Credit & Collections Manager (Central Team)',
        'Technical Support'
    };

    // Role hierarchy levels (higher number = higher authority)
    private static final Map<String, Integer> ROLE_HIERARCHY = new Map<String, Integer>{
        'CEO' => 100,
        'CFO' => 100,
        'Technical Support' => 100,
        'VP Treasurer' => 90,
        'Director - Credit & Collections' => 80,
        'AR Manager' => 70,
        'Credit & Collections Manager (Central Team)' => 70,
        'Credit Manager' => 60,
        'RDPL' => 50,
        'Team Lead' => 40,
        'Credit & Collection Analyst' => 10
    };

    // Cache for the current user's role
    private static String currentUserRoleName;

    /**
     * MÉTODO GENÉRICO - Funciona con cualquier objeto y campo
     * @param newRecords - Lista de registros nuevos (puede ser Account, Dispute__c, etc.)
     * @param oldRecordsMap - Map de registros antiguos
     * @param userFieldName - Nombre del campo a validar (ej: 'OwnerId', 'Owner__c', 'Assigned_User__c')
     */
    public static void validateUserField(
        List<SObject> newRecords, 
        Map<Id, SObject> oldRecordsMap,
        String userFieldName
    ) {
        // Get current user's role information
        String currentUserRole = getCurrentUserRoleName();

        // Check if current user is BLOCKED from ANY changes
        if (isUserBlocked()) {
            for (SObject record : newRecords) {
                Boolean fieldChanged = hasFieldChanged(record, oldRecordsMap, userFieldName);
                
                if (fieldChanged) {
                    record.addError(userFieldName,
                        'You do not have permission to change ' + userFieldName + '. ' +
                        'Your role (' + currentUserRole + ') is not authorized to reassign records.'
                    );
                }
            }
            return;
        }

        // Check if user has regional restrictions
        Boolean isRestricted = isRegionallyRestricted();

        if (!isRestricted) {
            // Unrestricted users still need hierarchy validation
            validateHierarchy(newRecords, oldRecordsMap, currentUserRole, userFieldName);
            return;
        }

        // Collect all user field changes
        Set<Id> newUserIds = new Set<Id>();
        
        for (SObject record : newRecords) {
            if (hasFieldChanged(record, oldRecordsMap, userFieldName)) {
                Id userId = (Id)record.get(userFieldName);
                if (userId != null) {
                    newUserIds.add(userId);
                }
            }
        }

        if (newUserIds.isEmpty()) {
            return;
        }

        // Get regions and hierarchy info for validation
        Map<Id, String> userRegions = getUserRegions(newUserIds);
        Map<Id, String> userRoles = getUserRoles(newUserIds);
        String currentUserRegion = getCurrentUserRegion();
        Integer currentUserLevel = getRoleHierarchyLevel(currentUserRole);

        // Validate each change against regional restrictions and hierarchy
        for (SObject record : newRecords) {
            if (hasFieldChanged(record, oldRecordsMap, userFieldName)) {
                Id newUserId = (Id)record.get(userFieldName);
                String newUserRegion = userRegions.get(newUserId);
                String newUserRole = userRoles.get(newUserId);
                Integer newUserLevel = getRoleHierarchyLevel(newUserRole);

                // Validate region match
                if (String.isNotBlank(newUserRegion) &&
                    String.isNotBlank(currentUserRegion) &&
                    newUserRegion != currentUserRegion) {
                    
                    record.addError(userFieldName,
                        'You cannot assign this record to users from the ' + newUserRegion + ' region. ' +
                        'You can only assign records to members of your region (' + currentUserRegion + ').'
                    );
                }

                // Validate hierarchy
                if (newUserLevel > currentUserLevel) {
                    record.addError(userFieldName,
                        'You cannot assign records to users with higher authority. ' +
                        'The target user\'s role (' + newUserRole + ') is at a higher level than yours (' + currentUserRole + ').'
                    );
                }
            }
        }
    }

    /**
     * Helper para verificar si un campo cambió
     */
    private static Boolean hasFieldChanged(SObject record, Map<Id, SObject> oldMap, String fieldName) {
        if (oldMap == null) {
            return true; // Es insert, consideramos que "cambió"
        }
        
        SObject oldRecord = oldMap.get(record.Id);
        if (oldRecord == null) {
            return true;
        }
        
        return record.get(fieldName) != oldRecord.get(fieldName);
    }

    /**
     * Validates hierarchy for unrestricted users
     */
    private static void validateHierarchy(
        List<SObject> newRecords, 
        Map<Id, SObject> oldRecordsMap, 
        String currentUserRole,
        String userFieldName
    ) {
        Set<Id> newUserIds = new Set<Id>();
        
        for (SObject record : newRecords) {
            if (hasFieldChanged(record, oldRecordsMap, userFieldName)) {
                Id userId = (Id)record.get(userFieldName);
                if (userId != null) {
                    newUserIds.add(userId);
                }
            }
        }

        if (newUserIds.isEmpty()) {
            return;
        }

        Map<Id, String> userRoles = getUserRoles(newUserIds);
        Integer currentUserLevel = getRoleHierarchyLevel(currentUserRole);

        for (SObject record : newRecords) {
            if (hasFieldChanged(record, oldRecordsMap, userFieldName)) {
                Id newUserId = (Id)record.get(userFieldName);
                String newUserRole = userRoles.get(newUserId);
                Integer newUserLevel = getRoleHierarchyLevel(newUserRole);

                if (newUserLevel > currentUserLevel) {
                    record.addError(userFieldName,
                        'You cannot assign records to users with higher authority. ' +
                        'The target user\'s role (' + newUserRole + ') is at a higher level than yours (' + currentUserRole + ').'
                    );
                }
            }
        }
    }

    /**
     * Gets the hierarchy level for a role
     */
    private static Integer getRoleHierarchyLevel(String roleName) {
        if (String.isBlank(roleName)) {
            return 0;
        }

        // Check if role name contains any of the defined roles
        for (String hierarchyRole : ROLE_HIERARCHY.keySet()) {
            if (roleName.contains(hierarchyRole)) {
                return ROLE_HIERARCHY.get(hierarchyRole);
            }
        }

        // Default to lowest level if not found
        return 0;
    }

    /**
     * Gets the roles for multiple users
     */
    private static Map<Id, String> getUserRoles(Set<Id> userIds) {
        Map<Id, String> roles = new Map<Id, String>();

        if (userIds.isEmpty()) {
            return roles;
        }

        for (User u : [
            SELECT Id, UserRole.Name
            FROM User
            WHERE Id IN :userIds
        ]) {
            roles.put(u.Id, u.UserRole != null ? u.UserRole.Name : '');
        }

        return roles;
    }

    /**
     * Checks if the current user is BLOCKED from making ownership changes
     */
    private static Boolean isUserBlocked() {
        String roleName = getCurrentUserRoleName();

        if (String.isBlank(roleName)) {
            return true;
        }

        for (String blockedRole : BLOCKED_ROLES) {
            if (roleName.contains(blockedRole)) {
                return true;
            }
        }

        return false;
    }

    /**
     * Checks whether the current user has regional restrictions
     */
    private static Boolean isRegionallyRestricted() {
        String roleName = getCurrentUserRoleName();

        if (String.isBlank(roleName)) {
            return false;
        }

        // First check UNRESTRICTED roles
        for (String unrestrictedRole : UNRESTRICTED_ROLES) {
            if (roleName.contains(unrestrictedRole)) {
                return false;
            }
        }

        // Then check REGIONAL roles
        for (String regionalRole : REGIONAL_ROLES) {
            if (roleName.contains(regionalRole)) {
                return true;
            }
        }

        // If not in either list, restrict them (safety default)
        return true;
    }

    /**
     * Gets the current user's role name (cached)
     */
    private static String getCurrentUserRoleName() {
        if (currentUserRoleName == null) {
            List<User> currentUser = [
                SELECT UserRole.Name
                FROM User
                WHERE Id = :UserInfo.getUserId()
                LIMIT 1
            ];

            if (!currentUser.isEmpty() && currentUser[0].UserRole != null) {
                currentUserRoleName = currentUser[0].UserRole.Name;
            } else {
                currentUserRoleName = '';
            }
        }
        return currentUserRoleName;
    }

    /**
     * Gets the current user's region
     */
    private static String getCurrentUserRegion() {
        String roleName = getCurrentUserRoleName();
        return extractRegionFromRole(roleName);
    }

    /**
     * Gets the regions for multiple users
     */
    private static Map<Id, String> getUserRegions(Set<Id> userIds) {
        Map<Id, String> regions = new Map<Id, String>();

        if (userIds.isEmpty()) {
            return regions;
        }

        for (User u : [
            SELECT Id, UserRole.Name
            FROM User
            WHERE Id IN :userIds
        ]) {
            String region = extractRegionFromRole(u.UserRole != null ? u.UserRole.Name : null);
            regions.put(u.Id, region);
        }

        return regions;
    }

    /**
     * Extracts the region from the role name
     */
    private static String extractRegionFromRole(String roleName) {
        if (String.isBlank(roleName)) {
            return null;
        }

        // First try to extract from parentheses: "Role Name (Region)"
        if (roleName.contains('(') && roleName.contains(')')) {
            Integer startIndex = roleName.indexOf('(') + 1;
            Integer endIndex = roleName.indexOf(')');
            return roleName.substring(startIndex, endIndex).trim();
        }

        // Fallback: check for region keywords
        if (roleName.contains('EMEA')) return 'EMEA';
        if (roleName.contains('North America')) return 'North America';
        if (roleName.contains('North Asia')) return 'North Asia';
        if (roleName.contains('South Asia & Oceania')) return 'South Asia & Oceania';
        if (roleName.contains('South America')) return 'South America';

        return null;
    }
}