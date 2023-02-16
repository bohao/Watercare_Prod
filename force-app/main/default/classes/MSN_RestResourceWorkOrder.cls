/**
 * @File Name          : MSN_RestResourceWorkOrder.cls
 * @Description        : API Receiver for WorkOrder commands
 * @Author             : David Azzi
 * @Group              : 
 * @Last Modified By   : David Azzi
 * @Last Modified On   : 23/11/2021
 * @Modification Log   : 
 * Ver      Date            Author                  Modification
 * 1.0      23/11/2021      David Azzi              Initial Version
 * 2.0      21/09/2022      Bohao Chen              better error handling/message
**/

@RestResource(urlMapping='/WorkOrder/*')
global with sharing class MSN_RestResourceWorkOrder {

    /*@HttpDelete
    global static void doDelete() {
        RestRequest req = RestContext.request;
        System.RestResponse res = RestContext.response;
        String accountId = req.requestURI.substring(req.requestURI.lastIndexOf('/')+1);
        Account account = [SELECT Id FROM Account WHERE Id = :accountId];
        delete account;
    }
    
    @HttpGet
    global static WorkOrder doGet() {
        System.RestRequest req = RestContext.request;
        System.RestResponse res = RestContext.response;
        String woId = req.requestURI.substring(req.requestURI.lastIndexOf('/')+1);
        
        return [SELECT Id FROM WorkOrder WHERE Id =: woId];
    }*/

    @HttpPost
    global static void doPost(){

        System.RestRequest req = RestContext.request;
        System.RestResponse res = RestContext.response;
        
        Blob body = req.requestBody;
        String jsonStr = body.toString();

        RestResponse resp = new RestResponse();   
        try {
            List<Id> woIds = MSN_RestResourceWorkOrderHelper.createWorkOrder(jsonStr, 'Planned Maintenance');
            resp.Success = 'true';
            resp.Description = String.format('Salesforce work order {0} has been created/updated successfully', woIds);
            res.statusCode = 200;
        }
        catch(Exception e) {
            resp.Success = 'false';

            system.debug('exception type: ' + e.getTypeName());
            String exceptionType = e.getTypeName();
            String errorMsg;
            Integer errorCode;
            if(exceptionType.equalsIgnoreCase('System.JSONException')) {
                errorMsg = String.format(MSN_RestResourceWorkOrderHelper.PAYLOAD_PARSING_ERROR, new String[]{e.getMessage()});
                errorCode = 400;
            }
            else if(exceptionType.equalsIgnoreCase('System.TypeException')) {
                errorMsg = String.format(MSN_RestResourceWorkOrderHelper.TYPE_CONVERSION_ERROR, new String[]{e.getMessage()});
                errorCode = 400;
            }            
            else if(exceptionType.equalsIgnoreCase('MSN_Utility.CustomException')) {
                errorMsg = e.getMessage();
                errorCode = 500;
            }
            else {
                errorMsg = e.getMessage();
                errorCode = 500;
            }

            resp.Description = errorMsg;            
            res.statusCode = errorCode;
            MSN_HandleErrorsException.insertLogException(e, '', jsonStr);
        }
        
        res.responseBody = Blob.valueOf(JSON.serialize(resp));
        res.addHeader('Content-Type', 'application/json');
    }

}