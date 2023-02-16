/**
 * @File Name          : MSN_CalloutAWSHelper.cls
 * @Description        : Create AWS Signture requests using the AWS Signature Protocol
 * @Author             : David Azzi
 * @Group              : 
 * @Last Modified By   : David Azzi
 * @Last Modified On   : 23/11/2021
 * @Modification Log   : 
 * Ver      Date            Author                  Modification
 * 1.0      23/11/2021      David Azzi              Initial Version
**/

public with sharing class MSN_CalloutAWSHelper {

    /*
        David Notes
        I was able to build the signature by using an AWS named credential, and then building a signature with the
        token that was returned. I wasn't able to test it outside of my own test environment. There was one 
        spike that was done to the MSN team however //TODO THIS NEEDS MORE TESTING

        I also haven't added any error checking
    */

    /*
    AWS String layout
        Map<String, String> Signature Details:
            endpoint
            requestUrl
            hostURL
            method
            content-type
            date //format: 'yyyMMdd'
            amz-date //format: 'yyMMdd\'T\'HHmmss\'Z\''
            SessionToken
            content
            contentHash
            method      
            service
            AccessKeyId
            SecretAccessKey
            region

    */


    public static Map<String, String> getCredentialsFromSTSTokenResponse(Dom.document doc, String namespace){
        Map<String, String> output = new Map<String, String>();

        Dom.XMLNode domAR = doc.getRootElement().getChildElement('AssumeRoleResult', namespace);
        Dom.XmlNode domCredentials = domAR.getChildElement('Credentials', namespace);

        output.put('Access_Key__c', domCredentials.getChildElement('AccessKeyId', namespace).getText());
        output.put('Secret_Access_Key__c', domCredentials.getChildElement('SecretAccessKey', namespace).getText());
        output.put('Session_Token__c', domCredentials.getChildElement('SessionToken', namespace).getText());

        return output;
    }


    /*public static HttpRequest buildAWSRequest(Map<String, String> signatureDetails)
    {
        HttpRequest output = new HttpRequest();
        output.setEndpoint(signatureDetails.get('endpoint'));
        output.setTimeout(120000);
        output.setMethod(signatureDetails.get('method'));
        
        output.setHeader('Content-Type', signatureDetails.get('content-type'));
        output.setHeader('Authorization', createAuthorisationHeader(signatureDetails));
        output.setHeader('X-Amz-Date', signatureDetails.get('amz-date'));
        output.setHeader('X-Amz-Security-Token', signatureDetails.get('SessionToken'));
        output.setHeader('X-Amz-Content-sha256', createPayloadHash(signatureDetails.get('content')));
        
        String content = signatureDetails.get('content');
        if(String.isNotBlank(content)) {
            output.setBody(content);//THIS NEEDS TO BE LOOKED IN TO
        }

        return output;
    }*/

    public static String createPayloadHash(String payload){
        return EncodingUtil.convertToHex(Crypto.generateDigest('sha-256', Blob.valueOf(payload)));
    }

    /*public static String createCanonicalRequestHash(Map<String, String> signatureDetails){
        

        String canonicalRequest = signatureDetails.get('method');
        canonicalRequest += '\n' + signatureDetails.get('requestUrl') + '\n'; //get proper name of this
        // canonicalRequest += '\ncontent-length:' + String.valueOf(Blob.valueOf(signatureDetails.get('content')).size());
        // canonicalRequest += '\ncontent-type:' + signatureDetails.get('content-type');        
        // canonicalRequest += '\ndate:' + (signatureDetails.containsKey('date') ? signatureDetails.get('date') : '');
        canonicalRequest += '\nhost:' + signatureDetails.get('hostURL'); //Resource Host URL
        canonicalRequest += '\nx-amz-content-sha256:' + signatureDetails.get('contentHash').toLowerCase();
        canonicalRequest += '\nx-amz-date:' + signatureDetails.get('amz-date');
        canonicalRequest += '\nx-amz-security-token:' + signatureDetails.get('SessionToken');
        // canonicalRequest += '\n\ncontent-length;content-type;date;host;x-amz-content-sha256;x-amz-date;x-amz-security-token';
        canonicalRequest += '\n\nhost;x-amz-content-sha256;x-amz-date;x-amz-security-token';
        canonicalRequest += '\n' + signatureDetails.get('contentHash').toLowerCase();

        System.debug('@canonicalRequest: ' + canonicalRequest);

        String canonicalRequestHash = EncodingUtil.convertToHex(Crypto.generateDigest('SHA-256', Blob.valueOf(canonicalRequest))).toLowerCase();

        System.debug('@canonicalRequestHash: ' + canonicalRequestHash);

        return canonicalRequestHash;
    }

    public static String createStringToSign(Map<String, String> signatureDetails){
        String output = 'AWS4-HMAC-SHA256\n';
        output += signatureDetails.get('amz-date') + '\n';
        output += signatureDetails.get('date') + '/' + signatureDetails.get('region') + '/' + signatureDetails.get('service') + '/aws4_request\n';
        output += createCanonicalRequestHash(signatureDetails);
        System.debug('@createStringToSign: ' + output);
        return output;
    }

    public static String createSignature(Map<String, String> signatureDetails){
        Blob signingKey = createSigningKey(signatureDetails.get('secret'), signatureDetails.get('service'), signatureDetails.get('region'));
        // String signature = EncodingUtil.convertToHex(Crypto.generateMac('hmacSHA256', Blob.valueOf(createSigningKey(signatureDetails)), signingKey));
        String signature = EncodingUtil.convertToHex(Crypto.generateMac('hmacSHA256', Blob.valueOf(createStringToSign(signatureDetails)), signingKey));
        System.debug('signature is: ' + signature.toLowerCase());

        return signature.toLowerCase();
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

    public static String createAuthorisationHeader(Map<String, String> signatureDetails){
        //Add auth credentials
        String credential_scope = signatureDetails.get('date') + '/' + signatureDetails.get('region') + '/' + signatureDetails.get('service') + '/aws4_request, ';

        //create auth header
        String authorizationHeader = 'AWS4-HMAC-SHA256 ';
        authorizationHeader += 'Credential=' + signatureDetails.get('AccessKeyId') + '/' + credential_scope;
        // authorizationHeader += 'SignedHeaders=host;content-length;content-type;date;x-amz-content-sha256;x-amz-date;x-amz-security-token, ';
        authorizationHeader += 'SignedHeaders=host;x-amz-content-sha256;x-amz-date;x-amz-security-token, ';
        authorizationHeader += 'Signature=' + createSignature(signatureDetails);

        return authorizationHeader;
    }*/
}