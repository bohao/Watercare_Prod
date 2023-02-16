/**
 * @File Name          : MSN_UpdateReactiveMaintenanceWrapper.cls
 * @Description        : Wrapper class for Updating WO Reactive Maintenance RestResource - INBOUND
 * @Author             : Bohao Chen
 * @Group              : 
 * @Last Modified By   : Bohao Chen
 * @Last Modified On   : 26/10/2022
 * @Modification Log   : 
 * Ver      Date            Author                  Modification
 * 1.0      26/10/2022      Bohao Chen              Initial Version
**/
public class MSN_UpdateReactiveMaintenanceWrapper{
	public String TransactionID;	//12345678909458374
	public String WorkOrderNo;	//128347563
	public String ContractorReference;	//{Salesforce WorkOrder.Name}
	public String ContractorCode;	//MSN
	public String UpdateType;	//COMMTW
	public String UpdateDate;	//2019-04-17T12:30:00
	public String UpdatedBy;	//AAIYUB
	public String Comments;	//WATERCARE: Hi, the fault that you reported on 52 Mokoia RD on SR15322623 has been repaired. Please allow 15-21 days for reinstatement work to be completed

	/*static testMethod void testParse() {
		String json=		'{'+
		'  "TransactionID": "12345678909458374",'+
		'  "WorkOrderNo": "128347563",'+
		'  "ContractorReference": "{Salesforce WorkOrder.Name}",'+
		'  "ContractorCode": "MSN",'+
		'  "UpdateType": "COMMTW",'+
		'  "UpdateDate": "2019-04-17T12:30:00",'+
		'  "UpdatedBy": "AAIYUB",'+
		'  "Comments": "WATERCARE: Hi, the fault that you reported on 52 Mokoia RD on SR15322623 has been repaired. Please allow 15-21 days for reinstatement work to be completed"'+
		'}';
		MSN_UpdateReactiveMaintenanceWrapper obj = parse(json);
		System.assert(obj != null);
	}*/
}