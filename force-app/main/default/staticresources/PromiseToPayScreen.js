(function(global, factory) {
    typeof exports === 'object' && typeof module !== 'undefined' ? factory(exports) :
        typeof define === 'function' && define.amd ? define(['exports'], factory) :
        (factory((global.gog = global.gog || {})));
}(this, (function(exports) {
    'use strict';

    var version = "1.0.0";
	
	function showNoteBody(values, invoke, ds) {
		values["showNoteBody"] = "true";
		return new Promise(function(resolve, error) {
			resolve(values);
		});
	}
	
	function generateStatement(values, invoke, ds) {
		var accId = values['Id'];
		var arr = values['TransactionList'];
		var formatType = values['StatementFormat'];
		var trxnId = '';
		return new Promise(function(resolve, reject) {
			if(!formatType) {
				reject('Please select Statement Format');
			} else {
				if(arr && arr.length > 0) {
					for(var i=0; i<arr.length;i++) {
						if(i == arr.length-1) {
							trxnId += arr[i].Id;
						} else {
							trxnId += arr[i].Id + ',';
						}
					}			
					var url = '/apex/PreviewStatement?formatType='+formatType+'&accId='+accId+'&txIds='+trxnId;
					window.open(url,'_blank');
				}
				resolve({});
			}
		});
	}
		
	function createStatementAttachment(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum) {
		return new Promise(function(resolve, error) {
			let negativepromiseAmount = false;
			const tranList = values['TransactionList'];
			tranList.forEach(tranObj => {
				if(tranObj.celsrm__Amount__c < 0) {
					negativepromiseAmount = true;
				}
			});
			if(negativepromiseAmount) {
				let returnMap = {};
				returnMap.ggErrorMessage = "You cannot create promise on credit invoice.";
				returnMap.stopExecution = true;
				resolve(returnMap);
				setTimeout(() => {
					fireEvent(cmp.pageRef, 'onCancel_SRMTransactionGridScreen_Group1', '');
					// fireEvent(cmp.pageRef, 'onCancel_SRM_PromisToPayScreen_TransactionList', '');
				}, 10);
			} else {
				values['StatementFormat'] = "Excel";
				values['AttachCheckBox']  =true;
				// return new Promise(function(resolve, error) {
					gog.showFollowupDaysp2p(values, invoke, ds).then(result1 => {
						gog.createStatementAttachmentonLoad(result1, invoke, ds).then(result1 => {
							var result = JSON.parse(JSON.stringify(result1));
							delete result.enableSubmitButton;
							resolve(result);
						}).catch(err => {
							reject(err);
						});
					}).catch(err => {
						reject(err);
					});
					//resolve(values);
				// });
			}
		});
	/*	return new Promise(function(resolve, reject) {
			if(values['AttachCheckBox']) {
				if(!formatType) {
					reject('Please select Statement Format');
				} else {
					invoke({ 
						className: 'AttachStatementOnAccount', 
						functionName: 'funcName',
						values: values 
					}).then(result => {
						//sessionStorage.removeItem(rNumber);
						resolve(result);
					}).catch(error => {
						console.log('error :' + error);
						//sessionStorage.removeItem(rNumber);
						reject(error);
					});
				}
			} else {
				//need to remove statement
				var compMap = values['ComposeEmail'];
				if(compMap && compMap.hasOwnProperty('attachment') && compMap['attachment'].length > 0) {
					for(var i=0;i<compMap['attachment'].length;i++) {
						if(compMap['attachment'][i].Title.includes('BillingStatement')) {
							compMap['attachment'].splice(i, 1);
							break;
						}
					}
				}
				resolve(values);
			}
			
		});*/
	}

	function changeStatementFormat(values, invoke, ds) {
		//var accId = values['Id'];
		//var arr = values['TransactionList'];
		var formatType = "Excel";
		values['AttachCheckBox']  ="true";
		return new Promise(function(resolve, reject) {
			if(values['AttachCheckBox']) {
				if(formatType) {
					invoke({ 
						className: 'AttachStatementOnAccount', 
						functionName: 'funcName',
						values: values 
					}).then(result1 => {
						//sessionStorage.removeItem(rNumber);
						var result = JSON.parse(JSON.stringify(result1));
						resolve(result);
					}).catch(error => {
						console.log('error :' + error);
						//sessionStorage.removeItem(rNumber);
						reject(error);
					});
				}
			} else {
				resolve({});
			}
			
		});
	}

	function showFollowupDaysp2p(values, invoke, ds) {
		return new Promise(function(resolve, reject){
			invoke({
				className: 'WCM_FetchFolloupDays', 
				values: values 
			}).then(result1 => {
				var result = JSON.parse(JSON.stringify(result1));
				resolve(result);
				
			}).catch(error => {
				console.log('error :' + error);
				reject(error);
			});
		});
	}
	function showFollowUpDays(values, invoke, ds) {
		return new Promise(function(resolve, reject) {
			try {
				let returnVal = {};
				if(values.isFollowUp) {
					returnVal.FollowUpDate = new Date(new Date().getTime()+(5*24*60*60*1000));
				}
				resolve(returnVal);
			} catch (error) {
				console.log('error :' + error);
				reject(error);
			}
		});
	}
	
	function createStatementAttachmentonLoad(values, invoke, ds) {
		//var accId = values['Id'];
		//var arr = values['TransactionList'];
		var arr = values['TransactionList'];
		var trxnId = '';
		// var formatType = 'Excel';
		return new Promise(function (resolve, reject) {
			//	if(values['AttachCheckBox']) {
			// if (!formatType) {
			// 	reject('Please select Statement Format');
			// } else {
				if(arr && arr.length > 0) {
					for(var i=0; i<arr.length;i++) {
						if(i == arr.length-1) {
							trxnId += arr[i].Id;
						} else {
							trxnId += arr[i].Id + ',';
						}
					}	
				}
				values.trxnId = trxnId;
				invoke({
					className: 'SendStatementOnAccount',
					functionName: 'contactCustomerPreview',
					values: values
				}).then(result1 => {

					//sessionStorage.removeItem(rNumber);
					//var newdata = [];
					//var Ids = "";
					var result = JSON.parse(JSON.stringify(result1));
					if (result) {
						var TotalBalance = 0;
						
						var newLst = result.DueTransList;
						var newLstFields = result.selectedFields;
						var newLstFieldsLabel = result.selectedFieldsLabel;
						
						var ContentSt = result.SendStmtAttachmentContent;
						
						var htmlBody;
						var pg = 0;
						var pageBreakAfter = 9;
						//pageBreakAfter= 13;
						// htmlBody ="<html><head><style> .thStyle{ border-right:1px #ccc solid; border-bottom:1px #ccc solid; text-align: center;}.trStyle{ border-right:1px #ccc solid; border-bottom:1px #ccc solid;background-color: rgb(249, 249, 249);}.tdStyle{ border-right:1px #ccc solid; border-bottom:1px #ccc solid; text-align: center;}</style></head>";
						//-- Start | FIN-8048 | Changed by Ravi | 29 July 2025 --//
						// var st =  "<head><style>#txSummaryTableJS td{text-align:left;border:solid 1px gray;white-space:nowrap;}  #txSummaryTableJS th{border:1px solid gray;text-align: left;}  #txSummaryTableJS {border-collapse:collapse;padding:0px;border:1px solid gray;font-family:Arial Unicode MS;}</style>";
						//-- End | FIN-8048 | Changed by Ravi | 29 July 2025 --//
						htmlBody = "<table width='100%' id='txSummaryTableJS'><tr>";

						for (let i = 0; i < newLstFieldsLabel.length; i++) {
							htmlBody = htmlBody + "<th><b>" + newLstFieldsLabel[i] + "</b></th>";

						}


						htmlBody += "</tr>";
						for (let i = 0; i < newLst.length; i++) {
							if(pg==pageBreakAfter && values['StatementFormat'] == 'PDF') {
								htmlBody += "</table>";
								htmlBody += "<br>";
								htmlBody += "<table width='100%' id='txSummaryTableJS'><tr style='page-break-before:always;'>";
								for (let i = 0; i < newLstFieldsLabel.length; i++) {
									htmlBody = htmlBody + "<th><b>" + newLstFieldsLabel[i] + "</b></th>";

								}
								htmlBody += "</tr>";
								pg=0;
									pageBreakAfter= 32;
							}
							pg=pg+1;
							htmlBody += "<tr>";
							for (let j = 0; j < newLstFields.length; j++) {
								
								//console.log(" newLst[i].Name"+ newLst[i].Name);
								//console.log(" newLst[i].Name"+ newLst[i].Name+newLst[i].Account__r.Name);
								var fieldName = newLstFields[j];
								var fieldValue = "";
								if (fieldName == "celsrm__Balance__c") {
									fieldName = "Balance";
								}
								if (newLst[i][fieldName] != undefined) {
									fieldValue = newLst[i][fieldName];
								} else {
									fieldValue = "";
								}
								
								htmlBody += "<td>" + fieldValue + "</td>";

							}
							htmlBody += "</tr>";
							var newAmt = newLst[i].celsrm__Balance__c == null ? 0 : newLst[i].Balance__c;
							TotalBalance = TotalBalance + newAmt;
							
						}
						htmlBody += "<tr>";
						// htmlBody += "<td colspan='" + newLstFields.length + "' > <b> Total</b>  $" + TotalBalance.toFixed(2) + "</td>";
						htmlBody += "</tr>";
						htmlBody += "</table>";
						delete result.DueTransList;
						delete result.selectedFields;
						delete result.selectedFieldsLabel;
						delete result.TransIds;
						delete result.returnTemplateAmount;
						console.log("htmlBody" + htmlBody);
						//-- Start | FIN-8048 | Changed by Ravi | 29 July 2025 --//
						// ContentSt= ContentSt.replace("<head>",st);
						//-- End | FIN-8048 | Changed by Ravi | 29 July 2025 --//
						ContentSt = ContentSt.replace("{Transaction.Summary}", htmlBody);
						var temp = window.btoa(unescape(encodeURIComponent(ContentSt)));
						values['SendStmtAttachmentContent'] = temp;
						gog.onAttachFormatCompletion(values, invoke, ds).then(result => {
							
							resolve(result);
						}).catch(err => {
							reject(err);
						});
						
					}
					
				}).catch(error => {
					console.log('error :' + error);
					//sessionStorage.removeItem(rNumber);
					reject(error);
				});
			// }
			/*	} else {
					//need to remove statement
					var compMap = values['ComposeEmail'];
					if(compMap && compMap.hasOwnProperty('attachment') && compMap['attachment'].length > 0) {
						for(var i=0;i<compMap['attachment'].length;i++) {
							if(compMap['attachment'][i].Title.includes('BillingStatement')) {
								compMap['attachment'].splice(i, 1);
								break;
							}
						}
					}
					resolve(values);
				}*/

		});
	}

	function onAttachFormatCompletion(values, invoke, ds) {
		let tempVal = {'finalContent' : values['SendStmtAttachmentContent'],'StatementFormat':values['StatementFormat']};
		return new Promise(function (resolve, reject) {
			invoke({
				className: 'SendStatementAttachmentInsert',
				functionName: 'Send Statement',
				values: tempVal
			}).then(result => {
				if (result) {
					values['AttachmentIDSendStmt'] = result.AttachmentIDSendStmt;
					gog.onAttachGenerateCompletion(values, invoke, ds).then(result => {
						resolve(result);
					}).catch(err => {
						reject(err);
					});
				}				
			}).catch(error => {
				console.log('error :' + error);
				reject(error);
			});
		});
	}
	function onAttachGenerateCompletion(values, invoke, ds) {
		let tempVal = {'AttachmentIDSendStmt' : values['AttachmentIDSendStmt'],'StatementFormat':values['StatementFormat'],'ComposeEmail':values['ComposeEmail'],
			//-- Start | FIN-8509 | Changed by Ravi | 13-Oct-2025 --//
			'fileName': values['fileName']
			//-- Start | FIN-8509 | Changed by Ravi | 13-Oct-2025 --//
		};
		return new Promise(function (resolve, reject) {
			invoke({
				className: 'SendStatementAttachmentformation',
				functionName: 'Send Statement',
				values: tempVal
			}).then(result => {
				if (result) {
					values['AttachmentIDSendStmt'] = result.AttachmentIDSendStmt;
					values['ContentIDSendStmt'] = result.ContentIDSendStmt;
					values['SendStmtAttachmentContent'] = '';
					//values['ComposeEmail'] = result.ComposeEmail;
					resolve(values);
				}				
			}).catch(error => {
				console.log('error :' + error);
				reject(error);
			});
		});
	}

	function updateAllGrid(values, invoke, ds, fireEvent, lwcRef, rowData) {
		
		var arr = values['TransactionList'];
		
		var count = rowData['gogGridIndex'];
		var editfieldS = values['EditableField'].split(",")
		var  size = arr.length;
		
		for(var i = 0; i < parseInt(editfieldS.length) ; i++ ){
			var test2 = parseInt(editfieldS.length);
			var Fieldst= String(editfieldS[i]);
			// if(Fieldst != 'PromisedAmount') {
                if(arr[count][Fieldst] != null){
                    var RequiredValue = arr[count][Fieldst];
                        for(var k = 0; k < parseInt(size); k++){
								arr[k][Fieldst] = RequiredValue;
                    }    
				}
			// }
		}  
			values['TransactionList'] = arr; 
			return new Promise(function(resolve, error) {
			resolve(values);
		});
	}

	function onSubmitEmail(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum) {
		return new Promise(function(resolve, error) {
			fireEvent(cmp.pageRef, 'refreshActivity_ComposeMailFromAnonomusActivity_Activity');
			resolve(values);
		});
    }

	function onChangeNotifyCustomer(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum) {
		return new Promise(function(resolve, error) {
			if(values['notifyCustomer'] == true) {
				values['ContactMethod'] = 'Email';
				//START FIN-5784 BY ASERA
				// if(!values.hasOwnProperty('ContentIDSendStmt') && !values.hasOwnProperty('AttachmentIDSendStmt')) {
				// 	values['StatementFormat'] = "Excel";
				// 	values['AttachCheckBox']  =true;
				// 	// return new Promise(function(resolve, error) {
				// 	// gog.showFollowupDaysp2p(values, invoke, ds).then(result1 => {
				// 	gog.createStatementAttachmentonLoad(values, invoke, ds).then(result1 => {
				// 		var result = JSON.parse(JSON.stringify(result1));
				// 		delete result.enableSubmitButton;
				// 		resolve(result);
				// 	}).catch(err => {
				// 		reject(err);
				// 	});
				// }
				//END FIN-5784 BY ASERA
			} else {
				values['ContactMethod'] = null;
			}
			resolve(values);	
		});
	}

	function onChangePromiseAmount(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum) {
		var screenName = values['ggScreenName'];
		return new Promise(function(resolve, error) {
			//-- Start | FIN:5699 | Changes By Dilshad | 06 June 2024 --//
			let returnValues = {
				PromiseAmountGtZero: false,
				PromiseAmountNotGtInvoiceAmount: false
			};
			//-- Start | FIN:5699 | Changes By Dilshad | 06 June 2024 --//
			if(values.TransactionList[rowNum]['PromisedAmount'] <= 0 || values.TransactionList[rowNum]['PromisedAmount'] > values.TransactionList[rowNum]['celsrm__Amount__c']) {
				if(values.TransactionList[rowNum]['PromisedAmount'] <= 0){
					let transactionList = values.TransactionList;
					transactionList[rowNum]['PromisedAmount'] = 0;

					returnValues.TransactionList = transactionList;
					returnValues.PromiseAmountGtZero = 'true';
					fireEvent(cmp.pageRef, 'EnableRequiredDesign_TransactionListPromisedAmount[' + rowNum + ']_' + screenName, values);
				} else if(values.TransactionList[rowNum]['PromisedAmount'] > values.TransactionList[rowNum]['celsrm__Amount__c']){
					let transactionList = values.TransactionList;
					transactionList[rowNum]['PromisedAmount'] = 0;

					returnValues.TransactionList = transactionList;
					returnValues.PromiseAmountNotGtInvoiceAmount = 'true';
					fireEvent(cmp.pageRef, 'EnableRequiredDesign_TransactionListPromisedAmount[' + rowNum + ']_' + screenName, values);
				}
			}
			resolve(returnValues);	
		});
	}

	// function beforeSubmitpromiseToPay(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum) {
	// 	return new Promise(function(resolve, error) {
	// 		for(var index = 0; index < values.TransactionList.length; index++){
	// 			if(values.TransactionList[index]['PromisedAmount'] <= 0 || values.TransactionList[index]['PromisedAmount'] > values.TransactionList[index]['celsrm__Amount__c']) {
	// 				if(values.TransactionList[index]['PromisedAmount'] <= 0){
	// 					values.ggErrorMessage = 'Invoice ' + values.TransactionList[index]['nameSort'] + ' : Promised amount should not be less than or equal to 0';
	// 					values.stopExecution = true;
	// 					resolve(values);
	// 				} else if(values.TransactionList[index]['PromisedAmount'] > values.TransactionList[index]['celsrm__Amount__c']){
	// 					values.ggErrorMessage = 'Invoice ' + values.TransactionList[index]['nameSort'] + ' : Promised amount should not be greater than invoice amount';
	// 					values.stopExecution = true;
	// 					resolve(values);
	// 				}
	// 			}
	// 		}
	// 		if(!values.stopExecution){
	// 			resolve(values);
	// 		}
	// 	});
	// }

	// FIN-6708 | Sejal | 18 Nov 2024 | Changed parameter's name
	function onLoadPromiseReverseScreen(values, invoke, dataServiceObj, fireEvent, ref, rowValue, navigationMixin, ShowToastEvent) {
		return new Promise(function (resolve, reject) {
			dataServiceObj.invokeDataServiceWithName('ReversePrmoise', values, false).then(result => {
				console.log(result);
				ref.dispatchEvent(new ShowToastEvent({
					title: "Success",
					message: "Promise reversed successfully!",
					variant: "success",
					mode: "dismissable"
				}));
				gog.filterDataByView(values, invoke, dataServiceObj, fireEvent, ref).then(result1 => {
					var result = JSON.parse(JSON.stringify(result1));
					resolve(result);
				}).catch(err => {
					reject(err);
				});
			}).catch(error => {
				reject(error);
			});
		});
	}

	// << START - MM - FIN-8174 - Dynamic translated headers based account local | on Change Account Locale on Create P2P Screen>>
	function onChangeAccountLocale(values, invoke, dataServiceObj, fireEvent, cmp, rowvals, NavigationMixin, rowNum, ShowToastEvent) {
		debugger;
		return new Promise(function (resolve, reject) {
			if (values['accountLocale'] && values['accountLocale'] != null) {
				invoke({
					className: 'PromiseToPayActionController',
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
	// << END - MM - FIN-8174 - Dynamic translated headers based account local | on Change Account Locale on Create P2P Screen>>

	//-- Start | FIN-8525 | Changed by Asera | 14 Oct 2025 --//
	function onLoadCreatePromiseScreen(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, ShowToastEvent) {
		return new Promise(function (resolve, reject) {
			invoke({
				className: 'PromiseToPayActionController',
				functionName: 'onLoadPromiseToPay',
				values: values
			}).then(response => {
				let result = JSON.parse(JSON.stringify(response));
				
				if (result.hasOwnProperty('ggErrorMessage') && result.ggErrorMessage) {
					if(result.hasOwnProperty('activityData'))  {
						setTimeout(() => {
							fireEvent(cmp.pageRef, 'closeScreen_Promise To Pay', '');	
						}, 0);
					} else {
						setTimeout(() => {
							fireEvent(cmp.pageRef, 'onCancel_SRMTransactionGridScreen_Group1', '');
						}, 0);
					}
				}
				resolve(result);
			}).catch(error => {
				console.log('error :' + error);
				reject(error);
			});
		});
	}
	//-- Starts | FIN-7319 | Changed by Ravi | 16-Jun-2026 --//
	function SendMessageToSummary(values, invoke, dataServiceObj, fireEvent, ref, rowValue, navigationMixin, ShowToastEvent) {
		return new Promise(function (resolve, reject) {
			let message = {};
			message.repharseSummary = true;
			message.isUser = false;
			message.hasError = false;
			message.errorMessage = '';
			message.resultSummary = 'We have capture a promise and sent out a response on the email.';
			fireEvent(ref.pageRef, 'All Incoming Emails_SummaryAgent_ActivityForMyEmailsTab', message);
			resolve({});
		});
	}

	exports.SendMessageToSummary = SendMessageToSummary;
	//-- End | FIN-7319 | Changed by Ravi | 16-Jun-2026 --//
	exports.onLoadCreatePromiseScreen = onLoadCreatePromiseScreen;
	//-- End | FIN-8525 | Changed by Asera | 14 Oct 2025 --//
	exports.onSubmitEmail = onSubmitEmail;
	exports.changeStatementFormat = changeStatementFormat;
	exports.createStatementAttachment = createStatementAttachment;
	exports.showNoteBody = showNoteBody;
    exports.generateStatement = generateStatement;
	exports.updateAllGrid = updateAllGrid;
	exports.showFollowupDaysp2p = showFollowupDaysp2p;
	exports.showFollowUpDays = showFollowUpDays;
	exports.onAttachFormatCompletion = onAttachFormatCompletion;
	exports.onAttachGenerateCompletion = onAttachGenerateCompletion;
	exports.createStatementAttachmentonLoad = createStatementAttachmentonLoad;
	exports.onChangeNotifyCustomer = onChangeNotifyCustomer;
	exports.onChangePromiseAmount = onChangePromiseAmount;
	// exports.beforeSubmitpromiseToPay = beforeSubmitpromiseToPay;
	exports.onLoadPromiseReverseScreen = onLoadPromiseReverseScreen;
	// << START - MM - FIN-8174 - Dynamic translated headers based account local | on Change Account Locale on Create P2P Screen>>
	exports.onChangeAccountLocale = onChangeAccountLocale;
	// << START - MM - FIN-8174 - Dynamic translated headers based account local | on Change Account Locale on Create P2P Screen>>
    Object.defineProperty(exports, '__esModule', {
        value: true
    });

})));