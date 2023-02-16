/**
	* Author : Ashwini Patil
	* Date : 12/08/2022
	* Description : Test class to cover service appointment trigger, service appointment helper class and handler class
	**/

@isTest
public class MSN_ServiceAppointmentTrigger_Test {
    
    
  /*  @isTest
    public static void insertmethod() {   
        
        ServiceTerritory st = (ServiceTerritory)TestDataFactory.createSObject('ServiceTerritory', new Map<String,Object>{
            'IsActive' => true
        });

        WorkType wt = (WorkType)TestDataFactory.createSObject('WorkType');

        // create a sample completed planned work order 
        Id msnWorkOrderRtId = Schema.SObjectType.WorkOrder.getRecordTypeInfosByName().get('MSN').getRecordTypeId();


        WorkOrder wo = (WorkOrder)TestDataFactory.createSObject('WorkOrder', new Map<String,Object>{
            'ServiceTerritoryId' =>  st.Id,
            'WorkTypeId' => wt.Id,
            'Status' => 'New',
            'recordTypeId' => msnWorkOrderRtId,
            'Work_Order_No__c' => 'WO-000008',
            'Street' => '44 Meadowbank Road', 
            'PostalCode' => '1072', 
            'Country' => 'New Zealand', 
            'City' => 'Auckland', 
            'Priority' => '7'
        });
    }*/

    @isTest
    public static void updateWorkOrder() {
        ServiceTerritory st = (ServiceTerritory)TestDataFactory.createSObject('ServiceTerritory', new Map<String,Object>{
            'IsActive' => true
        });

        WorkType wt = (WorkType)TestDataFactory.createSObject('WorkType');

        // create a sample completed planned work order 
        Id msnWorkOrderRtId = Schema.SObjectType.WorkOrder.getRecordTypeInfosByName().get('MSN').getRecordTypeId();


        WorkOrder wo = (WorkOrder)TestDataFactory.createSObject('WorkOrder', new Map<String,Object>{
            'ServiceTerritoryId' =>  st.Id,
            'WorkTypeId' => wt.Id,
            'Status' => 'New',
            'recordTypeId' => msnWorkOrderRtId,
            'Work_Order_No__c' => 'WO-000008',
            'Street' => '44 Meadowbank Road', 
            'PostalCode' => '1072', 
            'Country' => 'New Zealand', 
            'City' => 'Auckland', 
            'Priority' => '7'
        });
        
        
        List<ServiceAppointment> SAList = new List<ServiceAppointment>();
	  	for (integer i=0; i<3; i++) {
		ServiceAppointment SA = new ServiceAppointment(
			ParentRecordId = wo.Id, 
			Status = 'Completed', 
            ServiceTerritoryId = st.Id,
			Subject = 'Planned meter replacement',
            Description = 'Replace the water meter');
		  SAList.add(SA);
	  }
			
	  insert SAList;
        for(ServiceAppointment sap:SAList){
            If(sap.Status == 'Completed') {
          		wo.Status = 'Ready for Review';
          		update wo;
            }
        }
   }        
}