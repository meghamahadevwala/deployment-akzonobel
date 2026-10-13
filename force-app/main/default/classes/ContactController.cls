public with sharing class ContactController {

    public class ObjectCriteria {
        public String stepName;
        public String iconClassName;
        public String iconColor;
        public Integer order;
        public List<TaskTreatmentController.Criteria> criteria; 
        public String criteriaCondition;
        public Boolean active;
        public List<String> taskType;
    }

    @AuraEnabled(cacheable=true)
    public static List<Contact> getContactRecord(Id recordId) {
        System.debug('recordId?>>>>>>>>>>'+recordId);
        return [SELECT Id, Name, Phone, MobilePhone, HomePhone, OtherPhone, AssistantPhone, Email, celsrm__Default__c 
                FROM Contact 
                WHERE AccountId = :recordId LIMIT 1];
    }

    @AuraEnabled(cacheable=true)
    public static Contact getDefaultContactRecord(Id recordId) {
        System.debug('recordId?>>>>>>>>>>'+recordId);
        Contact defaultContact;
        List<Contact> listContact = [SELECT Id, Name, Phone, MobilePhone, HomePhone, OtherPhone, AssistantPhone, Email, celsrm__Default__c 
                                     FROM Contact 
                                     WHERE AccountId = :recordId 
                                     AND celsrm__Default__c = true 
                                     ORDER BY LastName];
        if(listContact != null && !listContact.isEmpty()){
            return listContact.get(0);
        }
        return null;
    }

    @AuraEnabled
    public static Integer getTotalOpenTask(Id recordId) {
        String QueryString = 'SELECT COUNT() FROM Task WHERE WhatId = :recordId AND status != \'Completed\''; 
        return Database.countQuery(QueryString);
        //return [SELECT Id FROM Task WHERE WhatId = :recordId];
    }

    @AuraEnabled
    public static Map<String, Object> getLatestTreatmentTask(Id recordId){
        Map<String, Object> returnMap = new Map<String, Object>();
        List<Task> tskList = [SELECT Id, Subject, celsrm__Treatment__c, celsrm__Treatment_Stage__c 
                             FROM Task 
                             WHERE WhatId = :recordId 
                             AND Status != 'Completed' 
                             AND celsrm__Treatment__c != '' 
                             ORDER BY celsrm__Treatment__r.celsrm__Treatment_Order__c DESC 
                             LIMIT 1];
        if(tskList != null && tskList.size() > 0) {
            List<celsrm__Treatment__c> treatList = [SELECT Id, celsrm__Treatment_Steps__c
                                                   FROM celsrm__Treatment__c 
                                                   WHERE Id = :tskList.get(0).celsrm__Treatment__c];
            returnMap.put('task', tskList.get(0));
            String stepsData = celsrm.SRMTreatmentUtility.readTreatmentDetailsFile(tskList.get(0).Id, 'Treatment Details');
            if (stepsData != '') {
                map < string, object > mapStepsDataObj =  (map < string, object > ) JSON.deserializeUntyped(stepsData);
                Set<Id> childIds = new Set<Id>();
                Id childId;
                for (Object ids : (List<Object>) mapStepsDataObj.get(tskList.get(0).celsrm__Treatment_Stage__c)) {
                    childId = (Id) ids;
                    childIds.add((Id) ids);
                }
                String ObjectName = ((Id) childId).getSObjectType().getDescribe().getName();
                String query = 'SELECT celsrm__balance__c FROM ' + ObjectName + ' WHERE Id = :childIds';
                List<SObject> recordList = Database.query(query);
                Decimal totalBalace = 0;
                for (SObject rec : recordList) {
                    totalBalace += (Decimal) rec.get('celsrm__balance__c');
                }
                returnMap.put('totalBalace', totalBalace);
                returnMap.put('totalcount', childIds.size());
                returnMap.put('treatmentStage', tskList.get(0).celsrm__Treatment_Stage__c);
                List<Map<String, String>> stepNameList = new List<Map<String, String>>();
                if(treatList != null && treatList.size() > 0 && treatList.get(0).celsrm__Treatment_Steps__c != null) {
                    List<ObjectCriteria> aCriterias = (List<ObjectCriteria>) JSON.deserialize(treatList.get(0).celsrm__Treatment_Steps__c, List<ObjectCriteria>.class);
                    if(aCriterias != null && aCriterias.size() > 0) {
                        for(ObjectCriteria aCriteria : aCriterias) {
                            if(aCriteria.active){
                                Map<String, String> tempMap = new Map<String, String>();
                                tempMap.put('stepName', aCriteria.stepName);
                                tempMap.put('iconClass', aCriteria.iconClassName);
                                tempMap.put('iconColor', aCriteria.iconColor);
                                stepNameList.add(tempMap);
                            }
                        }
                        returnMap.put('stepNameList', stepNameList);
                    }
                }
            }
        }
        return returnMap;
    }

    @AuraEnabled
    public static Map<String, Integer> getTotalBucket(String recordId){
        Map<String, Integer> returnMap = new Map<String, Integer>();

        System.debug('@@ recordId  : ' + recordId );
        
        // For current
        List<AggregateResult> result = [SELECT COUNT(Id) intVal 
                                       FROM celsrm__Transaction__c 
                                       WHERE celsrm__Account__c = :recordId 
                                         AND celsrm__DPD__c <= 0 
                                         AND celsrm__Balance__c != 0];
        System.debug('@@ result : ' + result);
        if(result.size() > 0) {
            returnMap.put('Current', ((Integer)result.get(0).get('intVal')));
        }

        // For 1-30
        result = [SELECT COUNT(Id) intVal 
                  FROM celsrm__Transaction__c 
                  WHERE celsrm__Account__c = :recordId 
                    AND celsrm__DPD__c > 0 
                    AND celsrm__DPD__c <= 30 
                    AND celsrm__Balance__c != 0];
        System.debug('@@ result 222 : ' + result);
        if(result.size() > 0) {
            returnMap.put('130', ((Integer)result.get(0).get('intVal')));
        }

        // For 31-60
        result = [SELECT COUNT(Id) intVal 
                  FROM celsrm__Transaction__c 
                  WHERE celsrm__Account__c = :recordId 
                    AND celsrm__DPD__c > 30 
                    AND celsrm__DPD__c <= 60 
                    AND celsrm__Balance__c != 0];
        if(result.size() > 0) {
            returnMap.put('3160', ((Integer)result.get(0).get('intVal')));
        }

        // For 61-90
        result = [SELECT COUNT(Id) intVal 
                  FROM celsrm__Transaction__c 
                  WHERE celsrm__Account__c = :recordId 
                    AND celsrm__DPD__c > 60 
                    AND celsrm__DPD__c <= 90 
                    AND celsrm__Balance__c != 0];
        if(result.size() > 0) {
            returnMap.put('6190', ((Integer)result.get(0).get('intVal')));
        }

        // For 91-180
        result = [SELECT COUNT(Id) intVal 
                  FROM celsrm__Transaction__c 
                  WHERE celsrm__Account__c = :recordId 
                    AND celsrm__DPD__c > 90 
                    AND celsrm__DPD__c <= 180 
                    AND celsrm__Balance__c != 0];
        if(result.size() > 0) {
            returnMap.put('91180', ((Integer)result.get(0).get('intVal')));
        }

        // For over 180
        result = [SELECT COUNT(Id) intVal 
                  FROM celsrm__Transaction__c 
                  WHERE celsrm__Account__c = :recordId 
                    AND celsrm__DPD__c > 180 
                    AND celsrm__Balance__c != 0];
        if(result.size() > 0) {
            returnMap.put('Over180', ((Integer)result.get(0).get('intVal')));
        }
        System.debug('@@@@@ returnMap ' + returnMap);
        return returnMap;
    }
}