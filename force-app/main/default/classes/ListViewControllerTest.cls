@isTest
public with sharing class ListViewControllerTest {
    public static testmethod void testMethod1(){
        Account acc = DataGenerator.insertAccount();
        celsrm__Transaction__c trans = DataGenerator.insertTransaction(acc);
        celsrm__Custom_List_View__c listView = DataGenerator.insertCustomListView(true);
        
        //celsrm__Custom_List_View__c listView2 = DataGenerator.insertCustomListView(true);
        celsrm__User_Preference__c userPref = DataGenerator.insertUserPreference(listView.Id);
        
        
        ListViewController controller = new ListViewController();
        Map<Object, Object> inMap = new Map<Object, Object>();
        inMap.put('ListViewObject', 'celsrm__transaction__c');
        inMap.put('ListViewParentField', 'celsrm__Account__c');
        controller.invoke('getObjectFields', inMap);
        controller.invoke('getNewListView', inMap);
        
        listView.celsrm__Sort_By_Field__c = '[{"order":"DESC","fieldName":"celsrm__DPD__c"}]';
        update listView;
		inMap.put('ListView', listView.Id);
        inMap.put('ListViewName', listView.Name);
        inMap.put('ListViewFolderName', listView.Folder_Name__c);
        controller.invoke('getListView', inMap);
        
        listView.celsrm__Object_Fields__c = '[{"enableCopy":null,"isExport":null,"hideLabel":true,"hide":null,"onClickFunction":"","isAggregate":false,"iconClassMap":false,"iconFlag":false,"iconName":"","width":"","type":"html","fieldName":"celsrm__Flag__c"},{"enableCopy":false,"isExport":false,"hideLabel":null,"hide":false,"onClickFunction":"","isAggregate":false,"iconClassMap":false,"iconFlag":false,"iconName":"","width":"","type":"link","fieldName":"Name"},{"enableCopy":null,"isExport":null,"hideLabel":null,"hide":null,"onClickFunction":"","isAggregate":false,"iconClassMap":false,"iconFlag":false,"iconName":"","width":"","type":"currency","fieldName":"celsrm__Amount__c"},{"enableCopy":null,"isExport":null,"hideLabel":null,"hide":null,"onClickFunction":"","isAggregate":false,"iconClassMap":false,"iconFlag":false,"iconName":"","width":"","type":"currency","fieldName":"celsrm__Balance__c"},{"enableCopy":null,"isExport":null,"hideLabel":null,"hide":null,"onClickFunction":"","isAggregate":false,"iconClassMap":false,"iconFlag":false,"iconName":"","width":"","type":"date","fieldName":"celsrm__Create_Date__c"},{"enableCopy":null,"isExport":null,"hideLabel":null,"hide":null,"onClickFunction":"","isAggregate":false,"iconClassMap":false,"iconFlag":false,"iconName":"","width":"","type":"date","fieldName":"celsrm__Due_Date__c"},{"enableCopy":null,"isExport":null,"hideLabel":null,"hide":null,"onClickFunction":"","isAggregate":false,"iconClassMap":false,"iconFlag":false,"iconName":"","width":"","type":"number","fieldName":"celsrm__DPD__c"},{"enableCopy":null,"isExport":null,"hideLabel":null,"hide":null,"onClickFunction":"","isAggregate":false,"iconClassMap":false,"iconFlag":false,"iconName":"","width":"","type":"text","fieldName":"celsrm__Payment_Terms__c"},{"enableCopy":null,"isExport":null,"hideLabel":null,"hide":null,"onClickFunction":"","isAggregate":false,"iconClassMap":false,"iconFlag":false,"iconName":"","width":"","type":"date","fieldName":"celsrm__Last_Contact_Date__c"},{"enableCopy":null,"isExport":null,"hideLabel":null,"hide":null,"onClickFunction":"","isAggregate":false,"iconClassMap":false,"iconFlag":false,"iconName":"","width":"","type":"date","fieldName":"celsrm__Promise_Date__c"},{"enableCopy":null,"isExport":null,"hideLabel":null,"hide":null,"onClickFunction":"","isAggregate":false,"iconClassMap":false,"iconFlag":false,"iconName":"","width":"","type":"currency","fieldName":"celsrm__Promised_Amount__c"},{"enableCopy":null,"isExport":null,"hideLabel":null,"hide":null,"onClickFunction":"","isAggregate":false,"iconClassMap":false,"iconFlag":false,"iconName":"","width":"","type":"currency","fieldName":"celsrm__Disputed_Amount__c"},{"enableCopy":null,"isExport":null,"hideLabel":null,"hide":null,"onClickFunction":"","isAggregate":false,"iconClassMap":false,"iconFlag":false,"iconName":"","width":"","type":"text","fieldName":"celsrm__Document_Type__c"},{"enableCopy":null,"isExport":null,"hideLabel":null,"hide":null,"onClickFunction":"","isAggregate":false,"iconClassMap":false,"iconFlag":false,"iconName":"","width":"","type":"text","fieldName":"celsrm__Posting_Key__c"},{"enableCopy":null,"isExport":null,"hideLabel":null,"hide":null,"onClickFunction":"","isAggregate":false,"iconClassMap":false,"iconFlag":false,"iconName":"","width":"","type":"text","fieldName":"celsrm__GL_Indicator__c"},{"enableCopy":null,"isExport":null,"hideLabel":null,"hide":null,"onClickFunction":"","isAggregate":false,"iconClassMap":false,"iconFlag":false,"iconName":"","width":"","type":"text","fieldName":"celsrm__Dunning_Block__c"},{"enableCopy":null,"isExport":null,"hideLabel":null,"hide":null,"onClickFunction":"","isAggregate":false,"iconClassMap":false,"iconFlag":false,"iconName":"","width":"","type":"text","fieldName":"celsrm__Dunning_Level__c"},{"enableCopy":null,"isExport":null,"hideLabel":null,"hide":true,"onClickFunction":"","isAggregate":false,"iconClassMap":false,"iconFlag":false,"iconName":"","width":"","type":"text","fieldName":"CurrencyIsoCode"}]'; //celsrm__Notes__c
        update listView;
        inMap = controller.invoke('changeListView', inMap);
        
        List<Map<Object, Object>> CriteriaGrid = new List<Map<Object, Object>>{
            new Map<Object, Object>{'value'=>'0', 'operator'=>'not equal to', 'type'=>'number', 'fieldName'=>'celsrm__Balance__c'},
            new Map<Object, Object>{'operator'=>'equals', 'type'=>'text', 'fieldName'=>'celsrm__Close_Date__c'}
        };
        List<Map<Object, Object>> SortingGrid = new List<Map<Object, Object>>{
            new Map<Object, Object>{'fieldName'=>'celsrm__DPD__c', 'order'=>'DESC', 'sortDirection'=>'<img src=\"/resource/CustomResource/image/sort_desc.png\" class=\"desc\" width=\"15\" height=\"15\"></img>'}
        };

        List<Map<Object, Object>> ColumnConfig = new List<Map<Object, Object>>();

        Map<Object, Object> column1 = new Map<Object, Object>{
            'enableCopy' => false,
            'isExport' => false,
            'hide' => true,
            'onClickFunction' => '',
            'isAggregate' => false,
            'iconClassMap' => false,
            'iconFlag' => false,
            'iconName' => '',
            'width' => '',
            'type' => 'text',
            'fieldName' => 'Id',
            'defaultField' => true,
            'MoveRowArea' => '<img src="/resource/CustomResource/image/arrow_up.png" class="up" width="15" height="15"></img><img src="/resource/CustomResource/image/arrow_down.png" class="down" width="15" height="15"></img>'
        };
        
        Map<Object, Object> column2 = new Map<Object, Object>{
            'hideLabel' => true,
            'onClickFunction' => '',
            'isAggregate' => false,
            'iconClassMap' => false,
            'iconFlag' => false,
            'iconName' => '',
            'width' => '',
            'type' => 'html',
            'fieldName' => 'celsrm__Flag__c',
            'MoveRowArea' => '<img src="/resource/CustomResource/image/arrow_up.png" class="up" width="15" height="15"></img><img src="/resource/CustomResource/image/arrow_down.png" class="down" width="15" height="15"></img>'
        };
        
        Map<Object, Object> column3 = new Map<Object, Object>{
            'enableCopy' => false,
            'isExport' => false,
            'hide' => false,
            'onClickFunction' => '',
            'isAggregate' => false,
            'iconClassMap' => false,
            'iconFlag' => false,
            'iconName' => '',
            'width' => '',
            'type' => 'link',
            'fieldName' => 'Name',
            'defaultField' => true,
            'MoveRowArea' => '<img src="/resource/CustomResource/image/arrow_up.png" class="up" width="15" height="15"></img><img src="/resource/CustomResource/image/arrow_down.png" class="down" width="15" height="15"></img>'
        };
        
        // Define other columns here...
        
        // Add all columns to SortingGrid
        ColumnConfig.add(column1);
        ColumnConfig.add(column2);
        ColumnConfig.add(column3);
        inMap.put('CriteriaGrid', CriteriaGrid);
        inMap.put('SortingGrid', SortingGrid);
        inMap.put('ColumnConfig', ColumnConfig);
        inMap.put('Operation', true);
        controller.invoke('saveListView', inMap);
        
        // listView.celsrm__Is_Global__c = true;
        // update listView;

        celsrm__Custom_List_View__c cl = new celsrm__Custom_List_View__c();
        User thisUser = [select Id from User where Id =: UserInfo.getUserId()];
        System.runAs(thisUser) {
            cl.Name =  'All Open Test2';
            cl.celsrm__ListView_For_Object__c = 'celsrm__Transaction__c';
            cl.Folder_Name__c = 'Collection';
            cl.celsrm__Object_Fields__c = '[{"enableCopy":false,"isExport":true,"hideLabel":null,"hide":true,"onClickFunction":"","isAggregate":false,"iconClassMap":false,"iconFlag":false,"iconName":"","width":"","type":"text","fieldName":"Id"},{"enableCopy":null,"isExport":null,"hideLabel":true,"hide":null,"onClickFunction":"","isAggregate":false,"iconClassMap":false,"iconFlag":false,"iconName":"","width":"","type":"html","fieldName":"celsrm__Flag__c"},{"enableCopy":false,"isExport":false,"hideLabel":null,"hide":false,"onClickFunction":"","isAggregate":false,"iconClassMap":false,"iconFlag":false,"iconName":"","width":"","type":"link","fieldName":"Name"},{"enableCopy":null,"isExport":null,"hideLabel":null,"hide":null,"onClickFunction":"","isAggregate":false,"iconClassMap":false,"iconFlag":false,"iconName":"","width":"","type":"currency","fieldName":"celsrm__Amount__c"},{"enableCopy":null,"isExport":true,"hideLabel":null,"hide":null,"onClickFunction":"","isAggregate":false,"iconClassMap":false,"iconFlag":false,"iconName":"","width":"","type":"currency","fieldName":"celsrm__Balance__c"},{"enableCopy":null,"isExport":null,"hideLabel":null,"hide":null,"onClickFunction":"","isAggregate":false,"iconClassMap":false,"iconFlag":false,"iconName":"","width":"","type":"text","fieldName":"celsrm__Po_Number__c"},{"enableCopy":null,"isExport":null,"hideLabel":null,"hide":null,"onClickFunction":"","isAggregate":false,"iconClassMap":false,"iconFlag":false,"iconName":"","width":"","type":"text","fieldName":"celsrm__So_Number__c"},{"enableCopy":null,"isExport":null,"hideLabel":null,"hide":null,"onClickFunction":"","isAggregate":false,"iconClassMap":false,"iconFlag":false,"iconName":"","width":"","type":"date","fieldName":"celsrm__Due_Date__c"},{"enableCopy":null,"isExport":null,"hideLabel":null,"hide":null,"onClickFunction":"","isAggregate":false,"iconClassMap":false,"iconFlag":false,"iconName":"","width":"","type":"number","fieldName":"celsrm__DPD__c"},{"enableCopy":null,"isExport":null,"hideLabel":null,"hide":true,"onClickFunction":"","isAggregate":false,"iconClassMap":false,"iconFlag":false,"iconName":"","width":"","type":"text","fieldName":"CurrencyIsoCode"}]';
            cl.celsrm__Is_Default__c = true;
            listView.celsrm__Is_Global__c = true;
            insert cl;
        }
        
        inMap.put('ListView', listView.Id);
        controller.invoke('deleteListView', inMap);
        
    }
}