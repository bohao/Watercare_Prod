/**
 * @File Name          : MSN_TeamsIntegration.cls
 * @Description        : Queueable job to send out Microsoft Team Notification
 * @Author             : Sahil
 * @Modification Log   : 
 * Ver      Date            Author                  Modification
 * 1.0      24/8/2022      Sahil              Initial Version
**/
public class MSN_TeamsIntegration implements Queueable {
    private Error_Log__c errLog;
    private String endpoint;


    public MSN_TeamsIntegration(Error_Log__c errorLog, String endpoint) {
        this.errLog = errorLog;
        this.endpoint = endpoint;
    }

	public void execute(QueueableContext context) {
        String message = String.isBlank(errLog.MSN_Error_Message__c) ? ' ' : errLog.MSN_Error_Message__c.remove('"').remove('{').remove('}');
        String title = String.isBlank(errLog.Message_Type__r.Name) ? ' ' : errLog.Message_Type__r.Name + ' Failed';
        String link = Url.getOrgDomainUrl().toExternalForm() + '/' + errLog.Id;
        String payload = String.isBlank(errLog.MSN_Payload__c) ? ' ' : errLog.MSN_Payload__c.remove('"').remove('{').remove('}');
        if(!Test.isRunningTest()) {
            callTeams(message, title, link, payload, endpoint); 
        }
    }
    
    @future(callout=true)
    public static void callTeams(String message, String title, String link, String payload, String endpoint) {  
        
        // construct MS team notification payload
        MSN_MsTeamNotificationPayloadWrapper msTeamNotificationPayload = new MSN_MsTeamNotificationPayloadWrapper();
        msTeamNotificationPayload.type = 'MessageCard';
        msTeamNotificationPayload.summary = title ;
        msTeamNotificationPayload.title = title;
        msTeamNotificationPayload.text = message;
        List<MSN_MsTeamNotificationPayloadWrapper.Section> sessions = new List<MSN_MsTeamNotificationPayloadWrapper.Section>();
        sessions.add(new MSN_MsTeamNotificationPayloadWrapper.Section(payload));
        sessions.add(new MSN_MsTeamNotificationPayloadWrapper.Section(link));
        msTeamNotificationPayload.sections = sessions;

        String body = JSON.serialize(msTeamNotificationPayload);
        body = body.replace('"type":', '"@type":');

        // Call the API
        HttpRequest req = new HttpRequest(); 
		req.setEndpoint(endpoint); 
        req.setMethod('POST');      
        
        System.debug('body : '+body);
		req.setBody(body);
        req.setHeader('Content-type', 'application/json');
        req.setTimeout(20000);

		Http http = new Http();
		HTTPResponse res = http.send(req);
        System.debug('@resp status: ' + res.getStatus());
		System.debug('@resp body: ' + res.getBody());
    }
}