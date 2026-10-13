global with sharing class FetchListViewForObjectForUser implements celsrm.GOGIScreenCustomLogic {
    global Map<Object, Object> invoke(String functionName, Map<Object, Object> inMap) {
        System.debug('@@@@ inMap : ' + inMap);
        if(!inMap.containsKey('ListViewObject') || inMap.get('ListViewObject') == null || inMap.get('ListViewObject') == '') {
            throw new celsrm.GOGDataServiceLoadException('List View Object is not specified');
        }
        
        if(!inMap.containsKey('ListViewParentField') || inMap.get('ListViewParentField') == null || inMap.get('ListViewParentField') == '') {
            throw new celsrm.GOGDataServiceLoadException('Parent Field Api name is not specified.');
        }
        
        List<Map<String,String>> returnOptions = new List<Map<string,String>>();
        try {
            String currUser = UserInfo.getUserId();

            // Query for the groups the current user is part of
            List<GroupMember> userGroups = [SELECT GroupId FROM GroupMember WHERE UserOrGroupId = :currUser];
            // Create a set of group IDs the current user is part of
            List<String> groupIdsAsStrings = new List<String>();
            for (GroupMember gm : userGroups) {
                groupIdsAsStrings.add('\'' + String.valueOf(gm.groupId) + '\'');
            }

            String accId = String.valueOf(inMap.get('Id'));
            String objectName = String.valueOf(inMap.get('ListViewObject'));
            String objectParentField = String.valueOf(inMap.get('ListViewParentField'));
            String folderName = '';
            if(inMap.containsKey('ListViewFolderName') &&  inMap.get('ListViewFolderName') != null && inMap.get('ListViewFolderName') != '') {
                folderName = (String)inMap.get('ListViewFolderName');
            }
            System.debug(' @@ currUser : ' + currUser);
            System.debug(' @@ accId : ' + accId );
            System.debug(' @@ objectName : ' + objectName );
            System.debug(' @@ objectParentField : ' + objectParentField );
            String query = 'SELECT Id, Name FROM celsrm__Custom_List_View__c WHERE celsrm__ListView_For_Object__c = :objectName ';
 			if (!String.isBlank(folderName)) {
                query += 'AND Folder_Name__c = :folderName ';
            }
			query += 'AND (celsrm__Is_Global__c = TRUE OR CreatedById = :currUser ';
			if (!groupIdsAsStrings.isEmpty()) {
                   String includesClause = 'Group_User_Id__c INCLUDES (' + String.join(groupIdsAsStrings, ', ') + ')';
                   query += 'OR (' + includesClause + ' AND celsrm__Is_Global__c = FALSE) ';
            } 
            query += ')';
            System.debug('@@@ final query ' + query);
            List<celsrm__Custom_List_View__c> obj = Database.query(query);
            
            Map<String,String> tmp;
            for(celsrm__Custom_List_View__c o : obj) {
                tmp = new Map<String,String>();
                tmp.put('label', o.Name);
                tmp.put('value', o.Id);
                returnOptions.add(tmp);
            }
           
        } catch(Exception e) {
            throw new celsrm.GOGDataServiceLoadException(e.getMessage());
        }
        inMap.put('dataServiceResponse', returnOptions);
         
        
        return inMap;
    }
}