/**
 * @File Name          : MSN_WorkOrderTriggerHelper_Test.cls
 * @Description        : Test class for MSN_WorkOrderTriggerHelper.cls
 * @Author             : Bohao Chen
 * Ver      Date            Author                  Modification
 * 1.0      20/01/2023      Bohao Chen           Initial Version
**/
@isTest
public class MSN_WorkOrderTriggerHelper_Test {
    @TestSetup
    static void testDataSetup() {
        ServiceTerritory st = (ServiceTerritory)TestDataFactory.createSObject('ServiceTerritory', new Map<String,Object>{
            'IsActive' => true
        });

        WorkType wt = (WorkType)TestDataFactory.createSObject('WorkType', new Map<String,Object>{
            'MSN_ActivityCode__c' => 'abcd'
        });

        Asset asset = (Asset)TestDataFactory.createSObject('Asset', new Map<String,Object>{
            'Comp_Key__c' => '555'
        });

        Profile p = [SELECT Id FROM Profile WHERE Name = 'MSN Field Crew'];

        // create a user for service resource
        User user = (User)TestDataFactory.createSObject('User', new Map<String,Object>{
            'ProfileId' => p.Id,
            'Username' => 'test@HGUBHJHGTU.com'
        });
        

        // create service resources for sa
        ServiceResource sr = (ServiceResource)TestDataFactory.createSObject('ServiceResource', new Map<String,Object>{
            'RelatedRecordId' => user.Id,
            'IsActive' => true
        });

        // create new ST member
        ServiceTerritoryMember stm = (ServiceTerritoryMember)TestDataFactory.createSObject('ServiceTerritoryMember', new Map<String,Object>{
            'ServiceResourceId' => sr.Id,
            'ServiceTerritoryId' => st.Id,
            'TerritoryType' => 'P'
        });
    }

    static testMethod void newParentWorkOrderIntegrationTest() {
        ServiceTerritory st = [SELECT Id FROM ServiceTerritory LIMIT 1];
        WorkType wt = [SELECT Id FROM WorkType LIMIT 1];
        
        Id msnWorkOrderRtId = Schema.SObjectType.WorkOrder.getRecordTypeInfosByName().get('MSN').getRecordTypeId();

        Test.startTest();
        
        // create a new work order
        WorkOrder wo = (WorkOrder)TestDataFactory.createSObject('WorkOrder', new Map<String,Object>{
            'ServiceTerritoryId' =>  st.Id,
            'WorkTypeId' => wt.Id,
            'Status' => 'New',
            'recordTypeId' => msnWorkOrderRtId,
            'Work_Order_No__c' => '123456',
            'Street' => '44 Meadowbank Road', 
            'PostalCode' => '1072', 
            'Country' => 'New Zealand', 
            'City' => 'Auckland', 
            'Priority' => '7'
        });

        Test.stopTest();
    }

    static testMethod void newChildWorkOrderIntegrationTest() {
        
        Id msnWorkOrderRtId = Schema.SObjectType.WorkOrder.getRecordTypeInfosByName().get('MSN').getRecordTypeId();
        ServiceTerritory st = [SELECT Id FROM ServiceTerritory LIMIT 1];
        WorkType wt = [SELECT Id FROM WorkType LIMIT 1];
        Asset asset = [SELECT Id FROM Asset LIMIT 1];

        // create a parent work order
        WorkOrder wo1 = (WorkOrder)TestDataFactory.createSObject('WorkOrder', new Map<String,Object>{
            'ServiceTerritoryId' =>  st.Id,
            'WorkTypeId' => wt.Id,
            'Status' => 'New',
            'recordTypeId' => msnWorkOrderRtId,
            'Work_Order_No__c' => '123456',
            'Street' => '44 Meadowbank Road', 
            'PostalCode' => '1072', 
            'Country' => 'New Zealand', 
            'City' => 'Auckland', 
            'Priority' => '7'
        });

        MSN_Integration.integrationQueued = false;
        Test.startTest();
        // Id woId = [SELECT Id FROM WorkOrder LIMIT 1].Id;

        // create a child work order
        WorkOrder wo2 = (WorkOrder)TestDataFactory.createSObject('WorkOrder', new Map<String,Object>{
            'ServiceTerritoryId' =>  st.Id,
            'WorkTypeId' => wt.Id,
            'Status' => 'New',
            'recordTypeId' => msnWorkOrderRtId,
            'Street' => '44 Meadowbank Road', 
            'PostalCode' => '1072', 
            'Country' => 'New Zealand', 
            'City' => 'Auckland', 
            'Priority' => '7',
            'ParentWorkOrderId' => wo1.Id,
            'AssetId' => asset.Id
        });
        Test.stopTest();

    }

