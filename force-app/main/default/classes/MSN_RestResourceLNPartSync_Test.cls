/**
 * @File Name          : MSN_RestResourceLNPartSync_Test.cls
 * @Description        : Test class for MSN_RestResourceLNPartSync.cls
 * @Author             : Ashwini Patil
 * @Last Modified By   : 
 * @Last Modified On   : 
 * @Modification Log   : 
 * 1. improve testing scenario
 * 2. improve test coverage
 * 3. correct bugs
 * Ver      Date            Author                  Modification
 * 1.0      22/08/2022      Ashwini Patil           Initial Version
 * 2.0      18/01/2023      Bohao Chen           Updated version
**/

@isTest
public class MSN_RestResourceLNPartSync_Test {

  @TestSetup
    static void insertrecord(){
        //Schema.Location loc = (Schema.Location)TestDataFactory.createSObject('Schema.Location');
        Schema.Location lo = new Schema.Location(Name = 'Test', LocationType = 'Van', WarehouseID__c  = 'OF0001', IsInventoryLocation = true );  
        insert lo;       


        Product2 product = (Product2)TestDataFactory.createSObject('Product2', new Map<String,Object>{
            'MSN_LN_Material_Key__c' => '100069'
        });

        ProductItem pi = (ProductItem)TestDataFactory.createSObject('ProductItem', new Map<String,Object>{
            'LocationId' => lo.Id,
            'Product2Id ' => product.Id
        });      
    }
    
    
    static testMethod void positiveTest() {
        System.RestRequest req = new System.RestRequest(); 
        System.RestResponse res = new System.RestResponse();

        MSN_LNPayloadData payloadrequest = new MSN_LNPayloadData();
        payloadrequest.TransactionID = '7936';
        payloadrequest.ItemID = '100069';
        payloadrequest.WarehouseID = 'OF0001';
        payloadrequest.WarehouseName = 'Test';
        payloadrequest.UnitCode = 'EA';
        payloadrequest.Quantity = 9;
        payloadrequest.Success = 'true';
        
        req.requestURI = '/services/apexrest/LNPartSync/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(JSON.serializePretty(payloadrequest));
        
        RestContext.request = req;
        RestContext.response = res;
     
        Test.startTest();

        MSN_RestResourceLNPartSync.updatepartquantity();

        System.assertEquals(200, res.statusCode);
        RestResponse resp = (RestResponse)JSON.deserialize(res.responseBody.toString(), RestResponse.class);
        
        System.assertEquals(MSN_RestResourceLNPartSync.SUCCESS_MSG, resp.Description);
        System.debug('res : ' + res);
        Test.stopTest();                                                                 
    }
  
     static testMethod void negativeTest() {
        System.RestRequest req = new System.RestRequest(); 
        System.RestResponse res = new System.RestResponse();

        MSN_LNPayloadData payloadrequest = new MSN_LNPayloadData();
        payloadrequest.TransactionID = '7936';
        payloadrequest.ItemID = '100068';
        payloadrequest.WarehouseID = 'OF0001';
        payloadrequest.WarehouseName = 'Test';
        payloadrequest.UnitCode = 'EA';
        payloadrequest.Quantity = 9;
        payloadrequest.Success = 'true';
        
        req.requestURI = '/services/apexrest/LNPartSync/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(JSON.serializePretty(payloadrequest));
        
        RestContext.request = req;
        RestContext.response = res;
     
        Test.startTest();

        MSN_RestResourceLNPartSync.updatepartquantity();

        System.assertEquals(400, res.statusCode);
        RestResponse resp = (RestResponse)JSON.deserialize(res.responseBody.toString(), RestResponse.class);
        
        System.assertEquals(MSN_RestResourceLNPartSync.FAILED_MSG, resp.Description);
        System.debug('res : ' + res);
        Test.stopTest();
    } 
}