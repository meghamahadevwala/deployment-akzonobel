@IsTest
private class ReminderEscalationRuleServiceTest {
    @IsTest
    static void testDynamicRuleReturnsFollowUpMatrixEntries() {
        Map<Object, Object> rule = buildDynamicRule(
            null,
            'Dynamic Rule',
            1,
            '( 1 AND 2 )',
            new List<Object>{
                new Map<Object, Object>{
                    'field' => 'Dispute_Type__c',
                    'operator' => '=',
                    'value' => '100 Financial & Invoicing',
                    'fieldType' => 'PICKLIST'
                },
                new Map<Object, Object>{
                    'field' => 'Reason_Code__c',
                    'operator' => '=',
                    'value' => '101 Cash Discount Deduction',
                    'fieldType' => 'PICKLIST'
                }
            },
            new List<Object>{
                new Map<Object, Object>{
                    'level' => 1,
                    'userType' => 'Approver',
                    'followUpType' => 'followup',
                    'followUpDays' => 2,
                    'followUpLevel' => 1,
                    'isActive' => true
                }
            }
        );

        //-- Start | FIN-10143 | Changed by Asera | 20-Jul-2026 --//
        insertManagedReminderEscalationRule(rule);
        //-- End | FIN-10143 | Changed by Asera | 20-Jul-2026 --//

        celsrm__Dispute_Workflow_Details__c workflowDetail = buildWorkflowDetail('100 Financial & Invoicing', '101 Cash Discount Deduction', 'Approver');

        Test.startTest();
        ReminderEscalationRuleService service = new ReminderEscalationRuleService('Account_Owner');
        List<ReminderEscalationRuleService.FollowUpEntry> entries = service.getFollowUpEntries(workflowDetail);
        Test.stopTest();

        System.assertEquals(1, entries.size(), 'One follow up matrix row should match.');
        System.assertEquals('followup', entries[0].followUpType, 'Follow up type should match configured value.');
        System.assertEquals(2, entries[0].followUpDays.intValue(), 'Follow up days should match configured value.');
    }

    @IsTest
    static void testRuleWithoutCriteriaDoesNotUseLegacyFallback() {
        //-- Start | FIN-10143 | Changed by Asera | 20-Jul-2026 --//
        celsrm__Dispute_Reminder_Escalation_Matrix__c ruleWithoutCriteria = new celsrm__Dispute_Reminder_Escalation_Matrix__c(
            Name = 'Rule Without Criteria',
            celsrm__Is_Active__c = true,
            celsrm__Order__c = 1,
            celsrm__Follow_Up_Config__c = JSON.serialize(new List<Object>{
                new Map<Object, Object>{
                    'userType' => 'Approver',
                    'followUpType' => 'escalation',
                    'followUpDays' => 3,
                    'followUpLevel' => 2,
                    'isActive' => true
                }
            })
        );
        insert ruleWithoutCriteria;
        //-- End | FIN-10143 | Changed by Asera | 20-Jul-2026 --//

        celsrm__Dispute_Workflow_Details__c workflowDetail = buildWorkflowDetail('100 Financial & Invoicing', 'Invoice is missing', 'Approver');

        Test.startTest();
        ReminderEscalationRuleService service = new ReminderEscalationRuleService('Account_Owner');
        List<ReminderEscalationRuleService.FollowUpEntry> entries = service.getFollowUpEntries(workflowDetail);
        Test.stopTest();

        //-- Start | FIN-10143 | Changed by Asera | 20-Jul-2026 --//
        System.assertEquals(0, entries.size(), 'Rules without managed criteria should not use removed legacy field fallback.');
        //-- End | FIN-10143 | Changed by Asera | 20-Jul-2026 --//
    }