    static testMethod void childWorkOrderCostIntegrationTest() {

        Id msnWorkOrderRtId = Schema.SObjectType.WorkOrder.getRecordTypeInfosByName().get('MSN').getRecordTypeId();
        ServiceTerritory st = [SELECT Id FROM ServiceTerritory LIMIT 1];
        WorkType wt = [SELECT Id FROM WorkType LIMIT 1];
        Asset asset = [SELECT Id FROM Asset LIMIT 1];

        MSN_Integration.integrationQueued = true;

        // create a parent work order
        WorkOrder wo1 = (WorkOrder)TestDataFactory.createSObject('WorkOrder', new Map<String,Object>{
            'ServiceTerritoryId' =>  st.Id,
            'WorkTypeId' => wt.Id,
            'Status' => 'New',
            'recordTypeId' => msnWorkOrderRtId,
            'Work_Order_No__c' => '123456',
            'Street' => '44 Meadowbank Road', 
            'PostalCode' => '1072', 
            'Country' => 'New Zealand', 
            'City' => 'Auckland', 
            'Priority' => '7',
            'MSN_Contract__c' => 'KKKK'
        });

        // create a completed child work order
        WorkOrder wo2 = (WorkOrder)TestDataFactory.createSObject('WorkOrder', new Map<String,Object>{
            'ServiceTerritoryId' =>  st.Id,
            'WorkTypeId' => wt.Id,
            'Status' => 'New',
            'recordTypeId' => msnWorkOrderRtId,
            'Street' => '44 Meadowbank Road', 
            'PostalCode' => '1072', 
            'Country' => 'New Zealand', 
            'City' => 'Auckland', 
            'Priority' => '7',
            'ParentWorkOrderId' => wo1.Id,
            'AssetId' => asset.Id,
            'Work_Order_No__c' => '123457',
            'Status' => 'Completed',
            'MSN_Contract__c' => 'KKKK'
        });
        
        WorkPlan wp = (WorkPlan)TestDataFactory.createSObject('WorkPlan', new Map<String,Object>{
            'ParentRecordId' => wo2.Id,
            'WorkOrderId' => wo2.Id
        });

        WorkStep workStep1 = (WorkStep)TestDataFactory.createSObject('WorkStep', new Map<String, Object>{
            'WorkPlanId' => wp.Id,
            'MSN_Answer_Type__c' => 'Schedule Item Code'
        });

        WorkStep workStep2 = (WorkStep)TestDataFactory.createSObject('WorkStep', new Map<String, Object>{
            'MSN_Answer_Type__c' => 'Schedule Item Code'
        });

        MSN_Integration.integrationQueued = false;
        
        Test.startTest();
        // set feco for completed child work orders
        wo2.EAM_Work_Order_Status__c = 'FECO';
        update wo2;
        
        Test.stopTest();
    }

    static testMethod void completedChildWorkOrderIntegrationTest() {

        Id msnWorkOrderRtId = Schema.SObjectType.WorkOrder.getRecordTypeInfosByName().get('MSN').getRecordTypeId();
        ServiceTerritory st = [SELECT Id FROM ServiceTerritory LIMIT 1];
        WorkType wt = [SELECT Id FROM WorkType LIMIT 1];
        Asset asset = [SELECT Id FROM Asset LIMIT 1];

        MSN_Integration.integrationQueued = true;

        // create a parent work order
        WorkOrder wo1 = (WorkOrder)TestDataFactory.createSObject('WorkOrder', new Map<String,Object>{
            'ServiceTerritoryId' =>  st.Id,
            'WorkTypeId' => wt.Id,
            'Status' => 'New',
            'recordTypeId' => msnWorkOrderRtId,
            'Work_Order_No__c' => '123456',
            'Street' => '44 Meadowbank Road', 
            'PostalCode' => '1072', 
            'Country' => 'New Zealand', 
            'City' => 'Auckland', 
            'Priority' => '7',
            'MSN_Contract__c' => 'KKKK'
        });

        // create a completed child work order
        WorkOrder wo2 = (WorkOrder)TestDataFactory.createSObject('WorkOrder', new Map<String,Object>{
            'ServiceTerritoryId' =>  st.Id,
            'WorkTypeId' => wt.Id,
            'Status' => 'New',
            'recordTypeId' => msnWorkOrderRtId,
            'Street' => '44 Meadowbank Road', 
            'PostalCode' => '1072', 
            'Country' => 'New Zealand', 
            'City' => 'Auckland', 
            'Priority' => '7',
            'ParentWorkOrderId' => wo1.Id,
            'AssetId' => asset.Id,
            'Work_Order_No__c' => '123457',
            'StartDate' => Date.today().addDays(-1),
            'EndDate' => Date.today(),
            'MSN_Contract__c' => 'KKKK'
        });
        
        WorkPlan wp = (WorkPlan)TestDataFactory.createSObject('WorkPlan', new Map<String,Object>{
            'ParentRecordId' => wo2.Id,
            'WorkOrderId' => wo2.Id
        });

        WorkStep workStep1 = (WorkStep)TestDataFactory.createSObject('WorkStep', new Map<String, Object>{
            'WorkPlanId' => wp.Id,
            'MSN_Answer_Type__c' => 'Schedule Item Code'
        });

        WorkStep workStep2 = (WorkStep)TestDataFactory.createSObject('WorkStep', new Map<String, Object>{
            'WorkPlanId' => wp.Id,
            'MSN_Answer_Type__c' => 'Date'
        });

        MSN_Integration.integrationQueued = false;
        
        Test.startTest();
        // set feco for completed child work orders
        wo2.Status = 'Completed';
        update wo2;
        
        Test.stopTest();
    }

