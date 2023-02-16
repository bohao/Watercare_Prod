@isTest
global class AWSUnauthorizedRequestCallout_Test implements HttpCalloutMock {    
    global HttpResponse respond(HTTPRequest req){
        HttpResponse res = new HttpResponse();
        res.setStatus('Forbidden');
        res.setStatusCode(403);
        res.setBody('{"message":"The security token included in the request is invalid"}');
        return res;
    }
}