/**
 * @File Name          : MSN_ProductConsumedTriggerHelper_Test.cls
 * @Description        : Test class for MSN_ProductConsumedTriggerHelper.cls
 * @Author             : Bohao Chen
 * Ver      Date            Author                  Modification
 * 1.0      31/01/2023      Bohao Chen           Initial Version
**/
@isTest
public class MSN_ProductConsumedTriggerHelper_Test {
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

        Product2 product = (Product2)TestDataFactory.createSObject('Product2', new Map<String,Object>{
            'Name' => 'Testing Part',
            'IsActive' => true,
            'ProductCode' => 'abcd'
        });

        Product2 labourCharge = (Product2)TestDataFactory.createSObject('Product2', new Map<String,Object>{
            'Name' => 'Labour Charge',
            'IsActive' => true,
            'ProductCode' => 'Labour',
            'Family' => 'Labour'
        });

        String standardPricebookId = Test.getStandardPricebookId();

        PricebookEntry pe = (PricebookEntry)TestDataFactory.createSObject('PricebookEntry', new Map<String,Object>{
            'Pricebook2Id' => standardPricebookId,
            'Product2Id' => labourCharge.Id,
            'IsActive' => true,
            'UnitPrice' => 1
        });

        Schema.Location l = new Schema.Location();
        l.LocationType = 'Van';
        l.IsInventoryLocation = true;
        l.Name = 'van location';
        insert l;
        // )TestDataFactory.createSObject('System.Location', new Map<String,Object>{
        //     'LocationType' => 'Van',
        //     'IsInventoryLocation' => true            
        // });

        ProductItem productItem = (ProductItem)TestDataFactory.createSObject('ProductItem', new Map<String,Object>{
            'EAM_Quantity__c' => 6,
            'Product2Id' => product.Id,
            'LocationId' => l.Id,
            'QuantityOnHand' => 6
        });

        Id msnWorkOrderRtId = Schema.SObjectType.WorkOrder.getRecordTypeInfosByName().get('MSN').getRecordTypeId();

        // create work order
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
            'Pricebook2Id' => standardPricebookId
        });

    }

    static testMethod void insertProductConsumedQuantityTest() {

        WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];
        ProductItem pi = [SELECT Id FROM ProductItem LIMIT 1];

        Test.startTest();
        ProductConsumed stm = (ProductConsumed)TestDataFactory.createSObject('ProductConsumed', new Map<String,Object>{
            'WorkOrderId' => wo.Id,
            'QuantityConsumed' => 1,
            'Sent_to_EAM__c' => false,
            'ProductItemId' => pi.Id,
            'Not_Sufficient_EAM_Stock__c' => false
        });
        Test.stopTest();
    }

    static testMethod void insertLabourChargeTest() {

        WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];
        ProductItem pi = [SELECT Id FROM ProductItem LIMIT 1];
        Product2 labourCharge = [SELECT Id FROM Product2 WHERE Name = 'Labour Charge'];
        PricebookEntry pe = [SELECT Id FROM PricebookEntry];

        Test.startTest();
        ProductConsumed stm = (ProductConsumed)TestDataFactory.createSObject('ProductConsumed', new Map<String,Object>{
            'WorkOrderId' => wo.Id,
            'QuantityConsumed' => 1,
            'Sent_to_EAM__c' => false,
            'PricebookEntryId' => pe.Id,
            // 'ProductItemId' => pi.Id,
            'Not_Sufficient_EAM_Stock__c' => false
        });
        Test.stopTest();
    }

    static testMethod void increaseProductConsumedQuantityTest() {

        WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];
        ProductItem pi = [SELECT Id FROM ProductItem LIMIT 1];

        
        ProductConsumed stm = (ProductConsumed)TestDataFactory.createSObject('ProductConsumed', new Map<String,Object>{
            'WorkOrderId' => wo.Id,
            'QuantityConsumed' => 1,
            'Sent_to_EAM__c' => true,
            'Previous_Quantity__c' => 0,
            'ProductItemId' => pi.Id,
            'Not_Sufficient_EAM_Stock__c' => false
        });

        Test.startTest();
        stm.Previous_Quantity__c = 1;
        stm.QuantityConsumed = 2;
        stm.Sent_to_EAM__c = false;
        update stm;
        Test.stopTest();
    }

    static testMethod void updateLabourChargeTest() {

        WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];
        ProductItem pi = [SELECT Id FROM ProductItem LIMIT 1];
        Product2 labourCharge = [SELECT Id FROM Product2 WHERE Name = 'Labour Charge'];
        PricebookEntry pe = [SELECT Id FROM PricebookEntry];

        
        ProductConsumed stm = (ProductConsumed)TestDataFactory.createSObject('ProductConsumed', new Map<String,Object>{
            'WorkOrderId' => wo.Id,
            'QuantityConsumed' => 1,
            'Sent_to_EAM__c' => false,
            'PricebookEntryId' => pe.Id,
            // 'ProductItemId' => pi.Id,
            'Not_Sufficient_EAM_Stock__c' => false
        });

        Test.startTest();
        stm.QuantityConsumed = 2;
        stm.Sent_to_EAM__c = false;
        update stm;
        Test.stopTest();
    }

    static testMethod void decreaseProductConsumedQuantityTest() {
        WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];
        ProductItem pi = [SELECT Id FROM ProductItem LIMIT 1];

        
        ProductConsumed stm = (ProductConsumed)TestDataFactory.createSObject('ProductConsumed', new Map<String,Object>{
            'WorkOrderId' => wo.Id,
            'QuantityConsumed' => 3,
            'Sent_to_EAM__c' => true,
            'Previous_Quantity__c' => 0,
            'ProductItemId' => pi.Id,
            'Not_Sufficient_EAM_Stock__c' => false
        });

        Test.startTest();
        stm.Previous_Quantity__c = 3;
        stm.QuantityConsumed = 1;
        stm.Sent_to_EAM__c = false;
        update stm;
        Test.stopTest();

    }

    static testMethod void deleteProductConsumedQuantityTest() {

        WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];
        ProductItem pi = [SELECT Id FROM ProductItem LIMIT 1];

        
        ProductConsumed stm = (ProductConsumed)TestDataFactory.createSObject('ProductConsumed', new Map<String,Object>{
            'WorkOrderId' => wo.Id,
            'QuantityConsumed' => 3,
            'Sent_to_EAM__c' => true,
            'ProductItemId' => pi.Id,
            'Not_Sufficient_EAM_Stock__c' => false
        });

        Test.startTest();
        delete stm;
        Test.stopTest();
    }

    static testMethod void deleteLabourChargeTest() {

        WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];
        ProductItem pi = [SELECT Id FROM ProductItem LIMIT 1];
        Product2 labourCharge = [SELECT Id FROM Product2 WHERE Name = 'Labour Charge'];
        PricebookEntry pe = [SELECT Id FROM PricebookEntry];

        
        ProductConsumed stm = (ProductConsumed)TestDataFactory.createSObject('ProductConsumed', new Map<String,Object>{
            'WorkOrderId' => wo.Id,
            'QuantityConsumed' => 1,
            'Sent_to_EAM__c' => false,
            'PricebookEntryId' => pe.Id,
            // 'ProductItemId' => pi.Id,
            'Not_Sufficient_EAM_Stock__c' => false
        });

        Test.startTest();
        delete stm;
        Test.stopTest();
    }
}