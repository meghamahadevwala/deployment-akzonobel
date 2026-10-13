// global with sharing class defaultViewClass implements celsrm.GOGIScreenCustomLogic {
//     global Map<Object, Object> invoke(String functionName, Map<Object, Object> inMap) {
//         if(functionName == 'OnLoadTransform'){
//             System.debug('inMap>> ' + inMap);
//             List<Object> response = (List<Object>)inMap.get('dataServiceResponse');
//             List<Object> newResponse = new List<Object>();
//             for(Object res : response) {
//                 Map<String,Object> tempMap = (Map<String,Object>)res;
//                 String name = String.valueOf(tempMap.get('disputeName'));
//                 Id disputeid= (Id)tempMap.get('Id');
//                 String key = '<a href="' + '/'+ disputeid + '"' + ' target="_blank">' + name + '</a>';
//                 tempMap.put('Name',key);
//                 newResponse.add(tempMap);
//             }
//             inMap.put('dataServiceResponse', newResponse);
//         } else {
//             try {
//                 if(!inMap.containsKey('ListViewObject') || inMap.get('ListViewObject') == null || inMap.get('ListViewObject') == '') {
//                     throw new celsrm.GOGDataServiceLoadException('List View Object is not specified');
//                 }
                
//                 if(!inMap.containsKey('ListViewParentField') || inMap.get('ListViewParentField') == null || inMap.get('ListViewParentField') == '') {
//                     throw new celsrm.GOGDataServiceLoadException('Parent Field Api name is not specified.');
//                 }
//                 String objectName = String.valueOf(inMap.get('ListViewObject'));
//                 String parentFieldApiName = String.valueOf(inMap.get('ListViewParentField'));
//                 String parentRecordID = String.valueOf(inMap.get('Id'));    
//                 String currUser = UserInfo.getUserId();
//                 String RefFields='';
//                 celsrm__User_Preference__c userPref  = new celsrm__User_Preference__c();
//                 try {
//                     String query= '';
//                     if (objectName.equalsIgnoreCase('celsrm__Transaction__c')) {
//                         query = 'SELECT Id, celsrm__SortListViewOrderType__c, celsrm__SortListViewField__c, celsrm__SelectedTransactionListView__c FROM celsrm__User_Preference__c WHERE celsrm__User__c =:currUser LIMIT 1';
//                     } else {
//                         query = 'SELECT Id, celsrm__DisputeSortListViewField__c, celsrm__DisputeSortListViewOrderType__c, celsrm__SelectedDisputeListView__c FROM celsrm__User_Preference__c WHERE celsrm__User__c =:currUser LIMIT 1';
//                     }
                    
//                     for (celsrm__User_Preference__c userPrefObj : Database.query(query)) {
//                         userPref = userPrefObj;
//                     }
//                 } catch (Exception e) {
//                     System.debug('exception>> ' + e.getMessage());
//                 }
//                 List<celsrm__Custom_List_View__c> dbView = new List<celsrm__Custom_List_View__c>();
//                 if (objectName.equalsIgnoreCase('celsrm__Transaction__c') && userPref != null && userPref.celsrm__SelectedTransactionListView__c != null) {
//                     dbView = [Select Id, CreatedById,Name, celsrm__Object_Fields__c, celsrm__Filter_Criteria__c, celsrm__Sort_By_Field__c, celsrm__Sort_By_Order__c From celsrm__Custom_List_View__c Where Id =: userPref.celsrm__SelectedTransactionListView__c LIMIT 1];
//                 } else if (objectName.equalsIgnoreCase('celsrm__Dispute__c') && userPref != null && userPref.celsrm__SelectedDisputeListView__c != null) {
//                     dbView = [Select Id, CreatedById,Name, celsrm__Object_Fields__c, celsrm__Filter_Criteria__c, celsrm__Sort_By_Field__c, celsrm__Sort_By_Order__c From celsrm__Custom_List_View__c Where Id =: userPref.celsrm__SelectedDisputeListView__c LIMIT 1 ];
//                 } else {
//                     dbView = [Select Id, CreatedById, Name, celsrm__Object_Fields__c, celsrm__Filter_Criteria__c, celsrm__Sort_By_Field__c, celsrm__Sort_By_Order__c From celsrm__Custom_List_View__c Where celsrm__ListView_For_Object__c =: objectName and celsrm__Is_Default__c = true and (CreatedById = :currUser or celsrm__Is_Global__c = true) order by CreatedDate DESC];
//                 } 
//                 if(dbView != null && dbView.size() == 0) {
//                     dbView = [Select Id, CreatedById, Name, celsrm__Object_Fields__c, celsrm__Filter_Criteria__c, celsrm__Sort_By_Field__c, celsrm__Sort_By_Order__c From celsrm__Custom_List_View__c Where celsrm__ListView_For_Object__c =: objectName and (CreatedById = :currUser or celsrm__Is_Global__c = true) order by CreatedDate DESC limit 1];    
//                 }
//                 Map<String, Schema.SObjectField> fMap;
//                 if(dbView != null && dbView.size() > 0) {
//                     String selectfields = '';
//                     Set<string> cFieldSet = new Set<string> ();
                    
//                     try {
                        
//                         Map<string, Schema.sObjectType> describeInfo = Schema.getGlobalDescribe();
//                         fMap = describeInfo.get(objectName.toLowerCase()).getDescribe().Fields.getMap();
                        
//                         if (fMap != null) {
//                             for (String field : fMap.keySet()) {
//                                 field = field.toLowerCase();
//                                 Schema.SObjectField f = fMap.get(field);
//                                 Schema.DescribeFieldResult tempObj = f.getDescribe();
//                                 if (!cFieldSet.contains(field)) {
//                                     selectfields += field + ',';
//                                 }        
//                             }
//                         }
//                         selectfields = selectfields.removeEnd(',');
                        
//                     } catch(Exception ex) { 
//                         System.debug('Error:'+ex.getStackTraceString());
//                     }
                    
//                     String whereClause = '';
//                     system.debug('dbView>>>>>'+dbView.get(0));
//                     celsrm__Custom_List_View__c view = dbView.get(0);
//                     if((view.CreatedById).equals(currUser)) {
//                         inMap.put('isCurrentUserListView', true);
//                     } else {
//                         inMap.put('isCurrentUserListView', false);
//                     }
//                     system.debug('view>>>>>'+view);
//                     if(view.celsrm__Filter_Criteria__c != null) {
//                         List<Map<String, String>> filters = (List<Map<String, String>>)JSON.deserialize(view.celsrm__Filter_Criteria__c, List<Map<String, String>>.class);
//                         if(filters != null && filters.size() > 0) {
//                             String LogicalOperator = '';
//                             for(Map<String, String> clause : filters) {
//                                 System.debug('whereClause>>> ' +  whereClause);
//                                 System.debug('LogicalOperator.contains>>> ' + LogicalOperator.contains('OR'));
//                                 if(LogicalOperator.contains('OR')) {
//                                     whereClause = whereClause.removeEnd(')');
//                                 }
//                                 whereClause += LogicalOperator;
                                
