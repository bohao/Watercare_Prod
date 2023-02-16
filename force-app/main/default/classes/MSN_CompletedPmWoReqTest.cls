@IsTest
public class MSN_CompletedPmWoReqTest {
    @IsTest
    static void testParseResponse(){
        String json=		'{'+
        '  "TransactionID": "1234567890876",'+
        '  "WorkOrderNo": "243546576",'+
        '  "ResultCode": "COMP",'+
        '  "Success": "true"'+
        '}';

        Test.startTest();

        MSN_CompletedPlannedMaintenanceWoReq obj = MSN_CompletedPlannedMaintenanceWoReq.parse(json);
        Test.stopTest();

        System.assert(obj != null);
    }
}