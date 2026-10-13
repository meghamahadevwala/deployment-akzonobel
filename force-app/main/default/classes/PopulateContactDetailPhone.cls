global class PopulateContactDetailPhone implements celsrm.GOGIScreenCustomLogic {
    global Map<Object, Object> invoke(String functionName, Map<Object, Object> inMap) {
        system.debug('functionName>>>'+functionName);
        if(String.valueOf(inMap.get('ContactName') )!= ''){
            Contact Con = [Select Phone from contact where id =:String.valueOf(inMap.get('ContactName'))];
            inMap.put('ContactCalled',Con.phone);
        }
        return inMap;
    }
}