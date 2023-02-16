@isTest
global class AWSSuccessAuthorizedCallout_Test implements HttpCalloutMock {    
    global HttpResponse respond(HTTPRequest req){
        HttpResponse res = new HttpResponse();
        res.setStatus('OK');
        res.setStatusCode(200);        

        String expectedResponseBody = '<AssumeRoleResponse xmlns="https://sts.amazonaws.com/doc/2011-06-15/"><AssumeRoleResult><AssumedRoleUser><AssumedRoleId>AROA5LLLFMND6CIA74BOA:testSesh</AssumedRoleId><Arn>arn:aws:sts::917737136967:assumed-role/msn_access_role/testSesh</Arn></AssumedRoleUser><Credentials><AccessKeyId>ASIA5LLLFMNDRURCHM6R</AccessKeyId><SecretAccessKey>IpRvpiaIWav/RAUNQCfBVmfrn9TEWkobuQNtth9v</SecretAccessKey><SessionToken>IQoJb3JpZ2luX2VjECwaDmFwLXNvdXRoZWFzdC0yIkYwRAIgNKl22HWwRHBQhkCbinUCFn/BNxLX624SuPoKQQnzCYICIFTKEK/LnXtZXHMA6ESHhmxeZoC4DlQDxwrqpx00Ug9kKp4CCJX//////////wEQAhoMOTE3NzM3MTM2OTY3IgwhR64++koQnimVbYMq8gHrnwZaAZttJCpM7sljfAnhwRhAfrm94HnLiDLmhLKAkzweSv9qNntq1OXD6b+S6OAgAq1AEbk1LhxO6lLU6dh292oxlSmY44ZtuncKUZN3T51mI4xcexoyaucoii0Gwysat88nbu5WyvoL9MQSk9Vh+kU1smWAB1o8HJM5jcttK5Lb603gCE5e0AgGm3vzgmRjv57ifBrhuf30DRNWobirea74Ng+D2cR+x811PUoBpH+PMT9D9CFmU1/vuPNci9AFQiQK3vFhOO1U1dCDZm+Hk46VBg63F4i0mAgyRgwF5scRh8U9PgVZwi2Oo+Zcad1MXTDs2aueBjqeAdGSCqYRFZMDMCFwBu1EVUgYRTeSxBBJPn1g29m+kFSaU61tdHm8SrzwmEMS0+JeRmsHVUjbXmoqrwxJFjPmbMa8n0bqDYNRPs+DpiktDMG3pVhpS6vd1Chf3kk2L/pNYSOtUDun/Ubp/IKxoh+U/5jlczegPENlaPIXi4DkmP8l/iU/ywTkXkhqXbGrGYwXF4qn3mx+xn5jvMWfhO63</SessionToken><Expiration>2023-01-20T20:35:08Z</Expiration></Credentials></AssumeRoleResult><ResponseMetadata><RequestId>476ce314-4947-4b35-a882-f0f3e43648da</RequestId></ResponseMetadata></AssumeRoleResponse>';

//         Dom.Document doc = new Dom.Document();
//   doc.load(expectedResult);
//   Dom.XMLNode root = doc.getRootElement();	 
//   xObjectID = walkthrough(root, 'ObjectID').trim();

        res.setBody(expectedResponseBody);
        return res;
    }
}