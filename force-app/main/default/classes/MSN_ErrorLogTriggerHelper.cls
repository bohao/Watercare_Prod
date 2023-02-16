/**
 * @File Name          : MSN_ErrorLogTriggerHelper.cls
 * @Description        : Helper class for MSN_ErrorLogTrigger
 * @Author             : Sahil
 * @Group              : 
 * @Last Modified By   : Bohao Chen
 * @Last Modified On   : 29/8/2021
 * @Modification Log   : 
 * Ver      Date            Author                  Modification
 * 1.0      24/8/2021      Sahil              Initial Version
**/
public class MSN_ErrorLogTriggerHelper {
    public static void callErrorLogActions(List<Error_Log__c> errorLogList) {
        
		Set<Id> messageTypeIdSet = new Set<Id>();

		// Loop through the logs to find the message type
        // errorLogList = [SELECT Message_Type__c, MSN_Error_Message__c, Message_Type__r.Name, MSN_Payload__c
        //                 FROM Error_Log__c 
        //                 WHERE Id IN: errorLogList
        //                 AND Message_Type__c != NULL];

		for(Error_Log__c err : errorLogList) {
            messageTypeIdSet.add(err.Message_Type__c);
		}
			
		// Now get the action type
		Map<Id,List<Message_Action__c>> mapMesTypeToMesAction = new Map<Id,List<Message_Action__c>>();

        for(Message_Action__c action : [SELECT Name, Message_Type__c, Type__c, Endpoint__c
                                        FROM Message_Action__c 
                                        WHERE Message_Type__c IN :messageTypeIdSet]) {

			if(!mapMesTypeToMesAction.containsKey(action.Message_Type__c)) {
                mapMesTypeToMesAction.put(action.Message_Type__c, new List<Message_Action__c>());
			}

            mapMesTypeToMesAction.get(action.Message_Type__c).add(action);
		}
			
        System.debug('@sahil messageActionList : '+mapMesTypeToMesAction);

		for(Error_Log__c err : [SELECT MSN_Error_Message__c, Message_Type__r.Name, MSN_Payload__c, Message_Type__c 
                                FROM Error_Log__c 
                                WHERE Id IN: errorLogList]) {

            System.debug('@sahil err.Message_Type__c : ' + err.Message_Type__c);	

            // Get the action list for each error and call the class
            // List<Message_Action__c> actionsToCall = mapMesTypeToMesAction.get(err.Message_Type__c);
            
            // System.debug('@sahil actionsToCall : '+actionsToCall);	

            // if(actionsToCall != null){
            if(!mapMesTypeToMesAction.isEmpty() && mapMesTypeToMesAction.containsKey(err.Message_Type__c)) {
                for (Message_Action__c action : mapMesTypeToMesAction.get(err.Message_Type__c)) {

                    // send MS Team Notification if action type is 'MS Team Notification'
                    // if(action.Name.equalsIgnoreCase('Send Teams Noficiation')) {
                    if(action.Type__c.equalsIgnoreCase('MS Team Notification')) {
                        MSN_TeamsIntegration teams = new MSN_TeamsIntegration(err, action.Endpoint__c);
                        System.enqueueJob(teams);  
                    }
                    // TODO: email notification for Message_Type__c 'email notification'
                    //else if(action == 'abc') {
                        // Call class for abc
                    //}
                }
            }
            // }
		}        
    }
}