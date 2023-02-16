/**
 * @File Name          : MSN_TeamsIntegration_Test.cls
 * @Description        : Test class for MSN_TeamsIntegration.cls
 * @Author             : Bohao Chen
 * Ver      Date            Author                  Modification
 * 1.0      07/02/2023      Bohao Chen           initial version
**/

@isTest
public class MSN_TeamsIntegration_Test {
    
    @TestSetup
    static void testDataSetup() {

    }

    @isTest
    public static void queueableJobTest() {  
        Error_Log__c err = (Error_Log__c)TestDataFactory.createSObject('Error_Log__c');
        MSN_TeamsIntegration teams = new MSN_TeamsIntegration(err, 'http://test.test.com');
        System.enqueueJob(teams);  

    }

    @isTest
    public static void callMsTeamTest() {
        Test.setMock(HttpCalloutMock.class, new AWSWebServiceMock_Test());
        String message = 'ms team test message';
        String title = 'ms team test tile';
        String link = Url.getOrgDomainUrl().toExternalForm();
        String payload = '{{some payload}}';
        String endpoint = 'https://abc.com';
        MSN_TeamsIntegration.callTeams(message, title, link, payload, endpoint);
    }
}