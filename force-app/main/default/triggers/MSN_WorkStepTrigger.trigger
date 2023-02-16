trigger MSN_WorkStepTrigger on WorkStep (before insert, before update, before delete, 
                                                            after insert, after update, after delete, 
                                                            after undelete) 
{

    TriggerDispatcher.Run(new MSN_WorkStepTriggerHandler());
}