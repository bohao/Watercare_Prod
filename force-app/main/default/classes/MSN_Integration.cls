/**
 * @File Name          : MSN_IntegrationUtility.cls
 * @Description        : Utility class for Dynamic Integration
 * @Author             : David Azzi
 * @Group              : 
 * @Last Modified By   : David Azzi
 * @Last Modified On   : 21/02/2022
 * @Modification Log   : 
 * Ver      Date            Author                  Modification
 * 1.0      21/02/2022      David Azzi              Initial Version
**/
public class MSN_Integration implements Queueable {
    
    /*
        David Notes
        I felt it was better to create a few maps and utilise it throughout this method but hindsight after creation
        a wrapper would probably be easier and faster. 
    */

    public static Boolean integrationQueued = false;
    // Map<Id, sObject> beforeMap;
    // Map<Id, sObject> afterMap;
    // String objectAPIName;
    // String triggerType;
    List<Outbound_Integration__e> platformEvents;
    List<ProductConsumed> partsList;
    List<WorkOrder> workOrders;

    /*public MSN_Integration(Map<Id, sObject> bMap, Map<Id, sObject> aMap, String objectName){
        beforeMap = bMap;
        afterMap = aMap;
        objectAPIName = objectName;
        triggerType = (Trigger.IsInsert) ? 'On_Insert__c' : (Trigger.IsUpdate) ? 'On_Update__c' : 'On_Delete__c';
    }*/

    public MSN_Integration(List<Outbound_Integration__e> platformEvents) {
        this.platformEvents = platformEvents;
    }

    public MSN_Integration(List<Outbound_Integration__e> platformEvents, List<ProductConsumed> partsList) {
        this.platformEvents = platformEvents;
        this.partsList = partsList;
    }

    // this constructor is only for new work order creation to create WOLI in order to send another 
    // new child work order payload to EAM due to queuable job limit which is 2
    public MSN_Integration(List<Outbound_Integration__e> platformEvents, List<WorkOrder> workOrders) {
        this.platformEvents = platformEvents;
        this.workOrders = workOrders;
    }

    public void execute(QueueableContext qc){
        // createOutboundIntegrationPiece(beforeMap, afterMap, objectAPIName, triggerType);
        try {
            Boolean eventCreation = MSN_GenericPlatformEventUtility.publishEvents(platformEvents);
            
            // for parts consumed, we need to tick the checkbox "Sent to EAM"
            if(partsList != null && !partsList.isEmpty()){ 
                List<String> partsConsumedIds = new List<String>();
                for(ProductConsumed part:partsList) {
                    partsConsumedIds.add(part.Id);
                }
                MSN_ProductConsumedTriggerHelper.setSentToEamForPartsConsumed(partsConsumedIds);
            }

            // create work order line item for each new work order created
            if(this.workOrders != null && !this.workOrders.isEmpty()) {
                for(WorkOrder wo : this.workOrders) {
                    if(wo.AssetId != null && wo.WorkType.MSN_ActivityCode__c != null) {
                        MSN_WorkOrderLineItemTriggerHelper.createWoliFromWorkOrder(wo);
                    }
                }
            }
            

        } catch(Exception e){
            MSN_HandleErrorsException.insertLogException(e, '', '');
        }
    }

