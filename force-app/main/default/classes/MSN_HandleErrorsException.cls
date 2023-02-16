/**
 * @File Name          : MSN_HandleErrorsException.cls
 * @Description        : Error log utility to update the error log when errors occur
 * @Author             : David Azzi
 * @Group              : 
 * @Last Modified By   : David Azzi
 * @Last Modified On   : 01/03/2022
 * @Modification Log   : 
 * Ver      Date            Author                  Modification
 * 1.0      01/03/2022      David Azzi              Initial Version
**/
public with sharing class MSN_HandleErrorsException extends Exception {
    // public static void LogException(Exception e, String recordId, String payload){
    //     insertLogException(e, recordId, payload); 
    // } 
    
    // Log Exception in CustomException object. 
    // relatedToId : Case/object for which this error in logged.
    public static void insertLogException(Exception e, String recordId, String payload){
        try{
            String stackTrace = e.getStackTraceString().substringBefore('\n');
            String className = stackTrace.substringAfter('.').substringBefore('.');	
            String methodName = stackTrace.substringBefore(':').substringAfter(className).substringAfter('.');
                
            //Governer Limit of executingQuery 
            String QueryLimit = 'QueryLimit: SOQL Queries used / SOQL Queries allowed: ' + Limits.getQueries() + '/' + Limits.getLimitQueries();
            String DMLimit = 'DMLimit: Number of records queried so far /  Number allowed: ' + Limits.getDmlRows() + '/' + Limits.getLimitDmlRows();
            String DMLStat = 'DMLStat: Number of DML statements used so far / Number allowed: ' +  Limits.getDmlStatements() + '/' + Limits.getLimitDmlStatements();   
            String CPUT = 'CPUT: Amount of CPU time (in ms) used so far / CPU usage time (in ms) allowed: ' + Limits.getCpuTime() + '/' + Limits.getLimitCpuTime();

            Error_Log__c err = new Error_Log__c();
            err.MSN_Source_Record_ID__c = recordId;
            err.MSN_Govt_Limit_in_Executing_Code__c = String.format('{0}\n{1}\n{2}\n{3}', new List<string>{QueryLimit, DMLimit, DMLStat, CPUT});
            err.MSN_Error_Message__c = e.getMessage();
            err.MSN_Exception_Type__c = e.getTypeName();
            err.MSN_Line_Number__c = e.getLineNumber();
            err.MSN_StackTrace__c = e.getStackTraceString();
            err.MSN_MethodName__c = methodName;
            err.MSN_ClassName__c = className;
            err.MSN_Payload__c = payload;
            err.MSN_Process_type__c = 'Automated';
            if(UserInfo.getFirstName().equalsIgnoreCase('Integration')) {
                err.Message_Type__c = getIntegrationErrorMessageTypeId();
            }

            Database.insert(err);            
        } finally{

        }
    }

    public static void insertCustomErrorLog(String errorMessage, String recordId, String methodName, String payload){
        try{
            Error_Log__c err = new Error_Log__c();
            err.MSN_Source_Record_ID__c = recordId;
            err.MSN_Error_Message__c = errorMessage;
            err.MSN_Payload__c = payload;
            err.MSN_MethodName__c = methodName;
            err.MSN_Process_type__c = 'Custom';
            if(UserInfo.getFirstName().equalsIgnoreCase('Integration')) {
                err.Message_Type__c = getIntegrationErrorMessageTypeId();
            }
            Database.insert(err);            
        } catch(Exception e){
            insertLogException(e, recordId, payload);
        }
    }

    public static void insertSaveResultErrors(String payload, String action, String className, String methodName, 
                                            Integer lineNumber, Map<Id, List<Database.Error>> recordIdDbErrors) {  

        List<Error_Log__c> errorLogs = new List<Error_Log__c>();
        for(Id recordId : recordIdDbErrors.keySet() ){
            for ( Database.Error dbError : recordIdDbErrors.get(recordId) ){
                Error_Log__c err = new Error_Log__c();
                //err.Name = String.valueOf(dbError.getStatusCode());
                err.MSN_Exception_Type__c = action;
                err.MSN_Error_Message__c =  dbError.getMessage() + '\nFields: ' + dbError.getFields();
                err.MSN_Payload__c = payload;
                err.MSN_ClassName__c = className;
                err.MSN_MethodName__c = methodName;
                err.MSN_Line_Number__c = lineNumber;
                err.MSN_Source_Record_ID__c = recordId;
                err.MSN_Process_type__c = 'Automated';
                if(UserInfo.getFirstName().equalsIgnoreCase('Integration')) {
                    err.Message_Type__c = getIntegrationErrorMessageTypeId();
                }
                //err.MSN_StackTrace__c = String.valueOf( dbError );    
                errorLogs.add(err);
            }
        }
        
        try {
            Database.insert(errorLogs);
            System.debug('MSN_ErrorLogUtility.logSaveResultErrors: ' + errorLogs);
        } catch(Exception e) {
            insertLogException(e, '', payload); 
        }
    }

    /*public static void insertErrorLogAll(
            String className, String errMessage, String exceptionType,
            String govLimit, Integer lineNumber, String methodName,
            String payload, String processType, String recordId, String stackTrace){
        
        Error_Log__c newError = new Error_Log__c();
        newError.MSN_ClassName__c = className;
        newError.MSN_MethodName__c = methodName;
        newError.MSN_Error_Message__c = errMessage;
        newError.MSN_Exception_Type__c = exceptionType;
        newError.MSN_Govt_Limit_in_Executing_Code__c = govLimit;
        newError.MSN_Line_Number__c = lineNumber;
        newError.MSN_Payload__c = payload;
        newError.MSN_Process_type__c = processType;
        newError.MSN_Source_Record_ID__c = recordId;
        newError.MSN_StackTrace__c = stackTrace;
        if(UserInfo.getFirstName().equalsIgnoreCase('Integration')) {
            newError.Message_Type__c = getIntegrationErrorMessageTypeId();
        }
        try { 
            Database.insert(newError);
        } catch ( Exception e){
            insertLogException(e, recordId, payload);
        }

    }*/
    
    // Created by sahil for log integration logs
    public static void insertIntegrationException (String payload, String endpoint,HTTPResponse resp){
		
		String type;
        String recordId = endpoint.substringAfterLast('/');

        // remove work order number
        String endpointComp = endpoint.replaceAll('\\/[0-9]+\\/', '/');

        /*if(!recordId.isNumeric()) {
            recordId = endpoint.remove(recordId+'/').substringAfterLast('/');
            endpointComp = endpoint.remove(recordId+'/');
        }
        else {
            endpointComp = endpoint.remove(recordId);
        }*/
        
        System.debug('@sahil endpointComp :'+endpointComp);
            
		List<Error_Log_Endpoint_Mapping__mdt> logMappingList = Error_Log_Endpoint_Mapping__mdt.getAll().values();
        
        for(Error_Log_Endpoint_Mapping__mdt mapping:logMappingList) {
            if(mapping.Endpoint__c == endpointComp) {
                type = mapping.Message_Type__c;
            }
        }
			
		// Get the message type
		List<Message_Type__c> msgTypeList = [SELECT Id,Name FROM Message_Type__c WHERE Name = :type or Name = 'Default'];
        
        Message_Type__c msgType, defaultMsg;

        for(Message_Type__c msgType2 : msgTypeList) {
            if(type == msgType2.Name) {
                msgType = msgType2;
            }
            if(msgType2.Name == 'Default'){
                defaultMsg = msgType2;
            }
        }
        if(msgType == NULL) {
            msgType = defaultMsg;
        }
        
        Error_Log__c err = new Error_Log__c();
        err.MSN_Source_Record_ID__c = recordId;
        err.MSN_Error_Message__c = resp.getBody();
        err.MSN_Exception_Type__c = 'Integration Error';
        err.MSN_StackTrace__c = String.valueOf(resp.getStatusCode());
        err.MSN_MethodName__c = 'callSTSAssumeRole';
        err.MSN_ClassName__c = 'AWSCallout';
        err.MSN_Payload__c = payload;
        err.MSN_Process_type__c = 'Automated';
		err.Message_Type__c = msgType.Id;
        insert err;
	}

    private static Id getIntegrationErrorMessageTypeId() {
        Id getIntegrationErrorMessageTypeId;

        List<Message_Type__c> messageTypes = [SELECT Id FROM Message_Type__c WHERE Name = 'Integration Error'];

        if(!messageTypes.isEmpty()) {
            getIntegrationErrorMessageTypeId = messageTypes[0].Id;
        }

        return getIntegrationErrorMessageTypeId;
    }
}