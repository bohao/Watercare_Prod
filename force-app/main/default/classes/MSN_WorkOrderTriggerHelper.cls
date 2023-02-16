/**
* @File Name          : MSN_WorkOrderTriggerHelper.cls
* @Description        : Trigger Helper for WorkOrder
* @Author             : David Azzi
* @Group              : 
* @Last Modified By   : Bohao Chen
* @Last Modified On   : 20/01/2023
* @Modification Log   : 
* Ver      Date            Author                  Modification
* 1.0      01/02/2022      David Azzi              Initial Version
**/
public class MSN_WorkOrderTriggerHelper {
    
    //get all dispatched items, and recalculate WorkStep answers for Spotcode Mapping
    public static void updateUnansweredWorkPlanAnswers(Set<Id> newWOIds) {
        List<WorkStep> wsteps = [SELECT MSN_WorkStep_Answer__c, WorkOrderId, MSN_SPOT_Code__c
                                 FROM WorkStep
                                 WHERE WorkOrderId IN: newWOIds ];
        
        MSN_WorkStepTriggerHelper.autofillWorkStepAnswer(wsteps);
    }
    
    /**
	* Author : Sahil Wadhwa
	* Date : 26/04/2022
	* Description : Created for ticket MSN-300 & MSN-692. Calculate and divide labour hours when the SA is set to completed
	**/
    public static void divideLabourHours(Map<Id, SObject> oldWorkOrderMap, List<WorkOrder> newWorkOrderList) {
        // newSAs is now gone
        List<ServiceAppointment> newSAs = new List<ServiceAppointment>();
        Set<Id> workOrderIdSet = new Set<Id>();
        Set<Id> assignedRecourceIdSet = new Set<Id>();
        Set<Id> sAIdSet = new Set<Id>();
        Set<Id> serviceResourceIdSet = new Set<Id>();
        Map<Id,ServiceAppointment> recourceToServiceAppointment = new Map<Id,ServiceAppointment>();
        Map<Id,List<ServiceResource>> SAToServiceResourceMap = new Map<Id,List<ServiceResource>>();
        List<ServiceAppointment> processSAList = new List<ServiceAppointment>();
        List<ProductConsumed> productConsumedList = new List<ProductConsumed>();
        Map<Id,List<WorkOrderLineItem>> woToWOLIMap = new Map<Id,List<WorkOrderLineItem>>();
        Map<Id,WorkOrder> workOrderIdMap = new Map<Id,WorkOrder>();
        
        for(WorkOrder wo:newWorkOrderList) {
            // MSRS-2798 Change Labour Line creation trigger point from  status 'completed' to "Reviewed"
            if(wo.Status == 'Reviewed' && oldWorkOrderMap.get(wo.Id).get('Status') != 'Reviewed'){
                workOrderIdSet.add(wo.Id);
                workOrderIdMap.put(wo.Id,wo);
            }
        }
        
        if(workOrderIdSet.size()>0){
            // Get all the service line items with Assigned recources
            List<ServiceAppointment> serviceAppointmentList = [SELECT id,ParentRecordId,ActualDuration,ActualStartTime,MSN_Labour_Time_Minutes__c,(SELECT id,ServiceResourceId,ServiceCrewId,ServiceAppointmentId FROM ServiceResources) FROM ServiceAppointment WHERE ParentRecordId in :workOrderIdSet];
            
            for(ServiceAppointment serviceAppointment:serviceAppointmentList) {
                List<AssignedResource> assignedResourceList = serviceAppointment.ServiceResources;
                for(AssignedResource assignedResource:assignedResourceList) {
                    serviceResourceIdSet.add(assignedResource.ServiceResourceId);
                }
            }
            
            // Get all the WOLI's related to work orders
            List<WorkOrderLineItem> woLineItemList = [SELECT Id,WorkOrderId FROM WorkOrderLineItem WHERE WorkOrderId in :workOrderIdSet];
            
            for(WorkOrderLineItem woli:woLineItemList) {
                if(woToWOLIMap.containsKey(woli.WorkOrderId)){
                    List<WorkOrderLineItem> woliList = woToWOLIMap.get(woli.WorkOrderId);
                    woliList.add(woli);
                    woToWOLIMap.put(woli.WorkOrderId,woliList);
                }
                else {
                    List<WorkOrderLineItem> woliList = new List<WorkOrderLineItem>();
                    woliList.add(woli);
                    woToWOLIMap.put(woli.WorkOrderId,woliList);
                }
            }
            
            Map<Id,ServiceResource> serviceResourceMap = new Map<Id,ServiceResource>([SELECT Id,Is_Subcontractor__c,MSN_Employee_Code__c,Trade_Code__c,ResourceType,Name FROM ServiceResource WHERE id in :serviceResourceIdSet]);
            // Loop through all the service resources to form a map to service appointment
            for(ServiceAppointment serviceApp:serviceAppointmentList) {
                List<AssignedResource> assignedResourceList = serviceApp.ServiceResources;
                for(AssignedResource resource:assignedResourceList) {
                    if (serviceResourceMap.get(resource.ServiceResourceId).Is_Subcontractor__c == false && serviceResourceMap.get(resource.ServiceResourceId).ResourceType == 'T' && SAToServiceResourceMap.containsKey(serviceApp.Id)) {
                        List<ServiceResource> serviceResourceList = SAToServiceResourceMap.get(serviceApp.Id);
                        serviceResourceList.add(serviceResourceMap.get(resource.ServiceResourceId));
                        SAToServiceResourceMap.put(serviceApp.Id,serviceResourceList);
                    }
                    else if (serviceResourceMap.get(resource.ServiceResourceId).Is_Subcontractor__c == false && serviceResourceMap.get(resource.ServiceResourceId).ResourceType == 'T') {
                        List<ServiceResource> serviceResourceList = new List<ServiceResource>();
                        serviceResourceList.add(serviceResourceMap.get(resource.ServiceResourceId));
                        SAToServiceResourceMap.put(serviceApp.Id,serviceResourceList);
                    }
                }
            }
            
            Map<Id,Id> mapPriceBookToPriceBookEntry = new Map<Id,Id>();
            // Here get the product Id using a custom label
            String productId;

            if(Test.isRunningTest()) {
                productId = [SELECT Id FROM Product2 WHERE Name = 'Labour Charge' LIMIT 1].Id;
            }
            else {
                productId = System.Label.MSN_Labor_Product_Id;
            }
            
            // Now we need to get the price book entries
            List<PricebookEntry> pbeList = [SELECT id,Pricebook2Id,Product2Id FROM PricebookEntry WHERE Product2Id = :productId];
            
            for(PricebookEntry entry:pbeList){
                mapPriceBookToPriceBookEntry.put(entry.Pricebook2Id,entry.Id);
            }
            
            
            // Loop through all SA to break the time
            for(ServiceAppointment processSA : serviceAppointmentList) {

                WorkOrder wo = workOrderIdMap.get(processSA.ParentRecordId);
                List<WorkOrderLineItem> woliList = woToWOLIMap.get(wo.Id);
                List<ServiceResource> serviceResourceList = SAToServiceResourceMap.get(processSA.Id);
                
                // calculate the hours time here for each one
                if(serviceResourceList != null && serviceResourceList.size() > 0) {
                    Decimal timeForEachEntry;
                    if(woliList == null) {
                        // timeForEachEntry = processSA.ActualDuration;
                        timeForEachEntry = processSA.MSN_Labour_Time_Minutes__c;
                    }
                    else {
                        Integer numberOfWOLI = woliList.size();
                        // timeForEachEntry = processSA.ActualDuration/(numberOfWOLI);
                        timeForEachEntry = processSA.MSN_Labour_Time_Minutes__c/(numberOfWOLI);
                    }
                                
                    // Loop through to create Labour entry
                    for(ServiceResource resource:serviceResourceList) {
                        if(woliList == null ) {
                            ProductConsumed productEntry = new ProductConsumed();
                            productEntry.WorkOrderId = wo.Id;
                            productEntry.PricebookEntryId = mapPriceBookToPriceBookEntry.get(wo.Pricebook2Id);
                            productEntry.QuantityConsumed = timeForEachEntry;
                            productEntry.Name_of_Crew__c = resource.Name;
                            productEntry.MSN_Trade_Code__c = resource.Trade_Code__c;
                            productEntry.MSN_Employee_Code__c = resource.MSN_Employee_Code__c;
                            productEntry.Date_of_the_SA__c = processSA.ActualStartTime.date();
                            System.debug('productEntry : '+productEntry);
                            productConsumedList.add(productEntry);
                        }
                        else{
                            for(WorkOrderLineItem lineItem:woLineItemList) {
                                ProductConsumed productEntry = new ProductConsumed();
                                productEntry.WorkOrderId = wo.Id;
                                productEntry.WorkOrderLineItemId = lineItem.Id;
                                productEntry.PricebookEntryId = mapPriceBookToPriceBookEntry.get(wo.Pricebook2Id);
                                productEntry.QuantityConsumed = timeForEachEntry;
                                productEntry.Name_of_Crew__c = resource.Name;
                                productEntry.MSN_Trade_Code__c = resource.Trade_Code__c;
                                productEntry.MSN_Employee_Code__c = resource.MSN_Employee_Code__c;
                                productEntry.Date_of_the_SA__c = processSA.ActualStartTime.date();
                                System.debug('productEntry : '+productEntry);
                                productConsumedList.add(productEntry);
                            }
                        }
                    }
                }
            }  
            
            System.debug('productConsumedList : '+productConsumedList);
            if(productConsumedList.size()>0){
           		insert productConsumedList;
            }
        }
    }
    