//                                 String TYPE = String.ValueOf(fMap.get(clause.get('Field')).getDescribe().getType());
                                
//                                 //Default for BOOLEAN, DOUBLE, CURRENCY, INTEGER, DATETIME, DATE
//                                 String quote = '';
//                                 if(TYPE == 'ID' || TYPE == 'REFERENCE' || TYPE == 'STRING' || TYPE == 'PICKLIST' || TYPE == 'TEXTAREA' ||
//                                 TYPE == 'ADDRESS' || TYPE == 'PHONE' || TYPE == 'URL') {
//                                     quote = '\'';
//                                 } 
//                                 String value = clause.get('Value');
//                                 System.debug('value='+value);
//                                 if (value != null && value == '{CURRENT_USER}') {
//                                     value = UserInfo.getUserId();
//                                 }
//                                 String str = clause.get('Operator');
                                
//                                 if(whereClause == '') {
//                                     whereClause += ' WHERE ';
//                                     // if(str.equals('does not contain')) {
//                                     //     whereClause += ' WHERE ( NOT ' + clause.get('Field');
//                                     // } else {
//                                     //     whereClause += ' WHERE ' + clause.get('Field');
//                                     // }
//                                 }
//                                     if(!LogicalOperator.contains('OR')) {
//                                         whereClause += '(';
//                                     }
//                                     if(str.equals('does not contain')) {
//                                         whereClause += ' ( NOT ' + clause.get('Field');
//                                     } else {
//                                         whereClause += ' ' + clause.get('Field');
//                                     }
                                
                                
//                                 if(str.equals('equals')) {
//                                     whereClause += ' = ' + (value == null || value == '' ? 'null' : quote + value + quote);
//                                 } else if(str.equals('not equal to')) {
//                                     whereClause += ' != ' + (value == null || value == '' ? 'null' : quote + value + quote);
//                                 } else if(str.equals('starts with')) {
//                                     whereClause += ' LIKE ' + (value == null ? 'null' : quote + value + '%' + quote);
//                                 } else if(str.equals('end with')) {
//                                     whereClause += ' LIKE ' + (value == null ? 'null' : quote + '%' + value + quote);
//                                 } else if(str.equals('contains')) {
//                                     whereClause += ' LIKE ' + (value == null ? 'null' : quote + '%' + value + '%' + quote);
//                                 } else if(str.equals('does not contain')) {
//                                     whereClause += ' LIKE ' + (value == null ? 'null' : quote + '%' + value + '%' + quote);
//                                 } else if(str.equals('contains in list')) {
//                                     whereClause += ' INCLUDES ' + (value == null ? '(null)' : '(' + '\'' + value + '\'' + ')');
//                                 } else if(str.equals('less than')) {
//                                     whereClause += ' < ' + (value == null ? 'null' : quote + value + quote);
//                                 } else if(str.equals('greater than')) {
//                                     whereClause += ' > ' + (value == null ? 'null' : quote + value + quote);
//                                 } else if(str.equals('less or equal')) {
//                                     whereClause += ' <= ' + (value == null ? 'null' : quote + value + quote);
//                                 } else if(str.equals('greater or equal')) {
//                                     whereClause += ' >= ' + (value == null ? 'null' : quote + value + quote);
//                                 }
    
//                                 if(str.equals('does not contain')) {
//                                     whereClause += ' ) ';
//                                 }
//                                 whereClause += ')';
                                
                                
//                                 LogicalOperator = (clause.get('LogicalOperator') != null && clause.get('LogicalOperator') != '' ? + ' ' + clause.get('LogicalOperator') + ' ' : '') + ' ';
//                                 // whereClause += (clause.get('LogicalOperator') != null && clause.get('LogicalOperator') != '' ? + ' ' + clause.get('LogicalOperator') + ' ' : '') + ' ';
//                             }
//                         }
//                     }
//                     if(parentRecordID != null) {
//                         if(whereClause != '') {
//                             whereClause += ' and '+ parentFieldApiName + ' = :parentRecordID';
//                         } else {
//                             whereClause = ' where '+ parentFieldApiName + ' = :parentRecordID'; 
//                         }
//                     }
//                     String sortfieldName = null;
//                     String sortOrder = null;
//                     if (inMap.get('TransactionList_SortColumn') != null && inMap.get('TransactionList_SortColumn') != '' && inMap.get('TransactionList_SortOrder') != null && inMap.get('TransactionList_SortOrder') != '') {
//                         sortfieldName = String.valueOf(inMap.get('TransactionList_SortColumn'));
//                         sortOrder = String.valueOf(inMap.get('TransactionList_SortOrder'));
//                         if(Schema.SObjectType.celsrm__Transaction__c.fields.getMap().get(sortfieldName).getDescribe().getType() == Schema.DisplayType.TextArea) {
//                             sortfieldName = null;
//                             sortOrder = null;
//                         }
//                     } 
    
//                     //By Ravi | 12-02-2020 | user preference
//                     if (sortfieldName == null && sortOrder == null && objectName.equalsIgnoreCase('celsrm__Transaction__c') && userPref != null && userPref.celsrm__SortListViewField__c != null && userPref.celsrm__SortListViewOrderType__c != null ) {
//                         sortfieldName = String.valueOf(userPref.celsrm__SortListViewField__c);
//                         sortOrder = String.valueOf(userPref.celsrm__SortListViewOrderType__c);
//                         if(Schema.SObjectType.celsrm__Transaction__c.fields.getMap().get(sortfieldName).getDescribe().getType() == Schema.DisplayType.TextArea) {
//                             sortfieldName = null;
//                             sortOrder = null;
//                         }
//                     } else if (sortfieldName == null && sortOrder == null && objectName.equalsIgnoreCase('celsrm__Dispute__c') && userPref != null && userPref.celsrm__DisputeSortListViewField__c != null && userPref.celsrm__DisputeSortListViewOrderType__c != null ) {
//                         sortfieldName = String.valueOf(userPref.celsrm__DisputeSortListViewField__c);
//                         sortOrder = String.valueOf(userPref.celsrm__DisputeSortListViewOrderType__c);
//                         if(Schema.SObjectType.celsrm__Dispute__c.fields.getMap().get(sortfieldName).getDescribe().getType() == Schema.DisplayType.TextArea) {
//                             sortfieldName = null;
//                             sortOrder = null;
//                         }
//                     } 
//                     //By Ravi | 12-02-2020 | user preference
    
//                     if(sortfieldName != null && sortOrder != null) {
//                         whereClause += ' ORDER BY ' + sortfieldName + ' ' + sortOrder + ' LIMIT 50000';
//                     } else if (view.celsrm__Sort_By_Field__c != null && view.celsrm__Sort_By_Field__c != '' && view.celsrm__Sort_By_Order__c != null && view.celsrm__Sort_By_Order__c != '') {
//                         whereClause += ' ORDER BY ' + String.valueOf(view.celsrm__Sort_By_Field__c) + ' ' + String.valueOf(view.celsrm__Sort_By_Order__c) + ' LIMIT 50000';
//                     }
//                     if(view.celsrm__Object_Fields__c != null){
//                         selectfields = (view.celsrm__Object_Fields__c).replaceAll(';', ',');
//                         List<String> TempSelFields= selectfields.split(',');
//                     List<String> TempSelFlds= new List<String>();
//                     for (String st : TempSelFields){
//                         inMap.put('st', st);
//                             if(fMap.get(st.trim().toLowerCase()).getDescribe().getType() == Schema.DisplayType.REFERENCE){
//                                 st= st.subString(0,st.length()-1)+ 'r.Name';
//                                 TempSelFlds.add(st);
//                             }
                            
