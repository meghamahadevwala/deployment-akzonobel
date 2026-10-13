@isTest
public with sharing class defaultViewClassTest {

    public static testmethod void defaultViewClassTest(){
        
        Map<Object, Object> inMap = new Map<Object, Object>();
        
        Account acc = DataGenerator.insertAccount();
        celsrm__Transaction__c trans = DataGenerator.insertTransaction(acc);
        celsrm__Custom_List_View__c listView = DataGenerator.insertCustomListView(true);
        celsrm__User_Preference__c userPref = DataGenerator.insertUserPreference(listView.Id);
        // celsrm__Dispute__c dis = [SELECT Id, Name FROM celsrm__Dispute__c LIMIT 1];

        List<Object> ObjList = new List<Object>();
        Map<String,Object> objMap1 = new Map<String,Object>();
        objMap1.put('Id',acc.Id);
        objMap1.put('disputeName',acc.Name);
        objList.add(objMap1);

        inMap.put('dataServiceResponse', ObjList);
        inMap.put('Id', acc.Id);

        defaultViewClass defaultView = new defaultViewClass();
        defaultView.invoke('OnLoadTransform', inMap);
    }
    
    public static testmethod void defaultViewClassTest2(){
                
        Account acc = DataGenerator.insertAccount();
        celsrm__Transaction__c trans = DataGenerator.insertTransaction(acc);
        celsrm__Custom_List_View__c listView = DataGenerator.insertCustomListView(true);
        celsrm__User_Preference__c userPref = DataGenerator.insertUserPreference(listView.Id);
        // celsrm__Dispute__c dis = [SELECT Id, Name FROM celsrm__Dispute__c LIMIT 1];
		defaultViewClass defaultClass = new defaultViewClass();
        Map<Object, Object> inMap = new Map<Object, Object>();
        
        inMap.put('ListViewObject', 'celsrm__transaction__c');
        inMap.put('ListViewParentField', 'celsrm__Account__c');
        inMap.put('Id', acc.Id);
        defaultClass.invoke('getDefaultView', inMap);
        
        inMap.put('ListView', listView.Name);
        defaultClass.invoke('onChangeView', inMap);
        
        listView.Folder_Name__c = 'MyListView';
        listView.celsrm__Sort_By_Field__c = '[{"order":"DESC","fieldName":"celsrm__DPD__c"}]';
        update listView;
        inMap.put('ListViewFolderName', 'MyListView');
        defaultClass.invoke('onChangeView', inMap);
        
    }
}