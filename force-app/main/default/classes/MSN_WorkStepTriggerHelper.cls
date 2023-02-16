/**
 * @File Name          : MSN_WorkStepTriggerHelper.cls
 * @Description        : Trigger Helper for WorkStep
 * @Author             : David Azzi
 * @Group              : 
 * @Last Modified By   : David Azzi
 * @Last Modified On   : 28/01/2022
 * @Modification Log   : 
 * Ver      Date            Author                  Modification
 * 1.0      28/01/2022      David Azzi              Initial Version
**/
public class MSN_WorkStepTriggerHelper {

    public static void autofillWorkStepAnswer(List<WorkStep> newWS)
    {
        
        //create map of WorkOrderId, List<String> spot codes - wsWoIdSpotCodes
        //create map of WorkOrderId, newWS - woIdWS
        //create set of all spot codes in newWSAs
        //create set of all WoIds
        Map<Id, List<String>> wsWoIdSpotCodes = new Map<Id, List<String>>();
        Map<Id, List<WorkStep>> woIdNewWSs = new Map<Id, List<WorkStep>>();
        Set<String> usedSpotCodes = new Set<String>();
        Set<Id> usedWoIds = new Set<Id>();

        List<WorkStep> wsToUpdate = new List<WorkStep>();

        //System.debug('autofillWorkStepAnswer: ' + newWS);
        for ( WorkStep ws : newWS )
        {
            if ( String.isNotEmpty(ws.WorkOrderId) && String.isEmpty( ws.MSN_WorkStep_Answer__c ) ){
                usedSpotCodes.add( ws.MSN_SPOT_Code__c );
                usedWoIds.add( ws.WorkOrderId );

                if ( !wsWoIdSpotCodes.containsKey ( ws.WorkOrderId ) )
                {
                    wsWoIdSpotCodes.put( ws.WorkOrderId, new List<String>() );
                    woIdNewWSs.put( ws.WorkOrderId, new List<WorkStep>() );
                }

                wsWoIdSpotCodes.get(ws.WorkOrderId).add( ws.MSN_SPOT_Code__c );
                woIdNewWSs.get( ws.WorkOrderId ) .add( ws );
            }
        }

        //query Work_Step_Answer_Mapping__c (SPOT_Code__c, MSN_FROM_Object__c, MSN_FROM_Object_Field_API_Name__c)
        //create double map<String, map<String, String> wsamFromObjectThenFieldAPINameSpotCodes
        Map<String, Map<String, List<String>>> wsamFromObjectThenFieldAPINameSpotCodes = new Map<String, Map<String, List<String>>>();

        for( Work_Step_Answer_Mapping__c wsam : [SELECT MSN_SPOT_Code__c, MSN_FROM_Object__c, MSN_FROM_Object_Field_API_Name__c
                                                FROM Work_Step_Answer_Mapping__c 
                                                WHERE MSN_SPOT_Code__c IN: usedSpotCodes ]){
            if ( !wsamFromObjectThenFieldAPINameSpotCodes.containsKey( wsam.MSN_FROM_Object__c ) )
            {
                wsamFromObjectThenFieldAPINameSpotCodes.put( wsam.MSN_FROM_Object__c, new Map<String, List<String>>() );
            }
            
            if ( !wsamFromObjectThenFieldAPINameSpotCodes.get( wsam.MSN_FROM_Object__c ).containsKey( wsam.MSN_FROM_Object_Field_API_Name__c ) )
            {
                wsamFromObjectThenFieldAPINameSpotCodes.get( wsam.MSN_FROM_Object__c ).put( wsam.MSN_FROM_Object_Field_API_Name__c, new List<String>() );
            }

            wsamFromObjectThenFieldAPINameSpotCodes.get( wsam.MSN_FROM_Object__c ).get( wsam.MSN_FROM_Object_Field_API_Name__c ).add( wsam.MSN_SPOT_Code__c );
        }
               
        //It can't be helped - need to query every object at least once      
        for(String objectName : wsamFromObjectThenFieldAPINameSpotCodes.keySet() ){

            String searchFieldName = 'Id';

            if ( objectName == 'ServiceAppointment' ) {
                searchFieldName = 'FSSK__FSK_Work_Order__c'; //or is it ParentRecordId ??
            } else if ( objectName == 'WorkOrderLineItem' ) {
                searchFieldName = 'WorkOrderId';
            } else if ( objectName == 'Asset' ) {
                searchFieldName = 'Id'; //TODO Which field is primary searched for in Asset?
            }
            
            String query = 'SELECT ' + (wsamFromObjectThenFieldAPINameSpotCodes.get(objectName).containsKey(searchFieldName) ? '' : searchFieldName + ', ');
            query += MSN_Utility.buildFieldsForSOQLQuery( wsamFromObjectThenFieldAPINameSpotCodes.get(objectName).keySet(), objectName );
            query += ' FROM ' + objectName;

            query += ' WHERE ' + searchFieldName + ' IN: usedWoIds';

            Set<Id> woIdsToUpdate = new Set<Id>();
            for(SObject sobj : Database.query(query)){

                
                String woId = String.valueOf(sobj.get(searchFieldName));
                //loop through worksteps that are related to woId in woIdNewWSs
                //get workstep.spotcode
                    //loop through fields that in query sobj
                    //if object.spotcode exists, get query field value
                //match workstep.spotcode with spotcode,
                //fill workstep.answer with query.fieldName value related to spotcode
                if ( woIdNewWSs.containsKey( woId ) ){
                    for(WorkStep ws : woIdNewWSs.get(woId) ){
                        for(String fieldName : wsamFromObjectThenFieldAPINameSpotCodes.get(objectName).keySet() )
                        {
                            for(String spotCode : wsamFromObjectThenFieldAPINameSpotCodes.get(objectName).get(fieldName)){
                                if ( ws.MSN_SPOT_Code__c == spotCode ){
                                    WorkStep updatedWS = new WorkStep(
                                        Id = ws.Id,
                                        MSN_WorkStep_Answer__c = String.valueOf(sobj.get(fieldName))
                                    );    
                                    if ( !woIdsToUpdate.contains(ws.Id) ){
                                        wsToUpdate.add(updatedWS);
                                        woIdsToUpdate.add(ws.Id);
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }     

        if ( wsToUpdate.size() > 0) {
            Database.update(wsToUpdate);
        }
        
    }
    
}