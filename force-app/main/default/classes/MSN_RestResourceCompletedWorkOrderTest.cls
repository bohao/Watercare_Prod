/**
 * @File Name          : MSN_RestResourceCompletedWorkOrderTest.cls
 * @Description        : Test class for MSN_RestResourceCompletedWorkOrder.cls
 * @Author             : Bohao Chen
 * @Last Modified By   : 
 * @Last Modified On   : 
 * @Modification Log   : 
 * Ver      Date            Author                  Modification
 * 1.0      17/08/2022      Bohao Chen                    Initial Version
**/
@IsTest
public class MSN_RestResourceCompletedWorkOrderTest {

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
            'Status' => 'Completed',
            'recordTypeId' => msnWorkOrderRtId,
            'Work_Order_No__c' => '12345'
        });

        WorkOrderLineItem woli = (WorkOrderLineItem)TestDataFactory.createSObject('WorkOrderLineItem', new Map<String,Object>{
            'Status' => 'Completed',
            'MSN_EAM_Work_Order_No__c' => '54321'
        });


    }

    @IsTest
    static void testCompletedWorkOrderRequest(){
        // query work order
        WorkOrder wo = [SELECT Id, Work_Order_No__c, MSN_Contract__c, EndDate FROM WorkOrder WHERE Status = 'Completed'];
        // WHERE Work_Order_No__c =: woNum 
        // AND Status = 'Completed']
        System.RestRequest req = new System.RestRequest(); 
        System.RestResponse res = new System.RestResponse();

        MSN_CompletedPlannedMaintenanceWoReq completedPmWoReqWrapper = new MSN_CompletedPlannedMaintenanceWoReq();
        completedPmWoReqWrapper.TransactionID = '1234567890876';
        completedPmWoReqWrapper.WorkOrderNo = wo.Work_Order_No__c;
        completedPmWoReqWrapper.UpdateType = 'FECO';
        
        req.requestURI = '/services/apexrest/CompletedWorkOrder/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(JSON.serializePretty(completedPmWoReqWrapper));
        
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        MSN_RestResourceCompletedWorkOrder.syncWorkOrderCost();
        system.debug('res : ' + res);

        Test.stopTest();

        System.assertEquals(200, res.statusCode);
        RestResponse resp = (RestResponse)JSON.deserialize(res.responseBody.toString(), RestResponse.class);
        System.assertEquals(MSN_RestResourceCompletedWorkOrder.SUCCESS_MSG, resp.Description);
    }

    @IsTest
    static void testCompletedWorkOrderLineItemRequest(){
        // query work order line item
        WorkOrderLineItem woli = [SELECT Id, MSN_EAM_Work_Order_No__c FROM WorkOrderLineItem WHERE Status = 'Completed'];
        // WHERE Work_Order_No__c =: woNum 
        // AND Status = 'Completed']
        System.RestRequest req = new System.RestRequest(); 
        System.RestResponse res = new System.RestResponse();

        MSN_CompletedPlannedMaintenanceWoReq completedPmWoReqWrapper = new MSN_CompletedPlannedMaintenanceWoReq();
        completedPmWoReqWrapper.TransactionID = '1234567890876';
        completedPmWoReqWrapper.WorkOrderNo = woli.MSN_EAM_Work_Order_No__c;
        completedPmWoReqWrapper.UpdateType = 'FECO';
        
        req.requestURI = '/services/apexrest/CompletedWorkOrder/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(JSON.serializePretty(completedPmWoReqWrapper));
        
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        MSN_RestResourceCompletedWorkOrder.syncWorkOrderCost();
        system.debug('res : ' + res);

        Test.stopTest();

        System.assertEquals(200, res.statusCode);
        RestResponse resp = (RestResponse)JSON.deserialize(res.responseBody.toString(), RestResponse.class);
        System.assertEquals(MSN_RestResourceCompletedWorkOrder.SUCCESS_MSG, resp.Description);
    }
    @IsTest
    static void testRequestHasNoWorkOrderNumber(){
            
        System.RestRequest req = new System.RestRequest(); 
        System.RestResponse res = new System.RestResponse();

        MSN_CompletedPlannedMaintenanceWoReq completedPmWoReqWrapper = new MSN_CompletedPlannedMaintenanceWoReq();
        completedPmWoReqWrapper.TransactionID = '1234567890876';
        completedPmWoReqWrapper.WorkOrderNo = '';
        completedPmWoReqWrapper.UpdateType = 'FECO';
        
        req.requestURI = '/services/apexrest/CompletedWorkOrder/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(JSON.serializePretty(completedPmWoReqWrapper));
        
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        MSN_RestResourceCompletedWorkOrder.syncWorkOrderCost();
        system.debug('res : ' + res);

        Test.stopTest();

        System.assertEquals(400, res.statusCode);
        RestResponse resp = (RestResponse)JSON.deserialize(res.responseBody.toString(), RestResponse.class);
        System.assertEquals(MSN_RestResourceCompletedWorkOrder.BLANK_WORKORDER_NUM, resp.Description);
    }

    @IsTest
    static void testBlankRequest(){
            
        System.RestRequest req = new System.RestRequest(); 
        System.RestResponse res = new System.RestResponse();

        MSN_CompletedPlannedMaintenanceWoReq completedPmWoReqWrapper = new MSN_CompletedPlannedMaintenanceWoReq();
        
        req.requestURI = '/services/apexrest/CompletedWorkOrder/';
        req.httpMethod = 'POST';
        
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        MSN_RestResourceCompletedWorkOrder.syncWorkOrderCost();
        system.debug('res : ' + res);

        Test.stopTest();

        System.assertEquals(400, res.statusCode);
        RestResponse resp = (RestResponse)JSON.deserialize(res.responseBody.toString(), RestResponse.class);
        System.assertEquals(MSN_RestResourceCompletedWorkOrder.BLANK_REQ_BODY, resp.Description);
    }

    @IsTest
    static void testNoWorkOrderFound(){
            
        System.RestRequest req = new System.RestRequest(); 
        System.RestResponse res = new System.RestResponse();

        MSN_CompletedPlannedMaintenanceWoReq completedPmWoReqWrapper = new MSN_CompletedPlannedMaintenanceWoReq();
        completedPmWoReqWrapper.TransactionID = '1234567890876';
        completedPmWoReqWrapper.WorkOrderNo = 'aaaaa';
        completedPmWoReqWrapper.UpdateType = 'FECO';

        req.requestURI = '/services/apexrest/CompletedWorkOrder/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(JSON.serializePretty(completedPmWoReqWrapper));
        
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        MSN_RestResourceCompletedWorkOrder.syncWorkOrderCost();
        system.debug('res : ' + res);

        Test.stopTest();

        System.assertEquals(400, res.statusCode);
        RestResponse resp = (RestResponse)JSON.deserialize(res.responseBody.toString(), RestResponse.class);
        System.assertEquals(String.format(MSN_RestResourceCompletedWorkOrder.NO_WORKORDER, new String[]{'aaaaa'}), resp.Description);
    }
}