/**
 * @File Name          : MSN_IntegrationUtility.cls
 * @Description        : Utility class for Dynamic Integration
 * @Author             : David Azzi
 * @Group              : 
 * @Last Modified By   : David Azzi
 * @Last Modified On   : 15/02/2022
 * @Modification Log   : 
 * Ver      Date            Author                  Modification
 * 1.0      15/02/2022      David Azzi              Initial Version
**/
public with sharing class MSN_IntegrationUtility {

    //Start the queuable so that this does not affect any current salesforce limitations
    public static List<Outbound_Integration__e> generateOutboundIntegrationEvents(Map<Id, sObject> recordMap, String objectName, Map<String, List<String>> endpointAndPayloadsApiNameMap){
        
        List<Outbound_Integration__e> platformEvents = new List<Outbound_Integration__e>();
        
        if ( MSN_Integration.integrationQueued == false){

            // have to loop through Integration_Endpoint__mdt and lower case the key for later key lookup
            // Map<String, Integration_Endpoint__mdt> integrationEndpointMap = Integration_Endpoint__mdt.getAll();
            Map<String, String> integrationEndpointMap = new Map<String, String>();
            
            for(Integration_Endpoint__mdt ie : [SELECT DeveloperName, Endpoint__c FROM Integration_Endpoint__mdt]) {
                integrationEndpointMap.put(ie.DeveloperName.toLowerCase(), ie.Endpoint__c);
            }

            // Integration_Payloads__mdt.getAll(); salesforce bug.
            Map<String, Integration_Payloads__mdt> payloadSettingMap = new Map<String, Integration_Payloads__mdt>();
            
            for(Integration_Payloads__mdt ip : [SELECT DeveloperName, Payload__c, Request_Method__c FROM Integration_Payloads__mdt]) { 
                payloadSettingMap.put(ip.DeveloperName, ip);
            }

            List<Integration_Endpoint_Placeholder_Lookup__mdt> integrationEndpointPlaceholderLookups = Integration_Endpoint_Placeholder_Lookup__mdt.getAll().values();

            String instanceName = EnvironmentHelper.getSandboxName();

            for(String endpointName : endpointAndPayloadsApiNameMap.keySet()) {

                System.debug('   ' + endpointName);

                // find endpoint placeholder to field API name lookups for each endpoint
                Map<String, String> endPointPlaceholderNameAndFieldName = new Map<String, String>();

                for(Integration_Endpoint_Placeholder_Lookup__mdt iepl : integrationEndpointPlaceholderLookups) {
                    if(iepl.Endpoint_Name__c == endpointName && iepl.Object_Api_Name__c == objectName) {
                        endPointPlaceholderNameAndFieldName.put(iepl.Placeholder_Name__c, iepl.Field_Api_Name__c);
                    }
                }
                
                System.debug('@endPointPlaceholderNameAndFieldName: ' + endPointPlaceholderNameAndFieldName);

                // generate an endpoint API Name with instance/environment name suffix
                // String endpointApiName = instanceName.equalsIgnoreCase('Production') ? endpointName : endpointName + '_' + instanceName.capitalize();
                String endpointApiName = instanceName.equalsIgnoreCase('Production') ? endpointName : endpointName + '_' + instanceName;
                endpointApiName = endpointApiName.toLowerCase();

                System.debug('@endpointApiName: ' + endpointApiName);
                System.debug('@integrationEndpointMap: ' + integrationEndpointMap);

                if(integrationEndpointMap.containsKey(endpointApiName)) {

                    // find endpoint with placeholders
                    String endpoint = integrationEndpointMap.get(endpointApiName);
                    System.debug('@endpoint: ' + endpoint);

                    // generate outbound integration platform event for each payload per record
                    for(String payloadApiName : endpointAndPayloadsApiNameMap.get(endpointName)) {                    
                        platformEvents.addAll(doGenerateOutboundIntegrationEvents(recordMap, objectName, payloadApiName, 
                                                                                endpoint, payloadSettingMap, 
                                                                                endPointPlaceholderNameAndFieldName));
                    }
                }
            }
            
            // publish platform events
            /*if(!platformEvents.isEmpty()) {
                Id jobId = System.enqueueJob(new MSN_Integration(platformEvents));
                MSN_Integration.integrationQueued = true;
            }*/
        }
        return platformEvents;
    }
    
    public static String replaceAllInPayload(String startValue, String replaceValue, String payload){
        System.debug('@startValue: ' + startValue);
        System.debug('@replaceValue: ' + replaceValue);
        System.debug('@payload: ' + payload);
        // replaceValue = String.isBlank(replaceValue) ? '' : replaceValue;
        return payload.replaceAll('(\\{\\{' + startValue + '\\}\\})', replaceValue);
    }

    // BOHAO CHEN @IBM
    // This method is to generate "outbound integration event" with payload, endpoint and request method by replacing placeholders in payloads
    // and endpoint. 
    // NOTE: this method CANNOT handle child records in the payload as placeholder. 
    // Currently all payloads contain normal fields and lookup fields ONLY.
    private static List<Outbound_Integration__e> doGenerateOutboundIntegrationEvents(Map<Id, sObject> recordsMap, 
                                                            String objectApiName, String payloadApiName, String endpointWithPlaceholder, 
                                                            Map<String, Integration_Payloads__mdt> payloadSettingMap, 
                                                            Map<String, String> endPointPlaceholderNameAndFieldName){
        
        List<Outbound_Integration__e> platformEvents = new List<Outbound_Integration__e>();

        // find a payload setting from custom metadata type
        Integration_Payloads__mdt payloadSetting = payloadSettingMap.get(payloadApiName);

        if(payloadSetting != null && String.isNotBlank(payloadSetting.Payload__c)) {

            String payloadWithFieldApiName = payloadSetting.Payload__c;

            System.debug('@payloadWithFieldApiName: ' + payloadWithFieldApiName);

            // extract all field placeholders in the payload
            Set<String> fieldApiNames = MSN_Utility.getFieldPlaceholders(payloadWithFieldApiName, '\\{\\{[^}]*\\}\\}', '{{', '}}');

            // in addition, add field API names found in endpoints
            // at this stage, we have all field API names needed for querying their values
            fieldApiNames.addAll(endPointPlaceholderNameAndFieldName.values());

            System.debug('@fieldApiNames: ' + fieldApiNames);

            // get all triggered record ids
            List<Id> recordIds = new List<Id>();

            // TODO: need to further filter record id based on trigger context and payload custom metadata setting
            // for example, update record id for update payload but not for insert payload
            recordIds.addAll(recordsMap.keySet());

            if(!recordIds.isEmpty()) {

                // execute a query to find values of all field Api Names for all triggering records
                List<sObject> queryResults = generateQuery(objectApiName, recordIds, fieldApiNames);

                // generate field-value map collection for all triggering records
                Map<Id, Map<String, String>> fieldValueMapByRecordId = getFieldValuesMapById(queryResults, fieldApiNames);                

                // replace place holders with field API names for endpoints
                System.debug('@endpointWithPlaceholder: ' + endpointWithPlaceholder);
                String endpointWithFieldName = swapPlaceholderWithFieldName(endpointWithPlaceholder, endPointPlaceholderNameAndFieldName);                
                System.debug('@endpointWithFieldName: ' + endpointWithFieldName);

                for(String recordId : recordIds) {

                    String payloadWithFieldApiNameCopy = payloadWithFieldApiName;
                    if(fieldValueMapByRecordId.containsKey(recordId)) {
                        Map<String, String> fieldValueMap = fieldValueMapByRecordId.get(recordId);                        

                        for(String fieldApiName : fieldApiNames) {
                            if(fieldValueMap.containsKey(fieldApiName)) {
                                payloadWithFieldApiNameCopy = replaceAllInPayload(fieldApiName, fieldValueMap.get(fieldApiName), payloadWithFieldApiNameCopy);
                                endpointWithFieldName = endpointWithFieldName.replaceAll('\\{' + fieldApiName + '\\}', fieldValueMap.get(fieldApiName));
                            }
                        }

                        // at this stage, payload and endpoint should have been replaced field name placeholders with field values
                        String payloadWithFieldValue = payloadWithFieldApiNameCopy;
                        String endpointWithFieldValue = endpointWithFieldName;

                        System.debug('@payload: ' + payloadWithFieldValue);
                        System.debug('@endpoint: ' + endpointWithFieldValue);

                        Outbound_Integration__e platformEvent = new Outbound_Integration__e();
                        platformEvent.EndPoint__c = endpointWithFieldValue;
                        platformEvent.Method__c = payloadSetting.Request_Method__c;
                        platformEvent.Payload__c = payloadWithFieldValue;
                        platformEvents.add(platformEvent);
                    }
                }
                System.debug('@platformEvents: ' + platformEvents);                
            }
        }
        else {
            // TODO: log error for payload setting couldn't be found or payload is blank
        }
        return platformEvents;
    }    

    private static List<sObject> generateQuery(String objectApiName, List<Id> recordIds, Set<String> fieldPlaceholders) {
        List<sObject> queryResults;

        String q = 'SELECT ';
        Map<String, Set<String>> parentObjectFieldsMap = new Map<String, Set<String>>();
        // NOTE: we only care about lookup fields now. The following variable is just a placeholder for now
        Map<String, Set<String>> childObjectFieldsMap = new Map<String, Set<String>>();
        Set<String> fields = new Set<String>();
        
        for(String fieldPlaceholder : fieldPlaceholders) {
            if(fieldPlaceholder.contains('.')) {
                String parentRelationshipName = fieldPlaceholder.substringBefore('.').toLowerCase();
                if(!parentObjectFieldsMap.containsKey(parentRelationshipName)) {
                    parentObjectFieldsMap.put(parentRelationshipName, new Set<String>());
                }
                parentObjectFieldsMap.get(parentRelationshipName).add(fieldPlaceholder.substringAfter('.'));
            }
            else {
                fields.add(fieldPlaceholder);
            }
        }

        SObjectType sObjType = ((SObject)Type.forName(objectApiName).newInstance()).getSObjectType();
        System.debug('@sObjType: ' + sObjType);

        Schema.DescribeSObjectResult objectDesc = sObjType.getDescribe();

        for(Schema.SobjectField field : objectDesc.fields.getMap().Values()){            
            // search for lookup fields
            // doing this is to make sure whatever appear as a lookup field is actually a valid lookup field to avoid any typo in the payload settings
            if(field.getDescribe().getType() == Schema.DisplayType.REFERENCE){

                String lookupFieldName = field.getDescribe().getRelationshipName().toLowerCase();

                System.debug('==parent object=' + field.getDescribe().getRelationshipName());

                if(parentObjectFieldsMap.containsKey(lookupFieldName)) {
                    for(String parentField : parentObjectFieldsMap.get(lookupFieldName)) {
                        fields.add(lookupFieldName + '.' + parentField);
                    }
                }
            }
        }

        System.debug('@fields: ' + fields);

        if(!fields.isEmpty()) {
            q = String.format('SELECT {0} FROM ' + objectAPIName + ' WHERE Id IN: recordIds ALL ROWS', new List<String>{String.join(new List<String>(fields), ', ')});
            queryResults = Database.query(q);
        }

        System.debug('@query: ' + q);

        return queryResults;
    }

    private static Map<Id, Map<String, String>> getFieldValuesMapById(List<sObject> queryResults, Set<String> fieldPlaceholders) {
        // query the record again in case there are relationship fields
        Map<Id, Map<String, String>> fieldValueMapByRecordId = new Map<Id, Map<String, String>>();

        for(sObject result : queryResults){
            Map<String, String> fieldValueMap = new Map<String, String>();
            for(String fieldPlaceholder : fieldPlaceholders) {
                String value = MSN_Utility.getValue(result, fieldPlaceholder);
                System.debug('@value: ' + value);
                if(String.isBlank(value)) {
                    fieldValueMap.put(fieldPlaceholder, '');
                }
                else {
                    value = value.replaceAll('\r\n', ' ');
                    value = value.replaceAll('\n', ' ');
                    System.debug('@value after replace: ' + value);
                    fieldValueMap.put(fieldPlaceholder, value);
                }
            }

            System.debug('fieldValueMap: ' + fieldValueMap);
            fieldValueMapByRecordId.put(result.Id, fieldValueMap);
        }

        System.debug('@fieldValueMapByRecordId: ' + fieldValueMapByRecordId);

        return fieldValueMapByRecordId;
    }

    private static String swapPlaceholderWithFieldName(String stringWithPlaceholder, Map<String, String> placeholderAndFieldNameMap) {
        // List<String> placeholders = MSN_Utility.getAllFieldNames(stringWithPlaceholder, '\\{[^}]*\\}', '{', '}');

        Set<String> placeholders = MSN_Utility.getFieldPlaceholders(stringWithPlaceholder, '\\{[^}]*\\}', '{', '}');

        System.debug('@placeholders: ' + placeholders);

        System.debug('@stringWithPlaceholder: ' + stringWithPlaceholder);

        stringWithPlaceholder = stringWithPlaceholder.toLowerCase();
        for(String placeholder : placeholders) {        
            placeholder = placeholder.toLowerCase();            
            stringWithPlaceholder = stringWithPlaceholder.replaceAll('\\{' + placeholder + '\\}', '{' + placeholderAndFieldNameMap.get(placeholder) + '}');
        }

        String stringWithFieldNames = stringWithPlaceholder;
        System.debug('@stringWithFieldNames: ' + stringWithFieldNames);
        return stringWithFieldNames;
    }

    /**
	* Author : Sahil Wadhwa
	* Date : 07/06/2022
	* Description : Create the payload for work order costs
	**/
    public static string createCostPayload(List<WorkStep> costList, SObject record) {

        String workOrderNo = '';
        String contract = '';
        String endDate = '';

        String objectType = record.getSObjectType().getDescribe().getName(); 

        System.debug('@objectType: ' + objectType);

        if(objectType.equalsIgnoreCase('WorkOrder')) {
            WorkOrder workOrder = (WorkOrder)record;
            workOrderNo = workOrder.Work_Order_No__c;
            contract = workOrder.MSN_Contract__c;
            if(workOrder.EndDate != null) {
                endDate = workOrder.EndDate.format('yyyy-MM-dd\'T\'HH:mm:ss.sss',Userinfo.getTimeZone().toString());
            }
        }
        else if(objectType.equalsIgnoreCase('WorkOrderLineItem')) {
            WorkOrderLineItem workOrderLineItem = (WorkOrderLineItem)record;
            workOrderNo = workOrderLineItem.MSN_EAM_Work_Order_No__c;
            contract = workOrderLineItem.MSN_Contract__c;
            if(workOrderLineItem.EndDate != null) {
                endDate = workOrderLineItem.EndDate.format('yyyy-MM-dd\'T\'HH:mm:ss.sss',Userinfo.getTimeZone().toString());
            }
        }

        System.debug('@workOrderNo: ' + workOrderNo);
        System.debug('@contract: ' + contract);
        System.debug('@endDate: ' + endDate);

        String payload = '{';
        payload = payload + '"TransactionID": "' + 'eventId' + '",';
        payload = payload + '"WorkOrderNo": "' + workOrderNo + '",';
        payload = payload + '"ContractorCode": "' + 'MSN'+ '",';
        payload = payload + '"IsLastCostItem": ' + 'false'+ ',';
        payload = payload + '"Cost":{';
        payload = payload + '"LineItems":[';
        if(costList != null) {
        	for(WorkStep cost:costList) {
                payload = payload + '{';
                payload = payload + '"Contract": "' + contract + '",';
                payload = payload + '"ContractorLineItemCode": "' + cost.MSN_ScheduleItem_Code__c + '",';
                payload = payload + '"Quantity": ' + '1'+ ',';
                payload = payload + '"Rate": ' + '0'+ ',';
                String wsAnser = String.isNotBlank(cost.MSN_WorkStep_Answer__c) ? cost.MSN_WorkStep_Answer__c.replaceAll('\n', ' ') : '';
                String comment = cost.MSN_Service_Product_Code__c + '|' + wsAnser;                
                comment = comment.length() > 80 ? comment.substring(0, 80) : comment;
                payload = payload + '"Comments": "' + comment + '",';
                payload = payload + '"ChargeDate": "' + endDate + '"';
                payload = payload + '}';
                payload = payload + ',';
        	}  
        }
        else {
        	payload = payload + '{';
            payload = payload + '"Contract": "' + 'string' + '",';
            payload = payload + '"ContractorLineItemCode": "' + 'string' + '",';
            payload = payload + '"Quantity": ' + '1'+ ',';
            payload = payload + '"Rate": ' + '0'+ ',';
            payload = payload + '"Comments": "' + 'Work Step Answer'+ '",';
            payload = payload + '"ChargeDate": "' +'2022-06-18T08:24:20.477' + '"';
            payload = payload + '}';
            payload = payload + ',';
        }
        
        payload = payload.removeEnd(',');
        payload = payload + ' ]}}';
        return payload;
    }
}