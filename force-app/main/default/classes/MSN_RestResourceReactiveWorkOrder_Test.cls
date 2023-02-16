/**
 * @File Name          : MSN_RestResourceReactiveWorkOrder_Test.cls
 * @Description        : Test class for MSN_RestResourceReactiveWorkOrder.cls
 * @Author             : Bohao Chen
 * Ver      Date            Author                  Modification
 * 1.0      18/01/2023      Bohao Chen           initial version
**/

@isTest
public class MSN_RestResourceReactiveWorkOrder_Test {

    static testMethod void payloadParsingErrorTest() {
        System.RestRequest req = new System.RestRequest(); 
        System.RestResponse res = new System.RestResponse();
        
        req.requestURI = '/services/apexrest/ReactiveWorkOrder/';
        req.httpMethod = 'POST';

        String jsonStr = '{"TransactionID": "fc39f4a2-1730-4312-b814-b15f8ae34a0f","WorkOrderNo": "1234567890","ContractorCode": "MSN","OrgID": "string","Contract": "string",}';

        req.requestBody = Blob.valueOf(jsonStr);

        RestContext.request = req;
        RestContext.response= res;

        Test.startTest();
        MSN_RestResourceReactiveWorkOrder.doPost();
        Test.stopTest();

        RestResponse resp = (RestResponse)JSON.deserialize(res.responseBody.toString(), RestResponse.class);
        System.assertEquals(400, res.statusCode);
        System.assert(resp.Description.contains(MSN_RestResourceWorkOrderHelper.PAYLOAD_PARSING_ERROR.split('\\.')[0]));
    }

    static testMethod void payloadOtherErrorTest() {
        System.RestRequest req = new System.RestRequest(); 
        System.RestResponse res = new System.RestResponse();
        
        req.requestURI = '/services/apexrest/ReactiveWorkOrder/';
        req.httpMethod = 'POST';

        String jsonStr = '{}';

        req.requestBody = Blob.valueOf(jsonStr);

        RestContext.request = req;
        RestContext.response= res;

        Test.startTest();
        MSN_RestResourceReactiveWorkOrder.doPost();
        Test.stopTest();
        
        System.assertEquals(500, res.statusCode);        
    }


    static testMethod void payloadAttributeTypeConversionErrorTest() {
        System.RestRequest req = new System.RestRequest(); 
        System.RestResponse res = new System.RestResponse();
        
        req.requestURI = '/services/apexrest/ReactiveWorkOrder/';
        req.httpMethod = 'POST';      

        String jsonStr = '{"TransactionID": "fc39f4a2-1730-4312-b814-b15f8ae34a0f","WorkOrderNo": "1234567890","ContractorCode": "MSN","OrgID": "string","Priority": "1", "Asset": {"AssetKey": "81201812","AssetTypeCode": "SOMETESTVALUE","AssetName": "X21A600203"}, "OnsiteDueDate": "2022-11-20T12:30:00","CallDetails": {"CallDate": "2022-11-20T12:30:00"}, "RestoreServiceDueDate": "2022-11-2012:30:00Z"}';

        req.requestBody = Blob.valueOf(jsonStr);

        RestContext.request = req;
        RestContext.response= res;

        Test.startTest();
        MSN_RestResourceReactiveWorkOrder.doPost();
        Test.stopTest();

        RestResponse resp = (RestResponse)JSON.deserialize(res.responseBody.toString(), RestResponse.class);
        System.assertEquals(400, res.statusCode);
        System.assert(resp.Description.contains(MSN_RestResourceWorkOrderHelper.TYPE_CONVERSION_ERROR.split('\\.')[0]));
    }

