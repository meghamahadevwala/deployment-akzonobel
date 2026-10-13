//--- DO NOT CHANGE CODE | START ---//
(function (global, factory) {
	typeof exports === 'object' && typeof module !== 'undefined' ? factory(exports) :
		typeof define === 'function' && define.amd ? define(['exports'], factory) :
			(factory((global.gog = global.gog || {})));
}(this, (function (exports) {
	'use strict';

	var version = "1.0.0";
	//--- DO NOT CHANGE CODE | END ---//	
	//--Depricated--//
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
		let tempVal = { 'AttachmentIDSendStmt': values['AttachmentIDSendStmt'], 'StatementFormat': values['StatementFormat'], 'ComposeEmail': values['ComposeEmail'],
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

	function onchangeVendor(values, invoke) {
		values.InvoiceNo = 'INV-1';
		//--- Below is a sample code which execute user's apex class. ---//
		return new Promise(function (resolve, error) {
			invoke({
				className: 'GOGCustomImplementation',
				functionName: 'funcName',
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
	function SearchProperty(values, invoke) {
		console.log("====SearchProperty=====");
		values['datagrid'] = [{
			id: 'a',
			opportunityName: 'Cloudhub',
			confidence: 0.2,
			amount: 30000,
			contact: 'jrogers@cloudhub.com',
			phone: '2352235235',
			trendIcon: 'utility:down'
		}];
		return new Promise(function (resolve, error) {
			resolve(values);

		});
	}
	function resetPropertySearch(values, invoke, dataServiceObj) {
		return new Promise(function (resolve, reject) {
			dataServiceObj.invokeDataServiceWithId('a00p0000007ofnSAAQ', values, false).then(result => {
				var newdata = [];
				console.log("JSON.parse(JSON.stringify(result)):" + JSON.stringify(result));
				if (Array.isArray(JSON.parse(JSON.stringify(result)))) {
					newdata = JSON.parse(JSON.stringify(result));
				} else {
					if (!this.isEmptyObject(result)) {
						newdata.push(JSON.parse(JSON.stringify(result)));
					}
				}
				values['datagrid'] = newdata;
				//for (var fieldname in result) {
				//	this.values[fieldname] = result[fieldname];
				//}
				resolve(values);
			}).catch(error => {
				console.log('error :' + error);
				reject(error);
			});

		});
	}
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

	function onPageLoadSetView(values, invoke, dataServiceObj, fireEvent, ref) {
		//console.log('values>>>>>'+JSON.stringify(values));
		var screenName = values['ggScreenName'];
		return new Promise(function (resolve, reject) {
			invoke({
				className: 'defaultViewClass',
				functionName: 'funcName',
				values: values
			}).then(result1 => {
				//resolve(result);
				var result = JSON.parse(JSON.stringify(result1));
				if (result['ListView']) {
					if (result.l_values.length > 0) {
						for (let tempVal of result.l_values) {
							for (let tempfield of result.updatedColumns) {
								if (tempfield.type == 'text' && tempVal[tempfield.fieldName] != null && tempVal[tempfield.fieldName] != undefined) {
									if (tempVal[tempfield.fieldName].includes("\n")) {
										tempVal[tempfield.fieldName] = tempVal[tempfield.fieldName].replace(/\n/g, '&nbsp');
									}
								}
								if (tempfield.fieldName == 'Name') {
									tempVal.InvoiceNo = tempVal.Name;
									tempVal.nameSort = tempVal.Name;
									let key = '<a href="' + '/' + tempVal['Id'] + '"' + ' target="_blank">' + tempVal['Name'] + '</a>';
									tempVal.Name = key;
									

								} else if (tempfield.fieldName == 'celsrm__Notes__c') {

									if (tempVal['celsrm__Notes__c'] == undefined) {

										tempVal.celsrm__Notes__c = "";
										tempVal.celsrm__Notes_sort__c = "";
									} else {
										tempVal.celsrm__Notes_sort__c = tempVal['celsrm__Notes__c'];
										var tempNt = tempVal['celsrm__Notes__c'].replace('"', '&quot;');
										var notesVal = tempNt;

										//if(tempNt.length > 30)
										//notesVal  = tempNt.substring(0,20)+'...';
										let key = '<img src="/resource/NotesIcon" target="_blank" width="15" height="15" title=\"' + tempNt + '\">' + '<a ' + ' style="text-decoration: none;cursor: pointer; cursor: hand;" title=\"' + tempNt + '\" >' + notesVal + '</a>' + '</img>';
										tempVal.celsrm__Notes__c = key;
									}
								} else if (tempfield.fieldName == 'celsrm__Flag__c') {

									let imageUrl = '';
									let date = new Date();

									console.log('tempVal::' + JSON.stringify(tempVal));
									if (tempVal['celsrm__Disputed_Amount__c'] && tempVal['celsrm__Disputed_Amount__c'] != 0) {
										imageUrl = "<img src='/resource/celsrm__SRMResource/image/red.png' title='Disputed' alt='Disputed' width='16' height='16'>";
									} else {
										imageUrl = "<img src='/resource/celsrm__SRMResource/image/transparent.png' title='' alt='' width='16' height='16'>";
									}
									if (tempVal['celsrm__Promise_Date__c']) {
										let d = new Date(tempVal['celsrm__Promise_Date__c']);
										if (tempVal['celsrm__Is_Broken_Promise__c'] && tempVal['celsrm__Is_Broken_Promise__c'] == true) {
											imageUrl += "<img src='/resource/celsrm__SRMResource/image/BrokenPromise$.png' title='Broken Promise' alt='Broken Promise' width='16' height='16'>";
										} else if (tempVal['celsrm__Promised_Amount__c'] && tempVal['celsrm__Promised_Amount__c'] != 0) {
											imageUrl += "<img src='/resource/celsrm__SRMResource/image/Promise$.png' title='Promised' alt='Promised' width='16' height='16'>";
										}

									}

									tempVal['celsrm__Flag__c'] = imageUrl;
								} else if (result.refField.indexOf(tempfield.fieldName) !== (-1)) {
									let st = tempfield.fieldName.substring(0, tempfield.fieldName.length - 1) + 'r';
									let tempmap = tempVal[st];
									if (tempmap !== undefined && tempmap !== null) {
										let key = '<a href="' + '/' + tempVal[tempfield.fieldName] + '"' + ' target="_blank">' + tempmap['Name'] + '</a>';
										tempVal[tempfield.fieldName] = key;
									}

								}
							}
						}
					}
					fireEvent(ref.pageRef, 'TransactionList_' + screenName + '_Columns', result.updatedColumns);
					fireEvent(ref.pageRef, 'TransactionList_' + screenName, result.l_values);
					//result['TransactionList'] = '';
					delete result.updatedColumns;
					delete result.l_values;
					result.Total = '<b> Total Balance = 0.00 </b>';
					result.totalSelectedinvoice = '<b>' + 'Selected Invoices : 0 </b>';
					resolve(result);
				}

			}).catch(error => {
				console.log('error :' + error);
				reject(error);
			});
		});
	}

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
					className: 'SearchClass',
					functionName: 'funcName',
					values: values
				}).then(result1 => {
					//resolve(result);
					var result = JSON.parse(JSON.stringify(result1));
					//-- Start | FIN-8530 | Changed by Ravi | 10 Nov 2025 --//
					// delete values.childAccountId;
					//-- End | FIN-8530 | Changed by Ravi | 10 Nov 2025 --//
					if (result.l_values.length > 0) {
						for (let tempVal of result.l_values) {
							for (let tempfield of result.updatedColumns) {
								if (tempfield.type == 'text' && tempVal[tempfield.fieldName] != null && tempVal[tempfield.fieldName] != undefined) {
									if (tempVal[tempfield.fieldName].includes("\n")) {
										tempVal[tempfield.fieldName] = tempVal[tempfield.fieldName].replace(/\n/g, '&nbsp');
									}
								}
								if (tempfield.fieldName == 'Name') {
									tempVal.nameSort = tempVal.Name;
									let key = '<a href="' + '/' + tempVal['Id'] + '"' + ' target="_blank">' + tempVal['Name'] + '</a>';
									tempVal.Name = key;
								} else if (tempfield.fieldName == 'celsrm__Notes__c') {
									if (tempVal['celsrm__Notes__c'] == undefined) {
										tempVal.celsrm__Notes_sort__c = "";
										tempVal.celsrm__Notes__c = "";
									} else {
										tempVal.celsrm__Notes_sort__c = tempVal['celsrm__Notes__c'];
										var tempNt = tempVal['celsrm__Notes__c'].replace('"', '&quot;');
										var notesVal = tempNt;

										//if(tempNt.length > 30)
										//notesVal  = tempNt.substring(0,20)+'...';
										let key = '<img src="/resource/NotesIcon" target="_blank" width="15" height="15" title=\"' + tempNt + '\">' + '<a ' + ' style="text-decoration: none;cursor: pointer; cursor: hand;" title=\"' + tempNt + '\" >' + notesVal + '</a>' + '</img>';
										tempVal.celsrm__Notes__c = key;
									}

								} else if (tempfield.fieldName == 'celsrm__Flag__c') {

									let imageUrl = '';
									let date = new Date();

									if (tempVal['celsrm__Disputed_Amount__c'] && tempVal['celsrm__Disputed_Amount__c'] != 0) {
										imageUrl = "<img src='/resource/celsrm__SRMResource/image/red.png' title='Disputed' alt='Disputed' width='16' height='16'>";
									} else {
										imageUrl = "<img src='/resource/celsrm__SRMResource/image/transparent.png' title='' alt='' width='16' height='16'>";
									}
									if (tempVal['celsrm__Promise_Date__c']) {
										let d = new Date(tempVal['celsrm__Promise_Date__c']);
										if (tempVal['celsrm__Is_Broken_Promise__c'] && tempVal['celsrm__Is_Broken_Promise__c'] == true) {
											imageUrl += "<img src='/resource/celsrm__SRMResource/image/BrokenPromise$.png' title='Broken Promise' alt='Broken Promise' width='16' height='16'>";
										} else if (tempVal['celsrm__Promised_Amount__c'] && tempVal['celsrm__Promised_Amount__c'] != 0) {
											imageUrl += "<img src='/resource/celsrm__SRMResource/image/Promise$.png' title='Promised' alt='Promised' width='16' height='16'>";
										}

									}

									tempVal['celsrm__Flag__c'] = imageUrl;
								} else if (result.refField.indexOf(tempfield.fieldName) !== (-1)) {
									let st = tempfield.fieldName.substring(0, tempfield.fieldName.length - 1) + 'r';
									let tempmap = tempVal[st];
									if (tempmap !== undefined && tempmap !== null) {
										let key = '<a href="' + '/' + tempVal[tempfield.fieldName] + '"' + ' target="_blank">' + tempmap['Name'] + '</a>';
										tempVal[tempfield.fieldName] = key;
									}
								}
							}
						}
					}
					fireEvent(ref.pageRef, 'TransactionList_' + screenName + '_Columns', result.updatedColumns);
					fireEvent(ref.pageRef, 'TransactionList_' + screenName, result.l_values);
					var finalText = '<b> Total Balance = 0.00 </b>';
					var totalSelectedinvoice = '<b>' + 'Selected Invoices : 0 </b>';
					resolve({ 'Total': finalText, 'totalSelectedinvoice': totalSelectedinvoice, 'isCurrentUserListView': result.isCurrentUserListView, 'TransactionList': [] });
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
			var d = new Date();
			console.log(d.getHours() + ':' + d.getMinutes() + ':' + d.getSeconds() + ':' + d.getMilliseconds());
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
						let balance = trxnLst[i]['celsrm__Balance__c'] ? Number(trxnLst[i]['celsrm__Balance__c']) : 0;
						if (trxnLst[i]['CurrencyIsoCode'] in amount) {
							amount[trxnLst[i]['CurrencyIsoCode']] += balance;
						} else {
							amount[trxnLst[i]['CurrencyIsoCode']] = balance;
						}
					}
					var str = '';
					for (var k in amount) {
						str += k + ' : ' + parseFloat(amount[k]).toFixed(2).replace(/(\d)(?=(\d{3})+\.)/g, '$1,') + ',';
					}
					if (str != '') {
						str = str.substring(0, str.length - 1);
					}
					totalSelectedinvoice = '<b>' + 'Selected Invoices : ' + len.toLocaleString() + '</b>';
					finalText = '<b> Total Balance : ' + str + '</b>';
				} else {
					d = new Date();
					console.log(d.getHours() + ':' + d.getMinutes() + ':' + d.getSeconds() + ':' + d.getMilliseconds());
					var tmp = 0.0;
					for (var i = 0; i < len; i++) {
						tmp += trxnLst[i]['celsrm__Balance__c'] ? trxnLst[i]['celsrm__Balance__c'] : 0;
					}
					totalSelectedinvoice = '<b>' + 'Selected Invoices : ' + len.toLocaleString() + '</b>';
					finalText = '<b>  Total Balance : ' + userCurrency + ' : ' + parseFloat(tmp).toFixed(2).replace(/(\d)(?=(\d{3})+\.)/g, '$1,') + '</b>';
					d = new Date();
					console.log(d.getHours() + ':' + d.getMinutes() + ':' + d.getSeconds() + ':' + d.getMilliseconds());
				}
			} else {
				d = new Date();
				console.log(d.getHours() + ':' + d.getMinutes() + ':' + d.getSeconds() + ':' + d.getMilliseconds());
				totalSelectedinvoice = '<b>' + 'Selected Invoices : 0 </b>';
				finalText = '<b> Total Balance : 0.00 </b>';
			}
			d = new Date();
			console.log(d.getHours() + ':' + d.getMinutes() + ':' + d.getSeconds() + ':' + d.getMilliseconds());
			resolve({ 'Total': finalText, 'totalSelectedinvoice': totalSelectedinvoice });
		});
	}
	function OnChangeViewCreate(values, invoke, ds, fireEvent, ref) {
		var ListViewName = values["ListView"];
		return new Promise(function (resolve, error) {
			window.location.reload(true);
			resolve(values);
		});


	}
	function openNoteScreen(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum) {
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
	function reversePromise(values, invoke, dataServiceObj, fireEvent, ref, rowvals, NavigationMixin, rowNum, ShowToastEvent) {
		var trxnLst = JSON.parse(JSON.stringify(values['TransactionList']));
		var showError = true;
		for (let trx of trxnLst) {
			if (trx.celsrm__Promised_Amount__c != 0) {
				showError = false;
				break;
			}
		}
		if (showError) {
			return new Promise(function (resolve, reject) {
				ref.dispatchEvent(new ShowToastEvent({
					title: "Error",
					message: "No Promise found on selected one or more Invoice (s)",
					variant: "error",
					mode: "dismissable"
				}));
				resolve({});
			});
			// } else if(confirm('Are you want to reverse the Promise to Pay?')) {
		} else {
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
		// else {
		// 	return new Promise(function(resolve, reject) {
		// 		resolve({});
		// 	});
		// }

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
					message: "There is no Dispute created for one or more selected Invoice(s)",
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
	exports.reverseDispute = reverseDispute;
	exports.reversePromise = reversePromise;
	exports.calculateTotalAmountTransaction = calculateTotalAmountTransaction;
	exports.OnChangeViewCreate = OnChangeViewCreate;
	exports.filterDataByAging = filterDataByAging;
	exports.filterDataByView = filterDataByView;
	exports.onExportAll = onExportAll;
	exports.onExport = onExport;
	exports.onchangeVendor = onchangeVendor;
	exports.SearchProperty = SearchProperty;
	exports.resetPropertySearch = resetPropertySearch;
	exports.getBillingAddress = getBillingAddress;
	exports.generateStatementFromTransactionGrid = generateStatementFromTransactionGrid;
	exports.deleteListView = deleteListView;
	exports.editListView = editListView;
	exports.onPageLoadSetView = onPageLoadSetView;
	exports.createStatementAttachmentexportAll = createStatementAttachmentexportAll;
	exports.onAttachFormatCompletionexportAll = onAttachFormatCompletionexportAll;
	exports.onAttachGenerateCompletionexportAll = onAttachGenerateCompletionexportAll;
	exports.ExportPdfAll = ExportPdfAll;
	exports.openNoteScreen = openNoteScreen;
	//--- DO NOT CHANGE CODE | START ---//
	Object.defineProperty(exports, '__esModule', {
		value: true
	});
	//--- DO NOT CHANGE CODE | END ---//

})));