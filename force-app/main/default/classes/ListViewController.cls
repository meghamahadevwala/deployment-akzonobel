global with sharing class ListViewController implements celsrm.GOGIScreenCustomLogic {
    global Map<Object, Object> invoke(String functionName, Map<Object, Object> inMap) {
        if(functionName == 'getObjectFields') {
            return ListViewController.getObjectFields(inMap);
        } else if(functionName == 'getNewListView') {
            return ListViewController.getNewListView(inMap);
        } else if(functionName == 'deleteListView') {
            return ListViewController.deleteListView(inMap);
        } else if (functionName == 'getListView') {
            return ListViewController.getListView(inMap, false);
        } else if (functionName == 'changeListView') {
            return ListViewController.getListView(inMap, true);
        } else if (functionName == 'saveListView') {
            return ListViewController.saveListView(inMap);
        } else if(functionName == 'getUserGroup'){
            return ListViewController.getUserGroup(inMap);
        }
        return null;
    }

    public static Map<Object, Object> getObjectFields(Map<Object, Object> inMap) {
        Map<Object, Object> newInMap = new Map<Object, Object>();
        if(!inMap.containsKey('ListViewObject') || inMap.get('ListViewObject') == null || inMap.get('ListViewObject') == '') {
            throw new celsrm.GOGDataServiceLoadException('List View Object is not specified');
        }
        String sObjectName = String.valueOf(inMap.get('ListViewObject'));
        system.debug('-sObjectName-' + sObjectName); 
        // if(sObjectName != '' && sObjectName != null) {
            Map<String,Schema.SObjectType> objList = Schema.getGlobalDescribe(); 
            Schema.SObjectType sobjType = objList.get(sObjectName); 
            if(sobjType != null){
                Schema.DescribeSObjectResult describeResult = sobjType.getDescribe(); 
                Map<String,Schema.SObjectField> fieldMap = describeResult.fields.getMap(); 
                List<Map<String,String>> fieldList = new List<Map<String,String>>(); 

                for(String fieldname : fieldMap.keySet()){ 
                    Map<String, String> customField = new Map<String, String>();
                    customField.put('label',fieldMap.get(fieldname).getDescribe().getLabel());
                    customField.put('value',fieldMap.get(fieldname).getDescribe().getName());
                    fieldList.add(customField);
                }                               
                system.debug('-fieldList-'+fieldList);
                newInMap.put('dataServiceResponse', fieldList); 
            } else {
                throw new celsrm.GOGDataServiceLoadException('Invalid List View Object');
            }
        return newInMap;
        // } else {
        //     List<Map<String,String>> fieldList = new List<Map<String,String>>(); 
        //     return fieldList;
        // }
    }

    public static Map<Object, Object> getNewListView(Map<Object, Object> inMap) {
        Map<Object, Object> newInMap = new Map<Object, Object>();
        // << START - MM - FIN-9671 - [Nouryon] [Collections] Read only listview radio button for all profiles except System Admin >>
        if(UserInfo.getUserId() != null) {
            List<User> lstProfile = [SELECT Profile.Name FROM User where Id = :UserInfo.getUserId()];
            if(lstProfile != null && lstProfile.size() > 0)
            {
                string profileType = lstProfile[0].Profile.Name;
                if(profileType.toLowerCase().contains('administrator') || profileType.toLowerCase().contains('super user') || profileType.toLowerCase().contains('superuser') || profileType.toLowerCase().contains('central') || profileType.toLowerCase().contains('manager') || profileType.toLowerCase().contains('lead') || profileType.toLowerCase().contains('technical')) {
                    newInMap.put('isSuperUser', 'true');
                }else{
                    newInMap.put('isSuperUser', 'false');
                }    
            }
        }
        // << END - MM - FIN-9671 - [Nouryon] [Collections] Read only listview radio button for all profiles except System Admin >>
        newInMap.put('ActionName', 'New');
        newInMap.put('ListViewName', '');
        newInMap.put('Default', false);
        newInMap.put('Global', false);
        newInMap.put('CriteriaGrid', null);
        newInMap.put('ColumnConfig', null);
        newInMap.put('SortingGrid', null);
        newInMap.put('listViewPermission', 'default');
		List<String> defaultColumns = new List<String>{'Id', 'Name'};
        List<Map<String, Object>> columns = new List<Map<String, Object>>();
        for(String col: defaultColumns) {
            Map<String, Object> colConfig = new Map<String, Object>();
            colConfig.put('enableCopy', false);
            colConfig.put('isExport', false);
            colConfig.put('hide', true);
            colConfig.put('hideLabel', true);
            colConfig.put('onClickFunction', null);
            colConfig.put('iconClassMap', false);
            colConfig.put('iconFlag', false);
            colConfig.put('iconName', null);
            colConfig.put('width', null);
            colConfig.put('defaultField', true);
            if(col == 'Name') {
                colConfig.put('type', 'link');
            } else {
                colConfig.put('type', 'text');
            }
            colConfig.put('fieldName', col);
            colConfig.put('notEditable', true);
            colConfig.put('MoveRowArea', '<img src="/resource/CustomResource/image/arrow_up.png" class="up" width="15" height="15" ></img><img src="/resource/CustomResource/image/arrow_down.png" class="down" width="15" height="15" ></img>');
            columns.add(colConfig);
        }
        newInMap.put('ColumnConfig', columns);
        return newInMap;
    }

    public static Map<Object, Object> deleteListView(Map<Object, Object> inMap) {
        String listViewId = String.valueOf(inMap.get('ListView'));
        celsrm__Custom_List_View__c obj = new celsrm__Custom_List_View__c(Id=listViewId);
        delete obj;
        String currUser = UserInfo.getUserId();
        String objectName = String.valueOf(inMap.get('ListViewObject'));
        List<celsrm__Custom_List_View__c> dbView = new List<celsrm__Custom_List_View__c>();
         dbView = [Select Id, Name, celsrm__Object_Fields__c, celsrm__Filter_Criteria__c From celsrm__Custom_List_View__c Where celsrm__ListView_For_Object__c =: objectName and celsrm__Is_Default__c = true and (CreatedById = :currUser or celsrm__Is_Global__c = true) order by celsrm__Is_Global__c];
        if(dbView != null && dbView.size() == 0) {
            dbView = [Select Id, Name, celsrm__Object_Fields__c, celsrm__Filter_Criteria__c From celsrm__Custom_List_View__c Where celsrm__ListView_For_Object__c =: objectName and (CreatedById = :currUser or celsrm__Is_Global__c = true) order by celsrm__Is_Global__c limit 1];    
        } 
        inMap.put('ListView',dbView.get(0).Id);
        //By Ravi | 12-02-2020 | user preference
        celsrm__User_Preference__c userPref  = new celsrm__User_Preference__c();
        try {
            userPref = [SELECT Id,celsrm__SelectedTransactionListView__c,celsrm__sendStatementListView__c,celsrm__SelectedDisputeListView__c FROM celsrm__User_Preference__c WHERE celsrm__User__c =:currUser LIMIT 1];
        } catch (Exception e) {
            System.debug('exception>> ' + e.getMessage());
        }
        if (objectName.equalsIgnoreCase('celsrm__Transaction__c')) {
            userPref.celsrm__SelectedTransactionListView__c = dbView.get(0).Id;
            if (userPref != null && userPref.celsrm__sendStatementListView__c == listViewId) {
                userPref.celsrm__sendStatementListView__c = '';
            }
        } else {
            userPref.celsrm__SelectedDisputeListView__c = dbView.get(0).Id;
        }
        userPref.celsrm__User__c = currUser;
        upsert userPref;
        //By Ravi | 12-02-2020 | user preference
        return inMap;
    }

    public static Map<Object, Object> getListView(Map<Object, Object> inMap, Boolean isChangeListView) {
        system.debug('inmap val is>>>>>>'+inMap.get('ListView'));
        //-- Start | FIN-8168 | Changed by Asera | 11 Aug 2025 --//
        Id recordId = null;
        String lvIdStr = (String)inMap.get('ListView');
        if (String.isNotBlank(lvIdStr)){
            recordId = (Id)lvIdStr;
        } 
        //-- End | FIN-8168 | Changed by Asera | 11 Aug 2025 --//
        String currUser = UserInfo.getUserId();
        String objectName = String.valueOf(inMap.get('ListViewObject'));
        system.debug('recordId>>>>>>>'+recordId);
        List<User> lstProfile = null;
        String isSysAdmin;
        lstProfile = [SELECT Profile.Name, TimeZoneSidKey, LocaleSidKey FROM User where Id = :UserInfo.getUserId()];
        if(lstProfile != null)
        {
            string profileType = lstProfile[0].Profile.Name;
              if(profileType.contains('Administrator')){
                isSysAdmin = 'true';
              }else{
                isSysAdmin = 'false';
              } 
            // << START - MM - FIN-9671 - [Nouryon] [Collections] Read only listview radio button for all profiles except System Admin >>
            if(profileType.toLowerCase().contains('administrator') || profileType.toLowerCase().contains('super user') || profileType.toLowerCase().contains('superuser') || profileType.toLowerCase().contains('central') || profileType.toLowerCase().contains('manager') || profileType.toLowerCase().contains('lead') || profileType.toLowerCase().contains('technical')) {
                inMap.put('isSuperUser', 'true');
            } else{
                inMap.put('isSuperUser', 'false');
            }
            // << END - MM - FIN-9671 - [Nouryon] [Collections] Read only listview radio button for all profiles except System Admin >>   
        }
        
        inMap.put('isSysAdmin',isSysAdmin);
        if( inMap.get('ScreenName') != 'ListViewNew' && recordId != null ){  //-- Added condtion | FIN-8168 | Changed by Asera | 11 Aug 2025 --//
            celsrm__Custom_List_View__c listView = [SELECT Id, Name, celsrm__Filter_Criteria__c, celsrm__Object_Fields__c, celsrm__Is_Default__c, celsrm__Is_Global__c, celsrm__Sort_By_Field__c, celsrm__Sort_By_Order__c, OwnerId, Folder_Name__c, Group_User_Id__c from celsrm__Custom_List_View__c where id =: recordId limit 1];
            if(listView != null){
                if((listView.OwnerId).equals(currUser)) {
                    inMap.put('isCurrentUserListView', 'true');
                } else {
                    inMap.put('isCurrentUserListView', 'false');
                }
                List<Map<String, Object>> criteriaList = new List<Map<String, Object>>();
                system.debug('listView>>>>>>>'+listView);
                if(String.isNotBlank(listView.celsrm__Filter_Criteria__c)){
                    system.debug('listView.celsrm__Filter_Criteria__c>>>>>>>'+listView.celsrm__Filter_Criteria__c);
                    Map<String, Object> criteriaObject = (Map<String, Object>)JSON.deserializeUntyped(listView.celsrm__Filter_Criteria__c);
                    inMap.put('FilterCondition', String.valueOf(criteriaObject.get('condition')));
                    List<Object> rawCriteriaList = (List<Object>)criteriaObject.get('criterias');
                    for (Object item : rawCriteriaList) {
                        Map<String, Object> criteria = (Map<String, Object>)item;
                        criteriaList.add(criteria);
                    }
                    inMap.put('CriteriaGrid', criteriaList);
                }else{
                    //blank array 
                    inMap.put('CriteriaGrid', new List<Map<String, String>>());
                }
                
                inMap.put('Default',listView.celsrm__Is_Default__c);
                if(listView.celsrm__Is_Global__c){
                    inMap.put('listViewPermission','global');
                } else if(listView.Group_User_Id__c != null){
                    inMap.put('listViewPermission','userGroup');
                    inMap.put('userGorup',listView.Group_User_Id__c);

                    List<String> groupIdList = listView.Group_User_Id__c.split(';');
                    String query = 'SELECT Id, Name FROM Group WHERE Id IN (\'' + String.join(groupIdList, '\',\'') + '\')';
                    System.debug('@@@ final query ' + query);                   
                    List<Group> obj = Database.query(query);
                    String htmlLinksForGroup = '';
                    for (Group g : obj) {
                        String url = '/lightning/r/Group/' + g.Id + '/view'; // Adjust URL for your Salesforce instance
                        htmlLinksForGroup += g.Name + '<br/>';
                    }
                    inMap.put('listViewUserGroup',htmlLinksForGroup); 
                } else {
                    inMap.put('listViewPermission','default');
                }
                if(isSysAdmin == 'true'){
                    inMap.put('Global',listView.celsrm__Is_Global__c);
                }
                if ((inMap.get('ScreenName') != null && ((String)inMap.get('ScreenName')).equalsIgnoreCase('ListViewClone')) || (inMap.get('ActionName') != null && ((String)inMap.get('ActionName')).equalsIgnoreCase('Clone'))) {
                    inMap.put('ListViewName','Clone ' + listView.Name);
                } else  {
                    inMap.put('ListViewName',listView.Name);
                }
                // To populate column config in datagrid - START
                List<Map<String, Object>> columnList = new List<Map<String, Object>>();
                List<String> fieldList = new List<String>();
                List<String> defaultColumns = new List<String>{'Name', 'Id'};
                if(String.isNotBlank(listView.celsrm__Object_Fields__c)){
                    system.debug('listView.celsrm__Object_Fields__c>>>>>>>'+listView.celsrm__Object_Fields__c);
                    List<Object> parsedJson = (List<Object>) JSON.deserializeUntyped(listView.celsrm__Object_Fields__c);

                    for(Object obj : parsedJson) {
                        Map<String, Object> resultMap = (Map<String, Object>)obj;
                        String fName = String.valueOf(resultMap.get('fieldName'));
                        if(fName != null && fName != '' && defaultColumns.contains(fName) && !fieldList.contains(fName)) {
                            if(fName == 'Id' && String.valueOf(resultMap.get('type')) == 'text') {
                                resultMap.put('defaultField', true);
                            } else if(fName == 'Name' && String.valueOf(resultMap.get('type')) == 'link'){
                                resultMap.put('defaultField', true);
                            }
                        }
                        fieldList.add(fName);
                        resultMap.put('MoveRowArea', '<img src="/resource/CustomResource/image/arrow_up.png" class="up" width="15" height="15" ></img><img src="/resource/CustomResource/image/arrow_down.png" class="down" width="15" height="15" ></img>');
                        columnList.add(resultMap);
                    }
                }
                for(String col: defaultColumns) {
                    if(fieldList.size() == 0 || !fieldList.contains(col)) {
                        Map<String, Object> colConfig = new Map<String, Object>();
                        colConfig.put('enableCopy', false);
                        colConfig.put('isExport', false);
                        colConfig.put('hide', true);
                        colConfig.put('hideLabel', true);
                        colConfig.put('onClickFunction', null);
                        colConfig.put('iconClassMap', false);
                        colConfig.put('iconFlag', false);
                        colConfig.put('iconName', null);
                        colConfig.put('width', null);
                        colConfig.put('defaultField', true);
                        if(col == 'Name') {
                            colConfig.put('type', 'link');
                        } else {
                            colConfig.put('type', 'text');
                        }
                        colConfig.put('fieldName', col);
                        colConfig.put('notEditable', true);
                        colConfig.put('MoveRowArea', '<img src="/resource/CustomResource/image/arrow_up.png" class="up" width="15" height="15" ></img><img src="/resource/CustomResource/image/arrow_down.png" class="down" width="15" height="15" ></img>');
                        if(columnList.size() == 0) {
                            columnList.add(colConfig);
                        } else {
                            columnList.add(0, colConfig);
                        }
                    }
                }
                inMap.put('ColumnConfig', columnList);
                // To populate column config in datagrid - START
                List<Map<String, String>> sortBy = new List<Map<String, String>>();
                if(listView.celsrm__Sort_By_Field__c != null && listView.celsrm__Sort_By_Field__c != '') {
                    sortBy =(List<Map<String, String>>) JSON.deserialize(listView.celsrm__Sort_By_Field__c, List<Map<String, String>>.class);
                    for(Map<String,String> sb: sortBy) {
                        if(sb.get('order') == 'ASC') {
                            sb.put('sortDirection', '<img src="/resource/CustomResource/image/sort_asc.png" class="asc" width="15" height="15"></img>');
                        } else if(sb.get('order') == 'DESC') {
                            sb.put('sortDirection', '<img src="/resource/CustomResource/image/sort_desc.png" class="desc" width="15" height="15"></img>');
                        }
                    }
                }
                
                inMap.put('SortingGrid', sortBy);
                inMap.put('ListViewFolderName', listView.Folder_Name__c);
                if (isChangeListView == true) {
                    inMap.put('UserName', UserInfo.getName());
                    Map<string, Schema.sObjectType> describeInfo = Schema.getGlobalDescribe();
                    Map<String, Schema.SObjectField> fMap = new Map<String, Schema.SObjectField>();
                    if (objectName != null && objectName != '') {
                        fMap = describeInfo.get(objectName).getDescribe().Fields.getMap();
                    }
                    for (Map<String, Object> criteria : criteriaList) {
                        criteria.put('fieldName', fMap.get((String.valueOf(criteria.get('fieldName'))).toLowerCase()).getDescribe().getLabel()); 
                    }
                    for (Map<String, String> sb : sortBy) {
                        sb.put('fieldName', fMap.get((String.valueOf(sb.get('fieldName'))).toLowerCase()).getDescribe().getLabel()); 
                    }
                    for (Map<String, Object> sb : columnList) {
                        sb.put('fieldName', fMap.get((String.valueOf(String.valueOf(sb.get('fieldName')))).toLowerCase()).getDescribe().getLabel()); 
                    }
                    inMap.put('CriteriaGrid', criteriaList );
                    inMap.put('SortingGrid', sortBy );
                    inMap.put('ColumnConfig', columnList );
                }
            }
        }
        return inMap;
    }

    public static Map<Object,Object> saveListView(Map<Object, Object> inMap) {
        system.debug('inmap val is'+inMap);
        if(!inMap.containsKey('ListViewObject') || inMap.get('ListViewObject') == null || inMap.get('ListViewObject') == '') {
            throw new celsrm.GOGDataServiceLoadException('List View Object is not specified');
        }
        if(!inMap.containsKey('ColumnConfig') || inMap.get('ColumnConfig') == null || inMap.get('ColumnConfig') == '') {
            throw new celsrm.GOGDataServiceLoadException('Column Config is not specified');
        }
        
        if(!inMap.containsKey('ListViewParentField') || inMap.get('ListViewParentField') == null || inMap.get('ListViewParentField') == '') {
            throw new celsrm.GOGDataServiceLoadException('Parent Field Api name is not specified.');
        }
        
        if(!inMap.containsKey('ListViewName') || inMap.get('ListViewName') == null || inMap.get('ListViewName') == '') {
            throw new celsrm.GOGDataServiceLoadException('List view name is not specified.');
        }
        
        system.debug('inMap.getCriteriaGrid'+inMap.get('CriteriaGrid'));
        system.debug('inMap.SortingGrid'+inMap.get('SortingGrid'));
        system.debug('inMap.ColumnConfig'+inMap.get('ColumnConfig'));
        //-- Start | FIN-9820 | Changed by Dhwanil | 22 May 2026 --// --
        List<Object> columnConfigsNew = (List<Object>) inMap.get('ColumnConfig');
        Set<String> selectedListViewFields = new Set<String>();
        for(Object obj: columnConfigsNew) {
            Map<Object,Object> colConfig = (Map<Object, Object>)obj;
            if(colConfig.get('fieldName') != null && String.valueOf(colConfig.get('fieldName')).trim() != '') {
                String fieldName = String.valueOf(colConfig.get('fieldName')).trim().toLowerCase();
                if(selectedListViewFields.contains(fieldName)) {
                    throw new celsrm.GOGDataServiceLoadException('Same field cannot be selected more than once.');
                }
                selectedListViewFields.add(fieldName);
            }
        }
        //-- End | FIN-9820 | Changed by Dhwanil | 22 May 2026 --//
        if(!inMap.containsKey('CriteriaGrid') || inMap.get('CriteriaGrid') == null || ((List<Object>)inMap.get('CriteriaGrid')).size() == 0) {
            throw new celsrm.GOGDataServiceLoadException('Atleast one filter criteria should be added.');
        }
        // if(inMap.containsKey('CriteriaGrid') && ((List<Object>)inMap.get('CriteriaGrid')).size() > 0) {
        //     Integer len = ((List<Object>)inMap.get('CriteriaGrid')).size() - 1;
        //     for (Integer i = 0; i < len; i++) {
        //         Map<Object,Object> tempCriteria =  (Map<Object,Object>)(((List<Object>)inMap.get('CriteriaGrid')).get(i));
        //         if (!tempCriteria.containsKey('LogicalOperator') || tempCriteria.get('LogicalOperator') == null || tempCriteria.get('LogicalOperator') == '') {
        //             throw new celsrm.GOGDataServiceLoadException('Enter the criteria Logical Operator in index ' + (i+1) + '.');
        //             break;
        //         }
        //     }
        //     // for (Object criteria : (List<Object>)inMap.get('CriteriaGrid')) {
        //     //     Map<Object,Object> tempCriteria =  (Map<Object,Object>)criteria;
        //     //     if (!tempCriteria.containsKey('LogicalOperator') || tempCriteria.get('LogicalOperator') == null) {
        //     //         throw new celsrm.GOGDataServiceLoadException('Enter the Logical Operator.');
        //     //         break;
        //     //     }
        //     // }
        // }
        List<Object> lst = ((List<Object>)inMap.get('CriteriaGrid'));
        system.debug('lst>>>>>'+lst);
        for(Object o : lst) {
            Map<Object, Object> m = (Map<Object, Object>)o;
            if(m.get('fieldName') == null || String.valueOf(m.get('fieldName')) == '') {
                throw new celsrm.GOGDataServiceLoadException('Please select field');
            } else if(m.get('operator') == null || String.valueOf(m.get('operator')) == '') {
                throw new celsrm.GOGDataServiceLoadException('Please select Operator');
            }
        }
        for(Object o : lst) {
            Map<Object, Object> m = (Map<Object, Object>)o;
            for (object field : m.keySet()) {
                String fld = String.valueOf(field);
                if (!fld.equalsIgnoreCase('fieldName') && !fld.equalsIgnoreCase('operator') && !fld.equalsIgnoreCase('value') && !fld.equalsIgnoreCase('type')) {
                    m.remove(fld);
                }
            }
        }

        String sortingJson = ''; 
        if(inMap.get('SortingGrid') != null) {
            List<Object> sortingList = ((List<Object>)inMap.get('SortingGrid'));
            Integer rowNum = 0;
            
            for(Object o : sortingList) {
                Map<Object, Object> m = (Map<Object, Object>)o;
                for (object field : m.keySet()) {
                    String fld = String.valueOf(field);
                    if (!fld.equalsIgnoreCase('fieldName') && !fld.equalsIgnoreCase('order')) {
                        m.remove(fld);
                    }
                }
                rowNum ++;
            }
            sortingJson = JSON.serialize(sortingList);
        }
        Map<String, Object> criteriaConfig = new Map<String, Object>();
        criteriaConfig.put('criterias', lst);
        criteriaConfig.put('condition', inMap.get('FilterCondition'));
        String jsonString = '';
        try {      
            Map<string, Schema.sObjectType> describeInfo = Schema.getGlobalDescribe();
            Map<String, Schema.SObjectField> fMap = describeInfo.get(String.valueOf(inMap.get('ListViewObject')).toLowerCase()).getDescribe().Fields.getMap();
            List<Object> columnConfigs = (List<Object>) inMap.get('ColumnConfig');
            List<Map<Object,Object>> datagridCols = new List<Map<Object,Object>>();
            for(Object obj: columnConfigs) {
                Map<Object,Object> colConfig = (Map<Object, Object>)obj;
                
                Map<Object,Object> datagridCol = new Map<Object, Object>();
                // datagridCol.put('label', String.valueOf(fMap.get(String.valueOf(colConfig.get('fieldName'))).getDescribe().getLabel()));
                datagridCol.put('fieldName', String.valueOf(colConfig.get('fieldName')));
                datagridCol.put('type', String.valueOf(colConfig.get('type')));
                //-- Starts | FIN-5698 | Changes By: Dilshad | 06 June 2024 --//
                datagridCol.put('width', colConfig.get('width') != null && colConfig.get('width') != '' ? String.valueOf(colConfig.get('width')) : '');
                //-- Ends | FIN-5698 | Changes By: Dilshad | 06 June 2024 --//
                if(colConfig.get('iconName') != null && colConfig.get('iconName') != '') {
                    datagridCol.put('iconName', String.valueOf(colConfig.get('iconName')));
                    datagridCol.put('iconFlag', true);
                    datagridCol.put('selectIcon', false);
                } else {
                    datagridCol.put('iconName', '');
                    datagridCol.put('iconFlag', false);
                }
                datagridCol.put('iconClassMap', false);
                datagridCol.put('isAggregate', false);
                datagridCol.put('onClickFunction', colConfig.get('onClickFunction') != null && colConfig.get('onClickFunction') != '' ? String.valueOf(colConfig.get('onClickFunction')) : '');
                datagridCol.put('hide', colConfig.get('hide'));
                datagridCol.put('hideLabel', colConfig.get('hideLabel'));
                datagridCol.put('isExport', colConfig.get('isExport'));
                datagridCol.put('enableCopy', colConfig.get('enableCopy'));
                // datagridCol.put('alternativeTextEnable', false);

                datagridCols.add(datagridCol);
            }
            jsonString = JSON.serialize(datagridCols);
            
        } catch(Exception ex) { 
            System.debug('Error:'+ex.getStackTraceString());
        }

        try {
            Map<String, Object> refreshParentValues = new Map<String, Object>();
            String objectName = String.valueOf(inMap.get('ListViewObject'));
            String objectParentField = String.valueOf(inMap.get('ListViewParentField'));
            system.debug('inMap.get>>>>>>>>>>>'+inMap.get('SelectField'));
            celsrm__Custom_List_View__c obj = new celsrm__Custom_List_View__c();
            obj.Name = String.valueOf(inMap.get('ListViewName'));
            obj.celsrm__Filter_Criteria__c = JSON.serialize(criteriaConfig);
            obj.celsrm__Is_Default__c = (inMap.get('Default') != null ? (Boolean)inMap.get('Default') : false );
           // obj.celsrm__Is_Global__c = (inMap.get('Global') != null ? (Boolean)inMap.get('Global') : false );
           if(inMap.containsKey('listViewPermission') && inMap.get('listViewPermission') != null){
                if(inMap.get('listViewPermission') == 'default'){
                    obj.celsrm__Is_Global__c = false;
                    obj.Group_User_Id__c = ''; 
                } else if(inMap.get('listViewPermission') == 'global'){
                    obj.celsrm__Is_Global__c = true;
                    obj.Group_User_Id__c = ''; 
                } else if(inMap.get('listViewPermission') == 'userGroup'){
                    obj.celsrm__Is_Global__c = false;
                    obj.Group_User_Id__c = inMap.get('userGorup') != null ?  String.valueOf(inMap.get('userGorup')) : '';
                }
            }
            obj.celsrm__ListView_For_Object__c = objectName;
            // obj.celsrm__Object_Fields__c = (inMap.get('SelectField') != null ? String.valueOf(inMap.get('SelectField')) : '' );
            obj.celsrm__Object_Fields__c = jsonString;
            obj.celsrm__Sort_By_Field__c = sortingJson;
            // obj.celsrm__Sort_By_Order__c = (inMap.get('SortDirection') != null ? String.valueOf(inMap.get('SortDirection')) : '');
            obj.Folder_Name__c = (inMap.get('ListViewFolderName') != null ? String.valueOf(inMap.get('ListViewFolderName')) : '');

            system.debug('obj>>>>>>>>>>>'+obj);
            system.debug('ListView>>>>>>>>>>>'+inMap.containsKey('ListView'));
            system.debug('Operation>>>>>>>>>>>'+inMap.containsKey('Operation'));
            if((inMap.containsKey('Operation') && inMap.containsKey('ListView') && inMap.get('ListView') != null && inMap.get('ListView') != '') || (inMap.get('ActionName') != null && ((String)inMap.get('ActionName')).equalsIgnoreCase('Edit'))) {
                obj.Id = String.valueOf(inMap.get('ListView'));
                refreshParentValues.put('ListViewEditMode', true);       
            } else {
                refreshParentValues.put('ListViewEditMode', false);       
            }
            upsert obj;      

            //By Ravi | 12-02-2020 | user preference
            String currentUser = UserInfo.getUserId();
            String folderName = String.valueOf(inMap.get('ListViewFolderName'));
            celsrm__User_Preference__c userPref  = null;
            try {
                if(folderName != null || folderName != '') {
                    userPref = [SELECT Id FROM celsrm__User_Preference__c WHERE celsrm__User__c =:currentUser AND celsrm__List_View_Folder__c =:folderName LIMIT 1];
                } else {
                    userPref = [SELECT Id FROM celsrm__User_Preference__c WHERE celsrm__User__c =:currentUser LIMIT 1];
                }
            } catch (Exception e) {
                System.debug('exception>> ' + e.getMessage());
                userPref = null;
            }
            if(userPref == null) {
                userPref = new celsrm__User_Preference__c();
                userPref.celsrm__User__c = UserInfo.getUserId();
                userPref.celsrm__List_View_Folder__c = folderName;
            }
            if (objectName.equalsIgnoreCase('celsrm__Transaction__c')) {
                userPref.celsrm__SelectedTransactionListView__c = obj.Id;
                // if (inMap.get('SortField') != null) {
                //     userPref.celsrm__SortListViewField__c = String.valueOf(inMap.get('SortField'));
                // }
                // if (inMap.get('SortDirection') != null) {
                //     userPref.celsrm__SortListViewOrderType__c = String.valueOf(inMap.get('SortDirection'));
                // }
                
            } else {
                userPref.celsrm__SelectedDisputeListView__c = obj.Id;
                //  if (inMap.get('SortField') != null) {
                //     userPref.celsrm__DisputeSortListViewField__c = String.valueOf(inMap.get('SortField'));
                // }
                // if (inMap.get('SortDirection') != null) {
                //     userPref.celsrm__DisputeSortListViewOrderType__c = String.valueOf(inMap.get('SortDirection'));
                // }
            }
            // userPref.celsrm__User__c = currentUser;
            upsert userPref;
            //By Ravi | 12-02-2020 | user preference

            if(inMap.containsKey('ListView')) {
             
               // refreshParentValues.put('name', 'ListView');
                refreshParentValues.put('ListView',obj.Id);
                List<Map<String,String>> returnOptions = new List<Map<string,String>>();
                Map<String,String> tmp = new Map<String,String>();
                tmp.put('label', obj.Name);
                tmp.put('value', obj.Id);
                returnOptions.add(tmp);
                refreshParentValues.put('selectedListViewOption', returnOptions);
               // refreshParentValues.put('label',obj.Name);
                if(objectName == 'celsrm__Dispute__c') {
                    // if((String)inMap.get('ggScreenName') == 'ListViewNew' || (String)inMap.get('ggScreenName') == 'ListViewClone'){
                         refreshParentValues.put('onChangeMethod','OnChangeViewCreateDispute');                  
                    //  }else{
                    //     refreshParentValues.put('onChangeMethod','filterDataByViewDispute');
                    //  }
                } else {
                    //  if((String)inMap.get('ggScreenName') == 'ListViewNew' || (String)inMap.get('ggScreenName') == 'ListViewClone'){
                         refreshParentValues.put('onChangeMethod','OnChangeViewCreate');                  
                    //  }else{
                    //     refreshParentValues.put('onChangeMethod','filterDataByView');
                    //  }
                }
                
            }
        
            System.debug('@@@ refreshParentValues : '  +refreshParentValues);
            inMap.put('refreshParentValues', refreshParentValues);
        } catch(Exception e) {
            //-- FIN-9821 | Changed by Dilshad | 25-May-2026 | Start --//
            if(e.getMessage().contains('DUPLICATES_DETECTED')) {
                inMap.put('ggErrorMessage', Label.Duplicate_List_View);
                return inMap;
            }
            //-- FIN-9821 | Changed by Dilshad | 25-May-2026 | End --//
            
            throw new celsrm.GOGDataServiceLoadException(e.getMessage());
        }
        //inMap.put('dataServiceResponse', returnOptions);
        
        return inMap;
    }

    public static Map<Object, Object> getUserGroup(Map<Object, Object> inMap) {
        List<Map<String,String>> returnOptions = new List<Map<string,String>>();        
        //-- Starts | FIN-7926 | Changes By: Ravi | 4 sep 2025 --//
        String query = 'SELECT Id, Name,Type FROM Group WHERE  Type IN (\'Regular\', \'Queue\')';
        //-- End | FIN-7926 | Changes By: Ravi | 4 sep 2025 --//
        System.debug('@@@ final query ' + query);
        List<Group> obj = Database.query(query);
        Map<String,String> tmp;
        for(Group o : obj) {
            tmp = new Map<String,String>();
            tmp.put('label', o.Name);
            tmp.put('value', o.Id);
            returnOptions.add(tmp);
        }
        inMap.put('dataServiceResponse', returnOptions);
        return inMap;
    }
}