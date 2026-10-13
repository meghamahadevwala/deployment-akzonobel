//--- DO NOT CHANGE CODE | START ---//
(function(global, factory) {
    typeof exports === 'object' && typeof module !== 'undefined' ? factory(exports) :
        typeof define === 'function' && define.amd ? define(['exports'], factory) :
        (factory((global.gog = global.gog || {})));
}(this, (function(exports) {
    'use strict';
    var version = "1.0.0";

	
	function fetchTaskList(values, invoke, dataServiceObj, fireEvent, ref){
		return new Promise(function(resolve, reject) {
			invoke({ 
				className: 'MassDunningController', 
				functionName: 'fetchTaskList',
				values: values 
			}).then(result => {
				if(result.editableTaskList.length > 0) {
					for(let tempVal of result.editableTaskList) {
						if(tempVal['AccountId'] != null ){
							tempVal.AccountName ='<a href="' + '/'+ tempVal['AccountId'] + '"' + ' target="_blank">' + tempVal['Account_Name__c'] + '</a>';
							tempVal.Account_Name = {};
							tempVal.Account_Name.id = tempVal['AccountId'];
							tempVal.Account_Name.name = tempVal['Account_Name__c'];
						} if(tempVal['Subject'] != null ){
							tempVal.SubjectName ='<a href="' + '/'+ tempVal['Id'] + '"' + ' target="_blank">' + tempVal['Subject'] + '</a>';
						}	
						if(tempVal['celsrm__To__c'] != null ){
							tempVal.To__c = tempVal['celsrm__To__c'];
						}
						if(tempVal['celsrm__Bcc__c'] != null ){
							tempVal.Bcc__c = tempVal['celsrm__Bcc__c'];
						}
						if(tempVal['celsrm__Cc__c'] != null ){
							tempVal.Cc__c = tempVal['celsrm__Cc__c'];
						}
						if(tempVal['celsrm__From__c'] != null ){
							tempVal.From__c = tempVal['celsrm__From__c'];
						}
						tempVal.isSelected = true;
						// tempVal.celsrm__To__c = ['s.vekariya@celonis.com'];
					}
				}
				resolve(result);
			}).catch(error => {
				console.log('error :' + error);
				reject(error);
			});				
		});
	}

	// function sendMassDunningEmails(values, invoke, dataServiceObj, fireEvent, cmp, rowvals, NavigationMixin, rowNum, ShowToastEvent){
	// 	debugger;
	// 	return new Promise(function(resolve, reject) {
	// 		let sendDunning = false;
	// 		let errorMsg = null;
	// 		for(let val of values.editableTaskList){
	// 			if(val.isSelected && val.isSelected == true){
	// 				sendDunning = true;
	// 				var reg = /^([A-Za-z0-9_\-\.])+\@([A-Za-z0-9_\-\.])+\.([A-Za-z]{2,4})$/;
	// 				if(val.hasOwnProperty('celsrm__To__c') == false || val.celsrm__To__c == null){
	// 					errorMsg = 'Please add recipients email address for selected tasks';
	// 				} else if(reg.test(val.celsrm__To__c) == false){
	// 					errorMsg = 'Please provide a valid To email address for the To field.';
	// 				} else if(reg.test(val.celsrm__Cc__c) == false){
	// 					errorMsg = 'Please provide a valid email address for the Cc field.';
	// 				}
	// 			}
	// 		}
	// 		if(sendDunning == true && errorMsg == null){
	// 			invoke({ 
	// 				className: 'MassDunningController', 
	// 				functionName: 'sendMassDunningEmails',
	// 				values: values 
	// 			}).then(result => {
	// 				resolve(result);
					
	// 				cmp.dispatchEvent(new ShowToastEvent({
	// 					title: 'Success',
	// 					message: result.ggSuccessMessage,
	// 					variant: 'success',
	// 					mode: 'dismissable'
	// 				}));
	// 				// gog.fetchTaskListBasedOnSubject(values, invoke, ds, fireEvent, cmp, rowvals, NavigationMixin, null, ShowToastEvent).then(result => {	
	// 				// 	resolve(result);	
	// 				// }).catch(err => {	
	// 				// 	reject(err);	
	// 				// });	
	// 			}).catch(error => {
	// 				console.log('error :' + error);
	// 				reject(error);
	// 			});	
	// 		} else {
	// 			let inMap = {};
	// 			if(errorMsg != null){
	// 				inMap.ggErrorMessage = errorMsg;
	// 			} else {
	// 				inMap.ggErrorMessage = 'No task selected for dunning';
	// 			}	
	// 			resolve(inMap)
	// 		}
	// 	});
	// }
	function sendMassDunningEmails(values, invoke, dataServiceObj, fireEvent, cmp, rowvals, NavigationMixin, rowNum, ShowToastEvent){
		debugger;
		return new Promise(function(resolve, reject) {
			invoke({ 
				className: 'MassDunningController', 
				functionName: 'sendMassDunningEmails',
				values: values 
			}).then(result => {
				if(result.errorMessage){
					let returnMap = {
						"ggErrorMessage" : result.errorMessage
					};
					if(result.errorMessageIndex != null && result.errorMsgField != null){
						fireEvent(cmp.pageRef, 'EnableRequiredDesign_editableTaskList' + result.errorMsgField + '[' + result.errorMessageIndex + ']_Mass Dunning');
					}
					resolve(returnMap);
				} else if(result.ggSuccessMessage){
					cmp.dispatchEvent(new ShowToastEvent({
						title: 'Success',
						message: result.ggSuccessMessage,
						variant: 'success',
						mode: 'dismissable'
					}));
				}
				resolve({});
				

				// 'EnableRequiredDesign_editableTaskListcelsrm__To__c[0]_Mass Dunning'
				// 'EnableRequiredDesign_editableTaskListcelsrm__To__c[0]_Mass Dunning'
				
			}).catch(error => {
				console.log('error :' + error);
				reject(error);
			});	
		});
	}
	
	exports.fetchTaskList = fetchTaskList;
	exports.sendMassDunningEmails = sendMassDunningEmails;

	//--- DO NOT CHANGE CODE | START ---//
    Object.defineProperty(exports, '__esModule', {
        value: true
    });
	//--- DO NOT CHANGE CODE | END ---//

})));
