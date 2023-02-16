/**
 * @File Name          : MSN_ProductConsumedTriggerHelper.cls
 * @Description        : Trigger helper for Parts and Labor trigger handler
 * @Author             : Sahil Wadhwa
 * @Modification Log   : 
 * Ver      Date            Author                  Modification
 * 1.0      11/05/2022      Sahil Wadhwa             Initial Version
**/
public class MSN_ProductConsumedTriggerHelper {
    public static void createOutboundIntegration(Map<Id, ProductConsumed> newProductConsumedList, Map<Id, ProductConsumed> oldProductConsumedList) {
        
        List<sObject> createEventList = new List<sObject>();
        Set<Id> workOrderIdSet = new Set<Id>();
        // Map<Id,Id> laboutIdTowoIdMap = new Map<Id,Id>();

        List<ProductConsumed> labourList = new List<ProductConsumed>();
        List<ProductConsumed> partsList = new List<ProductConsumed>();

        Map<Id, ProductConsumed> laboursMap = new Map<Id, ProductConsumed>();
        Map<Id, ProductConsumed> partsConsumedMap = new Map<Id, ProductConsumed>();
        Map<Id, ProductConsumed> partsReturnedMap = new Map<Id, ProductConsumed>();

        List<ProductConsumed> productConsumedList = Trigger.isDelete ? oldProductConsumedList.values() : newProductConsumedList.values();

        for(ProductConsumed pc : productConsumedList) {
            workOrderIdSet.add(pc.WorkOrderId);
        }

        Map<Id,WorkOrder> workOrderMap = new Map<Id,WorkOrder>(
            [SELECT Id, Work_Order_No__c 
            FROM WorkOrder 
            WHERE Id IN:workOrderIdSet AND Work_Order_No__c != null]
        );

        if(Trigger.isUpdate) {
            for(ProductConsumed productConsumed : newProductConsumedList.values()) {

                if(workOrderMap.containsKey(productConsumed.WorkOrderId)) {

                    ProductConsumed oldProductConsumed = oldProductConsumedList.get(productConsumed.Id);

                    // laboutIdTowoIdMap.put(productConsumed.Id, productConsumed.WorkOrderId);
                
                    if(productConsumed.Is_Part__c) {
                        // for update, if quantity consumed has been updated, part consumed has not been sent to EAM (!productConsumed.Sent_to_EAM__c)
                        // and EAM has sufficent stock (!productConsumed.Not_Sufficient_EAM_Stock__c)
                        System.debug('@compare quantity: ' + productConsumed.QuantityConsumed + '|' + oldProductConsumed.QuantityConsumed);
                        if(!productConsumed.Sent_to_EAM__c && 
                                (productConsumed.QuantityConsumed != oldProductConsumed.QuantityConsumed || 
                                oldProductConsumed.Not_Sufficient_EAM_Stock__c != productConsumed.Not_Sufficient_EAM_Stock__c)
                            && 
                            !productConsumed.Not_Sufficient_EAM_Stock__c) {

                            partsList.add(productConsumed);

                            // consume parts
                            if(productConsumed.QuantityConsumed > productConsumed.Previous_Quantity__c) {
                                partsConsumedMap.put(productConsumed.Id, productConsumed);
                            }
                            // return parts
                            else if(productConsumed.QuantityConsumed < productConsumed.Previous_Quantity__c) {
                                partsReturnedMap.put(productConsumed.Id, productConsumed);
                            }
                        }
                    }
                    else {
                        labourList.add(productConsumed);
                        laboursMap.put(productConsumed.Id, productConsumed);
                    }
                }
            }
        }
        else if(Trigger.isInsert) {
            for(ProductConsumed productConsumed : newProductConsumedList.values()) {
                
                if(workOrderMap.containsKey(productConsumed.WorkOrderId)) {
                    // laboutIdTowoIdMap.put(productConsumed.Id,productConsumed.WorkOrderId);
        
                    System.debug('@ProductItem: ' + productConsumed.ProductItemId);

                    if(productConsumed.Is_Part__c) {
                        if(!productConsumed.Sent_to_EAM__c && !productConsumed.Not_Sufficient_EAM_Stock__c) {
                            partsList.add(productConsumed);
                            partsConsumedMap.put(productConsumed.Id, productConsumed);
                        }
                    }
                    else {
                        labourList.add(productConsumed);
                        laboursMap.put(productConsumed.Id, productConsumed);
                    }
                }
            }
        }

        else if(Trigger.isDelete) {
            for(ProductConsumed productConsumed : oldProductConsumedList.values()) {
                
                if(workOrderMap.containsKey(productConsumed.WorkOrderId)) {

                    // laboutIdTowoIdMap.put(productConsumed.Id,productConsumed.WorkOrderId);
        
                    if(productConsumed.Is_Part__c) {
                        if(productConsumed.Sent_to_EAM__c) {
                            partsList.add(productConsumed);
                            partsReturnedMap.put(productConsumed.Id, productConsumed);
                        }
                    }
                    else {
                        labourList.add(productConsumed);
                        laboursMap.put(productConsumed.Id, productConsumed);
                    }
                }
            }
        }

        System.debug('@partsList: ' + partsList);
        System.debug('@labourList: ' + labourList);
        System.debug('@laboursMap: ' + laboursMap);                
        System.debug('@partsConsumedMap: ' + partsConsumedMap);
        System.debug('@partsReturnedMap: ' + partsReturnedMap);

        // ======= new way of creating platform event ==========
        List<Outbound_Integration__e> platformEvents = new List<Outbound_Integration__e>();

        String partsEndpoint = 'Parts_Integration';
        String laborsEndpoint = 'Labour_Integration';

        Map<String, List<String>> endpointAndPayloadsApiNameMap = new Map<String, List<String>>();        
        // the first argument should be the dev/API name of the endpoint 
        //  in "Integration Payloads" custom metadata setting (without the instance name as suffix)
        // the second argument should be a list of payloads which are calling the same endpoint

        // consume labours
        if(!laboursMap.isEmpty()) {
            platformEvents.addAll(MSN_IntegrationUtility.generateOutboundIntegrationEvents(laboursMap, 'ProductConsumed', 
                new Map<String, List<String>>{laborsEndpoint => new String[]{'Work_Order_Labour_Booking'}}));
        }

        // consume parts            
        if(!partsConsumedMap.isEmpty()) {
            platformEvents.addAll(MSN_IntegrationUtility.generateOutboundIntegrationEvents(partsConsumedMap, 'ProductConsumed', 
                new Map<String, List<String>>{partsEndpoint => new String[]{'Work_Order_Part_Booking'}}));
        }

        // return parts
        if(!partsReturnedMap.isEmpty()) {
            // return parts due to the deletion of part consumed records
            if(Trigger.isDelete) {
                platformEvents.addAll(MSN_IntegrationUtility.generateOutboundIntegrationEvents(partsReturnedMap, 'ProductConsumed', 
                    new Map<String, List<String>>{partsEndpoint => new String[]{'Work_Order_Part_Delete'}}));
            }
            // return parts due to replenishment
            else {
                platformEvents.addAll(MSN_IntegrationUtility.generateOutboundIntegrationEvents(partsReturnedMap, 'ProductConsumed', 
                    new Map<String, List<String>>{partsEndpoint => new String[]{'Work_Order_Part_Replenish'}}));
            }
        }   

        // publish platform events
        if(!platformEvents.isEmpty()) {
            Id jobId = System.enqueueJob(new MSN_Integration(platformEvents, partsList));
            MSN_Integration.integrationQueued = true;
        }

        // ============  old way of creating platform event (To Be Deleted) =============
        /*String partsEndpoint,laborEndpoint;
        List<Integration_Endpoint__mdt> integrationEndpoints = Integration_Endpoint__mdt.getAll().values();
        for(Integration_Endpoint__mdt endpoint:integrationEndpoints){
            if(endpoint.Integration_Type__c == 'Parts Integration' && endpoint.Active__c == true) {
                partsEndpoint = endpoint.Endpoint__c.toLowercase();
            }
            if(endpoint.Integration_Type__c == 'Labor Integration' && endpoint.Active__c == true) {
                laborEndpoint = endpoint.Endpoint__c.toLowercase();
            }
        }
        
        // Looping through each labour to create a platform event
        for(ProductConsumed labour:labourList) {
        	String payload = createLabourPayload(labour,laboutIdTowoIdMap,workOrderMap);
            String endpoint = laborEndpoint.replace('{workordernumber}', workOrderMap.get(laboutIdTowoIdMap.get(labour.Id)).Work_Order_No__c);
            // here insert the platform event with the info
            Outbound_Integration__e platformEvent = new Outbound_Integration__e();
            platformEvent.EndPoint__c = endpoint;
            platformEvent.Method__c = method;
            platformEvent.Payload__c = payload;
            createEventList.add(platformEvent);
        }
        
        // Loop through each Part to create a platform event
        /*for(ProductConsumed part:partsList) {
            String payload = createPartPayload(part,laboutIdTowoIdMap,workOrderMap);
            //String endpoint = 'https://9fa04kq7a0.execute-api.ap-southeast-2.amazonaws.com/dev/v2/maintenance/workorder/'+workOrderMap.get(laboutIdTowoIdMap.get(part.Id)).Work_Order_No__c+'/parts';
            System.debug('@partsEndpoint: ' + partsEndpoint);
            System.debug('@workOrderMap: ' + workOrderMap);
            System.debug('@laboutIdTowoIdMap: ' + laboutIdTowoIdMap);
            System.debug('@part: ' + part);

            String endpoint = partsEndpoint.replace('{workordernumber}', workOrderMap.get(laboutIdTowoIdMap.get(part.Id)).Work_Order_No__c);
            // here insert the platform event with the info
            Outbound_Integration__e platformEvent = new Outbound_Integration__e();
            platformEvent.EndPoint__c = endpoint;
            platformEvent.Method__c = method;
            platformEvent.Payload__c = payload;
            createEventList.add(platformEvent);
        }
        
        // Publishing the events
        try {
        	Boolean eventCreation = MSN_GenericPlatformEventUtility.publishEvents(createEventList);

            if(!System.IsBatch() && !System.isFuture()){ 
                List<String> partsConsumedIds = new List<String>();
                for(ProductConsumed part:partsList) {
                    partsConsumedIds.add(part.Id);
                }
                setSentToEamForPartsConsumed(partsConsumedIds);
            }
        } catch(Exception e){
            MSN_HandleErrorsException.insertLogException(e, '', '');
        }*/
    }

