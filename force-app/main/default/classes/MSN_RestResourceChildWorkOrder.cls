/**
 * @File Name          : MSN_RestResourceChildWorkOrder.cls
 * @Description        : API Receiver for child work order
 * @Author             : Bohao Chen
 * @Group              : 
 * @Modification Log   : 
 * Ver      Date            Author                  Modification
 * 1.0      06/12/2022      Bohao Chen              Initial Version
**/

@RestResource(urlMapping='/ChildWorkOrder/*')
global without sharing class MSN_RestResourceChildWorkOrder {
    
    public static final String NO_WORKORDER = 'Couldn\'t find child work order {0} in Salesforce';
    public static final String BLANK_SF_WORKORDER_NUM = 'The EAM work order number is blank in the request';
    public static final String BLANK_EAM_WORKORDER_NUM = 'The Salesforce work order number is blank in the request';
    public static final String INVALID_CWO_NUM = 'ContractorReference has invalid Salesforce Child Work Order Number. It should start with \'WO-\' or \'WL-\'';

    public static final String UNKNOWN_ISSUE = 'unknown issue';
    public static final String BLANK_REQ_BODY = 'request body is blank';
    public static final String SUCCESS_MSG = 'request has been processed successfully';
    
    
    @HttpPost
    global static void doPost(){
        System.RestRequest req = RestContext.request;
        System.RestResponse res = RestContext.response;

        Blob reqBody = req.requestBody;
        String respMessage = '';
        Integer respStatusCode;

        if(reqBody != null) {
            MSN_ChildWorkOrderWrapper childWorkOrder = MSN_ChildWorkOrderWrapper.parse(reqBody.toString());

            String childWorkOrderNum = childWorkOrder.ContractorReference; // this is SF work order number (WO-000001) or SF work order line item number (WL-000001)
            String eamChildWorkOrderNum = childWorkOrder.WorkOrderNo; // this is EAM work order number

            if(String.isBlank(childWorkOrderNum)) {
                respMessage = BLANK_SF_WORKORDER_NUM;
                respStatusCode = 500;
            }
            else if(String.isBlank(eamChildWorkOrderNum)) {
                respMessage = BLANK_EAM_WORKORDER_NUM;
                respStatusCode = 500;
            }
            else {
                
                // depends on the prefix of SF child work order number, either query WOLI (if prefix is WL) or WO (if prefix is WO)
                List<String> childWorkOrderNumParts = childWorkOrderNum.split('-');

                try {
                    if(childWorkOrderNumParts[0].equalsIgnoreCase('WO')) {
                        WorkOrder wo = [SELECT Id 
                                        FROM WorkOrder 
                                        WHERE WorkOrderNumber = :childWorkOrderNum 
                                        LIMIT 1];
                        
                        wo.Work_Order_No__c = eamChildWorkOrderNum;
                        update wo;

                        respMessage = SUCCESS_MSG;
                        respStatusCode = 200;
                    }
                    else if(childWorkOrderNumParts[0].equalsIgnoreCase('WL')) {
                        WorkOrderLineItem woli = [SELECT Id 
                                                  FROM WorkOrderLineItem 
                                                  WHERE MSN_Work_Line_Number__c =: childWorkOrderNum 
                                                  LIMIT 1];
                                   
                        woli.MSN_EAM_Work_Order_No__c = eamChildWorkOrderNum;
                        update woli;

                        respMessage = SUCCESS_MSG;
                        respStatusCode = 200;
                    }
                    else {
                        respStatusCode = 500;
                        respMessage = INVALID_CWO_NUM;
                    }
                }
                catch (QueryException e) {
                    respStatusCode = 500;
                    if(e.getMessage().contains('no rows for assignment')) {
                        respMessage = String.format(NO_WORKORDER, new String[]{childWorkOrderNum});
                    }
                    else {
                        respMessage = e.getMessage();
                    }
                }
                catch (Exception e) {
                    respStatusCode = 500;
                    respMessage = e.getMessage();
                }
            }
        }
        else {
            respMessage = BLANK_REQ_BODY;
            respStatusCode = 400;
        }

        RestResponse resp = new RestResponse();        
        resp.Success = respStatusCode == 200 ? 'true' : 'false';
        resp.Description = respMessage;

        res.statusCode = respStatusCode;        
        res.responseBody = Blob.valueOf(JSON.serialize(resp));
        res.addHeader('Content-Type', 'application/json');
    }
}