    @IsTest
    static void testDynamicRuleFiltersByWorkflowUserType() {
        Map<Object, Object> rule = buildDynamicRule(
            null,
            'Dynamic Resolver Rule',
            1,
            '( 1 )',
            new List<Object>{
                new Map<Object, Object>{
                    'field' => 'Dispute_Type__c',
                    'operator' => '=',
                    'value' => '100 Financial & Invoicing',
                    'fieldType' => 'PICKLIST'
                }
            },
            new List<Object>{
                new Map<Object, Object>{
                    'level' => 1,
                    'userType' => 'Resolver',
                    'followUpType' => 'followup',
                    'followUpDays' => 1,
                    'followUpLevel' => 1,
                    'isActive' => true
                }
            }
        );

        //-- Start | FIN-10143 | Changed by Asera | 20-Jul-2026 --//
        insertManagedReminderEscalationRule(rule);
        //-- End | FIN-10143 | Changed by Asera | 20-Jul-2026 --//

        celsrm__Dispute_Workflow_Details__c approverDetail = buildWorkflowDetail('100 Financial & Invoicing', 'Any Reason', 'Approver');
        celsrm__Dispute_Workflow_Details__c resolverDetail = buildWorkflowDetail('100 Financial & Invoicing', 'Any Reason', 'Resolver');

        ReminderEscalationRuleService service = new ReminderEscalationRuleService('Account_Owner');

        List<ReminderEscalationRuleService.FollowUpEntry> approverEntries = service.getFollowUpEntries(approverDetail);
        List<ReminderEscalationRuleService.FollowUpEntry> resolverEntries = service.getFollowUpEntries(resolverDetail);

        System.assertEquals(0, approverEntries.size(), 'Approver workflow detail should not receive resolver-only matrix row.');
        System.assertEquals(1, resolverEntries.size(), 'Resolver workflow detail should receive configured matrix row.');
    }

    private static Map<Object, Object> buildDynamicRule(
        String idValue,
        String nameValue,
        Object orderValue,
        String criteriaCondition,
        List<Object> criteria,
        List<Object> followUpMatrices
    ) {
        Map<Object, Object> rule = new Map<Object, Object>();
        if (idValue != null) {
            rule.put('id', idValue);
        }
        rule.put('name', nameValue);
        rule.put('order', orderValue);
        rule.put('isActive', true);
        rule.put('criteriaCondition', criteriaCondition);
        rule.put('criteria', criteria);
        rule.put('followUpMatrices', followUpMatrices);
        return rule;
    }

    //-- Start | FIN-10143 | Changed by Asera | 20-Jul-2026 --//
    private static void insertManagedReminderEscalationRule(Map<Object, Object> rule) {
        celsrm__Dispute_Reminder_Escalation_Matrix__c matrixRule = new celsrm__Dispute_Reminder_Escalation_Matrix__c(
            Name = String.valueOf(rule.get('name')),
            celsrm__Is_Active__c = true,
            celsrm__Order__c = celsrm.ApprovalConfigController.toDecimal(rule.get('order')),
            celsrm__Criteria__c = JSON.serialize(new Map<String, Object>{
                'criteriaCondition' => rule.get('criteriaCondition'),
                'criteria' => rule.get('criteria')
            }),
            celsrm__Follow_Up_Config__c = JSON.serialize(rule.get('followUpMatrices'))
        );
        insert matrixRule;
    }
    //-- End | FIN-10143 | Changed by Asera | 20-Jul-2026 --//

    private static celsrm__Dispute_Workflow_Details__c buildWorkflowDetail(
        String disputeType,
        String reasonCode,
        String workflowUserType
    ) {
        celsrm__Dispute_Workflow_Details__c workflowDetail = new celsrm__Dispute_Workflow_Details__c();
        workflowDetail.Id = buildFakeId(celsrm__Dispute_Workflow_Details__c.SObjectType);
        workflowDetail.celsrm__Dispute__c = buildFakeId(celsrm__Dispute__c.SObjectType);
        workflowDetail.celsrm__Workflow_User_Type__c = workflowUserType;
        workflowDetail.celsrm__Dispute__r = new celsrm__Dispute__c(
            Id = workflowDetail.celsrm__Dispute__c,
            celsrm__Dispute_Type__c = disputeType,
            celsrm__Reason_Code__c = reasonCode
        );
        return workflowDetail;
    }

    private static Id buildFakeId(Schema.SObjectType sobjectType) {
        String prefix = sobjectType.getDescribe().getKeyPrefix();
        return Id.valueOf(prefix + '000000000001');
    }
}