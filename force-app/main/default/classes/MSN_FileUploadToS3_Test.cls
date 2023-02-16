/**
 * @File Name          : MSN_FileUploadToS3_Test.cls
 * @Description        : Test class for MSN_FileUploadToS3.cls
 * @Author             : Bohao Chen
 * Ver      Date            Author                  Modification
 * 1.0      25/01/2023      Bohao Chen           initial version
**/

@isTest
public class MSN_FileUploadToS3_Test {
    static testMethod void test() {
        Test.setMock(HttpCalloutMock.class, new AWSWebServiceMock_Test());
        MSN_FileUploadToS3.uploadFile();
        MSN_FileUploadToS3.retrieveFile();
    }
}