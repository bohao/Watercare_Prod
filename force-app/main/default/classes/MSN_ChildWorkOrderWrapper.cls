public class MSN_ChildWorkOrderWrapper{

	public String TransactionID;	//123
	public String ContractorReference;	//string
	public String WorkOrderNo;	//string

	public static MSN_ChildWorkOrderWrapper parse(String json){
		return (MSN_ChildWorkOrderWrapper) System.JSON.deserialize(json, MSN_ChildWorkOrderWrapper.class);
	}

	/*static testMethod void testParse() {
		String json=		'{'+
		'  "TransactionID": "123",'+
		'  "ContractorReference": "string",'+
		'  "WorkOrderNo": "string"  '+
		'}';
		MSN_ChildWorkOrderWrapper obj = parse(json);
		System.assert(obj != null);
	}*/
}