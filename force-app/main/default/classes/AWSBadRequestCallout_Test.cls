@isTest
global class AWSBadRequestCallout_Test implements HttpCalloutMock {    
    global HttpResponse respond(HTTPRequest req){
        HttpResponse res = new HttpResponse();
        res.setStatus('Bad Request');
        res.setStatusCode(400);
        res.setBody('Something went wrong');
        return res;
    }
}