/**
 * @File Name          : MSN_RestResourceWorkOrderHelper_Test.cls
 * @Description        : Test class for MSN_RestResourceWorkOrderHelper.cls
 * @Author             : Bohao Chen
 * Ver      Date            Author                  Modification
 * 1.0      18/01/2023      Bohao Chen           initial version
**/

@isTest
public class MSN_RestResourcePlannedWOHelper_Test {

    static testMethod void payloadParsingErrorTest() {
        System.RestRequest req = new System.RestRequest(); 
        System.RestResponse res = new System.RestResponse();
        
        req.requestURI = '/services/apexrest/WorkOrder/';
        req.httpMethod = 'POST';

        String jsonStr = '{"TransactionID": "fc39f4a2-1730-4312-b814-b15f8ae34a0f","WorkOrderNo": "1234567890","ContractorCode": "MSN","OrgID": "string","Contract": "string",}';

        req.requestBody = Blob.valueOf(jsonStr);

        RestContext.request = req;
        RestContext.response= res;

        Test.startTest();
        MSN_RestResourceWorkOrder.doPost();
        Test.stopTest();

        RestResponse resp = (RestResponse)JSON.deserialize(res.responseBody.toString(), RestResponse.class);
        System.assertEquals(400, res.statusCode);
        System.assert(resp.Description.contains(MSN_RestResourceWorkOrderHelper.PAYLOAD_PARSING_ERROR.split('\\.')[0]));
    }

    static testMethod void payloadAttributeTypeConversionErrorTest() {
        System.RestRequest req = new System.RestRequest(); 
        System.RestResponse res = new System.RestResponse();
        
        req.requestURI = '/services/apexrest/WorkOrder/';
        req.httpMethod = 'POST';      

        String jsonStr = '{"TransactionID": "fc39f4a2-1730-4312-b814-b15f8ae34a0f","WorkOrderNo": "1234567890","ContractorCode": "MSN","OrgID": "string","Priority": "1", "Asset": {"AssetKey": "81201812","AssetTypeCode": "SOMETESTVALUE","AssetName": "X21A600203"}, "OnsiteDueDate": "2022-11-2012:30:00","CallDetails": {"CallDate": "2022-11-20T12:30:00"}, "RestoreServiceDueDate": "2022-11-2012:30:00Z"}';

        req.requestBody = Blob.valueOf(jsonStr);

        RestContext.request = req;
        RestContext.response= res;

        Test.startTest();
        MSN_RestResourceWorkOrder.doPost();
        Test.stopTest();

        RestResponse resp = (RestResponse)JSON.deserialize(res.responseBody.toString(), RestResponse.class);
        System.assertEquals(400, res.statusCode);
        System.assert(resp.Description.contains(MSN_RestResourceWorkOrderHelper.TYPE_CONVERSION_ERROR.split('\\.')[0]));
    }

    static testMethod void payloadOtherErrorTest() {
        System.RestRequest req = new System.RestRequest(); 
        System.RestResponse res = new System.RestResponse();
        
        req.requestURI = '/services/apexrest/WorkOrder/';
        req.httpMethod = 'POST';      

        String jsonStr = '{"TransactionID": "fc39f4a2-1730-4312-b814-b15f8ae34a0f","WorkOrderNo": "1234567890","ContractorCode": "MSN","OrgID": "string","Priority": "1", "Asset": {"AssetKey": "81201812","AssetTypeCode": "SOMETESTVALUE","AssetName": "X21A600203"}, "OnsiteDueDate": "2022-11-20T12:30:00","CallDetails": {"CallDate": "2022-11-20T12:30:00"}, "RestoreServiceDueDate": "2022-11-2012:30:00Z"}';

        req.requestBody = Blob.valueOf(jsonStr);

        RestContext.request = req;
        RestContext.response= res;

        Test.startTest();
        MSN_RestResourceWorkOrder.doPost();
        Test.stopTest();

        RestResponse resp = (RestResponse)JSON.deserialize(res.responseBody.toString(), RestResponse.class);
        System.assertEquals(500, res.statusCode);
    }

