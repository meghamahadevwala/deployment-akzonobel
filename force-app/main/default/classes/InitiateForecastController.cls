global with sharing class InitiateForecastController implements celsrm.GOGIScreenCustomLogic {
    global Map<Object, Object> invoke(String functionName, Map<Object, Object> inMap) {
        try {
            if (functionName == 'initiateForecast') {
                List<String> period = String.valueOf(inMap.get('Period')).split('-');
                // Integer forecastMonth = Integer.valueOf(inMap.get('ForecastMonth'));
                Integer forecastMonth = Integer.valueOf(period[0]);
                // Integer forecastYear = Integer.valueOf(inMap.get('ForecastYear'));
                Integer forecastYear = Integer.valueOf(period[1]);
                Integer DSO =  Integer.valueOf(inMap.get('avgDSO'));
                Integer BPDSO =  Integer.valueOf(inMap.get('bpDSO'));
                Database.executeBatch(new UpdateForecastBatch(forecastMonth, forecastYear, DSO, BPDSO), 200);
            }
        } catch (Exception ex) {
            throw new celsrm.CustomException(ex.getMessage()+'::'+ex.getStackTraceString());
        }
        return inMap;
    }
}