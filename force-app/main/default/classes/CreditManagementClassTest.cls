@isTest
public with sharing class CreditManagementClassTest {
    
    static Map<Object,Object> inMap = new Map<Object,Object>();

    public static testmethod void CreditManagementClassTest() {

        celsrm__Score_Card_Parameter__c SCP = DataGenerator.insertScoreCardParams();
        celsrm__Score_Card_Parameter_Value__c SCPV = DataGenerator.ScoreCardParamVal(SCP);
        celsrm__Score_Card_Parameter_Value__c SCPV1 = DataGenerator.ScoreCardParamVal(SCP);

        List<Object> ObjList = new List<Object>();
        Map<Object,Object> objMap1 = new Map<Object,Object>();
        Map<Object, Object> ParametersValueMap = new Map<Object, Object>();
        List<Object> ParametersValueList = new List<Object>();
        objMap1.put('ceParamId',SCP.Id);
        objMap1.put('cepValueId', SCPV.Id);
        objMap1.put('ParameterType','Boolean');
        objList.add(objMap1);
		ParametersValueMap.put('BooleanValue', SCPV.celsrm__Boolean_Value__c);
        ParametersValueMap.put('Score', SCPV.celsrm__Score__c);
        ParametersValueMap.put('cepValueId', SCPV.celsrm__Score__c);
        ParametersValueList.add(ParametersValueMap);
        ParametersValueMap.put('ParameterValue', SCPV1.celsrm__Text_Value__c);
        ParametersValueMap.put('Score', SCPV1.celsrm__Score__c);
        ParametersValueMap.put('cepValueId', SCPV1.celsrm__Score__c);
        ParametersValueList.add(ParametersValueMap);
        inMap.put('ParametersValueScore', ParametersValueList);
        inMap.put('ScoreCardType', 'Full Review');
        inMap.put('MissingScoreValue', false);
        inMap.put('gogGridIndex', 0);
        inMap.put('ExcludeIfMissing', true);
        inMap.put('isSelected', true);
        inMap.put('ParametersValueScore',ParametersValueList);
        
        CreditManagementClass CreditMng = new CreditManagementClass();
        CreditMng.invoke('GetCreditReviewField', inMap);
        CreditMng.invoke('GetCreditScoreField', inMap);
        CreditMng.invoke('GetParameters', inMap);
        inMap = CreditMng.invoke('GetParametersValueScore', inMap);
        inMap = CreditMng.invoke('SaveParameter', inMap);
        inMap = CreditMng.invoke('SaveParameterValue', inMap);

        inMap.put('Parameters', ObjList);
        inMap.put('cepValueId', SCPV.Id);
        inMap.put('ceParamId', SCP.Id);
        inMap = CreditMng.invoke('GetParametersValueScore', inMap);
        inMap = CreditMng.invoke('SaveParameter', inMap);
        inMap = CreditMng.invoke('SaveParameterValue', inMap);

        objMap1.put('ParameterType','Currency');
        objList.add(objMap1); 
        inMap.put('Parameters', ObjList);
        inMap = CreditMng.invoke('GetParametersValueScore', inMap);
        inMap = CreditMng.invoke('SaveParameter', inMap);
        inMap = CreditMng.invoke('SaveParameterValue', inMap);

        objMap1.put('ParameterType','Number');
        objList.add(objMap1); 
        inMap.put('Parameters', ObjList);
        inMap = CreditMng.invoke('GetParametersValueScore', inMap);
        inMap = CreditMng.invoke('SaveParameter', inMap);
        inMap = CreditMng.invoke('SaveParameterValue', inMap);
        
        objMap1.put('ParameterType','Text');
        objList.add(objMap1); 
        inMap.put('Parameters', ObjList);
        inMap = CreditMng.invoke('GetParametersValueScore', inMap);
        inMap = CreditMng.invoke('SaveParameter', inMap);
        inMap = CreditMng.invoke('SaveParameterValue', inMap);

        CreditMng.invoke('DeleteParameter', inMap);
        
        CreditMng.invoke('DeleteParameterValue', inMap);
    }
}