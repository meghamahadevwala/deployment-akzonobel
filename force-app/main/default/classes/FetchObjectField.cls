global with sharing class FetchObjectField implements celsrm.GOGIScreenCustomLogic {
    global Map<Object, Object> invoke(String functionName, Map<Object, Object> inMap) {
    
        /*
            if(!inMap.containsKey('ListViewObject') || inMap.get('ListViewObject') == null || inMap.get('ListViewObject') == '') {
            throw new AuraHandledException('List View Object is not specified');
        } else
        */
    String objectName = '';
   
    if( inMap.containsKey('values') ){
        Map<String,Object> mapOfValues = (Map<String,Object>) JSON.deserializeUntyped(JSON.serialize(inMap.get('values')));
        if( mapOfValues.containsKey('ListViewObject') ){
                objectName = String.valueOf(mapOfValues.get('ListViewObject'));
            }
        } else if((boolean)inMap.containsKey('ListViewObject')){
            objectName = String.valueOf(inMap.get('ListViewObject'));
        } else{
            throw new AuraHandledException('List View Object is not specified');
        }
        List<Map<String,String>> returnOptions = new List<Map<string,String>>();
        Map<String, Schema.SObjectField> fieldMap = Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap();
        Map<String,String> tmp;
        if(functionName == 'DualListBox') {
            for (Schema.SObjectField sObjectField : fieldMap.values()) {
                Schema.DescribeFieldResult descrFieldResult = sObjectField.getDescribe();
                  if( descrFieldResult.getName() !='isdeleted' && descrFieldResult.getName() != 'CreatedById' && descrFieldResult.getName() != 'LastModifiedById' && descrFieldResult.getName() != 'Id'){
                tmp = new Map<String,String>();
                tmp.put('label', descrFieldResult.getLabel());
                tmp.put('value', descrFieldResult.getName());
                returnOptions.add(tmp);
                }
            }
        } else {
            for (Schema.SObjectField sObjectField : fieldMap.values()) {
                Schema.DescribeFieldResult descrFieldResult = sObjectField.getDescribe();
                if(descrFieldResult.getType() != Schema.DisplayType.TextArea && descrFieldResult.getName() !='isdeleted' && descrFieldResult.getName() != 'CreatedById' && descrFieldResult.getName() != 'LastModifiedById' && descrFieldResult.getName() != 'Id') {
                    tmp = new Map<String,String>();
                    tmp.put('label', descrFieldResult.getLabel());
                    tmp.put('value', descrFieldResult.getName());
                    returnOptions.add(tmp);
                }
            }
        }
        
        inMap.put('dataServiceResponse', returnOptions);
        return inMap;
    }
}