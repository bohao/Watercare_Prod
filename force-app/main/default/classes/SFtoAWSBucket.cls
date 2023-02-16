public with sharing class SFtoAWSBucket {
    //GET FILE FROM S3 AND ATTACH TO AN OBJECT IN SALESFORCE
    //PASS the OBJECT ID in salesforce and the name of the file from the s3 bucket to be attached.
    /*public static void getFileFromS3(Id oid, String fileName) {
        if (!String.isBlank(filename)) {
            String url = 'callout:Connect_to_S3';
            HttpRequest req  = new HttpRequest();
            HttpResponse res = new HttpResponse();
            req.setEndpoint(url + '/' + filename);
            req.setMethod('GET');
            system.debug(req.getBody());
            Http http = new Http();
            res = http.send(req);
            System.debug(res.getStatusCode());
            system.debug(res.getBody());
            if (res.getStatusCode() == 404) {
                //retry once on failure, as there my delay in file creation on ENLM
                res = http.send(req);
                if(res.getStatusCode() == 200) {
                    ContentVersion conVer = new ContentVersion();
                    conVer.contentLocation = 'S';
                    conver.PathonClient = filename;
                    conVer.Title = filename.substringAfter('/');
                    conver.VersionData = res.getBodyasblob();
                    insert conVer;
                    Id conDoc = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:conVer.Id].ContentDocumentId;
                    ContentDocumentLink conDocLink = New ContentDocumentLink();
                    conDocLink.LinkedEntityId = oid; 
                    conDocLink.ContentDocumentId = conDoc;  
                    conDocLink.shareType = 'V';
                    insert conDocLink;
                }
            }
            if(res.getStatusCode() == 200) {
                ContentVersion conVer = new ContentVersion();
                conVer.contentLocation = 'S';
                conver.PathonClient = filename;
                conVer.Title = filename.substringAfter('/');
                conver.VersionData = res.getBodyasblob();
                insert conVer;
                Id conDoc = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:conVer.Id].ContentDocumentId;
                ContentDocumentLink conDocLink = New ContentDocumentLink();
                conDocLink.LinkedEntityId = oid; 
                conDocLink.ContentDocumentId = conDoc;  
                conDocLink.shareType = 'V';
                insert conDocLink;
            }
        }
    }

    public static void putFileInS3FromObject(Id oid) {
        List<ContentDocumentLink> links=[SELECT ContentDocumentId,LinkedEntityId FROM ContentDocumentLink where LinkedEntityId=:oid];
        Set<Id> ids=new Set<Id>();
        for(ContentDocumentLink link:links) {
            ids.add(link.ContentDocumentId);
        }
        
        List<ContentVersion> versions=[SELECT VersionData,Title,ContentDocumentId,FileExtension FROM ContentVersion WHERE ContentDocumentId = :ids AND IsLatest = true];
        if (versions.size() > 0) {
            String attachmentBody = EncodingUtil.base64Encode(versions[0].VersionData);
            system.debug('file:'+ versions[0]);
            String formattedDateString = Datetime.now().formatGMT('EEE, dd MMM yyyy HH:mm:ss z');
            String filename = versions[0].Title;
            //Update the content-type based on the file type being attached
            string contentType= 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
            system.debug('contentType:'+contentType);
            // String url = 'callout:Connect_to_S3';
            

            HttpRequest req  = new HttpRequest();
            HttpResponse res  = new HttpResponse();
            req.setMethod('PUT');
            // req.setEndpoint(url + filename);
            // req.setEndpoint('callout:Integrate_AWS_S3/msn/inbound/329448/' + EncodingUtil.urlEncode(filename, 'UTF-8'));
            req.setEndpoint('callout:Integrate_AWS_S3/' + EncodingUtil.urlEncode(filename, 'UTF-8'));
            // req.setEndpoint('callout:Integrate_AWS_S3/');
            req.setHeader('Content-Length', String.valueOf(attachmentBody.length()));
            req.setHeader('Content-Encoding', 'UTF-8');
            req.setHeader('Content-type', contentType);
            req.setHeader('Connection', 'keep-alive');
            req.setHeader('Date', formattedDateString);
            req.setHeader('ACL', 'public-read');
            Blob pdfBlob = EncodingUtil.base64Decode(attachmentBody);
            req.setBodyAsBlob(pdfBlob);
            Http http = new Http();
            System.debug(req);
            res = http.send(req);
            system.debug(res.getStatusCode());
            system.debug(res.getBody());
        }
    }*/
}