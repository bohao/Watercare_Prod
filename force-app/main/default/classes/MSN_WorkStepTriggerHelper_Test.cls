/**
 * @File Name          : MSN_WorkStepTriggerHelper_Test.cls
 * @Description        : Test class for MSN_WorkStepTriggerHelper.cls
 * @Author             : Bohao Chen
 * Ver      Date            Author                  Modification
 * 1.0      23/01/2023      Bohao Chen           Initial Version
**/
@isTest
public class MSN_WorkStepTriggerHelper_Test {
    @TestSetup
    static void testDataSetup() {
        ServiceTerritory st = (ServiceTerritory)TestDataFactory.createSObject('ServiceTerritory', new Map<String,Object>{
            'IsActive' => true
        });

        WorkType wt = (WorkType)TestDataFactory.createSObject('WorkType', new Map<String,Object>{
            'MSN_ActivityCode__c' => 'abcd'
        });

        Asset asset = (Asset)TestDataFactory.createSObject('Asset', new Map<String,Object>{
            'Comp_Key__c' => '555',
            'SerialNumber' => '55555'
        });

        WorkStepTemplate wsTemplate = (WorkStepTemplate)TestDataFactory.createSObject('WorkStepTemplate', new Map<String,Object>{
            'MSN_SPOT_Code__c' => 'W2010',
            'MSN_Answer_Type__c' => 'String',
            'IsActive' => true,
            'Description' => 'What is the ID of the old water meter?'
        });

        Work_Step_Answer_Mapping__c wsm = (Work_Step_Answer_Mapping__c)TestDataFactory.createSObject('Work_Step_Answer_Mapping__c', new Map<String,Object>{
            'MSN_FROM_Object__c' => 'WorkOrder',
            'MSN_FROM_Object_Field_API_Name__c' => 'Serial_Number__c',
            'MSN_Work_Step_Template__c' => wsTemplate.Id
        });

        Id msnWorkOrderRtId = Schema.SObjectType.WorkOrder.getRecordTypeInfosByName().get('MSN').getRecordTypeId();        
        
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
            'Priority' => '7',
            'AssetId' => asset.Id
        });
    }

    static testMethod void successWorkStepTest() {

        Id woId = [SELECT Id FROM WorkOrder LIMIT 1].Id;
        Id wstId = [SELECT Id FROM WorkStepTemplate LIMIT 1].Id;

        WorkPlan wp = (WorkPlan)TestDataFactory.createSObject('WorkPlan', new Map<String,Object>{
            'ParentRecordId' => woId
        });

        Test.startTest();
        WorkStep ws = (WorkStep)TestDataFactory.createSObject('WorkStep', new Map<String,Object>{
            'MSN_WorkStep_Answer__c' => '',
            'MSN_SPOT_Code__c' => 'W2010',
            'WorkPlanId' => wp.Id
        });
        Test.stopTest();

        ws = [SELECT MSN_WorkStep_Answer__c FROM WorkStep WHERE WorkOrderId =: woId];
        System.assertEquals('55555', ws.MSN_WorkStep_Answer__c);
        


    }
}