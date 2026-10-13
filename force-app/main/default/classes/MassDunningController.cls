global with sharing class MassDunningController implements celsrm.GOGIScreenCustomLogic{
    global Map<Object, Object> invoke(String functionName, Map<Object, Object> inMap){
        try {
            if(functionName == 'fetchTreatmentNames'){
                inMap = fetchTreatmentNames(inMap);
            } else if(functionName == 'fetchTreatmentAccounts'){
                inMap = fetchTreatmentAccounts(inMap);
            } else if(functionName == 'fetchTaskList'){
                inMap = fetchTaskList(inMap);
            } else if(functionName == 'sendMassDunningEmails'){
                inMap = sendMassDunningEmails(inMap);
            }
        } catch (Exception ex) {
            throw new celsrm.CustomException(ex.getMessage()+'::'+ex.getStackTraceString());
        }
        return inMap;
    }


    public static Map<Object, Object> fetchTreatmentNames(Map<Object, Object> inMap){
        try{
            List<Map<String, String>> subjectMaplist = new List<Map<String, String>>();
            set<String> s_Subject = new set<String>();
            List<celsrm__Treatment__c> tList = [SELECT Id, celsrm__Treatment_Name__c, celsrm__Active__c FROM celsrm__Treatment__c 
                                            WHERE celsrm__Active__c = true ] ;

            if(tList.size() > 0){
                Map<string,string> m_taskSubject =  new Map<string,string>();
                for(celsrm__Treatment__c t : tList){
                    m_taskSubject= new Map<string,string>();
                    m_taskSubject.put('label',t.celsrm__Treatment_Name__c);
                    m_taskSubject.put('value',t.Id);
                    subjectMaplist.add(m_taskSubject);
                }
            }
            inMap.put('dataServiceResponse',subjectMaplist);
            return inMap;
            
        } catch(Exception ex){
            System.debug('Method: fetchTreatmentNames | Linenumber: ' + ex.getLineNumber() + ' | Message: ' + ex.getMessage());
        }
        return inMap;
    }

    public static Map<Object, Object> fetchTreatmentAccounts(Map<Object, Object> inMap){
        try{
            List<Map<String, String>> AccountNameMaplist = new List<Map<String, String>>();
            set<String> s_Subject = new set<String>();
            //-- Start | FIN-8492  | Changed By Asera | 10 Oct 2025 --//
            Set<Id> ownerIds = getAllOwnerIdsForUser(UserInfo.getUserId());
            List<String> ownerIdStrings = new List<String>();
            for (Id ownerId : ownerIds) {
                ownerIdStrings.add(String.valueOf(ownerId));
            }
            String ownerIdString = '\'' + String.join(ownerIdStrings, '\', \'') + '\'';
            //-- End | FIN-8492  | Changed By Asera | 10 Oct 2025 --//
            String accountQuery = 'SELECT AccountId, MAX(Account_Name__c) AccountName, COUNT(Id) FROM Task';
            accountQuery += ' WHERE celsrm__Treatment__r.celsrm__Active__c = true ';
            accountQuery += ' AND Status NOT IN (\'Completed\', \'Auto Dunning Error\') AND what.type=\'Account\'';
            // accountQuery += ' AND celsrm__Treatment__r.celsrm__Task_Type__c = \'Email\'';
            accountQuery += ' AND (celsrm__Treatment__r.celsrm__Task_Type__c = \'Email\' OR ';
            accountQuery += 'celsrm__Treatment__r.celsrm__Seperate_Task_For_Step__c = true)';
            //-- Start | FIN-8492  | Changed By Asera | 10 Oct 2025 --//
            // accountQuery += ' AND ownerId = \'' + UserInfo.getUserId() + '\'';
            accountQuery += ' AND ownerId IN (' + ownerIdString + ') ';
            //-- End | FIN-8492  | Changed By Asera | 10 Oct 2025 --//
            if(String.valueOf(inMap.get('TreatmentFilter')) != '' && String.valueOf(inMap.get('TreatmentFilter')) != null){
                system.debug('<<<<<TreatmentFilter>>>>>'+inMap.get('TreatmentFilter'));
                accountQuery += ' AND celsrm__Treatment__c = \'' + String.valueOf(inMap.get('TreatmentFilter'))  + '\'';
            }
            accountQuery += ' GROUP BY AccountId';
            List<AggregateResult> tList = Database.query(accountQuery);
            // List<AggregateResult> tList = [SELECT AccountId, MAX(Account_Name__c) AccountName, COUNT(Id) FROM Task 
            //                                 WHERE celsrm__Treatment__r.celsrm__Active__c = true
            //                                 GROUP BY AccountId] ;

            if(tList.size() > 0){
                Map<string,string> m_taskAccounts =  new Map<string,string>();
                for(AggregateResult t : tList){
                    m_taskAccounts= new Map<string,string>();
                    m_taskAccounts.put('label',(String)t.get('AccountName'));
                    m_taskAccounts.put('value',(String)t.get('AccountId'));
                    AccountNameMaplist.add(m_taskAccounts);
                }
            }
            inMap.put('dataServiceResponse',AccountNameMaplist);
            return inMap;
            
        } catch(Exception ex){
            System.debug('Method: fetchTreatmentNames | Linenumber: ' + ex.getLineNumber() + ' | Message: ' + ex.getMessage());
        }
        return inMap;
    }

    public static Map<Object, Object> fetchTaskList(Map<Object, Object> inMap){
        try{
            
            system.debug('UserInfo.getUserId()>>'+UserInfo.getUserId());
             //-- Start | FIN-8492  | Changed By Asera | 10 Oct 2025 --//
             Set<Id> ownerIds = getAllOwnerIdsForUser(UserInfo.getUserId());
             List<String> ownerIdStrings = new List<String>();
             for (Id ownerId : ownerIds) {
                 ownerIdStrings.add(String.valueOf(ownerId));
             }
             String ownerIdString = '\'' + String.join(ownerIdStrings, '\', \'') + '\'';
             //-- End | FIN-8492  | Changed By Asera | 10 Oct 2025 --//
            //-- Starts | FIN-7567 | Changed by Ravi | 23 May 2025 | add treatment stage field--//
            String taskQuery = 'SELECT t.Id,t.What.type,t.ownerId, t.ActivityDate,t.Account_Name__c, t.celsrm__Notes__c, ';
            taskQuery += 't.WhatId, t.Type, t.SystemModstamp, t.Subject, t.Status, t.Priority , t.Description, ';
            taskQuery += 't.CallType, t.CallObject, t.AccountId, t.celsrm__Treatment__c,';
            // << START - MM - FIN-9969 - select contact by Email_Type__c based on treatment rule name >>
            taskQuery += 't.celsrm__Treatment__r.Name, t.celsrm__Treatment__r.celsrm__Treatment_Name__c,';
            // << END - MM - FIN-9969 - select contact by Email_Type__c based on treatment rule name >>
            taskQuery += 't.Owner.Email, t.Total_AR__c, t.Total_Past_Due__c, t.celsrm__Treatment_Stage__c FROM Task t ';
            taskQuery += 'WHERE t.Status NOT IN (\'Completed\', \'Auto Dunning Error\') AND t.what.type=\'Account\' ';
            taskQuery += ' AND (t.celsrm__Treatment__r.celsrm__Task_Type__c = \'Email\' OR ';
            taskQuery += 't.celsrm__Treatment__r.celsrm__Seperate_Task_For_Step__c = true)';
            //-- Start | FIN-8492  | Changed By Asera | 10 Oct 2025 --//
            taskQuery += ' AND t.ownerId IN (' + ownerIdString + ') ';
            // taskQuery += ' AND t.ownerId = \'' + UserInfo.getUserId() + '\'';
            //-- End | FIN-8492  | Changed By Asera | 10 Oct 2025 --//
            //-- End | FIN-7567 | Changed by Ravi | 23 May 2025 --//
            if(String.valueOf(inMap.get('TreatmentFilter')) != ''){
                taskQuery += ' AND t.celsrm__Treatment__c = \'' + String.valueOf(inMap.get('TreatmentFilter'))  + '\'';
            } 
            if(String.valueOf(inMap.get('AccountFilter')) != null && String.valueOf(inMap.get('AccountFilter')) != ''){
                system.debug('<<<<<AccountFilter>>>>>'+inMap.get('AccountFilter'));
                List<String> accountIdList= String.valueOf(inMap.get('AccountFilter')).split(';');
                taskQuery += ' AND t.AccountId IN :accountIdList';
            } 
            system.debug('<<<<<taskQuery>>>'+taskQuery);

            List <Task> tlst = Database.Query(taskQuery);
            System.debug('tlst>>>'+tlst);
            
            List < Id > AccIDs = new List< Id >();
            // << START - MM - FIN-9969 - select contact by Email_Type__c based on treatment rule name >>
            Map<Id, String> taskIdVsEmailType = new Map<Id, String>();
            Map<Id, Id> taskIdVsAccount = new Map<Id, Id>();
            // << END - MM - FIN-9969 - select contact by Email_Type__c based on treatment rule name >>
            for(Task ts: tlst ){            
                system.debug('ts'+ts);
                AccIDs.add(ts.WhatID);
                // << START - MM - FIN-9969 - select contact by Email_Type__c based on treatment rule name >>
                String ruleName = (ts.celsrm__Treatment__c != null && ts.celsrm__Treatment__r.celsrm__Treatment_Name__c != null) ? ts.celsrm__Treatment__r.celsrm__Treatment_Name__c.toUpperCase() : '';
                String emailType = null;
                if (ruleName.contains('CUSTSTAT')) {
                    emailType = 'Statement';
                } else if (ruleName.contains('DUNNING')) {
                    emailType = 'Dunning';
                }
                taskIdVsEmailType.put(ts.Id, emailType); 
                taskIdVsAccount.put(ts.Id, ts.WhatId);        
                // << END - MM - FIN-9969 - select contact by Email_Type__c based on treatment rule name >>         
            }            
            if(!AccIDs.isEmpty()){
                // << START - MM - FIN-9969 - select contact by Email_Type__c based on treatment rule name | Calling new method fetchEmailsBasedOnEmailType() instead of fetchEmails() >>
                // Map< String, Map<String, List<String>> > returnMap = UtilityController.fetchEmails(AccIDs);
                Map< String, Map<String, List<String>> > returnMap = UtilityController.fetchEmailsBasedOnEmailType(taskIdVsAccount, taskIdVsEmailType); // This will return From, to, cc, bcc based on contact data
                // << END - MM - FIN-9969 - select contact by Email_Type__c based on treatment rule name | Calling new method fetchEmailsBasedOnEmailType() instead of fetchEmails() >>
                // This will return From, cc, bcc based on treatment configuration for each task
                Map< String, Map<String, List<String>> > treatmentEmails = UtilityController.fetchEmailsForTreatmentTask(tlst);
                for(Task t : tlst) {
                    Map<String, List<String>> finalMap = new Map<String, List<String>>();
    
                    // << START - MM - FIN-9969 - select contact by Email_Type__c based on treatment rule name | Calling new method fetchEmailsBasedOnEmailType() instead of fetchEmails() >>
                    // Merge entries from returnMap (account-based)
                    // if (returnMap != null && returnMap.containsKey(t.WhatId)) {
                    //     for (String key : returnMap.get(t.WhatId).keySet()) {
                    //         if (!finalMap.containsKey(key)) {
                    //             finalMap.put(key, new List<String>());
                    //         }
                    //         finalMap.get(key).addAll(returnMap.get(t.WhatId).get(key));
                    //     }
                    // }
                    if (returnMap != null && returnMap.containsKey(t.Id)) {
                        for (String key : returnMap.get(t.Id).keySet()) {
                            if (!finalMap.containsKey(key)) {
                                finalMap.put(key, new List<String>());
                            }
                            finalMap.get(key).addAll(returnMap.get(t.Id).get(key));
                        }
                    }
                    // << END - MM - FIN-9969 - select contact by Email_Type__c based on treatment rule name | Calling new method fetchEmailsBasedOnEmailType() instead of fetchEmails() >>

                    // Merge entries from treatmentEmails (treatment-based)
                    if (treatmentEmails != null && treatmentEmails.containsKey(t.Id)) {
                        for (String key : treatmentEmails.get(t.Id).keySet()) {
                            if (!finalMap.containsKey(key)) {
                                finalMap.put(key, new List<String>());
                            }
                            finalMap.get(key).addAll(treatmentEmails.get(t.Id).get(key));
                        }
                    }
                    if(finalMap.containsKey('to') && !finalMap.get('to').isEmpty())
                        t.celsrm__To__c = string.join(finalMap.get('to'),';');
                    if(finalMap.containsKey('bcc') && !finalMap.get('bcc').isEmpty())
                        t.celsrm__Bcc__c =  string.join(finalMap.get('bcc'),';');
                    if(finalMap.containsKey('cc') && !finalMap.get('cc').isEmpty())
                        t.celsrm__Cc__c = string.join(finalMap.get('cc'),';');
                    if(finalMap.containsKey('from') && !finalMap.get('from').isEmpty())
                        t.celsrm__From__c = Id.ValueOf(string.join(finalMap.get('from'),';'));
                }
            }
            inMap.put('editableTaskList', tlst);
            inMap.put('isVisibleDataGrid','false');
            inMap.put('CountNumberOfTask','<b>Task# : '+tlst.Size() + '</b>'); 
        } catch(Exception ex){
            System.debug('Method: fetchTaskList | Linenumber: ' + ex.getLineNumber() + ' | Message: ' + ex.getMessage());
        }
        return inMap;
    }
    
    public static Map<Object,Object> sendMassDunningEmails(Map<Object,Object> inMap){
        system.debug('from mass dunning >>'+ JSON.serialize(inMap));
        List<Object> editableTaskList = (List<Object>)inMap.get('editableTaskList');
        Map<String, Object> taskListMap = new Map<String, Object>();
		String errorMsg = null;
        Map<Integer, Set<String>> errorMsgIndexMap = new Map<Integer, Set<String>>();
        String errorMsgField = null;
        // Regular expression for email validation
        // String emailRegex = '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$';
        // Regular expression to extract email addresses (from '< >' or standalone)
        Pattern emailPattern = Pattern.compile('(?:[^<>]*)<([^<>]+)>|([^<>\\s]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,})');
        Boolean stopOuterLoop = false;

        for(Integer i = 0; i < editableTaskList.size(); i++){
            Map<Object, Object> taskMap = (map<Object, Object>)editableTaskList[i];
            if(taskMap.containsKey('isSelected') && (Boolean)taskMap.get('isSelected') == true){
                Boolean isError = false;
                String toAddress = (String)taskMap.get('celsrm__To__c');
                System.debug('ToAddress>>>'+ toAddress);
                //-- Starts | FIN-7567 | Changed by Ravi | 23 May 2025 --//
                String ccAddress = taskMap.containsKey('celsrm__Cc__c') && taskMap.get('celsrm__Cc__c') != null  ? (String)taskMap.get('celsrm__Cc__c') : '';
                String bccAddress = taskMap.containsKey('celsrm__Bcc__c') && taskMap.get('celsrm__Bcc__c') != null ? (String)taskMap.get('celsrm__Bcc__c') : '';
                //-- Ends | FIN-7567 | Changed by Ravi | 23 May 2025 --//
                if (String.isBlank(toAddress)) {
                    errorMsgIndexMap.put(i, new Set<String>{'celsrm__To__c'});
                    isError = true;
                } else {
                    //-- Starts | FIN-7306| Changes By: Asera | 3 Apr 2025 --//
                    Set<String> emailSet = new Set<String>();
                    // Normalize delimiters (replace ',' with ';' so we can split easily)
                    toAddress = toAddress.replace(',', ';');
                    toAddress = toAddress.replaceAll('[‘’“”\'"]', ''); 
                    for (String emailEntry : toAddress.split(';')) {
                            emailEntry = emailEntry.trim();
                            Matcher matcher = emailPattern.matcher(emailEntry);
                            if (matcher.matches()) {
                                // Extract valid email (either from <email> or plain email)
                                String extractedEmail = String.isNotBlank(matcher.group(1)) ? matcher.group(1) : matcher.group(2);
                                System.debug('emailSet>>'+ extractedEmail);
                                emailSet.add(extractedEmail.trim().toLowerCase()); // Ensure uniqueness
                            } else {
                                // Store invalid email for error tracking
                                if(!errorMsgIndexMap.containsKey(i)){
                                     errorMsgIndexMap.put(i, new Set<String>{'celsrm__To__c'});
                                     isError = true;
                                } 
                            }
                    }
                    if(isError == false){
                        String toEmailsString = emailSet.isEmpty() ? '' : String.join(new List<String>(emailSet), ';');
                        taskMap.put('celsrm__To__c', toEmailsString);
                        System.debug('taskMapTo'+ toEmailsString);
                    }
                    // List<String> toList = toAddress.split(';');
                    // for(String to : toList){
                    //     if(!Pattern.matches(emailRegex, to)){
                    //         if(!errorMsgIndexMap.containsKey(i)){
                    //             errorMsgIndexMap.put(i, new Set<String>{'celsrm__To__c'});
                    //             isError = true;
                    //         } 
                    //     }
                    // }
                }
                if(!String.isBlank(ccAddress)){
                    Set<String> ccemailSet = new Set<String>();
                    ccAddress = ccAddress.replace(',', ';');
                    ccAddress = ccAddress.replaceAll('[‘’“”\'"]', ''); 
                    for (String emailEntry : ccAddress.split(';')) {
                            emailEntry = emailEntry.trim();
                            Matcher matcher = emailPattern.matcher(emailEntry);
                            if (matcher.matches()) {
                                String extractedEmail = String.isNotBlank(matcher.group(1)) ? matcher.group(1) : matcher.group(2);
                                ccemailSet.add(extractedEmail.trim().toLowerCase()); 
                            } else {
                                if(!errorMsgIndexMap.containsKey(i)){
                                     errorMsgIndexMap.put(i, new Set<String>{'celsrm__Cc__c'});
                                     isError = true;
                                } 
                            }
                    }
                    if(isError == false){
                        String toEmailsString = ccemailSet.isEmpty() ? '' : String.join(new List<String>(ccemailSet), ';');
                        taskMap.put('celsrm__Cc__c', toEmailsString);
                        System.debug('taskMapCC'+ toEmailsString);
                    }
                }
                 //-- End | FIN-7306| Changes By: Asera | 3 Apr 2025 --//
                 //-- Starts | FIN-7567 | Changed by Ravi | 23 May 2025 --//
                if(!String.isBlank(bccAddress)){
                    Set<String> bccemailSet = new Set<String>();
                    bccAddress = bccAddress.replace(',', ';');
                    bccAddress = bccAddress.replaceAll('[‘’“”\'"]', ''); 
                    for (String emailEntry : bccAddress.split(';')) {
                            emailEntry = emailEntry.trim();
                            Matcher matcher = emailPattern.matcher(emailEntry);
                            if (matcher.matches()) {
                                String extractedEmail = String.isNotBlank(matcher.group(1)) ? matcher.group(1) : matcher.group(2);
                                bccemailSet.add(extractedEmail.trim().toLowerCase()); 
                            } else {
                                if(!errorMsgIndexMap.containsKey(i)){
                                     errorMsgIndexMap.put(i, new Set<String>{'celsrm__Bcc__c'});
                                     isError = true;
                                } 
                            }
                    }
                    if(isError == false){
                        String toEmailsString = bccemailSet.isEmpty() ? '' : String.join(new List<String>(bccemailSet), ';');
                        taskMap.put('celsrmc_Bcc__c', toEmailsString);
                        System.debug('taskMapCC'+ toEmailsString);
                    }
                }
                //-- End | FIN-7567 | Changed by Ravi | 23 May 2025 --//
                // if(!String.isBlank(ccAddress)){
                //     List<String> ccList = ccAddress.split(';');
                //     for(String cc : ccList){
                //         if(!Pattern.matches(emailRegex, cc)){
                //             if(errorMsgIndexMap.containsKey(i)){
                //                 Set<String> fieldList = errorMsgIndexMap.get(i);
                //                 fieldList.add('celsrm__Cc__c');
                //                 errorMsgIndexMap.put(i, fieldList);
                //                 isError = true;
                //             } else {
                //                 errorMsgIndexMap.put(i, new Set<String>{'celsrm__Cc__c'});
                //                 isError = true;
                //             }
                //         }
                //     }
                // }
                
                if(isError == false) {
                    String taskID = (String)taskMap.get('Id');
                    editableTaskList[i] = taskMap;
                    taskListMap.put(taskID, editableTaskList[i]);
                }
            }
        } 

        if(!errorMsgIndexMap.isEmpty()){
            inMap.put('errorMessage', Label.Error_Missing_Or_Invalid_Email_Address);
            inMap.put('errorMessageIndex', errorMsgIndexMap);
        } else {
            if(!taskListMap.isEmpty()){
                //-- Start | FIN-8313 | Changed by Ravi | 10 sep 2025 --//
                System.enqueueJob(new MassDunningBatch(taskListMap));
                // MassDunningBatch dunningBatch = new MassDunningBatch(taskListMap);
                //-- Start | FIN-8085 | Changed by Ravi | 4 Aug 2025 --//
                // Database.executeBatch(dunningBatch, 5);
                //-- End | FIN-8085 | Changed by Ravi | 4 Aug 2025 --//
                //-- End | FIN-8313 | Changed by Ravi | 10 sep 2025 --//

                inMap.put('ggSuccessMessage', Label.Mass_Dunning_Success_Message);
            
            } else {
                inMap.put('errorMessage', Label.Error_No_Task_Selected_For_Dunning);
            }
        }
        //-- Starts |FIN-7502| Changed by Asera | 25 Nov 2025 --//
        try {
            Map<String, Object> metadataMap = new Map<String, Object>{
                'MassDunningObj' => inMap,
                'timestamp' => String.valueOf(Datetime.now())
            };
            Id activityId = (Id) inMap.get('activityLogIdFromScreen');
            // Convert to JSON string
            String metadataJson = JSON.serialize(metadataMap);
            celsrm.SRMUtilityController.updateActivity(activityId, metadataJson);
            
            System.debug('Activity logged with Id: ' + activityId);
        } catch (Exception e) {
            System.debug('Failed to log activity: ' + e.getMessage());
        }
        //-- End |FIN-7502| Changed by Asera | 25 Nov 2025 --//

        return inMap;
    }

    //-- Start | FIN-8492  | Changed By Asera | 10 Oct 2025 --//
    public static Set<Id> getAllOwnerIdsForUser(Id userId) {
        Set<Id> ownerIds = new Set<Id>{ userId };
        Set<Id> groupsToCheck = new Set<Id>();
        Set<Id> processedGroups = new Set<Id>();
    
        // Step 1: find all groups (queues/public groups) the user is a member of
        for (GroupMember gm : [
            SELECT GroupId
            FROM GroupMember
            WHERE UserOrGroupId = :userId
        ]) {
            groupsToCheck.add(gm.GroupId);
        }
    
        // Step 2: handle nested groups
        while (!groupsToCheck.isEmpty()) {
            Set<Id> nextGroups = new Set<Id>();
    
            for (GroupMember gm : [
                SELECT GroupId, UserOrGroupId
                FROM GroupMember
                WHERE UserOrGroupId IN :groupsToCheck
            ]) {
                if(!processedGroups.contains(gm.UserOrGroupId)) {
                    nextGroups.add(gm.GroupId);
                }
            }
    
            processedGroups.addAll(groupsToCheck);
            ownerIds.addAll(groupsToCheck);
            groupsToCheck = nextGroups;
        }
    
        return ownerIds;
    }
    //-- End | FIN-8492  | Changed By Asera | 10 Oct 2025 --//

    // public class ObjectCriteria {
    //     public String stepName;
    //     public String taskSubject;
    //     public Integer order;
    //     public List<Criteria> criteria; 
    //     public String criteriaCondition;
    //     public Boolean active;
    //     public String dueDate;
    //     public String dueDateCustom;
    //     public List<String> taskType;
    //     public String template;
    //     public String emailTemplatePrefix;
    //     public Boolean enableDynamicTemplate;
    //     public String templateFolderReferenceField;
    //     public List<String> columns;
    //     public String sortField;
    //     public String sortDirection;
    //     public Boolean calculateTotal;
    //     public Boolean showTotal;
    //     public String aggregationField;
    //     public String totalTitle;
    //     public String description;
    //     public String fromAddress;
    //     public Boolean notifyAccountOwner;
    //     public Boolean attachment;
    //     public String customLogicClass;
    //     public Boolean autoDunning;
    // }

    // public class Criteria {
    //     public String field;
    //     public String operator;
    //     public String value;
    // }

}