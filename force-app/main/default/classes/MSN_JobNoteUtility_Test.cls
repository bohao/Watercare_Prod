/**
 * @File Name          : MSN_JobNoteUtility_Test.cls
 * @Description        : Test class for MSN_JobNoteUtility.cls
 * @Author             : Bohao Chen
 * Ver      Date            Author                  Modification
 * 1.0      30/01/2023      Bohao Chen           Initial Version
**/
@isTest
public class MSN_JobNoteUtility_Test {
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
            'Priority' => '7'
        });

        WorkPlan wp = (WorkPlan)TestDataFactory.createSObject('WorkPlan', new Map<String,Object>{
            'ParentRecordId' => wo.Id,
            'WorkOrderId' => wo.Id
        });

        WorkStep workStep = (WorkStep)TestDataFactory.createSObject('WorkStep', new Map<String, Object>{
            'WorkPlanId' => wp.Id,
            'MSN_Answer_Type__c' => 'Schedule Item Code'
        });

        FSL__Scheduling_Policy__c schPolicy = (FSL__Scheduling_Policy__c)TestDataFactory.createSObject('FSL__Scheduling_Policy__c');        

        // create service appointment for work order
        ServiceAppointment sa = (ServiceAppointment)TestDataFactory.createSObject('ServiceAppointment', new Map<String,Object>{
            'ParentRecordId' => wo.Id,
            'EarliestStartTime' => Datetime.now().addHours(-2),
            'SchedStartTime' => Datetime.now(),
            'SchedEndTime' => Datetime.now().addDays(2),
            'Street' => '26 Phyllis ST',
            'City' => 'Mount Albert',
            'Country' => 'New Zealand',
            'PostalCode' => '3127',
            'ServiceTerritoryId' => st.Id,
            'DueDate' => Date.today().addDays(2),
            'Confined_space_entry__c' => false,
            'Crew_out_of_confined_space__c' => false,
            // 'Dialysis_Patient__c' => false,
            'FSL__Scheduling_Policy_Used__c' => schPolicy.Id,
            'Priority__c' => 'P7',
            'Status' => 'Dispatched'
            // 'ActualStartTime' => Datetime.now(),
            // 'MSN_TravelStart__c' => Datetime.now(),
            // 'ActualEndTime' => Datetime.now().addDays(1)
        });

        // create service resource
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

        // create an assigned service resource for service appointment
        AssignedResource ar = (AssignedResource)TestDataFactory.createSObject('AssignedResource', new Map<String,Object>{
            'ServiceResourceId' => sr.Id,
            'ServiceAppointmentId' => sa.Id
        });
    }

    // static testMethod void createJobNotesForServiceAppointmentTest() {        
    //     ServiceAppointment sa = [SELECT Id FROM ServiceAppointment LIMIT 1];        
        
    //     // sa.Status = 'Dispatched';
    //     // update sa;

    //     Test.startTest();
    //     sa.Status = 'Travel'; ///???
    //     update sa;
    //     Test.stopTest();
    // }

    static testMethod void createJobNotesForWorkOrderTest() {
        WorkOrder wo = [SELECT Id, Estimated_Water_On__c FROM WorkOrder WHERE Work_Order_No__c = '123456' LIMIT 1];
        Test.startTest();
        wo.Estimated_Water_On__c = Datetime.now().addDays(1);
        update wo;
        Test.stopTest();

        // assertion
        MSN_JobNotes__c jn = [SELECT Id, MSN_JobNote_Details__c FROM MSN_JobNotes__c 
                            WHERE MSN_EAM_Work_Order_No__c = '123456' 
                            AND Service_Request_Update_Code__c = 'WAON'];
                            
        Map<String, Schema.SObjectField> fieldMap = Schema.getGlobalDescribe().get('WorkOrder').getDescribe().fields.getMap();
        wo = [SELECT Estimated_Water_On__c FROM WorkOrder LIMIT 1];
        String valueStr = MSN_JobNoteUtility.convertValueToStr(wo, 'Estimated_Water_On__c', fieldMap);
        System.assertEquals('Estimated Water On Time:' + valueStr, jn.MSN_JobNote_Details__c);
    }

    static testMethod void createJobNotesForWorkStepTest() {

        WorkStep workStep = [SELECT MSN_WorkStep_Answer__c FROM WorkStep LIMIT 1];

        Test.startTest();
        workStep.MSN_WorkStep_Answer__c = 'PRIPRO';
        update workStep;
        Test.stopTest();

        // assertion
    }

    static testMethod void createJobNotesFromJSONTest() {

        MSN_UpdateReactiveMaintenanceWrapper req = new MSN_UpdateReactiveMaintenanceWrapper();
        req.TransactionID = '123';
        req.WorkOrderNo = '123456';
        req.ContractorCode = 'MSN';
        req.UpdateType = 'COMMTW';
        req.UpdateDate = '2019-04-17T12:30:00';
        req.Comments = 'WATERCARE: Hi, the fault that you reported on 52 Mokoia RD on SR15322623 has been repaired. Please allow 15-21 days for reinstatement work to be complete';

        MSN_JobNoteUtility.createJobNote(String.valueOf(JSON.serialize(req)));
        
    }
}