/**
 * @File Name          : MSN_WorkStepAnswerTriggerHelper.cls
 * @Description        : Trigger Helper for WorkStepAnswer__c
 * @Author             : David Azzi
 * @Group              : 
 * @Last Modified By   : David Azzi
 * @Last Modified On   : 17/01/2022
 * @Modification Log   : 
 * Ver      Date            Author                  Modification
 * 1.0      17/01/2022      David Azzi              Initial Version
**/
public class MSN_JobNoteTriggerHelper {

    public static List<WorkOrder> buildJobNotesForWorkOrder(List<MSN_JobNotes__c> allJobNotes) 
    {
        //date, time, user, type
        //comment by:
        Map<Id, WorkOrder> woIdWo = new Map<Id, WorkOrder>();

        for(MSN_JobNotes__c jobNote : allJobNotes )
        {
            String note = '';
            
            // insert Service Request Update Note (only concatenate onto Work Order MSN Job Notes if Type = Service Request Update AND Concatenate on Work Order Job Notes = true)
            if(jobNote.MSN_JobNote_Type__c == 'Service Request Update Type' && jobNote.Concatenate_Job_Note__c) {
                note += String.valueOf(jobNote.CreatedDate) + ' ** Service Request Update Type ** ';
                note += '<br />' + (jobNote.MSN_JobNote_Details__c == null ? '' : jobNote.MSN_JobNote_Details__c.replaceAll('\n', '<br />'));
            }
            else if(jobNote.MSN_JobNote_Type__c != 'Service Request Update Type') {
                note += String.valueOf(jobNote.CreatedDate) + ' ** User Note ** ' + (jobNote.MSN_ServiceAppointmentNumber__c == null ? '' : jobNote.MSN_ServiceAppointmentNumber__c);
                note += '<br />Comment By: ' + (jobNote.MSN_Created_By_User_Name__c == null ? '' : jobNote.MSN_Created_By_User_Name__c);
                note += '<br />' + (jobNote.MSN_JobNote_Details__c == null ? '' : jobNote.MSN_JobNote_Details__c);
            }

            system.debug('@note: ' + note);

            if(String.isNotBlank(note)) {
                if ( woIdWo.containsKey(jobNote.MSN_Work_Order__c)) {                
                    woIdWo.get(jobNote.MSN_Work_Order__c).MSN_Job_Notes__c = note 
                        + '<br />----------------------------------------<br />' 
                        + woIdWo.get(jobNote.MSN_Work_Order__c).MSN_Job_Notes__c;
                } else {
                    woIdWo.put(jobNote.MSN_Work_Order__c, new WorkOrder(Id = jobNote.MSN_Work_Order__c, MSN_Job_Notes__c = note));
                }
            }
        }

        return woIdWo.values();
    }

    //TODO Check if the job note has changed, and remove the existing comment OR do i just append it to the end as a new comment?
    /*public static void insertJobNotesToWorkOrder(List<MSN_JobNotes__c> newJobNotes ){

        Map<Id, WorkOrder> woIdWO = new Map<Id, WorkOrder>();
        Set<Id> woIds = new Set<Id>();
        List<WorkOrder> woToUpdate = new List<WorkOrder>();

        for(WorkOrder wo : buildJobNotesForWorkOrder(newJobNotes) )
        {
            woIdWO.put(wo.Id, wo);
            woIds.add(wo.Id);
        }

        List<WorkOrder> oldWorkOrders = [SELECT Id, MSN_Job_Notes__c 
                                        FROM WorkOrder
                                        WHERE Id IN: woIds ];

        for(WorkOrder wo : [SELECT Id, MSN_Job_Notes__c FROM WorkOrder WHERE Id IN: woIds])
        {
            String note = woIdWO.get(wo.Id).MSN_Job_Notes__c + '<br />----------------------------------------<br />';
            woToUpdate.add(new WorkOrder(Id = wo.Id, MSN_Job_Notes__c = note + wo.MSN_Job_Notes__c));
        }

        Database.update(woToUpdate);
    }*/

    //TODO Check if the job note has changed, and remove the existing comment OR do i just append it to the end as a new comment?
    //TODO Check with Matt on how to sort the updates, if we just sort it by Created date, uncomment, if not - rebuild.     
    public static void updateJobNotesToWorkOrder(List<MSN_JobNotes__c> jobNotesToUpdate ){

        List<MSN_JobNotes__c> qualifiedJobNotes = new List<MSN_JobNotes__c>();
        List<WorkOrder> afffectedWorkOrders = new List<WorkOrder>();

        for(MSN_JobNotes__c jn : jobNotesToUpdate) {
            
            if((String.isBlank(jn.MSN_ServiceAppointmentNumber__c) && String.isBlank(jn.Work_Order_Line_Item__c))
                || String.isNotBlank(jn.MSN_ServiceAppointmentNumber__c)) {                
                    afffectedWorkOrders.add(new WorkOrder(Id = jn.MSN_Work_Order__c));
            }
        }

        // get all Job notes of these affected work orders which has updated job note
        for(WorkOrder wo : [SELECT MSN_Job_Notes__c,  
                                (SELECT MSN_ServiceAppointmentNumber__c, MSN_Work_Order__c, Work_Order_Line_Item__c, Concatenate_Job_Note__c, 
                                        CreatedDate, MSN_JobNote_Type__c, MSN_Created_By_User_Name__c, MSN_JobNote_Details__c
                                FROM Job_Notes__r ORDER BY CreatedDate ASC) 
                            FROM WorkOrder 
                            WHERE Id IN: afffectedWorkOrders]) {

            for(MSN_JobNotes__c jn : wo.Job_Notes__r) {
                if((String.isBlank(jn.MSN_ServiceAppointmentNumber__c) && String.isBlank(jn.Work_Order_Line_Item__c))
                    || String.isNotBlank(jn.MSN_ServiceAppointmentNumber__c)) {
                    qualifiedJobNotes.add(jn);
                }
            }            
        }

        System.debug('@qualifiedJobNotes: ' + qualifiedJobNotes);

        List<WorkOrder> workOrderToBeUpdated = buildJobNotesForWorkOrder(qualifiedJobNotes);


        if(!workOrderToBeUpdated.isEmpty()) {
            Database.update(workOrderToBeUpdated);
        }
        /*
        Set<Id> woIds = new Set<Id>();

        for(MSN_JobNotes__c jn : jobNotesToUpdate)
        {
            woIds.add(jn.MSN_Work_Order__c);
        }

        
        List<WorkOrder> workOrdersToUpdate = buildJobNotesForWorkOrder([SELECT MSN_JobNote_Type__c, CreatedDate, MSN_ServiceAppointmentNumber__c, MSN_JobNote_Details__c, MSN_Created_By_User_Name__c, MSN_Work_Order__c
                                                                        FROM MSN_JobNotes__c
                                                                        WHERE MSN_Work_Order__c IN: woIds
                                                                        GROUP BY CreatedDate
                                                                        ASC ]);

        Database.update(workOrdersToUpdate);
        */
        //fillWorkOrderJobNotes();//TODO remove this temporary fix
    }




