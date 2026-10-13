public with sharing class IAPIService {
    Celonis_Team_Details__c celTeamDetails;

    public IAPIService() {
        celTeamDetails = Celonis_Team_Details__c.getOrgDefaults();
    }

    public Map<String, Object> invoke(String recordId, List<String> fields, List<String> filterExpr, List<String> sortList, String order, Integer p, Integer pSize) {
        System.debug('in map val is ' + recordId);
        Map<String, Object> returnMap = new Map<String, Object>();
        String page = p != null ? String.valueOf(p) : '0';
        String pageSize = pSize != null ? String.valueOf(pSize) : '10';
        // String pageSize = '5000';
        String columnStr = fields != null && fields.size() > 0 ? String.join(fields, ',') : '';
        String filtersStr = filterExpr != null && filterExpr.size() > 0 ? String.join(filterExpr, ',') : null;
        String sortStr = sortList != null && sortList.size() > 0 ? String.join(sortList, ',') : '';

        String kmKey = celTeamDetails.Knowledge_Model_Key__c;
        //String apiUrl = celTeamDetails.Team_URL__c + '/intelligence/api/knowledge-models/' + kmKey + '/records/' + recordId +
          //              '/data?pageSize=' + pageSize + '&page=' + page + '&fields=' + columnStr;
        String apiUrl = '/intelligence/api/knowledge-models/' + kmKey + '/records/' + recordId +
                         '/data?pageSize=' + pageSize + '&page=' + page + '&fields=' + columnStr;
        apiUrl += filtersStr != null ? '&filterExpr=' + filtersStr.replace(' ', '%20') : '';
        apiUrl += sortStr != null ? '&sort=' + sortStr : '';
        //String appKey = celTeamDetails.Application_Key__c;

        HttpRequest request = new HttpRequest();
        // request.setEndpoint(apiUrl);
        request.setEndpoint('callout:CelonisEMS'+ apiUrl);
        request.setMethod('GET'); // Change method as needed (GET, POST, etc.)
        request.setHeader('Content-Type', 'application/json');
        // request.setHeader('Authorization', 'AppKey ' + appKey);

        HttpResponse response = new Http().send(request);

        if (response.getStatusCode() == 200) {
            // Successful response handling
            String responseBody = response.getBody();
            System.debug('API Response: ' + responseBody);
            returnMap = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
        } else {
            // Error handling
            System.debug('API Request failed with status code: ' + response.getStatusCode());
            System.debug('Response Body: ' + response.getBody());
            returnMap.put('statusCode',response.getStatusCode());
        }
        return returnMap;
    }
}