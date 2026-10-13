//--- DO NOT CHANGE CODE | START ---//
(function (global, factory) {
	typeof exports === 'object' && typeof module !== 'undefined' ? factory(exports) :
		typeof define === 'function' && define.amd ? define(['exports'], factory) :
			(factory((global.gog = global.gog || {})));
}(this, (function (exports) {
	'use strict';

	var version = "1.0.0";
	var STATEMENT_PDF_TABLE_CHUNK_SIZE = 90000;
	//--- DO NOT CHANGE CODE | END ---//	

	function onPageLoadSetView(values, invoke, dataServiceObj, fireEvent, ref) {
		debugger
		//console.log('values>>>>>'+JSON.stringify(values));
		var screenName = values['ggScreenName'];
		return new Promise(function (resolve, reject) {
			invoke({
				className: 'TaskTreatmentController',
				functionName: 'returnGridData',
				values: values
			}).then(result1 => {
				//resolve(result);
				var result = JSON.parse(JSON.stringify(result1));
				let childObjectIds = [];
				let stepLen = result.listOfStep.length;
				if (stepLen > 0) {
					for (let step of result.listOfStep) {
						//-- Start | FIN-8048 | Changed By Dilshad | 13-Aug-2025 --//
						if (result[step].length > 0) {
							for (let tempVal of result[step]) {
								//-- End | FIN-8048 | Changed By Dilshad | 13-Aug-2025 --//
								childObjectIds.push(tempVal['Id']);
								for (let tempfield of result[step + 'columns']) {
									if (tempfield.type == 'text' && tempVal[tempfield.fieldName] != null && tempVal[tempfield.fieldName] != undefined) {
										if (tempVal[tempfield.fieldName].includes("\n")) {
											tempVal[tempfield.fieldName] = tempVal[tempfield.fieldName].replace(/\n/g, '&nbsp');
										}
									}
									tempVal.isSelected = true;
									if (tempfield.fieldName == 'RemoveCommunication') {
										let key = '<i class="fa fa-times" style="color:red;font-size: large;"></i>';
										tempVal.RemoveCommunication = key;

									} else if (tempfield.fieldName == 'Name') {
										tempVal.nameSort = tempVal.Name;
										//-- Starts | FIN-8506 | Changed by Ravi | 5 Nov 2025 --//
										// let key = '<a href="' + '/' + tempVal['Id'] + '"' + ' target="_blank">' + tempVal['Name'] + '</a>';
										//tempVal['Name-email'] = tempVal['Name'];
										// tempVal.Name = key;
										//-- Ends | FIN-8506 | Changed by Ravi | 5 Nov 2025 --//

									}
									//-- Starts | FIN-8506 | Changed by Ravi | 5 Nov 2025 --//
									// else if (result[step + 'refField'].indexOf(tempfield.fieldName) !== (-1)) {
									// 	if (tempfield.fieldName.includes('__c')) {
									// 		let st = tempfield.fieldName.substring(0, tempfield.fieldName.length - 1) + 'r';
									// 		let tempmap = tempVal[st];
									// 		if (tempmap !== undefined && tempmap !== null) {
									// 			//tempVal[tempfield.fieldName + '-email'] = tempmap['Name'];
									// 			let key = '<a href="' + '/' + tempVal[tempfield.fieldName] + '"' + ' target="_blank">' + tempmap['Name'] + '</a>';
									// 			tempVal[tempfield.fieldName] = key;
									// 		}

									// 	} else {
									// 		let st = tempfield.fieldName.substring(0, tempfield.fieldName.length - 2);
									// 		let tempmap = tempVal[st];

									// 		if (tempmap !== undefined && tempmap !== null) {
									// 			//tempVal[tempfield.fieldName + '-email'] = tempmap['Name'];
									// 			let key = '<a href="' + '/' + tempVal[tempfield.fieldName] + '"' + ' target="_blank">' + tempmap['Name'] + '</a>';
									// 			tempVal[tempfield.fieldName] = key;
									// 		}

									// 	}
									// }
									//-- Ends | FIN-8506 | Changed by Ravi | 5 Nov 2025 --//
								}
							}
						}
						fireEvent(ref.pageRef, step + '_' + screenName + '_Columns', result[step + 'columns']);
						//-- Start | FIN-8048 | Changed By Dilshad | 13-Aug-2025 --//
						fireEvent(ref.pageRef, step + '_' + screenName, result[step]);
						//-- End | FIN-8048 | Changed By Dilshad | 13-Aug-2025 --//
					}
				}
				if (result.status != 'Completed' && stepLen > 1) {
					result.showRemoveCommunicationButton = 'true';
				} else {
					result.showRemoveCommunicationButton = 'false';
				}
				result.childObjectIds = childObjectIds;
				result.isTaskScreen = true;
				resolve(result);

			}).catch(error => {
				console.log('error :' + error);
				reject(error);
			});
		});
	}
	function callToAgent(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum, ShowToastEvent) {

		return new Promise(function (resolve, reject) {

			let transMap = {};
			let transList = []
			// for(let trans of Object.values(values['childObjectIds'])){
			// 	transList.push(trans);
			// }
			if (values.childObjAPIName === 'celsrm__Transaction__c') {
				transMap.transactions = values['childObjectIds'];
			} else if (values.childObjAPIName === 'celsrm__Dispute__c') {
				transMap.disputes = values['childObjectIds'];
			}


			let customVals = {};
			customVals.account = values.accountId;
			customVals.contactNo = values.DialContact.replace("(", "").replace(")", "").replace(/\s/g, '').replace("-", "");;
			customVals.transactions = transMap;
			customVals.screenName = 'Log A Call';
			customVals.calledTo = values.ContactName.split("_")[0];

			invoke({
				nameSpace: '',
				className: 'OutgoingCallHandler',
				functionName: 'isCallerIdVerified',
				values: customVals
			}).then(result => {
				values = result;

				if (!result.isCallerIdVerified) {
					var data = {};
					data.phone = result.UserPhoneNumber;
					data.Message = 'Your ' + result.UserPhoneNumber + ' number is not verified. To verify please click on Verify button.';
					data.callLogDetails = customVals;

					let customChangeHandler = {
						"callingControlName": "Dial",
						"targetScreen": "CallerIDVerification",
						"targetScreenSize": "small-width",
						"sourceControlName": '',
						"vals": data
					};
					fireEvent(cmp.pageRef, 'openChildScreen_' + 'WCMContactCustomerScreen' + "Dial", customChangeHandler);
					resolve(result);
				} else {
					invoke({
						nameSpace: '',
						className: 'OutgoingCallHandler',
						functionName: 'callToCustomer',
						values: customVals
					}).then(result => {
						console.log(' Result >>>>>> ' + JSON.stringify(result));
						values = result;
						result['showCallingIcon'] = true;
						result['CallingIcon'] = '<div style="margin-top: 1.55rem;border: 1px solid rgb(208, 203, 203);border-top: 1px solid rgb(208, 203, 203);border-bottom: 1px solid rgb(208, 203, 203);border-top-left-radius: 7px;border-bottom-left-radius: 7px;z-index: 10;display: inline-flex;cursor: pointer;width: 45px;height: 32px;border-radius: 4px;box-shadow: 0 3px 10px 0 rgba(0, 0, 0, 0.04);background-color: #ffffff;padding-left: 6px;" >	<span class="width: 36px; height: 30px; text-align: center; margin-top: 7px;">		<img src="https://wcmqa-dev-ed--c.documentforce.com/sfc/dist/version/renditionDownload?rendition=ORIGINAL_Gif&amp;versionId=0683k000008fa8i&amp;operationContext=DELIVERY&amp;contentId=05T3k00000igphz&amp;page=0&amp;d=/a/3k0000008vMa/dX5tB_QLL04VwKZ67MovxqCC8iVDnMVe3JyhRCbzWhQ&amp;oid=00D3k000000tmG1&amp;dpt=null&amp;viewId="			alt="Call" />	</span></div>';
						resolve(result);
						cmp.dispatchEvent(new ShowToastEvent({
							title: "Success",
							message: 'Call has been initiated.',
							variant: "Success",
							mode: "dismissable"
						}));
						checkCallStatus(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum, ShowToastEvent, result)
						//location.reload();
					}).catch(error => {
						console.log('error :' + error);
						reject(error);
					});
				}

				//location.reload();
			}).catch(error => {
				console.log('error :' + error);
				reject(error);
			});



		});
	}
	function checkCallStatus(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum, ShowToastEvent, callResult) {
		console.log(' CustomerCommunication ID >>> ' + callResult.CustomerCommunicationId);
		return new Promise(function (resolve, reject) {

			invoke({
				nameSpace: '',
				className: 'OutgoingCallHandler',
				functionName: 'checkChangeStatus',
				values: callResult
			}).then(result => {
				console.log('result status >>> : ' + JSON.stringify(result));
				if (result && result.callStatus && result.callStatus !== 'Call Initiation') {
					let message = '';
					let variant = 'Success';
					if (result.callStatus == 'Call Completed') {
						message = 'Call has been completed.';
					} else if (result.callStatus == 'Call Failed') {
						message = 'Call has been failed.';
						variant = 'error';
					} else if (result.callStatus == 'Call Cancelled') {
						message = 'Call has been cancelled.';
						variant = 'error';
					}
					if (message != '') {
						cmp.dispatchEvent(new ShowToastEvent({
							title: variant,
							message: message,
							variant: variant,
							mode: "dismissable"
						}));
					}
					var hideCallingIcon = {
						'name': 'showCallingIcon',
						'value': 'false',
						'indexcm': undefined,
						'parentname': undefined,
						'onChangeMethod': undefined
					}
					fireEvent(cmp.pageRef, 'refreshValues_' + 'LogACallForTreatmentRule', hideCallingIcon);
					result['showCallingIcon'] = 'false';
					resolve(result);
				} else {
					setTimeout(() => {
						checkCallStatus(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum, ShowToastEvent, callResult);
					}, 2000);
				}
			}).catch(error => {
				console.log('error :' + error);
				reject(error);
			});

		});
	}
	function OnChangeCantactNamePhone(values, invoke, ds) {
		var contactId = values["ContactName"];

		return new Promise(function (resolve, reject) {
			if (values.ContactName.includes('_blank')) {
				let contacts = values.ContactName.split("_");
				values.ContactCalled = '';
				values.DialContact = '';
				values.DialContactId = contacts[0];
			} else {
				let contacts = values.ContactName.split("_");
				values.ContactCalled = contacts[1];
				values.DialContact = contacts[1];
				values.DialContactId = contacts[0];
			}
			resolve(values);
			// 	invoke({ 
			// 	className: 'PopulateContactDetailPhone', 
			// 	functionName: 'SelectionContactDetail',
			// 	values: values 
			// }).then(result1 => {
			// 	var result = JSON.parse(JSON.stringify(result1));
			// 	if (!result.ContactCalled) {
			// 		result.ContactCalled = '';
			// 	}
			// 	resolve(result);
			// }).catch(error => {
			// 	console.log('error :' + error);
			// 	reject(error);
			// });
		});
	}
	function onDidnotpickcall(values, invoke, ds) {
		values["isFollowup"] = true;
		if (values["FollowupDays"] === null || values["FollowupDays"] === undefined || values["FollowupDays"] === "") {
			values["FollowupDays"] = "7";
		}

		return new Promise(function (resolve, reject) {
			resolve(values);
		});
	}
	function removeCommunication(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum, ShowToastEvent, controlName, parentControlName) {
		console.log('controlName>>> ' + controlName);
		console.log('parentControlName>>> ' + parentControlName);
		var screenName = values['ggScreenName'];
		return new Promise(function (resolve, reject) {
			let resolveVal = {};
			if (parentControlName) {
				let val = values[parentControlName + 'value'];
				let remainingChildIds = [];
				for (let childId of values.childObjectIds) {
					if (childId != val[rowNum].Id) {
						remainingChildIds.push(childId);
					}
				}
				resolveVal.childObjectIds = remainingChildIds;
				val.splice(rowNum, 1);
				if (val.length == 1) {
					val[0].RemoveCommunication = '';
				}
				//fireEvent(cmp.pageRef, parentControlName + '_' + screenName + '_Columns', values[parentControlName + 'columns']);
				fireEvent(cmp.pageRef, parentControlName + '_' + screenName, val);

				resolveVal[parentControlName + 'value'] = val;
				if (val.length == 0) {
					let step = [];
					for (let a of values.listOfStep) {
						if (a != parentControlName) {
							step.push(a);
						}
					}
					resolveVal.listOfStep = step;
				}
			} else {
				let nameOfControl = controlName.split("-")[0];
				let val = values[nameOfControl + 'value'];
				let removeIds = [];
				for (let tempVal of val) {
					removeIds.push(tempVal.Id);
				}
				let remainingChildIds = [];
				for (let childId of values.childObjectIds) {
					if (removeIds.indexOf(childId) == -1) {
						remainingChildIds.push(childId);
					}
				}
				resolveVal.childObjectIds = remainingChildIds;
				resolveVal[nameOfControl + 'value'] = [];
				resolveVal[nameOfControl + 'blockShow'] = 'false';
				let step = [];
				for (let a of values.listOfStep) {
					if (a != nameOfControl) {
						step.push(a);
					}
				}
				resolveVal.listOfStep = step;
			}
			let steplen = resolveVal.listOfStep != undefined ? resolveVal.listOfStep.length : values.listOfStep.length;
			if (steplen > 1) {
				resolveVal.showRemoveCommunicationButton = 'true';
			} else {
				resolveVal.showRemoveCommunicationButton = 'false';
			}
			resolve(resolveVal);
		});
	}
	function openEditPage(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum, ShowToastEvent, controlName, parentControlName) {
		return new Promise(function (resolve, reject) {
			cmp[navigationMixin.Navigate]({
				type: 'standard__objectPage',
				attributes: {
					objectApiName: 'Task',
					recordId: values.Id,
					actionName: 'edit'
				}
			});
			resolve({});
		});

	}
	function refreshParentScreenValue(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum, ShowToastEvent, controlName, parentControlName) {
		return new Promise(function (resolve, reject) {
			let refreshParentValues = {
				"priority": values.priority,
				"dueDate": values.dueDate,
				"status": values.status
			}
			resolve({ "refreshParentValues": refreshParentValues });
		});

	}
	function openSendEMailScreen(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum, ShowToastEvent, controlName, parentControlName) {
		return new Promise(function (resolve, reject) {
			debugger;
			//-- Starts | FIN-6329 | changes by Dilshad | 1 Aug 2024 --//
			let openSendEmailScreen = false;
			//-- Start | FIN-8048 | Changed By Dilshad | 13-Aug-2025 --//
			let selectedRecordSize = 0;
			//-- End | FIN-8048 | Changed By Dilshad | 13-Aug-2025 --//
			let valueMap = JSON.parse(JSON.stringify(values));
			if (valueMap.childObjAPIName != '' && valueMap.childObjAPIName != undefined) {
				let stepLen = valueMap.listOfStep ? valueMap.listOfStep.length : 0;
				if (stepLen > 0) {
					let stepToRecIds = {};
					for (let step of valueMap.listOfStep) {
						if (valueMap[step].length > 0) {
							//-- Start | FIN-8048 | Changed By Dilshad | 13-Aug-2025 --//
							selectedRecordSize += new Blob([JSON.stringify(valueMap[step])]).size / 1024 / 1024;
							//-- End | FIN-8048 | Changed By Dilshad | 13-Aug-2025 --//
							let tempIds = [];
							for (let tempVal of valueMap[step]) {
								if (tempVal.isSelected == undefined || tempVal.isSelected == true) {
									tempIds.push(tempVal.Id);
								}
							}
							if (tempIds.length > 0) {
								openSendEmailScreen = true;
							}
							stepToRecIds[step] = tempIds;
							delete valueMap[step];
						}
						//-- Start | FIN-8048 | Changed By Dilshad | 13-Aug-2025 --//
						// if (openSendEmailScreen) {
						// 	break;
						// }
						//-- End | FIN-8048 | Changed By Dilshad | 13-Aug-2025 --//
					}
					valueMap.stepToRecIds = stepToRecIds;
				}
			} else {
				openSendEmailScreen = true;
			}
			//-- Start | FIN-8048 | Changed By Dilshad | 13-Aug-2025 --//
			//-- Check for too large number of records selected --//
			if (selectedRecordSize >= 10.47) {

				cmp.dispatchEvent(new ShowToastEvent({
					title: "Error",
					message: "Very large number of records selected. Please select less number of records or export data from grid and send email manually.",
					variant: "error",
					mode: "sticky"
				}));
				resolve({});
			
			} else if (openSendEmailScreen) {
				//-- Ends | FIN-6329 | changes by Dilshad | 1 Aug 2024 --//
				let customChangeHandler = {
					"callingControlName": "SendEmail",
					"targetScreen": "SendEmailForTreatmentRule",
					"targetScreenSize": "large-width",
					"sourceControlName": '',
					"vals": valueMap
				};
				//-- End | FIN-8048 | Changed By Dilshad | 13-Aug-2025 --//
				fireEvent(cmp.pageRef, 'openChildScreen_' + valueMap.ggScreenName + "customAction", customChangeHandler);
				resolve({});
			} else {
				cmp.dispatchEvent(new ShowToastEvent({
					title: "Error",
					message: "Please selecte one or more record (s)",
					variant: "error",
					mode: "dismissable"
				}));
				resolve({});
			}

		});
	}
	function openMakeACallScreen(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum, ShowToastEvent, controlName, parentControlName) {
		return new Promise(function (resolve, reject) {
			//-- Starts | FIN-6329 | changes by Dilshad | 1 Aug 2024 --//
			let openLogACallScreen = false;
			if (values.childObjAPIName != '' && values.childObjAPIName != undefined) {
				let stepLen = values.listOfStep ? values.listOfStep.length : 0;
				if (stepLen > 0) {
					for (let step of values.listOfStep) {
						if (values[step].length > 0) {
							for (let tempVal of values[step]) {
								if (tempVal.isSelected) {
									openLogACallScreen = true;
									break;
								}
							}
						}
						if (openLogACallScreen) {
							break;
						}
					}
				}
			} else {
				openLogACallScreen = true;
			}
			if (openLogACallScreen) {
				//-- Ends | FIN-6329 | changes by Dilshad | 1 Aug 2024 --//
				let customChangeHandler = {
					"callingControlName": "logaCall",
					"targetScreen": "LogACallForTreatmentRule",
					"targetScreenSize": "large-width",
					"sourceControlName": '',
					"vals": values
				};
				fireEvent(cmp.pageRef, 'openChildScreen_' + values.ggScreenName + "customAction", customChangeHandler);
				resolve({});
			} else {
				cmp.dispatchEvent(new ShowToastEvent({
					title: "Error",
					message: "Please selecte one or more record (s)",
					variant: "error",
					mode: "dismissable"
				}));
				resolve({});
			}

		});
	}
	//-- Start | FIN-8048 | Changed by Ravi | 23 July 2025 --//
	//-- Start | FIN-8209 | Changed By Dilshad | 13-Aug-2025 --//
	//-- FIN-9747 | Changed by Dilshad | 12-May-2026 | Start --//
	function submitSendEmailScreen(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum, ShowToastEvent, controlName, parentControlName) {
		return new Promise(async function (resolve, reject) {
			try {
				debugger;
				let newValues = {
					'Id': values.Id,
					'ComposeEmail': values.ComposeEmail,
					'accountId': values.accountId,
					'isAttachment': values.isAttachment,
					'attachmentFormat': values.attachmentFormat,
					'isDunningScreen': values.isDunningScreen,
					'taskSubject': values.taskSubject,
					'treatmentStage': values.treatmentStage,
					'listOfStep': values.listOfStep,
					'stepToRecIds': values.stepToRecIds,
					'updateDocument': values.updateDocument,
					'childObjectIds': values.childObjectIds,
					//-- FIN-9747 | Changed by Dilshad | 12-May-2026 | Start --//
					'childObjAPIName': values.childObjAPIName,
					//-- FIN-9747 | Changed by Dilshad | 12-May-2026 | End --//
					'objectName': values.objectName,
					'treatmentName': values.treatmentName,
					'isConsolidated': values.isConsolidated,
					'attachmentName': values.attachmentName,
					//-- FIN-9747 | Changed by Dilshad | 12-May-2026 | Start --//
					'attachmentTemplate': values.attachmentTemplate,
					'attachmentTemplateFolder': values.attachmentTemplateFolder,
					'attachmentTemplateFolderRefField': values.attachmentTemplateFolderRefField,
					//-- FIN-9747 | Changed by Dilshad | 12-May-2026 | End --//
					'attachment-template': values.attachmentTemplate ? values.attachmentTemplate : 'BillingStatementPDF'
				};
				//-- FIN-9747 | Changed by Dilshad | 12-May-2026 | Start --//
				if (Array.isArray(values.listOfStep)) {
					values.listOfStep.forEach(step => {
						newValues[step + 'columns'] = values[step + 'columns'];
						newValues[step + 'totalTitle'] = values[step + 'totalTitle'];
						newValues[step + 'aggregationField'] = values[step + 'aggregationField'];
						newValues[step + 'showTotal'] = values[step + 'showTotal'];
					});
				}
				if ((!newValues.stepToRecIds || Object.keys(newValues.stepToRecIds).length === 0) && Array.isArray(values.listOfStep)) {
					const stepToRecIds = {};
					values.listOfStep.forEach(step => {
						const tempIds = [];
						if (Array.isArray(values[step])) {
							values[step].forEach(tempVal => {
								if (tempVal && (tempVal.isSelected === undefined || tempVal.isSelected === true) && tempVal.Id) {
									tempIds.push(tempVal.Id);
								}
							});
						}
						stepToRecIds[step] = tempIds;
					});
					newValues.stepToRecIds = stepToRecIds;
				}
				//-- FIN-9747 | Changed by Dilshad | 12-May-2026 | End --//
				//-- Generate Excel Attachment --//
				if (values['attachmentFormat'] == "Excel") {
                    //-- Starts | FIN-8653 | Changed by Dhwanil | 27 Nov 2025 --//
					if (values.isConsolidated) {
						const result1 = await invoke({
							className: 'TaskTreatmentController',
							functionName: 'getPreDataForExcelFileGeneration',
							values: values
						});
						//-- Start | FIN-9041 | Chanegs by Asera 02-Feb-2026--//
						// newValues = await createConsolidatedExcelFile(result1, newValues);
						//-- FIN-9747 | Changed by Dilshad | 12-May-2026 | Start --//
						const resultUnproxied = JSON.parse(JSON.stringify(result1));
						//-- Start | FIN-9543 | Changes by Dhwanil | 06-Arl-2026 --//
						resultUnproxied['fontLibraryUrl'] = '/resource/FontLibrary';
						//-- ends | FIN-9543 | Changes by Dhwanil | 06-Arl-2026 --//
						newValues = await generateHTMLContentForConsolidatedExcel(resultUnproxied, newValues);
						// Convert HTML to Excel
						if (newValues && newValues.finalContent && window.gog && window.gog.statementUtils && window.gog.statementUtils.generateExcelFromHtml) {
							const fileName = values['attachmentName'] || ('Treatment-' + values['taskSubject']);
							newValues.finalContent = await window.gog.statementUtils.generateExcelFromHtml(newValues.finalContent, fileName, ExcelJS, resultUnproxied);
						}
						//-- End | FIN-9041 | Chanegs by Asera 02-Feb-2026--//
						newValues["fileName"] = values['attachmentName'] ? values['attachmentName'] + ".xlsx" : 'Treatment-' + values['taskSubject'] + '.xlsx';
						delete resultUnproxied['templateBodyImageBase64Map']; // FIN-9351
						//-- FIN-9747 | Changed by Dilshad | 12-May-2026 | End --//
					} else {
						const result = await cmp.invoke({
							className: 'TaskTreatmentController',
							functionName: 'getPreDataForExcelFileGeneration',
							values: values
						});
							//-- Start | FIN-9041 | Chanegs by Asera 02-Feb-2026--//
							//-- Start | FIN-9543 | Changes by Dhwanil | 06-Arl-2026 --//
							result['fontLibraryUrl'] = '/resource/FontLibrary';
							//-- ends | FIN-9543 | Changes by Dhwanil | 06-Arl-2026 --//
							// newValues = await createExcelFile(values, newValues, cmp, ShowToastEvent, result);
						//-- FIN-9747 | Changed by Dilshad | 12-May-2026 | Start --//
						newValues = await generateHTMLContentForExcel(values, newValues, cmp, ShowToastEvent, result);
						//-- FIN-9747 | Changed by Dilshad | 12-May-2026 | End --//
							// Convert HTML to Excel
							if (newValues && newValues.finalContent && window.gog && window.gog.statementUtils && window.gog.statementUtils.generateExcelFromHtml) {
								const fileName = values['attachmentName'] || ('Treatment-' + values['taskSubject']);
								newValues.finalContent = await window.gog.statementUtils.generateExcelFromHtml(newValues.finalContent, fileName, ExcelJS, result);
							}
							//-- End | FIN-9041 | Chanegs by Asera 02-Feb-2026--//
							newValues["fileName"] = values['attachmentName'] ? values['attachmentName'] + ".xlsx" : 'Treatment-' + values['taskSubject'] + '.xlsx';
							delete result['templateBodyImageBase64Map']; // FIN-9351
					}
					//-- Insert Attachment in Salesforce --//
					if (newValues && newValues.finalContent) {
						await invoke({
							className: 'TaskTreatmentController',
							functionName: 'uploadExcelFile',
							values: { finalContent: newValues.finalContent, fileName: newValues.fileName }
						}).then(result => {
							newValues.contentVersionId = result.contentVersionId;
							delete newValues.finalContent;
							delete newValues.fileName;
						});
					}
				} else {
					//-- FIN-9747 | Changed by Dilshad | 12-May-2026 | Start --//
					if (values.isConsolidated) {
						const result = await invoke({
							className: 'TaskTreatmentController',
							functionName: 'getPreDataForPDFAttachment',
							values: newValues
						});
						const resultUnproxied = JSON.parse(JSON.stringify(result));
						newValues = await generateHTMLContentForConsolidatedPDF(resultUnproxied, newValues, cmp);
						delete resultUnproxied['templateBodyImageBase64Map']; // FIN-9351
					} else {
						const result = await cmp.invoke({
							className: 'TaskTreatmentController',
							functionName: 'getPreDataForPDFAttachment',
							values: newValues
						});
						newValues = await generateHTMLContentForPDF(newValues, newValues, cmp, ShowToastEvent, result);
						delete result['templateBodyImageBase64Map']; // FIN-9351
					}
					if (newValues && newValues.finalContent) {
						const pdfFileName = newValues['attachmentName'] ? newValues['attachmentName'] : 'Treatment-' + newValues['taskSubject'];
						newValues = await generatePdfAttachmentUsingVF(newValues, newValues, invoke, pdfFileName);
					}
				}
				//-- FIN-9747 | Changed by Dilshad | 12-May-2026 | End --//
				//-- ends | FIN-8653 | Changed by Dhwanil | 27 Nov 2025 --//

				await invoke({
					className: 'TaskTreatmentController',
					functionName: 'customSendEmail',
					values: newValues
				});

			} catch (error) {
				console.error('Error in submitSendEmailScreen:', error);
				cmp.dispatchEvent(new ShowToastEvent({
					title: "Error",
					message: 'An error occurred while sending the email: ' + (error.body ? error.body.message : error.message),
					variant: "error",
					mode: "sticky"
				}));
			} finally {
				resolve({});
			}
		});
	}

	// deprecated //
	async function createExcelFile(values, returnValues, cmp, ShowToastEvent, fileData) {
		try {
			debugger;

			console.log('fileData : ' + JSON.stringify(fileData));
			let recordCounter = 1;
			const workbook = new ExcelJS.Workbook();
			const worksheet = workbook.addWorksheet('Sheet1');
			if (fileData.hasCompanyLogo) {
				// first 3 rows will be used for logo
				const logoUrl = '/resource/CompanyLogo'; // <-- upload your logo as static resource
				const response = await fetch(logoUrl);
				const arrayBuffer = await response.arrayBuffer();

				// Add image to workbook
				const imageId = workbook.addImage({
					buffer: arrayBuffer,
					extension: 'png',   // or 'jpeg'
				});

				// Position logo (example: top-left corner covering A1:B3)
				worksheet.addImage(imageId, {
					tl: { col: 0, row: 0 },   // top-left
					br: { col: 2, row: 3 },   // bottom-right
					editAs: 'oneCell'
				});
				// one row for space after logo
				recordCounter = 4
			}

			// Add title below the logo

			const titleRow = worksheet.getRow(recordCounter);
			titleRow.font = { bold: true, size: 20 };
			titleRow.getCell(1).value = 'STATEMENT OF ACCOUNT';


			worksheet.mergeCells(recordCounter, 0, recordCounter + 2, 3);
			titleRow.eachCell((cell) => {
				cell.font = { bold: true };
				cell.border = {
					top: { style: 'thin' },
					left: { style: 'thin' },
					bottom: { style: 'thin' },
					right: { style: 'thin' }
				}
			});
			//recordCounter = recordCounter + 3;

			//-- Orgnization Name --//
			const titleRowAccName = worksheet.getRow(recordCounter + 3); // 7
			titleRowAccName.font = { bold: true, size: 18 };
			titleRowAccName.getCell(1).value = fileData.orgName;
			worksheet.mergeCells(recordCounter + 3, 0, recordCounter + 5, 3);
			titleRowAccName.eachCell((cell) => {
				cell.font = { bold: true };
				cell.border = {
					top: { style: 'thin' },
					left: { style: 'thin' },
					bottom: { style: 'thin' },
					right: { style: 'thin' }
				}
			});

			//-- Customer Name : Label--//
			const custNumTitleRow = worksheet.getRow(recordCounter + 1); // row number - 4
			custNumTitleRow.font = { bold: true, size: 16 };
			custNumTitleRow.getCell(4).value = 'Customer Name';
			custNumTitleRow.getCell(4).fill = {
				type: 'pattern',
				pattern: 'solid', // Use 'solid' for a uniform background color
				fgColor: { argb: 'FFDEF2F1' } // Red color in ARGB format (Alpha, Red, Green, Blue)
			};
			worksheet.mergeCells(recordCounter, 4, recordCounter, 6);
			//-- Customer Name : Value--//
			const custNumValRow = worksheet.getRow(recordCounter + 1); // row number - 5
			custNumValRow.font = { bold: true, size: 18 };
			custNumValRow.getCell(4).value = fileData.customerName;
			worksheet.mergeCells(recordCounter + 1, 4, recordCounter + 1, 6);


			//-- Customer Number | Label --//
			const statementDateTitleRow = worksheet.getRow(recordCounter + 2); // row number - 6
			statementDateTitleRow.font = { bold: true, size: 16 };
			statementDateTitleRow.getCell(4).value = 'Customer Number';
			statementDateTitleRow.getCell(4).fill = {
				type: 'pattern',
				pattern: 'solid', // Use 'solid' for a uniform background color
				fgColor: { argb: 'FFDEF2F1' } // Red color in ARGB format (Alpha, Red, Green, Blue)
			};
			worksheet.mergeCells(recordCounter + 2, 4, recordCounter + 2, 6);

			const statementDateValRow = worksheet.getRow(recordCounter + 3); // row number - 7
			statementDateValRow.font = { bold: true, size: 16 };
			statementDateValRow.getCell(4).value = fileData.customerNumber;
			worksheet.mergeCells(recordCounter + 3, 4, recordCounter + 3, 6);

			//-- Statement Date | Label --//
			const totalPastDueTitleRow = worksheet.getRow(recordCounter + 4); // row number - 8
			totalPastDueTitleRow.font = { bold: true, size: 16 };
			totalPastDueTitleRow.getCell(4).value = 'Statement Date';
			totalPastDueTitleRow.getCell(4).fill = {
				type: 'pattern',
				pattern: 'solid', // Use 'solid' for a uniform background color
				fgColor: { argb: 'FFDEF2F1' } // Red color in ARGB format (Alpha, Red, Green, Blue)
			};
			worksheet.mergeCells(recordCounter + 4, 4, recordCounter + 4, 6);
			//-- Statement Date | Value --//
			const totalPastDueValRow = worksheet.getRow(9);  // row number - 9
			totalPastDueValRow.font = { bold: true, size: 16 };
			totalPastDueValRow.getCell(4).value = fileData.statementDate;
			worksheet.mergeCells(recordCounter + 5, 4, recordCounter + 5, 6);


			recordCounter += 7;
			for (let index = 0; index < values.listOfStep.length; index++) {
				const step = values.listOfStep[index];

				const data = fileData[step];
				const columns = values[step + 'columns'];

				let columnLabels = values[step + 'columns'].map(c => c.label);


				// Format header row
				const headerRow = worksheet.getRow(recordCounter + 1);
				headerRow.values = columnLabels;

				headerRow.eachCell((cell) => {
					cell.font = { bold: true };
					cell.border = {
						top: { style: 'thin' },
						left: { style: 'thin' },
						bottom: { style: 'thin' },
						right: { style: 'thin' }
					};
					cell.alignment = { horizontal: 'center', vertical: 'middle' };
				});

				// Add data rows starting from the 2nd row
				let totalMap = {};
				const totalTitle = values[step + 'totalTitle'];
				const aggregationField = values[step + 'aggregationField'];
				const showTotal = values[step + 'showTotal'];
				data.forEach((record, index) => {
					const row = worksheet.getRow(recordCounter + 2 + index);

					columns.forEach((column, colIndex) => {
						let value = record[column.fieldName] || '';
						// Apply currency formatting if needed
						if (columns.find(c => c.fieldName === column.fieldName || c.name === column.fieldName)?.type === 'currency') {
							const currencyCode = record['CurrencyIsoCode'];
							if (currencyCode) {
								const currencySymbol = getCurrencySymbol(currencyCode);
								//row.getCell(colIndex + 1).numFmt = `${currencySymbol} #,##0.00`;
								row.getCell(colIndex + 1).numFmt = '[$' + currencySymbol + '] #,##0.00';
								//step-1aggregationField
								//step-1showTotal
								//step-1totalTitle
								if (showTotal) {
									if (column.fieldName == aggregationField) {
										if (totalMap[currencyCode]) {
											totalMap[currencyCode] = totalMap[currencyCode] + parseFloat(value);
										} else {
											totalMap[currencyCode] = parseFloat(value);
										}
									}
								}
							}


						} else if (column.fieldName == 'Name') {
							// If the field is 'Name', convert it to a text from a link
							if (typeof value === 'string' && value.startsWith('<a href=')) {
								// Extract the text between the tags
								const start = value.indexOf('>') + 1;
								const end = value.lastIndexOf('</a>');
								value = value.substring(start, end);
                            }//-- Start | FIN-8638 | Changed by Dhwanil | 28 Nov 2025 --//
                        } else if (columns.find(c => c.fieldName === column.fieldName || c.name === column.fieldName)?.type === 'number') {
                            if (showTotal) {
                                if (column.fieldName == aggregationField) {
                                    if (totalMap['total']) {
                                        totalMap['total'] = totalMap['total'] + parseFloat(value);
                                    } else {
                                        totalMap['total'] = parseFloat(value);
                                    }
                                }
                            }
                        }//-- end | FIN-8638 | Changed by Dhwanil | 28 Nov 2025 --//
                        else if (column.type == 'html' && typeof value === 'string' && value.startsWith('<a href=')) {
							const start = value.indexOf('>') + 1;
							const end = value.lastIndexOf('</a>');
							value = value.substring(start, end);
						}
						const cell = row.getCell(colIndex + 1);
						cell.value = value;
						// apply alignment
						cell.alignment = getAlignmentByType(columns.find(c => c.fieldName === column.fieldName || c.name === column.fieldName)?.type);
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
				recordCounter += data.length + 2; // Move to the next row for the next step

				// Add total rows for each currency in totalMap
				//-- Start | FIN-9501 | Changed by Dhwanil | 30-MAR-2025 --//
				if (showTotal && Object.keys(totalMap).length > 0) {
					const rowCounter = recordCounter++;
					const totalRow = worksheet.getRow(rowCounter);

					// Build combined totals string
					const totalString = Object.entries(totalMap)
						.map(([currencyCode, totalValue]) => {
							const symbol = getCurrencySymbol(currencyCode);
							return `${symbol} ${totalValue.toFixed(2)}`;
						})
						.join(', ');

						// Set combined totals in last column
					totalRow.getCell(1).value = totalValue + ': ' + totalString;
					// Merge all except last column
					worksheet.mergeCells({
						top: rowCounter,
						left: 1,
						bottom: rowCounter,
						right: columns.length
					});
					// Style row
					totalRow.eachCell((cell) => {
						cell.font = { bold: true };
						cell.border = {
							top: { style: 'thin' },
							left: { style: 'thin' },
							bottom: { style: 'thin' },
							right: { style: 'thin' }
						};
					});
				}
				recordCounter++;
			}
			//-- Ends | FIN-9501 | Changed by Dhwanil | 30-MAR-2025 --//


			// Write the workbook to a binary string
			const buffer = await workbook.xlsx.writeBuffer();
			// var temp = window.btoa(String.fromCharCode(...new Uint8Array(buffer)));
			var temp = await bufferToBase64(buffer, 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
			returnValues["finalContent"] = temp;
			return returnValues;
		} catch (error) {
			console.error('Error creating Excel file:', error);
			cmp.dispatchEvent(new ShowToastEvent({
				title: "Error in createExcelFile",
				message: 'Excel generation failed.',
				variant: "Error",
				mode: "dismissable"
			}));
			return null;
		}
	}

	function buildTaskPDFTotalHtml(totalMap, totalTitle) {
		if (!totalMap) {
			return '';
		}

		let totalsHtml = '<div style="font-weight:bold; text-align:right; margin-bottom:20px; white-space:normal; overflow-wrap:break-word;">';
		totalsHtml += (totalTitle || 'Total') + ' : ';
		totalsHtml += totalMap;
		totalsHtml += '</div>';
		return totalsHtml;
	}

	async function buildTaskPDFTableHtml(columns, data, options, cmp) {
		const safeColumns = columns || [];
		const safeData = data || [];
		const showTotal = options && options.showTotal;
		const aggregationField = options ? options.aggregationField : null;
		const totalTitle = options ? options.totalTitle : null;
		const locale = options && options.locale ? options.locale : 'en-US';
		// << START - MM - FIN-9497 - Task -> Send Email -> PIP subtotal calculation for PDF (mirrors Excel logic) >>
		const pipSubtotal = options ? !!options.pipSubtotal : false;
		const clearingDocumentField = options && options.clearingDocumentField ? options.clearingDocumentField : 'celsrm__Clearing_Document__c';
		// << END - MM - FIN-9497 - Task -> Send Email -> PIP subtotal calculation for PDF (mirrors Excel logic) >>
		const fieldTypeMap = {};
		safeColumns.forEach(col => {
			fieldTypeMap[col.fieldName] = col.type || 'text';
		});
		// << START - MM - FIN-10130 | Task -> Send Email (Replace custom place holders)>>
		// const renderData = await window.gog.statementUtils.buildStatementTableRenderData({
		const renderData = await buildStatementTableRenderData({
		// << END - MM - FIN-10130 | Task -> Send Email (Replace custom place holders)>>
			data: safeData,
			selectedFields: safeColumns.map(col => col.fieldName),
			selectedFieldsLabel: safeColumns.map(col => col.label),
			selectedFieldTypes: fieldTypeMap,
			LOCALE: locale,
			showTotal: showTotal,
			aggregationField: aggregationField,
			// << START - MM - FIN-9497 - Task -> Send Email -> PIP subtotal calculation for PDF (mirrors Excel logic) >>
			pipSubtotal: pipSubtotal,
			clearingDocumentField: clearingDocumentField
			// << END - MM - FIN-9497 - Task -> Send Email -> PIP subtotal calculation for PDF (mirrors Excel logic) >>
		}, !!(cmp && cmp.getCurrencySymbols), cmp);
		return {
			tableHtml: renderData.tableHtml || '',
			totalsHtml: showTotal && renderData.totalString ? buildTaskPDFTotalHtml(renderData.totalString, totalTitle) : ''
		};
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

	async function createConsolidatedExcelFile(values, returnValues) {

		const workbook = new ExcelJS.Workbook();
		const worksheet = workbook.addWorksheet('Sheet1');
		let recordCounter = 1;
		if (values.hasCompanyLogo) {
			// first 3 rows will be used for logo
			const logoUrl = '/resource/CompanyLogo'; // <-- upload your logo as static resource
			const response = await fetch(logoUrl);
			const arrayBuffer = await response.arrayBuffer();

			// Add image to workbook
			const imageId = workbook.addImage({
				buffer: arrayBuffer,
				extension: 'png',   // or 'jpeg'
			});

			// Position logo (example: top-left corner covering A1:B3)
			worksheet.addImage(imageId, {
				tl: { col: 0, row: 0 },   // top-left
				br: { col: 2, row: 3 },   // bottom-right
				editAs: 'oneCell'
			});
			// one row for space after logo
			recordCounter = 4
		}
		// Add title below the logo

		const titleRow = worksheet.getRow(recordCounter);
		titleRow.font = { bold: true, size: 20 };
		titleRow.getCell(1).value = 'STATEMENT OF ACCOUNT';


		worksheet.mergeCells(recordCounter, 0, recordCounter + 2, 3);
		titleRow.eachCell((cell) => {
			cell.font = { bold: true };
			cell.border = {
				top: { style: 'thin' },
				left: { style: 'thin' },
				bottom: { style: 'thin' },
				right: { style: 'thin' }
			}
		});
		//recordCounter = recordCounter + 3;

		//-- Orgnization Name --//
		const titleRowAccName = worksheet.getRow(recordCounter + 3); // 7
		titleRowAccName.font = { bold: true, size: 18 };
		titleRowAccName.getCell(1).value = values.orgName;
		worksheet.mergeCells(recordCounter + 3, 0, recordCounter + 5, 3);
		titleRowAccName.eachCell((cell) => {
			cell.font = { bold: true };
			cell.border = {
				top: { style: 'thin' },
				left: { style: 'thin' },
				bottom: { style: 'thin' },
				right: { style: 'thin' }
			}
		});

		//-- Customer Name : Label--//
		const custNumTitleRow = worksheet.getRow(recordCounter + 1); // row number - 4
		custNumTitleRow.font = { bold: true, size: 16 };
		custNumTitleRow.getCell(4).value = 'Customer Name';
		custNumTitleRow.getCell(4).fill = {
			type: 'pattern',
			pattern: 'solid', // Use 'solid' for a uniform background color
			fgColor: { argb: 'FFDEF2F1' } // Red color in ARGB format (Alpha, Red, Green, Blue)
		};
		worksheet.mergeCells(recordCounter, 4, recordCounter, 6);
		//-- Customer Name : Value--//
		const custNumValRow = worksheet.getRow(recordCounter + 1); // row number - 5
		custNumValRow.font = { bold: true, size: 18 };
		custNumValRow.getCell(4).value = values.customerName;
		worksheet.mergeCells(recordCounter + 1, 4, recordCounter + 1, 6);


		//-- Customer Number | Label --//
		const statementDateTitleRow = worksheet.getRow(recordCounter + 2); // row number - 6
		statementDateTitleRow.font = { bold: true, size: 16 };
		statementDateTitleRow.getCell(4).value = 'Customer Number';
		statementDateTitleRow.getCell(4).fill = {
			type: 'pattern',
			pattern: 'solid', // Use 'solid' for a uniform background color
			fgColor: { argb: 'FFDEF2F1' } // Red color in ARGB format (Alpha, Red, Green, Blue)
		};
		worksheet.mergeCells(recordCounter + 2, 4, recordCounter + 2, 6);

		const statementDateValRow = worksheet.getRow(recordCounter + 3); // row number - 7
		statementDateValRow.font = { bold: true, size: 16 };
		statementDateValRow.getCell(4).value = values.customerNumber;
		worksheet.mergeCells(recordCounter + 3, 4, recordCounter + 3, 6);

		//-- Statement Date | Label --//
		const totalPastDueTitleRow = worksheet.getRow(recordCounter + 4); // row number - 8
		totalPastDueTitleRow.font = { bold: true, size: 16 };
		totalPastDueTitleRow.getCell(4).value = 'Statement Date';
		totalPastDueTitleRow.getCell(4).fill = {
			type: 'pattern',
			pattern: 'solid', // Use 'solid' for a uniform background color
			fgColor: { argb: 'FFDEF2F1' } // Red color in ARGB format (Alpha, Red, Green, Blue)
		};
		worksheet.mergeCells(recordCounter + 4, 4, recordCounter + 4, 6);
		//-- Statement Date | Value --//
		const totalPastDueValRow = worksheet.getRow(9);  // row number - 9
		totalPastDueValRow.font = { bold: true, size: 16 };
		totalPastDueValRow.getCell(4).value = values.statementDate;
		worksheet.mergeCells(recordCounter + 5, 4, recordCounter + 5, 6);


		recordCounter += 7;

		const data = values.data;
		const columns = values.columns;
		let columnLabels = columns.map(c => c.label);


		// Format header row
		const headerRow = worksheet.getRow(recordCounter + 1);
		headerRow.values = columnLabels;

		headerRow.eachCell((cell) => {
			cell.font = { bold: true };
			cell.border = {
				top: { style: 'thin' },
				left: { style: 'thin' },
				bottom: { style: 'thin' },
				right: { style: 'thin' }
			};
			cell.alignment = { horizontal: 'center', vertical: 'middle' };
		});

		// Add data rows starting from the 2nd row
		let totalMap = {};
		const hasListStepValue = values.listOfStep && values.listOfStep.length > 0;
		const totalTitle = hasListStepValue ? values[values.listOfStep[0] + 'totalTitle'] : 'Total Amount';
		const aggregationField = hasListStepValue ? values[values.listOfStep[0] + 'aggregationField'] : 'Amount__c';
		const showTotal = hasListStepValue ? values[values.listOfStep[0] + 'showTotal'] : true;

		data.forEach((record, index) => {
			const row = worksheet.getRow(recordCounter + 2 + index);

			columns.forEach((column, colIndex) => {
				let value = record[column.fieldName] || '';

				const cell = row.getCell(colIndex + 1);
				cell.value = value;
				// apply alignment
				cell.alignment = getAlignmentByType(columns.find(c => c.fieldName === column.fieldName || c.name === column.fieldName)?.type);

				// Apply currency formatting if needed
				if (columns.find(c => c.fieldName === column.fieldName || c.name === column.fieldName)?.type === 'currency') {
					const currencyCode = record['CurrencyIsoCode'];
					if (currencyCode) {
						const currencySymbol = getCurrencySymbol(currencyCode);
						//row.getCell(colIndex + 1).numFmt = `${currencySymbol} #,##0.00`;
						row.getCell(colIndex + 1).numFmt = '[$' + currencySymbol + '] #,##0.00';
						if (showTotal) {
							if (column.fieldName == aggregationField) {
								if (totalMap[currencyCode]) {
									totalMap[currencyCode] = totalMap[currencyCode] + parseFloat(value);
								} else {
									totalMap[currencyCode] = parseFloat(value);
								}
							}
						}
					}
				} else if (column.fieldName == 'Name') {
					// If the field is 'Name', convert it to a text from a link
					if (typeof value === 'string' && value.startsWith('<a href=')) {
						// Extract the text between the tags
						const start = value.indexOf('>') + 1;
						const end = value.lastIndexOf('</a>');
						value = value.substring(start, end);
                    } //-- Start | FIN-8638 | Changed by Dhwanil | 28 Nov 2025 --//
                }else if (columns.find(c => c.fieldName === column.fieldName || c.name === column.fieldName)?.type === 'number') {
					if (showTotal) {
						if (column.fieldName == aggregationField) {
							if (totalMap['total']) {
								totalMap['total'] = totalMap['total'] + parseFloat(value);
							} else {
								totalMap['total'] = parseFloat(value);
							}
						}
					}
				}  //-- Ends | FIN-8638 | Changed by Dhwanil | 28 Nov 2025 --//
				else if (column.type == 'html' && typeof value === 'string' && value.startsWith('<a href=')) {
					const start = value.indexOf('>') + 1;
					const end = value.lastIndexOf('</a>');
					value = value.substring(start, end);
				}
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
		recordCounter += data.length + 2; // Move to the next row for the next step

		//--Start | FIN-9501 | Changed by Dhwanil | 30 Mar 2025 --//
		// Add total rows for each currency in totalMap
		if (showTotal && Object.keys(totalMap).length > 0) {

			const rowCounter = recordCounter++;
			const totalRow = worksheet.getRow(rowCounter);

			// Build combined string
			const totalString = Object.entries(totalMap)
			.map(([currencyCode, totalValue]) => {
				const symbol = getCurrencySymbol(currencyCode);
				return `${symbol} ${totalValue.toFixed(2)}`;
			})
			.join(', ');

			// Set in first cell
			totalRow.getCell(1).value = totalTitle
				? `${totalTitle}: ${totalString}`
				: `Total: ${totalString}`;

			totalRow.getCell(1).alignment = { horizontal: 'right' };
			
			worksheet.mergeCells({
				top: rowCounter,
				left: 1,
				bottom: rowCounter,
				right: columns.length
			});

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
		//--End | FIN-9501 | Changed by Dhwanil | 30 Mar 2025 --//


		// Write the workbook to a binary string
		const buffer = await workbook.xlsx.writeBuffer();
		// var temp = window.btoa(String.fromCharCode(...new Uint8Array(buffer)));
		var temp = await bufferToBase64(buffer, 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
		returnValues["finalContent"] = temp;
		return returnValues;
	}

	//-- Start | FIN-9041 | Chanegs by Asera 02-Feb-2026--//
	// depricated
	async function createConsolidatedPdfFile(values, returnValues, cmp) {
		try {
			//debugger;
			if (!values) {
				console.error('createConsolidatedPdfFile: values is undefined/null');
				return null;
			}

			//-- Start | FIN-9543 | Changed by Dhwanil | 06-Apr-2026 --//
			//-- End | FIN-9543 | Changed by Dhwanil | 06-Apr-2026 --//

			const LOCAL = (values.LOCALE || 'en-US').replace('_', '-');

			const columns = values.columns || [];
			const data = values.data || [];
			const hasListStepValue = values.listOfStep && values.listOfStep.length > 0;
			const totalTitle = hasListStepValue ? values[values.listOfStep[0] + 'totalTitle'] : 'Total Amount';
			const aggregationField = hasListStepValue ? values[values.listOfStep[0] + 'aggregationField'] : 'Amount__c';
			const showTotal = hasListStepValue ? values[values.listOfStep[0] + 'showTotal'] : true;
			const pdfTable = await buildTaskPDFTableHtml(columns, data, {
				showTotal: showTotal,
				aggregationField: aggregationField,
				totalTitle: totalTitle,
				locale: LOCAL
			}, cmp);
			const tableHtml = pdfTable.tableHtml + pdfTable.totalsHtml;
			//-- FIN-9729 | Changed by Dilshad | 07-May-2026 | Start --//
			returnValues["finalContent"] = tableHtml;
			returnValues["renderWithAttachmentTemplate"] = !!returnValues.attachmentTemplate;
			//-- FIN-9729 | Changed by Dilshad | 07-May-2026 | End --//
			return returnValues;

		} catch (error) {
			console.error('Error creating Consolidated PDF file:', error);
			return null;
		}
	}
	//-- End | FIN-9041 | Chanegs by Asera 02-Feb-2026--//

	//-- FIN-9729 | Changed by Dilshad | 07-May-2026 | Start --//
	async function generatePdfAttachmentUsingVF(values, returnValues, invoke, fileName) {
		let prebuiltAttachmentHtmlKey = null;
		try {
			prebuiltAttachmentHtmlKey = await uploadTaskTreatmentPDFHtml(returnValues.finalContent, values, invoke);
			const result1 = await invoke({
				className: 'TaskTreatmentController',
				functionName: 'generatePDFAttachment',
				values: {
					accountId: values.accountId,
					fileName: fileName,
					prebuiltAttachmentHtmlKey: prebuiltAttachmentHtmlKey,
					renderWithAttachmentTemplate: returnValues.renderWithAttachmentTemplate === true,
					attachmentTemplate: values.attachmentTemplate,
					attachmentTemplateFolder: values.attachmentTemplateFolder,
					attachmentTemplateFolderRefField: values.attachmentTemplateFolderRefField,
					// << START - MM - FIN-10130 - Pass selected transaction/child record Ids so PDF attachment totals (TotalOpenItems/TotalOverdueItems/TotalOverdueNotNotedItems) can be computed >>
					childObjectIds: values.childObjectIds
					// << END - MM - FIN-10130 - Pass selected transaction/child record Ids so PDF attachment totals (TotalOpenItems/TotalOverdueItems/TotalOverdueNotNotedItems) can be computed >>
				}
			});
			const result = JSON.parse(JSON.stringify(result1 || {}));
			if (result && result.ggErrorMessage) {
				throw new Error(result.ggErrorMessage);
			}

			returnValues.contentVersionId = result.contentVersionId;
			delete returnValues.finalContent;
			delete returnValues.renderWithAttachmentTemplate;
			return returnValues;
		} catch (error) {
			await cleanupTaskTreatmentPdfTempChunks(prebuiltAttachmentHtmlKey, invoke);
			throw error;
		}
	}

	async function uploadTaskTreatmentPDFHtml(contentHtml, values, invoke) {
		STATEMENT_PDF_TABLE_CHUNK_SIZE
		if (!contentHtml) {
			return null;
		}

		const uploadToken = 'taskpdf_' + Date.now() + '_' + Math.random().toString(36).substring(2, 10);
		let prebuiltAttachmentHtmlKey = null;

		for (let startIndex = 0, chunkIndex = 0; startIndex < contentHtml.length; startIndex += STATEMENT_PDF_TABLE_CHUNK_SIZE, chunkIndex++) {
			const htmlChunk = contentHtml.substring(startIndex, Math.min(startIndex + STATEMENT_PDF_TABLE_CHUNK_SIZE, contentHtml.length));
			const chunkResult1 = await invoke({
				className: 'TaskTreatmentController',
				functionName: 'savePdfHtmlChunk',
				values: {
					accountId: values.accountId,
					uploadToken: uploadToken,
					chunkIndex: chunkIndex,
					htmlChunk: htmlChunk
				}
			});
			const chunkResult = JSON.parse(JSON.stringify(chunkResult1 || {}));
			if (chunkResult && chunkResult.ggErrorMessage) {
				throw new Error(chunkResult.ggErrorMessage);
			}
			prebuiltAttachmentHtmlKey = chunkResult.prebuiltAttachmentHtmlKey || prebuiltAttachmentHtmlKey;
		}

		return prebuiltAttachmentHtmlKey;
	}

	async function cleanupTaskTreatmentPdfTempChunks(tempKeyPrefix, invoke) {
		if (!tempKeyPrefix) {
			return;
		}

		try {
			await invoke({
				className: 'TaskTreatmentController',
				functionName: 'deletePdfTempChunks',
				values: {
					tempKeyPrefix: tempKeyPrefix
				}
			});
		} catch (cleanupError) {
			console.error('task pdf temp cleanup error :', cleanupError);
		}
	}

	function inlinePdfAttachmentImages(contentHtml, templateBodyImageBase64Map) {
		if (!contentHtml || !templateBodyImageBase64Map) {
			return contentHtml;
		}

		let processedHtml = contentHtml;
		Object.keys(templateBodyImageBase64Map).forEach((imageUrl) => {
			const dataUrl = templateBodyImageBase64Map[imageUrl];
			if (imageUrl && dataUrl) {
				processedHtml = processedHtml.split(imageUrl).join(dataUrl);
			}
		});
		return processedHtml;
	}
	
	//-- FIN-9729 | Changed by Dilshad | 07-May-2026 | End --//

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
	//-- Start | FIN-8638 | Changed by Dhwanil | 28 Nov 2025 --//
	const getCurrencySymbol = (currencyKey) => {
		if (!currencyKey) return '';
		try {
			return (0).toLocaleString(
				'en-US',
				{
					style: 'currency',
					currency: currencyKey,
					minimumFractionDigits: 0,
					maximumFractionDigits: 0,
				}
			).replace(/[0-9\u0660-\u0669]/g, '').trim()
		} catch {
			return '';
		}
	}
	// << START - MM - FIN-10130 | Task -> Send Email (Replace custom place holders)>> 
	/**
	const buildStatementTableRenderData = async (result, useSymbol, cmp) => {
		const MAX_PDF_TABLE_CELL_COUNT = 100000;
		if (!result) {
			console.error('buildStatementTableRenderData: result is undefined/null');
			return { tableHtml: '', totalString: '' };
		}
		let currencySymbolMap = {};
		if (useSymbol) {
			currencySymbolMap = await cmp.getCurrencySymbols();
		}

		const data = result.data || result.DueTransList || [];
		const fields = [...(result.lastSectionSelectedFields || result.selectedFields || [])];
		let typeMap = result.selectedFieldTypes || result.fieldDataTypeMap;
		const LOCAL = (result.LOCALE || 'en-US').replace('_', '-');
		const showTotal = result.showTotal !== false;
		const aggregationField = result.aggregationField ? String(result.aggregationField) : null;
		const aggregationFieldLower = aggregationField ? aggregationField.toLowerCase() : null;
		if (typeof typeMap === 'string') {
			try { typeMap = JSON.parse(typeMap); } catch (e) { console.error('Error parsing typeMap', e); }
		}

		let totalMap = {};
		let balanceFieldAdded = false;
		if (!aggregationFieldLower && !fields.some(f => f && ['balance__c', 'balance__c'].includes(f.toLowerCase()))) {
			const allKeys = new Set([
				...(data.length > 0 ? Object.keys(data[0]) : []),
				...(typeMap ? Object.keys(typeMap) : [])
			]);
			for (const k of allKeys) {
				if (['balance__c', 'balance__c'].includes(k.toLowerCase())) {
					fields.push(k);
					balanceFieldAdded = true;
					break;
				}
			}
		}

		const renderedFields = fields.filter(field => {
			if (!field) {
				return false;
			}
			const lowerField = field.toLowerCase();
			return !(balanceFieldAdded && ['balance__c', 'balance__c'].includes(lowerField));
		});
		const isRightAlignedField = (fieldName) => {
			if (!fieldName) {
				return false;
			}
			const lowerFieldName = fieldName.toLowerCase();
			const apexType = (typeMap && typeMap[fieldName]) ? String(typeMap[fieldName]).toLowerCase() : 'text';
			return ['currency', 'double', 'decimal', 'number', 'integer', 'percent'].includes(apexType)
				|| lowerFieldName.includes('amount')
				|| lowerFieldName.includes('balance');
		};
		const labels = result.lastSectionSelectedFieldsLabel || result.selectedFieldsLabel || [];
		const headerLabels = labels.length > 0 ? labels : renderedFields;
		let tableHtml = `<table class="txSummaryTable">`;
		if (headerLabels.length > 0) {
			tableHtml += '<thead><tr>';
			headerLabels.forEach((label, index) => {
				const headerField = renderedFields[index];
				const headerClass = isRightAlignedField(headerField) ? ' class="rightAlign"' : '';
				tableHtml += `<th${headerClass}><b>${escapeHtml(label)}</b></th>`;
			});
			tableHtml += '</tr></thead>';
		}
		tableHtml += '<tbody>';
		const headerCellCount = headerLabels.length;
		const estimatedCellCount = (data.length * renderedFields.length) + headerCellCount;
		if (estimatedCellCount > MAX_PDF_TABLE_CELL_COUNT) {
			throw new Error(
				`The selected statement is too large to generate as a single PDF. ` +
				`Reduce the number of rows/columns or split the statement into smaller batches. ` +
				`(Estimated cells: ${estimatedCellCount}, limit: ${MAX_PDF_TABLE_CELL_COUNT})`
			);
		}

		data.forEach(rec => {
			if (!rec) return;
			tableHtml += '<tr>';
			fields.forEach(field => {
				if (!field) return;
				let val = rec[field] || '';
				let cellClass = '';
				const apexType = (typeMap && typeMap[field]) ? typeMap[field] : 'text';
				const lowerField = field.toLowerCase();
				const lowerApexType = String(apexType).toLowerCase();

				if (typeof val === 'string' && val.startsWith('<a')) {
					const start = val.indexOf('>') + 1;
					const end = val.lastIndexOf('</a>');
					if (start > 0 && end > start) {
						val = val.substring(start, end);
					}
				}

				if (isRightAlignedField(field)) {
					cellClass += ' class="rightAlign"';
					const currCode = rec.CurrencyIsoCode || '';
					const num = parseFloat(val);
					if (!isNaN(num)) {
						const shouldAggregate = showTotal && (
							(aggregationFieldLower && lowerField === aggregationFieldLower) ||
							(!aggregationFieldLower && ['balance__c', 'balance__c'].includes(lowerField))
						);
						if (shouldAggregate) {
							if (['number', 'integer'].includes(lowerApexType)) {
								totalMap.total = (totalMap.total || 0) + num;
							} else {
								totalMap[currCode] = (totalMap[currCode] || 0) + num;
							}
						}
						if (!['number', 'integer'].includes(lowerApexType)) {
							const currLabel = useSymbol ? (currencySymbolMap[currCode] || currCode) : currCode;
							val = currLabel + ' ' + num.toLocaleString(LOCAL, { minimumFractionDigits: 2 });
						} else {
							val = num.toLocaleString(LOCAL);
						}
					}
				} else if (['date', 'datetime'].includes(lowerApexType)) {

					if (val) {
						try {
							val = new Intl.DateTimeFormat(LOCAL).format(new Date(val));
						} catch (e) {
							console.error('Error formatting date:', val, e);
						}
					}
				}

				if (balanceFieldAdded && ['balance__c', 'balance__c'].includes(lowerField)) return;
				tableHtml += `<td${cellClass}>${escapeHtml(val)}</td>`;
			});
			tableHtml += '</tr>';
		});
		tableHtml += '</tbody></table>';

		let totalString = '';
		if (Object.keys(totalMap).length > 0) {
			const totalParts = [];
			for (let c in totalMap) {
				const totalLabel = useSymbol ? (currencySymbolMap[c] || c) : c;
				totalParts.push(`${totalLabel} ${totalMap[c].toLocaleString(LOCAL, { minimumFractionDigits: 2 })}`);
			}
			totalString = totalParts.join(', ');
		}

		return { tableHtml, totalString };
	}
	*/

	const buildStatementTableRenderData = async (result, useSymbol, cmp) => {
		const MAX_PDF_TABLE_CELL_COUNT = 100000;
         if (!result) {
            console.error('buildStatementTableRenderData: result is undefined/null');
            return { tableHtml: '', totalString: '' };
         }
         let currencySymbolMap = {};
         if (useSymbol) {
            currencySymbolMap = await cmp.getCurrencySymbols();
         }

         const data = result.data || result.DueTransList || [];
         const fields = [...(result.lastSectionSelectedFields || result.selectedFields || [])];
         let typeMap = result.selectedFieldTypes || result.fieldDataTypeMap;
         const LOCAL = (result.LOCALE || 'en-US').replace('_', '-');
         const showTotal = result.showTotal !== false;
         const aggregationField = result.aggregationField ? String(result.aggregationField) : null;
         const aggregationFieldLower = aggregationField ? aggregationField.toLowerCase() : null;
         if (typeof typeMap === 'string') {
            try { typeMap = JSON.parse(typeMap); } catch (e) { console.error('Error parsing typeMap', e); }
         }

         let totalMap = {};
         let balanceFieldAdded = false;
         if (!aggregationFieldLower && !fields.some(f => f && ['balance__c', 'celsrm__balance__c'].includes(f.toLowerCase()))) {
            const allKeys = new Set([
               ...(data.length > 0 ? Object.keys(data[0]) : []),
               ...(typeMap ? Object.keys(typeMap) : [])
            ]);
            for (const k of allKeys) {
               if (['balance__c', 'celsrm__balance__c'].includes(k.toLowerCase())) {
                  fields.push(k);
                  balanceFieldAdded = true;
                  break;
               }
            }
         }

         const renderedFields = fields.filter(field => {
            if (!field) {
               return false;
            }
            const lowerField = field.toLowerCase();
            return !(balanceFieldAdded && ['balance__c', 'celsrm__balance__c'].includes(lowerField));
         });
         const isRightAlignedField = (fieldName) => {
            if (!fieldName) {
               return false;
            }
            const lowerFieldName = fieldName.toLowerCase();
            const apexType = (typeMap && typeMap[fieldName]) ? String(typeMap[fieldName]).toLowerCase() : 'text';
            return ['currency', 'double', 'decimal', 'number', 'integer', 'percent'].includes(apexType)
               || lowerFieldName.includes('amount')
               || lowerFieldName.includes('balance');
         };

         //-- Start | FIN-9906 | Changed by Dhwanil | 10-Jun-2026  ----//
         const parseFormattedNumber = (value) => {
            if (typeof value === 'number') {
               return value;
            }

            if (value === null || value === undefined) {
               return NaN;
            }

            let normalizedValue = String(value).trim();
            if (!normalizedValue) {
               return NaN;
            }

            const isNegativeByParentheses = normalizedValue.includes('(') && normalizedValue.includes(')');
            normalizedValue = normalizedValue.replace(/[^\d.,+-]/g, '');
            const lastCommaIndex = normalizedValue.lastIndexOf(',');
            const lastDotIndex = normalizedValue.lastIndexOf('.');

            if (lastCommaIndex > -1 && lastDotIndex > -1) {
               if (lastCommaIndex > lastDotIndex) {
                  normalizedValue = normalizedValue.replace(/\./g, '').replace(',', '.');
               } else {
                  normalizedValue = normalizedValue.replace(/,/g, '');
               }
            } else if (lastCommaIndex > -1) {
               const commaParts = normalizedValue.split(',');
               const lastCommaPart = commaParts[commaParts.length - 1];
               normalizedValue = commaParts.length > 2 || lastCommaPart.length === 3
                  ? normalizedValue.replace(/,/g, '')
                  : normalizedValue.replace(',', '.');
            } else if (lastDotIndex > -1) {
               const dotParts = normalizedValue.split('.');
               const lastDotPart = dotParts[dotParts.length - 1];
               if (dotParts.length > 2 || lastDotPart.length === 3) {
                  normalizedValue = normalizedValue.replace(/\./g, '');
               }
            }

            const parsedValue = parseFloat(normalizedValue);
            return isNegativeByParentheses ? -parsedValue : parsedValue;
         };
         //-- End | FIN-9906 | Changed by Dhwanil | 10-Jun-2026 --//
         const labels = result.lastSectionSelectedFieldsLabel || result.selectedFieldsLabel || [];
         const headerLabels = labels.length > 0 ? labels : renderedFields;

         // << START - MM - FIN-9497 - Task -> Send Email -> PIP subtotal calculation for PDF (mirrors Excel logic) >>
         const pipSubtotalEnabled = !!result.pipSubtotal;
         const clearingDocumentField = result.clearingDocumentField || 'celsrm__Clearing_Document__c';
         let pipSubTotal = 0.0;
         let pipTotalCurrencyCode = '';
         let previousClearingDoc = null;
         const buildPipSubtotalRowHtml = () => {
            let rowHtml = '<tr>';
            fields.forEach(field => {
               if (!field) return;
               const lowerField = field.toLowerCase();
               if (balanceFieldAdded && ['balance__c', 'celsrm__balance__c'].includes(lowerField)) return;
               if (aggregationFieldLower && lowerField === aggregationFieldLower) {
                  rowHtml += `<td class="rightAlign" style="font-weight:bold;">${pipSubTotal.toLocaleString(LOCAL, { minimumFractionDigits: 2 })}</td>`;
               } else if (lowerField === 'currencyisocode') {
                  rowHtml += `<td style="font-weight:bold;">${pipTotalCurrencyCode}</td>`;
               } else {
                  rowHtml += `<td style="font-weight:bold;"></td>`;
               }
            });
            rowHtml += '</tr>';
            return rowHtml;
         };
         // << END - MM - FIN-9497 - Task -> Send Email -> PIP subtotal calculation for PDF (mirrors Excel logic) >>

         let tableHtml = `<table class="txSummaryTable" style="width:100%; border-collapse:collapse; border:1px solid #000;">`;
         if (headerLabels.length > 0) {
            tableHtml += '<thead><tr>';
            headerLabels.forEach((label, index) => {
               const headerField = renderedFields[index];
               const headerClass = isRightAlignedField(headerField) ? ' class="rightAlign"' : '';
               tableHtml += `<th${headerClass}><b>${escapeHtml(label)}</b></th>`;
            });
            tableHtml += '</tr></thead>';
         }
         tableHtml += '<tbody>';
         const headerCellCount = headerLabels.length;
         const estimatedCellCount = (data.length * renderedFields.length) + headerCellCount;
         if (estimatedCellCount > MAX_PDF_TABLE_CELL_COUNT) {
            throw new Error(
               `The selected statement is too large to generate as a single PDF. ` +
               `Reduce the number of rows/columns or split the statement into smaller batches. ` +
               `(Estimated cells: ${estimatedCellCount}, limit: ${MAX_PDF_TABLE_CELL_COUNT})`
            );
         }

         data.forEach(rec => {
            if (!rec) return;
            // << START - MM - FIN-9497 - Task -> Send Email -> PIP subtotal calculation for PDF (mirrors Excel logic) >>
            if (pipSubtotalEnabled) {
               const currentClearingDoc = rec[clearingDocumentField];
               if (previousClearingDoc !== null && currentClearingDoc !== previousClearingDoc) {
                  tableHtml += buildPipSubtotalRowHtml();
                  pipSubTotal = 0.0;
               }
               const aggVal = aggregationField ? parseFormattedNumber(rec[aggregationField]) : NaN;
               pipSubTotal += isNaN(aggVal) ? 0 : aggVal;
               pipTotalCurrencyCode = rec.CurrencyIsoCode || pipTotalCurrencyCode || 'USD';
               previousClearingDoc = currentClearingDoc;
            }
            // << END - MM - FIN-9497 - Task -> Send Email -> PIP subtotal calculation for PDF (mirrors Excel logic) >>
            tableHtml += '<tr>';
            fields.forEach(field => {
               if (!field) return;
               let val = rec[field] || '';
               let cellClass = '';
               const apexType = (typeMap && typeMap[field]) ? typeMap[field] : 'text';
               const lowerField = field.toLowerCase();
               const lowerApexType = String(apexType).toLowerCase();

               if (typeof val === 'string' && val.startsWith('<a')) {
                  const start = val.indexOf('>') + 1;
                  const end = val.lastIndexOf('</a>');
                  if (start > 0 && end > start) {
                     val = val.substring(start, end);
                  }
               }

               if (isRightAlignedField(field)) {
                  cellClass += ' class="rightAlign"';
                  const currCode = rec.CurrencyIsoCode || '';
                  //-- Start | FIN-9906 | Changed by Dhwanil | 10-Jun-2026 --//
                  const num = parseFormattedNumber(val);
                  //-- End | FIN-9906 | Changed by Dhwanil | 10-Jun-2026 --//
                  if (!isNaN(num)) {
                     const shouldAggregate = showTotal && (
                        (aggregationFieldLower && lowerField === aggregationFieldLower) ||
                        (!aggregationFieldLower && ['balance__c', 'celsrm__balance__c'].includes(lowerField))
                     );
                     if (shouldAggregate) {
                        if (['number', 'integer'].includes(lowerApexType)) {
                           totalMap.total = (totalMap.total || 0) + num;
                        } else {
                           totalMap[currCode] = (totalMap[currCode] || 0) + num;
                        }
                     }
                     if (!['number', 'integer'].includes(lowerApexType)) {
                        const currLabel = useSymbol ? (currencySymbolMap[currCode] || currCode) : currCode;
                        val = currLabel + ' ' + num.toLocaleString(LOCAL, { minimumFractionDigits: 2 });
                     } else {
                        val = num.toLocaleString(LOCAL);
                     }
                  }
               } else if (['date', 'datetime'].includes(lowerApexType)) {
                 
                  if (val) {
                     try {
                        val = new Intl.DateTimeFormat(LOCAL).format(new Date(val));
                     } catch (e) {
                        console.error('Error formatting date:', val, e);
                     }
                  }
               } 

               if (balanceFieldAdded && ['balance__c', 'celsrm__balance__c'].includes(lowerField)) return;
               tableHtml += `<td${cellClass}>${escapeHtml(val)}</td>`;
            });
            tableHtml += '</tr>';
         });
         // << START - MM - FIN-9497 - Task -> Send Email -> PIP subtotal calculation for PDF (final group subtotal row) >>
         if (pipSubtotalEnabled && data.length > 0) {
            tableHtml += buildPipSubtotalRowHtml();
         }
         // << END - MM - FIN-9497 - Task -> Send Email -> PIP subtotal calculation for PDF (final group subtotal row) >>
         tableHtml += '</tbody></table>';

         let totalString = '';
         if (Object.keys(totalMap).length > 0) {
            const totalParts = [];
            for (let c in totalMap) {
               const totalLabel = useSymbol ? (currencySymbolMap[c] || c) : c;
               //-- Start | FIN-9906 | Changed by Dhwanil | 26-May-2026 --//
               totalParts.push(`${totalLabel} ${totalMap[c].toLocaleString(LOCAL, { minimumFractionDigits: 2 })}`);
               //-- End | FIN-9906 | Changed by Dhwanil | 26-May-2026 --//
            }
            totalString = totalParts.join(', ');
         }

         return { tableHtml, totalString };
	}
	// << END - MM - FIN-10130 | Task -> Send Email (Replace custom place holders)>> 

	const escapeHtml = (value) => {
		if (value === null || value === undefined) {
			return '';
		}
		return String(value)
			.replace(/&/g, '&amp;')
			.replace(/</g, '&lt;')
			.replace(/>/g, '&gt;')
			.replace(/"/g, '&quot;')
			.replace(/'/g, '&#39;');
	}
	
	//-- FIN-9729 | Changed by Dilshad | 12-May-2026 | Start --//
	const generateHTMLContentForExcel = async (values, returnValues, cmp, ShowToastEvent, fileData) => {
		try {
			let contentHtml = fileData.templateBody || fileData.stmtTemplate;
			let allTablesHtml = '';
			const LOCAL = (fileData.LOCALE || 'en-US').replace('_', '-');
			// const attachmentFontFamily = fileData['attachmentFontFamily'] || 'sans-serif';
			const attachmentFontSize = fileData['attachmentFontSize'] || '12px';

			if (values.listOfStep && values.listOfStep.length > 0) {
				values.listOfStep.forEach(step => {
					const columns = values[step + 'columns'];
					const data = fileData[step];
					const showTotal = values[step + 'showTotal'];
					const aggregationField = values[step + 'aggregationField'];
					const totalTitle = values[step + 'totalTitle'];

					let tableHtml = `<table id="txSummaryTableJS" style="width:100%; border-collapse:collapse; border:1px solid #000;">`;
					tableHtml += '<thead><tr>';
					if (columns) {
						columns.forEach(col => {
							// << START - MM - FIN-10130 | Excel header color to alin with PDF >> 
							// tableHtml += `<th style="border:1px solid #000; padding:4px; background-color:#DEF2F1; font-weight:bold; text-align:center; vertical-align:middle;">${col.label}</th>`;
							tableHtml += `<th style="border:1px solid #000; padding:4px; background-color:black; font-weight:bold; text-align:center; vertical-align:middle; font:white; ">${col.label}</th>`;
							// << END - MM - FIN-10130 | Excel header color to alin with PDF >> 
						});
					}
					tableHtml += '</tr></thead><tbody>';

					let totalMap = {};

					if (data && data.length > 0) {
						// << START - MM - FIN-9497 - Task -> Send Email -> PIP subtotal calculation >> 
						let subTotal = 0.0;
						let totalCurrencyCode = '';
						let previousClearingDoc = null;
						// << END - MM - FIN-9497 - Task -> Send Email -> PIP subtotal calculation >> 
						data.forEach(record => {
							// << START - MM - FIN-9497 - Task -> Send Email -> PIP subtotal calculation >> 
							if(step == 'PaymentInProgress') {
								let currentClearingDoc = record['celsrm__Clearing_Document__c'];
								if(previousClearingDoc != null && currentClearingDoc != previousClearingDoc) {
									tableHtml += '<tr>';
									columns.forEach(col => {
										let style = 'border:1px solid #000; padding:4px; font-weight: bold;';
										let align = 'right';
										if(col.fieldName === aggregationField) {
											style += `text-align:${align};`;
											tableHtml += `<td style="${style}">${subTotal.toFixed(2)}</td>`;
										} else if(col.fieldName === 'CurrencyIsoCode') {
											align = 'left';
											style += `text-align:${align};`;
											tableHtml += `<td style="${style}">${totalCurrencyCode}</td>`;
										} else {
											tableHtml += `<td style="${style}"></td>`;
										}
									});
									tableHtml += '</tr>';
									subTotal = parseFloat(record[aggregationField]) || 0;
									totalCurrencyCode = record['CurrencyIsoCode'] || 'USD';
								} else {
									subTotal += parseFloat(record[aggregationField]) || 0;
									totalCurrencyCode = record['CurrencyIsoCode'] || 'USD';
								}
								previousClearingDoc = currentClearingDoc;
							}
							// << END - MM - FIN-9497 - Task -> Send Email -> PIP subtotal calculation >> 
							tableHtml += '<tr>';
							columns.forEach(col => {
								let val = record[col.fieldName] || '';
								let style = 'border:1px solid #000; padding:4px;';
								let align = 'left';

								if (col.type === 'currency') {
									align = 'right';
									const currencyCode = record.CurrencyIsoCode || 'USD';
									const amount = parseFloat(val) || 0;
									val = getCurrencySymbol(currencyCode) + ' ' + amount.toLocaleString(LOCAL, { minimumFractionDigits: 2 });

									if (showTotal && col.fieldName === aggregationField) {
										totalMap[currencyCode] = (totalMap[currencyCode] || 0) + amount;
									}
								} else if (col.type === 'number') {
									align = 'right';
									const amount = parseFloat(val) || 0;
									val = amount.toLocaleString(LOCAL);
									if (showTotal && col.fieldName === aggregationField) {
										totalMap['total'] = (totalMap['total'] || 0) + amount;
									}
								} else if (col.type === 'date' || col.type === 'datetime') {
									align = 'left';
									if (val) {
										try {
											val = new Intl.DateTimeFormat(LOCAL).format(new Date(val));
										} catch (e) {
											console.error('Error formatting date:', val, e);
										}
									}
								} else {
									if (typeof val === 'string' && val.startsWith('<a')) {
										const start = val.indexOf('>') + 1;
										const end = val.lastIndexOf('</a>');
										val = val.substring(start, end);
									}
								}

								style += `text-align:${align};`;
								tableHtml += `<td style="${style}">${val}</td>`;
							});
							tableHtml += '</tr>';
						});
						// << START - MM - FIN-9497 - Task -> Send Email -> PIP subtotal calculation >> 
						if(step == 'PaymentInProgress') {
							tableHtml += '<tr>';
							columns.forEach(col => {
								let style = 'border:1px solid #000; padding:4px; font-weight: bold;';
								let align = 'right';
								if(col.fieldName === aggregationField) {
									style += `text-align:${align};`;
									tableHtml += `<td style="${style}">${subTotal.toFixed(2)}</td>`;
								} else if(col.fieldName === 'CurrencyIsoCode') {
									align = 'left';
									style += `text-align:${align};`;
									tableHtml += `<td style="${style}">${totalCurrencyCode}</td>`;
								} else {
									tableHtml += `<td style="${style}"></td>`;
								}
							});
							subTotal = 0.0;
							tableHtml += '</tr>';
						}
						// << END - MM - FIN-9497 - Task -> Send Email -> PIP subtotal calculation >> 
					}
					tableHtml += '</tbody></table>';
					allTablesHtml += tableHtml;
					debugger;
					if (showTotal && Object.keys(totalMap).length > 0) {
						let totalsHtml = `<div style="font-weight:bold; text-align:right; margin-bottom:20px;white-space: normal;overflow-wrap: break-word;">`;
						totalsHtml += (totalTitle || 'Total') + ' : ';

						const totalString = Object.entries(totalMap)
							.map(([key, value]) => {
								const currencyCode = key === 'total' ? 'USD' : key;
								const symbol = key === 'total' ? '' : getCurrencySymbol(currencyCode);
								const displayValue = value.toLocaleString('en-US', { minimumFractionDigits: 2 });

								return key === 'total'
									? `${displayValue}`
									: `${symbol} ${displayValue}`;
							})
							.join(', ');

						totalsHtml += `${totalString}`;
						totalsHtml += '</div>';

						allTablesHtml += totalsHtml;
						// << START - MM - FIN-9483 - [Attachment] [Non Consolidated Treatment] StepName.Transaction.Summary should work >>
						if (contentHtml) {
							if (contentHtml.includes('{' + step + '.Transaction.Summary}')) {
								contentHtml = contentHtml.replace('{' + step + '.Transaction.Summary}', tableHtml);
							}
						}
						// << END - MM - FIN-9483 - [Attachment] [Non Consolidated Treatment] StepName.Transaction.Summary should work >>
					}
					// << START - MM - FIN-9483 - [Attachment] [Non Consolidated Treatment] StepName.Transaction.Summary should work >>
					else if (contentHtml) {
						if (contentHtml.includes('{' + step + '.Transaction.Summary}')) {
							contentHtml = contentHtml.replace('{' + step + '.Transaction.Summary}', tableHtml);
						}
					}
					// << END - MM - FIN-9483 - [Attachment] [Non Consolidated Treatment] StepName.Transaction.Summary should work >>
				});
			}

			// << START - MM - FIN-9483 - [Attachment] [Non Consolidated Treatment] StepName.Transaction.Summary should work >>
			// if (contentHtml) {
			// 	if (contentHtml.includes('{Transaction.Summary}')) {
			// 		contentHtml = contentHtml.replace('{Transaction.Summary}', allTablesHtml);
			// 	}
			// } else {
			// 	contentHtml = allTablesHtml;
			// }
			if (!contentHtml) {
				contentHtml = allTablesHtml;
			}
			// << END - MM - FIN-9483 - [Attachment] [Non Consolidated Treatment] StepName.Transaction.Summary should work >>

			returnValues["finalContent"] = contentHtml;
			return returnValues;

		} catch (error) {
			console.error('Error in createPdfFileForExcel:', error);
			cmp.dispatchEvent(new ShowToastEvent({
				title: "Error in createPdfFileForExcel",
				message: 'PDF HTML generation failed.',
				variant: "Error",
				mode: "dismissable"
			}));
			return null;
		}
	}

	const generateHTMLContentForConsolidatedExcel = async (values, returnValues) => {
		try {
			if (!values) {
				console.error('generateHTMLContentForConsolidatedExcel: values is undefined/null');
				return null;
			}
			let contentHtml = values.templateBody || values.stmtTemplate;
			const LOCAL = (values.LOCALE || 'en-US').replace('_', '-');
			let tableHtml = `<table id="txSummaryTableJS" style="width:100%; border-collapse:collapse; border:1px solid #000;">`;

			const columns = values.columns || [];
			const data = values.data || [];

			tableHtml += '<thead><tr>';
			if (columns) {
				columns.forEach(col => {
					tableHtml += `<th style="border:1px solid #000; padding:4px; background-color:#DEF2F1; font-weight:bold; text-align:center; vertical-align:middle;">${col.label}</th>`;
				});
			}
			tableHtml += '</tr></thead><tbody>';

			let totalMap = {};
			const hasListStepValue = values.listOfStep && values.listOfStep.length > 0;
			const totalTitle = hasListStepValue ? values[values.listOfStep[0] + 'totalTitle'] : 'Total Amount';
			const aggregationField = hasListStepValue ? values[values.listOfStep[0] + 'aggregationField'] : 'Amount__c';
			const showTotal = hasListStepValue ? values[values.listOfStep[0] + 'showTotal'] : true;

			if (data && data.length > 0) {
				data.forEach(record => {
					tableHtml += '<tr>';
					columns.forEach(col => {
						let val = record[col.fieldName] || '';
						let style = 'border:1px solid #000; padding:4px;';
						let align = 'left';

						if (col.type === 'currency') {
							align = 'right';
							const currencyCode = record.CurrencyIsoCode || 'USD';
							const amount = parseFloat(val) || 0;
							val = getCurrencySymbol(currencyCode) + ' ' + amount.toLocaleString(LOCAL, { minimumFractionDigits: 2 });

							if (showTotal && col.fieldName === aggregationField) {
								totalMap[currencyCode] = (totalMap[currencyCode] || 0) + amount;
							}
						} else if (col.type === 'number') {
							const amount = parseFloat(val) || 0;
							val = amount.toLocaleString(LOCAL);

							if (showTotal && col.fieldName === aggregationField) {
								totalMap['total'] = (totalMap['total'] || 0) + amount;
							}
						} else if (col.type === 'date' || col.type === 'datetime') {
							align = 'left';
							if (val) {
								try {
									val = new Intl.DateTimeFormat(LOCAL).format(new Date(val));
								} catch (e) {
									console.error('Error formatting date:', val, e);
								}
							}
						} else {
							if (typeof val === 'string' && val.startsWith('<a')) {
								const start = val.indexOf('>') + 1;
								const end = val.lastIndexOf('</a>');
								val = val.substring(start, end);
							}
						}

						style += `text-align:${align};`;
						tableHtml += `<td style="${style}">${val}</td>`;
					});
					tableHtml += '</tr>';
				});
			}
			tableHtml += '</tbody></table>';

			if (showTotal && Object.keys(totalMap).length > 0) {
				let totalsHtml = `<div style="font-weight:bold; text-align:right; margin-bottom:20px;white-space: normal;overflow-wrap: break-word;">`;
				totalsHtml += (totalTitle || 'Total') + ' : ';
				const totalString = Object.entries(totalMap)
					.map(([key, value]) => {
						const currencyCode = key === 'total' ? 'USD' : key;
						const symbol = key === 'total' ? '' : getCurrencySymbol(currencyCode);
						const displayValue = value.toLocaleString('en-US', { minimumFractionDigits: 2 });
						// Start | FIN-9565 | Changed by Dhwanil | 14 May 2026 --//
						//const label = totalTitle || 'Total';
						if (key === 'total') {
							return `${displayValue}`;
						} else {
							return `${symbol} ${displayValue}`;
						}
						// Ends | FIN-9565 | Changed by Dhwanil | 14 May 2026 --//
					})
					.join(', ');

				totalsHtml += totalString;
				totalsHtml += '</div>';

				tableHtml += totalsHtml;
			}

			if (contentHtml) {
				if (contentHtml.includes('{Transaction.Summary}')) {
					contentHtml = contentHtml.replace('{Transaction.Summary}', tableHtml);
				}
			} else {
				contentHtml = tableHtml;
			}

			returnValues["finalContent"] = contentHtml;
			return returnValues;

		} catch (error) {
			console.error('Error creating Consolidated PDF file for Excel:', error);
			return null;
		}
	}

	const generateHTMLContentForPDF = async (values, returnValues, cmp, ShowToastEvent, fileData) => {
		try {
			//debugger;
			let allTablesHtml = '';
			const LOCAL = (fileData.LOCALE || 'en-US').replace('_', '-');;

			//-- Start | FIN-9543 | Changed by Dhwanil | 06-Apr-2026 --//
			//-- End | FIN-9543 | Changed by Dhwanil | 06-Apr-2026 --//

			// << START - MM - FIN-10130 - Task -> Send Email -> PDF Non Consolidated attachment: mirror the working
			// Excel flow (generateHTMLContentForExcel / FIN-9483) by taking the attachment template body (already
			// resolved for step-scoped Total* tokens server-side) and inserting each step's table HTML at its own
			// {StepName.Transaction.Summary} marker, instead of just concatenating all steps into one blob >>
			let contentHtml = fileData.templateBody;
			// << END - MM - FIN-10130 - Task -> Send Email -> PDF Non Consolidated attachment: mirror the working

			if (values.listOfStep && values.listOfStep.length > 0) {
				for (const step of values.listOfStep) {
					const columns = values[step + 'columns'];
					const data = fileData[step];
					const showTotal = values[step + 'showTotal'];
					const aggregationField = values[step + 'aggregationField'];
					const totalTitle = values[step + 'totalTitle'];
					const pdfTable = await buildTaskPDFTableHtml(columns, data, {
						showTotal: showTotal,
						aggregationField: aggregationField,
						totalTitle: totalTitle,
						locale: LOCAL,
						// << START - MM - FIN-9497 - Task -> Send Email -> PIP subtotal calculation for PDF (mirrors Excel logic) >>
						pipSubtotal: step === 'PaymentInProgress',
						clearingDocumentField: 'celsrm__Clearing_Document__c'
						// << END - MM - FIN-9497 - Task -> Send Email -> PIP subtotal calculation for PDF (mirrors Excel logic) >>
					}, cmp);
					// << START - MM - FIN-9497 - Task -> Send Email -> PIP subtotal calculation for PDF (mirrors Excel logic) >>
					// allTablesHtml += pdfTable.tableHtml + pdfTable.totalsHtml;
					const stepTableHtml = pdfTable.tableHtml + pdfTable.totalsHtml;
					allTablesHtml += stepTableHtml;
					// << END - MM - FIN-9497 - Task -> Send Email -> PIP subtotal calculation for PDF (mirrors Excel logic) >>

					// << START - MM - FIN-10130 - insert this step's table at its own {StepName.Transaction.Summary} marker >>
					if (contentHtml && contentHtml.includes('{' + step + '.Transaction.Summary}')) {
						contentHtml = contentHtml.replace('{' + step + '.Transaction.Summary}', stepTableHtml);
					}
					// << END - MM - FIN-10130 - insert this step's table at its own {StepName.Transaction.Summary} marker >>
				}
			}

			//-- FIN-9729 | Changed by Dilshad | 07-May-2026 | Start --//
			// << START - MM - FIN-10130 - if we have a resolved template body, use it (already merged with per-step
			// tables/totals above) and let the PDF page use it as-is; only fall back to the old flat blob + VF-side
			// template render when no attachment template body could be resolved (preserves prior behavior) >>
			/**
			returnValues["finalContent"] = allTablesHtml;
			returnValues["renderWithAttachmentTemplate"] = !!values.attachmentTemplate;
			 */
			if (contentHtml) {
				returnValues["finalContent"] = contentHtml;
				returnValues["renderWithAttachmentTemplate"] = false;
			} else {
				returnValues["finalContent"] = allTablesHtml;
				returnValues["renderWithAttachmentTemplate"] = !!values.attachmentTemplate;
			}
			// << END - MM - FIN-10130 - if we have a resolved template body, use it (already merged with per-step
			//-- FIN-9729 | Changed by Dilshad | 07-May-2026 | End --//
			return returnValues;

		} catch (error) {
			console.error('Error in generateHTMLContentForPDF:', error);
			cmp.dispatchEvent(new ShowToastEvent({
				title: "Error in generateHTMLContentForPDF",
				message: 'PDF HTML generation failed.',
				variant: "Error",
				mode: "dismissable"
			}));
			return null;
		}
	}

	const generateHTMLContentForConsolidatedPDF = async (values, returnValues, cmp) => {
		try {
			//debugger;
			if (!values) {
				console.error('generateHTMLContentForConsolidatedPDF: values is undefined/null');
				return null;
			}

			//-- Start | FIN-9543 | Changed by Dhwanil | 06-Apr-2026 --//
			//-- End | FIN-9543 | Changed by Dhwanil | 06-Apr-2026 --//

			const LOCAL = (values.LOCALE || 'en-US').replace('_', '-');

			const columns = values.columns || [];
			const data = values.data || [];
			const hasListStepValue = values.listOfStep && values.listOfStep.length > 0;
			const totalTitle = hasListStepValue ? values[values.listOfStep[0] + 'totalTitle'] : 'Total Amount';
			const aggregationField = hasListStepValue ? values[values.listOfStep[0] + 'aggregationField'] : 'celsrm__Amount__c';
			const showTotal = hasListStepValue ? values[values.listOfStep[0] + 'showTotal'] : true;
			const pdfTable = await buildTaskPDFTableHtml(columns, data, {
				showTotal: showTotal,
				aggregationField: aggregationField,
				totalTitle: totalTitle,
				locale: LOCAL
			}, cmp);
			const tableHtml = pdfTable.tableHtml + pdfTable.totalsHtml;
			// -- FIN-9729 | Changed by Dilshad | 07-May-2026 | Start --//
			returnValues["finalContent"] = tableHtml;
			returnValues["renderWithAttachmentTemplate"] = !!returnValues.attachmentTemplate;
			//-- FIN-9729 | Changed by Dilshad | 07-May-2026 | End --//
			return returnValues;

		} catch (error) {
			console.error('Error creating Consolidated PDF file:', error);
			return null;
		}
	}
	//-- FIN-9747 | Changed by Dilshad | 12-May-2026 | End --//

	//-- End | FIN-8638 | Changed by Dhwanil | 28 Nov 2025 --//

	// << Start - ND - FIN-8132 - Email Templates based on Account Locale >>
	// << CHANGE - MM - FIN-8174 - Dynamic translated headers based account local | Renamed fucntion from onChangeCompanyCode -> onChangeAccountLocale>>
	function onChangeAccountLocale(values, invoke, dataServiceObj, fireEvent, cmp, rowvals, NavigationMixin, rowNum, ShowToastEvent) {
		debugger;
		return new Promise(function (resolve, reject) {
			if (values['accountLocale'] && values['accountLocale'] != null) {
				invoke({
					className: 'TaskTreatmentController',
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
	
	// << START - MM - FIN-8174 - Dynamic translated headers based account local | On Load of Send Email Screen for treatment>>
	function onLoadTaskSendEmail(values, invoke, dataServiceObj, fireEvent, cmp, rowvals, NavigationMixin, rowNum, ShowToastEvent) {
		debugger;
		return new Promise(function (resolve, reject) {
			invoke({
				className: 'TaskTreatmentController',
				functionName: 'setAccountLocale',
				values: values
			}).then(result => {
				fireEvent(cmp.pageRef, 'ComposeEmail__'+ cmp.additionalAttributes.screenName, result.accountLocale);
				resolve(result);
			}).catch(error => {
				console.log('error :' + error);
				reject(error);
			});
			// fireEvent(cmp.pageRef, 'ComposeEmail__'+ cmp.additionalAttributes.screenName, values.CompanyCode);
			// resolve(values);
		});
	}
	// << END - MM - FIN-8174 - Dynamic translated headers based account local | On Load of Send Email Screen for treatment>>
	// << End - ND - FIN-8132 - Email Templates based on Account Locale >>
	// << Start - ND - FIN-8132 - Email Templates based on Account Locale >>
	exports.onChangeAccountLocale = onChangeAccountLocale;
	// << End - ND - FIN-8132 - Email Templates based on Account Locale >>

	//-- End | FIN-8209 | Changed By Dilshad | 13-Aug-2025 --//
	exports.submitSendEmailScreen = submitSendEmailScreen;
	//-- End | FIN-8048 | Changed by Ravi | 23 July 2025 --//
	exports.openMakeACallScreen = openMakeACallScreen;
	exports.openSendEMailScreen = openSendEMailScreen;
	exports.refreshParentScreenValue = refreshParentScreenValue;
	exports.openEditPage = openEditPage;
	exports.removeCommunication = removeCommunication;
	exports.onPageLoadSetView = onPageLoadSetView;
	exports.OnChangeCantactNamePhone = OnChangeCantactNamePhone;
	exports.callToAgent = callToAgent;
	exports.onDidnotpickcall = onDidnotpickcall;

	// << START - MM - FIN-8174 - Dynamic translated headers based account local | On Load of Send Email Screen for treatment>>
	exports.onLoadTaskSendEmail = onLoadTaskSendEmail;
	// << END - MM - FIN-8174 - Dynamic translated headers based account local | On Load of Send Email Screen for treatment>>

	//--- DO NOT CHANGE CODE | START ---//
	Object.defineProperty(exports, '__esModule', {
		value: true
	});
	//--- DO NOT CHANGE CODE | END ---//

})));
