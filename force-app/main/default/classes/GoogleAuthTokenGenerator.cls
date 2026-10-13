public with sharing class GoogleAuthTokenGenerator {

    // NOTE - DONT PUT THIS KEY HERE IN A PROD SCENARIO - SEE ARTICLE ON SECURE CODING STORING SECRETS
  private static final String CLIENT_KEY = 'MIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQCqx7jKPzitsInpUj+Xnf33qKKdDrRpwB6J7JaTrP5D8oVmIWRIRNXFP9XAeb1GIwgkBnTPjHAexLcB5ILvz5qXgj14gLWPzKNMRhvQrFM+/NpR+RNWYCbDT8kLuLsMYVTdh5R1HTgi+GA8isgEzx/aK3GuHwLe/5gBBqSCO30hGLIFSDZbp1W/fGRlTZwr6dE1tGcUBjXbtCTDTz1U+XVaFJvgiAnjJibfkaHZgwFXqHf0VZgb1nj+SHRuG0m06Nk/FNU7tnP/ztCl/lZNkFhP5Jgm02zW2p9yWSAvkc4oceKXN/CICic3sF876mcXq1UErptZTb+3G+izNXa3FG77AgMBAAECggEABNvOwY4/5g0eN1GcNouLpKabDb3T2yhYlhLxi70BtNwq+Gddy4KN1GFHCwVLobmwaxn168uyiuWM0VR3dywgWUwexJVg1Pj88lgSRYMJkUKvUWK1LqFoqOjVruwwAh+owu6vBg/xP2lyj3ZhT2W3IcVXpB0Ev2RlJi5SstPPcQgPbfnV4NHOB1jTFuoN9nDBdecIP87JDoQNo8Y502wm7GUPudMmL04aMfApiQ/6zMt0n47sxHUiI3++s8fpzZbfOhJ3lSRvW6dQ26oFEJenpsyKOMt7I5+YYs5TVI2ylRMXlahbnEOE2xXeIdQLVJJZfBCYzo5DsZnmFZ8Qs3W0LQKBgQDV7cQ5hMYDFrnXicU8+xLblOw84c+67AeieyP01Sd4jKbbuZVWWorRBznBKNzhiKGNOJqLgNO7hEyrTo4AqYLwPXpMbqBEYBCPGRjGrnI2Hne8/b153HCdvYlKNs2l+js5Nm9LhKZARTizQPysNQrKHRFDhknRFfc934ktixA1rwKBgQDMXaP/xSSfLzLw2XQRaOXNPU6zPuiUbt6Iwj/LzvpgIlorIE5ZZqdZaM4HpyxJlF0na0PTgQFsLOeBhD9JQAeKRoCzR/hBDJmYQm1STPsWh1mhhChs42I/b+z+bIIYjzGPQZ/Cp2FG6DUwCbupXQHh1CzXbP1x1xceFtyj/nH6dQKBgFTbd5aJQDJBdX41u/MwdI59SCfuOoQe0/hzeBPJ6Vo8EIPf3YjfaWj4wMQJ/XPIyqxF46eqdlJPbEoXYuSIWNQKztQ6nYAByw+4GMfWsp8c/soMrHgGJPWtFSRHENPhqlRLb2I5P+kGjDMueAunDpyVYx+xyN4TJHt6i+Nw4gEpAoGAWljngNJ5/znRjnLEAlJajaKV4V5lWgGttc4SgBqvy8JEFJ7CpHlicH+J3g5E4P6LNDsSkDWPGHC9pB+ADvUUoEfM6/VcRf25BXwQcnr/4hTSRjpz2LepnpvvrQbxeMQNR+TeKSLwOXW81dDnutcYVusDK/XOEf7iBHZc8s8xOmUCgYEAx7yCCP684jcBZJ8V2kBgYLKSqV9ECriOZhy9E6lH4LnA07QMTcl/caAOhjjvnjaLLRvzUomFK14YQEPB8Pd/VVA3F3Zv52xxQTqfCZYcCfujB1aBYokSg8lZmlZFUuiXp7PDBM9KoPBsvX9wzHHtnR4cQPBIzzXVS4JbSEEuOYo=';
  private static final String CLIENT_SCOPE = 'https://www.googleapis.com/auth/cloud-platform';
  private static final String CLIENT_EMAIL = 'sailfin-auto-ml@sailfin-auto-ml.iam.gserviceaccount.com';

    
    public Token generateAuthToken(){
        String jwt = generateJWT(CLIENT_KEY, CLIENT_SCOPE, CLIENT_EMAIL);
        System.debug('jwt : ' + jwt);
        Token t = getToken(jwt);
        return t;
      }
    
      
    
      public Token getToken(String jwt) {
    
        Httprequest req = new HttpRequest();
        req.setEndpoint('https://www.googleapis.com/oauth2/v4/token');
        req.setMethod('POST');
        req.setHeader('Content-Type','application/x-www-form-urlencoded');
    
        String body = '';
        body = 'grant_type='+EncodingUtil.urlEncode('urn:ietf:params:oauth:grant-type:jwt-bearer','UTF-8');
        body += '&assertion='+jwt;
        req.setBody(body);
    
        Http h = new Http();
        HttpResponse res = h.send(req);
        system.debug('res : ' + res.getBody());
        return (Token)JSON.deserialize(res.getBody(), Token.Class);
        }
    
      private String generateJWT(String key, String scope, String clientEmail){
    
        String header = '{"alg":"RS256","typ":"JWT"}';
        String headerUrlBase64Encode = EncodingUtil.base64Encode(Blob.valueOf(header));
        String headerBase64UrlEncode = EncodingUtil.urlEncode(headerUrlBase64Encode, 'UTF-8');
    
        long currentTime = datetime.now().getTime()/1000;
        long expiryTime = datetime.now().addHours(1).getTime()/1000;
    
        ClaimSet claimSet = new ClaimSet();
        claimSet.iss = clientEmail;
        claimSet.scope = scope;
        claimSet.aud = 'https://www.googleapis.com/oauth2/v4/token';
        claimSet.exp = expiryTime;
        claimSet.iat = currentTime;
    
        String clailSetJson = JSON.serialize(claimSet);
        String claimSetBaseEncode = EncodingUtil.base64Encode(Blob.valueOf(clailSetJson));
        String claimSetBase64UrlEncode = EncodingUtil.urlEncode(claimSetBaseEncode, 'UTF-8');
    
        String algorithmName = 'RSA-SHA256';
        Blob privateKey = EncodingUtil.base64Decode(key);
        Blob input = Blob.valueOf(headerBase64UrlEncode+'.'+claimSetBase64UrlEncode);
        Blob signed = Crypto.sign(algorithmName, input, privateKey);
        String signedBase64Encode = EncodingUtil.base64Encode(signed);
        String signedStrBase64UrlEncode = EncodingUtil.urlEncode(signedBase64Encode, 'UTF-8');
    
        String jwt = headerBase64UrlEncode+'.'+claimSetBase64UrlEncode+'.'+signedStrBase64UrlEncode;
        return jwt;
      }
    
      private class ClaimSet{
    
        private String iss;
        private String scope;
        private String aud;
        private long exp;
        private long iat;
      }
    
      public class Token{
    
        public String access_token;
        public String token_type;
        public String expires_in;
      }
}