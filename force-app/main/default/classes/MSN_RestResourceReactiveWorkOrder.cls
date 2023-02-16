/**
 * @File Name          : MSN_RestResourceReactiveWorkOrder.cls
 * @Description        : REST endpoint for creating a reactive work order
 * @Author             : Bohao Chen
 * @Group              : 
 * @Last Modified By   : Bohao Chen
 * @Last Modified On   : 21/09/2022
 * @Modification Log   : 
 * Ver      Date            Author                  Modification
 * 1.0      21/09/2022      Bohao Chen              Initial Version
**/
@RestResource(urlMapping='/ReactiveWorkOrder/*')
global without sharing class MSN_RestResourceReactiveWorkOrder {

    @HttpPost
    global static void doPost(){

        System.RestRequest req = RestContext.request;
        System.RestResponse res = RestContext.response;
        
        Blob body = req.requestBody;
        String jsonStr = body.toString();

        RestResponse resp = new RestResponse();   
        try {
            System.debug('@jsonStr: ' + jsonStr);
            
            List<Id> woIds = MSN_RestResourceWorkOrderHelper.createWorkOrder(jsonStr, 'Reactive Maintenance');
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

    @HttpPatch
    global static void doPatch(){
        System.RestRequest req = RestContext.request;
        System.RestResponse res = RestContext.response;
        
        Blob body = req.requestBody;
        String jsonStr = body.toString();

        String errorMessage;
        MSN_JobNotes__c jobNote;
        try { 
            jobNote = MSN_JobNoteUtility.createJobNote(jsonStr);
        }
        catch ( Exception e){
            MSN_HandleErrorsException.insertLogException(e, '', '');
            errorMessage = e.getMessage();
        }

        RestResponse resp = new RestResponse();

        if(String.isBlank(errorMessage)) {
            res.statusCode = 200;
            resp.Success = 'true';
            resp.Description = 'Job Note \'' + jobNote.Id + '\' has been created successfully in Salesforce.';
        }
        else {
            res.statusCode = 400;
            resp.Success = 'false';
            resp.Description = errorMessage;
        }
        
        res.responseBody = Blob.valueOf(JSON.serialize(resp));
        res.addHeader('Content-Type', 'application/json');
    }
}