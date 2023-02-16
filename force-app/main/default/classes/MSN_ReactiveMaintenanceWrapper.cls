/**
 * @File Name          : MSN_ReactiveMaintenanceWrapper.cls
 * @Description        : Wrapper class for WO Reactive Maintenance RestResource - INBOUND
 * @Author             : Bohao Chen
 * @Group              : 
 * @Last Modified By   : Bohao Chen
 * @Last Modified On   : 20/10/2022
 * @Modification Log   : 
 * Ver      Date            Author                  Modification
 * 1.0      20/10/2022      Bohao Chen              Initial Version
**/
public class MSN_ReactiveMaintenanceWrapper {
	public String TransactionID;	//fc39f4a2-1730-4312-b814-b15f8ae34a0f
	public String WorkOrderNo;	//1234567890
	public String ContractorCode;	//MSN
	public String OrgID;	//string
	public String Contract;	//string
	public CallDetails CallDetails;
	public Address Address;
	public Asset Asset;
	public String Location;	//string
	public String ContractorArea;	//string
	public String ServiceArea;	//Wastewater
	public String ProblemCode;	//string
	public String ProblemDescription;	//string
	public Integer Priority;	//1
	public String Comments;	//string
	public String RestoreServiceDueDate;	//2019-04-17T12:30:00
	public String OnsiteDueDate;	//2019-04-17T12:30:00
	public String CompletionDueDate;	//2019-04-17T12:30:00
	public String ContactRequestor;
	public class CallDetails {
		public RequestorInfo RequestorInfo;
		public String CallDate;	//2019-04-17T12:30:00
		public String CallTakenBy;	//string
	}
	public class RequestorInfo {
		public IndividualName IndividualName;
		public ContactDetails ContactDetails;
		public Address Address;
	}
	public class IndividualName {
		public String Title;	//string
		public String FirstName;	//string
		public String MiddleName;	//string
		public String LastName;	//string
	}
	public class ContactDetails {
		public String PhoneNo;	//string
		public String PhoneNoAlternative;	//string
		public String Email;	//string
	}
	public class Address {
		public String FlatNo;	//string
		public String StreetNo;	//string
		public String StreetName;	//string
		public String Suburb;	//string
		public String Postcode;	//string
		public String City;	//string
		public String Country;	//string
		public cls_GPSCoordinates GPSCoordinates;
	}
	public class cls_GPSCoordinates {
		public String Northing;	//string
		public String Easting;	//string
	}
	public class Asset {
		public String AssetKey;	//string
		public String AssetTypeCode;	//string
		public String AssetName;	//string
	}
}