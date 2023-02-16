/**
 * @File Name          : MSN_Utility.cls
 * @Description        : Utility Class - General use functions
 * @Author             : David Azzi
 * @Group              : 
 * @Last Modified By   : David Azzi
 * @Last Modified On   : 28/01/2022
 * @Modification Log   : 
 * Ver      Date            Author                  Modification
 * 1.0      28/01/2022      David Azzi              Initial Version
**/
public class MSN_Utility {

    //Generic method to get the first numbers of a string and return 'Even' or 'Odd'
    public static String OddsOrEvens(String streetNo){
        String output = 'N/A';
        String tmpStreetNo = '';

        if ( String.isNotBlank(streetNo)){
            for(Integer i = 0; i < streetNo.length(); i++){
                if ( streetNo.substring(i, i+1).isNumeric() ){
                    tmpStreetNo += streetNo.substring(i, i+1);
                } else {
                    break;
                }
            }
    
            if ( String.isNotBlank(tmpStreetNo) ){
                output = (Math.mod(Integer.valueOf(tmpStreetNo), 2) == 0) ? 'Even' : 'Odd';
            } 
        }
        
        return output;
    }

    //Generic method to generate a random string at any desired length
    /*public static String generateRandomString(Integer len) {
        final String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz';
        String randStr = '';
        while (randStr.length() < len) {
           Integer idx = Math.mod(Math.abs(Crypto.getRandomInteger()), chars.length());
           randStr += chars.substring(idx, idx+1);
        }
        return randStr; 
    }*/

    //Generic method to generate a random string of numbers at any desired length
    /*public static String generateRandomNumber(Integer len) {
        final String chars = '0123456789';
        String randStr = '';
        while (randStr.length() < len) {
           Integer idx = Math.mod(Math.abs(Crypto.getRandomInteger()), chars.length());
           randStr += chars.substring(idx, idx+1);
        }
        return randStr; 
    }*/

    //Generic method to convert a string in YYYY-MM-DD format to Date YYYY-MM-DD format.
    public static Date setStringToDateFormat(String myDate) {

        if ( myDate.contains(':') ){
            myDate = myDate.split(' ')[0];
        }
        myDate = myDate.replaceAll('/', '-');
        List<String> strDate = myDate.split('-');
        Integer myIntDate = Integer.valueOf(strDate[2]);
        Integer myIntMonth = Integer.valueOf(strDate[1]);
        Integer myIntYear = Integer.valueOf(strDate[0]);
        Date d = Date.newInstance(myIntYear, myIntMonth, myIntDate); //input format was YYYY-MM-DD
        if ( myIntYear > 31 ){
            if ( myIntMonth > 12 ){
                d = Date.newInstance(myIntYear, myIntDate, myIntMonth); //input format was YYYY-DD-MM
            }
        } else {
            if ( myIntMonth > 12 ){
                d = Date.newInstance(myIntDate, myIntYear, myIntMonth); //input format was MM-DD-YYYY
            } else {
                d = Date.newInstance(myIntDate, myIntMonth, myIntYear); //input format was DD-MM-YYYY
            }
        }
        
            
        //System.debug('Date is '+d);
        
        return d;
        
    }

    //Generic method to convert a string in YYYY-MM-DDThh:mm:ss.000Z format to DateTime YYYY-MM-DD hh:mm:ss format.
    public static DateTime setStringToDateTimeFormat(String myDate) {
    
        DateTime dateOne = (DateTime)Json.deserialize('"'+myDate+'"', DateTime.class);
        
        //System.debug(dateOne);
        
        String dateformat = 'yyyy-MM-dd  HH:mm:ss:sssZ';
        String dtString = dateOne.format(dateformat,''+userinfo.getTimeZone().toString());
        //System.debug('dtString is -->'+dtString);
        //System.debug('DateTime is -->'+DateTime.valueOf(dtString));
        
        return DateTime.valueOf(dtString);
        
    }

