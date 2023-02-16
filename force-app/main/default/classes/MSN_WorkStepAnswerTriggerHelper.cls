/**
 * @File Name          : MSN_WorkStepAnswerTriggerHelper.cls
 * @Description        : Trigger Helper for WorkStepAnswer__c
 * @Author             : David Azzi
 * @Group              : 
 * @Last Modified By   : David Azzi
 * @Last Modified On   : 13/01/2022
 * @Modification Log   : 
 * Ver      Date            Author                  Modification
 * 1.0      01/12/2021      David Azzi              Initial Version
**/
public class MSN_WorkStepAnswerTriggerHelper {
    // commented out because none of method has been used    
    //1 Select
    /*public static Map<Id, List<MSN_WorkStepAnswer__c>> getAllRelatedWSAs(List<MSN_WorkStepAnswer__c> newWSA)
    {   
        Map<Id, List<MSN_WorkStepAnswer__c>> output = new Map<Id, List<MSN_WorkStepAnswer__c>>();
        List<MSN_WorkStepAnswer__c> relatedWSAs = new List<MSN_WorkStepAnswer__c>(newWSA);
        Set<Id> wstIds = new Set<Id>();

        for ( MSN_WorkStepAnswer__c wsa : newWSA )
        {
            wstIds.add(wsa.MSN_WorkStepTemplate__c);
        }

        relatedWSAs.addAll([SELECT MSN_WorkStepTemplate__c, MSN_AnswerValue__c, MSN_Sort_Order__c FROM MSN_WorkStepAnswer__c WHERE MSN_WorkStepTemplate__c IN: wstIds]);

        for ( MSN_WorkStepAnswer__c wsa : relatedWSAs ){
            if ( output.containsKey(wsa.MSN_WorkStepTemplate__c) )
            {
                output.get(wsa.MSN_WorkStepTemplate__c).add(wsa);
            } else {
                output.put(wsa.MSN_WorkStepTemplate__c, new List<MSN_WorkStepAnswer__c>{wsa});
            }
        }
        
        return output;
    }


    public static void updateSortAllWSA(List<MSN_WorkStepAnswer__c> newWSAs)
    {
        Map<Id, List<MSN_WorkStepAnswer__c>> wstIdWSAs = getAllRelatedWSAs(newWSAs);
        
        List<MSN_WorkStepAnswer__c> lstToUpdate = new List<MSN_WorkStepAnswer__c>();
        for(Id wstId : wstIdWSAs.keySet())
        {
            List<MSN_WorkStepAnswer__c> wsas = wstIdWSAs.get(wstId);
            Map<String, List<MSN_WorkStepAnswer__c>> wsaAnswerValueWSA = new Map<String, List<MSN_WorkStepAnswer__c>>();
            List<MSN_WorkStepAnswer__c> wsaNumericList = new List<MSN_WorkStepAnswer__c>();
            List<MSN_WorkStepAnswer__c> wsaSortedList = new List<MSN_WorkStepAnswer__c>();

            for ( MSN_WorkStepAnswer__c wsa : wsas)
            {
                if ( wsa.MSN_AnswerValue__c.isNumeric() )
                {
                    wsaNumericList.add(wsa);
                } else {
                    if (wsaAnswerValueWSA.containsKey(wsa.MSN_AnswerValue__c) )
                    {
                        wsaAnswerValueWSA.get(wsa.MSN_AnswerValue__c).add(wsa);
                    } else {
                        wsaAnswerValueWSA.put(wsa.MSN_AnswerValue__c, new List<MSN_WorkStepAnswer__c>{wsa});
                    }
                }
            }

            System.debug(wsaNumericList.size());
            //insertion sort
            for(Integer i = 1; i < wsaNumericList.size(); i++)
            {
                MSN_WorkStepAnswer__c wsaKey = wsaNumericList[i];

                Integer j = i - 1;

                while( j >= 0 && Integer.valueOf(wsaNumericList[j].MSN_AnswerValue__c) > Integer.valueOf(wsaKey.MSN_AnswerValue__c))
                {
                    wsaNumericList[j + 1] = wsaNumericList[j];
                    j = j - 1;
                }
                wsaNumericList[j+1] = wsaKey;
            }

            //numeric first
            wsaSortedList.addAll(wsaNumericList);

            //alpha last - Lists are already sorted by in-built Map
            for(String values : wsaAnswerValueWSA.keySet())
            {
                wsaSortedList.addAll(wsaAnswerValueWSA.get(values));
            }

            System.debug(wsaSortedList);
            lstToUpdate.addAll(addAlphaToSortedList(wsaSortedList));
        }

        for(MSN_WorkStepAnswer__c wsa : lstToUpdate){
            System.debug(wsa.MSN_Sort_Order__c);
        }
        System.debug(lstToUpdate);
    }

    public static List<MSN_WorkStepAnswer__c> addAlphaToSortedList(List<MSN_WorkStepAnswer__c> wsas)
    {

        for(Integer i = 0; i < wsas.size(); i++) {
            wsas[i].MSN_Sort_Order__c = convertNumberToSortString(i);
        }
        return wsas;
    }

    public static String getLetterOfIndex(Integer letterIndex){

        List<String> hex = new List<String>{'0','A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'};       
        return hex[letterIndex];
    }

    //Examples: 1 == A     27 == AA     1367 == AZO
    public static String convertNumberToSortString(Integer num){
        Integer rem = num;

        String output = '';

        while (rem > 0 ){
            Integer numberToLetter = Math.mod(rem,26);
            numberToLetter = (numberToLetter == 0 ) ? 26 : numberToLetter;
            rem = (rem - numberToLetter) / 26;
            output = getLetterOfIndex(numberToLetter) + output;
        }

        return output;
    }*/
}