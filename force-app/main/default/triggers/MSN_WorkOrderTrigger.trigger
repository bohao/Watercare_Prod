/**
 * @File Name          : MSN_WorkOrderTrigger.cls
 * @Description        : Trigger for WorkOrder
 * @Author             : David Azzi
 * @Group              : 
 * @Last Modified By   : David Azzi
 * @Last Modified On   : 01/12/2021
 * @Modification Log   : 
 * Ver      Date            Author                  Modification
 * 1.0      01/12/2021      David Azzi              Initial Version
**/
trigger MSN_WorkOrderTrigger on WorkOrder (before insert, before update, before delete, 
                                            after insert, after update, after delete, 
                                            after undelete) 
{
    TriggerDispatcher.Run(new MSN_WorkOrderTriggerHandler());
}