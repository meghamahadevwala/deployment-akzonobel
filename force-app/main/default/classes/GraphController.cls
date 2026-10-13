public with sharing class GraphController {
    @auraEnabled
    public List<LineChartVar> myLineChartVarList;
    
    public class LineChartVar {
        Date label;
        Decimal firstValue;
        Decimal secondValue;
        Decimal thirdValue;
        Decimal fourthValue;
        
        public LineChartVar(Date a, Decimal b, Decimal c,  Decimal d, Decimal e){
            label = a;
            firstValue = b;
            secondValue = c;
            thirdValue = d;
            fourthValue = e;
        }
    }
    
    // Manager Cash Monitoring
    @auraEnabled
    public static Map<string,Object> getCashMonitoringManager(string collecitonForecastId){
        system.debug('recordId>>'+collecitonForecastId);
        try{
            Map<String,Object> returnObj = new Map<String, Object>();
            Map<String,Object> summarizeData = new Map<String, Object>();
            List<Cash_Monitoring__c> cms = [SELECT Date__c,Cumulative_Target__c, Cumulative_Receipt_Percent__c, Daily_Receipts__c, Receipt_Target__c, Monthly_Forecast__r.Forecast_Amount__c, 
                                                   Monthly_Forecast__r.Total_Days__c, Cumulative_Receipt__c, Cumulative_Target_Percent__c, Monthly_Forecast__r.Name, Monthly_Forecast__r.Month__c, Monthly_Forecast__r.Year__c
                                                   FROM Cash_Monitoring__c  where Monthly_Forecast__c =:collecitonForecastId ORDER BY Date__c ];
            List<LineChartVar> myLineChartVarList = new List<LineChartVar>();
            
            // Monthly_Forecast__c cfRecord = [SELECT Id, Name, Forecast_Amount__c FROM Monthly_Forecast__c WHERE Id =: collecitonForecastId LIMIT 1];
            summarizeData.put('monthTarget', cms.get(0).Monthly_Forecast__r.Forecast_Amount__c);
            
            integer lastIndex = cms.size()-1;
            Cash_Monitoring__c firstRecord = cms[0];
            Cash_Monitoring__c lastRecord = cms[lastIndex];
            Decimal forecastMonth = lastRecord.Monthly_Forecast__r.Month__c;
            Decimal forecastYear = lastRecord.Monthly_Forecast__r.Year__c;
            Decimal diffPer = 0.0;
            integer diffDays = 0;
            Date todaysDate = Date.newInstance(Date.today().year(), Date.today().month(), Date.today().day());
            Integer currentYear = todaysDate.year();
            Integer currentMonth = todaysDate.month();
            Decimal dailyTarget = 0;
            Decimal avgDailyReciept = 0.0;
            if((forecastYear == currentYear && forecastMonth == currentMonth)){
                List<Cash_Monitoring__c> cmsList = [SELECT Date__c,Cumulative_Target__c, Cumulative_Receipt_Percent__c, Daily_Receipts__c, Monthly_Forecast__r.Forecast_Amount__c, 
                                                            Cumulative_Receipt__c, Cumulative_Target_Percent__c FROM Cash_Monitoring__c WHERE Monthly_Forecast__c =:collecitonForecastId AND Date__c = LAST_N_DAYS:7 ORDER BY Date__c DESC LIMIT 2];
                
                // List<AggregateResult> result = [SELECT AVG(Daily_Receipts__c) avgValue FROM Cash_Monitoring__c WHERE Monthly_Forecast__c =:collecitonForecastId AND Date__c = LAST_N_DAYS:15];
                List<AggregateResult> result = [SELECT AVG(Daily_Receipts__c) avgValue FROM Cash_Monitoring__c WHERE Monthly_Forecast__c =:collecitonForecastId AND Date__c = LAST_N_MONTHS:6];
                
                // Extract the average value
                if (result != null && result[0].get('avgValue') != null) {
                    avgDailyReciept = (Decimal)result[0].get('avgValue');
                }
                if (cmsList.size() > 1) {
                    if (cmsList[0].Cumulative_Target__c > cmsList[1].Cumulative_Target__c) {
                        dailyTarget = cmsList[0].Cumulative_Target__c - cmsList[1].Cumulative_Target__c;
                    } else {
                        dailyTarget = cmsList[1].Cumulative_Target__c - cmsList[0].Cumulative_Target__c;
                    }
                } else {
                    dailyTarget = cmsList[0].Cumulative_Target__c;
                }
            }
            if (forecastYear < currentYear || (forecastYear == currentYear && forecastMonth < currentMonth)) {
                todaysDate = lastRecord.Date__c;
                dailyTarget = cms.get(lastIndex - 6).Cumulative_Target__c - cms.get(lastIndex - 5).Cumulative_Target__c ;
            } else if (forecastYear > currentYear || (forecastYear == currentYear && forecastMonth > currentMonth)) {
                todaysDate = firstRecord.Date__c;
                dailyTarget = 0;
            }
            system.debug('todaysDate>>>'+todaysDate);
            Map<String, Decimal> weekDayCollection = new Map<String, Decimal>();
            Map<String, Decimal> weekDayTarget = new Map<String, Decimal>();
            Map<String, integer> weekDayCount = new Map<String, integer>();
            Decimal tempCumlativeReceipt = 0.0;
            Map<Date,decimal> dayWiseCumalativeReciept = new Map<Date,decimal>();
            Decimal cumalativeReciept = 0.0;
            System.debug('cms  size >>>>' + cms.size());
            
            if(cms != null && cms.size() > 0){
                returnObj.put('forecastName',cms.get(0).Monthly_Forecast__r.Name);
            }
            summarizeData.put('monthTitle',cms.get(0).Monthly_Forecast__r.Name);
            Cash_Monitoring__c previousCm = null; 
            Decimal prevTempCumulativeReciept = null;
            for(Cash_Monitoring__c cm:cms){
                if(cm.Date__c == todaysDate){
                    Decimal cumlativeReceipt = cm.Cumulative_Receipt__c != null && cm.Cumulative_Receipt__c > 0  ?  cm.Cumulative_Receipt__c : 0;
                    Decimal deltaPer = cm.Cumulative_Target__c != null && cm.Cumulative_Target__c > 0 ? (((cumlativeReceipt*100)/cm.Cumulative_Target__c).setScale(2) - 100).setScale(2) : 0;
                    Decimal dailyReciept = cm.Daily_Receipts__c != null ? cm.Daily_Receipts__c : 0;
                    Decimal deltaPerDaily = dailyTarget != 0 ? ((dailyReciept*100)/(dailyTarget).setScale(2) - 100).setScale(2) : 0;
                    summarizeData.put('todaysDate',todaysDate);
                    summarizeData.put('dateTitle',(todaysDate).format());
                    summarizeData.put('todaysTarget',cm.Cumulative_Target__c.setScale(2));
                    summarizeData.put('todaysReceipt',cumlativeReceipt.setScale(2));
                    summarizeData.put('deltaDiff',(cm.Cumulative_Target__c - cumlativeReceipt).setScale(2));
                    summarizeData.put('deltaPer',deltaPer);
                    summarizeData.put('dailyTarget',Math.abs(dailyTarget));
                    summarizeData.put('dailyReciept',dailyReciept);
                    summarizeData.put('deltaDiffDaily',(Math.abs(dailyTarget) - dailyReciept).setScale(2));
                    summarizeData.put('deltaPerDaily',deltaPerDaily);
                    tempCumlativeReceipt = cumlativeReceipt;
                } 
                else if (cm.Date__c > todaysDate) {
                    if (previousCm != null) {
                        System.debug('previousCm.Cumulative_Receipt__c: ' + previousCm.Cumulative_Receipt__c);
                        
                        // Calculate the percentage change (delta)
                        Decimal prevPercent = (previousCm.Cumulative_Target_Percent__c != null) ? previousCm.Cumulative_Target_Percent__c : 0;
                        Decimal currPercent = (cm.Cumulative_Target_Percent__c != null) ? cm.Cumulative_Target_Percent__c : 0;
                        Decimal percentDelta = currPercent - prevPercent; // Change in percentage
                        System.debug('pecent delta: '+ percentDelta);
                        // Apply the delta percentage to prevTempCumulativeReciept
                        if (prevTempCumulativeReciept != null) {
                            prevTempCumulativeReciept += (prevTempCumulativeReciept * (percentDelta / 100));
                        } else {
                            if (previousCm.Cumulative_Receipt__c != null) {
                                prevTempCumulativeReciept = (Decimal)previousCm.Cumulative_Receipt__c * (1 + (percentDelta / 100));
                            } else {
                                prevTempCumulativeReciept = avgDailyReciept; // Default case
                            }
                        }
                
                        tempCumlativeReceipt = prevTempCumulativeReciept;
                    }
                }
                // else if(cm.Date__c > todaysDate){
                //     if(previousCm != null){
                //         // Integer previousIndex = index - 1;
                //         System.debug('previousCm.Cumulative_Receipt__c: '+ previousCm.Cumulative_Receipt__c);
                //         if(prevTempCumulativeReciept != null ){
                //             prevTempCumulativeReciept += avgDailyReciept;
                //         }else{
                //             if(previousCm.Cumulative_Receipt__c != null){
                //                 prevTempCumulativeReciept = (Decimal)previousCm.Cumulative_Receipt__c + avgDailyReciept;
                //             }else{
                //                 prevTempCumulativeReciept = avgDailyReciept;
                //             }
                //         }
                //         tempCumlativeReceipt = prevTempCumulativeReciept;
                //     }
                //     // else{
                //         // tempCumlativeReceipt = avgDailyReciept;
                //         System.debug('avgDailyReciept: '+ avgDailyReciept);
                //     // }
                // } 
                else if(cm.Date__c < todaysDate){
                    tempCumlativeReceipt = 0.0;
                }
                else{
                    tempCumlativeReceipt = cm.Monthly_Forecast__r.Forecast_Amount__c;
                }
                myLineChartVarList.add(new LineChartVar(cm.Date__c, cm.Cumulative_Target__c, cm.Cumulative_Receipt__c, cms[lastIndex].Cumulative_Target__c, tempCumlativeReceipt) ); //cm.Cumulative_Receipt__c
                
                previousCm = cm;
            }
            returnObj.put('summarizeData',summarizeData);
            returnObj.put('graphData',JSON.Serialize(myLineChartVarList));
            return returnObj;
        } catch(exception e){
            system.debug('error occurered in graph controller>> on line>>'+e.getLineNumber()+'<< reason is >>'+e.getMessage()+'<<<Cause:>>' + e.getCause());
            
            return null;
        }
        
    }
    // Manager Cash Monitoring
    
    // Collector Dashboard
    @auraEnabled
    public static Map<string, Map<string, Decimal>> collectorDashboardManager( string collecitonForecastId){
        try{
            system.debug('recordId>>'+collecitonForecastId);
            Map<string, Map<string, Decimal>> tempMap =  new Map<string, Map<string, Decimal>>();
            Map<string, Decimal> collectionTargetMap = new Map<string, Decimal>();
            Map<string, Decimal> cashrRecordMap = new Map<string, Decimal>();
            Map<string, Decimal> percentTargetMap = new Map<string, Decimal>();
            Map<string, Decimal> expectedPercentTargetMap = new Map<string, Decimal>();
            
            if(collecitonForecastId == null || collecitonForecastId == ''){
                collecitonForecastId = GraphController.getForecastIdForCurrentMonth().get('forecastId');
            }
            system.debug('collecitonForecastId>>'+collecitonForecastId);
            
            
            Decimal dateTarget = 0.0;
            List<Cash_Monitoring__c> cms = [SELECT Date__c,Cumulative_Target__c,Cumulative_Receipt__c,Cumulative_Target_Percent__c,Monthly_Forecast__r.Name FROM Cash_Monitoring__c  where Monthly_Forecast__c =:collecitonForecastId ORDER BY Date__c ];
            Date tempDate = Date.newInstance(Date.today().year(), Date.today().month(), Date.today().day());
            
            if(cms != null && cms.size() > 0){
                Map<string, Decimal> nameMap = new  Map<string, Decimal>();
                nameMap.put(cms.get(0).Monthly_Forecast__r.Name,0);
                tempMap.put('forecastName',nameMap);
            }
            
            for( Cash_Monitoring__c cm : cms){            
                if( cm.Date__c == tempDate ){
                    dateTarget = cm.Cumulative_Target_Percent__c;
                }
            }
            if(dateTarget == 0){
                dateTarget = 100;
            }
            
            List<AggregateResult> ctList = [SELECT Collector_User__r.Name nm, SUM(Forecast_Amount__c)ctarget, SUM(Actual_Payment_Received__c)cRecord, SUM(Target_Percent__c)cPercentage FROM Collector_Target__c where Monthly_Forecast__c =:collecitonForecastId group by Collector_User__r.Name ];
            
            for(AggregateResult ct : ctList){
                cashrRecordMap.put(string.valueOf(ct.get('nm')), (Decimal)((ct.get('cRecord') != null) ? ct.get('cRecord') : 0) );
                collectionTargetMap.put(string.valueOf(ct.get('nm')), (Decimal)(ct.get('ctarget')) );
                percentTargetMap.put(string.valueOf(ct.get('nm')), (Decimal)((ct.get('cPercentage') != null) ? ct.get('cPercentage') : 0) );
                expectedPercentTargetMap.put(string.valueOf(ct.get('nm')), dateTarget);
            }
            
            
            tempMap.put('collectionTarget',collectionTargetMap);
            tempMap.put('cashRecord',cashrRecordMap);
            tempMap.put('percentageTarget',percentTargetMap);
            tempMap.put('expectedTarget',expectedPercentTargetMap);
            return tempMap;
        } catch(exception e){
            system.debug('error occurered in graph controller>> on line>>'+e.getLineNumber()+'<< reason is >>'+e.getMessage()+'<<<Cause:>>' + e.getCause());
            
            return null;
        }
    }
    // Collector Dashboard
    
    // Forecast Dashboard
    @auraEnabled
    public static Map<string, Map<string, Decimal>> getForecastCollectionChartMap( ){
        try{
            Map<string, Map<string, Decimal>> tempMap =  new Map<string, Map<string, Decimal>>();
            Map<string, Decimal> TotalAR = new Map<string, Decimal>();
            Map<string, Decimal> CurrentAR = new Map<string, Decimal>();
            Map<string, Decimal> ForecastAmount = new Map<string, Decimal>();
            Map<string, Decimal> ActualCollection = new Map<string, Decimal>();
            Map<string, Decimal> DSO = new Map<string, Decimal>();
            Map<string, Decimal> BPDSO = new Map<string, Decimal>();
            
            List<Monthly_Forecast__c> cfList = [SELECT Name , Total_AR__c, Current_AR__c, Forecast_Amount__c, Actual_Payment_Received__c, DSO__c, BPDSO__c  
                                                          FROM Monthly_Forecast__c order by Year__c DESC, Month__c DESC limit 12];
            
            for(Monthly_Forecast__c cf : cfList){
                if(cf.Total_AR__c != null){
                    TotalAR.put(cf.Name, (Decimal)(cf.Total_AR__c) );
                }
                if(cf.Current_AR__c != null){
                    CurrentAR.put(cf.Name, (Decimal)(cf.Current_AR__c) );
                } 
                if(cf.Forecast_Amount__c != null){
                    ForecastAmount.put(cf.Name, (Decimal)(cf.Forecast_Amount__c) );
                } 
                if(cf.Actual_Payment_Received__c != null){
                    ActualCollection.put(cf.Name, (Decimal)(cf.Actual_Payment_Received__c) );
                } 
                if(cf.DSO__c != null){
                    DSO.put(cf.Name, (Decimal)(cf.DSO__c) );
                } 
                if(cf.BPDSO__c != null){
                    BPDSO.put(cf.Name, (Decimal)(cf.BPDSO__c) );
                } 
            } 
            tempMap.put('TotalAR',TotalAR);
            tempMap.put('CurrentAR',CurrentAR);
            tempMap.put('ForecastAmount',ForecastAmount);
            tempMap.put('ActualCollection',ActualCollection);
            tempMap.put('DSO',DSO);
            tempMap.put('BPDSO',BPDSO);
            return tempMap;
        } catch(exception e){
            system.debug('error occurered in graph controller>> on line>>'+e.getLineNumber()+'<< reason is >>'+e.getMessage()+'<<<Cause:>>' + e.getCause());
            
            return null;
        }
    }
    // Forecast Dashboard
    
    //for individual collector
    // @auraEnabled
    // public static string getLineChartMapForCollectorUser( string collecitonForecastId){
    //     try{
    //         // system.debug('recordId>>'+collecitonForecastId);
    //         Date todaysDate = Date.newInstance(Date.today().year(), Date.today().month(), Date.today().day());
            
    //         Date startOfMonth = todaysDate.toStartOfMonth();
    //         Date startOfNextMonth = todaysDate.addMonths(1);
    //         // List<Cash_Monitoring__c> cms = [SELECT Date__c,Cumulative_Target_Percent__c,Monthly_Forecast__c, Cumulative_Receipt_Percent__c FROM Cash_Monitoring__c  
    //         //                                 where Date__c >=:startOfMonth and Date__c <:startOfNextMonth ORDER BY Date__c ];
            
            
    //         List<Cash_Monitoring__c> cms = [SELECT Date__c,Cumulative_Target__c, Cumulative_Receipt_Percent__c, Monthly_Forecast__r.Forecast_Amount__c, Monthly_Forecast__r.Total_Days__c, Cumulative_Receipt__c, Cumulative_Target_Percent__c 
    //                                                FROM Cash_Monitoring__c where Date__c >=:startOfMonth and Date__c <:startOfNextMonth ORDER BY Date__c ];
    //         List<LineChartVar> myLineChartVarList = new List<LineChartVar>();
    //         List<sfsrm__Collector_Target__c> ct = [SELECT Id,sfsrm__Target__c from sfsrm__Collector_Target__c where sfsrm__Collector__c=: UserInfo.getUserId() and Monthly_Forecast__c =: cms[0].Monthly_Forecast__c] ;
            
    //         List<AggregateResult> transCollLst = [ Select  SUM(sfsrm__Amount__c)amt, sfsrm__Close_Date__c cd  FROM sfsrm__Transaction__c 
    //                                               WHERE sfsrm__Close_Date__c >=:startOfMonth and sfsrm__Close_Date__c <=: todaysDate
    //                                               and sfsrm__Amount__c > 0 and sfsrm__Account__r.OwnerId =: UserInfo.getUserId() group by sfsrm__Close_Date__c ];
            
    //         List<sfsrm__Transaction__c> translLst = [ Select  sfsrm__Amount__c, sfsrm__Close_Date__c  FROM sfsrm__Transaction__c 
    //                                                  WHERE sfsrm__Close_Date__c >=:startOfMonth and sfsrm__Close_Date__c <=: todaysDate
    //                                                  and sfsrm__Amount__c > 0 and sfsrm__Account__r.OwnerId =: UserInfo.getUserId() ];
            
    //         // Map<Date,Decimal> closedTransByDate = new Map<Date,Decimal>();
    //         // for(sfsrm__Transaction__c trnsa : translLst){
    //         //     closedTransByDate.put(trnsa.sfsrm__Close_Date__c, trnsa.sfsrm__Amount__c);
    //         // }
    //         Map<Date,Decimal> closedTrans = new Map<Date,Decimal>();
    //         for(AggregateResult trns : transCollLst){
    //             Date tempDate = Date.newInstance(Date.valueOf(trns.get('cd')).year(), Date.valueOf(trns.get('cd')).month(), Date.valueOf(trns.get('cd')).day());
    //             closedTrans.put( tempDate, (decimal)trns.get('amt'));
    //         }
    //         Decimal tempCumalativeTarget = 0.0;
    //         Decimal tempCumalativeReceipt = 0.0;
    //         integer lastIndex = cms.size() - 1;
    //         integer countDays = 0;
    //         Decimal diffPer = 0.0;
    //         integer diffDays = 0;
    //         for(Cash_Monitoring__c cm:cms){
    //             Decimal projectedCumlativeReceipt = 0.0;
    //             Decimal tempDailyReciept = !closedTrans.isEmpty() && closedTrans.containsKey(cm.Date__c) && closedTrans.get(cm.Date__c) != null ? closedTrans.get(cm.Date__c) : 0.0;
    //             Decimal finalTarget = (cms[lastIndex].Cumulative_Target_Percent__c/100)*ct[0].sfsrm__Target__c;
    //             // if(tempDailyReciept > 0){
                
    //             // } else{
    //             // tempCumalativeReceipt = tempCumalativeReceipt;
    //             // }
    //             if(cm.Date__c <= todaysDate){
    //                 // projectedCumlativeReceipt = tempCumalativeReceipt;
    //                 tempCumalativeReceipt += tempDailyReciept;
    //             }  
    //             if(cm.Date__c == todaysDate){
    //                 projectedCumlativeReceipt = tempCumalativeReceipt;
    //                 // tempCumalativeReceipt = 0;
    //             } else if(cm.Date__c > todaysDate){
    //                 tempCumalativeReceipt = 0;
    //                 system.debug('countDayscountDayscountDays>>>>..'+countDays);
    //                 if(countDays > 0){
    //                     if(diffPer == 0.0){
    //                         system.debug('cms[(countDays > 0 ? countDays-1 : countDays)].Cumulative_Target_Percent__c>>>>>>>>>>>'+cms[(countDays > 0 ? countDays-1 : countDays)].Cumulative_Target_Percent__c);
    //                         system.debug('cms[(countDays > 0 ? countDays-1 : countDays)].Cumulative_Receipt_Percent__c>>>>>>>>>>>'+cms[(countDays > 0 ? countDays-1 : countDays)].Cumulative_Receipt_Percent__c);
    //                         diffPer = cms[(countDays > 0 ? countDays-1 : countDays)].Cumulative_Target_Percent__c - cms[(countDays > 0 ? countDays-1 : countDays)].Cumulative_Receipt_Percent__c;
    //                         diffDays = (integer)(cm.Monthly_Forecast__r.Total_Days__c - countDays);
    //                     }
    //                     Decimal tempPerAdd = (diffPer/diffDays).setScale(2); //diffPer.divide(diffDays, 2, System.RoundingMode.UP)
    //                     system.debug('tempPerAdd>>>>>>>>>>>'+tempPerAdd);                
    //                     if(countDays < cms.size()-1){
    //                         system.debug('cm.Cumulative_Target_Percent__c>>>.'+ cm.Cumulative_Target_Percent__c);
    //                         system.debug('cm.Cumulative_Target_Percent__c>>>.'+ cms[countDays+1].Cumulative_Target_Percent__c);
    //                         Decimal tempDiff =  cms[countDays+1].Cumulative_Target_Percent__c - cm.Cumulative_Target_Percent__c ;
    //                         system.debug('tempDiff>>>>>>>>>>>'+tempDiff);
    //                         Decimal addVal = tempDiff+tempPerAdd+cms[(countDays > 0 ? countDays-1 : countDays)].Cumulative_Target_Percent__c;
    //                         system.debug('addval>>>>>>>>>>>'+addVal);
    //                         projectedCumlativeReceipt = (finalTarget * addVal).divide(100, 2, System.RoundingMode.HALF_DOWN); //(/100).setScale(2);                   
    //                     }  else{
    //                         projectedCumlativeReceipt = finalTarget;
    //                     }
    //                 }else{
    //                     projectedCumlativeReceipt = finalTarget;
    //                 }     
    //             }
                
    //             tempCumalativeTarget =  (cm.Cumulative_Target_Percent__c/100)*ct[0].sfsrm__Target__c;
                
    //             myLineChartVarList.add(new LineChartVar(cm.Date__c, tempCumalativeTarget,tempCumalativeReceipt,finalTarget, projectedCumlativeReceipt));
    //             countDays++;
    //         } 
    //         return JSON.Serialize(myLineChartVarList);
    //     } catch(exception e){
    //         system.debug('error occurered in graph controller>> on line>>'+e.getLineNumber()+'<< reason is >>'+e.getMessage()+'<<<Cause:>>' + e.getCause());
            
    //         return null;
    //     }
    // }
    
    
    //for individual collector
    @auraEnabled
    public static Map<String, String> getForecastIdForCurrentMonth(){
        try{
            System.debug('getForecastIdForCurrentMonth called >>> ');
            Datetime currentDate = (Datetime.newInstance(date.today().year(), date.today().month(), date.today().day()));//.addDays(-6)
            system.debug('this.currentDate>>'+currentDate);
            String currentMonth = currentDate.format('MMM');
            String currentYear = currentDate.format('YY');
            String forecastName = currentMonth +'-'+ currentYear;
            System.debug('forecastName >>> ' + forecastName);
            List<Monthly_Forecast__c> listCurrentForecast = [SELECT Id,Name FROM Monthly_Forecast__c where Name =:forecastName];
            System.debug('listCurrentForecast >>> ' + listCurrentForecast);
            if(listCurrentForecast != null && !listCurrentForecast.isEmpty()){
                
                return new Map<String, String>{
                    'forecastId' => listCurrentForecast[0].Id,
                    'forecastName' => listCurrentForecast[0].Name
                };
            }else{
                List<Monthly_Forecast__c> cfList = [SELECT Id,Name FROM Monthly_Forecast__c order by Year__c desc, Month__c desc limit 2];
                if(!cfList.isEmpty()){
                    return new Map<String, String>{
                        'forecastId' => cfList[0].Id,
                        'forecastName' => cfList[0].Name
                    };
                }
            }
            return null;
        }catch(exception e){
            system.debug('error occurered in graph controller>> on line>>'+e.getLineNumber()+'<< reason is >>'+e.getMessage()+'<<<Cause:>>' + e.getCause());
            return null;
        }
    }
    
    //for individual collector
    
    //closed transaction amount group by close date
    // public static Map<string, Decimal> closedTransaction(){
    //     try{   
    //         Map<string, Decimal> closdTransMap = new Map<string, Decimal>();
    //         Date startDate = Date.newInstance(date.today().year(), date.today().month(), date.today().day()).toStartOfMonth();
    //         Date todayDate = Date.newInstance(date.today().year(), date.today().month(), date.today().day());
    //         list<AggregateResult> aggregateTransListOwner = [SELECT SUM(sfsrm__Amount__c)totalAmt, sfsrm__Close_Date__c closeDate 
    //                                                                     FROM sfsrm__Transaction__c WHERE sfsrm__Amount__c > 0 
    //                                                                     AND sfsrm__Close_Date__c >: startDate AND
    //                                                                     sfsrm__Close_Date__c <=: todayDate AND sfsrm__Account__r.OwnerId =: UserInfo.getUserId() 
    //                                                                     Group by sfsrm__Close_Date__c];
    //         for(AggregateResult aggr : aggregateTransListOwner){
    //             closdTransMap.put(String.valueOf(aggr.get('closeDate')), (Decimal)aggr.get('totalAmt'));
    //         }
    //         return closdTransMap;
    //     } catch(exception e){
    //         system.debug('error occurered in graph controller>> on line>>'+e.getLineNumber()+'<< reason is >>'+e.getMessage()+'<<<Cause:>>' + e.getCause());
    
    //         return null;
    //     }
    // }
    //closed transaction amount group by close date
}