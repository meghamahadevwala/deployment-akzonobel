//--- DO NOT CHANGE CODE | START ---//
(function(global, factory) {
    typeof exports === 'object' && typeof module !== 'undefined' ? factory(exports) :
        typeof define === 'function' && define.amd ? define(['exports'], factory) :
        (factory((global.gog = global.gog || {})));
}(this, (function(exports) {
    'use strict';
    var version = "1.0.0";
	
	function filterDataByViewDispute(values, invoke, dataServiceObj, fireEvent, ref){
		console.log('values>>>>>'+values);
		var screenName = values['ggScreenName'];
		var userCurrency = values['userCurrency'];
		//if(values['ListView']) {
			return new Promise(function(resolve, reject) {
				if(values['ListView'] && values['ListView'] !== null && values['ListView'] !== ''){
					invoke({ 
						className: 'defaultViewClass', 
						functionName: 'onChangeView',
						values: values 
					}).then(result1 => {
						var result = JSON.parse(JSON.stringify(result1));
					// 	if(result.l_values.length > 0) {
					// 	for(let tempVal of result.l_values) {
					// 		for(let tempfield of result.updatedColumns) {
					// 			if(tempfield.fieldName =='Name'){
					// 				let key = '<a href="' + '/'+ tempVal['Id'] + '"' + ' target="_blank">' + tempVal['Name'] + '</a>';
					// 				tempVal.Name = key;
					// 			} else if(result.refField.indexOf(tempfield.fieldName) !== (-1)){
					// 				let st =tempfield.fieldName.substring(0,tempfield.fieldName.length -1)+ 'r';
					// 				let tempmap = tempVal[st]; 
					// 				if(tempmap !== undefined && tempmap !== null) {
					// 					let key = '<a href="' + '/'+ tempVal[tempfield.fieldName] + '"' + ' target="_blank">' +   tempmap['Name'] + '</a>';
					// 					tempVal[tempfield.fieldName] = key;
					// 				}
					// 			}
					// 		}
					// 	}
					// }
					let paramMap = {
						columns: result.updatedColumns,
						values: result.l_values,
						onChangeMethodName: 'filterDataByViewDispute'
						};
					fireEvent(ref.pageRef, 'SetDataInDataGrid_' + screenName + '_DisputeGrid', paramMap);
						// fireEvent(ref.pageRef, 'DisputeGrid_' + screenName + '_Columns', result.updatedColumns);
						// fireEvent(ref.pageRef, 'DisputeGrid_' + screenName , result.l_values);
						var finalText = '<b> Total Balance = 0.00 </b>';
						var totalSelectedDispute = '<b>' + 'Selected Dispute : 0 </b>';
						//-- Start | FIN-8530 | Changed by Ravi | 10 Nov 2025 --//
						let resolveResult = {'Total' : finalText,'totalSelectedDispute':totalSelectedDispute,'DisputeGrid':[]};
						if (result.childAccountNames) {
							resolveResult.enableChildNotes = 'true';
							resolveResult.childAccountNotes = '<div id="accountBanner" style="background-color:#e3f2fd; color:#0d47a1; border:1px solid #90caf9; border-radius:8px;padding:0px 20px; width:fit-content; box-shadow:0 2px 6px rgba(0,0,0,0.15);font-size:15px; display:flex; justify-content:space-between; align-items:center;"><span><strong>Included Child Accounts: </strong>' + result.childAccountNames + '</span><span class="closeChildAccount" style="cursor:pointer; font-size:20px; font-weight:bold; margin-left:12px; color:#0d47a1;">×</span></div>';
							// resolveResult.childAccountNotes = 'Include child Accounts: ' + result.childAccountNames;	
						} else {
							resolveResult.enableChildNotes = 'false';
						}
						resolve(resolveResult);
						//-- End | FIN-8530 | Changed by Ravi | 10 Nov 2025 --//
					}).catch(error => {
						console.log('error :' + error);
						reject(error);
					});
				}else{
					resolve(values);
				}
								
			});
		//}		
	}
	//-- Start | FIN-8530 | Changed by Ravi | 10 Nov 2025 --//
	function removDisputeChildAccount(values, invoke, dataServiceObj, fireEvent, ref) {
		debugger;
		console.log('values>>>>>' + values);
		return new Promise(function (resolve, reject) {
			if(values.buttonClassListchildAccountNotes && values.buttonClassListchildAccountNotes.contains('closeChildAccount')) {
				sessionStorage.removeItem('selectedAccountIds');
				values['accountHierarchyChildIds'] = null;
				var onchangeMap = {
					"onChangeMethod": 'filterDataByView',
					"accountHierarchyChildIds": null
				};
				fireEvent(ref.pageRef, 'refreshValues_SRMTransactionGridScreen', onchangeMap);
				gog.filterDataByViewDispute(values, invoke, dataServiceObj, fireEvent, ref).then(result1 => {
					var result = JSON.parse(JSON.stringify(result1));
					resolve(result);
				}).catch(err => {
					reject(err);
				});
			} else {
				resolve(values);
			}
		});
	}
	//-- End | FIN-8530 | Changed by Ravi | 10 Nov 2025 --//
	function onPageLoadSetViewForDispute(values, invoke, dataServiceObj, fireEvent, ref){
		//console.log('values>>>>>'+JSON.stringify(values));
		var screenName = values['ggScreenName'];
		return new Promise(function(resolve, reject) {
			invoke({ 
				className: 'defaultViewClass', 
				functionName: 'getDefaultView',
				values: values 
			}).then(result1 => {
				//resolve(result);
				var result = JSON.parse(JSON.stringify(result1));
				if(result['ListView']){
					// if(result.l_values.length > 0) {
					// 	for(let tempVal of result.l_values) {
					// 		for(let tempfield of result.updatedColumns) {
					// 			if(tempfield.fieldName =='Name'){
					// 				let key = '<a href="' + '/'+ tempVal['Id'] + '"' + ' target="_blank">' + tempVal['Name'] + '</a>';
					// 				tempVal.Name = key;
					// 			} else if(result.refField.indexOf(tempfield.fieldName) !== (-1)){
					// 				let st =tempfield.fieldName.substring(0,tempfield.fieldName.length -1)+ 'r';
					// 				let tempmap = tempVal[st]; 
					// 				if(tempmap !== undefined && tempmap !== null) {
					// 					let key = '<a href="' + '/'+ tempVal[tempfield.fieldName] + '"' + ' target="_blank">' +   tempmap['Name'] + '</a>';
					// 					tempVal[tempfield.fieldName] = key;
					// 				};
					// 			}
					// 		}
					// 	}
					// }
					let paramMap = {
						columns: result.updatedColumns,
						values: result.l_values,
						onChangeMethodName: 'filterDataByViewDispute'
						};
					fireEvent(ref.pageRef, 'SetDataInDataGrid_' + screenName + '_DisputeGrid', paramMap);
					// fireEvent(ref.pageRef, 'DisputeGrid_' + screenName + '_Columns', result.updatedColumns);
					// fireEvent(ref.pageRef, 'DisputeGrid_' + screenName , result.l_values);
					//result['TransactionList'] = '';
					delete result.updatedColumns;
					delete result.l_values;
					result.Total = '<b> Total Balance = 0.00 </b>';
					result.totalSelectedDispute = '<b>' + 'Selected Dispute : 0 </b>';
					//-- Start | FIN-8530 | Changed by Ravi | 10 Nov 2025 --//
					if (result.childAccountNames) {
						result.enableChildNotes = 'true';
						result.childAccountNotes = '<div id="accountBanner" style="background-color:#e3f2fd; color:#0d47a1; border:1px solid #90caf9; border-radius:8px;padding:0px 20px; width:fit-content; box-shadow:0 2px 6px rgba(0,0,0,0.15);font-size:15px; display:flex; justify-content:space-between; align-items:center;"><span><strong>Included Child Accounts: </strong>' + result.childAccountNames + '</span><span class="closeChildAccount" style="cursor:pointer; font-size:20px; font-weight:bold; margin-left:12px; color:#0d47a1;">×</span></div>';
						// resolveResult.childAccountNotes = 'Include child Accounts: ' + result.childAccountNames;	
					} else {
						result.enableChildNotes = 'false';
					}
					//-- End | FIN-8530 | Changed by Ravi | 10 Nov 2025 --//
					resolve(result);
				}				
			}).catch(error => {
				console.log('error :' + error);
				reject(error);
			});				
		});
	}
	
	function calculateTotalAmount(values, invoke, dataServiceObj, fireEvent, ref){
		return new Promise(function(resolve, error) {
			var finalText = '';
			var totalSelectedDispute = '';
			var isMultiCurrency = values['isMultiCurrency'];
			var userCurrency = values['userCurrency'];
			if(values['DisputeGrid'] !== undefined && values['DisputeGrid'] !== null && values['DisputeGrid'].length > 0) {
				var trxnLst = values['DisputeGrid']; 
				var len = trxnLst.length;
				var amount = {};
				if(isMultiCurrency) {
					//TODO
					for(var i=0; i<len; i++) {
						if(trxnLst[i]['CurrencyIsoCode'] in amount) {
							amount[ trxnLst[i]['CurrencyIsoCode'] ] += trxnLst[i]['balance'] ? trxnLst[i]['balance'] : trxnLst[i]['celsrm__Balance__c'];
						} else {
							amount[ trxnLst[i]['CurrencyIsoCode'] ] = trxnLst[i]['balance'] ? trxnLst[i]['balance'] : trxnLst[i]['celsrm__Balance__c'];
						}
					}
					var str = '';
					for(var k in amount) {
						str += k + ' : ' + parseFloat(amount[k]).toFixed(2).replace(/(\d)(?=(\d{3})+\.)/g, '$1,') + ' ';
					}
					totalSelectedDispute = '<b>' + 'Selected Dispute : ' + len.toLocaleString() + '</b>';
					finalText = '<b> Total Balance = ' + str + '</b>';
				} else {
					var tmp = 0.0;
					for(var i=0; i<len; i++) {
						tmp += trxnLst[i]['balance'] ? trxnLst[i]['balance'] : trxnLst[i]['celsrm__Balance__c'];
					}
					totalSelectedDispute = '<b>' + 'Selected Dispute : ' + len.toLocaleString() + '</b>';
					finalText = '<b> Total Balance = ' + userCurrency + ' : ' + parseFloat(tmp).toFixed(2).replace(/(\d)(?=(\d{3})+\.)/g, '$1,') + '</b>';
				}
			} else {
				totalSelectedDispute = '<b>' + 'Selected Dispute : 0 </b>';
				finalText = '<b> Total Balance = 0.00 </b>';
			}
			resolve({'Total' : finalText,'totalSelectedDispute':totalSelectedDispute});
		});
	}
	function deleteListViewDispute(values, invoke, dataServiceObj, fireEvent, ref){
		if(confirm('Are you sure?')) {
			return new Promise(function(resolve, error) {
				invoke({ 
					className: 'DeleteListView', 
					functionName: '',
					values: values 
				}).then(result => {
					var listview = result.ListView;
					gog.filterDataByViewDispute(result, invoke, dataServiceObj, fireEvent, ref).then(result1 => {
						var result = JSON.parse(JSON.stringify(result1));
						result.ListView = listview;
						resolve(result);
					}).catch(err => {
						reject(err);
					});
				}).catch(error => {
					console.log('error :' + error);
					reject(error);
				});
				
			});
		} else {
			return new Promise(function(resolve, error) {
				resolve({});
			});
		}
	}
	
	function OnChangeViewCreateDispute(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum) {
		var ListViewName  = values["ListView"];
		return new Promise(function(resolve, error) {
			// window.location.reload(true);
			if(!values['ListViewEditMode'] && values['selectedListViewOption']){
				fireEvent(cmp.pageRef, 'addPicklistOption_'+ values.ggScreenName +'_ListView', values['selectedListViewOption']);
			}
			if(ListViewName){
            gog.filterDataByViewDispute(values, invoke, ds, fireEvent, cmp);
         }
			resolve(values);
		});
	}

	function onSubmitReverseDispute(values, invoke, ds,fireEvent,ref) {
		return new Promise(function(resolve, error) {
			if(values.DisputeList && values.DisputeList.length > 0){
				resolve(values);
			} else {
				let resturnVal = {};
				resturnVal.ggErrorMessage = 'Please select at least one dispute for reversal.';
				resturnVal.stopExecution = true;
				resolve(resturnVal);
			}
		});
	}
	//-- Start | FIN-8530 | Changed by Ravi | 10 Nov 2025 --//
	exports.removDisputeChildAccount = removDisputeChildAccount;
	//-- End | FIN-8530 | Changed by Ravi | 10 Nov 2025 --//
	exports.OnChangeViewCreateDispute = OnChangeViewCreateDispute;
	exports.calculateTotalAmount = calculateTotalAmount;
	exports.filterDataByViewDispute = filterDataByViewDispute;
	exports.onPageLoadSetViewForDispute = onPageLoadSetViewForDispute;
	exports.deleteListViewDispute = deleteListViewDispute;
	exports.onSubmitReverseDispute = onSubmitReverseDispute;

	//--- DO NOT CHANGE CODE | START ---//
    Object.defineProperty(exports, '__esModule', {
        value: true
    });
	//--- DO NOT CHANGE CODE | END ---//

})));