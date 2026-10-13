public with sharing class HttpRestCallout {
    
    public class HttpCalloutResponse{
        public Integer statusCode;
        public String response;
        public Blob blobData;
    }

    public static HttpCalloutResponse makeAcallout(String endPoint,String methodType,String body,Map<String,String> headers,boolean isBlobData){
        HttpCalloutResponse response = new HttpCalloutResponse();
        HttpResponse httpResponse;
        try{
           Http http = new Http();
           
           HttpRequest request = new HttpRequest();
           request.setEndpoint(endPoint);
           request.setTimeout(120000);
           request.setMethod(methodType);
           
            if(headers != null && headers.size() > 0){
                for(String headerName :headers.keyset()){
                    request.setHeader(headerName, headers.get(headerName));
                }
            }
            
            if(body != null && body.length() > 0){
                request.setBody(body);
            }
            httpResponse = http.send(request);
            System.debug('Response Code : ' + httpResponse.getStatusCode());
            //System.debug('Response Body: ' +httpResponse.getBody());
            response.statusCode = httpResponse.getStatusCode();
            if(isBlobData){
                response.blobData = httpResponse.getBodyAsBlob();
            }else{
                response.response = httpResponse.getBody();
            }
            
        }catch(Exception e){
           System.debug(' ERROR :: callout() :: ' + e);
           system.debug(' ERROR :: callout() :: ' + e.getMessage());
           response.statusCode = httpResponse.getStatusCode();
           response.response = httpResponse.getBody();
       }
       return response;
   }
}