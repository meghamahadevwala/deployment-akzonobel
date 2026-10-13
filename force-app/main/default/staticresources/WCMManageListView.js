//--- DO NOT CHANGE CODE | START ---//
(function(global, factory) {
    typeof exports === 'object' && typeof module !== 'undefined' ? factory(exports) :
        typeof define === 'function' && define.amd ? define(['exports'], factory) :
        (factory((global.gog = global.gog || {})));
}(this, (function(exports) {
    'use strict';

    var version = "1.0.0";
	//--- DO NOT CHANGE CODE | END ---//	
	
	// function deleteListView(values, invoke, dataServiceObj, fireEvent, ref, rowvals,NavigationMixin, rowNum, ShowToastEvent){
	// 	values.ActionName = 'Delete';
	// 	if(values.isCurrentUserListView){
	// 		if(confirm('Are you sure?')) {
	// 			return new Promise(function(resolve, reject) {
	// 				invoke({ 
	// 					className: 'DeleteListView', 
	// 					functionName: '',
	// 					values: values 
	// 				}).then(result => {
	// 					result = JSON.parse(JSON.stringify(result));
	// 					var listview = result.ListView;
	// 					result.enableSubmitButton = false;
	// 					window.location.reload(true);
	// 					// gog.filterDataByView(result, invoke, dataServiceObj, fireEvent, ref).then(result1 => {
	// 					// 	var result = JSON.parse(JSON.stringify(result1));
	// 					// 	result.ListView = listview;
	// 					// 	resolve(result);
	// 					// }).catch(err => {
	// 					// 	reject(err);
	// 					// });
	// 					resolve(result);
	// 				}).catch(error => {
	// 					console.log('error :' + error);
	// 					reject(error);
	// 				});
					
	// 			});
	// 		} else {
	// 			return new Promise(function(resolve, error) {
	// 				resolve({});
	// 			});
	// 		}
	// 	} else {
	// 		return new Promise(function(resolve, reject) {
	// 			let error = 'You can not delete this view';
	// 			reject(error);
	// 		});
	// 	}
		
	// }
	
	// function newListView(values, invoke, dataServiceObj, fireEvent, ref, rowvals,NavigationMixin, rowNum, ShowToastEvent){
	// 	values.ActionName = 'New';
	// 	values.ListViewName = '';
	// 	values.Default = false;
	// 	values.Global = false;
	// 	values.SortField = '';
	// 	values.SortDirection = '';
	// 	values.CriteriaGrid = [];
	// 	values.SelectField = "";
	// 	return new Promise(function(resolve, reject) {
	// 		values.enableSubmitButton = true;
	// 		resolve(values);
	// 	});
	// }

	// function cloneListView(values, invoke, dataServiceObj, fireEvent, ref, rowvals,NavigationMixin, rowNum, ShowToastEvent){
	// 	values.ActionName = 'Clone';
	// 	return new Promise(function(resolve, reject) {
	// 		invoke({ 
	// 			className: 'GetListView', 
	// 			functionName: '',
	// 			values: values 
	// 		}).then(result => {
	// 			result = JSON.parse(JSON.stringify(result));
	// 			result.enableSubmitButton = true;
	// 			var listview = result.ListView;
	// 			// gog.filterDataByView(result, invoke, dataServiceObj, fireEvent, ref).then(result1 => {
	// 			// 	var result = JSON.parse(JSON.stringify(result1));
	// 			// 	result.ListView = listview;
	// 			// 	resolve(result);
	// 			// }).catch(err => {
	// 			// 	reject(err);
	// 			// });
	// 			resolve(result);
	// 		}).catch(error => {
	// 			console.log('error :' + error);
	// 			reject(error);
	// 		});
	// 	});
	// }
	// function editListView(values, invoke, dataServiceObj, fireEvent, ref, rowvals,NavigationMixin, rowNum, ShowToastEvent){
	// 	values.ActionName = 'Edit';
	// 	return new Promise(function(resolve, reject) {
	// 		invoke({ 
	// 			className: 'GetListView', 
	// 			functionName: '',
	// 			values: values 
	// 		}).then(result => {
	// 			result = JSON.parse(JSON.stringify(result));
	// 			result.enableSubmitButton = true;
	// 			var listview = result.ListView;
	// 			// gog.filterDataByView(result, invoke, dataServiceObj, fireEvent, ref).then(result1 => {
	// 			// 	var result = JSON.parse(JSON.stringify(result1));
	// 			// 	result.ListView = listview;
	// 			// 	resolve(result);
	// 			// }).catch(err => {
	// 			// 	reject(err);
	// 			// });
	// 			resolve(result);
	// 		}).catch(error => {
	// 			console.log('error :' + error);
	// 			reject(error);
	// 		});
	// 	});
	// }
	// function changemanageListView(values, invoke, dataServiceObj, fireEvent, ref, rowvals,NavigationMixin, rowNum, ShowToastEvent){
	// 	values.ActionName = '';
	// 	var screenName = values['ggScreenName'];
	// 	return new Promise(function(resolve, reject) {
	// 		invoke({ 
	// 			className: 'GetListView', 
	// 			functionName: 'changeListView',
	// 			values: values 
	// 		}).then(result => {
	// 			result = JSON.parse(JSON.stringify(result));
	// 			var listview = result.ListView;
	// 			result.CriteriaGrid1 = result.CriteriaGrid;
	// 			result.enableSubmitButton = false;
	// 			fireEvent(ref.pageRef, 'CriteriaGrid1_' + screenName , result.CriteriaGrid);
	// 			// gog.filterDataByView(result, invoke, dataServiceObj, fireEvent, ref).then(result1 => {
	// 			// 	var result = JSON.parse(JSON.stringify(result1));
	// 			// 	result.ListView = listview;
	// 			// 	resolve(result);
	// 			// }).catch(err => {
	// 			// 	reject(err);
	// 			// });
	// 			resolve(result);
	// 		}).catch(error => {
	// 			console.log('error :' + error);
	// 			reject(error);
	// 		});
	// 	});
	// }

	function deleteListView(values, invoke, dataServiceObj, fireEvent, ref, rowvals,NavigationMixin, rowNum, ShowToastEvent){
		debugger;
		values.ActionName = 'Delete';
		if(values.isCurrentUserListView){
			if(confirm('Are you sure?')) {
				return new Promise(function(resolve, reject) {
					invoke({ 
						className: 'ListViewController', 
						functionName: 'deleteListView',
						values: values 
					}).then(result => {
						result = JSON.parse(JSON.stringify(result));
						var listview = result.ListView;
						result.enableSubmitButton = false;
						window.location.reload(true);
						// gog.filterDataByView(result, invoke, dataServiceObj, fireEvent, ref).then(result1 => {
						// 	var result = JSON.parse(JSON.stringify(result1));
						// 	result.ListView = listview;
						// 	resolve(result);
						// }).catch(err => {
						// 	reject(err);
						// });
						resolve(result);
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
		} else {
			return new Promise(function(resolve, reject) {
				let error = 'You can not delete this view';
				reject(error);
			});
		}
		
	}
	
	function newListView(values, invoke, dataServiceObj, fireEvent, ref, rowvals,NavigationMixin, rowNum, ShowToastEvent){
		values.ActionName = 'New';
		values.ListViewName = '';
		values.Default = false;
		values.Global = false;
		values.CriteriaGrid = [];
		values.SortingGrid = [];
		values.ColumnConfig = [];
		values.FilterCondition = '';
		// {"enableCopy":null,"isExport":true,"hide":null,"onClickFunction":"","isAggregate":false,"iconClassMap":false,"iconFlag":false,"iconName":"","width":"","type":"link","fieldName":"Name","label":"Invoice#"}
		values.SelectField = "";
		// return new Promise(function(resolve, reject) {
		// 	values.enableSubmitButton = true;
		// 	resolve(values);
		// });

		return new Promise(function(resolve, reject) {
			invoke({ 
				className: 'ListViewController', 
				functionName: 'getNewListView',
				values: values 
			}).then(result => {
				result = JSON.parse(JSON.stringify(result));
				result.enableSubmitButton = true;
				resolve(result);
			}).catch(error => {
				console.log('error :' + error);
				reject(error);
			});
		});
	}

	function cloneListView(values, invoke, dataServiceObj, fireEvent, ref, rowvals,NavigationMixin, rowNum, ShowToastEvent){
		values.ActionName = 'Clone';
		return new Promise(function(resolve, reject) {
			invoke({ 
				className: 'ListViewController', 
				functionName: 'GetListView',
				values: values 
			}).then(result => {
				result = JSON.parse(JSON.stringify(result));
				result.enableSubmitButton = true;
				var listview = result.ListView;
				// gog.filterDataByView(result, invoke, dataServiceObj, fireEvent, ref).then(result1 => {
				// 	var result = JSON.parse(JSON.stringify(result1));
				// 	result.ListView = listview;
				// 	resolve(result);
				// }).catch(err => {
				// 	reject(err);
				// });
				resolve(result);
			}).catch(error => {
				console.log('error :' + error);
				reject(error);
			});
		});
	}
	function editListView(values, invoke, dataServiceObj, fireEvent, ref, rowvals,NavigationMixin, rowNum, ShowToastEvent){
		values.ActionName = 'Edit';
		return new Promise(function(resolve, reject) {
			invoke({ 
				className: 'ListViewController', 
				functionName: 'getListView',
				values: values 
			}).then(result => {
				result = JSON.parse(JSON.stringify(result));
				result.enableSubmitButton = true;
				var listview = result.ListView;
				// gog.filterDataByView(result, invoke, dataServiceObj, fireEvent, ref).then(result1 => {
				// 	var result = JSON.parse(JSON.stringify(result1));
				// 	result.ListView = listview;
				// 	resolve(result);
				// }).catch(err => {
				// 	reject(err);
				// });
				resolve(result);
			}).catch(error => {
				console.log('error :' + error);
				reject(error);
			});
		});
	}
	function changemanageListView(values, invoke, dataServiceObj, fireEvent, ref, rowvals,NavigationMixin, rowNum, ShowToastEvent){
		debugger;
		values.ActionName = '';
		var screenName = values['ggScreenName'];
		//-- Start | FIN-9463 | Changed by Dhwanil Shah | 18 May 2026 --//
		function refreshConfigGrid(controlName, data, valuesMap) {
			// Clear first, then repopulate on the next tick so reused grid row components do not keep stale cell values.
			fireEvent(ref.pageRef, 'UpdateValuesMap' + screenName + '_' + controlName, valuesMap);
			fireEvent(ref.pageRef, controlName + '_' + screenName, []);
			fireEvent(ref.pageRef, 'refreshDataGrid' + screenName + '_' + controlName, null);
			setTimeout(function() {
				fireEvent(ref.pageRef, 'UpdateValuesMap' + screenName + '_' + controlName, valuesMap);
				fireEvent(ref.pageRef, controlName + '_' + screenName, data || []);
				fireEvent(ref.pageRef, 'refreshDataGrid' + screenName + '_' + controlName, null);
			}, 0);
		}
		//-- End | FIN-9463 | Changed by Dhwanil Shah | 18 May 2026 --//
		return new Promise(function(resolve, reject) {
			invoke({ 
				className: 'ListViewController', 
				functionName: 'changeListView',
				values: values 
			}).then(result => {
				result = JSON.parse(JSON.stringify(result));
				var listview = result.ListView;
				result.CriteriaGrid1 = result.CriteriaGrid;
				result.ColumnConfig1 = result.ColumnConfig;
				result.SortingGrid1 = result.SortingGrid;
				result.enableSubmitButton = false;
				//-- Start | FIN-9463 | Changed by Dhwanil Shah | 18 May 2026 --//
				refreshConfigGrid('CriteriaGrid1', result.CriteriaGrid, result);
				refreshConfigGrid('ColumnConfig1', result.ColumnConfig, result);
				refreshConfigGrid('SortingGrid1', result.SortingGrid, result);
				//-- End | FIN-9463 | Changed by Dhwanil Shah | 18 May 2026 --//
				// gog.filterDataByView(result, invoke, dataServiceObj, fireEvent, ref).then(result1 => {
				// 	var result = JSON.parse(JSON.stringify(result1));
				// 	result.ListView = listview;
				// 	resolve(result);
				// }).catch(err => {
				// 	reject(err);
				// });
				resolve(result);
			}).catch(error => {
				console.log('error :' + error);
				reject(error);
			});
		});
	}

	function onClickReOrder(values, invoke, dataServiceObj, fireEvent, ref, rowvals,NavigationMixin, rowNum, ShowToastEvent) {
		return new Promise(function(resolve, reject) {
			let reorderIndex = rowNum;
			let className = values['buttonClassList' + 'MoveRowArea' + reorderIndex][0];
			if(className == 'up') {
				if (reorderIndex !== 0) {
					reorderIndex = parseInt(parseInt(reorderIndex) - 1);
					let oldData = values.ColumnConfig[reorderIndex];
					values.ColumnConfig.splice(reorderIndex, 1);
					values.ColumnConfig.splice(rowNum, 0, oldData);
				}
			} else if(className == 'down') {
				if (reorderIndex !== parseInt(parseInt(values.ColumnConfig.length) - 1)) {
					reorderIndex = parseInt(parseInt(reorderIndex) + 1);
					let oldData = values.ColumnConfig[reorderIndex];
					values.ColumnConfig.splice(reorderIndex, 1);
					values.ColumnConfig.splice(rowNum, 0, oldData);
				}
			}
			resolve(values);
		});
	}

	function onChangeSortOrder(values, invoke, dataServiceObj, fireEvent, ref, rowvals,NavigationMixin, rowNum, ShowToastEvent) {
		var screenName = values['ggScreenName'];
		return new Promise(function(resolve, reject) {
			let className = values['buttonClassList' + 'sortDirection' + rowNum][0];
			if(className == 'asc') {
				values.SortingGrid[rowNum].sortDirection = '<img src="/resource/CustomResource/image/sort_desc.png" class="desc" width="15" height="15"></img>';
				values.SortingGrid[rowNum].order = 'DESC';
			} else if(className == 'desc') {
				values.SortingGrid[rowNum].sortDirection = '<img src="/resource/CustomResource/image/sort_asc.png" class="asc" width="15" height="15"></img>';
				values.SortingGrid[rowNum].order = 'ASC';
			}

			fireEvent(ref.pageRef, 'UpdateValuesMap' + screenName + '_' + 'SortingGrid', values);
			resolve(values);
		});
	}

	// exports.deleteListView = deleteListView;
	// exports.newListView = newListView;
	// exports.cloneListView = cloneListView;
	// exports.editListView = editListView;
	// exports.changemanageListView = changemanageListView;

	exports.deleteListView = deleteListView;
	exports.newListView = newListView;
	exports.cloneListView = cloneListView;
	exports.editListView = editListView;
	exports.changemanageListView = changemanageListView;
	exports.onClickReOrder = onClickReOrder;
	exports.onChangeSortOrder = onChangeSortOrder;

	//--- DO NOT CHANGE CODE | START ---//
    Object.defineProperty(exports, '__esModule', {
        value: true
    });
//--- DO NOT CHANGE CODE | END ---//

})));
