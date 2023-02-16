/**
 * @File Name          : MSN_WorkOrderLineItemTriggerHelper.cls
 * @Description        : Trigger Helper for WorkOrderLineItem
 * @Author             : David Azzi
 * @Group              : 
 * @Last Modified By   : David Azzi
 * @Last Modified On   : 01/02/2022
 * @Modification Log   : 
 * Ver      Date            Author                  Modification
 * 1.0      01/02/2022      David Azzi              Initial Version
**/
public class MSN_WorkOrderLineItemTriggerHelper {
    
    //get all dispatched items, and recalculate WorkStep answers for Spotcode Mapping
    public static void updateUnansweredWorkPlanAnswers(List<WorkOrderLineItem> newWOLIs)
    {

        Set<Id> woIds = new Set<Id>();
        for(WorkOrderLineItem woli : newWOLIs){
            woIds.add( woli.WorkOrderId );
        }
        
        List<WorkStep> wsteps = [SELECT MSN_WorkStep_Answer__c, WorkOrderId, MSN_SPOT_Code__c
                                FROM WorkStep
                                WHERE WorkOrderId IN: woIds ];

        MSN_WorkStepTriggerHelper.autofillWorkStepAnswer(wsteps);
    }

    public static void callChildWorkOrderToIntegration(Map<Id, WorkOrderLineItem> workOrderLineItemsMap) {
        try {
            List<Outbound_Integration__e> platformEvents = new List<Outbound_Integration__e>();
            String endpoint = 'New_Child_Work_Order';
            platformEvents.addAll(MSN_IntegrationUtility.generateOutboundIntegrationEvents(workOrderLineItemsMap, 'WorkOrderLineItem', 
                new Map<String, List<String>>{endpoint => new String[]{'Create_Child_Work_Order1'}}));

            // publish platform events
            if(!platformEvents.isEmpty()) {
                Id jobId = System.enqueueJob(new MSN_Integration(platformEvents));
                MSN_Integration.integrationQueued = true;
            }
        }catch(Exception e){
            MSN_HandleErrorsException.insertLogException(e, '', '');
        }
    }

   /**
	* Author : Bohao Chen
	* Date : 12/12/2022
	* Description : Created for ticket integration when work order line items are updated
	**/
    public static void updateWorkOrderLineItemIntegration(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        
        List<WorkOrderLineItem> completedWOLIList = new List<WorkOrderLineItem>();
        List<WorkOrderLineItem> costWOLIList = new List<WorkOrderLineItem>();

        List<WorkOrderLineItem> workOrderLineItemList = [SELECT StartDate,EndDate, MSN_EAM_Work_Order_No__c, Description, 
                                                           Status,MSN_Contract__c, EAM_Work_Order_Status__c,
                                                           WorkOrder.Work_Order_No__c, WorkType.MSN_ActivityCode__c, 
                                                           WorkOrderId, StatusCategory, MSN_Work_Line_Number__c, 
                                                           MSN_Root_Work_Order__r.Work_Order_No__c, Asset.Comp_Key__c,
                                                           MSN_Root_Work_Order__r.StartDate, MSN_Root_Work_Order__r.EndDate,
                                                           CreatedDate
                                                         FROM WorkOrderLineItem WHERE Id IN: newItems.keySet() ];

        for(WorkOrderLineItem newWOLI: workOrderLineItemList) {

            WorkOrderLineItem oldWOLI = (WorkOrderLineItem)oldItems.get(newWOLI.Id);

            if(newWOLI.StatusCategory == 'Completed' && oldWOLI.StatusCategory != 'Completed') {
                completedWOLIList.add(newWOLI);
            }
            
            if(newWOLI.Status == 'Completed' && newWOLI.EAM_Work_Order_Status__c == 'FECO' && oldWOLI.EAM_Work_Order_Status__c != 'FECO') {
                costWOLIList.add(newWOLI);
            }
        }

        // send completed woli (child work order) payload to EAM
        if(!completedWOLIList.isEmpty()) {
            callChildWorkOrderCompleteIntegration(completedWOLIList);
        }

        // send cost payload to EAM
        if(!costWOLIList.isEmpty()) {
            callWorkOrderCostIntegration(costWOLIList);
        }
    }

