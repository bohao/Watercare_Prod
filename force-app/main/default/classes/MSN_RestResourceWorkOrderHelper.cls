/**
 * @File Name          : MSN_RestResourceWorkOrderHelper.cls
 * @Description        : Helper to create WO from API POST calls
 * @Author             : David Azzi
 * @Group              : 
 * @Last Modified By   : David Azzi
 * @Last Modified On   : 23/11/2021
 * @Modification Log   : 
 * Ver      Date            Author                  Modification
 * 1.0      23/11/2021      David Azzi              Initial Version
**/
public with sharing class MSN_RestResourceWorkOrderHelper {

    @testVisible
    String receivedJsonString;
    static Map<String, String> bulkifiedWorkTypes;
    static Map<String, String> bulkifiedServiceTerritory;
    Boolean isTest = false;
    String workOrderType;
    public static final String PAYLOAD_PARSING_ERROR = 'Couldn\'t parse the payload. {0}';
    public static final String TYPE_CONVERSION_ERROR = 'Couldn\'t convert the value in the payload to the expected type. {0}';
    static final String PLANNED_WO_QUEUE = 'Planned_Meter_Queue';
    static final String SEEK_SUPPORT = 'Please provide a valid value for {0} or contact your Salesforce administrator.';

    public static List<Id> createWorkOrder(String json, String workOrderType){

        System.debug('Created PLanned Maintenance');

        MSN_PlannedMaintenanceWrapper msnPlannedWo;
        MSN_ReactiveMaintenanceWrapper msnReactiveWo;
        String assetName;
        String assetKey;
        String onSiteDueDateString;
        String scheduledDateString;
        String callDateString;

        Integer priority;

        if(workOrderType.equalsIgnoreCase('Planned Maintenance')) {
            msnPlannedWo = (MSN_PlannedMaintenanceWrapper) System.JSON.deserialize(json, MSN_PlannedMaintenanceWrapper.class);
            assetName = msnPlannedWo.Asset.AssetName;
            assetKey = msnPlannedWo.Asset.AssetKey;
            onSiteDueDateString = msnPlannedWo.OnsiteDueDate;
            scheduledDateString = msnPlannedWo.ScheduledDate;
            priority = Integer.valueOf(msnPlannedWo.Priority.right(1));
        }
        else if(workOrderType.equalsIgnoreCase('Reactive Maintenance')) {                
            msnReactiveWo = (MSN_ReactiveMaintenanceWrapper) System.JSON.deserialize(json, MSN_ReactiveMaintenanceWrapper.class);            
            assetName = msnReactiveWo.Asset.AssetName;
            assetKey = msnReactiveWo.Asset.AssetKey;
            onSiteDueDateString = msnReactiveWo.OnsiteDueDate;
            callDateString = msnReactiveWo.CallDetails.CallDate;
            priority = msnReactiveWo.Priority;
        }
        
        bulkifiedWorkTypes = new Map<String, String>();
        bulkifiedServiceTerritory = new Map<String, String>();

        List<QueueSobject> queueSobjects = [SELECT Queue.Id, SobjectType FROM QueueSobject 
                                            WHERE Queue.DeveloperName = :PLANNED_WO_QUEUE 
                                            AND Queue.Type='Queue'
                                            AND (SobjectType = 'ServiceAppointment' OR SobjectType = 'WorkOrder')];

        Id woQId, saQId;

        for(QueueSobject queueSobject : queueSobjects) {
            if(queueSobject.SobjectType == 'ServiceAppointment') {
                saQId = queueSobject.Queue.Id;
            }
            else if(queueSobject.SobjectType == 'WorkOrder') {
                woQId = queueSobject.Queue.Id;
            }
        }

        if(woQId == null) {
            throw new MSN_Utility.CustomException('Couldn\'t find the queue \'' + PLANNED_WO_QUEUE + 
            '\' with \'WorkOrder\' sObjectType in Salesforce. Please contact your Salesforce administrator.');
        }
        if(saQId == null) {
            throw new MSN_Utility.CustomException('Couldn\'t find the queue \'' + PLANNED_WO_QUEUE + 
            '\' with \'ServiceAppointment\' sObjectType in Salesforce. Please contact your Salesforce administrator.');
        }

        // Id woQId = (qIds[0].SobjectType == 'WorkOrder') ? qIds[0].Queue.Id : qIds[1].Queue.Id;
        // Id saQId = (qIds[0].SobjectType == 'ServiceAppointment') ? qIds[0].Queue.Id : qIds[1].Queue.Id;
        
        List<Asset> sfAssets = [SELECT Name, Asset_Type__c, Comp_Key__c, House_Number__c, Street_Name__c, 
                                       Street_Type__c, Suburb__c, Flat__c
                                FROM Asset 
                                WHERE Name =: assetName OR Comp_Key__c =: assetKey];

        List<WorkOrder> sfWOs = new List<WorkOrder>();
        List<Id> woIds = new List<Id>(); //changed to list for String.join

        if(workOrderType.equalsIgnoreCase('Planned Maintenance')) {
            sfWOs.add(createPlannedWorkOrder(msnPlannedWo, woQId, sfAssets));
        }
        else if(workOrderType.equalsIgnoreCase('Reactive Maintenance')) {
            sfWOs.add(createReactiveWorkOrder(msnReactiveWo, woQId, sfAssets));
        }

        System.debug(sfWOs);

        if ( sfWOs != null ){
            String errorMsg = '';
            Database.UpsertResult[] woSR = Database.upsert(sfWOs);
            Map<Id, List<Database.Error>> woIdInsertErrors = new Map<id, List<Database.Error>>();
            for (Database.UpsertResult sr : woSR ){
                if ( sr.isSuccess() ){
                    woIds.add(sr.getId());
                } else {                        
                    woIdInsertErrors.put( sr.getId(), sr.getErrors());
                    for(Database.Error e : sr.getErrors()) {
                        errorMsg += e.getMessage() + '. ';
                    }
                }
            }
            if ( woIdInsertErrors.size() > 0 ){
                throw new MSN_Utility.CustomException('Couldn\'t create work order(s). Error message:  \'' + errorMsg + '\'. Please contact your Salesforce administrator.');
            }
        }

        if ( woIds.size() > 0 ){
            //Create WOLIs
            List<WorkOrderLineItem> sfWOLIs = new List<WorkOrderLineItem>();
            List<ServiceAppointment> sfSAs = new List<ServiceAppointment>();

            try {
                Map<Id, ServiceAppointment> parentIdServiceAppointment = new Map<Id, ServiceAppointment>();
                for (ServiceAppointment sa : [SELECT Id, Street, City, Country, ParentRecordId, FSSK__FSK_Work_Order__c, ServiceTerritoryId, SideOfStreet__c, DueDate 
                                            FROM ServiceAppointment 
                                            WHERE ParentRecordId IN: woIds]){
                    parentIdServiceAppointment.put(sa.ParentRecordId, sa);
                }

                // MSRS-2175
                Map<Id, WorkOrderLineItem> parentIdWorkOrderLineItem = new Map<Id, WorkOrderLineItem>();
                for (WorkOrderLineItem woli : [SELECT Id, WorkOrderId
                                            FROM WorkOrderLineItem 
                                            WHERE WorkOrderId IN: woIds]){
                    parentIdWorkOrderLineItem.put(woli.WorkOrderId, woli);
                }
                
                Set<Id> stIds = new Set<Id>();
                for(WorkOrder sfWO : sfWOs){

                    ServiceAppointment sa = createServiceAppointment(sfWO, parentIdServiceAppointment.get(sfWO.Id), 
                                                saQId, onSiteDueDateString, priority, workOrderType, scheduledDateString, callDateString);

                    stIds.add(sa.ServiceTerritoryId);
                    sfSAs.add(sa);                    
                }

                if ( sfSAs.size() > 0 ){
                    System.debug('**sfSA: ' + sfSAs);

                    // lock SA records to avoid "UNABLE_TO_LOCK_ROW" issue on ServiceTerritory
                    List<ServiceTerritory> sts = [SELECT Id FROM ServiceTerritory WHERE Id IN: stIds FOR UPDATE];

                    Database.UpsertResult[] srSAs = Database.upsert(sfSAs);
                    Map<Id, List<Database.Error>> saIdUpsertErrors = new Map<id, List<Database.Error>>();
                    String errorMsg = '';
                    for (Database.UpsertResult sr : srSAs ){
                        if ( !sr.isSuccess() ){
                            saIdUpsertErrors.put( sr.getId(), sr.getErrors());
                            for(Database.Error e : sr.getErrors()) {
                                errorMsg += e.getMessage() + '. ';
                            }
                        }
                    } 
                    if ( saIdUpsertErrors.size() > 0 ){
                        throw new MSN_Utility.CustomException('Couldn\'t create work order(s). Error message:  \'' + errorMsg + '\'. Please contact your Salesforce administrator.');
                    }
                }

            }catch(Exception e){
                throw new MSN_Utility.CustomException(e.getMessage());
            }
        }

        System.debug('END');
        
        return woIds;
    }

    public static WorkOrder createPlannedWorkOrder(MSN_PlannedMaintenanceWrapper msnWO, Id woQId, List<Asset> sfAssets) {
        Workorder wo = new WorkOrder();

        // Assume there is just one asset per work order coming from EAM
        if(!sfAssets.isEmpty()) {
            wo.AssetId = sfAssets[0].Id;
        }
        
        wo.MSN_Due_Date__c = String.isNotBlank(msnWO.OnsiteDueDate) ? MSN_Utility.convertToDatetime(msnWO.OnsiteDueDate) : null;
        
        wo.Flat__c = String.isBlank(msnWO.CallDetails.RequestorInfo.ContactDetails.Address.FlatNo) && !sfAssets.isEmpty() ? 
                     sfAssets[0].Flat__c : msnWO.CallDetails.RequestorInfo.ContactDetails.Address.FlatNo;
        

        wo.Street = String.isBlank(msnWO.CallDetails.RequestorInfo.ContactDetails.Address.StreetNo) && !sfAssets.isEmpty() ?
                    sfAssets[0].Street_Name__c + ' ' + sfAssets[0].Street_Type__c :
                    msnWO.CallDetails.RequestorInfo.ContactDetails.Address.StreetNo + ' ' + msnWO.CallDetails.RequestorInfo.ContactDetails.Address.StreetName;

        wo.PostalCode = msnWO.CallDetails.RequestorInfo.ContactDetails.Address.Postcode;

        wo.City = String.isBlank(msnWO.CallDetails.RequestorInfo.ContactDetails.Address.Suburb) && !sfAssets.isEmpty() ? 
                    sfAssets[0].Suburb__c :
                    msnWO.CallDetails.RequestorInfo.ContactDetails.Address.Suburb;

        wo.Country = String.isBlank(msnWO.CallDetails.RequestorInfo.ContactDetails.Address.Country) ? 
                    'New Zealand' :
                    msnWO.CallDetails.RequestorInfo.ContactDetails.Address.Country;

        wo.Priority = (msnWO.Priority.isNumeric()) ? 'P' + msnWO.Priority : msnWO.Priority;
        wo.Description = msnWO.Comments;
        wo.Group_Number__c = msnWO.GroupNo;
        wo.Transaction_ID__c = msnWO.TransactionId;
        wo.MSN_Contract__c = msnWO.Contract;
        wo.Variation_Number__c = msnWO.VariationNo; 
        wo.Activity_Instructions__c = msnWO.ActivityInstructions;
        wo.Subject = msnWO.ActivityDescription;        
        wo.Watercare_Engineer__c = msnWO.InitiatedBy;
        wo.OwnerId = woQId;
        wo.Work_Order_No__c = msnWO.WorkOrderNo;
        wo.Required_End_Date__c = String.isNotBlank(msnWO.OnsiteDueDate) ? MSN_Utility.convertToDatetime(msnWO.OnsiteDueDate) : null;

        // find the existing work orders based on msnWO.WorkOrderNo
        // if existing work order found, assign id to the new work order so that it won't create a new work order
        for(WorkOrder existingWork : [SELECT Id FROM WorkOrder WHERE Work_Order_No__c =: msnWO.WorkOrderNo]) {
            wo.Id = existingWork.Id;
        }

        try {            
            ServiceTerritory st = [SELECT Id FROM ServiceTerritory WHERE Name =: msnWO.ContractorArea LIMIT 1];
            wo.ServiceTerritoryId = st.Id;
        }
        catch(QueryException e) {
            String msg;
            if(String.isBlank(msnWO.ContractorArea)) {
                msg = 'Couldn\'t find the Service Territory record when ContractorArea is blank in the payload. Please provide a value for ContractorArea. ';
            }
            else {
                msg = String.format('Couldn\'t find the Service Territory based on ContractorArea in the payload. ' + SEEK_SUPPORT, new String[]{'ContractorArea'});
            }
            throw new MSN_Utility.CustomException(msg);
        }

        try {
            WorkType wt = [SELECT Id FROM WorkType WHERE (Name =: msnWO.ActivityDescription) 
                            OR (MSN_ActivityCode__c =: msnWO.ActivityCode) LIMIT 1];            
            wo.WorkTypeId = wt.Id;
        } 
        catch(QueryException e) {
            String msg = String.format('Couldn\'t find the Work Type based on \'ActivityDescription\' or \'ActivityCode\' in the payload. ' + SEEK_SUPPORT, new String[]{'ActivityDescription or ActivityCode'});
            throw new MSN_Utility.CustomException(msg);
        }
        
        return wo;
    }

    public static WorkOrder createReactiveWorkOrder(MSN_ReactiveMaintenanceWrapper msnWO, Id woQId, List<Asset> sfAssets) {
        Workorder wo = new WorkOrder();

        wo.MSN_Service_Restored_Due_Date__c = String.isNotBlank(msnWO.RestoreServiceDueDate) ? MSN_Utility.convertToDatetime(msnWO.RestoreServiceDueDate) : null;
        
        // Assume there is just one asset per work order coming from EAM
        if(!sfAssets.isEmpty()) {
            wo.AssetId = sfAssets[0].Id;
        }

        wo.Flat__c = String.isBlank(msnWO.Address.FlatNo) && !sfAssets.isEmpty() ? 
                     sfAssets[0].Flat__c : msnWO.Address.FlatNo;
        

        wo.Street = String.isBlank(msnWO.Address.StreetNo) && !sfAssets.isEmpty() ?
                    sfAssets[0].Street_Name__c + ' ' + sfAssets[0].Street_Type__c :
                    msnWO.Address.StreetNo + ' ' + msnWO.Address.StreetName;
        
        wo.PostalCode = msnWO.Address.Postcode;
        wo.City = String.isBlank(msnWO.Address.Suburb) && !sfAssets.isEmpty() ? sfAssets[0].Suburb__c : msnWO.Address.Suburb;
        wo.Country = String.isBlank(msnWO.Address.Country) ? 'New Zealand' : msnWO.Address.Country;

        wo.Priority = 'P' + msnWO.Priority;
        wo.Description = msnWO.Comments;
        wo.Transaction_ID__c = msnWO.TransactionId;
        wo.MSN_Contract__c = msnWO.Contract;
        wo.Subject = msnWO.ProblemDescription;        
        wo.OwnerId = woQId;
        wo.Work_Order_No__c = msnWO.WorkOrderNo;
        wo.MSN_Due_Date__c = String.isNotBlank(msnWO.OnsiteDueDate) ? MSN_Utility.convertToDatetime(msnWO.OnsiteDueDate) : null;        
        wo.Required_End_Date__c = String.isNotBlank(msnWO.CompletionDueDate) ? MSN_Utility.convertToDatetime(msnWO.CompletionDueDate) : null;

        // find the existing work orders based on msnWO.WorkOrderNo
        // if existing work order found, assign id to the new work order so that it won't create a new work order
        for(WorkOrder existingWork : [SELECT Id FROM WorkOrder WHERE Work_Order_No__c =: msnWO.WorkOrderNo]) {
            wo.Id = existingWork.Id;
        }
            
        try {  
            ServiceTerritory st = [SELECT Id FROM ServiceTerritory WHERE Name =: msnWO.ContractorArea LIMIT 1];
            wo.ServiceTerritoryId = st.Id;
        }
        catch(QueryException e) {
            String msg;
            if(String.isBlank(msnWO.ContractorArea)) {
                msg = 'Couldn\'t find the Service Territory record in Salesforce when ContractorArea is blank in the payload. Please provide a value for ContractorArea. ';
            }
            else {
                msg = String.format('Couldn\'t find the Service Territory record in Salesforce based on ContractorArea in the payload. ' + SEEK_SUPPORT, new String[]{'ContractorArea'});
            }
            throw new MSN_Utility.CustomException(msg);
        }

        try {
            // MSRS-2291
            WorkType wt = [SELECT Id 
                           FROM WorkType 
                           WHERE MSN_Problem_Code__c =: msnWO.ProblemCode LIMIT 1];

            wo.WorkTypeId = wt.Id;
        } 
        catch(QueryException e) {
            String msg;
            if(String.isBlank(msnWO.ProblemCode)) {
                msg = 'Couldn\'t find the Work Type record in Salesforce when ProblemCode is blank in the payload. Please provide a value for ProblemCode. ';
            }
            else {
                msg = String.format('Couldn\'t find the Work Type record in Salesforce based on ProblemCode in the payload. ' + SEEK_SUPPORT, new String[]{'ProblemCode'});
            }
            throw new MSN_Utility.CustomException(msg);
        }
        
        // new mappings (need to check with Andrew Swain and decide if we need to display them on the page layout)
        wo.MSN_Contact_Phone__c = msnWO.CallDetails.RequestorInfo.ContactDetails.PhoneNo;
        wo.MSN_Contact_Email__c = msnWO.CallDetails.RequestorInfo.ContactDetails.Email;
        wo.MSN_Contact_First_Name__c = msnWO.CallDetails.RequestorInfo.IndividualName.FirstName;
        wo.MSN_Contact_Last_Name__c = msnWO.CallDetails.RequestorInfo.IndividualName.LastName;
        wo.MSN_Taken_By__c = msnWO.CallDetails.CallTakenBy;
        wo.MSN_Fault_Location__c = msnWO.Location;
        wo.MSN_Contact_Requestor__c = Boolean.valueOf(msnWO.ContactRequestor);

        return wo;
    }

    public static ServiceAppointment createServiceAppointment(WorkOrder sfWO, ServiceAppointment sas, Id saQId,
        String onSiteDueDateString, Integer priority, String workOrderType, String scheduledDateString, String callDateString) {

        ServiceAppointment newSA = (sas != null ? sas : new ServiceAppointment() );

        try{
            newSA.Flat__c = sfWO.Flat__c;
            newSA.Street = sfWO.Street;
            newSA.PostalCode = sfWO.PostalCode;
            newSA.City = sfWO.City;
            newSA.Country = sfWO.Country;
                    
            // The parent record can’t be updated after the service appointment is created.
            if(newSA.Id == null) {
                newSA.ParentRecordId = sfWO.Id;
            }

            newSA.FSSK__FSK_Work_Order__c = sfWO.Id;        
            newSA.ServiceTerritoryId = sfWO.ServiceTerritoryId;
            newSA.SideOfStreet__c = MSN_Utility.OddsOrEvens(sfWO.Street);

            // MSRS-2164     
            // if planned wo, the Earliest Start Permitted needs to be populated with the scheduled date
            if(workOrderType.equalsIgnoreCase('Planned Maintenance')) {
                newSA.EarliestStartTime = String.isNotBlank(scheduledDateString) ? MSN_Utility.convertToDatetime(scheduledDateString) : null;
            }
            else if(workOrderType.equalsIgnoreCase('Reactive Maintenance')) {
                newSA.EarliestStartTime = String.isNotBlank(callDateString) ? MSN_Utility.convertToDatetime(callDateString) : null;
            }
            
            Datetime onSiteDueDatetime = String.isNotBlank(onSiteDueDateString) ? MSN_Utility.convertToDatetime(onSiteDueDateString) : null;
            newSA.DueDate = onSiteDueDatetime;
            newSA.Inline_Due_Date__c = Date.valueOf(onSiteDueDateString);
            newSA.MSN_Original_Due_Date__c = onSiteDueDatetime;
            newSA.Priority__c = sfWO.Priority;
            newSA.Subject = sfWO.Subject;
            newSA.OwnerId = saQId;
            newSA.FSL__Schedule_over_lower_priority_appointment__c = false;
            newSA.FSL__Schedule_over_lower_priority_appointment__c = priority > 2;
            
        }catch(Exception e){
            throw new MSN_Utility.CustomException(e.getMessage() + ' Please contact your Salesforce administrator.');
        }
                
        return newSA;
    }

}