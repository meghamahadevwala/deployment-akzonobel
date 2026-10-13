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
	function showFollowupDaysDispute(values, invoke, ds) {
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
	
	function updateAllGrid(values, invoke, ds, fireEvent, lwcRef, rowData) {
		
		var arr = values['TransactionList'];
		
		var count = rowData['gogGridIndex'];
		var editfieldS = values['EditableField'].split(",")
		var  size = arr.length;
		
		for(var i = 0; i < parseInt(editfieldS.length) ; i++ ){
			var test2 = parseInt(editfieldS.length);
			var Fieldst= String(editfieldS[i]);
			if(Fieldst != 'DisputeAmount') {
                if(arr[count][Fieldst] != null){
                    var RequiredValue = arr[count][Fieldst];
                        for(var k = 0; k < parseInt(size); k++){
                        
								arr[k][Fieldst] = RequiredValue;
                                
                            
                    }    
				}
			}
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

	function getDisputeResolver(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum) {
		return new Promise(function(resolve, error) {
			values['selectedType'] = values['TransactionList'][rowNum]['Type'];
			values['selectedReasonCode'] = values['TransactionList'][rowNum]['ReasonCode'];
			invoke({	
				className: 'CreateDisputeController', 
				functionName: 'getDisputeResolver',	
				values: values 	
			}).then(result1 => {	
				let resolverMap = {};
				resolverMap.id = result1['resolverId'];
				resolverMap.name = result1['resolverName'];
				result1['TransactionList'][rowNum]['DisputeResolver'] = resolverMap;
				result1['TransactionList'][rowNum]['WorkflowMatrix'] = result1['relatedMatrixId'];
				resolve(result1);	
					
			}).catch(error => {	
				console.log('error :' + error);	
				reject(error);	
			});	
		});
	}

	exports.onSubmitEmail = onSubmitEmail;
	exports.showFollowupDaysDispute = showFollowupDaysDispute;
    exports.showNoteBody = showNoteBody;
	exports.updateAllGrid = updateAllGrid;
	exports.getDisputeResolver = getDisputeResolver;

    Object.defineProperty(exports, '__esModule', {
        value: true
    });

})));