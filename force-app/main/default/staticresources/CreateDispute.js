(function (global, factory) {
	typeof exports === 'object' && typeof module !== 'undefined' ? factory(exports) :
		typeof define === 'function' && define.amd ? define(['exports'], factory) :
			(factory((global.gog = global.gog || {})));
}(this, (function (exports) {
	'use strict';

	var version = "1.0.0";

	function onLoadCreateDisputeScreen(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, ShowToastEvent) {
		return new Promise(function (resolve, reject) {
			invoke({
				className: 'DisputeActionController',
				functionName: 'onLoadCreateDisputeScreen',
				values: values
			}).then(response => {
				let result = JSON.parse(JSON.stringify(response));
				//-- Start | FIN-8525 | Changed by Asera | 14 Oct 2025 --//
				if (result.hasOwnProperty('ggErrorMessage') && result.ggErrorMessage) {
						setTimeout(() => {
							fireEvent(cmp.pageRef, 'closeScreen_Create Dispute', '');	
							fireEvent(cmp.pageRef, 'onCancel_SRMTransactionGridScreen_Group1', '');
						}, 0);
					// result.ggErrorMessage = '';
				}
				//-- End | FIN-8525 | Changed by Asera | 14 Oct 2025 --//
				resolve(result);
			}).catch(error => {
				console.log('error :' + error);
				reject(error);
			});
		});
	}

	function updateAllGrid(values, invoke, ds, fireEvent, lwcRef, rowData) {

		var arr = values['TransactionList'];

		var count = rowData['gogGridIndex'];
		var editfieldS = values['EditableField'].split(",");
		editfieldS.push('workflowMatrix');
		editfieldS.push('totalSLADays');
		var size = arr.length;

		for (var i = 0; i < parseInt(editfieldS.length); i++) {
			var test2 = parseInt(editfieldS.length);
			var Fieldst = String(editfieldS[i]);
			if (Fieldst != 'DisputeAmount') {
				if (arr[count][Fieldst] != null) {
					var RequiredValue = arr[count][Fieldst];
					for (var k = 0; k < parseInt(size); k++) {

						arr[k][Fieldst] = RequiredValue;


					}
				}
			}
		}
		values['TransactionList'] = arr;
		return new Promise(function (resolve, error) {
			resolve(values);
		});
	}

	function onSubmitEmail(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum) {
		return new Promise(function (resolve, error) {
			fireEvent(cmp.pageRef, 'refreshActivity_ComposeMailFromAnonomusActivity_Activity');
			resolve(values);
		});
	}

	function onChangeDisputeType(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum) {
		return new Promise(function (resolve, error) {
			//-- Starts | FIN-7796 | Changed by Dilshad | 30-Jun-2025 --//
			if (values.disputeResolverType == 'Dispute_Workflow_Matrix') {
				let transactionList = values['TransactionList'];
				transactionList[rowNum]['DisputeResolver'] = {};
				resolve({ 'TransactionList': transactionList });
			} else {
				resolve({});
			}
			//-- Ends | FIN-7796 | Changed by Dilshad | 30-Jun-2025 --//
		});
	}

	function onChangeReasonCode(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum) {
		return new Promise(function (resolve, error) {
			//-- Starts | FIN-7796 | Changed by Dilshad | 30-Jun-2025 --//
			if (values.disputeResolverType == 'Dispute_Workflow_Matrix') {
			//-- Ends | FIN-7796 | Changed by Dilshad | 30-Jun-2025 --//
				//-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
				let transactionList = JSON.parse(JSON.stringify(values['TransactionList']));
				let selectedRow = transactionList[rowNum];
				values['selectedRowIndex'] = rowNum;
				values['rowNum'] = rowNum;
				values['selectedTransactionRow'] = selectedRow;
				values['selectedType'] = selectedRow['disputeType'];
				values['selectedReasonCode'] = selectedRow['reasonCode'];
				//-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
				invoke({
					className: 'DisputeActionController',
					functionName: 'onChangeReasonCode',
					values: values
				}).then(result => {
					//-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
					if (result.resolverId || result.resolverUserMasterId) {
					//-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
						let resolverMap = {};
						//-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
						resolverMap.id = result.resolverUserMasterId || result['resolverId'];
						//-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
						resolverMap.name = result['resolverName'];
						//-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
						resolverMap.userMasterId = result.resolverUserMasterId;
						transactionList[rowNum]['DisputeResolver'] = resolverMap;
						transactionList[rowNum]['WorkflowMatrix'] = result['relatedMatrixId'];
						transactionList[rowNum]['totalSLADays'] = result['totalSLADays'];
						transactionList[rowNum]['isExternalResolver'] = result['isExternalResolver'];
						resolve({ 'TransactionList': transactionList });
						//-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
					} else {
						//-- Start | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
						transactionList[rowNum]['DisputeResolver'] = {};
						resolve({
							'TransactionList': transactionList,
							ggErrorMessage: result.ggErrorMessage
						});
						//-- End | FIN-9786 | Changed by Asera | 10 Jun 2026 --//
					}
				}).catch(error => {
					console.log('error :' + error);
					reject(error);
				});
			//-- Starts | FIN-7796 | Changed by Dilshad | 30-Jun-2025 --//
			} else {
				resolve({});
			}
			//-- Ends | FIN-7796 | Changed by Dilshad | 30-Jun-2025 --//
		});
	}

	function onChangeNotifyCustomer(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum) {
		return new Promise(function (resolve, error) {
			if (values['notifyCustomer'] == true) {
				values['ContactMethod'] = 'Email';
				// << START - MM - FIN-8420 - Assigne Status based on Notify>>
				values['disputeStatus'] = '30 Waiting For Information';
				// << END - MM - FIN-8420 - Assigne Status based on Notify>>
			} else {
				values['ContactMethod'] = null;
				// << START - MM - FIN-8420 - Assigne Status based on Notify>>
				values['disputeStatus'] = '10 New';
				// << END - MM - FIN-8420 - Assigne Status based on Notify>>
			}
			resolve(values);
		});
	}

	function onSubmitCreateDisputeScreen(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum) {
		return new Promise(function (resolve, error) {
			for (var i = 0; i < values.TransactionList.length; i++) {
				if (JSON.stringify(values.TransactionList[i].DisputeResolver) == '{}') {
					values.ggErrorMessage = 'Dispute resolver is missing for Invoice ' + values.TransactionList[i]['invoiceNo'] + '. Please configure the resolver first.';
					values.stopExecution = true;
					resolve(values);
					break;
				}
			}
			if (!values.stopExecution) {
				resolve(values);
			}
		});
	}
	function showToast(stTitle, stMessage, stVariant, stMode, stDispatchFunction, ShowToastEvent) {
		stDispatchFunction.dispatchEvent(new ShowToastEvent({
			title: stTitle,
			message: stMessage,
			variant: stVariant,
			mode: stMode
		}));
	};
	//-- Starts | FIN-7319 | Changed by Ravi | 16-Jun-2026 --//
	function SendMessageToSummary(values, invoke, dataServiceObj, fireEvent, ref, rowValue, navigationMixin, ShowToastEvent) {
		return new Promise(function (resolve, reject) {
			let message = {};
			message.repharseSummary = true;
			message.isUser = false;
			message.hasError = false;
			message.errorMessage = '';
			message.resultSummary = 'We have capture a Dispute and sent out a response on the email.';
			fireEvent(ref.pageRef, 'All Incoming Emails_SummaryAgent_ActivityForMyEmailsTab', message);
			resolve({});
		});
	}

	// << START - MM - FIN-8174 - Dynamic translated headers based account local | on Change Account Locale on Create Dispute Screen>>
	function onChangeAccountLocale(values, invoke, dataServiceObj, fireEvent, cmp, rowvals, NavigationMixin, rowNum, ShowToastEvent) {
		debugger;
		return new Promise(function (resolve, reject) {
			if (values['accountLocale'] && values['accountLocale'] != null) {
				invoke({
					className: 'DisputeActionController',
					functionName: 'updateAccountLocale',
					values: values
				}).then(result => {
					fireEvent(cmp.pageRef, 'ComposeEmail__'+ cmp.additionalAttributes.screenName, result.accountLocale);
					resolve(result);
				}).catch(error => {
					console.log('error :' + error);
					reject(error);
				});
			} else {
				resolve({});
			}
			// fireEvent(cmp.pageRef, 'ComposeEmail__'+ cmp.additionalAttributes.screenName, values.CompanyCode);
			// resolve(values);
		});
	}
	// << END - MM - FIN-8174 - Dynamic translated headers based account local | on Change Account Locale on Create Dispute Screen>>

	exports.SendMessageToSummary = SendMessageToSummary;
	//-- End | FIN-7319 | Changed by Ravi | 16-Jun-2026 --//
	exports.showToast = showToast;
	exports.onLoadCreateDisputeScreen = onLoadCreateDisputeScreen;
	exports.onSubmitEmail = onSubmitEmail;
	exports.updateAllGrid = updateAllGrid;
	exports.onChangeReasonCode = onChangeReasonCode;
	exports.onChangeDisputeType = onChangeDisputeType;
	exports.onChangeNotifyCustomer = onChangeNotifyCustomer;
	exports.onSubmitCreateDisputeScreen = onSubmitCreateDisputeScreen;
	// << START - MM - FIN-8174 - Dynamic translated headers based account local | on Change Account Locale on Create Dispute Screen>>
	exports.onChangeAccountLocale = onChangeAccountLocale;
	// << END - MM - FIN-8174 - Dynamic translated headers based account local | on Change Account Locale on Create Dispute Screen>>
	Object.defineProperty(exports, '__esModule', {
		value: true
	});

})));