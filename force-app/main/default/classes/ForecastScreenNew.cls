Global with sharing class ForecastScreenNew implements celsrm.GOGIScreenCustomLogic {
    private List<String> documentTypes;

    public ForecastScreenNew() {
        this.documentTypes = new List<String>{'RV','AB','DG','DR','DA'};
    }

    public ForecastScreenNew(List<String> documentTypes) {
        this.documentTypes = documentTypes;
    }
    Global Map<Object,Object> invoke(String functionName,Map<Object,Object> inMap){
        
        Map<String, String> monthMap = new Map<String, String>{'1'=>'Jan','2'=>'Feb','3'=>'Mar','4'=>'Apr','5'=>'May','6'=>'Jun','7'=>'Jul','8'=>'Aug','9'=>'Sep','10'=>'Oct','11'=>'Nov','12'=>'Dec'};
        
        if(functionName == 'GetPickListOptionForPeriod'){
            Date periodStartMonth = Date.newInstance(date.today().year(), date.today().month(), date.today().day()).toStartOfMonth().addMonths(-5);
            system.debug('periodStartMonth>>>>'+periodStartMonth);
            List<Map<String,String>> forecastingPeriodList = new List<Map<String,String>>();
            for(Integer i = 0; i < 12; i++){
                Map<String,String> tempMap = new Map<String,String>();
                date tempDate = periodStartMonth.addMonths(i);
                Date startMonthEachPeriod = tempDate;
                String tempMonth = monthMap.get(String.valueOf(startMonthEachPeriod.month())) + '-' + String.valueOf(startMonthEachPeriod.year()).right(2);
                String tempVal = String.valueOf(startMonthEachPeriod.month()) + '-' + String.valueOf(startMonthEachPeriod.year());
                tempMap.put('label',tempMonth);
                tempMap.put('value',tempVal);
                forecastingPeriodList.add(tempMap);
            } 

            // Reverse the list to have descending order of months
            List<Map<String, String>> reversedList = new List<Map<String, String>>();
            for (Integer i = forecastingPeriodList.size() - 1; i >= 0; i--) {
                reversedList.add(forecastingPeriodList[i]);
            }

            inMap.put('dataServiceResponse',reversedList);
        }

        if(functionName == 'GetAverageDSO'){
            List<String> period = String.valueOf(inMap.get('Period')).split('-');
            Integer forecastMonth = Integer.valueOf(period[0]);
            Integer forecastYear = Integer.valueOf(period[1]);
            Date firstDayOfForecastMonth = Date.newInstance(forecastYear, forecastMonth, 1);
            Integer numberOfDays = Date.daysInMonth(forecastYear, forecastMonth);
            Date lastDayOfMonth = Date.newInstance(forecastYear, forecastMonth, numberOfDays);

            inMap.put('avgDSO', 0);
            inMap.put('bpDSO', 0);

            // String query = 'SELECT Id, ' +
            //            'celsrm__Create_Date__c, celsrm__Due_Date__c, celsrm__Close_Date__c, celsrm__Document_Type__c  '+
            //            'FROM celsrm__Transaction__c ' +
            //            'WHERE Expected_Payment_Date__c <= :lastDayOfMonth ' +
            //            	'AND celsrm__Document_Type__c IN :documentTypes ' +
            //         	'AND (celsrm__Close_Date__c = null OR celsrm__Close_Date__c > :firstDayOfForecastMonth) ' +
            //            'AND celsrm__Amount__c != null';

            // List<celsrm__Transaction__c> transactions = Database.query(query);

            // Integer totalDays = 0;
            // Integer count = 0;

            // // Calculate days for each transaction
            // for (celsrm__Transaction__c trxn : transactions) {
            //     Date createDate = trxn.celsrm__Create_Date__c;
            //     Date closeDate = trxn.celsrm__Close_Date__c;

            //     if (createDate != null) {
            //         Integer days;
            //         if (closeDate != null) {
            //             days = Math.abs(createDate.daysBetween(closeDate));
            //         } else {
            //             days = Math.abs(createDate.daysBetween(firstDayOfForecastMonth));
            //         }
            //         totalDays += days;
            //         count++;
            //     }
            // }

            // // Calculate and return the average
            // if(count > 0){
            //     inMap.put('avgDSO', Math.round(Decimal.valueOf(totalDays) / count));
            // }else{
            //     inMap.put('avgDSO', 0);
            // }

            // //calculate BPDSO
            // String bpDSOQuery = 'SELECT Id, ' +
            //            'celsrm__Create_Date__c, celsrm__Due_Date__c, celsrm__Close_Date__c, celsrm__Document_Type__c  '+
            //            'FROM celsrm__Transaction__c ' +
            //            'WHERE celsrm__Create_Date__c < :firstDayOfForecastMonth AND celsrm__Due_Date__c >= :firstDayOfForecastMonth ' +
            //            	'AND celsrm__Document_Type__c IN :documentTypes ' +
            //         	'AND (celsrm__Close_Date__c = null OR celsrm__Close_Date__c > :firstDayOfForecastMonth) ' +
            //            'AND celsrm__Amount__c != null';

            // List<celsrm__Transaction__c> eligibleTransactionsForBPDSO = Database.query(bpDSOQuery);

            // totalDays = 0;
            // count = 0;

            // // Calculate days for each transaction
            // for (celsrm__Transaction__c trxn : eligibleTransactionsForBPDSO) {
            //     Date createDate = trxn.celsrm__Create_Date__c;
            //     Date closeDate = trxn.celsrm__Close_Date__c;

            //     if (createDate != null) {
            //         Integer days;
            //         if (closeDate != null) {
            //             days = Math.abs(createDate.daysBetween(closeDate));
            //         } else {
            //             days = Math.abs(createDate.daysBetween(firstDayOfForecastMonth));
            //         }
            //         totalDays += days;
            //         count++;
            //     }
            // }

            // // Calculate and return the average
            // if(count > 0){
            //     inMap.put('bpDSO', Math.round(Decimal.valueOf(totalDays) / count));
            // }else{
            //     inMap.put('bpDSO', 0);
            // }
         }
        
        // if(functionName == 'SetDefaultValueOfPeriod'){
		// 	try{
		// 		date curretMonthStartingDate = date.today().toStartOfMonth();//.addMonths(-1)
		// 		Date startDate = curretMonthStartingDate;
        //         String currentPeriod = startDate+'#'+startDate.addMonths(1).addDays(-1);
        //         System.debug('currentPeriod >> ' + currentPeriod);
		// 		//String currentPeriod = startDate.format('MMM') + '-' + startDate.format('YY');
		// 		inMap.put('Period',currentPeriod);
		// 		List<Object> setDays = setMonthDays(curretMonthStartingDate, UserInfo.getTimeZone());
		// 		inMap.put('TotalDays',setDays);
				
		// 		//to set default cash target gross based on 70 Target Gross DBO
		// 		Decimal newTarGross = 0;
		// 		Decimal totalCashTrgtGross = 0;
		// 		Decimal totalTargetDBO = 0;
		// 		Decimal finalCashTarget = 0;
		// 		Decimal systemSuggestedDSO = 65;
		// 		Decimal lastMonthDSO = 70;
		// 		Decimal lastMonthBPDSO = 0;
		// 		Decimal totalActualGrossDSO = 0;
		// 		Decimal totalActualGrossDSORecCount = 0;
		// 		List<sfsrm__Collection_Forecast__c > forecastList = [Select Id, Name, sfsrm__Cash_Target_Gross__c,sfsrm__Actual_Gross_DBO__c, sfsrm__Target_Gross_DBO__c, sfsrm__Start_Date__c,sfsrm__Actual_Collection__c,sfsrm__Cumulative_Cash_Receipt__c,sfsrm__BP_DBO__c from sfsrm__Collection_Forecast__c order by sfsrm__Start_Date__c desc limit 6];
		// 		if(forecastList.size() > 0){
		// 			if(forecastList.get(0).sfsrm__Actual_Gross_DBO__c != null){
		// 				lastMonthDSO = forecastList.get(0).sfsrm__Actual_Gross_DBO__c.round();
		// 			}
					
		// 			if(forecastList.get(0).sfsrm__BP_DBO__c != null){
		// 				lastMonthBPDSO = forecastList.get(0).sfsrm__BP_DBO__c.round();
		// 			}
					
		// 			Decimal avgTrgtCashGross=0;
		// 			Decimal avgTrgtDBO=0;
		// 			systemSuggestedDSO=0;
		// 			if(forecastList.size() > 0) {
		// 				avgTrgtCashGross += forecastList.get(0).sfsrm__Actual_Collection__c / 2;
		// 				avgTrgtDBO += forecastList.get(0).sfsrm__Actual_Gross_DBO__c / 2;
		// 				systemSuggestedDSO += forecastList.get(0).sfsrm__Actual_Gross_DBO__c / 2;
		// 			}
		// 			if(forecastList.size() > 1) {
		// 				avgTrgtCashGross += forecastList.get(1).sfsrm__Actual_Collection__c / 4;
		// 				avgTrgtDBO += forecastList.get(1).sfsrm__Actual_Gross_DBO__c / 4;
		// 				systemSuggestedDSO += forecastList.get(1).sfsrm__Actual_Gross_DBO__c / 4;
		// 			}
		// 			if(forecastList.size() > 2) {
		// 				avgTrgtCashGross += forecastList.get(2).sfsrm__Actual_Collection__c / 8;
		// 				avgTrgtDBO += forecastList.get(2).sfsrm__Actual_Gross_DBO__c / 8;
		// 				systemSuggestedDSO += forecastList.get(2).sfsrm__Actual_Gross_DBO__c / 8;
		// 			}
		// 			if(forecastList.size() > 3) {
		// 				avgTrgtCashGross += forecastList.get(3).sfsrm__Actual_Collection__c / 16;
		// 				avgTrgtDBO += forecastList.get(3).sfsrm__Actual_Gross_DBO__c / 16;
		// 				systemSuggestedDSO += forecastList.get(3).sfsrm__Actual_Gross_DBO__c / 16;
		// 			}
		// 			if(forecastList.size() > 4) {
		// 				avgTrgtCashGross += forecastList.get(4).sfsrm__Actual_Collection__c / 32;
		// 				avgTrgtDBO += forecastList.get(4).sfsrm__Actual_Gross_DBO__c / 32;
		// 				systemSuggestedDSO += forecastList.get(4).sfsrm__Actual_Gross_DBO__c / 32;
		// 			}
		// 			if(forecastList.size() > 5) {
		// 				avgTrgtCashGross += forecastList.get(5).sfsrm__Actual_Collection__c / 32;
		// 				avgTrgtDBO += forecastList.get(5).sfsrm__Actual_Gross_DBO__c / 32;
		// 				systemSuggestedDSO += forecastList.get(5).sfsrm__Actual_Gross_DBO__c / 32;
		// 			}
		// 			System.debug('systemSuggestedDSO >>> ' + systemSuggestedDSO);
		// 			systemSuggestedDSO = systemSuggestedDSO.round();
		// 			/*for(sfsrm__Collection_Forecast__c cf : forecastList){
		// 				totalCashTrgtGross += cf.sfsrm__Cash_Target_Gross__c;
		// 				totalTargetDBO += cf.sfsrm__Target_Gross_DBO__c;
		// 				totalActualGrossDSO += cf.sfsrm__Actual_Gross_DBO__c;
		// 				totalActualGrossDSORecCount++;
		// 			}*/
					
		// 			//Decimal avgTrgtCashGross = totalCashTrgtGross/forecastList.size();
		// 			//Decimal avgTrgtDBO = totalTargetDBO/forecastList.size();
					
		// 			/*if(totalActualGrossDSO > 0 && totalActualGrossDSORecCount > 0){
		// 				systemSuggestedDSO = (totalActualGrossDSO/totalActualGrossDSORecCount).round();
		// 			}*/
					
		// 			if(avgTrgtDBO > 0 && avgTrgtCashGross > 0 && systemSuggestedDSO > 0){
		// 				finalCashTarget = ((avgTrgtDBO*avgTrgtCashGross)/systemSuggestedDSO).round();
		// 			}else{
		// 				finalCashTarget = 0 ;
		// 			}
					
		// 			inMap.put('SystemSuggestedInitialDSO',systemSuggestedDSO);
		// 			inMap.put('SystemSuggestedInitialCashTargetGross',finalCashTarget);
		// 			inMap.put('targetGrossDBO',systemSuggestedDSO);
		// 			inMap.put('cashTargetGross',finalCashTarget);
		// 			inMap.put('SystemSuggestedDBO','<div class="cards slds-m-right_x-small" data-value="test"   style="width:66%;height: 100%;cursor: pointer;position: relative;padding: 0;background: var(--lwc-cardColorBackground,rgb(255, 255, 255));border:var(--lwc-borderWidthThin,1px) solid var(--lwc-cardColorBorder,rgb(221, 219, 218)); border-radius: var(--lwc-borderRadiusMedium,0.25rem); background-clip: padding-box;box-shadow: var(--lwc-cardShadow,0 2px 2px 0 rgba(0, 0, 0, 0.10));" id="myDIV"> <b style="text-align: center;">     <div class="slds-p-around_small" style="font-size: 15px;">          System Suggested DSO</div>  </b>    <b style="text-align: center;" >        <div style="color: #00716B;display: block;margin-left: auto;margin-right: auto;font-size: 25px;background: inherit;"  >' + systemSuggestedDSO + ' days</div>    </b></div>');
		// 			//inMap.put('Confidence','<div class="cards slds-m-right_x-small" data-value="test"   style="width:66%;height: 100%;cursor: pointer;position: relative;padding: 0;background: var(--lwc-cardColorBackground,rgb(255, 255, 255));border:var(--lwc-borderWidthThin,1px) solid var(--lwc-cardColorBorder,rgb(221, 219, 218)); border-radius: var(--lwc-borderRadiusMedium,0.25rem); background-clip: padding-box;box-shadow: var(--lwc-cardShadow,0 2px 2px 0 rgba(0, 0, 0, 0.10));" id="myDIV"> <b style="text-align: center;">     <div class="slds-p-around_small" style="font-size: 15px;">          Confidence</div>    </b>    <b style="text-align: center;" >        <div style="color: #00716B;display: block;margin-left: auto;margin-right: auto;font-size: 25px;background: inherit;"  >74%</div>    </b></div>');
		// 			inMap.put('LastMonthDBO','<div class="cards slds-m-right_x-small" data-value="test"     style="width:77%;height: 100%;cursor: pointer;position: relative;padding: 0;background: var(--lwc-cardColorBackground,rgb(255, 255, 255));border:var(--lwc-borderWidthThin,1px) solid var(--lwc-cardColorBorder,rgb(221, 219, 218)); border-radius: var(--lwc-borderRadiusMedium,0.25rem); background-clip: padding-box;box-shadow: var(--lwc-cardShadow,0 2px 2px 0 rgba(0, 0, 0, 0.10));" id="myDIV"> <b style="text-align: center;">     <div class="slds-p-around_small" style="font-size: 15px;">          Last Month DSO</div>    </b>    <b style="text-align: center;" >        <div style="color: #00716B;display: block;margin-left: auto;margin-right: auto;font-size: 25px;background: inherit;"  >' + lastMonthDSO + ' days</div>  </b></div>');
		// 			inMap.put('LastMonthBPDSO','<div class="cards slds-m-right_x-small" data-value="test"     style="width:88%;height: 100%;cursor: pointer;position: relative;padding: 0;background: var(--lwc-cardColorBackground,rgb(255, 255, 255));border:var(--lwc-borderWidthThin,1px) solid var(--lwc-cardColorBorder,rgb(221, 219, 218)); border-radius: var(--lwc-borderRadiusMedium,0.25rem); background-clip: padding-box;box-shadow: var(--lwc-cardShadow,0 2px 2px 0 rgba(0, 0, 0, 0.10));" id="myDIV"> <b style="text-align: center;">     <div class="slds-p-around_small" style="font-size: 15px;">          Last Month BPDSO</div>    </b>    <b style="text-align: center;" >        <div style="color: #00716B;display: block;margin-left: auto;margin-right: auto;font-size: 25px;background: inherit;"  >' + lastMonthBPDSO + ' days</div>  </b></div>');
		// 			inMap.put('Confidence','<div class="cards slds-m-right_x-small" data-value="test"   style="width:66%;height: 100%;cursor: pointer;position: relative;padding: 0;background: var(--lwc-cardColorBackground,rgb(255, 255, 255));border:var(--lwc-borderWidthThin,1px) solid var(--lwc-cardColorBorder,rgb(221, 219, 218)); border-radius: var(--lwc-borderRadiusMedium,0.25rem); background-clip: padding-box;box-shadow: var(--lwc-cardShadow,0 2px 2px 0 rgba(0, 0, 0, 0.10));" id="myDIV"> <b style="text-align: center;">     <div class="slds-p-around_small" style="font-size: 15px;">          Confidence</div>    </b>    <b style="text-align: center;" >        <div style="color: #00716B;display: block;margin-left: auto;margin-right: auto;font-size: 25px;background: inherit;"  > 80%</div>  </b></div>');
		// 		}
		// 		//to set default cash target gross based on 70 Target Gross DBO
		// 	}catch(exception e){
        //         system.debug('exception occured on line : '+e.getLineNumber() + ' Reason is >>'+e.getMessage());
        //     }
        // }
        
        // if(functionName == 'SetDaysOnMonthChange'){
        //     system.debug('inMap Value>>>>>>>>>'+inMap);
        //     if(inMap.get('Period') != null) {
        //         List<String> p = String.valueOf(inMap.get('Period')).split('#');
        //         //system.debug('p>>>>'+p);
        //         List<String> sDate = String.valueOf(p[0]).removeEnd('00:00:00').deleteWhitespace().split('-');
        //         //system.debug('sDate>>>>'+sDate);
        //         Date startDate = Date.newInstance(Integer.valueOf(sDate[0]), Integer.valueOf(sDate[1]), Integer.valueOf(sDate[2]));
        //         //system.debug('sDate>>>>'+startDate);
        //         List<Object> setDays = setMonthDays(startDate, UserInfo.getTimeZone());
        //         inMap.put('TotalDays',setDays);
        //     }
        // }
        
        // if(functionName == 'CheckForecastConfiguration'){
        //     Boolean showForecastFields = sfsrm__Forecast_Configuration__c.getOrgDefaults().sfsrm__Show_Forecast_Fields__c;
        //     if(showForecastFields){
        //         inMap.put('ShowFields','show');
        //     } else{
        //         inMap.put('ShowFields','hide');
        //     }
        // }

        // if(functionName == 'changeCashTargetGross'){
        //     try{
        //         List<sfsrm__Collection_Forecast__c> forecastList = new List<sfsrm__Collection_Forecast__c>();
        //         Decimal userEntCashTarGross = (Decimal)inMap.get('cashTargetGross');
        //         //Decimal newTarGross = 0;
        //         Decimal totalCashTrgtGross = 0;
        //         Decimal totalTargetDBO = 0;
        //         Decimal finalTargetDBO = 0;
        //         forecastList = [Select Id, Name, sfsrm__Cash_Target_Gross__c, sfsrm__Actual_Gross_DBO__c,sfsrm__Target_Gross_DBO__c, sfsrm__Start_Date__c,sfsrm__Actual_Collection__c,sfsrm__Cumulative_Cash_Receipt__c from sfsrm__Collection_Forecast__c order by sfsrm__Start_Date__c desc limit 6];
        //         if(forecastList.size() > 0){
                    
        //             Decimal avgTrgtCashGross=0;
        //             Decimal avgTrgtDBO=0;
        //             if(forecastList.size() > 0) {
        //                 avgTrgtCashGross += forecastList.get(0).sfsrm__Actual_Collection__c / 2;
        //                 avgTrgtDBO += forecastList.get(0).sfsrm__Actual_Gross_DBO__c / 2;
        //             }
        //             if(forecastList.size() > 1) {
        //                 avgTrgtCashGross += forecastList.get(1).sfsrm__Actual_Collection__c / 4;
        //                 avgTrgtDBO += forecastList.get(1).sfsrm__Actual_Gross_DBO__c / 4;
        //             }
        //             if(forecastList.size() > 2) {
        //                 avgTrgtCashGross += forecastList.get(2).sfsrm__Actual_Collection__c / 8;
        //                 avgTrgtDBO += forecastList.get(2).sfsrm__Actual_Gross_DBO__c / 8;
        //             }
        //             if(forecastList.size() > 3) {
        //                 avgTrgtCashGross += forecastList.get(3).sfsrm__Actual_Collection__c / 16;
        //                 avgTrgtDBO += forecastList.get(3).sfsrm__Actual_Gross_DBO__c / 16;
        //             }
        //             if(forecastList.size() > 4) {
        //                 avgTrgtCashGross += forecastList.get(4).sfsrm__Actual_Collection__c / 32;
        //                 avgTrgtDBO += forecastList.get(4).sfsrm__Actual_Gross_DBO__c / 32;
        //             }
        //             if(forecastList.size() > 5) {
        //                 avgTrgtCashGross += forecastList.get(5).sfsrm__Actual_Collection__c / 32;
        //                 avgTrgtDBO += forecastList.get(5).sfsrm__Actual_Gross_DBO__c / 32;
        //             }

        //             // for(sfsrm__Collection_Forecast__c cf : forecastList){
        //             //     totalCashTrgtGross += cf.sfsrm__Cash_Target_Gross__c;
        //             //     totalTargetDBO += cf.sfsrm__Target_Gross_DBO__c;
        //             // }
        //             // Decimal avgTrgtCashGross = totalCashTrgtGross/forecastList.size();
        //             // Decimal avgTrgtDBO = totalTargetDBO/forecastList.size();

                    
        //             if(avgTrgtDBO > 0 && avgTrgtCashGross > 0 && userEntCashTarGross > 0){
        //                 finalTargetDBO = ((avgTrgtCashGross*avgTrgtDBO)/userEntCashTarGross).round();
        //             }else{
		// 				finalTargetDBO = 0 ;
		// 			}
        //             inMap.put('targetGrossDBO',finalTargetDBO);
        //         } else{
        //             finalTargetDBO=65;
        //             inMap.put('targetGrossDBO',finalTargetDBO);
        //         }
                
        //         Integer systemSuggestedInitialDSO = Integer.valueOf(inMap.get('SystemSuggestedInitialDSO'));
        //         Decimal newConfidence = ((80*finalTargetDBO) / systemSuggestedInitialDSO).round();
        //         if (newConfidence > 100) newConfidence=100;
        //         if (newConfidence < 0) newConfidence=0;

        //         // System.debug('systemSuggestedInitialDSO >>> ' + systemSuggestedInitialDSO);
        //         // System.debug('finalTargetDBO >>> ' + finalTargetDBO);
        //         // if(finalTargetDBO >= systemSuggestedInitialDSO){
        //         //     inMap.put('Confidence','<div class="cards slds-m-right_x-small" data-value="test"   style="width:66%;height: 100%;cursor: pointer;position: relative;padding: 0;background: var(--lwc-cardColorBackground,rgb(255, 255, 255));border:var(--lwc-borderWidthThin,1px) solid var(--lwc-cardColorBorder,rgb(221, 219, 218)); border-radius: var(--lwc-borderRadiusMedium,0.25rem); background-clip: padding-box;box-shadow: var(--lwc-cardShadow,0 2px 2px 0 rgba(0, 0, 0, 0.10));" id="myDIV"> <b style="text-align: center;">     <div class="slds-p-around_small" style="font-size: 15px;">          Confidence</div>    </b>    <b style="text-align: center;" >        <div style="color: #00716B;display: block;margin-left: auto;margin-right: auto;font-size: 25px;background: inherit;"  > 100%</div>  </b></div>');
        //         // }else{
        //         String color = '';
                
        //         // Decimal newConfidence = ((100*finalTargetDBO) / systemSuggestedInitialDSO).round();
                
        //         if(newConfidence >= 70){
        //             color = '#00716B';
        //         }
        //         else if(newConfidence >= 40 && newConfidence < 70){
        //             color = '#FFB75D';
        //         }else{
        //             color = '#FB453C';
        //         }
                
        //         System.debug('newConfidence >>> ' + newConfidence);
        //         // newConfidence = newConfidence > 0 ? newConfidence : 0;
        //         inMap.put('Confidence','<div class="cards slds-m-right_x-small" data-value="test"   style="width:66%;height: 100%;cursor: pointer;position: relative;padding: 0;background: var(--lwc-cardColorBackground,rgb(255, 255, 255));border:var(--lwc-borderWidthThin,1px) solid var(--lwc-cardColorBorder,rgb(221, 219, 218)); border-radius: var(--lwc-borderRadiusMedium,0.25rem); background-clip: padding-box;box-shadow: var(--lwc-cardShadow,0 2px 2px 0 rgba(0, 0, 0, 0.10));" id="myDIV"> <b style="text-align: center;">     <div class="slds-p-around_small" style="font-size: 15px;">          Confidence</div>    </b>    <b style="text-align: center;" >        <div style="color: ' + color + ';display: block;margin-left: auto;margin-right: auto;font-size: 25px;background: inherit;"  >' + newConfidence + '%</div>   </b></div>');
        //         // }
        //     } catch(exception e){
        //         system.debug('exception occured on line'+e.getLineNumber() + 'Reason is >>'+e.getMessage());
        //     }
        // }

        // if(functionName == 'changeTargetDBO'){
        //     try{
        //         List<sfsrm__Collection_Forecast__c> forecastList = new List<sfsrm__Collection_Forecast__c>();
        //         system.debug('cashTargetGross>>>>>>>..'+inMap.get('targetGrossDBO'));
        //         Decimal userEntTarDBO = decimal.valueOf((String)inMap.get('targetGrossDBO'));
        //         system.debug('userEntCashTarGross>>>>>>>..'+userEntTarDBO);
        //         Decimal newTarGross = 0;
        //         Decimal totalCashTrgtGross = 0;
        //         Decimal totalTargetDBO = 0;
        //         Decimal finalCashTarget = 0;
        //         forecastList = [Select Id, Name, sfsrm__Cash_Target_Gross__c, sfsrm__Target_Gross_DBO__c, sfsrm__Start_Date__c,sfsrm__Actual_Gross_DBO__c,sfsrm__Actual_Collection__c,sfsrm__Cumulative_Cash_Receipt__c from sfsrm__Collection_Forecast__c order by sfsrm__Start_Date__c desc limit 6];
        //         if(forecastList.size() > 0){
                    
        //             Decimal avgTrgtCashGross=0;
        //             Decimal avgTrgtDBO=0;
        //             if(forecastList.size() > 0) {
        //                 avgTrgtCashGross += forecastList.get(0).sfsrm__Actual_Collection__c / 2;
        //                 avgTrgtDBO += forecastList.get(0).sfsrm__Actual_Gross_DBO__c / 2;
        //             }
        //             if(forecastList.size() > 1) {
        //                 avgTrgtCashGross += forecastList.get(1).sfsrm__Actual_Collection__c / 4;
        //                 avgTrgtDBO += forecastList.get(1).sfsrm__Actual_Gross_DBO__c / 4;
        //             }
        //             if(forecastList.size() > 2) {
        //                 avgTrgtCashGross += forecastList.get(2).sfsrm__Actual_Collection__c / 8;
        //                 avgTrgtDBO += forecastList.get(2).sfsrm__Actual_Gross_DBO__c / 8;
        //             }
        //             if(forecastList.size() > 3) {
        //                 avgTrgtCashGross += forecastList.get(3).sfsrm__Actual_Collection__c / 16;
        //                 avgTrgtDBO += forecastList.get(3).sfsrm__Actual_Gross_DBO__c / 16;
        //             }
        //             if(forecastList.size() > 4) {
        //                 avgTrgtCashGross += forecastList.get(4).sfsrm__Actual_Collection__c / 32;
        //                 avgTrgtDBO += forecastList.get(4).sfsrm__Actual_Gross_DBO__c / 32;
        //             }
        //             if(forecastList.size() > 5) {
        //                 avgTrgtCashGross += forecastList.get(5).sfsrm__Actual_Collection__c / 32;
        //                 avgTrgtDBO += forecastList.get(5).sfsrm__Actual_Gross_DBO__c / 32;
        //             }

        //             // for(sfsrm__Collection_Forecast__c cf : forecastList){
        //             //     totalCashTrgtGross += cf.sfsrm__Cash_Target_Gross__c;
        //             //     totalTargetDBO += cf.sfsrm__Target_Gross_DBO__c;
        //             // }
        //             // Decimal avgTrgtCashGross = totalCashTrgtGross/forecastList.size();
        //             // Decimal avgTrgtDBO = totalTargetDBO/forecastList.size();
        //             if(avgTrgtDBO > 0 && avgTrgtCashGross > 0){
        //                 finalCashTarget = ((avgTrgtDBO*avgTrgtCashGross)/userEntTarDBO).round();
        //             }
        //             inMap.put('cashTargetGross',finalCashTarget);
        //         }
                
        //         Integer systemSuggestedInitialDSO = Integer.valueOf(inMap.get('SystemSuggestedInitialDSO'));
		// 		Decimal newConfidence = 0;
		// 		if(systemSuggestedInitialDSO > 0){
		// 			newConfidence = ((80*userEntTarDBO) / systemSuggestedInitialDSO).round();
		// 		}
        //         if (newConfidence > 100) newConfidence=100;
        //         if (newConfidence < 0) newConfidence=0;

        //         // if(userEntTarDBO >= systemSuggestedInitialDSO){
        //         //     inMap.put('Confidence','<div class="cards slds-m-right_x-small" data-value="test"   style="width:66%;height: 100%;cursor: pointer;position: relative;padding: 0;background: var(--lwc-cardColorBackground,rgb(255, 255, 255));border:var(--lwc-borderWidthThin,1px) solid var(--lwc-cardColorBorder,rgb(221, 219, 218)); border-radius: var(--lwc-borderRadiusMedium,0.25rem); background-clip: padding-box;box-shadow: var(--lwc-cardShadow,0 2px 2px 0 rgba(0, 0, 0, 0.10));" id="myDIV"> <b style="text-align: center;">     <div class="slds-p-around_small" style="font-size: 15px;">          Confidence</div>    </b>    <b style="text-align: center;" >        <div style="color: #00716B;display: block;margin-left: auto;margin-right: auto;font-size: 25px;background: inherit;"  > 100%</div>  </b></div>');
        //         // }else{
        //             String color = '';
                    
        //         //     Decimal newConfidence = ((100*userEntTarDBO) / systemSuggestedInitialDSO).round();
                    
        //         if(newConfidence >= 70){
        //             color = '#00716B';
        //         } else if(newConfidence >= 40 && newConfidence < 70){
        //             color = '#FFB75D';
        //         } else {
        //             color = '#FB453C';
        //         }
        //         System.debug('newConfidence >>> ' + newConfidence);
        //         // newConfidence = newConfidence > 0 ? newConfidence : 0;
        //         inMap.put('Confidence','<div class="cards slds-m-right_x-small" data-value="test"   style="width:66%;height: 100%;cursor: pointer;position: relative;padding: 0;background: var(--lwc-cardColorBackground,rgb(255, 255, 255));border:var(--lwc-borderWidthThin,1px) solid var(--lwc-cardColorBorder,rgb(221, 219, 218)); border-radius: var(--lwc-borderRadiusMedium,0.25rem); background-clip: padding-box;box-shadow: var(--lwc-cardShadow,0 2px 2px 0 rgba(0, 0, 0, 0.10));" id="myDIV"> <b style="text-align: center;">     <div class="slds-p-around_small" style="font-size: 15px;">          Confidence</div>    </b>    <b style="text-align: center;" >        <div style="color: ' + color + ';display: block;margin-left: auto;margin-right: auto;font-size: 25px;background: inherit;"  >' + newConfidence + '%</div>   </b></div>');
        //         // }
                
        //         system.debug('inMap>.......'+inMap);  
        //     } catch(exception e){
        //         system.debug('exception occured on line'+e.getLineNumber() + 'Reason is >>'+e.getMessage());
        //     }
        // }

        return inMap;
    }
	
	
	//Will get month days 
    // public List<Object> setMonthDays(Date startDate, Timezone tz){
    //     Map<String, String> weekMap = new Map<String, String>{'0'=>'Sunday','1'=>'Monday','2'=>'Tuesday','3'=>'Wednesday','4'=>'Thursday','5'=>'Friday','6'=>'Saturday'};
    //     Integer totalDaysOfMonth = ( (startDate).daysBetween((startDate).addMonths(1))) ;
    //     List<Object> setDays = new List<Object>();
    //     for(Integer i = 0 ; i < totalDaysOfMonth; i++){
    //         map<Object,Object> daysMap = new map<Object,Object>();
    //         Date tempDate = startDate.addDays(i);
	// 		/*
    //         system.debug('tempDate>>>>'+tempDate);
    //         Integer offset = tz.getOffset(tempDate)/1000/60;
    //         system.debug('offset>>>>'+offset);
    //         Datetime dt = Datetime.newInstance(tempDate.year(), tempDate.month(), tempDate.day()).addMinutes(-offset) ;
    //         system.debug('dt>>>>'+dt);
    //         Integer dtOffset = tz.getOffset(dt)/1000/60;
    //         system.debug('dtOffset>>>>'+dtOffset);
    //         if (offset != dtOffset) {
    //             dt =  Datetime.newInstance(dt.year(), dt.month(), dt.day()).addMinutes(-dtOffset);
    //             system.debug('dt 1>>>>'+dtOffset);
    //         }*/
	// 		Date dt = tempDate;
    //         String weekDay = weekMap.get(String.valueOf(Math.mod(Date.newInstance(1900, 1, 7).daysBetween(dt),7)));
    //         daysMap.put('Days', tempDate );            
    //         daysMap.put('Weekday', weekDay );
    //         system.debug('daysMap>>>>>>>>'+daysMap);
    //         system.debug('startDate weekDay>>>>'+weekDay);
    //         if(weekDay != 'Sunday' && weekDay != 'Saturday' ){
    //             daysMap.put('isSelected',true);
    //         }
    //         setDays.add(daysMap);
    //     }
    //     return setDays;
    // }
	
	/*
    //Will get month days 
    public List<Object> setMonthDays(Datetime startDate, Timezone tz){
        Integer totalDaysOfMonth = ( (startDate.date()).daysBetween((startDate.date()).addMonths(1)) ) ;
        List<Object> setDays = new List<Object>();
        for(Integer i = 0 ; i < totalDaysOfMonth; i++){
            map<Object,Object> daysMap = new map<Object,Object>();
            Datetime tempDate = startDate.addDays(i);
            system.debug('tempDate>>>>'+tempDate);
            Integer offset = tz.getOffset(tempDate)/1000/60;
            system.debug('offset>>>>'+offset);
            Datetime dt = Datetime.newInstance(tempDate.year(), tempDate.month(), tempDate.day()).addMinutes(-offset) ;
            system.debug('dt>>>>'+dt);
            Integer dtOffset = tz.getOffset(dt)/1000/60;
            system.debug('dtOffset>>>>'+dtOffset);
            if (offset != dtOffset) {
                dt =  Datetime.newInstance(dt.year(), dt.month(), dt.day()).addMinutes(-dtOffset);
                system.debug('dt 1>>>>'+dtOffset);
            }   
            daysMap.put('Days', dt.date() );            
            daysMap.put('Weekday', dt.format('EEEE') );
            system.debug('daysMap>>>>>>>>'+daysMap);
            system.debug('startDate weekDay>>>>'+dt.format('EEEE'));
            if(dt.format('EEEE') != 'Sunday' && dt.format('EEEE') != 'Saturday' ){
                daysMap.put('isSelected',true);
            }
            setDays.add(daysMap);
        }
        return setDays;
    } */
}