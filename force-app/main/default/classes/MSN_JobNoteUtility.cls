/**
 * @File Name          : MSN_JobNoteUtility.cls
 * @Description        : Utility class for Job Note 
 * @Author             : Bohao Chen
 * @Group              : 
 * @Last Modified By   : Bohao Chen
 * @Last Modified On   : 31/08/2022
 * @Modification Log   : 
 * Ver      Date            Author                  Modification
 * 1.0      31/08/2022      Bohao Chen              Initial Version
**/
public with sharing class MSN_JobNoteUtility {
    
    // this method is to create a job note when records gets updated based on the Custom Metadata Type "Job Notes Type Mappings"
    public static void createJobNotes(Map<Id, sObject> newRecords, Map<Id, sObject> oldRecords) {
        List<MSN_JobNotes__c> jobNotes = new List<MSN_JobNotes__c>();

        for(Id recId : newRecords.keySet()) {
            sObject newRec = newRecords.get(recId);
            String objectApiName = newRec.getSObjectType().getDescribe().getName();
            System.debug('@objectApiName: ' + objectApiName);

            Map<String, Schema.SObjectField> fieldMap = Schema.getGlobalDescribe().get(objectApiName).getDescribe().fields.getMap();

            // get custom metadata type Job_Notes_Type_Mapping__mdt
            for ( Job_Notes_Type_Mapping__mdt jobNoteTypeMapping : Job_Notes_Type_Mapping__mdt.getAll().values()){
                
                if(jobNoteTypeMapping.Trigger_Object__c.equalsIgnoreCase(objectApiName)) {

                    String triggerField = jobNoteTypeMapping.Trigger_Field__c;
                                        
                    // when trigger field value changed
                    if(newRec.get(triggerField) != null && (oldRecords == null || oldRecords.get(recId).get(triggerField) != newRec.get(triggerField))) {

                        String value = String.valueOf(newRec.get(triggerField));
                        String triggerValue = jobNoteTypeMapping.Trigger_Value__c;

                        System.debug('@trigger field string value: ' + value);

                        if((objectApiName.equalsIgnoreCase('WorkStep') && triggerField.equalsIgnoreCase('MSN_WorkStep_Answer__c') && value.contains(triggerValue))
                            || (String.isNotBlank(triggerValue) && value.equalsIgnoreCase(triggerValue))
                            || (String.isBlank(triggerValue) && String.isNotBlank(value) == jobNoteTypeMapping.Is_Not_Blank__c)) {

                            System.debug('@same value');
                            // create job note
                            jobNotes.add(createJobNote(newRec, jobNoteTypeMapping, objectApiName, fieldMap));
                        }
                    }
                }
            }                       
        }

        if(!jobNotes.isEmpty()) {
            insert jobNotes;
        }
    }

    private static MSN_JobNotes__c createJobNote(sObject record, Job_Notes_Type_Mapping__mdt jobNoteTypeMapping, String objectApiName, Map<String, Schema.SObjectField> fieldMap) {
        
        Id workOrderId = (Id)record.get(jobNoteTypeMapping.Work_Order_Id_Field__c);
        Id serviceAppointmentId;
        Id workOrderLineItemId;

        if(objectApiName == 'ServiceAppointment') {
            serviceAppointmentId = record.Id;
        }
        else if(objectApiName == 'WorkOrderLineItem') {
            workOrderLineItemId = record.Id;
        }

        MSN_JobNotes__c jobNote = new MSN_JobNotes__c(
            MSN_Work_Order__c = workOrderId,
            MSN_Service_Appointment__c = serviceAppointmentId,
            Work_Order_Line_Item__c = workOrderLineItemId,
            MSN_JobNote_Type__c = 'Service Request Update Type',
            Concatenate_Job_Note__c = jobNoteTypeMapping.Concatenate_Job_Note__c,
            Integrate_to_EAM__c = jobNoteTypeMapping.Integrate_to_EAM__c,
            Service_Request_Update_Code__c = jobNoteTypeMapping.Service_Request_Update_Code__c,
            MSN_JobNote_Details__c = populateJobNoteDetails(record, jobNoteTypeMapping.Payload_Fields__c, fieldMap)
        );

        return jobNote;
    }

    public static String populateJobNoteDetails(sObject record, String fieldsStr, Map<String, Schema.SObjectField> fieldMap) {
        String details = '';
        if(String.isNotBlank(fieldsStr)) {
            if(fieldsStr.contains(',')) {
                for(String fieldStr : fieldsStr.split(',')) {
                    details += String.format('{0}\n', new String[]{fieldMap.get(fieldStr).getDescribe().getLabel() + ':' + convertValueToStr(record, fieldStr, fieldMap)});
                }
                details = details.removeEnd('\n');
            }
            else {
                details += fieldMap.get(fieldsStr).getDescribe().getLabel() + ':' + convertValueToStr(record, fieldsStr, fieldMap);
            }
            
            System.debug('@details: ' + details);
        }

        return details;
    }

    // this method is to create a job note when receiving work order update from EAM
    public static MSN_JobNotes__c createJobNote(String jsonString) {
		MSN_UpdateReactiveMaintenanceWrapper jobNoteWrapper = (MSN_UpdateReactiveMaintenanceWrapper)System.JSON.deserialize(jsonString, MSN_UpdateReactiveMaintenanceWrapper.class);

        // search for the work order based on EAM work order number (Work_Order_No__c)
        String eamWorkOrderNum = jobNoteWrapper.WorkOrderNo;

        List<WorkOrder> workOrders = [SELECT Id FROM WorkOrder Where Work_Order_No__c =: eamWorkOrderNum];

        MSN_JobNotes__c jobNote;
        if(workOrders.isEmpty()) {
            throw new MSN_Utility.CustomException('Couldn\'t find the work order \'' + eamWorkOrderNum + '\'');
        }
        else {
            jobNote = new MSN_JobNotes__c();
            jobNote.Service_Request_Update_Code__c = jobNoteWrapper.UpdateType;
            jobNote.MSN_JobNote_Details__c = jobNoteWrapper.Comments;
            jobNote.MSN_Work_Order__c = workOrders[0].Id;
            jobNote.MSN_JobNote_Type__c = 'Service Request Update Type';
            insert jobNote;
        }
        
        return jobNote;
    }

    @TestVisible private static String convertValueToStr(sObject record, String fieldStr, Map<String, Schema.SObjectField> fieldMap) {
        
        String val;

        if(fieldMap.get(fieldStr).getDescribe().getType() == Schema.DisplayType.DATETIME) {
            System.debug('@this is a datetime field');

            Datetime dt = Datetime.valueOf(record.get(fieldStr));
            val = dt.format('yyyy-MM-dd h:mm a');
            System.debug('@myDate: ' + val);
        }
        else {
            val = String.valueOf(record.get(fieldStr));
        }

        return val;
    }
}