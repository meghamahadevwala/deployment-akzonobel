public with sharing class cSRMTreatmentUtility {
    public static Map<String, Object> getBody(cSRMTreatmentMapper.ObjectCriteria treStep, Map<String, Schema.SObjectField> fMap, String childObjAPIName, celsrm__Treatment__c treatment, Boolean updateRecord, Set<Id> childIds, String stepName, Boolean isConsolidated,  Map<String, String> fieldApiVsTranslatedLabel){
		//-- Start | FIN-9543 | Changed by Dhwanil | 06 April 2026 --//
		String attachmentTableFontFamily = 'Arial Unicode MS';
		String attachmentTableFontSize = '10px';
		//-- End | FIN-9543 | Changed by Dhwanil | 06 April 2026 --//

		Map<String, Object> returnMap = new Map<String, Object>();
		List<String> objColumns = treStep.columns;
		List<String> columns = new List<String>();
		String innerHtml= '';
		Map<String, String> columnWithType = new Map<String, String>();
		Map<String, Boolean> customReferenceField = new Map<String, Boolean>();
		// << START - MM - FIN-8279 - Email Attachment -> Totals by currencycode >>
		Map<String, Double> mapCurBalance = new Map<String, Double>();
		Map<String, Double> mapCurBalanceForOverDue = new Map<String, Double>();
		Map<String, Double> mapCurBalanceForOverDueNotNoted = new Map<String, Double>();
		// << END - MM - FIN-8279 - Email Attachment -> Totals by currencycode >>
		if (objColumns != null && objColumns.size() > 0) {
			String query = '';
			for (String col : objColumns){
				String type = fMap.get(col.trim().toLowerCase()).getDescribe().getType().name();	
				Boolean isCustom = false;
				if(type == 'REFERENCE'){
					isCustom = fMap.get(col.trim().toLowerCase()).getDescribe().isCustom();
					customReferenceField.put(col,isCustom);
				}
				columnWithType.put(col, type);
				columns.add(col);
				
				if(type == 'REFERENCE' && isCustom){
					col= col.subString(0,col.length()-1)+ 'r.Name';
					columns.add(col);
				} else if (type == 'REFERENCE' && !isCustom) {
					col= col.subString(0,col.length()-2)+ '.Name';
					columns.add(col);
				}
			}
			if (UserInfo.IsMultiCurrencyOrganization() && columns.indexOf('CurrencyIsoCode') == -1) {
				columns.add('CurrencyIsoCode');
			}
			String fields = String.Join(columns,',');
			if (!fields.contains('celsrm__Treatment_Notes__c')) {
				fields = fields + ',' + 'celsrm__Treatment_Notes__c';
			}
			// << START - MM - FIN-8279 - Email Attachment -> Totals by currencycode >> 
			if(childObjAPIName == 'celsrm__Transaction__c') {
				if(!fields.contains('celsrm__Balance__c')) { 
					fields = fields + ',' + 'celsrm__Balance__c';
				}
				if(!fields.contains('celsrm__DPD__c')) { 
					fields = fields + ',' + 'celsrm__DPD__c';
				}
				if(!fields.contains('Noted__c')) { 
					fields = fields + ',' + 'Noted__c';
				}
			}
			// << END - MM - FIN-8279 - Email Attachment -> Totals by currencycode >> 
			if (columns.contains('Id')) {
				query = 'SELECT ' + String.escapeSingleQuotes(fields) + ' FROM ' + String.escapeSingleQuotes(childObjAPIName) + ' WHERE ID =:childIds ';
			} else {
				query = 'SELECT Id,' + String.escapeSingleQuotes(fields) + ' FROM ' + String.escapeSingleQuotes(childObjAPIName) + ' WHERE ID =:childIds ';
			}
			if (treStep.sortField != null && treStep.sortField != '') {
				query += ' order by '  + String.escapeSingleQuotes(treStep.sortField);
				if (treStep.sortDirection != null && treStep.sortDirection != '') {
					query += ' ' + String.escapeSingleQuotes(treStep.sortDirection);
				}
			}
			List<SObject> childObjRecord = Database.query(query);
			Integer j=0;
			//-- Start | FIN-8048 | Changed by Ravi | 30 July 2025 --//
			//-- Start | FIN-8666 | Changed By Dhwanil | 25 Nov 2025 --//
			//innerHtml = '<html><head><meta http-equiv="Content-type" content="text/html;charset=UTF-8"></head><body>';
			//-- End | FIN-8666 | Changed By Dhwanil | 25 Nov 2025 --//
			//-- Start | FIN-9543 | Changed by Dhwanil | 06 April 2026 --//
			innerHtml += '<table width="100%" class="billing" style="border-collapse:collapse;padding:0px;font-family:'+attachmentTableFontFamily+';font-size:'+attachmentTableFontSize+';">';
			//-- End | FIN-9543 | Changed by Dhwanil | 06 April 2026 --//
			//-- End | FIN-8048 | Changed by Ravi | 30 July 2025 --//
			// Start | FIN-8208| Changed by Asera | 17 April 2026 --// - Dynamic translated headers based account local
			List<String> fieldType = new List<String>();
				for (String col : objColumns) {
					String key = col.trim().toLowerCase();
					if (fieldApiVsTranslatedLabel != null && !fieldApiVsTranslatedLabel.isEmpty() && fieldApiVsTranslatedLabel.containsKey(key)) {
						fieldType.add(fieldApiVsTranslatedLabel.get(key));
					} else {
					Schema.SObjectField sf = fMap.get(key);
						fieldType.add(sf != null ? sf.getDescribe().getLabel() : col);
					}
				}
				//-- Start | FIN-9975 | Changed by Dhwanil | 02-Jul-2026 --// - Calculate treatment Excel column widths from header and cell values
				Map<String, Integer> excelColumnWidthByField = new Map<String, Integer>();
				for (Integer hi = 0; hi < objColumns.size(); hi++) {
					String apiField = objColumns[hi];
					String displayHeader = (fieldType != null && hi < fieldType.size()) ? fieldType[hi] : apiField;
					Integer maxColumnLength = String.isNotBlank(displayHeader) ? displayHeader.length() : 0;
					for (SObject widthRecord : childObjRecord) {
						String cellDisplayValue = getTreatmentFieldDisplayValue(widthRecord, apiField, columnWithType, customReferenceField);
						maxColumnLength = Math.max(maxColumnLength, String.isNotBlank(cellDisplayValue) ? cellDisplayValue.length() : 0);
					}
					excelColumnWidthByField.put(apiField, getExcelColumnPixelWidth(maxColumnLength));
				}
				//-- End | FIN-9975 | Changed by Dhwanil | 02-Jul-2026 --// - Calculate treatment Excel column widths from header and cell values
				//-- Start | FIN-9975 | Changed by Dhwanil | 02-Jul-2026 --// - Apply widths at the Excel column level so Invoice# sizing is respected
				innerHtml += '<colgroup>';
				for (String apiField : objColumns) {
					Integer columnWidth = excelColumnWidthByField.get(apiField);
					innerHtml += '<col width="' + columnWidth + '" style="' + getExcelColumnWidthStyle(columnWidth) + 'mso-width-source:userset;" />';
				}
				innerHtml += '</colgroup>';
				//-- End | FIN-9975 | Changed by Dhwanil | 02-Jul-2026 --// - Apply widths at the Excel column level so Invoice# sizing is respected
			innerHtml += '<tr>';
			for (Integer hi = 0; hi < objColumns.size(); hi++) {
				String apiField = objColumns[hi];
				String displayHeader = (fieldType != null && hi < fieldType.size()) ? fieldType[hi] : apiField;
				String colType = columnWithType.get(apiField);
				String excelWidthStyle = getExcelColumnWidthStyle(excelColumnWidthByField.get(apiField));
				if (colType == 'CURRENCY' || colType == 'NUMBER' || colType == 'DOUBLE' || colType == 'PERCENT') {
					//-- Start | FIN-8048 | Changed by Ravi | 30 July 2025 --//
					innerHtml += '<th width="' + excelColumnWidthByField.get(apiField) + '" style="' + excelWidthStyle + 'mso-width-source:userset;white-space:nowrap;border:1px solid gray;text-align:right;background-color: black;color: white;">'+ displayHeader +'</th>';
					//-- End | FIN-8048 | Changed by Ravi | 30 July 2025 --//
				} else {
					//-- Start | FIN-8048 | Changed by Ravi | 30 July 2025 --//
					innerHtml += '<th width="' + excelColumnWidthByField.get(apiField) + '" style="' + excelWidthStyle + 'mso-width-source:userset;white-space:nowrap;border:1px solid gray;text-align:left;background-color: black;color: white;">'+ displayHeader +'</th>';
					//-- End | FIN-8048 | Changed by Ravi | 30 July 2025 --//
				}
			}
			//-- End |FIN-8208| Changed by Asera | 17 April 2026 --// - Dynamic translated headers based account local
			innerHtml += '</tr>';
			Object fieldvalue;
			Map<String,Double> totalMap = new Map<String,Double>();
			Double total = 0;
			String aggregationField = '';
			String totalTitle = '';
			if(treStep.calculateTotal && treStep.aggregationField != null){
				aggregationField = treStep.aggregationField;
				if(treStep.totalTitle != null){
					totalTitle = treStep.totalTitle;
				}
			}
			Map<Id,Sobject> childMap = new Map<Id,Sobject>();
			// << START - MM - FIN-9497 - Task -> Send Email -> PIP subtotal calculation >> 
			Decimal subTotal = 0.0;
			String previousClearingDoc = null;
			String totalCurrencyCode = '';
			// << END - MM - FIN-9497 - Task -> Send Email -> PIP subtotal calculation >> 
			for (SObject val : childObjRecord) {
				if(updateRecord){
					Schema.SObjectType token =((Id)val.get('Id')).getSObjectType();
					Sobject child = token.newSobject();
					child.put('Id', (Id)val.get('Id'));
					child.put('celsrm__Treatment_Notes__c', treatment.get('Name') + ' - ' + stepName + '\n' + 'Auto contact by system.' + '\n' + UserInfo.getName() +':'+ date.today().month()+'/'+date.today().day() + '/'+ date.today().year() + '\n\n' + (val.get('celsrm__Treatment_Notes__c') != null && val.get('celsrm__Treatment_Notes__c') != '' ? String.valueOf(val.get('celsrm__Treatment_Notes__c')) : ''));
					child.put('celsrm__Last_Dunning_Date__c', date.today());
					child.put('celsrm__Last_Treatment__c', treatment.Id);
					childMap.put((Id)val.get('Id'), child);
				}
				// << START - MM - FIN-8279 - Email Attachment -> Totals by currencycode >>
				if(childObjAPIName == 'celsrm__Transaction__c') {
					String recCurrencyIsoCode = (String) val.get('CurrencyIsoCode');
					Double recBalance = (Double)val.get('celsrm__Balance__c');
					Decimal recDPD = (Decimal)val.get('celsrm__DPD__c');
					String recNoted = (String)val.get('Noted__c');

					if(recCurrencyIsoCode!=null && recBalance!=null){
						if(!mapCurBalance.containsKey(recCurrencyIsoCode)) {
							mapCurBalance.put(recCurrencyIsoCode, 0.0);
						}
						if(!mapCurBalanceForOverDue.containsKey(recCurrencyIsoCode)) {
							mapCurBalanceForOverDue.put(recCurrencyIsoCode, 0.0);
						}
						if(!mapCurBalanceForOverDueNotNoted.containsKey(recCurrencyIsoCode)) {
							mapCurBalanceForOverDueNotNoted.put(recCurrencyIsoCode, 0.0);
						}
						mapCurBalance.put(recCurrencyIsoCode, (Double)mapCurBalance.get(recCurrencyIsoCode) != null ? (Double)mapCurBalance.get(recCurrencyIsoCode) + recBalance : recBalance);
						if(recDPD != null && recDPD > 0) {
							mapCurBalanceForOverDue.put(recCurrencyIsoCode, (Double)mapCurBalanceForOverDue.get(recCurrencyIsoCode) != null ? (Double)mapCurBalanceForOverDue.get(recCurrencyIsoCode) + recBalance : recBalance);
							if(recNoted == null || recNoted == '') {
								mapCurBalanceForOverDueNotNoted.put(recCurrencyIsoCode, (Double)mapCurBalanceForOverDueNotNoted.get(recCurrencyIsoCode) != null ? (Double)mapCurBalanceForOverDueNotNoted.get(recCurrencyIsoCode) + recBalance : recBalance);
							}
						}
					}
					
				}
				// << END - MM - FIN-8279 - Email Attachment -> Totals by currencycode >>
				j=j+1;
				// << START - MM - FIN-9497 - Task -> Send Email -> PIP subtotal calculation >> 
				if(treStep.stepName == 'PaymentInProgress') {
					String currentClearingDoc = (String)val.get('celsrm__Clearing_Document__c');
					if(previousClearingDoc != null && currentClearingDoc != previousClearingDoc) {
						innerHtml += '<tr>';
						for (String field : objColumns) {
							String style = 'border:1px solid #000; padding:4px; font-weight: bold;';
							String align = 'right';
							if (field == aggregationField) {
								style += 'text-align:${align};';
								innerHtml += '<td width="auto" style="text-align:right;border:solid 0.5px gray;white-space:nowrap; font-weight: bold;">' + subTotal + '</td>';
							} else if(field == 'CurrencyIsoCode') {
								align = 'left';
								style += 'text-align:${align};';
								innerHtml += '<td width="auto" style="text-align:left;border:solid 0.5px gray;white-space:nowrap; font-weight: bold;">' + totalCurrencyCode + '</td>';
							} else {
								innerHtml += '<td width="auto" style="text-align:right;border:solid 0.5px gray;white-space:nowrap; font-weight: bold;"></td>';
							}
						}
						innerHtml += '</tr>';
						subTotal = val.get(aggregationField) != null ? (Decimal)(val.get(aggregationField)) : 0;
						totalCurrencyCode = val.get('CurrencyIsoCode') != null ? (String)val.get('CurrencyIsoCode') : '';
					} else {
						subTotal += val.get(aggregationField) != null ? (Decimal)(val.get(aggregationField)) : 0;
						totalCurrencyCode = val.get('CurrencyIsoCode') != null ? (String)val.get('CurrencyIsoCode') : '';
					}
					previousClearingDoc = currentClearingDoc;
				}
				// << END - MM - FIN-9497 - Task -> Send Email -> PIP subtotal calculation >> 
				innerHtml += '<tr>';
				for (String field : objColumns) {
					String excelWidthStyle = getExcelColumnWidthStyle(excelColumnWidthByField.get(field));
					if (columnWithType.get(field) == 'REFERENCE') {
						String tempfield = '';
						if (customReferenceField.get(field)) {
							tempfield= field.subString(0,field.length()-1)+ 'r';
						} else {
							tempfield= field.subString(0,field.length()-2);
						}
						Sobject tempvalue = val.getSobject(tempfield);
						if (tempvalue != null) {
							fieldvalue = tempvalue.get('Name');
						} else {
							fieldvalue = '';
						}
					} else if (columnWithType.get(field) == 'CURRENCY'){
						if(val.get(field) != null){
							Double dtTemp = (Double)val.get(field);
							String currencyIsoCode = ( String )(UserInfo.IsMultiCurrencyOrganization() ? val.get('CurrencyIsoCode') : UserInfo.getDefaultCurrency());           
							fieldvalue =cSRMTreatmentUtility.formatDoubleValue(currencyIsoCode ,dtTemp );
						}else{
							fieldvalue = '';
						}
					} else if (columnWithType.get(field) == 'DATE') {
						if (val.get(field) != null) {
							Date tempval = (Date)val.get(field);
							fieldvalue = tempval.format();
						} else {
							fieldvalue = '';
						}
					} else if (columnWithType.get(field) == 'DATETIME') {
						if (val.get(field) != null) {
							Datetime tempval = (Datetime)val.get(field);
							fieldvalue = tempval.format();
						} else {
							fieldvalue = '';
						}
					} else if (columnWithType.get(field) == 'NUMBER' || columnWithType.get(field) == 'DOUBLE'){
						Double dtTemp = (Double)val.get(field);
						//-- Start | FIN-8949 | Changed By Dhwanil | 30 Jan 2026 --//
						fieldvalue = cSRMTreatmentUtility.formatAsNumber(dtTemp);
						//-- End | FIN-8949 | Changed By Dhwanil | 30 Jan 2026 --//
					} else{
						fieldvalue = val.get(field);
						if(fieldvalue == null){
							fieldvalue = '';
						}
					}
					if (aggregationField != '' &&  aggregationField == field && val.get(field) != null) {
						if (columnWithType.get(field) == 'CURRENCY') {
							Double dtTemp = (Double)val.get(field);
							String currencyIsoCode = ( String )(UserInfo.IsMultiCurrencyOrganization() ? val.get('CurrencyIsoCode') : UserInfo.getDefaultCurrency());           
							if (totalMap.get(currencyIsoCode) != null) {
								Double finalValue = totalMap.get(currencyIsoCode) + dtTemp;
								totalMap.put(currencyIsoCode, finalValue);
							} else {
								totalMap.put(currencyIsoCode, dtTemp);
							}
						} else {
							total = total + (Double)val.get(field);
						}
					}
					if (columnWithType.get(field) == 'CURRENCY' || columnWithType.get(field) == 'NUMBER' || columnWithType.get(field) == 'DOUBLE' || columnWithType.get(field) == 'PERCENT') {
						//-- Start | FIN-8048 | Changed by Ravi | 30 July 2025 --//
						innerHtml += '<td width="' + excelColumnWidthByField.get(field) + '" style="' + excelWidthStyle + 'mso-width-source:userset;mso-number-format:&quot;\\@&quot;;text-align:right;border:solid 0.5px gray;white-space:nowrap;">'+ fieldvalue+'</td>';
						//-- End | FIN-8048 | Changed by Ravi | 30 July 2025 --//
					} else {
						//-- Start | FIN-8048 | Changed by Ravi | 30 July 2025 --//
						innerHtml += '<td width="' + excelColumnWidthByField.get(field) + '" style="' + excelWidthStyle + 'mso-width-source:userset;mso-number-format:&quot;\\@&quot;;text-align:left;border:solid 0.5px gray;white-space:nowrap;">'+ fieldvalue+'</td>';
						//-- End | FIN-8048 | Changed by Ravi | 30 July 2025 --//
					}
					
				}
				innerHtml += '</tr>';
			}
			// << START - MM - FIN-9497 - Task -> Send Email -> PIP subtotal calculation >> 
			if(treStep.stepName == 'PaymentInProgress') {
				innerHtml += '<tr>';
				for (String field : objColumns) {
					String style = 'border:1px solid #000; padding:4px; font-weight: bold;';
					String align = 'right';
					if (field == aggregationField) {
						style += 'text-align:${align};';
						innerHtml += '<td width="auto" style="text-align:right;border:solid 0.5px gray;white-space:nowrap; font-weight: bold;">' + subTotal + '</td>';
					} else if(field == 'CurrencyIsoCode') {
						align = 'left';
						style += 'text-align:${align};';
						innerHtml += '<td width="auto" style="text-align:left;border:solid 0.5px gray;white-space:nowrap; font-weight: bold;">' + totalCurrencyCode + '</td>';
					} else {
						innerHtml += '<td width="auto" style="text-align:right;border:solid 0.5px gray;white-space:nowrap; font-weight: bold;"></td>';
					}
				}
				subTotal = 0.0;
				innerHtml += '</tr>';
			}
			// << END - MM - FIN-9497 - Task -> Send Email -> PIP subtotal calculation >> 
			innerHtml += '</table><br>';
			if (aggregationField != '' && (Boolean)treStep.showTotal) {
				String totalHtml = '';
				if (total > 0) {
					String doubleVal = cSRMTreatmentUtility.formatAsCurrency(total);
					innerHtml += '<span style="float:right;white-space:nowrap;">' + totalTitle + ' ' + doubleVal + '</span>';
					totalHtml = ''+ total;
				} else {
					if (totalMap.keySet().size() > 0) {
						//-- Start | FIN-9543 | Changed by Dhwanil | 06 April 2026 --//
						innerHtml += '<span style="float:right;white-space:nowrap;font-family:'+attachmentTableFontFamily+';font-size:'+attachmentTableFontSize+';">' + totalTitle + ' ';
						//-- End | FIN-9543 | Changed by Dhwanil | 06 April 2026 --//
						for (String code : totalMap.keySet()) {
							innerHtml += cSRMTreatmentUtility.formatDoubleValue(code ,totalMap.get(code) ) + ', ';
							totalHtml += cSRMTreatmentUtility.formatDoubleValue(code ,totalMap.get(code) ) + ', ';
						}
						totalHtml = totalHtml.removeEnd(', ');
						innerHtml = innerHtml.removeEnd(', ') + '</span>';
					} else {
						totalHtml = '0.0';
						//-- Start | FIN-9543 | Changed by Dhwanil | 06 April 2026 --//
						innerHtml += '<span style="float:right;white-space:nowrap;font-family:'+attachmentTableFontFamily+';font-size:'+attachmentTableFontSize+';">' + totalTitle + ' 0.0' + '</span>';
						//-- End | FIN-9543 | Changed by Dhwanil | 06 April 2026 --//
					}
				}
				returnMap.put('totalHtml',totalHtml);
			} else if(isConsolidated == true){
				String totalHtml = '';
				if (total > 0) {
					String doubleVal = cSRMTreatmentUtility.formatAsCurrency(total);
					totalHtml = ''+ doubleVal;
				} else {
					if (totalMap.keySet().size() > 0) {
						for (String code : totalMap.keySet()) {
							totalHtml += cSRMTreatmentUtility.formatDoubleValue(code ,totalMap.get(code) ) + ', ';
						}
						totalHtml = totalHtml.removeEnd(', ');
					} else {
						totalHtml = '0.0';
					}
				}
				returnMap.put('totalHtml',totalHtml);
			}
			//-- Start | FIN-8666 | Changed By Dhwanil | 25 Nov 2025 --//
			//innerHtml += '<br></body></html>';
			innerHtml += '<br>';
			//-- End | FIN-8666 | Changed By Dhwanil | 25 Nov 2025 --//
			returnMap.put('childMap',childMap);
		}
		returnMap.put('innerHtml',innerHtml);

		// << START - MM - FIN-8279 - Email Attachment -> Totals by currencycode >>
		System.debug('TotalOpenItems::' + mapCurBalance);
		System.debug('TotalOverdueItems::' + mapCurBalanceForOverDue);
		System.debug('openItemsForOverDueNotNotedTotal::' + mapCurBalanceForOverDueNotNoted);
		returnMap.put('TotalOpenItems', mapCurBalance);
		returnMap.put('TotalOverdueItems', mapCurBalanceForOverDue);
		returnMap.put('TotalOverdueNotNotedItems', mapCurBalanceForOverDueNotNoted);
		// << END - MM - FIN-8279 - Email Attachment -> Totals by currencycode >>
		return returnMap;
	}

    public static String formatDoubleValue(String currencyCode, Double d) {
        String formattedCurrencyStr;
         String doubleVal = formatAsCurrency(d);
        // String doubleVal = Decimal.valueOf(d).setScale(2).format();
        System.debug('doubleValue>>> ' + doubleVal);
        // if(currencyCode!=null && currencyCode!=''){
        celsrm__CurrencyCode_Symbols__c currencyCodesettings = celsrm__CurrencyCode_Symbols__c.getInstance(currencyCode);
        
        //String doubleVal =  Decimal.valueOf(d).setScale(2).toPlainString();
        
        if(currencyCodesettings!=null && currencyCodesettings.celsrm__Currency_Symbol__c!=null  ){
            formattedCurrencyStr = currencyCodesettings.celsrm__Currency_Symbol__c + ' ' + doubleVal;
        }
        // }  
        else{
            formattedCurrencyStr = '$' + ' ' +doubleVal;
        }
        return formattedCurrencyStr;
    }

    public static String formatAsCurrency(Double amount) {
        
        String userLocale = UserInfo.getLocale();
        if(amount!=null)
        {   
            if ( 'de_DE_EURO'.equalsIgnoreCase(userLocale) || 'de'.equalsIgnoreCase(userLocale) || 'pt_BR'.equalsIgnoreCase(userLocale) || 'de_DE'.equalsIgnoreCase(userLocale)){
                //Convert String to Decimal
                Decimal currencyindec = Decimal.valueof(amount);
                //Convert String to Integer
                Long curdecint = currencyindec.longValue();
                //Get value after PRECISION
                decimal cents = currencyindec - currencyindec.longValue();
                //Set scale 2
                cents = cents.setScale(2);                
                if(cents.toPlainString().startsWith('-')){
                    return  curdecint.format() + ',' + cents.toPlainString().substring(3);
                }else
                    return  curdecint.format() + ',' + cents.toPlainString().substring(2);
            } else {
                //Convert String to Decimal
                Decimal currencyindec = Decimal.valueof(amount);
                //Convert String to Integer
                Long curdecint = currencyindec.longValue();
                //Get value after PRECISION
                decimal cents = currencyindec - currencyindec.longValue();
                cents = cents.setScale(2);
                if(curdecint == 0 ){
                    return cents.toPlainString().substring(0);
                }
                if(cents.toPlainString().startsWith('-0.')){
                    return curdecint.format() + cents.toPlainString().substring(2);
                }else{
                    return curdecint.format() + cents.toPlainString().substring(1);
                }
            }
        }
        return null;
    }

	// << START - MM - FIN-9455 - Mass Dunning -> Replace custom placeholders and translations >> 
	//-- FIN-8983 | Changed by Dilshad | 28-Jan-2026 | Start --//
	public static Map<String, String> getAttachmentDetails(String attachmentType, celsrm__Treatment__c treatment, Task tsk, String accountId, String jsonFileName, String treatmentStage) {
		Map<String, String> attachmentDetails = new Map<String, String>();
		String templateBody = '';
		String attachmentBody = '';
		String fileName = '';
		//-- Start | FIN-8208| Changed by Asera | 17 April 2026 --// - Dynamic translated headers based account local
		String accountLocal = 'EN';
		if (String.isNotBlank(accountId)) {
			List<Account> accountsForLocale = [SELECT Id, celsrm__Locale__c FROM Account WHERE Id = :accountId LIMIT 1];
			if (!accountsForLocale.isEmpty()) {
				accountLocal = accountsForLocale[0].celsrm__Locale__c != null ? accountsForLocale[0].celsrm__Locale__c : 'EN';
			}
		}
		//-- End | FIN-8208| Changed by Asera | 17 April 2026 --// - Dynamic translated headers based account local
		// Fetch Email Template for attachment
		EmailTemplate emailTemplate = getEmailTemplateForAttachment(attachmentType, treatment, tsk, accountId);
		if(emailTemplate != null) {
			// Fetch Contact for Email Template
			List<Contact> contacts = new List<Contact>();
            try {
                contacts = [SELECT Id FROM Contact WHERE celsrm__Default__c=true AND accountId = :accountId WITH SECURITY_ENFORCED];
                if (contacts == null || contacts.size() == 0) {
                    contacts = [SELECT Id FROM Contact WHERE accountId=:accountId WITH SECURITY_ENFORCED];
                }
            } catch (Exception e) {
                System.debug(e.getMessage());
            }
            
            Id contactId = null;
            if(contacts != null && contacts.size() > 0){
                contactId = contacts.get(0).Id;
            }
			// Render Email Template
            Messaging.SingleEmailMessage message = Messaging.renderStoredEmailTemplate(emailTemplate.Id, contactId, accountId);
            // Update template body
            templateBody = message.getHtmlBody();
            // Remove Total Balance from template body
            templateBody = templateBody.remove('<strong>Total :&nbsp;&nbsp; </strong>{Transactions.TotalBalance}');
			
			// fetch transaction data and create table to be inserted in attachment body
			String stepsData = celsrm.SRMTreatmentUtility.readTreatmentDetailsFile(tsk.Id,jsonFileName);
			if (stepsData != '') {
				String tableBody = '';
                if (treatment != null) {
                    String childObjAPIName = treatment.celsrm__Related_Object__c;
                    Map<string, Schema.sObjectType> describeInfo = Schema.getGlobalDescribe();
                    Map<String, Schema.SObjectField> fMap = describeInfo.get(childObjAPIName.toLowerCase()).getDescribe().Fields.getMap();
					Map<String, String> fieldApiVsTranslatedLabel = celsrm.SRMUtilityController.getTranslatedLabelMapForObject(accountLocal, childObjAPIName); //-- FIN-8208| Changed by Asera | 17 April 2026 --// - Dynamic translated headers based account local
                    List<cSRMTreatmentMapper.ObjectCriteria> treatmentSteps = (List<cSRMTreatmentMapper.ObjectCriteria>)JSON.deserialize(treatment.celsrm__Treatment_Steps__c, List<cSRMTreatmentMapper.ObjectCriteria>.class);
                    Map<String, Object> mapStepsDataObj =  (Map<String, Object>) JSON.deserializeUntyped(stepsData);
                    
                    if (treatment.celsrm__Seperate_Task_For_Step__c || treatment.celsrm__Consolidated_Treatment__c) {
                        Set<Id> childIds = new Set<Id>();
                        for(String mapStepsDataKey : mapStepsDataObj.keySet()){
                            for (Object ids : (List<Object>) mapStepsDataObj.get(mapStepsDataKey)) {
                                childIds.add((Id)ids);
                            }
                        }
                        if (childIds != null && childIds.size() > 0) {
                            Double TotalBalance = 0;
                            List<String> columnsNameList = new List<String>();
                            List<String> TempSelFlds= new List<String>();
                            for (cSRMTreatmentMapper.ObjectCriteria treStep: treatmentSteps) {
                                if (treatmentStage == treStep.stepName) {
                                    fileName = treStep.attachmentName;
                                    Map<String, Object> returnBodyMap = getBody(treStep, fMap, childObjAPIName, treatment, false, childIds, treStep.stepName, true, fieldApiVsTranslatedLabel); // FIN-8208| Changed by Asera | 17 April 2026 --// - Dynamic translated headers based account local
                                    String htmlBody = returnBodyMap.get('innerHtml') != null ? (String)returnBodyMap.get('innerHtml') : '';
                                    attachmentBody = templateBody.replace('{Transaction.Summary}', htmlBody);
									// << START - MM - FIN-9455 - Mass Dunning -> Replace custom placeholders and translations >> 
									Map<String, Double> TotalOpenItems = returnBodyMap.get('TotalOpenItems') != null ? (Map<String, Double>)returnBodyMap.get('TotalOpenItems'): new Map<String, Double>();
                                    Map<String, Double> TotalOverdueItems = returnBodyMap.get('TotalOverdueItems') != null ? (Map<String, Double>)returnBodyMap.get('TotalOverdueItems'): new Map<String, Double>();
                                    Map<String, Double> TotalOverdueNotNotedItems = returnBodyMap.get('TotalOverdueNotNotedItems') != null ? (Map<String, Double>)returnBodyMap.get('TotalOverdueNotNotedItems'): new Map<String, Double>();
									Map<String, String> returnMap = fetchAgreegatedAmount(TotalOpenItems, TotalOverdueItems, TotalOverdueNotNotedItems);
                                    attachmentBody = attachmentBody.replace('{Transactions.TotalOpenItems}', returnMap.get('TotalOpenItems'));
                                    attachmentBody = attachmentBody.replace('{Transactions.TotalOverdueItems}', returnMap.get('TotalOverdueItems'));
                                    attachmentBody = attachmentBody.replace('{Transactions.TotalOverdueNotNotedItems}', returnMap.get('TotalOverdueNotNotedItems'));
									attachmentBody = UtilityController.replaceCustomerSpecificPlaceholders(attachmentBody, accountLocal);
									// << END - MM - FIN-9455 - Mass Dunning -> Replace custom placeholders and translations >> 
                                }
                            }
                        }
                    
                    } else if(!treatment.celsrm__Consolidated_Treatment__c) {
                        tableBody = '';
                        fileName = treatment.celsrm__Attachment_Name__c;
                        for (cSRMTreatmentMapper.ObjectCriteria treStep: treatmentSteps) {
                            String stepName = treStep.stepName != null ? String.valueOf(treStep.stepName) : '';
                            if(mapStepsDataObj.containsKey(String.valueOf(treStep.stepName))){
                                List<Object> objChildIds = (List<Object>) mapStepsDataObj.get(String.valueOf(treStep.stepName));
                                Set<Id> childId = new Set<Id>();
                                if (objChildIds != null && objChildIds.size() > 0) {
                                    for(Object a: objChildIds){
                                        childId.add(String.valueOf(a));
                                    }
                                }
                                if (childId != null && childId.size() > 0) {
                                    Map<String, Object> returnBodyMap = getBody(treStep, fMap, childObjAPIName, treatment, false, childId, stepName, false, fieldApiVsTranslatedLabel); //-- Start | FIN-8208| Changed by Asera | 17 April 2026 --// - Dynamic translated headers based account local
                                    String htmlBody = returnBodyMap.get('innerHtml') != null ? (String)returnBodyMap.get('innerHtml') : '';
                                    tableBody += htmlBody;
									// << START - MM - FIN-9483 - [Attachment] [Non Consolidated Treatment] StepName.Transaction.Summary should work >>
									templateBody = templateBody.replace('{' + stepName + '.Transaction.Summary}', htmlBody);
									// << END - MM - FIN-9483 - [Attachment] [Non Consolidated Treatment] StepName.Transaction.Summary should work >>
									// << START - MM - FIN-9616 - [Akzonobel] [Collection] Switch to VF Page from JS Code >> 
									templateBody = templateBody.replaceAll(
										'(?i)font-family\\s*:\\s*[^;]*\\s*;',
										'font-family: Arial Unicode MS;'
									);
									// << END - MM - FIN-9616 - [Akzonobel] [Collection] Switch to VF Page from JS Code >> 
									// << START - MM - FIN-9455 - Mass Dunning -> Replace custom placeholders and translations >> 
									Map<String, Double> TotalOpenItems = returnBodyMap.get('TotalOpenItems') != null ? (Map<String, Double>)returnBodyMap.get('TotalOpenItems'): new Map<String, Double>();
                                    Map<String, Double> TotalOverdueItems = returnBodyMap.get('TotalOverdueItems') != null ? (Map<String, Double>)returnBodyMap.get('TotalOverdueItems'): new Map<String, Double>();
                                    Map<String, Double> TotalOverdueNotNotedItems = returnBodyMap.get('TotalOverdueNotNotedItems') != null ? (Map<String, Double>)returnBodyMap.get('TotalOverdueNotNotedItems'): new Map<String, Double>();
									Map<String, String> returnMap = fetchAgreegatedAmount(TotalOpenItems, TotalOverdueItems, TotalOverdueNotNotedItems);
                                    templateBody = templateBody.replace('{' + stepName + '.Transactions.TotalOpenItems}', returnMap.get('TotalOpenItems'));
                                    templateBody = templateBody.replace('{' + stepName + '.Transactions.TotalOverdueItems}', returnMap.get('TotalOverdueItems'));
                                    templateBody = templateBody.replace('{' + stepName + '.Transactions.TotalOverdueNotNotedItems}', returnMap.get('TotalOverdueNotNotedItems'));
									// << END - MM - FIN-9455 - Mass Dunning -> Replace custom placeholders and translations >> 
                                }
                            }
                        }
						// START - MM - stepName.Transaction.Summary
						if(templateBody != null && templateBody != '') {
							attachmentBody = templateBody;
						} else {
							tableBody = tableBody.removeEnd('<br><br>');
							attachmentBody = tableBody;
						}
						// tableBody = tableBody.removeEnd('<br><br>');
                        // attachmentBody = templateBody.replace('{Transaction.Summary}', tableBody);
						// END - MM - stepName.Transaction.Summary
						// << START - MM - FIN-9455 - Mass Dunning -> Replace custom placeholders and translations >> 
						attachmentBody = UtilityController.replaceCustomerSpecificPlaceholders(attachmentBody, accountLocal);
						System.debug(attachmentBody);
						// << END - MM - FIN-9455 - Mass Dunning -> Replace custom placeholders and translations >> 
                    }
                }
            }
		}
		//-- Start | FIN-9975 | Changed by Dhwanil | 02-Jul-2026 --// - Apply Excel-safe table sizing and text formatting for manual dunning attachments
		if (String.isNotBlank(attachmentType) && attachmentType.equalsIgnoreCase('Excel')) {
			attachmentBody = applyExcelCellSizing(attachmentBody);
		}
		//-- End | FIN-9975 | Changed by Dhwanil | 02-Jul-2026 --// - Apply Excel-safe table sizing and text formatting for manual dunning attachments
		attachmentDetails.put('body', attachmentBody);
		attachmentDetails.put('fileName', fileName);
		return attachmentDetails;
	}
	public static EmailTemplate getEmailTemplateForAttachment(String attachmentType, celsrm__Treatment__c treatment, Task tsk, String accountId) {
		List<EmailTemplate> em = new List<EmailTemplate>();
		String folderName = treatment.celsrm__Attachment_Template_Folder__c;
        String attachmentTemplateName = treatment.celsrm__Attachment_Template_Name__c;
        String attachmentTemplateFolderReferenceField = treatment.celsrm__Attachment_Template_Folder_Ref_Field__c;
		if(treatment.celsrm__Seperate_Task_For_Step__c) {
			List<cSRMTreatmentMapper.ObjectCriteria> treatmentSteps = (List<cSRMTreatmentMapper.ObjectCriteria>)JSON.deserialize(treatment.celsrm__Treatment_Steps__c, List<cSRMTreatmentMapper.ObjectCriteria>.class);
			for(cSRMTreatmentMapper.ObjectCriteria treatmentStep : treatmentSteps) {
				if (tsk.Subject == treatmentStep.taskSubject && tsk.celsrm__Treatment_Stage__c == treatmentStep.stepName) {
					folderName = treatmentStep.attachmentTemplateFolder;
					attachmentTemplateName = treatmentStep.attachmentTemplate;
					attachmentTemplateFolderReferenceField = treatmentStep.attachmentTemplateFolderReferenceField;
				}
			}
		}
		// if reference field of account object is available to get folder name
		if(attachmentTemplateFolderReferenceField != null && attachmentTemplateFolderReferenceField != '' && attachmentTemplateName != null && attachmentTemplateName != '') {
			String queryString = 'SELECT ' +  String.escapeSingleQuotes(attachmentTemplateFolderReferenceField) + ' FROM Account WHERE Id=:accountId';
			System.debug('query>> ' + queryString);
			List<Account> accList = Database.query(queryString);
			if (!accList.isEmpty() && accList.size() > 0) {
				folderName = (String)accList.get(0).get(attachmentTemplateFolderReferenceField);
				if (folderName != null && folderName != '') {
					em = [SELECT Id FROM EmailTemplate WHERE Folder.Name = :folderName AND Name = :attachmentTemplateName AND IsActive = TRUE WITH SECURITY_ENFORCED LIMIT 1];
					if (em.isEmpty() || em.size() == 0) {
						System.debug('Error: Template not found in folder ' + folderName + ' with name ' + attachmentTemplateName);
						em = [SELECT Id FROM EmailTemplate WHERE Name = :attachmentTemplateName AND IsActive = TRUE WITH SECURITY_ENFORCED LIMIT 1];
					}
				} else {
					System.debug('Error: Template folder name is invalid ');
					em = [SELECT Id FROM EmailTemplate WHERE Name = :attachmentTemplateName AND IsActive = TRUE WITH SECURITY_ENFORCED LIMIT 1];
				}
			}
		} else if(folderName != null && folderName != '' && attachmentTemplateName != null && attachmentTemplateName != ''){
			em = [SELECT Id FROM EmailTemplate WHERE Folder.Name = :folderName AND Name = :attachmentTemplateName AND IsActive = TRUE WITH SECURITY_ENFORCED LIMIT 1];
			if (em.isEmpty() || em.size() == 0) {
				System.debug('Error: Template not found in folder ' + folderName + ' with name ' + attachmentTemplateName);
				em = [SELECT Id FROM EmailTemplate WHERE Name = :attachmentTemplateName AND IsActive = TRUE WITH SECURITY_ENFORCED LIMIT 1];
			}
		} else if (treatment.celsrm__Enable_Dynamic_Template__c && treatment.celsrm__Template_Folder_Reference_Field__c != null && treatment.celsrm__Template_Folder_Reference_Field__c != '') { 
			//-- backward compatibility for old configuration --//
			attachmentTemplateName = attachmentType == 'Excel' ? 'System_TreatmentExcelAttachment' : 'System_BillingStatementPDF';
			String queryString = 'SELECT ' +  String.escapeSingleQuotes(treatment.celsrm__Template_Folder_Reference_Field__c) + ' FROM Account WHERE Id=:accountId';
			System.debug('query>> ' + queryString);
			List<Account> accList = Database.query(queryString);
			if (!accList.isEmpty() && accList.size() > 0) {
				folderName = (String)accList.get(0).get(treatment.celsrm__Template_Folder_Reference_Field__c);
				if (folderName != null && folderName != '') {
					em = [SELECT Id FROM EmailTemplate WHERE Folder.Name = :folderName AND Name = :attachmentTemplateName AND IsActive = TRUE WITH SECURITY_ENFORCED LIMIT 1];
					if (em.isEmpty() || em.size() == 0) {
						em = [SELECT Id FROM EmailTemplate WHERE Name = :attachmentTemplateName AND IsActive = TRUE WITH SECURITY_ENFORCED LIMIT 1];
					}
				} else {
					em = [SELECT Id FROM EmailTemplate WHERE Name = :attachmentTemplateName AND IsActive = TRUE WITH SECURITY_ENFORCED LIMIT 1];
				}
			}
		} else {
			attachmentTemplateName = attachmentType == 'Excel' ? 'System_TreatmentExcelAttachment' : 'System_BillingStatementPDF';
			em = [SELECT Id FROM EmailTemplate WHERE Name = :attachmentTemplateName AND IsActive = TRUE WITH SECURITY_ENFORCED LIMIT 1];
		}
		
		if (!em.isEmpty()) {
			return em[0];
		} else {
			System.debug('Error: Template not found with name ' + attachmentTemplateName);
			return null;
		}
	}
	//-- FIN-8983 | Changed by Dilshad | 28-Jan-2026 | End --//
	// << END - MM - FIN-9455 - Mass Dunning -> Replace custom placeholders and translations >> 

	// << START - MM - FIN-9455 - Mass Dunning -> Replace custom placeholders and translations >> 
    private static  Map<String, String>  fetchAgreegatedAmount(Map<String, Double> TotalOpenItems, Map<String, Double> openItemsForOverDue, Map<String, Double> openItemsForOverDueNotNoted) {
        List<String> openItemsTotal = new List<String>();
        if(TotalOpenItems.keySet().size() > 0) {
            for(String curr : TotalOpenItems.keySet()) {
                openItemsTotal.add(curr + ' ' + String.valueOf(cSRMTreatmentUtility.formatAsCurrency(TotalOpenItems.get(curr))));
            }
        }

        List<String> openItemsForOverDueTotal = new List<String>();
        if(openItemsForOverDue.keySet().size() > 0) {
            for(String curr : openItemsForOverDue.keySet()) {
                openItemsForOverDueTotal.add(curr + ' ' + String.valueOf(cSRMTreatmentUtility.formatAsCurrency(openItemsForOverDue.get(curr))));
            }
        }

        List<String> openItemsForOverDueNotNotedTotal = new List<String>();
        if(openItemsForOverDueNotNoted.keySet().size() > 0) {
            for(String curr : openItemsForOverDueNotNoted.keySet()) {
                openItemsForOverDueNotNotedTotal.add(curr + ' ' + String.valueOf(cSRMTreatmentUtility.formatAsCurrency(openItemsForOverDueNotNoted.get(curr))));
            }
        }
        Map<String, String> returnMap = new Map<String, String>();
        returnMap.put('TotalOpenItems', String.join(openItemsTotal, ', '));
        returnMap.put('TotalOverdueItems', String.join(openItemsForOverDueTotal, ', '));
        returnMap.put('TotalOverdueNotNotedItems', String.join(openItemsForOverDueNotNotedTotal, ', '));
        return returnMap;
    }

	public static String formatAsNumber(Decimal value) {
        if (value == null) return null;
        return value.format();
    }
    // << START - MM - FIN-9455 - Mass Dunning -> Replace custom placeholders and translations >>

    // << START - Local copy port - methods required by local cCreateTreatmentTaskService chain >>
    // Ported from celsrm SRMTreatmentUtility.getCronForDatetime (public in package, not global)
    public static String getCronForDatetime(Datetime dt) {
        return String.format(
            '{0} {1} {2} {3} {4} ? {5}',
            new List<String>{
                String.valueOf(dt.second()), // Seconds
                String.valueOf(dt.minute()), // Minutes
                String.valueOf(dt.hour()),   // Hours
                String.valueOf(dt.day()),    // Day of month
                String.valueOf(dt.month()),  // Month
                String.valueOf(dt.year())    // Year
            }
        );
    }

    // Ported from celsrm SRMTreatmentUtility.getChildRecordIds (public in package, not global)
    // readTreatmentDetailsFile IS global, so it is referenced via the celsrm namespace.
    public static List<String> getChildRecordIds(Task tsk, celsrm__Treatment__c treatment) {
        List<String> childIds = new List<String>();
        try {
            Map<String, Object> mapStepsDataObj = new Map<String, Object>();
            String stepsData = celsrm.SRMTreatmentUtility.readTreatmentDetailsFile(tsk.Id, 'Treatment Details');
            mapStepsDataObj = (Map<String, Object>) JSON.deserializeUntyped(stepsData);

            for (String mapStepsDataKey : mapStepsDataObj.keySet()) {
                for (Object ids : (List<Object>) mapStepsDataObj.get(mapStepsDataKey)) {
                    childIds.add((Id) ids);
                }
            }
        } catch (Exception ex) {
            System.debug('Exception: ' + ex.getStackTraceString());
        }
        return childIds;
    }

    // Ported from celsrm SRMTreatmentUtility.getQueryWhereClause (global in package).
    // Re-implemented locally so it operates on the local cSRMTreatmentMapper.Criteria type
    // and uses the local cCreateTreatmentTaskService condition helpers, avoiding a
    // cross-namespace type mismatch with the package's SRMTreatmentMapper.Criteria.
    public static String getQueryWhereClause(List<cSRMTreatmentMapper.Criteria> criteriaSet, String criteriaCondition, String relatedObject, Map<String, Object> additionalParams) {
        List<String> conditionList = criteriaCondition.split(' ');
        if (criteriaCondition == '') {
            conditionList = new List<String>();
        }
        String whereClause = '';
        String operator = '';
        for (Integer i = 0; i < criteriaSet.size(); i++) {
            String tmpWhere = cCreateTreatmentTaskService.createCondition(criteriaSet.get(i), relatedObject);
			System.debug('tmpWhere::' + tmpWhere);
            if (tmpWhere != null) {
                if (criteriaCondition == '' && tmpWhere != '') {
                    if (i > 0 && operator != '') {
                        whereClause += 'AND ( ' + tmpWhere + ')';
                    } else {
                        whereClause += ' ( ' + tmpWhere + ')';
                        operator = 'AND';
                    }
                } else {
                    Integer index = i + 1;
                    String currenIndex = String.valueOf(index);
                    Integer len = conditionList.size();
                    for (Integer l = len - 1; l >= 0; l--) {
                        if (conditionList[l].isWhitespace()) {
                            conditionList.remove(l);
                        }
                    }
                    len = conditionList.size();
                    for (Integer j = 0; j < len; j++) {
                        if (currenIndex.equalsignorecase(conditionList[j])) {
                            if (tmpWhere == '') {
                                conditionList[j] = '';
                                if (j + 1 < len && conditionList[j + 1].contains(')') && !conditionList[j - 1].contains('(')) {
                                    conditionList[j - 1] = '';
                                } else if (j + 1 < len && !conditionList[j + 1].contains(')')) {
                                    conditionList[j + 1] = '';
                                }
                            } else {
                                conditionList[j] = tmpWhere;
                            }
                        }
                    }
                }
            }
        }

        if (conditionList.size() > 0) {
            conditionList = cCreateTreatmentTaskService.removeParentheses(conditionList);
            whereClause = String.join(conditionList, ' ');
        }
        return whereClause;
    }
    // << END - Local copy port >>

			//-- Start | FIN-9975 | Changed by Dhwanil | 02-Jul-2026 --// - Helpers for treatment Excel column width calculation
		private static String getTreatmentFieldDisplayValue(SObject val, String field, Map<String, String> columnWithType, Map<String, Boolean> customReferenceField) {
			if (val == null || String.isBlank(field)) {
				return '';
			}
			Object fieldValue;
			String fieldType = columnWithType != null ? columnWithType.get(field) : '';
			if (fieldType == 'REFERENCE') {
				String tempfield = '';
				Boolean isCustomReference = customReferenceField != null && customReferenceField.containsKey(field) && customReferenceField.get(field);
				if (isCustomReference) {
					tempfield = field.subString(0, field.length() - 1) + 'r';
				} else {
					tempfield = field.subString(0, field.length() - 2);
				}
				SObject tempvalue = val.getSObject(tempfield);
				fieldValue = tempvalue != null ? tempvalue.get('Name') : '';
			} else if (fieldType == 'CURRENCY') {
				if (val.get(field) != null) {
					Double dtTemp = (Double)val.get(field);
					String currencyIsoCode = (String)(UserInfo.IsMultiCurrencyOrganization() ? val.get('CurrencyIsoCode') : UserInfo.getDefaultCurrency());
					fieldValue = formatDoubleValue(currencyIsoCode, dtTemp);
				} else {
					fieldValue = '';
				}
			} else if (fieldType == 'DATE') {
				fieldValue = val.get(field) != null ? ((Date)val.get(field)).format() : '';
			} else if (fieldType == 'DATETIME') {
				fieldValue = val.get(field) != null ? ((Datetime)val.get(field)).format() : '';
			} else if (fieldType == 'NUMBER' || fieldType == 'DOUBLE') {
				fieldValue = val.get(field) != null ? formatAsNumber((Double)val.get(field)) : '';
			} else {
				fieldValue = val.get(field);
			}
			return fieldValue != null ? String.valueOf(fieldValue) : '';
		}

		private static Integer getExcelColumnPixelWidth(Integer maxColumnLength) {
			Integer safeLength = maxColumnLength != null ? maxColumnLength : 0;
			Integer columnWidth = (safeLength * 10) + 24;
			if (columnWidth < 72) {
				columnWidth = 72;
			}
			if (columnWidth > 500) {
				columnWidth = 500;
			}
			return columnWidth;
		}

		private static String getExcelColumnWidthStyle(Integer columnWidth) {
			Integer safeWidth = columnWidth != null ? columnWidth : 72;
			//-- Start | FIN-9975 | Changed by Dhwanil | 03-Jul-2026 --// - Add Excel-native width metadata for server-generated auto dunning XLS attachments
			Integer excelWidthAlt = safeWidth * 36;
			Decimal pointWidth = (Decimal.valueOf(safeWidth) * 0.75).setScale(2);
			return 'width:' + pointWidth + 'pt;max-width:' + safeWidth + 'px;mso-width-alt:' + excelWidthAlt + ';';
			//-- End | FIN-9975 | Changed by Dhwanil | 03-Jul-2026 --// - Add Excel-native width metadata for server-generated auto dunning XLS attachments
		}
		//-- End | FIN-9975 | Changed by Dhwanil | 02-Jul-2026 --// - Helpers for treatment Excel column width calculation

		private static String applyExcelCellSizing(String attachmentBody) {
		if (String.isBlank(attachmentBody)) {
			return attachmentBody;
		}
		attachmentBody = attachmentBody.replace(
			'<table width="100%" class="billing" style="border-collapse:collapse;padding:0px;font-family:',
			'<table width="auto" class="billing" style="width:auto;table-layout:auto;border-collapse:collapse;padding:0px;font-family:'
		);
		attachmentBody = attachmentBody.replace(
			'<th width="auto" style="border:1px solid gray;text-align:right;background-color: black;color: white;">',
			'<th width="auto" style="mso-width-source:userset;white-space:nowrap;border:1px solid gray;text-align:right;background-color: black;color: white;">'
		);
		attachmentBody = attachmentBody.replace(
			'<th width="auto" style="border:1px solid gray;text-align:left;background-color: black;color: white;">',
			'<th width="auto" style="mso-width-source:userset;white-space:nowrap;border:1px solid gray;text-align:left;background-color: black;color: white;">'
		);
		attachmentBody = attachmentBody.replace(
			'<td width="auto" style="text-align:right;border:solid 0.5px gray;white-space:nowrap;">',
			'<td width="auto" style="mso-width-source:userset;mso-number-format:&quot;\\@&quot;;text-align:right;border:solid 0.5px gray;white-space:nowrap;">'
		);
		attachmentBody = attachmentBody.replace(
			'<td width="auto" style="text-align:left;border:solid 0.5px gray;white-space:nowrap;">',
			'<td width="auto" style="mso-width-source:userset;mso-number-format:&quot;\\@&quot;;text-align:left;border:solid 0.5px gray;white-space:nowrap;">'
		);
		return attachmentBody;
	}

}