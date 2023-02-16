/**
 * @File Name          : MSN_ServiceAppointmentTriggerHelper.cls
 * @Description        : Trigger Helper for ServiceAppointment
 * @Author             : David Azzi
 * @Group              : 
 * @Last Modified By   : David Azzi
 * @Last Modified On   : 01/12/2021
 * @Modification Log   : 
 * Ver      Date            Author                  Modification
 * 1.0      01/12/2021      David Azzi              Initial Version
 * 2.0      26/04/2022      Sahil Wadhwa            Add labour hour split
**/

public class MSN_ServiceAppointmentTriggerHelper {

    public static void updateSideOfStreet(List<ServiceAppointment> newSAs, Map<Id, SObject> oldItems)
    {
        
        for(ServiceAppointment newSA : newSAs )
        {
            ServiceAppointment oldSA = (oldItems != null) ? (ServiceAppointment) oldItems.get(newSA.Id) : new ServiceAppointment(Street = '123fakestreet456');
            if ( newSA.Street != oldSA.Street)
            {
                newSA.SideOfStreet__c = MSN_Utility.OddsOrEvens(newSA.Street);
            }
        }
    }

    public static void updateWOStatusOnJobCompletion(List<ServiceAppointment> newSAs)
    {
		// List of work orders to update
        List<WorkOrder> wosToUpdate = new List<WorkOrder>();

        //create map of Parent WO Id and list of child SA
        Map<Id, List<ServiceAppointment>> parentWoIdSAs = new Map<Id, List<ServiceAppointment>>();
        Set<Id> parentWoIds = new Set<Id>();
        Set<Id> newSAIds = new Set<Id>();
        for (ServiceAppointment sa : newSAs )
        {
            if ( !parentWoIdSAs.containsKey(sa.ParentRecordId) )
            {
                parentWoIdSAs.put(sa.ParentRecordId, new List<ServiceAppointment>());
            }
            parentWoIdSAs.get(sa.ParentRecordId).add(sa);
            newSAIds.add(sa.Id);
        }
        System.debug('parentWoIdSAs : '+parentWoIdSAs);
        // parentWoIds.addAll(parentWoIdSAs.keySet());
        
        for(WorkOrder wo : [SELECT Id 
                            FROM WorkOrder 
                            WHERE Id IN: parentWoIdSAs.keySet() 
                            AND StatusCategory != 'Completed' 
                            AND StatusCategory != 'Canceled' 
                            AND StatusCategory != 'Closed']) {
            parentWoIds.add(wo.Id);
        }

        System.debug('@parentWoIds : '+parentWoIds);

        //Get all child WOs of ParentWO Id Keyset and place in a map childWoIdParentWoId
        Map<Id, List<WorkOrder>> parentWoToChildWoMap = new Map<Id, List<WorkOrder>>();
        
        List<WorkOrder> chilWorkOrderList = [SELECT Id,ParentWorkOrderId,Status FROM WorkOrder WHERE ParentWorkOrderId IN: parentWoIds AND Is_Reinstatement__c = false];

        for(WorkOrder wo : chilWorkOrderList)
        {
            if ( !parentWoToChildWoMap.containsKey(wo.ParentWorkOrderId) )
            {
                parentWoToChildWoMap.put(wo.ParentWorkOrderId, new List<WorkOrder>());
            }
            parentWoToChildWoMap.get(wo.ParentWorkOrderId).add(wo);
        }

        //Get all SAs related to childWo keyset, add to SA List on Parent WO Map
        for(ServiceAppointment sa :  [SELECT Status, ParentRecordId, StatusCategory FROM ServiceAppointment WHERE ParentRecordId IN: parentWoIds AND Id NOT IN: newSAIds])
        {
            parentWoIdSAs.get(sa.ParentRecordId).add(sa);
        }

        //loop through each SA list and count Completed - if all completed, parentwo.status = completed and add to updated WO List
        for(Id parentWoId : parentWoIdSAs.keySet() )
        {
            if(parentWoIds.contains(parentWoId)) {
                Integer counter = 0;
                for(ServiceAppointment sa : parentWoIdSAs.get(parentWoId) ) {
                    if ( ( sa.Status == 'Completed' || sa.status == 'Canceled' || sa.Status == 'Cannot Complete' )
                        ||  (sa.StatusCategory == 'Completed' || sa.StatusCategory == 'Canceled' || sa.StatusCategory == 'Cannot Complete' )) {
                        counter++;
                    }
                }

                if(!parentWoToChildWoMap.isEmpty() && parentWoToChildWoMap.containsKey(parentWoId)) {
                    for(WorkOrder wo:parentWoToChildWoMap.get(parentWoId)) {

                        if(wo.Status == 'Ready for Review' || wo.Status == 'Completed'){
                            counter++;
                        }
                    }
                }

                Integer totalCount = 0;
                if(!parentWoToChildWoMap.isEmpty() && parentWoToChildWoMap.containsKey(parentWoId)){
                    totalCount = parentWoIdSAs.get(parentWoId).size() + parentWoToChildWoMap.get(parentWoId).size();
                }
                else {
                    totalCount = parentWoIdSAs.get(parentWoId).size() ;
                }

                System.debug('@count: ' + counter);
                System.debug('@totalCount: ' + totalCount);
                
                if ( counter == totalCount && MSN_Utility.getObjectNameFromId(parentWoId) == 'WorkOrder' )
                {
                    WorkOrder wo = new WorkOrder(Id = parentWoId, Status = 'Ready for Review');
                    wosToUpdate.add(wo);
                }
            }
        }

        if ( wosToUpdate.size() > 0 )
        {
            Database.update(wosToUpdate);
        }
    }

    //get all dispatched items, and recalculate WorkStep answers for Spotcode Mapping
    public static void updateUnansweredWorkPlanAnswers(List<ServiceAppointment> newSAs)
    {
        Set<Id> woIds = new Set<Id>();
        for(ServiceAppointment sa : newSAs )
        {
            if ( sa.Status == 'Dispatched' ){
                woIds.add(sa.ParentRecordId);
            }
        }

        List<WorkStep> wsteps = [SELECT MSN_WorkStep_Answer__c, WorkOrderId, MSN_SPOT_Code__c
                                FROM WorkStep
                                WHERE WorkOrderId IN: woIds ];

        MSN_WorkStepTriggerHelper.autofillWorkStepAnswer(wsteps);
    }
    
    
}