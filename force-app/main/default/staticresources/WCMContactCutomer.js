(function(global, factory) {
    typeof exports === 'object' && typeof module !== 'undefined' ? factory(exports) :
        typeof define === 'function' && define.amd ? define(['exports'], factory) :
        (factory((global.gog = global.gog || {})));
}(this, (function(exports) {
    'use strict';

    var version = "1.0.0";
	
	function showNoteBody(values, invoke, ds) {
		values["showNoteBody"] = "true";
		return new Promise(function(resolve, reject) {
			resolve(values);
		});
	}
	function OnChangeCantactNamePhone(values, invoke, ds) {
		var contactId = values["ContactName"];
		
		return new Promise(function(resolve, reject) {
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
			// invoke({ 
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
	function onContactMethods(values, invoke, ds) {
		if(values["ContactMehods"] == "Phone" && values["ContactnotpickcallMethod"] != null && values["ContactnotpickcallMethod"] != "") {
			values["isFollowup"] = true;
		}
		return new Promise(function(resolve, reject) {
			resolve(values);
		});
	}
	function onDidnotpickcall(values, invoke, ds) {
		values["isFollowup"] = true;
		return new Promise(function(resolve, reject) {
		
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
	function showFollowupDays(values, invoke, ds) {
		return new Promise(function(resolve, reject){
			invoke({
				className: 'WCM_FetchFolloupDays', 
				values: values 
			}).then(result1 => {
				var result = JSON.parse(JSON.stringify(result1));
				result.StatementFormat = 'PDF';
				gog.generateStatementforAttachment(result, invoke, ds).then(result1 => {
					result = JSON.parse(JSON.stringify(result1));
					delete result.enableSubmitButton;
					resolve(result);
				}).catch(err => {
					reject(err);
				});
				
			}).catch(error => {
				console.log('error :' + error);
				reject(error);
			});
		});
	}
	function generateStatementforAttachment (values, invoke, ds) {
		var formatType = values['StatementFormat'];
		return new Promise(function(resolve, reject) {
			if(!formatType && values['AttachCheckBox']) {
				reject('Please select Statement Format');
			} else if(values['AttachCheckBox']) {
				/*if(arr && arr.length > 0) {
					for(var i=0; i<arr.length;i++) {
						if(i == arr.length-1) {
							trxnId += arr[i].Id;
						} else {
							trxnId += arr[i].Id + ',';
						}
					}			
					var url = '';
					if(values['tempKey'] != undefined && values['tempKey'] != null){
						url = '/apex/PreviewStatement?formatType='+formatType+'&accId='+accId+'&ListView='+ListView+'&key='+values['tempKey'];
					}else{
						url = '/apex/PreviewStatement?formatType='+formatType+'&accId='+accId+'&ListView='+ListView+'&txIds='+trxnId;
					} 
					window.open(url,'_blank');
				}
				resolve({});*/
				values.preview = true;
				gog.createStatementAttachmentonPreview(values, invoke, ds).then(result1 => {
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
	function generateStatement(values, invoke, ds) {
		//var accId = values['Id'];
		//var arr = values['TransactionList'];
		var formatType = values['StatementFormat'];
		//var tempId ;
		//var trxnId = '';
		//var ListView = values['ListView']
		return new Promise(function(resolve, reject) {
			if(!formatType) {
				reject('Please select Statement Format');
			} else {
				/*if(arr && arr.length > 0) {
					for(var i=0; i<arr.length;i++) {
						if(i == arr.length-1) {
							trxnId += arr[i].Id;
						} else {
							trxnId += arr[i].Id + ',';
						}
					}			
					var url = '';
					if(values['tempKey'] != undefined && values['tempKey'] != null){
						url = '/apex/PreviewStatement?formatType='+formatType+'&accId='+accId+'&ListView='+ListView+'&key='+values['tempKey'];
					}else{
						url = '/apex/PreviewStatement?formatType='+formatType+'&accId='+accId+'&ListView='+ListView+'&txIds='+trxnId;
					} 
					window.open(url,'_blank');
				}
				resolve({});*/
				values.preview = true;
				gog.createStatementAttachmentonPreview(values, invoke, ds).then(result1 => {
					var result = JSON.parse(JSON.stringify(result1));
					delete result.preview;
					var attId = result['AttachmentIDSendStmt'];
					var url = "/servlet/servlet.FileDownload?file=" + attId;
					window.open(url, '_blank');
					resolve({});
				}).catch(err => {
					reject(err);
				});
			}
		});
	}
	
	function createStatementAttachmentonPreview(values, invoke, ds) {
		//var accId = values['Id'];
		//var arr = values['TransactionList'];
		var arr = values['TransactionList'];
		var trxnId = '';
		var formatType = values['StatementFormat'];
		return new Promise(function (resolve, reject) {
			//	if(values['AttachCheckBox']) {
			if (!formatType) {
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
						// htmlBody ="<html><head><style> .thStyle{ border-right:1px #ccc solid; border-bottom:1px #ccc solid; text-align: center;}.trStyle{ border-right:1px #ccc solid; border-bottom:1px #ccc solid;background-color: rgb(249, 249, 249);}.tdStyle{ border-right:1px #ccc solid; border-bottom:1px #ccc solid; text-align: center;} </style></head>";
						//-- Start | FIN-8048 | Changed by Ravi | 29 July 2025 --//
						var st =  "<head><style>@page{size:landscape;}</style>";
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
							var newAmt = newLst[i].celsrm__Balance__c == null ? 0 : newLst[i].celsrm__Balance__c;
							TotalBalance = TotalBalance + newAmt;
							
						}
						// htmlBody += "<tr>";
						// htmlBody += "<td colspan='" + newLstFields.length + "' > <b> Total</b>  $" + TotalBalance.toFixed(2) + "</td>";
						// htmlBody += "</tr>";
						htmlBody += "</table>";
						delete result.DueTransList;
						delete result.selectedFields;
						delete result.selectedFieldsLabel;
						delete result.TransIds;
						delete result.returnTemplateAmount;
						console.log("htmlBody" + htmlBody);
						
						ContentSt= ContentSt.replace("<head>",st);
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
			}
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
	
	function createStatementAttachment(values, invoke, ds) {
		//var accId = values['Id'];
		//var arr = values['TransactionList'];
		var formatType = values['StatementFormat'];
		//-- Start | FIN-8509 | Changed by Ravi | 13-Oct-2025 --//
		let fileName = values['fileName'] ? values['fileName'] : 'BillingStatement';
		//-- Ends | FIN-8509 | Changed by Ravi | 13-Oct-2025 --//
		return new Promise(function(resolve, reject) {
			if(values['AttachCheckBox']) {
				if(!formatType) {
					reject('Please select Statement Format');
				} else {
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
	
	function changeStatementFormat(values, invoke, ds) {
		//var accId = values['Id'];
		//var arr = values['TransactionList'];
		var formatType = values['StatementFormat'];
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
	
	function updateEmailBodyValue(values,invoke,ds){
		return new Promise(function(resolve, reject) {
		if(values['ComposeEmail']){
				if(values['ComposeEmail'].oldBody !== undefined && values['ComposeEmail'].oldBody !== null){
					values['ComposeEmail'].body = values['ComposeEmail'].oldBody;
				} else {
					values['ComposeEmail'].body = null;
				}
			}
			
			resolve(values);			
		});
	}
	function onPhoneTypeChange(values, invoke, ds) {
		if(values["PhoneType"] == "Incoming"){
			values["isFollowup"] = false;
		}else if(values["ContactnotpickcallMethod"] != null && values["ContactnotpickcallMethod"] != ""){
			values["isFollowup"] = true;
		}
		
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
	
	function callToAgent(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum,ShowToastEvent) {
		
		return new Promise(function(resolve, reject) {

			let transMap = {};
			let transList = []
			for(let trans of Object.values(values['TransactionList'])){
				transList.push(trans.Id);
			}
			transMap.transactions = transList;

			let customVals = {};
			customVals.account = values.Id;
			customVals.contactNo = values.DialContact.replace("(", "").replace(")", "").replace(/\s/g, '').replace("-", "");;
			customVals.transactions = transMap;
			customVals.screenName = 'Contact Customer';
			customVals.calledTo = values.ContactName.split("_")[0];

			invoke({
				nameSpace : '', 
				className: 'OutgoingCallHandler', 
				functionName: 'isCallerIdVerified',
				values: customVals
			}).then(result => { 
				values = result;
				
				if(!result.isCallerIdVerified){
					var data = {};
					data.phone = result.UserPhoneNumber;
					data.Message = 'Your ' + result.UserPhoneNumber + ' number is not verified. To verify please click on Verify button.';
					data.callLogDetails = customVals;
					
					let customChangeHandler = {
						"callingControlName":"Dial",
						"targetScreen": "CallerIDVerification",
						"targetScreenSize": "small-width",
						"sourceControlName":'',
						"vals": data
					};
					fireEvent(cmp.pageRef, 'openChildScreen_' + 'WCMContactCustomerScreen' + "Dial", customChangeHandler);
					resolve(result);
				}else{
					invoke({
						nameSpace : '', 
						className: 'OutgoingCallHandler', 
						functionName: 'callToCustomer',
						values: customVals
					}).then(result => { 
							console.log(' Result >>>>>> ' + JSON.stringify(result));
						values = result;
						if(result && result.CustomerCommunicationId){
							result['showCallingIcon'] = true;
							result['CallingIcon'] = '<div style="margin-top: 1.55rem;border: 1px solid rgb(208, 203, 203);border-top: 1px solid rgb(208, 203, 203);border-bottom: 1px solid rgb(208, 203, 203);border-top-left-radius: 7px;border-bottom-left-radius: 7px;z-index: 10;display: inline-flex;cursor: pointer;width: 45px;height: 32px;border-radius: 4px;box-shadow: 0 3px 10px 0 rgba(0, 0, 0, 0.04);background-color: #ffffff;padding-left: 6px;" >	<span class="width: 36px; height: 30px; text-align: center; margin-top: 7px;">		<img src="https://srm-standard-tso--c.documentforce.com/sfc/dist/version/renditionDownload?rendition=ORIGINAL_Gif&amp;versionId=0685w00000Cadop&amp;operationContext=DELIVERY&amp;contentId=05T5w00000gmfic&amp;page=0&amp;d=/a/5w000000LuDQ/FoN5L4s095pOCSyCZhlywyp8_hUJkz7I0Hpk2WwEoXo&amp;oid=00D5w000002ve0c&amp;dpt=null&amp;viewId="			alt="Call" />	</span></div>';
							
							cmp.dispatchEvent(new ShowToastEvent({
								title: "Success",
								message: 'Call has been initiated.',
								variant: "Success",
								mode: "dismissable"
							}));
							checkCallStatus(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum,ShowToastEvent,result);
						}else{
							cmp.dispatchEvent(new ShowToastEvent({
								title: "error",
								message: 'There is problem in making call. Please try again later!',
								variant: "error",
								mode: "dismissable"
							}));
						}
						resolve(result);
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
	
	function checkCallStatus(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum,ShowToastEvent,callResult) {
		console.log(' CustomerCommunication ID >>> ' + callResult.CustomerCommunicationId);
		return new Promise(function(resolve, reject) {
			
			invoke({
				nameSpace : '', 
				className: 'OutgoingCallHandler', 
				functionName: 'checkChangeStatus',
				values: callResult
			}).then(result => {
				console.log('result status >>> : ' + JSON.stringify(result));
				if(result && result.callStatus && result.callStatus !== 'Call Initiation'){
					let message = '';
					let variant = 'Success';
					if(result.callStatus == 'Call Completed'){
						message = 'Call has been completed.';
					} else if(result.callStatus == 'Call Failed') {
						message = 'Call has been failed.';
						variant = 'error';
					} else if(result.callStatus == 'Call Cancelled') {
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
					fireEvent(cmp.pageRef, 'refreshValues_' + 'WCMContactCustomerScreen', hideCallingIcon);
					result['showCallingIcon'] = 'false';
					resolve(result);
				} else {
					setTimeout(() => {
						checkCallStatus(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum,ShowToastEvent,callResult);
					}, 5000);
				}
			}).catch(error => {
				console.log('error :' + error);
				reject(error);
			});
		
		});
	}

	function initCallerIDVerification(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum) {
		
		console.log(JSON.stringify(values));
		
		
		return new Promise(function(resolve, reject) {

			invoke({
				nameSpace : '', 
				className: 'OutgoingCallHandler', 
				functionName: 'initCallerIDVerification',
				values: values
			}).then(result => { 
				result = JSON.parse(JSON.stringify(result));
				if(result.OTP){
					result.OTPMessage = '<p class="slds-text-align_center"> Verification Code : <b class="slds-text-heading--medium">' +  result.OTP + '</b> </p>';
				}
				resolve(result);
				connectbwAgentAndCustomer(values.callLogDetails,cmp.pageRef,result,1,invoke, fireEvent);
				//location.reload();
			}).catch(error => {
				console.log('error :' + error);
				reject(error);
			});
		
		});
			
	}
	
	function connectbwAgentAndCustomer(callConfig,pageRef,result,count,invoke, fireEvent){
		
		console.log('Inside count : ' + count);
		return new Promise(function(resolve, reject) {
			
			invoke({
				nameSpace : '', 
				className: 'OutgoingCallHandler', 
				functionName: 'isCallerIdVerified',
				values: result
			}).then(result => { 
				console.log('Caller ID : ' + result.isCallerIdVerified);
				if(!result.isCallerIdVerified){
					if(count < 7){
						setTimeout(() => {
							count++;
							console.log('count >> : ' + count);
							connectbwAgentAndCustomer(callConfig,pageRef,result,count,invoke, fireEvent);
						}, 10000);
					}else{
						//alert('Not able to verify caller id. Please try again');
						result.errorMsg = 'Not able to verify caller id. Please try again';
						var errorMessage = {
							'name': 'errorMsg',
							'value': 'OTP not verified',
							'indexcm': undefined,
							'parentname': undefined,
							'onChangeMethod': undefined
						}

						fireEvent(pageRef, 'refreshValues_' + 'CallerIDVerification', errorMessage);
						resolve(result);
					}
				}else if(result.isCallerIdVerified){
					result.errorMsg = '<p class="slds-text-align_center slds-text-heading--medium slds-text-color_success">Caller ID has been verified successfully!</p>';
					var successMessage = {
						'name': 'successMsg',
						'value': '<p class="slds-text-align_center slds-text-heading--medium slds-text-color_success"><b>Caller ID has been verified successfully!</b></p>',
						'indexcm': undefined,
						'parentname': undefined,
						'onChangeMethod': undefined
					}

					fireEvent(pageRef, 'refreshValues_' + 'CallerIDVerification', successMessage);
					resolve(result);
					//fireEvent(pageRef, 'onCancel_' +  'WCMContactCustomerScreen_Dial' , result);
				}
				resolve(result);
			}).catch(error => {
				console.log('error :' + error);
				reject(error);
			});
		
		});
	}
	
	function refreshCustomerCommunication(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum) {
		return new Promise(function(resolve, reject) {
			
			invoke({
				nameSpace : '', 
				className: 'FetchCustomerCommunication', 
				functionName: 'getTransactions',
				values: values
			}).then(result => { 
				console.log('result :' + JSON.stringify(result));
				resolve(result);
				//fireEvent(cmp.pageRef, 'TransactionList_' + 'SRM_CustomerCommunicationScreen' , result);
				fireEvent(cmp.pageRef, 'CustomerCommunicationGrid_' + 'SRM_CustomerCommunicationScreen', result.CustomerCommunicationGrid);
			}).catch(error => {
				console.log('error :' + error);
				reject(error);
			});
		
		});
	}
	function noteChange(values, invoke, dataServiceObj, fireEvent, ref, rowvals,NavigationMixin, rowNum, ShowToastEvent) {
		return new Promise(function(resolve, reject) {
			if (values["buttonClassListremoveTreatmentNotes"] && values["buttonClassListremoveTreatmentNotes"].contains("removeTreatment")) {
				values.hideTreatmentNotes = "false";
				values.treatmentButtonName = "";
				delete values["buttonClassListremoveTreatmentNotes"];
				resolve(values);
			} if (values["buttonClassListtreatmentNotes"] && values["buttonClassListtreatmentNotes"].contains("oninclude")) {
				values.hideTreatmentNotes = "true";
				values.treatmentButtonName = "Include";
				// ref.dispatchEvent(new ShowToastEvent({
				// 	title: "Error",
				// 	message: "click yes",
				// 	variant: "error",
				// 	mode: "dismissable"
				// }));
				delete values["buttonClassListtreatmentNotes"];
				resolve(values);
			}else if (values["buttonClassListtreatmentNotes"] && values["buttonClassListtreatmentNotes"].contains("onno")) {
				values.hideTreatmentNotes = "true";
				values.treatmentButtonName = "No";
				// ref.dispatchEvent(new ShowToastEvent({
				// 	title: "Error",
				// 	message: "click no",
				// 	variant: "error",
				// 	mode: "dismissable"
				// }));
				delete values["buttonClassListtreatmentNotes"];
				resolve(values);
			} else {
				resolve(values);
			}
		});
	}
	function removeCommunication(values, invoke, dataServiceObj, fireEvent, ref, rowvals,NavigationMixin, rowNum, ShowToastEvent) {
		return new Promise(function(resolve, reject) {
			if(rowvals) {
				let val = {
					'Id' : rowvals.CustCommId
				}
				invoke({
					nameSpace : '', 
					className: 'FetchCustomerCommunication', 
					functionName: 'removeCommunication',
					values: val
				}).then(result => { 
					resolve({});
					ref.dispatchEvent(new ShowToastEvent({
						title: "Success",
						message: "Delete Successfully",
						variant: "success",
						mode: "dismissable"
					}));
				}).catch(error => {
					console.log('error :' + error);
					reject(error);
				});
			} else {
				resolve({});
			}
			
		});
	}

	exports.removeCommunication = removeCommunication;
	exports.noteChange = noteChange;
	exports.refreshCustomerCommunication = refreshCustomerCommunication;
	exports.connectbwAgentAndCustomer = connectbwAgentAndCustomer;
	exports.callToAgent = callToAgent;
	exports.initCallerIDVerification = initCallerIDVerification;
	exports.onSubmitEmail = onSubmitEmail;
	exports.onPhoneTypeChange = onPhoneTypeChange;
	exports.onContactMethods = onContactMethods;
	exports.onDidnotpickcall = onDidnotpickcall;
	exports.OnChangeCantactNamePhone = OnChangeCantactNamePhone;
	exports.onAttachFormatCompletion = onAttachFormatCompletion;
	exports.onAttachGenerateCompletion = onAttachGenerateCompletion;
	exports.changeStatementFormat = changeStatementFormat;
	exports.createStatementAttachment = createStatementAttachment;
    exports.showNoteBody = showNoteBody;
	exports.generateStatement = generateStatement;
	exports.updateEmailBodyValue = updateEmailBodyValue;
	exports.showFollowupDays = showFollowupDays;
	exports.createStatementAttachmentonPreview = createStatementAttachmentonPreview;
    exports.generateStatementforAttachment = generateStatementforAttachment;
	
    Object.defineProperty(exports, '__esModule', {
        value: true
    });

})));