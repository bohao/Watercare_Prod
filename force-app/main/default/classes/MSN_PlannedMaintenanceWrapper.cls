/**
 * @File Name          : MSN_PlannedMaintenanceWrapper.cls
 * @Description        : Wrapper class for WO PlannedMaintenance RestResource - INBOUND
 * @Author             : David Azzi
 * @Group              : 
 * @Last Modified By   : David Azzi
 * @Last Modified On   : 23/11/2021
 * @Modification Log   : 
 * Ver      Date            Author                  Modification
 * 1.0      23/11/2021      David Azzi              Initial Version
**/
public class MSN_PlannedMaintenanceWrapper {

    @AuraEnabled public String TransactionId;
    @AuraEnabled public String WorkOrderNo;
    @AuraEnabled public String Priority; 
    @AuraEnabled public String ContractorArea; 
    @AuraEnabled public String ServiceArea;
    @AuraEnabled public String Comments;
    @AuraEnabled public String ActivityCode;
    @AuraEnabled public String ActivityDescription;
    @AuraEnabled public String GroupNo;
    @AuraEnabled public String InitiatedBy;
    @AuraEnabled public String VariationNo;
    @AuraEnabled public String ActivityInstructions;
    @AuraEnabled public CallDetails CallDetails;
    @AuraEnabled public String Location; //Asset Location
    @AuraEnabled public String InitiatedDate;
    @AuraEnabled public String OnsiteDueDate;
    @AuraEnabled public String ScheduledDate;
    @AuraEnabled public String ObservationCode;
    @AuraEnabled public String Contract;

    //@AuraEnabled public List<Asset> Asset;
    @AuraEnabled public Asset Asset;

    public class CallDetails {
        @AuraEnabled public RequestorInfo RequestorInfo;
    }

    public class RequestorInfo {
        @AuraEnabled public ContactDetails ContactDetails;
    }

    public class ContactDetails {
        @AuraEnabled public Address Address;
    }

    public class Address{
        @AuraEnabled public String FlatNo;
        @AuraEnabled public String StreetNo;
        @AuraEnabled public String StreetName;
        @AuraEnabled public String Suburb;
        @AuraEnabled public String Postcode;
        @AuraEnabled public String City;
        @AuraEnabled public String Country;
    }

    public class Asset {
        @AuraEnabled public String AssetKey; //CompKey
        @AuraEnabled public String AssetTypeCode; //AssetType?
        @AuraEnabled public String AssetName;
    }

}