    /**
	* Author : Sahil Wadhwa
	* Date : 07/06/2022
	* Description : Created for ticket integration when new work orders are created
	**/
    public static void newWorkOrderIntegration(List<WorkOrder> newWorkOrderList) {

        Map<Id, WorkOrder> newWorkOrdersMap = new Map<Id, WorkOrder>();
        Map<Id, WorkOrder> newChildWorkOrdersMap = new Map<Id, WorkOrder>();

        Set<Id> woIdSet = new Set<Id> ();
        
        for(WorkOrder workOrder:newWorkOrderList) {
            woIdSet.add(workOrder.Id);
        }
        
        List<WorkOrder> workOrderList = [SELECT id, Planned_Work__c, ParentWorkOrderId, StatusCategory, WorkType.Id, Asset.Id,
                                            Work_Order_No__c, Status, MSN_Contract__c, Service_Request_Number__c, WorkOrderNumber,
                                            Subject, Description, AssetId, WorkType.MSN_ActivityCode__c
                                        FROM WorkOrder WHERE Id in:woIdSet];
        
        for(WorkOrder workOrder : workOrderList) {
            // main work order
            if(workOrder.ParentWorkOrderId == null && workOrder.Work_Order_No__c != null) {
                newWorkOrdersMap.put(workOrder.Id, workOrder);
            }
            else {
                if(workOrder.StatusCategory != 'Completed') {
                    newChildWorkOrdersMap.put(workOrder.Id, workOrder);
                }
            }
        }

        // send the new work order payload back to EAM with salesforce ID
        if(!newWorkOrdersMap.isEmpty()) {
            callWorkOrderToEAMIntegration(newWorkOrdersMap);
        }

        
        // Call the reacive child Work Order to EAM integration class
        if(!newChildWorkOrdersMap.isEmpty()) {
            callChildWorkOrderToIntegration(newChildWorkOrdersMap);
        }
    }
    
