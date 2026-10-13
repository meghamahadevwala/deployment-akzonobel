global with sharing class creditParamsHttpCalloutManager {

    public class bureauCompanyDetails{
        public String city;
        public String country;
        public String state;
        public String street;
        public String zipCode;
        public String bureauIdentifierNumber;
        public String businessName;
        public String locationIndicator;
        public String matchScore;
        public String telephone;
    }
    

    public class DnbParams{
        public String accountNumber;
        public String businessName;
        public String dunsNumber;
        public String assetsTotal;
        public String assetsTotalCurrent;
        public String liabilitiesTotal;
        public String liabilitiesTotalCurrent;
        public String netWorth;
        public String saleRevenue;
        public String statementDate;
        public String workingCapital;
        public String dnbRating;
        public String dnbFailure;
        public String paydex;
        public String dnbDelinquency;
        public String currentLiabilitiesToInventoryPercent;
        public String grossProfit;
        public String longTermLiabilities;
        public String statementCurrencyCode;
        public String statementType;
        public String inventory;
        public String dnbScore;
        public String yearsInBusiness;
        public String netProfitNetLoss;
        public String vatNumber;
    }
    
    
    
    
    public List<Map<String, Object>> getMatchingAccounts(Map<Object, Object> inMap) {
        String requestBody = JSON.serialize(new Map<String, Object>{
            'MATCH' => new Map<String, Object>{
                'Criteria' => new Map<String, String>{
                    'Name' => inMap.get('Name') != null ? (String) inMap.get('Name') : '',
                    'City' => inMap.get('BillingCity') != null ? (String) inMap.get('BillingCity') : '',
                    'Country' => inMap.get('BillingCountry') != null ? (String) inMap.get('BillingCountry') : '',
                    'State' => inMap.get('BillingState') != null ? (String) inMap.get('BillingState') : '',
                    'Postcode' => inMap.get('BillingPostalCode') != null ? (String) inMap.get('BillingPostalCode') : '',
                    'Address' => inMap.get('BillingStreet') != null ? (String) inMap.get('BillingStreet') : '',
                    'NationalId' => inMap.get('NationalId') != null ? (String) inMap.get('NationalId') : ''
                },
                'Options' => new Map<String, Object>{
                    'ExclusionFlags' => new List<String>{'ExcludeBranchLocations'},
                    'ScoreLimit' => 0.5
                }
            },
            'SELECT' => new List<String>{
                'Match.Hint', 'Match.Score', 'Match.Name', 'Match.Address',
                'Match.Postcode', 'Match.City', 'Match.Country', 'Match.National_Id',
                'Match.NationalIdLabel', 'Match.LegalForm', 'Match.Status', 'Match.Isin', 'Match.BvDId'
            }
        });
        HttpResponse res;
        res = getInfoFromAPI(requestBody, '/companies/match/');
        if (res.getStatusCode() == 200){
            List<Map<String, Object>> listMatches = getMatchList(res);
            Id accId = extractAccountIdFromInput(inMap);
            autoAssignBvdIfHundred(accId, listMatches);
            return listMatches;
        }
        return null;
    }
    
       private static Id extractAccountIdFromInput(Map<Object, Object> inMap) {
        if (inMap == null) return null;
        List<String> keys = new List<String>{ 'AccountId', 'accountId', 'recordId', 'Id', 'id' };
        for (String k : keys) {
            if (inMap.containsKey(k) && inMap.get(k) != null) {
                Object v = inMap.get(k);
                if (v instanceof Id) return (Id) v;
                if (v instanceof String) {
                    try { return (Id) (String) v; } catch (Exception e) {}
                }
            }
        }
        return null;
    }
    
    private static void autoAssignBvdIfHundred(Id accountId, List<Map<String, Object>> matches) {
        if (accountId == null || matches == null || matches.isEmpty()) return;
        Account acc = [SELECT Id, BvD_ID_Number__c FROM Account WHERE Id = :accountId LIMIT 1];
        if (acc.BvD_ID_Number__c != null) return;
        for (Map<String, Object> row : matches) {
            Object sObj = row.get('score');
            if (sObj == null) continue;
            Decimal score;
            try { score = (sObj instanceof Decimal) ? (Decimal) sObj : Decimal.valueOf(String.valueOf(sObj)); } catch (Exception e) { continue; }
            if (score == 100 && row.get('bvDId') != null) {
                String bvd = (String) row.get('bvDId');
                update new Account(Id = acc.Id, BvD_ID_Number__c = bvd);
                break;
            }
        }
    }

    // public static String getMoodysAccessToken() {        
    //     // Set up the HTTP request
    //     // System.debug(EncodingUtil.base64Encode(Blob.valueOf(username:apiKey)));    

    //     HttpRequest req = new HttpRequest();
    //     req.setEndpoint('callout:MoodysAccessToken' + '/prod/auth/token');
    //     req.setMethod('POST');
        
    //     // You may need to set an empty JSON body if required
    //     req.setBody('{}');

    //     // Send the request
    //     Http http = new Http();
    //     HttpResponse res;
    //     try {
    //         res = http.send(req);
    //         // Check for a successful response
    //         if (res.getStatusCode() == 200) {
    //             Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
    //             return (String) responseMap.get('access_token');
    //         } else {
    //             System.debug('Error: ' + res.getStatusCode() + ' - ' + res.getStatus());
    //         }
    //     } catch (Exception e) {
    //         System.debug('Exception: ' + e.getMessage());
    //     }
    //     return null;
    // }

    public static String generateNewMoodysAccessToken() {
        Integer maxRetries = 3;  // Total attempts: 1 initial + 2 retries
        Integer retryCount = 0;
        HttpResponse res;
        
        while (retryCount < maxRetries) {
            HttpRequest req = new HttpRequest();
            req.setEndpoint('callout:MoodysAccessToken' + '/prod/auth/token');
            req.setMethod('POST');
            
            req.setBody('{}');
            
            Http http = new Http();
            try {
                res = http.send(req);
                
                if (res.getStatusCode() == 200) {
                    Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                    return (String) responseMap.get('access_token');
                } else if (res.getStatusCode() >= 500 && res.getStatusCode() < 600) {
                    System.debug('Received server error ' + res.getStatusCode() + '. Retrying... (Attempt ' + (retryCount + 1) + ')');
                } else {
                    System.debug('Error: ' + res.getStatusCode() + ' - ' + res.getStatus());
                    return null;
                }
            } catch (Exception e) {
                System.debug('Exception: ' + e.getMessage() + '. Retrying... (Attempt ' + (retryCount + 1) + ')');
            }
    
            // Wait before retrying
            retryCount++;
        }
    
        return null;
    }
    
    public static Moody_s_Auth__c getMoodysAccessToken() {
        Moody_s_Auth__c moodysAuth = getExistingAccessToken();
        
        if (moodysAuth != null) {
            DateTime tokenAge = moodysAuth.Token_Generation_Time__c;
            DateTime now = System.now();
            Integer tokenValidityPeriodInMinutes = 50;
            if (tokenAge.addMinutes(tokenValidityPeriodInMinutes) > now) {
                return moodysAuth;
            } else {
                String accessToken = generateNewMoodysAccessToken();
                moodysAuth.Token_Generation_Time__c = System.now();
                moodysAuth.Access_Token__c = accessToken;
                return moodysAuth;
            }
        } else {
            Moody_s_Auth__c newAuth = new Moody_s_Auth__c();
            newAuth.Token_Generation_Time__c = System.now();
            String accessToken = generateNewMoodysAccessToken();
            newAuth.Access_Token__c = accessToken;
            return newAuth;
        }
    }
    
    private static Moody_s_Auth__c getExistingAccessToken() {
        List<Moody_s_Auth__c>  existingAuthList = [SELECT Access_Token__c, Token_Generation_Time__c FROM Moody_s_Auth__c ORDER BY Token_Generation_Time__c DESC LIMIT 1];
        
        if (!existingAuthList.isEmpty()) {
            Moody_s_Auth__c existingAuth = existingAuthList[0];
            DateTime tokenAge = existingAuth.Token_Generation_Time__c;
            DateTime now = System.now();
            Integer tokenValidityPeriodInMinutes = 50;
            return existingAuth;
            // if (tokenAge.addMinutes(tokenValidityPeriodInMinutes) > now) {
            //     return existingAuth;
            // } else {
            //     deleteExistingToken(existingAuth.Id);
            // }
        }
        return null;
    }
    
    private static void deleteExistingToken(Id tokenId) {
        try {
            delete [SELECT Id FROM Moody_s_Auth__c WHERE Id = :tokenId LIMIT 1];
            System.debug('Deleted expired token with Id: ' + tokenId);
        } catch (Exception e) {
            System.debug('Error while deleting expired token: ' + e.getMessage());
        }
    }
    

    private static void saveAccessTokenToDatabase(String accessToken, DateTime generationTime) {
        Moody_s_Auth__c newAuth = new Moody_s_Auth__c();
        newAuth.Access_Token__c = accessToken;
        newAuth.Token_Generation_Time__c = generationTime;
        try {
            upsert newAuth;
        } catch (Exception e) {
            System.debug('Error while saving token to database: ' + e.getMessage());
        }
    }

    
    public HttpResponse getInfoFromAPI(String requestBody, String endPoint) {
        // String accessToken = generateNewMoodysAccessToken();
        Moody_s_Auth__c MoodysAuth = getMoodysAccessToken();
        String accessToken;
        if(MoodysAuth != null) {
            accessToken = MoodysAuth.Access_Token__c;
        }
        // String accessToken = 'eyJraWQiOiIxTjhGM1V0YzVyRmVsQ1luTjRra3dzNXNfUFFhNHQtU21JZXY0UVlTUzhjIiwiYWxnIjoiUlMyNTYifQ.eyJ2ZXIiOjEsImp0aSI6IkFULnk5dDB4VDRGMnhsZmZnc2hBd1B6T2xyNHlPYVFQQU1XSHg1NUtXa0JXbjQub2FyMm5mOGlnOFBTaDkweTM0eDciLCJpc3MiOiJodHRwczovL2xvZ2luLm1vb2R5c2FuYWx5dGljcy5jb20vb2F1dGgyL2RlZmF1bHQiLCJhdWQiOiJhcGk6Ly9kZWZhdWx0IiwiaWF0IjoxNzM0NzAxODkxLCJleHAiOjE3MzQ3MDU0OTEsImNpZCI6IjBvYTF6dnNnMWpqb05IUzJONHg3IiwidWlkIjoiMDB1bnBheTMxdkVrcjBmSGg0eDciLCJzY3AiOlsib2ZmbGluZV9hY2Nlc3MiLCJncm91cHMiLCJhcGlodWJfdXNlciJdLCJhdXRoX3RpbWUiOjE3MzQ3MDE4OTEsInRlbmFudF9pZCI6IiIsInN1YiI6ImNvcmVhcGlkZXZvcHMtYWt6b25vYmVsQG1vb2R5cy5hcGkiLCJhcGlodWJfdXNlciI6ImNvcmVhcGlkZXZvcHNAYWt6b25vYmVsLmNvbSIsInNnX3RlbmFudF9pZCI6IiIsIm9yZ2FuaXphdGlvbiI6IiIsIm5hbWUiOiJDb3JlQVBJIERldk9wcyIsImdyb3VwcyI6WyJFdmVyeW9uZSIsImFwaS1odWItdXNlcnMtc2VydmljZS1hY2NvdW50cyIsImZyb21TcG9rZS1wcmQtbW9vZHlzYW5hbHl0aWNzIiwiQVBJUG9ydGFsIl0sIlpvbmVJbmZvIjoiIiwiZW1haWwiOiJjb3JlYXBpZGV2b3BzLWFrem9ub2JlbEBtb29keXMuYXBpIn0.HmW2ocA_QDSAG_yItSK9zKjAC3-gvz-vzC2vipkd2UwnRNnaBb3B9bNlWTIGEEDEglpotr6Jo3kcq1WCQMXe-6AkjwXsq6R7BAwChrZ8_iHRWkpm6A3sd-yQ_Pv4JnY7fNxZCxk3DVo5rnii3Vk4VB-a4NnDKf3ZjQ6MFYyiZSgfdx-uDmYXBewQJwm2DVtw0NMeX8_NLv86UvvOUACXNmnhqZUMVqS-NCr1ArBaZ3EcVA6PTH0BTHkAddbfA20cPAPoWY-HdkrM3WeYM3r9x7-SuofrABIik0PI7EQ8rY5SQ8XeQodIY8QCPZE1HnbpFObPzGxGJ2lJW4DzrLPwhQ';
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        req.setHeader('Authorization', 'Bearer ' + accessToken);
        req.setEndpoint('callout:Moodys_Integration' + endPoint);
        req.setMethod('POST');
        req.setBody(requestBody);
        req.setTimeout(120000);
        System.debug('Request>>>' + req);
        HttpResponse res = h.send(req);
        System.debug('res>>>>>'+ res);
        upsert MoodysAuth;
        return res;
    }

    

    

    public Map<Object, Object> getBvDInfo(String bvdId, String currencyIsoCode) {
        Map<String, Object> requestBody = new Map<String, Object>();
        if(currencyIsoCode == null || currencyIsoCode == '') {
            currencyIsoCode = 'EUR';
        }
        // WHERE clause with dynamic BvDID
        Map<String, List<String>> whereClause = new Map<String, List<String>>();
        whereClause.put('BvDID', new List<String>{bvdId});
        
        // Construct SELECT section of the body
        List<Object> selectList = new List<Object>{
            new Map<String, Object>{
                'NAME' => new Map<String, String>{ 
                    'AS' => 'NAME' 
                }
            },
            new Map<String, Object>{
                'BVD_ID_NUMBER' => new Map<String, String>{
                    'AS' => 'BVD_ID_NUMBER' 
                }
            }
            ,
            new Map<String, Object>{
                'EMPL' => new Map<String, String>{ 
                    'AS' => 'EMPL'
                }
            },
            new Map<String, Object>{
                'MORRAT' => new Map<String, Object>{
                    'INDEXORYEAR' => '0',
                    'AS' => 'MORRAT' 
                }
            },
            new Map<String, Object>{
                'MORE_YEAR' => new Map<String, Object>{
                    'INDEXORYEAR' => '0', 
                    'AS' => 'MORE_YEAR' 
                }
            },
            new Map<String, Object>{ 
                'MORCREDLIMIT' => new Map<String, Object>{ 
                    'FILTERS' => 'Filter.Name=FinancialStrengthFilter;FinancialStrengthFilter.Mode=FSSummary', 
                    'CURRENCY' => currencyIsoCode, 
                    'UNIT' => 0, 
                    'INDEXORYEAR' => '0', 
                    'AS' => 'MORCREDLIMIT' 
                } 
            },
            new Map<String, Object>{ 
                'MORDEF' => new Map<String, Object>{ 
                    'INDEXORYEAR' => '0', 
                    'AS' => 'MORDEF' 
                } 
            },
            new Map<String, Object>{ 
                'MORCONF' => new Map<String, Object>{ 
                    'INDEXORYEAR' => '0', 
                    'AS' => 'MORCONF' 
                } 
            },
            new Map<String, Object>{ 
                'REACMORRAT' => new Map<String, Object>{ 
                    'INDEXORYEAR' => '0', 
                    'AS' => 'REACMORRAT' 
                } 
            },
            new Map<String, Object>{ 
                'REACMORE_DATE' => new Map<String, Object>{ 
                    'INDEXORYEAR' => '0', 
                    'AS' => 'REACMORE_DATE' 
                } 
            },
            new Map<String, Object>{ 
                'REACMORCREDLIMIT' => new Map<String, Object>{ 
                    'CURRENCY' => currencyIsoCode, 
                    'UNIT' => 0, 
                    'INDEXORYEAR' => '0', 
                    'AS' => 'REACMORCREDLIMIT' 
                } 
            },
            new Map<String, Object>{ 
                'REACMORDEF' => new Map<String, Object>{ 
                    'INDEXORYEAR' => '0', 
                    'AS' => 'REACMORDEF' 
                } 
            },
            new Map<String, Object>{ 
                'REACMORCONF' => new Map<String, Object>{ 
                    'INDEXORYEAR' => '0', 
                    'AS' => 'REACMORCONF' 
                } 
            },
            new Map<String, Object>{ 
                'MODEFINNF' => new Map<String, Object>{ 
                    'FILTERS' => 'Filter.Name=FinancialStrengthFilter;FinancialStrengthFilter.Mode=FSSummary', 
                    'INDEXORYEAR' => '0', 
                    'AS' => 'MODEFINNF' 
                } 
            },
            new Map<String, Object>{ 
                'MODEFINNFDATE' => new Map<String, Object>{ 
                    'INDEXORYEAR' => '0', 
                    'AS' => 'MODEFINNFDATE' 
                } 
            },
            new Map<String, Object>{ 
                'MODEFINNF_CreditLimitValue' => new Map<String, Object>{ 
                    'FILTERS' => 'Filter.Name=FinancialStrengthFilter;FinancialStrengthFilter.Mode=FSSummary', 
                    'CURRENCY' => currencyIsoCode, 
                    'UNIT' => 0, 
                    'INDEXORYEAR' => '0', 
                    'AS' => 'MODEFINNF_CreditLimitValue' 
                } 
            },
            new Map<String, Object>{ 
                'MODEFINNFCONF' => new Map<String, Object>{ 
                    'INDEXORYEAR' => '0', 
                    'AS' => 'MODEFINNFCONF' 
                } 
            },
            new Map<String, Object>{ 
                'CURR' => new Map<String, Object>{ 
                    'UNIT' => 0, 
                    'INDEXORYEAR' => '0', 
                    'AS' => 'CURR' 
                } 
            },
            new Map<String, Object>{ 
                'LIQR' => new Map<String, Object>{ 
                    'MODELID' => 'IND', 
                    'UNIT' => 0, 
                    'INDEXORYEAR' => '0', 
                    'AS' => 'LIQR' 
                } 
            },
            new Map<String, Object>{ 
                'STATUS' => new Map<String, Object>{ 
                    'LIMIT' => 1, 
                    'AS' => 'STATUS' 
                } 
            },
            new Map<String, Object>{ 
                'STATUS_DATE' => new Map<String, Object>{ 
                    'LIMIT' => 1, 
                    'AS' => 'STATUS_DATE' 
                } 
            },
            new Map<String, Object>{ 
                'INCORPORATION_DATE' => new Map<String, Object>{ 
                    'AS' => 'INCORPORATION_DATE' 
                } 
            },
            // new Map<String, Object>{ 
            //     'SHFD' => new Map<String, Object>{ 
            //         'CURRENCY' => currencyIsoCode,
            //         'UNIT' => 0,
            //         'INDEXORYEAR' => '0',
            //         'AS' => 'SHFD' 
            //     } 
            // } 
            new Map<String, Object>{ 
                'CAPI' => new Map<String, Object>{ 
                    'CURRENCY' => currencyIsoCode,
                    'MODELID' => 'IND', 
                    'UNIT' => 0, 
                    'INDEXORYEAR' => '0', 
                    'AS' => 'CAPI' 
                } 
            }
        };
        
        // Add WHERE and SELECT sections to the request body
        requestBody.put('WHERE', new List<Map<String, List<String>>>{ whereClause });
        requestBody.put('select', selectList);
        
        // Add RANGE and ORDERBY
        requestBody.put('RANGE', new Map<String, Integer>{ 'MAX' => 100, 'OFFSET' => 0 });
        requestBody.put('ORDERBY', new Map<String, String>{ 'DESC' => 'OPRE' });

        // Convert the request body to JSON
        String jsonBody = JSON.serialize(requestBody);

        HttpResponse res;
        // if(!Test.isRunningTest()){
            res = getInfoFromAPI(jsonBody, '/companies/data');
            system.debug('Response (DUN# Avail)>>>'+res);
            system.debug('Response Body (DUN# Avail)>>>'+res.getBody());
            if (res.getStatusCode() == 200) {
                return getBvdDetails(res);
            }
        // }
        return null;

    }

    public Map<Object, Object> getBvdDetails(HttpResponse response){
        String responseBody = response.getBody();
        Map<String, Object> parsedResponseList = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
        List<Object> dataList = (List<Object>) parsedResponseList.get('Data');
        Map<Object, Object> inMap = new Map<Object, Object>();
        if(dataList.size() > 0) {
            Map<String, Object> bvdMap = (Map<String, Object>) dataList[0];

            
            // inMap.put('NAME', bvdMap.get('NAME') != null ? (String) bvdMap.get('NAME'): null);
            // inMap.put('BVD_ID_NUMBER', bvdMap.get('BVD_ID_NUMBER') != null ? (String) bvdMap.get('BVD_ID_NUMBER'): null);
            // inMap.put('EMPL', bvdMap.get('EMPL') != null ? (String) bvdMap.get('EMPL'): null);
            inMap.put('moreEvaluationScore', bvdMap.get('MORRAT') != null ? (String) bvdMap.get('MORRAT'): null);
            inMap.put('moreEvaluationYear', bvdMap.get('MORE_YEAR') != null ? DateTime.valueOf(((String) bvdMap.get('MORE_YEAR')).replaceAll('T', ' ')).date(): null);
            inMap.put('moreEvaluationCurrent', bvdMap.get('MORCREDLIMIT') != null ? (Decimal) bvdMap.get('MORCREDLIMIT'): null); //MORE credit limit - current
            inMap.put('moreEvaluationProbOfDefault', bvdMap.get('MORDEF') != null ? (Decimal) bvdMap.get('MORDEF'): null);   //MORE evaluation - Probability of default
            inMap.put('moreEvaluationConfifenceLevel', bvdMap.get('MORCONF') != null ? (Decimal) bvdMap.get('MORCONF'): null);   //MORE evaluation - Confidence level
            inMap.put('reactiveMoreEvaluationReactiveScore', bvdMap.get('REACMORRAT') != null ? (String) bvdMap.get('REACMORRAT'): null);   //Reactive MORE evaluation - Reactive score
            inMap.put('reactiveMoreEvaluationReactiveDate', bvdMap.get('REACMORE_DATE') != null ? DateTime.valueOf(((String) bvdMap.get('REACMORE_DATE')).replaceAll('T', ' ')).date(): null);  //Reactive MORE evaluation - Reactive date
            inMap.put('reactiveMoreCreditLimitCurrent', bvdMap.get('REACMORCREDLIMIT') != null ? (Decimal) bvdMap.get('REACMORCREDLIMIT'): null);    //Reactive MORE credit limit - current
            inMap.put('reactiveMoreEvaluationProbOfDefault', bvdMap.get('REACMORDEF') != null ? (Decimal) bvdMap.get('REACMORDEF'): null);   //Reactive MORE evaluation - Reactive probability of default
            inMap.put('reactiveMoreEvaluationConfidenceLevel', bvdMap.get('REACMORCONF') != null ? (Decimal) bvdMap.get('REACMORCONF'): null);   //Reactive MORE evaluation - Reactive confidence level
            inMap.put('qualitativeScoreCurrent', bvdMap.get('MODEFINNF') != null ? (String) bvdMap.get('MODEFINNF'): null); //Qualitative score – current
            inMap.put('qualitativeScoreDate', bvdMap.get('MODEFINNFDATE') != null ? DateTime.valueOf(((String) bvdMap.get('MODEFINNFDATE')).replaceAll('T', ' ')).date(): null);    //Qualitative score - Date
            inMap.put('qualitativereditLimitCurrent', bvdMap.get('MODEFINNF_CreditLimitValue') != null ? (Decimal) bvdMap.get('MODEFINNF_CreditLimitValue'): null);  //Qualitative credit limit – current
            inMap.put('qualitativeScoreConfidenceLevel', bvdMap.get('MODEFINNFCONF') != null ? (Decimal) bvdMap.get('MODEFINNFCONF'): null); //Qualitative score - Confidence level (%)
            inMap.put('currentRatio', bvdMap.get('CURR') != null ? (Decimal) bvdMap.get('CURR'): null);   //Current ratio
            inMap.put('liquidityRatio', bvdMap.get('LIQR') != null ? (Decimal) bvdMap.get('LIQR'): null); //Liquidity ratio
            inMap.put('status', bvdMap.get('STATUS') != null && ((List<Object>)bvdMap.get('STATUS')).size() > 0 ? (String) (((List<Object>)bvdMap.get('STATUS'))[0]): null); //Status
            inMap.put('statusDate', bvdMap.get('STATUS_DATE') != null && ((List<Object>)bvdMap.get('STATUS_DATE')).size() > 0 ? DateTime.valueOf(((String) (((List<Object>)bvdMap.get('STATUS_DATE'))[0])).replaceAll('T', ' ')).date(): null); //Status
            inMap.put('incorporationDate', bvdMap.get('INCORPORATION_DATE') != null ? DateTime.valueOf(((String) bvdMap.get('INCORPORATION_DATE')).replaceAll('T', ' ')).date(): null);
            // inMap.put('registeredCapital', bvdMap.get('SHFD') != null ? (Decimal) bvdMap.get('SHFD'): null);  //registeredCapital
            inMap.put('registeredCapital', bvdMap.get('CAPI') != null ? (Decimal) bvdMap.get('CAPI'): null);  //registeredCapital
        }
        return inMap;
    }
    // public DnbParams getCreditData(String accountNumber, String accountName, String dunsNumber, String billingCountry) {
    //     DnbParams dnbParams = new DnbParams();
    //     dunsNumber = dunsNumber.replace('-','');
    //     System.debug('Inside getCreditData');
    //     String requestBody = '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:com="http://com.dnbi.eai.service.CreditApplication" xmlns:cred="http://creditapp.message.eai.dnbi.com" xmlns:dto="http://dto.eai.dnbi.com">';
    //     requestBody +=          '<soapenv:Header>';
    //     requestBody +=              '<dto:AuthenticationDTO>';
    //     requestBody +=                   '<dto:LOGIN_ID>' + '{!$Credential.UserName}' + '</dto:LOGIN_ID>';
    //     requestBody +=                   '<dto:LOGIN_PASSWORD>' + '{!$Credential.Password}' + '</dto:LOGIN_PASSWORD>';
    //     requestBody +=              '</dto:AuthenticationDTO>';
    //     requestBody +=          '</soapenv:Header>';
    //     requestBody +=          '<soapenv:Body>';
    //     requestBody +=              '<com:applyForCreditEnhanced>';
    //     requestBody +=                  '<com:in0>';
    //     requestBody +=                      '<cred:HQDunsNeeded>true</cred:HQDunsNeeded>';
    //     requestBody +=                      '<cred:allFieldList>';                           
    //     requestBody +=                      '<dto:FieldDTO>';
    //     requestBody +=                          '<dto:fieldType>GENERAL</dto:fieldType>';
    //     requestBody +=                          '<dto:index>1</dto:index>';
    //     requestBody +=                          '<dto:label>Country</dto:label>';
    //     requestBody +=                          '<dto:name>BizInfo-Country</dto:name>';
    //     requestBody +=                          '<dto:value>' + billingCountry + '</dto:value>';
    //     requestBody +=                      '</dto:FieldDTO>';
    //     requestBody +=                      '<dto:FieldDTO>';
    //     requestBody +=                          '<dto:fieldType>GENERAL</dto:fieldType>';
    //     requestBody +=                          '<dto:index>0</dto:index>';
    //     requestBody +=                          '<dto:label>Duns Number</dto:label>';
    //     requestBody +=                          '<dto:name>BizInfo-DUNSNumber</dto:name>';
    //     requestBody +=                          '<dto:value>' + dunsNumber + '</dto:value>';
    //     requestBody +=                      '</dto:FieldDTO>';
    //     requestBody +=                      '</cred:allFieldList>';
    //     requestBody +=                      '<cred:exactCompanyMatchRequiredFlag>true</cred:exactCompanyMatchRequiredFlag>';
    //     requestBody +=                  '</com:in0>';
    //     requestBody +=               '</com:applyForCreditEnhanced>';
    //     requestBody +=          '</soapenv:Body>';
    //     requestBody +=          '</soapenv:Envelope>';
    //     HttpResponse res;
    //     if(!Test.isRunningTest()){
    //         res = getInfoFromAPI(requestBody);
    //         system.debug('Response (DUN# Avail)>>>'+res);
    //      system.debug('Response Body (DUN# Avail)>>>'+res.getBody());
    //         if (res.getStatusCode() == 200) {
    //             return getDnbParams(res, accountNumber, accountName);
    //         }
    //     }
    //     return null;
    // }
    // public DnbParams getDnbParams(HttpResponse res, String accountNumber, String accountName){
    //     DnbParams dnbParams = new DnbParams();
    //     dom.Document resDoc = res.getBodyDocument();
    //     System.debug('Body Doc:' + resDoc);
    //     Dom.XMLNode rootEle = resDoc.getRootElement();
    //     List<dom.XmlNode> envelope = rootEle.getChildren(); //Childs of <soap:Envelope
    //     List<dom.XmlNode> body = envelope[0].getChildren(); //Childs of <soap:Body>
    //     List<dom.XmlNode> applyForCreditEnhancedResponse = body[0].getChildren(); //Childs of <ns1:applyForCreditEnhancedResponse
    //     List<dom.XmlNode> out = applyForCreditEnhancedResponse[0].getChildren(); //Childs of <ns1:out>
    //     List<dom.XmlNode> applicationECF = out[1].getChildren();
    //     List<dom.XmlNode> decisionOutcome = applicationECF[3].getChildren();
    //     List<dom.XmlNode> andFields = decisionOutcome[1].getChildren(); //Childs of andFields
    //     List<dom.XmlNode> orFields = decisionOutcome[2].getChildren(); //Childs of andFields
    //     String triggeredBy = decisionOutcome[6].getText();

    //     System.debug('andFields:' + andFields);
        
    //     // System.debug('Account Data: >> ' + account);
    //     dnbParams.accountNumber = accountNumber;
    //     dnbParams.businessName = accountName;
        
    //     for(dom.XmlNode field: andFields){
    //         System.debug(field.getChildren()[0].getText());
    //         // if(field.getChildren()[3].getText() == 'D-U-N-S Number'){
    //         //     dnbParams.dunsNumber = field.getChildren()[0].getText();
    //         // } else if(field.getChildren()[3].getText() == 'Assets - Total'){
    //         //     dnbParams.assetsTotal = field.getChildren()[0].getText().replace(',','');
    //         // } else if(field.getChildren()[3].getText() == 'Assets - Total Current'){
    //         //     dnbParams.assetsTotalCurrent = field.getChildren()[0].getText().replace(',','');
    //         // } else if(field.getChildren()[3].getText() == 'Liabilities - Total'){
    //         //     dnbParams.liabilitiesTotal = field.getChildren()[0].getText().replace(',','');
    //         // } else if(field.getChildren()[3].getText() == 'Liabilities - Total Current'){
    //         //     dnbParams.liabilitiesTotalCurrent = field.getChildren()[0].getText().replace(',','');
    //         // } else if(field.getChildren()[3].getText() == 'Net Worth'){
    //         //     dnbParams.netWorth = field.getChildren()[0].getText().replace(',','');
    //         // } else if(field.getChildren()[3].getText() == 'Sales (Revenue)'){
    //         //     dnbParams.saleRevenue = field.getChildren()[0].getText().replace(',','');
    //         // } else if(field.getChildren()[3].getText() == 'Statement Date'){
    //         //     dnbParams.statementDate = field.getChildren()[0].getText();
    //         // } else if(field.getChildren()[3].getText() == 'Working Capital'){
    //         //     dnbParams.workingCapital = field.getChildren()[0].getText().replace(',','');
    //         // } else if(field.getChildren()[3].getText() == 'D&B Rating'){
    //         //     dnbParams.dnbRating = field.getChildren()[0].getText();
    //         // } else if(field.getChildren()[3].getText() == 'D&B Failure Score' || field.getChildren()[3].getText() == 'Failure Score'){
    //         //     dnbParams.dnbFailure = field.getChildren()[0].getText();
    //         // } else if(field.getChildren()[3].getText() == 'PAYDEX®'){
    //         //     dnbParams.paydex = field.getChildren()[0].getText();
    //         // } else if(field.getChildren()[3].getText() == 'D&B  Delinquency Score' || field.getChildren()[3].getText() == 'D&B Delinquency Score' || field.getChildren()[3].getText() == 'Delinquency Score'){
    //         //     dnbParams.dnbDelinquency = field.getChildren()[0].getText();
    //         // } else if(field.getChildren()[3].getText() == 'RestWorldAppCustomScore') {
    //         //     dnbParams.dnbScore = field.getChildren()[0].getText();
    //         // }else if(field.getChildren()[3].getText() == 'Years In Business'){
    //         //     dnbParams.YearsInBusiness = field.getChildren()[0].getText();
    //         // } else if(field.getChildren()[3].getText() == 'Current Liabilities to Inventory %') {
    //         //     dnbParams.currentLiabilitiesToInventoryPercent = field.getChildren()[0].getText();
    //         // } else if(field.getChildren()[3].getText() == 'Gross Profit') {
    //         //     dnbParams.grossProfit = field.getChildren()[0].getText().replace(',','');
    //         // } else if(field.getChildren()[3].getText() == 'Net Profit/Loss') {
    //         //     dnbParams.netProfitNetLoss = field.getChildren()[0].getText().replace(',','');
    //         // } else if(field.getChildren()[3].getText() == 'Long Term Liabilities') {
    //         //     dnbParams.longTermLiabilities = field.getChildren()[0].getText().replace(',','');
    //         // } else if(field.getChildren()[3].getText() == 'Statement Currency Code') {
    //         //     dnbParams.statementCurrencyCode = field.getChildren()[0].getText();
    //         // } else if(field.getChildren()[3].getText() == 'Statement Type') {
    //         //     dnbParams.statementType = field.getChildren()[0].getText();
    //         // } else if(field.getChildren()[3].getText() == 'Stock / Inventory') {
    //         //     dnbParams.inventory = field.getChildren()[0].getText().replace(',','');
    //         // } else if(field.getChildren()[3].getText() == 'Stocks'){
    //         //     dnbParams.inventory = field.getChildren()[0].getText().replace(',','');
    //         // } else if(field.getChildren()[3].getText() == 'Local Business ID Number'){
    //         //     dnbParams.vatNumber = field.getChildren()[0].getText().replace(',','');
    //         // }
    //         if(field.getChildren()[3].getText() == 'D-U-N-S Number'){
    //             dnbParams.dunsNumber = field.getChildren()[0].getText();
    //         } else if(field.getChildren()[3].getText() == 'D&B Rating'){
    //             dnbParams.dnbRating = field.getChildren()[0].getText();
    //         } else if(field.getChildren()[3].getText() == 'D&B Failure Score' || field.getChildren()[3].getText() == 'Failure Score'){
    //             dnbParams.dnbFailure = field.getChildren()[0].getText();
    //         } else if(field.getChildren()[3].getText() == 'PAYDEX®'){
    //             dnbParams.paydex = field.getChildren()[0].getText();
    //         } else if(field.getChildren()[3].getText() == 'D&B  Delinquency Score' || field.getChildren()[3].getText() == 'D&B Delinquency Score' || field.getChildren()[3].getText() == 'Delinquency Score'){
    //             dnbParams.dnbDelinquency = field.getChildren()[0].getText();
    //         } else if(field.getChildren()[3].getText() == 'RestWorldAppCustomScore') {
    //             dnbParams.dnbScore = field.getChildren()[0].getText();
    //         }else if(field.getChildren()[3].getText() == 'Years In Business'){
    //             dnbParams.YearsInBusiness = field.getChildren()[0].getText();
    //         }
    //     }
    //     for(dom.XmlNode field: orFields){
    //         if(field.getChildren()[3].getText() == 'US App Custom Score'){
    //             dnbParams.dnbScore = field.getChildren()[0].getText();
    //         } 
    //     }
    //     return dnbParams;
    // }
    
    public List<Map<String, Object>> getMatchList(HttpResponse response) {
        String responseBody = response.getBody();
        List<Object> parsedResponseList = (List<Object>) JSON.deserializeUntyped(responseBody);
        List<Map<String, Object>> matches = new List<Map<String, Object>>();
        Integer count = 0;
        for (Object matchRecord : parsedResponseList) {
            count += 1;
            if(count > 10) {
                break;
            }
            Map<String, Object> record = (Map<String, Object>)matchRecord;
            Map<String, Object> match = new Map<String, Object>();
            match.put('hint', record.get('Hint') != null ? (String)record.get('Hint') : null);
            match.put('score', record.get('Score') != null ? (Decimal)record.get('Score') * 100 : null);
            match.put('name', record.get('Name') != null ? (String)record.get('Name') : null);
            match.put('address', record.get('Address') != null ? (String)record.get('Address') : null);
            match.put('postcode', record.get('Postcode') != null ? (String)record.get('Postcode') : null);
            match.put('city', record.get('City') != null ? (String)record.get('City') : null);
            match.put('country', record.get('Country') != null ? (String)record.get('Country') : null);
            match.put('nationalId', record.get('NationalId') != null ? (String)record.get('NationalId') : null);
            match.put('nationalIdLabel', record.get('NationalIdLabel') != null ? (String)record.get('NationalIdLabel') : null);
            match.put('legalForm', record.get('LegalForm') != null ? (String)record.get('LegalForm') : null);
            match.put('status', record.get('Status') != null ? (String)record.get('Status') : null);
            match.put('isin', record.get('Isin') != null ? (String)record.get('Isin') : null);
            match.put('bvDId', record.get('BvDId') != null ? (String)record.get('BvDId') : null);
            
            matches.add(match);
        }
        return matches;
    }
    
    
    
    // public List<bureauCompanyDetails> getCompanyList(HttpResponse res) {
    //     List<bureauCompanyDetails> CompanyList = new List<bureauCompanyDetails>();
    //     dom.Document resDoc = res.getBodyDocument();
    //     Dom.XMLNode address = resDoc.getRootElement();
    //     List<dom.XmlNode> body = address.getChildren();
        
    //     List<dom.XmlNode> childNode = body[0].getChildren(); 
    //     System.debug('childNode::'+childNode);
    //     List<dom.XmlNode> matchCompanyResponse = childNode[0].getChildren(); //<ns1:matchCompanyResponse
    //     System.debug('matchCompanyResponse::'+matchCompanyResponse);
    //     List<dom.XmlNode> matchCompanyResponseList = matchCompanyResponse[0].getChildren(); //<ns1:out>
    //     System.debug('matchCompanyResponseList::'+matchCompanyResponseList);
    //     List<dom.XmlNode> bureauCompanyList = matchCompanyResponseList[0].getChildren(); //<bureauCompanyList
    //     System.debug('bureauCompanyList::'+bureauCompanyList);
        
    //     for(dom.XmlNode bureauCompany: bureauCompanyList){ //<ns2:BureauCompanyDTO
    //         bureauCompanyDetails companydetail = new bureauCompanyDetails();
    //         for(dom.XmlNode bureauCompanyChild: bureauCompany.getChildElements()){
    //             system.debug('bureauCompanyChild>>'+ bureauCompanyChild.getName() );
    //             if(bureauCompanyChild.getName() == 'address'){
    //                 for(dom.XmlNode adreedetail: bureauCompanyChild.getChildElements()){ //<city
    //                     system.debug('adreedetail>>'+ adreedetail.getName() );
    //                     if(adreedetail.getName() == 'city'){
    //                         companydetail.city = adreedetail.getText();
    //                     } else if(adreedetail.getName() == 'country'){
    //                         companydetail.country = adreedetail.getText();
    //                     } else if(adreedetail.getName() == 'state'){
    //                         companydetail.state = adreedetail.getText();
    //                     } else if(adreedetail.getName() == 'street'){
    //                         companydetail.street = adreedetail.getText();
    //                     } else if(adreedetail.getName() == 'zipCode'){
    //                         companydetail.zipCode = adreedetail.getText();
    //                     }
    //                 }
    //             } else if(bureauCompanyChild.getName() == 'bureauIdentifierNumber'){
    //                 companydetail.bureauIdentifierNumber = bureauCompanyChild.getText();
    //             } else if(bureauCompanyChild.getName() == 'businessName'){
    //                 companydetail.businessName = bureauCompanyChild.getText();
    //             } else if(bureauCompanyChild.getName() == 'locationIndicator'){
    //                 companydetail.locationIndicator = bureauCompanyChild.getText();
    //             } else if(bureauCompanyChild.getName() == 'matchScore'){
    //                 companydetail.matchScore = bureauCompanyChild.getText();
    //             } else if(bureauCompanyChild.getName() == 'telephone'){
    //                 companydetail.telephone = bureauCompanyChild.getText();
    //             } 
    //         }
    //         CompanyList.add(companydetail);
    //         system.debug('bureauCompany>>>'+ companydetail);
    //     }
    //     System.debug('childNode>>>'+matchCompanyResponseList);
    //     return CompanyList;
    // }
}