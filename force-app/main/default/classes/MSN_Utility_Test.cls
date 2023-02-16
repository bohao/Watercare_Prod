/**
 * @File Name          : MSN_Utility_Test.cls
 * @Description        : Test class for MSN_Utility.cls
 * @Author             : Bohao Chen
 * Ver      Date            Author                  Modification
 * 1.0      25/01/2023      Bohao Chen           initial version
**/

@isTest
public class MSN_Utility_Test {

    static testMethod void test() {
        MSN_Utility.getCurrentLineNumber();
        Map<String, Schema.DisplayType> fieldAPINameToFieldTypeMap = MSN_Utility.fetchFieldTypesforObject('WorkOrder');
        Schema.DisplayType nameDt = fieldAPINameToFieldTypeMap.get('Name');
        Schema.DisplayType datetimeDt = fieldAPINameToFieldTypeMap.get('CreatedDate');
        Schema.DisplayType dateDt = fieldAPINameToFieldTypeMap.get('Date_of_Application__c');
        Schema.DisplayType booleanDt = fieldAPINameToFieldTypeMap.get('MSN_Contact_Requestor__c');
        Schema.DisplayType decimalDt = fieldAPINameToFieldTypeMap.get('Duration');
        Schema.DisplayType phoneDt = fieldAPINameToFieldTypeMap.get('MSN_Contact_Phone__c');
        Schema.DisplayType integerDt = fieldAPINameToFieldTypeMap.get('MinimumCrewSize');
        
        MSN_Utility.transformAndMapFieldValues(nameDt, 'abc');
        MSN_Utility.transformAndMapFieldValues(datetimeDt, '2023-01-25T12:00:00.000Z');
        MSN_Utility.transformAndMapFieldValues(dateDt, '2023-01-25');
        MSN_Utility.transformAndMapFieldValues(booleanDt, 'true');
        MSN_Utility.transformAndMapFieldValues(decimalDt, '2.3');
        MSN_Utility.transformAndMapFieldValues(phoneDt, '0456874596');
        MSN_Utility.transformAndMapFieldValues(integerDt, '2');

        MSN_Utility.setStringToDateFormat('2023-01-25');
        MSN_Utility.setStringToDateFormat('2023-25-01');
        MSN_Utility.setStringToDateFormat('01-25-2023');
        MSN_Utility.setStringToDateFormat('25-01-2023');
        MSN_Utility.setStringToDateFormat('2023-01-25 12:00:00.000Z');

        MSN_Utility.doesObjectExist('WorkOrder');
        MSN_Utility.doesApiNameOfFieldExist('WorkOrder', 'MinimumCrewSize');
        MSN_Utility.doesApiNameOfFieldExist('WorkOrder', 'MinimumCrewSize1');
        Set<String> fieldAPINameList = new Set<String>();
        fieldAPINameList.add('Id');
        fieldAPINameList.add('Name');
        MSN_Utility.buildFieldsForSOQLQuery(fieldAPINameList, 'WorkOrder');
        MSN_Utility.buildFieldsForSOQLQuery(fieldAPINameList, '');
        MSN_Utility.getObjectNameFromId('0gq0p000000CasLAAS');


        String stringWithPlaceholder = '"partCode": "{{ProductItem.MSN_LN_Material_Key__c}}","bin": "*","lot": "*","transactionQty": {{QuantityConsumed}}}],';
        Set<String> fieldNames = MSN_Utility.getFieldPlaceholders(stringWithPlaceholder, '\\{[^}]*\\}', '{', '}');
        System.assert(fieldNames.contains('ProductItem.MSN_LN_Material_Key__c'));
        System.assert(fieldNames.contains('QuantityConsumed'));

        String odd = MSN_Utility.OddsOrEvens('17');
        System.assertEquals('Odd', odd);
        String even = MSN_Utility.OddsOrEvens('20');
        System.assertEquals('Even', even);

        Integration_Endpoint__mdt awsAssumeRoleEndpoint = MSN_Utility.getEndpointSetting('AWS_Assume_Role');

        MSN_Utility.convertToDatetime('2023-01-25T12:00:00.000Z');

    }
}