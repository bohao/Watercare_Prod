/**
 * @File Name          : MSN_RestResourceCompletedWorkOrder.cls
 * @Description        : API Receiver for completed WorkOrder request
 * @Author             : Bohao Chen
 * @Last Modified By   : 
 * @Last Modified On   : 
 * @Modification Log   : 
 * Ver      Date            Author                  Modification
 * 1.0      16/08/2022      Bohao Chen              Initial Version
 * 2.0      30/09/2022      Bohao Chen              
**/

@RestResource(urlMapping='/CompletedWorkOrder/*')
global without sharing class MSN_RestResourceCompletedWorkOrder {
    public static final String NO_WORKORDER = 'Couldn\'t find work order {0} in Salesforce';
    public static final String BLANK_WORKORDER_NUM = 'The work order number is blank in the request';
    public static final String UNKNOWN_ISSUE = 'unknown issue';
    public static final String BLANK_REQ_BODY = 'request body is blank';
    public static final String SUCCESS_MSG = 'request has been processed successfully';

    @HttpPost
    global static void syncWorkOrderCost() {
        
        System.RestRequest req = RestContext.request;
        System.RestResponse res = RestContext.response;

        Blob reqBody = req.requestBody;
        String respMessage = '';
        Integer respStatusCode;

        if(reqBody != null) {
            // parse json response
            MSN_CompletedPlannedMaintenanceWoReq completedWorkOrderReq = 
                MSN_CompletedPlannedMaintenanceWoReq.parse(reqBody.toString());

            // check json response
            String woNum = completedWorkOrderReq.WorkOrderNo;

            if(String.isNotBlank(woNum)) {
                    // query work order in Salesforce based on the work order number from the payload
                    List<WorkOrder> completedWorkOrders = 
                        [SELECT Transaction_ID__c, EAM_Work_Order_Status__c 
                         FROM WorkOrder 
                         WHERE Work_Order_No__c =: woNum 
                         AND Status = 'Completed'];

                    if(!completedWorkOrders.isEmpty()) {
                        for(WorkOrder wo : completedWorkOrders) {
                            wo.Transaction_ID__c = completedWorkOrderReq.TransactionID;
                            wo.EAM_Work_Order_Status__c = completedWorkOrderReq.UpdateType;
                        }

                        try {
                            update completedWorkOrders;
                            respMessage = SUCCESS_MSG;
                            respStatusCode = 200;
                        }
                        catch (Exception e) {
                            System.debug('Error: ' + e.getMessage());
                            MSN_HandleErrorsException.insertLogException(e, '', reqBody.toString());
                            respMessage = 'Salesforce error: ' + e.getMessage();
                            respStatusCode = 500;
                        }
                    }
                    else {
                        // try to search work order line items as child work orders
                        List<WorkOrderLineItem> completedWorkOrderLineItems = 
                                [SELECT EAM_Work_Order_Status__c 
                                FROM WorkOrderLineItem 
                                WHERE MSN_EAM_Work_Order_No__c =: woNum 
                                AND Status = 'Completed'];

                        if(!completedWorkOrderLineItems.isEmpty()) {
                            for(WorkOrderLineItem woli : completedWorkOrderLineItems) {
                                woli.EAM_Work_Order_Status__c = completedWorkOrderReq.UpdateType;
                            }
    
                            try {
                                update completedWorkOrderLineItems;
                                respMessage = SUCCESS_MSG;
                                respStatusCode = 200;
                            }
                            catch (Exception e) {
                                System.debug('Error: ' + e.getMessage());
                                MSN_HandleErrorsException.insertLogException(e, '', reqBody.toString());
                                respMessage = 'Salesforce error: ' + e.getMessage();
                                respStatusCode = 500;
                            }
                        }
                        else {
                            respMessage = String.format(NO_WORKORDER, new String[]{woNum});
                            respStatusCode = 400;
                        }
                    }                                        
            }
            else if(String.isBlank(woNum)) {
                respMessage = BLANK_WORKORDER_NUM;
                respStatusCode = 400;
            }
            else {
                respMessage = UNKNOWN_ISSUE;
                respStatusCode = 400;
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