/**
 * @File Name          : MSN_RestResourceChildWorkOrderTest.cls
 * @Description        : Test class for MSN_RestResourceChildWorkOrder.cls
 * @Author             : Bohao Chen
 * @Last Modified By   : 
 * @Last Modified On   : 
 * @Modification Log   : 
 * Ver      Date            Author                  Modification
 * 1.0      31/01/2022      Bohao Chen              Initial Version
**/
@IsTest
public class MSN_RestResourceChildWorkOrder_Test {
    
    @TestSetup
    static void makeData(){

        ServiceTerritory st = (ServiceTerritory)TestDataFactory.createSObject('ServiceTerritory', new Map<String,Object>{
            'IsActive' => true
        });

        WorkType wt = (WorkType)TestDataFactory.createSObject('WorkType');

        // create a sample completed planned work order 
        Id msnWorkOrderRtId = Schema.SObjectType.WorkOrder.getRecordTypeInfosByName().get('MSN').getRecordTypeId();


        WorkOrder wo = (WorkOrder)TestDataFactory.createSObject('WorkOrder', new Map<String,Object>{
            'ServiceTerritoryId' =>  st.Id,
            'WorkTypeId' => wt.Id,
            'Status' => 'New',
            'recordTypeId' => msnWorkOrderRtId,
            'Work_Order_No__c' => '12345'
        });

        WorkOrder cwo = (WorkOrder)TestDataFactory.createSObject('WorkOrder', new Map<String,Object>{
            'ParentWorkOrderId' => wo.Id,
            'ServiceTerritoryId' =>  st.Id,
            'WorkTypeId' => wt.Id,
            'Status' => 'New',
            'recordTypeId' => msnWorkOrderRtId,
            'Street' => '44 Meadowbank Road', 
            'PostalCode' => '1072', 
            'Country' => 'New Zealand', 
            'City' => 'Auckland', 
            'Priority' => '7'
        });

        WorkOrderLineItem woli = (WorkOrderLineItem)TestDataFactory.createSObject('WorkOrderLineItem', new Map<String,Object>{
            'Status' => 'Completed',
            'MSN_EAM_Work_Order_No__c' => '54321'
        });
    }

    @IsTest
    static void childWorkOrderRequestTest(){
        // query work order
        WorkOrder cwo = [SELECT Id, WorkOrderNumber, Work_Order_No__c, MSN_Contract__c, EndDate FROM WorkOrder WHERE ParentWorkOrderId != null];

        System.RestRequest req = new System.RestRequest(); 
        System.RestResponse res = new System.RestResponse();

        MSN_ChildWorkOrderWrapper childWoReqWrapper = new MSN_ChildWorkOrderWrapper();
        childWoReqWrapper.TransactionID = '1234567890876';
        childWoReqWrapper.WorkOrderNo = '2222';
        childWoReqWrapper.ContractorReference = cwo.WorkOrderNumber;
        
        req.requestURI = '/services/apexrest/ChildWorkOrder/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(JSON.serializePretty(childWoReqWrapper));
        
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        MSN_RestResourceChildWorkOrder.doPost();
        system.debug('res : ' + res);

        Test.stopTest();

        System.assertEquals(200, res.statusCode);
        RestResponse resp = (RestResponse)JSON.deserialize(res.responseBody.toString(), RestResponse.class);
        System.assertEquals(MSN_RestResourceChildWorkOrder.SUCCESS_MSG, resp.Description);

        cwo = [SELECT Id, WorkOrderNumber, Work_Order_No__c, MSN_Contract__c, EndDate FROM WorkOrder WHERE Id =: cwo.Id];
        System.assertEquals('2222', cwo.Work_Order_No__c);
    }

    @IsTest
    static void childWorkOrderLineItemRequestTest(){
        // query work order
        WorkOrderLineItem cwoli = [SELECT Id, MSN_Work_Line_Number__c, MSN_EAM_Work_Order_No__c FROM WorkOrderLineItem LIMIT 1];

        System.RestRequest req = new System.RestRequest(); 
        System.RestResponse res = new System.RestResponse();

        MSN_ChildWorkOrderWrapper childWoReqWrapper = new MSN_ChildWorkOrderWrapper();
        childWoReqWrapper.TransactionID = '1234567890876';
        childWoReqWrapper.WorkOrderNo = '2222';
        childWoReqWrapper.ContractorReference = cwoli.MSN_Work_Line_Number__c;
        
        req.requestURI = '/services/apexrest/ChildWorkOrder/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(JSON.serializePretty(childWoReqWrapper));
        
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        MSN_RestResourceChildWorkOrder.doPost();
        system.debug('res : ' + res);

        Test.stopTest();

        System.assertEquals(200, res.statusCode);
        RestResponse resp = (RestResponse)JSON.deserialize(res.responseBody.toString(), RestResponse.class);
        System.assertEquals(MSN_RestResourceChildWorkOrder.SUCCESS_MSG, resp.Description);

        cwoli = [SELECT Id, MSN_Work_Line_Number__c, MSN_EAM_Work_Order_No__c FROM WorkOrderLineItem WHERE Id =: cwoli.Id];
        System.assertEquals('2222', cwoli.MSN_EAM_Work_Order_No__c);
    }