    static testMethod void labourLineGenerationWithoutWoliTest() {

        // setup pricebook entry
		String standardPricebookId = Test.getStandardPricebookId();

        Product2 pd = (Product2)TestDataFactory.createSObject('Product2', new Map<String,Object>{
            'Name' => 'Labour Charge',
            'Family' => 'Labour'
        });
        
        PricebookEntry pe = (PricebookEntry)TestDataFactory.createSObject('PricebookEntry', new Map<String,Object>{
            'Pricebook2Id' => standardPricebookId,
            'Product2Id' => pd.Id,
            'IsActive' => true,
            'UnitPrice' => 1
        });
      //  PricebookEntry

        Id msnWorkOrderRtId = Schema.SObjectType.WorkOrder.getRecordTypeInfosByName().get('MSN').getRecordTypeId();
        ServiceTerritory st = [SELECT Id FROM ServiceTerritory LIMIT 1];

        WorkType wt = [SELECT Id FROM WorkType LIMIT 1];
        Asset asset = [SELECT Id FROM Asset LIMIT 1];

        MSN_Integration.integrationQueued = true;

        // create a parent work order
        WorkOrder wo1 = (WorkOrder)TestDataFactory.createSObject('WorkOrder', new Map<String,Object>{
            'ServiceTerritoryId' =>  st.Id,
            'WorkTypeId' => wt.Id,
            'Status' => 'New',
            'recordTypeId' => msnWorkOrderRtId,
            'Work_Order_No__c' => '123456',
            'Street' => '44 Meadowbank Road', 
            'PostalCode' => '1072', 
            'Country' => 'New Zealand', 
            'City' => 'Auckland', 
            'Priority' => '7',
            'MSN_Contract__c' => 'KKKK',
            'Pricebook2Id' => standardPricebookId
        });

        // create service appointment for work order
        ServiceAppointment sa = (ServiceAppointment)TestDataFactory.createSObject('ServiceAppointment', new Map<String,Object>{
            'ParentRecordId' => wo1.Id,
            'EarliestStartTime' => Date.today().addDays(-1),
            'SchedStartTime' => Datetime.now(),
            'SchedEndTime' => Datetime.now().addDays(2),
            'ActualStartTime' => Datetime.now(),
            'MSN_TravelStart__c' => Datetime.now(),
            'ActualEndTime' => Datetime.now().addDays(1)
        });

        /*Profile p = [SELECT Id FROM Profile WHERE Name = 'MSN Field Crew'];

        // create a user for service resource
        User user = (User)TestDataFactory.createSObject('User', new Map<String,Object>{
            'ProfileId' => p.Id,
            'Username' => 'test@HGUBHJHGTU.com'
        });
        

        // create service resources for sa
        ServiceResource sr = (ServiceResource)TestDataFactory.createSObject('ServiceResource', new Map<String,Object>{
            'RelatedRecordId' => user.Id,
            'IsActive' => true
        });

        // create new ST member
        ServiceTerritoryMember stm = (ServiceTerritoryMember)TestDataFactory.createSObject('ServiceTerritoryMember', new Map<String,Object>{
            'ServiceResourceId' => sr.Id,
            'ServiceTerritoryId' => st.Id,
            'TerritoryType' => 'P'
        });*/

        ServiceResource sr = [SELECT Id FROM ServiceResource];

        // create an assigned service resource
        AssignedResource ar = (AssignedResource)TestDataFactory.createSObject('AssignedResource', new Map<String,Object>{
            'ServiceResourceId' => sr.Id,
            'ServiceAppointmentId' => sa.Id
        });

        Test.startTest();

        wo1.Status = 'Reviewed';
        update wo1;

        Test.stopTest();
    }

