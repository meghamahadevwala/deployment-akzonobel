public class MultiPartFileUpload {
    
    
    public Blob attBody {get;set;}
    
    public void SendMassEmailtoBuyers(){
        //uploadFile(attBody,'Payment1234.wav','https://storage.googleapis.com/upload/storage/v1/b/srm_speech_to_text/o?uploadType=media&name=demo/Payment1234.wav');
    }

    
    public static HttpRestCallout.HttpCalloutResponse uploadFile(Blob file_body, String file_name, String reqEndPoint,string authTokem){
          
          HttpRestCallout.HttpCalloutResponse calloutResponse = new HttpRestCallout.HttpCalloutResponse(); 
          HTTPResponse response;
          try{
            String boundary = '----------------------------741e90d31eff';
              String header = '--'+boundary+'\nContent-Disposition: form-data; name="file"; filename="'+file_name+'";\nContent-Type: audio/wav';
              
              // String footer = '\r\n--'+boundary+'--'; 
              String footer = '--'+boundary+'--';             
              String headerEncoded = EncodingUtil.base64Encode(Blob.valueOf(header+'\r\n\r\n'));
              while(headerEncoded.endsWith('='))
              {
               header+=' ';
               headerEncoded = EncodingUtil.base64Encode(Blob.valueOf(header+'\r\n\r\n'));
              }
              /*
              String bodyEncoded = EncodingUtil.base64Encode(file_body);
              // GW: Do not encode footer yet
              // String footerEncoded = EncodingUtil.base64Encode(Blob.valueOf(footer));
        
              Blob bodyBlob = null;
              String last4Bytes = bodyEncoded.substring(bodyEncoded.length()-4,bodyEncoded.length());
        
              
             // GW: replacement section to get rid of padding without corrupting data
             if(last4Bytes.endsWith('==')) {
                last4Bytes = last4Bytes.substring(0,2) + '0K';
                bodyEncoded = bodyEncoded.substring(0,bodyEncoded.length()-4) + last4Bytes;
                // We have appended the \r\n to the Blob, so leave footer as it is.
                String footerEncoded = EncodingUtil.base64Encode(Blob.valueOf(footer));
                bodyBlob = EncodingUtil.base64Decode(headerEncoded+bodyEncoded+footerEncoded);
              } else if(last4Bytes.endsWith('=')) {
                last4Bytes = last4Bytes.substring(0,3) + 'N';
                bodyEncoded = bodyEncoded.substring(0,bodyEncoded.length()-4) + last4Bytes;
                // We have appended the CR e.g. \r, still need to prepend the line feed to the footer
                footer = '\n' + footer;
                String footerEncoded = EncodingUtil.base64Encode(Blob.valueOf(footer));
                bodyBlob = EncodingUtil.base64Decode(headerEncoded+bodyEncoded+footerEncoded);              
              } else {
                // Prepend the CR LF to the footer
                footer = '\r\n' + footer;
                String footerEncoded = EncodingUtil.base64Encode(Blob.valueOf(footer));
                bodyBlob = EncodingUtil.base64Decode(headerEncoded+bodyEncoded+footerEncoded);  
              }*/
        
              HttpRequest req = new HttpRequest();
              req.setHeader('Content-Type','multipart/form-data; boundary='+boundary);
              req.setHeader('Authorization','Bearer ' + authTokem);
              req.setMethod('POST');
              req.setEndpoint(reqEndPoint);
              req.setBodyAsBlob(file_body);
              req.setTimeout(120000);
        
              Http http = new Http();
              response = http.send(req);
              System.debug('Response Header: ' + response.getStatusCode());
              System.debug('Response Body: ' +response.getBody());
              
              calloutResponse.statusCode = response.getStatusCode();
              calloutResponse.response = response.getBody();
          }catch(Exception e){
               System.debug(' ERROR :: callout() :: ' + e);
               system.debug(' ERROR :: callout() :: ' + e.getMessage());
              system.debug(' ERROR :: response :: ' + response);
               /*calloutResponse.statusCode = response.getStatusCode();
               calloutResponse.response = response.getBody(); */
              calloutResponse.statusCode = 500;
               calloutResponse.response = 'ERROR';
          }
          
          return calloutResponse;
    }
}