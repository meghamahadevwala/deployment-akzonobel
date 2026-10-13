(function(global, factory) {
    typeof exports === 'object' && typeof module !== 'undefined' ? factory(exports) :
        typeof define === 'function' && define.amd ? define(['exports'], factory) :
        (factory((global.gog = global.gog || {})));
}(this, (function(exports) {
    'use strict';

    var version = "1.0.0";
	
	function onLoadUpdateDisputeWorkflowMatrix(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum) {
		return new Promise(function(resolve, error) {
			//-- Start | FIN-9672 | Changed by Ravi | 05 May 2026 --//
			if(values.userMasterId){
				resolve({"isExternalUser": !!(values.userEmail && !values.userName)});
			}else if(values.externalUserEmail){
			//-- End | FIN-9672 | Changed by Ravi | 05 May 2026 --//
				resolve({"isExternalUser": true});
			}else{
				resolve({"isExternalUser": false});
			}
		});
	}
	function onChangeIsExternalUser(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum) {
		return new Promise(function(resolve, error) {
			if(values.isExternalUser){
				//-- Start | FIN-9672 | Changed by Ravi | 05 May 2026 --//
				resolve({"User": {}, "UserMaster": {}});
				//-- End | FIN-9672 | Changed by Ravi | 05 May 2026 --//
			}else{
				//-- Start | FIN-9672 | Changed by Ravi | 05 May 2026 --//
				resolve({"externalUserEmail": "", "externalManagerEmail": ""});
				//-- End | FIN-9672 | Changed by Ravi | 05 May 2026 --//
			}
		});
	}
	function onDeleteDisputeWorkflowDetail(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum) {
		if (confirm('Are you sure you want to delete this record?')) {
			return new Promise(function (resolve, reject) {
				values.recordId = rowValue.Id;
				values.objectName = 'Dispute_Workflow_Matrix__c';
				invoke({
					className: 'DisputeConfigurationScreenController',
					functionName: 'onDeleteRecord',
					values: values
				}).then(result => {
					window.location.reload(true);				
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

	function onDeleteReminderEscalation(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum) {
		if (confirm('Are you sure you want to delete this record?')) {
			return new Promise(function (resolve, reject) {
				values.recordId = rowValue.Id;
				values.objectName = 'Dispute_Reminder_Escalation_Matrix__c';
				invoke({
					className: 'DisputeConfigurationScreenController',
					functionName: 'onDeleteRecord',
					values: values
				}).then(result => {
					window.location.reload(true);			
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

	function reloadPage(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum) {
		return new Promise(function(resolve, error) {
			window.location.reload(true);
			resolve({});
		});
		
	}

	function refreshDisputeMatrixList(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum) {
		return new Promise(function (resolve, error) {
			fireEvent(cmp.pageRef, 'refreshDataGrid' + values.parentScreenName + '_disputeWorflowGrid', null);
			resolve({});
		});

	}

	function refreshDisputeReminderEscalationList(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum) {
		return new Promise(function (resolve, error) {
			fireEvent(cmp.pageRef, 'refreshDataGrid' + values.parentScreenName + '_disputeReminderEscalationMatrix', null);
			resolve({});
		});

	}

	//-- Starts | FIN-8626 | Changed by Asera | 14 Nov 2025 --//
	function setDisputeResolverType(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum) {
		debugger;
		return new Promise(function(resolve, error) {
			invoke({ 
				className: 'DisputeActionController', 
				functionName: 'setDisputeResolverType',
				values: values 
			}).then(result => {
				if(result.disputeResolverType){
					resolve(result);
				} else {
					resolve({'disputeResolverType': ''});
				} 
			}).catch(error => {
				console.log('error :' + error);
				reject(error);
			});
			
		});
	}
	//-- End | FIN-8626 | Changed by Asera | 14 Nov 2025 --//

	exports.setDisputeResolverType = setDisputeResolverType;
	exports.onChangeIsExternalUser = onChangeIsExternalUser;
	exports.onLoadUpdateDisputeWorkflowMatrix = onLoadUpdateDisputeWorkflowMatrix;
	exports.onDeleteDisputeWorkflowDetail = onDeleteDisputeWorkflowDetail;
	exports.onDeleteReminderEscalation = onDeleteReminderEscalation;
	exports.refreshDisputeMatrixList = refreshDisputeMatrixList;
	exports.refreshDisputeReminderEscalationList = refreshDisputeReminderEscalationList;

    Object.defineProperty(exports, '__esModule', {
        value: true
    });

})));