    /**
	* Author : Sahil Wadhwa
	* Date : 07/06/2022
	* Description : Created for ticket integration when work orders are updated
	**/
    public static void updateWorkOrderIntegration(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        System.debug('Calling updateWorkOrderIntegration');
        // Here we will go through the updated work orders and find the integrations to call
        List<WorkOrder> completedWOList = new List<WorkOrder>();
        List<WorkOrder> completedPlannedWOList = new List<WorkOrder>();
        List<WorkOrder> completedReaciveWOList = new List<WorkOrder>();
        List<WorkOrder> completedChildWorkOrders = new List<WorkOrder>();

        Set<Id> woIdSet = newItems.keySet();
        
                
        List<WorkOrder> workOrderList = [SELECT id,StartDate,EndDate,MSN_Job_Notes__c, Planned_Work__c, Reactive_Work__c, Work_Order_No__c,
                                                Status,MSN_Contract__c,Service_Request_Number__c,WorkOrderNumber, EAM_Work_Order_Status__c,
                                                ParentWorkOrder.Work_Order_No__c, WorkType.MSN_ActivityCode__c, Asset.Comp_Key__c,
                                                ParentWorkOrderId, StatusCategory, Description, CreatedDate, RootWorkOrder.Work_Order_No__c
                                        FROM WorkOrder WHERE Id in:woIdSet ];
        
        for(WorkOrder newWO: workOrderList) {
            WorkOrder oldWO = (WorkOrder)oldItems.get(newWO.Id);
            
            // parent work order
            /*if(newWO.ParentWorkOrderId == null) {
                // MSRS-2795: stop sending completed wo payload for parent wo
                if(newWO.Status=='Completed' && oldWO.Status != 'Completed' && newWO.Reactive_Work__c) {
                    // completedWOList.add(newWO);
                    completedReaciveWOList.add(newWO);
                }
                else if (newWO.Status=='Completed' && oldWO.Status != 'Completed' && newWO.Planned_Work__c) {
                    // completedWOList.add(newWO);
                    completedPlannedWOList.add(newWO);
                }

                // MSRS-2796 Parent Work Orders: Do not send Costs Integration Payload on EAM Status change to "FECO"
                // Call work order cost integration for completed work orders with EAM_Work_Order_Status__c equals to 'success'
                //if(newWO.Status == 'Completed' && newWO.EAM_Work_Order_Complete__c == 'Success' && oldWO.EAM_Work_Order_Complete__c != 'Success') {
                if(newWO.Status == 'Completed' && newWO.EAM_Work_Order_Status__c == 'FECO' && oldWO.EAM_Work_Order_Status__c != 'FECO') {
                    completedWOList.add(newWO);
                }
            }*/

            // only sends completed child work order payload to EAM excluding parent work orders
            if(newWO.ParentWorkOrderId != null && newWO.StatusCategory == 'Completed' && oldWO.StatusCategory != 'Completed') {
                completedChildWorkOrders.add(newWO);
            }

            // Call work order cost integration for completed child work orders (not for parent work orders) with EAM_Work_Order_Status__c equals to 'FECO'
            if(newWO.ParentWorkOrderId != null && newWO.Status == 'Completed' && newWO.EAM_Work_Order_Status__c == 'FECO' && oldWO.EAM_Work_Order_Status__c != 'FECO') {
                completedWOList.add(newWO);
            }
        }
        
        // Call the Work Order Cost integration class
        if(!completedWOList.isEmpty()) {
        	callWorkOrderCostIntegration(completedWOList);
        }
        
        System.debug('@sahil completedPlannedWOList : '+completedPlannedWOList);

        if(!completedChildWorkOrders.isEmpty()) {
            callCompletedChildWorkOrderToIntegration(completedChildWorkOrders, newItems);
        }
    }
    