    static testMethod void payloadSuccessTest() {

        ServiceTerritory st = (ServiceTerritory)TestDataFactory.createSObject('ServiceTerritory', new Map<String,Object>{
            'Name' => 'Metro',
            'IsActive' => true
        });

        WorkType wt = (WorkType)TestDataFactory.createSObject('WorkType', new Map<String,Object>{
            'MSN_Problem_Code__c' => 'FRGD',
            'Service_Area__c' => 'Wastewater'
        });

        System.RestRequest req = new System.RestRequest(); 
        System.RestResponse res = new System.RestResponse();

        MSN_ReactiveMaintenanceWrapper.IndividualName individualName = new MSN_ReactiveMaintenanceWrapper.IndividualName();
        individualName.Title = 'string';
        individualName.FirstName = 'FirstName';
        individualName.MiddleName = 'string';
        individualName.LastName = 'LastNam';
        
        MSN_ReactiveMaintenanceWrapper.ContactDetails contactDetails = new MSN_ReactiveMaintenanceWrapper.ContactDetails();
        contactDetails.PhoneNo = '0485789554';
        contactDetails.PhoneNoAlternative = 'string';
        contactDetails.Email = 's@test.co';

        MSN_ReactiveMaintenanceWrapper.cls_GPSCoordinates gPSCoordinates = new MSN_ReactiveMaintenanceWrapper.cls_GPSCoordinates();
        gPSCoordinates.Northing = 'string';
        gPSCoordinates.Easting = 'string';

        MSN_ReactiveMaintenanceWrapper.Address address = new MSN_ReactiveMaintenanceWrapper.Address();
        address.FlatNo = 'string';
        address.StreetNo = '123';
        address.StreetName = 'Verran Road';
        address.Suburb = 'Birkdale';
        address.Postcode = '0626';
        address.City = 'string';
        address.Country = 'string';
        address.GPSCoordinates = gPSCoordinates;

        MSN_ReactiveMaintenanceWrapper.RequestorInfo requestorInfo = new MSN_ReactiveMaintenanceWrapper.RequestorInfo();
        requestorInfo.IndividualName = individualName;
        requestorInfo.ContactDetails = contactDetails;
        requestorInfo.Address = address;

        MSN_ReactiveMaintenanceWrapper.CallDetails callDetails = new MSN_ReactiveMaintenanceWrapper.CallDetails();
        callDetails.CallDate = '2022-11-16T12:30:00';
        callDetails.CallTakenBy = 'CallTakenB';
        callDetails.RequestorInfo = requestorInfo;

        MSN_ReactiveMaintenanceWrapper.Asset asset = new MSN_ReactiveMaintenanceWrapper.Asset();
        asset.AssetKey = '81201812';
        asset.AssetTypeCode = 'SOMETESTVALUE';
        asset.AssetName = 'X21A60020';

        MSN_ReactiveMaintenanceWrapper payloadrequest = new MSN_ReactiveMaintenanceWrapper();
        payloadrequest.TransactionID = 'fc39f4a2-1730-4312-b814-b15f8ae34a0f';
        payloadrequest.WorkOrderNo = '1234567890';
        payloadrequest.ContractorCode = 'MSN';
        payloadrequest.OrgID = 'string';
        payloadrequest.Contract = 'string';
        payloadrequest.CallDetails = callDetails;
        payloadrequest.Address = address;
        payloadrequest.Location = 'Location';
        payloadrequest.ContractorArea = 'Metro';
        payloadrequest.ServiceArea = 'Wastewater';
        payloadrequest.ProblemCode = 'FRGD';
        payloadrequest.ProblemDescription = 'something something';
        payloadrequest.Priority = 1;
        payloadrequest.Comments = 'string';
        payloadrequest.RestoreServiceDueDate = '2022-11-20T12:30:00';
        payloadrequest.OnsiteDueDate = '2022-11-20T12:30:00';
        payloadrequest.CompletionDueDate = '2022-11-20T12:30:00';
        payloadrequest.ContactRequestor = 'true';
        payloadrequest.Asset = asset;

        req.requestBody = Blob.valueOf(JSON.serializePretty(payloadrequest));
        req.requestURI = '/services/apexrest/ReactiveWorkOrder/';
        req.httpMethod = 'POST';      

        RestContext.request = req;
        RestContext.response= res;

        Test.startTest();
        MSN_RestResourceReactiveWorkOrder.doPost();
        Test.stopTest();

        RestResponse resp = (RestResponse)JSON.deserialize(res.responseBody.toString(), RestResponse.class);
        System.assertEquals(200, res.statusCode);
    }


    static testMethod void reactiveWorkOrderUpdateFailTest() {

        System.RestRequest req = new System.RestRequest(); 
        System.RestResponse res = new System.RestResponse();

        MSN_UpdateReactiveMaintenanceWrapper payloadrequest = new MSN_UpdateReactiveMaintenanceWrapper();
        payloadrequest.TransactionID = '123';
        payloadrequest.WorkOrderNo = '123457890';
        payloadrequest.ContractorCode =  'MSN';
        payloadrequest.UpdateType =  'COMMTW';
        payloadrequest.UpdateDate =  '2019-04-17T12:30:00';
        payloadrequest.Comments =  'WATERCARE: Hi, the fault that you reported on 52 Mokoia RD on SR15322623 has been repaired. Please allow 15-21 days for reinstatement work to be complete';

        req.requestBody = Blob.valueOf(JSON.serializePretty(payloadrequest));
        req.requestURI = '/services/apexrest/ReactiveWorkOrder/';
        req.httpMethod = 'PATCH';      

        RestContext.request = req;
        RestContext.response= res;

        Test.startTest();
        MSN_RestResourceReactiveWorkOrder.doPatch();
        Test.stopTest();

        RestResponse resp = (RestResponse)JSON.deserialize(res.responseBody.toString(), RestResponse.class);
        System.assertEquals(400, res.statusCode);
        System.assert(resp.Description.contains('Couldn\'t find the work order \'123457890\''));
    }

    static testMethod void reactiveWorkOrderUpdateSuccessTest() {

        WorkOrder wo = (WorkOrder)TestDataFactory.createSObject('WorkOrder', new Map<String,Object>{
            'Work_Order_No__c' => '123457890'
        });

        System.RestRequest req = new System.RestRequest(); 
        System.RestResponse res = new System.RestResponse();

        MSN_UpdateReactiveMaintenanceWrapper payloadrequest = new MSN_UpdateReactiveMaintenanceWrapper();
        payloadrequest.TransactionID = '123';
        payloadrequest.WorkOrderNo = '123457890';
        payloadrequest.ContractorCode =  'MSN';
        payloadrequest.UpdateType =  'COMMTW';
        payloadrequest.UpdateDate =  '2019-04-17T12:30:00';
        payloadrequest.Comments =  'WATERCARE: Hi, the fault that you reported on 52 Mokoia RD on SR15322623 has been repaired. Please allow 15-21 days for reinstatement work to be complete';

        req.requestBody = Blob.valueOf(JSON.serializePretty(payloadrequest));
        req.requestURI = '/services/apexrest/ReactiveWorkOrder/';
        req.httpMethod = 'PATCH';      

        RestContext.request = req;
        RestContext.response= res;

        Test.startTest();
        MSN_RestResourceReactiveWorkOrder.doPatch();
        Test.stopTest();

        RestResponse resp = (RestResponse)JSON.deserialize(res.responseBody.toString(), RestResponse.class);
        System.assertEquals(200, res.statusCode);
        Id workOrderId = [SELECT Id FROM WorkOrder WHERE Work_Order_No__c = '123457890' LIMIT 1].Id;
        List<MSN_JobNotes__c> jobNotes = [SELECT Id FROM MSN_JobNotes__c WHERE MSN_Work_Order__c =: workOrderId];
        System.assert(!jobNotes.isEmpty());
    }
}