//                     }
//                         if(TempSelFlds != null && TempSelFlds.size()>0)
//                             RefFields =  ','+String.Join(TempSelFlds,',');
                            
                        
//                     //  selectfields = String.Join(TempSelFlds,',');
//                     }
//                     boolean isId = false;
//                     boolean isName = false;
//                     if( selectfields != null && selectfields != ''){
//                         for(String str : selectfields.split(',')){
//                             if(str.equalsIgnoreCase('id')){
//                                 isId = true;
//                             }
//                             if(str.equalsIgnoreCase('name')){
//                                 isName = true;
//                             }
//                         }
//                     }
//                     /*   if(!isId){
//                         selectfields += ',id ';
//                     }
//                     if(!isName){
//                         selectfields += ',Name ';
//                     }*/
//                     //creating map of data type compatible
//                     Map<String,String> m_Type = new Map<String,String>();
//                     m_Type.put('ID','id');
//                     m_Type.put('STRING','text');
//                     m_Type.put('TEXTAREA','html');
//                     m_Type.put('NUMBER','number');
//                     m_Type.put('CURRENCY','currency');
//                     m_Type.put('DOUBLE','number');
//                     m_Type.put('PERCENT','percent');
//                     m_Type.put('PICKLIST','text');
//                     m_Type.put('BOOLEAN','boolean');
//                     m_Type.put('EMAIL','email');
//                     m_Type.put('PHONE','phone');
//                     m_Type.put('DATE','date');
//                     m_Type.put('DATETIME','datetime');
//                     m_Type.put('REFERENCE','html');
//                     system.debug('m_Type>>>>'+m_Type);
//                     system.debug('selectfields>>>>'+selectfields);
                    
//                     //By Mekyush | 05-09-2019 | Adding some key field for Transaction object to highlight cell in Trxn Grid
//                     Boolean addedDPDFieldManually = false;
//                     Boolean addedPromiseAmtFieldManually = false;
//                     Boolean addedDisputeAmtFieldManually = false;
//                     Boolean addedBalanceFieldManually = false;
//                     Boolean addedPromiseDateFieldManually = false;
//                     Boolean addedIsBrokenPromiseFieldManually = false;
//                     if(objectName == 'celsrm__Transaction__c') {
//                         if(!selectfields.contains('celsrm__Disputed_Amount__c')) {
//                             addedDisputeAmtFieldManually=true;
//                             selectfields += ',celsrm__Disputed_Amount__c'; 
//                         }
//                         if(!selectfields.contains('celsrm__Promised_Amount__c')) {
//                             addedPromiseAmtFieldManually=true;
//                             selectfields += ',celsrm__Promised_Amount__c'; 
//                         }
//                         if(!selectfields.contains('celsrm__DPD__c')) {
//                             addedDPDFieldManually=true;
//                             selectfields += ',celsrm__DPD__c'; 
//                         }
//                         if(!selectfields.contains('celsrm__Promise_Date__c')) {
//                             addedPromiseDateFieldManually=true;
//                             selectfields += ',celsrm__Promise_Date__c'; 
//                         }
//                         if(!selectfields.contains('celsrm__Is_Broken_Promise__c')) {
//                             addedIsBrokenPromiseFieldManually=true;
//                             selectfields += ',celsrm__Is_Broken_Promise__c'; 
//                         }
//                     }
//                     if(!selectfields.containsIgnoreCase('celsrm__Balance__c')) {
//                         addedBalanceFieldManually=true;
//                         selectfields += ',celsrm__Balance__c'; 
//                     }
//                     String currencyCodeStr = '';
//                     if(UserInfo.isMultiCurrencyOrganization() && !selectfields.containsIgnoreCase('currencyISOCode')) {
//                         currencyCodeStr += ',currencyISOCode'; 
//                     }
                    
//                     String finalQuery = 'SELECT ' + selectfields + RefFields + currencyCodeStr + ' FROM ' + objectName + (whereClause != '' ? whereClause : ' LIMIT 50000');
//                     // if(objectName == 'celsrm__Transaction__c') {
//                     //     finalQuery +=' Order by celsrm__Due_Date__c ASC';
//                     // }
//                     System.debug('final query : ' + finalQuery);
//                     List<sObject> l_values = database.query(finalQuery);
//                     inMap.put('l_values',l_values);
//                     system.debug('inMap befroe>>>>>'+l_values);
//                     system.debug('inMap befroe>>>>>'+inMap);
//                     //String strtemp = JSON.serialize(l_values); 
//                     //strtemp = '{ "data" : ' + strtemp + '}';
//                     //Map<String, Object> transMap =  (map < string, object > ) JSON.deserializeUntyped(strtemp );
//                     //List<Object> trxns = (List<Object>)  transMap.get('data');
//                     //List<Object> l_valuesfinal = new List<Object>();
//                     List<String> selectField = selectfields.trim().split(',');
//                     List<String> refField = new List<String>();
//                     for(String field : selectField){
//                         if(fMap.get(field).getDescribe().getType() == Schema.DisplayType.REFERENCE){
//                             refField.add(field);
//                         }
//                     }
//                     inMap.put('refField',refField);
//                     //String key = '<a href="/{0}" target="_blank">{1}</a>';
//                     /*for(Object tx: trxns ){ 
//                         Map<String, Object> m = (Map<String, Object>)tx;
//                             for(String field : selectField){
//                             if(field =='Name'){
//                                 List<Object> parameters = new List<Object> {m.get('Id'), m.get('Name') };
//                                 //String key = '<a href="' + '/'+ m.get('Id') + '"' + ' target="_blank">' + m.get('Name') + '</a>';
//                                 m.put('Name',String.format(key, parameters)) ;
//                             }else if(fMap.get(field).getDescribe().getType() == Schema.DisplayType.REFERENCE){
//                                 system.debug('m====='+ m);
//                                 String st =field.subString(0,field.length()-1)+ 'r';
//                                 system.debug('st=='+m.get(st));
//                                 Map<String,Object> tempmap = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(((Map<String, Object>)m).get(st))); 
//                                 //  object st2 =((Map<String, Object>)m).get(st);
//                                 system.debug('tempmap ====='+ tempmap );
//                                 List<Object> parameters = new List<Object> {m.get('field'), m.get('Name') };
//                                 //String key = '<a href="' + '/'+ m.get(field) + '"' + ' target="_blank">' +   tempmap.get('Name') + '</a>';
//                                 m.put(field,String.format(key, parameters)) ;
                            