    static testMethod void labourLineGenerationWithWoliTest() {

        // setup pricebook entry
		String standardPricebookId = Test.getStandardPricebookId();

        Product2 pd = (Product2)TestDataFactory.createSObject('Product2', new Map<String,Object>{
            'Name' => 'Labour Charge',
            'Family' => 'Labour'
        });
        
        PricebookEntry pe = (PricebookEntry)TestDataFactory.createSObject('PricebookEntry', new Map<String,Object>{
            'Pricebook2Id' => standardPricebookId,
            'Product2Id' => pd.Id,
            'IsActive' => true,
            'UnitPrice' => 1
        });
      //  PricebookEntry

        Id msnWorkOrderRtId = Schema.SObjectType.WorkOrder.getRecordTypeInfosByName().get('MSN').getRecordTypeId();
        ServiceTerritory st = [SELECT Id FROM ServiceTerritory LIMIT 1];

        WorkType wt = [SELECT Id FROM WorkType LIMIT 1];
        Asset asset = [SELECT Id FROM Asset LIMIT 1];

        MSN_Integration.integrationQueued = true;

        // create a parent work order
        WorkOrder wo1 = (WorkOrder)TestDataFactory.createSObject('WorkOrder', new Map<String,Object>{
            'ServiceTerritoryId' =>  st.Id,
            'WorkTypeId' => wt.Id,
            'Status' => 'New',
            'recordTypeId' => msnWorkOrderRtId,
            'Work_Order_No__c' => '123456',
            'Street' => '44 Meadowbank Road', 
            'PostalCode' => '1072', 
            'Country' => 'New Zealand', 
            'City' => 'Auckland', 
            'Priority' => '7',
            'MSN_Contract__c' => 'KKKK',
            'Pricebook2Id' => standardPricebookId,
            'StartDate' => Date.today().addDays(-1),
            'EndDate' => Date.today()
        });
        
        WorkOrderLineItem woli = new WorkOrderLineItem(
            WorkOrderId = wo1.Id,
            MSN_EAM_Work_Order_No__c = '2222',
            WorkTypeId = wt.Id,
            AssetId = asset.Id,
            ServiceTerritoryId = st.Id,
            MSN_Root_Work_Order__c = wo1.Id
        );
        
        insert woli;

        // create service appointment for work order
        ServiceAppointment sa = (ServiceAppointment)TestDataFactory.createSObject('ServiceAppointment', new Map<String,Object>{
            'ParentRecordId' => wo1.Id,
            'EarliestStartTime' => Date.today().addDays(-1),
            'SchedStartTime' => Datetime.now(),
            'SchedEndTime' => Datetime.now().addDays(2),
            'ActualStartTime' => Datetime.now(),
            'MSN_TravelStart__c' => Datetime.now(),
            'ActualEndTime' => Datetime.now().addDays(1)
        });

        /*Profile p = [SELECT Id FROM Profile WHERE Name = 'MSN Field Crew'];

        // create a user for service resource
        User user = (User)TestDataFactory.createSObject('User', new Map<String,Object>{
            'ProfileId' => p.Id,
            'Username' => 'test@HGUBHJHGTU.com'
        });
        

        // create service resources for sa
        ServiceResource sr = (ServiceResource)TestDataFactory.createSObject('ServiceResource', new Map<String,Object>{
            'RelatedRecordId' => user.Id,
            'IsActive' => true
        });

        // create new ST member
        ServiceTerritoryMember stm = (ServiceTerritoryMember)TestDataFactory.createSObject('ServiceTerritoryMember', new Map<String,Object>{
            'ServiceResourceId' => sr.Id,
            'ServiceTerritoryId' => st.Id,
            'TerritoryType' => 'P'
        });*/

        ServiceResource sr = [SELECT Id FROM ServiceResource];

        // create an assigned service resource
        AssignedResource ar = (AssignedResource)TestDataFactory.createSObject('AssignedResource', new Map<String,Object>{
            'ServiceResourceId' => sr.Id,
            'ServiceAppointmentId' => sa.Id
        });

        Test.startTest();

        wo1.Status = 'Reviewed';
        update wo1;

        Test.stopTest();
    }
}