    //Generic method to convert a set of fields to a query whilst checking if the field exists on the object
    public static String buildFieldsForSOQLQuery(Set<String> fieldAPINameList, String objectName) {
        String fieldsQuery = '';

        for(String str : fieldAPINameList) {
            if ( String.isBlank(objectName)){
                fieldsQuery = (fieldsQuery + ',' + str).removeStart(',');
                break;
            } else {
                if ( doesApiNameOfFieldExist(objectName, str) ){
                    fieldsQuery = (fieldsQuery + ',' + str).removeStart(',');
                }
            }
        }

        return fieldsQuery;
    }

    //Check to see if the field exists in the object schema
    public static Boolean doesApiNameOfFieldExist(String objectName, string apiFieldName)
    {
        try {
            if ( doesObjectExist(objectName) ){
                SObject sobj = Schema.getGlobalDescribe().get(objectName).newSObject();
                return sobj.getSobjectType().getDescribe().fields.getMap().containsKey(apiFieldName);
            }
        }
        catch(Exception e) {
            System.debug('MSN_Utility.doesFieldExist: ' + e.getMessage() );
        }
         
        return false;
    }

    public static Boolean doesObjectExist(String objectApiName){
        return Schema.getGlobalDescribe().containsKey(objectApiName);
    }


    /* Compare SObjects attributes; ignore non-existent attributes when new value is null */
    /*public static Set<String> compareSobjects(sObject sobjBefore, sObject sobjAfter) {

        Set<String> changedFields = new Set<String>();

        if(sobjBefore != sobjAfter) {
            if(sobjBefore != null && sobjAfter != null) {
                try {
                    Map<String, Object> beforeMap = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(sobjBefore));
                    Map<String, Object> afterMap = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(sobjAfter));
                    for(String key : afterMap.keySet()) {
                        if( beforeMap.containsKey(key) ? afterMap.get(key) != beforeMap.get(key) : afterMap.get(key) != null) {
                            changedFields.add(key);
                        }
                    }
                } catch(Exception e){
                    MSN_HandleErrorsException.insertLogException(e, '', '');
                    return changedFields;
                }
            } else {
                System.debug('compareSobjects: failed - one or more SObjects were null');
                return changedFields;
            }
        } 
        //System.debug('compareSobjects: compare success');
        return changedFields;
    }*/


    /*public static List<String> getAllFieldNames(String text, String fieldPattern, String removeStart, String removeEnd){
        //String fieldPattern = '\\{\\{[^}]*\\}\\}';
        Pattern patternObj = Pattern.compile(fieldPattern);
        Matcher matcher = patternObj.matcher(text);

        List<String> fields = new List<String>();

        while (matcher.find()) {
            String fieldName = matcher.group();
            fieldName = fieldName.remove(removeStart);
            fieldName = fieldName.remove(removeEnd);
            fields.add(fieldName);
        }

        return fields;
    }*/

    public static Set<String> getFieldPlaceholders(String text, String fieldPattern, String removeStart, String removeEnd){
        //String fieldPattern = '\\{\\{[^}]*\\}\\}';
        Pattern patternObj = Pattern.compile(fieldPattern);
        Matcher matcher = patternObj.matcher(text);

        Set<String> fields = new Set<String>();

        while (matcher.find()) {
            String fieldName = matcher.group();
            fieldName = fieldName.remove(removeStart);
            fieldName = fieldName.remove(removeEnd);
            fields.add(fieldName);
        }

        return fields;
    }

    //Generic method which allows us to pass an sObject list containing all data records to be upserted for a specific sObject
    /*public static void dynamicUpsert(List<SObject> records, String externalIdField) {
        
        Schema.SObjectType sObjectType = records.getSObjectType();
        if (sObjectType != null) {
            String listType = 'List<' + sObjectType + '>';
            List<SObject> castRecords = (List<SObject>)Type.forName(listType).newInstance();
            castRecords.addAll(records);
            upsert castRecords;
        }
        
    } */

