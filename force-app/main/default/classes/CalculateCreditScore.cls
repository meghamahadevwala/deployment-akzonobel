public with sharing class CalculateCreditScore {
    public List<celsrm__Score_Card_Parameter__c> scParams;
    public static celsrm__Credit_Score__c getCreditScore(String accountId, String creditReviewId, String modelType, Map<String, Object> dnbData) {
        String query = '';
        Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        String ObjName = '';

        celsrm__Credit_Review__c cr = new celsrm__Credit_Review__c();
        if(creditReviewId != null && creditReviewId != '') {
            // ObjName = 'celsrm__Credit_Review__c';
            query = 'SELECT Id, celsrm__Account__r.Id, celsrm__Account__r.AccountNumber, celsrm__Account__r.Name, celsrm__D_U_N_S_Number__c, Country_Code__c, celsrm__Model_Type__c FROM celsrm__Credit_Review__c WHERE Id = \'' +  String.escapeSingleQuotes(creditReviewId)+'\'';
            List<celsrm__Credit_Review__c> crList;
            if (celsrm.GOGSecurityController.isAccessible('celsrm__Credit_Review__c','Id, celsrm__D_U_N_S_Number__c, Country_Code__c, celsrm__Model_Type__c')){
                crList = Database.query(query);
            }
            if(crList != null && crList.size() > 0) {
                cr = crList.get(0);                  
            }
        }

        Account account = new Account();
        if(accountId != null && accountId != '') {
            ObjName = 'Account';
            query = 'SELECT Id, Name, AccountNumber, Duns_Number__c, celsrm__Country_Code__c FROM Account WHERE Id = \'' +  String.escapeSingleQuotes(accountId)+'\'';
            List<Account> accList;
            if (celsrm.GOGSecurityController.isAccessible('Account','Id, AccountNumber, Duns_Number__c, celsrm__Country_Code__c')){
                accList = Database.query(query);
            }
            if(accList != null && accList.size() > 0) {
                account = accList.get(0);                       
            }
        }

        creditParamsHttpCalloutManager calloutManager = new creditParamsHttpCalloutManager();
        creditParamsHttpCalloutManager.DnbParams dnbParams =  new creditParamsHttpCalloutManager.DnbParams();
        if(dnbData == null) {
            // dnbParams = calloutManager.getCreditData(account.AccountNumber, account.Name, account.Duns_Number__c, account.celsrm__Country_Code__c);
            // if(creditReviewId != null && creditReviewId != '') {
            //     dnbParams.accountNumber = cr.celsrm__Account__r.AccountNumber;
            //     dnbParams.businessName = cr.celsrm__Account__r.AccountNumber;
            //     dnbParams.dunsNumber = cr.celsrm__D_U_N_S_Number__c;
            // } else if(accountId != null && accountId != '') {
            //     dnbParams.accountNumber = account.AccountNumber;
            //     dnbParams.businessName = account.Name;
            //     dnbParams.dunsNumber = account.Duns_Number__c;
            // }
            dnbParams.dnbRating = 'FF1';
            dnbParams.dnbFailure = '34';
            dnbParams.dnbDelinquency = '34';
            dnbParams.paydex = '34';
            dnbParams.dnbScore = '34';
            dnbParams.yearsInBusiness = '3';
        } else {
            dnbParams.dnbRating = dnbData.get('dnbRating') != null ? String.valueOf(dnbData.get('dnbRating')) : '';
            dnbParams.dnbFailure = dnbData.get('dnbFailure') != null ? String.valueOf(dnbData.get('dnbFailure')) : '';
            dnbParams.dnbDelinquency = dnbData.get('dnbDelinquency') != null ? String.valueOf(dnbData.get('dnbDelinquency')) : '';
            dnbParams.paydex = dnbData.get('paydex') != null ? (String) String.valueOf(dnbData.get('paydex')) : '';
        }
        celsrm__Credit_Score__c creditScore = new celsrm__Credit_Score__c();
        if(creditReviewId != null && creditReviewId != '') {
            creditScore.celsrm__Account__c = cr.celsrm__Account__r.Id;
            creditScore.celsrm__Credit_Review__c = cr.Id;
        } else if(accountId != null && accountId != ''){
            creditScore.celsrm__Account__c = accountId;
        }
        creditScore = CalculateCreditScore.generateCreditScore( dnbParams, modelType, creditScore);
        return creditScore;
    }

    public CalculateCreditScore(String matrixType) {
        // get all the Score Card Parameters frm the system with same matrix type.   
        if (celsrm.GOGSecurityController.isAccessible('celsrm__Score_Card_Parameter__c','Id,Name,celsrm__Weight__c,celsrm__Parameter_Type__c,celsrm__Exclude_If_Missing__c,celsrm__Score_If_Missing__c ,celsrm__Model_Type__c,celsrm__Credit_Review_Field__c') && (celsrm.GOGSecurityController.isAccessible('celsrm__celsrm__Score_Card_Parameter_Value__c','celsrm__Boolean_Value__c,celsrm__Text_Value__c,celsrm__Minimum_Number_Value__c,celsrm__Maximum_Number_Value__c,celsrm__Score_Card_Parameter__c,celsrm__Score__c'))){
            scParams = [Select Id, Name, celsrm__Weight__c, celsrm__Parameter_Type__c, celsrm__Exclude_If_Missing__c, celsrm__Score_If_Missing__c , celsrm__Model_Type__c, celsrm__Credit_Review_Field__c, 
                        (Select celsrm__Boolean_Value__c, celsrm__Text_Value__c , celsrm__Minimum_Number_Value__c, celsrm__Maximum_Number_Value__c, celsrm__Score_Card_Parameter__c, celsrm__Score__c From celsrm__Score_Card_Parameter_Value__r) 
                        From celsrm__Score_Card_Parameter__c where celsrm__Model_Type__c = :matrixType];
        }
    }

    public static celsrm__Credit_Score__c generateCreditScore(creditParamsHttpCalloutManager.DnbParams dnbParams, String modelType, celsrm__Credit_Score__c creditScore) {
        Decimal score = 0;
        if(modelType == null || modelType == ''){
            modelType = 'Recalculation';
        }
        CalculateCreditScore creditScoreClassObj = new CalculateCreditScore(modelType);
        Map<String,String> paramValueMap = new Map<String,String>();
        Map<String,String> paramValueFieldMap = new Map<String,String>();
        Map<String, Object> dnbData = new Map<String, Object>();
        dnbData.put('celsrm__D_B_Rating__c', dnbParams.dnbRating == '' || dnbParams.dnbRating == null || dnbParams.dnbRating == '--' ? null : dnbParams.dnbRating);
        dnbData.put('celsrm__D_B_Failure__c', dnbParams.dnbFailure == '' || dnbParams.dnbFailure == null || dnbParams.dnbFailure == '--' ? null : Decimal.valueOf(dnbParams.dnbFailure));
        dnbData.put('celsrm__D_B_Paydex__c', dnbParams.paydex == '' || dnbParams.paydex == null  || dnbParams.paydex == '--' ? null : Decimal.valueOf(dnbParams.paydex));
        dnbData.put('celsrm__D_B_Delinquency__c', dnbParams.dnbDelinquency == '' || dnbParams.dnbDelinquency == null || dnbParams.dnbDelinquency == '--' ? null : Decimal.valueOf(dnbParams.dnbDelinquency));
        
        for(celsrm__Score_Card_Parameter__c scp : creditScoreClassObj.scParams) {
            if(scp.celsrm__Credit_Review_Field__c != null && dnbData.containsKey(scp.celsrm__Credit_Review_Field__c)) {
                paramValueMap.put(scp.Name, String.valueOf(dnbData.get(scp.celsrm__Credit_Review_Field__c)));
                paramValueFieldMap.put(scp.Name, getValueFieldName(scp.celsrm__Credit_Review_Field__c));
            }
        }
        creditScore.put('celsrm__D_B_Rating__c', dnbData.get('celsrm__D_B_Rating__c'));
        creditScore.put('celsrm__D_B_Failure__c',dnbData.get('celsrm__D_B_Failure__c'));
        creditScore.put('celsrm__D_B_Paydex__c', dnbData.get('celsrm__D_B_Paydex__c'));
        creditScore.put('celsrm__D_B_Delinquency__c', dnbData.get('celsrm__D_B_Delinquency__c'));
        score = creditScoreClassObj.calculateTotalScore(paramValueMap, paramValueFieldMap, creditScore);
        creditScore.put('celsrm__Model_Type__c', modelType);
        creditScore.put('celsrm__Risk_Score__c', score);
        return creditScore;
    }
        
    // public function to calculate the total score for a credit application
    // this is what a credit enging does.
    //Map[Score Card Param name: credit review field value]

    public Double calculateTotalScore(Map<String,String> paramNameValueMap,Map<String,String> paramNameValueFieldMap, celsrm__Credit_Score__c creditScore) {
        Double totalCalculatedScore = 0;
        Double totalWeight = 0;
        // iterate over all the input parameters from the credit-apllication map<ParamName, ParamValue>
        //paramNameValueMap[Score Card Param name: credit review field value]
        for(String mapParam : paramNameValueMap.keySet()) {            
            for(celsrm__Score_Card_Parameter__c scp : scParams) {
                //if given mapParam matches the Score Card Parameter scp                
                if( scp.Name == mapParam ) {
                    // The corresponding CreditEngingPrameter found then get the list of all parameters values
                    List<celsrm__Score_Card_Parameter_Value__c> scParamValues = scp.celsrm__Score_Card_Parameter_Value__r;
                    String inputParamValue = paramNameValueMap.get(mapParam);
                    String valuefieldName = paramNameValueFieldMap.get( mapParam );                    
                    if ( inputParamValue == null ) {
                        System.debug('Missing Parameter Found ' + mapParam );
                        if ( !scp.celsrm__Exclude_If_Missing__c ) {
                            System.debug(' Calculating missing score ');
                            Double msv = 0;
                            if (scp.celsrm__Score_If_Missing__c != null  ){
                                msv = Double.valueOf(scp.celsrm__Score_If_Missing__c);
                            }
                            totalCalculatedScore = totalCalculatedScore + (msv  * scp.celsrm__Weight__c) ;

                            if(scp.celsrm__Weight__c != null){
                                totalWeight = totalWeight  + scp.celsrm__Weight__c;
                                System.debug('---------->> Total Weight [missing score] :: '+ totalWeight);
                            }
                            creditScore.put(valuefieldName, msv);
                        }
                        continue;
                    }  
                    // and calculate score for the value by matching it with scoring conditions
                    for(celsrm__Score_Card_Parameter_Value__c scParamValue : scParamValues) {
                        //get the credit review field value for which score has to be calculated 
                        system.debug('----------scParamValue---------->0'+scParamValue);
                        system.debug('----------scp.Parameter_Type__c---------->0'+scp.celsrm__Parameter_Type__c);
                        system.debug('----------inputParamValue ---------->0'+inputParamValue );
                        system.debug('----------inputParamValue >= scParamValue.Text_Value__c---------->0'+ inputParamValue  + '--Final --' + scParamValue.celsrm__Text_Value__c);

                        system.debug('----------inputParamValue <= scParamValue.Text_Value__c---------->0'+scParamValue.celsrm__Text_Value__c);
                        // if credit review field has some data in it then check the Score Card Parameter data type 
                        // pick score of that param value for which credit review field value lies within the range  
                        if(inputParamValue != null && inputParamValue != '') {
                            if( scp.celsrm__Parameter_Type__c == 'Text' && inputParamValue == scParamValue.celsrm__Text_Value__c ) {
                                
                                //totalCalculatedScore = totalCalculatedScore + (scParamValue.Score__c * scp.Weight__c/100);
                                totalCalculatedScore = totalCalculatedScore + (scParamValue.celsrm__Score__c * scp.celsrm__Weight__c);
                                
                                if(scp.celsrm__Weight__c != null){
                                    totalWeight = totalWeight  + scp.celsrm__Weight__c;
                                    System.debug('---------->> Total Weight [text] :: '+ totalWeight);
                                }
                                system.debug('-----inputParamValue ----'+inputParamValue);
                                system.debug('------valuefieldName----'+valuefieldName );
                                system.debug('----scParamValue1.Score__c----'+scParamValue.celsrm__Score__c);
                                
                                system.debug('-----------Value1-----------'+ scParamValue.celsrm__Text_Value__c);
                                system.debug('-----------Value2-----------'+ scParamValue.celsrm__Text_Value__c);                                 
                                creditScore.put( valuefieldName , scParamValue.celsrm__Score__c  );
                                
                                break;
                            }
                            else if(scp.celsrm__Parameter_Type__c == 'Number' && double.valueOf(inputParamValue)>= scParamValue.celsrm__Minimum_Number_Value__c && double.valueOf(inputParamValue) < scParamValue.celsrm__Maximum_Number_Value__c) {
                                //totalCalculatedScore = totalCalculatedScore + (scParamValue.Score__c * scp.Weight__c/100);
                                totalCalculatedScore = totalCalculatedScore + (scParamValue.celsrm__Score__c * scp.celsrm__Weight__c);
                                
                                if(scp.celsrm__Weight__c != null){
                                    totalWeight = totalWeight  + scp.celsrm__Weight__c;
                                    System.debug('---------->> Total Weight [number] :: '+ totalWeight);
                                }
                                
                                system.debug('--------scParamValue.Minimum_Number_Value__c---'+ scParamValue.celsrm__Minimum_Number_Value__c);
                                system.debug('--------scParamValue.Maximum_Number_Value__c---'+ scParamValue.celsrm__Maximum_Number_Value__c);  
                                system.debug('--------scParamValue.Val_Number3__c---'+ inputParamValue);                              
                                system.debug('------valuefieldName----'+ valuefieldName );
                                system.debug('----scParamValue2.Score__c----'+scParamValue.celsrm__Score__c);
                                system.debug('----totalCalculatedScore123 ----'+totalCalculatedScore);
                                
                                creditScore.put( valuefieldName , scParamValue.celsrm__Score__c  );
                                break;
                            }
                            else if(scp.celsrm__Parameter_Type__c == 'Currency' && double.valueOf(inputParamValue)>= scParamValue.celsrm__Minimum_Number_Value__c && double.valueOf(inputParamValue) < scParamValue.celsrm__Maximum_Number_Value__c) {
                                //  totalCalculatedScore = totalCalculatedScore + (scParamValue.Score__c * scp.Weight__c/100);
                                totalCalculatedScore = totalCalculatedScore + (scParamValue.celsrm__Score__c * scp.celsrm__Weight__c);
                                if(scp.celsrm__Weight__c != null){
                                    totalWeight = totalWeight  + scp.celsrm__Weight__c;
                                    System.debug('---------->> Total Weight [currency] :: '+ totalWeight);
                                }
                                system.debug('------valuefieldName----'+valuefieldName );
                                system.debug('----scParamValue3.Score__c----'+scParamValue.celsrm__Score__c);
                                creditScore.put( valuefieldName , scParamValue.celsrm__Score__c );
                                break;
                            }
                            else if(scp.celsrm__Parameter_Type__c == 'Boolean' && Boolean.valueOf(inputParamValue)== scParamValue.celsrm__Boolean_Value__c) {
                                //totalCalculatedScore = totalCalculatedScore + (scParamValue.Score__c * scp.Weight__c/100);
                                totalCalculatedScore = totalCalculatedScore + (scParamValue.celsrm__Score__c * scp.celsrm__Weight__c);
                                
                                if(scp.celsrm__Weight__c != null){
                                    totalWeight = totalWeight  + scp.celsrm__Weight__c;
                                    System.debug('---------->> Total Weight [Boolean] :: '+ totalWeight);
                                }
                                system.debug('------valuefieldName----'+valuefieldName );
                                system.debug('----scParamValue4.Score__c----'+scParamValue.celsrm__Score__c);
                                creditScore.put( valuefieldName , scParamValue.celsrm__Score__c);
                                break;
                            }
                        }       
                    }
                }
            }
        }

        System.debug('---------->> totalCalculatedScore :: '+ totalCalculatedScore + ' total weight :: '+totalWeight );
        if(totalWeight > 0){
            totalCalculatedScore = totalCalculatedScore / totalWeight ;
            System.debug('-------------->>> Final totla Score :: '+ totalCalculatedScore);
        }
        
        return totalCalculatedScore;
    }
        
    public static String getValueFieldName(String fieldName) {
        String v = '_Score';
        Integer i = fieldName.indexOf('__c');
        String s = fieldName.subString( 0, i );
        v = s + v + '__c';
        return v;
    }

}