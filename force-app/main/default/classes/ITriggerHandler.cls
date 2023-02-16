/**
 * @File Name          : ITriggerHandler.cls
 * @Description        : Interface implementation of trigger logic. 
 * @Author             : David Azzi
 * @Group              : 
 * @Last Modified By   : David Azzi
 * @Last Modified On   : 01/12/2021
 * @Modification Log   : 
 * Ver      Date            Author                  Modification
 * 1.0      01/12/2021      David Azzi              Initial Version
**/
public interface ITriggerHandler {

    void BeforeInsert(List<SObject> newItems);
    
    void BeforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems);
    
    void BeforeDelete(Map<Id, SObject> oldItems);
    
    void AfterInsert(Map<Id, SObject> newItems);
    
    void AfterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems);
    
    void AfterDelete(Map<Id, SObject> oldItems);
    
    void AfterUndelete(Map<Id, SObject> oldItems);
    
    Boolean IsDisabled();
    
}