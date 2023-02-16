trigger MSN_ErrorLogTrigger on Error_Log__c (before insert,after insert,after update,after delete,after undelete) {
	TriggerDispatcher.Run(new MSN_ErrorLogTriggerHandler());
}