    /**
	* Author : Bohao Chen
	* Date : 12/12/2022
	* Description : Call the work order (line item) complete integration
	**/
    private static void callChildWorkOrderCompleteIntegration (List<WorkOrderLineItem> completedWOLIList) {
        
        Map<Id,List<WorkStep>> woliIdToWorkStepList = findWorkSteps(completedWOLIList);

        List<sObject> createEventList = new List<sObject>();
        Integration_Endpoint__mdt endpointSetting = MSN_Utility.getEndpointSetting('New_Child_Work_Order');

        if(endpointSetting != null) {
            String endpointStr = endpointSetting.Endpoint__c;

            String method = 'PUT';
            
            for(WorkOrderLineItem woli : completedWOLIList) {
                List<WorkStep> costList = woliIdToWorkStepList.get(woli.Id);
                String payload = createCompletedChildWorkOrderPlayload(costList, woli);
                //String endpoint = 'https://9fa04kq7a0.execute-api.ap-southeast-2.amazonaws.com/dev/v2/maintenance/pmworkorder/'+wo.Work_Order_No__c;
                String endpoint = endpointStr.replace('{workOrderNumber}',woli.MSN_EAM_Work_Order_No__c);
                Outbound_Integration__e platformEvent = new Outbound_Integration__e();
                platformEvent.EndPoint__c = endpoint;
                platformEvent.Method__c = method;
                platformEvent.Payload__c = payload;
                createEventList.add(platformEvent);
            }
            
            // Publishing the events
            try {
                Boolean eventCreation = MSN_GenericPlatformEventUtility.publishEvents(createEventList);
            } catch(Exception e){
                MSN_HandleErrorsException.insertLogException(e, '', '');
            }
        }
    }

    private static Map<Id,List<WorkStep>> findWorkSteps(List<WorkOrderLineItem> completedWOLIList) {

        Set<Id> workOrderIdSet = new Set<Id>();
        Map<Id,List<WorkStep>> woliIdToWorkStepList = new Map<Id,List<WorkStep>>();
        List<sObject> createEventList = new List<sObject>();    
        
        // Loop through wo order to form the Id set
        // for(WorkOrder wo : completeWorkOrderList) {
        //     workOrderIdSet.add(wo.Id);
        // }
        
        List<WorkStep> workStepList = [SELECT WorkOrderLineItemId, MSN_ScheduleItem_Code__c, MSN_SPOT_Code__c,
                                            Description, MSN_WorkStep_Answer__c, LastModifiedDate
                                        FROM WorkStep 
                                        WHERE WorkOrderLineItemId in :completedWOLIList 
                                        AND MSN_Answer_Type__c != 'Schedule Item Code'];
        
        // Form the work order id to work step list
        for(WorkStep step:workStepList) {
            System.debug('step: '+step);
            if(!woliIdToWorkStepList.containsKey(step.WorkOrderLineItemId)) {
                List<WorkStep> stepList = new List<WorkStep>();
                stepList.add(step);
                woliIdToWorkStepList.put(step.WorkOrderLineItemId,stepList);
            }
            else { 
                List<WorkStep> stepList = woliIdToWorkStepList.get(step.WorkOrderLineItemId);
                stepList.add(step);
            	woliIdToWorkStepList.put(step.WorkOrderLineItemId,stepList);
            } 
            System.debug('woliIdToWorkStepList : '+woliIdToWorkStepList);
        }

        return woliIdToWorkStepList;
    }

    /**
	* Author : Sahil Wadhwa
	* Date : 08/06/2022
	* Description : Create the payload for planned work order complete
	**/
    private static string createCompletedChildWorkOrderPlayload(List<WorkStep> costList, WorkOrderLineItem woli) {
        String payload = '{';
        payload += '"TransactionID": "eventId",'
                + '"ContractorReference": "' + woli.MSN_Work_Line_Number__c + '",'
                + '"WorkOrderNo": "' + woli.MSN_Root_Work_Order__r.Work_Order_No__c + '",'
                + '"ContractorCode": "MSN",'
                + '"Asset":{'
                + '"AssetKey":' + woli.Asset.Comp_Key__c
                + '},'
                + '"ActivityCode": "' + woli.WorkType.MSN_ActivityCode__c + '",'
                + '"AssetCondition":"2",'
                + '"Comments": "' + woli.Description + '",'
                + '"Crew": "MSN",'
                + '"InitiatedDate":"' + woli.CreatedDate.format('yyyy-MM-dd\'T\'HH:mm:ss.sss',Userinfo.getTimeZone().toString()) + '",'
                + '"StartDate": "' + woli.MSN_Root_Work_Order__r.StartDate.format('yyyy-MM-dd\'T\'HH:mm:ss.sss',Userinfo.getTimeZone().toString())+ '",'
                + '"CompletedDate": "' + woli.MSN_Root_Work_Order__r.EndDate.format('yyyy-MM-dd\'T\'HH:mm:ss.sss',Userinfo.getTimeZone().toString())+ '",'
                + '"CompletedBy": "MSN",'
                + '"ResultCode": "COMP",'
                + '"VariationNo":"",'
                + '"TransactionType":"FM",';
        
        payload += '"Observations": [';
        if(costList != null){    
            for(WorkStep cost:costList) {
                String value = String.isNotBlank(cost.MSN_WorkStep_Answer__c) ? cost.MSN_WorkStep_Answer__c.replaceAll('\n', ' ') : '';
                payload += '{'
                        + '"Code": "' + cost.MSN_SPOT_Code__c + '",'
                        + '"Value": "' + value + '",'
                        + '"Date": "' + cost.LastModifiedDate.format('yyyy-MM-dd\'T\'HH:mm:ss.sss',Userinfo.getTimeZone().toString()) + '",'
                        + '"Detail": "' + cost.Description + '"'
                        + '},';
            }

        }
        else {
            payload += '{"Code": ""}';
        }
        payload = payload.removeEnd(',');
        payload += '],';

        payload += '"Failures":[{'
                + '"Code":"string",'
                + '"Detail":"string"'
                + '}]}';

        System.debug('@payload: ' + payload);

        return payload;
    }

