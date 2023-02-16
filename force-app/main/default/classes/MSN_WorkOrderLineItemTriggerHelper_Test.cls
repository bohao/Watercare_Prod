/**
 * @File Name          : MSN_WorkOrderTriggerHelper_Test.cls
 * @Description        : Test class for MSN_WorkOrderTriggerHelper.cls
 * @Author             : Bohao Chen
 * Ver      Date            Author                  Modification
 * 1.0      27/01/2023      Bohao Chen           Initial Version
**/
@isTest
public class MSN_WorkOrderLineItemTriggerHelper_Test {
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

        MSN_Integration.integrationQueued = true;

        // create a parent work order
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
            'Priority' => '7',
            'MSN_Contract__c' => 'KKKK',
            'Pricebook2Id' => standardPricebookId,
            'StartDate' => Date.today().addDays(-2),
            'EndDate' => Date.today()
        });
        
        WorkOrderLineItem woli = (WorkOrderLineItem)TestDataFactory.createSObject('WorkOrderLineItem', new Map<String,Object>{
            'WorkOrderId' => wo.Id,
            'WorkTypeId' => wt.Id,
            'AssetId' => asset.Id,
            'ServiceTerritoryId' => st.Id,
            'Status' => 'New',
            'MSN_EAM_Work_Order_No__c' => '987654',
            'MSN_Root_Work_Order__c' => wo.Id
        // WorkOrderLineItem woli = new WorkOrderLineItem(
        //     WorkOrderId = wo.Id,
        //     // MSN_Root_Work_Order__c = wo.Id,
        //     WorkTypeId = wt.Id,
        //     AssetId = asset.Id,
        //     ServiceTerritoryId = st.Id
        });
        
        // insert woli;

        WorkPlan wp = (WorkPlan)TestDataFactory.createSObject('WorkPlan', new Map<String,Object>{
            'ParentRecordId' => woli.Id,
            'WorkOrderId' => wo.Id,
            'WorkOrderLineItemId' => woli.Id
        });

        WorkStep workStep1 = (WorkStep)TestDataFactory.createSObject('WorkStep', new Map<String, Object>{
            'WorkPlanId' => wp.Id,
            'MSN_SPOT_Code__c' => 'ABCD',
            'Description' => 'test'
        });

        WorkStep workStep2 = (WorkStep)TestDataFactory.createSObject('WorkStep', new Map<String, Object>{
            'WorkPlanId' => wp.Id,
            'MSN_Answer_Type__c' => 'Schedule Item Code',
            'Description' => 'test'
        });

    }

    static testMethod void workOrderCompleteIntegrationTest() {

        Test.startTest();

        WorkOrderLineItem woli = [SELECT Id, MSN_Root_Work_Order__c, Status FROM WorkOrderLineItem];
        woli.Status = 'Completed';
        update woli;

        Test.stopTest();
    }

    static testMethod void workOrderCostIntegrationTest() {
        
        MSN_Integration.integrationQueued = true;
        WorkOrderLineItem woli = [SELECT Status FROM WorkOrderLineItem];
        woli.Status = 'Completed';
        update woli;        

        MSN_Integration.integrationQueued = false;

        Test.startTest();
        woli = [SELECT EAM_Work_Order_Status__c FROM WorkOrderLineItem];
        woli.EAM_Work_Order_Status__c = 'FECO';
        update woli;

        Test.stopTest();

    }

    static testMethod void creatingWolisFromWoTest() {
        WorkOrder wo = [SELECT Id, WorkType.Id, Asset.Id, Subject, Description FROM WorkOrder LIMIT 1];
        Test.startTest();
        MSN_WorkOrderLineItemTriggerHelper.createWoliFromWorkOrder(wo);
        Test.stopTest();
    }
}