global with sharing class DisputeConfigurationScreenController implements celsrm.GOGIScreenCustomLogic{
    global Map<Object, Object> invoke(String functionName, Map<Object, Object> inMap){
        try {
            system.debug('FunctionName>>>>>'+functionName);
            //inMap.put('functionName', functionName);
            if(functionName == 'getDisputeWorkflowMatrixList'){
                inMap = getDisputeWorkflowMatrixList(inMap);
            }if(functionName == 'getDisputeReminderAndEscalationMatrixList'){
                inMap = getDisputeReminderAndEscalationMatrixList(inMap);
            } else if(functionName == 'onDeleteRecord'){
                inMap = onDeleteRecord(inMap);
            } else if(functionName == 'updateDisputeWorkflowMatrix'){
                inMap = updateDisputeWorkflowMatrix(inMap);
            }
        } catch(exception ex){
            String errorMessage = 'ClassName: DisputeConfigurationScreenController | Method: invoke() | Linenumber: ' + ex.getLineNumber() + ' | Message: ' + ex.getMessage();
            System.debug('errorMessage: ' + errorMessage);
        }
        return inMap;
    }

    public static Map<Object, Object> updateDisputeWorkflowMatrix(Map<Object, Object> inMap){
        try {
            System.debug('Inside updateDisputeWorkflowMatrix >>>>');
            String recordId = (String)inMap.get('Id');
            celsrm__Dispute_Workflow_Matrix__c dwm = new celsrm__Dispute_Workflow_Matrix__c(Id = recordId);
            //-- Start | FIN-9672 | Changed by Ravi | 05 May 2026 --//
            Id userMasterId;
            if (inMap.get('User') != null) {
                Map<Object, Object> userMasterMap = (Map<Object, Object>)inMap.get('User');
                userMasterId = userMasterMap.get('id') != null ? Id.valueOf(String.valueOf(userMasterMap.get('id'))) : null;
            }

            if (userMasterId != null) {
                //-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
                dwm.celsrm__User_Master__c = userMasterId;
                //-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
            } else {
                //-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
                dwm.celsrm__User_Master__c = null;
                //-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
            }
            //-- End | FIN-9672 | Changed by Ravi | 05 May 2026 --//
            if(inMap.get('disputeType') != null){
                dwm.celsrm__Dispute_Type__c = (String)inMap.get('disputeType');
            } else {
                dwm.celsrm__Dispute_Type__c = null;
            }
            if(inMap.get('reasonCode') != null){
                dwm.celsrm__Reason_Code__c = (String)inMap.get('reasonCode');
            } else {
                dwm.celsrm__Reason_Code__c = null;
            }
            if(inMap.get('level') != null){
                dwm.celsrm__Level__c = (Decimal)inMap.get('level');
            } else {
                dwm.celsrm__Level__c = null;
            }
            if(inMap.get('userSLADays') != null){
                dwm.celsrm__User_SLA_Days__c = (Decimal)inMap.get('userSLADays');
            } else {
                dwm.celsrm__User_SLA_Days__c = null;
            }
            if(inMap.get('userType') != null){
                dwm.celsrm__User_Type__c = (String)inMap.get('userType');
            } else {
                dwm.celsrm__User_Type__c = null;
            }
            if(inMap.get('approvalLimit') != null){
                dwm.celsrm__Approval_Limit__c = (Decimal)inMap.get('approvalLimit');
            } else {
                dwm.celsrm__Approval_Limit__c = null;
            }
            if(inMap.get('active') != null){
                dwm.celsrm__Is_Active__c = (Boolean)inMap.get('active');
            } else {
                dwm.celsrm__Is_Active__c = false;
            }
            if(inMap.get('optional') != null){
                dwm.celsrm__Optional__c = (Boolean)inMap.get('optional');
            } else {
                dwm.celsrm__Optional__c = false;
            }
            update dwm;
        } catch(Exception ex) {
            inMap.put('ggErrorMessage', 'Method: updateDisputeWorkflowMatrix | Linenumber: ' + ex.getLineNumber() + ' | Message: ' + ex.getMessage());
            System.debug('Method: updateDisputeWorkflowMatrix | Linenumber: ' + ex.getLineNumber() + ' | Message: ' + ex.getMessage());
        }
        return inMap;
    }
    public static Map<Object, Object> getDisputeWorkflowMatrixList(Map<Object, Object> inMap){
        try {
            System.debug('Inside getDisputeWorkflowMatrixList >>>>');

            List<Map<String, Object>> disputeWorflowGrid = new List<Map<String, Object>>();
            //-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
            for (celsrm__Dispute_Workflow_Matrix__c record : [
                SELECT Id,
                    Name,
                    celsrm__User_Master__c,
                    celsrm__User_Master__r.Name,
                    celsrm__User_Master__r.celsrm__Email__c,
                    celsrm__User_Master__r.celsrm__User__c,
                    celsrm__User_Master__r.celsrm__Is_External_User__c,
                    celsrm__User_Master__r.celsrm__Manager__c,
                    celsrm__User_Master__r.celsrm__Manager__r.Name,
                    celsrm__User_Master__r.celsrm__Manager__r.celsrm__Email__c,
                    celsrm__User_Type__c,
                    celsrm__User_SLA_Days__c,
                    celsrm__Approval_Limit__c,
                    celsrm__Level__c,
                    celsrm__Dispute_Type__c,
                    celsrm__Reason_Code__c,
                    celsrm__Is_Active__c
                FROM celsrm__Dispute_Workflow_Matrix__c
                ORDER BY celsrm__Dispute_Type__c, celsrm__Reason_Code__c, celsrm__Level__c ASC
            ]) {
            //-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
                Map<String, Object> recordMap = new Map<String, Object>();
                recordMap.put('Id', record.Id);
                recordMap.put('name', record.Name);
                recordMap.put('Name', '<a href="' + '/'+ record.Id + '"' + ' target="_blank">' + record.Name + '</a>');
                DisputeUserMasterService.ResolvedUserInfo resolvedUser = DisputeUserMasterService.resolveFromMatrixRecord(record);
                String escalationEmail = DisputeUserMasterService.resolveEscalationEmailFromMatrixRecord(record, resolvedUser);
                //-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
                recordMap.put('userMasterId', record.celsrm__User_Master__c);
                if (resolvedUser != null) {
                //-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
                    recordMap.put('userEmail', resolvedUser.email);
                    recordMap.put('userName', resolvedUser.name);
                    recordMap.put('isExternalUser', resolvedUser.isExternal());
                    //-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
                    String manager = resolvedUser.managerName;
                    if (!String.isBlank(manager) && resolvedUser.managerUserMasterId != null) {
                        manager = '<a href="' + '/' + resolvedUser.managerUserMasterId + '" target="_blank">' + manager + '</a>';
                    }
                    recordMap.put('manager', manager);
                    //-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
                }
                recordMap.put('userType', record.celsrm__User_Type__c);
                recordMap.put('SLADays', record.celsrm__User_SLA_Days__c);
                //-- Start | FIN-9672 | Changed by Ravi | 05 May 2026 --//
                recordMap.put('escalationEmail', escalationEmail);
                //-- End | FIN-9672 | Changed by Ravi | 05 May 2026 --//
                recordMap.put('approvalLimit', record.celsrm__Approval_Limit__c);
                recordMap.put('workflowLevel', record.celsrm__Level__c);
                recordMap.put('disputeType', record.celsrm__Dispute_Type__c);
                recordMap.put('reasonCode', record.celsrm__Reason_Code__c);
                if(record.celsrm__Is_Active__c) {
                    // recordMap.put('active', '<span title="'+record.celsrm__Is_Active__c+'" style="height: 20px;width: 20px;display: block;background-color: green;border-radius: 10px;"></span>');
                    recordMap.put('active', 
                    '<span title="'+record.celsrm__Is_Active__c+'" ' +
                    'style="height: 17px; width: 17px; display: inline-block; background-color: green; border-radius: 50%; text-align: center; line-height: 17px;">' +
                    '<i class="fa fa-check" style="color: white;font-size: 11px;"></i></span>');
                } else {
                    // recordMap.put('active', '<span title="'+record.celsrm__Is_Active__c+'" style="height: 20px;width: 20px;display: block;background-color: red;border-radius: 10px;"></span>');
                    recordMap.put('active', 
                    '<span title="'+record.celsrm__Is_Active__c+'" ' +
                    'style="height: 17px; width: 17px; display: inline-block; background-color: red; border-radius: 50%; text-align: center; line-height: 17px;">' +
                    '<i class="fa fa-times" style="color: white;font-size: 11px;"></i></span>');
                }
                disputeWorflowGrid.add(recordMap);
            }

            inMap.put('dataServiceResponse', disputeWorflowGrid);
        } catch(Exception ex) {
            inMap.put('ggErrorMessage', 'Method: getDisputeWorkflowMatrixList | Linenumber: ' + ex.getLineNumber() + ' | Message: ' + ex.getMessage());
            System.debug('Method: getDisputeWorkflowMatrixList | Linenumber: ' + ex.getLineNumber() + ' | Message: ' + ex.getMessage());
        }
        return inMap;
    }

    public static Map<Object, Object> getDisputeReminderAndEscalationMatrixList(Map<Object, Object> inMap){
        try {
            System.debug('Inside getDisputeReminderAndEscalationMatrixList >>>>');

            List<Map<String, Object>> disputeReminderEscalationMatrix = new List<Map<String, Object>>();
            for(Dispute_Reminder_Escalation_Matrix__c record : [SELECT Id, Name, Dispute_Type__c, Reason_Code__c, User_Type__c,
                                Follow_Up_Type__c, Follow_Up_Escalation_Days__c, Follow_Up_Escalation_Level__c, Is_Active__c 
                                FROM Dispute_Reminder_Escalation_Matrix__c 
                                ORDER BY Dispute_Type__c, Reason_Code__c, Follow_Up_Escalation_Level__c ASC]){
                Map<String, Object> recordMap = new Map<String, Object>();
                recordMap.put('Id', record.Id);
                recordMap.put('name', record.Name);
                recordMap.put('Name', '<a href="' + '/'+ record.Id + '"' + ' target="_blank">' + record.Name + '</a>');
                recordMap.put('disputeType', record.Dispute_Type__c);
                recordMap.put('reasonCode', record.Reason_Code__c);
                recordMap.put('userType', record.User_Type__c);
                recordMap.put('followUpType', record.Follow_Up_Type__c);
                recordMap.put('followUpDays', record.Follow_Up_Escalation_Days__c);
                recordMap.put('followUpLevel', record.Follow_Up_Escalation_Level__c);
                if(record.Is_Active__c) {
                    //recordMap.put('active', '<span title="'+record.Is_Active__c+'" style="height: 20px;width: 20px;display: block;background-color: green;border-radius: 10px;"></span>');
                    recordMap.put('active', 
                    '<span title="'+record.Is_Active__c+'" ' +
                    'style="height: 17px; width: 17px; display: inline-block; background-color: green; border-radius: 50%; text-align: center; line-height: 17px;">' +
                    '<i class="fa fa-check" style="color: white;font-size: 11px;"></i></span>');
                } else {
                    //recordMap.put('active', '<span title="'+record.Is_Active__c+'" style="height: 20px;width: 20px;display: block;background-color: red;border-radius: 10px;"></span>');
                    recordMap.put('active', 
                    '<span title="'+record.Is_Active__c+'" ' +
                    'style="height: 17px; width: 17px; display: inline-block; background-color: red; border-radius: 50%; text-align: center; line-height: 17px;">' +
                    '<i class="fa fa-times" style="color: white;font-size: 11px;"></i></span>');
                }
                
                disputeReminderEscalationMatrix.add(recordMap);
            }

            inMap.put('dataServiceResponse', disputeReminderEscalationMatrix);
        } catch(Exception ex) {
            System.debug('Method: getDisputeReminderAndEscalationMatrixList | Linenumber: ' + ex.getLineNumber() + ' | Message: ' + ex.getMessage());
        }
        return inMap;
    }

    public static Map<Object, Object> onDeleteRecord(Map<Object, Object> inMap){
        try {
            System.debug('Inside onDeleteRecord >>>>');

            String recordId = (String)inMap.get('recordId');
            String objectName = (String)inMap.get('objectName');
            //-- Starts | FIN-8858 | Changed By Dhwanil Shah | 25 Feb 2026 --//
            Database.delete(recordId);
            /*if(objectName == 'celsrm__Dispute_Workflow_Matrix__c'){
                celsrm__Dispute_Workflow_Matrix__c dwm = new celsrm__Dispute_Workflow_Matrix__c(Id = recordId);
                delete dwm;
            } else if(objectName == 'Dispute_Reminder_Escalation_Matrix__c'){
                Dispute_Reminder_Escalation_Matrix__c drem = new Dispute_Reminder_Escalation_Matrix__c(Id = recordId);
                delete drem;
            }*/
            //-- Ends | FIN-8858 | Changed By Dhwanil Shah | 25 Feb 2026 --//
            inMap.put('recordId', null);
        } catch(Exception ex) {
            System.debug('Method: onDeleteRecord | Linenumber: ' + ex.getLineNumber() + ' | Message: ' + ex.getMessage());
        }
        return inMap;
    }
}