    /**
	* Author : Sahil Wadhwa
	* Date : 07/06/2022
	* Description : Call the work order cost integration
	**/
    public static void callWorkOrderCostIntegration (List<WorkOrder> completeWorkOrderList) {
        System.debug('We are in work order cost integration');
        Set<Id> workOrderIdSet = new Set<Id>();
        Map<Id,List<WorkStep>> woIdToWorkStepList = new Map<Id,List<WorkStep>>();
        List<sObject> createEventList = new List<sObject>();                
        
        // Loop through wo order to form the Id set
        for(WorkOrder wo:completeWorkOrderList) {
            workOrderIdSet.add(wo.Id);
        }
        
        List<WorkStep> workStepList = [SELECT Id,WorkOrderId,MSN_ScheduleItem_Code__c,MSN_Service_Product_Code__c,MSN_WorkStep_Answer__c FROM WorkStep WHERE WorkOrderId in :workOrderIdSet AND MSN_Answer_Type__c = 'Schedule Item Code'];
        
        // Form the work order id to work step list
        for(WorkStep step:workStepList) {
            if(!woIdToWorkStepList.containsKey(step.WorkOrderId)) {
                List<WorkStep> stepList = new List<WorkStep>();
                stepList.add(step);
                woIdToWorkStepList.put(step.WorkOrderId,stepList);
            }
            else {
                List<WorkStep> stepList = woIdToWorkStepList.get(step.WorkOrderId);
                stepList.add(step);
            	woIdToWorkStepList.put(step.WorkOrderId,stepList);
            }
        }

        Integration_Endpoint__mdt endpointSetting = MSN_Utility.getEndpointSetting('Work_Order_Cost');

        if(endpointSetting != null) {
            
            String endpointStr = endpointSetting.Endpoint__c;

            String method = 'PUT';
            
            for(WorkOrder wo:completeWorkOrderList) {
                List<WorkStep> costList = woIdToWorkStepList.get(wo.Id);

                // TODO: future improvement: 
                // Currenlty MSN_IntegrationUtility.generateOutboundIntegrationEvents can't handle any payload with a list inside
                // therefore, for any payload with lists, we cannot use MSN_IntegrationUtility.generateOutboundIntegrationEvents to
                // generate platform events
                String payload = MSN_IntegrationUtility.createCostPayload(costList, (SObject)wo); 

                //String endpoint = 'https://9fa04kq7a0.execute-api.ap-southeast-2.amazonaws.com/dev/v2/maintenance/workorder/'+wo.Work_Order_No__c+'/cost';
                String endpoint = endpointStr.replace('{workOrderNumber}',wo.Work_Order_No__c);
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
    
    /**
	* Author : Sahil Wadhwa    
	* Date : 14/06/2022
    * Updated By: Bohao Chen @IBM using generateOutboundIntegrationEvents to generate platform events
    * Update Date: 4/10/2022    
	* Description : Call the planned work order to EAM integration
	**/
    // public static void callPlannedWorkOrderToEAMIntegration (Map<Id, WorkOrder> newPlannedWorkOrdersMap) {
    public static void callWorkOrderToEAMIntegration (Map<Id, WorkOrder> newWorkOrdersMap) {
        try {
            List<Outbound_Integration__e> platformEvents = new List<Outbound_Integration__e>();
            String endpoint = 'New_Work_Order';
            platformEvents.addAll(MSN_IntegrationUtility.generateOutboundIntegrationEvents(newWorkOrdersMap, 'WorkOrder', 
                new Map<String, List<String>>{endpoint => new String[]{'New_Work_Order'}}));

            // publish platform events
            if(!platformEvents.isEmpty()) {
                Id jobId = System.enqueueJob(new MSN_Integration(platformEvents, newWorkOrdersMap.values()));
                MSN_Integration.integrationQueued = true;
            }
        }catch(Exception e){
            MSN_HandleErrorsException.insertLogException(e, '', '');
        }
    }
    
    /**
	* Author : Bohao Chen
	* Date : 12/10/2022
	* Description : send child work orders to EAM integration
	**/
    public static void callChildWorkOrderToIntegration(Map<Id, WorkOrder> childWorkOrdersMap) {
        try {
            List<Outbound_Integration__e> platformEvents = new List<Outbound_Integration__e>();
            String endpoint = 'New_Child_Work_Order';
            platformEvents.addAll(MSN_IntegrationUtility.generateOutboundIntegrationEvents(childWorkOrdersMap, 'WorkOrder', 
                new Map<String, List<String>>{endpoint => new String[]{'Create_Child_Work_Order'}}));

            // publish platform events
            if(!platformEvents.isEmpty()) {
                Id jobId = System.enqueueJob(new MSN_Integration(platformEvents));
                MSN_Integration.integrationQueued = true;
            }
        }catch(Exception e){
            MSN_HandleErrorsException.insertLogException(e, '', '');
        }
    }
        
    public static void callCompletedChildWorkOrderToIntegration(List<WorkOrder> childWorkOrders, Map<Id, SObject> triggerWorkOrdersMap) {
        System.debug('We are in complete child work order ');

        Map<Id,List<WorkStep>> woIdToWorkStepList = findWorkSteps(childWorkOrders);
        
        // TODO: future improvement: 
        // Currenlty MSN_IntegrationUtility.generateOutboundIntegrationEvents can't handle any payload with a list inside
        // therefore, for any payload with lists, we cannot use MSN_IntegrationUtility.generateOutboundIntegrationEvents to
        // generate platform events
        List<sObject> createEventList = new List<sObject>();    
        Integration_Endpoint__mdt endpointSetting = MSN_Utility.getEndpointSetting('New_Child_Work_Order');

        if(endpointSetting != null) {
            String endpointStr = endpointSetting.Endpoint__c;

            String method = 'PUT';
            try {
                for(WorkOrder wo : childWorkOrders) {
                    List<WorkStep> costList = woIdToWorkStepList.get(wo.Id);
                    String payload = createCompleteChildWorkOrderToEAMPlayload(costList, wo);
                    
                    System.debug('@callCompletedChildWorkOrderToIntegration payload' + payload);
                    //String endpoint = 'https://9fa04kq7a0.execute-api.ap-southeast-2.amazonaws.com/dev/v2/maintenance/pmworkorder/'+wo.Work_Order_No__c;
                    String endpoint = endpointStr.replace('{workOrderNumber}',wo.Work_Order_No__c);
                    Outbound_Integration__e platformEvent = new Outbound_Integration__e();
                    platformEvent.EndPoint__c = endpoint;
                    platformEvent.Method__c = method;
                    platformEvent.Payload__c = payload;
                    createEventList.add(platformEvent);
                }
                
                // Publishing the events
                Boolean eventCreation = MSN_GenericPlatformEventUtility.publishEvents(createEventList);
            } catch(Exception e){
                MSN_HandleErrorsException.insertLogException(e, '', '');
                throw new MSN_Utility.CustomException(e.getMessage());
            }
        }
    }
        
    /**
	* Author : Sahil Wadhwa
    * Updated By: Bohao Chen
    * Updated On: 17/10/2022
	* Date : 21/06/2022
	* Description : Create the payload for completed child work order to EAM
	**/
    public static string createCompleteChildWorkOrderToEAMPlayload(List<WorkStep> workSteps, Workorder wo) {

        String payload = '{';
        payload += '"TransactionID": "eventId",';
        payload += '"ContractorReference": "' + wo.WorkOrderNumber + '",';
        // payload += '"WorkOrderNo" : "' + wo.Work_Order_No__c + '",';
        payload += '"WorkOrderNo" : "' + wo.RootWorkOrder.Work_Order_No__c + '",';
        payload += '"ContractorCode": "MSN",';
        payload += '"Asset" : {';
        payload += '"AssetKey": ' + wo.Asset.Comp_Key__c;
        // payload += '"AssetTypeCode": "",';
        // payload += '"AssetName": ""';
        payload += '},';
        // TODO: acitivity code for child work order is under analysis
        // JIRA ticke https://watercarestp.atlassian.net/browse/MSRS-2385
        payload += '"ActivityCode": "' + wo.WorkType.MSN_ActivityCode__c + '",'; 
        payload += '"AssetCondition": "2",';
        payload += '"Comments": "' + wo.Description + '",';
        payload += '"Crew": "MSN",';
        payload += '"InitiatedDate": "' + wo.CreatedDate.format('yyyy-MM-dd\'T\'HH:mm:ss.sss',Userinfo.getTimeZone().toString()) + '",';
        payload += '"StartDate": "' + wo.StartDate.format('yyyy-MM-dd\'T\'HH:mm:ss.sss',Userinfo.getTimeZone().toString())+ '",';
        payload += '"CompletedDate": "' + wo.EndDate.format('yyyy-MM-dd\'T\'HH:mm:ss.sss',Userinfo.getTimeZone().toString())+ '",';
        payload += '"CompletedBy": "MSN",'; 
        payload += '"ResultCode": "COMP",';
        payload += '"VariationNo": "",';
        payload += '"TransactionType":"FM",';

        payload += '"Observations": [';
        if(workSteps != null && !workSteps.isEmpty()) {
            for(WorkStep ws : workSteps) {
                String value = String.isNotBlank(ws.MSN_WorkStep_Answer__c) ? ws.MSN_WorkStep_Answer__c.replaceAll('\n', ' ') : '';
                payload += '{';
                payload += '"Code": "' + ws.MSN_SPOT_Code__c + '",';
                // payload += '"Description": "' + ws.Description + '",';
                payload += '"Value": "' + value + '",';
                payload += '"Date": "' + ws.LastModifiedDate.format('yyyy-MM-dd\'T\'HH:mm:ss.sss',Userinfo.getTimeZone().toString()) + '",';
                payload += '"Detail": "' + ws.Description + '"';
                // payload += '"UoM": "' + ' ' + '"';
                payload += '},';
            }
        }
        // because "Observations" is required in the payload. need some dummy at the absence of spot code questions
        else {
            payload += '{"Code": "dummy"}';
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
    
    private static Map<Id,List<WorkStep>> findWorkSteps(List<WorkOrder> completeWorkOrderList) {

        Set<Id> workOrderIdSet = new Set<Id>();
        Map<Id,List<WorkStep>> woIdToWorkStepList = new Map<Id,List<WorkStep>>();
        List<sObject> createEventList = new List<sObject>();    
        
        // Loop through wo order to form the Id set
        // for(WorkOrder wo : completeWorkOrderList) {
        //     workOrderIdSet.add(wo.Id);
        // }
        
        List<WorkStep> workStepList = [SELECT Id,WorkOrderId,MSN_ScheduleItem_Code__c,MSN_SPOT_Code__c,
                                            Description,MSN_WorkStep_Answer__c,LastModifiedDate 
                                        FROM WorkStep 
                                        // WHERE WorkOrderId in :workOrderIdSet 
                                        WHERE WorkOrderId in :completeWorkOrderList 
                                        AND MSN_Answer_Type__c != 'Schedule Item Code'];
        
        // Form the work order id to work step list
        for(WorkStep step:workStepList) {
            System.debug('step: '+step);
            if(!woIdToWorkStepList.containsKey(step.WorkOrderId)) {
                List<WorkStep> stepList = new List<WorkStep>();
                stepList.add(step);
                woIdToWorkStepList.put(step.WorkOrderId,stepList);
            }
            else { 
                List<WorkStep> stepList = woIdToWorkStepList.get(step.WorkOrderId);
                stepList.add(step);
            	woIdToWorkStepList.put(step.WorkOrderId,stepList);
            } 
            System.debug('woIdToWorkStepList : '+woIdToWorkStepList);
        }

        return woIdToWorkStepList;
    }
}