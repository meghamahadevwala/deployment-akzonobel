global with sharing class CreditReviewListController implements celsrm.GOGIScreenCustomLogic {
    global Map<Object, Object> invoke(String functionName, Map<Object, Object> inMap){
        try {
            if(functionName == 'onPageLoadFunctionAssignedToMe'){
                inMap = onPageLoadFunctionAssignedToMe(inMap);
            } else if(functionName == 'onPageLoadFunctionAssignedToQueue'){
                inMap = onPageLoadFunctionAssignedToQueue(inMap);
            } else if(functionName == 'onPageLoadFunctionAssignedToDelegated'){
                inMap = onPageLoadFunctionAssignedToDelegated(inMap);
            } else if(functionName == 'onPageLoadFunctionAssignedToManager'){
                inMap = onPageLoadFunctionAssignedToManager(inMap);
            }

        } catch(exception ex){
            String errorMessage = 'ClassName: CA_ApplyCashController | Method: invoke() | Linenumber: ' + ex.getLineNumber() + ' | Message: ' + ex.getMessage();
            System.debug('errorMessage: ' + errorMessage);
        }
        return inMap;
    }

    public static Map<Object, Object> onPageLoadFunctionAssignedToMe(Map<Object, Object> inMap){
        
        List<celsrm__Credit_Limit_Approval_Detail__c> detailRows = [SELECT Id, celsrm__Credit_Review__c,celsrm__Credit_Review__r.Name, 
                                                            celsrm__Credit_Review__r.celsrm__Account__r.Name,
                                                            celsrm__Credit_Review__r.celsrm__Account__r.AccountNumber,
                                                            celsrm__Credit_Review__r.celsrm__Account__r.celsrm__Credit_control_Area__c,
                                                            celsrm__Credit_Review__r.celsrm__Account__r.celsrm__Credit_Segment__c,
                                                            celsrm__Credit_Review__r.celsrm__Requested_Credit_Limit__c,
                                                            celsrm__Credit_Review__r.celsrm__Requested_Credit_Limit_Group_Currency__c,
                                                            celsrm__User_Master__c,
                                                            celsrm__User_Master__r.Name,
                                                            celsrm__Credit_Review__r.OwnerId,
                                                            celsrm__Credit_Review__r.Owner.Name
                                                            FROM celsrm__Credit_Limit_Approval_Detail__c 
                                                            WHERE celsrm__Status__c = 'Pending' AND celsrm__Credit_Review__r.celsrm__Status__c = 'Pending'
                                                            AND celsrm__User_Master__r.celsrm__User__c = :UserInfo.getUserId()];
        List<Map<Object, Object>> responseRows = new List<Map<Object, Object>>();
        // To avoide duplicate data, we need to use a set to store the credit review ids
        Set<Id> creditReviewIds = new Set<Id>();
        for(celsrm__Credit_Limit_Approval_Detail__c detailRow : detailRows){
            if(creditReviewIds.contains(detailRow.celsrm__Credit_Review__c)){
                continue; // Skip duplicate data
            }
            creditReviewIds.add(detailRow.celsrm__Credit_Review__c);
            Map<Object, Object> responseRow = new Map<Object, Object>();
            responseRow.put('Id', detailRow.Id);
            responseRow.put('creditReview', new Map<String, Object>{
                'id' => detailRow.celsrm__Credit_Review__c,
                'name' => detailRow.celsrm__Credit_Review__r.Name
            });
            responseRow.put('account', new Map<String, Object>{
                'id' => detailRow.celsrm__Credit_Review__r.celsrm__Account__c,
                'name' => detailRow.celsrm__Credit_Review__r.celsrm__Account__r.Name
            });
            responseRow.put('accountNumber', detailRow.celsrm__Credit_Review__r.celsrm__Account__r.AccountNumber);
            responseRow.put('creditControlArea', detailRow.celsrm__Credit_Review__r.celsrm__Account__r.celsrm__Credit_control_Area__c);
            responseRow.put('creditSegment', detailRow.celsrm__Credit_Review__r.celsrm__Account__r.celsrm__Credit_Segment__c);
            responseRow.put('requestedCreditLimit', detailRow.celsrm__Credit_Review__r.celsrm__Requested_Credit_Limit__c);
            responseRow.put('requestedCreditLimitGroup', detailRow.celsrm__Credit_Review__r.celsrm__Requested_Credit_Limit_Group_Currency__c);
            responseRow.put('assignee', new Map<String, Object>{
                'id' => detailRow.celsrm__User_Master__c,
                'name' => detailRow.celsrm__User_Master__r.Name
            });
            responseRow.put('owner', new Map<String, Object>{
                'id' => detailRow.celsrm__Credit_Review__r.OwnerId,
                'name' => detailRow.celsrm__Credit_Review__r.Owner.Name
            });
            responseRows.add(responseRow);
        }
        inMap.put('dataServiceResponse', responseRows);
        return inMap;
    }

    public static Map<Object, Object> onPageLoadFunctionAssignedToDelegated(Map<Object, Object> inMap){
        celsrm__Credit_Configuration__c config = celsrm__Credit_Configuration__c.getOrgDefaults();
        if (config == null || config.celsrm__Allow_Delegated_User_Manger_to_act__c != true) {
            inMap.put('dataServiceResponse', new List<Map<Object, Object>>());
            return inMap;
        }
        Id currentUserId = UserInfo.getUserId();
        Set<Id> currentUserMasterIds = new Set<Id>();
        for (celsrm__User_Master__c currentUserMaster : [
            SELECT Id
            FROM celsrm__User_Master__c
            WHERE celsrm__User__c = :currentUserId
        ]) {
            currentUserMasterIds.add(currentUserMaster.Id);
        }
        if (currentUserMasterIds.isEmpty()) {
            inMap.put('dataServiceResponse', new List<Map<Object, Object>>());
            return inMap;
        }

        Set<Id> delegatedUserMasterIds = new Set<Id>();
        Set<Id> delegatedSalesforceUserIds = new Set<Id>();
        for (celsrm__User_Master__c delegatedUserMaster : [
            SELECT Id, celsrm__User__c
            FROM celsrm__User_Master__c
            WHERE celsrm__Delegated_User__c IN :currentUserMasterIds
        ]) {
            delegatedUserMasterIds.add(delegatedUserMaster.Id);
            if (delegatedUserMaster.celsrm__User__c != null) {
                delegatedSalesforceUserIds.add(delegatedUserMaster.celsrm__User__c);
            }
        }
        if (delegatedUserMasterIds.isEmpty()) {
            inMap.put('dataServiceResponse', new List<Map<Object, Object>>());
            return inMap;
        }

        Set<Id> delegatedQueueIds = new Set<Id>();
        for (Id delegatedUserId : delegatedSalesforceUserIds) {
            delegatedQueueIds.addAll(CreditReviewAccessUtil.getQueueIdsForUserWithNestedGroups(delegatedUserId));
        }

        List<celsrm__Credit_Limit_Approval_Detail__c> detailRows;
        detailRows = [
                SELECT Id, celsrm__Credit_Review__c, celsrm__Credit_Review__r.Name,
                    celsrm__Credit_Review__r.celsrm__Account__c,
                    celsrm__Credit_Review__r.celsrm__Account__r.Name,
                    celsrm__Credit_Review__r.celsrm__Account__r.AccountNumber,
                    celsrm__Credit_Review__r.celsrm__Account__r.celsrm__Credit_Control_Area__c,
                    celsrm__Credit_Review__r.celsrm__Account__r.celsrm__Credit_Segment__c,
                    celsrm__Credit_Review__r.celsrm__Requested_Credit_Limit__c,
                    celsrm__Credit_Review__r.celsrm__Requested_Credit_Limit_Group_Currency__c,
                    celsrm__User_Master__c,
                    celsrm__User_Master__r.Name,
                    celsrm__Queue__c,
                    celsrm__Credit_Review__r.OwnerId,
                    celsrm__Credit_Review__r.Owner.Name
                FROM celsrm__Credit_Limit_Approval_Detail__c
                WHERE celsrm__Status__c = 'Pending' AND celsrm__Credit_Review__r.celsrm__Status__c = 'Pending'
                AND (
                    celsrm__User_Master__c IN :delegatedUserMasterIds
                    OR celsrm__Queue__c IN :delegatedQueueIds
                )
            ];

        Map<Id, String> queueMap = new Map<Id, String>();
        if (!delegatedQueueIds.isEmpty()) {
            for (Group queueRow : [SELECT Id, Name FROM Group WHERE Id IN :delegatedQueueIds]) {
                queueMap.put(queueRow.Id, queueRow.Name);
            }
        }

        List<Map<Object, Object>> responseRows = new List<Map<Object, Object>>();
        Set<Id> creditReviewIds = new Set<Id>();
        for (celsrm__Credit_Limit_Approval_Detail__c detailRow : detailRows) {
            if (creditReviewIds.contains(detailRow.celsrm__Credit_Review__c)) {
                continue;
            }
            creditReviewIds.add(detailRow.celsrm__Credit_Review__c);
            Map<Object, Object> responseRow = new Map<Object, Object>();
            responseRow.put('Id', detailRow.Id);
            responseRow.put('creditReview', new Map<String, Object>{
                'id' => detailRow.celsrm__Credit_Review__c,
                'name' => detailRow.celsrm__Credit_Review__r.Name
            });
            responseRow.put('account', new Map<String, Object>{
                'id' => detailRow.celsrm__Credit_Review__r.celsrm__Account__c,
                'name' => detailRow.celsrm__Credit_Review__r.celsrm__Account__r.Name
            });
            responseRow.put('accountNumber', detailRow.celsrm__Credit_Review__r.celsrm__Account__r.AccountNumber);
            responseRow.put('creditControlArea', detailRow.celsrm__Credit_Review__r.celsrm__Account__r.celsrm__Credit_control_Area__c);
            responseRow.put('creditSegment', detailRow.celsrm__Credit_Review__r.celsrm__Account__r.celsrm__Credit_Segment__c);
            responseRow.put('requestedCreditLimit', detailRow.celsrm__Credit_Review__r.celsrm__Requested_Credit_Limit__c);
            responseRow.put('requestedCreditLimitGroup', detailRow.celsrm__Credit_Review__r.celsrm__Requested_Credit_Limit_Group_Currency__c);
            if(detailRow.celsrm__User_Master__c != null){
                responseRow.put('assignee', new Map<String, Object>{
                    'id' => detailRow.celsrm__User_Master__c,
                    'name' => detailRow.celsrm__User_Master__r.Name
                });
            }
            if(detailRow.celsrm__Queue__c != null){
                responseRow.put('assignee', new Map<String, Object>{
                    'id' => detailRow.celsrm__Queue__c,
                    'name' => queueMap.get(detailRow.celsrm__Queue__c)
                });
            }
            responseRow.put('owner', new Map<String, Object>{
                'id' => detailRow.celsrm__Credit_Review__r.OwnerId,
                'name' => detailRow.celsrm__Credit_Review__r.Owner.Name
            });
            responseRows.add(responseRow);
        }
        inMap.put('dataServiceResponse', responseRows);
        return inMap;
    }

    public static Map<Object, Object> onPageLoadFunctionAssignedToManager(Map<Object, Object> inMap){
        Id currentUserId = UserInfo.getUserId();
        Set<Id> currentUserMasterIds = new Set<Id>();
        for (celsrm__User_Master__c currentUserMaster : [
            SELECT Id
            FROM celsrm__User_Master__c
            WHERE celsrm__User__c = :currentUserId
        ]) {
            currentUserMasterIds.add(currentUserMaster.Id);
        }
        if (currentUserMasterIds.isEmpty()) {
            inMap.put('dataServiceResponse', new List<Map<Object, Object>>());
            return inMap;
        }

        Set<Id> managerUserMasterIds = new Set<Id>();
        Set<Id> managerSalesforceUserIds = new Set<Id>();
        for (celsrm__User_Master__c managerUserMaster : [
            SELECT Id, celsrm__User__c, celsrm__Manager__c
            FROM celsrm__User_Master__c
            WHERE celsrm__Manager__c IN :currentUserMasterIds
        ]) {
            managerUserMasterIds.add(managerUserMaster.Id);
            if (managerUserMaster.celsrm__User__c != null) {
                managerSalesforceUserIds.add(managerUserMaster.celsrm__User__c);
            }
        }
        if (managerUserMasterIds.isEmpty()) {
            inMap.put('dataServiceResponse', new List<Map<Object, Object>>());
            return inMap;
        }

        Set<Id> managerQueueIds = new Set<Id>();
        for (Id managerUserId : managerSalesforceUserIds) {
            managerQueueIds.addAll(CreditReviewAccessUtil.getQueueIdsForUserWithNestedGroups(managerUserId));
        }

        List<celsrm__Credit_Limit_Approval_Detail__c> detailRows;
        detailRows = [
                SELECT Id, celsrm__Credit_Review__c, celsrm__Credit_Review__r.Name,
                    celsrm__Credit_Review__r.celsrm__Account__c,
                    celsrm__Credit_Review__r.celsrm__Account__r.Name,
                    celsrm__Credit_Review__r.celsrm__Account__r.AccountNumber,
                    celsrm__Credit_Review__r.celsrm__Account__r.celsrm__Credit_control_Area__c,
                    celsrm__Credit_Review__r.celsrm__Account__r.celsrm__Credit_Segment__c,
                    celsrm__Credit_Review__r.celsrm__Requested_Credit_Limit__c,
                    celsrm__Credit_Review__r.celsrm__Requested_Credit_Limit_Group_Currency__c,
                    celsrm__User_Master__c,
                    celsrm__User_Master__r.Name,
                    celsrm__Queue__c,
                    celsrm__Credit_Review__r.OwnerId,
                    celsrm__Credit_Review__r.Owner.Name
                FROM celsrm__Credit_Limit_Approval_Detail__c
                WHERE celsrm__Status__c = 'Pending' AND celsrm__Credit_Review__r.celsrm__Status__c = 'Pending'
                AND (
                    celsrm__User_Master__c IN :managerUserMasterIds
                    OR celsrm__Queue__c IN :managerQueueIds
                )
            ];

        Map<Id, String> queueMap = new Map<Id, String>();
        if (!managerQueueIds.isEmpty()) {
            for (Group queueRow : [SELECT Id, Name FROM Group WHERE Id IN :managerQueueIds]) {
                queueMap.put(queueRow.Id, queueRow.Name);
            }
        }

        List<Map<Object, Object>> responseRows = new List<Map<Object, Object>>();
        Set<Id> creditReviewIds = new Set<Id>();
        for (celsrm__Credit_Limit_Approval_Detail__c detailRow : detailRows) {
            if (creditReviewIds.contains(detailRow.celsrm__Credit_Review__c)) {
                continue;
            }
            creditReviewIds.add(detailRow.celsrm__Credit_Review__c);
            Map<Object, Object> responseRow = new Map<Object, Object>();
            responseRow.put('Id', detailRow.Id);
            responseRow.put('creditReview', new Map<String, Object>{
                'id' => detailRow.celsrm__Credit_Review__c,
                'name' => detailRow.celsrm__Credit_Review__r.Name
            });
            responseRow.put('account', new Map<String, Object>{
                'id' => detailRow.celsrm__Credit_Review__r.celsrm__Account__c,
                'name' => detailRow.celsrm__Credit_Review__r.celsrm__Account__r.Name
            });
            responseRow.put('accountNumber', detailRow.celsrm__Credit_Review__r.celsrm__Account__r.AccountNumber);
            responseRow.put('creditControlArea', detailRow.celsrm__Credit_Review__r.celsrm__Account__r.celsrm__Credit_control_Area__c);
            responseRow.put('creditSegment', detailRow.celsrm__Credit_Review__r.celsrm__Account__r.celsrm__Credit_Segment__c);
            responseRow.put('requestedCreditLimit', detailRow.celsrm__Credit_Review__r.celsrm__Requested_Credit_Limit__c);
            responseRow.put('requestedCreditLimitGroup', detailRow.celsrm__Credit_Review__r.celsrm__Requested_Credit_Limit_Group_Currency__c);
            if(detailRow.celsrm__User_Master__c != null){
                responseRow.put('assignee', new Map<String, Object>{
                    'id' => detailRow.celsrm__User_Master__c,
                    'name' => detailRow.celsrm__User_Master__r.Name
                });
            }
            if(detailRow.celsrm__Queue__c != null){
                responseRow.put('assignee', new Map<String, Object>{
                    'id' => detailRow.celsrm__Queue__c,
                    'name' => queueMap.get(detailRow.celsrm__Queue__c)
                });
            }
            responseRow.put('owner', new Map<String, Object>{
                'id' => detailRow.celsrm__Credit_Review__r.OwnerId,
                'name' => detailRow.celsrm__Credit_Review__r.Owner.Name
            });
            responseRows.add(responseRow);
        }
        inMap.put('dataServiceResponse', responseRows);
        return inMap;
    }

    public static Map<Object, Object> onPageLoadFunctionAssignedToQueue(Map<Object, Object> inMap){
        
        List<Group> queues = getCurrentUserQueuesWithNestedGroups();
        Set<Id> queueIds = new Set<Id>();
        Map<Id, String> queueMap = new Map<Id, String>();
        for (Group queueRow : queues) {
            queueIds.add(queueRow.Id);
            queueMap.put(queueRow.Id, queueRow.Name);
        }
        if (queueIds.isEmpty()) {
            inMap.put('dataServiceResponse', new List<Map<Object, Object>>());
            return inMap;
        }
        List<celsrm__Credit_Limit_Approval_Detail__c> detailRows = [SELECT Id, celsrm__Credit_Review__c, celsrm__Credit_Review__r.Name, 
                                                            celsrm__Credit_Review__r.celsrm__Account__r.Name,
                                                            celsrm__Credit_Review__r.celsrm__Account__r.AccountNumber,
                                                            celsrm__Credit_Review__r.celsrm__Account__r.celsrm__Credit_control_Area__c,
                                                            celsrm__Credit_Review__r.celsrm__Account__r.celsrm__Credit_Segment__c,
                                                            celsrm__Credit_Review__r.celsrm__Requested_Credit_Limit__c,
                                                            celsrm__Credit_Review__r.celsrm__Requested_Credit_Limit_Group_Currency__c,
                                                            celsrm__Queue__c,
                                                            celsrm__Credit_Review__r.OwnerId,
                                                            celsrm__Credit_Review__r.Owner.Name
                                                            FROM celsrm__Credit_Limit_Approval_Detail__c 
                                                            WHERE celsrm__Status__c = 'Pending' AND celsrm__Credit_Review__r.celsrm__Status__c = 'Pending'
                                                            AND celsrm__Queue__c IN :queueIds];
        List<Map<Object, Object>> responseRows = new List<Map<Object, Object>>();
        // To avoide duplicate data, we need to use a set to store the credit review ids
        Set<Id> creditReviewIds = new Set<Id>();
        for(celsrm__Credit_Limit_Approval_Detail__c detailRow : detailRows){
            if(creditReviewIds.contains(detailRow.celsrm__Credit_Review__c)){
                continue; // Skip duplicate data
            }
            creditReviewIds.add(detailRow.celsrm__Credit_Review__c);
            Map<Object, Object> responseRow = new Map<Object, Object>();
            responseRow.put('Id', detailRow.Id);
            responseRow.put('creditReview', new Map<String, Object>{
                'id' => detailRow.celsrm__Credit_Review__c,
                'name' => detailRow.celsrm__Credit_Review__r.Name
            });
            responseRow.put('account', new Map<String, Object>{
                'id' => detailRow.celsrm__Credit_Review__r.celsrm__Account__c,
                'name' => detailRow.celsrm__Credit_Review__r.celsrm__Account__r.Name
            });
            responseRow.put('accountNumber', detailRow.celsrm__Credit_Review__r.celsrm__Account__r.AccountNumber);
            responseRow.put('creditControlArea', detailRow.celsrm__Credit_Review__r.celsrm__Account__r.celsrm__Credit_control_Area__c);
            responseRow.put('creditSegment', detailRow.celsrm__Credit_Review__r.celsrm__Account__r.celsrm__Credit_Segment__c);
            responseRow.put('requestedCreditLimit', detailRow.celsrm__Credit_Review__r.celsrm__Requested_Credit_Limit__c);
            responseRow.put('requestedCreditLimitGroup', detailRow.celsrm__Credit_Review__r.celsrm__Requested_Credit_Limit_Group_Currency__c);
            responseRow.put('assignee', new Map<String, Object>{
                'id' => detailRow.celsrm__Queue__c,
                'name' => queueMap.get(detailRow.celsrm__Queue__c)
            });
            responseRow.put('owner', new Map<String, Object>{
                'id' => detailRow.celsrm__Credit_Review__r.OwnerId,
                'name' => detailRow.celsrm__Credit_Review__r.Owner.Name
            });
            responseRows.add(responseRow);
        }
        inMap.put('dataServiceResponse', responseRows);
        return inMap;
    }

    // Returns all Queue groups where current user is a member, including nested subgroup membership.
    public static List<Group> getCurrentUserQueuesWithNestedGroups() {
        Set<Id> queueIds = CreditReviewAccessUtil.getQueueIdsForUserWithNestedGroups(UserInfo.getUserId());
        if (queueIds.isEmpty()) {
            return new List<Group>();
        }
        return [
            SELECT Id, Name, DeveloperName, Type
            FROM Group
            WHERE Id IN :queueIds
            ORDER BY Name
        ];
    }
}