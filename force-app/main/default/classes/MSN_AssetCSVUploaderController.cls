/**
 * @File Name          : MSN_AssetCSVUploaderController.cls
 * @Description        : MSN_lwc_AssetCSVUploader Controller - Asset Integration - import a CSV from an S3 Bucket and Upsert in to Assets. 
 * @Author             : David Azzi
 * @Group              : 
 * @Last Modified By   : David Azzi
 * @Last Modified On   : 23/11/2021
 * @Modification Log   : 
 * Ver      Date            Author                  Modification
 * 1.0      23/11/2021      David Azzi              Initial Version - JIRA: MSRS-109
**/
public class MSN_AssetCSVUploaderController {

    /*
        David Notes
        This file was thrown together as a temporary fix to create new Assets and update assets.
        It hasn't been fully-bulkified and tested with large quantities of Assets
        There is a high chance of a salesforce limitation being hit whether it is the Upsert limits or
        CPU Limits
    */

    @AuraEnabled
    public static Map<Asset, String> upsertFile(String base64Data, List<Map<String, String>> preMappedData) {

        //retrieve mapping information from LWC to speed up run as it is faster than getAssetMappingFromCustomMetadata
        Map<String, String> mapping = new Map<String, String>();
        String label = '';
        String fieldName = '';
        for(Integer i = 0; i < preMappedData.size(); i++){
            for(String key : preMappedData[i].keySet()){
                mapping.put(key, preMappedData[i].get(key));
                
                if ( key == 'label' ){
                    label = preMappedData[i].get(key);
                }
                if ( key == 'fieldName' ){
                    fieldName = preMappedData[i].get(key);
                }
                if(label != '' && fieldName != ''){
                    if ( MSN_Utility.doesApiNameOfFieldExist('Asset', fieldName ) ){
                        mapping.put(label, fieldName);
                        System.debug('Key: ' + label + '..Value: ' + fieldName);
                    }
                    label = '';
                    fieldName = '';
                }
            }
        }
        //Map<String, String> mapping = getAssetMappingFromCustomMetadata();
        Map<String,Schema.DisplayType> fieldAPINameToFieldTypeMap = MSN_Utility.fetchFieldTypesforObject('Asset');

        String data = JSON.deserializeUntyped(base64Data).toString();
        List<Asset> assetsToUpsert = new List<Asset>();
        Set<String> usedAssetTypes = new Set<String>();
        List<String> lstCSVLines = data.split('\n');

        Map<String, Integer> columnIndex = new Map<String, Integer>();
        List<String> csvColumnTitles = lstCSVLines[0].split(',');
        for (Integer i = 0; i < csvColumnTitles.size(); i++){
            if ( mapping.containsKey( csvColumnTitles[i] ) ){
                //if ( MSN_Utility.doesApiNameOfFieldExist('Asset', mapping.get(csvColumnTitles[i])) ){
                    columnIndex.put(csvColumnTitles[i], i);
                //}
            }
        }

        Integer counter = 0;
        for(Integer i = 1; i < lstCSVLines.size(); i++){          
            
            String csvLine = lstCSVLines[i];
            String prevLine = csvLine;

            List<String> csvRowData = new List<String>();
            csvRowData.addAll(filterCSVRowData(csvLine));

            Asset newAsset = new Asset();
            newAsset.Asset_Type__c = null;

            if ( mapping.size() > 0 ){
                for(String columnName : columnIndex.keySet() ){
                    if ( mapping.containsKey(columnName) ){
                        if ( String.isNotBlank(csvRowData[columnIndex.get(columnName)])){
                            newAsset.put(
                                mapping.get(columnName), 
                                MSN_Utility.transformAndMapFieldValues(
                                    fieldAPINameToFieldTypeMap.get(mapping.get(columnName)), 
                                    csvRowData[columnIndex.get(columnName)]
                                )
                            );
                        } else {
                            newAsset.put(
                                mapping.get(columnName), 
                                null
                            );
                        }
                    }
                }

                counter++;
                usedAssetTypes.add(newAsset.Asset_Type__c);

                newAsset.Name = newAsset.Asset_Type__c;
                newAsset.Name += String.isNotBlank(newAsset.Comp_Key__c) ? ' -' + newAsset.Comp_Key__c : '';
                newAsset.Name += String.isNotBlank(newAsset.SerialNumber) ? ' -' + newAsset.SerialNumber : '';
                newAsset.Name += String.isNotBlank(newAsset.House_Number__c) ? ' -' + newAsset.House_Number__c : '';
                newAsset.Name += String.isNotBlank(newAsset.Street_Name__c) ? ' -' + newAsset.Street_Name__c : '';
                newAsset.Name += String.isNotBlank(newAsset.Street_Type__c) ? ' -' + newAsset.Street_Type__c : '';
                
                assetsToUpsert.add(newAsset);
                // this has been commented out in QA. As far as i know, MSN_AssetCSVUploaderBatch hasn't been tested
                /*try {
                    if ( counter > 100 && assetsToUpsert.size() > 0 ){
                        Id batchJobId = Database.executeBatch(new MSN_AssetCSVUploaderBatch(assetsToUpsert));
                        assetsToUpsert = new List<Asset>();
                    }
                } catch ( Exception e){
                    MSN_HandleErrorsException.insertLogException(e, '', '');
                }*/
                
            }
        }
        
        //get all AssetTypes and add them to the asset
        Map<String, String> product2AssetTypes = new Map<String, String>();
        for(Product2 product : [SELECT Asset_Type__c FROM Product2 WHERE Asset_Type__c IN: usedAssetTypes ]){
            product2AssetTypes.put(product.Asset_Type__c, product.Id);
        }

        for(Asset aset : assetsToUpsert){
            aset.Product2Id = (product2AssetTypes.containsKey(aset.Asset_Type__c)) ? product2AssetTypes.get(aset.Asset_Type__c) : null;
        }

        Map<Asset, String> output = new Map<Asset, String>();
        if ( assetsToUpsert.size() > 0 ){
            Schema.SObjectField compkeyToken = Asset.Fields.Comp_Key__c;
            Database.UpsertResult[] srList = Database.upsert(assetsToUpsert,compkeyToken,false);
            Map<Id, List<Database.Error>> upsertErrors = new Map<id, List<Database.Error>>();
            for(Integer srIndex = 0; srIndex < srList.size(); srIndex++){
                if (srList[srIndex].isSuccess()) {
                    // Operation was successful
                    output.put(assetsToUpsert[srIndex], '' );
                }
                else {
                    // Operation failed, so get all errors    
                    upsertErrors.put( srList[srIndex].getId(), srList[srIndex].getErrors() );            
                    for(Database.Error err : srList[srIndex].getErrors()) {
                        System.debug('error has occurred in MSN_AssetCSVUploaderController.upsertFile:' + err.getStatusCode() + ': ' + err.getMessage());                    
                        System.debug('fields that affected this error: ' + err.getFields());
                        output.put(assetsToUpsert[srIndex],  + '(Row: ' + (srIndex+1) + ')' + err.getStatusCode() + ': ' + err.getMessage());
                    }
                }
            }
            if ( upsertErrors.size() > 0 ){
                MSN_HandleErrorsException.insertSaveResultErrors('', 
                                                                'Upserting Assets through the CSV Uploader', 
                                                                'MSN_AssetCSVUploaderController', 
                                                                'upsertFile',
                                                                MSN_Utility.getCurrentLineNumber(),
                                                                upsertErrors);
            }
        } 
        return output;
    }