//                             }
//                         }
//                         l_valuesfinal.add(tx);
//                     }*/
//                     //inMap.put('NewTransactionList',trxns);
//                     system.debug('selectfields 1>>>>'+selectfields);
//                     if(selectfields.contains(',id')){
//                         selectfields = selectfields.remove(',id');
//                     } else if(selectfields.contains(',Id')){
//                         selectfields = selectfields.remove(',Id');
//                     } else if(selectfields.contains('id,')){
//                         selectfields = selectfields.remove('id,');
//                     } else if(selectfields.contains('Id,')){
//                         selectfields = selectfields.remove('Id,');
//                     }
//                     /*  if(selectfields.contains(',name')){
//                         selectfields = selectfields.remove(',name');
//                     } else if(selectfields.contains(',Name')){
//                         selectfields = selectfields.remove(',Name');
//                     } else if(selectfields.contains('Name,')){
//                         selectfields = selectfields.remove('Name,');
//                     }*/
//                     system.debug('selectfields 1>>>>'+selectfields);
//                     list<Map<String,Object>> l_map = new list<Map<String,Object>>();
//                     for(String field : selectfields.trim().split(',')){
//                         system.debug('efield?>>>>>>>>>'+field);
//                         Map<String,Object> m_key_value = new Map<String,Object>();
//                         /*  if(field.contains('__r.Name')){
//                                 field= field.replaceAll('__r.Name','__c');
//                             }*/
//                         if(field == 'celsrm__Flag__c' ){                    
//                             m_key_value.put('label','');
//                             m_key_value.put('fieldName',field);
//                             m_key_value.put('type','html');
//                             m_key_value.put('sortable',false);
//                             m_key_value.put('width','3rem');
//                         } else if(field == 'celsrm__Notes__c' ){                    
//                             m_key_value.put('label',fMap.get(field).getDescribe().getLabel());
//                             m_key_value.put('fieldName',field);
//                             m_key_value.put('type','html');
//                             m_key_value.put('sortable',false);
//                             m_key_value.put('width','max-width:10rem');
//                             m_key_value.put('alternativeText', 'celsrm__Notes_sort__c');
//                             if (objectName.equalsIgnoreCase('celsrm__Transaction__c')) {
//                                     m_key_value.put('onClickFunction','openNoteScreen');
//                                 }
//                         } else if(field.equalsIgnoreCase('Name')){
//                             m_key_value.put('label',fMap.get(field).getDescribe().getLabel());
//                             m_key_value.put('fieldName',field);
//                             m_key_value.put('type','html');
//                             m_key_value.put('sortable',false);
//                             m_key_value.put('alternativeText', 'nameSort');
//                         }else if(field == 'InvoiceNumber__c' ){                    
//                             m_key_value.put('label',fMap.get(field).getDescribe().getLabel());
//                             m_key_value.put('fieldName',field);
//                             m_key_value.put('type','html');
//                             m_key_value.put('sortable',false);
//                             m_key_value.put('alternativeText', 'InvoiceNumber__c');
//                         }  else if( (field != 'celsrm__DPD__c' && field != 'celsrm__Disputed_Amount__c' && field != 'celsrm__Promised_Amount__c' && field != 'celsrm__Balance__c' && field != 'celsrm__Promise_Date__c' && field != 'celsrm__Is_Broken_Promise__c') || 
//                                     ( (field == 'celsrm__DPD__c' && !addedDPDFieldManually) ||
//                                         (field == 'celsrm__Promised_Amount__c' && !addedPromiseAmtFieldManually) ||
//                                         (field == 'celsrm__Disputed_Amount__c' && !addedDisputeAmtFieldManually) ||
//                                         (field == 'celsrm__Balance__c' && !addedBalanceFieldManually) || (field == 'celsrm__Promise_Date__c' && !addedPromiseDateFieldManually) || (field == 'celsrm__Is_Broken_Promise__c' && !addedIsBrokenPromiseFieldManually)
//                                     )
//                                     ){
//                             //Map<String,Object> m_key_value = new Map<String,Object>();
//                             m_key_value.put('label',fMap.get(field).getDescribe().getLabel());
//                             m_key_value.put('fieldName',field);
//                             m_key_value.put('type',m_Type.get(String.valueOf(fMap.get(field).getDescribe().getType())) == 'double' ? 'number' : m_Type.get(String.valueOf(fMap.get(field).getDescribe().getType())));
//                             m_key_value.put('sortable',true);
//                         }
//                         if(!m_key_value.isEmpty()) {
//                             l_map.add(m_key_value);    
//                         }
                        
//                     }
//                     System.debug('@@ l_map : ' + l_map);
//                     inMap.put('updatedColumns',l_map);
//                     inMap.put('ListView',dbView.get(0).Id);
//                 }
//             } catch (Exception ex) {
//                 system.debug('Error in defaultViewClass:'+ex.getMessage());
//                 system.debug('StackTrackString:'+ex.getStackTraceString());
//                 throw new celsrm.CustomException('Error Stacktrace>>' + ex.getStackTraceString());
//             }
            
//         }
        
//         return inMap; 
//     }

// }

