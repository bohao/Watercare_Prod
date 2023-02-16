trigger MSN_WorkOrderLineItemTrigger on WorkOrderLineItem (before insert, before update, before delete, 
                                                            after insert, after update, after delete, 
                                                            after undelete)  {
    TriggerDispatcher.Run(new MSN_WorkOrderLineItemTriggerHandler());

}