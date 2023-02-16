/**
 * @File Name          : MSN_RestResourceLNPartSync.cls
 * @Description        : API Receiver for parts update from LN
 * @Author             : Ashwini Patil
 * @Group              : 
 * @Created Date	   : 22nd August 2022
 * @Last Modified By   : 
 * @Last Modified On   : 
 * @Modification Log   : 
 * Ver      Date            Author                  Modification
 * 1.0                          Initial Version
**/

@RestResource(urlMapping='/LNPartSync/*')
global with sharing class MSN_RestResourceLNPartSync {
   		public static final String SUCCESS_MSG = 'Request has been processed successfully';
        public static final String FAILED_MSG = 'Request has been unsuccessful, no ItemID or WarehouseID found';

    @HttpPost
    global static void updatepartquantity() {
        
        System.RestRequest req = RestContext.request;
        System.RestResponse res = RestContext.response;

        Blob reqBody = req.requestBody;
        String respMessage = '';
        Integer respStatusCode;

        if(reqBody != null) {
            // parse json response
            MSN_LNPayloadData updatepartquantity = MSN_LNPayloadData.parse(reqBody.toString());

            // check json response
            String WarehouseID = updatepartquantity.WarehouseID;
            String ItemID = updatepartquantity.ItemID;
            Double Quantity = updatepartquantity.Quantity;

            // query Warehouse ID and ItemID in Salesforce based on the WarehouseID and ItemID from the payload
            List<ProductItem> getlocationrecords;
            try {
                getlocationrecords = 
                    [SELECT Id, QuantityOnHand, EAM_Quantity__c FROM ProductItem  
                        WHERE Product2.MSN_LN_Material_Key__c =: ItemID 
                        AND Location.WarehouseID__c =: WarehouseID];
                
                if(!getlocationrecords.isEmpty()) {
                    getlocationrecords[0].QuantityOnHand = Quantity;
                    getlocationrecords[0].EAM_Quantity__c = Quantity;
                    update getlocationrecords;
                    respMessage = SUCCESS_MSG;
                    respStatusCode = 200;
                }
                else {
                    respMessage = FAILED_MSG;
                    respStatusCode = 400;
                }    
            }
            catch(DmlException e) {
            System.debug('An unexpected error has occurred: ' + e.getMessage());
            }                                                                 
        }

        RestResponse resp = new RestResponse();        
        resp.Success = respStatusCode == 200 ? 'true' : 'false';
        resp.Description = respMessage;

        res.statusCode = respStatusCode;        
        res.responseBody = Blob.valueOf(JSON.serialize(resp));
        res.addHeader('Content-Type', 'application/json');
    }
}