    public static List<String> filterCSVRowData(String csvLine){
        Integer startIndex;
        Integer endIndex;
        List<String> output = new List<String>();

        //If line has Quotes, check to see if there is any commas in the quotes
        while(csvLine.indexOf('"') > -1){
            if(startIndex == null){
                startIndex = csvLine.indexOf('"');
                csvLine = csvLine.substring(0, startIndex) + ':quotes:' + csvLine.substring(startIndex+1, csvLine.length());
            }else{
                if(endIndex == null){
                    endIndex = csvLine.indexOf('"');
                    csvLine = csvLine.substring(0, endIndex) + ':quotes:' + csvLine.substring(endIndex+1, csvLine.length());
                }
            }
            
            if(startIndex != null && endIndex != null){
                String sub = csvLine.substring(startIndex, endIndex);
                sub = sub.replaceAll(',', ':comma:');
                csvLine = csvLine.substring(0, startIndex) + sub + csvLine.substring(endIndex, csvLine.length());
                startIndex = null;
                endIndex = null;
            }
        }

        for(String column : csvLine.split(',')){
            column = column.replaceAll(':quotes:', '').replaceAll(':comma:', ',');
            output.add(column);
        }

        return output;
    }

    //make 25/12/2021 11:00 to DateTime format: 2021/12/25 11:00
    /*public static String getCorrectDateTimeFormat(String oldDT){
        oldDT = oldDT.replace('/', '-');
        String modifiedDate = oldDT.substring(oldDT.length() - 6, oldDT.length() - 5) == ' ' ? oldDT + ':00' : oldDT;
        List<String> dtSplit = new List<String>();
        List<String> dateSplit = new List<String>();

        dtSplit.addAll(modifiedDate.split(' '));
        dateSplit.addAll(dtSplit[0].split('-'));
        
        return dateSplit[2] + '-' + dateSplit[1] + '-' + dateSplit[0] + ' ' + dtSplit[1];
    }*/

    @AuraEnabled
    public static Map<String, String> getAssetMappingFromCustomMetadata(){
        Map<String, String> output = new Map<String, String>();
        Integer dupeIndex = 0;
        for ( Asset_CSV_Mapping__mdt mapData : Asset_CSV_Mapping__mdt.getAll().values() ){
            if ( mapData.Is_Active__c == true && MSN_Utility.doesApiNameOfFieldExist('Asset', mapData.SF_Field_API_Name__c)){               
                String colName = mapData.CSV_Column_Name__c;
                if ( output.containsKey(mapData.CSV_Column_Name__c) ){
                    colName += '-Duplicate-' + String.valueOf(dupeIndex);
                    dupeIndex++;
                }
                output.put(colName, mapData.SF_Field_API_Name__c);
            }
        }
        
        return output;
    }
}