/**
 * @File Name          : MSN_WorkOrderLineItemTriggerHandler.cls
 * @Description        : Trigger Handler for WorkOrderLineItem
 * @Author             : David Azzi
 * @Group              : 
 * @Last Modified By   : David Azzi
 * @Last Modified On   : 01/02/2022
 * @Modification Log   : 
 * Ver      Date            Author                  Modification
 * 1.0      01/02/2022      David Azzi              Initial Version
**/
public class MSN_WorkOrderLineItemTriggerHandler implements ITriggerHandler{
    // Allows unit tests (or other code) to disable this trigger for the transaction
    public static Boolean TriggerDisabled = false;
    
    /*
        Checks to see if the trigger has been disabled either by custom setting or by running code
    */
    public Boolean IsDisabled()
    {
        return false;
    }
    
    public void BeforeInsert(List<SObject> newItems) {}
    
    public void BeforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {}
         
    public void BeforeDelete(Map<Id, SObject> oldItems) {}  
    public void AfterInsert(Map<Id, SObject> newItems) {
        MSN_WorkOrderLineItemTriggerHelper.callChildWorkOrderToIntegration((Map<Id, WorkOrderLineItem>)newItems);
        MSN_JobNoteUtility.createJobNotes(newItems, null);
    }      
    public void AfterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        MSN_JobNoteUtility.createJobNotes(newItems, oldItems);
        MSN_WorkOrderLineItemTriggerHelper.updateUnansweredWorkPlanAnswers(newItems.values());
        MSN_WorkOrderLineItemTriggerHelper.updateWorkOrderLineItemIntegration(newItems,oldItems);
    } 
    public void AfterDelete(Map<Id, SObject> oldItems) {} 
    public void AfterUndelete(Map<Id, SObject> oldItems) {}
}