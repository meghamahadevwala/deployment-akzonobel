@isTest
public with sharing class HTTPRequestMapperTest {
    public static testmethod void HTTPRequestMapperTest() {

        Map<String, String> header = new Map<String, String>();
        header.put('type', 'test');
        header.put('auth', 'auth');

        HTTPRequestMapper reqMapper = new HTTPRequestMapper();
        reqMapper = new HTTPRequestMapper('body', Blob.valueOf('body as a blob'), 'clientCertificateName', 'endpoint', header, 'post', 1000);
        reqMapper.send();
        
        reqMapper = new HTTPRequestMapper('body', Blob.valueOf('body as a blob'), null, 'endpoint', header, 'post', 1000);
        reqMapper.send();
    }
}