    @future
    public static void setSentToEamForPartsConsumed(List<String> partsConsumedIds) {
        List<ProductConsumed> partsList = [SELECT Sent_to_EAM__c FROM ProductConsumed WHERE Id IN: partsConsumedIds];
        for(ProductConsumed part : partsList) {
            part.Sent_to_EAM__c = true;
        }
        if(!partsList.isEmpty()) {
            update partsList;
        }
    }

    /*public static void setSentToEamForPartsConsumed(List<ProductConsumed> partsList) {
        for(ProductConsumed part : partsList) {
            part.Sent_to_EAM__c = true;
        }
        if(!partsList.isEmpty()) {
            update partsList;
        }
    }*/

    /*public static string createLabourPayload(ProductConsumed labour,Map<Id,Id> laboutIdTowoIdMap,Map<Id,WorkOrder> workOrderMap){
        String payload = '{';
        payload = payload + '"TransactionID": "' + '1254875' + '",';
        payload = payload + '"ContractorCode": "' + 'MSN'+ '",';
        payload = payload + '"typeOfHours": "' + labour.MSN_Type_of_Hours__c + '",';
		payload = payload + '"hoursWorked": ' + labour.Hours_Worked__c + ',';
        payload = payload + '"dateWorked": "' + labour.Date_of_the_SA__c + '",';
        payload = payload + '"departmentCode": "' + ''+ '",';
        payload = payload + '"employeeCode": "' + labour.MSN_Employee_Code__c + '",';
        payload = payload + '"employeeDesc": "employeeDesc",';
        payload = payload + '"activityCode": "' + labour.MSN_Activity_Code__c + '",';
        payload = payload + '"tradeCode": "' + labour.MSN_Trade_Code__c + '",';
        payload = payload + '"workOrderNumber": "' + workOrderMap.get(laboutIdTowoIdMap.get(labour.Id)).Work_Order_No__c + '"';
        payload = payload + '}';
        System.debug('@payload: ' + payload);
        return payload;
    }
    
    public static string createPartPayload(ProductConsumed part,Map<Id,Id> laboutIdTowoIdMap,Map<Id,WorkOrder> workOrderMap){
        String payload = '{';
        payload = payload + '"TransactionID": "' + workOrderMap.get(laboutIdTowoIdMap.get(part.Id)).Id + '",';
        payload = payload + '"transactionOn": "' + 'WORKORDER'+ '",';
        payload = payload + '"transactionlines": ' + '[';
        payload = payload + '{' ;
        payload = payload + '"partCode": "' + 'test'+ '",';
        payload = payload + '"bin": "' + 'test'+ '",';
        payload = payload + '"lot": "' + 'test'+ '",';
        // if(context == 'delete') {
        if(Trigger.isDelete) {
            payload = payload + '"transactionQty": -' + part.QuantityConsumed+ '';
        }
        else {
            payload = payload + '"transactionQty": ' + Integer.valueOf(part.QuantityConsumed - part.Previous_Quantity__c) + '';
        }
        
        payload = payload + '}],' ;
        payload = payload + '"WorkOrderNo": "' + workOrderMap.get(laboutIdTowoIdMap.get(part.Id)).Work_Order_No__c + '",';
        payload = payload + '"ContractorCode": "' + 'MSN'+ '",';
        payload = payload + '"storeCode": "' + '1234'+ '",';
        payload = payload + '"date": "' + 'test'+ '",';
        payload = payload + '"transactionType": "' + 'test' + '"';
        payload = payload + '}';

        return payload;
    }*/
    
    public static void updatePreviousQuantity(Map<Id, SObject> newItems,Map<Id, SObject> oldItems) {
        for(Id newItemId : newItems.keySet()) {
			ProductConsumed newProductConsumed = (ProductConsumed)newItems.get(newItemId);
            ProductConsumed oldProductConsumed = (ProductConsumed)oldItems.get(newItemId);

            if(newProductConsumed.Sent_to_EAM__c) {
           	    newProductConsumed.Previous_Quantity__c = oldProductConsumed.QuantityConsumed;
            }
        }
    }

    public static void uncheckSentToEam(Map<Id, SObject> newItems,Map<Id, SObject> oldItems) {
        for(Id newItemId : newItems.keySet()) {
			ProductConsumed newProductConsumed = (ProductConsumed)newItems.get(newItemId);
            ProductConsumed oldProductConsumed = (ProductConsumed)oldItems.get(newItemId);

            if(newProductConsumed.QuantityConsumed != oldProductConsumed.QuantityConsumed) {
                newProductConsumed.Sent_to_EAM__c = false;
            }           	
        }
    }
}