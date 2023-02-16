/**
 * @File Name          : MSN_ServiceAppointmentTriggerHandler.cls
 * @Description        : Trigger Handler for ServiceAppointment
 * @Author             : David Azzi
 * @Group              : 
 * @Last Modified By   : David Azzi
 * @Last Modified On   : 01/12/2021
 * @Modification Log   : 
 * Ver      Date            Author                  Modification
 * 1.0      01/12/2021      David Azzi              Initial Version
**/
public class MSN_ServiceAppointmentTriggerHandler implements ITriggerHandler{

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
            //MSN_ServiceAppointmentTriggerHelper.updateSideOfStreet((List<ServiceAppointment>) newItems, null );
        }
        
        public void BeforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) 
        {
            MSN_ServiceAppointmentTriggerHelper.updateSideOfStreet((List<ServiceAppointment>) newItems.values(), oldItems );
        } 
        public void BeforeDelete(Map<Id, SObject> oldItems) {}  
        public void AfterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
            MSN_ServiceAppointmentTriggerHelper.updateUnansweredWorkPlanAnswers((List<ServiceAppointment>) newItems.values());
            MSN_ServiceAppointmentTriggerHelper.updateWOStatusOnJobCompletion((List<ServiceAppointment>) newItems.values());
            MSN_JobNoteUtility.createJobNotes(newItems, oldItems);
        } 
    
        public void AfterDelete(Map<Id, SObject> oldItems) {} 
        public void AfterUndelete(Map<Id, SObject> oldItems) {}
        
        public void AfterInsert(Map<Id, SObject> newItems) {}      
}