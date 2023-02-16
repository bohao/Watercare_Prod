/**
* Author : Ashwini Patil
* Date : 18/08/2022
* Updated By: Bohao Chen
* Updated Date: 27/01/2023
* Description : Test class to cover MSN_JobNoteTriggerHandler and MSN_JobNoteTriggerHelper class
**/
@isTest
public class MSN_JobNotesTrigger_Test {

    @TestSetup
    static void testDataSetup() {

        OperatingHours oh = (OperatingHours)TestDataFactory.createSObject('OperatingHours', new Map<String,Object>{
            'Name' => 'test operation hours',
            'TimeZone' => 'Pacific/Auckland'
        });

        ServiceTerritory st = (ServiceTerritory)TestDataFactory.createSObject('ServiceTerritory', new Map<String,Object>{
            'IsActive' => true,
            'OperatingHoursId' => oh.Id
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
    }

    @isTest
    public static void insertTest() {   
        
        WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];
                      
        MSN_Integration.integrationQueued = false;
        Test.startTest();

        List<MSN_JobNotes__c> JON = new List<MSN_JobNotes__c>();
        for(Integer i=0;i<4;i++) {
            JON.add(new MSN_JobNotes__c(MSN_Work_Order__c = wo.Id, MSN_JobNote_Details__c = 'Test data for note details field', Concatenate_Job_Note__c =
                                        true, MSN_JobNote_Type__c = 'Service Request Update Type', Integrate_to_EAM__c = true, Service_Request_Update_Code__c = 'WATEROFF'));
            i++;
        }
        
        JON.add(new MSN_JobNotes__c(MSN_Work_Order__c = wo.Id, MSN_JobNote_Details__c = 'Test data for note details field', 
                                    Concatenate_Job_Note__c = true, MSN_JobNote_Type__c = 'Service Restore'));

        insert JON;

        Test.stopTest();
    }
    
    @isTest
    static void updateJobNotestest(){

        WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];

        List<MSN_JobNotes__c> jobNotes = new List<MSN_JobNotes__c>();
        for(Integer i=0;i<4;i++) {
            jobNotes.add(new MSN_JobNotes__c(MSN_Work_Order__c = wo.Id, MSN_JobNote_Details__c = 'Test data for note details field', Concatenate_Job_Note__c =
                                        true, MSN_JobNote_Type__c = 'Service Request Update Type', Integrate_to_EAM__c = true, Service_Request_Update_Code__c = 'WATEROFF'));
            i++;
        }
        
        jobNotes.add(new MSN_JobNotes__c(MSN_Work_Order__c = wo.Id, MSN_JobNote_Details__c = 'Test data for note details field', 
                                    Concatenate_Job_Note__c = true, MSN_JobNote_Type__c = 'Service Restore'));

        insert jobNotes;
        
        Test.startTest();
        for(MSN_JobNotes__c jn : jobNotes) {
            jn.MSN_JobNote_Details__c = 'updated note details';
        }

        Test.stopTest();
        update jobNotes;
    }       

    @isTest
    static void deleteJobNotestest(){

        WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];
        
        List<MSN_JobNotes__c> jobNotes = new List<MSN_JobNotes__c>();
        for(Integer i=0;i<4;i++) {
            jobNotes.add(new MSN_JobNotes__c(MSN_Work_Order__c = wo.Id, MSN_JobNote_Details__c = 'Test data for note details field', Concatenate_Job_Note__c =
                                        true, MSN_JobNote_Type__c = 'Service Request Update Type', Integrate_to_EAM__c = true, Service_Request_Update_Code__c = 'WATEROFF'));
            i++;
        }
        
        jobNotes.add(new MSN_JobNotes__c(MSN_Work_Order__c = wo.Id, MSN_JobNote_Details__c = 'Test data for note details field', 
                                    Concatenate_Job_Note__c = true, MSN_JobNote_Type__c = 'Service Restore'));

        insert jobNotes;
        
        Test.startTest();
        delete jobNotes;
        Test.stopTest();
    }
}