    public static void createWoliFromWorkOrder(WorkOrder wo) {
        WorkOrderLineItem woli = new WorkOrderLineItem();
        woli.WorkOrderId = wo.Id;
        woli.WorkTypeId = wo.WorkType.Id;
        woli.AssetId = wo.Asset.Id;
        woli.Subject = wo.Subject;
        woli.Description = wo.Description;   

        System.debug('**WOLICreation: ' + woli);    
        Database.SaveResult woliSR = Database.insert(woli);
        Map<Id, List<Database.Error>> woliIdInsertErrors = new Map<id, List<Database.Error>>();

        if (!woliSR.isSuccess() ){
            woliIdInsertErrors.put( woliSR.getId(), woliSR.getErrors());
        }                        

        if ( woliIdInsertErrors.size() > 0 ){
            MSN_HandleErrorsException.insertSaveResultErrors('', 'Inserting Work Order Line Items', 'MSN_WorkOrderLineItemTriggerHelper', 
                'createWoliFromWorkOrder',MSN_Utility.getCurrentLineNumber(),woliIdInsertErrors);
        }
    }

    /**
	* Author : Bohao Chen
	* Date : 10/01/2023
	* Description : Call the work order line item cost integration
	**/
    public static void callWorkOrderCostIntegration (List<WorkOrderLineItem> completeWorkOrderLineItems) {
        System.debug('We are in work order cost integration');
        // Set<Id> workOrderIdSet = new Set<Id>();
        Map<Id,List<WorkStep>> woliIdToWorkStepList = new Map<Id,List<WorkStep>>();
        List<sObject> createEventList = new List<sObject>();                
        
        // Loop through wo order to form the Id set
        // for(WorkOrder wo:completeWorkOrderList) {
        //     workOrderIdSet.add(wo.Id);
        // }
        
        List<WorkStep> workStepList = [SELECT WorkOrderLineItemId, MSN_ScheduleItem_Code__c, 
                                            MSN_Service_Product_Code__c, MSN_WorkStep_Answer__c 
                                        FROM WorkStep 
                                        WHERE WorkOrderLineItemId IN :completeWorkOrderLineItems 
                                        AND MSN_Answer_Type__c = 'Schedule Item Code'];
        
        // Form the work order line item id to work step list
        for(WorkStep step : workStepList) {

            if(!woliIdToWorkStepList.containsKey(step.WorkOrderLineItemId)) {
                woliIdToWorkStepList.put(step.WorkOrderLineItemId, new List<WorkStep>());
            }

            woliIdToWorkStepList.get(step.WorkOrderLineItemId).add(step);
        }

        Integration_Endpoint__mdt endpointSetting = MSN_Utility.getEndpointSetting('Work_Order_Cost'); // TODO: what is the latest endpoint for work order line item cost?

        if(endpointSetting != null) {
            
            String endpointStr = endpointSetting.Endpoint__c;

            String method = 'PUT';
            
            for(WorkOrderLineItem woli : completeWorkOrderLineItems) {
                
                List<WorkStep> costList = woliIdToWorkStepList.get(woli.Id);

                // TODO: future improvement: 
                // Currenlty MSN_IntegrationUtility.generateOutboundIntegrationEvents can't handle any payload with a list inside
                // therefore, for any payload with lists, we cannot use MSN_IntegrationUtility.generateOutboundIntegrationEvents to
                // generate platform events
                String payload = MSN_IntegrationUtility.createCostPayload(costList, (SObject)woli); 

                //String endpoint = 'https://9fa04kq7a0.execute-api.ap-southeast-2.amazonaws.com/dev/v2/maintenance/workorder/'+wo.Work_Order_No__c+'/cost';
                String endpoint = endpointStr.replace('{workOrderNumber}', woli.MSN_EAM_Work_Order_No__c);
                Outbound_Integration__e platformEvent = new Outbound_Integration__e();
                platformEvent.EndPoint__c = endpoint;
                platformEvent.Method__c = method;
                platformEvent.Payload__c = payload;
                createEventList.add(platformEvent);
            }
            
            // Publishing the events
            try {
                Boolean eventCreation = MSN_GenericPlatformEventUtility.publishEvents(createEventList);
            } catch(Exception e){
                MSN_HandleErrorsException.insertLogException(e, '', '');
            }
        }
    }
}