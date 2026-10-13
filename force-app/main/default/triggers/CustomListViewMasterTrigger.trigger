trigger CustomListViewMasterTrigger on celsrm__Custom_List_View__c (before insert, before update) {
    for(celsrm__Custom_List_View__c listViewObj: Trigger.new) {
        listViewObj.Custom_List_View_Key__c = listViewObj.Name + listViewObj.celsrm__ListView_For_Object__c + listViewObj.Folder_Name__c;
        listViewObj.Custom_List_View_Key__c = listViewObj.Custom_List_View_Key__c.replaceAll('\\s', '');
   }
}