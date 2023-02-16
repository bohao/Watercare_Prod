/**
	* Author : Ashwini Patil
	* Date : 15/08/2022
	* Description : Test class to cover work order trigger, work order helper class and handler class
	**/

@isTest 
public class MSN_WorkOrderTrigger_Test {
    
	@isTest
    public static void insertmethod() {   
        //Create asset record
    	Asset asset = new Asset(Name = 'Water Meter-458800-A06A138755 18-26 Wellesley ST-E Auckland Central');
    	insert asset;
    
        //Create ServiceTerritory record
    	ServiceTerritory st = (ServiceTerritory)TestDataFactory.createSObject('ServiceTerritory', new Map<String,Object>{
            'IsActive' => true
        });
        
        Id msnWorkOrderRtId = Schema.SObjectType.WorkOrder.getRecordTypeInfosByName().get('MSN').getRecordTypeId();

        //Create WorkType record
    	WorkType wt = new WorkType(Name = 'Watermeter - Planned Replacement', DurationType = 'Minutes', EstimatedDuration = 40 );
        insert wt;
    
        //Create WorkOrder record
    	WorkOrder wo = new WorkOrder(Transaction_ID__c = '0800052712', Work_Order_No__c = '20035223', ServiceTerritoryId = st.Id, 
                                     WorkTypeId = wt.Id, Contractor_Area__c = 'METRO', Subject = 'Replace the water meters as instructed',
                                     AssetId = asset.Id, Street = '44 Meadowbank Road', PostalCode = '1072', Country = 'New Zealand', City = 'Auckland',
                                     Priority = '7', RecordTypeId = msnWorkOrderRtId);
        insert wo;
        
        
        //Create ServiceAppointment record
        ServiceAppointment sa = new ServiceAppointment(ParentRecordId = wo.Id, Status = 'New', Street = wo.Street, PostalCode = wo.PostalCode, 
                                                       Country = wo.Country, City = wo.City, Priority__c = wo.Priority,
                                                       ServiceTerritoryId = wo.ServiceTerritoryId);
        insert sa;
        
		 
        //Create WorkOrderLineItem record
        WorkOrderLineItem woli = new WorkOrderLineItem(WorkOrderId = wo.Id, Status = 'New', Street = wo.Street, PostalCode = wo.PostalCode, 
                                                       Country = wo.Country, City = wo.City, WorkTypeId = wt.Id, AssetId = asset.Id, 
                                                       Subject = 'PLANNED METER REPLACEMENT', Description = 'MSN EAM SFS WMTPMR Test' );
        
    }  
    
}