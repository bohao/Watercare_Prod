/**
 * @File Name          : AWSCallout_Test.cls
 * @Description        : Test class for AWSCallout.cls
 * @Author             : Bohao Chen
 * Ver      Date            Author                  Modification
 * 1.0      23/01/2023      Bohao Chen           initial version
**/

@isTest
public class AWSCallout_Test {
    @TestSetup
    static void testDataSetup() {
        Message_Type__c st = (Message_Type__c)TestDataFactory.createSObject('Message_Type__c', new Map<String,Object>{
            'Name' => 'Default'
        });
    }

    static testMethod void awsSuccessCalloutTest() {
        Test.setMock(HttpCalloutMock.class, new AWSWebServiceMock_Test());

        String method = '';
        String endPoint = 'https://qa.contractor.api.water.co.nz/v2/maintenance/workorder/124568/labor';        
        String payload = '{"TransactionID":"123456789","ContractorCode":"MSN","employeeCode":"145785","workOrderNumber":"87584","activityCode":"12456","tradeCode":"MMM","departmentCode":"*","typeOfHours":"N","hoursWorked":5,"dateWorked":"2023-01-17"}';
        String serviceName = 's3';

        AWSCallout.callSTSAssumeRole(method, endPoint , payload, serviceName);
    }

    // static testMethod void awsBadRequestCalloutTest() {
    //     Test.setMock(HttpCalloutMock.class, new AWSBadRequestCallout_Test());

    //     String method = '';
    //     String endPoint = 'https://qa.contractor.api.water.co.nz/v2/maintenance/workorder/124568/labor';        
    //     String payload = '{"TransactionID":"123456789","ContractorCode":"MSN","employeeCode":"145785","workOrderNumber":"87584","activityCode":"12456","tradeCode":"MMM","departmentCode":"*","typeOfHours":"N","hoursWorked":5,"dateWorked":"2023-01-17"}';
    //     String serviceName = 's3';

    //     AWSCallout.callSTSAssumeRole(method, endPoint , payload, serviceName);
    // }

    static testMethod void awsUnauthoriseRequestCalloutTest() {

        Test.setMock(HttpCalloutMock.class, new AWSUnauthorizedRequestCallout_Test());

        String method = '';
        String endPoint = 'https://qa.contractor.api.water.co.nz/v2/maintenance/workorder/124568/labor';        
        String payload = '{"TransactionID":"123456789","ContractorCode":"MSN","employeeCode":"145785","workOrderNumber":"87584","activityCode":"12456","tradeCode":"MMM","departmentCode":"*","typeOfHours":"N","hoursWorked":5,"dateWorked":"2023-01-17"}';
        String serviceName = 's3';

        AWSCallout.callSTSAssumeRole(method, endPoint , payload, serviceName);
    }
    
    static testMethod void awsRefreshSessionCalloutTest() {

        Test.setMock(HttpCalloutMock.class, new AWSSuccessAuthorizedCallout_Test());

        String method = '';
        String endPoint = 'https://qa.contractor.api.water.co.nz/v2/maintenance/workorder/124568/labor';        
        String payload = '{"TransactionID":"123456789","ContractorCode":"MSN","employeeCode":"145785","workOrderNumber":"87584","activityCode":"12456","tradeCode":"MMM","departmentCode":"*","typeOfHours":"N","hoursWorked":5,"dateWorked":"2023-01-17"}';
        String serviceName = 's3';

        Test.startTest();
        AWSCallout.refreshSession(payload, endPoint);
        Test.stopTest();
    }
}