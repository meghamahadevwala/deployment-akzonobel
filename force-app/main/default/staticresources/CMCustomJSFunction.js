//--- DO NOT CHANGE CODE | START ---//
(function(global, factory) {
    typeof exports === 'object' && typeof module !== 'undefined' ? factory(exports) :
        typeof define === 'function' && define.amd ? define(['exports'], factory) :
        (factory((global.gog = global.gog || {})));
}(this, (function(exports) {
    'use strict';

    var version = "1.0.0";
	//--- DO NOT CHANGE CODE | END ---//	

	function onChangeScoreCardType(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum) {
		return new Promise(function(resolve, error) {
			var EmptyList = [];
			if (values.ScoreCardType === undefined || values.ScoreCardType === null || values.ScoreCardType === "") {
				fireEvent(cmp.pageRef,'Parameters_'+ values.ggScreenName, EmptyList);
				resolve(values);
			} else {
				fireEvent(cmp.pageRef,'ParametersValueScore_'+ values.ggScreenName, EmptyList);
				values.ParameterType = null;
				invoke({
					nameSpace : '', 
					className: 'CreditManagementClass', 
					functionName: 'GetParameters',
					values: values 
				}).then(result => {
					fireEvent(cmp.pageRef,'Parameters_'+ values.ggScreenName, result['Parameters']);
					resolve(result);
				}).catch(error => {
					console.log('error :' + error);
					reject(error);
				});
			}
		});
    }
	
	function onChangeParameter(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum) {
		return new Promise(function(resolve, error) {
			if (values.Parameters == [] || values.Parameters.length == 0 || values.ScoreCardType === undefined || values.ScoreCardType === null || values.ScoreCardType === "") {
				var EmptyList = [];
				fireEvent(cmp.pageRef,'ParametersValueScore_'+ values.ggScreenName, EmptyList);
				values.ParameterType = null;
				resolve(values);
			} else {
				invoke({
					nameSpace : '', 
					className: 'CreditManagementClass', 
					functionName: 'GetParametersValueScore',
					values: values 
				}).then(result => {
					fireEvent(cmp.pageRef, 'ParametersValueScore_' + values.ggScreenName + '_Columns', result['ParametersValueScoreColumns']);
					fireEvent(cmp.pageRef,'ParametersValueScore_'+ values.ggScreenName, result['ParametersValueScore']);
					resolve(result);
				}).catch(error => {
					console.log('error :' + error);
					reject(error);
				});
			}
		});
    }
	
	function DeleteParameter(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum) {
		return new Promise(function(resolve, error) {
			invoke({
				nameSpace : '', 
				className: 'CreditManagementClass', 
				functionName: 'DeleteParameter',
				values: values 
			}).then(result => {
				fireEvent(cmp.pageRef,'Parameters_'+ values.ggScreenName, result['Parameters']);
				resolve(result);
			}).catch(error => {
				console.log('error :' + error);
				reject(error);
			});
		});
    }
	
	function DeleteParameterValue(values, invoke, ds, fireEvent, cmp, rowValue, navigationMixin, rowNum) {
		return new Promise(function(resolve, error) {
			invoke({
				nameSpace : '', 
				className: 'CreditManagementClass', 
				functionName: 'DeleteParameterValue',
				values: values 
			}).then(result => {
				fireEvent(cmp.pageRef,'ParametersValueScore_'+ values.ggScreenName, result['ParametersValueScore']);
				resolve(result);
			}).catch(error => {
				console.log('error :' + error);
				reject(error);
			});
		});
    }

	exports.onChangeScoreCardType = onChangeScoreCardType;
	exports.onChangeParameter = onChangeParameter;
	exports.DeleteParameter = DeleteParameter;
	exports.DeleteParameterValue = DeleteParameterValue;
	
//--- DO NOT CHANGE CODE | START ---//
    Object.defineProperty(exports, '__esModule', {
        value: true
    });
//--- DO NOT CHANGE CODE | END ---//
})));