    public static Map<String,Schema.DisplayType> fetchFieldTypesforObject(String sObjectname) {
        Map<String,Schema.DisplayType> fieldAPINameToDataTypeMap = new Map<String,Schema.DisplayType>();
        Map<String, Schema.SObjectField> fields = new Map<String, Schema.SObjectField>();
        
        if(sObjectname == 'Schema.Location')
        	fields = Schema.getGlobalDescribe().get('Location').getDescribe().fields.getMap();
        else
            fields = Schema.getGlobalDescribe().get(sObjectname).getDescribe().fields.getMap();
        
        for(String fieldName : fields.keySet()){
            if((fields.get(fieldName)).getDescribe().getType() == Schema.DisplayType.LOCATION){
                
                fieldAPINameToDataTypeMap.put((fields.get(fieldName)).getDescribe().getName().replace('__c','__latitude__s'),(fields.get(fieldName)).getDescribe().getType());
                fieldAPINameToDataTypeMap.put((fields.get(fieldName)).getDescribe().getName().replace('__c','__longitude__s'),(fields.get(fieldName)).getDescribe().getType());                
            }
            
            fieldAPINameToDataTypeMap.put((fields.get(fieldName)).getDescribe().getName(),(fields.get(fieldName)).getDescribe().getType());
        }
        //System.debug('fieldAPINameToDataTypeMap'+fieldAPINameToDataTypeMap);
        //System.debug('fieldAPINameToDataTypeMap1'+fieldAPINameToDataTypeMap.get('WorkOrder_Geolocation__c'));
    
        return fieldAPINameToDataTypeMap;
    }

    public static Object transformAndMapFieldValues(Schema.DisplayType fieldType, Object value){
        //System.debug('fieldType*****'+fieldType);
        //System.debug('valuex*****'+value);
        
        if(fieldType == Schema.DisplayType.DATE){
            if (value == null  ||  value =='' ){return null;}
            return setStringToDateFormat((String)value);
        } else if(fieldType == Schema.DisplayType.DATETIME){
              if (value == null  ||  value =='' ){return null;}
            return setStringToDateTimeFormat((String)value);
        } else if(fieldType == Schema.DisplayType.DOUBLE  || Fieldtype == schema.DisplayType.CURRENCY || Fieldtype == schema.DisplayType.PERCENT){
              if (value == null  ||  value =='' ){return 0;}
                return Decimal.valueOf((String)value);
        } else if ( fieldType == Schema.DisplayType.INTEGER){
              if (value == null  ||  value =='' ){return 0;}
            return integer.valueof((string)value);
        } else if(fieldType == Schema.DisplayType.BOOLEAN){
              if (value == null  ||  value =='' ){return null;}
            return Boolean.valueOf((String)value);
         
        } else if(fieldType == Schema.DisplayType.ADDRESS ||  fieldType == Schema.DisplayType.STRING ||  fieldType == Schema.DisplayType.PHONE || fieldType == Schema.DisplayType.TEXTAREA || fieldType == Schema.DisplayType.PICKLIST){
                 if (value == null ){return '';}
        } else if(fieldType == Schema.DisplayType.LOCATION){
              if (value == null ){return '';}
            return Decimal.valueOf((String)value);
        }
        return value;
    }


    /*public static Map<String, List<Schema.ChildRelationship>> getObjectChildRelationships(String objectName, Boolean includeDeletedObjects){

        Schema.SObjectType targetObjectType = Schema.getGlobalDescribe().get( objectName );
        Map<String, List<Schema.ChildRelationship>> output = new Map<String, List<Schema.ChildRelationship>>();

        for ( Schema.ChildRelationship scr : targetObjectType.getDescribe().getchildRelationships() ){

            String childObjectName = String.valueOf(scr.getChildSObject());
            if ( !output.containsKey( childObjectName ) ) {
                output.put( childObjectName, new List<Schema.ChildRelationship>() );
            }

            if ( (includeDeletedObjects) || !(scr.isCascadeDelete() && scr.isDeprecatedAndHidden() && scr.isRestrictedDelete()) ){
                output.get( childObjectName ).add( scr );
            }
        }

        return output;
    }*/

