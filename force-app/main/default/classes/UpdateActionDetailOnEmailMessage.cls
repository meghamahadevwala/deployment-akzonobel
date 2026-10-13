global class UpdateActionDetailOnEmailMessage implements celsrm.GOGIScreenCustomLogic {
    global Map<Object, Object> invoke(String functionName, Map<Object, Object> inMap){
        Map<String,Object> reqParamMap = new Map<String,Object>();
        if (inMap.containsKey('actionName')) {
            Map<Object, Object> aData = (Map<Object, Object>)inMap.get('activityData');
            reqParamMap.put('emailId',(String)aData.get('Id'));
            reqParamMap.put('actionName',inMap.get('actionName'));
            reqParamMap.put('action',functionName);
            if (inMap.containsKey('oldValue')) {
                reqParamMap.put('oldValue',inMap.get('oldValue'));
            }
            if (inMap.containsKey('newValue')) {
                reqParamMap.put('newValue',inMap.get('newValue'));
            }
            Map<String,String> response = celsrm.GOGUtilityWithoutSharingController.updateEmailActionCount(reqParamMap);
            if (response.containsKey('Error')) {
                throw new celsrm.GOGDataServiceLoadException(response.get('Error'));         
            }
        }
        
        return inMap;
    }
}