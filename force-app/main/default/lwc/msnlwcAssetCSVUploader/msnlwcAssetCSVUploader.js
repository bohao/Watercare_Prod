import { LightningElement, track, api } from 'lwc';
import upsertFile from '@salesforce/apex/MSN_AssetCSVUploaderController.upsertFile';
import getAssetMappingFromCustomMetadata from '@salesforce/apex/MSN_AssetCSVUploaderController.getAssetMappingFromCustomMetadata';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';

const bulkData = [
    { label: 'Upload Message', fieldName: 'Upload_Message' },
    { label: 'Salesforce ID', fieldName: 'Id' },
    { label: 'Asset SF Name', fieldName: 'Name'},
    { label: 'Asset Type to Product', fieldName: 'Product2Id'}
];

export default class msnlwcAssetCSVUploader extends LightningElement {

    @track columns = bulkData;
    @track data;
    @track fileName = '';
    @track UploadFile = 'Upload CSV File';
    @track showLoadingSpinner = false;
    @track isTrue = false;
    csvType = 'bulkData';
    selectedRecords;
    filesUploaded = [];
    file;
    fileContents;
    fileReader;
    content;
    MAX_FILE_SIZE = 1500000;
    buData = bulkData;
    //asData = assetData;
    //atData = attributeData;
    uploadSuccessful = false;
    hideFileName = true;
    hasErrors = false;

    connectedCallback(){
        getAssetMappingFromCustomMetadata()
        .then(result => {
            let data = [...this.buData];

            let keys = Object.keys(result);
            keys.sort();
            for (let i = 0; i < keys.length; i++) {
                console.log(keys[i] + ':' + result[keys[i]]);
                data.push ( { label : keys[i], fieldName : result[keys[i]] } );
            }

            this.buData = data;
        })
        .catch(error => {
            window.console.log(JSON.stringify(error));
            this.showToast('Error', 'Error while retrieving metadata mapping.', 'error');
        });
        this.pageLoaded = true;
    }

    handleFilesChange(event) {
        this.onDelete();
        if(event.target.files.length > 0) {
            this.filesUploaded = event.target.files;
            this.fileName = event.target.files[0].name;
            this.hideFileName = false;
        } else {
            this.showToast('Error', 'Please upload a CSV File', 'error');
        }
    }

    handleSave() {
        console.log('handleSave');
        const allValid = [
            ...this.template.querySelectorAll('lightning-input'),
        ].reduce((validSoFar, inputCmp) => {
            inputCmp.reportValidity();
            return validSoFar && inputCmp.checkValidity();
        }, true);
        
        if (allValid) {
            this.uploadHelper();
        } else {
            this.showToast('Error', 'There was an error upserting the file.', 'error');
        }
    }

    onDelete(){
        this.filesUploaded = '';
        this.fileName = '';
        this.file = '';
        this.hideFileName = true;
        this.isTrue = false;
        this.data = [];
        this.uploadSuccessful = false;
        this.columns = bulkData;
        this.hasErrors = false;
    }

    uploadHelper() {
        this.file = this.filesUploaded[0];
        console.log('FileSize: ' + this.file.size);
        if (this.file.size > this.MAX_FILE_SIZE) {
            this.showToast('Error', 'File Size is too big', 'error');
            return ;
        }

        this.showLoadingSpinner = true;
        this.fileReader= new FileReader();
        this.fileReader.onloadend = (() => {
            this.fileContents = this.fileReader.result;
            //console.log('FileContents: ' + this.fileContents.substring(1, 19));
            if ( this.fileContents.includes('Business Area Code') ){
                this.csvType = 'bulkData';
                this.columns = bulkData;
            } else if ( this.fileContents.includes('Asset Type Desc') ){s
                this.csvType = 'attributeData';
            } else {
                this.csvType = 'assetData';
            }
            
            this.saveToFile();
        });

        //console.log('Columns: ' + this.columns);
        
        this.fileReader.readAsText(this.file);
    }

    showToast(title, message, variant){
        console.log('showToast');
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: variant
            })
        )

        this.showLoadingSpinner = false;
    }

 

    saveToFile() {
        //console.log('saveToFile:  \n' + JSON.stringify(this.fileContents));
        console.log('BuData: ' + this.buData);
        let columnArray = [...this.buData];
        upsertFile({ base64Data: JSON.stringify(this.fileContents), preMappedData : columnArray})
        .then(result => {
            let tmpData = [];
            for(const [key, value] of Object.entries(result)){
                if ( value != ''){
                    let json = key.replace('}', '"}');
                    for (const [key2, val2] of Object.entries(this.buData)) {
                        json = json.replace(', ' + val2.fieldName + '=', '", "' + val2.fieldName + '":"');
                        json = json.replace('{' + val2.fieldName + '=', '{ "' + val2.fieldName + '":"');
                    }
                    let tmpObj = JSON.parse(json);
                    tmpObj.Upload_Message = value;
                    
                    tmpData.push(tmpObj);    
                }
            }
            if ( Object.keys(tmpData).length !== 0){
                for (const [key1, val1] of Object.entries(tmpData[0])) {
                    for (const [key2, val2] of Object.entries(this.buData)) {
                        if ( val2.fieldName == key1 ){
                            this.columns.push( val2 );
                            break;
                        }
                    }
                }
                this.data = tmpData;
                this.hasErrors = true;
            } else {
                this.columns = [];
                this.hasErrors = false;
            }

            this.fileName = this.fileName + ' - Uploaded Successfully';
            this.isTrue = false;
            this.showLoadingSpinner = false;
            this.uploadSuccessful = true;
            if ( !this.hasErrors ){
                this.showToast('Success', this.file.name + ' - Uploaded Successfully', 'success');
            } else {
                this.showToast('Success', this.file.name + ' - Uploaded Successfully but with some errors', 'warning');
            }
            
        })
        .catch(error => {
            window.console.log(JSON.stringify(error));
            this.showToast('Error Upserting', error?.body?.message, 'error');
        });
    }
}