/**
 * @File Name          : MSN_JobNoteTriggerHandler.cls
 * @Description        : Trigger Handler for MSN_JobNote__c
 * @Author             : David Azzi
 * @Group              : 
 * @Last Modified By   : David Azzi
 * @Last Modified On   : 17/01/2022
 * @Modification Log   : 
 * Ver      Date            Author                  Modification
 * 1.0      17/01/2022      David Azzi              Initial Version
**/
public class MSN_JobNoteTriggerHandler implements ITriggerHandler{
    // Allows unit tests (or other code) to disable this trigger for the transaction
    public static Boolean TriggerDisabled = false;
    
    /*
        Checks to see if the trigger has been disabled either by custom setting or by running code
    */
    public Boolean IsDisabled()
    {
        return false;
    }
    
    public void BeforeInsert(List<SObject> newItems) 
    {
    }
    
    public void BeforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){} 
    public void BeforeDelete(Map<Id, SObject> oldItems) {}  
    public void AfterInsert(Map<Id, SObject> newItems) {
        MSN_JobNoteTriggerHelper.triggerOutboundIntegration(newItems);
        MSN_JobNoteTriggerHelper.updateJobNotesToWorkOrder((List<MSN_JobNotes__c>) newItems.values() );
    }      
    public void AfterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {     
        MSN_JobNoteTriggerHelper.triggerOutboundIntegration(newItems);
        MSN_JobNoteTriggerHelper.updateJobNotesToWorkOrder((List<MSN_JobNotes__c>) newItems.values() );
    } 
    public void AfterDelete(Map<Id, SObject> oldItems) {
        MSN_JobNoteTriggerHelper.triggerOutboundIntegration(oldItems);

    } 
    public void AfterUndelete(Map<Id, SObject> oldItems) {}
    
    
}