    static testMethod void createPlannedWorkOrder() {

        ServiceTerritory st = (ServiceTerritory)TestDataFactory.createSObject('ServiceTerritory', new Map<String,Object>{
            'Name' => 'METRO',
            'IsActive' => true
        });

        WorkType wt = (WorkType)TestDataFactory.createSObject('WorkType', new Map<String,Object>{
            'MSN_ActivityCode__c' => 'WMTPMR',
            'Service_Area__c' => 'Water'
        });

        System.RestRequest req = new System.RestRequest(); 
        System.RestResponse res = new System.RestResponse();

        MSN_PlannedMaintenanceWrapper.Address address = new MSN_PlannedMaintenanceWrapper.Address();
        address.FlatNo = '';
        address.StreetNo = '123"';
        address.StreetName = 'Verran Road"';
        address.Suburb = 'Birkdale"';
        address.Postcode = '0626';
        address.City = '';
        address.Country = '';
        
        
        MSN_PlannedMaintenanceWrapper.ContactDetails contactDetails = new MSN_PlannedMaintenanceWrapper.ContactDetails();
        contactDetails.Address = address;
        
        MSN_PlannedMaintenanceWrapper.Asset asset = new MSN_PlannedMaintenanceWrapper.Asset();
        asset.AssetKey = '81201812';
        asset.AssetName = 'SOMETESTVALUE';
        asset.AssetTypeCode = 'X21A600203';

        MSN_PlannedMaintenanceWrapper.RequestorInfo requestInfo = new MSN_PlannedMaintenanceWrapper.RequestorInfo();
        requestInfo.ContactDetails = contactDetails;


        MSN_PlannedMaintenanceWrapper.CallDetails callDetails = new MSN_PlannedMaintenanceWrapper.CallDetails();
        callDetails.RequestorInfo = requestInfo;

        MSN_PlannedMaintenanceWrapper plannedWoPayload = new MSN_PlannedMaintenanceWrapper();
        plannedWoPayload.TransactionID = '0800052712';
        plannedWoPayload.WorkOrderNo = '11111131';
        // plannedWoPayload.ContractorCode = 'MSN';
        plannedWoPayload.CallDetails = callDetails;
        plannedWoPayload.Asset = asset;
        plannedWoPayload.Location = '';
        plannedWoPayload.Priority = '1';
        plannedWoPayload.ContractorArea = 'METRO';
        plannedWoPayload.ServiceArea = 'Water';
        plannedWoPayload.Comments = 'Replace the water meters as instructed';
        // plannedWoPayload.Assignee = 'MSN';
        plannedWoPayload.ActivityCode = 'WMTPMR';
        plannedWoPayload.ActivityDescription = 'PLANNED WATER METER REPLACEMENT';
        // plannedWoPayload.MaintenanceType = 'PPM';
        // plannedWoPayload.WorkOrderType = 'GroupScheduledMaintenance';
        plannedWoPayload.GroupNo = 'MSN EAM  SFS WMTPMR1';
        // plannedWoPayload.Crew = 'MSN';
        plannedWoPayload.InitiatedDate = '2022-10-15T00:00:00.000+13:00';
        plannedWoPayload.InitiatedBy = '033A75A7-0D7E-401B-9063-24D1D9E7DCB6';
        plannedWoPayload.ScheduledDate = '2019-10-22T12:30:00';
        plannedWoPayload.OnsiteDueDate = '2019-11-22T12:30:00';
        plannedWoPayload.VariationNo = 'ul';
        plannedWoPayload.ActivityInstructions = 'u';

        req.requestBody = Blob.valueOf(JSON.serializePretty(plannedWoPayload));
        req.requestURI = '/services/apexrest/WorkOrder/';
        req.httpMethod = 'POST';      

        RestContext.request = req;
        RestContext.response= res;

        Test.startTest();
        MSN_RestResourceWorkOrder.doPost();
        Test.stopTest();

        RestResponse resp = (RestResponse)JSON.deserialize(res.responseBody.toString(), RestResponse.class);
        System.assertEquals(200, res.statusCode);
    }

}