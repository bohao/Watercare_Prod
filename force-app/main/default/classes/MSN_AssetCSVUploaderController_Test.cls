/**
 * @File Name          : MSN_AssetCSVUploaderController_Test.cls
 * @Description        : Test class for MSN_AssetCSVUploaderController.cls
 * @Author             : Bohao Chen
 * Ver      Date            Author                  Modification
 * 1.0      30/01/2023      Bohao Chen           initial version
**/
@isTest
public class MSN_AssetCSVUploaderController_Test {

    static testMethod void upsertFileTest() {

        contact objContact =  new Contact(lastName='test contact');
        insert objContact ;

        String testString = 'Asset Type,Business Area Code\nWater "Meter,Device",WNC';
        Blob testBlob = Blob.valueof(testString);        

        Attachment objAttachment=new Attachment(); 
        objAttachment.Body= testBlob;
        objAttachment.Name = 'test Attachment';
        objAttachment.ParentId = objContact.Id;
        insert objAttachment;

        System.debug(testBlob.toString());

        String JSONblob = JSON.serialize(testString);

        System.debug(JSONblob);

        // String base64Data = EncodingUtil.base64Encode(testBlob);

        // System.debug(base64Data);

        List<Map<String, String>> preMappedData = new List<Map<String, String>>();

        Map<String, String> bulkData1 = new Map<String, String>();
        bulkData1.put('label', 'Asset Type');
        bulkData1.put('fieldName', 'Asset_Type__c');
        preMappedData.add(bulkData1);

        Map<String, String> bulkData2 = new Map<String, String>();
        bulkData2.put('label', 'Business Area Code');
        bulkData2.put('fieldName', 'Business_Area_Code__c');
        preMappedData.add(bulkData2);

        // Map<String, String> bulkData3 = new Map<String, String>();
        // bulkData3.put('label', 'Asset SF Name');
        // bulkData3.put('fieldName', 'Name');
        // preMappedData.add(bulkData3);

        // Map<String, String> bulkData4 = new Map<String, String>();
        // bulkData4.put('label', 'Asset Type to Product');
        // bulkData4.put('fieldName', 'Product2Id');
        // preMappedData.add(bulkData4);

        MSN_AssetCSVUploaderController.upsertFile(JSONblob, preMappedData);

    }

    static testMethod void getAssetMappingFromCustomMetadataTest() {
        MSN_AssetCSVUploaderController.getAssetMappingFromCustomMetadata();
    }

}