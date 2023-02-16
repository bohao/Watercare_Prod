/**
 * @File Name          : MSN_ProductConsumedTriggerHandler.cls
 * @Description        : Trigger handler for Parts and Labor
 * @Author             : Sahil Wadhwa
 * @Modification Log   : 
 * Ver      Date            Author                  Modification
 * 1.0      11/05/2022      Sahil Wadhwa             Initial Version
**/
public class MSN_ProductConsumedTriggerHandler implements ITriggerHandler {
	
    // Allows unit tests (or other code) to disable this trigger for the transaction
    public static Boolean TriggerDisabled = false;
    
    /*
        Checks to see if the trigger has been disabled either by custom setting or by running code
    */
    public Boolean IsDisabled() {
        return false;
    }
    
    public void BeforeInsert(List<SObject> newItems) {
    }
    
    public void BeforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        MSN_ProductConsumedTriggerHelper.updatePreviousQuantity(newItems,oldItems);
        MSN_ProductConsumedTriggerHelper.uncheckSentToEam(newItems,oldItems);
    } 
    public void BeforeDelete(Map<Id, SObject> oldItems) {}  
    public void AfterInsert(Map<Id, SObject> newItems) {
        // MSN_ProductConsumedTriggerHelper.createOutboundIntegration(newItems.values(),'insert');
        MSN_ProductConsumedTriggerHelper.createOutboundIntegration((Map<Id, ProductConsumed>)newItems, null);
    }      
    public void AfterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        // MSN_ProductConsumedTriggerHelper.createOutboundIntegration(newItems.values(),'update');
        MSN_ProductConsumedTriggerHelper.createOutboundIntegration((Map<Id, ProductConsumed>)newItems, (Map<Id, ProductConsumed>)oldItems);
    } 
    public void AfterDelete(Map<Id, SObject> oldItems) {
        // MSN_ProductConsumedTriggerHelper.createOutboundIntegration(oldItems.values(),'delete');
        MSN_ProductConsumedTriggerHelper.createOutboundIntegration(null, (Map<Id, ProductConsumed>)oldItems);
    } 
    public void AfterUndelete(Map<Id, SObject> oldItems) {}
}