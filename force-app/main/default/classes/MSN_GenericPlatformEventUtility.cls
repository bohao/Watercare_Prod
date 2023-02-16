/**
 * @File Name          : MSN_GenericPlatformEventUtility.cls
 * @Description        : Creation of Platform Events
 * @Author             : David Azzi
 * @Group              : 
 * @Last Modified By   : David Azzi
 * @Last Modified On   : 15/02/2022
 * @Modification Log   : 
 * Ver      Date            Author                  Modification
 * 1.0      15/02/2022      David Azzi              Initial Version
**/
public class MSN_GenericPlatformEventUtility {

    /*
        David Notes
        I created this class as a Generic Utility to incorporate the Listening side of the PlatformEvents
        as it opens up for much further expansion and the proper use of Platform Events inside and outside Salesforce
    */

    private static final Integer MAX_RETRY_COUNT = 1;    
    
    
    public static Boolean publishEvents(List<sObject> events){
        return publishEvents(events, 0);
    }
    
    // retry failed events for three time and log error if its failed after three retry
    public static Boolean publishEvents(List<sObject> events, Integer retryCount) {

        Boolean isSuccess = false;
        List<sObject> failedEvents =  new List<sObject>();

        if (events == null || events.isEmpty())
            return isSuccess;

        System.debug('Events size : ' + events.size());
        
        List<Database.SaveResult> results = EventBus.publish(events);
    	Integer counter = 0;
        for (Database.SaveResult sr : results) {
            if (sr.isSuccess()) {
                System.debug(String.format('Successfully published event : {0}', new List<Object>{sr.getId()}));
                isSuccess = true;
            } else {
                for (Database.Error err : sr.getErrors()) {
                    failedEvents.add(events.get(counter));
                    System.debug(String.format('Error status code : {0}, message : {1}', new List<Object>{err.getStatusCode(), err.getMessage()}));
                }
                isSuccess = false;
            } 
            counter++;
        }
        
        if(!failedEvents.isEmpty()){
            if(retryCount < MAX_RETRY_COUNT){
                publishEvents(failedEvents, retryCount++);
            }
            else{
                MSN_HandleErrorsException.insertCustomErrorLog('Failed to Publish Platform Events.', '', 'MSN_GenericPlatformEventUtility', JSON.serialize(failedEvents));
            }
        }
       
        return isSuccess;
    }
}