global with sharing class defaultViewClass implements celsrm.GOGIScreenCustomLogic {
    global Map<Object, Object> invoke(String functionName, Map<Object, Object> inMap) {
        if(functionName == 'OnLoadTransform'){
            return defaultViewClass.onLoadTransform(inMap);
        } else if(functionName == 'onChangeView'){
            return defaultViewClass.fetchDataFromView(inMap, false);
        } else if(functionName == 'getDefaultView') {
            return defaultViewClass.fetchDataFromView(inMap, true);
        }
        return inMap; 
    }

    private static Map<Object, Object> fetchDataFromView (Map<Object, Object> inMap, Boolean isDefault) {
        try {
            if(!inMap.containsKey('ListViewObject') || inMap.get('ListViewObject') == null || inMap.get('ListViewObject') == '') {
                throw new celsrm.GOGDataServiceLoadException('List View Object is not specified');
            }
            
            if(!inMap.containsKey('ListViewParentField') || inMap.get('ListViewParentField') == null || inMap.get('ListViewParentField') == '') {
                throw new celsrm.GOGDataServiceLoadException('Parent Field Api name is not specified.');
            }

            if(!isDefault) {
                if(!inMap.containsKey('ListView') || inMap.get('ListViewParentField') == null || inMap.get('ListView') == '') {
                    throw new celsrm.GOGDataServiceLoadException('List View details is not available');
                }
            }
            
            String objectName = String.valueOf(inMap.get('ListViewObject'));
            String folderName = String.valueOf(inMap.get('ListViewFolderName'));
            String parentFieldApiName = String.valueOf(inMap.get('ListViewParentField'));
            String selectedView = String.valueOf(inMap.get('ListView'));
            String currUser = UserInfo.getUserId();
            String RefFields='';

            List<celsrm__Custom_List_View__c> dbView = new List<celsrm__Custom_List_View__c>();
            // Fetch User preference - transaction or dispute based on ListViewObject (Configured at screen level - parent) - START
            celsrm__User_Preference__c userPref  = null;
            try {
                String query= '';
                if (objectName.equalsIgnoreCase('celsrm__Transaction__c')) {
                    if(folderName != null && folderName != '') {
                        query = 'SELECT Id, celsrm__SortListViewOrderType__c, celsrm__SortListViewField__c, celsrm__SelectedTransactionListView__c FROM celsrm__User_Preference__c WHERE celsrm__User__c =:currUser AND celsrm__List_View_Folder__c =:folderName LIMIT 1';
                    } else {
                        query = 'SELECT Id, celsrm__SortListViewOrderType__c, celsrm__SortListViewField__c, celsrm__SelectedTransactionListView__c FROM celsrm__User_Preference__c WHERE celsrm__User__c =:currUser LIMIT 1';
                    }
                } else {
                    if(folderName != null && folderName != '') {
                        query = 'SELECT Id, celsrm__DisputeSortListViewField__c, celsrm__DisputeSortListViewOrderType__c, celsrm__SelectedDisputeListView__c FROM celsrm__User_Preference__c WHERE celsrm__User__c =:currUser AND celsrm__List_View_Folder__c =:folderName LIMIT 1';
                    } else {
                        query = 'SELECT Id, celsrm__DisputeSortListViewField__c, celsrm__DisputeSortListViewOrderType__c, celsrm__SelectedDisputeListView__c FROM celsrm__User_Preference__c WHERE celsrm__User__c =:currUser LIMIT 1';
                    }
                }
                
                for (celsrm__User_Preference__c userPrefObj : Database.query(query)) {
                    userPref = userPrefObj;
                }
            } catch (Exception e) {
                System.debug('exception>> ' + e.getMessage());
            }
            // Fetch User preference - transaction or dispute based on ListViewObject (Configured at screen level - parent) - END
            // BLOCK1 - IF - START
            if(isDefault) {
                // Fetch custom list view based on user preference or default or global - START
                if (objectName.equalsIgnoreCase('celsrm__Transaction__c') && userPref != null && userPref.celsrm__SelectedTransactionListView__c != null) {
                    if(folderName != null && folderName != '') {
                        dbView = [Select Id, CreatedById,Name, celsrm__Object_Fields__c, celsrm__Filter_Criteria__c, celsrm__Sort_By_Field__c, celsrm__Sort_By_Order__c From celsrm__Custom_List_View__c Where Id =: userPref.celsrm__SelectedTransactionListView__c AND Folder_Name__c = :folderName LIMIT 1];
                    } else {
                        dbView = [Select Id, CreatedById,Name, celsrm__Object_Fields__c, celsrm__Filter_Criteria__c, celsrm__Sort_By_Field__c, celsrm__Sort_By_Order__c From celsrm__Custom_List_View__c Where Id =: userPref.celsrm__SelectedTransactionListView__c LIMIT 1];
                    }
                } else if (objectName.equalsIgnoreCase('celsrm__Dispute__c') && userPref != null && userPref.celsrm__SelectedDisputeListView__c != null) {
                    if(folderName != null && folderName != '') {
                        dbView = [Select Id, CreatedById,Name, celsrm__Object_Fields__c, celsrm__Filter_Criteria__c, celsrm__Sort_By_Field__c, celsrm__Sort_By_Order__c From celsrm__Custom_List_View__c Where Id =: userPref.celsrm__SelectedDisputeListView__c AND Folder_Name__c = :folderName LIMIT 1 ];
                    } else {
                        dbView = [Select Id, CreatedById,Name, celsrm__Object_Fields__c, celsrm__Filter_Criteria__c, celsrm__Sort_By_Field__c, celsrm__Sort_By_Order__c From celsrm__Custom_List_View__c Where Id =: userPref.celsrm__SelectedDisputeListView__c LIMIT 1 ];
                    }
                } 
                //-- Start | FIN-6777 | Changed by Ravi | 11 Aug 2024 --//
                if(dbView.size() == 0) {
                    if(folderName != null && folderName != '') {
                        dbView = [Select Id, CreatedById, Name, celsrm__Object_Fields__c, celsrm__Filter_Criteria__c, celsrm__Sort_By_Field__c, celsrm__Sort_By_Order__c From celsrm__Custom_List_View__c Where celsrm__ListView_For_Object__c =: objectName and celsrm__Is_Default__c = true and (CreatedById = :currUser or celsrm__Is_Global__c = true) AND Folder_Name__c = :folderName order by CreatedDate DESC LIMIT 1];
                    } else {
                        dbView = [Select Id, CreatedById, Name, celsrm__Object_Fields__c, celsrm__Filter_Criteria__c, celsrm__Sort_By_Field__c, celsrm__Sort_By_Order__c From celsrm__Custom_List_View__c Where celsrm__ListView_For_Object__c =: objectName and celsrm__Is_Default__c = true and (CreatedById = :currUser or celsrm__Is_Global__c = true) order by CreatedDate DESC LIMIT 1];
                    }
                } 
                if(dbView.size() == 0) {
                    if(folderName != null && folderName != '') {
                        dbView = [Select Id, CreatedById, Name, celsrm__Object_Fields__c, celsrm__Filter_Criteria__c, celsrm__Sort_By_Field__c, celsrm__Sort_By_Order__c From celsrm__Custom_List_View__c Where celsrm__ListView_For_Object__c =: objectName and (CreatedById = :currUser or celsrm__Is_Global__c = true) AND Folder_Name__c = :folderName order by CreatedDate DESC LIMIT 1];    
                    } else {
                        dbView = [Select Id, CreatedById, Name, celsrm__Object_Fields__c, celsrm__Filter_Criteria__c, celsrm__Sort_By_Field__c, celsrm__Sort_By_Order__c From celsrm__Custom_List_View__c Where celsrm__ListView_For_Object__c =: objectName and (CreatedById = :currUser or celsrm__Is_Global__c = true) order by CreatedDate DESC LIMIT 1];    
                    }
                }
                //-- End | FIN-6777 | Changed by Ravi | 11 Aug 2024 --//
                // Fetch custom list view based on user preference or default or global - END
            } else {
                // BLOCK1 - IF - START
                dbView = [Select Id, Name, celsrm__Object_Fields__c, celsrm__Filter_Criteria__c, CreatedById,celsrm__Sort_By_Field__c, celsrm__Sort_By_Order__c From celsrm__Custom_List_View__c Where Id = :selectedView LIMIT 1];
                //-- Start | FIN-6777 | Changed by Ravi | 11 Aug 2024 --//
                if(dbView.size() == 0) {
                //-- End | FIN-6777 | Changed by Ravi | 11 Aug 2024 --//
                    dbView = [Select Id, Name, celsrm__Object_Fields__c, celsrm__Filter_Criteria__c, CreatedById,celsrm__Sort_By_Field__c, celsrm__Sort_By_Order__c From celsrm__Custom_List_View__c Where celsrm__ListView_For_Object__c =: objectName and celsrm__Is_Default__c = true and (CreatedById = :currUser or celsrm__Is_Global__c = true) ORDER BY celsrm__Is_Global__c LIMIT 1];
                    //-- Start | FIN-6777 | Changed by Ravi | 11 Aug 2024 --//
                    if(dbView.size() == 0) {
                    //-- End | FIN-6777 | Changed by Ravi | 11 Aug 2024 --//
                        dbView = [Select Id, Name, celsrm__Object_Fields__c, celsrm__Filter_Criteria__c, CreatedById,celsrm__Sort_By_Field__c, celsrm__Sort_By_Order__c From celsrm__Custom_List_View__c Where celsrm__ListView_For_Object__c =: objectName and (CreatedById = :currUser or celsrm__Is_Global__c = true) order by celsrm__Is_Global__c limit 1];    
                    }   
                }
                // BLOCK1 - IF - END
            }
            // BLOCK1 - IF - END
            Map<String, Schema.SObjectField> fMap;
            if(dbView != null && dbView.size() > 0) {
                String selectfields = '';   
                try {
                    Map<string, Schema.sObjectType> describeInfo = Schema.getGlobalDescribe();
                    fMap = describeInfo.get(objectName.toLowerCase()).getDescribe().Fields.getMap();
                } catch(Exception ex) { 
                    System.debug('Error:'+ex.getStackTraceString());
                }
                
                String whereClause = '';
                system.debug('dbView>>>>>'+dbView.get(0));
                celsrm__Custom_List_View__c view = dbView.get(0);
                if((view.CreatedById).equals(currUser)) {
                    inMap.put('isCurrentUserListView', true);
                } else {
                    inMap.put('isCurrentUserListView', false);
                }
                system.debug('view>>>>>'+view);
                if(view.celsrm__Filter_Criteria__c != null) {
                    Map<String, Object> filterObj = (Map<String,Object>)JSON.deserializeUntyped(view.celsrm__Filter_Criteria__c);
                    List<Object> criteriasRaw = (List<Object>) filterObj.get('criterias');
                    List<Map<String, Object>> filters = new List<Map<String, Object>>();
                    for(Object criteria : criteriasRaw) {
                        filters.add((Map<String, Object>) criteria);
                    }
    
                    String criteriaCondition = String.valueOf(filterObj.get('condition'));
    
                    List<String>  conditionList =  new List<String>();
                    List<String>  conditionListValue =  new List<String>();
                    if (criteriaCondition != null && criteriaCondition != ' ') {
                        conditionList = criteriaCondition.split(' ');   // ["(1","AND","2)"]
                    }
                    Integer conditionListLength = conditionList.size();
                    // for (Integer l = conditionListLength-1; l >= 0; l--) {
                    //     if (conditionList[l].isWhitespace()) {
                    //         conditionList.remove(l);
                    //         continue;
                    //     }
                    //     conditionListValue.add(conditionList[l]);

                    //     System.debug('conditionList[l]:::' + conditionList[l]);
                    //     System.debug('conditionListValue:::' + conditionListValue);
                    // }
                    for (Integer l = 0; l < conditionListLength; l++) {
                        if (conditionList[l].isWhitespace()) {
                            conditionList.remove(l);
                            continue;
                        }
                        conditionListValue.add(conditionList[l]);

                        System.debug('conditionList[l]:::' + conditionList[l]);
                        System.debug('conditionListValue:::' + conditionListValue);
                    }
                    // System.debug('@@@ (obj.criteria : ' + obj.criteria);
    
                    if(filters.size() > 0) {
                        Map<String, String> filtersMap = new Map<String, String>();
                        for(Integer i=0; i<filters.size(); i++) {
                            System.debug('conditionListValue:::' + conditionListValue);
                            String field = String.valueOf(filters[i].get('fieldName'));
                            String operator = String.valueOf(filters[i].get('operator'));
                            String value = String.valueOf(filters[i].get('value'));
                            String type = String.valueOf(filters[i].get('type'));
    
                            String tmpWhere = defaultViewClass.buildQuery(field, operator, value, type);
                            filtersMap.put(String.valueOf(i + 1), tmpWhere);
                        }
                        if(conditionListValue.size() > 0 && filtersMap.size() > 0) {//[1, AND, 2)AND, 3]
                            for(Integer i=0; i<conditionListValue.size(); i++) {
                                // String conditionPart = conditionListValue[i];
                                List<String> conditionParts = conditionListValue[i].split('');
                                for(Integer j=0; j<conditionParts.size(); j++) {
                                    if(filtersMap.containsKey(conditionParts[j])) {
                                        conditionParts[Integer.valueOf(j)] = filtersMap.get(conditionParts[j]);
                                    }
                                }
                                System.debug('conditionParts:::'+ conditionParts);
                                conditionListValue[i] = String.join(conditionParts, '');
                                System.debug('conditionListValue:::'+ conditionListValue);
                            }
                        }
                        // for(Integer i=0; i<filters.size(); i++) {
                        //     System.debug('conditionListValue:::' + conditionListValue);
                        //     String field = String.valueOf(filters[i].get('fieldName'));
                        //     String operator = String.valueOf(filters[i].get('operator'));
                        //     String value = String.valueOf(filters[i].get('value'));
                        //     String type = String.valueOf(filters[i].get('type'));
    
                        //     String tmpWhere = defaultViewClass.buildQuery(field, operator, value, type);
                        //     System.debug('tmpWhere:::' + tmpWhere);
    
                        //     if(tmpWhere != null) {
    
                        //         if(criteriaCondition == '' && tmpWhere != ''){
                        //             if (i > 0 && operator != '') {
                        //                 whereClause += 'AND ( ' + tmpWhere + ')';
                        //             } else {
                        //                 whereClause += ' ( ' + tmpWhere + ')';
                        //                 operator = 'AND';
                        //             }
                        //         } else { 
                        //             Integer index = i+1;    //1
                        //             String currenIndex = String.valueOf(index);     //1
                        //             Integer len = conditionList.size();     //5
                                    
                        //             // len = conditionList.size();     //( celsrm__DPD__c >= 1),AND,( celsrm__DPD__c <= ( celsrm__Close_Date__c = null)0),AND,( celsrm__Close_Date__c = null)
                        //             for (Integer j = 0; j < len; j++) {
                        //                 System.debug('currenIndex:::' + currenIndex);
                        //                 System.debug('conditionList[j]:::' + conditionList[j]); // 2 )
                        //                 System.debug('conditionListValue:::' + conditionListValue);
                        //                 List<String> conditionParts = conditionList[j].split(''); //(, 2
                        //                 Boolean foundMatch = false;
                        //                 for(Integer k = 0; k < conditionParts.size(); k++) {
                        //                     if(currenIndex.equalsignorecase(conditionParts[k])){
                        //                         // if (tmpWhere == '') {
                        //                         //     conditionList[j] =  '';
                        //                         //     if (j+1 < len && conditionList[j+1].contains(')') && !conditionList[j-1].contains('(')) {
                        //                         //         conditionList[j-1] =  '';
                        //                         //     } else if (j+1 < len && !conditionList[j+1].contains(')')) {
                        //                         //         conditionList[j+1] = '';
                        //                         //     }
                        //                         // } else {
                        //                             conditionParts[k] =  tmpWhere;
                        //                             foundMatch = true;
                        //                         // }
                        //                     }
                        //                 }
                        //                 System.debug('conditionListValue:::' + conditionListValue);
                        //                 if(foundMatch == true) {
                        //                     conditionListValue[j] = String.join(conditionParts, '');
                        //                 }
                        //                 // if(currenIndex.equalsignorecase(conditionList[j])){
                        //                 //     // if (tmpWhere == '') {
                        //                 //     //     conditionList[j] =  '';
                        //                 //     //     if (j+1 < len && conditionList[j+1].contains(')') && !conditionList[j-1].contains('(')) {
                        //                 //     //         conditionList[j-1] =  '';
                        //                 //     //     } else if (j+1 < len && !conditionList[j+1].contains(')')) {
                        //                 //     //         conditionList[j+1] = '';
                        //                 //     //     }
                        //                 //     // } else {
                        //                 //         conditionList[j] =  tmpWhere;
                        //                 //     // }
                        //                 // } 
                        //                 System.debug('conditionList:::' + conditionList);
                        //                 System.debug('conditionListValue:::' + conditionListValue);
                        //             }
                        //             System.debug('conditionListValue:::' + conditionListValue);
                        //         }
                        //         System.debug('conditionListValue:::' + conditionListValue);
                        //     }
                        //     System.debug('conditionListValue:::' + conditionListValue);
                        // }
                        if(conditionListValue.size() > 0) {
                            System.debug('@@@@conditionList:::: ' + conditionListValue);
                            conditionListValue = defaultViewClass.removeParentheses(conditionListValue);
                            whereClause = ' WHERE ' + string.join(conditionListValue,' ');
                            System.debug('@@@ whereClause :::: ' + whereClause);
                        }    
                    }
                }
                //-- Start | FIN-8530 | Changed by Ravi | 10 Nov 2025 --//
                List<String> parentRecordIDs = new List<String>();
                if(inMap.get('Id') != null) {
                    parentRecordIDs.add(String.valueOf(inMap.get('Id')));
                }
                if (inMap.get('accountHierarchyChildIds') != null) {
                    List<Object> tempList = (List<Object>)inMap.get('accountHierarchyChildIds');
                    for(Object objId : tempList) {
                        parentRecordIDs.add(String.valueOf(objId));
                    }
                }
                if(isDefault) {
                    if(parentRecordIDs != null && parentRecordIDs.size() > 0) {
                        if(whereClause != '') {
                            whereClause += ' and '+ parentFieldApiName + ' in :parentRecordIDs';
                        } else {
                            whereClause = ' where '+ parentFieldApiName + ' in :parentRecordIDs'; 
                        }
                    }
                } else {
                    //-- End | FIN-8530 | Changed by Ravi | 10 Nov 2025 --//
                    if(parentRecordIDs != null && parentRecordIDs.size() > 0) {
                        if(whereClause != '') {
                            whereClause += ' and '+ parentFieldApiName + ' in :parentRecordIDs';
                        } else {
                            whereClause = ' where '+ parentFieldApiName + ' in :parentRecordIDs'; 
                        }
                    }
                }
                
                String sortfieldName = null;
                String sortOrder = null;
                //By Ravi | 12-02-2020 | user preference
                // if (sortfieldName == null && sortOrder == null && objectName.equalsIgnoreCase('celsrm__Transaction__c') && userPref != null && userPref.celsrm__SortListViewField__c != null && userPref.celsrm__SortListViewOrderType__c != null ) {
                //     sortfieldName = String.valueOf(userPref.celsrm__SortListViewField__c);
                //     sortOrder = String.valueOf(userPref.celsrm__SortListViewOrderType__c);
                //     if(Schema.SObjectType.celsrm__Transaction__c.fields.getMap().get(sortfieldName).getDescribe().getType() == Schema.DisplayType.TextArea) {
                //         sortfieldName = null;
                //         sortOrder = null;
                //     }
                // } else if (sortfieldName == null && sortOrder == null && objectName.equalsIgnoreCase('celsrm__Dispute__c') && userPref != null && userPref.celsrm__DisputeSortListViewField__c != null && userPref.celsrm__DisputeSortListViewOrderType__c != null ) {
                //     sortfieldName = String.valueOf(userPref.celsrm__DisputeSortListViewField__c);
                //     sortOrder = String.valueOf(userPref.celsrm__DisputeSortListViewOrderType__c);
                //     if(Schema.SObjectType.celsrm__Dispute__c.fields.getMap().get(sortfieldName).getDescribe().getType() == Schema.DisplayType.TextArea) {
                //         sortfieldName = null;
                //         sortOrder = null;
                //     }
                // } 
                //By Ravi | 12-02-2020 | user preference

                List<String> sortings = new List<String>();
                // if(sortfieldName != null && sortOrder != null) {
                //     whereClause += ' ORDER BY ' + sortfieldName + ' ' + sortOrder + ' LIMIT 50000';
                // } else 
                if (view.celsrm__Sort_By_Field__c != null && view.celsrm__Sort_By_Field__c != '') {
                    List<Map<String, String>> sortByFields = (List<Map<String, String>>)JSON.deserialize(view.celsrm__Sort_By_Field__c, List<Map<String, String>>.class);
                    if(sortByFields.size() > 0) {
                        for(Map<String, String> sb: sortByFields) {
                            String temp = '';
                            if(sb.get('fieldName') != null && sb.get('fieldName') != '') {
                                temp += String.valueOf(sb.get('fieldName'));
                            }
                            if(sb.get('order') != null && sb.get('order') != '') {
                                temp += ' ' + String.valueOf(sb.get('order'));
                            } else {
                                temp += ' ASC';
                            }
                            sortings.add(temp);
                        }
                        whereClause += ' ORDER BY ' + String.join(sortings, ', ') + ' LIMIT 50000';
                    }
                }

                List<Map<String, Object>> columnList = new List<Map<String, Object>>();
                if(view.celsrm__Object_Fields__c != null){
                    List<Object> parsedJson = (List<Object>) JSON.deserializeUntyped(view.celsrm__Object_Fields__c);
                    List<String> TempSelFields = new List<String>();
                    List<String> TempRefFields = new List<String>();
                    //-- Start | FIN-8530 | Changed by Ravi | 10 Nov 2025 --//
                    Boolean isAccountAdded = false;
                    //-- End | FIN-8530 | Changed by Ravi | 10 Nov 2025 --//
                    for(Object obj : parsedJson) {
                        Map<String, Object> resultMap = (Map<String, Object>)obj;
                        String fieldName = String.valueOf(resultMap.get('fieldName'));
                        if(resultMap.get('type') == 'lookup') {
                            String relField = '';
                            if(fieldName.contains('__c')) {
                                relField = fieldName.replace('__c', '__r.Name');
                            } else {
                                relField = fieldName.replace('Id', '.Name');
                            }
                            TempRefFields.add(relField);
                        }
                        //-- Start | FIN-8530 | Changed by Ravi | 10 Nov 2025 --//
                        if(fieldName == 'celsrm__Account__c') {
                            isAccountAdded = true;
                        }
                        //-- End | FIN-8530 | Changed by Ravi | 10 Nov 2025 --//
                        resultMap.put('label', String.valueOf(fMap.get(fieldName).getDescribe().getLabel()));
                        columnList.add(resultMap);
                        TempSelFields.add(String.valueOf(resultMap.get('fieldName')));
                    }
                    //-- Start | FIN-8530 | Changed by Ravi | 10 Nov 2025 --//
                    if (!isAccountAdded) {
                        TempSelFields.add('celsrm__Account__c');
                    }
                    //-- End | FIN-8530 | Changed by Ravi | 10 Nov 2025 --//
                    TempSelFields.addAll(TempRefFields);
                    selectfields = String.join(TempSelFields, ',');
                }
                if(!isDefault) {
                    if(userPref == null) {
                        userPref = new celsrm__User_Preference__c();
                        userPref.celsrm__User__c = UserInfo.getUserId();
                        userPref.celsrm__List_View_Folder__c = folderName;
                    }
                    if (objectName.equalsIgnoreCase('celsrm__Transaction__c')) {
                        userPref.celsrm__SelectedTransactionListView__c = view.Id;
                    } else {
                        userPref.celsrm__SelectedDisputeListView__c = view.Id;
                    }
                    upsert userPref;
                }
                

                String finalQuery = 'SELECT ' + selectfields + ' FROM ' + objectName + (whereClause != '' ? whereClause : ' LIMIT 50000');
                System.debug('final query : ' + finalQuery);
                List<sObject> l_values = database.query(finalQuery);
                inMap.put('l_values',l_values);                    
                list<Map<String,Object>> l_map = columnList;
                System.debug('@@ l_map : ' + l_map);
                inMap.put('updatedColumns',l_map);
                inMap.put('ListView',dbView.get(0).Id);
                //-- Start | FIN-8530 | Changed by Ravi | 10 Nov 2025 --//
                if(inMap.get('Id') != null && parentRecordIDs.indexOf(String.valueOf(inMap.get('Id'))) != -1) {
                    parentRecordIDs.remove(parentRecordIDs.indexOf(String.valueOf(inMap.get('Id'))));
                }
                if (!parentRecordIDs.isEmpty()) {
                    List<Account> accountList = [Select Id, Name From Account where Id In :parentRecordIDs];
                    set<String> accountNames = new set<String>();
                    for(Account acc : accountList) {
                        accountNames.add(acc.Name);
                    }
                    inMap.put('childAccountNames', accountNames);
                } else {
                    inMap.put('childAccountNames', null);
                }
                //-- End | FIN-8530 | Changed by Ravi | 10 Nov 2025 --//
            }
        } catch (Exception ex) {
            system.debug('Error in defaultViewClass:'+ex.getMessage());
            system.debug('StackTrackString:'+ex.getStackTraceString());
            throw new celsrm.CustomException('Error Stacktrace>>' + ex.getStackTraceString());
        }
        return inMap;
    }

    private static Map<Object, Object> onLoadTransform (Map<Object, Object> inMap) {
        System.debug('inMap>> ' + inMap);
        List<Object> response = (List<Object>)inMap.get('dataServiceResponse');
        List<Object> newResponse = new List<Object>();
        for(Object res : response) {
            Map<String,Object> tempMap = (Map<String,Object>)res;
            String name = String.valueOf(tempMap.get('disputeName'));
            Id disputeid= (Id)tempMap.get('Id');
            String key = '<a href="' + '/'+ disputeid + '"' + ' target="_blank">' + name + '</a>';
            tempMap.put('Name',key);
            newResponse.add(tempMap);
        }
        inMap.put('dataServiceResponse', newResponse);
        return inMap; 
    }
    public static String buildQuery(String field, String operator, String value, String type) {
        //Default for BOOLEAN, DOUBLE, CURRENCY, INTEGER, DATETIME, DATE
        String whereClause = '';
        String quote = '';
        if(type == 'text') {
            quote = '\'';
        }
        if (value != null && value == '{CURRENT_USER}') {
            value = UserInfo.getUserId();
        }
        whereClause += '(';
        if(operator.equals('does not contain')) {
            whereClause += ' ( NOT ' + field;
        } else {
            whereClause += ' ' + field;
        }
        
        if(operator.equals('equals')) {
            whereClause += ' = ' + (value == null || value == '' ? 'null' : quote + value + quote);
        } else if(operator.equals('not equal to')) {
            whereClause += ' != ' + (value == null || value == '' ? 'null' : quote + value + quote);
        } else if(operator.equals('starts with')) {
            whereClause += ' LIKE ' + (value == null || value == '' ? 'null' : quote + value + '%' + quote);
        } else if(operator.equals('end with')) {
            whereClause += ' LIKE ' + (value == null || value == '' ? 'null' : quote + '%' + value + quote);
        } else if(operator.equals('contains')) {
            whereClause += ' LIKE ' + (value == null || value == '' ? 'null' : quote + '%' + value + '%' + quote);
        } else if(operator.equals('does not contain')) {
            whereClause += ' LIKE ' + (value == null || value == '' ? 'null' : quote + '%' + value + '%' + quote);
        } else if(operator.equals('contains in list')) {
            whereClause += ' INCLUDES ' + (value == null || value == '' ? '(null)' : '(' + '\'' + value + '\'' + ')');
        } else if(operator.equals('less than')) {
            whereClause += ' < ' + (value == null || value == '' ? 'null' : quote + value + quote);
        } else if(operator.equals('greater than')) {
            whereClause += ' > ' + (value == null || value == '' ? 'null' : quote + value + quote);
        } else if(operator.equals('less or equal')) {
            whereClause += ' <= ' + (value == null || value == '' ? 'null' : quote + value + quote);
        } else if(operator.equals('greater or equal')) {
            whereClause += ' >= ' + (value == null || value == '' ? 'null' : quote + value + quote);
        }
        
        if(operator.equals('does not contain')) {
            whereClause += ' ) ';
        }
        whereClause += ')';
        return whereClause;
    }

    public static List<String> removeParentheses(List<String> conditionList) {
        Integer len = conditionList.size();
        for (Integer i = len-1; i >= 0; i--) {
            if (conditionList[i].isWhitespace()) {
                conditionList.remove(i);
            }
        }
        len = conditionList.size();
        for (Integer j = 0; j < len; j++) {
            if(conditionList[j].equalsignorecase('(')) {
                if(conditionList[j+1].equalsignorecase(')')) {
                    conditionList[j] = '';
                    conditionList[j+1] = '';
                    if (j+2 < len && conditionList[j+2].equalsignorecase(')') && (conditionList[j-1] == 'AND' || conditionList[j-1] == 'OR' )) {
                        conditionList[j-1] = '';
                    } else if(j+2 < len && (conditionList[j+2] == 'AND' || conditionList[j+2] == 'OR' )){
                        conditionList[j+2] = '';
                    }
                    conditionList = removeParentheses(conditionList);
                    break;
                }     
            }
        }
        return conditionList;
    }

}