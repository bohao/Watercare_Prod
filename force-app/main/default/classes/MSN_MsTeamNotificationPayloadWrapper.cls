public class MSN_MsTeamNotificationPayloadWrapper{
	public String type;	//MessageCard // this is sepcial one that we need to convert this to @type
	public String summary;	//title
	public String title;	//title
	public String text;	//message
	public Section[] sections;
	public class Section {        
		public String text;	//payload
        public Section(String text) {
            this.text = text;
        }
	}

	/*public static MSN_MsTeamNotificationPayloadWrapper parse(String json){
		return (MSN_MsTeamNotificationPayloadWrapper) System.JSON.deserialize(json, MSN_MsTeamNotificationPayloadWrapper.class);
	}*/

	/*static testMethod void testParse() {
		String json=		'{'+
		' "@type":"MessageCard",'+
		'"summary":"title",'+
		'"title":"title",'+
		'"text": "message",'+
		'"sections": ['+
		'{'+
		'"text": "payload"'+
		'},'+
		'{'+
		'"text": "link"'+
		'}'+
		']'+
		'}';
		MSN_MsTeamNotificationPayloadWrapper obj = parse(json);
		System.assert(obj != null);
	}*/
}