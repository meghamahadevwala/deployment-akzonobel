public with sharing class DisputeUserMasterService {
    //-- Start | FIN-9672 | Changed by Ravi | 05 May 2026 --//
    public static final String INTERNAL_CATEGORY = 'Internal';
    public static final String EXTERNAL_CATEGORY = 'External';
    public static final String DEFAULT_LANGUAGE_FOLDER = 'English (United States)';
    public static final String INTERNAL_MASTER_PREFIX = 'USR:';
    public static final String EXTERNAL_MASTER_PREFIX = 'EXT:';

    public class ResolvedUserInfo {
        public Id userMasterId;
        public Id userId;
        public String email;
        public String name;
        public String category;
        public String language;
        public Id managerUserMasterId;
        public String managerEmail;
        public String managerName;

        public Boolean isExternal() {
            return category == DisputeUserMasterService.EXTERNAL_CATEGORY || (userId == null && !String.isBlank(email));
        }
    }

    public static String normalizeEmail(String emailAddress) {
        return String.isBlank(emailAddress) ? null : emailAddress.trim().toLowerCase();
    }

    public static String buildInternalMasterKey(Id userId) {
        return userId == null ? null : INTERNAL_MASTER_PREFIX + String.valueOf(userId);
    }

    public static String buildExternalMasterKey(String emailAddress) {
        String normalizedEmail = normalizeEmail(emailAddress);
        return normalizedEmail == null ? null : EXTERNAL_MASTER_PREFIX + normalizedEmail;
    }

    //-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
    public static Map<Id, celsrm__User_Master__c> getUserMastersById(Set<Id> masterIds) {
        Map<Id, celsrm__User_Master__c> mastersById = new Map<Id, celsrm__User_Master__c>();
    //-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
        if (masterIds == null || masterIds.isEmpty()) {
            return mastersById;
        }

        //-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
        for (celsrm__User_Master__c master : [
            SELECT Id, Name, celsrm__Master_Key__c, celsrm__User__c, celsrm__Email__c, celsrm__Is_External_User__c, celsrm__Language__c, celsrm__Is_Active__c,
                   celsrm__Manager__c, celsrm__Manager__r.Name, celsrm__Manager__r.celsrm__Email__c
            FROM celsrm__User_Master__c
            WHERE Id IN :masterIds
        ]) {
        //-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
            mastersById.put(master.Id, master);
        }
        return mastersById;
    }

    //-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
    public static Map<Id, celsrm__User_Master__c> getInternalMastersByUserIds(Set<Id> userIds) {
        Map<Id, celsrm__User_Master__c> mastersByUserId = new Map<Id, celsrm__User_Master__c>();
    //-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
        if (userIds == null || userIds.isEmpty()) {
            return mastersByUserId;
        }

        //-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
        for (celsrm__User_Master__c master : [
            SELECT Id, Name, celsrm__Master_Key__c, celsrm__User__c, celsrm__Email__c, celsrm__Is_External_User__c, celsrm__Language__c, celsrm__Is_Active__c,
                   celsrm__Manager__c, celsrm__Manager__r.Name, celsrm__Manager__r.celsrm__Email__c
            FROM celsrm__User_Master__c
            WHERE celsrm__User__c IN :userIds
        ]) {
            //-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
            //-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
            mastersByUserId.put(master.celsrm__User__c, master);
            //-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
        }
        return mastersByUserId;
    }

    //-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
    public static Map<String, celsrm__User_Master__c> getExternalMastersByEmail(Set<String> emailAddresses) {
        Map<String, celsrm__User_Master__c> mastersByEmail = new Map<String, celsrm__User_Master__c>();
    //-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
        if (emailAddresses == null || emailAddresses.isEmpty()) {
            return mastersByEmail;
        }

        Set<String> masterKeys = new Set<String>();
        for (String emailAddress : emailAddresses) {
            String masterKey = buildExternalMasterKey(emailAddress);
            if (masterKey != null) {
                masterKeys.add(masterKey);
            }
        }

        if (masterKeys.isEmpty()) {
            return mastersByEmail;
        }

        //-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
        for (celsrm__User_Master__c master : [
            SELECT Id, Name, celsrm__Master_Key__c, celsrm__User__c, celsrm__Email__c, celsrm__Is_External_User__c, celsrm__Language__c, celsrm__Is_Active__c,
                   celsrm__Manager__c, celsrm__Manager__r.Name, celsrm__Manager__r.celsrm__Email__c
            FROM celsrm__User_Master__c
            WHERE celsrm__Master_Key__c IN :masterKeys
        ]) {
            //-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
            //-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
            mastersByEmail.put(normalizeEmail(master.celsrm__Email__c), master);
            //-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
        }
        return mastersByEmail;
    }

    //-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
    private static void saveUserMasters(List<celsrm__User_Master__c> mastersToSave) {
    //-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
        if (mastersToSave == null || mastersToSave.isEmpty()) {
            return;
        }

        Set<String> masterKeys = new Set<String>();
        //-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
        for (celsrm__User_Master__c master : mastersToSave) {
            if (!String.isBlank(master.celsrm__Master_Key__c)) {
                masterKeys.add(master.celsrm__Master_Key__c);
        //-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
            }
        }

        Map<String, Id> existingIdsByKey = new Map<String, Id>();
        if (!masterKeys.isEmpty()) {
            //-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
            for (celsrm__User_Master__c existingMaster : [
                SELECT Id, celsrm__Master_Key__c
                FROM celsrm__User_Master__c
                WHERE celsrm__Master_Key__c IN :masterKeys
            ]) {
                //-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
                //-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
                existingIdsByKey.put(existingMaster.celsrm__Master_Key__c, existingMaster.Id);
                //-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
            }
        }

        //-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
        List<celsrm__User_Master__c> inserts = new List<celsrm__User_Master__c>();
        List<celsrm__User_Master__c> updates = new List<celsrm__User_Master__c>();
        for (celsrm__User_Master__c master : mastersToSave) {
            if (master.Id == null && !String.isBlank(master.celsrm__Master_Key__c) && existingIdsByKey.containsKey(master.celsrm__Master_Key__c)) {
                master.Id = existingIdsByKey.get(master.celsrm__Master_Key__c);
        //-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
            }

            if (master.Id == null) {
                inserts.add(master);
            } else {
                updates.add(master);
            }
        }

        if (!inserts.isEmpty()) {
            insert inserts;
        }
        if (!updates.isEmpty()) {
            update updates;
        }
    }

    // Keeps internal user masters in sync with User so name, email, active flag, language, and manager never drift.
    public static void syncInternalUsers(Set<Id> userIds) {
        if (userIds == null || userIds.isEmpty()) {
            return;
        }

        Map<Id, User> requestedUsers = queryUsersWithLanguage(userIds);
        if (requestedUsers.isEmpty()) {
            return;
        }

        Set<Id> allUserIds = new Set<Id>(requestedUsers.keySet());
        for (User userRecord : requestedUsers.values()) {
            if (userRecord.ManagerId != null) {
                allUserIds.add(userRecord.ManagerId);
            }
        }

        Set<Id> missingManagerIds = new Set<Id>(allUserIds);
        missingManagerIds.removeAll(requestedUsers.keySet());
        if (!missingManagerIds.isEmpty()) {
            requestedUsers.putAll(queryUsersWithLanguage(missingManagerIds));
        }

        //-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
        List<celsrm__User_Master__c> mastersToUpsert = new List<celsrm__User_Master__c>();
        //-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
        for (User userRecord : requestedUsers.values()) {
            //-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
            celsrm__User_Master__c master = new celsrm__User_Master__c();
            master.celsrm__Master_Key__c = buildInternalMasterKey(userRecord.Id);
            //-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
            master.Name = userRecord.Name;
            //-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
            master.celsrm__User__c = userRecord.Id;
            master.celsrm__Email__c = userRecord.Email;
            master.celsrm__Is_External_User__c = false;
            master.celsrm__Is_Active__c = userRecord.IsActive;
            master.celsrm__Language__c = String.valueOf(userRecord.get('LanguageLabel'));
            //-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
            mastersToUpsert.add(master);
        }

        if (!mastersToUpsert.isEmpty()) {
            saveUserMasters(mastersToUpsert);
        }

        //-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
        Map<Id, celsrm__User_Master__c> mastersByUserId = getInternalMastersByUserIds(allUserIds);
        List<celsrm__User_Master__c> managerUpdates = new List<celsrm__User_Master__c>();
        //-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
        for (User userRecord : requestedUsers.values()) {
            //-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
            celsrm__User_Master__c master = mastersByUserId.get(userRecord.Id);
            //-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
            if (master == null) {
                continue;
            }

            Id managerMasterId = null;
            if (userRecord.ManagerId != null && mastersByUserId.containsKey(userRecord.ManagerId)) {
                managerMasterId = mastersByUserId.get(userRecord.ManagerId).Id;
            }

            //-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
            if (master.celsrm__Manager__c != managerMasterId) {
                managerUpdates.add(new celsrm__User_Master__c(
            //-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
                    Id = master.Id,
                    //-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
                    celsrm__Manager__c = managerMasterId
                    //-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
                ));
            }
        }

        if (!managerUpdates.isEmpty()) {
            update managerUpdates;
        }
    }

    // Creates missing external masters on demand and links manager masters using normalized email keys.
    //-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
    public static Map<String, celsrm__User_Master__c> ensureExternalUserMasters(
    //-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
        Map<String, String> namesByEmail,
        Map<String, String> managerEmailsByEmail
    ) {
        //-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
        Map<String, celsrm__User_Master__c> mastersByEmail = new Map<String, celsrm__User_Master__c>();
        //-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
        if ((namesByEmail == null || namesByEmail.isEmpty()) &&
            (managerEmailsByEmail == null || managerEmailsByEmail.isEmpty())) {
            return mastersByEmail;
        }

        Map<String, String> normalizedNamesByEmail = new Map<String, String>();
        Map<String, String> normalizedManagersByEmail = new Map<String, String>();
        Set<String> allEmails = new Set<String>();

        if (namesByEmail != null) {
            for (String emailAddress : namesByEmail.keySet()) {
                String normalizedEmail = normalizeEmail(emailAddress);
                if (normalizedEmail == null) {
                    continue;
                }
                normalizedNamesByEmail.put(normalizedEmail, namesByEmail.get(emailAddress));
                allEmails.add(normalizedEmail);
            }
        }

        if (managerEmailsByEmail != null) {
            for (String emailAddress : managerEmailsByEmail.keySet()) {
                String normalizedEmail = normalizeEmail(emailAddress);
                String normalizedManagerEmail = normalizeEmail(managerEmailsByEmail.get(emailAddress));
                if (normalizedEmail == null) {
                    continue;
                }
                if (normalizedManagerEmail != null) {
                    normalizedManagersByEmail.put(normalizedEmail, normalizedManagerEmail);
                    allEmails.add(normalizedManagerEmail);
                }
            }
        }

        if (allEmails.isEmpty()) {
            return mastersByEmail;
        }

        //-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
        Map<String, celsrm__User_Master__c> existingMasters = getExternalMastersByEmail(allEmails);
        List<celsrm__User_Master__c> mastersToUpsert = new List<celsrm__User_Master__c>();
        //-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
        for (String normalizedEmail : allEmails) {
            if (existingMasters.containsKey(normalizedEmail)) {
                continue;
            }
            String configuredName = normalizedNamesByEmail.containsKey(normalizedEmail)
                ? normalizedNamesByEmail.get(normalizedEmail)
                : normalizedEmail;
            //-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
            celsrm__User_Master__c master = new celsrm__User_Master__c();
            master.celsrm__Master_Key__c = buildExternalMasterKey(normalizedEmail);
            //-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
            master.Name = String.isBlank(configuredName) ? normalizedEmail : configuredName;
            //-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
            master.celsrm__Email__c = normalizedEmail;
            master.celsrm__Is_External_User__c = true;
            master.celsrm__Is_Active__c = true;
            //-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
            mastersToUpsert.add(master);
        }

        if (!mastersToUpsert.isEmpty()) {
            saveUserMasters(mastersToUpsert);
            existingMasters = getExternalMastersByEmail(allEmails);
        }

        Map<Id, Id> existingManagerByMasterId = new Map<Id, Id>();
        Map<Id, Id> desiredManagerByMasterId = new Map<Id, Id>();
        //-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
        for (celsrm__User_Master__c existingMaster : existingMasters.values()) {
            existingManagerByMasterId.put(existingMaster.Id, existingMaster.celsrm__Manager__c);
        //-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
        }
        for (String normalizedEmail : normalizedNamesByEmail.keySet()) {
            //-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
            celsrm__User_Master__c master = existingMasters.get(normalizedEmail);
            //-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
            if (master == null) {
                continue;
            }

            String normalizedManagerEmail = normalizedManagersByEmail.get(normalizedEmail);
            Id managerMasterId = normalizedManagerEmail != null && existingMasters.containsKey(normalizedManagerEmail)
                ? existingMasters.get(normalizedManagerEmail).Id
                : null;
            desiredManagerByMasterId.put(master.Id, managerMasterId);
        }

        //-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
        List<celsrm__User_Master__c> managerUpdates = new List<celsrm__User_Master__c>();
        //-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
        for (String normalizedEmail : normalizedNamesByEmail.keySet()) {
            //-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
            celsrm__User_Master__c master = existingMasters.get(normalizedEmail);
            //-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
            if (master == null) {
                continue;
            }

            Id desiredManagerMasterId = desiredManagerByMasterId.get(master.Id);
            Id safeManagerMasterId = desiredManagerMasterId;
            if (createsManagerCycle(master.Id, desiredManagerMasterId, desiredManagerByMasterId, existingManagerByMasterId)) {
                // Skip invalid external-manager loops during backfill instead of failing the whole transaction.
                //-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
                safeManagerMasterId = master.celsrm__Manager__c;
                //-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
            }

            Boolean nameChanged = false;
            if (!String.isBlank(normalizedNamesByEmail.get(normalizedEmail)) &&
                master.Name != normalizedNamesByEmail.get(normalizedEmail)) {
                nameChanged = true;
            }

            //-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
            if (nameChanged || master.celsrm__Manager__c != safeManagerMasterId) {
                managerUpdates.add(new celsrm__User_Master__c(
            //-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
                    Id = master.Id,
                    Name = nameChanged ? normalizedNamesByEmail.get(normalizedEmail) : master.Name,
                    //-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
                    celsrm__Manager__c = safeManagerMasterId
                    //-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
                ));
            }
        }

        if (!managerUpdates.isEmpty()) {
            update managerUpdates;
            existingMasters = getExternalMastersByEmail(allEmails);
        }

        for (String normalizedEmail : normalizedNamesByEmail.keySet()) {
            if (existingMasters.containsKey(normalizedEmail)) {
                mastersByEmail.put(normalizedEmail, existingMasters.get(normalizedEmail));
            }
        }
        return mastersByEmail;
    }

    private static Boolean createsManagerCycle(
        Id masterId,
        Id managerMasterId,
        Map<Id, Id> desiredManagerByMasterId,
        Map<Id, Id> existingManagerByMasterId
    ) {
        if (masterId == null || managerMasterId == null) {
            return false;
        }
        if (masterId == managerMasterId) {
            return true;
        }

        Set<Id> visitedManagerIds = new Set<Id>();
        Id currentManagerId = managerMasterId;
        while (currentManagerId != null && !visitedManagerIds.contains(currentManagerId)) {
            if (currentManagerId == masterId) {
                return true;
            }
            visitedManagerIds.add(currentManagerId);
            currentManagerId = desiredManagerByMasterId.containsKey(currentManagerId)
                ? desiredManagerByMasterId.get(currentManagerId)
                : existingManagerByMasterId.get(currentManagerId);
        }
        return false;
    }

    // Resolves a runtime assignee from the new master model first, then falls back to legacy user/email values.
    public static ResolvedUserInfo resolveUserAssignment(
        Id userMasterId,
        String userIdOrEmail,
        String displayName,
        Boolean createExternalMaster,
        String managerEmail
    ) {
        //-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
        celsrm__User_Master__c masterRecord;
        //-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
        if (userMasterId != null) {
            //-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
            Map<Id, celsrm__User_Master__c> mastersById = getUserMastersById(new Set<Id>{ userMasterId });
            //-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
            masterRecord = mastersById.get(userMasterId);
        }

        if (masterRecord == null && isUserId(userIdOrEmail)) {
            Id legacyUserId = Id.valueOf(userIdOrEmail);
            syncInternalUsers(new Set<Id>{ legacyUserId });
            masterRecord = getInternalMastersByUserIds(new Set<Id>{ legacyUserId }).get(legacyUserId);
        }

        if (masterRecord == null && !String.isBlank(userIdOrEmail) && !isUserId(userIdOrEmail)) {
            //-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
            Map<String, celsrm__User_Master__c> mastersByEmail;
            //-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
            String normalizedEmail = normalizeEmail(userIdOrEmail);
            if (createExternalMaster) {
                Map<String, String> namesByEmail = new Map<String, String>{
                    normalizedEmail => String.isBlank(displayName) ? normalizedEmail : displayName
                };
                Map<String, String> managerEmailsByEmail = String.isBlank(managerEmail)
                    ? new Map<String, String>()
                    : new Map<String, String>{ normalizedEmail => managerEmail };
                mastersByEmail = ensureExternalUserMasters(namesByEmail, managerEmailsByEmail);
            } else {
                mastersByEmail = getExternalMastersByEmail(new Set<String>{ normalizedEmail });
            }
            masterRecord = normalizedEmail != null ? mastersByEmail.get(normalizedEmail) : null;
        }

        if (masterRecord != null) {
            return fromUserMaster(masterRecord);
        }

        if (String.isBlank(userIdOrEmail)) {
            return null;
        }

        ResolvedUserInfo fallbackInfo = new ResolvedUserInfo();
        fallbackInfo.userMasterId = userMasterId;
        fallbackInfo.name = displayName;
        if (isUserId(userIdOrEmail)) {
            fallbackInfo.userId = Id.valueOf(userIdOrEmail);
            fallbackInfo.category = INTERNAL_CATEGORY;
        } else {
            fallbackInfo.email = normalizeEmail(userIdOrEmail);
            fallbackInfo.category = EXTERNAL_CATEGORY;
        }
        if (String.isBlank(fallbackInfo.name)) {
            fallbackInfo.name = fallbackInfo.isExternal() ? fallbackInfo.email : String.valueOf(fallbackInfo.userId);
        }
        fallbackInfo.managerEmail = normalizeEmail(managerEmail);
        return fallbackInfo;
    }

    public static ResolvedUserInfo resolveFromMatrixRecord(celsrm__Dispute_Workflow_Matrix__c matrixRecord) {
        if (matrixRecord == null) {
            return null;
        }
        //-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
        String displayName = matrixRecord.celsrm__User_Master__r != null ? matrixRecord.celsrm__User_Master__r.Name : '';
        String managerEmail = matrixRecord.celsrm__User_Master__r != null &&
            matrixRecord.celsrm__User_Master__r.celsrm__Manager__r != null
            ? matrixRecord.celsrm__User_Master__r.celsrm__Manager__r.celsrm__Email__c
        //-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
            : null;
        return resolveUserAssignment(
            //-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
            matrixRecord.celsrm__User_Master__c,
            null,
            //-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
            displayName,
            false,
            //-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
            managerEmail
            //-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
        );
    }

    // Managed package formula fields cannot be changed, so matrix escalation email is resolved in Apex instead.
    public static String resolveEscalationEmailFromMatrixRecord(
        celsrm__Dispute_Workflow_Matrix__c matrixRecord,
        ResolvedUserInfo resolvedUser
    ) {
        if (matrixRecord == null) {
            return null;
        }

        if (resolvedUser != null && !String.isBlank(resolvedUser.managerEmail)) {
            return resolvedUser.managerEmail;
        }

        //-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
        if (matrixRecord.celsrm__User_Master__r != null
            && matrixRecord.celsrm__User_Master__r.celsrm__Manager__r != null
            && !String.isBlank(matrixRecord.celsrm__User_Master__r.celsrm__Manager__r.celsrm__Email__c)) {
            return matrixRecord.celsrm__User_Master__r.celsrm__Manager__r.celsrm__Email__c;
        //-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
        }

        return String.valueOf(matrixRecord.get('celsrm__Escalation_Email__c'));
    }

    public static ResolvedUserInfo resolveFromDisputeRecord(celsrm__Dispute__c disputeRecord) {
        if (disputeRecord == null) {
            return null;
        }
        //-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
        String displayName = disputeRecord.celsrm__Resolver_User_Master__r != null
            ? disputeRecord.celsrm__Resolver_User_Master__r.Name
        //-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
            : null;
        return resolveUserAssignment(
            //-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
            disputeRecord.celsrm__Resolver_User_Master__c,
            null,
            //-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
            displayName,
            false,
            null
        );
    }

    //-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
    public static ResolvedUserInfo resolveFromWorkflowDetailRecord(celsrm__Dispute_Workflow_Details__c workflowDetail) {
    //-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
        if (workflowDetail == null) {
            return null;
        }
        //-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
        String legacyIdentifier = workflowDetail.celsrm__User_Master__c ;
            
        // String fallbackName = workflowDetail.getPopulatedFieldsAsMap().containsKey('User_Name__c')
        //     ? String.valueOf(workflowDetail.get('User_Name__c'))
        //     : null;
        String displayName = workflowDetail.celsrm__User_Master__r != null ? workflowDetail.celsrm__User_Master__r.Name : '';
        String managerEmail = workflowDetail.celsrm__User_Master__r != null &&
            workflowDetail.celsrm__User_Master__r.celsrm__Manager__r != null
            ? workflowDetail.celsrm__User_Master__r.celsrm__Manager__r.celsrm__Email__c
        //-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
            : null;
        return resolveUserAssignment(
            //-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
            workflowDetail.celsrm__User_Master__c,
            //-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
            legacyIdentifier,
            displayName,
            false,
            managerEmail
        );
    }

    public static void applyAssignmentToDispute(celsrm__Dispute__c disputeRecord, ResolvedUserInfo resolvedUser) {
        if (disputeRecord == null) {
            return;
        }

        //-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
        disputeRecord.celsrm__Resolver_User_Master__c = resolvedUser != null ? resolvedUser.userMasterId : null;
        //-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
    }

    //-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
    public static void applyAssignmentToWorkflowDetail(celsrm__Dispute_Workflow_Details__c workflowDetail, ResolvedUserInfo resolvedUser) {
    //-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
        if (workflowDetail == null) {
            return;
        }

        // Workflow details also keep both models populated so reminder/escalation code can read either path.
        //-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
        workflowDetail.celsrm__User_Master__c = resolvedUser != null ? resolvedUser.userMasterId : null;
        // workflowDetail.User_Name__c = resolvedUser != null ? resolvedUser.name : null;
        // if (resolvedUser == null) {
        //     workflowDetail.User__c = null;
        //     workflowDetail.External_User_Email__c = null;
        //     return;
        // }

        // if (resolvedUser.isExternal()) {
        //     workflowDetail.User__c = null;
        //     workflowDetail.External_User_Email__c = resolvedUser.email;
        // } else {
        //     workflowDetail.User__c = resolvedUser.userId;
        //     workflowDetail.External_User_Email__c = null;
        // }
        //-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
    }

    public static void applyAssignmentToWorkflowMatrix(celsrm__Dispute_Workflow_Matrix__c matrixRecord, ResolvedUserInfo resolvedUser) {
        if (matrixRecord == null) {
            return;
        }

        // Matrix rows are normalized into master + legacy snapshots so old configuration consumers still work.
        //-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
        matrixRecord.celsrm__User_Master__c = resolvedUser != null ? resolvedUser.userMasterId : null;
        // if (resolvedUser == null) {
        //     matrixRecord.User__c = null;
        //     matrixRecord.External_Email__c = null;
        //     matrixRecord.External_Manager_Email__c = null;
        //     return;
        // }

        // if (resolvedUser.isExternal()) {
        //     matrixRecord.User__c = null;
        //     matrixRecord.External_Email__c = resolvedUser.email;
        //     matrixRecord.External_Manager_Email__c = resolvedUser.managerEmail;
        // } else {
        //     matrixRecord.User__c = resolvedUser.userId;
        //     matrixRecord.External_Email__c = null;
        //     matrixRecord.External_Manager_Email__c = null;
        // }
        //-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
    }

    public static Map<Object, Object> toAssignmentMap(ResolvedUserInfo resolvedUser) {
        Map<Object, Object> assignmentMap = new Map<Object, Object>();
        assignmentMap.put('id', resolvedUser == null ? null : (resolvedUser.isExternal() ? resolvedUser.email : resolvedUser.userId));
        assignmentMap.put('name', resolvedUser == null ? null : resolvedUser.name);
        assignmentMap.put('userMasterId', resolvedUser == null ? null : resolvedUser.userMasterId);
        assignmentMap.put('isExternalResolver', resolvedUser == null ? false : resolvedUser.isExternal());
        return assignmentMap;
    }

    public static Boolean isUserId(String value) {
        if (String.isBlank(value)) {
            return false;
        }
        Integer valueLength = value.length();
        return (valueLength == 15 || valueLength == 18) && value.startsWith('005');
    }

    //-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
    private static ResolvedUserInfo fromUserMaster(celsrm__User_Master__c masterRecord) {
    //-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
        ResolvedUserInfo resolvedUser = new ResolvedUserInfo();
        resolvedUser.userMasterId = masterRecord.Id;
        //-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
        resolvedUser.userId = masterRecord.celsrm__User__c;
        resolvedUser.email = masterRecord.celsrm__Email__c;
        // resolvedUser.name = !String.isBlank(masterRecord.Name)
        //     ? masterRecord.Name
        //     : (masterRecord.User__c != null ? String.valueOf(masterRecord.User__c) : masterRecord.celsrm__Email__c);
        resolvedUser.category = masterRecord.celsrm__Is_External_User__c == true ? EXTERNAL_CATEGORY : INTERNAL_CATEGORY;
        resolvedUser.language = masterRecord.celsrm__Language__c;
        resolvedUser.managerUserMasterId = masterRecord.celsrm__Manager__c;
        resolvedUser.managerEmail = masterRecord.celsrm__Manager__r != null
            ? masterRecord.celsrm__Manager__r.celsrm__Email__c
        //-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
            : null;
        //-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
        resolvedUser.managerName = masterRecord.celsrm__Manager__r != null
            ? masterRecord.celsrm__Manager__r.Name
        //-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
            : null;
        return resolvedUser;
    }

    private static Map<Id, User> queryUsersWithLanguage(Set<Id> userIds) {
        Map<Id, User> usersById = new Map<Id, User>();
        if (userIds == null || userIds.isEmpty()) {
            return usersById;
        }

        for (User userRecord : [
            SELECT Id, Name, Email, IsActive, ManagerId, LanguageLocaleKey, toLabel(LanguageLocaleKey) LanguageLabel
            FROM User
            WHERE Id IN :userIds
        ]) {
            usersById.put(userRecord.Id, userRecord);
        }
        return usersById;
    }
    //-- End | FIN-9672 | Changed by Ravi | 05 May 2026 --//
}
//-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//