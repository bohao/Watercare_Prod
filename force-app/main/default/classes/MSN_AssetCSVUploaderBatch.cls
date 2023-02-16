/**
 * @File Name          : MSN_AssetCSVUploaderBatch.cls
 * @Description        : MSN_AssetCSVUploaderBatch Controller - Asset Integration
 * @Author             : David Azzi
 * @Group              : 
 * @Last Modified By   : David Azzi
 * @Last Modified On   : 24/02/2022
 * @Modification Log   : 
 * 1/2/2023 This batch class hasn't been fully tested. Commented out for deployment purpose. 
 * Ver      Date            Author                  Modification
 * 1.0      24/02/2022      David Azzi              Initial Version
 * 2.0      1/02/2023       Bohao Chen              Comment out
**/
public class MSN_AssetCSVUploaderBatch {
//  implements Database.Batchable<sObject> {

    /*List<Asset> newAssetsToBeUpserted;

    public MSN_AssetCSVUploaderBatch(List<Asset> assetsToUpsert) {
        newAssetsToBeUpserted = assetsToUpsert;
    }

    public List<sObject> start(Database.BatchableContext context) {
        return newAssetsToBeUpserted;
    }
    public void execute(Database.BatchableContext context, List<sObject> scope) {

        //Get a the list of Assets that have been included in the CSV file and insert them
        //If there are any errors, save the errors to the Error Log Utility
        Map<Asset, String> output = new Map<Asset, String>();
        if ( newAssetsToBeUpserted.size() > 0 ){
            Schema.SObjectField compkeyToken = Asset.Fields.Comp_Key__c;
            Database.UpsertResult[] srList = Database.upsert(newAssetsToBeUpserted,compkeyToken,false);
            
            
            Map<Id, List<Database.Error>> upsertErrors = new Map<id, List<Database.Error>>();
            for (Database.UpsertResult sr : srList ){
                if ( !sr.isSuccess() && upsertErrors.size() < 5000 ){
                    upsertErrors.put( sr.getId(), sr.getErrors());
                }
            }
            if ( upsertErrors.size() > 0 ){
                MSN_HandleErrorsException.insertSaveResultErrors('', 
                                                                'Upserting Assets through the CSV Uploader', 
                                                                'MSN_AssetCSVUploaderBatch', 
                                                                'MSN_AssetCSVUploaderBatch.Execute',
                                                                MSN_Utility.getCurrentLineNumber(),
                                                                upsertErrors);
            }
        } 

    }
    public void finish(Database.BatchableContext context) {

    }*/
}