    /*@IsTest
    static void testCompletedWorkOrderLineItemRequest(){
        // query work order line item
        WorkOrderLineItem woli = [SELECT Id, MSN_EAM_Work_Order_No__c FROM WorkOrderLineItem WHERE Status = 'Completed'];
        // WHERE Work_Order_No__c =: woNum 
        // AND Status = 'Completed']
        System.RestRequest req = new System.RestRequest(); 
        System.RestResponse res = new System.RestResponse();

        MSN_ChildWorkOrderWrapper completedPmWoReqWrapper = new MSN_ChildWorkOrderWrapper();
        completedPmWoReqWrapper.TransactionID = '1234567890876';
        completedPmWoReqWrapper.WorkOrderNo = woli.MSN_EAM_Work_Order_No__c;
        completedPmWoReqWrapper.ContractorReference = 'FECO';
        
        req.requestURI = '/services/apexrest/ChildWorkOrder/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(JSON.serializePretty(completedPmWoReqWrapper));
        
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        MSN_RestResourceChildWorkOrder.syncWorkOrderCost();
        system.debug('res : ' + res);

        Test.stopTest();

        System.assertEquals(200, res.statusCode);
        RestResponse resp = (RestResponse)JSON.deserialize(res.responseBody.toString(), RestResponse.class);
        System.assertEquals(MSN_RestResourceChildWorkOrder.SUCCESS_MSG, resp.Description);
    }
    */

    @IsTest
    static void testInvalidWorkOrderNumberRequest(){

        System.RestRequest req = new System.RestRequest(); 
        System.RestResponse res = new System.RestResponse();

        MSN_ChildWorkOrderWrapper childWoReqWrapper = new MSN_ChildWorkOrderWrapper();
        childWoReqWrapper.TransactionID = '1234567890876';
        childWoReqWrapper.WorkOrderNo = '2222';
        childWoReqWrapper.ContractorReference = '8888';
        
        req.requestURI = '/services/apexrest/ChildWorkOrder/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(JSON.serializePretty(childWoReqWrapper));
        
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        MSN_RestResourceChildWorkOrder.doPost();
        system.debug('res : ' + res);

        Test.stopTest();

        System.assertEquals(500, res.statusCode);
        RestResponse resp = (RestResponse)JSON.deserialize(res.responseBody.toString(), RestResponse.class);
        System.assertEquals(MSN_RestResourceChildWorkOrder.INVALID_CWO_NUM, resp.Description);
    }

    @IsTest
    static void testNoWorkOrderNumberRequest(){

        System.RestRequest req = new System.RestRequest(); 
        System.RestResponse res = new System.RestResponse();

        MSN_ChildWorkOrderWrapper childWoReqWrapper = new MSN_ChildWorkOrderWrapper();
        childWoReqWrapper.TransactionID = '1234567890876';
        childWoReqWrapper.WorkOrderNo = '2222';
        childWoReqWrapper.ContractorReference = 'WO-123456';
        
        req.requestURI = '/services/apexrest/ChildWorkOrder/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(JSON.serializePretty(childWoReqWrapper));
        
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        MSN_RestResourceChildWorkOrder.doPost();
        system.debug('res : ' + res);

        Test.stopTest();

        System.assertEquals(500, res.statusCode);
        RestResponse resp = (RestResponse)JSON.deserialize(res.responseBody.toString(), RestResponse.class);
        System.assert(resp.Description.contains('Couldn\'t find child work order'));
    }

    @IsTest
    static void testBlankRequest(){
            
        System.RestRequest req = new System.RestRequest(); 
        System.RestResponse res = new System.RestResponse();

        MSN_ChildWorkOrderWrapper childWoReqWrapper = new MSN_ChildWorkOrderWrapper();
        childWoReqWrapper.TransactionID = '1234567890876';
        childWoReqWrapper.WorkOrderNo = '2222';
        childWoReqWrapper.ContractorReference = 'WO-123456';
        
        req.requestURI = '/services/apexrest/ChildWorkOrder/';
        req.httpMethod = 'POST';
        // req.requestBody = Blob.valueOf('');
        
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        MSN_RestResourceChildWorkOrder.doPost();
        system.debug('res : ' + res);

        Test.stopTest();

        System.assertEquals(400, res.statusCode);
        RestResponse resp = (RestResponse)JSON.deserialize(res.responseBody.toString(), RestResponse.class);
        System.assertEquals(MSN_RestResourceChildWorkOrder.BLANK_REQ_BODY, resp.Description);
    }

    /*@IsTest
    static void testNoWorkOrderFound(){
            
        System.RestRequest req = new System.RestRequest(); 
        System.RestResponse res = new System.RestResponse();

        MSN_ChildWorkOrderWrapper completedPmWoReqWrapper = new MSN_ChildWorkOrderWrapper();
        completedPmWoReqWrapper.TransactionID = '1234567890876';
        completedPmWoReqWrapper.WorkOrderNo = 'aaaaa';
        completedPmWoReqWrapper.ContractorReference = 'FECO';

        req.requestURI = '/services/apexrest/ChildWorkOrder/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(JSON.serializePretty(completedPmWoReqWrapper));
        
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        MSN_RestResourceChildWorkOrder.syncWorkOrderCost();
        system.debug('res : ' + res);

        Test.stopTest();

        System.assertEquals(400, res.statusCode);
        RestResponse resp = (RestResponse)JSON.deserialize(res.responseBody.toString(), RestResponse.class);
        System.assertEquals(MSN_RestResourceChildWorkOrder.INVALID_CWO_NUM, resp.Description);
    }*/
}