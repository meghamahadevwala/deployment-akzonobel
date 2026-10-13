	(function(global, factory) {
	typeof exports === 'object' && typeof module !== 'undefined' ? factory(exports) :
		typeof define === 'function' && define.amd ? define(['exports'], factory) :
		(factory((global.gog = global.gog || {})));
	}(this, (function(exports) {
	'use strict';

	var version = "1.0.0";
	var Timeinterval;
	
	function fillAccountDetails(values, invoke, ds, fireEvent, lwcRef, rowData) {
		var selectedTask = [];
		values['selectedTask'] = rowData;
		var screenName = values['ggScreenName'];
		return new Promise(function(resolve, reject) {
			invoke({ 
				className: 'WCM_HomeSendFollowUp', 
				functionName: 'Send Statement',
				values: values 
			}).then(result => {
				
				let customChangeHandler = {
                "callingControlName": "TaskList",
                "targetScreen": "SRM_SendStatementScreen",
                "targetScreenSize": "large-width",
                "sourceControlName": "TaskList",
                "vals" : result,
            };
            fireEvent(lwcRef.pageRef, 'openChildScreen' + '_'+screenName + 'TaskList', customChangeHandler); 
				//resolve(result);
				resolve({});
			}).catch(error => {
				console.log('error :' + error);
				reject(error);
			});
		});
	}
	function LogACall(values, invoke, ds, fireEvent, lwcRef, rowData,NavigationMixin) {
		var selectedTask = [];
		values['selectedTask'] = rowData;
		var screenName = values['ggScreenName'];
		return new Promise(function(resolve, reject) {
			lwcRef[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Task',
                actionName: 'new'
            }
        }); 
		
			resolve({});
		});
	}
	
	
	exports.fillAccountDetails = fillAccountDetails;
	exports.LogACall = LogACall;
	
	
	


	Object.defineProperty(exports, '__esModule', {
		value: true
	});

	})));