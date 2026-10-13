public with sharing class CreditReviewAccessUtil {
    public static Set<Id> getCurrentUserMasterIds(Id currentUserId) {
        Set<Id> userMasterIds = new Set<Id>();
        if (currentUserId == null) {
            return userMasterIds;
        }
        for (celsrm__User_Master__c userMaster : [
            SELECT Id
            FROM celsrm__User_Master__c
            WHERE celsrm__User__c = :currentUserId
        ]) {
            userMasterIds.add(userMaster.Id);
        }
        return userMasterIds;
    }

    public static Boolean hasIntersection(Set<Id> left, Set<Id> right) {
        if (left == null || right == null || left.isEmpty() || right.isEmpty()) {
            return false;
        }
        for (Id idValue : left) {
            if (right.contains(idValue)) {
                return true;
            }
        }
        return false;
    }

    public static Set<Id> getQueueIdsForUserWithNestedGroups(Id userId) {
        Set<Id> queueIds = new Set<Id>();
        if (userId == null) {
            return queueIds;
        }

        Set<Id> discoveredGroupIds = new Set<Id>();
        Set<Id> frontierMemberIds = new Set<Id>{ userId };
        Integer depthGuard = 0;
        while (!frontierMemberIds.isEmpty() && depthGuard < 25) {
            depthGuard++;
            Set<Id> nextFrontierGroupIds = new Set<Id>();
            for (GroupMember memberRow : [
                SELECT GroupId
                FROM GroupMember
                WHERE UserOrGroupId IN :frontierMemberIds
            ]) {
                if (memberRow.GroupId == null || discoveredGroupIds.contains(memberRow.GroupId)) {
                    continue;
                }
                discoveredGroupIds.add(memberRow.GroupId);
                nextFrontierGroupIds.add(memberRow.GroupId);
            }
            frontierMemberIds = nextFrontierGroupIds;
        }

        if (discoveredGroupIds.isEmpty()) {
            return queueIds;
        }
        for (Group queueRow : [
            SELECT Id
            FROM Group
            WHERE Id IN :discoveredGroupIds
            AND Type = 'Queue'
        ]) {
            queueIds.add(queueRow.Id);
        }
        return queueIds;
    }

    public static Set<Id> getUserIdsForQueuesWithNestedGroups(Set<Id> queueIds) {
        Set<Id> userIds = new Set<Id>();
        if (queueIds == null || queueIds.isEmpty()) {
            return userIds;
        }

        Set<Id> visitedGroups = new Set<Id>();
        Set<Id> frontierGroupIds = new Set<Id>();
        frontierGroupIds.addAll(queueIds);
        visitedGroups.addAll(queueIds);

        Integer depthGuard = 0;
        while (!frontierGroupIds.isEmpty() && depthGuard < 25) {
            depthGuard++;
            Set<Id> nextFrontierGroupIds = new Set<Id>();
            for (GroupMember memberRow : [
                SELECT UserOrGroupId
                FROM GroupMember
                WHERE GroupId IN :frontierGroupIds
            ]) {
                Id memberId = memberRow.UserOrGroupId;
                if (memberId == null) {
                    continue;
                }
                Schema.SObjectType memberType = memberId.getSObjectType();
                if (memberType == User.SObjectType) {
                    userIds.add(memberId);
                } else if (memberType == Group.SObjectType && !visitedGroups.contains(memberId)) {
                    visitedGroups.add(memberId);
                    nextFrontierGroupIds.add(memberId);
                }
            }
            frontierGroupIds = nextFrontierGroupIds;
        }
        return userIds;
    }

    public static Boolean isDelegatedOrManagerForAnyMaster(Set<Id> targetUserMasterIds, Set<Id> currentUserMasterIds) {
        if (targetUserMasterIds == null || targetUserMasterIds.isEmpty() || currentUserMasterIds == null || currentUserMasterIds.isEmpty()) {
            return false;
        }
        String queryString =
            'SELECT Id, celsrm__Delegated_User__c' + getManagerFieldSelectPart() +
            ' FROM celsrm__User_Master__c WHERE Id IN :targetUserMasterIds';
        return isDelegatedOrManagerMatch(Database.query(queryString), currentUserMasterIds);
    }

    public static Boolean isDelegatedOrManagerForAnySalesforceUser(Set<Id> targetSalesforceUserIds, Set<Id> currentUserMasterIds) {
        if (targetSalesforceUserIds == null || targetSalesforceUserIds.isEmpty() || currentUserMasterIds == null || currentUserMasterIds.isEmpty()) {
            return false;
        }
        String queryString =
            'SELECT Id, celsrm__Delegated_User__c' + getManagerFieldSelectPart() +
            ' FROM celsrm__User_Master__c WHERE celsrm__User__c IN :targetSalesforceUserIds';
        return isDelegatedOrManagerMatch(Database.query(queryString), currentUserMasterIds);
    }

    public static Set<Id> getDelegatedManagerAccessibleQueueIds(Set<Id> queueIds, Set<Id> currentUserMasterIds) {
        Set<Id> accessibleQueueIds = new Set<Id>();
        if (queueIds == null || queueIds.isEmpty() || currentUserMasterIds == null || currentUserMasterIds.isEmpty()) {
            return accessibleQueueIds;
        }
        for (Id queueId : queueIds) {
            Set<Id> queueMemberUserIds = getUserIdsForQueuesWithNestedGroups(new Set<Id>{ queueId });
            if (queueMemberUserIds.isEmpty()) {
                continue;
            }
            if (isDelegatedOrManagerForAnySalesforceUser(queueMemberUserIds, currentUserMasterIds)) {
                accessibleQueueIds.add(queueId);
            }
        }
        return accessibleQueueIds;
    }

    private static Boolean isDelegatedOrManagerMatch(List<SObject> rows, Set<Id> currentUserMasterIds) {
        Boolean managerFieldExists = hasManagerField();
        for (SObject row : rows) {
            Id delegatedUserId = (Id) row.get('celsrm__Delegated_User__c');
            if (delegatedUserId != null && currentUserMasterIds.contains(delegatedUserId)) {
                return true;
            }
            if (managerFieldExists) {
                Id managerId = (Id) row.get('celsrm__Manager__c');
                if (managerId != null && currentUserMasterIds.contains(managerId)) {
                    return true;
                }
            }
        }
        return false;
    }

    private static String getManagerFieldSelectPart() {
        return hasManagerField() ? ', celsrm__Manager__c' : '';
    }

    private static Boolean hasManagerField() {
        return celsrm__User_Master__c.SObjectType.getDescribe().fields.getMap().containsKey('celsrm__Manager__c');
    }
}