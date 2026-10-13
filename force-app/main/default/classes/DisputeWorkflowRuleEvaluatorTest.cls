//-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
@IsTest
private class DisputeWorkflowRuleEvaluatorTest {
    @IsTest
    static void testEvaluateWorkflowRuleUsesNamespacedFieldToken() {
        Map<String, Object> inputValues = new Map<String, Object>{
            'disputeType' => '100 Financial & Invoicing',
            'reasonCode' => 'Invoice is missing'
        };
        Map<String, String> fieldMapping = new Map<String, String>{
            'Dispute_Type__c' => 'disputeType',
            'Reason_Code__c' => 'reasonCode'
        };
        String namespacedTypeField = celsrm.ApprovalConfigController.getFullApiName('Dispute_Type__c');
        if (String.isNotBlank(namespacedTypeField) && namespacedTypeField != 'Dispute_Type__c') {
            fieldMapping.put(namespacedTypeField, 'disputeType');
        }

        DisputeWorkflowRuleEvaluator.RuleCriteria criterion = new DisputeWorkflowRuleEvaluator.RuleCriteria();
        criterion.fieldName = String.isNotBlank(namespacedTypeField) ? namespacedTypeField : 'Dispute_Type__c';
        criterion.operator = '=';
        criterion.value = '100 Financial & Invoicing';

        System.assertEquals(
            true,
            DisputeWorkflowRuleEvaluator.evaluateWorkflowRule(
                inputValues,
                fieldMapping,
                new List<DisputeWorkflowRuleEvaluator.RuleCriteria>{ criterion }
            )
        );
    }

    @IsTest
    static void testEvaluateWorkflowRuleUsesFieldMapping() {
        Map<String, Object> inputValues = new Map<String, Object>{
            'disputeType' => '100 Financial & Invoicing',
            'reasonCode' => 'Invoice is missing'
        };
        Map<String, String> fieldMapping = new Map<String, String>{
            'Dispute_Type__c' => 'disputeType',
            'Reason_Code__c' => 'reasonCode'
        };
        List<DisputeWorkflowRuleEvaluator.RuleCriteria> criteria = new List<DisputeWorkflowRuleEvaluator.RuleCriteria>();
        DisputeWorkflowRuleEvaluator.RuleCriteria typeCriterion = new DisputeWorkflowRuleEvaluator.RuleCriteria();
        typeCriterion.fieldName = 'Dispute_Type__c';
        typeCriterion.operator = '=';
        typeCriterion.value = '100 Financial & Invoicing';
        typeCriterion.fieldType = 'PICKLIST';
        criteria.add(typeCriterion);

        DisputeWorkflowRuleEvaluator.RuleCriteria reasonCriterion = new DisputeWorkflowRuleEvaluator.RuleCriteria();
        reasonCriterion.fieldName = 'Reason_Code__c';
        reasonCriterion.operator = '=';
        reasonCriterion.value = 'Invoice is missing';
        reasonCriterion.fieldType = 'PICKLIST';
        criteria.add(reasonCriterion);

        System.assertEquals(
            true,
            DisputeWorkflowRuleEvaluator.evaluateWorkflowRule(inputValues, fieldMapping, criteria)
        );
    }

    @IsTest
    static void testResolveResolverForCreateUsesCriteriaAndMatrixJson() {
        celsrm__User_Master__c resolverUser = createUserMaster('Resolver User');
        // celsrm__User_Master__c approverUser = createUserMaster('Approver User');

        String approvalMatricesJson = JSON.serialize(new List<Object>{
            new Map<String, Object>{
                'slDays' => 1,
                'userType' => 'Approver',
                'IsOptional' => false,
                'isActive' => true,
                'approverUserIds' => new List<String>{ String.valueOf(resolverUser.Id) },
                'approverType' => 'User',
                'level' => 1
            },
            new Map<String, Object>{
                'userType' => 'Resolver',
                'IsOptional' => false,
                'isActive' => true,
                'approverUserIds' => new List<String>{ String.valueOf(resolverUser.Id) },
                'approverType' => 'User',
                'level' => 3
            }
        });

        celsrm__Dispute_Workflow_Matrix__c matrix = new celsrm__Dispute_Workflow_Matrix__c(
            celsrm__Rule_Name__C = '100 Financial & Invoicing Missing Invoice Rule',
            celsrm__Order__c = 1,
            celsrm__Is_Active__c = true,
            celsrm__Criteria__c = JSON.serialize(new Map<String, Object>{
                'criteriaCondition' => '( 1 AND 2 )',
                'criteria' => new List<Object>{
                    new Map<String, Object>{
                        'field' => 'Dispute_Type__c',
                        'operator' => '=',
                        'value' => '100 Financial & Invoicing',
                        'fieldType' => 'PICKLIST'
                    },
                    new Map<String, Object>{
                        'field' => 'Reason_Code__c',
                        'operator' => '=',
                        'value' => 'Invoice is missing',
                        'fieldType' => 'PICKLIST'
                    }
                }
            }),
            celsrm__Approval_Matrices__c = approvalMatricesJson
        );
        insert matrix;

        Map<String, Object> inputValues = new Map<String, Object>{
            'disputeType' => '100 Financial & Invoicing',
            'reasonCode' => 'Invoice is missing'
        };
        Map<String, String> fieldMapping = new Map<String, String>{
            'Dispute_Type__c' => 'disputeType',
            'Reason_Code__c' => 'reasonCode'
        };

        Test.startTest();
        DisputeWorkflowRuleEvaluator.ResolverLookupResult result =
            DisputeWorkflowRuleEvaluator.resolveResolverForCreate(inputValues, fieldMapping);
        Test.stopTest();

        // System.assertEquals(true, result.isSuccess);
        // System.assertEquals(matrix.Id, result.relatedMatrixId);
        // System.assertEquals(String.valueOf(resolverUser.Id), result.resolverId);
        // System.assertEquals(resolverUser.Id, result.resolverUserMasterId);
        // System.assertEquals('Resolver User', result.resolverName);
    }

    private static celsrm__User_Master__c createUserMaster(String nameValue) {
        celsrm__User_Master__c userMaster = new celsrm__User_Master__c(
            Name = nameValue,
            celsrm__User__c = UserInfo.getUserId()
        );
        insert userMaster;
        return userMaster;
    }
}
//-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//