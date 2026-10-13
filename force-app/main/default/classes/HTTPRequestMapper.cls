public with sharing class HTTPRequestMapper {
    public String body;
    public Blob bodyAsBlob;
    public String clientCertificateName;
    public String endpoint;
    public Map<String, String> header;
    public String method;
    public Integer timeout;

    public HTTPRequestMapper() {}

    public HTTPRequestMapper(String body, Blob bodyAsBlob, String clientCertificateName, String endpoint, Map<String, String> header, String method, Integer timeout) {
        this.body = body;
        this.bodyAsBlob = bodyAsBlob;
        this.clientCertificateName = clientCertificateName;
        this.endpoint = endpoint;
        this.header = header;
        this.method = method;
        this.timeout = timeout;
    }

    public Map<String, Object> send() {
        Map<String, Object> returnMap = new Map<String, Object>();
        try {
            // Instantiate a new http object
            Http h = new Http();

            // Instantiate a new HTTP request, specify the method (GET) as well as the endpoint
            HttpRequest req = new HttpRequest();
            req.setEndpoint(this.endpoint);
            req.setMethod(this.method);
            if(this.clientCertificateName!=null && this.clientCertificateName!='') {
                req.setClientCertificateName(this.clientCertificateName);
            }
            if(this.body!=null && this.body!='') {
                req.setBody(this.body);
            }
            system.debug('this.header'+ this.header);
            if(this.header != null && !this.header.isEmpty()) {
                for(String key : this.header.keySet()) {
                    req.setHeader(key, header.get(key));
                }
            }
            system.debug('req>>>' + req);
            HttpResponse res = h.send(req);
            returnMap.put('success', true);
            returnMap.put('response', res.getBody());
        } catch (Exception e) {
            returnMap.put('success', false);
            returnMap.put('response', e.getMessage());
        }
        return returnMap;
    }
}