    /*public static void createOutboundIntegrationPiece(Map<Id, sObject> beforeMap, Map<Id, sObject> afterMap, String objectAPIName, String triggerType){
		
        System.debug('@sahil We are in createOutboundIntegrationPiece.');
        System.debug('@sahil objectAPIName: '+objectAPIName);
        System.debug('@sahil triggerType: '+triggerType);
        
        //get a list of fields that have changed in the sobjects
        Map<Id, Map<String, String>> recordIdChangedFieldNameAndNewValue = new Map<Id, Map<String, String>>();
        if(triggerType == 'On_Update__c'){
            for ( Id beforeId : beforeMap.keySet() ){
                recordIdChangedFieldNameAndNewValue.put( beforeId, new Map<String, String>() );
                for(String changedFieldName : MSN_Utility.compareSobjects(beforeMap.get(beforeId), afterMap.get(beforeId)) ){
                    recordIdChangedFieldNameAndNewValue.get(beforeId).put( changedFieldName, String.valueOf(afterMap.get(beforeId).get(changedFieldName)));
                }
            }
        }
        else if(triggerType == 'On_Insert__c'){
            for ( Id recordId : afterMap.keySet() ){
                Map<String, Object> afterRecordsMap = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(afterMap.get(recordId)));

                System.debug('@afterRecordsMap: ' + afterRecordsMap);

                recordIdChangedFieldNameAndNewValue.put(recordId, new Map<String, String>() );
                for(String changedFieldName : afterRecordsMap.keySet()) {
                    if(!changedFieldName.equalsIgnoreCase('attributes')) {
                        System.debug('@changedFieldName: ' + changedFieldName);
                        recordIdChangedFieldNameAndNewValue.get(recordId).put(changedFieldName, String.valueOf(afterMap.get(recordId).get(changedFieldName)));
                    }
                }
            }
        }
        System.debug('@sahil recordIdChangedFieldNameAndNewValue: '+recordIdChangedFieldNameAndNewValue);

        //Get all trigger metadata that meets criteria to be triggered
        Map<String, Integration_Mapping__mdt> mappingNameAndMappingMetadata = MSN_IntegrationUtility.getTriggerFieldWithMappingName(objectAPIName, recordIdChangedFieldNameAndNewValue, triggerType);

        //get payload from custom metadata payload that relate to the trigger criteria found
        Set<String> payloadMetaDataIds = new Set<String>();
        System.debug('@sahil mappingNameAndMappingMetadata.values()'+mappingNameAndMappingMetadata.values());
        for (Integration_Mapping__mdt fm : mappingNameAndMappingMetadata.values()){
            payloadMetaDataIds.add(fm.Integration_Payloads__c);
        }
        System.debug('@sahil payloadMetaDataIds'+payloadMetaDataIds);
        Map<Id, Integration_Payloads__mdt> payloadMappings = MSN_IntegrationUtility.getCMetadataPayloadInformation(payloadMetaDataIds);
        // List<Integration_Payloads__mdt> payloadMappings = MSN_IntegrationUtility.getCMetadataPayloadInformation(payloadMetaDataIds);

        //get all the mapping names that are in the payloads
        // Map<Integration_Payloads__mdt, List<String>> payloadObjWithMappedNames = new Map<Integration_Payloads__mdt, List<String>>();
        Map<Id, List<String>> payloadIdWithMappedNames = new Map<Id, List<String>>();
        
        System.debug('@sahil payloadMappings'+payloadMappings);
        // for(Integration_Payloads__mdt payloadObj : payloadMappings.values()){
            // payloadObjWithMappedNames.put(payloadObj, MSN_IntegrationUtility.getMappingNamesFromPayload(payloadObj.Payload__c));
            // payloadIdWithMappedNames.put(payloadObj.Id, MSN_IntegrationUtility.getMappingNamesFromPayload(payloadObj.Payload__c));
        // }

        //get the field information from the custommetadata that links to payloads
        mappingNameAndMappingMetadata.putAll( MSN_IntegrationUtility.getCMetadataFieldsRelatedToPayload(payloadMetaDataIds) );

        //loop through mapped names and get the object the mapped names link to <object,fields>
        Map<String, Set<String>> objectNameAndFields = new Map<String, Set<String>>();
        
        // TODO: could be replaced with getObjectNameFieldsMapping in MSN_IntegrationUtility.cls
        // System.debug('@sahil payloadIdWithMappedNames.keySet()'+payloadIdWithMappedNames.keySet()); 
        // for(Integration_Payloads__mdt payloadObj : payloadIdWithMappedNames.keySet() ){ //18:33:58.0 (238541755)|VARIABLE_ASSIGNMENT|[97]|payloadObj|{"EndPoint__c":"thiswillchangeforeac (9 more) ...","Integration_Type__c":"Outbound","Is_Active__c":true,"Payload__c":"{\r\n  \"TransactionID\" (362 more) ...","Platform_Event_API_Name__c":"mandatory now, name_ (2 more) ...","Id":"m060p0000008mdqAAA"}|0x615762dd
        for(Integration_Payloads__mdt payloadObj : payloadMappings.values()){

            List<String> mappingNames = MSN_IntegrationUtility.getMappingNamesFromPayload(payloadObj.Payload__c);

            payloadIdWithMappedNames.put(payloadObj.Id, mappingNames);
            
            for(String mappingName : mappingNames) {

            // for(String mappingName : payloadIdWithMappedNames.get(payloadObj) ){//18:33:58.0 (238681842)|VARIABLE_ASSIGNMENT|[98]|mappingName|"MSN_JobNote_Details_ (2 more) ..."
                System.debug('@mappingName: ' + mappingName); //@mappingName: MSN_JobNote_Details__c
                // Todo: key is wrong, need to fix it
                System.debug('@mappingNameAndMappingMetadata: ' + mappingNameAndMappingMetadata);// @mappingNameAndMappingMetadata: {Job_Details=Integration_Mapping__mdt:{Integration_Payloads__c=m060p0000008mdq, External_Id_Field__c=null, Label=Job Details, SF_Field_API_Name__c=MSN_JobNote_Details__c, MasterLabel=Job Details, Language=en_US, Field_Value_For_Trigger__c=null, Integration_Trigger__c=true, On_Insert__c=true, SF_Field_Data_Type__c=Text Area, DeveloperName=Job_Details, NamespacePrefix=null, On_Update__c=false, SF_Object_API_Name__c=MSN_JobNotes__c, Is_Active__c=true, On_Delete__c=false, QualifiedApiName=Job_Details, Id=m040p0000004v0V}, Service_Request_Number=Integration_Mapping__mdt:{Integration_Payloads__c=m060p0000008mdq, External_Id_Field__c=null, Label=Service Request Number, SF_Field_API_Name__c=Service_Request_Number__c, MasterLabel=Service Request Number, Language=en_US, Field_Value_For_Trigger__c=null, Integration_Trigger__c=true, On_Insert__c=true, SF_Field_Data_Type__c=Text, DeveloperName=Service_Request_Number, NamespacePrefix=null, On_Update__c=false, SF_Object_API_Name__c=WorkOrder, Is_Active__c=true, On_Delete__c=false, QualifiedApiName=Service_Request_Number, Id=m040p0000004uE2}}

                if ( mappingNameAndMappingMetadata.containsKey(mappingName) ) {

                    System.debug('@value: ' + mappingNameAndMappingMetadata.get(mappingName));

                    if ( !objectNameAndFields.containsKey(mappingNameAndMappingMetadata.get(mappingName).SF_Object_API_Name__c) ){
                        if ( MSN_Utility.doesObjectExist(mappingNameAndMappingMetadata.get(mappingName).SF_Object_API_Name__c) ){
                            objectNameAndFields.put( mappingNameAndMappingMetadata.get(mappingName).SF_Object_API_Name__c, new Set<String>());
                        } else {
                            continue;
                        }
                    }
                    objectNameAndFields.get( mappingNameAndMappingMetadata.get(mappingName).SF_Object_API_Name__c ).add(mappingNameAndMappingMetadata.get(mappingName).SF_Field_API_Name__c);
                }
            }
        }

        //build and query objects and fields
        //TODO - build dynamic parent-child query if can't find any relation with child- How do you tell which one childs information to take if there is multiple? E.g. Multiple SA to WO?
        Set<Id> triggerIds = (triggerType == 'On_Delete__c') ? beforeMap.keySet() : afterMap.keySet();
        Map<Id, Map<String, List<sObject>>> queriedResults = new Map<Id, Map<String, List<sObject>>>();
        Map<String, List<String>> objectNameAndRelationship = new Map<String, List<String>>();
        
        System.debug('@sahil objectNameAndFields.keySet()'+objectNameAndFields.keySet());
        for(String objectName : objectNameAndFields.keySet() ){

            String query = '';
            List<sObject> results = new List<sObject>();

            if ( !objectNameAndRelationship.containsKey( objectName ) ){
                objectNameAndRelationship.put( objectName, new List<String>() );
            }
            if ( objectName == objectAPIName ){
                //The information can be taken from the trigger rather than having to query it from the same records
                results = (triggerType == 'On_Delete__c') ? beforeMap.values() : afterMap.values();
                objectNameAndRelationship.get( objectName ).add('');
            }else {
                //get the lookup relationship name of the object to add in to the query
                List<String> relationships = MSN_IntegrationUtility.getQueryStringsFromObjectRelationships(objectAPIName, objectName);
                if ( relationships[0].contains('ERROR:')){
                    continue;
                }
                //create the query
                List<String> relationshipAndField = new List<String>();
                for(String field : objectNameAndFields.get(objectName)){
                    relationshipAndField.add( relationships[0] + '.' + field);
                }
                query = String.format('SELECT {0} FROM ' + objectAPIName + ' WHERE Id IN: triggerIds', new List<String>{String.join(relationshipAndField, ', ')});

                
                objectNameAndRelationship.get( objectName ).add(relationships[0]);
                results = Database.query(query); // oops, query inside for loop // probably we can't move this out and it won't have many object names
            }
            
            System.debug('Query: ' + query);
            System.debug('Query.objectName: ' + objectName);
            for(sObject result : results){
                System.debug('result: ' + result);
                if ( !queriedResults.containsKey(result.Id) ){
                    queriedResults.put(result.Id, new Map<String, List<sObject>>() );
                }
                if ( !queriedResults.get(result.Id).containsKey( objectName) ){
                    queriedResults.get(result.Id).put( objectName, new List<sObject>() );
                }
                queriedResults.get(result.Id).get(objectName).add( result );
            }
        }

        System.debug('Step5-queriedResults' + queriedResults);
        //Get the mapped names and the salesforce values to be able to fill the payload with the information
        Map<Id, Map<Id, Map<String, String>>> recordIdPayloadMappingValues = MSN_IntegrationUtility.getMappedNamesAndFieldValuesFromPayloads(
                                                                                                    payloadIdWithMappedNames,
                                                                                                    mappingNameAndMappingMetadata,
                                                                                                    queriedResults,
                                                                                                    objectNameAndRelationship);
                                                                                                    
        System.debug('Step6-recordIdPayloadMappingValues' + recordIdPayloadMappingValues);
        //fill the payload
        Map<Id, List<Integration_Payloads__mdt>> recordIdsUpdatedPayloads = MSN_IntegrationUtility.replaceAllMappingsInPayload(recordIdPayloadMappingValues, payloadMappings);

        Map<String, String> endpointsByApiName = retrieveEndpoints(recordIdsUpdatedPayloads);

        System.debug('Step7-completedPayloads' + recordIdsUpdatedPayloads);

        String instanceName = EnvironmentHelper.getSandboxName();

        //FINAL STEP - Create the object from the payload or send to the endpoint on the metadata
        List<sObject> platformEventsToCreate = new List<sObject>();
        for(Id recordId : recordIdsUpdatedPayloads.keySet() ){
            for(Integration_Payloads__mdt intPayloadObj : recordIdsUpdatedPayloads.get(recordId)){

                String endpointApiName;
                if(instanceName.equalsIgnoreCase('Production')) {
                    endpointApiName = intPayloadObj.EndPoint__c;
                }
                else {
                    endpointApiName = intPayloadObj.EndPoint__c + '_' + instanceName.capitalize();
                }    

                if(endpointsByApiName.containsKey(endpointApiName)) {

                    String endpoint = endpointsByApiName.get(endpointApiName); // the endpoint with placeholder

                    Map<String, String> fieldValueMap = recordIdPayloadMappingValues.get(recordId).get(intPayloadObj.Id);
                    System.debug('@fieldValueMap: ' + fieldValueMap);

                    // below is to search a hardcoded placeholder. it won't work if placeholder name gets updated in the future
                    endpoint = endpoint.toLowercase().replace('{workordernumber}', fieldValueMap.get('workordernumber'));
                    System.debug('@endpoint: ' + endpoint);

                    Outbound_Integration__e outboundPE = new Outbound_Integration__e();
                    outboundPE.EndPoint__c = endpoint;
                    outboundPE.Method__c = 'POST';
                    outboundPE.Payload__c = intPayloadObj.Payload__c;
                    platformEventsToCreate.add(outboundPE);
                }
            }
        }
        try {
            if(!platformEventsToCreate.isEmpty()) {
                Boolean eventCreation = MSN_GenericPlatformEventUtility.publishEvents(platformEventsToCreate);
            }
        } catch(Exception e){
            MSN_HandleErrorsException.insertLogException(e, '', '');
        }
    }

    private static Map<String, String> retrieveEndpoints(Map<Id, List<Integration_Payloads__mdt>> recordIdsUpdatedPayloads) {

        Map<String, String> endpointsByDevName = new Map<String, String>();
        Set<String> endpoints = new Set<String>();

        String instanceName = EnvironmentHelper.getSandboxName();

        for(Id recordId : recordIdsUpdatedPayloads.keySet() ){
            for(Integration_Payloads__mdt intPayloadObj : recordIdsUpdatedPayloads.get(recordId) ){
                Outbound_Integration__e outboundPE = new Outbound_Integration__e();

                if(instanceName.equalsIgnoreCase('Production')) {
                    endpoints.add(intPayloadObj.EndPoint__c);
                }
                else {
                    endpoints.add(intPayloadObj.EndPoint__c + '_' + instanceName.capitalize());
                }                
            }
        }

        System.debug('@endpoints: ' + endpoints);

        for(Integration_Endpoint__mdt ie : [SELECT DeveloperName, Endpoint__c 
                                            FROM Integration_Endpoint__mdt 
                                            WHERE DeveloperName IN: endpoints 
                                            AND Active__c = true]) {
            // replace placeholder in the endpoint with the value
            // String endpoint = laborEndpoint.replace('{workordernumber}', workOrderMap.get(laboutIdTowoIdMap.get(labour.Id)).Work_Order_No__c);


            endpointsByDevName.put(ie.DeveloperName, ie.EndPoint__c);
        }            
        
        System.debug('@endpointsByDevName: ' + endpointsByDevName);

        return endpointsByDevName;
    }*/
}