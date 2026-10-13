//--- DO NOT CHANGE CODE | START ---//
(function(global, factory) {
    typeof exports === 'object' && typeof module !== 'undefined' ? factory(exports) :
        typeof define === 'function' && define.amd ? define(['exports'], factory) :
        (factory((global.gog = global.gog || {})));
}(this, (function(exports) {
    'use strict';

    var version = "1.0.0";
	//--- DO NOT CHANGE CODE | END ---//
	function onPageLoadDatagrid(values, invoke, ds,fireEvent, ref) {
		var screenName = values['ggScreenName'];
		console.log("JSON.parse(JSON.stringify(values)):" + JSON.stringify(values));
		return new Promise(function(resolve, reject) {
			invoke({ 
				className: 'CA_PaymentLineExtract', 
				functionName: '',
				values: values 
			}).then(result => {	
				fireEvent(ref.pageRef, 'PaymentLineList_' + screenName, result.PayLineList);
				resolve(result);
			}).catch(error => {	
				reject(error);
			});
		});
	}

	function ExportPaymentLine(values, invoke, ds,fireEvent, ref) {
		var screenName = values['ggScreenName'];
		console.log("JSON.parse(JSON.stringify(values)):" + JSON.stringify(values));
		values.isExport = 'true';
		return new Promise(function(resolve, reject) {
			invoke({ 
				className: 'CA_PaymentLineExtract', 
				functionName: '',
				values: values 
			}).then(result => {
					var csvStringResult, counter, keys, columnDivider, lineDivider;
					var header = ['Name','Account_Number', 'Account_Name', 'Invoice', 'Invoice_Balance', 'Discount_Amount', 'NET_PAID_Amount', 'Correction_Codes','Reason_Codes','PO_Number', 'Check_Number', 'Check_Amount', 'Payment_Type','Transaction_Type','Invoice_Amount','Remittance_Amount'];
					keys = ['payLineName','Account','AccountName','TransactionFormula','InvoiceBalance','DiscountAmount','Amount','applicationCode','ReasonCode','TransactionPO','Cheque','ChequeAmount', 'paymentType','TransactionType','InvoiceAmount','celsrm__Remittance_Amount__c'];
					columnDivider = ',';
					lineDivider =  '\n';
					csvStringResult = '';
					csvStringResult += header.join(columnDivider);
					csvStringResult += lineDivider;
					var objectRecords = result.PayLineList;
					
					for(var i=0; i < objectRecords.length; i++){  
						counter = 0;
				   
						for(var sTempkey in keys) {
							var skey = keys[sTempkey] ;  
						// add , [comma] after every String value,. [except first]
							if(counter > 0){ 
								csvStringResult += columnDivider; 
							}   
							if ( objectRecords[i][skey] != undefined){
								csvStringResult += '"'+objectRecords[i][skey] +'"'; 
							}else{
								csvStringResult += ""; 
							}
							counter++;
						} // inner for loop close 
					 	csvStringResult += lineDivider;
					}// outer main for loop close 
					
					// csvStringResult += ',,,,\"'+ values.netAmount +'\",\"'+ values.totalDiscountAmt +'\",,,,,,,,,\n'
					csvStringResult += ',,,,,\"'+ values.totalDiscountAmt +'\",\"'+ values.netAmount +'\",,,,,,,,,\n'
					var hiddenElement = document.createElement('a');
					const encodedURI = encodeURI(csvStringResult);
					const fixedEncodedURI = encodedURI.replaceAll('#', '%23');
					hiddenElement.href = 'data:text/csv;charset=utf-8,' + fixedEncodedURI;
					// hiddenElement.href = 'data:text/csv;charset=utf-8,' + encodeURI(csvStringResult);
					hiddenElement.target = '_self'; // 
					hiddenElement.download = 'ExportData.csv';  // CSV file Name* you can change it.[only name not .csv] 
					document.body.appendChild(hiddenElement); // Required for FireFox browser
					hiddenElement.click();
					result.isExport = 'false';
					resolve(result);
			}).catch(error => {
					reject(error);
				});
			
		});
	}

	exports.ExportPaymentLine = ExportPaymentLine;
	exports.onPageLoadDatagrid = onPageLoadDatagrid;
	
//--- DO NOT CHANGE CODE | START ---//
    Object.defineProperty(exports, '__esModule', {
        value: true
    });
//--- DO NOT CHANGE CODE | END ---//
})));