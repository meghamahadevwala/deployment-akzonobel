//--- DO NOT CHANGE CODE | START ---//
(function (global, factory) {
	typeof exports === 'object' && typeof module !== 'undefined' ? factory(exports) :
		typeof define === 'function' && define.amd ? define(['exports'], factory) :
			(factory((global.gog = global.gog || {})));
}(this, (function (exports) {
	'use strict';

	var version = "1.0.0";
	//--- DO NOT CHANGE CODE | END ---//	

	function onExport(values, invoke, ds) {
		//--- Below is a sample code which execute user's apex class. ---//
		//var accId = values['Id'];
		var arr = values['TransactionList'];
		//var formatType = values['StatementFormat'];
		var trxnId = '';
		//var ListView = values['ListView'];
		return new Promise(function (resolve, reject) {
			var len = arr.length;
			if (arr && len > 0) {
				for (var i = 0; i < len; i++) {
					if (i == len - 1) {
						trxnId += arr[i].Id;
					} else {
						trxnId += arr[i].Id + ',';
					}
				}
				values['StatementFormat'] = 'Excel';
				values['trxnId'] = trxnId;
				gog.createStatementAttachmentexportAll(values, invoke, ds).then(result => {
					delete values.trxnId;
					var attId = result['AttachmentIDSendStmt'];
					var url = "/servlet/servlet.FileDownload?file=" + attId;
					window.open(url, '_blank');
					resolve({});
				}).catch(err => {
					reject(err);
				});
				//var url = '/apex/PreviewStatement?formatType='+formatType+'&accId='+accId+'&ListView='+ListView+'&txIds='+trxnId;
				//window.open(url,'_blank');
			}
		});
	}

	function onExportAll(values, invoke, ds) {

		//--- Below is a sample code which execute user's apex class. ---//
		//-- Start | FIN-8530 | Changed by Ravi | 10 Nov 2025 --//
		// var arr = values['ChildAccount'];
		// if (arr) {
		// 	let ids = '';
		// 	for (let a of arr) {
		// 		ids = ids + a.Id + ',';
		// 	}
		// 	values['childAccountId'] = ids;
		// }
		//-- End | FIN-8530 | Changed by Ravi | 10 Nov 2025 --//
		return new Promise(function (resolve, reject) {
			delete values.trxnId;
			values['StatementFormat'] = 'Excel';
			gog.createStatementAttachmentexportAll(values, invoke, ds).then(result => {
				//-- Start | FIN-8530 | Changed by Ravi | 10 Nov 2025 --//
				// delete values.childAccountId;
				//-- End | FIN-8530 | Changed by Ravi | 10 Nov 2025 --//
				var attId = result['AttachmentIDSendStmt'];
				var url = "/servlet/servlet.FileDownload?file=" + attId;
				window.open(url, '_blank');
				resolve({});
			}).catch(err => {
				reject(err);
			});
			//resolve(values);
		});
	}
	function ExportPdfAll(values, invoke, ds) {

		//--- Below is a sample code which execute user's apex class. ---//
		//-- Start | FIN-8530 | Changed by Ravi | 10 Nov 2025 --//
		// var arr = values['ChildAccount'];
		// if (arr) {
		// 	let ids = '';
		// 	for (let a of arr) {
		// 		ids = ids + a.Id + ',';
		// 	}
		// 	values['childAccountId'] = ids;
		// }
		//-- End | FIN-8530 | Changed by Ravi | 10 Nov 2025 --//
		return new Promise(function (resolve, reject) {
			delete values.trxnId;
			values['StatementFormat'] = 'PDF';
			gog.createStatementAttachmentexportAll(values, invoke, ds).then(result => {
				//-- Start | FIN-8530 | Changed by Ravi | 10 Nov 2025 --//
				// delete values.childAccountId;
				//-- End | FIN-8530 | Changed by Ravi | 10 Nov 2025 --//
				var attId = result['AttachmentIDSendStmt'];
				var url = "/servlet/servlet.FileDownload?file=" + attId;
				window.open(url, '_blank');
				resolve({});
			}).catch(err => {
				reject(err);
			});
			//resolve(values);
		});
	}

	function createStatementAttachmentexportAll(values, invoke, ds) {
		return new Promise(function (resolve, reject) {
			invoke({
				className: 'SendStatementOnAccount',
				functionName: 'exportAll',
				values: values
			}).then(result1 => {
				var result = JSON.parse(JSON.stringify(result1));
				if (result) {
					var TotalBalance = 0;

					var newLst = result.DueTransList;
					var newLstFields = result.selectedFields;
					var newLstFieldsLabel = result.selectedFieldsLabel;
					var htmlBody;
					var pg = 0;
					var pageBreakAfter = 45;
					htmlBody = "<html><head><style> #txSummaryTableJS td{font-size:10px; text-align:left;  width:auto; border: solid 1px gray;padding-left: 3px;  padding-right: 3px;  white-space:nowrap;  font-family: verdana;}  #txSummaryTableJS th{ font-size:12px; background-color:#3d79eb;color:White;border:1px solid gray;text-align: left;padding: 6px 6px 6px 3px;}  #txSummaryTableJS {border-collapse:collapse;padding:0px;border:1px solid gray; font-family: verdana;}  @page {size:landscape; }</style></head><body>";

					htmlBody += "<table width='100%' id='txSummaryTableJS'><tr>";

					for (let i = 0; i < newLstFieldsLabel.length; i++) {
						htmlBody += "<th><b>" + newLstFieldsLabel[i] + "</b></th>";

					}


					htmlBody += "</tr>";
					for (let i = 0; i < newLst.length; i++) {
						if (pg == pageBreakAfter && values['StatementFormat'] == 'PDF') {
							htmlBody += "</table>";
							htmlBody += "<br>";
							htmlBody += "<table width='100%' id='txSummaryTableJS'><tr style='page-break-before:always;'>";
							for (let i = 0; i < newLstFieldsLabel.length; i++) {
								htmlBody = htmlBody + "<th><b>" + newLstFieldsLabel[i] + "</b></th>";

							}
							htmlBody += "</tr>";
							pg = 0;
							pageBreakAfter = 45;
						}
						pg = pg + 1;
						htmlBody += "<tr>";
						for (let j = 0; j < newLstFields.length; j++) {
							var fieldName = newLstFields[j];
							var fieldValue = "";
							if (fieldName.includes('__c')) {
								if (newLst[i][fieldName.substring(0, fieldName.length - 1) + 'r']) {
									fieldValue = newLst[i][fieldName.substring(0, fieldName.length - 1) + 'r'].Name;
								} else if (newLst[i][fieldName] != undefined) {
									fieldValue = newLst[i][fieldName];
								} else {
									fieldValue = "";
								}
							} else {
								if (newLst[i][fieldName.substring(0, fieldName.length - 2)]) {
									fieldValue = newLst[i][fieldName.substring(0, fieldName.length - 2)].Name;
								} else if (newLst[i][fieldName] != undefined) {
									fieldValue = newLst[i][fieldName];
								} else {
									fieldValue = "";
								}
							}

							htmlBody += "<td>" + fieldValue + "</td>";

						}
						htmlBody += "</tr>";
						var newAmt = newLst[i].celsrm__Balance__c == null ? 0 : newLst[i].celsrm__Balance__c;
						TotalBalance = TotalBalance + newAmt;

					}
					//htmlBody += "<tr>";
					//htmlBody += "<td colspan='" + newLstFields.length + "' > <b> Total</b>  $" + TotalBalance.toFixed(2) + "</td>";
					//htmlBody += "</tr>";
					htmlBody += "</table></body></html>";
					console.log("htmlBody" + htmlBody);

					var temp = window.btoa(unescape(encodeURIComponent(htmlBody)));
					values['SendStmtAttachmentContent'] = temp;

					gog.onAttachFormatCompletionexportAll(values, invoke, ds).then(result1 => {
						var result = JSON.parse(JSON.stringify(result1));
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

	function onAttachFormatCompletionexportAll(values, invoke, ds) {
		let tempVal = { 'finalContent': values['SendStmtAttachmentContent'], 'StatementFormat': values['StatementFormat'] };
		return new Promise(function (resolve, reject) {
			invoke({
				className: 'SendStatementAttachmentInsert',
				functionName: 'Send Statement',
				values: tempVal
			}).then(result => {
				if (result) {
					values['AttachmentIDSendStmt'] = result.AttachmentIDSendStmt;
					gog.onAttachGenerateCompletionexportAll(values, invoke, ds).then(result => {
						resolve(result);
						delete values.finalContent;
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
	function onAttachGenerateCompletionexportAll(values, invoke, ds) {
		let tempVal = { 
			'AttachmentIDSendStmt': values['AttachmentIDSendStmt'], 
			'StatementFormat': values['StatementFormat'], 
			'ComposeEmail': values['ComposeEmail'],
			'ContentIDSendStmt':values['ContentIDSendStmt'],
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
					resolve(values);
				}
			}).catch(error => {
				console.log('error :' + error);
				reject(error);
			});
		});
	}

	// function onchangeVendor(values, invoke) {
	// 	values.InvoiceNo = 'INV-1';
	// 	//--- Below is a sample code which execute user's apex class. ---//
	// 	return new Promise(function (resolve, error) {
	// 		invoke({
	// 			className: 'GOGCustomImplementation',
	// 			functionName: 'funcName',
	// 			values: values
	// 		}).then(result1 => {
	// 			var result = JSON.parse(JSON.stringify(result1));
	// 			resolve(result);
	// 		}).catch(error => {
	// 			console.log('error :' + error);
	// 			reject(error);
	// 		});

	// 	});
	// }
	// function SearchProperty(values, invoke) {
	// 	console.log("====SearchProperty=====");
	// 	values['datagrid'] = [{
	// 		id: 'a',
	// 		opportunityName: 'Cloudhub',
	// 		confidence: 0.2,
	// 		amount: 30000,
	// 		contact: 'jrogers@cloudhub.com',
	// 		phone: '2352235235',
	// 		trendIcon: 'utility:down'
	// 	}];
	// 	return new Promise(function (resolve, error) {
	// 		resolve(values);

	// 	});
	// }

	// function resetPropertySearch(values, invoke, dataServiceObj) {
	// 	return new Promise(function (resolve, reject) {
	// 		dataServiceObj.invokeDataServiceWithId('a00p0000007ofnSAAQ', values, false).then(result => {
	// 			var newdata = [];
	// 			console.log("JSON.parse(JSON.stringify(result)):" + JSON.stringify(result));
	// 			if (Array.isArray(JSON.parse(JSON.stringify(result)))) {
	// 				newdata = JSON.parse(JSON.stringify(result));
	// 			} else {
	// 				if (!this.isEmptyObject(result)) {
	// 					newdata.push(JSON.parse(JSON.stringify(result)));
	// 				}
	// 			}
	// 			values['datagrid'] = newdata;
	// 			//for (var fieldname in result) {
	// 			//	this.values[fieldname] = result[fieldname];
	// 			//}
	// 			resolve(values);
	// 		}).catch(error => {
	// 			console.log('error :' + error);
	// 			reject(error);
	// 		});

	// 	});
	// }
	function generateStatementFromTransactionGrid(values, invoke, dataServiceObj) {
		//var accId = values['Id'];
		var arr = values['TransactionList'];
		//var formatType = values['StatementFormat'];
		//var formatType = 'PDF';
		var trxnId = '';
		//var ListView = values['ListView'];
		return new Promise(function (resolve, reject) {
			var len = arr.length;
			if (arr && len > 0) {
				for (var i = 0; i < len; i++) {
					if (i == len - 1) {
						trxnId += arr[i].Id;
					} else {
						trxnId += arr[i].Id + ',';
					}
				}
				values['StatementFormat'] = 'PDF';
				values['trxnId'] = trxnId;
				gog.createStatementAttachmentexportAll(values, invoke, dataServiceObj).then(result => {
					delete values.trxnId;
					var attId = result['AttachmentIDSendStmt'];
					var url = "/servlet/servlet.FileDownload?file=" + attId;
					window.open(url, '_blank');
					resolve({});
				}).catch(err => {
					reject(err);
				});
				//var url = '/apex/PreviewStatement?formatType='+formatType+'&accId='+accId+'&ListView='+ListView+'&txIds='+trxnId;
				//window.open(url,'_blank');
			}


		});
	}
	function getBillingAddress(values, invoke, dataServiceObj) {
		return new Promise(function (resolve, reject) {
			dataServiceObj.invokeDataServiceWithId('a001U000006A2OwQAK', values, true).then(result1 => {
				console.log("JSON.parse(JSON.stringify(result)):" + JSON.stringify(result));
				var result = JSON.parse(JSON.stringify(result1));
				for (var fieldname in result) {
					values[fieldname] = result[fieldname];
				}
				resolve(values);
			}).catch(error => {
				console.log('error :' + error);
				reject(error);
			});

		});
	}

	// function onPageLoadSetView_old(values, invoke, dataServiceObj, fireEvent, ref) {
	// 	//console.log('values>>>>>'+JSON.stringify(values));
	// 	var screenName = values['ggScreenName'];
	// 	return new Promise(function (resolve, reject) {
	// 		invoke({
	// 			className: 'defaultViewClass',
	// 			functionName: 'funcName',
	// 			values: values
	// 		}).then(result1 => {
	// 			//resolve(result);
	// 			var result = JSON.parse(JSON.stringify(result1));
	// 			if (result['ListView']) {
	// 				if (result.l_values.length > 0) {
	// 					for (let tempVal of result.l_values) {
	// 						for (let tempfield of result.updatedColumns) {
	// 							if (tempfield.type == 'text' && tempVal[tempfield.fieldName] != null && tempVal[tempfield.fieldName] != undefined) {
	// 								if (tempVal[tempfield.fieldName].includes("\n")) {
	// 									tempVal[tempfield.fieldName] = tempVal[tempfield.fieldName].replace(/\n/g, '&nbsp');
	// 								}
	// 							}
	// 							if (tempfield.fieldName == 'Name') {
	// 								tempVal.invoiceNo = tempVal.Name;
	// 								tempVal.nameSort = tempVal.Name;
	// 								let key = '<a href="' + '/' + tempVal['Id'] + '"' + ' target="_blank">' + tempVal['Name'] + '</a>';
	// 								tempVal.Name = key;

	// 							} else if (tempfield.fieldName == 'celsrm__Notes__c') {

	// 								if (tempVal['celsrm__Notes__c'] == undefined) {

	// 									tempVal.celsrm__Notes__c = "";
	// 									tempVal.celsrm__Notes_sort__c = "";
	// 								} else {
	// 									tempVal.celsrm__Notes_sort__c = tempVal['celsrm__Notes__c'];
	// 									var tempNt = tempVal['celsrm__Notes__c'].replace('"', '&quot;');
	// 									var notesVal = tempNt;

	// 									//if(tempNt.length > 30)
	// 									//notesVal  = tempNt.substring(0,20)+'...';
	// 									let key = '<img src="/resource/NotesIcon" target="_blank" width="15" height="15" title=\"' + tempNt + '\">' + '<a ' + ' style="text-decoration: none;cursor: pointer; cursor: hand;" title=\"' + tempNt + '\" >' + notesVal + '</a>' + '</img>';
	// 									tempVal.celsrm__Notes__c = key;
	// 								}
	// 							} else if (tempfield.fieldName == 'celsrm__Flag__c') {

	// 								let imageUrl = '';
	// 								let date = new Date();

	// 								console.log('tempVal::' + JSON.stringify(tempVal));
	// 								if (tempVal['celsrm__Disputed_Amount__c'] && tempVal['celsrm__Disputed_Amount__c'] != 0) {
	// 									imageUrl = "<img src='/resource/celsrm__SRMResource/image/red.png' title='Disputed' alt='Disputed' width='16' height='16'>";
	// 								} else {
	// 									imageUrl = "<img src='/resource/celsrm__SRMResource/image/transparent.png' title='' alt='' width='16' height='16'>";
	// 								}
	// 								if (tempVal['celsrm__Promise_Date__c']) {
	// 									let d = new Date(tempVal['celsrm__Promise_Date__c']);
	// 									if (tempVal['celsrm__Is_Broken_Promise__c'] && tempVal['celsrm__Is_Broken_Promise__c'] == true) {
	// 										imageUrl += "<img src='/resource/celsrm__SRMResource/image/BrokenPromise$.png' title='Broken Promise' alt='Broken Promise' width='16' height='16'>";
	// 									} else if (tempVal['celsrm__Promised_Amount__c'] && tempVal['celsrm__Promised_Amount__c'] != 0) {
	// 										imageUrl += "<img src='/resource/celsrm__SRMResource/image/Promise$.png' title='Promised' alt='Promised' width='16' height='16'>";
	// 									}

	// 								}

	// 								tempVal['celsrm__Flag__c'] = imageUrl;
	// 							} else if (result.refField.indexOf(tempfield.fieldName) !== (-1)) {
	// 								let st = tempfield.fieldName.substring(0, tempfield.fieldName.length - 1) + 'r';
	// 								let tempmap = tempVal[st];
	// 								if (tempmap !== undefined && tempmap !== null) {
	// 									let key = '<a href="' + '/' + tempVal[tempfield.fieldName] + '"' + ' target="_blank">' + tempmap['Name'] + '</a>';
	// 									tempVal[tempfield.fieldName] = key;
	// 								}

	// 							}
	// 						}
	// 					}
	// 				}
	// 				fireEvent(ref.pageRef, 'TransactionList_' + screenName + '_Columns', result.updatedColumns);
	// 				fireEvent(ref.pageRef, 'TransactionList_' + screenName, result.l_values);
	// 				//result['TransactionList'] = '';
	// 				delete result.updatedColumns;
	// 				delete result.l_values;
	// 				result.Total = '<b> {Label.Total_Balance} : 0.00 </b>';
	// 				result.totalSelectedinvoice = '<b>' + '{Label.Selected_Invoices} : 0 </b>';
	// 				resolve(result);
	// 			}

	// 		}).catch(error => {
	// 			console.log('error :' + error);
	// 			reject(error);
	// 		});
	// 	});
	// }

	function onPageLoadSetView(values, invoke, dataServiceObj, fireEvent, ref) {
		//console.log('values>>>>>'+JSON.stringify(values));
		var screenName = values['ggScreenName'];
		//-- Start | FIN-8530 | Changed by Ravi | 10 Nov 2025 --//
		sessionStorage.removeItem('selectedAccountIds');
		console.log('Session storage cleared on refresh');
		sessionStorage.removeItem('refreshing');
		values['accountHierarchyChildIds'] = null;
		//-- End | FIN-8530 | Changed by Ravi | 10 Nov 2025 --//
		return new Promise(function (resolve, reject) {
			invoke({
				className: 'defaultViewClass',
				functionName: 'getDefaultView',
				values: values
			}).then(result1 => {
				//resolve(result);
				var result = JSON.parse(JSON.stringify(result1));
				if (result['ListView']) {
					// fireEvent(ref.pageRef, 'TransactionList_' + screenName + '_Columns', result.updatedColumns);
					// fireEvent(ref.pageRef, 'TransactionList_' + screenName, result.l_values);

					let paramMap = {
						columns: result.updatedColumns,
						values: result.l_values,
						onChangeMethodName: 'filterDataByView'
						};
					fireEvent(ref.pageRef, 'SetDataInDataGrid_' + screenName + '_TransactionList', paramMap);
					//result['TransactionList'] = '';
					delete result.updatedColumns;
					delete result.l_values;
					result.Total = '<b> {Label.Total_Balance} : 0.00 </b>';
					result.totalSelectedinvoice = '<b>' + '{Label.Selected_Invoices} : 0 </b>';
					//-- Start | FIN-8530 | Changed by Ravi | 10 Nov 2025 --//
					result['accountHierarchyChildIds'] = null;
					//-- End | FIN-8530 | Changed by Ravi | 10 Nov 2025 --//
					resolve(result);
				}

			}).catch(error => {
				console.log('error :' + error);
				reject(error);
			});
		});
	}

	// function filterDataByView_old(values, invoke, dataServiceObj, fireEvent, ref) {

	// 	console.log('values>>>>>' + values);
	// 	var screenName = values['ggScreenName'];
	// 	var userCurrency = values['userCurrency'];
	// 	var arr = values['ChildAccount'];
	// 	if (arr) {
	// 		let ids = '';
	// 		for (let a of arr) {
	// 			ids = ids + a.Id + ',';
	// 		}
	// 		values['childAccountId'] = ids;
	// 	}
	// 	values['TransactionList'] = null;
	// 	//if(values['ListView']) {
	// 	return new Promise(function (resolve, reject) {
	// 		if (values['ListView'] && values['ListView'] !== null && values['ListView'] !== '') {
	// 			invoke({
	// 				className: 'SearchClass',
	// 				functionName: 'funcName',
	// 				values: values
	// 			}).then(result1 => {
	// 				//resolve(result);
	// 				var result = JSON.parse(JSON.stringify(result1));
	// 				delete values.childAccountId;
	// 				if (result.l_values.length > 0) {
	// 					for (let tempVal of result.l_values) {
	// 						for (let tempfield of result.updatedColumns) {
	// 							if (tempfield.type == 'text' && tempVal[tempfield.fieldName] != null && tempVal[tempfield.fieldName] != undefined) {
	// 								if (tempVal[tempfield.fieldName].includes("\n")) {
	// 									tempVal[tempfield.fieldName] = tempVal[tempfield.fieldName].replace(/\n/g, '&nbsp');
	// 								}
	// 							}
	// 							if (tempfield.fieldName == 'Name') {
	// 								tempVal.invoiceNo = tempVal.Name;
	// 								tempVal.nameSort = tempVal.Name;
	// 								let key = '<a href="' + '/' + tempVal['Id'] + '"' + ' target="_blank">' + tempVal['Name'] + '</a>';
	// 								tempVal.Name = key;
	// 							} else if (tempfield.fieldName == 'celsrm__Notes__c') {
	// 								if (tempVal['celsrm__Notes__c'] == undefined) {
	// 									tempVal.celsrm__Notes_sort__c = "";
	// 									tempVal.celsrm__Notes__c = "";
	// 								} else {
	// 									tempVal.celsrm__Notes_sort__c = tempVal['celsrm__Notes__c'];
	// 									var tempNt = tempVal['celsrm__Notes__c'].replace('"', '&quot;');
	// 									var notesVal = tempNt;

	// 									//if(tempNt.length > 30)
	// 									//notesVal  = tempNt.substring(0,20)+'...';
	// 									let key = '<img src="/resource/NotesIcon" target="_blank" width="15" height="15" title=\"' + tempNt + '\">' + '<a ' + ' style="text-decoration: none;cursor: pointer; cursor: hand;" title=\"' + tempNt + '\" >' + notesVal + '</a>' + '</img>';
	// 									tempVal.celsrm__Notes__c = key;
	// 								}

	// 							} else if (tempfield.fieldName == 'celsrm__Flag__c') {

	// 								let imageUrl = '';
	// 								let date = new Date();

	// 								if (tempVal['celsrm__Disputed_Amount__c'] && tempVal['celsrm__Disputed_Amount__c'] != 0) {
	// 									imageUrl = "<img src='/resource/celsrm__SRMResource/image/red.png' title='Disputed' alt='Disputed' width='16' height='16'>";
	// 								} else {
	// 									imageUrl = "<img src='/resource/celsrm__SRMResource/image/transparent.png' title='' alt='' width='16' height='16'>";
	// 								}
	// 								if (tempVal['celsrm__Promise_Date__c']) {
	// 									let d = new Date(tempVal['celsrm__Promise_Date__c']);
	// 									if (tempVal['celsrm__Is_Broken_Promise__c'] && tempVal['celsrm__Is_Broken_Promise__c'] == true) {
	// 										imageUrl += "<img src='/resource/celsrm__SRMResource/image/BrokenPromise$.png' title='Broken Promise' alt='Broken Promise' width='16' height='16'>";
	// 									} else if (tempVal['celsrm__Promised_Amount__c'] && tempVal['celsrm__Promised_Amount__c'] != 0) {
	// 										imageUrl += "<img src='/resource/celsrm__SRMResource/image/Promise$.png' title='Promised' alt='Promised' width='16' height='16'>";
	// 									}

	// 								}

	// 								tempVal['celsrm__Flag__c'] = imageUrl;
	// 							} else if (result.refField.indexOf(tempfield.fieldName) !== (-1)) {
	// 								let st = tempfield.fieldName.substring(0, tempfield.fieldName.length - 1) + 'r';
	// 								let tempmap = tempVal[st];
	// 								if (tempmap !== undefined && tempmap !== null) {
	// 									let key = '<a href="' + '/' + tempVal[tempfield.fieldName] + '"' + ' target="_blank">' + tempmap['Name'] + '</a>';
	// 									tempVal[tempfield.fieldName] = key;
	// 								}
	// 							}
	// 						}
	// 					}
	// 				}
	// 				fireEvent(ref.pageRef, 'TransactionList_' + screenName + '_Columns', result.updatedColumns);
	// 				fireEvent(ref.pageRef, 'TransactionList_' + screenName, result.l_values);
	// 				var finalText = '<b> {Label.Total_Balance} : 0.00 </b>';
	// 				var totalSelectedinvoice = '<b>' + '{Label.Selected_Invoices} : 0 </b>';
	// 				resolve({ 'Total': finalText, 'totalSelectedinvoice': totalSelectedinvoice, 'isCurrentUserListView': result.isCurrentUserListView, 'TransactionList': [] });
	// 			}).catch(error => {
	// 				console.log('error :' + error);
	// 				reject(error);
	// 			});
	// 		} else {
	// 			resolve(values);
	// 		}
	// 	});
	// 	//}		
	// }

	function filterDataByView(values, invoke, dataServiceObj, fireEvent, ref) {

		console.log('values>>>>>' + values);
		var screenName = values['ggScreenName'];
		var userCurrency = values['userCurrency'];
		//-- Start | FIN-8530 | Changed by Ravi | 10 Nov 2025 --//
		// var arr = values['ChildAccount'];
		// if (arr) {
		// 	let ids = '';
		// 	for (let a of arr) {
		// 		ids = ids + a.Id + ',';
		// 	}
		// 	values['childAccountId'] = ids;
		// }
		//-- End | FIN-8530 | Changed by Ravi | 10 Nov 2025 --//
		values['TransactionList'] = null;
		//if(values['ListView']) {
		return new Promise(function (resolve, reject) {
			if (values['ListView'] && values['ListView'] !== null && values['ListView'] !== '') {
				invoke({
					className: 'defaultViewClass',
					functionName: 'onChangeView',
					values: values
				}).then(result1 => {
					var result = JSON.parse(JSON.stringify(result1));
					//-- Start | FIN-8530 | Changed by Ravi | 10 Nov 2025 --//
					// delete values.childAccountId;
					//-- End | FIN-8530 | Changed by Ravi | 10 Nov 2025 --//
					// fireEvent(ref.pageRef, 'TransactionList_' + screenName + '_Columns', result.updatedColumns);
					// fireEvent(ref.pageRef, 'TransactionList_' + screenName, result.l_values);
					let paramMap = {
						columns: result.updatedColumns,
						values: result.l_values,
						onChangeMethodName: 'filterDataByView'
						};
					fireEvent(ref.pageRef, 'SetDataInDataGrid_' + screenName + '_TransactionList', paramMap);
					
					var finalText = '<b> {Label.Total_Balance} : 0.00 </b>';
					var totalSelectedinvoice = '<b>' + '{Label.Selected_Invoices} : 0 </b>';
					//-- Start | FIN-8530 | Changed by Ravi | 10 Nov 2025 --//
					let resolveResult = { 'Total': finalText, 'totalSelectedinvoice': totalSelectedinvoice, 'isCurrentUserListView': result.isCurrentUserListView, 'TransactionList': [] };
					if (result.childAccountNames) {
						resolveResult.enableChildNotes = 'true';
						resolveResult.childAccountNotes = '<div id="accountBanner" style="background-color:#e3f2fd; color:#0d47a1; border:1px solid #90caf9; border-radius:8px;padding:0px 20px; width:fit-content; box-shadow:0 2px 6px rgba(0,0,0,0.15);font-size:15px; display:flex; justify-content:space-between; align-items:center;"><span><strong>Included Child Accounts: </strong>' + result.childAccountNames + '</span><span class="closeChildAccount" style="cursor:pointer; font-size:20px; font-weight:bold; margin-left:12px; color:#0d47a1;">×</span></div>';
						// resolveResult.childAccountNotes = 'Include child Accounts: ' + result.childAccountNames;	
					} else {
						resolveResult.enableChildNotes = 'false';
						resolveResult.childAccountNotes = '';
					}
					resolve(resolveResult);
					//-- End | FIN-8530 | Changed by Ravi | 10 Nov 2025 --//
				}).catch(error => {
					console.log('error :' + error);
					reject(error);
				});
			} else {
				resolve(values);
			}
		});
		//}		
	}
	//-- Start | FIN-8530 | Changed by Ravi | 10 Nov 2025 --//
	function removeChildAccount(values, invoke, dataServiceObj, fireEvent, ref) {
		debugger;
		console.log('values>>>>>' + values);
		return new Promise(function (resolve, reject) {
			if(values.buttonClassListchildAccountNotes && values.buttonClassListchildAccountNotes.contains('closeChildAccount')) {
				sessionStorage.removeItem('selectedAccountIds');
				values['accountHierarchyChildIds'] = null;
				var onchangeMap = {
					"onChangeMethod": 'filterDataByViewDispute',
					"accountHierarchyChildIds": null,
					"enableChildNotes": 'false',
					"childAccountNotes": ''
				};
				fireEvent(ref.pageRef, 'refreshValues_Disputes On Account', onchangeMap);
				gog.filterDataByView(values, invoke, dataServiceObj, fireEvent, ref).then(result1 => {
					var result = JSON.parse(JSON.stringify(result1));
					result.accountHierarchyChildIds = null;
					result.enableChildNotes = 'false';
					result.childAccountNotes = '';
					resolve(result);
				}).catch(err => {
					reject(err);
				});
			} else {
				resolve({});
			}
		});
	}
	//-- End | FIN-8530 | Changed by Ravi | 10 Nov 2025 --//
	function filterDataByAging(values, invoke, dataServiceObj, fireEvent, ref) {
		//--- Below is a sample code which execute data service and will fireEvent. ---//
		try {
			var filterValues = {};
			var screenName = values['ggScreenName'];
			return new Promise(function (resolve, reject) {
				dataServiceObj.invokeDataServiceWithName('OTCFetchTransactionExtract', values, false).then(result => {
					console.log(result);
					/*var newdata = [];
					if (Array.isArray(result)) {
						newdata = JSON.parse(JSON.stringify(result));
					} else {
						
						var isEmptyObject = true;
						for (var key in result) {
							if (obj.hasOwnProperty(key)) isEmptyObject = false;
						}
						if (!isEmptyObject) {
							newdata.push(JSON.parse(JSON.stringify(result)));
						}
					}*/
					fireEvent(ref.pageRef, 'TransactionList_' + screenName, result);
					resolve({});
				}).catch(error => {
					reject(error);
				});
			});
		} catch (ex) {
			reject(ex.stack);
		}
	}
	function editListView(values, invoke, dataServiceObj, fireEvent, ref) {
		if (values.isCurrentUserListView) {
			return new Promise(function (resolve, reject) {
				let customChangeHandler = {
					"callingControlName": "Button Group1",
					"targetScreen": "LIstViewEdit",
					"targetScreenSize": "medium-width",
					"sourceControlName": "ListView",
					"vals": values
				};
				fireEvent(ref.pageRef, 'openChildScreen_' + ref.additionalAttributes.screenName + "Button Group1", customChangeHandler);
				resolve({});
			});
		} else {
			return new Promise(function (resolve, reject) {
				let error = 'You can not edit this view';
				reject(error);
			});
		}
	}
	function deleteListView(values, invoke, dataServiceObj, fireEvent, ref) {
		debugger;
		if (values.isCurrentUserListView) {
			if (confirm('Are you sure?')) {
				return new Promise(function (resolve, reject) {
					invoke({
						className: 'DeleteListView',
						functionName: '',
						values: values
					}).then(result => {
						result = JSON.parse(JSON.stringify(result));
						var listview = result.ListView;
						gog.filterDataByView(result, invoke, dataServiceObj, fireEvent, ref).then(result1 => {
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
				return new Promise(function (resolve, error) {
					resolve({});
				});
			}
		} else {
			return new Promise(function (resolve, reject) {
				let error = 'You can not delete this view';
				reject(error);
			});
		}

	}

	function calculateTotalAmountTransaction(values, invoke, dataServiceObj, fireEvent, ref) {
		return new Promise(function (resolve, error) {
			try {

				var finalText = '';
				var totalSelectedinvoice = '';
				var isMultiCurrency = values['isMultiCurrency'];
				var userCurrency = values['userCurrency'];
				if (values['TransactionList'] !== undefined && values['TransactionList'] !== null && values['TransactionList'].length > 0) {
					var trxnLst = values['TransactionList'];
					var len = trxnLst.length;
					var amount = {};
					if (isMultiCurrency) {
						//TODO
						for (var i = 0; i < len; i++) {
							// << START - MM - CBE-51387 - Sum of selected transactions is not calculating correctly when there are multiple currencies >>
							let balance = trxnLst[i]['celsrm__Balance__c'] ? Number(trxnLst[i]['celsrm__Balance__c']) : 0;
							// << END - MM - CBE-51387 - Sum of selected transactions is not calculating correctly when there are multiple currencies >>
							if (trxnLst[i]['CurrencyIsoCode'] in amount) {
								// << START - MM - CBE-51387 - Sum of selected transactions is not calculating correctly when there are multiple currencies >>
								// amount[trxnLst[i]['CurrencyIsoCode']] += trxnLst[i]['celsrm__Balance__c'];
								amount[trxnLst[i]['CurrencyIsoCode']] += balance;
								// << END - MM - CBE-51387 - Sum of selected transactions is not calculating correctly when there are multiple currencies >>
							} else {
								// << START - MM - CBE-51387 - Sum of selected transactions is not calculating correctly when there are multiple currencies >>
								// amount[trxnLst[i]['CurrencyIsoCode']] = trxnLst[i]['celsrm__Balance__c'];
								amount[trxnLst[i]['CurrencyIsoCode']] = balance;
								// << END - MM - CBE-51387 - Sum of selected transactions is not calculating correctly when there are multiple currencies >>
							}
						}
						var str = '';
						for (var k in amount) {
							str += k + ' ' + parseFloat(amount[k]).toFixed(2).replace(/(\d)(?=(\d{3})+\.)/g, '$1,') + ' | ';
						}
						if (str != '') {
							str = str.substring(0, str.length - 3);
						}
						totalSelectedinvoice = '<b>' + '{Label.Selected_Invoices} : ' + len.toLocaleString() + '</b>';
						finalText = '<b> {Label.Total_Balance} : ' + str + '</b>';
					} else {
						var tmp = 0.0;
						for (var i = 0; i < len; i++) {
							tmp += trxnLst[i]['celsrm__Balance__c'] ? trxnLst[i]['celsrm__Balance__c'] : 0;
						}
						totalSelectedinvoice = '<b>' + '{Label.Selected_Invoices} : ' + len.toLocaleString() + '</b>';
						finalText = '<b>  {Label.Total_Balance} : ' + userCurrency + ' ' + parseFloat(tmp).toFixed(2).replace(/(\d)(?=(\d{3})+\.)/g, '$1,') + '</b>';
					}
				} else {
					totalSelectedinvoice = '<b>' + '{Label.Selected_Invoices} : 0 </b>';
					finalText = '<b> {Label.Total_Balance} : 0.00 </b>';
				}
				resolve({ 'Total': finalText, 'totalSelectedinvoice': totalSelectedinvoice });
			} catch (error) {
				console.error("Error:" + error);
			}
		});
	}
	function OnChangeViewCreate(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum) {
		debugger;
		var ListViewName = values["ListView"];
		return new Promise(function (resolve, error) {
			// window.location.reload(true);
			if(!values['ListViewEditMode'] && values['selectedListViewOption']){
				fireEvent(cmp.pageRef, 'addPicklistOption_'+ values.ggScreenName +'_ListView', values['selectedListViewOption']);
			}
			if(ListViewName){
            gog.filterDataByView(values, invoke, ds, fireEvent, cmp);
         }
			resolve(values);
		});


	}
	function openNoteScreen(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum) {
		debugger;
		return new Promise(function (resolve, reject) {
			//fireEvent(cmp.pageRef, 'TransactionList_Notes', rowValue);
			var rowdata = JSON.parse(JSON.stringify(rowValue));
			rowdata.enableSubmitButton = false;
			let customChangeHandler = {
				"callingControlName": "TransactionList",
				"targetScreen": "Notes",
				"targetScreenSize": "small-width",
				"sourceControlName": '',
				"vals": rowdata
			};
			fireEvent(cmp.pageRef, 'openChildScreen_' + 'WCMTransactionGridScreen' + "TransactionList", customChangeHandler);
			resolve(values);
		}).catch(error => {
			reject(error);
		});
	}
	//-- This method will reverse promise to pay from transaction --//
	function reversePromise(values, invoke, dataServiceObj, fireEvent, cmp, rowvals, NavigationMixin, rowNum, ShowToastEvent) {
		let ggScreenName = values['ggScreenName'];
		return new Promise(function (resolve, reject) {
			invoke({
				className: 'AccountActionController',
				functionName: 'reversePromiseToPay',
				values: values
			}).then(result => {
				if (result.ggErrorMessage) {
					gog.showToast('Error', result.ggErrorMessage, 'error', 'dismissable', cmp, ShowToastEvent);
				} else {
					//fireEvent(cmp.pageRef, 'refreshDataGrid_' + ggScreenName + '_TransactionList', null);
					gog.showToast('Success', result.ggSuccessMessage, 'success', 'dismissable', cmp, ShowToastEvent);
					gog.filterDataByView(values, invoke, dataServiceObj, fireEvent, cmp);
				}
				resolve({});
			}).catch(error => {
				console.log('error :' + error);
				reject(error);
			});

		});
	}
	function reverseDispute(values, invoke, dataServiceObj, fireEvent, ref, rowvals, NavigationMixin, rowNum, ShowToastEvent) {
		var trxnLst = JSON.parse(JSON.stringify(values['TransactionList']));
		var showError = true;
		for (let trx of trxnLst) {
			if (trx.celsrm__Disputed_Amount__c != 0) {
				showError = false;
				break;
			}
		}
		if (showError) {
			return new Promise(function (resolve, reject) {
				ref.dispatchEvent(new ShowToastEvent({
					title: "Error",
					message: "There is no dispute created for one or more selected Invoice(s)",
					variant: "error",
					mode: "dismissable"
				}));
				resolve({});
			});
		} else {
			return new Promise(function (resolve, reject) {
				let customChangeHandler = {
					"callingControlName": "Group1",
					"targetScreen": "ReverseDispute",
					"targetScreenSize": "medium-width",
					"sourceControlName": '',
					"vals": values
				};
				fireEvent(ref.pageRef, 'openChildScreen_' + ref.additionalAttributes.screenName + "Group1", customChangeHandler);
				resolve({});
			});

		}
	}

	//-- This method saves note on account --//
	function saveAccountNote(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum, ShowToastEvent) {
		var screenName = values['ggScreenName'];
		return new Promise(function (resolve, reject) {
			if (values && values['NoteBody']) {
				invoke({
					className: 'AccountActionController',
					functionName: 'saveAccountNote',
					values: values
				}).then(result => {
					if (!result.success) {
						cmp.dispatchEvent(new ShowToastEvent({
							title: "Error",
							message: result.errorMessage,
							variant: "error",
							mode: "dismissable"
						}));
						resolve({});
					} else {
						if (result) {
							fireEvent(cmp.pageRef, 'updateLatestNote', result.LatestNote);
							//-- Start | FIN-5726 | Changed By Dilshad | 13 Jun 2024 --//
							fireEvent(cmp.pageRef, 'refreshDataGrid_AccountNotes_noteDataGrid', null);
							//-- Ends | FIN-5726 | Changed By Dilshad | 13 Jun 2024 --//
							fireEvent(cmp.pageRef, 'closeScreen_' + screenName, null);
							resolve(result);
						} else {
							fireEvent(cmp.pageRef, 'updateLatestNote', values.NoteBody);
							//-- Start | FIN-5726 | Changed By Dilshad | 13 Jun 2024 --//
							fireEvent(cmp.pageRef, 'refreshDataGrid_AccountNotes_noteDataGrid', null);
							//-- Ends | FIN-5726 | Changed By Dilshad | 13 Jun 2024 --//
							fireEvent(cmp.pageRef, 'closeScreen_' + screenName, null);
							resolve(values);
						}
					}
				}).catch(error => {
					console.log('error :' + error);
					reject(error);
				});
			} else {
				let returnVal = {}
				returnVal.ggErrorMessage = 'Please enter note.'
				resolve(returnVal);
			}
		});
	}

	function onLoadAccountDetailTab(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum) {
		return new Promise(function (resolve, reject) {
			try {
				invoke({
					className: 'AccountDetailController',
					functionName: 'AgingSummary',
					values: values
				}).then(response => {
					let returnVal = {};
					let openAR = gog.formatNumber(response['LOCALE'], response['CURRENCY_CODE'], response['OPEN_AR']);
					let notDue = gog.formatNumber(response['LOCALE'], response['CURRENCY_CODE'], response['AGE_0']);
					let age1 = gog.formatNumber(response['LOCALE'], response['CURRENCY_CODE'], response['AGE_1']);
					let age2 = gog.formatNumber(response['LOCALE'], response['CURRENCY_CODE'], response['AGE_2']);
					let age3 = gog.formatNumber(response['LOCALE'], response['CURRENCY_CODE'], response['AGE_3']);
					let age4 = gog.formatNumber(response['LOCALE'], response['CURRENCY_CODE'], response['AGE_4']);
					let age5 = gog.formatNumber(response['LOCALE'], response['CURRENCY_CODE'], response['AGE_5']);

					let openInvoicesCount = response['OPEN_INVOICES'];
					let notDueInvoices = response['NOT_DUE_INVOICES'];
					let invoices_1_30 = response['INVOICES_1_30'];
					let invoices_31_60 = response['INVOICES_31_60'];
					let invoices_61_90 = response['INVOICES_61_90'];
					let invoices_91_180 = response['INVOICES_91_180'];
					let invoices_Over_190 = response['INVOICES_OVER_180'];

					let NOT_DUE_PERCENT = gog.formatPercentage(response['LOCALE'], response['NOT_DUE_PERCENT']);
					let AGE_1_PERCENT = gog.formatPercentage(response['LOCALE'], response['AGE_1_PERCENT']);
					let AGE_2_PERCENT = gog.formatPercentage(response['LOCALE'], response['AGE_2_PERCENT']);
					let AGE_3_PERCENT = gog.formatPercentage(response['LOCALE'], response['AGE_3_PERCENT']);
					let AGE_4_PERCENT = gog.formatPercentage(response['LOCALE'], response['AGE_4_PERCENT']);
					let AGE_5_PERCENT = gog.formatPercentage(response['LOCALE'], response['AGE_5_PERCENT']);

					// resolverMap.id = result1['resolverId'];
					// resolverMap.name = result1['resolverName'];
					// result1['TransactionList'][rowNum]['DisputeResolver'] = resolverMap;
					// result1['TransactionList'][rowNum]['WorkflowMatrix'] = result1['relatedMatrixId'];
					// result1['TransactionList'][rowNum]['totalSLADays'] = result1['totalSLADays'];
					returnVal.receivableInfoArea = '<style> .tableClass tr th { border: 1px solid #ddd; padding: 4px 8px 4px 8px; background-color: #ececec; height: 30px; } .tableClass tr td { border: 1px solid #ddd; padding: 4px 8px 4px 8px; height: 28px; } .tableClass tr td.rightAligned, .tableClass tr th.rightAligned { text-align: right; } </style> <table border="1" class="tableClass" style="table-layout: fixed; width: 100%;"> <tr> <th title="Bucket">Bucket</th> <th title="Amount" class="rightAligned">Amount</th> <th title="Percentage (%)" class="rightAligned">Percentage (%)</th> <th title="# of Invoices" class="rightAligned"># of Invoices</th> </tr> <tr> <td title="Total (Open A/R)">Total (Open A/R)</td> <td title="' + openAR + '" class="rightAligned">' + openAR + '</td> <td title="100%" class="rightAligned">100.00%</td> <td title="' + openInvoicesCount + '" class="rightAligned">' + openInvoicesCount + '</td> </tr> <tr> <td title="Not Due">Not Due </td> <td title="' + notDue + '" class="rightAligned">' + notDue + '</td> <td class="rightAligned" title="' + NOT_DUE_PERCENT + '">' + NOT_DUE_PERCENT + '</td> <td class="rightAligned" title="' + notDueInvoices + '">' + notDueInvoices + '</td> </tr> <tr> <td title="0 - 31 days">0 - 31 days</td> <td title="' + age1 + '" class="rightAligned">' + age1 + '</td> <td class="rightAligned" title="' + AGE_1_PERCENT + '">' + AGE_1_PERCENT + '</td> <td class="rightAligned" title="' + invoices_1_30 + '">' + invoices_1_30 + '</td> </tr> <tr> <td title="31 - 60 days">31 - 60 days</td> <td title="' + age2 + '" class="rightAligned">' + age2 + '</td> <td class="rightAligned" title="' + AGE_2_PERCENT + '">' + AGE_2_PERCENT + '</td> <td class="rightAligned" title="' + invoices_31_60 + '">' + invoices_31_60 + '</td> </tr> <tr> <td title="61 - 90 days">61 - 90 days</td> <td title="' + age3 + '" class="rightAligned">' + age3 + '</td> <td class="rightAligned" title="' + AGE_3_PERCENT + '">' + AGE_3_PERCENT + '</td> <td class="rightAligned" title="' + invoices_61_90 + '">' + invoices_61_90 + '</td> </tr> <tr> <td title="91 - 180 days"> 91 - 180 days</td> <td title="' + age4 + '" class="rightAligned">' + age4 + '</td> <td class="rightAligned" title="' + AGE_4_PERCENT + '">' + AGE_4_PERCENT + '</td> <td class="rightAligned" title="' + invoices_91_180 + '">' + invoices_91_180 + '</td> </tr> <tr> <td title="Over 180">Over 180</td> <td title="' + age5 + '" class="rightAligned">' + age5 + '</td> <td class="rightAligned" title="' + AGE_5_PERCENT + '">' + AGE_5_PERCENT + '</td> <td class="rightAligned" title="' + invoices_Over_190 + '">' + invoices_Over_190 + '</td> </tr> </table>';
					resolve(returnVal);

				}).catch(error => {
					console.log('error :' + error);
					reject(error);
				});
			} catch (error) {
				reject(error);
			}
		});
	}
	function onLoadScoreCardTab(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum) {
		debugger;
		return new Promise(function (resolve, reject) {
			try {
				invoke({
					className: 'AccountDetailController',
					functionName: 'getScoreCardDetail',
					values: values
				}).then(response => {
					debugger;
					let returnVal = {};
					if(response.collectionPriorityConfig){

						let htmlTable = '<html> <head> <style> #customer { font-family: Arial, Helvetica, sans-serif; border-collapse: collapse; width: 100%; } #customer td, #customer th { border: 1px solid #ddd; padding: 4px 8px 4px 8px; } #customer th { background-color: #ececec; color: black; } </style> </head>';
						htmlTable += '<body> <table width="100%" border="1" id="customer"> <tr> <th align="left">{Label.Parameter}</th> <th align="right">{Label.Weightage} </th> <th align="right">{Label.Calculated_Value}</th> </tr> ';

						let htmlTable1 = '<html> <head> <style> #customer { font-family: Arial, Helvetica, sans-serif; border-collapse: collapse; width: 100%; } #customer td, #customer th { border: 1px solid #ddd; padding: 4px 8px 4px 8px; } #customer th { background-color: #ececec; color: black; } </style> </head>';
						htmlTable1 += '<body> <table width="100%" border="0" id="customer"> <tr> <th align="left">{Label.Parameter}</th> <th align="left">{Label.Definition}</th> </tr>';

						let htmlTable2 = '<html><head> <style>#customer{font-family: Arial, Helvetica, sans-serif; border-collapse: collapse; width: 100%;}#customer td, #customer th{border: 1px solid #ddd; padding: 4px 8px 4px 8px;}#customer th{background-color: #ebebeb; color: black;}</style></head>';
						htmlTable2 += '<body> <table width="100%" border="0" id="customer"> <tr> <th align="left">{Label.SRM_CH_Grid_Category}</th> <th align="left">{Label.Average_Days_Of_Delay}</th> <th align="left">{Label.SRM_Score}</th> </tr>';

						let htmlTable3 = '<html><head> <style>#customer{font-family: Arial, Helvetica, sans-serif; border-collapse: collapse; width: 100%;}#customer td, #customer th{border: 1px solid #ddd; padding: 4px 8px 4px 8px;}#customer th{background-color: #ebebeb; color: black;}</style></head>';
						htmlTable3 += '<body> <table width="100%" border="0" id="customer"> <tr> <th align="left">Last Touched</th> <th align="left">Score</th> </tr>';
						
						response.collectionPriorityConfig.forEach(parm => {
							if(parm.IsActive__c){
								htmlTable1 += '<tr style="border-bottom: 1px solid #000;"> <td align="left">' + parm.Parameter_Name__c + '</td><td align="left">' + parm.Definition__c + '</td></tr>';
								// htmlTable += '<tr style="border-bottom: 1px solid #000;"> <td align="left">' + parm.Parameter_Name__c + '</td> <td align="right">' + parm.Weightage__c + '%</td> <td align="right">' + 0 + '</td> </tr>';
								if(parm.MasterLabel == 'avgDaysOfDelay'){
									htmlTable += '<tr style="border-bottom: 1px solid #000;"> <td align="left">' + parm.Parameter_Name__c + '</td> <td align="right">' + parm.Weightage__c + '%</td> <td align="right">' + response.avgADD + '</td> </tr>';
								} else if(parm.MasterLabel == 'countryRating'){
									htmlTable += '<tr style="border-bottom: 1px solid #000;"> <td align="left">' + parm.Parameter_Name__c + '</td> <td align="right">' + parm.Weightage__c + '%</td> <td align="right">' + response.countryRating + '</td> </tr>';
								} else if(parm.MasterLabel == 'maxDunningPerformed'){
									htmlTable += '<tr style="border-bottom: 1px solid #000;"> <td align="left">' + parm.Parameter_Name__c + '</td> <td align="right">' + parm.Weightage__c + '%</td> <td align="right">' + response.maxDunningPerformed + '</td> </tr>';
								} else if(parm.MasterLabel == 'pastDueBucket'){
									htmlTable += '<tr style="border-bottom: 1px solid #000;"> <td align="left">' + parm.Parameter_Name__c + '*</td> <td align="right">' + parm.Weightage__c + '%</td> <td align="right">' + response.pastDueRisk + '</td> </tr>';
								} else if(parm.MasterLabel == 'LastTouchedDay'){
									htmlTable += '<tr style="border-bottom: 1px solid #000;"> <td align="left">' + parm.Parameter_Name__c + '</td> <td align="right">' + parm.Weightage__c + '%</td> <td align="right">' + (response.LastTouchedDay).toFixed(2) + '</td> </tr>';
								} else if(parm.MasterLabel == 'MaxPastDueAR'){
									htmlTable += '<tr style="border-bottom: 1px solid #000;"> <td align="left">' + parm.Parameter_Name__c + '</td> <td align="right">' + parm.Weightage__c + '%</td> <td align="right">' + (response.MaxPastDueAR).toFixed(2) + '</td> </tr>';
								}
							}
							if(parm.MasterLabel == 'avgDaysOfDelay'){
								// let score = JSON.parse(parm.score__c)
								for (let score of  JSON.parse(parm.Score__c)) {
									htmlTable2 += '<tr style="border-bottom: 1px solid #000;"> <td align="left">' + score.name + '</td><td align="left">' + score.label + '</td><td align="left">' + score.score * 100 + '</td></tr>'
							  	}
								htmlTable2 += '</table> </body> </html>';
								returnVal.averageDaysofDelayDesc = htmlTable2;
							}
						}),
						htmlTable += '<tr style="border-bottom: 1px solid #000;"> <td align="left">Total Value</td> <td align="right"> 100% </td> <td align="right">' + response.totaScorecard + '</td> </tr>';
						htmlTable += '</table> </body> </html>';
						returnVal.collectionPriorityTable = htmlTable;

						htmlTable1 += '</table> </body> </html>';
						returnVal.parameterDescription = htmlTable1;
						resolve({ 'parameterDescription': htmlTable1, 'collectionPriorityTable': htmlTable, 'averageDaysofDelayDesc': htmlTable2 });

					}
					// resolve(returnVal);
				}).catch(error => {
					console.log('error :' + error);
					reject(error);
				});
			} catch (error) {
				reject(error);
			}
		});
	}


	function formatNumber(userLocale, currencyCode, numberToFormat) {
		if (numberToFormat == undefined || numberToFormat == null) {
			numberToFormat = 0;
		}
		return Intl.NumberFormat(userLocale, {
			notation: "compact",
			compactDisplay: "short",
			maximumFractionDigits: "2",
			style: 'currency',
			currency: currencyCode
		}).format(numberToFormat);
	}

	function formatPercentage(userLocale, numberToFormat) {
		if (numberToFormat == undefined || numberToFormat == null) {
			numberToFormat = 0;
		}
		return Intl.NumberFormat(userLocale, {
			minimumFractionDigits: 2,
			maximumFractionDigits: 2,
			style: 'percent'
		}).format(numberToFormat);
	}

	//-- This method is related to Log A Call action --//
	function onChangeResponseByContact(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum) {
		return new Promise(function (resolve, reject) {
			let returnValue = {};

			if (values.ResponseByContact != null && values.ResponseByContact != "") {
				returnValue["isFollowUp"] = true;
				let followUpDate = new Date();
				if (values.ResponseByContact == "No Answer") {
					followUpDate.setDate(followUpDate.getDate() + 1);
				} else if (values.ResponseByContact == "Left Voicemail") {
					followUpDate.setDate(followUpDate.getDate() + 2);
				} else {
					followUpDate.setDate(followUpDate.getDate() + 5);
				}
				returnValue["FollowUpDate"] = followUpDate;
			}

			resolve(returnValue);
		});
	}

	function onChangeIsFollowUp(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum) {
		return new Promise(function (resolve, reject) {
			let returnValue = {};
			let followUpDate = new Date();
			if (values.ResponseByContact != null && values.ResponseByContact != "") {
				if (values.ResponseByContact == "No Answer") {
					followUpDate.setDate(followUpDate.getDate() + 1);
				} else if (values.ResponseByContact == "Left Voicemail") {
					followUpDate.setDate(followUpDate.getDate() + 2);
				} else {
					followUpDate.setDate(followUpDate.getDate() + 5);
				}
			} else {
				followUpDate.setDate(followUpDate.getDate() + 5);
			}
			returnValue["FollowUpDate"] = followUpDate;
			resolve(returnValue);
		});
	}

	//-- This method is related to Send Email action --//
	function handleTreatmentNotes(values, invoke, dataServiceObj, fireEvent, ref, rowvals, NavigationMixin, rowNum, ShowToastEvent) {
		return new Promise(function (resolve, reject) {
			if (values["buttonClassListremoveTreatmentNotes"] && values["buttonClassListremoveTreatmentNotes"].contains("removeTreatment")) {
				values.hideTreatmentNotes = "false";
				values.treatmentButtonName = "";
				delete values["buttonClassListremoveTreatmentNotes"];
				resolve(values);
			} if (values["buttonClassListtreatmentNotes"] && values["buttonClassListtreatmentNotes"].contains("oninclude")) {
				values.hideTreatmentNotes = "true";
				values.treatmentButtonName = "Include";

				delete values["buttonClassListtreatmentNotes"];
				resolve(values);
			} else if (values["buttonClassListtreatmentNotes"] && values["buttonClassListtreatmentNotes"].contains("onno")) {
				values.hideTreatmentNotes = "true";
				values.treatmentButtonName = "No";
				delete values["buttonClassListtreatmentNotes"];
				resolve(values);
			} else {
				resolve(values);
			}
		});
	}
	//-- Start | FIN-9409 | Changed by Ravi | 23-Mar-2026 --//
	function generateStatementForAttachment(values, invoke, ds, fireEvent, cmp) {
	//-- End | FIN-9409 | Changed by Ravi | 23-Mar-2026 --//
		return new Promise(function (resolve, reject) {
			if (values['StatementFormat'] == null || values['StatementFormat'] == "") {
				values['StatementFormat'] = 'PDF'
			}
			if (values['AttachCheckBox']) {
				values.preview = true;
				//-- Start | FIN-9409 | Changed by Ravi | 23-Mar-2026 --//
				gog.createStatementAttachmentOnPreview(values, invoke, ds, fireEvent, cmp).then(result1 => {
				//-- End | FIN-9409 | Changed by Ravi | 23-Mar-2026 --//
					var result = JSON.parse(JSON.stringify(result1));
					delete result.enableSubmitButton;
					delete result.preview;
					resolve(result);
				}).catch(err => {
					reject(err);
				});
			} else {
				resolve(values);
			}
		});
	}
	//-- Start | FIN-9409 | Changed by Ravi | 23-Mar-2026 --//
	function createStatementAttachmentOnPreview(values, invoke, ds, fireEvent, cmp) {
	//-- End | FIN-9409 | Changed by Ravi | 23-Mar-2026 --//	
		debugger;
		var arr = values['TransactionList'];
		var trxnId = '';
		var formatType = values['StatementFormat'] ? values['StatementFormat'] : 'PDF'; //FIN-9048 | Chanegs by Asera 02-Feb-2026
		//-- Start | FIN-8509 | Changed by Ravi | 13-Oct-2025 --//
		let fileName = values['fileName'] ? values['fileName'] : 'BillingStatement';
		//-- Ends | FIN-8509 | Changed by Ravi | 13-Oct-2025 --//
		return new Promise(function (resolve, reject) {
			if (!formatType) {
				reject('Please select Statement Format');
			} else {
				if (arr && arr.length > 0) {
					for (var i = 0; i < arr.length; i++) {
						if (i == arr.length - 1) {
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
				}).then(async result1 => {
					var result = JSON.parse(JSON.stringify(result1));
					if (result) {
						//-- Start | FIN-9543 | Changes by Dhwanil | 06-Arl-2026 --//
						result['fontLibraryUrl'] = '/resource/FontLibrary';
						//-- ends | FIN-9543 | Changes by Dhwanil | 06-Arl-2026 --//
						//-- Start | FIN-9048 | Chanegs by Asera 02-Feb-2026--//
						if (result.templateBody) {
							//-- Start | FIN-9409 | Changed by Ravi | 23-Mar-2026 --//
							const contentHtml = await window.gog.statementUtils.getProcessedTemplateHtml(result, true, cmp);
							//-- End | FIN-9409 | Changed by Ravi | 23-Mar-2026 --//
							if (formatType == "Excel") {
								values["SendStmtAttachmentContent"] = await window.gog.statementUtils.generateExcelFromHtml(contentHtml, fileName, ExcelJS, result);
							} else if (formatType == "PDF") {
								//-- Start | FIN-9410 | Changed by Ravi | 16-Mar-2026 --//
								values["SendStmtAttachmentContent"] = await window.gog.statementUtils.generatePdfFromHtml(contentHtml, window, result, 'landscape');
								//-- End | FIN-9410 | Changed by Ravi | 16-Mar-2026 --//
							}
							delete result['templateBodyImageBase64Map']; // FIN-9351
						}
						//-- End | FIN-9048 | Chanegs by Asera 02-Feb-2026--//
						//-- Start | FIN-7812 | Changed By Ravi | 14 July 2025 --//
						else if (formatType != "Excel") {
							// << COMMENT - START - MM - FIN-9616 - [Akzonobel] [Collection] Switch to VF Page from JS Code >> 
							/*
							if (!window.jspdf) {
								console.error('jsPDF not loaded');
								return;
							}

							// Landscape to match wide tables
							const doc = window.jspdf.jsPDF({
									orientation: 'l',   // 'p' = portrait, 'l' = landscape
									unit: 'pt',         // 'pt', 'mm', 'cm', 'in'
									format: 'a4',       // 'a4', 'letter', [210, 297]
									compress: true,     // enable internal PDF compression
									precision: 2        // reduce float precision (smaller size)
								});

							let y = 40; // starting vertical position

							// Add Company Logo if exists
							if (result.hasCompanyLogo) {
								const logoUrl = '/resource/CompanyLogo'; // static resource
								const response = await fetch(logoUrl);
								const blob = await response.blob();
								const base64 = await blobToBase64(blob);

								doc.addImage(base64, 'PNG', 40, y, 100, 50); // x, y, width, height
								y += 60; // space after logo

								doc.setDrawColor(0);       // black line
								doc.setLineWidth(0.5);     // thin line
								doc.line(40, y, 800, y);
								y += 20;
							}

							// Add Title
							doc.setFontSize(20);
							doc.setFont('Times New Roman', 'bold');
							doc.text('STATEMENT OF ACCOUNT', 50, y);
							y += 10;

							doc.setDrawColor(0);       // black line
							doc.setLineWidth(0.5);     // thin line
							doc.line(40, y, 590, y);
							y += 20;

							if(result.orgName){
								// Organization Name
								doc.setFontSize(16);
								doc.text(result.orgName, 50, y);
								y += 20;
							}
							//-- Start | FIN-9250 | Chanegs by Asera 18-Feb-2026--//
							const LOCAL = (result.LOCALE || 'en-US').replace('_', '-');;
							//-- Ends | FIN-9250 | Chanegs by Asera 18-Feb-2026--//
							if(result.customerName){
								y -= 60;
								const summaryStartX = 600;   // right side position
								const summaryStartY = y;     // current Y
								const boxWidth = 180;

								const headerStyle = {
									fillColor: [222, 242, 241], // light teal
									fontStyle: 'bold'
								};

								const valueStyle = {
									fillColor: [255, 255, 255],
									fontStyle: 'bold'
								};
								//--Start | FIN-9250 | Changed by Dhwanil | 18-Feb-2026 --//
								doc.autoTable({
								startY: summaryStartY,
								margin: { left: summaryStartX },
								tableWidth: boxWidth,
								body: [
									[{ content: 'Customer Name : ', styles: headerStyle }],
									[{ content: result.customerName || '', styles: valueStyle }],
									[{ content: 'Customer Number : ', styles: headerStyle }],
									[{ content: result.customerNumber || '', styles: valueStyle }],
									[{ content: 'Statement Date : ', styles: headerStyle }],
									[{ content: new Intl.DateTimeFormat(LOCAL).format(new Date(result.statementDate)) || '', styles: valueStyle }]
								],
								theme: 'grid',
								styles: {
									font: 'Time new roman',
									fontSize: 12,
									halign: 'center',
									valign: 'middle',
									lineWidth: 0.8,
									lineColor: [0, 0, 0]
								}
								});
								//--Ends | FIN-9250 | Changed by Dhwanil | 18-Feb-2026 --//
								// move y below the table
								y = doc.lastAutoTable.finalY + 20;
							}

							let startY = y;

							const data = result.DueTransList;
							const newLstFields = result.selectedFields;
							const newLstFieldsLabel = result.selectedFieldsLabel;
							let fieldTypeMap = result.selectedFieldTypes;

							if (typeof result.selectedFieldTypes === 'string') {
								fieldTypeMap = JSON.parse(result.selectedFieldTypes);
							}

							//-- Start | FIN-9543 | Changed by Dhwanil | 06 April 2026 --//
							const attachmentFontFamily = result['attachmentFontFamily'] || 'Times New Roman';
							const attachmentFontSize = (result['attachmentFontSize'] || '9')+'px';
							//-- End | FIN-9543 | Changed by Dhwanil | 06-Apr-2026 --//
							// ===============================
							// COLUMN METADATA
							// ===============================
							const columns = newLstFields.map((field, index) => {
								const typeFromApex = fieldTypeMap?.[field];

								let type = 'text';

								if (typeFromApex === 'currency' || typeFromApex === 'double' || typeFromApex === 'decimal') {
									type = 'currency';
								} else if (typeFromApex === 'number' || typeFromApex === 'integer') {
									type = 'number';
								} else if (typeFromApex === 'date' || typeFromApex === 'datetime') {
									type = 'date';
								}

								return {
									fieldName: field,
									label: newLstFieldsLabel[index],
									isExport: true,
									type
								};
							});

							// ===============================
							// TABLE HEADER
							// ===============================
							const head = [newLstFieldsLabel];

							// ===============================
							// TABLE BODY + TOTALS
							// ===============================
							const body = [];
							const totalMap = {};

							data.forEach(record => {
								const row = [];

								newLstFields.forEach(fieldName => {
									let value = record[fieldName] ?? '';

									const colDef = columns.find(c => c.fieldName === fieldName);

									if (colDef?.type === 'currency') {
										const currencyCode = record.CurrencyIsoCode;
										const amount = parseFloat(value) || 0;

										if (currencyCode) {
											const symbol = getCurrencySymbol(currencyCode);
											value = `${symbol} ${amount.toFixed(2)}`;

											if (fieldName?.toLowerCase().endsWith('balance__c')) {
												totalMap[currencyCode] =
													(totalMap[currencyCode] || 0) + amount;
											}
										}
									}
									else if (colDef?.type === 'date') {
										//--Start | FIN-9250 | Changed by Dhwanil | 18-Feb-2026 --//
										value = value ? new Intl.DateTimeFormat(LOCAL).format(new Date(value)): '';
										//--Ends | FIN-9250 | Changed by Dhwanil | 18-Feb-2026 --//
									}

									row.push(value);
								});

								body.push(row);
							});

							// ===============================
							// MAIN TABLE
							// ===============================
							doc.autoTable({
								startY,
								head,
								body,
								theme: 'grid',
								styles: {
									font: attachmentFontFamily,
									fontSize: attachmentFontSize,
									cellPadding: 4,
									valign: 'middle',
									lineWidth: 0.8,
									lineColor: [0, 0, 0]
								},
								headStyles: {
									halign: 'center',
									font: attachmentFontFamily,
									fontStyle: 'bold',
									fillColor: [222, 242, 241],
									textColor: [0, 0, 0],
									lineWidth: 0.8,
									lineColor: [0, 0, 0]
								},
								bodyStyles: {
									lineWidth: 0.3
								},
								columnStyles: columns.reduce((acc, col, idx) => {
									if (col.type === 'currency' || col.type === 'number') {
										acc[idx] = { halign: 'right' };
									}
									return acc;
								}, {}),
								showHead: 'everyPage',
								pageBreak: 'auto'
							});

							// ===============================
							// TOTAL ROWS (POST TABLE)
							// ===============================
							y = doc.lastAutoTable.finalY + 20;
							doc.setFont('Times New Roman', 'bold');
							doc.setFontSize(10);

							Object.entries(totalMap).forEach(([currencyCode, totalValue]) => {
								const symbol = getCurrencySymbol(currencyCode);
								doc.text(
									`Total (${symbol}) : ${totalValue.toFixed(2)}`,
									doc.internal.pageSize.getWidth() - 220,
									y
								);
								y += 14;
							});

							// ===============================
							// BASE64 OUTPUT FOR APEX
							// ===============================
							//const pdfBase64 = doc.output('datauristring').split(',')[1];
							//values['SendStmtAttachmentContent'] = pdfBase64;
							const buffer = doc.output('arraybuffer');
							values['SendStmtAttachmentContent'] = await bufferToBase64(buffer, 'application/pdf');
							*/
							// << COMMENT - END - MM - FIN-9616 - [Akzonobel] [Collection] Switch to VF Page from JS Code >> 

							// << START - MM - FIN-9616 - [Akzonobel] [Collection] Switch to VF Page from JS Code >> 
							var TotalBalance = 0;

							var newLst = result.DueTransList;
							var newLstFields = result.selectedFields;
							var newLstFieldsLabel = result.selectedFieldsLabel;

							var ContentSt = result.SendStmtAttachmentContent;

							var htmlBody;
							var pg = 0;
							var pageBreakAfter = 9;
							//-- Start | FIN-8048 | Changed by Ravi | 29 July 2025 --//
							var st = "<head><style>@page{size:landscape;}</style>";
							htmlBody = "<br/><table width='100%' id='txSummaryTableJS' style='border-collapse:collapse;padding:0px;font-family:verdana;'><tr>";
							//-- End | FIN-8048 | Changed by Ravi | 29 July 2025 --//
							for (let i = 0; i < newLstFieldsLabel.length; i++) {
								//-- Start | FIN-8048 | Changed by Ravi | 29 July 2025 --//
								htmlBody = htmlBody + '<th style="border:1px solid gray;text-align:left;"><strong>' + newLstFieldsLabel[i] + '</strong></th>';
								//-- End | FIN-8048 | Changed by Ravi | 29 July 2025 --//
							}


							htmlBody += "</tr>";
							for (let i = 0; i < newLst.length; i++) {
								if (pg == pageBreakAfter && values['StatementFormat'] == 'PDF') {
									htmlBody += "</table>";
									htmlBody += "<br>";
									//-- Start | FIN-8048 | Changed by Ravi | 29 July 2025 --//
									htmlBody += "<table width='100%' id='txSummaryTableJS' style='border-collapse:collapse;padding:0px;font-family:verdana;'><tr style='page-break-before:always;'>";
									//-- End | FIN-8048 | Changed by Ravi | 29 July 2025 --//
									for (let i = 0; i < newLstFieldsLabel.length; i++) {
										//-- Start | FIN-8048 | Changed by Ravi | 29 July 2025 --//
										htmlBody = htmlBody + '<th style="border:1px solid gray;text-align:left;"><strong>' + newLstFieldsLabel[i] + '</strong></th>';
										//-- End | FIN-8048 | Changed by Ravi | 29 July 2025 --//
									}
									htmlBody += "</tr>";
									pg = 0;
									pageBreakAfter = 32;
								}
								pg = pg + 1;
								htmlBody += "<tr>";
								for (let j = 0; j < newLstFields.length; j++) {
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
									//-- Start | FIN-8048 | Changed by Ravi | 11 Aug 2025 --//
									htmlBody += "<td style='border:1px solid gray;text-align:left;white-space:nowrap;'>" + fieldValue + "</td>";
									//-- End | FIN-8048 | Changed by Ravi | 11 Aug 2025 --//
								}
								htmlBody += "</tr>";
								var newAmt = newLst[i].celsrm__Balance__c == null ? 0 : newLst[i].celsrm__Balance__c;
								TotalBalance = TotalBalance + newAmt;

							}
							htmlBody += "</table>";
							delete result.DueTransList;
							delete result.selectedFields;
							delete result.selectedFieldsLabel;
							delete result.TransIds;
							delete result.returnTemplateAmount;
							// << START - MM - FIN-9616 - [Akzonobel] [Collection] Switch to VF Page from JS Code >> 
							htmlBody = htmlBody.replace(
								/font-family\s*:\s*[^;]*\s*;/gi,
								'font-family: Arial Unicode MS;'
							);
							// << END - MM - FIN-9616 - [Akzonobel] [Collection] Switch to VF Page from JS Code >> 
							console.log("htmlBody" + htmlBody);

							ContentSt = ContentSt.replace("<head>", st);
							ContentSt = ContentSt.replace("{Transaction.Summary}", htmlBody);
							var temp = window.btoa(unescape(encodeURIComponent(ContentSt)));
							values['SendStmtAttachmentContent'] = temp;
							// << START - MM - FIN-9616 - [Akzonobel] [Collection] Switch to VF Page from JS Code >> 
						} else if (formatType == "Excel") {
							const data = result.DueTransList;
							const newLstFields = result.selectedFields;
							const newLstFieldsLabel = result.selectedFieldsLabel;
							let fieldTypeMap = result.selectedFieldTypes;

							if (typeof result.selectedFieldTypes === 'string') {
								fieldTypeMap = JSON.parse(result.selectedFieldTypes);
							}

							const columns = newLstFields.map((field, index) => {
								const apexType = fieldTypeMap?.[field];

								let type = 'text';

								if (apexType === 'currency') {
									type = 'currency';
								} else if (apexType === 'number') {
									type = 'number';
								} else if (apexType === 'date') {
									type = 'date';
								} else if (apexType === 'link') {
									type = 'text'; // ExcelJS does not support hyperlink formatting here
								}

								return {
									fieldName: field,
									label: newLstFieldsLabel[index],
									isExport: true,
									type
								};
							});

							const workbook = new ExcelJS.Workbook();
							//-- Start | FIN-8509 | Changed by Ravi | 13-Oct-2025 --//
							const worksheet = workbook.addWorksheet(fileName);
							//-- Ends | FIN-8509 | Changed by Ravi | 13-Oct-2025 --//
							// Format header row
							const headerRow = worksheet.getRow(1);
							headerRow.values = newLstFieldsLabel;

							headerRow.eachCell((cell) => {
								//-- Start | FIN-8048 | Changed by Ravi | 29 July 2025 --//
								cell.font = { bold: true};
								cell.border = {
									top: { style: 'thin' },
									left: { style: 'thin' },
									bottom: { style: 'thin' },
									right: { style: 'thin' }
								}
								// cell.fill = {
								// 	type: 'pattern',
								// 	pattern: 'solid',
								// 	fgColor: { argb: '000000' } // Black background color
								// };
								//-- End | FIN-8048 | Changed by Ravi | 29 July 2025 --//
							});

							// Define columns using newLstFields
							worksheet.columns = newLstFields.map(field => ({ key: field, width: 20 }));

							// Add data rows starting from the 2nd row
							let totalMap = {}; // FIN-8285 | Changed by Asera | 23-Oct-2025 --//
							data.forEach((record, index) => {
								const row = worksheet.getRow(2 + index);

								newLstFields.forEach((fieldName, colIndex) => {
									let value = record[fieldName] || '';
									row.getCell(colIndex + 1).value = value;
									//-- Start | FIN-8285 | Changed by Asera | 23-Oct-2025 --//
									// Apply currency formatting if needed
									// if (columns.find(c => c.fieldName === fieldName || c.name === fieldName)?.type === 'currency') {
									// 	const currencyCode = record['CurrencyIsoCode'] || additionalAttributes.currencyCode;
									// 	if (currencyCode) {
									// 		const currencySymbol = getCurrencySymbol(currencyCode);
									// 		row.getCell(colIndex + 1).numFmt = `${currencySymbol} #,##0.00`;
									// 	}
									// }
									if (columns.find(c => c.fieldName === fieldName || c.name === fieldName)?.type === 'currency') {
										const currencyCode = record['CurrencyIsoCode'];
										if (currencyCode) {
											const currencySymbol = getCurrencySymbol(currencyCode);
											row.getCell(colIndex + 1).numFmt = '[$' + currencySymbol + '] #,##0.00';
											if (fieldName?.toLowerCase().endsWith('balance__c')) {
												if (totalMap[currencyCode]) {
													totalMap[currencyCode] = totalMap[currencyCode] + parseFloat(value);
												} else {
													totalMap[currencyCode] = parseFloat(value);
												}
											}
											
										}
									}
									//-- End | FIN-8285 | Changed by Asera | 23-Oct-2025 --//
								});

								// Apply borders after all cells are populated
								row.eachCell((cell) => {
									cell.border = {
										top: { style: 'thin' },
										left: { style: 'thin' },
										bottom: { style: 'thin' },
										right: { style: 'thin' }
									}
								});
							});
							//-- Start | FIN-8285 | Changed by Asera | 23-Oct-2025 --//
							// Write the workbook to a binary string
							// Add total rows for each currency in totalMap
							if (Object.keys(totalMap).length > 0) {
								let recordCounter = data.length + 2;
								for (const [currencyCode, totalValue] of Object.entries(totalMap)) {
									const rowCounter = recordCounter ++;
									const totalRow = worksheet.getRow(rowCounter);
									const currencySymbol = getCurrencySymbol(currencyCode);
									// Set the total title in the first cell
									totalRow.getCell(1).value = 'Total (' + currencySymbol + ')';
									totalRow.getCell(1).alignment = { horizontal: 'right' };

									worksheet.mergeCells({
										top: rowCounter,
										left: 1,
										bottom: rowCounter,
										right: columns.length - 1
									});


									// Set the total value in the aggregation column
									const totalAmountColumnIndex = columns.length;
									if (totalAmountColumnIndex > 0) {
										totalRow.getCell(totalAmountColumnIndex).value = totalValue;
										totalRow.getCell(totalAmountColumnIndex).numFmt = '[$' + getCurrencySymbol(currencyCode) + '] #,##0.00';

									}
									// Style the total row
									totalRow.eachCell((cell) => {
										cell.font = { bold: true };
										cell.border = {
											top: { style: 'thin' },
											left: { style: 'thin' },
											bottom: { style: 'thin' },
											right: { style: 'thin' }
										}
									});
								}
							}
							//-- End | FIN-8285 | Changed by Asera | 23-Oct-2025 --//
							const buffer = await workbook.xlsx.writeBuffer();
							// var temp = window.btoa(String.fromCharCode(...new Uint8Array(buffer)));
							var temp = await bufferToBase64(buffer, 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
							values['SendStmtAttachmentContent'] = temp;
							delete result.DueTransList;
							delete result.selectedFields;
							delete result.selectedFieldsLabel;
							delete result.TransIds;
							delete result.returnTemplateAmount;
						}
						//-- Start | FIN-7812 | Changed By Ravi | 14 July 2025 --//
						gog.onAttachFormatCompletion(values, invoke, ds).then(result => {
							resolve(result);
						}).catch(err => {
							reject(err);
						});
					}

				}).catch(error => {
					console.log('error :' + error);
					reject(error);
				});
			}
		});
	}

	// Helper: Blob → Base64
	function blobToBase64(blob) {
		return new Promise((resolve, reject) => {
			const reader = new FileReader();
			reader.onloadend = () => resolve(reader.result);
			reader.onerror = reject;
			reader.readAsDataURL(blob);
		});
	}
	
	function onAttachFormatCompletion(values, invoke, ds) {
		let tempVal = { 
			'finalContent': values['SendStmtAttachmentContent'], 
			'StatementFormat': values['StatementFormat'],
			'AttachmentIDSendStmt': values['AttachmentIDSendStmt']
		};
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
		let tempVal = {
			'AttachmentIDSendStmt': values['AttachmentIDSendStmt'], 
			'StatementFormat': values['StatementFormat'], 
			'ComposeEmail': values['ComposeEmail'],
			'ContentIDSendStmt':values['ContentIDSendStmt'],
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
					values['ContentDocID'] = result.ContentDocID;
					//values['ComposeEmail'] = result.ComposeEmail;
					resolve(values);
				}
			}).catch(error => {
				console.log('error :' + error);
				reject(error);
			});
		});
	}

	function changeStatementFormat(values, invoke, ds) {
		var formatType = values['StatementFormat'];
		return new Promise(function (resolve, reject) {
			if (values['AttachCheckBox']) {
				if (formatType) {
					invoke({
						className: 'AttachStatementOnAccount',
						functionName: 'funcName',
						values: values
					}).then(result1 => {
						var result = JSON.parse(JSON.stringify(result1));
						resolve(result);
					}).catch(error => {
						console.log('error :' + error);
						reject(error);
					});
				}
			} else {
				resolve({});
			}
		});
	}

	function generateStatement(values, invoke, ds) {
		debugger;
		var attId = values['AttachmentIDSendStmt'];
		var formatType = values['StatementFormat'];
		//lightning/r/ContentDocument/069a5000009Bg3ZAAS/view
		return new Promise(function (resolve, reject) {
			//-- Start | FIN-7269 | 11-April-2025 -- (Attachment Related changes)//
			if(values.hasOwnProperty('ContentDocID')) {
				debugger;
				let url = "/lightning/r/ContentDocument/"+ values['ContentDocID'] +"/view";
				window.open(url, '_blank');
				resolve({});
			//-- End | FIN-7269 | 11-April-2025 -- (Attachment Related changes)//
			} else {

			
			if (!formatType) {
				reject('Please select Statement Format');
			} else if (values['ListView'] == '') {
				resolve({});
			} else {
				if (formatType == 'PDF' && values['ContentIDSendStmt']) {
					invoke({
						className: 'SendStatementActionController',
						functionName: 'generatePublicURLforPDF',
						values: values
					}).then(result => {
						var url = result.publicURL;
						window.open(url, '_blank');
						resolve({});
					}).catch(error => {
						console.log('error :' + error);
						reject(error);
					});
				}
				else {
					values.preview = true;
					// gog.createStatementAttachment(values, invoke, ds, fireEvent, ref, rowvals, NavigationMixin, rowNum, ShowToastEvent, ExcelJS).then(result1 => {
					gog.createStatementAttachment(values, invoke, ds, fireEvent, ref, rowvals, NavigationMixin, rowNum, ShowToastEvent, null, null, ExcelJS).then(result1 => {
						debugger;
						var result = JSON.parse(JSON.stringify(result1));
						delete result.preview;
						attId = result['AttachmentIDSendStmt'];
						var url = "/servlet/servlet.FileDownload?file=" + attId;
						window.open(url, '_blank');
						resolve({});
					}).catch(err => {
						reject(err);
					});
				}
			}
			}
		});
	}

	function onChangePromiseAmount(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum) {
		return new Promise(function (resolve, error) {
			if (values.TransactionList[rowNum]['PromisedAmount'] <= 0 || values.TransactionList[rowNum]['PromisedAmount'] > values.TransactionList[rowNum]['celsrm__Balance__c']) {
				if (values.TransactionList[rowNum]['PromisedAmount'] <= 0) {
					values.ggErrorMessage = 'Invoice ' + values.TransactionList[rowNum]['nameSort'] + ' : Promised amount should not be less than or equal to 0'
				} else if (values.TransactionList[rowNum]['PromisedAmount'] > values.TransactionList[rowNum]['celsrm__Balance__c']) {
					values.ggErrorMessage = 'Invoice ' + values.TransactionList[rowNum]['nameSort'] + ' : Promised amount should not be greater than invoice amount'
				}
			}
			resolve(values);
		});
	}
	//-- Common Functions --//
	function showToast(stTitle, stMessage, stVariant, stMode, stDispatchFunction, ShowToastEvent) {
		stDispatchFunction.dispatchEvent(new ShowToastEvent({
			title: stTitle,
			message: stMessage,
			variant: stVariant,
			mode: stMode
		}));
	};

	function onSubmitSendEmail(values, invoke, ds) {
		return new Promise(function (resolve, reject) {
			if (values['ContentIDSendStmt'] && values['ContentIDSendStmt'] != null) {
				invoke({
					className: 'SendStatementActionController',
					functionName: 'deleteAttachmentAfterSendStatement',
					values: values
				}).then(result => {
					resolve(result);
				}).catch(error => {
					console.log('error :' + error);
					reject(error);
				});
			} else {
				resolve({});
			}

		});
	}

	function validateReversePromise(values, invoke, dataServiceObj, fireEvent, ref, rowvals, NavigationMixin, rowNum, ShowToastEvent) {
		return new Promise(function (resolve, reject) {
			debugger;
			invoke({
				className: 'PromiseToPayActionController',
				functionName: 'validateReversePromise',
				values: values
			}).then(result => {
				if (result) {
					if (!result.success) {
						ref.dispatchEvent(new ShowToastEvent({
							title: "Error",
							message: result.errorMessage,
							variant: "error",
							mode: "dismissable"
						}));
						resolve({});
					} else {
						let customChangeHandler = {
							"callingControlName": "Group1",
							"targetScreen": "ReversePromise",
							"targetScreenSize": "medium-width",
							"sourceControlName": '',
							"vals": values
						};
						fireEvent(ref.pageRef, 'openChildScreen_' + ref.additionalAttributes.screenName + "Group1", customChangeHandler);
						resolve({});
					}
				}
			}).catch(error => {
				console.log('error :' + error);
				reject(error);
			});
		});
	}

	//-- Start | FIN-5817 | Changed By Megha | 8 July 2024 --//
	function submitSnoozeUnsnooze(values, invoke, dataServiceObj, fireEvent, ref, rowvals, NavigationMixin, rowNum, ShowToastEvent) {
		return new Promise(function (resolve, reject) {
			fireEvent(ref.pageRef, 'refreshDataGrid_Account Collection Activity_collectionActivity', null);
			resolve({});
		});
	}
	//-- End | FIN-5817 | Changed By Megha | 8 July 2024 --//
	//-- Start | FIN-7812 | Changed By Ravi | 14 July 2025 --//
	const getCurrencySymbol = (currencyKey) => {
		if(currencyKey == 'INR') {
			return 'INR';
		}
		else {
			return (0).toLocaleString(
			'en-US',
			{
				style: 'currency',
				currency: currencyKey,
				minimumFractionDigits: 0,
				maximumFractionDigits: 0,
			}
		).replace(/[0-9\u0660-\u0669]/g, '').trim()
		}
	}
	function bufferToBase64(buffer, mimeType) {
		return new Promise((resolve, reject) => {
			const blob = new Blob([buffer], { type: mimeType });
			const reader = new FileReader();
			reader.onload = function () {
				const dataUrl = reader.result;
				const base64 = dataUrl.split(',')[1]; // Remove the data URL header
				resolve(base64);
			};
			reader.onerror = reject;
			reader.readAsDataURL(blob);
		});
	}
	
	function getAlignmentByType(type) {
		switch (type) {
			case 'currency':
			case 'number':
				return { horizontal: 'right' };

			case 'date':
				return { horizontal: 'left' };

			case 'text':
			default:
				return { horizontal: 'left' };
		}
	}
	//-- End | FIN-7812 | Changed By Ravi | 14 July 2025 --//
	//-- Start | FIN-7406 | Changed By Megha | 11 April 2025 --//
	function createStatementAttachment(values, invoke, ds, fireEvent, cmp, rowvals, NavigationMixin, rowNum, ShowToastEvent) {
		debugger;
		if (values['StatementFormat'] == null || values['StatementFormat'] == "") {
			values['StatementFormat'] = 'PDF'
		}
		//-- Start | FIN-8509 | Changed by Ravi | 13-Oct-2025 --//
		let fileName = values['fileName'] ? values['fileName'] : 'BillingStatement';
		//-- Ends | FIN-8509 | Changed by Ravi | 13-Oct-2025 --//
		return new Promise(function (resolve, reject) {
			if(values['AttachCheckBox'] || values.preview) {
					invoke({
						className: 'SendEmailActionController',
						functionName: 'createStatementAttachment',
						values: values
					}).then(async result => {
						//-- Start | FIN-7812 | Changed By Ravi | 14 July 2025 --//
						let formatType = values['StatementFormat'];
						//-- Start | FIN-9543 | Changes by Dhwanil | 06-Arl-2026 --//
						result['fontLibraryUrl'] = '/resource/FontLibrary';
						//-- ends | FIN-9543 | Changes by Dhwanil | 06-Arl-2026 --//
						if(result.ggErrorMessage) {
							gog.showToast('Error', result.ggErrorMessage, 'error', 'dismissable', cmp, ShowToastEvent);
							resolve({});
						} 
						//-- Start | FIN-9048 | Chanegs by Asera 02-Feb-2026--//
						else if (result.templateBody) {
							//-- Start | FIN-9409 | Changed by Ravi | 23-Mar-2026 --//
							const contentHtml = await window.gog.statementUtils.getProcessedTemplateHtml(result, true, cmp);
							//-- End | FIN-9409 | Changed by Ravi | 23-Mar-2026 --//
							if (formatType == "Excel") {
								values["finalContent"] = await window.gog.statementUtils.generateExcelFromHtml(contentHtml, fileName, ExcelJS, result);
							} else if (formatType == "PDF") {
								//-- Start | FIN-9410 | Changed by Ravi | 16-Mar-2026 --//
								values["finalContent"] = await window.gog.statementUtils.generatePdfFromHtml(contentHtml, window, result, 'landscape');
								//-- End | FIN-9410 | Changed by Ravi | 16-Mar-2026 --//
							}
							delete result['templateBodyImageBase64Map']; // FIN-9351
							if (result.hasOwnProperty("ComposeEmail") &&
								typeof result.ComposeEmail === "object" &&
								Object.keys(result.ComposeEmail).length > 0) {
								values["ComposeEmail"] = result.ComposeEmail;
							}
							// END || FIN-7214
							//-- Send Excel attachment body to apex class to create attachment (not contentversion) --//
							invoke({
								className: 'SendStatementAttachmentInsert',
								functionName: 'Send Statement',
								values: values
							}).then(result => {
								debugger;
								gog.onAttachGenerateCompletion(result, invoke, ds).then(result => {
									resolve(result);
								}).catch(err => {
									reject(err);
								});
							}).catch(error => {
								console.log('error :' + error);
								reject(error);
							});
						}
						//-- End | FIN-9048 | Chanegs by Asera 02-Feb-2026--//
						else if (formatType == "Excel") {
							//-- Generate Excel Body --//
							
							const data = result.DueTransList;
							const newLstFields = result.selectedFields;
							const newLstFieldsLabel = result.selectedFieldsLabel;
							let fieldTypeMap = result.selectedFieldTypes;

							if (typeof result.selectedFieldTypes === 'string') {
								fieldTypeMap = JSON.parse(result.selectedFieldTypes);
							}

							const columns = newLstFields.map((field, index) => {
								const apexType = fieldTypeMap?.[field];

								let type = 'text';

								if (apexType === 'currency') {
									type = 'currency';
								} else if (apexType === 'number') {
									type = 'number';
								} else if (apexType === 'date') {
									type = 'date';
								} else if (apexType === 'link') {
									type = 'text'; // ExcelJS does not support hyperlink formatting here
								}

								return {
									fieldName: field,
									label: newLstFieldsLabel[index],
									isExport: true,
									type
								};
							});

							 const workbook = new ExcelJS.Workbook();
							//-- Start | FIN-8509 | Changed by Ravi | 13-Oct-2025 --//
							const worksheet = workbook.addWorksheet(fileName);

							//Code to add image and company information
							let currentRow = 1;

							/* -------------------------------
							Company Logo
							-------------------------------- */
							if (result.hasCompanyLogo) {
							const logoUrl = '/resource/CompanyLogo'; // static resource
							const response = await fetch(logoUrl);
							const blob = await response.blob();
							const logoBase64 = await blobToBase64(blob);
							
							const imageId = workbook.addImage({
								base64: logoBase64,
								extension: 'png'
							});

							worksheet.addImage(imageId, {
								tl: { col: 0, row: currentRow - 1 },
								ext: { width: 300, height: 100 }
							});

							currentRow += 6;
							currentRow += 1;

							// Divider line (border)
							worksheet.mergeCells(`A${currentRow}:H${currentRow}`);
							worksheet.getCell(`A${currentRow}`).border = {
								bottom: { style: 'thin' }
							};

							currentRow += 1;
							}

							/* -------------------------------
							Title
							-------------------------------- */
							worksheet.mergeCells(`A${currentRow}:H${currentRow}`);
							const titleCell = worksheet.getCell(`A${currentRow}`);
							titleCell.value = 'STATEMENT OF ACCOUNT';
							titleCell.font = {
							name: 'Times New Roman',
							size: 20,
							bold: true
							};
							titleCell.alignment = { horizontal: 'center' };

							currentRow++;

							worksheet.mergeCells(`A${currentRow}:H${currentRow}`);
							worksheet.getCell(`A${currentRow}`).border = {
							bottom: { style: 'thin' }
							};

							currentRow += 1;

							/* -------------------------------
							Organization Name
							-------------------------------- */
							if (result.orgName) {
							worksheet.mergeCells(`A${currentRow}:D${currentRow}`);
							const orgCell = worksheet.getCell(`A${currentRow}`);
							orgCell.value = result.orgName;
							orgCell.font = {
								name: 'Times New Roman',
								size: 16,
								bold: true
							};
							}

							currentRow += 1;

							/* -------------------------------
							Customer Summary Box (Right Side)
							-------------------------------- */
							if (result.customerName) {
							const startCol = 6; // Right side
							let r = currentRow;

							const headerStyle = {
								font: { bold: true },
								fill: {
								type: 'pattern',
								pattern: 'solid',
								fgColor: { argb: 'DEF2F1' }
								},
								alignment: { horizontal: 'center', vertical: 'middle' },
								border: {
								top: { style: 'thin' },
								left: { style: 'thin' },
								bottom: { style: 'thin' },
								right: { style: 'thin' }
								}
							};

							const valueStyle = {
								font: { bold: true },
								alignment: { horizontal: 'center', vertical: 'middle' },
								border: {
								top: { style: 'thin' },
								left: { style: 'thin' },
								bottom: { style: 'thin' },
								right: { style: 'thin' }
								}
							};

							const summaryData = [
								['Customer Name :', result.customerName || ''],
								['Customer Number :', result.customerNumber || ''],
								['Statement Date :', result.statementDate || '']
							];

							summaryData.forEach(([label, value]) => {
								worksheet.mergeCells(r, startCol, r, startCol + 1);
								worksheet.getCell(r, startCol).value = label;
								Object.assign(worksheet.getCell(r, startCol), headerStyle);

								r++;

								worksheet.mergeCells(r, startCol, r, startCol + 1);
								worksheet.getCell(r, startCol).value = value;
								Object.assign(worksheet.getCell(r, startCol), valueStyle);

								r++;
							});

							currentRow = r + 1;
							}

							//-- Ends | FIN-8509 | Changed by Ravi | 13-Oct-2025 --//
							// Format header row
							const headerRow = worksheet.getRow(currentRow);
							headerRow.values = newLstFieldsLabel;

							headerRow.eachCell((cell) => {
								//-- Start | FIN-8048 | Changed by Ravi | 29 July 2025 --//
								cell.font = { bold: true};
								cell.border = {
									top: { style: 'thin' },
									left: { style: 'thin' },
									bottom: { style: 'thin' },
									right: { style: 'thin' }
								}
								cell.alignment = { horizontal: 'center', vertical: 'middle' };
							});

							// Define columns using newLstFields
							worksheet.columns = newLstFields.map(field => ({ key: field, width: 20 }));

							// Add data rows starting from the 2nd row
							let totalMap = {}; //FIN-8285 | Changed by Asera | 23-Oct-2025 --//
							data.forEach((record, index) => {
								const row = worksheet.getRow(++currentRow);

								newLstFields.forEach((fieldName, colIndex) => {
									let value = record[fieldName] || '';
									// if(fieldName.toLowerCase().includes('balance')){
									// 	value = record['Balance'];
									// } 
									const cell = row.getCell(colIndex + 1);
									cell.value = value;

									// get column definition
									const columnDef = columns.find(c => c.fieldName === fieldName);
									if (columns.find(c => c.fieldName === fieldName || c.name === fieldName)?.type === 'currency') {
										const currencyCode = record['CurrencyIsoCode'];
										if (currencyCode) {
											const currencySymbol = getCurrencySymbol(currencyCode);
											row.getCell(colIndex + 1).numFmt = '[$' + currencySymbol + '] #,##0.00';
											if (fieldName?.toLowerCase().endsWith('balance__c')) {
												if (totalMap[currencyCode]) {
													totalMap[currencyCode] = totalMap[currencyCode] + parseFloat(value);
												} else {
													totalMap[currencyCode] = parseFloat(value);
												}
											}
											
										}
									}

									// apply alignment
									cell.alignment = getAlignmentByType(columnDef?.type);

									if (columnDef?.type === 'currency') {
										const currencyCode = record['CurrencyIsoCode'];
										if (currencyCode) {
											const currencySymbol = getCurrencySymbol(currencyCode);
											cell.numFmt = '[$' + currencySymbol + '] #,##0.00';
										}
									}
								});

								// Apply borders after all cells are populated
								row.eachCell((cell) => {
									cell.border = {
										top: { style: 'thin' },
										left: { style: 'thin' },
										bottom: { style: 'thin' },
										right: { style: 'thin' }
									};
								});
							});
							++currentRow;
							//-- Start | FIN-8285 | Changed by Asera | 23-Oct-2025 --//
							// Add total rows for each currency in totalMap
							if (Object.keys(totalMap).length > 0) {
								let recordCounter = data.length + 2;
								for (const [currencyCode, totalValue] of Object.entries(totalMap)) {
									const rowCounter = recordCounter++;
									const totalRow = worksheet.getRow(currentRow++);
									const currencySymbol = getCurrencySymbol(currencyCode);
									// Set the total title in the first cell
									const totalAmountColumnIndex = columns.length;
									totalRow.getCell(totalAmountColumnIndex-1).value = 'Total (' + currencySymbol + ')';
									totalRow.getCell(totalAmountColumnIndex-1).alignment = { horizontal: 'right' };

									worksheet.mergeCells({
										top: currentRow,
										left: 1,
										bottom: rowCounter,
										right: columns.length - 1
									});


									// Set the total value in the aggregation column
									if (totalAmountColumnIndex > 0) {
										totalRow.getCell(totalAmountColumnIndex).value = totalValue;
										totalRow.getCell(totalAmountColumnIndex).numFmt = '[$' + getCurrencySymbol(currencyCode) + '] #,##0.00';

									}
									// Style the total row
									totalRow.eachCell((cell) => {
										cell.font = { bold: true };
										cell.border = {
											top: { style: 'thin' },
											left: { style: 'thin' },
											bottom: { style: 'thin' },
											right: { style: 'thin' }
										}
									});
								}
							}
							//-- End | FIN-8285 | Changed by Asera | 23-Oct-2025 --//

							// Write the workbook to a binary string
							const buffer = await workbook.xlsx.writeBuffer();
							// var temp = window.btoa(String.fromCharCode(...new Uint8Array(buffer)));
							var temp = await bufferToBase64(buffer, 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
							values["finalContent"] = temp;
							// START || FIN-7214 || Fixed refresh of composeEmail Body for sendStatement if addAttachment is checked
							// values["ComposeEmail"] = result.ComposeEmail;
							if (result.hasOwnProperty("ComposeEmail") &&
								typeof result.ComposeEmail === "object" &&
								Object.keys(result.ComposeEmail).length > 0) {
								values["ComposeEmail"] = result.ComposeEmail;
							}
							// END || FIN-7214
							//-- Send Excel attachment body to apex class to create attachment (not contentversion) --//
							invoke({
								className: 'SendStatementAttachmentInsert',
								functionName: 'Send Statement',
								values: values
							}).then(result => {
								debugger;
								gog.onAttachGenerateCompletion(result, invoke, ds).then(result => {
									resolve(result);
								}).catch(err => {
									reject(err);
								});
								delete values.finalContent;
							}).catch(error => {
								console.log('error :' + error);
								reject(error);
							});

							// Create a Blob from the binary string
							// const blob = new Blob([buffer], { type: "application/octet-stream" });
						//-- End | FIN-7812 | Changed By Ravi | 14 July 2025 --//
						} else if (formatType == "PDF") {
							// << COMMENT - START - MM - FIN-9616 - [Akzonobel] [Collection] Switch to VF Page from JS Code >> 
							/*
							if (!window.jspdf) {
								console.error('jsPDF not loaded');
								return;
							}

							// Landscape to match wide tables
							const doc = window.jspdf.jsPDF({
									orientation: 'l',   // 'p' = portrait, 'l' = landscape
									unit: 'pt',         // 'pt', 'mm', 'cm', 'in'
									format: 'a4',       // 'a4', 'letter', [210, 297]
									compress: true,     // enable internal PDF compression
									precision: 2        // reduce float precision (smaller size)
								});

							
							let y = 40; // starting vertical position
							//-- Start | FIN-9250 | Chanegs by Asera 18-Feb-2026--//
							const LOCAL = (result.LOCALE || 'en-US').replace('_', '-');;
							//-- Ends | FIN-9250 | Chanegs by Asera 18-Feb-2026--//
							// Add Company Logo if exists
							if (result.hasCompanyLogo) {
								const logoUrl = '/resource/CompanyLogo'; // static resource
								const response = await fetch(logoUrl);
								const blob = await response.blob();
								const base64 = await blobToBase64(blob);

								doc.addImage(base64, 'PNG', 40, y, 100, 50); // x, y, width, height
								y += 60; // space after logo

								doc.setDrawColor(0);       // black line
								doc.setLineWidth(0.5);     // thin line
								doc.line(40, y, 800, y);
								y += 20;
							}

							// Add Title
							doc.setFontSize(20);
							doc.setFont('Times New Roman', 'bold');
							doc.text('STATEMENT OF ACCOUNT', 50, y);
							y += 10;

							doc.setDrawColor(0);       // black line
							doc.setLineWidth(0.5);     // thin line
							doc.line(40, y, 590, y);
							y += 20;

							if(result.orgName){
								// Organization Name
								doc.setFontSize(16);
								doc.text(result.orgName, 50, y);
								y += 20;
							}
							
							if(result.customerName){
								y -= 60;
								const summaryStartX = 600;   // right side position
								const summaryStartY = y;     // current Y
								const boxWidth = 180;

								const headerStyle = {
									fillColor: [222, 242, 241], // light teal
									fontStyle: 'bold'
								};

								const valueStyle = {
									fillColor: [255, 255, 255],
									fontStyle: 'bold'
								};
								//--Start | FIN-9250 | Changed by Dhwanil | 18-Feb-2026 --//
								doc.autoTable({
								startY: summaryStartY,
								margin: { left: summaryStartX },
								tableWidth: boxWidth,
								body: [
									[{ content: 'Customer Name : ', styles: headerStyle }],
									[{ content: result.customerName || '', styles: valueStyle }],
									[{ content: 'Customer Number : ', styles: headerStyle }],
									[{ content: result.customerNumber || '', styles: valueStyle }],
									[{ content: 'Statement Date : ', styles: headerStyle }],
									[{ content: new Intl.DateTimeFormat(LOCAL).format(new Date(result.statementDate)) || '', styles: valueStyle }]
								],
								theme: 'grid',
								styles: {
									font: 'Time new roman',
									fontSize: 12,
									halign: 'center',
									valign: 'middle',
									lineWidth: 0.8,
									lineColor: [0, 0, 0]
								}
								});
								//--Ends | FIN-9250 | Changed by Dhwanil | 18-Feb-2026 --//
								// move y below the table
								y = doc.lastAutoTable.finalY + 20;
							}

							let startY = y;

							const data = result.DueTransList;
							const newLstFields = result.selectedFields;
							const newLstFieldsLabel = result.selectedFieldsLabel;
							let fieldTypeMap = result.selectedFieldTypes;

							if (typeof result.selectedFieldTypes === 'string') {
								fieldTypeMap = JSON.parse(result.selectedFieldTypes);
							}
							// Column metadata
							const columns = newLstFields.map((field, index) => {
								const typeFromApex = fieldTypeMap?.[field];

								let type = 'text';

								if (typeFromApex === 'currency' || typeFromApex === 'double' || typeFromApex === 'decimal') {
									type = 'currency';
								} else if (typeFromApex === 'number' || typeFromApex === 'integer') {
									type = 'number';
								} else if (typeFromApex === 'date' || typeFromApex === 'datetime') {
									type = 'date';
								}

								return {
									fieldName: field,
									label: newLstFieldsLabel[index],
									isExport: true,
									type
								};
							});

							// ---------- Header ----------
							doc.setFontSize(12);
							doc.text(fileName, 14, 12);

							// ---------- Prepare Table ----------
							const head = [newLstFieldsLabel];
							const body = [];
							const totalMap = {};

							// Populate rows
							data.forEach(record => {
								const row = [];

								newLstFields.forEach(fieldName => {
									let value = record[fieldName] ?? '';

									const columnType = columns.find(c => c.fieldName === fieldName)?.type;

									if (columnType === 'currency') {
										const currencyCode = record.CurrencyIsoCode;
										if (currencyCode && value !== '') {
											const symbol = getCurrencySymbol(currencyCode);
											value = `${symbol} ${parseFloat(value).toFixed(2)}`;

											// Total logic
											if (fieldName?.toLowerCase().endsWith('balance__c')) 
											{
												totalMap[currencyCode] =
													(totalMap[currencyCode] || 0) + parseFloat(value.replace(symbol, ''));
											}
										}
									}
									else if (columnType === 'date') {
										//--Start | FIN-9250 | Changed by Dhwanil | 18-Feb-2026 --//
										value = value ? new Intl.DateTimeFormat(LOCAL).format(new Date(value)) : '';
										//--Ends | FIN-9250 | Changed by Dhwanil | 18-Feb-2026 --//
									}

									row.push(value);
								});

								body.push(row);
							});

							// ---------- Totals ----------
							Object.entries(totalMap).forEach(([currencyCode, total]) => {
								const symbol = getCurrencySymbol(currencyCode);
								const totalRow = new Array(newLstFields.length).fill('');

								totalRow[newLstFields.length - 2] = `Total (${symbol})`;
								totalRow[newLstFields.length - 1] = `${symbol} ${total.toFixed(2)}`;

								body.push(totalRow);
							});

							//-- Start | FIN-9543 | Changed by Dhwanil | 06-Apr-2026 --//
							const attachmentFontFamily = result['attachmentFontFamily'] || 'Time new roman';
							const attachmentFontSize = (result['attachmentFontSize'] || '9');
							//-- End | FIN-9543 | Changed by Dhwanil | 06-Apr-2026 --//

							// ---------- Render Table ----------
							//-- Start | FIN-9543 | Changed by Dhwanil | 06-Apr-2026 --//
							doc.autoTable({
								startY,
								head,
								body,
								theme: 'grid',
								styles: {
									font: attachmentFontFamily,
									fontSize: parseInt(attachmentFontSize),
									cellPadding: 4,
									valign: 'middle',
									lineWidth: 0.8,
									lineColor: [0, 0, 0]
								},
								headStyles: {
									halign: 'center',
									font: attachmentFontFamily,
									fontStyle: 'bold',
									fillColor: [222, 242, 241],
									textColor: [0, 0, 0],
									lineWidth: 0.8,
									lineColor: [0, 0, 0]
								},
								bodyStyles: {
									font: attachmentFontFamily,
									lineWidth: 0.8,
									lineColor: [0, 0, 0]
								},
								columnStyles: columns.reduce((acc, col, idx) => {
									if (col.type === 'currency' || col.type === 'number') {
										acc[idx] = { halign: 'right' };
									}
									return acc;
								}, {}),
								didParseCell(data) {
									// Bold total rows
									if (data.row.index >= body.length - Object.keys(totalMap).length) {
										data.cell.styles.fontStyle = 'bold';
									}

									// Right-align currency
									if (
										columns[data.column.index]?.type === 'currency' &&
										data.section === 'body'
									) {
										data.cell.styles.halign = 'right';
									}
								}
							});
							//-- End | FIN-9543 | Changed by Dhwanil | 06-Apr-2026 --//
							// ---------- Convert to Base64 ----------
							//const pdfBase64 = doc.output('datauristring').split(',')[1];
							//values.finalContent = pdfBase64;
							const buffer = doc.output('arraybuffer');
							values.finalContent = await bufferToBase64(buffer, 'application/pdf');

							invoke({
								className: 'SendStatementAttachmentInsert',
								functionName: 'Send Statement',
								values: values
							}).then(result => {
								debugger;
								gog.onAttachGenerateCompletion(result, invoke, ds).then(result => {
									resolve(result);
									delete values.finalContent;
								}).catch(err => {
									reject(err);
								});
							}).catch(error => {
								console.log('error :' + error);
								reject(error);
							});
							*/
							// << COMMENT - END - MM - FIN-9616 - [Akzonobel] [Collection] Switch to VF Page from JS Code >> 
							gog.onAttachGenerateCompletion(result, invoke, ds).then(result => {
								resolve(result);
							}).catch(err => {
								reject(err);
							});

						}else {
							gog.onAttachGenerateCompletion(result, invoke, ds).then(result => {
								resolve(result);
								delete values.finalContent;
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
			} else {
				//need to remove statement
				var compMap = values['ComposeEmail'];
				if(compMap && compMap.hasOwnProperty('attachment') && compMap['attachment'].length > 0) {
					for(var i=0;i<compMap['attachment'].length;i++) {
						//-- Start | FIN-8509 | Changed by Ravi | 13-Oct-2025 --//
						if(compMap['attachment'][i].Title.includes(fileName)) {
						//-- Ends | FIN-8509 | Changed by Ravi | 13-Oct-2025 --//
							compMap['attachment'].splice(i, 1);
							break;
						}
					}
				}
				resolve(values);
			}
		});
	}
	//-- End | FIN-7406 | Changed By Megha | 11 April 2025 --//

	// << Start - ND - FIN-8132 - Email Templates based on Account Locale >>
	// << CHANGE - MM - FIN-8174 - Dynamic translated headers based account local | Renamed fucntion from onChangeCompanyCode -> onChangeAccountLocale>>
	function onChangeAccountLocale(values, invoke, dataServiceObj, fireEvent, cmp, rowvals, NavigationMixin, rowNum, ShowToastEvent) {
		debugger;
		return new Promise(function (resolve, reject) {
			// << CHANGE - MM - FIN-8174 - Dynamic translated headers based account local | Checking values['accountLocale'] instead of values['CompanyCode']>>
			if (values['accountLocale'] && values['accountLocale'] != null) {
				invoke({
					className: 'SendStatementActionController',
					// << CHANGE - MM - FIN-8174 - Dynamic translated headers based account local | Renamed fucntion from updateCompanyCode -> updateAccountLocale>>
					functionName: 'updateAccountLocale',
					values: values
				}).then(result => {
					// << CHANGE - MM - FIN-8174 - Dynamic translated headers based account local | Chanaged from result.CompanyCode -> result.accountLocale>>
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
	
	exports.onChangeAccountLocale = onChangeAccountLocale;
	// << End - ND - FIN-8132 - Email Templates based on Account Locale >>

	exports.showToast = showToast;
	//-- Account Level Actions --//
	exports.saveAccountNote = saveAccountNote;
	exports.onLoadAccountDetailTab = onLoadAccountDetailTab;
	exports.reverseDispute = reverseDispute;
	exports.reversePromise = reversePromise;
	exports.calculateTotalAmountTransaction = calculateTotalAmountTransaction;
	exports.OnChangeViewCreate = OnChangeViewCreate;
	exports.filterDataByAging = filterDataByAging;
	// exports.filterDataByView_old = filterDataByView_old;
	exports.onExportAll = onExportAll;
	exports.onExport = onExport;
	// exports.onchangeVendor = onchangeVendor;
	// exports.SearchProperty = SearchProperty;
	// exports.resetPropertySearch = resetPropertySearch;
	exports.getBillingAddress = getBillingAddress;
	exports.generateStatementFromTransactionGrid = generateStatementFromTransactionGrid;
	exports.deleteListView = deleteListView;
	exports.editListView = editListView;
	// exports.onPageLoadSetView_old = onPageLoadSetView_old;
	exports.createStatementAttachmentexportAll = createStatementAttachmentexportAll;
	exports.onAttachFormatCompletionexportAll = onAttachFormatCompletionexportAll;
	exports.onAttachGenerateCompletionexportAll = onAttachGenerateCompletionexportAll;
	exports.ExportPdfAll = ExportPdfAll;
	exports.openNoteScreen = openNoteScreen;
	exports.formatNumber = formatNumber;
	exports.formatPercentage = formatPercentage;

	exports.onPageLoadSetView = onPageLoadSetView;
	exports.filterDataByView = filterDataByView;
	exports.onChangeResponseByContact = onChangeResponseByContact;
	exports.onChangeIsFollowUp = onChangeIsFollowUp;
	//-- Send Statement & Send Email --//
	exports.handleTreatmentNotes = handleTreatmentNotes;
	exports.generateStatementForAttachment = generateStatementForAttachment;
	exports.createStatementAttachmentOnPreview = createStatementAttachmentOnPreview;
	exports.onAttachFormatCompletion = onAttachFormatCompletion;
	exports.onAttachGenerateCompletion = onAttachGenerateCompletion;
	exports.changeStatementFormat = changeStatementFormat;
	exports.generateStatement = generateStatement;
	//-- Promise To Pay --//
	exports.onChangePromiseAmount = onChangePromiseAmount;
	//-- Common Functions --//
	exports.onSubmitSendEmail = onSubmitSendEmail;
	exports.onLoadScoreCardTab = onLoadScoreCardTab;
	exports.validateReversePromise = validateReversePromise;
	exports.submitSnoozeUnsnooze = submitSnoozeUnsnooze;
	exports.createStatementAttachment = createStatementAttachment;
	//-- Start | FIN-8530 | Changed by Ravi | 10 Nov 2025 --//
	exports.removeChildAccount = removeChildAccount;
	//-- End | FIN-8530 | Changed by Ravi | 10 Nov 2025 --//

	//--- DO NOT CHANGE CODE | START ---//
	Object.defineProperty(exports, '__esModule', {
		value: true
	});
	//--- DO NOT CHANGE CODE | END ---//

})));