    //TODO DELETE BEFORE PROD
    ///THIS WAS A MANUAL 1 OFF TIME TO BE RUN, KEEPING INCASE IT NEEDS TO BE RUN AGAIN WITH FURTHER CHANGES *** CAN DELETE FOR PROD
    /*public static void fillWorkOrderJobNotes()
    {

        //get all job notes that have no SA or WOLI
        //get all job notes that have SA
        //get all job ntoes that have WOLI

        Map<Id, WorkOrder> allWos = new Map<Id, WorkOrder>();

        for(WorkOrder wo : buildJobNotesForWorkOrder([SELECT MSN_JobNote_Type__c, CreatedDate, MSN_ServiceAppointmentNumber__c, MSN_JobNote_Details__c, MSN_Created_By_User_Name__c, MSN_Work_Order__c 
                                                    FROM MSN_JobNotes__c 
                                                    WHERE MSN_ServiceAppointmentNumber__c = '' 
                                                    AND Work_Order_Line_Item__c = ''
                                                    ORDER BY CreatedDate 
                                                    ASC]))
        {
            if ( allWos.containsKey(wo.Id) )
            {
                allWos.get(wo.Id).MSN_Job_Notes__c =  wo.MSN_Job_Notes__c + '<br />----------------------------------------<br />' + allWos.get(wo.Id).MSN_Job_Notes__c;
            } else {
                allWos.put(wo.Id, wo);
            }
        }

        for(WorkOrder wo : buildJobNotesForWorkOrder([SELECT MSN_JobNote_Type__c, CreatedDate, MSN_ServiceAppointmentNumber__c, MSN_JobNote_Details__c, MSN_Created_By_User_Name__c, MSN_Work_Order__c 
                                                    FROM MSN_JobNotes__c 
                                                    WHERE MSN_ServiceAppointmentNumber__c != ''
                                                    ORDER BY CreatedDate 
                                                    ASC]))
        {
            if ( allWos.containsKey(wo.Id) )
            {
                allWos.get(wo.Id).MSN_Job_Notes__c =  wo.MSN_Job_Notes__c + '<br />----------------------------------------<br />' + allWos.get(wo.Id).MSN_Job_Notes__c;
            } else {
                allWos.put(wo.Id, wo);
            }
        }
        
        Database.update(allwos.values());
    }*/

    // this method defines which endpoints to which payloads are going to send.
    public static void triggerOutboundIntegration(Map<Id, SObject> recordsMap) {

        // only send job notes with 'Service Request Update Code' to EAM
        Map<Id, SObject> eligibleRecordsMap = new Map<Id, SObject>();

        for(String Id : recordsMap.keySet()) {
            MSN_JobNotes__c jobNote = (MSN_JobNotes__c)recordsMap.get(Id);
            
            if(String.isNotBlank(jobNote.Service_Request_Update_Code__c) && jobNote.Integrate_to_EAM__c) {
                eligibleRecordsMap.put(Id, jobNote);
            }
        }

        Map<String, List<String>> endpointAndPayloadsApiNameMap = new Map<String, List<String>>();        
        // the first argument should be the dev/API name of the endpoint 
        //  in "Integration Payloads" custom metadata setting (without the instance name as suffix)
        // the second argument should be a list of payloads which are calling the same endpoint
        
        endpointAndPayloadsApiNameMap.put('Update_Maintenance_Work_Order', new String[]{'Update_a_Maintenance_Work_Order'}); 
        MSN_Integration.integrationQueued = false;
        List<Outbound_Integration__e> platformEvents = MSN_IntegrationUtility.generateOutboundIntegrationEvents(eligibleRecordsMap, 'MSN_JobNotes__c', endpointAndPayloadsApiNameMap);


        Boolean eventCreation = MSN_GenericPlatformEventUtility.publishEvents(platformEvents);

        // Comment from BC: why we need to use a queueable job to make a future callout below? Instead, we could jus use
        // the publishEvents method in MSN_GenericPlatformEventUtility. 
        // the only concern is for a future callout to make another future callout

        // publish platform events
        // if(!platformEvents.isEmpty()) {
        //     Id jobId = System.enqueueJob(new MSN_Integration(platformEvents));
        //     MSN_Integration.integrationQueued = true;
        // }

    }

}