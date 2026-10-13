global with sharing class CreditManagementClass implements celsrm.GOGIScreenCustomLogic {
    global Map<Object, Object> invoke(String functionName, Map<Object, Object> inMap) {
        try {
           if (functionName == 'GetParameters') {
                inMap = GetParameters(inMap);
            } else if (functionName == 'GetParametersValueScore') {
                inMap = GetParametersValueScore(inMap);
            } else if (functionName == 'GetCreditReviewField') {
                inMap = GetCreditReviewField(inMap);
            } else if (functionName == 'GetCreditScoreField') {
                inMap = GetCreditScoreField(inMap);
            } else if (functionName == 'SaveParameter') {
                inMap = SaveParameter(inMap);
            } else if (functionName == 'SaveParameterValue') {
                inMap = SaveParameterValue(inMap);
            } else if (functionName == 'DeleteParameter') {
                inMap = DeleteParameter(inMap);
            } else if (functionName == 'DeleteParameterValue') {
                inMap = DeleteParameterValue(inMap);
            }

        } catch (Exception ex) {
            String errorMessage = 'ClassName: CreditManagementClass | Method: invoke() | Linenumber: ' + ex.getLineNumber() + ' | Message: ' + ex.getMessage();
            System.debug('errorMessage: ' + errorMessage);
        }
        return inMap;
    }
    
    public static Map<Object, Object> GetParameters(Map<Object, Object> inMap) {
        try {
            List<Object> ParametersList = new List<Object>();
            String ModelType = String.valueOf(inMap.get('ScoreCardType'));
            for(celsrm__Score_Card_Parameter__c ceParam : [SELECT Id, Name, celsrm__Exclude_If_Missing__c, celsrm__Score_If_Missing__c, celsrm__Weight__c, celsrm__Parameter_Type__c, celsrm__Credit_Review_Field__c,celsrm__Model_Type__c, celsrm__Credit_Score_Field__c FROM celsrm__Score_Card_Parameter__c WHERE celsrm__Model_Type__c =: ModelType ]){ //celsrm__Model_Type__c   
                Map<Object, Object> ParametersMap = new Map<Object, Object>();
                ParametersMap.put('ceParamId', ceParam.Id);
                ParametersMap.put('ScoreCardParameterName', ceParam.Name);
                ParametersMap.put('Weight',(ceParam.celsrm__Weight__c).setScale(3)); // /100
                System.debug('ParametersMap.get(Weight>'+ParametersMap.get('Weight'));
                //ParametersMap.put('ScoreCardType', ceParam.celsrm__Model_Type__c);
                ParametersMap.put('ParameterType', ceParam.celsrm__Parameter_Type__c != null ? ceParam.celsrm__Parameter_Type__c : '');
                ParametersMap.put('CreditReviewField', ceParam.celsrm__Credit_Review_Field__c);
                ParametersMap.put('CreditScoreField', ceParam.celsrm__Credit_Score_Field__c);
                ParametersMap.put('ExcludeIfMissing', ceParam.celsrm__Exclude_If_Missing__c);
                ParametersMap.put('ScoreCardType', ceParam.celsrm__Model_Type__c);                
                ParametersList.add(ParametersMap);
            }
            inMap.put('Parameters', ParametersList);
        } catch (Exception ex) {
            String errorMessage = 'ClassName: CreditManagementClass | Method: GetParameters() | Linenumber: ' + ex.getLineNumber() + ' | Message: ' + ex.getMessage();
            System.debug('errorMessage: ' + errorMessage);
        }
        return inMap;
    }
    
    public static Map<Object, Object> GetParametersValueScore(Map<Object, Object> inMap) {
        try {
            String ModelType = String.valueOf(inMap.get('ScoreCardType'));
            
            List<Object> ParametersList = (List<Object>)inMap.get('Parameters');
            Map<Object, Object> ParametersMap = (Map<Object, Object>)ParametersList.get(0);
            String Parameter = String.valueOf(ParametersMap.get('ceParamId'));
            inMap.put('cepId', Parameter);
            String ParameterType = String.valueOf(ParametersMap.get('ParameterType'));
            
            List<Object> ParametersValueList = new List<Object>();
            for(celsrm__Score_Card_Parameter_Value__c scpValue : [SELECT Id, Name, celsrm__Score__c, celsrm__Boolean_Value__c, celsrm__Text_Value__c, celsrm__Minimum_Number_Value__c, celsrm__Maximum_Number_Value__c, celsrm__Score_Card_Parameter__r.celsrm__Model_Type__c , celsrm__Score_Card_Parameter__c FROM celsrm__Score_Card_Parameter_Value__c WHERE celsrm__Score_Card_Parameter__c =: Parameter AND celsrm__Score_Card_Parameter__r.celsrm__Model_Type__c =: ModelType ]){  //  
                Map<Object, Object> ParametersValueMap = new Map<Object, Object>();
                if (ParameterType == 'Boolean') {
                    ParametersValueMap.put('cepValueId', scpValue.Id);
                    ParametersValueMap.put('BooleanValue', scpValue.celsrm__Boolean_Value__c);
                    ParametersValueMap.put('Score', scpValue.celsrm__Score__c);
                } else if (ParameterType == 'Currency') {
                    ParametersValueMap.put('cepValueId', scpValue.Id);
                    ParametersValueMap.put('MinimumCurrencyParameter', scpValue.celsrm__Minimum_Number_Value__c);
                    ParametersValueMap.put('MaximumCurrencyParameter', scpValue.celsrm__Maximum_Number_Value__c);
                    ParametersValueMap.put('Score', scpValue.celsrm__Score__c.setScale(3));
                } else if (ParameterType == 'Number') {
                    ParametersValueMap.put('cepValueId', scpValue.Id);
                    ParametersValueMap.put('MinimumNumberParameter', scpValue.celsrm__Minimum_Number_Value__c);
                    ParametersValueMap.put('MaximumNumberParameter', scpValue.celsrm__Maximum_Number_Value__c);
                    ParametersValueMap.put('Score', scpValue.celsrm__Score__c);
                } else if (ParameterType == 'Text') {
                    ParametersValueMap.put('cepValueId', scpValue.Id);
                    ParametersValueMap.put('ParameterValue', scpValue.celsrm__Text_Value__c);
                    ParametersValueMap.put('Score', scpValue.celsrm__Score__c);
                }
                ParametersValueMap.put('cepId', scpValue.celsrm__Score_Card_Parameter__c);
                ParametersValueMap.put('ParameterType', ParameterType);
                ParametersValueList.add(ParametersValueMap);
            }
            inMap.put('ParametersValueScore', ParametersValueList);
            system.debug('ParametersValueScore>>>'+ inMap.get('ParametersValueScore'));
            inMap.put('ParameterType', ParameterType);
            List<Object> pvColumnList = new List<Object>();
            if (ParameterType == 'Boolean') {
                Map<Object,Object> pvColumnMap1 = new Map<Object,Object>();
                pvColumnMap1.put('label', 'BOOLEAN VALUE');
                pvColumnMap1.put('fieldName', 'BooleanValue');
                pvColumnMap1.put('type', 'boolean');
                pvColumnMap1.put('sortable', true);
                pvColumnList.add(pvColumnMap1);
            } else if (ParameterType == 'Currency') {
                Map<Object,Object> pvColumnMap1 = new Map<Object,Object>();
                pvColumnMap1.put('label', 'MINIMUM CURRENCY PARAMETER');
                pvColumnMap1.put('fieldName', 'MinimumCurrencyParameter');
                pvColumnMap1.put('type', 'currency');
                pvColumnMap1.put('sortable', true);
                pvColumnList.add(pvColumnMap1);
                
                Map<Object,Object> pvColumnMap2 = new Map<Object,Object>();
                pvColumnMap2.put('label', 'MINIMUM CURRENCY PARAMETER');
                pvColumnMap2.put('fieldName', 'MaximumCurrencyParameter');
                pvColumnMap2.put('type', 'currency');
                pvColumnMap2.put('sortable', true);
                pvColumnList.add(pvColumnMap2);
            } else if (ParameterType == 'Number') {
                Map<Object,Object> pvColumnMap1 = new Map<Object,Object>();
                pvColumnMap1.put('label', 'START RANGE');
                pvColumnMap1.put('fieldName', 'MinimumNumberParameter');
                pvColumnMap1.put('type', 'number');
                pvColumnMap1.put('sortable', true);
                pvColumnList.add(pvColumnMap1);
                
                Map<Object,Object> pvColumnMap2 = new Map<Object,Object>();
                pvColumnMap2.put('label', 'END RANGE');
                pvColumnMap2.put('fieldName', 'MaximumNumberParameter');
                pvColumnMap2.put('type', 'number');
                pvColumnMap2.put('sortable', true);
                pvColumnList.add(pvColumnMap2);
            } else if (ParameterType == 'Text') {
                Map<Object,Object> pvColumnMap1 = new Map<Object,Object>();
                pvColumnMap1.put('label', 'PARAMETER VALUE');
                pvColumnMap1.put('fieldName', 'ParameterValue');
                pvColumnMap1.put('type', 'text');
                pvColumnMap1.put('sortable', true);
                pvColumnList.add(pvColumnMap1);
            }
            
            Map<Object,Object> pvColumnMap3 = new Map<Object,Object>();
            pvColumnMap3.put('label', 'SCORE');
            pvColumnMap3.put('fieldName', 'Score');
            pvColumnMap3.put('type', 'number');
            pvColumnMap3.put('sortable', true);
            pvColumnMap3.put('width', 'width:5rem');
            pvColumnList.add(pvColumnMap3);
            
            inMap.put('ParametersValueScoreColumns', pvColumnList);
        } catch (Exception ex) {
            String errorMessage = 'ClassName: CreditManagementClass | Method: GetParametersValueScore() | Linenumber: ' + ex.getLineNumber() + ' | Message: ' + ex.getMessage();
            System.debug('errorMessage: ' + errorMessage);
        }
        return inMap;
    }
    
    public static Map<Object, Object> GetCreditReviewField(Map<Object, Object> inMap) {
        try {
            List<Object> creditAppFields = new List<Object>();
            Map<String, Schema.Sobjectfield> fieldMap = Schema.sObjectType.celsrm__Credit_Review__c.fields.getMap();
            for(String fieldname : fieldMap.keySet()){ 
                Map<Object, Object> customField = new Map<Object, Object>();
                customField.put('label',fieldMap.get(fieldname).getDescribe().getLabel());
                customField.put('value',fieldMap.get(fieldname).getDescribe().getName());
                creditAppFields.add(customField);
            }
            inMap.put('dataServiceResponse', creditAppFields);
        } catch (Exception ex) {
            String errorMessage = 'ClassName: CreditManagementClass | Method: GetCreditReviewField() | Linenumber: ' + ex.getLineNumber() + ' | Message: ' + ex.getMessage();
            System.debug('errorMessage: ' + errorMessage);
        }
        return inMap;
    }

    public static Map<Object, Object> GetCreditScoreField(Map<Object, Object> inMap) {
        try {
            List<Object> creditAppFields = new List<Object>();
            Map<String, Schema.Sobjectfield> fieldMap = Schema.sObjectType.celsrm__Credit_Score__c.fields.getMap();
            for(String fieldname : fieldMap.keySet()){ 
                Map<Object, Object> customField = new Map<Object, Object>();
                customField.put('label',fieldMap.get(fieldname).getDescribe().getLabel());
                customField.put('value',fieldMap.get(fieldname).getDescribe().getName());
                creditAppFields.add(customField);
            }
            inMap.put('dataServiceResponse', creditAppFields);
        } catch (Exception ex) {
            String errorMessage = 'ClassName: CreditManagementClass | Method: GetCreditScoreField() | Linenumber: ' + ex.getLineNumber() + ' | Message: ' + ex.getMessage();
            System.debug('errorMessage: ' + errorMessage);
        }
        return inMap;
    }
    
    public static Map<Object, Object> SaveParameter(Map<Object, Object> inMap) {
        try {
            celsrm__Score_Card_Parameter__c scp = new celsrm__Score_Card_Parameter__c();
            if(inMap.containsKey('ceParamId')) {
                scp.Id = String.valueOf(inMap.get('ceParamId'));
            }
            scp.Name = String.valueOf(inMap.get('ScoreCardParameterName'));
            scp.celsrm__Model_Type__c = String.valueOf(inMap.get('ScoreCardType'));
            scp.celsrm__Credit_Review_Field__c = String.valueOf(inMap.get('CreditReviewField'));
            scp.celsrm__Credit_Score_Field__c = String.valueOf(inMap.get('CreditScoreField'));
            scp.celsrm__Parameter_Type__c = String.valueOf(inMap.get('ParameterType'));
            scp.celsrm__Weight__c = Double.valueOf(inMap.get('Weight'));
            scp.celsrm__Exclude_If_Missing__c = Boolean.valueOf(inMap.get('ExcludeIfMissing'));
            scp.celsrm__Score_If_Missing__c = String.valueOf(inMap.get('MissingScoreValue'));
            upsert scp;
            System.debug('scp>>>>'+scp);
            List<Object> paramList = (List<Object>)inMap.get('Parameters');
            if(inMap.containsKey('ceParamId')) {
                Integer Index = Integer.valueOf(inMap.get('gogGridIndex'));
                Map<Object, Object> ParametersMap = (Map<Object,Object>)paramList.get(Index);                
                ParametersMap.put('ceParamId', scp.Id);
                ParametersMap.put('ScoreCardParameterName', scp.Name);
                ParametersMap.put('Weight', scp.celsrm__Weight__c); // /100
                ParametersMap.put('ScoreCardType', scp.celsrm__Model_Type__c);
                ParametersMap.put('ParameterType', scp.celsrm__Parameter_Type__c);
                ParametersMap.put('CreditReviewField', scp.celsrm__Credit_Review_Field__c);
                ParametersMap.put('ExcludeIfMissing', scp.celsrm__Exclude_If_Missing__c);
                ParametersMap.put('MissingScoreValue', scp.celsrm__Score_If_Missing__c);
            } else {
                Map<Object, Object> ParametersMap = new Map<Object,Object>();                
                ParametersMap.put('ceParamId', scp.Id);
                ParametersMap.put('ScoreCardParameterName', scp.Name);
                ParametersMap.put('Weight', scp.celsrm__Weight__c); // /100
                ParametersMap.put('ScoreCardType', scp.celsrm__Model_Type__c);
                ParametersMap.put('ParameterType', scp.celsrm__Parameter_Type__c);
                ParametersMap.put('CreditReviewField', scp.celsrm__Credit_Review_Field__c);
                ParametersMap.put('ExcludeIfMissing', scp.celsrm__Exclude_If_Missing__c);
                ParametersMap.put('MissingScoreValue', scp.celsrm__Score_If_Missing__c);
                paramList.add(ParametersMap);
            }
            System.debug('paramList>>>>'+paramList);
            Map<Object, Object> refreshParentValues = new Map<Object, Object>();
            refreshParentValues.put('Parameters', paramList);
            inMap.put('refreshParentValues', refreshParentValues);
        } catch (Exception ex) {
            String errorMessage = 'ClassName: CreditManagementClass | Method: SaveParameter() | Linenumber: ' + ex.getLineNumber() + ' | Message: ' + ex.getMessage();
            System.debug('errorMessage: ' + errorMessage);
        }
        return inMap;
    }
    
    public static Map<Object, Object> SaveParameterValue(Map<Object, Object> inMap) {
        try {
            celsrm__Score_Card_Parameter_Value__c cepv = new celsrm__Score_Card_Parameter_Value__c();
            if(inMap.containsKey('cepValueId')) {
                cepv.Id = String.valueOf(inMap.get('cepValueId'));
            }
            if (String.valueOf(inMap.get('ParameterType')) == 'Boolean') {
                cepv.celsrm__Boolean_Value__c = Boolean.valueOf(inMap.get('BooleanValue'));
            } else if (String.valueOf(inMap.get('ParameterType')) == 'Text') {
                cepv.celsrm__Text_Value__c = String.valueOf(inMap.get('ParameterValue'));
            } else if (String.valueOf(inMap.get('ParameterType')) == 'Number') {
                cepv.celsrm__Minimum_Number_Value__c = Double.valueOf(inMap.get('MinimumNumberParameter'));
                cepv.celsrm__Maximum_Number_Value__c = Double.valueOf(inMap.get('MaximumNumberParameter'));
            } else if (String.valueOf(inMap.get('ParameterType')) == 'Currency') {
                cepv.celsrm__Minimum_Number_Value__c = Double.valueOf(inMap.get('MinimumCurrencyParameter'));
                cepv.celsrm__Maximum_Number_Value__c = Double.valueOf(inMap.get('MaximumCurrencyParameter'));
            }
            cepv.celsrm__Score__c = Double.valueOf(inMap.get('Score'));
            cepv.celsrm__Score_Card_Parameter__c = String.valueOf(inMap.get('cepId'));
            upsert cepv;
            
            // List<Object> pvScoreList1 = inMap.get('ParametersValueScore'); 

            System.debug('ParametersValueScore?>>>>>'+inMap.get('ParametersValueScore'));
           
            String ParameterType = String.valueOf(inMap.get('ParameterType'));
            List<Object> pvScoreList = (List<Object>)inMap.get('ParametersValueScore');
            if (inMap.containsKey('cepValueId')) {
                if(inMap.containsKey('gogGridIndex') ){
                    Integer Index = Integer.valueOf(inMap.get('gogGridIndex'));
                    Map<Object, Object> ParametersValueMap = (Map<Object,Object>)pvScoreList.get(Index);    
                    if (ParameterType == 'Boolean') {
                        ParametersValueMap.put('cepValueId', cepv.Id);
                        ParametersValueMap.put('BooleanValue', cepv.celsrm__Boolean_Value__c);
                        ParametersValueMap.put('Score', cepv.celsrm__Score__c);
                    } else if (ParameterType == 'Currency') {
                        ParametersValueMap.put('cepValueId', cepv.Id);
                        ParametersValueMap.put('MinimumCurrencyParameter', cepv.celsrm__Minimum_Number_Value__c);
                        ParametersValueMap.put('MaximumCurrencyParameter', cepv.celsrm__Maximum_Number_Value__c);
                        ParametersValueMap.put('Score', cepv.celsrm__Score__c);
                    } else if (ParameterType == 'Number') {
                        ParametersValueMap.put('cepValueId', cepv.Id);
                        ParametersValueMap.put('MinimumNumberParameter', cepv.celsrm__Minimum_Number_Value__c);
                        ParametersValueMap.put('MaximumNumberParameter', cepv.celsrm__Maximum_Number_Value__c);
                        ParametersValueMap.put('Score', cepv.celsrm__Score__c);
                    } else if (ParameterType == 'Text') {
                        ParametersValueMap.put('cepValueId', cepv.Id);
                        ParametersValueMap.put('ParameterValue', cepv.celsrm__Text_Value__c);
                        ParametersValueMap.put('Score', cepv.celsrm__Score__c);
                    }
                    ParametersValueMap.put('cepId', cepv.celsrm__Score_Card_Parameter__c);
                    ParametersValueMap.put('ParameterType', ParameterType);
                }
            } else {
                Map<Object, Object> ParametersValueMap = new Map<Object, Object>();
                if (ParameterType == 'Boolean') {
                    ParametersValueMap.put('cepValueId', cepv.Id);
                    ParametersValueMap.put('BooleanValue', cepv.celsrm__Boolean_Value__c);
                    ParametersValueMap.put('Score', cepv.celsrm__Score__c);
                } else if (ParameterType == 'Currency') {
                    ParametersValueMap.put('cepValueId', cepv.Id);
                    ParametersValueMap.put('MinimumCurrencyParameter', cepv.celsrm__Minimum_Number_Value__c);
                    ParametersValueMap.put('MaximumCurrencyParameter', cepv.celsrm__Maximum_Number_Value__c);
                    ParametersValueMap.put('Score', cepv.celsrm__Score__c);
                } else if (ParameterType == 'Number') {
                    ParametersValueMap.put('cepValueId', cepv.Id);
                    ParametersValueMap.put('MinimumNumberParameter', cepv.celsrm__Minimum_Number_Value__c);
                    ParametersValueMap.put('MaximumNumberParameter', cepv.celsrm__Maximum_Number_Value__c);
                    ParametersValueMap.put('Score', cepv.celsrm__Score__c);
                } else if (ParameterType == 'Text') {
                    ParametersValueMap.put('cepValueId', cepv.Id);
                    ParametersValueMap.put('ParameterValue', cepv.celsrm__Text_Value__c);
                    ParametersValueMap.put('Score', cepv.celsrm__Score__c);
                }
                ParametersValueMap.put('cepId', cepv.celsrm__Score_Card_Parameter__c);
                ParametersValueMap.put('ParameterType', ParameterType);
                pvScoreList.add(ParametersValueMap);
            }
            /*if (inMap.containsKey('cepValueId')) {
                Integer Index = Integer.valueOf(inMap.get('gogGridIndex'));
                Map<Object, Object> ParametersValueMap = (Map<Object,Object>)pvScoreList.get(Index);
                if (ParameterType == 'Boolean') {
                    ParametersValueMap.put('cepValueId', cepv.Id);
                    ParametersValueMap.put('BooleanValue', cepv.celsrm__Boolean_Value__c);
                    ParametersValueMap.put('Score', cepv.celsrm__Score__c);
                } else if (ParameterType == 'Currency') {
                    ParametersValueMap.put('cepValueId', cepv.Id);
                    ParametersValueMap.put('MinimumCurrencyParameter', cepv.celsrm__Minimum_Number_Value__c);
                    ParametersValueMap.put('MaximumCurrencyParameter', cepv.celsrm__Maximum_Number_Value__c);
                    ParametersValueMap.put('Score', cepv.celsrm__Score__c);
                } else if (ParameterType == 'Number') {
                    ParametersValueMap.put('cepValueId', cepv.Id);
                    ParametersValueMap.put('MinimumNumberParameter', cepv.celsrm__Minimum_Number_Value__c);
                    ParametersValueMap.put('MaximumNumberParameter', cepv.celsrm__Maximum_Number_Value__c);
                    ParametersValueMap.put('Score', cepv.celsrm__Score__c);
                } else if (ParameterType == 'Text') {
                    ParametersValueMap.put('cepValueId', cepv.Id);
                    ParametersValueMap.put('ParameterValue', cepv.celsrm__Text_Value__c);
                    ParametersValueMap.put('Score', cepv.celsrm__Score__c);
                }
                ParametersValueMap.put('cepId', cepv.celsrm__Score_Card_Parameter__c);
                ParametersValueMap.put('ParameterType', ParameterType);
            } else {
                Map<Object, Object> ParametersValueMap = new Map<Object, Object>();
                if (ParameterType == 'Boolean') {
                    ParametersValueMap.put('cepValueId', cepv.Id);
                    ParametersValueMap.put('BooleanValue', cepv.celsrm__Boolean_Value__c);
                    ParametersValueMap.put('Score', cepv.celsrm__Score__c);
                } else if (ParameterType == 'Currency') {
                    ParametersValueMap.put('cepValueId', cepv.Id);
                    ParametersValueMap.put('MinimumCurrencyParameter', cepv.celsrm__Minimum_Number_Value__c);
                    ParametersValueMap.put('MaximumCurrencyParameter', cepv.celsrm__Maximum_Number_Value__c);
                    ParametersValueMap.put('Score', cepv.celsrm__Score__c);
                } else if (ParameterType == 'Number') {
                    ParametersValueMap.put('cepValueId', cepv.Id);
                    ParametersValueMap.put('MinimumNumberParameter', cepv.celsrm__Minimum_Number_Value__c);
                    ParametersValueMap.put('MaximumNumberParameter', cepv.celsrm__Maximum_Number_Value__c);
                    ParametersValueMap.put('Score', cepv.celsrm__Score__c);
                } else if (ParameterType == 'Text') {
                    ParametersValueMap.put('cepValueId', cepv.Id);
                    ParametersValueMap.put('ParameterValue', cepv.celsrm__Text_Value__c);
                    ParametersValueMap.put('Score', cepv.celsrm__Score__c);
                }
                ParametersValueMap.put('cepId', cepv.celsrm__Score_Card_Parameter__c);
                ParametersValueMap.put('ParameterType', ParameterType);
                pvScoreList.add(ParametersValueMap);
            }*/
            
            Map<Object, Object> refreshParentValues = new Map<Object, Object>();
            refreshParentValues.put('ParametersValueScore', pvScoreList);
            inMap.put('refreshParentValues', refreshParentValues);
        } catch (Exception ex) {
            String errorMessage = 'ClassName: CreditManagementClass | Method: SaveParameterValue() | Linenumber: ' + ex.getLineNumber() + ' | Message: ' + ex.getMessage();
            System.debug('errorMessage: ' + errorMessage);
        }
        return inMap;
    }
    
    public static Map<Object, Object> DeleteParameter(Map<Object, Object> inMap) {
        try {
            System.debug('into DeleteParameter');
            System.debug('inMap>>>' + inMap);
            Integer Index = Integer.valueOf(inMap.get('gogGridIndex'));
            System.debug('Index>>>' + Index);
            
            List<Object> paramList = (List<Object>)inMap.get('Parameters');
            Map<Object,Object> paramObj = (Map<Object,Object>)paramList.get(Index);
            celsrm__Score_Card_Parameter__c scp = new celsrm__Score_Card_Parameter__c();
            scp.Id = String.valueOf(paramObj.get('ceParamId'));
            delete scp;
            paramList.remove(Index);
            
            Map<Object, Object> refreshParentValues = new Map<Object, Object>();
            refreshParentValues.put('Parameters', paramList);
            inMap.put('refreshParentValues', refreshParentValues);
        } catch (Exception ex) {
            String errorMessage = 'ClassName: CreditManagementClass | Method: DeleteParameter() | Linenumber: ' + ex.getLineNumber() + ' | Message: ' + ex.getMessage();
            System.debug('errorMessage: ' + errorMessage);
        }
        return inMap;
    }
    
    public static Map<Object, Object> DeleteParameterValue(Map<Object, Object> inMap) {
        try {
            System.debug('into DeleteParameterValue');
            System.debug('inMap>>>' + inMap);
            Integer Index = Integer.valueOf(inMap.get('gogGridIndex'));
            System.debug('Index>>>' + Index);
            
            List<Object> pvScoreList = (List<Object>)inMap.get('ParametersValueScore');
            Map<Object,Object> pvScoreObj = (Map<Object,Object>)pvScoreList.get(Index);
            celsrm__Score_Card_Parameter_Value__c cepv = new celsrm__Score_Card_Parameter_Value__c();
            cepv.Id = String.valueOf(pvScoreObj.get('cepValueId'));
            delete cepv;
            pvScoreList.remove(Index);
            System.debug('pvScoreList>>>' + pvScoreList);
            
            Map<Object, Object> refreshParentValues = new Map<Object, Object>();
            refreshParentValues.put('ParametersValueScore', pvScoreList);
            inMap.put('refreshParentValues', refreshParentValues);
        } catch (Exception ex) {
            String errorMessage = 'ClassName: CreditManagementClass | Method: DeleteParameterValue() | Linenumber: ' + ex.getLineNumber() + ' | Message: ' + ex.getMessage();
            System.debug('errorMessage: ' + errorMessage);
        }
        return inMap;
    }
}