    /*public static Map<String, Map<String,String>> getLookupReferencesFromObject(String objectName){
        Map<String, Map<String,String>> objectNameRelationshipNameFieldName = new Map<String, Map<String,String>>();

        Map<String, Schema.SObjectField> fieldMap = Schema.getGlobalDescribe().get( objectName ).getDescribe().fields.getMap();
        DescribeSObjectResult objResult = Schema.getGlobalDescribe().get(objectName).getDescribe();

        for (String fieldName: fieldMap.keySet() ){
            //lookup types are Reference
            if(fieldMap.get(fieldName).getDescribe().getType() == Schema.DisplayType.Reference) {
                DescribeFieldResult fResult = objResult.fields.getMap().get(fieldName).getDescribe();
                if ( !objectNameRelationshipNameFieldName.containsKey( fResult.getReferenceTo()[0].getDescribe().getName() ) ){
                    objectNameRelationshipNameFieldName.put( fResult.getReferenceTo()[0].getDescribe().getName(), new Map<String, String>() );
                }
                objectNameRelationshipNameFieldName.get( fResult.getReferenceTo()[0].getDescribe().getName() ).put(
                        fieldMap.get(fieldName).getDescribe().getRelationshipName(), //Relationship Name
                        fieldMap.get(fieldName).getDescribe().getName() //object Name relationship is pointing to
                    )
                ;
            }
            
        }

        return objectNameRelationshipNameFieldName;
    }*/

    public static Integer getCurrentLineNumber(){
        try{
            Integer x = 0 / 0;
        } catch(Exception e) {
            String line2 = e.getStackTraceString().split('\n')[1];
            Pattern patt = Pattern.compile('([A-Za-z0-9_.<>]+): line (\\d+)');
            Matcher match = patt.matcher(line2);
            match.find();
            return Integer.valueOf(match.group(2));
        }
        return null;
    }

/*
    public static Map<String, String> findRelationshipOfObjectThroughLookups(String objectNameToStart, String objectNameToFind){
        
        Set<String> foundObjectNames = new Set<String>();
        String output = objectNameToStart +'.';
        Map<String, String> objectNameReferenceQueryString = new Map<String, String>();
        String reference = '';

        Map<String, Map<String,String>> startLookupReferences = getLookupReferencesFromObject(objectNameToStart);
        Map<String, String> objectNameObjectRelationship = new Map<String, String>();
        

        try {
            if ( startLookupReferences.containsKey(objectNameToFind) ){
                //TODO <commented>How to find which relationship is best if there is more than one?
                for(String refName : startLookupReferences.get(objectNameToFind).keySet() ){
                    reference = refName;
                }
            } else {
                //loop through lookup objects to find the object you're searching for
                for(String lookupObjectName1 : startLookupReferences.keySet() ){
                    Map<String, Map<String,String>> childLookupReferences1 = getLookupReferencesFromObject(lookupObjectName1);
                    if ( childLookupReferences1.containsKey(objectNameToFind) ){
                        for(String refName : startLookupReferences.get(lookupObjectName1).keySet() ){
                            reference = refName;
                        }
                        for(String refName : childLookupReferences1.get(objectNameToFind).keySet() ){
                            reference += '.' + refName;
                        }
                    } else {
                        foundObjectNames.addAll(startLookupReferences.keySet());
                        //didn't find it, so lets go through lookups of sub-object references again to see if it's there
                        for(String lookupObjectName2 : childLookupReferences1.keySet() ){
                            if ( foundObjectNames.contains(lookupObjectName2) ){
                                continue;
                            }
                            Map<String, Map<String,String>> childLookupReferences2 = getLookupReferencesFromObject(lookupObjectName2);
                            if ( childLookupReferences2.containsKey(objectNameToFind) ){
                                for(String refName : startLookupReferences.get(lookupObjectName1).keySet() ){
                                    reference = refName;
                                }
                                for(String refName : childLookupReferences1.get(lookupObjectName2).keySet() ){
                                    reference += '.' + refName;
                                }
                                for(String refName : childLookupReferences2.get(objectNameToFind).keySet() ){
                                    reference += '.' + refName;
                                }
                            } else {
                                foundObjectNames.addAll(childLookupReferences1.keySet());
                                //didn't find it, so lets go through lookups of sub-object references again to see if it's there
                                for(String lookupObjectName3 : childLookupReferences2.keySet() ){
                                    if ( foundObjectNames.contains(lookupObjectName3) ){
                                        continue;
                                    }
                                    Map<String, Map<String,String>> childLookupReferences3 = getLookupReferencesFromObject(lookupObjectName3);
                                    if ( childLookupReferences3.containsKey(objectNameToFind) ){
                                        for(String refName : startLookupReferences.get(lookupObjectName1).keySet() ){
                                            reference = refName;
                                        }
                                        for(String refName : childLookupReferences1.get(lookupObjectName2).keySet() ){
                                            reference += '.' + refName;
                                        }
                                        for(String refName : childLookupReferences2.get(lookupObjectName3).keySet() ){
                                            reference += '.' + refName;
                                        }
                                        for(String refName : childLookupReferences3.get(objectNameToFind).keySet() ){
                                            reference += '.' + refName;
                                        }
                                    } else {
                                        //TODO <commented>Throw error message that relationship was unable to be found between objects
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }catch( Exception e ){
            System.debug('Error in MSN_Utility.findRelationshipOfObjectThroughLookupsAdd: ' + e.getMessage());
        }
        
        if ( String.isBlank( reference ) ){
            reference = 'Unable to find object relationship';
        }
        objectNameReferenceQueryString.put( objectNameToFind, reference );

        return objectNameReferenceQueryString;
    }
*/
    public static String getObjectNameFromId(Id objId){

        String objectName = '';

        try {
            objectName = String.isBlank(objId) ? '' : objId.getSObjectType().getDescribe().getName();  
        } catch ( Exception e){
            System.debug('Error: MSN_Utility.getObjectNameFromId. Message: ' + e.getMessage() );
        }

        return objectName;
    }

