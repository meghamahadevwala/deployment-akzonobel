public with sharing class CreditLimitChangeHistoryChartController {
    @AuraEnabled
    public static List<Map<String, Object>> getChartDetails(Id recordId) {
        
        Map<Object, Object> inMap = new Map<Object, Object>();
        inMap.put('page', 0);
        inMap.put('pageSize', 50);
        inMap.put('Id', recordId);

        GetDataFromCelonisController getDataFromCelonisController = new GetDataFromCelonisController();
        Map<Object, Object> resultMap =getDataFromCelonisController.getCreditLimitChanges(inMap);
        List<Map<String, Object>> changeHistories;
        if (resultMap.containsKey('dataServiceResponse') && resultMap.get('dataServiceResponse') instanceof List<Object>) {
            changeHistories = (List<Map<String, Object>>) resultMap.get('dataServiceResponse');
        } else {
            changeHistories = new List<Map<String, Object>>();
        }        
        return changeHistories;
    }
}