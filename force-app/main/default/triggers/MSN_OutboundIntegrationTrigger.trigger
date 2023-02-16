trigger MSN_OutboundIntegrationTrigger on Outbound_Integration__e (after insert) {
	for (Outbound_Integration__e event : Trigger.New) {
        System.debug('Event trigger Method__c : ' + event.Method__c);
        System.debug('Event trigger EndPoint__c : ' + event.EndPoint__c);
        String payload = event.Payload__c.replace('eventId',event.EventUuid  );
        System.debug('Event trigger Payload__c : ' + payload);
        if(!Test.isRunningTest()) {
            AWSCallout.callSTSAssumeRole(event.Method__c, event.EndPoint__c, payload, 'execute-api');
        }
    }
}