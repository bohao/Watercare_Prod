public class MSN_LNPayloadData {
	public String TransactionID;	//7936 
	public String ItemID;	//100069
	public String WarehouseID;	//OF0001
    public String WarehouseName; //New Market Head Offices
    public String UnitCode; //EA
    public Double Quantity; //4
	public String Success;	//true
	public static MSN_LNPayloadData parse(String json){
		return (MSN_LNPayloadData) System.JSON.deserialize(json, MSN_LNPayloadData.class);
	}
}