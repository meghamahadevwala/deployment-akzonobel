//--- DO NOT CHANGE CODE | START ---//
(function(global, factory) {
    typeof exports === 'object' && typeof module !== 'undefined' ? factory(exports) :
        typeof define === 'function' && define.amd ? define(['exports'], factory) :
        (factory((global.gog = global.gog || {})));
}(this, (function(exports) {
    'use strict';

    var version = "1.0.0";
	//--- DO NOT CHANGE CODE | END ---//	
	
	
	function IncludeChildAccountOnTransactionGrid(values, invoke, dataServiceObj, fireEvent, ref){
		var arr = JSON.parse(JSON.stringify(values['ChildAccount']));
		let ids = '';
		for(let a of arr) {
			ids = ids + a.Id + ',';
		}
		values['childAccountId'] = ids;
		var userCurrency = values['userCurrency'];
		return new Promise(function(resolve, reject) {
			invoke({ 
					className: 'WCMFetchChildAccount', 
					functionName: 'fetchChildAccount',
					values: values 
				}).then(result1 => {	
					var result = JSON.parse(JSON.stringify(result1));
					if(result.l_values.length > 0) {
						for(let tempVal of result.l_values) {
							for(let tempfield of result.updatedColumns) {
								if (tempfield.type == 'text' && tempVal[tempfield.fieldName] != null && tempVal[tempfield.fieldName] != undefined) {
									if(tempVal[tempfield.fieldName].includes("\n")) {
										tempVal[tempfield.fieldName] = tempVal[tempfield.fieldName].replace(/\n/g, '&nbsp');
									}
								}
								if(tempfield.fieldName =='Name'){
									tempVal.nameSort = tempVal.Name;
									let key = '<a href="' + '/'+ tempVal['Id'] + '"' + ' target="_blank">' + tempVal['Name'] + '</a>';
									tempVal.Name = key;
								} else if(tempfield.fieldName =='celsrm__Latest_Note__c'){
									if(tempVal['celsrm__Latest_Note__c'] == undefined ){
										// tempVal.Notes_sort__c = "";
										tempVal.celsrm__Latest_Note__c = "";
									}else{
										// tempVal.Notes_sort__c = tempVal['celsrm__Latest_Note__c'];
										var tempNt = tempVal['celsrm__Latest_Note__c'].replace('"','&quot;');
										var notesVal = tempNt ;
									
										if(tempNt.length > 30)
										notesVal  = tempNt.substring(0,20)+'...';
										let key = '<img src="/resource/NotesIcon" target="_blank" width="15" height="15" title=\"'+tempNt+'\">'  + notesVal+'</img>';
										tempVal.celsrm__Latest_Note__c = key;
									}
									
							 } else if(tempfield.fieldName =='celsrm__Flag__c'){
										
								let imageUrl = '';
								let date = new Date();
								
								if (tempVal['celsrm__Disputed_Amount__c'] && tempVal['celsrm__Disputed_Amount__c'] != 0) {
									// imageUrl = "<img src='/resource/SRMResource/WCMResource/image/red.png' title='Disputed' alt='Disputed' width='16' height='16'>";
									imageUrl = "<img src='/resource/celsrm__SRMResource/image/red.png' title='Disputed' alt='Disputed' width='16' height='16'>";;
								} else {
									// imageUrl = "<img src='/resource/SRMResource/WCMResource/image/transparent.png' title='' alt='' width='16' height='16'>";
									imageUrl = "<img src='/resource/celsrm__SRMResource/image/transparent.png' title='' alt='' width='16' height='16'>";
								}
								if (tempVal['celsrm__Promise_Date__c']) {
									let d = new Date(tempVal['celsrm__Promise_Date__c']);
									if (tempVal['celsrm__Is_Broken_Promise__c'] && tempVal['celsrm__Is_Broken_Promise__c'] == true ) {
										// imageUrl += "<img src='/resource/SRMResource/WCMResource/image/BrokenPromise$.png' title='Broken Promise' alt='Broken Promise' width='16' height='16'>";
										imageUrl += "<img src='/resource/celsrm__SRMResource/image/BrokenPromise$.png' title='Broken Promise' alt='Broken Promise' width='16' height='16'>";
									} else if (tempVal['celsrm__Promised_Amount__c'] && tempVal['celsrm__Promised_Amount__c'] != 0 ) {
										// imageUrl += "<img src='/resource/SRMResource/WCMResource/image/Promise$.png' title='Promised' alt='Promised' width='16' height='16'>";
										imageUrl += "<img src='/resource/celsrm__SRMResource/image/BrokenPromise$.png' title='Broken Promise' alt='Broken Promise' width='16' height='16'>";
									}
									
								}

								tempVal['celsrm__Flag__c'] = imageUrl;
							}else if(result.refField.indexOf(tempfield.fieldName) !== (-1)){
									let st =tempfield.fieldName.substring(0,tempfield.fieldName.length-1)+ 'r';
									let tempmap = tempVal[st];
									if(tempmap !== undefined && tempmap !== null) {
										let key = '<a href="' + '/'+ tempVal[tempfield.fieldName] + '"' + ' target="_blank">' +   tempmap['Name'] + '</a>';
										tempVal[tempfield.fieldName] = key;
									}
								}
							}
						}
					}
					fireEvent(ref.pageRef, 'TransactionList_SRMTransactionGridScreen_Columns', result.updatedColumns);
					fireEvent(ref.pageRef, 'TransactionList_SRMTransactionGridScreen' , result.l_values);
					delete result.l_values;
					delete result.updatedColumns;
					var finalText = '<b> Total Balance = 0.00 </b>';
					var totalSelectedinvoice = '<b>' + 'Selected Invoices : 0 </b>';
					resolve({});
					let temp = {
						"refreshParentValues" : {
							"ChildAccount" : result.ChildAccount,
							"TransactionList" : null,
							"Total": finalText,
							"totalSelectedinvoice":totalSelectedinvoice,
							'TransactionList':[]
						}
					};
					ref.dispatchEvent(new  CustomEvent("closewindow", {
						detail: temp
					}));
					
				}).catch(error => {
					console.log('error :' + error);
					reject(error);
				});
		});
	}	
	
	function RemoveChildAccountOnTransactionGrid(values, invoke, dataServiceObj, fireEvent, ref){

		delete values['childAccountId'];
		var userCurrency = values['userCurrency'];
		return new Promise(function(resolve, reject) {
			invoke({ 
					className: 'WCMFetchChildAccount', 
					functionName: 'fetchChildAccount',
					values: values 
				}).then(result1 => {
					var result = JSON.parse(JSON.stringify(result1));
					if(result.l_values.length > 0) {
						for(let tempVal of result.l_values) {
							for(let tempfield of result.updatedColumns) {
								if(tempfield.fieldName =='Name'){
									tempVal.nameSort = tempVal.Name;
									let key = '<a href="' + '/'+ tempVal['Id'] + '"' + ' target="_blank">' + tempVal['Name'] + '</a>';
									tempVal.Name = key;
								}else if(tempfield.fieldName =='celsrm__Latest_Note__c'){
									if(tempVal['celsrm__Latest_Note__c'] == undefined ){
										tempVal.Notes_sort__c = "";
										tempVal.celsrm__Latest_Note__c = "";
									}else{
										tempVal.Notes_sort__c = tempVal['celsrm__Latest_Note__c'];
										var tempNt = tempVal['celsrm__Latest_Note__c'].replace('"','&quot;');
										var notesVal = tempNt ;
									
										if(tempNt.length > 30)
										notesVal  = tempNt.substring(0,20)+'...';
										let key = '<img src="/resource/NotesIcon" target="_blank" width="15" height="15" title=\"'+tempNt+'\">'  + notesVal+'</img>';
										tempVal.celsrm__Latest_Note__c = key;
									}
									
							} else if(tempfield.fieldName =='celsrm__Flag__c'){
										
								let imageUrl = '';
								let date = new Date();
								
								if (tempVal['celsrm__Disputed_Amount__c'] && tempVal['celsrm__Disputed_Amount__c'] != 0) {
									// imageUrl = "<img src='/resource/SRMResource/WCMResource/image/red.png' title='Disputed' alt='Disputed' width='16' height='16'>";
									imageUrl = "<img src='/resource/celsrm__SRMResource/image/red.png' title='Disputed' alt='Disputed' width='16' height='16'>";;
								} else {
									// imageUrl = "<img src='/resource/SRMResource/WCMResource/image/transparent.png' title='' alt='' width='16' height='16'>";
									imageUrl = "<img src='/resource/celsrm__SRMResource/image/transparent.png' title='' alt='' width='16' height='16'>";
								}
								if (tempVal['celsrm__Promise_Date__c']) {
									let d = new Date(tempVal['celsrm__Promise_Date__c']);
									if (tempVal['celsrm__Is_Broken_Promise__c'] && tempVal['celsrm__Is_Broken_Promise__c'] == true ) {
										// imageUrl += "<img src='/resource/SRMResource/WCMResource/image/BrokenPromise$.png' title='Broken Promise' alt='Broken Promise' width='16' height='16'>";
										imageUrl += "<img src='/resource/celsrm__SRMResource/image/BrokenPromise$.png' title='Broken Promise' alt='Broken Promise' width='16' height='16'>";
									} else if (tempVal['celsrm__Promised_Amount__c'] && tempVal['celsrm__Promised_Amount__c'] != 0 ) {
										// imageUrl += "<img src='/resource/SRMResource/WCMResource/image/Promise$.png' title='Promised' alt='Promised' width='16' height='16'>";
										imageUrl += "<img src='/resource/celsrm__SRMResource/image/BrokenPromise$.png' title='Broken Promise' alt='Broken Promise' width='16' height='16'>";
									}
									
								}

								tempVal['celsrm__Flag__c'] = imageUrl;
							} else if(result.refField.indexOf(tempfield.fieldName) !== (-1)){
									let st =tempfield.fieldName.substring(0,tempfield.fieldName.length-1)+ 'r';
									let tempmap = tempVal[st];
									if(tempmap !== undefined && tempmap !== null) {
										let key = '<a href="' + '/'+ tempVal[tempfield.fieldName] + '"' + ' target="_blank">' +   tempmap['Name'] + '</a>';
										tempVal[tempfield.fieldName] = key;
									}
								}
							}
						}
					}
					fireEvent(ref.pageRef, 'TransactionList_SRMTransactionGridScreen_Columns', result.updatedColumns);
					fireEvent(ref.pageRef, 'TransactionList_SRMTransactionGridScreen' , result.l_values);
					delete result.l_values;
					delete result.updatedColumns;
					resolve({});
					var finalText = '<b> Total Balance = 0.00 </b>';
					var totalSelectedinvoice = '<b>' + 'Selected Invoices : 0 </b>';
					let temp = {
						"refreshParentValues" : {
							"ChildAccount" : null,
							"TransactionList" : null,
							"Total": finalText,
							"totalSelectedinvoice":totalSelectedinvoice,
							'TransactionList':[]
						}
					};
					ref.dispatchEvent(new  CustomEvent("closewindow", {
						detail: temp
					}));
					
				}).catch(error => {
					console.log('error :' + error);
					reject(error);
				});
		});
	}

	exports.RemoveChildAccountOnTransactionGrid = RemoveChildAccountOnTransactionGrid;
	exports.IncludeChildAccountOnTransactionGrid = IncludeChildAccountOnTransactionGrid;
//--- DO NOT CHANGE CODE | START ---//
    Object.defineProperty(exports, '__esModule', {
        value: true
    });
//--- DO NOT CHANGE CODE | END ---//

})));