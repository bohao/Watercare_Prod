trigger MSN_WorkStepAnswerTrigger on MSN_WorkStepAnswer__c (before insert, before update, before delete, 
                                                            after insert, after update, after delete, 
                                                            after undelete) 
{
    // disable it because there is no logic in it
    // TriggerDispatcher.Run(new MSN_WorkStepAnswerTriggerHandler());
}