public without sharing class MSN_CompletedPlannedMaintenanceWoReq {
	public String TransactionID;	//1234567890876
	public String WorkOrderNo;	//243546576
	public String UpdateType;	//string
	public static MSN_CompletedPlannedMaintenanceWoReq parse(String json){
		return (MSN_CompletedPlannedMaintenanceWoReq) System.JSON.deserialize(json, MSN_CompletedPlannedMaintenanceWoReq.class);
	}
}