    public static String getValue(SObject record, String path) {
        // try {
        SObject temp = record;
        String[] parts = path.split('\\.');
        while(parts.size() > 1) {
        temp = temp.getSObject(parts.remove(0));
        }

        String value;
        if(temp.get(parts[0]) != null) {
            value = String.valueOf(temp.get(parts[0]));
            
            // check if the value is datetime format. if so, convert it to a certain format into auckland timezone
            Pattern patternObj = Pattern.compile('^20[0-9]{2}-[01]{1}[0-9]{1}-[0-3]{1}[0-9]{1}\\s[0-2]{1}[0-9]{1}:[0-5]{1}[0-9]{1}:[0-5]{1}[0-9]{1}$');
            Matcher matcher = patternObj.matcher(value);

            // if it is datetime format
            if(matcher.find()) {
                Datetime gmtDatetime = DateTime.valueOfGmt(value);            
                value = String.valueOf(gmtDatetime.format('yyy-MM-dd\'T\'HH:mm:ss.SSS', 'Pacific/Auckland'));
            }

            System.debug('@value: ' + value);
        }
          
        return value;
        // } catch(Exception e) {
            // TODO: log the error
        //   return null;
        // }
    }

    public static Integration_Endpoint__mdt getEndpointSetting(String endpointApiWithoutSuffix) {
        String instanceName = EnvironmentHelper.getSandboxName(); // return 'Production' if it is Production   
        String endpointApiName = instanceName.equalsIgnoreCase('Production') ? endpointApiWithoutSuffix : endpointApiWithoutSuffix + '_' +  instanceName.capitalize();

        Integration_Endpoint__mdt endpoint;
        try {
            endpoint = [SELECT DeveloperName, Endpoint__c 
                        FROM Integration_Endpoint__mdt 
                        WHERE DeveloperName =: endpointApiName.toLowerCase() LIMIT 1];
        }
        catch(Exception e) {
            MSN_HandleErrorsException.insertLogException(e, '', '');
        }

        return endpoint;
    }

    public static Datetime convertToDatetime(String dateTimeString) {
        if(dateTimeString.contains('T')) {
            dateTimeString = dateTimeString.replaceAll('T', ' ');
        }
        return Datetime.valueOf(dateTimeString);
    }

    public class CustomException extends Exception {}
}