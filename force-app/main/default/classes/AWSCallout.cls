public class AWSCallout {

    //Named credentials
    /*@AuraEnabled
    public static void getAwsIntegrate() {        
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:Integrate_AWS_S3/');
        req.setTimeout(120000);
        req.setMethod('PUT');
        req.setHeader('Content-Type','application/json');
        req.setBody('{"test":"test"}');

        Http h = new Http();
        HTTPResponse res = h.send(req);
        System.debug('response:######' + res);   
        System.debug('getEndpoint: ' + req.getEndpoint()); 
        
        Integer StatusCode = Integer.valueof(res.getStatusCode());
        String Status = String.valueof(res.getStatus());
        String body = String.valueof(res.getBody());
        
        system.debug('getStatusCodeAAA ' + StatusCode);
        system.debug('getStatusBBB ' + Status);
        system.debug('getBody ' + body);
    }*/

	/**  
	* Name : Sahi wadhwa
	* Date : 09/05/2022
	* Description : This method is used to make the STS call and send the payload to AWS
	**/
    @future(callout = true)
    public static void callSTSAssumeRole(String method, String endPoint , String payload, String serviceName){

        Session_Management__mdt sessionInfo = [SELECT Access_Key__c,Secret_Access_Key__c,Session_Token__c FROM Session_Management__mdt WHERE DeveloperName ='Session_Management' LIMIT 1 ];
        String accessKeyId = sessionInfo.Access_Key__c;
        // accessKeyId = 'ASIAYH766F7IXP5U6K4H';
        String secret = sessionInfo.Secret_Access_Key__c; 
        // secret = 'm1MFt7ThHckDXU6JNJRR9ngSb8DpU78W19fIngFC';
        String securityToken = sessionInfo.Session_Token__c;
        // securityToken = 'IQoJb3JpZ2luX2VjEIX//////////wEaDmFwLXNvdXRoZWFzdC0yIkgwRgIhANEyF/blIr2t3A5zjG9mEKcLTye1pZDuGyZRGmOz1mF7AiEAsD6mMHaM9ABKyv6aZ/4Z9kJtL8+5ORFFW9H9AbBl6e8qngII7v//////////ARADGgw1NjY5MzM0NjcwODkiDGsz0114Fyz43i0kQiryAR2Dy4bJXA1GzL2QCJqzo2vVLAkHY42RxGMWA/QjzvHYtwdK2KNnUVdes2gIeBRQcyg+DrFMfqWnHkJ/Ou8AeKenKC+qpnEhR/byBmA5vA6+DC8ZoyPgzcsj39MMDwuREcQjtnJCYXV0YiEf3mvcRhBPgFLzeCro7vePy1ddWhybK8ifMnu2WModWK7OJe8CjSCG5SXWt7JuvjmZ5zpyKwqvrVo8vlDbZLUIUdt38DbzX5Hb4YhFK16QedSgd/q5C4k1s73CiGIPIQ6QiP0slVe+jlI0ETMYJIO4Aibk2Id3mAVweKzaR0Dv3NxyMQq74G5TMMKvv54GOpwBtNfTdz8eIwtgJByX/vXEOMt8/CiS+0d07bW1X+hRPviOMZvzXz1P3PYhbIDL4SyVvmoSsXFgJNGiS4VqREVKMmtuQjlCCi8Ge9EBmqkAbELqs1OJ7keixRgsbL15sqiSaUCi9m2Q36sJ2F0q9xnH/fGHLhP7l/fijZleWqbcXhwxOHvZrWAbyWE1xeuayDbrfOOxbDUfnE2gPW5m';

        // Break the end point url
        String endPointLast = endPoint.remove('https://').substringAfter('/');
        endPointLast = '/'+endPointLast;
        //Build AWS Signature 
        String dateNowYear = Datetime.now().formatGMT('yyyMMdd');
        String region = 'ap-southeast-2';
        String service = serviceName;

        HTTPResponse resp = sendRequest(endPoint,  method, payload, region, service, accessKeyId, secret, securityToken, dateNowYear);

        System.debug('response:######' + resp);                
        System.debug('getStatusCode1: ' + Integer.valueof(resp.getStatusCode()));
        System.debug('getStatus1: ' + String.valueof(resp.getStatus()));
        System.debug('getBody1: ' + String.valueof(resp.getBody())); 

        // Boolean hasTokenIssue = false;

        // if(Integer.valueof(resp.getStatusCode()) == 400){

            // response body {"message": "Invalid request body"}
            // XmlStreamReader reader = new XmlStreamReader(String.valueof(resp.getBody()));

            // boolean isSafeToGetNextXmlElement = true;

            // while(isSafeToGetNextXmlElement) {
            //     // Start at the beginning of the book and make sure that it is a book
            //     if (reader.getEventType() == XmlTag.START_ELEMENT) {
            //         System.debug('@reader.getLocalName(): ' + reader.getLocalName());
            //         if ('Code' == reader.getLocalName()) {
            //             // String errorCode = reader.getAttributeValue(null, 'Code');
            //             reader.next();
            //             System.debug('@reader.getLocalName(): ' + reader.getLocalName());
            //             if(reader.getText().equalsIgnoreCase('ExpiredToken') || reader.getText().equalsIgnoreCase('InvalidToken')) {
            //                 hasTokenIssue = true;
            //             }
            //             break;
            //         }
            //     }
            //     // Always use hasNext() before calling next() to confirm 
            //     // that we have not reached the end of the stream
            //     if (reader.hasNext()) {
            //         reader.next();
            //     } else {
            //         isSafeToGetNextXmlElement = false;
            //         break;
            //     }
            // }
        // }
        
        // refresh token
        if(Integer.valueof(resp.getStatusCode()) == 403 || Integer.valueof(resp.getStatusCode()) == 401) {            
            
            // We make the 1st request to STS
            // query AWS assume role endpoint
            /*Integration_Endpoint__mdt awsAssumeRoleEndpoint = MSN_Utility.getEndpointSetting('AWS_Assume_Role');

            HttpRequest req2 = new HttpRequest();
            req2.setEndpoint('callout:AWS_STS_Dev/' + awsAssumeRoleEndpoint.Endpoint__c);
            req2.setTimeout(120000);
            req2.setMethod('GET');
            req2.setHeader('Content-Type','application/json');

            Http h2 = new Http();
            HTTPResponse res2 = h2.send(req2);
            System.debug('response:######' + res2);  
                
            if(Integer.valueof(res2.getStatusCode()) != 200) {
                MSN_HandleErrorsException.insertIntegrationException( payload,  endpoint,res2);
            }
                
            Integer StatusCode = Integer.valueof(res2.getStatusCode());
            String Status = String.valueof(res2.getStatus());
            String body = String.valueof(res2.getBody());
            
            system.debug('getStatusCode2 ' + StatusCode);
            system.debug('getStatus2 ' + Status);
            system.debug('getBody2 ' + body);

            String domNamespace = 'https://sts.amazonaws.com/doc/2011-06-15/';
            Dom.Document doc = res2.getBodyDocument();

            Map<String, String> updateSessionInfo = MSN_CalloutAWSHelper.getCredentialsFromSTSTokenResponse(doc, domNamespace);
            */
            Map<String, String> updateSessionInfo;
            if(!Test.isRunningTest()) {
                updateSessionInfo = refreshSession(payload, endPoint);

                accessKeyId = updateSessionInfo.get('Access_Key__c');
                secret = updateSessionInfo.get('Secret_Access_Key__c');
                securityToken = updateSessionInfo.get('Session_Token__c');
            }
            else {
                updateSessionInfo = new Map<String, String>();
                updateSessionInfo.put('Access_Key__c', 'abc');
                updateSessionInfo.put('Secret_Access_Key__c', 'dcd');
                updateSessionInfo.put('Session_Token__c', 'xxx');
            }
            
            resp = sendRequest(endPoint,  method, payload, region, service, accessKeyId, secret, securityToken, dateNowYear);
          
            System.debug('response:######' + resp);  
                
            Integer StatusCode = Integer.valueof(resp.getStatusCode());
            String Status = String.valueof(resp.getStatus());
            String body = String.valueof(resp.getBody());
            
            system.debug('getStatusCode ' + StatusCode);
            system.debug('getStatus ' + Status);
            system.debug('getBody ' + body);
        
            if(Integer.valueof(resp.getStatusCode()) != 200) {
                MSN_HandleErrorsException.insertIntegrationException( payload,  endpoint, resp);
            }

            MSN_MetadataInsertUpdate.handleInsertAndUpdate('Session_Management.Session_Management', 'Session_Management', updateSessionInfo);
		}
        else if(Integer.valueof(resp.getStatusCode()) != 200) {
            MSN_HandleErrorsException.insertIntegrationException( payload, endpoint, resp);
        }
        
        
    }

    @TestVisible private static Map<String, String> refreshSession(String payload, String endpoint) {
        // We make the 1st request to STS
        // query AWS assume role endpoint
        Integration_Endpoint__mdt awsAssumeRoleEndpoint = MSN_Utility.getEndpointSetting('AWS_Assume_Role');

        HttpRequest req2 = new HttpRequest();
        req2.setEndpoint('callout:AWS_STS_Dev/' + awsAssumeRoleEndpoint.Endpoint__c);
        req2.setTimeout(120000);
        req2.setMethod('GET');
        req2.setHeader('Content-Type','application/json');

        Http h2 = new Http();
        HTTPResponse res2 = h2.send(req2);
        System.debug('response:######' + res2);  
            
        if(Integer.valueof(res2.getStatusCode()) != 200) {
            MSN_HandleErrorsException.insertIntegrationException( payload,  endpoint,res2);
        }
            
        Integer StatusCode = Integer.valueof(res2.getStatusCode());
        String Status = String.valueof(res2.getStatus());
        String body = String.valueof(res2.getBody());
        
        system.debug('getStatusCode2 ' + StatusCode);
        system.debug('getStatus2 ' + Status);
        system.debug('getBody2 ' + body);

        String domNamespace = 'https://sts.amazonaws.com/doc/2011-06-15/';
        Dom.Document doc = res2.getBodyDocument();

        Map<String, String> updateSessionInfo = MSN_CalloutAWSHelper.getCredentialsFromSTSTokenResponse(doc, domNamespace);

        return updateSessionInfo;
    } 

    public static HTTPResponse sendRequest(String endPoint,  String method, String payload, 
                                                String region, String service, 
                                                String accessKey, String secretKey, String securityToken, 
                                                String dateNowYear) {
        
        String requestUrl = '/' + endPoint.remove('https://').substringAfter('/');
        String hostURl = endPoint.remove('https://').substringBefore('/');
        String dateNowLong = Datetime.now().formatGMT('yyyMMdd\'T\'HHmmss\'Z\'');
        String payloadHash = MSN_CalloutAWSHelper.createPayloadHash(payload);

        // TODO: need to be fixed by using helper methods in MSN_CalloutAWSHelper due to 'not matched signature' issue.
        // not sure why it happened, code looks identical to the code section below. 
        Map<String, String> signatureDetails = new Map<String, String>{
            'endpoint' => endPoint,
            'requestUrl' => requestUrl,
            'hostURL' => hostURl,
            'method' => method,
            'content-type' => 'application/json',
            'date' => Datetime.now().formatGMT('yyyMMdd'), //format: 'yyyMMdd''
            'amz-date' => dateNowLong, //format: 'yyMMdd\'T\'HHmmss\'Z\'''
            'SessionToken' => securityToken,
            'content' => payload,
            'contentHash' => payloadHash,
            'service' => service,
            'AccessKeyId' => accessKey,
            'SecretAccessKey' => secretKey,
            'region' => region
        };

        // HttpRequest req = MSN_CalloutAWSHelper.buildAWSRequest(signatureDetails);

        Blob contentsToSend = Blob.valueOf(payload);

        String strPayloadHash = EncodingUtil.convertToHex(Crypto.generateDigest('sha-256', contentsToSend));
        
        //generate canonicalRequest
        String canonicalRequest = method;
        canonicalRequest = canonicalRequest + '\n' + requestUrl + '\n';
        // canonicalRequest = canonicalRequest + '\n\ncontent-length:' + String.valueOf(contentsToSend.size());
        // canonicalRequest = canonicalRequest + '\ncontent-type:application/json';
        // canonicalRequest = canonicalRequest + '\ndate:';
        canonicalRequest = canonicalRequest + '\nhost:' + hostURL; //Resource Host URL
        canonicalRequest = canonicalRequest + '\nx-amz-content-sha256:' + strPayloadHash.toLowerCase();
        canonicalRequest = canonicalRequest + '\nx-amz-date:' + dateNowLong;
        canonicalRequest = canonicalRequest + '\nx-amz-security-token:' + securityToken;
        canonicalRequest = canonicalRequest + '\n\nhost;x-amz-content-sha256;x-amz-date;x-amz-security-token';
        canonicalRequest = canonicalRequest + '\n' + strPayloadHash.toLowerCase();

        System.debug('CanRequest: ' + canonicalRequest);

        //sign the key
        String strCanonicalHash = EncodingUtil.convertToHex(Crypto.generateDigest('SHA-256', Blob.valueOf(canonicalRequest)));
        
        System.debug('strCanonicalHash:' + strCanonicalHash);

        String strStringToSign = '';
        strStringToSign += 'AWS4-HMAC-SHA256\n';
        strStringToSign += dateNowLong + '\n';
        strStringToSign += dateNowYear + '/' + region + '/' + service + '/aws4_request';
        strStringToSign += '\n' + strCanonicalHash.toLowerCase();

        System.debug('strStringToSign:' + strStringToSign);

        //create/calculate signature
        Blob signingKey = createSigningKey(secretKey, service, region);
        String signature = EncodingUtil.convertToHex(Crypto.generateMac('hmacSHA256', Blob.valueOf(strStringToSign), signingKey));
        signature = signature.toLowerCase();

        System.debug('signature should be:' + signature);

        //Add auth credentials
        String credential_scope = dateNowYear + '/' + region + '/' + service + '/' + 'aws4_request, ';

        //create auth header
        String strAuthorizationHeader = 'AWS4-HMAC-SHA256 ';
        strAuthorizationHeader += 'Credential=' + accessKey + '/' + credential_scope;
        strAuthorizationHeader += 'SignedHeaders=host;x-amz-content-sha256;x-amz-date;x-amz-security-token, ';
        strAuthorizationHeader += 'Signature=' + signature;

        HttpRequest req = new HttpRequest();
        req.setEndpoint(endPoint);
        req.setTimeout(120000);
        //req.setMethod('PUT');
        req.setMethod(method);
        req.setHeader('Content-Type','application/json');
        req.setHeader('Authorization', strAuthorizationHeader);
        req.setHeader('X-Amz-Date', dateNowLong);
        req.setHeader('X-Amz-Security-Token', securityToken);
        req.setHeader('X-Amz-Content-sha256', strPayloadHash.toLowerCase());
        //req.setBody(filledJson());
        if(String.isNotBlank(payload)) {
            req.setBody(payload);
        }

        Http h = new Http();
        HTTPResponse resp = h.send(req);
        System.debug('response:######' + resp);  
        return resp;
    }

    public static Blob createSigningKey(String secretKey, string service, string region){
        return Crypto.generateMac('hmacSHA256', Blob.valueOf('aws4_request'),
            Crypto.generateMac('hmacSHA256', Blob.valueOf(service),
                Crypto.generateMac('hmacSHA256', Blob.valueOf(region),
                    Crypto.generateMac('hmacSHA256', Blob.valueOf(Datetime.now().formatGMT('YYYYMMdd')), Blob.valueOf('AWS4'+secretKey))
                )
            )
        );
    }
        
}