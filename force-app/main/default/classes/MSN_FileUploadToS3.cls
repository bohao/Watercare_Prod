/**
 * @File Name          : MSN_FileUploadToS3.cls
 * @Description        : Apex class to upload, list and retrieve file to Amazon S3. 
 *                      Note: This is a prototype to test SF ability to connect, upload and retrieve files from and to S3.
 *                      The prototype has been tested successfully as below but everything is hardcoded. 
 *                      Moving forward, an UI and apex functions/methods needed to upload file from personal devices with 
 *                      file content encoding capability. 
 * @Author             : Bohao Chen         
 * Ver      Date            Author                  Modification
 * 1.0      21/11/2022      Bohao Chen              Initial Version
**/
public with sharing class MSN_FileUploadToS3 {
    // TODO:
    /*public static void listFile() {
        
    }*/
    
    public static void uploadFile() {
        AWSCallout.callSTSAssumeRole('PUT', 'https://s3.ap-southeast-2.amazonaws.com/watercaredev-files-to-idm/bcTest.txt', 'hello world', 's3');
    }

    public static void retrieveFile() {
        AWSCallout.callSTSAssumeRole('GET', 'https://s3.ap-southeast-2.amazonaws.com/watercaredev-files-to-idm/bcTest.txt', '', 's3');
    }
}