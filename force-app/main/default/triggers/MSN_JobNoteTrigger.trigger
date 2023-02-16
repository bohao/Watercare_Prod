trigger MSN_JobNoteTrigger on MSN_JobNotes__c (before insert, before update, before delete, 
                                                            after insert, after update, after delete, 
                                                            after undelete) 
{

    TriggerDispatcher.Run(new MSN_JobNoteTriggerHandler());
}